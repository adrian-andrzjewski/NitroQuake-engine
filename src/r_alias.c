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
// r_alias.c: routines for setting up to draw alias models

#include "quakedef.h"
#include "r_local.h"
#include "asm_renderdispatch.h"
#include "asm_aliascontrol.h"
#include "d_local.h"	// FIXME: shouldn't be needed (is needed for patch
						// right now, but that should move)

#define ASM486_ALIAS_MODEL_OCCLUSION 1

#if ASM486_ALIAS_MODEL_OCCLUSION
#define ALIAS_OCCLUSION_SCREEN_WIDTH	320
#define ALIAS_OCCLUSION_SCREEN_HEIGHT	200
#define ALIAS_OCCLUSION_TILE_SHIFT	3
#define ALIAS_OCCLUSION_TILE_SIZE	(1 << ALIAS_OCCLUSION_TILE_SHIFT)
#define ALIAS_OCCLUSION_TILES_X		(ALIAS_OCCLUSION_SCREEN_WIDTH / ALIAS_OCCLUSION_TILE_SIZE)
#define ALIAS_OCCLUSION_TILES_Y		(ALIAS_OCCLUSION_SCREEN_HEIGHT / ALIAS_OCCLUSION_TILE_SIZE)
#define ALIAS_OCCLUSION_TILE_COUNT	(ALIAS_OCCLUSION_TILES_X * ALIAS_OCCLUSION_TILES_Y)

extern qboolean r_drawpolys;
extern qboolean r_drawculledpolys;

// Written by the bbox projection helper. Values are min x/y, max x/y, max 1/z.
float alias_occlusion_projection[5];

static unsigned short alias_occlusion_tile_min[ALIAS_OCCLUSION_TILE_COUNT];
static unsigned long alias_occlusion_tile_epoch[ALIAS_OCCLUSION_TILE_COUNT];
static unsigned long alias_occlusion_epoch;
static int alias_occlusion_frame = -2147483647;
static short *alias_occlusion_zbuffer;
static int alias_occlusion_vrect_x;
static int alias_occlusion_vrect_y;
static int alias_occlusion_vrect_width;
static int alias_occlusion_vrect_height;

#ifdef PROFILE486
extern unsigned long bench486_alias_occlusion_queries;
extern unsigned long bench486_alias_occlusion_culls;
extern unsigned long bench486_alias_occlusion_tiles;
extern unsigned long bench486_alias_occlusion_z_samples;
#endif

qboolean R_AliasModelOccluded (void)
{
	int				x0, y0, x1, y1, tx, ty, tile, row, col, nearest_z;
	int				x, y;
	short			*zrow;
	unsigned short	minimum_z;
	float			depth, minx, miny, maxx, maxy;
	int				view_right, view_bottom, tile_x, tile_y;

#ifdef PROFILE486
	bench486_alias_occlusion_queries++;
#endif

	// The cache is sized for the exact benchmark mode. Other view layouts use
	// the reference renderer path without an occlusion query.
	if (screenwidth != ALIAS_OCCLUSION_SCREEN_WIDTH ||
			d_zwidth != ALIAS_OCCLUSION_SCREEN_WIDTH ||
			vid.width != ALIAS_OCCLUSION_SCREEN_WIDTH ||
			vid.height != ALIAS_OCCLUSION_SCREEN_HEIGHT ||
			r_refdef.vrect.x < 0 ||
		r_refdef.vrect.y < 0 || r_refdef.vrect.width <= 0 ||
		r_refdef.vrect.height <= 0 ||
		r_refdef.vrect.x >= ALIAS_OCCLUSION_SCREEN_WIDTH ||
		r_refdef.vrect.y >= ALIAS_OCCLUSION_SCREEN_HEIGHT ||
		r_refdef.vrect.width >
				ALIAS_OCCLUSION_SCREEN_WIDTH - r_refdef.vrect.x ||
		r_refdef.vrect.height >
				ALIAS_OCCLUSION_SCREEN_HEIGHT - r_refdef.vrect.y || !d_pzbuffer ||
			r_drawpolys || r_drawculledpolys)
		return false;

	view_right = r_refdef.vrect.x + r_refdef.vrect.width;
	view_bottom = r_refdef.vrect.y + r_refdef.vrect.height;

	minx = alias_occlusion_projection[0];
	miny = alias_occlusion_projection[1];
	maxx = alias_occlusion_projection[2];
	maxy = alias_occlusion_projection[3];
	if (!(minx <= maxx) || !(miny <= maxy) ||
			maxx < r_refdef.vrect.x || minx >= view_right ||
			maxy < r_refdef.vrect.y || miny >= view_bottom)
		return false;

	// Clamp in floating point before conversion so even an unusually large
	// projected model bound cannot overflow the integer screen coordinates.
	if (minx < r_refdef.vrect.x + 2.0f)
		x0 = r_refdef.vrect.x;
	else
		x0 = (int)minx - 1;
	if (miny < r_refdef.vrect.y + 2.0f)
		y0 = r_refdef.vrect.y;
	else
		y0 = (int)miny - 1;
	if (maxx >= view_right - 1.0f)
		x1 = view_right - 1;
	else
		x1 = (int)maxx + 1;
	if (maxy >= view_bottom - 1.0f)
		y1 = view_bottom - 1;
	else
		y1 = (int)maxy + 1;

	// Alias Z is the truncated 16-bit 1/z value. Add two units so rounding in
	// the bound can only make this test more conservative.
	depth = alias_occlusion_projection[4] * 32768.0f;
	if (!(depth > 0.0f) || depth > 32764.0f)
		return false;
	nearest_z = (int)depth + 2;

	if (alias_occlusion_frame != r_framecount ||
			alias_occlusion_zbuffer != d_pzbuffer ||
			alias_occlusion_vrect_x != r_refdef.vrect.x ||
			alias_occlusion_vrect_y != r_refdef.vrect.y ||
			alias_occlusion_vrect_width != r_refdef.vrect.width ||
			alias_occlusion_vrect_height != r_refdef.vrect.height)
	{
		alias_occlusion_frame = r_framecount;
		alias_occlusion_zbuffer = d_pzbuffer;
		alias_occlusion_vrect_x = r_refdef.vrect.x;
		alias_occlusion_vrect_y = r_refdef.vrect.y;
		alias_occlusion_vrect_width = r_refdef.vrect.width;
		alias_occlusion_vrect_height = r_refdef.vrect.height;
		alias_occlusion_epoch++;
		if (!alias_occlusion_epoch)
		{
			memset (alias_occlusion_tile_epoch, 0,
					sizeof(alias_occlusion_tile_epoch));
			alias_occlusion_epoch = 1;
		}
	}

	for (ty = y0 >> ALIAS_OCCLUSION_TILE_SHIFT;
			ty <= (y1 >> ALIAS_OCCLUSION_TILE_SHIFT); ty++)
	{
		for (tx = x0 >> ALIAS_OCCLUSION_TILE_SHIFT;
				tx <= (x1 >> ALIAS_OCCLUSION_TILE_SHIFT); tx++)
		{
			tile = ty * ALIAS_OCCLUSION_TILES_X + tx;
#ifdef PROFILE486
			bench486_alias_occlusion_tiles++;
#endif
			if (alias_occlusion_tile_epoch[tile] != alias_occlusion_epoch)
			{
				minimum_z = 0xffff;
				tile_x = tx << ALIAS_OCCLUSION_TILE_SHIFT;
				tile_y = ty << ALIAS_OCCLUSION_TILE_SHIFT;
				if (tile_x < r_refdef.vrect.x ||
						tile_y < r_refdef.vrect.y ||
						tile_x + ALIAS_OCCLUSION_TILE_SIZE > view_right ||
						tile_y + ALIAS_OCCLUSION_TILE_SIZE > view_bottom)
					minimum_z = 0;
				for (row = 0 ; minimum_z && row < ALIAS_OCCLUSION_TILE_SIZE ; row++)
				{
					y = tile_y + row;
					zrow = d_pzbuffer + y * d_zwidth +
							tile_x;
					for (col = 0 ; col < ALIAS_OCCLUSION_TILE_SIZE ; col++)
					{
#ifdef PROFILE486
						bench486_alias_occlusion_z_samples++;
#endif
						if (zrow[col] < 0)
						{
							minimum_z = 0;
							break;
						}
						if ((unsigned short)zrow[col] < minimum_z)
							minimum_z = (unsigned short)zrow[col];
					}
					if (!minimum_z)
						break;
				}
				alias_occlusion_tile_min[tile] = minimum_z;
				alias_occlusion_tile_epoch[tile] = alias_occlusion_epoch;
			}

			// Entity depth writes are monotonic after the world/brush pass, so
			// this cached minimum remains a conservative lower bound this frame.
			if (alias_occlusion_tile_min[tile] <= nearest_z)
				return false;
		}
	}

#ifdef PROFILE486
	bench486_alias_occlusion_culls++;
#endif
	return true;
}
#endif

#if defined(ASM486_ALIAS_PREPARE) || defined(ASM486_ALIAS_SETUP_LIGHTING) || defined(ASM486_ALIAS_SETUP_FRAME) || defined(ASM486_ALIAS_SETUP_SKIN)
#include <stddef.h>
#endif

#ifdef ASM486_ALIAS_PREPARE

typedef char alias_prepare_i386_pointer_size[(sizeof(void *) == 4) ? 1 : -1];
typedef char alias_prepare_finalvert_layout[
		(offsetof(finalvert_t, v) == 0 &&
		offsetof(finalvert_t, flags) == 24 && sizeof(finalvert_t) == 32) ? 1 : -1];
typedef char alias_prepare_auxvert_layout[
		(offsetof(auxvert_t, fv) == 0 && sizeof(auxvert_t) == 12) ? 1 : -1];
typedef char alias_prepare_trivert_layout[
		(offsetof(trivertx_t, v) == 0 &&
		offsetof(trivertx_t, lightnormalindex) == 3 &&
		sizeof(trivertx_t) == 4) ? 1 : -1];
typedef char alias_prepare_stvert_layout[
		(offsetof(stvert_t, onseam) == 0 && offsetof(stvert_t, s) == 4 &&
		offsetof(stvert_t, t) == 8 && sizeof(stvert_t) == 12) ? 1 : -1];
typedef char alias_prepare_refdef_layout[
		(offsetof(refdef_t, aliasvrect) == 20 &&
		offsetof(refdef_t, aliasvrectright) == 48 &&
		offsetof(refdef_t, aliasvrectbottom) == 52) ? 1 : -1];
#endif
#ifdef ASM486_ALIAS_SETUP_LIGHTING
typedef char alias_setup_lighting_i386_pointer_size[(sizeof(void *) == 4) ? 1 : -1];
typedef char alias_setup_lighting_layout[
		(offsetof(alight_t, ambientlight) == 0 &&
		offsetof(alight_t, shadelight) == 4 &&
		offsetof(alight_t, plightvec) == 8 &&
			sizeof(alight_t) == 12) ? 1 : -1];
#endif
#ifdef ASM486_ALIAS_SETUP_FRAME
typedef char alias_setup_frame_i386_pointer_size[(sizeof(void *) == 4) ? 1 : -1];
typedef char alias_setup_frame_layout[
		(offsetof(maliasframedesc_t, type) == 0 &&
		offsetof(maliasframedesc_t, frame) == 12 &&
		offsetof(maliasframedesc_t, name) == 16 &&
		sizeof(maliasframedesc_t) == 32 &&
		offsetof(maliasgroup_t, numframes) == 0 &&
		offsetof(maliasgroup_t, intervals) == 4 &&
		offsetof(maliasgroup_t, frames) == 8 &&
		sizeof(maliasgroupframedesc_t) == 12 &&
		offsetof(aliashdr_t, frames) == 16 &&
		ALIAS_SINGLE == 0 && ALIAS_GROUP == 1) ? 1 : -1];
#endif
#ifdef ASM486_ALIAS_SETUP_SKIN
typedef char alias_setup_skin_i386_pointer_size[(sizeof(void *) == 4) ? 1 : -1];
typedef char alias_setup_skin_layout[
		(offsetof(maliasskindesc_t, type) == 0 &&
		offsetof(maliasskindesc_t, pcachespot) == 4 &&
		offsetof(maliasskindesc_t, skin) == 8 &&
		sizeof(maliasskindesc_t) == 12 &&
		offsetof(maliasskingroup_t, numskins) == 0 &&
		offsetof(maliasskingroup_t, intervals) == 4 &&
		offsetof(maliasskingroup_t, skindescs) == 8 &&
		offsetof(aliashdr_t, skindesc) == 8 &&
		ALIAS_SKIN_SINGLE == 0 && ALIAS_SKIN_GROUP == 1) ? 1 : -1];
#endif

#define LIGHT_MIN	5		// lowest light value we'll allow, to avoid the
							//  need for inner-loop light clamping

mtriangle_t		*ptriangles;
affinetridesc_t	r_affinetridesc;

void *			acolormap;	// FIXME: should go away

trivertx_t		*r_apverts;

// TODO: these probably will go away with optimized rasterization
mdl_t				*pmdl;
vec3_t				r_plightvec;
int					r_ambientlight;
float				r_shadelight;
aliashdr_t			*paliashdr;
finalvert_t			*pfinalverts;
auxvert_t			*pauxverts;
float			ziscale;
static model_t		*pmodel __attribute__((used));
static entity_t		*alias_transform_entity __attribute__((used));
static int			alias_transform_mode __attribute__((used));

static vec3_t alias_forward __attribute__((used)),alias_right __attribute__((used)),alias_up __attribute__((used));
static float		alias_viewmatrix[3][4] __attribute__((used));
#ifdef ASM486_RENDER_DISPATCH
/* The assembly adapter writes the same private matrix used by transform setup. */
__asm__(".globl _r_dispatch_alias_viewmatrix\n.set _r_dispatch_alias_viewmatrix,_alias_viewmatrix");
#endif

static maliasskindesc_t	*pskindesc __attribute__((used));
#ifdef ASM486_ALIAS_CONTROL
/* Retain the original private C data; assembly owns the instructions that use it. */
float aliascontrol_tmatrix[3][4];
__asm__(".globl _aliascontrol_pmodel\n.set _aliascontrol_pmodel,_pmodel");
__asm__(".globl _aliascontrol_alias_transform_entity\n.set _aliascontrol_alias_transform_entity,_alias_transform_entity");
__asm__(".globl _aliascontrol_alias_transform_mode\n.set _aliascontrol_alias_transform_mode,_alias_transform_mode");
__asm__(".globl _aliascontrol_alias_forward\n.set _aliascontrol_alias_forward,_alias_forward");
__asm__(".globl _aliascontrol_alias_right\n.set _aliascontrol_alias_right,_alias_right");
__asm__(".globl _aliascontrol_alias_up\n.set _aliascontrol_alias_up,_alias_up");
__asm__(".globl _aliascontrol_alias_viewmatrix\n.set _aliascontrol_alias_viewmatrix,_alias_viewmatrix");
__asm__(".globl _aliascontrol_pskindesc\n.set _aliascontrol_pskindesc,_pskindesc");
#endif


int				r_amodels_drawn;
int				a_skinwidth;
int				r_anumverts;

float	aliastransform[3][4];

typedef struct {
	int	index0;
	int	index1;
} aedge_t;

static aedge_t	aedges[12] = {
{0, 1}, {1, 2}, {2, 3}, {3, 0},
{4, 5}, {5, 6}, {6, 7}, {7, 4},
{0, 5}, {1, 4}, {2, 7}, {3, 6}
};

#define NUMVERTEXNORMALS	162

float	r_avertexnormals[NUMVERTEXNORMALS][3] = {
#include "anorms.h"
};

void R_AliasTransformAndProjectFinalVerts (finalvert_t *fv,
	stvert_t *pstverts);
void R_AliasSetUpTransform (int trivial_accept);
void R_AliasTransformVector (vec3_t in, vec3_t out);
#ifdef ASM486_ALIAS_BBOX_PROJECT
void R_AliasTransformVector_asm486 (vec3_t in, vec3_t out);
#endif
void R_AliasTransformFinalVert (finalvert_t *fv, auxvert_t *av,
	trivertx_t *pverts, stvert_t *pstverts);
void R_AliasProjectFinalVert (finalvert_t *fv, auxvert_t *av);
#ifdef ASM486_ALIAS_MATRIX_COMPOSE_ASM
void R_AliasSetViewMatrix_asm486 (const float *right, const float *up,
		const float *forward, float *out);
#endif
#ifdef ASM486_ALIAS_PREPARE
void R_AliasPreparePointsVertices_asm486 (finalvert_t *fv, auxvert_t *av,
	trivertx_t *pverts, stvert_t *pstverts, int numverts);
#endif


/*
================
R_AliasCheckBBox
================
*/
#if !defined(ASM486_ALIAS_CONTROL)
qboolean R_AliasCheckBBox (void)
{
	int					i, flags, frame, numv;
	aliashdr_t			*pahdr;
	float				zi, basepts[8][3], v0, v1, frac;
	finalvert_t			*pv0, *pv1, viewpts[16];
	auxvert_t			*pa0, *pa1, viewaux[16];
	maliasframedesc_t	*pframedesc;
	qboolean			zclipped, zfullyclipped;
	unsigned			anyclip, allclip;
	int					minz;

	alias_transform_entity = NULL;
	
// expand, rotate, and translate points into worldspace

	currententity->trivial_accept = 0;
	pmodel = currententity->model;
	pahdr = Mod_Extradata (pmodel);
	pmdl = (mdl_t *)((byte *)pahdr + pahdr->model);

	R_AliasSetUpTransform (0);

// construct the base bounding box for this frame
	frame = currententity->frame;
// TODO: don't repeat this check when drawing?
	if ((frame >= pmdl->numframes) || (frame < 0))
	{
		Con_DPrintf ("No such frame %d %s\n", frame,
				pmodel->name);
		frame = 0;
	}

	pframedesc = &pahdr->frames[frame];

// x worldspace coordinates
	basepts[0][0] = basepts[1][0] = basepts[2][0] = basepts[3][0] =
			(float)pframedesc->bboxmin.v[0];
	basepts[4][0] = basepts[5][0] = basepts[6][0] = basepts[7][0] =
			(float)pframedesc->bboxmax.v[0];

// y worldspace coordinates
	basepts[0][1] = basepts[3][1] = basepts[5][1] = basepts[6][1] =
			(float)pframedesc->bboxmin.v[1];
	basepts[1][1] = basepts[2][1] = basepts[4][1] = basepts[7][1] =
			(float)pframedesc->bboxmax.v[1];

// z worldspace coordinates
	basepts[0][2] = basepts[1][2] = basepts[4][2] = basepts[5][2] =
			(float)pframedesc->bboxmin.v[2];
	basepts[2][2] = basepts[3][2] = basepts[6][2] = basepts[7][2] =
			(float)pframedesc->bboxmax.v[2];

	zclipped = false;
	zfullyclipped = true;

	minz = 9999;
	for (i=0; i<8 ; i++)
	{
		R_AliasTransformVector  (&basepts[i][0], &viewaux[i].fv[0]);

		if (viewaux[i].fv[2] < ALIAS_Z_CLIP_PLANE)
		{
		// we must clip points that are closer than the near clip plane
			viewpts[i].flags = ALIAS_Z_CLIP;
			zclipped = true;
		}
		else
		{
			if (viewaux[i].fv[2] < minz)
				minz = viewaux[i].fv[2];
			viewpts[i].flags = 0;
			zfullyclipped = false;
		}
	}

	
	if (zfullyclipped)
	{
		return false;	// everything was near-z-clipped
	}

	numv = 8;

	if (zclipped)
	{
	// organize points by edges, use edges to get new points (possible trivial
	// reject)
		for (i=0 ; i<12 ; i++)
		{
		// edge endpoints
			pv0 = &viewpts[aedges[i].index0];
			pv1 = &viewpts[aedges[i].index1];
			pa0 = &viewaux[aedges[i].index0];
			pa1 = &viewaux[aedges[i].index1];

		// if one end is clipped and the other isn't, make a new point
			if (pv0->flags ^ pv1->flags)
			{
				frac = (ALIAS_Z_CLIP_PLANE - pa0->fv[2]) /
					   (pa1->fv[2] - pa0->fv[2]);
				viewaux[numv].fv[0] = pa0->fv[0] +
						(pa1->fv[0] - pa0->fv[0]) * frac;
				viewaux[numv].fv[1] = pa0->fv[1] +
						(pa1->fv[1] - pa0->fv[1]) * frac;
				viewaux[numv].fv[2] = ALIAS_Z_CLIP_PLANE;
				viewpts[numv].flags = 0;
				numv++;
			}
		}
	}

// project the vertices that remain after clipping
	anyclip = 0;
	allclip = ALIAS_XY_CLIP_MASK;

#ifdef ASM486_ALIAS_BBOX_PROJECT
	{
		int clipresult;

		clipresult = R_AliasCheckBBoxProject_asm486 (viewaux, viewpts, numv);
		anyclip = clipresult & 0xff;
		allclip = (clipresult >> 8) & 0xff;
	}
#else
// Keep the original C loop as the reference implementation for comparison.
	for (i=0 ; i<numv ; i++)
	{
	// we don't need to bother with vertices that were z-clipped
		if (viewpts[i].flags & ALIAS_Z_CLIP)
			continue;

		zi = 1.0 / viewaux[i].fv[2];

	// FIXME: do with chop mode in ASM, or convert to float
		v0 = (viewaux[i].fv[0] * xscale * zi) + xcenter;
		v1 = (viewaux[i].fv[1] * yscale * zi) + ycenter;

		flags = 0;

		if (v0 < r_refdef.fvrectx)
			flags |= ALIAS_LEFT_CLIP;
		if (v1 < r_refdef.fvrecty)
			flags |= ALIAS_TOP_CLIP;
		if (v0 > r_refdef.fvrectright)
			flags |= ALIAS_RIGHT_CLIP;
		if (v1 > r_refdef.fvrectbottom)
			flags |= ALIAS_BOTTOM_CLIP;

		anyclip |= flags;
		allclip &= flags;
	}
#endif

	if (allclip)
		return false;	// trivial reject off one side

#if ASM486_ALIAS_MODEL_OCCLUSION && defined(ASM486_ALIAS_BBOX_PROJECT) && !defined(BENCH486)
	if (R_AliasModelOccluded ())
		return false;
#endif

	currententity->trivial_accept = !anyclip & !zclipped;

	if (currententity->trivial_accept)
	{
		if (minz > (r_aliastransition + (pmdl->size * r_resfudge)))
		{
			currententity->trivial_accept |= 2;
		}
	}

	// R_AliasDrawModel immediately follows this check for world entities.
	// Keep the transform that the check already built, including the scaled
	// form needed by the trivial-accept path.
	if (currententity->trivial_accept)
		R_AliasSetUpTransform (currententity->trivial_accept);
	alias_transform_entity = currententity;
	alias_transform_mode = currententity->trivial_accept;

	return true;
}
#endif

#ifdef BENCH486
/*
===============
R_AliasCheckBBoxProject_C

Reference version of the projection and XY clip loop from R_AliasCheckBBox.
The result packs anyclip in the low byte and allclip in the next byte so the
benchmark can compare the complete loop without changing renderer state.
===============
*/
int R_AliasCheckBBoxProject_C (auxvert_t *viewaux, finalvert_t *viewpts,
	int numv)
{
	int			i, flags;
	float			zi, v0, v1;
	unsigned		anyclip, allclip;

	anyclip = 0;
	allclip = ALIAS_XY_CLIP_MASK;

	for (i=0 ; i<numv ; i++)
	{
		if (viewpts[i].flags & ALIAS_Z_CLIP)
			continue;

		zi = 1.0 / viewaux[i].fv[2];
		v0 = (viewaux[i].fv[0] * aliasxscale * zi) + aliasxcenter;
		v1 = (viewaux[i].fv[1] * aliasyscale * zi) + aliasycenter;

		flags = 0;
		if (v0 < r_refdef.fvrectx)
			flags |= ALIAS_LEFT_CLIP;
		if (v1 < r_refdef.fvrecty)
			flags |= ALIAS_TOP_CLIP;
		if (v0 > r_refdef.fvrectright)
			flags |= ALIAS_RIGHT_CLIP;
		if (v1 > r_refdef.fvrectbottom)
			flags |= ALIAS_BOTTOM_CLIP;

		anyclip |= flags;
		allclip &= flags;
	}

	return (int)(anyclip | (allclip << 8));
}
#endif


/*
================
R_AliasTransformVector
================
*/
#if !defined(ASM486_PUBLIC_BINDINGS) || !defined(ASM486_ALIAS_BBOX_PROJECT)
void R_AliasTransformVector (vec3_t in, vec3_t out)
{
#ifdef ASM486_ALIAS_BBOX_PROJECT
	R_AliasTransformVector_asm486 (in, out);
#else
	out[0] = DotProduct(in, aliastransform[0]) + aliastransform[0][3];
	out[1] = DotProduct(in, aliastransform[1]) + aliastransform[1][3];
	out[2] = DotProduct(in, aliastransform[2]) + aliastransform[2][3];
#endif
}
#endif /* public entry is assembly-owned when selected */

#ifdef BENCH486
void R_AliasTransformVector_C (vec3_t in, vec3_t out)
{
	out[0] = DotProduct(in, aliastransform[0]) + aliastransform[0][3];
	out[1] = DotProduct(in, aliastransform[1]) + aliastransform[1][3];
	out[2] = DotProduct(in, aliastransform[2]) + aliastransform[2][3];
}
#endif


/*
================
R_AliasPreparePoints

General clipped case
================
*/
#if !defined(ASM486_ALIAS_CONTROL)
void R_AliasPreparePoints (void)
{
	int			i;
	stvert_t	*pstverts;
	finalvert_t	*fv;
	auxvert_t	*av;
	mtriangle_t	*ptri;
	finalvert_t	*pfv[3];
#ifdef ASM486_ALIAS_PREPARE_LOCAL
	trivertx_t	*pverts;
#endif

	pstverts = (stvert_t *)((byte *)paliashdr + paliashdr->stverts);
	r_anumverts = pmdl->numverts;
 	fv = pfinalverts;
	av = pauxverts;

	BENCH486_PROFILE_ENTER (BENCH486_PROFILE_ALIAS_TRANSFORM);
#ifdef ASM486_ALIAS_PREPARE
	R_AliasPreparePointsVertices_asm486 (fv, av, r_apverts, pstverts,
			r_anumverts);
#else
#ifdef ASM486_ALIAS_PREPARE_LOCAL
	/*
	 * The transform/project helpers do not mutate r_apverts.  Keep only the
	 * advancing source cursor local; retain the original clip-bound loads and
	 * comparison order because a prior aliasvrect-hoist experiment was
	 * rejected.  Publish the advanced source cursor after the loop because
	 * the control path leaves r_apverts at the same post-incremented address.
	 */
	pverts = r_apverts;
	for (i=0 ; i<r_anumverts ; i++, fv++, av++, pverts++, pstverts++)
	{
		R_AliasTransformFinalVert (fv, av, pverts, pstverts);
		if (av->fv[2] < ALIAS_Z_CLIP_PLANE)
			fv->flags |= ALIAS_Z_CLIP;
		else
		{
			R_AliasProjectFinalVertDispatch (fv, av);

			if (fv->v[0] < r_refdef.aliasvrect.x)
				fv->flags |= ALIAS_LEFT_CLIP;
			if (fv->v[1] < r_refdef.aliasvrect.y)
				fv->flags |= ALIAS_TOP_CLIP;
			if (fv->v[0] > r_refdef.aliasvrectright)
				fv->flags |= ALIAS_RIGHT_CLIP;
			if (fv->v[1] > r_refdef.aliasvrectbottom)
				fv->flags |= ALIAS_BOTTOM_CLIP;
		}
	}
	r_apverts = pverts;
#else
	for (i=0 ; i<r_anumverts ; i++, fv++, av++, r_apverts++, pstverts++)
	{
		R_AliasTransformFinalVert (fv, av, r_apverts, pstverts);
		if (av->fv[2] < ALIAS_Z_CLIP_PLANE)
			fv->flags |= ALIAS_Z_CLIP;
		else
		{
			 R_AliasProjectFinalVertDispatch (fv, av);

			if (fv->v[0] < r_refdef.aliasvrect.x)
				fv->flags |= ALIAS_LEFT_CLIP;
			if (fv->v[1] < r_refdef.aliasvrect.y)
				fv->flags |= ALIAS_TOP_CLIP;
			if (fv->v[0] > r_refdef.aliasvrectright)
				fv->flags |= ALIAS_RIGHT_CLIP;
			if (fv->v[1] > r_refdef.aliasvrectbottom)
				fv->flags |= ALIAS_BOTTOM_CLIP;	
		}
	}
#endif
#endif
	BENCH486_PROFILE_LEAVE ();

//
// clip and draw all triangles
//
	r_affinetridesc.numtriangles = 1;

	BENCH486_PROFILE_ENTER (BENCH486_PROFILE_ALIAS_RASTER);
	ptri = (mtriangle_t *)((byte *)paliashdr + paliashdr->triangles);
	for (i=0 ; i<pmdl->numtris ; i++, ptri++)
	{
		pfv[0] = &pfinalverts[ptri->vertindex[0]];
		pfv[1] = &pfinalverts[ptri->vertindex[1]];
		pfv[2] = &pfinalverts[ptri->vertindex[2]];

		if ( pfv[0]->flags & pfv[1]->flags & pfv[2]->flags & (ALIAS_XY_CLIP_MASK | ALIAS_Z_CLIP) )
			continue;		// completely clipped
		
		if ( ! ( (pfv[0]->flags | pfv[1]->flags | pfv[2]->flags) &
			(ALIAS_XY_CLIP_MASK | ALIAS_Z_CLIP) ) )
		{	// totally unclipped
			r_affinetridesc.pfinalverts = pfinalverts;
			r_affinetridesc.ptriangles = ptri;
			D_PolysetDraw ();
		}
		else		
		{	// partially clipped
			R_AliasClipTriangle (ptri);
		}
	}
	BENCH486_PROFILE_LEAVE ();
}
#endif


/*
================
R_AliasSetViewMatrix

Filled once per frame after vpn/vright/vup are set.  Per-model transform
setup only concatenates this cached view matrix.
================
*/
#if !(defined(ASM486_RENDER_DISPATCH) && defined(ASM486_ALIAS_MATRIX_COMPOSE_ASM))
void R_AliasSetViewMatrix (void)
{
#ifdef ASM486_ALIAS_MATRIX_COMPOSE_ASM
	R_AliasSetViewMatrix_asm486 (vright, vup, vpn, &alias_viewmatrix[0][0]);
#else
	VectorCopy (vright, alias_viewmatrix[0]);
	VectorCopy (vup, alias_viewmatrix[1]);
	VectorInverse (alias_viewmatrix[1]);
	VectorCopy (vpn, alias_viewmatrix[2]);
#endif
}
#endif


/*
================
R_AliasSetUpTransform
================
*/
#if !defined(ASM486_ALIAS_CONTROL)
void R_AliasSetUpTransform (int trivial_accept)
{
	int				i;
	float			rotationmatrix[3][4], t2matrix[3][4];
	static float	tmatrix[3][4];
	vec3_t			angles;

// TODO: should really be stored with the entity instead of being reconstructed
// TODO: should use a look-up table
// TODO: could cache lazily, stored in the entity

	angles[ROLL] = currententity->angles[ROLL];
	angles[PITCH] = -currententity->angles[PITCH];
	angles[YAW] = currententity->angles[YAW];
	AngleVectors (angles, alias_forward, alias_right, alias_up);

	tmatrix[0][0] = pmdl->scale[0];
	tmatrix[1][1] = pmdl->scale[1];
	tmatrix[2][2] = pmdl->scale[2];

	tmatrix[0][3] = pmdl->scale_origin[0];
	tmatrix[1][3] = pmdl->scale_origin[1];
	tmatrix[2][3] = pmdl->scale_origin[2];

// TODO: can do this with simple matrix rearrangement

	for (i=0 ; i<3 ; i++)
	{
		t2matrix[i][0] = alias_forward[i];
		t2matrix[i][1] = -alias_right[i];
		t2matrix[i][2] = alias_up[i];
	}

	t2matrix[0][3] = -modelorg[0];
	t2matrix[1][3] = -modelorg[1];
	t2matrix[2][3] = -modelorg[2];

// FIXME: can do more efficiently than full concatenation
#if defined(ASM486_ALIAS_MATRIX_COMPOSE_ASM)
	R_ConcatTransforms_asm486 (t2matrix, tmatrix, rotationmatrix);
#elif defined(ASM486_ALIAS_MATRIX_COMPOSE)
	for (i=0 ; i<3 ; i++)
	{
		rotationmatrix[i][0] = t2matrix[i][0] * tmatrix[0][0];
		rotationmatrix[i][1] = t2matrix[i][1] * tmatrix[1][1];
		rotationmatrix[i][2] = t2matrix[i][2] * tmatrix[2][2];
		rotationmatrix[i][3] = t2matrix[i][0] * tmatrix[0][3] +
				t2matrix[i][1] * tmatrix[1][3] +
				t2matrix[i][2] * tmatrix[2][3] + t2matrix[i][3];
	}
#else
	R_ConcatTransforms (t2matrix, tmatrix, rotationmatrix);
#endif
#if defined(ASM486_ALIAS_MATRIX_COMPOSE_ASM)
	R_ConcatTransforms_asm486 (alias_viewmatrix, rotationmatrix, aliastransform);
#else
	R_ConcatTransforms (alias_viewmatrix, rotationmatrix, aliastransform);
#endif

// do the scaling up of x and y to screen coordinates as part of the transform
// for the unclipped case (it would mess up clipping in the clipped case).
// Also scale down z, so 1/z is scaled 31 bits for free, and scale down x and y
// correspondingly so the projected x and y come out right
// FIXME: make this work for clipped case too?
	if (trivial_accept)
	{
		for (i=0 ; i<4 ; i++)
		{
			aliastransform[0][i] *= aliasxscale *
					(1.0 / ((float)0x8000 * 0x10000));
			aliastransform[1][i] *= aliasyscale *
					(1.0 / ((float)0x8000 * 0x10000));
			aliastransform[2][i] *= 1.0 / ((float)0x8000 * 0x10000);

		}
	}
}
#endif


/*
================
R_AliasTransformFinalVert
================
*/
#if !defined(ASM486_PUBLIC_BINDINGS) || !defined(ASM486_ALIAS_TRANSFORM_FINAL)
void R_AliasTransformFinalVert (finalvert_t *fv, auxvert_t *av,
	trivertx_t *pverts, stvert_t *pstverts)
{
#ifdef ASM486_ALIAS_TRANSFORM_FINAL
	R_AliasTransformFinalVert_asm486 (fv, av, pverts, pstverts);
#else
	int		temp;
	float	lightcos, *plightnormal;

	av->fv[0] = DotProduct(pverts->v, aliastransform[0]) +
			aliastransform[0][3];
	av->fv[1] = DotProduct(pverts->v, aliastransform[1]) +
			aliastransform[1][3];
	av->fv[2] = DotProduct(pverts->v, aliastransform[2]) +
			aliastransform[2][3];

	fv->v[2] = pstverts->s;
	fv->v[3] = pstverts->t;

	fv->flags = pstverts->onseam;

// lighting
	plightnormal = r_avertexnormals[pverts->lightnormalindex];
	lightcos = DotProduct (plightnormal, r_plightvec);
	temp = r_ambientlight;

	if (lightcos < 0)
	{
		temp += (int)(r_shadelight * lightcos);

	// clamp; because we limited the minimum ambient and shading light, we
	// don't have to clamp low light, just bright
		if (temp < 0)
			temp = 0;
	}

	fv->v[4] = temp;
#endif
}
#endif /* public entry is assembly-owned when selected */

#ifdef BENCH486
/*
===============
R_AliasTransformFinalVert_C

Reference version of the clipped alias vertex transform and lighting helper.
*/
void R_AliasTransformFinalVert_C (finalvert_t *fv, auxvert_t *av,
	trivertx_t *pverts, stvert_t *pstverts)
{
	int		temp;
	float	lightcos, *plightnormal;

	av->fv[0] = DotProduct(pverts->v, aliastransform[0]) +
			aliastransform[0][3];
	av->fv[1] = DotProduct(pverts->v, aliastransform[1]) +
			aliastransform[1][3];
	av->fv[2] = DotProduct(pverts->v, aliastransform[2]) +
			aliastransform[2][3];

	fv->v[2] = pstverts->s;
	fv->v[3] = pstverts->t;

	fv->flags = pstverts->onseam;

// lighting
	plightnormal = r_avertexnormals[pverts->lightnormalindex];
	lightcos = DotProduct (plightnormal, r_plightvec);
	temp = r_ambientlight;

	if (lightcos < 0)
	{
		temp += (int)(r_shadelight * lightcos);

	// clamp; because we limited the minimum ambient and shading light, we
	// don't have to clamp low light, just bright
		if (temp < 0)
			temp = 0;
	}

	fv->v[4] = temp;
}
#endif


#if	!id386

/*
================
R_AliasTransformAndProjectFinalVerts
================
*/
void R_AliasTransformAndProjectFinalVerts (finalvert_t *fv, stvert_t *pstverts)
{
	int			i, temp;
	float		lightcos, *plightnormal, zi;
	trivertx_t	*pverts;

	pverts = r_apverts;

	for (i=0 ; i<r_anumverts ; i++, fv++, pverts++, pstverts++)
	{
	// transform and project
		zi = 1.0 / (DotProduct(pverts->v, aliastransform[2]) +
				aliastransform[2][3]);

	// x, y, and z are scaled down by 1/2**31 in the transform, so 1/z is
	// scaled up by 1/2**31, and the scaling cancels out for x and y in the
	// projection
		fv->v[5] = zi;

		fv->v[0] = ((DotProduct(pverts->v, aliastransform[0]) +
				aliastransform[0][3]) * zi) + aliasxcenter;
		fv->v[1] = ((DotProduct(pverts->v, aliastransform[1]) +
				aliastransform[1][3]) * zi) + aliasycenter;

		fv->v[2] = pstverts->s;
		fv->v[3] = pstverts->t;
		fv->flags = pstverts->onseam;

	// lighting
		plightnormal = r_avertexnormals[pverts->lightnormalindex];
		lightcos = DotProduct (plightnormal, r_plightvec);
		temp = r_ambientlight;

		if (lightcos < 0)
		{
			temp += (int)(r_shadelight * lightcos);

		// clamp; because we limited the minimum ambient and shading light, we
		// don't have to clamp low light, just bright
			if (temp < 0)
				temp = 0;
		}

		fv->v[4] = temp;
	}
}

#endif


/*
================
R_AliasProjectFinalVert
================
*/
#if !defined(ASM486_ALIAS_CONTROL)
void R_AliasProjectFinalVert (finalvert_t *fv, auxvert_t *av)
{
	float	zi;

// project points
	zi = 1.0 / av->fv[2];

	fv->v[5] = zi * ziscale;

	fv->v[0] = (av->fv[0] * aliasxscale * zi) + aliasxcenter;
	fv->v[1] = (av->fv[1] * aliasyscale * zi) + aliasycenter;
}
#endif


/*
================
R_AliasPrepareUnclippedPoints
================
*/
#if !defined(ASM486_ALIAS_CONTROL)
void R_AliasPrepareUnclippedPoints (void)
{
	stvert_t	*pstverts;
	finalvert_t	*fv;

	pstverts = (stvert_t *)((byte *)paliashdr + paliashdr->stverts);
	r_anumverts = pmdl->numverts;
// FIXME: just use pfinalverts directly?
	fv = pfinalverts;

	BENCH486_PROFILE_ENTER (BENCH486_PROFILE_ALIAS_TRANSFORM);
	R_AliasTransformAndProjectFinalVerts (fv, pstverts);
	BENCH486_PROFILE_LEAVE ();

	if (r_affinetridesc.drawtype)
		D_PolysetDrawFinalVerts (fv, r_anumverts);

	r_affinetridesc.pfinalverts = pfinalverts;
	r_affinetridesc.ptriangles = (mtriangle_t *)
			((byte *)paliashdr + paliashdr->triangles);
	r_affinetridesc.numtriangles = pmdl->numtris;

	BENCH486_PROFILE_ENTER (BENCH486_PROFILE_ALIAS_RASTER);
	D_PolysetDraw ();
	BENCH486_PROFILE_LEAVE ();
}
#endif

/*
===============
R_AliasSetupSkin
===============
*/
#if !defined(ASM486_ALIAS_CONTROL)
void R_AliasSetupSkin (void)
{
	int					skinnum;

	skinnum = currententity->skinnum;
	if ((skinnum >= pmdl->numskins) || (skinnum < 0))
	{
		Con_DPrintf ("R_AliasSetupSkin: no such skin # %d\n", skinnum);
		skinnum = 0;
	}

#ifdef ASM486_ALIAS_SETUP_SKIN
	pskindesc = R_AliasSetupSkinSelect_asm486 (skinnum, cl.time,
			currententity->syncbase);
#else
	pskindesc = R_AliasSetupSkinSelect_C (skinnum, cl.time,
			currententity->syncbase);
#endif
	a_skinwidth = pmdl->skinwidth;

	r_affinetridesc.pskindesc = pskindesc;
	r_affinetridesc.pskin = (void *)((byte *)paliashdr + pskindesc->skin);
	r_affinetridesc.skinwidth = a_skinwidth;
	r_affinetridesc.seamfixupX16 =  (a_skinwidth >> 1) << 16;
	r_affinetridesc.skinheight = pmdl->skinheight;
}
#endif

#if !defined(ASM486_ALIAS_SETUP_SKIN) || defined(BENCH486)
maliasskindesc_t *R_AliasSetupSkinSelect_C (int skinnum, double cltime,
		float syncbase)
{
	int				i, numskins;
	maliasskingroup_t	*paliasskingroup;
	maliasskindesc_t	*selected;
	float				*pskinintervals, fullskininterval;
	float				skintargettime, skintime;

	selected = ((maliasskindesc_t *)
			((byte *)paliashdr + paliashdr->skindesc)) + skinnum;

	if (selected->type == ALIAS_SKIN_GROUP)
	{
		paliasskingroup = (maliasskingroup_t *)((byte *)paliashdr +
				selected->skin);
		pskinintervals = (float *)
				((byte *)paliashdr + paliasskingroup->intervals);
		numskins = paliasskingroup->numskins;
		fullskininterval = pskinintervals[numskins-1];
		skintime = cltime + syncbase;

		// Mod_LoadAliasSkinGroup guarantees positive interval values.
		skintargettime = skintime -
				((int)(skintime / fullskininterval)) * fullskininterval;

		for (i=0 ; i<(numskins-1) ; i++)
		{
			if (pskinintervals[i] > skintargettime)
				break;
		}

		selected = &paliasskingroup->skindescs[i];
	}

	return selected;
}
#endif

#ifdef ASM486_ALIAS_SETUP_SKIN
maliasskindesc_t *R_AliasSetupSkinSelect_asm486 (int skinnum,
		double cltime, float syncbase);
#endif

/*
================
R_AliasSetupLighting
================
*/
#if !defined(ASM486_ALIAS_SETUP_LIGHTING) || defined(BENCH486)
void R_AliasSetupLighting_C (alight_t *plighting, const float *forward,
		const float *right, const float *up)
{

// guarantee that no vertex will ever be lit below LIGHT_MIN, so we don't have
// to clamp off the bottom
	r_ambientlight = plighting->ambientlight;

	if (r_ambientlight < LIGHT_MIN)
		r_ambientlight = LIGHT_MIN;

	r_ambientlight = (255 - r_ambientlight) << VID_CBITS;

	if (r_ambientlight < LIGHT_MIN)
		r_ambientlight = LIGHT_MIN;

	r_shadelight = plighting->shadelight;

	if (r_shadelight < 0)
		r_shadelight = 0;

	r_shadelight *= VID_GRADES;

// rotate the lighting vector into the model's frame of reference
	r_plightvec[0] = DotProduct (plighting->plightvec, forward);
	r_plightvec[1] = -DotProduct (plighting->plightvec, right);
	r_plightvec[2] = DotProduct (plighting->plightvec, up);
}
#endif

#ifdef ASM486_ALIAS_SETUP_LIGHTING
void R_AliasSetupLighting_asm486 (alight_t *plighting,
		const float *forward, const float *right, const float *up);
#endif

#if !defined(ASM486_ALIAS_CONTROL)
void R_AliasSetupLighting (alight_t *plighting)
{
#ifdef ASM486_ALIAS_SETUP_LIGHTING
	R_AliasSetupLighting_asm486 (plighting, alias_forward, alias_right,
			alias_up);
#else
	R_AliasSetupLighting_C (plighting, alias_forward, alias_right, alias_up);
#endif
}
#endif

/*
=================
R_AliasSetupFrame

set r_apverts
=================
*/
#if !defined(ASM486_ALIAS_SETUP_FRAME) || defined(BENCH486)
void R_AliasSetupFrame_C (int frame, double cltime, float syncbase)
{
	int				i, numframes;
	maliasgroup_t	*paliasgroup;
	float			*pintervals, fullinterval, targettime, time;

	if (paliashdr->frames[frame].type == ALIAS_SINGLE)
	{
		r_apverts = (trivertx_t *)
				((byte *)paliashdr + paliashdr->frames[frame].frame);
		return;
	}
	
	paliasgroup = (maliasgroup_t *)
				((byte *)paliashdr + paliashdr->frames[frame].frame);
	pintervals = (float *)((byte *)paliashdr + paliasgroup->intervals);
	numframes = paliasgroup->numframes;
	fullinterval = pintervals[numframes-1];

	time = cltime + syncbase;

//
// when loading in Mod_LoadAliasGroup, we guaranteed all interval values
// are positive, so we don't have to worry about division by 0
//
	targettime = time - ((int)(time / fullinterval)) * fullinterval;

	for (i=0 ; i<(numframes-1) ; i++)
	{
		if (pintervals[i] > targettime)
			break;
	}

	r_apverts = (trivertx_t *)
				((byte *)paliashdr + paliasgroup->frames[i].frame);
}
#endif

#ifdef ASM486_ALIAS_SETUP_FRAME
void R_AliasSetupFrame_asm486 (int frame, double cltime, float syncbase);
#endif

#if !defined(ASM486_ALIAS_CONTROL)
void R_AliasSetupFrame (void)
{
	int			frame;

	frame = currententity->frame;
	if ((frame >= pmdl->numframes) || (frame < 0))
	{
		Con_DPrintf ("R_AliasSetupFrame: no such frame %d\n", frame);
		frame = 0;
	}

#ifdef ASM486_ALIAS_SETUP_FRAME
	R_AliasSetupFrame_asm486 (frame, cl.time, currententity->syncbase);
#else
	R_AliasSetupFrame_C (frame, cl.time, currententity->syncbase);
#endif
}
#endif


/*
================
R_AliasDrawModel
================
*/
#if !defined(ASM486_ALIAS_CONTROL)
void __attribute__((regparm(1))) R_AliasDrawModel (alight_t *plighting)
{
	finalvert_t		finalverts[MAXALIASVERTS +
						((CACHE_SIZE - 1) / sizeof(finalvert_t)) + 1];
	auxvert_t		auxverts[MAXALIASVERTS];
#ifdef PROFILE486
	double			bench486_alias_start;
#endif
	BENCH486_PROFILE_ENTER (BENCH486_PROFILE_ALIAS_MODEL);

#ifdef PROFILE486
	if (bench486_profile_frame_active)
		bench486_alias_start = Sys_FloatTime ();
#endif

	r_amodels_drawn++;

#ifdef PROFILE486
	if (bench486_profile_frame_active)
		bench486_alias_models++;
#endif

// cache align
	pfinalverts = (finalvert_t *)
			(((long)&finalverts[0] + CACHE_SIZE - 1) & ~(CACHE_SIZE - 1));
	pauxverts = &auxverts[0];

	paliashdr = (aliashdr_t *)Mod_Extradata (currententity->model);
	pmdl = (mdl_t *)((byte *)paliashdr + paliashdr->model);

#ifdef PROFILE486
	if (bench486_profile_frame_active)
		bench486_alias_vertices += pmdl->numverts;
#endif
	BENCH486_PROFILE_WORK (BENCH486_PROFILE_ALIAS_MODEL, 1,
			(unsigned long)pmdl->numverts);

	BENCH486_PROFILE_ENTER (BENCH486_PROFILE_ALIAS_SETUP);
	R_AliasSetupSkin ();
	if (alias_transform_entity != currententity ||
			alias_transform_mode != currententity->trivial_accept)
		R_AliasSetUpTransform (currententity->trivial_accept);
	alias_transform_entity = NULL;
	R_AliasSetupLighting (plighting);
	R_AliasSetupFrame ();

	if (!currententity->colormap)
		Sys_Error ("R_AliasDrawModel: !currententity->colormap");

	r_affinetridesc.drawtype = (currententity->trivial_accept == 3) &&
			r_recursiveaffinetriangles;

	if (r_affinetridesc.drawtype)
	{
		D_PolysetUpdateTables ();		// FIXME: precalc...
	}
	else
	{
#if	id386
		D_Aff8Patch (currententity->colormap);
#endif
	}

	acolormap = currententity->colormap;

	if (currententity != &cl.viewent)
		ziscale = (float)0x8000 * (float)0x10000;
	else
		ziscale = (float)0x8000 * (float)0x10000 * 3.0;
	BENCH486_PROFILE_LEAVE ();

	if (currententity->trivial_accept)
		R_AliasPrepareUnclippedPoints ();
	else
		R_AliasPreparePoints ();

#ifdef PROFILE486
	if (bench486_profile_frame_active)
		bench486_alias_seconds += Sys_FloatTime () - bench486_alias_start;
#endif
	BENCH486_PROFILE_LEAVE ();
}
#endif

/* Pinned original argument adapters, compiled only as independent test oracles. */
#if defined(BENCH486) && defined(ASM486_RENDER_DISPATCH) && defined(ASM486_ALIAS_MATRIX_COMPOSE_ASM)
void R_AliasSetViewMatrix_Dispatch_C (void)
{
#ifdef ASM486_ALIAS_MATRIX_COMPOSE_ASM
	Bench486DispatchAliasView (vright, vup, vpn, &alias_viewmatrix[0][0]);
#else
	VectorCopy (vright, alias_viewmatrix[0]);
	VectorCopy (vup, alias_viewmatrix[1]);
	VectorInverse (alias_viewmatrix[1]);
	VectorCopy (vpn, alias_viewmatrix[2]);
#endif
}
#endif

#if defined(BENCH486) && defined(ASM486_ALIAS_CONTROL)
#include "aliascontrol_bench_hooks.inc"
#define Bench486ProfileEnter Bench486AliasControlProfileEnter
#define Bench486ProfileLeave Bench486AliasControlProfileLeave
#define Bench486ProfileWork Bench486AliasControlProfileWork
qboolean R_AliasCheckBBox_AliasControl_C (void)
{
	int					i, flags, frame, numv;
	aliashdr_t			*pahdr;
	float				zi, basepts[8][3], v0, v1, frac;
	finalvert_t			*pv0, *pv1, viewpts[16];
	auxvert_t			*pa0, *pa1, viewaux[16];
	maliasframedesc_t	*pframedesc;
	qboolean			zclipped, zfullyclipped;
	unsigned			anyclip, allclip;
	int					minz;

	alias_transform_entity = NULL;

// expand, rotate, and translate points into worldspace

	currententity->trivial_accept = 0;
	pmodel = currententity->model;
	pahdr = Bench486AliasControlModel (pmodel);
	pmdl = (mdl_t *)((byte *)pahdr + pahdr->model);

	R_AliasSetUpTransform_AliasControl_C (0);

// construct the base bounding box for this frame
	frame = currententity->frame;
// TODO: don't repeat this check when drawing?
	if ((frame >= pmdl->numframes) || (frame < 0))
	{
		Bench486AliasControlPrint ("No such frame %d %s\n", frame,
				pmodel->name);
		frame = 0;
	}

	pframedesc = &pahdr->frames[frame];

// x worldspace coordinates
	basepts[0][0] = basepts[1][0] = basepts[2][0] = basepts[3][0] =
			(float)pframedesc->bboxmin.v[0];
	basepts[4][0] = basepts[5][0] = basepts[6][0] = basepts[7][0] =
			(float)pframedesc->bboxmax.v[0];

// y worldspace coordinates
	basepts[0][1] = basepts[3][1] = basepts[5][1] = basepts[6][1] =
			(float)pframedesc->bboxmin.v[1];
	basepts[1][1] = basepts[2][1] = basepts[4][1] = basepts[7][1] =
			(float)pframedesc->bboxmax.v[1];

// z worldspace coordinates
	basepts[0][2] = basepts[1][2] = basepts[4][2] = basepts[5][2] =
			(float)pframedesc->bboxmin.v[2];
	basepts[2][2] = basepts[3][2] = basepts[6][2] = basepts[7][2] =
			(float)pframedesc->bboxmax.v[2];

	zclipped = false;
	zfullyclipped = true;

	minz = 9999;
	for (i=0; i<8 ; i++)
	{
		R_AliasTransformVector  (&basepts[i][0], &viewaux[i].fv[0]);

		if (viewaux[i].fv[2] < ALIAS_Z_CLIP_PLANE)
		{
		// we must clip points that are closer than the near clip plane
			viewpts[i].flags = ALIAS_Z_CLIP;
			zclipped = true;
		}
		else
		{
			if (viewaux[i].fv[2] < minz)
				minz = viewaux[i].fv[2];
			viewpts[i].flags = 0;
			zfullyclipped = false;
		}
	}


	if (zfullyclipped)
	{
		return false;	// everything was near-z-clipped
	}

	numv = 8;

	if (zclipped)
	{
	// organize points by edges, use edges to get new points (possible trivial
	// reject)
		for (i=0 ; i<12 ; i++)
		{
		// edge endpoints
			pv0 = &viewpts[aedges[i].index0];
			pv1 = &viewpts[aedges[i].index1];
			pa0 = &viewaux[aedges[i].index0];
			pa1 = &viewaux[aedges[i].index1];

		// if one end is clipped and the other isn't, make a new point
			if (pv0->flags ^ pv1->flags)
			{
				frac = (ALIAS_Z_CLIP_PLANE - pa0->fv[2]) /
					   (pa1->fv[2] - pa0->fv[2]);
				viewaux[numv].fv[0] = pa0->fv[0] +
						(pa1->fv[0] - pa0->fv[0]) * frac;
				viewaux[numv].fv[1] = pa0->fv[1] +
						(pa1->fv[1] - pa0->fv[1]) * frac;
				viewaux[numv].fv[2] = ALIAS_Z_CLIP_PLANE;
				viewpts[numv].flags = 0;
				numv++;
			}
		}
	}

// project the vertices that remain after clipping
	anyclip = 0;
	allclip = ALIAS_XY_CLIP_MASK;

#ifdef ASM486_ALIAS_BBOX_PROJECT
	{
		int clipresult;

		clipresult = R_AliasCheckBBoxProject_asm486 (viewaux, viewpts, numv);
		anyclip = clipresult & 0xff;
		allclip = (clipresult >> 8) & 0xff;
	}
#else
// Keep the original C loop as the reference implementation for comparison.
	for (i=0 ; i<numv ; i++)
	{
	// we don't need to bother with vertices that were z-clipped
		if (viewpts[i].flags & ALIAS_Z_CLIP)
			continue;

		zi = 1.0 / viewaux[i].fv[2];

	// FIXME: do with chop mode in ASM, or convert to float
		v0 = (viewaux[i].fv[0] * xscale * zi) + xcenter;
		v1 = (viewaux[i].fv[1] * yscale * zi) + ycenter;

		flags = 0;

		if (v0 < r_refdef.fvrectx)
			flags |= ALIAS_LEFT_CLIP;
		if (v1 < r_refdef.fvrecty)
			flags |= ALIAS_TOP_CLIP;
		if (v0 > r_refdef.fvrectright)
			flags |= ALIAS_RIGHT_CLIP;
		if (v1 > r_refdef.fvrectbottom)
			flags |= ALIAS_BOTTOM_CLIP;

		anyclip |= flags;
		allclip &= flags;
	}
#endif

	if (allclip)
		return false;	// trivial reject off one side

	currententity->trivial_accept = !anyclip & !zclipped;

	if (currententity->trivial_accept)
	{
		if (minz > (r_aliastransition + (pmdl->size * r_resfudge)))
		{
			currententity->trivial_accept |= 2;
		}
	}

	// R_AliasDrawModel_AliasControl_C immediately follows this check for world entities.
	// Keep the transform that the check already built, including the scaled
	// form needed by the trivial-accept path.
	if (currententity->trivial_accept)
		R_AliasSetUpTransform_AliasControl_C (currententity->trivial_accept);
	alias_transform_entity = currententity;
	alias_transform_mode = currententity->trivial_accept;

	return true;
}

void R_AliasPreparePoints_AliasControl_C (void)
{
	int			i;
	stvert_t	*pstverts;
	finalvert_t	*fv;
	auxvert_t	*av;
	mtriangle_t	*ptri;
	finalvert_t	*pfv[3];
#ifdef ASM486_ALIAS_PREPARE_LOCAL
	trivertx_t	*pverts;
#endif

	pstverts = (stvert_t *)((byte *)paliashdr + paliashdr->stverts);
	r_anumverts = pmdl->numverts;
	fv = pfinalverts;
	av = pauxverts;

	BENCH486_PROFILE_ENTER (BENCH486_PROFILE_ALIAS_TRANSFORM);
#ifdef ASM486_ALIAS_PREPARE
	R_AliasPreparePointsVertices_asm486 (fv, av, r_apverts, pstverts,
			r_anumverts);
#else
#ifdef ASM486_ALIAS_PREPARE_LOCAL
	/*
	 * The transform/project helpers do not mutate r_apverts.  Keep only the
	 * advancing source cursor local; retain the original clip-bound loads and
	 * comparison order because a prior aliasvrect-hoist experiment was
	 * rejected.  Publish the advanced source cursor after the loop because
	 * the control path leaves r_apverts at the same post-incremented address.
	 */
	pverts = r_apverts;
	for (i=0 ; i<r_anumverts ; i++, fv++, av++, pverts++, pstverts++)
	{
		R_AliasTransformFinalVert (fv, av, pverts, pstverts);
		if (av->fv[2] < ALIAS_Z_CLIP_PLANE)
			fv->flags |= ALIAS_Z_CLIP;
		else
		{
			R_AliasProjectFinalVertDispatch (fv, av);

			if (fv->v[0] < r_refdef.aliasvrect.x)
				fv->flags |= ALIAS_LEFT_CLIP;
			if (fv->v[1] < r_refdef.aliasvrect.y)
				fv->flags |= ALIAS_TOP_CLIP;
			if (fv->v[0] > r_refdef.aliasvrectright)
				fv->flags |= ALIAS_RIGHT_CLIP;
			if (fv->v[1] > r_refdef.aliasvrectbottom)
				fv->flags |= ALIAS_BOTTOM_CLIP;
		}
	}
	r_apverts = pverts;
#else
	for (i=0 ; i<r_anumverts ; i++, fv++, av++, r_apverts++, pstverts++)
	{
		R_AliasTransformFinalVert (fv, av, r_apverts, pstverts);
		if (av->fv[2] < ALIAS_Z_CLIP_PLANE)
			fv->flags |= ALIAS_Z_CLIP;
		else
		{
			 R_AliasProjectFinalVertDispatch (fv, av);

			if (fv->v[0] < r_refdef.aliasvrect.x)
				fv->flags |= ALIAS_LEFT_CLIP;
			if (fv->v[1] < r_refdef.aliasvrect.y)
				fv->flags |= ALIAS_TOP_CLIP;
			if (fv->v[0] > r_refdef.aliasvrectright)
				fv->flags |= ALIAS_RIGHT_CLIP;
			if (fv->v[1] > r_refdef.aliasvrectbottom)
				fv->flags |= ALIAS_BOTTOM_CLIP;
		}
	}
#endif
#endif
	BENCH486_PROFILE_LEAVE ();

//
// clip and draw all triangles
//
	r_affinetridesc.numtriangles = 1;

	BENCH486_PROFILE_ENTER (BENCH486_PROFILE_ALIAS_RASTER);
	ptri = (mtriangle_t *)((byte *)paliashdr + paliashdr->triangles);
	for (i=0 ; i<pmdl->numtris ; i++, ptri++)
	{
		pfv[0] = &pfinalverts[ptri->vertindex[0]];
		pfv[1] = &pfinalverts[ptri->vertindex[1]];
		pfv[2] = &pfinalverts[ptri->vertindex[2]];

		if ( pfv[0]->flags & pfv[1]->flags & pfv[2]->flags & (ALIAS_XY_CLIP_MASK | ALIAS_Z_CLIP) )
			continue;		// completely clipped

		if ( ! ( (pfv[0]->flags | pfv[1]->flags | pfv[2]->flags) &
			(ALIAS_XY_CLIP_MASK | ALIAS_Z_CLIP) ) )
		{	// totally unclipped
			r_affinetridesc.pfinalverts = pfinalverts;
			r_affinetridesc.ptriangles = ptri;
			Bench486AliasControlRaster ();
		}
		else
		{	// partially clipped
			Bench486AliasControlClip (ptri);
		}
	}
	BENCH486_PROFILE_LEAVE ();
}

void R_AliasSetUpTransform_AliasControl_C (int trivial_accept)
{
	int				i;
	float			rotationmatrix[3][4], t2matrix[3][4];
	vec3_t			angles;

// TODO: should really be stored with the entity instead of being reconstructed
// TODO: should use a look-up table
// TODO: could cache lazily, stored in the entity

	angles[ROLL] = currententity->angles[ROLL];
	angles[PITCH] = -currententity->angles[PITCH];
	angles[YAW] = currententity->angles[YAW];
	AngleVectors (angles, alias_forward, alias_right, alias_up);

	aliascontrol_tmatrix[0][0] = pmdl->scale[0];
	aliascontrol_tmatrix[1][1] = pmdl->scale[1];
	aliascontrol_tmatrix[2][2] = pmdl->scale[2];

	aliascontrol_tmatrix[0][3] = pmdl->scale_origin[0];
	aliascontrol_tmatrix[1][3] = pmdl->scale_origin[1];
	aliascontrol_tmatrix[2][3] = pmdl->scale_origin[2];

// TODO: can do this with simple matrix rearrangement

	for (i=0 ; i<3 ; i++)
	{
		t2matrix[i][0] = alias_forward[i];
		t2matrix[i][1] = -alias_right[i];
		t2matrix[i][2] = alias_up[i];
	}

	t2matrix[0][3] = -modelorg[0];
	t2matrix[1][3] = -modelorg[1];
	t2matrix[2][3] = -modelorg[2];

// FIXME: can do more efficiently than full concatenation
#if defined(ASM486_ALIAS_MATRIX_COMPOSE_ASM)
	R_ConcatTransforms_asm486 (t2matrix, aliascontrol_tmatrix, rotationmatrix);
#elif defined(ASM486_ALIAS_MATRIX_COMPOSE)
	for (i=0 ; i<3 ; i++)
	{
		rotationmatrix[i][0] = t2matrix[i][0] * aliascontrol_tmatrix[0][0];
		rotationmatrix[i][1] = t2matrix[i][1] * aliascontrol_tmatrix[1][1];
		rotationmatrix[i][2] = t2matrix[i][2] * aliascontrol_tmatrix[2][2];
		rotationmatrix[i][3] = t2matrix[i][0] * aliascontrol_tmatrix[0][3] +
				t2matrix[i][1] * aliascontrol_tmatrix[1][3] +
				t2matrix[i][2] * aliascontrol_tmatrix[2][3] + t2matrix[i][3];
	}
#else
	R_ConcatTransforms (t2matrix, aliascontrol_tmatrix, rotationmatrix);
#endif
#if defined(ASM486_ALIAS_MATRIX_COMPOSE_ASM)
	R_ConcatTransforms_asm486 (alias_viewmatrix, rotationmatrix, aliastransform);
#else
	R_ConcatTransforms (alias_viewmatrix, rotationmatrix, aliastransform);
#endif

// do the scaling up of x and y to screen coordinates as part of the transform
// for the unclipped case (it would mess up clipping in the clipped case).
// Also scale down z, so 1/z is scaled 31 bits for free, and scale down x and y
// correspondingly so the projected x and y come out right
// FIXME: make this work for clipped case too?
	if (trivial_accept)
	{
		for (i=0 ; i<4 ; i++)
		{
			aliastransform[0][i] *= aliasxscale *
					(1.0 / ((float)0x8000 * 0x10000));
			aliastransform[1][i] *= aliasyscale *
					(1.0 / ((float)0x8000 * 0x10000));
			aliastransform[2][i] *= 1.0 / ((float)0x8000 * 0x10000);

		}
	}
}

void R_AliasProjectFinalVert_AliasControl_C (finalvert_t *fv, auxvert_t *av)
{
	float	zi;

// project points
	zi = 1.0 / av->fv[2];

	fv->v[5] = zi * ziscale;

	fv->v[0] = (av->fv[0] * aliasxscale * zi) + aliasxcenter;
	fv->v[1] = (av->fv[1] * aliasyscale * zi) + aliasycenter;
}

void R_AliasPrepareUnclippedPoints_AliasControl_C (void)
{
	stvert_t	*pstverts;
	finalvert_t	*fv;

	pstverts = (stvert_t *)((byte *)paliashdr + paliashdr->stverts);
	r_anumverts = pmdl->numverts;
// FIXME: just use pfinalverts directly?
	fv = pfinalverts;

	BENCH486_PROFILE_ENTER (BENCH486_PROFILE_ALIAS_TRANSFORM);
	R_AliasTransformAndProjectFinalVerts (fv, pstverts);
	BENCH486_PROFILE_LEAVE ();

	if (r_affinetridesc.drawtype)
		Bench486AliasControlFinalVerts (fv, r_anumverts);

	r_affinetridesc.pfinalverts = pfinalverts;
	r_affinetridesc.ptriangles = (mtriangle_t *)
			((byte *)paliashdr + paliashdr->triangles);
	r_affinetridesc.numtriangles = pmdl->numtris;

	BENCH486_PROFILE_ENTER (BENCH486_PROFILE_ALIAS_RASTER);
	Bench486AliasControlRaster ();
	BENCH486_PROFILE_LEAVE ();
}

void R_AliasSetupSkin_AliasControl_C (void)
{
	int					skinnum;

	skinnum = currententity->skinnum;
	if ((skinnum >= pmdl->numskins) || (skinnum < 0))
	{
		Bench486AliasControlPrint ("R_AliasSetupSkin: no such skin # %d\n", skinnum);
		skinnum = 0;
	}

#ifdef ASM486_ALIAS_SETUP_SKIN
	pskindesc = R_AliasSetupSkinSelect_asm486 (skinnum, cl.time,
			currententity->syncbase);
#else
	pskindesc = R_AliasSetupSkinSelect_C (skinnum, cl.time,
			currententity->syncbase);
#endif
	a_skinwidth = pmdl->skinwidth;

	r_affinetridesc.pskindesc = pskindesc;
	r_affinetridesc.pskin = (void *)((byte *)paliashdr + pskindesc->skin);
	r_affinetridesc.skinwidth = a_skinwidth;
	r_affinetridesc.seamfixupX16 =  (a_skinwidth >> 1) << 16;
	r_affinetridesc.skinheight = pmdl->skinheight;
}

void R_AliasSetupLighting_AliasControl_C (alight_t *plighting)
{
#ifdef ASM486_ALIAS_SETUP_LIGHTING
	R_AliasSetupLighting_asm486 (plighting, alias_forward, alias_right,
			alias_up);
#else
	R_AliasSetupLighting_C (plighting, alias_forward, alias_right, alias_up);
#endif
}

void R_AliasSetupFrame_AliasControl_C (void)
{
	int			frame;

	frame = currententity->frame;
	if ((frame >= pmdl->numframes) || (frame < 0))
	{
		Bench486AliasControlPrint ("R_AliasSetupFrame: no such frame %d\n", frame);
		frame = 0;
	}

#ifdef ASM486_ALIAS_SETUP_FRAME
	R_AliasSetupFrame_asm486 (frame, cl.time, currententity->syncbase);
#else
	R_AliasSetupFrame_C (frame, cl.time, currententity->syncbase);
#endif
}

void __attribute__((regparm(1))) R_AliasDrawModel_AliasControl_C (alight_t *plighting)
{
	finalvert_t		finalverts[MAXALIASVERTS +
						((CACHE_SIZE - 1) / sizeof(finalvert_t)) + 1];
	auxvert_t		auxverts[MAXALIASVERTS];
#ifdef PROFILE486
	double			bench486_alias_start;
#endif
	BENCH486_PROFILE_ENTER (BENCH486_PROFILE_ALIAS_MODEL);

#ifdef PROFILE486
	if (bench486_profile_frame_active)
		bench486_alias_start = Bench486AliasControlTime ();
#endif

	r_amodels_drawn++;

#ifdef PROFILE486
	if (bench486_profile_frame_active)
		bench486_alias_models++;
#endif

// cache align
	pfinalverts = (finalvert_t *)
			(((long)&finalverts[0] + CACHE_SIZE - 1) & ~(CACHE_SIZE - 1));
	pauxverts = &auxverts[0];

	paliashdr = (aliashdr_t *)Bench486AliasControlModel (currententity->model);
	pmdl = (mdl_t *)((byte *)paliashdr + paliashdr->model);

#ifdef PROFILE486
	if (bench486_profile_frame_active)
		bench486_alias_vertices += pmdl->numverts;
#endif
	BENCH486_PROFILE_WORK (BENCH486_PROFILE_ALIAS_MODEL, 1,
			(unsigned long)pmdl->numverts);

	BENCH486_PROFILE_ENTER (BENCH486_PROFILE_ALIAS_SETUP);
	R_AliasSetupSkin_AliasControl_C ();
	if (alias_transform_entity != currententity ||
			alias_transform_mode != currententity->trivial_accept)
		R_AliasSetUpTransform_AliasControl_C (currententity->trivial_accept);
	alias_transform_entity = NULL;
	R_AliasSetupLighting_AliasControl_C (plighting);
	R_AliasSetupFrame_AliasControl_C ();

	if (!currententity->colormap)
		Sys_Error ("R_AliasDrawModel: !currententity->colormap");

	r_affinetridesc.drawtype = (currententity->trivial_accept == 3) &&
			r_recursiveaffinetriangles;

	if (r_affinetridesc.drawtype)
	{
		Bench486AliasControlTables ();		// FIXME: precalc...
	}
	else
	{
#if	id386
		Bench486AliasControlPatch (currententity->colormap);
#endif
	}

	acolormap = currententity->colormap;

	if (currententity != &cl.viewent)
		ziscale = (float)0x8000 * (float)0x10000;
	else
		ziscale = (float)0x8000 * (float)0x10000 * 3.0;
	BENCH486_PROFILE_LEAVE ();

	if (currententity->trivial_accept)
		R_AliasPrepareUnclippedPoints_AliasControl_C ();
	else
		R_AliasPreparePoints_AliasControl_C ();

#ifdef PROFILE486
	if (bench486_profile_frame_active)
		bench486_alias_seconds += Bench486AliasControlTime () - bench486_alias_start;
#endif
	BENCH486_PROFILE_LEAVE ();
}
#undef Bench486ProfileEnter
#undef Bench486ProfileLeave
#undef Bench486ProfileWork
#endif
