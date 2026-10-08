	.file	"usleep.c"
	.section .text
	.p2align 4,,15
	.globl	_usleep
_usleep:
LFB1:
	.cfi_startproc
	pushl	%esi
	.cfi_def_cfa_offset 8
	.cfi_offset 6, -8
	pushl	%ebx
	.cfi_def_cfa_offset 12
	.cfi_offset 3, -12
	pushl	%ecx
	.cfi_def_cfa_offset 16
	call	_clock
	movl	%eax, %esi
	movl	16(%esp), %eax
	shrl	$10, %eax
	leal	(%eax,%eax,2), %edx
	leal	(%eax,%edx,4), %eax
	movl	$206615623, %edx
	leal	0(,%eax,8), %ebx
	subl	%eax, %ebx
	movl	%ebx, %eax
	mull	%edx
	subl	%edx, %ebx
	shrl	%ebx
	addl	%edx, %ebx
	shrl	$9, %ebx
	jmp	L3
	.p2align 4,,7
L6:
	call	___dpmi_yield
L3:
	call	_clock
	subl	%esi, %eax
	cmpl	%eax, %ebx
	jg	L6
	popl	%edx
	.cfi_def_cfa_offset 12
	xorl	%eax, %eax
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 8
	popl	%esi
	.cfi_restore 6
	.cfi_def_cfa_offset 4
	ret
	.cfi_endproc
LFE1:
	.ident	"GCC: (GNU) 4.7.4"
