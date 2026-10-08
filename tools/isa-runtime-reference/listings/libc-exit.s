	.file	"exit.c"
/APP
	.long ___stdio_cleanup_proc
/NO_APP
	.section .text
	.p2align 4,,15
	.globl	_exit
_exit:
LFB6:
	.cfi_startproc
	pushl	%esi
	.cfi_def_cfa_offset 8
	.cfi_offset 6, -8
	pushl	%ebx
	.cfi_def_cfa_offset 12
	.cfi_offset 3, -12
	subl	$20, %esp
	.cfi_def_cfa_offset 32
	movl	___atexit_ptr, %ebx
	movl	$0, ___atexit_ptr
	testl	%ebx, %ebx
	je	L6
	.p2align 4,,7
L17:
	call	*4(%ebx)
	movl	(%ebx), %esi
	movl	%ebx, (%esp)
	movl	%esi, %ebx
	call	_free
	testl	%esi, %esi
	jne	L17
L6:
	movl	$djgpp_last_dtor, %esi
	xorl	%ebx, %ebx
	subl	$djgpp_first_dtor, %esi
	sarl	$2, %esi
	testl	%esi, %esi
	jle	L4
	.p2align 4,,7
L16:
	call	*djgpp_first_dtor(,%ebx,4)
	incl	%ebx
	cmpl	%esi, %ebx
	jne	L16
L4:
	movl	___stdio_cleanup_hook, %eax
	testl	%eax, %eax
	je	L8
	call	*%eax
L8:
	movl	___fd_properties_cleanup_hook, %eax
	testl	%eax, %eax
	je	L9
	call	*%eax
L9:
	movl	___FSEXT_exit_hook, %eax
	testl	%eax, %eax
	je	L10
	call	*%eax
L10:
	movl	$8, 4(%esp)
	movl	$0, (%esp)
	call	___setmode
	movl	32(%esp), %eax
	movl	%eax, (%esp)
	call	__exit
	.cfi_endproc
LFE6:
	.globl	___fd_properties_cleanup_hook
	.section	.bss
	.p2align 2
___fd_properties_cleanup_hook:
	.space 4
	.globl	___FSEXT_exit_hook
	.p2align 2
___FSEXT_exit_hook:
	.space 4
.comm ___stdio_cleanup_hook,16
	.globl	___atexit_ptr
	.p2align 2
___atexit_ptr:
	.space 4
	.ident	"GCC: (GNU) 4.7.4"
