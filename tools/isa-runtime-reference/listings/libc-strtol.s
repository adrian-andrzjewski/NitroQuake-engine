	.file	"strtol.c"
	.section .text
	.p2align 4,,15
	.globl	_strtol
_strtol:
LFB0:
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
	subl	$12, %esp
	.cfi_def_cfa_offset 32
	movl	40(%esp), %edi
	movl	32(%esp), %ecx
	.p2align 4,,7
L2:
	movb	(%ecx), %bl
	xorl	%eax, %eax
	movb	%bl, %al
	incl	%ecx
	testb	$1, ___dj_ctype_flags+3(%eax,%eax)
	jne	L2
	cmpb	$45, %bl
	je	L45
	movl	$0, 4(%esp)
	cmpb	$43, %bl
	je	L46
L4:
	movl	%edi, (%esp)
	testl	$-17, %edi
	jne	L9
	testl	%edi, %edi
	sete	%al
	cmpb	$48, %bl
	je	L47
	testb	%al, %al
	je	L43
	movl	$10, (%esp)
	movl	$10, %edi
L9:
	cmpl	$1, 4(%esp)
	sbbl	%eax, %eax
	xorl	%edx, %edx
	addl	$-2147483648, %eax
	xorl	%ebp, %ebp
	divl	(%esp)
	movl	%edx, 8(%esp)
	xorl	%esi, %esi
	jmp	L17
	.p2align 4,,7
L49:
	subl	$48, %ebx
	xorl	%edx, %edx
	movb	%bl, %dl
	cmpl	%edx, %edi
	jle	L13
L50:
	cmpl	%eax, %esi
	ja	L32
	shrl	$31, %ebp
	jne	L32
	cmpl	%eax, %esi
	je	L48
L16:
	movl	(%esp), %ebp
	andl	$255, %ebx
	imull	%ebp, %esi
	movl	$1, %ebp
	addl	%ebx, %esi
L15:
	movb	(%ecx), %bl
	incl	%ecx
L17:
	xorl	%edx, %edx
	movb	%bl, %dl
	movw	___dj_ctype_flags+2(%edx,%edx), %dx
	testb	$8, %dl
	jne	L49
	testb	$2, %dl
	je	L13
	andl	$512, %edx
	cmpw	$1, %dx
	sbbl	%edx, %edx
	andl	$32, %edx
	addl	$55, %edx
	subl	%edx, %ebx
	xorl	%edx, %edx
	movb	%bl, %dl
	cmpl	%edx, %edi
	jg	L50
L13:
	cmpl	$-1, %ebp
	je	L51
	movl	4(%esp), %ebx
	testl	%ebx, %ebx
	jne	L52
L22:
	movl	36(%esp), %edx
	movl	%esi, %eax
	testl	%edx, %edx
	je	L41
	testl	%ebp, %ebp
	jne	L20
L25:
	movl	36(%esp), %ecx
	movl	32(%esp), %edx
	movl	%edx, (%ecx)
L41:
	addl	$12, %esp
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
L32:
	.cfi_restore_state
	orl	$-1, %ebp
	jmp	L15
	.p2align 4,,7
L48:
	orl	$-1, %ebp
	cmpl	%edx, 8(%esp)
	jl	L15
	jmp	L16
	.p2align 4,,7
L51:
	cmpl	$1, 4(%esp)
	movl	36(%esp), %esi
	movl	$2, _errno
	sbbl	%eax, %eax
	addl	$-2147483648, %eax
	testl	%esi, %esi
	je	L41
L20:
	decl	%ecx
	movl	%ecx, 32(%esp)
	jmp	L25
	.p2align 4,,7
L52:
	negl	%esi
	jmp	L22
	.p2align 4,,7
L45:
	movb	(%ecx), %bl
	movl	$1, 4(%esp)
	incl	%ecx
	jmp	L4
	.p2align 4,,7
L46:
	movb	(%ecx), %bl
	incl	%ecx
	jmp	L4
L47:
	movb	(%ecx), %dl
	andl	$-33, %edx
	cmpb	$88, %dl
	je	L53
	testb	%al, %al
	je	L43
	movl	$8, (%esp)
	movl	$8, %edi
	jmp	L9
	.p2align 4,,7
L53:
	movb	1(%ecx), %bl
	movl	$16, (%esp)
	addl	$2, %ecx
	movl	$16, %edi
	jmp	L9
L43:
	movl	%edi, (%esp)
	jmp	L9
	.cfi_endproc
LFE0:
	.ident	"GCC: (GNU) 4.7.4"
