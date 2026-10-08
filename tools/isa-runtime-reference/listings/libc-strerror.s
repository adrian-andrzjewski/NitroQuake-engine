	.file	"strerror.c"
	.section .text
	.p2align 4,,15
	.globl	_strerror
_strerror:
LFB0:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	pushl	%edi
	.cfi_def_cfa_offset 12
	.cfi_offset 7, -12
	pushl	%esi
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	pushl	%ebx
	.cfi_def_cfa_offset 20
	.cfi_offset 3, -20
	movl	20(%esp), %eax
	testl	%eax, %eax
	js	L2
	movl	20(%esp), %eax
	cmpl	___sys_nerr, %eax
	jl	L14
	movl	$1852534357, _ebuf.1828
	movl	$544110447, _ebuf.1828+4
	movl	$1869771365, _ebuf.1828+8
	movl	$2112114, _ebuf.1828+12
	movl	$_ebuf.1828+15, %ebp
L8:
	movl	$7, %esi
	xorl	%edi, %edi
	movl	$1000000, %ecx
	movl	$1717986919, %ebx
	jmp	L7
	.p2align 4,,7
L16:
	xorl	%edi, %edi
	cmpl	$1, %ecx
	je	L5
L6:
	movl	20(%esp), %eax
	movl	%eax, %edx
	sarl	$31, %edx
	idivl	%ecx
	movl	%ecx, %eax
	movl	%edx, 20(%esp)
	imull	%ebx
	sarl	$31, %ecx
	sarl	$2, %edx
	subl	%ecx, %edx
	decl	%esi
	movl	%edx, %ecx
	je	L15
L7:
	movl	20(%esp), %eax
	movl	%eax, %edx
	sarl	$31, %edx
	idivl	%ecx
	orl	%eax, %edi
	je	L16
L5:
	addl	$48, %eax
	movl	$1, %edi
	movb	%al, 0(%ebp)
	incl	%ebp
	jmp	L6
	.p2align 4,,7
L15:
	popl	%ebx
	.cfi_remember_state
	.cfi_restore 3
	.cfi_def_cfa_offset 16
	movl	$_ebuf.1828, %eax
	popl	%esi
	.cfi_restore 6
	.cfi_def_cfa_offset 12
	popl	%edi
	.cfi_restore 7
	.cfi_def_cfa_offset 8
	popl	%ebp
	.cfi_restore 5
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L14:
	.cfi_restore_state
	popl	%ebx
	.cfi_remember_state
	.cfi_restore 3
	.cfi_def_cfa_offset 16
	movl	___sys_errlist(,%eax,4), %eax
	popl	%esi
	.cfi_restore 6
	.cfi_def_cfa_offset 12
	popl	%edi
	.cfi_restore 7
	.cfi_def_cfa_offset 8
	popl	%ebp
	.cfi_restore 5
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L2:
	.cfi_restore_state
	movl	$2112114, _ebuf.1828+12
	movl	$1852534357, _ebuf.1828
	movl	$544110447, _ebuf.1828+4
	movl	$1869771365, _ebuf.1828+8
	movb	$45, _ebuf.1828+15
	movl	$_ebuf.1828+16, %ebp
	negl	20(%esp)
	jmp	L8
	.cfi_endproc
LFE0:
.lcomm _ebuf.1828,40,16
	.ident	"GCC: (GNU) 4.7.4"
