	.file	"w_pow.c"
	.section .text
	.p2align 4,,15
	.globl	_pow
_pow:
LFB0:
	.cfi_startproc
	subl	$76, %esp
	.cfi_def_cfa_offset 80
	fldl	80(%esp)
	fldl	88(%esp)
	fstl	8(%esp)
	fxch	%st(1)
	fstl	(%esp)
	fxch	%st(1)
	fstpl	32(%esp)
	fstpl	48(%esp)
	call	___ieee754_pow
	fldl	32(%esp)
	cmpl	$-1, ___fdlib_version
	fldl	48(%esp)
	je	L18
	fxch	%st(1)
	fucom	%st(0)
	fnstsw	%ax
	testb	$4, %ah
	jne	L19
	fxch	%st(1)
	fucom	%st(0)
	fnstsw	%ax
	fldz
	testb	$4, %ah
	jne	L14
	fxch	%st(1)
	fucom	%st(1)
	fnstsw	%ax
	andb	$69, %ah
	xorb	$64, %ah
	jne	L4
	fxch	%st(2)
	fucom	%st(1)
	fnstsw	%ax
	andb	$69, %ah
	xorb	$64, %ah
	je	L15
	fld	%st(0)
	fabs
	fldl	LC1
	fucompp
	fnstsw	%ax
	testb	$1, %ah
	jne	L20
	fxch	%st(1)
	fucomp	%st(1)
	fnstsw	%ax
	testb	$69, %ah
	je	L16
	fstp	%st(0)
	fstp	%st(0)
	jmp	L2
	.p2align 4,,7
L18:
	fstp	%st(0)
	fstp	%st(0)
	jmp	L2
	.p2align 4,,7
L19:
	fstp	%st(0)
	fstp	%st(0)
	jmp	L2
	.p2align 4,,7
L20:
	fstp	%st(0)
	fstp	%st(0)
	fstp	%st(0)
	jmp	L2
	.p2align 4,,7
L23:
	fstp	%st(0)
	fstp	%st(0)
	jmp	L2
	.p2align 4,,7
L24:
	fstp	%st(0)
	fstp	%st(0)
	fstp	%st(0)
	jmp	L2
	.p2align 4,,7
L25:
	fstp	%st(0)
	fstp	%st(0)
	jmp	L2
	.p2align 4,,7
L26:
	fstp	%st(0)
	fstp	%st(0)
	.p2align 4,,7
L2:
	addl	$76, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L4:
	.cfi_restore_state
	fstp	%st(1)
	fld	%st(2)
	fabs
	fldl	LC1
	fucom	%st(1)
	fnstsw	%ax
	fstp	%st(1)
	testb	$1, %ah
	je	L21
	fld	%st(1)
	fabs
	fxch	%st(1)
	fucom	%st(1)
	fnstsw	%ax
	fstp	%st(1)
	testb	$1, %ah
	jne	L22
	fld	%st(2)
	fabs
	fxch	%st(1)
	fucompp
	fnstsw	%ax
	testb	$1, %ah
	jne	L7
	fxch	%st(2)
	fucomp	%st(0)
	fnstsw	%ax
	testb	$4, %ah
	jne	L17
	fstpl	8(%esp)
	movl	$21, 16(%esp)
	fstpl	(%esp)
	call	___kernel_standard
	jmp	L2
	.p2align 4,,7
L21:
	fstp	%st(0)
	jmp	L7
	.p2align 4,,7
L22:
	fstp	%st(0)
L7:
	fldz
	fxch	%st(3)
	fucom	%st(3)
	fnstsw	%ax
	fstp	%st(3)
	andb	$69, %ah
	xorb	$64, %ah
	jne	L23
	fld	%st(0)
	fabs
	fldl	LC1
	fucom	%st(1)
	fnstsw	%ax
	fstp	%st(1)
	testb	$1, %ah
	jne	L24
	fld	%st(2)
	fabs
	fxch	%st(1)
	fucompp
	fnstsw	%ax
	testb	$1, %ah
	jne	L25
	fstp	%st(2)
	fstpl	8(%esp)
	movl	$22, 16(%esp)
	fstpl	(%esp)
	call	___kernel_standard
	jmp	L2
	.p2align 4,,7
L14:
	fxch	%st(2)
	fucom	%st(2)
	fnstsw	%ax
	fstp	%st(2)
	andb	$69, %ah
	xorb	$64, %ah
	jne	L26
	fstp	%st(2)
	fstpl	8(%esp)
	movl	$42, 16(%esp)
	fstpl	(%esp)
	call	___kernel_standard
	jmp	L2
	.p2align 4,,7
L15:
	fstp	%st(3)
	fstp	%st(0)
	fxch	%st(1)
	fstpl	8(%esp)
	movl	$20, 16(%esp)
	fstpl	(%esp)
	call	___kernel_standard
	jmp	L2
	.p2align 4,,7
L16:
	fstp	%st(2)
	fxch	%st(1)
	fstpl	8(%esp)
	movl	$23, 16(%esp)
	fstpl	(%esp)
	call	___kernel_standard
	jmp	L2
L17:
	fstpl	8(%esp)
	movl	$24, 16(%esp)
	fstpl	(%esp)
	call	___kernel_standard
	jmp	L2
	.cfi_endproc
LFE0:
	.p2align 3
LC1:
	.long	-1
	.long	2146435071
	.ident	"GCC: (GNU) 4.7.4"
