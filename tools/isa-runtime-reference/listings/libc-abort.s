	.file	"abort.c"
	.section .text
	.p2align 4,,15
	.globl	_abort
_abort:
LFB0:
	.cfi_startproc
	subl	$28, %esp
	.cfi_def_cfa_offset 32
	movl	$8, 8(%esp)
	movl	$_msg, 4(%esp)
	movl	$2, (%esp)
	call	__write
	movl	$288, (%esp)
	call	_raise
	movl	$1, (%esp)
	call	__exit
	.cfi_endproc
LFE0:
	.section .data
_msg:
	.ascii "Abort!\15\12\0"
	.ident	"GCC: (GNU) 4.7.4"
