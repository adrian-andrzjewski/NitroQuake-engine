	.file	"rand.c"
	.section .text
	.p2align 4,,15
	.globl	_rand
_rand:
LFB0:
	.cfi_startproc
	imull	$1481765933, _next, %eax
	imull	$1284865837, _next+4, %ecx
	addl	%eax, %ecx
	movl	$1284865837, %eax
	mull	_next
	addl	%ecx, %edx
	addl	$1, %eax
	adcl	$0, %edx
	movl	%eax, _next
	movl	%edx, %eax
	movl	%edx, _next+4
	andl	$2147483647, %eax
	ret
	.cfi_endproc
LFE0:
	.p2align 4,,15
	.globl	_srand
_srand:
LFB1:
	.cfi_startproc
	movl	4(%esp), %eax
	movl	$0, _next+4
	movl	%eax, _next
	ret
	.cfi_endproc
LFE1:
	.section .data
	.p2align 3
_next:
	.long	1
	.long	0
	.ident	"GCC: (GNU) 4.7.4"
