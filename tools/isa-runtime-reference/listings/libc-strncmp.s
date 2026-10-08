	.file	"strncmp.c"
	.section .text
	.p2align 4,,15
	.globl	_strncmp
_strncmp:
LFB0:
	.cfi_startproc
	pushl	%esi
	.cfi_def_cfa_offset 8
	.cfi_offset 6, -8
	pushl	%ebx
	.cfi_def_cfa_offset 12
	.cfi_offset 3, -12
	movl	20(%esp), %esi
	xorl	%eax, %eax
	movl	12(%esp), %ecx
	movl	16(%esp), %edx
	testl	%esi, %esi
	jne	L7
	jmp	L2
	.p2align 4,,7
L3:
	incl	%ecx
	testb	%al, %al
	je	L6
	decl	%esi
	je	L6
L7:
	movb	(%edx), %bl
	movb	(%ecx), %al
	incl	%edx
	cmpb	%bl, %al
	je	L3
	xorl	%eax, %eax
	movb	-1(%edx), %dl
	movb	(%ecx), %al
	andl	$255, %edx
	subl	%edx, %eax
L2:
	popl	%ebx
	.cfi_remember_state
	.cfi_restore 3
	.cfi_def_cfa_offset 8
	popl	%esi
	.cfi_restore 6
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L6:
	.cfi_restore_state
	xorl	%eax, %eax
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 8
	popl	%esi
	.cfi_restore 6
	.cfi_def_cfa_offset 4
	ret
	.cfi_endproc
LFE0:
	.ident	"GCC: (GNU) 4.7.4"
