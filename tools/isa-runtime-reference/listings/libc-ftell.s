	.file	"ftell.c"
	.section .text
	.p2align 4,,15
	.globl	_ftell
_ftell:
LFB13:
	.cfi_startproc
	pushl	%esi
	.cfi_def_cfa_offset 8
	.cfi_offset 6, -8
	pushl	%ebx
	.cfi_def_cfa_offset 12
	.cfi_offset 3, -12
	subl	$20, %esp
	.cfi_def_cfa_offset 32
	movl	32(%esp), %edx
	movl	20(%edx), %ecx
	testl	%ecx, %ecx
	js	L2
	movl	___fd_properties, %eax
	testl	%eax, %eax
	je	L2
	movl	(%eax,%ecx,4), %ebx
	testl	%ebx, %ebx
	je	L2
	xorl	%eax, %eax
	testb	$32, 8(%ebx)
	je	L2
L14:
	addl	$20, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 12
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 8
	popl	%esi
	.cfi_restore 6
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L2:
	.cfi_restore_state
	movl	(%edx), %eax
	testl	%eax, %eax
	js	L20
	movl	16(%edx), %eax
	testb	$8, %al
	je	L5
L21:
	movl	(%edx), %ebx
	negl	%ebx
L6:
	movl	$1, 8(%esp)
	movl	$0, 4(%esp)
	movl	%ecx, (%esp)
	call	___lseek
	testl	%eax, %eax
	js	L14
	addl	$20, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 12
	addl	%ebx, %eax
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 8
	popl	%esi
	.cfi_restore 6
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L5:
	.cfi_restore_state
	testl	$528, %eax
	je	L8
	xorl	%ebx, %ebx
	testb	$16, %al
	je	L6
	movl	8(%edx), %esi
	testl	%esi, %esi
	je	L6
	testb	$2, %al
	jne	L6
	movl	4(%edx), %ebx
	subl	%esi, %ebx
	jmp	L6
	.p2align 4,,7
L20:
	movl	16(%edx), %eax
	movl	$0, (%edx)
	testb	$8, %al
	je	L5
	jmp	L21
L8:
	orl	$-1, %eax
	jmp	L14
	.cfi_endproc
LFE13:
	.ident	"GCC: (GNU) 4.7.4"
