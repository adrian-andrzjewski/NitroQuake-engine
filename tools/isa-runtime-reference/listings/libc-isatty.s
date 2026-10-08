	.file	"isatty.c"
	.section .text
	.p2align 4,,15
	.globl	___isatty
___isatty:
LFB0:
	.cfi_startproc
	subl	$28, %esp
	.cfi_def_cfa_offset 32
	movl	32(%esp), %eax
	movl	%eax, (%esp)
	call	__get_dev_info
	cmpw	$-1, %ax
	je	L3
	andl	$131, %eax
	cmpw	$131, %ax
	sete	%al
	andl	$255, %eax
	addl	$28, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L3:
	.cfi_restore_state
	xorl	%eax, %eax
	addl	$28, %esp
	.cfi_def_cfa_offset 4
	ret
	.cfi_endproc
LFE0:
	.ident	"GCC: (GNU) 4.7.4"
