/*
 * Assembly equivalent of src/renderer/r_draw.c:R_ZDrawSubmodelPolys.
 *
 * Preserve the original x87 evaluation order and status-word tests.  The
 * production entry always calls R_RenderPoly directly.  BENCH486 also exports
 * a separate observation entry for the direct C/ASM fixture; its callback path
 * cannot affect a timedemo or release render.
 *
 * cdecl: model_t * at 4(%esp); EBX/ESI/EDI are preserved.  All instructions are
 * baseline i486 integer or 387 instructions.
 */
/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
#include "asm_i386.h"
#include "renderer/asm_zsubmodel.h"
#undef i386
.arch i386
.arch .387
.code32

#ifdef ASM486_DRAW_Z_SUBMODEL_POLYS
.extern C(modelorg)
.extern C(R_RenderPoly)
#ifdef BENCH486
.extern C(bench486_zsubmodel_render_hook)
#endif

.text

.macro ZSUBMODEL_BODY name, use_hook
.p2align 2
.globl \name
\name:
	pushl	%edi
	pushl	%esi
	pushl	%ebx
	movl	16(%esp),%eax
	movl	ZSP_MODEL_FIRSTSURFACE(%eax),%ebx
	sall	$6,%ebx
	addl	ZSP_MODEL_SURFACES(%eax),%ebx
	movl	ZSP_MODEL_NUMSURFACES(%eax),%edi
	testl	%edi,%edi
	jle	.Lzsubmodel_done\@
	xorl	%esi,%esi
	jmp	.Lzsubmodel_loop\@

.Lzsubmodel_loop\@:
	movl	ZSP_SURFACE_PLANE(%ebx),%edx
	/* DotProduct(modelorg, plane->normal), in the C compiler's x87 order. */
	flds	C(modelorg)
	fmuls	ZSP_PLANE_NORMAL(%edx)
	flds	C(modelorg)+4
	fmuls	ZSP_PLANE_NORMAL+4(%edx)
	faddp	%st,%st(1)
	flds	C(modelorg)+8
	fmuls	ZSP_PLANE_NORMAL+8(%edx)
	faddp	%st,%st(1)
	fsubs	ZSP_PLANE_DIST(%edx)

	testb	$2,ZSP_SURFACE_FLAGS(%ebx)
	je	.Lzsubmodel_front_face\@
	/* Original C: dot < -BACKFACE_EPSILON. */
	fcompl	.Lzsubmodel_negative_epsilon
	fnstsw	%ax
	testb	$1,%ah
	je	.Lzsubmodel_advance\@
	jmp	.Lzsubmodel_draw\@

.Lzsubmodel_front_face\@:
	/* Original C: dot > BACKFACE_EPSILON; C0/C2/C3 mean skip. */
	fcompl	.Lzsubmodel_positive_epsilon
	fnstsw	%ax
	testb	$69,%ah
	jne	.Lzsubmodel_advance\@

.Lzsubmodel_draw\@:
	.if \use_hook
		movl	C(bench486_zsubmodel_render_hook),%ecx
		testl	%ecx,%ecx
		je	.Lzsubmodel_real_render\@
		/* Match the C oracle's outgoing-call alignment in the test fixture. */
		subl	$8,%esp
		pushl	$15
		pushl	%ebx
		call	*%ecx
		addl	$16,%esp
		jmp	.Lzsubmodel_advance\@
.Lzsubmodel_real_render\@:
	.endif
	/* Same outgoing stack layout used by the reference C function. */
	subl	$8,%esp
	pushl	$15
	pushl	%ebx
	call	C(R_RenderPoly)
	addl	$16,%esp

.Lzsubmodel_advance\@:
	incl	%esi
	addl	$ZSP_SURFACE_SIZE,%ebx
	cmpl	%esi,%edi
	je	.Lzsubmodel_done\@
	jmp	.Lzsubmodel_loop\@

.Lzsubmodel_done\@:
	popl	%ebx
	popl	%esi
	popl	%edi
	ret
.endm

ZSUBMODEL_BODY C(R_ZDrawSubmodelPolys_asm486), 0
#ifdef BENCH486
ZSUBMODEL_BODY C(R_ZDrawSubmodelPolys_asm486_test), 1
#endif

.section .rodata
.p2align 3
.Lzsubmodel_negative_epsilon:
	.double -0.01
.Lzsubmodel_positive_epsilon:
	.double 0.01
#endif /* ASM486_DRAW_Z_SUBMODEL_POLYS */
