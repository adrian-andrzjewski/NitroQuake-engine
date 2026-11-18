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
// d_clear: clears a specified rectangle to the specified color

#include "common.h"
#include "vid.h"

#ifdef ASM486_FILLRECT
typedef char d_fillrect_vid_buffer_offset[
		(__builtin_offsetof (viddef_t, buffer) == 0) ? 1 : -1];
typedef char d_fillrect_vid_rowbytes_offset[
		(__builtin_offsetof (viddef_t, rowbytes) == 16) ? 1 : -1];
typedef char d_fillrect_vid_width_offset[
		(__builtin_offsetof (viddef_t, width) == 20) ? 1 : -1];
typedef char d_fillrect_vid_height_offset[
		(__builtin_offsetof (viddef_t, height) == 24) ? 1 : -1];
#define D_FillRect D_FillRect_C
#endif

#if !defined(ASM486_FILLRECT) || defined(BENCH486)
/*
================
D_FillRect
================
*/
void D_FillRect (vrect_t *rect, int color)
{
	int				rx, ry, rwidth, rheight;
	int				y;
	unsigned char	*dest;
	unsigned		*ldest;

	rx = rect->x;
	ry = rect->y;
	rwidth = rect->width;
	rheight = rect->height;

	if (rx < 0)
	{
		rwidth += rx;
		rx = 0;
	}
	if (ry < 0)
	{
		rheight += ry;
		ry = 0;
	}
	if (rx >= (int)vid.width || ry >= (int)vid.height)
		return;
	if (rx+rwidth > (int)vid.width)
		rwidth = (int)vid.width - rx;
	if (ry+rheight > (int)vid.height)
		rheight = (int)vid.height - ry;
		
	if (rwidth < 1 || rheight < 1)
		return;

	dest = ((byte *)vid.buffer + ry*vid.rowbytes + rx);

	/* Large rows go through the 486-tuned dword clear, including tails. */
	if (rwidth >= 16)
	{
		for (y=0 ; y<rheight ; y++)
		{
			Q_memset (dest, color, rwidth);
			dest += vid.rowbytes;
		}
		return;
	}

	if (((rwidth & 0x03) == 0) && (((long)dest & 0x03) == 0))
	{
	// faster aligned dword clear
		ldest = (unsigned *)dest;
		color += color << 16;

		rwidth >>= 2;
		color += color << 8;

		for (ry=0 ; ry<rheight ; ry++)
		{
			for (rx=0 ; rx<rwidth ; rx++)
				ldest[rx] = color;
			ldest = (unsigned *)((byte*)ldest + vid.rowbytes);
		}
	}
	else
	{
	// slower byte-by-byte clear for unaligned cases
		for (ry=0 ; ry<rheight ; ry++)
		{
			for (rx=0 ; rx<rwidth ; rx++)
				dest[rx] = color;
			dest += vid.rowbytes;
		}
	}
}
#endif

#ifdef ASM486_FILLRECT
#undef D_FillRect
#endif

