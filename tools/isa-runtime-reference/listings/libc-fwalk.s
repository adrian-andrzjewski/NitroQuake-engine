	.file	"fwalk.c"
	.section .text
	.p2align 4,,15
	.globl	__fwalk
__fwalk:
LFB8:
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
	subl	$16, %esp
	.cfi_def_cfa_offset 32
	movl	___file_rec_list, %esi
	movl	32(%esp), %edi
	testl	%esi, %esi
	je	L1
	.p2align 4,,7
L9:
	movl	4(%esi), %eax
	xorl	%ebx, %ebx
	testl	%eax, %eax
	jg	L10
	jmp	L7
	.p2align 4,,7
L4:
	incl	%ebx
	cmpl	%ebx, 4(%esi)
	jle	L7
L10:
	movl	8(%esi,%ebx,4), %eax
	movl	16(%eax), %edx
	testl	%edx, %edx
	je	L4
	movl	%eax, (%esp)
	incl	%ebx
	call	*%edi
	cmpl	%ebx, 4(%esi)
	jg	L10
L7:
	movl	(%esi), %esi
	testl	%esi, %esi
	jne	L9
L1:
	addl	$16, %esp
	.cfi_def_cfa_offset 16
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 12
	popl	%esi
	.cfi_restore 6
	.cfi_def_cfa_offset 8
	popl	%edi
	.cfi_restore 7
	.cfi_def_cfa_offset 4
	ret
	.cfi_endproc
LFE8:
	.ident	"GCC: (GNU) 4.7.4"
