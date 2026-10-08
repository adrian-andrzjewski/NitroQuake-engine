	.file	"dup.c"
	.section .text
	.p2align 4,,15
	.globl	___dup
___dup:
LFB5:
	.cfi_startproc
	pushl	%ebx
	.cfi_def_cfa_offset 8
	.cfi_offset 3, -8
	subl	$88, %esp
	.cfi_def_cfa_offset 96
	leal	28(%esp), %eax
	movl	96(%esp), %ebx
	movl	%eax, 4(%esp)
	movl	$33, (%esp)
	movb	$69, 57(%esp)
	movw	%bx, 44(%esp)
	call	___dpmi_int
	testb	$1, 60(%esp)
	jne	L12
	movl	%ebx, (%esp)
	call	___FSEXT_get_function
	movl	%eax, 4(%esp)
	movl	56(%esp), %eax
	andl	$65535, %eax
	movl	%eax, (%esp)
	call	___FSEXT_set_function
	movl	___file_handle_modes, %eax
	movsbl	(%eax,%ebx), %eax
	movl	%eax, 4(%esp)
	movl	56(%esp), %eax
	andl	$65535, %eax
	movl	%eax, (%esp)
	call	___setmode
	testl	%ebx, %ebx
	js	L4
	movl	___fd_properties, %eax
	testl	%eax, %eax
	je	L4
	movl	(%eax,%ebx,4), %eax
	testl	%eax, %eax
	je	L4
	movl	56(%esp), %eax
	movl	%ebx, (%esp)
	andl	$65535, %eax
	movl	%eax, 4(%esp)
	call	___dup_fd_properties
L4:
	movl	56(%esp), %eax
	andl	$65535, %eax
L9:
	addl	$88, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 8
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L12:
	.cfi_restore_state
	movl	56(%esp), %eax
	andl	$65535, %eax
	movl	%eax, (%esp)
	call	___doserr_to_errno
	movl	%eax, _errno
	orl	$-1, %eax
	jmp	L9
	.cfi_endproc
LFE5:
	.ident	"GCC: (GNU) 4.7.4"
