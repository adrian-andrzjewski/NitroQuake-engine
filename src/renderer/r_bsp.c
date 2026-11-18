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
// r_bsp.c

#include "render.h"
#include "client.h"
#include "bspfile.h"
#include "model.h"
#include "d_iface.h"
#include "console.h"
#include "sys.h"
#include "tests/bench486/bench486_profile.h"
#include "renderer/r_local.h"
#include "renderer/asm_worldcontrol.h"

#if defined(ASM486_BSP_WALK) || defined(ASM486_RENDER_WORLD) || \
	defined(ASM486_DRAW_SUBMODEL_POLYGONS) || \
	defined(ASM486_BMODEL_POLYGON_CLIP) || \
	defined(ASM486_DRAW_SOLID_CLIPPED_SUBMODEL_POLYGONS)
#include <stddef.h>
#endif

#ifdef ASM486_BSP_WALK

typedef char bsp_walk_i386_pointer_size[(sizeof(void *) == 4) ? 1 : -1];
typedef char bsp_walk_plane_layout[
		(offsetof(mplane_t, normal) == 0 &&
		offsetof(mplane_t, dist) == 12 &&
		offsetof(mplane_t, type) == 16 &&
		sizeof(mplane_t) == 20) ? 1 : -1];
typedef char bsp_walk_node_layout[
		(offsetof(mnode_t, contents) == 0 &&
		offsetof(mnode_t, visframe) == 4 &&
		offsetof(mnode_t, minmaxs) == 8 &&
		offsetof(mnode_t, plane) == 24 &&
		offsetof(mnode_t, children) == 28 &&
		offsetof(mnode_t, firstsurface) == 36 &&
		offsetof(mnode_t, numsurfaces) == 38 &&
		sizeof(mnode_t) == 40) ? 1 : -1];
typedef char bsp_walk_leaf_layout[
		(offsetof(mleaf_t, efrags) == 28 &&
		offsetof(mleaf_t, firstmarksurface) == 32 &&
		offsetof(mleaf_t, nummarksurfaces) == 36 &&
		offsetof(mleaf_t, key) == 40 &&
		sizeof(mleaf_t) == 48) ? 1 : -1];
typedef char bsp_walk_surface_layout[
		(offsetof(msurface_t, visframe) == 0 &&
		offsetof(msurface_t, plane) == 12 &&
		offsetof(msurface_t, flags) == 16 &&
		sizeof(msurface_t) == 64) ? 1 : -1];
typedef char bsp_walk_worldmodel_offset[
		(offsetof(client_state_t, worldmodel) == 2692) ? 1 : -1];
typedef char bsp_walk_model_surfaces_offset[
		(offsetof(model_t, surfaces) == 180) ? 1 : -1];
typedef char bsp_walk_poly_layout[
		(offsetof(btofpoly_t, clipflags) == 0 &&
		offsetof(btofpoly_t, psurf) == 4 &&
		sizeof(btofpoly_t) == 8) ? 1 : -1];
#endif

#ifdef ASM486_RENDER_WORLD
typedef char render_world_i386_pointer_size[(sizeof(void *) == 4) ? 1 : -1];
typedef char render_world_entity_model_offset[
		(offsetof(entity_t, model) == 132) ? 1 : -1];
typedef char render_world_model_vertexes_offset[
		(offsetof(model_t, vertexes) == 148) ? 1 : -1];
typedef char render_world_model_nodes_offset[
		(offsetof(model_t, nodes) == 164) ? 1 : -1];
typedef char render_world_poly_layout[
		(offsetof(btofpoly_t, clipflags) == 0 &&
		offsetof(btofpoly_t, psurf) == 4 &&
		sizeof(btofpoly_t) == 8 &&
		MAX_BTOFPOLYS == 5000) ? 1 : -1];
#endif

#ifdef ASM486_DRAW_SUBMODEL_POLYGONS
typedef char submodel_poly_i386_pointer_size[(sizeof(void *) == 4) ? 1 : -1];
typedef char submodel_poly_model_layout[
		(offsetof(model_t, firstmodelsurface) == 112 &&
		offsetof(model_t, nummodelsurfaces) == 116 &&
		offsetof(model_t, surfaces) == 180) ? 1 : -1];
typedef char submodel_poly_surface_layout[
		(offsetof(msurface_t, plane) == 12 &&
		offsetof(msurface_t, flags) == 16 &&
		sizeof(msurface_t) == 64) ? 1 : -1];
typedef char submodel_poly_plane_layout[
		(offsetof(mplane_t, normal) == 0 &&
		offsetof(mplane_t, dist) == 12) ? 1 : -1];
typedef char submodel_poly_entity_leaf_layout[
		(offsetof(entity_t, topnode) == 176 &&
		offsetof(mleaf_t, key) == 40) ? 1 : -1];
#endif

#ifdef ASM486_BMODEL_POLYGON_CLIP
typedef char bmodel_clip_i386_pointer_size[(sizeof(void *) == 4) ? 1 : -1];
typedef char bmodel_clip_vertex_layout[
		(offsetof(mvertex_t, position) == 0 && sizeof(mvertex_t) == 12) ? 1 : -1];
typedef char bmodel_clip_edge_layout[
		(offsetof(bedge_t, v) == 0 && offsetof(bedge_t, pnext) == 8 &&
		sizeof(bedge_t) == 12) ? 1 : -1];
typedef char bmodel_clip_plane_layout[
		(offsetof(mplane_t, normal) == 0 && offsetof(mplane_t, dist) == 12 &&
		sizeof(mplane_t) == 20) ? 1 : -1];
typedef char bmodel_clip_node_layout[
		(offsetof(mnode_t, contents) == 0 &&
		offsetof(mnode_t, visframe) == 4 &&
		offsetof(mnode_t, plane) == 24 &&
		offsetof(mnode_t, children) == 28 && sizeof(mnode_t) == 40) ? 1 : -1];
typedef char bmodel_clip_leaf_layout[
		(offsetof(mleaf_t, contents) == 0 &&
		offsetof(mleaf_t, visframe) == 4 &&
		offsetof(mleaf_t, key) == 40 && sizeof(mleaf_t) == 48) ? 1 : -1];
typedef char bmodel_clip_surface_layout[
		(offsetof(msurface_t, plane) == 12 &&
		offsetof(msurface_t, flags) == 16 && sizeof(msurface_t) == 64) ? 1 : -1];
#endif

//
// current entity info
//
qboolean		insubmodel;
entity_t		*currententity;
vec3_t			modelorg, base_modelorg;
								// modelorg is the viewpoint reletive to
								// the currently rendering entity
vec3_t			r_entorigin;	// the currently rendering entity in world
								// coordinates

float			entity_rotation[3][3];

vec3_t			r_worldmodelorg;

int				r_currentbkey;

typedef enum {touchessolid, drawnode, nodrawnode} solidstate_t;

#define MAX_BMODEL_VERTS	500			// 6K
#define MAX_BMODEL_EDGES	1000		// 12K

#if defined(ASM486_BMODEL_POLYGON_CLIP) || \
	defined(ASM486_DRAW_SOLID_CLIPPED_SUBMODEL_POLYGONS)
mvertex_t	*pbverts;
bedge_t		*pbedges;
int			numbverts, numbedges;
mvertex_t	*pfrontenter, *pfrontexit;
qboolean		makeclippededge;
#else
static mvertex_t	*pbverts;
static bedge_t		*pbedges;
static int			numbverts, numbedges;
static mvertex_t	*pfrontenter, *pfrontexit;
static qboolean		makeclippededge;
#endif

#ifdef ASM486_BMODEL_POLYGON_CLIP
/* Per-entity, per-frame transformed brush splitter-plane cache. */
#define BMODEL_CLIP_PLANE_CACHE_ENTRIES 512
unsigned long bpoly_plane_cache_plane[BMODEL_CLIP_PLANE_CACHE_ENTRIES];
unsigned long bpoly_plane_cache_entity[BMODEL_CLIP_PLANE_CACHE_ENTRIES];
unsigned long bpoly_plane_cache_frame[BMODEL_CLIP_PLANE_CACHE_ENTRIES];
float bpoly_plane_cache_values[BMODEL_CLIP_PLANE_CACHE_ENTRIES][4];
#endif

#ifdef ASM486_DRAW_SOLID_CLIPPED_SUBMODEL_POLYGONS
typedef char solid_bmodel_clip_i386_pointer_size[(sizeof(void *) == 4) ? 1 : -1];
typedef char solid_bmodel_clip_model_layout[
		(offsetof(model_t, firstmodelsurface) == 112 &&
		offsetof(model_t, nummodelsurfaces) == 116 &&
		offsetof(model_t, edges) == 156 &&
		offsetof(model_t, surfaces) == 180 &&
		offsetof(model_t, surfedges) == 188) ? 1 : -1];
typedef char solid_bmodel_clip_surface_layout[
		(offsetof(msurface_t, plane) == 12 &&
		offsetof(msurface_t, flags) == 16 &&
		offsetof(msurface_t, firstedge) == 20 &&
		offsetof(msurface_t, numedges) == 24 &&
		sizeof(msurface_t) == 64) ? 1 : -1];
typedef char solid_bmodel_clip_plane_layout[
		(offsetof(mplane_t, normal) == 0 &&
		offsetof(mplane_t, dist) == 12 && sizeof(mplane_t) == 20) ? 1 : -1];
typedef char solid_bmodel_clip_vertex_layout[
		(offsetof(mvertex_t, position) == 0 && sizeof(mvertex_t) == 12) ? 1 : -1];
typedef char solid_bmodel_clip_medge_layout[
		(offsetof(medge_t, v) == 0 && sizeof(medge_t) == 8) ? 1 : -1];
typedef char solid_bmodel_clip_bedge_layout[
		(offsetof(bedge_t, v) == 0 && offsetof(bedge_t, pnext) == 8 &&
		sizeof(bedge_t) == 12) ? 1 : -1];
typedef char solid_bmodel_clip_buffer_sizes[
		(MAX_BMODEL_VERTS == 500 && MAX_BMODEL_EDGES == 1000) ? 1 : -1];
#endif


//===========================================================================

/*
================
R_EntityRotate
================
*/
#if !defined(ASM486_WORLD_ROTATION)
void R_EntityRotate (vec3_t vec)
{
	vec3_t	tvec;

	VectorCopy (vec, tvec);
	vec[0] = DotProduct (entity_rotation[0], tvec);
	vec[1] = DotProduct (entity_rotation[1], tvec);
	vec[2] = DotProduct (entity_rotation[2], tvec);
}
#endif


/*
================
R_RotateBmodel
================
*/
#if !defined(ASM486_WORLD_ROTATION)
void R_RotateBmodel (void)
{
	float	angle, s, c, temp1[3][3], temp2[3][3], temp3[3][3];

// TODO: should use a look-up table
// TODO: should really be stored with the entity instead of being reconstructed
// TODO: could cache lazily, stored in the entity
// TODO: share work with R_SetUpAliasTransform

// yaw
	angle = currententity->angles[YAW];		
	angle = angle * M_PI*2 / 360;
	s = sin(angle);
	c = cos(angle);

	temp1[0][0] = c;
	temp1[0][1] = s;
	temp1[0][2] = 0;
	temp1[1][0] = -s;
	temp1[1][1] = c;
	temp1[1][2] = 0;
	temp1[2][0] = 0;
	temp1[2][1] = 0;
	temp1[2][2] = 1;


// pitch
	angle = currententity->angles[PITCH];		
	angle = angle * M_PI*2 / 360;
	s = sin(angle);
	c = cos(angle);

	temp2[0][0] = c;
	temp2[0][1] = 0;
	temp2[0][2] = -s;
	temp2[1][0] = 0;
	temp2[1][1] = 1;
	temp2[1][2] = 0;
	temp2[2][0] = s;
	temp2[2][1] = 0;
	temp2[2][2] = c;

	R_ConcatRotations (temp2, temp1, temp3);

// roll
	angle = currententity->angles[ROLL];		
	angle = angle * M_PI*2 / 360;
	s = sin(angle);
	c = cos(angle);

	temp1[0][0] = 1;
	temp1[0][1] = 0;
	temp1[0][2] = 0;
	temp1[1][0] = 0;
	temp1[1][1] = c;
	temp1[1][2] = s;
	temp1[2][0] = 0;
	temp1[2][1] = -s;
	temp1[2][2] = c;

	R_ConcatRotations (temp1, temp3, entity_rotation);

//
// rotate modelorg and the transformation matrix
//
	R_EntityRotate (modelorg);
	R_EntityRotate (vpn);
	R_EntityRotate (vright);
	R_EntityRotate (vup);

	R_TransformFrustum ();
}
#endif


/*
================
R_RotateBmodelCached

Same drawing state as R_RotateBmodel, but reuses this frame's entity
rotation matrix so later polygons skip the 486 sin/cos rebuild.
R_RotateBmodel remains the reference that always reconstructs the matrix.
================
*/
#define BMODEL_ROTCACHE_SLOTS	8
typedef char worldcontrol_cache_slots_must_match[(BMODEL_ROTCACHE_SLOTS==WORLD_BMODEL_CACHE_SLOTS)?1:-1];
/* Original private zeroed cache data, shared with the BENCH oracle. */
entity_t *worldcontrol_cache_ent[BMODEL_ROTCACHE_SLOTS];
int worldcontrol_cache_frame[BMODEL_ROTCACHE_SLOTS];
float worldcontrol_cache_rot[BMODEL_ROTCACHE_SLOTS][3][3];

#if !defined(ASM486_WORLD_ROTATION)
void R_RotateBmodelCached (void)
{
	unsigned				slot;
	int						i, j;


	slot = ((unsigned)currententity >> 5) & (BMODEL_ROTCACHE_SLOTS - 1);
	if (worldcontrol_cache_ent[slot] == currententity && worldcontrol_cache_frame[slot] == r_framecount)
	{
		for (i = 0 ; i < 3 ; i++)
			for (j = 0 ; j < 3 ; j++)
				entity_rotation[i][j] = worldcontrol_cache_rot[slot][i][j];
		R_EntityRotate (modelorg);
		R_EntityRotate (vpn);
		R_EntityRotate (vright);
		R_EntityRotate (vup);
		R_TransformFrustum ();
		return;
	}

	R_RotateBmodel ();
	worldcontrol_cache_ent[slot] = currententity;
	worldcontrol_cache_frame[slot] = r_framecount;
	for (i = 0 ; i < 3 ; i++)
		for (j = 0 ; j < 3 ; j++)
			worldcontrol_cache_rot[slot][i][j] = entity_rotation[i][j];
}
#endif


/*
================
R_RecursiveClipBPoly
================
*/
#if !defined(ASM486_BMODEL_POLYGON_CLIP) || defined(BENCH486)
#ifdef ASM486_BMODEL_POLYGON_CLIP
void R_RecursiveClipBPoly_C (bedge_t *pedges, mnode_t *pnode,
		msurface_t *psurf)
#else
void R_RecursiveClipBPoly (bedge_t *pedges, mnode_t *pnode, msurface_t *psurf)
#endif
{
	bedge_t		*psideedges[2], *pnextedge, *ptedge;
	int			i, side, lastside;
	float		dist, frac, lastdist;
	mplane_t	*splitplane, tplane;
	mvertex_t	*pvert, *plastvert, *ptvert;
	mnode_t		*pn;

	psideedges[0] = psideedges[1] = NULL;

	makeclippededge = false;

// transform the BSP plane into model space
// FIXME: cache these?
	splitplane = pnode->plane;
	tplane.dist = splitplane->dist -
			DotProduct(r_entorigin, splitplane->normal);
	tplane.normal[0] = DotProduct (entity_rotation[0], splitplane->normal);
	tplane.normal[1] = DotProduct (entity_rotation[1], splitplane->normal);
	tplane.normal[2] = DotProduct (entity_rotation[2], splitplane->normal);

// clip edges to BSP plane
	for ( ; pedges ; pedges = pnextedge)
	{
		pnextedge = pedges->pnext;

	// set the status for the last point as the previous point
	// FIXME: cache this stuff somehow?
		plastvert = pedges->v[0];
		lastdist = DotProduct (plastvert->position, tplane.normal) -
				   tplane.dist;

		if (lastdist > 0)
			lastside = 0;
		else
			lastside = 1;

		pvert = pedges->v[1];

		dist = DotProduct (pvert->position, tplane.normal) - tplane.dist;

		if (dist > 0)
			side = 0;
		else
			side = 1;

		if (side != lastside)
		{
		// clipped
			if (numbverts >= MAX_BMODEL_VERTS)
				return;

		// generate the clipped vertex
			frac = lastdist / (lastdist - dist);
			ptvert = &pbverts[numbverts++];
			ptvert->position[0] = plastvert->position[0] +
					frac * (pvert->position[0] -
					plastvert->position[0]);
			ptvert->position[1] = plastvert->position[1] +
					frac * (pvert->position[1] -
					plastvert->position[1]);
			ptvert->position[2] = plastvert->position[2] +
					frac * (pvert->position[2] -
					plastvert->position[2]);

		// split into two edges, one on each side, and remember entering
		// and exiting points
		// FIXME: share the clip edge by having a winding direction flag?
			if (numbedges >= (MAX_BMODEL_EDGES - 1))
			{
				Con_Printf ("Out of edges for bmodel\n");
				return;
			}

			ptedge = &pbedges[numbedges];
			ptedge->pnext = psideedges[lastside];
			psideedges[lastside] = ptedge;
			ptedge->v[0] = plastvert;
			ptedge->v[1] = ptvert;

			ptedge = &pbedges[numbedges + 1];
			ptedge->pnext = psideedges[side];
			psideedges[side] = ptedge;
			ptedge->v[0] = ptvert;
			ptedge->v[1] = pvert;

			numbedges += 2;

			if (side == 0)
			{
			// entering for front, exiting for back
				pfrontenter = ptvert;
				makeclippededge = true;
			}
			else
			{
				pfrontexit = ptvert;
				makeclippededge = true;
			}
		}
		else
		{
		// add the edge to the appropriate side
			pedges->pnext = psideedges[side];
			psideedges[side] = pedges;
		}
	}

// if anything was clipped, reconstitute and add the edges along the clip
// plane to both sides (but in opposite directions)
	if (makeclippededge)
	{
		if (numbedges >= (MAX_BMODEL_EDGES - 2))
		{
			Con_Printf ("Out of edges for bmodel\n");
			return;
		}

		ptedge = &pbedges[numbedges];
		ptedge->pnext = psideedges[0];
		psideedges[0] = ptedge;
		ptedge->v[0] = pfrontexit;
		ptedge->v[1] = pfrontenter;

		ptedge = &pbedges[numbedges + 1];
		ptedge->pnext = psideedges[1];
		psideedges[1] = ptedge;
		ptedge->v[0] = pfrontenter;
		ptedge->v[1] = pfrontexit;

		numbedges += 2;
	}

// draw or recurse further
	for (i=0 ; i<2 ; i++)
	{
		if (psideedges[i])
		{
		// draw if we've reached a non-solid leaf, done if all that's left is a
		// solid leaf, and continue down the tree if it's not a leaf
			pn = pnode->children[i];

		// we're done with this branch if the node or leaf isn't in the PVS
			if (pn->visframe == r_visframecount)
			{
				if (pn->contents < 0)
				{
					if (pn->contents != CONTENTS_SOLID)
					{
						r_currentbkey = ((mleaf_t *)pn)->key;
						R_RenderBmodelFace (psideedges[i], psurf);
					}
				}
				else
				{
#ifdef ASM486_BMODEL_POLYGON_CLIP
					R_RecursiveClipBPoly_C (psideedges[i], pnode->children[i],
										psurf);
#else
					R_RecursiveClipBPoly (psideedges[i], pnode->children[i],
									  psurf);
#endif
				}
			}
		}
	}
}
#endif

#ifdef ASM486_BMODEL_POLYGON_CLIP
void R_RecursiveClipBPoly_asm486 (bedge_t *pedges, mnode_t *pnode,
		msurface_t *psurf);

#if !defined(ASM486_PUBLIC_BINDINGS) || !defined(ASM486_BMODEL_POLYGON_CLIP)
void R_RecursiveClipBPoly (bedge_t *pedges, mnode_t *pnode,
		msurface_t *psurf)
{
	R_RecursiveClipBPoly_asm486 (pedges, pnode, psurf);
}
#endif /* public entry is assembly-owned when selected */
#endif


/*
================
R_DrawSolidClippedSubmodelPolygons
================
*/
#if !defined(ASM486_DRAW_SOLID_CLIPPED_SUBMODEL_POLYGONS) || defined(BENCH486)
#ifdef ASM486_DRAW_SOLID_CLIPPED_SUBMODEL_POLYGONS
void R_DrawSolidClippedSubmodelPolygons_C (model_t *pmodel)
#else
void R_DrawSolidClippedSubmodelPolygons (model_t *pmodel)
#endif
{
	int			i, j, lindex;
	vec_t		dot;
	msurface_t	*psurf;
	int			numsurfaces;
	mplane_t	*pplane;
	mvertex_t	bverts[MAX_BMODEL_VERTS];
	bedge_t		bedges[MAX_BMODEL_EDGES], *pbedge;
	medge_t		*pedge, *pedges;
	int			*psurfedges;

// FIXME: use bounding-box-based frustum clipping info?

	psurf = &pmodel->surfaces[pmodel->firstmodelsurface];
	numsurfaces = pmodel->nummodelsurfaces;
	pedges = pmodel->edges;

	for (i=0 ; i<numsurfaces ; i++, psurf++)
	{
	// find which side of the node we are on
		pplane = psurf->plane;

		dot = DotProduct (modelorg, pplane->normal) - pplane->dist;

	// draw the polygon
		if (((psurf->flags & SURF_PLANEBACK) && (dot < -BACKFACE_EPSILON)) ||
			(!(psurf->flags & SURF_PLANEBACK) && (dot > BACKFACE_EPSILON)))
		{
		// FIXME: use bounding-box-based frustum clipping info?

		// copy the edges to bedges, flipping if necessary so always
		// clockwise winding
		// FIXME: if edges and vertices get caches, these assignments must move
		// outside the loop, and overflow checking must be done here
			pbverts = bverts;
			pbedges = bedges;
			numbverts = numbedges = 0;

			if (psurf->numedges > 0)
			{
				pbedge = &bedges[numbedges];
				numbedges += psurf->numedges;
				psurfedges = pmodel->surfedges + psurf->firstedge;

				for (j=0 ; j<psurf->numedges ; j++)
				{
				   lindex = psurfedges[j];

					if (lindex > 0)
					{
						pedge = &pedges[lindex];
						pbedge[j].v[0] = &r_pcurrentvertbase[pedge->v[0]];
						pbedge[j].v[1] = &r_pcurrentvertbase[pedge->v[1]];
					}
					else
					{
						lindex = -lindex;
						pedge = &pedges[lindex];
						pbedge[j].v[0] = &r_pcurrentvertbase[pedge->v[1]];
						pbedge[j].v[1] = &r_pcurrentvertbase[pedge->v[0]];
					}

					pbedge[j].pnext = &pbedge[j+1];
				}

				pbedge[j-1].pnext = NULL;	// mark end of edges

				R_RecursiveClipBPoly (pbedge, currententity->topnode, psurf);
			}
			else
			{
				Sys_Error ("no edges in bmodel");
			}
		}
	}
}
#endif

#ifdef ASM486_DRAW_SOLID_CLIPPED_SUBMODEL_POLYGONS
void R_DrawSolidClippedSubmodelPolygons_asm486 (model_t *pmodel);

#if !defined(ASM486_PUBLIC_BINDINGS) || !defined(ASM486_DRAW_SOLID_CLIPPED_SUBMODEL_POLYGONS)
void R_DrawSolidClippedSubmodelPolygons (model_t *pmodel)
{
	R_DrawSolidClippedSubmodelPolygons_asm486 (pmodel);
}
#endif /* public entry is assembly-owned when selected */
#endif


/*
================
R_DrawSubmodelPolygons
================
*/
#if !defined(ASM486_DRAW_SUBMODEL_POLYGONS) || defined(BENCH486)
#ifdef ASM486_DRAW_SUBMODEL_POLYGONS
void R_DrawSubmodelPolygons_C (model_t *pmodel, int clipflags)
#else
void R_DrawSubmodelPolygons (model_t *pmodel, int clipflags)
#endif
{
	int			i;
	vec_t		dot;
	msurface_t	*psurf;
	int			numsurfaces;
	mplane_t	*pplane;

// FIXME: use bounding-box-based frustum clipping info?

	psurf = &pmodel->surfaces[pmodel->firstmodelsurface];
	numsurfaces = pmodel->nummodelsurfaces;

#ifdef PROFILE486
// A per-(face, entity) precompute of the backface dot product can only pay if
// the same entity is drawn more than once: this loop already visits every face
// of a submodel exactly once per call, so there is no reuse within a call.
// Count calls, faces, distinct entities and repeat draws to test that.
	{
		extern unsigned long bench486_submodel_calls;
		extern unsigned long bench486_submodel_faces;
		extern unsigned long bench486_submodel_distinct_entities;
		extern unsigned long bench486_submodel_entity_hits;
		extern unsigned long bench486_submodel_table_overwrites;
		extern void *bench486_submodel_entity_table[1024];
		unsigned int slot = ((unsigned int)(size_t)currententity >> 4) & 1023u;
		bench486_submodel_calls++;
		bench486_submodel_faces += numsurfaces;
		if (bench486_submodel_entity_table[slot] == currententity)
			bench486_submodel_entity_hits++;
		else if (bench486_submodel_entity_table[slot] != NULL)
			bench486_submodel_table_overwrites++;
		else
			bench486_submodel_distinct_entities++;
		bench486_submodel_entity_table[slot] = currententity;
	}
#endif

	for (i=0 ; i<numsurfaces ; i++, psurf++)
	{
	// find which side of the node we are on
		pplane = psurf->plane;

		dot = DotProduct (modelorg, pplane->normal) - pplane->dist;

	// draw the polygon
		if (((psurf->flags & SURF_PLANEBACK) && (dot < -BACKFACE_EPSILON)) ||
			(!(psurf->flags & SURF_PLANEBACK) && (dot > BACKFACE_EPSILON)))
		{
			r_currentkey = ((mleaf_t *)currententity->topnode)->key;

		// FIXME: use bounding-box-based frustum clipping info?
		BENCH486_PROFILE_ENTER (BENCH486_PROFILE_RENDERFACE);
		R_RenderFace (psurf, clipflags);
		BENCH486_PROFILE_LEAVE ();
		}
	}
}
#endif

#ifdef ASM486_DRAW_SUBMODEL_POLYGONS
void R_DrawSubmodelPolygons_asm486 (model_t *pmodel, int clipflags);

#if !defined(ASM486_PUBLIC_BINDINGS) || !defined(ASM486_DRAW_SUBMODEL_POLYGONS)
void R_DrawSubmodelPolygons (model_t *pmodel, int clipflags)
{
	R_DrawSubmodelPolygons_asm486 (pmodel, clipflags);
}
#endif /* public entry is assembly-owned when selected */

#ifdef PROFILE486
void R_DrawSubmodelPolygonsProfileEntry_asm486 (int numsurfaces)
{
	extern unsigned long bench486_submodel_calls;
	extern unsigned long bench486_submodel_faces;
	extern unsigned long bench486_submodel_distinct_entities;
	extern unsigned long bench486_submodel_entity_hits;
	extern unsigned long bench486_submodel_table_overwrites;
	extern void *bench486_submodel_entity_table[1024];
	unsigned int slot;

	slot = ((unsigned int)(size_t)currententity >> 4) & 1023u;
	bench486_submodel_calls++;
	bench486_submodel_faces += numsurfaces;
	if (bench486_submodel_entity_table[slot] == currententity)
		bench486_submodel_entity_hits++;
	else if (bench486_submodel_entity_table[slot] != NULL)
		bench486_submodel_table_overwrites++;
	else
		bench486_submodel_distinct_entities++;
	bench486_submodel_entity_table[slot] = currententity;
}

void R_DrawSubmodelPolygonsProfileFaceEnter_asm486 (void)
{
	BENCH486_PROFILE_ENTER (BENCH486_PROFILE_RENDERFACE);
}

void R_DrawSubmodelPolygonsProfileFaceLeave_asm486 (void)
{
	BENCH486_PROFILE_LEAVE ();
}
#endif
#endif


/*
================
R_RecursiveWorldNode
================
*/
#ifdef ASM486_BSP_FRAME_COUNT
#define R_BSP_FRAMECOUNT framecount
#else
#define R_BSP_FRAMECOUNT r_framecount
#endif

void __attribute__((regparm(2))) R_RecursiveWorldNode_C
	(mnode_t *node, int clipflags)
{
	int			i, c, side, *pindex;
	vec3_t		acceptpt, rejectpt;
	mplane_t	*plane;
	msurface_t	*surf, **mark;
	mleaf_t		*pleaf;
	double		d, dot;
#ifdef ASM486_BSP_FRAME_COUNT
	int			framecount;
#endif
#ifdef ASM486_BSP_CLIP
	int			asm_clipflags;
#endif

#ifdef PROFILE486
	if (bench486_profile_frame_active)
	{
		bench486_bsp_nodes++;
		if (node->contents == CONTENTS_SOLID)
			bench486_bsp_solid_culls++;
		else if (node->visframe != r_visframecount)
			bench486_bsp_visibility_culls++;
		else if (node->contents < 0)
			bench486_bsp_leaf_nodes++;
		else
			bench486_bsp_internal_nodes++;
	}
#endif

	if (node->visframe != r_visframecount)
		return;

	if (node->contents == CONTENTS_SOLID)
		return;		// solid

// cull the clipping planes if not trivial accept
// FIXME: the compiler is doing a lousy job of optimizing here; it could be
//  twice as fast in ASM
	if (clipflags)
	{
#ifdef ASM486_BSP_CLIP
		asm_clipflags = R_RecursiveWorldNodeClip_asm486 (node, clipflags);
		clipflags = asm_clipflags;
		if (clipflags < 0)
			return;
#else
		for (i=0 ; i<4 ; i++)
		{
			if (! (clipflags & (1<<i)) )
				continue;	// don't need to clip against it

		// generate accept and reject points
		// FIXME: do with fast look-ups or integer tests based on the sign bit
		// of the floating point values

			pindex = pfrustum_indexes[i];

			rejectpt[0] = (float)node->minmaxs[pindex[0]];
			rejectpt[1] = (float)node->minmaxs[pindex[1]];
			rejectpt[2] = (float)node->minmaxs[pindex[2]];
			
			d = DotProduct (rejectpt, view_clipplanes[i].normal);
			d -= view_clipplanes[i].dist;

			if (d <= 0)
				return;

			acceptpt[0] = (float)node->minmaxs[pindex[3+0]];
			acceptpt[1] = (float)node->minmaxs[pindex[3+1]];
			acceptpt[2] = (float)node->minmaxs[pindex[3+2]];

			d = DotProduct (acceptpt, view_clipplanes[i].normal);
			d -= view_clipplanes[i].dist;

			if (d >= 0)
				clipflags &= ~(1<<i);	// node is entirely on screen
		}
#endif
	}
	
#ifdef ASM486_BSP_FRAME_COUNT
	framecount = r_framecount;
#endif

// if a leaf node, draw stuff
	if (node->contents < 0)
	{
		pleaf = (mleaf_t *)node;

		mark = pleaf->firstmarksurface;
		c = pleaf->nummarksurfaces;

		if (c)
		{
			do
			{
				(*mark)->visframe = R_BSP_FRAMECOUNT;
				mark++;
			} while (--c);
		}

	// deal with model fragments in this leaf
		if (pleaf->efrags)
		{
			R_StoreEfrags (&pleaf->efrags);
		}

		pleaf->key = r_currentkey;
		r_currentkey++;		// all bmodels in a leaf share the same key
	}
	else
	{
	// node is just a decision point, so go down the apropriate sides

	// find which side of the node we are on
		plane = node->plane;

#ifdef ASM486_BSP_PLANE_DOT
		dot = R_RecursiveWorldNodePlaneDot_asm486 (plane);
#else
		switch (plane->type)
		{
		case PLANE_X:
			dot = modelorg[0] - plane->dist;
			break;
		case PLANE_Y:
			dot = modelorg[1] - plane->dist;
			break;
		case PLANE_Z:
			dot = modelorg[2] - plane->dist;
			break;
		default:
			dot = DotProduct (modelorg, plane->normal) - plane->dist;
			break;
		}
#endif
	
		if (dot >= 0)
			side = 0;
		else
			side = 1;

	// recurse down the children, front side first
		R_RecursiveWorldNode_C (node->children[side], clipflags);

	// draw stuff
		c = node->numsurfaces;
#ifdef PROFILE486
		if (bench486_profile_frame_active)
			bench486_bsp_surface_tests += c;
#endif

		if (c)
		{
			surf = cl.worldmodel->surfaces + node->firstsurface;

			if (dot < -BACKFACE_EPSILON)
			{
				do
				{
					if ((surf->visframe == R_BSP_FRAMECOUNT) &&
						(surf->flags & SURF_PLANEBACK))
					{
						if (r_drawpolys)
						{
							if (r_worldpolysbacktofront)
							{
								if (numbtofpolys < MAX_BTOFPOLYS)
								{
									pbtofpolys[numbtofpolys].clipflags =
											clipflags;
									pbtofpolys[numbtofpolys].psurf = surf;
									numbtofpolys++;
								}
							}
							else
							{
								R_RenderPoly (surf, clipflags);
							}
						}
						else
						{
							BENCH486_PROFILE_ENTER (BENCH486_PROFILE_RENDERFACE);
							R_RenderFace (surf, clipflags);
							BENCH486_PROFILE_LEAVE ();
						}
					}

					surf++;
				} while (--c);
			}
			else if (dot > BACKFACE_EPSILON)
			{
				do
				{
					if ((surf->visframe == R_BSP_FRAMECOUNT) &&
						!(surf->flags & SURF_PLANEBACK))
					{
						if (r_drawpolys)
						{
							if (r_worldpolysbacktofront)
							{
								if (numbtofpolys < MAX_BTOFPOLYS)
								{
									pbtofpolys[numbtofpolys].clipflags =
											clipflags;
									pbtofpolys[numbtofpolys].psurf = surf;
									numbtofpolys++;
								}
							}
							else
							{
								R_RenderPoly (surf, clipflags);
							}
						}
						else
						{
							BENCH486_PROFILE_ENTER (BENCH486_PROFILE_RENDERFACE);
							R_RenderFace (surf, clipflags);
							BENCH486_PROFILE_LEAVE ();
						}
					}

					surf++;
				} while (--c);
			}

		// all surfaces on the same node share the same sequence number
			r_currentkey++;
		}

	// recurse down the back side
		R_RecursiveWorldNode_C (node->children[!side], clipflags);
	}
}

#undef R_BSP_FRAMECOUNT

#ifdef ASM486_BSP_WALK
void __attribute__((regparm(2))) R_RecursiveWorldNode_asm486
	(mnode_t *node, int clipflags);
#endif

#if !defined(ASM486_PUBLIC_BINDINGS) || !defined(ASM486_BSP_WALK)
void __attribute__((regparm(2))) R_RecursiveWorldNode
	(mnode_t *node, int clipflags)
{
#ifdef ASM486_BSP_WALK
	R_RecursiveWorldNode_asm486 (node, clipflags);
#else
	R_RecursiveWorldNode_C (node, clipflags);
#endif
}
#endif /* public entry is assembly-owned when selected */

#if defined(ASM486_BSP_WALK) && defined(PROFILE486)
void R_BspProfileRenderFaceEnter_asm486 (void)
{
	BENCH486_PROFILE_ENTER (BENCH486_PROFILE_RENDERFACE);
}

void R_BspProfileRenderFaceLeave_asm486 (void)
{
	BENCH486_PROFILE_LEAVE ();
}
#endif

#ifdef BENCH486

/*
===============
R_RecursiveWorldNodePlaneDot_C

Reference version of the small plane-side calculation used by the world BSP
walk.  The production C path remains inline above unless the ASM experiment
is selected.
===============
*/
double R_RecursiveWorldNodePlaneDot_C (mplane_t *plane)
{
	switch (plane->type)
	{
	case PLANE_X:
		return modelorg[0] - plane->dist;
	case PLANE_Y:
		return modelorg[1] - plane->dist;
	case PLANE_Z:
		return modelorg[2] - plane->dist;
	default:
		return DotProduct (modelorg, plane->normal) - plane->dist;
	}
}

/*
===============
R_RecursiveWorldNodeClip_C

Reference version of the visible-node frustum clip block.  A negative return
means that the node is fully outside the view; otherwise the returned value
is the reduced clip mask.
===============
*/
int R_RecursiveWorldNodeClip_C (mnode_t *node, int clipflags)
{
	int			i, *pindex;
	vec3_t		acceptpt, rejectpt;
	double		d;

	for (i=0 ; i<4 ; i++)
	{
		if (! (clipflags & (1<<i)) )
			continue;

		pindex = pfrustum_indexes[i];

		rejectpt[0] = (float)node->minmaxs[pindex[0]];
		rejectpt[1] = (float)node->minmaxs[pindex[1]];
		rejectpt[2] = (float)node->minmaxs[pindex[2]];

		d = DotProduct (rejectpt, view_clipplanes[i].normal);
		d -= view_clipplanes[i].dist;

		if (d <= 0)
			return -1;

		acceptpt[0] = (float)node->minmaxs[pindex[3+0]];
		acceptpt[1] = (float)node->minmaxs[pindex[3+1]];
		acceptpt[2] = (float)node->minmaxs[pindex[3+2]];

		d = DotProduct (acceptpt, view_clipplanes[i].normal);
		d -= view_clipplanes[i].dist;

		if (d >= 0)
			clipflags &= ~(1<<i);
	}

	return clipflags;
}

#endif



/*
================
R_RenderWorld
================
*/
#if defined(ASM486_RENDER_WORLD)
void R_RenderWorld_asm486 (void);
#endif

#if !defined(ASM486_RENDER_WORLD) || defined(BENCH486)
#ifdef ASM486_RENDER_WORLD
void R_RenderWorld_C (void)
#else
void R_RenderWorld (void)
#endif
{
	int			i;
	model_t		*clmodel;
	btofpoly_t	btofpolys[MAX_BTOFPOLYS];
#ifdef PROFILE486
	unsigned long profile_bsp_start;
	profile_bsp_start = bench486_bsp_nodes;
#endif
	BENCH486_PROFILE_ENTER (BENCH486_PROFILE_WORLD_BSP);

	pbtofpolys = btofpolys;

	currententity = &cl_entities[0];
	VectorCopy (r_origin, modelorg);
	clmodel = currententity->model;
	r_pcurrentvertbase = clmodel->vertexes;

	R_RecursiveWorldNode (clmodel->nodes, 15);

// if the driver wants the polygons back to front, play the visible ones back
// in that order
	if (r_worldpolysbacktofront)
	{
		for (i=numbtofpolys-1 ; i>=0 ; i--)
		{
			R_RenderPoly (btofpolys[i].psurf, btofpolys[i].clipflags);
		}
	}
	BENCH486_PROFILE_WORK (BENCH486_PROFILE_WORLD_BSP,
			bench486_bsp_nodes - profile_bsp_start, 0);
	BENCH486_PROFILE_LEAVE ();
}
#endif

#ifdef ASM486_RENDER_WORLD
#if !defined(ASM486_PUBLIC_BINDINGS) || !defined(ASM486_RENDER_WORLD)
void R_RenderWorld (void)
{
	R_RenderWorld_asm486 ();
}
#endif /* public entry is assembly-owned when selected */

#ifdef PROFILE486
void R_RenderWorldProfileEnter_asm486 (void)
{
	BENCH486_PROFILE_ENTER (BENCH486_PROFILE_WORLD_BSP);
}

void R_RenderWorldProfileWork_asm486 (unsigned long start)
{
	BENCH486_PROFILE_WORK (BENCH486_PROFILE_WORLD_BSP,
			bench486_bsp_nodes - start, 0);
}

void R_RenderWorldProfileLeave_asm486 (void)
{
	BENCH486_PROFILE_LEAVE ();
}
#endif
#endif



#if defined(BENCH486) && defined(ASM486_WORLD_CONTROL_FIXTURE)
void R_EntityRotate_WorldControl_C (vec3_t vec)
{
	vec3_t	tvec;

	VectorCopy (vec, tvec);
	vec[0] = DotProduct (entity_rotation[0], tvec);
	vec[1] = DotProduct (entity_rotation[1], tvec);
	vec[2] = DotProduct (entity_rotation[2], tvec);
}

void R_RotateBmodel_WorldControl_C (void)
{
	float	angle, s, c, temp1[3][3], temp2[3][3], temp3[3][3];

// TODO: should use a look-up table
// TODO: should really be stored with the entity instead of being reconstructed
// TODO: could cache lazily, stored in the entity
// TODO: share work with R_SetUpAliasTransform

// yaw
	angle = currententity->angles[YAW];
	angle = angle * M_PI*2 / 360;
	s = sin(angle);
	c = cos(angle);

	temp1[0][0] = c;
	temp1[0][1] = s;
	temp1[0][2] = 0;
	temp1[1][0] = -s;
	temp1[1][1] = c;
	temp1[1][2] = 0;
	temp1[2][0] = 0;
	temp1[2][1] = 0;
	temp1[2][2] = 1;


// pitch
	angle = currententity->angles[PITCH];
	angle = angle * M_PI*2 / 360;
	s = sin(angle);
	c = cos(angle);

	temp2[0][0] = c;
	temp2[0][1] = 0;
	temp2[0][2] = -s;
	temp2[1][0] = 0;
	temp2[1][1] = 1;
	temp2[1][2] = 0;
	temp2[2][0] = s;
	temp2[2][1] = 0;
	temp2[2][2] = c;

	R_ConcatRotations (temp2, temp1, temp3);

// roll
	angle = currententity->angles[ROLL];
	angle = angle * M_PI*2 / 360;
	s = sin(angle);
	c = cos(angle);

	temp1[0][0] = 1;
	temp1[0][1] = 0;
	temp1[0][2] = 0;
	temp1[1][0] = 0;
	temp1[1][1] = c;
	temp1[1][2] = s;
	temp1[2][0] = 0;
	temp1[2][1] = -s;
	temp1[2][2] = c;

	R_ConcatRotations (temp1, temp3, entity_rotation);

//
// rotate modelorg and the transformation matrix
//
	R_EntityRotate_WorldControl_C (modelorg);
	R_EntityRotate_WorldControl_C (vpn);
	R_EntityRotate_WorldControl_C (vright);
	R_EntityRotate_WorldControl_C (vup);

	Bench486WorldControlFrustum ();
}

void R_RotateBmodelCached_WorldControl_C (void)
{
	unsigned				slot;
	int						i, j;


	slot = ((unsigned)currententity >> 5) & (BMODEL_ROTCACHE_SLOTS - 1);
	if (worldcontrol_cache_ent[slot] == currententity && worldcontrol_cache_frame[slot] == r_framecount)
	{
		for (i = 0 ; i < 3 ; i++)
			for (j = 0 ; j < 3 ; j++)
				entity_rotation[i][j] = worldcontrol_cache_rot[slot][i][j];
		R_EntityRotate_WorldControl_C (modelorg);
		R_EntityRotate_WorldControl_C (vpn);
		R_EntityRotate_WorldControl_C (vright);
		R_EntityRotate_WorldControl_C (vup);
		Bench486WorldControlFrustum ();
		return;
	}

	R_RotateBmodel_WorldControl_C ();
	worldcontrol_cache_ent[slot] = currententity;
	worldcontrol_cache_frame[slot] = r_framecount;
	for (i = 0 ; i < 3 ; i++)
		for (j = 0 ; j < 3 ; j++)
			worldcontrol_cache_rot[slot][i][j] = entity_rotation[i][j];
}
#endif
