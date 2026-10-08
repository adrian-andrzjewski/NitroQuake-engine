	.file	"s_scalbn.c"
	.section .text
	.p2align 4,,15
	.globl	_scalbn
_scalbn:
LFB0:
	.cfi_startproc
	pushl	%ebx
	.cfi_def_cfa_offset 8
	.cfi_offset 3, -8
	subl	$8, %esp
	.cfi_def_cfa_offset 16
	fldl	16(%esp)
	fstl	(%esp)
	movl	4(%esp), %edx
	movl	(%esp), %eax
	movl	%edx, %ecx
	andl	$2146435072, %edx
	sarl	$20, %edx
	jne	L2
	andl	$2147483647, %ecx
	orl	%eax, %ecx
	je	L33
	fmuls	LC0
	cmpl	$-50000, 24(%esp)
	fstl	(%esp)
	movl	4(%esp), %edx
	movl	%edx, %ecx
	jl	L13
	fstp	%st(0)
	andl	$2146435072, %edx
	movl	24(%esp), %ebx
	sarl	$20, %edx
	subl	$54, %edx
	addl	%edx, %ebx
	cmpl	$2046, %ebx
	jle	L7
L31:
	fldl	(%esp)
	fxam
	fnstsw	%ax
	fstp	%st(0)
	fldl	___dj_huge_val
	fabs
	testb	$2, %ah
	jne	L28
L27:
	fstpl	(%esp)
	jmp	L3
	.p2align 4,,7
L33:
	fstp	%st(0)
L3:
	fldl	(%esp)
	addl	$8, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 8
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L2:
	.cfi_restore_state
	fstp	%st(0)
	cmpl	$2047, %edx
	je	L30
	movl	24(%esp), %ebx
	addl	%edx, %ebx
	cmpl	$2046, %ebx
	jg	L31
L7:
	testl	%ebx, %ebx
	jle	L9
	sall	$20, %ebx
	andl	$-2146435073, %ecx
	movl	%ebx, %edx
	movl	(%esp), %eax
	orl	%ecx, %edx
	movl	%eax, (%esp)
	movl	%edx, 4(%esp)
	fldl	(%esp)
	addl	$8, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 8
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L9:
	.cfi_restore_state
	cmpl	$-53, %ebx
	jge	L10
	fldl	(%esp)
	fxam
	fnstsw	%ax
	fstp	%st(0)
	cmpl	$50000, 24(%esp)
	jg	L32
	fldl	LC1
	testb	$2, %ah
	je	L13
	fstp	%st(0)
	fldl	LC2
	.p2align 4,,7
L13:
	fmull	LC1
	fstpl	(%esp)
	fldl	(%esp)
	addl	$8, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 8
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L32:
	.cfi_restore_state
	fldl	___dj_huge_val
	fabs
	testb	$2, %ah
	je	L27
	.p2align 4,,7
L28:
	fchs
	fstpl	(%esp)
	jmp	L3
	.p2align 4,,7
L30:
	fldl	(%esp)
	fadd	%st(0), %st
	fstpl	(%esp)
	fldl	(%esp)
	addl	$8, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 8
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L10:
	.cfi_restore_state
	addl	$54, %ebx
	andl	$-2146435073, %ecx
	sall	$20, %ebx
	movl	(%esp), %eax
	movl	%ebx, %edx
	movl	%eax, (%esp)
	orl	%ecx, %edx
	movl	%edx, 4(%esp)
	fldl	(%esp)
	fmuls	LC3
	jmp	L27
	.cfi_endproc
LFE0:
	.p2align 2
LC0:
	.long	1518338048
	.p2align 3
LC1:
	.long	-1023872167
	.long	27618847
	.p2align 3
LC2:
	.long	-1023872167
	.long	-2119864801
	.p2align 2
LC3:
	.long	612368384
	.ident	"GCC: (GNU) 4.7.4"
