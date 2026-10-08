	.file	"fread.c"
	.section .text
	.p2align 4,,15
	.globl	_fread
_fread:
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
	movl	56(%esp), %esi
	movl	52(%esp), %ebp
	imull	%esi, %ebp
	movl	60(%esp), %ebx
	movl	28(%ebx), %eax
	cmpl	%eax, %ebp
	jbe	L5
	movl	12(%ebx), %edx
	cmpl	%eax, %edx
	ja	L50
	jmp	L5
	.p2align 4,,7
L70:
	addl	%eax, %eax
	cmpl	%eax, %ebp
	jbe	L67
L7:
	cmpl	%edx, %eax
	jae	L67
L50:
	cmpl	$511, %eax
	ja	L70
	movl	$1024, %eax
	cmpl	%eax, %ebp
	ja	L7
L67:
	movl	%eax, 28(%ebx)
L5:
	movl	___libc_read_termios_hook, %edi
	testl	%edi, %edi
	je	L71
	movl	16(%ebx), %eax
	testb	$96, %ah
	je	L72
L9:
	movl	%ebp, %edi
	testb	$33, %ah
	jne	L11
	movl	20(%ebx), %eax
	movl	___file_handle_modes, %edx
	testb	$8, (%edx,%eax)
	je	L11
	movl	48(%esp), %ebp
L63:
	testl	%edi, %edi
	jle	L15
	movl	(%ebx), %eax
	cmpl	%eax, %edi
	jg	L48
L20:
	testl	%edi, %edi
	jle	L15
	.p2align 4,,7
L68:
	testl	%eax, %eax
	jle	L63
	movl	4(%ebx), %edx
	movb	(%edx), %al
	incl	%edx
	movl	%edx, 4(%ebx)
	cmpb	$13, %al
	je	L27
	movb	%al, 0(%ebp)
	incl	%ebp
	movl	(%ebx), %eax
	decl	%eax
	decl	%edi
	movl	%eax, (%ebx)
	jne	L68
L15:
	movl	52(%esp), %eax
	testl	%eax, %eax
	je	L34
	movl	52(%esp), %edx
	leal	-1(%edi,%edx), %eax
	xorl	%edx, %edx
	divl	52(%esp)
	addl	$28, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 20
	subl	%eax, %esi
	movl	%esi, %eax
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
L11:
	.cfi_restore_state
	testl	%ebp, %ebp
	jle	L15
	movl	(%ebx), %eax
	cmpl	%eax, %ebp
	movl	48(%esp), %ebp
	jg	L19
L13:
	movl	4(%ebx), %eax
	movl	%edi, 8(%esp)
	movl	%ebp, (%esp)
	movl	%eax, 4(%esp)
	call	_memcpy
	movl	4(%ebx), %edx
	movl	(%ebx), %ecx
	addl	%edi, %edx
	subl	%edi, %ecx
	movl	%edx, 4(%ebx)
	movl	%ecx, (%ebx)
	addl	$28, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 20
	movl	%esi, %eax
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
L21:
	.cfi_restore_state
	movl	%ebx, (%esp)
	call	__filbuf
	cmpl	$-1, %eax
	je	L15
	cmpl	$13, %eax
	je	L24
	movb	%al, 0(%ebp)
	decl	%edi
	incl	%ebp
L24:
	movl	(%ebx), %eax
	cmpl	%eax, %edi
	jle	L20
	testl	%edi, %edi
	jle	L15
L48:
	testl	%eax, %eax
	jle	L21
	.p2align 4,,7
L49:
	movl	4(%ebx), %edx
	movb	(%edx), %al
	incl	%edx
	movl	%edx, 4(%ebx)
	cmpb	$13, %al
	je	L22
	movb	%al, 0(%ebp)
	decl	%edi
	incl	%ebp
L22:
	movl	(%ebx), %edx
	decl	%edx
	movl	%edx, (%ebx)
	testl	%edx, %edx
	jg	L49
	jmp	L21
	.p2align 4,,7
L27:
	movl	(%ebx), %eax
	decl	%eax
	movl	%eax, (%ebx)
	jmp	L68
	.p2align 4,,7
L19:
	testl	%eax, %eax
	jle	L14
	movl	4(%ebx), %edx
	movl	%ebp, (%esp)
	movl	%eax, 8(%esp)
	movl	%edx, 4(%esp)
	call	_memcpy
	movl	(%ebx), %eax
	addl	%eax, %ebp
	subl	%eax, %edi
L14:
	movl	%ebx, (%esp)
	call	__filbuf
	cmpl	$-1, %eax
	je	L15
	movb	%al, 0(%ebp)
	decl	%edi
	movl	(%ebx), %eax
	incl	%ebp
	cmpl	%eax, %edi
	jle	L13
	testl	%edi, %edi
	jg	L19
	jmp	L15
L34:
	addl	$28, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 20
	xorl	%esi, %esi
	movl	%esi, %eax
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
L72:
	.cfi_restore_state
	movl	20(%ebx), %eax
	movl	%eax, (%esp)
	call	___isatty
	testl	%eax, %eax
	movl	16(%ebx), %eax
	je	L10
	orb	$32, %ah
	movl	%eax, 16(%ebx)
	jmp	L9
L10:
	orb	$64, %ah
	movl	%eax, 16(%ebx)
	jmp	L9
L71:
	movl	16(%ebx), %eax
	jmp	L9
	.cfi_endproc
LFE8:
	.ident	"GCC: (GNU) 4.7.4"
