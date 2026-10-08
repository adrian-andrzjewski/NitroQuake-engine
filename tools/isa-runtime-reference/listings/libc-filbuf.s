	.file	"filbuf.c"
	.section .text
	.p2align 4,,15
	.globl	__filbuf
__filbuf:
LFB11:
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
	subl	$60, %esp
	.cfi_def_cfa_offset 80
	movl	80(%esp), %ebx
	movl	16(%ebx), %esi
	testl	$512, %esi
	je	L2
	orl	$8, %esi
	movl	%esi, 16(%ebx)
L2:
	testl	$8, %esi
	je	L60
	testl	$320, %esi
	jne	L27
	movl	%esi, %edi
	movl	8(%ebx), %eax
	andl	$-4097, %edi
	testl	%eax, %eax
	movl	%edi, 16(%ebx)
	je	L61
L5:
	movl	%edi, %ecx
	andl	$2, %ecx
	jne	L62
	cmpl	$___dj_stdin, %ebx
	je	L63
L8:
	movl	28(%ebx), %eax
	movl	12(%ebx), %edx
	cmpl	%edx, %eax
	ja	L64
	cmpl	$1024, %eax
	je	L65
L12:
	movl	$1, %esi
	testl	%ecx, %ecx
	je	L66
L13:
	andl	$8192, %edi
	je	L17
	movl	___libc_read_termios_hook, %eax
	testl	%eax, %eax
	je	L17
	movl	%ebx, 12(%esp)
	movl	%esi, 8(%esp)
	movl	8(%ebx), %edx
	movl	%edx, 4(%esp)
	movl	20(%ebx), %edx
	movl	%edx, (%esp)
	call	*%eax
	testl	%eax, %eax
	je	L17
L56:
	movl	28(%ebx), %eax
	movl	8(%ebx), %esi
	movl	16(%ebx), %edi
	cmpl	12(%ebx), %eax
	jae	L20
	addl	%eax, %eax
	movl	%eax, 28(%ebx)
L20:
	movl	%esi, 4(%ebx)
	testl	$2, %edi
	jne	L67
L21:
	movl	(%ebx), %eax
	decl	%eax
	movl	%eax, (%ebx)
	testl	%eax, %eax
	js	L68
	xorl	%eax, %eax
	movb	(%esi), %al
	incl	%esi
	movl	%esi, 4(%ebx)
L51:
	addl	$60, %esp
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
L17:
	.cfi_restore_state
	movl	%esi, 8(%esp)
	movl	8(%ebx), %eax
	movl	%eax, 4(%esp)
	movl	20(%ebx), %eax
	movl	%eax, (%esp)
	call	__read
	movl	16(%ebx), %edi
	movl	%eax, %ebp
	movl	%eax, (%ebx)
	testl	$8448, %edi
	je	L15
L57:
	movl	8(%ebx), %esi
L18:
	movl	28(%ebx), %eax
	cmpl	12(%ebx), %eax
	jae	L20
	addl	%eax, %eax
	movl	%eax, 28(%ebx)
	jmp	L20
	.p2align 4,,7
L67:
	movl	$0, 8(%ebx)
	jmp	L21
	.p2align 4,,7
L66:
	movl	%eax, %esi
	jmp	L13
	.p2align 4,,7
L64:
	movl	%edx, %eax
	movl	%edx, 28(%ebx)
	cmpl	$1024, %eax
	jne	L12
L65:
	cmpl	$1535, %edx
	jbe	L12
	movw	$1536, %ax
	jmp	L12
	.p2align 4,,7
L62:
	leal	47(%esp), %eax
	cmpl	$___dj_stdin, %ebx
	movl	%eax, 8(%ebx)
	jne	L8
L63:
	testb	$4, ___dj_stdout+16
	jne	L69
L9:
	testb	$4, ___dj_stderr+16
	jne	L10
L54:
	movl	___dj_stdin+16, %edi
	movl	%edi, %ecx
	andl	$2, %ecx
	jmp	L8
	.p2align 4,,7
L15:
	movl	20(%ebx), %edx
	movl	___file_handle_modes, %eax
	testb	$8, (%eax,%edx)
	je	L57
	testl	%ebp, %ebp
	jle	L57
	movl	8(%ebx), %esi
	movl	%ebp, 8(%esp)
	movl	$26, 4(%esp)
	movl	%esi, (%esp)
	movl	%edx, 28(%esp)
	call	_memchr
	movl	28(%esp), %edx
	testl	%eax, %eax
	je	L18
	subl	%esi, %eax
	movl	$1, 8(%esp)
	movl	%eax, %esi
	subl	%ebp, %eax
	movl	%eax, 4(%esp)
	movl	%edx, (%esp)
	call	___lseek
	movl	%esi, (%ebx)
	jmp	L56
	.p2align 4,,7
L61:
	testl	$2, %esi
	jne	L5
	movl	__go32_info_block+16, %ebp
	movl	%ebp, (%esp)
	call	_malloc
	movl	%eax, 8(%ebx)
	testl	%eax, %eax
	je	L70
	orl	$32, %edi
	movl	%ebp, 12(%ebx)
	movl	%edi, 16(%ebx)
	movl	$512, 28(%ebx)
	jmp	L5
	.p2align 4,,7
L10:
	movl	$___dj_stderr, (%esp)
	call	_fflush
	jmp	L54
	.p2align 4,,7
L69:
	movl	$___dj_stdout, (%esp)
	call	_fflush
	jmp	L9
	.p2align 4,,7
L60:
	orl	$128, %esi
	orl	$-1, %eax
	movl	%esi, 16(%ebx)
	jmp	L51
	.p2align 4,,7
L27:
	orl	$-1, %eax
	jmp	L51
L68:
	incl	%eax
	je	L71
	orl	$128, %edi
	movl	%edi, 16(%ebx)
L25:
	movl	$0, (%ebx)
	orl	$-1, %eax
	jmp	L51
L70:
	movl	%esi, %edi
	andl	$-4102, %edi
	orl	$2, %edi
	movl	%edi, 16(%ebx)
	jmp	L5
L71:
	testl	$512, %edi
	je	L58
	andl	$-9, %edi
L58:
	orl	$64, %edi
	movl	%edi, 16(%ebx)
	jmp	L25
	.cfi_endproc
LFE11:
	.ident	"GCC: (GNU) 4.7.4"
