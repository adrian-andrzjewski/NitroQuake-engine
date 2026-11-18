/*
 * R_TransformPlane: translate a world plane into view space.
 *
 * The source C order is preserved: left-associated r_origin dot plane.normal,
 * a single-precision local `d`, plane.dist - d, then TransformVector. The
 * shared TransformVector entry is the existing 32-bit x87 implementation in
 * math.s, which keeps its view-axis product and accumulation schedule intact.
 */
/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
#include "asm_i386.h"
#include "quakeasm.h"

#if id386 && (defined(ASM486_TRANSFORM_PLANE) || defined(BENCH486))

	.arch i486
	.arch .387
	.code32

	.set tp_plane_normal, 0
	.set tp_plane_dist, 12

	.extern C(r_origin)
	.extern C(TransformVector)

	.text
	.p2align 4,,15
	.globl C(R_TransformPlane_asm486)
#ifdef ASM486_TRANSFORM_PLANE
	.globl C(R_TransformPlane)
#endif
C(R_TransformPlane_asm486):
#ifdef ASM486_TRANSFORM_PLANE
C(R_TransformPlane):
#endif
	/* cdecl: plane, output normal, output distance. Only EBP is saved. */
	pushl	%ebp
	movl	%esp,%ebp
	subl	$4,%esp			/* local float d */
	movl	8(%ebp),%eax		/* plane */

	/* d = DotProduct(r_origin, p->normal), in source left-to-right order. */
	flds	C(r_origin)
	fmuls	tp_plane_normal(%eax)
	flds	C(r_origin)+4
	fmuls	tp_plane_normal+4(%eax)
	faddp	%st(0),%st(1)
	flds	C(r_origin)+8
	fmuls	tp_plane_normal+8(%eax)
	faddp	%st(0),%st(1)
	fstps	-4(%ebp)

	/* *dist = p->dist - d; store before the TransformVector call, as in C. */
	flds	tp_plane_dist(%eax)
	fsubs	-4(%ebp)
	movl	16(%ebp),%edx
	fstps	(%edx)

	/* TransformVector(p->normal, normal). The helper preserves the original
	 * three output dot-product schedules and consumes the usual cdecl args. */
	pushl	12(%ebp)
	pushl	8(%ebp)
	call	C(TransformVector)
	addl	$8,%esp

	movl	%ebp,%esp
	popl	%ebp
	ret

#endif
