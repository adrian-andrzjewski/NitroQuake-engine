	.file	"putenv.c"
	.section .text
	.p2align 4,,15
	.globl	___putenv
___putenv:
LFB0:
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
	subl	$60, %esp
	.cfi_def_cfa_offset 80
	movl	80(%esp), %edx
	movl	%edx, (%esp)
	call	_strlen
	movl	80(%esp), %esi
	movl	$61, 4(%esp)
	movl	%esi, (%esp)
	movl	%eax, 44(%esp)
	call	_strchr
	movl	%eax, 40(%esp)
	testl	%eax, %eax
	je	L27
	movl	%eax, %edi
	subl	%esi, %edi
	incl	%edi
L2:
	movl	_putenv_bss_count, %edx
	movl	___bss_count, %ebx
	movl	__environ, %esi
	cmpl	%ebx, %edx
	je	L3
L4:
	movl	(%esi), %ebp
	movl	$0, _ecount
	testl	%ebp, %ebp
	je	L28
	movl	$1, %eax
	.p2align 4,,7
L7:
	movl	%eax, %ecx
	leal	1(%eax), %eax
	cmpl	$0, -4(%esi,%eax,4)
	jne	L7
	movl	%ecx, _ecount
L6:
	movl	___environ_changed, %eax
	movl	%ecx, _emax
	incl	%eax
	cmpl	%ebx, %edx
	movl	%eax, ___environ_changed
	je	L5
	movl	%ebx, _putenv_bss_count
	movl	%esi, _prev_environ
L5:
	testl	%ebp, %ebp
	je	L9
	leal	4(%esi), %ebx
	movl	%esi, 36(%esp)
	movl	%esi, 28(%esp)
	movl	$0, 32(%esp)
	movl	%ebp, %esi
	movl	%ebx, %ebp
	movl	80(%esp), %ebx
	.p2align 4,,7
L19:
	movl	%edi, 8(%esp)
	movl	%ebx, 4(%esp)
	movl	%esi, (%esp)
	call	_strncmp
	testl	%eax, %eax
	jne	L10
	movl	40(%esp), %eax
	testl	%eax, %eax
	jne	L11
	leal	(%esi,%edi), %eax
	cmpb	$61, (%eax)
	je	L40
L10:
	movl	%ebp, %esi
	movl	28(%esp), %ecx
	movl	%ebp, 36(%esp)
	addl	$4, %ebp
	subl	%ecx, %esi
	movl	%esi, 32(%esp)
	movl	-4(%ebp), %esi
	testl	%esi, %esi
	jne	L19
	movl	28(%esp), %esi
L9:
	movl	80(%esp), %edx
	cmpb	$0, (%edx,%edi)
	je	L41
L20:
	movl	_ecount, %ebx
	movl	_emax, %eax
	cmpl	%eax, %ebx
	jl	L21
	leal	10(%eax), %edx
	leal	44(,%eax,4), %eax
	movl	%eax, (%esp)
	movl	%edx, _emax
	call	_malloc
	movl	%eax, %edi
	testl	%eax, %eax
	je	L38
	leal	0(,%ebx,4), %eax
	movl	%esi, 4(%esp)
	movl	%eax, 8(%esp)
	movl	%edi, (%esp)
	call	_memcpy
	cmpl	%esi, _prev_environ
	je	L42
L23:
	movl	%edi, __environ
	movl	%edi, _prev_environ
	movl	%edi, %esi
L21:
	movl	44(%esp), %eax
	leal	0(,%ebx,4), %edi
	incl	%eax
	movl	%eax, (%esp)
	call	_malloc
	movl	%eax, (%esi,%edi)
	movl	__environ, %eax
	movl	(%eax,%edi), %eax
	testl	%eax, %eax
	je	L38
	movl	80(%esp), %esi
	movl	%eax, (%esp)
	movl	%esi, 4(%esp)
	incl	%ebx
	call	_strcpy
	movl	__environ, %eax
	movl	$0, (%eax,%ebx,4)
	movl	___environ_changed, %eax
	incl	%eax
	movl	%ebx, _ecount
	movl	%eax, ___environ_changed
	xorl	%eax, %eax
L31:
	addl	$60, %esp
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
L41:
	.cfi_restore_state
	movl	40(%esp), %edx
	testl	%edx, %edx
	jne	L20
	xorl	%eax, %eax
	jmp	L31
	.p2align 4,,7
L3:
	cmpl	_prev_environ, %esi
	jne	L4
	movl	(%esi), %ebp
	jmp	L5
	.p2align 4,,7
L40:
	movl	%esi, %ebp
	movl	%eax, 24(%esp)
	movl	%ebp, (%esp)
	movl	28(%esp), %esi
	call	_strlen
	movl	24(%esp), %ecx
	movl	%eax, %ebx
	movl	80(%esp), %eax
	addl	%edi, %eax
	cmpb	$0, (%eax)
	je	L25
L26:
	movl	%ecx, (%esp)
	movl	%eax, 4(%esp)
	call	_strcmp
	movl	%eax, %ecx
	xorl	%eax, %eax
	testl	%ecx, %ecx
	je	L31
	cmpl	%ebx, 44(%esp)
	je	L43
	movl	44(%esp), %eax
	jle	L16
	incl	%eax
	movl	%eax, (%esp)
	call	_malloc
	movl	36(%esp), %esi
	movl	%eax, (%esi)
	movl	32(%esp), %ecx
	movl	__environ, %edi
	addl	%edi, %ecx
	movl	(%ecx), %eax
	testl	%eax, %eax
	je	L17
	movl	%ebp, (%esp)
	call	_free
	movl	__environ, %eax
	movl	32(%esp), %esi
	movl	(%eax,%esi), %eax
	jmp	L15
L16:
	incl	%eax
	movl	%ebp, (%esp)
	movl	%eax, 4(%esp)
	call	_realloc
	movl	36(%esp), %edx
	movl	32(%esp), %ecx
	movl	%eax, (%edx)
	movl	__environ, %esi
	addl	%esi, %ecx
	movl	(%ecx), %eax
	testl	%eax, %eax
	je	L17
L15:
	movl	80(%esp), %edx
	movl	%eax, (%esp)
	movl	%edx, 4(%esp)
	call	_strcpy
	movl	___environ_changed, %ebx
	incl	%ebx
	xorl	%eax, %eax
	movl	%ebx, ___environ_changed
	addl	$60, %esp
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
L27:
	.cfi_restore_state
	movl	44(%esp), %edi
	jmp	L2
L28:
	xorl	%ecx, %ecx
	jmp	L6
L25:
	movl	%ebp, (%esp)
	call	_free
	movl	_ecount, %eax
	decl	%eax
	movl	__environ, %ecx
	movl	32(%esp), %esi
	movl	%eax, _ecount
	leal	0(,%eax,4), %edx
	movl	___environ_changed, %eax
	incl	%eax
	movl	(%ecx,%edx), %ebx
	movl	%ebx, (%ecx,%esi)
	movl	__environ, %ecx
	movl	$0, (%ecx,%edx)
	movl	%eax, ___environ_changed
	xorl	%eax, %eax
	jmp	L31
L43:
	movl	32(%esp), %edx
	movl	(%esi,%edx), %eax
	jmp	L15
L42:
	movl	%esi, (%esp)
	call	_free
	jmp	L23
L38:
	movl	$25, _errno
	orl	$-1, %eax
	jmp	L31
L17:
	movl	%ebp, (%ecx)
	orl	$-1, %eax
	movl	$25, _errno
	jmp	L31
	.p2align 4,,7
L11:
	movl	%esi, %ebp
	movl	28(%esp), %esi
	movl	%ebp, (%esp)
	call	_strlen
	leal	0(%ebp,%edi), %ecx
	movl	%eax, %ebx
	movl	80(%esp), %eax
	addl	%edi, %eax
	jmp	L26
	.cfi_endproc
LFE0:
	.globl	___environ_changed
	.section .data
	.p2align 2
___environ_changed:
	.long	1
	.p2align 2
_putenv_bss_count:
	.long	-1
.lcomm _prev_environ,4,4
	.p2align 2
_ecount:
	.long	-1
	.p2align 2
_emax:
	.long	-1
	.ident	"GCC: (GNU) 4.7.4"
