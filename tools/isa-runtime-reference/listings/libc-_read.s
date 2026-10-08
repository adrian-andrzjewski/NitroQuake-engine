	.file	"_read.c"
	.section .text
	.p2align 4,,15
___FSEXT_func_wrapper.constprop.0:
LFB6:
	.cfi_startproc
	subl	$28, %esp
	.cfi_def_cfa_offset 32
	leal	44(%esp), %eax
	movl	$3, (%esp)
	movl	%eax, 8(%esp)
	movl	40(%esp), %eax
	movl	%eax, 4(%esp)
	call	*32(%esp)
	addl	$28, %esp
	.cfi_def_cfa_offset 4
	ret
	.cfi_endproc
LFE6:
	.p2align 4,,15
	.globl	__read
__read:
LFB5:
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
	subl	$124, %esp
	.cfi_def_cfa_offset 144
	movl	144(%esp), %ebp
	movl	152(%esp), %ebx
	movl	%ebp, (%esp)
	call	___FSEXT_get_function
	testl	%eax, %eax
	je	L4
	movl	148(%esp), %edx
	movl	%ebx, 20(%esp)
	movl	%edx, 16(%esp)
	leal	56(%esp), %edx
	movl	%ebp, 12(%esp)
	movl	%edx, 8(%esp)
	movl	$3, 4(%esp)
	movl	%eax, (%esp)
	call	___FSEXT_func_wrapper.constprop.0
	testl	%eax, %eax
	jne	L28
L4:
	xorl	%esi, %esi
	movl	%esi, 44(%esp)
L10:
	movl	__go32_info_block+16, %eax
	movl	%ebx, %esi
	cmpl	%eax, %ebx
	jbe	L7
	movl	%eax, %esi
L7:
	movl	__go32_info_block+12, %eax
	movl	$33, (%esp)
	movl	%eax, %edi
	movw	$16128, 88(%esp)
	shrl	$4, %eax
	andl	$15, %edi
	movw	%ax, 96(%esp)
	leal	60(%esp), %eax
	movl	%eax, 4(%esp)
	movw	%bp, 76(%esp)
	movw	%si, 84(%esp)
	movw	%di, 80(%esp)
	call	___dpmi_int
	testb	$1, 92(%esp)
	jne	L29
	movl	88(%esp), %edi
	movl	44(%esp), %edx
	andl	$65535, %edi
	subl	%esi, %ebx
	addl	%edi, %edx
	testl	%edi, %edi
	movl	%edx, 44(%esp)
	jne	L30
L9:
	movl	148(%esp), %eax
	addl	%edi, %eax
	testl	%ebx, %ebx
	movl	%eax, 148(%esp)
	je	L25
	cmpl	%edi, %esi
	je	L10
L25:
	movl	44(%esp), %esi
	addl	$124, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 20
	movl	%esi, %eax
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
L30:
	.cfi_restore_state
	movl	148(%esp), %edx
	movl	__go32_info_block+12, %eax
	movl	%edx, 8(%esp)
	movl	%edi, 4(%esp)
	movl	%eax, (%esp)
	call	___dosmemget
	jmp	L9
	.p2align 4,,7
L28:
	movl	56(%esp), %esi
	addl	$124, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 20
	movl	%esi, %eax
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
L29:
	.cfi_restore_state
	movl	88(%esp), %eax
	orl	$-1, %esi
	andl	$65535, %eax
	movl	%eax, (%esp)
	call	___doserr_to_errno
	movl	%eax, _errno
	addl	$124, %esp
	.cfi_def_cfa_offset 20
	movl	%esi, %eax
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
	.cfi_endproc
LFE5:
	.ident	"GCC: (GNU) 4.7.4"
