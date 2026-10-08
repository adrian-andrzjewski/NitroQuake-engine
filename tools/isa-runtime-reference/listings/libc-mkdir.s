	.file	"mkdir.c"
	.section .text
	.p2align 4,,15
	.globl	___mkdir
___mkdir:
LFB9:
	.cfi_startproc
	pushl	%esi
	.cfi_def_cfa_offset 8
	.cfi_offset 6, -8
	pushl	%ebx
	.cfi_def_cfa_offset 12
	.cfi_offset 3, -12
	subl	$340, %esp
	.cfi_def_cfa_offset 352
	movl	$0, (%esp)
	leal	76(%esp), %esi
	call	__use_lfn
	movl	352(%esp), %edx
	movl	%esi, 4(%esp)
	movl	%edx, (%esp)
	movb	%al, %bl
	call	___solve_symlinks
	testl	%eax, %eax
	je	L22
	movl	%esi, (%esp)
	call	__put_path
	testb	%bl, %bl
	jne	L24
	movb	$57, 53(%esp)
	leal	24(%esp), %ebx
	jmp	L20
	.p2align 4,,7
L25:
	movb	$57, 53(%esp)
L20:
	movl	__go32_info_block+12, %eax
	movl	%ebx, 4(%esp)
	shrl	$4, %eax
	movl	$33, (%esp)
	movw	%ax, 60(%esp)
	movw	$0, 44(%esp)
	call	___dpmi_int
	movl	52(%esp), %eax
	cmpw	$28928, %ax
	je	L25
	testb	$1, 56(%esp)
	je	L8
	andl	$65535, %eax
	movl	%eax, (%esp)
	call	___doserr_to_errno
	movl	%eax, _errno
	cmpl	$4, %eax
	jne	L22
	movl	$0, 8(%esp)
	movl	$0, 4(%esp)
	movl	%esi, (%esp)
	call	__chmod
	cmpl	$-1, %eax
	je	L10
	testb	$16, %al
	je	L10
	movl	$10, _errno
L22:
	addl	$340, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 12
	orl	$-1, %eax
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 8
	popl	%esi
	.cfi_restore 6
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L24:
	.cfi_restore_state
	movw	$1, 56(%esp)
	movw	$28985, 52(%esp)
	leal	24(%esp), %ebx
	jmp	L20
	.p2align 4,,7
L8:
	movl	$0, 8(%esp)
	movl	$0, 4(%esp)
	movl	%esi, (%esp)
	call	__chmod
	movl	$1, 4(%esp)
	andl	$65510, %eax
	testb	$-128, 356(%esp)
	sete	%dl
	andl	$255, %edx
	movl	%esi, (%esp)
	orl	%edx, %eax
	movl	%eax, 8(%esp)
	call	__chmod
	incl	%eax
	je	L22
	addl	$340, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 12
	xorl	%eax, %eax
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 8
	popl	%esi
	.cfi_restore 6
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L10:
	.cfi_restore_state
	movl	$4, _errno
	addl	$340, %esp
	.cfi_def_cfa_offset 12
	orl	$-1, %eax
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 8
	popl	%esi
	.cfi_restore 6
	.cfi_def_cfa_offset 4
	ret
	.cfi_endproc
LFE9:
	.ident	"GCC: (GNU) 4.7.4"
