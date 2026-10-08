	.file	"sdirlink.c"
	.section .text
	.p2align 4,,15
	.globl	___solve_dir_symlinks
___solve_dir_symlinks:
LFB0:
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
	subl	$288, %esp
	.cfi_def_cfa_offset 304
	movl	308(%esp), %ebx
	movl	304(%esp), %eax
	testl	%ebx, %ebx
	je	L16
	testl	%eax, %eax
	je	L16
	movb	(%eax), %dl
	testb	%dl, %dl
	je	L24
	cmpb	$92, %dl
	je	L6
	cmpb	$47, %dl
	je	L6
	movb	1(%eax), %dl
	xorl	%ecx, %ecx
	cmpb	$58, %dl
	je	L25
L8:
	testl	%ecx, %ecx
	jne	L10
	leal	28(%esp), %edi
	movl	%eax, 4(%esp)
	movl	%edi, (%esp)
	call	_strcpy
	movl	%edi, (%esp)
	call	___basename
	movl	%eax, %esi
	cmpb	$0, (%eax)
	jne	L12
	cmpb	$58, -1(%eax)
	je	L14
	movb	$0, -1(%eax)
	movl	%edi, (%esp)
	call	___basename
	movl	%eax, %esi
L12:
	cmpl	%edi, %esi
	je	L14
	cmpb	$58, -1(%esi)
	je	L14
	movb	$0, -1(%esi)
	movl	%ebx, 4(%esp)
	movl	%edi, (%esp)
	call	___solve_symlinks
	movl	%eax, %edx
	xorl	%eax, %eax
	testl	%edx, %edx
	je	L4
	movl	%ebx, (%esp)
	call	_strlen
	movb	$47, (%ebx,%eax)
	leal	1(%ebx,%eax), %eax
	movl	%esi, 4(%esp)
	movl	%eax, (%esp)
	call	_strcpy
	movl	$1, %eax
	jmp	L4
	.p2align 4,,7
L16:
	movl	$14, _errno
	xorl	%eax, %eax
L4:
	addl	$288, %esp
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
	.p2align 4,,7
L24:
	.cfi_restore_state
	movl	$22, _errno
	addl	$288, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 16
	xorl	%eax, %eax
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
	.p2align 4,,7
L6:
	.cfi_restore_state
	movb	1(%eax), %dl
	testb	%dl, %dl
	sete	%cl
	andl	$255, %ecx
	cmpb	$58, %dl
	jne	L8
L25:
	movb	2(%eax), %dl
	cmpb	$92, %dl
	je	L17
	cmpb	$47, %dl
	jne	L8
L17:
	cmpb	$0, 3(%eax)
	jne	L8
	.p2align 4,,7
L10:
	movl	%ebx, (%esp)
	movl	%eax, 4(%esp)
	call	_strcpy
	addl	$288, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 16
	movl	$1, %eax
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
	.p2align 4,,7
L14:
	.cfi_restore_state
	movl	%edi, 4(%esp)
	movl	%ebx, (%esp)
	call	_strcpy
	movl	$1, %eax
	jmp	L4
	.cfi_endproc
LFE0:
	.ident	"GCC: (GNU) 4.7.4"
