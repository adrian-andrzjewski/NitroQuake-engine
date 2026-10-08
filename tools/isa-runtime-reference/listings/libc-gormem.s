	.file	"gormem.c"
	.section .text
	.p2align 4,,15
	.globl	__go32_dpmi_allocate_dos_memory
__go32_dpmi_allocate_dos_memory:
LFB0:
	.cfi_startproc
	pushl	%ebx
	.cfi_def_cfa_offset 8
	.cfi_offset 3, -8
	subl	$40, %esp
	.cfi_def_cfa_offset 48
	movl	48(%esp), %ebx
	leal	28(%esp), %eax
	movl	%eax, 4(%esp)
	movl	(%ebx), %eax
	movl	%eax, (%esp)
	call	___dpmi_allocate_dos_memory
	cmpl	$-1, %eax
	je	L6
	movw	%ax, 12(%ebx)
	movl	28(%esp), %eax
	movw	%ax, 8(%ebx)
	addl	$40, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 8
	xorl	%eax, %eax
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L6:
	.cfi_restore_state
	movl	28(%esp), %eax
	movw	$0, 8(%ebx)
	movl	%eax, (%ebx)
	movw	___dpmi_error, %ax
	addl	$40, %esp
	.cfi_def_cfa_offset 8
	andl	$65535, %eax
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 4
	ret
	.cfi_endproc
LFE0:
	.p2align 4,,15
	.globl	__go32_dpmi_free_dos_memory
__go32_dpmi_free_dos_memory:
LFB1:
	.cfi_startproc
	subl	$28, %esp
	.cfi_def_cfa_offset 32
	movl	32(%esp), %eax
	movl	8(%eax), %eax
	andl	$65535, %eax
	movl	%eax, (%esp)
	call	___dpmi_free_dos_memory
	xorl	%edx, %edx
	incl	%eax
	jne	L8
	movw	___dpmi_error, %dx
	andl	$65535, %edx
L8:
	movl	%edx, %eax
	addl	$28, %esp
	.cfi_def_cfa_offset 4
	ret
	.cfi_endproc
LFE1:
	.p2align 4,,15
	.globl	__go32_dpmi_resize_dos_memory
__go32_dpmi_resize_dos_memory:
LFB2:
	.cfi_startproc
	pushl	%ebx
	.cfi_def_cfa_offset 8
	.cfi_offset 3, -8
	subl	$40, %esp
	.cfi_def_cfa_offset 48
	movl	48(%esp), %ebx
	leal	28(%esp), %eax
	movl	%eax, 8(%esp)
	movl	(%ebx), %eax
	movl	%eax, 4(%esp)
	movl	8(%ebx), %eax
	andl	$65535, %eax
	movl	%eax, (%esp)
	call	___dpmi_resize_dos_memory
	xorl	%edx, %edx
	testl	%eax, %eax
	je	L12
	movl	28(%esp), %eax
	movw	___dpmi_error, %dx
	movl	%eax, (%ebx)
	andl	$65535, %edx
L12:
	addl	$40, %esp
	.cfi_def_cfa_offset 8
	movl	%edx, %eax
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 4
	ret
	.cfi_endproc
LFE2:
	.ident	"GCC: (GNU) 4.7.4"
