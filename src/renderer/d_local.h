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
// d_local.h:  private rasterization driver defs

#include "renderer/r_shared.h"

//
// TODO: fine-tune this; it's based on providing some overage even if there
// is a 2k-wide scan, with subdivision every 8, for 256 spans of 12 bytes each
//
#define SCANBUFFERPAD		0x1000

#define R_SKY_SMASK	0x007F0000
#define R_SKY_TMASK	0x007F0000

#ifdef ASM486_SKY_SPAN
void D_SkyDrawPixels_asm486 (byte *source, byte *dest, int count,
		fixed16_t s, fixed16_t t, fixed16_t sstep, fixed16_t tstep);
void D_SkyUVToST_asm486 (int u, int v, float sky_temp,
		float skytime_offset, fixed16_t *s, fixed16_t *t);
#ifdef BENCH486
void D_Sky_uv_To_st_C (int u, int v, float sky_temp,
		float skytime_offset, fixed16_t *s, fixed16_t *t);
void D_DrawSkyScans8_C_Bench (espan_t *pspan);
#endif
#endif

#ifdef ASM486_WARP_SCREEN
void D_WarpBuildTables_asm486 (byte **rowptr, int *column,
		byte *viewbase, int screenwidth, int rowcount, int colcount,
		int h, int w, int hdenominator, int wdenominator,
		int x_origin, float hratio, float wratio);
void D_WarpPixels_asm486 (byte *dest, byte **rowptr, int *column,
		int *turb, int width, int height, int rowbytes);
#endif

void D_DrawSolidSurface (surf_t *surf, int color);
#ifdef ASM486_SOLID_SURFACE
#ifdef BENCH486
void D_DrawSolidSurface_C (surf_t *surf, int color);
#endif
#endif

#define DS_SPAN_LIST_END	-128

// The low-memory guard in vid_vga.c subtracts this same constant from
// tbuffersize and adds it straight back, so at 320x200 it cancels and the
// guard stays memsize - framebuffer + 192K. Raising this value therefore does
// not weaken the guard on a small machine. 2400 KB measured 0.0634% faster
// than 1800 KB with checksum 1047377823 on every run; 6000 KB added only a
// further 0.015% for 2.5x the memory.
#define SURFCACHE_SIZE_AT_320X200	2400*1024

typedef struct surfcache_s
{
	struct surfcache_s	*next;
	struct surfcache_s 	**owner;		// NULL is an empty chunk of memory
	int					lightadj[MAXLIGHTMAPS]; // checked for strobe flush
	int					dlight;
	int					size;		// including header
	unsigned			width;
#ifdef DEBUG
	unsigned			height;		// diagnostic builds only
#endif
	float				mipscale;
	struct texture_s	*texture;	// checked for animating textures
	// This is a variable-size tail.  Keep sizeof(surfcache_t) equal to the
	// header used by D_SCAlloc instead of charging a four-byte placeholder.
	byte				data[0];	// width*height elements
} surfcache_t;

// !!! if this is changed, it must be changed in asm_draw.h too !!!
typedef struct sspan_s
{
	int				u, v, count;
} sspan_t;

extern cvar_t	d_subdiv16;

extern float	scale_for_mip;

extern qboolean		d_roverwrapped;
extern surfcache_t	*sc_rover;
extern surfcache_t	*d_initial_rover;

#ifdef PROFILE486
extern unsigned long bench486_surface_cache_hits;
extern unsigned long bench486_surface_cache_rebuilds;
extern unsigned long bench486_surface_cache_immutable_rebuilds;
extern unsigned long bench486_surface_cache_dlight_probes;
extern unsigned long bench486_surface_cache_dlight_contributing_probes;
extern unsigned long bench486_surface_cache_draw_calls;
extern unsigned long bench486_surface_cache_allocations;
extern unsigned long bench486_surface_cache_wraps;
extern unsigned long bench486_surface_cache_invalidated_blocks;
extern unsigned long bench486_surface_cache_requested_bytes;
extern unsigned long bench486_surface_cache_reclaimed_bytes;
extern unsigned long bench486_surface_cache_thrash_frames;
#endif

extern float	d_sdivzstepu, d_tdivzstepu, d_zistepu;
extern float	d_sdivzstepv, d_tdivzstepv, d_zistepv;
extern float	d_sdivzorigin, d_tdivzorigin, d_ziorigin;

#ifdef ASM486_SURFACE_GRADIENTS
extern int d_gradient_miplevel;
extern float d_mipscale_values[4];
extern float d_mip_xscale[4];
extern float d_mip_yscale[4];
extern vec3_t transformed_modelorg;
extern int d_texaxis_cache_mask;
void D_CalcGradients_asm486 (msurface_t *pface);
#ifdef BENCH486
void D_CalcGradients_C (msurface_t *pface);
#endif
#endif

fixed16_t	sadjust, tadjust;
fixed16_t	bbextents, bbextentt;


void D_DrawSpans8 (espan_t *pspans);
/* Public prototypes also cover builds that exclude the C entry definitions. */
void D_CalcGradients (msurface_t *pface);
void D_DrawSurfacesCalcGradients_asm486 (msurface_t *pface);
void D_PolysetUpdateTables (void);
void D_RasterizeAliasPolySmooth (void);
void D_PolysetSetEdgeTable (void);
void D_PolysetCalcGradients (int skinwidth);
void D_PolysetCalcGradients_C (int skinwidth);
void D_PolysetCalcGradients_asm486 (int skinwidth);
void D_PolysetSetUpForLineScan (fixed8_t startvertu, fixed8_t startvertv,
		fixed8_t endvertu, fixed8_t endvertv);
void D_PolysetSetUpForLineScan_C (fixed8_t startvertu, fixed8_t startvertv,
		fixed8_t endvertu, fixed8_t endvertv);
void D_PolysetSetEdgeTable_C (void);
void D_PolysetUpdateTables_C (void);
#if id386
void D_PolysetSetUpForLineScan_asm486 (fixed8_t startvertu,
		fixed8_t startvertv, fixed8_t endvertu, fixed8_t endvertv);
void D_PolysetSetEdgeTable_asm486 (void);
void D_PolysetUpdateTables_asm486 (void);
#endif
#ifdef BENCH486
extern int r_p0[6], r_p1[6], r_p2[6], d_xdenom, d_xdenom_int;
extern byte *skintable[480], *skinstart;
extern int skinwidth;
void *D_PolysetGetEdgeTableForBench (void);
void D_PolysetSetEdgeTableForBench (void *table);
extern int a_sstepxfrac, a_tstepxfrac, a_ststepxwhole;
extern int r_lstepx, r_lstepy, r_sstepx, r_sstepy;
extern int r_tstepx, r_tstepy, r_zistepx, r_zistepy;
extern unsigned int single_cw __asm__("single_cw");
#endif
void D_DrawSpans16 (espan_t *pspans);
void D_DrawZSpans (espan_t *pspans);
#ifdef BENCH486
void D_DrawZSpans_C (espan_t *pspans);
#endif
void Turbulent8 (espan_t *pspan);
#if defined(ASM486_TURBULENT_SCAN) && defined(BENCH486)
void Turbulent8_C (espan_t *pspan);
#endif
void D_SpriteDrawSpans (sspan_t *pspan);
void D_DrawSprite_C (void);
void D_DrawSprite_asm486 (int nump, emitpoint_t *pverts, int frame_width,
		int frame_height, byte *frame_pixels);
void D_SpriteScanLeftEdge_C (void);
void D_SpriteScanLeftEdge_asm486 (sspan_t *spans, int minindex,
		int maxindex, int nump, emitpoint_t *pverts);
#ifdef BENCH486
void D_SpriteScanLeftEdgeGetState (sspan_t **spans, int *min, int *max);
void D_SpriteScanLeftEdgeSetState (sspan_t *spans, int min, int max);
#endif
void D_SpriteScanRightEdge_C (void);
void D_SpriteScanRightEdge_asm486 (sspan_t *spans, int minindex,
		int maxindex, int nump, emitpoint_t *pverts, float xleft,
		float xright, float ytop, float ybottom);
#ifdef BENCH486
void D_SpriteScanRightEdgeGetState (sspan_t **spans, int *min, int *max,
		float *xleft, float *xright, float *ytop, float *ybottom);
void D_SpriteScanRightEdgeSetState (sspan_t *spans, int min, int max,
		float xleft, float xright, float ytop, float ybottom);
#endif
void D_SpriteCalculateGradients_C (void);
void D_SpriteCalculateGradients_asm486 (int height);
extern int sprite_height, minindex, maxindex;
extern sspan_t *sprite_spans;
#ifdef BENCH486
int D_SpriteCalculateGradientsSetHeight (int height);
#endif

void D_DrawSkyScans8 (espan_t *pspan);
void D_DrawSkyScans16 (espan_t *pspan);

void R_ShowSubDiv (void);
void (*prealspandrawer)(void);
surfcache_t	*D_CacheSurface (msurface_t *surface, int miplevel);
surfcache_t	*D_SCAlloc (int width, int size);
#if defined(BENCH486) && (defined(ASM486_SURFACE_CACHE_CHECK) || defined(ASM486_DRAWING_DRIVER))
extern int sc_size;
extern surfcache_t *sc_base;
#endif
#ifdef ASM486_SURFACE_CACHE_CHECK
surfcache_t *D_SCAlloc_asm486 (int width, int size);
#ifdef BENCH486
surfcache_t *D_SCAlloc_C (int width, int size);
surfcache_t *D_CacheSurface_C (msurface_t *surface, int miplevel);
int D_SurfaceCacheForRes_C (int width, int height);
void D_InitCaches_C (void *buffer, int size);
void D_FlushCaches_C (void);
#endif
void D_CacheSurfaceSetup_asm486 (msurface_t *surface, int miplevel,
		drawsurf_t *drawsurf);
void D_CacheSurfaceKeys_asm486 (msurface_t *surface, texture_t *texture,
		drawsurf_t *drawsurf, int *lightstylevalues);
surfcache_t *D_CacheSurfaceCheckAndPrepare_asm486 (msurface_t *surface,
		texture_t *texture, drawsurf_t *drawsurf, int *lightstylevalues,
		surfcache_t *cache);
void D_CacheSurfaceStoreTags_asm486 (surfcache_t *cache,
		drawsurf_t *drawsurf);
void D_CacheSurfaceAttach_asm486 (msurface_t *surface, int miplevel,
		surfcache_t *cache, drawsurf_t *drawsurf, int cache_created);
void D_CacheSurfaceDispatch_asm486 (msurface_t *surface,
		drawsurf_t *drawsurf);
void D_CacheSurfaceSetDlight_asm486 (surfcache_t *cache,
		int surface_dlightframe, int frame, int contributed);
#ifdef PROFILE486
void D_CacheSurfaceProfileBegin_asm486 (void *context);
void D_CacheSurfaceProfileHit_asm486 (void *context);
void D_CacheSurfaceProfileMiss_asm486 (void *context,
		msurface_t *surface);
void D_CacheSurfaceProfileAllocBegin_asm486 (void *context);
void D_CacheSurfaceProfileAllocEnd_asm486 (void *context);
void D_CacheSurfaceProfileDrawBegin_asm486 (void *context);
void D_CacheSurfaceProfileDrawEnd_asm486 (void *context);
void D_CacheSurfaceProfileFinish_asm486 (void *context);
#endif
#ifdef BENCH486
void D_CacheSurfaceSetup_C (msurface_t *surface, int miplevel,
		drawsurf_t *drawsurf);
void D_CacheSurfaceKeys_C (msurface_t *surface, texture_t *texture,
		drawsurf_t *drawsurf, int *lightstylevalues);
void D_CacheSurfaceStoreTags_C (surfcache_t *cache, drawsurf_t *drawsurf);
void D_CacheSurfaceAttach_C (msurface_t *surface, int miplevel,
		surfcache_t *cache, drawsurf_t *drawsurf, int cache_created);
void D_CacheSurfaceSetDlight_C (surfcache_t *cache,
		int surface_dlightframe, int frame, int contributed);
#endif
#endif

extern int D_MipLevelForScale (float scale);

#if id386
extern void D_PolysetAff8Start (void);
extern void D_PolysetAff8End (void);
#endif

extern short *d_pzbuffer;
extern unsigned int d_zrowbytes, d_zwidth;

extern int	*d_pscantable;
extern int	d_scantable[MAXHEIGHT];

extern int	d_vrectx, d_vrecty, d_vrectright_particle, d_vrectbottom_particle;

extern int	d_y_aspect_shift, d_pix_min, d_pix_max, d_pix_shift;

extern pixel_t	*d_viewbuffer;

extern short	*zspantable[MAXHEIGHT];
extern pixel_t	*viewspantable[MAXHEIGHT];

extern int		d_minmip;
extern float	d_scalemip[3];

extern void (*d_drawspans) (espan_t *pspan);

#ifdef BENCH486
extern unsigned char	*r_turb_pbase, *r_turb_pdest;
extern fixed16_t		r_turb_s, r_turb_t, r_turb_sstep, r_turb_tstep;
extern int			*r_turb_turb;
extern int			r_turb_spancount;
void D_DrawTurbulent8Span_C (void);
void D_DrawTurbulent8Span_asm486 (void);
#endif
