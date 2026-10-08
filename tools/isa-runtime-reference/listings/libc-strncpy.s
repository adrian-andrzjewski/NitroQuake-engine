	.file	"strncpy.c"
	.section .text
	.p2align 4,,15
	.globl	_strncpy
_strncpy:
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
	je	L8
	movl	16(%esp), %ebx
	movl	%esi, %edx
	.p2align 4,,7
L6:
	movb	(%ebx), %al
	incl	%ebx
	movb	%al, (%edx)
	incl	%edx
	testb	%al, %al
	je	L15
	decl	%ecx
	jne	L6
L8:
	movl	%esi, %eax
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
	cmpl	$1, %ecx
	je	L8
	leal	-1(%edx,%ecx), %eax
	.p2align 4,,7
L5:
	movb	$0, (%edx)
	incl	%edx
	cmpl	%eax, %edx
	jne	L5
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
