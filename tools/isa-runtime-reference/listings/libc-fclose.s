	.file	"fclose.c"
	.section .text
	.p2align 4,,15
	.globl	_fclose
_fclose:
LFB13:
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
	movl	32(%esp), %ebx
	movl	16(%ebx), %edx
	movl	20(%ebx), %edi
	testl	$536, %edx
	je	L2
	testb	$1, %dh
	je	L3
L2:
	testl	%edi, %edi
	js	L9
	movl	___fd_properties, %eax
	testl	%eax, %eax
	je	L9
	movl	(%eax,%edi,4), %eax
	testl	%eax, %eax
	je	L9
	testb	$32, 8(%eax)
	je	L9
L3:
	movl	%ebx, (%esp)
	call	_fflush
	movl	%edi, (%esp)
	movl	%eax, %esi
	call	___close
	testl	%eax, %eax
	js	L29
	movl	16(%ebx), %edx
	testb	$32, %dl
	jne	L30
L4:
	andb	$8, %dh
	je	L7
L31:
	movl	24(%ebx), %eax
	testl	%eax, %eax
	je	L7
	movl	%eax, (%esp)
	call	_remove
	movl	24(%ebx), %eax
	movl	%eax, (%esp)
	call	_free
	movl	$0, 24(%ebx)
L7:
	movl	$0, (%ebx)
	movl	$0, 8(%ebx)
	movl	$0, 4(%ebx)
	movl	$0, 12(%ebx)
	movl	$0, 16(%ebx)
	movl	$-1, 20(%ebx)
	addl	$16, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 16
	movl	%esi, %eax
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
	.p2align 4,,7
L9:
	.cfi_restore_state
	orl	$-1, %esi
	andb	$8, %dh
	je	L7
	jmp	L31
	.p2align 4,,7
L30:
	movl	8(%ebx), %eax
	movl	%eax, (%esp)
	call	_free
	movl	16(%ebx), %edx
	andb	$8, %dh
	je	L7
	jmp	L31
	.p2align 4,,7
L29:
	movl	16(%ebx), %edx
	orl	$-1, %esi
	testb	$32, %dl
	je	L4
	jmp	L30
	.cfi_endproc
LFE13:
	.ident	"GCC: (GNU) 4.7.4"
