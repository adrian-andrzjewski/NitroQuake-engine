	.file	"sscanf.c"
	.section .text
	.p2align 4,,15
	.globl	_sscanf
_sscanf:
LFB8:
	.cfi_startproc
	pushl	%esi
	.cfi_def_cfa_offset 8
	.cfi_offset 6, -8
	pushl	%ebx
	.cfi_def_cfa_offset 12
	.cfi_offset 3, -12
	subl	$52, %esp
	.cfi_def_cfa_offset 64
	movl	64(%esp), %ecx
	leal	72(%esp), %esi
	movl	$16648, 32(%esp)
	movl	%ecx, 24(%esp)
	movl	%ecx, 20(%esp)
	movl	$0, 16(%esp)
	cmpb	$0, (%ecx)
	je	L4
	movl	$1, %eax
	.p2align 4,,7
L3:
	movb	(%ecx,%eax), %dl
	movl	%eax, %ebx
	incl	%eax
	testb	%dl, %dl
	jne	L3
	movl	%ebx, 16(%esp)
L2:
	movl	68(%esp), %eax
	movl	%esi, 8(%esp)
	movl	%eax, 4(%esp)
	leal	16(%esp), %eax
	movl	%eax, (%esp)
	movl	%ebx, 28(%esp)
	call	__doscan
	addl	$52, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 12
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 8
	popl	%esi
	.cfi_restore 6
	.cfi_def_cfa_offset 4
	ret
L4:
	.cfi_restore_state
	xorl	%ebx, %ebx
	jmp	L2
	.cfi_endproc
LFE8:
	.ident	"GCC: (GNU) 4.7.4"
