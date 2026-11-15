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
// r_local.h -- private refresh defs

#include "renderer/r_shared.h"

#define BMODEL_FULLY_CLIPPED	0x10 // value returned by R_BmodelCheckBBox ()
									 //  if bbox is trivially rejected

//===========================================================================
// viewmodel lighting

typedef struct {
	int			ambientlight;
	int			shadelight;
	float		*plightvec;
} alight_t;

//===========================================================================
// clipped bmodel edges

typedef struct bedge_s
{
	mvertex_t		*v[2];
	struct bedge_s	*pnext;
} bedge_t;

typedef struct {
	float	fv[3];		// viewspace x, y
} auxvert_t;

extern float aliastransform[3][4];
extern vec3_t r_plightvec;
extern int r_ambientlight;
extern float r_shadelight;
extern float r_shadelight;

//===========================================================================

extern cvar_t	r_draworder;
extern cvar_t	r_speeds;
extern cvar_t	r_timegraph;
extern cvar_t	r_graphheight;
extern cvar_t	r_clearcolor;
extern cvar_t	r_waterwarp;
extern cvar_t	r_fullbright;
extern cvar_t	r_drawentities;
extern cvar_t	r_aliasstats;
extern cvar_t	r_dspeeds;
extern cvar_t	r_drawflat;
extern cvar_t	r_ambient;
extern cvar_t	r_reportsurfout;
extern cvar_t	r_maxsurfs;
extern cvar_t	r_numsurfs;
extern cvar_t	r_reportedgeout;
extern cvar_t	r_maxedges;
extern cvar_t	r_numedges;

#define XCENTERING	(1.0 / 2.0)
#define YCENTERING	(1.0 / 2.0)

#define CLIP_EPSILON		0.001

#define BACKFACE_EPSILON	0.01

//===========================================================================

#define	DIST_NOT_SET	98765

// !!! if this is changed, it must be changed in asm_draw.h too !!!
typedef struct clipplane_s
{
	vec3_t		normal;
	float		dist;
	struct		clipplane_s	*next;
	byte		leftedge;
	byte		rightedge;
	byte		reserved[2];
} clipplane_t;

extern	clipplane_t	view_clipplanes[4];

//=============================================================================

void R_RenderWorld (void);
#ifdef ASM486_RENDER_WORLD
void R_RenderWorld_asm486 (void);
#ifdef BENCH486
void R_RenderWorld_C (void);
#endif
#ifdef PROFILE486
void R_RenderWorldProfileEnter_asm486 (void);
void R_RenderWorldProfileWork_asm486 (unsigned long start);
void R_RenderWorldProfileLeave_asm486 (void);
#endif
#endif

void R_EdgeDrawing (void);
#ifdef ASM486_EDGE_DRAWING
void R_EdgeDrawing_asm486 (void);
#ifdef BENCH486
void R_EdgeDrawing_C (void);
#endif
#ifdef PROFILE486
void R_EdgeDrawingProfileEnter_asm486 (void);
void R_EdgeDrawingProfileLeave_asm486 (void);
void R_EdgeDrawingProfileWorldStart_asm486 (void);
void R_EdgeDrawingProfileWorldEnd_asm486 (void);
void R_EdgeDrawingProfileBrushEnter_asm486 (void);
void R_EdgeDrawingProfileBrushLeave_asm486 (void);
#endif
#endif

//=============================================================================

extern	mplane_t	screenedge[4];

extern	vec3_t	r_origin;

extern	vec3_t	r_entorigin;

extern	float	screenAspect;
extern	float	verticalFieldOfView;
extern	float	xOrigin, yOrigin;

extern	int		r_visframecount;

//=============================================================================

extern int	vstartscan;


void R_ClearPolyList (void);
void R_DrawPolyList (void);

//
// current entity info
//
extern	qboolean		insubmodel;
extern	vec3_t			r_worldmodelorg;


void R_DrawSprite (void);
void R_DrawSprite_C (void);
void R_DrawSprite_asm486 (void);
mspriteframe_t *R_GetSpriteframePublic_asm486 (msprite_t *psprite);
/* Keep the public argument type visible when its implementation is assembly.
 * An implicit declaration would promote beamlength to double at C call sites. */
void R_RotateSprite (float beamlength);
void R_RotateSprite_C (float beamlength);
void R_RotateSprite_asm486 (float beamlength);
extern int clip_current;
extern vec5_t clip_verts[2][MAXWORKINGVERTS];
extern int sprite_width, sprite_height;
void R_SetupAndDrawSprite (void);
void R_SetupAndDrawSprite_C (void);
void R_SetupAndDrawSprite_asm486 (void);
void __attribute__((regparm(2))) R_RecursiveWorldNode
	(mnode_t *node, int clipflags);
int R_AliasClip (finalvert_t *in, finalvert_t *out, int flag, int count,
	void (*clip)(finalvert_t *pfv0, finalvert_t *pfv1, finalvert_t *out));
void R_AliasTransformVector (vec3_t in, vec3_t out);
void R_AliasTransformFinalVert (finalvert_t *fv, auxvert_t *av,
	trivertx_t *pverts, stvert_t *pstverts);
void R_RecursiveClipBPoly (bedge_t *pedges, mnode_t *pnode, msurface_t *psurf);
void R_GenerateSpansBackward (void);
void R_CleanupSpan (void);
void R_LeadingEdgeBackwards (edge_t *edge);
void R_TrailingEdge (surf_t *surf, edge_t *edge);
int R_ClipSpriteFace (int nump, clipplane_t *pclipplane);
int R_ClipSpriteFace_C (int nump, clipplane_t *pclipplane);
int R_ClipSpriteFace_asm486 (int nump, clipplane_t *pclipplane);
mspriteframe_t *R_GetSpriteframe_C (msprite_t *psprite);
mspriteframe_t *R_GetSpriteframe (msprite_t *psprite);
mspriteframe_t *R_GetSpriteframe_asm486 (msprite_t *psprite, int frame,
		double cltime, float syncbase);
void R_RenderFace (msurface_t *fa, int clipflags);
#ifdef ASM486_RENDER_FACE
void R_RenderFace_asm486 (msurface_t *fa, int clipflags,
	medge_t *pedges, int *psurfedges);
void R_RenderFaceGradient_asm486 (mplane_t *plane);
#ifdef BENCH486
void R_RenderFace_C (msurface_t *fa, int clipflags);
#endif
#endif
void R_RenderPoly (msurface_t *fa, int clipflags);
#ifdef ASM486_RENDER_POLY
void R_RenderPoly_asm486 (msurface_t *fa, int clipflags);
#ifdef BENCH486
void R_RenderPoly_C (msurface_t *fa, int clipflags);
#endif
#endif
void R_RenderBmodelFace (bedge_t *pedges, msurface_t *psurf);
#ifdef ASM486_RENDER_BMODEL_FACE
void R_RenderBmodelFace_asm486 (bedge_t *pedges, msurface_t *psurf);
void R_RenderBmodelFaceGradient_asm486 (mplane_t *plane);
#ifdef BENCH486
void R_RenderBmodelFace_C (bedge_t *pedges, msurface_t *psurf);
#endif
#endif
void R_TransformPlane (mplane_t *p, float *normal, float *dist);
void R_SetUpFrustumIndexes (void);
#if defined(BENCH486) && defined(ASM486_TRANSFORM_FRUSTUM)
void R_SetUpFrustumIndexes_C (void);
#endif
void R_TransformFrustum (void);
void R_SetSkyFrame (void);
void R_DrawSurfaceBlock16 (void);
void R_DrawSurfaceBlock8 (void);
void R_BuildLightMap (void);
#if defined(ASM486_SURFACE_ZGRADIENTS)
void R_SetSurfaceZGradients (mplane_t *plane);
#endif
#if defined(BENCH486) && defined(ASM486_SURFACE_ZGRADIENTS)
void R_SetSurfaceZGradients_C (mplane_t *plane);
void R_SetSurfaceZGradients_asm486 (mplane_t *plane);
extern int r_zgradient_asm_cache_frame;
extern mplane_t *r_zgradient_asm_cache_plane;
extern entity_t *r_zgradient_asm_cache_entity;
extern float r_zgradient_asm_cache_zistepu;
extern float r_zgradient_asm_cache_zistepv;
extern float r_zgradient_asm_cache_ziorigin;
#endif
#if defined(ASM486_SURFACE_DRAW) && defined(BENCH486)
void R_DrawSurface_C (void);
#endif
#if defined(ASM486_SURFACE_DRAW) && defined(PROFILE486)
void R_DrawSurfaceProfileBegin_asm486_C (void);
void R_DrawSurfaceProfileAfterLightmap_asm486_C (void);
void R_DrawSurfaceProfileCountBlocks_asm486_C (void);
void R_DrawSurfaceProfileStartBlocks_asm486_C (void);
void R_DrawSurfaceProfileFinish_asm486_C (void);
#endif
texture_t *R_TextureAnimation (texture_t *base);
texture_t *R_TextureAnimationFrame_C (texture_t *base, int relative);
#ifdef BENCH486
texture_t *R_TextureAnimation_C (texture_t *base);
#endif
void R_BuildLightMapNormalize_C (unsigned *lights, int size);
void R_AddDynamicLights_C (void);
void R_AddDynamicLights (void);
int R_DlightContributes (msurface_t *surf);
#ifdef ASM486_DYNAMIC_LIGHT_PROJECTION
#ifdef BENCH486
int R_AddDynamicLightProject_C (int lnum, msurface_t *surf, int smax,
	int tmax, float *local0, float *local1, int *local0_int,
	int *local1_int, int *idist_limit, int *irad, int *all_lit);
#endif
int R_AddDynamicLightProject_asm486 (int lnum, msurface_t *surf, int smax,
	int tmax, float *local0, float *local1, int *local0_int,
	int *local1_int, int *idist_limit, int *irad, int *all_lit);
#endif
#ifdef ASM486_DYNAMIC_LIGHT_ORCHESTRATION
int R_AddDynamicLightSamples_C (unsigned *lights, int smax, int tmax,
	float local0, float local1, int idist_limit, int irad);
#ifdef BENCH486
void R_AddDynamicLightsOrchestration_C (void);
#endif
#endif
#ifdef ASM486_DLIGHT_CONTRIBUTES
int R_DlightContributes_asm486 (msurface_t *surf);
#ifdef BENCH486
int R_DlightContributes_C (msurface_t *surf);
#endif
#endif
#if defined(BENCH486) && defined(ASM486_LIGHTMAP_BUILD)
void R_BuildLightMap_C (void);
#endif
#ifdef ASM486_LIGHTMAP_BUILD
extern unsigned blocklights[18*18];
extern unsigned lightmap_single_table[256];
extern unsigned lightmap_single_first;
extern int lightmap_single_inverse_scale;
extern qboolean lightmap_single_table_valid;
#endif
#ifdef BENCH486
double R_RecursiveWorldNodePlaneDot_C (mplane_t *plane);
int R_RecursiveWorldNodeClip_C (mnode_t *node, int clipflags);
int R_AliasCheckBBoxProject_C (auxvert_t *viewaux, finalvert_t *viewpts,
	int numv);
void R_AliasTransformFinalVert_C (finalvert_t *fv, auxvert_t *av,
	trivertx_t *pverts, stvert_t *pstverts);
#endif
#if defined(__i386__)
texture_t *R_TextureAnimation_asm486 (texture_t *base);
texture_t *R_TextureAnimationFrame_asm486 (texture_t *base, int relative);
void R_BuildLightMapNormalize_asm486 (unsigned *lights, int size);
int R_AddDynamicLightSamples_asm486 (unsigned *blocklights, int smax,
	int tmax, int local0, int local1, float local1_float,
	int idist_limit, int irad, int all_lit);
double R_RecursiveWorldNodePlaneDot_asm486 (mplane_t *plane);
int R_RecursiveWorldNodeClip_asm486 (mnode_t *node, int clipflags);
int R_AliasCheckBBoxProject_asm486 (auxvert_t *viewaux, finalvert_t *viewpts,
	int numv);
void R_AliasTransformVector_asm486 (vec3_t in, vec3_t out);
void R_AliasTransformFinalVert_asm486 (finalvert_t *fv, auxvert_t *av,
		trivertx_t *pverts, stvert_t *pstverts);
void R_ConcatTransforms_asm486 (float in1[3][4], float in2[3][4],
		float out[3][4]);
void R_AliasSetViewMatrix_asm486 (const float *right, const float *up,
		const float *forward, float *out);
#endif
#ifdef BENCH486
void R_AliasTransformVector_C (vec3_t in, vec3_t out);
#endif

#if defined(__i386__)

void R_DrawSurfaceBlock8_mip0 (void);
void R_DrawSurfaceBlock8_mip1 (void);
void R_DrawSurfaceBlock8_mip2 (void);
void R_DrawSurfaceBlock8_mip3 (void);

#endif

void R_GenSkyTile (void *pdest);
void R_GenSkyTile16 (void *pdest);
void R_Surf8Patch (void);
void R_Surf16Patch (void);
void R_DrawSubmodelPolygons (model_t *pmodel, int clipflags);
#ifdef ASM486_DRAW_SUBMODEL_POLYGONS
void R_DrawSubmodelPolygons_asm486 (model_t *pmodel, int clipflags);
#ifdef BENCH486
void R_DrawSubmodelPolygons_C (model_t *pmodel, int clipflags);
#endif
#ifdef PROFILE486
void R_DrawSubmodelPolygonsProfileEntry_asm486 (int numsurfaces);
void R_DrawSubmodelPolygonsProfileFaceEnter_asm486 (void);
void R_DrawSubmodelPolygonsProfileFaceLeave_asm486 (void);
#endif
#endif
#ifdef ASM486_BMODEL_POLYGON_CLIP
void R_RecursiveClipBPoly_asm486 (bedge_t *pedges, mnode_t *pnode,
		msurface_t *psurf);
#ifdef BENCH486
void R_RecursiveClipBPoly_C (bedge_t *pedges, mnode_t *pnode,
		msurface_t *psurf);
#endif
#endif
void R_DrawSolidClippedSubmodelPolygons (model_t *pmodel);
#ifdef ASM486_DRAW_SOLID_CLIPPED_SUBMODEL_POLYGONS
void R_DrawSolidClippedSubmodelPolygons_asm486 (model_t *pmodel);
#ifdef BENCH486
void R_DrawSolidClippedSubmodelPolygons_C (model_t *pmodel);
#endif
#endif

void R_AddPolygonEdges (emitpoint_t *pverts, int numverts, int miplevel);
surf_t *R_GetSurf (void);
void __attribute__((regparm(1))) R_AliasDrawModel (alight_t *plighting);
void R_AliasProjectFinalVert (finalvert_t *fv, auxvert_t *av);
void R_AliasSetupLighting_C (alight_t *plighting, const float *forward,
		const float *right, const float *up);
void R_AliasSetupLighting_asm486 (alight_t *plighting,
		const float *forward, const float *right, const float *up);
void R_AliasSetupFrame_C (int frame, double cltime, float syncbase);
void R_AliasSetupFrame_asm486 (int frame, double cltime, float syncbase);
maliasskindesc_t *R_AliasSetupSkinSelect_C (int skinnum, double cltime,
		float syncbase);
maliasskindesc_t *R_AliasSetupSkinSelect_asm486 (int skinnum,
		double cltime, float syncbase);
#if defined(__i386__)
void R_AliasProjectFinalVert_asm486 (finalvert_t *fv, auxvert_t *av);
#endif
#if defined(ASM486_ALIAS_PROJECT)
#define R_AliasProjectFinalVertDispatch R_AliasProjectFinalVert_asm486
#else
#define R_AliasProjectFinalVertDispatch R_AliasProjectFinalVert
#endif
void R_BeginEdgeFrame (void);
void R_ScanEdges (void);
#ifdef ASM486_SCAN_EDGES
void R_ScanEdges_asm486 (void);
#ifdef BENCH486
void R_ScanEdges_C (void);
#endif
#ifdef PROFILE486
void R_ScanEdgesProfileBegin_asm486 (double *start);
void R_ScanEdgesProfileEnd_asm486 (double *start,
		unsigned long scanline_start);
#endif
#endif
void D_DrawSurfaces (void);
void R_InsertNewEdges (edge_t *edgestoadd, edge_t *edgelist);
void R_StepActiveU (edge_t *pedge);
void R_RemoveEdges (edge_t *pedge);
#ifdef ASM486_EDGE_LIST
void R_InsertNewEdges_asm486 (edge_t *edgestoadd, edge_t *edgelist);
void R_RemoveEdges_asm486 (edge_t *pedge);
void R_StepActiveU_asm486 (edge_t *pedge);
#ifdef BENCH486
void R_InsertNewEdges_C (edge_t *edgestoadd, edge_t *edgelist);
void R_RemoveEdges_C (edge_t *pedge);
void R_StepActiveU_C (edge_t *pedge);
#endif
#endif
#ifdef ASM486_BACKWARD_SPANS
void R_CleanupSpan_asm486 (void);
void R_LeadingEdgeBackwards_asm486 (edge_t *edge);
void R_TrailingEdge_asm486 (surf_t *surf, edge_t *edge);
void R_GenerateSpansBackward_asm486 (void);
#ifdef BENCH486
void R_CleanupSpan_C (void);
void R_LeadingEdgeBackwards_C (edge_t *edge);
void R_TrailingEdge_C (surf_t *surf, edge_t *edge);
void R_GenerateSpansBackward_C (void);
#endif
#endif

extern void R_Surf8Start (void);
extern void R_Surf8End (void);
extern void R_Surf16Start (void);
extern void R_Surf16End (void);
extern void R_EdgeCodeStart (void);
extern void R_EdgeCodeEnd (void);

extern void R_RotateBmodel (void);
extern void R_RotateBmodelCached (void);

extern int	c_faceclip;
extern int	r_polycount;
extern int	r_wholepolycount;

extern	model_t		*cl_worldmodel;

extern int		*pfrustum_indexes[4];

// !!! if this is changed, it must be changed in asm_draw.h too !!!
#define	NEAR_CLIP	0.01

extern int			ubasestep, errorterm, erroradjustup, erroradjustdown;
extern int			vstartscan;

extern fixed16_t	sadjust, tadjust;
extern fixed16_t	bbextents, bbextentt;

#define MAXBVERTINDEXES	1000	// new clipped vertices when clipping bmodels
								//  to the world BSP
extern mvertex_t	*r_ptverts, *r_ptvertsmax;

extern vec3_t			sbaseaxis[3], tbaseaxis[3];
extern float			entity_rotation[3][3];

extern int		reinit_surfcache;

extern int		r_currentkey;
extern int		r_currentbkey;

typedef struct btofpoly_s {
	int			clipflags;
	msurface_t	*psurf;
} btofpoly_t;

#define MAX_BTOFPOLYS	5000	// FIXME: tune this

extern int			numbtofpolys;
extern btofpoly_t	*pbtofpolys;

void	R_InitTurb (void);
void	R_ZDrawSubmodelPolys (model_t *clmodel);

//=========================================================
// Alias models
//=========================================================

#define ALIAS_Z_CLIP_PLANE	5

extern int				numverts;
extern int				a_skinwidth;
extern mtriangle_t		*ptriangles;
extern int				numtriangles;
extern aliashdr_t		*paliashdr;
extern trivertx_t		*r_apverts;
extern mdl_t			*pmdl;
extern float			leftclip, topclip, rightclip, bottomclip;
extern int				r_acliptype;
extern finalvert_t		*pfinalverts;
extern auxvert_t		*pauxverts;

qboolean R_AliasCheckBBox (void);

//=========================================================
// turbulence stuff

#define	AMP		8*0x10000
#define	AMP2	3
#define	SPEED	20

//=========================================================
// particle stuff

void R_DrawParticles (void);
void R_InitParticles (void);
void R_ClearParticles (void);
void R_ReadPointFile_f (void);
void R_SurfacePatch (void);

extern int		r_amodels_drawn;
extern edge_t	*auxedges;
extern int		r_numallocatededges;
extern edge_t	*r_edges, *edge_p, *edge_max;

extern	edge_t	*newedges[MAXHEIGHT];
extern	edge_t	*removeedges[MAXHEIGHT];

extern	int	screenwidth;

// FIXME: make stack vars when debugging done
extern	edge_t	edge_head;
extern	edge_t	edge_tail;
extern	edge_t	edge_aftertail;
extern int		r_bmodelactive;
extern vrect_t	*pconupdate;

extern float		aliasxscale, aliasyscale, aliasxcenter, aliasycenter;
extern float		ziscale;
extern float		r_aliastransition, r_resfudge;

extern int		r_outofsurfaces;
extern int		r_outofedges;

extern mvertex_t	*r_pcurrentvertbase;
extern int			r_maxvalidedgeoffset;

void R_AliasClipTriangle (mtriangle_t *ptri);

extern float	r_time1;
extern float	dp_time1, dp_time2, db_time1, db_time2, rw_time1, rw_time2;
extern float	se_time1, se_time2, de_time1, de_time2, dv_time1, dv_time2;
extern int		r_frustum_indexes[4*6];
extern int		r_maxsurfsseen, r_maxedgesseen, r_cnumsurfs;
extern qboolean	r_surfsonstack;
extern cshift_t	cshift_water;
extern qboolean	r_dowarpold, r_viewchanged;

extern mleaf_t	*r_viewleaf, *r_oldviewleaf;

extern vec3_t	r_emins, r_emaxs;
extern mnode_t	*r_pefragtopnode;
extern int		r_clipflags;
extern int		r_dlightframecount;
extern int		r_dlight_contributed;
extern qboolean	r_fov_greater_than_90;

void R_StoreEfrags (efrag_t **ppefrag);
void R_TimeRefresh_f (void);
void R_TimeGraph (void);
void R_PrintAliasStats (void);
void R_PrintTimes (void);
void R_PrintDSpeeds (void);
void R_AnimateLight (void);
int R_LightPoint (vec3_t p);
void R_SetupFrame (void);
void R_AliasSetViewMatrix (void);
void R_cshift_f (void);
void R_EmitEdge (mvertex_t *pv0, mvertex_t *pv1);
void R_EmitCachedEdge (void);
#ifdef ASM486_EMIT_CACHED_EDGE
void R_EmitCachedEdge_asm486 (void);
#ifdef BENCH486
void R_EmitCachedEdge_C (void);
#endif
#endif
void R_ClipEdge (mvertex_t *pv0, mvertex_t *pv1, clipplane_t *clip);
void R_SplitEntityOnNode2 (mnode_t *node);
void R_MarkLights (dlight_t *light, int bit, mnode_t *node);
void R_MarkLights_asm486 (dlight_t *light, int bit, mnode_t *node);
void R_PushDlights (void);
#ifdef BENCH486
typedef struct
{
	float planedist;
	float rad;
	float fmin;
	float local0;
	float local1;
	float cs;
	float ct;
	int fmin_scaled;
	int sd;
	int td;
	int idist;
	int stage;
	int marked;
} bench486_mark_lights_probe_t;
extern bench486_mark_lights_probe_t *bench486_mark_lights_probe;
void R_MarkLights_C (dlight_t *light, int bit, mnode_t *node);
void R_PushDlights_C (void);
#endif
