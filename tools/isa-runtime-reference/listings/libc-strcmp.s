	.file	"strcmp.c"
	.section .text
	.p2align 4,,15
	.globl	_strcmp
_strcmp:
LFB0:
	.cfi_startproc
	movl	4(%esp), %eax
	movl	8(%esp), %edx
	movb	(%eax), %cl
	cmpb	(%edx), %cl
	je	L6
	jmp	L2
	.p2align 4,,7
L12:
	incl	%eax
	incl	%edx
	movb	(%eax), %cl
	cmpb	(%edx), %cl
	jne	L2
L6:
	testb	%cl, %cl
	jne	L12
	xorl	%eax, %eax
	ret
	.p2align 4,,7
L2:
	movb	(%eax), %al
	movb	(%edx), %dl
	andl	$255, %eax
	andl	$255, %edx
	subl	%edx, %eax
	ret
	.cfi_endproc
LFE0:
	.ident	"GCC: (GNU) 4.7.4"
