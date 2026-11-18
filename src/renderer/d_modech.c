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
/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
// d_modech.c: called when mode has just changed

#include "common.h"
#include "bspfile.h"
#include "mathlib.h"
#include "zone.h"
#include "cvar.h"
#include "model.h"
#include "d_iface.h"
#include "sys.h"
#include "renderer/d_local.h"
#include "renderer/asm_drawingdriver.h"

/* Same process-lifetime patch latch as the original function-local object. */
static qboolean protectset8 __attribute__((used)) = false;
#ifdef ASM486_DRAWING_DRIVER
__asm__(".globl _d_driver_protectset8\n.set _d_driver_protectset8,_protectset8");
#endif
int	d_vrectx, d_vrecty, d_vrectright_particle, d_vrectbottom_particle;

int	d_y_aspect_shift, d_pix_min, d_pix_max, d_pix_shift;

int		d_scantable[MAXHEIGHT];
short	*zspantable[MAXHEIGHT];
pixel_t	*viewspantable[MAXHEIGHT]; 

/*
================
D_Patch
================
*/
#ifndef ASM486_DRAWING_DRIVER
void D_Patch (void)
{
#if defined(__i386__)



	if (!protectset8)
	{
		Sys_MakeCodeWriteable ((int)D_PolysetAff8Start,
						     (int)D_PolysetAff8End - (int)D_PolysetAff8Start);
		protectset8 = true;
	}

#endif	// __i386__
}
#endif


/*
================
D_ViewChanged
================
*/
#ifndef ASM486_DRAWING_DRIVER
void D_ViewChanged (void)
{
	int rowbytes;

	if (r_dowarp)
		rowbytes = WARP_WIDTH;
	else
		rowbytes = vid.rowbytes;

	scale_for_mip = xscale;
	if (yscale > xscale)
		scale_for_mip = yscale;

	d_zrowbytes = vid.width * 2;
	d_zwidth = vid.width;

	d_pix_min = r_refdef.vrect.width / 320;
	if (d_pix_min < 1)
		d_pix_min = 1;

	d_pix_max = (int)((float)r_refdef.vrect.width / (320.0 / 4.0) + 0.5);
	d_pix_shift = 8 - (int)((float)r_refdef.vrect.width / 320.0 + 0.5);
	if (d_pix_max < 1)
		d_pix_max = 1;

	if (pixelAspect > 1.4)
		d_y_aspect_shift = 1;
	else
		d_y_aspect_shift = 0;

	d_vrectx = r_refdef.vrect.x;
	d_vrecty = r_refdef.vrect.y;
	d_vrectright_particle = r_refdef.vrectright - d_pix_max;
	d_vrectbottom_particle =
			r_refdef.vrectbottom - (d_pix_max << d_y_aspect_shift);

	{
		int		i;

		for (i=0 ; i<vid.height; i++)
		{
			d_scantable[i] = i*rowbytes;
			zspantable[i] = d_pzbuffer + i*d_zwidth;
		}
	}

	D_Patch ();
}
#endif


/* Independent pinned C algorithms are test-only. */
#if defined(BENCH486) && defined(ASM486_DRAWING_DRIVER)
void D_Patch_Driver_C (void)
{
#if defined(__i386__)



	if (!protectset8)
	{
		Bench486DriverMakeWritable ((int)D_PolysetAff8Start,
						     (int)D_PolysetAff8End - (int)D_PolysetAff8Start);
		protectset8 = true;
	}

#endif	// __i386__
}
#endif

#if defined(BENCH486) && defined(ASM486_DRAWING_DRIVER)
void D_ViewChanged_Driver_C (void)
{
	int rowbytes;

	if (r_dowarp)
		rowbytes = WARP_WIDTH;
	else
		rowbytes = vid.rowbytes;

	scale_for_mip = xscale;
	if (yscale > xscale)
		scale_for_mip = yscale;

	d_zrowbytes = vid.width * 2;
	d_zwidth = vid.width;

	d_pix_min = r_refdef.vrect.width / 320;
	if (d_pix_min < 1)
		d_pix_min = 1;

	d_pix_max = (int)((float)r_refdef.vrect.width / (320.0 / 4.0) + 0.5);
	d_pix_shift = 8 - (int)((float)r_refdef.vrect.width / 320.0 + 0.5);
	if (d_pix_max < 1)
		d_pix_max = 1;

	if (pixelAspect > 1.4)
		d_y_aspect_shift = 1;
	else
		d_y_aspect_shift = 0;

	d_vrectx = r_refdef.vrect.x;
	d_vrecty = r_refdef.vrect.y;
	d_vrectright_particle = r_refdef.vrectright - d_pix_max;
	d_vrectbottom_particle =
			r_refdef.vrectbottom - (d_pix_max << d_y_aspect_shift);

	{
		int		i;

		for (i=0 ; i<vid.height; i++)
		{
			d_scantable[i] = i*rowbytes;
			zspantable[i] = d_pzbuffer + i*d_zwidth;
		}
	}

	D_Patch_Driver_C ();
}
#endif
