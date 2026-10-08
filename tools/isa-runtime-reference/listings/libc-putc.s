	.file	"putc.c"
	.section .text
	.p2align 4,,15
	.globl	_putc
_putc:
LFB8:
	.cfi_startproc
	pushl	%ebx
	.cfi_def_cfa_offset 8
	.cfi_offset 3, -8
	subl	$40, %esp
	.cfi_def_cfa_offset 48
	movl	___libc_write_termios_hook, %eax
	movl	48(%esp), %edx
	movl	52(%esp), %ebx
	testl	%eax, %eax
	je	L2
	movl	16(%ebx), %eax
	testb	$96, %ah
	je	L15
L2:
	cmpl	$10, %edx
	je	L16
L5:
	movl	(%ebx), %eax
	testl	%eax, %eax
	jle	L7
L19:
	movl	4(%ebx), %ecx
	decl	%eax
	movl	%eax, (%ebx)
	movb	%dl, (%ecx)
	incl	%ecx
	movl	%ecx, 4(%ebx)
	addl	$40, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 8
	movzbl	%dl, %eax
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L15:
	.cfi_restore_state
	testb	$1, %ah
	je	L17
L3:
	orb	$64, %ah
	cmpl	$10, %edx
	movl	%eax, 16(%ebx)
	jne	L5
L16:
	testl	$8448, 16(%ebx)
	jne	L5
	movl	20(%ebx), %eax
	movl	___file_handle_modes, %ecx
	testb	$8, (%ecx,%eax)
	je	L5
	movl	(%ebx), %eax
	testl	%eax, %eax
	jle	L18
	decl	%eax
	movl	%eax, (%ebx)
	movl	4(%ebx), %eax
	movb	$13, (%eax)
	incl	%eax
	movl	%eax, 4(%ebx)
	movl	(%ebx), %eax
	testl	%eax, %eax
	jg	L19
	.p2align 4,,7
L7:
	andl	$255, %edx
	movl	%ebx, 52(%esp)
	movl	%edx, 48(%esp)
	addl	$40, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 8
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 4
	jmp	__flsbuf
	.p2align 4,,7
L17:
	.cfi_restore_state
	movl	20(%ebx), %eax
	movl	%edx, 28(%esp)
	movl	%eax, (%esp)
	call	___isatty
	movl	28(%esp), %edx
	testl	%eax, %eax
	jne	L4
	movl	16(%ebx), %eax
	jmp	L3
	.p2align 4,,7
L4:
	orl	$8192, 16(%ebx)
	jmp	L2
	.p2align 4,,7
L18:
	movl	%ebx, 4(%esp)
	movl	$13, (%esp)
	movl	%edx, 28(%esp)
	call	__flsbuf
	movl	28(%esp), %edx
	jmp	L5
	.cfi_endproc
LFE8:
	.ident	"GCC: (GNU) 4.7.4"
