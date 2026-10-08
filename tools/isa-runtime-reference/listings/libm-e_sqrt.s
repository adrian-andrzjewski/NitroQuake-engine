	.file	"e_sqrt.c"
	.section .text
	.p2align 4,,15
	.globl	___ieee754_sqrt
___ieee754_sqrt:
LFB0:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	pushl	%edi
	.cfi_def_cfa_offset 12
	.cfi_offset 7, -12
	pushl	%esi
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	pushl	%ebx
	.cfi_def_cfa_offset 20
	.cfi_offset 3, -20
	subl	$52, %esp
	.cfi_def_cfa_offset 72
	fldl	72(%esp)
	fld	%st(0)
	fstl	(%esp)
	movl	(%esp), %ecx
	movl	4(%esp), %ebx
	movl	%ecx, %edx
	movl	%ebx, %ecx
	andl	$2146435072, %ecx
	movl	%ebx, %eax
	cmpl	$2146435072, %ecx
	je	L67
	fstp	%st(1)
	testl	%ebx, %ebx
	jle	L68
	fstp	%st(0)
	sarl	$20, %ebx
	je	L6
L7:
	andl	$1048575, %eax
	subl	$1023, %ebx
	orl	$1048576, %eax
	testb	$1, %bl
	jne	L69
L10:
	movl	%edx, %ecx
	movl	$22, %esi
	shrl	$31, %ecx
	addl	%edx, %edx
	sarl	%ebx
	movl	$0, 24(%esp)
	movl	%ebx, 28(%esp)
	leal	(%ecx,%eax,2), %eax
	movl	$2097152, %ebx
	xorl	%ecx, %ecx
	xorl	%ebp, %ebp
	.p2align 4,,7
L12:
	leal	(%ecx,%ebx), %edi
	cmpl	%eax, %edi
	jg	L11
	leal	(%edi,%ebx), %ecx
	subl	%edi, %eax
	addl	%ebx, %ebp
L11:
	shrl	%ebx
	movl	%edx, %edi
	shrl	$31, %edi
	addl	%edx, %edx
	decl	%esi
	leal	(%edi,%eax,2), %eax
	jne	L12
	movl	%ebp, 24(%esp)
	movl	$32, 8(%esp)
	movl	$0, 20(%esp)
	xorl	%edi, %edi
	movl	$-2147483648, %ebx
	.p2align 4,,7
L17:
	leal	(%ebx,%edi), %esi
	cmpl	%ecx, %eax
	jg	L13
	cmpl	%edx, %esi
	ja	L14
	cmpl	%ecx, %eax
	jne	L14
L13:
	leal	(%esi,%ebx), %edi
	movl	%ecx, %ebp
	testl	%esi, %esi
	jns	L15
	movl	%edi, %ebp
	andl	$-2147483648, %ebp
	cmpl	$1, %ebp
	movl	%ecx, %ebp
	adcl	$0, %ebp
L15:
	subl	%ecx, %eax
	cmpl	%esi, %edx
	sbbl	$0, %eax
	subl	%esi, %edx
	movl	20(%esp), %esi
	movl	%ebp, %ecx
	addl	%ebx, %esi
	movl	%esi, 20(%esp)
L14:
	shrl	%ebx
	movl	%edx, %esi
	shrl	$31, %esi
	addl	%edx, %edx
	decl	8(%esp)
	leal	(%esi,%eax,2), %eax
	jne	L17
	orl	%eax, %edx
	jne	L18
	jmp	L65
L72:
	fstp	%st(0)
	fstp	%st(0)
L65:
	movl	20(%esp), %ecx
	shrl	%ecx
L19:
	movl	24(%esp), %ebx
	sarl	%ebx
	addl	$1071644672, %ebx
	testb	$1, 24(%esp)
	je	L25
	orl	$-2147483648, %ecx
L25:
	movl	28(%esp), %esi
	movl	%ecx, 8(%esp)
	sall	$20, %esi
	leal	(%esi,%ebx), %edx
	movl	%edx, 12(%esp)
	fldl	8(%esp)
	fstpl	40(%esp)
	fldl	40(%esp)
L3:
	addl	$52, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 20
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 16
	popl	%esi
	.cfi_restore 6
	.cfi_def_cfa_offset 12
	popl	%edi
	.cfi_restore 7
	.cfi_def_cfa_offset 8
	popl	%ebp
	.cfi_restore 5
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L69:
	.cfi_restore_state
	movl	%edx, %ecx
	addl	%edx, %edx
	shrl	$31, %ecx
	leal	(%ecx,%eax,2), %eax
	jmp	L10
	.p2align 4,,7
L18:
	fld1
	fld	%st(0)
	fstl	40(%esp)
	fldl	40(%esp)
	fucomp	%st(2)
	fnstsw	%ax
	testb	$5, %ah
	jne	L72
	fstpl	40(%esp)
	cmpl	$-1, 20(%esp)
	je	L70
	fldl	40(%esp)
	fucompp
	fnstsw	%ax
	testb	$69, %ah
	jne	L62
	cmpl	$-2, 20(%esp)
	sete	%al
	movl	24(%esp), %edx
	andl	$255, %eax
	movl	20(%esp), %ecx
	addl	%eax, %edx
	addl	$2, %ecx
	movl	%edx, 24(%esp)
	shrl	%ecx
	jmp	L19
	.p2align 4,,7
L68:
	movl	%ebx, %ecx
	andl	$2147483647, %ecx
	orl	%edx, %ecx
	je	L3
	xorl	%ebx, %ebx
	testl	%eax, %eax
	jne	L71
	fstp	%st(0)
	.p2align 4,,7
L47:
	movl	%edx, %eax
	subl	$21, %ebx
	shrl	$11, %eax
	sall	$21, %edx
	testl	%eax, %eax
	je	L47
L6:
	testl	$1048576, %eax
	jne	L27
	xorl	%esi, %esi
	.p2align 4,,7
L9:
	addl	%eax, %eax
	incl	%esi
	testl	$1048576, %eax
	je	L9
	movl	$1, %edi
	movl	$32, %ecx
	subl	%esi, %edi
	subl	%esi, %ecx
L8:
	addl	%edi, %ebx
	movl	%edx, %edi
	shrl	%cl, %edi
	movl	%esi, %ecx
	orl	%edi, %eax
	sall	%cl, %edx
	jmp	L7
	.p2align 4,,7
L67:
	fmul	%st, %st(1)
	addl	$52, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 20
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 16
	popl	%esi
	.cfi_restore 6
	.cfi_def_cfa_offset 12
	faddp	%st, %st(1)
	popl	%edi
	.cfi_restore 7
	.cfi_def_cfa_offset 8
	popl	%ebp
	.cfi_restore 5
	.cfi_def_cfa_offset 4
	ret
L70:
	.cfi_restore_state
	fstp	%st(0)
	movl	24(%esp), %ecx
	incl	%ecx
	movl	%ecx, 24(%esp)
	xorl	%ecx, %ecx
	jmp	L19
L62:
	movl	20(%esp), %ecx
	movl	20(%esp), %eax
	andl	$1, %ecx
	addl	%eax, %ecx
	shrl	%ecx
	jmp	L19
L27:
	movl	$32, %ecx
	movl	$1, %edi
	xorl	%esi, %esi
	jmp	L8
L71:
	fsub	%st(0), %st
	fdiv	%st(0), %st
	jmp	L3
	.cfi_endproc
LFE0:
	.ident	"GCC: (GNU) 4.7.4"
