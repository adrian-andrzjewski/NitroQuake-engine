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
// d_surf.c: rasterization driver surface heap manager

#include "common.h"
#include "cvar.h"
#include "bspfile.h"
#include "client.h"
#include "model.h"
#include "render.h"
#include "sys.h"
#include "zone.h"
#include "d_iface.h"
#include "tests/bench486/bench486_profile.h"
#include "renderer/d_local.h"
#include "renderer/asm_drawingdriver.h"
#include "renderer/r_local.h"

#ifdef ASM486_SURFACE_CACHE_CHECK
#include <stddef.h>
#ifdef DEBUG
#define ASM486_SURFCACHE_TEXTURE_OFFSET 44
#define ASM486_SURFCACHE_DATA_OFFSET 48
#else
#define ASM486_SURFCACHE_TEXTURE_OFFSET 40
#define ASM486_SURFCACHE_DATA_OFFSET 44
#endif
typedef char surface_cache_setup_extents_layout[
		(offsetof(msurface_t, extents) == 48) ? 1 : -1];
typedef char surface_cache_entry_layout[
		(offsetof(msurface_t, dlightframe) == 4 &&
		offsetof(msurface_t, cachespots) == 28 &&
		offsetof(msurface_t, texinfo) == 52 &&
		offsetof(msurface_t, styles) == 56 &&
		offsetof(mtexinfo_t, texture) == 36 &&
		offsetof(texture_t, anim_total) == 24 &&
		offsetof(texture_t, alternate_anims) == 40 &&
		offsetof(entity_t, frame) == 140) ? 1 : -1];
typedef char surface_cache_setup_drawsurf_layout[
		(MAXLIGHTMAPS == 4 && MIPLEVELS == 4 &&
		offsetof(msurface_t, cachespots) == 28 &&
		offsetof(msurface_t, styles) == 56 &&
		offsetof(drawsurf_t, lightadj) == 12 &&
		offsetof(drawsurf_t, surf) == 8 &&
		offsetof(drawsurf_t, texture) == 28 &&
		sizeof(((drawsurf_t *)0)->lightadj[0]) == 4 &&
		(offsetof(drawsurf_t, rowbytes) == 4 &&
		offsetof(drawsurf_t, surfmip) == 32 &&
		offsetof(drawsurf_t, surfwidth) == 36 &&
		offsetof(drawsurf_t, surfheight) == 40 &&
		offsetof(surfcache_t, next) == 0 &&
		offsetof(surfcache_t, owner) == 4 &&
		offsetof(surfcache_t, lightadj) == 8 &&
		offsetof(surfcache_t, dlight) == 24 &&
		offsetof(surfcache_t, size) == 28 &&
		offsetof(surfcache_t, width) == 32 &&
		offsetof(surfcache_t, texture) == ASM486_SURFCACHE_TEXTURE_OFFSET &&
		offsetof(surfcache_t, data) == ASM486_SURFCACHE_DATA_OFFSET)) ? 1 : -1];
#endif

#if defined(PROFILE486) && !defined(ASM486_SURFACE_CACHE_CHECK)
static int D_CacheSurfaceProbeDlight (msurface_t *surface)
{
	double start;
	double end;
	int contributes;

	if (!bench486_profile_frame_active)
		return R_DlightContributes (surface);

	start = Sys_FloatTime ();
	contributes = R_DlightContributes (surface);
	end = Sys_FloatTime ();
	bench486_surface_cache_dlight_probes++;
	if (contributes)
		bench486_surface_cache_dlight_contributing_probes++;
	bench486_surface_cache_dlight_probe_seconds += end - start;
	return contributes;
}
#define D_CACHE_SURFACE_PROBE_DLIGHT(surface) D_CacheSurfaceProbeDlight (surface)
#elif !defined(ASM486_SURFACE_CACHE_CHECK)
#define D_CACHE_SURFACE_PROBE_DLIGHT(surface) R_DlightContributes (surface)
#endif

qboolean        r_cache_thrash;         // set if surface cache is thrashing

int                                     sc_size;
surfcache_t                     *sc_rover, *sc_base;

#define GUARDSIZE       4


#if !defined(ASM486_SURFACE_CACHE_CHECK) || defined(BENCH486)
#if defined(ASM486_SURFACE_CACHE_CHECK)
int D_SurfaceCacheForRes_C (int width, int height)
#else
int D_SurfaceCacheForRes (int width, int height)
#endif
{
	int             size, pix;

	if (COM_CheckParm ("-surfcachesize"))
	{
		size = Q_atoi(com_argv[COM_CheckParm("-surfcachesize")+1]) * 1024;
		return size;
	}
	
	size = SURFCACHE_SIZE_AT_320X200;

	pix = width*height;
	if (pix > 64000)
		size += (pix-64000)*3;
		

	return size;
}
#endif

void D_CheckCacheGuard (void)
{
	byte    *s;
	int             i;

	s = (byte *)sc_base + sc_size;
	for (i=0 ; i<GUARDSIZE ; i++)
		if (s[i] != (byte)i)
			Sys_Error ("D_CheckCacheGuard: failed");
}

#if !defined(ASM486_SURFACE_CACHE_CHECK) || defined(BENCH486)
void D_ClearCacheGuard (void)
{
	byte    *s;
	int             i;
	
	s = (byte *)sc_base + sc_size;
	for (i=0 ; i<GUARDSIZE ; i++)
		s[i] = (byte)i;
}
#endif


/*
================
D_InitCaches

================
*/
#if !defined(ASM486_SURFACE_CACHE_CHECK) || defined(BENCH486)
#if defined(ASM486_SURFACE_CACHE_CHECK)
void D_InitCaches_C (void *buffer, int size)
#else
void D_InitCaches (void *buffer, int size)
#endif
{

	if (!msg_suppress_1)
		Con_Printf ("%ik surface cache\n", size/1024);

	sc_size = size - GUARDSIZE;
	sc_base = (surfcache_t *)buffer;
	sc_rover = sc_base;
	
	sc_base->next = NULL;
	sc_base->owner = NULL;
	sc_base->size = sc_size;
	
	D_ClearCacheGuard ();
}
#endif


/*
==================
D_FlushCaches
==================
*/
#if defined(BENCH486) && defined(ASM486_SURFACE_CACHE_CHECK)
#define D_FLUSH_CACHES_C_ENTRY D_FlushCaches_C
#elif !defined(ASM486_DRAWING_DRIVER) && !defined(ASM486_SURFACE_CACHE_CHECK)
#define D_FLUSH_CACHES_C_ENTRY D_FlushCaches
#endif
#ifdef D_FLUSH_CACHES_C_ENTRY
void D_FLUSH_CACHES_C_ENTRY (void)
{
	surfcache_t     *c;
	
	if (!sc_base)
		return;

	for (c = sc_base ; c ; c = c->next)
	{
		if (c->owner)
			*c->owner = NULL;
	}
	
	sc_rover = sc_base;
	sc_base->next = NULL;
	sc_base->owner = NULL;
	sc_base->size = sc_size;
}
#undef D_FLUSH_CACHES_C_ENTRY
#endif

/*
=================
D_SCAlloc
=================
*/
#if !defined(ASM486_SURFACE_CACHE_CHECK) || defined(BENCH486)
#ifdef ASM486_SURFACE_CACHE_CHECK
surfcache_t     *D_SCAlloc_C (int width, int size)
#else
surfcache_t     *D_SCAlloc (int width, int size)
#endif
{
	surfcache_t             *new;
	qboolean                wrapped_this_time;

	if ((width < 0) || (width > 256))
		Sys_Error ("D_SCAlloc: bad cache width %d\n", width);

	if ((size <= 0) || (size > 0x10000))
		Sys_Error ("D_SCAlloc: bad cache size %d\n", size);

#ifdef PROFILE486
	if (bench486_profile_frame_active)
	{
		bench486_surface_cache_allocations++;
		bench486_surface_cache_requested_bytes += size;
	}
#endif
	
	size = (int)&((surfcache_t *)0)->data[size];
	size = (size + 3) & ~3;
	if (size > sc_size)
		Sys_Error ("D_SCAlloc: %i > cache size",size);

// if there is not size bytes after the rover, reset to the start
	wrapped_this_time = false;

	if ( !sc_rover || (byte *)sc_rover - (byte *)sc_base > sc_size - size)
	{
		if (sc_rover)
		{
			wrapped_this_time = true;
#ifdef PROFILE486
			if (bench486_profile_frame_active)
				bench486_surface_cache_wraps++;
#endif
		}
		sc_rover = sc_base;
	}
		
// colect and free surfcache_t blocks until the rover block is large enough
	new = sc_rover;
	if (sc_rover->owner)
	{
		*sc_rover->owner = NULL;
#ifdef PROFILE486
		if (bench486_profile_frame_active)
		{
			bench486_surface_cache_invalidated_blocks++;
			bench486_surface_cache_reclaimed_bytes += sc_rover->size;
		}
#endif
	}
	
	while (new->size < size)
	{
	// free another
		sc_rover = sc_rover->next;
		if (!sc_rover)
			Sys_Error ("D_SCAlloc: hit the end of memory");
		if (sc_rover->owner)
		{
			*sc_rover->owner = NULL;
	#ifdef PROFILE486
			if (bench486_profile_frame_active)
			{
				bench486_surface_cache_invalidated_blocks++;
				bench486_surface_cache_reclaimed_bytes += sc_rover->size;
			}
	#endif
		}
			
		new->size += sc_rover->size;
		new->next = sc_rover->next;
	}

// create a fragment out of any leftovers
	if (new->size - size > 256)
	{
		sc_rover = (surfcache_t *)( (byte *)new + size);
		sc_rover->size = new->size - size;
		sc_rover->next = new->next;
		sc_rover->width = 0;
		sc_rover->owner = NULL;
		new->next = sc_rover;
		new->size = size;
	}
	else
		sc_rover = new->next;
	
	new->width = width;
#ifdef DEBUG
	if (width > 0)
		new->height = (size - sizeof(*new) + sizeof(new->data)) / width;
#endif

	new->owner = NULL;              // should be set properly after return

	if (d_roverwrapped)
	{
		if (wrapped_this_time || (sc_rover >= d_initial_rover))
		{
			if (!r_cache_thrash)
			{
				r_cache_thrash = true;
#ifdef PROFILE486
				if (bench486_profile_frame_active)
					bench486_surface_cache_thrash_frames++;
#endif
			}
		}
	}
	else if (wrapped_this_time)
	{       
		d_roverwrapped = true;
	}

#ifdef DEBUG
	D_CheckCacheGuard ();
#endif
	return new;
}
#endif


/*
=================
D_SCDump
=================
*/
void D_SCDump (void)
{
	surfcache_t             *test;

	for (test = sc_base ; test ; test = test->next)
	{
		if (test == sc_rover)
			Sys_Printf ("ROVER:\n");
		printf ("%p : %i bytes     %i width\n",test, test->size, test->width);
	}
}

//=============================================================================

// if the num is not a power of 2, assume it will not repeat

int     MaskForNum (int num)
{
	if (num==128)
		return 127;
	if (num==64)
		return 63;
	if (num==32)
		return 31;
	if (num==16)
		return 15;
	return 255;
}

int D_log2 (int num)
{
	int     c;
	
	c = 0;
	
	while (num>>=1)
		c++;
	return c;
}

//=============================================================================

#if !defined(ASM486_SURFACE_CACHE_CHECK) || defined(BENCH486)
/*
================
D_CacheSurface
================
*/
#ifdef ASM486_SURFACE_CACHE_CHECK
surfcache_t *D_CacheSurface_C (msurface_t *surface, int miplevel)
#else
surfcache_t *D_CacheSurface (msurface_t *surface, int miplevel)
#endif
{
	surfcache_t     *cache;
	texture_t	*tex;
#ifdef ASM486_SURFACE_CACHE_CHECK
	int cache_created;
#endif
#ifdef PROFILE486
	double			bench486_surface_cache_start;
	double			bench486_surface_cache_rebuild_start;
	double			bench486_surface_cache_now;
	double			bench486_surface_cache_elapsed;
	double			bench486_surface_cache_alloc_start;
	double			bench486_surface_cache_draw_start;
	int				bench486_surface_cache_profile_active;

	bench486_surface_cache_profile_active = bench486_profile_frame_active;
	if (bench486_surface_cache_profile_active)
		bench486_surface_cache_start = Sys_FloatTime ();
#endif
	BENCH486_PROFILE_ENTER (BENCH486_PROFILE_SURFACE_CACHE);

//
// if the surface is animating or flashing, flush the cache.
// Static textures skip the R_TextureAnimation call; that function
// remains the reference for alternate skins and animated frames.
//
	tex = surface->texinfo->texture;
	if (tex->anim_total || (currententity->frame && tex->alternate_anims))
		tex = R_TextureAnimation (surface->texinfo->texture);

//
// see if the cache holds apropriate data
//
	cache = surface->cachespots[miplevel];

#ifdef ASM486_SURFACE_CACHE_CHECK
	if (D_CacheSurfaceCheckAndPrepare_asm486 (surface, tex, &r_drawsurf,
			d_lightstylevalue, cache))
#else
	// Hit on tex/lightadj with a clean sticky dlight bit.  Unmarked frames
	// return immediately; phantom marks probe the discrete sample walk and
	// skip the rebuild when no sample would be lit (same lit output).
	if (cache && !cache->dlight
			&& cache->texture == tex
			&& cache->lightadj[0] == d_lightstylevalue[surface->styles[0]]
			&& (surface->styles[1] == 255
				 || (cache->lightadj[1] == d_lightstylevalue[surface->styles[1]]
				  && cache->lightadj[2] == d_lightstylevalue[surface->styles[2]]
				  && cache->lightadj[3] == d_lightstylevalue[surface->styles[3]]))
			&& (surface->dlightframe != r_framecount
				 || !D_CACHE_SURFACE_PROBE_DLIGHT (surface)))
#endif
	{
#ifdef PROFILE486
		if (bench486_surface_cache_profile_active)
		{
			bench486_surface_cache_now = Sys_FloatTime ();
			bench486_surface_cache_elapsed = bench486_surface_cache_now -
					bench486_surface_cache_start;
			bench486_surface_cache_hits++;
			bench486_surface_cache_hit_seconds +=
					bench486_surface_cache_elapsed;
			bench486_surface_cache_seconds +=
					bench486_surface_cache_elapsed;
		}
#endif
		BENCH486_PROFILE_LEAVE ();
		return cache;
	}

#ifdef PROFILE486
	if (bench486_surface_cache_profile_active)
	{
		bench486_surface_cache_now = Sys_FloatTime ();
		bench486_surface_cache_miss_check_seconds +=
				bench486_surface_cache_now - bench486_surface_cache_start;
		bench486_surface_cache_rebuild_start =
				bench486_surface_cache_now;
		bench486_surface_cache_rebuilds++;
		if (d_lightstylevalue[surface->styles[0]] == 256 &&
			d_lightstylevalue[surface->styles[1]] == 256 &&
			d_lightstylevalue[surface->styles[2]] == 256 &&
			d_lightstylevalue[surface->styles[3]] == 256)
			bench486_surface_cache_immutable_rebuilds++;
	}
#endif

#ifdef ASM486_SURFACE_CACHE_CHECK
	cache_created = 0;
#endif

#ifndef ASM486_SURFACE_CACHE_CHECK
	r_drawsurf.texture = tex;
	r_drawsurf.lightadj[0] = d_lightstylevalue[surface->styles[0]];
	r_drawsurf.lightadj[1] = d_lightstylevalue[surface->styles[1]];
	r_drawsurf.lightadj[2] = d_lightstylevalue[surface->styles[2]];
	r_drawsurf.lightadj[3] = d_lightstylevalue[surface->styles[3]];
#endif

//
// determine shape of surface
//
#ifdef ASM486_SURFACE_CACHE_CHECK
	D_CacheSurfaceSetup_asm486 (surface, miplevel, &r_drawsurf);
#else
	r_drawsurf.surfmip = miplevel;
	r_drawsurf.surfwidth = surface->extents[0] >> miplevel;
	r_drawsurf.rowbytes = r_drawsurf.surfwidth;
	r_drawsurf.surfheight = surface->extents[1] >> miplevel;
#endif
	
//
// allocate memory if needed
//
	if (!cache)     // if a texture just animated, don't reallocate it
	{
#ifdef PROFILE486
		if (bench486_surface_cache_profile_active)
			bench486_surface_cache_alloc_start = Sys_FloatTime ();
#endif
		cache = D_SCAlloc (r_drawsurf.surfwidth,
						   r_drawsurf.surfwidth * r_drawsurf.surfheight);
#ifdef PROFILE486
		if (bench486_surface_cache_profile_active)
			bench486_surface_cache_alloc_seconds += Sys_FloatTime () -
					bench486_surface_cache_alloc_start;
#endif
#ifdef ASM486_SURFACE_CACHE_CHECK
		cache_created = 1;
#else
		surface->cachespots[miplevel] = cache;
		cache->owner = &surface->cachespots[miplevel];
#endif
	}

#ifdef ASM486_SURFACE_CACHE_CHECK
	D_CacheSurfaceAttach_asm486 (surface, miplevel, cache, &r_drawsurf,
			cache_created);
#else
	r_drawsurf.surfdat = (pixel_t *)cache->data;
#endif

#ifdef ASM486_SURFACE_CACHE_CHECK
	D_CacheSurfaceStoreTags_asm486 (cache, &r_drawsurf);
#else
	cache->texture = r_drawsurf.texture;
	cache->lightadj[0] = r_drawsurf.lightadj[0];
	cache->lightadj[1] = r_drawsurf.lightadj[1];
	cache->lightadj[2] = r_drawsurf.lightadj[2];
	cache->lightadj[3] = r_drawsurf.lightadj[3];
#endif

//
// draw and light the surface texture
//
#ifdef PROFILE486
	if (bench486_surface_cache_profile_active)
		bench486_surface_cache_draw_start = Sys_FloatTime ();
#endif
#ifdef ASM486_SURFACE_CACHE_CHECK
	D_CacheSurfaceDispatch_asm486 (surface, &r_drawsurf);
#else
	r_drawsurf.surf = surface;
	c_surf++;
	R_DrawSurface ();
#endif
#ifdef PROFILE486
	if (bench486_surface_cache_profile_active)
	{
		bench486_surface_cache_draw_calls++;
		bench486_surface_cache_draw_seconds += Sys_FloatTime () -
				bench486_surface_cache_draw_start;
	}
#endif

	// Sticky dlight bit only if a sample was actually lit; phantom marks
	// must not force a rebuild next frame when the cache already matches.
	#ifdef ASM486_SURFACE_CACHE_CHECK
	D_CacheSurfaceSetDlight_asm486 (cache, surface->dlightframe,
			r_framecount, r_dlight_contributed);
	#else
	if (surface->dlightframe == r_framecount)
		cache->dlight = r_dlight_contributed;
	else
		cache->dlight = 0;
	#endif

#ifdef PROFILE486
	if (bench486_surface_cache_profile_active)
	{
		bench486_surface_cache_now = Sys_FloatTime ();
		bench486_surface_cache_elapsed = bench486_surface_cache_now -
				bench486_surface_cache_start;
		bench486_surface_cache_seconds += bench486_surface_cache_elapsed;
		bench486_surface_cache_rebuild_seconds +=
				bench486_surface_cache_now -
				bench486_surface_cache_rebuild_start;
	}
#endif
	BENCH486_PROFILE_LEAVE ();

	return surface->cachespots[miplevel];
}
#endif

#if defined(PROFILE486) && defined(ASM486_SURFACE_CACHE_CHECK)
typedef struct
{
	double start;
	double rebuild_start;
	double alloc_start;
	double draw_start;
	int active;
} d_cache_surface_profile_context_t;

void D_CacheSurfaceProfileBegin_asm486 (void *opaque_context)
{
	d_cache_surface_profile_context_t *context;

	context = (d_cache_surface_profile_context_t *)opaque_context;
	context->active = bench486_profile_frame_active;
	BENCH486_PROFILE_ENTER (BENCH486_PROFILE_SURFACE_CACHE);
	if (context->active)
		context->start = Sys_FloatTime ();
}

void D_CacheSurfaceProfileHit_asm486 (void *opaque_context)
{
	d_cache_surface_profile_context_t *context;
	double now, elapsed;

	context = (d_cache_surface_profile_context_t *)opaque_context;
	if (context->active)
	{
		now = Sys_FloatTime ();
		elapsed = now - context->start;
		bench486_surface_cache_hits++;
		bench486_surface_cache_hit_seconds += elapsed;
		bench486_surface_cache_seconds += elapsed;
	}
	BENCH486_PROFILE_LEAVE ();
}

void D_CacheSurfaceProfileMiss_asm486 (void *opaque_context,
		msurface_t *surface)
{
	d_cache_surface_profile_context_t *context;
	byte *style;
	int i, immutable;
	double now;

	context = (d_cache_surface_profile_context_t *)opaque_context;
	if (!context->active)
		return;
	now = Sys_FloatTime ();
	bench486_surface_cache_miss_check_seconds += now - context->start;
	context->rebuild_start = now;
	bench486_surface_cache_rebuilds++;
	style = surface->styles;
	immutable = 1;
	for (i=0 ; i<MAXLIGHTMAPS ; i++, style++)
		if (d_lightstylevalue[*style] != 256)
			immutable = 0;
	if (immutable)
		bench486_surface_cache_immutable_rebuilds++;
}

void D_CacheSurfaceProfileAllocBegin_asm486 (void *opaque_context)
{
	d_cache_surface_profile_context_t *context;

	context = (d_cache_surface_profile_context_t *)opaque_context;
	if (context->active)
		context->alloc_start = Sys_FloatTime ();
}

void D_CacheSurfaceProfileAllocEnd_asm486 (void *opaque_context)
{
	d_cache_surface_profile_context_t *context;

	context = (d_cache_surface_profile_context_t *)opaque_context;
	if (context->active)
		bench486_surface_cache_alloc_seconds += Sys_FloatTime () -
				context->alloc_start;
}

void D_CacheSurfaceProfileDrawBegin_asm486 (void *opaque_context)
{
	d_cache_surface_profile_context_t *context;

	context = (d_cache_surface_profile_context_t *)opaque_context;
	if (context->active)
		context->draw_start = Sys_FloatTime ();
}

void D_CacheSurfaceProfileDrawEnd_asm486 (void *opaque_context)
{
	d_cache_surface_profile_context_t *context;

	context = (d_cache_surface_profile_context_t *)opaque_context;
	if (context->active)
	{
		bench486_surface_cache_draw_calls++;
		bench486_surface_cache_draw_seconds += Sys_FloatTime () -
				context->draw_start;
	}
}

void D_CacheSurfaceProfileFinish_asm486 (void *opaque_context)
{
	d_cache_surface_profile_context_t *context;
	double now;

	context = (d_cache_surface_profile_context_t *)opaque_context;
	if (context->active)
	{
		now = Sys_FloatTime ();
		bench486_surface_cache_seconds += now - context->start;
		bench486_surface_cache_rebuild_seconds +=
				now - context->rebuild_start;
	}
	BENCH486_PROFILE_LEAVE ();
}
#endif

#ifdef BENCH486
void *D_CacheSurfaceHit_C (void *cache_ptr, int surface_dlightframe,
		int frame, void *texture, int *lightadj, void *surface_ptr)
{
	surfcache_t *cache;
	msurface_t *surface;

	cache = (surfcache_t *)cache_ptr;
	surface = (msurface_t *)surface_ptr;
	if (cache && !cache->dlight
			&& cache->texture == (texture_t *)texture
			&& cache->lightadj[0] == lightadj[0]
			&& (surface->styles[1] == 255
				 || (cache->lightadj[1] == lightadj[1]
				  && cache->lightadj[2] == lightadj[2]
				  && cache->lightadj[3] == lightadj[3]))
			&& (surface_dlightframe != frame ||
					!R_DlightContributes (surface)))
		return cache_ptr;
	return NULL;
}
#endif

#if defined(BENCH486) && defined(ASM486_SURFACE_CACHE_CHECK)
void D_CacheSurfaceSetup_C (msurface_t *surface, int miplevel,
		drawsurf_t *drawsurf)
{
	drawsurf->surfmip = miplevel;
	drawsurf->surfwidth = surface->extents[0] >> miplevel;
	drawsurf->rowbytes = drawsurf->surfwidth;
	drawsurf->surfheight = surface->extents[1] >> miplevel;
}

void D_CacheSurfaceKeys_C (msurface_t *surface, texture_t *texture,
		drawsurf_t *drawsurf, int *lightstylevalues)
{
	int i;

	drawsurf->texture = texture;
	for (i=0 ; i<MAXLIGHTMAPS ; i++)
		drawsurf->lightadj[i] = lightstylevalues[surface->styles[i]];
}

void D_CacheSurfaceStoreTags_C (surfcache_t *cache, drawsurf_t *drawsurf)
{
	int i;

	cache->texture = drawsurf->texture;
	for (i=0 ; i<MAXLIGHTMAPS ; i++)
		cache->lightadj[i] = drawsurf->lightadj[i];
}

void D_CacheSurfaceAttach_C (msurface_t *surface, int miplevel,
		surfcache_t *cache, drawsurf_t *drawsurf, int cache_created)
{
	if (cache_created)
	{
		surface->cachespots[miplevel] = cache;
		cache->owner = &surface->cachespots[miplevel];
	}
	drawsurf->surfdat = (pixel_t *)cache->data;
}

void D_CacheSurfaceSetDlight_C (surfcache_t *cache,
		int surface_dlightframe, int frame, int contributed)
{
	if (surface_dlightframe == frame)
		cache->dlight = contributed;
	else
		cache->dlight = 0;
}
#endif



/* Independent pinned C algorithms are test-only. */
#if defined(BENCH486) && defined(ASM486_DRAWING_DRIVER)
void D_FlushCaches_Driver_C (void)
{
	surfcache_t     *c;

	if (!sc_base)
		return;

	for (c = sc_base ; c ; c = c->next)
	{
		if (c->owner)
			*c->owner = NULL;
	}

	sc_rover = sc_base;
	sc_base->next = NULL;
	sc_base->owner = NULL;
	sc_base->size = sc_size;
}
#endif
