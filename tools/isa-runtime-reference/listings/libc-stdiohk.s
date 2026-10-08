	.file	"stdiohk.c"
	.section .text
	.p2align 4,,15
	.globl	___stdio_cleanup_proc
___stdio_cleanup_proc:
LFB9:
	.cfi_startproc
	subl	$28, %esp
	.cfi_def_cfa_offset 32
	movl	$_fcloseall_helper, (%esp)
	call	__fwalk
	addl	$28, %esp
	.cfi_def_cfa_offset 4
	ret
	.cfi_endproc
LFE9:
	.p2align 4,,15
_fcloseall_helper:
LFB8:
	.cfi_startproc
	pushl	%ebx
	.cfi_def_cfa_offset 8
	.cfi_offset 3, -8
	subl	$24, %esp
	.cfi_def_cfa_offset 32
	movl	32(%esp), %ebx
	movl	%ebx, (%esp)
	call	_fflush
	cmpl	$2, 20(%ebx)
	jg	L7
	addl	$24, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 8
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L7:
	.cfi_restore_state
	movl	%ebx, 32(%esp)
	addl	$24, %esp
	.cfi_def_cfa_offset 8
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 4
	jmp	_fclose
	.cfi_endproc
LFE8:
	.globl	___stdio_cleanup_hook
	.section .data
	.p2align 2
___stdio_cleanup_hook:
	.long	___stdio_cleanup_proc
	.ident	"GCC: (GNU) 4.7.4"
