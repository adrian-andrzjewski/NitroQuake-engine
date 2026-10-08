	.file	"dup2.c"
	.section .text
	.p2align 4,,15
	.globl	___dup2
___dup2:
LFB5:
	.cfi_startproc
	pushl	%esi
	.cfi_def_cfa_offset 8
	.cfi_offset 6, -8
	pushl	%ebx
	.cfi_def_cfa_offset 12
	.cfi_offset 3, -12
	subl	$84, %esp
	.cfi_def_cfa_offset 96
	movl	96(%esp), %esi
	movl	100(%esp), %ebx
	cmpl	%ebx, %esi
	je	L11
	movl	___file_handle_modes, %eax
	movb	(%eax,%esi), %al
	movl	%ebx, (%esp)
	xorl	$12, %eax
	movsbl	%al, %eax
	movl	%eax, 4(%esp)
	call	___file_handle_set
	movl	$0, 4(%esp)
	movl	%ebx, (%esp)
	call	___FSEXT_set_function
	leal	28(%esp), %eax
	movl	%eax, 4(%esp)
	movl	$33, (%esp)
	movb	$70, 57(%esp)
	movw	%si, 44(%esp)
	movw	%bx, 52(%esp)
	call	___dpmi_int
	testb	$1, 60(%esp)
	jne	L18
	testl	%ebx, %ebx
	js	L5
	movl	___fd_properties, %eax
	testl	%eax, %eax
	je	L5
	movl	(%eax,%ebx,4), %edx
	testl	%edx, %edx
	je	L5
	movl	%ebx, (%esp)
	call	___clear_fd_properties
L5:
	movl	%esi, (%esp)
	call	___FSEXT_get_function
	movl	%ebx, (%esp)
	movl	%eax, 4(%esp)
	call	___FSEXT_set_function
	movl	___file_handle_modes, %eax
	movsbl	(%eax,%esi), %eax
	movl	%ebx, (%esp)
	movl	%eax, 4(%esp)
	call	___setmode
	testl	%esi, %esi
	js	L11
	movl	___fd_properties, %eax
	testl	%eax, %eax
	je	L11
	movl	(%eax,%esi,4), %eax
	testl	%eax, %eax
	je	L11
	movl	%ebx, 4(%esp)
	movl	%esi, (%esp)
	call	___dup_fd_properties
L11:
	addl	$84, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 12
	movl	%ebx, %eax
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 8
	popl	%esi
	.cfi_restore 6
	.cfi_def_cfa_offset 4
	ret
L18:
	.cfi_restore_state
	movl	56(%esp), %eax
	orl	$-1, %ebx
	andl	$65535, %eax
	movl	%eax, (%esp)
	call	___doserr_to_errno
	movl	%eax, _errno
	jmp	L11
	.cfi_endproc
LFE5:
	.ident	"GCC: (GNU) 4.7.4"
