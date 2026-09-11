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
#include "d_local.h"

static int	miplevel;
static float	d_mipscale_values[4] = {1.0, 0.5, 0.25, 0.125};

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

vec3_t		transformed_modelorg;

/*
==============
D_RestoreWorldDrawingState

Undo a per-polygon bmodel rotation so world surfaces use base view axes.
==============
*/
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

#ifdef BENCH486
int D_MipLevelForScale (float scale)
{
#ifdef ASM486_MIP_LEVEL
	return D_MipLevelForScale_asm486 (scale);
#else
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
#endif
}
#elif defined(ASM486_MIP_LEVEL)
int D_MipLevelForScale (float scale)
{
	return D_MipLevelForScale_asm486 (scale);
}
#endif


/*
==============
D_DrawSolidSurface
==============
*/

// FIXME: clean this up

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
		pdest = (byte *)d_viewbuffer + screenwidth*span->v;
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
void D_CalcGradients (msurface_t *pface)
{
	mplane_t	*pplane;
	float		mipscale;
	vec3_t		p_temp1;
	d_texaxis_cache_t *axes;
	float		t;
	BENCH486_PROFILE_ENTER (BENCH486_PROFILE_GRADIENTS);

#ifdef PROFILE486
	if (bench486_profile_frame_active)
		bench486_gradient_calls++;
#endif

	pplane = pface->plane;

	mipscale = d_mipscale_values[miplevel];

	axes = D_GetTextureAxes (pface->texinfo);

	t = xscaleinv * mipscale;
	d_sdivzstepu = axes->saxis[0] * t;
	d_tdivzstepu = axes->taxis[0] * t;

	t = yscaleinv * mipscale;
	d_sdivzstepv = -axes->saxis[1] * t;
	d_tdivzstepv = -axes->taxis[1] * t;

	d_sdivzorigin = axes->saxis[2] * mipscale - xcenter * d_sdivzstepu -
			ycenter * d_sdivzstepv;
	d_tdivzorigin = axes->taxis[2] * mipscale - xcenter * d_tdivzstepu -
			ycenter * d_tdivzstepv;

	VectorScale (transformed_modelorg, mipscale, p_temp1);

	t = 0x10000*mipscale;
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


/*
==============
D_DrawSurfaces
==============
*/
void D_DrawSurfaces (void)
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

