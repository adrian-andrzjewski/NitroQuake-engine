	.file	"rewind.c"
	.section .text
	.p2align 4,,15
	.globl	_rewind
_rewind:
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
	movl	32(%esp), %ebx
	movl	20(%ebx), %esi
	testl	%esi, %esi
	js	L2
	movl	___fd_properties, %eax
	testl	%eax, %eax
	je	L2
	movl	(%eax,%esi,4), %eax
	testl	%eax, %eax
	je	L2
	testb	$32, 8(%eax)
	je	L2
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
	movl	%ebx, (%esp)
	call	_fflush
	movl	$0, 8(%esp)
	movl	$0, 4(%esp)
	movl	%esi, (%esp)
	call	___lseek
	movl	8(%ebx), %eax
	movl	%eax, 4(%ebx)
	movl	16(%ebx), %eax
	movl	$512, 28(%ebx)
	movl	$0, (%ebx)
	testb	$2, %ah
	je	L12
	andb	$39, %al
	movl	%eax, 16(%ebx)
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
L12:
	.cfi_restore_state
	andb	$63, %al
	movl	%eax, 16(%ebx)
	addl	$20, %esp
	.cfi_def_cfa_offset 12
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 8
	popl	%esi
	.cfi_restore 6
	.cfi_def_cfa_offset 4
	ret
	.cfi_endproc
LFE13:
	.ident	"GCC: (GNU) 4.7.4"
