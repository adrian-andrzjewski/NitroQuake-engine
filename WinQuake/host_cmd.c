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

#include "quakedef.h"

#ifdef BENCH486
#include "d_local.h"
#include "r_local.h"
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

#ifdef PROFILE486
int bench486_profile_frame_active;
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
unsigned long bench486_renderface_emitted;
unsigned long bench486_clipedge_calls;
unsigned long bench486_emitcachededge_calls;
unsigned long bench486_clipvert_clips;
// R_RenderFace premise counters. The admissible part of renderface is its C
// scaffolding; the inadmissible part is the assembly clipper's x87 chain.
// These price the population split before any probe is built: edges that hit
// the edge cache do no clipping at all, so their cost is pure C.
unsigned long bench486_renderface_edge_setups;
unsigned long bench486_renderface_early_surfs;
unsigned long bench486_renderface_early_edges;
unsigned long bench486_renderface_faces;
unsigned long bench486_texture_full_tzero;
unsigned long bench486_texture_full_tdelta_zero;
unsigned long bench486_texture_full_tfrac_zero;
unsigned long bench486_texture_full_sfrac_zero;
unsigned long bench486_texture_full_sone;
unsigned long bench486_texture_full_exact;
unsigned long bench486_texture_final_exact;
unsigned long bench486_texture_full_row_eligible;
unsigned long bench486_texture_full_row_fast;
// Unit-stride span premise. bench486_span_segments is every sixteen-wide
// segment the span drawer sets up; the other two are the subset whose t step
// has no whole texel, whose s step is exactly one texel and whose s step has
// no fractional part, so the source advances one byte per sample with no
// carry. Only the pixel count can be priced.
unsigned long bench486_span_segments;
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
	"cd-audio"
};
#endif

extern void D_PolysetSetUpForLineScan (fixed8_t startvertu,
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
static unsigned long bench486_timedemo_measured_frames;
static unsigned long bench486_timedemo_stored_frames;
static unsigned long bench486_timedemo_overflow_frames;
static unsigned long bench486_timedemo_invalid_frames;
static unsigned long bench486_timedemo_timer_reads;
static qboolean bench486_timedemo_stats_enabled;
static qboolean bench486_timedemo_stats_active;
static qboolean bench486_timedemo_frame_started;
static double bench486_timedemo_frame_start;

static void Bench486TimedemoRecordFrame (double seconds)
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
	bench486_timedemo_frame_seconds[bench486_timedemo_stored_frames++] =
			(float)seconds;
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
}

void Bench486BeginTimedemoStats (void)
{
	if (bench486_timedemo_stats_enabled)
		bench486_timedemo_stats_active = true;
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
	Bench486TimedemoRecordFrame (now - bench486_timedemo_frame_start);
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
	bench486_timedemo_fps_stats_t stats;

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

	if (!bench486_profile_frame_active)
		return;

	if (node < 0 || node >= BENCH486_PROFILE_NODE_COUNT)
	{
		bench486_profile_bad_leaves++;
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

	if (!bench486_profile_frame_active)
		return;

	if (bench486_profile_pending_leaves)
	{
		bench486_profile_pending_leaves--;
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
			"    \"texture_spans\": %lu, \"texture_pixels\": %lu, \"texture_segments\": %lu, \"alias_models\": %lu, \"alias_vertices\": %lu, \"particles\": %lu, \"gib_trail_particles\": %lu,\n"
			"    \"present_rects\": %lu, \"present_pixels\": %lu, \"sound_updates\": %lu, \"sound_mixes\": %lu,\n"
			"    \"renderface_calls\": %lu, \"renderface_emitted\": %lu, \"clipedge_calls\": %lu, \"emitcachededge_calls\": %lu,\n"
			"    \"texture_span_buckets\": [%lu, %lu, %lu, %lu, %lu],\n"
			"    \"texture_widths\": [%lu, %lu, %lu, %lu, %lu, %lu, %lu, %lu, %lu, %lu, %lu, %lu, %lu, %lu, %lu, %lu, %lu],\n"
			"    \"texture_final_lengths\": [%lu, %lu, %lu, %lu, %lu, %lu, %lu, %lu, %lu, %lu, %lu, %lu, %lu, %lu, %lu, %lu, %lu],\n"
			"    \"texture_full\": {\"tzero\": %lu, \"tdelta_zero\": %lu, \"tfrac_zero\": %lu, \"sfrac_zero\": %lu, \"sone\": %lu, \"exact\": %lu, \"final_exact\": %lu, \"row_eligible\": %lu, \"row_fast\": %lu},\n"
			"    \"span_strides\": {\"segments\": %lu, \"unit_stride_segments\": %lu, \"unit_stride_pixels\": %lu}\n"
			"  }\n}\n",
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
			bench486_texture_span_count, bench486_texture_span_pixels,
			bench486_texture_span_segments, bench486_alias_models,
			bench486_alias_vertices, bench486_particle_count,
			bench486_gib_trail_particles,
			bench486_present_rects, bench486_present_pixels,
			bench486_sound_update_calls, bench486_sound_mix_calls,
			bench486_renderface_calls, bench486_renderface_emitted,
			bench486_clipedge_calls, bench486_emitcachededge_calls,
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
			bench486_span_unit_stride_pixels);
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
	bench486_texture_span_pixels = 0;
	bench486_texture_span_segments = 0;
	bench486_texture_span_buckets[0] = 0;
	bench486_texture_span_buckets[1] = 0;
	bench486_texture_span_buckets[2] = 0;
	bench486_texture_span_buckets[3] = 0;
	bench486_texture_span_buckets[4] = 0;
	bench486_renderface_calls = 0;
	bench486_renderface_emitted = 0;
	bench486_renderface_edge_setups = 0;
	bench486_renderface_early_surfs = 0;
	bench486_renderface_early_edges = 0;
	bench486_renderface_faces = 0;
	bench486_clipedge_calls = 0;
	bench486_emitcachededge_calls = 0;
	bench486_clipvert_clips = 0;
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
	bench486_span_segments = 0;
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
	bench486_profile_frame_active = true;
	Bench486ProfileEnter (BENCH486_PROFILE_FRAME);
	bench486_profile_pending_leaves = 1;
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
	sprintf (text,
			"profile-work renderface-calls %lu renderface-emitted %lu "
			"clipedge-calls %lu emitcached-calls %lu\n",
			bench486_renderface_calls, bench486_renderface_emitted,
			bench486_clipedge_calls, bench486_emitcachededge_calls);
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
	char	text[64];
	unsigned checksum;

	checksum = vid.buffer ? Bench486Checksum ((byte *)vid.buffer,
			(int)(vid.rowbytes * vid.height)) : 0;
	sprintf (text, "framebuffer-checksum %u\n", checksum);
	Con_Printf ("%s", text);
	if (report_handle != -1)
		Sys_FileWrite (report_handle, text, Q_strlen(text));
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
		int surface_dlightframe, int frame, void *texture, int *lightadj);
typedef int (*bench486_mip_fn_t) (float scale);
typedef void (*bench486_turbulent_fn_t) (void);
typedef void (*bench486_alias_project_fn_t) (finalvert_t *fv, auxvert_t *av);
typedef texture_t *(*bench486_texture_animation_fn_t) (texture_t *base,
		int relative);
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

static void Bench486AliasBBoxProjectCases (void)
{
	Bench486AliasBBoxProjectCase ("inside", 8, 0x0000, 0);
	Bench486AliasBBoxProjectCase ("mixed", 8, 0x0000, 1);
	Bench486AliasBBoxProjectCase ("z-clipped", 16, 0xaaaa, 1);
	Bench486AliasBBoxProjectCase ("all-left", 8, 0x0000, 2);
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
	r_plightvec[0] = 0.0;
	r_plightvec[1] = 0.0;
	r_plightvec[2] = lightmode == 0 ? 1.0 : -1.0;
	r_ambientlight = lightmode == 2 ? 32 : 96;
	r_shadelight = lightmode == 2 ? 160.0 : 64.0;

	pverts.v[0] = 12;
	pverts.v[1] = 34;
	pverts.v[2] = 56;
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
		int *lightadj, int iterations, unsigned *hits)
{
	double start, elapsed;
	int i;
	unsigned hit_count;
	void *result;

	for (i=0 ; i<BENCH486_MEMORY_WARMUP ; i++)
		function (cache, surface_dlightframe, frame, texture, lightadj);

	start = Sys_FloatTime ();
	hit_count = 0;
	for (i=0 ; i<iterations ; i++)
	{
		result = function (cache, surface_dlightframe, frame, texture,
				lightadj);
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
		qboolean expected_hit)
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
					texture, lightadj, BENCH486_SURFACE_CACHE_ITERATIONS,
					&c_hits);
			asm_samples[sample] = Bench486MeasureSurfaceCache(
					D_CacheSurfaceHit_asm486, cache, surface_dlightframe, frame,
					texture, lightadj, BENCH486_SURFACE_CACHE_ITERATIONS,
					&asm_hits);
		}
		else
		{
			asm_samples[sample] = Bench486MeasureSurfaceCache(
					D_CacheSurfaceHit_asm486, cache, surface_dlightframe, frame,
					texture, lightadj, BENCH486_SURFACE_CACHE_ITERATIONS,
					&asm_hits);
			c_samples[sample] = Bench486MeasureSurfaceCache(
					D_CacheSurfaceHit_C, cache, surface_dlightframe, frame,
					texture, lightadj, BENCH486_SURFACE_CACHE_ITERATIONS,
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
	int lightadj[MAXLIGHTMAPS];
	int other_lightadj[MAXLIGHTMAPS];
	texture_t texture, other_texture;
	void *expected;
	void *c_result;
	void *asm_result;
	int i;

	Q_memset (&cache, 0, sizeof(cache));
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
	c_result = D_CacheSurfaceHit_C (&cache, 17, 23, &texture, lightadj);
	asm_result = D_CacheSurfaceHit_asm486 (&cache, 17, 23, &texture,
			lightadj);
	if (c_result != expected || asm_result != expected)
		bench486_memory_failures++;

	expected = NULL;
	c_result = D_CacheSurfaceHit_C (NULL, 17, 23, &texture, lightadj);
	asm_result = D_CacheSurfaceHit_asm486 (NULL, 17, 23, &texture,
			lightadj);
	if (c_result != expected || asm_result != expected)
		bench486_memory_failures++;

	cache.dlight = 1;
	c_result = D_CacheSurfaceHit_C (&cache, 17, 23, &texture, lightadj);
	asm_result = D_CacheSurfaceHit_asm486 (&cache, 17, 23, &texture,
			lightadj);
	if (c_result != expected || asm_result != expected)
		bench486_memory_failures++;
	cache.dlight = 0;

	c_result = D_CacheSurfaceHit_C (&cache, 23, 23, &texture, lightadj);
	asm_result = D_CacheSurfaceHit_asm486 (&cache, 23, 23, &texture,
			lightadj);
	if (c_result != expected || asm_result != expected)
		bench486_memory_failures++;

	c_result = D_CacheSurfaceHit_C (&cache, 17, 23, &other_texture, lightadj);
	asm_result = D_CacheSurfaceHit_asm486 (&cache, 17, 23, &other_texture,
			lightadj);
	if (c_result != expected || asm_result != expected)
		bench486_memory_failures++;

	for (i=0 ; i<MAXLIGHTMAPS ; i++)
	{
		other_lightadj[i] = lightadj[i] + 1;
		c_result = D_CacheSurfaceHit_C (&cache, 17, 23, &texture,
				other_lightadj);
		asm_result = D_CacheSurfaceHit_asm486 (&cache, 17, 23, &texture,
				other_lightadj);
		if (c_result != expected || asm_result != expected)
			bench486_memory_failures++;
		other_lightadj[i] = lightadj[i];
	}

	Bench486SurfaceCacheTimingCase ("hit", &cache, 17, 23, &texture,
			lightadj, true);
	Bench486SurfaceCacheTimingCase ("miss-texture", &cache, 17, 23,
			&other_texture, lightadj, false);
	cache.dlight = 1;
	Bench486SurfaceCacheTimingCase ("miss-cache-dlight", &cache, 17, 23,
			&texture, lightadj, false);
	cache.dlight = 0;
}

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
	int c_result, asm_result;
	int sample;

	expected = (unsigned)D_MipLevelForScale_C (scale);
	c_result = D_MipLevelForScale_C (scale);
	asm_result = D_MipLevelForScale_asm486 (scale);
	if ((unsigned)c_result != expected || (unsigned)asm_result != expected)
	{
		bench486_memory_failures++;
		Bench486Printf ("mip %s correctness FAIL scale %.6f expected %u c %d asm %d\n",
				name, scale, expected, c_result, asm_result);
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

static void Bench486FillCase (void)
{
	vrect_t	rect;
	int		i;
	double		start, elapsed, rate;
	unsigned	checksum;

	if (!vid.buffer)
	{
		Bench486Printf ("fill-rect skipped: no video buffer\n");
		return;
	}

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

static void Bench486_f (void)
{
	bench486_report_handle = Sys_FileOpenWrite ("bench486.txt");
	if (bench486_report_handle == -1)
		Con_Printf ("bench486: could not create bench486.txt\n");

	Bench486Printf ("486 benchmark begin\n");
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
	if (COM_CheckParm ("-benchtextureanimation"))
	{
		Bench486Printf ("texture-animation experiment compares the C frame loop\n");
		Bench486Printf ("with a register-only 486 pointer/branch loop\n");
		Bench486TextureAnimationCases ();
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
	Bench486Printf ("memory experiment compares existing C helpers with\n");
	Bench486Printf ("separate forward-copy and byte-fill 486 assembly paths\n");
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
	Bench486Printf ("texture-axis experiment compares the C cache-key probe with\n");
	Bench486Printf ("the isolated 486 assembly fast-hit/miss probe\n");
	Bench486TextureAxisCase ();
	Bench486Printf ("surface-cache experiment compares the C cache-validity predicate\n");
	Bench486Printf ("with the isolated 486 assembly fast-hit/miss predicate\n");
	Bench486SurfaceCacheCase ();
	Bench486Printf ("mip-level experiment compares the C threshold selector with\n");
	Bench486Printf ("the isolated 486 x87 threshold selector\n");
	Bench486MipCases ();
	Bench486Printf ("turbulent-span experiment compares the C inner loop with\n");
	Bench486Printf ("the current and optional STOSB 486 sequential-store loop\n");
	Bench486TurbulentCases ();
	Bench486Printf ("texture-animation experiment compares the C frame loop with\n");
	Bench486Printf ("the register-only 486 pointer/branch loop\n");
	Bench486TextureAnimationCases ();
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
	Bench486Printf ("alias-transform-final experiment compares the C clipped vertex helper with\n");
	Bench486Printf ("the register-held 486 x87 transform and lighting helper\n");
	Bench486AliasTransformFinalCases ();
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
	print ("version: %4.2f\n", VERSION);
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
	Con_Printf ("Version %4.2f\n", VERSION);
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
void Host_InitCommands (void)
{
	Cmd_AddCommand ("status", Host_Status_f);
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
#endif
}
