	.file	"doslk64.c"
	.section .text
	.p2align 4,,15
	.globl	__dos_lk64
__dos_lk64:
LFB0:
	.cfi_startproc
	pushl	%edi
	.cfi_def_cfa_offset 8
	.cfi_offset 7, -8
	pushl	%esi
	.cfi_def_cfa_offset 12
	.cfi_offset 6, -12
	pushl	%ebx
	.cfi_def_cfa_offset 16
	.cfi_offset 3, -16
	subl	$80, %esp
	.cfi_def_cfa_offset 96
	movl	100(%esp), %ecx
	movl	108(%esp), %eax
	movl	104(%esp), %ebx
	movl	96(%esp), %esi
	movl	112(%esp), %edx
	movw	%si, 44(%esp)
	movl	%ebx, %edi
	movl	%ecx, %esi
	movw	%cx, 48(%esp)
	movl	%edx, %ebx
	movl	%eax, %ecx
	movw	%ax, 28(%esp)
	leal	28(%esp), %eax
	movl	$33, (%esp)
	shrdl	$16, %ebx, %ecx
	shrdl	$16, %edi, %esi
	movl	%eax, 4(%esp)
	movw	$23552, 56(%esp)
	movw	%si, 52(%esp)
	movw	%cx, 32(%esp)
	call	___dpmi_int
	xorl	%eax, %eax
	testb	$1, 60(%esp)
	je	L2
	movl	56(%esp), %eax
	andl	$65535, %eax
L2:
	addl	$80, %esp
	.cfi_def_cfa_offset 16
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 12
	popl	%esi
	.cfi_restore 6
	.cfi_def_cfa_offset 8
	popl	%edi
	.cfi_restore 7
	.cfi_def_cfa_offset 4
	ret
	.cfi_endproc
LFE0:
	.ident	"GCC: (GNU) 4.7.4"
