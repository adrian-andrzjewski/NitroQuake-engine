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
// r_surf.c: surface-related refresh code

#include "quakedef.h"
#include "renderer/r_local.h"

#ifdef ASM486_TEXTURE_ANIMATION
#include <stddef.h>

typedef char texture_animation_i386_pointer_size[(sizeof(void *) == 4) ? 1 : -1];
typedef char texture_animation_texture_layout[
		(offsetof(texture_t, anim_total) == 24 &&
		offsetof(texture_t, anim_min) == 28 &&
		offsetof(texture_t, anim_max) == 32 &&
		offsetof(texture_t, anim_next) == 36 &&
		offsetof(texture_t, alternate_anims) == 40) ? 1 : -1];
typedef char texture_animation_entity_frame_offset[
		(offsetof(entity_t, frame) == 140) ? 1 : -1];
typedef char texture_animation_client_time_offset[
		(offsetof(client_state_t, time) == 572) ? 1 : -1];
#endif

#ifdef ASM486_SURFACE_DRAW
#include <stddef.h>

typedef char surface_draw_i386_pointer_size[(sizeof(void *) == 4) ? 1 : -1];
typedef char surface_draw_drawsurf_layout[
		(offsetof(drawsurf_t, surfdat) == 0 &&
		offsetof(drawsurf_t, rowbytes) == 4 &&
		offsetof(drawsurf_t, surf) == 8 &&
		offsetof(drawsurf_t, texture) == 28 &&
		offsetof(drawsurf_t, surfmip) == 32 &&
		offsetof(drawsurf_t, surfwidth) == 36 &&
		offsetof(drawsurf_t, surfheight) == 40) ? 1 : -1];
typedef char surface_draw_texture_layout[
		(offsetof(texture_t, width) == 16 &&
		offsetof(texture_t, height) == 20 &&
		offsetof(texture_t, offsets) == 44 &&
		sizeof(texture_t) == 60) ? 1 : -1];
typedef char surface_draw_surface_layout[
		(offsetof(msurface_t, texturemins) == 44 &&
		offsetof(msurface_t, extents) == 48) ? 1 : -1];
#endif

#ifdef ASM486_LIGHTMAP_BUILD
#include <stddef.h>

typedef char lightmap_build_i386_pointer_size[(sizeof(void *) == 4) ? 1 : -1];
typedef char lightmap_build_drawsurf_surf_offset[
		(offsetof(drawsurf_t, surf) == 8) ? 1 : -1];
typedef char lightmap_build_drawsurf_lightadj_offset[
		(offsetof(drawsurf_t, lightadj) == 12) ? 1 : -1];
typedef char lightmap_build_surface_dlightframe_offset[
		(offsetof(msurface_t, dlightframe) == 4) ? 1 : -1];
typedef char lightmap_build_surface_extents_offset[
		(offsetof(msurface_t, extents) == 48) ? 1 : -1];
typedef char lightmap_build_surface_styles_offset[
		(offsetof(msurface_t, styles) == 56) ? 1 : -1];
typedef char lightmap_build_surface_samples_offset[
		(offsetof(msurface_t, samples) == 60) ? 1 : -1];
typedef char lightmap_build_client_worldmodel_offset[
		(offsetof(client_state_t, worldmodel) == 2692) ? 1 : -1];
typedef char lightmap_build_model_lightdata_offset[
		(offsetof(model_t, lightdata) == 380) ? 1 : -1];
typedef char lightmap_build_refdef_ambient_offset[
		(offsetof(refdef_t, ambientlight) == 144) ? 1 : -1];
typedef char lightmap_build_cvar_value_offset[
		(offsetof(cvar_t, value) == 16) ? 1 : -1];
typedef char lightmap_build_lightmap_constants[
		(MAXLIGHTMAPS == 4 && VID_CBITS == 6 && MIPLEVELS == 4) ? 1 : -1];
#endif

#ifdef ASM486_DYNAMIC_LIGHT_PROJECTION
#include <stddef.h>

typedef char dynamic_light_i386_pointer_size[(sizeof(void *) == 4) ? 1 : -1];
typedef char dynamic_light_drawsurf_surf_offset[
		(offsetof(drawsurf_t, surf) == 8) ? 1 : -1];
typedef char dynamic_light_surface_dlightbits_offset[
		(offsetof(msurface_t, dlightbits) == 8) ? 1 : -1];
typedef char dynamic_light_surface_extents_offset[
		(offsetof(msurface_t, extents) == 48) ? 1 : -1];
typedef char dynamic_light_surface_plane_offset[
		(offsetof(msurface_t, plane) == 12) ? 1 : -1];
typedef char dynamic_light_surface_texturemins_offset[
		(offsetof(msurface_t, texturemins) == 44) ? 1 : -1];
typedef char dynamic_light_surface_texinfo_offset[
		(offsetof(msurface_t, texinfo) == 52) ? 1 : -1];
typedef char dynamic_light_plane_dist_offset[
		(offsetof(mplane_t, dist) == 12) ? 1 : -1];
typedef char dynamic_light_texinfo_vecs_offset[
		(offsetof(mtexinfo_t, vecs) == 0) ? 1 : -1];
typedef char dynamic_light_dlight_layout[
		(offsetof(dlight_t, radius) == 12 &&
		offsetof(dlight_t, minlight) == 24 &&
		sizeof(dlight_t) == 32) ? 1 : -1];
#endif

drawsurf_t	r_drawsurf;

int			r_dlight_contributed;

int				lightleft, sourcesstep, blocksize, sourcetstep;
int				lightdelta, lightdeltastep;
int				lightright, lightleftstep, lightrightstep, blockdivshift;
unsigned		blockdivmask;
void			*prowdestbase;
unsigned char	*pbasesource;
int				surfrowbytes;	// used by ASM files
unsigned		*r_lightptr;
int				r_stepback;
int				r_lightwidth;
int				r_numhblocks, r_numvblocks;
unsigned char	*r_source, *r_sourcemax;

void R_DrawSurfaceBlock8_mip0 (void);
void R_DrawSurfaceBlock8_mip1 (void);
void R_DrawSurfaceBlock8_mip2 (void);
void R_DrawSurfaceBlock8_mip3 (void);

static void	(*surfmiptable[4])(void) = {
	R_DrawSurfaceBlock8_mip0,
	R_DrawSurfaceBlock8_mip1,
	R_DrawSurfaceBlock8_mip2,
	R_DrawSurfaceBlock8_mip3
};



unsigned		blocklights[18*18];
#ifdef ASM486_LIGHTMAP_BUILD
unsigned		lightmap_single_table[256];
unsigned		lightmap_single_first;
int				lightmap_single_inverse_scale;
qboolean		lightmap_single_table_valid;
#else
static unsigned	lightmap_single_table[256];
static unsigned	lightmap_single_first;
static int		lightmap_single_inverse_scale;
static qboolean	lightmap_single_table_valid;
#endif

/*
===============
R_BuildLightMapNormalize_C

Reference implementation for the compact 486 normalization experiment.
Keep the arithmetic and clamp in the same order as the original loop in
R_BuildLightMap.
===============
*/
void R_BuildLightMapNormalize_C (unsigned *lights, int size)
{
	int		i;
	int		t;

	for (i=0 ; i<size ; i++)
	{
		t = (255*256 - (int)lights[i]) >> (8 - VID_CBITS);

		if (t < (1 << 6))
			t = (1 << 6);

		lights[i] = t;
	}
}

/*
===============
R_AddDynamicLights_C

Reference implementation. The original inner loop stores the approximate
distance in a float (`dist`) and indexes `blocklights[t*smax + s]`.
===============
*/
void R_AddDynamicLights_C (void)
{
	msurface_t *surf;
	int			lnum;
	int			sd, td;
	float		dist, rad, minlight;
	vec3_t		impact, local;
	int			s, t;
	int			i;
	int			smax, tmax;
	mtexinfo_t	*tex;

	surf = r_drawsurf.surf;
	smax = (surf->extents[0]>>4)+1;
	tmax = (surf->extents[1]>>4)+1;
	tex = surf->texinfo;

	for (lnum=0 ; lnum<MAX_DLIGHTS ; lnum++)
	{
		if ( !(surf->dlightbits & (1<<lnum) ) )
			continue;		// not lit by this light

		rad = cl_dlights[lnum].radius;
		dist = DotProduct (cl_dlights[lnum].origin, surf->plane->normal) -
				surf->plane->dist;
		rad -= fabs(dist);
		minlight = cl_dlights[lnum].minlight;
		if (rad < minlight)
			continue;
		minlight = rad - minlight;

		for (i=0 ; i<3 ; i++)
		{
			impact[i] = cl_dlights[lnum].origin[i] -
					surf->plane->normal[i]*dist;
		}

		local[0] = DotProduct (impact, tex->vecs[0]) + tex->vecs[0][3];
		local[1] = DotProduct (impact, tex->vecs[1]) + tex->vecs[1][3];

		local[0] -= surf->texturemins[0];
		local[1] -= surf->texturemins[1];
		
		for (t = 0 ; t<tmax ; t++)
		{
			td = local[1] - t*16;
			if (td < 0)
				td = -td;
			for (s=0 ; s<smax ; s++)
			{
				sd = local[0] - s*16;
				if (sd < 0)
					sd = -sd;
				if (sd > td)
					dist = sd + (td>>1);
				else
					dist = td + (sd>>1);
				if (dist < minlight)
#ifdef QUAKE2
				{
					unsigned temp;
					temp = (rad - dist)*256;
					i = t*smax + s;
					if (!cl_dlights[lnum].dark)
						blocklights[i] += temp;
					else
					{
						if (blocklights[i] > temp)
							blocklights[i] -= temp;
						else
							blocklights[i] = 0;
					}
				}
#else
					blocklights[t*smax + s] += (rad - dist)*256;
#endif
			}
		}
	}
}

#ifdef ASM486_DYNAMIC_LIGHT_PROJECTION
#ifdef BENCH486
/*
===============
R_AddDynamicLightProject_C

Keep the x87 projection and float-to-int conversions in a small C helper while
the surrounding per-light orchestration moves to assembly. The returned float
and integer coordinates let the independently selected C and ASM sample loops
keep their original inputs.
===============
*/
int R_AddDynamicLightProject_C (int lnum, msurface_t *surf, int smax, int tmax,
		float *local0, float *local1, int *local0_int, int *local1_int,
		int *idist_limit, int *irad, int *all_lit)
{
	float planedist, rad, fmin;
	vec3_t impact, local;
	int fmin_scaled, sd, td, idist, t;
	dlight_t *dl;
	mtexinfo_t *tex;

	dl = &cl_dlights[lnum];
	tex = surf->texinfo;
	rad = dl->radius;
	planedist = DotProduct (dl->origin, surf->plane->normal) -
			surf->plane->dist;
	rad -= fabs (planedist);
	if (rad < dl->minlight)
		return 0;
	fmin = rad - dl->minlight;
	*irad = (int)(rad * 256);
	fmin_scaled = (int)ceil (fmin * 256);
	*idist_limit = (fmin_scaled + 255) >> 8;

	impact[0] = dl->origin[0] - surf->plane->normal[0]*planedist;
	impact[1] = dl->origin[1] - surf->plane->normal[1]*planedist;
	impact[2] = dl->origin[2] - surf->plane->normal[2]*planedist;
	local[0] = DotProduct (impact, tex->vecs[0]) + tex->vecs[0][3];
	local[1] = DotProduct (impact, tex->vecs[1]) + tex->vecs[1][3];
	local[0] -= surf->texturemins[0];
	local[1] -= surf->texturemins[1];
	*local0 = local[0];
	*local1 = local[1];
	*local0_int = (int)local[0];
	*local1_int = (int)local[1];

	sd = *local0_int;
	if (sd < 0)
		sd = -sd;
	t = *local0_int - (smax - 1)*16;
	if (t < 0)
		t = -t;
	if (t > sd)
		sd = t;
	td = *local1_int;
	if (td < 0)
		td = -td;
	t = *local1_int - (tmax - 1)*16;
	if (t < 0)
		t = -t;
	if (t > td)
		td = t;
	if (sd > td)
		idist = sd + (td>>1);
	else
		idist = td + (sd>>1);
	*all_lit = (idist < *idist_limit);
	return 1;
}

#endif
#endif

#ifdef ASM486_DYNAMIC_LIGHT_ORCHESTRATION
/* C sample-loop reference used only when assembly owns the outer dlight loop. */
int R_AddDynamicLightSamples_C (unsigned *lights, int smax, int tmax,
		float local0, float local1, int idist_limit, int irad)
{
	unsigned *bl;
	int contributed, sd, td, idist, s, t;

	contributed = 0;
	for (t=0 ; t<tmax ; t++)
	{
		td = local1 - t*16;
		if (td < 0)
			td = -td;
		sd = local0;
		bl = lights + t * smax;
		for (s=0 ; s+3<smax ; s+=4)
		{
#define LIGHTMAP_DLIGHT_SAMPLE(index) \
			if (sd < 0) idist = -sd; else idist = sd; \
			sd -= 16; \
			if (idist > td) idist += (td>>1); \
			else idist = td + (idist>>1); \
			if (idist < idist_limit) \
			{ bl[index] += (unsigned)(irad - (idist << 8)); contributed = 1; }
			LIGHTMAP_DLIGHT_SAMPLE (s)
			LIGHTMAP_DLIGHT_SAMPLE (s+1)
			LIGHTMAP_DLIGHT_SAMPLE (s+2)
			LIGHTMAP_DLIGHT_SAMPLE (s+3)
#undef LIGHTMAP_DLIGHT_SAMPLE
		}
		for ( ; s<smax ; s++)
		{
			if (sd < 0)
				idist = -sd;
			else
				idist = sd;
			sd -= 16;
			if (idist > td)
				idist += (td>>1);
			else
				idist = td + (idist>>1);
			if (idist < idist_limit)
			{
				bl[s] += (unsigned)(irad - (idist << 8));
				contributed = 1;
			}
		}
	}
	return contributed;
}

#endif

/*
===============
R_AddDynamicLights

Same sampling as R_AddDynamicLights_C, but keep the per-texel distance in
an integer and walk `blocklights` with a row pointer so the 486 inner loop
does not store through a reused float or IMUL the lightmap index.
===============
*/
#if !defined(ASM486_DYNAMIC_LIGHT_ORCHESTRATION) || defined(BENCH486)
#ifdef ASM486_DYNAMIC_LIGHT_ORCHESTRATION
void R_AddDynamicLightsOrchestration_C (void)
#else
void R_AddDynamicLights (void)
#endif
{
	msurface_t *surf;
	int			lnum;
	int			sd, td, idist;
	float		planedist, rad, fmin;
	int			irad, fmin_scaled, idist_limit;
	vec3_t		impact, local;
	int			s, t;
	int			i;
	int			smax, tmax;
	int			all_lit;
	unsigned	dlightbits;
	unsigned	*bl;
	mtexinfo_t	*tex;
	int			contributed;

	surf = r_drawsurf.surf;
	smax = (surf->extents[0]>>4)+1;
	tmax = (surf->extents[1]>>4)+1;
	tex = surf->texinfo;
	dlightbits = (unsigned)surf->dlightbits;
	contributed = r_dlight_contributed;
	while (dlightbits)
	{
		lnum = __builtin_ctz (dlightbits);
		dlightbits &= dlightbits - 1;

		rad = cl_dlights[lnum].radius;
		planedist = DotProduct (cl_dlights[lnum].origin, surf->plane->normal) -
				surf->plane->dist;
		rad -= fabs(planedist);
		if (rad < cl_dlights[lnum].minlight)
			continue;
		fmin = rad - cl_dlights[lnum].minlight;
		irad = (int)(rad * 256);
		fmin_scaled = (int)ceil(fmin * 256);
		idist_limit = (fmin_scaled + 255) >> 8;

		for (i=0 ; i<3 ; i++)
		{
			impact[i] = cl_dlights[lnum].origin[i] -
					surf->plane->normal[i]*planedist;
		}

		local[0] = DotProduct (impact, tex->vecs[0]) + tex->vecs[0][3];
		local[1] = DotProduct (impact, tex->vecs[1]) + tex->vecs[1][3];

		local[0] -= surf->texturemins[0];
		local[1] -= surf->texturemins[1];

		#ifdef ASM486_DYNAMIC_LIGHTS
		sd = (int)local[0];
		if (sd < 0)
			sd = -sd;
		t = (int)local[0] - (smax - 1)*16;
		if (t < 0)
			t = -t;
		if (t > sd)
			sd = t;

		td = (int)local[1];
		if (td < 0)
			td = -td;
		t = (int)local[1] - (tmax - 1)*16;
		if (t < 0)
			t = -t;
		if (t > td)
			td = t;

		if (sd > td)
			idist = sd + (td>>1);
		else
			idist = td + (sd>>1);
		all_lit = (idist < idist_limit);
		contributed |= R_AddDynamicLightSamples_asm486 (blocklights,
				smax, tmax, (int)local[0], (int)local[1], local[1],
				idist_limit, irad, all_lit);
		#else
		for (t = 0 ; t<tmax ; t++)
		{
			td = local[1] - t*16;
			if (td < 0)
				td = -td;
			sd = local[0];
			bl = blocklights + t * smax;
			for (s=0 ; s+3<smax ; s+=4)
			{
				if (sd < 0)
					idist = -sd;
				else
					idist = sd;
				sd -= 16;
				if (idist > td)
					idist += (td>>1);
				else
					idist = td + (idist>>1);
				if (idist < idist_limit)
				{
					bl[s] += (unsigned)(irad - (idist << 8));
					contributed = 1;
				}

				if (sd < 0)
					idist = -sd;
				else
					idist = sd;
				sd -= 16;
				if (idist > td)
					idist += (td>>1);
				else
					idist = td + (idist>>1);
				if (idist < idist_limit)
				{
					bl[s+1] += (unsigned)(irad - (idist << 8));
					contributed = 1;
				}

				if (sd < 0)
					idist = -sd;
				else
					idist = sd;
				sd -= 16;
				if (idist > td)
					idist += (td>>1);
				else
					idist = td + (idist>>1);
				if (idist < idist_limit)
				{
					bl[s+2] += (unsigned)(irad - (idist << 8));
					contributed = 1;
				}

				if (sd < 0)
					idist = -sd;
				else
					idist = sd;
				sd -= 16;
				if (idist > td)
					idist += (td>>1);
				else
					idist = td + (idist>>1);
				if (idist < idist_limit)
				{
					bl[s+3] += (unsigned)(irad - (idist << 8));
					contributed = 1;
				}
			}
			for ( ; s<smax ; s++)
			{
				if (sd < 0)
					idist = -sd;
				else
					idist = sd;
				sd -= 16;
				if (idist > td)
					idist += (td>>1);
				else
					idist = td + (idist>>1);
				if (idist < idist_limit)
				{
					bl[s] += (unsigned)(irad - (idist << 8));
					contributed = 1;
				}
			}
		}
		#endif
	}
	r_dlight_contributed = contributed;
}
#endif

/*
===============
R_BuildLightMapStyles_C

Reference for the generic raw style-combination loop.  Keep the style planes
and accumulation order identical to the original R_BuildLightMap fallback.
===============
*/
void R_BuildLightMapStyles_C (unsigned *dest, byte *lightmap, int size,
		int maps, unsigned scale, int *lightadj)
{
	int		i, map;
	byte	*plane;

	plane = lightmap;
	for (i=0 ; i<size ; i++)
		dest[i] = scale + plane[i] * lightadj[0];

	for (map=1 ; map<maps ; map++)
	{
		plane += size;
		for (i=0 ; i<size ; i++)
			dest[i] += plane[i] * lightadj[map];
	}
}

void R_BuildLightMapFusedNoDlights_C (unsigned *dest, byte *lightmap,
		int size, int maps, unsigned scale, int *lightadj)
{
	int i, map, t;
	unsigned v;
	byte *plane;

	for (i=0 ; i<size ; i++)
	{
		v = scale + lightmap[i] * lightadj[0];
		for (map=1 ; map<maps ; map++)
		{
			plane = lightmap + map * size;
			v += plane[i] * lightadj[map];
		}
		t = (255*256 - (int)v) >> (8 - VID_CBITS);
		if (t < (1 << 6))
			t = (1 << 6);
		dest[i] = t;
	}
}

/*
===============
R_DlightContributes

Same discrete sample predicates as R_AddDynamicLights, but return as soon as
any sample would add light.  Used by D_CacheSurface to skip phantom-mark
rebuilds without changing lit output.
===============
*/
#if !defined(ASM486_DLIGHT_CONTRIBUTES) || defined(BENCH486)
#ifdef ASM486_DLIGHT_CONTRIBUTES
int R_DlightContributes_C (msurface_t *surf)
#else
int R_DlightContributes (msurface_t *surf)
#endif
{
	int			lnum;
	int			sd, td, idist;
	float		planedist, rad, fmin;
	int			fmin_scaled;
	vec3_t		impact, local;
	int			s, t;
	int			i;
	int			smax, tmax;
	unsigned	dlightbits;
	mtexinfo_t	*tex;

	smax = (surf->extents[0]>>4)+1;
	tmax = (surf->extents[1]>>4)+1;
	tex = surf->texinfo;
	dlightbits = (unsigned)surf->dlightbits;
	while (dlightbits)
	{
		lnum = __builtin_ctz (dlightbits);
		dlightbits &= dlightbits - 1;

		rad = cl_dlights[lnum].radius;
		planedist = DotProduct (cl_dlights[lnum].origin, surf->plane->normal) -
				surf->plane->dist;
		rad -= fabs(planedist);
		if (rad < cl_dlights[lnum].minlight)
			continue;
		fmin = rad - cl_dlights[lnum].minlight;
		fmin_scaled = (int)ceil(fmin * 256);

		for (i=0 ; i<3 ; i++)
		{
			impact[i] = cl_dlights[lnum].origin[i] -
					surf->plane->normal[i]*planedist;
		}

		local[0] = DotProduct (impact, tex->vecs[0]) + tex->vecs[0][3];
		local[1] = DotProduct (impact, tex->vecs[1]) + tex->vecs[1][3];

		local[0] -= surf->texturemins[0];
		local[1] -= surf->texturemins[1];

		// The weighted distance is monotonic in |sd| and |td|, so the
		// minimum over the discrete lightmap is its nearest clamped sample.
		s = (int)local[0];
		if (s <= 0)
			s = 0;
		else
		{
			s = (s + 8) >> 4;
			if (s >= smax)
				s = smax - 1;
		}
		sd = (int)local[0] - s*16;
		if (sd < 0)
			sd = -sd;

		t = (int)local[1];
		if (t <= 0)
			t = 0;
		else
		{
			t = (t + 8) >> 4;
			if (t >= tmax)
				t = tmax - 1;
		}
		td = (int)local[1] - t*16;
		if (td < 0)
			td = -td;

		if (sd > td)
			idist = sd + (td>>1);
		else
			idist = td + (sd>>1);
		if ((idist << 8) < fmin_scaled)
			return 1;
	}

	return 0;
}
#endif

/*
===============
R_BuildLightMap

Combine and scale multiple lightmaps into the 8.8 format in blocklights
===============
*/
#if !defined(ASM486_LIGHTMAP_BUILD) || defined(BENCH486)
#ifdef ASM486_LIGHTMAP_BUILD
void R_BuildLightMap_C (void)
#else
void R_BuildLightMap (void)
#endif
{
	int			smax, tmax;
	int			i, size;
	byte		*lightmap;
	unsigned	scale;
	int			maps;
	msurface_t	*surf;

	surf = r_drawsurf.surf;

	smax = (surf->extents[0]>>4)+1;
	tmax = (surf->extents[1]>>4)+1;
	size = smax*tmax;
	lightmap = surf->samples;

	if (r_fullbright.value || !cl.worldmodel->lightdata)
	{
		for (i=0 ; i<size ; i++)
			blocklights[i] = 0;
		return;
	}

// Fold ambient into the first lightmap so the common one-style case does not
// write blocklights twice. Extra styles still add on top, same 8.8 scale.
	scale = r_refdef.ambientlight<<8;
	maps = 0;
	if (lightmap && surf->styles[0] != 255)
	{
		unsigned	first;

		first = r_drawsurf.lightadj[0];
		// No dlights: fold invert/clamp into the lightmap walk so
		// blocklights is written once. Dlights still use the two-pass
		// reference (accumulate, then R_BuildLightMapNormalize_*).
		if (surf->dlightframe != r_framecount)
		{
			int			t;
			int			inverse_scale;
			unsigned	v;
			unsigned	a1, a2, a3;
			byte		*lm1, *lm2, *lm3;

			if (surf->styles[1] == 255)
			{
				inverse_scale = 255*256 - (int)scale;
				if (!lightmap_single_table_valid ||
						lightmap_single_first != first ||
						lightmap_single_inverse_scale != inverse_scale)
				{
					for (i=0 ; i<256 ; i++)
					{
						t = (inverse_scale - (int)(i * first)) >>
								(8 - VID_CBITS);
						if (t < (1 << 6))
							t = (1 << 6);
						lightmap_single_table[i] = t;
					}
					lightmap_single_first = first;
					lightmap_single_inverse_scale = inverse_scale;
					lightmap_single_table_valid = true;
				}
#ifdef PROFILE486
				// Texel population of the single-style table path, so the fused
				// multi-style loop below can be priced against a measured
				// denominator rather than inferred from rebuild_seconds.
				bench486_lm_single_texels += size;
#endif
				for (i=0 ; i<size ; i++)
				{
					blocklights[i] = lightmap_single_table[lightmap[i]];
				}
				return;
			}

			maps = surf->styles[2] == 255 ? 2 :
					surf->styles[3] == 255 ? 3 : 4;
#ifdef PROFILE486
			bench486_lm_fused_texels += size;
			bench486_lm_fused_maps[maps > 4 ? 4 : maps] += size;
#endif
#if defined(ASM486_FUSED_LIGHTMAP)
			R_BuildLightMapFusedNoDlights_asm486 (blocklights, lightmap,
					size, maps, scale, r_drawsurf.lightadj);
#else
			R_BuildLightMapFusedNoDlights_C (blocklights, lightmap,
					size, maps, scale, r_drawsurf.lightadj);
#endif
			return;

			lm1 = lightmap + size;
			a1 = r_drawsurf.lightadj[1];
			if (surf->styles[2] == 255)
			{
				int j = 0;
				for (; j+3 < size; j+=4)
				{
					v = scale + lightmap[j] * first + lm1[j] * a1;
					t = (255*256 - (int)v) >> (8 - VID_CBITS);
					if (t < (1 << 6)) t = (1 << 6);
					blocklights[j] = t;
					v = scale + lightmap[j+1] * first + lm1[j+1] * a1;
					t = (255*256 - (int)v) >> (8 - VID_CBITS);
					if (t < (1 << 6)) t = (1 << 6);
					blocklights[j+1] = t;
					v = scale + lightmap[j+2] * first + lm1[j+2] * a1;
					t = (255*256 - (int)v) >> (8 - VID_CBITS);
					if (t < (1 << 6)) t = (1 << 6);
					blocklights[j+2] = t;
					v = scale + lightmap[j+3] * first + lm1[j+3] * a1;
					t = (255*256 - (int)v) >> (8 - VID_CBITS);
					if (t < (1 << 6)) t = (1 << 6);
					blocklights[j+3] = t;
				}
				for (; j < size; j++)
				{
					v = scale + lightmap[j] * first + lm1[j] * a1;
					t = (255*256 - (int)v) >> (8 - VID_CBITS);
					if (t < (1 << 6))
						t = (1 << 6);
					blocklights[j] = t;
				}
				return;
			}

			lm2 = lm1 + size;
			a2 = r_drawsurf.lightadj[2];
			if (surf->styles[3] == 255)
			{
				int j = 0;
				for (; j+3 < size; j+=4)
				{
					v = scale + lightmap[j] * first + lm1[j] * a1 +
							lm2[j] * a2;
					t = (255*256 - (int)v) >> (8 - VID_CBITS);
					if (t < (1 << 6)) t = (1 << 6);
					blocklights[j] = t;
					v = scale + lightmap[j+1] * first + lm1[j+1] * a1 +
							lm2[j+1] * a2;
					t = (255*256 - (int)v) >> (8 - VID_CBITS);
					if (t < (1 << 6)) t = (1 << 6);
					blocklights[j+1] = t;
					v = scale + lightmap[j+2] * first + lm1[j+2] * a1 +
							lm2[j+2] * a2;
					t = (255*256 - (int)v) >> (8 - VID_CBITS);
					if (t < (1 << 6)) t = (1 << 6);
					blocklights[j+2] = t;
					v = scale + lightmap[j+3] * first + lm1[j+3] * a1 +
							lm2[j+3] * a2;
					t = (255*256 - (int)v) >> (8 - VID_CBITS);
					if (t < (1 << 6)) t = (1 << 6);
					blocklights[j+3] = t;
				}
				for (; j < size; j++)
				{
					v = scale + lightmap[j] * first + lm1[j] * a1 +
							lm2[j] * a2;
					t = (255*256 - (int)v) >> (8 - VID_CBITS);
					if (t < (1 << 6))
						t = (1 << 6);
					blocklights[j] = t;
				}
				return;
			}

			lm3 = lm2 + size;
			a3 = r_drawsurf.lightadj[3];
			{
				int j = 0;
				for (; j+3 < size; j+=4)
				{
					v = scale + lightmap[j] * first + lm1[j] * a1 +
							lm2[j] * a2 + lm3[j] * a3;
					t = (255*256 - (int)v) >> (8 - VID_CBITS);
					if (t < (1 << 6)) t = (1 << 6);
					blocklights[j] = t;
					v = scale + lightmap[j+1] * first + lm1[j+1] * a1 +
							lm2[j+1] * a2 + lm3[j+1] * a3;
					t = (255*256 - (int)v) >> (8 - VID_CBITS);
					if (t < (1 << 6)) t = (1 << 6);
					blocklights[j+1] = t;
					v = scale + lightmap[j+2] * first + lm1[j+2] * a1 +
							lm2[j+2] * a2 + lm3[j+2] * a3;
					t = (255*256 - (int)v) >> (8 - VID_CBITS);
					if (t < (1 << 6)) t = (1 << 6);
					blocklights[j+2] = t;
					v = scale + lightmap[j+3] * first + lm1[j+3] * a1 +
							lm2[j+3] * a2 + lm3[j+3] * a3;
					t = (255*256 - (int)v) >> (8 - VID_CBITS);
					if (t < (1 << 6)) t = (1 << 6);
					blocklights[j+3] = t;
				}
				for (; j < size; j++)
				{
					v = scale + lightmap[j] * first + lm1[j] * a1 +
							lm2[j] * a2 + lm3[j] * a3;
					t = (255*256 - (int)v) >> (8 - VID_CBITS);
					if (t < (1 << 6))
						t = (1 << 6);
					blocklights[j] = t;
				}
			}
			return;
		}

		maps = 1;
		for ( ; maps < MAXLIGHTMAPS && surf->styles[maps] != 255 ; maps++)
			;
#if defined(ASM486_LIGHTMAP_STYLES)
		R_BuildLightMapStyles_asm486 (blocklights, lightmap,
				size, maps, scale, r_drawsurf.lightadj);
#else
		R_BuildLightMapStyles_C (blocklights, lightmap,
				size, maps, scale, r_drawsurf.lightadj);
#endif
	}
	else
	{
		for (i=0 ; i<size ; i++)
			blocklights[i] = scale;
	}

// add all the dynamic lights
	if (surf->dlightframe == r_framecount)
	{
		r_dlight_contributed = 0;
#if defined(BENCH486) && defined(ASM486_DYNAMIC_LIGHT_ORCHESTRATION)
		R_AddDynamicLightsOrchestration_C ();
#else
		R_AddDynamicLights ();
#endif
	}

// bound, invert, and shift
#if defined(ASM486_LIGHTMAP_NORMALIZE)
	R_BuildLightMapNormalize_asm486 (blocklights, size);
#else
	R_BuildLightMapNormalize_C (blocklights, size);
#endif
}
#endif


/*
===============
R_TextureAnimationFrame_C

Reference frame-selection loop.  Keep this separate so the compact ASM
experiment can be compared without changing the animation setup or timing
calculation around it.
===============
*/
texture_t *R_TextureAnimationFrame_C (texture_t *base, int relative)
{
	int		count;

	count = 0;	
	while (base->anim_min > relative || base->anim_max <= relative)
	{
		base = base->anim_next;
		if (!base)
			Sys_Error ("R_TextureAnimation: broken cycle");
		if (++count > 100)
			Sys_Error ("R_TextureAnimation: infinite cycle");
	}

	return base;
}

/*
===============
R_TextureAnimation_C

Reference wrapper for animation selection and time conversion.
===============
*/
#if !defined(ASM486_TEXTURE_ANIMATION) || !id386 || defined(BENCH486)
static texture_t *R_TextureAnimation_C_Impl (texture_t *base)
{
	int		reletive;

	if (currententity->frame)
	{
		if (base->alternate_anims)
			base = base->alternate_anims;
	}
	
	if (!base->anim_total)
		return base;

	reletive = (int)(cl.time*10) % base->anim_total;

	return R_TextureAnimationFrame_C (base, reletive);
}
#endif

#ifdef BENCH486
texture_t *R_TextureAnimation_C (texture_t *base)
{
	return R_TextureAnimation_C_Impl (base);
}
#endif

/*
===============
R_TextureAnimation

Returns the proper texture for a given time and base texture.
===============
*/
#if !defined(ASM486_PUBLIC_BINDINGS) || !defined(ASM486_TEXTURE_ANIMATION)
texture_t *R_TextureAnimation (texture_t *base)
{
#if defined(ASM486_TEXTURE_ANIMATION) && id386
	return R_TextureAnimation_asm486 (base);
#else
	return R_TextureAnimation_C_Impl (base);
#endif
}
#endif /* public entry is assembly-owned when selected */

#if defined(ASM486_SURFACE_DRAW) && defined(PROFILE486)
static double r_drawsurface_asm_profile_stage_start;
static int r_drawsurface_asm_profile_active;

void R_DrawSurfaceProfileBegin_asm486_C (void)
{
	r_drawsurface_asm_profile_active = bench486_profile_frame_active;
	if (r_drawsurface_asm_profile_active)
		r_drawsurface_asm_profile_stage_start = Sys_FloatTime ();
}

void R_DrawSurfaceProfileAfterLightmap_asm486_C (void)
{
	if (r_drawsurface_asm_profile_active)
		bench486_surface_cache_lightmap_seconds += Sys_FloatTime () -
				r_drawsurface_asm_profile_stage_start;
}

void R_DrawSurfaceProfileCountBlocks_asm486_C (void)
{
	int mip, u, v;
	unsigned *top, *bottom;
	unsigned tl, tr, bl, br;

	if (!r_drawsurface_asm_profile_active)
		return;

	mip = r_drawsurf.surfmip & 3;
	top = blocklights;
	for (v=0 ; v<r_numvblocks ; v++)
	{
		bottom = top + r_lightwidth;
		for (u=0 ; u<r_numhblocks ; u++)
		{
			bench486_surface_cache_mip_blocks[mip]++;
			tl = top[u];
			tr = top[u+1];
			bl = bottom[u];
			br = bottom[u+1];
			bench486_surface_cache_mip_blocks_flat[mip]++;
			if (tl == tr && bl == br)
			{
				bench486_surface_cache_horizontal_flat_blocks++;
				bench486_surface_cache_horizontal_flat_per_mip[mip]++;
			}
			if (tl == bl && tr == br)
				bench486_surface_cache_vertical_flat_blocks++;
			if (tl == tr && tl == bl && tl == br)
			{
				bench486_surface_cache_flat_blocks++;
				bench486_surface_cache_flat_blocks_per_mip[mip]++;
			}
		}
		top = bottom;
	}
}

void R_DrawSurfaceProfileStartBlocks_asm486_C (void)
{
	if (r_drawsurface_asm_profile_active)
		r_drawsurface_asm_profile_stage_start = Sys_FloatTime ();
}

void R_DrawSurfaceProfileFinish_asm486_C (void)
{
	double elapsed;
	int mip;

	if (!r_drawsurface_asm_profile_active)
		return;

	elapsed = Sys_FloatTime () - r_drawsurface_asm_profile_stage_start;
	bench486_surface_cache_block_seconds += elapsed;
	if (r_drawsurf.surfmip >= 0 && r_drawsurf.surfmip < 4)
	{
		mip = r_drawsurf.surfmip;
		bench486_surface_cache_mip_calls[mip]++;
		bench486_surface_cache_mip_seconds[mip] += elapsed;
	}
}
#endif


/*
===============
R_DrawSurface
===============
*/
#if !defined(ASM486_SURFACE_DRAW) || defined(BENCH486)
#ifdef ASM486_SURFACE_DRAW
void R_DrawSurface_C (void)
#else
void R_DrawSurface (void)
#endif
{
	unsigned char	*basetptr;
	int				smax, tmax, twidth;
	int				u;
	int				soffset, basetoffset, texwidth;
	int				horzblockstep;
	unsigned char	*pcolumndest;
	void			(*pblockdrawer)(void);
	texture_t		*mt;
#ifdef PROFILE486
	double			bench486_surface_stage_start;
	double			bench486_surface_stage_elapsed;
	int				bench486_surface_profile_active;
unsigned long	bench486_lm_single_texels;
unsigned long	bench486_lm_fused_texels;
unsigned long	bench486_lm_fused_maps[5];
	int				bench486_light_v;
	unsigned		*bench486_light_top;
	unsigned		*bench486_light_bottom;
	unsigned		bench486_light_tl, bench486_light_tr;
	unsigned		bench486_light_bl, bench486_light_br;

	bench486_surface_profile_active = bench486_profile_frame_active;
	if (bench486_surface_profile_active)
		bench486_surface_stage_start = Sys_FloatTime ();
#endif

// calculate the lightings
	R_BuildLightMap ();
#ifdef PROFILE486
	if (bench486_surface_profile_active)
	{
		bench486_surface_cache_lightmap_seconds += Sys_FloatTime () -
				bench486_surface_stage_start;
	}
#endif
	
	surfrowbytes = r_drawsurf.rowbytes;

	mt = r_drawsurf.texture;
	
	r_source = (byte *)mt + mt->offsets[r_drawsurf.surfmip];
	
// the fractional light values should range from 0 to (VID_GRADES - 1) << 16
// from a source range of 0 - 255
	
	texwidth = mt->width >> r_drawsurf.surfmip;

	blocksize = 16 >> r_drawsurf.surfmip;
	blockdivshift = 4 - r_drawsurf.surfmip;
	blockdivmask = (1 << blockdivshift) - 1;
	
	r_lightwidth = (r_drawsurf.surf->extents[0]>>4)+1;

	r_numhblocks = r_drawsurf.surfwidth >> blockdivshift;
	r_numvblocks = r_drawsurf.surfheight >> blockdivshift;
#ifdef PROFILE486
	if (bench486_surface_profile_active)
	{
		int	bench486_mip = r_drawsurf.surfmip & 3;

		for (bench486_light_v=0 ; bench486_light_v<r_numvblocks ;
				bench486_light_v++)
		{
			bench486_light_top = blocklights +
					bench486_light_v * r_lightwidth;
			bench486_light_bottom = bench486_light_top + r_lightwidth;
			for (u=0 ; u<r_numhblocks ; u++)
			{
				bench486_light_tl = bench486_light_top[u];
				bench486_light_tr = bench486_light_top[u+1];
				bench486_light_bl = bench486_light_bottom[u];
				bench486_light_br = bench486_light_bottom[u+1];
				bench486_surface_cache_mip_blocks_flat[bench486_mip]++;
				if (bench486_light_tl == bench486_light_tr &&
						bench486_light_bl == bench486_light_br)
				{
					bench486_surface_cache_horizontal_flat_blocks++;
					bench486_surface_cache_horizontal_flat_per_mip[bench486_mip]++;
				}
				if (bench486_light_tl == bench486_light_bl &&
						bench486_light_tr == bench486_light_br)
					bench486_surface_cache_vertical_flat_blocks++;
				if (bench486_light_tl == bench486_light_tr &&
						bench486_light_tl == bench486_light_bl &&
						bench486_light_tl == bench486_light_br)
				{
					bench486_surface_cache_flat_blocks++;
					bench486_surface_cache_flat_blocks_per_mip[bench486_mip]++;
				}
			}
		}
	}
#endif

//==============================

	// DOS 8-bit software path; R_DrawSurfaceBlock16 remains the 16-bit
	// reference and is unused by qbench.  Hoist the mip dispatch out of
	// the per-column loop so the 486 avoids an indirect CALL per hblock.
	// Direct mip dispatch was 1.1ms slower per-column; hoisting saves
	// 220k indirect CALLs per timedemo.
	horzblockstep = blocksize;

	smax = texwidth;
	twidth = texwidth;
	tmax = mt->height >> r_drawsurf.surfmip;
	sourcetstep = texwidth;
	r_stepback = tmax * twidth;
	r_sourcemax = r_source + r_stepback;

	soffset = r_drawsurf.surf->texturemins[0];
	basetoffset = r_drawsurf.surf->texturemins[1];

// << 16 components are to guarantee positive values for wrap.
	// Quake textures are power-of-two; avoid IDIV on the 486 rebuild path.
	soffset = (soffset >> r_drawsurf.surfmip) + (smax << 16);
	if (smax && !(smax & (smax - 1)))
		soffset &= (smax - 1);
	else
		soffset %= smax;
	{
		int		toffset;

		toffset = (basetoffset >> r_drawsurf.surfmip) + (tmax << 16);
		if (tmax && !(tmax & (tmax - 1)))
			toffset &= (tmax - 1);
		else
			toffset %= tmax;
		basetptr = &r_source[toffset * twidth];
	}

	pcolumndest = r_drawsurf.surfdat;
#ifdef PROFILE486
	if (bench486_surface_profile_active)
		bench486_surface_stage_start = Sys_FloatTime ();
#endif

	if (smax && !(smax & (smax - 1)))
	{
		int soffsetmask = smax - 1;
		switch (r_drawsurf.surfmip)
		{
		case 0:
			for (u=0 ; u<r_numhblocks; u++)
			{
				r_lightptr = blocklights + u;
				prowdestbase = pcolumndest;
				pbasesource = basetptr + soffset;
				R_DrawSurfaceBlock8_mip0();
				soffset = (soffset + blocksize) & soffsetmask;
				pcolumndest += horzblockstep;
			}
			break;
		case 1:
			for (u=0 ; u<r_numhblocks; u++)
			{
				r_lightptr = blocklights + u;
				prowdestbase = pcolumndest;
				pbasesource = basetptr + soffset;
				R_DrawSurfaceBlock8_mip1();
				soffset = (soffset + blocksize) & soffsetmask;
				pcolumndest += horzblockstep;
			}
			break;
		case 2:
			for (u=0 ; u<r_numhblocks; u++)
			{
				r_lightptr = blocklights + u;
				prowdestbase = pcolumndest;
				pbasesource = basetptr + soffset;
				R_DrawSurfaceBlock8_mip2();
				soffset = (soffset + blocksize) & soffsetmask;
				pcolumndest += horzblockstep;
			}
			break;
		case 3:
			for (u=0 ; u<r_numhblocks; u++)
			{
				r_lightptr = blocklights + u;
				prowdestbase = pcolumndest;
				pbasesource = basetptr + soffset;
				R_DrawSurfaceBlock8_mip3();
				soffset = (soffset + blocksize) & soffsetmask;
				pcolumndest += horzblockstep;
			}
			break;
		default:
			pblockdrawer = surfmiptable[r_drawsurf.surfmip];
			for (u=0 ; u<r_numhblocks; u++)
			{
				r_lightptr = blocklights + u;
				prowdestbase = pcolumndest;
				pbasesource = basetptr + soffset;
				(*pblockdrawer)();
				soffset = (soffset + blocksize) & soffsetmask;
				pcolumndest += horzblockstep;
			}
			break;
		}
	}
	else
	{
		switch (r_drawsurf.surfmip)
		{
		case 0:
			for (u=0 ; u<r_numhblocks; u++)
			{
				r_lightptr = blocklights + u;
				prowdestbase = pcolumndest;
				pbasesource = basetptr + soffset;
				R_DrawSurfaceBlock8_mip0();
				soffset = soffset + blocksize;
				if (soffset >= smax) soffset = 0;
				pcolumndest += horzblockstep;
			}
			break;
		case 1:
			for (u=0 ; u<r_numhblocks; u++)
			{
				r_lightptr = blocklights + u;
				prowdestbase = pcolumndest;
				pbasesource = basetptr + soffset;
				R_DrawSurfaceBlock8_mip1();
				soffset = soffset + blocksize;
				if (soffset >= smax) soffset = 0;
				pcolumndest += horzblockstep;
			}
			break;
		case 2:
			for (u=0 ; u<r_numhblocks; u++)
			{
				r_lightptr = blocklights + u;
				prowdestbase = pcolumndest;
				pbasesource = basetptr + soffset;
				R_DrawSurfaceBlock8_mip2();
				soffset = soffset + blocksize;
				if (soffset >= smax) soffset = 0;
				pcolumndest += horzblockstep;
			}
			break;
		case 3:
			for (u=0 ; u<r_numhblocks; u++)
			{
				r_lightptr = blocklights + u;
				prowdestbase = pcolumndest;
				pbasesource = basetptr + soffset;
				R_DrawSurfaceBlock8_mip3();
				soffset = soffset + blocksize;
				if (soffset >= smax) soffset = 0;
				pcolumndest += horzblockstep;
			}
			break;
		default:
			pblockdrawer = surfmiptable[r_drawsurf.surfmip];
			for (u=0 ; u<r_numhblocks; u++)
			{
				r_lightptr = blocklights + u;
				prowdestbase = pcolumndest;
				pbasesource = basetptr + soffset;
				(*pblockdrawer)();
				soffset = soffset + blocksize;
				if (soffset >= smax) soffset = 0;
				pcolumndest += horzblockstep;
			}
			break;
		}
	}
#ifdef PROFILE486
	if (bench486_surface_profile_active)
	{
		bench486_surface_stage_elapsed = Sys_FloatTime () -
				bench486_surface_stage_start;
		bench486_surface_cache_block_seconds +=
				bench486_surface_stage_elapsed;
		if (r_drawsurf.surfmip >= 0 && r_drawsurf.surfmip < 4)
		{
			bench486_surface_cache_mip_calls[r_drawsurf.surfmip]++;
			bench486_surface_cache_mip_blocks[r_drawsurf.surfmip] +=
					r_numhblocks * r_numvblocks;
			bench486_surface_cache_mip_seconds[r_drawsurf.surfmip] +=
					bench486_surface_stage_elapsed;
		}
	}
#endif
}
#endif


//=============================================================================

#if	!id386

/*
================
R_DrawSurfaceBlock8_mip0
================
*/
void R_DrawSurfaceBlock8_mip0 (void)
{
	int				v, i, b, lightstep, lighttemp, light;
	unsigned char	pix, *psource, *prowdest;

	psource = pbasesource;
	prowdest = prowdestbase;

	for (v=0 ; v<r_numvblocks ; v++)
	{
	// FIXME: make these locals?
	// FIXME: use delta rather than both right and left, like ASM?
		lightleft = r_lightptr[0];
		lightright = r_lightptr[1];
		r_lightptr += r_lightwidth;
		lightleftstep = (r_lightptr[0] - lightleft) >> 4;
		lightrightstep = (r_lightptr[1] - lightright) >> 4;

		for (i=0 ; i<16 ; i++)
		{
			lighttemp = lightleft - lightright;
			lightstep = lighttemp >> 4;

			light = lightright;

			for (b=15; b>=0; b--)
			{
				pix = psource[b];
				prowdest[b] = ((unsigned char *)vid.colormap)
						[(light & 0xFF00) + pix];
				light += lightstep;
			}
	
			psource += sourcetstep;
			lightright += lightrightstep;
			lightleft += lightleftstep;
			prowdest += surfrowbytes;
		}

		if (psource >= r_sourcemax)
			psource -= r_stepback;
	}
}


/*
================
R_DrawSurfaceBlock8_mip1
================
*/
void R_DrawSurfaceBlock8_mip1 (void)
{
	int				v, i, b, lightstep, lighttemp, light;
	unsigned char	pix, *psource, *prowdest;

	psource = pbasesource;
	prowdest = prowdestbase;

	for (v=0 ; v<r_numvblocks ; v++)
	{
	// FIXME: make these locals?
	// FIXME: use delta rather than both right and left, like ASM?
		lightleft = r_lightptr[0];
		lightright = r_lightptr[1];
		r_lightptr += r_lightwidth;
		lightleftstep = (r_lightptr[0] - lightleft) >> 3;
		lightrightstep = (r_lightptr[1] - lightright) >> 3;

		for (i=0 ; i<8 ; i++)
		{
			lighttemp = lightleft - lightright;
			lightstep = lighttemp >> 3;

			light = lightright;

			for (b=7; b>=0; b--)
			{
				pix = psource[b];
				prowdest[b] = ((unsigned char *)vid.colormap)
						[(light & 0xFF00) + pix];
				light += lightstep;
			}
	
			psource += sourcetstep;
			lightright += lightrightstep;
			lightleft += lightleftstep;
			prowdest += surfrowbytes;
		}

		if (psource >= r_sourcemax)
			psource -= r_stepback;
	}
}


/*
================
R_DrawSurfaceBlock8_mip2
================
*/
void R_DrawSurfaceBlock8_mip2 (void)
{
	int				v, i, b, lightstep, lighttemp, light;
	unsigned char	pix, *psource, *prowdest;

	psource = pbasesource;
	prowdest = prowdestbase;

	for (v=0 ; v<r_numvblocks ; v++)
	{
	// FIXME: make these locals?
	// FIXME: use delta rather than both right and left, like ASM?
		lightleft = r_lightptr[0];
		lightright = r_lightptr[1];
		r_lightptr += r_lightwidth;
		lightleftstep = (r_lightptr[0] - lightleft) >> 2;
		lightrightstep = (r_lightptr[1] - lightright) >> 2;

		for (i=0 ; i<4 ; i++)
		{
			lighttemp = lightleft - lightright;
			lightstep = lighttemp >> 2;

			light = lightright;

			for (b=3; b>=0; b--)
			{
				pix = psource[b];
				prowdest[b] = ((unsigned char *)vid.colormap)
						[(light & 0xFF00) + pix];
				light += lightstep;
			}
	
			psource += sourcetstep;
			lightright += lightrightstep;
			lightleft += lightleftstep;
			prowdest += surfrowbytes;
		}

		if (psource >= r_sourcemax)
			psource -= r_stepback;
	}
}


/*
================
R_DrawSurfaceBlock8_mip3
================
*/
void R_DrawSurfaceBlock8_mip3 (void)
{
	int				v, i, b, lightstep, lighttemp, light;
	unsigned char	pix, *psource, *prowdest;

	psource = pbasesource;
	prowdest = prowdestbase;

	for (v=0 ; v<r_numvblocks ; v++)
	{
	// FIXME: make these locals?
	// FIXME: use delta rather than both right and left, like ASM?
		lightleft = r_lightptr[0];
		lightright = r_lightptr[1];
		r_lightptr += r_lightwidth;
		lightleftstep = (r_lightptr[0] - lightleft) >> 1;
		lightrightstep = (r_lightptr[1] - lightright) >> 1;

		for (i=0 ; i<2 ; i++)
		{
			lighttemp = lightleft - lightright;
			lightstep = lighttemp >> 1;

			light = lightright;

			for (b=1; b>=0; b--)
			{
				pix = psource[b];
				prowdest[b] = ((unsigned char *)vid.colormap)
						[(light & 0xFF00) + pix];
				light += lightstep;
			}
	
			psource += sourcetstep;
			lightright += lightrightstep;
			lightleft += lightleftstep;
			prowdest += surfrowbytes;
		}

		if (psource >= r_sourcemax)
			psource -= r_stepback;
	}
}


/*
================
R_DrawSurfaceBlock16

FIXME: make this work
================
*/
void R_DrawSurfaceBlock16 (void)
{
	int				k;
	unsigned char	*psource;
	int				lighttemp, lightstep, light;
	unsigned short	*prowdest;

	prowdest = (unsigned short *)prowdestbase;

	for (k=0 ; k<blocksize ; k++)
	{
		unsigned short	*pdest;
		unsigned char	pix;
		int				b;

		psource = pbasesource;
		lighttemp = lightright - lightleft;
		lightstep = lighttemp >> blockdivshift;

		light = lightleft;
		pdest = prowdest;

		for (b=0; b<blocksize; b++)
		{
			pix = *psource;
			*pdest = vid.colormap16[(light & 0xFF00) + pix];
			psource += sourcesstep;
			pdest++;
			light += lightstep;
		}

		pbasesource += sourcetstep;
		lightright += lightrightstep;
		lightleft += lightleftstep;
		prowdest = (unsigned short *)((long)prowdest + surfrowbytes);
	}

	prowdestbase = prowdest;
}

#endif


//============================================================================

/*
================
R_GenTurbTile
================
*/
void R_GenTurbTile (pixel_t *pbasetex, void *pdest)
{
	int		*turb;
	int		i, j, s, t;
	byte	*pd;
	
	turb = sintable + ((int)(cl.time*SPEED)&(CYCLE-1));
	pd = (byte *)pdest;

	for (i=0 ; i<TILE_SIZE ; i++)
	{
		for (j=0 ; j<TILE_SIZE ; j++)
		{	
			s = (((j << 16) + turb[i & (CYCLE-1)]) >> 16) & 63;
			t = (((i << 16) + turb[j & (CYCLE-1)]) >> 16) & 63;
			*pd++ = *(pbasetex + (t<<6) + s);
		}
	}
}


/*
================
R_GenTurbTile16
================
*/
void R_GenTurbTile16 (pixel_t *pbasetex, void *pdest)
{
	int				*turb;
	int				i, j, s, t;
	unsigned short	*pd;

	turb = sintable + ((int)(cl.time*SPEED)&(CYCLE-1));
	pd = (unsigned short *)pdest;

	for (i=0 ; i<TILE_SIZE ; i++)
	{
		for (j=0 ; j<TILE_SIZE ; j++)
		{	
			s = (((j << 16) + turb[i & (CYCLE-1)]) >> 16) & 63;
			t = (((i << 16) + turb[j & (CYCLE-1)]) >> 16) & 63;
			*pd++ = d_8to16table[*(pbasetex + (t<<6) + s)];
		}
	}
}


/*
================
R_GenTile
================
*/
void R_GenTile (msurface_t *psurf, void *pdest)
{
	if (psurf->flags & SURF_DRAWTURB)
	{
		if (r_pixbytes == 1)
		{
			R_GenTurbTile ((pixel_t *)
				((byte *)psurf->texinfo->texture + psurf->texinfo->texture->offsets[0]), pdest);
		}
		else
		{
			R_GenTurbTile16 ((pixel_t *)
				((byte *)psurf->texinfo->texture + psurf->texinfo->texture->offsets[0]), pdest);
		}
	}
	else if (psurf->flags & SURF_DRAWSKY)
	{
		if (r_pixbytes == 1)
		{
			R_GenSkyTile (pdest);
		}
		else
		{
			R_GenSkyTile16 (pdest);
		}
	}
	else
	{
		Sys_Error ("Unknown tile type");
	}
}

