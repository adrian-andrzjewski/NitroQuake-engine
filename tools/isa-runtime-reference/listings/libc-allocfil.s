	.file	"allocfil.c"
	.section .text
	.p2align 4,,15
	.globl	___alloc_file
___alloc_file:
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
	testl	%esi, %esi
	je	L21
L17:
	movl	4(%esi), %edi
	testl	%edi, %edi
	jle	L3
	movl	8(%esi), %ebx
	movl	16(%ebx), %eax
	testl	%eax, %eax
	je	L14
	xorl	%edx, %edx
	jmp	L5
	.p2align 4,,7
L6:
	movl	8(%esi,%edx,4), %ebx
	movl	16(%ebx), %ecx
	testl	%ecx, %ecx
	je	L14
L5:
	incl	%edx
	cmpl	%edi, %edx
	jne	L6
	cmpl	$20, %edx
	jne	L3
	movl	(%esi), %eax
	testl	%eax, %eax
	je	L22
	movl	%eax, %esi
	jmp	L17
L21:
	movl	$___file_rec_list, %ebx
L2:
	movl	$88, (%esp)
	call	_malloc
	movl	%eax, %esi
	movl	%eax, (%ebx)
	testl	%eax, %eax
	je	L9
	movl	$0, (%esi)
	movl	$0, 4(%esi)
	xorl	%edi, %edi
L3:
	movl	$32, (%esp)
	call	_malloc
	movl	%eax, %ebx
	movl	%eax, 8(%esi,%edi,4)
	testl	%eax, %eax
	je	L9
	xorl	%eax, %eax
	movl	$8, %ecx
	movl	%ebx, %edi
	rep stosl
	movl	4(%esi), %eax
	incl	%eax
	movl	%eax, 4(%esi)
	.p2align 4,,7
L14:
	addl	$16, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 16
	movl	%ebx, %eax
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
L22:
	.cfi_restore_state
	movl	%esi, %ebx
	jmp	L2
L9:
	xorl	%ebx, %ebx
	jmp	L14
	.cfi_endproc
LFE8:
	.ident	"GCC: (GNU) 4.7.4"
