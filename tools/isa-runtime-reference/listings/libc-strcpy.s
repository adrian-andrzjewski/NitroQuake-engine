	.file	"strcpy.c"
	.section .text
	.p2align 4,,15
	.globl	_strcpy
_strcpy:
LFB0:
	.cfi_startproc
	pushl	%ebx
	.cfi_def_cfa_offset 8
	.cfi_offset 3, -8
	movl	12(%esp), %edx
	movl	8(%esp), %eax
	movl	%eax, %ecx
	movb	(%edx), %bl
	movb	%bl, (%eax)
	testb	%bl, %bl
	je	L7
	.p2align 4,,7
L5:
	incl	%edx
	incl	%ecx
	movb	(%edx), %bl
	movb	%bl, (%ecx)
	testb	%bl, %bl
	jne	L5
L7:
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 4
	ret
	.cfi_endproc
LFE0:
	.ident	"GCC: (GNU) 4.7.4"
