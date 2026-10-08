	.file	"ungetc.c"
	.section .text
	.p2align 4,,15
	.globl	_ungetc
_ungetc:
LFB8:
	.cfi_startproc
	pushl	%esi
	.cfi_def_cfa_offset 8
	.cfi_offset 6, -8
	pushl	%ebx
	.cfi_def_cfa_offset 12
	.cfi_offset 3, -12
	movl	12(%esp), %eax
	movl	16(%esp), %edx
	cmpl	$-1, %eax
	je	L2
	movl	16(%edx), %esi
	testl	$520, %esi
	je	L7
	movl	4(%edx), %ecx
	testl	%ecx, %ecx
	je	L7
	movl	8(%edx), %ebx
	testl	%ebx, %ebx
	je	L7
	cmpl	%ebx, %ecx
	je	L13
L3:
	movl	(%edx), %ebx
	incl	%ebx
	movl	%ebx, (%edx)
	leal	-1(%ecx), %ebx
	movl	%ebx, 4(%edx)
	movsbl	-1(%ecx), %ebx
	cmpl	%eax, %ebx
	je	L2
	orl	$4096, %esi
	movl	%esi, 16(%edx)
	movb	%al, -1(%ecx)
L2:
	popl	%ebx
	.cfi_remember_state
	.cfi_restore 3
	.cfi_def_cfa_offset 8
	popl	%esi
	.cfi_restore 6
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L13:
	.cfi_restore_state
	movl	(%edx), %ebx
	testl	%ebx, %ebx
	jne	L7
	incl	%ecx
	jmp	L3
	.p2align 4,,7
L7:
	orl	$-1, %eax
	jmp	L2
	.cfi_endproc
LFE8:
	.ident	"GCC: (GNU) 4.7.4"
