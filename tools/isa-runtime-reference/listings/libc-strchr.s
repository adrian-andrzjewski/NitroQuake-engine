	.file	"strchr.c"
	.section .text
	.p2align 4,,15
	.globl	_strchr
_strchr:
LFB0:
	.cfi_startproc
	movl	4(%esp), %eax
	movb	8(%esp), %cl
	movb	(%eax), %dl
	testb	%dl, %dl
	je	L2
	cmpb	%dl, %cl
	jne	L12
	jmp	L15
	.p2align 4,,7
L6:
	cmpb	%dl, %cl
	je	L3
L12:
	incl	%eax
	movb	(%eax), %dl
	testb	%dl, %dl
	jne	L6
L2:
	testb	%cl, %cl
	sete	%dl
	andl	$255, %edx
	negl	%edx
	andl	%edx, %eax
L3:
	ret
L15:
	ret
	.cfi_endproc
LFE0:
	.ident	"GCC: (GNU) 4.7.4"
