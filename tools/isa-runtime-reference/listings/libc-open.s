	.file	"open.c"
	.section .text
	.p2align 4,,15
_move_fd.constprop.0:
LFB14:
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
	movl	%eax, %ebx
	subl	$16, %esp
	.cfi_def_cfa_offset 32
	cmpl	$19, %eax
	jle	L7
L2:
	addl	$16, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 16
	movl	%ebx, %eax
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
L7:
	.cfi_restore_state
	cmpl	$-1, %eax
	je	L2
	movl	%eax, (%esp)
	call	___dup
	movl	%eax, %esi
	cmpl	$-1, %eax
	je	L4
	call	_move_fd.constprop.0
	movl	%eax, %edi
	cmpl	$-1, %eax
	je	L3
	movl	%ebx, (%esp)
	movl	%edi, %ebx
	call	___close
	addl	$16, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 16
	movl	%ebx, %eax
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
L3:
	.cfi_restore_state
	movl	%esi, (%esp)
	orl	$-1, %ebx
	call	___close
	jmp	L2
	.p2align 4,,7
L4:
	addl	$16, %esp
	.cfi_def_cfa_offset 16
	orl	$-1, %ebx
	movl	%ebx, %eax
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
	.cfi_endproc
LFE14:
	.p2align 4,,15
	.globl	___open
___open:
LFB13:
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
	subl	$844, %esp
	.cfi_def_cfa_offset 864
	movl	868(%esp), %ebx
	leal	49(%esp), %esi
	movl	%ebx, %eax
	movl	%esi, 4(%esp)
	andl	$768, %eax
	cmpl	$768, %eax
	sete	%al
	andl	$255, %eax
	movl	%eax, 40(%esp)
	movl	864(%esp), %eax
	movl	%eax, (%esp)
	testb	$64, %bh
	je	L9
	call	___solve_dir_symlinks
	movl	$1, %edi
	testl	%eax, %eax
	je	L86
	testb	$128, %bh
	je	L13
L90:
	movl	864(%esp), %eax
	movl	%esi, 4(%esp)
	movl	%eax, (%esp)
	call	_strcmp
	testl	%eax, %eax
	jne	L87
L13:
	movl	40(%esp), %eax
	testl	%eax, %eax
	je	L16
L92:
	testl	%edi, %edi
	jne	L17
	movl	864(%esp), %eax
	leal	310(%esp), %ebp
	movl	%ebp, 4(%esp)
	movl	%eax, (%esp)
	call	___solve_dir_symlinks
	testl	%eax, %eax
	je	L86
L19:
	leal	571(%esp), %eax
	movl	$261, 12(%esp)
	movl	%eax, 8(%esp)
	movl	$0, 4(%esp)
	movl	%ebp, (%esp)
	call	___internal_readlink
	testl	%eax, %eax
	jns	L85
	movl	_errno, %eax
	cmpl	$14, %eax
	jne	L88
L22:
	movl	%esi, (%esp)
	call	___file_exists
	testl	%eax, %eax
	jne	L85
L16:
	movl	%ebx, %eax
	andl	$12, %eax
	movl	%eax, 36(%esp)
	jne	L26
	movl	__fmode, %eax
	andl	$12, %eax
	movl	%eax, 36(%esp)
	jne	L26
	movl	$4, 36(%esp)
L26:
	movl	%ebx, %edi
	andl	$-13, %edi
	testb	$-128, 872(%esp)
	sete	%cl
	andl	$255, %ecx
	xorl	%edx, %edx
	movl	%edi, 868(%esp)
	testb	$112, %bl
	jne	L27
	movl	___djgpp_share_flags, %eax
	movb	$1, %dl
	testl	%eax, %eax
	je	L27
	orl	%eax, %edi
	xorb	%dl, %dl
	movl	%edi, 868(%esp)
L27:
	movl	40(%esp), %ebp
	testl	%ebp, %ebp
	je	L28
	movl	%edi, %edx
	movl	%ecx, 4(%esp)
	andl	$255, %edx
	movl	%esi, (%esp)
	movl	%edx, 8(%esp)
	call	__creatnew
	movl	%eax, %ebp
L29:
	cmpl	$-1, %ebp
	je	L41
	movl	868(%esp), %edi
	testl	$2048, %edi
	je	L40
	movl	40(%esp), %eax
	testl	%eax, %eax
	je	L42
L40:
	movl	36(%esp), %eax
	movl	%ebp, (%esp)
	xorl	$12, %eax
	movl	%eax, 4(%esp)
	call	___file_handle_set
	movl	36(%esp), %eax
	movl	%eax, 4(%esp)
	movl	%ebp, (%esp)
	call	___setmode
	movl	%edi, 8(%esp)
	movl	%esi, 4(%esp)
	movl	%ebp, (%esp)
	call	___set_fd_properties
	andl	$4096, %edi
	jne	L89
L60:
	addl	$844, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 20
	movl	%ebp, %eax
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
L9:
	.cfi_restore_state
	call	___solve_symlinks
	testl	%eax, %eax
	je	L86
	xorl	%edi, %edi
	testb	$128, %bh
	je	L13
	jmp	L90
	.p2align 4,,7
L28:
	movl	%edi, 4(%esp)
	movl	%esi, (%esp)
	movl	%edx, 32(%esp)
	movl	%ecx, 28(%esp)
	call	__open
	movl	%eax, %ebp
	cmpl	$-1, %eax
	je	L91
L30:
	testl	$2048, %edi
	je	L40
L42:
	movl	$0, 8(%esp)
	movl	$0, 4(%esp)
	movl	%ebp, (%esp)
	call	__write
	jmp	L40
L94:
	movl	%ebx, (%esp)
	call	___close
	movl	$17, _errno
	.p2align 4,,7
L86:
	addl	$844, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 20
	orl	$-1, %ebp
	movl	%ebp, %eax
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
	leal	310(%esp), %ebp
	movl	%esi, 4(%esp)
	movl	%ebp, (%esp)
	call	_strcpy
	jmp	L19
	.p2align 4,,7
L87:
	leal	571(%esp), %ebp
	movl	_errno, %eax
	movl	%esi, 4(%esp)
	movl	%ebp, (%esp)
	movl	%eax, 44(%esp)
	call	_strcpy
	movl	%ebp, (%esp)
	call	___basename
	movb	$0, (%eax)
	movl	864(%esp), %eax
	movl	%eax, (%esp)
	call	___basename
	movl	%ebp, (%esp)
	movl	%eax, 28(%esp)
	call	_strlen
	movb	$47, 0(%ebp,%eax)
	leal	1(%ebp,%eax), %eax
	movl	28(%esp), %ecx
	movl	%eax, (%esp)
	movl	%ecx, 4(%esp)
	call	_strcpy
	leal	310(%esp), %eax
	movl	$1, 8(%esp)
	movl	%eax, 4(%esp)
	movl	%ebp, (%esp)
	call	___readlink
	incl	%eax
	jne	L14
	cmpl	$14, _errno
	jne	L14
	movl	44(%esp), %eax
	movl	%eax, _errno
	movl	40(%esp), %eax
	testl	%eax, %eax
	je	L16
	jmp	L92
	.p2align 4,,7
L85:
	movl	$10, _errno
	jmp	L86
	.p2align 4,,7
L89:
	movl	%ebp, (%esp)
	movl	$2, 12(%esp)
	movl	$0, 4(%esp)
	movl	$0, 8(%esp)
	call	___llseek
	addl	$844, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 20
	movl	%ebp, %eax
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
L91:
	.cfi_restore_state
	movl	_errno, %eax
	cmpl	$20, %eax
	je	L86
	cmpl	$17, %eax
	je	L86
	movl	%esi, (%esp)
	call	___file_exists
	movl	32(%esp), %edx
	testl	%eax, %eax
	movl	28(%esp), %ecx
	je	L31
	testl	%edx, %edx
	je	L41
	movl	%edi, %edx
	movl	%esi, (%esp)
	orl	$64, %edx
	movl	%edx, 4(%esp)
	call	__open
	movl	%eax, %ebp
	jmp	L29
	.p2align 4,,7
L41:
	movl	$16, 4(%esp)
	movl	%esi, (%esp)
	call	___access
	testl	%eax, %eax
	jne	L86
	andl	$3, %ebx
	jne	L93
	movl	$0, (%esp)
	call	___FSEXT_alloc_fd
	movl	%eax, %ebx
	testl	%eax, %eax
	js	L86
	call	_move_fd.constprop.0
	movl	%eax, %ebp
	testl	%eax, %eax
	js	L94
	movl	$0, 8(%esp)
	movl	%esi, 4(%esp)
	movl	%eax, (%esp)
	call	___set_fd_properties
	movl	___fd_properties, %eax
	movl	(%eax,%ebp,4), %eax
	orl	$32, 8(%eax)
	movl	$2, 4(%esp)
	movl	%ebp, (%esp)
	call	_fcntl
	testl	%eax, %eax
	js	L86
	orl	$1, %eax
	movl	$5, 4(%esp)
	movl	%eax, 8(%esp)
	movl	%ebp, (%esp)
	call	_fcntl
	testl	%eax, %eax
	jns	L60
	jmp	L86
	.p2align 4,,7
L88:
	cmpl	$22, %eax
	je	L22
	jmp	L86
	.p2align 4,,7
L14:
	movl	$39, _errno
	orl	$-1, %ebp
	jmp	L60
	.p2align 4,,7
L31:
	testl	$256, %edi
	je	L41
	movl	%ecx, 4(%esp)
	movl	%esi, (%esp)
	call	__creat
	movl	%eax, %ebp
	cmpl	$-1, %eax
	jne	L30
	cmpw	$1330, __os_trueversion
	jne	L41
	movl	_errno, %edi
	cmpl	$20, %edi
	je	L48
	cmpl	$17, %edi
	jne	L41
L48:
	movl	%esi, (%esp)
	call	_remove
	movl	%edi, _errno
	jmp	L60
	.p2align 4,,7
L93:
	movl	$16, _errno
	orl	$-1, %ebp
	jmp	L60
	.cfi_endproc
LFE13:
.comm ___djgpp_share_flags,16
	.ident	"GCC: (GNU) 4.7.4"
