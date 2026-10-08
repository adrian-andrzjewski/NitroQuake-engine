	.file	"e_pow.c"
	.section .text
	.p2align 4,,15
	.globl	___ieee754_pow
___ieee754_pow:
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
	subl	$124, %esp
	.cfi_def_cfa_offset 144
	fldl	144(%esp)
	fstpl	56(%esp)
	fldl	152(%esp)
	movl	60(%esp), %edx
	movl	56(%esp), %eax
	fstl	24(%esp)
	movl	%edx, %esi
	movl	28(%esp), %edx
	movl	%edx, %ebx
	movl	%eax, %ebp
	movl	24(%esp), %eax
	movl	%eax, %edx
	movl	%ebx, %eax
	andl	$2147483647, %eax
	movl	%eax, %ecx
	orl	%edx, %ecx
	je	L44
	movl	%esi, %edi
	andl	$2147483647, %edi
	movl	%edi, 20(%esp)
	cmpl	$2146435072, %edi
	jg	L3
	sete	64(%esp)
	je	L81
L59:
	cmpl	$2146435072, %eax
	jg	L3
	sete	72(%esp)
	je	L82
L5:
	movl	$0, 84(%esp)
	testl	%esi, %esi
	js	L83
L6:
	testl	%edx, %edx
	jne	L8
L43:
	cmpb	$0, 72(%esp)
	jne	L84
	cmpl	$1072693248, %eax
	je	L85
	cmpl	$1073741824, %ebx
	je	L86
	cmpl	$1071644672, %ebx
	jne	L8
	testl	%esi, %esi
	js	L8
	fstp	%st(0)
	fldl	56(%esp)
	fstpl	(%esp)
	call	___ieee754_sqrt
	jmp	L65
	.p2align 4,,7
L82:
	testl	%edx, %edx
	je	L5
	.p2align 4,,7
L3:
	faddl	56(%esp)
L65:
	addl	$124, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 20
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 16
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
L44:
	.cfi_restore_state
	fstp	%st(0)
	addl	$124, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 20
	fld1
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 16
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
L8:
	.cfi_restore_state
	fldl	56(%esp)
	fabs
	testl	%ebp, %ebp
	jne	L15
	movl	20(%esp), %edx
	testl	%edx, %edx
	je	L93
	cmpb	$0, 64(%esp)
	jne	L94
	cmpl	$1072693248, 20(%esp)
	jne	L15
	fstp	%st(1)
	jmp	L16
L93:
	fstp	%st(1)
	jmp	L16
L94:
	fstp	%st(1)
L16:
	fstpl	104(%esp)
	testl	%ebx, %ebx
	js	L87
L17:
	testl	%esi, %esi
	js	L88
L18:
	fldl	104(%esp)
	jmp	L65
	.p2align 4,,7
L81:
	testl	%ebp, %ebp
	je	L59
	jmp	L3
	.p2align 4,,7
L15:
	shrl	$31, %esi
	movl	84(%esp), %edx
	leal	-1(%esi), %ecx
	orl	%ecx, %edx
	je	L89
	cmpl	$1105199104, %eax
	jle	L21
	cmpl	$1139802112, %eax
	jle	L22
	fstp	%st(0)
	fstp	%st(0)
	cmpl	$1072693247, 20(%esp)
	jle	L78
	jmp	L77
L102:
	fstp	%st(0)
	fstp	%st(0)
L77:
	testl	%ebx, %ebx
	jle	L53
L24:
	fldl	LC3
	fmul	%st(0), %st
	jmp	L65
	.p2align 4,,7
L83:
	cmpl	$1128267775, %eax
	jg	L46
	cmpl	$1072693247, %eax
	jle	L6
	movl	%eax, %edi
	sarl	$20, %edi
	cmpl	$1043, %edi
	jle	L7
	movl	$1075, 80(%esp)
	movl	80(%esp), %ecx
	subl	%edi, %ecx
	movl	%edx, %edi
	movl	%ecx, 80(%esp)
	movb	80(%esp), %cl
	shrl	%cl, %edi
	movl	%edi, 88(%esp)
	sall	%cl, %edi
	cmpl	%edx, %edi
	jne	L6
	movl	88(%esp), %ecx
	movl	$2, 84(%esp)
	andl	$1, %ecx
	subl	%ecx, 84(%esp)
	jmp	L6
	.p2align 4,,7
L89:
	fstp	%st(0)
	fstp	%st(0)
	fldl	56(%esp)
	fsub	%st(0), %st
	fdiv	%st(0), %st
	jmp	L65
L21:
	xorl	%eax, %eax
	cmpl	$1048575, 20(%esp)
	jg	L28
	fmuls	LC10
	movl	$-53, %eax
	fstl	24(%esp)
	movl	28(%esp), %edx
	movl	%edx, 20(%esp)
L28:
	movl	20(%esp), %edx
	movl	20(%esp), %edi
	sarl	$20, %edx
	andl	$1048575, %edi
	movl	%edi, %ebp
	orl	$1072693248, %ebp
	leal	-1023(%eax,%edx), %esi
	cmpl	$235662, %edi
	jle	L55
	cmpl	$767609, %edi
	jle	L56
	incl	%esi
	subl	$1048576, %ebp
	xorl	%edi, %edi
	xorl	%ebx, %ebx
L29:
	fstpl	24(%esp)
	movl	24(%esp), %eax
	movl	%ebp, 68(%esp)
	sarl	%ebp
	movl	%eax, 64(%esp)
	fldl	64(%esp)
	fsubl	_bp(,%ebx,8)
	orl	$536870912, %ebp
	xorl	%eax, %eax
	leal	524288(%edi,%ebp), %ebp
	movl	%eax, 56(%esp)
	fldl	64(%esp)
	faddl	_bp(,%ebx,8)
	fdivrs	LC0
	fld	%st(1)
	fmul	%st(1), %st
	fstl	24(%esp)
	fldz
	movl	28(%esp), %edx
	fstpl	72(%esp)
	movl	%ebp, 76(%esp)
	movl	%edx, 60(%esp)
	fldl	72(%esp)
	fldl	56(%esp)
	fmul	%st(1), %st
	fsubrp	%st, %st(4)
	fsubl	_bp(,%ebx,8)
	fsubrl	64(%esp)
	fmull	56(%esp)
	fsubrp	%st, %st(3)
	fxch	%st(2)
	fmulp	%st, %st(1)
	fld	%st(1)
	fmul	%st(2), %st
	fld	%st(0)
	fmul	%st(1), %st
	fldl	LC11
	fmul	%st(2), %st
	faddl	LC12
	fmul	%st(2), %st
	faddl	LC13
	fmul	%st(2), %st
	faddl	LC14
	fmul	%st(2), %st
	faddl	LC15
	fmulp	%st, %st(2)
	fxch	%st(1)
	faddl	LC16
	fmulp	%st, %st(1)
	fldl	56(%esp)
	fadd	%st(3), %st
	fmul	%st(2), %st
	faddp	%st, %st(1)
	fldl	56(%esp)
	fmul	%st(0), %st
	flds	LC17
	fld	%st(1)
	fadd	%st(1), %st
	fadd	%st(3), %st
	fstpl	64(%esp)
	movl	$0, 64(%esp)
	fldl	64(%esp)
	fldl	56(%esp)
	fmul	%st(1), %st
	fxch	%st(5)
	fmul	%st(1), %st
	fxch	%st(1)
	fsubp	%st, %st(2)
	fxch	%st(1)
	fsubp	%st, %st(2)
	fxch	%st(2)
	fsubp	%st, %st(1)
	fmulp	%st, %st(3)
	faddp	%st, %st(2)
	fld	%st(0)
	fadd	%st(2), %st
	fstpl	56(%esp)
	movl	$0, 56(%esp)
	movl	%esi, 92(%esp)
	fldl	56(%esp)
	fld	%st(0)
	fmuls	LC18
	fldl	LC19
	fmul	%st(2), %st
	fxch	%st(2)
	fsubp	%st, %st(3)
	fxch	%st(3)
	fsubp	%st, %st(2)
	fxch	%st(1)
	fmull	LC20
	faddp	%st, %st(1)
	faddl	_dp_l(,%ebx,8)
	fildl	92(%esp)
	fldl	_dp_h(,%ebx,8)
	fld	%st(3)
	fadd	%st(3), %st
	fadd	%st(1), %st
	fadd	%st(2), %st
	fstpl	56(%esp)
	movl	$0, 56(%esp)
	fldl	56(%esp)
	fsub	%st, %st(2)
	fxch	%st(2)
	fsubp	%st, %st(1)
	fsubp	%st, %st(3)
	fxch	%st(2)
	fsubrp	%st, %st(1)
L27:
	movl	84(%esp), %eax
	decl	%eax
	fld1
	orl	%ecx, %eax
	jne	L95
	fchs
	fxch	%st(3)
	jmp	L30
L95:
	fxch	%st(3)
L30:
	fstl	24(%esp)
	xorl	%eax, %eax
	movl	28(%esp), %edx
	movl	%eax, 56(%esp)
	movl	%edx, 60(%esp)
	fldl	56(%esp)
	fsubr	%st(1), %st
	fmul	%st(3), %st
	fxch	%st(1)
	fmulp	%st, %st(2)
	faddp	%st, %st(1)
	fxch	%st(1)
	fmull	56(%esp)
	fld	%st(1)
	fadd	%st(1), %st
	fstl	104(%esp)
	fldl	104(%esp)
	fstpl	56(%esp)
	movl	60(%esp), %edx
	movl	56(%esp), %eax
	cmpl	$1083179007, %edx
	jle	L31
	leal	-1083179008(%edx), %ecx
	orl	%eax, %ecx
	jne	L96
	fldl	104(%esp)
	fldl	LC21
	fadd	%st(4), %st
	fxch	%st(1)
	fsub	%st(3), %st
	fxch	%st(1)
	fucompp
	fnstsw	%ax
	testb	$69, %ah
	je	L97
	movl	%edx, %ecx
	andl	$2147483647, %ecx
L35:
	cmpl	$1071644672, %ecx
	jg	L98
	xorl	%ecx, %ecx
	xorl	%ebx, %ebx
L39:
	fstpl	24(%esp)
	xorl	%eax, %eax
	movl	28(%esp), %edx
	movl	%edx, 60(%esp)
	movl	%eax, 56(%esp)
	fldl	56(%esp)
	fmuls	LC23
	fxch	%st(1)
	fsubrl	56(%esp)
	fsubrp	%st, %st(2)
	fxch	%st(1)
	fmull	LC24
	fldl	56(%esp)
	fmull	LC25
	faddp	%st, %st(1)
	fld	%st(1)
	fadd	%st(1), %st
	fstpl	104(%esp)
	fldl	104(%esp)
	fsubp	%st, %st(2)
	fsubp	%st, %st(1)
	fldl	104(%esp)
	fldl	104(%esp)
	fmulp	%st, %st(1)
	fldl	104(%esp)
	fldl	LC26
	fmul	%st(2), %st
	fsubl	LC27
	fmul	%st(2), %st
	faddl	LC28
	fmul	%st(2), %st
	fsubl	LC29
	fmul	%st(2), %st
	faddl	LC30
	fmulp	%st, %st(2)
	fsubp	%st, %st(1)
	fldl	104(%esp)
	fldl	104(%esp)
	fldl	104(%esp)
	fxch	%st(2)
	fmul	%st(3), %st
	fxch	%st(3)
	fsubs	LC31
	fdivrp	%st, %st(3)
	fmul	%st(3), %st
	faddp	%st, %st(3)
	fxch	%st(1)
	fsubp	%st, %st(2)
	fsubrp	%st, %st(1)
	fsubrs	LC0
	fstpl	104(%esp)
	fldl	104(%esp)
	fstpl	56(%esp)
	movl	60(%esp), %edx
	addl	%edx, %ecx
	cmpl	$1048575, %ecx
	jle	L90
	fldl	104(%esp)
	fstpl	56(%esp)
	movl	56(%esp), %eax
	movl	%ecx, 60(%esp)
	movl	%eax, 56(%esp)
	fldl	56(%esp)
	fstpl	104(%esp)
L42:
	fldl	104(%esp)
	fmulp	%st, %st(1)
	jmp	L65
L84:
	movl	20(%esp), %eax
	subl	$1072693248, %eax
	orl	%ebp, %eax
	je	L91
	cmpl	$1072693247, 20(%esp)
	jle	L12
	testl	%ebx, %ebx
	jns	L65
	fstp	%st(0)
	jmp	L53
L103:
	fstp	%st(0)
L53:
	fldz
	jmp	L65
L46:
	movl	$2, 84(%esp)
	jmp	L6
L85:
	fstp	%st(0)
	fldl	56(%esp)
	testl	%ebx, %ebx
	jns	L65
	fdivrs	LC0
	jmp	L65
L31:
	movl	%edx, %ecx
	andl	$2147483647, %ecx
	cmpl	$1083231231, %ecx
	jle	L35
	fstp	%st(0)
	leal	1064252416(%edx), %ebx
	orl	%eax, %ebx
	jne	L99
	fldl	104(%esp)
	fsub	%st(1), %st
	fucomp	%st(2)
	fnstsw	%ax
	testb	$5, %ah
	jne	L37
	jmp	L100
L98:
	fstp	%st(0)
L37:
	sarl	$20, %ecx
	movl	$1048576, %ebx
	subl	$1022, %ecx
	movl	$1048575, %eax
	sarl	%cl, %ebx
	addl	%edx, %ebx
	movl	%ebx, %esi
	andl	$2147483647, %esi
	sarl	$20, %esi
	fldz
	leal	-1023(%esi), %ecx
	sarl	%cl, %eax
	xorl	$-1, %eax
	movl	$1043, %ecx
	andl	%ebx, %eax
	andl	$1048575, %ebx
	fstpl	56(%esp)
	orl	$1048576, %ebx
	subl	%esi, %ecx
	movl	%eax, 60(%esp)
	sarl	%cl, %ebx
	fldl	56(%esp)
	testl	%edx, %edx
	js	L92
L40:
	fsubrp	%st, %st(1)
	movl	%ebx, %ecx
	sall	$20, %ecx
	fld	%st(1)
	fadd	%st(1), %st
	jmp	L39
L88:
	movl	20(%esp), %edi
	subl	$1072693248, %edi
	orl	84(%esp), %edi
	jne	L19
	fldl	104(%esp)
	fldl	104(%esp)
	fldl	104(%esp)
	fldl	104(%esp)
	fxch	%st(3)
	fsubp	%st, %st(2)
	fsubp	%st, %st(2)
	fdivp	%st, %st(1)
	fstpl	104(%esp)
	jmp	L18
L101:
	fstp	%st(0)
	fstp	%st(0)
L78:
	testl	%ebx, %ebx
	js	L24
	fldz
	jmp	L65
L22:
	cmpl	$1072693246, 20(%esp)
	jle	L101
	cmpl	$1072693248, 20(%esp)
	jg	L102
	fsubs	LC0
	fld	%st(0)
	fmuls	LC4
	fldl	LC5
	fmul	%st(2), %st
	fld	%st(2)
	fmul	%st(3), %st
	fld	%st(3)
	fmuls	LC6
	fsubrl	LC7
	fmulp	%st, %st(4)
	fxch	%st(3)
	fsubrs	LC8
	fmulp	%st, %st(3)
	fxch	%st(2)
	fmull	LC9
	fsubrp	%st, %st(2)
	fld	%st(0)
	fadd	%st(2), %st
	fstpl	56(%esp)
	movl	$0, 56(%esp)
	fldl	56(%esp)
	fsub	%st, %st(1)
	fxch	%st(2)
	fsubp	%st, %st(1)
	jmp	L27
L55:
	xorl	%edi, %edi
	xorl	%ebx, %ebx
	jmp	L29
L87:
	fldl	104(%esp)
	fdivrs	LC0
	fstpl	104(%esp)
	jmp	L17
L91:
	fsub	%st(0), %st
	jmp	L65
L86:
	fstp	%st(0)
	fldl	56(%esp)
	fmul	%st(0), %st
	jmp	L65
L96:
	fstp	%st(0)
	fstp	%st(0)
	fstp	%st(0)
	jmp	L75
L97:
	fstp	%st(0)
	fstp	%st(0)
	fstp	%st(0)
L75:
	fldl	LC3
	fmulp	%st, %st(1)
	fmull	LC3
	jmp	L65
L12:
	testl	%ebx, %ebx
	jns	L103
	fchs
	jmp	L65
L19:
	cmpl	$1, 84(%esp)
	jne	L18
	fldl	104(%esp)
	fchs
	fstpl	104(%esp)
	jmp	L18
L56:
	movl	$262144, %edi
	movl	$1, %ebx
	jmp	L29
L7:
	testl	%edx, %edx
	jne	L8
	movl	$1043, 80(%esp)
	movl	%eax, %edx
	movl	80(%esp), %ecx
	subl	%edi, %ecx
	movl	%ecx, 80(%esp)
	movb	80(%esp), %cl
	sarl	%cl, %edx
	movl	%edx, %edi
	sall	%cl, %edi
	cmpl	%eax, %edi
	jne	L43
	andl	$1, %edx
	movl	$2, 84(%esp)
	subl	%edx, 84(%esp)
	jmp	L43
L99:
	fstp	%st(0)
	fstp	%st(0)
	jmp	L74
L100:
	fstp	%st(0)
	fstp	%st(0)
L74:
	fldl	LC22
	fmulp	%st, %st(1)
	fmull	LC22
	jmp	L65
L90:
	fldl	104(%esp)
	movl	%ebx, 8(%esp)
	fstpl	(%esp)
	fstpl	32(%esp)
	call	_scalbn
	fstpl	104(%esp)
	fldl	32(%esp)
	jmp	L42
L92:
	negl	%ebx
	jmp	L40
	.cfi_endproc
LFE0:
	.p2align 4
_bp:
	.long	0
	.long	1072693248
	.long	0
	.long	1073217536
	.p2align 4
_dp_l:
	.long	0
	.long	0
	.long	1137692678
	.long	1045233131
	.p2align 4
_dp_h:
	.long	0
	.long	0
	.long	1073741824
	.long	1071822851
	.p2align 2
LC0:
	.long	1065353216
	.p2align 3
LC3:
	.long	-2013235812
	.long	2117592124
	.p2align 2
LC4:
	.long	1069066811
	.p2align 3
LC5:
	.long	-128065724
	.long	1045736971
	.p2align 2
LC6:
	.long	1048576000
	.p2align 3
LC7:
	.long	1431655765
	.long	1070945621
	.p2align 2
LC8:
	.long	1056964608
	.p2align 3
LC9:
	.long	1697350398
	.long	1073157447
	.p2align 2
LC10:
	.long	1509949440
	.p2align 3
LC11:
	.long	1246056175
	.long	1070235176
	.p2align 3
LC12:
	.long	-1815487643
	.long	1070433866
	.p2align 3
LC13:
	.long	-1457700607
	.long	1070691424
	.p2align 3
LC14:
	.long	1368335949
	.long	1070945621
	.p2align 3
LC15:
	.long	-613438465
	.long	1071345078
	.p2align 3
LC16:
	.long	858993411
	.long	1071854387
	.p2align 2
LC17:
	.long	1077936128
	.p2align 2
LC18:
	.long	1064712271
	.p2align 3
LC19:
	.long	341508597
	.long	-1103220768
	.p2align 3
LC20:
	.long	-600177667
	.long	1072613129
	.p2align 3
LC21:
	.long	1697350398
	.long	1016534343
	.p2align 3
LC22:
	.long	-1023872167
	.long	27618847
	.p2align 2
LC23:
	.long	1060205080
	.p2align 3
LC24:
	.long	-17155601
	.long	1072049730
	.p2align 3
LC25:
	.long	212364345
	.long	-1105175455
	.p2align 3
LC26:
	.long	1925096656
	.long	1046886249
	.p2align 3
LC27:
	.long	-976065551
	.long	1052491073
	.p2align 3
LC28:
	.long	-1356472788
	.long	1058100842
	.p2align 3
LC29:
	.long	381599123
	.long	1063698796
	.p2align 3
LC30:
	.long	1431655742
	.long	1069897045
	.p2align 2
LC31:
	.long	1073741824
	.ident	"GCC: (GNU) 4.7.4"
