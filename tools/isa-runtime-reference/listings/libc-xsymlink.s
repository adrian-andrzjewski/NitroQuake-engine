	.file	"xsymlink.c"
	.section .text
LC0:
	.ascii "/\\\0"
	.p2align 4,,15
_advance:
LFB4:
	.cfi_startproc
	pushl	%edi
	.cfi_def_cfa_offset 8
	.cfi_offset 7, -8
	pushl	%esi
	.cfi_def_cfa_offset 12
	.cfi_offset 6, -12
	pushl	%ebx
	.cfi_def_cfa_offset 16
	.cfi_offset 3, -16
	movl	%eax, %edi
	subl	$16, %esp
	.cfi_def_cfa_offset 32
	movl	%edx, %esi
	movl	$LC0, 4(%esp)
	movl	(%eax), %eax
	incl	%eax
	movl	%eax, (%esp)
	call	_strpbrk
	movl	%eax, (%edi)
	testl	%eax, %eax
	je	L5
	movb	(%eax), %dl
	cmpb	$92, %dl
	jne	L21
L9:
	leal	1(%eax), %ecx
	.p2align 4,,7
L17:
	movl	%ecx, (%edi)
	movb	(%ecx), %bl
	incl	%ecx
	cmpb	$92, %bl
	je	L17
	cmpb	$47, %bl
	je	L17
L5:
	movl	(%esi), %ebx
	movb	(%ebx), %al
	cmpb	$47, %al
	jne	L22
L3:
	leal	1(%ebx), %eax
	.p2align 4,,7
L18:
	movl	%eax, (%esi)
	movl	%eax, %ebx
	movb	(%eax), %cl
	incl	%eax
	cmpb	$92, %cl
	je	L18
	cmpb	$47, %cl
	je	L18
L4:
	movl	%ebx, (%esp)
	movl	$LC0, 4(%esp)
	call	_strpbrk
	movl	%eax, (%esi)
	addl	$16, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 16
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 12
	popl	%esi
	.cfi_restore 6
	.cfi_def_cfa_offset 8
	popl	%edi
	.cfi_restore 7
	.cfi_def_cfa_offset 4
	ret
L22:
	.cfi_restore_state
	cmpb	$92, %al
	je	L3
	jmp	L4
L21:
	cmpb	$47, %dl
	je	L9
	jmp	L5
	.cfi_endproc
LFE4:
LC1:
	.ascii "/dev/env/\0"
	.p2align 4,,15
	.globl	___solve_symlinks
___solve_symlinks:
LFB3:
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
	subl	$588, %esp
	.cfi_def_cfa_offset 608
	movl	612(%esp), %eax
	movl	608(%esp), %ebx
	testl	%eax, %eax
	je	L65
	testl	%ebx, %ebx
	je	L65
	movl	%ebx, (%esp)
	call	_strlen
	cmpl	$260, %eax
	jbe	L27
	movl	$19, _errno
	xorl	%eax, %eax
L66:
	addl	$588, %esp
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
L65:
	.cfi_restore_state
	movl	$14, _errno
	addl	$588, %esp
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
L27:
	.cfi_restore_state
	incl	%eax
	movl	%ebx, 4(%esp)
	movl	%eax, 8(%esp)
	movl	612(%esp), %eax
	movl	%eax, (%esp)
	call	_memcpy
	leal	54(%esp), %eax
	movl	$260, 12(%esp)
	movl	%eax, 8(%esp)
	movl	$0, 4(%esp)
	movl	%ebx, (%esp)
	movl	_errno, %esi
	movl	%eax, 16(%esp)
	call	___internal_readlink
	incl	%eax
	je	L70
L28:
	movl	612(%esp), %eax
	movl	$LC0, 4(%esp)
	movl	%eax, (%esp)
	movl	%esi, _errno
	movl	%eax, 44(%esp)
	call	_strpbrk
	movl	%eax, 48(%esp)
	cmpl	%eax, 612(%esp)
	je	L71
L29:
	testl	%eax, %eax
	je	L72
L30:
	movl	612(%esp), %ebx
	movl	$0, 20(%esp)
	leal	315(%esp), %ebp
L31:
	cmpb	$0, (%ebx)
	je	L63
	movl	612(%esp), %eax
	movl	%ebp, (%esp)
	movl	%eax, 4(%esp)
	call	_strcpy
	movl	48(%esp), %eax
	cmpb	$0, (%eax)
	je	L32
	movl	612(%esp), %edi
	subl	%edi, %eax
	movb	$0, 315(%esp,%eax)
L32:
	movl	_errno, %eax
	xorl	%esi, %esi
	movl	%eax, 24(%esp)
	movl	$0, 28(%esp)
	.p2align 4,,7
L56:
	leal	54(%esp), %eax
	movl	$260, 12(%esp)
	movl	%eax, 8(%esp)
	movl	$0, 4(%esp)
	movl	%ebp, (%esp)
	call	___internal_readlink
	movl	%eax, %ebx
	cmpl	$-1, %eax
	je	L33
	cmpl	$8, 20(%esp)
	je	L73
	movl	20(%esp), %esi
	movb	$0, 54(%esp,%eax)
	incl	%esi
	movl	$LC1, %edi
	movl	%esi, 20(%esp)
	movl	$9, %ecx
	movl	16(%esp), %esi
	leal	54(%esp), %eax
	repe cmpsb
	je	L35
	movl	%eax, 4(%esp)
	movl	%ebp, (%esp)
	call	_strcpy
L36:
	cmpl	$2, %ebx
	jle	L37
	cmpb	$58, 316(%esp)
	je	L60
L39:
	movb	315(%esp), %al
	cmpb	$92, %al
	je	L60
	cmpb	$47, %al
	jne	L40
L60:
	movl	$1, 28(%esp)
L38:
	movl	$1, %esi
	jmp	L56
	.p2align 4,,7
L37:
	testl	%ebx, %ebx
	jg	L39
	movb	315(%esp), %al
L40:
	movl	%ebp, %ebx
	cmpb	$46, %al
	je	L74
L41:
	movl	%ebp, (%esp)
	call	_strlen
	addl	%ebp, %eax
	jmp	L42
	.p2align 4,,7
L75:
	cmpb	$47, %dl
	je	L43
	incl	%ebx
L42:
	cmpl	%ebx, %eax
	jbe	L38
	movb	(%ebx), %dl
	cmpb	$92, %dl
	jne	L75
L43:
	movl	24(%esp), %eax
	movl	$1, %ebx
	movl	%eax, _errno
L54:
	movl	48(%esp), %eax
	cmpb	$0, (%eax)
	jne	L76
	movb	$0, 54(%esp)
L46:
	movl	28(%esp), %ecx
	testl	%ecx, %ecx
	je	L47
	movl	612(%esp), %eax
	movl	%ebp, 4(%esp)
	movl	%eax, (%esp)
	call	_strcpy
L48:
	cmpb	$0, 54(%esp)
	jne	L77
L49:
	movl	28(%esp), %eax
	testl	%eax, %eax
	je	L78
	movl	612(%esp), %eax
	movl	$LC0, 4(%esp)
	movl	%eax, (%esp)
	movl	%eax, 44(%esp)
	call	_strpbrk
	movl	612(%esp), %ebx
	movl	%eax, 48(%esp)
L50:
	testl	%eax, %eax
	je	L79
L52:
	testl	%ebx, %ebx
	jne	L31
L63:
	movl	$1, %eax
	jmp	L66
	.p2align 4,,7
L35:
	movl	%eax, (%esp)
	call	__put_path
	movl	__go32_info_block+12, %eax
	movl	%ebp, 8(%esp)
	movl	$260, 4(%esp)
	movl	%eax, (%esp)
	call	___dosmemget
	jmp	L36
	.p2align 4,,7
L33:
	movl	24(%esp), %eax
	testl	%esi, %esi
	movl	%eax, _errno
	jne	L80
L51:
	leal	44(%esp), %eax
	leal	48(%esp), %edx
	call	_advance
	movl	48(%esp), %eax
	movl	44(%esp), %ebx
	jmp	L50
	.p2align 4,,7
L74:
	movb	316(%esp), %al
	cmpb	$92, %al
	je	L62
	cmpb	$47, %al
	jne	L41
L62:
	leal	317(%esp), %ebx
	jmp	L41
	.p2align 4,,7
L80:
	xorl	%ebx, %ebx
	jmp	L54
L70:
	cmpl	$14, _errno
	jne	L28
	movl	%esi, _errno
	movl	$1, %eax
	jmp	L66
	.p2align 4,,7
L73:
	movl	$39, _errno
	addl	$588, %esp
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
L78:
	.cfi_restore_state
	testl	%ebx, %ebx
	je	L51
	movl	44(%esp), %ebx
	movl	$LC0, 4(%esp)
	leal	1(%ebx), %eax
	movl	%eax, (%esp)
	call	_strpbrk
	movl	%eax, 48(%esp)
	jmp	L50
L47:
	movl	%ebp, (%esp)
	call	_strlen
	movl	%ebp, 4(%esp)
	incl	%eax
	movl	%eax, 8(%esp)
	movl	44(%esp), %eax
	movl	%eax, (%esp)
	call	_memcpy
	jmp	L48
L76:
	movl	%eax, 4(%esp)
	leal	54(%esp), %eax
	movl	%eax, (%esp)
	call	_strcpy
	jmp	L46
L71:
	movl	612(%esp), %eax
	movl	$LC0, 4(%esp)
	incl	%eax
	movl	%eax, (%esp)
	call	_strpbrk
	movl	%eax, 48(%esp)
	jmp	L29
L72:
	movl	612(%esp), %eax
	movl	%eax, (%esp)
	call	_strlen
	movl	612(%esp), %ebp
	addl	%ebp, %eax
	movl	%eax, 48(%esp)
	jmp	L30
L79:
	movl	612(%esp), %eax
	movl	%eax, (%esp)
	call	_strlen
	movl	612(%esp), %edx
	addl	%edx, %eax
	movl	%eax, 48(%esp)
	jmp	L52
L77:
	leal	54(%esp), %eax
	movl	%eax, 4(%esp)
	movl	612(%esp), %eax
	movl	%eax, (%esp)
	call	_strcat
	jmp	L49
	.cfi_endproc
LFE3:
	.ident	"GCC: (GNU) 4.7.4"
