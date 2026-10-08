	.file	"s_nan.c"
	.section .text
	.p2align 4,,15
	.globl	_nan
_nan:
LFB0:
	.cfi_startproc
	fldl	_a_nan
	ret
	.cfi_endproc
LFE0:
	.p2align 2
_a_nan:
	.long	0
	.long	2146959360
	.ident	"GCC: (GNU) 4.7.4"
