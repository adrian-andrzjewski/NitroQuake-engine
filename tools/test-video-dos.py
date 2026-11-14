"""Host-side BIOS fault tests of the actual DOS video C functions.

Requires a native GCC. Hardware/assembly presentation still needs DOSBox/486
validation; the mock copier implements the existing assembly's dword contract.
"""
from pathlib import Path
import re
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def function(source, name):
    signature = re.compile(r"(?m)^(?:int|void|vmode_t \*)\s+" + re.escape(name) + r"\s*\(")
    match = signature.search(source)
    if match is None:
        aliases = re.findall(
            r"(?m)^\s*#define\s+([A-Za-z_]\w*)\s+" + re.escape(name) + r"\s*$",
            source,
        )
        for alias in aliases:
            source = re.sub(r"\b" + re.escape(alias) + r"\b", name, source)
        match = signature.search(source)
    if match is None:
        raise ValueError("could not find C function %s" % name)
    start = match.start()
    brace = source.index("{", start)
    depth = 1
    end = brace + 1
    while depth:
        depth += (source[end] == "{") - (source[end] == "}")
        end += 1
    return source[start:end]


prefix = r'''
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
typedef unsigned char byte;
typedef int qboolean;
#define true 1
#define false 0
#define UNUSED(x) (void)(x)
#define MAXWIDTH 1280
#define MAXHEIGHT 1024
#define WARP_WIDTH 320
#define WARP_HEIGHT 200
#define LittleLong(x) (x)
#define Q_memcpy memcpy
typedef struct { float value; } cvar_t;
typedef struct vrect_s { int x,y,width,height; struct vrect_s *pnext; } vrect_t;
typedef struct { unsigned width,height,rowbytes; int numpages,conrowbytes,conwidth,conheight;
 int maxwarpwidth,maxwarpheight,fullbright,recalc_refdef; float aspect;
 byte *buffer,*conbuffer,*direct,*colormap; } viddef_t;
#include "video/vid_dos.h"
typedef struct { unsigned long address,size; } __dpmi_meminfo;
typedef struct { struct { unsigned ax,bx,cx,dx,es,di; } x; } regs_t;
regs_t regs;
static byte memory[0x500000], ram[0x200000], biosinfo[256];
static int allocations, frees, maps, unmaps, bankcalls, startcalls, modecalls;
static int fail_alloc, fail_map, fail_mode, fail_bank, fail_palette, fail_ram;
static int copycalls, copywidth, copyheight, planar_calls, vga_calls, palette_calls, probes;
static int many_modes, banked_bios, no_vesa, lastbank;
static unsigned alloc_cursor;
static byte cmap[9000];
byte *host_colormap = cmap;
vmode_t *pvidmodes,*pcurrentmode,*VGA_pcurmode;
int numvidmodes,vid_modenum,vid_realmode;
int VGA_width,VGA_height,VGA_rowbytes,VGA_bufferrowbytes,VGA_planar;
byte *VGA_pagebase;
void *vid_surfcache;
int vid_surfcachesize;
cvar_t vid_mode,vid_wait,vid_nopageflip,_vid_wait_override,_vid_default_mode;
static int firstupdate=1,startup_mode_requested,host_framecount,vid_testingmode;
static int force_std,explicit_mode;
static unsigned report_mode,report_pitch;
static char report_video[80];
static void Sys_ReportSystem(const char *v,unsigned m,unsigned p) {
 strcpy(report_video,v);report_mode=m;report_pitch=p;
 assert(!modecalls && !vga_calls);
}
static double realtime,vid_testendtime;
#define BENCH486_PROFILE_ENTER(x)
#define BENCH486_PROFILE_WORK(x,y,z)
#define BENCH486_PROFILE_LEAVE()
static int COM_CheckParm(const char *s) { return !strcmp(s,"-stdvid")?force_std:explicit_mode; }
viddef_t vid;
byte vid_current_palette[768];
int nomodecheck,scr_disabled_for_loading;
static void Con_Printf(const char *f, ...) { (void)f; }
#define Con_SafePrintf Con_Printf
static void Sys_Error(const char *f, ...) { fprintf(stderr,"%s\n",f); abort(); }
static void Cvar_SetValue(const char *s,float v) {
 if (!strcmp(s,"vid_mode")) vid_mode.value=v;
 if (!strcmp(s,"vid_wait")) vid_wait.value=v;
 if (!strcmp(s,"_vid_default_mode")) _vid_default_mode.value=v;
}
static void *real2ptr(unsigned long a) { assert(a < sizeof(memory)); return memory+a; }
static unsigned long ptr2real(void *p) { return (byte*)p-memory; }
static void *dos_getmemory(int n) {
 if (++allocations == fail_alloc) return NULL;
 alloc_cursor += (n+15)&~15; return memory+alloc_cursor-n;
}
static void dos_freememory(void *p) { assert(p); frees++; }
static int __dpmi_physical_address_mapping(__dpmi_meminfo *m) {
 if (fail_map) return -1; maps++; m->address=0x100000; return 0;
}
static int __dpmi_free_physical_address_mapping(__dpmi_meminfo *m) { (void)m; unmaps++; return 0; }
static void word(byte *p,unsigned v) { p[0]=v; p[1]=v>>8; }
static void dos_int86(int irq) {
 byte *b=memory+(regs.x.es<<4)+regs.x.di; unsigned ax=regs.x.ax; (void)irq;
 regs.x.ax=0x4f;
 switch(ax) {
 case 0x4f00:
  if(no_vesa) { regs.x.ax=0x14f; break; }
  memcpy(b,"VESA",4); word(b+4,0x200); word(b+16,0x800); word(b+18,64);
  for(int i=0;i<(many_modes?33:1);i++) word(memory+0x8000+i*2,0x100+i);
  word(memory+0x8000+(many_modes?33:1)*2,0xffff); break;
 case 0x4f01:
  memcpy(b,biosinfo,256);
  if(many_modes && regs.x.cx<0x11e) { word(b+18,640); word(b+20,480); word(b+16,640); }
  if(banked_bios || (many_modes && regs.x.cx==0x11e)) word(b,0x19);
  break;
 case 0x4f02: modecalls++; if(fail_mode) regs.x.ax=0x14f; break;
 case 0x4f05: bankcalls++; lastbank=regs.x.bx; assert(regs.x.dx==0); if(fail_bank) regs.x.ax=0x14f; break;
 case 0x4f07: startcalls++; break;
 case 0x4f09: palette_calls++; if(fail_palette) regs.x.ax=0x14f; break;
 default: abort();
 }
}
static double Sys_FloatTime(void) { static double t; return t+=0.2; }
static int inportb(int p) { (void)p; return (++probes & 1)?9:0; }
void VGA_WaitVsync(void) {}
static byte backingbuf[48*24];
#define SC_INDEX 0
#define SC_DATA 1
#define MAP_MASK 2
#define GC_INDEX 3
#define GC_DATA 4
#define READ_MAP 5
static void outportb(int p,int v) { (void)p;(void)v;abort(); } // no planar IO in these tests
qboolean VGA_FreeAndAllocVidbuffer(viddef_t *v,int ram_requested) {
 if(fail_ram && vga_calls==0) return 0;
 if(ram_requested) v->buffer=v->conbuffer=ram; return 1;
}
static void D_InitCaches(void*p,int n) { (void)p;(void)n; }
void VGA_UpdateLinearScreen(void*s,void*d,int w,int h,int sp,int dp) {
 assert(w>0 && h>0 && !(w&3)); copycalls++;copywidth=w;copyheight=h;
 for(int y=0;y<h;y++) memcpy((byte*)d+y*dp,(byte*)s+y*sp,w);
}
void VGA_UpdatePlanarScreen(void*p) { (void)p; planar_calls++; }
static vmode_t vga;
static int fake_vga(viddef_t *v,vmode_t*m) {
 (void)m;vga_calls++;v->buffer=v->conbuffer=ram;v->direct=memory+0xa0000;
 v->numpages=1;return 1;
}
static void fake_palette(viddef_t*v,vmode_t*m,byte*p) { (void)v;(void)m;(void)p; }
static void fake_swap(viddef_t*v,vmode_t*m,vrect_t*r) { (void)v;(void)m;(void)r; }
vmode_t *VID_GetModePtr(int n) { vmode_t *m=pvidmodes;while(n--)m=m->pnext;assert(m);return m; }
static char *VID_ModeInfo(int n,char **h) { (void)n;(void)h;return "test"; }
'''

tests = r'''
static void reset(void) {
 VID_ShutdownExtra(); memset(memory,0,sizeof(memory)); memset(biosinfo,0,256);
 memset(&vid,0,sizeof(vid)); memset(vesa_modes,0,sizeof(vesa_modes));
 memset(&vga,0,sizeof(vga));
 vga.width=320;vga.height=200;vga.rowbytes=320;vga.aspect=0.833333;
 vga.setmode=fake_vga;vga.setpalette=fake_palette;
 vga.swapbuffers=fake_swap;
 allocations=frees=maps=unmaps=bankcalls=startcalls=modecalls=0;
 fail_alloc=fail_map=fail_mode=fail_bank=fail_palette=fail_ram=0;
  copycalls=planar_calls=vga_calls=palette_calls=probes=many_modes=banked_bios=no_vesa=0;
 alloc_cursor=0x1000; pvidmodes=NULL;pcurrentmode=NULL;numvidmodes=0;
 vid_mode.value=vid_wait.value=_vid_wait_override.value=0;
 vid_modenum=vid_realmode=0;scr_disabled_for_loading=nomodecheck=0;
 firstupdate=1;startup_mode_requested=host_framecount=vid_testingmode=0;
 force_std=explicit_mode=0;_vid_default_mode.value=0;
 word(biosinfo,0x99);biosinfo[2]=7;word(biosinfo+4,64);word(biosinfo+6,64);
 word(biosinfo+8,0xa000);word(biosinfo+16,320);word(biosinfo+18,320);
 word(biosinfo+20,200);biosinfo[24]=1;biosinfo[25]=8;biosinfo[27]=4;
 biosinfo[29]=2;word(biosinfo+42,0xe000);
}
static void discover(void) { VID_InitExtra();vga.pnext=pvidmodes;pvidmodes=&vga;numvidmodes++; }
int main(void) {
 vesa_info_t m; int w,h;
 reset();discover();VID_ReportSystem();
 assert(!strcmp(report_video,"VESA linear") && report_mode==0x100 && report_pitch==320);
 reset();word(biosinfo,0x19);discover();VID_ReportSystem();
 assert(!strcmp(report_video,"VESA banked") && report_pitch==320);
 reset();no_vesa=1;discover();VID_ReportSystem();
 assert(!strcmp(report_video,"VGA fallback") && !report_pitch);
 reset();force_std=1;pvidmodes=&vga;numvidmodes=1;VID_ReportSystem();
 assert(strstr(report_video,"forced VGA") && !allocations);
 reset(); assert(VESA_Decode(biosinfo,0x400000,&m));assert(m.pages==1 && m.linear);
 for(int off=24;off<=27;off++) { if(off==26)continue;byte save=biosinfo[off];biosinfo[off]=0;
  assert(!VESA_Decode(biosinfo,0x400000,&m));biosinfo[off]=save; }
 for(int bit=1;bit<=16;bit*=2) { if(bit==2||bit==4)continue;word(biosinfo,0x99^bit);
  assert(!VESA_Decode(biosinfo,0x400000,&m)); } word(biosinfo,0x99);
 word(biosinfo+16,319);assert(!VESA_Decode(biosinfo,0x400000,&m));
 word(biosinfo+16,328);assert(VESA_Decode(biosinfo,0x400000,&m));
 assert(!VESA_Decode(biosinfo,65535,&m));
 word(biosinfo,0x19);assert(!VESA_Decode(biosinfo,0x400000,&m)); // bank overflow
 word(biosinfo+16,320);assert(VESA_Decode(biosinfo,0x400000,&m));
 biosinfo[2]=5;assert(!VESA_Decode(biosinfo,0x400000,&m)); // read required for direct rects
 biosinfo[3]=7;word(biosinfo+10,0xb000);assert(VESA_Decode(biosinfo,0x400000,&m));assert(m.window==1 && m.segment==0xb000);
 word(biosinfo+4,0);assert(!VESA_Decode(biosinfo,0x400000,&m));
 w=320;h=200;VESA_CopyShape(&w,&h,320,320);assert(w==64000 && h==1);
 w=320;h=200;VESA_CopyShape(&w,&h,320,328);assert(w==320 && h==200);
 for(int fault=1;fault<=3;fault++) {reset();fail_alloc=fault;discover();assert(numvidmodes==1 && frees==2);}
 reset();no_vesa=1;discover();assert(numvidmodes==1 && frees==3 && !VID_ExtraDefaultMode());
 reset();many_modes=1;discover();assert(numvidmodes==33 && VID_ExtraDefaultMode()==32);
 VID_ShutdownExtra();assert(frees==3);
 // Startup and runtime choices use the actual VID_Update state machine.
 for(int choice=0;choice<7;choice++) {
  reset();discover();assert(VID_SetMode(0,vid_current_palette));
  if(choice==1)force_std=1;
  if(choice==2)explicit_mode=1;
  if(choice==3)_vid_default_mode.value=1;
  if(choice==4)_vid_default_mode.value=-1;
  if(choice==5) { vid_mode.value=1;VID_Update(NULL);assert(vid_modenum==1); }
  if(choice==6)fail_mode=1;
  host_framecount=1;VID_Update(NULL);
  assert(vid_modenum==((choice==1||choice==2||choice==6)?0:1));
  int attempts=modecalls;VID_Update(NULL);assert(modecalls==attempts);
  // Explicit later mode changes remain available, including mode zero.
  vid_mode.value=0;VID_Update(NULL);assert(vid_modenum==0);
 }
 // Actual initialization, palette, bounded recovery, and mapping ownership.
 for(int fault=0;fault<6;fault++) {
  reset();if(fault==4)banked_bios=1;discover();
  fail_ram=fault==1;fail_map=fault==2;fail_mode=fault==3;fail_bank=fault==4;fail_palette=fault==5;
  assert(VID_SetMode(1,vid_current_palette)==(fault==0));
  assert(vid_modenum==(fault?0:1));assert(vga_calls==(fault?1:0));
  assert(!scr_disabled_for_loading && !nomodecheck);
  if(fault)assert(maps==unmaps);
  else {assert(vid.numpages==1 && !bankcalls && !startcalls && !probes);
   assert(VID_SetMode(0,vid_current_palette));assert(maps==unmaps);}
  VID_ShutdownExtra();assert(frees==3);
 }
 reset();banked_bios=1;biosinfo[2]=0;biosinfo[3]=7;word(biosinfo+10,0xb000);discover();
 assert(VID_SetMode(1,vid_current_palette));assert(bankcalls==1 && lastbank==1);
 vrect_t bankrect={0,0,320,200,NULL};
 VID_ExtraSwapBuffers(&vid,pcurrentmode,&bankrect);assert(bankcalls==1 && !startcalls);
 byte icon[24*24];memset(icon,0x5a,sizeof(icon));memset(vid.direct,0xcd,64000);
 pcurrentmode->begindirectrect(&vid,pcurrentmode,296,0,icon,24,24);
 for(int y=0;y<24;y++)assert(!memcmp(vid.direct+y*320+296,icon+y*24,24));
 pcurrentmode->enddirectrect(&vid,pcurrentmode,296,0,24,24);
 for(int i=0;i<64000;i++)assert(vid.direct[i]==0xcd);
 assert(bankcalls==1 && !startcalls);
 // VBE palette is 6-bit B,G,R,0; runtime palette failure also recovers.
 for(int i=0;i<768;i++)vid_current_palette[i]=(byte)i;
 VID_SetPalette(vid_current_palette);
 for(int i=0;i<256;i++) {
  assert(ppal[i*4]==(vid_current_palette[i*3+2]>>2));
  assert(ppal[i*4+1]==(vid_current_palette[i*3+1]>>2));
  assert(ppal[i*4+2]==(vid_current_palette[i*3]>>2));assert(!ppal[i*4+3]);
 }
 fail_palette=1;VID_SetPalette(vid_current_palette);assert(vid_modenum==0);
 VID_SetPalette(vid_current_palette);assert(vga_calls==1);
 reset();discover();_vid_wait_override.value=1;
 assert(VID_SetMode(1,vid_current_palette));assert(vid_wait.value==1 && probes);
 assert(!startcalls && !bankcalls);
 // Sentinel checked copies: whole screen, partial/odd rectangles, padded pitch.
 for(int padded=0;padded<=1;padded++) {
  reset();word(biosinfo+16,padded?328:320);discover();assert(VID_SetMode(1,vid_current_palette));
  for(int i=0;i<64000;i++)ram[i]=(byte)(i*7+3);
  memset(VGA_pagebase-16,0xcd,65632);
  vrect_t r={0,0,320,200,NULL};VID_ExtraSwapBuffers(&vid,pcurrentmode,&r);
  assert(copycalls==1 && copywidth==(padded?320:64000) && copyheight==(padded?200:1));
  for(int y=0;y<200;y++) {assert(!memcmp(VGA_pagebase+y*VGA_rowbytes,ram+y*320,320));
   if(padded)for(int x=320;x<328;x++)assert(VGA_pagebase[y*328+x]==0xcd);}
  for(int i=1;i<=16;i++)assert(VGA_pagebase[-i]==0xcd);
  assert(VGA_pagebase[200*VGA_rowbytes]==0xcd);
  memset(VGA_pagebase,0xcd,65600);r.x=3;r.y=4;r.width=7;r.height=2;
  VID_ExtraSwapBuffers(&vid,pcurrentmode,&r);
  for(int y=0;y<200;y++)for(int x=0;x<VGA_rowbytes;x++)
   assert(VGA_pagebase[y*VGA_rowbytes+x]==((y>=4&&y<6&&x>=3&&x<10)?ram[y*320+x]:0xcd));
  int old=copycalls;r.x=319;VID_ExtraSwapBuffers(&vid,pcurrentmode,&r);assert(copycalls==old);
  r.x=0;r.width=321;VID_ExtraSwapBuffers(&vid,pcurrentmode,&r);assert(copycalls==old);
  assert(!bankcalls && !startcalls && !probes);
 }
  // Direct standard-VGA linear presentation coverage.
  reset();memset(ram,0,64000);for(int i=0;i<64000;i++)ram[i]=(byte)(i*11+5);
  memset(memory+0xa0000,0xcd,64000);vid.buffer=ram;vid.width=320;vid.height=200;
  vid.rowbytes=320;vid.numpages=1;VGA_pagebase=memory+0xa0000;
  VGA_rowbytes=320;VGA_planar=0;copycalls=0;planar_calls=0;
  vrect_t full={0,0,320,200,NULL};VGA_SwapBuffersCopy(&vid,NULL,&full);
  assert(copycalls==1 && copywidth==320 && copyheight==200);
  assert(!memcmp(VGA_pagebase,ram,64000));
  memset(VGA_pagebase,0xcd,64000);copycalls=0;
  vrect_t partial={8,4,16,2,NULL};VGA_SwapBuffersCopy(&vid,NULL,&partial);
  assert(copycalls==1 && copywidth==16 && copyheight==2);
  vrect_t second={24,8,16,2,NULL};partial.pnext=&second;copycalls=0;
  VGA_SwapBuffersCopy(&vid,NULL,&partial);assert(copycalls==2);
  partial.pnext=NULL;vid.rowbytes=328;copycalls=0;
  VGA_SwapBuffersCopy(&vid,NULL,&full);assert(copycalls==1 && copywidth==320);
  vid.rowbytes=320;vid.numpages=2;copycalls=0;
  VGA_SwapBuffersCopy(&vid,NULL,&full);assert(copycalls==1);
  VGA_planar=1;copycalls=0;planar_calls=0;
  VGA_SwapBuffersCopy(&vid,NULL,&full);assert(!copycalls && planar_calls==1);

  VID_ShutdownExtra();puts("PASS: VBE rejection, VGA full-frame/fallback/planar copies, overflow discovery, allocation/mapping/mode/bank/palette recovery, copy boundaries and padded pitch");
 return 0;
}
'''

ext = (ROOT / "src/video/vid_ext.c").read_text()
ext = re.sub(r'^#include (?!"vid_vesa.h").*$', '', ext, flags=re.M)
dos = (ROOT / "src/video/vid_dos.c").read_text()
vga = (ROOT / "src/video/vid_vga.c").read_text()
source = (prefix + function(vga, "VGA_BeginDirectRect") + function(vga, "VGA_EndDirectRect")
          + function(vga, "VGA_SwapBuffersCopy")
          + ext + function(dos, "VID_SetMode") + function(dos, "VID_SetPalette")
          + function(dos, "VID_Update") + tests)
with tempfile.TemporaryDirectory(prefix="quake-video-") as tmp:
    cfile = Path(tmp) / "video.c"
    exe = Path(tmp) / "video.exe"
    cfile.write_text(source)
    subprocess.run(["gcc", "-std=c99", "-O2", "-Wall", "-Wextra",
                    "-Wno-misleading-indentation", "-I", str(ROOT / "src"),
                    str(cfile), "-o", str(exe)], check=True)
    subprocess.run([str(exe)], check=True)
