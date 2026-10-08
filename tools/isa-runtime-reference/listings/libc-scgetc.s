	.file	"scgetc.c"
	.section .text
	.p2align 4,,15
	.globl	_ScreenGetCursor
_ScreenGetCursor:
LFB23:
	.cfi_startproc
	subl	$92, %esp
	.cfi_def_cfa_offset 96
	leal	28(%esp), %eax
	movl	$16, (%esp)
	movl	%eax, 4(%esp)
	movb	$3, 57(%esp)
	movb	$0, 45(%esp)
	call	___dpmi_int
	movl	96(%esp), %eax
	xorl	%edx, %edx
	movb	49(%esp), %dl
	movl	%edx, (%eax)
	movl	100(%esp), %eax
	xorl	%edx, %edx
	movb	48(%esp), %dl
	movl	%edx, (%eax)
	addl	$92, %esp
	.cfi_def_cfa_offset 4
	ret
	.cfi_endproc
LFE23:
	.ident	"GCC: (GNU) 4.7.4"
