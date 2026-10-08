	.file	"sprintf.c"
	.section .text
	.p2align 4,,15
	.globl	_sprintf
_sprintf:
LFB8:
	.cfi_startproc
	subl	$60, %esp
	.cfi_def_cfa_offset 64
	movl	64(%esp), %eax
	leal	16(%esp), %edx
	movl	%eax, 20(%esp)
	leal	72(%esp), %eax
	movl	%eax, 4(%esp)
	movl	68(%esp), %eax
	movl	%edx, 8(%esp)
	movl	%eax, (%esp)
	movl	$16656, 32(%esp)
	movl	$2147483647, 16(%esp)
	call	__doprnt
	movl	20(%esp), %edx
	movb	$0, (%edx)
	addl	$60, %esp
	.cfi_def_cfa_offset 4
	ret
	.cfi_endproc
LFE8:
	.ident	"GCC: (GNU) 4.7.4"
