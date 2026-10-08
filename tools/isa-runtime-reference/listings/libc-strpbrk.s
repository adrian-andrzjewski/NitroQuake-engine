	.file	"strpbrk.c"
	.section .text
	.p2align 4,,15
	.globl	_strpbrk
_strpbrk:
LFB0:
	.cfi_startproc
	pushl	%edi
	.cfi_def_cfa_offset 8
	.cfi_offset 7, -8
	pushl	%esi
	.cfi_def_cfa_offset 12
	.cfi_offset 6, -12
	pushl	%ebx
	.cfi_def_cfa_offset 16
	.cfi_offset 3, -16
	movl	16(%esp), %eax
	movl	20(%esp), %edi
	jmp	L2
	.p2align 4,,7
L10:
	movl	%esi, %eax
L2:
	movsbl	(%eax), %ebx
	leal	1(%eax), %esi
	testl	%ebx, %ebx
	je	L9
	movl	%edi, %edx
L4:
	movsbl	(%edx), %ecx
	incl	%edx
	testl	%ecx, %ecx
	je	L10
	cmpl	%ebx, %ecx
	jne	L4
	popl	%ebx
	.cfi_remember_state
	.cfi_restore 3
	.cfi_def_cfa_offset 12
	popl	%esi
	.cfi_restore 6
	.cfi_def_cfa_offset 8
	popl	%edi
	.cfi_restore 7
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L9:
	.cfi_restore_state
	popl	%ebx
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
	.cfi_endproc
LFE0:
	.ident	"GCC: (GNU) 4.7.4"
