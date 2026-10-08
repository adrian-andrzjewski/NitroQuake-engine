	.file	"atold.c"
	.section .text
	.p2align 4,,15
	.globl	__atold
__atold:
LFB0:
	.cfi_startproc
	subl	$28, %esp
	.cfi_def_cfa_offset 32
	movl	32(%esp), %eax
	movl	$0, 4(%esp)
	movl	%eax, (%esp)
	call	__strtold
	addl	$28, %esp
	.cfi_def_cfa_offset 4
	ret
	.cfi_endproc
LFE0:
	.ident	"GCC: (GNU) 4.7.4"
