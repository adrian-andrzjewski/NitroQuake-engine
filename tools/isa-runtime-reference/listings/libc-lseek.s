	.file	"lseek.c"
	.section .text
	.p2align 4,,15
___FSEXT_func_wrapper.constprop.0:
LFB11:
	.cfi_startproc
	subl	$28, %esp
	.cfi_def_cfa_offset 32
	leal	44(%esp), %eax
	movl	$9, (%esp)
	movl	%eax, 8(%esp)
	movl	40(%esp), %eax
	movl	%eax, 4(%esp)
	call	*32(%esp)
	addl	$28, %esp
	.cfi_def_cfa_offset 4
	ret
	.cfi_endproc
LFE11:
	.p2align 4,,15
	.globl	___lseek
___lseek:
LFB10:
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
	subl	$48, %esp
	.cfi_def_cfa_offset 64
	movl	64(%esp), %ebx
	movl	68(%esp), %esi
	movl	%ebx, (%esp)
	movl	72(%esp), %edi
	call	___FSEXT_get_function
	testl	%eax, %eax
	je	L4
	leal	44(%esp), %edx
	movl	%edi, 20(%esp)
	movl	%esi, 16(%esp)
	movl	%ebx, 12(%esp)
	movl	%edx, 8(%esp)
	movl	$9, 4(%esp)
	movl	%eax, (%esp)
	call	___FSEXT_func_wrapper.constprop.0
	testl	%eax, %eax
	jne	L17
L4:
	movl	%esi, %eax
	movl	%edi, 12(%esp)
	sarl	$31, %eax
	movl	%esi, 4(%esp)
	movl	%eax, 8(%esp)
	movl	%ebx, (%esp)
	call	___llseek
	andl	%eax, %edx
	movl	%eax, %ecx
	incl	%edx
	je	L8
	movl	%ecx, %eax
	andl	$2147483647, %eax
	testl	%ecx, %ecx
	js	L18
L6:
	addl	$48, %esp
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
L18:
	.cfi_restore_state
	addl	$48, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 16
	movl	%ecx, %eax
	orl	$-2147483648, %eax
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
	movl	44(%esp), %eax
	addl	$48, %esp
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
L8:
	.cfi_restore_state
	orl	$-1, %eax
	jmp	L6
	.cfi_endproc
LFE10:
	.ident	"GCC: (GNU) 4.7.4"
