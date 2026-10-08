	.file	"s_infinity.c"
	.section .text
	.p2align 4,,15
	.globl	_infinity
_infinity:
LFB0:
	.cfi_startproc
	subl	$12, %esp
	.cfi_def_cfa_offset 16
	xorl	%eax, %eax
	movl	$2146435072, %edx
	movl	%eax, (%esp)
	movl	%edx, 4(%esp)
	fldl	(%esp)
	addl	$12, %esp
	.cfi_def_cfa_offset 4
	ret
	.cfi_endproc
LFE0:
	.ident	"GCC: (GNU) 4.7.4"
