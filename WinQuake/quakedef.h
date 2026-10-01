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
// quakedef.h -- primary header for client

//#define	GLTEST			// experimental stuff

#define	QUAKE_GAME			// as opposed to utilities

#define	VERSION				1.09

//define	PARANOID			// speed sapping error checking

#ifdef QUAKE2
#define	GAMENAME	"id1"		// directory to look in by default
#else
#define	GAMENAME	"id1"
#endif

#include <math.h>
#include <string.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <setjmp.h>

#define	VID_LockBuffer()
#define	VID_UnlockBuffer()

#if defined __i386__
#define id386	1
#else
#define id386	0
#endif

#if id386
#define UNALIGNED_OK	1	// set to 0 if unaligned accesses are not supported
#else
#define UNALIGNED_OK	0
#endif

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
	BENCH486_PROFILE_NODE_COUNT
} bench486_profile_node_id_t;

extern int bench486_profile_frame_active;
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
void Bench486FinishTimedemoStats (int timedemo_frames);
void Bench486WriteTimedemoStats (int report_handle, int timedemo_frames,
		double timedemo_seconds);
#endif

// !!! if this is changed, it must be changed in d_ifacea.h too !!!
#define CACHE_SIZE	32		// used to align key data structures

#define UNUSED(x)	(x = x)	// for pesky compiler / lint warnings

#define	MINIMUM_MEMORY			0x550000
#define	MINIMUM_MEMORY_LEVELPAK	(MINIMUM_MEMORY + 0x100000)

#define MAX_NUM_ARGVS	50

// up / down
#define	PITCH	0

// left / right
#define	YAW		1

// fall over
#define	ROLL	2


#define	MAX_QPATH		64			// max length of a quake game pathname
#define	MAX_OSPATH		128			// max length of a filesystem pathname

#define	ON_EPSILON		0.1			// point on plane side epsilon

#define	MAX_MSGLEN		8000		// max length of a reliable message
#define	MAX_DATAGRAM	1024		// max length of unreliable message

//
// per-level limits
//
#define	MAX_EDICTS		600			// FIXME: ouch! ouch! ouch!
#define	MAX_LIGHTSTYLES	64
#define	MAX_MODELS		256			// these are sent over the net as bytes
#define	MAX_SOUNDS		256			// so they cannot be blindly increased

#define	SAVEGAME_COMMENT_LENGTH	39

#define	MAX_STYLESTRING	64

//
// stats are integers communicated to the client by the server
//
#define	MAX_CL_STATS		32
#define	STAT_HEALTH			0
#define	STAT_FRAGS			1
#define	STAT_WEAPON			2
#define	STAT_AMMO			3
#define	STAT_ARMOR			4
#define	STAT_WEAPONFRAME	5
#define	STAT_SHELLS			6
#define	STAT_NAILS			7
#define	STAT_ROCKETS		8
#define	STAT_CELLS			9
#define	STAT_ACTIVEWEAPON	10
#define	STAT_TOTALSECRETS	11
#define	STAT_TOTALMONSTERS	12
#define	STAT_SECRETS		13		// bumped on client side by svc_foundsecret
#define	STAT_MONSTERS		14		// bumped by svc_killedmonster

// stock defines

#define	IT_SHOTGUN				1
#define	IT_SUPER_SHOTGUN		2
#define	IT_NAILGUN				4
#define	IT_SUPER_NAILGUN		8
#define	IT_GRENADE_LAUNCHER		16
#define	IT_ROCKET_LAUNCHER		32
#define	IT_LIGHTNING			64
#define IT_SUPER_LIGHTNING      128
#define IT_SHELLS               256
#define IT_NAILS                512
#define IT_ROCKETS              1024
#define IT_CELLS                2048
#define IT_AXE                  4096
#define IT_ARMOR1               8192
#define IT_ARMOR2               16384
#define IT_ARMOR3               32768
#define IT_SUPERHEALTH          65536
#define IT_KEY1                 131072
#define IT_KEY2                 262144
#define	IT_INVISIBILITY			524288
#define	IT_INVULNERABILITY		1048576
#define	IT_SUIT					2097152
#define	IT_QUAD					4194304
#define IT_SIGIL1               (1<<28)
#define IT_SIGIL2               (1<<29)
#define IT_SIGIL3               (1<<30)
#define IT_SIGIL4               (1<<31)

//===========================================
//rogue changed and added defines

#define RIT_SHELLS              128
#define RIT_NAILS               256
#define RIT_ROCKETS             512
#define RIT_CELLS               1024
#define RIT_AXE                 2048
#define RIT_LAVA_NAILGUN        4096
#define RIT_LAVA_SUPER_NAILGUN  8192
#define RIT_MULTI_GRENADE       16384
#define RIT_MULTI_ROCKET        32768
#define RIT_PLASMA_GUN          65536
#define RIT_ARMOR1              8388608
#define RIT_ARMOR2              16777216
#define RIT_ARMOR3              33554432
#define RIT_LAVA_NAILS          67108864
#define RIT_PLASMA_AMMO         134217728
#define RIT_MULTI_ROCKETS       268435456
#define RIT_SHIELD              536870912
#define RIT_ANTIGRAV            1073741824
#define RIT_SUPERHEALTH         2147483648

//MED 01/04/97 added hipnotic defines
//===========================================
//hipnotic added defines
#define HIT_PROXIMITY_GUN_BIT 16
#define HIT_MJOLNIR_BIT       7
#define HIT_LASER_CANNON_BIT  23
#define HIT_PROXIMITY_GUN   (1<<HIT_PROXIMITY_GUN_BIT)
#define HIT_MJOLNIR         (1<<HIT_MJOLNIR_BIT)
#define HIT_LASER_CANNON    (1<<HIT_LASER_CANNON_BIT)
#define HIT_WETSUIT         (1<<(23+2))
#define HIT_EMPATHY_SHIELDS (1<<(23+3))

//===========================================

#define	MAX_SCOREBOARD		16
#define	MAX_SCOREBOARDNAME	32

#define	SOUND_CHANNELS		8

// This makes anyone on id's net privileged
// Use for multiplayer testing only - VERY dangerous!!!
// #define IDGODS

#include "common.h"
#include "bspfile.h"
#include "vid.h"
#include "sys.h"
#include "zone.h"
#include "mathlib.h"

typedef struct
{
	vec3_t	origin;
	vec3_t	angles;
	int		modelindex;
	int		frame;
	int		colormap;
	int		skin;
	int		effects;
} entity_state_t;


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

//=============================================================================

// the host system specifies the base of the directory tree, the
// command line parms passed to the program, and the amount of memory
// available for the program to use

typedef struct
{
	char	*basedir;
	char	*cachedir;		// for development over ISDN lines
	int		argc;
	char	**argv;
	void	*membase;
	int		memsize;
} quakeparms_t;


//=============================================================================



extern qboolean noclip_anglehack;


//
// host
//
extern	quakeparms_t host_parms;

extern	cvar_t		sys_ticrate;
extern	cvar_t		sys_nostdout;
extern	cvar_t		developer;

extern	qboolean	host_initialized;		// true if into command execution
extern	double		host_frametime;
extern	byte		*host_basepal;
extern	byte		*host_colormap;
extern	int			host_framecount;	// incremented every frame, never reset
extern	double		realtime;			// not bounded in any way, changed at
										// start of every frame, never reset

void Host_ClearMemory (void);
void Host_ServerFrame (void);
void Host_InitCommands (void);
void Host_Init (quakeparms_t *parms);
void Host_Shutdown(void);
void Host_Error (char *error, ...);
void Host_EndGame (char *message, ...);
void Host_Frame (float time);
void Host_Quit_f (void);
void Host_ClientCommands (char *fmt, ...);
void Host_ShutdownServer (qboolean crash);

extern qboolean		msg_suppress_1;		// suppresses resolution and cache size console output
										//  an fullscreen DIB focus gain/loss
extern int			current_skill;		// skill level for currently loaded level (in case
										//  the user changes the cvar while the level is
										//  running, this reflects the level actually in use)

extern qboolean		isDedicated;

extern int			minimum_memory;

//
// chase
//
extern	cvar_t	chase_active;

void Chase_Init (void);
void Chase_Reset (void);
void Chase_Update (void);
