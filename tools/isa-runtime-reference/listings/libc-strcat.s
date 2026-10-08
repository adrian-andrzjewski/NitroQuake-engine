	.file	"strcat.c"
	.section .text
	.p2align 4,,15
	.globl	_strcat
_strcat:
LFB0:
	.cfi_startproc
	pushl	%ebx
	.cfi_def_cfa_offset 8
	.cfi_offset 3, -8
	movl	8(%esp), %eax
	movl	12(%esp), %ecx
	movl	%eax, %edx
	cmpb	$0, (%eax)
	je	L6
	.p2align 4,,7
L3:
	incl	%edx
	cmpb	$0, (%edx)
	jne	L3
	.p2align 4,,7
L6:
	movb	(%ecx), %bl
	incl	%ecx
	movb	%bl, (%edx)
	incl	%edx
	testb	%bl, %bl
	jne	L6
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 4
	ret
	.cfi_endproc
LFE0:
	.ident	"GCC: (GNU) 4.7.4"
