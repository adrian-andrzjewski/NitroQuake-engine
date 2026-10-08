	.file	"opendir.c"
	.section .text
	.p2align 4,,15
	.globl	__lfn_find_close
__lfn_find_close:
LFB0:
	.cfi_startproc
	subl	$92, %esp
	.cfi_def_cfa_offset 96
	movl	96(%esp), %eax
	movl	$33, (%esp)
	movw	%ax, 44(%esp)
	leal	28(%esp), %eax
	movl	%eax, 4(%esp)
	movw	$1, 60(%esp)
	movw	$29089, 56(%esp)
	call	___dpmi_int
	testb	$1, 60(%esp)
	jne	L7
	cmpw	$28928, 56(%esp)
	je	L8
	addl	$92, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L8:
	.cfi_restore_state
	movl	$28928, %eax
L3:
	andl	$65535, %eax
	movl	%eax, (%esp)
	call	___doserr_to_errno
	movl	%eax, _errno
	addl	$92, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L7:
	.cfi_restore_state
	movl	56(%esp), %eax
	jmp	L3
	.cfi_endproc
LFE0:
LC0:
	.ascii ".\0"
	.p2align 4,,15
	.globl	___set_need_fake_dot_dotdot
___set_need_fake_dot_dotdot:
LFB1:
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
	subl	$316, %esp
	.cfi_def_cfa_offset 336
	movl	_errno, %ebp
	movl	336(%esp), %ebx
	movl	4(%ebx), %esi
	movl	$0, 568(%ebx)
	cmpb	$58, 1(%esi)
	je	L31
L9:
	addl	$316, %esp
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
L31:
	.cfi_restore_state
	cmpb	$47, 2(%esi)
	jne	L9
	cmpb	$0, 3(%esi)
	jne	L9
	movb	(%esi), %cl
	testb	%cl, %cl
	je	L18
	xorl	%eax, %eax
	leal	43(%esp), %edx
	.p2align 4,,7
L12:
	movb	%cl, (%edx,%eax)
	incl	%eax
	movb	(%esi,%eax), %cl
	testb	%cl, %cl
	jne	L12
	leal	1(%eax), %ecx
	leal	2(%eax), %edi
	movl	%ecx, 28(%esp)
	leal	3(%eax), %esi
	leal	4(%eax), %ecx
L11:
	movb	$47, 43(%esp,%eax)
	movl	28(%esp), %eax
	movb	$42, 43(%esp,%eax)
	leal	12(%ebx), %eax
	movb	$46, 43(%esp,%edi)
	movb	$42, 43(%esp,%esi)
	movb	$0, 43(%esp,%ecx)
	movl	$49, 8(%esp)
	movl	%eax, 4(%esp)
	movl	%edx, (%esp)
	call	___findfirst
	testl	%eax, %eax
	jne	L13
	leal	42(%ebx), %esi
	movl	$LC0, %edi
	movl	$2, %ecx
	repe cmpsb
	jne	L13
L14:
	movl	$0, (%esp)
	call	__use_lfn
	testb	%al, %al
	je	L9
	movswl	18(%ebx), %eax
	testw	%ax, %ax
	je	L9
	movl	%eax, (%esp)
	call	__lfn_find_close
	movw	$0, 18(%ebx)
	jmp	L9
L13:
	movl	_errno, %eax
	movl	$2, 568(%ebx)
	cmpl	$38, %eax
	je	L19
	cmpl	$22, %eax
	jne	L14
L19:
	movl	%ebp, _errno
	jmp	L14
L18:
	movl	$4, %ecx
	movl	$3, %esi
	movl	$2, %edi
	movl	$1, 28(%esp)
	xorl	%eax, %eax
	leal	43(%esp), %edx
	jmp	L11
	.cfi_endproc
LFE1:
	.p2align 4,,15
	.globl	_opendir
_opendir:
LFB2:
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
	subl	$304, %esp
	.cfi_def_cfa_offset 320
	movl	320(%esp), %eax
	leal	43(%esp), %ebx
	movl	%ebx, 4(%esp)
	movl	%eax, (%esp)
	call	___solve_symlinks
	testl	%eax, %eax
	je	L53
	movl	$572, (%esp)
	call	_malloc
	movl	%eax, %esi
	testl	%eax, %eax
	je	L53
	movl	$0, (%eax)
	movl	$512, (%esp)
	call	_malloc
	movl	%eax, 4(%esi)
	testl	%eax, %eax
	je	L52
	movl	___opendir_flags, %edx
	movl	%edx, 8(%esi)
	andl	$1, %edx
	je	L54
L37:
	movl	%eax, 4(%esp)
	movl	%ebx, (%esp)
	call	__fixpath
	movl	$16, 4(%esp)
	movl	4(%esi), %eax
	movl	%eax, (%esp)
	call	___access
	testl	%eax, %eax
	jne	L55
	movl	4(%esi), %ebx
	movl	%ebx, (%esp)
	call	_strlen
	movl	%eax, %edi
	testl	%eax, %eax
	je	L40
	leal	-1(%eax), %ecx
	leal	(%ebx,%ecx), %edx
	movb	(%edx), %al
	movb	%al, 31(%esp)
	cmpb	$92, %al
	jne	L56
L48:
	movb	$0, (%edx)
	testl	%ecx, %ecx
	je	L57
	.p2align 4,,7
L43:
	leal	-1(%ecx), %edi
	movl	4(%esi), %ebx
	leal	(%ebx,%edi), %edx
	movb	(%edx), %al
	cmpb	$92, %al
	jne	L58
L45:
	movl	%edi, %ecx
	movb	$0, (%edx)
	testl	%ecx, %ecx
	jne	L43
L57:
	movl	4(%esi), %ebx
	xorl	%edi, %edi
L40:
	movb	$0, (%ebx,%edi)
	movl	%esi, (%esp)
	call	___set_need_fake_dot_dotdot
	addl	$304, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 16
	movl	%esi, %eax
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
L58:
	.cfi_restore_state
	cmpb	$47, %al
	je	L45
	movl	%ecx, %edi
	jmp	L40
L55:
	movl	4(%esi), %eax
	movl	%eax, (%esp)
	call	_free
L52:
	movl	%esi, (%esp)
	call	_free
	.p2align 4,,7
L53:
	addl	$304, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 16
	xorl	%esi, %esi
	movl	%esi, %eax
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
L54:
	.cfi_restore_state
	call	__preserve_fncase
	testb	%al, %al
	je	L51
	orl	$1, 8(%esi)
L51:
	movl	4(%esi), %eax
	jmp	L37
L56:
	cmpb	$47, %al
	je	L48
	jmp	L40
	.cfi_endproc
LFE2:
	.ident	"GCC: (GNU) 4.7.4"
