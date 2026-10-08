	.file	"getgid.c"
	.section .text
	.p2align 4,,15
	.globl	_getgid
_getgid:
LFB0:
	.cfi_startproc
	movl	$42, %eax
	ret
	.cfi_endproc
LFE0:
	.ident	"GCC: (GNU) 4.7.4"
