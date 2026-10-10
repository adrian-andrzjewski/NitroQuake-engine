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
// r_edge.c

#include "quakedef.h"
#include "r_local.h"
#include "asm_worldcontrol.h"
#include <stddef.h>

#if 0
// FIXME
the complex cases add new polys on most lines, so dont optimize for keeping them the same
have multiple free span lists to try to get better coherence?
low depth complexity -- 1 to 3 or so

this breaks spans at every edge, even hidden ones (bad)

have a sentinal at both ends?
#endif


edge_t	*auxedges;
edge_t	*r_edges, *edge_p, *edge_max;

surf_t	*surfaces, *surface_p, *surf_max;

// surfaces are generated in back to front order by the bsp, so if a surf
// pointer is greater than another one, it should be drawn in front
// surfaces[1] is the background, and is used as the active surface stack

edge_t	*newedges[MAXHEIGHT];
edge_t	*removeedges[MAXHEIGHT];

espan_t	*span_p, *max_span_p;

int		r_currentkey;

extern	int	screenwidth;

int	current_iv;

int	edge_head_u_shift20, edge_tail_u_shift20;

#if defined(ASM486_SCAN_EDGES) || defined(ASM486_WORLD_CONTROL)
void (*pdrawfunc)(void);
#else
static void (*pdrawfunc)(void);
#endif

edge_t	edge_head;
edge_t	edge_tail;
edge_t	edge_aftertail;
edge_t	edge_sentinel;

float	fv;

void R_GenerateSpans (void);
void R_GenerateSpansBackward (void);

void R_LeadingEdge (edge_t *edge);
void R_LeadingEdgeBackwards (edge_t *edge);
void R_TrailingEdge (surf_t *surf, edge_t *edge);


//=============================================================================


/*
==============
R_DrawCulledPolys
==============
*/
#if !defined(ASM486_WORLD_CONTROL)
void R_DrawCulledPolys (void)
{
	surf_t			*s;
	msurface_t		*pface;

	currententity = &cl_entities[0];

	if (r_worldpolysbacktofront)
	{
		for (s=surface_p-1 ; s>&surfaces[1] ; s--)
		{
			if (!s->spans)
				continue;

			if (!(s->flags & SURF_DRAWBACKGROUND))
			{
				pface = (msurface_t *)s->data;
				R_RenderPoly (pface, 15);
			}
		}
	}
	else
	{
		for (s = &surfaces[1] ; s<surface_p ; s++)
		{
			if (!s->spans)
				continue;

			if (!(s->flags & SURF_DRAWBACKGROUND))
			{
				pface = (msurface_t *)s->data;
				R_RenderPoly (pface, 15);
			}
		}
	}
}
#endif


/*
==============
R_BeginEdgeFrame
==============
*/
#if !defined(ASM486_WORLD_CONTROL)
void R_BeginEdgeFrame (void)
{
	int		v;

	edge_p = r_edges;
	edge_max = &r_edges[r_numallocatededges];

	surface_p = &surfaces[2];	// background is surface 1,
								//  surface 0 is a dummy
	surfaces[1].spans = NULL;	// no background spans yet
	surfaces[1].flags = SURF_DRAWBACKGROUND;

// put the background behind everything in the world
	if (r_draworder.value)
	{
		pdrawfunc = R_GenerateSpansBackward;
		surfaces[1].key = 0;
		r_currentkey = 1;
	}
	else
	{
		pdrawfunc = R_GenerateSpans;
		surfaces[1].key = 0x7FFFFFFF;
		r_currentkey = 0;
	}

// FIXME: set with memset
	for (v=r_refdef.vrect.y ; v<r_refdef.vrectbottom ; v++)
	{
		newedges[v] = removeedges[v] = NULL;
	}
}
#endif


#if	!id386 || defined(BENCH486) || defined(ASM486_EDGE_LIST_C)

/*
==============
R_InsertNewEdges

Adds the edges in the linked list edgestoadd, adding them to the edges in the
linked list edgelist.  edgestoadd is assumed to be sorted on u, and non-empty (this is actually newedges[v]).  edgelist is assumed to be sorted on u, with a
sentinel at the end (actually, this is the active edge table starting at
edge_head.next).
==============
*/
#if !defined(ASM486_EDGE_LIST) || defined(BENCH486) || defined(ASM486_EDGE_LIST_C)
#if defined(ASM486_EDGE_LIST) || (defined(BENCH486) && !defined(ASM486_EDGE_LIST_C))
void R_InsertNewEdges_C (edge_t *edgestoadd, edge_t *edgelist)
#else
void R_InsertNewEdges (edge_t *edgestoadd, edge_t *edgelist)
#endif
{
	edge_t	*next_edge;

	do
	{
		next_edge = edgestoadd->next;
edgesearch:
		if (edgelist->u >= edgestoadd->u)
			goto addedge;
		edgelist=edgelist->next;
		if (edgelist->u >= edgestoadd->u)
			goto addedge;
		edgelist=edgelist->next;
		if (edgelist->u >= edgestoadd->u)
			goto addedge;
		edgelist=edgelist->next;
		if (edgelist->u >= edgestoadd->u)
			goto addedge;
		edgelist=edgelist->next;
		goto edgesearch;

	// insert edgestoadd before edgelist
addedge:
		edgestoadd->next = edgelist;
		edgestoadd->prev = edgelist->prev;
		edgelist->prev->next = edgestoadd;
		edgelist->prev = edgestoadd;
	} while ((edgestoadd = next_edge) != NULL);
}
#endif

#endif	// !id386 || BENCH486 || ASM486_EDGE_LIST_C

#ifdef ASM486_EDGE_LIST
void R_InsertNewEdges_asm486 (edge_t *edgestoadd, edge_t *edgelist);

#if !defined(ASM486_PUBLIC_BINDINGS) || !defined(ASM486_EDGE_LIST)
void R_InsertNewEdges (edge_t *edgestoadd, edge_t *edgelist)
{
	R_InsertNewEdges_asm486 (edgestoadd, edgelist);
}
#endif /* public entry is assembly-owned when selected */
#endif
	

#if	!id386 || defined(BENCH486) || defined(ASM486_EDGE_LIST_C)

/*
==============
R_RemoveEdges
==============
*/
#if !defined(ASM486_EDGE_LIST) || defined(BENCH486) || defined(ASM486_EDGE_LIST_C)
#if defined(ASM486_EDGE_LIST) || (defined(BENCH486) && !defined(ASM486_EDGE_LIST_C))
void R_RemoveEdges_C (edge_t *pedge)
#else
void R_RemoveEdges (edge_t *pedge)
#endif
{

	do
	{
		pedge->next->prev = pedge->prev;
		pedge->prev->next = pedge->next;
	} while ((pedge = pedge->nextremove) != NULL);
}
#endif

#endif	// !id386 || BENCH486 || ASM486_EDGE_LIST_C

#ifdef ASM486_EDGE_LIST
void R_RemoveEdges_asm486 (edge_t *pedge);

#if !defined(ASM486_PUBLIC_BINDINGS) || !defined(ASM486_EDGE_LIST)
void R_RemoveEdges (edge_t *pedge)
{
	R_RemoveEdges_asm486 (pedge);
}
#endif /* public entry is assembly-owned when selected */
#endif


#if	!id386 || defined(BENCH486) || defined(ASM486_EDGE_LIST_C)

/*
==============
R_StepActiveU
==============
*/
#if !defined(ASM486_EDGE_LIST) || defined(BENCH486) || defined(ASM486_EDGE_LIST_C)
#if defined(ASM486_EDGE_LIST) || (defined(BENCH486) && !defined(ASM486_EDGE_LIST_C))
void R_StepActiveU_C (edge_t *pedge)
#else
void R_StepActiveU (edge_t *pedge)
#endif
{
	edge_t		*pnext_edge, *pwedge;

	while (1)
	{
nextedge:
		pedge->u += pedge->u_step;
		if (pedge->u < pedge->prev->u)
			goto pushback;
		pedge = pedge->next;
			
		pedge->u += pedge->u_step;
		if (pedge->u < pedge->prev->u)
			goto pushback;
		pedge = pedge->next;
			
		pedge->u += pedge->u_step;
		if (pedge->u < pedge->prev->u)
			goto pushback;
		pedge = pedge->next;
			
		pedge->u += pedge->u_step;
		if (pedge->u < pedge->prev->u)
			goto pushback;
		pedge = pedge->next;
			
		goto nextedge;		
		
pushback:
		if (pedge == &edge_aftertail)
			return;
			
	// push it back to keep it sorted		
		pnext_edge = pedge->next;

	// pull the edge out of the edge list
		pedge->next->prev = pedge->prev;
		pedge->prev->next = pedge->next;

	// find out where the edge goes in the edge list
		pwedge = pedge->prev->prev;

		while (pwedge->u > pedge->u)
		{
			pwedge = pwedge->prev;
		}

	// put the edge back into the edge list
		pedge->next = pwedge->next;
		pedge->prev = pwedge;
		pedge->next->prev = pedge;
		pwedge->next = pedge;

		pedge = pnext_edge;
		if (pedge == &edge_tail)
			return;
	}
}
#endif

#endif	// !id386 || BENCH486 || ASM486_EDGE_LIST_C

#ifdef ASM486_EDGE_LIST
void R_StepActiveU_asm486 (edge_t *pedge);

#if !defined(ASM486_PUBLIC_BINDINGS) || !defined(ASM486_EDGE_LIST)
void R_StepActiveU (edge_t *pedge)
{
	R_StepActiveU_asm486 (pedge);
}
#endif /* public entry is assembly-owned when selected */
#endif


/*
==============
R_CleanupSpan
==============
*/
#if !defined(ASM486_BACKWARD_SPANS) || defined(BENCH486)
#ifdef ASM486_BACKWARD_SPANS
void R_CleanupSpan_C (void)
#else
void R_CleanupSpan (void)
#endif
{
	surf_t	*surf;
	int		iu;
	espan_t	*span;

// now that we've reached the right edge of the screen, we're done with any
// unfinished surfaces, so emit a span for whatever's on top
	surf = surfaces[1].next;
	iu = edge_tail_u_shift20;
	if (iu > surf->last_u)
	{
		span = span_p++;
		span->u = surf->last_u;
		span->count = iu - span->u;
		span->v = current_iv;
		span->pnext = surf->spans;
		surf->spans = span;
	}

// reset spanstate for all surfaces in the surface stack
	do
	{
		surf->spanstate = 0;
		surf = surf->next;
	} while (surf != &surfaces[1]);
}
#endif

#ifdef ASM486_BACKWARD_SPANS
void R_CleanupSpan_asm486 (void);

#if !defined(ASM486_PUBLIC_BINDINGS) || !defined(ASM486_BACKWARD_SPANS)
void R_CleanupSpan (void)
{
	R_CleanupSpan_asm486 ();
}
#endif /* public entry is assembly-owned when selected */
#endif


/*
==============
R_LeadingEdgeBackwards
==============
*/
#if !defined(ASM486_BACKWARD_SPANS) || defined(BENCH486)
#ifdef ASM486_BACKWARD_SPANS
void R_LeadingEdgeBackwards_C (edge_t *edge)
#else
void R_LeadingEdgeBackwards (edge_t *edge)
#endif
{
	espan_t			*span;
	surf_t			*surf, *surf2;
	int				iu;

// it's adding a new surface in, so find the correct place
	surf = &surfaces[edge->surfs[1]];

// don't start a span if this is an inverted span, with the end
// edge preceding the start edge (that is, we've already seen the
// end edge)
	if (++surf->spanstate == 1)
	{
		surf2 = surfaces[1].next;

		if (surf->key > surf2->key)
			goto newtop;

	// if it's two surfaces on the same plane, the one that's already
	// active is in front, so keep going unless it's a bmodel
		if (surf->insubmodel && (surf->key == surf2->key))
		{
		// must be two bmodels in the same leaf; don't care, because they'll
		// never be farthest anyway
			goto newtop;
		}

continue_search:

		do
		{
			surf2 = surf2->next;
		} while (surf->key < surf2->key);

		if (surf->key == surf2->key)
		{
		// if it's two surfaces on the same plane, the one that's already
		// active is in front, so keep going unless it's a bmodel
			if (!surf->insubmodel)
				goto continue_search;

		// must be two bmodels in the same leaf; don't care which is really
		// in front, because they'll never be farthest anyway
		}

		goto gotposition;

newtop:
	// emit a span (obscures current top)
		iu = edge->u >> 20;

		if (iu > surf2->last_u)
		{
			span = span_p++;
			span->u = surf2->last_u;
			span->count = iu - span->u;
			span->v = current_iv;
			span->pnext = surf2->spans;
			surf2->spans = span;
		}

		// set last_u on the new span
		surf->last_u = iu;
				
gotposition:
	// insert before surf2
		surf->next = surf2;
		surf->prev = surf2->prev;
		surf2->prev->next = surf;
		surf2->prev = surf;
	}
}
#endif

#ifdef ASM486_BACKWARD_SPANS
void R_LeadingEdgeBackwards_asm486 (edge_t *edge);

#if !defined(ASM486_PUBLIC_BINDINGS) || !defined(ASM486_BACKWARD_SPANS)
void R_LeadingEdgeBackwards (edge_t *edge)
{
	R_LeadingEdgeBackwards_asm486 (edge);
}
#endif /* public entry is assembly-owned when selected */
#endif


/*
==============
R_TrailingEdge
==============
*/
#if !defined(ASM486_BACKWARD_SPANS) || defined(BENCH486)
#ifdef ASM486_BACKWARD_SPANS
void R_TrailingEdge_C (surf_t *surf, edge_t *edge)
#else
void R_TrailingEdge (surf_t *surf, edge_t *edge)
#endif
{
	espan_t			*span;
	int				iu;

// don't generate a span if this is an inverted span, with the end
// edge preceding the start edge (that is, we haven't seen the
// start edge yet)
	if (--surf->spanstate == 0)
	{
		if (surf->insubmodel)
			r_bmodelactive--;

		if (surf == surfaces[1].next)
		{
		// emit a span (current top going away)
			iu = edge->u >> 20;
			if (iu > surf->last_u)
			{
				span = span_p++;
				span->u = surf->last_u;
				span->count = iu - span->u;
				span->v = current_iv;
				span->pnext = surf->spans;
				surf->spans = span;
			}

		// set last_u on the surface below
			surf->next->last_u = iu;
		}

		surf->prev->next = surf->next;
		surf->next->prev = surf->prev;
	}
}
#endif

#ifdef ASM486_BACKWARD_SPANS
void R_TrailingEdge_asm486 (surf_t *surf, edge_t *edge);

#if !defined(ASM486_PUBLIC_BINDINGS) || !defined(ASM486_BACKWARD_SPANS)
void R_TrailingEdge (surf_t *surf, edge_t *edge)
{
	R_TrailingEdge_asm486 (surf, edge);
}
#endif /* public entry is assembly-owned when selected */
#endif


#if !id386 || defined(BENCH486)

/*
==============
R_LeadingEdge
==============
*/
#ifdef BENCH486
void R_LeadingEdge_C (edge_t *edge)
#else
void R_LeadingEdge (edge_t *edge)
#endif
{
	espan_t			*span;
	surf_t			*surf, *surf2;
	int				iu;
	double			fu, newzi, testzi, newzitop, newzibottom;

	if (edge->surfs[1])
	{
	// it's adding a new surface in, so find the correct place
		surf = &surfaces[edge->surfs[1]];

	// don't start a span if this is an inverted span, with the end
	// edge preceding the start edge (that is, we've already seen the
	// end edge)
		if (++surf->spanstate == 1)
		{
			if (surf->insubmodel)
				r_bmodelactive++;

			surf2 = surfaces[1].next;

			if (surf->key < surf2->key)
				goto newtop;

		// if it's two surfaces on the same plane, the one that's already
		// active is in front, so keep going unless it's a bmodel
			if (surf->insubmodel && (surf->key == surf2->key))
			{
			// must be two bmodels in the same leaf; sort on 1/z
				fu = (float)(edge->u - 0xFFFFF) * (1.0 / 0x100000);
				newzi = surf->d_ziorigin + fv*surf->d_zistepv +
						fu*surf->d_zistepu;
				newzibottom = newzi * 0.99;

				testzi = surf2->d_ziorigin + fv*surf2->d_zistepv +
						fu*surf2->d_zistepu;

				if (newzibottom >= testzi)
				{
					goto newtop;
				}

				newzitop = newzi * 1.01;
				if (newzitop >= testzi)
				{
					if (surf->d_zistepu >= surf2->d_zistepu)
					{
						goto newtop;
					}
				}
			}

continue_search:

			do
			{
				surf2 = surf2->next;
			} while (surf->key > surf2->key);

			if (surf->key == surf2->key)
			{
			// if it's two surfaces on the same plane, the one that's already
			// active is in front, so keep going unless it's a bmodel
				if (!surf->insubmodel)
					goto continue_search;

			// must be two bmodels in the same leaf; sort on 1/z
				fu = (float)(edge->u - 0xFFFFF) * (1.0 / 0x100000);
				newzi = surf->d_ziorigin + fv*surf->d_zistepv +
						fu*surf->d_zistepu;
				newzibottom = newzi * 0.99;

				testzi = surf2->d_ziorigin + fv*surf2->d_zistepv +
						fu*surf2->d_zistepu;

				if (newzibottom >= testzi)
				{
					goto gotposition;
				}

				newzitop = newzi * 1.01;
				if (newzitop >= testzi)
				{
					if (surf->d_zistepu >= surf2->d_zistepu)
					{
						goto gotposition;
					}
				}

				goto continue_search;
			}

			goto gotposition;

newtop:
		// emit a span (obscures current top)
			iu = edge->u >> 20;

			if (iu > surf2->last_u)
			{
				span = span_p++;
				span->u = surf2->last_u;
				span->count = iu - span->u;
				span->v = current_iv;
				span->pnext = surf2->spans;
				surf2->spans = span;
			}

			// set last_u on the new span
			surf->last_u = iu;
				
gotposition:
		// insert before surf2
			surf->next = surf2;
			surf->prev = surf2->prev;
			surf2->prev->next = surf;
			surf2->prev = surf;
		}
	}
}


/*
==============
R_GenerateSpans
==============
*/
#ifdef BENCH486
void R_GenerateSpans_C (void)
#else
void R_GenerateSpans (void)
#endif
{
	edge_t			*edge;
	surf_t			*surf;

	r_bmodelactive = 0;

// clear active surfaces to just the background surface
	surfaces[1].next = surfaces[1].prev = &surfaces[1];
	surfaces[1].last_u = edge_head_u_shift20;

// generate spans
	for (edge=edge_head.next ; edge != &edge_tail; edge=edge->next)
	{			
		if (edge->surfs[0])
		{
		// it has a left surface, so a surface is going away for this span
			surf = &surfaces[edge->surfs[0]];

#if defined(BENCH486) && defined(ASM486_BACKWARD_SPANS)
			R_TrailingEdge_C (surf, edge);
#else
			R_TrailingEdge (surf, edge);
#endif

			if (!edge->surfs[1])
				continue;
		}

#ifdef BENCH486
		R_LeadingEdge_C (edge);
#else
		R_LeadingEdge (edge);
#endif
	}

#if defined(BENCH486) && defined(ASM486_BACKWARD_SPANS)
	R_CleanupSpan_C ();
#else
	R_CleanupSpan ();
#endif
}

#endif	// !id386 || BENCH486


/*
==============
R_GenerateSpansBackward
==============
*/
#if !defined(ASM486_BACKWARD_SPANS) || defined(BENCH486)
#ifdef ASM486_BACKWARD_SPANS
void R_GenerateSpansBackward_C (void)
#else
void R_GenerateSpansBackward (void)
#endif
{
	edge_t			*edge;

	r_bmodelactive = 0;

// clear active surfaces to just the background surface
	surfaces[1].next = surfaces[1].prev = &surfaces[1];
	surfaces[1].last_u = edge_head_u_shift20;

// generate spans
	for (edge=edge_head.next ; edge != &edge_tail; edge=edge->next)
	{
		if (edge->surfs[0])
		{
#ifdef ASM486_BACKWARD_SPANS
			R_TrailingEdge_C (&surfaces[edge->surfs[0]], edge);
#else
			R_TrailingEdge (&surfaces[edge->surfs[0]], edge);
#endif
		}

		if (edge->surfs[1])
		{
#ifdef ASM486_BACKWARD_SPANS
			R_LeadingEdgeBackwards_C (edge);
#else
			R_LeadingEdgeBackwards (edge);
#endif
		}
	}

#ifdef ASM486_BACKWARD_SPANS
	R_CleanupSpan_C ();
#else
	R_CleanupSpan ();
#endif
}
#endif

#ifdef ASM486_BACKWARD_SPANS
void R_GenerateSpansBackward_asm486 (void);

#if !defined(ASM486_PUBLIC_BINDINGS) || !defined(ASM486_BACKWARD_SPANS)
void R_GenerateSpansBackward (void)
{
	R_GenerateSpansBackward_asm486 ();
}
#endif /* public entry is assembly-owned when selected */
#endif


/*
==============
R_ScanEdges

Input: 
newedges[] array
	this has links to edges, which have links to surfaces

Output:
Each surface has a linked list of its visible spans
==============
*/
#if !defined(ASM486_SCAN_EDGES) || defined(BENCH486)
#ifdef ASM486_SCAN_EDGES
void R_ScanEdges_C (void)
#else
void R_ScanEdges (void)
#endif
{
	int		iv, bottom;
	byte	basespans[MAXSPANS*sizeof(espan_t)+CACHE_SIZE];
	espan_t	*basespan_p;
	surf_t	*s;
#ifdef PROFILE486
	double	bench486_edge_scan_start;
	unsigned long profile_scanline_start;
	profile_scanline_start = bench486_scanlines;

	if (bench486_profile_frame_active)
		bench486_edge_scan_start = Sys_FloatTime ();
#endif
	BENCH486_PROFILE_ENTER (BENCH486_PROFILE_EDGE_SCAN);

	basespan_p = (espan_t *)
			((long)(basespans + CACHE_SIZE - 1) & ~(CACHE_SIZE - 1));
	max_span_p = &basespan_p[MAXSPANS - r_refdef.vrect.width];

	span_p = basespan_p;

// clear active edges to just the background edges around the whole screen
// FIXME: most of this only needs to be set up once
	edge_head.u = r_refdef.vrect.x << 20;
	edge_head_u_shift20 = edge_head.u >> 20;
	edge_head.u_step = 0;
	edge_head.prev = NULL;
	edge_head.next = &edge_tail;
	edge_head.surfs[0] = 0;
	edge_head.surfs[1] = 1;
	
	edge_tail.u = (r_refdef.vrectright << 20) + 0xFFFFF;
	edge_tail_u_shift20 = edge_tail.u >> 20;
	edge_tail.u_step = 0;
	edge_tail.prev = &edge_head;
	edge_tail.next = &edge_aftertail;
	edge_tail.surfs[0] = 1;
	edge_tail.surfs[1] = 0;
	
	edge_aftertail.u = -1;		// force a move
	edge_aftertail.u_step = 0;
	edge_aftertail.next = &edge_sentinel;
	edge_aftertail.prev = &edge_tail;

// FIXME: do we need this now that we clamp x in r_draw.c?
	edge_sentinel.u = 2000 << 24;		// make sure nothing sorts past this
	edge_sentinel.prev = &edge_aftertail;

//	
// process all scan lines
//
	bottom = r_refdef.vrectbottom - 1;

	for (iv=r_refdef.vrect.y ; iv<bottom ; iv++)
	{
	#ifdef PROFILE486
		if (bench486_profile_frame_active)
			bench486_scanlines++;
	#endif
		current_iv = iv;
		fv = (float)iv;

	// mark that the head (background start) span is pre-included
		surfaces[1].spanstate = 1;

		if (newedges[iv])
		{
	#ifdef PROFILE486
			if (bench486_profile_frame_active)
				bench486_edge_insert_calls++;
	#endif
			R_InsertNewEdges (newedges[iv], edge_head.next);
		}

		(*pdrawfunc) ();

	// flush the span list if we can't be sure we have enough spans left for
	// the next scan
		if (span_p >= max_span_p)
		{
			VID_UnlockBuffer ();
			S_ExtraUpdate ();	// don't let sound get messed up if going slow
			VID_LockBuffer ();
		
			if (r_drawculledpolys)
			{
				R_DrawCulledPolys ();
			}
			else
			{
	#ifdef PROFILE486
				if (bench486_profile_frame_active)
					bench486_span_flushes++;
	#endif
				D_DrawSurfaces ();
			}

		// clear the surface span pointers
			for (s = &surfaces[1] ; s<surface_p ; s++)
				s->spans = NULL;

			span_p = basespan_p;
		}

		if (removeedges[iv])
		{
	#ifdef PROFILE486
			if (bench486_profile_frame_active)
				bench486_edge_remove_calls++;
	#endif
			R_RemoveEdges (removeedges[iv]);
		}

		if (edge_head.next != &edge_tail)
		{
	#ifdef PROFILE486
			if (bench486_profile_frame_active)
				bench486_edge_step_calls++;
	#endif
			R_StepActiveU (edge_head.next);
		}
	}

// do the last scan (no need to step or sort or remove on the last scan)

	current_iv = iv;
	fv = (float)iv;
	#ifdef PROFILE486
	if (bench486_profile_frame_active)
		bench486_scanlines++;
	#endif

// mark that the head (background start) span is pre-included
	surfaces[1].spanstate = 1;

	if (newedges[iv])
	{
	#ifdef PROFILE486
		if (bench486_profile_frame_active)
			bench486_edge_insert_calls++;
	#endif
		R_InsertNewEdges (newedges[iv], edge_head.next);
	}

	(*pdrawfunc) ();

// draw whatever's left in the span list
	if (r_drawculledpolys)
		R_DrawCulledPolys ();
	else
	{
	#ifdef PROFILE486
		if (bench486_profile_frame_active)
			bench486_span_flushes++;
	#endif
		D_DrawSurfaces ();
	}

#ifdef PROFILE486
	if (bench486_profile_frame_active)
		bench486_edge_scan_seconds += Sys_FloatTime () - bench486_edge_scan_start;
#endif
	BENCH486_PROFILE_WORK (BENCH486_PROFILE_EDGE_SCAN,
			bench486_scanlines - profile_scanline_start, 0);
	BENCH486_PROFILE_LEAVE ();
}
#endif

#ifdef ASM486_SCAN_EDGES
typedef char r_scan_edges_espan_size_must_be_16[
	(sizeof(espan_t) == 16) ? 1 : -1];
typedef char r_scan_edges_edge_size_must_be_32[
	(sizeof(edge_t) == 32) ? 1 : -1];
typedef char r_scan_edges_surf_size_must_be_64[
	(sizeof(surf_t) == 64) ? 1 : -1];
typedef char r_scan_edges_cache_size_must_be_32[
	(CACHE_SIZE == 32) ? 1 : -1];
typedef char r_scan_edges_max_spans_must_be_3000[
	(MAXSPANS == 3000) ? 1 : -1];
typedef char r_scan_edges_refdef_vrectright_offset_must_be_40[
	(offsetof(refdef_t, vrectright) == 40) ? 1 : -1];
typedef char r_scan_edges_refdef_vrectbottom_offset_must_be_44[
	(offsetof(refdef_t, vrectbottom) == 44) ? 1 : -1];
typedef char r_scan_edges_refdef_vrect_width_offset_must_be_8[
	(offsetof(refdef_t, vrect.width) == 8) ? 1 : -1];

void R_ScanEdges_asm486 (void);

#if !defined(ASM486_PUBLIC_BINDINGS) || !defined(ASM486_SCAN_EDGES)
void R_ScanEdges (void)
{
	R_ScanEdges_asm486 ();
}
#endif /* public entry is assembly-owned when selected */

#ifdef PROFILE486
void R_ScanEdgesProfileBegin_asm486 (double *start)
{
	if (bench486_profile_frame_active)
		*start = Sys_FloatTime ();
	BENCH486_PROFILE_ENTER (BENCH486_PROFILE_EDGE_SCAN);
}

void R_ScanEdgesProfileEnd_asm486 (double *start,
		unsigned long scanline_start)
{
	if (bench486_profile_frame_active)
		bench486_edge_scan_seconds += Sys_FloatTime () - *start;
	BENCH486_PROFILE_WORK (BENCH486_PROFILE_EDGE_SCAN,
			bench486_scanlines - scanline_start, 0);
	BENCH486_PROFILE_LEAVE ();
}
#endif

#endif

#ifdef ASM486_EDGE_LIST
typedef char r_edge_list_edge_size_must_be_32[
	(sizeof(edge_t) == 32) ? 1 : -1];
typedef char r_edge_list_u_offset_must_be_0[
	(offsetof(edge_t, u) == 0) ? 1 : -1];
typedef char r_edge_list_u_step_offset_must_be_4[
	(offsetof(edge_t, u_step) == 4) ? 1 : -1];
typedef char r_edge_list_prev_offset_must_be_8[
	(offsetof(edge_t, prev) == 8) ? 1 : -1];
typedef char r_edge_list_next_offset_must_be_12[
	(offsetof(edge_t, next) == 12) ? 1 : -1];
typedef char r_edge_list_nextremove_offset_must_be_20[
	(offsetof(edge_t, nextremove) == 20) ? 1 : -1];
#endif

#ifdef ASM486_BACKWARD_SPANS
typedef char r_backward_span_espan_size_must_be_16[
	(sizeof(espan_t) == 16) ? 1 : -1];
typedef char r_backward_span_espan_offsets_must_match[
	(offsetof(espan_t, u) == 0 && offsetof(espan_t, v) == 4 &&
	 offsetof(espan_t, count) == 8 && offsetof(espan_t, pnext) == 12) ? 1 : -1];
typedef char r_backward_span_edge_layout_must_match[
	(sizeof(edge_t) == 32 && offsetof(edge_t, u) == 0 &&
	 offsetof(edge_t, surfs) == 16 && sizeof(((edge_t *)0)->surfs[0]) == 2) ? 1 : -1];
typedef char r_backward_span_surface_layout_must_match[
	(sizeof(surf_t) == 64 && offsetof(surf_t, next) == 0 &&
	 offsetof(surf_t, prev) == 4 && offsetof(surf_t, spans) == 8 &&
	 offsetof(surf_t, key) == 12 && offsetof(surf_t, last_u) == 16 &&
	 offsetof(surf_t, spanstate) == 20 && offsetof(surf_t, insubmodel) == 40) ? 1 : -1];
#endif

#if defined(BENCH486) && defined(ASM486_WORLD_CONTROL)
void R_DrawCulledPolys_WorldControl_C (void)
{
	surf_t			*s;
	msurface_t		*pface;

	currententity = &cl_entities[0];

	if (r_worldpolysbacktofront)
	{
		for (s=surface_p-1 ; s>&surfaces[1] ; s--)
		{
			if (!s->spans)
				continue;

			if (!(s->flags & SURF_DRAWBACKGROUND))
			{
				pface = (msurface_t *)s->data;
				Bench486WorldControlPoly (pface, 15);
			}
		}
	}
	else
	{
		for (s = &surfaces[1] ; s<surface_p ; s++)
		{
			if (!s->spans)
				continue;

			if (!(s->flags & SURF_DRAWBACKGROUND))
			{
				pface = (msurface_t *)s->data;
				Bench486WorldControlPoly (pface, 15);
			}
		}
	}
}

void R_BeginEdgeFrame_WorldControl_C (void)
{
	int		v;

	edge_p = r_edges;
	edge_max = &r_edges[r_numallocatededges];

	surface_p = &surfaces[2];	// background is surface 1,
								//  surface 0 is a dummy
	surfaces[1].spans = NULL;	// no background spans yet
	surfaces[1].flags = SURF_DRAWBACKGROUND;

// put the background behind everything in the world
	if (r_draworder.value)
	{
		pdrawfunc = R_GenerateSpansBackward;
		surfaces[1].key = 0;
		r_currentkey = 1;
	}
	else
	{
		pdrawfunc = R_GenerateSpans;
		surfaces[1].key = 0x7FFFFFFF;
		r_currentkey = 0;
	}

// FIXME: set with memset
	for (v=r_refdef.vrect.y ; v<r_refdef.vrectbottom ; v++)
	{
		newedges[v] = removeedges[v] = NULL;
	}
}
#endif
