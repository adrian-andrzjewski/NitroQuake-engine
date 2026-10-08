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
// r_light.c

#include "quakedef.h"
#include "r_local.h"
#include "asm_renderdispatch.h"

#if defined(ASM486_MARK_LIGHTS) || defined(ASM486_DYNAMIC_LIGHT_PUSH) || defined(ASM486_ANIMATED_LIGHT) || defined(ASM486_POINT_LIGHT) || defined(BENCH486)
#include <stddef.h>
#include "asm_light.h"
#include "asm_lightcontrol.h"

typedef char light_assembly_pointer_size[(sizeof(void *) == 4) ? 1 : -1];
#endif

#ifdef ASM486_MARK_LIGHTS
typedef char mark_lights_pointer_size[(sizeof(void *) == 4) ? 1 : -1];
typedef char mark_lights_dlight_layout[
		(offsetof(dlight_t, origin) == ml_dlight_origin &&
		offsetof(dlight_t, radius) == ml_dlight_radius &&
		offsetof(dlight_t, minlight) == ml_dlight_minlight &&
		sizeof(dlight_t) == ml_dlight_size) ? 1 : -1];
typedef char mark_lights_plane_layout[
		(offsetof(mplane_t, normal) == ml_plane_normal &&
		offsetof(mplane_t, dist) == ml_plane_dist &&
		sizeof(mplane_t) == ml_plane_size) ? 1 : -1];
typedef char mark_lights_node_layout[
		(offsetof(mnode_t, contents) == ml_node_contents &&
		offsetof(mnode_t, plane) == ml_node_plane &&
		offsetof(mnode_t, children) == ml_node_children &&
		offsetof(mnode_t, firstsurface) == ml_node_firstsurface &&
		offsetof(mnode_t, numsurfaces) == ml_node_numsurfaces &&
		sizeof(mnode_t) == ml_node_size) ? 1 : -1];
typedef char mark_lights_surface_layout[
		(offsetof(msurface_t, dlightframe) == ml_surface_dlightframe &&
		offsetof(msurface_t, dlightbits) == ml_surface_dlightbits &&
		offsetof(msurface_t, plane) == ml_surface_plane &&
		offsetof(msurface_t, texturemins) == ml_surface_texturemins &&
		offsetof(msurface_t, extents) == ml_surface_extents &&
		offsetof(msurface_t, texinfo) == ml_surface_texinfo &&
		sizeof(msurface_t) == ml_surface_size) ? 1 : -1];
typedef char mark_lights_texinfo_layout[
		(offsetof(mtexinfo_t, vecs) == ml_texinfo_vecs &&
		sizeof(mtexinfo_t) == ml_texinfo_size) ? 1 : -1];
#ifdef BENCH486
typedef char mark_lights_probe_layout[
		(offsetof(bench486_mark_lights_probe_t, planedist) == ml_probe_planedist &&
		offsetof(bench486_mark_lights_probe_t, rad) == ml_probe_rad &&
		offsetof(bench486_mark_lights_probe_t, fmin) == ml_probe_fmin &&
		offsetof(bench486_mark_lights_probe_t, local0) == ml_probe_local0 &&
		offsetof(bench486_mark_lights_probe_t, local1) == ml_probe_local1 &&
		offsetof(bench486_mark_lights_probe_t, cs) == ml_probe_cs &&
		offsetof(bench486_mark_lights_probe_t, ct) == ml_probe_ct &&
		offsetof(bench486_mark_lights_probe_t, fmin_scaled) == ml_probe_fmin_scaled &&
		offsetof(bench486_mark_lights_probe_t, sd) == ml_probe_sd &&
		offsetof(bench486_mark_lights_probe_t, td) == ml_probe_td &&
		offsetof(bench486_mark_lights_probe_t, idist) == ml_probe_idist &&
		offsetof(bench486_mark_lights_probe_t, stage) == ml_probe_stage &&
		offsetof(bench486_mark_lights_probe_t, marked) == ml_probe_marked &&
		sizeof(bench486_mark_lights_probe_t) == ml_probe_size) ? 1 : -1];
#endif
#endif

#ifdef ASM486_DYNAMIC_LIGHT_PUSH
typedef char dynamic_light_push_dlight_layout[
		(offsetof(dlight_t, origin) == ml_dlight_origin &&
		offsetof(dlight_t, radius) == ml_dlight_radius &&
		offsetof(dlight_t, die) == ml_dlight_die &&
		sizeof(dlight_t) == ml_dlight_size) ? 1 : -1];
#endif

#if defined(ASM486_ANIMATED_LIGHT) || defined(ASM486_POINT_LIGHT) || defined(BENCH486)
typedef char light_control_client_layout[
    (offsetof(client_state_t,time) == lc_client_time &&
     offsetof(client_state_t,worldmodel) == lc_client_worldmodel) ? 1 : -1];
typedef char light_control_model_layout[
    (offsetof(model_t,nodes) == lc_model_nodes &&
     offsetof(model_t,surfaces) == lc_model_surfaces &&
     offsetof(model_t,lightdata) == lc_model_lightdata) ? 1 : -1];
typedef char light_control_refdef_layout[
    (offsetof(refdef_t,ambientlight) == lc_refdef_ambient) ? 1 : -1];
typedef char light_control_style_layout[
    (offsetof(lightstyle_t,length) == lc_style_length &&
     offsetof(lightstyle_t,map) == lc_style_map &&
     sizeof(lightstyle_t) == lc_style_size && MAX_LIGHTSTYLES == lc_style_count) ? 1 : -1];
typedef char light_control_surface_layout[
    (offsetof(msurface_t,flags) == lc_surface_flags &&
     offsetof(msurface_t,styles) == lc_surface_styles &&
     offsetof(msurface_t,samples) == lc_surface_samples &&
     offsetof(msurface_t,texturemins) == ml_surface_texturemins &&
     offsetof(msurface_t,extents) == ml_surface_extents &&
     offsetof(msurface_t,texinfo) == ml_surface_texinfo &&
     sizeof(msurface_t) == ml_surface_size) ? 1 : -1];
typedef char light_control_node_plane_layout[
    (offsetof(mnode_t,contents) == ml_node_contents &&
     offsetof(mnode_t,plane) == ml_node_plane &&
     offsetof(mnode_t,children) == ml_node_children &&
     offsetof(mnode_t,firstsurface) == ml_node_firstsurface &&
     offsetof(mnode_t,numsurfaces) == ml_node_numsurfaces &&
     offsetof(mplane_t,normal) == ml_plane_normal &&
     offsetof(mplane_t,dist) == ml_plane_dist) ? 1 : -1];
#endif

int	r_dlightframecount;

#ifdef BENCH486
bench486_mark_lights_probe_t *bench486_mark_lights_probe;
#endif


/*
==================
R_AnimateLight
==================
*/
#if !defined(ASM486_ANIMATED_LIGHT) || defined(BENCH486)
static int r_light_last_i;
static int r_light_cur[MAX_LIGHTSTYLES];
static int r_light_len[MAX_LIGHTSTYLES];
static qboolean r_light_inited;

void R_AnimateLight_C (void)
{
	int			i,j,k;
	int			len;
	int			delta;


//
// light animations
// 'm' is normal light, 'a' is no light, 'z' is double bright
// 486: avoid 64 IDIVs per frame.  Keep a per-style frame counter that
// advances by delta = i - last_i without a divide.  The hot path
// (delta==1) is one add + one compare; large jumps fall back to the
// original modulus (rare — map load, hitch, or time wrap).
	i = (int)(cl.time*10);
	if (!r_light_inited)
	{
		for (j=0 ; j<MAX_LIGHTSTYLES ; j++)
		{
			r_light_len[j] = -1;
			r_light_cur[j] = 0;
		}
		r_light_last_i = i;
		r_light_inited = true;
	}
	delta = i - r_light_last_i;

	for (j=0 ; j<MAX_LIGHTSTYLES ; j++)
	{
		len = cl_lightstyle[j].length;
		if (!len)
		{
			d_lightstylevalue[j] = 256;
			r_light_len[j] = 0;
			r_light_cur[j] = 0;
			continue;
		}

		if (len != r_light_len[j])
		{
			k = i % len;
			if (k < 0)
				k += len;
			r_light_cur[j] = k;
			r_light_len[j] = len;
		}
		else if (delta != 0)
		{
			if (delta > 0 && delta < len)
			{
				k = r_light_cur[j] + delta;
				if (k >= len)
					k -= len;
				r_light_cur[j] = k;
			}
			else if (delta < 0 && delta > -len)
			{
				k = r_light_cur[j] + delta;
				if (k < 0)
					k += len;
				r_light_cur[j] = k;
			}
			else
			{
				k = i % len;
				if (k < 0)
					k += len;
				r_light_cur[j] = k;
			}
		}
		k = r_light_cur[j];
		k = cl_lightstyle[j].map[k] - 'a';
		k = k*22;
		d_lightstylevalue[j] = k;
	}
	r_light_last_i = i;
}


#ifndef ASM486_ANIMATED_LIGHT
void R_AnimateLight (void) { R_AnimateLight_C (); }
#endif

#ifdef BENCH486
/* Test-only exchange of the original C algorithm's private persistent state. */
void Bench486AnimateState_C (int *state, int restore)
{
    int j;
    if (restore)
    {
        r_light_last_i = state[0]; r_light_inited = state[1];
        for(j=0 ; j<MAX_LIGHTSTYLES ; j++)
        { r_light_cur[j] = state[2+j]; r_light_len[j] = state[66+j]; }
    }
    else
    {
        state[0] = r_light_last_i; state[1] = r_light_inited;
        for(j=0 ; j<MAX_LIGHTSTYLES ; j++)
        { state[2+j] = r_light_cur[j]; state[66+j] = r_light_len[j]; }
    }
}
#endif
#endif /* C animated-light oracle or C-selected implementation */


/*
=============================================================================

DYNAMIC LIGHTS

=============================================================================
*/

/*
=============
R_MarkLights
=============
*/
#if !defined(ASM486_MARK_LIGHTS) || defined(BENCH486)
#ifdef ASM486_MARK_LIGHTS
void R_MarkLights_C (dlight_t *light, int bit, mnode_t *node)
#define R_MARK_LIGHTS_RECURSE R_MarkLights_C
#else
void R_MarkLights (dlight_t *light, int bit, mnode_t *node)
#define R_MARK_LIGHTS_RECURSE R_MarkLights
#endif
{
	mplane_t	*splitplane;
	float		dist;
	msurface_t	*surf;
	int			i;
#ifdef BENCH486
	bench486_mark_lights_probe_t *probe;
	int			probeindex;
#endif
	
	if (node->contents < 0)
		return;

	splitplane = node->plane;
	dist = DotProduct (light->origin, splitplane->normal) - splitplane->dist;
	
	if (dist > light->radius)
	{
		R_MARK_LIGHTS_RECURSE (light, bit, node->children[0]);
		return;
	}
	if (dist < -light->radius)
	{
		R_MARK_LIGHTS_RECURSE (light, bit, node->children[1]);
		return;
	}
		
// mark the polygons
	surf = cl.worldmodel->surfaces + node->firstsurface;
	for (i=0 ; i<node->numsurfaces ; i++, surf++)
	{
		float		planedist, rad, fmin, cs, ct;
		float		local0, local1;
		vec3_t		impact;
		mtexinfo_t	*tex;
		int			j, sd, td, idist, fmin_scaled;
#ifdef BENCH486
		probe = NULL;
		if (bench486_mark_lights_probe)
		{
			probeindex = (int)(surf - cl.worldmodel->surfaces);
			probe = &bench486_mark_lights_probe[probeindex];
			Q_memset (probe, 0, sizeof(*probe));
			probe->stage = 1;
		}
#endif

		// Same plane reject as R_AddDynamicLights: if no lightmap sample can
		// receive this light, skip the mark so D_CacheSurface can keep a hit
		// instead of rebuilding with a no-op dlight pass.
		planedist = DotProduct (light->origin, surf->plane->normal) -
				surf->plane->dist;
#ifdef BENCH486
		if (probe)
			probe->planedist = planedist;
#endif
		rad = light->radius - (float)fabs (planedist);
#ifdef BENCH486
		if (probe)
			probe->rad = rad;
#endif
		if (rad < light->minlight)
		{
#ifdef BENCH486
			if (probe)
				probe->stage = 2;
#endif
			continue;
		}

		// Same impact/local as R_AddDynamicLights, then O(1) idist to the
		// lightmap rect (replaces the looser fmin-expanded AABB).
		fmin = rad - light->minlight;
		fmin_scaled = (int)ceil (fmin * 256);
#ifdef BENCH486
		if (probe)
		{
			probe->fmin = fmin;
			probe->fmin_scaled = fmin_scaled;
			probe->stage = 3;
		}
#endif
		for (j=0 ; j<3 ; j++)
		{
			impact[j] = light->origin[j] -
					surf->plane->normal[j]*planedist;
		}
		tex = surf->texinfo;
		local0 = DotProduct (impact, tex->vecs[0]) + tex->vecs[0][3]
				- surf->texturemins[0];
		local1 = DotProduct (impact, tex->vecs[1]) + tex->vecs[1][3]
				- surf->texturemins[1];
#ifdef BENCH486
		if (probe)
		{
			probe->local0 = local0;
			probe->local1 = local1;
		}
#endif
		cs = local0;
		if (cs < 0)
			cs = 0;
		else if (cs > surf->extents[0])
			cs = surf->extents[0];
		ct = local1;
		if (ct < 0)
			ct = 0;
		else if (ct > surf->extents[1])
			ct = surf->extents[1];
#ifdef BENCH486
		if (probe)
		{
			probe->cs = cs;
			probe->ct = ct;
		}
#endif
		sd = (int)(local0 - cs);
		if (sd < 0)
			sd = -sd;
		td = (int)(local1 - ct);
		if (td < 0)
			td = -td;
		if (sd > td)
			idist = sd + (td >> 1);
		else
			idist = td + (sd >> 1);

#ifdef BENCH486
		if (probe)
		{
			probe->sd = sd;
			probe->td = td;
			probe->idist = idist;
			probe->stage = 4;
		}
#endif
		if ((idist << 8) >= fmin_scaled)
		{
#ifdef BENCH486
			if (probe)
				probe->marked = 0;
#endif
			continue;
		}

		if (surf->dlightframe != r_dlightframecount)
		{
			surf->dlightbits = 0;
			surf->dlightframe = r_dlightframecount;
		}
		surf->dlightbits |= bit;
#ifdef BENCH486
		if (probe)
		{
			probe->stage = 5;
			probe->marked = 1;
		}
#endif
	}

	R_MARK_LIGHTS_RECURSE (light, bit, node->children[0]);
	R_MARK_LIGHTS_RECURSE (light, bit, node->children[1]);
}
#undef R_MARK_LIGHTS_RECURSE
#endif

#ifdef ASM486_MARK_LIGHTS
void R_MarkLightsTree_asm486 (dlight_t *light, int bit, mnode_t *node,
		msurface_t *surfaces);

#if !(defined(ASM486_RENDER_DISPATCH) && defined(ASM486_MARK_LIGHTS))
void R_MarkLights_asm486 (dlight_t *light, int bit, mnode_t *node)
{
	R_MarkLightsTree_asm486 (light, bit, node, cl.worldmodel->surfaces);
}
#endif

#if !(defined(ASM486_RENDER_DISPATCH) && defined(ASM486_MARK_LIGHTS))
void R_MarkLights (dlight_t *light, int bit, mnode_t *node)
{
	R_MarkLights_asm486 (light, bit, node);
}
#endif
#endif


/*
=============
R_PushDlights
=============
*/
#if defined(ASM486_DYNAMIC_LIGHT_PUSH) && defined(BENCH486)
void R_PushDlights_C (void)
{
	int		i;
	dlight_t	*l;

	r_dlightframecount = r_framecount + 1;	// because the count hasn't
											//  advanced yet for this frame
	l = cl_dlights;

	for (i=0 ; i<MAX_DLIGHTS ; i++, l++)
	{
		if (l->die < cl.time || !l->radius)
			continue;
		R_MarkLights ( l, 1<<i, cl.worldmodel->nodes );
	}
}
#endif

#ifdef ASM486_DYNAMIC_LIGHT_PUSH
void R_PushDlights_asm486 (double time, int frameCount,
		dlight_t *lights, mnode_t *world);

#if !(defined(ASM486_RENDER_DISPATCH) && defined(ASM486_DYNAMIC_LIGHT_PUSH))
void R_PushDlights (void)
{
	model_t *worldModel;

	worldModel = cl.worldmodel;
	R_PushDlights_asm486 (cl.time, r_framecount, cl_dlights,
			worldModel ? worldModel->nodes : NULL);
}
#endif
#else
void R_PushDlights (void)
{
	int		i;
	dlight_t	*l;

	r_dlightframecount = r_framecount + 1;	// because the count hasn't
											//  advanced yet for this frame
	l = cl_dlights;

	for (i=0 ; i<MAX_DLIGHTS ; i++, l++)
	{
		if (l->die < cl.time || !l->radius)
			continue;
		R_MarkLights ( l, 1<<i, cl.worldmodel->nodes );
	}
}
#endif


/*
=============================================================================

LIGHT SAMPLING

=============================================================================
*/

#if !defined(ASM486_POINT_LIGHT) || defined(BENCH486)
int RecursiveLightPoint_C (mnode_t *node, vec3_t start, vec3_t end)
{
	int			r;
	float		front, back, frac;
	int			side;
	mplane_t	*plane;
	vec3_t		mid;
	msurface_t	*surf;
	int			s, t, ds, dt;
	int			i;
	mtexinfo_t	*tex;
	byte		*lightmap;
	unsigned	scale;
	int			maps;

	if (node->contents < 0)
		return -1;		// didn't hit anything
	
// calculate mid point

// FIXME: optimize for axial
	plane = node->plane;
	front = DotProduct (start, plane->normal) - plane->dist;
	back = DotProduct (end, plane->normal) - plane->dist;
	side = front < 0;
	
	if ( (back < 0) == side)
		return RecursiveLightPoint_C (node->children[side], start, end);
	
	frac = front / (front-back);
	mid[0] = start[0] + (end[0] - start[0])*frac;
	mid[1] = start[1] + (end[1] - start[1])*frac;
	mid[2] = start[2] + (end[2] - start[2])*frac;
	
// go down front side	
	r = RecursiveLightPoint_C (node->children[side], start, mid);
	if (r >= 0)
		return r;		// hit something
		
	if ( (back < 0) == side )
		return -1;		// didn't hit anuthing
		
// check for impact on this node

	surf = cl.worldmodel->surfaces + node->firstsurface;
	for (i=0 ; i<node->numsurfaces ; i++, surf++)
	{
		if (surf->flags & SURF_DRAWTILED)
			continue;	// no lightmaps

		tex = surf->texinfo;
		
		s = DotProduct (mid, tex->vecs[0]) + tex->vecs[0][3];
		t = DotProduct (mid, tex->vecs[1]) + tex->vecs[1][3];;

		if (s < surf->texturemins[0] ||
		t < surf->texturemins[1])
			continue;
		
		ds = s - surf->texturemins[0];
		dt = t - surf->texturemins[1];
		
		if ( ds > surf->extents[0] || dt > surf->extents[1] )
			continue;

		if (!surf->samples)
			return 0;

		ds >>= 4;
		dt >>= 4;

		lightmap = surf->samples;
		r = 0;
		if (lightmap)
		{

			lightmap += dt * ((surf->extents[0]>>4)+1) + ds;

			for (maps = 0 ; maps < MAXLIGHTMAPS && surf->styles[maps] != 255 ;
					maps++)
			{
				scale = d_lightstylevalue[surf->styles[maps]];
				r += *lightmap * scale;
				lightmap += ((surf->extents[0]>>4)+1) *
						((surf->extents[1]>>4)+1);
			}
			
			r >>= 8;
		}
		
		return r;
	}

// go down back side
	return RecursiveLightPoint_C (node->children[!side], mid, end);
}

int R_LightPoint_C (vec3_t p)
{
	vec3_t		end;
	int			r;
	
	if (!cl.worldmodel->lightdata)
		return 255;
	
	end[0] = p[0];
	end[1] = p[1];
	end[2] = p[2] - 2048;
	
	r = RecursiveLightPoint_C (cl.worldmodel->nodes, p, end);
	
	if (r == -1)
		r = 0;

	if (r < r_refdef.ambientlight)
		r = r_refdef.ambientlight;

	return r;
}


#endif /* C point-light oracle or C-selected implementation */
#ifndef ASM486_POINT_LIGHT
int RecursiveLightPoint (mnode_t *node, vec3_t start, vec3_t end)
{ return RecursiveLightPoint_C (node,start,end); }
int R_LightPoint (vec3_t point) { return R_LightPoint_C (point); }
#endif

/* Pinned original argument adapters, compiled only as independent test oracles. */
#if defined(BENCH486) && defined(ASM486_RENDER_DISPATCH) && defined(ASM486_MARK_LIGHTS)
void R_MarkLights_asm486_Dispatch_C (dlight_t *light, int bit, mnode_t *node)
{
	Bench486DispatchMarkTree (light, bit, node, cl.worldmodel->surfaces);
}
#endif

#if defined(BENCH486) && defined(ASM486_RENDER_DISPATCH) && defined(ASM486_MARK_LIGHTS)
void R_MarkLights_Dispatch_C (dlight_t *light, int bit, mnode_t *node)
{
	R_MarkLights_asm486_Dispatch_C (light, bit, node);
}
#endif

#if defined(BENCH486) && defined(ASM486_RENDER_DISPATCH) && defined(ASM486_DYNAMIC_LIGHT_PUSH)
void R_PushDlights_Dispatch_C (void)
{
	model_t *worldModel;

	worldModel = cl.worldmodel;
	Bench486DispatchPushLights (cl.time, r_framecount, cl_dlights,
			worldModel ? worldModel->nodes : NULL);
}
#endif
