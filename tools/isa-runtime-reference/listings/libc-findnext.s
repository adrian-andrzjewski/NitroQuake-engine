	.file	"findnext.c"
	.section .text
	.p2align 4,,15
	.globl	___findnext
___findnext:
LFB3:
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
	subl	$400, %esp
	.cfi_def_cfa_offset 416
	movl	416(%esp), %ebx
	testl	%ebx, %ebx
	je	L29
	movl	$0, (%esp)
	call	__use_lfn
	testb	%al, %al
	je	L4
	leal	82(%esp), %esi
	movl	$318, %edx
	movl	%esi, %edi
	testl	$2, %esi
	jne	L30
L5:
	movl	%edx, %ecx
	xorl	%eax, %eax
	shrl	$2, %ecx
	andl	$2, %edx
	rep stosl
	je	L7
	movw	$0, (%edi)
L7:
	movl	__go32_info_block+12, %eax
	movl	$318, 4(%esp)
	movl	%eax, 8(%esp)
	movl	%esi, (%esp)
	call	___dosmemput
	movw	6(%ebx), %ax
	movw	$1, 60(%esp)
	movw	$29007, 56(%esp)
	testw	%ax, %ax
	movw	%ax, 44(%esp)
	jne	L8
	movl	$38, _errno
	addl	$400, %esp
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
L4:
	.cfi_restore_state
	movl	__go32_info_block+12, %eax
	leal	28(%esp), %esi
	shrl	$4, %eax
	movl	%esi, 4(%esp)
	movl	$33, (%esp)
	movw	$0, 48(%esp)
	movw	%ax, 64(%esp)
	movb	$26, 57(%esp)
	call	___dpmi_int
	movl	__go32_info_block+12, %eax
	movl	%eax, 8(%esp)
	movl	$290, 4(%esp)
	movl	%ebx, (%esp)
	call	___dosmemput
	movl	%esi, 4(%esp)
	movl	$33, (%esp)
	movb	$79, 57(%esp)
	call	___dpmi_int
	testb	$1, 60(%esp)
	jne	L27
	movl	__go32_info_block+12, %eax
	movl	%ebx, 8(%esp)
	movl	%eax, (%esp)
	movl	$44, 4(%esp)
	call	___dosmemget
	xorl	%eax, %eax
L3:
	addl	$400, %esp
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
L8:
	.cfi_restore_state
	movl	__go32_info_block+12, %eax
	leal	28(%esp), %edi
	shrl	$4, %eax
	movl	%edi, 4(%esp)
	movl	$33, (%esp)
	movw	$0, 28(%esp)
	movw	%ax, 62(%esp)
	movw	$1, 32(%esp)
	call	___dpmi_int
	testb	$1, 60(%esp)
	jne	L10
	cmpw	$28928, 56(%esp)
	je	L13
	movl	__go32_info_block+12, %eax
	movl	%esi, 8(%esp)
	movl	%eax, (%esp)
	movl	$318, 4(%esp)
	call	___dosmemget
	movl	82(%esp), %eax
	movb	%al, 21(%ebx)
	movl	102(%esp), %eax
	movw	%ax, 22(%ebx)
	shrl	$16, %eax
	movw	%ax, 24(%ebx)
	movl	114(%esp), %eax
	movl	%eax, 26(%ebx)
	leal	126(%esp), %eax
	movl	%eax, 4(%esp)
	leal	30(%ebx), %eax
	movl	%eax, (%esp)
	call	_strcpy
	movl	86(%esp), %eax
	movw	%ax, 8(%ebx)
	shrl	$16, %eax
	movw	%ax, 10(%ebx)
	movl	94(%esp), %eax
	movw	%ax, 12(%ebx)
	shrl	$16, %eax
	movw	%ax, 14(%ebx)
	xorl	%eax, %eax
	jmp	L3
	.p2align 4,,7
L13:
	movl	$28928, %eax
L11:
	andl	$65535, %eax
	movl	%eax, (%esp)
	call	___doserr_to_errno
	movl	%eax, %edx
	movl	%eax, _errno
	orl	$-1, %eax
	cmpl	$38, %edx
	jne	L3
	movw	$0, 6(%ebx)
	movl	%edi, 4(%esp)
	movl	$33, (%esp)
	movw	$29089, 56(%esp)
	orw	$1, 60(%esp)
	call	___dpmi_int
	movl	$1, %eax
	testb	$1, 60(%esp)
	je	L3
L27:
	movl	56(%esp), %eax
	andl	$65535, %eax
	movl	%eax, (%esp)
	call	___doserr_to_errno
	movl	%eax, _errno
	orl	$-1, %eax
	jmp	L3
	.p2align 4,,7
L30:
	movw	$0, 82(%esp)
	leal	84(%esp), %edi
	movb	$60, %dl
	jmp	L5
	.p2align 4,,7
L10:
	movl	56(%esp), %eax
	jmp	L11
	.p2align 4,,7
L29:
	movl	$4, _errno
	orl	$-1, %eax
	jmp	L3
	.cfi_endproc
LFE3:
	.ident	"GCC: (GNU) 4.7.4"
