	.file	"umask.c"
	.section .text
	.p2align 4,,15
	.globl	_umask
_umask:
LFB0:
	.cfi_startproc
	movl	4(%esp), %edx
	movl	_the_mask.1452, %eax
	movl	%edx, _the_mask.1452
	ret
	.cfi_endproc
LFE0:
	.section .data
	.p2align 2
_the_mask.1452:
	.long	18
	.ident	"GCC: (GNU) 4.7.4"
