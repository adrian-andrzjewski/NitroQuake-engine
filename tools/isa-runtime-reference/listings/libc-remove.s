	.file	"remove.c"
	.section .text
	.p2align 4,,15
___FSEXT_call_open_handlers_wrapper.constprop.0:
LFB6:
	.cfi_startproc
	subl	$28, %esp
	.cfi_def_cfa_offset 32
	leal	40(%esp), %eax
	movl	$11, (%esp)
	movl	%eax, 8(%esp)
	movl	36(%esp), %eax
	movl	%eax, 4(%esp)
	call	___FSEXT_call_open_handlers
	addl	$28, %esp
	.cfi_def_cfa_offset 4
	ret
	.cfi_endproc
LFE6:
	.p2align 4,,15
	.globl	_remove
_remove:
LFB5:
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
	subl	$336, %esp
	.cfi_def_cfa_offset 352
	movl	$0, (%esp)
	leal	76(%esp), %ebx
	call	__use_lfn
	movl	%ebx, 4(%esp)
	movl	%eax, %esi
	movl	352(%esp), %eax
	movl	%eax, (%esp)
	call	___solve_dir_symlinks
	testl	%eax, %eax
	je	L13
	leal	20(%esp), %eax
	movl	%ebx, 8(%esp)
	movl	%eax, 4(%esp)
	movl	$11, (%esp)
	call	___FSEXT_call_open_handlers_wrapper.constprop.0
	testl	%eax, %eax
	je	L5
	movl	20(%esp), %eax
L4:
	addl	$336, %esp
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
L5:
	.cfi_restore_state
	movl	$0, 4(%esp)
	movl	%ebx, (%esp)
	call	__chmod
	movl	%eax, %edi
	cmpl	$-1, %eax
	je	L21
	andl	$65504, %eax
	movl	$1, 4(%esp)
	movl	%eax, 8(%esp)
	movl	%ebx, (%esp)
	call	__chmod
	movl	%edi, %eax
	andl	$16, %eax
	cmpl	$1, %eax
	movl	%esi, %eax
	sbbl	%edx, %edx
	andl	$7, %edx
	addl	$58, %edx
	testb	%al, %al
	movb	%dl, 53(%esp)
	jne	L22
L9:
	movl	__go32_info_block+12, %eax
	movl	$33, (%esp)
	shrl	$4, %eax
	movw	$0, 48(%esp)
	movw	%ax, 60(%esp)
	leal	24(%esp), %eax
	movl	%eax, 4(%esp)
	movw	$0, 44(%esp)
	call	___dpmi_int
	testb	$1, 56(%esp)
	jne	L23
	cmpw	$28928, 52(%esp)
	je	L24
	addl	$336, %esp
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
L22:
	.cfi_restore_state
	movw	$1, 56(%esp)
	movb	%dl, 52(%esp)
	movb	$113, 53(%esp)
	movw	$0, 28(%esp)
	jmp	L9
	.p2align 4,,7
L13:
	orl	$-1, %eax
	jmp	L4
	.p2align 4,,7
L21:
	movl	$22, _errno
	orl	$-1, %eax
	jmp	L4
L23:
	movl	52(%esp), %eax
L11:
	andl	$65535, %eax
	movl	%eax, (%esp)
	call	___doserr_to_errno
	movl	%eax, %esi
	cmpl	$22, %eax
	je	L25
L12:
	andl	$65511, %edi
	movl	$1, 4(%esp)
	movl	%edi, 8(%esp)
	movl	%ebx, (%esp)
	call	__chmod
	movl	%esi, _errno
	orl	$-1, %eax
	jmp	L4
L24:
	movl	$28928, %eax
	jmp	L11
L25:
	movw	$4, %si
	jmp	L12
	.cfi_endproc
LFE5:
	.ident	"GCC: (GNU) 4.7.4"
