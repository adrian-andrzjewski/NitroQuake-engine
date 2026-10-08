	.file	"fgets.c"
	.section .text
	.p2align 4,,15
	.globl	_fgets
_fgets:
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
	subl	$28, %esp
	.cfi_def_cfa_offset 48
	xorl	%eax, %eax
	movl	48(%esp), %esi
	movl	52(%esp), %edi
	incl	%esi
	decl	%edi
	movl	56(%esp), %ebx
	testl	%edi, %edi
	leal	-1(%esi), %ebp
	jle	L33
	.p2align 4,,7
L4:
	movl	___libc_read_termios_hook, %eax
	testl	%eax, %eax
	je	L6
	movl	16(%ebx), %eax
	testb	$96, %ah
	jne	L6
	testb	$1, %ah
	je	L34
L7:
	orb	$64, %ah
	movl	%eax, 16(%ebx)
L6:
	movl	(%ebx), %eax
	testl	%eax, %eax
	jle	L9
	movl	4(%ebx), %edx
	decl	%eax
	movl	%eax, (%ebx)
	xorl	%eax, %eax
	movb	(%edx), %al
	incl	%edx
	movl	%edx, 4(%ebx)
L10:
	cmpl	$13, %eax
	je	L35
L11:
	cmpl	$-1, %eax
	je	L36
L15:
	movl	%esi, %ebp
	movb	%al, -1(%esi)
	cmpl	$10, %eax
	je	L3
	incl	%esi
L38:
	decl	%edi
	leal	-1(%esi), %ebp
	testl	%edi, %edi
	jg	L4
L33:
	incl	%eax
	sete	%al
L5:
	cmpl	48(%esp), %ebp
	jne	L3
	testb	%al, %al
	jne	L21
	.p2align 4,,7
L3:
	movb	$0, 0(%ebp)
	movl	48(%esp), %eax
	addl	$28, %esp
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
L35:
	.cfi_restore_state
	testl	$8448, 16(%ebx)
	jne	L12
	movl	20(%ebx), %edx
	movl	___file_handle_modes, %ecx
	testb	$8, (%ecx,%edx)
	je	L12
	movl	(%ebx), %eax
	testl	%eax, %eax
	jle	L37
	decl	%eax
	movl	4(%ebx), %edx
	movl	%eax, (%ebx)
	xorl	%eax, %eax
	movb	(%edx), %al
	incl	%edx
	movl	%edx, 4(%ebx)
	cmpl	$-1, %eax
	jne	L15
	.p2align 4,,7
L36:
	movb	$1, %al
	jmp	L5
	.p2align 4,,7
L12:
	movb	$13, -1(%esi)
	incl	%esi
	jmp	L38
	.p2align 4,,7
L9:
	movl	%ebx, (%esp)
	call	__filbuf
	jmp	L10
	.p2align 4,,7
L34:
	movl	20(%ebx), %eax
	movl	%eax, (%esp)
	call	___isatty
	testl	%eax, %eax
	je	L39
	orl	$8192, 16(%ebx)
	jmp	L6
	.p2align 4,,7
L39:
	movl	16(%ebx), %eax
	jmp	L7
L21:
	movl	$0, 48(%esp)
	movl	48(%esp), %eax
	addl	$28, %esp
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
L37:
	.cfi_restore_state
	movl	%ebx, (%esp)
	call	__filbuf
	jmp	L11
	.cfi_endproc
LFE8:
	.ident	"GCC: (GNU) 4.7.4"
