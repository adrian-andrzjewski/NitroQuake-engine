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
// d_sky.c

#include "quakedef.h"
#include "r_local.h"
#include "d_local.h"

#define SKY_SPAN_SHIFT	5
#define SKY_SPAN_MAX	(1 << SKY_SPAN_SHIFT)

#if defined(ASM486_SKY_SPAN)
typedef char d_sky_asm_masks_match[
		(R_SKY_SMASK == 0x007F0000 && R_SKY_TMASK == 0x007F0000) ? 1 : -1];
#endif

#if defined(ASM486_SKY_SPAN) && defined(BENCH486)
static void D_SkyDrawPixels_C (byte *source, byte *dest, int count,
		fixed16_t s, fixed16_t t, fixed16_t sstep, fixed16_t tstep)
{
	if (count <= 0)
		return;

	do
	{
		*dest++ = source[((t & R_SKY_TMASK) >> 8) +
				((s & R_SKY_SMASK) >> 16)];
		s += sstep;
		t += tstep;
	} while (--count > 0);
}

void D_SkyDrawPixels_C_Bench (byte *source, byte *dest, int count,
		fixed16_t s, fixed16_t t, fixed16_t sstep, fixed16_t tstep)
{
	D_SkyDrawPixels_C (source, dest, count, s, t, sstep, tstep);
}
#endif

/*
=================
D_Sky_uv_To_st
=================
*/
static void D_Sky_uv_To_st (int u, int v, float sky_temp,
		float skytime_offset, fixed16_t *s, fixed16_t *t)
{
	float	wu, wv;
	vec3_t	end;

	wu = 8192.0 * (float)(u-((int)vid.width>>1)) / sky_temp;
	wv = 8192.0 * (float)(((int)vid.height>>1)-v) / sky_temp;

	end[0] = 4096*vpn[0] + wu*vright[0] + wv*vup[0];
	end[1] = 4096*vpn[1] + wu*vright[1] + wv*vup[1];
	end[2] = 4096*vpn[2] + wu*vright[2] + wv*vup[2];
	end[2] *= 3;
	VectorNormalize (end);

	*s = (int)((skytime_offset + 6*(SKYSIZE/2-1)*end[0]) * 0x10000);
	*t = (int)((skytime_offset + 6*(SKYSIZE/2-1)*end[1]) * 0x10000);
}
#if defined(ASM486_SKY_SPAN) && defined(BENCH486)
void D_Sky_uv_To_st_C (int u, int v, float sky_temp,
		float skytime_offset, fixed16_t *s, fixed16_t *t)
{
	D_Sky_uv_To_st (u, v, sky_temp, skytime_offset, s, t);
}
#endif


/*
=================
D_DrawSkyScans8
=================
*/
#if !defined(ASM486_SKY_SPAN) || defined(BENCH486)
#if defined(ASM486_SKY_SPAN) && defined(BENCH486)
static void D_DrawSkyScans8_C_Core (espan_t *pspan)
#else
void D_DrawSkyScans8 (espan_t *pspan)
#endif
{
	int				count, spancount, u, v;
	unsigned char	*pdest;
	fixed16_t		s, t, snext, tnext, sstep, tstep;
	int				spancountminus1;
	float				sky_temp, skytime_offset;

	sstep = 0;	// keep compiler happy
	tstep = 0;	// ditto

	if (r_refdef.vrect.width >= r_refdef.vrect.height)
		sky_temp = (float)r_refdef.vrect.width;
	else
		sky_temp = (float)r_refdef.vrect.height;
	skytime_offset = skytime*skyspeed;	// invariant for this surface draw

	do
	{
		pdest = (unsigned char *)((byte *)d_viewbuffer +
				(screenwidth * pspan->v) + pspan->u);

		count = pspan->count;

	// calculate the initial s & t
		u = pspan->u;
		v = pspan->v;
		D_Sky_uv_To_st (u, v, sky_temp, skytime_offset, &s, &t);

		do
		{
			if (count >= SKY_SPAN_MAX)
				spancount = SKY_SPAN_MAX;
			else
				spancount = count;

			count -= spancount;

			if (count)
			{
				u += spancount;

			// calculate s and t at far end of span,
			// calculate s and t steps across span by shifting
				D_Sky_uv_To_st (u, v, sky_temp, skytime_offset, &snext, &tnext);

				sstep = (snext - s) >> SKY_SPAN_SHIFT;
				tstep = (tnext - t) >> SKY_SPAN_SHIFT;
			}
			else
			{
			// calculate s and t at last pixel in span,
			// calculate s and t steps across span by division
				spancountminus1 = (float)(spancount - 1);

				if (spancountminus1 > 0)
				{
					u += spancountminus1;
					D_Sky_uv_To_st (u, v, sky_temp, skytime_offset, &snext, &tnext);

					sstep = (snext - s) / spancountminus1;
					tstep = (tnext - t) / spancountminus1;
				}
			}

			do
			{
				*pdest++ = r_skysource[((t & R_SKY_TMASK) >> 8) +
						((s & R_SKY_SMASK) >> 16)];
				s += sstep;
				t += tstep;
			} while (--spancount > 0);

			s = snext;
			t = tnext;

		} while (count > 0);

	} while ((pspan = pspan->pnext) != NULL);
}
#endif

#ifdef ASM486_SKY_SPAN
#ifdef BENCH486
void D_DrawSkyScans8_C_Bench (espan_t *pspan)
{
	D_DrawSkyScans8_C_Core (pspan);
}
#endif
#endif

