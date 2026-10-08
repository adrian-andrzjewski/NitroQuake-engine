	.file	"getenv.c"
	.section .text
	.p2align 4,,15
	.globl	_getenv
_getenv:
LFB0:
	.cfi_startproc
	pushl	%edi
	.cfi_def_cfa_offset 8
	.cfi_offset 7, -8
	pushl	%esi
	.cfi_def_cfa_offset 12
	.cfi_offset 6, -12
	movl	__environ, %esi
	pushl	%ebx
	.cfi_def_cfa_offset 16
	.cfi_offset 3, -16
	movl	16(%esp), %edi
	testl	%esi, %esi
	je	L10
	movl	(%esi), %edx
	testl	%edx, %edx
	je	L10
	addl	$4, %esi
	.p2align 4,,7
L3:
	movb	(%edx), %al
	testb	%al, %al
	je	L4
	movb	(%edi), %cl
	testb	%cl, %cl
	je	L12
	cmpb	%cl, %al
	jne	L12
	movl	%edi, %ecx
	jmp	L25
	.p2align 4,,7
L19:
	incl	%edx
	incl	%ecx
	movb	(%edx), %al
	testb	%al, %al
	je	L4
	movb	(%ecx), %bl
	testb	%bl, %bl
	je	L5
	cmpb	%bl, %al
	jne	L5
L25:
	cmpb	$61, %al
	jne	L19
L4:
	addl	$4, %esi
	movl	-4(%esi), %edx
	testl	%edx, %edx
	jne	L3
L10:
	popl	%ebx
	.cfi_remember_state
	.cfi_restore 3
	.cfi_def_cfa_offset 12
	xorl	%eax, %eax
	popl	%esi
	.cfi_restore 6
	.cfi_def_cfa_offset 8
	popl	%edi
	.cfi_restore 7
	.cfi_def_cfa_offset 4
	ret
L12:
	.cfi_restore_state
	movl	%edi, %ecx
	.p2align 4,,7
L5:
	cmpb	$61, %al
	jne	L4
	cmpb	$0, (%ecx)
	jne	L4
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 12
	leal	1(%edx), %eax
	popl	%esi
	.cfi_restore 6
	.cfi_def_cfa_offset 8
	popl	%edi
	.cfi_restore 7
	.cfi_def_cfa_offset 4
	ret
	.cfi_endproc
LFE0:
	.ident	"GCC: (GNU) 4.7.4"
