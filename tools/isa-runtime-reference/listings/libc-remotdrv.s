	.file	"remotdrv.c"
	.section .text
	.p2align 4,,15
	.globl	__is_remote_drive
__is_remote_drive:
LFB6:
	.cfi_startproc
	subl	$92, %esp
	.cfi_def_cfa_offset 96
	movl	$1, (%esp)
	call	__get_dos_version
	cmpw	$777, %ax
	ja	L2
	movb	96(%esp), %al
	movl	$33, (%esp)
	incl	%eax
	movb	$28, 57(%esp)
	movb	%al, 48(%esp)
	leal	28(%esp), %eax
	movl	%eax, 4(%esp)
	call	___dpmi_int
	cmpb	$-1, 56(%esp)
	je	L8
	xorl	%eax, %eax
L3:
	addl	$92, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L2:
	.cfi_restore_state
	movb	96(%esp), %al
	movl	$33, (%esp)
	incl	%eax
	movw	$17417, 56(%esp)
	movb	%al, 44(%esp)
	leal	28(%esp), %eax
	movl	%eax, 4(%esp)
	call	___dpmi_int
	testb	$1, 60(%esp)
	jne	L9
	movl	48(%esp), %eax
	addl	$92, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 4
	shrw	$12, %ax
	andl	$1, %eax
	ret
L9:
	.cfi_restore_state
	movl	56(%esp), %eax
	andl	$65535, %eax
	movl	%eax, (%esp)
	call	___doserr_to_errno
	movl	%eax, _errno
	orl	$-1, %eax
	jmp	L3
L8:
	movl	$21, _errno
	orl	$-1, %eax
	jmp	L3
	.cfi_endproc
LFE6:
	.ident	"GCC: (GNU) 4.7.4"
