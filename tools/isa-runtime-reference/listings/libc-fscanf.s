	.file	"fscanf.c"
	.section .text
	.p2align 4,,15
	.globl	_fscanf
_fscanf:
LFB8:
	.cfi_startproc
	subl	$28, %esp
	.cfi_def_cfa_offset 32
	leal	40(%esp), %eax
	movl	%eax, 8(%esp)
	movl	36(%esp), %eax
	movl	%eax, 4(%esp)
	movl	32(%esp), %eax
	movl	%eax, (%esp)
	call	__doscan
	addl	$28, %esp
	.cfi_def_cfa_offset 4
	ret
	.cfi_endproc
LFE8:
	.ident	"GCC: (GNU) 4.7.4"
