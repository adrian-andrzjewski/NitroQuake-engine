	.file	"dxeload.c"
	.section .text
	.p2align 4,,15
	.globl	__dxe_load
__dxe_load:
LFB0:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%edi
	pushl	%esi
	pushl	%ebx
	subl	$60, %esp
	.cfi_offset 7, -12
	.cfi_offset 6, -16
	.cfi_offset 3, -20
	movl	$0, 4(%esp)
	movl	8(%ebp), %eax
	movl	%eax, (%esp)
	call	__open
	movl	%eax, %edi
	testl	%eax, %eax
	js	L8
	leal	-40(%ebp), %eax
	movl	$16, 8(%esp)
	movl	%eax, 4(%esp)
	movl	%edi, (%esp)
	call	__read
	cmpl	$826628164, -40(%ebp)
	jne	L13
	movl	-32(%ebp), %esi
	movl	%esi, (%esp)
	call	_malloc
	movl	%eax, %ebx
	testl	%eax, %eax
	je	L14
	movl	%esi, 8(%esp)
	movl	%edi, (%esp)
	movl	%eax, 4(%esp)
	call	__read
	movl	-28(%ebp), %edx
	sall	$2, %edx
	movl	%esp, -44(%ebp)
	leal	18(%edx), %eax
	andl	$-16, %eax
	subl	%eax, %esp
	leal	12(%esp), %esi
	movl	%edx, 8(%esp)
	movl	%edi, (%esp)
	movl	%esi, 4(%esp)
	call	__read
	movl	%edi, (%esp)
	call	__close
	movl	-28(%ebp), %edi
	xorl	%edx, %edx
	testl	%edi, %edi
	jle	L7
	.p2align 4,,7
L9:
	movl	(%esi,%edx,4), %eax
	incl	%edx
	addl	%ebx, %eax
	movl	(%eax), %ecx
	addl	%ebx, %ecx
	cmpl	%edi, %edx
	movl	%ecx, (%eax)
	jne	L9
L7:
	movl	-36(%ebp), %eax
	movl	-44(%ebp), %esp
	addl	%ebx, %eax
L2:
	leal	-12(%ebp), %esp
	popl	%ebx
	.cfi_remember_state
	.cfi_restore 3
	popl	%esi
	.cfi_restore 6
	popl	%edi
	.cfi_restore 7
	popl	%ebp
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.p2align 4,,7
L13:
	.cfi_restore_state
	movl	%edi, (%esp)
	call	__close
	movl	$23, _errno
	leal	-12(%ebp), %esp
	xorl	%eax, %eax
	popl	%ebx
	.cfi_remember_state
	.cfi_restore 3
	popl	%esi
	.cfi_restore 6
	popl	%edi
	.cfi_restore 7
	popl	%ebp
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.p2align 4,,7
L8:
	.cfi_restore_state
	xorl	%eax, %eax
	jmp	L2
L14:
	movl	%edi, (%esp)
	call	__close
	movl	$25, _errno
	xorl	%eax, %eax
	jmp	L2
	.cfi_endproc
LFE0:
	.ident	"GCC: (GNU) 4.7.4"
