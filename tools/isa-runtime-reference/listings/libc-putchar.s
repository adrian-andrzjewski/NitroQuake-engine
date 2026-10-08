	.file	"putchar.c"
	.section .text
	.p2align 4,,15
	.globl	_putchar
_putchar:
LFB8:
	.cfi_startproc
	pushl	%ebx
	.cfi_def_cfa_offset 8
	.cfi_offset 3, -8
	subl	$24, %esp
	.cfi_def_cfa_offset 32
	movl	___libc_write_termios_hook, %eax
	movl	32(%esp), %ebx
	testl	%eax, %eax
	je	L2
	movl	___dj_stdout+16, %eax
	testb	$96, %ah
	je	L15
L2:
	cmpl	$10, %ebx
	je	L16
L5:
	movl	___dj_stdout, %eax
	testl	%eax, %eax
	jle	L7
L19:
	movl	___dj_stdout+4, %edx
	decl	%eax
	movl	%eax, ___dj_stdout
	movb	%bl, (%edx)
	incl	%edx
	movl	%edx, ___dj_stdout+4
	addl	$24, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 8
	movzbl	%bl, %eax
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
	cmpl	$10, %ebx
	movl	%eax, ___dj_stdout+16
	jne	L5
L16:
	testl	$8448, ___dj_stdout+16
	jne	L5
	movl	___dj_stdout+20, %eax
	movl	___file_handle_modes, %edx
	testb	$8, (%edx,%eax)
	je	L5
	movl	___dj_stdout, %eax
	testl	%eax, %eax
	jle	L18
	decl	%eax
	movl	%eax, ___dj_stdout
	movl	___dj_stdout+4, %eax
	movb	$13, (%eax)
	incl	%eax
	movl	%eax, ___dj_stdout+4
	movl	___dj_stdout, %eax
	testl	%eax, %eax
	jg	L19
	.p2align 4,,7
L7:
	andl	$255, %ebx
	movl	$___dj_stdout, 4(%esp)
	movl	%ebx, (%esp)
	call	__flsbuf
	addl	$24, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 8
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L17:
	.cfi_restore_state
	movl	___dj_stdout+20, %eax
	movl	%eax, (%esp)
	call	___isatty
	testl	%eax, %eax
	jne	L4
	movl	___dj_stdout+16, %eax
	jmp	L3
	.p2align 4,,7
L4:
	orl	$8192, ___dj_stdout+16
	jmp	L2
	.p2align 4,,7
L18:
	movl	$___dj_stdout, 4(%esp)
	movl	$13, (%esp)
	call	__flsbuf
	jmp	L5
	.cfi_endproc
LFE8:
	.ident	"GCC: (GNU) 4.7.4"
