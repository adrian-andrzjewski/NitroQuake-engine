	.file	"stpcpy.c"
	.section .text
	.p2align 4,,15
	.globl	_stpcpy
_stpcpy:
LFB0:
	.cfi_startproc
	movl	4(%esp), %eax
	movl	8(%esp), %edx
	.p2align 4,,7
L2:
	movb	(%edx), %cl
	incl	%edx
	movb	%cl, (%eax)
	incl	%eax
	testb	%cl, %cl
	jne	L2
	decl	%eax
	ret
	.cfi_endproc
LFE0:
	.ident	"GCC: (GNU) 4.7.4"
