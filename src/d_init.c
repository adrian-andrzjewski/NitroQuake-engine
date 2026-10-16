/*
Copyright (C) 1996-1997 Id Software, Inc.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  

See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

*/
// d_init.c: rasterization driver initialization

#include "quakedef.h"
#include "d_local.h"
#include "asm_drawingdriver.h"

#define NUM_MIPS	4

cvar_t	d_subdiv16 = {"d_subdiv16", "1"};
cvar_t	d_mipcap = {"d_mipcap", "0"};
cvar_t	d_mipscale = {"d_mipscale", "1"};

surfcache_t		*d_initial_rover;
qboolean		d_roverwrapped;
int				d_minmip;
float			d_scalemip[NUM_MIPS-1];

static float	basemip[NUM_MIPS-1] = {1.0, 0.5*0.8, 0.25*0.8};
static pixel_t *viewspantable_base __attribute__((used));
static int viewspantable_stride __attribute__((used)) = -1;

#ifdef ASM486_DRAWING_DRIVER
/* Private canonical state shared with the maintained assembly implementation. */
__asm__(".globl _d_driver_viewspan_base\n.set _d_driver_viewspan_base,_viewspantable_base\n"
        ".globl _d_driver_viewspan_stride\n.set _d_driver_viewspan_stride,_viewspantable_stride");
#endif
extern int			d_aflatcolor;

void (*d_drawspans) (espan_t *pspan);


/*
===============
D_Init
===============
*/
#ifndef ASM486_DRAWING_DRIVER
void D_Init (void)
{

	r_skydirect = 1;

	Cvar_RegisterVariable (&d_subdiv16);
	Cvar_RegisterVariable (&d_mipcap);
	Cvar_RegisterVariable (&d_mipscale);

	/* Keep the legacy brush-submodel polygon pass opt-in and reproducible. */
	r_drawpolys = COM_CheckParm ("-drawpolys") != 0;
	r_worldpolysbacktofront = false;
	r_recursiveaffinetriangles = true;
	r_pixbytes = 1;
	r_aliasuvscale = 1.0;
}
#endif


/*
===============
D_CopyRects
===============
*/
#ifndef ASM486_DRAWING_DRIVER
void D_CopyRects (vrect_t *prects, int transparent)
{

// this function is only required if the CPU doesn't have direct access to the
// back buffer, and there's some driver interface function that the driver
// doesn't support and requires Quake to do in software (such as drawing the
// console); Quake will then draw into wherever the driver points vid.buffer
// and will call this function before swapping buffers

	UNUSED(prects);
	UNUSED(transparent);
}
#endif


/*
===============
D_EnableBackBufferAccess
===============
*/
#ifndef ASM486_DRAWING_DRIVER
void D_EnableBackBufferAccess (void)
{
	VID_LockBuffer ();
}
#endif


/*
===============
D_TurnZOn
===============
*/
#ifndef ASM486_DRAWING_DRIVER
void D_TurnZOn (void)
{
// not needed for software version
}
#endif


/*
===============
D_DisableBackBufferAccess
===============
*/
#ifndef ASM486_DRAWING_DRIVER
void D_DisableBackBufferAccess (void)
{
	VID_UnlockBuffer ();
}
#endif


/*
===============
D_SetupFrame
===============
*/
#ifndef ASM486_DRAWING_DRIVER
void D_SetupFrame (void)
{
	int		i;

	if (r_dowarp)
		d_viewbuffer = r_warpbuffer;
	else
		d_viewbuffer = (void *)(byte *)vid.buffer;

	if (r_dowarp)
		screenwidth = WARP_WIDTH;
	else
		screenwidth = vid.rowbytes;

	// Bake d_viewbuffer + d_scantable[v] so span ASM can load one row
	// pointer instead of adding the view base every span.  The table only
	// changes when the active buffer or its row stride changes.
	if (viewspantable_base != d_viewbuffer ||
			viewspantable_stride != screenwidth)
	{
		for (i=0 ; i<vid.height ; i++)
			viewspantable[i] = d_viewbuffer + d_scantable[i];
		viewspantable_base = d_viewbuffer;
		viewspantable_stride = screenwidth;
	}

	d_roverwrapped = false;
	d_initial_rover = sc_rover;

	d_minmip = d_mipcap.value;
	if (d_minmip > 3)
		d_minmip = 3;
	else if (d_minmip < 0)
		d_minmip = 0;

	for (i=0 ; i<(NUM_MIPS-1) ; i++)
		d_scalemip[i] = basemip[i] * d_mipscale.value;

#if	id386
				if (d_subdiv16.value)
					d_drawspans = D_DrawSpans16;
				else
					d_drawspans = D_DrawSpans8;
#else
				d_drawspans = D_DrawSpans8;
#endif

	d_aflatcolor = 0;
}
#endif


/*
===============
D_UpdateRects
===============
*/
#ifndef ASM486_DRAWING_DRIVER
void D_UpdateRects (vrect_t *prect)
{

// the software driver draws these directly to the vid buffer

	UNUSED(prect);
}
#endif


/* Independent pinned C algorithms are test-only. */
#if defined(BENCH486) && defined(ASM486_DRAWING_DRIVER)
void D_Init_Driver_C (void)
{

	r_skydirect = 1;

	Bench486DriverRegister (&d_subdiv16);
	Bench486DriverRegister (&d_mipcap);
	Bench486DriverRegister (&d_mipscale);

	/* Keep the BENCH486 C oracle aligned with the release driver's option. */
	r_drawpolys = COM_CheckParm ("-drawpolys") != 0;
	r_worldpolysbacktofront = false;
	r_recursiveaffinetriangles = true;
	r_pixbytes = 1;
	r_aliasuvscale = 1.0;
}
#endif

#if defined(BENCH486) && defined(ASM486_DRAWING_DRIVER)
void D_CopyRects_Driver_C (vrect_t *prects, int transparent)
{

// this function is only required if the CPU doesn't have direct access to the
// back buffer, and there's some driver interface function that the driver
// doesn't support and requires Quake to do in software (such as drawing the
// console); Quake will then draw into wherever the driver points vid.buffer
// and will call this function before swapping buffers

	UNUSED(prects);
	UNUSED(transparent);
}
#endif

#if defined(BENCH486) && defined(ASM486_DRAWING_DRIVER)
void D_EnableBackBufferAccess_Driver_C (void)
{
	VID_LockBuffer ();
}
#endif

#if defined(BENCH486) && defined(ASM486_DRAWING_DRIVER)
void D_TurnZOn_Driver_C (void)
{
// not needed for software version
}
#endif

#if defined(BENCH486) && defined(ASM486_DRAWING_DRIVER)
void D_DisableBackBufferAccess_Driver_C (void)
{
	VID_UnlockBuffer ();
}
#endif

#if defined(BENCH486) && defined(ASM486_DRAWING_DRIVER)
void D_SetupFrame_Driver_C (void)
{
	int		i;

	if (r_dowarp)
		d_viewbuffer = r_warpbuffer;
	else
		d_viewbuffer = (void *)(byte *)vid.buffer;

	if (r_dowarp)
		screenwidth = WARP_WIDTH;
	else
		screenwidth = vid.rowbytes;

	// Bake d_viewbuffer + d_scantable[v] so span ASM can load one row
	// pointer instead of adding the view base every span.  The table only
	// changes when the active buffer or its row stride changes.
	if (viewspantable_base != d_viewbuffer ||
			viewspantable_stride != screenwidth)
	{
		for (i=0 ; i<vid.height ; i++)
			viewspantable[i] = d_viewbuffer + d_scantable[i];
		viewspantable_base = d_viewbuffer;
		viewspantable_stride = screenwidth;
	}

	d_roverwrapped = false;
	d_initial_rover = sc_rover;

	d_minmip = d_mipcap.value;
	if (d_minmip > 3)
		d_minmip = 3;
	else if (d_minmip < 0)
		d_minmip = 0;

	for (i=0 ; i<(NUM_MIPS-1) ; i++)
		d_scalemip[i] = basemip[i] * d_mipscale.value;

#if	id386
				if (d_subdiv16.value)
					d_drawspans = D_DrawSpans16;
				else
					d_drawspans = D_DrawSpans8;
#else
				d_drawspans = D_DrawSpans8;
#endif

	d_aflatcolor = 0;
}
#endif

#if defined(BENCH486) && defined(ASM486_DRAWING_DRIVER)
void D_UpdateRects_Driver_C (vrect_t *prect)
{

// the software driver draws these directly to the vid buffer

	UNUSED(prect);
}
#endif
