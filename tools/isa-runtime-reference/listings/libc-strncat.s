	.file	"strncat.c"
	.section .text
	.p2align 4,,15
	.globl	_strncat
_strncat:
LFB0:
	.cfi_startproc
	pushl	%esi
	.cfi_def_cfa_offset 8
	.cfi_offset 6, -8
	pushl	%ebx
	.cfi_def_cfa_offset 12
	.cfi_offset 3, -12
	movl	20(%esp), %ecx
	movl	12(%esp), %esi
	testl	%ecx, %ecx
	je	L2
	movl	%esi, %edx
	cmpb	$0, (%esi)
	je	L3
	.p2align 4,,7
L4:
	incl	%edx
	cmpb	$0, (%edx)
	jne	L4
L3:
	movl	16(%esp), %ebx
	.p2align 4,,7
L6:
	movb	(%ebx), %al
	incl	%ebx
	movb	%al, (%edx)
	testb	%al, %al
	je	L5
	incl	%edx
	decl	%ecx
	jne	L6
L5:
	movb	$0, (%edx)
L2:
	movl	%esi, %eax
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
