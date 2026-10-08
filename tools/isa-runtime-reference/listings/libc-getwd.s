	.file	"getwd.c"
	.section .text
	.p2align 4,,15
	.globl	_getwd
_getwd:
LFB0:
	.cfi_startproc
	subl	$28, %esp
	.cfi_def_cfa_offset 32
	movl	32(%esp), %eax
	testl	%eax, %eax
	je	L3
	movl	$512, 4(%esp)
	movl	%eax, (%esp)
	call	___getcwd
L2:
	addl	$28, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L3:
	.cfi_restore_state
	xorl	%eax, %eax
	jmp	L2
	.cfi_endproc
LFE0:
	.ident	"GCC: (GNU) 4.7.4"
