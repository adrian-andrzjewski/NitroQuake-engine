	.file	"fflush.c"
	.section .text
	.p2align 4,,15
	.globl	_fflush
_fflush:
LFB13:
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
	movl	64(%esp), %ebx
	testl	%ebx, %ebx
	je	L34
	movl	20(%ebx), %eax
	testl	%eax, %eax
	js	L4
	movl	___fd_properties, %edx
	testl	%edx, %edx
	je	L4
	movl	(%edx,%eax,4), %edx
	testl	%edx, %edx
	je	L4
	testb	$16, 8(%edx)
	je	L4
	movl	$2, 12(%esp)
	movl	$0, 4(%esp)
	movl	$0, 8(%esp)
	movl	%eax, (%esp)
	movl	_errno, %esi
	call	___llseek
	andl	%edx, %eax
	cmpl	$-1, %eax
	je	L35
L4:
	movl	16(%ebx), %eax
	movl	%eax, %edx
	movl	%eax, %ecx
	andb	$239, %dh
	andl	$18, %ecx
	movl	%edx, 16(%ebx)
	cmpl	$16, %ecx
	je	L36
L6:
	xorl	%eax, %eax
	testb	$2, %dh
	je	L26
	andl	$-25, %edx
	movl	$0, (%ebx)
	movl	%edx, 16(%ebx)
	movl	8(%ebx), %edx
	movl	%edx, 4(%ebx)
L26:
	addl	$44, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 20
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
L36:
	.cfi_restore_state
	movl	8(%ebx), %ebp
	testl	%ebp, %ebp
	je	L6
	movl	4(%ebx), %esi
	subl	%ebp, %esi
	movl	%esi, 28(%esp)
	testl	%esi, %esi
	jle	L6
	xorb	%cl, %cl
	movl	%ebp, 4(%ebx)
	testb	$6, %al
	jne	L7
	movl	12(%ebx), %ecx
L7:
	movl	%ecx, (%ebx)
	leal	28(%esp), %edi
	jmp	L13
	.p2align 4,,7
L8:
	movl	___libc_write_termios_hook, %eax
	testl	%eax, %eax
	je	L10
	movl	%edi, 12(%esp)
	movl	%esi, 8(%esp)
	movl	%ebp, 4(%esp)
	movl	20(%ebx), %edx
	movl	%edx, (%esp)
	call	*%eax
	testl	%eax, %eax
	je	L10
	movl	28(%esp), %eax
L9:
	testl	%eax, %eax
	jle	L37
	addl	%eax, %ebp
	subl	%eax, %esi
	movl	16(%ebx), %edx
	je	L6
L13:
	andb	$32, %dh
	jne	L8
L10:
	movl	%esi, 8(%esp)
	movl	%ebp, 4(%esp)
	movl	20(%ebx), %eax
	movl	%eax, (%esp)
	call	__write
	movl	%eax, 28(%esp)
	jmp	L9
	.p2align 4,,7
L37:
	orl	$128, 16(%ebx)
	orl	$-1, %eax
	jmp	L26
	.p2align 4,,7
L34:
	movl	$_fflush, (%esp)
	movl	_errno, %ebx
	movl	$0, _errno
	call	__fwalk
	movl	_errno, %eax
	testl	%eax, %eax
	jne	L15
	movl	%ebx, _errno
	xorl	%eax, %eax
	jmp	L26
L35:
	movl	%esi, _errno
	jmp	L26
L15:
	orl	$-1, %eax
	jmp	L26
	.cfi_endproc
LFE13:
	.ident	"GCC: (GNU) 4.7.4"
