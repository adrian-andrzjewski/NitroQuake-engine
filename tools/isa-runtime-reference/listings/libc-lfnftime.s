	.file	"lfnftime.c"
	.section .text
	.p2align 4,,15
	.globl	__lfn_get_ftime
__lfn_get_ftime:
LFB0:
	.cfi_startproc
	subl	$92, %esp
	.cfi_def_cfa_offset 96
	movl	100(%esp), %eax
	leal	-1(%eax), %edx
	cmpl	$1, %edx
	jbe	L2
	movl	$14, _errno
	xorl	%eax, %eax
L3:
	addl	$92, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L2:
	.cfi_restore_state
	movl	$22278, %edx
	cmpl	$2, %eax
	je	L9
L4:
	movl	96(%esp), %eax
	movl	$33, (%esp)
	movw	%ax, 44(%esp)
	leal	28(%esp), %eax
	movl	%eax, 4(%esp)
	movw	%dx, 56(%esp)
	call	___dpmi_int
	testb	$1, 60(%esp)
	jne	L10
	movl	48(%esp), %eax
	movl	52(%esp), %edx
	sall	$16, %eax
	andl	$65535, %edx
	orl	%edx, %eax
	addl	$92, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L9:
	.cfi_restore_state
	movb	$4, %dl
	jmp	L4
	.p2align 4,,7
L10:
	movl	56(%esp), %eax
	andl	$65535, %eax
	movl	%eax, (%esp)
	call	___doserr_to_errno
	movl	%eax, _errno
	xorl	%eax, %eax
	jmp	L3
	.cfi_endproc
LFE0:
	.ident	"GCC: (GNU) 4.7.4"
