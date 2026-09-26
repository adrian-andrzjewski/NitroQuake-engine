"""Test actual DOS report and pause functions with mocked DPMI and IRQ input."""
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
src = (ROOT / 'WinQuake/sys_dos.c').read_text()
start = src.index('#ifndef BENCH486\n/* IRQ 9')
end = src.index('void Sys_SendKeyEvents', start)
prefix = r'''
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#define KEYBUF_SIZE 256
static volatile unsigned char keybuf[256];
static volatile int keybuf_head;
static int keybuf_tail,isDedicated,scenario;
static struct { int memsize; } quakeparms = {8388608};
typedef struct { unsigned char major,minor,cpu; } __dpmi_version_ret;
typedef struct { unsigned long total_number_of_physical_pages; } __dpmi_free_mem_info;
typedef struct { struct {unsigned ax,flags;} x; struct {unsigned al,ah;} h; } __dpmi_regs;
static int COM_CheckParm(const char *s) { (void)s;return scenario>=10; }
static int __dpmi_get_version(__dpmi_version_ret *v) {
 if(scenario==1)return -1;
 v->major=0;v->minor=90;v->cpu=scenario==2?255:4;return 0;
}
static int __dpmi_int(int n,__dpmi_regs *r) {
 assert(n==0x21 && r->x.ax==0x3000);
 if(scenario==1)return -1;r->h.al=6;r->h.ah=22;return 0;
}
static int __dpmi_get_free_memory_information(__dpmi_free_mem_info *m) {
 if(scenario==1)return -1;
 m->total_number_of_physical_pages=scenario==2?0xffffffffUL:scenario==3?0xfffffffeUL:4096;
 return 0;
}
static int __dpmi_get_page_size(unsigned long *p) {
 if(scenario==4)return -1;
 *p=scenario==5?0:scenario==6?0xffffffffUL:scenario==7?3000:4096;
 return 0;
}
'''
main = r'''
int main(int argc,char **argv) {
 scenario=argc>1?atoi(argv[1]):0;isDedicated=scenario==11;
 if(scenario==12) {
  unsigned char sequence[]={0x2a,0xe0,0x1c,0xe0,0x1c,0xe0,0x9c,0xaa};
  memcpy((void*)keybuf,sequence,sizeof(sequence));keybuf_head=sizeof(sequence);
 }
 if(scenario==13) { keybuf[0]=0x1c;keybuf_head=1; }
 if(scenario==14) {
  unsigned char sequence[]={0xe1,0x1d,0x45,0xe1,0x9d,0xc5,0x1c,0x9c};
  memcpy((void*)keybuf,sequence,sizeof(sequence));keybuf_head=sizeof(sequence);
 }
 Sys_ReportSystem("VESA linear",0x100,320);
 Sys_ReportSystem("VGA fallback",0,0);
 assert(keybuf_head==keybuf_tail || scenario==13);
 puts("RESUMED");return 0;
}
'''
vid = (ROOT / 'WinQuake/vid_dos.c').read_text()
init = vid[vid.index('void    VID_Init'):vid.index('VID_GetModePtr')]
assert init.index('VID_InitExtra ();') < init.index('VID_ReportSystem ();') < init.index('VID_SetMode (')
assert src.index('dos_registerintr(9, TrapKey)') < src.index('Host_Init(&quakeparms)')
with tempfile.TemporaryDirectory(prefix='quake-sysinfo-') as tmp:
    c = Path(tmp) / 'sysinfo.c'
    c.write_text(prefix + src[start:end] + main)
    for benchmark in (False, True):
        exe = Path(tmp) / ('bench.exe' if benchmark else 'normal.exe')
        subprocess.run(['gcc', '-std=c99', '-O2', *(['-DBENCH486'] if benchmark else []),
                        str(c), '-o', str(exe)], check=True)
        for case in range(15):
            if benchmark and case in (12,13,14):
                continue
            try:
                output = subprocess.check_output([str(exe), str(case)], timeout=1, text=True)
            except subprocess.TimeoutExpired:
                assert not benchmark and case in (10,13), case
                continue
            assert benchmark or case not in (10,13)
            assert output.count('--- DOS system summary ---') == 1
            assert all(len(line)<=80 and line.isascii() for line in output.splitlines())
            assert 'Quake heap (allocated): 8192 KiB' in output
            if case in (1,2,4,5,6,7):
                assert 'Physical RAM (DPMI reported): unknown' in output
            if case == 1:
                assert 'CPU (DPMI): unknown' in output and 'DOS: unknown; DPMI: unknown' in output
            if case == 2:
                assert 'CPU (DPMI): unknown' in output
            if case == 3:
                assert '17179869176 KiB' in output
            if case == 11:
                assert 'Video: disabled (dedicated)' in output
            if benchmark or case == 11:
                assert 'Press and release' not in output
print('PASS: ordering/once, query failures, unsupported fields, wide RAM arithmetic,')
print('      ASCII layout, default/dedicated/benchmark no pause, Enter release and IRQ input')
