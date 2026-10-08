	.file	"crlf2nl.c"
	.section .text
	.p2align 4,,15
	.globl	___crlf2nl
___crlf2nl:
LFB0:
	.cfi_startproc
	pushl	%esi
	.cfi_def_cfa_offset 8
	.cfi_offset 6, -8
	pushl	%ebx
	.cfi_def_cfa_offset 12
	.cfi_offset 3, -12
	movl	16(%esp), %esi
	movl	12(%esp), %ebx
	testl	%esi, %esi
	je	L5
	addl	%ebx, %esi
	movl	%ebx, %edx
	xorl	%eax, %eax
	.p2align 4,,7
L4:
	movb	(%edx), %cl
	cmpb	$13, %cl
	je	L3
	movb	%cl, (%ebx)
	incl	%eax
	incl	%ebx
L3:
	incl	%edx
	cmpl	%esi, %edx
	jne	L4
L2:
	popl	%ebx
	.cfi_remember_state
	.cfi_restore 3
	.cfi_def_cfa_offset 8
	popl	%esi
	.cfi_restore 6
	.cfi_def_cfa_offset 4
	ret
L5:
	.cfi_restore_state
	xorl	%eax, %eax
	jmp	L2
	.cfi_endproc
LFE0:
	.ident	"GCC: (GNU) 4.7.4"
