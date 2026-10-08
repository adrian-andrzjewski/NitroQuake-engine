	.file	"getdtabl.c"
	.section .text
	.p2align 4,,15
	.globl	___getdtablesize
___getdtablesize:
LFB0:
	.cfi_startproc
	movl	$255, %eax
	ret
	.cfi_endproc
LFE0:
	.ident	"GCC: (GNU) 4.7.4"
