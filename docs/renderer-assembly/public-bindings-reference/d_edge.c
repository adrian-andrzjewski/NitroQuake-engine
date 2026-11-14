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
// d_edge.c

#include "quakedef.h"
#include "renderer/d_local.h"

#if defined(ASM486_SURFACE_GRADIENTS) || defined(ASM486_SURFACE_DISPATCH)
int			d_gradient_miplevel;
#define miplevel d_gradient_miplevel
float		d_mipscale_values[4] = {1.0, 0.5, 0.25, 0.125};
float		d_mip_xscale[4];
float		d_mip_yscale[4];
#else
static int	miplevel;
static float	d_mipscale_values[4] = {1.0, 0.5, 0.25, 0.125};
static float	d_mip_xscale[4];
static float	d_mip_yscale[4];
#endif
// 0x10000 * d_mipscale_values[] for {1.0, 0.5, 0.25, 0.125}; all exactly
// representable, so this is the same value the loop used to recompute.
#ifdef ASM486_SURFACE_GRADIENTS
const float	d_mip_t16[4] = {0x10000, 0x8000, 0x4000, 0x2000};
#else
static const float	d_mip_t16[4] = {0x10000, 0x8000, 0x4000, 0x2000};
#endif

#ifndef D_TEXAXIS_CACHE_SIZE
#define D_TEXAXIS_CACHE_SIZE	256
#endif

typedef struct
{
	mtexinfo_t	*texinfo;
	entity_t	*entity;
	int			frame;
	vec3_t		saxis;
	vec3_t		taxis;
} d_texaxis_cache_t;

static d_texaxis_cache_t	d_texaxis_cache[D_TEXAXIS_CACHE_SIZE];

#ifdef ASM486_SURFACE_GRADIENTS
typedef char d_gradient_pointer_size[(sizeof(void *) == 4) ? 1 : -1];
typedef char d_gradient_cache_entry_size[(sizeof(d_texaxis_cache_t) == 36) ? 1 : -1];
typedef char d_gradient_cache_saxis_offset[
		(__builtin_offsetof(d_texaxis_cache_t, saxis) == 12) ? 1 : -1];
typedef char d_gradient_cache_taxis_offset[
		(__builtin_offsetof(d_texaxis_cache_t, taxis) == 24) ? 1 : -1];
typedef char d_gradient_surface_offsets[
		(__builtin_offsetof(msurface_t, plane) == 12 &&
		 __builtin_offsetof(msurface_t, texturemins) == 44 &&
		 __builtin_offsetof(msurface_t, extents) == 48 &&
		 __builtin_offsetof(msurface_t, texinfo) == 52) ? 1 : -1];
typedef char d_gradient_texinfo_layout[
		(__builtin_offsetof(mtexinfo_t, vecs) == 0 &&
		 __builtin_offsetof(mtexinfo_t, mipadjust) == 32) ? 1 : -1];

// Kept separate from the reference cache so C/ASM comparisons exercise both
// miss and hit paths independently.
d_texaxis_cache_t	d_texaxis_cache_asm[D_TEXAXIS_CACHE_SIZE];
int			d_texaxis_cache_mask = D_TEXAXIS_CACHE_SIZE - 1;
typedef char d_gradient_cache_array_size[
		((sizeof(d_texaxis_cache_asm) / sizeof(d_texaxis_cache_asm[0])) ==
		 D_TEXAXIS_CACHE_SIZE) ? 1 : -1];
#endif

#ifdef ASM486_SURFACE_DISPATCH
typedef char d_dispatch_pointer_size[(sizeof(void *) == 4) ? 1 : -1];
typedef char d_dispatch_surface_layout[
		(sizeof(surf_t) == 64 &&
		 __builtin_offsetof(surf_t, spans) == 8 &&
		 __builtin_offsetof(surf_t, flags) == 24 &&
		 __builtin_offsetof(surf_t, data) == 28 &&
		 __builtin_offsetof(surf_t, entity) == 32 &&
		 __builtin_offsetof(surf_t, nearzi) == 36 &&
		 __builtin_offsetof(surf_t, insubmodel) == 40 &&
		 __builtin_offsetof(surf_t, d_ziorigin) == 44 &&
		 __builtin_offsetof(surf_t, d_zistepu) == 48 &&
		 __builtin_offsetof(surf_t, d_zistepv) == 52) ? 1 : -1];
typedef char d_dispatch_entity_origin_offset[
		(__builtin_offsetof(entity_t, origin) == 84) ? 1 : -1];
typedef char d_dispatch_texture_layout[
		(__builtin_offsetof(texture_t, offsets) == 44 &&
		 __builtin_offsetof(mtexinfo_t, mipadjust) == 32 &&
		 __builtin_offsetof(mtexinfo_t, texture) == 36 &&
		 __builtin_offsetof(msurface_t, texturemins) == 44 &&
		 __builtin_offsetof(msurface_t, extents) == 48 &&
		 __builtin_offsetof(msurface_t, texinfo) == 52) ? 1 : -1];
typedef char d_dispatch_cache_data_offset[
#ifdef DEBUG
		(__builtin_offsetof(surfcache_t, data) == 48) ? 1 : -1];
#else
		(__builtin_offsetof(surfcache_t, data) == 44) ? 1 : -1];
#endif
typedef char d_dispatch_cvar_value_offset[
		(__builtin_offsetof(cvar_t, value) == 16) ? 1 : -1];
#endif

// E0: count DISTINCT faces drawn per frame, not total draws.  A per-face
// precompute (E3) only pays if a face is drawn more than once in a frame;
// counting draws would report a ratio of 1.0 by construction and settle
// nothing.  Direct-mapped on the face pointer, so a collision merges two
// faces and can only understate the distinct count -- the safe direction.
// Instrumentation only; the release build never sees this.
#ifdef PROFILE486
#define D_FACEDRAWN_SEEN	4096
static int	d_facedrawn_tag[D_FACEDRAWN_SEEN];

static void D_NoteFaceDrawn (msurface_t *face)
{
	int		slot;

	slot = (int)(((unsigned long)face >> 4) & (D_FACEDRAWN_SEEN - 1));
	if (d_facedrawn_tag[slot] == r_framecount)
		return;					// already counted this frame
	d_facedrawn_tag[slot] = r_framecount;
	bench486_surface_drawn++;
}
#endif

// The view basis is stable for an entity during one render frame.  The
// entity and frame keys therefore invalidate entries when world or bmodel
// orientation changes, while collisions only cause a harmless recompute.

#ifdef BENCH486
void *D_GetTextureAxesHit_C (void *entry_ptr, void *texinfo_ptr,
		void *entity_ptr, int frame)
{
	d_texaxis_cache_t *entry;

	entry = (d_texaxis_cache_t *)entry_ptr;
	if (entry && entry->texinfo == (mtexinfo_t *)texinfo_ptr &&
			entry->entity == (entity_t *)entity_ptr &&
			entry->frame == frame)
		return entry_ptr;
	return NULL;
}
#endif

float		scale_for_mip;
int			screenwidth;
int			ubasestep, errorterm, erroradjustup, erroradjustdown;
int			vstartscan;

#ifdef PROFILE486
static void D_ProfileSpans (espan_t *span, qboolean texture)
{
	int		count;
	int		bucket;

	while (span)
	{
		count = span->count;
		bench486_surface_span_count++;
		bench486_surface_span_pixels += count;
		bench486_surface_span_segments += (count + 15) >> 4;

		if (texture)
		{
			bench486_texture_span_count++;
			bench486_texture_span_pixels += count;
			bench486_texture_span_segments += (count + 15) >> 4;
			bench486_texture_final_lengths[((count - 1) & 15) + 1]++;

			if (count <= 1)
				bucket = 0;
			else if (count <= 8)
				bucket = 1;
			else if (count <= 16)
				bucket = 2;
			else if (count <= 32)
				bucket = 3;
			else
				bucket = 4;
			bench486_texture_span_buckets[bucket]++;
		}
		span = span->pnext;
	}
}
#endif

// FIXME: should go away
extern void			R_RotateBmodel (void);
extern void			R_RotateBmodelCached (void);
extern void			R_TransformFrustum (void);

#if defined(ASM486_SURFACE_GRADIENTS) || defined(ASM486_SURFACE_DISPATCH)
vec3_t		transformed_modelorg;
#else
static vec3_t	transformed_modelorg;
#endif

/*
==============
D_RestoreWorldDrawingState

Undo a per-polygon bmodel rotation so world surfaces use base view axes.
==============
*/
#if !defined(ASM486_SURFACE_DISPATCH) || defined(BENCH486)
static void D_RestoreWorldDrawingState (entity_t **rotated,
	vec3_t world_transformed_modelorg)
{
	if (!*rotated)
		return;

	currententity = &cl_entities[0];
	VectorCopy (world_transformed_modelorg, transformed_modelorg);
	VectorCopy (base_vpn, vpn);
	VectorCopy (base_vup, vup);
	VectorCopy (base_vright, vright);
	VectorCopy (base_modelorg, modelorg);
	R_TransformFrustum ();
	*rotated = NULL;
}

/*
==============
D_SetBmodelDrawingState

Id's driver rotated every in-submodel polygon. Consecutive polygons from the
same brush entity can keep the current axes; later revisits reuse the cached
rotation matrix instead of rebuilding it with sin/cos.
==============
*/
static void D_SetBmodelDrawingState (entity_t **rotated, surf_t *s,
	vec3_t local_modelorg, vec3_t world_transformed_modelorg)
{
	if (*rotated == s->entity)
		return;

	D_RestoreWorldDrawingState (rotated, world_transformed_modelorg);

	currententity = s->entity;	//FIXME: make this passed in to
								// R_RotateBmodel ()
	VectorSubtract (r_origin, currententity->origin, local_modelorg);
	TransformVector (local_modelorg, transformed_modelorg);

	R_RotateBmodelCached ();	// FIXME: don't mess with the frustum,
								// make entity passed in
	*rotated = s->entity;
}
#endif

#if defined(ASM486_SURFACE_DISPATCH) && defined(PROFILE486)
enum
{
	D_SURFACE_PROFILE_SOLID = 0,
	D_SURFACE_PROFILE_SKY,
	D_SURFACE_PROFILE_BACKGROUND,
	D_SURFACE_PROFILE_TURBULENT,
	D_SURFACE_PROFILE_TEXTURE
};

enum
{
	D_SPAN_PROFILE_SOLID = 0,
	D_SPAN_PROFILE_Z,
	D_SPAN_PROFILE_SKY,
	D_SPAN_PROFILE_TURBULENT,
	D_SPAN_PROFILE_TEXTURE
};

static double		d_surface_profile_start_asm486;
static double		d_surface_span_draw_start_asm486;
static unsigned long	d_surface_profile_count_start_asm486;
static unsigned long	d_surface_profile_pixels_start_asm486;
static unsigned long	d_surface_texture_span_start_asm486;
static unsigned long	d_surface_texture_pixel_start_asm486;

void D_DrawSurfacesProfileBegin_asm486 (void)
{
	d_surface_profile_count_start_asm486 = bench486_surface_count;
	d_surface_profile_pixels_start_asm486 = bench486_surface_span_pixels;
	if (bench486_profile_frame_active)
		d_surface_profile_start_asm486 = Sys_FloatTime ();
	BENCH486_PROFILE_ENTER (BENCH486_PROFILE_SURFACES);
}

void D_DrawSurfacesProfileFinish_asm486 (void)
{
	if (bench486_profile_frame_active)
	{
		bench486_surface_seconds += Sys_FloatTime () -
				d_surface_profile_start_asm486;
		BENCH486_PROFILE_WORK (BENCH486_PROFILE_SURFACES,
				bench486_surface_count - d_surface_profile_count_start_asm486,
				bench486_surface_span_pixels -
				d_surface_profile_pixels_start_asm486);
	}
	BENCH486_PROFILE_LEAVE ();
}

void D_DrawSurfacesProfileRecordSurface_asm486 (surf_t *surface, int category)
{
	if (!bench486_profile_frame_active)
		return;

	bench486_surface_count++;
	switch (category)
	{
	case D_SURFACE_PROFILE_SOLID:
		bench486_surface_solid_count++;
		D_ProfileSpans (surface->spans, false);
		break;
	case D_SURFACE_PROFILE_SKY:
		bench486_surface_sky_count++;
		D_ProfileSpans (surface->spans, false);
		break;
	case D_SURFACE_PROFILE_BACKGROUND:
		bench486_surface_background_count++;
		D_ProfileSpans (surface->spans, false);
		break;
	case D_SURFACE_PROFILE_TURBULENT:
		bench486_surface_turbulent_count++;
		D_ProfileSpans (surface->spans, false);
		break;
	default:
		bench486_surface_normal_count++;
		D_ProfileSpans (surface->spans, true);
		break;
	}
}

void D_DrawSurfacesProfileEnter_asm486 (int kind)
{
	switch (kind)
	{
	case D_SPAN_PROFILE_SOLID:
		BENCH486_PROFILE_ENTER (BENCH486_PROFILE_SOLID_SPANS);
		break;
	case D_SPAN_PROFILE_Z:
		BENCH486_PROFILE_ENTER (BENCH486_PROFILE_Z_SPANS);
		break;
	case D_SPAN_PROFILE_SKY:
		BENCH486_PROFILE_ENTER (BENCH486_PROFILE_SKY_SPANS);
		break;
	case D_SPAN_PROFILE_TURBULENT:
		BENCH486_PROFILE_ENTER (BENCH486_PROFILE_TURBULENT_SPANS);
		break;
	default:
		BENCH486_PROFILE_ENTER (BENCH486_PROFILE_TEXTURE_SPANS);
		break;
	}
}

void D_DrawSurfacesProfileLeave_asm486 (void)
{
	BENCH486_PROFILE_LEAVE ();
}

void D_DrawSurfacesProfileWork_asm486 (int kind)
{
	if (kind == D_SPAN_PROFILE_SKY)
		BENCH486_PROFILE_WORK (BENCH486_PROFILE_SKY_SPANS, 1, 0);
	else if (kind == D_SPAN_PROFILE_TURBULENT)
		BENCH486_PROFILE_WORK (BENCH486_PROFILE_TURBULENT_SPANS, 1, 0);
}

void D_DrawSurfacesProfileTimedStart_asm486 (void)
{
	if (bench486_profile_frame_active)
		d_surface_span_draw_start_asm486 = Sys_FloatTime ();
}

void D_DrawSurfacesProfileTimedFinish_asm486 (void)
{
	if (bench486_profile_frame_active)
		bench486_span_draw_seconds += Sys_FloatTime () -
				d_surface_span_draw_start_asm486;
}

void D_DrawSurfacesProfileTextureStart_asm486 (void)
{
	d_surface_texture_span_start_asm486 = bench486_texture_span_count;
	d_surface_texture_pixel_start_asm486 = bench486_texture_span_pixels;
	D_DrawSurfacesProfileTimedStart_asm486 ();
}

void D_DrawSurfacesProfileTextureFinish_asm486 (void)
{
	D_DrawSurfacesProfileTimedFinish_asm486 ();
	BENCH486_PROFILE_WORK (BENCH486_PROFILE_TEXTURE_SPANS,
			bench486_texture_span_count -
			d_surface_texture_span_start_asm486,
			bench486_texture_span_pixels -
			d_surface_texture_pixel_start_asm486);
}

void D_DrawSurfacesProfileTextureWidth_asm486 (void)
{
	int width;

	if (!bench486_profile_frame_active)
		return;
	width = cachewidth;
	if (width >= 16 && width <= 256 && !(width & 15))
		bench486_texture_widths[width >> 4]++;
	else
		bench486_texture_widths[0]++;
}
#endif

/*
==============
D_DrawPoly

==============
*/
void D_DrawPoly (void)
{
// this driver takes spans, not polygons
}


/*
=============
D_MipLevelForScale
=============
*/
#if !defined(ASM486_MIP_LEVEL) || defined(BENCH486)
#ifdef BENCH486
int D_MipLevelForScale_C (float scale)
#elif !defined(ASM486_MIP_LEVEL)
int D_MipLevelForScale (float scale)
#endif
{
	int		lmiplevel;

	if (scale >= d_scalemip[0] )
		lmiplevel = 0;
	else if (scale >= d_scalemip[1] )
		lmiplevel = 1;
	else if (scale >= d_scalemip[2] )
		lmiplevel = 2;
	else
		lmiplevel = 3;

	if (lmiplevel < d_minmip)
		lmiplevel = d_minmip;

	return lmiplevel;
}
#endif

#if defined(BENCH486) && !defined(ASM486_MIP_LEVEL)
int D_MipLevelForScale (float scale)
{
	int		lmiplevel;

	if (scale >= d_scalemip[0] )
		lmiplevel = 0;
	else if (scale >= d_scalemip[1] )
		lmiplevel = 1;
	else if (scale >= d_scalemip[2] )
		lmiplevel = 2;
	else
		lmiplevel = 3;

	if (lmiplevel < d_minmip)
		lmiplevel = d_minmip;

	return lmiplevel;
}
#endif


/*
==============
D_DrawSolidSurface
==============
*/

// FIXME: clean this up

#ifdef ASM486_SOLID_SURFACE
typedef char d_solidsurface_pointer_size[
		(sizeof(void *) == 4) ? 1 : -1];
typedef char d_solidsurface_spans_offset[
		(__builtin_offsetof (surf_t, spans) == 8) ? 1 : -1];
typedef char d_solidsurface_espan_u_offset[
		(__builtin_offsetof (espan_t, u) == 0) ? 1 : -1];
typedef char d_solidsurface_espan_v_offset[
		(__builtin_offsetof (espan_t, v) == 4) ? 1 : -1];
typedef char d_solidsurface_espan_count_offset[
		(__builtin_offsetof (espan_t, count) == 8) ? 1 : -1];
typedef char d_solidsurface_espan_next_offset[
		(__builtin_offsetof (espan_t, pnext) == 12) ? 1 : -1];
typedef char d_solidsurface_pixel_size[
		(sizeof(pixel_t) == 1) ? 1 : -1];
#if defined(BENCH486)
#define D_DrawSolidSurface D_DrawSolidSurface_C
#endif
#endif

#if !defined(ASM486_SOLID_SURFACE) || defined(BENCH486)
void D_DrawSolidSurface (surf_t *surf, int color)
{
	espan_t	*span;
	byte	*pdest;
	int		u, u2, pix;
	
	pix = (color<<24) | (color<<16) | (color<<8) | color;
	for (span=surf->spans ; span ; span=span->pnext)
	{
#ifdef PROFILE486
		if (bench486_profile_frame_active)
			bench486_solid_span_count++;
#endif
		pdest = viewspantable[span->v];
		if (span->count >= 16)
		{
			Q_memset (pdest + span->u, color, span->count);
			continue;
		}

		u = span->u;
		u2 = span->u + span->count - 1;
		((byte *)pdest)[u] = pix;

		if (u2 - u < 8)
		{
			for (u++ ; u <= u2 ; u++)
				((byte *)pdest)[u] = pix;
		}
		else
		{
			for (u++ ; u & 3 ; u++)
				((byte *)pdest)[u] = pix;

			u2 -= 4;
			for ( ; u <= u2 ; u+=4)
				*(int *)((byte *)pdest + u) = pix;
			u2 += 4;
			for ( ; u <= u2 ; u++)
				((byte *)pdest)[u] = pix;
		}
	}
}
#endif

#if defined(ASM486_SOLID_SURFACE) && defined(BENCH486)
#undef D_DrawSolidSurface
#endif


/*
==============
D_GetTextureAxes
==============
*/
static d_texaxis_cache_t *D_GetTextureAxes (mtexinfo_t *texinfo)
{
	unsigned int		index;
	d_texaxis_cache_t	*entry;

	index = (((unsigned long)texinfo >> 4) ^
			((unsigned long)currententity >> 4)) &
			(D_TEXAXIS_CACHE_SIZE - 1);
	entry = &d_texaxis_cache[index];

#ifdef ASM486_TEXTURE_AXIS_CACHE
	if (D_GetTextureAxesHit_asm486 (entry, texinfo, currententity,
			r_framecount))
#else
	if (entry->texinfo == texinfo && entry->entity == currententity &&
		entry->frame == r_framecount)
#endif
	{
#ifdef PROFILE486
		if (bench486_profile_frame_active)
			bench486_axis_cache_hits++;
#endif
		return entry;
	}

	TransformVector (texinfo->vecs[0], entry->saxis);
	TransformVector (texinfo->vecs[1], entry->taxis);

	entry->texinfo = texinfo;
	entry->entity = currententity;
	entry->frame = r_framecount;
#ifdef PROFILE486
	if (bench486_profile_frame_active)
		bench486_axis_cache_misses++;
#endif
	return entry;
}


/*
==============
D_CalcGradients
==============
*/
#if !defined(ASM486_SURFACE_GRADIENTS) || defined(BENCH486)
#ifdef BENCH486
void D_CalcGradients_C (msurface_t *pface)
#else
void D_CalcGradients (msurface_t *pface)
#endif
{
	mplane_t	*pplane;
	float		mipscale;
	vec3_t		p_temp1;
	d_texaxis_cache_t *axes;
	float		t;
	BENCH486_PROFILE_ENTER (BENCH486_PROFILE_GRADIENTS);

#ifdef PROFILE486
	if (bench486_profile_frame_active)
	{
		bench486_gradient_calls++;
		D_NoteFaceDrawn (pface);
	}
#endif

	pplane = pface->plane;

	mipscale = d_mipscale_values[miplevel];

	axes = D_GetTextureAxes (pface->texinfo);

	t = d_mip_xscale[miplevel];
	d_sdivzstepu = axes->saxis[0] * t;
	d_tdivzstepu = axes->taxis[0] * t;

	t = d_mip_yscale[miplevel];
	d_sdivzstepv = -axes->saxis[1] * t;
	d_tdivzstepv = -axes->taxis[1] * t;

	d_sdivzorigin = axes->saxis[2] * mipscale - xcenter * d_sdivzstepu -
			ycenter * d_sdivzstepv;
	d_tdivzorigin = axes->taxis[2] * mipscale - xcenter * d_tdivzstepu -
			ycenter * d_tdivzstepv;

	VectorScale (transformed_modelorg, mipscale, p_temp1);

	t = d_mip_t16[miplevel];
	sadjust = ((fixed16_t)(DotProduct (p_temp1, axes->saxis) * 0x10000 + 0.5)) -
			((pface->texturemins[0] << 16) >> miplevel)
			+ pface->texinfo->vecs[0][3]*t;
	tadjust = ((fixed16_t)(DotProduct (p_temp1, axes->taxis) * 0x10000 + 0.5)) -
			((pface->texturemins[1] << 16) >> miplevel)
			+ pface->texinfo->vecs[1][3]*t;

//
// -1 (-epsilon) so we never wander off the edge of the texture
//
	bbextents = ((pface->extents[0] << 16) >> miplevel) - 1;
	bbextentt = ((pface->extents[1] << 16) >> miplevel) - 1;
	BENCH486_PROFILE_LEAVE ();
}
#endif

#ifdef ASM486_SURFACE_GRADIENTS
#ifdef PROFILE486
void D_CalcGradientsProfileBegin_asm486 (msurface_t *pface)
{
	BENCH486_PROFILE_ENTER (BENCH486_PROFILE_GRADIENTS);
	if (bench486_profile_frame_active)
	{
		bench486_gradient_calls++;
		D_NoteFaceDrawn (pface);
	}
}

void D_CalcGradientsProfileEnd_asm486 (void)
{
	BENCH486_PROFILE_LEAVE ();
}

void D_CalcGradientsProfileAxisHit_asm486 (void)
{
	if (bench486_profile_frame_active)
		bench486_axis_cache_hits++;
}

void D_CalcGradientsProfileAxisMiss_asm486 (void)
{
	if (bench486_profile_frame_active)
		bench486_axis_cache_misses++;
}
#endif

void D_CalcGradients (msurface_t *pface)
{
	D_CalcGradients_asm486 (pface);
}
#elif defined(BENCH486)
#define D_CalcGradients D_CalcGradients_C
#endif

#ifdef ASM486_SURFACE_DISPATCH
// Keep the benchmark C reference selectable without teaching the assembler
// build about C-only BENCH486 flags. This binding calls whichever gradient
// implementation the build selected above.
void D_DrawSurfacesCalcGradients_asm486 (msurface_t *pface)
{
	D_CalcGradients (pface);
}

#endif


/*
==============
D_DrawSurfaces
==============
*/
#if defined(BENCH486)
#define D_DRAW_SURFACES_FUNCTION D_DrawSurfaces_C
#elif !defined(ASM486_SURFACE_DISPATCH)
#define D_DRAW_SURFACES_FUNCTION D_DrawSurfaces
#endif

#if !defined(ASM486_SURFACE_DISPATCH) || defined(BENCH486)
void D_DRAW_SURFACES_FUNCTION (void)
{
	surf_t			*s;
	msurface_t		*pface;
	surfcache_t		*pcurrentcache;
	vec3_t			world_transformed_modelorg;
	vec3_t			local_modelorg;
	entity_t		*span_bmodel;
#ifdef PROFILE486
	double			bench486_surface_start;
	double			bench486_span_draw_start;
	unsigned long	profile_surface_start;
	unsigned long	profile_surface_pixels_start;
	unsigned long	profile_texture_span_start;
	unsigned long	profile_texture_pixel_start;
	profile_surface_start = bench486_surface_count;
	profile_surface_pixels_start = bench486_surface_span_pixels;

	if (bench486_profile_frame_active)
	{
		bench486_surface_start = Sys_FloatTime ();
	}
#endif
	BENCH486_PROFILE_ENTER (BENCH486_PROFILE_SURFACES);

	currententity = &cl_entities[0];
	TransformVector (modelorg, transformed_modelorg);
	VectorCopy (transformed_modelorg, world_transformed_modelorg);
	span_bmodel = NULL;

	{
		int		mip;

		for (mip = 0 ; mip < 4 ; mip++)
		{
			d_mip_xscale[mip] = xscaleinv * d_mipscale_values[mip];
			d_mip_yscale[mip] = yscaleinv * d_mipscale_values[mip];
		}
	}

// TODO: could preset a lot of this at mode set time
	if (r_drawflat.value)
	{
		for (s = &surfaces[1] ; s<surface_p ; s++)
		{
			if (!s->spans)
				continue;

#ifdef PROFILE486
			if (bench486_profile_frame_active)
			{
				bench486_surface_count++;
				bench486_surface_solid_count++;
				D_ProfileSpans (s->spans, false);
			}
#endif

			d_zistepu = s->d_zistepu;
			d_zistepv = s->d_zistepv;
			d_ziorigin = s->d_ziorigin;

			BENCH486_PROFILE_ENTER (BENCH486_PROFILE_SOLID_SPANS);
			D_DrawSolidSurface (s, (int)s->data & 0xFF);
			BENCH486_PROFILE_LEAVE ();
			BENCH486_PROFILE_ENTER (BENCH486_PROFILE_Z_SPANS);
			D_DrawZSpans (s->spans);
			BENCH486_PROFILE_LEAVE ();
		}
	}
	else
	{
		for (s = &surfaces[1] ; s<surface_p ; s++)
		{
			if (!s->spans)
				continue;

#ifdef PROFILE486
			if (bench486_profile_frame_active)
			{
				bench486_surface_count++;
			}
#endif

			r_drawnpolycount++;

			d_zistepu = s->d_zistepu;
			d_zistepv = s->d_zistepv;
			d_ziorigin = s->d_ziorigin;

			if (s->flags & SURF_DRAWSKY)
			{
				D_RestoreWorldDrawingState (&span_bmodel,
						world_transformed_modelorg);
	#ifdef PROFILE486
				if (bench486_profile_frame_active)
				{
					bench486_surface_sky_count++;
					D_ProfileSpans (s->spans, false);
				}
	#endif
				if (!r_skymade)
				{
					R_MakeSky ();
				}

#ifdef PROFILE486
				if (bench486_profile_frame_active)
					bench486_span_draw_start = Sys_FloatTime ();
#endif
				BENCH486_PROFILE_ENTER (BENCH486_PROFILE_SKY_SPANS);
				D_DrawSkyScans8 (s->spans);
				BENCH486_PROFILE_LEAVE ();
				BENCH486_PROFILE_WORK (BENCH486_PROFILE_SKY_SPANS, 1, 0);

#ifdef PROFILE486
				if (bench486_profile_frame_active)
					bench486_span_draw_seconds += Sys_FloatTime () -
							bench486_span_draw_start;
#endif
				BENCH486_PROFILE_ENTER (BENCH486_PROFILE_Z_SPANS);
				D_DrawZSpans (s->spans);
				BENCH486_PROFILE_LEAVE ();
			}
			else if (s->flags & SURF_DRAWBACKGROUND)
			{
				D_RestoreWorldDrawingState (&span_bmodel,
						world_transformed_modelorg);
	#ifdef PROFILE486
				if (bench486_profile_frame_active)
				{
					bench486_surface_background_count++;
					D_ProfileSpans (s->spans, false);
				}
	#endif
			// set up a gradient for the background surface that places it
			// effectively at infinity distance from the viewpoint
				d_zistepu = 0;
				d_zistepv = 0;
				d_ziorigin = -0.9;

				BENCH486_PROFILE_ENTER (BENCH486_PROFILE_SOLID_SPANS);
				D_DrawSolidSurface (s, (int)r_clearcolor.value & 0xFF);
				BENCH486_PROFILE_LEAVE ();
				BENCH486_PROFILE_ENTER (BENCH486_PROFILE_Z_SPANS);
				D_DrawZSpans (s->spans);
				BENCH486_PROFILE_LEAVE ();
			}
			else if (s->flags & SURF_DRAWTURB)
			{
	#ifdef PROFILE486
				if (bench486_profile_frame_active)
				{
					bench486_surface_turbulent_count++;
					D_ProfileSpans (s->spans, false);
				}
	#endif
				pface = s->data;
				miplevel = 0;
				cacheblock = (pixel_t *)
						((byte *)pface->texinfo->texture +
						pface->texinfo->texture->offsets[0]);
				cachewidth = 64;

				if (s->insubmodel)
					D_SetBmodelDrawingState (&span_bmodel, s, local_modelorg,
							world_transformed_modelorg);
				else
					D_RestoreWorldDrawingState (&span_bmodel,
							world_transformed_modelorg);

				D_CalcGradients (pface);
				BENCH486_PROFILE_ENTER (BENCH486_PROFILE_TURBULENT_SPANS);
				Turbulent8 (s->spans);
				BENCH486_PROFILE_LEAVE ();
				BENCH486_PROFILE_WORK (BENCH486_PROFILE_TURBULENT_SPANS, 1, 0);
				BENCH486_PROFILE_ENTER (BENCH486_PROFILE_Z_SPANS);
				D_DrawZSpans (s->spans);
				BENCH486_PROFILE_LEAVE ();
			}
			else
			{
	#ifdef PROFILE486
				profile_texture_span_start = bench486_texture_span_count;
				profile_texture_pixel_start = bench486_texture_span_pixels;
				if (bench486_profile_frame_active)
				{
					bench486_surface_normal_count++;
					D_ProfileSpans (s->spans, true);
				}
	#endif
				if (s->insubmodel)
					D_SetBmodelDrawingState (&span_bmodel, s, local_modelorg,
							world_transformed_modelorg);
				else
					D_RestoreWorldDrawingState (&span_bmodel,
							world_transformed_modelorg);

				pface = s->data;
				miplevel = D_MipLevelForScale (s->nearzi * scale_for_mip
				* pface->texinfo->mipadjust);

			// FIXME: make this passed in to D_CacheSurface
				pcurrentcache = D_CacheSurface (pface, miplevel);

				cacheblock = (pixel_t *)pcurrentcache->data;
				cachewidth = pcurrentcache->width;

				D_CalcGradients (pface);

#ifdef PROFILE486
				if (bench486_profile_frame_active)
				{
					if (cachewidth >= 16 && cachewidth <= 256 &&
							!(cachewidth & 15))
						bench486_texture_widths[cachewidth >> 4]++;
					else
						bench486_texture_widths[0]++;
				}
#endif

#ifdef PROFILE486
				if (bench486_profile_frame_active)
					bench486_span_draw_start = Sys_FloatTime ();
#endif
				BENCH486_PROFILE_ENTER (BENCH486_PROFILE_TEXTURE_SPANS);
				(*d_drawspans) (s->spans);
				BENCH486_PROFILE_LEAVE ();
#ifdef PROFILE486
				if (bench486_profile_frame_active)
					bench486_span_draw_seconds += Sys_FloatTime () -
							bench486_span_draw_start;
				BENCH486_PROFILE_WORK (BENCH486_PROFILE_TEXTURE_SPANS,
						bench486_texture_span_count - profile_texture_span_start,
						bench486_texture_span_pixels - profile_texture_pixel_start);
#endif
				BENCH486_PROFILE_ENTER (BENCH486_PROFILE_Z_SPANS);
				D_DrawZSpans (s->spans);
				BENCH486_PROFILE_LEAVE ();
			}
		}

		D_RestoreWorldDrawingState (&span_bmodel, world_transformed_modelorg);
	}

#ifdef PROFILE486
	if (bench486_profile_frame_active)
	{
		bench486_surface_seconds += Sys_FloatTime () - bench486_surface_start;
		BENCH486_PROFILE_WORK (BENCH486_PROFILE_SURFACES,
				bench486_surface_count - profile_surface_start,
				bench486_surface_span_pixels - profile_surface_pixels_start);
	}
#endif
	BENCH486_PROFILE_LEAVE ();
}
#if defined(BENCH486) && !defined(ASM486_SURFACE_DISPATCH)
void D_DrawSurfaces (void)
{
	D_DrawSurfaces_C ();
}
#endif
#endif

#undef D_DRAW_SURFACES_FUNCTION

