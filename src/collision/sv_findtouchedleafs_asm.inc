/* i486 translation of the recursive BSP entity-to-leaf traversal. */
/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
#include "collision/asm_findtouchedleafs.h"

	.text
	.extern C(sv)
	.extern C(BoxOnPlaneSide)
	.globl C(SV_FindTouchedLeafs)
C(SV_FindTouchedLeafs):
	#if defined(BENCH486) && defined(ASM486_FIND_TOUCHED_LEAFS)
	incl C(bench486_findtouchedleafs_asm_calls)
	#endif
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	movl	8(%ebp),%ebx		/* edict */
	movl	12(%ebp),%esi		/* BSP node or leaf */

	movl	FTL_NODE_CONTENTS(%esi),%eax
	cmpl	$FTL_CONTENTS_SOLID,%eax
	je	.Lftl_return
	testl	%eax,%eax
	js	.Lftl_leaf

	movl	FTL_NODE_PLANE(%esi),%edx
	movzbl	FTL_PLANE_TYPE(%edx),%ecx
	cmpl	$3,%ecx
	jae	.Lftl_nonaxial

	/* Match BOX_ON_PLANE_SIDE's inclusive axial bounds, including NaNs. */
	flds	FTL_PLANE_DIST(%edx)
	fcomps	FTL_EDICT_ABSMIN(%ebx,%ecx,4)
	fnstsw	%ax
	sahf
	jp	.Lftl_check_back
	jbe	.Lftl_child0_only

.Lftl_check_back:
	flds	FTL_PLANE_DIST(%edx)
	fcomps	FTL_EDICT_ABSMAX(%ebx,%ecx,4)
	fnstsw	%ax
	sahf
	jp	.Lftl_both_children
	jae	.Lftl_child1_only
	jmp	.Lftl_both_children

.Lftl_nonaxial:
	leal	FTL_EDICT_ABSMAX(%ebx),%eax
	pushl	%edx
	pushl	%eax
	leal	FTL_EDICT_ABSMIN(%ebx),%eax
	pushl	%eax
	call	C(BoxOnPlaneSide)
	addl	$12,%esp
	movl	%eax,%edi
	testl	$1,%edi
	jnz	.Lftl_child0
	testl	$2,%edi
	jnz	.Lftl_child1
	jmp	.Lftl_return

.Lftl_child0_only:
	movl	$1,%edi
	jmp	.Lftl_child0

.Lftl_child1_only:
	movl	$2,%edi
	jmp	.Lftl_child1

.Lftl_both_children:
	movl	$3,%edi

.Lftl_child0:
	testl	$1,%edi
	jz	.Lftl_test_child1
	movl	FTL_NODE_CHILDREN+0(%esi),%eax
	pushl	%eax
	pushl	%ebx
	call	C(SV_FindTouchedLeafs)
	addl	$8,%esp

.Lftl_test_child1:
	testl	$2,%edi
	jz	.Lftl_return
.Lftl_child1:
	movl	FTL_NODE_CHILDREN+4(%esi),%eax
	pushl	%eax
	pushl	%ebx
	call	C(SV_FindTouchedLeafs)
	addl	$8,%esp
	jmp	.Lftl_return

.Lftl_leaf:
	cmpl	$FTL_MAX_LEAFS,FTL_EDICT_NUM_LEAFS(%ebx)
	je	.Lftl_return
	movl	C(sv)+FTL_SERVER_WORLDMODEL,%eax
	movl	FTL_MODEL_LEAFS(%eax),%eax
	movl	%esi,%edx
	subl	%eax,%edx			/* byte distance from model leaf zero */
	movl	%edx,%eax
	shrl	$4,%eax			/* leaf size is 48 bytes; reduce to 3*n */
	movl	$0xaaaaaaab,%ecx		/* floor(x / 3) = high(x * 0xaaaaaaab) >> 1 */
	mull	%ecx
	shrl	$1,%edx
	movl	%edx,%eax
	decl	%eax				/* Quake excludes the solid leaf zero */
	movl	FTL_EDICT_NUM_LEAFS(%ebx),%ecx
	movw	%ax,FTL_EDICT_LEAFNUMS(%ebx,%ecx,2)
	incl	FTL_EDICT_NUM_LEAFS(%ebx)

.Lftl_return:
	popl	%edi
	popl	%esi
	popl	%ebx
	leave
	ret
