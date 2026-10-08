	.file	"gopvec.c"
	.section .text
	.p2align 4,,15
	.globl	__go32_dpmi_get_protected_mode_interrupt_vector
__go32_dpmi_get_protected_mode_interrupt_vector:
LFB0:
	.cfi_startproc
	movl	8(%esp), %eax
	addl	$4, %eax
	movl	%eax, 8(%esp)
	jmp	___dpmi_get_protected_mode_interrupt_vector
	.cfi_endproc
LFE0:
	.p2align 4,,15
	.globl	__go32_dpmi_set_protected_mode_interrupt_vector
__go32_dpmi_set_protected_mode_interrupt_vector:
LFB1:
	.cfi_startproc
	movl	8(%esp), %eax
	addl	$4, %eax
	movl	%eax, 8(%esp)
	jmp	___dpmi_set_protected_mode_interrupt_vector
	.cfi_endproc
LFE1:
	.ident	"GCC: (GNU) 4.7.4"
