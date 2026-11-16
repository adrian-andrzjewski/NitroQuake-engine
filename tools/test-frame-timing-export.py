"""Execute the native buffered timing/export functions with a controlled clock."""
import csv
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import unittest

ROOT=Path(__file__).resolve().parents[1]
COMPILER=shutil.which('gcc') or next((str(p) for p in [
    Path('C:/msys64/ucrt64/bin/gcc.exe'), Path('C:/msys64/mingw64/bin/gcc.exe'),
    Path('C:/msys64/usr/bin/gcc.exe')] if p.is_file()),None)


def extract(source, name):
    # Mask literals/comments without changing offsets before scanning braces.
    masked=re.sub(r'/\*.*?\*/|//[^\n]*|"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\'',
                  lambda m:' '*len(m[0]),source,flags=re.S)
    match=re.search(r'(?m)^(?:static )?void '+name+r'\s*\(',masked)
    if not match: raise ValueError('Missing native function '+name)
    brace=masked.index('{',match.start()); depth=1; end=brace+1
    while depth:
        depth+=(masked[end]=='{')-(masked[end]=='}'); end+=1
    return source[match.start():end]


@unittest.skipUnless(COMPILER,'Native host GCC is required for the controlled-clock harness')
class NativeTimingTests(unittest.TestCase):
    def test_original_order_endpoints_and_post_measurement_io(self):
        source=(ROOT/'src/tests/bench486/bench486_harness.c').read_text(encoding='utf-8')
        end=source.index('} bench486_timedemo_fps_stats_t;')+len('} bench486_timedemo_fps_stats_t;')
        start=source.rfind('typedef struct',0,end)
        stats_type=source[start:end]
        limit=re.search(r'#define BENCH486_TIMEDEMO_MAX_FRAMES (\d+)',(ROOT/'src/tests/bench486/bench486_profile.h').read_text())[1]
        harness=r'''
#include <assert.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
typedef int qboolean;
#define true 1
#define false 0
static double clock_now;
static int reads, writes;
static FILE *frame_file;
static double Sys_FloatTime(void) { reads++; return clock_now; }
static int Sys_FileOpenWrite(char *name) { assert(!strcmp(name,"FRAMTIME.CSV"));frame_file=fopen(name,"wb");return frame_file?1:-1; }
static void Sys_FileWrite(int h,void *bytes,int count) { assert(h==1);writes++;assert(fwrite(bytes,1,count,frame_file)==(unsigned)count); }
static void Sys_FileClose(int h) { assert(h==1);fclose(frame_file); }
static int Q_strlen(char *s) { return strlen(s); }
static void Bench486TimedemoReportText(int h,char *s) { (void)h;(void)s; }
'''
        harness+=f'\n#define BENCH486_TIMEDEMO_MAX_FRAMES {limit}\n'
        harness+=stats_type+r'''
static float bench486_timedemo_frame_seconds[BENCH486_TIMEDEMO_MAX_FRAMES];
static float bench486_timedemo_frame_elapsed[BENCH486_TIMEDEMO_MAX_FRAMES];
static unsigned long bench486_timedemo_measured_frames,bench486_timedemo_stored_frames;
static unsigned long bench486_timedemo_invalid_frames,bench486_timedemo_overflow_frames,bench486_timedemo_timer_reads;
static qboolean bench486_timedemo_stats_enabled,bench486_timedemo_stats_active,bench486_timedemo_frame_started;
static double bench486_timedemo_frame_start,bench486_timedemo_time_origin;
static void Bench486TimedemoComputeStats(int frames,double seconds,bench486_timedemo_fps_stats_t *stats) {
    unsigned i; (void)frames;(void)seconds;memset(stats,0,sizeof(*stats));
    /* The real summary destroys sample order too. Export must precede it. */
    for(i=0;i<bench486_timedemo_stored_frames;i++)bench486_timedemo_frame_seconds[i]=9999;
}
static void Bench486WriteTimedemoStatsJson(int frames,double seconds,bench486_timedemo_fps_stats_t *stats) {
    (void)frames;(void)seconds;(void)stats;
}
void Bench486TimedemoFrameEnd(void);
'''
        for name in ['Bench486TimedemoRecordFrame','Bench486ResetTimedemoStats','Bench486BeginTimedemoStats',
                     'Bench486TimedemoFrameStart','Bench486TimedemoFrameEnd','Bench486FinishTimedemoStats',
                     'Bench486WriteTimedemoStats']:
            harness+=extract(source,name)+'\n'
        harness+=r'''
int main(void) {
    Bench486TimedemoFrameStart();assert(reads==0);
    Bench486ResetTimedemoStats();
    clock_now=10;Bench486TimedemoFrameStart();Bench486BeginTimedemoStats();
    clock_now=10.02;Bench486TimedemoFrameEnd();
    clock_now=10.03;Bench486TimedemoFrameStart();clock_now=10.06;Bench486TimedemoFrameEnd();
    clock_now=10.07;Bench486TimedemoFrameStart();clock_now=10.08;Bench486TimedemoFrameEnd();
    Bench486FinishTimedemoStats(3);
    assert(reads==6 && bench486_timedemo_timer_reads==6 && writes==0);
    assert(bench486_timedemo_measured_frames==3 && bench486_timedemo_stored_frames==3);
    Bench486WriteTimedemoStats(-1,3,.08);assert(writes==4);
    assert(bench486_timedemo_frame_seconds[0]==9999);
    Bench486ResetTimedemoStats();
    Bench486TimedemoRecordFrame(0,0);assert(bench486_timedemo_invalid_frames==1);
    bench486_timedemo_stored_frames=BENCH486_TIMEDEMO_MAX_FRAMES;
    Bench486TimedemoRecordFrame(.01,.01);assert(bench486_timedemo_overflow_frames==1);
    puts("native capture/export PASS");return 0;
}
'''
        with tempfile.TemporaryDirectory(prefix='native frame timing ') as directory:
            root=Path(directory); c=root/'fixture.c'; exe=root/'fixture.exe';c.write_text(harness,encoding='utf-8')
            env=os.environ.copy();env['PATH']=str(Path(COMPILER).parent)+os.pathsep+env.get('PATH','')
            result=subprocess.run([COMPILER,str(c),'-o',str(exe)],env=env,capture_output=True,text=True)
            self.assertEqual(result.returncode,0,result.stderr)
            result=subprocess.run([str(exe)],cwd=root,env=env,capture_output=True,text=True)
            self.assertEqual(result.returncode,0,result.stderr)
            with (root/'FRAMTIME.CSV').open(newline='') as stream: rows=list(csv.DictReader(stream))
            self.assertEqual([int(row['sample_index']) for row in rows],[0,1,2])
            for row,duration,elapsed in zip(rows,[.02,.03,.01],[.02,.06,.08]):
                self.assertAlmostEqual(float(row['frame_seconds']),duration,places=7)
                self.assertAlmostEqual(float(row['elapsed_seconds']),elapsed,places=7)


if __name__=='__main__':unittest.main()
