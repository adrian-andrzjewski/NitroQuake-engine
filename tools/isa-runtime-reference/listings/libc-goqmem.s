	.file	"goqmem.c"
	.section .text
	.p2align 4,,15
	.globl	__go32_dpmi_remaining_physical_memory
__go32_dpmi_remaining_physical_memory:
LFB0:
	.cfi_startproc
	subl	$76, %esp
	.cfi_def_cfa_offset 80
	leal	16(%esp), %eax
	movl	%eax, (%esp)
	call	___dpmi_get_free_memory_information
	movl	36(%esp), %eax
	testl	%eax, %eax
	jne	L6
	movl	16(%esp), %eax
	addl	$76, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L6:
	.cfi_restore_state
	sall	$12, %eax
	addl	$76, %esp
	.cfi_def_cfa_offset 4
	ret
	.cfi_endproc
LFE0:
	.p2align 4,,15
	.globl	__go32_dpmi_remaining_virtual_memory
__go32_dpmi_remaining_virtual_memory:
LFB1:
	.cfi_startproc
	subl	$76, %esp
	.cfi_def_cfa_offset 80
	leal	16(%esp), %eax
	movl	%eax, (%esp)
	call	___dpmi_get_free_memory_information
	movl	16(%esp), %eax
	addl	$76, %esp
	.cfi_def_cfa_offset 4
	ret
	.cfi_endproc
LFE1:
	.ident	"GCC: (GNU) 4.7.4"
