	.file	"s_rint.c"
	.section .text
	.p2align 4,,15
	.globl	_rint
_rint:
LFB0:
	.cfi_startproc
	pushl	%edi
	.cfi_def_cfa_offset 8
	.cfi_offset 7, -8
	pushl	%esi
	.cfi_def_cfa_offset 12
	.cfi_offset 6, -12
	pushl	%ebx
	.cfi_def_cfa_offset 16
	.cfi_offset 3, -16
	subl	$32, %esp
	.cfi_def_cfa_offset 48
	fldl	48(%esp)
	fstl	(%esp)
	movl	4(%esp), %edx
	movl	(%esp), %eax
	movl	%edx, %ebx
	movl	%edx, %esi
	sarl	$20, %ebx
	shrl	$31, %esi
	andl	$2047, %ebx
	leal	-1023(%ebx), %ecx
	cmpl	$19, %ecx
	jg	L2
	testl	%ecx, %ecx
	js	L23
	movl	$1048575, %ebx
	sarl	%cl, %ebx
	movl	%ebx, %edi
	andl	%edx, %edi
	orl	%eax, %edi
	je	L4
	fstp	%st(0)
	shrl	%ebx
	movl	%ebx, %edi
	andl	%edx, %edi
	orl	%eax, %edi
	je	L7
	cmpl	$19, %ecx
	je	L8
	xorl	$-1, %ebx
	andl	%ebx, %edx
	movl	$131072, %ebx
	sarl	%cl, %ebx
	orl	%ebx, %edx
	jmp	L5
	.p2align 4,,7
L2:
	cmpl	$51, %ecx
	jle	L6
	cmpl	$1024, %ecx
	je	L24
L4:
	addl	$32, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 16
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 12
	popl	%esi
	.cfi_restore 6
	.cfi_def_cfa_offset 8
	popl	%edi
	.cfi_restore 7
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L6:
	.cfi_restore_state
	orl	$-1, %edi
	leal	-1043(%ebx), %ecx
	shrl	%cl, %edi
	testl	%eax, %edi
	je	L4
	fstp	%st(0)
	shrl	%edi
	testl	%eax, %edi
	je	L5
	xorl	$-1, %edi
	movl	$1073741824, %ebx
	andl	%edi, %eax
	sarl	%cl, %ebx
	orl	%ebx, %eax
L5:
	fldl	_TWO52(,%esi,8)
	movl	%eax, 8(%esp)
	movl	%edx, 12(%esp)
	fldl	8(%esp)
	fadd	%st(1), %st
	fstpl	24(%esp)
	fldl	24(%esp)
	fsubp	%st, %st(1)
	addl	$32, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 16
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 12
	popl	%esi
	.cfi_restore 6
	.cfi_def_cfa_offset 8
	popl	%edi
	.cfi_restore 7
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L23:
	.cfi_restore_state
	movl	%edx, %ecx
	andl	$2147483647, %ecx
	orl	%eax, %ecx
	je	L4
	fstp	%st(0)
	movl	%edx, %edi
	andl	$-131072, %edx
	andl	$1048575, %edi
	movl	(%esp), %ecx
	orl	%eax, %edi
	movl	%ecx, 8(%esp)
	movl	%edi, %eax
	negl	%eax
	orl	%edi, %eax
	shrl	$12, %eax
	andl	$524288, %eax
	movl	%eax, %ebx
	orl	%edx, %ebx
	movl	%ebx, 12(%esp)
	fldl	_TWO52(,%esi,8)
	faddl	8(%esp)
	fstpl	24(%esp)
	fldl	24(%esp)
	fsubl	_TWO52(,%esi,8)
	sall	$31, %esi
	fstpl	8(%esp)
	movl	12(%esp), %edx
	movl	8(%esp), %eax
	movl	%edx, %ecx
	movl	%esi, %edx
	andl	$2147483647, %ecx
	movl	%eax, (%esp)
	orl	%ecx, %edx
	movl	%edx, 4(%esp)
	fldl	(%esp)
	jmp	L4
	.p2align 4,,7
L7:
	xorl	%eax, %eax
	jmp	L5
	.p2align 4,,7
L24:
	fadd	%st(0), %st
	jmp	L4
	.p2align 4,,7
L8:
	movl	$1073741824, %eax
	jmp	L5
	.cfi_endproc
LFE0:
	.p2align 4
_TWO52:
	.long	0
	.long	1127219200
	.long	0
	.long	-1020264448
	.ident	"GCC: (GNU) 4.7.4"
