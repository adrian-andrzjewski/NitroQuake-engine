	.file	"basename.c"
	.section .text
	.p2align 4,,15
	.globl	___basename
___basename:
LFB0:
	.cfi_startproc
	pushl	%esi
	.cfi_def_cfa_offset 8
	.cfi_offset 6, -8
	pushl	%ebx
	.cfi_def_cfa_offset 12
	.cfi_offset 3, -12
	movl	12(%esp), %esi
	testl	%esi, %esi
	je	L7
	movb	(%esi), %bl
	movl	%esi, %eax
	testb	%bl, %bl
	je	L13
	movb	1(%esi), %cl
	cmpb	$58, %cl
	je	L21
L3:
	leal	1(%esi), %edx
	movl	%esi, %eax
	cmpb	$47, %bl
	je	L10
	.p2align 4,,7
L22:
	cmpb	$92, %bl
	je	L10
	incl	%edx
	testb	%cl, %cl
	je	L13
L23:
	movb	%cl, %bl
	movb	(%edx), %cl
	cmpb	$47, %bl
	jne	L22
L10:
	movl	%edx, %eax
	incl	%edx
	testb	%cl, %cl
	jne	L23
L13:
	popl	%ebx
	.cfi_remember_state
	.cfi_restore 3
	.cfi_def_cfa_offset 8
	popl	%esi
	.cfi_restore 6
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L21:
	.cfi_restore_state
	movb	2(%esi), %bl
	leal	2(%esi), %eax
	testb	%bl, %bl
	je	L13
	movb	3(%esi), %cl
	movl	%eax, %esi
	jmp	L3
	.p2align 4,,7
L7:
	xorl	%eax, %eax
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 8
	popl	%esi
	.cfi_restore 6
	.cfi_def_cfa_offset 4
	ret
	.cfi_endproc
LFE0:
	.ident	"GCC: (GNU) 4.7.4"
