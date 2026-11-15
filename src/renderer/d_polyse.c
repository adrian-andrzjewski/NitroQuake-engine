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
// d_polyset.c: routines for drawing sets of polygons sharing the same
// texture (used for Alias models)

#include <math.h>

#include "common.h"
#include "cvar.h"
#include "mathlib.h"
#include "bspfile.h"
#include "zone.h"
#include "model.h"
#include "client.h"
#include "render.h"
#include "d_iface.h"
#include "tests/bench486/bench486_profile.h"
#include "renderer/asm_publicbindings.h"
#include "renderer/r_local.h"
#include "renderer/d_local.h"

// TODO: put in span spilling to shrink list size
// !!! if this is changed, it must be changed in d_polysa.s too !!!
#define DPS_MAXSPANS			MAXHEIGHT+1	
									// 1 extra for spanpackage that marks end

// !!! if this is changed, it must be changed in asm_draw.h too !!!
typedef struct {
	void			*pdest;
	short			*pz;
	int				count;
	byte			*ptex;
	int				sfrac, tfrac, light, zi;
} spanpackage_t;

typedef struct {
	int		isflattop;
	int		numleftedges;
	int		*pleftedgevert0;
	int		*pleftedgevert1;
	int		*pleftedgevert2;
	int		numrightedges;
	int		*prightedgevert0;
	int		*prightedgevert1;
	int		*prightedgevert2;
} edgetable;

/* The i486 selector indexes this array using the original 36-byte C layout. */
typedef char edgetable_i486_size[(sizeof(edgetable) == 36) ? 1 : -1];

int	r_p0[6], r_p1[6], r_p2[6];

byte		*d_pcolormap;

int			d_aflatcolor;
int			d_xdenom;
int			d_xdenom_int;

edgetable	*pedgetable;

edgetable	edgetables[12] = {
	{0, 1, r_p0, r_p2, NULL, 2, r_p0, r_p1, r_p2 },
	{0, 2, r_p1, r_p0, r_p2,   1, r_p1, r_p2, NULL},
	{1, 1, r_p0, r_p2, NULL, 1, r_p1, r_p2, NULL},
	{0, 1, r_p1, r_p0, NULL, 2, r_p1, r_p2, r_p0 },
	{0, 2, r_p0, r_p2, r_p1,   1, r_p0, r_p1, NULL},
	{0, 1, r_p2, r_p1, NULL, 1, r_p2, r_p0, NULL},
	{0, 1, r_p2, r_p1, NULL, 2, r_p2, r_p0, r_p1 },
	{0, 2, r_p2, r_p1, r_p0,   1, r_p2, r_p0, NULL},
	{0, 1, r_p1, r_p0, NULL, 1, r_p1, r_p2, NULL},
	{1, 1, r_p2, r_p1, NULL, 1, r_p0, r_p1, NULL},
	{1, 1, r_p1, r_p0, NULL, 1, r_p2, r_p0, NULL},
	{0, 1, r_p0, r_p2, NULL, 1, r_p0, r_p1, NULL},
};

// FIXME: some of these can become statics
int				a_sstepxfrac, a_tstepxfrac, r_lstepx, a_ststepxwhole;
int				r_sstepx, r_tstepx, r_lstepy, r_sstepy, r_tstepy;
int				r_zistepx, r_zistepy;
int				d_aspancount, d_countextrastep;

spanpackage_t			*a_spans;
spanpackage_t			*d_pedgespanpackage;
static int				ystart;
byte					*d_pdest, *d_ptex;
short					*d_pz;
int						d_sfrac, d_tfrac, d_light, d_zi;
int						d_ptexextrastep, d_sfracextrastep;
int						d_tfracextrastep, d_lightextrastep, d_pdestextrastep;
int						d_lightbasestep, d_pdestbasestep, d_ptexbasestep;
int						d_sfracbasestep, d_tfracbasestep;
int						d_ziextrastep, d_zibasestep;
int						d_pzextrastep, d_pzbasestep;

typedef struct {
	int		quotient;
	int		remainder;
} adivtab_t;

/* The i486 line-scan setup reads the same small-step table directly. */
typedef char adivtab_i486_entry_size[(sizeof(adivtab_t) == 8) ? 1 : -1];
adivtab_t	adivtab[64*64] = {
#include "renderer/adivtab.h"
};

#ifdef ASM486_ALIAS_GLUE_PROBE
// Dead-scratch probe sink and execution count for the alias-glue C block.
// Defined here rather than in host_cmd.c, exactly as bench486_rf_probe_sink is
// in r_draw.c: a C probe cannot accumulate into a dead local, because -O3
// deletes the store and turns the probe into a silent no-op that measures
// zero.  An external global is the only form -O3 has to keep, and the sink's
// own load/add/store is counted as part of the probe rather than hidden.
unsigned long	bench486_ag_probe_sink;
unsigned long	bench486_ag_probe_count;
#endif

byte	*skintable[MAX_LBM_HEIGHT];
int		skinwidth;
byte	*skinstart;
typedef char skintable_i486_rows[(sizeof(skintable) / sizeof(skintable[0]) == 480) ? 1 : -1];

void D_PolysetDrawSpans8 (spanpackage_t *pspanpackage);
void D_PolysetCalcGradients (int skinwidth);
void D_PolysetCalcGradients_C (int skinwidth);
void D_PolysetSetUpForLineScan (fixed8_t startvertu, fixed8_t startvertv,
		fixed8_t endvertu, fixed8_t endvertv);
void D_PolysetSetUpForLineScan_C (fixed8_t startvertu, fixed8_t startvertv,
		fixed8_t endvertu, fixed8_t endvertv);
void D_PolysetSetEdgeTable_C (void);
void D_PolysetUpdateTables_C (void);
void D_RasterizeAliasPolySmooth_C (void);
#ifdef PROFILE486
void D_PolysetCalcGradientsProfiled (int skinwidth);
void D_PolysetScanLeftEdgeProfiled (int height);
void D_PolysetDrawSpansProfiled (spanpackage_t *spans);
#endif
#if id386
void D_PolysetCalcGradients_asm486 (int skinwidth);
void D_PolysetSetUpForLineScan_asm486 (fixed8_t startvertu,
		fixed8_t startvertv, fixed8_t endvertu, fixed8_t endvertv);
void D_PolysetSetEdgeTable_asm486 (void);
void D_PolysetUpdateTables_asm486 (void);
void D_RasterizeAliasPolySmooth_asm486 (void);
#endif
void D_DrawSubdiv (void);
void D_DrawNonSubdiv (void);
void D_PolysetRecursiveTriangle (int *p1, int *p2, int *p3);
void D_PolysetSetEdgeTable (void);
void D_RasterizeAliasPolySmooth (void);
void D_PolysetScanLeftEdge (int height);

#ifdef PROFILE486
void D_PolysetCalcGradientsProfiled (int skinwidth)
{
	BENCH486_PROFILE_ENTER (BENCH486_PROFILE_ALIAS_CALCGRADIENTS);
	D_PolysetCalcGradients (skinwidth);
	BENCH486_PROFILE_LEAVE ();
}

void D_PolysetScanLeftEdgeProfiled (int height)
{
	BENCH486_PROFILE_ENTER (BENCH486_PROFILE_ALIAS_SCAN_LEFT_EDGE);
	D_PolysetScanLeftEdge (height);
	BENCH486_PROFILE_LEAVE ();
}

void D_PolysetDrawSpansProfiled (spanpackage_t *spans)
{
	spanpackage_t	*span;
	int				span_count, span_pixels, span_width;
	int				span_aspancount, span_errorterm;

	/*
	 * Count the samples submitted to the 486 span drawer without changing its
	 * state.  The stepping below mirrors D_PolysetDrawSpans8: PROFILE486 uses
	 * this wrapper around the assembly drawer, while the C reference uses the
	 * same wrapper around the C drawer.
	 */
	span_count = 0;
	span_pixels = 0;
	span_aspancount = d_aspancount;
	span_errorterm = errorterm;
	for (span = spans; span->count != -999999; span++)
	{
		span_width = span_aspancount - span->count;
		if (span_width > 0)
		{
			span_count++;
			span_pixels += span_width;
		}

		span_errorterm += erroradjustup;
		if (span_errorterm >= 0)
		{
			span_aspancount += d_countextrastep;
			span_errorterm -= erroradjustdown;
		}
		else
		{
			span_aspancount += ubasestep;
		}
	}
	BENCH486_PROFILE_WORK (BENCH486_PROFILE_ALIAS_DRAW_SPANS,
			(unsigned long)span_count, (unsigned long)span_pixels);

	BENCH486_PROFILE_ENTER (BENCH486_PROFILE_ALIAS_DRAW_SPANS);
	D_PolysetDrawSpans8 (spans);
	BENCH486_PROFILE_LEAVE ();
}
#endif

#if !id386 || defined(BENCH486) || !defined(ASM486_ALIAS_GRADIENTS)
void D_PolysetCalcGradients_C (int skinwidth)
{
	float	xstepdenominv, ystepdenominv, t0, t1;
	float	p01_minus_p21, p11_minus_p21, p00_minus_p20, p10_minus_p20;

	p00_minus_p20 = r_p0[0] - r_p2[0];
	p01_minus_p21 = r_p0[1] - r_p2[1];
	p10_minus_p20 = r_p1[0] - r_p2[0];
	p11_minus_p21 = r_p1[1] - r_p2[1];

	xstepdenominv = 1.0 / (float)d_xdenom;
	ystepdenominv = -xstepdenominv;

	// ceil () for light so positive steps are exaggerated, negative steps
	// diminished, pushing away from underflow toward overflow.
	t0 = r_p0[4] - r_p2[4];
	t1 = r_p1[4] - r_p2[4];
	r_lstepx = (int)
			ceil((t1 * p01_minus_p21 - t0 * p11_minus_p21) * xstepdenominv);
	r_lstepy = (int)
			ceil((t1 * p00_minus_p20 - t0 * p10_minus_p20) * ystepdenominv);

	t0 = r_p0[2] - r_p2[2];
	t1 = r_p1[2] - r_p2[2];
	r_sstepx = (int)((t1 * p01_minus_p21 - t0 * p11_minus_p21) *
			xstepdenominv);
	r_sstepy = (int)((t1 * p00_minus_p20 - t0 * p10_minus_p20) *
			ystepdenominv);

	t0 = r_p0[3] - r_p2[3];
	t1 = r_p1[3] - r_p2[3];
	r_tstepx = (int)((t1 * p01_minus_p21 - t0 * p11_minus_p21) *
			xstepdenominv);
	r_tstepy = (int)((t1 * p00_minus_p20 - t0 * p10_minus_p20) *
			ystepdenominv);

	t0 = r_p0[5] - r_p2[5];
	t1 = r_p1[5] - r_p2[5];
	r_zistepx = (int)((t1 * p01_minus_p21 - t0 * p11_minus_p21) *
			xstepdenominv);
	r_zistepy = (int)((t1 * p00_minus_p20 - t0 * p10_minus_p20) *
			ystepdenominv);

#if id386
	a_sstepxfrac = r_sstepx << 16;
	a_tstepxfrac = r_tstepx << 16;
#else
	a_sstepxfrac = r_sstepx & 0xFFFF;
	a_tstepxfrac = r_tstepx & 0xFFFF;
#endif

	a_ststepxwhole = skinwidth * (r_tstepx >> 16) + (r_sstepx >> 16);
}
#endif

#if !defined(ASM486_PUBLIC_BINDINGS) || !defined(ASM486_ALIAS_GRADIENTS)
void D_PolysetCalcGradients (int skinwidth)
{
#if id386 && defined(ASM486_ALIAS_GRADIENTS)
	D_PolysetCalcGradients_asm486 (skinwidth);
#elif id386
	int saved_denominator;

	// The legacy assembly edge walker leaves the reciprocal as a float bit
	// pattern in d_xdenom. The C reference consumes the integer determinant.
	saved_denominator = d_xdenom;
	d_xdenom = d_xdenom_int;
	D_PolysetCalcGradients_C (skinwidth);
	d_xdenom = saved_denominator;
#else
	D_PolysetCalcGradients_C (skinwidth);
#endif
}
#endif /* public entry is assembly-owned when selected */

#if	!id386

/*
================
D_PolysetDraw
================
*/
void D_PolysetDraw (void)
{
	spanpackage_t	spans[DPS_MAXSPANS + 1 +
			((CACHE_SIZE - 1) / sizeof(spanpackage_t)) + 1];
						// one extra because of cache line pretouching

	a_spans = (spanpackage_t *)
			(((long)&spans[0] + CACHE_SIZE - 1) & ~(CACHE_SIZE - 1));

	if (r_affinetridesc.drawtype)
	{
		D_DrawSubdiv ();
	}
	else
	{
		D_DrawNonSubdiv ();
	}
}


/*
================
D_PolysetDrawFinalVerts
================
*/
void D_PolysetDrawFinalVerts (finalvert_t *fv, int numverts)
{
	int		i, z;
	int		clipright, clipbottom;
	short	*zbuf;

	clipright = r_refdef.vrectright;
	clipbottom = r_refdef.vrectbottom;

	for (i=0 ; i<numverts ; i++, fv++)
	{
	// valid triangle coordinates for filling can include the bottom and
	// right clip edges, due to the fill rule; these shouldn't be drawn
		if ((fv->v[0] < clipright) &&
			(fv->v[1] < clipbottom))
		{
			z = fv->v[5]>>16;
			zbuf = zspantable[fv->v[1]] + fv->v[0];
			if (z >= *zbuf)
			{
				int		pix;
				
				*zbuf = z;
				pix = skintable[fv->v[3]>>16][fv->v[2]>>16];
				pix = ((byte *)acolormap)[pix + (fv->v[4] & 0xFF00) ];
				d_viewbuffer[d_scantable[fv->v[1]] + fv->v[0]] = pix;
			}
		}
	}
}


/*
================
D_DrawSubdiv
================
*/
void D_DrawSubdiv (void)
{
	mtriangle_t		*ptri;
	finalvert_t		*pfv, *index0, *index1, *index2;
	int				i;
	int				lnumtriangles;

	pfv = r_affinetridesc.pfinalverts;
	ptri = r_affinetridesc.ptriangles;
	lnumtriangles = r_affinetridesc.numtriangles;

	for (i=0 ; i<lnumtriangles ; i++)
	{
		index0 = pfv + ptri[i].vertindex[0];
		index1 = pfv + ptri[i].vertindex[1];
		index2 = pfv + ptri[i].vertindex[2];

		if (((index0->v[1]-index1->v[1]) *
			 (index0->v[0]-index2->v[0]) -
			 (index0->v[0]-index1->v[0]) * 
			 (index0->v[1]-index2->v[1])) >= 0)
		{
			continue;
		}

		d_pcolormap = &((byte *)acolormap)[index0->v[4] & 0xFF00];

		if (ptri[i].facesfront)
		{
			D_PolysetRecursiveTriangle(index0->v, index1->v, index2->v);
		}
		else
		{
			int		s0, s1, s2;

			s0 = index0->v[2];
			s1 = index1->v[2];
			s2 = index2->v[2];

			if (index0->flags & ALIAS_ONSEAM)
				index0->v[2] += r_affinetridesc.seamfixupX16;
			if (index1->flags & ALIAS_ONSEAM)
				index1->v[2] += r_affinetridesc.seamfixupX16;
			if (index2->flags & ALIAS_ONSEAM)
				index2->v[2] += r_affinetridesc.seamfixupX16;

			D_PolysetRecursiveTriangle(index0->v, index1->v, index2->v);

			index0->v[2] = s0;
			index1->v[2] = s1;
			index2->v[2] = s2;
		}
	}
}


/*
================
D_DrawNonSubdiv
================
*/
void D_DrawNonSubdiv (void)
{
	mtriangle_t		*ptri;
	finalvert_t		*pfv, *index0, *index1, *index2;
	int				i;
	int				lnumtriangles;

	pfv = r_affinetridesc.pfinalverts;
	ptri = r_affinetridesc.ptriangles;
	lnumtriangles = r_affinetridesc.numtriangles;

	for (i=0 ; i<lnumtriangles ; i++, ptri++)
	{
		index0 = pfv + ptri->vertindex[0];
		index1 = pfv + ptri->vertindex[1];
		index2 = pfv + ptri->vertindex[2];

		d_xdenom = (index0->v[1]-index1->v[1]) *
				(index0->v[0]-index2->v[0]) -
				(index0->v[0]-index1->v[0])*(index0->v[1]-index2->v[1]);

		if (d_xdenom >= 0)
		{
			continue;
		}

		r_p0[0] = index0->v[0];		// u
		r_p0[1] = index0->v[1];		// v
		r_p0[2] = index0->v[2];		// s
		r_p0[3] = index0->v[3];		// t
		r_p0[4] = index0->v[4];		// light
		r_p0[5] = index0->v[5];		// iz

		r_p1[0] = index1->v[0];
		r_p1[1] = index1->v[1];
		r_p1[2] = index1->v[2];
		r_p1[3] = index1->v[3];
		r_p1[4] = index1->v[4];
		r_p1[5] = index1->v[5];

		r_p2[0] = index2->v[0];
		r_p2[1] = index2->v[1];
		r_p2[2] = index2->v[2];
		r_p2[3] = index2->v[3];
		r_p2[4] = index2->v[4];
		r_p2[5] = index2->v[5];

		if (!ptri->facesfront)
		{
			if (index0->flags & ALIAS_ONSEAM)
				r_p0[2] += r_affinetridesc.seamfixupX16;
			if (index1->flags & ALIAS_ONSEAM)
				r_p1[2] += r_affinetridesc.seamfixupX16;
			if (index2->flags & ALIAS_ONSEAM)
				r_p2[2] += r_affinetridesc.seamfixupX16;
		}

		D_PolysetSetEdgeTable ();
		D_RasterizeAliasPolySmooth ();
	}
}


/*
================
D_PolysetRecursiveTriangle
================
*/
void D_PolysetRecursiveTriangle (int *lp1, int *lp2, int *lp3)
{
	int		*temp;
	int		d;
	int		new[6];
	int		z;
	short	*zbuf;

	d = lp2[0] - lp1[0];
	if (d < -1 || d > 1)
		goto split;
	d = lp2[1] - lp1[1];
	if (d < -1 || d > 1)
		goto split;

	d = lp3[0] - lp2[0];
	if (d < -1 || d > 1)
		goto split2;
	d = lp3[1] - lp2[1];
	if (d < -1 || d > 1)
		goto split2;

	d = lp1[0] - lp3[0];
	if (d < -1 || d > 1)
		goto split3;
	d = lp1[1] - lp3[1];
	if (d < -1 || d > 1)
	{
split3:
		temp = lp1;
		lp1 = lp3;
		lp3 = lp2;
		lp2 = temp;

		goto split;
	}

	return;			// entire tri is filled

split2:
	temp = lp1;
	lp1 = lp2;
	lp2 = lp3;
	lp3 = temp;

split:
// split this edge
	new[0] = (lp1[0] + lp2[0]) >> 1;
	new[1] = (lp1[1] + lp2[1]) >> 1;
	new[2] = (lp1[2] + lp2[2]) >> 1;
	new[3] = (lp1[3] + lp2[3]) >> 1;
	new[5] = (lp1[5] + lp2[5]) >> 1;

// draw the point if splitting a leading edge
	if (lp2[1] > lp1[1])
		goto nodraw;
	if ((lp2[1] == lp1[1]) && (lp2[0] < lp1[0]))
		goto nodraw;


	z = new[5]>>16;
	zbuf = zspantable[new[1]] + new[0];
	if (z >= *zbuf)
	{
		int		pix;
		
		*zbuf = z;
		pix = d_pcolormap[skintable[new[3]>>16][new[2]>>16]];
		d_viewbuffer[d_scantable[new[1]] + new[0]] = pix;
	}

nodraw:
// recursively continue
	D_PolysetRecursiveTriangle (lp3, lp1, new);
	D_PolysetRecursiveTriangle (lp3, new, lp2);
}

#endif	// !id386


/*
================
D_PolysetUpdateTables
================
*/
#if !id386 || defined(BENCH486) || !defined(ASM486_ALIAS_SKIN_TABLE)
void D_PolysetUpdateTables_C (void)
{
	int		i;
	byte	*s;
	
	if (r_affinetridesc.skinwidth != skinwidth ||
		r_affinetridesc.pskin != skinstart)
	{
		skinwidth = r_affinetridesc.skinwidth;
		skinstart = r_affinetridesc.pskin;
		s = skinstart;
		for (i=0 ; i<MAX_LBM_HEIGHT ; i++, s+=skinwidth)
			skintable[i] = s;
	}
}
#endif


#if	!id386

/*
===================
D_PolysetScanLeftEdge
====================
*/
void D_PolysetScanLeftEdge (int height)
{

	do
	{
		d_pedgespanpackage->pdest = d_pdest;
		d_pedgespanpackage->pz = d_pz;
		d_pedgespanpackage->count = d_aspancount;
		d_pedgespanpackage->ptex = d_ptex;

		d_pedgespanpackage->sfrac = d_sfrac;
		d_pedgespanpackage->tfrac = d_tfrac;

	// FIXME: need to clamp l, s, t, at both ends?
		d_pedgespanpackage->light = d_light;
		d_pedgespanpackage->zi = d_zi;

		d_pedgespanpackage++;

		errorterm += erroradjustup;
		if (errorterm >= 0)
		{
			d_pdest += d_pdestextrastep;
			d_pz += d_pzextrastep;
			d_aspancount += d_countextrastep;
			d_ptex += d_ptexextrastep;
			d_sfrac += d_sfracextrastep;
			d_ptex += d_sfrac >> 16;

			d_sfrac &= 0xFFFF;
			d_tfrac += d_tfracextrastep;
			if (d_tfrac & 0x10000)
			{
				d_ptex += r_affinetridesc.skinwidth;
				d_tfrac &= 0xFFFF;
			}
			d_light += d_lightextrastep;
			d_zi += d_ziextrastep;
			errorterm -= erroradjustdown;
		}
		else
		{
			d_pdest += d_pdestbasestep;
			d_pz += d_pzbasestep;
			d_aspancount += ubasestep;
			d_ptex += d_ptexbasestep;
			d_sfrac += d_sfracbasestep;
			d_ptex += d_sfrac >> 16;
			d_sfrac &= 0xFFFF;
			d_tfrac += d_tfracbasestep;
			if (d_tfrac & 0x10000)
			{
				d_ptex += r_affinetridesc.skinwidth;
				d_tfrac &= 0xFFFF;
			}
			d_light += d_lightbasestep;
			d_zi += d_zibasestep;
		}
	} while (--height);
}

#endif	// !id386


/*
===================
D_PolysetSetUpForLineScan
====================
*/
void D_PolysetSetUpForLineScan_C(fixed8_t startvertu, fixed8_t startvertv,
		fixed8_t endvertu, fixed8_t endvertv)
{
	int			tm, tn;
	adivtab_t	*ptemp;

	errorterm = -1;

	tm = endvertu - startvertu;
	tn = endvertv - startvertv;

	if (((tm <= 32) && (tm >= -31)) &&
		((tn <= 32) && (tn >= -31)))
	{
		ptemp = &adivtab[((tm+31) << 6) + (tn+31)];
		ubasestep = ptemp->quotient;
		erroradjustup = ptemp->remainder;
		erroradjustdown = tn;
	}
	else
	{
		/*
		 * Edge heights are positive in the rasterizer.  Keep the exact
		 * floor-division/remainder convention used by FloorDivMod, but avoid
		 * promoting every long edge to double precision on a 486DX.
		 */
		if (tn > 0)
		{
			if (tm >= 0)
			{
				ubasestep = tm / tn;
				erroradjustup = tm % tn;
			}
			else
			{
				int magnitude;

				magnitude = -tm;
				ubasestep = -(magnitude / tn);
				erroradjustup = magnitude % tn;
				if (erroradjustup)
				{
					ubasestep--;
					erroradjustup = tn - erroradjustup;
				}
			}
			erroradjustdown = tn;
		}
		else
		{
			/* Preserve the historical error behavior for invalid heights. */
			FloorDivMod ((double)tm, (double)tn,
					&ubasestep, &erroradjustup);
			erroradjustdown = tn;
		}
	}
}

#if !defined(ASM486_PUBLIC_BINDINGS) || !defined(ASM486_ALIAS_SKIN_TABLE)
void D_PolysetUpdateTables (void)
{
#if id386 && defined(ASM486_ALIAS_SKIN_TABLE)
	D_PolysetUpdateTables_asm486 ();
#else
	D_PolysetUpdateTables_C ();
#endif
}
#endif /* public entry is assembly-owned when selected */

#if !defined(ASM486_PUBLIC_BINDINGS) || !defined(ASM486_ALIAS_LINE_SCAN)
void D_PolysetSetUpForLineScan (fixed8_t startvertu, fixed8_t startvertv,
		fixed8_t endvertu, fixed8_t endvertv)
{
#ifdef PROFILE486
	if (bench486_profile_frame_active)
		bench486_line_setup_calls++;
#endif

#if id386 && defined(ASM486_ALIAS_LINE_SCAN)
	D_PolysetSetUpForLineScan_asm486 (startvertu, startvertv,
			endvertu, endvertv);
#else
	D_PolysetSetUpForLineScan_C (startvertu, startvertv,
			endvertu, endvertv);
#endif
}
#endif /* public entry is assembly-owned when selected */


#if	!id386

#endif	// !id386


#if 0
byte gelmap[256];
void InitGel (byte *palette)
{
	int		i;
	int		r;

	for (i=0 ; i<256 ; i++)
	{
//		r = (palette[i*3]>>4);
		r = (palette[i*3] + palette[i*3+1] + palette[i*3+2])/(16*3);
		gelmap[i] = /* 64 */ 0 + r;
	}
}
#endif


#if	!id386

/*
================
D_PolysetDrawSpans8
================
*/
void D_PolysetDrawSpans8 (spanpackage_t *pspanpackage)
{
	int		lcount;
	byte	*lpdest;
	byte	*lptex;
	int		lsfrac, ltfrac;
	int		llight;
	int		lzi;
	short	*lpz;

	do
	{
		lcount = d_aspancount - pspanpackage->count;

		errorterm += erroradjustup;
		if (errorterm >= 0)
		{
			d_aspancount += d_countextrastep;
			errorterm -= erroradjustdown;
		}
		else
		{
			d_aspancount += ubasestep;
		}

		if (lcount)
		{
			lpdest = pspanpackage->pdest;
			lptex = pspanpackage->ptex;
			lpz = pspanpackage->pz;
			lsfrac = pspanpackage->sfrac;
			ltfrac = pspanpackage->tfrac;
			llight = pspanpackage->light;
			lzi = pspanpackage->zi;

			do
			{
				if ((lzi >> 16) >= *lpz)
				{
					*lpdest = ((byte *)acolormap)[*lptex + (llight & 0xFF00)];
// gel mapping					*lpdest = gelmap[*lpdest];
					*lpz = lzi >> 16;
				}
				lpdest++;
				lzi += r_zistepx;
				lpz++;
				llight += r_lstepx;
				lptex += a_ststepxwhole;
				lsfrac += a_sstepxfrac;
				lptex += lsfrac >> 16;
				lsfrac &= 0xFFFF;
				ltfrac += a_tstepxfrac;
				if (ltfrac & 0x10000)
				{
					lptex += r_affinetridesc.skinwidth;
					ltfrac &= 0xFFFF;
				}
			} while (--lcount);
		}

		pspanpackage++;
	} while (pspanpackage->count != -999999);
}
#endif	// !id386


/*
================
D_PolysetFillSpans8
================
*/
void D_PolysetFillSpans8 (spanpackage_t *pspanpackage)
{
	int				color;

// FIXME: do z buffering

	color = d_aflatcolor++;

	while (1)
	{
		int		lcount;
		byte	*lpdest;

		lcount = pspanpackage->count;

		if (lcount == -1)
			return;

		if (lcount)
		{
			lpdest = pspanpackage->pdest;

			do
			{
				*lpdest++ = color;
			} while (--lcount);
		}

		pspanpackage++;
	}
}

/*
================
D_RasterizeAliasPolySmooth
================
*/
#if !id386 || defined(BENCH486) || !defined(ASM486_ALIAS_RASTERIZE)
void D_RasterizeAliasPolySmooth_C (void)
{
	int				initialleftheight, initialrightheight;
	int				*plefttop, *prighttop, *pleftbottom, *prightbottom;
	int				working_lstepx, originalcount;
	int				skinwidth, sbase, tbase, sextra, textra;

	plefttop = pedgetable->pleftedgevert0;
	prighttop = pedgetable->prightedgevert0;

	pleftbottom = pedgetable->pleftedgevert1;
	prightbottom = pedgetable->prightedgevert1;

	initialleftheight = pleftbottom[1] - plefttop[1];
	initialrightheight = prightbottom[1] - prighttop[1];

//
// set the s, t, and light gradients, which are consistent across the triangle
// because being a triangle, things are affine
//
#ifdef PROFILE486
	D_PolysetCalcGradientsProfiled (r_affinetridesc.skinwidth);
#else
	D_PolysetCalcGradients (r_affinetridesc.skinwidth);
#endif

//
// rasterize the polygon
//

//
// scan out the top (and possibly only) part of the left edge
//
	d_pedgespanpackage = a_spans;

	ystart = plefttop[1];
	d_aspancount = plefttop[0] - prighttop[0];

	d_ptex = (byte *)r_affinetridesc.pskin + (plefttop[2] >> 16) +
			(plefttop[3] >> 16) * r_affinetridesc.skinwidth;
#if	id386
	d_sfrac = (plefttop[2] & 0xFFFF) << 16;
	d_tfrac = (plefttop[3] & 0xFFFF) << 16;
#else
	d_sfrac = plefttop[2] & 0xFFFF;
	d_tfrac = plefttop[3] & 0xFFFF;
#endif
	d_light = plefttop[4];
	d_zi = plefttop[5];

	d_pdest = viewspantable[ystart] + plefttop[0];
	d_pz = zspantable[ystart] + plefttop[0];
	// Multiply form: d_viewbuffer + ystart * screenwidth + plefttop[0]
	// and d_pzbuffer + ystart * d_zwidth + plefttop[0].

	if (initialleftheight == 1)
	{
		d_pedgespanpackage->pdest = d_pdest;
		d_pedgespanpackage->pz = d_pz;
		d_pedgespanpackage->count = d_aspancount;
		d_pedgespanpackage->ptex = d_ptex;

		d_pedgespanpackage->sfrac = d_sfrac;
		d_pedgespanpackage->tfrac = d_tfrac;

	// FIXME: need to clamp l, s, t, at both ends?
		d_pedgespanpackage->light = d_light;
		d_pedgespanpackage->zi = d_zi;

		d_pedgespanpackage++;
	}
	else
	{
		D_PolysetSetUpForLineScan(plefttop[0], plefttop[1],
							  pleftbottom[0], pleftbottom[1]);

	#if	id386
		d_pzbasestep = (d_zwidth + ubasestep) << 1;
		d_pzextrastep = d_pzbasestep + 2;
	#else
		d_pzbasestep = d_zwidth + ubasestep;
		d_pzextrastep = d_pzbasestep + 1;
	#endif

		d_pdestbasestep = screenwidth + ubasestep;
		d_pdestextrastep = d_pdestbasestep + 1;

	// for negative steps in x along left edge, bias toward overflow rather than
	// underflow (sort of turning the floor () we did in the gradient calcs into
	// ceil (), but plus a little bit)
		if (ubasestep < 0)
			working_lstepx = r_lstepx - 1;
		else
			working_lstepx = r_lstepx;

		skinwidth = r_affinetridesc.skinwidth;
		d_countextrastep = ubasestep + 1;
		sbase = r_sstepy + r_sstepx * ubasestep;
		tbase = r_tstepy + r_tstepx * ubasestep;
		d_ptexbasestep = (sbase >> 16) + (tbase >> 16) * skinwidth;
	#if	id386
		d_sfracbasestep = sbase << 16;
		d_tfracbasestep = tbase << 16;
	#else
		d_sfracbasestep = sbase & 0xFFFF;
		d_tfracbasestep = tbase & 0xFFFF;
	#endif
		d_lightbasestep = r_lstepy + working_lstepx * ubasestep;
		d_zibasestep = r_zistepy + r_zistepx * ubasestep;

		sextra = sbase + r_sstepx;
		textra = tbase + r_tstepx;
		d_ptexextrastep = (sextra >> 16) + (textra >> 16) * skinwidth;
	#if	id386
		d_sfracextrastep = sextra << 16;
		d_tfracextrastep = textra << 16;
	#else
		d_sfracextrastep = sextra & 0xFFFF;
		d_tfracextrastep = textra & 0xFFFF;
	#endif
		d_lightextrastep = d_lightbasestep + working_lstepx;
		d_ziextrastep = d_zibasestep + r_zistepx;

#if defined(ASM486_ALIAS_GLUE_PROBE) && defined(ASM486_ALIAS_GLUE_PROBE_SETUP)
	// Dead-scratch probe over the per-triangle step setup above, which is the
	// largest single block of C in the alias path.  It recomputes the same
	// arithmetic into locals and folds it into the sink; nothing is written to
	// any d_* global, so the three ASM helpers that follow are untouched.
	//
	// -O3 deletes a dead local store, so the sink MUST be an external global
	// that something reports -- otherwise the probe compiles to nothing and
	// measures zero while appearing to run.  The count is a second external
	// global, so a probe that got folded away reports 0 instead of lying.
	// Placed after the real block so every input is live and final.
	{
		int		ppz = (d_zwidth + ubasestep) << 1;
		int		ppd = screenwidth + ubasestep;
		int		pskin = r_affinetridesc.skinwidth;
		int		psb = r_sstepy + r_sstepx * ubasestep;
		int		ptb = r_tstepy + r_tstepx * ubasestep;
		int		pwl = ubasestep < 0 ? r_lstepx - 1 : r_lstepx;
		int		psex = psb + r_sstepx;
		int		ptex = ptb + r_tstepx;

		bench486_ag_probe_sink += (unsigned long)ppz + (unsigned long)(ppz + 2)
			+ (unsigned long)ppd + (unsigned long)(ppd + 1)
			+ (unsigned long)(ubasestep + 1)
			+ (unsigned long)((psb >> 16) + (ptb >> 16) * pskin)
			+ (unsigned long)(psb << 16) + (unsigned long)(ptb << 16)
			+ (unsigned long)(r_lstepy + pwl * ubasestep)
			+ (unsigned long)(r_zistepy + r_zistepx * ubasestep)
			+ (unsigned long)((psex >> 16) + (ptex >> 16) * pskin)
			+ (unsigned long)(psex << 16) + (unsigned long)(ptex << 16)
			+ (unsigned long)(r_lstepy + pwl * ubasestep + pwl)
			+ (unsigned long)(r_zistepy + r_zistepx * ubasestep + r_zistepx);
		bench486_ag_probe_count++;
	}
#endif

	#ifdef PROFILE486
		D_PolysetScanLeftEdgeProfiled (initialleftheight);
	#else
		D_PolysetScanLeftEdge (initialleftheight);
	#endif
	}

//
// scan out the bottom part of the left edge, if it exists
//
	if (pedgetable->numleftedges == 2)
	{
		int		height;

		plefttop = pleftbottom;
		pleftbottom = pedgetable->pleftedgevert2;

		height = pleftbottom[1] - plefttop[1];

// TODO: make this a function; modularize this function in general

		ystart = plefttop[1];
		d_aspancount = plefttop[0] - prighttop[0];
		d_ptex = (byte *)r_affinetridesc.pskin + (plefttop[2] >> 16) +
				(plefttop[3] >> 16) * r_affinetridesc.skinwidth;
		d_sfrac = 0;
		d_tfrac = 0;
		d_light = plefttop[4];
		d_zi = plefttop[5];

		d_pdest = viewspantable[ystart] + plefttop[0];
		d_pz = zspantable[ystart] + plefttop[0];

		if (height == 1)
		{
			d_pedgespanpackage->pdest = d_pdest;
			d_pedgespanpackage->pz = d_pz;
			d_pedgespanpackage->count = d_aspancount;
			d_pedgespanpackage->ptex = d_ptex;

			d_pedgespanpackage->sfrac = d_sfrac;
			d_pedgespanpackage->tfrac = d_tfrac;

		// FIXME: need to clamp l, s, t, at both ends?
			d_pedgespanpackage->light = d_light;
			d_pedgespanpackage->zi = d_zi;

			d_pedgespanpackage++;
		}
		else
		{
			D_PolysetSetUpForLineScan(plefttop[0], plefttop[1],
								  pleftbottom[0], pleftbottom[1]);

			d_pdestbasestep = screenwidth + ubasestep;
			d_pdestextrastep = d_pdestbasestep + 1;

	#if	id386
			d_pzbasestep = (d_zwidth + ubasestep) << 1;
			d_pzextrastep = d_pzbasestep + 2;
	#else
			d_pzbasestep = d_zwidth + ubasestep;
			d_pzextrastep = d_pzbasestep + 1;
	#endif

			if (ubasestep < 0)
				working_lstepx = r_lstepx - 1;
			else
				working_lstepx = r_lstepx;

			skinwidth = r_affinetridesc.skinwidth;
			d_countextrastep = ubasestep + 1;
			sbase = r_sstepy + r_sstepx * ubasestep;
			tbase = r_tstepy + r_tstepx * ubasestep;
			d_ptexbasestep = (sbase >> 16) + (tbase >> 16) * skinwidth;
	#if	id386
			d_sfracbasestep = sbase << 16;
			d_tfracbasestep = tbase << 16;
	#else
			d_sfracbasestep = sbase & 0xFFFF;
			d_tfracbasestep = tbase & 0xFFFF;
	#endif
			d_lightbasestep = r_lstepy + working_lstepx * ubasestep;
			d_zibasestep = r_zistepy + r_zistepx * ubasestep;

			sextra = sbase + r_sstepx;
			textra = tbase + r_tstepx;
			d_ptexextrastep = (sextra >> 16) + (textra >> 16) * skinwidth;
	#if	id386
			d_sfracextrastep = (sextra & 0xFFFF) << 16;
			d_tfracextrastep = (textra & 0xFFFF) << 16;
	#else
			d_sfracextrastep = sextra & 0xFFFF;
			d_tfracextrastep = textra & 0xFFFF;
	#endif
			d_lightextrastep = d_lightbasestep + working_lstepx;
			d_ziextrastep = d_zibasestep + r_zistepx;

			#ifdef PROFILE486
			D_PolysetScanLeftEdgeProfiled (height);
			#else
			D_PolysetScanLeftEdge (height);
			#endif
		}
	}

// scan out the top (and possibly only) part of the right edge, updating the
// count field
	d_pedgespanpackage = a_spans;

	D_PolysetSetUpForLineScan(prighttop[0], prighttop[1],
						  prightbottom[0], prightbottom[1]);
	d_aspancount = 0;
	d_countextrastep = ubasestep + 1;
	originalcount = a_spans[initialrightheight].count;
	a_spans[initialrightheight].count = -999999; // mark end of the spanpackages
	#ifdef PROFILE486
	D_PolysetDrawSpansProfiled (a_spans);
	#else
	D_PolysetDrawSpans8 (a_spans);
	#endif

// scan out the bottom part of the right edge, if it exists
	if (pedgetable->numrightedges == 2)
	{
		int				height;
		spanpackage_t	*pstart;

		pstart = a_spans + initialrightheight;
		pstart->count = originalcount;

		d_aspancount = prightbottom[0] - prighttop[0];

		prighttop = prightbottom;
		prightbottom = pedgetable->prightedgevert2;

		height = prightbottom[1] - prighttop[1];

		D_PolysetSetUpForLineScan(prighttop[0], prighttop[1],
							  prightbottom[0], prightbottom[1]);

		d_countextrastep = ubasestep + 1;
		a_spans[initialrightheight + height].count = -999999;
											// mark end of the spanpackages
		#ifdef PROFILE486
		D_PolysetDrawSpansProfiled (pstart);
		#else
		D_PolysetDrawSpans8 (pstart);
		#endif
	}

}
#endif

#if !defined(ASM486_PUBLIC_BINDINGS) || !defined(ASM486_ALIAS_RASTERIZE)
void D_RasterizeAliasPolySmooth (void)
{
	// One scope per triangle rather than one per sub-block. The three delegated
	// raster helpers keep their own scopes; this measures only their C/ASM glue.
	BENCH486_PROFILE_ENTER (BENCH486_PROFILE_ALIAS_GLUE);
#if id386 && defined(ASM486_ALIAS_RASTERIZE)
	D_RasterizeAliasPolySmooth_asm486 ();
#else
	D_RasterizeAliasPolySmooth_C ();
#endif
	BENCH486_PROFILE_LEAVE ();
}
#endif /* public entry is assembly-owned when selected */


/*
================
D_PolysetSetEdgeTable
================
*/
#if !id386 || defined(BENCH486) || !defined(ASM486_ALIAS_EDGE_TABLE)
void D_PolysetSetEdgeTable_C (void)
{
	int			edgetableindex;

	edgetableindex = 0;	// assume the vertices are already in
						//  top to bottom order

//
// determine which edges are right & left, and the order in which
// to rasterize them
//
	if (r_p0[1] >= r_p1[1])
	{
		if (r_p0[1] == r_p1[1])
		{
			if (r_p0[1] < r_p2[1])
				pedgetable = &edgetables[2];
			else
				pedgetable = &edgetables[5];

			return;
		}
		else
		{
			edgetableindex = 1;
		}
	}

	if (r_p0[1] == r_p2[1])
	{
		if (edgetableindex)
			pedgetable = &edgetables[8];
		else
			pedgetable = &edgetables[9];

		return;
	}
	else if (r_p1[1] == r_p2[1])
	{
		if (edgetableindex)
			pedgetable = &edgetables[10];
		else
			pedgetable = &edgetables[11];

		return;
	}

	if (r_p0[1] > r_p2[1])
		edgetableindex += 2;

	if (r_p1[1] > r_p2[1])
		edgetableindex += 4;

	pedgetable = &edgetables[edgetableindex];
}
#endif

#if !defined(ASM486_PUBLIC_BINDINGS) || !defined(ASM486_ALIAS_EDGE_TABLE)
void D_PolysetSetEdgeTable (void)
{
#if id386 && defined(ASM486_ALIAS_EDGE_TABLE)
	D_PolysetSetEdgeTable_asm486 ();
#else
	D_PolysetSetEdgeTable_C ();
#endif
}
#endif /* public entry is assembly-owned when selected */

#ifdef BENCH486
void *D_PolysetGetEdgeTableForBench (void)
{
	return (void *)pedgetable;
}

void D_PolysetSetEdgeTableForBench (void *table)
{
	pedgetable = (edgetable *)table;
}
#endif


#if 0

void D_PolysetRecursiveDrawLine (int *lp1, int *lp2)
{
	int		d;
	int		new[6];
	int 	ofs;
	
	d = lp2[0] - lp1[0];
	if (d < -1 || d > 1)
		goto split;
	d = lp2[1] - lp1[1];
	if (d < -1 || d > 1)
		goto split;

	return;	// line is completed

split:
// split this edge
	new[0] = (lp1[0] + lp2[0]) >> 1;
	new[1] = (lp1[1] + lp2[1]) >> 1;
	new[5] = (lp1[5] + lp2[5]) >> 1;
	new[2] = (lp1[2] + lp2[2]) >> 1;
	new[3] = (lp1[3] + lp2[3]) >> 1;
	new[4] = (lp1[4] + lp2[4]) >> 1;

// draw the point
	ofs = d_scantable[new[1]] + new[0];
	if (new[5] > d_pzbuffer[ofs])
	{
		int		pix;
		
		d_pzbuffer[ofs] = new[5];
		pix = skintable[new[3]>>16][new[2]>>16];
//		pix = ((byte *)acolormap)[pix + (new[4] & 0xFF00)];
		d_viewbuffer[ofs] = pix;
	}

// recursively continue
	D_PolysetRecursiveDrawLine (lp1, new);
	D_PolysetRecursiveDrawLine (new, lp2);
}

void D_PolysetRecursiveTriangle2 (int *lp1, int *lp2, int *lp3)
{
	int		d;
	int		new[4];
	
	d = lp2[0] - lp1[0];
	if (d < -1 || d > 1)
		goto split;
	d = lp2[1] - lp1[1];
	if (d < -1 || d > 1)
		goto split;
	return;

split:
// split this edge
	new[0] = (lp1[0] + lp2[0]) >> 1;
	new[1] = (lp1[1] + lp2[1]) >> 1;
	new[5] = (lp1[5] + lp2[5]) >> 1;
	new[2] = (lp1[2] + lp2[2]) >> 1;
	new[3] = (lp1[3] + lp2[3]) >> 1;
	new[4] = (lp1[4] + lp2[4]) >> 1;

	D_PolysetRecursiveDrawLine (new, lp3);

// recursively continue
	D_PolysetRecursiveTriangle (lp1, new, lp3);
	D_PolysetRecursiveTriangle (new, lp2, lp3);
}

#endif

