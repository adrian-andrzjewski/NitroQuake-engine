	.file	"doprnt.c"
	.section .text
	.p2align 4,,15
_doprnt_roundl:
LFB12:
	.cfi_startproc
	pushl	%esi
	.cfi_def_cfa_offset 8
	.cfi_offset 6, -8
	pushl	%ebx
	.cfi_def_cfa_offset 12
	.cfi_offset 3, -12
	subl	$52, %esp
	.cfi_def_cfa_offset 64
	movl	%eax, %esi
	fldt	64(%esp)
	fldz
	fxch	%st(1)
	fucom	%st(1)
	fnstsw	%ax
	fstp	%st(1)
	andb	$69, %ah
	movsbl	76(%esp), %ebx
	cmpb	$64, %ah
	je	L2
	flds	LC2
	fxch	%st(1)
	fucom	%st(1)
	fnstsw	%ax
	fstp	%st(1)
	andb	$69, %ah
	xorb	$64, %ah
	jne	L3
	movb	(%ecx), %al
	cmpb	_decimal_point, %al
	je	L35
L4:
	movb	%al, %bl
	andl	$-3, %ebx
	cmpb	$48, %bl
	je	L43
	cmpb	$52, %al
	je	L44
	cmpb	$54, %al
	je	L45
	cmpb	$56, %al
	je	L46
L3:
	fmuls	LC4
	leal	32(%esp), %eax
	movl	%eax, 12(%esp)
	movl	%edx, 24(%esp)
	movl	%ecx, 20(%esp)
	fstpt	(%esp)
	call	___modfl
	fstp	%st(0)
	movl	24(%esp), %edx
	fldt	32(%esp)
	movl	20(%esp), %ecx
	jmp	L7
	.p2align 4,,7
L2:
	fstp	%st(0)
	fldz
	cmpb	$47, %bl
	jg	L36
L8:
	fld	%st(0)
	fstpt	32(%esp)
L7:
	flds	LC5
	fxch	%st(1)
	fucompp
	fnstsw	%ax
	movb	_decimal_point, %bl
	testb	$69, %ah
	je	L29
	jmp	L6
	.p2align 4,,7
L10:
	incl	%eax
	cmpb	$57, %al
	jle	L11
L38:
	movb	$48, (%ecx)
	cmpl	%edx, %ecx
	je	L37
	decl	%ecx
L29:
	movb	(%ecx), %al
	cmpb	%bl, %al
	jne	L10
	movb	-1(%ecx), %al
	decl	%ecx
	incl	%eax
	cmpb	$57, %al
	jg	L38
L11:
	movb	%al, (%ecx)
L14:
	addl	$52, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 12
	movl	%edx, %eax
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 8
	popl	%esi
	.cfi_restore 6
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L43:
	.cfi_restore_state
	fstp	%st(0)
	jmp	L5
L44:
	fstp	%st(0)
	jmp	L5
L45:
	fstp	%st(0)
	jmp	L5
L46:
	fstp	%st(0)
	.p2align 4,,7
L5:
	movl	$0, 32(%esp)
	movl	$-1073741824, 36(%esp)
	movl	$16384, 40(%esp)
L6:
	movl	80(%esp), %eax
	cmpb	$45, (%eax)
	jne	L14
	movb	_decimal_point, %bl
	movb	(%ecx), %al
	cmpb	%al, %bl
	je	L39
	.p2align 4,,7
L17:
	cmpb	$48, %al
	jne	L14
	cmpl	%edx, %ecx
	je	L40
	decl	%ecx
L42:
	movb	(%ecx), %al
	cmpb	%al, %bl
	jne	L17
L39:
	movb	-1(%ecx), %al
	decl	%ecx
	jmp	L17
	.p2align 4,,7
L36:
	fstp	%st(0)
	cmpb	$57, %bl
	jle	L41
	flds	LC1
	jmp	L8
	.p2align 4,,7
L37:
	testl	%esi, %esi
	je	L13
	movb	$49, (%edx)
	movl	(%esi), %eax
	incl	%eax
	movl	%eax, (%esi)
	addl	$52, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 12
	movl	%edx, %eax
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 8
	popl	%esi
	.cfi_restore 6
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L40:
	.cfi_restore_state
	movl	80(%esp), %eax
	decl	%ecx
	movb	$0, (%eax)
	jmp	L42
	.p2align 4,,7
L41:
	subl	$48, %ebx
	movl	%ebx, 28(%esp)
	fildl	28(%esp)
	jmp	L8
	.p2align 4,,7
L35:
	movb	-1(%ecx), %al
	jmp	L4
L13:
	movb	$49, -1(%edx)
	decl	%edx
	jmp	L14
	.cfi_endproc
LFE12:
	.p2align 4,,15
	.globl	__doprnt
__doprnt:
LFB10:
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
	subl	$10236, %esp
	.cfi_def_cfa_offset 10256
	movl	10264(%esp), %ebp
	call	_localeconv
	movl	%eax, 144(%esp)
	movl	4(%eax), %eax
	movb	(%eax), %al
	movb	%al, _decimal_point
	movl	16(%ebp), %eax
	testb	$2, %ah
	je	L48
	andl	$-73, %eax
	orl	$16, %eax
	movl	%eax, 16(%ebp)
L48:
	testb	$16, %al
	je	L538
	movl	10256(%esp), %ebx
	movl	10260(%esp), %esi
	movl	%ebx, 104(%esp)
	leal	5232(%esp), %ebx
	movl	%esi, 116(%esp)
	movl	$0, 132(%esp)
	movl	$0, 124(%esp)
	movl	$0, 120(%esp)
	movl	%ebx, 92(%esp)
	.p2align 4,,7
L950:
	movl	104(%esp), %esi
	movsbl	(%esi), %eax
	testl	%eax, %eax
	jne	L1081
L707:
	movl	120(%esp), %eax
	addl	$10236, %esp
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
L1081:
	.cfi_restore_state
	cmpl	$37, %eax
	jne	L52
	movb	_thousands_sep, %al
	movb	1(%esi), %bl
	movb	%al, 80(%esp)
	movl	_grouping, %edi
	movb	$0, 166(%esp)
	movl	$0, 112(%esp)
	movl	$-1, 108(%esp)
	movl	$0, 100(%esp)
	movl	%esi, %ecx
L951:
	leal	1(%ecx), %esi
	cmpb	$122, %bl
	jbe	L1082
L54:
	movb	80(%esp), %al
	movl	%ebp, 4(%esp)
	movb	%al, _thousands_sep
	movl	%ecx, 104(%esp)
	movsbl	%bl, %eax
	movl	%eax, (%esp)
	movl	%edi, _grouping
	call	_putc
	movl	120(%esp), %edx
	incl	%edx
	movl	%edx, 120(%esp)
	.p2align 4,,7
L441:
	movl	104(%esp), %eax
	addl	$2, %eax
	movl	%eax, 104(%esp)
	jmp	L950
	.p2align 4,,7
L1082:
	xorl	%eax, %eax
	movb	%bl, %al
	jmp	*L85(,%eax,4)
	.p2align 2
	.p2align 2
L85:
	.long	L55
	.long	L54
	.long	L54
	.long	L54
	.long	L54
	.long	L54
	.long	L54
	.long	L54
	.long	L54
	.long	L54
	.long	L54
	.long	L54
	.long	L54
	.long	L54
	.long	L54
	.long	L54
	.long	L54
	.long	L54
	.long	L54
	.long	L54
	.long	L54
	.long	L54
	.long	L54
	.long	L54
	.long	L54
	.long	L54
	.long	L54
	.long	L54
	.long	L54
	.long	L54
	.long	L54
	.long	L54
	.long	L56
	.long	L54
	.long	L54
	.long	L57
	.long	L54
	.long	L54
	.long	L54
	.long	L58
	.long	L54
	.long	L54
	.long	L59
	.long	L60
	.long	L54
	.long	L61
	.long	L62
	.long	L54
	.long	L63
	.long	L539
	.long	L539
	.long	L539
	.long	L539
	.long	L539
	.long	L539
	.long	L539
	.long	L539
	.long	L539
	.long	L54
	.long	L54
	.long	L54
	.long	L54
	.long	L54
	.long	L54
	.long	L54
	.long	L65
	.long	L54
	.long	L54
	.long	L66
	.long	L65
	.long	L65
	.long	L65
	.long	L54
	.long	L54
	.long	L54
	.long	L54
	.long	L75
	.long	L54
	.long	L54
	.long	L68
	.long	L54
	.long	L54
	.long	L54
	.long	L54
	.long	L54
	.long	L69
	.long	L54
	.long	L54
	.long	L70
	.long	L54
	.long	L54
	.long	L54
	.long	L54
	.long	L54
	.long	L54
	.long	L54
	.long	L54
	.long	L71
	.long	L54
	.long	L72
	.long	L73
	.long	L71
	.long	L71
	.long	L71
	.long	L74
	.long	L73
	.long	L75
	.long	L54
	.long	L76
	.long	L54
	.long	L77
	.long	L78
	.long	L79
	.long	L54
	.long	L54
	.long	L80
	.long	L1023
	.long	L82
	.long	L54
	.long	L54
	.long	L83
	.long	L54
	.long	L84
L76:
	testb	$1, 100(%esp)
	je	L84
L75:
	orl	$2, 100(%esp)
L1023:
	movb	2(%ecx), %bl
	movl	%esi, %ecx
	jmp	L951
L84:
	movb	2(%ecx), %bl
	movl	%esi, %ecx
	orl	$1, 100(%esp)
	jmp	L951
L66:
	orl	$1, 100(%esp)
	movb	80(%esp), %al
	movl	%ecx, 104(%esp)
	movb	%al, _thousands_sep
	movl	%edi, _grouping
L90:
	movl	124(%esp), %ebx
	testl	%ebx, %ebx
	je	L264
	movl	132(%esp), %ebx
	movl	%ebx, 116(%esp)
L264:
	testb	$2, 100(%esp)
	je	L265
	movl	116(%esp), %edx
	movl	116(%esp), %ecx
	addl	$8, %ecx
	movl	(%edx), %eax
	movl	4(%edx), %edx
	movl	%eax, 40(%esp)
	movl	%edx, 44(%esp)
	movl	%ecx, 116(%esp)
L266:
	movl	44(%esp), %ecx
	testl	%ecx, %ecx
	js	L1083
L269:
	movl	100(%esp), %ebx
	movl	40(%esp), %esi
	orl	$32, %ebx
	movl	$10, 100(%esp)
	orl	44(%esp), %esi
	movl	%ebx, 80(%esp)
	setne	%cl
L270:
	movl	108(%esp), %eax
	testl	%eax, %eax
	js	L471
	movl	80(%esp), %eax
	andb	$254, %ah
	movl	%eax, 80(%esp)
L471:
	movl	108(%esp), %eax
	testl	%eax, %eax
	jne	L706
	testb	%cl, %cl
	je	L668
L706:
	movl	$_LOWER_DIGITS, %ecx
	testb	$2, 80(%esp)
	je	L474
	testl	$2048, 80(%esp)
	je	L475
	movl	$_UPPER_DIGITS, %ecx
L475:
	movl	100(%esp), %eax
	movl	%ebp, 128(%esp)
	movl	%eax, %edx
	movl	%eax, 72(%esp)
	sarl	$31, %edx
	movl	40(%esp), %edi
	movl	%edx, 76(%esp)
	movl	44(%esp), %esi
	leal	10224(%esp), %ebx
	movl	%ecx, %ebp
	.p2align 4,,7
L476:
	movl	76(%esp), %ecx
	movl	72(%esp), %edx
	movl	%ecx, 12(%esp)
	movl	%edi, (%esp)
	movl	%esi, 4(%esp)
	movl	%edx, 8(%esp)
	call	___umoddi3
	decl	%ebx
	movl	76(%esp), %edx
	movb	0(%ebp,%eax), %al
	movb	%al, (%ebx)
	movl	72(%esp), %eax
	movl	%edi, (%esp)
	movl	%esi, 4(%esp)
	movl	%eax, 8(%esp)
	movl	%edx, 12(%esp)
	call	___udivdi3
	movl	%eax, %edi
	movl	%edx, %esi
	orl	%edi, %edx
	jne	L476
	movl	128(%esp), %ebp
L477:
	testb	$64, 80(%esp)
	je	L1043
	cmpl	$8, 100(%esp)
	je	L481
L1043:
	leal	10224(%esp), %eax
	subl	%ebx, %eax
	movl	%eax, 96(%esp)
	movl	80(%esp), %eax
	andl	$1056, %eax
	cmpl	$1056, %eax
	je	L483
L1058:
	movl	96(%esp), %eax
	movl	108(%esp), %esi
	movl	%eax, 72(%esp)
	cmpl	%esi, %eax
	jge	L487
	movl	%esi, 72(%esp)
L487:
	movl	108(%esp), %esi
L485:
	cmpb	$1, 166(%esp)
	sbbl	$-1, 72(%esp)
	movl	80(%esp), %ecx
	andl	$544, %ecx
	movl	%ecx, 100(%esp)
	cmpl	$544, %ecx
	je	L1084
L506:
	movl	80(%esp), %ecx
	andl	$384, %ecx
	movl	%ecx, 108(%esp)
	jne	L510
	movl	112(%esp), %eax
	testl	%eax, %eax
	je	L510
	movl	112(%esp), %eax
	cmpl	%eax, 72(%esp)
	jge	L510
	movl	%ebx, 128(%esp)
	movl	72(%esp), %edi
	movl	%eax, %ebx
	.p2align 4,,7
L511:
	movl	%ebp, 4(%esp)
	movl	$32, (%esp)
	incl	%edi
	call	_putc
	cmpl	%ebx, %edi
	jne	L511
	movl	128(%esp), %ebx
L510:
	cmpb	$0, 166(%esp)
	jne	L1085
	cmpl	$544, 100(%esp)
	je	L1086
L512:
	cmpl	$256, 108(%esp)
	je	L514
L517:
	movl	96(%esp), %edi
	cmpl	%esi, %edi
	jge	L516
	.p2align 4,,7
L822:
	movl	%ebp, 4(%esp)
	movl	$48, (%esp)
	incl	%edi
	call	_putc
	cmpl	%esi, %edi
	jne	L822
L516:
	movl	96(%esp), %esi
	movl	96(%esp), %edi
	addl	%ebx, %esi
	testl	%edi, %edi
	jle	L520
	.p2align 4,,7
L821:
	movsbl	(%ebx), %eax
	incl	%ebx
	movl	%ebp, 4(%esp)
	movl	%eax, (%esp)
	call	_putc
	cmpl	%esi, %ebx
	jne	L821
L520:
	testb	$-128, 80(%esp)
	je	L523
	movl	112(%esp), %ebx
	cmpl	%ebx, 72(%esp)
	jge	L523
	movl	72(%esp), %ebx
	movl	112(%esp), %esi
	.p2align 4,,7
L526:
	movl	%ebp, 4(%esp)
	movl	$32, (%esp)
	incl	%ebx
	call	_putc
	cmpl	%esi, %ebx
	jne	L526
L523:
	movl	72(%esp), %eax
	cmpl	112(%esp), %eax
	jge	L525
	movl	112(%esp), %eax
L525:
	movl	120(%esp), %ecx
	addl	%eax, %ecx
	movl	%ecx, 120(%esp)
	jmp	L441
L69:
	orl	$1, 100(%esp)
	movb	80(%esp), %bl
	movl	%ecx, 104(%esp)
	movb	%bl, _thousands_sep
	movl	%edi, _grouping
L87:
	movl	124(%esp), %edx
	testl	%edx, %edx
	je	L460
	movl	132(%esp), %esi
	movl	%esi, 116(%esp)
L460:
	testb	$2, 100(%esp)
	je	L461
	movl	116(%esp), %edx
	movl	116(%esp), %ecx
	addl	$8, %ecx
	movl	(%edx), %eax
	movl	4(%edx), %edx
	movl	%eax, 40(%esp)
	movl	%edx, 44(%esp)
	movl	%ecx, 116(%esp)
L462:
	movl	100(%esp), %ebx
	movl	40(%esp), %esi
	orl	$32, %ebx
	movb	$0, 166(%esp)
	orl	44(%esp), %esi
	movl	%ebx, 80(%esp)
	setne	%cl
	movl	$10, 100(%esp)
	jmp	L270
L68:
	orl	$1, 100(%esp)
	movl	%ecx, 104(%esp)
	movb	80(%esp), %cl
	movb	%cl, _thousands_sep
	movl	%edi, _grouping
L89:
	movl	124(%esp), %edi
	testl	%edi, %edi
	je	L445
	movl	132(%esp), %ebx
	movl	%ebx, 116(%esp)
L445:
	testb	$2, 100(%esp)
	je	L446
	movl	116(%esp), %edx
	movl	116(%esp), %ecx
	addl	$8, %ecx
	movl	(%edx), %eax
	movl	4(%edx), %edx
	movl	%eax, 40(%esp)
	movl	%edx, 44(%esp)
	movl	%ecx, 116(%esp)
L447:
	movl	100(%esp), %ebx
	movl	40(%esp), %esi
	orl	$32, %ebx
	movb	$0, 166(%esp)
	orl	44(%esp), %esi
	movl	%ebx, 80(%esp)
	setne	%cl
	movl	$8, 100(%esp)
	jmp	L270
L73:
	movb	80(%esp), %al
	movl	%ecx, 104(%esp)
	movb	%al, _thousands_sep
	movl	%edi, _grouping
	jmp	L90
L74:
	testb	$4, 100(%esp)
	je	L261
	movl	100(%esp), %eax
	movb	2(%ecx), %bl
	andl	$-5, %eax
	movl	%esi, %ecx
	movl	%eax, 100(%esp)
	orl	$8, 100(%esp)
	jmp	L951
L80:
	movb	80(%esp), %al
	movl	124(%esp), %ebx
	movl	%ecx, 104(%esp)
	movb	%al, _thousands_sep
	movl	%edi, _grouping
	testl	%ebx, %ebx
	je	L451
	movl	132(%esp), %ebx
	movl	%ebx, 116(%esp)
L451:
	movl	116(%esp), %ecx
	movl	116(%esp), %esi
	addl	$4, %esi
	movl	(%ecx), %ebx
	movl	%esi, 128(%esp)
	testl	%ebx, %ebx
	je	L1087
L452:
	movl	108(%esp), %ecx
	testl	%ecx, %ecx
	js	L453
	movl	108(%esp), %esi
	movl	$0, 4(%esp)
	movl	%esi, 8(%esp)
	movl	%ebx, (%esp)
	call	_memchr
	testl	%eax, %eax
	je	L1047
	subl	%ebx, %eax
	movl	108(%esp), %esi
	movl	%eax, 96(%esp)
	cmpl	%esi, %eax
	jle	L456
L1047:
	movl	%esi, 72(%esp)
	movl	%esi, 96(%esp)
	movb	$0, 166(%esp)
	jmp	L263
L83:
	movb	80(%esp), %dl
	movl	%ecx, 104(%esp)
	movb	%dl, _thousands_sep
	movl	%edi, _grouping
L86:
	movl	124(%esp), %eax
	testl	%eax, %eax
	je	L465
	movl	132(%esp), %ebx
	movl	%ebx, 116(%esp)
L465:
	testb	$2, 100(%esp)
	je	L466
	movl	116(%esp), %edx
	movl	116(%esp), %ecx
	addl	$8, %ecx
	movl	(%edx), %eax
	movl	4(%edx), %edx
	movl	%eax, 40(%esp)
	movl	%edx, 44(%esp)
	movl	%ecx, 116(%esp)
L467:
	movl	100(%esp), %ebx
	orl	$32, %ebx
	testb	$64, 100(%esp)
	movl	%ebx, 80(%esp)
	jne	L470
	movl	40(%esp), %esi
	movb	$0, 166(%esp)
	orl	44(%esp), %esi
	movl	$16, 100(%esp)
	setne	%cl
	jmp	L270
L82:
	movl	%ecx, 104(%esp)
	movb	80(%esp), %cl
	movb	%cl, _thousands_sep
	movl	%edi, _grouping
	jmp	L87
L79:
	movb	80(%esp), %al
	movl	124(%esp), %esi
	movb	%al, _thousands_sep
	movl	%ecx, 104(%esp)
	movl	%edi, _grouping
	movl	132(%esp), %eax
	testl	%esi, %esi
	je	L1088
L450:
	xorl	%esi, %esi
	movl	(%eax), %ebx
	leal	4(%eax), %ecx
	movl	%ebx, 40(%esp)
	movl	%esi, 44(%esp)
	orl	%esi, %ebx
	movl	100(%esp), %esi
	movl	%ecx, 116(%esp)
	movl	%esi, 80(%esp)
	movb	$0, 166(%esp)
	setne	%cl
	movl	$16, 100(%esp)
	jmp	L270
L78:
	movb	80(%esp), %bl
	movl	%ecx, 104(%esp)
	movb	%bl, _thousands_sep
	movl	%edi, _grouping
	jmp	L89
L77:
	movb	80(%esp), %al
	movl	%ecx, 104(%esp)
	movb	%al, _thousands_sep
	movl	124(%esp), %eax
	movl	%edi, _grouping
	testl	%eax, %eax
	je	L439
	movl	132(%esp), %ebx
	movl	%ebx, 116(%esp)
L439:
	testb	$2, 100(%esp)
	je	L440
	movl	116(%esp), %esi
	movl	120(%esp), %eax
	movl	%eax, %edx
	sarl	$31, %edx
	movl	(%esi), %ecx
	addl	$4, %esi
	movl	%eax, (%ecx)
	movl	%edx, 4(%ecx)
	movl	%esi, 116(%esp)
	jmp	L441
L61:
	movb	2(%ecx), %bl
	movl	%esi, %ecx
L92:
	orl	$128, 100(%esp)
	jmp	L951
L60:
	movb	2(%ecx), %bl
	movb	$43, 166(%esp)
	movl	%esi, %ecx
	jmp	L951
L59:
	leal	2(%ecx), %eax
	movb	2(%ecx), %bl
	movl	%eax, 72(%esp)
	xorl	%eax, %eax
	movb	%bl, %al
	testb	$-128, %al
	jne	L541
	testb	$8, ___dj_ctype_flags+2(%eax,%eax)
	je	L541
	movsbl	%bl, %eax
	xorl	%ecx, %ecx
	movl	%esi, 96(%esp)
	movl	72(%esp), %edx
	movb	%bl, 104(%esp)
	jmp	L96
	.p2align 4,,7
L1089:
	testb	$8, ___dj_ctype_flags+2(%ebx,%ebx)
	je	L962
L96:
	leal	(%ecx,%ecx,4), %ecx
	xorl	%esi, %esi
	addl	%ecx, %ecx
	cmpb	$47, %al
	jle	L95
	movw	$9, %si
	cmpb	$57, %al
	jg	L95
	leal	-48(%eax), %esi
L95:
	incl	%edx
	addl	%esi, %ecx
	movsbl	(%edx), %eax
	movb	%al, %bl
	andl	$255, %ebx
	testb	$-128, %bl
	je	L1089
L962:
	movl	96(%esp), %esi
	movl	%edx, 72(%esp)
	movb	104(%esp), %bl
L94:
	cmpb	$36, %al
	je	L1090
L97:
	movl	116(%esp), %ecx
	movl	116(%esp), %eax
	addl	$4, %eax
	movl	(%ecx), %ecx
	movl	%ecx, 112(%esp)
	testl	%ecx, %ecx
	js	L1091
	movl	%esi, %ecx
	movl	%eax, 116(%esp)
	jmp	L951
L58:
	movl	144(%esp), %ebx
	orl	$1024, 100(%esp)
	movl	36(%ebx), %eax
	movl	8(%ebx), %edi
	movb	2(%ecx), %bl
	movl	%esi, %ecx
	movb	(%eax), %al
	movb	%al, 80(%esp)
	jmp	L951
L57:
	movb	2(%ecx), %bl
	movl	%esi, %ecx
	orl	$64, 100(%esp)
	jmp	L951
L56:
	cmpb	$0, 166(%esp)
	jne	L1023
	movb	2(%ecx), %bl
	movb	$32, 166(%esp)
	movl	%esi, %ecx
	jmp	L951
L55:
	movb	80(%esp), %cl
	movl	%edi, _grouping
	movl	120(%esp), %eax
	movb	%cl, _thousands_sep
	addl	$10236, %esp
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
L65:
	.cfi_restore_state
	orl	$2048, 100(%esp)
	movb	80(%esp), %al
	movl	%ecx, 104(%esp)
	movb	%al, _thousands_sep
	movl	%edi, _grouping
L91:
	movl	124(%esp), %edx
	testl	%edx, %edx
	je	L271
	movl	132(%esp), %esi
	movl	%esi, 116(%esp)
L271:
	movb	%bl, %dl
	andl	$-33, %edx
	movb	%dl, 96(%esp)
	cmpb	$65, %dl
	je	L272
	orl	$16, 100(%esp)
	movl	116(%esp), %esi
	testb	$2, 100(%esp)
	je	L274
L1110:
	movl	116(%esp), %ecx
	addl	$12, %esi
	movl	%esi, 128(%esp)
	fldt	(%ecx)
L275:
	fld	%st(0)
	fstpt	192(%esp)
	movl	200(%esp), %edx
	andl	$32767, %edx
	je	L276
	cmpw	$32767, %dx
	je	L276
	movl	196(%esp), %eax
	testl	%eax, %eax
	js	L277
L278:
	movl	100(%esp), %eax
	andb	$254, %ah
	movl	%eax, 100(%esp)
L279:
	movl	100(%esp), %esi
	andl	$512, %esi
	cmpl	$39, 108(%esp)
	jle	L280
	cmpb	$103, %bl
	je	L1056
	cmpb	$71, %bl
	je	L1092
L1037:
	movl	%esi, 116(%esp)
L282:
	fldz
	fucomp	%st(1)
	fnstsw	%ax
	movb	$0, 187(%esp)
	testb	$69, %ah
	je	L286
	cmpw	$32767, %dx
	je	L1093
L287:
	movl	$0, 148(%esp)
	cmpb	$0, 201(%esp)
	jns	L289
	testw	%dx, %dx
	movl	$1, 148(%esp)
	jne	L289
	movl	196(%esp), %eax
	testl	%eax, %eax
	jne	L289
	movl	192(%esp), %edi
	testl	%edi, %edi
	jne	L289
	movb	$45, 187(%esp)
	.p2align 4,,7
L289:
	movl	100(%esp), %eax
	xorl	%ecx, %ecx
	fld	%st(0)
	fstpt	256(%esp)
	shrl	$11, %eax
	movb	$0, 5232(%esp)
	andl	$1, %eax
	movb	%al, 72(%esp)
	movb	%al, %cl
	movl	264(%esp), %eax
	andl	$32767, %eax
	jne	L1094
	movl	260(%esp), %esi
	testl	%esi, %esi
	js	L1176
L293:
	movb	%bl, 167(%esp)
	movl	$0, 188(%esp)
	cmpb	$65, 96(%esp)
	jne	L1095
	fstpt	240(%esp)
	movl	240(%esp), %eax
	movl	248(%esp), %esi
	andl	$32767, %esi
	movl	%eax, 136(%esp)
	cmpl	$-1, 108(%esp)
	setne	%cl
	xorl	%eax, %eax
	movl	244(%esp), %edx
	movb	%cl, %al
	movl	%edx, 140(%esp)
	movw	%si, 152(%esp)
	movl	%eax, 160(%esp)
	movl	$0, 96(%esp)
	orl	136(%esp), %edx
	jne	L1096
L297:
	cmpl	$1, 160(%esp)
	je	L1097
L301:
	movl	$_LOWER_DIGITS, %edi
	cmpb	$65, %bl
	je	L1098
L305:
	movl	136(%esp), %eax
	movl	140(%esp), %edx
	leal	10224(%esp), %ecx
	movl	%ebp, 80(%esp)
	jmp	L306
	.p2align 4,,7
L627:
	movl	%esi, %ecx
L306:
	movl	%eax, %ebx
	leal	-1(%ecx), %esi
	andl	$15, %ebx
	shrdl	$4, %edx, %eax
	shrl	$4, %edx
	movb	(%edi,%ebx), %bl
	movl	%edx, %ebp
	movb	%bl, -1(%ecx)
	orl	%eax, %ebp
	jne	L627
	movl	%esi, %eax
	movl	%ebx, %esi
	movb	_decimal_point, %dl
	movl	%eax, %ebx
	movl	%esi, %eax
	leal	10224(%esp), %esi
	movb	%dl, 156(%esp)
	movb	%dl, 5233(%esp)
	movl	80(%esp), %ebp
	movl	%ecx, %edi
	movb	%al, 5232(%esp)
	leal	5234(%esp), %edx
	cmpl	%esi, %ecx
	jae	L628
	movl	%edx, %eax
	.p2align 4,,7
L308:
	movb	(%ecx), %bl
	leal	10224(%esp), %esi
	incl	%ecx
	movb	%bl, (%eax)
	incl	%eax
	cmpl	%esi, %ecx
	jne	L308
	movl	%esi, %eax
	subl	%edi, %eax
	leal	(%edx,%eax), %ecx
	leal	-1(%edi,%eax), %ebx
L307:
	movl	160(%esp), %esi
	testl	%esi, %esi
	je	L885
	movl	%ecx, %eax
	subl	%edx, %eax
	cmpl	%eax, 108(%esp)
	jle	L1038
	leal	10224(%esp), %eax
	movl	108(%esp), %esi
	cmpl	%eax, %ecx
	jb	L825
	jmp	L1038
	.p2align 4,,7
L1099:
	leal	10224(%esp), %eax
	cmpl	%eax, %ecx
	je	L630
L825:
	movb	$48, (%ecx)
	incl	%ecx
	movl	%ecx, %eax
	subl	%edx, %eax
	cmpl	%eax, %esi
	jg	L1099
L630:
	movb	$48, %al
L311:
	cmpb	156(%esp), %al
	je	L1100
L315:
	cmpw	$0, 152(%esp)
	je	L1101
L316:
	movl	152(%esp), %esi
	andl	$65535, %esi
	subl	$16383, %esi
L317:
	subl	96(%esp), %esi
	movl	$1, 108(%esp)
	js	L1102
L318:
	movl	$_LOWER_DIGITS, %edi
	cmpb	$0, 72(%esp)
	je	L320
	movl	$_UPPER_DIGITS, %edi
L320:
	movl	%ecx, 80(%esp)
	jmp	L955
	.p2align 4,,7
L1103:
	decl	%ebx
L955:
	movl	%esi, %edx
	movl	%esi, %eax
	sarl	$31, %edx
	movl	$10, %ecx
	idivl	%ecx
	movl	$1717986919, %eax
	movb	(%edi,%edx), %dl
	movb	%dl, (%ebx)
	imull	%esi
	sarl	$31, %esi
	sarl	$2, %edx
	subl	%esi, %edx
	movl	%edx, %esi
	jne	L1103
	cmpl	$1, 108(%esp)
	sbbl	%eax, %eax
	movl	80(%esp), %ecx
	andl	$2, %eax
	addl	$43, %eax
	cmpb	$1, 72(%esp)
	sbbl	%esi, %esi
	movb	%al, -1(%ebx)
	andl	$32, %esi
	leal	-2(%ebx), %eax
	addl	$80, %esi
	movl	%esi, %edx
	movb	%dl, -2(%ebx)
	leal	10224(%esp), %edx
	cmpl	%edx, %eax
	jae	L323
	movl	%ecx, %edx
	movl	%esi, %ecx
	movl	%edx, %esi
	jmp	L325
	.p2align 4,,7
L1104:
	movb	(%eax), %cl
L325:
	movb	%cl, (%edx)
	incl	%eax
	leal	10224(%esp), %ecx
	incl	%edx
	cmpl	%ecx, %eax
	jne	L1104
	leal	10224(%esp), %eax
	subl	%ebx, %eax
	leal	2(%esi,%eax), %ecx
L323:
	movl	92(%esp), %eax
	subl	%eax, %ecx
	movl	%ecx, 96(%esp)
	cmpb	$0, 187(%esp)
	je	L1105
L658:
	movb	$45, 166(%esp)
L435:
	leal	5233(%esp), %ebx
	cmpb	$0, 5232(%esp)
	je	L436
	leal	5232(%esp), %ebx
L436:
	movl	116(%esp), %eax
	testl	%eax, %eax
	jne	L437
	movl	100(%esp), %eax
	andl	$1056, %eax
	cmpl	$1056, %eax
	je	L682
	movl	96(%esp), %edx
	movl	96(%esp), %eax
	xorl	$-1, %edx
	sarl	$31, %edx
	andl	%eax, %edx
	movl	%edx, 72(%esp)
	jmp	L263
	.p2align 4,,7
L276:
	testw	%dx, %dx
	jne	L278
	movl	196(%esp), %eax
	testl	%eax, %eax
	js	L278
L277:
	orl	$32, 100(%esp)
	jmp	L279
L539:
	movl	$0, 72(%esp)
	xorl	%eax, %eax
	jmp	L64
	.p2align 4,,7
L595:
	movl	%ecx, %esi
L64:
	leal	(%eax,%eax,4), %edx
	xorl	%eax, %eax
	addl	%edx, %edx
	cmpb	$47, %bl
	jle	L207
	movb	$9, %al
	cmpb	$57, %bl
	jg	L207
	movsbl	%bl, %eax
	subl	$48, %eax
L207:
	addl	%edx, %eax
	movb	1(%esi), %bl
	xorl	%edx, %edx
	leal	1(%esi), %ecx
	movb	%bl, %dl
	testb	$-128, %dl
	jne	L1034
	testb	$8, ___dj_ctype_flags+2(%edx,%edx)
	jne	L595
L1034:
	movl	%eax, 72(%esp)
	cmpb	$36, %bl
	je	L1106
	movl	72(%esp), %esi
	decl	%ecx
	movl	%esi, 112(%esp)
	jmp	L951
L71:
	movb	80(%esp), %dl
	movl	%ecx, 104(%esp)
	movb	%dl, _thousands_sep
	movl	%edi, _grouping
	jmp	L91
L70:
	movb	80(%esp), %al
	movl	%ecx, 104(%esp)
	movb	%al, _thousands_sep
	movl	%edi, _grouping
	orl	$2048, 100(%esp)
	jmp	L86
L72:
	movl	116(%esp), %esi
	movb	80(%esp), %al
	movl	116(%esp), %ebx
	movb	%al, _thousands_sep
	addl	$4, %ebx
	movl	(%esi), %eax
	movl	%ebx, 128(%esp)
	movl	%ecx, 104(%esp)
	movl	%edi, _grouping
	movb	%al, 5232(%esp)
	movl	$1, 72(%esp)
	movb	$0, 166(%esp)
	movl	$1, 96(%esp)
	leal	5232(%esp), %ebx
L263:
	movl	100(%esp), %esi
	movl	%esi, 80(%esp)
	movl	128(%esp), %esi
	movl	%esi, 116(%esp)
	xorl	%esi, %esi
	jmp	L485
	.p2align 4,,7
L63:
	movb	2(%ecx), %bl
	movl	%esi, %ecx
	orl	$256, 100(%esp)
	jmp	L951
L62:
	movb	2(%ecx), %bl
	leal	2(%ecx), %edx
	cmpb	$42, %bl
	je	L146
	xorl	%ecx, %ecx
	movb	%bl, %cl
	testb	$-128, %cl
	jne	L565
	xorl	%eax, %eax
	testb	$8, ___dj_ctype_flags+2(%ecx,%ecx)
	jne	L834
	jmp	L565
	.p2align 4,,7
L204:
	testb	$8, ___dj_ctype_flags+2(%ecx,%ecx)
	je	L1033
L834:
	leal	(%eax,%eax,4), %ecx
	incl	%edx
	addl	%ecx, %ecx
	xorl	%eax, %eax
	cmpb	$47, %bl
	jle	L203
	movb	$9, %al
	cmpb	$57, %bl
	jg	L203
	movsbl	%bl, %eax
	subl	$48, %eax
L203:
	addl	%ecx, %eax
	movb	(%edx), %bl
	xorl	%ecx, %ecx
	movb	%bl, %cl
	testb	$-128, %cl
	je	L204
L1033:
	movl	%eax, 108(%esp)
	testl	%eax, %eax
	js	L1107
L147:
	leal	-1(%edx), %ecx
	jmp	L951
	.p2align 4,,7
L52:
	movl	%ebp, 4(%esp)
	movl	%eax, (%esp)
	call	_putc
	movl	104(%esp), %ecx
	movl	120(%esp), %ebx
	incl	%ecx
	incl	%ebx
	movl	%ecx, 104(%esp)
	movl	%ebx, 120(%esp)
	jmp	L950
	.p2align 4,,7
L668:
	movl	80(%esp), %eax
	movl	$0, 96(%esp)
	andl	$1056, %eax
	leal	10224(%esp), %ebx
	cmpl	$1056, %eax
	jne	L1058
L483:
	cmpl	$10, 100(%esp)
	jne	L1058
	movl	108(%esp), %esi
L486:
	movb	_thousands_sep, %al
	movb	%al, 100(%esp)
	testb	%al, %al
	je	L1046
	movl	_grouping, %ecx
	cmpb	$127, (%ecx)
	je	L1046
	movb	(%ebx), %dl
	leal	5232(%esp), %eax
	testb	%dl, %dl
	je	L492
	.p2align 4,,7
L493:
	incl	%ebx
	movb	%dl, (%eax)
	incl	%eax
	movb	(%ebx), %dl
	testb	%dl, %dl
	jne	L493
L492:
	leal	10224(%esp), %ebx
	testb	$16, 80(%esp)
	je	L494
	movb	_decimal_point, %dl
	cmpb	%dl, (%eax)
	je	L675
	movl	%ecx, %edi
	.p2align 4,,7
L495:
	decl	%eax
	decl	%ebx
	movb	(%eax), %cl
	movb	%cl, (%ebx)
	cmpb	%dl, (%eax)
	jne	L495
	movl	%edi, %ecx
L494:
	movsbl	(%ecx), %edi
	cmpl	$127, %edi
	je	L496
	cmpl	92(%esp), %eax
	jbe	L1044
	movl	%esi, 72(%esp)
	movl	%ebp, 96(%esp)
	movl	%ebx, %esi
	movl	%ecx, %ebp
	jmp	L824
	.p2align 4,,7
L501:
	decl	%eax
	leal	-1(%ecx), %ebx
	cmpl	92(%esp), %eax
	movb	(%eax), %dl
	movb	%dl, -1(%ecx)
	je	L1108
L824:
	movl	%esi, %edx
	movl	%ebx, %ecx
	subl	%ebx, %edx
	cmpl	%edi, %edx
	jne	L501
	decl	%ecx
	movb	100(%esp), %dl
	movb	%dl, -1(%ebx)
	movl	%ecx, %esi
	testl	%edi, %edi
	je	L501
	movb	1(%ebp), %dl
	leal	1(%ebp), %ebx
	movl	%ebx, %ebp
	cmpb	$127, %dl
	je	L678
	testb	%dl, %dl
	je	L501
	movsbl	%dl, %edi
	jmp	L501
	.p2align 4,,7
L1085:
	movsbl	166(%esp), %eax
	movl	%ebp, 4(%esp)
	movl	%eax, (%esp)
	call	_putc
	cmpl	$544, 100(%esp)
	jne	L512
L1086:
	movl	%ebp, 4(%esp)
	movl	$48, (%esp)
	call	_putc
	movl	104(%esp), %edx
	movsbl	1(%edx), %eax
	cmpb	$65, %al
	je	L680
	cmpb	$97, %al
	je	L681
L513:
	movl	%ebp, 4(%esp)
	movl	%eax, (%esp)
	call	_putc
	cmpl	$256, 108(%esp)
	jne	L517
	.p2align 4,,7
L514:
	movl	112(%esp), %ecx
	cmpl	%ecx, 72(%esp)
	jge	L517
	movl	%ebx, 100(%esp)
	movl	72(%esp), %edi
	movl	%ecx, %ebx
	.p2align 4,,7
L518:
	movl	%ebp, 4(%esp)
	movl	$48, (%esp)
	incl	%edi
	call	_putc
	cmpl	%ebx, %edi
	jne	L518
	movl	100(%esp), %ebx
	jmp	L517
	.p2align 4,,7
L1084:
	movl	72(%esp), %eax
	addl	$2, %eax
	movl	%eax, 72(%esp)
	jmp	L506
	.p2align 4,,7
L474:
	testl	$2048, 80(%esp)
	je	L478
	movl	$_UPPER_DIGITS, %ecx
L478:
	movl	40(%esp), %eax
	leal	10224(%esp), %ebx
	movl	100(%esp), %esi
	.p2align 4,,7
L479:
	xorl	%edx, %edx
	decl	%ebx
	divl	%esi
	testl	%eax, %eax
	movb	(%ecx,%edx), %dl
	movb	%dl, (%ebx)
	jne	L479
	jmp	L477
L470:
	movl	44(%esp), %eax
	orl	40(%esp), %eax
	je	L667
	movl	100(%esp), %ebx
	movb	$1, %cl
	orl	$544, %ebx
	movb	$0, 166(%esp)
	movl	%ebx, 80(%esp)
	movl	$16, 100(%esp)
	jmp	L270
L466:
	testb	$1, 100(%esp)
	je	L468
	movl	116(%esp), %esi
	movl	116(%esp), %ecx
	addl	$4, %ecx
	movl	(%esi), %ebx
	xorl	%esi, %esi
	movl	%ebx, 40(%esp)
	movl	%esi, 44(%esp)
	movl	%ecx, 116(%esp)
	jmp	L467
L280:
	cmpl	$-1, 108(%esp)
	jne	L1037
	testb	$1, 100(%esp)
	movl	%esi, 116(%esp)
	je	L285
	movl	$6, 108(%esp)
	jmp	L282
L1094:
	movl	260(%esp), %edx
	testl	%edx, %edx
	js	L1109
	fstp	%st(0)
	jmp	L291
L1176:
	fstp	%st(0)
L291:
	leal	0(,%ecx,4), %eax
	addl	$_NAN_REP.3485, %eax
	movl	%eax, 4(%esp)
	leal	5232(%esp), %eax
	movl	%eax, (%esp)
	call	_strcpy
L294:
	movl	$3, 96(%esp)
L326:
	cmpb	$0, 187(%esp)
	jne	L658
L1105:
	movl	148(%esp), %eax
	testl	%eax, %eax
	je	L435
	cmpb	$43, 166(%esp)
	jne	L435
	movb	$45, 166(%esp)
	jmp	L435
L437:
	movl	96(%esp), %eax
	movl	96(%esp), %edx
	xorl	$-1, %eax
	sarl	$31, %eax
	andl	%edx, %eax
	movl	%eax, 72(%esp)
	jmp	L263
L265:
	testb	$1, 100(%esp)
	je	L267
	movl	116(%esp), %ebx
	movl	(%ebx), %eax
	addl	$4, %ebx
	movl	%eax, %esi
	movl	%eax, 40(%esp)
	sarl	$31, %esi
	movl	%ebx, 116(%esp)
	movl	%esi, 44(%esp)
	movl	44(%esp), %ecx
	testl	%ecx, %ecx
	jns	L269
L1083:
	negl	40(%esp)
	adcl	$0, 44(%esp)
	movb	$45, 166(%esp)
	negl	44(%esp)
	jmp	L269
L461:
	testb	$1, 100(%esp)
	je	L463
	movl	116(%esp), %esi
	movl	116(%esp), %ecx
	addl	$4, %ecx
	movl	(%esi), %ebx
	xorl	%esi, %esi
	movl	%ebx, 40(%esp)
	movl	%esi, 44(%esp)
	movl	%ecx, 116(%esp)
	jmp	L462
L272:
	movl	100(%esp), %eax
	movl	116(%esp), %esi
	andl	$-2, %eax
	movl	%eax, 100(%esp)
	orl	$528, 100(%esp)
	testb	$2, 100(%esp)
	jne	L1110
L274:
	movl	116(%esp), %ecx
	addl	$8, %esi
	movl	%esi, 128(%esp)
	fldl	(%ecx)
	jmp	L275
L446:
	testb	$1, 100(%esp)
	je	L448
	movl	116(%esp), %esi
	movl	116(%esp), %ecx
	addl	$4, %ecx
	movl	(%esi), %ebx
	xorl	%esi, %esi
	movl	%ebx, 40(%esp)
	movl	%esi, 44(%esp)
	movl	%ecx, 116(%esp)
	jmp	L447
L1046:
	movl	96(%esp), %eax
	movl	%eax, 72(%esp)
	cmpl	%esi, %eax
	jge	L485
	movl	%esi, 72(%esp)
	jmp	L485
L1088:
	movl	116(%esp), %eax
	jmp	L450
L261:
	movb	2(%ecx), %bl
	movl	%esi, %ecx
	orl	$4, 100(%esp)
	jmp	L951
L448:
	testb	$4, 100(%esp)
	je	L449
	movl	116(%esp), %ebx
	movl	$0, 44(%esp)
	movl	(%ebx), %eax
	addl	$4, %ebx
	andl	$65535, %eax
	movl	%ebx, 116(%esp)
	movl	%eax, 40(%esp)
	jmp	L447
L463:
	testb	$4, 100(%esp)
	je	L464
	movl	116(%esp), %ebx
	movl	$0, 44(%esp)
	movl	(%ebx), %eax
	addl	$4, %ebx
	andl	$65535, %eax
	movl	%ebx, 116(%esp)
	movl	%eax, 40(%esp)
	jmp	L462
L267:
	testb	$4, 100(%esp)
	je	L268
	movl	116(%esp), %ecx
	movswl	(%ecx), %eax
	movl	%eax, %ebx
	addl	$4, %ecx
	sarl	$31, %ebx
	movl	%eax, 40(%esp)
	movl	%ebx, 44(%esp)
	movl	%ecx, 116(%esp)
	jmp	L266
L468:
	testb	$4, 100(%esp)
	je	L469
	movl	116(%esp), %ebx
	movl	$0, 44(%esp)
	movl	(%ebx), %eax
	addl	$4, %ebx
	andl	$65535, %eax
	movl	%ebx, 116(%esp)
	movl	%eax, 40(%esp)
	jmp	L467
L667:
	xorl	%ecx, %ecx
	movb	$0, 166(%esp)
	movl	$16, 100(%esp)
	jmp	L270
L440:
	testb	$1, 100(%esp)
	jne	L1111
	testb	$4, 100(%esp)
	je	L443
	movl	116(%esp), %esi
	movl	120(%esp), %edx
	movl	(%esi), %eax
	addl	$4, %esi
	movl	%esi, 116(%esp)
	movw	%dx, (%eax)
	jmp	L441
L1095:
	fld	%st(0)
	fstpt	208(%esp)
	fldz
	fxch	%st(1)
	fucom	%st(1)
	fnstsw	%ax
	fstp	%st(1)
	andb	$69, %ah
	cmpb	$64, %ah
	jne	L1112
	leal	10223(%esp), %ecx
	movl	%ecx, 96(%esp)
	movl	%ecx, %esi
L327:
	fstpt	(%esp)
	leal	208(%esp), %eax
	movl	%eax, 12(%esp)
	call	___modfl
	fstpt	80(%esp)
	fldt	208(%esp)
	fld1
	fucomp	%st(1)
	fnstsw	%ax
	testb	$69, %ah
	je	L1113
	movl	$0, 152(%esp)
	movl	$0, 160(%esp)
L333:
	fldz
	fxch	%st(1)
	fucom	%st(1)
	fnstsw	%ax
	fstp	%st(1)
	andb	$69, %ah
	cmpb	$64, %ah
	je	L1177
	leal	5233(%esp), %edx
	movl	%edx, 72(%esp)
	cmpl	%edx, %esi
	jb	L1178
	leal	-1(%esi), %edi
	leal	224(%esp), %ecx
	movb	%bl, 156(%esp)
	movl	%ecx, %esi
	movl	%edi, %ebx
	movl	%edx, %edi
	jmp	L339
	.p2align 4,,7
L1114:
	fldt	224(%esp)
	fnstcw	174(%esp)
	fmul	%st, %st(1)
	movw	174(%esp), %ax
	movb	$12, %ah
	movw	%ax, 172(%esp)
	movb	$57, %al
	fldt	208(%esp)
	fsubp	%st, %st(2)
	fxch	%st(1)
	fldcw	172(%esp)
	fistpl	168(%esp)
	fldcw	174(%esp)
	movl	168(%esp), %ecx
	cmpl	$9, %ecx
	jg	L337
	testl	%ecx, %ecx
	js	L642
	leal	48(%ecx), %eax
L337:
	movl	%ebx, %ecx
	movb	%al, 1(%ebx)
L338:
	fld	%st(0)
	fstpt	208(%esp)
	movl	188(%esp), %eax
	incl	%eax
	fldz
	fxch	%st(1)
	movl	%eax, 188(%esp)
	fucom	%st(1)
	fnstsw	%ax
	fstp	%st(1)
	andb	$69, %ah
	cmpb	$64, %ah
	je	L1179
	decl	%ebx
	cmpl	%edi, %ecx
	jb	L1180
L339:
	flds	LC4
	fdivr	%st, %st(1)
	fxch	%st(1)
	movl	%esi, 12(%esp)
	fstpt	(%esp)
	fstpt	48(%esp)
	call	___modfl
	fldz
	fxch	%st(1)
	fucompp
	fnstsw	%ax
	andb	$69, %ah
	cmpb	$64, %ah
	fldt	48(%esp)
	jne	L1114
	fstp	%st(0)
	movl	%ebx, %ecx
	movb	$48, 1(%ebx)
	fldt	224(%esp)
	jmp	L338
	.p2align 4,,7
L629:
	movl	%edx, %ecx
L885:
	movb	-1(%ecx), %al
	leal	-1(%ecx), %edx
	cmpb	$48, %al
	je	L629
	cmpb	156(%esp), %al
	jne	L315
L1100:
	movl	100(%esp), %eax
	andl	$64, %eax
	cmpl	$1, %eax
	sbbl	$0, %ecx
	cmpw	$0, 152(%esp)
	jne	L316
L1101:
	movl	140(%esp), %eax
	movl	136(%esp), %edx
	orl	%edx, %eax
	cmpl	$1, %eax
	sbbl	%esi, %esi
	xorl	$-1, %esi
	andl	$-16382, %esi
	jmp	L317
L1092:
	testb	$64, 100(%esp)
	jne	L1037
L1056:
	movl	%esi, 116(%esp)
	movl	$39, 108(%esp)
	jmp	L282
L1109:
	cmpw	$32767, %ax
	jne	L293
	fstp	%st(0)
	leal	0(,%ecx,4), %eax
	andl	$2147483647, %edx
	jne	L295
	movl	256(%esp), %edx
	testl	%edx, %edx
	je	L296
L295:
	addl	$_NAN_REP.3485, %eax
	leal	5232(%esp), %edx
	movl	%eax, 4(%esp)
	movl	%edx, (%esp)
	call	_strcpy
	jmp	L294
L1093:
	testl	$2147483647, 196(%esp)
	jne	L288
	movl	192(%esp), %eax
	testl	%eax, %eax
	je	L287
L288:
	movl	$0, 148(%esp)
	cmpb	$0, 201(%esp)
	jns	L289
L286:
	movb	$45, 187(%esp)
	movl	$1, 148(%esp)
	fchs
	jmp	L289
L481:
	cmpb	$48, (%ebx)
	je	L671
	leal	-1(%ebx), %eax
	movb	$48, -1(%ebx)
L482:
	leal	10224(%esp), %ecx
	movl	108(%esp), %ebx
	subl	%eax, %ecx
	movl	%ecx, 96(%esp)
	movl	%ecx, 72(%esp)
	cmpl	%ebx, %ecx
	jl	L1115
L535:
	movl	108(%esp), %esi
	movl	%eax, %ebx
	jmp	L485
	.p2align 4,,7
L680:
	movl	$88, %eax
	jmp	L513
L681:
	movl	$120, %eax
	jmp	L513
L456:
	movl	96(%esp), %eax
	movl	96(%esp), %edx
	xorl	$-1, %eax
	movb	$0, 166(%esp)
	sarl	$31, %eax
	andl	%edx, %eax
	movl	%eax, 72(%esp)
	jmp	L263
L1096:
	movl	140(%esp), %edi
	testl	%edi, %edi
	js	L624
	movl	136(%esp), %eax
	movl	140(%esp), %edx
	xorl	%esi, %esi
	.p2align 4,,7
L298:
	shldl	$1, %eax, %edx
	incl	%esi
	addl	%eax, %eax
	testl	%edx, %edx
	jns	L298
	movl	%esi, 96(%esp)
	movl	160(%esp), %esi
	testl	%esi, %esi
	je	L299
	movl	%eax, 136(%esp)
	movl	%edx, 140(%esp)
L299:
	cmpl	$59, 96(%esp)
	jg	L625
	movl	96(%esp), %eax
	xorl	$-1, %eax
	andl	$3, %eax
	je	L300
	movl	96(%esp), %esi
	addl	%eax, %esi
	movl	%esi, 96(%esp)
	jmp	L297
L1112:
	flds	LC8
	fxch	%st(1)
	fucom	%st(1)
	fnstsw	%ax
	fstp	%st(1)
	testb	$69, %ah
	jne	L956
	fld	%st(0)
	fmuls	LC9
	xorl	%esi, %esi
	xorl	%edx, %edx
	movl	$4096, %ecx
	fld1
	jmp	L331
	.p2align 4,,7
L1182:
	fxch	%st(1)
L331:
	fldt	_powten+144(%edx)
	fxch	%st(2)
	fucom	%st(2)
	fnstsw	%ax
	testb	$5, %ah
	jne	L1181
	fldt	_powtenneg+144(%edx)
	fmulp	%st, %st(1)
	fxch	%st(1)
	addl	%ecx, %esi
	fmulp	%st, %st(2)
	jmp	L329
L1181:
	fstp	%st(2)
	fxch	%st(1)
L329:
	sarl	%ecx
	subl	$12, %edx
	cmpl	$-156, %edx
	jne	L1182
	fstp	%st(0)
	fdivrp	%st, %st(1)
	movl	%esi, 188(%esp)
	testl	%esi, %esi
	fld	%st(0)
	fstpt	208(%esp)
	jle	L638
	movl	92(%esp), %eax
	leal	10223(%esp), %ecx
	subl	%esi, %eax
	movl	%ecx, 96(%esp)
	leal	4991(%eax), %edx
	movl	%ecx, %eax
	.p2align 4,,7
L332:
	movb	$48, (%eax)
	decl	%eax
	cmpl	%edx, %eax
	jne	L332
	movl	96(%esp), %edx
	subl	%esi, %edx
	movl	%edx, %esi
	jmp	L327
L453:
	movl	%ebx, (%esp)
	call	_strlen
	movb	$0, 166(%esp)
	movl	%eax, 96(%esp)
	xorl	$-1, %eax
	sarl	$31, %eax
	movl	96(%esp), %ecx
	andl	%ecx, %eax
	movl	%eax, 72(%esp)
	jmp	L263
L1091:
	negl	%ecx
	movl	%ecx, 112(%esp)
	movl	%eax, 116(%esp)
	movl	%esi, %ecx
	jmp	L92
L146:
	leal	3(%ecx), %ebx
	xorl	%eax, %eax
	movl	%ebx, 128(%esp)
	movb	3(%ecx), %bl
	movb	%bl, %al
	testb	$-128, %al
	jne	L568
	testb	$8, ___dj_ctype_flags+2(%eax,%eax)
	je	L568
	movl	%edx, 72(%esp)
	xorl	%esi, %esi
	movsbl	%bl, %eax
	movl	128(%esp), %edx
	jmp	L151
	.p2align 4,,7
L1116:
	testb	$8, ___dj_ctype_flags+2(%ecx,%ecx)
	je	L981
L151:
	leal	(%esi,%esi,4), %esi
	xorl	%ecx, %ecx
	addl	%esi, %esi
	cmpb	$47, %al
	jle	L150
	movb	$9, %cl
	cmpb	$57, %al
	jg	L150
	leal	-48(%eax), %ecx
L150:
	incl	%edx
	addl	%ecx, %esi
	xorl	%ecx, %ecx
	movsbl	(%edx), %eax
	movb	%al, %cl
	testb	$-128, %cl
	je	L1116
L981:
	movl	%edx, 128(%esp)
	movl	72(%esp), %edx
L149:
	cmpb	$36, %al
	je	L1117
L152:
	movl	116(%esp), %ecx
	movl	116(%esp), %eax
	addl	$4, %eax
	movl	(%ecx), %ecx
	movl	%ecx, 108(%esp)
	testl	%ecx, %ecx
	js	L1118
L201:
	movl	%edx, %ecx
	movl	%eax, 116(%esp)
	jmp	L951
L469:
	movl	116(%esp), %edx
	movl	116(%esp), %ecx
	addl	$4, %ecx
	movl	(%edx), %eax
	xorl	%edx, %edx
	movl	%eax, 40(%esp)
	movl	%edx, 44(%esp)
	movl	%ecx, 116(%esp)
	jmp	L467
L1111:
	movl	116(%esp), %ecx
	movl	120(%esp), %ebx
	movl	(%ecx), %eax
	addl	$4, %ecx
	movl	%ecx, 116(%esp)
	movl	%ebx, (%eax)
	jmp	L441
L464:
	movl	116(%esp), %edx
	movl	116(%esp), %ecx
	addl	$4, %ecx
	movl	(%edx), %eax
	xorl	%edx, %edx
	movl	%eax, 40(%esp)
	movl	%edx, 44(%esp)
	movl	%ecx, 116(%esp)
	jmp	L462
L449:
	movl	116(%esp), %edx
	movl	116(%esp), %ecx
	addl	$4, %ecx
	movl	(%edx), %eax
	xorl	%edx, %edx
	movl	%eax, 40(%esp)
	movl	%edx, 44(%esp)
	movl	%ecx, 116(%esp)
	jmp	L447
L268:
	movl	116(%esp), %esi
	movl	(%esi), %eax
	addl	$4, %esi
	movl	%eax, %edx
	movl	%eax, 40(%esp)
	sarl	$31, %edx
	movl	%esi, 116(%esp)
	movl	%edx, 44(%esp)
	jmp	L266
L1087:
	movl	$_NULL_REP, %ebx
	jmp	L452
L1106:
	movl	72(%esp), %ebx
	incl	%ebx
	movl	%ebx, 148(%esp)
	decl	%ebx
	jle	L1119
	movl	10256(%esp), %eax
	movl	10260(%esp), %edx
	movl	%edx, 132(%esp)
	movl	%eax, %edx
	movsbl	(%eax), %ebx
	movl	$1, %eax
	movl	%ecx, 96(%esp)
	movl	%esi, 104(%esp)
	movl	%eax, %ecx
	xorl	%esi, %esi
	movl	%edi, 124(%esp)
	movl	%ebp, 128(%esp)
L213:
	testl	%ebx, %ebx
	je	L614
	cmpl	$37, %ebx
	jne	L836
	jmp	L216
	.p2align 4,,7
L1120:
	cmpl	$37, %eax
	je	L216
L836:
	incl	%edx
	movsbl	(%edx), %eax
	testl	%eax, %eax
	jne	L1120
L614:
	movl	10256(%esp), %eax
L214:
	xorl	%edi, %edi
L949:
	leal	1(%eax), %ebx
	movl	%ebx, 152(%esp)
	movsbl	1(%eax), %ebx
	cmpb	$122, %bl
	ja	L1000
	movb	%bl, %dl
	andl	$255, %edx
	jmp	*L234(,%edx,4)
	.p2align 2
	.p2align 2
L234:
	.long	L1026
	.long	L1000
	.long	L1000
	.long	L1000
	.long	L1000
	.long	L1000
	.long	L1000
	.long	L1000
	.long	L1000
	.long	L1000
	.long	L1000
	.long	L1000
	.long	L1000
	.long	L1000
	.long	L1000
	.long	L1000
	.long	L1000
	.long	L1000
	.long	L1000
	.long	L1000
	.long	L1000
	.long	L1000
	.long	L1000
	.long	L1000
	.long	L1000
	.long	L1000
	.long	L1000
	.long	L1000
	.long	L1000
	.long	L1000
	.long	L1000
	.long	L1000
	.long	L1035
	.long	L1000
	.long	L1000
	.long	L1035
	.long	L1000
	.long	L1000
	.long	L1000
	.long	L1035
	.long	L1000
	.long	L1000
	.long	L221
	.long	L1035
	.long	L1000
	.long	L1035
	.long	L222
	.long	L1000
	.long	L223
	.long	L223
	.long	L223
	.long	L223
	.long	L223
	.long	L223
	.long	L223
	.long	L223
	.long	L223
	.long	L223
	.long	L1000
	.long	L1000
	.long	L1000
	.long	L1000
	.long	L1000
	.long	L1000
	.long	L1000
	.long	L224
	.long	L1000
	.long	L1000
	.long	L227
	.long	L224
	.long	L224
	.long	L224
	.long	L1000
	.long	L1000
	.long	L1000
	.long	L1000
	.long	L230
	.long	L1000
	.long	L1000
	.long	L227
	.long	L1000
	.long	L1000
	.long	L1000
	.long	L1000
	.long	L1000
	.long	L227
	.long	L1000
	.long	L1000
	.long	L227
	.long	L1000
	.long	L1000
	.long	L1000
	.long	L1000
	.long	L1000
	.long	L1000
	.long	L1000
	.long	L1000
	.long	L224
	.long	L1000
	.long	L232
	.long	L1002
	.long	L224
	.long	L224
	.long	L224
	.long	L1035
	.long	L1002
	.long	L230
	.long	L1000
	.long	L231
	.long	L1000
	.long	L232
	.long	L1002
	.long	L232
	.long	L1000
	.long	L1000
	.long	L232
	.long	L1035
	.long	L1002
	.long	L1000
	.long	L1000
	.long	L1002
	.long	L1000
	.long	L1035
L1090:
	leal	1(%ecx), %esi
	movl	%esi, 124(%esp)
	decl	%esi
	je	L544
	movl	10256(%esp), %esi
	movl	10260(%esp), %eax
	movl	%eax, 116(%esp)
	movl	$1, %eax
	movsbl	(%esi), %ebx
	movl	%esi, %edx
	movl	%ecx, 96(%esp)
	xorl	%esi, %esi
	movl	%eax, %ecx
	movl	%edi, 104(%esp)
	movl	%ebp, 112(%esp)
L99:
	testl	%ebx, %ebx
	je	L563
	cmpl	$37, %ebx
	jne	L831
	jmp	L102
	.p2align 4,,7
L1121:
	cmpl	$37, %eax
	je	L102
L831:
	incl	%edx
	movsbl	(%edx), %eax
	testl	%eax, %eax
	jne	L1121
L563:
	movl	10256(%esp), %eax
L100:
	xorl	%edi, %edi
L947:
	movsbl	1(%eax), %ebx
	leal	1(%eax), %edx
	cmpb	$122, %bl
	movl	%edx, 128(%esp)
	ja	L964
	movb	%bl, %dl
	andl	$255, %edx
	jmp	*L119(,%edx,4)
	.p2align 2
	.p2align 2
L119:
	.long	L978
	.long	L964
	.long	L964
	.long	L964
	.long	L964
	.long	L964
	.long	L964
	.long	L964
	.long	L964
	.long	L964
	.long	L964
	.long	L964
	.long	L964
	.long	L964
	.long	L964
	.long	L964
	.long	L964
	.long	L964
	.long	L964
	.long	L964
	.long	L964
	.long	L964
	.long	L964
	.long	L964
	.long	L964
	.long	L964
	.long	L964
	.long	L964
	.long	L964
	.long	L964
	.long	L964
	.long	L964
	.long	L1027
	.long	L964
	.long	L964
	.long	L1027
	.long	L964
	.long	L964
	.long	L964
	.long	L1027
	.long	L964
	.long	L964
	.long	L106
	.long	L1027
	.long	L964
	.long	L1027
	.long	L107
	.long	L964
	.long	L108
	.long	L108
	.long	L108
	.long	L108
	.long	L108
	.long	L108
	.long	L108
	.long	L108
	.long	L108
	.long	L108
	.long	L964
	.long	L964
	.long	L964
	.long	L964
	.long	L964
	.long	L964
	.long	L964
	.long	L109
	.long	L964
	.long	L964
	.long	L112
	.long	L109
	.long	L109
	.long	L109
	.long	L964
	.long	L964
	.long	L964
	.long	L964
	.long	L115
	.long	L964
	.long	L964
	.long	L112
	.long	L964
	.long	L964
	.long	L964
	.long	L964
	.long	L964
	.long	L112
	.long	L964
	.long	L964
	.long	L112
	.long	L964
	.long	L964
	.long	L964
	.long	L964
	.long	L964
	.long	L964
	.long	L964
	.long	L964
	.long	L109
	.long	L964
	.long	L117
	.long	L967
	.long	L109
	.long	L109
	.long	L109
	.long	L1027
	.long	L967
	.long	L115
	.long	L964
	.long	L116
	.long	L964
	.long	L117
	.long	L967
	.long	L117
	.long	L964
	.long	L964
	.long	L117
	.long	L1027
	.long	L967
	.long	L964
	.long	L964
	.long	L967
	.long	L964
	.long	L1027
L116:
	testl	$1, %edi
	je	L131
L115:
	orl	$2, %edi
	movl	128(%esp), %eax
	jmp	L947
L231:
	testl	$1, %edi
	je	L246
L230:
	orl	$2, %edi
	movl	152(%esp), %eax
	jmp	L949
L112:
	movl	128(%esp), %edx
	orl	$1, %edi
L118:
	cmpl	%ecx, 96(%esp)
	je	L1122
L690:
	cmpl	%esi, %ecx
	je	L1123
	.p2align 4,,7
L105:
	cmpl	%ecx, 124(%esp)
	jg	L99
L978:
	movl	104(%esp), %edi
	movl	112(%esp), %ebp
L98:
	movl	72(%esp), %esi
	movl	$1, 124(%esp)
	movb	1(%esi), %bl
	jmp	L97
L117:
	movl	128(%esp), %edx
	cmpl	%ecx, 96(%esp)
	je	L1124
L691:
	cmpl	%esi, %ecx
	jne	L105
L141:
	movl	116(%esp), %esi
	addl	$4, %esi
	movl	%esi, 116(%esp)
L142:
	movl	%ecx, %esi
	incl	%ecx
	jmp	L105
L227:
	movl	152(%esp), %edx
	orl	$1, %edi
L233:
	cmpl	%ecx, 72(%esp)
	je	L1125
L255:
	cmpl	%esi, %ecx
	je	L1126
	.p2align 4,,7
L219:
	cmpl	%ecx, 148(%esp)
	jg	L213
L1026:
	movl	104(%esp), %esi
	movl	124(%esp), %edi
	movl	96(%esp), %ecx
	movl	128(%esp), %ebp
	movb	2(%esi), %bl
	movl	$1, 124(%esp)
	jmp	L951
L232:
	movl	152(%esp), %edx
	cmpl	%ecx, 72(%esp)
	je	L1127
L259:
	cmpl	%esi, %ecx
	jne	L219
L256:
	movl	132(%esp), %eax
	addl	$4, %eax
	movl	%eax, 132(%esp)
L257:
	movl	%ecx, %esi
	incl	%ecx
	jmp	L219
L496:
	movl	%eax, %ecx
	movl	%ebx, %edi
	cmpl	92(%esp), %eax
	jbe	L1044
L823:
	decl	%ecx
	decl	%edi
	cmpl	92(%esp), %ecx
	movb	(%ecx), %dl
	movb	%dl, (%edi)
	jne	L823
	subl	%eax, %ebx
	leal	5232(%esp,%ebx), %ebx
L498:
	cmpb	100(%esp), %dl
	sete	%al
	andl	$255, %eax
	addl	%eax, %ebx
	leal	10224(%esp), %eax
	subl	%ebx, %eax
	movl	%eax, 96(%esp)
	movl	%eax, 72(%esp)
	cmpl	%esi, %eax
	jge	L485
	movl	%esi, 72(%esp)
	jmp	L485
L967:
	movl	128(%esp), %edx
	jmp	L118
L1002:
	movl	152(%esp), %edx
	jmp	L233
L964:
	movl	128(%esp), %edx
	jmp	L105
L1000:
	movl	152(%esp), %edx
	jmp	L219
L246:
	orl	$1, %edi
L1035:
	movl	152(%esp), %eax
	jmp	L949
L131:
	orl	$1, %edi
L1027:
	movl	128(%esp), %eax
	jmp	L947
L106:
	leal	2(%eax), %ebx
	xorl	%edx, %edx
	movsbl	2(%eax), %eax
	movb	%al, %dl
	testb	$-128, %dl
	jne	L550
	testb	$8, ___dj_ctype_flags+2(%edx,%edx)
	movl	$0, %edx
	je	L121
	movl	%ecx, 128(%esp)
	jmp	L123
L1128:
	testb	$8, ___dj_ctype_flags+2(%ecx,%ecx)
	je	L969
L123:
	leal	(%edx,%edx,4), %ebp
	xorl	%edx, %edx
	addl	%ebp, %ebp
	cmpb	$47, %al
	jle	L122
	movb	$9, %dl
	cmpb	$57, %al
	jg	L122
	leal	-48(%eax), %edx
L122:
	incl	%ebx
	addl	%ebp, %edx
	movsbl	(%ebx), %eax
	movb	%al, %cl
	andl	$255, %ecx
	testb	$-128, %cl
	je	L1128
L969:
	movl	128(%esp), %ecx
L121:
	cmpl	%edx, 96(%esp)
	je	L1129
L685:
	movl	%ebx, %eax
	cmpl	%ecx, %edx
	jne	L947
L1028:
	movl	116(%esp), %edx
	incl	%ecx
	addl	$4, %edx
	movl	%edx, 116(%esp)
	jmp	L947
L221:
	leal	2(%eax), %ebx
	xorl	%edx, %edx
	movsbl	2(%eax), %eax
	movb	%al, %dl
	testb	$-128, %dl
	jne	L601
	testb	$8, ___dj_ctype_flags+2(%edx,%edx)
	movl	$0, %edx
	je	L236
	movl	%ecx, 152(%esp)
	jmp	L238
L1130:
	testb	$8, ___dj_ctype_flags+2(%ecx,%ecx)
	je	L1004
L238:
	leal	(%edx,%edx,4), %ebp
	xorl	%edx, %edx
	addl	%ebp, %ebp
	cmpb	$47, %al
	jle	L237
	movb	$9, %dl
	cmpb	$57, %al
	jg	L237
	leal	-48(%eax), %edx
L237:
	incl	%ebx
	addl	%ebp, %edx
	movsbl	(%ebx), %eax
	movb	%al, %cl
	andl	$255, %ecx
	testb	$-128, %cl
	je	L1130
L1004:
	movl	152(%esp), %ecx
L236:
	cmpl	%edx, 72(%esp)
	je	L1131
L239:
	movl	%ebx, %eax
	cmpl	%ecx, %edx
	jne	L949
L1036:
	movl	132(%esp), %edx
	incl	%ecx
	addl	$4, %edx
	movl	%edx, 132(%esp)
	jmp	L949
L109:
	movl	128(%esp), %edx
	cmpl	%ecx, 96(%esp)
	je	L1132
L689:
	cmpl	%esi, %ecx
	jne	L105
	andl	$2, %edi
	je	L1049
	movl	116(%esp), %ebp
	addl	$12, %ebp
	movl	%ebp, 116(%esp)
	jmp	L142
L108:
	movsbl	%bl, %eax
	xorl	%esi, %esi
	movl	128(%esp), %edx
	testb	$8, ___dj_ctype_flags+2(%eax,%eax)
	jne	L830
	jmp	L1027
	.p2align 4,,7
L1133:
	testb	$8, ___dj_ctype_flags+2(%eax,%eax)
	je	L562
L830:
	leal	(%esi,%esi,4), %esi
	xorl	%eax, %eax
	addl	%esi, %esi
	cmpb	$47, %bl
	jle	L130
	movb	$9, %al
	cmpb	$57, %bl
	jg	L130
	movsbl	%bl, %eax
	subl	$48, %eax
L130:
	incl	%edx
	addl	%eax, %esi
	xorl	%eax, %eax
	movb	(%edx), %bl
	movb	%bl, %al
	testb	$-128, %al
	je	L1133
L562:
	movl	%edx, %eax
	jmp	L947
L107:
	cmpb	$42, 2(%eax)
	je	L125
	addl	$2, %eax
	jmp	L947
L223:
	movsbl	%bl, %eax
	xorl	%esi, %esi
	movl	152(%esp), %edx
	testb	$8, ___dj_ctype_flags+2(%eax,%eax)
	jne	L835
	jmp	L1035
	.p2align 4,,7
L1134:
	testb	$8, ___dj_ctype_flags+2(%eax,%eax)
	je	L613
L835:
	leal	(%esi,%esi,4), %esi
	xorl	%eax, %eax
	addl	%esi, %esi
	cmpb	$47, %bl
	jle	L245
	movb	$9, %al
	cmpb	$57, %bl
	jg	L245
	movsbl	%bl, %eax
	subl	$48, %eax
L245:
	incl	%edx
	addl	%eax, %esi
	xorl	%eax, %eax
	movb	(%edx), %bl
	movb	%bl, %al
	testb	$-128, %al
	je	L1134
L613:
	movl	%edx, %eax
	jmp	L949
L222:
	cmpb	$42, 2(%eax)
	je	L240
	addl	$2, %eax
	jmp	L949
L224:
	movl	152(%esp), %edx
	cmpl	%ecx, 72(%esp)
	je	L1135
L252:
	cmpl	%esi, %ecx
	jne	L219
	andl	$2, %edi
	je	L1055
	movl	132(%esp), %eax
	addl	$12, %eax
	movl	%eax, 132(%esp)
	jmp	L257
	.p2align 4,,7
L1179:
	fstp	%st(0)
	jmp	L1009
L1180:
	fstp	%st(0)
L1009:
	movb	156(%esp), %bl
	movl	%ecx, %esi
	jmp	L335
L1177:
	fstp	%st(0)
	jmp	L335
L1178:
	fstp	%st(0)
L335:
	leal	-69(%ebx), %eax
	cmpb	$34, %al
	jbe	L1136
L643:
	movl	$0, 96(%esp)
	jmp	L326
L102:
	movl	%edx, %eax
	jmp	L100
L216:
	movl	%edx, %eax
	jmp	L214
L642:
	movb	$48, %al
	jmp	L337
L1136:
	andl	$255, %eax
	jmp	*L344(,%eax,4)
	.p2align 2
	.p2align 2
L344:
	.long	L341
	.long	L342
	.long	L343
	.long	L643
	.long	L643
	.long	L643
	.long	L643
	.long	L643
	.long	L643
	.long	L643
	.long	L643
	.long	L643
	.long	L643
	.long	L643
	.long	L643
	.long	L643
	.long	L643
	.long	L643
	.long	L643
	.long	L643
	.long	L643
	.long	L643
	.long	L643
	.long	L643
	.long	L643
	.long	L643
	.long	L643
	.long	L643
	.long	L643
	.long	L643
	.long	L643
	.long	L643
	.long	L341
	.long	L342
	.long	L343
L343:
	movl	108(%esp), %eax
	testl	%eax, %eax
	je	L405
	cmpl	$1, 152(%esp)
	adcl	$-1, 108(%esp)
L406:
	movl	188(%esp), %edx
	cmpl	108(%esp), %edx
	jg	L407
	testl	%edx, %edx
	jne	L1137
	fldz
	fldt	80(%esp)
	fucom	%st(1)
	fnstsw	%ax
	fstp	%st(1)
	andb	$69, %ah
	cmpb	$64, %ah
	je	L1183
	fldl	LC10
	fucompp
	fnstsw	%ax
	testb	$69, %ah
	je	L407
	jmp	L411
L1183:
	fstp	%st(0)
L411:
	leal	5233(%esp), %esi
	movb	$48, 5233(%esp)
	leal	5234(%esp), %edx
	movl	%esi, 72(%esp)
L410:
	movl	108(%esp), %eax
	testl	%eax, %eax
	jne	L1138
	movl	100(%esp), %esi
	movl	$0, 96(%esp)
	andl	$64, %esi
	movl	%esi, 152(%esp)
	je	L416
L415:
	movb	_decimal_point, %al
	movl	$1, 96(%esp)
	movb	%al, (%edx)
	incl	%edx
L416:
	leal	1(%edx), %edi
	movl	%ebp, 156(%esp)
	leal	224(%esp), %esi
	movl	%edi, %ebp
	movl	108(%esp), %ebx
	movl	160(%esp), %edi
L417:
	fldz
	fldt	80(%esp)
	fucompp
	fnstsw	%ax
	andb	$69, %ah
	xorb	$64, %ah
	leal	-1(%ebp), %ecx
	je	L705
	testl	%ebx, %ebx
	je	L705
	fldt	80(%esp)
	fmuls	LC4
	movl	%esi, 12(%esp)
	fstpt	(%esp)
	call	___modfl
	fnstcw	174(%esp)
	movw	174(%esp), %ax
	fstpt	80(%esp)
	movb	$12, %ah
	movw	%ax, 172(%esp)
	fldt	224(%esp)
	fldcw	172(%esp)
	fistpl	168(%esp)
	fldcw	174(%esp)
	movl	168(%esp), %eax
	cmpl	$9, %eax
	jg	L656
	testl	%eax, %eax
	js	L419
	leal	48(%eax), %ecx
	cmpl	$1, %edi
	movb	%cl, -1(%ebp)
	je	L1139
L420:
	decl	%ebx
	xorl	%edi, %edi
	incl	%ebp
	jmp	L417
L342:
	movl	188(%esp), %eax
	testl	%eax, %eax
	jne	L1140
	leal	5233(%esp), %edx
	movb	$48, 5233(%esp)
	leal	5234(%esp), %ebx
	movl	%edx, 72(%esp)
L346:
	movl	108(%esp), %eax
	testl	%eax, %eax
	je	L1141
	fldz
	movb	_decimal_point, %al
	fldt	80(%esp)
	movb	%al, (%ebx)
	fucompp
	fnstsw	%ax
	andb	$69, %ah
	incl	%ebx
	xorb	$64, %ah
	je	L537
	leal	224(%esp), %ecx
L355:
	fldt	80(%esp)
	fmuls	LC4
	movl	%ecx, 12(%esp)
	movl	%ecx, 68(%esp)
	fstpt	(%esp)
	call	___modfl
	movl	68(%esp), %ecx
	fnstcw	174(%esp)
	movw	174(%esp), %ax
	fstpt	80(%esp)
	movb	$12, %ah
	movw	%ax, 172(%esp)
	movb	$57, %al
	fldt	224(%esp)
	fldcw	172(%esp)
	fistpl	168(%esp)
	fldcw	174(%esp)
	movl	168(%esp), %edx
	cmpl	$9, %edx
	jg	L353
	testl	%edx, %edx
	js	L646
	leal	48(%edx), %eax
L353:
	movb	%al, (%ebx)
	incl	%ebx
	decl	108(%esp)
	fldz
	je	L354
	fldt	80(%esp)
	fucompp
	fnstsw	%ax
	andb	$69, %ah
	xorb	$64, %ah
	jne	L355
	movl	108(%esp), %eax
	decl	%eax
	jmp	L351
L341:
	movl	188(%esp), %edx
	movl	$0, 96(%esp)
L358:
	testl	%edx, %edx
	je	L359
	movb	1(%esi), %cl
	leal	1(%esi), %eax
	movb	%cl, 5233(%esp)
	movl	108(%esp), %ecx
	testl	%ecx, %ecx
	jne	L360
	leal	5234(%esp), %ebx
	testb	$64, 100(%esp)
	je	L362
	movb	_decimal_point, %bl
	movb	%bl, 5234(%esp)
	leal	5235(%esp), %ebx
L362:
	leal	1(%eax), %ecx
	leal	10224(%esp), %esi
	cmpl	%ecx, %esi
	ja	L531
	leal	5233(%esp), %eax
	movl	$0, 108(%esp)
	movl	%eax, 72(%esp)
	movl	%eax, %esi
L530:
	decl	%edx
	movl	%edx, 188(%esp)
L365:
	fldz
	fldt	80(%esp)
	fucompp
	fnstsw	%ax
	andb	$69, %ah
	xorb	$64, %ah
	je	L1142
	movl	108(%esp), %ecx
	testl	%ecx, %ecx
	jne	L1143
L381:
	fldt	80(%esp)
	leal	187(%esp), %eax
	movl	%esi, %edx
	fstpt	(%esp)
	movl	%eax, 16(%esp)
	leal	-1(%ebx), %ecx
	movl	$0, 12(%esp)
	leal	188(%esp), %eax
	call	_doprnt_roundl
	movl	%eax, %esi
L1040:
	movl	188(%esp), %ecx
L387:
	movl	96(%esp), %edi
	testl	%edi, %edi
	je	L389
	testb	$64, 100(%esp)
	jne	L389
	cmpl	%esi, %ebx
	jbe	L1144
	movb	-1(%ebx), %dl
	leal	-1(%ebx), %eax
	cmpb	$48, %dl
	jne	L391
L826:
	cmpl	%esi, %eax
	je	L1145
	decl	%eax
	movb	(%eax), %dl
	cmpb	$48, %dl
	je	L826
L391:
	cmpb	%dl, _decimal_point
	sete	%dl
	andl	$255, %edx
	subl	%edx, %eax
	leal	1(%eax), %ebx
L389:
	movb	167(%esp), %al
	testl	%ecx, %ecx
	movb	%al, (%ebx)
	js	L1146
	movb	$43, 1(%ebx)
	addl	$2, %ebx
	movl	%ebx, 96(%esp)
L397:
	cmpl	$9, %ecx
	jle	L398
	leal	5232(%esp), %ebx
	movl	$1717986919, %edi
	jmp	L400
L1148:
	addl	$48, %edx
L399:
	movl	%ecx, %eax
	movb	%dl, (%ebx)
	imull	%edi
	sarl	$31, %ecx
	sarl	$2, %edx
	subl	%ecx, %edx
	movl	%edx, %ecx
	cmpl	$9, %edx
	jle	L1147
L400:
	movl	%ecx, %eax
	decl	%ebx
	imull	%edi
	sarl	$2, %edx
	movl	%ecx, %eax
	sarl	$31, %eax
	subl	%eax, %edx
	leal	(%edx,%edx,4), %eax
	movl	%ecx, %edx
	addl	%eax, %eax
	subl	%eax, %edx
	jns	L1148
	movb	$48, %dl
	jmp	L399
L1108:
	movl	%ebp, %ecx
	movl	72(%esp), %esi
	movl	96(%esp), %ebp
	movl	%ecx, _grouping
	jmp	L498
L1097:
	cmpl	$14, 108(%esp)
	jg	L301
	movl	$14, %ecx
	movl	108(%esp), %eax
	subl	%eax, %ecx
	movl	140(%esp), %edi
	sall	$2, %ecx
	movl	136(%esp), %esi
	shrdl	%cl, %edi, %esi
	shrl	%cl, %edi
	testb	$32, %cl
	je	L1175
	movl	%edi, %esi
	xorl	%edi, %edi
L1175:
	movl	%esi, %eax
	andl	$15, %eax
	cmpl	$8, %eax
	ja	L302
	cmpl	$8, %eax
	je	L1149
L304:
	movl	%edi, %ecx
	movl	%esi, %edx
	shrdl	$4, %ecx, %edx
	movl	108(%esp), %eax
	movl	%edx, 136(%esp)
	shrl	$4, %ecx
	movl	%ecx, 140(%esp)
	leal	4(,%eax,4), %ecx
	movl	140(%esp), %edx
	movl	136(%esp), %eax
	shrdl	%cl, %edx, %eax
	shrl	%cl, %edx
	testb	$32, %cl
	je	L1174
	movl	%edx, %eax
L1174:
	andl	$1, %eax
	testl	%eax, %eax
	je	L301
	movl	%edi, %ecx
	movl	%esi, %edx
	movl	96(%esp), %edi
	shrdl	$8, %ecx, %edx
	subl	$4, %edi
	movl	%edx, 136(%esp)
	shrl	$8, %ecx
	movl	%edi, 96(%esp)
	movl	%ecx, 140(%esp)
	jmp	L301
L671:
	movl	%ebx, %eax
	jmp	L482
L1098:
	movl	$_UPPER_DIGITS, %edi
	jmp	L305
L1102:
	negl	%esi
	movl	$0, 108(%esp)
	jmp	L318
L1113:
	fldz
	fldt	80(%esp)
	fucompp
	fnstsw	%ax
	andb	$69, %ah
	xorb	$64, %ah
	jne	L640
	movl	$1, 152(%esp)
	movl	$0, 160(%esp)
	jmp	L333
L956:
	leal	10223(%esp), %esi
	movl	%esi, 96(%esp)
	jmp	L327
L285:
	cmpl	$1, %esi
	sbbl	%esi, %esi
	andl	$7, %esi
	decl	%esi
	movl	%esi, 108(%esp)
	jmp	L282
L1107:
	movl	$-1, 108(%esp)
	jmp	L147
L443:
	testb	$8, 100(%esp)
	je	L444
	movl	116(%esp), %ecx
	movb	120(%esp), %bl
	movl	(%ecx), %eax
	addl	$4, %ecx
	movl	%ecx, 116(%esp)
	movb	%bl, (%eax)
	jmp	L441
L1126:
	andl	$2, %edi
	je	L256
L1055:
	movl	132(%esp), %eax
	addl	$8, %eax
	movl	%eax, 132(%esp)
	jmp	L257
L1123:
	andl	$2, %edi
	je	L141
L1049:
	movl	116(%esp), %edi
	addl	$8, %edi
	movl	%edi, 116(%esp)
	jmp	L142
L359:
	fldz
	fldt	80(%esp)
	fucom	%st(1)
	fnstsw	%ax
	fstp	%st(1)
	andb	$69, %ah
	cmpb	$64, %ah
	jne	L1150
	fstp	%st(0)
	movl	108(%esp), %ebx
	movb	$48, 5233(%esp)
	testl	%ebx, %ebx
	jne	L377
	testb	$64, 100(%esp)
	jne	L377
	orl	$-1, %eax
	leal	5234(%esp), %ebx
L378:
	leal	5233(%esp), %edx
	xorl	%ecx, %ecx
	movl	%edx, 72(%esp)
	movl	%edx, %esi
L380:
	movl	108(%esp), %edx
	testl	%edx, %edx
	je	L387
L385:
	leal	1(%ebx,%eax), %eax
	.p2align 4,,7
L388:
	movb	$48, (%ebx)
	incl	%ebx
	cmpl	%eax, %ebx
	jne	L388
	jmp	L387
L678:
	xorl	%edi, %edi
	jmp	L501
L541:
	movb	%bl, %al
	xorl	%ecx, %ecx
	jmp	L94
L1140:
	leal	1(%esi), %eax
	leal	10224(%esp), %ecx
	cmpl	%eax, %ecx
	jbe	L644
	leal	5233(%esp), %ebx
	movl	96(%esp), %edx
	subl	%esi, %edx
	xorl	%eax, %eax
	movl	%ebx, 72(%esp)
	movl	%ebx, %ecx
L347:
	movb	1(%esi,%eax), %bl
	movb	%bl, (%ecx,%eax)
	incl	%eax
	cmpl	%edx, %eax
	jne	L347
	xorl	$-1, %esi
	movl	72(%esp), %eax
	leal	10224(%esp,%esi), %ebx
	addl	%eax, %ebx
	jmp	L346
L625:
	movl	$63, 96(%esp)
	jmp	L297
L640:
	movl	$0, 152(%esp)
	movl	$1, 160(%esp)
	jmp	L333
L407:
	movl	108(%esp), %eax
	subl	$2, %ebx
	decl	%eax
	movb	%bl, 167(%esp)
	movl	%eax, 108(%esp)
	movl	$1, 96(%esp)
	jmp	L358
L444:
	movl	116(%esp), %esi
	movl	120(%esp), %edx
	movl	(%esi), %eax
	addl	$4, %esi
	movl	%esi, 116(%esp)
	movl	%edx, (%eax)
	jmp	L441
L1150:
	flds	LC9
	fucompp
	fnstsw	%ax
	movl	$-1, 188(%esp)
	testb	$69, %ah
	jne	L1039
	fldt	80(%esp)
	fmuls	LC8
	xorl	%edx, %edx
	orl	$-1, %ebx
	movl	$4096, %ecx
	fld1
L371:
	fldt	_powtenneg+144(%edx)
	fucomp	%st(2)
	fnstsw	%ax
	testb	$5, %ah
	jne	L369
	fldt	_powten+144(%edx)
	fmul	%st, %st(2)
	subl	%ecx, %ebx
	fmulp	%st, %st(1)
L369:
	sarl	%ecx
	subl	$12, %edx
	cmpl	$-156, %edx
	jne	L371
	fstp	%st(1)
	fldt	80(%esp)
	fmulp	%st, %st(1)
	movl	%ebx, 188(%esp)
	fstpt	80(%esp)
L1039:
	leal	224(%esp), %ecx
	movl	%ecx, %ebx
	jmp	L959
	.p2align 4,,7
L1151:
	fstp	%st(0)
	movl	188(%esp), %edi
	decl	%edi
	movl	%edi, 188(%esp)
L959:
	fldt	80(%esp)
	fmuls	LC4
	movl	%ebx, 12(%esp)
	fstpt	(%esp)
	call	___modfl
	fstpt	80(%esp)
	fldt	224(%esp)
	fldz
	fxch	%st(1)
	fucom	%st(1)
	fnstsw	%ax
	fstp	%st(1)
	andb	$69, %ah
	xorb	$64, %ah
	je	L1151
	fnstcw	174(%esp)
	movw	174(%esp), %ax
	movb	$12, %ah
	movw	%ax, 172(%esp)
	movb	$57, %al
	fldcw	172(%esp)
	fistpl	168(%esp)
	fldcw	174(%esp)
	movl	168(%esp), %edx
	cmpl	$9, %edx
	jg	L374
	testl	%edx, %edx
	js	L649
	leal	48(%edx), %eax
L374:
	movl	108(%esp), %esi
	movb	%al, 5233(%esp)
	testl	%esi, %esi
	jne	L375
	testb	$64, 100(%esp)
	jne	L375
	fldz
	fldt	80(%esp)
	fucompp
	fnstsw	%ax
	andb	$69, %ah
	xorb	$64, %ah
	je	L1152
	leal	5233(%esp), %edx
	leal	5234(%esp), %ebx
	movl	%edx, 72(%esp)
	movl	%edx, %esi
L383:
	fldz
	fldt	80(%esp)
	fucompp
	fnstsw	%ax
	andb	$69, %ah
	xorb	$64, %ah
	je	L1040
	jmp	L381
	.p2align 4,,7
L360:
	movb	_decimal_point, %al
	leal	10224(%esp), %ecx
	movb	%al, 5234(%esp)
	leal	2(%esi), %eax
	leal	5235(%esp), %ebx
	cmpl	%ecx, %eax
	jae	L364
	movl	108(%esp), %ecx
	movl	%edx, %esi
	jmp	L827
	.p2align 4,,7
L1154:
	incl	%eax
	leal	10224(%esp), %edx
	cmpl	%edx, %eax
	je	L1153
L827:
	movb	(%eax), %dl
	movb	%dl, (%ebx)
	incl	%ebx
	decl	%ecx
	jne	L1154
	movl	%esi, %edx
	jmp	L362
L1149:
	movl	%esi, %eax
	andl	$16, %eax
	testl	%eax, %eax
	je	L304
L302:
	addl	$16, %esi
	adcl	$0, %edi
	jmp	L304
L1137:
	leal	1(%esi), %eax
	leal	10224(%esp), %ecx
	cmpl	%eax, %ecx
	jbe	L1155
	movl	96(%esp), %edx
	leal	5233(%esp), %ecx
	subl	%esi, %edx
	xorl	%eax, %eax
	movl	%ecx, 72(%esp)
L413:
	movb	1(%esi,%eax), %bl
	movb	%bl, (%ecx,%eax)
	incl	%eax
	cmpl	%edx, %eax
	jne	L413
	addl	$2, %esi
	leal	10224(%esp), %ebx
	leal	10224(%esp), %eax
	movl	72(%esp), %ecx
	subl	%esi, %eax
	subl	%ebx, %esi
	movl	108(%esp), %ebx
	leal	1(%eax,%ecx), %edx
	leal	-1(%ebx,%esi), %ebx
	movl	%ebx, 108(%esp)
	jmp	L410
L240:
	leal	3(%eax), %ebx
	xorl	%edx, %edx
	movsbl	3(%eax), %eax
	movb	%al, %dl
	testb	$-128, %dl
	jne	L606
	testb	$8, ___dj_ctype_flags+2(%edx,%edx)
	movl	$0, %edx
	je	L241
	movl	%ecx, 152(%esp)
	jmp	L243
L1156:
	testb	$8, ___dj_ctype_flags+2(%ecx,%ecx)
	je	L1005
L243:
	leal	(%edx,%edx,4), %ebp
	xorl	%edx, %edx
	addl	%ebp, %ebp
	cmpb	$47, %al
	jle	L242
	movb	$9, %dl
	cmpb	$57, %al
	jg	L242
	leal	-48(%eax), %edx
L242:
	incl	%ebx
	addl	%ebp, %edx
	movsbl	(%ebx), %eax
	movb	%al, %cl
	andl	$255, %ecx
	testb	$-128, %cl
	je	L1156
L1005:
	movl	152(%esp), %ecx
L241:
	cmpl	%edx, 72(%esp)
	je	L1157
L244:
	movl	%ebx, %eax
	cmpl	%edx, %ecx
	jne	L949
	jmp	L1036
L125:
	leal	3(%eax), %ebx
	xorl	%edx, %edx
	movsbl	3(%eax), %eax
	movb	%al, %dl
	testb	$-128, %dl
	jne	L555
	testb	$8, ___dj_ctype_flags+2(%edx,%edx)
	movl	$0, %edx
	je	L126
	movl	%ecx, 128(%esp)
	jmp	L128
L1158:
	testb	$8, ___dj_ctype_flags+2(%ecx,%ecx)
	je	L971
L128:
	leal	(%edx,%edx,4), %ebp
	xorl	%edx, %edx
	addl	%ebp, %ebp
	cmpb	$47, %al
	jle	L127
	movb	$9, %dl
	cmpb	$57, %al
	jg	L127
	leal	-48(%eax), %edx
L127:
	incl	%ebx
	addl	%ebp, %edx
	movsbl	(%ebx), %eax
	movb	%al, %cl
	andl	$255, %ecx
	testb	$-128, %cl
	je	L1158
L971:
	movl	128(%esp), %ecx
L126:
	cmpl	%edx, 96(%esp)
	je	L1159
L686:
	movl	%ebx, %eax
	cmpl	%edx, %ecx
	jne	L947
	jmp	L1028
L644:
	leal	5233(%esp), %edx
	movl	%edx, 72(%esp)
	movl	%edx, %ebx
	jmp	L346
	.p2align 4,,7
L656:
	movb	$57, %cl
	cmpl	$1, %edi
	movb	%cl, -1(%ebp)
	jne	L420
L1139:
	testl	%eax, %eax
	jne	L420
	incl	%ebp
	jmp	L417
L398:
	movl	96(%esp), %ebx
	addl	$48, %ecx
	movb	$48, (%ebx)
	movb	%cl, 1(%ebx)
	addl	$2, %ebx
	movl	%ebx, 96(%esp)
L402:
	movl	96(%esp), %eax
	subl	%esi, %eax
	movl	%eax, 96(%esp)
	jmp	L326
L1147:
	leal	-1(%ebx), %eax
	testl	%edx, %edx
	js	L654
	addl	$48, %ecx
L401:
	movb	%cl, -1(%ebx)
	cmpl	92(%esp), %eax
	jae	L402
	movl	96(%esp), %edx
	jmp	L404
	.p2align 4,,7
L403:
	movb	(%eax), %cl
L404:
	incl	%eax
	movb	%cl, (%edx)
	incl	%edx
	cmpl	92(%esp), %eax
	jne	L403
	movl	72(%esp), %eax
	movl	96(%esp), %edx
	subl	%ebx, %eax
	addl	%eax, %edx
	movl	%edx, 96(%esp)
	jmp	L402
L538:
	movl	$-1, 120(%esp)
	jmp	L707
L1141:
	testb	$64, 100(%esp)
	je	L1160
	fldz
	movb	_decimal_point, %al
	fldt	80(%esp)
	movb	%al, (%ebx)
	fucompp
	fnstsw	%ax
	andb	$69, %ah
	incl	%ebx
	xorb	$64, %ah
	je	L537
L534:
	fldt	80(%esp)
	leal	187(%esp), %eax
	leal	-1(%ebx), %ecx
	fstpt	(%esp)
	movl	%eax, 16(%esp)
	movl	$0, 12(%esp)
	movl	72(%esp), %edx
	xorl	%eax, %eax
	call	_doprnt_roundl
L352:
	subl	%eax, %ebx
	movl	%ebx, 96(%esp)
	jmp	L326
L405:
	movl	152(%esp), %edx
	xorl	$1, %edx
	movl	%edx, 108(%esp)
	jmp	L406
L705:
	fldz
	fldt	80(%esp)
	fucom	%st(1)
	fnstsw	%ax
	fstp	%st(1)
	andb	$69, %ah
	movl	%ebx, 108(%esp)
	movl	156(%esp), %ebp
	movl	%ecx, %ebx
	movl	%ecx, %esi
	movl	72(%esp), %edx
	cmpb	$64, %ah
	jne	L1161
	fstp	%st(0)
L424:
	movl	152(%esp), %edi
	testl	%edi, %edi
	jne	L1162
	movl	96(%esp), %eax
	testl	%eax, %eax
	je	L1042
	cmpl	%ebx, %edx
	jae	L1041
	movb	-1(%esi), %al
	decl	%ebx
	cmpb	$48, %al
	jne	L430
L829:
	cmpl	%edx, %ebx
	je	L1041
	decl	%ebx
	movb	(%ebx), %al
	cmpb	$48, %al
	je	L829
L430:
	cmpb	_decimal_point, %al
	je	L1042
	incl	%ebx
L1042:
	subl	%edx, %ebx
	movl	%ebx, 96(%esp)
	jmp	L326
L296:
	addl	$_INF_REP.3484, %eax
	leal	5232(%esp), %ecx
	movl	%eax, 4(%esp)
	movl	%ecx, (%esp)
	call	_strcpy
	jmp	L294
L1142:
	movl	108(%esp), %eax
	movl	188(%esp), %ecx
	decl	%eax
	jmp	L380
L1153:
	movl	%ecx, 108(%esp)
	movl	%esi, %edx
L364:
	leal	5233(%esp), %ecx
	movl	%ecx, 72(%esp)
	movl	%ecx, %esi
	jmp	L530
L565:
	movl	$0, 108(%esp)
	jmp	L147
L628:
	movl	%edx, %ecx
	jmp	L307
L1118:
	movl	$-1, 108(%esp)
	jmp	L201
L1146:
	movb	$45, 1(%ebx)
	addl	$2, %ebx
	negl	%ecx
	movl	%ebx, 96(%esp)
	jmp	L397
L537:
	movl	108(%esp), %eax
	movl	108(%esp), %edi
	decl	%eax
	testl	%edi, %edi
	je	L647
L351:
	leal	1(%ebx,%eax), %eax
	.p2align 4,,7
L357:
	movb	$48, (%ebx)
	incl	%ebx
	cmpl	%eax, %ebx
	jne	L357
	movl	72(%esp), %esi
	subl	%esi, %ebx
	movl	%ebx, 96(%esp)
	jmp	L326
L1143:
	leal	224(%esp), %ecx
	movl	108(%esp), %edi
	jmp	L384
L1164:
	leal	48(%edx), %eax
L382:
	movb	%al, (%ebx)
	incl	%ebx
	decl	%edi
	je	L383
	fldz
	fldt	80(%esp)
	fucompp
	fnstsw	%ax
	andb	$69, %ah
	xorb	$64, %ah
	je	L1163
L384:
	fldt	80(%esp)
	fmuls	LC4
	movl	%ecx, 12(%esp)
	movl	%ecx, 68(%esp)
	fstpt	(%esp)
	call	___modfl
	movl	68(%esp), %ecx
	fnstcw	174(%esp)
	movw	174(%esp), %ax
	fstpt	80(%esp)
	movb	$12, %ah
	movw	%ax, 172(%esp)
	movb	$57, %al
	fldt	224(%esp)
	fldcw	172(%esp)
	fistpl	168(%esp)
	fldcw	174(%esp)
	movl	168(%esp), %edx
	cmpl	$9, %edx
	jg	L382
	testl	%edx, %edx
	jns	L1164
	movb	$48, %al
	jmp	L382
L1163:
	movl	%edi, %eax
	movl	%edi, 108(%esp)
	movl	188(%esp), %ecx
	decl	%eax
	jmp	L385
L1117:
	leal	1(%esi), %eax
	movl	%eax, 124(%esp)
	decl	%eax
	je	L571
	movl	10256(%esp), %edx
	movl	10260(%esp), %ecx
	movl	%ecx, 116(%esp)
	xorl	%ebx, %ebx
	movb	(%edx), %dl
	movl	10256(%esp), %ecx
	movb	%dl, 108(%esp)
	movl	%edi, 96(%esp)
	movl	$1, %edx
	movl	%ebp, 104(%esp)
L154:
	movsbl	108(%esp), %eax
	testl	%eax, %eax
	jne	L1029
	jmp	L590
	.p2align 4,,7
L833:
	incl	%ecx
	movsbl	(%ecx), %eax
	testl	%eax, %eax
	je	L590
L1029:
	cmpl	$37, %eax
	jne	L833
	movl	%ecx, %eax
L155:
	movl	$0, 72(%esp)
L948:
	leal	1(%eax), %ecx
	movl	%ecx, 148(%esp)
	movb	1(%eax), %cl
	movb	%cl, 108(%esp)
	cmpb	$122, %cl
	ja	L983
	andl	$255, %ecx
	jmp	*L174(,%ecx,4)
	.p2align 2
	.p2align 2
L174:
	.long	L997
	.long	L983
	.long	L983
	.long	L983
	.long	L983
	.long	L983
	.long	L983
	.long	L983
	.long	L983
	.long	L983
	.long	L983
	.long	L983
	.long	L983
	.long	L983
	.long	L983
	.long	L983
	.long	L983
	.long	L983
	.long	L983
	.long	L983
	.long	L983
	.long	L983
	.long	L983
	.long	L983
	.long	L983
	.long	L983
	.long	L983
	.long	L983
	.long	L983
	.long	L983
	.long	L983
	.long	L983
	.long	L1030
	.long	L983
	.long	L983
	.long	L1030
	.long	L983
	.long	L983
	.long	L983
	.long	L1030
	.long	L983
	.long	L983
	.long	L161
	.long	L1030
	.long	L983
	.long	L1030
	.long	L162
	.long	L983
	.long	L163
	.long	L163
	.long	L163
	.long	L163
	.long	L163
	.long	L163
	.long	L163
	.long	L163
	.long	L163
	.long	L163
	.long	L983
	.long	L983
	.long	L983
	.long	L983
	.long	L983
	.long	L983
	.long	L983
	.long	L164
	.long	L983
	.long	L983
	.long	L167
	.long	L164
	.long	L164
	.long	L164
	.long	L983
	.long	L983
	.long	L983
	.long	L983
	.long	L170
	.long	L983
	.long	L983
	.long	L167
	.long	L983
	.long	L983
	.long	L983
	.long	L983
	.long	L983
	.long	L167
	.long	L983
	.long	L983
	.long	L167
	.long	L983
	.long	L983
	.long	L983
	.long	L983
	.long	L983
	.long	L983
	.long	L983
	.long	L983
	.long	L164
	.long	L983
	.long	L172
	.long	L986
	.long	L164
	.long	L164
	.long	L164
	.long	L1030
	.long	L986
	.long	L170
	.long	L983
	.long	L171
	.long	L983
	.long	L172
	.long	L986
	.long	L172
	.long	L983
	.long	L983
	.long	L172
	.long	L1030
	.long	L986
	.long	L983
	.long	L983
	.long	L986
	.long	L983
	.long	L1030
L170:
	orl	$2, 72(%esp)
	movl	148(%esp), %eax
	jmp	L948
L167:
	orl	$1, 72(%esp)
	movl	148(%esp), %ecx
L173:
	cmpl	%esi, %edx
	je	L1165
L697:
	cmpl	%ebx, %edx
	je	L1166
L160:
	cmpl	%edx, 124(%esp)
	jg	L154
L997:
	movl	96(%esp), %edi
	movl	104(%esp), %ebp
L153:
	movl	128(%esp), %esi
	movl	$1, 124(%esp)
	movl	%esi, %edx
	movb	1(%esi), %bl
	jmp	L152
L172:
	movl	148(%esp), %ecx
	cmpl	%esi, %edx
	je	L1167
L698:
	cmpl	%ebx, %edx
	jne	L160
L196:
	movl	116(%esp), %ebx
	addl	$4, %ebx
	movl	%ebx, 116(%esp)
L197:
	movl	%edx, %ebx
	incl	%edx
	jmp	L160
L986:
	movl	148(%esp), %ecx
	jmp	L173
L983:
	movl	148(%esp), %ecx
	jmp	L160
L171:
	testb	$1, 72(%esp)
	jne	L170
	orl	$1, 72(%esp)
L1030:
	movl	148(%esp), %eax
	jmp	L948
L162:
	cmpb	$42, 2(%eax)
	je	L180
	addl	$2, %eax
	jmp	L948
L161:
	leal	2(%eax), %edi
	xorl	%ecx, %ecx
	movsbl	2(%eax), %eax
	movb	%al, %cl
	testb	$-128, %cl
	jne	L577
	testb	$8, ___dj_ctype_flags+2(%ecx,%ecx)
	movl	$0, %ecx
	je	L176
	movl	%edx, 108(%esp)
	jmp	L178
L1168:
	testb	$8, ___dj_ctype_flags+2(%edx,%edx)
	je	L988
L178:
	leal	(%ecx,%ecx,4), %ebp
	xorl	%ecx, %ecx
	addl	%ebp, %ebp
	cmpb	$47, %al
	jle	L177
	movb	$9, %cl
	cmpb	$57, %al
	jg	L177
	leal	-48(%eax), %ecx
L177:
	incl	%edi
	addl	%ebp, %ecx
	movsbl	(%edi), %eax
	movb	%al, %dl
	andl	$255, %edx
	testb	$-128, %dl
	je	L1168
L988:
	movl	108(%esp), %edx
L176:
	cmpl	%ecx, %esi
	je	L1169
L692:
	movl	%edi, %eax
	cmpl	%edx, %ecx
	jne	L948
L1031:
	movl	116(%esp), %ecx
	incl	%edx
	addl	$4, %ecx
	movl	%ecx, 116(%esp)
	jmp	L948
L164:
	movl	148(%esp), %ecx
	cmpl	%esi, %edx
	je	L1170
L696:
	cmpl	%ebx, %edx
	jne	L160
	testb	$2, 72(%esp)
	je	L1052
	movl	116(%esp), %ebp
	addl	$12, %ebp
	movl	%ebp, 116(%esp)
	jmp	L197
	.p2align 4,,7
L163:
	movsbl	108(%esp), %eax
	xorl	%ebx, %ebx
	testb	$8, ___dj_ctype_flags+2(%eax,%eax)
	je	L1030
	movl	148(%esp), %ecx
	movl	%edx, 152(%esp)
	movsbl	108(%esp), %eax
	jmp	L832
L1171:
	testb	$8, ___dj_ctype_flags+2(%edx,%edx)
	je	L589
L832:
	leal	(%ebx,%ebx,4), %edi
	xorl	%ebx, %ebx
	addl	%edi, %edi
	cmpb	$47, %al
	jle	L185
	movb	$9, %bl
	cmpb	$57, %al
	jg	L185
	leal	-48(%eax), %ebx
L185:
	incl	%ecx
	addl	%edi, %ebx
	movsbl	(%ecx), %eax
	movb	%al, %dl
	andl	$255, %edx
	testb	$-128, %dl
	je	L1171
L589:
	movl	152(%esp), %edx
	movl	%ecx, %eax
	jmp	L948
L590:
	movl	10256(%esp), %eax
	jmp	L155
L1162:
	movl	108(%esp), %eax
	movl	108(%esp), %ecx
	addl	%ebx, %eax
	testl	%ecx, %ecx
	je	L1042
L828:
	movb	$48, (%ebx)
	incl	%ebx
	cmpl	%eax, %ebx
	jne	L828
	jmp	L1042
L1138:
	movl	100(%esp), %ebx
	andl	$64, %ebx
	movl	%ebx, 152(%esp)
	jmp	L415
L375:
	leal	5233(%esp), %edx
	movb	_decimal_point, %al
	movb	%al, 5234(%esp)
	leal	5235(%esp), %ebx
	movl	%edx, 72(%esp)
	movl	%edx, %esi
	jmp	L365
L1044:
	movb	(%ebx), %dl
	jmp	L498
L377:
	movb	_decimal_point, %cl
	movl	108(%esp), %eax
	movb	%cl, 5234(%esp)
	decl	%eax
	leal	5235(%esp), %ebx
	jmp	L378
L1166:
	testb	$2, 72(%esp)
	je	L196
L1052:
	movl	116(%esp), %edi
	addl	$8, %edi
	movl	%edi, 116(%esp)
	jmp	L197
L624:
	movl	$3, 96(%esp)
	jmp	L297
L1038:
	movb	-1(%ecx), %al
	jmp	L311
L568:
	movb	%bl, %al
	xorl	%esi, %esi
	jmp	L149
L654:
	movb	$48, %cl
	jmp	L401
L1161:
	fstpt	(%esp)
	leal	187(%esp), %eax
	leal	-1(%ecx), %ecx
	movl	%eax, 16(%esp)
	movl	$0, 12(%esp)
	xorl	%eax, %eax
	call	_doprnt_roundl
	movl	%eax, %edx
	jmp	L424
L675:
	leal	10224(%esp), %ebx
	jmp	L494
L531:
	leal	5233(%esp), %edx
	leal	-1(%ebx), %ecx
	movl	%edx, 72(%esp)
	leal	187(%esp), %edx
	movl	%edx, 16(%esp)
	movl	72(%esp), %edx
	movsbl	1(%eax), %eax
	movl	$0, (%esp)
	movl	%eax, 12(%esp)
	movl	$0, 4(%esp)
	movl	$0, 8(%esp)
	leal	188(%esp), %eax
	call	_doprnt_roundl
	movl	188(%esp), %edx
	fldz
	movl	%eax, %esi
	movl	$0, 108(%esp)
	fstpt	80(%esp)
	jmp	L530
L649:
	movb	$48, %al
	jmp	L374
L180:
	leal	3(%eax), %edi
	xorl	%ecx, %ecx
	movsbl	3(%eax), %eax
	movb	%al, %cl
	testb	$-128, %cl
	jne	L582
	testb	$8, ___dj_ctype_flags+2(%ecx,%ecx)
	movl	$0, %ecx
	je	L181
	movl	%edx, 108(%esp)
	jmp	L183
L1172:
	testb	$8, ___dj_ctype_flags+2(%edx,%edx)
	je	L990
L183:
	leal	(%ecx,%ecx,4), %ebp
	xorl	%ecx, %ecx
	addl	%ebp, %ebp
	cmpb	$47, %al
	jle	L182
	movb	$9, %cl
	cmpb	$57, %al
	jg	L182
	leal	-48(%eax), %ecx
L182:
	incl	%edi
	addl	%ebp, %ecx
	movsbl	(%edi), %eax
	movb	%al, %dl
	andl	$255, %edx
	testb	$-128, %dl
	je	L1172
L990:
	movl	108(%esp), %edx
L181:
	cmpl	%ecx, %esi
	je	L1173
L693:
	movl	%edi, %eax
	cmpl	%ecx, %edx
	jne	L948
	jmp	L1031
	.p2align 4,,7
L1145:
	movb	(%eax), %dl
	jmp	L391
L582:
	xorl	%ecx, %ecx
	jmp	L181
L1169:
	cmpl	%edx, %esi
	jne	L692
	jmp	L997
L1127:
	cmpl	%esi, 72(%esp)
	jne	L259
	jmp	L1026
L1125:
	cmpl	%esi, 72(%esp)
	jne	L255
	jmp	L1026
L1124:
	cmpl	%esi, 96(%esp)
	jne	L691
	jmp	L978
L1122:
	cmpl	%esi, 96(%esp)
	jne	L690
	jmp	L978
L1041:
	movb	(%ebx), %al
	jmp	L430
L544:
	movl	10260(%esp), %ebx
	movl	%ebx, 116(%esp)
	jmp	L98
L1170:
	cmpl	%esi, %ebx
	jne	L696
	jmp	L997
L1152:
	leal	5233(%esp), %edx
	movl	188(%esp), %ecx
	leal	5234(%esp), %ebx
	movl	%edx, 72(%esp)
	movl	%edx, %esi
	jmp	L387
L419:
	movb	$48, -1(%ebp)
	jmp	L420
L1129:
	cmpl	%ecx, 96(%esp)
	jne	L685
	jmp	L978
L1135:
	cmpl	%esi, 72(%esp)
	jne	L252
	jmp	L1026
L1157:
	cmpl	%ecx, 72(%esp)
	jne	L244
	jmp	L1026
L606:
	xorl	%edx, %edx
	jmp	L241
L555:
	xorl	%edx, %edx
	jmp	L126
L1132:
	cmpl	%esi, 96(%esp)
	jne	L689
	jmp	L978
L601:
	xorl	%edx, %edx
	jmp	L236
L1115:
	movl	%ebx, 72(%esp)
	jmp	L535
L1159:
	cmpl	%ecx, 96(%esp)
	jne	L686
	jmp	L978
L1160:
	fldz
	fldt	80(%esp)
	fucompp
	fnstsw	%ax
	andb	$69, %ah
	xorb	$64, %ah
	jne	L534
L647:
	movl	72(%esp), %eax
	jmp	L352
	.p2align 4,,7
L646:
	movb	$48, %al
	jmp	L353
L354:
	fldt	80(%esp)
	fucompp
	fnstsw	%ax
	andb	$69, %ah
	cmpb	$64, %ah
	jne	L534
	jmp	L647
L1131:
	cmpl	%ecx, 72(%esp)
	jne	L239
	jmp	L1026
L1155:
	leal	5233(%esp), %edx
	movl	%edx, 72(%esp)
	jmp	L410
L1119:
	movb	2(%esi), %bl
	movl	10260(%esp), %esi
	movl	%esi, 132(%esp)
	movl	$1, 124(%esp)
	jmp	L951
L1144:
	movb	(%ebx), %dl
	movl	%ebx, %eax
	jmp	L391
L550:
	xorl	%edx, %edx
	jmp	L121
L1173:
	cmpl	%edx, %esi
	jne	L693
	jmp	L997
L682:
	movl	100(%esp), %esi
	movl	%esi, 80(%esp)
	movl	128(%esp), %esi
	movl	%esi, 116(%esp)
	xorl	%esi, %esi
	jmp	L486
L571:
	movl	10260(%esp), %ecx
	movl	%ecx, 116(%esp)
	jmp	L153
L638:
	leal	10223(%esp), %edx
	movl	%edx, 96(%esp)
	movl	%edx, %esi
	jmp	L327
L300:
	testb	%cl, %cl
	je	L297
	movl	140(%esp), %edx
	movl	136(%esp), %eax
	shrdl	$3, %edx, %eax
	shrl	$3, %edx
	movl	%eax, 136(%esp)
	movl	%edx, 140(%esp)
	jmp	L297
L1165:
	cmpl	%esi, %ebx
	jne	L697
	jmp	L997
L577:
	xorl	%ecx, %ecx
	jmp	L176
L1167:
	cmpl	%esi, %ebx
	jne	L698
	jmp	L997
	.cfi_endproc
LFE10:
.lcomm _decimal_point,1,1
.lcomm _thousands_sep,1,1
.lcomm _grouping,4,4
	.section .data
_NULL_REP:
	.ascii "(null)\0"
	.section .text
	.p2align 4
_UPPER_DIGITS:
	.ascii "0123456789ABCDEF\0"
	.p2align 4
_LOWER_DIGITS:
	.ascii "0123456789abcdef\0"
	.p2align 4
_powten:
	.long	0
	.long	-1610612736
	.long	16386
	.long	0
	.long	-939524096
	.long	16389
	.long	0
	.long	-1673527296
	.long	16396
	.long	0
	.long	-1094967296
	.long	16409
	.long	67108864
	.long	-1910781505
	.long	16436
	.long	728806814
	.long	-1647989336
	.long	16489
	.long	-3168555
	.long	-1032315063
	.long	16595
	.long	-2132177696
	.long	-1816508471
	.long	16808
	.long	-1644568946
	.long	-1434522629
	.long	17233
	.long	-1508994617
	.long	-484859730
	.long	18083
	.long	-2123035625
	.long	-914983546
	.long	19784
	.long	-985834011
	.long	-1635042467
	.long	23186
	.long	-1977575525
	.long	-1000320510
	.long	29989
	.p2align 4
_powtenneg:
	.long	-858993459
	.long	-858993460
	.long	16379
	.long	1889785610
	.long	-1546188227
	.long	16376
	.long	-501652180
	.long	-776530088
	.long	16369
	.long	-2073964803
	.long	-1412663535
	.long	16356
	.long	-1001528997
	.long	-426404674
	.long	16329
	.long	1161401530
	.long	-810475859
	.long	16276
	.long	-1522931291
	.long	-1468011993
	.long	16170
	.long	1690100897
	.long	-573553028
	.long	15957
	.long	1668946234
	.long	-1070513371
	.long	15532
	.long	-618409444
	.long	-1874203086
	.long	14682
	.long	-631783234
	.long	-1566145883
	.long	12981
	.long	875965924
	.long	-827436209
	.long	9579
	.long	-758210594
	.long	-1495464760
	.long	2776
_NAN_REP.3485:
	.ascii "nan\0"
	.ascii "NAN\0"
_INF_REP.3484:
	.ascii "inf\0"
	.ascii "INF\0"
	.p2align 2
LC1:
	.long	1091567616
	.p2align 2
LC2:
	.long	1056964608
	.p2align 2
LC4:
	.long	1092616192
	.p2align 2
LC5:
	.long	1082130432
	.p2align 2
LC8:
	.long	1610612736
	.p2align 2
LC9:
	.long	520093696
	.p2align 3
LC10:
	.long	-350469331
	.long	1058682594
	.ident	"GCC: (GNU) 4.7.4"
