/* i486/387 translation of SV_HullForBox and SV_HullForEntity. */
/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
	.section .rodata
	.p2align 2
.Lhfe_solid_bsp:
	.long 1082130432
.Lhfe_movetype_push:
	.long 1088421888
.Lhfe_three:
	.long 1077936128
.Lhfe_thirty_two:
	.long 1107296256
.Lhfe_solid_error:
	.asciz "SOLID_BSP without MOVETYPE_PUSH"
.Lhfe_model_error:
	.asciz "MOVETYPE_PUSH with a non bsp model"
	.text
	.extern C(box_hull)
	.extern C(box_planes)
	.extern C(sv)
	.extern C(Sys_Error)
	#if defined(BENCH486) && defined(ASM486_HULL_FOR_ENTITY)
	.extern C(bench486_hullforbox_asm_calls)
	.extern C(bench486_hullforentity_asm_calls)
	#endif

	.globl C(SV_HullForBox)
C(SV_HullForBox):
	#if defined(BENCH486) && defined(ASM486_HULL_FOR_ENTITY)
	incl C(bench486_hullforbox_asm_calls)
	#endif
	movl	4(%esp), %eax
	movl	8(%esp), %edx
	flds	(%edx)
	fstps	C(box_planes)+12
	flds	(%eax)
	fstps	C(box_planes)+32
	flds	4(%edx)
	fstps	C(box_planes)+52
	flds	4(%eax)
	fstps	C(box_planes)+72
	flds	8(%edx)
	fstps	C(box_planes)+92
	flds	8(%eax)
	fstps	C(box_planes)+112
	movl	$C(box_hull), %eax
	ret

	.p2align 2
	.globl C(SV_HullForEntity)
C(SV_HullForEntity):
	#if defined(BENCH486) && defined(ASM486_HULL_FOR_ENTITY)
	incl	C(bench486_hullforentity_asm_calls)
	#endif
	pushl	%ebp
	pushl	%edi
	pushl	%esi
	pushl	%ebx
	subl	$28, %esp
	movl	48(%esp), %ebx
	movl	52(%esp), %ebp
	movl	56(%esp), %edx
	movl	60(%esp), %esi
	flds	132(%ebx)
	fcomps	.Lhfe_solid_bsp
	fnstsw	%ax
	testb	$64, %ah
	je	.Lhfe_box_hull
	flds	128(%ebx)
	fcomps	.Lhfe_movetype_push
	fnstsw	%ax
	testb	$64, %ah
	je	.Lhfe_bad_movetype

.Lhfe_model_index:
	flds	96(%ebx)
	fnstcw	14(%esp)
	movw	14(%esp), %cx
	orb	$12, %ch
	movw	%cx, 12(%esp)
	fldcw	12(%esp)
	fistpl	8(%esp)
	fldcw	14(%esp)
	movl	8(%esp), %edi
	movl	C(sv)+1188(,%edi,4), %edi
	testl	%edi, %edi
	je	.Lhfe_bad_model
	movl	68(%edi), %eax
	testl	%eax, %eax
	jne	.Lhfe_bad_model

.Lhfe_model_valid:
	flds	0(%ebp)
	flds	(%edx)
	fsub	%st(1), %st
	fcoms	.Lhfe_three
	fnstsw	%ax
	testb	$1, %ah
	je	.Lhfe_size_at_least_three
	fstp	%st(0)
	leal	208(%edi), %eax
	jmp	.Lhfe_hull_selected

.Lhfe_size_at_least_three:
	fcomps	.Lhfe_thirty_two
	fnstsw	%ax
	testb	$69, %ah
	je	.Lhfe_use_hull_two
	leal	248(%edi), %eax
	jmp	.Lhfe_hull_selected

.Lhfe_use_hull_two:
	leal	288(%edi), %eax

.Lhfe_hull_selected:
	fsubrs	16(%eax)
	fsts	(%esi)
	flds	20(%eax)
	fsubs	4(%ebp)
	fsts	4(%esi)
	flds	24(%eax)
	fsubs	8(%ebp)
	fsts	8(%esi)
	fxch	%st(2)
	fadds	136(%ebx)
	fstps	(%esi)
	fadds	140(%ebx)
	fstps	4(%esi)
	fadds	144(%ebx)
	fstps	8(%esi)
	fstp	%st(0)
	addl	$28, %esp
	popl	%ebx
	popl	%esi
	popl	%edi
	popl	%ebp
	ret

	.p2align 3
.Lhfe_box_hull:
	flds	228(%ebx)
	fsubs	(%edx)
	flds	232(%ebx)
	fsubs	4(%edx)
	flds	236(%ebx)
	fsubs	8(%edx)
	flds	244(%ebx)
	fsubs	4(%ebp)
	flds	248(%ebx)
	fsubs	8(%ebp)
	flds	240(%ebx)
	fsubs	0(%ebp)
	fstps	C(box_planes)+12
	fxch	%st(4)
	fstps	C(box_planes)+32
	fstps	C(box_planes)+52
	fxch	%st(1)
	fstps	C(box_planes)+72
	fxch	%st(1)
	fstps	C(box_planes)+92
	fstps	C(box_planes)+112
	flds	136(%ebx)
	fstps	(%esi)
	flds	140(%ebx)
	fstps	4(%esi)
	flds	144(%ebx)
	movl	$C(box_hull), %eax
	fstps	8(%esi)
	addl	$28, %esp
	popl	%ebx
	popl	%esi
	popl	%edi
	popl	%ebp
	ret

.Lhfe_bad_movetype:
	subl	$12, %esp
	pushl	$.Lhfe_solid_error
	call	C(Sys_Error)
	addl	$16, %esp
	movl	56(%esp), %edx
	jmp	.Lhfe_model_index

.Lhfe_bad_model:
	movl	%edx, 56(%esp)
	subl	$12, %esp
	pushl	$.Lhfe_model_error
	call	C(Sys_Error)
	addl	$16, %esp
	movl	56(%esp), %edx
	jmp	.Lhfe_model_valid
