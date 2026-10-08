	.file	"printf.c"
	.section .text
	.p2align 4,,15
	.globl	_printf
_printf:
LFB8:
	.cfi_startproc
	pushl	%ebx
	.cfi_def_cfa_offset 8
	.cfi_offset 3, -8
	subl	$24, %esp
	.cfi_def_cfa_offset 32
	leal	36(%esp), %eax
	movl	$___dj_stdout, 8(%esp)
	movl	%eax, 4(%esp)
	movl	32(%esp), %eax
	movl	%eax, (%esp)
	call	__doprnt
	movl	___dj_stdout+16, %edx
	movl	%eax, %ebx
	testb	$4, %dl
	jne	L12
L2:
	andl	$128, %edx
	jne	L13
L3:
	addl	$24, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 8
	movl	%ebx, %eax
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L12:
	.cfi_restore_state
	movl	$___dj_stdout, (%esp)
	call	_fflush
	movl	___dj_stdout+16, %edx
	jmp	L2
	.p2align 4,,7
L13:
	orl	$-1, %ebx
	jmp	L3
	.cfi_endproc
LFE8:
	.ident	"GCC: (GNU) 4.7.4"
