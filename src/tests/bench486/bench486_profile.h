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
// bench486_profile.h -- benchmark-only profiling interface

#ifndef BENCH486_PROFILE_H
#define BENCH486_PROFILE_H

#ifdef PROFILE486
typedef enum
{
	BENCH486_PROFILE_FRAME = 0,
	BENCH486_PROFILE_INPUT,
	BENCH486_PROFILE_GAME,
	BENCH486_PROFILE_SCREEN,
	BENCH486_PROFILE_VIEW,
	BENCH486_PROFILE_VIEW_LIGHTS,
	BENCH486_PROFILE_RENDERER,
	BENCH486_PROFILE_SETUP,
	BENCH486_PROFILE_VISIBILITY,
	BENCH486_PROFILE_EDGE_DRAWING,
BENCH486_PROFILE_WORLD_BSP,
// Coarse scope over R_RenderFace. The BSP walk and the per-face edge setup are
// otherwise indistinguishable inside world-bsp's self time. Low call count by
// construction (once per visible face), so the scope is affordable.
BENCH486_PROFILE_RENDERFACE,
BENCH486_PROFILE_EDGE_SCAN,
	BENCH486_PROFILE_SURFACES,
	BENCH486_PROFILE_SURFACE_CACHE,
	BENCH486_PROFILE_GRADIENTS,
	BENCH486_PROFILE_TEXTURE_SPANS,
	BENCH486_PROFILE_Z_SPANS,
	BENCH486_PROFILE_SKY_SPANS,
	BENCH486_PROFILE_TURBULENT_SPANS,
	BENCH486_PROFILE_SOLID_SPANS,
	BENCH486_PROFILE_BRUSH_ENTITIES,
	BENCH486_PROFILE_ENTITIES,
	BENCH486_PROFILE_SPRITES,
	BENCH486_PROFILE_ALIAS_MODEL,
	BENCH486_PROFILE_ALIAS_SETUP,
	BENCH486_PROFILE_ALIAS_TRANSFORM,
BENCH486_PROFILE_ALIAS_RASTER,
// Whole-triangle scope over the C glue. The four per-call C scopes below
// (LINESCAN_SETUP, EDGE_SETUP, SPAN_PACKAGE, STEP_MATH) are no longer emitted:
// at 100k-260k calls each they cost more in timer reads than they measured.
// They remain in the enum so older profile files still parse, and now report
// zero calls.
BENCH486_PROFILE_ALIAS_GLUE,
BENCH486_PROFILE_ALIAS_CALCGRADIENTS,
	BENCH486_PROFILE_ALIAS_LINESCAN_SETUP,
	BENCH486_PROFILE_ALIAS_SCAN_LEFT_EDGE,
	BENCH486_PROFILE_ALIAS_DRAW_SPANS,
	BENCH486_PROFILE_ALIAS_EDGE_SETUP,
	BENCH486_PROFILE_ALIAS_SPAN_PACKAGE,
	BENCH486_PROFILE_ALIAS_STEP_MATH,
	BENCH486_PROFILE_VIEWMODEL,
	BENCH486_PROFILE_PARTICLES,
	BENCH486_PROFILE_WARP,
	BENCH486_PROFILE_OVERLAY,
	BENCH486_PROFILE_PALETTE,
	BENCH486_PROFILE_PRESENT,
	BENCH486_PROFILE_AUDIO,
	BENCH486_PROFILE_SOUND_SPATIAL,
	BENCH486_PROFILE_SOUND_MIX,
	BENCH486_PROFILE_CD_AUDIO,
	BENCH486_PROFILE_SERVER,
	BENCH486_PROFILE_SERVER_CLIENTS,
	BENCH486_PROFILE_SERVER_PHYSICS,
	BENCH486_PROFILE_SERVER_MESSAGES,
	BENCH486_PROFILE_CLIENT_READ,
	BENCH486_PROFILE_QUAKEC,
	BENCH486_PROFILE_COLLISION,
	BENCH486_PROFILE_PHYSICS_STARTFRAME,
	BENCH486_PROFILE_PHYSICS_CLIENT,
	BENCH486_PROFILE_PHYSICS_PUSHER,
	BENCH486_PROFILE_PHYSICS_NONE,
	BENCH486_PROFILE_PHYSICS_FOLLOW,
	BENCH486_PROFILE_PHYSICS_NOCLIP,
	BENCH486_PROFILE_PHYSICS_STEP,
	BENCH486_PROFILE_PHYSICS_TOSS,
	BENCH486_PROFILE_COLLISION_WORLD,
	BENCH486_PROFILE_COLLISION_BOUNDS,
	BENCH486_PROFILE_COLLISION_LINKS,
	BENCH486_PROFILE_NODE_COUNT
} bench486_profile_node_id_t;

extern int bench486_profile_frame_active;
extern int bench486_profile_coarse_active;
extern unsigned long bench486_profile_frames;
extern double bench486_frame_seconds;
extern double bench486_render_seconds;
extern double bench486_visibility_seconds;
extern double bench486_world_seconds;
extern double bench486_edge_scan_seconds;
extern double bench486_surface_cache_seconds;
extern double bench486_surface_cache_hit_seconds;
extern double bench486_surface_cache_miss_check_seconds;
extern double bench486_surface_cache_rebuild_seconds;
extern double bench486_surface_cache_dlight_probe_seconds;
extern double bench486_surface_cache_draw_seconds;
extern double bench486_surface_cache_alloc_seconds;
extern double bench486_surface_cache_lightmap_seconds;
extern double bench486_surface_cache_block_seconds;
extern double bench486_surface_cache_mip_seconds[4];
extern unsigned long bench486_surface_cache_mip_calls[4];
extern unsigned long bench486_surface_cache_mip_blocks[4];
extern unsigned long bench486_surface_cache_flat_blocks;
extern unsigned long bench486_surface_cache_horizontal_flat_blocks;
extern unsigned long bench486_surface_cache_vertical_flat_blocks;
extern unsigned long bench486_surface_cache_flat_blocks_per_mip[4];
extern unsigned long bench486_surface_cache_horizontal_flat_per_mip[4];
extern unsigned long bench486_surface_cache_mip_blocks_flat[4];
extern double bench486_span_draw_seconds;
extern double bench486_sound_seconds;
extern double bench486_framebuffer_seconds;
extern unsigned long bench486_alias_models;
extern unsigned long bench486_alias_vertices;
extern unsigned long bench486_surface_count;
extern unsigned long bench486_surface_drawn;
extern unsigned long bench486_texture_span_count;
extern unsigned long bench486_texture_span_pixels;
extern unsigned long bench486_texture_span_segments;
extern unsigned long bench486_texture_span_buckets[5];
extern unsigned long bench486_texture_widths[17];
extern unsigned long bench486_texture_final_lengths[17];
extern unsigned long bench486_texture_full_tzero;
extern unsigned long bench486_texture_full_tdelta_zero;
extern unsigned long bench486_texture_full_tfrac_zero;
extern unsigned long bench486_texture_full_sfrac_zero;
extern unsigned long bench486_texture_full_sone;
extern unsigned long bench486_texture_full_exact;
extern unsigned long bench486_texture_final_exact;
extern unsigned long bench486_texture_full_row_eligible;
extern unsigned long bench486_texture_full_row_fast;
extern unsigned long bench486_texture_tail_tstep_zero_segments;
extern unsigned long bench486_texture_tail_tstep_zero_samples;
extern unsigned long bench486_span_segments;
extern unsigned long bench486_zspan_pixels;
extern unsigned long bench486_zspan_spans;
extern unsigned long bench486_lm_single_texels;
extern unsigned long bench486_lm_fused_texels;
extern unsigned long bench486_lm_fused_maps[5];
extern unsigned long bench486_span_unit_stride_segments;
extern unsigned long bench486_span_unit_stride_pixels;
extern unsigned long bench486_surf8_flat_rows;
extern unsigned long bench486_surf8_flat_dh_moved;
extern unsigned long bench486_gradient_calls;
extern unsigned long bench486_solid_span_count;
extern unsigned long bench486_memset_calls;
extern unsigned long bench486_memset_bytes;
extern unsigned long bench486_memset_aligned_calls;
extern unsigned long bench486_memcpy_calls;
extern unsigned long bench486_memcpy_bytes;
extern unsigned long bench486_memcpy_same_alignment_calls;
extern unsigned long bench486_line_setup_calls;
extern unsigned long bench486_axis_cache_hits;
extern unsigned long bench486_axis_cache_misses;
extern unsigned long bench486_bsp_nodes;
extern unsigned long bench486_bsp_solid_culls;
extern unsigned long bench486_bsp_visibility_culls;
extern unsigned long bench486_bsp_leaf_nodes;
extern unsigned long bench486_bsp_internal_nodes;
extern unsigned long bench486_bsp_surface_tests;
extern unsigned long bench486_scanlines;
extern unsigned long bench486_edge_insert_calls;
extern unsigned long bench486_edge_remove_calls;
extern unsigned long bench486_edge_step_calls;
extern unsigned long bench486_span_flushes;
extern unsigned long bench486_edge_insert_iters;
extern unsigned long bench486_edge_remove_iters;
extern unsigned long bench486_edge_step_iters;
extern unsigned long bench486_edge_pushback_iters;
extern unsigned long bench486_edge_sort_iters;
extern unsigned long bench486_edge_emit_blocks;
extern unsigned long bench486_edge_genspans_edges;
extern unsigned long bench486_edge_bmodel_zsort;
extern unsigned long bench486_edge_trailing_calls;
extern unsigned long bench486_edge_leading;
extern unsigned long bench486_edge_bmodel_leading;
extern unsigned long bench486_edge_bmodel_trailing;
extern unsigned long bench486_edge_insert_exit;
extern unsigned long bench486_edge_newtop;
extern unsigned long bench486_edge_xldone;
extern unsigned long bench486_edge_lastspan;
extern unsigned long bench486_edge_reset_iters;
extern unsigned long bench486_renderface_calls;
extern unsigned long bench486_renderface_general_edges;
extern unsigned long bench486_renderface_emitted;
#ifdef ASM486_RENDERFACE_PROBE
extern unsigned long bench486_rf_probe_sink;
#endif
extern unsigned long bench486_surface_span_count;
extern unsigned long bench486_surface_span_pixels;
extern unsigned long bench486_surface_span_segments;
extern unsigned long bench486_surface_sky_count;
extern unsigned long bench486_surface_background_count;
extern unsigned long bench486_surface_turbulent_count;
extern unsigned long bench486_surface_normal_count;
extern unsigned long bench486_surface_solid_count;
extern unsigned long bench486_present_rects;
extern unsigned long bench486_present_pixels;
extern unsigned long bench486_sound_update_calls;
extern unsigned long bench486_sound_mix_calls;
extern double bench486_alias_seconds;
extern double bench486_surface_seconds;
extern double bench486_turbulent_seconds;
extern unsigned long bench486_particle_count;
extern double bench486_particle_seconds;
extern unsigned long bench486_zone_malloc_calls;
extern unsigned long bench486_zone_malloc_bytes;
extern unsigned long bench486_zone_check_calls;
extern unsigned long bench486_zone_check_blocks;
extern unsigned long bench486_zone_scan_iterations;
extern unsigned long bench486_zone_splits;
extern unsigned long bench486_zone_coalesces;
extern unsigned long bench486_zone_failed_allocations;
extern unsigned long bench486_hunk_low_calls;
extern unsigned long bench486_hunk_low_bytes;
extern unsigned long bench486_hunk_high_calls;
extern unsigned long bench486_hunk_high_bytes;
extern unsigned long bench486_cache_checks;
extern unsigned long bench486_cache_hits;
extern unsigned long bench486_cache_misses;
extern unsigned long bench486_cache_lru_relinks;
extern unsigned long bench486_cache_allocations;
extern unsigned long bench486_cache_frees;
extern unsigned long bench486_cache_evictions;
extern unsigned long bench486_cache_tryalloc_scans;
extern unsigned long bench486_cache_tryalloc_failures;
extern unsigned long bench486_cache_moves;
extern unsigned long bench486_cache_move_bytes;

void Zone_ResetProfileCounters (void);

void Bench486ProfileEnter (int node);
void Bench486ProfileLeave (void);
void Bench486ProfileWork (int node, unsigned long items,
		unsigned long bytes);
void Bench486ProfileClipVertexFrameStart (void);

#define BENCH486_PROFILE_ENTER(node) Bench486ProfileEnter (node)
#define BENCH486_PROFILE_LEAVE() Bench486ProfileLeave ()
#define BENCH486_PROFILE_WORK(node, items, bytes) \
	Bench486ProfileWork ((node), (items), (bytes))
#else
#define BENCH486_PROFILE_ENTER(node) ((void)0)
#define BENCH486_PROFILE_LEAVE() ((void)0)
#define BENCH486_PROFILE_WORK(node, items, bytes) ((void)0)
#endif

#ifdef BENCH486
#define BENCH486_TIMEDEMO_MAX_FRAMES 8192

void Bench486ResetTimedemoStats (void);
void Bench486BeginTimedemoStats (void);
void Bench486TimedemoFrameStart (void);
void Bench486TimedemoFrameEnd (void);
void Bench486GameplayFrameStart (void);
void Bench486GameplayFrameEnd (void);
void Bench486ResetTimedemoFrameChecksums (int enabled);
void Bench486TimedemoFrameChecksumRecord (void);
void Bench486RecordBlobExplosionEvent (void);
void Bench486RecordLavaSplashEvent (void);
void Bench486RecordTeleportSplashEvent (void);
void Bench486RecordRunParticleEffectEvent (void);
void Bench486RecordSvcDamageEvent (void);
void Bench486FinishTimedemoStats (int timedemo_frames);
void Bench486WriteTimedemoStats (int report_handle, int timedemo_frames,
		double timedemo_seconds);
#endif

#endif /* BENCH486_PROFILE_H */
