	.file	"llseek.c"
	.section .text
	.p2align 4,,15
___FSEXT_func_wrapper.constprop.0:
LFB8:
	.cfi_startproc
	subl	$28, %esp
	.cfi_def_cfa_offset 32
	leal	44(%esp), %eax
	movl	$16, (%esp)
	movl	%eax, 8(%esp)
	movl	40(%esp), %eax
	movl	%eax, 4(%esp)
	call	*32(%esp)
	addl	$28, %esp
	.cfi_def_cfa_offset 4
	ret
	.cfi_endproc
LFE8:
	.p2align 4,,15
	.globl	___llseek
___llseek:
LFB7:
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
	subl	$108, %esp
	.cfi_def_cfa_offset 128
	movl	128(%esp), %ebx
	movl	132(%esp), %esi
	movl	%ebx, (%esp)
	movl	136(%esp), %edi
	call	___FSEXT_get_function
	testl	%eax, %eax
	je	L4
	movl	140(%esp), %edx
	movl	%esi, 16(%esp)
	movl	%edx, 24(%esp)
	leal	40(%esp), %edx
	movl	%edi, 20(%esp)
	movl	%ebx, 12(%esp)
	movl	%edx, 8(%esp)
	movl	$16, 4(%esp)
	movl	%eax, (%esp)
	call	___FSEXT_func_wrapper.constprop.0
	testl	%eax, %eax
	jne	L40
L4:
	testl	%ebx, %ebx
	js	L7
	movl	___fd_properties, %eax
	testl	%eax, %eax
	je	L7
	leal	0(,%ebx,4), %ebp
	movl	(%eax,%ebp), %eax
	testl	%eax, %eax
	je	L7
	movl	8(%eax), %ecx
	xorl	%edx, %edx
	xorl	%eax, %eax
	testb	$32, %cl
	jne	L31
	andl	$8, %ecx
	jne	L41
	movb	140(%esp), %al
	movl	%edi, %edx
	movb	%al, 72(%esp)
	movl	%esi, %eax
	shrdl	$16, %edx, %eax
	movw	%ax, 68(%esp)
	leal	44(%esp), %eax
	movl	%eax, 4(%esp)
	movl	$33, (%esp)
	movb	$66, 73(%esp)
	movw	%bx, 60(%esp)
	movw	%si, 64(%esp)
	call	___dpmi_int
	testb	$1, 76(%esp)
	jne	L16
	movl	___fd_properties, %eax
	movl	(%eax,%ebp), %edx
	movl	8(%edx), %ecx
	testb	$4, %cl
	jne	L11
	cmpl	$0, %edi
	jle	L42
L19:
	movl	(%eax,%ebx,4), %eax
	orl	$2, 8(%eax)
L11:
	movl	64(%esp), %edx
	movl	72(%esp), %eax
	addl	$108, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 20
	andl	$65535, %eax
	sall	$16, %edx
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 16
	addl	%edx, %eax
	popl	%esi
	.cfi_restore 6
	.cfi_def_cfa_offset 12
	xorl	%edx, %edx
	popl	%edi
	.cfi_restore 7
	.cfi_def_cfa_offset 8
	popl	%ebp
	.cfi_restore 5
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L40:
	.cfi_restore_state
	movl	40(%esp), %eax
	movl	%eax, %edx
	sarl	$31, %edx
L31:
	addl	$108, %esp
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
L7:
	.cfi_restore_state
	movb	140(%esp), %dl
	movl	%esi, %eax
	movb	%dl, 72(%esp)
	movl	%edi, %edx
	shrdl	$16, %edx, %eax
	movw	%ax, 68(%esp)
	leal	44(%esp), %eax
	movl	%eax, 4(%esp)
	movl	$33, (%esp)
	movb	$66, 73(%esp)
	movw	%bx, 60(%esp)
	movw	%si, 64(%esp)
	call	___dpmi_int
	testb	$1, 76(%esp)
	jne	L16
	cmpl	$0, %edi
	jle	L43
L12:
	movl	$0, 8(%esp)
	movl	$0, 4(%esp)
	movl	%ebx, (%esp)
	call	___set_fd_properties
	testl	%eax, %eax
	jne	L11
	movl	___fd_properties, %eax
	jmp	L19
	.p2align 4,,7
L43:
	jl	L11
	cmpl	$0, %esi
	ja	L12
	jmp	L11
	.p2align 4,,7
L41:
	movl	$35, _errno
	orl	$-1, %eax
	orl	$-1, %edx
	jmp	L31
L16:
	movl	72(%esp), %eax
	andl	$65535, %eax
	movl	%eax, (%esp)
	call	___doserr_to_errno
	movl	%eax, _errno
	orl	$-1, %eax
	movl	%eax, %edx
	jmp	L31
L42:
	jl	L21
	cmpl	$0, %esi
	ja	L19
L21:
	testl	$-3, 140(%esp)
	jne	L11
	andl	$-3, %ecx
	movl	%ecx, 8(%edx)
	jmp	L11
	.cfi_endproc
LFE7:
	.ident	"GCC: (GNU) 4.7.4"
