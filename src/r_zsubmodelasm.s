/*
 * Assembly equivalent of src/r_draw.c:R_ZDrawSubmodelPolys.
 *
 * Preserve the C routine's x87 evaluation order and its two distinct status-word
 * tests.  In particular, the front-face test rejects C0/C2/C3 while the
 * plane-back test tests C0 only; this is the sequence emitted for the retained
 * C oracle by the pinned DJGPP compiler.  asm_zsubmodel.h statically pins every
 * structure offset and stride used below.
 *
 * cdecl: model_t * at 4(%esp); EBX/ESI/EDI are preserved.  All instructions are
 * baseline i486 integer or 387 instructions; the only run-time calls are the
 * original R_RenderPoly entry and a BENCH486-only observation hook.
 */
#include "asm_i386.h"
#include "asm_zsubmodel.h"
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
.p2align 2
.globl C(R_ZDrawSubmodelPolys_asm486)
C(R_ZDrawSubmodelPolys_asm486):
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	movl	16(%esp),%eax
	movl	ZSP_MODEL_FIRSTSURFACE(%eax),%ebx
	sall	$6,%ebx
	addl	ZSP_MODEL_SURFACES(%eax),%ebx
	movl	ZSP_MODEL_NUMSURFACES(%eax),%edi
	testl	%edi,%edi
	jle	.Lzsubmodel_done

.Lzsubmodel_loop:
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
	je	.Lzsubmodel_front_face
	/* Original C: dot < -BACKFACE_EPSILON. */
	fcompl	.Lzsubmodel_negative_epsilon
	fnstsw	%ax
	testb	$1,%ah
	je	.Lzsubmodel_advance
	jmp	.Lzsubmodel_draw

.Lzsubmodel_front_face:
	/* Original C: dot > BACKFACE_EPSILON; C0/C2/C3 mean skip. */
	fcompl	.Lzsubmodel_positive_epsilon
	fnstsw	%ax
	testb	$69,%ah
	jne	.Lzsubmodel_advance

.Lzsubmodel_draw:
#ifdef BENCH486
	movl	C(bench486_zsubmodel_render_hook),%eax
	testl	%eax,%eax
	je	.Lzsubmodel_real_render
	/* Keep the compiler's 16-byte outgoing-call alignment in the BENCH build. */
	subl	$8,%esp
	pushl	$15
	pushl	%ebx
	call	*%eax
	addl	$16,%esp
	jmp	.Lzsubmodel_advance
.Lzsubmodel_real_render:
#endif
	/* Same outgoing stack layout used by the reference C function. */
	subl	$8,%esp
	pushl	$15
	pushl	%ebx
	call	C(R_RenderPoly)
	addl	$16,%esp

.Lzsubmodel_advance:
	addl	$ZSP_SURFACE_SIZE,%ebx
	decl	%edi
	jne	.Lzsubmodel_loop

.Lzsubmodel_done:
	popl	%edi
	popl	%esi
	popl	%ebx
	ret

.section .rodata
.p2align 3
.Lzsubmodel_negative_epsilon:
	.double -0.01
.Lzsubmodel_positive_epsilon:
	.double 0.01
#endif /* ASM486_DRAW_Z_SUBMODEL_POLYS */
