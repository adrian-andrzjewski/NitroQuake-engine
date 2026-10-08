	.file	"feof.c"
	.section .text
	.p2align 4,,15
	.globl	_feof
_feof:
LFB8:
	.cfi_startproc
	movl	4(%esp), %eax
	movl	16(%eax), %eax
	andl	$64, %eax
	ret
	.cfi_endproc
LFE8:
	.ident	"GCC: (GNU) 4.7.4"
