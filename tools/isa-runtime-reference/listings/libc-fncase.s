	.file	"fncase.c"
	.section .text
LC0:
	.ascii "FNCASE\0"
	.p2align 4,,15
	.globl	__preserve_fncase
__preserve_fncase:
LFB0:
	.cfi_startproc
	movb	$1, %al
	testb	$32, __crt0_startup_flags+1
	je	L9
	ret
	.p2align 4,,7
L9:
	subl	$28, %esp
	.cfi_def_cfa_offset 32
	movl	$LC0, (%esp)
	call	_getenv
	testl	%eax, %eax
	je	L4
	movb	(%eax), %al
	andl	$255, %eax
	cmpb	$121, ___dj_ctype_tolower+1(%eax)
	sete	%al
L2:
	addl	$28, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L4:
	.cfi_restore_state
	xorl	%eax, %eax
	jmp	L2
	.cfi_endproc
LFE0:
	.ident	"GCC: (GNU) 4.7.4"
