	.file	"fileno.c"
	.section .text
	.p2align 4,,15
	.globl	_fileno
_fileno:
LFB8:
	.cfi_startproc
	movl	4(%esp), %eax
	testl	%eax, %eax
	je	L3
	movl	20(%eax), %eax
	ret
L3:
	orl	$-1, %eax
	ret
	.cfi_endproc
LFE8:
	.ident	"GCC: (GNU) 4.7.4"
