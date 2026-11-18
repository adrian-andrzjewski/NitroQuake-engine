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
// r_aclip.c: clip routines for drawing Alias models directly to the screen

#include "common.h"
#include "bspfile.h"
#include "client.h"
#include "cvar.h"
#include "mathlib.h"
#include "zone.h"
#include "model.h"
#include "render.h"
#include "d_iface.h"
#include "sys.h"
#include "renderer/r_local.h"
#include "renderer/d_local.h"

#ifdef ASM486_ALIAS_CLIP
#include <stddef.h>

typedef char alias_clip_i386_pointer_size[(sizeof(void *) == 4) ? 1 : -1];
typedef char alias_clip_finalvert_layout[
		(offsetof(finalvert_t, v) == 0 &&
		offsetof(finalvert_t, flags) == 24 && sizeof(finalvert_t) == 32) ? 1 : -1];
typedef char alias_clip_auxvert_layout[
		(offsetof(auxvert_t, fv) == 0 && sizeof(auxvert_t) == 12) ? 1 : -1];
typedef char alias_clip_mtriangle_layout[
		(offsetof(mtriangle_t, facesfront) == 0 &&
		offsetof(mtriangle_t, vertindex) == 4 && sizeof(mtriangle_t) == 16) ? 1 : -1];
typedef char alias_clip_affinetridesc_layout[
		(offsetof(affinetridesc_t, ptriangles) == 16 &&
		offsetof(affinetridesc_t, pfinalverts) == 20 &&
		offsetof(affinetridesc_t, seamfixupX16) == 32 &&
		sizeof(affinetridesc_t) == 36) ? 1 : -1];
typedef char alias_clip_refdef_layout[
		(offsetof(refdef_t, aliasvrect) == 20 &&
		offsetof(refdef_t, aliasvrectright) == 48 &&
		offsetof(refdef_t, aliasvrectbottom) == 52) ? 1 : -1];
#endif

#ifdef ASM486_ALIAS_CLIP
finalvert_t			R_AliasClip_fv[2][8];
auxvert_t			R_AliasClip_av[8];
#else
static finalvert_t	R_AliasClip_fv[2][8];
static auxvert_t	R_AliasClip_av[8];
#endif

void R_AliasProjectFinalVert (finalvert_t *fv, auxvert_t *av);
void R_Alias_clip_top (finalvert_t *pfv0, finalvert_t *pfv1,
	finalvert_t *out);
void R_Alias_clip_bottom (finalvert_t *pfv0, finalvert_t *pfv1,
	finalvert_t *out);
void R_Alias_clip_left (finalvert_t *pfv0, finalvert_t *pfv1,
	finalvert_t *out);
void R_Alias_clip_right (finalvert_t *pfv0, finalvert_t *pfv1,
	finalvert_t *out);


/*
================
R_Alias_clip_z

pfv0 is the unclipped vertex, pfv1 is the z-clipped vertex
================
*/
#ifdef ASM486_ALIAS_CLIP
#define R_AliasClipTriangleZCallback R_Alias_clip_z_C
void R_Alias_clip_z_C (finalvert_t *pfv0, finalvert_t *pfv1,
		finalvert_t *out)
#else
#define R_AliasClipTriangleZCallback R_Alias_clip_z
void R_Alias_clip_z (finalvert_t *pfv0, finalvert_t *pfv1,
		finalvert_t *out)
#endif
{
	float		scale;
	auxvert_t	*pav0, *pav1, avout;

	pav0 = &R_AliasClip_av[pfv0 - &R_AliasClip_fv[0][0]];
	pav1 = &R_AliasClip_av[pfv1 - &R_AliasClip_fv[0][0]];

	if (pfv0->v[1] >= pfv1->v[1])
	{
		scale = (ALIAS_Z_CLIP_PLANE - pav0->fv[2]) /
				(pav1->fv[2] - pav0->fv[2]);
	
		avout.fv[0] = pav0->fv[0] + (pav1->fv[0] - pav0->fv[0]) * scale;
		avout.fv[1] = pav0->fv[1] + (pav1->fv[1] - pav0->fv[1]) * scale;
		avout.fv[2] = ALIAS_Z_CLIP_PLANE;
	
		out->v[2] =	pfv0->v[2] + (pfv1->v[2] - pfv0->v[2]) * scale;
		out->v[3] =	pfv0->v[3] + (pfv1->v[3] - pfv0->v[3]) * scale;
		out->v[4] =	pfv0->v[4] + (pfv1->v[4] - pfv0->v[4]) * scale;
	}
	else
	{
		scale = (ALIAS_Z_CLIP_PLANE - pav1->fv[2]) /
				(pav0->fv[2] - pav1->fv[2]);
	
		avout.fv[0] = pav1->fv[0] + (pav0->fv[0] - pav1->fv[0]) * scale;
		avout.fv[1] = pav1->fv[1] + (pav0->fv[1] - pav1->fv[1]) * scale;
		avout.fv[2] = ALIAS_Z_CLIP_PLANE;
	
		out->v[2] =	pfv1->v[2] + (pfv0->v[2] - pfv1->v[2]) * scale;
		out->v[3] =	pfv1->v[3] + (pfv0->v[3] - pfv1->v[3]) * scale;
		out->v[4] =	pfv1->v[4] + (pfv0->v[4] - pfv1->v[4]) * scale;
	}

	R_AliasProjectFinalVertDispatch (out, &avout);

	if (out->v[0] < r_refdef.aliasvrect.x)
		out->flags |= ALIAS_LEFT_CLIP;
	if (out->v[1] < r_refdef.aliasvrect.y)
		out->flags |= ALIAS_TOP_CLIP;
	if (out->v[0] > r_refdef.aliasvrectright)
		out->flags |= ALIAS_RIGHT_CLIP;
	if (out->v[1] > r_refdef.aliasvrectbottom)
		out->flags |= ALIAS_BOTTOM_CLIP;	
}

#if defined(BENCH486_ALIAS_CLIP_Z_COMPARE) && defined(BENCH486)
extern void R_Alias_clip_z_asm486 (finalvert_t *pfv0, finalvert_t *pfv1,
		finalvert_t *out);

void R_Alias_clip_z_bench (finalvert_t *pfv0, finalvert_t *pfv1,
		finalvert_t *out)
{
	static int compare_enabled = -1;
	static int trace_handle = -1;
	static unsigned long callback_count;
	static unsigned long mismatch_count;
	finalvert_t c_out, asm_out;
	auxvert_t *pav0, *pav1;
	char text[256];
	int i, mismatch;

	if (compare_enabled < 0)
		compare_enabled = COM_CheckParm ("-aliasclipzcompare") != 0;
	if (!compare_enabled)
	{
		R_Alias_clip_z_asm486 (pfv0, pfv1, out);
		return;
	}

	Q_memset (&c_out, 0, sizeof(c_out));
	Q_memset (&asm_out, 0, sizeof(asm_out));
	R_Alias_clip_z_C (pfv0, pfv1, &c_out);
	R_Alias_clip_z_asm486 (pfv0, pfv1, &asm_out);
	callback_count++;
	pav0 = &R_AliasClip_av[
			pfv0 - &R_AliasClip_fv[0][0]];
	pav1 = &R_AliasClip_av[
			pfv1 - &R_AliasClip_fv[0][0]];
	mismatch = c_out.flags != asm_out.flags;
	for (i=0 ; i<6 ; i++)
		if (c_out.v[i] != asm_out.v[i])
			mismatch = true;

	if ((callback_count <= 16 || mismatch) && mismatch_count < 128)
	{
		if (trace_handle == -1)
		{
			trace_handle = Sys_FileOpenWrite ("aliasz.txt");
		}
		if (trace_handle != -1)
		{
			sprintf (text,
					"%lu mismatch %d y %d %d z %.6f %.6f C %d %d %d %d %d %d f%u ASM %d %d %d %d %d %d f%u\n",
					callback_count, mismatch, pfv0->v[1], pfv1->v[1],
					pav0->fv[2], pav1->fv[2],
					c_out.v[0], c_out.v[1], c_out.v[2], c_out.v[3],
					c_out.v[4], c_out.v[5], (unsigned)c_out.flags,
					asm_out.v[0], asm_out.v[1], asm_out.v[2], asm_out.v[3],
					asm_out.v[4], asm_out.v[5], (unsigned)asm_out.flags);
			Sys_FileWrite (trace_handle, text, Q_strlen(text));
		}
	}
	if (mismatch)
	{
		mismatch_count++;
	}

	*out = asm_out;
}
#endif


#if !defined(__i386__)

void R_Alias_clip_left (finalvert_t *pfv0, finalvert_t *pfv1, finalvert_t *out)
{
	float		scale;
	int			i;

	if (pfv0->v[1] >= pfv1->v[1])
	{
		scale = (float)(r_refdef.aliasvrect.x - pfv0->v[0]) /
				(pfv1->v[0] - pfv0->v[0]);
		for (i=0 ; i<6 ; i++)
			out->v[i] = pfv0->v[i] + (pfv1->v[i] - pfv0->v[i])*scale + 0.5;
	}
	else
	{
		scale = (float)(r_refdef.aliasvrect.x - pfv1->v[0]) /
				(pfv0->v[0] - pfv1->v[0]);
		for (i=0 ; i<6 ; i++)
			out->v[i] = pfv1->v[i] + (pfv0->v[i] - pfv1->v[i])*scale + 0.5;
	}
}


void R_Alias_clip_right (finalvert_t *pfv0, finalvert_t *pfv1,
	finalvert_t *out)
{
	float		scale;
	int			i;

	if (pfv0->v[1] >= pfv1->v[1])
	{
		scale = (float)(r_refdef.aliasvrectright - pfv0->v[0]) /
				(pfv1->v[0] - pfv0->v[0]);
		for (i=0 ; i<6 ; i++)
			out->v[i] = pfv0->v[i] + (pfv1->v[i] - pfv0->v[i])*scale + 0.5;
	}
	else
	{
		scale = (float)(r_refdef.aliasvrectright - pfv1->v[0]) /
				(pfv0->v[0] - pfv1->v[0]);
		for (i=0 ; i<6 ; i++)
			out->v[i] = pfv1->v[i] + (pfv0->v[i] - pfv1->v[i])*scale + 0.5;
	}
}


void R_Alias_clip_top (finalvert_t *pfv0, finalvert_t *pfv1, finalvert_t *out)
{
	float		scale;
	int			i;

	if (pfv0->v[1] >= pfv1->v[1])
	{
		scale = (float)(r_refdef.aliasvrect.y - pfv0->v[1]) /
				(pfv1->v[1] - pfv0->v[1]);
		for (i=0 ; i<6 ; i++)
			out->v[i] = pfv0->v[i] + (pfv1->v[i] - pfv0->v[i])*scale + 0.5;
	}
	else
	{
		scale = (float)(r_refdef.aliasvrect.y - pfv1->v[1]) /
				(pfv0->v[1] - pfv1->v[1]);
		for (i=0 ; i<6 ; i++)
			out->v[i] = pfv1->v[i] + (pfv0->v[i] - pfv1->v[i])*scale + 0.5;
	}
}


void R_Alias_clip_bottom (finalvert_t *pfv0, finalvert_t *pfv1,
	finalvert_t *out)
{
	float		scale;
	int			i;

	if (pfv0->v[1] >= pfv1->v[1])
	{
		scale = (float)(r_refdef.aliasvrectbottom - pfv0->v[1]) /
				(pfv1->v[1] - pfv0->v[1]);

		for (i=0 ; i<6 ; i++)
			out->v[i] = pfv0->v[i] + (pfv1->v[i] - pfv0->v[i])*scale + 0.5;
	}
	else
	{
		scale = (float)(r_refdef.aliasvrectbottom - pfv1->v[1]) /
				(pfv0->v[1] - pfv1->v[1]);

		for (i=0 ; i<6 ; i++)
			out->v[i] = pfv1->v[i] + (pfv0->v[i] - pfv1->v[i])*scale + 0.5;
	}
}

#endif


#if !defined(ASM486_ALIAS_CLIP) || defined(BENCH486)
#ifdef ASM486_ALIAS_CLIP
int R_AliasClip_C (finalvert_t *in, finalvert_t *out, int flag, int count,
	void(*clip)(finalvert_t *pfv0, finalvert_t *pfv1, finalvert_t *out) )
#else
int R_AliasClip (finalvert_t *in, finalvert_t *out, int flag, int count,
	void(*clip)(finalvert_t *pfv0, finalvert_t *pfv1, finalvert_t *out) )
#endif
{
	int			i,j,k;
	int			flags, oldflags;
	
	j = count-1;
	k = 0;
	for (i=0 ; i<count ; j = i, i++)
	{
		oldflags = in[j].flags & flag;
		flags = in[i].flags & flag;

		if (flags && oldflags)
			continue;
		if (oldflags ^ flags)
		{
			clip (&in[j], &in[i], &out[k]);
			out[k].flags = 0;
			if (out[k].v[0] < r_refdef.aliasvrect.x)
				out[k].flags |= ALIAS_LEFT_CLIP;
			if (out[k].v[1] < r_refdef.aliasvrect.y)
				out[k].flags |= ALIAS_TOP_CLIP;
			if (out[k].v[0] > r_refdef.aliasvrectright)
				out[k].flags |= ALIAS_RIGHT_CLIP;
			if (out[k].v[1] > r_refdef.aliasvrectbottom)
				out[k].flags |= ALIAS_BOTTOM_CLIP;	
			k++;
		}
		if (!flags)
		{
			out[k] = in[i];
			k++;
		}
	}
	
	return k;
}
#endif

#ifdef ASM486_ALIAS_CLIP
int R_AliasClip_asm486 (finalvert_t *in, finalvert_t *out, int flag,
		int count,
		void(*clip)(finalvert_t *pfv0, finalvert_t *pfv1, finalvert_t *out));

#if !defined(ASM486_PUBLIC_BINDINGS) || !defined(ASM486_ALIAS_CLIP)
int R_AliasClip (finalvert_t *in, finalvert_t *out, int flag, int count,
	void(*clip)(finalvert_t *pfv0, finalvert_t *pfv1, finalvert_t *out))
{
	return R_AliasClip_asm486 (in, out, flag, count, clip);
}
#endif /* public entry is assembly-owned when selected */
#endif


/*
================
R_AliasClipTriangle
================
*/
#if !defined(ASM486_ALIAS_CLIP) || defined(BENCH486)
#ifdef ASM486_ALIAS_CLIP
#define R_AliasClipTrianglePass R_AliasClip_C
void R_AliasClipTriangle_C (mtriangle_t *ptri)
#else
#define R_AliasClipTrianglePass R_AliasClip
void R_AliasClipTriangle (mtriangle_t *ptri)
#endif
{
	int				i, k, pingpong;
	mtriangle_t		mtri;
	unsigned		clipflags;

// copy vertexes and fix seam texture coordinates
	if (ptri->facesfront)
	{
		R_AliasClip_fv[0][0] = pfinalverts[ptri->vertindex[0]];
		R_AliasClip_fv[0][1] = pfinalverts[ptri->vertindex[1]];
		R_AliasClip_fv[0][2] = pfinalverts[ptri->vertindex[2]];
	}
	else
	{
		for (i=0 ; i<3 ; i++)
		{
			R_AliasClip_fv[0][i] = pfinalverts[ptri->vertindex[i]];
	
			if (!ptri->facesfront &&
					(R_AliasClip_fv[0][i].flags & ALIAS_ONSEAM) )
				R_AliasClip_fv[0][i].v[2] += r_affinetridesc.seamfixupX16;
		}
	}

// clip
	clipflags = R_AliasClip_fv[0][0].flags |
			R_AliasClip_fv[0][1].flags | R_AliasClip_fv[0][2].flags;

	if (clipflags & ALIAS_Z_CLIP)
	{
		for (i=0 ; i<3 ; i++)
			R_AliasClip_av[i] = pauxverts[ptri->vertindex[i]];

		k = R_AliasClipTrianglePass (R_AliasClip_fv[0], R_AliasClip_fv[1],
				ALIAS_Z_CLIP, 3, R_AliasClipTriangleZCallback);
		if (k == 0)
			return;

		pingpong = 1;
		clipflags = R_AliasClip_fv[1][0].flags |
				R_AliasClip_fv[1][1].flags | R_AliasClip_fv[1][2].flags;
	}
	else
	{
		pingpong = 0;
		k = 3;
	}

	if (clipflags & ALIAS_LEFT_CLIP)
	{
		k = R_AliasClipTrianglePass (R_AliasClip_fv[pingpong],
						R_AliasClip_fv[pingpong ^ 1],
							ALIAS_LEFT_CLIP, k, R_Alias_clip_left);
		if (k == 0)
			return;

		pingpong ^= 1;
	}

	if (clipflags & ALIAS_RIGHT_CLIP)
	{
		k = R_AliasClipTrianglePass (R_AliasClip_fv[pingpong],
						R_AliasClip_fv[pingpong ^ 1],
							ALIAS_RIGHT_CLIP, k, R_Alias_clip_right);
		if (k == 0)
			return;

		pingpong ^= 1;
	}

	if (clipflags & ALIAS_BOTTOM_CLIP)
	{
		k = R_AliasClipTrianglePass (R_AliasClip_fv[pingpong],
						R_AliasClip_fv[pingpong ^ 1],
							ALIAS_BOTTOM_CLIP, k, R_Alias_clip_bottom);
		if (k == 0)
			return;

		pingpong ^= 1;
	}

	if (clipflags & ALIAS_TOP_CLIP)
	{
		k = R_AliasClipTrianglePass (R_AliasClip_fv[pingpong],
						R_AliasClip_fv[pingpong ^ 1],
							ALIAS_TOP_CLIP, k, R_Alias_clip_top);
		if (k == 0)
			return;

		pingpong ^= 1;
	}

	for (i=0 ; i<k ; i++)
	{
		if (R_AliasClip_fv[pingpong][i].v[0] < r_refdef.aliasvrect.x)
			R_AliasClip_fv[pingpong][i].v[0] = r_refdef.aliasvrect.x;
		else if (R_AliasClip_fv[pingpong][i].v[0] > r_refdef.aliasvrectright)
			R_AliasClip_fv[pingpong][i].v[0] = r_refdef.aliasvrectright;

		if (R_AliasClip_fv[pingpong][i].v[1] < r_refdef.aliasvrect.y)
			R_AliasClip_fv[pingpong][i].v[1] = r_refdef.aliasvrect.y;
		else if (R_AliasClip_fv[pingpong][i].v[1] > r_refdef.aliasvrectbottom)
			R_AliasClip_fv[pingpong][i].v[1] = r_refdef.aliasvrectbottom;

		R_AliasClip_fv[pingpong][i].flags = 0;
	}

// draw triangles
	mtri.facesfront = ptri->facesfront;
	r_affinetridesc.ptriangles = &mtri;
	r_affinetridesc.pfinalverts = R_AliasClip_fv[pingpong];

// FIXME: do all at once as trifan?
	mtri.vertindex[0] = 0;
	for (i=1 ; i<k-1 ; i++)
	{
		mtri.vertindex[1] = i;
		mtri.vertindex[2] = i+1;
		D_PolysetDraw ();
	}
}
#undef R_AliasClipTrianglePass
#undef R_AliasClipTriangleZCallback
#endif

#ifdef ASM486_ALIAS_CLIP
void R_AliasClipTriangle_asm486 (mtriangle_t *ptri);

#if !defined(ASM486_PUBLIC_BINDINGS) || !defined(ASM486_ALIAS_CLIP)
void R_AliasClipTriangle (mtriangle_t *ptri)
{
	R_AliasClipTriangle_asm486 (ptri);
}
#endif /* public entry is assembly-owned when selected */
#endif
