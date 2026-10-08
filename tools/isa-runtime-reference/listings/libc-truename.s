	.file	"truename.c"
	.section .text
	.p2align 4,,15
__truename_internal:
LFB9:
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
	subl	$636, %esp
	.cfi_def_cfa_offset 656
	movl	%eax, %esi
	movl	_errno, %eax
	movw	__go32_info_block+26, %bx
	movl	$0, (%esp)
	movl	%edx, 40(%esp)
	movl	%ecx, 32(%esp)
	movl	%eax, 44(%esp)
	call	__use_lfn
/APP
# 36 "c:/djgpp/include/sys/segments.h" 1
	movw %ds,%bp
# 0 "" 2
/NO_APP
	movsbl	%al, %edi
	testl	%esi, %esi
	je	L54
	cmpb	$0, (%esi)
	je	L55
	movl	%esi, 4(%esp)
	leal	364(%esp), %esi
	movl	$260, 8(%esp)
	movl	%esi, (%esp)
	call	_strncpy
	movb	$0, 623(%esp)
	movl	%esi, %edx
L5:
	movl	(%edx), %ecx
	addl	$4, %edx
	leal	-16843009(%ecx), %eax
	xorl	$-1, %ecx
	andl	%ecx, %eax
	andl	$-2139062144, %eax
	je	L5
	testl	$32896, %eax
	je	L56
L7:
	addb	%al, %al
	sbbl	$3, %edx
	leal	-1(%edx), %eax
	cmpl	%esi, %eax
	jae	L8
	jmp	L11
	.p2align 4,,7
L57:
	movb	$0, (%eax)
	decl	%eax
	cmpl	%esi, %eax
	jb	L11
L8:
	xorl	%edx, %edx
	movb	(%eax), %dl
	testb	$1, ___dj_ctype_flags+3(%edx,%edx)
	jne	L57
L11:
	cmpb	$58, 365(%esp)
	je	L58
L10:
	movl	%esi, (%esp)
	call	__put_path
	testl	%edi, %edi
	je	L14
	movl	32(%esp), %ecx
	movw	$1, 84(%esp)
	testl	%ecx, %ecx
	movw	$29024, 80(%esp)
	setne	%al
	andl	$255, %eax
	addl	%eax, %eax
	movw	%ax, 76(%esp)
L16:
	andl	$65535, %ebx
	leal	104(%esp), %eax
	movl	%ebx, 36(%esp)
	movl	%eax, 32(%esp)
	andl	$65535, %ebp
	movl	$1, %ebx
	leal	52(%esp), %esi
	.p2align 4,,7
L50:
	movl	__go32_info_block+12, %eax
	movl	%esi, 4(%esp)
	shrl	$4, %eax
	movl	$33, (%esp)
	movw	%ax, 86(%esp)
	movw	%ax, 88(%esp)
	movw	$0, 56(%esp)
	movw	$260, 52(%esp)
	call	___dpmi_int
	cmpw	$28928, 80(%esp)
	je	L59
	leal	104(%esp), %eax
	movl	$260, 16(%esp)
	movl	%eax, 12(%esp)
	movl	__go32_info_block+12, %eax
	addl	$260, %eax
	movl	%ebp, 8(%esp)
	movl	%eax, 4(%esp)
	movl	36(%esp), %eax
	movl	%eax, (%esp)
	call	___movedata
	testb	$1, 84(%esp)
	je	L20
	testl	%ebx, %ebx
	je	L21
	testl	%edi, %edi
	je	L21
	movw	$29024, 80(%esp)
	movw	$0, 76(%esp)
	xorl	%ebx, %ebx
	jmp	L50
	.p2align 4,,7
L59:
	movw	$24576, 80(%esp)
	xorl	%edi, %edi
	jmp	L50
	.p2align 4,,7
L20:
	movl	40(%esp), %edx
	testl	%edx, %edx
	je	L60
L22:
	movl	44(%esp), %eax
	movl	%eax, _errno
	leal	104(%esp), %eax
	movl	%eax, 4(%esp)
	movl	40(%esp), %eax
	movl	%eax, (%esp)
	call	_strcpy
L3:
	movl	40(%esp), %eax
	addl	$636, %esp
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
L14:
	.cfi_restore_state
	movw	$24576, 80(%esp)
	jmp	L16
	.p2align 4,,7
L21:
	movl	80(%esp), %eax
	andl	$65535, %eax
	movl	%eax, (%esp)
	call	___doserr_to_errno
	movl	$0, 40(%esp)
	movl	%eax, _errno
	movl	40(%esp), %eax
	addl	$636, %esp
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
L58:
	.cfi_restore_state
	movb	366(%esp), %al
	cmpb	$47, %al
	je	L27
	cmpb	$92, %al
	jne	L10
L27:
	cmpb	$0, 367(%esp)
	jne	L10
	movb	$46, 367(%esp)
	movb	$0, 368(%esp)
	jmp	L10
	.p2align 4,,7
L55:
	movl	$0, 40(%esp)
	movl	$28, _errno
	movl	40(%esp), %eax
	addl	$636, %esp
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
L56:
	.cfi_restore_state
	shrl	$16, %eax
	addl	$2, %edx
	jmp	L7
L60:
	leal	104(%esp), %edx
L23:
	movl	(%edx), %ecx
	addl	$4, %edx
	leal	-16843009(%ecx), %eax
	xorl	$-1, %ecx
	andl	%ecx, %eax
	andl	$-2139062144, %eax
	je	L23
	testl	$32896, %eax
	jne	L25
	shrl	$16, %eax
	addl	$2, %edx
L25:
	addb	%al, %al
	movl	32(%esp), %eax
	sbbl	$3, %edx
	subl	%eax, %edx
	incl	%edx
	movl	%edx, (%esp)
	call	_malloc
	movl	%eax, 40(%esp)
	testl	%eax, %eax
	jne	L22
	movl	40(%esp), %eax
	movl	$25, _errno
	addl	$636, %esp
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
L54:
	.cfi_restore_state
	movl	$11, _errno
	movl	$0, 40(%esp)
	jmp	L3
	.cfi_endproc
LFE9:
	.p2align 4,,15
	.globl	__truename
__truename:
LFB10:
	.cfi_startproc
	movl	$1, %ecx
	movl	8(%esp), %edx
	movl	4(%esp), %eax
	jmp	__truename_internal
	.cfi_endproc
LFE10:
	.p2align 4,,15
	.globl	__truename_sfn
__truename_sfn:
LFB11:
	.cfi_startproc
	xorl	%ecx, %ecx
	movl	8(%esp), %edx
	movl	4(%esp), %eax
	jmp	__truename_internal
	.cfi_endproc
LFE11:
	.ident	"GCC: (GNU) 4.7.4"
