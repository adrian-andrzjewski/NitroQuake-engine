	.file	"gettimeo.c"
	.section .text
	.p2align 4,,15
	.globl	___gettimeofday
___gettimeofday:
LFB1:
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
	addl	$-128, %esp
	.cfi_def_cfa_offset 144
	movl	144(%esp), %ebx
	movl	148(%esp), %esi
	testl	%ebx, %ebx
	je	L10
L2:
	leal	76(%esp), %edi
	movl	$33, (%esp)
	movl	%edi, 4(%esp)
	movb	$44, 105(%esp)
	call	___dpmi_int
	xorl	%eax, %eax
	movb	96(%esp), %al
	movb	$42, 105(%esp)
	leal	(%eax,%eax,4), %eax
	leal	(%eax,%eax,4), %eax
	leal	(%eax,%eax,4), %eax
	leal	(%eax,%eax,4), %eax
	sall	$4, %eax
	movl	%eax, 4(%ebx)
	xorl	%eax, %eax
	movb	97(%esp), %al
	movl	%edi, 4(%esp)
	movl	%eax, 32(%esp)
	xorl	%eax, %eax
	movb	100(%esp), %al
	movl	$33, (%esp)
	movl	%eax, 36(%esp)
	xorl	%eax, %eax
	movb	101(%esp), %al
	movl	%eax, 40(%esp)
	call	___dpmi_int
	xorl	%eax, %eax
	movl	$0, 72(%esp)
	movb	96(%esp), %al
	movl	$0, 60(%esp)
	movl	%eax, 44(%esp)
	xorl	%eax, %eax
	movb	97(%esp), %al
	movl	$0, 56(%esp)
	decl	%eax
	movl	$0, 68(%esp)
	movl	%eax, 48(%esp)
	movl	100(%esp), %eax
	andl	$2047, %eax
	movl	$-1, 64(%esp)
	subl	$1900, %eax
	movl	%eax, 52(%esp)
	leal	32(%esp), %eax
	movl	%eax, (%esp)
	call	_mktime
	testl	%esi, %esi
	movl	%eax, (%ebx)
	je	L3
	movl	%ebx, (%esp)
	call	_localtime
	movl	$-2004318071, %edx
	movl	%eax, %ebx
	movl	40(%eax), %ecx
	movl	%ecx, %eax
	imull	%edx
	addl	%ecx, %edx
	movl	32(%ebx), %eax
	sarl	$5, %edx
	movl	%eax, 4(%esi)
	sarl	$31, %ecx
	subl	%edx, %ecx
	movl	%ecx, (%esi)
L3:
	subl	$-128, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 16
	xorl	%eax, %eax
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
L10:
	.cfi_restore_state
	leal	24(%esp), %ebx
	jmp	L2
	.cfi_endproc
LFE1:
	.ident	"GCC: (GNU) 4.7.4"
