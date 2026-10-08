	.file	"scsetc.c"
	.section .text
	.p2align 4,,15
	.globl	_ScreenSetCursor
_ScreenSetCursor:
LFB23:
	.cfi_startproc
	subl	$92, %esp
	.cfi_def_cfa_offset 96
	movl	96(%esp), %eax
	movl	$16, (%esp)
	movb	%al, 49(%esp)
	movl	100(%esp), %eax
	movb	%al, 48(%esp)
	leal	28(%esp), %eax
	movl	%eax, 4(%esp)
	movb	$2, 57(%esp)
	movb	$0, 45(%esp)
	call	___dpmi_int
	addl	$92, %esp
	.cfi_def_cfa_offset 4
	ret
	.cfi_endproc
LFE23:
	.ident	"GCC: (GNU) 4.7.4"
