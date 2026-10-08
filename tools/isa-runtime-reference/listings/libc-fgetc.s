	.file	"fgetc.c"
	.section .text
	.p2align 4,,15
	.globl	_fgetc
_fgetc:
LFB8:
	.cfi_startproc
	pushl	%ebx
	.cfi_def_cfa_offset 8
	.cfi_offset 3, -8
	subl	$24, %esp
	.cfi_def_cfa_offset 32
	movl	___libc_read_termios_hook, %eax
	movl	32(%esp), %ebx
	testl	%eax, %eax
	je	L2
	movl	16(%ebx), %eax
	testb	$96, %ah
	je	L16
L2:
	movl	(%ebx), %eax
	testl	%eax, %eax
	jle	L5
L19:
	decl	%eax
	movl	4(%ebx), %edx
	movl	%eax, (%ebx)
	xorl	%eax, %eax
	movb	(%edx), %al
	incl	%edx
	movl	%edx, 4(%ebx)
	cmpl	$13, %eax
	je	L17
L12:
	addl	$24, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 8
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L16:
	.cfi_restore_state
	testb	$1, %ah
	je	L18
L3:
	orb	$64, %ah
	movl	%eax, 16(%ebx)
	movl	(%ebx), %eax
	testl	%eax, %eax
	jg	L19
L5:
	movl	%ebx, (%esp)
	call	__filbuf
	cmpl	$13, %eax
	jne	L12
	.p2align 4,,7
L17:
	testl	$8448, 16(%ebx)
	jne	L12
	movl	20(%ebx), %edx
	movl	___file_handle_modes, %ecx
	testb	$8, (%ecx,%edx)
	je	L12
	movl	(%ebx), %eax
	testl	%eax, %eax
	jle	L20
	movl	4(%ebx), %edx
	decl	%eax
	movl	%eax, (%ebx)
	xorl	%eax, %eax
	movb	(%edx), %al
	incl	%edx
	movl	%edx, 4(%ebx)
	addl	$24, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 8
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L18:
	.cfi_restore_state
	movl	20(%ebx), %eax
	movl	%eax, (%esp)
	call	___isatty
	testl	%eax, %eax
	jne	L4
	movl	16(%ebx), %eax
	jmp	L3
	.p2align 4,,7
L4:
	orl	$8192, 16(%ebx)
	jmp	L2
L20:
	movl	%ebx, 32(%esp)
	addl	$24, %esp
	.cfi_def_cfa_offset 8
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 4
	jmp	__filbuf
	.cfi_endproc
LFE8:
	.ident	"GCC: (GNU) 4.7.4"
