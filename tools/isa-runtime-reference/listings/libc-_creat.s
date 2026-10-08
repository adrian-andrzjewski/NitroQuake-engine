	.file	"_creat.c"
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
	.globl	__creat
__creat:
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
	subl	$92, %esp
	.cfi_def_cfa_offset 112
	movl	112(%esp), %ebx
	movl	$0, (%esp)
	movl	116(%esp), %ebp
	call	__use_lfn
	testl	%ebx, %ebx
	je	L22
	movl	%eax, %esi
	leal	24(%esp), %eax
	movl	%ebp, 12(%esp)
	movl	%ebx, 8(%esp)
	movl	%eax, 4(%esp)
	movl	$2, (%esp)
	call	___FSEXT_call_open_handlers_wrapper.constprop.0
	testl	%eax, %eax
	jne	L23
	movl	%esi, %eax
	movsbl	%al, %esi
	testl	%esi, %esi
	je	L7
	movw	__osmajor, %ax
	movw	$1, 60(%esp)
	subl	$7, %eax
	movw	$29036, 56(%esp)
	cmpw	$2, %ax
	movw	$2, 44(%esp)
	jbe	L24
L8:
	movw	$18, 48(%esp)
	movw	$0, 32(%esp)
L9:
	leal	28(%esp), %edi
	jmp	L12
	.p2align 4,,7
L25:
	movb	$60, 57(%esp)
	movw	$0, 48(%esp)
	xorl	%esi, %esi
L12:
	movl	__go32_info_block+12, %eax
	movl	%ebx, (%esp)
	shrl	$4, %eax
	movw	%bp, 52(%esp)
	movw	%ax, 64(%esp)
	call	__put_path
	movl	%edi, 4(%esp)
	movl	$33, (%esp)
	call	___dpmi_int
	movl	56(%esp), %eax
	cmpw	$28928, %ax
	je	L25
	testb	$1, 60(%esp)
	jne	L26
	testl	%esi, %esi
	je	L14
	cmpw	$1330, __os_trueversion
	je	L27
L14:
	andl	$65535, %eax
	movl	$4, 4(%esp)
	movl	%eax, (%esp)
	call	___file_handle_set
	movl	56(%esp), %eax
	andl	$65535, %eax
L5:
	addl	$92, %esp
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
	ja	L10
	movw	$27648, 56(%esp)
	movw	$4098, 44(%esp)
	movw	$18, 48(%esp)
	movw	$0, 32(%esp)
	jmp	L9
	.p2align 4,,7
L23:
	movl	24(%esp), %eax
	addl	$92, %esp
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
L24:
	.cfi_restore_state
	movw	$4098, 44(%esp)
	jmp	L8
	.p2align 4,,7
L10:
	movb	$60, 57(%esp)
	movw	$0, 48(%esp)
	jmp	L9
L27:
	movl	$2, 4(%esp)
	movl	%ebx, (%esp)
	call	__open
	movl	%eax, 24(%esp)
	cmpl	$-1, %eax
	je	L20
	movl	56(%esp), %edx
	movl	%eax, (%esp)
	andl	$65535, %edx
	movl	%edx, 4(%esp)
	call	___dup2
	movl	24(%esp), %eax
	movl	%eax, (%esp)
	call	__close
L20:
	movl	56(%esp), %eax
	jmp	L14
L22:
	movl	$14, _errno
	orl	$-1, %eax
	jmp	L5
L26:
	andl	$65535, %eax
	movl	%eax, (%esp)
	call	___doserr_to_errno
	movl	%eax, _errno
	orl	$-1, %eax
	jmp	L5
	.cfi_endproc
LFE11:
	.ident	"GCC: (GNU) 4.7.4"
