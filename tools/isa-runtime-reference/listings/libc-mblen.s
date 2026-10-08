	.file	"mblen.c"
	.section .text
	.p2align 4,,15
	.globl	_mblen
_mblen:
LFB0:
	.cfi_startproc
	movl	4(%esp), %edx
	testl	%edx, %edx
	je	L3
	movl	8(%esp), %ecx
	xorl	%eax, %eax
	testl	%ecx, %ecx
	je	L2
	cmpb	$0, (%edx)
	setne	%al
	andl	$255, %eax
	ret
	.p2align 4,,7
L3:
	movl	$1, %eax
L2:
	ret
	.cfi_endproc
LFE0:
	.ident	"GCC: (GNU) 4.7.4"
