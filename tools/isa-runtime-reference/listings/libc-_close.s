	.file	"_close.c"
	.section .text
	.p2align 4,,15
___FSEXT_func_wrapper.constprop.0:
LFB11:
	.cfi_startproc
	subl	$28, %esp
	.cfi_def_cfa_offset 32
	leal	44(%esp), %eax
	movl	$6, (%esp)
	movl	%eax, 8(%esp)
	movl	40(%esp), %eax
	movl	%eax, 4(%esp)
	call	*32(%esp)
	addl	$28, %esp
	.cfi_def_cfa_offset 4
	ret
	.cfi_endproc
LFE11:
	.p2align 4,,15
	.globl	__close
__close:
LFB10:
	.cfi_startproc
	pushl	%ebx
	.cfi_def_cfa_offset 8
	.cfi_offset 3, -8
	subl	$88, %esp
	.cfi_def_cfa_offset 96
	movl	96(%esp), %ebx
	movl	%ebx, (%esp)
	call	___FSEXT_get_function
	testl	%eax, %eax
	je	L4
	leal	24(%esp), %edx
	movl	%ebx, 12(%esp)
	movl	%edx, 8(%esp)
	movl	$6, 4(%esp)
	movl	%eax, (%esp)
	call	___FSEXT_func_wrapper.constprop.0
	movl	$0, 4(%esp)
	movl	%ebx, (%esp)
	testl	%eax, %eax
	jne	L18
	call	___FSEXT_set_function
L4:
	leal	28(%esp), %eax
	movl	$33, (%esp)
	movl	%eax, 4(%esp)
	movb	$62, 57(%esp)
	movw	%bx, 44(%esp)
	call	___dpmi_int
	testb	$1, 60(%esp)
	jne	L19
	testl	%ebx, %ebx
	js	L16
	movl	___fd_properties, %eax
	testl	%eax, %eax
	je	L16
	movl	(%eax,%ebx,4), %eax
	testl	%eax, %eax
	je	L16
	movl	%ebx, (%esp)
	call	___clear_fd_properties
L16:
	xorl	%eax, %eax
L14:
	addl	$88, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 8
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L18:
	.cfi_restore_state
	call	___FSEXT_set_function
	movl	24(%esp), %eax
	addl	$88, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 8
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L19:
	.cfi_restore_state
	movl	$6, _errno
	orl	$-1, %eax
	jmp	L14
	.cfi_endproc
LFE10:
	.ident	"GCC: (GNU) 4.7.4"
