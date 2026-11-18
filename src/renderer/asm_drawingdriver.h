/* Audited 32-bit drawing-driver storage contracts. */
/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
#ifndef ASM_DRAWINGDRIVER_H
#define ASM_DRAWINGDRIVER_H
#define dd_pointer_size 4
#define dd_integer_size 4
#define dd_float_size 4
#define dd_double_size 8
#define dd_viddef_t_buffer 0
#define dd_viddef_t_rowbytes 16
#define dd_viddef_t_width 20
#define dd_viddef_t_height 24
#define dd_refdef_t_vrect 0
#define dd_refdef_t_vrectright 40
#define dd_refdef_t_vrectbottom 44
#define dd_vrect_t_x 0
#define dd_vrect_t_y 4
#define dd_vrect_t_width 8
#define dd_vrect_t_height 12
#define dd_cvar_t_value 16
#define dd_surfcache_t_next 0
#define dd_surfcache_t_owner 4
#define dd_surfcache_t_size 28
#define dd_WARP_WIDTH 320
#define dd_MAXHEIGHT 1024
#define dd_id386 1
#ifndef __ASSEMBLER__
#include <stddef.h>
#define DD_LAYOUT(name,condition) typedef char dd_layout_##name[(condition)?1:-1]
DD_LAYOUT(pointer_size,sizeof(void *)==dd_pointer_size);
DD_LAYOUT(integer_size,sizeof(int)==dd_integer_size);
DD_LAYOUT(float_size,sizeof(float)==dd_float_size);
DD_LAYOUT(double_size,sizeof(double)==dd_double_size);
DD_LAYOUT(viddef_t_buffer,offsetof(viddef_t,buffer)==dd_viddef_t_buffer);
DD_LAYOUT(viddef_t_rowbytes,offsetof(viddef_t,rowbytes)==dd_viddef_t_rowbytes);
DD_LAYOUT(viddef_t_width,offsetof(viddef_t,width)==dd_viddef_t_width);
DD_LAYOUT(viddef_t_height,offsetof(viddef_t,height)==dd_viddef_t_height);
DD_LAYOUT(refdef_t_vrect,offsetof(refdef_t,vrect)==dd_refdef_t_vrect);
DD_LAYOUT(refdef_t_vrectright,offsetof(refdef_t,vrectright)==dd_refdef_t_vrectright);
DD_LAYOUT(refdef_t_vrectbottom,offsetof(refdef_t,vrectbottom)==dd_refdef_t_vrectbottom);
DD_LAYOUT(vrect_t_x,offsetof(vrect_t,x)==dd_vrect_t_x);
DD_LAYOUT(vrect_t_y,offsetof(vrect_t,y)==dd_vrect_t_y);
DD_LAYOUT(vrect_t_width,offsetof(vrect_t,width)==dd_vrect_t_width);
DD_LAYOUT(vrect_t_height,offsetof(vrect_t,height)==dd_vrect_t_height);
DD_LAYOUT(cvar_t_value,offsetof(cvar_t,value)==dd_cvar_t_value);
DD_LAYOUT(surfcache_t_next,offsetof(surfcache_t,next)==dd_surfcache_t_next);
DD_LAYOUT(surfcache_t_owner,offsetof(surfcache_t,owner)==dd_surfcache_t_owner);
DD_LAYOUT(surfcache_t_size,offsetof(surfcache_t,size)==dd_surfcache_t_size);
DD_LAYOUT(WARP_WIDTH,WARP_WIDTH==dd_WARP_WIDTH);
DD_LAYOUT(MAXHEIGHT,MAXHEIGHT==dd_MAXHEIGHT);
#undef DD_LAYOUT
extern pixel_t *d_driver_viewspan_base;
extern int d_driver_viewspan_stride;
extern qboolean d_driver_protectset8;
void D_Patch(void);
#ifdef BENCH486
void Bench486DriverRegister(cvar_t *);
void Bench486DriverMakeWritable(int,int);
void D_Patch_Driver_C(void);
#endif
#endif
#endif
