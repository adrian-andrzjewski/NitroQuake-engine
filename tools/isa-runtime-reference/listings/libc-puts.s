	.file	"puts.c"
	.section .text
	.p2align 4,,15
	.globl	_puts
_puts:
LFB0:
	.cfi_startproc
	pushl	%ebx
	.cfi_def_cfa_offset 8
	.cfi_offset 3, -8
	subl	$24, %esp
	.cfi_def_cfa_offset 32
	movl	32(%esp), %ebx
	movsbl	(%ebx), %eax
	incl	%ebx
	testl	%eax, %eax
	je	L4
	.p2align 4,,7
L5:
	movl	%eax, (%esp)
	call	_putchar
	movsbl	(%ebx), %eax
	incl	%ebx
	testl	%eax, %eax
	jne	L5
L4:
	movl	$10, 32(%esp)
	addl	$24, %esp
	.cfi_def_cfa_offset 8
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 4
	jmp	_putchar
	.cfi_endproc
LFE0:
	.ident	"GCC: (GNU) 4.7.4"
