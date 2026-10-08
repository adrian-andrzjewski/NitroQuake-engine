	.file	"dmp.c"
	.section .text
	.p2align 4,,15
	.globl	___dosmemput
___dosmemput:
LFB3:
	.cfi_startproc
	subl	$44, %esp
	.cfi_def_cfa_offset 48
/APP
# 36 "c:/djgpp/include/sys/segments.h" 1
	movw %ds,%ax
# 0 "" 2
/NO_APP
	movl	52(%esp), %edx
	andl	$65535, %eax
	movl	%edx, 16(%esp)
	movl	56(%esp), %edx
	movl	%edx, 12(%esp)
	movw	__go32_info_block+26, %dx
	andl	$65535, %edx
	movl	%eax, (%esp)
	movl	%edx, 8(%esp)
	movl	48(%esp), %edx
	movl	%edx, 4(%esp)
	call	___movedata
	addl	$44, %esp
	.cfi_def_cfa_offset 4
	ret
	.cfi_endproc
LFE3:
	.ident	"GCC: (GNU) 4.7.4"
