	.file	"is_dos83.c"
	.section .text
	.p2align 4,,15
	.globl	__is_DOS83
__is_DOS83:
LFB0:
	.cfi_startproc
	pushl	%esi
	.cfi_def_cfa_offset 8
	.cfi_offset 6, -8
	pushl	%ebx
	.cfi_def_cfa_offset 12
	.cfi_offset 3, -12
	movl	12(%esp), %edx
	movb	(%edx), %al
	cmpb	$46, %al
	je	L19
	leal	8(%edx), %ebx
	xorl	%esi, %esi
	incl	%edx
	testb	%al, %al
	je	L20
	.p2align 4,,7
L7:
	cmpb	$46, %al
	je	L21
	cmpl	%edx, %ebx
	jb	L15
	leal	-97(%eax), %ecx
	cmpb	$25, %cl
	jbe	L15
	leal	-43(%eax), %ecx
	cmpb	$1, %cl
	jbe	L15
	cmpb	$59, %al
	je	L15
	cmpb	$61, %al
	je	L15
	cmpb	$32, %al
	je	L15
	cmpb	$93, %al
	je	L15
	cmpb	$91, %al
	je	L15
	movb	(%edx), %al
L22:
	incl	%edx
	testb	%al, %al
	jne	L7
L20:
	movl	$1, %eax
	popl	%ebx
	.cfi_remember_state
	.cfi_restore 3
	.cfi_def_cfa_offset 8
	popl	%esi
	.cfi_restore 6
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L15:
	.cfi_restore_state
	xorl	%eax, %eax
L3:
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
	movl	%esi, %eax
	testb	%al, %al
	jne	L15
	leal	3(%edx), %ebx
	movl	$1, %esi
	movb	(%edx), %al
	jmp	L22
	.p2align 4,,7
L19:
	movb	1(%edx), %cl
	movl	$1, %eax
	testb	%cl, %cl
	je	L3
	xorb	%al, %al
	cmpb	$46, %cl
	jne	L3
	cmpb	$0, 2(%edx)
	sete	%al
	andl	$255, %eax
	jmp	L3
	.cfi_endproc
LFE0:
	.ident	"GCC: (GNU) 4.7.4"
