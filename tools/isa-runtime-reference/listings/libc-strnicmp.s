	.file	"strnicmp.c"
	.section .text
	.p2align 4,,15
	.globl	___strnicmp
___strnicmp:
LFB0:
	.cfi_startproc
	pushl	%edi
	.cfi_def_cfa_offset 8
	.cfi_offset 7, -8
	pushl	%esi
	.cfi_def_cfa_offset 12
	.cfi_offset 6, -12
	pushl	%ebx
	.cfi_def_cfa_offset 16
	.cfi_offset 3, -16
	xorl	%eax, %eax
	movl	24(%esp), %edi
	movl	16(%esp), %esi
	movl	20(%esp), %edx
	testl	%edi, %edi
	jne	L7
	jmp	L2
	.p2align 4,,7
L3:
	incl	%esi
	testb	%cl, %cl
	je	L6
	decl	%edi
	je	L6
L7:
	xorl	%eax, %eax
	xorl	%ebx, %ebx
	movb	(%esi), %cl
	movb	(%edx), %bl
	movb	%cl, %al
	incl	%edx
	movb	___dj_ctype_tolower+1(%ebx), %bl
	movb	___dj_ctype_tolower+1(%eax), %al
	cmpb	%bl, %al
	je	L3
	andl	$255, %eax
	andl	$255, %ebx
	subl	%ebx, %eax
L2:
	popl	%ebx
	.cfi_remember_state
	.cfi_restore 3
	.cfi_def_cfa_offset 12
	popl	%esi
	.cfi_restore 6
	.cfi_def_cfa_offset 8
	popl	%edi
	.cfi_restore 7
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L6:
	.cfi_restore_state
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 12
	xorl	%eax, %eax
	popl	%esi
	.cfi_restore 6
	.cfi_def_cfa_offset 8
	popl	%edi
	.cfi_restore 7
	.cfi_def_cfa_offset 4
	ret
	.cfi_endproc
LFE0:
	.ident	"GCC: (GNU) 4.7.4"
