	.file	"atexit.c"
	.section .text
	.p2align 4,,15
	.globl	_atexit
_atexit:
LFB0:
	.cfi_startproc
	pushl	%ebx
	.cfi_def_cfa_offset 8
	.cfi_offset 3, -8
	subl	$24, %esp
	.cfi_def_cfa_offset 32
	movl	32(%esp), %ebx
	testl	%ebx, %ebx
	je	L4
	movl	$8, (%esp)
	call	_malloc
	testl	%eax, %eax
	je	L4
	movl	___atexit_ptr, %edx
	movl	%ebx, 4(%eax)
	movl	%edx, (%eax)
	movl	%eax, ___atexit_ptr
	xorl	%eax, %eax
L3:
	addl	$24, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 8
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L4:
	.cfi_restore_state
	orl	$-1, %eax
	jmp	L3
	.cfi_endproc
LFE0:
	.ident	"GCC: (GNU) 4.7.4"
