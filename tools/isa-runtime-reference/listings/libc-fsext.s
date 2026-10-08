	.file	"fsext.c"
	.section .text
	.p2align 4,,15
___FSEXT_close_all:
LFB8:
	.cfi_startproc
	movl	_fsext_list, %eax
	testl	%eax, %eax
	je	L12
	pushl	%ebx
	.cfi_def_cfa_offset 8
	.cfi_offset 3, -8
	subl	$24, %esp
	.cfi_def_cfa_offset 32
	movl	$0, ___FSEXT_exit_hook
	movl	_num_fds, %ecx
	testl	%ecx, %ecx
	jle	L3
	xorl	%ebx, %ebx
	.p2align 4,,7
L5:
	movl	(%eax,%ebx,8), %edx
	testl	%edx, %edx
	je	L4
	movl	%ebx, (%esp)
	call	__close
	movl	_fsext_list, %eax
L4:
	incl	%ebx
	cmpl	%ebx, _num_fds
	jg	L5
L3:
	movl	%eax, (%esp)
	call	_free
	movl	$0, _fsext_list
	addl	$24, %esp
	.cfi_def_cfa_offset 8
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 4
L12:
	ret
	.cfi_endproc
LFE8:
	.p2align 4,,15
_grow_table:
LFB5:
	.cfi_startproc
	movl	___bss_count, %edx
	cmpl	%edx, _init_count.2743
	je	L15
	movl	%edx, _init_count.2743
	movl	$0, _num_fds
	movl	$0, _fsext_list
	movl	$___FSEXT_close_all, ___FSEXT_exit_hook
L15:
	testl	%eax, %eax
	js	L21
	pushl	%edi
	.cfi_def_cfa_offset 8
	.cfi_offset 7, -8
	pushl	%esi
	.cfi_def_cfa_offset 12
	.cfi_offset 6, -12
	pushl	%ebx
	.cfi_def_cfa_offset 16
	.cfi_offset 3, -16
	subl	$16, %esp
	.cfi_def_cfa_offset 32
	movl	_num_fds, %ebx
	cmpl	%ebx, %eax
	jge	L17
L19:
	xorl	%eax, %eax
L16:
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
	.p2align 4,,7
L17:
	.cfi_restore_state
	leal	256(%eax), %esi
	movl	_fsext_list, %eax
	andl	$-256, %esi
	movl	%eax, (%esp)
	movl	%esi, _num_fds
	leal	0(,%esi,8), %edi
	movl	%edi, 4(%esp)
	call	_realloc
	testl	%eax, %eax
	je	L25
	movl	%eax, _fsext_list
	cmpl	%esi, %ebx
	jge	L19
	leal	(%eax,%ebx,8), %edx
	addl	%edi, %eax
	.p2align 4,,7
L20:
	movl	$0, (%edx)
	movl	$0, 4(%edx)
	addl	$8, %edx
	cmpl	%eax, %edx
	jne	L20
	jmp	L19
	.p2align 4,,7
L21:
	.cfi_def_cfa_offset 4
	.cfi_restore 3
	.cfi_restore 6
	.cfi_restore 7
	movl	$1, %eax
	ret
	.p2align 4,,7
L25:
	.cfi_def_cfa_offset 32
	.cfi_offset 3, -16
	.cfi_offset 6, -12
	.cfi_offset 7, -8
	movl	%ebx, _num_fds
	movb	$1, %al
	jmp	L16
	.cfi_endproc
LFE5:
	.p2align 4,,15
	.globl	___FSEXT_set_function
___FSEXT_set_function:
LFB6:
	.cfi_startproc
	pushl	%ebx
	.cfi_def_cfa_offset 8
	.cfi_offset 3, -8
	subl	$8, %esp
	.cfi_def_cfa_offset 16
	movl	16(%esp), %ebx
	movl	%ebx, %eax
	call	_grow_table
	movl	$1, %edx
	testl	%eax, %eax
	jne	L27
	movl	_fsext_list, %eax
	movl	20(%esp), %edx
	movl	%edx, (%eax,%ebx,8)
	xorl	%edx, %edx
L27:
	addl	$8, %esp
	.cfi_def_cfa_offset 8
	movl	%edx, %eax
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 4
	ret
	.cfi_endproc
LFE6:
LC0:
	.ascii "nul\0"
	.p2align 4,,15
	.globl	___FSEXT_alloc_fd
___FSEXT_alloc_fd:
LFB4:
	.cfi_startproc
	pushl	%ebx
	.cfi_def_cfa_offset 8
	.cfi_offset 3, -8
	subl	$88, %esp
	.cfi_def_cfa_offset 96
	movl	___bss_count, %eax
	cmpl	%eax, _init_count.2743
	je	L31
	movl	%eax, _init_count.2743
	movl	$0, _num_fds
	movl	$0, _fsext_list
	movl	$___FSEXT_close_all, ___FSEXT_exit_hook
L35:
	movl	$LC0, (%esp)
	leal	28(%esp), %ebx
	call	__put_path
	movl	__go32_info_block+12, %eax
	shrl	$4, %eax
	movl	%ebx, 4(%esp)
	movl	$33, (%esp)
	movw	$15746, 56(%esp)
	movw	$0, 48(%esp)
	movw	%ax, 64(%esp)
	call	___dpmi_int
	testb	$1, 60(%esp)
	jne	L32
	movl	56(%esp), %eax
	andl	$65535, %eax
	movl	%eax, _null_dev_fd.2747
L36:
	movl	%ebx, 4(%esp)
	movl	$33, (%esp)
	movb	$69, 57(%esp)
	movw	%ax, 44(%esp)
	call	___dpmi_int
	testb	$1, 60(%esp)
	jne	L37
	movl	56(%esp), %ebx
	movl	$4, 4(%esp)
	andl	$65535, %ebx
	movl	%ebx, (%esp)
	call	___file_handle_set
	movl	96(%esp), %eax
	movl	%eax, 4(%esp)
	movl	%ebx, (%esp)
	call	___FSEXT_set_function
L41:
	addl	$88, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 8
	movl	%ebx, %eax
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L32:
	.cfi_restore_state
	movl	$-1, _null_dev_fd.2747
L37:
	movl	56(%esp), %eax
	orl	$-1, %ebx
	andl	$65535, %eax
	movl	%eax, (%esp)
	call	___doserr_to_errno
	movl	%eax, _errno
	jmp	L41
	.p2align 4,,7
L31:
	movl	_null_dev_fd.2747, %eax
	cmpl	$-1, %eax
	je	L35
	leal	28(%esp), %ebx
	jmp	L36
	.cfi_endproc
LFE4:
	.p2align 4,,15
	.globl	___FSEXT_get_function
___FSEXT_get_function:
LFB7:
	.cfi_startproc
	movl	___bss_count, %edx
	movl	4(%esp), %eax
	cmpl	%edx, _init_count.2743
	je	L44
	movl	%edx, _init_count.2743
	movl	$0, _num_fds
	movl	$0, _fsext_list
	movl	$___FSEXT_close_all, ___FSEXT_exit_hook
L44:
	testl	%eax, %eax
	js	L47
	cmpl	_num_fds, %eax
	jge	L47
	movl	_fsext_list, %edx
	movl	(%edx,%eax,8), %eax
	ret
	.p2align 4,,7
L47:
	xorl	%eax, %eax
	ret
	.cfi_endproc
LFE7:
	.p2align 4,,15
	.globl	___FSEXT_set_data
___FSEXT_set_data:
LFB9:
	.cfi_startproc
	pushl	%esi
	.cfi_def_cfa_offset 8
	.cfi_offset 6, -8
	pushl	%ebx
	.cfi_def_cfa_offset 12
	.cfi_offset 3, -12
	pushl	%ecx
	.cfi_def_cfa_offset 16
	movl	16(%esp), %esi
	movl	20(%esp), %ebx
	movl	%esi, %eax
	call	_grow_table
	testl	%eax, %eax
	jne	L50
	movl	_fsext_list, %eax
	movl	%ebx, 4(%eax,%esi,8)
	movl	%ebx, %eax
	popl	%edx
	.cfi_remember_state
	.cfi_def_cfa_offset 12
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 8
	popl	%esi
	.cfi_restore 6
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L50:
	.cfi_restore_state
	xorl	%ebx, %ebx
	popl	%edx
	.cfi_def_cfa_offset 12
	movl	%ebx, %eax
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 8
	popl	%esi
	.cfi_restore 6
	.cfi_def_cfa_offset 4
	ret
	.cfi_endproc
LFE9:
	.p2align 4,,15
	.globl	___FSEXT_get_data
___FSEXT_get_data:
LFB10:
	.cfi_startproc
	movl	___bss_count, %edx
	movl	4(%esp), %eax
	cmpl	%edx, _init_count.2743
	je	L53
	movl	%edx, _init_count.2743
	movl	$0, _num_fds
	movl	$0, _fsext_list
	movl	$___FSEXT_close_all, ___FSEXT_exit_hook
L53:
	testl	%eax, %eax
	js	L56
	cmpl	_num_fds, %eax
	jge	L56
	movl	_fsext_list, %edx
	movl	4(%edx,%eax,8), %eax
	ret
	.p2align 4,,7
L56:
	xorl	%eax, %eax
	ret
	.cfi_endproc
LFE10:
	.section .data
	.p2align 2
_init_count.2743:
	.long	-1
.lcomm _num_fds,4,4
.lcomm _fsext_list,4,4
	.p2align 2
_null_dev_fd.2747:
	.long	-1
	.ident	"GCC: (GNU) 4.7.4"
