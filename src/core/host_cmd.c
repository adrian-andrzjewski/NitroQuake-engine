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

#include <math.h>
#include <setjmp.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "common.h"
#include "host.h"
#include "bspfile.h"
#include "vid.h"
#include "video/vid_dos.h"
#include "sys.h"
#include "zone.h"
#include "mathlib.h"
#include "wad.h"
#include "draw.h"
#include "cvar.h"
#include "screen.h"
#include "net.h"
#include "protocol.h"
#include "cmd.h"
#include "sbar.h"
#include "sound.h"
#include "render.h"
#include "client.h"
#include "progs.h"
#include "server.h"
#include "model.h"
#include "d_iface.h"
#include "input.h"
#include "world.h"
#include "keys.h"
#include "console.h"
#include "view.h"
#include "menu.h"
#include "crc.h"
#include "cdaudio.h"
#include "nitroquake_version.h"
#include "tests/bench486/bench486_profile.h"
#include "tests/bench486/bench486_light_probe.h"

#ifdef BENCH486
#include "tests/bench486/bench486_sprite_hooks.h"
#include "tests/bench486/bench486_console.h"
#include "renderer/d_local.h"
#include "renderer/r_local.h"
extern float r_avertexnormals[][3];
extern void WritePCXfile (char *filename, byte *data, int width, int height,
		int rowbytes, byte *palette);
#if defined(ASM486_CACHE_CHECK_FIXTURE)
extern int Bench486CacheCheckCases (void);
#endif
#if defined(ASM486_CACHE_TRY_ALLOC_FIXTURE)
extern int Bench486CacheTryAllocCases (void);
#endif
#if defined(ASM486_CACHE_FREE_FIXTURE)
extern int Bench486CacheFreeCases (void);
#endif
#if defined(ASM486_CACHE_FREE_LOW_FIXTURE)
extern int Bench486CacheFreeLowCases (void);
#endif
#if defined(ASM486_CACHE_FREE_HIGH_FIXTURE)
extern int Bench486CacheFreeHighCases (void);
#endif
#if defined(ASM486_HUNK_MARK_RELEASE_FIXTURE)
extern int Bench486HunkMarkFreeCases (void);
#endif
#if defined(ASM486_HUNK_TEMP_ALLOC_FIXTURE)
extern int Bench486HunkTempAllocCases (void);
#endif
#if defined(ASM486_HUNK_NAMED_ALLOC_FIXTURE)
extern int Bench486HunkNamedAllocCases (void);
#endif
#if defined(ASM486_ZONE_HEAP_FIXTURE)
extern int Bench486ZoneHeapCases (void);
#endif
#if defined(ASM486_CACHE_ALLOC_FIXTURE)
extern int Bench486CacheAllocCases (void);
#endif
#if defined(ASM486_CACHE_MOVE_FIXTURE)
extern int Bench486CacheMoveCases (void);
#endif
#if defined(ASM486_VESA_COPY_RECTS_FIXTURE)
extern int Bench486VesaCopyRectsCases (void);
#endif
#if defined(ASM486_VESA_SWAP_BUFFERS_FIXTURE)
extern int Bench486VesaSwapBuffersCases (void);
#endif
#if defined(ASM486_VGA_PRESENTATION_FIXTURE)
extern int Bench486VgaPresentationCases (void);
#endif
#if defined(ASM486_VESA_LIFECYCLE_FIXTURE)
extern int Bench486VesaLifecycleCases (void);
#endif
#if defined(ASM486_VESA_WAIT_FIXTURE)
extern int Bench486VesaWaitCases (void);
#endif
#if defined(ASM486_VID_UPDATE_FIXTURE)
extern int Bench486VidUpdateCases (void);
extern int Bench486VidDirectRectCases (void);
extern int Bench486VidModeCases (void);
#endif
#if defined(ASM486_PLAYER_TRANSLATION_FIXTURE)
#include "tests/bench486/bench486_playertranslation.h"
#endif
#if defined(ASM486_VESA_PALETTE_FIXTURE)
#include "tests/bench486/bench486_vesapalette.h"
#endif
#if defined(ASM486_VESA_DEFAULT_MODE_FIXTURE)
#include "video/vid_dos.h"
#include "video/vid_vesa.h"
#include "tests/bench486/bench486_vesadefaultmode.h"
#endif
#if defined(ASM486_VESA_LIFECYCLE_FIXTURE)
#include "video/vid_dos.h"
#include "video/vid_vesa.h"
#include "video/asm_vesalifecycle.h"
#endif
#ifdef ASM486_FILLRECT
extern void D_FillRect_C (vrect_t *rect, int color);
#endif
#ifdef ASM486_ZPOINT
extern void D_DrawZPoint_C (void);
#endif
#ifdef ASM486_SKY_SPAN
extern void D_SkyDrawPixels_C_Bench (byte *source, byte *dest, int count,
		fixed16_t s, fixed16_t t, fixed16_t sstep, fixed16_t tstep);
#endif
#ifdef ASM486_WARP_SCREEN
extern void D_WarpTables_C_Bench (byte **rowptr, int *column,
		byte *viewbase, int screenwidth, int rowcount, int colcount,
		int h, int w, int hdenominator, int wdenominator,
		int x_origin, float hratio, float wratio);
extern void D_WarpPixels_C_Bench (byte *dest, byte **rowptr, int *column,
		int *turb, int width, int height, int rowbytes);
#endif
#endif

extern cvar_t	pausable;

int	current_skill;

void Mod_Print (void);

#ifdef BENCH486

static byte bench486_source[4104];
static byte bench486_dest[4104];
static byte bench486_expected[4104];
static volatile unsigned bench486_sink;
static int bench486_report_handle;
static int bench486_memory_failures;
static struct { byte before[32], pixels[320*200], after[32]; }
	bench486_sprite_c_color, bench486_sprite_a_color;
static struct { byte before[32]; short depth[320*200]; byte after[32]; }
	bench486_sprite_c_z, bench486_sprite_a_z;
#define bench486_sprite_draw_c_pixels bench486_sprite_c_color.pixels
#define bench486_sprite_draw_asm_pixels bench486_sprite_a_color.pixels
#define bench486_sprite_draw_c_depth bench486_sprite_c_z.depth
#define bench486_sprite_draw_asm_depth bench486_sprite_a_z.depth

#ifdef ASM486_SURFACE_DRAW
extern int lightleft, sourcesstep, blocksize, sourcetstep;
extern int lightdelta, lightdeltastep;
extern int lightright, lightleftstep, lightrightstep, blockdivshift;
extern unsigned blockdivmask;
extern void *prowdestbase;
extern unsigned char *pbasesource;
extern int surfrowbytes;
extern unsigned *r_lightptr;
extern int r_stepback, r_lightwidth, r_numhblocks, r_numvblocks;
extern unsigned char *r_source, *r_sourcemax;
extern unsigned blocklights[18*18];

typedef union
{
	texture_t align;
	byte storage[8192];
} bench486_surface_draw_texture_t;

typedef struct
{
	int lightleft, sourcesstep, blocksize, sourcetstep;
	int lightdelta, lightdeltastep;
	int lightright, lightleftstep, lightrightstep, blockdivshift;
	unsigned blockdivmask;
	int surfrowbytes, r_stepback, r_lightwidth;
	int r_numhblocks, r_numvblocks;
	unsigned *r_lightptr;
	unsigned char *pbasesource, *r_source, *r_sourcemax;
	int prowdest_offset;
} bench486_surface_draw_state_t;

static bench486_surface_draw_texture_t bench486_surface_draw_texture;
static msurface_t bench486_surface_draw_surface;
static model_t bench486_surface_draw_model;
static byte bench486_surface_draw_samples[48];
static byte bench486_surface_draw_c_pixels[4096];
static byte bench486_surface_draw_asm_pixels[4096];
static unsigned bench486_surface_draw_c_lights[18*18];
static unsigned bench486_surface_draw_saved_lights[18*18];
#endif

#ifdef PROFILE486
int bench486_profile_frame_active;
int bench486_profile_coarse_active;
static int bench486_profile_coarse_mode;
static int bench486_profile_filter[128];
static int bench486_profile_filter_depth;
unsigned long bench486_profile_frames;
double bench486_frame_seconds;
double bench486_render_seconds;
double bench486_visibility_seconds;
double bench486_world_seconds;
double bench486_edge_scan_seconds;
double bench486_surface_cache_seconds;
double bench486_surface_cache_hit_seconds;
double bench486_surface_cache_miss_check_seconds;
double bench486_surface_cache_rebuild_seconds;
double bench486_surface_cache_dlight_probe_seconds;
double bench486_surface_cache_draw_seconds;
double bench486_surface_cache_alloc_seconds;
double bench486_surface_cache_lightmap_seconds;
double bench486_surface_cache_block_seconds;
double bench486_surface_cache_mip_seconds[4];
unsigned long bench486_surface_cache_mip_calls[4];
unsigned long bench486_surface_cache_mip_blocks[4];
unsigned long bench486_surface_cache_flat_blocks;
unsigned long bench486_surface_cache_horizontal_flat_blocks;
unsigned long bench486_surface_cache_vertical_flat_blocks;
// The three counters above are summed over every mip level, which hides whether
// a level has enough flat blocks to be worth a specialised drawer. These are
// the same counts indexed by r_drawsurf.surfmip.
unsigned long bench486_surface_cache_flat_blocks_per_mip[4];
unsigned long bench486_surface_cache_horizontal_flat_per_mip[4];
unsigned long bench486_surface_cache_mip_blocks_flat[4];
double bench486_span_draw_seconds;
double bench486_sound_seconds;
double bench486_framebuffer_seconds;
unsigned long bench486_alias_models;
unsigned long bench486_alias_vertices;
unsigned long bench486_alias_occlusion_queries;
unsigned long bench486_alias_occlusion_culls;
unsigned long bench486_alias_occlusion_tiles;
unsigned long bench486_alias_occlusion_z_samples;
unsigned long bench486_surface_count;
unsigned long bench486_surface_drawn;
unsigned long bench486_surface_cache_hits;
unsigned long bench486_surface_cache_rebuilds;
unsigned long bench486_surface_cache_immutable_rebuilds;
unsigned long bench486_submodel_calls;
unsigned long bench486_submodel_faces;
unsigned long bench486_submodel_distinct_entities;
unsigned long bench486_submodel_entity_hits;
unsigned long bench486_submodel_table_overwrites;
void *bench486_submodel_entity_table[1024];
unsigned long bench486_bpoly_clip_edges;
unsigned long bench486_bpoly_adjacent_endpoint_hits;
unsigned long bench486_bpoly_plane_cache_hits;
unsigned long bench486_bpoly_plane_cache_misses;
unsigned long bench486_turbulent_rows;
unsigned long bench486_turbulent_chunks;
unsigned long bench486_turbulent_pixels;
unsigned long bench486_surface_cache_dlight_probes;
unsigned long bench486_surface_cache_dlight_contributing_probes;
unsigned long bench486_surface_cache_draw_calls;
unsigned long bench486_surface_cache_allocations;
unsigned long bench486_surface_cache_wraps;
unsigned long bench486_surface_cache_invalidated_blocks;
unsigned long bench486_surface_cache_requested_bytes;
unsigned long bench486_surface_cache_reclaimed_bytes;
unsigned long bench486_surface_cache_thrash_frames;
unsigned long bench486_texture_span_count;
unsigned long bench486_texture_span_same_row_links;
unsigned long bench486_texture_span_pixels;
unsigned long bench486_texture_span_segments;
unsigned long bench486_texture_span_buckets[5];
unsigned long bench486_texture_widths[17];
unsigned long bench486_texture_final_lengths[17];
// Premise counters for the world-bsp and edge-scan decomposition. These are
// plain increments with no timer reads, so they can be measured at any
// granularity; they exist to decide where a coarse scope is worth adding
// rather than to time anything.
unsigned long bench486_renderface_calls;
unsigned long bench486_renderface_general_edges;
unsigned long bench486_renderface_emitted;
unsigned long bench486_clipedge_calls;
unsigned long bench486_clipedge_plane_tests;
unsigned long bench486_clipedge_fully_clipped;
unsigned long bench486_emitcachededge_calls;
unsigned long bench486_clipvert_clips;
unsigned long bench486_clipvertex_world_endpoint_uses;
unsigned long bench486_clipvertex_world_unique_uses;
unsigned long bench486_clipvertex_seen_world[2048];
unsigned long bench486_clipvertex_plane_distance_uses[4];
unsigned long bench486_clipvertex_plane_distance_unique[4];
unsigned long bench486_clipvertex_plane_distance_hits[4];
unsigned long bench486_clipvertex_plane_seen[4][2048];
unsigned long bench486_clipvertex_plane_world_pair_uses[4];
unsigned long bench486_clipvertex_plane_lru_uses[4];
unsigned long bench486_clipvertex_plane_lru_hits[4];
static unsigned long bench486_clipvertex_plane_lru_vertex[4];
// PROFILE486-only hit-rate model; these tables do not cache render distances.
#define BENCH486_CLIP_VERTEX_CACHE_LEVELS 6
#define BENCH486_CLIP_VERTEX_CACHE_TAGS 504
static const unsigned long bench486_clipvertex_cache_sizes[
		BENCH486_CLIP_VERTEX_CACHE_LEVELS] = {8, 16, 32, 64, 128, 256};
static const unsigned long bench486_clipvertex_cache_bases[
		BENCH486_CLIP_VERTEX_CACHE_LEVELS] = {0, 8, 24, 56, 120, 248};
unsigned long bench486_clipvertex_plane_cache_hits[
		BENCH486_CLIP_VERTEX_CACHE_LEVELS][4];
unsigned long bench486_clipvertex_plane_cache_pair_hits[
		BENCH486_CLIP_VERTEX_CACHE_LEVELS][4];
static unsigned long bench486_clipvertex_plane_cache_tags[4][
		BENCH486_CLIP_VERTEX_CACHE_TAGS];
static unsigned long bench486_clipvertex_world_base;
static unsigned long bench486_clipvertex_world_bytes;
// R_RenderFace premise counters. The admissible part of renderface is its C
// scaffolding; the inadmissible part is the assembly clipper's x87 chain.
// These price the population split before any probe is built: edges that hit
// the edge cache do no clipping at all, so their cost is pure C.
unsigned long bench486_renderface_edge_setups;
unsigned long bench486_renderface_early_surfs;
unsigned long bench486_renderface_early_edges;
unsigned long bench486_renderface_faces;
unsigned long bench486_renderface_clipchain_builds;
unsigned long bench486_renderface_clipchain_cache_hits;
unsigned long bench486_texture_full_tzero;
unsigned long bench486_texture_full_tdelta_zero;
unsigned long bench486_texture_full_tfrac_zero;
unsigned long bench486_texture_full_sfrac_zero;
unsigned long bench486_texture_full_sone;
unsigned long bench486_texture_full_exact;
unsigned long bench486_texture_final_exact;
unsigned long bench486_texture_full_row_eligible;
unsigned long bench486_texture_full_row_fast;
unsigned long bench486_texture_tail_tstep_zero_segments;
unsigned long bench486_texture_tail_tstep_zero_samples;
// Unit-stride span premise. bench486_span_segments is every sixteen-wide
// segment the span drawer sets up; the other two are the subset whose t step
// has no whole texel, whose s step is exactly one texel and whose s step has
// no fractional part, so the source advances one byte per sample with no
// carry. Only the pixel count can be priced.
unsigned long bench486_span_segments;
// Lightmap build populations. The single-style path uses a 256-entry table and
// the multi-style path the fused asm loop; they have very different per-texel
// costs, so rebuild_seconds alone cannot price either.
// Alias-glue dead-scratch probe sink and count.  Defined by d_polyse.c, as the
// R_RenderFace probe does, because a C probe must accumulate into an external
// global: -O3 deletes a dead local store, so a local sink would make the probe
// a silent no-op.  The count is what proves it survived.
unsigned long bench486_zspan_pixels;
unsigned long bench486_zspan_spans;
unsigned long bench486_zspan_constant_runs;
unsigned long bench486_zspan_constant_pixels;
unsigned long bench486_lm_single_texels;
unsigned long bench486_lm_fused_texels;
unsigned long bench486_lm_fused_maps[5];
unsigned long bench486_span_unit_stride_segments;
unsigned long bench486_span_unit_stride_pixels;
// Does the light byte %dh hold still across the eight texels of an mip-1
// horizontal-flat row?  The -SurfaceBlockMip1IndexHoist hoist assumed it does.
// These are the direct measurement of that assumption and are the evidence for
// the experiment's outcome; they cost nothing in release builds.  The scratch
// byte the asm compares against is sb_flat_dh in surf8.s.
unsigned long bench486_surf8_flat_rows;
unsigned long bench486_surf8_flat_dh_moved;
unsigned long bench486_gradient_calls;
unsigned long bench486_solid_span_count;
unsigned long bench486_memset_calls;
unsigned long bench486_memset_bytes;
unsigned long bench486_memset_aligned_calls;
unsigned long bench486_memcpy_calls;
unsigned long bench486_memcpy_bytes;
unsigned long bench486_memcpy_same_alignment_calls;
unsigned long bench486_line_setup_calls;
unsigned long bench486_axis_cache_hits;
unsigned long bench486_axis_cache_misses;
unsigned long bench486_bsp_nodes;
unsigned long bench486_bsp_solid_culls;
unsigned long bench486_bsp_visibility_culls;
unsigned long bench486_bsp_leaf_nodes;
unsigned long bench486_bsp_internal_nodes;
unsigned long bench486_bsp_surface_tests;
unsigned long bench486_scanlines;
unsigned long bench486_edge_insert_calls;
unsigned long bench486_edge_remove_calls;
unsigned long bench486_edge_step_calls;
unsigned long bench486_span_flushes;
// Loop iterations behind those calls.  Three of the four edge routines walk
// a list, so a probe priced per call would be sized wrong by the walk length;
// these are the denominator for sizing the edge-scan dead-scratch probes.
unsigned long bench486_edge_insert_iters;
unsigned long bench486_edge_remove_iters;
unsigned long bench486_edge_step_iters;
unsigned long bench486_edge_pushback_iters;
unsigned long bench486_edge_sort_iters;
unsigned long bench486_edge_emit_blocks;
unsigned long bench486_edge_genspans_edges;
unsigned long bench486_edge_bmodel_zsort;
unsigned long bench486_edge_trailing_calls;
unsigned long bench486_edge_leading;
unsigned long bench486_edge_bmodel_leading;
unsigned long bench486_edge_bmodel_trailing;
unsigned long bench486_edge_insert_exit;
unsigned long bench486_edge_newtop;
unsigned long bench486_edge_xldone;
unsigned long bench486_edge_lastspan;
unsigned long bench486_edge_reset_iters;
unsigned long bench486_surface_span_count;
unsigned long bench486_surface_span_pixels;
unsigned long bench486_surface_span_segments;
unsigned long bench486_surface_sky_count;
unsigned long bench486_surface_background_count;
unsigned long bench486_surface_turbulent_count;
unsigned long bench486_surface_normal_count;
unsigned long bench486_surface_solid_count;
unsigned long bench486_present_rects;
unsigned long bench486_present_pixels;
unsigned long bench486_sound_update_calls;
unsigned long bench486_sound_mix_calls;
unsigned long bench486_joystick_reads;
unsigned long bench486_joystick_poll_iterations;
unsigned long bench486_joystick_timeouts;
unsigned long bench486_move_calls;
unsigned long bench486_hull_check_calls;
double bench486_alias_seconds;
double bench486_surface_seconds;
double bench486_turbulent_seconds;
unsigned long bench486_particle_count;
unsigned long bench486_gib_trail_particles;
double bench486_particle_seconds;

#define BENCH486_PROFILE_MAX_DEPTH 24
#define BENCH486_PROFILE_ROOT BENCH486_PROFILE_NODE_COUNT

typedef struct
{
	unsigned long calls;
	unsigned long work_items;
	unsigned long work_bytes;
	double inclusive_seconds;
	double self_seconds;
} bench486_profile_stat_t;

typedef struct
{
	unsigned long calls;
	double inclusive_seconds;
	double self_seconds;
} bench486_profile_edge_t;

typedef struct
{
	int node;
	int parent;
	double start;
	double child_seconds;
} bench486_profile_stack_entry_t;

static bench486_profile_stat_t bench486_profile_stats[
		BENCH486_PROFILE_NODE_COUNT];
static bench486_profile_edge_t bench486_profile_edges[
		BENCH486_PROFILE_NODE_COUNT + 1][BENCH486_PROFILE_NODE_COUNT];
static bench486_profile_stack_entry_t bench486_profile_stack[
		BENCH486_PROFILE_MAX_DEPTH];
static int bench486_profile_stack_depth;
static int bench486_profile_suppressed_depth;
static int bench486_profile_pending_leaves;
static unsigned long bench486_profile_timer_reads;
static unsigned long bench486_profile_stack_overflows;
static unsigned long bench486_profile_bad_leaves;
static unsigned long bench486_profile_max_depth;
static unsigned long bench486_profile_discarded_scopes;

static char *bench486_profile_node_names[BENCH486_PROFILE_NODE_COUNT] =
{
	"frame",
	"input",
	"game",
	"screen",
	"view",
	"view-lights",
	"renderer",
	"setup",
	"visibility",
	"edge-drawing",
	"world-bsp",
	"renderface",
	"edge-scan",
	"surfaces",
	"surface-cache",
	"gradients",
	"texture-spans",
	"z-spans",
	"sky-spans",
	"turbulent-spans",
	"solid-spans",
	"brush-entities",
	"entities",
	"sprites",
	"alias-model",
	"alias-setup",
	"alias-transform",
	"alias-raster",
	"alias-glue",
	"alias-calcgradients",
	"alias-linescan-setup",
	"alias-scan-left-edge",
	"alias-draw-spans",
	"alias-edge-setup",
	"alias-span-package",
	"alias-step-math",
	"viewmodel",
	"particles",
	"warp",
	"overlay",
	"palette",
	"present",
	"audio",
	"sound-spatial",
	"sound-mix",
	"cd-audio",
	"server",
	"server-clients",
	"server-physics",
	"server-messages",
	"client-read",
	"quakec",
	"collision",
	"physics-startframe",
	"physics-client",
	"physics-pusher",
	"physics-none",
	"physics-follow",
	"physics-noclip",
	"physics-step",
	"physics-toss",
	"collision-world",
	"collision-bounds",
	"collision-links"
};
#endif

extern void D_PolysetSetUpForLineScan (fixed8_t startvertu,
		fixed8_t startvertv, fixed8_t endvertu, fixed8_t endvertv);
extern void D_PolysetSetUpForLineScan_C (fixed8_t startvertu,
		fixed8_t startvertv, fixed8_t endvertu, fixed8_t endvertv);
extern void D_PolysetSetUpForLineScan_asm486 (fixed8_t startvertu,
		fixed8_t startvertv, fixed8_t endvertu, fixed8_t endvertv);
extern int ubasestep, erroradjustup, erroradjustdown;

static unsigned Bench486Checksum (byte *buffer, int count)
{
	int		i;
	unsigned	checksum;

	checksum = 0;
	for (i=0 ; i<count ; i++)
		checksum = checksum * 33 + buffer[i];

	return checksum;
}

static void Bench486Printf (char *format, ...)
{
	char		text[192];
	va_list		argptr;

	va_start (argptr, format);
	vsprintf (text, format, argptr);
	va_end (argptr);

	Con_Printf ("%s", text);
	if (bench486_report_handle != -1)
		Sys_FileWrite (bench486_report_handle, text, Q_strlen(text));
}

/* Fixture reports must not draw through vid.buffer while a test substitutes
 * a minimal video state. Keep progress visible in the report file only. */
static void Bench486ReportPrintf (char *format, ...)
{
	char		text[192];
	va_list		argptr;

	va_start (argptr, format);
	vsprintf (text, format, argptr);
	va_end (argptr);

	if (bench486_report_handle != -1)
		Sys_FileWrite (bench486_report_handle, text, Q_strlen(text));
}

#if defined(ASM486_VID_UPDATE_FIXTURE)
void Bench486VidUpdateReportCase (const char *name, unsigned differences,
		unsigned c_expected, unsigned asm_expected)
{
	Bench486ReportPrintf (
			"VID_Update case %s state diff 0x%x C expected diff 0x%x ASM expected diff 0x%x\n",
			name, differences, c_expected, asm_expected);
}
#endif

static void Bench486TimedemoReportText (int report_handle, char *text)
{
	Con_Printf ("%s", text);
	if (report_handle != -1)
		Sys_FileWrite (report_handle, text, Q_strlen(text));
}

/* Frame-rate events are intentionally broad enough to expose sustained
 * stalls without treating normal PIT quantization as a failure. */
#define BENCH486_TIMEDEMO_FPS_DROP_PERCENT 25

typedef struct
{
	unsigned long measured_frames;
	unsigned long stored_frames;
	unsigned long overflow_frames;
	unsigned long invalid_frames;
	unsigned long timer_reads;
	double average_fps;
	double minimum_fps;
	double maximum_fps;
	double median_fps;
	double low_1_percent_fps;
	double low_0_1_percent_fps;
	double high_1_percent_fps;
	double p0_1_fps;
	double p1_fps;
	double p5_fps;
	double p95_fps;
	double p99_fps;
	double p99_9_fps;
	double mean_frame_fps;
	double variance_fps;
	double standard_deviation_fps;
	double drop_threshold_fps;
	double spike_threshold_fps;
	unsigned long drop_frames;
	unsigned long spike_frames;
	unsigned long longest_drop_run;
	unsigned long longest_spike_run;
} bench486_timedemo_fps_stats_t;

/* The built-in demos fit comfortably in this fixed buffer; longer runs are
 * counted as overflow instead of allocating from the DOS heap. */
static float bench486_timedemo_frame_seconds[
		BENCH486_TIMEDEMO_MAX_FRAMES];
/* One extra buffered store per frame, using the existing end timer read.
 * Keep real elapsed positions (including inter-frame gaps) for host graphs. */
static float bench486_timedemo_frame_elapsed[
		BENCH486_TIMEDEMO_MAX_FRAMES];
static double bench486_timedemo_time_origin;
static unsigned long bench486_timedemo_measured_frames;
static unsigned long bench486_timedemo_stored_frames;
static unsigned long bench486_timedemo_overflow_frames;
static unsigned long bench486_timedemo_invalid_frames;
static unsigned long bench486_timedemo_timer_reads;
static unsigned long bench486_timedemo_frame_checksum_count;
static unsigned long bench486_timedemo_frame_checksum_overflow;
static unsigned long bench486_timedemo_rendered_frame_count;
#define BENCH486_BLOB_EXPLOSION_EVENT_MAX 32
static unsigned long bench486_blob_explosion_event_count;
static unsigned long bench486_blob_explosion_event_stored_count;
static unsigned long bench486_blob_explosion_event_overflow;
static unsigned long bench486_blob_explosion_event_frames[
		BENCH486_BLOB_EXPLOSION_EVENT_MAX];
#define BENCH486_LAVA_SPLASH_EVENT_MAX 32
static unsigned long bench486_lava_splash_event_count;
static unsigned long bench486_lava_splash_event_stored_count;
static unsigned long bench486_lava_splash_event_overflow;
static unsigned long bench486_lava_splash_event_frames[
		BENCH486_LAVA_SPLASH_EVENT_MAX];
#define BENCH486_TELEPORT_SPLASH_EVENT_MAX 32
static unsigned long bench486_teleport_splash_event_count;
static unsigned long bench486_teleport_splash_event_stored_count;
static unsigned long bench486_teleport_splash_event_overflow;
static unsigned long bench486_teleport_splash_event_frames[
		BENCH486_TELEPORT_SPLASH_EVENT_MAX];
#define BENCH486_RUN_PARTICLE_EFFECT_EVENT_MAX 32
static unsigned long bench486_run_particle_effect_event_count;
static unsigned long bench486_run_particle_effect_event_stored_count;
static unsigned long bench486_run_particle_effect_event_overflow;
static unsigned long bench486_run_particle_effect_event_frames[
		BENCH486_RUN_PARTICLE_EFFECT_EVENT_MAX];
#define BENCH486_ENTITY_PARTICLES_EVENT_MAX 32
static unsigned long bench486_entity_particles_event_count;
static unsigned long bench486_entity_particles_event_stored_count;
static unsigned long bench486_entity_particles_event_overflow;
static unsigned long bench486_entity_particles_event_frames[
		BENCH486_ENTITY_PARTICLES_EVENT_MAX];
#define BENCH486_SVC_DAMAGE_EVENT_MAX 32
static unsigned long bench486_svc_damage_event_count;
static unsigned long bench486_svc_damage_event_stored_count;
static unsigned long bench486_svc_damage_event_overflow;
static unsigned long bench486_svc_damage_event_frames[
		BENCH486_SVC_DAMAGE_EVENT_MAX];
static int bench486_timedemo_frame_capture_index = -1;
static qboolean bench486_timedemo_frame_checksums_enabled;
static int bench486_timedemo_frame_checksum_handle = -1;
static int bench486_timedemo_z_checksum_handle = -1;
static qboolean bench486_timedemo_stats_enabled;
static qboolean bench486_timedemo_stats_active;
static qboolean bench486_timedemo_frame_started;
static double bench486_timedemo_frame_start;

static void Bench486TimedemoRecordFrame (double seconds, double elapsed)
{
	bench486_timedemo_measured_frames++;
	if (seconds <= 0)
	{
		bench486_timedemo_invalid_frames++;
		return;
	}
	if (bench486_timedemo_stored_frames >= BENCH486_TIMEDEMO_MAX_FRAMES)
	{
		bench486_timedemo_overflow_frames++;
		return;
	}
	bench486_timedemo_frame_elapsed[bench486_timedemo_stored_frames] =
			(float)elapsed;
	bench486_timedemo_frame_seconds[bench486_timedemo_stored_frames++] = (float)seconds;
}

void Bench486ResetTimedemoStats (void)
{
	bench486_timedemo_measured_frames = 0;
	bench486_timedemo_stored_frames = 0;
	bench486_timedemo_overflow_frames = 0;
	bench486_timedemo_invalid_frames = 0;
	bench486_timedemo_timer_reads = 0;
	bench486_timedemo_stats_enabled = true;
	bench486_timedemo_stats_active = false;
	bench486_timedemo_frame_started = false;
	bench486_timedemo_frame_start = 0;
	bench486_timedemo_time_origin = 0;
}

void Bench486BeginTimedemoStats (void)
{
	if (bench486_timedemo_stats_enabled)
	{
		bench486_timedemo_time_origin = bench486_timedemo_frame_start;
		bench486_timedemo_stats_active = true;
	}
}

void Bench486TimedemoFrameStart (void)
{
	if (!bench486_timedemo_stats_enabled)
		return;
	bench486_timedemo_frame_start = Sys_FloatTime ();
	bench486_timedemo_timer_reads++;
	bench486_timedemo_frame_started = true;
}

void Bench486TimedemoFrameEnd (void)
{
	double now;

	if (!bench486_timedemo_frame_started)
		return;
	bench486_timedemo_frame_started = false;
	if (!bench486_timedemo_stats_active)
		return;
	now = Sys_FloatTime ();
	bench486_timedemo_timer_reads++;
	Bench486TimedemoRecordFrame (now - bench486_timedemo_frame_start,
			now - bench486_timedemo_time_origin);
}

void Bench486ResetTimedemoFrameChecksums (int enabled)
{
	int parm;

	if (bench486_timedemo_frame_checksum_handle != -1)
		Sys_FileClose (bench486_timedemo_frame_checksum_handle);
	if (bench486_timedemo_z_checksum_handle != -1)
		Sys_FileClose (bench486_timedemo_z_checksum_handle);
	bench486_timedemo_frame_checksum_count = 0;
	bench486_timedemo_frame_checksum_overflow = 0;
	bench486_timedemo_rendered_frame_count = 0;
	bench486_blob_explosion_event_count = 0;
	bench486_blob_explosion_event_stored_count = 0;
	bench486_blob_explosion_event_overflow = 0;
	bench486_lava_splash_event_count = 0;
	bench486_lava_splash_event_stored_count = 0;
	bench486_lava_splash_event_overflow = 0;
	bench486_teleport_splash_event_count = 0;
	bench486_teleport_splash_event_stored_count = 0;
	bench486_teleport_splash_event_overflow = 0;
	bench486_run_particle_effect_event_count = 0;
	bench486_run_particle_effect_event_stored_count = 0;
	bench486_run_particle_effect_event_overflow = 0;
	bench486_entity_particles_event_count = 0;
	bench486_entity_particles_event_stored_count = 0;
	bench486_entity_particles_event_overflow = 0;
	bench486_svc_damage_event_count = 0;
	bench486_svc_damage_event_stored_count = 0;
	bench486_svc_damage_event_overflow = 0;
	bench486_timedemo_frame_checksums_enabled = enabled != 0;
	bench486_timedemo_frame_capture_index = -1;
	parm = COM_CheckParm ("-framecapture");
	if (parm && parm + 1 < com_argc)
		bench486_timedemo_frame_capture_index = Q_atoi (com_argv[parm + 1]);
	bench486_timedemo_frame_checksum_handle = enabled ?
			Sys_FileOpenWrite ("framechecksums.txt") : -1;
	parm = COM_CheckParm ("-zchecksums");
	bench486_timedemo_z_checksum_handle = enabled && parm ?
			Sys_FileOpenWrite ("framezchecksums.txt") : -1;
}

void Bench486RecordBlobExplosionEvent (void)
{
	if (bench486_blob_explosion_event_stored_count <
			BENCH486_BLOB_EXPLOSION_EVENT_MAX)
		bench486_blob_explosion_event_frames[
				bench486_blob_explosion_event_stored_count++] =
				bench486_timedemo_rendered_frame_count;
	else
		bench486_blob_explosion_event_overflow++;
	bench486_blob_explosion_event_count++;
}

void Bench486RecordLavaSplashEvent (void)
{
	if (bench486_lava_splash_event_stored_count <
			BENCH486_LAVA_SPLASH_EVENT_MAX)
		bench486_lava_splash_event_frames[
				bench486_lava_splash_event_stored_count++] =
				bench486_timedemo_rendered_frame_count;
	else
		bench486_lava_splash_event_overflow++;
	bench486_lava_splash_event_count++;
}

void Bench486RecordTeleportSplashEvent (void)
{
	if (bench486_teleport_splash_event_stored_count <
			BENCH486_TELEPORT_SPLASH_EVENT_MAX)
		bench486_teleport_splash_event_frames[
				bench486_teleport_splash_event_stored_count++] =
				bench486_timedemo_rendered_frame_count;
	else
		bench486_teleport_splash_event_overflow++;
	bench486_teleport_splash_event_count++;
}

void Bench486RecordRunParticleEffectEvent (void)
{
	if (bench486_run_particle_effect_event_stored_count <
			BENCH486_RUN_PARTICLE_EFFECT_EVENT_MAX)
		bench486_run_particle_effect_event_frames[
				bench486_run_particle_effect_event_stored_count++] =
				bench486_timedemo_rendered_frame_count;
	else
		bench486_run_particle_effect_event_overflow++;
	bench486_run_particle_effect_event_count++;
}

unsigned long Bench486TimedemoRenderedFrameCount (void)
{
	return bench486_timedemo_rendered_frame_count;
}

void Bench486RecordEntityParticlesEvent (void)
{
	if (bench486_entity_particles_event_stored_count <
			BENCH486_ENTITY_PARTICLES_EVENT_MAX)
		bench486_entity_particles_event_frames[
				bench486_entity_particles_event_stored_count++] =
				bench486_timedemo_rendered_frame_count;
	else
		bench486_entity_particles_event_overflow++;
	bench486_entity_particles_event_count++;
}

void Bench486RecordSvcDamageEvent (void)
{
	if (bench486_svc_damage_event_stored_count <
			BENCH486_SVC_DAMAGE_EVENT_MAX)
		bench486_svc_damage_event_frames[
				bench486_svc_damage_event_stored_count++] =
				bench486_timedemo_rendered_frame_count;
	else
		bench486_svc_damage_event_overflow++;
	bench486_svc_damage_event_count++;
}

void Bench486TimedemoFrameChecksumRecord (void)
{
	char	text[32];
	unsigned checksum, zchecksum;
	unsigned long frame;

	/* Keep event timing meaningful even when checksum output is disabled. */
	bench486_timedemo_rendered_frame_count++;
	if (!bench486_timedemo_frame_checksums_enabled)
		return;

	if (bench486_timedemo_frame_checksum_count >=
			BENCH486_TIMEDEMO_MAX_FRAMES)
	{
		bench486_timedemo_frame_checksum_overflow++;
		return;
	}

	checksum = vid.buffer ? Bench486Checksum ((byte *)vid.buffer,
			(int)(vid.rowbytes * vid.height)) : 0;
	frame = bench486_timedemo_frame_checksum_count++;
	if ((int)frame == bench486_timedemo_frame_capture_index && vid.buffer &&
			host_basepal)
	{
		WritePCXfile ("frame.pcx", (byte *)vid.buffer, vid.width, vid.height,
				vid.rowbytes, host_basepal);
		bench486_timedemo_frame_capture_index = -1;
	}
	if (bench486_timedemo_frame_checksum_handle != -1)
	{
		sprintf (text, "%lu %u\n", frame, checksum);
		Sys_FileWrite (bench486_timedemo_frame_checksum_handle, text,
				Q_strlen(text));
	}
	if (bench486_timedemo_z_checksum_handle != -1)
	{
		zchecksum = d_pzbuffer ? Bench486Checksum ((byte *)d_pzbuffer,
				(int)(d_zrowbytes * vid.height)) : 0;
		sprintf (text, "%lu %u\n", frame, zchecksum);
		Sys_FileWrite (bench486_timedemo_z_checksum_handle, text,
				Q_strlen(text));
	}
}

void Bench486FinishTimedemoStats (int timedemo_frames)
{
	if (bench486_timedemo_stats_active &&
			bench486_timedemo_frame_started &&
			bench486_timedemo_measured_frames < (unsigned long)timedemo_frames)
		Bench486TimedemoFrameEnd ();
	else
		bench486_timedemo_frame_started = false;
	bench486_timedemo_stats_active = false;
	bench486_timedemo_stats_enabled = false;
}

static double Bench486TimedemoRangeAverage (unsigned start,
		unsigned count)
{
	unsigned i;
	double total;

	if (!count)
		return 0;
	total = 0;
	for (i=0 ; i<count ; i++)
		total += bench486_timedemo_frame_seconds[start + i];
	return total / count;
}

static double Bench486TimedemoPercentile (unsigned count, unsigned numerator,
		unsigned denominator)
{
	unsigned rank;

	if (!count)
		return 0;
	rank = (count * numerator + denominator - 1) / denominator;
	if (rank)
		rank--;
	if (rank >= count)
		rank = count - 1;
	return bench486_timedemo_frame_seconds[rank];
}

static void Bench486TimedemoComputeStats (int timedemo_frames,
		double timedemo_seconds, bench486_timedemo_fps_stats_t *stats)
{
	unsigned i, j, count, low_count, low_tenth_count;
	float value;
	double fps, total, total_squared;
	unsigned long current_drop_run, current_spike_run;

	Q_memset (stats, 0, sizeof(*stats));
	stats->measured_frames = bench486_timedemo_measured_frames;
	stats->stored_frames = bench486_timedemo_stored_frames;
	stats->overflow_frames = bench486_timedemo_overflow_frames;
	stats->invalid_frames = bench486_timedemo_invalid_frames;
	stats->timer_reads = bench486_timedemo_timer_reads;
	stats->average_fps = timedemo_seconds > 0 ?
			timedemo_frames / timedemo_seconds : 0;
	count = (unsigned)bench486_timedemo_stored_frames;
	if (!count)
		return;

	stats->drop_threshold_fps = stats->average_fps *
			(100 - BENCH486_TIMEDEMO_FPS_DROP_PERCENT) / 100.0;
	stats->spike_threshold_fps = stats->average_fps *
			(100 + BENCH486_TIMEDEMO_FPS_DROP_PERCENT) / 100.0;
	total = 0;
	total_squared = 0;
	current_drop_run = 0;
	current_spike_run = 0;
	for (i=0 ; i<count ; i++)
	{
		fps = bench486_timedemo_frame_seconds[i] > 0 ?
				1.0 / bench486_timedemo_frame_seconds[i] : 0;
		total += fps;
		total_squared += fps * fps;
		if (fps < stats->drop_threshold_fps)
		{
			stats->drop_frames++;
			current_drop_run++;
			if (current_drop_run > stats->longest_drop_run)
				stats->longest_drop_run = current_drop_run;
		}
		else
			current_drop_run = 0;
		if (fps > stats->spike_threshold_fps)
		{
			stats->spike_frames++;
			current_spike_run++;
			if (current_spike_run > stats->longest_spike_run)
				stats->longest_spike_run = current_spike_run;
		}
		else
			current_spike_run = 0;
		bench486_timedemo_frame_seconds[i] = (float)fps;
	}
	stats->mean_frame_fps = total / count;
	stats->variance_fps = total_squared / count -
			stats->mean_frame_fps * stats->mean_frame_fps;
	if (stats->variance_fps < 0)
		stats->variance_fps = 0;
	stats->standard_deviation_fps = sqrt (stats->variance_fps);

	for (i=1 ; i<count ; i++)
	{
		value = bench486_timedemo_frame_seconds[i];
		j = i;
		while (j > 0 && bench486_timedemo_frame_seconds[j - 1] > value)
		{
			bench486_timedemo_frame_seconds[j] =
					bench486_timedemo_frame_seconds[j - 1];
			j--;
		}
		bench486_timedemo_frame_seconds[j] = value;
	}

	stats->minimum_fps = bench486_timedemo_frame_seconds[0];
	stats->maximum_fps = bench486_timedemo_frame_seconds[count - 1];
	if (count & 1)
		stats->median_fps = bench486_timedemo_frame_seconds[count / 2];
	else
		stats->median_fps = (bench486_timedemo_frame_seconds[count / 2 - 1] +
				bench486_timedemo_frame_seconds[count / 2]) / 2.0;
	low_count = (count + 99) / 100;
	low_tenth_count = (count + 999) / 1000;
	if (!low_count)
		low_count = 1;
	if (!low_tenth_count)
		low_tenth_count = 1;
	stats->low_1_percent_fps = Bench486TimedemoRangeAverage (0, low_count);
	stats->low_0_1_percent_fps = Bench486TimedemoRangeAverage (0,
			low_tenth_count);
	stats->high_1_percent_fps = Bench486TimedemoRangeAverage (count - low_count,
			low_count);
	stats->p0_1_fps = Bench486TimedemoPercentile (count, 1, 1000);
	stats->p1_fps = Bench486TimedemoPercentile (count, 1, 100);
	stats->p5_fps = Bench486TimedemoPercentile (count, 5, 100);
	stats->p95_fps = Bench486TimedemoPercentile (count, 95, 100);
	stats->p99_fps = Bench486TimedemoPercentile (count, 99, 100);
	stats->p99_9_fps = Bench486TimedemoPercentile (count, 999, 1000);
}

static void Bench486TimedemoStatsJsonPrintf (int file_handle,
		char *format, ...)
{
	char text[512];
	va_list argptr;

	va_start (argptr, format);
	vsprintf (text, format, argptr);
	va_end (argptr);
	Sys_FileWrite (file_handle, text, Q_strlen(text));
}

static void Bench486WriteTimedemoStatsJson (int timedemo_frames,
		double timedemo_seconds, bench486_timedemo_fps_stats_t *stats)
{
	int file_handle;

	file_handle = Sys_FileOpenWrite ("timedemo.jsn");
	if (file_handle == -1)
		return;
	Bench486TimedemoStatsJsonPrintf (file_handle,
			"{\n  \"schema\": 1,\n"
			"  \"benchmark\": {\"frames\": %d, \"duration_seconds\": %.6f, \"average_fps\": %.6f},\n",
			timedemo_frames, timedemo_seconds, stats->average_fps);
	Bench486TimedemoStatsJsonPrintf (file_handle,
			"  \"frame_timing\": {\"schema\": 1, \"csv\": \"FRAMTIME.CSV\", \"clock\": \"Sys_FloatTime\", \"width\": %d, \"height\": %d},\n",
			vid.width, vid.height);
	Bench486TimedemoStatsJsonPrintf (file_handle,
			"  \"fps\": {\"measured_frames\": %lu, \"stored_frames\": %lu, \"overflow_frames\": %lu, \"invalid_frames\": %lu, \"timer_reads\": %lu, \"minimum_fps\": %.6f, \"maximum_fps\": %.6f, \"median_fps\": %.6f, \"low_1_percent_fps\": %.6f, \"low_0_1_percent_fps\": %.6f, \"high_1_percent_fps\": %.6f, \"mean_frame_fps\": %.6f, \"standard_deviation_fps\": %.6f, \"variance_fps\": %.6f},\n",
			stats->measured_frames, stats->stored_frames,
			stats->overflow_frames, stats->invalid_frames,
			stats->timer_reads,
			stats->minimum_fps, stats->maximum_fps, stats->median_fps,
			stats->low_1_percent_fps, stats->low_0_1_percent_fps,
			stats->high_1_percent_fps, stats->mean_frame_fps,
			stats->standard_deviation_fps, stats->variance_fps);
	Bench486TimedemoStatsJsonPrintf (file_handle,
			"  \"percentiles\": {\"p0_1\": %.6f, \"p1\": %.6f, \"p5\": %.6f, \"p50\": %.6f, \"p95\": %.6f, \"p99\": %.6f, \"p99_9\": %.6f},\n",
			stats->p0_1_fps, stats->p1_fps, stats->p5_fps,
			stats->median_fps, stats->p95_fps, stats->p99_fps,
			stats->p99_9_fps);
	Bench486TimedemoStatsJsonPrintf (file_handle,
			"  \"events\": {\"drop_threshold_fps\": %.6f, \"drops\": %lu, \"longest_drop_run\": %lu, \"spike_threshold_fps\": %.6f, \"spikes\": %lu, \"longest_spike_run\": %lu}\n}\n",
			stats->drop_threshold_fps, stats->drop_frames,
			stats->longest_drop_run, stats->spike_threshold_fps,
			stats->spike_frames, stats->longest_spike_run);
	Sys_FileClose (file_handle);
}

void Bench486WriteTimedemoStats (int report_handle, int timedemo_frames,
		double timedemo_seconds)
{
	char text[1024];
	int frame_file;
	unsigned long frame;
	bench486_timedemo_fps_stats_t stats;

	/* Export before ComputeStats converts and sorts the duration buffer in place.
	 * All formatting and disk I/O happen after the timed interval, never per frame.
	 * DOS 8.3 name; the host validates completeness against timedemo.jsn. */
	frame_file = Sys_FileOpenWrite ("FRAMTIME.CSV");
	if (frame_file != -1)
	{
		strcpy (text, "sample_index,elapsed_seconds,frame_seconds\n");
		Sys_FileWrite (frame_file, text, Q_strlen(text));
		for (frame=0 ; frame<bench486_timedemo_stored_frames ; frame++)
		{
			sprintf (text, "%lu,%.9f,%.9f\n", frame,
					(double)bench486_timedemo_frame_elapsed[frame],
					(double)bench486_timedemo_frame_seconds[frame]);
			Sys_FileWrite (frame_file, text, Q_strlen(text));
		}
		Sys_FileClose (frame_file);
	}
	Bench486TimedemoComputeStats (timedemo_frames, timedemo_seconds, &stats);
	sprintf (text,
			"fps-summary frames %d measured %lu stored %lu overflow %lu "
			"timer-reads %lu "
			"duration %.6f average %.6f min %.6f max %.6f median %.6f "
			"low1 %.6f low0.1 %.6f high1 %.6f mean-frame %.6f "
			"stddev %.6f variance %.6f\n",
			timedemo_frames, stats.measured_frames, stats.stored_frames,
			stats.overflow_frames, stats.timer_reads, timedemo_seconds,
			stats.average_fps,
			stats.minimum_fps, stats.maximum_fps, stats.median_fps,
			stats.low_1_percent_fps, stats.low_0_1_percent_fps,
			stats.high_1_percent_fps, stats.mean_frame_fps,
			stats.standard_deviation_fps, stats.variance_fps);
	Bench486TimedemoReportText (report_handle, text);
	sprintf (text,
			"fps-percentiles p0.1 %.6f p1 %.6f p5 %.6f p50 %.6f "
			"p95 %.6f p99 %.6f p99.9 %.6f\n",
			stats.p0_1_fps, stats.p1_fps, stats.p5_fps, stats.median_fps,
			stats.p95_fps, stats.p99_fps, stats.p99_9_fps);
	Bench486TimedemoReportText (report_handle, text);
	sprintf (text,
			"fps-events drop-threshold %.6f drops %lu longest-drop %lu "
			"spike-threshold %.6f spikes %lu longest-spike %lu invalid %lu\n",
			stats.drop_threshold_fps, stats.drop_frames,
			stats.longest_drop_run, stats.spike_threshold_fps,
			stats.spike_frames, stats.longest_spike_run,
			stats.invalid_frames);
	Bench486TimedemoReportText (report_handle, text);
	Bench486WriteTimedemoStatsJson (timedemo_frames, timedemo_seconds,
			&stats);
}

#ifdef PROFILE486
/*
Measure what one Sys_FloatTime call actually costs on this host, by timing a
back-to-back burst. Everything the profiler reports is bounded below by this
value, so a per-call figure smaller than it is not a measurement.
*/
static double bench486_profile_read_seconds = 0;

static void Bench486ProfileCalibrateTimer (void)
{
	int		i;
	double	start, end;
	const int reads = 256;

	start = Sys_FloatTime ();
	for (i=0 ; i<reads ; i++)
	{
		Sys_FloatTime ();
	}
	end = Sys_FloatTime ();

	// The two bracketing reads are themselves part of the elapsed interval.
	bench486_profile_read_seconds = (end - start) / (reads + 2);
}

/*
A scope's measured self window physically contains its own LEAVE timer read plus
the ENTER read of every child scope it invokes. Both are real Sys_FloatTime calls,
so a scope called N times cannot report a per-call cost below the time its own
instrumentation consumed. Counting those reads lets the report refuse to quote a
per-call figure that its own instrumentation floor swamps.
*/
static unsigned long Bench486ProfileChildReads (int node)
{
	unsigned long reads = 0;
	int			child;

	for (child=0 ; child<BENCH486_PROFILE_NODE_COUNT ; child++)
	{
		reads += (unsigned long)
				bench486_profile_edges[node][child].calls;
	}

	return reads;
}

static void Bench486ProfileReset (void)
{
	bench486_profile_coarse_active = false;
	bench486_profile_coarse_mode = COM_CheckParm ("-profilecoarse") != 0;
	if (COM_CheckParm ("-profileparts"))
		bench486_profile_coarse_mode = 2;
	bench486_profile_filter_depth = 0;
	Bench486ProfileCalibrateTimer ();
	Zone_ResetProfileCounters ();
	Q_memset (bench486_profile_stats, 0, sizeof(bench486_profile_stats));
	Q_memset (bench486_profile_edges, 0, sizeof(bench486_profile_edges));
	Q_memset (bench486_profile_stack, 0, sizeof(bench486_profile_stack));
	bench486_profile_stack_depth = 0;
	bench486_profile_suppressed_depth = 0;
	bench486_profile_pending_leaves = 0;
	bench486_profile_timer_reads = 0;
	bench486_profile_stack_overflows = 0;
	bench486_profile_bad_leaves = 0;
	bench486_profile_max_depth = 0;
	bench486_profile_discarded_scopes = 0;
}

void Bench486ProfileEnter (int node)
{
	double now;
	int parent;
	bench486_profile_edge_t *edge;

	if (!bench486_profile_frame_active && !bench486_profile_coarse_active)
		return;

	if (node < 0 || node >= BENCH486_PROFILE_NODE_COUNT)
	{
		bench486_profile_bad_leaves++;
		return;
	}
	/* Coarse captures disable all dense renderer premise counters. Keep a
	 * logical entry stack so audio calls inside unselected renderer scopes
	 * still get attributed, without timing every triangle or surface. */
	if (bench486_profile_coarse_mode)
	{
		int selected = node == BENCH486_PROFILE_FRAME ||
			node == BENCH486_PROFILE_INPUT || node == BENCH486_PROFILE_GAME ||
			node == BENCH486_PROFILE_SCREEN || node == BENCH486_PROFILE_RENDERER ||
			node == BENCH486_PROFILE_PRESENT || node == BENCH486_PROFILE_AUDIO ||
			node == BENCH486_PROFILE_SOUND_SPATIAL || node == BENCH486_PROFILE_SOUND_MIX ||
			node == BENCH486_PROFILE_CD_AUDIO ||
			(node >= BENCH486_PROFILE_SERVER && node <= BENCH486_PROFILE_CLIENT_READ);
		/* Component capture keeps dense premise counters off as well. Exclude
		 * the per-triangle/per-face scopes that otherwise dominate clock cost. */
		if (bench486_profile_coarse_mode == 2 &&
				(node == BENCH486_PROFILE_SETUP || node == BENCH486_PROFILE_VISIBILITY ||
				node == BENCH486_PROFILE_EDGE_DRAWING || node == BENCH486_PROFILE_WORLD_BSP ||
				node == BENCH486_PROFILE_EDGE_SCAN || node == BENCH486_PROFILE_SURFACES ||
				node == BENCH486_PROFILE_SURFACE_CACHE ||
				(node >= BENCH486_PROFILE_TEXTURE_SPANS && node <= BENCH486_PROFILE_ALIAS_TRANSFORM) ||
				node == BENCH486_PROFILE_ALIAS_RASTER || node == BENCH486_PROFILE_VIEWMODEL ||
				node == BENCH486_PROFILE_PARTICLES || node == BENCH486_PROFILE_WARP ||
				node == BENCH486_PROFILE_QUAKEC || node == BENCH486_PROFILE_COLLISION))
			selected = 1;
		if (bench486_profile_filter_depth >= 128)
			Sys_Error ("Coarse profile entry stack overflow");
		bench486_profile_filter[bench486_profile_filter_depth++] = selected;
		if (!selected)
			return;
	}

	if (bench486_profile_suppressed_depth)
	{
		bench486_profile_suppressed_depth++;
		return;
	}

	if (bench486_profile_stack_depth >= BENCH486_PROFILE_MAX_DEPTH)
	{
		bench486_profile_stack_overflows++;
		bench486_profile_suppressed_depth = 1;
		return;
	}

	now = Sys_FloatTime ();
	bench486_profile_timer_reads++;
	parent = bench486_profile_stack_depth ?
			bench486_profile_stack[bench486_profile_stack_depth - 1].node :
			BENCH486_PROFILE_ROOT;

	bench486_profile_stack[bench486_profile_stack_depth].node = node;
	bench486_profile_stack[bench486_profile_stack_depth].parent = parent;
	bench486_profile_stack[bench486_profile_stack_depth].start = now;
	bench486_profile_stack[bench486_profile_stack_depth].child_seconds = 0;
	bench486_profile_stack_depth++;
	if ((unsigned long)bench486_profile_stack_depth > bench486_profile_max_depth)
		bench486_profile_max_depth = bench486_profile_stack_depth;

	bench486_profile_stats[node].calls++;
	edge = &bench486_profile_edges[parent][node];
	edge->calls++;
}

void Bench486ProfileLeave (void)
{
	bench486_profile_stack_entry_t *entry;
	bench486_profile_stat_t *stat;
	bench486_profile_edge_t *edge;
	double now;
	double elapsed;
	double self;

	if (!bench486_profile_frame_active && !bench486_profile_coarse_active)
		return;

	if (bench486_profile_pending_leaves)
	{
		bench486_profile_pending_leaves--;
		return;
	}
	if (bench486_profile_coarse_mode)
	{
		if (!bench486_profile_filter_depth)
		{
			bench486_profile_bad_leaves++;
			return;
		}
		if (!bench486_profile_filter[--bench486_profile_filter_depth])
			return;
	}

	if (bench486_profile_suppressed_depth)
	{
		bench486_profile_suppressed_depth--;
		return;
	}

	if (!bench486_profile_stack_depth)
	{
		bench486_profile_bad_leaves++;
		return;
	}

	now = Sys_FloatTime ();
	bench486_profile_timer_reads++;
	entry = &bench486_profile_stack[bench486_profile_stack_depth - 1];
	elapsed = now - entry->start;
	self = elapsed - entry->child_seconds;
	if (self < 0)
		self = 0;

	stat = &bench486_profile_stats[entry->node];
	stat->inclusive_seconds += elapsed;
	stat->self_seconds += self;
	edge = &bench486_profile_edges[entry->parent][entry->node];
	edge->inclusive_seconds += elapsed;
	edge->self_seconds += self;

	bench486_profile_stack_depth--;
	if (bench486_profile_stack_depth)
		bench486_profile_stack[bench486_profile_stack_depth - 1].child_seconds +=
				elapsed;
}

void Bench486ProfileWork (int node, unsigned long items,
		unsigned long bytes)
{
	if (!bench486_profile_frame_active)
		return;
	if (node < 0 || node >= BENCH486_PROFILE_NODE_COUNT)
		return;
	bench486_profile_stats[node].work_items += items;
	bench486_profile_stats[node].work_bytes += bytes;
}

void Bench486ProfileDiscardOpenScopes (void)
{
	bench486_profile_stack_entry_t *entry;

	while (bench486_profile_stack_depth)
	{
		entry = &bench486_profile_stack[bench486_profile_stack_depth - 1];
		if (bench486_profile_stats[entry->node].calls)
			bench486_profile_stats[entry->node].calls--;
		if (bench486_profile_edges[entry->parent][entry->node].calls)
			bench486_profile_edges[entry->parent][entry->node].calls--;
		bench486_profile_stack_depth--;
		bench486_profile_discarded_scopes++;
	}
	bench486_profile_suppressed_depth = 0;
	bench486_profile_pending_leaves = 0;
	bench486_profile_filter_depth = 0;
}

static void Bench486ProfileReportText (int report_handle, char *text)
{
	Con_Printf ("%s", text);
	if (report_handle != -1)
		Sys_FileWrite (report_handle, text, Q_strlen(text));
}

static void Bench486ProfileJsonPrintf (int file_handle, char *format, ...)
{
	char		text[2048];
	va_list		argptr;

	va_start (argptr, format);
	vsprintf (text, format, argptr);
	va_end (argptr);
	Sys_FileWrite (file_handle, text, Q_strlen(text));
}

static double Bench486ProfileFrameSeconds (void)
{
	return bench486_profile_stats[BENCH486_PROFILE_FRAME].inclusive_seconds;
}

static void Bench486ProfileTree (int report_handle, int parent, int depth)
{
	int		order[BENCH486_PROFILE_NODE_COUNT];
	int		count;
	int		child;
	int		i, j, swap;
	char		text[256];
	double		frame_seconds;
	double		inclusive_percent;
	double		self_percent;
	bench486_profile_edge_t *edge;
	bench486_profile_stat_t *stat;

	if (depth >= BENCH486_PROFILE_MAX_DEPTH)
		return;

	count = 0;
	for (child=0 ; child<BENCH486_PROFILE_NODE_COUNT ; child++)
	{
		if (!bench486_profile_edges[parent][child].calls)
			continue;
		order[count++] = child;
	}

	for (i=1 ; i<count ; i++)
	{
		swap = order[i];
		j = i - 1;
		while (j >= 0 &&
				bench486_profile_edges[parent][order[j]].inclusive_seconds <
				bench486_profile_edges[parent][swap].inclusive_seconds)
		{
			order[j+1] = order[j];
			j--;
		}
		order[j+1] = swap;
	}

	frame_seconds = Bench486ProfileFrameSeconds ();
	for (i=0 ; i<count ; i++)
	{
		child = order[i];
		edge = &bench486_profile_edges[parent][child];
		stat = &bench486_profile_stats[child];
		if (frame_seconds > 0)
		{
			inclusive_percent = edge->inclusive_seconds * 100.0 /
					frame_seconds;
			self_percent = edge->self_seconds * 100.0 / frame_seconds;
		}
		else
		{
			inclusive_percent = 0;
			self_percent = 0;
		}
		sprintf (text,
				"%*s%s inc %.6f self %.6f inc%% %.2f self%% %.2f "
				"calls %lu work %lu bytes %lu\n",
				depth * 2, "", bench486_profile_node_names[child],
				edge->inclusive_seconds, edge->self_seconds,
				inclusive_percent, self_percent, edge->calls,
				stat->work_items, stat->work_bytes);
		Bench486ProfileReportText (report_handle, text);
		Bench486ProfileTree (report_handle, child, depth + 1);
	}
}

static void Bench486ProfileHotspots (int report_handle)
{
	int		order[BENCH486_PROFILE_NODE_COUNT];
	int		count;
	int		node;
	int		i, j, swap;
	char		text[256];
	double		frame_seconds;
	bench486_profile_stat_t *stat;

	count = 0;
	for (node=0 ; node<BENCH486_PROFILE_NODE_COUNT ; node++)
	{
		if (bench486_profile_stats[node].calls)
			order[count++] = node;
	}

	for (i=1 ; i<count ; i++)
	{
		swap = order[i];
		j = i - 1;
		while (j >= 0 &&
				bench486_profile_stats[order[j]].self_seconds <
				bench486_profile_stats[swap].self_seconds)
		{
			order[j+1] = order[j];
			j--;
		}
		order[j+1] = swap;
	}

	frame_seconds = Bench486ProfileFrameSeconds ();
	for (i=0 ; i<count && i<12 ; i++)
	{
		unsigned long instr_reads;
		double		floor_seconds;

		node = order[i];
		stat = &bench486_profile_stats[node];
		instr_reads = (unsigned long)stat->calls +
				Bench486ProfileChildReads (node);
		floor_seconds = frame_seconds > 0
				? instr_reads * bench486_profile_read_seconds
				: 0;
		sprintf (text,
				"%2i %s self %.6f self%% %.2f inc %.6f calls %lu "
				"work %lu bytes %lu instr %lu%s\n",
				i + 1, bench486_profile_node_names[node],
				stat->self_seconds,
				frame_seconds > 0 ? stat->self_seconds * 100.0 /
						frame_seconds : 0,
				stat->inclusive_seconds, stat->calls,
				stat->work_items, stat->work_bytes,
				instr_reads,
				floor_seconds > stat->self_seconds
					? " [BELOW INSTRUMENTATION FLOOR]" : "");
		Bench486ProfileReportText (report_handle, text);
	}
}

/*
A scope's measured self window physically contains its own LEAVE timer read plus
the ENTER read of every child scope it invokes. Both are real Sys_FloatTime calls
at roughly 250-305 cycles each, so a scope called N times cannot report a
per-call cost below about 2N reads worth of time. Counting the reads charged
into each node lets the report refuse to quote a per-call figure that its own
instrumentation floor swamps.
*/
static void Bench486WriteProfileJson (int timedemo_frames,
		float timedemo_seconds)
{
	int		file_handle;
	int		parent, child;
	int		first;
	double		fps;
	bench486_profile_stat_t *stat;
	bench486_profile_edge_t *edge;

	file_handle = Sys_FileOpenWrite ("profile.jsn");
	if (file_handle == -1)
		return;

	fps = timedemo_seconds > 0 ? timedemo_frames / timedemo_seconds : 0;
	Bench486ProfileJsonPrintf (file_handle, "{\n");
	Bench486ProfileJsonPrintf (file_handle,
			"  \"schema\": 1,\n"
			"  \"benchmark\": {\"demo_frames\": %d, \"demo_seconds\": %.6f, \"demo_fps\": %.6f},\n",
			timedemo_frames, timedemo_seconds, fps);
	Bench486ProfileJsonPrintf (file_handle,
			"  \"capture_mode\": \"%s\",\n",
			bench486_profile_coarse_mode == 2 ? "components-no-premise-counters" :
			bench486_profile_coarse_mode ? "coarse-no-premise-counters" : "detailed");
	Bench486ProfileJsonPrintf (file_handle,
			"  \"profiler\": {\"timer\": \"Sys_FloatTime\", \"timer_reads\": %lu, \"stack_overflows\": %lu, \"bad_leaves\": %lu, \"max_depth\": %lu, \"discarded_scopes\": %lu},\n",
			bench486_profile_timer_reads, bench486_profile_stack_overflows,
			bench486_profile_bad_leaves, bench486_profile_max_depth,
			bench486_profile_discarded_scopes);
	Bench486ProfileJsonPrintf (file_handle,
			"  \"instrumentation\": {\"timer\": \"Sys_FloatTime\", \"read_seconds\": %.9f, \"note\": \"Each scope charges one ENTER read to its parent and one LEAVE read to its own self time. A node's instr_reads is that floor; subtract it from self_seconds before quoting any per-call cost.\"},\n",
			bench486_profile_read_seconds);

	Bench486ProfileJsonPrintf (file_handle, "  \"nodes\": [\n");
	for (child=0 ; child<BENCH486_PROFILE_NODE_COUNT ; child++)
	{
		unsigned long child_reads = Bench486ProfileChildReads (child);
		stat = &bench486_profile_stats[child];
		Bench486ProfileJsonPrintf (file_handle,
				"    {\"id\": \"%s\", \"calls\": %lu, \"inclusive_seconds\": %.6f, \"self_seconds\": %.6f, \"work_items\": %lu, \"work_bytes\": %lu, \"instr_reads\": %lu}%s\n",
				bench486_profile_node_names[child], stat->calls,
				stat->inclusive_seconds, stat->self_seconds,
				stat->work_items, stat->work_bytes,
				(unsigned long)stat->calls + child_reads,
				child + 1 == BENCH486_PROFILE_NODE_COUNT ? "" : ",");
	}
	Bench486ProfileJsonPrintf (file_handle, "  ],\n");

	Bench486ProfileJsonPrintf (file_handle, "  \"edges\": [\n");
	first = true;
	for (parent=0 ; parent<=BENCH486_PROFILE_ROOT ; parent++)
	{
		for (child=0 ; child<BENCH486_PROFILE_NODE_COUNT ; child++)
		{
			edge = &bench486_profile_edges[parent][child];
			if (!edge->calls)
				continue;
			if (!first)
				Bench486ProfileJsonPrintf (file_handle, ",\n");
			first = false;
			if (parent == BENCH486_PROFILE_ROOT)
			{
				Bench486ProfileJsonPrintf (file_handle,
						"    {\"parent\": null, \"child\": \"%s\", \"calls\": %lu, \"inclusive_seconds\": %.6f, \"self_seconds\": %.6f}",
						bench486_profile_node_names[child], edge->calls,
						edge->inclusive_seconds, edge->self_seconds);
			}
			else
			{
				Bench486ProfileJsonPrintf (file_handle,
						"    {\"parent\": \"%s\", \"child\": \"%s\", \"calls\": %lu, \"inclusive_seconds\": %.6f, \"self_seconds\": %.6f}",
						bench486_profile_node_names[parent],
						bench486_profile_node_names[child], edge->calls,
						edge->inclusive_seconds, edge->self_seconds);
			}
		}
	}
	Bench486ProfileJsonPrintf (file_handle, "\n  ],\n");

	Bench486ProfileJsonPrintf (file_handle,
			"  \"memory\": {\"memset_calls\": %lu, \"memset_bytes\": %lu, \"memset_aligned_calls\": %lu, \"memcpy_calls\": %lu, \"memcpy_bytes\": %lu, \"memcpy_same_alignment_calls\": %lu},\n",
			bench486_memset_calls, bench486_memset_bytes,
			bench486_memset_aligned_calls, bench486_memcpy_calls,
			bench486_memcpy_bytes, bench486_memcpy_same_alignment_calls);

	Bench486ProfileJsonPrintf (file_handle,
			"  \"allocator\": {\"zone_malloc_calls\": %lu, \"zone_malloc_bytes\": %lu, \"zone_check_calls\": %lu, \"zone_check_blocks\": %lu, \"zone_scan_iterations\": %lu, \"zone_splits\": %lu, \"zone_coalesces\": %lu, \"zone_failed_allocations\": %lu, \"hunk_low_calls\": %lu, \"hunk_low_bytes\": %lu, \"hunk_high_calls\": %lu, \"hunk_high_bytes\": %lu, \"cache_checks\": %lu, \"cache_hits\": %lu, \"cache_misses\": %lu, \"cache_lru_relinks\": %lu, \"cache_allocations\": %lu, \"cache_frees\": %lu, \"cache_evictions\": %lu, \"cache_tryalloc_scans\": %lu, \"cache_tryalloc_failures\": %lu, \"cache_moves\": %lu, \"cache_move_bytes\": %lu},\n",
			bench486_zone_malloc_calls, bench486_zone_malloc_bytes,
			bench486_zone_check_calls, bench486_zone_check_blocks,
			bench486_zone_scan_iterations, bench486_zone_splits,
			bench486_zone_coalesces, bench486_zone_failed_allocations,
			bench486_hunk_low_calls, bench486_hunk_low_bytes,
			bench486_hunk_high_calls, bench486_hunk_high_bytes,
			bench486_cache_checks, bench486_cache_hits, bench486_cache_misses,
			bench486_cache_lru_relinks, bench486_cache_allocations,
			bench486_cache_frees, bench486_cache_evictions,
			bench486_cache_tryalloc_scans, bench486_cache_tryalloc_failures,
			bench486_cache_moves, bench486_cache_move_bytes);

	Bench486ProfileJsonPrintf (file_handle,
			"  \"surface_cache\": {\"hits\": %lu, \"rebuilds\": %lu, \"immutable_rebuilds\": %lu, \"allocations\": %lu, \"wraps\": %lu, \"invalidated_blocks\": %lu, \"requested_bytes\": %lu, \"reclaimed_bytes\": %lu, \"thrash_frames\": %lu, ",
			bench486_surface_cache_hits, bench486_surface_cache_rebuilds,
			bench486_surface_cache_immutable_rebuilds,
			bench486_surface_cache_allocations, bench486_surface_cache_wraps,
			bench486_surface_cache_invalidated_blocks,
			bench486_surface_cache_requested_bytes,
			bench486_surface_cache_reclaimed_bytes,
			bench486_surface_cache_thrash_frames);
	Bench486ProfileJsonPrintf (file_handle,
			"\"dlight_probes\": %lu, \"dlight_contributing_probes\": %lu, \"draw_calls\": %lu, ",
			bench486_surface_cache_dlight_probes,
			bench486_surface_cache_dlight_contributing_probes,
			bench486_surface_cache_draw_calls);
	Bench486ProfileJsonPrintf (file_handle,
			"\"hit_seconds\": %.6f, \"miss_check_seconds\": %.6f, \"rebuild_seconds\": %.6f, \"dlight_probe_seconds\": %.6f, \"draw_seconds\": %.6f, \"alloc_seconds\": %.6f, \"lightmap_seconds\": %.6f, \"block_seconds\": %.6f, ",
			bench486_surface_cache_hit_seconds,
			bench486_surface_cache_miss_check_seconds,
			bench486_surface_cache_rebuild_seconds,
			bench486_surface_cache_dlight_probe_seconds,
			bench486_surface_cache_draw_seconds,
			bench486_surface_cache_alloc_seconds,
			bench486_surface_cache_lightmap_seconds,
			bench486_surface_cache_block_seconds);
	Bench486ProfileJsonPrintf (file_handle,
			"\"mip_calls\": [%lu, %lu, %lu, %lu], \"mip_blocks\": [%lu, %lu, %lu, %lu], ",
			bench486_surface_cache_mip_calls[0],
			bench486_surface_cache_mip_calls[1],
			bench486_surface_cache_mip_calls[2],
			bench486_surface_cache_mip_calls[3],
			bench486_surface_cache_mip_blocks[0],
			bench486_surface_cache_mip_blocks[1],
			bench486_surface_cache_mip_blocks[2],
			bench486_surface_cache_mip_blocks[3]);
	Bench486ProfileJsonPrintf (file_handle,
			"\"mip_seconds\": [%.6f, %.6f, %.6f, %.6f], ",
			bench486_surface_cache_mip_seconds[0],
			bench486_surface_cache_mip_seconds[1],
			bench486_surface_cache_mip_seconds[2],
			bench486_surface_cache_mip_seconds[3]);
	Bench486ProfileJsonPrintf (file_handle,
			"\"flat_blocks\": %lu, \"horizontal_flat_blocks\": %lu, \"vertical_flat_blocks\": %lu, ",
			bench486_surface_cache_flat_blocks,
			bench486_surface_cache_horizontal_flat_blocks,
			bench486_surface_cache_vertical_flat_blocks);
	Bench486ProfileJsonPrintf (file_handle,
			"\"blocks_per_mip\": [%lu, %lu, %lu, %lu], "
			"\"horizontal_flat_per_mip\": [%lu, %lu, %lu, %lu], "
			"\"fully_flat_per_mip\": [%lu, %lu, %lu, %lu]},\n",
			bench486_surface_cache_mip_blocks_flat[0],
			bench486_surface_cache_mip_blocks_flat[1],
			bench486_surface_cache_mip_blocks_flat[2],
			bench486_surface_cache_mip_blocks_flat[3],
			bench486_surface_cache_horizontal_flat_per_mip[0],
			bench486_surface_cache_horizontal_flat_per_mip[1],
			bench486_surface_cache_horizontal_flat_per_mip[2],
			bench486_surface_cache_horizontal_flat_per_mip[3],
			bench486_surface_cache_flat_blocks_per_mip[0],
			bench486_surface_cache_flat_blocks_per_mip[1],
			bench486_surface_cache_flat_blocks_per_mip[2],
			bench486_surface_cache_flat_blocks_per_mip[3]);

	Bench486ProfileJsonPrintf (file_handle,
			"  \"platform\": {\"joystick_reads\": %lu, \"joystick_poll_iterations\": %lu, \"joystick_timeouts\": %lu, \"move_calls\": %lu, \"hull_check_calls\": %lu},\n",
			bench486_joystick_reads, bench486_joystick_poll_iterations,
			bench486_joystick_timeouts, bench486_move_calls,
			bench486_hull_check_calls);

	Bench486ProfileJsonPrintf (file_handle,
			"  \"edge_iters\": {\"insert\": %lu, \"remove\": %lu, \"step\": %lu, \"pushback\": %lu, \"sort\": %lu, \"emit\": %lu, \"genspans\": %lu, \"bmodel_zsort\": %lu, \"trailing\": %lu},\n",
			bench486_edge_insert_iters, bench486_edge_remove_iters,
			bench486_edge_step_iters, bench486_edge_pushback_iters,
			bench486_edge_sort_iters, bench486_edge_emit_blocks,
			bench486_edge_genspans_edges, bench486_edge_bmodel_zsort,
			bench486_edge_trailing_calls);

	Bench486ProfileJsonPrintf (file_handle,
			"  \"edge_dispatch\": {\"leading\": %lu, \"bmodel_leading\": %lu, \"bmodel_trailing\": %lu, \"insert_exit\": %lu, \"newtop\": %lu, \"xldone\": %lu, \"lastspan\": %lu, \"reset_iters\": %lu},\n",
			bench486_edge_leading, bench486_edge_bmodel_leading,
			bench486_edge_bmodel_trailing, bench486_edge_insert_exit,
			bench486_edge_newtop, bench486_edge_xldone,
			bench486_edge_lastspan, bench486_edge_reset_iters);

	Bench486ProfileJsonPrintf (file_handle,
			"  \"metrics\": {\n"
			"    \"frames\": %lu, \"bsp_nodes\": %lu, \"bsp_solid_culls\": %lu, \"bsp_visibility_culls\": %lu, \"bsp_leaf_nodes\": %lu, \"bsp_internal_nodes\": %lu, \"bsp_surface_tests\": %lu,\n"
			"    \"scanlines\": %lu, \"edge_insert_calls\": %lu, \"edge_remove_calls\": %lu, \"edge_step_calls\": %lu, \"span_flushes\": %lu,\n"
			"    \"surfaces\": %lu, \"surface_drawn\": %lu, \"surface_span_count\": %lu, \"surface_span_pixels\": %lu, \"surface_span_segments\": %lu, \"surface_sky\": %lu, \"surface_background\": %lu, \"surface_turbulent\": %lu, \"surface_normal\": %lu, \"surface_solid\": %lu,\n"
			"    \"texture_spans\": %lu, \"texture_span_same_row_links\": %lu, \"texture_pixels\": %lu, \"texture_segments\": %lu, \"alias_models\": %lu, \"alias_vertices\": %lu, \"particles\": %lu, \"gib_trail_particles\": %lu,\n"
			"    \"present_rects\": %lu, \"present_pixels\": %lu, \"sound_updates\": %lu, \"sound_mixes\": %lu,\n"
			"    \"renderface_calls\": %lu, \"renderface_emitted\": %lu, \"clipedge_calls\": %lu, \"clipedge_plane_tests\": %lu, \"clipedge_fully_clipped\": %lu, \"clipvert_clips\": %lu, \"emitcachededge_calls\": %lu,\n"
			"    \"clipvertex_world_endpoint_uses\": %lu, \"clipvertex_world_unique_uses\": %lu,\n"
			"    \"texture_span_buckets\": [%lu, %lu, %lu, %lu, %lu],\n"
			"    \"texture_widths\": [%lu, %lu, %lu, %lu, %lu, %lu, %lu, %lu, %lu, %lu, %lu, %lu, %lu, %lu, %lu, %lu, %lu],\n"
			"    \"texture_final_lengths\": [%lu, %lu, %lu, %lu, %lu, %lu, %lu, %lu, %lu, %lu, %lu, %lu, %lu, %lu, %lu, %lu, %lu],\n"
			"    \"texture_full\": {\"tzero\": %lu, \"tdelta_zero\": %lu, \"tfrac_zero\": %lu, \"sfrac_zero\": %lu, \"sone\": %lu, \"exact\": %lu, \"final_exact\": %lu, \"row_eligible\": %lu, \"row_fast\": %lu},\n"
			"    \"span_strides\": {\"segments\": %lu, \"unit_stride_segments\": %lu, \"unit_stride_pixels\": %lu},\n"
			"    \"texture_tail\": {\"zero_tstep_segments\": %lu, \"zero_tstep_samples\": %lu}\n"
			"  },\n",
			bench486_profile_frames, bench486_bsp_nodes,
			bench486_bsp_solid_culls, bench486_bsp_visibility_culls,
			bench486_bsp_leaf_nodes, bench486_bsp_internal_nodes,
			bench486_bsp_surface_tests, bench486_scanlines,
			bench486_edge_insert_calls, bench486_edge_remove_calls,
			bench486_edge_step_calls, bench486_span_flushes,
			bench486_surface_count, bench486_surface_drawn, bench486_surface_span_count,
			bench486_surface_span_pixels, bench486_surface_span_segments,
			bench486_surface_sky_count, bench486_surface_background_count,
			bench486_surface_turbulent_count, bench486_surface_normal_count,
			bench486_surface_solid_count,
			bench486_texture_span_count, bench486_texture_span_same_row_links,
			bench486_texture_span_pixels,
			bench486_texture_span_segments, bench486_alias_models,
			bench486_alias_vertices, bench486_particle_count,
			bench486_gib_trail_particles,
			bench486_present_rects, bench486_present_pixels,
			bench486_sound_update_calls, bench486_sound_mix_calls,
			bench486_renderface_calls, bench486_renderface_emitted,
			bench486_clipedge_calls, bench486_clipedge_plane_tests,
			bench486_clipedge_fully_clipped, bench486_clipvert_clips,
			bench486_emitcachededge_calls,
			bench486_clipvertex_world_endpoint_uses,
			bench486_clipvertex_world_unique_uses,
			bench486_texture_span_buckets[0], bench486_texture_span_buckets[1],
			bench486_texture_span_buckets[2], bench486_texture_span_buckets[3],
			bench486_texture_span_buckets[4],
			bench486_texture_widths[0], bench486_texture_widths[1],
			bench486_texture_widths[2], bench486_texture_widths[3],
			bench486_texture_widths[4], bench486_texture_widths[5],
			bench486_texture_widths[6], bench486_texture_widths[7],
			bench486_texture_widths[8], bench486_texture_widths[9],
			bench486_texture_widths[10], bench486_texture_widths[11],
			bench486_texture_widths[12], bench486_texture_widths[13],
			bench486_texture_widths[14], bench486_texture_widths[15],
			bench486_texture_widths[16],
			bench486_texture_final_lengths[0], bench486_texture_final_lengths[1],
			bench486_texture_final_lengths[2], bench486_texture_final_lengths[3],
			bench486_texture_final_lengths[4], bench486_texture_final_lengths[5],
			bench486_texture_final_lengths[6], bench486_texture_final_lengths[7],
			bench486_texture_final_lengths[8], bench486_texture_final_lengths[9],
			bench486_texture_final_lengths[10], bench486_texture_final_lengths[11],
			bench486_texture_final_lengths[12], bench486_texture_final_lengths[13],
			bench486_texture_final_lengths[14], bench486_texture_final_lengths[15],
			bench486_texture_final_lengths[16],
			bench486_texture_full_tzero, bench486_texture_full_tdelta_zero,
			bench486_texture_full_tfrac_zero, bench486_texture_full_sfrac_zero,
			bench486_texture_full_sone, bench486_texture_full_exact,
			bench486_texture_final_exact, bench486_texture_full_row_eligible,
			bench486_texture_full_row_fast, bench486_span_segments,
			bench486_span_unit_stride_segments,
			bench486_span_unit_stride_pixels,
			bench486_texture_tail_tstep_zero_segments,
			bench486_texture_tail_tstep_zero_samples);
	Bench486ProfileJsonPrintf (file_handle,
			"  \"clipvertex_plane_distance_reuse\": {"
			"\"uses_by_plane\": [%lu, %lu, %lu, %lu], "
			"\"unique_by_plane\": [%lu, %lu, %lu, %lu], "
			"\"hits_by_plane\": [%lu, %lu, %lu, %lu]},\n"
			"  \"clipvertex_plane_lru_cache\": {"
			"\"uses_by_plane\": [%lu, %lu, %lu, %lu], "
			"\"hits_by_plane\": [%lu, %lu, %lu, %lu]},\n",
			bench486_clipvertex_plane_distance_uses[0],
			bench486_clipvertex_plane_distance_uses[1],
			bench486_clipvertex_plane_distance_uses[2],
			bench486_clipvertex_plane_distance_uses[3],
			bench486_clipvertex_plane_distance_unique[0],
			bench486_clipvertex_plane_distance_unique[1],
			bench486_clipvertex_plane_distance_unique[2],
			bench486_clipvertex_plane_distance_unique[3],
			bench486_clipvertex_plane_distance_hits[0],
			bench486_clipvertex_plane_distance_hits[1],
			bench486_clipvertex_plane_distance_hits[2],
			bench486_clipvertex_plane_distance_hits[3],
			bench486_clipvertex_plane_lru_uses[0],
			bench486_clipvertex_plane_lru_uses[1],
			bench486_clipvertex_plane_lru_uses[2],
			bench486_clipvertex_plane_lru_uses[3],
			bench486_clipvertex_plane_lru_hits[0],
			bench486_clipvertex_plane_lru_hits[1],
			bench486_clipvertex_plane_lru_hits[2],
			bench486_clipvertex_plane_lru_hits[3]);
	Bench486ProfileJsonPrintf (file_handle,
			"  \"clipvertex_plane_direct_cache_hits_by_slots\": {"
			"\"8\": [%lu, %lu, %lu, %lu], "
			"\"16\": [%lu, %lu, %lu, %lu], "
			"\"32\": [%lu, %lu, %lu, %lu], "
			"\"64\": [%lu, %lu, %lu, %lu], "
			"\"128\": [%lu, %lu, %lu, %lu], "
			"\"256\": [%lu, %lu, %lu, %lu]},\n",
			bench486_clipvertex_plane_cache_hits[0][0],
			bench486_clipvertex_plane_cache_hits[0][1],
			bench486_clipvertex_plane_cache_hits[0][2],
			bench486_clipvertex_plane_cache_hits[0][3],
			bench486_clipvertex_plane_cache_hits[1][0],
			bench486_clipvertex_plane_cache_hits[1][1],
			bench486_clipvertex_plane_cache_hits[1][2],
			bench486_clipvertex_plane_cache_hits[1][3],
			bench486_clipvertex_plane_cache_hits[2][0],
			bench486_clipvertex_plane_cache_hits[2][1],
			bench486_clipvertex_plane_cache_hits[2][2],
			bench486_clipvertex_plane_cache_hits[2][3],
			bench486_clipvertex_plane_cache_hits[3][0],
			bench486_clipvertex_plane_cache_hits[3][1],
			bench486_clipvertex_plane_cache_hits[3][2],
			bench486_clipvertex_plane_cache_hits[3][3],
			bench486_clipvertex_plane_cache_hits[4][0],
			bench486_clipvertex_plane_cache_hits[4][1],
			bench486_clipvertex_plane_cache_hits[4][2],
			bench486_clipvertex_plane_cache_hits[4][3],
			bench486_clipvertex_plane_cache_hits[5][0],
			bench486_clipvertex_plane_cache_hits[5][1],
			bench486_clipvertex_plane_cache_hits[5][2],
			bench486_clipvertex_plane_cache_hits[5][3]);
	Bench486ProfileJsonPrintf (file_handle,
			"  \"clipvertex_plane_cache_world_pairs_by_plane\": "
			"[%lu, %lu, %lu, %lu],\n"
			"  \"clipvertex_plane_direct_cache_pair_hits_by_slots\": {"
			"\"8\": [%lu, %lu, %lu, %lu], "
			"\"16\": [%lu, %lu, %lu, %lu], "
			"\"32\": [%lu, %lu, %lu, %lu], "
			"\"64\": [%lu, %lu, %lu, %lu], "
			"\"128\": [%lu, %lu, %lu, %lu], "
			"\"256\": [%lu, %lu, %lu, %lu]}\n}\n",
			bench486_clipvertex_plane_world_pair_uses[0],
			bench486_clipvertex_plane_world_pair_uses[1],
			bench486_clipvertex_plane_world_pair_uses[2],
			bench486_clipvertex_plane_world_pair_uses[3],
			bench486_clipvertex_plane_cache_pair_hits[0][0],
			bench486_clipvertex_plane_cache_pair_hits[0][1],
			bench486_clipvertex_plane_cache_pair_hits[0][2],
			bench486_clipvertex_plane_cache_pair_hits[0][3],
			bench486_clipvertex_plane_cache_pair_hits[1][0],
			bench486_clipvertex_plane_cache_pair_hits[1][1],
			bench486_clipvertex_plane_cache_pair_hits[1][2],
			bench486_clipvertex_plane_cache_pair_hits[1][3],
			bench486_clipvertex_plane_cache_pair_hits[2][0],
			bench486_clipvertex_plane_cache_pair_hits[2][1],
			bench486_clipvertex_plane_cache_pair_hits[2][2],
			bench486_clipvertex_plane_cache_pair_hits[2][3],
			bench486_clipvertex_plane_cache_pair_hits[3][0],
			bench486_clipvertex_plane_cache_pair_hits[3][1],
			bench486_clipvertex_plane_cache_pair_hits[3][2],
			bench486_clipvertex_plane_cache_pair_hits[3][3],
			bench486_clipvertex_plane_cache_pair_hits[4][0],
			bench486_clipvertex_plane_cache_pair_hits[4][1],
			bench486_clipvertex_plane_cache_pair_hits[4][2],
			bench486_clipvertex_plane_cache_pair_hits[4][3],
			bench486_clipvertex_plane_cache_pair_hits[5][0],
			bench486_clipvertex_plane_cache_pair_hits[5][1],
			bench486_clipvertex_plane_cache_pair_hits[5][2],
			bench486_clipvertex_plane_cache_pair_hits[5][3]);
	Sys_FileClose (file_handle);
}

void Bench486ResetTimedemoCounters (void)
{
	int i;

	Bench486ProfileReset ();
	bench486_profile_frame_active = false;
	bench486_profile_frames = 0;
	bench486_frame_seconds = 0;
	bench486_render_seconds = 0;
	bench486_visibility_seconds = 0;
	bench486_world_seconds = 0;
	bench486_edge_scan_seconds = 0;
	bench486_surface_cache_seconds = 0;
	bench486_surface_cache_hit_seconds = 0;
	bench486_surface_cache_miss_check_seconds = 0;
	bench486_surface_cache_rebuild_seconds = 0;
	bench486_surface_cache_dlight_probe_seconds = 0;
	bench486_surface_cache_draw_seconds = 0;
	bench486_surface_cache_alloc_seconds = 0;
	bench486_surface_cache_lightmap_seconds = 0;
	bench486_surface_cache_block_seconds = 0;
	bench486_span_draw_seconds = 0;
	bench486_sound_seconds = 0;
	bench486_framebuffer_seconds = 0;
	bench486_alias_models = 0;
	bench486_alias_vertices = 0;
	bench486_alias_occlusion_queries = 0;
	bench486_alias_occlusion_culls = 0;
	bench486_alias_occlusion_tiles = 0;
	bench486_alias_occlusion_z_samples = 0;
	bench486_surface_count = 0;
	bench486_surface_drawn = 0;
	bench486_surface_cache_hits = 0;
	bench486_surface_cache_rebuilds = 0;
	bench486_surface_cache_immutable_rebuilds = 0;
	bench486_submodel_calls = 0;
	bench486_submodel_faces = 0;
	bench486_submodel_distinct_entities = 0;
	bench486_submodel_entity_hits = 0;
	bench486_submodel_table_overwrites = 0;
	bench486_bpoly_clip_edges = 0;
	bench486_bpoly_adjacent_endpoint_hits = 0;
	bench486_bpoly_plane_cache_hits = 0;
	bench486_bpoly_plane_cache_misses = 0;
	memset (bench486_submodel_entity_table, 0, sizeof (bench486_submodel_entity_table));
	bench486_turbulent_rows = 0;
	bench486_turbulent_chunks = 0;
	bench486_turbulent_pixels = 0;
	bench486_surface_cache_dlight_probes = 0;
	bench486_surface_cache_dlight_contributing_probes = 0;
	bench486_surface_cache_draw_calls = 0;
	bench486_surface_cache_flat_blocks = 0;
	bench486_surface_cache_horizontal_flat_blocks = 0;
	for (i=0 ; i<4 ; i++)
	{
		bench486_surface_cache_flat_blocks_per_mip[i] = 0;
		bench486_surface_cache_horizontal_flat_per_mip[i] = 0;
		bench486_surface_cache_mip_blocks_flat[i] = 0;
	}
	bench486_surface_cache_vertical_flat_blocks = 0;
	bench486_surface_cache_allocations = 0;
	bench486_surface_cache_wraps = 0;
	bench486_surface_cache_invalidated_blocks = 0;
	bench486_surface_cache_requested_bytes = 0;
	bench486_surface_cache_reclaimed_bytes = 0;
	bench486_surface_cache_thrash_frames = 0;
	bench486_texture_span_count = 0;
	bench486_texture_span_same_row_links = 0;
	bench486_texture_span_pixels = 0;
	bench486_texture_span_segments = 0;
	bench486_texture_span_buckets[0] = 0;
	bench486_texture_span_buckets[1] = 0;
	bench486_texture_span_buckets[2] = 0;
	bench486_texture_span_buckets[3] = 0;
	bench486_texture_span_buckets[4] = 0;
	bench486_renderface_calls = 0;
	bench486_renderface_general_edges = 0;
	bench486_renderface_emitted = 0;
	bench486_renderface_edge_setups = 0;
	bench486_renderface_early_surfs = 0;
	bench486_renderface_early_edges = 0;
	bench486_renderface_faces = 0;
	bench486_renderface_clipchain_builds = 0;
	bench486_renderface_clipchain_cache_hits = 0;
	bench486_clipedge_calls = 0;
	bench486_clipedge_plane_tests = 0;
	bench486_clipedge_fully_clipped = 0;
	bench486_emitcachededge_calls = 0;
	bench486_clipvert_clips = 0;
	bench486_clipvertex_world_endpoint_uses = 0;
	bench486_clipvertex_world_unique_uses = 0;
	memset (bench486_clipvertex_seen_world, 0,
			sizeof(bench486_clipvertex_seen_world));
	memset (bench486_clipvertex_plane_distance_uses, 0,
			sizeof(bench486_clipvertex_plane_distance_uses));
	memset (bench486_clipvertex_plane_distance_unique, 0,
			sizeof(bench486_clipvertex_plane_distance_unique));
	memset (bench486_clipvertex_plane_distance_hits, 0,
			sizeof(bench486_clipvertex_plane_distance_hits));
	memset (bench486_clipvertex_plane_seen, 0,
			sizeof(bench486_clipvertex_plane_seen));
	memset (bench486_clipvertex_plane_world_pair_uses, 0,
			sizeof(bench486_clipvertex_plane_world_pair_uses));
	memset (bench486_clipvertex_plane_lru_uses, 0,
			sizeof(bench486_clipvertex_plane_lru_uses));
	memset (bench486_clipvertex_plane_lru_hits, 0,
			sizeof(bench486_clipvertex_plane_lru_hits));
	memset (bench486_clipvertex_plane_lru_vertex, 0,
			sizeof(bench486_clipvertex_plane_lru_vertex));
	memset (bench486_clipvertex_plane_cache_hits, 0,
			sizeof(bench486_clipvertex_plane_cache_hits));
	memset (bench486_clipvertex_plane_cache_pair_hits, 0,
			sizeof(bench486_clipvertex_plane_cache_pair_hits));
	memset (bench486_clipvertex_plane_cache_tags, 0,
			sizeof(bench486_clipvertex_plane_cache_tags));
	bench486_clipvertex_world_base = 0;
	bench486_clipvertex_world_bytes = 0;
	for (i=0 ; i<17 ; i++)
	{
		bench486_texture_widths[i] = 0;
		bench486_texture_final_lengths[i] = 0;
	}
	for (i=0 ; i<4 ; i++)
	{
		bench486_surface_cache_mip_calls[i] = 0;
		bench486_surface_cache_mip_blocks[i] = 0;
		bench486_surface_cache_mip_seconds[i] = 0;
	}
	bench486_texture_full_tzero = 0;
	bench486_texture_full_tdelta_zero = 0;
	bench486_texture_full_tfrac_zero = 0;
	bench486_texture_full_sfrac_zero = 0;
	bench486_texture_full_sone = 0;
	bench486_texture_full_exact = 0;
	bench486_texture_final_exact = 0;
	bench486_texture_full_row_eligible = 0;
	bench486_texture_full_row_fast = 0;
	bench486_texture_tail_tstep_zero_segments = 0;
	bench486_texture_tail_tstep_zero_samples = 0;
	bench486_span_segments = 0;
	bench486_zspan_pixels = 0;
	bench486_zspan_spans = 0;
	bench486_zspan_constant_runs = 0;
	bench486_zspan_constant_pixels = 0;
	bench486_lm_single_texels = 0;
	bench486_lm_fused_texels = 0;
	{
		int lm_i;
		for (lm_i = 0; lm_i < 5; lm_i++) bench486_lm_fused_maps[lm_i] = 0;
	}
	bench486_span_unit_stride_segments = 0;
	bench486_span_unit_stride_pixels = 0;
	bench486_surf8_flat_rows = 0;
	bench486_surf8_flat_dh_moved = 0;
	bench486_gradient_calls = 0;
	bench486_solid_span_count = 0;
	bench486_memset_calls = 0;
	bench486_memset_bytes = 0;
	bench486_memset_aligned_calls = 0;
	bench486_memcpy_calls = 0;
	bench486_memcpy_bytes = 0;
	bench486_memcpy_same_alignment_calls = 0;
	bench486_line_setup_calls = 0;
	bench486_axis_cache_hits = 0;
	bench486_axis_cache_misses = 0;
	bench486_bsp_nodes = 0;
	bench486_bsp_solid_culls = 0;
	bench486_bsp_visibility_culls = 0;
	bench486_bsp_leaf_nodes = 0;
	bench486_bsp_internal_nodes = 0;
	bench486_bsp_surface_tests = 0;
	bench486_scanlines = 0;
	bench486_edge_insert_calls = 0;
	bench486_edge_remove_calls = 0;
	bench486_edge_step_calls = 0;
	bench486_span_flushes = 0;
	bench486_edge_insert_iters = 0;
	bench486_edge_remove_iters = 0;
	bench486_edge_step_iters = 0;
	bench486_edge_pushback_iters = 0;
	bench486_edge_sort_iters = 0;
	bench486_edge_emit_blocks = 0;
	bench486_edge_genspans_edges = 0;
	bench486_edge_bmodel_zsort = 0;
	bench486_edge_trailing_calls = 0;
	bench486_edge_leading = 0;
	bench486_edge_bmodel_leading = 0;
	bench486_edge_bmodel_trailing = 0;
	bench486_edge_insert_exit = 0;
	bench486_edge_newtop = 0;
	bench486_edge_xldone = 0;
	bench486_edge_lastspan = 0;
	bench486_edge_reset_iters = 0;
	bench486_surface_span_count = 0;
	bench486_surface_span_pixels = 0;
	bench486_surface_span_segments = 0;
	bench486_surface_sky_count = 0;
	bench486_surface_background_count = 0;
	bench486_surface_turbulent_count = 0;
	bench486_surface_normal_count = 0;
	bench486_surface_solid_count = 0;
	bench486_present_rects = 0;
	bench486_present_pixels = 0;
	bench486_sound_update_calls = 0;
	bench486_sound_mix_calls = 0;
	bench486_joystick_reads = 0;
	bench486_joystick_poll_iterations = 0;
	bench486_joystick_timeouts = 0;
	bench486_move_calls = 0;
	bench486_hull_check_calls = 0;
	bench486_alias_seconds = 0;
	bench486_surface_seconds = 0;
	bench486_turbulent_seconds = 0;
	bench486_particle_count = 0;
	bench486_gib_trail_particles = 0;
	bench486_particle_seconds = 0;
}

void Bench486BeginTimedemoProfile (void)
{
	memset (bench486_clipvertex_seen_world, 0,
			sizeof(bench486_clipvertex_seen_world));
	bench486_profile_frame_active = !bench486_profile_coarse_mode;
	bench486_profile_coarse_active = bench486_profile_coarse_mode;
	Bench486ProfileEnter (BENCH486_PROFILE_FRAME);
	/* Activation occurs inside client-read inside game; neither enclosing
	 * scope entered while profiling was active. Skip both unmatched leaves. */
	bench486_profile_pending_leaves = 2;
}

void Bench486ProfileClipVertexFrameStart (void)
{
	if (!bench486_profile_frame_active)
		return;
	memset (bench486_clipvertex_seen_world, 0,
			sizeof(bench486_clipvertex_seen_world));
	memset (bench486_clipvertex_plane_seen, 0,
			sizeof(bench486_clipvertex_plane_seen));
	memset (bench486_clipvertex_plane_lru_vertex, 0,
			sizeof(bench486_clipvertex_plane_lru_vertex));
	memset (bench486_clipvertex_plane_cache_tags, 0,
			sizeof(bench486_clipvertex_plane_cache_tags));
	if (cl.worldmodel && cl.worldmodel->vertexes &&
		cl.worldmodel->numvertexes > 0)
	{
		bench486_clipvertex_world_base =
				(unsigned long)cl.worldmodel->vertexes;
		bench486_clipvertex_world_bytes =
				(unsigned long)cl.worldmodel->numvertexes * sizeof(mvertex_t);
	}
	else
	{
		bench486_clipvertex_world_base = 0;
		bench486_clipvertex_world_bytes = 0;
	}
}

void Bench486ProfileClipPlaneEndpoints (mvertex_t *pv0, mvertex_t *pv1,
		clipplane_t *clip)
{
	mvertex_t *endpoints[2];
	unsigned long plane_address, plane_base, plane_offset, plane_index;
	unsigned long vertex_address, vertex_offset, vertex_index, bit;
	unsigned long *seen_word;
	unsigned long cache_slot;
	unsigned long endpoint_addresses[2];
	unsigned long endpoint_vertex_indices[2];
	unsigned long cache_slots[2][BENCH486_CLIP_VERTEX_CACHE_LEVELS];
	int endpoint_is_world[2];
	int i, cache_level;

	if (!bench486_profile_frame_active || !bench486_clipvertex_world_base ||
		!bench486_clipvertex_world_bytes)
		return;

	plane_address = (unsigned long)clip;
	plane_base = (unsigned long)&view_clipplanes[0];
	if (plane_address < plane_base)
		return;
	plane_offset = plane_address - plane_base;
	if (plane_offset % sizeof(clipplane_t))
		return;
	plane_index = plane_offset / sizeof(clipplane_t);
	if (plane_index >= 4)
		return;

	endpoints[0] = pv0;
	endpoints[1] = pv1;
	for (i=0 ; i<2 ; i++)
	{
		endpoint_is_world[i] = 0;
		vertex_address = (unsigned long)endpoints[i];
		if (vertex_address < bench486_clipvertex_world_base)
			continue;
		vertex_offset = vertex_address - bench486_clipvertex_world_base;
		if (vertex_offset >= bench486_clipvertex_world_bytes ||
			vertex_offset % sizeof(mvertex_t))
			continue;
		vertex_index = vertex_offset / sizeof(mvertex_t);
		if (vertex_index >= 65536UL)
			continue;

		endpoint_is_world[i] = 1;
		endpoint_addresses[i] = vertex_address;
		endpoint_vertex_indices[i] = vertex_index;
		for (cache_level=0 ;
				cache_level<BENCH486_CLIP_VERTEX_CACHE_LEVELS;
				cache_level++)
			cache_slots[i][cache_level] =
					bench486_clipvertex_cache_bases[cache_level] +
					(vertex_index &
					(bench486_clipvertex_cache_sizes[cache_level] - 1));
	}

	if (endpoint_is_world[0] && endpoint_is_world[1])
	{
		bench486_clipvertex_plane_world_pair_uses[plane_index]++;
		for (cache_level=0 ;
				cache_level<BENCH486_CLIP_VERTEX_CACHE_LEVELS;
				cache_level++)
		{
			if (bench486_clipvertex_plane_cache_tags[plane_index]
					[cache_slots[0][cache_level]] == endpoint_addresses[0] &&
				bench486_clipvertex_plane_cache_tags[plane_index]
					[cache_slots[1][cache_level]] == endpoint_addresses[1])
				bench486_clipvertex_plane_cache_pair_hits[cache_level]
						[plane_index]++;
		}
	}

	for (i=0 ; i<2 ; i++)
	{
		if (!endpoint_is_world[i])
			continue;
		vertex_address = endpoint_addresses[i];
		vertex_index = endpoint_vertex_indices[i];
		bench486_clipvertex_plane_distance_uses[plane_index]++;
		bench486_clipvertex_plane_lru_uses[plane_index]++;
		if (bench486_clipvertex_plane_lru_vertex[plane_index] == vertex_address)
			bench486_clipvertex_plane_lru_hits[plane_index]++;
		bench486_clipvertex_plane_lru_vertex[plane_index] = vertex_address;
		seen_word = &bench486_clipvertex_plane_seen[plane_index]
				[vertex_index >> 5];
		bit = 1UL << (vertex_index & 31);
		if (*seen_word & bit)
			bench486_clipvertex_plane_distance_hits[plane_index]++;
		else
		{
			*seen_word |= bit;
			bench486_clipvertex_plane_distance_unique[plane_index]++;
		}

		for (cache_level=0 ;
				cache_level<BENCH486_CLIP_VERTEX_CACHE_LEVELS;
				cache_level++)
		{
			cache_slot = cache_slots[i][cache_level];
			if (bench486_clipvertex_plane_cache_tags[plane_index][cache_slot]
					== vertex_address)
				bench486_clipvertex_plane_cache_hits[cache_level][plane_index]++;
			else
				bench486_clipvertex_plane_cache_tags[plane_index][cache_slot] =
						vertex_address;
		}
	}
}
#endif

void Bench486WriteTimedemoCounters (int report_handle, int timedemo_frames,
		float timedemo_seconds)
{
#ifdef PROFILE486
	char text[1024];

	sprintf (text,
			"profile frames %lu frame-sec %.6f render-sec %.6f "
			"visibility-sec %.6f world-sec %.6f edge-scan-sec %.6f "
			"surface-sec %.6f surface-cache-sec %.6f span-draw-sec %.6f "
			"alias-sec %.6f turbulent-sec %.6f particles %lu "
			"gib-trail-particles %lu "
			"particle-sec %.6f sound-sec %.6f framebuffer-sec %.6f "
			"alias-models %lu alias-vertices %lu surfaces %lu "
			"texture-spans %lu texture-pixels %lu texture-segments %lu "
			"span-buckets %lu,%lu,%lu,%lu,%lu "
			"texture-widths %lu,%lu,%lu,%lu,%lu,%lu,%lu,%lu,%lu,%lu,%lu,%lu,%lu,%lu,%lu,%lu,%lu "
			"texture-final-lengths %lu,%lu,%lu,%lu,%lu,%lu,%lu,%lu,%lu,%lu,%lu,%lu,%lu,%lu,%lu,%lu,%lu "
			"full-tzero %lu full-tdelta-zero %lu full-tfrac-zero %lu "
			"full-sfrac-zero %lu full-sone %lu full-exact %lu "
			"final-exact %lu full-row-eligible %lu full-row-fast %lu "
			"gradients %lu solid-spans %lu line-setups %lu "
			"surface-drawn %lu axis-hits %lu axis-misses %lu\n",
			bench486_profile_frames, bench486_frame_seconds,
			bench486_render_seconds, bench486_visibility_seconds,
			bench486_world_seconds, bench486_edge_scan_seconds,
			bench486_surface_seconds, bench486_surface_cache_seconds,
			bench486_span_draw_seconds, bench486_alias_seconds,
			bench486_turbulent_seconds, bench486_particle_count,
			bench486_gib_trail_particles,
			bench486_particle_seconds, bench486_sound_seconds,
			bench486_framebuffer_seconds,
			bench486_alias_models, bench486_alias_vertices,
			bench486_surface_count, bench486_texture_span_count,
			bench486_texture_span_pixels, bench486_texture_span_segments,
			bench486_texture_span_buckets[0],
			bench486_texture_span_buckets[1],
			bench486_texture_span_buckets[2],
			bench486_texture_span_buckets[3],
			bench486_texture_span_buckets[4],
			bench486_texture_widths[0],
			bench486_texture_widths[1],
			bench486_texture_widths[2],
			bench486_texture_widths[3],
			bench486_texture_widths[4],
			bench486_texture_widths[5],
			bench486_texture_widths[6],
			bench486_texture_widths[7],
			bench486_texture_widths[8],
			bench486_texture_widths[9],
			bench486_texture_widths[10],
			bench486_texture_widths[11],
			bench486_texture_widths[12],
			bench486_texture_widths[13],
			bench486_texture_widths[14],
			bench486_texture_widths[15],
			bench486_texture_widths[16],
			bench486_texture_final_lengths[0],
			bench486_texture_final_lengths[1],
			bench486_texture_final_lengths[2],
			bench486_texture_final_lengths[3],
			bench486_texture_final_lengths[4],
			bench486_texture_final_lengths[5],
			bench486_texture_final_lengths[6],
			bench486_texture_final_lengths[7],
			bench486_texture_final_lengths[8],
			bench486_texture_final_lengths[9],
			bench486_texture_final_lengths[10],
			bench486_texture_final_lengths[11],
			bench486_texture_final_lengths[12],
			bench486_texture_final_lengths[13],
			bench486_texture_final_lengths[14],
			bench486_texture_final_lengths[15],
			bench486_texture_final_lengths[16],
			bench486_texture_full_tzero, bench486_texture_full_tdelta_zero,
			bench486_texture_full_tfrac_zero,
			bench486_texture_full_sfrac_zero,
			bench486_texture_full_sone,
			bench486_texture_full_exact, bench486_texture_final_exact,
			bench486_texture_full_row_eligible,
			bench486_texture_full_row_fast, bench486_gradient_calls,
			bench486_solid_span_count, bench486_line_setup_calls,
			bench486_surface_drawn,
			bench486_axis_cache_hits, bench486_axis_cache_misses);
	Con_Printf ("%s", text);
	if (report_handle != -1)
		Sys_FileWrite (report_handle, text, Q_strlen(text));
	// Its own report call, not another field in the block above.  That
	// sprintf targets char text[1024] and already carries 60 conversions; its
	// worst case is about 1,350 bytes, so it is living on the edge of the
	// buffer and three more counters are what tips an instrumented run into a
	// silent abort inside this function (no profile.jsn, checksum line
	// missing).  Counters that are not in that block get their own line.
	sprintf (text,
			"span-strides segments %lu unit-stride-segments %lu "
			"unit-stride-pixels %lu\n",
			bench486_span_segments,
			bench486_span_unit_stride_segments,
			bench486_span_unit_stride_pixels);
	Con_Printf ("%s", text);
	if (report_handle != -1)
		Sys_FileWrite (report_handle, text, Q_strlen(text));
	#ifdef ASM486_ALIAS_GLUE_PROBE
	extern unsigned long bench486_ag_probe_sink;
	extern unsigned long bench486_ag_probe_count;
	// Its own report call: the alias-glue probe's execution count and sink.
	// The count is the probe's denominator, so a probe -O3 folded away reports
	// 0 here instead of producing a plausible wrong number.
	sprintf (text, "alias-glue-probe count %lu sink %lu\n",
			bench486_ag_probe_count, bench486_ag_probe_sink);
	Con_Printf ("%s", text);
	if (report_handle != -1)
		Sys_FileWrite (report_handle, text, Q_strlen(text));
	bench486_ag_probe_sink = 0;
	bench486_ag_probe_count = 0;
#endif
// Its own report call: z-span pixel population, which is the denominator
	// the per-pixel loop has never had.
	sprintf (text,
			"z-spans pixels %lu spans %lu avg %lu constant-runs %lu constant-pixels %lu\n",
			bench486_zspan_pixels, bench486_zspan_spans,
			bench486_zspan_spans ?
				bench486_zspan_pixels / bench486_zspan_spans : 0,
			bench486_zspan_constant_runs, bench486_zspan_constant_pixels);
	Con_Printf ("%s", text);
	if (report_handle != -1)
		Sys_FileWrite (report_handle, text, Q_strlen(text));
	// Its own report call, per the same buffer reason as the block above:
	// lightmap build populations, split by path.
	sprintf (text,
			"lightmap-texels single %lu fused %lu maps2 %lu maps3 %lu maps4 %lu\n",
			bench486_lm_single_texels, bench486_lm_fused_texels,
			bench486_lm_fused_maps[2], bench486_lm_fused_maps[3],
			bench486_lm_fused_maps[4]);
	Con_Printf ("%s", text);
	if (report_handle != -1)
		Sys_FileWrite (report_handle, text, Q_strlen(text));
	// mip-1 horizontal-flat rows measured, and how many of them saw the light
	// byte %dh change between the row head and the row end.  A non-zero
	// "dh-moved" is what makes the index-hoist unsafe.
	sprintf (text,
			"surf8-flat rows %lu dh-moved %lu\n",
			bench486_surf8_flat_rows, bench486_surf8_flat_dh_moved);
	Con_Printf ("%s", text);
	if (report_handle != -1)
		Sys_FileWrite (report_handle, text, Q_strlen(text));
	sprintf (text,
			"memory memset-calls %lu memset-bytes %lu memset-aligned %lu "
			"memcpy-calls %lu memcpy-bytes %lu memcpy-same-align %lu\n",
			bench486_memset_calls, bench486_memset_bytes,
			bench486_memset_aligned_calls, bench486_memcpy_calls,
			bench486_memcpy_bytes, bench486_memcpy_same_alignment_calls);
	Con_Printf ("%s", text);
	if (report_handle != -1)
		Sys_FileWrite (report_handle, text, Q_strlen(text));
	sprintf (text,
			"platform joystick-reads %lu joystick-poll-iterations %lu "
			"joystick-timeouts %lu move-calls %lu hull-check-calls %lu\n",
			bench486_joystick_reads, bench486_joystick_poll_iterations,
			bench486_joystick_timeouts, bench486_move_calls,
			bench486_hull_check_calls);
	Con_Printf ("%s", text);
	if (report_handle != -1)
		Sys_FileWrite (report_handle, text, Q_strlen(text));

	Bench486ProfileReportText (report_handle,
				"profile-tree begin (edge inclusive / edge self seconds)\n");
	Bench486ProfileTree (report_handle, BENCH486_PROFILE_ROOT, 0);
	Bench486ProfileReportText (report_handle, "profile-tree end\n");
	Bench486ProfileReportText (report_handle, "profile-hotspots begin (self time)\n");
	Bench486ProfileHotspots (report_handle);
	Bench486ProfileReportText (report_handle, "profile-hotspots end\n");

	sprintf (text,
			"profile-work bsp-nodes %lu solid-culls %lu visibility-culls %lu "
			"leaves %lu internal %lu surface-tests %lu scanlines %lu "
			"edge-inserts %lu edge-removes %lu edge-steps %lu span-flushes %lu\n",
			bench486_bsp_nodes, bench486_bsp_solid_culls,
			bench486_bsp_visibility_culls, bench486_bsp_leaf_nodes,
			bench486_bsp_internal_nodes, bench486_bsp_surface_tests,
			bench486_scanlines, bench486_edge_insert_calls,
			bench486_edge_remove_calls, bench486_edge_step_calls,
			bench486_span_flushes);
	Bench486ProfileReportText (report_handle, text);
	// Its own report call, not another field in the block above.  The
	// profile-work sprintf above targets char text[1024] and is already at
	// its limit; see the note in this function.
	sprintf (text,
			"edge-iters insert %lu remove %lu step %lu pushback %lu "
			"sort %lu emit %lu genspans %lu bmodel-zsort %lu "
			"trailing %lu\n",
			bench486_edge_insert_iters, bench486_edge_remove_iters,
			bench486_edge_step_iters, bench486_edge_pushback_iters,
			bench486_edge_sort_iters, bench486_edge_emit_blocks,
			bench486_edge_genspans_edges, bench486_edge_bmodel_zsort,
			bench486_edge_trailing_calls);
	Bench486ProfileReportText (report_handle, text);
	// Per-edge dispatch census.  Its own report call for the same reason as
	// the line above.
	sprintf (text,
			"edge-dispatch leading %lu bmodel-leading %lu bmodel-trailing %lu "
			"insert-exit %lu newtop %lu xldone %lu lastspan %lu "
			"reset-iters %lu\n",
			bench486_edge_leading, bench486_edge_bmodel_leading,
			bench486_edge_bmodel_trailing, bench486_edge_insert_exit,
			bench486_edge_newtop, bench486_edge_xldone,
			bench486_edge_lastspan, bench486_edge_reset_iters);
	Bench486ProfileReportText (report_handle, text);
#ifdef ASM486_RENDERFACE_PROBE
	// The sink's own value doubles as the probe's execution count, which is
	// how a C probe proves it survived -O3: a deleted store would report 0.
	{
		extern unsigned long bench486_rf_probe_sink;
		sprintf (text, "renderface-probe sink %lu\n", bench486_rf_probe_sink);
		Bench486ProfileReportText (report_handle, text);
	}
#endif
	sprintf (text,
			"profile-work renderface-general-edges %lu\n",
			bench486_renderface_general_edges);
	Bench486ProfileReportText (report_handle, text);
	sprintf (text,
			"profile-work renderface-calls %lu renderface-emitted %lu "
			"clipedge-calls %lu emitcached-calls %lu\n",
			bench486_renderface_calls, bench486_renderface_emitted,
			bench486_clipedge_calls, bench486_emitcachededge_calls);
	Bench486ProfileReportText (report_handle, text);
	sprintf (text,
			"profile-work renderface-clipchain-builds %lu cache-hits %lu\n",
			bench486_renderface_clipchain_builds,
			bench486_renderface_clipchain_cache_hits);
	Bench486ProfileReportText (report_handle, text);
	sprintf (text,
			"profile-work renderface-edges %lu early-surfs %lu early-edges %lu "
			"clipplanes %lu\n",
			bench486_renderface_edge_setups,
			bench486_renderface_early_surfs,
			bench486_renderface_early_edges,
			bench486_renderface_faces);
	Bench486ProfileReportText (report_handle, text);
	sprintf (text,
			"profile-work surface-spans %lu surface-pixels %lu "
			"surface-segments %lu sky %lu background %lu turbulent %lu "
			"normal %lu solid %lu present-rects %lu present-pixels %lu "
			"sound-updates %lu sound-mixes %lu\n",
			bench486_surface_span_count, bench486_surface_span_pixels,
			bench486_surface_span_segments, bench486_surface_sky_count,
			bench486_surface_background_count,
			bench486_surface_turbulent_count,
			bench486_surface_normal_count, bench486_surface_solid_count,
			bench486_present_rects,
			bench486_present_pixels, bench486_sound_update_calls,
			bench486_sound_mix_calls);
	Bench486ProfileReportText (report_handle, text);
	sprintf (text,
			"profile-overhead timer-reads %lu max-depth %lu "
			"stack-overflows %lu bad-leaves %lu discarded-scopes %lu "
			"json profile.jsn\n",
			bench486_profile_timer_reads, bench486_profile_max_depth,
			bench486_profile_stack_overflows, bench486_profile_bad_leaves,
			bench486_profile_discarded_scopes);
	Bench486ProfileReportText (report_handle, text);
	sprintf (text,
			"profile-surface-cache hits %lu rebuilds %lu immutable-rebuilds %lu allocations %lu "
			"wraps %lu invalidated-blocks %lu requested-bytes %lu "
			"reclaimed-bytes %lu thrash-frames %lu\n",
			bench486_surface_cache_hits, bench486_surface_cache_rebuilds,
			bench486_surface_cache_immutable_rebuilds,
			bench486_surface_cache_allocations, bench486_surface_cache_wraps,
			bench486_surface_cache_invalidated_blocks,
			bench486_surface_cache_requested_bytes,
			bench486_surface_cache_reclaimed_bytes,
			bench486_surface_cache_thrash_frames);
	Bench486ProfileReportText (report_handle, text);
	sprintf (text,
			"profile-bmodel-plane-cache hits %lu misses %lu hit-percent %lu\n",
			bench486_bpoly_plane_cache_hits,
			bench486_bpoly_plane_cache_misses,
			(bench486_bpoly_plane_cache_hits + bench486_bpoly_plane_cache_misses) ?
				(bench486_bpoly_plane_cache_hits * 100UL) /
				(bench486_bpoly_plane_cache_hits +
				 bench486_bpoly_plane_cache_misses) : 0);
	Bench486ProfileReportText (report_handle, text);
	sprintf (text,
			"profile-bmodel-clip edges %lu adjacent-endpoint-hits %lu "
			"endpoint-hit-percent %lu\n",
			bench486_bpoly_clip_edges,
			bench486_bpoly_adjacent_endpoint_hits,
			bench486_bpoly_clip_edges ?
				(bench486_bpoly_adjacent_endpoint_hits * 100UL) /
				(bench486_bpoly_clip_edges * 2UL) : 0);
	Bench486ProfileReportText (report_handle, text);
	sprintf (text,
			"profile-alias-occlusion queries %lu culls %lu tiles %lu z-samples %lu\n",
			bench486_alias_occlusion_queries,
			bench486_alias_occlusion_culls,
			bench486_alias_occlusion_tiles,
			bench486_alias_occlusion_z_samples);
	Bench486ProfileReportText (report_handle, text);
	sprintf (text,
			"profile-submodel calls %lu faces %lu distinct-entities %lu "
			"entity-hits %lu table-overwrites %lu\n",
			bench486_submodel_calls, bench486_submodel_faces,
			bench486_submodel_distinct_entities, bench486_submodel_entity_hits,
			bench486_submodel_table_overwrites);
	Bench486ProfileReportText (report_handle, text);
	sprintf (text,
			"profile-turbulent rows %lu chunks %lu pixels %lu\n",
			bench486_turbulent_rows, bench486_turbulent_chunks,
			bench486_turbulent_pixels);
	Bench486ProfileReportText (report_handle, text);
	Bench486WriteProfileJson (timedemo_frames, timedemo_seconds);
#else
	(void)report_handle;
	(void)timedemo_frames;
	(void)timedemo_seconds;
#endif
}

void Bench486WriteTimedemoFrameChecksum (int report_handle)
{
	char	text[512];
	unsigned checksum;
	unsigned long event;
	int text_length;

	checksum = vid.buffer ? Bench486Checksum ((byte *)vid.buffer,
			(int)(vid.rowbytes * vid.height)) : 0;
	sprintf (text, "framebuffer-checksum %u\n", checksum);
	Con_Printf ("%s", text);
	if (report_handle != -1)
		Sys_FileWrite (report_handle, text, Q_strlen(text));

	text_length = sprintf (text, "blob-explosion-events %lu frames",
			bench486_blob_explosion_event_count);
	for (event = 0 ; event < bench486_blob_explosion_event_stored_count ; event++)
		text_length += sprintf (text + text_length, " %lu",
				bench486_blob_explosion_event_frames[event]);
	text_length += sprintf (text + text_length, " overflow %lu\n",
			bench486_blob_explosion_event_overflow);
	Con_Printf ("%s", text);
	if (report_handle != -1)
		Sys_FileWrite (report_handle, text, text_length);

	text_length = sprintf (text, "lava-splash-events %lu frames",
			bench486_lava_splash_event_count);
	for (event = 0 ; event < bench486_lava_splash_event_stored_count ; event++)
		text_length += sprintf (text + text_length, " %lu",
				bench486_lava_splash_event_frames[event]);
	text_length += sprintf (text + text_length, " overflow %lu\n",
			bench486_lava_splash_event_overflow);
	Con_Printf ("%s", text);
	if (report_handle != -1)
		Sys_FileWrite (report_handle, text, text_length);

	text_length = sprintf (text, "teleport-splash-events %lu frames",
			bench486_teleport_splash_event_count);
	for (event = 0 ; event < bench486_teleport_splash_event_stored_count ; event++)
		text_length += sprintf (text + text_length, " %lu",
				bench486_teleport_splash_event_frames[event]);
	text_length += sprintf (text + text_length, " overflow %lu\n",
			bench486_teleport_splash_event_overflow);
	Con_Printf ("%s", text);
	if (report_handle != -1)
		Sys_FileWrite (report_handle, text, text_length);

	text_length = sprintf (text, "run-particle-effect-events %lu frames",
			bench486_run_particle_effect_event_count);
	for (event = 0 ; event < bench486_run_particle_effect_event_stored_count ; event++)
		text_length += sprintf (text + text_length, " %lu",
				bench486_run_particle_effect_event_frames[event]);
	text_length += sprintf (text + text_length, " overflow %lu\n",
			bench486_run_particle_effect_event_overflow);
	Con_Printf ("%s", text);
	if (report_handle != -1)
		Sys_FileWrite (report_handle, text, text_length);

	text_length = sprintf (text, "entity-particles-events %lu frames",
			bench486_entity_particles_event_count);
	for (event = 0 ; event < bench486_entity_particles_event_stored_count ; event++)
		text_length += sprintf (text + text_length, " %lu",
				bench486_entity_particles_event_frames[event]);
	text_length += sprintf (text + text_length, " overflow %lu\n",
				bench486_entity_particles_event_overflow);
	Con_Printf ("%s", text);
	if (report_handle != -1)
		Sys_FileWrite (report_handle, text, text_length);

	text_length = sprintf (text, "svc-damage-events %lu frames",
			bench486_svc_damage_event_count);
	for (event = 0 ; event < bench486_svc_damage_event_stored_count ; event++)
		text_length += sprintf (text + text_length, " %lu",
				bench486_svc_damage_event_frames[event]);
	text_length += sprintf (text + text_length, " overflow %lu\n",
			bench486_svc_damage_event_overflow);
	Con_Printf ("%s", text);
	if (report_handle != -1)
		Sys_FileWrite (report_handle, text, text_length);

	if (!bench486_timedemo_frame_checksums_enabled)
		return;

	if (bench486_timedemo_frame_checksum_handle == -1)
		return;

	sprintf (text, "frames %lu overflow %lu\n",
			bench486_timedemo_frame_checksum_count,
			bench486_timedemo_frame_checksum_overflow);
	Sys_FileWrite (bench486_timedemo_frame_checksum_handle, text,
			Q_strlen(text));
	Sys_FileClose (bench486_timedemo_frame_checksum_handle);
	bench486_timedemo_frame_checksum_handle = -1;
	if (bench486_timedemo_z_checksum_handle != -1)
	{
		sprintf (text, "frames %lu\n",
				bench486_timedemo_frame_checksum_count);
		Sys_FileWrite (bench486_timedemo_z_checksum_handle, text,
				Q_strlen(text));
		Sys_FileClose (bench486_timedemo_z_checksum_handle);
		bench486_timedemo_z_checksum_handle = -1;
	}
}

#define BENCH486_MEMORY_SAMPLES	5
#define BENCH486_MEMORY_WARMUP	32
#define BENCH486_SURFACE_CACHE_ITERATIONS	500000
#define BENCH486_MIP_ITERATIONS	500000
#define BENCH486_TURBULENT_SAMPLES	5
#define BENCH486_TURBULENT_ITERATIONS	50000
#define BENCH486_ALIAS_PROJECT_ITERATIONS	100000
#define BENCH486_TEXTURE_ANIMATION_ITERATIONS	500000
#define BENCH486_LIGHTMAP_NORMALIZE_SAMPLES	5
#define BENCH486_LIGHTMAP_NORMALIZE_ITERATIONS	25000
#define BENCH486_LIGHTMAP_STYLES_SAMPLES	5
#define BENCH486_LIGHTMAP_STYLES_ITERATIONS	5000
#define BENCH486_BSP_PLANE_DOT_SAMPLES	5
#define BENCH486_BSP_PLANE_DOT_ITERATIONS	500000
#define BENCH486_BSP_CLIP_SAMPLES	5
#define BENCH486_BSP_CLIP_ITERATIONS	200000
#define BENCH486_ALIAS_BBOX_PROJECT_SAMPLES	5
#define BENCH486_ALIAS_BBOX_PROJECT_ITERATIONS	200000
#define BENCH486_ALIAS_TRANSFORM_FINAL_SAMPLES	5
#define BENCH486_ALIAS_TRANSFORM_FINAL_ITERATIONS	200000

typedef void (*bench486_memset_fn_t) (void *dest, int fill, int count);
typedef void (*bench486_memcpy_fn_t) (void *dest, void *src, int count);
typedef void *(*bench486_texture_axis_fn_t) (void *entry, void *texinfo,
		void *entity, int frame);
typedef void *(*bench486_surface_cache_fn_t) (void *cache,
		int surface_dlightframe, int frame, void *texture, int *lightadj,
		void *surface);
typedef int (*bench486_mip_fn_t) (float scale);
typedef void (*bench486_turbulent_fn_t) (void);
typedef void (*bench486_alias_project_fn_t) (finalvert_t *fv, auxvert_t *av);
typedef texture_t *(*bench486_texture_animation_fn_t) (texture_t *base,
		int relative);
typedef texture_t *(*bench486_texture_animation_entry_fn_t) (texture_t *base);
typedef void (*bench486_lightmap_normalize_fn_t) (unsigned *lights,
		int size);
typedef void (*bench486_lightmap_styles_fn_t) (unsigned *dest, byte *lightmap,
		int size, int maps, unsigned scale, int *lightadj);
typedef void (*bench486_fused_lightmap_fn_t) (unsigned *dest, byte *lightmap,
		int size, int maps, unsigned scale, int *lightadj);
typedef double (*bench486_bsp_plane_dot_fn_t) (mplane_t *plane);
typedef int (*bench486_bsp_clip_fn_t) (mnode_t *node, int clipflags);
typedef int (*bench486_alias_bbox_project_fn_t) (auxvert_t *viewaux,
		finalvert_t *viewpts, int numv);
typedef void (*bench486_alias_transform_final_fn_t) (finalvert_t *fv,
		auxvert_t *av, trivertx_t *pverts, stvert_t *pstverts);

static int bench486_turbulent_table[128];

static void Bench486SortSamples (double *samples, int count)
{
	double value;
	int i, j;

	for (i=1 ; i<count ; i++)
	{
		value = samples[i];
		j = i;
		while (j > 0 && samples[j-1] > value)
		{
			samples[j] = samples[j-1];
			j--;
		}
		samples[j] = value;
	}
}

static double Bench486MeasureMemset (bench486_memset_fn_t function,
		byte *dest, int fill, int count, int iterations, unsigned *checksum)
{
	double start, elapsed;
	int i;

	Q_memset (dest, 0xa5, 4096);
	for (i=0 ; i<BENCH486_MEMORY_WARMUP ; i++)
		function (dest, fill, count);

	start = Sys_FloatTime ();
	for (i=0 ; i<iterations ; i++)
		function (dest, i, count);
	elapsed = Sys_FloatTime () - start;

	*checksum = Bench486Checksum (dest, count > 0 ? count : 0);
	bench486_sink ^= *checksum;
	return elapsed;
}

static double Bench486MeasureMemcpy (bench486_memcpy_fn_t function,
		byte *dest, byte *source, int count, int iterations,
		unsigned *checksum)
{
	double start, elapsed;
	int i;

	Q_memset (dest, 0xa5, 4096);
	for (i=0 ; i<BENCH486_MEMORY_WARMUP ; i++)
		function (dest, source, count);

	start = Sys_FloatTime ();
	for (i=0 ; i<iterations ; i++)
		function (dest, source, count);
	elapsed = Sys_FloatTime () - start;

	*checksum = Bench486Checksum (dest, count > 0 ? count : 0);
	bench486_sink ^= *checksum;
	return elapsed;
}

static void Bench486PrintSamples (char *name, int count, int iterations,
		qboolean set, int source_offset, int dest_offset, double *c_samples,
		double *asm_samples, unsigned c_checksum, unsigned asm_checksum)
{
	double c_median, asm_median, c_rate, asm_rate, delta;
	int i;

	Bench486SortSamples (c_samples, BENCH486_MEMORY_SAMPLES);
	Bench486SortSamples (asm_samples, BENCH486_MEMORY_SAMPLES);
	c_median = c_samples[BENCH486_MEMORY_SAMPLES / 2];
	asm_median = asm_samples[BENCH486_MEMORY_SAMPLES / 2];
	c_rate = c_median > 0.0 ? (double)iterations / c_median : 0.0;
	asm_rate = asm_median > 0.0 ? (double)iterations / asm_median : 0.0;
	delta = c_median > 0.0 ? (c_median - asm_median) / c_median * 100.0 : 0.0;

	Bench486Printf ("memory %s %s src-off %d dest-off %d count %d iterations %d samples %d\n",
			name, set ? "memset" : "memcpy", source_offset, dest_offset,
			count, iterations, BENCH486_MEMORY_SAMPLES);
	Bench486Printf ("  c median %.6f sec %.0f ops/sec checksum %u samples",
			c_median, c_rate, c_checksum);
	for (i=0 ; i<BENCH486_MEMORY_SAMPLES ; i++)
		Bench486Printf (" %.6f", c_samples[i]);
	Bench486Printf ("\n");
	Bench486Printf ("  asm486 median %.6f sec %.0f ops/sec checksum %u samples",
			asm_median, asm_rate, asm_checksum);
	for (i=0 ; i<BENCH486_MEMORY_SAMPLES ; i++)
		Bench486Printf (" %.6f", asm_samples[i]);
	Bench486Printf ("\n");
	Bench486Printf ("  asm486-vs-c median %.3f percent\n", delta);
}

static void Bench486MemoryCase (char *name, int count, int iterations,
		qboolean set, int source_offset, int dest_offset)
{
	byte		*source, *dest, *expected;
	int		i, sample;
	double		c_samples[BENCH486_MEMORY_SAMPLES];
	double		asm_samples[BENCH486_MEMORY_SAMPLES];
	unsigned	c_checksum, asm_checksum;

	source = (byte *)(((long)bench486_source + 3) & ~3);
	dest = (byte *)(((long)bench486_dest + 3) & ~3);
	expected = (byte *)(((long)bench486_expected + 3) & ~3);
	source += source_offset;
	dest += dest_offset;
	expected += dest_offset;

	for (i=0 ; i<4096 ; i++)
		source[i] = (byte)(i * 17 + 3);

	/* Compare the complete guarded working region before timing either path. */
	Q_memset (expected, 0xa5, 4096);
	Q_memset (dest, 0xa5, 4096);
	if (set)
	{
		Q_memset (expected, 0x1234, count);
		Q_memset_asm486 (dest, 0x1234, count);
	}
	else
	{
		Q_memcpy (expected, source, count);
		Q_memcpy_asm486 (dest, source, count);
	}
	if (Q_memcmp (dest, expected, 4096) != 0)
	{
		bench486_memory_failures++;
		Bench486Printf ("memory %s %s src-off %d dest-off %d count %d correctness FAIL\n",
				name, set ? "memset" : "memcpy", source_offset, dest_offset, count);
		return;
	}

	for (sample=0 ; sample<BENCH486_MEMORY_SAMPLES ; sample++)
	{
		Bench486Printf ("486 benchmark progress memory %s sample %d/%d\n",
				name, sample + 1, BENCH486_MEMORY_SAMPLES);
		/* Alternate order to expose any first-run cache or emulator bias. */
		if ((sample & 1) == 0)
		{
			if (set)
			{
				c_samples[sample] = Bench486MeasureMemset (Q_memset,
						dest, sample, count, iterations, &c_checksum);
				asm_samples[sample] = Bench486MeasureMemset (Q_memset_asm486,
						dest, sample, count, iterations, &asm_checksum);
			}
			else
			{
				c_samples[sample] = Bench486MeasureMemcpy (Q_memcpy,
						dest, source, count, iterations, &c_checksum);
				asm_samples[sample] = Bench486MeasureMemcpy (Q_memcpy_asm486,
						dest, source, count, iterations, &asm_checksum);
			}
		}
		else
		{
			if (set)
			{
				asm_samples[sample] = Bench486MeasureMemset (Q_memset_asm486,
						dest, sample, count, iterations, &asm_checksum);
				c_samples[sample] = Bench486MeasureMemset (Q_memset,
						dest, sample, count, iterations, &c_checksum);
			}
			else
			{
				asm_samples[sample] = Bench486MeasureMemcpy (Q_memcpy_asm486,
						dest, source, count, iterations, &asm_checksum);
				c_samples[sample] = Bench486MeasureMemcpy (Q_memcpy,
						dest, source, count, iterations, &c_checksum);
			}
		}
	}

	Bench486PrintSamples (name, count, iterations, set, source_offset, dest_offset,
			c_samples, asm_samples, c_checksum, asm_checksum);
}

static void Bench486MemoryCases (void)
{
	Bench486Printf ("486 benchmark progress memory phase: 19 cases, %d samples each\n",
			BENCH486_MEMORY_SAMPLES);
	Bench486MemoryCase ("copy-1", 1, 250000, false, 0, 0);
	Bench486MemoryCase ("copy-3", 3, 250000, false, 0, 0);
	Bench486MemoryCase ("copy-zero", 0, 250000, false, 0, 0);
	Bench486MemoryCase ("copy-negative", -1, 250000, false, 0, 0);
	Bench486MemoryCase ("copy-4", 4, 250000, false, 0, 0);
	Bench486MemoryCase ("copy-255", 255, 250000, false, 0, 0);
	Bench486MemoryCase ("copy-256", 256, 250000, false, 0, 0);
	Bench486MemoryCase ("copy-1024", 1024, 100000, false, 0, 0);
	Bench486MemoryCase ("copy-255-both-unaligned", 255, 250000, false, 1, 1);
	Bench486MemoryCase ("copy-255-misaligned", 255, 250000, false, 1, 2);
	Bench486MemoryCase ("set-1", 1, 250000, true, 0, 0);
	Bench486MemoryCase ("set-3", 3, 250000, true, 0, 0);
	Bench486MemoryCase ("set-4", 4, 250000, true, 0, 0);
	Bench486MemoryCase ("set-255", 255, 250000, true, 0, 0);
	Bench486MemoryCase ("set-256", 256, 250000, true, 0, 0);
	Bench486MemoryCase ("set-1024", 1024, 100000, true, 0, 0);
	Bench486MemoryCase ("set-255-unaligned", 255, 250000, true, 0, 1);
	Bench486MemoryCase ("set-zero", 0, 250000, true, 0, 0);
	Bench486MemoryCase ("set-negative", -1, 250000, true, 0, 0);
}

static void Bench486SetTurbulentState (byte *dest, int count)
{
	r_turb_s = 11 << 16;
	r_turb_t = 23 << 16;
	r_turb_sstep = 0x00003111;
	r_turb_tstep = 0x00005222;
	r_turb_pbase = bench486_source;
	r_turb_pdest = dest;
	r_turb_turb = bench486_turbulent_table;
	r_turb_spancount = count;
}

static double Bench486MeasureTurbulent (bench486_turbulent_fn_t function,
		byte *dest, int count, int iterations, unsigned *checksum)
{
	double start, elapsed;
	int i;

	for (i=0 ; i<BENCH486_MEMORY_WARMUP ; i++)
	{
		Bench486SetTurbulentState (dest, count);
		function ();
	}

	start = Sys_FloatTime ();
	for (i=0 ; i<iterations ; i++)
	{
		Bench486SetTurbulentState (dest, count);
		function ();
	}
	elapsed = Sys_FloatTime () - start;

	*checksum = Bench486Checksum (dest, count);
	bench486_sink ^= *checksum;
	return elapsed;
}

static void Bench486PrintTurbulentSamples (int count, double *c_samples,
		double *asm_samples, unsigned c_checksum, unsigned asm_checksum)
{
	double c_median, asm_median, c_rate, asm_rate, delta;
	int i;

	Bench486SortSamples (c_samples, BENCH486_TURBULENT_SAMPLES);
	Bench486SortSamples (asm_samples, BENCH486_TURBULENT_SAMPLES);
	c_median = c_samples[BENCH486_TURBULENT_SAMPLES / 2];
	asm_median = asm_samples[BENCH486_TURBULENT_SAMPLES / 2];
	c_rate = c_median > 0.0 ?
			(double)BENCH486_TURBULENT_ITERATIONS / c_median : 0.0;
	asm_rate = asm_median > 0.0 ?
			(double)BENCH486_TURBULENT_ITERATIONS / asm_median : 0.0;
	delta = c_median > 0.0 ?
			(c_median - asm_median) / c_median * 100.0 : 0.0;

	Bench486Printf ("turbulent count %d pixels iterations %d samples %d\n",
			count, BENCH486_TURBULENT_ITERATIONS,
			BENCH486_TURBULENT_SAMPLES);
	Bench486Printf ("  c median %.6f sec %.0f ops/sec checksum %u samples",
			c_median, c_rate, c_checksum);
	for (i=0 ; i<BENCH486_TURBULENT_SAMPLES ; i++)
		Bench486Printf (" %.6f", c_samples[i]);
	Bench486Printf ("\n");
	Bench486Printf ("  asm486 median %.6f sec %.0f ops/sec checksum %u samples",
			asm_median, asm_rate, asm_checksum);
	for (i=0 ; i<BENCH486_TURBULENT_SAMPLES ; i++)
		Bench486Printf (" %.6f", asm_samples[i]);
	Bench486Printf ("\n");
	Bench486Printf ("  asm486-vs-c median %.3f percent\n", delta);
}

static void Bench486TurbulentCase (int count)
{
	double c_samples[BENCH486_TURBULENT_SAMPLES];
	double asm_samples[BENCH486_TURBULENT_SAMPLES];
	unsigned c_checksum, asm_checksum;
	int i, sample, mismatch;

	for (i=0 ; i<4096 ; i++)
		bench486_source[i] = (byte)((i * 13 + 7) & 0xff);

	Bench486SetTurbulentState (bench486_expected, count);
	D_DrawTurbulent8Span_C ();
	Bench486SetTurbulentState (bench486_dest, count);
	D_DrawTurbulent8Span_asm486 ();
	mismatch = -1;
	for (i=0 ; i<count ; i++)
	{
		if (bench486_dest[i] != bench486_expected[i])
		{
			mismatch = i;
			break;
		}
	}
	if (mismatch >= 0 || r_turb_pdest != bench486_dest + count)
	{
		bench486_memory_failures++;
		Bench486Printf ("turbulent count %d correctness FAIL byte %d c %u asm %u pdest %p expected %p\n",
				count, mismatch, mismatch >= 0 ? bench486_expected[mismatch] : 0,
				mismatch >= 0 ? bench486_dest[mismatch] : 0,
				r_turb_pdest, bench486_dest + count);
		return;
	}

	for (sample=0 ; sample<BENCH486_TURBULENT_SAMPLES ; sample++)
	{
		if ((sample & 1) == 0)
		{
			c_samples[sample] = Bench486MeasureTurbulent(
					D_DrawTurbulent8Span_C, bench486_dest, count,
					BENCH486_TURBULENT_ITERATIONS, &c_checksum);
			asm_samples[sample] = Bench486MeasureTurbulent(
					D_DrawTurbulent8Span_asm486, bench486_dest, count,
					BENCH486_TURBULENT_ITERATIONS, &asm_checksum);
		}
		else
		{
			asm_samples[sample] = Bench486MeasureTurbulent(
					D_DrawTurbulent8Span_asm486, bench486_dest, count,
					BENCH486_TURBULENT_ITERATIONS, &asm_checksum);
			c_samples[sample] = Bench486MeasureTurbulent(
					D_DrawTurbulent8Span_C, bench486_dest, count,
					BENCH486_TURBULENT_ITERATIONS, &c_checksum);
		}
	}

	Bench486PrintTurbulentSamples (count, c_samples, asm_samples,
			c_checksum, asm_checksum);
}

static void Bench486TurbulentCases (void)
{
	int i;

	for (i=0 ; i<128 ; i++)
		bench486_turbulent_table[i] = (i * 19 + 5) & 127;

	Bench486TurbulentCase (4);
	Bench486TurbulentCase (8);
	Bench486TurbulentCase (16);
	Bench486TurbulentCase (64);
}

#if defined(ASM486_TURBULENT_SCAN)
static void Bench486TurbulentScanParity (void)
{
	static const int span_counts[13] = {
		1, 2, 7, 15, 16, 17, 31, 32, 33, 63, 65, 0, -1
	};
	static const double time_values[6] = {
		-3.201, -0.051, 0.0, 0.04999999, 0.05, 17.999
	};
	espan_t spans[13];
	pixel_t *saved_rowptrs[13];
	pixel_t *saved_cacheblock;
	byte *saved_pbase, *saved_pdest;
	fixed16_t saved_s, saved_t, saved_sstep, saved_tstep;
	int *saved_turb;
	int saved_spancount;
	fixed16_t saved_sadjust, saved_tadjust, saved_bbextents, saved_bbextentt;
	float saved_sdu, saved_tdu, saved_zdu;
	float saved_sdv, saved_tdv, saved_zdv;
	float saved_sorigin, saved_torigin, saved_zorigin;
	double saved_time;
	unsigned short original_cw, test_cw, after_cw;
	int failures, scenario, rounding, row, mismatch;
	int expected_s, expected_t, expected_sstep, expected_tstep;
	int expected_spancount;
	int *expected_turb;
	byte *expected_pdest;
	byte *expected_pbase;
	int scan_bytes;
#ifdef PROFILE486
	int saved_profile_active;
	unsigned long saved_row_count, saved_chunks, saved_pixels;
	double saved_seconds;
#endif

	for (row=0 ; row<13 ; row++)
	{
		saved_rowptrs[row] = viewspantable[row];
		spans[row].u = 3 + (row % 5);
		spans[row].v = row;
		spans[row].count = span_counts[row];
		spans[row].pnext = row == 12 ? NULL : &spans[row+1];
	}
	scan_bytes = 13 * 160;
	saved_cacheblock = cacheblock;
	saved_pbase = r_turb_pbase;
	saved_pdest = r_turb_pdest;
	saved_s = r_turb_s;
	saved_t = r_turb_t;
	saved_sstep = r_turb_sstep;
	saved_tstep = r_turb_tstep;
	saved_turb = r_turb_turb;
	saved_spancount = r_turb_spancount;
	saved_sadjust = sadjust;
	saved_tadjust = tadjust;
	saved_bbextents = bbextents;
	saved_bbextentt = bbextentt;
	saved_sdu = d_sdivzstepu;
	saved_tdu = d_tdivzstepu;
	saved_zdu = d_zistepu;
	saved_sdv = d_sdivzstepv;
	saved_tdv = d_tdivzstepv;
	saved_zdv = d_zistepv;
	saved_sorigin = d_sdivzorigin;
	saved_torigin = d_tdivzorigin;
	saved_zorigin = d_ziorigin;
	saved_time = cl.time;
#ifdef PROFILE486
	saved_profile_active = bench486_profile_frame_active;
	saved_row_count = bench486_turbulent_rows;
	saved_chunks = bench486_turbulent_chunks;
	saved_pixels = bench486_turbulent_pixels;
	saved_seconds = bench486_turbulent_seconds;
	bench486_profile_frame_active = false;
#endif
	__asm__ __volatile__ ("fnstcw %0" : "=m" (original_cw));

	for (row=0 ; row<4096 ; row++)
		bench486_source[row] = (byte)((row * 29 + 11) & 0xff);
	cacheblock = (pixel_t *)bench486_source;
	sadjust = 2 << 16;
	tadjust = 1 << 16;
	bbextents = 63 << 16;
	bbextentt = 63 << 16;
	failures = 0;

	for (scenario=0 ; scenario<6 ; scenario++)
	{
		cl.time = time_values[scenario];
		d_sdivzorigin = 0.75f + scenario * 0.125f;
		d_tdivzorigin = 1.25f - scenario * 0.0625f;
		d_ziorigin = 0.5f + scenario * 0.03125f;
		d_sdivzstepu = (scenario & 1) ? -0.00325f : 0.00475f;
		d_tdivzstepu = (scenario & 1) ? 0.00275f : -0.00175f;
		d_zistepu = 0.00125f + scenario * 0.000125f;
		d_sdivzstepv = (scenario & 1) ? 0.00625f : 0.00375f;
		d_tdivzstepv = (scenario & 1) ? -0.00225f : 0.00575f;
		d_zistepv = 0.0015f + scenario * 0.00025f;
		for (rounding=0 ; rounding<4 ; rounding++)
		{
			test_cw = (unsigned short)((original_cw & ~0x0c00) | (rounding << 10));
			for (row=0 ; row<13 ; row++)
				viewspantable[row] = (pixel_t *)(bench486_expected + row * 160);
			memset (bench486_expected, 0xa5, scan_bytes);
			__asm__ __volatile__ ("fldcw %0" : : "m" (test_cw));
			Turbulent8_C (&spans[0]);
			__asm__ __volatile__ ("fnstcw %0" : "=m" (after_cw));
			expected_s = r_turb_s;
			expected_t = r_turb_t;
			expected_sstep = r_turb_sstep;
			expected_tstep = r_turb_tstep;
			expected_spancount = r_turb_spancount;
			expected_turb = r_turb_turb;
			expected_pdest = r_turb_pdest;
			expected_pbase = r_turb_pbase;
			if (after_cw != test_cw)
			{
				failures++;
				bench486_memory_failures++;
				Bench486Printf ("turbulent scan C changed x87 control word scenario %d round %d %04x/%04x\n",
						scenario, rounding, test_cw, after_cw);
			}

			for (row=0 ; row<13 ; row++)
				viewspantable[row] = (pixel_t *)(bench486_dest + row * 160);
			memset (bench486_dest, 0xa5, scan_bytes);
			__asm__ __volatile__ ("fldcw %0" : : "m" (test_cw));
			Turbulent8 (&spans[0]);
			__asm__ __volatile__ ("fnstcw %0" : "=m" (after_cw));
			mismatch = -1;
			for (row=0 ; row<scan_bytes ; row++)
			{
				if (bench486_expected[row] != bench486_dest[row])
				{
					mismatch = row;
					break;
				}
			}
			if (mismatch >= 0 || after_cw != test_cw ||
					r_turb_s != expected_s || r_turb_t != expected_t ||
					r_turb_sstep != expected_sstep || r_turb_tstep != expected_tstep ||
					r_turb_spancount != expected_spancount ||
					r_turb_turb != expected_turb ||
					((unsigned long)r_turb_pdest - (unsigned long)bench486_dest) !=
						((unsigned long)expected_pdest - (unsigned long)bench486_expected) ||
					r_turb_pbase != expected_pbase)
			{
				failures++;
				bench486_memory_failures++;
				Bench486Printf ("turbulent scan assembly parity FAIL scenario %d round %d byte %d c %u asm %u cw %04x/%04x s %ld/%ld t %ld/%ld\n",
						scenario, rounding, mismatch,
						mismatch >= 0 ? bench486_expected[mismatch] : 0,
						mismatch >= 0 ? bench486_dest[mismatch] : 0,
						test_cw, after_cw, (long)expected_s, (long)r_turb_s,
						(long)expected_t, (long)r_turb_t);
			}
		}
	}

	for (row=0 ; row<13 ; row++)
		viewspantable[row] = saved_rowptrs[row];
	cacheblock = saved_cacheblock;
	r_turb_pbase = saved_pbase;
	r_turb_pdest = saved_pdest;
	r_turb_s = saved_s;
	r_turb_t = saved_t;
	r_turb_sstep = saved_sstep;
	r_turb_tstep = saved_tstep;
	r_turb_turb = saved_turb;
	r_turb_spancount = saved_spancount;
	sadjust = saved_sadjust;
	tadjust = saved_tadjust;
	bbextents = saved_bbextents;
	bbextentt = saved_bbextentt;
	d_sdivzstepu = saved_sdu;
	d_tdivzstepu = saved_tdu;
	d_zistepu = saved_zdu;
	d_sdivzstepv = saved_sdv;
	d_tdivzstepv = saved_tdv;
	d_zistepv = saved_zdv;
	d_sdivzorigin = saved_sorigin;
	d_tdivzorigin = saved_torigin;
	d_ziorigin = saved_zorigin;
	cl.time = saved_time;
#ifdef PROFILE486
	bench486_profile_frame_active = saved_profile_active;
	bench486_turbulent_rows = saved_row_count;
	bench486_turbulent_chunks = saved_chunks;
	bench486_turbulent_pixels = saved_pixels;
	bench486_turbulent_seconds = saved_seconds;
#endif
	__asm__ __volatile__ ("fldcw %0" : : "m" (original_cw));
	if (failures == 0)
		Bench486Printf ("turbulent scan assembly parity PASS (13 lengths across six phases and four x87 rounding modes; zero mismatches)\n");
	else
		Bench486Printf ("turbulent scan assembly parity FAIL (%d mismatches)\n", failures);
}
#endif

static double Bench486MeasureAliasProject (bench486_alias_project_fn_t function,
		finalvert_t *fv, auxvert_t *av, int iterations, unsigned *checksum)
{
	double start, elapsed;
	unsigned result_sum;
	int i;

	for (i=0 ; i<BENCH486_MEMORY_WARMUP ; i++)
		function (fv, av);

	start = Sys_FloatTime ();
	result_sum = 0;
	for (i=0 ; i<iterations ; i++)
	{
		function (fv, av);
		result_sum += (unsigned)fv->v[0];
		result_sum += (unsigned)fv->v[1];
		result_sum += (unsigned)fv->v[5];
	}
	elapsed = Sys_FloatTime () - start;

	*checksum = result_sum;
	bench486_sink ^= result_sum;
	return elapsed;
}

static void Bench486AliasProjectCase (char *name, float x, float y,
		float z, float scale)
{
	finalvert_t *c_result, *asm_result;
	auxvert_t av;
	double c_samples[BENCH486_MEMORY_SAMPLES];
	double asm_samples[BENCH486_MEMORY_SAMPLES];
	double c_median, asm_median, delta;
	unsigned c_checksum, asm_checksum;
	int i, sample;

	av.fv[0] = x;
	av.fv[1] = y;
	av.fv[2] = z;
	ziscale = scale;
	aliasxscale = 320.0;
	aliasyscale = 240.0;
	aliasxcenter = 160.0;
	aliasycenter = 120.0;

	c_result = (finalvert_t *)bench486_expected;
	asm_result = (finalvert_t *)bench486_dest;
	Q_memset (c_result, 0x5a, sizeof(*c_result));
	Q_memset (asm_result, 0x5a, sizeof(*asm_result));
	R_AliasProjectFinalVert (c_result, &av);
	R_AliasProjectFinalVert_asm486 (asm_result, &av);
	if (Q_memcmp (c_result, asm_result, sizeof(*c_result)) != 0)
	{
		bench486_memory_failures++;
		Bench486Printf ("alias-project %s correctness FAIL c %d,%d,%d asm %d,%d,%d\n",
				name, c_result->v[0], c_result->v[1], c_result->v[5],
				asm_result->v[0], asm_result->v[1], asm_result->v[5]);
		return;
	}

	for (sample=0 ; sample<BENCH486_MEMORY_SAMPLES ; sample++)
	{
		if ((sample & 1) == 0)
		{
			c_samples[sample] = Bench486MeasureAliasProject (
					R_AliasProjectFinalVert, c_result, &av,
					BENCH486_ALIAS_PROJECT_ITERATIONS, &c_checksum);
			asm_samples[sample] = Bench486MeasureAliasProject (
					R_AliasProjectFinalVert_asm486, asm_result, &av,
					BENCH486_ALIAS_PROJECT_ITERATIONS, &asm_checksum);
		}
		else
		{
			asm_samples[sample] = Bench486MeasureAliasProject (
					R_AliasProjectFinalVert_asm486, asm_result, &av,
					BENCH486_ALIAS_PROJECT_ITERATIONS, &asm_checksum);
			c_samples[sample] = Bench486MeasureAliasProject (
					R_AliasProjectFinalVert, c_result, &av,
					BENCH486_ALIAS_PROJECT_ITERATIONS, &c_checksum);
		}

		if (Q_memcmp (c_result, asm_result, sizeof(*c_result)) != 0 ||
				c_checksum != asm_checksum)
		{
			bench486_memory_failures++;
			Bench486Printf ("alias-project %s checksum correctness FAIL\n", name);
			return;
		}
	}

	Bench486SortSamples (c_samples, BENCH486_MEMORY_SAMPLES);
	Bench486SortSamples (asm_samples, BENCH486_MEMORY_SAMPLES);
	c_median = c_samples[BENCH486_MEMORY_SAMPLES / 2];
	asm_median = asm_samples[BENCH486_MEMORY_SAMPLES / 2];
	delta = c_median > 0.0 ? (c_median - asm_median) / c_median * 100.0 : 0.0;
	Bench486Printf ("alias-project %s x %.3f y %.3f z %.3f iterations %d samples %d\n",
			name, x, y, z, BENCH486_ALIAS_PROJECT_ITERATIONS,
			BENCH486_MEMORY_SAMPLES);
	Bench486Printf ("  c median %.6f sec checksum %u samples",
			c_median, c_checksum);
	for (i=0 ; i<BENCH486_MEMORY_SAMPLES ; i++)
		Bench486Printf (" %.6f", c_samples[i]);
	Bench486Printf ("\n");
	Bench486Printf ("  asm486 median %.6f sec checksum %u samples",
			asm_median, asm_checksum);
	for (i=0 ; i<BENCH486_MEMORY_SAMPLES ; i++)
		Bench486Printf (" %.6f", asm_samples[i]);
	Bench486Printf ("\n");
	Bench486Printf ("  asm486-vs-c median %.3f percent\n", delta);
}

static void Bench486AliasProjectCases (void)
{
	float saved_ziscale, saved_xscale, saved_yscale;
	float saved_xcenter, saved_ycenter;

	saved_ziscale = ziscale;
	saved_xscale = aliasxscale;
	saved_yscale = aliasyscale;
	saved_xcenter = aliasxcenter;
	saved_ycenter = aliasycenter;

	Bench486AliasProjectCase ("far", 1.25, -0.75, 32.0,
			(float)0x8000 * (float)0x10000);
	Bench486AliasProjectCase ("near", -5.5, 3.25, 8.0,
			(float)0x8000 * (float)0x10000);
	Bench486AliasProjectCase ("viewmodel", 0.125, -0.25, 16.0,
			(float)0x8000 * (float)0x10000 * 3.0);

	ziscale = saved_ziscale;
	aliasxscale = saved_xscale;
	aliasyscale = saved_yscale;
	aliasxcenter = saved_xcenter;
	aliasycenter = saved_ycenter;
}

static double Bench486MeasureTextureAnimation (
		bench486_texture_animation_fn_t function, texture_t *base,
		int relative, int iterations, unsigned *checksum)
{
	double start, elapsed;
	texture_t *result;
	unsigned result_sum;
	int i;

	for (i=0 ; i<BENCH486_MEMORY_WARMUP ; i++)
		function (base, relative);

	start = Sys_FloatTime ();
	result_sum = 0;
	for (i=0 ; i<iterations ; i++)
	{
		result = function (base, relative);
		result_sum += (unsigned)result->anim_min;
		result_sum += (unsigned)result->anim_max;
	}
	elapsed = Sys_FloatTime () - start;

	*checksum = result_sum;
	bench486_sink ^= result_sum;
	return elapsed;
}

static void Bench486TextureAnimationCase (char *name, int frames,
		int base_index, int relative)
{
	texture_t textures[8];
	double c_samples[BENCH486_MEMORY_SAMPLES];
	double asm_samples[BENCH486_MEMORY_SAMPLES];
	double c_median, asm_median, delta;
	unsigned c_checksum, asm_checksum;
	texture_t *c_result, *asm_result;
	int i, sample, test_relative;

	Q_memset (textures, 0, sizeof(textures));
	for (i=0 ; i<frames ; i++)
	{
		textures[i].anim_total = frames * 2;
		textures[i].anim_min = i * 2;
		textures[i].anim_max = (i + 1) * 2;
		textures[i].anim_next = &textures[(i + 1) % frames];
	}

	/* Check every frame interval from every possible starting node. */
	for (i=0 ; i<frames ; i++)
	{
		for (test_relative=0 ; test_relative<frames*2 ; test_relative++)
		{
			c_result = R_TextureAnimationFrame_C (&textures[i],
					test_relative);
			asm_result = R_TextureAnimationFrame_asm486 (&textures[i],
					test_relative);
			if (c_result != asm_result)
			{
				bench486_memory_failures++;
				Bench486Printf ("texture-animation %s correctness FAIL base %d relative %d\n",
						name, i, test_relative);
				return;
			}
		}
	}

	c_result = R_TextureAnimationFrame_C (&textures[base_index], relative);
	asm_result = R_TextureAnimationFrame_asm486 (&textures[base_index], relative);
	if (c_result != asm_result)
	{
		bench486_memory_failures++;
		Bench486Printf ("texture-animation %s selected-frame correctness FAIL\n",
				name);
		return;
	}

	for (sample=0 ; sample<BENCH486_MEMORY_SAMPLES ; sample++)
	{
		if ((sample & 1) == 0)
		{
			c_samples[sample] = Bench486MeasureTextureAnimation (
					R_TextureAnimationFrame_C, &textures[base_index], relative,
					BENCH486_TEXTURE_ANIMATION_ITERATIONS, &c_checksum);
			asm_samples[sample] = Bench486MeasureTextureAnimation (
					R_TextureAnimationFrame_asm486, &textures[base_index], relative,
					BENCH486_TEXTURE_ANIMATION_ITERATIONS, &asm_checksum);
		}
		else
		{
			asm_samples[sample] = Bench486MeasureTextureAnimation (
					R_TextureAnimationFrame_asm486, &textures[base_index], relative,
					BENCH486_TEXTURE_ANIMATION_ITERATIONS, &asm_checksum);
			c_samples[sample] = Bench486MeasureTextureAnimation (
					R_TextureAnimationFrame_C, &textures[base_index], relative,
					BENCH486_TEXTURE_ANIMATION_ITERATIONS, &c_checksum);
		}

		if (c_checksum != asm_checksum)
		{
			bench486_memory_failures++;
			Bench486Printf ("texture-animation %s checksum correctness FAIL\n",
					name);
			return;
		}
	}

	Bench486SortSamples (c_samples, BENCH486_MEMORY_SAMPLES);
	Bench486SortSamples (asm_samples, BENCH486_MEMORY_SAMPLES);
	c_median = c_samples[BENCH486_MEMORY_SAMPLES / 2];
	asm_median = asm_samples[BENCH486_MEMORY_SAMPLES / 2];
	delta = c_median > 0.0 ?
			(c_median - asm_median) / c_median * 100.0 : 0.0;
	Bench486Printf ("texture-animation %s frames %d base %d relative %d iterations %d samples %d\n",
			name, frames, base_index, relative,
			BENCH486_TEXTURE_ANIMATION_ITERATIONS, BENCH486_MEMORY_SAMPLES);
	Bench486Printf ("  c median %.6f sec checksum %u samples",
			c_median, c_checksum);
	for (i=0 ; i<BENCH486_MEMORY_SAMPLES ; i++)
		Bench486Printf (" %.6f", c_samples[i]);
	Bench486Printf ("\n");
	Bench486Printf ("  asm486 median %.6f sec checksum %u samples",
			asm_median, asm_checksum);
	for (i=0 ; i<BENCH486_MEMORY_SAMPLES ; i++)
		Bench486Printf (" %.6f", asm_samples[i]);
	Bench486Printf ("\n");
	Bench486Printf ("  asm486-vs-c median %.3f percent\n", delta);
}

static void Bench486TextureAnimationCases (void)
{
	Bench486TextureAnimationCase ("2frame-first", 2, 0, 0);
	Bench486TextureAnimationCase ("4frame-middle", 4, 0, 4);
	Bench486TextureAnimationCase ("8frame-tail", 8, 0, 14);
	Bench486TextureAnimationCase ("8frame-wrap", 8, 7, 0);
}

#if defined(BENCH486) && defined(ASM486_TEXTURE_ANIMATION)
static double Bench486MeasureTextureAnimationEntry (
		bench486_texture_animation_entry_fn_t function, texture_t *base,
		int iterations, unsigned *checksum)
{
	double start, elapsed;
	texture_t *result;
	unsigned result_sum;
	int i;

	for (i=0 ; i<BENCH486_MEMORY_WARMUP ; i++)
		function (base);

	start = Sys_FloatTime ();
	result_sum = 0;
	for (i=0 ; i<iterations ; i++)
	{
		result = function (base);
		result_sum += (unsigned)result->anim_min;
		result_sum += (unsigned)result->anim_max;
	}
	elapsed = Sys_FloatTime () - start;

	*checksum = result_sum;
	bench486_sink ^= result_sum;
	return elapsed;
}

static void Bench486TextureAnimationEntryCases (void)
{
	static const double times[] = {
		0.0, 0.099999999, 0.1, 0.199999999, 0.2,
		0.799999999, 0.8, 0.999999999, 1.0, 1.599999999,
		1.6, 2.399999999, 2.4, 3.199999999, 3.2,
		3.999999999, 4.0, 7.9, 8.0,
		-0.1, -0.9, -1.0, -1.9, -3.2, -4.1
	};
	static const unsigned short rounding[4] = {
		0x0000, 0x0400, 0x0800, 0x0c00
	};
	texture_t primary[4], alternate[4], static_texture;
	entity_t entity;
	entity_t *saved_entity;
	double saved_time, c_samples[BENCH486_MEMORY_SAMPLES];
	double asm_samples[BENCH486_MEMORY_SAMPLES];
	double c_median, asm_median, delta;
	unsigned c_checksum, asm_checksum;
	unsigned short original_cw, test_cw, c_after_cw, asm_after_cw;
	texture_t *c_result, *asm_result;
	int i, frame, time_index, mode, sample, failures;

	Q_memset (primary, 0, sizeof(primary));
	Q_memset (alternate, 0, sizeof(alternate));
	Q_memset (&static_texture, 0, sizeof(static_texture));
	Q_memset (&entity, 0, sizeof(entity));
	for (i=0 ; i<4 ; i++)
	{
		primary[i].anim_total = 40;
		primary[i].anim_min = i * 10;
		primary[i].anim_max = (i + 1) * 10;
		primary[i].anim_next = &primary[(i + 1) & 3];
		alternate[i].anim_total = 32;
		alternate[i].anim_min = i * 8;
		alternate[i].anim_max = (i + 1) * 8;
		alternate[i].anim_next = &alternate[(i + 1) & 3];
	}
	primary[0].anim_min = -40;
	alternate[0].anim_min = -32;
	primary[0].alternate_anims = &alternate[0];
	static_texture.alternate_anims = &alternate[0];

	saved_entity = currententity;
	saved_time = cl.time;
	currententity = &entity;
	__asm__ __volatile__ ("fnstcw %0" : "=m" (original_cw));
	failures = 0;
	for (mode=0 ; mode<4 && !failures ; mode++)
	{
		test_cw = (original_cw & (unsigned short)~0x0c00) | rounding[mode];
		for (frame=0 ; frame<2 && !failures ; frame++)
		{
			entity.frame = frame;
			for (time_index=0 ; time_index<(int)(sizeof(times)/sizeof(times[0]));
					time_index++)
			{
				cl.time = times[time_index];
				__asm__ __volatile__ ("fldcw %0" : : "m" (test_cw));
				c_result = R_TextureAnimation_C (&primary[0]);
				__asm__ __volatile__ ("fnstcw %0" : "=m" (c_after_cw));
				__asm__ __volatile__ ("fldcw %0" : : "m" (test_cw));
				asm_result = R_TextureAnimation_asm486 (&primary[0]);
				__asm__ __volatile__ ("fnstcw %0" : "=m" (asm_after_cw));
				if (c_result != asm_result || c_after_cw != test_cw ||
						asm_after_cw != test_cw)
				{
					failures++;
					Bench486Printf ("texture-animation entry parity FAIL frame %d time %.12f rounding %d c %p asm %p cw %04x/%04x expected %04x\n",
							frame, cl.time, mode, c_result, asm_result,
							c_after_cw, asm_after_cw, test_cw);
					break;
				}

				/* Also cover a static base, with and without its alternate. */
				__asm__ __volatile__ ("fldcw %0" : : "m" (test_cw));
				c_result = R_TextureAnimation_C (&static_texture);
				__asm__ __volatile__ ("fnstcw %0" : "=m" (c_after_cw));
				__asm__ __volatile__ ("fldcw %0" : : "m" (test_cw));
				asm_result = R_TextureAnimation_asm486 (&static_texture);
				__asm__ __volatile__ ("fnstcw %0" : "=m" (asm_after_cw));
				if (c_result != asm_result || c_after_cw != test_cw ||
						asm_after_cw != test_cw)
				{
					failures++;
					Bench486Printf ("texture-animation static/alternate parity FAIL frame %d time %.12f rounding %d c %p asm %p cw %04x/%04x expected %04x\n",
							frame, cl.time, mode, c_result, asm_result,
							c_after_cw, asm_after_cw, test_cw);
					break;
				}
			}
		}
	}

	if (!failures)
	{
		entity.frame = 0;
		cl.time = 3.25;
		for (sample=0 ; sample<BENCH486_MEMORY_SAMPLES ; sample++)
		{
			if ((sample & 1) == 0)
			{
				c_samples[sample] = Bench486MeasureTextureAnimationEntry (
						R_TextureAnimation_C, &primary[0],
						BENCH486_TEXTURE_ANIMATION_ITERATIONS, &c_checksum);
				asm_samples[sample] = Bench486MeasureTextureAnimationEntry (
						R_TextureAnimation_asm486, &primary[0],
						BENCH486_TEXTURE_ANIMATION_ITERATIONS, &asm_checksum);
			}
			else
			{
				asm_samples[sample] = Bench486MeasureTextureAnimationEntry (
						R_TextureAnimation_asm486, &primary[0],
						BENCH486_TEXTURE_ANIMATION_ITERATIONS, &asm_checksum);
				c_samples[sample] = Bench486MeasureTextureAnimationEntry (
						R_TextureAnimation_C, &primary[0],
						BENCH486_TEXTURE_ANIMATION_ITERATIONS, &c_checksum);
			}
			if (c_checksum != asm_checksum)
			{
				failures++;
				Bench486Printf ("texture-animation entry timing checksum FAIL\n");
				break;
			}
		}
	}

	__asm__ __volatile__ ("fldcw %0" : : "m" (original_cw));
	cl.time = saved_time;
	currententity = saved_entity;
	if (failures)
	{
		bench486_memory_failures++;
		return;
	}

	Bench486SortSamples (c_samples, BENCH486_MEMORY_SAMPLES);
	Bench486SortSamples (asm_samples, BENCH486_MEMORY_SAMPLES);
	c_median = c_samples[BENCH486_MEMORY_SAMPLES / 2];
	asm_median = asm_samples[BENCH486_MEMORY_SAMPLES / 2];
	delta = c_median > 0.0 ?
			(c_median - asm_median) / c_median * 100.0 : 0.0;
	Bench486Printf ("texture-animation entry parity PASS (%d time phases, primary and alternate animation, static fast path, four x87 rounding modes)\n",
			(int)(sizeof(times)/sizeof(times[0])));
	Bench486Printf ("  C median %.6f sec asm486 median %.6f sec delta %.3f percent (%d iterations, %d samples)\n",
			c_median, asm_median, delta,
			BENCH486_TEXTURE_ANIMATION_ITERATIONS, BENCH486_MEMORY_SAMPLES);
}
#endif

static void Bench486SetLightMapNormalizeInput (unsigned *lights, int size,
		int pattern)
{
	int i;

	for (i=0 ; i<size ; i++)
	{
		if (pattern == 0)
			lights[i] = (unsigned)((i * 257 + 3) & 0xffff);
		else if (pattern == 1)
			lights[i] = 0xffff;
		else
		{
			switch (i & 7)
			{
			case 0: lights[i] = 0; break;
			case 1: lights[i] = 1; break;
			case 2: lights[i] = 64; break;
			case 3: lights[i] = 256; break;
			case 4: lights[i] = 32768; break;
			case 5: lights[i] = 64000; break;
			case 6: lights[i] = 65280; break;
			default: lights[i] = 65535; break;
			}
		}
	}
}

static unsigned Bench486LightMapNormalizeChecksum (unsigned *lights, int size)
{
	unsigned checksum;
	int i;

	checksum = 0;
	for (i=0 ; i<size ; i++)
		checksum += lights[i];
	return checksum;
}

static double Bench486MeasureLightMapNormalize (
		bench486_lightmap_normalize_fn_t function, unsigned *initial,
		unsigned *lights, int size, int iterations, unsigned *checksum)
{
	double start, elapsed;
	int i;

	for (i=0 ; i<BENCH486_MEMORY_WARMUP ; i++)
	{
		Q_memcpy (lights, initial, size * sizeof(unsigned));
		function (lights, size);
	}

	start = Sys_FloatTime ();
	for (i=0 ; i<iterations ; i++)
		function (lights, size);
	elapsed = Sys_FloatTime () - start;

	*checksum = Bench486LightMapNormalizeChecksum (lights, size);
	bench486_sink ^= *checksum;
	return elapsed;
}

static void Bench486LightMapNormalizeCase (char *name, int size, int pattern)
{
	unsigned *initial, *c_result, *asm_result;
	double c_samples[BENCH486_LIGHTMAP_NORMALIZE_SAMPLES];
	double asm_samples[BENCH486_LIGHTMAP_NORMALIZE_SAMPLES];
	double c_median, asm_median, delta;
	unsigned c_checksum, asm_checksum;
	int i, sample;

	initial = (unsigned *)(((long)bench486_source + 3) & ~3);
	c_result = (unsigned *)(((long)bench486_expected + 3) & ~3);
	asm_result = (unsigned *)(((long)bench486_dest + 3) & ~3);
	Bench486SetLightMapNormalizeInput (initial, size, pattern);
	Q_memcpy (c_result, initial, size * sizeof(unsigned));
	Q_memcpy (asm_result, initial, size * sizeof(unsigned));
	R_BuildLightMapNormalize_C (c_result, size);
	R_BuildLightMapNormalize_asm486 (asm_result, size);
	if (Q_memcmp (c_result, asm_result, size * sizeof(unsigned)) != 0)
	{
		bench486_memory_failures++;
		Bench486Printf ("lightmap-normalize %s correctness FAIL\n", name);
		return;
	}

	for (sample=0 ; sample<BENCH486_LIGHTMAP_NORMALIZE_SAMPLES; sample++)
	{
		if ((sample & 1) == 0)
		{
			c_samples[sample] = Bench486MeasureLightMapNormalize (
					R_BuildLightMapNormalize_C, initial, c_result, size,
					BENCH486_LIGHTMAP_NORMALIZE_ITERATIONS, &c_checksum);
			asm_samples[sample] = Bench486MeasureLightMapNormalize (
					R_BuildLightMapNormalize_asm486, initial, asm_result, size,
					BENCH486_LIGHTMAP_NORMALIZE_ITERATIONS, &asm_checksum);
		}
		else
		{
			asm_samples[sample] = Bench486MeasureLightMapNormalize (
					R_BuildLightMapNormalize_asm486, initial, asm_result, size,
					BENCH486_LIGHTMAP_NORMALIZE_ITERATIONS, &asm_checksum);
			c_samples[sample] = Bench486MeasureLightMapNormalize (
					R_BuildLightMapNormalize_C, initial, c_result, size,
					BENCH486_LIGHTMAP_NORMALIZE_ITERATIONS, &c_checksum);
		}

		if (Q_memcmp (c_result, asm_result, size * sizeof(unsigned)) != 0 ||
				c_checksum != asm_checksum)
		{
			bench486_memory_failures++;
			Bench486Printf ("lightmap-normalize %s checksum correctness FAIL\n",
					name);
			return;
		}
	}

	Bench486SortSamples (c_samples, BENCH486_LIGHTMAP_NORMALIZE_SAMPLES);
	Bench486SortSamples (asm_samples, BENCH486_LIGHTMAP_NORMALIZE_SAMPLES);
	c_median = c_samples[BENCH486_LIGHTMAP_NORMALIZE_SAMPLES / 2];
	asm_median = asm_samples[BENCH486_LIGHTMAP_NORMALIZE_SAMPLES / 2];
	delta = c_median > 0.0 ?
			(c_median - asm_median) / c_median * 100.0 : 0.0;
	Bench486Printf ("lightmap-normalize %s size %d pattern %d iterations %d samples %d\n",
			name, size, pattern, BENCH486_LIGHTMAP_NORMALIZE_ITERATIONS,
			BENCH486_LIGHTMAP_NORMALIZE_SAMPLES);
	Bench486Printf ("  c median %.6f sec checksum %u samples",
			c_median, c_checksum);
	for (i=0 ; i<BENCH486_LIGHTMAP_NORMALIZE_SAMPLES ; i++)
		Bench486Printf (" %.6f", c_samples[i]);
	Bench486Printf ("\n");
	Bench486Printf ("  asm486 median %.6f sec checksum %u samples",
			asm_median, asm_checksum);
	for (i=0 ; i<BENCH486_LIGHTMAP_NORMALIZE_SAMPLES ; i++)
		Bench486Printf (" %.6f", asm_samples[i]);
	Bench486Printf ("\n");
	Bench486Printf ("  asm486-vs-c median %.3f percent\n", delta);
}

static void Bench486LightMapNormalizeCases (void)
{
	Bench486LightMapNormalizeCase ("small-normal", 16, 0);
	Bench486LightMapNormalizeCase ("full-clamp", 64, 1);
	Bench486LightMapNormalizeCase ("mixed-324", 324, 2);
}

static void Bench486SetLightMapStylesInput (byte *lightmap, int size,
		int maps, int pattern)
{
	int i, map;

	for (map=0 ; map<maps ; map++)
		for (i=0 ; i<size ; i++)
			lightmap[map*size+i] = (byte)((i*17 + map*31 + pattern*7) & 255);
}

static unsigned Bench486LightMapStylesChecksum (unsigned *dest, int size)
{
	unsigned checksum;
	int i;

	checksum = 0;
	for (i=0 ; i<size ; i++)
		checksum += dest[i];
	return checksum;
}

static double Bench486MeasureLightMapStyles (
		bench486_lightmap_styles_fn_t function, unsigned *dest, byte *lightmap,
		int size, int maps, unsigned scale, unsigned *lightadj,
		int iterations, unsigned *checksum)
{
	double start, elapsed;
	int i;

	for (i=0 ; i<BENCH486_MEMORY_WARMUP ; i++)
		function (dest, lightmap, size, maps, scale, lightadj);
	start = Sys_FloatTime ();
	for (i=0 ; i<iterations ; i++)
		function (dest, lightmap, size, maps, scale, lightadj);
	elapsed = Sys_FloatTime () - start;
	*checksum = Bench486LightMapStylesChecksum (dest, size);
	bench486_sink ^= *checksum;
	return elapsed;
}

static void Bench486LightMapStylesCase (char *name, int size, int maps,
		int pattern, int unaligned)
{
	byte *lightmap;
	unsigned *c_result, *asm_result;
	int lightadj[4];
	double c_samples[BENCH486_LIGHTMAP_STYLES_SAMPLES];
	double asm_samples[BENCH486_LIGHTMAP_STYLES_SAMPLES];
	double c_median, asm_median, delta;
	unsigned c_checksum, asm_checksum;
	int i, sample, mismatch;

	lightmap = bench486_source + unaligned;
	c_result = (unsigned *)(bench486_expected + unaligned);
	asm_result = (unsigned *)(bench486_dest + unaligned);
	Bench486SetLightMapStylesInput (lightmap, size, maps, pattern);
	for (i=0 ; i<4 ; i++)
		lightadj[i] = 64 + i*73 + pattern*11;
	R_BuildLightMapStyles_C (c_result, lightmap, size, maps,
			pattern*257, lightadj);
	R_BuildLightMapStyles_asm486 (asm_result, lightmap, size, maps,
			pattern*257, lightadj);
	mismatch = -1;
	for (i=0 ; i<size ; i++)
		if (c_result[i] != asm_result[i])
		{
			mismatch = i;
			break;
		}
	if (mismatch >= 0)
	{
		bench486_memory_failures++;
		Bench486Printf ("lightmap-styles %s correctness FAIL index %d c %u asm %u",
				name, mismatch, c_result[mismatch], asm_result[mismatch]);
		return;
	}

	for (sample=0 ; sample<BENCH486_LIGHTMAP_STYLES_SAMPLES ; sample++)
	{
		if ((sample & 1) == 0)
		{
			c_samples[sample] = Bench486MeasureLightMapStyles(
					R_BuildLightMapStyles_C, c_result, lightmap, size, maps,
					pattern*257, lightadj, BENCH486_LIGHTMAP_STYLES_ITERATIONS,
					&c_checksum);
			asm_samples[sample] = Bench486MeasureLightMapStyles(
					R_BuildLightMapStyles_asm486, asm_result, lightmap, size, maps,
					pattern*257, lightadj, BENCH486_LIGHTMAP_STYLES_ITERATIONS,
					&asm_checksum);
		}
		else
		{
			asm_samples[sample] = Bench486MeasureLightMapStyles(
					R_BuildLightMapStyles_asm486, asm_result, lightmap, size, maps,
					pattern*257, lightadj, BENCH486_LIGHTMAP_STYLES_ITERATIONS,
					&asm_checksum);
			c_samples[sample] = Bench486MeasureLightMapStyles(
					R_BuildLightMapStyles_C, c_result, lightmap, size, maps,
					pattern*257, lightadj, BENCH486_LIGHTMAP_STYLES_ITERATIONS,
					&c_checksum);
		}
		if (c_checksum != asm_checksum)
		{
			bench486_memory_failures++;
			Bench486Printf ("lightmap-styles %s checksum correctness FAIL", name);
			return;
		}
	}

	Bench486SortSamples (c_samples, BENCH486_LIGHTMAP_STYLES_SAMPLES);
	Bench486SortSamples (asm_samples, BENCH486_LIGHTMAP_STYLES_SAMPLES);
	c_median = c_samples[BENCH486_LIGHTMAP_STYLES_SAMPLES / 2];
	asm_median = asm_samples[BENCH486_LIGHTMAP_STYLES_SAMPLES / 2];
	delta = c_median > 0.0 ? (c_median - asm_median) / c_median * 100.0 : 0.0;
	Bench486Printf ("lightmap-styles %s size %d maps %d unaligned %d samples %d",
			name, size, maps, unaligned, BENCH486_LIGHTMAP_STYLES_SAMPLES);
	Bench486Printf ("  c median %.6f sec checksum %u", c_median, c_checksum);
	Bench486Printf ("  asm486 median %.6f sec checksum %u",
			asm_median, asm_checksum);
	Bench486Printf ("  asm486-vs-c median %.3f percent", delta);
}

static void Bench486LightMapStylesCases (void)
{
	static int sizes[] = { 1, 2, 3, 15, 16, 17, 63, 64, 65, 324 };
	int i, maps;
	char name[32];

	for (maps=1 ; maps<=4 ; maps++)
		for (i=0 ; i<10 ; i++)
		{
			sprintf (name, "styles-%d-%d", maps, sizes[i]);
			Bench486LightMapStylesCase (name, sizes[i], maps,
					(i + maps) & 3, i & 1);
		}
}

static void Bench486FusedLightMapCases (void)
{
	static int sizes[] = { 1, 2, 3, 15, 16, 17, 63, 64, 65, 324 };
	byte *lightmap;
	unsigned *c_result, *asm_result;
	int lightadj[4];
	int i, j, maps, mismatch;
	unsigned c_checksum, asm_checksum;

	for (maps=2 ; maps<=4 ; maps++)
		for (i=0 ; i<10 ; i++)
		{
			lightmap = bench486_source + (i & 1);
			c_result = (unsigned *)(bench486_expected + (i & 1));
			asm_result = (unsigned *)(bench486_dest + (i & 1));
			Bench486SetLightMapStylesInput (lightmap, sizes[i], maps,
					(i + maps) & 3);
			for (j=0 ; j<4 ; j++)
				lightadj[j] = 64 + j*73 + ((i + maps) & 3)*11;
			R_BuildLightMapFusedNoDlights_C (c_result, lightmap, sizes[i],
					maps, ((i + maps) & 3)*257, lightadj);
			R_BuildLightMapFusedNoDlights_asm486 (asm_result, lightmap,
					sizes[i], maps, ((i + maps) & 3)*257, lightadj);
			mismatch = -1;
			for (j=0 ; j<sizes[i] ; j++)
				if (c_result[j] != asm_result[j])
				{
					mismatch = j;
					break;
				}
			c_checksum = Bench486LightMapStylesChecksum (c_result, sizes[i]);
			asm_checksum = Bench486LightMapStylesChecksum (asm_result, sizes[i]);
			if (mismatch >= 0 || c_checksum != asm_checksum)
			{
				bench486_memory_failures++;
				Bench486Printf ("fused-lightmap maps %d size %d correctness FAIL index %d c %u asm %u",
						maps, sizes[i], mismatch,
						c_result[mismatch], asm_result[mismatch]);
			}
			bench486_sink ^= c_checksum ^ asm_checksum;
		}
}

#ifdef ASM486_LIGHTMAP_BUILD
static int Bench486LightMapBuildCase (char *name, int maps, int ambient,
		int fullbright, int has_lightdata, int has_samples, int dlight_mode,
		int warm_cache)
{
	static msurface_t surface;
	static model_t world;
	static mplane_t plane;
	static mtexinfo_t texinfo;
	static byte lightmaps[MAXLIGHTMAPS * 324];
	static byte lightdata_marker;
	static unsigned starting_lights[324];
	static unsigned c_result[324];
	static unsigned c_table[256];
	static unsigned starting_table[256];
	unsigned c_first, c_inverse;
	qboolean c_valid;
	int c_dlight, size, i, map, t, inverse_scale, mismatch;

	Q_memset (&surface, 0, sizeof(surface));
	Q_memset (&world, 0, sizeof(world));
	Q_memset (&plane, 0, sizeof(plane));
	Q_memset (&texinfo, 0, sizeof(texinfo));
	surface.extents[0] = 32;
	surface.extents[1] = 16;
	surface.dlightframe = dlight_mode ? r_framecount : r_framecount - 1;
	surface.dlightbits = dlight_mode == 2 ? 1 : 0;
	surface.plane = &plane;
	surface.texinfo = &texinfo;
	surface.samples = has_samples ? lightmaps : NULL;
	for (map=0 ; map<MAXLIGHTMAPS ; map++)
		surface.styles[map] = map < maps ? (byte)map : 255;
	for (i=0 ; i<MAXLIGHTMAPS*6 ; i++)
		lightmaps[i] = (byte)(i*37 + (i/6)*19 + 11);
	world.lightdata = has_lightdata ? &lightdata_marker : NULL;
	cl.worldmodel = &world;
	plane.normal[2] = 1.0;
	texinfo.vecs[0][0] = 1.0;
	texinfo.vecs[1][1] = 1.0;
	for (map=0 ; map<MAXLIGHTMAPS ; map++)
		r_drawsurf.lightadj[map] = 47 + map*71;
	r_drawsurf.surf = &surface;
	r_refdef.ambientlight = ambient;
	r_fullbright.value = (float)fullbright;
	size = 3 * 2;
	if (dlight_mode == 2)
	{
		cl_dlights[0].origin[0] = 8.0;
		cl_dlights[0].origin[1] = 8.0;
		cl_dlights[0].origin[2] = 0.0;
		cl_dlights[0].radius = 64.0;
		cl_dlights[0].minlight = 0.0;
	}

	for (i=0 ; i<324 ; i++)
		starting_lights[i] = 0xa5a50000U | (unsigned)i;
	Q_memcpy (blocklights, starting_lights, sizeof(starting_lights));
	if (warm_cache)
	{
		unsigned first;
		first = (unsigned)r_drawsurf.lightadj[0];
		inverse_scale = 255*256 - (ambient << 8);
		for (i=0 ; i<256 ; i++)
		{
			t = (inverse_scale - (int)(i * first)) >> (8 - VID_CBITS);
			if (t < (1 << 6))
				t = (1 << 6);
			lightmap_single_table[i] = (unsigned)t;
		}
		lightmap_single_first = first;
		lightmap_single_inverse_scale = inverse_scale;
		lightmap_single_table_valid = true;
	}
	else
	{
		lightmap_single_table_valid = false;
		lightmap_single_first = 0x13579;
		lightmap_single_inverse_scale = -12345;
	}
	Q_memcpy (starting_table, lightmap_single_table,
			sizeof(starting_table));
	c_first = lightmap_single_first;
	c_inverse = (unsigned)lightmap_single_inverse_scale;
	c_valid = lightmap_single_table_valid;
	r_dlight_contributed = 0x2468;

	R_BuildLightMap_C ();
	Q_memcpy (c_result, blocklights, sizeof(c_result));
	Q_memcpy (c_table, lightmap_single_table, sizeof(c_table));
	c_first = lightmap_single_first;
	c_inverse = (unsigned)lightmap_single_inverse_scale;
	c_valid = lightmap_single_table_valid;
	c_dlight = r_dlight_contributed;

	Q_memcpy (blocklights, starting_lights, sizeof(starting_lights));
	Q_memcpy (lightmap_single_table, starting_table, sizeof(starting_table));
	if (warm_cache)
	{
		lightmap_single_first = (unsigned)r_drawsurf.lightadj[0];
		lightmap_single_inverse_scale = 255*256 - (ambient << 8);
		lightmap_single_table_valid = true;
	}
	else
	{
		lightmap_single_first = 0x13579;
		lightmap_single_inverse_scale = -12345;
		lightmap_single_table_valid = false;
	}
	r_dlight_contributed = 0x2468;
	R_BuildLightMap ();

	mismatch = -1;
	for (i=0 ; i<324 ; i++)
		if (c_result[i] != blocklights[i])
		{
			mismatch = i;
			break;
		}
	if (mismatch >= 0 ||
			Q_memcmp (c_table, lightmap_single_table, sizeof(c_table)) != 0 ||
			c_first != lightmap_single_first ||
			c_inverse != (unsigned)lightmap_single_inverse_scale ||
			c_valid != lightmap_single_table_valid ||
			c_dlight != r_dlight_contributed)
	{
		bench486_memory_failures++;
		if (mismatch >= 0)
			Bench486Printf ("lightmap-build %s parity FAIL index %d c %u asm %u\n",
					name, mismatch, c_result[mismatch], blocklights[mismatch]);
		else
			Bench486Printf ("lightmap-build %s state parity FAIL\n", name);
		return 1;
	}
	return 0;
}
#endif

#if defined(ASM486_DYNAMIC_LIGHT_PROJECTION)
static int Bench486DynamicLightProjectParity (void)
{
	static struct
	{
		char *name;
		float origin[3];
		float radius, minlight;
		float normal[3], dist;
		float vecs[2][4];
		short texturemins[2];
		int smax, tmax;
	} cases[] = {
		{ "center", { 8.0, 8.0, 0.0 }, 64.0, 0.0,
			{ 0.0, 0.0, 1.0 }, 0.0,
			{ { 1.0, 0.0, 0.0, 0.0 }, { 0.0, 1.0, 0.0, 0.0 } },
			{ 0, 0 }, 3, 2 },
		{ "negative-fraction", { -3.75, 21.75, 2.25 }, 96.0, 1.0,
			{ 0.0, 0.0, 1.0 }, 1.25,
			{ { 1.0, 0.0, 0.0, 2.25 }, { 0.0, 1.0, 0.0, -3.5 } },
			{ 5, -7 }, 4, 3 },
		{ "outside-surface", { 63.25, 46.5, -3.0 }, 160.0, 12.0,
			{ 0.0, 0.0, 1.0 }, -2.0,
			{ { 1.0, 0.0, 0.0, -0.75 }, { 0.0, 1.0, 0.0, 1.5 } },
			{ -16, 9 }, 3, 2 },
		{ "minlight-equal", { 2.5, 4.25, 10.0 }, 20.0, 10.0,
			{ 0.0, 0.0, 1.0 }, 0.0,
			{ { 1.0, 0.0, 0.0, 0.0 }, { 0.0, 1.0, 0.0, 0.0 } },
			{ 0, 0 }, 2, 2 },
		{ "minlight-reject", { 2.5, 4.25, 10.0 }, 19.0, 10.0,
			{ 0.0, 0.0, 1.0 }, 0.0,
			{ { 1.0, 0.0, 0.0, 0.0 }, { 0.0, 1.0, 0.0, 0.0 } },
			{ 0, 0 }, 2, 2 },
		{ "ceil-boundary", { 17.25, -8.5, 0.0 }, 10.125, 9.99609375,
			{ 0.0, 0.0, 1.0 }, 0.0,
			{ { 1.0, 0.0, 0.0, 0.125 }, { 0.0, 1.0, 0.0, -0.25 } },
			{ 1, -3 }, 2, 3 },
		{ "tilted-plane", { 21.25, -8.75, 7.5 }, 128.0, 8.0,
			{ 0.25, -0.5, 0.75 }, 3.125,
			{ { 0.75, 0.125, -0.25, 5.5 },
			  { -0.125, 0.5, 0.25, -2.75 } },
			{ -11, 19 }, 5, 4 },
		{ "all-lit", { 4.0, 7.0, 0.0 }, 2048.0, 0.0,
			{ 0.0, 0.0, 1.0 }, 0.0,
			{ { 1.0, 0.0, 0.0, 0.0 }, { 0.0, 1.0, 0.0, 0.0 } },
			{ 0, 0 }, 18, 18 },
		{ "corner-clamp", { -16.0, -16.0, 0.0 }, 80.0, 0.5,
			{ 0.0, 0.0, 1.0 }, 0.0,
			{ { 1.0, 0.0, 0.0, 0.0 }, { 0.0, 1.0, 0.0, 0.0 } },
			{ 0, 0 }, 1, 1 }
	};
	static msurface_t surface;
	static mplane_t plane;
	static mtexinfo_t texinfo;
	static const unsigned short rounding[4] = {
		0x0000, 0x0400, 0x0800, 0x0c00
	};
	unsigned short saved_cw, test_cw;
	float c_local0, c_local1, asm_local0, asm_local1;
	int c_local0_int, c_local1_int, c_limit, c_irad, c_all_lit;
	int asm_local0_int, asm_local1_int, asm_limit, asm_irad, asm_all_lit;
	int c_result, asm_result, failures, i, mode;
#ifdef ASM486_DLIGHT_CONTRIBUTES
	int c_contributes, asm_contributes;
#endif

	__asm__ __volatile__ ("fnstcw %0" : "=m" (saved_cw));
	failures = 0;
	for (mode=0 ; mode<4 ; mode++)
	{
		test_cw = (saved_cw & (unsigned short)~0x0c00) | rounding[mode];
		__asm__ __volatile__ ("fldcw %0" : : "m" (test_cw));
		for (i=0 ; i<(int)(sizeof(cases)/sizeof(cases[0])) ; i++)
		{
			Q_memset (&surface, 0, sizeof(surface));
			Q_memset (&plane, 0, sizeof(plane));
			Q_memset (&texinfo, 0, sizeof(texinfo));
			plane.normal[0] = cases[i].normal[0];
			plane.normal[1] = cases[i].normal[1];
			plane.normal[2] = cases[i].normal[2];
			plane.dist = cases[i].dist;
			surface.plane = &plane;
			surface.texinfo = &texinfo;
			surface.texturemins[0] = cases[i].texturemins[0];
			surface.texturemins[1] = cases[i].texturemins[1];
			surface.extents[0] = (short)((cases[i].smax - 1) * 16);
			surface.extents[1] = (short)((cases[i].tmax - 1) * 16);
			surface.dlightbits = 1;
			Q_memcpy (texinfo.vecs, cases[i].vecs, sizeof(texinfo.vecs));
			cl_dlights[0].origin[0] = cases[i].origin[0];
			cl_dlights[0].origin[1] = cases[i].origin[1];
			cl_dlights[0].origin[2] = cases[i].origin[2];
			cl_dlights[0].radius = cases[i].radius;
			cl_dlights[0].minlight = cases[i].minlight;

			c_local0 = 0.0;
			c_local1 = 0.0;
			asm_local0 = 0.0;
			asm_local1 = 0.0;
			c_local0_int = c_local1_int = c_limit = c_irad = c_all_lit = 0;
			asm_local0_int = asm_local1_int = asm_limit = asm_irad =
					asm_all_lit = 0;
			c_result = R_AddDynamicLightProject_C (0, &surface,
					cases[i].smax, cases[i].tmax, &c_local0, &c_local1,
					&c_local0_int, &c_local1_int, &c_limit, &c_irad,
					&c_all_lit);
			asm_result = R_AddDynamicLightProject_asm486 (0, &surface,
					cases[i].smax, cases[i].tmax, &asm_local0, &asm_local1,
					&asm_local0_int, &asm_local1_int, &asm_limit, &asm_irad,
					&asm_all_lit);
#ifdef ASM486_DLIGHT_CONTRIBUTES
			c_contributes = R_DlightContributes_C (&surface);
			asm_contributes = R_DlightContributes_asm486 (&surface);
#endif
			if (c_result != asm_result ||
					Q_memcmp (&c_local0, &asm_local0, sizeof(c_local0)) != 0 ||
					Q_memcmp (&c_local1, &asm_local1, sizeof(c_local1)) != 0 ||
					c_local0_int != asm_local0_int ||
					c_local1_int != asm_local1_int || c_limit != asm_limit ||
					c_irad != asm_irad || c_all_lit != asm_all_lit
#ifdef ASM486_DLIGHT_CONTRIBUTES
					|| c_contributes != asm_contributes
#endif
					)
			{
				failures++;
				Bench486Printf ("dlight-project parity FAIL %s round %d c %d asm %d",
						cases[i].name, mode, c_result, asm_result);
#ifdef ASM486_DLIGHT_CONTRIBUTES
				Bench486Printf (" contributes %d/%d", c_contributes,
						asm_contributes);
#endif
				Bench486Printf ("\n");
			}
		}
	}
	__asm__ __volatile__ ("fldcw %0" : : "m" (saved_cw));
	Bench486Printf ("dynamic-light projection parity %s (%d cases)\n",
			failures ? "FAIL" : "PASS", 4 * (int)(sizeof(cases)/sizeof(cases[0])));
	if (failures)
		bench486_memory_failures += failures;
	return failures;
}
#endif

#if defined(ASM486_DYNAMIC_LIGHT_PUSH) && defined(BENCH486)
typedef struct
{
	double time;
	int frame;
	unsigned int future_mask;
	unsigned int deadline_mask;
	unsigned int zero_mask;
	unsigned int negative_zero_mask;
	unsigned int expected_bits;
	int has_world;
} bench486_push_dlights_case_t;

static int Bench486PushDlightsParity (void)
{
	static const bench486_push_dlights_case_t cases[] = {
		{ 1.0, 17, 0x80000001U, 0x00000010U, 0x00000200U,
			0x00000400U, 0x80000011U, 1 },
		{ 2.5, 92, 0xffffffffU, 0x00000000U, 0x00000000U,
			0x00000000U, 0xffffffffU, 1 },
		{ 4.0, 300, 0x00000000U, 0x80000000U, 0x00000000U,
			0x00000000U, 0x80000000U, 1 },
		{ 16.0, 0, 0x00000000U, 0x00000000U, 0x00000001U,
			0x00000002U, 0x00000000U, 1 },
		{ 0.125, 7, 0x00000000U, 0x00000000U, 0x00000000U,
			0x00000000U, 0x00000000U, 0 }
	};
	static model_t fixture_model;
	static mnode_t nodes[3];
	static mplane_t plane;
	static mtexinfo_t texinfo;
	static msurface_t surface;
	static dlight_t saved_lights[MAX_DLIGHTS];
	static int failures;
	static int test;
	static int i;
	static int c_frame;
	static int c_surface_frame;
	static int c_surface_bits;
	static int expected_surface_frame;
	static int saved_frame;
	static int saved_dlight_frame;
	static double saved_time;
	static model_t *saved_worldmodel;
	static bench486_mark_lights_probe_t *saved_probe;
	const bench486_push_dlights_case_t *test_case;
	const int untouched_frame = -777;
	const int untouched_bits = 0x12345678;

	failures = 0;
	saved_frame = r_framecount;
	saved_dlight_frame = r_dlightframecount;
	saved_time = cl.time;
	saved_worldmodel = cl.worldmodel;
	Q_memcpy (saved_lights, cl_dlights, sizeof(saved_lights));
	saved_probe = bench486_mark_lights_probe;
	bench486_mark_lights_probe = NULL;

	Q_memset (&fixture_model, 0, sizeof(fixture_model));
	Q_memset (nodes, 0, sizeof(nodes));
	Q_memset (&plane, 0, sizeof(plane));
	Q_memset (&texinfo, 0, sizeof(texinfo));
	Q_memset (&surface, 0, sizeof(surface));
	plane.normal[0] = 1.0;
	nodes[0].contents = 0;
	nodes[0].plane = &plane;
	nodes[0].children[0] = &nodes[1];
	nodes[0].children[1] = &nodes[2];
	nodes[0].firstsurface = 0;
	nodes[0].numsurfaces = 1;
	nodes[1].contents = -1;
	nodes[2].contents = -1;
	surface.plane = &plane;
	surface.texinfo = &texinfo;
	fixture_model.nodes = nodes;
	fixture_model.surfaces = &surface;

	for (test = 0; test < (int)(sizeof(cases) / sizeof(cases[0])); test++)
	{
		test_case = &cases[test];
		cl.time = test_case->time;
		cl.worldmodel = test_case->has_world ? &fixture_model : NULL;
		r_framecount = test_case->frame;
		for (i = 0; i < MAX_DLIGHTS; i++)
		{
			unsigned int bit;
			dlight_t *light;

			bit = 1U << i;
			light = &cl_dlights[i];
			Q_memset (light, 0, sizeof(*light));
			light->die = (float)(test_case->time - 1.0);
			light->radius = 16.0;
			if (test_case->future_mask & bit)
				light->die = (float)(test_case->time + 1.0);
			if (test_case->deadline_mask & bit)
				light->die = (float)test_case->time;
			if (test_case->zero_mask & bit)
			{
				light->die = (float)(test_case->time + 1.0);
				light->radius = 0.0;
			}
			if (test_case->negative_zero_mask & bit)
			{
				light->die = (float)(test_case->time + 1.0);
				light->radius = -0.0;
			}
		}

		surface.dlightframe = untouched_frame;
		surface.dlightbits = untouched_bits;
		R_PushDlights_C ();
		c_frame = r_dlightframecount;
		c_surface_frame = surface.dlightframe;
		c_surface_bits = surface.dlightbits;

		surface.dlightframe = untouched_frame;
		surface.dlightbits = untouched_bits;
		R_PushDlights ();
		expected_surface_frame = test_case->expected_bits ?
				test_case->frame + 1 : untouched_frame;
		if (c_frame != test_case->frame + 1 ||
				c_surface_frame != expected_surface_frame ||
				c_surface_bits != (test_case->expected_bits ?
					test_case->expected_bits : untouched_bits) ||
				r_dlightframecount != c_frame ||
				surface.dlightframe != c_surface_frame ||
				surface.dlightbits != c_surface_bits)
		{
			failures++;
			Bench486Printf ("R_PushDlights parity case %d failed\n", test);
		}
	}

	r_framecount = saved_frame;
	r_dlightframecount = saved_dlight_frame;
	cl.time = saved_time;
	cl.worldmodel = saved_worldmodel;
	Q_memcpy (cl_dlights, saved_lights, sizeof(saved_lights));
	bench486_mark_lights_probe = saved_probe;
	Bench486Printf ("R_PushDlights C/assembly parity: %s (%d cases)\n",
			failures ? "FAIL" : "PASS",
			(int)(sizeof(cases) / sizeof(cases[0])));
	if (failures)
		bench486_memory_failures += failures;
	return failures;
}
#endif

#if defined(ASM486_MARK_LIGHTS) && defined(BENCH486)
static int Bench486MarkLightsParity (void)
{
	static model_t fixture_model;
	static mnode_t nodes[7];
	static mplane_t node_planes[3];
	static mplane_t surface_planes[6];
	static mtexinfo_t texinfo[6];
	static msurface_t c_surfaces[6];
	static msurface_t asm_surfaces[6];
	static bench486_mark_lights_probe_t c_probe[6];
	static bench486_mark_lights_probe_t asm_probe[6];
	static const unsigned short rounding[4] = {
		0x0000, 0x0400, 0x0800, 0x0c00
	};
	dlight_t light;
	model_t *saved_worldmodel;
	unsigned short saved_cw, test_cw, current_cw;
	int saved_dlightframe, failures, mode, test, i, surface_index;
	int bit;
	unsigned seed;

	__asm__ __volatile__ ("fnstcw %0" : "=m" (saved_cw));
	saved_worldmodel = cl.worldmodel;
	saved_dlightframe = r_dlightframecount;
	cl.worldmodel = &fixture_model;
	failures = 0;

	for (mode=0 ; mode<4 ; mode++)
	{
		test_cw = (saved_cw & (unsigned short)~0x0c00) | rounding[mode];
		__asm__ __volatile__ ("fldcw %0" : : "m" (test_cw));
		for (test=0 ; test<32 ; test++)
		{
			seed = 0x6d2b79f5u ^ (unsigned)test * 0x9e3779b9u;
			for (i=0 ; i<16 ; i++)
				seed = seed * 1664525u + 1013904223u;
			r_dlightframecount = 1000 + mode * 32 + test;
			light.origin[0] = ((int)(seed & 0x1ff) - 256) * 0.5f;
			light.origin[1] = ((int)((seed >> 9) & 0x1ff) - 256) * 0.5f;
			light.origin[2] = ((int)((seed >> 18) & 0x1ff) - 256) * 0.5f;
			light.radius = 24.0f + (float)((seed >> 5) % 224);
			light.minlight = (float)((seed >> 14) % 12);
			if ((test & 7) == 0)
				light.minlight = light.radius;
			light.die = 0.0f;
			light.decay = 0.0f;
			light.key = test;

			Q_memset (nodes, 0, sizeof(nodes));
			Q_memset (node_planes, 0, sizeof(node_planes));
			Q_memset (surface_planes, 0, sizeof(surface_planes));
			Q_memset (texinfo, 0, sizeof(texinfo));
			Q_memset (c_surfaces, 0, sizeof(c_surfaces));

			// A three-node BSP covers both strict plane rejects, an intersecting
			// parent, and recursive child visits with independent surface ranges.
			node_planes[0].normal[0] = 1.0f;
			node_planes[1].normal[1] = 1.0f;
			node_planes[2].normal[2] = 1.0f;
			node_planes[0].dist = 0.0f;
			node_planes[1].dist = ((test % 5) - 2) * 16.0f;
			node_planes[2].dist = (((test + 2) % 5) - 2) * 16.0f;
			if ((test & 7) == 1)
				light.origin[0] = light.radius;
			else if ((test & 7) == 2)
				light.origin[0] = -light.radius;
			else if ((test & 7) == 3)
				light.origin[0] = light.radius + 0.5f;
			else if ((test & 7) == 4)
				light.origin[0] = -light.radius - 0.5f;

			nodes[0].contents = nodes[1].contents = nodes[2].contents = 0;
			nodes[0].plane = &node_planes[0];
			nodes[1].plane = &node_planes[1];
			nodes[2].plane = &node_planes[2];
			nodes[0].children[0] = &nodes[1];
			nodes[0].children[1] = &nodes[2];
			nodes[1].children[0] = &nodes[3];
			nodes[1].children[1] = &nodes[4];
			nodes[2].children[0] = &nodes[5];
			nodes[2].children[1] = &nodes[6];
			nodes[0].firstsurface = 0;
			nodes[0].numsurfaces = 2;
			nodes[1].firstsurface = 2;
			nodes[1].numsurfaces = 2;
			nodes[2].firstsurface = 4;
			nodes[2].numsurfaces = 2;
			for (i=3 ; i<7 ; i++)
				nodes[i].contents = -1;

			for (i=0 ; i<6 ; i++)
			{
				unsigned local_seed;
				int axis;

				local_seed = seed + (unsigned)i * 0x45d9f3bu;
				axis = i % 3;
				surface_planes[i].normal[axis] = 1.0f;
				surface_planes[i].normal[(axis + 1) % 3] =
						(float)((int)(local_seed & 3) - 1) * 0.125f;
				surface_planes[i].dist =
						(float)((int)((local_seed >> 4) & 0x7f) - 64) * 0.5f;
				c_surfaces[i].plane = &surface_planes[i];
				c_surfaces[i].texinfo = &texinfo[i];
				c_surfaces[i].texturemins[0] =
						(short)(((int)((local_seed >> 12) & 7) - 3) * 16);
				c_surfaces[i].texturemins[1] =
						(short)(((int)((local_seed >> 16) & 7) - 3) * 16);
				c_surfaces[i].extents[0] =
						(short)(((local_seed >> 20) & 15) * 16);
				c_surfaces[i].extents[1] =
						(short)(((local_seed >> 24) & 15) * 16);
				c_surfaces[i].dlightframe =
						((i + test) % 3) ? r_dlightframecount : 0;
				c_surfaces[i].dlightbits = (int)(local_seed >> 1);

				texinfo[i].vecs[0][0] = 1.0f;
				texinfo[i].vecs[0][1] =
						(float)((int)((local_seed >> 2) & 7) - 3) * 0.125f;
				texinfo[i].vecs[0][2] =
						(float)((int)((local_seed >> 5) & 3) - 1) * 0.0625f;
				texinfo[i].vecs[0][3] =
						(float)((int)((local_seed >> 7) & 15) - 7) * 0.25f;
				texinfo[i].vecs[1][0] =
						(float)((int)((local_seed >> 11) & 3) - 1) * 0.0625f;
				texinfo[i].vecs[1][1] = 1.0f;
				texinfo[i].vecs[1][2] =
						(float)((int)((local_seed >> 14) & 7) - 3) * 0.125f;
				texinfo[i].vecs[1][3] =
						(float)((int)((local_seed >> 17) & 15) - 7) * 0.25f;
			}
			Q_memcpy (asm_surfaces, c_surfaces, sizeof(c_surfaces));
			Q_memset (c_probe, 0, sizeof(c_probe));
			Q_memset (asm_probe, 0, sizeof(asm_probe));
			fixture_model.surfaces = c_surfaces;
			bit = (int)(1UL << (test % 31));

			bench486_mark_lights_probe = c_probe;
			R_MarkLights_C (&light, bit, &nodes[0]);
			__asm__ __volatile__ ("fnstcw %0" : "=m" (current_cw));
			fixture_model.surfaces = asm_surfaces;
			bench486_mark_lights_probe = asm_probe;
			R_MarkLights_asm486 (&light, bit, &nodes[0]);
			bench486_mark_lights_probe = NULL;
			__asm__ __volatile__ ("fnstcw %0" : "=m" (test_cw));
			if (current_cw != test_cw || test_cw !=
					((saved_cw & (unsigned short)~0x0c00) | rounding[mode]) ||
					Q_memcmp (c_surfaces, asm_surfaces,
							sizeof(c_surfaces)) != 0)
			{
				failures++;
				for (surface_index=0 ; surface_index<6 ; surface_index++)
				{
					if (c_surfaces[surface_index].dlightframe !=
							asm_surfaces[surface_index].dlightframe ||
						c_surfaces[surface_index].dlightbits !=
							asm_surfaces[surface_index].dlightbits)
					{
						Bench486Printf ("mark-lights parity FAIL round %d case %d surface %d frame %d/%d bits %u/%u\n",
								mode, test, surface_index,
								c_surfaces[surface_index].dlightframe,
								asm_surfaces[surface_index].dlightframe,
								(unsigned)c_surfaces[surface_index].dlightbits,
								(unsigned)asm_surfaces[surface_index].dlightbits);
						Bench486Printf ("  probe stage %d/%d plane %.6g/%.6g rad %.6g/%.6g fmin %.6g/%d vs %.6g/%d\n",
								c_probe[surface_index].stage,
								asm_probe[surface_index].stage,
								c_probe[surface_index].planedist,
								asm_probe[surface_index].planedist,
								c_probe[surface_index].rad,
								asm_probe[surface_index].rad,
								c_probe[surface_index].fmin,
								c_probe[surface_index].fmin_scaled,
								asm_probe[surface_index].fmin,
								asm_probe[surface_index].fmin_scaled);
						Bench486Printf ("  local %.6g,%.6g / %.6g,%.6g clamp %.6g,%.6g / %.6g,%.6g dist %d,%d,%d / %d,%d,%d mark %d/%d\n",
								c_probe[surface_index].local0,
								c_probe[surface_index].local1,
								asm_probe[surface_index].local0,
								asm_probe[surface_index].local1,
								c_probe[surface_index].cs,
								c_probe[surface_index].ct,
								asm_probe[surface_index].cs,
								asm_probe[surface_index].ct,
								c_probe[surface_index].sd,
								c_probe[surface_index].td,
								c_probe[surface_index].idist,
								asm_probe[surface_index].sd,
								asm_probe[surface_index].td,
								asm_probe[surface_index].idist,
								c_probe[surface_index].marked,
								asm_probe[surface_index].marked);
						break;
					}
				}
				if (surface_index == 6)
					Bench486Printf ("mark-lights state/control-word parity FAIL round %d case %d\n",
							mode, test);
			}
		}
	}
	__asm__ __volatile__ ("fldcw %0" : : "m" (saved_cw));
	cl.worldmodel = saved_worldmodel;
	r_dlightframecount = saved_dlightframe;
	Bench486Printf ("BSP dynamic-light marking parity %s (%d cases, 4 x87 modes)\n",
			failures ? "FAIL" : "PASS", 32);
	if (failures)
		bench486_memory_failures += failures;
	return failures;
}
#endif

#ifdef ASM486_LIGHTMAP_BUILD
static void Bench486LightMapBuildParity (void)
{
	drawsurf_t saved_drawsurf;
	model_t *saved_worldmodel;
	dlight_t saved_dlight;
	unsigned saved_blocklights[324];
	unsigned saved_lightmap_table[256];
	unsigned saved_lightmap_first;
	int saved_lightmap_inverse, saved_ambient, saved_frame;
	int saved_dlight_contributed;
	qboolean saved_lightmap_valid;
	float saved_fullbright;
	int failures, i;
#ifdef PROFILE486
	unsigned long saved_single_texels, saved_fused_texels;
	unsigned long saved_fused_maps[5];
#endif

	saved_drawsurf = r_drawsurf;
	saved_worldmodel = cl.worldmodel;
	saved_dlight = cl_dlights[0];
	Q_memcpy (saved_blocklights, blocklights, sizeof(saved_blocklights));
	Q_memcpy (saved_lightmap_table, lightmap_single_table,
			sizeof(saved_lightmap_table));
	saved_lightmap_first = lightmap_single_first;
	saved_lightmap_inverse = lightmap_single_inverse_scale;
	saved_lightmap_valid = lightmap_single_table_valid;
	saved_ambient = r_refdef.ambientlight;
	saved_fullbright = r_fullbright.value;
	saved_frame = r_framecount;
	saved_dlight_contributed = r_dlight_contributed;
#ifdef PROFILE486
	saved_single_texels = bench486_lm_single_texels;
	saved_fused_texels = bench486_lm_fused_texels;
	for (i=0 ; i<5 ; i++)
		saved_fused_maps[i] = bench486_lm_fused_maps[i];
#endif
	r_framecount = saved_frame + 100;
	cl.worldmodel = NULL;
	failures = 0;
	failures += Bench486LightMapBuildCase ("fullbright-positive", 1, 24,
			1, 1, 1, 0, 0);
	failures += Bench486LightMapBuildCase ("fullbright-negative", 2, 24,
			-1, 1, 1, 0, 0);
	failures += Bench486LightMapBuildCase ("no-lightdata", 1, 24,
			0, 0, 1, 0, 0);
	failures += Bench486LightMapBuildCase ("ambient-no-samples", 0, 36,
			0, 1, 0, 0, 0);
	failures += Bench486LightMapBuildCase ("single-style-cold", 1, 36,
			0, 1, 1, 0, 0);
	failures += Bench486LightMapBuildCase ("single-style-warm", 1, 36,
			0, 1, 1, 0, 1);
	failures += Bench486LightMapBuildCase ("no-dlight-2-style", 2, 16,
			0, 1, 1, 0, 0);
	failures += Bench486LightMapBuildCase ("no-dlight-3-style", 3, 16,
			0, 1, 1, 0, 0);
	failures += Bench486LightMapBuildCase ("no-dlight-4-style", 4, 16,
			0, 1, 1, 0, 0);
	failures += Bench486LightMapBuildCase ("active-empty-dlights", 2, 16,
			0, 1, 1, 1, 0);
	failures += Bench486LightMapBuildCase ("active-real-dlight", 1, 16,
			0, 1, 1, 2, 0);
#ifdef ASM486_DYNAMIC_LIGHT_PROJECTION
	failures += Bench486DynamicLightProjectParity ();
#endif

	r_drawsurf = saved_drawsurf;
	cl.worldmodel = saved_worldmodel;
	cl_dlights[0] = saved_dlight;
	Q_memcpy (blocklights, saved_blocklights, sizeof(saved_blocklights));
	Q_memcpy (lightmap_single_table, saved_lightmap_table,
			sizeof(saved_lightmap_table));
	lightmap_single_first = saved_lightmap_first;
	lightmap_single_inverse_scale = saved_lightmap_inverse;
	lightmap_single_table_valid = saved_lightmap_valid;
	r_refdef.ambientlight = saved_ambient;
	r_fullbright.value = saved_fullbright;
	r_framecount = saved_frame;
	r_dlight_contributed = saved_dlight_contributed;
#ifdef PROFILE486
	bench486_lm_single_texels = saved_single_texels;
	bench486_lm_fused_texels = saved_fused_texels;
	for (i=0 ; i<5 ; i++)
		bench486_lm_fused_maps[i] = saved_fused_maps[i];
#else
	(void)i;
#endif
	Bench486Printf ("lightmap-build dispatcher parity %s (%d scenarios)\n",
			failures ? "FAIL" : "PASS", 11);
}
#endif

#ifdef ASM486_SURFACE_DRAW
static void Bench486CaptureSurfaceDrawState (
		bench486_surface_draw_state_t *state, byte *pixels)
{
	Q_memset (state, 0, sizeof(*state));
	state->lightleft = lightleft;
	state->sourcesstep = sourcesstep;
	state->blocksize = blocksize;
	state->sourcetstep = sourcetstep;
	state->lightdelta = lightdelta;
	state->lightdeltastep = lightdeltastep;
	state->lightright = lightright;
	state->lightleftstep = lightleftstep;
	state->lightrightstep = lightrightstep;
	state->blockdivshift = blockdivshift;
	state->blockdivmask = blockdivmask;
	state->surfrowbytes = surfrowbytes;
	state->r_stepback = r_stepback;
	state->r_lightwidth = r_lightwidth;
	state->r_numhblocks = r_numhblocks;
	state->r_numvblocks = r_numvblocks;
	state->r_lightptr = r_lightptr;
	state->pbasesource = pbasesource;
	state->r_source = r_source;
	state->r_sourcemax = r_sourcemax;
	state->prowdest_offset = (byte *)prowdestbase - pixels;
}

static void Bench486SurfaceDrawParity (void)
{
	/* Keep diagnostic label pointers in writable data, with no executable-table
	   ambiguity when link addresses change. The labels themselves are unchanged. */
	static char *volatile mode_names[5] = {
		"fullbright", "no-lightdata", "ambient", "one-style", "four-style"
	};
	drawsurf_t saved_drawsurf;
	model_t *saved_worldmodel;
	float saved_fullbright;
	int saved_frame, saved_ambient, saved_contributed;
	int saved_profile_active;
	bench486_surface_draw_state_t c_state, asm_state;
	texture_t *texture;
	byte *texture_bytes;
	int texture_width, texture_height, cursor, mip_width, mip_height;
	int texture_kind, mip, mode, x, y, i, output_size, case_index, failures;
	byte *texture_row;
	int saved_lightleft, saved_sourcesstep, saved_blocksize, saved_sourcetstep;
	int saved_lightdelta, saved_lightdeltastep;
	int saved_lightright, saved_lightleftstep, saved_lightrightstep;
	int saved_blockdivshift, saved_surfrowbytes, saved_stepback;
	int saved_lightwidth, saved_numhblocks, saved_numvblocks;
	unsigned saved_blockdivmask;
	void *saved_prowdestbase;
	byte *saved_pbasesource, *saved_source, *saved_sourcemax;
	unsigned *saved_lightptr;

	saved_drawsurf = r_drawsurf;
	saved_worldmodel = cl.worldmodel;
	saved_fullbright = r_fullbright.value;
	saved_frame = r_framecount;
	saved_ambient = r_refdef.ambientlight;
	saved_contributed = r_dlight_contributed;
	saved_lightleft = lightleft;
	saved_sourcesstep = sourcesstep;
	saved_blocksize = blocksize;
	saved_sourcetstep = sourcetstep;
	saved_lightdelta = lightdelta;
	saved_lightdeltastep = lightdeltastep;
	saved_lightright = lightright;
	saved_lightleftstep = lightleftstep;
	saved_lightrightstep = lightrightstep;
	saved_blockdivshift = blockdivshift;
	saved_blockdivmask = blockdivmask;
	saved_prowdestbase = prowdestbase;
	saved_pbasesource = pbasesource;
	saved_surfrowbytes = surfrowbytes;
	saved_lightptr = r_lightptr;
	saved_stepback = r_stepback;
	saved_lightwidth = r_lightwidth;
	saved_numhblocks = r_numhblocks;
	saved_numvblocks = r_numvblocks;
	saved_source = r_source;
	saved_sourcemax = r_sourcemax;
#ifdef PROFILE486
	saved_profile_active = bench486_profile_frame_active;
	bench486_profile_frame_active = false;
#else
	saved_profile_active = 0;
#endif
	Q_memcpy (bench486_surface_draw_saved_lights, blocklights,
			sizeof(bench486_surface_draw_saved_lights));

	failures = 0;
	case_index = 0;
	for (texture_kind=0 ; texture_kind<2 ; texture_kind++)
	{
		texture_width = texture_kind ? 60 : 64;
		texture_height = texture_kind ? 44 : 64;
		Q_memset (&bench486_surface_draw_texture, 0,
				sizeof(bench486_surface_draw_texture));
		texture = &bench486_surface_draw_texture.align;
		texture_bytes = bench486_surface_draw_texture.storage;
		texture->width = texture_width;
		texture->height = texture_height;
		cursor = sizeof(texture_t);
		for (mip=0 ; mip<4 ; mip++)
		{
			mip_width = texture_width >> mip;
			mip_height = texture_height >> mip;
			texture->offsets[mip] = cursor;
			texture_row = texture_bytes + cursor;
			for (y=0 ; y<mip_height ; y++)
			{
				for (x=0 ; x<mip_width ; x++)
				{
					texture_row[x] =
							(byte)(x*17 + y*31 + mip*43 + texture_kind*59);
				}
				texture_row += mip_width;
				cursor += mip_width;
			}
		}

		for (mip=0 ; mip<4 ; mip++)
		{
			for (mode=0 ; mode<5 ; mode++)
			{
				Q_memset (&bench486_surface_draw_surface, 0,
						sizeof(bench486_surface_draw_surface));
				bench486_surface_draw_surface.extents[0] = 48;
				bench486_surface_draw_surface.extents[1] = 32;
				bench486_surface_draw_surface.texturemins[0] =
						((mip + texture_kind) & 1) ? -17 : 137;
				bench486_surface_draw_surface.texturemins[1] =
						((mip + mode) & 1) ? -29 : 91;
				bench486_surface_draw_surface.dlightframe = saved_frame;
				for (i=0 ; i<MAXLIGHTMAPS ; i++)
					bench486_surface_draw_surface.styles[i] = 255;
				for (i=0 ; i<(int)sizeof(bench486_surface_draw_samples) ; i++)
					bench486_surface_draw_samples[i] = (byte)(i*23 + mode*41 + 7);

				Q_memset (&bench486_surface_draw_model, 0,
						sizeof(bench486_surface_draw_model));
				if (mode >= 2)
					bench486_surface_draw_model.lightdata =
							bench486_surface_draw_samples;
				cl.worldmodel = &bench486_surface_draw_model;
				r_framecount = saved_frame + 1;
				bench486_surface_draw_surface.dlightframe = r_framecount - 1;
				r_refdef.ambientlight = 17;
				r_fullbright.value = mode == 0 ? 1.0 : 0.0;
				bench486_surface_draw_surface.samples = NULL;
				if (mode == 3)
				{
					bench486_surface_draw_surface.styles[0] = 0;
					bench486_surface_draw_surface.samples =
							bench486_surface_draw_samples;
				}
				else if (mode == 4)
				{
					for (i=0 ; i<MAXLIGHTMAPS ; i++)
						bench486_surface_draw_surface.styles[i] = i;
					bench486_surface_draw_surface.samples =
							bench486_surface_draw_samples;
				}

				r_drawsurf.surf = &bench486_surface_draw_surface;
				r_drawsurf.texture = texture;
				r_drawsurf.surfmip = mip;
				r_drawsurf.surfwidth = 48 >> mip;
				r_drawsurf.surfheight = 32 >> mip;
				r_drawsurf.rowbytes = r_drawsurf.surfwidth;
				for (i=0 ; i<MAXLIGHTMAPS ; i++)
					r_drawsurf.lightadj[i] = 61 + i*47;
				output_size = 1536;
				for (i=0 ; i<mip+mip ; i++)
					output_size >>= 1;
				Q_memset (bench486_surface_draw_c_pixels, 0xa5,
						sizeof(bench486_surface_draw_c_pixels));
				Q_memset (bench486_surface_draw_asm_pixels, 0xa5,
						sizeof(bench486_surface_draw_asm_pixels));
				Q_memset (blocklights, 0x5a, sizeof(bench486_surface_draw_saved_lights));
				r_drawsurf.surfdat = (pixel_t *)bench486_surface_draw_c_pixels;
				R_DrawSurface_C ();
				Q_memcpy (bench486_surface_draw_c_lights, blocklights,
						sizeof(bench486_surface_draw_c_lights));
				Bench486CaptureSurfaceDrawState (&c_state,
						bench486_surface_draw_c_pixels);

				Q_memset (blocklights, 0x5a, sizeof(bench486_surface_draw_saved_lights));
				r_drawsurf.surfdat = (pixel_t *)bench486_surface_draw_asm_pixels;
				R_DrawSurface ();
				Bench486CaptureSurfaceDrawState (&asm_state,
						bench486_surface_draw_asm_pixels);
				if (Q_memcmp (bench486_surface_draw_c_pixels,
						bench486_surface_draw_asm_pixels,
						sizeof(bench486_surface_draw_c_pixels)) != 0 ||
						Q_memcmp (bench486_surface_draw_c_lights, blocklights,
						sizeof(bench486_surface_draw_c_lights)) != 0 ||
						Q_memcmp (&c_state, &asm_state, sizeof(c_state)) != 0)
				{
					failures++;
					Bench486Printf ("surface-draw parity FAIL texture %s mip %d light %s\n",
							texture_kind ? "nonpot" : "pot", mip,
							mode_names[mode]);
				}
				else
					bench486_sink += bench486_surface_draw_c_pixels[
							case_index % output_size];
				case_index++;
			}
		}
	}

	r_drawsurf = saved_drawsurf;
	cl.worldmodel = saved_worldmodel;
	r_fullbright.value = saved_fullbright;
	r_framecount = saved_frame;
	r_refdef.ambientlight = saved_ambient;
	r_dlight_contributed = saved_contributed;
	lightleft = saved_lightleft;
	sourcesstep = saved_sourcesstep;
	blocksize = saved_blocksize;
	sourcetstep = saved_sourcetstep;
	lightdelta = saved_lightdelta;
	lightdeltastep = saved_lightdeltastep;
	lightright = saved_lightright;
	lightleftstep = saved_lightleftstep;
	lightrightstep = saved_lightrightstep;
	blockdivshift = saved_blockdivshift;
	blockdivmask = saved_blockdivmask;
	prowdestbase = saved_prowdestbase;
	pbasesource = saved_pbasesource;
	surfrowbytes = saved_surfrowbytes;
	r_lightptr = saved_lightptr;
	r_stepback = saved_stepback;
	r_lightwidth = saved_lightwidth;
	r_numhblocks = saved_numhblocks;
	r_numvblocks = saved_numvblocks;
	r_source = saved_source;
	r_sourcemax = saved_sourcemax;
	Q_memcpy (blocklights, bench486_surface_draw_saved_lights,
			sizeof(bench486_surface_draw_saved_lights));
#ifdef PROFILE486
	bench486_profile_frame_active = saved_profile_active;
#endif
	if (failures)
		bench486_memory_failures += failures;
	Bench486Printf ("surface-draw parity %s (%d cases: four mips, two texture shapes, five light modes)\n",
			failures ? "FAIL" : "PASS", case_index);
}
#endif

static double Bench486MeasureBspPlaneDot (bench486_bsp_plane_dot_fn_t function,
		mplane_t *plane, int iterations, unsigned *checksum)
{
	double start, elapsed, result_sum;
	int i;

	for (i=0 ; i<BENCH486_MEMORY_WARMUP ; i++)
		function (plane);

	start = Sys_FloatTime ();
	result_sum = 0;
	for (i=0 ; i<iterations ; i++)
		result_sum += function (plane);
	elapsed = Sys_FloatTime () - start;

	*checksum = (unsigned)(result_sum * 1000.0);
	bench486_sink ^= *checksum;
	return elapsed;
}

static void Bench486BspPlaneDotCase (char *name, int type, float nx,
		float ny, float nz, float dist)
{
	mplane_t plane;
	float saved_modelorg[3];
	double c_samples[BENCH486_BSP_PLANE_DOT_SAMPLES];
	double asm_samples[BENCH486_BSP_PLANE_DOT_SAMPLES];
	double c_median, asm_median, delta;
	double c_result, asm_result;
	unsigned c_checksum, asm_checksum;
	int i, sample, failure;

	saved_modelorg[0] = modelorg[0];
	saved_modelorg[1] = modelorg[1];
	saved_modelorg[2] = modelorg[2];
	modelorg[0] = 1.25;
	modelorg[1] = -3.5;
	modelorg[2] = 7.75;

	Q_memset (&plane, 0, sizeof(plane));
	plane.normal[0] = nx;
	plane.normal[1] = ny;
	plane.normal[2] = nz;
	plane.dist = dist;
	plane.type = type;

	c_result = R_RecursiveWorldNodePlaneDot_C (&plane);
	asm_result = R_RecursiveWorldNodePlaneDot_asm486 (&plane);
	failure = c_result != asm_result;
	if (failure)
	{
		bench486_memory_failures++;
		Bench486Printf ("bsp-plane-dot %s correctness FAIL c %.9f asm %.9f\n",
				name, c_result, asm_result);
	}

	if (!failure)
	{
		for (sample=0 ; sample<BENCH486_BSP_PLANE_DOT_SAMPLES; sample++)
		{
			if ((sample & 1) == 0)
			{
				c_samples[sample] = Bench486MeasureBspPlaneDot (
						R_RecursiveWorldNodePlaneDot_C, &plane,
						BENCH486_BSP_PLANE_DOT_ITERATIONS, &c_checksum);
				asm_samples[sample] = Bench486MeasureBspPlaneDot (
						R_RecursiveWorldNodePlaneDot_asm486, &plane,
						BENCH486_BSP_PLANE_DOT_ITERATIONS, &asm_checksum);
			}
			else
			{
				asm_samples[sample] = Bench486MeasureBspPlaneDot (
						R_RecursiveWorldNodePlaneDot_asm486, &plane,
						BENCH486_BSP_PLANE_DOT_ITERATIONS, &asm_checksum);
				c_samples[sample] = Bench486MeasureBspPlaneDot (
						R_RecursiveWorldNodePlaneDot_C, &plane,
						BENCH486_BSP_PLANE_DOT_ITERATIONS, &c_checksum);
			}

			if (c_checksum != asm_checksum)
			{
				bench486_memory_failures++;
				Bench486Printf ("bsp-plane-dot %s checksum correctness FAIL\n",
						name);
				failure = 1;
				break;
			}
		}
	}

	if (!failure)
	{
		Bench486SortSamples (c_samples, BENCH486_BSP_PLANE_DOT_SAMPLES);
		Bench486SortSamples (asm_samples, BENCH486_BSP_PLANE_DOT_SAMPLES);
		c_median = c_samples[BENCH486_BSP_PLANE_DOT_SAMPLES / 2];
		asm_median = asm_samples[BENCH486_BSP_PLANE_DOT_SAMPLES / 2];
		delta = c_median > 0.0 ?
				(c_median - asm_median) / c_median * 100.0 : 0.0;
		Bench486Printf ("bsp-plane-dot %s type %d iterations %d samples %d\n",
				name, type, BENCH486_BSP_PLANE_DOT_ITERATIONS,
				BENCH486_BSP_PLANE_DOT_SAMPLES);
		Bench486Printf ("  c median %.6f sec checksum %u samples",
				c_median, c_checksum);
		for (i=0 ; i<BENCH486_BSP_PLANE_DOT_SAMPLES ; i++)
			Bench486Printf (" %.6f", c_samples[i]);
		Bench486Printf ("\n");
		Bench486Printf ("  asm486 median %.6f sec checksum %u samples",
				asm_median, asm_checksum);
		for (i=0 ; i<BENCH486_BSP_PLANE_DOT_SAMPLES ; i++)
			Bench486Printf (" %.6f", asm_samples[i]);
		Bench486Printf ("\n");
		Bench486Printf ("  asm486-vs-c median %.3f percent\n", delta);
	}

	modelorg[0] = saved_modelorg[0];
	modelorg[1] = saved_modelorg[1];
	modelorg[2] = saved_modelorg[2];
}

static void Bench486BspPlaneDotCases (void)
{
	Bench486BspPlaneDotCase ("axis-x", PLANE_X, 1.0, 0.0, 0.0, 0.5);
	Bench486BspPlaneDotCase ("axis-y", PLANE_Y, 0.0, 1.0, 0.0, -2.0);
	Bench486BspPlaneDotCase ("axis-z", PLANE_Z, 0.0, 0.0, 1.0, 3.0);
	Bench486BspPlaneDotCase ("generic", 3, 0.25, -0.5, 1.5, 2.25);
}

static double Bench486MeasureBspClip (bench486_bsp_clip_fn_t function,
		mnode_t *node, int clipflags, int iterations, unsigned *checksum)
{
	double start, elapsed;
	unsigned result_sum;
	int i, result;

	for (i=0 ; i<BENCH486_MEMORY_WARMUP ; i++)
		function (node, clipflags);

	start = Sys_FloatTime ();
	result_sum = 0;
	for (i=0 ; i<iterations ; i++)
	{
		result = function (node, clipflags);
		result_sum = result_sum * 33 + (unsigned)(result + 1);
	}
	elapsed = Sys_FloatTime () - start;

	*checksum = result_sum;
	bench486_sink ^= result_sum;
	return elapsed;
}

static void Bench486BspClipCase (char *name, int clipflags, int mode)
{
	mnode_t node;
	clipplane_t saved_clipplanes[4];
	int *saved_indexes[4];
	int indexes[4][6];
	double c_samples[BENCH486_BSP_CLIP_SAMPLES];
	double asm_samples[BENCH486_BSP_CLIP_SAMPLES];
	double c_median, asm_median, delta;
	unsigned c_checksum, asm_checksum;
	int i, j, failure, c_result, asm_result;

	for (i=0 ; i<4 ; i++)
	{
		saved_clipplanes[i] = view_clipplanes[i];
		saved_indexes[i] = pfrustum_indexes[i];
		pfrustum_indexes[i] = indexes[i];
	}

	Q_memset (&node, 0, sizeof(node));
	node.minmaxs[0] = -10;
	node.minmaxs[1] = -20;
	node.minmaxs[2] = -30;
	node.minmaxs[3] = 10;
	node.minmaxs[4] = 20;
	node.minmaxs[5] = 30;

	/* Match R_SetUpFrustumIndexes for the signs used below. */
	for (i=0 ; i<4 ; i++)
	{
		for (j=0 ; j<3 ; j++)
		{
			if (i == 1 && j == 0)
			{
				indexes[i][j] = j;
				indexes[i][j+3] = j+3;
			}
			else
			{
				indexes[i][j] = j+3;
				indexes[i][j+3] = j;
			}
		}
		Q_memset (&view_clipplanes[i], 0, sizeof(view_clipplanes[i]));
		view_clipplanes[i].normal[0] = i == 1 ? -1.0 : 1.0;
		view_clipplanes[i].normal[1] = 0.5;
		view_clipplanes[i].normal[2] = i == 3 ? -0.25 : 0.75;
		view_clipplanes[i].dist = mode == 0 ? -100.0 :
				(mode == 2 && i == 0 ? 100.0 : 0.0);
	}
	c_result = R_RecursiveWorldNodeClip_C (&node, clipflags);
	asm_result = R_RecursiveWorldNodeClip_asm486 (&node, clipflags);
	failure = c_result != asm_result;
	if (failure)
	{
		bench486_memory_failures++;
		Bench486Printf ("bsp-clip %s correctness FAIL c %d asm %d\n",
				name, c_result, asm_result);
	}

	if (!failure)
	{
		for (i=0 ; i<BENCH486_BSP_CLIP_SAMPLES ; i++)
		{
			if ((i & 1) == 0)
			{
				c_samples[i] = Bench486MeasureBspClip (
						R_RecursiveWorldNodeClip_C, &node, clipflags,
						BENCH486_BSP_CLIP_ITERATIONS, &c_checksum);
				asm_samples[i] = Bench486MeasureBspClip (
						R_RecursiveWorldNodeClip_asm486, &node, clipflags,
						BENCH486_BSP_CLIP_ITERATIONS, &asm_checksum);
			}
			else
			{
				asm_samples[i] = Bench486MeasureBspClip (
						R_RecursiveWorldNodeClip_asm486, &node, clipflags,
						BENCH486_BSP_CLIP_ITERATIONS, &asm_checksum);
				c_samples[i] = Bench486MeasureBspClip (
						R_RecursiveWorldNodeClip_C, &node, clipflags,
						BENCH486_BSP_CLIP_ITERATIONS, &c_checksum);
			}

			if (c_checksum != asm_checksum)
			{
				bench486_memory_failures++;
				Bench486Printf ("bsp-clip %s checksum correctness FAIL\n",
						name);
				failure = 1;
				break;
			}
		}
	}

	if (!failure)
	{
		Bench486SortSamples (c_samples, BENCH486_BSP_CLIP_SAMPLES);
		Bench486SortSamples (asm_samples, BENCH486_BSP_CLIP_SAMPLES);
		c_median = c_samples[BENCH486_BSP_CLIP_SAMPLES / 2];
		asm_median = asm_samples[BENCH486_BSP_CLIP_SAMPLES / 2];
		delta = c_median > 0.0 ?
				(c_median - asm_median) / c_median * 100.0 : 0.0;
		Bench486Printf ("bsp-clip %s flags %d mode %d iterations %d samples %d result %d\n",
				name, clipflags, mode, BENCH486_BSP_CLIP_ITERATIONS,
				BENCH486_BSP_CLIP_SAMPLES, c_result);
		Bench486Printf ("  c median %.6f sec checksum %u samples",
				c_median, c_checksum);
		for (i=0 ; i<BENCH486_BSP_CLIP_SAMPLES ; i++)
			Bench486Printf (" %.6f", c_samples[i]);
		Bench486Printf ("\n");
		Bench486Printf ("  asm486 median %.6f sec checksum %u samples",
				asm_median, asm_checksum);
		for (i=0 ; i<BENCH486_BSP_CLIP_SAMPLES ; i++)
			Bench486Printf (" %.6f", asm_samples[i]);
		Bench486Printf ("\n");
		Bench486Printf ("  asm486-vs-c median %.3f percent\n", delta);
	}

	for (i=0 ; i<4 ; i++)
	{
		view_clipplanes[i] = saved_clipplanes[i];
		pfrustum_indexes[i] = saved_indexes[i];
	}
}

static void Bench486BspClipCases (void)
{
	Bench486BspClipCase ("none", 0, 0);
	Bench486BspClipCase ("all-visible", 15, 0);
	Bench486BspClipCase ("partial", 15, 1);
	Bench486BspClipCase ("early-reject", 15, 2);
	Bench486BspClipCase ("single-plane", 1, 1);
}

static double Bench486MeasureAliasBBoxProject (
		bench486_alias_bbox_project_fn_t function, auxvert_t *viewaux,
		finalvert_t *viewpts, int numv, int iterations, unsigned *checksum)
{
	double start, elapsed;
	unsigned result_sum;
	int i, result;

	for (i=0 ; i<BENCH486_MEMORY_WARMUP ; i++)
		function (viewaux, viewpts, numv);

	start = Sys_FloatTime ();
	result_sum = 0;
	for (i=0 ; i<iterations ; i++)
	{
		result = function (viewaux, viewpts, numv);
		result_sum = result_sum * 33 + (unsigned)result;
	}
	elapsed = Sys_FloatTime () - start;

	*checksum = result_sum;
	bench486_sink ^= result_sum;
	return elapsed;
}

static void Bench486AliasBBoxProjectCase (char *name, int numv,
	int zmask, int mode)
{
	auxvert_t viewaux[16];
	finalvert_t viewpts[16];
	double c_samples[BENCH486_ALIAS_BBOX_PROJECT_SAMPLES];
	double asm_samples[BENCH486_ALIAS_BBOX_PROJECT_SAMPLES];
	double c_median, asm_median, delta;
	float saved_xscale, saved_yscale, saved_xcenter, saved_ycenter;
	float saved_fvrectx, saved_fvrecty;
	float saved_fvrectright, saved_fvrectbottom;
	unsigned c_checksum, asm_checksum;
	int i, sample, c_result, asm_result, failure;

	saved_xscale = aliasxscale;
	saved_yscale = aliasyscale;
	saved_xcenter = aliasxcenter;
	saved_ycenter = aliasycenter;
	saved_fvrectx = r_refdef.fvrectx;
	saved_fvrecty = r_refdef.fvrecty;
	saved_fvrectright = r_refdef.fvrectright;
	saved_fvrectbottom = r_refdef.fvrectbottom;

	aliasxscale = 320.0;
	aliasyscale = 240.0;
	aliasxcenter = 160.0;
	aliasycenter = 120.0;
	r_refdef.fvrectx = 0.0;
	r_refdef.fvrecty = 0.0;
	r_refdef.fvrectright = 320.0;
	r_refdef.fvrectbottom = 240.0;

	Q_memset (viewaux, 0, sizeof(viewaux));
	Q_memset (viewpts, 0, sizeof(viewpts));
	for (i=0 ; i<numv ; i++)
	{
		viewaux[i].fv[2] = 8.0 + (float)(i & 3);
		if (mode == 1)
		{
			switch (i & 3)
			{
			case 0:
				viewaux[i].fv[0] = -8.0;
				break;
			case 1:
				viewaux[i].fv[0] = 8.0;
				break;
			case 2:
				viewaux[i].fv[1] = -8.0;
				break;
			default:
				viewaux[i].fv[1] = 8.0;
				break;
			}
		}
		else if (mode == 2)
		{
			viewaux[i].fv[0] = -12.0;
		}
		else
		{
			viewaux[i].fv[0] = 0.25;
			viewaux[i].fv[1] = -0.25;
		}
		if (zmask & (1 << i))
			viewpts[i].flags = ALIAS_Z_CLIP;
	}

	c_result = R_AliasCheckBBoxProject_C (viewaux, viewpts, numv);
	asm_result = R_AliasCheckBBoxProject_asm486 (viewaux, viewpts, numv);
	failure = c_result != asm_result;
	if (failure)
	{
		bench486_memory_failures++;
		Bench486Printf ("alias-bbox-project %s correctness FAIL c 0x%x asm 0x%x\n",
				name, c_result, asm_result);
	}

	if (!failure)
	{
		for (sample=0 ; sample<BENCH486_ALIAS_BBOX_PROJECT_SAMPLES ; sample++)
		{
			if ((sample & 1) == 0)
			{
				c_samples[sample] = Bench486MeasureAliasBBoxProject (
						R_AliasCheckBBoxProject_C, viewaux, viewpts, numv,
						BENCH486_ALIAS_BBOX_PROJECT_ITERATIONS, &c_checksum);
				asm_samples[sample] = Bench486MeasureAliasBBoxProject (
						R_AliasCheckBBoxProject_asm486, viewaux, viewpts, numv,
						BENCH486_ALIAS_BBOX_PROJECT_ITERATIONS, &asm_checksum);
			}
			else
			{
				asm_samples[sample] = Bench486MeasureAliasBBoxProject (
						R_AliasCheckBBoxProject_asm486, viewaux, viewpts, numv,
						BENCH486_ALIAS_BBOX_PROJECT_ITERATIONS, &asm_checksum);
				c_samples[sample] = Bench486MeasureAliasBBoxProject (
						R_AliasCheckBBoxProject_C, viewaux, viewpts, numv,
						BENCH486_ALIAS_BBOX_PROJECT_ITERATIONS, &c_checksum);
			}

			if (c_checksum != asm_checksum)
			{
				bench486_memory_failures++;
				Bench486Printf ("alias-bbox-project %s checksum correctness FAIL\n",
						name);
				failure = 1;
				break;
			}
		}
	}

	if (!failure)
	{
		Bench486SortSamples (c_samples,
				BENCH486_ALIAS_BBOX_PROJECT_SAMPLES);
		Bench486SortSamples (asm_samples,
				BENCH486_ALIAS_BBOX_PROJECT_SAMPLES);
		c_median = c_samples[BENCH486_ALIAS_BBOX_PROJECT_SAMPLES / 2];
		asm_median = asm_samples[BENCH486_ALIAS_BBOX_PROJECT_SAMPLES / 2];
		delta = c_median > 0.0 ?
				(c_median - asm_median) / c_median * 100.0 : 0.0;
		Bench486Printf ("alias-bbox-project %s vertices %d zmask 0x%x mode %d "
				"iterations %d samples %d result 0x%x\n",
				name, numv, zmask, mode,
				BENCH486_ALIAS_BBOX_PROJECT_ITERATIONS,
				BENCH486_ALIAS_BBOX_PROJECT_SAMPLES, c_result);
		Bench486Printf ("  c median %.6f sec checksum %u samples",
				c_median, c_checksum);
		for (i=0 ; i<BENCH486_ALIAS_BBOX_PROJECT_SAMPLES ; i++)
			Bench486Printf (" %.6f", c_samples[i]);
		Bench486Printf ("\n");
		Bench486Printf ("  asm486 median %.6f sec checksum %u samples",
				asm_median, asm_checksum);
		for (i=0 ; i<BENCH486_ALIAS_BBOX_PROJECT_SAMPLES ; i++)
			Bench486Printf (" %.6f", asm_samples[i]);
		Bench486Printf ("\n");
		Bench486Printf ("  asm486-vs-c median %.3f percent\n", delta);
	}

	aliasxscale = saved_xscale;
	aliasyscale = saved_yscale;
	aliasxcenter = saved_xcenter;
	aliasycenter = saved_ycenter;
	r_refdef.fvrectx = saved_fvrectx;
	r_refdef.fvrecty = saved_fvrecty;
	r_refdef.fvrectright = saved_fvrectright;
	r_refdef.fvrectbottom = saved_fvrectbottom;
}

#ifdef ASM486_ALIAS_BBOX_PROJECT
static void Bench486AliasTransformVectorCase (char *name, int row_order)
{
	vec3_t input, c_output, asm_output;
	float saved_transform[3][4];
	unsigned c_words[3], asm_words[3];
	unsigned checksum;
	int i, failure;

	for (i=0 ; i<3 ; i++)
	{
		saved_transform[i][0] = aliastransform[i][0];
		saved_transform[i][1] = aliastransform[i][1];
		saved_transform[i][2] = aliastransform[i][2];
		saved_transform[i][3] = aliastransform[i][3];
	}

	aliastransform[0][0] = 0.125;
	aliastransform[0][1] = -0.25;
	aliastransform[0][2] = 0.5;
	aliastransform[0][3] = 1.0;
	aliastransform[1][0] = -0.375;
	aliastransform[1][1] = 0.625;
	aliastransform[1][2] = 0.25;
	aliastransform[1][3] = -2.0;
	aliastransform[2][0] = 0.5;
	aliastransform[2][1] = 0.25;
	aliastransform[2][2] = -0.125;
	aliastransform[2][3] = 3.0;
	input[0] = 12.5;
	input[1] = -24.25;
	input[2] = 56.5;

	if (row_order)
	{
		/*
		 * With the reference order, (x * 3*2^63) + (-3*2^63) + z
		 * returns z.  Adding z before the translation rounds it away in
		 * the 64-bit x87 significand, so this catches translation-last code.
		 */
		input[0] = 1.0;
		input[1] = 0.0;
		input[2] = 1.0;
		aliastransform[0][0] = 27670116110564327424.0;
		aliastransform[0][1] = 0.0;
		aliastransform[0][2] = 1.0;
		aliastransform[0][3] = -27670116110564327424.0;
	}

	R_AliasTransformVector_C (input, c_output);
	R_AliasTransformVector_asm486 (input, asm_output);
	failure = Q_memcmp (c_output, asm_output, sizeof(c_output)) != 0;
	if (failure)
	{
		bench486_memory_failures++;
		Q_memcpy (c_words, c_output, sizeof(c_words));
		Q_memcpy (asm_words, asm_output, sizeof(asm_words));
		Bench486Printf ("alias-bbox-transform %s correctness FAIL c "
				"%08x %08x %08x asm %08x %08x %08x\n", name,
				c_words[0], c_words[1], c_words[2],
				asm_words[0], asm_words[1], asm_words[2]);
	}
	else
	{
		checksum = Bench486Checksum ((byte *)c_output, sizeof(c_output));
		Bench486Printf ("alias-bbox-transform %s exact result %u\n",
				name, checksum);
	}

	for (i=0 ; i<3 ; i++)
	{
		aliastransform[i][0] = saved_transform[i][0];
		aliastransform[i][1] = saved_transform[i][1];
		aliastransform[i][2] = saved_transform[i][2];
		aliastransform[i][3] = saved_transform[i][3];
	}
}

static void Bench486AliasTransformVectorCases (void)
{
	Bench486AliasTransformVectorCase ("fractional", 0);
	Bench486AliasTransformVectorCase ("x87-row-order", 1);
}
#endif

#ifdef ASM486_ALIAS_MATRIX_COMPOSE_ASM
static void Bench486AliasMatrixComposeCase (char *name, int row_order)
{
	float in1[3][4], in2[3][4], c_output[3][4], asm_output[3][4];
	unsigned c_words[12], asm_words[12];
	unsigned checksum;
	int row, column, failure;

	for (row=0 ; row<3 ; row++)
	{
		for (column=0 ; column<4 ; column++)
		{
			in1[row][column] = (float)(row * 7 + column * 3 - 8) * 0.125;
			in2[row][column] = (float)(row * 5 - column * 2 + 3) * 0.25;
		}
	}

	if (row_order)
	{
		Q_memset (in1, 0, sizeof(in1));
		Q_memset (in2, 0, sizeof(in2));
		in1[0][0] = 1.0;
		in1[0][2] = 1.0;
		in1[0][3] = -18446744073709551616.0;
		in2[0][3] = 18446744073709551616.0;
		in2[2][3] = 1.0;
	}

	R_ConcatTransforms (in1, in2, c_output);
	R_ConcatTransforms_asm486 (in1, in2, asm_output);
	failure = Q_memcmp (c_output, asm_output, sizeof(c_output)) != 0;
	if (row_order && c_output[0][3] != 1.0)
		failure = true;
	if (failure)
	{
		bench486_memory_failures++;
		Q_memcpy (c_words, c_output, sizeof(c_words));
		Q_memcpy (asm_words, asm_output, sizeof(asm_words));
		Bench486Printf ("alias-matrix-compose %s parity FAIL c %08x asm %08x\n",
				name, c_words[3], asm_words[3]);
	}
	else
	{
		checksum = Bench486Checksum ((byte *)c_output, sizeof(c_output));
		Bench486Printf ("alias-matrix-compose %s exact result %u\n",
				name, checksum);
	}
}

static void Bench486AliasMatrixComposeCases (void)
{
	Bench486AliasMatrixComposeCase ("fractional", 0);
	Bench486AliasMatrixComposeCase ("translation-order", 1);
}

static void Bench486AliasViewMatrixCase (char *name, const float *right,
		const float *up, const float *forward)
{
	float c_output[3][4], asm_output[3][4];
	unsigned c_words[12], asm_words[12];
	unsigned checksum;
	int i, failure;

	Q_memset (c_output, 0x5a, sizeof(c_output));
	Q_memset (asm_output, 0x5a, sizeof(asm_output));
	for (i=0 ; i<3 ; i++)
	{
		c_output[0][i] = right[i];
		c_output[1][i] = -up[i];
		c_output[2][i] = forward[i];
	}

	R_AliasSetViewMatrix_asm486 (right, up, forward, &asm_output[0][0]);
	failure = Q_memcmp (c_output, asm_output, sizeof(c_output)) != 0;
	if (failure)
	{
		bench486_memory_failures++;
		Q_memcpy (c_words, c_output, sizeof(c_words));
		Q_memcpy (asm_words, asm_output, sizeof(asm_words));
		Bench486Printf ("alias-view-matrix %s parity FAIL c %08x asm %08x\n",
				name, c_words[4], asm_words[4]);
	}
	else
	{
		checksum = Bench486Checksum ((byte *)c_output, sizeof(c_output));
		Bench486Printf ("alias-view-matrix %s exact result %u\n",
				name, checksum);
	}
}

static void Bench486AliasViewMatrixCases (void)
{
	static const float vectors[3][3][3] = {
		{{1.25, -2.5, 0.0}, {3.75, -4.5, -0.0}, {-5.0, 6.0, 7.25}},
		{{0.0009765625, -32768.0, 42.5},
			{-0.000244140625, 16384.0, -64.75}, {9.5, -11.125, 0.125}},
		{{-0.0, 1.0, -1.0}, {0.0, -0.0, 0.0},
			{-17.0, 0.000001, -2.0}}
	};
	static char *volatile names[3] = {"fractional", "wide-range", "signed-zero"};
	int i;

	for (i=0 ; i<3 ; i++)
		Bench486AliasViewMatrixCase (names[i], vectors[i][0], vectors[i][1],
				vectors[i][2]);
}
#endif

#ifdef BENCH486
typedef struct
{
	char	*name;
	int		ambient;
	int		shade;
	float	light[3];
	float	forward[3];
	float	right[3];
	float	up[3];
} bench486_alias_setup_lighting_case_t;

typedef struct
{
	int		ambient;
	float	shade;
	float	light[3];
} bench486_alias_setup_lighting_result_t;

static void Bench486AliasSetupLightingCase (
		const bench486_alias_setup_lighting_case_t *test, int mode,
		unsigned short test_cw)
{
	alight_t lighting;
	bench486_alias_setup_lighting_result_t c_result, asm_result;
	unsigned short c_after_cw, asm_after_cw;
	unsigned checksum_word;
	int i;

	lighting.ambientlight = test->ambient;
	lighting.shadelight = test->shade;
	lighting.plightvec = (float *)test->light;
	Q_memset (&c_result, 0, sizeof(c_result));
	Q_memset (&asm_result, 0, sizeof(asm_result));

	__asm__ __volatile__ ("fldcw %0" : : "m" (test_cw));
	R_AliasSetupLighting_C (&lighting, test->forward, test->right, test->up);
	c_result.ambient = r_ambientlight;
	c_result.shade = r_shadelight;
	Q_memcpy (c_result.light, r_plightvec, sizeof(c_result.light));
	__asm__ __volatile__ ("fnstcw %0" : "=m" (c_after_cw));

	__asm__ __volatile__ ("fldcw %0" : : "m" (test_cw));
	R_AliasSetupLighting_asm486 (&lighting, test->forward, test->right,
			test->up);
	asm_result.ambient = r_ambientlight;
	asm_result.shade = r_shadelight;
	Q_memcpy (asm_result.light, r_plightvec, sizeof(asm_result.light));
	__asm__ __volatile__ ("fnstcw %0" : "=m" (asm_after_cw));

	if (Q_memcmp (&c_result, &asm_result, sizeof(c_result)) != 0 ||
			c_after_cw != test_cw || asm_after_cw != test_cw)
	{
		bench486_memory_failures++;
		Bench486Printf ("alias-setup-lighting %s rounding %d FAIL ambient %d/%d shade %.9g/%.9g light %.9g %.9g %.9g / %.9g %.9g %.9g cw %04x/%04x expected %04x\n",
				test->name, mode, c_result.ambient, asm_result.ambient,
				c_result.shade, asm_result.shade,
				c_result.light[0], c_result.light[1], c_result.light[2],
				asm_result.light[0], asm_result.light[1], asm_result.light[2],
				c_after_cw, asm_after_cw, test_cw);
		return;
	}

	for (i=0 ; i<(int)sizeof(c_result) ; i+=sizeof(checksum_word))
	{
		Q_memcpy (&checksum_word, (byte *)&c_result + i,
				sizeof(checksum_word));
		bench486_sink = (bench486_sink << 5) |
				(bench486_sink >> 27);
		bench486_sink ^= checksum_word;
	}
}

static void Bench486AliasSetupLightingCases (void)
{
	static bench486_alias_setup_lighting_case_t tests[] = {
		{"ambient-clamps", 4, -25,
			{-1.25f, 0.5f, 2.0f},
			{1.0f, 0.0f, 0.0f}, {0.0f, 1.0f, 0.0f}, {0.0f, 0.0f, 1.0f}},
		{"negative-shade", -128, -16777217,
			{0.25f, -0.5f, 1.25f},
			{0.5f, 0.25f, -0.75f}, {-0.125f, 0.875f, 0.375f},
			{0.25f, -0.25f, 1.0f}},
		{"fractional-axes", 128, 192,
			{0.125f, -0.625f, 2.5f},
			{0.75f, -0.25f, 0.125f}, {-0.5f, 0.125f, 0.75f},
			{0.0625f, 0.875f, -0.375f}},
		{"large-light-vector", 250, 16777217,
			{4096.0f, -2048.0f, 1024.0f},
			{0.25f, 0.5f, -0.75f}, {0.875f, -0.125f, 0.25f},
			{-0.5f, 0.375f, 0.625f}},
		{"cancellation-order", 5, 0,
			{1.0f, 1.0f, 1.0f},
			{16777216.0f, 1.0f, -16777216.0f},
			{-16777216.0f, 1.0f, 16777216.0f},
			{0.5f, -0.25f, 0.125f}},
		{"maximum-valid-ambient", 255, 32767,
			{-0.0f, 0.0f, -0.0f},
			{0.0f, -0.0f, 0.0f}, {-0.0f, 0.0f, 0.0f},
			{0.0f, 0.0f, -0.0f}}
	};
	int saved_ambient, mode, step;
	float saved_shade, saved_light[3];
	unsigned short original_cw, test_cw;
	int start_failures;

	saved_ambient = r_ambientlight;
	saved_shade = r_shadelight;
	Q_memcpy (saved_light, r_plightvec, sizeof(saved_light));
	__asm__ __volatile__ ("fnstcw %0" : "=m" (original_cw));
	start_failures = bench486_memory_failures;

	for (mode=0 ; mode<4 ; mode++)
	{
		test_cw = (original_cw & (unsigned short)~0x0c00) |
				(unsigned short)(mode << 10);
		for (step=0 ; step<(int)(sizeof(tests)/sizeof(tests[0])); step++)
			Bench486AliasSetupLightingCase (&tests[step], mode, test_cw);
	}

	__asm__ __volatile__ ("fldcw %0" : : "m" (original_cw));
	r_ambientlight = saved_ambient;
	r_shadelight = saved_shade;
	Q_memcpy (r_plightvec, saved_light, sizeof(saved_light));
	Bench486Printf ("alias setup lighting parity %s (%d cases, four x87 rounding modes)\n",
			bench486_memory_failures == start_failures ? "PASS" : "FAIL",
			4 * (int)(sizeof(tests)/sizeof(tests[0])));
}
#endif

#ifdef BENCH486
typedef struct
{
	char	*name;
	int		frame;
	double	cltime;
	float	syncbase;
	int		expected_offset;
} bench486_alias_setup_frame_case_t;

static void Bench486AliasSetupFrameCase (
		const bench486_alias_setup_frame_case_t *test, aliashdr_t *header,
		byte *header_bytes, int mode, unsigned short test_cw)
{
	trivertx_t *c_result, *asm_result;
	unsigned short c_after_cw, asm_after_cw;
	unsigned checksum_word;
	int expected_match;

	__asm__ __volatile__ ("fldcw %0" : : "m" (test_cw));
	R_AliasSetupFrame_C (test->frame, test->cltime, test->syncbase);
	c_result = r_apverts;
	__asm__ __volatile__ ("fnstcw %0" : "=m" (c_after_cw));

	__asm__ __volatile__ ("fldcw %0" : : "m" (test_cw));
	R_AliasSetupFrame_asm486 (test->frame, test->cltime, test->syncbase);
	asm_result = r_apverts;
	__asm__ __volatile__ ("fnstcw %0" : "=m" (asm_after_cw));

	expected_match = c_result == (trivertx_t *)(header_bytes +
			test->expected_offset) && asm_result == c_result;
	if (!expected_match || c_after_cw != test_cw || asm_after_cw != test_cw)
	{
		bench486_memory_failures++;
		Bench486Printf ("alias-setup-frame %s rounding %d FAIL expected %d c %d asm %d cw %04x/%04x expected %04x\n",
				test->name, mode, test->expected_offset,
				(int)((byte *)c_result - header_bytes),
				(int)((byte *)asm_result - header_bytes), c_after_cw,
				asm_after_cw, test_cw);
		return;
	}

	checksum_word = (unsigned)((byte *)c_result - header_bytes);
	bench486_sink = (bench486_sink << 5) |
			(bench486_sink >> 27);
	bench486_sink ^= checksum_word;
	(void)header;
}

static void Bench486AliasSetupFrameCases (void)
{
	/* DJGPP otherwise places this pointer table in executable .text, where
	 * relocated label addresses can decode as forbidden CPU instructions.
	 * Keep fixture data separate from code for the mechanical ISA audit. */
	static const bench486_alias_setup_frame_case_t tests[]
		__attribute__((section(".data"))) = {
		{"single-frame", 0, 0.375, 0.0f, 960},
		{"group-start", 1, 0.0, 0.0f, 1024},
		{"boundary-first", 1, 0.25, 0.0f, 1032},
		{"boundary-middle", 1, 0.5, 0.0f, 1040},
		{"last-interval", 1, 0.875, 0.0f, 1040},
		{"wrap-period", 1, 1.0, 0.0f, 1024},
		{"positive-multiple", 1, 2.75, 0.0f, 1040},
		{"negative-truncate-zero", 1, -0.125, 0.0f, 1024},
		{"negative-truncate-period", 1, -1.125, 0.0f, 1024},
		{"syncbase-boundary", 1, 0.125, 0.125f, 1032},
		{"negative-syncbase", 1, -0.75, 0.5f, 1024},
		{"large-time-boundary", 1, 1024.5, 0.0f, 1040},
		{"one-frame-group", 2, 0.625, -0.125f, 1048},
		{"second-single", 3, -17.25, 4.0f, 992}
	};
	union
	{
		unsigned long align;
		byte bytes[2048];
	} storage;
	aliashdr_t *saved_header;
	trivertx_t *saved_verts;
	aliashdr_t *header;
	maliasgroup_t *group;
	float *intervals;
	unsigned short original_cw, test_cw;
	int start_failures, mode, step;

	saved_header = paliashdr;
	saved_verts = r_apverts;
	__asm__ __volatile__ ("fnstcw %0" : "=m" (original_cw));
	start_failures = bench486_memory_failures;
	Q_memset (&storage, 0, sizeof(storage));
	header = (aliashdr_t *)storage.bytes;
	paliashdr = header;

	header->frames[0].type = ALIAS_SINGLE;
	header->frames[0].frame = 960;
	header->frames[1].type = ALIAS_GROUP;
	header->frames[1].frame = 256;
	header->frames[2].type = ALIAS_GROUP;
	header->frames[2].frame = 320;
	header->frames[3].type = ALIAS_SINGLE;
	header->frames[3].frame = 992;

	group = (maliasgroup_t *)(storage.bytes + 256);
	group->numframes = 3;
	group->intervals = 512;
	intervals = (float *)(storage.bytes + 512);
	intervals[0] = 0.25f;
	intervals[1] = 0.5f;
	intervals[2] = 1.0f;
	group->frames[0].frame = 1024;
	group->frames[1].frame = 1032;
	group->frames[2].frame = 1040;

	group = (maliasgroup_t *)(storage.bytes + 320);
	group->numframes = 1;
	group->intervals = 600;
	*(float *)(storage.bytes + 600) = 0.4f;
	group->frames[0].frame = 1048;

	for (mode=0 ; mode<4 ; mode++)
	{
		test_cw = (original_cw & (unsigned short)~0x0c00) |
				(unsigned short)(mode << 10);
		for (step=0 ; step<(int)(sizeof(tests)/sizeof(tests[0])); step++)
			Bench486AliasSetupFrameCase (&tests[step], header,
					storage.bytes, mode, test_cw);
	}

	__asm__ __volatile__ ("fldcw %0" : : "m" (original_cw));
	paliashdr = saved_header;
	r_apverts = saved_verts;
	Bench486Printf ("alias setup frame parity %s (%d cases, four x87 rounding modes)\n",
			bench486_memory_failures == start_failures ? "PASS" : "FAIL",
			4 * (int)(sizeof(tests)/sizeof(tests[0])));
}

typedef struct
{
	char	*name;
	int		skinnum;
	double	cltime;
	float	syncbase;
	int		expected_offset;
} bench486_alias_setup_skin_case_t;

static void Bench486AliasSetupSkinCase (
		const bench486_alias_setup_skin_case_t *test, byte *header_bytes,
		int mode, unsigned short test_cw)
{
	maliasskindesc_t *c_result, *asm_result;
	unsigned short c_after_cw, asm_after_cw;
	unsigned checksum_word;

	__asm__ __volatile__ ("fldcw %0" : : "m" (test_cw));
	c_result = R_AliasSetupSkinSelect_C (test->skinnum, test->cltime,
			test->syncbase);
	__asm__ __volatile__ ("fnstcw %0" : "=m" (c_after_cw));

	__asm__ __volatile__ ("fldcw %0" : : "m" (test_cw));
	asm_result = R_AliasSetupSkinSelect_asm486 (test->skinnum,
			test->cltime, test->syncbase);
	__asm__ __volatile__ ("fnstcw %0" : "=m" (asm_after_cw));

	if (c_result != (maliasskindesc_t *)(header_bytes +
			test->expected_offset) || asm_result != c_result ||
			c_after_cw != test_cw || asm_after_cw != test_cw)
	{
		bench486_memory_failures++;
		Bench486Printf ("alias-setup-skin %s rounding %d FAIL expected %d c %d asm %d cw %04x/%04x expected %04x\n",
				test->name, mode, test->expected_offset,
				(int)((byte *)c_result - header_bytes),
				(int)((byte *)asm_result - header_bytes), c_after_cw,
				asm_after_cw, test_cw);
		return;
	}

	checksum_word = (unsigned)((byte *)c_result - header_bytes);
	bench486_sink = (bench486_sink << 5) |
			(bench486_sink >> 27);
	bench486_sink ^= checksum_word;
}

static void Bench486AliasSetupSkinCases (void)
{
	/* Keep relocated fixture pointers out of executable .text (see frame cases). */
	static const bench486_alias_setup_skin_case_t tests[]
		__attribute__((section(".data"))) = {
		{"single-skin", 0, 0.375, 0.0f, 128},
		{"group-start", 1, 0.0, 0.0f, 264},
		{"boundary-first", 1, 0.25, 0.0f, 276},
		{"boundary-middle", 1, 0.5, 0.0f, 288},
		{"last-interval", 1, 0.875, 0.0f, 288},
		{"wrap-period", 1, 1.0, 0.0f, 264},
		{"positive-multiple", 1, 2.75, 0.0f, 288},
		{"negative-truncate-zero", 1, -0.125, 0.0f, 264},
		{"negative-truncate-period", 1, -1.125, 0.0f, 264},
		{"syncbase-boundary", 1, 0.125, 0.125f, 276},
		{"negative-syncbase", 1, -0.75, 0.5f, 264},
		{"large-time-boundary", 1, 1024.5, 0.0f, 288},
		{"one-skin-group", 2, 0.625, -0.125f, 328},
		{"second-single", 3, -17.25, 4.0f, 164}
	};
	union
	{
		unsigned long align;
		byte bytes[2048];
	} storage;
	aliashdr_t *saved_header, *header;
	maliasskindesc_t *descs;
	maliasskingroup_t *group;
	float *intervals;
	unsigned short original_cw, test_cw;
	int start_failures, mode, step;

	saved_header = paliashdr;
	__asm__ __volatile__ ("fnstcw %0" : "=m" (original_cw));
	start_failures = bench486_memory_failures;
	Q_memset (&storage, 0, sizeof(storage));
	header = (aliashdr_t *)storage.bytes;
	paliashdr = header;
	header->skindesc = 128;
	descs = (maliasskindesc_t *)(storage.bytes + header->skindesc);
	descs[0].type = ALIAS_SKIN_SINGLE;
	descs[0].skin = 900;
	descs[1].type = ALIAS_SKIN_GROUP;
	descs[1].skin = 256;
	descs[2].type = ALIAS_SKIN_GROUP;
	descs[2].skin = 320;
	descs[3].type = ALIAS_SKIN_SINGLE;
	descs[3].skin = 960;

	group = (maliasskingroup_t *)(storage.bytes + 256);
	group->numskins = 3;
	group->intervals = 512;
	intervals = (float *)(storage.bytes + group->intervals);
	intervals[0] = 0.25f;
	intervals[1] = 0.5f;
	intervals[2] = 1.0f;
	group->skindescs[0].skin = 1200;
	group->skindescs[1].skin = 1216;
	group->skindescs[2].skin = 1232;

	group = (maliasskingroup_t *)(storage.bytes + 320);
	group->numskins = 1;
	group->intervals = 600;
	*(float *)(storage.bytes + group->intervals) = 0.4f;
	group->skindescs[0].skin = 1248;

	for (mode=0 ; mode<4 ; mode++)
	{
		test_cw = (original_cw & (unsigned short)~0x0c00) |
				(unsigned short)(mode << 10);
		for (step=0 ; step<(int)(sizeof(tests)/sizeof(tests[0])); step++)
			Bench486AliasSetupSkinCase (&tests[step], storage.bytes,
					mode, test_cw);
	}

	__asm__ __volatile__ ("fldcw %0" : : "m" (original_cw));
	paliashdr = saved_header;
	Bench486Printf ("alias setup skin parity %s (%d cases, four x87 rounding modes)\n",
			bench486_memory_failures == start_failures ? "PASS" : "FAIL",
			4 * (int)(sizeof(tests)/sizeof(tests[0])));
}

typedef struct
{
	char	*name;
	int		p0[6];
	int		p1[6];
	int		p2[6];
	int		denominator;
	int		skinwidth;
} bench486_alias_gradient_case_t;

static void Bench486AliasGradientRead (int *values)
{
	values[0] = r_lstepx;
	values[1] = r_lstepy;
	values[2] = r_sstepx;
	values[3] = r_sstepy;
	values[4] = r_tstepx;
	values[5] = r_tstepy;
	values[6] = r_zistepx;
	values[7] = r_zistepy;
	values[8] = a_sstepxfrac;
	values[9] = a_tstepxfrac;
	values[10] = a_ststepxwhole;
}

static void Bench486AliasGradientCase (
		const bench486_alias_gradient_case_t *test,
		unsigned short original_cw, unsigned short asm_cw)
{
	int c_values[11], asm_values[11];
	unsigned short c_after_cw, asm_after_cw;
	union
	{
		int i;
		float f;
	} denominator;
	unsigned checksum;
	int i;

	for (i=0 ; i<6 ; i++)
	{
		r_p0[i] = test->p0[i];
		r_p1[i] = test->p1[i];
		r_p2[i] = test->p2[i];
	}
	d_xdenom = test->denominator;

	__asm__ __volatile__ ("fldcw %0" : : "m" (original_cw));
	D_PolysetCalcGradients_C (test->skinwidth);
	Bench486AliasGradientRead (c_values);
	__asm__ __volatile__ ("fnstcw %0" : "=m" (c_after_cw));

	denominator.f = 1.0f / (float)test->denominator;
	d_xdenom_int = test->denominator;
	d_xdenom = denominator.i;
	__asm__ __volatile__ ("fldcw %0" : : "m" (original_cw));
	D_PolysetCalcGradients_asm486 (test->skinwidth);
	Bench486AliasGradientRead (asm_values);
	__asm__ __volatile__ ("fnstcw %0" : "=m" (asm_after_cw));

	for (i=0 ; i<11 ; i++)
	{
		if (c_values[i] != asm_values[i])
		{
			bench486_memory_failures++;
			Bench486Printf ("alias-gradient %s output %d FAIL c %d asm %d cw %04x/%04x\n",
					test->name, i, c_values[i], asm_values[i],
					c_after_cw, asm_after_cw);
			return;
		}
	}

	if (c_after_cw != original_cw || asm_after_cw != asm_cw)
	{
		bench486_memory_failures++;
		Bench486Printf ("alias-gradient %s control word FAIL c %04x/%04x asm %04x/%04x\n",
				test->name, c_after_cw, original_cw, asm_after_cw, asm_cw);
		return;
	}

	checksum = (unsigned)c_values[0] ^ ((unsigned)c_values[2] << 3) ^
			((unsigned)c_values[4] << 7) ^ (unsigned)c_values[6];
	bench486_sink = (bench486_sink << 5) |
			(bench486_sink >> 27);
	bench486_sink ^= checksum;
}

static void Bench486AliasGradientCases (void)
{
	static const bench486_alias_gradient_case_t tests[] = {
		{"standard-positive", {0,0,0,0,0,65536},
			{320,0,65536,0,64,65536}, {0,200,0,65536,128,65536},
			64000, 64},
		{"reverse-denominator", {20,10,65535,65535,200,200000},
			{-220,15,-16384,98304,64,-65536},
			{40,-180,131072,-32768,0,65536}, -42000, 256},
		{"negative-texture-slopes", {-17,31,400000,-210000,75,80000},
			{231,-9,-75000,155000,-125,120000},
			{3,207,92000,-31000,225,-50000}, 51719, 320},
		{"fractional-light-ceil", {0,0,0,0,1,0},
			{193,0,0,0,14,0}, {0,211,0,0,9,0}, 40723, 128},
		{"opposite-light-gradients", {0,0,8000,-16000,250,60000},
			{511,0,80000,24000,11,90000},
			{0,257,-12000,96000,131,30000}, 131327, 512},
		{"zero-attribute-plane", {0,0,-4096,16384,64,32768},
			{128,0,-4096,16384,64,32768},
			{0,128,-4096,16384,64,32768}, 16384, 64},
		{"large-fixed-coordinates", {-4096,2048,-1048576,524288,32767,16777216},
			{8192,-1024,16777215,-8388608,-32768,-16777216},
			{-2048,-8192,1048576,4194304,0,8388608}, 33554431, 1024},
		{"small-denominator", {0,0,0,0,0,65536},
			{9,0,17,-5,7,65537}, {0,11,-3,23,4,65530}, 99, 16}
	};
	int saved_p0[6], saved_p1[6], saved_p2[6];
	int saved_outputs[11], saved_denominator, saved_integer_denominator;
	int start_failures, mode;
	unsigned short original_cw, asm_cw;

	Q_memcpy (saved_p0, r_p0, sizeof(saved_p0));
	Q_memcpy (saved_p1, r_p1, sizeof(saved_p1));
	Q_memcpy (saved_p2, r_p2, sizeof(saved_p2));
	Bench486AliasGradientRead (saved_outputs);
	saved_denominator = d_xdenom;
	saved_integer_denominator = d_xdenom_int;
	start_failures = bench486_memory_failures;
	__asm__ __volatile__ ("fnstcw %0" : "=m" (original_cw));
	asm_cw = (unsigned short)single_cw;
	for (mode=0 ; mode<(int)(sizeof(tests)/sizeof(tests[0])); mode++)
		Bench486AliasGradientCase (&tests[mode], original_cw, asm_cw);
	__asm__ __volatile__ ("fldcw %0" : : "m" (original_cw));
	d_xdenom = saved_denominator;
	d_xdenom_int = saved_integer_denominator;
	Q_memcpy (r_p0, saved_p0, sizeof(saved_p0));
	Q_memcpy (r_p1, saved_p1, sizeof(saved_p1));
	Q_memcpy (r_p2, saved_p2, sizeof(saved_p2));
	r_lstepx = saved_outputs[0];
	r_lstepy = saved_outputs[1];
	r_sstepx = saved_outputs[2];
	r_sstepy = saved_outputs[3];
	r_tstepx = saved_outputs[4];
	r_tstepy = saved_outputs[5];
	r_zistepx = saved_outputs[6];
	r_zistepy = saved_outputs[7];
	a_sstepxfrac = saved_outputs[8];
	a_tstepxfrac = saved_outputs[9];
	a_ststepxwhole = saved_outputs[10];
	Bench486Printf ("alias gradient setup parity %s (%d cases)\n",
			bench486_memory_failures == start_failures ? "PASS" : "FAIL",
			(int)(sizeof(tests)/sizeof(tests[0])));
}
#endif

static void Bench486SpriteBeamCase (char *name, float beamlength)
{
	float saved_vpn[3], saved_entorigin[3], saved_modelorg[3];
	float c_result[6], asm_result[6];
	unsigned checksum;
	int i, failure;

	Q_memcpy (saved_vpn, r_spritedesc.vpn, sizeof(saved_vpn));
	Q_memcpy (saved_entorigin, r_entorigin, sizeof(saved_entorigin));
	Q_memcpy (saved_modelorg, modelorg, sizeof(saved_modelorg));

	r_spritedesc.vpn[0] = 0.6;
	r_spritedesc.vpn[1] = -0.8;
	r_spritedesc.vpn[2] = 0.25;
	r_entorigin[0] = 128.25;
	r_entorigin[1] = -256.5;
	r_entorigin[2] = 0.125;
	modelorg[0] = -64.75;
	modelorg[1] = 512.125;
	modelorg[2] = -0.5;

	R_RotateSprite_C (beamlength);
	Q_memcpy (c_result, r_entorigin, sizeof(r_entorigin));
	Q_memcpy (c_result + 3, modelorg, sizeof(modelorg));

	r_entorigin[0] = 128.25;
	r_entorigin[1] = -256.5;
	r_entorigin[2] = 0.125;
	modelorg[0] = -64.75;
	modelorg[1] = 512.125;
	modelorg[2] = -0.5;
	R_RotateSprite_asm486 (beamlength);
	Q_memcpy (asm_result, r_entorigin, sizeof(r_entorigin));
	Q_memcpy (asm_result + 3, modelorg, sizeof(modelorg));

	failure = Q_memcmp (c_result, asm_result, sizeof(c_result)) != 0;
	if (failure)
	{
		unsigned c_words[6], asm_words[6];

		bench486_memory_failures++;
		Q_memcpy (c_words, c_result, sizeof(c_words));
		Q_memcpy (asm_words, asm_result, sizeof(asm_words));
		Bench486Printf ("sprite-beam %s parity FAIL c %08x %08x %08x %08x %08x %08x asm %08x %08x %08x %08x %08x %08x\n",
				name, c_words[0], c_words[1], c_words[2], c_words[3], c_words[4], c_words[5],
				asm_words[0], asm_words[1], asm_words[2], asm_words[3], asm_words[4], asm_words[5]);
	}
	else
	{
		checksum = Bench486Checksum ((byte *)c_result, sizeof(c_result));
		Bench486Printf ("sprite-beam %s exact result %u\n", name, checksum);
	}

	for (i=0 ; i<3 ; i++)
	{
		r_spritedesc.vpn[i] = saved_vpn[i];
		r_entorigin[i] = saved_entorigin[i];
		modelorg[i] = saved_modelorg[i];
	}
}

static void Bench486SpriteBeamCases (void)
{
	Bench486SpriteBeamCase ("zero", 0.0);
	Bench486SpriteBeamCase ("negative-zero", -0.0);
	Bench486SpriteBeamCase ("positive", 32.0);
	Bench486SpriteBeamCase ("negative", -0.375);
	Bench486SpriteBeamCase ("fractional", 0.125);
	Bench486SpriteBeamCase ("small", 1.0e-20);
}

static void Bench486SpriteClipCase (char *name, int input_index,
		int nump, vec5_t *points, vec3_t normal, float dist)
{
	vec5_t saved_verts[2][MAXWORKINGVERTS];
	vec5_t c_verts[2][MAXWORKINGVERTS];
	clipplane_t plane;
	int saved_current, c_count, c_current, asm_count, asm_current;
	int failure, i, mismatch_word;
	unsigned checksum, *c_words, *asm_words;

	Q_memcpy (saved_verts, clip_verts, sizeof(saved_verts));
	saved_current = clip_current;
	Q_memset (&plane, 0, sizeof(plane));
	plane.normal[0] = normal[0];
	plane.normal[1] = normal[1];
	plane.normal[2] = normal[2];
	plane.dist = dist;

	Q_memset (clip_verts, 0x5a, sizeof(clip_verts));
	clip_current = input_index;
	Q_memcpy (clip_verts[input_index], points, nump * sizeof(vec5_t));
	c_count = R_ClipSpriteFace_C (nump, &plane);
	c_current = clip_current;
	Q_memcpy (c_verts, clip_verts, sizeof(c_verts));

	Q_memset (clip_verts, 0x5a, sizeof(clip_verts));
	clip_current = input_index;
	Q_memcpy (clip_verts[input_index], points, nump * sizeof(vec5_t));
	asm_count = R_ClipSpriteFace_asm486 (nump, &plane);
	asm_current = clip_current;
	failure = c_count != asm_count || c_current != asm_current ||
		Q_memcmp (c_verts, clip_verts, sizeof(c_verts)) != 0;
	if (failure)
	{
		c_words = (unsigned *)c_verts;
		asm_words = (unsigned *)clip_verts;
		mismatch_word = -1;
		for (i=0 ; i<(sizeof(c_verts) / sizeof(unsigned)) ; i++)
		{
			if (c_words[i] != asm_words[i])
			{
				mismatch_word = i;
				break;
			}
		}
		bench486_memory_failures++;
		if (mismatch_word >= 0)
			Bench486Printf ("sprite-clip %s parity FAIL count %d/%d buffer %d/%d word %d c %08x asm %08x\n",
					name, c_count, asm_count, c_current, asm_current,
					mismatch_word, c_words[mismatch_word], asm_words[mismatch_word]);
		else
			Bench486Printf ("sprite-clip %s parity FAIL count %d/%d buffer %d/%d\n",
					name, c_count, asm_count, c_current, asm_current);
	}
	else
	{
		checksum = Bench486Checksum ((byte *)c_verts, sizeof(c_verts));
		Bench486Printf ("sprite-clip %s exact count %d checksum %u\n",
				name, c_count, checksum);
	}

	Q_memcpy (clip_verts, saved_verts, sizeof(saved_verts));
	clip_current = saved_current;
}

static void Bench486SpriteClipCases (void)
{
	vec3_t xnormal = { 1.0, 0.0, 0.0 };
	vec3_t oblique = { 0.3, -0.7, 0.125 };
	vec5_t all_front[4] = {
		{ 1.0, -1.0, 0.0, 0.0, 0.0 },
		{ 2.0, -1.0, 0.5, 16.0, 0.0 },
		{ 2.0,  1.0, 0.5, 16.0, 16.0 },
		{ 1.0,  1.0, 0.0, 0.0, 16.0 }
	};
	vec5_t crossing[4] = {
		{ -1.0, -1.0, 0.0, 0.0, 0.0 },
		{  1.0, -1.0, 0.0, 16.0, 0.0 },
		{  1.0,  1.0, 0.0, 16.0, 16.0 },
		{ -1.0,  1.0, 0.0, 0.0, 16.0 }
	};
	vec5_t touching[4] = {
		{ -1.0, -1.0, 0.0, 0.0, 0.0 },
		{ -0.0, -1.0, 0.0, 8.0, 0.0 },
		{  1.0,  1.0, 0.0, 16.0, 16.0 },
		{ -1.0,  1.0, 0.0, 0.0, 16.0 }
	};
	vec5_t skewed[5] = {
		{ -2.0, -1.0,  0.5,  0.0,  0.0 },
		{  1.0, -2.0,  1.5, 12.0,  0.0 },
		{  3.0,  0.5, -0.5, 20.0,  8.0 },
		{  0.5,  2.0,  1.0, 12.0, 16.0 },
		{ -2.0,  1.0, -1.0,  0.0, 16.0 }
	};
	vec5_t near_plane[4] = {
		{ -1.0e-20, -1.0, 0.0, 0.0, 0.0 },
		{  1.0e-20, -1.0, 0.0, 1.0, 0.0 },
		{  1.0e-20,  1.0, 0.0, 1.0, 1.0 },
		{ -1.0e-20,  1.0, 0.0, 0.0, 1.0 }
	};

	Bench486SpriteClipCase ("all-front-alt-buffer", 1, 4, all_front,
			xnormal, -0.25);
	Bench486SpriteClipCase ("all-back", 0, 4, all_front, xnormal, 4.0);
	Bench486SpriteClipCase ("fractional-crossings", 0, 4, crossing,
			xnormal, 0.0);
	Bench486SpriteClipCase ("exact-plane-touch", 1, 4, touching,
			xnormal, 0.0);
	Bench486SpriteClipCase ("oblique-five-vertex", 0, 5, skewed,
			oblique, 0.0375);
	Bench486SpriteClipCase ("near-plane-crossings", 0, 4, near_plane,
			xnormal, 0.0);
}

extern unsigned Bench486Call_asm486 (void (*function)(void), unsigned words,
		const unsigned *arguments, float *float_result);

static void Bench486SpriteFrameCase (char *name, msprite_t *sprite,
		int frame, double cltime, float syncbase)
{
	entity_t test_entity;
	entity_t *saved_currententity;
	double saved_time;
	int asm_frame;
	mspriteframe_t *c_frame, *asm_frameptr, *public_frame;
	unsigned checksum, arguments[1], abi;

	saved_currententity = currententity;
	saved_time = cl.time;
	Q_memset (&test_entity, 0, sizeof(test_entity));
	test_entity.frame = frame;
	test_entity.syncbase = syncbase;
	currententity = &test_entity;
	cl.time = cltime;

	c_frame = R_GetSpriteframe_C (sprite);
	asm_frame = frame;
	if ((asm_frame >= sprite->numframes) || (asm_frame < 0))
		asm_frame = 0;
	asm_frameptr = R_GetSpriteframe_asm486 (sprite, asm_frame,
			cltime, syncbase);
	public_frame = R_GetSpriteframePublic_asm486 (sprite);
	arguments[0] = (unsigned)sprite;
	abi = Bench486Call_asm486 ((void (*)(void))R_GetSpriteframePublic_asm486,
			1, arguments, NULL);
	if (c_frame != asm_frameptr || c_frame != public_frame || abi)
	{
		bench486_memory_failures++;
		Bench486Printf ("sprite-frame %s parity FAIL c %08x core %08x public %08x ABI %x\n",
				name, (unsigned)c_frame, (unsigned)asm_frameptr,
				(unsigned)public_frame, abi);
	}
	else
	{
		checksum = Bench486Checksum ((byte *)c_frame, sizeof(*c_frame));
		Bench486Printf ("sprite-frame %s exact result %u\n", name, checksum);
	}

	currententity = saved_currententity;
	cl.time = saved_time;
}

static void Bench486SpriteFrameCases (void)
{
	msprite_t sprite;
	struct
	{
		mspritegroup_t group;
		mspriteframe_t *frame_tail[3];
	} group_storage;
	mspritegroup_t *group;
	mspriteframe_t frames[4];
	float intervals[4];
	int i;

	Q_memset (&sprite, 0, sizeof(sprite));
	Q_memset (&group_storage, 0, sizeof(group_storage));
	Q_memset (frames, 0, sizeof(frames));
	group = &group_storage.group;
	sprite.numframes = 1;
	group->numframes = 4;
	group->intervals = intervals;
	intervals[0] = 0.25;
	intervals[1] = 0.5;
	intervals[2] = 0.75;
	intervals[3] = 1.0;
	for (i=0 ; i<4 ; i++)
	{
		frames[i].width = 64 + i;
		frames[i].height = 48 + i;
		frames[i].up = 20.25 + i;
		frames[i].down = -12.5 - i;
		frames[i].left = -16.75 - i;
		frames[i].right = 15.5 + i;
		frames[i].pixels[0] = i + 1;
		frames[i].pixels[1] = i + 2;
		frames[i].pixels[2] = i + 3;
		frames[i].pixels[3] = i + 4;
	}
	group->frames[0] = &frames[0];
	group_storage.frame_tail[0] = &frames[1];
	group_storage.frame_tail[1] = &frames[2];
	group_storage.frame_tail[2] = &frames[3];

	sprite.frames[0].type = SPR_SINGLE;
	sprite.frames[0].frameptr = &frames[2];
	Bench486SpriteFrameCase ("single-frame", &sprite, 0, 0.0, 0.0);

	sprite.frames[0].type = SPR_GROUP;
	sprite.frames[0].frameptr = (mspriteframe_t *)group;
	Bench486SpriteFrameCase ("group-start", &sprite, 0, 0.1, 0.0);
	Bench486SpriteFrameCase ("boundary-first", &sprite, 0, 0.25, 0.0);
	Bench486SpriteFrameCase ("boundary-middle", &sprite, 0, 0.5, 0.0);
	Bench486SpriteFrameCase ("last-interval", &sprite, 0, 0.999, 0.0);
	Bench486SpriteFrameCase ("wrap-exact-period", &sprite, 0, 1.0, 0.0);
	Bench486SpriteFrameCase ("positive-multiple", &sprite, 0, 2.75, 0.0);
	Bench486SpriteFrameCase ("negative-truncate-zero", &sprite, 0, -0.125, 0.0);
	Bench486SpriteFrameCase ("negative-truncate-period", &sprite, 0, -1.125, 0.0);
	Bench486SpriteFrameCase ("syncbase-boundary", &sprite, 0, 0.125, 0.125);
	Bench486SpriteFrameCase ("negative-frame-fallback", &sprite, -1, 0.5, 0.0);
	Bench486SpriteFrameCase ("high-frame-fallback", &sprite, 4, 0.5, 0.0);
}

typedef struct
{
	float steps[6];
	float origins[3];
	fixed16_t adjust[2];
	fixed16_t extents[2];
} bench486_sprite_gradient_result_t;

static void Bench486SpriteGradientReadResult (
		bench486_sprite_gradient_result_t *result)
{
	result->steps[0] = d_sdivzstepu;
	result->steps[1] = d_tdivzstepu;
	result->steps[2] = d_sdivzstepv;
	result->steps[3] = d_tdivzstepv;
	result->steps[4] = d_zistepu;
	result->steps[5] = d_zistepv;
	result->origins[0] = d_sdivzorigin;
	result->origins[1] = d_tdivzorigin;
	result->origins[2] = d_ziorigin;
	result->adjust[0] = sadjust;
	result->adjust[1] = tadjust;
	result->extents[0] = bbextents;
	result->extents[1] = bbextentt;
}

static void Bench486SpriteGradientWriteResult (
		const bench486_sprite_gradient_result_t *result)
{
	d_sdivzstepu = result->steps[0];
	d_tdivzstepu = result->steps[1];
	d_sdivzstepv = result->steps[2];
	d_tdivzstepv = result->steps[3];
	d_zistepu = result->steps[4];
	d_zistepv = result->steps[5];
	d_sdivzorigin = result->origins[0];
	d_tdivzorigin = result->origins[1];
	d_ziorigin = result->origins[2];
	sadjust = result->adjust[0];
	tadjust = result->adjust[1];
	bbextents = result->extents[0];
	bbextentt = result->extents[1];
}

static void Bench486SpriteGradientCase (char *name, int variant)
{
	static const float view_right[3][3] = {
		{ 0.87, 0.31, -0.12 }, { -0.80, 0.25, 0.16 }, { 0.42, -0.51, 0.33 }
	};
	static const float view_up[3][3] = {
		{ -0.20, 0.91, 0.24 }, { 0.12, 0.91, -0.37 }, { -0.22, 0.79, 0.28 }
	};
	static const float view_normal[3][3] = {
		{ 0.43, -0.17, 0.89 }, { -0.57, -0.31, -0.74 }, { -0.67, 0.44, 0.52 }
	};
	static const float sprite_up[3][3] = {
		{ 0.10, 0.80, 0.20 }, { -0.25, 0.60, 0.75 }, { 0.52, 0.41, -0.33 }
	};
	static const float sprite_right[3][3] = {
		{ 0.70, -0.30, 0.05 }, { 0.66, 0.11, -0.42 }, { -0.18, 0.73, 0.49 }
	};
	static const float sprite_normal[3][3] = {
		{ -0.20, 0.15, 0.90 }, { -0.75, -0.25, -0.50 }, { 0.32, -0.48, 0.74 }
	};
	static const float origins[3][3] = {
		{ 42.75, -18.5, 97.25 }, { 12.0, 24.0, 36.0 }, { 140.25, -83.75, 225.5 }
	};
	static const float scale_inverse[3][2] = {
		{ 0.75, 1.25 }, { 1.8, 0.625 }, { 0.42, 0.91 }
	};
	static const float centers[3][2] = {
		{ 159.5, 99.5 }, { 12.25, 173.75 }, { 201.25, 111.5 }
	};
	static const int widths[3] = { 80, 129, 256 };
	static const int heights[3] = { 61, 79, 192 };
	float saved_sprite_axes[9], saved_view_right[3], saved_view_up[3];
	float saved_view_normal[3], saved_modelorg[3];
	float saved_scale_inverse[2], saved_centers[2];
	int saved_cachewidth, saved_height;
	bench486_sprite_gradient_result_t saved_result, c_result, asm_result;
	unsigned checksum;
	int failure;

	Q_memcpy (saved_sprite_axes, &r_spritedesc.vup, sizeof(saved_sprite_axes));
	Q_memcpy (saved_view_right, vright, sizeof(saved_view_right));
	Q_memcpy (saved_view_up, vup, sizeof(saved_view_up));
	Q_memcpy (saved_view_normal, vpn, sizeof(saved_view_normal));
	Q_memcpy (saved_modelorg, modelorg, sizeof(saved_modelorg));
	saved_scale_inverse[0] = xscaleinv;
	saved_scale_inverse[1] = yscaleinv;
	saved_centers[0] = xcenter;
	saved_centers[1] = ycenter;
	saved_cachewidth = cachewidth;
	Bench486SpriteGradientReadResult (&saved_result);

	Q_memcpy (vright, (void *)view_right[variant], sizeof(saved_view_right));
	Q_memcpy (vup, (void *)view_up[variant], sizeof(saved_view_up));
	Q_memcpy (vpn, (void *)view_normal[variant], sizeof(saved_view_normal));
	Q_memcpy (&r_spritedesc.vup, (void *)sprite_up[variant], sizeof(float) * 3);
	Q_memcpy (&r_spritedesc.vright, (void *)sprite_right[variant], sizeof(float) * 3);
	Q_memcpy (&r_spritedesc.vpn, (void *)sprite_normal[variant], sizeof(float) * 3);
	Q_memcpy (modelorg, (void *)origins[variant], sizeof(saved_modelorg));
	xscaleinv = scale_inverse[variant][0];
	yscaleinv = scale_inverse[variant][1];
	xcenter = centers[variant][0];
	ycenter = centers[variant][1];
	cachewidth = widths[variant];
	saved_height = D_SpriteCalculateGradientsSetHeight (heights[variant]);

	D_SpriteCalculateGradients_C ();
	Bench486SpriteGradientReadResult (&c_result);
	D_SpriteCalculateGradients_asm486 (heights[variant]);
	Bench486SpriteGradientReadResult (&asm_result);
	failure = Q_memcmp (&c_result, &asm_result, sizeof(c_result)) != 0;
	if (failure)
	{
		unsigned *c_words, *asm_words;
		int i, mismatch_word;

		c_words = (unsigned *)&c_result;
		asm_words = (unsigned *)&asm_result;
		mismatch_word = -1;
		for (i=0 ; i<(sizeof(c_result) / sizeof(unsigned)) ; i++)
		{
			if (c_words[i] != asm_words[i])
			{
				mismatch_word = i;
				break;
			}
		}
		bench486_memory_failures++;
		Bench486Printf ("sprite-gradients %s parity FAIL word %d c %08x asm %08x\n",
				name, mismatch_word,
				mismatch_word >= 0 ? c_words[mismatch_word] : 0,
				mismatch_word >= 0 ? asm_words[mismatch_word] : 0);
	}
	else
	{
		checksum = Bench486Checksum ((byte *)&c_result, sizeof(c_result));
		Bench486Printf ("sprite-gradients %s exact result %u\n", name, checksum);
	}

	Bench486SpriteGradientWriteResult (&saved_result);
	Q_memcpy (&r_spritedesc.vup, saved_sprite_axes, sizeof(saved_sprite_axes));
	Q_memcpy (vright, saved_view_right, sizeof(saved_view_right));
	Q_memcpy (vup, saved_view_up, sizeof(saved_view_up));
	Q_memcpy (vpn, saved_view_normal, sizeof(saved_view_normal));
	Q_memcpy (modelorg, saved_modelorg, sizeof(saved_modelorg));
	xscaleinv = saved_scale_inverse[0];
	yscaleinv = saved_scale_inverse[1];
	xcenter = saved_centers[0];
	ycenter = saved_centers[1];
	cachewidth = saved_cachewidth;
	D_SpriteCalculateGradientsSetHeight (saved_height);
}

static void Bench486SpriteGradientCases (void)
{
	Bench486SpriteGradientCase ("oblique-camera", 0);
	Bench486SpriteGradientCase ("positive-plane-distance", 1);
	Bench486SpriteGradientCase ("large-viewport", 2);
}

static void Bench486SpriteScanLeftCase (char *name, int nump, int minindex,
		int maxindex, emitpoint_t *input_vertices)
{
	emitpoint_t vertices[MAXWORKINGVERTS+1];
	sspan_t c_spans[MAXHEIGHT+1], asm_spans[MAXHEIGHT+1];
	sspan_t *saved_spans;
	emitpoint_t *saved_pverts;
	int saved_nump, saved_min, saved_max;
	int i, failure;
	unsigned checksum;

	Q_memcpy (vertices, input_vertices, nump * sizeof(emitpoint_t));
	vertices[nump] = vertices[0];
	Q_memset (c_spans, 0x5a, sizeof(c_spans));
	Q_memset (asm_spans, 0x5a, sizeof(asm_spans));
	saved_nump = r_spritedesc.nump;
	saved_pverts = r_spritedesc.pverts;
	D_SpriteScanLeftEdgeGetState (&saved_spans, &saved_min, &saved_max);
	r_spritedesc.nump = nump;
	r_spritedesc.pverts = vertices;
	D_SpriteScanLeftEdgeSetState (c_spans, minindex, maxindex);
	D_SpriteScanLeftEdge_C ();
	D_SpriteScanLeftEdge_asm486 (asm_spans, minindex, maxindex,
			nump, vertices);
	failure = Q_memcmp (c_spans, asm_spans, sizeof(c_spans)) != 0;
	if (failure)
	{
		unsigned *c_words, *asm_words;
		int mismatch_word;

		c_words = (unsigned *)c_spans;
		asm_words = (unsigned *)asm_spans;
		mismatch_word = -1;
		for (i=0 ; i<(sizeof(c_spans) / sizeof(unsigned)) ; i++)
		{
			if (c_words[i] != asm_words[i])
			{
				mismatch_word = i;
				break;
			}
		}
		bench486_memory_failures++;
		Bench486Printf ("sprite-scan-left %s parity FAIL word %d c %08x asm %08x\n",
				name, mismatch_word,
				mismatch_word >= 0 ? c_words[mismatch_word] : 0,
				mismatch_word >= 0 ? asm_words[mismatch_word] : 0);
	}
	else
	{
		checksum = Bench486Checksum ((byte *)c_spans, sizeof(c_spans));
		Bench486Printf ("sprite-scan-left %s exact result %u\n", name, checksum);
	}
	r_spritedesc.nump = saved_nump;
	r_spritedesc.pverts = saved_pverts;
	D_SpriteScanLeftEdgeSetState (saved_spans, saved_min, saved_max);
}

static void Bench486SpriteScanLeftCases (void)
{
	emitpoint_t quad[4] = {
		{ 3.25, 2.25, 0.0, 0.0, 0.0 },
		{ 16.75, 2.25, 0.0, 0.0, 0.0 },
		{ 13.125, 9.125, 0.0, 0.0, 0.0 },
		{ 1.5, 8.875, 0.0, 0.0, 0.0 }
	};
	emitpoint_t pentagon[5] = {
		{ 1.5, 6.25, 0.0, 0.0, 0.0 },
		{ 8.25, 1.125, 0.0, 0.0, 0.0 },
		{ 17.875, 3.75, 0.0, 0.0, 0.0 },
		{ 15.25, 8.125, 0.0, 0.0, 0.0 },
		{ 2.375, 9.75, 0.0, 0.0, 0.0 }
	};
	emitpoint_t negative_u[4] = {
		{ -8.875, 0.5, 0.0, 0.0, 0.0 },
		{ 4.25, 0.5, 0.0, 0.0, 0.0 },
		{ 2.125, 5.75, 0.0, 0.0, 0.0 },
		{ -11.5, 5.25, 0.0, 0.0, 0.0 }
	};

	Bench486SpriteScanLeftCase ("fractional-quad-wrap", 4, 0, 2, quad);
	Bench486SpriteScanLeftCase ("five-vertex-nonzero-start", 5, 1, 4,
			pentagon);
	Bench486SpriteScanLeftCase ("negative-u", 4, 0, 2, negative_u);
}

static void Bench486SpriteScanRightCase (char *name, int nump, int minindex,
		int maxindex, emitpoint_t *input_vertices, float xleft, float xright,
		float ytop, float ybottom)
{
	emitpoint_t vertices[MAXWORKINGVERTS+1];
	sspan_t c_spans[MAXHEIGHT+1], asm_spans[MAXHEIGHT+1];
	sspan_t *saved_spans;
	emitpoint_t *saved_pverts;
	int saved_nump, saved_min, saved_max;
	float saved_xleft, saved_xright, saved_ytop, saved_ybottom;
	int i, failure;
	unsigned checksum;

	Q_memcpy (vertices, input_vertices, nump * sizeof(emitpoint_t));
	vertices[nump] = vertices[0];
	Q_memset (c_spans, 0x5a, sizeof(c_spans));
	Q_memset (asm_spans, 0x5a, sizeof(asm_spans));
	saved_nump = r_spritedesc.nump;
	saved_pverts = r_spritedesc.pverts;
	D_SpriteScanRightEdgeGetState (&saved_spans, &saved_min, &saved_max,
			&saved_xleft, &saved_xright, &saved_ytop, &saved_ybottom);
	r_spritedesc.nump = nump;
	r_spritedesc.pverts = vertices;
	D_SpriteScanRightEdgeSetState (c_spans, minindex, maxindex,
			xleft, xright, ytop, ybottom);
	D_SpriteScanRightEdge_C ();
	D_SpriteScanRightEdge_asm486 (asm_spans, minindex, maxindex,
			nump, vertices, xleft, xright, ytop, ybottom);
	failure = Q_memcmp (c_spans, asm_spans, sizeof(c_spans)) != 0;
	if (failure)
	{
		unsigned *c_words, *asm_words;
		int mismatch_word;

		c_words = (unsigned *)c_spans;
		asm_words = (unsigned *)asm_spans;
		mismatch_word = -1;
		for (i=0 ; i<(sizeof(c_spans) / sizeof(unsigned)) ; i++)
		{
			if (c_words[i] != asm_words[i])
			{
				mismatch_word = i;
				break;
			}
		}
		bench486_memory_failures++;
		Bench486Printf ("sprite-scan-right %s parity FAIL word %d c %08x asm %08x\n",
				name, mismatch_word,
				mismatch_word >= 0 ? c_words[mismatch_word] : 0,
				mismatch_word >= 0 ? asm_words[mismatch_word] : 0);
	}
	else
	{
		checksum = Bench486Checksum ((byte *)c_spans, sizeof(c_spans));
		Bench486Printf ("sprite-scan-right %s exact result %u\n", name, checksum);
	}
	r_spritedesc.nump = saved_nump;
	r_spritedesc.pverts = saved_pverts;
	D_SpriteScanRightEdgeSetState (saved_spans, saved_min, saved_max,
			saved_xleft, saved_xright, saved_ytop, saved_ybottom);
}

static void Bench486SpriteScanRightCases (void)
{
	emitpoint_t quad[4] = {
		{ 3.25, 2.25, 0.0, 0.0, 0.0 },
		{ 16.75, 2.25, 0.0, 0.0, 0.0 },
		{ 13.125, 9.125, 0.0, 0.0, 0.0 },
		{ 1.5, 8.875, 0.0, 0.0, 0.0 }
	};
	emitpoint_t clipped_quad[4] = {
		{ -100.5, -50.25, 0.0, 0.0, 0.0 },
		{ 300.75, 10.25, 0.0, 0.0, 0.0 },
		{ 400.5, 250.75, 0.0, 0.0, 0.0 },
		{ 80.25, 280.5, 0.0, 0.0, 0.0 }
	};
	emitpoint_t negative_slope[4] = {
		{ 14.75, 1.5, 0.0, 0.0, 0.0 },
		{ 2.125, 5.25, 0.0, 0.0, 0.0 },
		{ 4.5, 11.75, 0.0, 0.0, 0.0 },
		{ 17.25, 8.125, 0.0, 0.0, 0.0 }
	};

	Bench486SpriteScanRightCase ("fractional-quad", 4, 0, 0, quad,
			-0.5, 319.5, -0.5, 199.5);
	Bench486SpriteScanRightCase ("viewport-clamp-wrap", 4, 0, 0,
			clipped_quad, 0.5, 319.5, 0.5, 199.5);
	Bench486SpriteScanRightCase ("negative-slope-narrow-view", 4, 1, 3,
			negative_slope, 3.5, 16.5, 2.5, 10.5);
}

static void Bench486SpriteDrawCase (char *name, int nump,
		emitpoint_t *input_vertices)
{
	typedef union
	{
		mspriteframe_t frame;
		byte storage[512];
	} bench486_sprite_frame_t;
	emitpoint_t vertices[MAXWORKINGVERTS+1];
	bench486_sprite_frame_t frame_storage;
	mspriteframe_t *frame;
	byte *pixels;
	spritedesc_t saved_desc;
	sspan_t *saved_spans;
	int saved_min, saved_max, saved_cachewidth, saved_sprite_height;
	float saved_xleft, saved_xright, saved_ytop, saved_ybottom;
	float saved_view_right[3], saved_view_up[3], saved_view_normal[3];
	float saved_modelorg[3], saved_xscaleinv, saved_yscaleinv;
	float saved_xcenter, saved_ycenter;
	bench486_sprite_gradient_result_t saved_gradient;
	pixel_t *saved_viewbuffer;
	short *saved_zbuffer;
	unsigned int saved_zwidth;
	int saved_screenwidth;
	byte *saved_cacheblock;
	pixel_t *saved_view_rows[200];
	short *saved_z_rows[200];
	int i, failure, first_pixel, first_depth;
	unsigned checksum;

	Q_memcpy (vertices, input_vertices, nump * sizeof(emitpoint_t));
	Q_memset (&frame_storage, 0, sizeof(frame_storage));
	frame = &frame_storage.frame;
	frame->width = 16;
	frame->height = 16;
	frame->up = 8.0;
	frame->down = -8.0;
	frame->left = -8.0;
	frame->right = 8.0;
	pixels = (byte *)&frame->pixels[0];
	for (i=0 ; i<16*16 ; i++)
		pixels[i] = (i % 13) ? (byte)((i * 17 + 3) & 255) : 255;

	Q_memcpy (&saved_desc, &r_spritedesc, sizeof(saved_desc));
	D_SpriteScanRightEdgeGetState (&saved_spans, &saved_min, &saved_max,
			&saved_xleft, &saved_xright, &saved_ytop, &saved_ybottom);
	saved_cachewidth = cachewidth;
	saved_cacheblock = (byte *)cacheblock;
	saved_sprite_height = sprite_height;
	Bench486SpriteGradientReadResult (&saved_gradient);
	Q_memcpy (saved_view_right, vright, sizeof(saved_view_right));
	Q_memcpy (saved_view_up, vup, sizeof(saved_view_up));
	Q_memcpy (saved_view_normal, vpn, sizeof(saved_view_normal));
	Q_memcpy (saved_modelorg, modelorg, sizeof(saved_modelorg));
	saved_xscaleinv = xscaleinv;
	saved_yscaleinv = yscaleinv;
	saved_xcenter = xcenter;
	saved_ycenter = ycenter;
	saved_viewbuffer = d_viewbuffer;
	saved_zbuffer = d_pzbuffer;
	saved_zwidth = d_zwidth;
	saved_screenwidth = screenwidth;

	r_spritedesc.nump = nump;
	r_spritedesc.pverts = vertices;
	r_spritedesc.pspriteframe = frame;
	r_spritedesc.vup[0] = 0.0; r_spritedesc.vup[1] = 0.0; r_spritedesc.vup[2] = 1.0;
	r_spritedesc.vright[0] = 1.0; r_spritedesc.vright[1] = 0.0; r_spritedesc.vright[2] = 0.0;
	r_spritedesc.vpn[0] = 0.0; r_spritedesc.vpn[1] = 1.0; r_spritedesc.vpn[2] = 0.0;
	vright[0] = 1.0; vright[1] = 0.0; vright[2] = 0.0;
	vup[0] = 0.0; vup[1] = 0.0; vup[2] = 1.0;
	vpn[0] = 0.0; vpn[1] = 1.0; vpn[2] = 0.0;
	modelorg[0] = 0.0; modelorg[1] = -128.0; modelorg[2] = 0.0;
	xscaleinv = 1.0 / 160.0;
	yscaleinv = 1.0 / 160.0;
	xcenter = 160.0;
	ycenter = 100.0;
	d_viewbuffer = (pixel_t *)bench486_sprite_draw_c_pixels;
	d_pzbuffer = bench486_sprite_draw_c_depth;
	d_zwidth = 320;
	screenwidth = 320;
	D_SpriteScanRightEdgeSetState (saved_spans, saved_min, saved_max,
			-0.5, 319.5, -0.5, 199.5);
	for (i=0 ; i<200 ; i++)
	{
		saved_view_rows[i] = viewspantable[i];
		saved_z_rows[i] = zspantable[i];
		viewspantable[i] = (pixel_t *)(bench486_sprite_draw_c_pixels + i * 320);
		zspantable[i] = bench486_sprite_draw_c_depth + i * 320;
	}
	Q_memset (bench486_sprite_draw_c_pixels, 0xa5,
		sizeof(bench486_sprite_draw_c_pixels));
	Q_memset (bench486_sprite_draw_c_depth, 0,
		sizeof(bench486_sprite_draw_c_depth));
	Bench486Printf ("sprite-draw %s entering C path\n", name);
	D_DrawSprite_C ();

	d_viewbuffer = (pixel_t *)bench486_sprite_draw_asm_pixels;
	d_pzbuffer = bench486_sprite_draw_asm_depth;
	for (i=0 ; i<200 ; i++)
	{
		viewspantable[i] = (pixel_t *)(bench486_sprite_draw_asm_pixels + i * 320);
		zspantable[i] = bench486_sprite_draw_asm_depth + i * 320;
	}
	Q_memset (bench486_sprite_draw_asm_pixels, 0xa5,
		sizeof(bench486_sprite_draw_asm_pixels));
	Q_memset (bench486_sprite_draw_asm_depth, 0,
		sizeof(bench486_sprite_draw_asm_depth));
	Bench486Printf ("sprite-draw %s entering ASM path\n", name);
	D_DrawSprite_asm486 (nump, vertices, 16, 16, pixels);

	first_pixel = -1;
	first_depth = -1;
	for (i=0 ; i<320*200 ; i++)
	{
		if (first_pixel < 0 &&
				bench486_sprite_draw_c_pixels[i] != bench486_sprite_draw_asm_pixels[i])
			first_pixel = i;
		if (first_depth < 0 &&
				bench486_sprite_draw_c_depth[i] != bench486_sprite_draw_asm_depth[i])
			first_depth = i;
	}
	failure = first_pixel >= 0 || first_depth >= 0;
	if (failure)
	{
		bench486_memory_failures++;
		Bench486Printf ("sprite-draw %s parity FAIL first pixel %d c %02x asm %02x depth %d c %04x asm %04x\n",
				name, first_pixel,
				first_pixel >= 0 ? bench486_sprite_draw_c_pixels[first_pixel] : 0,
				first_pixel >= 0 ? bench486_sprite_draw_asm_pixels[first_pixel] : 0,
				first_depth,
				first_depth >= 0 ? (unsigned short)bench486_sprite_draw_c_depth[first_depth] : 0,
				first_depth >= 0 ? (unsigned short)bench486_sprite_draw_asm_depth[first_depth] : 0);
	}
	else
	{
		checksum = Bench486Checksum (bench486_sprite_draw_c_pixels,
				sizeof(bench486_sprite_draw_c_pixels));
		checksum ^= Bench486Checksum ((byte *)bench486_sprite_draw_c_depth,
				sizeof(bench486_sprite_draw_c_depth));
		Bench486Printf ("sprite-draw %s exact framebuffer result %u\n",
				name, checksum);
	}

	Q_memcpy (&r_spritedesc, &saved_desc, sizeof(saved_desc));
	D_SpriteScanRightEdgeSetState (saved_spans, saved_min, saved_max,
			saved_xleft, saved_xright, saved_ytop, saved_ybottom);
	cachewidth = saved_cachewidth;
	cacheblock = (pixel_t *)saved_cacheblock;
	sprite_height = saved_sprite_height;
	Bench486SpriteGradientWriteResult (&saved_gradient);
	Q_memcpy (vright, saved_view_right, sizeof(saved_view_right));
	Q_memcpy (vup, saved_view_up, sizeof(saved_view_up));
	Q_memcpy (vpn, saved_view_normal, sizeof(saved_view_normal));
	Q_memcpy (modelorg, saved_modelorg, sizeof(saved_modelorg));
	xscaleinv = saved_xscaleinv;
	yscaleinv = saved_yscaleinv;
	xcenter = saved_xcenter;
	ycenter = saved_ycenter;
	d_viewbuffer = saved_viewbuffer;
	d_pzbuffer = saved_zbuffer;
	d_zwidth = saved_zwidth;
	screenwidth = saved_screenwidth;
	for (i=0 ; i<200 ; i++)
	{
		viewspantable[i] = saved_view_rows[i];
		zspantable[i] = saved_z_rows[i];
	}
}

static void Bench486SpriteDrawCases (void)
{
	emitpoint_t fractional_rectangle[4] = {
		{ 82.25, 70.5, 0.0, 0.0, 0.0 },
		{ 118.25, 72.25, 0.0, 0.0, 0.0 },
		{ 115.75, 121.5, 0.0, 0.0, 0.0 },
		{ 80.25, 119.25, 0.0, 0.0, 0.0 }
	};
	emitpoint_t viewport_clip[4] = {
		{ -30.5, 30.25, 0.0, 0.0, 0.0 },
		{ 350.25, 42.5, 0.0, 0.0, 0.0 },
		{ 260.5, 151.25, 0.0, 0.0, 0.0 },
		{ 50.25, 180.75, 0.0, 0.0, 0.0 }
	};
	emitpoint_t zero_height[4] = {
		{ 80.25, 80.5, 0.0, 0.0, 0.0 },
		{ 120.25, 80.5, 0.0, 0.0, 0.0 },
		{ 120.25, 80.5, 0.0, 0.0, 0.0 },
		{ 80.25, 80.5, 0.0, 0.0, 0.0 }
	};

	Bench486SpriteDrawCase ("fractional-rectangle", 4, fractional_rectangle);
	Bench486SpriteDrawCase ("viewport-clamp", 4, viewport_clip);
	Bench486SpriteDrawCase ("zero-scan", 4, zero_height);
}

static emitpoint_t *bench486_sprite_project_capture;

static void Bench486SpriteCaptureProjected (const spritedesc_t *desc)
{
	if (desc->nump > 0 && desc->nump < MAXWORKINGVERTS)
		Q_memcpy (bench486_sprite_project_capture, desc->pverts,
				desc->nump * sizeof(emitpoint_t));
}

static void Bench486SpriteSetupCase (char *name, int mode)
{
	typedef union
	{
		mspriteframe_t frame;
		byte storage[512];
	} bench486_sprite_setup_frame_t;
	bench486_sprite_setup_frame_t frame_storage;
	mspriteframe_t *frame;
	spritedesc_t saved_desc, initial_desc;
	clipplane_t saved_clipplanes[4];
	vec5_t saved_clip_verts[2][MAXWORKINGVERTS];
	vec5_t c_final_verts[MAXWORKINGVERTS];
	emitpoint_t c_projected[MAXWORKINGVERTS+1];
	emitpoint_t asm_projected[MAXWORKINGVERTS+1];
	vec3_t saved_entorigin, saved_origin, saved_modelorg;
	float saved_vright[3], saved_vup[3], saved_vpn[3];
	float saved_xscale, saved_yscale, saved_xcenter, saved_ycenter;
	float c_nearzi;
	int saved_clip_current, saved_sprite_width, saved_sprite_height;
	int saved_cachewidth, saved_screenwidth;
	byte *saved_cacheblock;
	sspan_t *saved_spans;
	int saved_min, saved_max;
	float saved_xleft, saved_xright, saved_ytop, saved_ybottom;
	bench486_sprite_gradient_result_t saved_gradient;
	pixel_t *saved_viewbuffer;
	short *saved_zbuffer;
	unsigned int saved_zwidth;
	pixel_t *saved_view_rows[200];
	short *saved_z_rows[200];
	int i, j, failure, first_pixel, first_depth, first_clip_vertex;
	int first_clip_component, first_projected_vertex, first_projected_field;
	int c_nump, asm_nump, c_clip_current;
	unsigned c_nearzi_bits, asm_nearzi_bits;
	unsigned c_vertex_bits, asm_vertex_bits;
	unsigned c_projected_bits, asm_projected_bits;
	unsigned checksum;
	byte *pixels;
	entity_t fixture_entity, *saved_entity;
	model_t fixture_model;
	msprite_t fixture_sprite;
	vec3_t input_entorigin, input_modelorg;
	float c_axes[9];
	void (*saved_project_hook)(const spritedesc_t *desc);

	Q_memset (&frame_storage, 0, sizeof(frame_storage));
	frame = &frame_storage.frame;
	frame->width = 16;
	frame->height = 16;
	frame->up = 8.0;
	frame->down = -8.0;
	frame->left = -8.0;
	frame->right = 8.0;
	pixels = (byte *)&frame->pixels[0];
	for (i=0 ; i<16*16 ; i++)
		pixels[i] = (i % 13) ? (byte)((i * 17 + 3) & 255) : 255;
	saved_entity = currententity;
	saved_project_hook = bench486_sprite_project_hook;
	bench486_sprite_project_hook = Bench486SpriteCaptureProjected;
	if (mode >= 5)
	{
		Q_memset (&fixture_entity,0,sizeof(fixture_entity));
		Q_memset (&fixture_model,0,sizeof(fixture_model));
		Q_memset (&fixture_sprite,0,sizeof(fixture_sprite));
		fixture_sprite.type = mode - 5;
		fixture_sprite.numframes = 1;
		fixture_sprite.frames[0].type = SPR_SINGLE;
		fixture_sprite.frames[0].frameptr = frame;
		fixture_sprite.beamlength = 0.375f;
		fixture_model.cache.data = &fixture_sprite;
		fixture_entity.model = &fixture_model;
		fixture_entity.angles[0] = -11.5f;
		fixture_entity.angles[1] = 7.125f;
		fixture_entity.angles[2] = 17.25f;
		currententity = &fixture_entity;
	}
	if (mode == 2)
	{
		/* Exercise near-plane clamping without an enormous projected quad. */
		frame->up = 0.0001;
		frame->down = -0.0001;
		frame->left = -0.0001;
		frame->right = 0.0001;
	}

	Q_memcpy (&saved_desc, &r_spritedesc, sizeof(saved_desc));
	Q_memcpy (saved_clipplanes, view_clipplanes, sizeof(saved_clipplanes));
	Q_memcpy (saved_clip_verts, clip_verts, sizeof(saved_clip_verts));
	saved_clip_current = clip_current;
	Q_memcpy (saved_entorigin, r_entorigin, sizeof(saved_entorigin));
	Q_memcpy (saved_origin, r_origin, sizeof(saved_origin));
	Q_memcpy (saved_modelorg, modelorg, sizeof(saved_modelorg));
	Q_memcpy (saved_vright, vright, sizeof(saved_vright));
	Q_memcpy (saved_vup, vup, sizeof(saved_vup));
	Q_memcpy (saved_vpn, vpn, sizeof(saved_vpn));
	saved_xscale = xscale;
	saved_yscale = yscale;
	saved_xcenter = xcenter;
	saved_ycenter = ycenter;
	saved_sprite_width = sprite_width;
	saved_sprite_height = sprite_height;
	saved_cachewidth = cachewidth;
	saved_cacheblock = (byte *)cacheblock;
	D_SpriteScanRightEdgeGetState (&saved_spans, &saved_min, &saved_max,
			&saved_xleft, &saved_xright, &saved_ytop, &saved_ybottom);
	Bench486SpriteGradientReadResult (&saved_gradient);
	saved_viewbuffer = d_viewbuffer;
	saved_zbuffer = d_pzbuffer;
	saved_zwidth = d_zwidth;
	saved_screenwidth = screenwidth;
	for (i=0 ; i<200 ; i++)
	{
		saved_view_rows[i] = viewspantable[i];
		saved_z_rows[i] = zspantable[i];
	}

	Q_memset (&r_spritedesc, 0, sizeof(r_spritedesc));
	r_spritedesc.pspriteframe = frame;
	r_spritedesc.vup[2] = 1.0;
	r_spritedesc.vright[1] = -1.0;
	r_spritedesc.vpn[0] = 1.0;
	r_spritedesc.nearzi = 37.5;
	sprite_width = frame->width;
	sprite_height = frame->height;
	r_entorigin[0] = mode == 2 ? 0.005 : 128.0;
	r_entorigin[1] = 0.0;
	r_entorigin[2] = 0.0;
	r_origin[0] = r_origin[1] = r_origin[2] = 0.0;
	modelorg[0] = -r_entorigin[0];
	modelorg[1] = modelorg[2] = 0.0;
	vright[0] = 0.0; vright[1] = -1.0; vright[2] = 0.0;
	vup[0] = 0.0; vup[1] = 0.0; vup[2] = 1.0;
	vpn[0] = 1.0; vpn[1] = 0.0; vpn[2] = 0.0;
	xscale = 160.0;
	yscale = 160.0;
	xcenter = 160.0;
	ycenter = 100.0;
	Q_memset (view_clipplanes, 0, sizeof(view_clipplanes));
	for (i=0 ; i<4 ; i++)
		view_clipplanes[i].dist = -1.0;
	if (mode == 1)
	{
		view_clipplanes[0].normal[1] = 1.0;
		view_clipplanes[0].dist = -2.0;
		view_clipplanes[1].normal[2] = 1.0;
		view_clipplanes[1].dist = -3.0;
	}
	else if (mode == 3)
	{
		view_clipplanes[0].normal[1] = 1.0;
		view_clipplanes[0].dist = 20.0;
	}
	else if (mode == 4)
		r_spritedesc.vpn[0] = -1.0;
	Q_memcpy (&initial_desc, &r_spritedesc, sizeof(initial_desc));
	Q_memcpy (input_entorigin,r_entorigin,sizeof(input_entorigin));
	Q_memcpy (input_modelorg,modelorg,sizeof(input_modelorg));
	Q_memset (&bench486_sprite_c_color,0xa5,sizeof(bench486_sprite_c_color));
	Q_memset (&bench486_sprite_a_color,0xa5,sizeof(bench486_sprite_a_color));
	Q_memset (&bench486_sprite_c_z,0xa5,sizeof(bench486_sprite_c_z));
	Q_memset (&bench486_sprite_a_z,0xa5,sizeof(bench486_sprite_a_z));
	Q_memset (c_projected,0,sizeof(c_projected));
	Q_memset (asm_projected,0,sizeof(asm_projected));

	/* Both paths receive identical span globals, row tables and buffers. */
	d_zwidth = 320;
	screenwidth = 320;
	for (i=0 ; i<200 ; i++)
	{
		viewspantable[i] = (pixel_t *)(bench486_sprite_draw_c_pixels + i * 320);
		zspantable[i] = bench486_sprite_draw_c_depth + i * 320;
	}
	d_viewbuffer = (pixel_t *)bench486_sprite_draw_c_pixels;
	d_pzbuffer = bench486_sprite_draw_c_depth;
	D_SpriteScanRightEdgeSetState (saved_spans, saved_min, saved_max,
			-0.5, 319.5, -0.5, 199.5);
	Bench486SpriteGradientWriteResult (&saved_gradient);
	Q_memset (bench486_sprite_draw_c_pixels, 0xa5,
			sizeof(bench486_sprite_draw_c_pixels));
	Q_memset (bench486_sprite_draw_c_depth, 0,
			sizeof(bench486_sprite_draw_c_depth));
	Q_memset (clip_verts, 0x5a, sizeof(clip_verts));
	clip_current = 1;
	Bench486Printf ("sprite-setup %s entering C path\n", name);
	bench486_sprite_project_capture = c_projected;
	if (mode >= 5) R_DrawSprite_C ();
	else R_SetupAndDrawSprite_C ();
	c_nump = r_spritedesc.nump;
	Q_memcpy (c_axes,&r_spritedesc.vup,sizeof(c_axes));
	c_nearzi = r_spritedesc.nearzi;
	c_clip_current = clip_current;
	Q_memcpy (c_final_verts, clip_verts[clip_current], sizeof(c_final_verts));

	Q_memcpy (&r_spritedesc, &initial_desc, sizeof(r_spritedesc));
	Q_memcpy (r_entorigin,input_entorigin,sizeof(input_entorigin));
	Q_memcpy (modelorg,input_modelorg,sizeof(input_modelorg));
	d_viewbuffer = (pixel_t *)bench486_sprite_draw_asm_pixels;
	d_pzbuffer = bench486_sprite_draw_asm_depth;
	for (i=0 ; i<200 ; i++)
	{
		viewspantable[i] = (pixel_t *)(bench486_sprite_draw_asm_pixels + i * 320);
		zspantable[i] = bench486_sprite_draw_asm_depth + i * 320;
	}
	D_SpriteScanRightEdgeSetState (saved_spans, saved_min, saved_max,
			-0.5, 319.5, -0.5, 199.5);
	Bench486SpriteGradientWriteResult (&saved_gradient);
	Q_memset (bench486_sprite_draw_asm_pixels, 0xa5,
			sizeof(bench486_sprite_draw_asm_pixels));
	Q_memset (bench486_sprite_draw_asm_depth, 0,
			sizeof(bench486_sprite_draw_asm_depth));
	Q_memset (clip_verts, 0x5a, sizeof(clip_verts));
	clip_current = 1;
	Bench486Printf ("sprite-setup %s entering ASM path\n", name);
	bench486_sprite_project_capture = asm_projected;
	if (mode >= 5) R_DrawSprite_asm486 ();
	else R_SetupAndDrawSprite_asm486 ();
	asm_nump = r_spritedesc.nump;

	first_pixel = -1;
	first_depth = -1;
	for (i=0 ; i<320*200 ; i++)
	{
		if (first_pixel < 0 &&
				bench486_sprite_draw_c_pixels[i] != bench486_sprite_draw_asm_pixels[i])
			first_pixel = i;
		if (first_depth < 0 &&
				bench486_sprite_draw_c_depth[i] != bench486_sprite_draw_asm_depth[i])
			first_depth = i;
	}
	first_clip_vertex = -1;
	first_clip_component = -1;
	for (i=0 ; i<MAXWORKINGVERTS && first_clip_vertex < 0 ; i++)
	{
		for (j=0 ; j<5 ; j++)
		{
			if (Q_memcmp (&c_final_verts[i][j],
					&clip_verts[clip_current][i][j], sizeof(float)) != 0)
			{
				first_clip_vertex = i;
				first_clip_component = j;
				break;
			}
		}
	}
	first_projected_vertex = -1;
	first_projected_field = -1;
	if (c_nump == asm_nump && c_nump > 0 && c_nump < MAXWORKINGVERTS)
	{
		for (i=0 ; i<c_nump && first_projected_vertex < 0 ; i++)
		{
			for (j=0 ; j<5 ; j++)
			{
				if (Q_memcmp ((byte *)&c_projected[i] + j * sizeof(float),
						(byte *)&asm_projected[i] + j * sizeof(float),
						sizeof(float)) != 0)
				{
					first_projected_vertex = i;
					first_projected_field = j;
					break;
				}
			}
		}
	}
	failure = first_pixel >= 0 || first_depth >= 0 ||
			c_nump != r_spritedesc.nump || c_clip_current != clip_current ||
			Q_memcmp (&c_nearzi, &r_spritedesc.nearzi, sizeof(c_nearzi)) != 0 ||
			Q_memcmp (c_final_verts, clip_verts[clip_current],
					sizeof(c_final_verts)) != 0 ||
			(c_nump == asm_nump && c_nump > 0 && c_nump < MAXWORKINGVERTS &&
				Q_memcmp (c_projected, asm_projected,
					c_nump * sizeof(emitpoint_t)) != 0) ||
			Q_memcmp (c_axes,&r_spritedesc.vup,sizeof(c_axes));
	for (i=0 ; i<32 ; i++)
	{
		if (bench486_sprite_c_color.before[i] != 0xa5 ||
			bench486_sprite_c_color.after[i] != 0xa5 ||
			bench486_sprite_a_color.before[i] != 0xa5 ||
			bench486_sprite_a_color.after[i] != 0xa5 ||
			bench486_sprite_c_z.before[i] != 0xa5 || bench486_sprite_c_z.after[i] != 0xa5 ||
			bench486_sprite_a_z.before[i] != 0xa5 || bench486_sprite_a_z.after[i] != 0xa5)
		{
			failure = 1;
			Bench486Printf ("sprite-setup %s framebuffer/depth guard FAIL byte %d\n",name,i);
			break;
		}
	}
	if (failure)
	{
		Q_memcpy (&c_nearzi_bits, &c_nearzi, sizeof(c_nearzi_bits));
		Q_memcpy (&asm_nearzi_bits, &r_spritedesc.nearzi,
				sizeof(asm_nearzi_bits));
		c_vertex_bits = 0;
		asm_vertex_bits = 0;
		if (first_clip_vertex >= 0)
		{
			Q_memcpy (&c_vertex_bits,
					&c_final_verts[first_clip_vertex][first_clip_component],
					sizeof(c_vertex_bits));
			Q_memcpy (&asm_vertex_bits,
					&clip_verts[clip_current][first_clip_vertex][first_clip_component],
					sizeof(asm_vertex_bits));
		}
		c_projected_bits = 0;
		asm_projected_bits = 0;
		if (first_projected_vertex >= 0)
		{
			Q_memcpy (&c_projected_bits,
					(byte *)&c_projected[first_projected_vertex] +
						first_projected_field * sizeof(float),
					sizeof(c_projected_bits));
			Q_memcpy (&asm_projected_bits,
					(byte *)&asm_projected[first_projected_vertex] +
						first_projected_field * sizeof(float),
					sizeof(asm_projected_bits));
		}
		bench486_memory_failures++;
		Bench486Printf ("sprite-setup %s parity FAIL pixel %d depth %d nump C/ASM %d/%d clip %d/%d nearzi %08x/%08x clipvertex %d/%d %08x/%08x projected %d/%d %08x/%08x\n",
				name, first_pixel, first_depth, c_nump, r_spritedesc.nump,
				c_clip_current, clip_current,
				c_nearzi_bits, asm_nearzi_bits,
				first_clip_vertex, first_clip_component,
				c_vertex_bits, asm_vertex_bits,
				first_projected_vertex, first_projected_field,
				c_projected_bits, asm_projected_bits);
	}
	else
	{
		checksum = Bench486Checksum (bench486_sprite_draw_c_pixels,
					sizeof(bench486_sprite_draw_c_pixels));
		checksum ^= Bench486Checksum ((byte *)bench486_sprite_draw_c_depth,
					sizeof(bench486_sprite_draw_c_depth));
		checksum = checksum * 33 + Bench486Checksum ((byte *)c_final_verts,
					sizeof(c_final_verts));
		Bench486Printf ("sprite-setup %s exact projected/framebuffer result %u\n",
				name, checksum);
		bench486_sink = bench486_sink * 33 + checksum + (unsigned)mode + 1;
	}

	Q_memcpy (&r_spritedesc, &saved_desc, sizeof(saved_desc));
	Q_memcpy (view_clipplanes, saved_clipplanes, sizeof(saved_clipplanes));
	Q_memcpy (clip_verts, saved_clip_verts, sizeof(saved_clip_verts));
	currententity = saved_entity;
	bench486_sprite_project_hook = saved_project_hook;
	clip_current = saved_clip_current;
	Q_memcpy (r_entorigin, saved_entorigin, sizeof(saved_entorigin));
	Q_memcpy (r_origin, saved_origin, sizeof(saved_origin));
	Q_memcpy (modelorg, saved_modelorg, sizeof(saved_modelorg));
	Q_memcpy (vright, saved_vright, sizeof(saved_vright));
	Q_memcpy (vup, saved_vup, sizeof(saved_vup));
	Q_memcpy (vpn, saved_vpn, sizeof(saved_vpn));
	xscale = saved_xscale;
	yscale = saved_yscale;
	xcenter = saved_xcenter;
	ycenter = saved_ycenter;
	sprite_width = saved_sprite_width;
	sprite_height = saved_sprite_height;
	cachewidth = saved_cachewidth;
	cacheblock = (pixel_t *)saved_cacheblock;
	D_SpriteScanRightEdgeSetState (saved_spans, saved_min, saved_max,
			saved_xleft, saved_xright, saved_ytop, saved_ybottom);
	Bench486SpriteGradientWriteResult (&saved_gradient);
	d_viewbuffer = saved_viewbuffer;
	d_pzbuffer = saved_zbuffer;
	d_zwidth = saved_zwidth;
	screenwidth = saved_screenwidth;
	for (i=0 ; i<200 ; i++)
	{
		viewspantable[i] = saved_view_rows[i];
		zspantable[i] = saved_z_rows[i];
	}
}

static void Bench486SpriteSetupCases (void)
{
	Bench486SpriteSetupCase ("centered", 0);
	Bench486SpriteSetupCase ("frustum-clipped", 1);
	Bench486SpriteSetupCase ("near-plane", 2);
	Bench486SpriteSetupCase ("outside-frustum", 3);
	Bench486SpriteSetupCase ("backface", 4);
	Bench486SpriteSetupCase ("orientation-parallel-upright",5);
	Bench486SpriteSetupCase ("orientation-facing-upright",6);
	Bench486SpriteSetupCase ("orientation-parallel",7);
	Bench486SpriteSetupCase ("orientation-world-angles",8);
	Bench486SpriteSetupCase ("orientation-parallel-roll",9);
}

#include "tests/bench486/bench486_sprite_orientation.h"
#include "tests/bench486/bench486_lightcontrol.h"
#include "tests/bench486/bench486_framecontrol.h"
#include "tests/bench486/bench486_palette.h"
#include "tests/bench486/bench486_mathclosure.h"
#include "tests/bench486/bench486_visibility.h"
#include "tests/bench486/bench486_publicbindings.h"
#include "tests/bench486/bench486_sky.h"
#include "renderer/asm_renderdispatch.h"
#include "tests/bench486/bench486_renderdispatch.h"
#include "renderer/asm_drawingdriver.h"
#include "tests/bench486/bench486_drawingdriver.h"
#include "client/asm_viewcontrol.h"
#include "tests/bench486/bench486_viewcontrol.h"
#include "tests/bench486/bench486_vinit.h"
#if defined(BENCH486) && defined(ASM486_SBAR_PRIMITIVES)
#include "tests/bench486/bench486_sbarprimitives.h"
#endif
#if defined(BENCH486) && defined(ASM486_SBAR_INVENTORY) && \
		defined(ASM486_SBAR_PRIMITIVES)
#include "tests/bench486/bench486_sbarinventory.h"
#endif
#if defined(BENCH486) && defined(ASM486_SBAR_FRAGS_FIXTURE)
#include "tests/bench486/bench486_sbarfrags.h"
#endif
#if defined(BENCH486) && defined(ASM486_SBAR_DRAW_FIXTURE)
#include "tests/bench486/bench486_sbardraw.h"
#endif
#if defined(BENCH486) && defined(ASM486_CONSOLE_INPUT) && \
		!defined(BENCH486_CONSOLE_OUTPUT_ONLY)
#include "tests/bench486/bench486_console_input.h"
#endif
#ifdef BENCH486
#include "tests/bench486/bench486_conprint.h"
#include "tests/bench486/bench486_conprintf.h"
#endif
#if defined(BENCH486) && defined(ASM486_SCREEN_NOTIFY)
#include "tests/bench486/bench486_screennotify.h"
#endif
#if defined(BENCH486) && defined(ASM486_SCREEN_CENTER_STRING)
#include "tests/bench486/bench486_screencenter.h"
#endif
#if defined(BENCH486) && defined(ASM486_SCREEN_ERASE_CENTER_STRING)
#include "tests/bench486/bench486_screenerase.h"
#endif
#if defined(BENCH486) && defined(ASM486_SCREEN_CONSOLE_SETUP)
#include "tests/bench486/bench486_screenconsolesetup.h"
#endif
#if defined(BENCH486) && defined(ASM486_SCREEN_REFDEF)
#include "tests/bench486/bench486_screenrefdef.h"
#endif
#if defined(BENCH486) && defined(ASM486_SCREEN_DRAW_RAM)
#include "tests/bench486/bench486_screendrawram.h"
#endif
#if defined(BENCH486) && defined(ASM486_SCREEN_OVERLAYS)
#include "tests/bench486/bench486_screenoverlays.h"
#endif
#if defined(BENCH486) && defined(ASM486_SCREEN_UPDATE)
#include "tests/bench486/bench486_screenupdate.h"
#endif
#if defined(BENCH486) && defined(ASM486_SCREEN_NET)
#include "tests/bench486/bench486_screennet.h"
#endif
#if defined(BENCH486) && defined(ASM486_SCREEN_TURTLE)
#include "tests/bench486/bench486_screenturtle.h"
#endif
#include "tests/bench486/bench486_drawing.h"
#include "client/asm_chase.h"
#include "tests/bench486/bench486_chase.h"
#ifdef BENCH486
#if defined(ASM486_FIND_TOUCHED_LEAFS) && !defined(QUAKE2)
#include "tests/bench486/bench486_findtouchedleafs.h"
#endif
#include "tests/bench486/bench486_hullcheck.h"
#endif
#include "tests/bench486/bench486_aliascontrol.h"
#if defined(BENCH486) && defined(ASM486_ALIAS_MODEL_LOAD_FIXTURE)
#include "tests/bench486/bench486_aliasmodelload.h"
#endif
#include "tests/bench486/bench486_worldcontrol.h"
#if defined(BENCH486) && defined(ASM486_PARTICLE_UPDATE)
#include "tests/bench486/bench486_particlelist.h"
#endif
#if defined(BENCH486) && defined(ASM486_PARTICLE_DRAW)
#include "tests/bench486/bench486_particledraw.h"
#endif
#if defined(BENCH486) && defined(ASM486_PARTICLE_UPDATE) && \
		defined(ASM486_PARTICLE_DRAW)
#include "tests/bench486/bench486_particleupdate.h"
#endif
#if defined(BENCH486) && defined(ASM486_DRAW_Z_SUBMODEL_POLYS)
#include "tests/bench486/bench486_zsubmodel.h"
#endif
#if defined(BENCH486) && defined(ASM486_TRANSFORM_FRUSTUM)
#include "tests/bench486/bench486_frustum.h"
#endif
#if defined(BENCH486) && defined(ASM486_LINE_GRAPH)
#include "tests/bench486/bench486_linegraph.h"
#endif
#if defined(BENCH486)
#include "tests/bench486/bench486_timegraph.h"
#endif
#if defined(BENCH486) && defined(ASM486_ALIAS_STATS)
#include "tests/bench486/bench486_aliasstats.h"
#endif
#if defined(BENCH486) && defined(ASM486_PRINT_TIMES)
#include "tests/bench486/bench486_printtimes.h"
#endif
#if defined(BENCH486) && defined(ASM486_PARTICLE_EXPLOSION2)
#include "tests/bench486/bench486_particleexplosion2.h"
#endif
#if defined(BENCH486) && defined(ASM486_ROCKET_TRAIL)
#include "tests/bench486/bench486_rockettrail.h"
#endif
#if defined(BENCH486) && defined(ASM486_PARTICLE_EXPLOSION)
#include "tests/bench486/bench486_particleexplosion.h"
#endif
#if defined(BENCH486) && defined(ASM486_RUN_PARTICLE_EFFECT)
#include "tests/bench486/bench486_runparticleeffect.h"
#endif
#if defined(BENCH486) && defined(ASM486_PARSE_PARTICLE_EFFECT)
#include "tests/bench486/bench486_parseparticleeffect.h"
#endif
#ifdef BENCH486
#include "tests/bench486/bench486_forwardspans.h"
#include "tests/bench486/bench486_zspans.h"
#endif
#if defined(BENCH486) && defined(ASM486_EFRAG_STORE)
#include "tests/bench486/bench486_efragstore.h"
#endif
#if defined(BENCH486) && defined(ASM486_ENTITY_PARTICLES)
#include "tests/bench486/bench486_entityparticles.h"
#endif
#if defined(BENCH486) && defined(ASM486_BLOB_EXPLOSION)
#include "tests/bench486/bench486_blobexplosion.h"
#endif
#if defined(BENCH486) && defined(ASM486_LAVA_SPLASH)
#include "tests/bench486/bench486_lavasplash.h"
#endif
#if defined(BENCH486) && defined(ASM486_TELEPORT_SPLASH)
#include "tests/bench486/bench486_teleportsplash.h"
#endif
#if defined(BENCH486) && defined(ASM486_TRANSFORM_PLANE)
#include "tests/bench486/bench486_transformplane.h"
#endif
#if defined(BENCH486) && defined(ASM486_V_PARSE_DAMAGE)
#include "tests/bench486/bench486_vdamage.h"
#endif

static void Bench486AliasBBoxProjectCases (void)
{
	Bench486AliasBBoxProjectCase ("inside", 8, 0x0000, 0);
	Bench486AliasBBoxProjectCase ("mixed", 8, 0x0000, 1);
	Bench486AliasBBoxProjectCase ("z-clipped", 16, 0xaaaa, 1);
	Bench486AliasBBoxProjectCase ("all-left", 8, 0x0000, 2);
#ifdef ASM486_ALIAS_MATRIX_COMPOSE_ASM
	Bench486AliasMatrixComposeCases ();
	Bench486AliasViewMatrixCases ();
#endif
#ifdef ASM486_ALIAS_BBOX_PROJECT
	Bench486AliasTransformVectorCases ();
#endif
}

static double Bench486MeasureAliasTransformFinal (
		bench486_alias_transform_final_fn_t function, finalvert_t *fv,
		auxvert_t *av, trivertx_t *pverts, stvert_t *pstverts, int iterations,
		unsigned *checksum)
{
	double start, elapsed;
	unsigned result_sum;
	int i;

	for (i=0 ; i<BENCH486_MEMORY_WARMUP ; i++)
		function (fv, av, pverts, pstverts);

	start = Sys_FloatTime ();
	for (i=0 ; i<iterations ; i++)
		function (fv, av, pverts, pstverts);
	elapsed = Sys_FloatTime () - start;

	result_sum = Bench486Checksum ((byte *)fv, sizeof(*fv));
	result_sum = result_sum * 33 +
			Bench486Checksum ((byte *)av, sizeof(*av));
	*checksum = result_sum;
	bench486_sink ^= result_sum;
	return elapsed;
}

static void Bench486AliasTransformFinalCase (char *name, int lightmode)
{
	finalvert_t c_fv, asm_fv;
	auxvert_t c_av, asm_av;
	trivertx_t pverts;
	stvert_t pstverts;
	float saved_transform[3][4], saved_lightvec[3], saved_shadelight;
	int saved_ambientlight;
	double c_samples[BENCH486_ALIAS_TRANSFORM_FINAL_SAMPLES];
	double asm_samples[BENCH486_ALIAS_TRANSFORM_FINAL_SAMPLES];
	double c_median, asm_median, delta;
	unsigned c_checksum, asm_checksum;
	int i, sample, failure;

	for (i=0 ; i<3 ; i++)
	{
		saved_lightvec[i] = r_plightvec[i];
		saved_transform[i][0] = aliastransform[i][0];
		saved_transform[i][1] = aliastransform[i][1];
		saved_transform[i][2] = aliastransform[i][2];
		saved_transform[i][3] = aliastransform[i][3];
	}
	saved_shadelight = r_shadelight;
	saved_ambientlight = r_ambientlight;

	aliastransform[0][0] = 0.125;
	aliastransform[0][1] = -0.25;
	aliastransform[0][2] = 0.5;
	aliastransform[0][3] = 1.0;
	aliastransform[1][0] = -0.375;
	aliastransform[1][1] = 0.625;
	aliastransform[1][2] = 0.25;
	aliastransform[1][3] = -2.0;
	aliastransform[2][0] = 0.5;
	aliastransform[2][1] = 0.25;
	aliastransform[2][2] = -0.125;
	aliastransform[2][3] = 3.0;
	if (lightmode == 4)
	{
		/*
		 * The C reference adds each row's translation before its third
		 * product.  These exact powers of two make that order return 1.0;
		 * adding the third product before the translation rounds it away on
		 * the 64-bit x87 significand and returns 0.0 instead.
		 */
		aliastransform[0][0] = 2305843009213693952.0; /* 2^61 */
		aliastransform[0][1] = 0.0;
		aliastransform[0][2] = 1.0;
		aliastransform[0][3] = -27670116110564327424.0; /* -3 * 2^63 */
	}
	r_plightvec[0] = 0.0;
	r_plightvec[1] = 0.0;
	r_plightvec[2] = lightmode == 0 ? 1.0 : -1.0;
	if (lightmode == 3)
	{
		int axis;

		// Force lightcos * r_shadelight to about -0.75. The C cast in the
		// reference truncates this to zero; FISTP under the default x87 mode
		// rounds it to -1 unless the assembly selects chop mode explicitly.
		r_plightvec[2] = 0.0;
		for (axis = 0; axis < 3; axis++)
		{
			if (r_avertexnormals[5][axis] != 0.0)
			{
				r_plightvec[axis] = -0.75 / r_avertexnormals[5][axis];
				break;
			}
		}
	}
	r_ambientlight = lightmode == 2 ? 32 : 96;
	r_shadelight = lightmode == 2 ? 160.0 : (lightmode == 3 ? 1.0 : 64.0);

	pverts.v[0] = 12;
	pverts.v[1] = 34;
	pverts.v[2] = lightmode == 4 ? 1 : 56;
	pverts.lightnormalindex = 5;
	pstverts.onseam = ALIAS_ONSEAM;
	pstverts.s = 1234;
	pstverts.t = 5678;
	Q_memset (&c_fv, 0xa5, sizeof(c_fv));
	Q_memset (&asm_fv, 0xa5, sizeof(asm_fv));
	Q_memset (&c_av, 0x5a, sizeof(c_av));
	Q_memset (&asm_av, 0x5a, sizeof(asm_av));

	R_AliasTransformFinalVert_C (&c_fv, &c_av, &pverts, &pstverts);
	R_AliasTransformFinalVert_asm486 (&asm_fv, &asm_av, &pverts, &pstverts);
	failure = Q_memcmp (&c_fv, &asm_fv, sizeof(c_fv)) != 0 ||
			Q_memcmp (&c_av, &asm_av, sizeof(c_av)) != 0;
	if (failure)
	{
		bench486_memory_failures++;
		Bench486Printf ("alias-transform-final %s correctness FAIL\n", name);
	}

	if (!failure)
	{
		for (sample=0 ; sample<BENCH486_ALIAS_TRANSFORM_FINAL_SAMPLES ; sample++)
		{
			Q_memset (&c_fv, 0xa5, sizeof(c_fv));
			Q_memset (&asm_fv, 0xa5, sizeof(asm_fv));
			Q_memset (&c_av, 0x5a, sizeof(c_av));
			Q_memset (&asm_av, 0x5a, sizeof(asm_av));
			if ((sample & 1) == 0)
			{
				c_samples[sample] = Bench486MeasureAliasTransformFinal (
						R_AliasTransformFinalVert_C, &c_fv, &c_av, &pverts,
						&pstverts, BENCH486_ALIAS_TRANSFORM_FINAL_ITERATIONS,
						&c_checksum);
				asm_samples[sample] = Bench486MeasureAliasTransformFinal (
						R_AliasTransformFinalVert_asm486, &asm_fv, &asm_av,
						&pverts, &pstverts,
						BENCH486_ALIAS_TRANSFORM_FINAL_ITERATIONS, &asm_checksum);
			}
			else
			{
				asm_samples[sample] = Bench486MeasureAliasTransformFinal (
						R_AliasTransformFinalVert_asm486, &asm_fv, &asm_av,
						&pverts, &pstverts,
						BENCH486_ALIAS_TRANSFORM_FINAL_ITERATIONS, &asm_checksum);
				c_samples[sample] = Bench486MeasureAliasTransformFinal (
						R_AliasTransformFinalVert_C, &c_fv, &c_av, &pverts,
						&pstverts, BENCH486_ALIAS_TRANSFORM_FINAL_ITERATIONS,
						&c_checksum);
			}

			if (Q_memcmp (&c_fv, &asm_fv, sizeof(c_fv)) != 0 ||
					Q_memcmp (&c_av, &asm_av, sizeof(c_av)) != 0 ||
					c_checksum != asm_checksum)
			{
				bench486_memory_failures++;
				Bench486Printf ("alias-transform-final %s checksum correctness FAIL\n",
						name);
				failure = 1;
				break;
			}
		}
	}

	if (!failure)
	{
		Bench486SortSamples (c_samples,
				BENCH486_ALIAS_TRANSFORM_FINAL_SAMPLES);
		Bench486SortSamples (asm_samples,
				BENCH486_ALIAS_TRANSFORM_FINAL_SAMPLES);
		c_median = c_samples[BENCH486_ALIAS_TRANSFORM_FINAL_SAMPLES / 2];
		asm_median = asm_samples[BENCH486_ALIAS_TRANSFORM_FINAL_SAMPLES / 2];
		delta = c_median > 0.0 ?
				(c_median - asm_median) / c_median * 100.0 : 0.0;
		Bench486Printf ("alias-transform-final %s lightmode %d iterations %d "
				"samples %d\n", name, lightmode,
				BENCH486_ALIAS_TRANSFORM_FINAL_ITERATIONS,
				BENCH486_ALIAS_TRANSFORM_FINAL_SAMPLES);
		Bench486Printf ("  c median %.6f sec checksum %u samples",
				c_median, c_checksum);
		for (i=0 ; i<BENCH486_ALIAS_TRANSFORM_FINAL_SAMPLES ; i++)
			Bench486Printf (" %.6f", c_samples[i]);
		Bench486Printf ("\n");
		Bench486Printf ("  asm486 median %.6f sec checksum %u samples",
				asm_median, asm_checksum);
		for (i=0 ; i<BENCH486_ALIAS_TRANSFORM_FINAL_SAMPLES ; i++)
			Bench486Printf (" %.6f", asm_samples[i]);
		Bench486Printf ("\n");
		Bench486Printf ("  asm486-vs-c median %.3f percent\n", delta);
	}

	for (i=0 ; i<3 ; i++)
	{
		r_plightvec[i] = saved_lightvec[i];
		aliastransform[i][0] = saved_transform[i][0];
		aliastransform[i][1] = saved_transform[i][1];
		aliastransform[i][2] = saved_transform[i][2];
		aliastransform[i][3] = saved_transform[i][3];
	}
	r_shadelight = saved_shadelight;
	r_ambientlight = saved_ambientlight;
}

static void Bench486AliasTransformFinalCases (void)
{
	Bench486AliasTransformFinalCase ("ambient", 0);
	Bench486AliasTransformFinalCase ("shaded", 1);
	Bench486AliasTransformFinalCase ("clamped", 2);
	Bench486AliasTransformFinalCase ("fractional-cast", 3);
	Bench486AliasTransformFinalCase ("x87-row-order", 4);
}

static double Bench486MeasureTextureAxis (bench486_texture_axis_fn_t function,
		void *entry, void *texinfo, void *entity, int frame, int iterations,
		unsigned *hits)
{
	double start, elapsed;
	int i;
	unsigned hit_count;
	void *result;

	for (i=0 ; i<BENCH486_MEMORY_WARMUP ; i++)
		function (entry, texinfo, entity, frame);

	start = Sys_FloatTime ();
	hit_count = 0;
	for (i=0 ; i<iterations ; i++)
	{
		result = function (entry, texinfo, entity, frame);
		if (result == entry)
			hit_count++;
	}
	elapsed = Sys_FloatTime () - start;

	*hits = hit_count;
	bench486_sink ^= hit_count;
	return elapsed;
}

static void Bench486TextureAxisTimingCase (char *name, void *entry,
		void *texinfo, void *entity, int frame, qboolean expected_hit)
{
	double c_samples[BENCH486_MEMORY_SAMPLES];
	double asm_samples[BENCH486_MEMORY_SAMPLES];
	double c_median, asm_median, delta;
	unsigned c_hits, asm_hits;
	int sample;

	for (sample=0 ; sample<BENCH486_MEMORY_SAMPLES ; sample++)
	{
		/* Alternate order to expose first-run cache or emulator bias. */
		if ((sample & 1) == 0)
		{
			c_samples[sample] = Bench486MeasureTextureAxis(
					D_GetTextureAxesHit_C, entry, texinfo, entity, frame,
					500000, &c_hits);
			asm_samples[sample] = Bench486MeasureTextureAxis(
					D_GetTextureAxesHit_asm486, entry, texinfo, entity, frame,
					500000, &asm_hits);
		}
		else
		{
			asm_samples[sample] = Bench486MeasureTextureAxis(
					D_GetTextureAxesHit_asm486, entry, texinfo, entity, frame,
					500000, &asm_hits);
			c_samples[sample] = Bench486MeasureTextureAxis(
					D_GetTextureAxesHit_C, entry, texinfo, entity, frame,
					500000, &c_hits);
		}

		if ((expected_hit && (c_hits != 500000 || asm_hits != 500000)) ||
				(!expected_hit && (c_hits != 0 || asm_hits != 0)))
		{
			bench486_memory_failures++;
			Bench486Printf ("texture-axis %s correctness FAIL\n", name);
			return;
		}
	}

	Bench486SortSamples (c_samples, BENCH486_MEMORY_SAMPLES);
	Bench486SortSamples (asm_samples, BENCH486_MEMORY_SAMPLES);
	c_median = c_samples[BENCH486_MEMORY_SAMPLES / 2];
	asm_median = asm_samples[BENCH486_MEMORY_SAMPLES / 2];
	delta = c_median > 0.0 ? (c_median - asm_median) / c_median * 100.0 : 0.0;
	Bench486Printf ("texture-axis %s iterations 500000 samples %d\n",
			name, BENCH486_MEMORY_SAMPLES);
	Bench486Printf ("  c median %.6f sec samples %.6f %.6f %.6f %.6f %.6f\n",
			c_median, c_samples[0], c_samples[1], c_samples[2],
			c_samples[3], c_samples[4]);
	Bench486Printf ("  asm486 median %.6f sec samples %.6f %.6f %.6f %.6f %.6f\n",
			asm_median, asm_samples[0], asm_samples[1], asm_samples[2],
			asm_samples[3], asm_samples[4]);
	Bench486Printf ("  asm486-vs-c median %.3f percent\n", delta);
}

static void Bench486TextureAxisCase (void)
{
	struct
	{
		void *texinfo;
		void *entity;
		int frame;
	} entry;
	mtexinfo_t texinfo, other_texinfo;
	entity_t entity, other_entity;
	void *expected;
	void *c_result;
	void *asm_result;

	entry.texinfo = &texinfo;
	entry.entity = &entity;
	entry.frame = 37;
	Q_memset (&texinfo, 0, sizeof(texinfo));
	Q_memset (&other_texinfo, 0, sizeof(other_texinfo));
	Q_memset (&entity, 0, sizeof(entity));
	Q_memset (&other_entity, 0, sizeof(other_entity));

	/* Exercise the common hit and each early-reject key. */
	expected = &entry;
	c_result = D_GetTextureAxesHit_C (&entry, &texinfo, &entity, 37);
	asm_result = D_GetTextureAxesHit_asm486 (&entry, &texinfo, &entity, 37);
	if (c_result != expected || asm_result != expected)
		bench486_memory_failures++;

	expected = NULL;
	c_result = D_GetTextureAxesHit_C (&entry, &other_texinfo, &entity, 37);
	asm_result = D_GetTextureAxesHit_asm486 (&entry, &other_texinfo, &entity, 37);
	if (c_result != expected || asm_result != expected)
		bench486_memory_failures++;
	c_result = D_GetTextureAxesHit_C (&entry, &texinfo, &other_entity, 37);
	asm_result = D_GetTextureAxesHit_asm486 (&entry, &texinfo, &other_entity, 37);
	if (c_result != expected || asm_result != expected)
		bench486_memory_failures++;
	c_result = D_GetTextureAxesHit_C (&entry, &texinfo, &entity, 38);
	asm_result = D_GetTextureAxesHit_asm486 (&entry, &texinfo, &entity, 38);
	if (c_result != expected || asm_result != expected)
		bench486_memory_failures++;
	c_result = D_GetTextureAxesHit_C (NULL, &texinfo, &entity, 37);
	asm_result = D_GetTextureAxesHit_asm486 (NULL, &texinfo, &entity, 37);
	if (c_result != expected || asm_result != expected)
		bench486_memory_failures++;

	Bench486TextureAxisTimingCase ("hit", &entry, &texinfo, &entity, 37, true);
	Bench486TextureAxisTimingCase ("miss-texinfo", &entry, &other_texinfo,
			&entity, 37, false);
}

static double Bench486MeasureSurfaceCache (bench486_surface_cache_fn_t function,
		void *cache, int surface_dlightframe, int frame, void *texture,
		int *lightadj, void *surface, int iterations, unsigned *hits)
{
	double start, elapsed;
	int i;
	unsigned hit_count;
	void *result;

	for (i=0 ; i<BENCH486_MEMORY_WARMUP ; i++)
		function (cache, surface_dlightframe, frame, texture, lightadj,
				surface);

	start = Sys_FloatTime ();
	hit_count = 0;
	for (i=0 ; i<iterations ; i++)
	{
		result = function (cache, surface_dlightframe, frame, texture,
				lightadj, surface);
		if (result == cache)
			hit_count++;
	}
	elapsed = Sys_FloatTime () - start;

	*hits = hit_count;
	bench486_sink ^= hit_count;
	return elapsed;
}

static void Bench486SurfaceCacheTimingCase (char *name, void *cache,
		int surface_dlightframe, int frame, void *texture, int *lightadj,
		void *surface, qboolean expected_hit)
{
	double c_samples[BENCH486_MEMORY_SAMPLES];
	double asm_samples[BENCH486_MEMORY_SAMPLES];
	double c_median, asm_median, delta;
	unsigned c_hits, asm_hits;
	int sample;

	for (sample=0 ; sample<BENCH486_MEMORY_SAMPLES ; sample++)
	{
		/* Alternate order to expose first-run cache or emulator bias. */
		if ((sample & 1) == 0)
		{
			c_samples[sample] = Bench486MeasureSurfaceCache(
					D_CacheSurfaceHit_C, cache, surface_dlightframe, frame,
					texture, lightadj, surface,
					BENCH486_SURFACE_CACHE_ITERATIONS,
					&c_hits);
			asm_samples[sample] = Bench486MeasureSurfaceCache(
					D_CacheSurfaceHit_asm486, cache, surface_dlightframe, frame,
					texture, lightadj, surface,
					BENCH486_SURFACE_CACHE_ITERATIONS,
					&asm_hits);
		}
		else
		{
			asm_samples[sample] = Bench486MeasureSurfaceCache(
					D_CacheSurfaceHit_asm486, cache, surface_dlightframe, frame,
					texture, lightadj, surface,
					BENCH486_SURFACE_CACHE_ITERATIONS,
					&asm_hits);
			c_samples[sample] = Bench486MeasureSurfaceCache(
					D_CacheSurfaceHit_C, cache, surface_dlightframe, frame,
					texture, lightadj, surface,
					BENCH486_SURFACE_CACHE_ITERATIONS,
					&c_hits);
		}

		if ((expected_hit && (c_hits != BENCH486_SURFACE_CACHE_ITERATIONS ||
				asm_hits != BENCH486_SURFACE_CACHE_ITERATIONS)) ||
				(!expected_hit && (c_hits != 0 || asm_hits != 0)))
		{
			bench486_memory_failures++;
			Bench486Printf ("surface-cache %s correctness FAIL\n", name);
			return;
		}
	}

	Bench486SortSamples (c_samples, BENCH486_MEMORY_SAMPLES);
	Bench486SortSamples (asm_samples, BENCH486_MEMORY_SAMPLES);
	c_median = c_samples[BENCH486_MEMORY_SAMPLES / 2];
	asm_median = asm_samples[BENCH486_MEMORY_SAMPLES / 2];
	delta = c_median > 0.0 ? (c_median - asm_median) / c_median * 100.0 : 0.0;
	Bench486Printf ("surface-cache %s iterations %d samples %d\n",
			name, BENCH486_SURFACE_CACHE_ITERATIONS, BENCH486_MEMORY_SAMPLES);
	Bench486Printf ("  c median %.6f sec samples %.6f %.6f %.6f %.6f %.6f\n",
			c_median, c_samples[0], c_samples[1], c_samples[2],
			c_samples[3], c_samples[4]);
	Bench486Printf ("  asm486 median %.6f sec samples %.6f %.6f %.6f %.6f %.6f\n",
			asm_median, asm_samples[0], asm_samples[1], asm_samples[2],
			asm_samples[3], asm_samples[4]);
	Bench486Printf ("  asm486-vs-c median %.3f percent\n", delta);
}

static void Bench486SurfaceCacheCase (void)
{
	surfcache_t cache;
	msurface_t surface;
	mplane_t plane;
	mtexinfo_t texinfo;
	dlight_t saved_dlight;
	int lightadj[MAXLIGHTMAPS];
	int other_lightadj[MAXLIGHTMAPS];
	texture_t texture, other_texture;
	void *expected;
	void *c_result;
	void *asm_result;
	int i;

	Q_memset (&cache, 0, sizeof(cache));
	Q_memset (&surface, 0, sizeof(surface));
	Q_memset (&plane, 0, sizeof(plane));
	Q_memset (&texinfo, 0, sizeof(texinfo));
	Q_memset (&texture, 0, sizeof(texture));
	Q_memset (&other_texture, 0, sizeof(other_texture));
	for (i=0 ; i<MAXLIGHTMAPS ; i++)
	{
		lightadj[i] = 100 + i;
		other_lightadj[i] = lightadj[i];
	}
	cache.dlight = 0;
	cache.texture = &texture;
	for (i=0 ; i<MAXLIGHTMAPS ; i++)
		cache.lightadj[i] = lightadj[i];

	/* Exercise the common hit and every fast-path rejection condition. */
	expected = &cache;
	c_result = D_CacheSurfaceHit_C (&cache, 17, 23, &texture, lightadj,
			&surface);
	asm_result = D_CacheSurfaceHit_asm486 (&cache, 17, 23, &texture,
			lightadj, &surface);
	if (c_result != expected || asm_result != expected)
	{
		bench486_memory_failures++;
		Bench486Printf ("surface-cache hit parity FAIL common-hit\n");
	}

	expected = NULL;
	c_result = D_CacheSurfaceHit_C (NULL, 17, 23, &texture, lightadj,
			&surface);
	asm_result = D_CacheSurfaceHit_asm486 (NULL, 17, 23, &texture,
			lightadj, &surface);
	if (c_result != expected || asm_result != expected)
	{
		bench486_memory_failures++;
		Bench486Printf ("surface-cache hit parity FAIL null-cache\n");
	}

	cache.dlight = 1;
	c_result = D_CacheSurfaceHit_C (&cache, 17, 23, &texture, lightadj,
			&surface);
	asm_result = D_CacheSurfaceHit_asm486 (&cache, 17, 23, &texture,
			lightadj, &surface);
	if (c_result != expected || asm_result != expected)
	{
		bench486_memory_failures++;
		Bench486Printf ("surface-cache hit parity FAIL sticky-dlight\n");
	}
	cache.dlight = 0;

	c_result = D_CacheSurfaceHit_C (&cache, 23, 23, &texture, lightadj,
			&surface);
	asm_result = D_CacheSurfaceHit_asm486 (&cache, 23, 23, &texture,
			lightadj, &surface);
	if (c_result != &cache || asm_result != &cache)
	{
		bench486_memory_failures++;
		Bench486Printf ("surface-cache hit parity FAIL phantom-dlight c=%d asm=%d\n",
				c_result == &cache, asm_result == &cache);
	}
	/* A marked but unlit surface may reuse its clean cache. */
	surface.plane = &plane;
	surface.texinfo = &texinfo;
	surface.dlightbits = 1;
	plane.normal[2] = 1.0;
	saved_dlight = cl_dlights[0];
	cl_dlights[0].radius = 0.0;
	cl_dlights[0].minlight = 0.0;
	c_result = D_CacheSurfaceHit_C (&cache, 23, 23, &texture, lightadj,
			&surface);
	asm_result = D_CacheSurfaceHit_asm486 (&cache, 23, 23, &texture,
			lightadj, &surface);
	if (c_result != &cache || asm_result != &cache)
	{
		bench486_memory_failures++;
		Bench486Printf ("surface-cache hit parity FAIL unlit-probe c=%d asm=%d\n",
				c_result == &cache, asm_result == &cache);
	}
	/* A lit discrete sample invalidates the cache on the marked frame. */
	cl_dlights[0].radius = 100.0;
	c_result = D_CacheSurfaceHit_C (&cache, 23, 23, &texture, lightadj,
			&surface);
	asm_result = D_CacheSurfaceHit_asm486 (&cache, 23, 23, &texture,
			lightadj, &surface);
	if (c_result != expected || asm_result != expected)
	{
		bench486_memory_failures++;
		Bench486Printf ("surface-cache hit parity FAIL lit-probe\n");
	}
	cl_dlights[0] = saved_dlight;

	c_result = D_CacheSurfaceHit_C (&cache, 17, 23, &other_texture,
			lightadj, &surface);
	asm_result = D_CacheSurfaceHit_asm486 (&cache, 17, 23, &other_texture,
			lightadj, &surface);
	if (c_result != expected || asm_result != expected)
	{
		bench486_memory_failures++;
		Bench486Printf ("surface-cache hit parity FAIL texture-key\n");
	}

	for (i=0 ; i<MAXLIGHTMAPS ; i++)
	{
		other_lightadj[i] = lightadj[i] + 1;
		c_result = D_CacheSurfaceHit_C (&cache, 17, 23, &texture,
				other_lightadj, &surface);
		asm_result = D_CacheSurfaceHit_asm486 (&cache, 17, 23, &texture,
				other_lightadj, &surface);
		if (c_result != expected || asm_result != expected)
		{
			bench486_memory_failures++;
			Bench486Printf ("surface-cache hit parity FAIL lightadj-%d\n", i);
		}
		other_lightadj[i] = lightadj[i];
	}
	/* styles[1] == 255 makes light-style slots 1..3 irrelevant. */
	surface.styles[1] = 255;
	other_lightadj[0] = lightadj[0];
	other_lightadj[1] = lightadj[1] + 1;
	other_lightadj[2] = lightadj[2] + 1;
	other_lightadj[3] = lightadj[3] + 1;
	c_result = D_CacheSurfaceHit_C (&cache, 17, 23, &texture,
			other_lightadj, &surface);
	asm_result = D_CacheSurfaceHit_asm486 (&cache, 17, 23, &texture,
			other_lightadj, &surface);
	if (c_result != &cache || asm_result != &cache)
	{
		bench486_memory_failures++;
		Bench486Printf ("surface-cache hit parity FAIL unused-style-sentinel\n");
	}
	surface.styles[1] = 0;

	Bench486SurfaceCacheTimingCase ("hit", &cache, 17, 23, &texture,
			lightadj, &surface, true);
	Bench486SurfaceCacheTimingCase ("miss-texture", &cache, 17, 23,
			&other_texture, lightadj, &surface, false);
	cache.dlight = 1;
	Bench486SurfaceCacheTimingCase ("miss-cache-dlight", &cache, 17, 23,
			&texture, lightadj, &surface, false);
	cache.dlight = 0;
}

#ifdef ASM486_SURFACE_CACHE_CHECK
static void Bench486InitSurfaceAllocator (byte *memory,
		surfcache_t **slots)
{
	surfcache_t *first, *second, *third;

	Q_memset (memory, 0, 4096);
	first = (surfcache_t *)memory;
	second = (surfcache_t *)(memory + 512);
	third = (surfcache_t *)(memory + 1280);
	first->next = second;
	first->owner = &slots[0];
	first->size = 512;
	first->width = 64;
	second->next = third;
	second->owner = &slots[1];
	second->size = 768;
	second->width = 32;
	third->next = NULL;
	third->owner = &slots[2];
	third->size = 2812;
	third->width = 16;
	slots[0] = first;
	slots[1] = second;
	slots[2] = third;
	slots[3] = NULL;

	sc_size = 4092;
	sc_base = first;
	sc_rover = first;
	d_initial_rover = third;
	d_roverwrapped = false;
	r_cache_thrash = false;
}

static void Bench486SurfaceCacheSizingParity (void)
{
	static struct
	{
		int width;
		int height;
		int expected;
	} cases[] = {
		{ 320, 200, 2400*1024 },
		{ 319, 200, 2400*1024 },
		{ 321, 200, 2400*1024 + 600 },
		{ 640, 400, 2400*1024 + 576000 },
		{ 640, 480, 2400*1024 + 729600 },
		{ 0, 480, 2400*1024 }
	};
	static char *default_args[] = { "qbench.exe" };
	static char *override_args[] = { "qbench.exe", "-surfcachesize", "128" };
	char **saved_argv;
	int saved_argc, c_size, asm_size, failures, i;

	saved_argv = com_argv;
	saved_argc = com_argc;
	failures = 0;
	com_argv = default_args;
	com_argc = sizeof(default_args) / sizeof(default_args[0]);
	for (i=0 ; i<(int)(sizeof(cases)/sizeof(cases[0])) ; i++)
	{
		c_size = D_SurfaceCacheForRes_C (cases[i].width, cases[i].height);
		asm_size = D_SurfaceCacheForRes (cases[i].width, cases[i].height);
		if (c_size != cases[i].expected || asm_size != cases[i].expected)
			failures++;
	}
	com_argv = override_args;
	com_argc = sizeof(override_args) / sizeof(override_args[0]);
	c_size = D_SurfaceCacheForRes_C (320, 200);
	asm_size = D_SurfaceCacheForRes (320, 200);
	if (c_size != 128*1024 || asm_size != c_size)
		failures++;
	com_argv = saved_argv;
	com_argc = saved_argc;
	Bench486Printf ("surface-cache sizing parity %s (%d resolutions and override)\n",
			failures ? "FAIL" : "PASS",
			(int)(sizeof(cases)/sizeof(cases[0])));
	bench486_memory_failures += failures;
}

static void Bench486SurfaceCacheLifecycleParity (void)
{
	typedef struct
	{
		surfcache_t nodes[3];
		surfcache_t *slots[4];
	} bench486_surface_cache_flush_state_t;
	static union
	{
		unsigned long align;
		byte bytes[4096];
	} c_init, asm_init;
	static bench486_surface_cache_flush_state_t c_flush, asm_flush;
	static const int init_size = 2048;
	surfcache_t *saved_base, *saved_rover;
	int saved_size, expected_size, expected_base_offset, expected_rover_offset;
	int saved_msg_suppress, failures, i;
	byte *c_buffer, *asm_buffer;

	saved_base = sc_base;
	saved_rover = sc_rover;
	saved_size = sc_size;
	saved_msg_suppress = msg_suppress_1;
	msg_suppress_1 = true;
	failures = 0;

	Q_memset (c_init.bytes, 0xa5, sizeof(c_init.bytes));
	Q_memset (asm_init.bytes, 0xa5, sizeof(asm_init.bytes));
	c_buffer = c_init.bytes + 16;
	asm_buffer = asm_init.bytes + 16;
	D_InitCaches_C (c_buffer, init_size);
	expected_size = sc_size;
	expected_base_offset = (int)((byte *)sc_base - c_buffer);
	expected_rover_offset = (int)((byte *)sc_rover - c_buffer);
	D_InitCaches (asm_buffer, init_size);
	if (expected_size != init_size - 4 || sc_size != expected_size ||
		(int)((byte *)sc_base - asm_buffer) != expected_base_offset ||
		(int)((byte *)sc_rover - asm_buffer) != expected_rover_offset ||
		Q_memcmp (c_init.bytes, asm_init.bytes, sizeof(c_init.bytes)) != 0 ||
		((surfcache_t *)asm_buffer)->next != NULL ||
		((surfcache_t *)asm_buffer)->owner != NULL ||
		((surfcache_t *)asm_buffer)->size != expected_size ||
		asm_buffer[expected_size] != 0 ||
		asm_buffer[expected_size + 1] != 1 ||
		asm_buffer[expected_size + 2] != 2 ||
		asm_buffer[expected_size + 3] != 3)
		failures++;
	Bench486Printf ("surface-cache init parity %s (state, guard, canaries)\n",
			failures ? "FAIL" : "PASS");

	failures = 0;
	Q_memset (&c_flush, 0, sizeof(c_flush));
	Q_memset (&asm_flush, 0, sizeof(asm_flush));
	for (i=0 ; i<3 ; i++)
	{
		c_flush.nodes[i].size = 0x100 + i * 0x40;
		c_flush.nodes[i].width = 32 + i;
		c_flush.nodes[i].dlight = i * 7;
		c_flush.nodes[i].lightadj[0] = i * 11;
		c_flush.nodes[i].lightadj[1] = i * 13;
		c_flush.nodes[i].lightadj[2] = i * 17;
		c_flush.nodes[i].lightadj[3] = i * 19;
		asm_flush.nodes[i].size = c_flush.nodes[i].size;
		asm_flush.nodes[i].width = c_flush.nodes[i].width;
		asm_flush.nodes[i].dlight = c_flush.nodes[i].dlight;
		Q_memcpy (asm_flush.nodes[i].lightadj,
				c_flush.nodes[i].lightadj, sizeof(c_flush.nodes[i].lightadj));
	}
	for (i=0 ; i<2 ; i++)
	{
		c_flush.nodes[i].next = &c_flush.nodes[i + 1];
		c_flush.nodes[i].owner = &c_flush.slots[i];
		asm_flush.nodes[i].next = &asm_flush.nodes[i + 1];
		asm_flush.nodes[i].owner = &asm_flush.slots[i];
	}
	c_flush.nodes[2].next = NULL;
	c_flush.nodes[2].owner = NULL;
	asm_flush.nodes[2].next = NULL;
	asm_flush.nodes[2].owner = NULL;
	for (i=0 ; i<4 ; i++)
	{
		c_flush.slots[i] = (i < 3) ? &c_flush.nodes[i] : NULL;
		asm_flush.slots[i] = (i < 3) ? &asm_flush.nodes[i] : NULL;
	}
	sc_base = c_flush.nodes;
	sc_rover = c_flush.nodes + 2;
	sc_size = 0x1357;
	D_FlushCaches_C ();
	sc_base = asm_flush.nodes;
	sc_rover = asm_flush.nodes + 2;
	sc_size = 0x1357;
	D_FlushCaches ();
	if (sc_base != asm_flush.nodes || sc_rover != asm_flush.nodes ||
		sc_size != 0x1357)
		failures++;
	for (i=0 ; i<3 ; i++)
	{
		int c_next, asm_next, c_owner, asm_owner;

		c_next = c_flush.nodes[i].next ?
			(int)(c_flush.nodes[i].next - c_flush.nodes) : -1;
		asm_next = asm_flush.nodes[i].next ?
			(int)(asm_flush.nodes[i].next - asm_flush.nodes) : -1;
		c_owner = c_flush.nodes[i].owner ?
			(int)(c_flush.nodes[i].owner - c_flush.slots) : -1;
		asm_owner = asm_flush.nodes[i].owner ?
			(int)(asm_flush.nodes[i].owner - asm_flush.slots) : -1;
		if (c_next != asm_next || c_owner != asm_owner ||
			Q_memcmp ((byte *)&c_flush.nodes[i] + 8,
				(byte *)&asm_flush.nodes[i] + 8,
				sizeof(c_flush.nodes[i]) - 8) != 0)
			failures++;
	}
	for (i=0 ; i<4 ; i++)
	{
		int c_slot, asm_slot;

		c_slot = c_flush.slots[i] ?
			(int)(c_flush.slots[i] - c_flush.nodes) : -1;
		asm_slot = asm_flush.slots[i] ?
			(int)(asm_flush.slots[i] - asm_flush.nodes) : -1;
		if (c_slot != asm_slot)
			failures++;
	}
	if (c_flush.nodes[0].next || c_flush.nodes[0].owner ||
		c_flush.nodes[0].size != 0x1357 ||
		c_flush.slots[0] || c_flush.slots[1] ||
		c_flush.slots[2] != &c_flush.nodes[2])
		failures++;

	// A NULL cache base is a no-op and must preserve the rover and size.
	sc_base = NULL;
	sc_rover = c_flush.nodes + 1;
	sc_size = 0x2468;
	D_FlushCaches_C ();
	if (sc_base || sc_rover != c_flush.nodes + 1 || sc_size != 0x2468)
		failures++;
	sc_base = NULL;
	sc_rover = asm_flush.nodes + 1;
	sc_size = 0x2468;
	D_FlushCaches ();
	if (sc_base || sc_rover != asm_flush.nodes + 1 || sc_size != 0x2468)
		failures++;

	sc_base = saved_base;
	sc_rover = saved_rover;
	sc_size = saved_size;
	msg_suppress_1 = saved_msg_suppress;
	Bench486Printf ("surface-cache flush parity %s (owner walk, sentinel, null base)\n",
			failures ? "FAIL" : "PASS");
	bench486_memory_failures += failures;
}

static void Bench486SurfaceAllocatorParity (void)
{
	static union
	{
		unsigned long align;
		byte bytes[4096];
	} arena, expected;
	static int widths[7] = { 64, 32, 16, 16, 8, 16, 16 };
	static int payloads[7] = { 100, 400, 700, 2000, 900, 800, 1300 };
	surfcache_t *slots[4], *expected_slots[4], *allocated;
	surfcache_t *saved_base, *saved_rover, *saved_initial_rover;
	int saved_size, saved_roverwrapped, saved_cache_thrash;
	int offsets[7], expected_offsets[7];
	int expected_rover, expected_roverwrapped, expected_cache_thrash;
	int i, failures;
#ifdef PROFILE486
	int saved_profile_active;
#endif

	saved_size = sc_size;
	saved_base = sc_base;
	saved_rover = sc_rover;
	saved_initial_rover = d_initial_rover;
	saved_roverwrapped = d_roverwrapped;
	saved_cache_thrash = r_cache_thrash;
#ifdef PROFILE486
	saved_profile_active = bench486_profile_frame_active;
	bench486_profile_frame_active = false;
#endif
	failures = 0;
	Bench486InitSurfaceAllocator (arena.bytes, slots);
	for (i=0 ; i<7 ; i++)
	{
		allocated = D_SCAlloc_C (widths[i], payloads[i]);
		if (!allocated)
		{
			failures++;
			break;
		}
		offsets[i] = (int)((byte *)allocated - arena.bytes);
		slots[i & 3] = allocated;
		allocated->owner = &slots[i & 3];
	}
	Q_memcpy (expected.bytes, arena.bytes, sizeof(arena.bytes));
	for (i=0 ; i<4 ; i++)
		expected_slots[i] = slots[i];
	for (i=0 ; i<7 ; i++)
		expected_offsets[i] = offsets[i];
	expected_rover = (int)((byte *)sc_rover - arena.bytes);
	expected_roverwrapped = d_roverwrapped;
	expected_cache_thrash = r_cache_thrash;

	Bench486InitSurfaceAllocator (arena.bytes, slots);
	for (i=0 ; i<7 ; i++)
	{
		allocated = D_SCAlloc (widths[i], payloads[i]);
		if (!allocated)
		{
			failures++;
			break;
		}
		offsets[i] = (int)((byte *)allocated - arena.bytes);
		slots[i & 3] = allocated;
		allocated->owner = &slots[i & 3];
	}
	if (Q_memcmp (expected.bytes, arena.bytes, sizeof(arena.bytes)) != 0 ||
		(int)((byte *)sc_rover - arena.bytes) != expected_rover ||
		d_roverwrapped != expected_roverwrapped ||
		r_cache_thrash != expected_cache_thrash)
		failures++;
	for (i=0 ; i<7 ; i++)
		if (offsets[i] != expected_offsets[i])
			failures++;
	for (i=0 ; i<4 ; i++)
		if (slots[i] != expected_slots[i])
			failures++;

	sc_size = saved_size;
	sc_base = saved_base;
	sc_rover = saved_rover;
	d_initial_rover = saved_initial_rover;
	d_roverwrapped = saved_roverwrapped;
	r_cache_thrash = saved_cache_thrash;
#ifdef PROFILE486
	bench486_profile_frame_active = saved_profile_active;
#endif
	Bench486Printf ("surface-cache allocator parity %s (7 allocations)\n",
			failures ? "FAIL" : "PASS");
	bench486_memory_failures += failures;
}

static void Bench486SurfaceAttachTagParity (void)
{
	msurface_t c_surface, asm_surface;
	surfcache_t c_cache[4], asm_cache[4];
	drawsurf_t c_drawsurf, asm_drawsurf;
	surfcache_t **c_owner, **asm_owner;
	int i, scenario, surface_frame, frame, contributed, failures;

	Q_memset (&c_surface, 0, sizeof(c_surface));
	Q_memset (&asm_surface, 0, sizeof(asm_surface));
	Q_memset (c_cache, 0x6b, sizeof(c_cache));
	Q_memset (asm_cache, 0x6b, sizeof(asm_cache));
	Q_memset (&c_drawsurf, 0x5a, sizeof(c_drawsurf));
	Q_memset (&asm_drawsurf, 0x5a, sizeof(asm_drawsurf));
	failures = 0;

	for (i=0 ; i<MIPLEVELS ; i++)
	{
		D_CacheSurfaceAttach_C (&c_surface, i, &c_cache[i],
				&c_drawsurf, 1);
		D_CacheSurfaceAttach_asm486 (&asm_surface, i, &asm_cache[i],
				&asm_drawsurf, 1);
		if (c_surface.cachespots[i] != &c_cache[i] ||
			asm_surface.cachespots[i] != &asm_cache[i] ||
			c_cache[i].owner != &c_surface.cachespots[i] ||
			asm_cache[i].owner != &asm_surface.cachespots[i] ||
			c_drawsurf.surfdat != (pixel_t *)c_cache[i].data ||
			asm_drawsurf.surfdat != (pixel_t *)asm_cache[i].data ||
			Q_memcmp ((byte *)&c_drawsurf + sizeof(void *),
				(byte *)&asm_drawsurf + sizeof(void *),
				sizeof(c_drawsurf) - sizeof(void *)) != 0 ||
			Q_memcmp (&c_cache[i], &asm_cache[i], 4) != 0 ||
			Q_memcmp ((byte *)&c_cache[i] + 8,
				(byte *)&asm_cache[i] + 8,
				sizeof(c_cache[i]) - 8) != 0)
			failures++;
	}

	// Reused blocks keep their current owner slot while surfdat is refreshed.
	c_owner = c_cache[0].owner;
	asm_owner = asm_cache[0].owner;
	D_CacheSurfaceAttach_C (&c_surface, 0, &c_cache[0], &c_drawsurf, 0);
	D_CacheSurfaceAttach_asm486 (&asm_surface, 0, &asm_cache[0],
			&asm_drawsurf, 0);
	if (c_cache[0].owner != c_owner || asm_cache[0].owner != asm_owner ||
		c_surface.cachespots[0] != &c_cache[0] ||
		asm_surface.cachespots[0] != &asm_cache[0] ||
		c_drawsurf.surfdat != (pixel_t *)c_cache[0].data ||
		asm_drawsurf.surfdat != (pixel_t *)asm_cache[0].data)
		failures++;

	for (scenario=0 ; scenario<4 ; scenario++)
	{
		surface_frame = (scenario < 2) ? 17 : 16;
		frame = 17;
		contributed = scenario & 1;
		c_cache[0].dlight = 0x55;
		asm_cache[0].dlight = 0x55;
		D_CacheSurfaceSetDlight_C (&c_cache[0], surface_frame, frame,
				contributed);
		D_CacheSurfaceSetDlight_asm486 (&asm_cache[0], surface_frame, frame,
				contributed);
		if (c_cache[0].dlight != asm_cache[0].dlight ||
			c_cache[0].dlight != ((surface_frame == frame) ? contributed : 0))
			failures++;
	}

	Bench486Printf ("surface-cache attach/tag parity %s (4 mips, 4 dlight states)\n",
			failures ? "FAIL" : "PASS");
	bench486_memory_failures += failures;
}

static void Bench486SurfaceCacheSetupCase (void)
{
	static struct
	{
		short s_extent;
		short t_extent;
		int mip;
	} cases[] = {
		{ 0, 0, 0 }, { 16, 32, 1 }, { 17, 31, 2 }, { 255, 127, 3 },
		{ 320, 200, 0 }, { 1023, 511, 1 }, { 2047, 1023, 2 },
		{ 4095, 2047, 3 }
	};
	msurface_t surface;
	drawsurf_t c_drawsurf, asm_drawsurf;
	surfcache_t c_cache, asm_cache;
	texture_t texture;
	int lightstylevalues[256];
	int i, failures;

	failures = 0;
	Q_memset (&texture, 0, sizeof(texture));
	for (i=0 ; i<256 ; i++)
		lightstylevalues[i] = i*37 - 12345;
	for (i=0 ; i<(int)(sizeof(cases)/sizeof(cases[0])) ; i++)
	{
		Q_memset (&surface, 0, sizeof(surface));
		Q_memset (&c_drawsurf, 0x5a, sizeof(c_drawsurf));
		Q_memset (&asm_drawsurf, 0x5a, sizeof(asm_drawsurf));
		surface.extents[0] = cases[i].s_extent;
		surface.extents[1] = cases[i].t_extent;
		surface.styles[0] = (byte)(i*31);
		surface.styles[1] = (byte)(i*47 + 1);
		surface.styles[2] = (byte)(i*59 + 2);
		surface.styles[3] = (byte)(i*71 + 3);
		D_CacheSurfaceSetup_C (&surface, cases[i].mip, &c_drawsurf);
		D_CacheSurfaceSetup_asm486 (&surface, cases[i].mip, &asm_drawsurf);
		D_CacheSurfaceKeys_C (&surface, &texture, &c_drawsurf,
				lightstylevalues);
		D_CacheSurfaceKeys_asm486 (&surface, &texture, &asm_drawsurf,
				lightstylevalues);
		if (Q_memcmp (&c_drawsurf, &asm_drawsurf, sizeof(c_drawsurf)) != 0)
		{
			failures++;
			Bench486Printf ("surface-cache setup parity FAIL case %d\n", i);
		}
	}
	Bench486Printf ("surface-cache setup/key parity %s (%d cases)\n",
			failures ? "FAIL" : "PASS",
			(int)(sizeof(cases)/sizeof(cases[0])));
	Q_memset (&c_cache, 0x3c, sizeof(c_cache));
	Q_memset (&asm_cache, 0x3c, sizeof(asm_cache));
	D_CacheSurfaceStoreTags_C (&c_cache, &c_drawsurf);
	D_CacheSurfaceStoreTags_asm486 (&asm_cache, &asm_drawsurf);
	if (Q_memcmp (&c_cache, &asm_cache, sizeof(c_cache)) != 0)
	{
		failures++;
		Bench486Printf ("surface-cache tag parity FAIL\n");
	}
	Bench486Printf ("surface-cache tag parity %s\n",
			failures ? "FAIL" : "PASS");
	bench486_memory_failures += failures;
}

static void Bench486SurfaceCacheEntryParity (void)
{
	entity_t entity;
	entity_t *saved_entity;
	msurface_t surface, saved_surface;
	mtexinfo_t texinfo;
	texture_t texture;
	surfcache_t caches[MIPLEVELS], saved_caches[MIPLEVELS];
	drawsurf_t c_drawsurf, saved_drawsurf;
	int saved_lightstyles[256];
	int saved_frame, saved_csurf;
	int mip, i, failures;
	void *c_result, *asm_result;
#ifdef PROFILE486
	int saved_profile_active;
#endif

	saved_entity = currententity;
	saved_frame = r_framecount;
	saved_csurf = c_surf;
	Q_memcpy (saved_lightstyles, d_lightstylevalue,
			sizeof(saved_lightstyles));
	Q_memcpy (&saved_drawsurf, &r_drawsurf, sizeof(saved_drawsurf));
#ifdef PROFILE486
	saved_profile_active = bench486_profile_frame_active;
	bench486_profile_frame_active = false;
#endif

	Q_memset (&entity, 0, sizeof(entity));
	Q_memset (&surface, 0, sizeof(surface));
	Q_memset (&texinfo, 0, sizeof(texinfo));
	Q_memset (&texture, 0, sizeof(texture));
	Q_memset (caches, 0, sizeof(caches));
	currententity = &entity;
	entity.frame = 0;
	texture.anim_total = 0;
	texture.alternate_anims = NULL;
	texinfo.texture = &texture;
	surface.texinfo = &texinfo;
	surface.dlightframe = 90;
	r_framecount = 91;
	for (i=0 ; i<256 ; i++)
		d_lightstylevalue[i] = 256 + i;
	for (i=0 ; i<MAXLIGHTMAPS ; i++)
		surface.styles[i] = i;
	for (mip=0 ; mip<MIPLEVELS ; mip++)
	{
		caches[mip].dlight = 0;
		caches[mip].texture = &texture;
		for (i=0 ; i<MAXLIGHTMAPS ; i++)
			caches[mip].lightadj[i] = d_lightstylevalue[i];
		surface.cachespots[mip] = &caches[mip];
	}
	saved_surface = surface;
	Q_memcpy (saved_caches, caches, sizeof(caches));
	failures = 0;
	for (mip=0 ; mip<MIPLEVELS ; mip++)
	{
		Q_memset (&r_drawsurf, 0x5a, sizeof(r_drawsurf));
		c_result = D_CacheSurface_C (&surface, mip);
		Q_memcpy (&c_drawsurf, &r_drawsurf, sizeof(c_drawsurf));
		Q_memset (&r_drawsurf, 0x5a, sizeof(r_drawsurf));
		asm_result = D_CacheSurface (&surface, mip);
		if (c_result != &caches[mip] || asm_result != &caches[mip] ||
			Q_memcmp (&c_drawsurf, &r_drawsurf, sizeof(c_drawsurf)) != 0 ||
			Q_memcmp (&surface, &saved_surface, sizeof(surface)) != 0 ||
			Q_memcmp (caches, saved_caches, sizeof(caches)) != 0)
			failures++;
	}

	Q_memcpy (d_lightstylevalue, saved_lightstyles,
			sizeof(saved_lightstyles));
	Q_memcpy (&r_drawsurf, &saved_drawsurf, sizeof(saved_drawsurf));
	currententity = saved_entity;
	r_framecount = saved_frame;
	c_surf = saved_csurf;
#ifdef PROFILE486
	bench486_profile_frame_active = saved_profile_active;
#endif
	Bench486Printf ("surface-cache entry parity %s (%d mip cache hits)\n",
			failures ? "FAIL" : "PASS", MIPLEVELS);
	bench486_memory_failures += failures;
}
#endif

static double Bench486MeasureMip (bench486_mip_fn_t function, float scale,
		int iterations, unsigned *checksum)
{
	double start, elapsed;
	int i;
	unsigned result_sum;

	for (i=0 ; i<BENCH486_MEMORY_WARMUP ; i++)
		function (scale);

	start = Sys_FloatTime ();
	result_sum = 0;
	for (i=0 ; i<iterations ; i++)
		result_sum += (unsigned)function (scale);
	elapsed = Sys_FloatTime () - start;

	*checksum = result_sum;
	bench486_sink ^= result_sum;
	return elapsed;
}

static void Bench486MipCase (char *name, float scale)
{
	double c_samples[BENCH486_MEMORY_SAMPLES];
	double asm_samples[BENCH486_MEMORY_SAMPLES];
	double c_median, asm_median, delta;
	unsigned expected, c_checksum, asm_checksum;
	int c_result, asm_result, public_result;
	int sample;

	expected = (unsigned)D_MipLevelForScale_C (scale);
	c_result = D_MipLevelForScale_C (scale);
	asm_result = D_MipLevelForScale_asm486 (scale);
	public_result = D_MipLevelForScale (scale);
	if ((unsigned)c_result != expected || (unsigned)asm_result != expected ||
			(unsigned)public_result != expected)
	{
		bench486_memory_failures++;
		Bench486Printf ("mip %s correctness FAIL scale %.6f expected %u c %d asm-helper %d public %d\n",
				name, scale, expected, c_result, asm_result, public_result);
		return;
	}

	for (sample=0 ; sample<BENCH486_MEMORY_SAMPLES ; sample++)
	{
		/* Alternate order to expose first-run cache or emulator bias. */
		if ((sample & 1) == 0)
		{
			c_samples[sample] = Bench486MeasureMip (D_MipLevelForScale_C,
					scale, BENCH486_MIP_ITERATIONS, &c_checksum);
			asm_samples[sample] = Bench486MeasureMip(
					D_MipLevelForScale_asm486, scale,
					BENCH486_MIP_ITERATIONS, &asm_checksum);
		}
		else
		{
			asm_samples[sample] = Bench486MeasureMip(
					D_MipLevelForScale_asm486, scale,
					BENCH486_MIP_ITERATIONS, &asm_checksum);
			c_samples[sample] = Bench486MeasureMip (D_MipLevelForScale_C,
					scale, BENCH486_MIP_ITERATIONS, &c_checksum);
		}

		if (c_checksum != asm_checksum)
		{
			bench486_memory_failures++;
			Bench486Printf ("mip %s checksum correctness FAIL\n", name);
			return;
		}
	}

	Bench486SortSamples (c_samples, BENCH486_MEMORY_SAMPLES);
	Bench486SortSamples (asm_samples, BENCH486_MEMORY_SAMPLES);
	c_median = c_samples[BENCH486_MEMORY_SAMPLES / 2];
	asm_median = asm_samples[BENCH486_MEMORY_SAMPLES / 2];
	delta = c_median > 0.0 ? (c_median - asm_median) / c_median * 100.0 : 0.0;
	Bench486Printf ("mip %s scale %.6f expected %u iterations %d samples %d\n",
			name, scale, expected, BENCH486_MIP_ITERATIONS,
			BENCH486_MEMORY_SAMPLES);
	Bench486Printf ("  c median %.6f sec samples %.6f %.6f %.6f %.6f %.6f\n",
			c_median, c_samples[0], c_samples[1], c_samples[2],
			c_samples[3], c_samples[4]);
	Bench486Printf ("  asm486 median %.6f sec samples %.6f %.6f %.6f %.6f %.6f\n",
			asm_median, asm_samples[0], asm_samples[1], asm_samples[2],
			asm_samples[3], asm_samples[4]);
	Bench486Printf ("  asm486-vs-c median %.3f percent\n", delta);
}

static void Bench486MipCases (void)
{
	float saved_scalemip[3];
	int saved_minmip;
	int i;

	for (i=0 ; i<3 ; i++)
		saved_scalemip[i] = d_scalemip[i];
	saved_minmip = d_minmip;

	/* bench486 runs before a map view initializes these renderer thresholds. */
	d_scalemip[0] = 1.0;
	d_scalemip[1] = 0.4;
	d_scalemip[2] = 0.2;
	d_minmip = 0;
	Bench486MipCase ("above-mip0", d_scalemip[0] + 0.1);
	Bench486MipCase ("at-mip0", d_scalemip[0]);
	Bench486MipCase ("between-mip0-mip1",
			(d_scalemip[0] + d_scalemip[1]) * 0.5);
	Bench486MipCase ("at-mip1", d_scalemip[1]);
	Bench486MipCase ("between-mip1-mip2",
			(d_scalemip[1] + d_scalemip[2]) * 0.5);
	Bench486MipCase ("at-mip2", d_scalemip[2]);
	Bench486MipCase ("below-mip2", d_scalemip[2] - 0.1);
	d_minmip = 2;
	Bench486MipCase ("clamped-minmip", d_scalemip[0] - 0.1);

	for (i=0 ; i<3 ; i++)
		d_scalemip[i] = saved_scalemip[i];
	d_minmip = saved_minmip;
}

#ifdef ASM486_SURFACE_ZGRADIENTS
static void Bench486SurfaceZGradientCases (void)
{
	static mplane_t planes[3];
	static entity_t entities[2];
	static surf_t c_surface, asm_surface;
	static const int plane_indices[8] = { 0, 0, 1, 1, 1, 2, 2, 2 };
	static const int frame_offsets[8] = { 0, 0, 0, 1, 1, 1, 2, 2 };
	static const int entity_indices[8] = { 0, 0, 0, 0, 1, 1, 1, 1 };
	float saved_modelorg[3], saved_vright[3], saved_vup[3], saved_vpn[3];
	float saved_xscaleinv, saved_yscaleinv, saved_xcenter, saved_ycenter;
	entity_t *saved_entity;
	surf_t *saved_surface;
	int saved_frame;
	unsigned short original_cw, test_cw, c_after_cw, asm_after_cw;
	int mode, step, failures, cases;

	saved_entity = currententity;
	saved_surface = surface_p;
	saved_frame = r_framecount;
	Q_memcpy (saved_modelorg, modelorg, sizeof(saved_modelorg));
	Q_memcpy (saved_vright, vright, sizeof(saved_vright));
	Q_memcpy (saved_vup, vup, sizeof(saved_vup));
	Q_memcpy (saved_vpn, vpn, sizeof(saved_vpn));
	saved_xscaleinv = xscaleinv;
	saved_yscaleinv = yscaleinv;
	saved_xcenter = xcenter;
	saved_ycenter = ycenter;
	__asm__ __volatile__ ("fnstcw %0" : "=m" (original_cw));

	Q_memset (planes, 0, sizeof(planes));
	Q_memset (entities, 0, sizeof(entities));
	planes[0].normal[0] = 0.25f;
	planes[0].normal[1] = -0.5f;
	planes[0].normal[2] = 1.25f;
	planes[0].dist = 5.5f;
	planes[1].normal[0] = -0.75f;
	planes[1].normal[1] = 0.125f;
	planes[1].normal[2] = 0.625f;
	planes[1].dist = 4.25f;
	planes[2].normal[0] = 1.5f;
	planes[2].normal[1] = 0.375f;
	planes[2].normal[2] = -0.25f;
	planes[2].dist = 6.75f;

	failures = 0;
	cases = 0;
	for (mode=0 ; mode<4 && !failures ; mode++)
	{
		test_cw = (original_cw & (unsigned short)~0x0c00) |
				(unsigned short)(mode << 10);
		r_zgradient_asm_cache_frame = 0;
		r_zgradient_asm_cache_plane = NULL;
		r_zgradient_asm_cache_entity = NULL;
		r_zgradient_asm_cache_zistepu = 0.0f;
		r_zgradient_asm_cache_zistepv = 0.0f;
		r_zgradient_asm_cache_ziorigin = 0.0f;

		for (step=0 ; step<8 && !failures ; step++)
		{
			/* Same plane/entity/frame at step 1 must hit even though the plane
			 * contents and the other inputs changed after step 0. */
			if (step == 1)
			{
				planes[0].normal[0] = -1.125f;
				planes[0].normal[1] = 0.875f;
				planes[0].normal[2] = 0.25f;
				planes[0].dist = 9.125f;
			}

			currententity = &entities[entity_indices[step]];
			r_framecount = 0x13570000 + mode * 16 + frame_offsets[step];
			modelorg[0] = 0.125f * (step + 1);
			modelorg[1] = -0.1875f * (step + 2);
			modelorg[2] = 0.3125f * (step + 3);
			vright[0] = 0.75f - 0.03125f * step;
			vright[1] = -0.25f + 0.015625f * step;
			vright[2] = 0.125f + 0.0078125f * step;
			vup[0] = -0.125f + 0.01171875f * step;
			vup[1] = 0.875f - 0.0234375f * step;
			vup[2] = 0.25f + 0.01953125f * step;
			vpn[0] = 0.1875f + 0.015625f * step;
			vpn[1] = -0.3125f + 0.0078125f * step;
			vpn[2] = 0.9375f - 0.02734375f * step;
			xscaleinv = 0.625f + 0.03125f * step;
			yscaleinv = 0.8125f - 0.015625f * step;
			xcenter = 160.25f + 0.125f * step;
			ycenter = 99.75f - 0.1875f * step;

			Q_memset (&c_surface, 0xa5, sizeof(c_surface));
			surface_p = &c_surface;
			__asm__ __volatile__ ("fldcw %0" : : "m" (test_cw));
			R_SetSurfaceZGradients_C (&planes[plane_indices[step]]);
			__asm__ __volatile__ ("fnstcw %0" : "=m" (c_after_cw));

			Q_memset (&asm_surface, 0xa5, sizeof(asm_surface));
			surface_p = &asm_surface;
			__asm__ __volatile__ ("fldcw %0" : : "m" (test_cw));
			R_SetSurfaceZGradients_asm486 (&planes[plane_indices[step]]);
			__asm__ __volatile__ ("fnstcw %0" : "=m" (asm_after_cw));
			cases++;

			if (Q_memcmp (&c_surface, &asm_surface, sizeof(c_surface)) != 0 ||
					c_after_cw != test_cw || asm_after_cw != test_cw)
			{
				failures++;
				Bench486Printf ("z-gradient parity FAIL rounding %d case %d c %.9g %.9g %.9g asm %.9g %.9g %.9g cw %04x/%04x expected %04x\n",
						mode, step, c_surface.d_ziorigin, c_surface.d_zistepu,
						c_surface.d_zistepv, asm_surface.d_ziorigin,
						asm_surface.d_zistepu, asm_surface.d_zistepv,
						c_after_cw, asm_after_cw, test_cw);
			}
		}
	}

	__asm__ __volatile__ ("fldcw %0" : : "m" (original_cw));
	surface_p = saved_surface;
	currententity = saved_entity;
	r_framecount = saved_frame;
	Q_memcpy (modelorg, saved_modelorg, sizeof(saved_modelorg));
	Q_memcpy (vright, saved_vright, sizeof(saved_vright));
	Q_memcpy (vup, saved_vup, sizeof(saved_vup));
	Q_memcpy (vpn, saved_vpn, sizeof(saved_vpn));
	xscaleinv = saved_xscaleinv;
	yscaleinv = saved_yscaleinv;
	xcenter = saved_xcenter;
	ycenter = saved_ycenter;
	bench486_memory_failures += failures;
	Bench486Printf ("surface Z-gradient parity %s (%d plane/cache/rounding cases; %d mismatches)\n",
			failures ? "FAIL" : "PASS", cases, failures);
}
#endif

#ifdef ASM486_SURFACE_GRADIENTS
typedef struct
{
	float	steps_and_origins[6];
	fixed16_t	texture_bounds[4];
} bench486_surface_gradient_result_t;

extern byte d_texaxis_cache_asm[];

static void Bench486CaptureSurfaceGradients (
	bench486_surface_gradient_result_t *result)
{
	Q_memset (result, 0, sizeof(*result));
	result->steps_and_origins[0] = d_sdivzstepu;
	result->steps_and_origins[1] = d_tdivzstepu;
	result->steps_and_origins[2] = d_sdivzstepv;
	result->steps_and_origins[3] = d_tdivzstepv;
	result->steps_and_origins[4] = d_sdivzorigin;
	result->steps_and_origins[5] = d_tdivzorigin;
	result->texture_bounds[0] = sadjust;
	result->texture_bounds[1] = tadjust;
	result->texture_bounds[2] = bbextents;
	result->texture_bounds[3] = bbextentt;
}

static void Bench486SurfaceGradientCases (void)
{
	static mtexinfo_t texinfos[2];
	static msurface_t faces[2];
	static entity_t entities[2];
	float saved_transformed_modelorg[3];
	float saved_vright[3], saved_vup[3], saved_vpn[3];
	float saved_mip_xscale[4], saved_mip_yscale[4];
	float saved_xscaleinv, saved_yscaleinv, saved_xcenter, saved_ycenter;
	entity_t *saved_entity;
	int saved_frame, saved_mip;
	unsigned short original_cw, test_cw, c_after_cw, asm_after_cw;
	int mode, step, axis, mip, failures, cases, texinfo_index;
	bench486_surface_gradient_result_t c_result, asm_result;

	saved_entity = currententity;
	saved_frame = r_framecount;
	saved_mip = d_gradient_miplevel;
	Q_memcpy (saved_transformed_modelorg, transformed_modelorg,
			sizeof(saved_transformed_modelorg));
	Q_memcpy (saved_vright, vright, sizeof(saved_vright));
	Q_memcpy (saved_vup, vup, sizeof(saved_vup));
	Q_memcpy (saved_vpn, vpn, sizeof(saved_vpn));
	Q_memcpy (saved_mip_xscale, d_mip_xscale, sizeof(saved_mip_xscale));
	Q_memcpy (saved_mip_yscale, d_mip_yscale, sizeof(saved_mip_yscale));
	saved_xscaleinv = xscaleinv;
	saved_yscaleinv = yscaleinv;
	saved_xcenter = xcenter;
	saved_ycenter = ycenter;
	__asm__ __volatile__ ("fnstcw %0" : "=m" (original_cw));

	Q_memset (texinfos, 0, sizeof(texinfos));
	Q_memset (faces, 0, sizeof(faces));
	Q_memset (entities, 0, sizeof(entities));
	for (axis=0 ; axis<2 ; axis++)
	{
		faces[axis].texinfo = &texinfos[axis];
		faces[axis].texturemins[0] = (short)(-37 + axis * 19);
		faces[axis].texturemins[1] = (short)(53 - axis * 29);
		faces[axis].extents[0] = (short)(257 + axis * 131);
		faces[axis].extents[1] = (short)(511 - axis * 73);
	}

	Q_memset (d_texaxis_cache_asm, 0, (d_texaxis_cache_mask + 1) * 36);
	failures = 0;
	cases = 0;
	for (mode=0 ; mode<4 && !failures ; mode++)
	{
		test_cw = (original_cw & (unsigned short)~0x0c00) |
				(unsigned short)(mode << 10);
		Q_memset (d_texaxis_cache_asm, 0, (d_texaxis_cache_mask + 1) * 36);

		for (step=0 ; step<5 && !failures ; step++)
		{
			texinfo_index = step == 4 ? 1 : 0;
			mip = step & 3;
			d_gradient_miplevel = mip;
			xscaleinv = 0.625f + mode * 0.046875f;
			yscaleinv = 0.8125f - mode * 0.03125f;
			for (axis=0 ; axis<4 ; axis++)
			{
				d_mip_xscale[axis] = xscaleinv * d_mipscale_values[axis];
				d_mip_yscale[axis] = yscaleinv * d_mipscale_values[axis];
			}
			xcenter = 159.75f + step * 0.1875f;
			ycenter = 101.125f - step * 0.21875f;
			for (axis=0 ; axis<3 ; axis++)
			{
				vright[axis] = 0.75f - axis * 0.21875f +
						mode * 0.0078125f + step * 0.00390625f;
				vup[axis] = -0.125f + axis * 0.328125f -
						mode * 0.00390625f + step * 0.005859375f;
				vpn[axis] = 0.1875f + axis * 0.2421875f +
						mode * 0.005859375f - step * 0.0078125f;
				transformed_modelorg[axis] = 0.09375f * (axis + 2) -
						mode * 0.015625f + step * 0.0234375f;
			}
			for (axis=0 ; axis<4 ; axis++)
			{
				texinfos[texinfo_index].vecs[0][axis] =
						0.1171875f * (axis + 1) - step * 0.00390625f;
				texinfos[texinfo_index].vecs[1][axis] =
						-0.0859375f * (axis + 2) + mode * 0.005859375f;
			}
			if (step == 1)
			{
				/* Same keys as step 0: both implementations must reuse axes. */
				texinfos[0].vecs[0][0] += 4.0f;
				texinfos[0].vecs[1][1] -= 3.0f;
			}
			currententity = &entities[step == 2 ? 1 : 0];
			r_framecount = 0x23510000 + mode * 16 + (step >= 3 ? 1 : 0);
			__asm__ __volatile__ ("fldcw %0" : : "m" (test_cw));
			D_CalcGradients_C (&faces[texinfo_index]);
			Bench486CaptureSurfaceGradients (&c_result);
			__asm__ __volatile__ ("fnstcw %0" : "=m" (c_after_cw));
			__asm__ __volatile__ ("fldcw %0" : : "m" (test_cw));
			D_CalcGradients_asm486 (&faces[texinfo_index]);
			Bench486CaptureSurfaceGradients (&asm_result);
			__asm__ __volatile__ ("fnstcw %0" : "=m" (asm_after_cw));
			cases++;

			if (Q_memcmp (&c_result, &asm_result, sizeof(c_result)) != 0 ||
					c_after_cw != test_cw || asm_after_cw != test_cw)
			{
				failures++;
				Bench486Printf ("surface-gradient parity FAIL rounding %d case %d mip %d\n",
						mode, step, mip);
				Bench486Printf ("  C steps %.10g %.10g %.10g %.10g origins %.10g %.10g bounds %ld %ld %ld %ld\n",
						c_result.steps_and_origins[0],
						c_result.steps_and_origins[1],
						c_result.steps_and_origins[2],
						c_result.steps_and_origins[3],
						c_result.steps_and_origins[4],
						c_result.steps_and_origins[5],
						(long)c_result.texture_bounds[0],
						(long)c_result.texture_bounds[1],
						(long)c_result.texture_bounds[2],
						(long)c_result.texture_bounds[3]);
				Bench486Printf ("ASM steps %.10g %.10g %.10g %.10g origins %.10g %.10g bounds %ld %ld %ld %ld cw %04x/%04x expected %04x\n",
						asm_result.steps_and_origins[0],
						asm_result.steps_and_origins[1],
						asm_result.steps_and_origins[2],
						asm_result.steps_and_origins[3],
						asm_result.steps_and_origins[4],
						asm_result.steps_and_origins[5],
						(long)asm_result.texture_bounds[0],
						(long)asm_result.texture_bounds[1],
						(long)asm_result.texture_bounds[2],
						(long)asm_result.texture_bounds[3],
						c_after_cw, asm_after_cw, test_cw);
			}
		}
	}

	__asm__ __volatile__ ("fldcw %0" : : "m" (original_cw));
	currententity = saved_entity;
	r_framecount = saved_frame;
	d_gradient_miplevel = saved_mip;
	Q_memcpy (transformed_modelorg, saved_transformed_modelorg,
			sizeof(saved_transformed_modelorg));
	Q_memcpy (vright, saved_vright, sizeof(saved_vright));
	Q_memcpy (vup, saved_vup, sizeof(saved_vup));
	Q_memcpy (vpn, saved_vpn, sizeof(saved_vpn));
	Q_memcpy (d_mip_xscale, saved_mip_xscale, sizeof(saved_mip_xscale));
	Q_memcpy (d_mip_yscale, saved_mip_yscale, sizeof(saved_mip_yscale));
	xscaleinv = saved_xscaleinv;
	yscaleinv = saved_yscaleinv;
	xcenter = saved_xcenter;
	ycenter = saved_ycenter;
	bench486_memory_failures += failures;
	Bench486Printf ("surface-gradient parity %s (%d cache/mip/rounding cases; %d mismatches)\n",
			failures ? "FAIL" : "PASS", cases, failures);
}
#endif

static void Bench486LineCase (char *name, int iterations,
		fixed8_t startu, fixed8_t startv, fixed8_t endu, fixed8_t endv)
{
	int		i;
	double		start, elapsed, rate;
	unsigned	checksum;

	checksum = 0;
	start = Sys_FloatTime ();
	for (i=0 ; i<iterations ; i++)
	{
		D_PolysetSetUpForLineScan (startu, startv, endu, endv);
		checksum ^= (unsigned)(ubasestep + erroradjustup +
				erroradjustdown);
	}
	elapsed = Sys_FloatTime () - start;
	bench486_sink ^= checksum;
	rate = elapsed > 0.0 ? (double)iterations / elapsed : 0.0;
	Bench486Printf ("%s %d ops %.3f sec %.0f ops/sec checksum %u\n",
				name, iterations, elapsed, rate, checksum);
}

static void Bench486AliasLineScanCases (void)
{
	static const struct
	{
		int startu, startv, endu, endv;
	} large_tests[] = {
		{0, 0, 33, 1},
		{0, 0, 32, 33},
		{0, 0, -32, 33},
		{0, 0, -33, 34},
		{1000, -700, -32000, 26000},
		{0, 0, 1000000, 1000000},
		{0, 0, 2147483647, 2147483647},
		{0, 0, (-2147483647 - 1), 2147483647}
	};
	int saved_base, saved_up, saved_down, saved_error;
	int c_base, c_up, c_down, c_error;
	int failures, cases, rounding, tm, tn, test;
	unsigned short original_cw, test_cw, c_after_cw, asm_after_cw;

	saved_base = ubasestep;
	saved_up = erroradjustup;
	saved_down = erroradjustdown;
	saved_error = errorterm;
	__asm__ __volatile__ ("fnstcw %0" : "=m" (original_cw));
	failures = 0;
	cases = 0;

	for (rounding=0 ; rounding<4 ; rounding++)
	{
		test_cw = (original_cw & (unsigned short)~0x0c00) |
				(unsigned short)(rounding << 10);
		for (tm=-31 ; tm<=32 ; tm++)
		{
			for (tn=-31 ; tn<=32 ; tn++)
			{
				__asm__ __volatile__ ("fldcw %0" : : "m" (test_cw));
				D_PolysetSetUpForLineScan_C (0, 0, tm, tn);
				c_base = ubasestep;
				c_up = erroradjustup;
				c_down = erroradjustdown;
				c_error = errorterm;
				__asm__ __volatile__ ("fnstcw %0" : "=m" (c_after_cw));

				__asm__ __volatile__ ("fldcw %0" : : "m" (test_cw));
				D_PolysetSetUpForLineScan_asm486 (0, 0, tm, tn);
				__asm__ __volatile__ ("fnstcw %0" : "=m" (asm_after_cw));
				cases++;
				if (c_base != ubasestep || c_up != erroradjustup ||
						c_down != erroradjustdown || c_error != errorterm ||
						c_after_cw != test_cw || asm_after_cw != test_cw)
				{
					failures++;
					if (failures <= 8)
						Bench486Printf ("alias-line-scan small FAIL tm %d tn %d round %d C %d/%d/%d/%d ASM %d/%d/%d/%d CW %04x/%04x\n",
							tm, tn, rounding, c_base, c_up, c_down, c_error,
							ubasestep, erroradjustup, erroradjustdown, errorterm,
							c_after_cw, asm_after_cw);
				}
			}
		}

		for (test=0 ; test<(int)(sizeof(large_tests)/sizeof(large_tests[0])); test++)
		{
			__asm__ __volatile__ ("fldcw %0" : : "m" (test_cw));
			D_PolysetSetUpForLineScan_C (large_tests[test].startu,
					large_tests[test].startv, large_tests[test].endu,
					large_tests[test].endv);
			c_base = ubasestep;
			c_up = erroradjustup;
			c_down = erroradjustdown;
			c_error = errorterm;
			__asm__ __volatile__ ("fnstcw %0" : "=m" (c_after_cw));

			__asm__ __volatile__ ("fldcw %0" : : "m" (test_cw));
			D_PolysetSetUpForLineScan_asm486 (
					large_tests[test].startu, large_tests[test].startv,
					large_tests[test].endu, large_tests[test].endv);
			__asm__ __volatile__ ("fnstcw %0" : "=m" (asm_after_cw));
			cases++;
			if (c_base != ubasestep || c_up != erroradjustup ||
					c_down != erroradjustdown || c_error != errorterm ||
					c_after_cw != test_cw || asm_after_cw != test_cw)
			{
				failures++;
				if (failures <= 8)
					Bench486Printf ("alias-line-scan large FAIL case %d round %d C %d/%d/%d/%d ASM %d/%d/%d/%d CW %04x/%04x\n",
							test, rounding, c_base, c_up, c_down, c_error,
							ubasestep, erroradjustup, erroradjustdown, errorterm,
							c_after_cw, asm_after_cw);
			}
		}
	}

	__asm__ __volatile__ ("fldcw %0" : : "m" (original_cw));
	ubasestep = saved_base;
	erroradjustup = saved_up;
	erroradjustdown = saved_down;
	errorterm = saved_error;
	bench486_memory_failures += failures;
	Bench486Printf ("alias line-scan setup parity %s (%d cases, four x87 rounding modes; %d mismatches)\n",
			failures ? "FAIL" : "PASS", cases, failures);
}

static void Bench486AliasEdgeTableCases (void)
{
	static const int test_y[] = {
		(-2147483647 - 1), -2147483647, -1, 0, 1, 2147483646, 2147483647
	};
	int saved_p0[6], saved_p1[6], saved_p2[6];
	int failures, cases, rounding, y0, y1, y2;
	unsigned short original_cw, test_cw, c_after_cw, asm_after_cw;
	void *saved_table, *c_table;

	Q_memcpy (saved_p0, r_p0, sizeof(saved_p0));
	Q_memcpy (saved_p1, r_p1, sizeof(saved_p1));
	Q_memcpy (saved_p2, r_p2, sizeof(saved_p2));
	saved_table = D_PolysetGetEdgeTableForBench ();
	__asm__ __volatile__ ("fnstcw %0" : "=m" (original_cw));
	failures = 0;
	cases = 0;

	for (rounding=0 ; rounding<4 ; rounding++)
	{
		test_cw = (original_cw & (unsigned short)~0x0c00) |
				(unsigned short)(rounding << 10);
		for (y0=0 ; y0<(int)(sizeof(test_y)/sizeof(test_y[0])); y0++)
		{
			for (y1=0 ; y1<(int)(sizeof(test_y)/sizeof(test_y[0])); y1++)
			{
				for (y2=0 ; y2<(int)(sizeof(test_y)/sizeof(test_y[0])); y2++)
				{
					r_p0[1] = test_y[y0];
					r_p1[1] = test_y[y1];
					r_p2[1] = test_y[y2];

					__asm__ __volatile__ ("fldcw %0" : : "m" (test_cw));
					D_PolysetSetEdgeTable_C ();
					c_table = D_PolysetGetEdgeTableForBench ();
					__asm__ __volatile__ ("fnstcw %0" : "=m" (c_after_cw));

					__asm__ __volatile__ ("fldcw %0" : : "m" (test_cw));
					D_PolysetSetEdgeTable_asm486 ();
					__asm__ __volatile__ ("fnstcw %0" : "=m" (asm_after_cw));
					cases++;
					if (c_table != D_PolysetGetEdgeTableForBench () ||
							c_after_cw != test_cw || asm_after_cw != test_cw)
					{
						failures++;
						if (failures <= 8)
							Bench486Printf ("alias-edge-table FAIL y %ld/%ld/%ld round %d C 0x%08lx ASM 0x%08lx CW %04x/%04x\n",
								(long)test_y[y0], (long)test_y[y1],
								(long)test_y[y2], rounding,
								(unsigned long)c_table,
								(unsigned long)D_PolysetGetEdgeTableForBench (),
								c_after_cw, asm_after_cw);
					}
				}
			}
		}
	}

	__asm__ __volatile__ ("fldcw %0" : : "m" (original_cw));
	Q_memcpy (r_p0, saved_p0, sizeof(saved_p0));
	Q_memcpy (r_p1, saved_p1, sizeof(saved_p1));
	Q_memcpy (r_p2, saved_p2, sizeof(saved_p2));
	D_PolysetSetEdgeTableForBench (saved_table);
	bench486_memory_failures += failures;
	Bench486Printf ("alias edge-table selection parity %s (%d cases, four x87 rounding modes; %d mismatches)\n",
			failures ? "FAIL" : "PASS", cases, failures);
}

static void Bench486AliasSkinTableCases (void)
{
	static const struct
	{
		int width, offset;
	} tests[] = {
		{1, 0}, {7, 31}, {64, 127}, {320, 512}
	};
	static byte test_skin_data[154000];
	static byte *c_table[480];
	static byte *saved_table[480];
	static byte *sentinel_table[480];
	int saved_width, saved_descriptor_width;
	byte *saved_start, *saved_skin;
	int failures, cases, rounding, test, mode, row, cache_width;
	byte *cache_start, *input_skin, *expected;
	unsigned short original_cw, test_cw, c_after_cw, asm_after_cw;

	saved_width = skinwidth;
	saved_start = skinstart;
	saved_descriptor_width = r_affinetridesc.skinwidth;
	saved_skin = r_affinetridesc.pskin;
	Q_memcpy (saved_table, skintable, sizeof(saved_table));
	__asm__ __volatile__ ("fnstcw %0" : "=m" (original_cw));
	failures = 0;
	cases = 0;

	for (rounding=0 ; rounding<4 ; rounding++)
	{
		test_cw = (original_cw & (unsigned short)~0x0c00) |
				(unsigned short)(rounding << 10);
		for (test=0 ; test<(int)(sizeof(tests)/sizeof(tests[0])); test++)
		{
			input_skin = test_skin_data + tests[test].offset;
			r_affinetridesc.skinwidth = tests[test].width;
			r_affinetridesc.pskin = input_skin;
			for (mode=0 ; mode<4 ; mode++)
			{
				cache_width = tests[test].width;
				cache_start = input_skin;
				if (mode == 0 || mode == 3)
					cache_width++;
				if (mode == 1)
					cache_start = input_skin + 1;
				else if (mode == 3)
					cache_start = input_skin + 3;

				for (row=0 ; row<480 ; row++)
					sentinel_table[row] = test_skin_data + ((row * 7 + test) & 511);

				skinwidth = cache_width;
				skinstart = cache_start;
				Q_memcpy (skintable, sentinel_table, sizeof(sentinel_table));
				__asm__ __volatile__ ("fldcw %0" : : "m" (test_cw));
				D_PolysetUpdateTables_C ();
				Q_memcpy (c_table, skintable, sizeof(c_table));
				__asm__ __volatile__ ("fnstcw %0" : "=m" (c_after_cw));

				skinwidth = cache_width;
				skinstart = cache_start;
				Q_memcpy (skintable, sentinel_table, sizeof(sentinel_table));
				__asm__ __volatile__ ("fldcw %0" : : "m" (test_cw));
				D_PolysetUpdateTables_asm486 ();
				__asm__ __volatile__ ("fnstcw %0" : "=m" (asm_after_cw));
				cases++;

				if (c_after_cw != test_cw || asm_after_cw != test_cw ||
						skinwidth != tests[test].width ||
						skinstart != input_skin ||
						Q_memcmp (c_table, skintable, sizeof(c_table)) != 0)
				{
					failures++;
					if (failures <= 8)
						Bench486Printf ("alias-skin-table state FAIL test %d mode %d round %d cache %d/0x%08lx result %d/0x%08lx CW %04x/%04x\n",
							test, mode, rounding, cache_width,
							(unsigned long)cache_start, skinwidth,
							(unsigned long)skinstart, c_after_cw, asm_after_cw);
				}

				for (row=0 ; row<480 ; row++)
				{
					if (mode == 2)
						expected = sentinel_table[row];
					else
						expected = input_skin + row * tests[test].width;
					if (c_table[row] != expected)
					{
						failures++;
						if (failures <= 8)
							Bench486Printf ("alias-skin-table row FAIL test %d mode %d row %d C 0x%08lx expected 0x%08lx\n",
								 test, mode, row, (unsigned long)c_table[row],
								 (unsigned long)expected);
						break;
					}
				}
			}
		}
	}

	__asm__ __volatile__ ("fldcw %0" : : "m" (original_cw));
	skinwidth = saved_width;
	skinstart = saved_start;
	r_affinetridesc.skinwidth = saved_descriptor_width;
	r_affinetridesc.pskin = saved_skin;
	Q_memcpy (skintable, saved_table, sizeof(saved_table));
	bench486_memory_failures += failures;
	Bench486Printf ("alias skin-table rebuild parity %s (%d cases, four x87 rounding modes; %d mismatches)\n",
			failures ? "FAIL" : "PASS", cases, failures);
}

#ifdef ASM486_FILLRECT
typedef void (*bench486_fillrect_fn_t) (vrect_t *rect, int color);

static double Bench486MeasureFillRect (bench486_fillrect_fn_t function,
		vrect_t *rect, unsigned bytes, int iterations, unsigned *checksum)
{
	double start, elapsed;
	int i;

	Q_memset (vid.buffer, 0xa5, (int)bytes);
	start = Sys_FloatTime ();
	for (i=0 ; i<iterations ; i++)
		function (rect, i);
	elapsed = Sys_FloatTime () - start;
	*checksum = Bench486Checksum ((byte *)vid.buffer, (int)bytes);
	bench486_sink ^= *checksum;
	return elapsed;
}
#endif

#ifdef ASM486_ZPOINT
static void Bench486ZPointCases (void)
{
	static short test_zbuffer[1024];
	static byte test_viewbuffer[1024];
	static float depths[9] = {
		0.0, 0.1, 0.5, 0.99999, 1.0, -1.0, -0.1, 0.25, 0.25
	};
	static short initial_depths[9] = {
		0, 4000, 16384, 32767, 32767, -1, 0, 9000, 8192
	};
	static int colors[9] = {
		0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88, 0x99
	};
	int original_scantable[16];
	short *original_zspantable[16];
	unsigned short original_cw, test_cw, after_cw;
	short *original_pzbuffer;
	pixel_t *original_viewbuffer;
	unsigned int original_zwidth;
	zpointdesc_t original_desc;
	int test, rounding, failures, row;

	__asm__ __volatile__ ("fnstcw %0" : "=m" (original_cw));
	original_desc = r_zpointdesc;
	original_pzbuffer = d_pzbuffer;
	original_viewbuffer = d_viewbuffer;
	original_zwidth = d_zwidth;
	for (row=0 ; row<16 ; row++)
	{
		original_scantable[row] = d_scantable[row];
		original_zspantable[row] = zspantable[row];
		d_scantable[row] = row * 64;
		zspantable[row] = test_zbuffer + row * 64;
	}
	d_pzbuffer = test_zbuffer;
	d_viewbuffer = (pixel_t *)test_viewbuffer;
	d_zwidth = 64;
	failures = 0;
	for (rounding=0 ; rounding<4 ; rounding++)
	{
		test_cw = (original_cw & ~0x0c00) | (rounding << 10);
		for (test=0 ; test<9 ; test++)
		{
			short *pz;
			byte *pdest;
			short c_z, asm_z, old_z;
			byte c_pixel, asm_pixel, old_pixel;
			int u, v;

			u = 2 + test;
			v = 2 + test;

			r_zpointdesc.u = u;
			r_zpointdesc.v = v;
			r_zpointdesc.zi = depths[test];
			r_zpointdesc.color = colors[test];
			pz = zspantable[v] + u;
			pdest = (byte *)d_viewbuffer + d_scantable[v] + u;
			old_z = *pz;
			old_pixel = *pdest;

			*pz = initial_depths[test];
			*pdest = 0xa5;
			__asm__ __volatile__ ("fldcw %0" : : "m" (test_cw));
			D_DrawZPoint_C ();
			c_z = *pz;
			c_pixel = *pdest;

			*pz = initial_depths[test];
			*pdest = 0xa5;
			__asm__ __volatile__ ("fldcw %0" : : "m" (test_cw));
			D_DrawZPoint ();
			__asm__ __volatile__ ("fnstcw %0" : "=m" (after_cw));
			asm_z = *pz;
			asm_pixel = *pdest;

			*pz = old_z;
			*pdest = old_pixel;
			if (c_z != asm_z || c_pixel != asm_pixel || after_cw != test_cw)
			{
				failures++;
				bench486_memory_failures++;
				Bench486Printf ("zpoint parity FAIL round %d case %d c %d/%u asm %d/%u cw %04x/%04x\n",
						rounding, test, c_z, c_pixel, asm_z, asm_pixel,
						test_cw, after_cw);
			}
		}
	}

	r_zpointdesc = original_desc;
	d_pzbuffer = original_pzbuffer;
	d_viewbuffer = original_viewbuffer;
	d_zwidth = original_zwidth;
	for (row=0 ; row<16 ; row++)
	{
		d_scantable[row] = original_scantable[row];
		zspantable[row] = original_zspantable[row];
	}
	__asm__ __volatile__ ("fldcw %0" : : "m" (original_cw));
	Bench486Printf ("zpoint assembly parity %s (36 cases, four x87 rounding modes; %d mismatches)\n",
			failures ? "FAIL" : "PASS", failures);
}
#endif

/* Keep fixture case-address data outside the audited instruction stream. */
static void __attribute__((optimize("no-jump-tables"))) Bench486FillCase (void)
{
	vrect_t	rect;
	int		i;
	double		start, elapsed, rate;
	unsigned	checksum;
#ifdef ASM486_FILLRECT
	unsigned	bytes;
#endif

	if (!vid.buffer)
	{
		Bench486Printf ("fill-rect skipped: no video buffer\n");
		return;
	}

#ifdef ASM486_FILLRECT
	// Compare the selected assembly renderer with the retained C oracle over
	// clipping, byte rows, aligned dword rows, and the large-row path.
	{
		static int colors[8] = { 0, 1, 0x35, 0x7f, 0xa2, 0xfe, 0x10, 0xff };
		unsigned c_checksum, asm_checksum;
		volatile unsigned row_bytes_total;
		int test, aligned_x, parity_failures, rows;

		row_bytes_total = 0;
		for (rows=0 ; rows<(int)vid.height ; rows++)
			row_bytes_total += vid.rowbytes;
		bytes = row_bytes_total;
		parity_failures = 0;
		for (test=0 ; test<8 ; test++)
		{
			rect.x = 0;
			rect.y = 0;
			rect.width = 8;
			rect.height = 4;
			switch (test)
			{
			case 0:
				rect.width = vid.width;
				rect.height = vid.height;
				break;
			case 1:
				rect.x = -3;
				rect.y = -2;
				rect.width = 19;
				rect.height = 13;
				break;
			case 2:
				rect.x = (int)vid.width - 7;
				rect.y = (int)vid.height - 5;
				rect.width = 16;
				rect.height = 12;
				break;
			case 3:
				aligned_x = (-(int)(unsigned long)vid.buffer) & 3;
				rect.x = aligned_x;
				rect.width = 8;
				rect.height = 5;
				break;
			case 4:
				rect.x = 1;
				rect.y = 2;
				rect.width = 3;
				rect.height = 5;
				break;
			case 5:
				rect.width = 16;
				rect.height = 3;
				break;
			case 6:
				rect.x = (int)vid.width + 2;
				break;
			case 7:
				rect.y = (int)vid.height + 1;
				break;
			}
			rect.pnext = NULL;
			Q_memset (vid.buffer, 0xa5, bytes);
			D_FillRect_C (&rect, colors[test]);
			c_checksum = Bench486Checksum ((byte *)vid.buffer, bytes);
			Q_memset (vid.buffer, 0xa5, bytes);
			D_FillRect (&rect, colors[test]);
			asm_checksum = Bench486Checksum ((byte *)vid.buffer, bytes);
			if (c_checksum != asm_checksum)
			{
				parity_failures++;
				bench486_memory_failures++;
				Bench486Printf ("fill-rect assembly parity FAIL case %d c %u asm %u\n",
						test, c_checksum, asm_checksum);
			}
		}
		Bench486Printf ("fill-rect assembly parity %s (8 cases)\n",
				parity_failures ? "FAIL" : "PASS");
	}

	{
		double c_samples[BENCH486_MEMORY_SAMPLES];
		double asm_samples[BENCH486_MEMORY_SAMPLES];
		double c_median, asm_median, delta;
		unsigned c_checksum, asm_checksum;
		int sample, i, iterations;

		rect.x = 0;
		rect.y = 0;
		rect.width = vid.width;
		rect.height = vid.height;
		rect.pnext = NULL;
		iterations = 256;
		for (sample=0 ; sample<BENCH486_MEMORY_SAMPLES ; sample++)
		{
			if (sample & 1)
			{
				asm_samples[sample] = Bench486MeasureFillRect (D_FillRect,
						&rect, bytes, iterations, &asm_checksum);
				c_samples[sample] = Bench486MeasureFillRect (D_FillRect_C,
						&rect, bytes, iterations, &c_checksum);
			}
			else
			{
				c_samples[sample] = Bench486MeasureFillRect (D_FillRect_C,
						&rect, bytes, iterations, &c_checksum);
				asm_samples[sample] = Bench486MeasureFillRect (D_FillRect,
						&rect, bytes, iterations, &asm_checksum);
			}
		}
		Bench486SortSamples (c_samples, BENCH486_MEMORY_SAMPLES);
		Bench486SortSamples (asm_samples, BENCH486_MEMORY_SAMPLES);
		c_median = c_samples[BENCH486_MEMORY_SAMPLES / 2];
		asm_median = asm_samples[BENCH486_MEMORY_SAMPLES / 2];
		delta = c_median > 0.0 ? (c_median - asm_median) / c_median * 100.0 : 0.0;
		if (c_checksum != asm_checksum)
		{
			bench486_memory_failures++;
			Bench486Printf ("fill-rect full-screen checksum FAIL c %u asm %u\n",
					c_checksum, asm_checksum);
		}
		Bench486Printf ("fill-rect full-screen %ux%u %d iterations %d samples\n",
			vid.width, vid.height, iterations, BENCH486_MEMORY_SAMPLES);
		Bench486Printf ("  c median %.6f sec checksum %u samples",
			c_median, c_checksum);
		for (i=0 ; i<BENCH486_MEMORY_SAMPLES ; i++)
			Bench486Printf (" %.6f", c_samples[i]);
		Bench486Printf ("\n");
		Bench486Printf ("  asm median %.6f sec checksum %u samples",
			asm_median, asm_checksum);
		for (i=0 ; i<BENCH486_MEMORY_SAMPLES ; i++)
			Bench486Printf (" %.6f", asm_samples[i]);
		Bench486Printf ("\n  asm-vs-c median %.3f percent\n", delta);
		return;
	}
#endif

	rect.x = 0;
	rect.y = 0;
	rect.width = vid.width;
	rect.height = vid.height;
	rect.pnext = NULL;

	start = Sys_FloatTime ();
	for (i=0 ; i<128 ; i++)
		D_FillRect (&rect, i);
	elapsed = Sys_FloatTime () - start;

	checksum = Bench486Checksum ((byte *)vid.buffer,
			(int)(vid.rowbytes * vid.height));
	bench486_sink ^= checksum;
	rate = elapsed > 0.0 ? 128.0 / elapsed : 0.0;
	Bench486Printf ("fill-rect %ux%u 128 ops %.3f sec %.0f ops/sec checksum %u\n",
			vid.width, vid.height, elapsed, rate, checksum);
}

/*
==================
Bench486FidelityCases

Validates that the emulator under test actually prices the costs a real 486
pays, before it is trusted as the 486-cost gate. A new harness with unvalidated
486 fidelity would be a second, worse version of the mistake recorded at
ASM486-HANDOFF.md:728-736, so these cases are the precondition for using it.

Four probes, each with a known 486 cost and the separation a real 486 shows:

  1. x87 op chain  - a loop whose body is the d_draw16.s:145-198 prologue
                     shape. A flat-FPU emulator prices every x87 op near one
                     cycle and this collapses; a cycle-accurate 486 charges
                     roughly the published latencies.
  2. FISTPL vs FIST - 16-bit store against 32-bit. The cost model prices
                     fistp at 39 cy, so this is the probe for the C1 claim.
  3. L1 residency  - 4 KB working set against 24 KB. Only an emulator with a
                     real 8 KB unified cache shows the second one slowing.
  4. Set aliasing  - two buffers sharing an L1 set index against two that do
                     not. Only a set-associative cache model separates them.

Each probe reports nanoseconds per iteration; the driver script converts using
the pinned clock and compares against the expected ratio.
==================
*/
#define	BENCH486_FIDELITY_WARMUP	100
// Under emulation a serialized x87 chain costs microseconds per iteration, not
// nanoseconds, so the iteration count has to stay small enough to finish. The
// probes compare ratios, so a small count costs precision rather than validity;
// 20000 is comfortably above timer resolution for every probe.
#define	BENCH486_FIDELITY_ITERATIONS	20000
// The 486DX L1 is 8 KB, 4-way, 32-byte lines, 64 sets, so the set index is
// A[11:5]: two addresses share a set when they agree modulo 2048 bytes. 64-byte
// offset moves the index by 2 lines; 2048 and 4096 do not move it at all.
#define	BENCH486_FIDELITY_ALIAS_SPAN	2048
#define	BENCH486_FIDELITY_L1_FIT_BYTES	4096
#define	BENCH486_FIDELITY_L1_MISS_BYTES	24576

static double bench486_fidelity_sink;

// Probe 2: 32-bit FISTPL against 16-bit FIST. The cost model prices fistp at
// 39 cy, so a cycle-accurate 486 must show a clear gap between the two. This is
// the direct test of the C1 candidate (16-bit FIST in d_draw16.s:233-234).
static void Bench486FidelityFpu (int use_fist)
{
	double		start, elapsed;
	int			i;
	volatile int	sink;
	float		a = 1.0001f, b = 0.9999f;
	int			wide = 0;
	short		narrow = 0;
	const char	*label = use_fist ? "fist16" : "fistp32";

	for (i=0 ; i<BENCH486_FIDELITY_WARMUP ; i++)
	{
		float value = (a * b) + a;
		if (use_fist)
		{
			__asm__ __volatile__ ("fistps %0" : "=m" (narrow) : "t" (value));
		}
		else
		{
			__asm__ __volatile__ ("fistpl %0" : "=m" (wide) : "t" (value));
		}
	}

	start = Sys_FloatTime ();
	for (i=0 ; i<BENCH486_FIDELITY_ITERATIONS ; i++)
	{
		float value = (a * b) + a;
		if (use_fist)
		{
			__asm__ __volatile__ ("fistps %0" : "=m" (narrow) : "t" (value));
		}
		else
		{
			__asm__ __volatile__ ("fistpl %0" : "=m" (wide) : "t" (value));
		}
		// Keep the value in a narrow range so neither store takes the
		// integer-indefinite path, which would distort the comparison.
		a = 1.0f + (float)(wide & 0xff) * 0.0001f + (float)(narrow & 0xff) * 0.0001f;
	}
	elapsed = Sys_FloatTime () - start;

	sink = wide + narrow;
	bench486_fidelity_sink += sink;
	Bench486Printf ("fidelity fpu %s %d ops %.6f sec %.1f ns/op checksum %d\n",
			label, BENCH486_FIDELITY_ITERATIONS, elapsed,
			elapsed * 1e9 / BENCH486_FIDELITY_ITERATIONS, sink);
}

// Probe 1: the texture-span prologue shape. A serialized x87 dependency chain
// with a real divide, so a cycle-accurate 486 charges the full chain latency
// while a flat-FPU emulator collapses it toward one cycle per operation.
static void Bench486FidelityX87Chain (void)
{
	double		start, elapsed;
	int			i;
	volatile int	sink;
	int			s = 0, t = 0;

	// Memory operands, exactly as the real prologue references its globals
	// (d_sdivzstepu, d_sdivzorigin, d_ziorigin, ... in d_draw16.s:145-198).
	// This keeps the chain serialized: each result is consumed by the next op,
	// so a latency-accurate 486 cannot hide any of it behind parallelism.
	float		sdivzstepu = 0.5f, sdivzstepv = 0.25f, sdivzorigin = 0.125f;
	float		tdivzstepu = 0.5f, tdivzstepv = 0.25f, tdivzorigin = 0.5f;
	float		zistepu = 0.0625f, zistepv = 0.03125f, ziorigin = 1.0f;
	float		fp64k = 65536.0f;

	start = Sys_FloatTime ();
	for (i=0 ; i<BENCH486_FIDELITY_ITERATIONS ; i++)
	{
		int dv = i, du = i ^ 0x5a5a;

		__asm__ __volatile__
		(
		"fildl %2\n\t"                  // dv
		"fildl %3\n\t"                  // du
		"fmuls %4\n\t"                  // du * sdivzstepu
		"fmuls %5\n\t"                  // dv * sdivzstepv
		"faddp %%st(0),%%st(1)\n\t"
		"fadds %6\n\t"                  // + sdivzorigin
		"fmuls %7\n\t"                  // * tdivzstepu
		"fmuls %8\n\t"                  // * tdivzstepv
		"faddp %%st(0),%%st(1)\n\t"
		"fadds %9\n\t"                  // + tdivzorigin
		"fmuls %10\n\t"                 // * zistepu
		"fmuls %11\n\t"                 // * zistepv
		"faddp %%st(0),%%st(1)\n\t"
		"fadds %12\n\t"                 // + ziorigin
		"flds %13\n\t"                  // fp_64k
		"fdivr %%st(0),%%st(1)\n\t"     // 1/z, a real divide
		"fistpl %0\n\t"                 // s
		"fistpl %1\n\t"                 // t
		: "=m" (s), "=m" (t)
		: "m" (dv), "m" (du), "m" (sdivzstepu), "m" (sdivzstepv),
		  "m" (sdivzorigin), "m" (tdivzstepu), "m" (tdivzstepv),
		  "m" (tdivzorigin), "m" (zistepu), "m" (zistepv), "m" (ziorigin),
		  "m" (fp64k)
		);
	}
	elapsed = Sys_FloatTime () - start;

	sink = s + t;
	bench486_fidelity_sink += sink;
	Bench486Printf ("fidelity x87chain %d ops %.6f sec %.1f ns/op checksum %d\n",
			BENCH486_FIDELITY_ITERATIONS, elapsed,
			elapsed * 1e9 / BENCH486_FIDELITY_ITERATIONS, sink);
}

// Probe 3: a working set that fits the 8 KB L1 against one that cannot.
static void Bench486FidelityL1 (int bytes)
{
	byte		*buffer;
	double		start, elapsed;
	int			i;
	volatile int	sink;
	int			count = bytes / 4;

	buffer = Z_TagMalloc (bytes + 64, 0x1000);
	if (!buffer)
	{
		Bench486Printf ("fidelity l1-%d skipped: allocation failed\n", bytes);
		return;
	}
	for (i=0 ; i<count ; i++)
		((int *)buffer)[i] = i;

	start = Sys_FloatTime ();
	for (i=0 ; i<BENCH486_FIDELITY_ITERATIONS ; i++)
	{
		int index = (i * 4) & (count - 1);
		int value = ((int *)buffer)[index];
		((int *)buffer)[index] = value + 1;
	}
	elapsed = Sys_FloatTime () - start;

	sink = ((int *)buffer)[0];
	bench486_fidelity_sink += sink;
	Bench486Printf ("fidelity l1-%d %d ops %.6f sec %.1f ns/op checksum %d\n",
			bytes, BENCH486_FIDELITY_ITERATIONS, elapsed,
			elapsed * 1e9 / BENCH486_FIDELITY_ITERATIONS, sink);
	Z_Free (buffer);
}

// Probe 4: two buffers sharing an L1 set index against two that do not.
// This is the shape of the vid_surfcache / lvid->buffer collision measured in
// vid_vga.c:299-304, which the DOSBox-X harness cannot observe at all.
static void Bench486FidelityAlias (int offset)
{
	byte		*region, *first, *second;
	double		start, elapsed;
	int			i;
	volatile int	sink;
	int			count = 1024;

	region = Z_TagMalloc (BENCH486_FIDELITY_ALIAS_SPAN * 2 + 8192, 0x1001);
	if (!region)
	{
		Bench486Printf ("fidelity alias-%d skipped: allocation failed\n", offset);
		return;
	}
	first = region + 1024;
	second = first + offset;
	memset (first, 1, count);
	memset (second, 2, count);

	start = Sys_FloatTime ();
	for (i=0 ; i<BENCH486_FIDELITY_ITERATIONS ; i++)
	{
		// Same access pattern the draw loop uses: read one buffer, store to the
		// other, so an aliasing pair contends for the same set on every pass.
		int value = first[i & (count - 1)];
		second[i & (count - 1)] = value + 1;
	}
	elapsed = Sys_FloatTime () - start;

	sink = first[0] + second[0];
	bench486_fidelity_sink += sink;
	Bench486Printf ("fidelity alias-%d %d ops %.6f sec %.1f ns/op checksum %d\n",
			offset, BENCH486_FIDELITY_ITERATIONS, elapsed,
			elapsed * 1e9 / BENCH486_FIDELITY_ITERATIONS, sink);
	Z_Free (region);
}

static void Bench486FidelityCases (void)
{
	Bench486Printf ("fidelity probes measure whether the emulator prices 486 costs.\n");
	Bench486Printf ("A flat-FPU emulator collapses the x87 probes and the cache\n");
	Bench486Printf ("probes tie; such an emulator cannot be used to reject an idea.\n");
	Bench486FidelityX87Chain ();
	Bench486FidelityFpu (0);
	Bench486FidelityFpu (1);
	Bench486FidelityL1 (BENCH486_FIDELITY_L1_FIT_BYTES);
	Bench486FidelityL1 (BENCH486_FIDELITY_L1_MISS_BYTES);
	Bench486FidelityAlias (0);
	Bench486FidelityAlias (64);
}

#ifdef ASM486_SKY_SPAN
typedef void (*bench486_sky_span_fn_t) (byte *source, byte *dest, int count,
		fixed16_t s, fixed16_t t, fixed16_t sstep, fixed16_t tstep);

static double Bench486MeasureSkySpan (bench486_sky_span_fn_t function,
		byte *source, byte *dest, int iterations, unsigned *checksum)
{
	double start, elapsed;
	int i;

	start = Sys_FloatTime ();
	for (i=0 ; i<iterations ; i++)
		function (source, dest, 32, 0x003f8000, 0x005a4000,
				0x00018000, -0x0000c000);
	elapsed = Sys_FloatTime () - start;
	*checksum = Bench486Checksum (dest, 32);
	bench486_sink ^= *checksum;
	return elapsed;
}

static void Bench486SkySpanCases (void)
{
	static byte source[32768];
	static byte c_dest[32];
	static byte asm_dest[32];
	static const fixed16_t cases[][4] = {
		{ 0, 0, 0, 0 },
		{ 0x007f0000, 0x007f0000, 0x00010000, 0x00ff0000 },
		{ 0x007e8000, 0x007e0000, 0x00018000, -0x00018000 },
		{ -1, 0x00400000, 0x00010000, 0x00018000 },
		{ 0x007f0000, 0x007f0000, -0x00010000, -0x00010000 },
		{ 0x00800000, 0x00800000, -0x00018000, 0x00020000 },
		{ 0x12345678, -123456789, 0x00008000, -0x00004000 },
		{ -0x007f0000, -0x007f0000, 0x00010000, 0x00010000 }
	};
	double c_samples[BENCH486_MEMORY_SAMPLES];
	double asm_samples[BENCH486_MEMORY_SAMPLES];
	double c_median, asm_median, delta;
	unsigned c_checksum, asm_checksum;
	int count, test, pixel, i, sample, failures, case_count, iterations;

	for (i=0 ; i<(int)sizeof(source) ; i++)
		source[i] = (byte)(i * 37 + i / 17 + 11);

	failures = 0;
	case_count = 0;
	for (count=1 ; count<=32 ; count++)
	{
		for (test=0 ; test<(int)(sizeof(cases)/sizeof(cases[0])); test++)
		{
			int s, t, sstep, tstep;

			s = cases[test][0];
			t = cases[test][1];
			sstep = cases[test][2];
			tstep = cases[test][3];
			Q_memset (c_dest, 0xa5, sizeof(c_dest));
			Q_memset (asm_dest, 0xa5, sizeof(asm_dest));
			D_SkyDrawPixels_C_Bench (source, c_dest, count, s, t,
					sstep, tstep);
			D_SkyDrawPixels_asm486 (source, asm_dest, count, s, t,
					sstep, tstep);
			for (pixel=0 ; pixel<count ; pixel++)
			{
				if (c_dest[pixel] != asm_dest[pixel])
				{
					failures++;
					bench486_memory_failures++;
					Bench486Printf ("sky-span parity FAIL count %d case %d pixel %d c %u asm %u\n",
							count, test, pixel, c_dest[pixel],
							asm_dest[pixel]);
					break;
				}
			}
			case_count++;
		}
	}
	Bench486Printf ("sky-span assembly parity %s (%d cases; %d mismatches)\n",
			failures ? "FAIL" : "PASS", case_count, failures);
	if (failures)
		return;

	iterations = 15000;
	for (sample=0 ; sample<BENCH486_MEMORY_SAMPLES ; sample++)
	{
		if ((sample & 1) == 0)
		{
			c_samples[sample] = Bench486MeasureSkySpan (
					D_SkyDrawPixels_C_Bench, source, c_dest,
					iterations, &c_checksum);
			asm_samples[sample] = Bench486MeasureSkySpan (
					D_SkyDrawPixels_asm486, source, asm_dest,
					iterations, &asm_checksum);
		}
		else
		{
			asm_samples[sample] = Bench486MeasureSkySpan (
					D_SkyDrawPixels_asm486, source, asm_dest,
					iterations, &asm_checksum);
			c_samples[sample] = Bench486MeasureSkySpan (
					D_SkyDrawPixels_C_Bench, source, c_dest,
					iterations, &c_checksum);
		}
		if (c_checksum != asm_checksum)
		{
			bench486_memory_failures++;
			Bench486Printf ("sky-span timing checksum FAIL sample %d c %u asm %u\n",
					sample, c_checksum, asm_checksum);
			return;
		}
	}

	Bench486SortSamples (c_samples, BENCH486_MEMORY_SAMPLES);
	Bench486SortSamples (asm_samples, BENCH486_MEMORY_SAMPLES);
	c_median = c_samples[BENCH486_MEMORY_SAMPLES / 2];
	asm_median = asm_samples[BENCH486_MEMORY_SAMPLES / 2];
	delta = c_median > 0.0 ? (c_median - asm_median) / c_median * 100.0 : 0.0;
	Bench486Printf ("sky-span timing %d pixels/call %d iterations %d samples %d\n",
			32, iterations, BENCH486_MEMORY_SAMPLES);
	Bench486Printf ("  c median %.6f sec samples %.6f %.6f %.6f %.6f %.6f\n",
			c_median, c_samples[0], c_samples[1], c_samples[2],
			c_samples[3], c_samples[4]);
	Bench486Printf ("  asm486 median %.6f sec samples %.6f %.6f %.6f %.6f %.6f\n",
			asm_median, asm_samples[0], asm_samples[1], asm_samples[2],
			asm_samples[3], asm_samples[4]);
	Bench486Printf ("  asm486-vs-c median %.3f percent\n", delta);
}

static void Bench486SkyScanCases (void)
{
	static byte source[32768];
	static byte c_buffer[320 * 200];
	static byte asm_buffer[320 * 200];
	static const int starts[6] = { 3, 12, 50, 90, 140, 230 };
	static const int rows[6] = { 10, 22, 40, 60, 80, 100 };
	static const int lengths[6] = { 1, 2, 31, 32, 33, 65 };
	static const int coords[8][2] = {
		{ 0, 0 }, { 159, 99 }, { 319, 199 }, { 160, 100 },
		{ 12, 178 }, { 287, 15 }, { -7, 40 }, { 327, 210 }
	};
	espan_t spans[6];
	byte *saved_viewbuffer;
	byte *saved_skysource;
	float saved_vpn[3], saved_vright[3], saved_vup[3];
	float saved_skytime, saved_skyspeed, skytime_offset;
	fixed16_t c_s, c_t, asm_s, asm_t;
	unsigned saved_vid_width, saved_vid_height;
	int saved_screenwidth, saved_vrect_width, saved_vrect_height;
	unsigned short original_cw, test_cw;
	int i, test, mode, pixel, coord, failures, cases, uv_cases;

	saved_viewbuffer = d_viewbuffer;
	saved_skysource = r_skysource;
	saved_screenwidth = screenwidth;
	saved_vid_width = vid.width;
	saved_vid_height = vid.height;
	saved_vrect_width = r_refdef.vrect.width;
	saved_vrect_height = r_refdef.vrect.height;
	saved_skytime = skytime;
	saved_skyspeed = skyspeed;
	Q_memcpy (saved_vpn, vpn, sizeof(saved_vpn));
	Q_memcpy (saved_vright, vright, sizeof(saved_vright));
	Q_memcpy (saved_vup, vup, sizeof(saved_vup));
	__asm__ __volatile__ ("fnstcw %0" : "=m" (original_cw));

	for (i=0 ; i<(int)sizeof(source) ; i++)
		source[i] = (byte)(i * 37 + i / 17 + 11);
	for (i=0 ; i<6 ; i++)
	{
		spans[i].u = starts[i];
		spans[i].v = rows[i];
		spans[i].count = lengths[i];
		spans[i].pnext = i < 5 ? &spans[i+1] : NULL;
	}

	screenwidth = 320;
	vid.width = 320;
	vid.height = 200;
	r_refdef.vrect.width = 320;
	r_refdef.vrect.height = 200;
	r_skysource = source;
	failures = 0;
	cases = 0;
	uv_cases = 0;

	for (test=0 ; test<8 && !failures ; test++)
	{
		vpn[0] = 0.20f + test * 0.013f;
		vpn[1] = -0.35f + test * 0.009f;
		vpn[2] = 0.88f - test * 0.007f;
		vright[0] = 0.91f - test * 0.005f;
		vright[1] = 0.11f + test * 0.004f;
		vright[2] = -0.08f + test * 0.003f;
		vup[0] = -0.12f + test * 0.002f;
		vup[1] = 0.89f - test * 0.006f;
		vup[2] = 0.21f + test * 0.005f;
		skytime = 0.037f * (test + 1);
		skyspeed = 1.25f + 0.125f * test;

		for (mode=0 ; mode<4 && !failures ; mode++)
		{
			test_cw = (original_cw & (unsigned short)~0x0c00) |
					(unsigned short)(mode << 10);
			__asm__ __volatile__ ("fldcw %0" : : "m" (test_cw));
			skytime_offset = skytime * skyspeed;
			for (coord=0 ; coord<8 ; coord++)
			{
				D_Sky_uv_To_st_C (coords[coord][0], coords[coord][1],
						320.0f, skytime_offset, &c_s, &c_t);
				D_SkyUVToST_asm486 (coords[coord][0], coords[coord][1],
						320.0f, skytime_offset, &asm_s, &asm_t);
				if (c_s != asm_s || c_t != asm_t)
				{
					failures++;
					Bench486Printf ("sky UV parity FAIL test %d mode %d coord %d C %d,%d asm %d,%d\n",
							test, mode, coord, c_s, c_t, asm_s, asm_t);
					break;
				}
				uv_cases++;
			}
			if (failures)
				break;
			__asm__ __volatile__ ("fnstcw %0" : "=m" (test_cw));
			if (test_cw != (unsigned short)((original_cw &
					(unsigned short)~0x0c00) | (unsigned short)(mode << 10)))
			{
				failures++;
				Bench486Printf ("sky UV helper control-word changed in mode %d\n", mode);
				break;
			}
			__asm__ __volatile__ ("fldcw %0" : : "m" (test_cw));
			for (pixel=0 ; pixel<(int)sizeof(c_buffer) ; pixel++)
			{
				c_buffer[pixel] = (byte)0xa5;
				asm_buffer[pixel] = (byte)0xa5;
			}
			d_viewbuffer = c_buffer;
			D_DrawSkyScans8_C_Bench (spans);
			__asm__ __volatile__ ("fnstcw %0" : "=m" (test_cw));
			if (test_cw != (unsigned short)((original_cw &
					(unsigned short)~0x0c00) | (unsigned short)(mode << 10)))
			{
				failures++;
				Bench486Printf ("sky-scan C control-word changed in mode %d\n", mode);
				break;
			}
			__asm__ __volatile__ ("fldcw %0" : : "m" (test_cw));
			d_viewbuffer = asm_buffer;
			D_DrawSkyScans8 (spans);
			__asm__ __volatile__ ("fnstcw %0" : "=m" (test_cw));
			if (test_cw != (unsigned short)((original_cw &
					(unsigned short)~0x0c00) | (unsigned short)(mode << 10)))
			{
				failures++;
				Bench486Printf ("sky-scan assembly control-word changed in mode %d\n", mode);
				break;
			}
			for (pixel=0 ; pixel<(int)sizeof(c_buffer) ; pixel++)
			{
				if (c_buffer[pixel] != asm_buffer[pixel])
				{
					failures++;
					Bench486Printf ("sky-scan parity FAIL test %d mode %d byte %d c %u asm %u\n",
							test, mode, pixel, c_buffer[pixel], asm_buffer[pixel]);
					break;
				}
			}
			cases++;
		}
	}

	__asm__ __volatile__ ("fldcw %0" : : "m" (original_cw));
	d_viewbuffer = saved_viewbuffer;
	r_skysource = saved_skysource;
	screenwidth = saved_screenwidth;
	vid.width = saved_vid_width;
	vid.height = saved_vid_height;
	r_refdef.vrect.width = saved_vrect_width;
	r_refdef.vrect.height = saved_vrect_height;
	skytime = saved_skytime;
	skyspeed = saved_skyspeed;
	Q_memcpy (vpn, saved_vpn, sizeof(saved_vpn));
	Q_memcpy (vright, saved_vright, sizeof(saved_vright));
	Q_memcpy (vup, saved_vup, sizeof(saved_vup));
	bench486_memory_failures += failures;
	Bench486Printf ("sky UV projection parity %s (%d coordinate/rounding cases; %d mismatches)\n",
			failures ? "FAIL" : "PASS", uv_cases, failures);
	Bench486Printf ("sky-scan full routine parity %s (%d viewport/rounding cases; %d mismatches)\n",
			failures ? "FAIL" : "PASS", cases, failures);
}
#endif

#ifdef ASM486_WARP_SCREEN
typedef void (*bench486_warp_tables_fn_t) (byte **rowptr, int *column,
		byte *viewbase, int screenwidth, int rowcount, int colcount,
		int h, int w, int hdenominator, int wdenominator,
		int x_origin, float hratio, float wratio);

static unsigned Bench486WarpTablesChecksum (byte **rowptr, int *column,
		int count)
{
	return Bench486Checksum ((byte *)rowptr,	count * sizeof(rowptr[0])) ^
			Bench486Checksum ((byte *)column, count * sizeof(column[0]));
}

static double Bench486MeasureWarpTables (bench486_warp_tables_fn_t function,
		byte **rowptr, int *column, byte *viewbase, int screenwidth,
		int rowcount, int colcount, int h, int w, int hdenominator,
		int wdenominator, int x_origin, float hratio, float wratio,
		int iterations, unsigned *checksum)
{
	double start, elapsed;
	int i;

	start = Sys_FloatTime ();
	for (i=0 ; i<iterations ; i++)
		function (rowptr, column, viewbase, screenwidth, rowcount, colcount,
				h, w, hdenominator, wdenominator, x_origin, hratio, wratio);
	elapsed = Sys_FloatTime () - start;
	*checksum = Bench486WarpTablesChecksum (rowptr, column, 512);
	bench486_sink ^= *checksum;
	return elapsed;
}

static int Bench486WarpTablesCases (byte *source)
{
	static byte *c_rows[512];
	static byte *asm_rows[512];
	static int c_columns[512];
	static int asm_columns[512];
	double c_samples[BENCH486_MEMORY_SAMPLES];
	double asm_samples[BENCH486_MEMORY_SAMPLES];
	double c_median, asm_median, delta;
	unsigned short original_cw, test_cw, c_after_cw, asm_after_cw;
	unsigned c_checksum, asm_checksum;
	int test, rounding, i, screen_w, screen_h, w, h;
	int rowcount, colcount, x_origin, failures, cases;
	int sample, iterations;
	float hratio, wratio;
	byte *viewbase;

	__asm__ __volatile__ ("fnstcw %0" : "=m" (original_cw));
	failures = 0;
	cases = 0;
	for (test=0 ; test<256 ; test++)
	{
		screen_w = 16 + (test * 37) % 85;
		screen_h = 16 + (test * 61) % 85;
		w = 16 + (test * 43) % 85;
		h = 16 + (test * 59) % 85;
		rowcount = screen_h + 6;
		colcount = screen_w + 6;
		x_origin = (test % 31) - 15;
		viewbase = source + (test % 32) * 512;

		for (rounding=0 ; rounding<4 ; rounding++)
		{
			test_cw = (original_cw & ~0x0c00) | (rounding << 10);
			__asm__ __volatile__ ("fldcw %0" : : "m" (test_cw));
			hratio = h / (float)screen_h;
			wratio = w / (float)screen_w;

			for (i=0 ; i<512 ; i++)
			{
				c_rows[i] = (byte *)source;
				asm_rows[i] = (byte *)source;
				c_columns[i] = 0x5a5a5a5a;
				asm_columns[i] = 0x5a5a5a5a;
			}
			D_WarpTables_C_Bench (c_rows, c_columns, viewbase, 320,
					rowcount, colcount, h, w, h+6, w+6,
					x_origin, hratio, wratio);
			__asm__ __volatile__ ("fnstcw %0" : "=m" (c_after_cw));

			__asm__ __volatile__ ("fldcw %0" : : "m" (test_cw));
			D_WarpBuildTables_asm486 (asm_rows, asm_columns, viewbase, 320,
					rowcount, colcount, h, w, h+6, w+6,
					x_origin, hratio, wratio);
			__asm__ __volatile__ ("fnstcw %0" : "=m" (asm_after_cw));
			cases++;

			if (c_after_cw != test_cw || asm_after_cw != test_cw)
			{
				failures++;
				bench486_memory_failures++;
				Bench486Printf ("warp-table x87 control-word FAIL case %d mode %d c 0x%x asm 0x%x expected 0x%x\n",
						test, rounding, c_after_cw, asm_after_cw, test_cw);
			}
			for (i=0 ; i<512 ; i++)
			{
				if (c_rows[i] != asm_rows[i] ||
						c_columns[i] != asm_columns[i])
				{
					failures++;
					bench486_memory_failures++;
					Bench486Printf ("warp-table parity FAIL case %d mode %d index %d row c 0x%lx asm 0x%lx column c %d asm %d\n",
							test, rounding, i, (unsigned long)c_rows[i],
							(unsigned long)asm_rows[i],
							c_columns[i], asm_columns[i]);
					break;
				}
			}
		}
		if (failures)
			break;
	}
	__asm__ __volatile__ ("fldcw %0" : : "m" (original_cw));
	Bench486Printf ("warp-screen table parity %s (%d cases; %d mismatches)\n",
			failures ? "FAIL" : "PASS", cases, failures);
	if (failures)
		return 0;

	rowcount = 206;
	colcount = 326;
	h = 200;
	w = 320;
	viewbase = source;
	hratio = h / 200.0;
	wratio = w / 320.0;
	iterations = 20;
	for (sample=0 ; sample<BENCH486_MEMORY_SAMPLES ; sample++)
	{
		if ((sample & 1) == 0)
		{
			c_samples[sample] = Bench486MeasureWarpTables (
					D_WarpTables_C_Bench, c_rows, c_columns, viewbase,
					320, rowcount, colcount, h, w, h+6, w+6, 0,
					hratio, wratio, iterations, &c_checksum);
			asm_samples[sample] = Bench486MeasureWarpTables (
					D_WarpBuildTables_asm486, asm_rows, asm_columns,
					viewbase, 320, rowcount, colcount, h, w, h+6, w+6,
					0, hratio, wratio, iterations, &asm_checksum);
		}
		else
		{
			asm_samples[sample] = Bench486MeasureWarpTables (
					D_WarpBuildTables_asm486, asm_rows, asm_columns,
					viewbase, 320, rowcount, colcount, h, w, h+6, w+6,
					0, hratio, wratio, iterations, &asm_checksum);
			c_samples[sample] = Bench486MeasureWarpTables (
					D_WarpTables_C_Bench, c_rows, c_columns, viewbase,
					320, rowcount, colcount, h, w, h+6, w+6, 0,
					hratio, wratio, iterations, &c_checksum);
		}
		if (c_checksum != asm_checksum)
		{
			bench486_memory_failures++;
			Bench486Printf ("warp-table timing checksum FAIL sample %d c %u asm %u\n",
					sample, c_checksum, asm_checksum);
			return 0;
		}
	}
	Bench486SortSamples (c_samples, BENCH486_MEMORY_SAMPLES);
	Bench486SortSamples (asm_samples, BENCH486_MEMORY_SAMPLES);
	c_median = c_samples[BENCH486_MEMORY_SAMPLES / 2];
	asm_median = asm_samples[BENCH486_MEMORY_SAMPLES / 2];
	delta = c_median > 0.0 ? (c_median - asm_median) / c_median * 100.0 : 0.0;
	Bench486Printf ("warp-screen table timing %dx%d %d iterations %d samples\n",
			320, 200, iterations, BENCH486_MEMORY_SAMPLES);
	Bench486Printf ("  c median %.6f sec samples %.6f %.6f %.6f %.6f %.6f\n",
			c_median, c_samples[0], c_samples[1], c_samples[2],
			c_samples[3], c_samples[4]);
	Bench486Printf ("  asm486 median %.6f sec samples %.6f %.6f %.6f %.6f %.6f\n",
			asm_median, asm_samples[0], asm_samples[1], asm_samples[2],
			asm_samples[3], asm_samples[4]);
	Bench486Printf ("  asm486-vs-c median %.3f percent\n", delta);
	return 1;
}

typedef void (*bench486_warp_pixels_fn_t) (byte *dest, byte **rowptr,
		int *column, int *turb, int width, int height, int rowbytes);

static double Bench486MeasureWarpPixels (bench486_warp_pixels_fn_t function,
		byte *dest, byte **rowptr, int *column, int *turb,
		int width, int height, int rowbytes, int iterations,
		unsigned *checksum)
{
	double start, elapsed;
	int i;

	start = Sys_FloatTime ();
	for (i=0 ; i<iterations ; i++)
		function (dest, rowptr, column, turb, width, height, rowbytes);
	elapsed = Sys_FloatTime () - start;
	*checksum = Bench486Checksum (dest, height * rowbytes);
	bench486_sink ^= *checksum;
	return elapsed;
}

static void Bench486WarpScreenCases (void)
{
	static byte source[256 * 512];
	static byte c_dest[80 * 16];
	static byte asm_dest[80 * 16];
	static byte *rowptr[256];
	static int column[1024];
	static int turb[512];
	double c_samples[BENCH486_MEMORY_SAMPLES];
	double asm_samples[BENCH486_MEMORY_SAMPLES];
	double c_median, asm_median, delta;
	unsigned c_checksum, asm_checksum;
	int i, width, height, rowbytes, failures, case_count;
	int sample, iterations;

	for (i=0 ; i<(int)sizeof(source) ; i++)
		source[i] = (byte)(i * 29 + i / 31 + 7);
	for (i=0 ; i<256 ; i++)
		rowptr[i] = source + i * 512;
	for (i=0 ; i<1024 ; i++)
		column[i] = (i * 19 + 11) & 511;
	for (i=0 ; i<512 ; i++)
		turb[i] = (i * 7 + 3) & 15;

	if (!Bench486WarpTablesCases (source))
		return;

	failures = 0;
	case_count = 0;
	rowbytes = 80;
	for (width=1 ; width<=64 ; width++)
	{
		for (height=1 ; height<=16 ; height++)
		{
			Q_memset (c_dest, 0xa5, sizeof(c_dest));
			Q_memset (asm_dest, 0xa5, sizeof(asm_dest));
			D_WarpPixels_C_Bench (c_dest, rowptr, column, turb,
					width, height, rowbytes);
			D_WarpPixels_asm486 (asm_dest, rowptr, column, turb,
					width, height, rowbytes);
			for (i=0 ; i<(int)sizeof(c_dest) ; i++)
			{
				if (c_dest[i] != asm_dest[i])
				{
					failures++;
					bench486_memory_failures++;
					Bench486Printf ("warp-screen parity FAIL width %d height %d byte %d c %u asm %u\n",
							width, height, i, c_dest[i], asm_dest[i]);
					break;
				}
			}
			case_count++;
		}
	}
	Bench486Printf ("warp-screen assembly parity %s (%d cases; %d mismatches)\n",
			failures ? "FAIL" : "PASS", case_count, failures);
	if (failures)
		return;

	iterations = 20;
	for (sample=0 ; sample<BENCH486_MEMORY_SAMPLES ; sample++)
	{
		if ((sample & 1) == 0)
		{
			c_samples[sample] = Bench486MeasureWarpPixels (
					D_WarpPixels_C_Bench, source, rowptr, column,
					turb, 320, 200, 320, iterations, &c_checksum);
			asm_samples[sample] = Bench486MeasureWarpPixels (
					D_WarpPixels_asm486, source, rowptr, column,
					turb, 320, 200, 320, iterations, &asm_checksum);
		}
		else
		{
			asm_samples[sample] = Bench486MeasureWarpPixels (
					D_WarpPixels_asm486, source, rowptr, column,
					turb, 320, 200, 320, iterations, &asm_checksum);
			c_samples[sample] = Bench486MeasureWarpPixels (
					D_WarpPixels_C_Bench, source, rowptr, column,
					turb, 320, 200, 320, iterations, &c_checksum);
		}
		if (c_checksum != asm_checksum)
		{
			bench486_memory_failures++;
			Bench486Printf ("warp-screen timing checksum FAIL sample %d c %u asm %u\n",
					sample, c_checksum, asm_checksum);
			return;
		}
	}

	Bench486SortSamples (c_samples, BENCH486_MEMORY_SAMPLES);
	Bench486SortSamples (asm_samples, BENCH486_MEMORY_SAMPLES);
	c_median = c_samples[BENCH486_MEMORY_SAMPLES / 2];
	asm_median = asm_samples[BENCH486_MEMORY_SAMPLES / 2];
	delta = c_median > 0.0 ? (c_median - asm_median) / c_median * 100.0 : 0.0;
	Bench486Printf ("warp-screen timing 320x200 %d iterations %d samples %d\n",
			iterations, BENCH486_MEMORY_SAMPLES);
	Bench486Printf ("  c median %.6f sec samples %.6f %.6f %.6f %.6f %.6f\n",
			c_median, c_samples[0], c_samples[1], c_samples[2],
			c_samples[3], c_samples[4]);
	Bench486Printf ("  asm486 median %.6f sec samples %.6f %.6f %.6f %.6f %.6f\n",
			asm_median, asm_samples[0], asm_samples[1], asm_samples[2],
			asm_samples[3], asm_samples[4]);
	Bench486Printf ("  asm486-vs-c median %.3f percent\n", delta);
}
#endif

#ifdef ASM486_SOLID_SURFACE
#define BENCH486_SOLID_SURFACE_ROWS 8
#define BENCH486_SOLID_SURFACE_WIDTH 128
#define BENCH486_SOLID_SURFACE_SPANS 12
#define BENCH486_SOLID_SURFACE_ITERATIONS 100000

typedef void (*bench486_solid_surface_fn_t)(surf_t *surf, int color);

static double Bench486MeasureSolidSurface (bench486_solid_surface_fn_t function,
		surf_t *surface, int color, byte *buffer, int iterations,
		unsigned *checksum)
{
	double start, elapsed;
	unsigned sum;
	int i;

	start = Sys_FloatTime ();
	for (i=0 ; i<iterations ; i++)
		function (surface, color);
	elapsed = Sys_FloatTime () - start;
	sum = 0;
	for (i=0 ; i<BENCH486_SOLID_SURFACE_ROWS * BENCH486_SOLID_SURFACE_WIDTH;
			i += 17)
		sum += buffer[i];
	*checksum = sum;
	bench486_sink ^= sum;
	return elapsed;
}

static void Bench486SolidSurfaceCases (void)
{
	static byte c_pixels[BENCH486_SOLID_SURFACE_ROWS *
			BENCH486_SOLID_SURFACE_WIDTH];
	static byte asm_pixels[BENCH486_SOLID_SURFACE_ROWS *
			BENCH486_SOLID_SURFACE_WIDTH];
	static pixel_t *saved_rows[BENCH486_SOLID_SURFACE_ROWS];
	static espan_t spans[BENCH486_SOLID_SURFACE_SPANS];
	static surf_t surface;
	static int starts[BENCH486_SOLID_SURFACE_SPANS] =
			{1, 4, 10, 18, 26, 33, 45, 51, 60, 64, 89, 117};
	static int counts[BENCH486_SOLID_SURFACE_SPANS] =
			{1, 2, 7, 8, 9, 15, 16, 17, 31, 64, 0, -1};
	static int colors[4] = {0, 1, 0x123456ab, -1};
	double c_samples[BENCH486_MEMORY_SAMPLES];
	double asm_samples[BENCH486_MEMORY_SAMPLES];
	double c_median, asm_median, delta;
	unsigned c_checksum, asm_checksum;
	int i, row, color_index, sample, mismatch;

	for (row=0 ; row<BENCH486_SOLID_SURFACE_ROWS ; row++)
	{
		saved_rows[row] = viewspantable[row];
		viewspantable[row] = (pixel_t *)c_pixels +
				row * BENCH486_SOLID_SURFACE_WIDTH;
	}
	for (i=0 ; i<BENCH486_SOLID_SURFACE_SPANS ; i++)
	{
		spans[i].u = starts[i];
		spans[i].v = i % BENCH486_SOLID_SURFACE_ROWS;
		spans[i].count = counts[i];
		spans[i].pnext = i + 1 < BENCH486_SOLID_SURFACE_SPANS ?
				&spans[i + 1] : NULL;
	}
	surface.spans = spans;

	mismatch = 0;
	for (color_index=0 ; color_index<4 ; color_index++)
	{
		for (i=0 ; i<sizeof(c_pixels) ; i++)
			c_pixels[i] = (byte)(i * 37 + color_index * 19 + 0x53);
		Q_memcpy (asm_pixels, c_pixels, sizeof(c_pixels));
		for (row=0 ; row<BENCH486_SOLID_SURFACE_ROWS ; row++)
			viewspantable[row] = (pixel_t *)c_pixels +
					row * BENCH486_SOLID_SURFACE_WIDTH;
		D_DrawSolidSurface_C (&surface, colors[color_index]);
		for (row=0 ; row<BENCH486_SOLID_SURFACE_ROWS ; row++)
			viewspantable[row] = (pixel_t *)asm_pixels +
					row * BENCH486_SOLID_SURFACE_WIDTH;
		D_DrawSolidSurface (&surface, colors[color_index]);
		if (Q_memcmp (c_pixels, asm_pixels, sizeof(c_pixels)) != 0)
		{
			bench486_memory_failures++;
			mismatch++;
			Bench486Printf ("solid-surface span parity FAIL color case %d\n",
					color_index);
		}
	}
	Bench486Printf ("solid-surface span parity %s (48 span operations; %d mismatches)\n",
			mismatch ? "FAIL" : "PASS", mismatch);

	for (i=0 ; i<sizeof(c_pixels) ; i++)
	{
		c_pixels[i] = (byte)(i * 11 + 0x31);
		asm_pixels[i] = c_pixels[i];
	}
	for (row=0 ; row<BENCH486_SOLID_SURFACE_ROWS ; row++)
		viewspantable[row] = (pixel_t *)c_pixels +
				row * BENCH486_SOLID_SURFACE_WIDTH;
	for (sample=0 ; sample<BENCH486_MEMORY_SAMPLES ; sample++)
	{
		if ((sample & 1) == 0)
		{
			c_samples[sample] = Bench486MeasureSolidSurface (
					D_DrawSolidSurface_C, &surface, 0x5a,
					c_pixels, BENCH486_SOLID_SURFACE_ITERATIONS,
					&c_checksum);
			for (row=0 ; row<BENCH486_SOLID_SURFACE_ROWS ; row++)
				viewspantable[row] = (pixel_t *)asm_pixels +
						row * BENCH486_SOLID_SURFACE_WIDTH;
			asm_samples[sample] = Bench486MeasureSolidSurface (
					D_DrawSolidSurface, &surface, 0x5a,
					asm_pixels, BENCH486_SOLID_SURFACE_ITERATIONS,
					&asm_checksum);
		}
		else
		{
			for (row=0 ; row<BENCH486_SOLID_SURFACE_ROWS ; row++)
				viewspantable[row] = (pixel_t *)asm_pixels +
						row * BENCH486_SOLID_SURFACE_WIDTH;
			asm_samples[sample] = Bench486MeasureSolidSurface (
					D_DrawSolidSurface, &surface, 0x5a,
					asm_pixels, BENCH486_SOLID_SURFACE_ITERATIONS,
					&asm_checksum);
			for (row=0 ; row<BENCH486_SOLID_SURFACE_ROWS ; row++)
				viewspantable[row] = (pixel_t *)c_pixels +
						row * BENCH486_SOLID_SURFACE_WIDTH;
			c_samples[sample] = Bench486MeasureSolidSurface (
					D_DrawSolidSurface_C, &surface, 0x5a,
					c_pixels, BENCH486_SOLID_SURFACE_ITERATIONS,
					&c_checksum);
		}
		if (c_checksum != asm_checksum)
		{
			bench486_memory_failures++;
			Bench486Printf ("solid-surface timing checksum FAIL sample %d\n",
					sample);
			break;
		}
	}

	mismatch = Q_memcmp (c_pixels, asm_pixels, sizeof(c_pixels)) != 0;
	if (mismatch)
	{
		bench486_memory_failures++;
		Bench486Printf ("solid-surface timing framebuffer FAIL\n");
	}
	else if (!bench486_memory_failures)
	{
		Bench486SortSamples (c_samples, BENCH486_MEMORY_SAMPLES);
		Bench486SortSamples (asm_samples, BENCH486_MEMORY_SAMPLES);
		c_median = c_samples[BENCH486_MEMORY_SAMPLES / 2];
		asm_median = asm_samples[BENCH486_MEMORY_SAMPLES / 2];
		delta = c_median > 0.0 ?
				(c_median - asm_median) / c_median * 100.0 : 0.0;
		Bench486Printf ("solid-surface timing %d calls/sample (%d spans)\n",
				BENCH486_SOLID_SURFACE_ITERATIONS,
				BENCH486_SOLID_SURFACE_SPANS);
		Bench486Printf ("  c median %.6f sec samples %.6f %.6f %.6f %.6f %.6f\n",
				c_median, c_samples[0], c_samples[1], c_samples[2],
				c_samples[3], c_samples[4]);
		Bench486Printf ("  asm486 median %.6f sec samples %.6f %.6f %.6f %.6f %.6f\n",
				asm_median, asm_samples[0], asm_samples[1], asm_samples[2],
				asm_samples[3], asm_samples[4]);
		Bench486Printf ("  asm486-vs-c median %.3f percent\n", delta);
	}

	for (row=0 ; row<BENCH486_SOLID_SURFACE_ROWS ; row++)
		viewspantable[row] = saved_rows[row];
}
#endif

static void Bench486RenderPolys_f (void)
{
	int requested;

	if (Cmd_Argc () != 2)
	{
		Con_Printf ("usage: bench486_renderpolys 0|1\n");
		return;
	}

	requested = (Q_atoi (Cmd_Argv (1)) != 0);
	r_drawpolys = false;
	if (requested)
	{
		Con_Printf ("bench486_renderpolys: unavailable in the DOS span renderer; keeping edge scanning enabled\n");
		return;
	}

	Con_Printf ("bench486_renderpolys: 0\n");
}

static void Bench486_f (void)
{
	bench486_report_handle = Sys_FileOpenWrite ("bench486.txt");
	if (bench486_report_handle == -1)
		Con_Printf ("bench486: could not create bench486.txt\n");

	Bench486Printf ("486 benchmark begin\n");
	if (COM_CheckParm ("-benchplayertranslation"))
	{
		int translation_failures;

#ifdef ASM486_PLAYER_TRANSLATION_FIXTURE
		translation_failures = Bench486PlayerTranslationCases ();
		bench486_memory_failures += translation_failures != 0;
		Bench486Printf ("player translation C/ASM tables and ABI %s failure mask 0x%x\n",
				translation_failures ? "FAIL" : "PASS",
				translation_failures);
#else
		bench486_memory_failures++;
		Bench486Printf ("player translation fixture requires PlayerTranslationImplementation=asm-fixture\n");
#endif
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
	if (COM_CheckParm ("-benchvesapalette"))
	{
#if defined(ASM486_VESA_PALETTE_FIXTURE)
		int vesa_palette_failures;
		vesa_palette_failures = Bench486VesaPaletteCases ();
		bench486_memory_failures += vesa_palette_failures != 0;
		Bench486Printf ("VESA C/ASM palette conversion and ABI %s failure mask 0x%x\n",
				vesa_palette_failures ? "FAIL" : "PASS", vesa_palette_failures);
#else
		bench486_memory_failures++;
		Bench486Printf ("VESA palette fixture requires VesaPaletteImplementation=asm-fixture\n");
#endif
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
	if (COM_CheckParm ("-benchvesadefaultmode"))
	{
#if defined(ASM486_VESA_DEFAULT_MODE_FIXTURE)
		int vesa_default_mode_failures;
		vesa_default_mode_failures = Bench486VesaDefaultModeCases ();
		bench486_memory_failures += vesa_default_mode_failures != 0;
		Bench486Printf ("VESA default-mode selection and ABI %s failure mask 0x%x\n",
				vesa_default_mode_failures ? "FAIL" : "PASS", vesa_default_mode_failures);
#else
		bench486_memory_failures++;
		Bench486Printf ("VESA default-mode fixture requires VesaDefaultModeImplementation=asm-fixture\n");
#endif
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
	if (COM_CheckParm ("-benchvesalifecycle"))
	{
#if defined(ASM486_VESA_LIFECYCLE_FIXTURE)
		int vesa_lifecycle_failures;
		vesa_lifecycle_failures = Bench486VesaLifecycleCases ();
		bench486_memory_failures += vesa_lifecycle_failures != 0;
		Bench486Printf ("VESA lifecycle parity %s failure count %u\n",
				vesa_lifecycle_failures ? "FAIL" : "PASS",
				vesa_lifecycle_failures);
#else
		bench486_memory_failures++;
		Bench486Printf ("VESA lifecycle fixture requires VesaLifecycleImplementation=asm-fixture\n");
#endif
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
	if (COM_CheckParm ("-benchvesawait"))
	{
#if defined(ASM486_VESA_WAIT_FIXTURE)
		int vesa_wait_failures;
		vesa_wait_failures = Bench486VesaWaitCases ();
		bench486_memory_failures += vesa_wait_failures != 0;
		Bench486Printf ("VESA wait gates and retrace-port C/ASM parity %s (%u exact cases, failure mask 0x%x)\n",
				vesa_wait_failures ? "FAIL" : "PASS", 36U,
				vesa_wait_failures);
#else
		bench486_memory_failures++;
		Bench486Printf ("VESA wait fixture requires VesaWaitImplementation=asm-fixture\n");
#endif
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
	if (COM_CheckParm ("-benchmemory"))
	{
		Bench486MemoryCases ();
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
	if (COM_CheckParm ("-benchforwardspans"))
	{
		Bench486ForwardSpansCases ();
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
	if (COM_CheckParm ("-benchzspans"))
	{
		Bench486ZSpansCases ();
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
	if (COM_CheckParm ("-benchlinegraph"))
	{
#ifdef ASM486_LINE_GRAPH
		Bench486LineGraphCases ();
#else
		bench486_memory_failures++;
		Bench486Printf ("line-graph fixture requires -LineGraphImplementation asm\n");
#endif
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
	if (COM_CheckParm ("-benchtimegraph"))
	{
		Bench486TimeGraphCases ();
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
	if (COM_CheckParm ("-benchsolidsurface"))
	{
#ifdef ASM486_SOLID_SURFACE
		Bench486SolidSurfaceCases ();
#else
		bench486_memory_failures++;
		Bench486Printf ("solid-surface requires -SolidSurfaceImplementation asm\n");
#endif
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
	if (COM_CheckParm ("-benchwarpscreen"))
	{
#ifdef ASM486_WARP_SCREEN
		Bench486WarpScreenCases ();
#else
		bench486_memory_failures++;
		Bench486Printf ("warp-screen requires -WarpScreenImplementation asm\n");
#endif
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
	if (COM_CheckParm ("-benchskyspan"))
	{
#ifdef ASM486_SKY_SPAN
		Bench486SkySpanCases ();
		Bench486SkyScanCases ();
#else
		bench486_memory_failures++;
		Bench486Printf ("sky-span requires -SkySpanImplementation asm\n");
#endif
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
	if (COM_CheckParm ("-benchzpoint"))
	{
#ifdef ASM486_ZPOINT
		Bench486ZPointCases ();
#else
		bench486_memory_failures++;
		Bench486Printf ("zpoint requires -ZPointImplementation asm\n");
#endif
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
	if (COM_CheckParm ("-benchfillrect"))
	{
		Bench486FillCase ();
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
	if (COM_CheckParm ("-benchfidelity"))
	{
		Bench486Printf ("fidelity probes establish whether this emulator prices 486\n");
		Bench486Printf ("x87 latency, L1 residency, and cache-set aliasing\n");
		Bench486FidelityCases ();
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
	if (COM_CheckParm ("-benchaliasproject"))
	{
		Bench486Printf ("alias-project experiment compares the C projection helper\n");
		Bench486Printf ("with one x87 control-word transition per ASM call\n");
		Bench486AliasProjectCases ();
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
	if (COM_CheckParm ("-benchaliassetuplighting"))
	{
		Bench486Printf ("alias lighting setup compares C and 486 x87 arithmetic\n");
		Bench486AliasSetupLightingCases ();
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
	if (COM_CheckParm ("-benchaliassetupframe"))
	{
		Bench486Printf ("alias frame setup compares C and 486 interval selection\n");
		Bench486AliasSetupFrameCases ();
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
	if (COM_CheckParm ("-benchaliassetupskin"))
	{
		Bench486Printf ("alias skin setup compares C and 486 interval selection\n");
		Bench486AliasSetupSkinCases ();
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
	if (COM_CheckParm ("-benchaliasgradients"))
	{
		Bench486Printf ("alias triangle gradient setup compares C and 486 x87 paths\n");
		Bench486AliasGradientCases ();
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
	if (COM_CheckParm ("-benchaliaslinescan"))
	{
		Bench486Printf ("alias triangle line-scan setup compares C and 486 integer paths\n");
		Bench486AliasLineScanCases ();
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
	if (COM_CheckParm ("-benchaliasedgetable"))
	{
		Bench486Printf ("alias triangle edge-table selection compares C and 486 integer paths\n");
		Bench486AliasEdgeTableCases ();
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
	if (COM_CheckParm ("-benchaliasskintable"))
	{
		Bench486Printf ("alias skin-table cache compares the C and 486 pointer rebuild paths\n");
		Bench486AliasSkinTableCases ();
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
	if (COM_CheckParm ("-benchaliasbboxproject"))
	{
		Bench486Printf ("alias-bbox-project experiment compares the C projection loop\n");
		Bench486Printf ("with a register-held 486 x87 projection helper\n");
		Bench486AliasBBoxProjectCases ();
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
	if (COM_CheckParm ("-benchspritebeam"))
	{
		Bench486Printf ("sprite-beam translation compares C and 486 x87 paths\n");
		Bench486SpriteBeamCases ();
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
	if (COM_CheckParm ("-benchspriteclip"))
	{
		Bench486Printf ("sprite-face clipping compares C and 486 x87 paths\n");
		Bench486SpriteClipCases ();
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
	if (COM_CheckParm ("-benchspriteframe"))
	{
		Bench486Printf ("sprite-frame selection compares C and 486 x87 paths\n");
		Bench486SpriteFrameCases ();
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
	if (COM_CheckParm ("-benchspritegradient"))
	{
		Bench486Printf ("sprite texture gradients compare C and 486 x87 paths\n");
		Bench486SpriteGradientCases ();
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
	if (COM_CheckParm ("-benchspritescanleft"))
	{
		Bench486Printf ("sprite left-edge spans compare C and 486 x87 paths\n");
		Bench486SpriteScanLeftCases ();
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
	if (COM_CheckParm ("-benchspritescanright"))
	{
		Bench486Printf ("sprite right-edge spans compare C and 486 x87 paths\n");
		Bench486SpriteScanRightCases ();
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
	if (COM_CheckParm ("-benchspritedraw"))
	{
		Bench486Printf ("sprite orchestration compares C and 486 assembly framebuffers\n");
		Bench486SpriteDrawCases ();
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
	if (COM_CheckParm ("-benchspritesetup"))
	{
		Bench486Printf ("sprite setup compares C and 486 assembly projection and framebuffers\n");
		Bench486SpriteSetupCases ();
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}

#ifdef ASM486_PUBLIC_BINDINGS
    if (COM_CheckParm ("-benchpublicbindings"))
    {
        Bench486PublicBindingsCases ();
        Bench486AliasGradientCases ();
        Bench486AliasLineScanCases ();
        Bench486AliasEdgeTableCases ();
        Bench486AliasSkinTableCases ();
        Bench486SpriteBeamCases ();
        Bench486SpriteClipCases ();
        Bench486SpriteScanLeftCases ();
        Bench486SpriteScanRightCases ();
        Bench486SpriteSetupCases ();
        Bench486RendererMathCases ();
        Bench486SpriteOrientationCases ();
#ifdef ASM486_TEXTURE_ANIMATION
        Bench486TextureAnimationEntryCases ();
#endif
        Bench486Printf ("486 benchmark correctness %s\n",bench486_memory_failures ? "FAIL":"PASS");
        if (bench486_report_handle != -1) { Sys_FileClose (bench486_report_handle); bench486_report_handle=-1; }
        if (COM_CheckParm ("-benchexit")) Sys_Quit ();
        return;
    }
#endif

	if (COM_CheckParm ("-benchaliascontrol"))
	{
		Bench486AliasControlCases ();
		Bench486Printf ("486 benchmark correctness %s\n", bench486_memory_failures ? "FAIL" : "PASS");
		if (bench486_report_handle != -1) { Sys_FileClose(bench486_report_handle); bench486_report_handle = -1; }
		if (COM_CheckParm ("-benchexit")) Sys_Quit ();
		return;
	}
	if (COM_CheckParm ("-benchaliasmodelload"))
	{
#if defined(ASM486_ALIAS_MODEL_LOAD_FIXTURE)
		Bench486AliasModelLoadCases ();
#else
		bench486_memory_failures++;
		Bench486ReportPrintf ("alias model load fixture is not enabled\n");
#endif
		Bench486ReportPrintf ("486 benchmark correctness %s\n", bench486_memory_failures ? "FAIL" : "PASS");
		if (bench486_report_handle != -1) { Sys_FileClose (bench486_report_handle); bench486_report_handle = -1; }
		if (COM_CheckParm ("-benchexit")) Sys_Quit ();
		return;
	}
	if (COM_CheckParm ("-benchsbar_draw"))
	{
#if defined(ASM486_SBAR_DRAW_FIXTURE)
		Bench486SbarDrawCases ();
#else
		bench486_memory_failures++;
		Bench486ReportPrintf ("sbar draw fixture is not enabled\n");
#endif
		Bench486ReportPrintf ("486 benchmark correctness %s\n", bench486_memory_failures ? "FAIL" : "PASS");
		if (bench486_report_handle != -1) { Sys_FileClose (bench486_report_handle); bench486_report_handle = -1; }
		if (COM_CheckParm ("-benchexit")) Sys_Quit ();
		return;
	}
	if (COM_CheckParm ("-benchaliasstats"))
	{
#ifdef ASM486_ALIAS_STATS
		Bench486AliasStatsCases ();
#else
		bench486_memory_failures++;
		Bench486Printf ("alias-stats fixture requires -AliasStatsImplementation asm\n");
#endif
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
	if (COM_CheckParm ("-benchprinttimes"))
	{
#ifdef ASM486_PRINT_TIMES
		Bench486PrintTimesCases ();
		Bench486PrintDSpeedsCases ();
#else
		bench486_memory_failures++;
		Bench486Printf ("print-times fixture requires -PrintTimesImplementation asm\n");
#endif
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
	if (COM_CheckParm ("-benchrockettrail"))
	{
#ifdef ASM486_ROCKET_TRAIL
		if (!COM_CheckParm ("-benchexit"))
		{
			bench486_memory_failures++;
			Bench486Printf ("rocket-trail fixture requires -benchexit to isolate libc RNG state\n");
			return;
		}
		Bench486RocketTrailCases ();
#else
		bench486_memory_failures++;
		Bench486Printf ("rocket-trail fixture requires -RocketTrailImplementation asm\n");
#endif
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
	if (COM_CheckParm ("-benchparticleexplosion2"))
	{
#ifdef ASM486_PARTICLE_EXPLOSION2
		Bench486ParticleExplosion2Cases ();
#else
		bench486_memory_failures++;
		Bench486Printf ("particle-explosion2 fixture requires -ParticleExplosion2Implementation asm\n");
#endif
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
	if (COM_CheckParm ("-benchparticleexplosion"))
	{
#ifdef ASM486_PARTICLE_EXPLOSION
		Bench486ParticleExplosionCases ();
#else
		bench486_memory_failures++;
		Bench486Printf ("particle-explosion fixture requires -ParticleExplosionImplementation asm\n");
#endif
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
	if (COM_CheckParm ("-benchrunparticleeffect"))
	{
#ifdef ASM486_RUN_PARTICLE_EFFECT
		if (!COM_CheckParm ("-benchexit"))
		{
			bench486_memory_failures++;
			Bench486Printf ("run-particle-effect fixture requires -benchexit to isolate libc RNG state\n");
		}
		else
			Bench486RunParticleEffectCases ();
#else
		bench486_memory_failures++;
		Bench486Printf ("run-particle-effect fixture requires -RunParticleEffectImplementation asm\n");
#endif
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
	if (COM_CheckParm ("-benchparseparticleeffect"))
	{
#ifdef ASM486_PARSE_PARTICLE_EFFECT
#ifdef ASM486_RUN_PARTICLE_EFFECT
		bench486_memory_failures++;
		Bench486Printf ("parse-particle-effect fixture requires -RunParticleEffectImplementation c so both parser paths use the C emitter\n");
#else
		Bench486ParseParticleEffectCases ();
#endif
#else
		bench486_memory_failures++;
		Bench486Printf ("parse-particle-effect fixture requires -ParseParticleEffectImplementation asm\n");
#endif
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
	if (COM_CheckParm ("-benchefragstore"))
	{
#ifdef ASM486_EFRAG_STORE
		Bench486EfragStoreCases ();
#else
		bench486_memory_failures++;
		Bench486Printf ("efrag-store fixture requires -EfragStoreImplementation asm\n");
#endif
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
	if (COM_CheckParm ("-benchentityparticles"))
	{
#ifdef ASM486_ENTITY_PARTICLES
		if (!COM_CheckParm ("-benchexit"))
		{
			bench486_memory_failures++;
			Bench486Printf ("entity-particles fixture requires -benchexit to isolate libc RNG state\n");
		}
		else
			Bench486EntityParticlesCases ();
#else
		bench486_memory_failures++;
		Bench486Printf ("entity-particles fixture requires -EntityParticlesImplementation asm\n");
#endif
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
	if (COM_CheckParm ("-benchblobexplosion"))
	{
#ifdef ASM486_BLOB_EXPLOSION
		if (!COM_CheckParm ("-benchexit"))
		{
			bench486_memory_failures++;
			Bench486Printf ("blob-explosion fixture requires -benchexit to isolate libc RNG state\n");
		}
		else
			Bench486BlobExplosionCases ();
#else
		bench486_memory_failures++;
		Bench486Printf ("blob-explosion fixture requires -BlobExplosionImplementation asm\n");
#endif
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
	if (COM_CheckParm ("-benchlavasplash"))
	{
#ifdef ASM486_LAVA_SPLASH
		if (!COM_CheckParm ("-benchexit"))
		{
			bench486_memory_failures++;
			Bench486Printf ("lava-splash fixture requires -benchexit to isolate libc RNG state\n");
		}
		else
			Bench486LavaSplashCases ();
#else
		bench486_memory_failures++;
		Bench486Printf ("lava-splash fixture requires -LavaSplashImplementation asm\n");
#endif
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
	if (COM_CheckParm ("-benchteleportsplash"))
	{
#ifdef ASM486_TELEPORT_SPLASH
		if (!COM_CheckParm ("-benchexit"))
		{
			bench486_memory_failures++;
			Bench486Printf ("teleport-splash fixture requires -benchexit to isolate libc RNG state\n");
		}
		else
			Bench486TeleportSplashCases ();
#else
		bench486_memory_failures++;
		Bench486Printf ("teleport-splash fixture requires -TeleportSplashImplementation asm\n");
#endif
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
	if (COM_CheckParm ("-benchtransformplane"))
	{
#ifdef ASM486_TRANSFORM_PLANE
		Bench486TransformPlaneCases ();
#else
		bench486_memory_failures++;
		Bench486Printf ("transform-plane fixture requires -TransformPlaneImplementation asm\n");
#endif
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
	if (COM_CheckParm ("-benchvparsedamage"))
	{
#ifdef ASM486_V_PARSE_DAMAGE
		Bench486VParseDamageCases ();
#else
		bench486_memory_failures++;
		Bench486Printf ("v-parse-damage fixture requires ASM486_V_PARSE_DAMAGE\n");
#endif
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
	if (COM_CheckParm ("-benchworldcontrol"))
	{
		Bench486WorldControlCases ();
		Bench486Printf ("486 benchmark correctness %s\n", bench486_memory_failures ? "FAIL" : "PASS");
		if (bench486_report_handle != -1) { Sys_FileClose(bench486_report_handle); bench486_report_handle = -1; }
		if (COM_CheckParm ("-benchexit")) Sys_Quit ();
		return;
	}

	if (COM_CheckParm ("-benchchase"))
	{
		Bench486ChaseCases ();
		Bench486Printf ("486 benchmark correctness %s\n", bench486_memory_failures ? "FAIL" : "PASS");
		if (bench486_report_handle != -1) { Sys_FileClose(bench486_report_handle); bench486_report_handle = -1; }
		if (COM_CheckParm ("-benchexit")) Sys_Quit ();
		return;
	}

	if (COM_CheckParm ("-benchhullcheck"))
	{
		Bench486HullCheckCases ();
		Bench486Printf ("486 benchmark correctness %s\n", bench486_memory_failures ? "FAIL" : "PASS");
		if (bench486_report_handle != -1) { Sys_FileClose(bench486_report_handle); bench486_report_handle = -1; }
		if (COM_CheckParm ("-benchexit")) Sys_Quit ();
		return;
	}

	if (COM_CheckParm ("-benchdrawing"))
	{
		Bench486DrawingCases ();
		Bench486Printf ("486 benchmark correctness %s\n", bench486_memory_failures ? "FAIL" : "PASS");
		if (bench486_report_handle != -1) { Sys_FileClose(bench486_report_handle); bench486_report_handle = -1; }
		if (COM_CheckParm ("-benchexit")) Sys_Quit ();
		return;
	}

	if (COM_CheckParm ("-benchsbarprimitives"))
	{
#ifdef ASM486_SBAR_PRIMITIVES
		Bench486SbarPrimitiveCases ();
#else
		bench486_memory_failures++;
		Bench486Printf ("sbar primitive fixture requires -SbarPrimitiveImplementation asm\n");
#endif
		Bench486Printf ("486 benchmark correctness %s\n", bench486_memory_failures ? "FAIL" : "PASS");
		if (bench486_report_handle != -1) { Sys_FileClose(bench486_report_handle); bench486_report_handle = -1; }
		if (COM_CheckParm ("-benchexit")) Sys_Quit ();
		return;
	}
	if (COM_CheckParm ("-benchsbarfrags"))
	{
#if defined(ASM486_SBAR_FRAGS_FIXTURE)
		Bench486SbarFragsCases ();
#else
		bench486_memory_failures++;
		Bench486Printf ("sbar frags fixture requires SbarFragsImplementation=asm-fixture\n");
#endif
		Bench486Printf ("486 benchmark correctness %s\n", bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
	if (COM_CheckParm ("-benchcachecheck"))
	{
#if defined(ASM486_CACHE_CHECK_FIXTURE)
		int cache_check_failures;
		cache_check_failures = Bench486CacheCheckCases ();
		bench486_memory_failures += cache_check_failures != 0;
		Bench486Printf ("cache check C/ASM LRU cases %s failure mask 0x%x\n",
				cache_check_failures ? "FAIL" : "PASS", cache_check_failures);
#else
		bench486_memory_failures++;
		Bench486Printf ("cache check fixture requires CacheCheckImplementation=asm-fixture\n");
#endif
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
	if (COM_CheckParm ("-benchcachetryalloc"))
	{
#if defined(ASM486_CACHE_TRY_ALLOC_FIXTURE)
		int cache_tryalloc_failures;
		cache_tryalloc_failures = Bench486CacheTryAllocCases ();
		bench486_memory_failures += cache_tryalloc_failures != 0;
		Bench486Printf ("cache tryalloc C/ASM allocation cases %s failure mask 0x%x\n",
				cache_tryalloc_failures ? "FAIL" : "PASS", cache_tryalloc_failures);
#else
		bench486_memory_failures++;
		Bench486Printf ("cache tryalloc fixture requires CacheTryAllocImplementation=asm-fixture\n");
#endif
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
	if (COM_CheckParm ("-benchcachemove"))
	{
#if defined(ASM486_CACHE_MOVE_FIXTURE)
		int cache_move_failures;
		cache_move_failures = Bench486CacheMoveCases ();
		bench486_memory_failures += cache_move_failures != 0;
		Bench486Printf ("cache move C/ASM relocation cases %s failure mask 0x%x\n",
				cache_move_failures ? "FAIL" : "PASS", cache_move_failures);
#else
		bench486_memory_failures++;
		Bench486Printf ("cache move fixture requires CacheMoveImplementation=asm-fixture\n");
#endif
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
	if (COM_CheckParm ("-benchcachealloc"))
	{
#if defined(ASM486_CACHE_ALLOC_FIXTURE)
		int cache_alloc_failures;
		cache_alloc_failures = Bench486CacheAllocCases ();
		bench486_memory_failures += cache_alloc_failures != 0;
		Bench486Printf ("cache alloc C/ASM empty/eviction cases %s failure mask 0x%x\n",
				cache_alloc_failures ? "FAIL" : "PASS", cache_alloc_failures);
#else
		bench486_memory_failures++;
		Bench486Printf ("cache alloc fixture requires CacheAllocImplementation=asm-fixture\n");
#endif
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
	if (COM_CheckParm ("-benchcachefree"))
	{
#if defined(ASM486_CACHE_FREE_FIXTURE)
		int cache_free_failures;
		cache_free_failures = Bench486CacheFreeCases ();
		bench486_memory_failures += cache_free_failures != 0;
		Bench486Printf ("cache free C/ASM address/LRU cases %s failure mask 0x%x\n",
				cache_free_failures ? "FAIL" : "PASS", cache_free_failures);
#else
		bench486_memory_failures++;
		Bench486Printf ("cache free fixture requires CacheFreeImplementation=asm-fixture\n");
#endif
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
	if (COM_CheckParm ("-benchcachefreehigh"))
	{
#if defined(ASM486_CACHE_FREE_HIGH_FIXTURE)
		int cache_free_high_failures;
		cache_free_high_failures = Bench486CacheFreeHighCases ();
		bench486_memory_failures += cache_free_high_failures != 0;
		Bench486Printf ("cache free-high C/ASM hunk-boundary cases %s failure mask 0x%x\n",
				cache_free_high_failures ? "FAIL" : "PASS", cache_free_high_failures);
#else
		bench486_memory_failures++;
		Bench486Printf ("cache free-high fixture requires CacheFreeHighImplementation=asm-fixture\n");
#endif
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
	if (COM_CheckParm ("-benchcachefreelow"))
	{
#if defined(ASM486_CACHE_FREE_LOW_FIXTURE)
		int cache_free_low_failures;
		cache_free_low_failures = Bench486CacheFreeLowCases ();
		bench486_memory_failures += cache_free_low_failures != 0;
		Bench486Printf ("cache free-low C/ASM hunk-boundary cases %s failure mask 0x%x\n",
				cache_free_low_failures ? "FAIL" : "PASS", cache_free_low_failures);
#else
		bench486_memory_failures++;
		Bench486Printf ("cache free-low fixture requires CacheFreeLowImplementation=asm-fixture\n");
#endif
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
	if (COM_CheckParm ("-benchhunkmarkfree"))
	{
#if defined(ASM486_HUNK_MARK_RELEASE_FIXTURE)
		int hunk_mark_free_failures;
		hunk_mark_free_failures = Bench486HunkMarkFreeCases ();
		bench486_memory_failures += hunk_mark_free_failures != 0;
		Bench486Printf ("hunk low/high mark-management C/ASM cases %s failure mask 0x%x\n",
				hunk_mark_free_failures ? "FAIL" : "PASS", hunk_mark_free_failures);
#else
		bench486_memory_failures++;
		Bench486Printf ("hunk free-mark fixture requires HunkMarkReleaseImplementation=asm-fixture\n");
#endif
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
	if (COM_CheckParm ("-benchvgaswap"))
	{
#if defined(ASM486_VGA_PRESENTATION_FIXTURE)
		int vga_presentation_failures;
		vga_presentation_failures = Bench486VgaPresentationCases ();
		bench486_memory_failures += vga_presentation_failures != 0;
		Bench486Printf ("VGA C/ASM linear, planar, and retrace presentation cases %s failure mask 0x%x\n",
				vga_presentation_failures ? "FAIL" : "PASS",
				vga_presentation_failures);
#else
		bench486_memory_failures++;
		Bench486Printf ("VGA presentation fixture requires VgaPresentationImplementation=asm-fixture\n");
#endif
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
	if (COM_CheckParm ("-benchvesacopy"))
	{
#if defined(ASM486_VESA_COPY_RECTS_FIXTURE)
		int vesa_copy_failures;
		vesa_copy_failures = Bench486VesaCopyRectsCases ();
		bench486_memory_failures += vesa_copy_failures != 0;
		Bench486Printf ("VESA C/ASM rectangle-copy cases %s failure mask 0x%x\n",
				vesa_copy_failures ? "FAIL" : "PASS", vesa_copy_failures);
#else
		bench486_memory_failures++;
		Bench486Printf ("VESA copy fixture requires VesaCopyRectsImplementation=asm-fixture\n");
#endif
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
	if (COM_CheckParm ("-benchvesaswap"))
	{
#if defined(ASM486_VESA_SWAP_BUFFERS_FIXTURE)
		int vesa_swap_failures;
		vesa_swap_failures = Bench486VesaSwapBuffersCases ();
		bench486_memory_failures += vesa_swap_failures != 0;
		Bench486Printf ("VESA C/ASM page-flip and copy presentation cases %s failure mask 0x%x\n",
				vesa_swap_failures ? "FAIL" : "PASS", vesa_swap_failures);
#else
		bench486_memory_failures++;
		Bench486Printf ("VESA swap fixture requires VesaSwapBuffersImplementation=asm-fixture\n");
#endif
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
	if (COM_CheckParm ("-benchvidupdate"))
	{
#if defined(ASM486_VID_UPDATE_FIXTURE)
		int vid_update_failures, vid_directrect_failures;
		int vid_mode_failures;
		vid_update_failures = Bench486VidUpdateCases ();
		bench486_memory_failures += vid_update_failures != 0;
		Bench486Printf ("VID_Update C/ASM state and dispatch cases %s failure mask 0x%x\n",
				vid_update_failures ? "FAIL" : "PASS", vid_update_failures);
		vid_mode_failures = Bench486VidModeCases ();
		bench486_memory_failures += vid_mode_failures != 0;
		Bench486Printf ("DOS video mode C/ASM lookup, palette, shutdown, and transition cases %s failure mask 0x%x\n",
				vid_mode_failures ? "FAIL" : "PASS", vid_mode_failures);
		vid_directrect_failures = Bench486VidDirectRectCases ();
		bench486_memory_failures += vid_directrect_failures != 0;
		Bench486Printf ("VGA direct-rectangle C/ASM parity %s (6 mode cases and 13 guard cases, failure mask 0x%x)\n",
				vid_directrect_failures ? "FAIL" : "PASS",
				vid_directrect_failures);
#else
		bench486_memory_failures++;
		Bench486Printf ("VID_Update fixture requires VideoUpdateImplementation=asm-fixture\n");
#endif
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
	if (COM_CheckParm ("-benchsbarinventory"))
	{
#if defined(ASM486_SBAR_INVENTORY) && defined(ASM486_SBAR_PRIMITIVES)
		Bench486SbarInventoryCases ();
#else
		bench486_memory_failures++;
		Bench486Printf ("sbar inventory fixture requires SbarInventoryImplementation=asm and SbarPrimitiveImplementation=asm\n");
#endif
		Bench486Printf ("486 benchmark correctness %s\n", bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}

	if (COM_CheckParm ("-benchviewcontrol"))
	{
		Bench486ViewControlCases ();
	#ifdef ASM486_VIEW_CONTROL
		Bench486VInitCases ();
	#endif
		Bench486Printf ("486 benchmark correctness %s\n", bench486_memory_failures ? "FAIL" : "PASS");
		if (bench486_report_handle != -1) { Sys_FileClose(bench486_report_handle); bench486_report_handle = -1; }
		if (COM_CheckParm ("-benchexit")) Sys_Quit ();
		return;
	}

	if (COM_CheckParm ("-benchconsoleinput"))
	{
#ifdef ASM486_CONSOLE_INPUT
	#ifndef BENCH486_CONSOLE_OUTPUT_ONLY
		Bench486ConsoleInputCases ();
	#else
		bench486_memory_failures++;
		Bench486Printf ("console input fixture excluded from console-output-only build\n");
	#endif
		Bench486ConPrintCases ();
		Bench486ConPrintfCases ();
#else
		bench486_memory_failures++;
		Bench486Printf ("console input fixture requires ConsoleImplementation=asm\n");
#endif
		Bench486Printf ("486 benchmark correctness %s\n", bench486_memory_failures ? "FAIL" : "PASS");
		if (bench486_report_handle != -1) { Sys_FileClose(bench486_report_handle); bench486_report_handle = -1; }
		if (COM_CheckParm ("-benchexit")) Sys_Quit ();
		return;
	}
	if (COM_CheckParm ("-benchconsoleoutput"))
	{
		Bench486ConPrintfCases ();
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
	if (COM_CheckParm ("-benchscreenconsolesetup"))
	{
#ifdef ASM486_SCREEN_CONSOLE_SETUP
		int con_resize_failures;
		Bench486ScreenConsoleSetupCases ();
		con_resize_failures = Bench486ConsoleResizeCases ();
		bench486_memory_failures += con_resize_failures != 0;
		Bench486Printf ("Con_CheckResize C/ASM buffer and ABI cases %s failure mask 0x%x\n",
				con_resize_failures ? "FAIL" : "PASS", con_resize_failures);
#else
		bench486_memory_failures++;
		Bench486Printf ("screen console setup fixture requires ScreenConsoleSetupImplementation=asm\n");
#endif
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
	if (COM_CheckParm ("-benchscreenrefdef"))
	{
#ifdef ASM486_SCREEN_REFDEF
		Bench486ScreenRefdefCases ();
#else
		bench486_memory_failures++;
		Bench486Printf ("screen refdef fixture requires ScreenRefdefImplementation=asm\n");
#endif
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
	if (COM_CheckParm ("-benchscreenram"))
	{
#ifdef ASM486_SCREEN_DRAW_RAM
		Bench486ScreenDrawRamCases ();
#else
		bench486_memory_failures++;
		Bench486Printf ("screen RAM fixture requires ScreenDrawRamImplementation=asm\n");
#endif
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
	if (COM_CheckParm ("-benchscreenoverlays"))
	{
#ifdef ASM486_SCREEN_OVERLAYS
		Bench486ScreenOverlaysCases ();
#else
		bench486_memory_failures++;
		Bench486Printf ("screen overlay fixture requires ScreenOverlaysImplementation=asm\n");
#endif
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
	if (COM_CheckParm ("-benchscreenupdate"))
	{
#ifdef ASM486_SCREEN_UPDATE
		Bench486ScreenUpdateCases ();
#else
		bench486_memory_failures++;
		Bench486Printf ("screen update fixture requires ScreenUpdateImplementation=asm\n");
#endif
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
	if (COM_CheckParm ("-benchscreennet"))
	{
#ifdef ASM486_SCREEN_NET
		Bench486ScreenNetCases ();
#else
		bench486_memory_failures++;
		Bench486Printf ("screen net fixture requires ScreenNetImplementation=asm\n");
#endif
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
	if (COM_CheckParm ("-benchscreenturtle"))
	{
#ifdef ASM486_SCREEN_TURTLE
		Bench486ScreenTurtleCases ();
#else
		bench486_memory_failures++;
		Bench486Printf ("screen turtle fixture requires ScreenTurtleImplementation=asm\n");
#endif
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}

	if (COM_CheckParm ("-benchscreenotify"))
	{
#ifdef ASM486_SCREEN_NOTIFY
		Bench486ScreenNotifyCases ();
#else
		bench486_memory_failures++;
		Bench486Printf ("screen notify fixture requires ScreenNotifyImplementation=asm\n");
#endif
		Bench486Printf ("486 benchmark correctness %s\n", bench486_memory_failures ? "FAIL" : "PASS");
		if (bench486_report_handle != -1) { Sys_FileClose(bench486_report_handle); bench486_report_handle = -1; }
		if (COM_CheckParm ("-benchexit")) Sys_Quit ();
		return;
	}
	if (COM_CheckParm ("-benchcenterstring"))
	{
#ifdef ASM486_SCREEN_CENTER_STRING
		Bench486ScreenCenterCases ();
#else
		bench486_memory_failures++;
		Bench486Printf ("screen center fixture requires ScreenCenterStringImplementation=asm\n");
#endif
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
	if (COM_CheckParm ("-benchcentererase"))
	{
#ifdef ASM486_SCREEN_ERASE_CENTER_STRING
		Bench486ScreenEraseCenterCases ();
#else
		bench486_memory_failures++;
		Bench486Printf ("screen erase fixture requires ScreenEraseCenterStringImplementation=asm\n");
#endif
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}

	if (COM_CheckParm ("-benchdrawingdriver"))
	{
		Bench486DrawingDriverCases ();
		Bench486Printf ("486 benchmark correctness %s\n", bench486_memory_failures ? "FAIL" : "PASS");
		if (bench486_report_handle != -1) { Sys_FileClose(bench486_report_handle); bench486_report_handle = -1; }
		if (COM_CheckParm ("-benchexit")) Sys_Quit ();
		return;
	}

	if (COM_CheckParm ("-benchrenderdispatch"))
	{
		Bench486RenderDispatchCases ();
		Bench486Printf ("486 benchmark correctness %s\n", bench486_memory_failures ? "FAIL" : "PASS");
		if (bench486_report_handle != -1) { Sys_FileClose(bench486_report_handle); bench486_report_handle = -1; }
		if (COM_CheckParm ("-benchexit")) Sys_Quit ();
		return;
	}

	if (COM_CheckParm ("-benchsky"))
	{
		Bench486SkyCases ();
		Bench486Printf ("486 benchmark correctness %s\n", bench486_memory_failures ? "FAIL" : "PASS");
		if (bench486_report_handle != -1) { Sys_FileClose(bench486_report_handle); bench486_report_handle = -1; }
		if (COM_CheckParm ("-benchexit")) Sys_Quit ();
		return;
	}

	if (COM_CheckParm ("-benchvisibility"))
	{
		Bench486VisibilityCases ();
		Bench486Printf ("486 benchmark correctness %s\n", bench486_memory_failures ? "FAIL" : "PASS");
		if (bench486_report_handle != -1) { Sys_FileClose(bench486_report_handle); bench486_report_handle = -1; }
		if (COM_CheckParm ("-benchexit")) Sys_Quit ();
		return;
	}

	if (COM_CheckParm ("-benchmathclosure"))
	{
		Bench486MathClosureCases ();
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit")) Sys_Quit ();
		return;
	}
	if (COM_CheckParm ("-benchpalette"))
	{
		Bench486PaletteCases ();
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit")) Sys_Quit ();
		return;
	}

	if (COM_CheckParm ("-benchframecontrol"))
	{
		Bench486FrameControlCases ();
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit")) Sys_Quit ();
		return;
	}
	if (COM_CheckParm ("-benchlightcontrol"))
	{
		Bench486AnimatedLightCases ();
		Bench486PointLightCases ();
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit")) Sys_Quit ();
		return;
	}
	if (COM_CheckParm ("-benchspriteorientation"))
	{
		Bench486RendererMathCases ();
		Bench486SpriteOrientationCases ();
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit")) Sys_Quit ();
		return;
	}
	if (COM_CheckParm ("-benchaliastransformfinal"))
	{
		Bench486Printf ("alias-transform-final experiment compares the C clipped vertex helper\n");
		Bench486Printf ("with a register-held 486 x87 transform and lighting helper\n");
		Bench486AliasTransformFinalCases ();
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
	if (COM_CheckParm ("-benchmip"))
	{
		Bench486Printf ("mip-level entry experiment compares C and 486 x87 paths\n");
		Bench486MipCases ();
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
#ifdef ASM486_SURFACE_ZGRADIENTS
	if (COM_CheckParm ("-benchzgradient"))
	{
		Bench486Printf ("surface Z-gradient experiment compares the C cache path\n");
		Bench486Printf ("with the 486 x87 assembly entry across cache keys and rounding modes\n");
		Bench486SurfaceZGradientCases ();
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
	if (COM_CheckParm ("-benchhunktempalloc"))
	{
#if defined(ASM486_HUNK_TEMP_ALLOC_FIXTURE)
		int hunk_temp_alloc_failures;
		hunk_temp_alloc_failures = Bench486HunkTempAllocCases ();
		bench486_memory_failures += hunk_temp_alloc_failures != 0;
		Bench486Printf ("hunk temp-allocation C/ASM cases %s failure mask 0x%x\n",
				hunk_temp_alloc_failures ? "FAIL" : "PASS", hunk_temp_alloc_failures);
#else
		bench486_memory_failures++;
		Bench486Printf ("hunk temp-allocation fixture requires HunkTempAllocImplementation=asm-fixture\n");
#endif
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
	if (COM_CheckParm ("-benchhunknamedalloc"))
	{
#if defined(ASM486_HUNK_NAMED_ALLOC_FIXTURE)
		int hunk_named_alloc_failures;
		hunk_named_alloc_failures = Bench486HunkNamedAllocCases ();
		bench486_memory_failures += hunk_named_alloc_failures != 0;
		Bench486Printf ("hunk low/high named-allocation C/ASM cases %s failure mask 0x%x\n",
				hunk_named_alloc_failures ? "FAIL" : "PASS", hunk_named_alloc_failures);
#else
		bench486_memory_failures++;
		Bench486Printf ("hunk named-allocation fixture requires HunkNamedAllocImplementation=asm-fixture\n");
#endif
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
#endif
	if (COM_CheckParm ("-benchzoneheap"))
	{
#if defined(ASM486_ZONE_HEAP_FIXTURE)
		int zone_heap_failures;
		zone_heap_failures = Bench486ZoneHeapCases ();
		bench486_memory_failures += zone_heap_failures != 0;
		Bench486Printf ("zone heap C/ASM cases %s failure mask 0x%x\n",
				zone_heap_failures ? "FAIL" : "PASS", zone_heap_failures);
#else
		bench486_memory_failures++;
		Bench486Printf ("zone heap fixture requires ZoneHeapImplementation=asm-fixture\n");
#endif
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
	#ifdef ASM486_SURFACE_GRADIENTS
	if (COM_CheckParm ("-benchsurfacegradients"))
	{
		Bench486Printf ("surface-gradient experiment compares C and 486 x87 assembly\n");
		Bench486Printf ("with independent texture-axis caches across mip levels and rounding modes\n");
		Bench486SurfaceGradientCases ();
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
	#endif
	if (COM_CheckParm ("-benchtextureanimation"))
	{
		Bench486Printf ("texture-animation experiment compares the C frame loop\n");
		Bench486Printf ("with a register-only 486 pointer/branch loop\n");
		Bench486TextureAnimationCases ();
#ifdef ASM486_TEXTURE_ANIMATION
		Bench486TextureAnimationEntryCases ();
#endif
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
	if (COM_CheckParm ("-benchlightmapnormalize"))
	{
		Bench486Printf ("lightmap-normalize experiment compares the C loop\n");
		Bench486Printf ("with a register-based 486 pointer/count loop\n");
		Bench486LightMapNormalizeCases ();
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
	if (COM_CheckParm ("-benchlightmapstyles"))
	{
		Bench486Printf ("lightmap-styles experiment compares the generic C accumulation loop");
		Bench486Printf ("with the selectable i486 contiguous-plane helper");
		Bench486LightMapStylesCases ();
		Bench486Printf ("486 benchmark correctness %s",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
	if (COM_CheckParm ("-benchfusedlightmap"))
	{
		Bench486Printf ("fused-lightmap experiment compares C/ASM 2..4-style paths");
		Bench486FusedLightMapCases ();
		Bench486Printf ("486 benchmark correctness %s",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
	return;
}
#if defined(ASM486_LIGHTMAP_BUILD) || defined(ASM486_MARK_LIGHTS) || defined(ASM486_DYNAMIC_LIGHT_PUSH)
	if (COM_CheckParm ("-benchlightmapbuild"))
	{
		Bench486Printf ("lighting assembly parity checks\n");
#ifdef ASM486_LIGHTMAP_BUILD
		Bench486LightMapBuildParity ();
#endif
#ifdef ASM486_MARK_LIGHTS
		Bench486MarkLightsParity ();
#endif
#ifdef ASM486_DYNAMIC_LIGHT_PUSH
		Bench486PushDlightsParity ();
#endif
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
#endif
#ifdef ASM486_PARTICLE_UPDATE
	if (COM_CheckParm ("-benchparticlelist"))
	{
		Bench486Printf ("particle-pool list reset compares C and 486 assembly\n");
		Bench486ParticleListCases ();
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
#endif
#if defined(BENCH486) && defined(ASM486_PARTICLE_DRAW)
	if (COM_CheckParm ("-benchparticledraw"))
	{
		Bench486Printf ("particle rasterizer compares the retained C routine with 486 assembly\n");
		Bench486ParticleDrawCases ();
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
#endif
#if defined(BENCH486) && defined(ASM486_PARTICLE_UPDATE) && \
		defined(ASM486_PARTICLE_DRAW)
	if (COM_CheckParm ("-benchparticleupdate"))
	{
		Bench486ParticleUpdateCases ();
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
#endif
#ifdef ASM486_DRAW_Z_SUBMODEL_POLYS
	if (COM_CheckParm ("-benchzsubmodelpolys"))
	{
		Bench486Printf ("submodel polygon Z pass compares the retained C routine with 486 assembly\n");
		Bench486ZSubmodelCases ();
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
#endif
#ifdef ASM486_TRANSFORM_FRUSTUM
	if (COM_CheckParm ("-benchfrustumtransform"))
	{
		Bench486Printf ("view frustum transform compares C and 486 assembly\n");
		Bench486FrustumCases ();
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
#endif
#ifdef ASM486_SURFACE_CACHE_CHECK
	if (COM_CheckParm ("-benchsurfacecache"))
	{
		Bench486Printf ("surface-cache experiment compares C and assembly fast paths\n");
		Bench486SurfaceCacheCase ();
		Bench486SurfaceCacheSetupCase ();
		Bench486SurfaceCacheEntryParity ();
		Bench486SurfaceCacheSizingParity ();
		Bench486SurfaceCacheLifecycleParity ();
		Bench486SurfaceAllocatorParity ();
		Bench486SurfaceAttachTagParity ();
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
#endif
#ifdef ASM486_SURFACE_DRAW
	if (COM_CheckParm ("-benchsurfacedraw"))
	{
		Bench486Printf ("surface-draw experiment compares the full C setup and\n");
		Bench486Printf ("i486 assembly entry across mip, wrap, and lightmap cases\n");
		Bench486SurfaceDrawParity ();
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
#endif
	if (COM_CheckParm ("-benchbspplanedot"))
	{
		Bench486Printf ("bsp-plane-dot experiment compares the C switch\n");
		Bench486Printf ("with a 486 x87 axis/generic plane-dot helper\n");
		Bench486BspPlaneDotCases ();
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
	if (COM_CheckParm ("-benchbspclip"))
	{
		Bench486Printf ("bsp-clip experiment compares the C frustum loop\n");
		Bench486Printf ("with a four-plane 486 x87 clipping helper\n");
		Bench486BspClipCases ();
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
	if (COM_CheckParm ("-benchturbulent"))
	{
		Bench486Printf ("turbulent-span experiment compares the C inner loop with\n");
		Bench486Printf ("the current and optional STOSB 486 sequential-store loop\n");
		Bench486TurbulentCases ();
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
#ifdef ASM486_TURBULENT_SCAN
	if (COM_CheckParm ("-benchturbulentscan"))
	{
		Bench486Printf ("turbulent-scan experiment compares full C setup/interpolation\n");
		Bench486Printf ("with the i486 assembly entry and selected shared pixel loop\n");
		Bench486TurbulentScanParity ();
		Bench486Printf ("486 benchmark correctness %s\n",
				bench486_memory_failures ? "FAIL" : "PASS");
		Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);
		if (bench486_report_handle != -1)
		{
			Sys_FileClose (bench486_report_handle);
			bench486_report_handle = -1;
		}
		if (COM_CheckParm ("-benchexit"))
			Sys_Quit ();
		return;
	}
#endif
	Bench486Printf ("memory experiment compares existing C helpers with\n");
	Bench486Printf ("separate forward-copy and byte-fill 486 assembly paths\n");
	Bench486MemoryCases ();
	Bench486Printf ("texture-axis experiment compares the C cache-key probe with\n");
	Bench486Printf ("the isolated 486 assembly fast-hit/miss probe\n");
	Bench486TextureAxisCase ();
	Bench486Printf ("surface-cache experiment compares the C cache-validity predicate\n");
	Bench486Printf ("with the isolated 486 assembly fast-hit/miss predicate\n");
	Bench486SurfaceCacheCase ();
#ifdef ASM486_SURFACE_CACHE_CHECK
	Bench486SurfaceCacheSetupCase ();
	Bench486SurfaceCacheEntryParity ();
#endif
	Bench486Printf ("mip-level experiment compares the C threshold selector with\n");
	Bench486Printf ("the isolated 486 x87 threshold selector\n");
	Bench486MipCases ();
	Bench486Printf ("turbulent-span experiment compares the C inner loop with\n");
	Bench486Printf ("the current and optional STOSB 486 sequential-store loop\n");
	Bench486TurbulentCases ();
#ifdef ASM486_TURBULENT_SCAN
	Bench486TurbulentScanParity ();
#endif
	Bench486Printf ("texture-animation experiment compares the C frame loop with\n");
	Bench486Printf ("the register-only 486 pointer/branch loop\n");
	Bench486TextureAnimationCases ();
#ifdef ASM486_TEXTURE_ANIMATION
	Bench486TextureAnimationEntryCases ();
#endif
	Bench486Printf ("lightmap-normalize experiment compares the C loop with\n");
	Bench486Printf ("the register-based 486 pointer/count loop\n");
	Bench486LightMapNormalizeCases ();
	Bench486Printf ("lightmap-styles experiment compares the generic C accumulation loop with");
	Bench486Printf ("the selectable i486 contiguous-plane helper");
	Bench486LightMapStylesCases ();
	Bench486Printf ("fused-lightmap experiment compares C/ASM 2..4-style paths");
	Bench486FusedLightMapCases ();
	Bench486Printf ("bsp-plane-dot experiment compares the C switch with\n");
	Bench486Printf ("the 486 x87 axis/generic plane-dot helper\n");
	Bench486BspPlaneDotCases ();
	Bench486Printf ("bsp-clip experiment compares the C frustum loop with\n");
	Bench486Printf ("the four-plane 486 x87 clipping helper\n");
	Bench486BspClipCases ();
	Bench486Printf ("alias-bbox-project experiment compares the C projection loop with\n");
	Bench486Printf ("the register-held 486 x87 projection helper\n");
	Bench486AliasBBoxProjectCases ();
	Bench486AliasSetupLightingCases ();
	Bench486AliasSetupFrameCases ();
	Bench486AliasSetupSkinCases ();
	Bench486AliasGradientCases ();
	Bench486AliasLineScanCases ();
	Bench486AliasEdgeTableCases ();
	Bench486AliasSkinTableCases ();
	Bench486SpriteBeamCases ();
	Bench486SpriteClipCases ();
	Bench486SpriteFrameCases ();
	Bench486SpriteGradientCases ();
	Bench486SpriteScanLeftCases ();
	Bench486SpriteScanRightCases ();
	Bench486SpriteDrawCases ();
	Bench486SpriteSetupCases ();
	Bench486RendererMathCases ();
	Bench486SpriteOrientationCases ();
#ifdef ASM486_ANIMATED_LIGHT
	Bench486AnimatedLightCases ();
#endif
#ifdef ASM486_POINT_LIGHT
	Bench486PointLightCases ();
#endif
#ifdef ASM486_FRAME_CONTROL
	Bench486FrameControlCases ();
#endif
#ifdef ASM486_PALETTE
	Bench486PaletteCases ();
#endif
#ifdef ASM486_MATH_CLOSURE
	Bench486MathClosureCases ();
#endif
#ifdef ASM486_VISIBILITY
	Bench486VisibilityCases ();
#endif
#ifdef ASM486_PUBLIC_BINDINGS
	Bench486PublicBindingsCases ();
#endif
#ifdef ASM486_SKY
	Bench486SkyCases ();
#endif
#ifdef ASM486_RENDER_DISPATCH
	Bench486RenderDispatchCases ();
#endif
#ifdef ASM486_DRAWING_DRIVER
	Bench486DrawingDriverCases ();
#endif
#ifdef ASM486_VIEW_CONTROL
	Bench486ViewControlCases ();
	Bench486VInitCases ();
#endif
#if defined(ASM486_CONSOLE_INPUT) && \
		!defined(BENCH486_CONSOLE_OUTPUT_ONLY)
	Bench486ConsoleInputCases ();
#endif
#ifdef BENCH486
	Bench486ConPrintCases ();
	Bench486ConPrintfCases ();
#endif
#ifdef ASM486_SCREEN_NOTIFY
	Bench486ScreenNotifyCases ();
#endif
#ifdef ASM486_SCREEN_CENTER_STRING
	Bench486ScreenCenterCases ();
#endif
#ifdef ASM486_SCREEN_ERASE_CENTER_STRING
	Bench486ScreenEraseCenterCases ();
#endif
#ifdef ASM486_DRAWING
	Bench486DrawingCases ();
#endif
#ifdef ASM486_SBAR_PRIMITIVES
	Bench486SbarPrimitiveCases ();
#endif
#if defined(ASM486_SBAR_INVENTORY) && defined(ASM486_SBAR_PRIMITIVES)
	Bench486SbarInventoryCases ();
#endif
#ifdef ASM486_CHASE
	Bench486ChaseCases ();
#endif
#ifdef ASM486_ALIAS_CONTROL
	Bench486AliasControlCases ();
#endif
#ifdef ASM486_WORLD_CONTROL_FIXTURE
	Bench486WorldControlCases ();
	Bench486ForwardSpansCases ();
#endif
#ifdef ASM486_EFRAG_STORE
	Bench486EfragStoreCases ();
#endif
	Bench486Printf ("alias-transform-final experiment compares the C clipped vertex helper with\n");
	Bench486Printf ("the register-held 486 x87 transform and lighting helper\n");
	Bench486AliasTransformFinalCases ();
#if defined(ASM486_MARK_LIGHTS) && defined(BENCH486)
	Bench486MarkLightsParity ();
#endif
#if defined(ASM486_DYNAMIC_LIGHT_PUSH) && defined(BENCH486)
	Bench486PushDlightsParity ();
#endif
	Bench486LineCase ("line-small", 500000, -5, 10, 8, 20);
	Bench486LineCase ("line-large", 500000, 20, 10, 327, 700);
	Bench486FillCase ();
	Bench486Printf ("486 benchmark correctness %s\n",
			bench486_memory_failures ? "FAIL" : "PASS");
	Bench486Printf ("486 benchmark end checksum %u\n", bench486_sink);

	if (bench486_report_handle != -1)
	{
		Sys_FileClose (bench486_report_handle);
		bench486_report_handle = -1;
	}

	/* The DOS runner uses this switch to exit without opening the quit menu. */
	if (COM_CheckParm ("-benchexit"))
		Sys_Quit ();
}

#endif

/*
==================
Host_Quit_f
==================
*/

extern void M_Menu_Quit_f (void);

void Host_Quit_f (void)
{
	if (!COM_CheckParm("-forcquit") &&
		key_dest != key_console && cls.state != ca_dedicated)
	{
		M_Menu_Quit_f ();
		return;
	}
	CL_Disconnect ();
	Host_ShutdownServer(false);		

	Sys_Quit ();
}


/*
==================
Host_Status_f
==================
*/
void Host_Status_f (void)
{
	client_t	*client;
	int			seconds;
	int			minutes;
	int			hours = 0;
	int			j;
	void		(*print) (char *fmt, ...);
	
	if (cmd_source == src_command)
	{
		if (!sv.active)
		{
			Cmd_ForwardToServer ();
			return;
		}
		print = Con_Printf;
	}
	else
		print = SV_ClientPrintf;

	print ("host:    %s\n", Cvar_VariableString ("hostname"));
	print ("%s\n%s\n", nitroquake_version, nitroquake_build);
	if (tcpipAvailable)
		print ("tcp/ip:  %s\n", my_tcpip_address);
	if (ipxAvailable)
		print ("ipx:     %s\n", my_ipx_address);
	print ("map:     %s\n", sv.name);
	print ("players: %i active (%i max)\n\n", net_activeconnections, svs.maxclients);
	for (j=0, client = svs.clients ; j<svs.maxclients ; j++, client++)
	{
		if (!client->active)
			continue;
		seconds = (int)(net_time - client->netconnection->connecttime);
		minutes = seconds / 60;
		if (minutes)
		{
			seconds -= (minutes * 60);
			hours = minutes / 60;
			if (hours)
				minutes -= (hours * 60);
		}
		else
			hours = 0;
		print ("#%-2u %-16.16s  %3i  %2i:%02i:%02i\n", j+1, client->name, (int)client->edict->v.frags, hours, minutes, seconds);
		print ("   %s\n", client->netconnection->address);
	}
}


/*
==================
Host_God_f

Sets client to godmode
==================
*/
void Host_God_f (void)
{
	if (cmd_source == src_command)
	{
		Cmd_ForwardToServer ();
		return;
	}

	if (pr_global_struct->deathmatch && !host_client->privileged)
		return;

	sv_player->v.flags = (int)sv_player->v.flags ^ FL_GODMODE;
	if (!((int)sv_player->v.flags & FL_GODMODE) )
		SV_ClientPrintf ("godmode OFF\n");
	else
		SV_ClientPrintf ("godmode ON\n");
}

void Host_Notarget_f (void)
{
	if (cmd_source == src_command)
	{
		Cmd_ForwardToServer ();
		return;
	}

	if (pr_global_struct->deathmatch && !host_client->privileged)
		return;

	sv_player->v.flags = (int)sv_player->v.flags ^ FL_NOTARGET;
	if (!((int)sv_player->v.flags & FL_NOTARGET) )
		SV_ClientPrintf ("notarget OFF\n");
	else
		SV_ClientPrintf ("notarget ON\n");
}

qboolean noclip_anglehack;

void Host_Noclip_f (void)
{
	if (cmd_source == src_command)
	{
		Cmd_ForwardToServer ();
		return;
	}

	if (pr_global_struct->deathmatch && !host_client->privileged)
		return;

	if (sv_player->v.movetype != MOVETYPE_NOCLIP)
	{
		noclip_anglehack = true;
		sv_player->v.movetype = MOVETYPE_NOCLIP;
		SV_ClientPrintf ("noclip ON\n");
	}
	else
	{
		noclip_anglehack = false;
		sv_player->v.movetype = MOVETYPE_WALK;
		SV_ClientPrintf ("noclip OFF\n");
	}
}

/*
==================
Host_Fly_f

Sets client to flymode
==================
*/
void Host_Fly_f (void)
{
	if (cmd_source == src_command)
	{
		Cmd_ForwardToServer ();
		return;
	}

	if (pr_global_struct->deathmatch && !host_client->privileged)
		return;

	if (sv_player->v.movetype != MOVETYPE_FLY)
	{
		sv_player->v.movetype = MOVETYPE_FLY;
		SV_ClientPrintf ("flymode ON\n");
	}
	else
	{
		sv_player->v.movetype = MOVETYPE_WALK;
		SV_ClientPrintf ("flymode OFF\n");
	}
}


/*
==================
Host_Ping_f

==================
*/
void Host_Ping_f (void)
{
	int		i, j;
	float	total;
	client_t	*client;
	
	if (cmd_source == src_command)
	{
		Cmd_ForwardToServer ();
		return;
	}

	SV_ClientPrintf ("Client ping times:\n");
	for (i=0, client = svs.clients ; i<svs.maxclients ; i++, client++)
	{
		if (!client->active)
			continue;
		total = 0;
		for (j=0 ; j<NUM_PING_TIMES ; j++)
			total+=client->ping_times[j];
		total /= NUM_PING_TIMES;
		SV_ClientPrintf ("%4i %s\n", (int)(total*1000), client->name);
	}
}

/*
===============================================================================

SERVER TRANSITIONS

===============================================================================
*/


/*
======================
Host_Map_f

handle a 
map <servername>
command from the console.  Active clients are kicked off.
======================
*/
void Host_Map_f (void)
{
	int		i;
	char	name[MAX_QPATH];

	if (cmd_source != src_command)
		return;

	cls.demonum = -1;		// stop demo loop in case this fails

	CL_Disconnect ();
	Host_ShutdownServer(false);		

	key_dest = key_game;			// remove console or menu
	SCR_BeginLoadingPlaque ();

	cls.mapstring[0] = 0;
	for (i=0 ; i<Cmd_Argc() ; i++)
	{
		strcat (cls.mapstring, Cmd_Argv(i));
		strcat (cls.mapstring, " ");
	}
	strcat (cls.mapstring, "\n");

	svs.serverflags = 0;			// haven't completed an episode yet
	strcpy (name, Cmd_Argv(1));
#ifdef QUAKE2
	SV_SpawnServer (name, NULL);
#else
	SV_SpawnServer (name);
#endif
	if (!sv.active)
		return;
	
	if (cls.state != ca_dedicated)
	{
		strcpy (cls.spawnparms, "");

		for (i=2 ; i<Cmd_Argc() ; i++)
		{
			strcat (cls.spawnparms, Cmd_Argv(i));
			strcat (cls.spawnparms, " ");
		}
		
		Cmd_ExecuteString ("connect local", src_command);
	}	
}

/*
==================
Host_Changelevel_f

Goes to a new map, taking all clients along
==================
*/
void Host_Changelevel_f (void)
{
#ifdef QUAKE2
	char	level[MAX_QPATH];
	char	_startspot[MAX_QPATH];
	char	*startspot;

	if (Cmd_Argc() < 2)
	{
		Con_Printf ("changelevel <levelname> : continue game on a new level\n");
		return;
	}
	if (!sv.active || cls.demoplayback)
	{
		Con_Printf ("Only the server may changelevel\n");
		return;
	}

	strcpy (level, Cmd_Argv(1));
	if (Cmd_Argc() == 2)
		startspot = NULL;
	else
	{
		strcpy (_startspot, Cmd_Argv(2));
		startspot = _startspot;
	}

	SV_SaveSpawnparms ();
	SV_SpawnServer (level, startspot);
#else
	char	level[MAX_QPATH];

	if (Cmd_Argc() != 2)
	{
		Con_Printf ("changelevel <levelname> : continue game on a new level\n");
		return;
	}
	if (!sv.active || cls.demoplayback)
	{
		Con_Printf ("Only the server may changelevel\n");
		return;
	}
	SV_SaveSpawnparms ();
	strcpy (level, Cmd_Argv(1));
	SV_SpawnServer (level);
#endif
}

/*
==================
Host_Restart_f

Restarts the current server for a dead player
==================
*/
void Host_Restart_f (void)
{
	char	mapname[MAX_QPATH];
#ifdef QUAKE2
	char	startspot[MAX_QPATH];
#endif

	if (cls.demoplayback || !sv.active)
		return;

	if (cmd_source != src_command)
		return;
	strcpy (mapname, sv.name);	// must copy out, because it gets cleared
								// in sv_spawnserver
#ifdef QUAKE2
	strcpy(startspot, sv.startspot);
	SV_SpawnServer (mapname, startspot);
#else
	SV_SpawnServer (mapname);
#endif
}

/*
==================
Host_Reconnect_f

This command causes the client to wait for the signon messages again.
This is sent just before a server changes levels
==================
*/
void Host_Reconnect_f (void)
{
	SCR_BeginLoadingPlaque ();
	cls.signon = 0;		// need new connection messages
}

/*
=====================
Host_Connect_f

User command to connect to server
=====================
*/
void Host_Connect_f (void)
{
	char	name[MAX_QPATH];
	
	cls.demonum = -1;		// stop demo loop in case this fails
	if (cls.demoplayback)
	{
		CL_StopPlayback ();
		CL_Disconnect ();
	}
	strcpy (name, Cmd_Argv(1));
	CL_EstablishConnection (name);
	Host_Reconnect_f ();
}


/*
===============================================================================

LOAD / SAVE GAME

===============================================================================
*/

#define	SAVEGAME_VERSION	5

/*
===============
Host_SavegameComment

Writes a SAVEGAME_COMMENT_LENGTH character comment describing the current 
===============
*/
void Host_SavegameComment (char *text)
{
	int		i;
	char	kills[20];

	for (i=0 ; i<SAVEGAME_COMMENT_LENGTH ; i++)
		text[i] = ' ';
	memcpy (text, cl.levelname, strlen(cl.levelname));
	sprintf (kills,"kills:%3i/%3i", cl.stats[STAT_MONSTERS], cl.stats[STAT_TOTALMONSTERS]);
	memcpy (text+22, kills, strlen(kills));
// convert space to _ to make stdio happy
	for (i=0 ; i<SAVEGAME_COMMENT_LENGTH ; i++)
		if (text[i] == ' ')
			text[i] = '_';
	text[SAVEGAME_COMMENT_LENGTH] = '\0';
}


/*
===============
Host_Savegame_f
===============
*/
void Host_Savegame_f (void)
{
	char	name[256];
	FILE	*f;
	int		i;
	char	comment[SAVEGAME_COMMENT_LENGTH+1];

	if (cmd_source != src_command)
		return;

	if (!sv.active)
	{
		Con_Printf ("Not playing a local game.\n");
		return;
	}

	if (cl.intermission)
	{
		Con_Printf ("Can't save in intermission.\n");
		return;
	}

	if (svs.maxclients != 1)
	{
		Con_Printf ("Can't save multiplayer games.\n");
		return;
	}

	if (Cmd_Argc() != 2)
	{
		Con_Printf ("save <savename> : save a game\n");
		return;
	}

	if (strstr(Cmd_Argv(1), ".."))
	{
		Con_Printf ("Relative pathnames are not allowed.\n");
		return;
	}
		
	for (i=0 ; i<svs.maxclients ; i++)
	{
		if (svs.clients[i].active && (svs.clients[i].edict->v.health <= 0) )
		{
			Con_Printf ("Can't savegame with a dead player\n");
			return;
		}
	}

	sprintf (name, "%s/%s", com_gamedir, Cmd_Argv(1));
	COM_DefaultExtension (name, ".sav");
	
	Con_Printf ("Saving game to %s...\n", name);
	f = fopen (name, "w");
	if (!f)
	{
		Con_Printf ("ERROR: couldn't open.\n");
		return;
	}
	
	fprintf (f, "%i\n", SAVEGAME_VERSION);
	Host_SavegameComment (comment);
	fprintf (f, "%s\n", comment);
	for (i=0 ; i<NUM_SPAWN_PARMS ; i++)
		fprintf (f, "%f\n", svs.clients->spawn_parms[i]);
	fprintf (f, "%d\n", current_skill);
	fprintf (f, "%s\n", sv.name);
	fprintf (f, "%f\n",sv.time);

// write the light styles

	for (i=0 ; i<MAX_LIGHTSTYLES ; i++)
	{
		if (sv.lightstyles[i])
			fprintf (f, "%s\n", sv.lightstyles[i]);
		else
			fprintf (f,"m\n");
	}


	ED_WriteGlobals (f);
	for (i=0 ; i<sv.num_edicts ; i++)
	{
		ED_Write (f, EDICT_NUM(i));
		fflush (f);
	}
	fclose (f);
	Con_Printf ("done.\n");
}


/*
===============
Host_Loadgame_f
===============
*/
void Host_Loadgame_f (void)
{
	char	name[MAX_OSPATH];
	FILE	*f;
	char	mapname[MAX_QPATH];
	float	time, tfloat;
	char	str[32768], *start;
	int		i, r;
	edict_t	*ent;
	int		entnum;
	int		version;
	float			spawn_parms[NUM_SPAWN_PARMS];

	if (cmd_source != src_command)
		return;

	if (Cmd_Argc() != 2)
	{
		Con_Printf ("load <savename> : load a game\n");
		return;
	}

	cls.demonum = -1;		// stop demo loop in case this fails

	sprintf (name, "%s/%s", com_gamedir, Cmd_Argv(1));
	COM_DefaultExtension (name, ".sav");
	
// we can't call SCR_BeginLoadingPlaque, because too much stack space has
// been used.  The menu calls it before stuffing loadgame command
//	SCR_BeginLoadingPlaque ();

	Con_Printf ("Loading game from %s...\n", name);
	f = fopen (name, "r");
	if (!f)
	{
		Con_Printf ("ERROR: couldn't open.\n");
		return;
	}

	fscanf (f, "%i\n", &version);
	if (version != SAVEGAME_VERSION)
	{
		fclose (f);
		Con_Printf ("Savegame is version %i, not %i\n", version, SAVEGAME_VERSION);
		return;
	}
	fscanf (f, "%s\n", str);
	for (i=0 ; i<NUM_SPAWN_PARMS ; i++)
		fscanf (f, "%f\n", &spawn_parms[i]);
// this silliness is so we can load 1.06 save files, which have float skill values
	fscanf (f, "%f\n", &tfloat);
	current_skill = (int)(tfloat + 0.1);
	Cvar_SetValue ("skill", (float)current_skill);

#ifdef QUAKE2
	Cvar_SetValue ("deathmatch", 0);
	Cvar_SetValue ("coop", 0);
	Cvar_SetValue ("teamplay", 0);
#endif

	fscanf (f, "%s\n",mapname);
	fscanf (f, "%f\n",&time);

	CL_Disconnect_f ();
	
#ifdef QUAKE2
	SV_SpawnServer (mapname, NULL);
#else
	SV_SpawnServer (mapname);
#endif
	if (!sv.active)
	{
		Con_Printf ("Couldn't load map\n");
		return;
	}
	sv.paused = true;		// pause until all clients connect
	sv.loadgame = true;

// load the light styles

	for (i=0 ; i<MAX_LIGHTSTYLES ; i++)
	{
		fscanf (f, "%s\n", str);
		sv.lightstyles[i] = Hunk_Alloc (strlen(str)+1);
		strcpy (sv.lightstyles[i], str);
	}

// load the edicts out of the savegame file
	entnum = -1;		// -1 is the globals
	while (!feof(f))
	{
		for (i=0 ; i<sizeof(str)-1 ; i++)
		{
			r = fgetc (f);
			if (r == EOF || !r)
				break;
			str[i] = r;
			if (r == '}')
			{
				i++;
				break;
			}
		}
		if (i == sizeof(str)-1)
			Sys_Error ("Loadgame buffer overflow");
		str[i] = 0;
		start = str;
		start = COM_Parse(str);
		if (!com_token[0])
			break;		// end of file
		if (strcmp(com_token,"{"))
			Sys_Error ("First token isn't a brace");
			
		if (entnum == -1)
		{	// parse the global vars
			ED_ParseGlobals (start);
		}
		else
		{	// parse an edict

			ent = EDICT_NUM(entnum);
			memset (&ent->v, 0, progs->entityfields * 4);
			ent->free = false;
			ED_ParseEdict (start, ent);
	
		// link it into the bsp tree
			if (!ent->free)
				SV_LinkEdict (ent, false);
		}

		entnum++;
	}
	
	sv.num_edicts = entnum;
	sv.time = time;

	fclose (f);

	for (i=0 ; i<NUM_SPAWN_PARMS ; i++)
		svs.clients->spawn_parms[i] = spawn_parms[i];

	if (cls.state != ca_dedicated)
	{
		CL_EstablishConnection ("local");
		Host_Reconnect_f ();
	}
}

#ifdef QUAKE2
void SaveGamestate()
{
	char	name[256];
	FILE	*f;
	int		i;
	char	comment[SAVEGAME_COMMENT_LENGTH+1];
	edict_t	*ent;

	sprintf (name, "%s/%s.gip", com_gamedir, sv.name);
	
	Con_Printf ("Saving game to %s...\n", name);
	f = fopen (name, "w");
	if (!f)
	{
		Con_Printf ("ERROR: couldn't open.\n");
		return;
	}
	
	fprintf (f, "%i\n", SAVEGAME_VERSION);
	Host_SavegameComment (comment);
	fprintf (f, "%s\n", comment);
//	for (i=0 ; i<NUM_SPAWN_PARMS ; i++)
//		fprintf (f, "%f\n", svs.clients->spawn_parms[i]);
	fprintf (f, "%f\n", skill.value);
	fprintf (f, "%s\n", sv.name);
	fprintf (f, "%f\n", sv.time);

// write the light styles

	for (i=0 ; i<MAX_LIGHTSTYLES ; i++)
	{
		if (sv.lightstyles[i])
			fprintf (f, "%s\n", sv.lightstyles[i]);
		else
			fprintf (f,"m\n");
	}


	for (i=svs.maxclients+1 ; i<sv.num_edicts ; i++)
	{
		ent = EDICT_NUM(i);
		if ((int)ent->v.flags & FL_ARCHIVE_OVERRIDE)
			continue;
		fprintf (f, "%i\n",i);
		ED_Write (f, ent);
		fflush (f);
	}
	fclose (f);
	Con_Printf ("done.\n");
}

int LoadGamestate(char *level, char *startspot)
{
	char	name[MAX_OSPATH];
	FILE	*f;
	char	mapname[MAX_QPATH];
	float	time, sk;
	char	str[32768], *start;
	int		i, r;
	edict_t	*ent;
	int		entnum;
	int		version;
//	float	spawn_parms[NUM_SPAWN_PARMS];

	sprintf (name, "%s/%s.gip", com_gamedir, level);
	
	Con_Printf ("Loading game from %s...\n", name);
	f = fopen (name, "r");
	if (!f)
	{
		Con_Printf ("ERROR: couldn't open.\n");
		return -1;
	}

	fscanf (f, "%i\n", &version);
	if (version != SAVEGAME_VERSION)
	{
		fclose (f);
		Con_Printf ("Savegame is version %i, not %i\n", version, SAVEGAME_VERSION);
		return -1;
	}
	fscanf (f, "%s\n", str);
//	for (i=0 ; i<NUM_SPAWN_PARMS ; i++)
//		fscanf (f, "%f\n", &spawn_parms[i]);
	fscanf (f, "%f\n", &sk);
	Cvar_SetValue ("skill", sk);

	fscanf (f, "%s\n",mapname);
	fscanf (f, "%f\n",&time);

	SV_SpawnServer (mapname, startspot);

	if (!sv.active)
	{
		Con_Printf ("Couldn't load map\n");
		return -1;
	}

// load the light styles
	for (i=0 ; i<MAX_LIGHTSTYLES ; i++)
	{
		fscanf (f, "%s\n", str);
		sv.lightstyles[i] = Hunk_Alloc (strlen(str)+1);
		strcpy (sv.lightstyles[i], str);
	}

// load the edicts out of the savegame file
	while (!feof(f))
	{
		fscanf (f, "%i\n",&entnum);
		for (i=0 ; i<sizeof(str)-1 ; i++)
		{
			r = fgetc (f);
			if (r == EOF || !r)
				break;
			str[i] = r;
			if (r == '}')
			{
				i++;
				break;
			}
		}
		if (i == sizeof(str)-1)
			Sys_Error ("Loadgame buffer overflow");
		str[i] = 0;
		start = str;
		start = COM_Parse(str);
		if (!com_token[0])
			break;		// end of file
		if (strcmp(com_token,"{"))
			Sys_Error ("First token isn't a brace");
			
		// parse an edict

		ent = EDICT_NUM(entnum);
		memset (&ent->v, 0, progs->entityfields * 4);
		ent->free = false;
		ED_ParseEdict (start, ent);
	
		// link it into the bsp tree
		if (!ent->free)
			SV_LinkEdict (ent, false);
	}
	
//	sv.num_edicts = entnum;
	sv.time = time;
	fclose (f);

//	for (i=0 ; i<NUM_SPAWN_PARMS ; i++)
//		svs.clients->spawn_parms[i] = spawn_parms[i];

	return 0;
}

// changing levels within a unit
void Host_Changelevel2_f (void)
{
	char	level[MAX_QPATH];
	char	_startspot[MAX_QPATH];
	char	*startspot;

	if (Cmd_Argc() < 2)
	{
		Con_Printf ("changelevel2 <levelname> : continue game on a new level in the unit\n");
		return;
	}
	if (!sv.active || cls.demoplayback)
	{
		Con_Printf ("Only the server may changelevel\n");
		return;
	}

	strcpy (level, Cmd_Argv(1));
	if (Cmd_Argc() == 2)
		startspot = NULL;
	else
	{
		strcpy (_startspot, Cmd_Argv(2));
		startspot = _startspot;
	}

	SV_SaveSpawnparms ();

	// save the current level's state
	SaveGamestate ();

	// try to restore the new level
	if (LoadGamestate (level, startspot))
		SV_SpawnServer (level, startspot);
}
#endif


//============================================================================

/*
======================
Host_Name_f
======================
*/
void Host_Name_f (void)
{
	char	*newName;

	if (Cmd_Argc () == 1)
	{
		Con_Printf ("\"name\" is \"%s\"\n", cl_name.string);
		return;
	}
	if (Cmd_Argc () == 2)
		newName = Cmd_Argv(1);	
	else
		newName = Cmd_Args();
	newName[15] = 0;

	if (cmd_source == src_command)
	{
		if (Q_strcmp(cl_name.string, newName) == 0)
			return;
		Cvar_Set ("_cl_name", newName);
		if (cls.state == ca_connected)
			Cmd_ForwardToServer ();
		return;
	}

	if (host_client->name[0] && strcmp(host_client->name, "unconnected") )
		if (Q_strcmp(host_client->name, newName) != 0)
			Con_Printf ("%s renamed to %s\n", host_client->name, newName);
	Q_strcpy (host_client->name, newName);
	host_client->edict->v.netname = host_client->name - pr_strings;
	
// send notification to all clients
	
	MSG_WriteByte (&sv.reliable_datagram, svc_updatename);
	MSG_WriteByte (&sv.reliable_datagram, host_client - svs.clients);
	MSG_WriteString (&sv.reliable_datagram, host_client->name);
}

	
void Host_Version_f (void)
{
	Con_Printf ("%s\n%s\n", nitroquake_version, nitroquake_build);
	Con_Printf ("Exe: "__TIME__" "__DATE__"\n");
}

#ifdef IDGODS
void Host_Please_f (void)
{
	client_t *cl;
	int			j;
	
	if (cmd_source != src_command)
		return;

	if ((Cmd_Argc () == 3) && Q_strcmp(Cmd_Argv(1), "#") == 0)
	{
		j = Q_atof(Cmd_Argv(2)) - 1;
		if (j < 0 || j >= svs.maxclients)
			return;
		if (!svs.clients[j].active)
			return;
		cl = &svs.clients[j];
		if (cl->privileged)
		{
			cl->privileged = false;
			cl->edict->v.flags = (int)cl->edict->v.flags & ~(FL_GODMODE|FL_NOTARGET);
			cl->edict->v.movetype = MOVETYPE_WALK;
			noclip_anglehack = false;
		}
		else
			cl->privileged = true;
	}

	if (Cmd_Argc () != 2)
		return;

	for (j=0, cl = svs.clients ; j<svs.maxclients ; j++, cl++)
	{
		if (!cl->active)
			continue;
		if (Q_strcasecmp(cl->name, Cmd_Argv(1)) == 0)
		{
			if (cl->privileged)
			{
				cl->privileged = false;
				cl->edict->v.flags = (int)cl->edict->v.flags & ~(FL_GODMODE|FL_NOTARGET);
				cl->edict->v.movetype = MOVETYPE_WALK;
				noclip_anglehack = false;
			}
			else
				cl->privileged = true;
			break;
		}
	}
}
#endif


void Host_Say(qboolean teamonly)
{
	client_t *client;
	client_t *save;
	int		j;
	char	*p;
	unsigned char	text[64];
	qboolean	fromServer = false;

	if (cmd_source == src_command)
	{
		if (cls.state == ca_dedicated)
		{
			fromServer = true;
			teamonly = false;
		}
		else
		{
			Cmd_ForwardToServer ();
			return;
		}
	}

	if (Cmd_Argc () < 2)
		return;

	save = host_client;

	p = Cmd_Args();
// remove quotes if present
	if (*p == '"')
	{
		p++;
		p[Q_strlen(p)-1] = 0;
	}

// turn on color set 1
	if (!fromServer)
		sprintf (text, "%c%s: ", 1, save->name);
	else
		sprintf (text, "%c<%s> ", 1, hostname.string);

	j = sizeof(text) - 2 - Q_strlen(text);  // -2 for /n and null terminator
	if (Q_strlen(p) > j)
		p[j] = 0;

	strcat (text, p);
	strcat (text, "\n");

	for (j = 0, client = svs.clients; j < svs.maxclients; j++, client++)
	{
		if (!client || !client->active || !client->spawned)
			continue;
		if (teamplay.value && teamonly && client->edict->v.team != save->edict->v.team)
			continue;
		host_client = client;
		SV_ClientPrintf("%s", text);
	}
	host_client = save;

	Sys_Printf("%s", &text[1]);
}


void Host_Say_f(void)
{
	Host_Say(false);
}


void Host_Say_Team_f(void)
{
	Host_Say(true);
}


void Host_Tell_f(void)
{
	client_t *client;
	client_t *save;
	int		j;
	char	*p;
	char	text[64];

	if (cmd_source == src_command)
	{
		Cmd_ForwardToServer ();
		return;
	}

	if (Cmd_Argc () < 3)
		return;

	Q_strcpy(text, host_client->name);
	Q_strcat(text, ": ");

	p = Cmd_Args();

// remove quotes if present
	if (*p == '"')
	{
		p++;
		p[Q_strlen(p)-1] = 0;
	}

// check length & truncate if necessary
	j = sizeof(text) - 2 - Q_strlen(text);  // -2 for /n and null terminator
	if (Q_strlen(p) > j)
		p[j] = 0;

	strcat (text, p);
	strcat (text, "\n");

	save = host_client;
	for (j = 0, client = svs.clients; j < svs.maxclients; j++, client++)
	{
		if (!client->active || !client->spawned)
			continue;
		if (Q_strcasecmp(client->name, Cmd_Argv(1)))
			continue;
		host_client = client;
		SV_ClientPrintf("%s", text);
		break;
	}
	host_client = save;
}


/*
==================
Host_Color_f
==================
*/
void Host_Color_f(void)
{
	int		top, bottom;
	int		playercolor;
	
	if (Cmd_Argc() == 1)
	{
		Con_Printf ("\"color\" is \"%i %i\"\n", ((int)cl_color.value) >> 4, ((int)cl_color.value) & 0x0f);
		Con_Printf ("color <0-13> [0-13]\n");
		return;
	}

	if (Cmd_Argc() == 2)
		top = bottom = atoi(Cmd_Argv(1));
	else
	{
		top = atoi(Cmd_Argv(1));
		bottom = atoi(Cmd_Argv(2));
	}
	
	top &= 15;
	if (top > 13)
		top = 13;
	bottom &= 15;
	if (bottom > 13)
		bottom = 13;
	
	playercolor = top*16 + bottom;

	if (cmd_source == src_command)
	{
		Cvar_SetValue ("_cl_color", playercolor);
		if (cls.state == ca_connected)
			Cmd_ForwardToServer ();
		return;
	}

	host_client->colors = playercolor;
	host_client->edict->v.team = bottom + 1;

// send notification to all clients
	MSG_WriteByte (&sv.reliable_datagram, svc_updatecolors);
	MSG_WriteByte (&sv.reliable_datagram, host_client - svs.clients);
	MSG_WriteByte (&sv.reliable_datagram, host_client->colors);
}

/*
==================
Host_Kill_f
==================
*/
void Host_Kill_f (void)
{
	if (cmd_source == src_command)
	{
		Cmd_ForwardToServer ();
		return;
	}

	if (sv_player->v.health <= 0)
	{
		SV_ClientPrintf ("Can't suicide -- allready dead!\n");
		return;
	}
	
	pr_global_struct->time = sv.time;
	pr_global_struct->self = EDICT_TO_PROG(sv_player);
	PR_ExecuteProgram (pr_global_struct->ClientKill);
}


/*
==================
Host_Pause_f
==================
*/
void Host_Pause_f (void)
{
	
	if (cmd_source == src_command)
	{
		Cmd_ForwardToServer ();
		return;
	}
	if (!pausable.value)
		SV_ClientPrintf ("Pause not allowed.\n");
	else
	{
		sv.paused ^= 1;

		if (sv.paused)
		{
			SV_BroadcastPrintf ("%s paused the game\n", pr_strings + sv_player->v.netname);
		}
		else
		{
			SV_BroadcastPrintf ("%s unpaused the game\n",pr_strings + sv_player->v.netname);
		}

	// send notification to all clients
		MSG_WriteByte (&sv.reliable_datagram, svc_setpause);
		MSG_WriteByte (&sv.reliable_datagram, sv.paused);
	}
}

//===========================================================================


/*
==================
Host_PreSpawn_f
==================
*/
void Host_PreSpawn_f (void)
{
	if (cmd_source == src_command)
	{
		Con_Printf ("prespawn is not valid from the console\n");
		return;
	}

	if (host_client->spawned)
	{
		Con_Printf ("prespawn not valid -- allready spawned\n");
		return;
	}
	
	SZ_Write (&host_client->message, sv.signon.data, sv.signon.cursize);
	MSG_WriteByte (&host_client->message, svc_signonnum);
	MSG_WriteByte (&host_client->message, 2);
	host_client->sendsignon = true;
}

/*
==================
Host_Spawn_f
==================
*/
void Host_Spawn_f (void)
{
	int		i;
	client_t	*client;
	edict_t	*ent;

	if (cmd_source == src_command)
	{
		Con_Printf ("spawn is not valid from the console\n");
		return;
	}

	if (host_client->spawned)
	{
		Con_Printf ("Spawn not valid -- allready spawned\n");
		return;
	}

// run the entrance script
	if (sv.loadgame)
	{	// loaded games are fully inited allready
		// if this is the last client to be connected, unpause
		sv.paused = false;
	}
	else
	{
		// set up the edict
		ent = host_client->edict;

		memset (&ent->v, 0, progs->entityfields * 4);
		ent->v.colormap = NUM_FOR_EDICT(ent);
		ent->v.team = (host_client->colors & 15) + 1;
		ent->v.netname = host_client->name - pr_strings;

		// copy spawn parms out of the client_t

		for (i=0 ; i< NUM_SPAWN_PARMS ; i++)
			(&pr_global_struct->parm1)[i] = host_client->spawn_parms[i];

		// call the spawn function

		pr_global_struct->time = sv.time;
		pr_global_struct->self = EDICT_TO_PROG(sv_player);
		PR_ExecuteProgram (pr_global_struct->ClientConnect);

		if ((Sys_FloatTime() - host_client->netconnection->connecttime) <= sv.time)
			Sys_Printf ("%s entered the game\n", host_client->name);

		PR_ExecuteProgram (pr_global_struct->PutClientInServer);	
	}


// send all current names, colors, and frag counts
	SZ_Clear (&host_client->message);

// send time of update
	MSG_WriteByte (&host_client->message, svc_time);
	MSG_WriteFloat (&host_client->message, sv.time);

	for (i=0, client = svs.clients ; i<svs.maxclients ; i++, client++)
	{
		MSG_WriteByte (&host_client->message, svc_updatename);
		MSG_WriteByte (&host_client->message, i);
		MSG_WriteString (&host_client->message, client->name);
		MSG_WriteByte (&host_client->message, svc_updatefrags);
		MSG_WriteByte (&host_client->message, i);
		MSG_WriteShort (&host_client->message, client->old_frags);
		MSG_WriteByte (&host_client->message, svc_updatecolors);
		MSG_WriteByte (&host_client->message, i);
		MSG_WriteByte (&host_client->message, client->colors);
	}
	
// send all current light styles
	for (i=0 ; i<MAX_LIGHTSTYLES ; i++)
	{
		MSG_WriteByte (&host_client->message, svc_lightstyle);
		MSG_WriteByte (&host_client->message, (char)i);
		MSG_WriteString (&host_client->message, sv.lightstyles[i]);
	}

//
// send some stats
//
	MSG_WriteByte (&host_client->message, svc_updatestat);
	MSG_WriteByte (&host_client->message, STAT_TOTALSECRETS);
	MSG_WriteLong (&host_client->message, pr_global_struct->total_secrets);

	MSG_WriteByte (&host_client->message, svc_updatestat);
	MSG_WriteByte (&host_client->message, STAT_TOTALMONSTERS);
	MSG_WriteLong (&host_client->message, pr_global_struct->total_monsters);

	MSG_WriteByte (&host_client->message, svc_updatestat);
	MSG_WriteByte (&host_client->message, STAT_SECRETS);
	MSG_WriteLong (&host_client->message, pr_global_struct->found_secrets);

	MSG_WriteByte (&host_client->message, svc_updatestat);
	MSG_WriteByte (&host_client->message, STAT_MONSTERS);
	MSG_WriteLong (&host_client->message, pr_global_struct->killed_monsters);

	
//
// send a fixangle
// Never send a roll angle, because savegames can catch the server
// in a state where it is expecting the client to correct the angle
// and it won't happen if the game was just loaded, so you wind up
// with a permanent head tilt
	ent = EDICT_NUM( 1 + (host_client - svs.clients) );
	MSG_WriteByte (&host_client->message, svc_setangle);
	for (i=0 ; i < 2 ; i++)
		MSG_WriteAngle (&host_client->message, ent->v.angles[i] );
	MSG_WriteAngle (&host_client->message, 0 );

	SV_WriteClientdataToMessage (sv_player, &host_client->message);

	MSG_WriteByte (&host_client->message, svc_signonnum);
	MSG_WriteByte (&host_client->message, 3);
	host_client->sendsignon = true;
}

/*
==================
Host_Begin_f
==================
*/
void Host_Begin_f (void)
{
	if (cmd_source == src_command)
	{
		Con_Printf ("begin is not valid from the console\n");
		return;
	}

	host_client->spawned = true;
}

//===========================================================================


/*
==================
Host_Kick_f

Kicks a user off of the server
==================
*/
void Host_Kick_f (void)
{
	char		*who;
	char		*message = NULL;
	client_t	*save;
	int			i;
	qboolean	byNumber = false;

	if (cmd_source == src_command)
	{
		if (!sv.active)
		{
			Cmd_ForwardToServer ();
			return;
		}
	}
	else if (pr_global_struct->deathmatch && !host_client->privileged)
		return;

	save = host_client;

	if (Cmd_Argc() > 2 && Q_strcmp(Cmd_Argv(1), "#") == 0)
	{
		i = Q_atof(Cmd_Argv(2)) - 1;
		if (i < 0 || i >= svs.maxclients)
			return;
		if (!svs.clients[i].active)
			return;
		host_client = &svs.clients[i];
		byNumber = true;
	}
	else
	{
		for (i = 0, host_client = svs.clients; i < svs.maxclients; i++, host_client++)
		{
			if (!host_client->active)
				continue;
			if (Q_strcasecmp(host_client->name, Cmd_Argv(1)) == 0)
				break;
		}
	}

	if (i < svs.maxclients)
	{
		if (cmd_source == src_command)
			if (cls.state == ca_dedicated)
				who = "Console";
			else
				who = cl_name.string;
		else
			who = save->name;

		// can't kick yourself!
		if (host_client == save)
			return;

		if (Cmd_Argc() > 2)
		{
			message = COM_Parse(Cmd_Args());
			if (byNumber)
			{
				message++;							// skip the #
				while (*message == ' ')				// skip white space
					message++;
				message += Q_strlen(Cmd_Argv(2));	// skip the number
			}
			while (*message && *message == ' ')
				message++;
		}
		if (message)
			SV_ClientPrintf ("Kicked by %s: %s\n", who, message);
		else
			SV_ClientPrintf ("Kicked by %s\n", who);
		SV_DropClient (false);
	}

	host_client = save;
}

/*
===============================================================================

DEBUGGING TOOLS

===============================================================================
*/

/*
==================
Host_Give_f
==================
*/
void Host_Give_f (void)
{
	char	*t;
	int		v, w;
	eval_t	*val;

	if (cmd_source == src_command)
	{
		Cmd_ForwardToServer ();
		return;
	}

	if (pr_global_struct->deathmatch && !host_client->privileged)
		return;

	t = Cmd_Argv(1);
	v = atoi (Cmd_Argv(2));
	
	switch (t[0])
	{
   case '0':
   case '1':
   case '2':
   case '3':
   case '4':
   case '5':
   case '6':
   case '7':
   case '8':
   case '9':
      // MED 01/04/97 added hipnotic give stuff
      if (hipnotic)
      {
         if (t[0] == '6')
         {
            if (t[1] == 'a')
               sv_player->v.items = (int)sv_player->v.items | HIT_PROXIMITY_GUN;
            else
               sv_player->v.items = (int)sv_player->v.items | IT_GRENADE_LAUNCHER;
         }
         else if (t[0] == '9')
            sv_player->v.items = (int)sv_player->v.items | HIT_LASER_CANNON;
         else if (t[0] == '0')
            sv_player->v.items = (int)sv_player->v.items | HIT_MJOLNIR;
         else if (t[0] >= '2')
            sv_player->v.items = (int)sv_player->v.items | (IT_SHOTGUN << (t[0] - '2'));
      }
      else
      {
         if (t[0] >= '2')
            sv_player->v.items = (int)sv_player->v.items | (IT_SHOTGUN << (t[0] - '2'));
      }
		break;
	
    case 's':
		if (rogue)
		{
	        val = GetEdictFieldValue(sv_player, "ammo_shells1");
		    if (val)
			    val->_float = v;
		}

        sv_player->v.ammo_shells = v;
        break;		
    case 'n':
		if (rogue)
		{
			val = GetEdictFieldValue(sv_player, "ammo_nails1");
			if (val)
			{
				val->_float = v;
				if (sv_player->v.weapon <= IT_LIGHTNING)
					sv_player->v.ammo_nails = v;
			}
		}
		else
		{
			sv_player->v.ammo_nails = v;
		}
        break;		
    case 'l':
		if (rogue)
		{
			val = GetEdictFieldValue(sv_player, "ammo_lava_nails");
			if (val)
			{
				val->_float = v;
				if (sv_player->v.weapon > IT_LIGHTNING)
					sv_player->v.ammo_nails = v;
			}
		}
        break;
    case 'r':
		if (rogue)
		{
			val = GetEdictFieldValue(sv_player, "ammo_rockets1");
			if (val)
			{
				val->_float = v;
				if (sv_player->v.weapon <= IT_LIGHTNING)
					sv_player->v.ammo_rockets = v;
			}
		}
		else
		{
			sv_player->v.ammo_rockets = v;
		}
        break;		
    case 'm':
		if (rogue)
		{
			val = GetEdictFieldValue(sv_player, "ammo_multi_rockets");
			if (val)
			{
				val->_float = v;
				if (sv_player->v.weapon > IT_LIGHTNING)
					sv_player->v.ammo_rockets = v;
			}
		}
        break;		
    case 'h':
        sv_player->v.health = v;
        break;		
    case 'c':
		if (rogue)
		{
			val = GetEdictFieldValue(sv_player, "ammo_cells1");
			if (val)
			{
				val->_float = v;
				if (sv_player->v.weapon <= IT_LIGHTNING)
					sv_player->v.ammo_cells = v;
			}
		}
		else
		{
			sv_player->v.ammo_cells = v;
		}
        break;		
    case 'p':
		if (rogue)
		{
			val = GetEdictFieldValue(sv_player, "ammo_plasma");
			if (val)
			{
				val->_float = v;
				if (sv_player->v.weapon > IT_LIGHTNING)
					sv_player->v.ammo_cells = v;
			}
		}
        break;		
    }
}

edict_t	*FindViewthing (void)
{
	int		i;
	edict_t	*e;
	
	for (i=0 ; i<sv.num_edicts ; i++)
	{
		e = EDICT_NUM(i);
		if ( !strcmp (pr_strings + e->v.classname, "viewthing") )
			return e;
	}
	Con_Printf ("No viewthing on map\n");
	return NULL;
}

/*
==================
Host_Viewmodel_f
==================
*/
void Host_Viewmodel_f (void)
{
	edict_t	*e;
	model_t	*m;

	e = FindViewthing ();
	if (!e)
		return;

	m = Mod_ForName (Cmd_Argv(1), false);
	if (!m)
	{
		Con_Printf ("Can't load %s\n", Cmd_Argv(1));
		return;
	}
	
	e->v.frame = 0;
	cl.model_precache[(int)e->v.modelindex] = m;
}

/*
==================
Host_Viewframe_f
==================
*/
void Host_Viewframe_f (void)
{
	edict_t	*e;
	int		f;
	model_t	*m;

	e = FindViewthing ();
	if (!e)
		return;
	m = cl.model_precache[(int)e->v.modelindex];

	f = atoi(Cmd_Argv(1));
	if (f >= m->numframes)
		f = m->numframes-1;

	e->v.frame = f;		
}


void PrintFrameName (model_t *m, int frame)
{
	aliashdr_t 			*hdr;
	maliasframedesc_t	*pframedesc;

	hdr = (aliashdr_t *)Mod_Extradata (m);
	if (!hdr)
		return;
	pframedesc = &hdr->frames[frame];
	
	Con_Printf ("frame %i: %s\n", frame, pframedesc->name);
}

/*
==================
Host_Viewnext_f
==================
*/
void Host_Viewnext_f (void)
{
	edict_t	*e;
	model_t	*m;
	
	e = FindViewthing ();
	if (!e)
		return;
	m = cl.model_precache[(int)e->v.modelindex];

	e->v.frame = e->v.frame + 1;
	if (e->v.frame >= m->numframes)
		e->v.frame = m->numframes - 1;

	PrintFrameName (m, e->v.frame);		
}

/*
==================
Host_Viewprev_f
==================
*/
void Host_Viewprev_f (void)
{
	edict_t	*e;
	model_t	*m;

	e = FindViewthing ();
	if (!e)
		return;

	m = cl.model_precache[(int)e->v.modelindex];

	e->v.frame = e->v.frame - 1;
	if (e->v.frame < 0)
		e->v.frame = 0;

	PrintFrameName (m, e->v.frame);		
}

/*
===============================================================================

DEMO LOOP CONTROL

===============================================================================
*/


/*
==================
Host_Startdemos_f
==================
*/
void Host_Startdemos_f (void)
{
	int		i, c;

	if (cls.state == ca_dedicated)
	{
		if (!sv.active)
			Cbuf_AddText ("map start\n");
		return;
	}

	c = Cmd_Argc() - 1;
	if (c > MAX_DEMOS)
	{
		Con_Printf ("Max %i demos in demoloop\n", MAX_DEMOS);
		c = MAX_DEMOS;
	}
	Con_Printf ("%i demo(s) in loop\n", c);

	for (i=1 ; i<c+1 ; i++)
		strncpy (cls.demos[i-1], Cmd_Argv(i), sizeof(cls.demos[0])-1);

	if (!sv.active && cls.demonum != -1 && !cls.demoplayback)
	{
		cls.demonum = 0;
		CL_NextDemo ();
	}
	else
		cls.demonum = -1;
}


/*
==================
Host_Demos_f

Return to looping demos
==================
*/
void Host_Demos_f (void)
{
	if (cls.state == ca_dedicated)
		return;
	if (cls.demonum == -1)
		cls.demonum = 1;
	CL_Disconnect_f ();
	CL_NextDemo ();
}

/*
==================
Host_Stopdemo_f

Return to looping demos
==================
*/
void Host_Stopdemo_f (void)
{
	if (cls.state == ca_dedicated)
		return;
	if (!cls.demoplayback)
		return;
	CL_StopPlayback ();
	CL_Disconnect ();
}

//=============================================================================

/*
==================
Host_InitCommands
==================
*/
#ifdef BENCH486
#include "tests/bench486/bench486_gameplay_profile.inc"
#endif

static void Host_Meminfo_f (void)
{
	Con_Printf ("Memory budget (bytes; cache and video allocations are inside the engine block)\n");
	Con_Printf ("Engine block: supplied=%d minimum=%d%s\n",
			host_parms.memsize, minimum_memory,
			COM_CheckParm ("-minmemory") ? " (-minmemory)" : "");
	Memory_ReportBudget ();
	VID_ReportMemoryBudget ();
	R_ReportMemoryBudget ();
}

void Host_InitCommands (void)
{
	Cmd_AddCommand ("status", Host_Status_f);
	Cmd_AddCommand ("meminfo", Host_Meminfo_f);
	Cmd_AddCommand ("quit", Host_Quit_f);
	Cmd_AddCommand ("god", Host_God_f);
	Cmd_AddCommand ("notarget", Host_Notarget_f);
	Cmd_AddCommand ("fly", Host_Fly_f);
	Cmd_AddCommand ("map", Host_Map_f);
	Cmd_AddCommand ("restart", Host_Restart_f);
	Cmd_AddCommand ("changelevel", Host_Changelevel_f);
#ifdef QUAKE2
	Cmd_AddCommand ("changelevel2", Host_Changelevel2_f);
#endif
	Cmd_AddCommand ("connect", Host_Connect_f);
	Cmd_AddCommand ("reconnect", Host_Reconnect_f);
	Cmd_AddCommand ("name", Host_Name_f);
	Cmd_AddCommand ("noclip", Host_Noclip_f);
	Cmd_AddCommand ("version", Host_Version_f);
#ifdef IDGODS
	Cmd_AddCommand ("please", Host_Please_f);
#endif
	Cmd_AddCommand ("say", Host_Say_f);
	Cmd_AddCommand ("say_team", Host_Say_Team_f);
	Cmd_AddCommand ("tell", Host_Tell_f);
	Cmd_AddCommand ("color", Host_Color_f);
	Cmd_AddCommand ("kill", Host_Kill_f);
	Cmd_AddCommand ("pause", Host_Pause_f);
	Cmd_AddCommand ("spawn", Host_Spawn_f);
	Cmd_AddCommand ("begin", Host_Begin_f);
	Cmd_AddCommand ("prespawn", Host_PreSpawn_f);
	Cmd_AddCommand ("kick", Host_Kick_f);
	Cmd_AddCommand ("ping", Host_Ping_f);
	Cmd_AddCommand ("load", Host_Loadgame_f);
	Cmd_AddCommand ("save", Host_Savegame_f);
	Cmd_AddCommand ("give", Host_Give_f);

	Cmd_AddCommand ("startdemos", Host_Startdemos_f);
	Cmd_AddCommand ("demos", Host_Demos_f);
	Cmd_AddCommand ("stopdemo", Host_Stopdemo_f);

	Cmd_AddCommand ("viewmodel", Host_Viewmodel_f);
	Cmd_AddCommand ("viewframe", Host_Viewframe_f);
	Cmd_AddCommand ("viewnext", Host_Viewnext_f);
	Cmd_AddCommand ("viewprev", Host_Viewprev_f);

	Cmd_AddCommand ("mcache", Mod_Print);
#ifdef BENCH486
	Cmd_AddCommand ("bench486", Bench486_f);
	Cmd_AddCommand ("benchprofile", Bench486Gameplay_f);
	Cmd_AddCommand ("bench486_renderpolys", Bench486RenderPolys_f);
#endif
}

#if defined(BENCH486) && defined(ASM486_VESA_LIFECYCLE_FIXTURE)
#include "tests/bench486/bench486_vesalifecycle.h"
#endif
#if defined(BENCH486) && defined(ASM486_VESA_WAIT_FIXTURE)
#include "video/vid_dos.h"
#include "video/asm_vesawait.h"
#include "tests/bench486/bench486_vesawait.h"
#endif
