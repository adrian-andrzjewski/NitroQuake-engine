	.file	"_creat_n.c"
	.section .text
	.p2align 4,,15
___FSEXT_call_open_handlers_wrapper.constprop.0:
LFB12:
	.cfi_startproc
	subl	$28, %esp
	.cfi_def_cfa_offset 32
	leal	40(%esp), %eax
	movl	$2, (%esp)
	movl	%eax, 8(%esp)
	movl	36(%esp), %eax
	movl	%eax, 4(%esp)
	call	___FSEXT_call_open_handlers
	addl	$28, %esp
	.cfi_def_cfa_offset 4
	ret
	.cfi_endproc
LFE12:
	.p2align 4,,15
	.globl	__creatnew
__creatnew:
LFB11:
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
	movl	$0, (%esp)
	movl	128(%esp), %ebp
	movl	132(%esp), %edi
	call	__use_lfn
	testl	%ebp, %ebp
	movsbl	%al, %ebx
	je	L24
	movl	136(%esp), %edx
	leal	40(%esp), %eax
	movl	%edx, 16(%esp)
	movl	%edi, 12(%esp)
	movl	%ebp, 8(%esp)
	movl	%eax, 4(%esp)
	movl	$2, (%esp)
	call	___FSEXT_call_open_handlers_wrapper.constprop.0
	testl	%eax, %eax
	je	L6
	movl	40(%esp), %eax
L5:
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
	.p2align 4,,7
L6:
	.cfi_restore_state
	movl	%ebp, (%esp)
	call	__put_path
	movl	136(%esp), %eax
	andl	$-8208, %eax
	movw	$16, 64(%esp)
	movl	%eax, %edx
	movw	$0, 48(%esp)
	orl	$8194, %edx
	testl	%ebx, %ebx
	movw	%dx, 60(%esp)
	movw	__osmajor, %dx
	jne	L25
	leal	-7(%edx), %ecx
	cmpw	$2, %cx
	ja	L10
	orl	$12290, %eax
	movw	%ax, 60(%esp)
L11:
	movw	$27648, 72(%esp)
L9:
	leal	44(%esp), %esi
	jmp	L14
	.p2align 4,,7
L26:
	movb	$91, 73(%esp)
	movw	$0, 60(%esp)
	movw	$0, 64(%esp)
	movw	$0, 48(%esp)
	xorl	%ebx, %ebx
L14:
	movl	__go32_info_block+12, %eax
	movl	%esi, 4(%esp)
	shrl	$4, %eax
	movl	$33, (%esp)
	movw	%di, 68(%esp)
	movw	%ax, 80(%esp)
	call	___dpmi_int
	movl	72(%esp), %eax
	cmpw	$28928, %ax
	je	L26
	testb	$1, 76(%esp)
	jne	L27
	testl	%ebx, %ebx
	je	L16
	cmpw	$1330, __os_trueversion
	je	L28
L16:
	andl	$65535, %eax
	movl	$4, 4(%esp)
	movl	%eax, (%esp)
	call	___file_handle_set
	movl	72(%esp), %eax
	addl	$108, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 20
	andl	$65535, %eax
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
L25:
	.cfi_restore_state
	subl	$7, %edx
	cmpw	$2, %dx
	ja	L8
	orl	$12290, %eax
	movw	%ax, 60(%esp)
L8:
	movw	$1, 76(%esp)
	movw	$29036, 72(%esp)
	jmp	L9
	.p2align 4,,7
L10:
	cmpw	$3, %dx
	ja	L11
	movb	$91, 73(%esp)
	movw	$0, 60(%esp)
	movw	$0, 64(%esp)
	jmp	L9
L28:
	movl	136(%esp), %eax
	movl	%ebp, (%esp)
	orl	$2, %eax
	movl	%eax, 4(%esp)
	call	__open
	movl	%eax, 40(%esp)
	cmpl	$-1, %eax
	je	L22
	movl	72(%esp), %edx
	movl	%eax, (%esp)
	andl	$65535, %edx
	movl	%edx, 4(%esp)
	call	___dup2
	movl	40(%esp), %eax
	movl	%eax, (%esp)
	call	__close
L22:
	movl	72(%esp), %eax
	jmp	L16
L24:
	movl	$14, _errno
	orl	$-1, %eax
	jmp	L5
L27:
	andl	$65535, %eax
	movl	%eax, (%esp)
	call	___doserr_to_errno
	movl	%eax, _errno
	orl	$-1, %eax
	jmp	L5
	.cfi_endproc
LFE11:
	.ident	"GCC: (GNU) 4.7.4"
