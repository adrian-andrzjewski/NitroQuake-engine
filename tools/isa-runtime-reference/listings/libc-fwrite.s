	.file	"fwrite.c"
	.section .text
	.p2align 4,,15
	.globl	_fwrite
_fwrite:
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
	subl	$44, %esp
	.cfi_def_cfa_offset 64
	movl	___libc_write_termios_hook, %ecx
	movl	76(%esp), %ebx
	movl	72(%esp), %edi
	testl	%ecx, %ecx
	movl	16(%ebx), %eax
	je	L3
	testb	$96, %ah
	je	L70
L3:
	movl	68(%esp), %esi
	imull	%edi, %esi
	testb	$33, %ah
	jne	L5
	movl	20(%ebx), %edx
	movl	___file_handle_modes, %ecx
	testb	$8, (%ecx,%edx)
	je	L5
	movl	64(%esp), %ebp
	testb	$4, %al
	je	L71
	testl	%esi, %esi
	jg	L54
	jmp	L10
	.p2align 4,,7
L73:
	cmpb	$10, %al
	je	L40
	movl	4(%ebx), %edx
	incl	%ebp
	movb	%al, (%edx)
	incl	%edx
	movl	%edx, 4(%ebx)
L24:
	decl	%esi
	je	L10
L54:
	movl	12(%ebx), %edx
	negl	%edx
	cmpb	$10, 0(%ebp)
	je	L72
L19:
	movl	(%ebx), %eax
	decl	%eax
	movl	%eax, (%ebx)
	cmpl	%eax, %edx
	movb	0(%ebp), %al
	jl	L73
L23:
	andl	$255, %eax
	movl	%ebx, 4(%esp)
	movl	%eax, (%esp)
	incl	%ebp
	call	__flsbuf
	incl	%eax
	jne	L24
	.p2align 4,,7
L10:
	movl	68(%esp), %eax
	testl	%eax, %eax
	je	L41
	movl	68(%esp), %edx
	leal	-1(%esi,%edx), %eax
	xorl	%edx, %edx
	divl	68(%esp)
	addl	$44, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 20
	subl	%eax, %edi
	movl	%edi, %eax
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
L5:
	.cfi_restore_state
	testb	$4, %al
	je	L36
	movl	64(%esp), %ebp
	testl	%esi, %esi
	jg	L56
	jmp	L10
	.p2align 4,,7
L74:
	movb	0(%ebp), %al
	cmpb	$10, %al
	je	L38
	movl	4(%ebx), %ecx
	incl	%ebp
	movb	%al, (%ecx)
	incl	%ecx
	movl	%ecx, 4(%ebx)
L9:
	decl	%esi
	je	L10
L56:
	movl	(%ebx), %ecx
	movl	12(%ebx), %eax
	decl	%ecx
	negl	%eax
	movl	%ecx, (%ebx)
	cmpl	%ecx, %eax
	jl	L74
	movsbl	0(%ebp), %eax
L8:
	movl	%ebx, 4(%esp)
	movl	%eax, (%esp)
	call	__flsbuf
	incl	%ebp
	incl	%eax
	jne	L9
	jmp	L10
	.p2align 4,,7
L36:
	testl	%esi, %esi
	jle	L10
	movl	(%ebx), %eax
	movl	64(%esp), %ebp
	cmpl	%esi, %eax
	jl	L17
L12:
	movl	4(%ebx), %eax
	movl	%esi, 8(%esp)
	movl	%ebp, 4(%esp)
	movl	%eax, (%esp)
	call	_memcpy
	movl	4(%ebx), %edx
	movl	(%ebx), %ecx
	addl	%esi, %edx
	subl	%esi, %ecx
	movl	%edx, 4(%ebx)
	movl	%ecx, (%ebx)
	addl	$44, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 20
	movl	%edi, %eax
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
	testl	%eax, %eax
	jle	L13
	movl	4(%ebx), %ecx
	movl	%ebp, 4(%esp)
	movl	%eax, 8(%esp)
	movl	%ecx, (%esp)
	call	_memcpy
	movl	(%ebx), %eax
	movl	4(%ebx), %edx
	addl	%eax, %ebp
	addl	%eax, %edx
	subl	%eax, %esi
	movl	%edx, 4(%ebx)
L13:
	xorl	%eax, %eax
	movb	0(%ebp), %al
	movl	%ebx, 4(%esp)
	movl	%eax, (%esp)
	incl	%ebp
	call	__flsbuf
	incl	%eax
	je	L10
	decl	%esi
	movl	(%ebx), %eax
	cmpl	%eax, %esi
	jle	L12
	testl	%esi, %esi
	jg	L17
	jmp	L10
	.p2align 4,,7
L71:
	testl	%esi, %esi
	jg	L55
	jmp	L10
	.p2align 4,,7
L27:
	movl	(%ebx), %eax
	decl	%eax
	movl	%eax, (%ebx)
	testl	%eax, %eax
	js	L30
L75:
	movl	4(%ebx), %eax
	movb	0(%ebp), %dl
	incl	%ebp
	movb	%dl, (%eax)
	incl	%eax
	movl	%eax, 4(%ebx)
L31:
	decl	%esi
	je	L10
L55:
	cmpb	$10, 0(%ebp)
	jne	L27
	movl	(%ebx), %eax
	decl	%eax
	movl	%eax, (%ebx)
	testl	%eax, %eax
	js	L28
	movl	4(%ebx), %eax
	movb	$13, (%eax)
	incl	%eax
	movl	%eax, 4(%ebx)
	movl	(%ebx), %eax
	decl	%eax
	movl	%eax, (%ebx)
	testl	%eax, %eax
	jns	L75
L30:
	xorl	%eax, %eax
	movb	0(%ebp), %al
	movl	%ebx, 4(%esp)
	movl	%eax, (%esp)
	incl	%ebp
	call	__flsbuf
	incl	%eax
	jne	L31
	jmp	L10
	.p2align 4,,7
L72:
	movl	(%ebx), %eax
	decl	%eax
	movl	%eax, (%ebx)
	cmpl	%eax, %edx
	jge	L20
	movl	4(%ebx), %eax
	movb	$13, (%eax)
	incl	%eax
	movl	%eax, 4(%ebx)
	jmp	L19
	.p2align 4,,7
L40:
	movb	$10, %al
	jmp	L23
	.p2align 4,,7
L38:
	movl	$10, %eax
	jmp	L8
	.p2align 4,,7
L20:
	movl	%ebx, 4(%esp)
	movl	$13, (%esp)
	movl	%edx, 28(%esp)
	call	__flsbuf
	movl	28(%esp), %edx
	incl	%eax
	jne	L19
	jmp	L10
	.p2align 4,,7
L41:
	addl	$44, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 20
	xorl	%edi, %edi
	movl	%edi, %eax
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
	movl	%ebx, 4(%esp)
	movl	$13, (%esp)
	call	__flsbuf
	incl	%eax
	jne	L27
	jmp	L10
	.p2align 4,,7
L70:
	movl	20(%ebx), %eax
	movl	%eax, (%esp)
	call	___isatty
	testl	%eax, %eax
	movl	16(%ebx), %eax
	je	L4
	orb	$32, %ah
	movl	%eax, 16(%ebx)
	jmp	L3
	.p2align 4,,7
L4:
	orb	$64, %ah
	movl	%eax, 16(%ebx)
	jmp	L3
	.cfi_endproc
LFE8:
	.ident	"GCC: (GNU) 4.7.4"
