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
// r_misc.c

#include "render.h"
#include "client.h"
#include "view.h"
#include "server.h"
#include "host.h"
#include "screen.h"
#include "bspfile.h"
#include "model.h"
#include "d_iface.h"
#include "console.h"
#include "sys.h"
#include "cvar.h"
#include "renderer/r_local.h"
#include <stddef.h>
#include "renderer/asm_draw.h"
#include "renderer/asm_timegraph.h"
#include "renderer/r_timegraph_state.h"
#include "renderer/asm_frustum.h"
#include "renderer/asm_transformplane.h"
#include "client/asm_viewcontrol.h"


/*
===============
R_CheckVariables
===============
*/
#if defined(ASM486_VIEW_CONTROL) && defined(BENCH486)
float bench486_rcheck_oldbright_c;
extern void Bench486ViewControlFlushCaches (void);
#endif

#if !defined(ASM486_VIEW_CONTROL) || defined(BENCH486)
#if defined(ASM486_VIEW_CONTROL)
void R_CheckVariables_View_C (void)
#else
void R_CheckVariables (void)
#endif
{
#if defined(ASM486_VIEW_CONTROL) && defined(BENCH486)
	if (r_fullbright.value != bench486_rcheck_oldbright_c)
	{
		bench486_rcheck_oldbright_c = r_fullbright.value;
		Bench486ViewControlFlushCaches ();
	}
#else
	static float	oldbright;

	if (r_fullbright.value != oldbright)
	{
		oldbright = r_fullbright.value;
		D_FlushCaches ();	// so all lighting changes
	}
#endif
}
#endif


/*
============
Show

Debugging use
============
*/
void Show (void)
{
	vrect_t	vr;

	vr.x = vr.y = 0;
	vr.width = vid.width;
	vr.height = vid.height;
	vr.pnext = NULL;
	VID_Update (&vr);
}


/*
====================
R_TimeRefresh_f

For program optimization
====================
*/
void R_TimeRefresh_f (void)
{
	int			i;
	float		start, stop, time;
	int			startangle;
	vrect_t		vr;

	startangle = r_refdef.viewangles[1];
	
	start = Sys_FloatTime ();
	for (i=0 ; i<128 ; i++)
	{
		r_refdef.viewangles[1] = i/128.0*360.0;

		VID_LockBuffer ();

		R_RenderView ();

		VID_UnlockBuffer ();

		vr.x = r_refdef.vrect.x;
		vr.y = r_refdef.vrect.y;
		vr.width = r_refdef.vrect.width;
		vr.height = r_refdef.vrect.height;
		vr.pnext = NULL;
		VID_Update (&vr);
	}
	stop = Sys_FloatTime ();
	time = stop-start;
	Con_Printf ("%f seconds (%f fps)\n", time, 128/time);
	
	r_refdef.viewangles[1] = startangle;
}


/*
================
R_LineGraph

Only called by R_TimeGraph
================
*/
#if defined(ASM486_LINE_GRAPH)
typedef char linegraph_vid_buffer_must_match[
	(offsetof(viddef_t, buffer) == LG_VID_BUFFER) ? 1 : -1];
typedef char linegraph_vid_rowbytes_must_match[
	(offsetof(viddef_t, rowbytes) == LG_VID_ROWBYTES) ? 1 : -1];
typedef char linegraph_refdef_vrect_x_must_match[
	(offsetof(refdef_t, vrect.x) == LG_REFDEF_VRECT_X) ? 1 : -1];
typedef char linegraph_refdef_vrect_y_must_match[
	(offsetof(refdef_t, vrect.y) == LG_REFDEF_VRECT_Y) ? 1 : -1];
typedef char linegraph_cvar_value_must_match[
	(offsetof(cvar_t, value) == LG_CVAR_VALUE) ? 1 : -1];

void R_LineGraph (int x, int y, int h);
void R_LineGraph_asm486 (int x, int y, int h);
#endif

#if !defined(ASM486_LINE_GRAPH) || defined(BENCH486)
#if defined(ASM486_LINE_GRAPH)
void R_LineGraph_C (int x, int y, int h)
#else
void R_LineGraph (int x, int y, int h)
#endif
{
	int		i;
	byte	*dest;
	int		s;

// FIXME: should be disabled on no-buffer adapters, or should be in the driver
	
	x += r_refdef.vrect.x;
	y += r_refdef.vrect.y;
	
	dest = vid.buffer + vid.rowbytes*y + x;
	
	s = r_graphheight.value;
	
	if (h>s)
		h = s;
		
	for (i=0 ; i<h ; i++, dest -= vid.rowbytes*2)
	{
		dest[0] = 0xff;
		*(dest-vid.rowbytes) = 0x30;
	}
	for ( ; i<s ; i++, dest -= vid.rowbytes*2)
	{
		dest[0] = 0x30;
		*(dest-vid.rowbytes) = 0x30;
	}
}
#endif /* !ASM486_LINE_GRAPH || BENCH486 */

/*
==============
R_TimeGraph

Performance monitoring tool
==============
*/
extern float mouse_x, mouse_y;

r_timegraph_state_t r_timegraph_state;

#if defined(ASM486_TIME_GRAPH)
typedef char timegraph_state_timex_must_match[
		(offsetof(r_timegraph_state_t, timex) == TG_STATE_TIMEX) ? 1 : -1];
typedef char timegraph_state_timings_must_match[
		(offsetof(r_timegraph_state_t, timings) == TG_STATE_TIMINGS) ? 1 : -1];
typedef char timegraph_state_size_must_match[
		(sizeof(r_timegraph_state_t) == TG_STATE_SIZE) ? 1 : -1];
typedef char timegraph_refdef_vrect_x_must_match[
		(offsetof(refdef_t, vrect.x) == TG_REFDEF_VRECT_X) ? 1 : -1];
typedef char timegraph_refdef_vrect_y_must_match[
		(offsetof(refdef_t, vrect.y) == TG_REFDEF_VRECT_Y) ? 1 : -1];
typedef char timegraph_refdef_vrect_width_must_match[
		(offsetof(refdef_t, vrect.width) == TG_REFDEF_VRECT_WIDTH) ? 1 : -1];
typedef char timegraph_refdef_vrect_height_must_match[
		(offsetof(refdef_t, vrect.height) == TG_REFDEF_VRECT_HEIGHT) ? 1 : -1];
typedef char timegraph_graphheight_value_must_match[
		(offsetof(cvar_t, value) == TG_GRAPHHEIGHT_VALUE) ? 1 : -1];
#endif

#if defined(BENCH486)
static int bench486_timegraph_clock_enabled;
static double bench486_timegraph_clock_value;

double Bench486TimeGraphTime (void)
{
	if (bench486_timegraph_clock_enabled)
		return bench486_timegraph_clock_value;
	return Sys_FloatTime ();
}

void Bench486TimeGraphSetClock (int enabled, double value)
{
	bench486_timegraph_clock_enabled = enabled;
	bench486_timegraph_clock_value = value;
}
#endif

#if defined(BENCH486) && defined(ASM486_LINE_GRAPH)
#define R_TIMEGRAPH_LINE_GRAPH R_LineGraph_C
#else
#define R_TIMEGRAPH_LINE_GRAPH R_LineGraph
#endif

static void R_TimeGraph_C_Work (void)
{
	int		a;
	float	r_time2;
	int		x;

#if defined(BENCH486)
	r_time2 = Bench486TimeGraphTime ();
#else
	r_time2 = Sys_FloatTime ();
#endif

	a = (r_time2-r_time1)/0.01;
//a = fabs(mouse_y * 0.05);
//a = (int)((r_refdef.vieworg[2] + 1024)/1)%(int)r_graphheight.value;
//a = fabs(velocity[0])/20;
//a = ((int)fabs(origin[0])/8)%20;
//a = (cl.idealpitch + 30)/5;
	r_timegraph_state.timings[r_timegraph_state.timex] = a;
	a = r_timegraph_state.timex;

	if (r_refdef.vrect.width <= TG_MAX_TIMINGS)
		x = r_refdef.vrect.width-1;
	else
		x = r_refdef.vrect.width -
				(r_refdef.vrect.width - TG_MAX_TIMINGS)/2;
	do
	{
		R_TIMEGRAPH_LINE_GRAPH (x, r_refdef.vrect.height-2,
				r_timegraph_state.timings[a]);
		if (x==0)
			break;		// screen too small to hold entire thing
		x--;
		a--;
		if (a == -1)
			a = TG_MAX_TIMINGS-1;
	} while (a != r_timegraph_state.timex);

	r_timegraph_state.timex = (r_timegraph_state.timex+1)%TG_MAX_TIMINGS;
}

#if defined(ASM486_TIME_GRAPH)
void R_TimeGraph (void);
#if defined(BENCH486)
void R_TimeGraph_C (void)
{
	R_TimeGraph_C_Work ();
}
#endif
#else
void R_TimeGraph (void)
{
	R_TimeGraph_C_Work ();
}
#endif


/*
=============
R_PrintTimes
=============
*/
#if defined(ASM486_PRINT_TIMES)
void R_PrintTimes (void);
#if defined(BENCH486)
double (*bench486_printtimes_time_probe) (void);

double Bench486PrintTimesTime (void)
{
	if (bench486_printtimes_time_probe)
		return bench486_printtimes_time_probe ();
	return Sys_FloatTime ();
}

/* C oracle for the selected i486 implementation and its deterministic fixture. */
void R_PrintTimes_C (void)
{
	float	r_time2;
	float		ms;

	r_time2 = Bench486PrintTimesTime ();
	ms = 1000* (r_time2 - r_time1);
	Con_Printf ("%5.1f ms %3i/%3i/%3i poly %3i surf\n",
				ms, c_faceclip, r_polycount, r_drawnpolycount, c_surf);
	c_surf = 0;
}
#endif
#else
void R_PrintTimes (void)
{
	float	r_time2;
	float		ms;

	r_time2 = Sys_FloatTime ();

	ms = 1000* (r_time2 - r_time1);
	
	Con_Printf ("%5.1f ms %3i/%3i/%3i poly %3i surf\n",
				ms, c_faceclip, r_polycount, r_drawnpolycount, c_surf);
	c_surf = 0;
}
#endif


/*
=============
R_PrintDSpeeds
=============
*/
#if defined(ASM486_PRINT_TIMES)
void R_PrintDSpeeds (void);
#if defined(BENCH486)
/* C oracle for the selected timing-diagnostics assembly entry. */
void R_PrintDSpeeds_C (void)
{
	float	ms, dp_time, r_time2, rw_time, db_time, se_time, de_time, dv_time;

	r_time2 = Bench486PrintTimesTime ();

	dp_time = (dp_time2 - dp_time1) * 1000;
	rw_time = (rw_time2 - rw_time1) * 1000;
	db_time = (db_time2 - db_time1) * 1000;
	se_time = (se_time2 - se_time1) * 1000;
	de_time = (de_time2 - de_time1) * 1000;
	dv_time = (dv_time2 - dv_time1) * 1000;
	ms = (r_time2 - r_time1) * 1000;

	Con_Printf ("%3i %4.1fp %3iw %4.1fb %3is %4.1fe %4.1fv\n",
				(int)ms, dp_time, (int)rw_time, db_time, (int)se_time, de_time,
				dv_time);
}
#endif
#else
void R_PrintDSpeeds (void)
{
	float	ms, dp_time, r_time2, rw_time, db_time, se_time, de_time, dv_time;

	r_time2 = Sys_FloatTime ();

	dp_time = (dp_time2 - dp_time1) * 1000;
	rw_time = (rw_time2 - rw_time1) * 1000;
	db_time = (db_time2 - db_time1) * 1000;
	se_time = (se_time2 - se_time1) * 1000;
	de_time = (de_time2 - de_time1) * 1000;
	dv_time = (dv_time2 - dv_time1) * 1000;
	ms = (r_time2 - r_time1) * 1000;

	Con_Printf ("%3i %4.1fp %3iw %4.1fb %3is %4.1fe %4.1fv\n",
				(int)ms, dp_time, (int)rw_time, db_time, (int)se_time, de_time,
				dv_time);
}
#endif


/*
=============
R_PrintAliasStats
=============
*/
#if defined(ASM486_ALIAS_STATS)
void R_PrintAliasStats (void);
#if defined(BENCH486)
void R_PrintAliasStats_C (void)
{
	Con_Printf ("%3i polygon model drawn\n", r_amodels_drawn);
}
#endif
#else
void R_PrintAliasStats (void)
{
	Con_Printf ("%3i polygon model drawn\n", r_amodels_drawn);
}
#endif


void WarpPalette (void)
{
	int		i,j;
	byte	newpalette[768];
	int		basecolor[3];
	
	basecolor[0] = 130;
	basecolor[1] = 80;
	basecolor[2] = 50;

// pull the colors halfway to bright brown
	for (i=0 ; i<256 ; i++)
	{
		for (j=0 ; j<3 ; j++)
		{
			newpalette[i*3+j] = (host_basepal[i*3+j] + basecolor[j])/2;
		}
	}
	
	VID_ShiftPalette (newpalette);
}


/*
===================
R_TransformFrustum
===================
*/
#if !defined(ASM486_TRANSFORM_FRUSTUM) || defined(BENCH486)
void R_TransformFrustumCore_C (const mplane_t *screen, clipplane_t *clip,
		const float *origin, const float *forward, const float *right,
		const float *up)
{
	int		i;
	vec3_t	v, v2;
	
	for (i=0 ; i<4 ; i++)
	{
		v[0] = screen[i].normal[2];
		v[1] = -screen[i].normal[0];
		v[2] = screen[i].normal[1];

		v2[0] = v[1]*right[0] + v[2]*up[0] + v[0]*forward[0];
		v2[1] = v[1]*right[1] + v[2]*up[1] + v[0]*forward[1];
		v2[2] = v[1]*right[2] + v[2]*up[2] + v[0]*forward[2];

		VectorCopy (v2, clip[i].normal);

		clip[i].dist = DotProduct (origin, v2);
	}
}

void R_TransformFrustum_C (void)
{
	R_TransformFrustumCore_C (screenedge, view_clipplanes, modelorg,
			vpn, vright, vup);
}
#endif

#ifndef ASM486_TRANSFORM_FRUSTUM
void R_TransformFrustum (void)
{
#ifdef BENCH486
	R_TransformFrustum_C ();
#else
	R_TransformFrustumCore_C (screenedge, view_clipplanes, modelorg,
			vpn, vright, vup);
#endif
}
#endif


#if !defined(__i386__)

/*
================
TransformVector
================
*/
void TransformVector (vec3_t in, vec3_t out)
{
	out[0] = DotProduct(in,vright);
	out[1] = DotProduct(in,vup);
	out[2] = DotProduct(in,vpn);		
}

#endif


/*
================
R_TransformPlane
================
*/
#if !defined(ASM486_TRANSFORM_PLANE) || defined(BENCH486)
#if defined(ASM486_TRANSFORM_PLANE)
void R_TransformPlane_C (mplane_t *p, float *normal, float *dist)
#else
void R_TransformPlane (mplane_t *p, float *normal, float *dist)
#endif
{
	float	d;
	
	d = DotProduct (r_origin, p->normal);
	*dist = p->dist - d;
// TODO: when we have rotating entities, this will need to use the view matrix
	TransformVector (p->normal, normal);
}
#endif /* !ASM486_TRANSFORM_PLANE || BENCH486 */


/*
===============
R_SetUpFrustumIndexes
===============
*/
#if !defined(ASM486_TRANSFORM_FRUSTUM) || defined(BENCH486)
#if defined(ASM486_TRANSFORM_FRUSTUM)
void R_SetUpFrustumIndexes_C (void)
#else
void R_SetUpFrustumIndexes (void)
#endif
{
	int		i, j, *pindex;

	pindex = r_frustum_indexes;

	for (i=0 ; i<4 ; i++)
	{
		for (j=0 ; j<3 ; j++)
		{
			if (view_clipplanes[i].normal[j] < 0)
			{
				pindex[j] = j;
				pindex[j+3] = j+3;
			}
			else
			{
				pindex[j] = j+3;
				pindex[j+3] = j;
			}
		}

	// FIXME: do just once at start
		pfrustum_indexes[i] = pindex;
		pindex += 6;
	}
}
#endif


/*
===============
R_SetupFrame
===============
*/
#if !defined(ASM486_VIEW_CONTROL)
void R_SetupFrame (void)
#elif defined(BENCH486)
void R_SetupFrame_View_C (void)
#endif
#if !defined(ASM486_VIEW_CONTROL) || defined(BENCH486)
{
	int				edgecount;
	vrect_t			vrect;
	float			w, h;

// don't allow cheats in multiplayer
	if (cl.maxclients > 1)
	{
		Cvar_Set ("r_draworder", "0");
		Cvar_Set ("r_fullbright", "0");
		Cvar_Set ("r_ambient", "0");
		Cvar_Set ("r_drawflat", "0");
	}

	if (r_numsurfs.value)
	{
		if ((surface_p - surfaces) > r_maxsurfsseen)
			r_maxsurfsseen = surface_p - surfaces;

		Con_Printf ("Used %d of %d surfs; %d max\n", surface_p - surfaces,
				surf_max - surfaces, r_maxsurfsseen);
	}

	if (r_numedges.value)
	{
		edgecount = edge_p - r_edges;

		if (edgecount > r_maxedgesseen)
			r_maxedgesseen = edgecount;

		Con_Printf ("Used %d of %d edges; %d max\n", edgecount,
				r_numallocatededges, r_maxedgesseen);
	}

	r_refdef.ambientlight = r_ambient.value;

	if (r_refdef.ambientlight < 0)
		r_refdef.ambientlight = 0;

	if (!sv.active)
		r_draworder.value = 0;	// don't let cheaters look behind walls
		
	R_CheckVariables ();
	
	R_AnimateLight ();

	r_framecount++;

	numbtofpolys = 0;

// debugging
#if 0
r_refdef.vieworg[0]=  80;
r_refdef.vieworg[1]=      64;
r_refdef.vieworg[2]=      40;
r_refdef.viewangles[0]=    0;
r_refdef.viewangles[1]=    46.763641357;
r_refdef.viewangles[2]=    0;
#endif

// build the transformation matrix for the given view angles
	VectorCopy (r_refdef.vieworg, modelorg);
	VectorCopy (r_refdef.vieworg, r_origin);

	AngleVectors (r_refdef.viewangles, vpn, vright, vup);
	R_AliasSetViewMatrix ();

// current viewleaf
	r_oldviewleaf = r_viewleaf;
	r_viewleaf = Mod_PointInLeaf (r_origin, cl.worldmodel);

	r_dowarpold = r_dowarp;
	r_dowarp = r_waterwarp.value && (r_viewleaf->contents <= CONTENTS_WATER);

	if ((r_dowarp != r_dowarpold) || r_viewchanged || lcd_x.value)
	{
		if (r_dowarp)
		{
			if ((vid.width <= vid.maxwarpwidth) &&
				(vid.height <= vid.maxwarpheight))
			{
				vrect.x = 0;
				vrect.y = 0;
				vrect.width = vid.width;
				vrect.height = vid.height;

				R_ViewChanged (&vrect, sb_lines, vid.aspect);
			}
			else
			{
				w = vid.width;
				h = vid.height;

				if (w > vid.maxwarpwidth)
				{
					h *= (float)vid.maxwarpwidth / w;
					w = vid.maxwarpwidth;
				}

				if (h > vid.maxwarpheight)
				{
					h = vid.maxwarpheight;
					w *= (float)vid.maxwarpheight / h;
				}

				vrect.x = 0;
				vrect.y = 0;
				vrect.width = (int)w;
				vrect.height = (int)h;

				R_ViewChanged (&vrect,
							   (int)((float)sb_lines * (h/(float)vid.height)),
							   vid.aspect * (h / w) *
								 ((float)vid.width / (float)vid.height));
			}
		}
		else
		{
			vrect.x = 0;
			vrect.y = 0;
			vrect.width = vid.width;
			vrect.height = vid.height;

			R_ViewChanged (&vrect, sb_lines, vid.aspect);
		}

		r_viewchanged = false;
	}

// start off with just the four screen edge clip planes
	R_TransformFrustum ();

// save base values
	VectorCopy (vpn, base_vpn);
	VectorCopy (vright, base_vright);
	VectorCopy (vup, base_vup);
	VectorCopy (modelorg, base_modelorg);

	R_SetSkyFrame ();

	R_SetUpFrustumIndexes ();

	r_cache_thrash = false;

// clear frame counts
	c_faceclip = 0;
	d_spanpixcount = 0;
	r_polycount = 0;
	r_drawnpolycount = 0;
	r_wholepolycount = 0;
	r_amodels_drawn = 0;
	r_outofsurfaces = 0;
	r_outofedges = 0;

	D_SetupFrame ();
}
#endif

