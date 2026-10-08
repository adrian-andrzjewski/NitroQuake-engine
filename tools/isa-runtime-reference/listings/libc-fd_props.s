	.file	"fd_props.c"
	.section .text
	.p2align 4,,15
_exit_cleanup:
LFB15:
	.cfi_startproc
	movl	___fd_properties, %eax
	testl	%eax, %eax
	je	L11
	movl	_active_fds, %edx
	testl	%edx, %edx
	je	L11
	pushl	%ebx
	.cfi_def_cfa_offset 8
	.cfi_offset 3, -8
	xorl	%ebx, %ebx
	subl	$24, %esp
	.cfi_def_cfa_offset 32
	jmp	L5
	.p2align 4,,7
L13:
	movl	___fd_properties, %eax
L5:
	movl	(%eax,%ebx,4), %eax
	testl	%eax, %eax
	je	L4
	movl	%ebx, (%esp)
	call	__close
L4:
	incl	%ebx
	cmpl	$255, %ebx
	jne	L13
	addl	$24, %esp
	.cfi_def_cfa_offset 8
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 4
L11:
	ret
	.cfi_endproc
LFE15:
	.p2align 4,,15
	.globl	___set_fd_properties
___set_fd_properties:
LFB7:
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
	subl	$16, %esp
	.cfi_def_cfa_offset 32
	movl	___bss_count, %eax
	movl	___fd_properties, %edx
	cmpl	%eax, _old_bss_count
	je	L16
	movl	$1020, (%esp)
	movl	%eax, _old_bss_count
	call	_malloc
	movl	$0, _active_fds
	movl	%eax, %edx
	movl	%eax, ___fd_properties
	movl	$0, _cached_fds
	testl	%eax, %eax
	je	L25
	movl	$255, %ecx
	xorl	%eax, %eax
	movl	%edx, %edi
	rep stosl
	movl	$_exit_cleanup, ___fd_properties_cleanup_hook
L16:
	movl	32(%esp), %ebx
	sall	$2, %ebx
	leal	(%edx,%ebx), %esi
	movl	(%esi), %edx
	testl	%edx, %edx
	je	L51
L19:
	movl	4(%edx), %eax
	testl	%eax, %eax
	je	L29
	testl	$65536, 40(%esp)
	jne	L52
L29:
	movl	$0, 8(%edx)
L28:
	xorl	%eax, %eax
	testl	$4096, 40(%esp)
	je	L18
	orl	$16, 8(%edx)
L18:
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
L52:
	.cfi_restore_state
	movl	$1, 8(%edx)
	jmp	L28
	.p2align 4,,7
L51:
	movl	_cached_fds, %eax
	testl	%eax, %eax
	je	L53
	movl	12(%eax), %edx
	testl	%edx, %edx
	je	L23
	movl	16(%eax), %ecx
	movl	$0, 12(%eax)
	movl	%ecx, 16(%edx)
L23:
	movl	16(%eax), %edx
	testl	%edx, %edx
	je	L24
	movl	12(%eax), %ecx
	movl	$0, 16(%eax)
	movl	%ecx, 12(%edx)
L24:
	movl	$0, _cached_fds
L22:
	movl	$0, 12(%eax)
	movl	$0, 16(%eax)
	movb	$1, (%eax)
L21:
	movl	%eax, (%esi)
	movl	___fd_properties, %eax
	movl	(%eax,%ebx), %eax
	testl	%eax, %eax
	je	L25
	movb	$1, (%eax)
	movl	36(%esp), %eax
	movl	$0, 4(%esp)
	movl	%eax, (%esp)
	call	__truename
	movl	___fd_properties, %edx
	addl	%edx, %ebx
	movl	(%ebx), %edx
	movl	%eax, 4(%edx)
	movl	_active_fds, %edx
	movl	(%ebx), %eax
	testl	%edx, %edx
	movl	%edx, 16(%eax)
	movl	$0, 12(%eax)
	je	L26
	movl	%eax, 12(%edx)
L26:
	movl	%eax, _active_fds
	movl	(%ebx), %edx
	jmp	L19
	.p2align 4,,7
L25:
	orl	$-1, %eax
	jmp	L18
L53:
	movl	$20, (%esp)
	call	_malloc
	testl	%eax, %eax
	jne	L22
	jmp	L21
	.cfi_endproc
LFE7:
	.p2align 4,,15
	.globl	___dup_fd_properties
___dup_fd_properties:
LFB8:
	.cfi_startproc
	movl	___fd_properties, %eax
	movl	4(%esp), %edx
	movl	(%eax,%edx,4), %edx
	testl	%edx, %edx
	je	L54
	movl	8(%esp), %ecx
	sall	$2, %ecx
	movl	%edx, (%eax,%ecx)
	movl	___fd_properties, %eax
	movl	(%eax,%ecx), %eax
	incb	(%eax)
L54:
	ret
	.cfi_endproc
LFE8:
	.p2align 4,,15
	.globl	___clear_fd_properties
___clear_fd_properties:
LFB9:
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
	subl	$16, %esp
	.cfi_def_cfa_offset 32
	movl	___fd_properties, %eax
	movl	32(%esp), %esi
	sall	$2, %esi
	addl	%esi, %eax
	movl	(%eax), %edx
	testl	%edx, %edx
	je	L72
	movb	(%edx), %cl
	decl	%ecx
	movb	%cl, (%edx)
	testb	%cl, %cl
	je	L92
L61:
	movl	$0, (%eax)
	xorl	%eax, %eax
L90:
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
L92:
	.cfi_restore_state
	movl	(%eax), %edi
	testb	$1, 8(%edi)
	jne	L93
L62:
	movl	4(%edi), %eax
	movl	%eax, (%esp)
	call	_free
	movl	___fd_properties, %eax
	addl	%esi, %eax
	movl	_active_fds, %ecx
	movl	(%eax), %edx
	movl	$0, 4(%edx)
	movl	(%eax), %edx
	movl	12(%edx), %ebx
	testl	%ebx, %ebx
	je	L68
	movl	16(%edx), %esi
	movl	$0, 12(%edx)
	movl	%esi, 16(%ebx)
L68:
	movl	16(%edx), %ebx
	testl	%ebx, %ebx
	je	L69
	movl	12(%edx), %esi
	movl	$0, 16(%edx)
	movl	%esi, 12(%ebx)
L69:
	cmpl	%ecx, %edx
	je	L94
L70:
	movl	%ecx, _active_fds
	movl	_cached_fds, %ecx
	movl	%ecx, 16(%edx)
	movl	$0, 12(%edx)
	testl	%ecx, %ecx
	je	L71
	movl	%edx, 12(%ecx)
L71:
	movl	%edx, _cached_fds
	jmp	L61
	.p2align 4,,7
L93:
	movl	_active_fds, %ebx
	testl	%ebx, %ebx
	je	L63
	.p2align 4,,7
L83:
	cmpl	%ebx, %edi
	je	L67
	movl	4(%ebx), %eax
	movl	%eax, 4(%esp)
	movl	4(%edi), %eax
	movl	%eax, (%esp)
	call	___stricmp
	testl	%eax, %eax
	je	L95
L67:
	movl	16(%ebx), %ebx
	testl	%ebx, %ebx
	jne	L83
L63:
	movl	4(%edi), %eax
	movl	%eax, (%esp)
	call	_remove
	movl	___fd_properties, %eax
	movl	(%eax,%esi), %edi
	jmp	L62
	.p2align 4,,7
L95:
	movl	___fd_properties, %eax
	orl	$1, 8(%ebx)
	movl	(%eax,%esi), %edi
	jmp	L62
	.p2align 4,,7
L94:
	movl	16(%edx), %ecx
	jmp	L70
L72:
	orl	$-1, %eax
	jmp	L90
	.cfi_endproc
LFE9:
	.globl	___fd_properties
	.section	.bss
	.p2align 2
___fd_properties:
	.space 4
.lcomm _old_bss_count,4,4
.lcomm _active_fds,4,4
.lcomm _cached_fds,4,4
	.ident	"GCC: (GNU) 4.7.4"
