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
// d_zpoint.c: software driver module for drawing z-buffered points

#include "common.h"
#include "bspfile.h"
#include "mathlib.h"
#include "zone.h"
#include "cvar.h"
#include "model.h"
#include "d_iface.h"
#include "renderer/d_local.h"

#ifdef ASM486_ZPOINT
typedef char d_zpoint_u_offset[
		(__builtin_offsetof (zpointdesc_t, u) == 0) ? 1 : -1];
typedef char d_zpoint_v_offset[
		(__builtin_offsetof (zpointdesc_t, v) == 4) ? 1 : -1];
typedef char d_zpoint_zi_offset[
		(__builtin_offsetof (zpointdesc_t, zi) == 8) ? 1 : -1];
typedef char d_zpoint_color_offset[
		(__builtin_offsetof (zpointdesc_t, color) == 12) ? 1 : -1];
#define D_DrawZPoint D_DrawZPoint_C
#endif

#if !defined(ASM486_ZPOINT) || defined(BENCH486)
/*
=====================
D_DrawZPoint
=====================
*/
void D_DrawZPoint (void)
{
	byte	*pdest;
	short	*pz;
	int		izi;
	
	pz = d_pzbuffer + (d_zwidth * r_zpointdesc.v) + r_zpointdesc.u;
	pdest = d_viewbuffer + d_scantable[r_zpointdesc.v] + r_zpointdesc.u;
	izi = (int)(r_zpointdesc.zi * 0x8000);

	if (*pz <= izi)
	{
		*pz = izi;
		*pdest = r_zpointdesc.color;
	}
}
#endif

#ifdef ASM486_ZPOINT
#undef D_DrawZPoint
#endif
