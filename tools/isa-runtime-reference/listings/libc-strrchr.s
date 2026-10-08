	.file	"strrchr.c"
	.section .text
	.p2align 4,,15
	.globl	_strrchr
_strrchr:
LFB0:
	.cfi_startproc
	pushl	%ebx
	.cfi_def_cfa_offset 8
	.cfi_offset 3, -8
	xorl	%eax, %eax
	movl	8(%esp), %edx
	movb	12(%esp), %bl
	movb	(%edx), %cl
	testb	%cl, %cl
	jne	L4
	jmp	L2
	.p2align 4,,7
L3:
	incl	%edx
	movb	(%edx), %cl
	testb	%cl, %cl
	je	L2
L4:
	cmpb	%cl, %bl
	jne	L3
	movl	%edx, %eax
	incl	%edx
	movb	(%edx), %cl
	testb	%cl, %cl
	jne	L4
L2:
	testb	%bl, %bl
	jne	L5
	movl	%edx, %eax
L5:
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 4
	ret
	.cfi_endproc
LFE0:
	.ident	"GCC: (GNU) 4.7.4"
