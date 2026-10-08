	.file	"time.c"
	.section .text
	.p2align 4,,15
	.globl	_time
_time:
LFB1:
	.cfi_startproc
	pushl	%ebx
	.cfi_def_cfa_offset 8
	.cfi_offset 3, -8
	subl	$40, %esp
	.cfi_def_cfa_offset 48
	leal	24(%esp), %eax
	movl	$0, 4(%esp)
	movl	%eax, (%esp)
	movl	48(%esp), %ebx
	call	___gettimeofday
	orl	$-1, %edx
	testl	%eax, %eax
	js	L2
	movl	24(%esp), %edx
	testl	%ebx, %ebx
	je	L2
	movl	%edx, (%ebx)
L2:
	addl	$40, %esp
	.cfi_def_cfa_offset 8
	movl	%edx, %eax
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 4
	ret
	.cfi_endproc
LFE1:
	.ident	"GCC: (GNU) 4.7.4"
