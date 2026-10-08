	.file	"_main.c"
	.section .text
	.p2align 4,,15
	.globl	___main
___main:
LFB0:
	.cfi_startproc
	movl	___bss_count, %eax
	cmpl	%eax, _been_there_done_that.1376
	je	L8
	pushl	%esi
	.cfi_def_cfa_offset 8
	.cfi_offset 6, -8
	movl	$djgpp_last_ctor, %esi
	subl	$djgpp_first_ctor, %esi
	pushl	%ebx
	.cfi_def_cfa_offset 12
	.cfi_offset 3, -12
	sarl	$2, %esi
	pushl	%edx
	.cfi_def_cfa_offset 16
	testl	%esi, %esi
	movl	%eax, _been_there_done_that.1376
	jle	L1
	xorl	%ebx, %ebx
	.p2align 4,,7
L4:
	call	*djgpp_first_ctor(,%ebx,4)
	incl	%ebx
	cmpl	%esi, %ebx
	jne	L4
L1:
	popl	%eax
	.cfi_def_cfa_offset 12
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 8
	popl	%esi
	.cfi_restore 6
	.cfi_def_cfa_offset 4
L8:
	ret
	.cfi_endproc
LFE0:
	.section .data
	.p2align 2
_been_there_done_that.1376:
	.long	-1
	.ident	"GCC: (GNU) 4.7.4"
