	.file	"fputs.c"
	.section .text
	.p2align 4,,15
	.globl	_fputs
_fputs:
LFB8:
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
	subl	$16428, %esp
	.cfi_def_cfa_offset 16448
	movl	16452(%esp), %ebx
	movl	16448(%esp), %ebp
	movl	16(%ebx), %eax
	movl	%eax, %edi
	andl	$2, %edi
	je	L2
	andl	$-3, %eax
	movl	$16384, 12(%ebx)
	movl	%eax, 16(%ebx)
	leal	32(%esp), %eax
	movl	%eax, 8(%ebx)
	movl	%eax, 4(%ebx)
L2:
	xorl	%ecx, %ecx
L28:
	movb	0(%ebp), %dl
	incl	%ebp
	movsbl	%dl, %esi
	testl	%esi, %esi
	je	L10
L12:
	movl	___libc_write_termios_hook, %eax
	testl	%eax, %eax
	je	L3
	movl	16(%ebx), %eax
	testb	$96, %ah
	jne	L3
	testb	$1, %ah
	je	L32
L4:
	orb	$64, %ah
	movl	%eax, 16(%ebx)
L3:
	cmpl	$10, %esi
	je	L33
L6:
	movl	(%ebx), %eax
	testl	%eax, %eax
	jle	L8
L36:
	decl	%eax
	xorl	%ecx, %ecx
	movl	%eax, (%ebx)
	movl	4(%ebx), %eax
	movb	%dl, %cl
	movb	%dl, (%eax)
	incl	%eax
	movl	%eax, 4(%ebx)
	movb	0(%ebp), %dl
	incl	%ebp
	movsbl	%dl, %esi
	testl	%esi, %esi
	jne	L12
L10:
	testl	%edi, %edi
	jne	L34
L21:
	addl	$16428, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 20
	movl	%ecx, %eax
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
L33:
	.cfi_restore_state
	testl	$8448, 16(%ebx)
	jne	L6
	movl	20(%ebx), %eax
	movl	___file_handle_modes, %ecx
	testb	$8, (%ecx,%eax)
	je	L6
	movl	(%ebx), %eax
	testl	%eax, %eax
	jle	L35
	decl	%eax
	movl	%eax, (%ebx)
	movl	4(%ebx), %eax
	movb	$13, (%eax)
	incl	%eax
	movl	%eax, 4(%ebx)
	movl	(%ebx), %eax
	testl	%eax, %eax
	jg	L36
	.p2align 4,,7
L8:
	andl	$255, %esi
	movl	%ebx, 4(%esp)
	movl	%esi, (%esp)
	call	__flsbuf
	movl	%eax, %ecx
	cmpl	$-1, %eax
	jne	L28
	testl	%edi, %edi
	je	L21
L34:
	movl	%ebx, (%esp)
	movl	%ecx, 28(%esp)
	call	_fflush
	movl	28(%esp), %ecx
	incl	%eax
	je	L37
L14:
	orl	$2, 16(%ebx)
	movl	$0, 8(%ebx)
	movl	$0, 12(%ebx)
	movl	$0, (%ebx)
	addl	$16428, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 20
	movl	%ecx, %eax
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
L32:
	.cfi_restore_state
	movl	20(%ebx), %eax
	movb	%dl, 28(%esp)
	movl	%eax, (%esp)
	call	___isatty
	movb	28(%esp), %dl
	testl	%eax, %eax
	jne	L5
	movl	16(%ebx), %eax
	jmp	L4
	.p2align 4,,7
L5:
	orl	$8192, 16(%ebx)
	jmp	L3
	.p2align 4,,7
L35:
	movl	%ebx, 4(%esp)
	movl	$13, (%esp)
	movb	%dl, 28(%esp)
	call	__flsbuf
	movb	28(%esp), %dl
	jmp	L6
	.p2align 4,,7
L37:
	orl	$-1, %ecx
	jmp	L14
	.cfi_endproc
LFE8:
	.ident	"GCC: (GNU) 4.7.4"
