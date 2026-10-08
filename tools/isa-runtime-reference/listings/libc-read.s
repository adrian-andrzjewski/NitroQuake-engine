	.file	"read.c"
	.section .text
	.p2align 4,,15
	.globl	___read
___read:
LFB5:
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
	movl	___libc_read_termios_hook, %eax
	movl	64(%esp), %esi
	movl	68(%esp), %ebp
	movl	72(%esp), %edi
	testl	%eax, %eax
	je	L2
	leal	28(%esp), %edx
	movl	%edi, 8(%esp)
	movl	%edx, 12(%esp)
	movl	%ebp, 4(%esp)
	movl	%esi, (%esp)
	call	*%eax
	testl	%eax, %eax
	jne	L28
L2:
	testl	%esi, %esi
	js	L5
	movl	___fd_properties, %eax
	testl	%eax, %eax
	je	L5
	movl	(%eax,%esi,4), %eax
	testl	%eax, %eax
	je	L5
	testb	$32, 8(%eax)
	jne	L29
L5:
	movl	%edi, 8(%esp)
	movl	%ebp, 4(%esp)
	movl	%esi, (%esp)
	call	__read
	testl	%eax, %eax
	jle	L16
	movl	___file_handle_modes, %edx
	testb	$8, (%edx,%esi)
	je	L16
	xorl	%ebx, %ebx
	.p2align 4,,7
L9:
	cmpb	$26, 0(%ebp,%ebx)
	je	L30
	incl	%ebx
	cmpl	%eax, %ebx
	jne	L9
L8:
	movl	%eax, 4(%esp)
	movl	%ebp, (%esp)
	call	___crlf2nl
	testl	%eax, %eax
	je	L31
	.p2align 4,,7
L16:
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
L28:
	.cfi_restore_state
	movl	28(%esp), %eax
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
L29:
	.cfi_restore_state
	movl	$16, _errno
	orl	$-1, %eax
	jmp	L16
	.p2align 4,,7
L30:
	movl	%ebx, %edx
	movl	$1, 8(%esp)
	subl	%eax, %edx
	movl	%esi, (%esp)
	movl	%edx, 4(%esp)
	call	___lseek
	testl	%ebx, %ebx
	jne	L11
	addl	$44, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 20
	xorl	%eax, %eax
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
L31:
	.cfi_restore_state
	movl	%edi, 8(%esp)
	movl	%ebp, 4(%esp)
	movl	%esi, (%esp)
	call	___read
	jmp	L16
L11:
	movl	%ebx, %eax
	jmp	L8
	.cfi_endproc
LFE5:
	.ident	"GCC: (GNU) 4.7.4"
