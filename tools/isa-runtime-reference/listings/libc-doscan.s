	.file	"doscan.c"
	.section .text
	.p2align 4,,15
__getccl:
LFB12:
	.cfi_startproc
	pushl	%esi
	.cfi_def_cfa_offset 8
	.cfi_offset 6, -8
	pushl	%ebx
	.cfi_def_cfa_offset 12
	.cfi_offset 3, -12
	movb	(%eax), %bl
	xorl	%ecx, %ecx
	cmpb	$94, %bl
	je	L35
L2:
	xorl	%edx, %edx
	jmp	L5
	.p2align 4,,7
L37:
	andb	$-3, __sctab(%edx)
	incl	%edx
	cmpl	$256, %edx
	je	L36
L5:
	testl	%ecx, %ecx
	jne	L37
	orb	$2, __sctab(%edx)
	incl	%edx
	cmpl	$256, %edx
	jne	L5
L36:
	xorl	%edx, %edx
	movb	%bl, %dl
	cmpl	$93, %edx
	je	L6
	cmpl	$45, %edx
	jne	L30
	jmp	L6
	.p2align 4,,7
L39:
	orb	$2, __sctab(%edx)
L14:
	movb	(%esi), %bl
	movl	%esi, %eax
L30:
	xorl	%edx, %edx
	leal	1(%eax), %esi
	movb	%bl, %dl
	cmpl	$93, %edx
	je	L11
	testl	%edx, %edx
	je	L22
	cmpl	$45, %edx
	je	L38
L12:
	testl	%ecx, %ecx
	jne	L39
	andb	$-3, __sctab(%edx)
	jmp	L14
	.p2align 4,,7
L38:
	movb	(%esi), %bl
	cmpb	$93, %bl
	je	L12
	movb	-2(%esi), %al
	cmpb	%al, %bl
	jbe	L12
	andl	$255, %eax
	andl	$255, %ebx
	leal	1(%eax), %edx
	cmpl	%ebx, %edx
	jb	L27
	jmp	L14
	.p2align 4,,7
L40:
	orb	$2, __sctab(%eax)
L16:
	incl	%edx
	cmpl	%ebx, %edx
	jae	L14
L27:
	movzbl	%dl, %eax
	testl	%ecx, %ecx
	jne	L40
	andb	$-3, __sctab(%eax)
	jmp	L16
L22:
	movl	%eax, %esi
L11:
	movl	%esi, %eax
	popl	%ebx
	.cfi_remember_state
	.cfi_restore 3
	.cfi_def_cfa_offset 8
	popl	%esi
	.cfi_restore 6
	.cfi_def_cfa_offset 4
	ret
L35:
	.cfi_restore_state
	movb	1(%eax), %bl
	movb	$1, %cl
	incl	%eax
	jmp	L2
L6:
	testl	%ecx, %ecx
	je	L8
	orb	$2, __sctab(%edx)
L9:
	movb	1(%eax), %bl
	incl	%eax
	jmp	L30
L8:
	andb	$-3, __sctab(%edx)
	jmp	L9
	.cfi_endproc
LFE12:
	.p2align 4,,15
	.globl	__doscan_low
__doscan_low:
LFB9:
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
	subl	$204, %esp
	.cfi_def_cfa_offset 224
	movl	_errno, %edx
	movl	236(%esp), %edi
	movl	%edx, 96(%esp)
	call	_localeconv
	movl	240(%esp), %esi
	leal	128(%esp), %ecx
	movl	$0, _nchars
	movl	4(%eax), %eax
	movl	$0, 88(%esp)
	movl	$0, 56(%esp)
	movl	%ecx, 32(%esp)
	movb	(%eax), %al
	movl	%esi, %ebp
	movb	%al, _decimal_point
	movl	$0, _errno
L290:
	movsbl	(%edi), %edx
	leal	1(%edi), %ebx
	cmpb	$37, %dl
	jbe	L313
L43:
	movl	%ebx, %edi
L48:
	movl	224(%esp), %ecx
	movl	%edx, 28(%esp)
	movl	%ecx, (%esp)
	movl	228(%esp), %ecx
	call	*%ecx
	movl	28(%esp), %edx
	cmpl	$-1, %eax
	je	L143
	movl	_nchars, %esi
	incl	%esi
	movl	%esi, _nchars
L143:
	cmpl	%edx, %eax
	je	L290
	cmpl	$-1, %eax
	jne	L144
	movl	56(%esp), %eax
	orl	88(%esp), %eax
	jne	L210
L312:
	movl	$-1, 56(%esp)
L210:
	movl	56(%esp), %eax
	addl	$204, %esp
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
L313:
	.cfi_restore_state
	xorl	%eax, %eax
	movb	%dl, %al
	jmp	*L47(,%eax,4)
	.p2align 2
	.p2align 2
L47:
	.long	L210
	.long	L43
	.long	L43
	.long	L43
	.long	L43
	.long	L43
	.long	L43
	.long	L43
	.long	L43
	.long	L294
	.long	L294
	.long	L294
	.long	L294
	.long	L294
	.long	L43
	.long	L43
	.long	L43
	.long	L43
	.long	L43
	.long	L43
	.long	L43
	.long	L43
	.long	L43
	.long	L43
	.long	L43
	.long	L43
	.long	L43
	.long	L43
	.long	L43
	.long	L43
	.long	L43
	.long	L43
	.long	L294
	.long	L43
	.long	L43
	.long	L43
	.long	L43
	.long	L46
L46:
	movsbl	1(%edi), %edx
	addl	$2, %edi
	cmpl	$37, %edx
	je	L48
L49:
	movl	$1, %eax
	xorl	%ebx, %ebx
	movl	240(%esp), %esi
	testl	%eax, %eax
	je	L50
	.p2align 4,,7
L315:
	cmpl	$42, %edx
	je	L50
	movzbl	%dl, %eax
	movl	0(%ebp), %ebx
	addl	$4, %ebp
	testb	$8, ___dj_ctype_flags+2(%eax,%eax)
	je	L52
L316:
	xorl	%eax, %eax
	.p2align 4,,7
L53:
	leal	(%eax,%eax,4), %eax
	leal	-48(%edx,%eax,2), %eax
	movsbl	(%edi), %edx
	movzbl	%dl, %ecx
	incl	%edi
	testb	$8, ___dj_ctype_flags+2(%ecx,%ecx)
	jne	L53
	cmpl	$36, %edx
	jne	L54
	movl	%esi, %ebp
	testl	%eax, %eax
	jg	L314
L55:
	xorl	%eax, %eax
	movl	$36, %edx
	testl	%eax, %eax
	jne	L315
L50:
	movsbl	(%edi), %edx
	movzbl	%dl, %eax
	incl	%edi
	testb	$8, ___dj_ctype_flags+2(%eax,%eax)
	jne	L316
L52:
	cmpl	$36, %edx
	jne	L317
	movl	%esi, %ebp
	jmp	L55
	.p2align 4,,7
L314:
	xorb	%dl, %dl
L56:
	movl	(%esi,%edx,4), %ebx
	incl	%edx
	cmpl	%eax, %edx
	jne	L56
	leal	(%esi,%edx,4), %ebp
	jmp	L55
L54:
	movl	%ebx, 100(%esp)
	movl	%eax, 36(%esp)
	testl	%eax, %eax
	je	L151
	cmpl	$108, %edx
	je	L318
L58:
	cmpl	$104, %edx
	je	L319
	cmpl	$76, %edx
	je	L311
	cmpl	$106, %edx
	je	L311
	cmpl	$122, %edx
	je	L320
	cmpl	$116, %edx
	je	L321
	cmpl	$109, %edx
	je	L322
	cmpl	$91, %edx
	je	L69
	movzbl	%dl, %eax
	incl	%eax
	movl	$0, 80(%esp)
	movl	$2, 52(%esp)
	jmp	L60
L294:
	movl	224(%esp), %esi
	movl	228(%esp), %edi
	.p2align 4,,7
L244:
	movl	_nchars, %eax
	movl	%esi, (%esp)
	incl	%eax
	movl	%eax, _nchars
	call	*%edi
	cmpl	$-1, %eax
	je	L141
	movzbl	%al, %edx
	testb	$1, __sctab(%edx)
	jne	L244
	movl	224(%esp), %edx
	movl	%eax, (%esp)
	movl	%edx, 4(%esp)
	movl	232(%esp), %ecx
	call	*%ecx
L141:
	movl	_nchars, %edi
	decl	%edi
	movl	%edi, _nchars
	movl	%ebx, %edi
	jmp	L290
L317:
	movl	%ebx, 100(%esp)
L151:
	movl	$30000, 36(%esp)
	cmpl	$108, %edx
	jne	L58
L318:
	movsbl	(%edi), %edx
	cmpl	$108, %edx
	je	L59
L310:
	movzbl	%dl, %eax
	incl	%edi
	incl	%eax
	movl	$0, 80(%esp)
	movl	$4, 52(%esp)
L60:
	testb	$2, ___dj_ctype_flags+1(%eax,%eax)
	je	L70
	addl	$32, %edx
	cmpl	$105, %edx
	je	L71
	cmpl	$100, %edx
	je	L71
	cmpl	$117, %edx
	je	L71
	cmpl	$111, %edx
	je	L71
L70:
	testl	%edx, %edx
	je	L312
	cmpl	$110, %edx
	jne	L74
	testl	%ebx, %ebx
	je	L290
	cmpl	$4, 52(%esp)
	je	L79
	movl	52(%esp), %eax
	testl	%eax, %eax
	je	L323
	cmpl	$1, 52(%esp)
	je	L324
	cmpl	$8, 52(%esp)
	je	L325
L79:
	movl	_nchars, %eax
	movl	%eax, (%ebx)
	jmp	L290
L71:
	cmpl	$4, 52(%esp)
	je	L154
	cmpl	$8, 52(%esp)
	je	L70
	movl	$4, 52(%esp)
	jmp	L70
L74:
	movl	%edx, %eax
	andl	$-17, %eax
	cmpl	$99, %eax
	je	L80
	cmpl	$91, %edx
	je	L326
	movl	%edx, %ecx
	movl	%edx, %eax
	andl	$-9, %ecx
	andl	$-5, %eax
	movl	%ecx, 84(%esp)
	movl	$1, 120(%esp)
	cmpl	$97, %eax
	jne	L327
	cmpl	$111, %edx
	je	L165
L335:
	movl	$16, 48(%esp)
	cmpl	$112, 84(%esp)
	je	L296
	cmpl	$97, %edx
	movl	%ebp, 40(%esp)
	sete	%cl
	andl	$255, %ecx
	movl	%edx, 60(%esp)
	decl	%ecx
	movl	224(%esp), %esi
	andl	$-6, %ecx
	movl	228(%esp), %ebp
	addl	$16, %ecx
	movl	%ecx, 48(%esp)
	.p2align 4,,7
L245:
	movl	_nchars, %eax
	movl	%esi, (%esp)
	incl	%eax
	movl	%eax, _nchars
	call	*%ebp
	cmpl	$-1, %eax
	je	L102
	movzbl	%al, %edx
	testb	$1, __sctab(%edx)
	jne	L245
	movl	40(%esp), %ebp
	movl	60(%esp), %edx
	cmpl	$45, %eax
	je	L328
	cmpl	$43, %eax
	je	L329
	movl	$0, 116(%esp)
	leal	128(%esp), %esi
L105:
	movl	36(%esp), %ecx
	testl	%ecx, %ecx
	jle	L169
	movl	120(%esp), %ecx
	movl	%ebx, 104(%esp)
	xorl	$1, %ecx
	movl	%esi, %ebx
	andl	$1, %ecx
	movl	%edi, 108(%esp)
	movl	$0, 64(%esp)
	movl	$0, 60(%esp)
	movl	$0, 40(%esp)
	movl	$0, 44(%esp)
	movl	$0, 72(%esp)
	movb	%cl, 115(%esp)
	movl	%ebp, 92(%esp)
	movl	%edx, 68(%esp)
	movl	224(%esp), %esi
	xorl	%edi, %edi
	jmp	L123
L332:
	leal	-47(%eax), %ecx
	cmpl	48(%esp), %ecx
	jg	L112
	movl	60(%esp), %edx
	incl	%edx
	movl	%edx, 60(%esp)
	cmpl	$8, 48(%esp)
	je	L330
	cmpl	$10, 48(%esp)
	jne	L118
	movl	40(%esp), %edx
	movl	44(%esp), %ecx
	shldl	$2, %edx, %ecx
	sall	$2, %edx
	movl	%ecx, 76(%esp)
	movl	%edx, 72(%esp)
	movl	40(%esp), %edx
	addl	%edx, 72(%esp)
	movl	44(%esp), %ecx
	adcl	%ecx, 76(%esp)
	movl	72(%esp), %edx
	movl	76(%esp), %ecx
	shldl	$1, %edx, %ecx
	addl	%edx, %edx
	movl	%ecx, 76(%esp)
	movl	%edx, 72(%esp)
L117:
	leal	-48(%eax), %edx
L120:
	movl	%edx, 40(%esp)
	movl	%edx, %ecx
	sarl	$31, %ecx
	movl	72(%esp), %edx
	addl	%edx, 40(%esp)
	movl	%ecx, 44(%esp)
	movl	76(%esp), %ecx
	adcl	%ecx, 44(%esp)
L110:
	movb	%al, (%ebx)
	movl	228(%esp), %edx
	movl	%esi, (%esp)
	incl	%ebx
	call	*%edx
	movl	_nchars, %ecx
	incl	%ecx
	cmpl	36(%esp), %edi
	movl	%ecx, _nchars
	je	L304
L123:
	incl	%edi
	cmpl	$48, %eax
	jne	L107
	cmpl	$1, %edi
	jne	L107
	cmpl	$105, 68(%esp)
	je	L331
L107:
	movl	%eax, %ebp
	andl	$-33, %ebp
	cmpl	$88, %ebp
	jne	L108
	cmpl	$97, 84(%esp)
	je	L109
	cmpl	$120, 68(%esp)
	je	L109
	.p2align 4,,7
L108:
	cmpl	$-1, %eax
	je	L112
	movzbl	%al, %edx
	movw	___dj_ctype_flags+2(%edx,%edx), %dx
	andl	$8, %edx
	movw	%dx, 26(%esp)
	jne	L332
L112:
	cmpl	$16, 48(%esp)
	je	L333
L114:
	movsbl	_decimal_point, %edx
	cmpl	%edx, %eax
	je	L334
	cmpl	$69, %ebp
	jne	L304
	movl	64(%esp), %ecx
	testl	%ecx, %ecx
	jne	L304
	cmpl	$8, 48(%esp)
	je	L304
	cmpb	$0, 115(%esp)
	jne	L304
	movl	60(%esp), %edx
	testl	%edx, %edx
	je	L304
	movb	%al, (%ebx)
	movl	228(%esp), %ecx
	movl	%esi, (%esp)
	incl	%ebx
	call	*%ecx
	movl	_nchars, %ebp
	incl	%ebp
	cmpl	$45, %eax
	movl	%ebp, _nchars
	je	L172
	cmpl	$43, %eax
	je	L172
	leal	-48(%eax), %edx
	cmpl	$9, %edx
	ja	L304
L172:
	movl	$1, 64(%esp)
	jmp	L110
L327:
	leal	-102(%edx), %eax
	cmpl	$1, %eax
	setbe	%cl
	andl	$255, %ecx
	cmpl	$111, %edx
	movl	%ecx, 120(%esp)
	jne	L335
	jmp	L165
L323:
	movl	_nchars, %eax
	movb	%al, (%ebx)
	jmp	L290
L311:
	movsbl	(%edi), %edx
	movzbl	%dl, %eax
	incl	%edi
	incl	%eax
	movl	$0, 80(%esp)
	movl	$8, 52(%esp)
	jmp	L60
L154:
	movl	$8, 52(%esp)
	jmp	L70
L165:
	movl	%ebp, 40(%esp)
	movl	$8, 48(%esp)
	movl	%edx, 60(%esp)
	movl	224(%esp), %esi
	movl	228(%esp), %ebp
	jmp	L245
L59:
	movsbl	1(%edi), %edx
	movzbl	%dl, %eax
	addl	$2, %edi
	incl	%eax
	movl	$0, 80(%esp)
	movl	$8, 52(%esp)
	jmp	L60
L109:
	movl	40(%esp), %edx
	orl	44(%esp), %edx
	jne	L108
	cmpl	$2, %edi
	jne	L108
	movl	$0, 40(%esp)
	movl	$0, 44(%esp)
	movl	$16, 48(%esp)
	jmp	L110
L304:
	movl	%ebx, %esi
	movl	92(%esp), %ebp
	movl	104(%esp), %ebx
	movl	108(%esp), %edi
L106:
	movl	116(%esp), %edx
	testl	%edx, %edx
	je	L124
	negl	40(%esp)
	adcl	$0, 44(%esp)
	negl	44(%esp)
L124:
	movl	$1, %ecx
	cmpl	$-1, %eax
	je	L125
	movl	224(%esp), %ecx
	movl	%eax, (%esp)
	movl	%ecx, 4(%esp)
	movl	232(%esp), %edx
	call	*%edx
	xorl	%ecx, %ecx
L125:
	movl	_nchars, %eax
	decl	%eax
	cmpl	32(%esp), %esi
	movl	%eax, _nchars
	je	L306
	movl	116(%esp), %eax
	testl	%eax, %eax
	je	L127
	leal	129(%esp), %eax
	cmpl	%eax, %esi
	je	L306
L127:
	testl	%ebx, %ebx
	je	L174
	movl	120(%esp), %eax
	movl	52(%esp), %edx
	sall	$4, %eax
	movb	$0, (%esi)
	orl	%edx, %eax
	cmpl	$24, %eax
	ja	L150
	jmp	*L137(,%eax,4)
	.p2align 2
	.p2align 2
L137:
	.long	L129
	.long	L130
	.long	L131
	.long	L150
	.long	L132
	.long	L150
	.long	L150
	.long	L150
	.long	L133
	.long	L150
	.long	L150
	.long	L150
	.long	L150
	.long	L150
	.long	L150
	.long	L150
	.long	L150
	.long	L134
	.long	L134
	.long	L150
	.long	L135
	.long	L150
	.long	L150
	.long	L150
	.long	L136
L131:
	movl	40(%esp), %edx
	movl	%edx, (%ebx)
L150:
	movl	100(%esp), %eax
	testl	%eax, %eax
	je	L174
	movl	56(%esp), %eax
	incl	%eax
	movl	%eax, 56(%esp)
	jmp	L290
L333:
	movl	%eax, %edx
	andl	$-33, %edx
	subl	$65, %edx
	cmpl	$5, %edx
	ja	L114
	movl	60(%esp), %edx
	incl	%edx
	movl	%edx, 60(%esp)
	movzbl	%al, %edx
	movw	___dj_ctype_flags+2(%edx,%edx), %dx
	andl	$8, %edx
	movw	%dx, 26(%esp)
L118:
	movl	40(%esp), %edx
	movl	44(%esp), %ecx
	shldl	$4, %edx, %ecx
	sall	$4, %edx
	movl	%ecx, 76(%esp)
	movl	%edx, 72(%esp)
	cmpw	$0, 26(%esp)
	jne	L117
	leal	-97(%eax), %ecx
	leal	-55(%eax), %edx
	cmpl	$5, %ecx
	ja	L120
	leal	-87(%eax), %edx
	jmp	L120
L334:
	cmpl	$8, 48(%esp)
	je	L304
	cmpb	$0, 115(%esp)
	jne	L304
	movl	60(%esp), %ebp
	incl	%ebp
	movl	%ebp, 60(%esp)
	jmp	L110
L331:
	movl	$8, 48(%esp)
	jmp	L107
L319:
	movsbl	(%edi), %edx
	leal	1(%edi), %ecx
	cmpl	$104, %edx
	je	L62
	movzbl	%dl, %eax
	incl	%eax
	movl	%ecx, %edi
	movl	$0, 80(%esp)
	movl	$1, 52(%esp)
	jmp	L60
L330:
	movl	40(%esp), %edx
	movl	44(%esp), %ecx
	shldl	$3, %edx, %ecx
	sall	$3, %edx
	movl	%ecx, 76(%esp)
	movl	%edx, 72(%esp)
	jmp	L117
L296:
	movl	%ebp, 40(%esp)
	movl	%edx, 60(%esp)
	movl	224(%esp), %esi
	movl	228(%esp), %ebp
	jmp	L245
L80:
	cmpl	$99, %edx
	sete	40(%esp)
	jne	L83
	cmpl	$30000, 36(%esp)
	jne	L83
	movl	$1, 36(%esp)
L83:
	movl	80(%esp), %eax
	testl	%eax, %eax
	je	L156
	movl	$128, (%esp)
	movl	%edx, 28(%esp)
	call	_malloc
	movl	28(%esp), %edx
	movl	%eax, 60(%esp)
	testl	%eax, %eax
	je	L336
	movl	%ebx, 84(%esp)
	movl	60(%esp), %ebx
	jmp	L84
L340:
	movl	%ebp, %ebx
	movl	%edi, 36(%esp)
	movl	64(%esp), %ebp
	movl	68(%esp), %edx
	movl	72(%esp), %edi
	movl	$1, %esi
L90:
	movl	36(%esp), %ecx
	testl	%ecx, %ecx
	jle	L337
	movl	224(%esp), %ecx
	movl	%edx, 28(%esp)
	movl	%ecx, 4(%esp)
	movl	%eax, (%esp)
	movl	232(%esp), %ecx
	call	*%ecx
	movl	_nchars, %eax
	decl	%eax
	xorl	%ecx, %ecx
	movl	%eax, _nchars
	movl	28(%esp), %edx
L146:
	testl	%esi, %esi
	jne	L95
L306:
	movl	%ecx, %ebp
L149:
	testl	%ebp, %ebp
	jne	L338
L138:
	movl	80(%esp), %eax
	testl	%eax, %eax
	je	L140
	cmpl	$25, _errno
	je	L312
L140:
	movl	96(%esp), %edx
	movl	%edx, _errno
	jmp	L210
L156:
	movl	$0, 60(%esp)
	movl	$0, 84(%esp)
L84:
	cmpl	$115, %edx
	movl	%ebx, 64(%esp)
	sete	%cl
	andl	$255, %ecx
	movl	%ebp, 52(%esp)
	movl	%ecx, 48(%esp)
	movl	%edx, 68(%esp)
	movl	224(%esp), %esi
	movl	228(%esp), %ebx
L87:
	movl	_nchars, %ebp
	movl	%esi, (%esp)
	leal	1(%ebp), %eax
	movl	%eax, _nchars
	call	*%ebx
	cmpl	$-1, %eax
	je	L86
	movzbl	%al, %edx
	movsbl	__sctab(%edx), %edx
	testl	%edx, 48(%esp)
	jne	L87
L86:
	movl	%ebp, 92(%esp)
	movl	64(%esp), %ebx
	movl	68(%esp), %edx
	movl	52(%esp), %ebp
	cmpb	$0, 40(%esp)
	jne	L158
	cmpl	$91, %edx
	sete	%cl
	andl	$255, %ecx
	incl	%ecx
	movl	%ecx, 40(%esp)
L88:
	cmpl	$-1, %eax
	je	L89
	movzbl	%al, %ecx
	movsbl	__sctab(%ecx), %ecx
	testl	%ecx, 40(%esp)
	jne	L160
	movb	80(%esp), %cl
	cmpl	$99, %edx
	movl	%ebp, 64(%esp)
	setne	52(%esp)
	movl	%ebx, %ebp
	movl	%edi, 72(%esp)
	andb	%cl, 52(%esp)
	movl	$128, 48(%esp)
	movl	%edx, 68(%esp)
	movl	224(%esp), %esi
	movl	228(%esp), %ebx
	movl	36(%esp), %edi
	jmp	L97
L341:
	decl	48(%esp)
	je	L339
L93:
	movl	%esi, (%esp)
	call	*%ebx
	movl	_nchars, %ecx
	incl	%ecx
	cmpl	$-1, %eax
	movl	%ecx, _nchars
	je	L163
	movzbl	%al, %ecx
	movsbl	__sctab(%ecx), %ecx
	testl	%ecx, 40(%esp)
	jne	L340
L97:
	testl	%ebp, %ebp
	je	L91
	movb	%al, 0(%ebp)
	incl	%ebp
L91:
	cmpb	$0, 52(%esp)
	jne	L341
	decl	%edi
	testl	%edi, %edi
	jg	L93
	movl	%ebp, %ebx
	movl	68(%esp), %edx
	movl	64(%esp), %ebp
	movl	72(%esp), %edi
	xorl	%ecx, %ecx
L95:
	movl	_nchars, %eax
	movl	92(%esp), %esi
	subl	%esi, %eax
	testl	%ebx, %ebx
	je	L98
	cmpl	$99, %edx
	je	L98
	movb	$0, (%ebx)
	incl	%eax
L98:
	movl	80(%esp), %edx
	testl	%edx, %edx
	je	L150
	movl	%eax, 4(%esp)
	movl	60(%esp), %eax
	movl	%eax, (%esp)
	movl	%ecx, 28(%esp)
	call	_realloc
	movl	84(%esp), %edx
	testb	%al, %al
	movl	28(%esp), %ecx
	movl	%eax, (%edx)
	jne	L150
	movl	60(%esp), %eax
	movl	%ecx, %ebp
	movl	%eax, (%esp)
	call	_free
	movl	$25, _errno
	movl	$1, 80(%esp)
	jmp	L149
	.p2align 4,,7
L339:
	movl	60(%esp), %eax
	subl	%eax, %ebp
	leal	128(%ebp), %eax
	movl	%eax, 4(%esp)
	movl	60(%esp), %eax
	movl	%eax, (%esp)
	call	_realloc
	testl	%eax, %eax
	je	L342
	decl	%edi
	addl	%eax, %ebp
	movl	%eax, 60(%esp)
	movl	$128, 48(%esp)
	testl	%edi, %edi
	jg	L93
	movl	$30000, %edi
	jmp	L93
L320:
	movsbl	(%edi), %edx
	jmp	L310
L326:
	movb	$0, 40(%esp)
	jmp	L83
L174:
	movl	$1, 88(%esp)
	jmp	L290
L102:
	movl	_nchars, %ecx
	movl	40(%esp), %ebp
	decl	%ecx
	movl	60(%esp), %edx
	movl	%ecx, _nchars
	movl	$0, 116(%esp)
	leal	128(%esp), %esi
	jmp	L105
L62:
	movsbl	1(%edi), %edx
	movzbl	%dl, %eax
	addl	$2, %edi
	incl	%eax
	movl	$0, 80(%esp)
	movl	$0, 52(%esp)
	jmp	L60
L136:
	leal	128(%esp), %edx
	movl	%edx, (%esp)
	call	__atold
	fstpt	(%ebx)
	jmp	L150
L135:
	leal	128(%esp), %eax
	movl	%eax, (%esp)
	call	_atof
	fstpl	(%ebx)
	jmp	L150
L134:
	leal	128(%esp), %ecx
	movl	%ecx, (%esp)
	call	_atof
	fstps	(%ebx)
	jmp	L150
L133:
	movl	40(%esp), %edx
	movl	44(%esp), %ecx
	movl	%edx, (%ebx)
	movl	%ecx, 4(%ebx)
	jmp	L150
L132:
	movl	40(%esp), %ecx
	movl	%ecx, (%ebx)
	jmp	L150
L130:
	movl	40(%esp), %eax
	movw	%ax, (%ebx)
	jmp	L150
L129:
	movb	40(%esp), %cl
	movb	%cl, (%ebx)
	jmp	L150
L338:
	movl	56(%esp), %eax
	orl	88(%esp), %eax
	jne	L138
	jmp	L312
	.p2align 4,,7
L163:
	movl	%ebp, %ebx
	movl	68(%esp), %edx
	movl	64(%esp), %ebp
	movl	72(%esp), %edi
	movl	$1, %esi
L96:
	decl	%ecx
	movl	%ecx, _nchars
	movl	$1, %ecx
	jmp	L146
L328:
	movl	224(%esp), %ecx
	movl	%edx, 28(%esp)
	movl	%ecx, (%esp)
	movl	228(%esp), %ecx
	movb	$45, 128(%esp)
	call	*%ecx
	movl	_nchars, %ecx
	movl	36(%esp), %esi
	decl	%esi
	incl	%ecx
	movl	%esi, 36(%esp)
	movl	%ecx, _nchars
	movl	$1, 116(%esp)
	leal	129(%esp), %esi
	movl	28(%esp), %edx
	jmp	L105
L321:
	movsbl	(%edi), %edx
	movzbl	%dl, %eax
	incl	%edi
	incl	%eax
	movl	$0, 80(%esp)
	movl	$2, 52(%esp)
	jmp	L60
L158:
	movl	$0, 40(%esp)
	jmp	L88
L329:
	movl	36(%esp), %esi
	movl	224(%esp), %ecx
	decl	%esi
	movl	%ecx, (%esp)
	movl	%edx, 28(%esp)
	movl	228(%esp), %ecx
	movl	%esi, 36(%esp)
	call	*%ecx
	movl	_nchars, %edx
	movl	$0, 116(%esp)
	incl	%edx
	leal	128(%esp), %esi
	movl	%edx, _nchars
	movl	28(%esp), %edx
	jmp	L105
L322:
	movsbl	(%edi), %edx
	incl	%edi
	cmpl	$91, %edx
	je	L68
	movzbl	%dl, %eax
	incl	%eax
	movl	$1, 80(%esp)
	movl	$2, 52(%esp)
	jmp	L60
L324:
	movl	_nchars, %eax
	movw	%ax, (%ebx)
	jmp	L290
L144:
	movl	224(%esp), %edx
	movl	%eax, (%esp)
	movl	%edx, 4(%esp)
	movl	232(%esp), %ecx
	call	*%ecx
	movl	_nchars, %ebx
	decl	%ebx
	movl	%ebx, _nchars
	jmp	L210
L325:
	movl	_nchars, %eax
	movl	%eax, %edx
	movl	%eax, (%ebx)
	sarl	$31, %edx
	movl	%edx, 4(%ebx)
	jmp	L290
L169:
	movl	$0, 40(%esp)
	movl	$0, 44(%esp)
	jmp	L106
L69:
	movl	%edi, %eax
	movl	%edx, 28(%esp)
	call	__getccl
	movl	$0, 80(%esp)
	movl	%eax, %edi
	movl	$2, 52(%esp)
	movl	$92, %eax
	movl	28(%esp), %edx
	jmp	L60
L342:
	movl	60(%esp), %eax
	movl	%eax, (%esp)
	call	_free
	movl	$25, _errno
	jmp	L138
L337:
	xorl	%ecx, %ecx
	jmp	L146
L160:
	xorl	%esi, %esi
	jmp	L90
L336:
	movl	$25, _errno
	movl	$1, 80(%esp)
	jmp	L138
L68:
	movl	%edi, %eax
	movl	%edx, 28(%esp)
	call	__getccl
	movl	$1, 80(%esp)
	movl	%eax, %edi
	movl	$2, 52(%esp)
	movl	$92, %eax
	movl	28(%esp), %edx
	jmp	L60
L89:
	movl	_nchars, %ecx
	xorl	%esi, %esi
	jmp	L96
	.cfi_endproc
LFE9:
	.p2align 4,,15
	.globl	__doscan
__doscan:
LFB8:
	.cfi_startproc
	subl	$44, %esp
	.cfi_def_cfa_offset 48
	movl	56(%esp), %eax
	movl	$_ungetc, 8(%esp)
	movl	%eax, 16(%esp)
	movl	52(%esp), %eax
	movl	%eax, 12(%esp)
	movl	48(%esp), %eax
	movl	$_fgetc, 4(%esp)
	movl	%eax, (%esp)
	call	__doscan_low
	addl	$44, %esp
	.cfi_def_cfa_offset 4
	ret
	.cfi_endproc
LFE8:
	.section .data
_decimal_point:
	.byte	46
.lcomm _nchars,4,4
	.p2align 4
__sctab:
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	1
	.byte	1
	.byte	1
	.byte	1
	.byte	1
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	1
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.space 192
	.ident	"GCC: (GNU) 4.7.4"
