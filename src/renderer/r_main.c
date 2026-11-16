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
// r_main.c

#include <stddef.h>
#include <math.h>
#include <stdlib.h>
#include <string.h>

#include "common.h"
#include "cmd.h"
#include "console.h"
#include "cvar.h"
#include "mathlib.h"
#include "bspfile.h"
#include "zone.h"
#include "model.h"
#include "client.h"
#include "host.h"
#include "render.h"
#include "view.h"
#include "vid.h"
#include "screen.h"
#include "sys.h"
#include "d_iface.h"
#include "tests/bench486/bench486_profile.h"
#include "renderer/r_local.h"

//define	PASSAGES

void		*colormap;
vec3_t		viewlightvec;
alight_t	r_viewlighting = {128, 192, viewlightvec};
float		r_time1;
int			r_numallocatededges;
qboolean	r_drawpolys;
qboolean	r_drawculledpolys;
qboolean	r_worldpolysbacktofront;
qboolean	r_recursiveaffinetriangles = true;
int			r_pixbytes = 1;
float		r_aliasuvscale = 1.0;
int			r_outofsurfaces;
int			r_outofedges;

qboolean	r_dowarp, r_dowarpold, r_viewchanged;

int			numbtofpolys;
btofpoly_t	*pbtofpolys;
mvertex_t	*r_pcurrentvertbase;

int			c_surf;
int			r_maxsurfsseen, r_maxedgesseen, r_cnumsurfs;
qboolean	r_surfsonstack;
int			r_clipflags;

byte		*r_warpbuffer;
static byte	*r_warpbuffer_storage;
static model_t	*r_warp_depth_world;
static unsigned long r_warp_depth_value;
static int		r_warp_depth_numnodes;
static int		r_warp_depth_numleafs;
static qboolean	r_warp_depth_cached;
static qboolean	r_warp_depth_valid;
static qboolean	r_render_stack_headroom_reported;
static qboolean	r_render_stack_failure_reported;
static qboolean	r_warp_stack_status_reported;
#ifdef BENCH486
static qboolean r_bench_warp_force_short_stack;
static unsigned long r_bench_warp_actual_stack_available;
static int r_bench_warp_report_handle = -1;
static void R_BenchWarpLog (const char *text, qboolean close_report);
static void R_BenchWarpAllocated_f (void);
static void R_BenchWarpFallback_f (void);
static void R_BenchWarpShort_f (void);
#endif

/* Stack costs are pinned by tools/renderer-stack-budget.py against the
 * generated renderer assembly. The edge frame includes its saved registers
 * and aligned-array reservation; the selected world frame includes the
 * back-to-front polygon list. The tree step is the larger of clipped-bmodel
 * recursion and world traversal. The assembly BSP walker adds its fixed frame
 * and entry return separately; its continuation record is checked against the
 * selected tree step. The polygon path is bounded by its generated frame plus
 * the nested call path. The dispatcher derives depth from the loaded BSP and
 * adds no environment-specific reserve. */
#define R_WARP_BUFFER_BYTES		(WARP_WIDTH * WARP_HEIGHT)
#define R_WARP_FALLBACK_FRAME_BYTES	64012UL /* push ebx + sub esp,64008 */
#ifdef ASM486_BSP_WALK
#define R_WARP_WORLD_WALK_FIXED_BYTES	68UL /* 64-byte frame + entry return */
#else
#define R_WARP_WORLD_WALK_FIXED_BYTES	0UL
#endif
#define R_RENDER_C_WORLD_FRAME_BYTES	40012UL
#define R_RENDER_ASM_WORLD_FRAME_BYTES	40020UL
#if defined(ASM486_BMODEL_POLYGON_CLIP)
#ifdef PROFILE486
#define R_WARP_TREE_STEP_BYTES		136UL
#else
#define R_WARP_TREE_STEP_BYTES		128UL
#endif
#else
#define R_WARP_TREE_STEP_BYTES		124UL
#endif
#define R_WARP_RENDER_POLY_PATH_BYTES	4648UL
#ifdef PROFILE486
#define R_WARP_RENDER_VIEW_FRAME_BYTES	40UL
#else
#define R_WARP_RENDER_VIEW_FRAME_BYTES	12UL
#endif
#ifdef ASM486_EDGE_DRAWING
#ifdef PROFILE486
#define R_RENDER_EDGE_FRAME_BYTES	128224UL
#else
#define R_RENDER_EDGE_FRAME_BYTES	128176UL
#endif
#else
#ifdef PROFILE486
#define R_RENDER_EDGE_FRAME_BYTES	128160UL
#else
#define R_RENDER_EDGE_FRAME_BYTES	128108UL
#endif
#endif
#ifdef ASM486_RENDER_WORLD
#ifdef PROFILE486
#define R_RENDER_WORLD_FRAME_BYTES	40068UL
#else
#define R_RENDER_WORLD_FRAME_BYTES	R_RENDER_ASM_WORLD_FRAME_BYTES
#endif
#else
#ifdef PROFILE486
#define R_RENDER_WORLD_FRAME_BYTES	40056UL
#else
#define R_RENDER_WORLD_FRAME_BYTES	R_RENDER_C_WORLD_FRAME_BYTES
#endif
#endif
#define R_WARP_CALL_BYTES		4UL

extern unsigned __djgpp_stack_limit;
extern unsigned __djgpp_stack_top;

qboolean	r_fov_greater_than_90;

//
// view origin
//
vec3_t	vup, base_vup;
vec3_t	vpn, base_vpn;
vec3_t	vright, base_vright;
vec3_t	r_origin;

//
// screen size info
//
refdef_t	r_refdef;
float		xcenter, ycenter;
float		xscale, yscale;
float		xscaleinv, yscaleinv;
float		xscaleshrink, yscaleshrink;
float		aliasxscale, aliasyscale, aliasxcenter, aliasycenter;

int		screenwidth;

float	pixelAspect;
float	screenAspect;
float	verticalFieldOfView;
float	xOrigin, yOrigin;

mplane_t	screenedge[4];

//
// refresh flags
//
int		r_framecount = 1;	// so frame counts initialized to 0 don't match
int		r_visframecount;
int		d_spanpixcount;
int		r_polycount;
int		r_drawnpolycount;
int		r_wholepolycount;

#define		VIEWMODNAME_LENGTH	256
char		viewmodname[VIEWMODNAME_LENGTH+1];
int			modcount;

int			*pfrustum_indexes[4];
int			r_frustum_indexes[4*6];

int		reinit_surfcache = 1;	// if 1, surface cache is currently empty and
								// must be reinitialized for current cache size

mleaf_t		*r_viewleaf, *r_oldviewleaf;

texture_t	*r_notexture_mip;

float		r_aliastransition, r_resfudge;

int		d_lightstylevalue[256];	// 8.8 fraction of base light value

float	dp_time1, dp_time2, db_time1, db_time2, rw_time1, rw_time2;
float	se_time1, se_time2, de_time1, de_time2, dv_time1, dv_time2;

void R_MarkLeaves (void);

cvar_t	r_draworder = {"r_draworder","0"};
cvar_t	r_speeds = {"r_speeds","0"};
cvar_t	r_timegraph = {"r_timegraph","0"};
cvar_t	r_graphheight = {"r_graphheight","10"};
cvar_t	r_clearcolor = {"r_clearcolor","0"};
cvar_t	r_waterwarp = {"r_waterwarp","1"};
cvar_t	r_fullbright = {"r_fullbright","0"};
cvar_t	r_drawentities = {"r_drawentities","1"};
cvar_t	r_drawviewmodel = {"r_drawviewmodel","1"};
cvar_t	r_aliasstats = {"r_polymodelstats","0"};
cvar_t	r_dspeeds = {"r_dspeeds","0"};
cvar_t	r_drawflat = {"r_drawflat", "0"};
cvar_t	r_ambient = {"r_ambient", "0"};
cvar_t	r_reportsurfout = {"r_reportsurfout", "0"};
cvar_t	r_maxsurfs = {"r_maxsurfs", "0"};
cvar_t	r_numsurfs = {"r_numsurfs", "0"};
cvar_t	r_reportedgeout = {"r_reportedgeout", "0"};
cvar_t	r_maxedges = {"r_maxedges", "0"};
cvar_t	r_numedges = {"r_numedges", "0"};
cvar_t	r_aliastransbase = {"r_aliastransbase", "200"};
cvar_t	r_aliastransadj = {"r_aliastransadj", "100"};

extern cvar_t	scr_fov;

void CreatePassages (void);
void SetVisibilityByPassages (void);
void R_InitWarpBuffer (void);
void R_InvalidateWarpStackCache (void);
void R_RenderViewDispatch (void (*render_view) (void));

/*
==================
R_InitTextures
==================
*/
#ifdef ASM486_FRAME_CONTROL
#include "renderer/asm_framecontrol.h"
#ifdef ASM486_EDGE_DRAWING
#define FRAME_CONTROL_RESTORE_EDGE_SELECTOR
#undef ASM486_EDGE_DRAWING
#endif
#define R_InitTextures R_InitTextures_C
void R_InitTextures_C (void);
#define R_Init R_Init_C
void R_Init_C (void);
#define R_NewMap R_NewMap_C
void R_NewMap_C (void);
#define R_SetVrect R_SetVrect_C
void R_SetVrect_C (vrect_t *pvrectin, vrect_t *pvrect, int lineadj);
#define R_ViewChanged R_ViewChanged_C
void R_ViewChanged_C (vrect_t *pvrect, int lineadj, float aspect);
#define R_MarkLeaves R_MarkLeaves_C
void R_MarkLeaves_C (void);
#define R_DrawEntitiesOnList R_DrawEntitiesOnList_C
void R_DrawEntitiesOnList_C (void);
#define R_DrawViewModel R_DrawViewModel_C
void R_DrawViewModel_C (void);
#define R_BmodelCheckBBox R_BmodelCheckBBox_C
int R_BmodelCheckBBox_C (model_t *clmodel, float *minmaxs);
#define R_DrawBEntitiesOnList R_DrawBEntitiesOnList_C
void R_DrawBEntitiesOnList_C (void);
#define R_EdgeDrawing R_EdgeDrawing_C
void R_EdgeDrawing_C (void);
#define R_RenderView_ R_RenderView__C
void R_RenderView__C (void);
#define R_RenderView R_RenderView_C
void R_RenderView_C (void);
#define R_InitTurb R_InitTurb_C
void R_InitTurb_C (void);
#endif
#if !defined(ASM486_FRAME_CONTROL) || defined(BENCH486)
void	R_InitTextures (void)
{
	int		x,y, m;
	byte	*dest;
	
// create a simple checkerboard texture for the default
	r_notexture_mip = Hunk_AllocName (sizeof(texture_t) + 16*16+8*8+4*4+2*2, "notexture");
	
	r_notexture_mip->width = r_notexture_mip->height = 16;
	r_notexture_mip->offsets[0] = sizeof(texture_t);
	r_notexture_mip->offsets[1] = r_notexture_mip->offsets[0] + 16*16;
	r_notexture_mip->offsets[2] = r_notexture_mip->offsets[1] + 8*8;
	r_notexture_mip->offsets[3] = r_notexture_mip->offsets[2] + 4*4;
	
	for (m=0 ; m<4 ; m++)
	{
		dest = (byte *)r_notexture_mip + r_notexture_mip->offsets[m];
		for (y=0 ; y< (16>>m) ; y++)
			for (x=0 ; x< (16>>m) ; x++)
			{
				if (  (y< (8>>m) ) ^ (x< (8>>m) ) )
					*dest++ = 0;
				else
					*dest++ = 0xff;
			}
	}	
}

/*
===============
R_Init
===============
*/
void R_Init (void)
{
	R_InitWarpBuffer ();
	
	R_InitTurb ();
	
	Cmd_AddCommand ("timerefresh", R_TimeRefresh_f);	
	Cmd_AddCommand ("pointfile", R_ReadPointFile_f);	

	Cvar_RegisterVariable (&r_draworder);
	Cvar_RegisterVariable (&r_speeds);
	Cvar_RegisterVariable (&r_timegraph);
	Cvar_RegisterVariable (&r_graphheight);
	Cvar_RegisterVariable (&r_drawflat);
	Cvar_RegisterVariable (&r_ambient);
	Cvar_RegisterVariable (&r_clearcolor);
	Cvar_RegisterVariable (&r_waterwarp);
	Cvar_RegisterVariable (&r_fullbright);
	Cvar_RegisterVariable (&r_drawentities);
	Cvar_RegisterVariable (&r_drawviewmodel);
	Cvar_RegisterVariable (&r_aliasstats);
	Cvar_RegisterVariable (&r_dspeeds);
	Cvar_RegisterVariable (&r_reportsurfout);
	Cvar_RegisterVariable (&r_maxsurfs);
	Cvar_RegisterVariable (&r_numsurfs);
	Cvar_RegisterVariable (&r_reportedgeout);
	Cvar_RegisterVariable (&r_maxedges);
	Cvar_RegisterVariable (&r_numedges);
	Cvar_RegisterVariable (&r_aliastransbase);
	Cvar_RegisterVariable (&r_aliastransadj);

	Cvar_SetValue ("r_maxedges", (float)NUMSTACKEDGES);
	Cvar_SetValue ("r_maxsurfs", (float)NUMSTACKSURFACES);

	view_clipplanes[0].leftedge = true;
	view_clipplanes[1].rightedge = true;
	view_clipplanes[1].leftedge = view_clipplanes[2].leftedge =
			view_clipplanes[3].leftedge = false;
	view_clipplanes[0].rightedge = view_clipplanes[2].rightedge =
			view_clipplanes[3].rightedge = false;

	r_refdef.xOrigin = XCENTERING;
	r_refdef.yOrigin = YCENTERING;

	R_InitParticles ();

// TODO: collect 386-specific code in one place
#if	id386
	Sys_MakeCodeWriteable ((long)R_EdgeCodeStart,
					     (long)R_EdgeCodeEnd - (long)R_EdgeCodeStart);
#endif	// id386

	D_Init ();
}

/*
===============
R_NewMap
===============
*/
void R_NewMap (void)
{
	int		i;
	
// clear out efrags in case the level hasn't been reloaded
// FIXME: is this one short?
	for (i=0 ; i<cl.worldmodel->numleafs ; i++)
		cl.worldmodel->leafs[i].efrags = NULL;
		 	
	r_viewleaf = NULL;
	R_ClearParticles ();

	r_cnumsurfs = r_maxsurfs.value;

	if (r_cnumsurfs <= MINSURFACES)
		r_cnumsurfs = MINSURFACES;

	if (r_cnumsurfs > NUMSTACKSURFACES)
	{
		surfaces = Hunk_AllocName (r_cnumsurfs * sizeof(surf_t), "surfaces");
		surface_p = surfaces;
		surf_max = &surfaces[r_cnumsurfs];
		r_surfsonstack = false;
	// surface 0 doesn't really exist; it's just a dummy because index 0
	// is used to indicate no edge attached to surface
		surfaces--;
		R_SurfacePatch ();
	}
	else
	{
		r_surfsonstack = true;
	}

	r_maxedgesseen = 0;
	r_maxsurfsseen = 0;

	r_numallocatededges = r_maxedges.value;

	if (r_numallocatededges < MINEDGES)
		r_numallocatededges = MINEDGES;

	if (r_numallocatededges <= NUMSTACKEDGES)
	{
		auxedges = NULL;
	}
	else
	{
		auxedges = Hunk_AllocName (r_numallocatededges * sizeof(edge_t),
								   "edges");
	}

	r_dowarpold = false;
	r_viewchanged = false;
#ifdef PASSAGES
CreatePassages ();
#endif
}


/*
===============
R_SetVrect
===============
*/
void R_SetVrect (vrect_t *pvrectin, vrect_t *pvrect, int lineadj)
{
	int		h;
	float	size;

	size = scr_viewsize.value > 100 ? 100 : scr_viewsize.value;
	if (cl.intermission)
	{
		size = 100;
		lineadj = 0;
	}
	size /= 100;

	h = pvrectin->height - lineadj;
	pvrect->width = pvrectin->width * size;
	if (pvrect->width < 96)
	{
		size = 96.0 / pvrectin->width;
		pvrect->width = 96;	// min for icons
	}
	pvrect->width &= ~7;
	pvrect->height = pvrectin->height * size;
	if (pvrect->height > pvrectin->height - lineadj)
		pvrect->height = pvrectin->height - lineadj;

	pvrect->height &= ~1;

	pvrect->x = (pvrectin->width - pvrect->width)/2;
	pvrect->y = (h - pvrect->height)/2;

	{
		if (lcd_x.value)
		{
			pvrect->y >>= 1;
			pvrect->height >>= 1;
		}
	}
}


/*
===============
R_ViewChanged

Called every time the vid structure or r_refdef changes.
Guaranteed to be called before the first refresh
===============
*/
void R_ViewChanged (vrect_t *pvrect, int lineadj, float aspect)
{
	int		i;
	float	res_scale;

	r_viewchanged = true;

	R_SetVrect (pvrect, &r_refdef.vrect, lineadj);

	r_refdef.horizontalFieldOfView = 2.0 * tan (r_refdef.fov_x/360*M_PI);
	r_refdef.fvrectx = (float)r_refdef.vrect.x;
	r_refdef.fvrectx_adj = (float)r_refdef.vrect.x - 0.5;
	r_refdef.vrect_x_adj_shift20 = (r_refdef.vrect.x<<20) + (1<<19) - 1;
	r_refdef.fvrecty = (float)r_refdef.vrect.y;
	r_refdef.fvrecty_adj = (float)r_refdef.vrect.y - 0.5;
	r_refdef.vrectright = r_refdef.vrect.x + r_refdef.vrect.width;
	r_refdef.vrectright_adj_shift20 = (r_refdef.vrectright<<20) + (1<<19) - 1;
	r_refdef.fvrectright = (float)r_refdef.vrectright;
	r_refdef.fvrectright_adj = (float)r_refdef.vrectright - 0.5;
	r_refdef.vrectrightedge = (float)r_refdef.vrectright - 0.99;
	r_refdef.vrectbottom = r_refdef.vrect.y + r_refdef.vrect.height;
	r_refdef.fvrectbottom = (float)r_refdef.vrectbottom;
	r_refdef.fvrectbottom_adj = (float)r_refdef.vrectbottom - 0.5;

	r_refdef.aliasvrect.x = (int)(r_refdef.vrect.x * r_aliasuvscale);
	r_refdef.aliasvrect.y = (int)(r_refdef.vrect.y * r_aliasuvscale);
	r_refdef.aliasvrect.width = (int)(r_refdef.vrect.width * r_aliasuvscale);
	r_refdef.aliasvrect.height = (int)(r_refdef.vrect.height * r_aliasuvscale);
	r_refdef.aliasvrectright = r_refdef.aliasvrect.x +
			r_refdef.aliasvrect.width;
	r_refdef.aliasvrectbottom = r_refdef.aliasvrect.y +
			r_refdef.aliasvrect.height;

	pixelAspect = aspect;
	xOrigin = r_refdef.xOrigin;
	yOrigin = r_refdef.yOrigin;
	
	screenAspect = r_refdef.vrect.width*pixelAspect /
			r_refdef.vrect.height;
// 320*200 1.0 pixelAspect = 1.6 screenAspect
// 320*240 1.0 pixelAspect = 1.3333 screenAspect
// proper 320*200 pixelAspect = 0.8333333

	verticalFieldOfView = r_refdef.horizontalFieldOfView / screenAspect;

// values for perspective projection
// if math were exact, the values would range from 0.5 to to range+0.5
// hopefully they wll be in the 0.000001 to range+.999999 and truncate
// the polygon rasterization will never render in the first row or column
// but will definately render in the [range] row and column, so adjust the
// buffer origin to get an exact edge to edge fill
	xcenter = ((float)r_refdef.vrect.width * XCENTERING) +
			r_refdef.vrect.x - 0.5;
	aliasxcenter = xcenter * r_aliasuvscale;
	ycenter = ((float)r_refdef.vrect.height * YCENTERING) +
			r_refdef.vrect.y - 0.5;
	aliasycenter = ycenter * r_aliasuvscale;

	xscale = r_refdef.vrect.width / r_refdef.horizontalFieldOfView;
	aliasxscale = xscale * r_aliasuvscale;
	xscaleinv = 1.0 / xscale;
	yscale = xscale * pixelAspect;
	aliasyscale = yscale * r_aliasuvscale;
	yscaleinv = 1.0 / yscale;
	xscaleshrink = (r_refdef.vrect.width-6)/r_refdef.horizontalFieldOfView;
	yscaleshrink = xscaleshrink*pixelAspect;

// left side clip
	screenedge[0].normal[0] = -1.0 / (xOrigin*r_refdef.horizontalFieldOfView);
	screenedge[0].normal[1] = 0;
	screenedge[0].normal[2] = 1;
	screenedge[0].type = PLANE_ANYZ;
	
// right side clip
	screenedge[1].normal[0] =
			1.0 / ((1.0-xOrigin)*r_refdef.horizontalFieldOfView);
	screenedge[1].normal[1] = 0;
	screenedge[1].normal[2] = 1;
	screenedge[1].type = PLANE_ANYZ;
	
// top side clip
	screenedge[2].normal[0] = 0;
	screenedge[2].normal[1] = -1.0 / (yOrigin*verticalFieldOfView);
	screenedge[2].normal[2] = 1;
	screenedge[2].type = PLANE_ANYZ;
	
// bottom side clip
	screenedge[3].normal[0] = 0;
	screenedge[3].normal[1] = 1.0 / ((1.0-yOrigin)*verticalFieldOfView);
	screenedge[3].normal[2] = 1;	
	screenedge[3].type = PLANE_ANYZ;
	
	for (i=0 ; i<4 ; i++)
		VectorNormalize (screenedge[i].normal);

	res_scale = sqrt ((double)(r_refdef.vrect.width * r_refdef.vrect.height) /
			          (320.0 * 152.0)) *
			(2.0 / r_refdef.horizontalFieldOfView);
	r_aliastransition = r_aliastransbase.value * res_scale;
	r_resfudge = r_aliastransadj.value * res_scale;

	if (scr_fov.value <= 90.0)
		r_fov_greater_than_90 = false;
	else
		r_fov_greater_than_90 = true;

// TODO: collect 386-specific code in one place
#if	id386
	if (r_pixbytes == 1)
	{
		Sys_MakeCodeWriteable ((long)R_Surf8Start,
						     (long)R_Surf8End - (long)R_Surf8Start);
		colormap = vid.colormap;
		R_Surf8Patch ();
	}
	else
	{
		Sys_MakeCodeWriteable ((long)R_Surf16Start,
						     (long)R_Surf16End - (long)R_Surf16Start);
		colormap = vid.colormap16;
		R_Surf16Patch ();
	}
#endif	// id386

	D_ViewChanged ();
}


/*
===============
R_MarkLeaves
===============
*/
void R_MarkLeaves (void)
{
	byte	*vis;
	mnode_t	*node;
	int		i;

	if (r_oldviewleaf == r_viewleaf)
		return;
	
	r_visframecount++;
	r_oldviewleaf = r_viewleaf;

	vis = Mod_LeafPVS (r_viewleaf, cl.worldmodel);
		
	for (i=0 ; i<cl.worldmodel->numleafs ; i++)
	{
		if (vis[i>>3] & (1<<(i&7)))
		{
			node = (mnode_t *)&cl.worldmodel->leafs[i+1];
			do
			{
				if (node->visframe == r_visframecount)
					break;
				node->visframe = r_visframecount;
				node = node->parent;
			} while (node);
		}
	}
}


/*
=============
R_DrawEntitiesOnList
=============
*/
void R_DrawEntitiesOnList (void)
{
	int			i, j;
	int			lnum;
	alight_t	lighting;
// FIXME: remove and do real lighting
	float		lightvec[3] = {-1, 0, 0};
	vec3_t		dist;
	float		add;

	if (!r_drawentities.value)
		return;

	for (i=0 ; i<cl_numvisedicts ; i++)
	{
		currententity = cl_visedicts[i];

		if (currententity == &cl_entities[cl.viewentity])
			continue;	// don't draw the player

		switch (currententity->model->type)
		{
		case mod_sprite:
			VectorCopy (currententity->origin, r_entorigin);
			VectorSubtract (r_origin, r_entorigin, modelorg);
			BENCH486_PROFILE_ENTER (BENCH486_PROFILE_SPRITES);
			R_DrawSprite ();
			BENCH486_PROFILE_LEAVE ();
			break;

		case mod_alias:
			VectorCopy (currententity->origin, r_entorigin);
			VectorSubtract (r_origin, r_entorigin, modelorg);

		// see if the bounding box lets us trivially reject, also sets
		// trivial accept status
			if (R_AliasCheckBBox ())
			{
				j = R_LightPoint (currententity->origin);
	
				lighting.ambientlight = j;
				lighting.shadelight = j;

				lighting.plightvec = lightvec;

				for (lnum=0 ; lnum<MAX_DLIGHTS ; lnum++)
				{
					if (cl_dlights[lnum].die >= cl.time)
					{
						VectorSubtract (currententity->origin,
										cl_dlights[lnum].origin,
										dist);
						add = cl_dlights[lnum].radius - Length(dist);
	
						if (add > 0)
							lighting.ambientlight += add;
					}
				}
	
			// clamp lighting so it doesn't overbright as much
				if (lighting.ambientlight > 128)
					lighting.ambientlight = 128;
				if (lighting.ambientlight + lighting.shadelight > 192)
					lighting.shadelight = 192 - lighting.ambientlight;

				R_AliasDrawModel (&lighting);
			}

			break;

		default:
			break;
		}
	}
}

/*
=============
R_DrawViewModel
=============
*/
void R_DrawViewModel (void)
{
// FIXME: remove and do real lighting
	float		lightvec[3] = {-1, 0, 0};
	int			j;
	int			lnum;
	vec3_t		dist;
	float		add;
	dlight_t	*dl;
	
	if (!r_drawviewmodel.value || r_fov_greater_than_90)
		return;

	if (cl.items & IT_INVISIBILITY)
		return;

	if (cl.stats[STAT_HEALTH] <= 0)
		return;

	currententity = &cl.viewent;
	if (!currententity->model)
		return;

	VectorCopy (currententity->origin, r_entorigin);
	VectorSubtract (r_origin, r_entorigin, modelorg);

	VectorCopy (vup, viewlightvec);
	VectorInverse (viewlightvec);

	j = R_LightPoint (currententity->origin);

	if (j < 24)
		j = 24;		// allways give some light on gun
	r_viewlighting.ambientlight = j;
	r_viewlighting.shadelight = j;

// add dynamic lights		
	for (lnum=0 ; lnum<MAX_DLIGHTS ; lnum++)
	{
		dl = &cl_dlights[lnum];
		if (!dl->radius)
			continue;
		if (!dl->radius)
			continue;
		if (dl->die < cl.time)
			continue;

		VectorSubtract (currententity->origin, dl->origin, dist);
		add = dl->radius - Length(dist);
		if (add > 0)
			r_viewlighting.ambientlight += add;
	}

// clamp lighting so it doesn't overbright as much
	if (r_viewlighting.ambientlight > 128)
		r_viewlighting.ambientlight = 128;
	if (r_viewlighting.ambientlight + r_viewlighting.shadelight > 192)
		r_viewlighting.shadelight = 192 - r_viewlighting.ambientlight;

	r_viewlighting.plightvec = lightvec;

#ifdef QUAKE2
	cl.light_level = r_viewlighting.ambientlight;
#endif

	R_AliasDrawModel (&r_viewlighting);
}


/*
=============
R_BmodelCheckBBox
=============
*/
int R_BmodelCheckBBox (model_t *clmodel, float *minmaxs)
{
	int			i, *pindex, clipflags;
	vec3_t		acceptpt, rejectpt;
	double		d;

	clipflags = 0;

	if (currententity->angles[0] || currententity->angles[1]
		|| currententity->angles[2])
	{
		for (i=0 ; i<4 ; i++)
		{
			d = DotProduct (currententity->origin, view_clipplanes[i].normal);
			d -= view_clipplanes[i].dist;

			if (d <= -clmodel->radius)
				return BMODEL_FULLY_CLIPPED;

			if (d <= clmodel->radius)
				clipflags |= (1<<i);
		}
	}
	else
	{
		for (i=0 ; i<4 ; i++)
		{
		// generate accept and reject points
		// FIXME: do with fast look-ups or integer tests based on the sign bit
		// of the floating point values

			pindex = pfrustum_indexes[i];

			rejectpt[0] = minmaxs[pindex[0]];
			rejectpt[1] = minmaxs[pindex[1]];
			rejectpt[2] = minmaxs[pindex[2]];
			
			d = DotProduct (rejectpt, view_clipplanes[i].normal);
			d -= view_clipplanes[i].dist;

			if (d <= 0)
				return BMODEL_FULLY_CLIPPED;

			acceptpt[0] = minmaxs[pindex[3+0]];
			acceptpt[1] = minmaxs[pindex[3+1]];
			acceptpt[2] = minmaxs[pindex[3+2]];

			d = DotProduct (acceptpt, view_clipplanes[i].normal);
			d -= view_clipplanes[i].dist;

			if (d <= 0)
				clipflags |= (1<<i);
		}
	}

	return clipflags;
}


/*
=============
R_DrawBEntitiesOnList
=============
*/
void R_DrawBEntitiesOnList (void)
{
	int			i, j, k, clipflags;
	vec3_t		oldorigin;
	model_t		*clmodel;
	float		minmaxs[6];

	if (!r_drawentities.value)
		return;

	VectorCopy (modelorg, oldorigin);
	insubmodel = true;
	r_dlightframecount = r_framecount;

	for (i=0 ; i<cl_numvisedicts ; i++)
	{
		currententity = cl_visedicts[i];

		switch (currententity->model->type)
		{
		case mod_brush:

			clmodel = currententity->model;

		// see if the bounding box lets us trivially reject, also sets
		// trivial accept status
			for (j=0 ; j<3 ; j++)
			{
				minmaxs[j] = currententity->origin[j] +
						clmodel->mins[j];
				minmaxs[3+j] = currententity->origin[j] +
						clmodel->maxs[j];
			}

			clipflags = R_BmodelCheckBBox (clmodel, minmaxs);

			if (clipflags != BMODEL_FULLY_CLIPPED)
			{
				VectorCopy (currententity->origin, r_entorigin);
				VectorSubtract (r_origin, r_entorigin, modelorg);
			// FIXME: is this needed?
				VectorCopy (modelorg, r_worldmodelorg);
		
				r_pcurrentvertbase = clmodel->vertexes;
		
			// FIXME: stop transforming twice
				R_RotateBmodel ();

			// calculate dynamic lighting for bmodel if it's not an
			// instanced model
				if (clmodel->firstmodelsurface != 0)
				{
					for (k=0 ; k<MAX_DLIGHTS ; k++)
					{
						if ((cl_dlights[k].die < cl.time) ||
							(!cl_dlights[k].radius))
						{
							continue;
						}

						R_MarkLights (&cl_dlights[k], 1<<k,
							clmodel->nodes + clmodel->hulls[0].firstclipnode);
					}
				}

			// if the driver wants polygons, deliver those. Z-buffering is on
			// at this point, so no clipping to the world tree is needed, just
			// frustum clipping
				if (r_drawpolys | r_drawculledpolys)
				{
					R_ZDrawSubmodelPolys (clmodel);
				}
				else
				{
					r_pefragtopnode = NULL;

					for (j=0 ; j<3 ; j++)
					{
						r_emins[j] = minmaxs[j];
						r_emaxs[j] = minmaxs[3+j];
					}

					R_SplitEntityOnNode2 (cl.worldmodel->nodes);

					if (r_pefragtopnode)
					{
						currententity->topnode = r_pefragtopnode;
	
						if (r_pefragtopnode->contents >= 0)
						{
						// not a leaf; has to be clipped to the world BSP
							r_clipflags = clipflags;
							R_DrawSolidClippedSubmodelPolygons (clmodel);
						}
						else
						{
						// falls entirely in one leaf, so we just put all the
						// edges in the edge list and let 1/z sorting handle
						// drawing order
							R_DrawSubmodelPolygons (clmodel, clipflags);
						}
	
						currententity->topnode = NULL;
					}
				}

			// put back world rotation and frustum clipping		
			// FIXME: R_RotateBmodel should just work off base_vxx
				VectorCopy (base_vpn, vpn);
				VectorCopy (base_vup, vup);
				VectorCopy (base_vright, vright);
				VectorCopy (base_modelorg, modelorg);
				VectorCopy (oldorigin, modelorg);
				R_TransformFrustum ();
			}

			break;

		default:
			break;
		}
	}

	insubmodel = false;
}


/*
================
R_EdgeDrawing
================
*/
#if defined(ASM486_EDGE_DRAWING)
typedef char r_edgedrawing_edge_size_must_be_32[
	(sizeof(edge_t) == 32) ? 1 : -1];
typedef char r_edgedrawing_surf_size_must_be_64[
	(sizeof(surf_t) == 64) ? 1 : -1];
typedef char r_edgedrawing_cache_size_must_be_32[
	(CACHE_SIZE == 32) ? 1 : -1];
typedef char r_edgedrawing_num_edges_must_be_2400[
	(NUMSTACKEDGES == 2400) ? 1 : -1];
typedef char r_edgedrawing_num_surfaces_must_be_800[
	(NUMSTACKSURFACES == 800) ? 1 : -1];
typedef char r_edgedrawing_cvar_value_offset_must_be_16[
	(offsetof(cvar_t, value) == 16) ? 1 : -1];
#endif

#if !defined(ASM486_EDGE_DRAWING) || defined(BENCH486)
#ifdef ASM486_EDGE_DRAWING
void R_EdgeDrawing_C (void)
#else
void R_EdgeDrawing (void)
#endif
{
	edge_t	ledges[NUMSTACKEDGES +
				((CACHE_SIZE - 1) / sizeof(edge_t)) + 1];
	surf_t	lsurfs[NUMSTACKSURFACES +
				((CACHE_SIZE - 1) / sizeof(surf_t)) + 1];
#ifdef PROFILE486
	double	bench486_world_start;
#endif
	BENCH486_PROFILE_ENTER (BENCH486_PROFILE_EDGE_DRAWING);

	if (auxedges)
	{
		r_edges = auxedges;
	}
	else
	{
		r_edges =  (edge_t *)
				(((long)&ledges[0] + CACHE_SIZE - 1) & ~(CACHE_SIZE - 1));
	}

	if (r_surfsonstack)
	{
		surfaces =  (surf_t *)
				(((long)&lsurfs[0] + CACHE_SIZE - 1) & ~(CACHE_SIZE - 1));
		surf_max = &surfaces[r_cnumsurfs];
	// surface 0 doesn't really exist; it's just a dummy because index 0
	// is used to indicate no edge attached to surface
		surfaces--;
		R_SurfacePatch ();
	}

	R_BeginEdgeFrame ();

	if (r_dspeeds.value)
	{
		rw_time1 = Sys_FloatTime ();
	}

#ifdef PROFILE486
	if (bench486_profile_frame_active)
		bench486_world_start = Sys_FloatTime ();
#endif
	R_RenderWorld ();
#ifdef PROFILE486
	if (bench486_profile_frame_active)
		bench486_world_seconds += Sys_FloatTime () - bench486_world_start;
#endif

	if (r_drawculledpolys)
		R_ScanEdges ();

// only the world can be drawn back to front with no z reads or compares, just
// z writes, so have the driver turn z compares on now
	D_TurnZOn ();

	if (r_dspeeds.value)
	{
		rw_time2 = Sys_FloatTime ();
		db_time1 = rw_time2;
	}

	BENCH486_PROFILE_ENTER (BENCH486_PROFILE_BRUSH_ENTITIES);
	R_DrawBEntitiesOnList ();
	BENCH486_PROFILE_WORK (BENCH486_PROFILE_BRUSH_ENTITIES,
			(unsigned long)cl_numvisedicts, 0);
	BENCH486_PROFILE_LEAVE ();

	if (r_dspeeds.value)
	{
		db_time2 = Sys_FloatTime ();
		se_time1 = db_time2;
	}

	if (!r_dspeeds.value)
	{
		VID_UnlockBuffer ();
		S_ExtraUpdate ();	// don't let sound get messed up if going slow
		VID_LockBuffer ();
	}
	
	if (!(r_drawpolys | r_drawculledpolys))
		R_ScanEdges ();
	BENCH486_PROFILE_LEAVE ();
}
#endif

#ifdef ASM486_EDGE_DRAWING
void R_EdgeDrawing_asm486 (void);

void R_EdgeDrawing (void)
{
	R_EdgeDrawing_asm486 ();
}

#ifdef PROFILE486
static double bench486_edgedrawing_world_start;

void R_EdgeDrawingProfileEnter_asm486 (void)
{
	BENCH486_PROFILE_ENTER (BENCH486_PROFILE_EDGE_DRAWING);
}

void R_EdgeDrawingProfileLeave_asm486 (void)
{
	BENCH486_PROFILE_LEAVE ();
}

void R_EdgeDrawingProfileWorldStart_asm486 (void)
{
	if (bench486_profile_frame_active)
		bench486_edgedrawing_world_start = Sys_FloatTime ();
}

void R_EdgeDrawingProfileWorldEnd_asm486 (void)
{
	if (bench486_profile_frame_active)
		bench486_world_seconds += Sys_FloatTime () -
			bench486_edgedrawing_world_start;
}

void R_EdgeDrawingProfileBrushEnter_asm486 (void)
{
	BENCH486_PROFILE_ENTER (BENCH486_PROFILE_BRUSH_ENTITIES);
}

void R_EdgeDrawingProfileBrushLeave_asm486 (void)
{
	BENCH486_PROFILE_WORK (BENCH486_PROFILE_BRUSH_ENTITIES,
			(unsigned long)cl_numvisedicts, 0);
	BENCH486_PROFILE_LEAVE ();
}
#endif
#endif


/*
================
R_RenderView

r_refdef must be set before the first call
================
*/
void R_RenderView_ (void)
{
#ifdef PROFILE486
	double	bench486_visibility_start;
	unsigned long profile_particle_start;
#endif
	BENCH486_PROFILE_ENTER (BENCH486_PROFILE_RENDERER);

	if (r_timegraph.value || r_speeds.value || r_dspeeds.value)
		r_time1 = Sys_FloatTime ();

	BENCH486_PROFILE_ENTER (BENCH486_PROFILE_SETUP);
	R_SetupFrame ();
	BENCH486_PROFILE_LEAVE ();

#ifdef PROFILE486
	if (bench486_profile_frame_active)
		bench486_visibility_start = Sys_FloatTime ();
#endif
	BENCH486_PROFILE_ENTER (BENCH486_PROFILE_VISIBILITY);

#ifdef PASSAGES
	SetVisibilityByPassages ();
#else
	R_MarkLeaves ();	// done here so we know if we're in water
#endif

#ifdef PROFILE486
	if (bench486_profile_frame_active)
		bench486_visibility_seconds += Sys_FloatTime () - bench486_visibility_start;
#endif
	BENCH486_PROFILE_LEAVE ();

// make FDIV fast. This reduces timing precision after we've been running for a
// while, so we don't do it globally.  This also sets chop mode, and we do it
// here so that setup stuff like the refresh area calculations match what's
// done in screen.c
	Sys_LowFPPrecision ();

	if (!cl_entities[0].model || !cl.worldmodel)
		Sys_Error ("R_RenderView: NULL worldmodel");
		
	if (!r_dspeeds.value)
	{
		VID_UnlockBuffer ();
		S_ExtraUpdate ();	// don't let sound get messed up if going slow
		VID_LockBuffer ();
	}
	
	R_EdgeDrawing ();

	if (!r_dspeeds.value)
	{
		VID_UnlockBuffer ();
		S_ExtraUpdate ();	// don't let sound get messed up if going slow
		VID_LockBuffer ();
	}
	
	if (r_dspeeds.value)
	{
		se_time2 = Sys_FloatTime ();
		de_time1 = se_time2;
	}

	BENCH486_PROFILE_ENTER (BENCH486_PROFILE_ENTITIES);
	R_DrawEntitiesOnList ();
	BENCH486_PROFILE_LEAVE ();
	BENCH486_PROFILE_WORK (BENCH486_PROFILE_ENTITIES,
			(unsigned long)cl_numvisedicts, 0);

	if (r_dspeeds.value)
	{
		de_time2 = Sys_FloatTime ();
		dv_time1 = de_time2;
	}

	BENCH486_PROFILE_ENTER (BENCH486_PROFILE_VIEWMODEL);
	R_DrawViewModel ();
	BENCH486_PROFILE_LEAVE ();
	BENCH486_PROFILE_WORK (BENCH486_PROFILE_VIEWMODEL, 1, 0);

	if (r_dspeeds.value)
	{
		dv_time2 = Sys_FloatTime ();
		dp_time1 = Sys_FloatTime ();
	}

	#ifdef PROFILE486
	profile_particle_start = bench486_particle_count;
	#endif
	BENCH486_PROFILE_ENTER (BENCH486_PROFILE_PARTICLES);
	R_DrawParticles ();
	BENCH486_PROFILE_LEAVE ();
	#ifdef PROFILE486
	BENCH486_PROFILE_WORK (BENCH486_PROFILE_PARTICLES,
			bench486_particle_count - profile_particle_start, 0);
	#endif

	if (r_dspeeds.value)
		dp_time2 = Sys_FloatTime ();

	if (r_dowarp)
	{
		BENCH486_PROFILE_ENTER (BENCH486_PROFILE_WARP);
		D_WarpScreen ();
		BENCH486_PROFILE_LEAVE ();
		BENCH486_PROFILE_WORK (BENCH486_PROFILE_WARP,
				(unsigned long)r_refdef.vrect.width *
				(unsigned long)r_refdef.vrect.height, 0);
	}

	V_SetContentsColor (r_viewleaf->contents);

	if (r_timegraph.value)
		R_TimeGraph ();

	if (r_aliasstats.value)
		R_PrintAliasStats ();
		
	if (r_speeds.value)
		R_PrintTimes ();

	if (r_dspeeds.value)
		R_PrintDSpeeds ();

	if (r_reportsurfout.value && r_outofsurfaces)
		Con_Printf ("Short %d surfaces\n", r_outofsurfaces);

	if (r_reportedgeout.value && r_outofedges)
		Con_Printf ("Short roughly %d edges\n", r_outofedges * 2 / 3);

// back to high floating-point precision
	Sys_HighFPPrecision ();
	BENCH486_PROFILE_LEAVE ();
}

void R_RenderView (void)
{
	int		dummy;

	if ( Hunk_LowMark() & 3 )
		Sys_Error ("Hunk is missaligned");

	if ( (long)(&dummy) & 3 )
		Sys_Error ("Stack is missaligned");

	if ( (long)(&r_warpbuffer) & 3 )
		Sys_Error ("Globals are missaligned");

	R_RenderViewDispatch (R_RenderView_);
}

/*
================
R_InitTurb
================
*/
void R_InitTurb (void)
{
	int		i;
	
	for (i=0 ; i<(SIN_BUFFER_SIZE) ; i++)
	{
		sintable[i] = AMP + sin(i*3.14159*2/CYCLE)*AMP;
		intsintable[i] = AMP2 + sin(i*3.14159*2/CYCLE)*AMP2;	// AMP2, not 20
	}
}


#endif /* Original frame-control C implementation or BENCH486 oracle. */
#ifdef ASM486_FRAME_CONTROL
#undef R_InitTextures
#endif
#ifdef ASM486_FRAME_CONTROL
#undef R_Init
#endif
#ifdef ASM486_FRAME_CONTROL
#undef R_NewMap
#endif
#ifdef ASM486_FRAME_CONTROL
#undef R_SetVrect
#endif
#ifdef ASM486_FRAME_CONTROL
#undef R_ViewChanged
#endif
#ifdef ASM486_FRAME_CONTROL
#undef R_MarkLeaves
#endif
#ifdef ASM486_FRAME_CONTROL
#undef R_DrawEntitiesOnList
#endif
#ifdef ASM486_FRAME_CONTROL
#undef R_DrawViewModel
#endif
#ifdef ASM486_FRAME_CONTROL
#undef R_BmodelCheckBBox
#endif
#ifdef ASM486_FRAME_CONTROL
#undef R_DrawBEntitiesOnList
#endif
#ifdef ASM486_FRAME_CONTROL
#undef R_EdgeDrawing
#endif
#ifdef ASM486_FRAME_CONTROL
#undef R_RenderView_
#endif
#ifdef ASM486_FRAME_CONTROL
#undef R_RenderView
#endif
#ifdef ASM486_FRAME_CONTROL
#undef R_InitTurb
#endif

/*
================
R_InitWarpBuffer

Keep the common warp image in renderer-owned storage.  A failed allocation is
handled at R_RenderViewDispatch, where the actual DJGPP stack bounds are
checked before a separate stack-backed render is entered.
================
*/
void R_InitWarpBuffer (void)
{
#ifdef BENCH486
	static qboolean warp_commands_registered;

	if (!warp_commands_registered)
	{
		Cmd_AddCommand ("benchwarp_allocated", R_BenchWarpAllocated_f);
		Cmd_AddCommand ("benchwarp_fallback", R_BenchWarpFallback_f);
		Cmd_AddCommand ("benchwarp_short", R_BenchWarpShort_f);
		warp_commands_registered = true;
	}
#endif

	if (r_warpbuffer_storage)
	{
		r_warpbuffer = r_warpbuffer_storage;
		return;
	}

	r_warpbuffer_storage = (byte *)malloc (R_WARP_BUFFER_BYTES);
	r_warpbuffer = r_warpbuffer_storage;
}

void R_InvalidateWarpStackCache (void)
{
	r_warp_depth_cached = false;
	r_warp_depth_valid = false;
	r_warp_depth_world = NULL;
	r_render_stack_headroom_reported = false;
	r_render_stack_failure_reported = false;
	r_warp_stack_status_reported = false;
}

#ifdef BENCH486
static void R_BenchWarpLog (const char *text, qboolean close_report)
{
	if (r_bench_warp_report_handle == -1)
	{
		r_bench_warp_report_handle = Sys_FileOpenWrite ("warp-stack.txt");
		if (r_bench_warp_report_handle == -1)
			Sys_Error ("benchwarp: could not create warp-stack.txt");
	}

	Sys_FileWrite (r_bench_warp_report_handle, (void *)text,
			Q_strlen ((char *)text));
	if (close_report)
	{
		Sys_FileClose (r_bench_warp_report_handle);
		r_bench_warp_report_handle = -1;
	}
}

static void R_BenchWarpAllocated_f (void)
{
	if (!r_warpbuffer_storage)
		Sys_Error ("benchwarp: renderer warp buffer allocation failed");
	R_BenchWarpLog ("storage=available\n", true);
	Con_Printf ("benchwarp allocated buffer: %s\n",
			r_warpbuffer_storage ? "available" : "allocation failed");
}

static void R_BenchWarpReleaseStorage (qboolean force_short_stack)
{
	if (r_warpbuffer_storage)
	{
		free (r_warpbuffer_storage);
		r_warpbuffer_storage = NULL;
	}
	r_warpbuffer = NULL;
	r_bench_warp_force_short_stack = force_short_stack;
	R_BenchWarpLog (force_short_stack ? "mode=shortstack\n" :
			"mode=fallback\n", false);
	Con_Printf ("benchwarp: allocation failure path enabled%s\n",
			force_short_stack ? "; stack capacity forced insufficient" : "");
}

static void R_BenchWarpFallback_f (void)
{
	R_BenchWarpReleaseStorage (false);
}

static void R_BenchWarpShort_f (void)
{
	R_BenchWarpReleaseStorage (true);
}
#endif

static qboolean R_WarpWorldTreeDepth (unsigned long *depth_out)
{
	model_t		*world;
	mnode_t		*node, *previous;
	unsigned long depth, maxdepth, visits, maxvisits;

	world = cl.worldmodel;
	if (!world || !world->nodes || !depth_out || world->numnodes <= 0 ||
			world->numleafs < 0)
		return false;

	if (r_warp_depth_cached && r_warp_depth_world == world &&
			r_warp_depth_numnodes == world->numnodes &&
			r_warp_depth_numleafs == world->numleafs)
	{
		if (!r_warp_depth_valid)
			return false;
		*depth_out = r_warp_depth_value;
		return true;
	}

	r_warp_depth_cached = true;
	r_warp_depth_valid = false;
	r_warp_depth_world = world;
	r_warp_depth_numnodes = world->numnodes;
	r_warp_depth_numleafs = world->numleafs;
	maxvisits = (unsigned long)world->numnodes;
	if (!maxvisits)
		return false;

	/* Walk internal nodes without recursion or scratch storage. BSP leaf zero
	 * can be shared by many branches, so its parent link is not a tree edge and
	 * must not be followed. Count one terminal leaf below the deepest node. */
	node = world->nodes;
	previous = node->parent;
	depth = maxdepth = visits = 0;
	while (node)
	{
		if (previous == node->parent)
		{
			if (++visits > maxvisits)
				return false;
			if (node->contents < 0)
				return false;
			depth++;
			if (depth + 1 > maxdepth)
				maxdepth = depth + 1;
			if (node->children[0]->contents >= 0)
			{
				previous = node;
				node = node->children[0];
				continue;
			}
			if (node->children[1]->contents >= 0)
			{
				previous = node->children[0];
				continue;
			}
		}
		else if (previous == node->children[0] &&
				node->children[1]->contents >= 0)
		{
			previous = node;
			node = node->children[1];
			continue;
		}

		previous = node;
		node = node->parent;
		if (!depth)
			return false;
		depth--;
	}

	if (!maxdepth)
		return false;
	r_warp_depth_value = maxdepth;
	r_warp_depth_valid = true;
	*depth_out = maxdepth;
	return true;
}

static qboolean R_RenderStackRequirement (unsigned long *required_out)
{
	unsigned long world_depth, fixed_bytes;

	if (!R_WarpWorldTreeDepth (&world_depth))
		return false;

	/* The recursive world and terminal polygon paths share the world frame;
	 * charging both bounds either deepest path. The two renderer calls are
	 * view-to-edge and edge-to-world. Charge a third return address for the
	 * dispatch-to-render callback even though the common allocated-buffer path
	 * tail-jumps: the no-warp recovery path makes a normal callback call. */
	fixed_bytes = (3UL * R_WARP_CALL_BYTES) +
			R_WARP_RENDER_VIEW_FRAME_BYTES + R_RENDER_EDGE_FRAME_BYTES +
			R_RENDER_WORLD_FRAME_BYTES + R_WARP_RENDER_POLY_PATH_BYTES +
			R_WARP_WORLD_WALK_FIXED_BYTES;
	if (world_depth > (0xffffffffUL - fixed_bytes) /
			R_WARP_TREE_STEP_BYTES)
		return false;
	*required_out = fixed_bytes + world_depth * R_WARP_TREE_STEP_BYTES;
	return true;
}

static qboolean R_WarpStackRequirement (unsigned long *required_out)
{
	unsigned long normal_required;

	if (!R_RenderStackRequirement (&normal_required))
		return false;
	if (normal_required > 0xffffffffUL - R_WARP_FALLBACK_FRAME_BYTES -
			R_WARP_CALL_BYTES)
		return false;
	*required_out = normal_required + R_WARP_FALLBACK_FRAME_BYTES +
			R_WARP_CALL_BYTES;
	return true;
}

static qboolean R_RenderStackHasRoom (unsigned long required,
		unsigned long *available_out, qboolean *bounds_valid_out,
		qboolean allow_forced_short)
{
	unsigned long stack_pointer;

	/* Read the current ESP directly: a local marker can sit above the actual
	 * stack pointer and would overstate the remaining capacity. */
	__asm__ __volatile__ ("movl %%esp, %0" : "=r" (stack_pointer) : : "memory");
	*available_out = 0;
	*bounds_valid_out = false;
	if (stack_pointer < __djgpp_stack_limit ||
			stack_pointer > __djgpp_stack_top)
		return false;

	*bounds_valid_out = true;
	*available_out = stack_pointer - __djgpp_stack_limit;
#ifdef BENCH486
	r_bench_warp_actual_stack_available = *available_out;
	if (allow_forced_short && r_bench_warp_force_short_stack)
	{
		*available_out = 0;
		return false;
	}
#endif
	return *available_out >= required;
}

static void R_RenderViewStackFallback (void (*render_view) (void))
{
	byte	warpbuffer[R_WARP_BUFFER_BYTES];
	byte	*old_warpbuffer;

	old_warpbuffer = r_warpbuffer;
	r_warpbuffer = warpbuffer;
	render_view ();
	r_warpbuffer = old_warpbuffer;
}

static void R_RenderViewWithoutWarp (void (*render_view) (void))
{
	float old_waterwarp;

	old_waterwarp = r_waterwarp.value;
	r_waterwarp.value = 0;
	render_view ();
	r_waterwarp.value = old_waterwarp;
}

void R_RenderViewDispatch (void (*render_view) (void))
{
	unsigned long normal_required, warp_required, available;
	qboolean bounds_valid;

	if (!render_view)
		Sys_Error ("R_RenderView: missing renderer entry");

	if (!R_RenderStackRequirement (&normal_required))
	{
		if (!r_render_stack_failure_reported)
			Con_Printf ("R_RenderView: render skipped; BSP stack requirement is unavailable\n");
		r_render_stack_failure_reported = true;
		return;
	}

	if (!R_RenderStackHasRoom (normal_required, &available, &bounds_valid, false))
	{
		if (!r_render_stack_failure_reported)
		{
			if (bounds_valid)
				Con_Printf ("R_RenderView: render skipped; normal path requires %lu, has %lu, short %lu bytes\n",
						normal_required, available, normal_required - available);
			else
				Con_Printf ("R_RenderView: render skipped; DJGPP stack bounds are unavailable\n");
		}
		r_render_stack_failure_reported = true;
		return;
	}

	if (!r_render_stack_headroom_reported)
	{
		Con_Printf ("R_RenderView: normal path requires %lu, has %lu, headroom %lu bytes\n",
				normal_required, available, available - normal_required);
		r_render_stack_headroom_reported = true;
	}

	if (r_warpbuffer_storage)
	{
		r_warpbuffer = r_warpbuffer_storage;
		render_view ();
		return;
	}

	if (!r_waterwarp.value)
	{
		render_view ();
		return;
	}

	if (R_WarpStackRequirement (&warp_required) &&
			R_RenderStackHasRoom (warp_required, &available, &bounds_valid, true))
	{
		if (!r_warp_stack_status_reported)
		{
			Con_Printf ("R_RenderView: stack warp fallback requires %lu, "
					"has %lu, headroom %lu bytes\n", warp_required, available,
					available - warp_required);
	#ifdef BENCH486
			{
				char report[160];

				sprintf (report, "stack=usable required=%lu available=%lu "
						"headroom=%lu actual_available=%lu\n", warp_required,
						available, available - warp_required,
						r_bench_warp_actual_stack_available);
				R_BenchWarpLog (report, true);
			}
	#endif
			r_warp_stack_status_reported = true;
		}
		R_RenderViewStackFallback (render_view);
		return;
	}

	if (!r_warp_stack_status_reported)
	{
		if (!R_WarpStackRequirement (&warp_required))
		{
			Con_Printf ("R_RenderView: warp skipped; BSP stack requirement is unavailable\n");
		#ifdef BENCH486
			R_BenchWarpLog ("stack=requirement-unavailable\n", true);
		#endif
		}
		else if (bounds_valid)
		{
			Con_Printf ("R_RenderView: warp skipped; stack fallback requires %lu, has %lu, short %lu bytes\n",
					warp_required, available, warp_required - available);
		#ifdef BENCH486
			{
				char report[160];

				sprintf (report, "stack=insufficient required=%lu available=%lu "
						"short=%lu actual_available=%lu forced=%u\n", warp_required,
						available, warp_required - available,
						r_bench_warp_actual_stack_available,
						r_bench_warp_force_short_stack ? 1U : 0U);
				R_BenchWarpLog (report, true);
			}
		#endif
		}
		else
		{
			Con_Printf ("R_RenderView: warp skipped; DJGPP stack bounds are unavailable\n");
		#ifdef BENCH486
			R_BenchWarpLog ("stack=bounds-unavailable\n", true);
		#endif
		}
		r_warp_stack_status_reported = true;
	}
	R_RenderViewWithoutWarp (render_view);
}

#ifdef FRAME_CONTROL_RESTORE_EDGE_SELECTOR
#define ASM486_EDGE_DRAWING
#endif
#if defined(ASM486_FRAME_CONTROL) && defined(ASM486_EDGE_DRAWING) && defined(PROFILE486)
static double bench486_edgedrawing_world_start;

void R_EdgeDrawingProfileEnter_asm486 (void)
{
	BENCH486_PROFILE_ENTER (BENCH486_PROFILE_EDGE_DRAWING);
}

void R_EdgeDrawingProfileLeave_asm486 (void)
{
	BENCH486_PROFILE_LEAVE ();
}

void R_EdgeDrawingProfileWorldStart_asm486 (void)
{
	if (bench486_profile_frame_active)
		bench486_edgedrawing_world_start = Sys_FloatTime ();
}

void R_EdgeDrawingProfileWorldEnd_asm486 (void)
{
	if (bench486_profile_frame_active)
		bench486_world_seconds += Sys_FloatTime () -
			bench486_edgedrawing_world_start;
}

void R_EdgeDrawingProfileBrushEnter_asm486 (void)
{
	BENCH486_PROFILE_ENTER (BENCH486_PROFILE_BRUSH_ENTITIES);
}

void R_EdgeDrawingProfileBrushLeave_asm486 (void)
{
	BENCH486_PROFILE_WORK (BENCH486_PROFILE_BRUSH_ENTITIES,
			(unsigned long)cl_numvisedicts, 0);
	BENCH486_PROFILE_LEAVE ();
}
#endif
