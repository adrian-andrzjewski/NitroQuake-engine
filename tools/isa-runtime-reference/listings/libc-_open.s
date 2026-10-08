	.file	"_open.c"
	.section .text
	.p2align 4,,15
___FSEXT_call_open_handlers_wrapper.constprop.0:
LFB12:
	.cfi_startproc
	subl	$28, %esp
	.cfi_def_cfa_offset 32
	leal	40(%esp), %eax
	movl	$1, (%esp)
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
	.globl	__open
__open:
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
	movl	128(%esp), %edi
	movl	$0, (%esp)
	movl	132(%esp), %ebx
	call	__use_lfn
	testl	%edi, %edi
	je	L28
	movl	%eax, %esi
	leal	40(%esp), %eax
	movl	%ebx, 12(%esp)
	movl	%edi, 8(%esp)
	movl	%eax, 4(%esp)
	movl	$1, (%esp)
	call	___FSEXT_call_open_handlers_wrapper.constprop.0
	testl	%eax, %eax
	jne	L29
	movl	%esi, %eax
	testb	%al, %al
	je	L7
	cmpw	$1330, __os_trueversion
	je	L30
	movzbl	%bl, %ebp
	movl	%ebp, %edx
	leal	44(%esp), %esi
L12:
	movw	__osmajor, %ax
	movw	$1, 76(%esp)
	subl	$7, %eax
	movw	$29036, 72(%esp)
	cmpw	$2, %ax
	movw	%dx, 60(%esp)
	jbe	L19
L20:
	movw	$1, 64(%esp)
	movw	$0, 48(%esp)
L14:
	movl	__go32_info_block+12, %eax
	movl	%edi, (%esp)
	shrl	$4, %eax
	movw	%ax, 80(%esp)
	call	__put_path
	jmp	L25
	.p2align 4,,7
L31:
	movb	$61, 73(%esp)
	movb	%bl, 72(%esp)
	movw	$0, 64(%esp)
L25:
	movl	%esi, 4(%esp)
	movl	$33, (%esp)
	movw	$0, 68(%esp)
	call	___dpmi_int
	movl	72(%esp), %eax
	cmpw	$28928, %ax
	je	L31
	testb	$1, 76(%esp)
	jne	L32
L18:
	andl	$65535, %eax
	movl	$4, 4(%esp)
	movl	%eax, (%esp)
	call	___file_handle_set
	movl	72(%esp), %eax
	andl	$65535, %eax
L24:
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
L7:
	.cfi_restore_state
	movw	__osmajor, %ax
	subl	$7, %eax
	cmpw	$2, %ax
	ja	L15
	movzbl	%bl, %eax
	orb	$16, %ah
	movw	$27648, 72(%esp)
	movw	%ax, 60(%esp)
	movw	$1, 64(%esp)
	movw	$0, 48(%esp)
	leal	44(%esp), %esi
	jmp	L14
	.p2align 4,,7
L29:
	movl	40(%esp), %eax
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
L15:
	.cfi_restore_state
	movb	$61, 73(%esp)
	movb	%bl, 72(%esp)
	movw	$0, 64(%esp)
	leal	44(%esp), %esi
	jmp	L14
	.p2align 4,,7
L19:
	orl	$4096, %ebp
	movw	%bp, 60(%esp)
	jmp	L20
L30:
	movl	__go32_info_block+12, %eax
	movl	%edi, (%esp)
	shrl	$4, %eax
	movw	$1, 76(%esp)
	movw	$29024, 72(%esp)
	movw	$1, 68(%esp)
	movw	%ax, 80(%esp)
	movw	$0, 48(%esp)
	movw	%ax, 78(%esp)
	call	__put_path
	leal	44(%esp), %esi
	movl	$33, (%esp)
	movl	%esi, 4(%esp)
	movw	%ax, 44(%esp)
	call	___dpmi_int
	testb	$1, 76(%esp)
	jne	L9
	movzbl	%bl, %eax
	movw	%ax, 60(%esp)
	movl	44(%esp), %eax
	movw	$27648, 72(%esp)
	movw	$1, 64(%esp)
	movw	%ax, 48(%esp)
	jmp	L25
L28:
	movl	$14, _errno
	orl	$-1, %eax
	jmp	L24
L9:
	movl	%esi, 4(%esp)
	movl	$33, (%esp)
	movw	$1, 76(%esp)
	movw	$28995, 72(%esp)
	movb	$0, 60(%esp)
	movw	$0, 64(%esp)
	call	___dpmi_int
	testb	$1, 76(%esp)
	je	L11
	movzbl	%bl, %ebp
	movl	%ebp, %edx
	jmp	L12
L32:
	andl	$65535, %eax
	movl	%eax, (%esp)
	call	___doserr_to_errno
	movl	%eax, _errno
	orl	$-1, %eax
	jmp	L24
L11:
	movzbl	%bl, %ebp
	movl	%ebp, %edx
	movl	%esi, 4(%esp)
	movl	$33, (%esp)
	movl	%edx, 28(%esp)
	movw	$27648, 72(%esp)
	movw	%bp, 60(%esp)
	movw	$1, 64(%esp)
	movw	$0, 48(%esp)
	movw	$0, 68(%esp)
	call	___dpmi_int
	testb	$1, 76(%esp)
	movl	28(%esp), %edx
	jne	L12
	movl	72(%esp), %eax
	jmp	L18
	.cfi_endproc
LFE11:
	.ident	"GCC: (GNU) 4.7.4"
