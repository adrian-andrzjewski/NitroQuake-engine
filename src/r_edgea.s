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
//
// r_edgea.s
// x86 assembly-language edge-processing code.
//

#include "asm_i386.h"
#include "quakeasm.h"
#include "asm_draw.h"

#if	id386

#ifdef PROFILE486
	// Loop-iteration census for the edge-scan dead-scratch probes.  The
	// existing counters count CALLS (edge_insert_calls, edge_remove_calls,
	// edge_step_calls, span_flushes), which is the wrong denominator: three
	// of these routines walk a list, so one call can be many iterations and
	// a probe priced per call would be sized wrong by that factor.
	//
	// These count iterations so each probe can be sized to clear the timedemo
	// noise floor before it is built, rather than guessed.  PROFILE486-only,
	// so they cost nothing in a release build.
	.extern	C(bench486_edge_insert_iters)
	.extern	C(bench486_edge_remove_iters)
	.extern	C(bench486_edge_step_iters)
	.extern	C(bench486_edge_pushback_iters)
	.extern	C(bench486_edge_sort_iters)
	.extern	C(bench486_edge_emit_blocks)
	.extern	C(bench486_edge_genspans_edges)
	.extern	C(bench486_edge_bmodel_zsort)
	.extern	C(bench486_edge_trailing_calls)
	// Per-edge dispatch census.  The six loop counters above account for only
	// 88.8x the gate against a 204x bucket, so the remainder is per-edge
	// dispatch rather than per-iteration work.  These name which dispatch
	// path each of the 3,500,514 edges takes.  `incl` on a global touches no
	// register and no flag, so these are safe at any instruction boundary.
	.extern	C(bench486_edge_leading)
	.extern	C(bench486_edge_bmodel_leading)
	.extern	C(bench486_edge_bmodel_trailing)
	.extern	C(bench486_edge_insert_exit)
	.extern	C(bench486_edge_newtop)
	.extern	C(bench486_edge_xldone)
	.extern	C(bench486_edge_lastspan)
	.extern	C(bench486_edge_reset_iters)
#endif

	.data
Ltemp:					.long	0
float_1_div_0100000h:	.long	0x35800000	// 1.0/(float)0x100000
double_point_99:		.double	0.99
double_1_point_01:		.double	1.01

	.text

//--------------------------------------------------------------------

#define edgestoadd	4+8		// note odd stack offsets because of interleaving
#define edgelist	8+12	// with pushes

.globl C(R_EdgeCodeStart)
C(R_EdgeCodeStart):

#if !defined(ASM486_EDGE_LIST) && !defined(ASM486_EDGE_LIST_C)
.globl C(R_InsertNewEdges)
C(R_InsertNewEdges):
	pushl	%edi
	pushl	%esi				// preserve register variables
	movl	edgestoadd(%esp),%edx
	pushl	%ebx
	movl	edgelist(%esp),%ecx

LDoNextEdge:
	movl	et_u(%edx),%eax
	movl	%edx,%edi

LContinueSearch:
#ifdef PROFILE486
	incl	C(bench486_edge_insert_iters)
#endif
// Defer et_next until after et_u early-out on the first three probes
// (dead on LAddedge / LAddedge2).  Keep the fourth probe's jg fallthrough
// so long walks do not pay an extra unconditional jmp.
// Memory cmpl et_u (drop preload into %ebx); %ebx overwritten in LAddedge*.
#ifdef EDGE_SCAN_PROBE_INSERT
	// Dead-scratch probe, 4 instructions.  Duplicates loads of et_u(%ecx),
	// writing %ebx, which the real search never reads and LAddedge/
	// LAddedge2 overwrite.  Read-only, and the real compares set the flags
	// the branches use, so no store or flag-carrying instruction is
	// duplicated.
	//
	// %ecx only, never %esi.  The first version of this probe also read
	// et_u(%esi) and faulted: %esi is DEAD-but-UNINITIALISED on the first
	// pass through this loop, because it is not written until the second
	// probe's `movl et_next(%ecx),%esi'.  A dead register is not a safe
	// address; an initialised one is.
	movl	et_u(%ecx),%ebx
	cmpl	et_u(%ecx),%ebx
	movl	et_u(%ecx),%ebx
	cmpl	et_u(%ecx),%ebx
#endif
	cmpl	et_u(%ecx),%eax
	jle		LAddedge
	movl	et_next(%ecx),%esi
	cmpl	et_u(%esi),%eax
	jle		LAddedge2
	movl	et_next(%esi),%ecx
	cmpl	et_u(%ecx),%eax
	jle		LAddedge
	movl	et_next(%ecx),%esi
	movl	et_next(%esi),%ecx
	cmpl	et_u(%esi),%eax
	jg		LContinueSearch

LAddedge2:
	movl	et_next(%edx),%edx
	movl	et_prev(%esi),%ebx
	movl	%esi,et_next(%edi)
	movl	%ebx,et_prev(%edi)
	movl	%edi,et_next(%ebx)
	movl	%edi,et_prev(%esi)
	movl	%esi,%ecx

	cmpl	$0,%edx
	jnz		LDoNextEdge
	jmp		LDone

	.p2align 4,,15
LAddedge:
	movl	et_next(%edx),%edx
	movl	et_prev(%ecx),%ebx
	movl	%ecx,et_next(%edi)
	movl	%ebx,et_prev(%edi)
	movl	%edi,et_next(%ebx)
	movl	%edi,et_prev(%ecx)

	cmpl	$0,%edx
	jnz		LDoNextEdge

LDone:
	popl	%ebx				// restore register variables
	popl	%esi
	popl	%edi

	ret
#endif /* legacy edge-list implementation */

//--------------------------------------------------------------------

#if !defined(ASM486_EDGE_LIST) && !defined(ASM486_EDGE_LIST_C)
.globl C(R_RemoveEdges)
C(R_RemoveEdges):
	movl	4(%esp),%eax

Lre_loop:
#ifdef PROFILE486
	incl	C(bench486_edge_remove_iters)
#endif
// Match C: both unlink stores, then advance.  Odd-length tails no longer
// take a special Lre_done path just to finish prev->next.
	movl	et_prev(%eax),%edx
	movl	et_next(%eax),%ecx
	movl	%ecx,et_next(%edx)
	movl	%edx,et_prev(%ecx)
	movl	et_nextremove(%eax),%eax
	testl	%eax,%eax
	jz		Lre_done

	movl	et_prev(%eax),%edx
	movl	et_next(%eax),%ecx
	movl	%ecx,et_next(%edx)
	movl	%edx,et_prev(%ecx)
	movl	et_nextremove(%eax),%eax
	testl	%eax,%eax
	jnz		Lre_loop

Lre_done:
	ret
#endif /* legacy edge-list implementation */

//--------------------------------------------------------------------

#define pedgelist	4+4		// note odd stack offset because of interleaving
							// with pushes

#if !defined(ASM486_EDGE_LIST) && !defined(ASM486_EDGE_LIST_C)
.globl C(R_StepActiveU)
C(R_StepActiveU):
	pushl	%edi
	movl	pedgelist(%esp),%edx
	pushl	%esi				// preserve register variables
	pushl	%ebx

	movl	et_prev(%edx),%esi

LNewEdge:
	movl	et_u(%esi),%edi

LNextEdge:
#ifdef PROFILE486
	incl	C(bench486_edge_step_iters)
#endif
#ifdef EDGE_SCAN_PROBE_STEP
	// Dead-scratch probe, 8 instructions.  Duplicates probe 1's load and
	// step, DROPPING the store: duplicating `movl %eax,et_u(%edx)' would
	// advance et_u a second time and the run would diverge, which is the
	// whole reason a probe on mutating list code copies compute and never
	// stores.  %ecx and %ebx are dead on entry and rewritten below.
	movl	et_u(%edx),%ecx
	addl	et_u_step(%edx),%ecx
	movl	et_u(%edx),%ebx
	addl	et_u_step(%edx),%ebx
	movl	et_u(%edx),%ecx
	addl	et_u_step(%edx),%ecx
	movl	et_u(%edx),%ebx
	addl	et_u_step(%edx),%ebx
#endif
// Defer et_next past order early-out on probes 1–3 (dead on pushback /
// aftertail).  Probe 4 keeps the preload so jnl LNextEdge needs no jmp.
// Memory addl et_u_step (drop preload into %ebx).
	movl	et_u(%edx),%eax
	addl	et_u_step(%edx),%eax
	movl	%eax,et_u(%edx)
	cmpl	%edi,%eax
	jl		LPushBack
	movl	et_next(%edx),%esi

	movl	et_u(%esi),%edi
	addl	et_u_step(%esi),%edi
	cmpl	%eax,%edi
	movl	%edi,et_u(%esi)
	jl		LPushBack2
	movl	et_next(%esi),%edx

	movl	et_u(%edx),%eax
	addl	et_u_step(%edx),%eax
	movl	%eax,et_u(%edx)
	cmpl	%edi,%eax
	jl		LPushBack
	movl	et_next(%edx),%esi

	movl	et_next(%esi),%edx
	movl	et_u(%esi),%edi
	addl	et_u_step(%esi),%edi
	movl	%edi,et_u(%esi)
	cmpl	%eax,%edi
	jnl		LNextEdge

LPushBack2:
// Edge to push is in %esi; u in %edi.  Load et_next only in LPushBack
// after the aftertail early-out (matches C).
	movl	%edi,%eax
	movl	%esi,%edx

LPushBack:
// done if the -1 in edge_aftertail triggered this
	cmpl	$(C(edge_aftertail)),%edx
	jz		LUDone

// push it back to keep it sorted
	movl	et_next(%edx),%esi
	movl	et_prev(%edx),%ecx

// pull the edge out of the edge list
	movl	et_prev(%ecx),%edi
	movl	%ecx,et_prev(%esi)
	movl	%esi,et_next(%ecx)

// find out where the edge goes in the edge list
LPushBackLoop:
#ifdef PROFILE486
	incl	C(bench486_edge_pushback_iters)
#endif
// Defer et_prev until after et_u early-out (dead on LPushBackFound).
// Memory cmpl et_u (drop preload into %ebx); %ebx overwritten in LPushBackFound.
	cmpl	et_u(%edi),%eax
	jnl		LPushBackFound
	movl	et_prev(%edi),%ecx

	movl	et_prev(%ecx),%edi
	cmpl	et_u(%ecx),%eax
	jl		LPushBackLoop

	movl	%ecx,%edi

// put the edge back into the edge list
LPushBackFound:
	movl	et_next(%edi),%ebx
	movl	%edi,et_prev(%edx)
	movl	%ebx,et_next(%edx)
	movl	%edx,et_next(%edi)
	movl	%edx,et_prev(%ebx)

	movl	%esi,%edx
	movl	et_prev(%esi),%esi

	cmpl	$(C(edge_tail)),%edx
	jnz		LNewEdge

LUDone:
	popl	%ebx				// restore register variables
	popl	%esi
	popl	%edi

	ret
#endif /* legacy edge-list implementation */

//--------------------------------------------------------------------

#define surf	4		// note this is loaded before any pushes

	.p2align 4,,15
TrailingEdge:
#ifdef PROFILE486
	// TrailingEdge is entered for every edge with a surface going away, which
	// is not the same as the number of spans it emits: the spanstate test
	// below can exit without emitting.  Separating the two is what prices the
	// per-call cost against the per-emit cost.
	incl	C(bench486_edge_trailing_calls)
#endif
#ifdef EDGE_SCAN_PROBE_TRAILING
	// Dead-scratch probe, 6 instructions.  Duplicates the two loads the
	// dispatch performs, including st_spanstate, which the real code then
	// decrements in place.  %eax/%ecx/%edx are all dead on entry to
	// TrailingEdge -- only %esi, %ebx and %ebp are live -- so the probe
	// cannot perturb the branch that follows.
	movl	st_spanstate(%esi),%eax
	movl	st_insubmodel(%esi),%ecx
	movl	st_spanstate(%esi),%eax
	movl	st_insubmodel(%esi),%ecx
	movl	st_spanstate(%esi),%edx
	movl	st_insubmodel(%esi),%eax
#endif
	// Match C's --surf->spanstate == 0 with a single memory decl (ZF).
	// Both exits need the decremented value stored; inverted path no longer
	// needs a separate store.
	decl	st_spanstate(%esi)
	jnz		LInverted

	// Compare in memory; the patched MOV below preserves these branch flags.
	cmpl	$0,st_insubmodel(%esi)
	movl	0x12345678,%edx		// surfaces[1].st_next
LPatch0:
	// World surfaces have insubmodel==0; skip the counter.  Bmodels match
	// C's r_bmodelactive-- with a single decl instead of load/sub/store.
	jz		LSkipBmodelDec
	decl	C(r_bmodelactive)
LSkipBmodelDec:
	cmpl	%esi,%edx
	jnz		LNoEmit				// surface isn't on top, just remove

// emit a span (current top going away)
#ifdef PROFILE486
	incl	C(bench486_edge_emit_blocks)
#endif
	movl	et_u(%ebx),%eax
	shrl	$20,%eax				// iu = integral pixel u
	movl	st_next(%esi),%ecx
#ifdef EDGE_SCAN_PROBE_EMIT
	// Dead-scratch probe, 7 instructions.  This block has no free register:
	// %eax holds iu, %ecx st_next and %edx the patch immediate at the same
	// time, and both `jle LNoEmit2' and the following block read them.  So
	// the probe borrows %eax across a push/pop and duplicates five loads
	// into it.  push/pop rather than a .data scratch because `mov mem,mem' is
	// not encodable on x86 -- the scratch long would need a register
	// anyway, which is the thing being borrowed here.  The push/pop pair is
	// counted in the seven, so the mix's true cost is what gets divided out.
	pushl	%eax
	movl	et_u(%ebx),%eax
	movl	st_next(%esi),%eax
	movl	st_last_u(%esi),%eax
	movl	et_u(%ebx),%eax
	movl	st_next(%esi),%eax
	popl	%eax
#endif// Memory cmpl last_u (dead preload on LNoEmit2); load into %edx only on emit.
	cmpl	st_last_u(%esi),%eax
	jle		LNoEmit2				// iu <= surf->last_u, so nothing to emit

	movl	st_last_u(%esi),%edx
	movl	%eax,st_last_u(%ecx)	// surf->next->last_u = iu;
	subl	%edx,%eax
	movl	%edx,espan_t_u(%ebp)		// span->u = surf->last_u;

	movl	%eax,espan_t_count(%ebp)	// span->count = iu - span->u;
	movl	C(current_iv),%eax
	movl	%eax,espan_t_v(%ebp)		// span->v = current_iv;
	movl	st_spans(%esi),%eax
	movl	%eax,espan_t_pnext(%ebp)	// span->pnext = surf->spans;
	movl	%ebp,st_spans(%esi)			// surf->spans = span;
	addl	$(espan_t_size),%ebp

	// %ecx still holds st_next from before the emit; unlink with it directly
	// instead of reloading into %edx (tighter than movl %ecx,%edx CSE).
	movl	st_prev(%esi),%esi
	movl	%ecx,st_next(%esi)
	movl	%esi,st_prev(%ecx)
	ret

LNoEmit2:
	movl	%eax,st_last_u(%ecx)	// surf->next->last_u = iu;
	movl	st_prev(%esi),%esi		// remove; %ecx still holds st_next
	movl	%ecx,st_next(%esi)
	movl	%esi,st_prev(%ecx)
	ret

LNoEmit:
	movl	st_next(%esi),%edx		// remove the surface from the surface
	movl	st_prev(%esi),%esi		// stack

	movl	%edx,st_next(%esi)
	movl	%esi,st_prev(%edx)
	ret

LInverted:
	ret

//--------------------------------------------------------------------

// trailing edge only
Lgs_trailing:
#ifdef PROFILE486
	incl	C(bench486_edge_bmodel_trailing)
#endif
	pushl	$Lgs_nextedge
	jmp		TrailingEdge


.globl C(R_GenerateSpans)
.globl C(R_GenerateSpans_asm486)
C(R_GenerateSpans):
C(R_GenerateSpans_asm486):
	pushl	%ebp				// preserve caller's stack frame
	pushl	%edi
	pushl	%esi				// preserve register variables
	pushl	%ebx

// clear active surfaces to just the background surface
	movl	C(surfaces),%eax
	movl	C(edge_head_u_shift20),%edx
	addl	$(st_size),%eax
// %ebp = span_p throughout
	movl	C(span_p),%ebp

	movl	$0,C(r_bmodelactive)

	movl	%eax,st_next(%eax)
	movl	%eax,st_prev(%eax)
	movl	%edx,st_last_u(%eax)
	movl	C(edge_head)+et_next,%ebx		// edge=edge_head.next

// generate spans
	cmpl	$(C(edge_tail)),%ebx		// done if empty list
	jz		Lgs_lastspan

Lgs_edgeloop:
#ifdef PROFILE486
	// Per-edge entry into R_GenerateSpans.  This is the loop that the
	// 208,581 cy/frame edge-scan bucket is mostly NOT in: the four counted
	// inner loops together account for only about 52x the gate.  This
	// counter is the denominator for the fixed per-edge setup below it.
	incl	C(bench486_edge_genspans_edges)
#endif

#ifdef EDGE_SCAN_PROBE_ENTRY
	// Dead-scratch probe, 6 instructions, duplicated the dispatch loads into
	// %edx and %ecx.  Both registers are dead on entry to this loop and the
	// real code rewrites them, so nothing here is observable.  No store is
	// duplicated -- this block only reads, which is what makes it safe to
	// run it twice.
	movl	et_surfs(%ebx),%edx
	movl	C(surfaces),%ecx
	movl	et_surfs(%ebx),%edx
	movl	C(surfaces),%ecx
	movl	et_surfs(%ebx),%edx
	movl	C(surfaces),%ecx
#endif

	movzwl	et_surfs(%ebx),%esi
	movzwl	et_surfs+2(%ebx),%edi
	movl	C(surfaces),%eax
	testl	%esi,%esi
	jz		Lgs_leading		// not a trailing edge

// it has a left surface, so a surface is going away for this span
	shll	$(SURF_T_SHIFT),%esi
	addl	%eax,%esi
	testl	%edi,%edi
	jz		Lgs_trailing

// both leading and trailing
	// EDI survives TrailingEdge; form the leading surface pointer before the
	// call so the global surfaces base does not need to be reloaded afterward.
	shll	$(SURF_T_SHIFT),%edi
	addl	%eax,%edi
	call	TrailingEdge
	jmp	Lgs_leading_body

// ---------------------------------------------------------------
// handle a leading edge
// ---------------------------------------------------------------

Lgs_leading:
	// Leading-only edges still carry an index here; convert it with the
	// surfaces base already loaded at Lgs_edgeloop.
	shll	$(SURF_T_SHIFT),%edi
	addl	%eax,%edi
Lgs_leading_body:
#ifdef PROFILE486
	incl	C(bench486_edge_leading)
#endif
#ifdef EDGE_SCAN_PROBE_LEADIN
	// Dead-scratch probe, 6 instructions, at LPatch2 rather than at
	// Lgs_leading.  The first version sat at the label and faulted the run:
	// %edi is a 16-bit surface INDEX there, not a pointer -- the two
	// instructions above are what turn it into one -- so `st_spanstate(%edi)'
	// was a wild read.  Dead register, invalid address: a third variant of
	// the same trap, after dead-but-uninitialised (%esi) and mov-mem-mem.
	movl	st_spanstate(%edi),%edx
	movl	st_insubmodel(%edi),%ecx
	movl	st_spanstate(%edi),%edx
	movl	st_insubmodel(%edi),%ecx
	movl	st_spanstate(%edi),%edx
	movl	st_insubmodel(%edi),%ecx
#endif
	movl	0x12345678,%esi		// surf2 = surfaces[1].next;
LPatch2:
	cmpl	$0,st_insubmodel(%edi)
	jnz		Lbmodel_leading

// handle a leading non-bmodel edge

// don't start a span if this is an inverted span, with the end edge preceding
// the start edge (that is, we've already seen the end edge)
	cmpl	$0,st_spanstate(%edi)
	jnz		Lxl_done


// if (surf->key < surf2->key)
//		goto newtop;
	// C's ++spanstate == 1; store 1 directly to avoid a memory increment.
	movl	$1,st_spanstate(%edi)
	movl	st_key(%edi),%eax
	cmpl	st_key(%esi),%eax
	jl		Lnewtop

// main sorting loop to search through surface stack until insertion point
// found. Always terminates because background surface is sentinel
// do
// {
// 		surf2 = surf2->next;
// } while (surf->key >= surf2->key);
Lsortloopnb:
#ifdef PROFILE486
incl	C(bench486_edge_sort_iters)
#endif
#ifdef EDGE_SCAN_PROBE_SORT
	// Dead-scratch probe, 6 instructions, duplicated into %ecx, which is
	// dead in both sort loops.  Deliberately placed BEFORE the real
	// `cmpl st_key(%esi),%eax': both the jge/jg back-edge and the jne to
	// LInsertAndExit read that compare's flags, so a probe after it would
	// clobber them.
	movl	st_next(%esi),%ecx
	cmpl	st_key(%esi),%ecx
	movl	st_next(%esi),%ecx
	cmpl	st_key(%esi),%ecx
	movl	st_next(%esi),%ecx
	cmpl	st_key(%esi),%ecx
#endif
	movl	st_next(%esi),%esi
	cmpl	st_key(%esi),%eax
	jge		Lsortloopnb

	jmp	LInsertAndExit


// handle a leading bmodel edge
	.p2align 4,,15
Lbmodel_leading:
#ifdef PROFILE486
	incl	C(bench486_edge_bmodel_leading)
#endif

// don't start a span if this is an inverted span, with the end edge preceding
// the start edge (that is, we've already seen the end edge)
	cmpl	$0,st_spanstate(%edi)
	jnz		Lxl_done

	// C's ++spanstate == 1; store 1 directly to avoid a memory increment.
	movl	$1,st_spanstate(%edi)
	// Match C's r_bmodelactive++ with a single incl (no load/store pair).
	incl	C(r_bmodelactive)

// if (surf->key < surf2->key)
//		goto newtop;
	movl	st_key(%edi),%eax
	cmpl	st_key(%esi),%eax
	jl		Lnewtop

// if ((surf->key == surf2->key) && surf->insubmodel)
// {
	jz		Lzcheck_for_newtop

// main sorting loop to search through surface stack until insertion point
// found. Always terminates because background surface is sentinel
// do
// {
// 		surf2 = surf2->next;
// } while (surf->key > surf2->key);
Lsortloop:
#ifdef PROFILE486
incl	C(bench486_edge_sort_iters)
#endif
#ifdef EDGE_SCAN_PROBE_SORT
	// Same six-instruction probe as Lsortloopnb.  Placement before the real
	// compare matters here for both readers of its flags: `jg Lsortloop'
	// and `jne LInsertAndExit'.
	movl	st_next(%esi),%ecx
	cmpl	st_key(%esi),%ecx
	movl	st_next(%esi),%ecx
	cmpl	st_key(%esi),%ecx
	movl	st_next(%esi),%ecx
	cmpl	st_key(%esi),%ecx
#endif
	movl	st_next(%esi),%esi
	cmpl	st_key(%esi),%eax
	jg	Lsortloop

	jne		LInsertAndExit

// Do 1/z sorting to see if we've arrived in the right position
	movl	et_u(%ebx),%eax
	subl	$0xFFFFF,%eax
	movl	%eax,Ltemp
	fildl	Ltemp	// the compiled C oracle keeps fu in extended x87 precision
	fmuls	float_1_div_0100000h // fu = (float)(edge->u - 0xFFFFF) *
								//      (1.0 / 0x100000);

	fld		%st(0)				// fu | fu
	fmuls	st_d_zistepu(%edi)	// fu*surf->d_zistepu | fu
	flds	C(fv)					// fv | fu*surf->d_zistepu | fu
	fmuls	st_d_zistepv(%edi)	// fv*surf->d_zistepv | fu*surf->d_zistepu | fu
	fxch	%st(1)				// fu*surf->d_zistepu | fv*surf->d_zistepv | fu
	fadds	st_d_ziorigin(%edi)	// fu*surf->d_zistepu + surf->d_ziorigin |
								//  fv*surf->d_zistepv | fu

	flds	st_d_zistepu(%esi)	// surf2->d_zistepu |
								//  fu*surf->d_zistepu + surf->d_ziorigin |
								//  fv*surf->d_zistepv | fu
	fmul	%st(3),%st(0)		// fu*surf2->d_zistepu |
								//  fu*surf->d_zistepu + surf->d_ziorigin |
								//  fv*surf->d_zistepv | fu
	fxch	%st(1)				// fu*surf->d_zistepu + surf->d_ziorigin |
								//  fu*surf2->d_zistepu |
								//  fv*surf->d_zistepv | fu
	faddp	%st(0),%st(2)		// fu*surf2->d_zistepu | newzi | fu

	flds	C(fv)					// fv | fu*surf2->d_zistepu | newzi | fu
	fmuls	st_d_zistepv(%esi)	// fv*surf2->d_zistepv |
								//  fu*surf2->d_zistepu | newzi | fu
	fld		%st(2)				// newzi | fv*surf2->d_zistepv |
								//  fu*surf2->d_zistepu | newzi | fu
	fmull	double_point_99		// newzibottom | fv*surf2->d_zistepv |
								//  fu*surf2->d_zistepu | newzi | fu

	fxch	%st(2)				// fu*surf2->d_zistepu | fv*surf2->d_zistepv |
								//  newzibottom | newzi | fu
	fadds	st_d_ziorigin(%esi)	// fu*surf2->d_zistepu + surf2->d_ziorigin |
								//  fv*surf2->d_zistepv | newzibottom | newzi |
								//  fu
	faddp	%st(0),%st(1)		// testzi | newzibottom | newzi | fu
	fxch	%st(1)				// newzibottom | testzi | newzi | fu

// if (newzibottom >= testzi)
//     goto Lgotposition;

	fcomp	%st(1)				// testzi | newzi | fu

	fxch	%st(1)				// newzi | testzi | fu
	fmull	double_1_point_01	// newzitop | testzi | fu
	fxch	%st(1)				// testzi | newzitop | fu

	fnstsw	%ax
	testb	$0x01,%ah
	jz		Lgotposition_fpop3

// if (newzitop >= testzi)
// {

	fcomp	%st(1)				// newzitop | fu
	fnstsw	%ax
	testb	$0x45,%ah
	jz		Lsortloop_fpop2

// if (surf->d_zistepu >= surf2->d_zistepu)
//     goto newtop;

	flds	st_d_zistepu(%edi)	// surf->d_zistepu | newzitop| fu
	fcomps	st_d_zistepu(%esi)	// newzitop | fu
	fnstsw	%ax
	testb	$0x01,%ah
	jz		Lgotposition_fpop2

	fstp	%st(0)				// clear the FPstack
	fstp	%st(0)
	movl	st_key(%edi),%eax
	jmp		Lsortloop


Lgotposition_fpop3:
	fstp	%st(0)
Lgotposition_fpop2:
	fstp	%st(0)
	fstp	%st(0)
	jmp		LInsertAndExit


// emit a span (obscures current top)

Lnewtop_fpop3:
	fstp	%st(0)
Lnewtop_fpop2:
	fstp	%st(0)
	fstp	%st(0)
	// Former "reload sorting key" into %eax was dead: Lnewtop overwrites %eax.

Lnewtop:
#ifdef PROFILE486
	incl	C(bench486_edge_newtop)
#endif
	movl	et_u(%ebx),%eax
	shrl	$20,%eax				// iu = integral pixel u
	movl	%eax,st_last_u(%edi)	// surf->last_u = iu;
#ifdef EDGE_SCAN_PROBE_NEWTOP
	// Dead-scratch probe, 6 instructions.  Duplicates the iu computation and
	// the last_u load into %edx/%ecx, both dead on every path into Lnewtop
	// (Lgs_leading, Lbmodel_leading and Lnewtop_fpop2 each overwrite %eax
	// here and leave %edx/%ecx as leftovers).  Read-only: the store to
	// st_last_u is NOT duplicated, per the never-duplicate-a-store rule.
	movl	et_u(%ebx),%edx
	shrl	$20,%edx
	movl	st_last_u(%edi),%ecx
	movl	et_u(%ebx),%edx
	shrl	$20,%edx
	movl	st_last_u(%edi),%ecx
#endif
// Memory cmpl last_u (dead preload on LInsertAndExit); load into %edx only on emit.
	cmpl	st_last_u(%esi),%eax
	jle		LInsertAndExit			// iu <= surf->last_u, so nothing to emit

	movl	st_last_u(%esi),%edx
	subl	%edx,%eax
	movl	%edx,espan_t_u(%ebp)		// span->u = surf->last_u;

	movl	%eax,espan_t_count(%ebp)	// span->count = iu - span->u;
	movl	C(current_iv),%eax
	movl	%eax,espan_t_v(%ebp)		// span->v = current_iv;
	movl	st_spans(%esi),%eax
	movl	%eax,espan_t_pnext(%ebp)	// span->pnext = surf->spans;
	movl	%ebp,st_spans(%esi)			// surf->spans = span;
	addl	$(espan_t_size),%ebp

LInsertAndExit:
#ifdef PROFILE486
	incl	C(bench486_edge_insert_exit)
#endif
#ifdef EDGE_SCAN_PROBE_INSERTEXIT
	// Dead-scratch probe, 6 instructions.  Duplicates the st_prev load and
	// the st_next read into %eax/%ecx.  All three of %eax/%ecx/%edx are dead
	// on entry from every path in -- Lsortloopnb's jmp leaves %eax holding
	// the sort key, Lnewtop's fall-through leaves it holding iu, and the FP
	// paths leave key -- and the real code overwrites %eax at its second
	// instruction.  This block is four stores and one load; the probe
	// duplicates only the load and a read, never a store.
	movl	st_prev(%esi),%eax
	movl	st_next(%edi),%ecx
	movl	st_prev(%esi),%eax
	movl	st_next(%edi),%ecx
	movl	st_prev(%esi),%eax
	movl	st_next(%edi),%ecx
#endif
// insert before surf2
	movl	%esi,st_next(%edi)		// surf->next = surf2;
	movl	st_prev(%esi),%eax
	movl	%eax,st_prev(%edi)		// surf->prev = surf2->prev;
	movl	%edi,st_prev(%esi)		// surf2->prev = surf;
	movl	%edi,st_next(%eax)		// surf2->prev->next = surf;

// ---------------------------------------------------------------
// leading edge done
// ---------------------------------------------------------------

// ---------------------------------------------------------------
// see if there are any more edges
// ---------------------------------------------------------------

Lgs_nextedge:
	movl	et_next(%ebx),%ebx
	cmpl	$(C(edge_tail)),%ebx
	jnz		Lgs_edgeloop

// clean up at the right edge
Lgs_lastspan:
#ifdef PROFILE486
	incl	C(bench486_edge_lastspan)
#endif

// now that we've reached the right edge of the screen, we're done with any
// unfinished surfaces, so emit a span for whatever's on top
	movl	0x12345678,%esi		// surfaces[1].st_next
LPatch3:
	movl	C(edge_tail_u_shift20),%eax
	xorl	%ecx,%ecx
	movl	st_last_u(%esi),%edx
	subl	%edx,%eax
	jle		Lgs_resetspanstate

	movl	%edx,espan_t_u(%ebp)
	movl	%eax,espan_t_count(%ebp)
	movl	C(current_iv),%eax
	movl	%eax,espan_t_v(%ebp)
	movl	st_spans(%esi),%eax
	movl	%eax,espan_t_pnext(%ebp)
	movl	%ebp,st_spans(%esi)
	addl	$(espan_t_size),%ebp

// reset spanstate for all surfaces in the surface stack
Lgs_resetspanstate:
#ifdef PROFILE486
	incl	C(bench486_edge_reset_iters)
#endif
	movl	%ecx,st_spanstate(%esi)
	movl	st_next(%esi),%esi
	cmpl	$0x12345678,%esi		// &surfaces[1]
LPatch4:
	jnz		Lgs_resetspanstate

// store the final span_p
	movl	%ebp,C(span_p)

	popl	%ebx				// restore register variables
	popl	%esi
	popl	%edi
	popl	%ebp				// restore the caller's stack frame
	ret


// ---------------------------------------------------------------
// 1/z sorting for bmodels in the same leaf
// ---------------------------------------------------------------
	.p2align 4,,15
Lxl_done:
#ifdef PROFILE486
	incl	C(bench486_edge_xldone)
#endif
	incl	st_spanstate(%edi)

	jmp		Lgs_nextedge


	.p2align 4,,15
Lzcheck_for_newtop:
#ifdef PROFILE486
	// The bmodel 1/z sort.  Roughly fifty instructions, about forty of them
	// x87, and it is the leading suspect for the part of the edge-scan
	// budget the integer loops do not account for.  Counted so that share
	// can be separated from the per-edge entry cost rather than guessed.
	incl	C(bench486_edge_bmodel_zsort)
#endif
	movl	et_u(%ebx),%eax
	subl	$0xFFFFF,%eax
	movl	%eax,Ltemp
	fildl	Ltemp	// the compiled C oracle keeps fu in extended x87 precision
	fmuls	float_1_div_0100000h // fu = (float)(edge->u - 0xFFFFF) *
								//      (1.0 / 0x100000);

	fld		%st(0)				// fu | fu
	fmuls	st_d_zistepu(%edi)	// fu*surf->d_zistepu | fu
	flds	C(fv)				// fv | fu*surf->d_zistepu | fu
	fmuls	st_d_zistepv(%edi)	// fv*surf->d_zistepv | fu*surf->d_zistepu | fu
	fxch	%st(1)				// fu*surf->d_zistepu | fv*surf->d_zistepv | fu
	fadds	st_d_ziorigin(%edi)	// fu*surf->d_zistepu + surf->d_ziorigin |
								//  fv*surf->d_zistepv | fu

	flds	st_d_zistepu(%esi)	// surf2->d_zistepu |
								//  fu*surf->d_zistepu + surf->d_ziorigin |
								//  fv*surf->d_zistepv | fu
	fmul	%st(3),%st(0)		// fu*surf2->d_zistepu |
								//  fu*surf->d_zistepu + surf->d_ziorigin |
								//  fv*surf->d_zistepv | fu
	fxch	%st(1)				// fu*surf->d_zistepu + surf->d_ziorigin |
								//  fu*surf2->d_zistepu |
								//  fv*surf->d_zistepv | fu
	faddp	%st(0),%st(2)		// fu*surf2->d_zistepu | newzi | fu

	flds	C(fv)				// fv | fu*surf2->d_zistepu | newzi | fu
	fmuls	st_d_zistepv(%esi)	// fv*surf2->d_zistepv |
								//  fu*surf2->d_zistepu | newzi | fu
	fld		%st(2)				// newzi | fv*surf2->d_zistepv |
								//  fu*surf2->d_zistepu | newzi | fu
	fmull	double_point_99		// newzibottom | fv*surf2->d_zistepv |
								//  fu*surf2->d_zistepu | newzi | fu

	fxch	%st(2)				// fu*surf2->d_zistepu | fv*surf2->d_zistepv |
								//  newzibottom | newzi | fu
	fadds	st_d_ziorigin(%esi)	// fu*surf2->d_zistepu + surf2->d_ziorigin |
								//  fv*surf2->d_zistepv | newzibottom | newzi |
								//  fu
	faddp	%st(0),%st(1)		// testzi | newzibottom | newzi | fu
	fxch	%st(1)				// newzibottom | testzi | newzi | fu

// if (newzibottom >= testzi)
//     goto newtop;

	fcomp	%st(1)				// testzi | newzi | fu

	fxch	%st(1)				// newzi | testzi | fu
	fmull	double_1_point_01	// newzitop | testzi | fu
	fxch	%st(1)				// testzi | newzitop | fu

	fnstsw	%ax
	testb	$0x01,%ah
	jz		Lnewtop_fpop3

// if (newzitop >= testzi)
// {

	fcomp	%st(1)				// newzitop | fu
	fnstsw	%ax
	testb	$0x45,%ah
	jz		Lsortloop_fpop2

// if (surf->d_zistepu >= surf2->d_zistepu)
//     goto newtop;

	flds	st_d_zistepu(%edi)	// surf->d_zistepu | newzitop | fu
	fcomps	st_d_zistepu(%esi)	// newzitop | fu
	fnstsw	%ax
	testb	$0x01,%ah
	jz		Lnewtop_fpop2

Lsortloop_fpop2:
	fstp	%st(0)				// clear the FP stack
	fstp	%st(0)
	movl	st_key(%edi),%eax
	jmp		Lsortloop


.globl C(R_EdgeCodeEnd)
C(R_EdgeCodeEnd):


//----------------------------------------------------------------------
// Surface array address code patching routine
//----------------------------------------------------------------------

	.p2align 4,,15
.globl C(R_SurfacePatch)
C(R_SurfacePatch):

	movl	C(surfaces),%eax
	addl	$(st_size),%eax
	movl	%eax,LPatch4-4

	addl	$(st_next),%eax
	movl	%eax,LPatch0-4
	movl	%eax,LPatch2-4
	movl	%eax,LPatch3-4

	ret

#endif	// id386

