"""Exercise the actual native coarse profiler's nested entry/leave bookkeeping."""
import importlib.util
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('native_capture_test',ROOT/'tools/test-frame-timing-export.py')
helper=importlib.util.module_from_spec(spec);spec.loader.exec_module(helper)


@unittest.skipUnless(helper.COMPILER,'Host GCC is required')
class CoarseProfileTests(unittest.TestCase):
    def test_selected_child_survives_unselected_parent_and_balances(self):
        header=(ROOT/'src/tests/bench486/bench486_profile.h').read_text()
        start=header.index('typedef enum',header.index('#ifdef PROFILE486'))
        end=header.index('} bench486_profile_node_id_t;',start)+len('} bench486_profile_node_id_t;')
        source=(ROOT/'src/tests/bench486/bench486_harness.c').read_text()
        declarations=source[source.index('#define BENCH486_PROFILE_MAX_DEPTH'):source.index('\n#endif',source.index('#define BENCH486_PROFILE_MAX_DEPTH'))]
        harness='''#include <assert.h>
#include <stdlib.h>
#include <string.h>
static double clock_now;
static double Sys_FloatTime(void) {clock_now+=.001;return clock_now;}
static void Sys_Error(char *s) {(void)s;abort();}
static int bench486_profile_frame_active,bench486_profile_coarse_active;
static int bench486_profile_coarse_mode,bench486_profile_filter[128],bench486_profile_filter_depth;
static unsigned long bench486_clipvertex_seen_world[2048];
'''+header[start:end]+'\n'+declarations+'\n'
        for name in ['Bench486ProfileEnter','Bench486ProfileLeave','Bench486ProfileDiscardOpenScopes','Bench486BeginTimedemoProfile']:
            harness+=helper.extract(source,name)+'\n'
        harness+='''
int main(void) {
    bench486_profile_coarse_mode=bench486_profile_coarse_active=1;
    Bench486ProfileEnter(BENCH486_PROFILE_FRAME);
    Bench486ProfileEnter(BENCH486_PROFILE_RENDERER);
    Bench486ProfileEnter(BENCH486_PROFILE_ALIAS_MODEL);
    Bench486ProfileEnter(BENCH486_PROFILE_SOUND_MIX);
    Bench486ProfileLeave();Bench486ProfileLeave();Bench486ProfileLeave();Bench486ProfileLeave();
    assert(bench486_profile_timer_reads==6);
    assert(bench486_profile_stats[BENCH486_PROFILE_ALIAS_MODEL].calls==0);
    assert(bench486_profile_stats[BENCH486_PROFILE_SOUND_MIX].calls==1);
    assert(bench486_profile_edges[BENCH486_PROFILE_RENDERER][BENCH486_PROFILE_SOUND_MIX].calls==1);
    assert(bench486_profile_stack_depth==0 && bench486_profile_filter_depth==0);
    assert(bench486_profile_bad_leaves==0);
    /* Start during client-read/game scopes that entered while inactive. */
    bench486_profile_coarse_active=0;
    Bench486ProfileEnter(BENCH486_PROFILE_GAME);Bench486ProfileEnter(BENCH486_PROFILE_CLIENT_READ);
    Bench486BeginTimedemoProfile();
    assert(bench486_profile_pending_leaves==2);
    Bench486ProfileLeave();Bench486ProfileLeave();assert(bench486_profile_stack_depth==1);
    Bench486ProfileEnter(BENCH486_PROFILE_SCREEN);Bench486ProfileLeave();Bench486ProfileLeave();
    assert(bench486_profile_stack_depth==0 && bench486_profile_filter_depth==0);
    Bench486ProfileEnter(BENCH486_PROFILE_FRAME);Bench486ProfileEnter(BENCH486_PROFILE_SETUP);
    Bench486ProfileDiscardOpenScopes();
    assert(!bench486_profile_filter_depth && !bench486_profile_stack_depth);
    bench486_profile_coarse_mode=2;
    Bench486ProfileEnter(BENCH486_PROFILE_FRAME);
    Bench486ProfileEnter(BENCH486_PROFILE_WORLD_BSP);
    Bench486ProfileEnter(BENCH486_PROFILE_RENDERFACE);
    Bench486ProfileEnter(BENCH486_PROFILE_TEXTURE_SPANS);
    Bench486ProfileLeave();Bench486ProfileLeave();Bench486ProfileLeave();Bench486ProfileLeave();
    assert(bench486_profile_stats[BENCH486_PROFILE_TEXTURE_SPANS].calls==1);
    assert(!bench486_profile_stats[BENCH486_PROFILE_RENDERFACE].calls);
    assert(!bench486_profile_frame_active && !bench486_profile_stack_depth && !bench486_profile_filter_depth);
    bench486_profile_coarse_active=0;
    Bench486ProfileEnter(BENCH486_PROFILE_FRAME);Bench486ProfileLeave();
    assert(!bench486_profile_stack_depth && !bench486_profile_bad_leaves);
    bench486_profile_coarse_mode=0;
    Bench486BeginTimedemoProfile();
    Bench486ProfileLeave();Bench486ProfileLeave();
    Bench486ProfileEnter(BENCH486_PROFILE_SCREEN);Bench486ProfileLeave();Bench486ProfileLeave();
    assert(!bench486_profile_stack_depth && !bench486_profile_bad_leaves && !bench486_profile_pending_leaves);
    return 0;
}
'''
        with tempfile.TemporaryDirectory(prefix='coarse profile ') as directory:
            p=Path(directory);(p/'fixture.c').write_text(harness)
            env=os.environ.copy();env['PATH']=str(Path(helper.COMPILER).parent)+os.pathsep+env['PATH']
            result=subprocess.run([helper.COMPILER,str(p/'fixture.c'),'-o',str(p/'fixture.exe')],capture_output=True,text=True,env=env)
            self.assertEqual(result.returncode,0,result.stderr)
            result=subprocess.run([str(p/'fixture.exe')],capture_output=True,text=True,env=env)
            self.assertEqual(result.returncode,0,result.stderr)


if __name__=='__main__':unittest.main()
