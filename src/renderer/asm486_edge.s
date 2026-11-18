/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
// asm486_edge.s
// Edge lists, span generation, face clipping, and efrags.

#include "asm_i386.h"
#include "renderer/d_ifacea.h"
#include "renderer/asm_draw.h"

#ifdef ASM486_EDGE_DRAWING
	.extern C(auxedges)
	.extern C(r_edges)
	.extern C(r_surfsonstack)
	.extern C(r_cnumsurfs)
	.extern C(surfaces)
	.extern C(surf_max)
	.extern C(r_dspeeds)
	.extern C(r_drawpolys)
	.extern C(r_drawculledpolys)
	.extern C(rw_time1)
	.extern C(rw_time2)
	.extern C(db_time1)
	.extern C(db_time2)
	.extern C(se_time1)
	.extern C(R_SurfacePatch)
	.extern C(R_BeginEdgeFrame)
	.extern C(R_RenderWorld)
	.extern C(R_ScanEdges)
	.extern C(D_TurnZOn)
	.extern C(R_DrawBEntitiesOnList)
	.extern C(S_ExtraUpdate)
	.extern C(Sys_FloatTime)
#ifdef PROFILE486
	.extern C(R_EdgeDrawingProfileEnter_asm486)
	.extern C(R_EdgeDrawingProfileLeave_asm486)
	.extern C(R_EdgeDrawingProfileWorldStart_asm486)
	.extern C(R_EdgeDrawingProfileWorldEnd_asm486)
	.extern C(R_EdgeDrawingProfileBrushEnter_asm486)
	.extern C(R_EdgeDrawingProfileBrushLeave_asm486)
#endif

	.text
	.p2align 4,,15
	.globl C(R_EdgeDrawing_asm486)
C(R_EdgeDrawing_asm486):
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	/*
	 * R_EdgeDrawing's local arrays are 2401 edge_t records (32 bytes each)
	 * and 801 surf_t records (64 bytes each), with each base aligned to 32.
	 * The C layout checks in r_main.c pin these sizes and counts. 128160 bytes
	 * includes the worst-case alignment slop for both arrays.
	 */
	subl	$128160,%esp

#ifdef PROFILE486
	call	C(R_EdgeDrawingProfileEnter_asm486)
#endif

	/* r_edges uses the caller-provided buffer when one exists. */
	movl	C(auxedges),%eax
	testl	%eax,%eax
	jz	.Ledge_drawing_local_edges
	movl	%eax,C(r_edges)
	jmp	.Ledge_drawing_edges_ready
.Ledge_drawing_local_edges:
	leal	31(%esp),%esi
	andl	$-32,%esi
	movl	%esi,C(r_edges)
.Ledge_drawing_edges_ready:

	/* Preserve the original stack-surface path and dummy surface zero. */
	cmpl	$0,C(r_surfsonstack)
	je	.Ledge_drawing_surfaces_ready
	leal	31(%esp),%esi
	andl	$-32,%esi
	leal	76863(%esi),%edi	/* end of the 2401-entry edge array + align pad */
	andl	$-32,%edi
	movl	%edi,C(surfaces)
	movl	C(r_cnumsurfs),%eax
	shll	$6,%eax
	addl	%edi,%eax
	movl	%eax,C(surf_max)
	subl	$64,%edi
	movl	%edi,C(surfaces)
	call	C(R_SurfacePatch)
.Ledge_drawing_surfaces_ready:

	call	C(R_BeginEdgeFrame)

	/* C's float truth test treats signed zero as false and NaN as true. */
	call	.Ledge_drawing_dspeeds_enabled
	/* r_dspeeds cannot change during this synchronous render pass. */
	movl	%eax,%ebx
	testl	%ebx,%ebx
	jz	.Ledge_drawing_after_rw_start_time
	call	C(Sys_FloatTime)
	fstps	C(rw_time1)
.Ledge_drawing_after_rw_start_time:

#ifdef PROFILE486
	call	C(R_EdgeDrawingProfileWorldStart_asm486)
#endif
	call	C(R_RenderWorld)
#ifdef PROFILE486
	call	C(R_EdgeDrawingProfileWorldEnd_asm486)
#endif

	cmpl	$0,C(r_drawculledpolys)
	je	.Ledge_drawing_after_culled_scan
	call	C(R_ScanEdges)
.Ledge_drawing_after_culled_scan:

	/* Only the world is drawn back-to-front without Z compares. */
	call	C(D_TurnZOn)

	testl	%ebx,%ebx
	jz	.Ledge_drawing_after_entity_start_time
	call	C(Sys_FloatTime)
	fstps	C(rw_time2)
	movl	C(rw_time2),%eax
	movl	%eax,C(db_time1)
.Ledge_drawing_after_entity_start_time:

#ifdef PROFILE486
	call	C(R_EdgeDrawingProfileBrushEnter_asm486)
#endif
	call	C(R_DrawBEntitiesOnList)
#ifdef PROFILE486
	call	C(R_EdgeDrawingProfileBrushLeave_asm486)
#endif

	testl	%ebx,%ebx
	jz	.Ledge_drawing_after_entity_end_time
	call	C(Sys_FloatTime)
	fstps	C(db_time2)
	movl	C(db_time2),%eax
	movl	%eax,C(se_time1)
.Ledge_drawing_after_entity_end_time:

	testl	%ebx,%ebx
	jnz	.Ledge_drawing_after_extra_update
	call	C(S_ExtraUpdate)
.Ledge_drawing_after_extra_update:

	/* Scan once at the end unless a polygon mode already scans explicitly. */
	movl	C(r_drawpolys),%eax
	orl	C(r_drawculledpolys),%eax
	testl	%eax,%eax
	jnz	.Ledge_drawing_after_final_scan
	call	C(R_ScanEdges)
.Ledge_drawing_after_final_scan:

#ifdef PROFILE486
	call	C(R_EdgeDrawingProfileLeave_asm486)
#endif

	leal	-12(%ebp),%esp
	popl	%edi
	popl	%esi
	popl	%ebx
	popl	%ebp
	ret

.Ledge_drawing_dspeeds_enabled:
	/* Float truth is all magnitude bits set: both signed zeros are false,
	 * while every finite nonzero value and NaN is true.  Integer masking
	 * preserves those C semantics without touching x87 state. */
	movl	C(r_dspeeds)+16,%eax
	andl	$0x7fffffff,%eax
	setnz	%al
	movzbl	%al,%eax
	ret
#endif

#ifdef ASM486_SCAN_EDGES
	.extern C(newedges)
	.extern C(removeedges)
	.extern C(current_iv)
	.extern C(edge_head_u_shift20)
	.extern C(edge_tail_u_shift20)
	.extern C(pdrawfunc)
	.extern C(edge_head)
	.extern C(edge_tail)
	.extern C(edge_aftertail)
	.extern C(edge_sentinel)
	.extern C(fv)
	.extern C(max_span_p)
	.extern C(span_p)
	.extern C(surface_p)
	.extern C(surfaces)
	.extern C(r_refdef)
	.extern C(r_drawculledpolys)
	.extern C(R_InsertNewEdges)
	.extern C(R_RemoveEdges)
	.extern C(R_StepActiveU)
	.extern C(R_DrawCulledPolys)
	.extern C(D_DrawSurfaces)
	.extern C(S_ExtraUpdate)
#ifdef PROFILE486
	.extern C(bench486_profile_frame_active)
	.extern C(bench486_scanlines)
	.extern C(bench486_edge_insert_calls)
	.extern C(bench486_edge_remove_calls)
	.extern C(bench486_edge_step_calls)
	.extern C(bench486_span_flushes)
	.extern C(R_ScanEdgesProfileBegin_asm486)
	.extern C(R_ScanEdgesProfileEnd_asm486)
#endif

	.text
	.p2align 4,,15
	.globl C(R_ScanEdges_asm486)
C(R_ScanEdges_asm486):
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	/* 3000 espan_t records plus 32 bytes of alignment slack and locals. */
	subl	$48096,%esp
	leal	31(%esp),%esi
	andl	$-32,%esi

#ifdef PROFILE486
	movl	C(bench486_scanlines),%eax
	movl	%eax,-16(%ebp)
	leal	-24(%ebp),%eax
	pushl	%eax
	call	C(R_ScanEdgesProfileBegin_asm486)
	addl	$4,%esp
#endif

	/* span_p and max_span_p point into this invocation's aligned stack spans. */
	movl	%esi,C(span_p)
	movl	C(r_refdef)+rd_vrect_width,%eax
	negl	%eax
	addl	$3000,%eax
	shll	$4,%eax
	addl	%esi,%eax
	movl	%eax,C(max_span_p)
	/* Save the span base for flush resets; cache the fixed row callback in ESI. */
	movl	%esi,-28(%ebp)
	movl	C(pdrawfunc),%esi

	/* Establish the background edge pair and terminal sentinels. */
	movl	C(r_refdef)+rd_vrect_x,%eax
	shll	$20,%eax
	movl	%eax,C(edge_head)+et_u
	sarl	$20,%eax
	movl	%eax,C(edge_head_u_shift20)
	movl	$0,C(edge_head)+et_u_step
	movl	$0,C(edge_head)+et_prev
	leal	C(edge_tail),%edx
	movl	%edx,C(edge_head)+et_next
	movw	$0,C(edge_head)+et_surfs
	movw	$1,C(edge_head)+et_surfs+2

	movl	C(r_refdef)+rd_vrectright,%eax
	shll	$20,%eax
	addl	$0xfffff,%eax
	movl	%eax,C(edge_tail)+et_u
	sarl	$20,%eax
	movl	%eax,C(edge_tail_u_shift20)
	movl	$0,C(edge_tail)+et_u_step
	leal	C(edge_head),%edx
	movl	%edx,C(edge_tail)+et_prev
	leal	C(edge_aftertail),%edx
	movl	%edx,C(edge_tail)+et_next
	movw	$1,C(edge_tail)+et_surfs
	movw	$0,C(edge_tail)+et_surfs+2

	movl	$-1,C(edge_aftertail)+et_u
	movl	$0,C(edge_aftertail)+et_u_step
	leal	C(edge_sentinel),%edx
	movl	%edx,C(edge_aftertail)+et_next
	leal	C(edge_tail),%edx
	movl	%edx,C(edge_aftertail)+et_prev
	movl	$0xd0000000,C(edge_sentinel)+et_u
	leal	C(edge_aftertail),%edx
	movl	%edx,C(edge_sentinel)+et_prev

	/* The C loop scans [vrect.y, vrectbottom - 1), then draws the final row. */
	movl	C(r_refdef)+rd_vrectbottom,%eax
	decl	%eax
	movl	%eax,-32(%ebp)
	movl	C(surfaces),%edi
	movl	C(r_refdef)+rd_vrect_y,%ebx
	cmpl	-32(%ebp),%ebx
	jge	.Lscan_edges_last_row
.Lscan_edges_row:
#ifdef PROFILE486
	cmpl	$0,C(bench486_profile_frame_active)
	je	.Lscan_edges_count_row_done
	incl	C(bench486_scanlines)
.Lscan_edges_count_row_done:
#endif
	movl	%ebx,C(current_iv)
	fildl	C(current_iv)
	fstps	C(fv)
	movl	$1,st_spanstate+64(%edi)

	movl	C(newedges)(,%ebx,4),%eax
	testl	%eax,%eax
	je	.Lscan_edges_no_new_edges
#ifdef PROFILE486
	cmpl	$0,C(bench486_profile_frame_active)
	je	.Lscan_edges_insert_count_done
	incl	C(bench486_edge_insert_calls)
.Lscan_edges_insert_count_done:
#endif
	movl	C(edge_head)+et_next,%edx
	pushl	%edx
	pushl	%eax
	call	C(R_InsertNewEdges)
	addl	$8,%esp
.Lscan_edges_no_new_edges:
	call	*%esi

	/* Flush spans before the next line when the reserved span buffer is low. */
	movl	C(span_p),%eax
	cmpl	C(max_span_p),%eax
	jb	.Lscan_edges_no_flush
	call	C(S_ExtraUpdate)
	cmpl	$0,C(r_drawculledpolys)
	jne	.Lscan_edges_flush_culled
#ifdef PROFILE486
	cmpl	$0,C(bench486_profile_frame_active)
	je	.Lscan_edges_span_count_done
	incl	C(bench486_span_flushes)
.Lscan_edges_span_count_done:
#endif
	call	C(D_DrawSurfaces)
	jmp	.Lscan_edges_clear_spans
.Lscan_edges_flush_culled:
	call	C(R_DrawCulledPolys)
.Lscan_edges_clear_spans:
	leal	st_size(%edi),%eax
	movl	C(surface_p),%edx
	leal	(14*st_size)(%eax),%ecx
	cmpl	%edx,%ecx
	ja	.Lscan_edges_clear_span_tail
.Lscan_edges_clear_span_loop:
	movl	$0,st_spans(%eax)
	movl	$0,st_spans+st_size(%eax)
	movl	$0,st_spans+(2*st_size)(%eax)
	movl	$0,st_spans+(3*st_size)(%eax)
	movl	$0,st_spans+(4*st_size)(%eax)
	movl	$0,st_spans+(5*st_size)(%eax)
	movl	$0,st_spans+(6*st_size)(%eax)
	movl	$0,st_spans+(7*st_size)(%eax)
	movl	$0,st_spans+(8*st_size)(%eax)
	movl	$0,st_spans+(9*st_size)(%eax)
	movl	$0,st_spans+(10*st_size)(%eax)
	movl	$0,st_spans+(11*st_size)(%eax)
	movl	$0,st_spans+(12*st_size)(%eax)
	movl	$0,st_spans+(13*st_size)(%eax)
	addl	$(14*st_size),%eax
	leal	(14*st_size)(%eax),%ecx
	cmpl	%edx,%ecx
	jbe	.Lscan_edges_clear_span_loop
.Lscan_edges_clear_span_tail:
	leal	(8*st_size)(%eax),%ecx
	cmpl	%edx,%ecx
	ja	.Lscan_edges_clear_span_tail_four
	movl	$0,st_spans(%eax)
	movl	$0,st_spans+st_size(%eax)
	movl	$0,st_spans+(2*st_size)(%eax)
	movl	$0,st_spans+(3*st_size)(%eax)
	movl	$0,st_spans+(4*st_size)(%eax)
	movl	$0,st_spans+(5*st_size)(%eax)
	movl	$0,st_spans+(6*st_size)(%eax)
	movl	$0,st_spans+(7*st_size)(%eax)
	addl	$(8*st_size),%eax
.Lscan_edges_clear_span_tail_four:
	leal	(4*st_size)(%eax),%ecx
	cmpl	%edx,%ecx
	ja	.Lscan_edges_clear_span_tail_two
	movl	$0,st_spans(%eax)
	movl	$0,st_spans+st_size(%eax)
	movl	$0,st_spans+(2*st_size)(%eax)
	movl	$0,st_spans+(3*st_size)(%eax)
	addl	$(4*st_size),%eax
.Lscan_edges_clear_span_tail_two:
	leal	(2*st_size)(%eax),%ecx
	cmpl	%edx,%ecx
	ja	.Lscan_edges_clear_span_tail_one
	movl	$0,st_spans(%eax)
	movl	$0,st_spans+st_size(%eax)
	addl	$(2*st_size),%eax
.Lscan_edges_clear_span_tail_one:
	cmpl	%edx,%eax
	jae	.Lscan_edges_spans_cleared
	movl	$0,st_spans(%eax)
.Lscan_edges_spans_cleared:
	movl	-28(%ebp),%eax
	movl	%eax,C(span_p)
.Lscan_edges_no_flush:

	movl	C(removeedges)(,%ebx,4),%eax
	testl	%eax,%eax
	je	.Lscan_edges_no_removedges
#ifdef PROFILE486
	cmpl	$0,C(bench486_profile_frame_active)
	je	.Lscan_edges_remove_count_done
	incl	C(bench486_edge_remove_calls)
.Lscan_edges_remove_count_done:
#endif
	pushl	%eax
	call	C(R_RemoveEdges)
	addl	$4,%esp
.Lscan_edges_no_removedges:
	movl	C(edge_head)+et_next,%eax
	leal	C(edge_tail),%edx
	cmpl	%edx,%eax
	je	.Lscan_edges_no_step
#ifdef PROFILE486
	cmpl	$0,C(bench486_profile_frame_active)
	je	.Lscan_edges_step_count_done
	incl	C(bench486_edge_step_calls)
.Lscan_edges_step_count_done:
#endif
	pushl	%eax
	call	C(R_StepActiveU)
	addl	$4,%esp
.Lscan_edges_no_step:
	incl	%ebx
	cmpl	-32(%ebp),%ebx
	jl	.Lscan_edges_row

.Lscan_edges_last_row:
#ifdef PROFILE486
	cmpl	$0,C(bench486_profile_frame_active)
	je	.Lscan_edges_last_count_done
	incl	C(bench486_scanlines)
.Lscan_edges_last_count_done:
#endif
	movl	%ebx,C(current_iv)
	fildl	C(current_iv)
	fstps	C(fv)
	movl	$1,st_spanstate+64(%edi)
	movl	C(newedges)(,%ebx,4),%eax
	testl	%eax,%eax
	je	.Lscan_edges_last_no_edges
#ifdef PROFILE486
	cmpl	$0,C(bench486_profile_frame_active)
	je	.Lscan_edges_last_insert_count_done
	incl	C(bench486_edge_insert_calls)
.Lscan_edges_last_insert_count_done:
#endif
	movl	C(edge_head)+et_next,%edx
	pushl	%edx
	pushl	%eax
	call	C(R_InsertNewEdges)
	addl	$8,%esp
.Lscan_edges_last_no_edges:
	call	*%esi

	cmpl	$0,C(r_drawculledpolys)
	jne	.Lscan_edges_final_culled
#ifdef PROFILE486
	cmpl	$0,C(bench486_profile_frame_active)
	je	.Lscan_edges_final_count_done
	incl	C(bench486_span_flushes)
.Lscan_edges_final_count_done:
#endif
	call	C(D_DrawSurfaces)
	jmp	.Lscan_edges_profile_end
.Lscan_edges_final_culled:
	call	C(R_DrawCulledPolys)

.Lscan_edges_profile_end:
#ifdef PROFILE486
	pushl	-16(%ebp)
	leal	-24(%ebp),%eax
	pushl	%eax
	call	C(R_ScanEdgesProfileEnd_asm486)
	addl	$8,%esp
#endif
	leal	-12(%ebp),%esp
	popl	%edi
	popl	%esi
	popl	%ebx
	popl	%ebp
	ret
#endif

#ifdef ASM486_EDGE_LIST
	.extern C(edge_aftertail)
	.extern C(edge_tail)

	.text
	.p2align 4,,15
	.globl C(R_InsertNewEdges_asm486)
C(R_InsertNewEdges_asm486):
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	movl	16(%esp),%ebx		/* edge to insert */
	movl	20(%esp),%esi		/* sorted active-list cursor */
.Linsert_new_edges_next:
	movl	et_next(%ebx),%edi	/* preserve the source-chain successor */
	movl	et_u(%ebx),%edx	/* target U is stable until this edge is inserted */
.Linsert_new_edges_search:
	cmpl	%edx,et_u(%esi)
	jge	.Linsert_new_edges_found
	movl	et_next(%esi),%esi
	cmpl	%edx,et_u(%esi)
	jge	.Linsert_new_edges_found
	movl	et_next(%esi),%esi
	cmpl	%edx,et_u(%esi)
	jge	.Linsert_new_edges_found
	movl	et_next(%esi),%esi
	cmpl	%edx,et_u(%esi)
	jge	.Linsert_new_edges_found
	movl	et_next(%esi),%esi
	jmp	.Linsert_new_edges_search
.Linsert_new_edges_found:
	movl	%esi,et_next(%ebx)
	movl	et_prev(%esi),%eax
	movl	%eax,et_prev(%ebx)
	movl	%ebx,et_next(%eax)
	movl	%ebx,et_prev(%esi)
	movl	%edi,%ebx
	testl	%ebx,%ebx
	jne	.Linsert_new_edges_next
	popl	%edi
	popl	%esi
	popl	%ebx
	ret

	.p2align 4,,15
	.globl C(R_RemoveEdges_asm486)
C(R_RemoveEdges_asm486):
	pushl	%ebx
	movl	8(%esp),%ebx
.Lremove_edges_loop:
	movl	et_next(%ebx),%eax
	movl	et_prev(%ebx),%edx
	movl	%edx,et_prev(%eax)
	movl	%eax,et_next(%edx)
	movl	et_nextremove(%ebx),%ebx
	testl	%ebx,%ebx
	jne	.Lremove_edges_loop
	popl	%ebx
	ret

	.p2align 4,,15
	.globl C(R_StepActiveU_asm486)
C(R_StepActiveU_asm486):
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	movl	16(%esp),%ebx
.Lstep_active_u_group:
	/* Keep the original four-edge unroll used by the C reference. */
	movl	et_u(%ebx),%eax
	addl	et_u_step(%ebx),%eax
	movl	%eax,et_u(%ebx)
	movl	et_prev(%ebx),%edx
	cmpl	et_u(%edx),%eax
	jl	.Lstep_active_u_pushback
	movl	et_next(%ebx),%ebx

	movl	et_u(%ebx),%eax
	addl	et_u_step(%ebx),%eax
	movl	%eax,et_u(%ebx)
	movl	et_prev(%ebx),%edx
	cmpl	et_u(%edx),%eax
	jl	.Lstep_active_u_pushback
	movl	et_next(%ebx),%ebx

	movl	et_u(%ebx),%eax
	addl	et_u_step(%ebx),%eax
	movl	%eax,et_u(%ebx)
	movl	et_prev(%ebx),%edx
	cmpl	et_u(%edx),%eax
	jl	.Lstep_active_u_pushback
	movl	et_next(%ebx),%ebx

	movl	et_u(%ebx),%eax
	addl	et_u_step(%ebx),%eax
	movl	%eax,et_u(%ebx)
	movl	et_prev(%ebx),%edx
	cmpl	et_u(%edx),%eax
	jl	.Lstep_active_u_pushback
	movl	et_next(%ebx),%ebx
	jmp	.Lstep_active_u_group

.Lstep_active_u_pushback:
	leal	C(edge_aftertail),%eax
	cmpl	%eax,%ebx
	je	.Lstep_active_u_done
	movl	et_next(%ebx),%esi		/* pnext_edge */
	movl	et_prev(%ebx),%edx
	movl	%esi,%eax
	movl	%edx,et_prev(%eax)
	movl	%eax,et_next(%edx)
	movl	et_prev(%edx),%edi		/* previous edge's previous edge */
	movl	et_u(%ebx),%edx		/* keep target U out of the search loop */
.Lstep_active_u_find:
	cmpl	%edx,et_u(%edi)
	jle	.Lstep_active_u_reinsert
	movl	et_prev(%edi),%edi
	jmp	.Lstep_active_u_find
.Lstep_active_u_reinsert:
	movl	et_next(%edi),%eax
	movl	%eax,et_next(%ebx)
	movl	%edi,et_prev(%ebx)
	movl	%ebx,et_prev(%eax)
	movl	%ebx,et_next(%edi)
	movl	%esi,%ebx
	leal	C(edge_tail),%eax
	cmpl	%eax,%ebx
	jne	.Lstep_active_u_group
.Lstep_active_u_done:
	popl	%edi
	popl	%esi
	popl	%ebx
	ret
#endif

#ifdef ASM486_BACKWARD_SPANS
	.extern C(r_bmodelactive)
	.extern C(surfaces)
	.extern C(span_p)
	.extern C(current_iv)
	.extern C(edge_head_u_shift20)
	.extern C(edge_tail_u_shift20)
	.extern C(edge_head)
	.extern C(edge_tail)

	.p2align 4,,15
	.globl C(R_CleanupSpan_asm486)
C(R_CleanupSpan_asm486):
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	movl	C(surfaces),%eax
	leal	st_size(%eax),%edi		// surfaces[1]
	movl	st_next(%edi),%ebx		// current top
	movl	C(edge_tail_u_shift20),%eax
	cmpl	st_last_u(%ebx),%eax
	jle	.Lbackspan_cleanup_reset
	movl	C(span_p),%esi
	movl	st_last_u(%ebx),%edx
	movw	%dx,espan_t_u(%esi)
	subl	%edx,%eax
	movl	%eax,espan_t_count(%esi)
	movl	C(current_iv),%eax
	movw	%ax,espan_t_v(%esi)
	movl	st_spans(%ebx),%eax
	movl	%eax,espan_t_pnext(%esi)
	movl	%esi,st_spans(%ebx)
	leal	espan_t_size(%esi),%eax
	movl	%eax,C(span_p)

.Lbackspan_cleanup_reset:
	movl	C(surfaces),%eax
	leal	st_size(%eax),%edi		// surfaces[1]
	movl	st_next(%edi),%ebx
.Lbackspan_cleanup_loop:
	movl	$0,st_spanstate(%ebx)
	movl	st_next(%ebx),%ebx
	cmpl	%edi,%ebx
	jne	.Lbackspan_cleanup_loop
	popl	%edi
	popl	%esi
	popl	%ebx
	ret

	.p2align 4,,15
	.globl C(R_TrailingEdge_asm486)
C(R_TrailingEdge_asm486):
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	movl	16(%esp),%edi			// surf
	movl	20(%esp),%ebx			// edge
	decl	st_spanstate(%edi)
	jnz	.Lbackspan_trailing_return
	cmpl	$0,st_insubmodel(%edi)
	je	.Lbackspan_trailing_top_test
	decl	C(r_bmodelactive)
.Lbackspan_trailing_top_test:
	movl	C(surfaces),%eax
	leal	st_size(%eax),%eax
	cmpl	st_next(%eax),%edi
	jne	.Lbackspan_trailing_unlink
	movl	et_u(%ebx),%esi
	sarl	$20,%esi				// iu = edge->u >> 20
	cmpl	st_last_u(%edi),%esi
	jle	.Lbackspan_trailing_update_below
	movl	C(span_p),%eax
	movl	st_last_u(%edi),%edx
	movw	%dx,espan_t_u(%eax)
	movl	%esi,%ecx
	subl	%edx,%ecx
	movl	%ecx,espan_t_count(%eax)
	movl	C(current_iv),%ecx
	movw	%cx,espan_t_v(%eax)
	movl	st_spans(%edi),%ecx
	movl	%ecx,espan_t_pnext(%eax)
	movl	%eax,st_spans(%edi)
	leal	espan_t_size(%eax),%eax
	movl	%eax,C(span_p)
.Lbackspan_trailing_update_below:
	movl	st_next(%edi),%edx
	movl	%esi,st_last_u(%edx)
.Lbackspan_trailing_unlink:
	movl	st_next(%edi),%eax
	movl	st_prev(%edi),%edx
	movl	%eax,st_next(%edx)
	movl	%edx,st_prev(%eax)
.Lbackspan_trailing_return:
	popl	%edi
	popl	%esi
	popl	%ebx
	ret

	.p2align 4,,15
	.globl C(R_LeadingEdgeBackwards_asm486)
C(R_LeadingEdgeBackwards_asm486):
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	movl	16(%esp),%ebx			// edge
	movl	C(surfaces),%eax
	movzwl	et_surfs+2(%ebx),%edx
	shll	$6,%edx
	leal	(%eax,%edx),%edi		// surf = surfaces[edge->surfs[1]]
	incl	st_spanstate(%edi)
	cmpl	$1,st_spanstate(%edi)
	jne	.Lbackspan_leading_return
	movl	C(surfaces),%eax
	leal	st_size(%eax),%esi		// surfaces[1]
	movl	st_next(%esi),%esi		// surf2 = current top
	movl	st_key(%edi),%eax
	cmpl	st_key(%esi),%eax
	jg	.Lbackspan_leading_newtop
	cmpl	st_key(%esi),%eax
	jne	.Lbackspan_leading_search
	cmpl	$0,st_insubmodel(%edi)
	jne	.Lbackspan_leading_newtop

.Lbackspan_leading_search:
	movl	st_key(%edi),%eax
.Lbackspan_leading_search_next:
	movl	st_next(%esi),%esi
	cmpl	st_key(%esi),%eax
	jl	.Lbackspan_leading_search_next
	cmpl	st_key(%esi),%eax
	jne	.Lbackspan_leading_insert
	cmpl	$0,st_insubmodel(%edi)
	je	.Lbackspan_leading_search_next
	jmp	.Lbackspan_leading_insert

.Lbackspan_leading_newtop:
	movl	et_u(%ebx),%eax
	sarl	$20,%eax				// iu = edge->u >> 20
	cmpl	st_last_u(%esi),%eax
	jle	.Lbackspan_leading_set_last
	movl	C(span_p),%edx
	movl	st_last_u(%esi),%ecx
	movw	%cx,espan_t_u(%edx)
	subl	%ecx,%eax
	movl	%eax,espan_t_count(%edx)
	movl	C(current_iv),%eax
	movw	%ax,espan_t_v(%edx)
	movl	st_spans(%esi),%eax
	movl	%eax,espan_t_pnext(%edx)
	movl	%edx,st_spans(%esi)
	leal	espan_t_size(%edx),%edx
	movl	%edx,C(span_p)
	movl	et_u(%ebx),%eax
	sarl	$20,%eax
.Lbackspan_leading_set_last:
	movl	%eax,st_last_u(%edi)

.Lbackspan_leading_insert:
	movl	st_prev(%esi),%eax
	movl	%esi,st_next(%edi)
	movl	%eax,st_prev(%edi)
	movl	%edi,st_next(%eax)
	movl	%edi,st_prev(%esi)
.Lbackspan_leading_return:
	popl	%edi
	popl	%esi
	popl	%ebx
	ret

	.p2align 4,,15
	.globl C(R_GenerateSpansBackward_asm486)
C(R_GenerateSpansBackward_asm486):
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	movl	$0,C(r_bmodelactive)
	movl	C(surfaces),%eax
	leal	st_size(%eax),%edi		// surfaces[1]
	movl	%edi,st_next(%edi)
	movl	%edi,st_prev(%edi)
	movl	C(edge_head_u_shift20),%eax
	movl	%eax,st_last_u(%edi)
	movl	C(edge_head)+et_next,%ebx
.Lbackspan_generate_loop:
	cmpl	$C(edge_tail),%ebx
	je	.Lbackspan_generate_cleanup
	movzwl	et_surfs(%ebx),%eax
	testl	%eax,%eax
	je	.Lbackspan_generate_leading
	movl	C(surfaces),%edi
	shll	$6,%eax
	addl	%eax,%edi
	decl	st_spanstate(%edi)
	jnz	.Lbackspan_generate_leading
	incl	st_spanstate(%edi)
	pushl	%ebx
	pushl	%edi
	call	C(R_TrailingEdge_asm486)
	addl	$8,%esp
.Lbackspan_generate_leading:
	movzwl	et_surfs+2(%ebx),%eax
	testl	%eax,%eax
	je	.Lbackspan_generate_next
	pushl	%ebx
	call	C(R_LeadingEdgeBackwards_asm486)
	addl	$4,%esp
.Lbackspan_generate_next:
	movl	et_next(%ebx),%ebx
	jmp	.Lbackspan_generate_loop
.Lbackspan_generate_cleanup:
	call	C(R_CleanupSpan_asm486)
	popl	%edi
	popl	%esi
	popl	%ebx
	ret
#endif

#ifdef ASM486_EMIT_CACHED_EDGE
	.extern C(r_pedge)
	.extern C(r_edges)
	.extern C(surface_p)
	.extern C(surfaces)
	.extern C(r_nearzi)
	.extern C(r_emitted)
#ifdef PROFILE486
	.extern C(bench486_profile_frame_active)
	.extern C(bench486_emitcachededge_calls)
#endif

	.text
	.p2align 4,,15
	.globl C(R_EmitCachedEdge_asm486)
C(R_EmitCachedEdge_asm486):
#ifdef PROFILE486
	cmpl	$0,C(bench486_profile_frame_active)
	je	.Lemit_cached_profile_done
	incl	C(bench486_emitcachededge_calls)
.Lemit_cached_profile_done:
#endif

	/* The cached edge offset is relative to the active frame edge buffer. */
	movl	C(r_pedge),%edx
	movl	me_cachededgeoffset(%edx),%ecx
	addl	C(r_edges),%ecx

	/* Fill the first empty surface slot, matching the C short stores. */
	cmpw	$0,et_surfs(%ecx)
	jne	.Lemit_cached_surf1
	movl	C(surface_p),%eax
	subl	C(surfaces),%eax
	sarl	$SURF_T_SHIFT,%eax
	movw	%ax,et_surfs(%ecx)
	jmp	.Lemit_cached_nearzi
.Lemit_cached_surf1:
	movl	C(surface_p),%eax
	subl	C(surfaces),%eax
	sarl	$SURF_T_SHIFT,%eax
	movw	%ax,et_surfs+2(%ecx)

.Lemit_cached_nearzi:
	/* Strict ordered comparison; always pop the temporary x87 value. */
	flds	et_nearzi(%ecx)
	fcoms	C(r_nearzi)
	fnstsw	%ax
	testb	$0x45,%ah
	jnz	.Lemit_cached_keep_nearzi
	fstps	C(r_nearzi)
	jmp	.Lemit_cached_nearzi_done
.Lemit_cached_keep_nearzi:
	fstp	%st(0)
.Lemit_cached_nearzi_done:
	movl	$1,C(r_emitted)
	ret
#endif

#ifdef ASM486_RENDER_FACE
	.extern C(R_ClipEdge)
	.extern C(R_RenderFaceGradient_asm486)
	.extern C(c_faceclip)
	.extern C(r_currentkey)
	.extern C(r_polycount)
	.extern C(r_outofsurfaces)
	.extern C(r_outofedges)
	.extern C(surf_max)
	.extern C(surface_p)
	.extern C(surfaces)
	.extern C(edge_p)
	.extern C(edge_max)
	.extern C(r_edges)
	.extern C(insubmodel)
	.extern C(r_pedge)
	.extern C(r_leftclipped)
	.extern C(r_rightclipped)
	.extern C(makeleftedge)
	.extern C(makerightedge)
	.extern C(r_nearzionly)
	.extern C(r_nearzi)
	.extern C(r_emitted)
	.extern C(r_lastvertvalid)
	.extern C(cacheoffset)
	.extern C(r_framecount)
	.extern C(r_pcurrentvertbase)
	.extern C(R_ClipEdgeRegs)
	.extern C(R_ClipEdgeStack)
	.extern C(view_clipplanes)
	.extern C(view_clipplanes_fullmask)
	.extern C(r_renderface_clipflags_cache)
	.extern C(r_renderface_clipchain_cache)
	.extern C(r_leftexit)
	.extern C(r_leftenter)
	.extern C(r_rightexit)
	.extern C(r_rightenter)
	.extern C(currententity)

#ifdef PROFILE486
	.extern C(bench486_profile_frame_active)
	.extern C(bench486_renderface_calls)
	.extern C(bench486_renderface_emitted)
	.extern C(bench486_renderface_edge_setups)
	.extern C(bench486_renderface_early_surfs)
	.extern C(bench486_renderface_early_edges)
	.extern C(bench486_renderface_faces)
	.extern C(bench486_renderface_clipchain_builds)
	.extern C(bench486_renderface_clipchain_cache_hits)
	.extern C(bench486_renderface_general_edges)
	.extern C(bench486_emitcachededge_calls)
	.extern C(bench486_clipvertex_world_endpoint_uses)
	.extern C(bench486_clipvertex_world_unique_uses)
	.extern C(bench486_clipvertex_seen_world)
#endif

	.equ RF_PCLIP, 36
	.equ RF_TEDGE, 28
	.equ RF_MEDGE, 20
	.equ RF_VERTEX0, 12
	.equ RF_VERTEX1, 16

	.text
	.globl C(R_RenderFace_asm486)
C(R_RenderFace_asm486):
	pushl	%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	/* Reserve 12 bytes of outgoing R_ClipEdge arguments in the local frame. */
	subl	$40,%esp

	/* Keep the model edge base in callee-saved EBP; locals use ESP offsets. */
	movl	68(%esp),%ebp			/* medge_t *pedges */
	movl	60(%esp),%ebx			/* msurface_t *fa */
	movl	72(%esp),%esi			/* model surfedges + firstedge */

#ifdef PROFILE486
	cmpl	$0,C(bench486_profile_frame_active)
	je	.Lrf_profile_entry_done
	incl	C(bench486_renderface_calls)
	movl	24(%ebx),%eax
	addl	%eax,C(bench486_renderface_edge_setups)
	movl	64(%esp),%eax
	andl	$15,%eax
	movl	%eax,%edx
	shrl	$1,%edx
	andl	$5,%eax
	andl	$5,%edx
	addl	%edx,%eax
	movl	%eax,%edx
	shrl	$2,%edx
	andl	$3,%eax
	andl	$3,%edx
	addl	%edx,%eax
	andl	$15,%eax
	addl	%eax,C(bench486_renderface_faces)
.Lrf_profile_entry_done:
#endif

	/* if ((surface_p) >= surf_max) */
	movl	C(surface_p),%eax
	movl	24(%ebx),%edx
	cmpl	C(surf_max),%eax
	jae	.Lrf_early_surfaces

	/* if (edge_p + fa->numedges + 4) >= edge_max */
	leal	4(%edx),%ecx
	shll	$5,%ecx
	addl	C(edge_p),%ecx
	cmpl	C(edge_max),%ecx
	jae	.Lrf_early_edges
	/* Keep remaining surfedges in callee-saved EDI across R_ClipEdge. */
	movl	%edx,%edi

	incl	C(c_faceclip)

	/* Build the same 3..0 clip chain as the C reference. */
	/* The common full mask can link that chain without per-plane tests. */
	movl	64(%esp),%edx
	cmpl	$15,%edx
	jne	.Lrf_clip_masked
#ifdef ASM486_TRANSFORM_FRUSTUM
	movl	$C(view_clipplanes_fullmask),%eax
#else
	movl	$C(view_clipplanes),%ecx
	movl	$0,88(%ecx)
	leal	72(%ecx),%eax
	movl	%eax,64(%ecx)
	leal	48(%ecx),%eax
	movl	%eax,40(%ecx)
	leal	24(%ecx),%eax
	movl	%eax,16(%ecx)
	movl	%ecx,%eax
	/* This full-mask path rewrote the base planes. */
	movl	$-1,C(r_renderface_clipflags_cache)
#endif
	jmp	.Lrf_clip_ready
.Lrf_clip_masked:
	/* Reuse the live chain when adjacent BSP faces share this mask. */
	cmpl	C(r_renderface_clipflags_cache),%edx
	jne	.Lrf_clip_build_masked
	movl	C(r_renderface_clipchain_cache),%eax
#ifdef PROFILE486
	cmpl	$0,C(bench486_profile_frame_active)
	je	.Lrf_clip_hit_counted
	incl	C(bench486_renderface_clipchain_cache_hits)
.Lrf_clip_hit_counted:
#endif
	jmp	.Lrf_clip_ready_cached
.Lrf_clip_build_masked:
	xorl	%eax,%eax
	testl	$8,%edx
	je	.Lrf_clip2
	movl	$C(view_clipplanes)+72,%ecx
	movl	%eax,16(%ecx)
	movl	%ecx,%eax
.Lrf_clip2:
	testl	$4,%edx
	je	.Lrf_clip1
	movl	$C(view_clipplanes)+48,%ecx
	movl	%eax,16(%ecx)
	movl	%ecx,%eax
.Lrf_clip1:
	testl	$2,%edx
	je	.Lrf_clip0
	movl	$C(view_clipplanes)+24,%ecx
	movl	%eax,16(%ecx)
	movl	%ecx,%eax
.Lrf_clip0:
	testl	$1,%edx
	je	.Lrf_clip_ready
	movl	$C(view_clipplanes),%ecx
	movl	%eax,16(%ecx)
	movl	%ecx,%eax
.Lrf_clip_ready:
#ifdef PROFILE486
	/* Count only partial-mask misses; the full-mask chain is prelinked. */
	cmpl	$15,%edx
	je	.Lrf_clip_profile_done
	cmpl	$0,C(bench486_profile_frame_active)
	je	.Lrf_clip_profile_done
	incl	C(bench486_renderface_clipchain_builds)
.Lrf_clip_profile_done:
#endif
	cmpl	$15,%edx
	je	.Lrf_clip_cache_done
	movl	%edx,C(r_renderface_clipflags_cache)
	movl	%eax,C(r_renderface_clipchain_cache)
.Lrf_clip_cache_done:
	jmp	.Lrf_clip_ready_done
.Lrf_clip_ready_cached:
	/* Do not dirty the same cache entry again on a hit. */
.Lrf_clip_ready_done:
	movl	%eax,RF_PCLIP(%esp)
	/* The edge-loop clip-plane argument is constant for this face. */
	movl	%eax,8(%esp)

	movl	$0,C(r_emitted)
	movl	$0,C(r_nearzi)
	movl	$0,C(r_nearzionly)
	movl	$0,C(makeleftedge)
	movl	$0,C(makerightedge)
	movl	$0,C(r_lastvertvalid)

#ifdef PROFILE486
	cmpl	$0,C(bench486_profile_frame_active)
	je	.Lrf_profile_edges_done
	movl	24(%ebx),%eax
	testl	%eax,%eax
	jle	.Lrf_profile_edges_done
	cmpl	$3,%eax
	je	.Lrf_profile_edges_done
	cmpl	$4,%eax
	je	.Lrf_profile_edges_done
	addl	%eax,C(bench486_renderface_general_edges)
.Lrf_profile_edges_done:
#endif

	/* EBX becomes the stable current-vertex base for both endpoints. */
	movl	C(r_pcurrentvertbase),%ebx
	testl	%edi,%edi
	jle	.Lrf_edges_done
	/* One R_ClipEdgeRegs stack base serves every edge in this face. */
	leal	-16(%esp),%eax
	movl	%eax,C(R_ClipEdgeStack)

	/* Select the cache-free submodel path once before processing any edge. */
	cmpl	$0,C(insubmodel)
	jne	.Lrf_submodel_edge_loop
.Lrf_edge_loop:
	lodsl						/* consume surfedge and advance the cursor */
	/* Positive and negative edges share the address calculation. */
	testl	%eax,%eax
	jg	.Lrf_edge_address_ready
	negl	%eax
.Lrf_edge_address_ready:
	leal	(%ebp,%eax,8),%ecx
.Lrf_edge_ready:
	/* Fetch the cached offset only when its high-bit frame marker is set. */
	testl	$0x80000000,4(%ecx)
	je	.Lrf_check_regular_cache
	movl	4(%ecx),%eax
	andl	$0x7fffffff,%eax
	cmpl	C(r_framecount),%eax
	jne	.Lrf_clip_edge
	movl	$0,C(r_lastvertvalid)
	jmp	.Lrf_next_edge

.Lrf_check_regular_cache:
	movl	C(edge_p),%eax
	subl	C(r_edges),%eax
	cmpl	4(%ecx),%eax
	jbe	.Lrf_clip_edge_offset_ready
	movl	4(%ecx),%edx
	addl	C(r_edges),%edx
	cmpl	%ecx,28(%edx)
	jne	.Lrf_clip_edge_offset_ready

	/* Match the cached-edge surface assignment used by R_EmitCachedEdge. */
#ifdef PROFILE486
	cmpl	$0,C(bench486_profile_frame_active)
	je	.Lrf_cached_profile_done
	incl	C(bench486_emitcachededge_calls)
.Lrf_cached_profile_done:
#endif
	cmpw	$0,16(%edx)
	jne	.Lrf_cached_surf1
	movl	C(surface_p),%eax
	subl	C(surfaces),%eax
	sarl	$6,%eax
	movw	%ax,16(%edx)
	jmp	.Lrf_cached_nearzi
.Lrf_cached_surf1:
	/* edge_t.surfs[] are unsigned shorts; never overwrite both slots. */
	movl	C(surface_p),%eax
	subl	C(surfaces),%eax
	sarl	$6,%eax
	movw	%ax,18(%edx)
.Lrf_cached_nearzi:
	flds	24(%edx)
	fcoms	C(r_nearzi)
	fnstsw	%ax
	testb	$0x45,%ah
	jnz	.Lrf_cached_nearzi_keep
	fstps	C(r_nearzi)
	jmp	.Lrf_cached_nearzi_done
.Lrf_cached_nearzi_keep:
	fstp	%st(0)
.Lrf_cached_nearzi_done:
	movl	$1,C(r_emitted)
	movl	$0,C(r_lastvertvalid)
	jmp	.Lrf_next_edge

.Lrf_clip_edge:
	movl	C(edge_p),%eax
	subl	C(r_edges),%eax
.Lrf_clip_edge_offset_ready:
	movl	%ecx,C(r_pedge)
	movl	%ecx,RF_MEDGE(%esp)
	movl	%eax,C(cacheoffset)
	movl	$0,C(r_leftclipped)
	movl	$0,C(r_rightclipped)

	/* Compare the signed surfedge in memory; EAX is reloaded with the vertex. */
	movzwl	0(%ecx),%eax
	movzwl	2(%ecx),%edx
	cmpl	$0,-4(%esi)
	jg	.Lrf_vertices_ready
	xchgl	%eax,%edx
.Lrf_vertices_ready:
	/* Count distinct world-model endpoints once per profiled frame. */
#ifdef PROFILE486
	cmpl	$0,C(bench486_profile_frame_active)
	je	.Lrf_profile_vertex_count_done
	cmpl	$0,C(insubmodel)
	jne	.Lrf_profile_vertex_count_done
	cmpl	$0,RF_PCLIP(%esp)
	je	.Lrf_profile_vertex_count_done
	movl	%eax,RF_VERTEX0(%esp)
	movl	%edx,RF_VERTEX1(%esp)
	addl	$2,C(bench486_clipvertex_world_endpoint_uses)
	movl	RF_VERTEX0(%esp),%ecx
	movl	%ecx,%edx
	shrl	$5,%ecx
	andl	$31,%edx
	btsl	%edx,C(bench486_clipvertex_seen_world)(,%ecx,4)
	jc	.Lrf_profile_vertex1
	incl	C(bench486_clipvertex_world_unique_uses)
.Lrf_profile_vertex1:
	movl	RF_VERTEX1(%esp),%ecx
	movl	%ecx,%edx
	shrl	$5,%ecx
	andl	$31,%edx
	btsl	%edx,C(bench486_clipvertex_seen_world)(,%ecx,4)
	jc	.Lrf_profile_vertex_restore
	incl	C(bench486_clipvertex_world_unique_uses)
.Lrf_profile_vertex_restore:
	movl	RF_VERTEX0(%esp),%eax
	movl	RF_VERTEX1(%esp),%edx
.Lrf_profile_vertex_count_done:
#endif
	/* EAX/EDX are the ordered vertex indices; form byte addresses. */
	leal	(%eax,%eax,2),%eax
	leal	(%ebx,%eax,4),%eax
	leal	(%edx,%edx,2),%edx
	leal	(%ebx,%edx,4),%edx
	movl	RF_PCLIP(%esp),%ecx
	call	C(R_ClipEdgeRegs)
	movl	RF_MEDGE(%esp),%ecx
	movl	C(cacheoffset),%eax
	movl	%eax,4(%ecx)
	cmpl	$0,C(r_leftclipped)
	je	.Lrf_left_flag_done
	movl	$1,C(makeleftedge)
.Lrf_left_flag_done:
	cmpl	$0,C(r_rightclipped)
	je	.Lrf_right_flag_done
	movl	$1,C(makerightedge)
.Lrf_right_flag_done:
	movl	$1,C(r_lastvertvalid)

.Lrf_next_edge:
	decl	%edi
	jnz	.Lrf_edge_loop
	jmp	.Lrf_edges_done

/* Submodel edges never use the regular edge cache. Keep that branch outside
 * the loop and use a dedicated clipping loop without changing clip behavior. */
.Lrf_submodel_edge_loop:
	lodsl
	/* Positive and negative edges share the address calculation. */
	testl	%eax,%eax
	jg	.Lrf_submodel_edge_address_ready
	negl	%eax
.Lrf_submodel_edge_address_ready:
	leal	(%ebp,%eax,8),%ecx
.Lrf_submodel_edge_ready:
	movl	%ecx,C(r_pedge)
	movl	%ecx,RF_MEDGE(%esp)
	movl	C(edge_p),%eax
	subl	C(r_edges),%eax
	movl	%eax,C(cacheoffset)
	movl	$0,C(r_leftclipped)
	movl	$0,C(r_rightclipped)

	/* Compare the signed surfedge in memory; EAX is reloaded with the vertex. */
	movzwl	0(%ecx),%eax
	movzwl	2(%ecx),%edx
	cmpl	$0,-4(%esi)
	jg	.Lrf_submodel_vertices_ready
	xchgl	%eax,%edx
.Lrf_submodel_vertices_ready:
	/* EAX/EDX are the ordered vertex indices; form byte addresses. */
	leal	(%eax,%eax,2),%eax
	leal	(%ebx,%eax,4),%eax
	leal	(%edx,%edx,2),%edx
	leal	(%ebx,%edx,4),%edx
	movl	RF_PCLIP(%esp),%ecx
	call	C(R_ClipEdgeRegs)
	movl	RF_MEDGE(%esp),%ecx
	movl	C(cacheoffset),%eax
	movl	%eax,4(%ecx)
	cmpl	$0,C(r_leftclipped)
	je	.Lrf_submodel_left_flag_done
	movl	$1,C(makeleftedge)
.Lrf_submodel_left_flag_done:
	cmpl	$0,C(r_rightclipped)
	je	.Lrf_submodel_right_flag_done
	movl	$1,C(makerightedge)
.Lrf_submodel_right_flag_done:
	movl	$1,C(r_lastvertvalid)
	decl	%edi
	jnz	.Lrf_submodel_edge_loop

.Lrf_edges_done:
	movl	60(%esp),%ebx			/* restore msurface_t *fa */
	cmpl	$0,C(makeleftedge)
	je	.Lrf_right_clip
	leal	RF_TEDGE(%esp),%eax
	movl	%eax,C(r_pedge)
	movl	$0,C(r_lastvertvalid)
	movl	RF_PCLIP(%esp),%eax
	movl	16(%eax),%eax
	movl	%eax,8(%esp)
	movl	$C(r_leftenter),4(%esp)
	movl	$C(r_leftexit),0(%esp)
	call	C(R_ClipEdge)

.Lrf_right_clip:
	cmpl	$0,C(makerightedge)
	je	.Lrf_post_surface
	leal	RF_TEDGE(%esp),%eax
	movl	%eax,C(r_pedge)
	movl	$0,C(r_lastvertvalid)
	movl	$1,C(r_nearzionly)
#ifdef ASM486_TRANSFORM_FRUSTUM
	cmpl	$C(view_clipplanes_fullmask),RF_PCLIP(%esp)
	jne	.Lrf_right_clip_original_tail
	movl	C(view_clipplanes_fullmask)+40,%eax
	jmp	.Lrf_right_clip_tail_ready
.Lrf_right_clip_original_tail:
#endif
	movl	C(view_clipplanes)+40,%eax
.Lrf_right_clip_tail_ready:
	movl	%eax,8(%esp)
	movl	$C(r_rightenter),4(%esp)
	movl	$C(r_rightexit),0(%esp)
	call	C(R_ClipEdge)

.Lrf_post_surface:
	cmpl	$0,C(r_emitted)
	je	.Lrf_return
#ifdef PROFILE486
	cmpl	$0,C(bench486_profile_frame_active)
	je	.Lrf_profile_emitted_done
	incl	C(bench486_renderface_emitted)
.Lrf_profile_emitted_done:
#endif
	incl	C(r_polycount)
	movl	C(surface_p),%eax
	movl	%ebx,28(%eax)
	movl	C(r_nearzi),%edx
	movl	%edx,36(%eax)
	movl	16(%ebx),%edx
	movl	%edx,24(%eax)
	movl	C(insubmodel),%edx
	movl	%edx,40(%eax)
	movl	$0,20(%eax)
	movl	C(currententity),%edx
	movl	%edx,32(%eax)
	movl	C(r_currentkey),%edx
	movl	%edx,12(%eax)
	incl	C(r_currentkey)
	movl	$0,8(%eax)
	movl	12(%ebx),%eax
	pushl	%eax
	call	C(R_RenderFaceGradient_asm486)
	addl	$4,%esp
	movl	C(surface_p),%eax
	addl	$64,%eax
	movl	%eax,C(surface_p)
	jmp	.Lrf_return

.Lrf_early_surfaces:
	incl	C(r_outofsurfaces)
#ifdef PROFILE486
	cmpl	$0,C(bench486_profile_frame_active)
	je	.Lrf_return
	incl	C(bench486_renderface_early_surfs)
#endif
	jmp	.Lrf_return

.Lrf_early_edges:
	movl	24(%ebx),%eax
	addl	%eax,C(r_outofedges)
#ifdef PROFILE486
	cmpl	$0,C(bench486_profile_frame_active)
	je	.Lrf_return
	incl	C(bench486_renderface_early_edges)
#endif

.Lrf_return:
	addl	$40,%esp
	popl	%edi
	popl	%esi
	popl	%ebx
	popl	%ebp
	ret

#endif

#ifdef ASM486_RENDER_BMODEL_FACE
	.extern C(R_ClipEdge)
	.extern C(R_RenderBmodelFaceGradient_asm486)
	.extern C(c_faceclip)
	.extern C(r_polycount)
	.extern C(r_outofsurfaces)
	.extern C(r_outofedges)
	.extern C(surf_max)
	.extern C(surface_p)
	.extern C(r_currentbkey)
	.extern C(edge_p)
	.extern C(edge_max)
	.extern C(r_clipflags)
	.extern C(r_pedge)
	.extern C(r_leftclipped)
	.extern C(r_rightclipped)
	.extern C(makeleftedge)
	.extern C(makerightedge)
	.extern C(r_nearzionly)
	.extern C(r_nearzi)
	.extern C(r_emitted)
	.extern C(r_lastvertvalid)
	.extern C(view_clipplanes)
	.extern C(r_renderface_clipflags_cache)
	.extern C(r_leftexit)
	.extern C(r_leftenter)
	.extern C(r_rightexit)
	.extern C(r_rightenter)
	.extern C(currententity)

.equ RBMF_PCLIP, -16
	.equ RBMF_TEDGE, -28

	.text
	.globl C(R_RenderBmodelFace_asm486)
C(R_RenderBmodelFace_asm486):
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	subl	$16,%esp

	movl	12(%ebp),%ebx			/* msurface_t *psurf */
	movl	8(%ebp),%esi			/* bedge_t *pedges */

	/* if (surface_p >= surf_max) */
	movl	C(surface_p),%eax
	cmpl	C(surf_max),%eax
	jae	.Lrbmf_early_surfaces

	/* if ((edge_p + psurf->numedges + 4) >= edge_max) */
	movl	24(%ebx),%edx
	leal	4(%edx),%ecx
	shll	$5,%ecx
	addl	C(edge_p),%ecx
	cmpl	C(edge_max),%ecx
	jae	.Lrbmf_early_edges

	incl	C(c_faceclip)

	/* The clipped bmodel edge path uses this temporary owner for all edges. */
	leal	RBMF_TEDGE(%ebp),%eax
	movl	%eax,C(r_pedge)

	/* Build the same 3..0 clip chain as the C reference. */
	movl	$-1,C(r_renderface_clipflags_cache)
	xorl	%eax,%eax
	movl	C(r_clipflags),%edx
	testl	$8,%edx
	je	.Lrbmf_clip2
	movl	$C(view_clipplanes)+72,%ecx
	movl	%eax,16(%ecx)
	movl	%ecx,%eax
.Lrbmf_clip2:
	testl	$4,%edx
	je	.Lrbmf_clip1
	movl	$C(view_clipplanes)+48,%ecx
	movl	%eax,16(%ecx)
	movl	%ecx,%eax
.Lrbmf_clip1:
	testl	$2,%edx
	je	.Lrbmf_clip0
	movl	$C(view_clipplanes)+24,%ecx
	movl	%eax,16(%ecx)
	movl	%ecx,%eax
.Lrbmf_clip0:
	testl	$1,%edx
	je	.Lrbmf_clip_ready
	movl	$C(view_clipplanes),%ecx
	movl	%eax,16(%ecx)
	movl	%ecx,%eax
.Lrbmf_clip_ready:
	movl	%eax,RBMF_PCLIP(%ebp)

	movl	$0,C(r_emitted)
	movl	$0,C(r_nearzi)
	movl	$0,C(r_nearzionly)
	movl	$0,C(makeleftedge)
	movl	$0,C(makerightedge)
	movl	$0,C(r_lastvertvalid)

.Lrbmf_edge_loop:
	testl	%esi,%esi
	je	.Lrbmf_edges_done
	movl	$0,C(r_leftclipped)
	movl	$0,C(r_rightclipped)
	pushl	RBMF_PCLIP(%ebp)
	pushl	4(%esi)				/* bedge_t::v[1] */
	pushl	0(%esi)				/* bedge_t::v[0] */
	call	C(R_ClipEdge)
	addl	$12,%esp
	cmpl	$0,C(r_leftclipped)
	je	.Lrbmf_left_flag_done
	movl	$1,C(makeleftedge)
.Lrbmf_left_flag_done:
	cmpl	$0,C(r_rightclipped)
	je	.Lrbmf_right_flag_done
	movl	$1,C(makerightedge)
.Lrbmf_right_flag_done:
	movl	8(%esi),%esi			/* bedge_t::pnext */
	jmp	.Lrbmf_edge_loop

.Lrbmf_edges_done:
	cmpl	$0,C(makeleftedge)
	je	.Lrbmf_right_clip
	leal	RBMF_TEDGE(%ebp),%eax
	movl	%eax,C(r_pedge)
	movl	RBMF_PCLIP(%ebp),%eax
	movl	16(%eax),%eax
	pushl	%eax
	pushl	$C(r_leftenter)
	pushl	$C(r_leftexit)
	call	C(R_ClipEdge)
	addl	$12,%esp

.Lrbmf_right_clip:
	cmpl	$0,C(makerightedge)
	je	.Lrbmf_post_surface
	leal	RBMF_TEDGE(%ebp),%eax
	movl	%eax,C(r_pedge)
	movl	$1,C(r_nearzionly)
	movl	C(view_clipplanes)+40,%eax
	pushl	%eax
	pushl	$C(r_rightenter)
	pushl	$C(r_rightexit)
	call	C(R_ClipEdge)
	addl	$12,%esp

.Lrbmf_post_surface:
	cmpl	$0,C(r_emitted)
	je	.Lrbmf_return
	incl	C(r_polycount)
	movl	C(surface_p),%edi
	movl	%ebx,28(%edi)			/* data = psurf */
	movl	C(r_nearzi),%eax
	movl	%eax,36(%edi)
	movl	16(%ebx),%eax
	movl	%eax,24(%edi)			/* flags */
	movl	$1,40(%edi)			/* insubmodel = true */
	movl	$0,20(%edi)			/* spanstate */
	movl	C(currententity),%eax
	movl	%eax,32(%edi)
	movl	C(r_currentbkey),%eax
	movl	%eax,12(%edi)
	movl	$0,8(%edi)			/* spans */
	movl	12(%ebx),%eax			/* psurf->plane */
	pushl	%eax
	call	C(R_RenderBmodelFaceGradient_asm486)
	addl	$4,%esp
	movl	C(surface_p),%eax
	addl	$64,%eax
	movl	%eax,C(surface_p)
	jmp	.Lrbmf_return

.Lrbmf_early_surfaces:
	incl	C(r_outofsurfaces)
	jmp	.Lrbmf_return

.Lrbmf_early_edges:
	movl	24(%ebx),%eax
	addl	%eax,C(r_outofedges)

.Lrbmf_return:
	leal	-12(%ebp),%esp
	popl	%edi
	popl	%esi
	popl	%ebx
	popl	%ebp
	ret

#endif

#ifdef ASM486_RENDER_POLY
	.extern C(currententity)
	.extern C(view_clipplanes)
	.extern C(r_renderface_clipflags_cache)
	.extern C(r_pcurrentvertbase)
	.extern C(r_pedge)
	.extern C(r_nearzi)
	.extern C(r_polydesc)
	.extern C(modelorg)
	.extern C(xscale)
	.extern C(yscale)
	.extern C(xcenter)
	.extern C(ycenter)
	.extern C(r_refdef)
	.extern C(TransformVector)
	.extern C(D_DrawPoly)

	.equ RPX_ENTITY_MODEL, 132
	.equ RPX_MODEL_EDGES, 156
	.equ RPX_MODEL_SURFEDGES, 188
	.equ RPX_SURFACE_PLANE, 12
	.equ RPX_SURFACE_FIRSTEDGE, 20
	.equ RPX_SURFACE_NUMEDGES, 24
	.equ RPX_MEDGE_SIZE, 8
	.equ RPX_MVERTEX_SIZE, 12
	.equ RPX_CLIP_DIST, 12
	.equ RPX_CLIP_NEXT, 16
	.equ RPX_CLIP_SIZE, 24
	.equ RPX_POLYVERT_SIZE, 20
	.equ RPX_VERTEX_PAGE_SIZE, 1200
	.equ RPX_STACK_BYTES, 4608
	.equ RPX_VERTS, -4608
	.equ RPX_PVERTS, -2208

	.equ RPX_I, -4
	.equ RPX_MASK, -8
	.equ RPX_LNUMVERTS, -12
	.equ RPX_SAXIS, -16
	.equ RPX_TAXIS, -20
	.equ RPX_LZI, -32
	.equ RPX_DIST, -160
	.equ RPX_LASTDIST, -172
	.equ RPX_FRAC, -184
	.equ RPX_PCLIP, -40
	.equ RPX_PEDGES, -44
	.equ RPX_SURFEDGES, -48
	.equ RPX_CURRPAGE, -52
	.equ RPX_NEWPAGE, -56
	.equ RPX_LASTVERT, -60
	.equ RPX_VISIBLE, -64
	.equ RPX_NEWVERTS, -68
	.equ RPX_MODEL, -72
	.equ RPX_EDGE_CURSOR, -76
	.equ RPX_VERTBASE, -80
	.equ RPX_SRC, -84
	.equ RPX_DST, -88
	.equ RPX_LOCAL, -104
	.equ RPX_TRANSFORMED, -116
	.equ RPX_PVERT_PTR, -120
	.equ RPX_LAST_VERTEX, -124
	.equ RPX_LAST_POSITIVE, -128
	.equ RPX_DIST_POSITIVE, -132
	.equ RPX_CLIP_FLAGS, -136
	.equ RPX_PPLANE, -140

	.section .rodata
	.p2align 3
.Lrpx_near_clip_double:
	.double 0.01
.Lrpx_near_clip_float:
	.long 0x3c23d70a
.Lrpx_reciprocal_numerator:
	.long 0x3f800000
.Lrpx_near_clip_reciprocal:
	.long 0x42c80000

	.text
	.globl C(R_RenderPoly_asm486)
C(R_RenderPoly_asm486):
	pushl	%ebp
	movl	%esp,%ebp
	/* Keep the EBP-relative locals clear of the saved callee registers. */
	subl	$RPX_STACK_BYTES,%esp
	pushl	%ebx
	pushl	%esi
	pushl	%edi

	// Build the linked clip-plane chain in the same descending plane order as C.
	movl	$-1,C(r_renderface_clipflags_cache)
	movl	$0,RPX_PCLIP(%ebp)
	movl	12(%ebp),%eax
	movl	%eax,RPX_CLIP_FLAGS(%ebp)
	movl	$3,RPX_I(%ebp)
	movl	$8,RPX_MASK(%ebp)
.Lrpx_clip_chain:
	movl	RPX_CLIP_FLAGS(%ebp),%eax
	testl	RPX_MASK(%ebp),%eax
	je	.Lrpx_clip_chain_next
	movl	RPX_I(%ebp),%eax
	imull	$RPX_CLIP_SIZE,%eax,%eax
	movl	$C(view_clipplanes),%edx
	addl	%eax,%edx
	movl	RPX_PCLIP(%ebp),%ecx
	movl	%ecx,RPX_CLIP_NEXT(%edx)
	movl	%edx,RPX_PCLIP(%ebp)
.Lrpx_clip_chain_next:
	shrl	$1,RPX_MASK(%ebp)
	decl	RPX_I(%ebp)
	jns	.Lrpx_clip_chain

	// Reconstruct the polygon from the model's surfedge and edge tables.
	movl	C(currententity),%eax
	movl	RPX_ENTITY_MODEL(%eax),%eax
	movl	%eax,RPX_MODEL(%ebp)
	movl	RPX_MODEL_EDGES(%eax),%edx
	movl	%edx,RPX_PEDGES(%ebp)
	movl	RPX_MODEL_SURFEDGES(%eax),%edx
	movl	%edx,RPX_SURFEDGES(%ebp)
	movl	8(%ebp),%eax
	movl	RPX_SURFACE_NUMEDGES(%eax),%edx
	cmpl	$100,%edx
	jg	.Lrpx_return
	movl	%edx,RPX_LNUMVERTS(%ebp)
	// The running edge pointer is surfedges + firstedge.
	movl	8(%ebp),%eax
	movl	RPX_SURFACE_FIRSTEDGE(%eax),%ecx
	movl	RPX_SURFEDGES(%ebp),%eax
	leal	(%eax,%ecx,4),%eax
	movl	%eax,RPX_EDGE_CURSOR(%ebp)
	movl	$0,RPX_I(%ebp)
.Lrpx_reconstruct:
	movl	RPX_I(%ebp),%ecx
	cmpl	RPX_LNUMVERTS(%ebp),%ecx
	jge	.Lrpx_reconstruct_done
	movl	RPX_EDGE_CURSOR(%ebp),%eax
	movl	(%eax),%edx
	addl	$4,%eax
	movl	%eax,RPX_EDGE_CURSOR(%ebp)
	testl	%edx,%edx
	jg	.Lrpx_edge_forward
	negl	%edx
	movl	RPX_PEDGES(%ebp),%eax
	leal	(%eax,%edx,RPX_MEDGE_SIZE),%eax
	movl	%eax,C(r_pedge)
	movzwl	2(%eax),%edx
	jmp	.Lrpx_edge_vertex
.Lrpx_edge_forward:
	movl	RPX_PEDGES(%ebp),%eax
	leal	(%eax,%edx,RPX_MEDGE_SIZE),%eax
	movl	%eax,C(r_pedge)
	movzwl	(%eax),%edx
.Lrpx_edge_vertex:
	movl	C(r_pcurrentvertbase),%esi
	leal	(%edx,%edx,2),%edx
	leal	(%esi,%edx,4),%esi
	movl	RPX_I(%ebp),%ecx
	leal	(%ecx,%ecx,2),%ecx
	shll	$2,%ecx
	leal	RPX_VERTS(%ebp,%ecx),%edi
	movl	(%esi),%eax
	movl	%eax,(%edi)
	movl	4(%esi),%eax
	movl	%eax,4(%edi)
	movl	8(%esi),%eax
	movl	%eax,8(%edi)
	incl	RPX_I(%ebp)
	jmp	.Lrpx_reconstruct
.Lrpx_reconstruct_done:

	// Clip against each selected plane, alternating the two 100-vertex pages.
	movl	$0,RPX_CURRPAGE(%ebp)
.Lrpx_clip_loop:
	movl	RPX_PCLIP(%ebp),%edx
	testl	%edx,%edx
	je	.Lrpx_clipping_done
	movl	RPX_LNUMVERTS(%ebp),%eax
	decl	%eax
	movl	%eax,RPX_LASTVERT(%ebp)
	movl	RPX_CURRPAGE(%ebp),%eax
	imull	$RPX_VERTEX_PAGE_SIZE,%eax,%eax
	leal	RPX_VERTS(%ebp,%eax),%esi
	movl	%esi,RPX_VERTBASE(%ebp)
	movl	RPX_LASTVERT(%ebp),%eax
	leal	(%eax,%eax,2),%eax
	leal	(%esi,%eax,4),%edi
	movl	%edi,RPX_LAST_VERTEX(%ebp)
	// lastdist = dot(last.position, plane.normal) - plane.dist.
	flds	(%edi)
	fmuls	(%edx)
	flds	4(%edi)
	fmuls	4(%edx)
	faddp	%st(0),%st(1)
	fsubs	RPX_CLIP_DIST(%edx)
	flds	8(%edi)
	fmuls	8(%edx)
	faddp	%st(0),%st(1)
	fstpt	RPX_LASTDIST(%ebp)

	movl	RPX_CURRPAGE(%ebp),%eax
	xorl	$1,%eax
	movl	%eax,RPX_NEWPAGE(%ebp)
	imull	$RPX_VERTEX_PAGE_SIZE,%eax,%eax
	leal	RPX_VERTS(%ebp,%eax),%eax
	movl	%eax,RPX_DST(%ebp)
	movl	RPX_VERTBASE(%ebp),%eax
	movl	%eax,RPX_SRC(%ebp)
	movl	$0,RPX_NEWVERTS(%ebp)
	movl	$0,RPX_VISIBLE(%ebp)
	movl	$0,RPX_I(%ebp)
.Lrpx_clip_vertex:
	movl	RPX_I(%ebp),%eax
	cmpl	RPX_LNUMVERTS(%ebp),%eax
	jge	.Lrpx_clip_plane_done
	movl	RPX_SRC(%ebp),%esi
	movl	RPX_PCLIP(%ebp),%edx
	// dist = dot(current.position, plane.normal) - plane.dist.
	flds	(%esi)
	fmuls	(%edx)
	flds	4(%esi)
	fmuls	4(%edx)
	faddp	%st(0),%st(1)
	fsubs	RPX_CLIP_DIST(%edx)
	flds	8(%esi)
	fmuls	8(%edx)
	faddp	%st(0),%st(1)
	fstpt	RPX_DIST(%ebp)

	// A crossing occurs when the strict-positive side changes.
	fldt	RPX_LASTDIST(%ebp)
	ftst
	fnstsw	%ax
	sahf
	fstp	%st(0)
	seta	%al
	movzbl	%al,%eax
	movl	%eax,RPX_LAST_POSITIVE(%ebp)
	fldt	RPX_DIST(%ebp)
	ftst
	fnstsw	%ax
	sahf
	fstp	%st(0)
	seta	%al
	movzbl	%al,%eax
	movl	%eax,RPX_DIST_POSITIVE(%ebp)
	movl	RPX_LAST_POSITIVE(%ebp),%eax
	cmpl	RPX_DIST_POSITIVE(%ebp),%eax
	je	.Lrpx_test_inside

	// frac = dist / (dist - lastdist), using Quake's fsubr/fdivrp ordering.
	fldt	RPX_DIST(%ebp)
	fldt	RPX_LASTDIST(%ebp)
	fsubr	%st(1),%st(0)
	fdivrp	%st(0),%st(1)
	fstpt	RPX_FRAC(%ebp)
	movl	RPX_LAST_VERTEX(%ebp),%eax
	movl	RPX_DST(%ebp),%edi
	// New intersection position: current + (previous - current) * frac.
	cmpl	$100,RPX_NEWVERTS(%ebp)
	jae	.Lrpx_return
	flds	(%eax)
	fsubs	(%esi)
	fldt	RPX_FRAC(%ebp)
	fmulp	%st(0),%st(1)
	fadds	(%esi)
	fstps	(%edi)
	flds	4(%eax)
	fsubs	4(%esi)
	fldt	RPX_FRAC(%ebp)
	fmulp	%st(0),%st(1)
	fadds	4(%esi)
	fstps	4(%edi)
	flds	8(%eax)
	fsubs	8(%esi)
	fldt	RPX_FRAC(%ebp)
	fmulp	%st(0),%st(1)
	fadds	8(%esi)
	fstps	8(%edi)
	addl	$RPX_MVERTEX_SIZE,RPX_DST(%ebp)
	incl	RPX_NEWVERTS(%ebp)

.Lrpx_test_inside:
	fldt	RPX_DIST(%ebp)
	ftst
	fnstsw	%ax
	sahf
	fstp	%st(0)
	jae	.Lrpx_keep_vertex
	jmp	.Lrpx_clip_advance
.Lrpx_keep_vertex:
	cmpl	$100,RPX_NEWVERTS(%ebp)
	jae	.Lrpx_return
	movl	RPX_SRC(%ebp),%esi
	movl	RPX_DST(%ebp),%edi
	movl	(%esi),%eax
	movl	%eax,(%edi)
	movl	4(%esi),%eax
	movl	%eax,4(%edi)
	movl	8(%esi),%eax
	movl	%eax,8(%edi)
	addl	$RPX_MVERTEX_SIZE,RPX_DST(%ebp)
	incl	RPX_NEWVERTS(%ebp)
	movl	$1,RPX_VISIBLE(%ebp)

.Lrpx_clip_advance:
	movl	RPX_SRC(%ebp),%eax
	movl	%eax,RPX_LAST_VERTEX(%ebp)
	addl	$RPX_MVERTEX_SIZE,RPX_SRC(%ebp)
	fldt	RPX_DIST(%ebp)
	fstpt	RPX_LASTDIST(%ebp)
	incl	RPX_I(%ebp)
	jmp	.Lrpx_clip_vertex

.Lrpx_clip_plane_done:
	cmpl	$0,RPX_VISIBLE(%ebp)
	je	.Lrpx_return
	cmpl	$3,RPX_NEWVERTS(%ebp)
	jl	.Lrpx_return
	movl	RPX_NEWVERTS(%ebp),%eax
	movl	%eax,RPX_LNUMVERTS(%ebp)
	movl	RPX_NEWPAGE(%ebp),%eax
	movl	%eax,RPX_CURRPAGE(%ebp)
	movl	RPX_PCLIP(%ebp),%eax
	movl	RPX_CLIP_NEXT(%eax),%eax
	movl	%eax,RPX_PCLIP(%ebp)
	jmp	.Lrpx_clip_loop
.Lrpx_clipping_done:
	// Resolve the face plane's texture axes; unknown types retain C's 0,0 pair.
	movl	8(%ebp),%eax
	movl	RPX_SURFACE_PLANE(%eax),%edx
	movl	%edx,RPX_PPLANE(%ebp)
	movzbl	16(%edx),%ecx
	movl	$0,RPX_SAXIS(%ebp)
	movl	$0,RPX_TAXIS(%ebp)
	cmpl	$0,%ecx
	je	.Lrpx_axis_x
	cmpl	$3,%ecx
	je	.Lrpx_axis_x
	cmpl	$1,%ecx
	je	.Lrpx_axis_y
	cmpl	$4,%ecx
	je	.Lrpx_axis_y
	cmpl	$2,%ecx
	je	.Lrpx_axis_z
	cmpl	$5,%ecx
	jne	.Lrpx_axes_done
.Lrpx_axis_z:
	movl	$1,RPX_TAXIS(%ebp)
	jmp	.Lrpx_axes_done
.Lrpx_axis_y:
	movl	$2,RPX_TAXIS(%ebp)
	jmp	.Lrpx_axes_done
.Lrpx_axis_x:
	movl	$1,RPX_SAXIS(%ebp)
	movl	$2,RPX_TAXIS(%ebp)
.Lrpx_axes_done:
	movl	$0,C(r_nearzi)
	movl	RPX_CURRPAGE(%ebp),%eax
	imull	$RPX_VERTEX_PAGE_SIZE,%eax,%eax
	leal	RPX_VERTS(%ebp,%eax),%eax
	movl	%eax,RPX_SRC(%ebp)
	leal	RPX_PVERTS(%ebp),%eax
	movl	%eax,RPX_PVERT_PTR(%ebp)
	movl	$0,RPX_I(%ebp)
.Lrpx_project_vertex:
	movl	RPX_I(%ebp),%eax
	cmpl	RPX_LNUMVERTS(%ebp),%eax
	jge	.Lrpx_project_done
	movl	RPX_SRC(%ebp),%esi
	flds	(%esi)
	fsubs	C(modelorg)
	fstps	RPX_LOCAL(%ebp)
	flds	4(%esi)
	fsubs	C(modelorg)+4
	fstps	RPX_LOCAL+4(%ebp)
	flds	8(%esi)
	fsubs	C(modelorg)+8
	fstps	RPX_LOCAL+8(%ebp)
	leal	RPX_TRANSFORMED(%ebp),%eax
	pushl	%eax
	leal	RPX_LOCAL(%ebp),%eax
	pushl	%eax
	call	C(TransformVector)
	addl	$8,%esp

	// C compares transformed z with the double literal and stores float 0.01.
	flds	RPX_TRANSFORMED+8(%ebp)
	fcompl	.Lrpx_near_clip_double
	fnstsw	%ax
	testb	$1,%ah
	je	.Lrpx_near_clip_not_applied
	movl	.Lrpx_near_clip_float,%eax
	movl	%eax,RPX_TRANSFORMED+8(%ebp)
	// GCC folds the clamped 1.0 / 0.01f path to the exact float 100.0f.
	flds	.Lrpx_near_clip_reciprocal
	fstpt	RPX_LZI(%ebp)
	jmp	.Lrpx_lzi_ready
.Lrpx_near_clip_not_applied:
	// Match GCC's C-reference reverse divide: float 1.0 / transformed z.
	flds	RPX_TRANSFORMED+8(%ebp)
	fdivrs	.Lrpx_reciprocal_numerator
	fstpt	RPX_LZI(%ebp)
.Lrpx_lzi_ready:
	fldt	RPX_LZI(%ebp)
	fcoms	C(r_nearzi)
	fnstsw	%ax
	sahf
	fstp	%st(0)
	jbe	.Lrpx_nearzi_done
	fldt	RPX_LZI(%ebp)
	fstps	C(r_nearzi)
.Lrpx_nearzi_done:

	movl	RPX_PVERT_PTR(%ebp),%edi
	// u = xcenter + xscale * lzi * transformed.x, clamped to the adjusted rect.
	fldt	RPX_LZI(%ebp)
	flds	C(xscale)
	fmuls	RPX_TRANSFORMED(%ebp)
	fmulp	%st(0),%st(1)
	fadds	C(xcenter)
	fld		%st(0)
	fcomps	C(r_refdef)+68
	fnstsw	%ax
	sahf
	jb	.Lrpx_u_low
	fld		%st(0)
	fcomps	C(r_refdef)+84
	fnstsw	%ax
	sahf
	ja	.Lrpx_u_high
	jmp	.Lrpx_u_store
.Lrpx_u_low:
	fstp	%st(0)
	flds	C(r_refdef)+68
	jmp	.Lrpx_u_store
.Lrpx_u_high:
	fstp	%st(0)
	flds	C(r_refdef)+84
.Lrpx_u_store:
	fstps	(%edi)

	// v = ycenter - yscale * lzi * transformed.y, clamped to the adjusted rect.
	fldt	RPX_LZI(%ebp)
	flds	C(yscale)
	fmuls	RPX_TRANSFORMED+4(%ebp)
	fmulp	%st(0),%st(1)
	fsubrs	C(ycenter)
	fld		%st(0)
	fcomps	C(r_refdef)+72
	fnstsw	%ax
	sahf
	jb	.Lrpx_v_low
	fld		%st(0)
	fcomps	C(r_refdef)+88
	fnstsw	%ax
	sahf
	ja	.Lrpx_v_high
	jmp	.Lrpx_v_store
.Lrpx_v_low:
	fstp	%st(0)
	flds	C(r_refdef)+72
	jmp	.Lrpx_v_store
.Lrpx_v_high:
	fstp	%st(0)
	flds	C(r_refdef)+88
.Lrpx_v_store:
	fstps	4(%edi)
	fldt	RPX_LZI(%ebp)
	fstps	8(%edi)
	movl	RPX_SAXIS(%ebp),%eax
	movl	(%esi,%eax,4),%edx
	movl	%edx,12(%edi)
	movl	RPX_TAXIS(%ebp),%eax
	movl	(%esi,%eax,4),%edx
	movl	%edx,16(%edi)
	addl	$RPX_MVERTEX_SIZE,RPX_SRC(%ebp)
	addl	$RPX_POLYVERT_SIZE,RPX_PVERT_PTR(%ebp)
	incl	RPX_I(%ebp)
	jmp	.Lrpx_project_vertex
.Lrpx_project_done:
	movl	RPX_LNUMVERTS(%ebp),%eax
	movl	%eax,C(r_polydesc)
	movl	C(r_nearzi),%eax
	movl	%eax,C(r_polydesc)+4
	movl	8(%ebp),%eax
	movl	%eax,C(r_polydesc)+8
	leal	RPX_PVERTS(%ebp),%eax
	movl	%eax,C(r_polydesc)+12
	call	C(D_DrawPoly)

.Lrpx_return:
	leal	-(RPX_STACK_BYTES+12)(%ebp),%esp
	popl	%edi
	popl	%esi
	popl	%ebx
	movl	%ebp,%esp
	popl	%ebp
	ret
#endif

#ifdef ASM486_EFRAG_STORE
	.extern C(Sys_Error)
	.extern C(cl_numvisedicts)
	.extern C(cl_visedicts)
	.extern C(r_framecount)

	.equ EF_LEAFNEXT, 4
	.equ EF_ENTITY, 8
	.equ ENTITY_MODEL, 132
	.equ ENTITY_VISFRAME, 160
	.equ MODEL_TYPE, 68
	.equ MAX_VISEDICTS, 256

	.section .rodata
.Lefrag_store_bad_type:
	.asciz "R_StoreEfrags: Bad entity type %d\n"

	.text
	.globl C(R_StoreEfrags_asm486)
C(R_StoreEfrags_asm486):
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	movl	8(%ebp),%esi			/* efrag_t **ppefrag */

.Lefrag_store_loop:
	movl	(%esi),%ebx			/* pefrag = *ppefrag */
	testl	%ebx,%ebx
	je	.Lefrag_store_done
	movl	EF_ENTITY(%ebx),%edi		/* pent = pefrag->entity */
	movl	ENTITY_MODEL(%edi),%eax	/* clmodel = pent->model */
	movl	MODEL_TYPE(%eax),%edx
	cmpl	$2,%edx				/* mod_brush, mod_sprite, mod_alias */
	ja	.Lefrag_store_bad

	movl	ENTITY_VISFRAME(%edi),%eax
	cmpl	C(r_framecount),%eax
	je	.Lefrag_store_next
	movl	C(cl_numvisedicts),%eax
	cmpl	$MAX_VISEDICTS,%eax
	jge	.Lefrag_store_next
	movl	%edi,C(cl_visedicts)(,%eax,4)
	incl	C(cl_numvisedicts)
	movl	C(r_framecount),%eax
	movl	%eax,ENTITY_VISFRAME(%edi)

.Lefrag_store_next:
	leal	EF_LEAFNEXT(%ebx),%esi		/* ppefrag = &pefrag->leafnext */
	jmp	.Lefrag_store_loop

.Lefrag_store_bad:
	pushl	%edx
	pushl	$.Lefrag_store_bad_type
	call	C(Sys_Error)
	addl	$8,%esp
	/* Sys_Error does not return. Preserve the C reference's bad-list behavior
	 * if a test stub does return: retry the same invalid efrag. */
	jmp	.Lefrag_store_loop

.Lefrag_store_done:
	leal	-12(%ebp),%esp
	popl	%edi
	popl	%esi
	popl	%ebx
	popl	%ebp
	ret
#endif

