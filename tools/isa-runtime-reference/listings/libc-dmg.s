	.file	"dmg.c"
	.section .text
	.p2align 4,,15
	.globl	___dosmemget
___dosmemget:
LFB3:
	.cfi_startproc
	subl	$44, %esp
	.cfi_def_cfa_offset 48
/APP
# 36 "c:/djgpp/include/sys/segments.h" 1
	movw %ds,%ax
# 0 "" 2
/NO_APP
	andl	$65535, %eax
	movl	52(%esp), %edx
	movl	%eax, 8(%esp)
	movl	48(%esp), %eax
	movl	%eax, 4(%esp)
	movw	__go32_info_block+26, %ax
	movl	%edx, 16(%esp)
	andl	$65535, %eax
	movl	56(%esp), %edx
	movl	%eax, (%esp)
	movl	%edx, 12(%esp)
	call	___movedata
	addl	$44, %esp
	.cfi_def_cfa_offset 4
	ret
	.cfi_endproc
LFE3:
	.ident	"GCC: (GNU) 4.7.4"
