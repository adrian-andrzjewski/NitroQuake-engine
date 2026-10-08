	.file	"readlink.c"
	.section .text
	.p2align 4,,15
	.globl	___readlink
___readlink:
LFB0:
	.cfi_startproc
	pushl	%ebx
	.cfi_def_cfa_offset 8
	.cfi_offset 3, -8
	subl	$296, %esp
	.cfi_def_cfa_offset 304
	movl	304(%esp), %eax
	leal	28(%esp), %ebx
	movl	%ebx, 4(%esp)
	movl	%eax, (%esp)
	call	___solve_dir_symlinks
	testl	%eax, %eax
	je	L3
	movl	312(%esp), %eax
	movl	$0, 4(%esp)
	movl	%eax, 12(%esp)
	movl	308(%esp), %eax
	movl	%eax, 8(%esp)
	movl	%ebx, (%esp)
	call	___internal_readlink
L2:
	addl	$296, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 8
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L3:
	.cfi_restore_state
	orl	$-1, %eax
	jmp	L2
	.cfi_endproc
LFE0:
	.ident	"GCC: (GNU) 4.7.4"
