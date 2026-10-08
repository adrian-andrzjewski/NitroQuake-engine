	.file	"2f_1680.c"
	.section .text
	.p2align 4,,15
	.globl	___dpmi_yield
___dpmi_yield:
LFB0:
	.cfi_startproc
	subl	$92, %esp
	.cfi_def_cfa_offset 96
	leal	28(%esp), %eax
	movl	$47, (%esp)
	movl	%eax, 4(%esp)
	movw	$5760, 56(%esp)
	movw	$0, 60(%esp)
	movw	$0, 74(%esp)
	movw	$0, 76(%esp)
	call	___dpmi_simulate_real_mode_interrupt
	cmpb	$-128, 56(%esp)
	jne	L1
	movl	$27, _errno
L1:
	addl	$92, %esp
	.cfi_def_cfa_offset 4
	ret
	.cfi_endproc
LFE0:
	.ident	"GCC: (GNU) 4.7.4"
