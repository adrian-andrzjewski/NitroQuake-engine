	.file	"memchr.c"
	.section .text
	.p2align 4,,15
	.globl	_memchr
_memchr:
LFB0:
	.cfi_startproc
	movl	12(%esp), %edx
	testl	%edx, %edx
	je	L4
	movb	8(%esp), %cl
	movl	4(%esp), %eax
	.p2align 4,,7
L3:
	cmpb	%cl, (%eax)
	je	L2
	incl	%eax
	decl	%edx
	jne	L3
L4:
	xorl	%eax, %eax
L2:
	ret
	.cfi_endproc
LFE0:
	.ident	"GCC: (GNU) 4.7.4"
