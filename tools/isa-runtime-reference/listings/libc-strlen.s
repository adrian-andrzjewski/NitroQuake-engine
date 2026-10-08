	.file	"strlen.c"
	.section .text
	.p2align 4,,15
	.globl	_strlen
_strlen:
LFB0:
	.cfi_startproc
	movl	4(%esp), %edx
	cmpb	$0, (%edx)
	je	L4
	movl	%edx, %eax
	.p2align 4,,7
L3:
	incl	%eax
	cmpb	$0, (%eax)
	jne	L3
	subl	%edx, %eax
	ret
L4:
	xorl	%eax, %eax
	ret
	.cfi_endproc
LFE0:
	.ident	"GCC: (GNU) 4.7.4"
