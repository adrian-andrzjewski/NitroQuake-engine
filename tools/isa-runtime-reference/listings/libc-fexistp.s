	.file	"fexistp.c"
	.section .text
	.p2align 4,,15
	.globl	___file_exists
___file_exists:
LFB0:
	.cfi_startproc
	pushl	%ebx
	.cfi_def_cfa_offset 8
	.cfi_offset 3, -8
	subl	$24, %esp
	.cfi_def_cfa_offset 32
	movl	_errno, %ebx
	movl	32(%esp), %eax
	movl	$0, 4(%esp)
	movl	%eax, (%esp)
	call	__chmod
	movl	%ebx, _errno
	incl	%eax
	setne	%al
	addl	$24, %esp
	.cfi_def_cfa_offset 8
	andl	$255, %eax
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 4
	ret
	.cfi_endproc
LFE0:
	.ident	"GCC: (GNU) 4.7.4"
