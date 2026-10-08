	.file	"d_getdrv.c"
	.section .text
	.p2align 4,,15
	.globl	__dos_getdrive
__dos_getdrive:
LFB6:
	.cfi_startproc
	subl	$92, %esp
	.cfi_def_cfa_offset 96
	leal	28(%esp), %eax
	movl	$33, (%esp)
	movl	%eax, 4(%esp)
	movb	$25, 57(%esp)
	call	___dpmi_int
	xorl	%edx, %edx
	movb	56(%esp), %dl
	movl	96(%esp), %eax
	incl	%edx
	movl	%edx, (%eax)
	addl	$92, %esp
	.cfi_def_cfa_offset 4
	ret
	.cfi_endproc
LFE6:
	.ident	"GCC: (GNU) 4.7.4"
