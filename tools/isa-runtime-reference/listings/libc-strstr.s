	.file	"strstr.c"
	.section .text
	.p2align 4,,15
	.globl	_strstr
_strstr:
LFB0:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	pushl	%edi
	.cfi_def_cfa_offset 12
	.cfi_offset 7, -12
	pushl	%esi
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	pushl	%ebx
	.cfi_def_cfa_offset 20
	.cfi_offset 3, -20
	subl	$44, %esp
	.cfi_def_cfa_offset 64
	movl	68(%esp), %esi
	movl	64(%esp), %ebx
	movb	(%esi), %dl
	testb	%dl, %dl
	je	L2
	incl	%esi
	movb	%dl, 28(%esp)
	movl	%esi, (%esp)
	leal	1(%ebx), %ebp
	call	_strlen
	movb	28(%esp), %dl
	movl	%eax, %edi
	movb	(%ebx), %al
	testb	%al, %al
	je	L5
	.p2align 4,,7
L13:
	cmpb	%dl, %al
	je	L12
	movl	%ebp, %ebx
L14:
	movb	(%ebx), %al
	leal	1(%ebx), %ebp
	testb	%al, %al
	jne	L13
L5:
	xorl	%ebx, %ebx
L2:
	addl	$44, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 20
	movl	%ebx, %eax
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 16
	popl	%esi
	.cfi_restore 6
	.cfi_def_cfa_offset 12
	popl	%edi
	.cfi_restore 7
	.cfi_def_cfa_offset 8
	popl	%ebp
	.cfi_restore 5
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L12:
	.cfi_restore_state
	movl	%edi, 8(%esp)
	movl	%esi, 4(%esp)
	movl	%ebp, (%esp)
	movb	%dl, 28(%esp)
	call	_strncmp
	movb	28(%esp), %dl
	testl	%eax, %eax
	je	L2
	movl	%ebp, %ebx
	jmp	L14
	.cfi_endproc
LFE0:
	.ident	"GCC: (GNU) 4.7.4"
