	.file	"getuid.c"
	.section .text
	.p2align 4,,15
	.globl	_getuid
_getuid:
LFB0:
	.cfi_startproc
	movl	$42, %eax
	ret
	.cfi_endproc
LFE0:
	.ident	"GCC: (GNU) 4.7.4"
