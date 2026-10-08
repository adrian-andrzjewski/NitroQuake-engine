	.file	"getdinfo.c"
	.section .text
	.p2align 4,,15
	.globl	__get_dev_info
__get_dev_info:
LFB0:
	.cfi_startproc
	subl	$92, %esp
	.cfi_def_cfa_offset 96
	movl	96(%esp), %eax
	movl	$33, (%esp)
	movw	%ax, 44(%esp)
	leal	28(%esp), %eax
	movl	%eax, 4(%esp)
	movw	$17408, 56(%esp)
	call	___dpmi_int
	testb	$1, 60(%esp)
	jne	L6
	movl	48(%esp), %eax
L3:
	addl	$92, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L6:
	.cfi_restore_state
	movl	56(%esp), %eax
	andl	$65535, %eax
	movl	%eax, (%esp)
	call	___doserr_to_errno
	movl	%eax, _errno
	orl	$-1, %eax
	jmp	L3
	.cfi_endproc
LFE0:
	.ident	"GCC: (GNU) 4.7.4"
