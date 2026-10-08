	.file	"stricmp.c"
	.section .text
	.p2align 4,,15
	.globl	___stricmp
___stricmp:
LFB0:
	.cfi_startproc
	pushl	%esi
	.cfi_def_cfa_offset 8
	.cfi_offset 6, -8
	pushl	%ebx
	.cfi_def_cfa_offset 12
	.cfi_offset 3, -12
	movl	12(%esp), %edx
	movl	16(%esp), %ecx
	jmp	L12
	.p2align 4,,7
L14:
	movl	%esi, %eax
	testb	%al, %al
	je	L8
	incl	%edx
	incl	%ecx
L12:
	movzbl	(%edx), %esi
	xorl	%ebx, %ebx
	movl	%esi, %eax
	andl	$255, %eax
	movb	(%ecx), %bl
	movb	___dj_ctype_tolower+1(%eax), %al
	movb	___dj_ctype_tolower+1(%ebx), %bl
	cmpb	%bl, %al
	je	L14
	andl	$255, %ebx
	andl	$255, %eax
	subl	%ebx, %eax
	popl	%ebx
	.cfi_remember_state
	.cfi_restore 3
	.cfi_def_cfa_offset 8
	popl	%esi
	.cfi_restore 6
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L8:
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
