/* i486/387 translation of SV_ClipMoveToEntity for QuakeWorld/DOS. */
/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
	.text
	.extern C(SV_HullForEntity)
	#ifdef ASM486_HULLCHECK
	.extern C(SV_RecursiveHullCheck_asm486)
	#else
	.extern C(SV_RecursiveHullCheck)
	#endif
	.globl C(SV_ClipMoveToEntity)
C(SV_ClipMoveToEntity):
	#if defined(BENCH486) && defined(ASM486_CLIP_MOVE_TO_ENTITY)
	incl C(bench486_clipmovetoentity_asm_calls)
	#endif
	/* GCC i386 returns this 52-byte struct through a hidden pointer at 4(%esp).
	   The callee removes that pointer with ret $4. */
	pushl	%ebp
	pushl	%edi
	pushl	%esi
	pushl	%ebx
	subl	$96, %esp
	movl	120(%esp), %ebx
	movl	124(%esp), %esi
	movl	136(%esp), %ebp
	/* The C default trace is zeroed, then fraction/allsolid/endpos are set. */
	leal	40(%esp), %edi
	xorl	%eax, %eax
	movl	$13, %ecx
	rep	stosl
	leal	40(%esp), %edi
	movl	$1, 0(%edi)
	movl	$0x3f800000, 16(%edi)
	flds	0(%ebp)
	fstps	20(%edi)
	flds	4(%ebp)
	fstps	24(%edi)
	flds	8(%ebp)
	fstps	28(%edi)

	/* hull = SV_HullForEntity(ent, mins, maxs, offset) */
	movl	132(%esp), %edx
	movl	128(%esp), %ecx
	leal	0(%esp), %eax
	pushl	%eax
	pushl	%edx
	pushl	%ecx
	pushl	%ebx
	call	C(SV_HullForEntity)
	addl	$16, %esp
	movl	%eax, 36(%esp)

	/* Translate both endpoints into hull space. */
	flds	0(%esi)
	fsubs	0(%esp)
	fstps	12(%esp)
	flds	4(%esi)
	fsubs	4(%esp)
	fstps	16(%esp)
	flds	8(%esi)
	fsubs	8(%esp)
	fstps	20(%esp)
	flds	0(%ebp)
	fsubs	0(%esp)
	fstps	24(%esp)
	flds	4(%ebp)
	fsubs	4(%esp)
	fstps	28(%esp)
	flds	8(%ebp)
	fsubs	8(%esp)
	fstps	32(%esp)

	/* Preserve the original float argument bits: recursive parameters are 0, 1. */
	movl	36(%esp), %eax
	movl	8(%eax), %edx
	leal	12(%esp), %ecx
	leal	24(%esp), %ebp
	pushl	%edi
	pushl	%ebp
	pushl	%ecx
	pushl	$0x3f800000
	pushl	$0
	pushl	%edx
	pushl	%eax
	#ifdef ASM486_HULLCHECK
	call	C(SV_RecursiveHullCheck_asm486)
	#else
	call	C(SV_RecursiveHullCheck)
	#endif
	addl	$28, %esp

	/* Match the C fractional comparisons and only translate a clipped endpos. */
	fld1
	flds	16(%edi)
	fcompp
	fnstsw	%ax
	testb	$64, %ah
	jne	.Lscm_finish_ent
	flds	20(%edi)
	fadds	0(%esp)
	fstps	20(%edi)
	flds	24(%edi)
	fadds	4(%esp)
	fstps	24(%edi)
	flds	28(%edi)
	fadds	8(%esp)
	fstps	28(%edi)

.Lscm_finish_ent:
	testb	$1, %ah
	jne	.Lscm_set_ent
	cmpl	$0, 4(%edi)
	je	.Lscm_return
.Lscm_set_ent:
	movl	%ebx, 48(%edi)

.Lscm_return:
	movl	116(%esp), %eax
	leal	40(%esp), %esi
	movl	%eax, %edi
	movl	$13, %ecx
	rep	movsl
	addl	$96, %esp
	popl	%ebx
	popl	%esi
	popl	%edi
	popl	%ebp
	ret	$4
