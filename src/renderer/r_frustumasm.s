/*
 * i486 translation of r_misc.c:R_TransformFrustum.
 *
 * The public entry passes the original renderer globals to a small cdecl core.
 * Keeping the core pointer-based lets the BENCH486 fixture surround all six
 * arrays with guards. The per-component x87 sequence follows the C expression
 * left to right: right term, add up term, then add forward term. Each result is
 * rounded to float at the same VectorCopy boundary before the origin dot
 * product is evaluated.
 *
 * Core arguments (cdecl): screen planes, output clip planes, model origin,
 * forward vector, right vector, up vector. EBX/ESI/EDI/EBP and ESP are
 * preserved. x87 starts and ends empty; its control word is never changed.
 */
/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
#include "asm_i386.h"
#include "renderer/asm_frustum.h"
#undef i486
.arch i486
.arch .387
.code32

#ifdef ASM486_TRANSFORM_FRUSTUM
.text
.p2align 2
.globl C(R_TransformFrustum)
C(R_TransformFrustum):
	/* Push six original globals in reverse cdecl order. */
	pushl	$C(vup)
	pushl	$C(vright)
	pushl	$C(vpn)
	pushl	$C(modelorg)
	pushl	$C(view_clipplanes)
	pushl	$C(screenedge)
	call	C(R_TransformFrustumCore_asm486)
	addl	$24,%esp
	/* Keep a private, stable all-four-plane chain for RenderFace. */
	pushl	%esi
	pushl	%edi
	movl	$C(view_clipplanes),%esi
	movl	$C(view_clipplanes_fullmask),%edi
	movl	$24,%ecx
	cld
	rep movsl
	popl	%edi
	popl	%esi
	movl	$0,C(view_clipplanes_fullmask)+88
	movl	$C(view_clipplanes_fullmask)+72,C(view_clipplanes_fullmask)+64
	movl	$C(view_clipplanes_fullmask)+48,C(view_clipplanes_fullmask)+40
	movl	$C(view_clipplanes_fullmask)+24,C(view_clipplanes_fullmask)+16
	ret

.p2align 2
.globl C(R_TransformFrustumCore_asm486)
C(R_TransformFrustumCore_asm486):
	/*
	 * This schedule preserves the source compiler's x87 evaluation order and
	 * extended intermediates. In particular, FSTS writes each normal to the
	 * public clip plane without popping its 80-bit value; the distance dot
	 * product consumes those retained values. The next plane's offsets account
	 * for the 20-byte mplane_t and 24-byte clipplane_t strides.
	 */
	pushl	%edi
	pushl	%esi
	pushl	%ebx
	movl	16(%esp),%edi		/* screen planes */
	movl	20(%esp),%eax		/* output clip planes */
	movl	24(%esp),%edx		/* model origin */
	movl	28(%esp),%ebx		/* forward vector */
	movl	32(%esp),%ecx		/* right vector */
	movl	36(%esp),%esi		/* up vector */

	/* Plane 0: v=(normal.z,-normal.x,normal.y), then transformed x/y/z. */
	flds	8(%edi)
	flds	(%edi)
	fchs
	flds	4(%edi)
	flds	(%ebx)
	fmul	%st(3),%st
	flds	(%esi)
	fmul	%st(2),%st
	faddp	%st,%st(1)
	flds	(%ecx)
	fmul	%st(3),%st
	faddp	%st,%st(1)
	flds	4(%ebx)
	fmul	%st(4),%st
	flds	4(%esi)
	fmul	%st(3),%st
	faddp	%st,%st(1)
	flds	4(%ecx)
	fmul	%st(4),%st
	faddp	%st,%st(1)
	fxch	%st(4)
	fmuls	8(%ebx)
	fxch	%st(2)
	fmuls	8(%esi)
	faddp	%st,%st(2)
	fxch	%st(2)
	fmuls	8(%ecx)
	faddp	%st,%st(1)
	fxch	%st(1)
	fsts	(%eax)
	fxch	%st(2)
	fsts	4(%eax)
	fxch	%st(1)
	fsts	8(%eax)
	fxch	%st(1)
	fmuls	4(%edx)
	fxch	%st(2)
	fmuls	(%edx)
	faddp	%st,%st(2)
	fmuls	8(%edx)
	faddp	%st,%st(1)
	fstps	12(%eax)

	/* Plane 1 (screen +20, clip +24); keep the same live x87 temporaries. */
	flds	28(%edi)
	flds	20(%edi)
	fchs
	flds	24(%edi)
	flds	(%esi)
	fmul	%st(1),%st
	flds	(%ebx)
	fmul	%st(4),%st
	faddp	%st,%st(1)
	flds	(%ecx)
	fmul	%st(3),%st
	faddp	%st,%st(1)
	flds	4(%esi)
	fmul	%st(2),%st
	flds	4(%ebx)
	fmul	%st(5),%st
	faddp	%st,%st(1)
	flds	4(%ecx)
	fmul	%st(4),%st
	faddp	%st,%st(1)
	fxch	%st(2)
	fmuls	8(%esi)
	fxch	%st(4)
	fmuls	8(%ebx)
	faddp	%st,%st(4)
	fxch	%st(2)
	fmuls	8(%ecx)
	faddp	%st,%st(3)
	fxch	%st(1)
	fsts	24(%eax)
	fxch	%st(1)
	fsts	28(%eax)
	fxch	%st(2)
	fsts	32(%eax)
	fxch	%st(1)
	fmuls	(%edx)
	fxch	%st(2)
	fmuls	4(%edx)
	faddp	%st,%st(2)
	fmuls	8(%edx)
	faddp	%st,%st(1)
	fstps	36(%eax)

	/* Plane 2 (screen +40, clip +48). */
	flds	48(%edi)
	flds	40(%edi)
	fchs
	flds	44(%edi)
	flds	(%esi)
	fmul	%st(1),%st
	flds	(%ebx)
	fmul	%st(4),%st
	faddp	%st,%st(1)
	flds	(%ecx)
	fmul	%st(3),%st
	faddp	%st,%st(1)
	flds	4(%esi)
	fmul	%st(2),%st
	flds	4(%ebx)
	fmul	%st(5),%st
	faddp	%st,%st(1)
	flds	4(%ecx)
	fmul	%st(4),%st
	faddp	%st,%st(1)
	fxch	%st(2)
	fmuls	8(%esi)
	fxch	%st(4)
	fmuls	8(%ebx)
	faddp	%st,%st(4)
	fxch	%st(2)
	fmuls	8(%ecx)
	faddp	%st,%st(3)
	fxch	%st(1)
	fsts	48(%eax)
	fxch	%st(1)
	fsts	52(%eax)
	fxch	%st(2)
	fsts	56(%eax)
	fxch	%st(1)
	fmuls	(%edx)
	fxch	%st(2)
	fmuls	4(%edx)
	faddp	%st,%st(2)
	fmuls	8(%edx)
	faddp	%st,%st(1)
	fstps	60(%eax)

	/* Plane 3 (screen +60, clip +72). */
	flds	68(%edi)
	flds	60(%edi)
	fchs
	flds	64(%edi)
	flds	(%esi)
	fmul	%st(1),%st
	flds	(%ebx)
	fmul	%st(4),%st
	faddp	%st,%st(1)
	flds	(%ecx)
	fmul	%st(3),%st
	faddp	%st,%st(1)
	flds	4(%esi)
	fmul	%st(2),%st
	flds	4(%ebx)
	fmul	%st(5),%st
	faddp	%st,%st(1)
	flds	4(%ecx)
	fmul	%st(4),%st
	faddp	%st,%st(1)
	fxch	%st(2)
	fmuls	8(%esi)
	fxch	%st(4)
	fmuls	8(%ebx)
	faddp	%st,%st(4)
	fxch	%st(2)
	fmuls	8(%ecx)
	faddp	%st,%st(3)
	fxch	%st(1)
	fsts	72(%eax)
	fxch	%st(1)
	fsts	76(%eax)
	fxch	%st(2)
	fsts	80(%eax)
	fxch	%st(1)
	fmuls	(%edx)
	fxch	%st(2)
	fmuls	4(%edx)
	faddp	%st,%st(2)
	fmuls	8(%edx)
	faddp	%st,%st(1)
	fstps	84(%eax)
	popl	%ebx
	popl	%esi
	popl	%edi
	ret

/*
 * R_SetUpFrustumIndexes: choose the AABB reject/accept corners for each
 * transformed clip plane.  Match the C compiler's fldz/fcomps ordering so
 * both the ordered decision and final x87 condition bits match the reference
 * (negative zero and NaN are not less than zero).  FCOMPS pops its zero
 * temporary; the routine uses only 486/387 instructions and preserves the
 * i386 callee-saved registers.
 */
#ifdef ASM486_TRANSFORM_FRUSTUM
.p2align 2
.globl C(R_SetUpFrustumIndexes)
C(R_SetUpFrustumIndexes):
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	movl	$C(view_clipplanes),%esi
	movl	$C(r_frustum_indexes),%edi
	movl	$C(pfrustum_indexes),%edx
	movl	$FR_INDEX_PLANES,%ecx
.Lfr_index_plane:
	movl	%edi,(%edx)
	addl	$4,%edx
	xorl	%ebx,%ebx
.Lfr_index_axis:
	fldz
	fcomps	FR_CLIP_NORMAL_X(%esi,%ebx,4)
	fnstsw	%ax
	sahf
	jp	.Lfr_index_nonnegative
	ja	.Lfr_index_negative
.Lfr_index_nonnegative:
	leal	FR_INDEX_HALF(%ebx),%eax
	movl	%eax,(%edi,%ebx,4)
	movl	%ebx,FR_INDEX_HALF_OFFSET(%edi,%ebx,4)
	jmp	.Lfr_index_axis_next
.Lfr_index_negative:
	movl	%ebx,(%edi,%ebx,4)
	leal	FR_INDEX_HALF(%ebx),%eax
	movl	%eax,FR_INDEX_HALF_OFFSET(%edi,%ebx,4)
.Lfr_index_axis_next:
	incl	%ebx
	cmpl	$FR_INDEX_AXES,%ebx
	jne	.Lfr_index_axis
	addl	$FR_CLIP_STRIDE,%esi
	addl	$FR_INDEX_STRIDE,%edi
	decl	%ecx
	jne	.Lfr_index_plane
	popl	%edi
	popl	%esi
	popl	%ebx
	ret
#endif

#endif /* ASM486_TRANSFORM_FRUSTUM */
