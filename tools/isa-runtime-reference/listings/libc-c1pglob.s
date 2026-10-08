	.file	"c1pglob.c"
	.section .text
	.p2align 4,,15
	.globl	___crt0_glob_function
___crt0_glob_function:
LFB0:
	.cfi_startproc
	subl	$44, %esp
	.cfi_def_cfa_offset 48
	leal	20(%esp), %eax
	movl	$0, 8(%esp)
	movl	%eax, 12(%esp)
	movl	48(%esp), %eax
	movl	$16, 4(%esp)
	movl	%eax, (%esp)
	call	___glob
	testl	%eax, %eax
	jne	L3
	movl	24(%esp), %eax
	addl	$44, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L3:
	.cfi_restore_state
	xorl	%eax, %eax
	addl	$44, %esp
	.cfi_def_cfa_offset 4
	ret
	.cfi_endproc
LFE0:
	.ident	"GCC: (GNU) 4.7.4"
