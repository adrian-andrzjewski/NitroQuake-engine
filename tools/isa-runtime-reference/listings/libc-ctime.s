	.file	"ctime.c"
	.section .text
	.p2align 4,,15
_getnum:
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
	movl	20(%esp), %edi
	testl	%eax, %eax
	je	L2
	xorl	%ebx, %ebx
	movl	%edx, %ebp
	movb	(%eax), %dl
	movb	%dl, %bl
	subl	$48, %ebx
	cmpl	$9, %ebx
	ja	L11
	testb	%dl, %dl
	je	L8
	cmpl	%ebx, %edi
	jge	L18
	jmp	L11
	.p2align 4,,7
L21:
	andl	$255, %edx
	leal	-48(%edx), %esi
	cmpl	$9, %esi
	ja	L3
	leal	(%ebx,%ebx,4), %edx
	leal	(%esi,%edx,2), %ebx
	cmpl	%edi, %ebx
	jg	L11
L18:
	incl	%eax
	movb	(%eax), %dl
	testb	%dl, %dl
	jne	L21
L3:
	cmpl	%ebx, %ecx
	jg	L11
	movl	%ebx, 0(%ebp)
L2:
	popl	%ebx
	.cfi_remember_state
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
L11:
	.cfi_restore_state
	popl	%ebx
	.cfi_remember_state
	.cfi_restore 3
	.cfi_def_cfa_offset 16
	xorl	%eax, %eax
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
L8:
	.cfi_restore_state
	xorl	%ebx, %ebx
	jmp	L3
	.cfi_endproc
LFE9:
	.p2align 4,,15
_getsecs:
LFB10:
	.cfi_startproc
	pushl	%esi
	.cfi_def_cfa_offset 8
	.cfi_offset 6, -8
	pushl	%ebx
	.cfi_def_cfa_offset 12
	.cfi_offset 3, -12
	subl	$20, %esp
	.cfi_def_cfa_offset 32
	xorl	%ecx, %ecx
	movl	%edx, %esi
	movl	$167, (%esp)
	leal	16(%esp), %edx
	call	_getnum
	testl	%eax, %eax
	je	L25
	movl	16(%esp), %ecx
	movl	%ecx, %edx
	sall	$4, %edx
	sall	$8, %ecx
	subl	%edx, %ecx
	movl	%ecx, %ebx
	sall	$4, %ebx
	subl	%ecx, %ebx
	movl	%ebx, (%esi)
	cmpb	$58, (%eax)
	je	L33
L24:
	addl	$20, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 12
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 8
	popl	%esi
	.cfi_restore 6
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L33:
	.cfi_restore_state
	incl	%eax
	xorl	%ecx, %ecx
	movl	$59, (%esp)
	leal	16(%esp), %edx
	call	_getnum
	testl	%eax, %eax
	je	L25
	movl	16(%esp), %edx
	movl	(%esi), %ebx
	leal	0(,%edx,4), %ecx
	sall	$6, %edx
	subl	%ecx, %edx
	addl	%edx, %ebx
	movl	%ebx, (%esi)
	cmpb	$58, (%eax)
	jne	L24
	incl	%eax
	xorl	%ecx, %ecx
	movl	$60, (%esp)
	leal	16(%esp), %edx
	call	_getnum
	testl	%eax, %eax
	je	L25
	movl	(%esi), %ecx
	movl	16(%esp), %edx
	addl	%edx, %ecx
	movl	%ecx, (%esi)
	jmp	L24
	.p2align 4,,7
L25:
	xorl	%eax, %eax
	jmp	L24
	.cfi_endproc
LFE10:
	.p2align 4,,15
_getoffset:
LFB11:
	.cfi_startproc
	pushl	%ebx
	.cfi_def_cfa_offset 8
	.cfi_offset 3, -8
	movl	%edx, %ebx
	movb	(%eax), %dl
	cmpb	$45, %dl
	je	L44
	cmpb	$43, %dl
	sete	%dl
	andl	$255, %edx
	addl	%edx, %eax
	movl	%ebx, %edx
	popl	%ebx
	.cfi_remember_state
	.cfi_restore 3
	.cfi_def_cfa_offset 4
	jmp	_getsecs
	.p2align 4,,7
L44:
	.cfi_restore_state
	incl	%eax
	movl	%ebx, %edx
	call	_getsecs
	testl	%eax, %eax
	je	L36
	negl	(%ebx)
L36:
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 4
	ret
	.cfi_endproc
LFE11:
	.p2align 4,,15
_getrule:
LFB12:
	.cfi_startproc
	pushl	%ebx
	.cfi_def_cfa_offset 8
	.cfi_offset 3, -8
	pushl	%ebx
	.cfi_def_cfa_offset 12
	movb	(%eax), %cl
	movl	%edx, %ebx
	cmpb	$74, %cl
	je	L60
	cmpb	$77, %cl
	je	L61
	andl	$255, %ecx
	subl	$48, %ecx
	cmpl	$9, %ecx
	ja	L51
	movl	$1, (%edx)
	xorl	%ecx, %ecx
	leal	4(%edx), %edx
	movl	$365, (%esp)
	call	_getnum
L47:
	testl	%eax, %eax
	je	L51
	cmpb	$47, (%eax)
	je	L62
	movl	$7200, 16(%ebx)
	popl	%edx
	.cfi_remember_state
	.cfi_def_cfa_offset 8
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L61:
	.cfi_restore_state
	movl	$2, (%edx)
	incl	%eax
	leal	12(%edx), %edx
	movl	$12, (%esp)
	movl	$1, %ecx
	call	_getnum
	testl	%eax, %eax
	je	L51
	cmpb	$46, (%eax)
	jne	L51
	incl	%eax
	leal	8(%ebx), %edx
	movl	$5, (%esp)
	movl	$1, %ecx
	call	_getnum
	testl	%eax, %eax
	je	L51
	cmpb	$46, (%eax)
	je	L63
	.p2align 4,,7
L51:
	xorl	%eax, %eax
	popl	%edx
	.cfi_remember_state
	.cfi_def_cfa_offset 8
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L60:
	.cfi_restore_state
	movl	$0, (%edx)
	incl	%eax
	leal	4(%edx), %edx
	movl	$365, (%esp)
	movl	$1, %ecx
	call	_getnum
	jmp	L47
	.p2align 4,,7
L62:
	leal	16(%ebx), %edx
	incl	%eax
	popl	%ecx
	.cfi_remember_state
	.cfi_def_cfa_offset 8
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 4
	jmp	_getsecs
	.p2align 4,,7
L63:
	.cfi_restore_state
	incl	%eax
	leal	4(%ebx), %edx
	movl	$6, (%esp)
	xorl	%ecx, %ecx
	call	_getnum
	jmp	L47
	.cfi_endproc
LFE12:
	.p2align 4,,15
_transtime:
LFB13:
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
	subl	$16, %esp
	.cfi_def_cfa_offset 36
	movl	%eax, %edi
	movl	%edx, %ebp
	testb	$3, %dl
	jne	L65
	movl	%edx, %eax
	movl	$100, %ebx
	sarl	$31, %edx
	movl	$1, (%esp)
	idivl	%ebx
	testl	%edx, %edx
	je	L65
	movl	(%ecx), %eax
	cmpl	$1, %eax
	je	L69
L92:
	cmpl	$2, %eax
	je	L70
	testl	%eax, %eax
	je	L68
	xorl	%edi, %edi
L67:
	movl	36(%esp), %eax
	movl	16(%ecx), %edx
	addl	$16, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 20
	addl	%edx, %eax
	addl	%edi, %eax
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
L65:
	.cfi_restore_state
	movl	%ebp, %edx
	movl	$400, %ebx
	sarl	$31, %edx
	movl	%ebp, %eax
	idivl	%ebx
	testl	%edx, %edx
	sete	%al
	andl	$255, %eax
	movl	%eax, (%esp)
	movl	(%ecx), %eax
	cmpl	$1, %eax
	jne	L92
L69:
	movl	4(%ecx), %eax
L77:
	leal	(%eax,%eax,2), %eax
	movl	%eax, %edx
	sall	$4, %edx
	subl	%eax, %edx
	movl	%edx, %eax
	sall	$4, %eax
	subl	%edx, %eax
	sall	$7, %eax
	addl	%eax, %edi
	jmp	L67
	.p2align 4,,7
L68:
	movl	4(%ecx), %ebx
	leal	-3(%ebx,%ebx,2), %eax
	movl	%eax, %edx
	sall	$4, %edx
	subl	%eax, %edx
	movl	%edx, %eax
	sall	$4, %eax
	subl	%edx, %eax
	sall	$7, %eax
	addl	%eax, %edi
	movl	(%esp), %eax
	testl	%eax, %eax
	je	L67
	cmpl	$59, %ebx
	jle	L67
	addl	$86400, %edi
	jmp	L67
	.p2align 4,,7
L70:
	movl	12(%ecx), %edx
	movl	%edx, 4(%esp)
	decl	%edx
	movl	%edx, 8(%esp)
	testl	%edx, %edx
	jle	L72
	movl	(%esp), %eax
	movl	(%esp), %edx
	movl	%ecx, 12(%esp)
	movl	8(%esp), %ecx
	leal	(%eax,%edx,2), %edx
	xorl	%eax, %eax
	sall	$4, %edx
	.p2align 4,,7
L73:
	movl	_mon_lengths(%edx,%eax,4), %ebx
	incl	%eax
	leal	(%ebx,%ebx,2), %ebx
	movl	%ebx, %esi
	sall	$4, %esi
	subl	%ebx, %esi
	movl	%esi, %ebx
	sall	$4, %ebx
	subl	%esi, %ebx
	sall	$7, %ebx
	addl	%ebx, %edi
	cmpl	%ecx, %eax
	jne	L73
	movl	12(%esp), %ecx
L72:
	movl	4(%esp), %eax
	movl	$12, %ebx
	addl	$9, %eax
	movl	%eax, %edx
	sarl	$31, %edx
	idivl	%ebx
	cmpl	$2, 4(%esp)
	setle	%al
	andl	$255, %eax
	movl	$1374389535, %ebx
	subl	%eax, %ebp
	leal	1(%edx), %esi
	movl	%ebp, %eax
	imull	%ebx
	movl	%ebp, %eax
	movl	%edx, %ebx
	sarl	$31, %eax
	movl	$1717986919, %edx
	sarl	$5, %ebx
	subl	%eax, %ebx
	leal	(%ebx,%ebx,4), %eax
	leal	(%eax,%eax,4), %eax
	sall	$2, %eax
	subl	%eax, %ebp
	leal	(%esi,%esi,2), %eax
	leal	(%esi,%eax,4), %eax
	leal	-2(%eax,%eax), %esi
	movl	%esi, %eax
	imull	%edx
	sarl	$31, %esi
	sarl	$2, %edx
	subl	%esi, %edx
	leal	1(%ebp,%edx), %eax
	movl	%ebp, %edx
	sarl	$31, %edx
	shrl	$30, %edx
	addl	%edx, %ebp
	sarl	$2, %ebp
	addl	%eax, %ebp
	movl	%ebx, %eax
	sarl	$31, %eax
	shrl	$30, %eax
	addl	%ebx, %eax
	sarl	$2, %eax
	negl	%ebx
	addl	%ebp, %eax
	leal	(%eax,%ebx,2), %eax
	movl	$7, %ebx
	movl	%eax, %edx
	sarl	$31, %edx
	idivl	%ebx
	testl	%edx, %edx
	js	L93
L75:
	movl	4(%ecx), %ebx
	subl	%edx, %ebx
	js	L94
L76:
	movl	8(%ecx), %edx
	cmpl	$1, %edx
	jle	L84
	movl	(%esp), %ebp
	movl	(%esp), %esi
	leal	7(%ebx), %eax
	leal	0(%ebp,%esi,2), %esi
	movl	8(%esp), %ebp
	leal	0(%ebp,%esi,4), %esi
	movl	_mon_lengths(,%esi,4), %esi
	cmpl	%eax, %esi
	jle	L84
	leal	(%ebx,%edx,8), %ebx
	subl	%edx, %ebx
	subl	$7, %ebx
	jmp	L78
	.p2align 4,,7
L79:
	leal	7(%eax), %edx
	cmpl	%esi, %edx
	jge	L77
	movl	%edx, %eax
L78:
	cmpl	%ebx, %eax
	jne	L79
	jmp	L77
	.p2align 4,,7
L94:
	addl	$7, %ebx
	jmp	L76
	.p2align 4,,7
L93:
	addl	$7, %edx
	jmp	L75
L84:
	movl	%ebx, %eax
	jmp	L77
	.cfi_endproc
LFE13:
	.p2align 4,,15
_normalize_overflow:
LFB32:
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
	movl	(%edx), %ebx
	movl	%eax, %ebp
	movl	%edx, %edi
	movl	%ebx, %eax
	testl	%ebx, %ebx
	js	L96
	movl	%ebx, %edx
	sarl	$31, %edx
	idivl	%ecx
	movl	%eax, %esi
	imull	%esi, %ecx
	subl	%ecx, %ebx
	movl	%ebx, (%edi)
	movl	0(%ebp), %edx
	testl	%edx, %edx
	js	L98
L103:
	movl	$2147483647, %eax
	subl	%edx, %eax
	cmpl	%eax, %esi
	setg	%cl
L99:
	movl	$1, %eax
	testb	%cl, %cl
	jne	L100
	addl	%edx, %esi
	xorb	%al, %al
	movl	%esi, 0(%ebp)
L100:
	popl	%ebx
	.cfi_remember_state
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
L96:
	.cfi_restore_state
	xorl	$-1, %eax
	movl	%eax, %edx
	sarl	$31, %edx
	idivl	%ecx
	movl	%eax, %esi
	xorl	$-1, %esi
	imull	%esi, %ecx
	subl	%ecx, %ebx
	movl	%ebx, (%edi)
	movl	0(%ebp), %edx
	testl	%edx, %edx
	jns	L103
L98:
	movl	$-2147483648, %eax
	subl	%edx, %eax
	cmpl	%eax, %esi
	setl	%cl
	jmp	L99
	.cfi_endproc
LFE32:
LC0:
	.ascii ",M4.1.0,M10.5.0\0"
LC1:
	.ascii "posixrules\0"
	.p2align 4,,15
_tzparse:
LFB14:
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
	movl	%eax, %edi
	movl	%edx, %ebx
	testl	%ecx, %ecx
	je	L105
	movl	%eax, (%esp)
	call	_strlen
	movl	%edi, 48(%esp)
	movl	%eax, %esi
	movl	%eax, 32(%esp)
	addl	%edi, %esi
	cmpl	$50, %eax
	jbe	L106
	movl	$50, 32(%esp)
L106:
	xorl	%ecx, %ecx
	movl	%ebx, %edx
	movl	$LC1, %eax
	call	_tzload
	movl	%eax, %edi
	testl	%eax, %eax
	je	L120
	movl	$0, (%ebx)
L120:
	movb	(%esi), %dl
	testb	%dl, %dl
	je	L121
	cmpb	$60, %dl
	je	L122
	testb	%dl, %dl
	je	L165
	xorl	%eax, %eax
	movb	%dl, %al
	subl	$48, %eax
	cmpl	$9, %eax
	jbe	L165
	leal	-44(%edx), %eax
	cmpb	$1, %al
	movl	%esi, %eax
	jbe	L166
	cmpb	$43, %dl
	jne	L197
	jmp	L166
	.p2align 4,,7
L128:
	xorl	%ecx, %ecx
	movb	%dl, %cl
	subl	$48, %ecx
	cmpl	$9, %ecx
	jbe	L228
	leal	-44(%edx), %ecx
	cmpb	$1, %cl
	jbe	L228
	cmpb	$43, %dl
	je	L228
L197:
	incl	%eax
	movb	(%eax), %dl
	testb	%dl, %dl
	jne	L128
L228:
	movl	%eax, %ecx
	subl	%esi, %ecx
	movl	%ecx, 40(%esp)
L123:
	movl	%esi, 52(%esp)
L127:
	cmpb	$44, %dl
	je	L132
	testb	%dl, %dl
	jne	L230
L132:
	movl	64(%esp), %edx
	subl	$3600, %edx
	movl	%edx, 68(%esp)
	movb	(%eax), %dl
	testb	%dl, %dl
	je	L231
L134:
	cmpb	$59, %dl
	je	L154
	cmpb	$44, %dl
	je	L154
L136:
	addl	$124, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 20
	orl	$-1, %esi
	movl	%esi, %eax
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
L105:
	.cfi_restore_state
	movb	(%eax), %dl
	cmpb	$60, %dl
	je	L107
	testb	%dl, %dl
	je	L160
	xorl	%eax, %eax
	movb	%dl, %al
	subl	$48, %eax
	cmpl	$9, %eax
	jbe	L160
	leal	-44(%edx), %eax
	cmpb	$1, %al
	movl	%edi, %eax
	jbe	L161
	cmpb	$43, %dl
	jne	L198
	jmp	L161
	.p2align 4,,7
L115:
	xorl	%ecx, %ecx
	movb	%dl, %cl
	subl	$48, %ecx
	cmpl	$9, %ecx
	jbe	L225
	leal	-44(%edx), %ecx
	cmpb	$1, %cl
	jbe	L225
	cmpb	$43, %dl
	je	L225
L198:
	incl	%eax
	movb	(%eax), %dl
	testb	%dl, %dl
	jne	L115
L225:
	movl	%eax, %ecx
	subl	%edi, %ecx
	movl	%ecx, 32(%esp)
L108:
	movl	%edi, 48(%esp)
L114:
	testb	%dl, %dl
	je	L136
	leal	64(%esp), %edx
	call	_getoffset
	movl	%eax, %esi
	testl	%eax, %eax
	jne	L106
	jmp	L136
	.p2align 4,,7
L121:
	movl	64(%esp), %eax
	movl	$1, 8(%ebx)
	negl	%eax
	movl	%eax, 6024(%ebx)
	movl	32(%esp), %eax
	incl	%eax
	movl	$0, 4(%ebx)
	movl	$0, 6028(%ebx)
	movl	$0, 6032(%ebx)
	movl	%eax, 28(%esp)
	movl	%eax, 12(%ebx)
	movl	$0, 40(%esp)
	movl	$0, 52(%esp)
L152:
	cmpl	$51, 28(%esp)
	jg	L136
	movl	32(%esp), %eax
	movl	48(%esp), %edi
	movl	%eax, 8(%esp)
	leal	6224(%ebx), %eax
	movl	%edi, 4(%esp)
	movl	%eax, (%esp)
	call	_strncpy
	movl	32(%esp), %eax
	movl	40(%esp), %edx
	xorl	%esi, %esi
	movb	$0, 6224(%ebx,%eax)
	testl	%edx, %edx
	je	L196
	movl	40(%esp), %edi
	leal	6225(%ebx,%eax), %ebx
	movl	%edi, 8(%esp)
	movl	52(%esp), %edi
	movl	%edi, 4(%esp)
	movl	%ebx, (%esp)
	call	_strncpy
	movl	40(%esp), %edi
	movb	$0, (%ebx,%edi)
L196:
	addl	$124, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 20
	movl	%esi, %eax
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
L230:
	.cfi_restore_state
	cmpb	$59, %dl
	je	L132
	leal	68(%esp), %edx
	call	_getoffset
	testl	%eax, %eax
	je	L136
	movb	(%eax), %dl
	testb	%dl, %dl
	jne	L134
L231:
	testl	%edi, %edi
	je	L135
	movl	$LC0, %eax
L154:
	incl	%eax
	leal	72(%esp), %edx
	call	_getrule
	movl	%eax, %edx
	testl	%eax, %eax
	je	L136
	leal	1(%eax), %eax
	cmpb	$44, (%edx)
	jne	L136
	leal	92(%esp), %edx
	call	_getrule
	testl	%eax, %eax
	je	L136
	cmpb	$0, (%eax)
	jne	L136
	movl	68(%esp), %edi
	movl	_zttinfo.2821+16, %eax
	movl	%eax, 6060(%ebx)
	movl	%eax, 6040(%ebx)
	movl	%edi, %eax
	movl	_zttinfo.2821+12, %edx
	negl	%eax
	movl	%eax, 6024(%ebx)
	movl	32(%esp), %eax
	incl	%eax
	movl	%edx, 6056(%ebx)
	movl	%eax, 28(%esp)
	movl	%eax, 6032(%ebx)
	movl	64(%esp), %eax
	movl	%edx, 6036(%ebx)
	movl	%eax, %edx
	movl	%edi, 44(%esp)
	negl	%edx
	movl	%edi, 60(%esp)
	movl	$2, 8(%ebx)
	movl	$1, 6028(%ebx)
	movl	%edx, 6044(%ebx)
	movl	$0, 6048(%ebx)
	movl	$0, 6052(%ebx)
	movl	$0, 4(%ebx)
	movl	%eax, 56(%esp)
	leal	32(%ebx), %esi
	leal	4826(%ebx), %ebp
	xorl	%edi, %edi
	movl	$1970, 24(%esp)
	jmp	L142
	.p2align 4,,7
L232:
	movl	%eax, -8(%esi)
	movl	36(%esp), %eax
	movb	$1, -2(%ebp)
	movl	%eax, -4(%esi)
	movb	$0, -1(%ebp)
L138:
	movl	4(%ebx), %ecx
	addl	$2, %ecx
	testb	$3, 24(%esp)
	movl	%ecx, 44(%esp)
	movl	%ecx, 4(%ebx)
	jne	L139
	movl	24(%esp), %eax
	movl	$100, %ecx
	movl	%eax, %edx
	sarl	$31, %edx
	idivl	%ecx
	testl	%edx, %edx
	movl	$1, %eax
	jne	L140
L139:
	movl	24(%esp), %eax
	movl	$400, %ecx
	movl	%eax, %edx
	sarl	$31, %edx
	idivl	%ecx
	testl	%edx, %edx
	sete	%al
	andl	$255, %eax
L140:
	movl	_year_lengths(,%eax,4), %eax
	leal	(%eax,%eax,2), %eax
	movl	%eax, %edx
	sall	$4, %edx
	subl	%eax, %edx
	movl	%edx, %eax
	sall	$4, %eax
	subl	%edx, %eax
	sall	$7, %eax
	addl	%edi, %eax
	cmpl	%edi, %eax
	jbe	L143
	movl	24(%esp), %edx
	addl	$8, %esi
	incl	%edx
	addl	$2, %ebp
	movl	%edx, 24(%esp)
	movl	%eax, %edi
	cmpl	$1198, 44(%esp)
	jg	L143
	movl	60(%esp), %edx
	movl	56(%esp), %eax
	movl	%edx, 44(%esp)
L142:
	movl	%eax, (%esp)
	leal	72(%esp), %ecx
	movl	24(%esp), %edx
	movl	%edi, %eax
	call	_transtime
	movl	44(%esp), %ecx
	movl	%eax, 36(%esp)
	movl	%ecx, (%esp)
	movl	24(%esp), %edx
	leal	92(%esp), %ecx
	movl	%edi, %eax
	call	_transtime
	cmpl	%eax, 36(%esp)
	ja	L232
	movl	36(%esp), %edx
	movl	%edx, -8(%esi)
	movb	$0, -2(%ebp)
	movl	%eax, -4(%esi)
	movb	$1, -1(%ebp)
	jmp	L138
L107:
	leal	1(%eax), %ecx
	movb	1(%eax), %al
	movsbl	%al, %edx
	testl	%edx, %edx
	je	L162
	cmpl	$62, %edx
	movl	%ecx, %edx
	jne	L111
	jmp	L110
	.p2align 4,,7
L233:
	cmpl	$62, %esi
	je	L110
L111:
	incl	%edx
	movb	(%edx), %al
	movsbl	%al, %esi
	testl	%esi, %esi
	jne	L233
L110:
	cmpb	$62, %al
	jne	L136
	movl	%edx, %eax
	movl	%ecx, 48(%esp)
	subl	%ecx, %eax
	movl	%eax, 32(%esp)
	leal	1(%edx), %eax
	movb	1(%edx), %dl
	jmp	L114
L135:
	movl	4(%ebx), %edi
	testl	%edi, %edi
	jle	L234
	xorl	%ecx, %ecx
	movb	4824(%ebx), %al
	movb	%al, %cl
	leal	(%ecx,%ecx,4), %edx
	movl	6028(%ebx,%edx,4), %esi
	testl	%esi, %esi
	je	L235
	addl	$4824, %edi
	leal	4825(%ebx), %edx
	movl	%edi, %ebp
	movl	%edi, 24(%esp)
	addl	%ebx, %ebp
	jmp	L146
	.p2align 4,,7
L148:
	xorl	%ecx, %ecx
	movb	(%edx), %cl
	incl	%edx
	leal	(%ecx,%ecx,4), %edi
	movl	6028(%ebx,%edi,4), %edi
	testl	%edi, %edi
	je	L144
L146:
	cmpl	%ebp, %edx
	jne	L148
	xorl	%ebp, %ebp
L147:
	movl	24(%esp), %edi
	movl	64(%esp), %edx
	addl	%ebx, %edi
	movl	%edx, 28(%esp)
	movl	%edi, 24(%esp)
	movl	%ebx, %edi
	leal	4824(%ebx), %ecx
	leal	24(%ebx), %edx
	movl	%esi, %ebx
	movl	%edi, %esi
	jmp	L157
	.p2align 4,,7
L151:
	movb	(%ecx), %al
	xorl	%ebx, %ebx
	movb	%al, %bl
	leal	(%ebx,%ebx,4), %ebx
	movl	6028(%esi,%ebx,4), %ebx
L157:
	andl	$255, %eax
	movb	%bl, (%ecx)
	leal	(%eax,%eax,4), %edi
	movl	6040(%esi,%edi,4), %edi
	testl	%edi, %edi
	jne	L149
	movl	28(%esp), %edi
	subl	%ebp, %edi
	addl	%edi, (%edx)
L149:
	leal	(%eax,%eax,4), %eax
	testl	%ebx, %ebx
	movl	6024(%esi,%eax,4), %eax
	jne	L150
	movl	%eax, %ebp
	negl	%ebp
L150:
	incl	%ecx
	addl	$4, %edx
	cmpl	24(%esp), %ecx
	jne	L151
	movl	%esi, %ebx
L156:
	movl	_zttinfo.2821+16, %eax
	movl	32(%esp), %edi
	movl	%eax, 6060(%ebx)
	movl	%eax, 6040(%ebx)
	movl	28(%esp), %eax
	movl	_zttinfo.2821+12, %edx
	negl	%eax
	movl	%eax, 6024(%ebx)
	movl	68(%esp), %eax
	incl	%edi
	movl	%edx, 6056(%ebx)
	negl	%eax
	movl	%edx, 6036(%ebx)
	movl	$0, 6028(%ebx)
	movl	$0, 6032(%ebx)
	movl	%eax, 6044(%ebx)
	movl	$1, 6048(%ebx)
	movl	%edi, 28(%esp)
	movl	%edi, 6052(%ebx)
	movl	$2, 8(%ebx)
L143:
	movl	40(%esp), %ecx
	testl	%ecx, %ecx
	je	L236
	movl	32(%esp), %eax
	movl	40(%esp), %edi
	leal	2(%eax,%edi), %edi
	movl	%edi, 28(%esp)
	movl	%edi, 12(%ebx)
	jmp	L152
L235:
	addl	$4824, %edi
	movl	%edi, 24(%esp)
L144:
	leal	(%ecx,%ecx,4), %edx
	movl	6024(%ebx,%edx,4), %ebp
	negl	%ebp
	jmp	L147
L122:
	movb	1(%esi), %al
	leal	1(%esi), %ecx
	movsbl	%al, %edx
	testl	%edx, %edx
	je	L167
	cmpl	$62, %edx
	movl	%ecx, %edx
	jne	L126
	jmp	L125
	.p2align 4,,7
L237:
	cmpl	$62, %esi
	je	L125
L126:
	incl	%edx
	movb	(%edx), %al
	movsbl	%al, %esi
	testl	%esi, %esi
	jne	L237
L125:
	cmpb	$62, %al
	jne	L136
	movl	%edx, %eax
	movl	%ecx, 52(%esp)
	subl	%ecx, %eax
	movl	%eax, 40(%esp)
	leal	1(%edx), %eax
	movb	1(%edx), %dl
	jmp	L127
L160:
	movl	%edi, %eax
	movl	$0, 32(%esp)
	jmp	L108
L161:
	movl	$0, 32(%esp)
	jmp	L108
L166:
	movl	$0, 40(%esp)
	jmp	L123
L165:
	movl	%esi, %eax
	movl	$0, 40(%esp)
	jmp	L123
L167:
	movl	%ecx, %edx
	jmp	L125
L234:
	movl	64(%esp), %eax
	movl	%eax, 28(%esp)
	jmp	L156
L162:
	movl	%ecx, %edx
	jmp	L110
L236:
	movl	28(%esp), %edi
	movl	%edi, 12(%ebx)
	jmp	L152
	.cfi_endproc
LFE14:
LC2:
	.ascii "/dev/env/DJDIR/etc/localtime\0"
LC3:
	.ascii "TZDIR\0"
LC4:
	.ascii "DJDIR\0"
	.p2align 4,,15
_tzload:
LFB5:
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
	subl	$16556, %esp
	.cfi_def_cfa_offset 16576
	movl	%eax, %ebx
	movl	%edx, %ebp
	movl	$0, 20(%edx)
	movl	%ecx, 60(%esp)
	movl	$0, 16(%edx)
	testl	%eax, %eax
	je	L414
L239:
	movb	(%ebx), %al
	cmpb	$58, %al
	je	L415
L240:
	testb	%al, %al
	je	L241
	cmpb	$92, %al
	je	L241
	cmpb	$47, %al
	je	L241
	cmpb	$58, 1(%ebx)
	je	L241
	movl	___bss_count, %eax
	cmpl	%eax, _tzdir_bss_count.2653
	je	L242
	movl	%eax, _tzdir_bss_count.2653
	movb	$0, _dir.2652
L243:
	movl	$LC3, (%esp)
	call	_getenv
	movl	%eax, _cp.2651
	testl	%eax, %eax
	je	L245
	movl	%eax, 4(%esp)
	movl	$_dir.2652, (%esp)
	call	_strcpy
L244:
	movl	$_dir.2652, %esi
L247:
	movl	(%esi), %edx
	addl	$4, %esi
	leal	-16843009(%edx), %eax
	xorl	$-1, %edx
	andl	%edx, %eax
	andl	$-2139062144, %eax
	je	L247
	testl	$32896, %eax
	jne	L249
	shrl	$16, %eax
	addl	$2, %esi
L249:
	addb	%al, %al
	movl	%ebx, (%esp)
	sbbl	$3, %esi
	call	_strlen
	subl	$_dir.2652, %esi
	movl	%eax, %edx
	leal	1(%esi,%eax), %eax
	cmpl	$260, %eax
	ja	L256
	leal	79(%esp), %edi
	movl	%esi, 8(%esp)
	movl	$_dir.2652, 4(%esp)
	movl	%edi, (%esp)
	movl	%edx, 20(%esp)
	call	_memcpy
	movb	$47, (%edi,%esi)
	leal	1(%edi,%esi), %eax
	movl	20(%esp), %edx
	movl	%ebx, 4(%esp)
	incl	%edx
	movl	%eax, (%esp)
	movl	%edx, 8(%esp)
	movl	%edi, %ebx
	call	_memcpy
L241:
	movl	$4, 4(%esp)
	movl	%ebx, (%esp)
	call	___open
	movl	%eax, %esi
	cmpl	$-1, %eax
	je	L416
	leal	7220(%esp), %ebx
	movl	$9324, 8(%esp)
	movl	%ebx, 4(%esp)
	movl	%eax, (%esp)
	call	___read
	movl	%esi, (%esp)
	movl	%eax, 56(%esp)
	call	___close
	testl	%eax, %eax
	jne	L256
	cmpl	$43, 56(%esp)
	jle	L256
L257:
	movb	7240(%esp), %dl
	leal	7244(%esp), %esi
	movsbl	%dl, %eax
	sarl	$31, %eax
	movl	%eax, 44(%esp)
	leal	7240(%esp), %eax
	movl	44(%esp), %ecx
	incl	%eax
	movl	%ecx, %edi
	xorl	%ecx, %ecx
	sall	$8, %edi
	movb	%dl, %cl
	orl	%edi, %ecx
	cmpl	%esi, %eax
	je	L259
L417:
	movb	(%eax), %dl
	movl	%ecx, %edi
	xorl	%ecx, %ecx
	incl	%eax
	sall	$8, %edi
	movb	%dl, %cl
	orl	%edi, %ecx
	cmpl	%esi, %eax
	jne	L417
L259:
	movb	7244(%esp), %dl
	movl	%ecx, 44(%esp)
	movsbl	%dl, %ecx
	sarl	$31, %ecx
	leal	28(%ebx), %esi
	movl	%ecx, %edi
	movl	%ecx, 48(%esp)
	xorl	%ecx, %ecx
	incl	%eax
	sall	$8, %edi
	movb	%dl, %cl
	orl	%edi, %ecx
	cmpl	%esi, %eax
	je	L262
L418:
	movb	(%eax), %dl
	movl	%ecx, %edi
	xorl	%ecx, %ecx
	incl	%eax
	sall	$8, %edi
	movb	%dl, %cl
	orl	%edi, %ecx
	cmpl	%esi, %eax
	jne	L418
L262:
	movb	7248(%esp), %dl
	movl	%ecx, 48(%esp)
	movsbl	%dl, %edi
	sarl	$31, %edi
	leal	7248(%esp), %eax
	movl	%edi, %ecx
	leal	32(%ebx), %esi
	movl	%ecx, %edi
	xorl	%ecx, %ecx
	sall	$8, %edi
	movb	%dl, %cl
	incl	%eax
	orl	%edi, %ecx
	cmpl	%esi, %eax
	je	L265
L419:
	movb	(%eax), %dl
	movl	%ecx, %edi
	xorl	%ecx, %ecx
	incl	%eax
	sall	$8, %edi
	movb	%dl, %cl
	orl	%edi, %ecx
	cmpl	%esi, %eax
	jne	L419
L265:
	movb	7252(%esp), %dl
	movl	%ecx, 40(%esp)
	movsbl	%dl, %eax
	sarl	$31, %eax
	movl	%ecx, 0(%ebp)
	movl	%eax, 32(%esp)
	leal	7252(%esp), %eax
	movl	32(%esp), %ecx
	leal	36(%ebx), %esi
	movl	%ecx, %edi
	xorl	%ecx, %ecx
	sall	$8, %edi
	movb	%dl, %cl
	incl	%eax
	orl	%edi, %ecx
	cmpl	%esi, %eax
	je	L268
L420:
	movb	(%eax), %dl
	movl	%ecx, %edi
	xorl	%ecx, %ecx
	incl	%eax
	sall	$8, %edi
	movb	%dl, %cl
	orl	%edi, %ecx
	cmpl	%esi, %eax
	jne	L420
L268:
	movb	7256(%esp), %dl
	movl	%ecx, 32(%esp)
	movl	%ecx, 4(%ebp)
	leal	7256(%esp), %eax
	movsbl	%dl, %ecx
	sarl	$31, %ecx
	leal	40(%ebx), %esi
	movl	%ecx, %edi
	movl	%ecx, 28(%esp)
	xorl	%ecx, %ecx
	incl	%eax
	sall	$8, %edi
	movb	%dl, %cl
	orl	%edi, %ecx
	cmpl	%esi, %eax
	je	L271
L421:
	movb	(%eax), %dl
	movl	%ecx, %edi
	xorl	%ecx, %ecx
	incl	%eax
	sall	$8, %edi
	movb	%dl, %cl
	orl	%edi, %ecx
	cmpl	%esi, %eax
	jne	L421
L271:
	movb	7260(%esp), %dl
	movl	%ecx, 28(%esp)
	movsbl	%dl, %edi
	sarl	$31, %edi
	movl	%ecx, 8(%ebp)
	movl	%edi, %ecx
	leal	7260(%esp), %eax
	movl	%ecx, %edi
	xorl	%ecx, %ecx
	sall	$8, %edi
	leal	44(%ebx), %esi
	movb	%dl, %cl
	incl	%eax
	orl	%edi, %ecx
	cmpl	%esi, %eax
	je	L274
L422:
	movb	(%eax), %dl
	movl	%ecx, %edi
	xorl	%ecx, %ecx
	incl	%eax
	sall	$8, %edi
	movb	%dl, %cl
	orl	%edi, %ecx
	cmpl	%esi, %eax
	jne	L422
L274:
	movl	%ecx, 36(%esp)
	movl	%ecx, 12(%ebp)
	cmpl	$50, 40(%esp)
	ja	L256
	movl	28(%esp), %eax
	testl	%eax, %eax
	jle	L256
	cmpl	$10, 28(%esp)
	jg	L256
	movl	32(%esp), %eax
	testl	%eax, %eax
	js	L256
	cmpl	$1200, 32(%esp)
	jg	L256
	testl	%ecx, %ecx
	js	L256
	cmpl	$50, %ecx
	jg	L256
	movl	28(%esp), %eax
	cmpl	%eax, 48(%esp)
	je	L276
	movl	48(%esp), %eax
	testl	%eax, %eax
	jne	L256
L276:
	movl	28(%esp), %edx
	cmpl	%edx, 44(%esp)
	je	L277
	movl	44(%esp), %edi
	testl	%edi, %edi
	jne	L256
L277:
	movl	44(%esp), %edi
	movl	48(%esp), %ecx
	movl	40(%esp), %edx
	movl	36(%esp), %esi
	leal	44(%edi,%ecx), %eax
	movl	32(%esp), %ecx
	movl	28(%esp), %edi
	leal	(%eax,%edx,8), %eax
	addl	%ecx, %eax
	movl	32(%esp), %ecx
	leal	(%edi,%edi,2), %edx
	leal	(%eax,%ecx,4), %eax
	leal	(%eax,%edx,2), %eax
	addl	%esi, %eax
	cmpl	%eax, 56(%esp)
	jl	L256
	testl	%ecx, %ecx
	je	L352
	leal	44(%ebx,%ecx,4), %edi
	leal	24(%ebp), %esi
	leal	7264(%esp), %ecx
	.p2align 4,,7
L281:
	movsbl	(%ecx), %eax
	sarl	$31, %eax
	xorl	%edx, %edx
L280:
	movl	%eax, %ebx
	xorl	%eax, %eax
	sall	$8, %ebx
	movb	(%ecx,%edx), %al
	incl	%edx
	orl	%ebx, %eax
	cmpl	$4, %edx
	jne	L280
	addl	$4, %ecx
	movl	%eax, (%esi)
	addl	$4, %esi
	cmpl	%edi, %ecx
	jne	L281
	movl	32(%esp), %eax
	leal	7264(%esp,%eax,4), %ebx
	xorl	%eax, %eax
	movb	(%ebx), %dl
	leal	1(%ebx), %ecx
	movb	%dl, %al
	movb	%dl, 4824(%ebp)
	cmpl	28(%esp), %eax
	jge	L256
	movl	32(%esp), %edx
	leal	4825(%ebp), %eax
	addl	%edx, %ebx
	movl	28(%esp), %esi
	jmp	L283
	.p2align 4,,7
L284:
	movb	(%ecx), %dl
	incl	%ecx
	movb	%dl, (%eax)
	andl	$255, %edx
	incl	%eax
	cmpl	%esi, %edx
	jge	L256
L283:
	cmpl	%ebx, %ecx
	jne	L284
L278:
	xorl	%esi, %esi
	movl	%ebp, 52(%esp)
	.p2align 4,,7
L287:
	leal	(%esi,%esi,4), %eax
	movl	52(%esp), %edx
	leal	6016(%edx,%eax,4), %ebp
	xorl	%edx, %edx
	movsbl	(%ecx), %eax
	sarl	$31, %eax
	leal	8(%ebp), %edi
L286:
	movl	%eax, %ebx
	xorl	%eax, %eax
	sall	$8, %ebx
	movb	(%ecx,%edx), %al
	incl	%edx
	orl	%ebx, %eax
	cmpl	$4, %edx
	jne	L286
	movl	%eax, 8(%ebp)
	xorl	%eax, %eax
	movb	4(%ecx), %al
	movl	%eax, 4(%edi)
	cmpb	$1, 4(%ecx)
	ja	L256
	xorl	%eax, %eax
	leal	6(%ecx), %edx
	movb	5(%ecx), %al
	movl	%edx, %ecx
	movl	%eax, 8(%edi)
	cmpl	36(%esp), %eax
	jg	L256
	incl	%esi
	cmpl	28(%esp), %esi
	jne	L287
	movl	36(%esp), %eax
	movl	52(%esp), %ebp
	testl	%eax, %eax
	je	L288
	xorl	%eax, %eax
	movl	36(%esp), %ecx
	.p2align 4,,7
L289:
	movb	(%edx,%eax), %bl
	movb	%bl, 6224(%ebp,%eax)
	incl	%eax
	cmpl	%ecx, %eax
	jne	L289
	movl	36(%esp), %ecx
	addl	%edx, %ecx
L288:
	movl	36(%esp), %edi
	movb	$0, 6224(%ebp,%edi)
	movl	40(%esp), %edi
	testl	%edi, %edi
	je	L290
	movl	%ecx, %esi
	xorl	%edi, %edi
	movl	%ecx, 36(%esp)
L295:
	leal	(%edi,%edi,2), %eax
	xorl	%edx, %edx
	leal	6272(%ebp,%eax,4), %ebx
	leal	4(%ebx), %eax
	movl	%eax, 24(%esp)
	movsbl	(%esi), %eax
	sarl	$31, %eax
L292:
	movl	%eax, %ecx
	xorl	%eax, %eax
	sall	$8, %ecx
	movb	(%esi,%edx), %al
	incl	%edx
	orl	%ecx, %eax
	cmpl	$4, %edx
	jne	L292
	movl	%eax, 4(%ebx)
	xorb	%dl, %dl
	movsbl	4(%esi), %eax
	sarl	$31, %eax
L294:
	movl	%eax, %ecx
	xorl	%eax, %eax
	sall	$8, %ecx
	movb	4(%esi,%edx), %al
	incl	%edx
	orl	%ecx, %eax
	cmpl	$4, %edx
	jne	L294
	movl	24(%esp), %edx
	movl	%eax, %ecx
	sarl	$31, %ecx
	incl	%edi
	addl	$8, %esi
	movl	%eax, 4(%edx)
	movl	%ecx, 8(%edx)
	cmpl	40(%esp), %edi
	jne	L295
	movl	36(%esp), %ecx
	leal	(%ecx,%edi,8), %ecx
L290:
	xorl	%ebx, %ebx
	movl	48(%esp), %edx
	jmp	L298
L424:
	movl	$0, 12(%eax)
L297:
	incl	%ebx
	cmpl	28(%esp), %ebx
	jge	L423
L298:
	leal	(%ebx,%ebx,4), %eax
	testl	%edx, %edx
	leal	6024(%ebp,%eax,4), %eax
	je	L424
	movsbl	(%ecx), %esi
	incl	%ecx
	movl	%esi, 12(%eax)
	cmpl	$1, %esi
	jbe	L297
L256:
	orl	$-1, %eax
L406:
	addl	$16556, %esp
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
L416:
	.cfi_restore_state
	movl	$47, 4(%esp)
	movl	%ebx, (%esp)
	call	_strrchr
	movl	$92, 4(%esp)
	movl	%ebx, (%esp)
	movl	%eax, %edi
	call	_strrchr
	testl	%eax, %eax
	je	L253
	cmpl	%edi, %eax
	ja	L343
	testl	%edi, %edi
	je	L343
L253:
	testl	%edi, %edi
	je	L425
L341:
	leal	1(%edi), %esi
L255:
	movl	$LC1, %edi
	movl	$11, %ecx
	repe cmpsb
	jne	L256
	leal	7220(%esp), %ebx
	movl	$1267, 8(%esp)
	movl	$__posixrules_data, 4(%esp)
	movl	%ebx, (%esp)
	call	_memcpy
	movl	$0, 56(%esp)
	jmp	L257
L343:
	movl	%eax, %edi
	jmp	L341
L415:
	movb	1(%ebx), %al
	incl	%ebx
	jmp	L240
L242:
	cmpb	$0, _dir.2652
	jne	L244
	jmp	L243
	.p2align 4,,7
L414:
	movl	$LC2, %ebx
	jmp	L239
L425:
	movl	%ebx, %esi
	cmpb	$58, 1(%ebx)
	jne	L255
	movl	%ebx, %edi
	incl	%edi
	je	L255
	jmp	L341
	.p2align 4,,7
L423:
	xorl	%ebx, %ebx
	movl	44(%esp), %esi
	jmp	L301
L427:
	movl	$0, 16(%eax)
L300:
	incl	%ebx
	cmpl	28(%esp), %ebx
	jge	L426
L301:
	leal	(%ebx,%ebx,4), %eax
	testl	%esi, %esi
	leal	6024(%ebp,%eax,4), %eax
	je	L427
	movsbl	(%ecx), %edx
	incl	%ecx
	movl	%edx, 16(%eax)
	cmpl	$1, %edx
	jbe	L300
	jmp	L256
L426:
	movl	32(%esp), %esi
	testl	%esi, %esi
	je	L302
	movl	32(%esp), %ecx
	leal	24(%ebp), %eax
	decl	%ecx
	xorl	%edx, %edx
	jmp	L309
	.p2align 4,,7
L305:
	incl	%edx
	addl	$4, %eax
	cmpl	32(%esp), %edx
	je	L302
L309:
	cmpl	%ecx, %edx
	jge	L303
	movl	4(%eax), %ebx
	cmpl	%ebx, (%eax)
	ja	L304
L303:
	cmpl	%ecx, %edx
	jne	L305
	movl	(%eax), %ebx
	testl	%ebx, %ebx
	jns	L305
L304:
	movl	$0, 24(%ebp,%edx,4)
	cmpl	%edx, 32(%esp)
	jle	L358
	movl	%edx, %ecx
	movl	%ebp, %edi
	negl	%ecx
	leal	1(%edx), %eax
	movl	%edx, %ebx
	leal	0(%ebp,%ecx,4), %esi
	subl	%edx, %edi
	xorl	%ecx, %ecx
	jmp	L308
	.p2align 4,,7
L307:
	movl	24(%ebp,%eax,4), %ecx
	incl	%eax
L308:
	movl	%ecx, 20(%esi,%eax,4)
	cmpl	%eax, 32(%esp)
	movb	4824(%ebp,%ebx), %bl
	movb	%bl, 4823(%edi,%eax)
	movl	%eax, %ebx
	jne	L307
	movl	32(%esp), %eax
	subl	%edx, %eax
L306:
	movl	%eax, 4(%ebp)
L302:
	cmpl	$2, 56(%esp)
	jle	L413
	movl	60(%esp), %eax
	testl	%eax, %eax
	je	L413
	cmpb	$10, 7220(%esp)
	je	L313
L413:
	movl	8(%ebp), %edx
	movl	4(%ebp), %eax
L312:
	testl	%edx, %edx
	jle	L362
	movb	4824(%ebp), %bl
	leal	4825(%ebp), %ecx
	leal	4824(%ebp,%edx), %esi
	testb	%bl, %bl
	jne	L332
	jmp	L330
	.p2align 4,,7
L333:
	incl	%ecx
	cmpb	$0, -1(%ecx)
	je	L330
L332:
	cmpl	%esi, %ecx
	jne	L333
L362:
	xorl	%eax, %eax
L339:
	movl	%eax, 6876(%ebp)
	xorl	%eax, %eax
	jmp	L406
L330:
	testl	%eax, %eax
	jle	L335
	xorl	%eax, %eax
	movb	%bl, %al
	leal	(%eax,%eax,4), %ecx
	movl	6028(%ebp,%ecx,4), %edi
	testl	%edi, %edi
	je	L335
	leal	-1(%eax), %ecx
	leal	(%ecx,%ecx,4), %eax
	leal	6028(%ebp,%eax,4), %ebx
	jmp	L336
	.p2align 4,,7
L337:
	subl	$20, %ebx
	movl	20(%ebx), %esi
	testl	%esi, %esi
	je	L339
	decl	%ecx
L336:
	movl	%ecx, %eax
	cmpl	$-1, %ecx
	jne	L337
L335:
	movl	%ebp, %ecx
	xorl	%eax, %eax
L338:
	movl	6028(%ecx), %ebx
	testl	%ebx, %ebx
	je	L339
	incl	%eax
	addl	$20, %ecx
	cmpl	%edx, %eax
	jne	L338
	jmp	L362
L245:
	movl	$LC4, (%esp)
	call	_getenv
	movl	%eax, _cp.2651
	testl	%eax, %eax
	je	L246
	movl	%eax, 4(%esp)
	movl	$_dir.2652, (%esp)
	call	_stpcpy
	movl	$1852799535, (%eax)
	movl	$1718511973, 4(%eax)
	movw	$111, 8(%eax)
	jmp	L244
L352:
	leal	7264(%esp), %ecx
	jmp	L278
L246:
	movw	$12078, _dir.2652
	movb	$0, _dir.2652+2
	jmp	L244
L358:
	xorl	%eax, %eax
	jmp	L306
L313:
	movl	56(%esp), %eax
	decl	%eax
	cmpb	$10, 7220(%esp,%eax)
	jne	L413
	cmpl	$8, 28(%esp)
	jg	L413
	movb	$0, 7220(%esp,%eax)
	xorl	%ecx, %ecx
	leal	340(%esp), %edx
	leal	7221(%esp), %eax
	call	_tzparse
	testl	%eax, %eax
	jne	L413
	cmpl	$2, 348(%esp)
	jne	L413
	movl	12(%ebp), %edx
	movl	352(%esp), %ecx
	leal	(%edx,%ecx), %eax
	cmpl	$50, %eax
	jg	L413
	movl	6372(%esp), %eax
	addl	%edx, %eax
	movl	%eax, 6372(%esp)
	movl	6392(%esp), %eax
	addl	%edx, %eax
	testl	%ecx, %ecx
	movl	%eax, 6392(%esp)
	jle	L323
	xorl	%eax, %eax
	leal	0(%ebp,%edx), %ebx
	movl	%ecx, %esi
L320:
	movb	6564(%esp,%eax), %cl
	movb	%cl, 6224(%ebx,%eax)
	incl	%eax
	cmpl	%esi, %eax
	jne	L320
	leal	(%edx,%eax), %eax
	movl	%eax, 12(%ebp)
L323:
	movl	344(%esp), %ecx
	testl	%ecx, %ecx
	jle	L428
	movl	4(%ebp), %eax
	xorl	%edx, %edx
	movl	20(%ebp,%eax,4), %ebx
	cmpl	%ebx, 364(%esp)
	ja	L325
L326:
	incl	%edx
	cmpl	%ecx, %edx
	je	L324
	cmpl	%ebx, 364(%esp,%edx,4)
	jbe	L326
L325:
	cmpl	$1199, %eax
	jg	L324
	subl	%eax, %edx
	leal	340(%esp), %edi
	addl	%edx, %edi
	movl	%ecx, 24(%esp)
	movzbl	8(%ebp), %esi
	leal	340(%esp,%edx,4), %ebx
	movl	%edi, 28(%esp)
L328:
	movl	28(%esp), %ecx
	movl	24(%ebx,%eax,4), %edi
	movl	%edi, 24(%ebp,%eax,4)
	movb	4824(%eax,%ecx), %cl
	leal	(%esi,%ecx), %edi
	movl	%edi, %ecx
	movb	%cl, 4824(%ebp,%eax)
	incl	%eax
	leal	(%edx,%eax), %edi
	cmpl	%edi, 24(%esp)
	jle	L429
	cmpl	$1200, %eax
	jne	L328
	movl	$1200, 4(%ebp)
L324:
	movl	8(%ebp), %edx
	movl	6364(%esp), %ebx
	leal	(%edx,%edx,4), %ecx
	leal	6016(%ebp,%ecx,4), %ecx
	movl	%ebx, 8(%ecx)
	movl	6368(%esp), %ebx
	movl	%ebx, 12(%ecx)
	movl	6372(%esp), %ebx
	movl	%ebx, 16(%ecx)
	movl	6376(%esp), %ebx
	movl	%ebx, 20(%ecx)
	movl	6380(%esp), %ebx
	movl	%ebx, 24(%ecx)
	leal	5(%edx,%edx,4), %ecx
	movl	6384(%esp), %ebx
	addl	$2, %edx
	leal	6016(%ebp,%ecx,4), %ecx
	movl	%edx, 8(%ebp)
	movl	%ebx, 8(%ecx)
	movl	6388(%esp), %ebx
	movl	%ebx, 12(%ecx)
	movl	6392(%esp), %ebx
	movl	%ebx, 16(%ecx)
	movl	6396(%esp), %ebx
	movl	%ebx, 20(%ecx)
	movl	6400(%esp), %ebx
	movl	%ebx, 24(%ecx)
	jmp	L312
L428:
	movl	4(%ebp), %eax
	jmp	L324
L429:
	movl	%eax, 4(%ebp)
	jmp	L324
	.cfi_endproc
LFE5:
	.p2align 2
LC5:
	.ascii "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 :+-._\0"
	.p2align 2
LC6:
	.ascii "Local time zone must be set--see zic manual page\0"
	.p2align 4,,15
_settzname:
LFB2:
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
	subl	$44, %esp
	.cfi_def_cfa_offset 64
	movl	$_wildabbr, _tzname
	movl	_lclmem+8, %eax
	movl	$_wildabbr, _tzname+4
	movl	%eax, 28(%esp)
	xorl	%eax, %eax
	movl	28(%esp), %edx
	testl	%edx, %edx
	jle	L434
	.p2align 4,,7
L448:
	leal	(%eax,%eax,4), %edx
	incl	%eax
	leal	_lclmem+6024(,%edx,4), %edx
	movl	4(%edx), %ecx
	movl	8(%edx), %edx
	addl	$_lclmem+6224, %edx
	cmpl	28(%esp), %eax
	movl	%edx, _tzname(,%ecx,4)
	jne	L448
L434:
	movl	_lclmem+4, %ebx
	testl	%ebx, %ebx
	jle	L433
	xorl	%eax, %eax
	.p2align 4,,7
L432:
	xorl	%edx, %edx
	movb	_lclmem+4824(%eax), %dl
	incl	%eax
	leal	(%edx,%edx,4), %edx
	leal	_lclmem+6024(,%edx,4), %edx
	movl	4(%edx), %ecx
	movl	8(%edx), %edx
	addl	$_lclmem+6224, %edx
	cmpl	%ebx, %eax
	movl	%edx, _tzname(,%ecx,4)
	jne	L432
L433:
	movl	_lclmem+12, %esi
	testl	%esi, %esi
	jle	L436
	xorl	%ebx, %ebx
	jmp	L435
	.p2align 4,,7
L439:
	incl	%ebx
	cmpl	%esi, %ebx
	je	L436
L435:
	movsbl	_lclmem+6224(%ebx), %eax
	movl	$LC5, (%esp)
	movl	%eax, 4(%esp)
	call	_strchr
	testl	%eax, %eax
	jne	L439
	movb	$95, _lclmem+6224(%ebx)
	incl	%ebx
	cmpl	%esi, %ebx
	jne	L435
	.p2align 4,,7
L436:
	movl	28(%esp), %eax
	xorl	%ebx, %ebx
	testl	%eax, %eax
	jle	L430
	.p2align 4,,7
L447:
	leal	(%ebx,%ebx,4), %eax
	movl	_lclmem+6032(,%eax,4), %ebp
	addl	$_lclmem+6224, %ebp
	movl	%ebp, (%esp)
	call	_strlen
	cmpl	$16, %eax
	jbe	L440
	movl	$LC6, %edi
	movl	%ebp, %esi
	movl	$49, %ecx
	repe cmpsb
	je	L440
	movb	$0, 16(%ebp)
L440:
	incl	%ebx
	cmpl	28(%esp), %ebx
	jne	L447
L430:
	addl	$44, %esp
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
	.cfi_endproc
LFE2:
	.section	.text.unlikely,"x"
_tmcomp:
LFB34:
	.cfi_startproc
	movl	20(%eax), %ecx
	subl	20(%edx), %ecx
	jne	L456
	movl	16(%eax), %ecx
	subl	16(%edx), %ecx
	jne	L456
	movl	12(%eax), %ecx
	subl	12(%edx), %ecx
	jne	L456
	movl	8(%eax), %ecx
	subl	8(%edx), %ecx
	jne	L456
	movl	4(%eax), %ecx
	subl	4(%edx), %ecx
	jne	L456
	movl	(%eax), %ecx
	subl	(%edx), %ecx
L456:
	movl	%ecx, %eax
	ret
	.cfi_endproc
LFE34:
	.section .text
	.p2align 4,,15
_gmtload:
LFB15:
	.cfi_startproc
	pushl	%ebx
	.cfi_def_cfa_offset 8
	.cfi_offset 3, -8
	movl	%eax, %edx
	subl	$8, %esp
	.cfi_def_cfa_offset 16
	movl	%eax, %ebx
	movl	$1, %ecx
	movl	$_gmt, %eax
	call	_tzload
	testl	%eax, %eax
	jne	L461
	addl	$8, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 8
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L461:
	.cfi_restore_state
	addl	$8, %esp
	.cfi_def_cfa_offset 8
	movl	%ebx, %edx
	movl	$1, %ecx
	movl	$_gmt, %eax
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 4
	jmp	_tzparse
	.cfi_endproc
LFE15:
	.p2align 4,,15
_leaps_thru_end_of:
LFB24:
	.cfi_startproc
	pushl	%esi
	.cfi_def_cfa_offset 8
	.cfi_offset 6, -8
	pushl	%ebx
	.cfi_def_cfa_offset 12
	.cfi_offset 3, -12
	testl	%eax, %eax
	pushl	%ecx
	.cfi_def_cfa_offset 16
	movl	%eax, %ecx
	js	L463
	movl	$1374389535, %edx
	movl	%eax, %ebx
	imull	%edx
	sarl	$31, %ecx
	movl	%edx, %eax
	sarl	$5, %eax
	movl	%ecx, %esi
	sarl	$2, %ebx
	subl	%eax, %esi
	sarl	$7, %edx
	movl	%esi, %eax
	addl	%ebx, %eax
	subl	%ecx, %edx
	addl	%edx, %eax
	popl	%edx
	.cfi_remember_state
	.cfi_def_cfa_offset 12
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 8
	popl	%esi
	.cfi_restore 6
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L463:
	.cfi_restore_state
	xorl	$-1, %eax
	call	_leaps_thru_end_of
	popl	%edx
	.cfi_def_cfa_offset 12
	xorl	$-1, %eax
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 8
	popl	%esi
	.cfi_restore 6
	.cfi_def_cfa_offset 4
	ret
	.cfi_endproc
LFE24:
	.p2align 4,,15
_timesub.isra.2:
LFB41:
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
	subl	$60, %esp
	.cfi_def_cfa_offset 80
	movl	%eax, 28(%esp)
	movl	%edx, 40(%esp)
	movl	(%ecx), %eax
	movl	28(%esp), %edi
	jmp	L467
	.p2align 4,,7
L515:
	movl	%ebx, %eax
L467:
	movl	%eax, %ebx
	decl	%ebx
	js	L547
	leal	(%ebx,%ebx,2), %edx
	leal	6272(%ecx,%edx,4), %edx
	leal	4(%edx), %esi
	cmpl	%edi, 4(%edx)
	ja	L515
	je	L468
	movl	4(%esi), %ecx
	movl	8(%esi), %ebx
	movl	%ecx, 32(%esp)
	movl	%ebx, 36(%esp)
	movl	$0, 44(%esp)
L477:
	movl	$-1037155065, %ecx
	movl	28(%esp), %eax
	mull	%ecx
	movl	$1970, %ebx
	movl	$1970, 24(%esp)
	shrl	$16, %edx
	movl	%edx, 16(%esp)
	movl	%edx, %esi
	testb	$3, %bl
	jne	L483
	.p2align 4,,7
L549:
	movl	%ebx, %edx
	movl	%ebx, %eax
	sarl	$31, %edx
	movl	$100, %ecx
	idivl	%ecx
	testl	%edx, %edx
	movl	$1, %eax
	jne	L484
L483:
	movl	%ebx, %edx
	movl	%ebx, %eax
	sarl	$31, %edx
	movl	$400, %edi
	idivl	%edi
	testl	%edx, %edx
	sete	%al
	andl	$255, %eax
L484:
	cmpl	_year_lengths(,%eax,4), %esi
	jb	L548
	movl	$-1290837165, %edx
	movl	%esi, %eax
	mull	%edx
	shrl	$8, %edx
	jne	L480
	movl	$1, %edx
L480:
	movl	$2147483647, %eax
	subl	%ebx, %eax
	cmpl	%edx, %eax
	jl	L494
	leal	(%ebx,%edx), %edi
	leal	-1(%edi), %eax
	call	_leaps_thru_end_of
	movl	%eax, %ebp
	leal	-1(%ebx), %eax
	call	_leaps_thru_end_of
	movl	%edi, %edx
	subl	%ebx, %edx
	subl	%eax, %ebp
	movl	%edi, %ebx
	leal	(%edx,%edx,8), %ecx
	leal	(%edx,%ecx,8), %edx
	leal	(%edx,%edx,4), %edx
	subl	%edx, %esi
	subl	%ebp, %esi
	testb	$3, %bl
	jne	L483
	jmp	L549
	.p2align 4,,7
L548:
	leal	(%esi,%esi,2), %edx
	movl	28(%esp), %esi
	movl	%edx, %eax
	xorl	%edi, %edi
	sall	$4, %eax
	movl	%ebx, 24(%esp)
	subl	%edx, %eax
	movl	$-1037155065, %edx
	movl	%eax, %ecx
	sall	$4, %ecx
	subl	%eax, %ecx
	sall	$7, %ecx
	movl	%ecx, %eax
	imull	%edx
	movl	%ecx, %eax
	sarl	$31, %eax
	leal	(%edx,%ecx), %ebp
	sarl	$16, %ebp
	movl	16(%esp), %edx
	subl	%eax, %ebp
	leal	(%edx,%edx,2), %eax
	movl	%eax, %edx
	sall	$4, %edx
	subl	%eax, %edx
	movl	%edx, %eax
	sall	$4, %eax
	subl	%edx, %eax
	sall	$7, %eax
	subl	%eax, %esi
	leal	0(%ebp,%ebp,2), %eax
	movl	%eax, %edx
	sall	$4, %edx
	subl	%eax, %edx
	movl	%edx, %eax
	sall	$4, %eax
	subl	%edx, %eax
	xorl	%edx, %edx
	sall	$7, %eax
	subl	%eax, %ecx
	movl	40(%esp), %eax
	addl	%ecx, %esi
	movl	%eax, %ecx
	adcl	%edx, %edi
	movl	%eax, %edx
	sarl	$31, %edx
	subl	32(%esp), %ecx
	movl	%edx, %ebx
	sbbl	36(%esp), %ebx
	addl	%ecx, %esi
	adcl	%ebx, %edi
	testl	%edi, %edi
	jns	L526
	movl	24(%esp), %ebx
	.p2align 4,,7
L531:
	addl	$86400, %esi
	adcl	$0, %edi
	decl	%ebp
	testl	%edi, %edi
	js	L531
	movl	%ebx, 24(%esp)
L526:
	testl	%edi, %edi
	jle	L550
L543:
	movl	24(%esp), %ebx
	.p2align 4,,7
L538:
	addl	$-86400, %esi
	adcl	$-1, %edi
	incl	%ebp
	cmpl	$0, %edi
	jg	L538
	jl	L544
	cmpl	$86399, %esi
	ja	L538
L544:
	movl	%ebx, 24(%esp)
L488:
	testl	%ebp, %ebp
	jns	L492
	movl	$-2147483648, %ecx
	movl	24(%esp), %eax
	subl	%eax, %ecx
	movl	%esi, 16(%esp)
	movl	%edi, 20(%esp)
	movl	24(%esp), %ebx
	jmp	L497
	.p2align 4,,7
L493:
	decl	%ebx
	testb	$3, %bl
	jne	L495
	movl	%ebx, %edx
	movl	%ebx, %eax
	sarl	$31, %edx
	movl	$100, %esi
	idivl	%esi
	testl	%edx, %edx
	movl	$1, %eax
	jne	L496
L495:
	movl	%ebx, %edx
	movl	%ebx, %eax
	sarl	$31, %edx
	movl	$400, %edi
	idivl	%edi
	testl	%edx, %edx
	sete	%al
	andl	$255, %eax
L496:
	movl	_year_lengths(,%eax,4), %eax
	incl	%ecx
	addl	%eax, %ebp
	jns	L551
L497:
	testl	%ebx, %ebx
	jns	L493
	testl	%ecx, %ecx
	js	L493
	.p2align 4,,7
L494:
	xorl	%eax, %eax
L539:
	addl	$60, %esp
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
L551:
	.cfi_restore_state
	movl	16(%esp), %esi
	movl	20(%esp), %edi
	movl	%ebx, 24(%esp)
L492:
	movl	24(%esp), %ebx
	movl	$2147483647, %ecx
	subl	%ebx, %ecx
	movl	24(%esp), %ebx
	movl	%esi, 16(%esp)
	movl	%ebx, %esi
	andl	$3, %esi
	movl	%edi, 20(%esp)
	movl	%ebx, %eax
	je	L552
L502:
	movl	%ebx, %edx
	movl	$400, %edi
	sarl	$31, %edx
	idivl	%edi
	testl	%edx, %edx
	sete	%al
	andl	$255, %eax
	movl	_year_lengths(,%eax,4), %edx
	cmpl	%edx, %ebp
	jl	L546
	.p2align 4,,7
L498:
	testl	%ebx, %ebx
	js	L499
	testl	%ecx, %ecx
	setle	%al
L500:
	decl	%ecx
	testb	%al, %al
	jne	L494
	incl	%ebx
	subl	%edx, %ebp
	movl	%ebx, %esi
	movl	%ebx, %eax
	andl	$3, %esi
	jne	L502
L552:
	movl	%ebx, %edx
	movl	$100, %edi
	sarl	$31, %edx
	idivl	%edi
	testl	%edx, %edx
	je	L553
	cmpl	$365, %ebp
	jle	L546
	movl	$366, %edx
	jmp	L498
	.p2align 4,,7
L499:
	leal	1(%ecx), %eax
	decl	%eax
	setg	%al
	jmp	L500
	.p2align 4,,7
L547:
	movl	$0, 44(%esp)
	movl	$0, 32(%esp)
	movl	$0, 36(%esp)
	jmp	L477
	.p2align 4,,7
L468:
	movl	4(%esi), %edi
	movl	8(%esi), %ebp
	movl	%edi, 32(%esp)
	movl	%ebp, 36(%esp)
	testl	%ebx, %ebx
	jne	L472
	cmpl	$0, %ebp
	jle	L554
L518:
	movl	$1, 44(%esp)
	jmp	L477
L554:
	jl	L472
	cmpl	$0, %edi
	ja	L518
	.p2align 4,,7
L472:
	leal	-6(%eax,%eax,2), %eax
	movl	36(%esp), %ebp
	leal	6272(%ecx,%eax,4), %eax
	cmpl	%ebp, 12(%eax)
	jge	L555
L474:
	testl	%ebx, %ebx
	je	L518
	leal	-3(%ebx,%ebx,2), %esi
	leal	(%ebx,%ebx,2), %eax
	sall	$2, %esi
	leal	(%ecx,%eax,4), %edi
	leal	(%ecx,%esi), %eax
	movl	6276(%eax), %edx
	incl	%edx
	cmpl	%edx, 6276(%edi)
	jne	L518
	movl	6284(%eax), %edx
	movl	6280(%eax), %eax
	addl	$1, %eax
	movl	6284(%edi), %ebp
	adcl	$0, %edx
	xorl	%ebp, %edx
	movl	6280(%edi), %ebp
	xorl	%ebp, %eax
	orl	%eax, %edx
	jne	L518
	leal	6280(%ecx,%esi), %ecx
	incl	%ebx
	movl	$2, %esi
	jmp	L476
	.p2align 4,,7
L556:
	movl	-16(%ecx), %eax
	movl	%ecx, %edi
	incl	%eax
	cmpl	%eax, -4(%ecx)
	jne	L542
	movl	-12(%edi), %eax
	incl	%esi
	subl	$12, %ecx
	movl	-8(%edi), %edx
	addl	$1, %eax
	adcl	$0, %edx
	xorl	(%edi), %eax
	xorl	4(%edi), %edx
	orl	%eax, %edx
	jne	L542
L476:
	movl	%esi, %ebp
	cmpl	%ebx, %esi
	jne	L556
L542:
	movl	%ebp, 44(%esp)
	jmp	L477
L550:
	cmpl	$86399, %esi
	jbe	L488
	jmp	L543
L555:
	jle	L557
L525:
	movl	$0, 44(%esp)
	jmp	L477
L557:
	movl	32(%esp), %edx
	cmpl	%edx, 8(%eax)
	jb	L474
	jmp	L525
L546:
	movl	%ebx, 24(%esp)
	movl	80(%esp), %eax
	movl	24(%esp), %edx
	movl	%esi, 28(%esp)
	movl	20(%esp), %edi
	movl	16(%esp), %esi
	movl	%edx, 20(%eax)
	testl	%edx, %edx
	js	L558
L505:
	movl	80(%esp), %ecx
	movl	24(%esp), %eax
	subl	$1900, %eax
	movl	$7, %ebx
	movl	%eax, 20(%ecx)
	movl	24(%esp), %eax
	movl	%ebp, 28(%ecx)
	decl	%eax
	call	_leaps_thru_end_of
	movl	%eax, %ecx
	movl	24(%esp), %eax
	subl	$1970, %eax
	movl	%eax, %edx
	sarl	$31, %edx
	idivl	%ebx
	leal	-473(%ecx,%edx), %eax
	addl	%ebp, %eax
	movl	%eax, %edx
	sarl	$31, %edx
	idivl	%ebx
	testl	%edx, %edx
	js	L506
	movl	80(%esp), %eax
	movl	%edx, 24(%eax)
L507:
	movl	%esi, (%esp)
	movl	%edi, 4(%esp)
	movl	$3600, 8(%esp)
	movl	$0, 12(%esp)
	call	___divdi3
	movl	80(%esp), %ebx
	movl	%eax, 8(%ebx)
	movl	%esi, (%esp)
	movl	%edi, 4(%esp)
	movl	$3600, 8(%esp)
	movl	$0, 12(%esp)
	call	___moddi3
	movl	$60, 8(%esp)
	movl	$0, 12(%esp)
	movl	%eax, (%esp)
	movl	%edx, 4(%esp)
	movl	%eax, %esi
	movl	%edx, %edi
	call	___divdi3
	movl	%eax, 4(%ebx)
	movl	$60, 8(%esp)
	movl	$0, 12(%esp)
	movl	%esi, (%esp)
	movl	%edi, 4(%esp)
	call	___moddi3
	movl	44(%esp), %edx
	addl	%edx, %eax
	movl	28(%esp), %ecx
	movl	%eax, (%ebx)
	testl	%ecx, %ecx
	jne	L508
	movl	24(%esp), %eax
	movl	$100, %ecx
	movl	%eax, %edx
	sarl	$31, %edx
	idivl	%ecx
	testl	%edx, %edx
	movl	$1, %eax
	jne	L509
L508:
	movl	24(%esp), %eax
	movl	$400, %ecx
	movl	%eax, %edx
	sarl	$31, %edx
	idivl	%ecx
	testl	%edx, %edx
	sete	%al
	andl	$255, %eax
L509:
	leal	(%eax,%eax), %edx
	movl	80(%esp), %esi
	addl	%edx, %eax
	sall	$4, %eax
	movl	$0, 16(%esi)
	movl	_mon_lengths(%eax), %edx
	leal	_mon_lengths(%eax), %ecx
	cmpl	%ebp, %edx
	jg	L510
	movl	$1, %eax
	.p2align 4,,7
L511:
	movl	80(%esp), %edi
	subl	%edx, %ebp
	movl	%eax, 16(%edi)
	incl	%eax
	movl	-4(%ecx,%eax,4), %edx
	cmpl	%ebp, %edx
	jle	L511
L510:
	movl	80(%esp), %eax
	incl	%ebp
	movl	40(%esp), %edx
	movl	%ebp, 12(%eax)
	movl	$0, 32(%eax)
	movl	%edx, 40(%eax)
	jmp	L539
L558:
	movl	$-2147483648, %eax
	subl	%edx, %eax
	cmpl	$-1899, %eax
	jge	L494
	jmp	L505
	.p2align 4,,7
L506:
	movl	80(%esp), %ecx
	addl	$7, %edx
	movl	%edx, 24(%ecx)
	jmp	L507
	.p2align 4,,7
L553:
	movl	%ebx, %edx
	movl	%ebx, %eax
	sarl	$31, %edx
	movl	$400, %edi
	idivl	%edi
	testl	%edx, %edx
	sete	%al
	andl	$255, %eax
	cmpl	_year_lengths(,%eax,4), %ebp
	jl	L546
	testl	%edx, %edx
	sete	%al
	andl	$255, %eax
	movl	_year_lengths(,%eax,4), %edx
	jmp	L498
	.cfi_endproc
LFE41:
	.p2align 4,,15
_localsub:
LFB18:
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
	subl	$32, %esp
	.cfi_def_cfa_offset 48
	movl	_lclmem+16, %edx
	movl	48(%esp), %eax
	movl	56(%esp), %esi
	testl	%edx, %edx
	movl	(%eax), %ebx
	je	L560
	movl	_lclmem+24, %edx
	cmpl	%edx, %ebx
	jae	L560
L561:
	leal	-262121088(%ebx), %ecx
	movl	%ecx, 28(%esp)
L565:
	xorl	%eax, %eax
	cmpl	%ecx, %edx
	ja	L569
	movl	_lclmem+4, %edx
	cmpl	%ecx, _lclmem+20(,%edx,4)
	jb	L569
	movl	52(%esp), %eax
	movl	%esi, 8(%esp)
	movl	%eax, 4(%esp)
	leal	28(%esp), %eax
	movl	%eax, (%esp)
	call	_localsub
	cmpl	%esi, %eax
	jne	L569
	movl	20(%esi), %ecx
	cmpl	_lclmem+24, %ebx
	leal	400(%ecx), %edx
	jae	L568
	leal	-400(%ecx), %edx
L568:
	movl	%edx, 20(%eax)
	jmp	L569
	.p2align 4,,7
L560:
	movl	_lclmem+20, %eax
	movl	_lclmem+4, %ecx
	testl	%eax, %eax
	je	L563
	cmpl	_lclmem+20(,%ecx,4), %ebx
	jbe	L563
	movl	_lclmem+24, %edx
	cmpl	%edx, %ebx
	jb	L561
	leal	262121088(%ebx), %ecx
	movl	%ecx, 28(%esp)
	jmp	L565
	.p2align 4,,7
L563:
	testl	%ecx, %ecx
	jne	L586
L570:
	movl	_lclmem+6876, %eax
L572:
	leal	(%eax,%eax,4), %eax
	movl	%esi, (%esp)
	movl	$_lclmem, %ecx
	leal	_lclmem+6016(,%eax,4), %eax
	leal	8(%eax), %edi
	movl	8(%eax), %edx
	movl	%ebx, %eax
	call	_timesub.isra.2
	movl	4(%edi), %ecx
	movl	8(%edi), %edx
	movl	%ecx, 32(%esi)
	addl	$_lclmem+6224, %edx
	movl	%edx, _tzname(,%ecx,4)
	movl	%edx, 36(%esi)
L569:
	addl	$32, %esp
	.cfi_remember_state
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
	.p2align 4,,7
L586:
	.cfi_restore_state
	cmpl	_lclmem+24, %ebx
	jb	L570
	movl	$1, %eax
	.p2align 4,,7
L571:
	cmpl	%eax, %ecx
	jle	L576
	leal	(%ecx,%eax), %edx
	sarl	%edx
	cmpl	_lclmem+24(,%edx,4), %ebx
	jae	L574
L581:
	movl	%edx, %ecx
	cmpl	%edx, %eax
	jge	L576
	addl	%eax, %edx
	sarl	%edx
	cmpl	_lclmem+24(,%edx,4), %ebx
	jb	L581
L574:
	leal	1(%edx), %eax
	jmp	L571
	.p2align 4,,7
L576:
	movb	_lclmem+4823(%eax), %al
	andl	$255, %eax
	jmp	L572
	.cfi_endproc
LFE18:
	.p2align 4,,15
_time2sub.constprop.10:
LFB48:
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
	subl	$156, %esp
	.cfi_def_cfa_offset 176
	movl	%edx, %ebx
	movl	%eax, %esi
	movl	%ecx, %edx
	leal	56(%esp), %ebp
	movl	$0, (%ebx)
	movl	$11, %ecx
	movl	%ebp, %edi
	rep movsl
	movl	%eax, 24(%esp)
	leal	60(%esp), %esi
	testl	%edx, %edx
	je	L591
	movl	$60, %ecx
	movl	%ebp, %edx
	movl	%esi, %eax
	call	_normalize_overflow
	testl	%eax, %eax
	je	L591
L589:
	orl	$-1, %eax
L656:
	addl	$156, %esp
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
L591:
	.cfi_restore_state
	movl	$60, %ecx
	movl	%esi, %edx
	leal	64(%esp), %eax
	call	_normalize_overflow
	testl	%eax, %eax
	jne	L589
	movl	$24, %ecx
	leal	64(%esp), %edx
	leal	68(%esp), %eax
	call	_normalize_overflow
	testl	%eax, %eax
	jne	L589
	movl	72(%esp), %ecx
	movl	76(%esp), %esi
	testl	%ecx, %ecx
	js	L593
	movl	%ecx, %eax
	movl	$715827883, %edx
	imull	%edx
	sarl	%edx
	movl	%ecx, %eax
	sarl	$31, %eax
	subl	%eax, %edx
L594:
	leal	(%edx,%edx,2), %eax
	sall	$2, %eax
	subl	%eax, %ecx
	testl	%esi, %esi
	movl	%ecx, 28(%esp)
	movl	%ecx, 72(%esp)
	js	L595
	movl	$2147483647, %eax
	subl	%esi, %eax
	cmpl	%eax, %edx
	setg	%al
L596:
	testb	%al, %al
	jne	L589
	addl	%esi, %edx
	js	L597
	movl	$2147483647, %eax
	subl	%edx, %eax
	cmpl	$1899, %eax
	jle	L589
L597:
	movl	68(%esp), %ecx
	leal	1900(%edx), %esi
	movl	%ecx, %eax
	testl	%ecx, %ecx
	jg	L598
	movl	$2147481748, %edi
	movl	%ebx, 32(%esp)
	subl	%edx, %edi
	movl	%edi, 36(%esp)
	jmp	L602
L599:
	decl	%esi
	cmpl	$1, 28(%esp)
	setg	%bl
	andl	$255, %ebx
	addl	%esi, %ebx
	testb	$3, %bl
	jne	L600
	movl	%ebx, %edx
	movl	%ebx, %eax
	sarl	$31, %edx
	movl	$100, %edi
	idivl	%edi
	testl	%edx, %edx
	movl	$1, %eax
	jne	L601
L600:
	movl	%ebx, %edx
	movl	%ebx, %eax
	sarl	$31, %edx
	movl	$400, %edi
	idivl	%edi
	testl	%edx, %edx
	sete	%al
	andl	$255, %eax
L601:
	movl	36(%esp), %ebx
	movl	_year_lengths(,%eax,4), %eax
	incl	%ebx
	addl	%eax, %ecx
	movl	%ebx, 36(%esp)
	testl	%ecx, %ecx
	jg	L659
L602:
	testl	%esi, %esi
	jns	L599
	movl	36(%esp), %edi
	testl	%edi, %edi
	jns	L589
	jmp	L599
	.p2align 4,,7
L595:
	movl	$-2147483648, %eax
	subl	%esi, %eax
	cmpl	%eax, %edx
	setl	%al
	jmp	L596
L593:
	movl	%ecx, %edi
	movl	$715827883, %edx
	xorl	$-1, %edi
	movl	%edi, %eax
	imull	%edx
	sarl	$31, %edi
	sarl	%edx
	subl	%edi, %edx
	xorl	$-1, %edx
	jmp	L594
L659:
	movl	32(%esp), %ebx
	movl	%ecx, %eax
L598:
	movl	%eax, %edi
	cmpl	$366, %eax
	jle	L607
	cmpl	$1, 28(%esp)
	movl	$2147483647, %ecx
	movl	%ebx, 32(%esp)
	setg	%al
	andl	$255, %eax
	subl	%esi, %ecx
	movl	%eax, 28(%esp)
	movl	%ecx, 40(%esp)
L606:
	movl	28(%esp), %ebx
	addl	%esi, %ebx
	testb	$3, %bl
	jne	L603
	movl	%ebx, %edx
	movl	$100, %ecx
	sarl	$31, %edx
	movl	%ebx, %eax
	idivl	%ecx
	testl	%edx, %edx
	movl	$1, %eax
	jne	L604
L603:
	movl	%ebx, %edx
	movl	%ebx, %eax
	sarl	$31, %edx
	movl	$400, %ecx
	idivl	%ecx
	testl	%edx, %edx
	sete	%al
	andl	$255, %eax
L604:
	movl	_year_lengths(,%eax,4), %edx
	subl	%edx, %edi
	testl	%esi, %esi
	js	L605
	movl	40(%esp), %ebx
	testl	%ebx, %ebx
	jle	L589
L605:
	movl	40(%esp), %ecx
	incl	%esi
	decl	%ecx
	cmpl	$366, %edi
	movl	%ecx, 40(%esp)
	jg	L606
	movl	32(%esp), %ebx
	movl	%edi, %eax
L607:
	movl	$2147483647, 28(%esp)
	movl	%eax, %ecx
	subl	%esi, 28(%esp)
	movl	72(%esp), %edi
	movl	%ebx, 40(%esp)
L612:
	movl	%esi, %ebx
	movl	%esi, %edx
	andl	$3, %ebx
	movl	%esi, %eax
	sarl	$31, %edx
	movl	%ebx, 44(%esp)
	movl	$100, %ebx
	idivl	%ebx
	movl	%edx, 36(%esp)
	movl	%esi, %edx
	movw	$400, %bx
	movl	%esi, %eax
	sarl	$31, %edx
	idivl	%ebx
	testl	%edx, %edx
	movl	44(%esp), %ebx
	sete	%al
	andl	$255, %eax
	movl	%eax, 32(%esp)
L610:
	movl	32(%esp), %eax
	testl	%ebx, %ebx
	jne	L608
	movl	36(%esp), %edx
	movl	$1, %eax
	testl	%edx, %edx
	jne	L608
	movl	32(%esp), %eax
L608:
	leal	(%eax,%eax), %edx
	addl	%edx, %eax
	leal	(%edi,%eax,4), %eax
	movl	_mon_lengths(,%eax,4), %eax
	cmpl	%ecx, %eax
	jge	L609
	incl	%edi
	subl	%eax, %ecx
	cmpl	$11, %edi
	jle	L610
	testl	%esi, %esi
	js	L611
	cmpl	$0, 28(%esp)
	jle	L589
L611:
	incl	%esi
	decl	28(%esp)
	xorl	%edi, %edi
	jmp	L612
L609:
	movl	40(%esp), %ebx
	movl	%ecx, 68(%esp)
	movl	%edi, 72(%esp)
	testl	%esi, %esi
	js	L660
L613:
	movl	56(%esp), %ecx
	leal	-1900(%esi), %eax
	movl	%eax, 76(%esp)
	movl	%ecx, 28(%esp)
	cmpl	$59, %ecx
	jbe	L644
	cmpl	$69, %eax
	jg	L615
	testl	%ecx, %ecx
	js	L661
L616:
	subl	$59, 28(%esp)
	movl	$59, 56(%esp)
L614:
	orl	$-1, %edi
	xorl	%esi, %esi
L657:
	movl	%edi, %edx
	movl	%esi, %eax
	shrl	%edx
	shrl	%eax
	addl	%edx, %eax
	cmpl	%eax, %esi
	jbe	L618
	movl	%esi, 52(%esp)
L619:
	leal	100(%esp), %eax
	leal	52(%esp), %edx
	movl	%eax, 8(%esp)
	movl	$0, 4(%esp)
	movl	%edx, (%esp)
	call	_localsub
	testl	%eax, %eax
	je	L662
	movl	%ebp, %edx
	leal	100(%esp), %eax
	call	_tmcomp
	testl	%eax, %eax
	je	L624
L638:
	movl	52(%esp), %edx
	cmpl	%edx, %esi
	je	L663
	cmpl	%edx, %edi
	je	L664
L626:
	cmpl	%edi, %esi
	ja	L589
	testl	%eax, %eax
	jle	L627
	movl	52(%esp), %edi
	jmp	L657
L644:
	movl	$0, 28(%esp)
	jmp	L614
L660:
	movl	$-2147483648, %eax
	subl	%esi, %eax
	cmpl	$-1899, %eax
	jge	L589
	jmp	L613
L627:
	movl	52(%esp), %esi
	jmp	L657
L664:
	leal	-1(%edi), %edx
	movl	%edx, 52(%esp)
	cmpl	%edx, %edi
	jbe	L589
	movl	%edx, %edi
	jmp	L626
L663:
	leal	1(%esi), %edx
	movl	%edx, 52(%esp)
	cmpl	%edx, %esi
	jae	L589
	movl	%edx, %esi
	jmp	L626
L624:
	movl	88(%esp), %eax
	testl	%eax, %eax
	js	L629
	cmpl	132(%esp), %eax
	je	L629
	movl	_lclmem+8, %eax
	xorl	%edi, %edi
	movl	%ebx, 44(%esp)
	leal	-1(%eax), %ecx
	imull	$20, %eax, %eax
	movl	%ecx, 32(%esp)
	movl	%eax, 36(%esp)
L630:
	cmpl	$0, 32(%esp)
	js	L589
	movl	36(%esp), %ebx
	movl	88(%esp), %eax
	cmpl	%eax, _lclmem+6008(%ebx,%edi)
	je	L631
L635:
	decl	32(%esp)
	subl	$20, %edi
	jmp	L630
L662:
	cmpl	$1, 52(%esp)
	sbbl	%eax, %eax
	orl	$1, %eax
	jmp	L638
L618:
	cmpl	%eax, %edi
	jb	L620
	movl	%eax, 52(%esp)
	jmp	L619
L661:
	movl	$-2147483648, %eax
	subl	%ecx, %eax
	cmpl	$-58, %eax
	jge	L589
	jmp	L616
L631:
	movl	_lclmem+8, %ebx
	decl	%ebx
	imull	$20, %ebx, %esi
	addl	$_lclmem+6028, %esi
L632:
	testl	%ebx, %ebx
	js	L635
	movl	88(%esp), %edx
	cmpl	%edx, (%esi)
	je	L633
	movl	36(%esp), %ecx
	movl	52(%esp), %eax
	leal	48(%esp), %edx
	subl	_lclmem+6004(%ecx,%edi), %eax
	addl	-4(%esi), %eax
	movl	$0, 4(%esp)
	movl	%eax, 48(%esp)
	leal	100(%esp), %eax
	movl	%eax, 8(%esp)
	movl	%edx, (%esp)
	call	_localsub
	testl	%eax, %eax
	je	L633
	movl	%ebp, %edx
	leal	100(%esp), %eax
	call	_tmcomp
	testl	%eax, %eax
	jne	L633
	movl	88(%esp), %ecx
	cmpl	%ecx, 132(%esp)
	je	L665
L633:
	decl	%ebx
	subl	$20, %esi
	jmp	L632
L615:
	movl	$0, 56(%esp)
	jmp	L614
L620:
	movl	%edi, 52(%esp)
	jmp	L619
L665:
	movl	48(%esp), %eax
	movl	44(%esp), %ebx
	movl	%eax, 52(%esp)
L629:
	movl	52(%esp), %eax
	movl	28(%esp), %edx
	addl	%eax, %edx
	movl	28(%esp), %ecx
	cmpl	%edx, %eax
	movl	%edx, 48(%esp)
	seta	%al
	shrl	$31, %ecx
	cmpb	%cl, %al
	jne	L589
	movl	24(%esp), %edi
	leal	52(%esp), %eax
	movl	%edi, 8(%esp)
	movl	$0, 4(%esp)
	movl	%eax, (%esp)
	movl	%edx, 52(%esp)
	call	_localsub
	movl	$1, %edx
	testl	%eax, %eax
	jne	L637
	movl	(%ebx), %edx
L637:
	movl	%edx, (%ebx)
	movl	52(%esp), %eax
	jmp	L656
	.cfi_endproc
LFE48:
	.p2align 4,,15
_time2.constprop.8:
LFB50:
	.cfi_startproc
	pushl	%esi
	.cfi_def_cfa_offset 8
	.cfi_offset 6, -8
	pushl	%ebx
	.cfi_def_cfa_offset 12
	.cfi_offset 3, -12
	movl	%edx, %ebx
	xorl	%ecx, %ecx
	pushl	%esi
	.cfi_def_cfa_offset 16
	movl	%eax, %esi
	call	_time2sub.constprop.10
	movl	(%ebx), %edx
	testl	%edx, %edx
	je	L669
	popl	%edx
	.cfi_remember_state
	.cfi_def_cfa_offset 12
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 8
	popl	%esi
	.cfi_restore 6
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L669:
	.cfi_restore_state
	movl	%ebx, %edx
	movl	%esi, %eax
	movl	$1, %ecx
	popl	%ebx
	.cfi_def_cfa_offset 12
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 8
	popl	%esi
	.cfi_restore 6
	.cfi_def_cfa_offset 4
	jmp	_time2sub.constprop.10
	.cfi_endproc
LFE50:
	.p2align 4,,15
	.globl	___tzsetwall
___tzsetwall:
LFB16:
	.cfi_startproc
	cmpl	$-1, _lcl_is_set
	je	L677
	subl	$12, %esp
	.cfi_def_cfa_offset 16
	xorl	%eax, %eax
	movl	$1, %ecx
	movl	$_lclmem, %edx
	movl	$-1, _lcl_is_set
	call	_tzload
	testl	%eax, %eax
	jne	L678
	addl	$12, %esp
	.cfi_def_cfa_offset 4
	jmp	_settzname
	.p2align 4,,7
L677:
	ret
	.p2align 4,,7
L678:
	.cfi_def_cfa_offset 16
	movl	$_lclmem, %eax
	call	_gmtload
	addl	$12, %esp
	.cfi_def_cfa_offset 4
	jmp	_settzname
	.cfi_endproc
LFE16:
LC7:
	.ascii "TZ\0"
	.p2align 4,,15
	.globl	___tzset
___tzset:
LFB17:
	.cfi_startproc
	pushl	%ebx
	.cfi_def_cfa_offset 8
	.cfi_offset 3, -8
	subl	$24, %esp
	.cfi_def_cfa_offset 32
	movl	_lcl_is_set, %edx
	movl	___environ_changed, %eax
	testl	%edx, %edx
	jle	L681
	cmpl	_last_env_changed.2857, %eax
	je	L679
L681:
	movl	$LC7, (%esp)
	movl	%eax, _last_env_changed.2857
	call	_getenv
	movl	%eax, %ebx
	movl	_lcl_is_set, %eax
	testl	%eax, %eax
	jle	L683
	testl	%ebx, %ebx
	je	L679
	movl	$_lcl_TZname, 4(%esp)
	movl	%ebx, (%esp)
	call	___stricmp
	testl	%eax, %eax
	je	L679
L685:
	movl	%ebx, (%esp)
	call	_strlen
	cmpl	$255, %eax
	setbe	%dl
	andl	$255, %edx
	movl	%edx, _lcl_is_set
	testl	%edx, %edx
	jne	L703
L686:
	cmpb	$0, (%ebx)
	jne	L687
	movl	_gmt, %eax
	movl	$0, _lclmem
	movl	$0, _lclmem+4
	movl	$0, _lclmem+6028
	movl	$0, _lclmem+6024
	movl	$0, _lclmem+6032
	movl	%eax, _lclmem+6224
L688:
	addl	$24, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 8
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 4
	jmp	_settzname
	.p2align 4,,7
L683:
	.cfi_restore_state
	testl	%ebx, %ebx
	jne	L685
	call	___tzsetwall
	movl	$1, _lcl_is_set
	.p2align 4,,7
L679:
	addl	$24, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 8
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L687:
	.cfi_restore_state
	movl	$1, %ecx
	movl	$_lclmem, %edx
	movl	%ebx, %eax
	call	_tzload
	testl	%eax, %eax
	je	L688
	cmpb	$58, (%ebx)
	je	L691
	xorl	%ecx, %ecx
	movl	$_lclmem, %edx
	movl	%ebx, %eax
	call	_tzparse
	testl	%eax, %eax
	je	L688
L691:
	movl	$_lclmem, %eax
	call	_gmtload
	jmp	L688
	.p2align 4,,7
L703:
	incl	%eax
	movl	%ebx, 4(%esp)
	movl	%eax, 8(%esp)
	movl	$_lcl_TZname, (%esp)
	call	_memcpy
	jmp	L686
	.cfi_endproc
LFE17:
	.p2align 4,,15
	.globl	___localtime_r
___localtime_r:
LFB20:
	.cfi_startproc
	subl	$28, %esp
	.cfi_def_cfa_offset 32
	movl	36(%esp), %eax
	movl	$0, 4(%esp)
	movl	%eax, 8(%esp)
	movl	32(%esp), %eax
	movl	%eax, (%esp)
	call	_localsub
	addl	$28, %esp
	.cfi_def_cfa_offset 4
	ret
	.cfi_endproc
LFE20:
	.p2align 4,,15
	.globl	_localtime
_localtime:
LFB19:
	.cfi_startproc
	subl	$28, %esp
	.cfi_def_cfa_offset 32
	call	___tzset
	movl	32(%esp), %eax
	movl	$_tm.2892, 4(%esp)
	movl	%eax, (%esp)
	call	___localtime_r
	addl	$28, %esp
	.cfi_def_cfa_offset 4
	ret
	.cfi_endproc
LFE19:
	.p2align 4,,15
	.globl	___gmtime_r
___gmtime_r:
LFB23:
	.cfi_startproc
	pushl	%ebx
	.cfi_def_cfa_offset 8
	.cfi_offset 3, -8
	subl	$24, %esp
	.cfi_def_cfa_offset 32
	movl	_gmt_is_set, %eax
	movl	36(%esp), %ebx
	testl	%eax, %eax
	je	L711
L709:
	movl	32(%esp), %eax
	movl	%ebx, (%esp)
	movl	$_gmtmem, %ecx
	xorl	%edx, %edx
	movl	(%eax), %eax
	call	_timesub.isra.2
	movl	$_gmtmem+6224, 36(%ebx)
	addl	$24, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 8
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L711:
	.cfi_restore_state
	movl	$_gmtmem, %eax
	movl	$1, _gmt_is_set
	call	_gmtload
	jmp	L709
	.cfi_endproc
LFE23:
	.p2align 4,,15
	.globl	_gmtime
_gmtime:
LFB22:
	.cfi_startproc
	subl	$28, %esp
	.cfi_def_cfa_offset 32
	movl	32(%esp), %eax
	movl	$_tm.2906, 4(%esp)
	movl	%eax, (%esp)
	call	___gmtime_r
	addl	$28, %esp
	.cfi_def_cfa_offset 4
	ret
	.cfi_endproc
LFE22:
	.p2align 2
LC8:
	.ascii "%.3s %.3s%3d %02d:%02d:%02d %d\12\0"
	.p2align 4,,15
	.globl	___asctime_r
___asctime_r:
LFB26:
	.cfi_startproc
	pushl	%ebx
	.cfi_def_cfa_offset 8
	.cfi_offset 3, -8
	subl	$56, %esp
	.cfi_def_cfa_offset 64
	movl	64(%esp), %edx
	movl	68(%esp), %ebx
	movl	20(%edx), %eax
	addl	$1900, %eax
	movl	%eax, 32(%esp)
	movl	(%edx), %eax
	movl	%eax, 28(%esp)
	movl	4(%edx), %eax
	movl	%eax, 24(%esp)
	movl	8(%edx), %eax
	movl	%eax, 20(%esp)
	movl	12(%edx), %eax
	movl	%eax, 16(%esp)
	movl	16(%edx), %eax
	leal	_mon_name.2964(%eax,%eax,2), %eax
	movl	%eax, 12(%esp)
	movl	24(%edx), %eax
	movl	%ebx, (%esp)
	movl	$LC8, 4(%esp)
	leal	_wday_name.2963(%eax,%eax,2), %eax
	movl	%eax, 8(%esp)
	call	_sprintf
	addl	$56, %esp
	.cfi_def_cfa_offset 8
	movl	%ebx, %eax
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 4
	ret
	.cfi_endproc
LFE26:
	.p2align 4,,15
	.globl	_asctime
_asctime:
LFB27:
	.cfi_startproc
	subl	$28, %esp
	.cfi_def_cfa_offset 32
	movl	32(%esp), %eax
	movl	$_result.2968, 4(%esp)
	movl	%eax, (%esp)
	call	___asctime_r
	addl	$28, %esp
	.cfi_def_cfa_offset 4
	ret
	.cfi_endproc
LFE27:
	.p2align 4,,15
	.globl	___ctime_r
___ctime_r:
LFB28:
	.cfi_startproc
	subl	$76, %esp
	.cfi_def_cfa_offset 80
	leal	20(%esp), %eax
	movl	%eax, 4(%esp)
	movl	80(%esp), %eax
	movl	%eax, (%esp)
	call	___localtime_r
	movl	84(%esp), %edx
	movl	%edx, 4(%esp)
	movl	%eax, (%esp)
	call	___asctime_r
	addl	$76, %esp
	.cfi_def_cfa_offset 4
	ret
	.cfi_endproc
LFE28:
	.p2align 4,,15
	.globl	_ctime
_ctime:
LFB29:
	.cfi_startproc
	subl	$28, %esp
	.cfi_def_cfa_offset 32
	movl	32(%esp), %eax
	movl	%eax, (%esp)
	call	_localtime
	movl	%eax, 32(%esp)
	addl	$28, %esp
	.cfi_def_cfa_offset 4
	jmp	_asctime
	.cfi_endproc
LFE29:
	.p2align 4,,15
	.globl	_mktime
_mktime:
LFB38:
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
	movl	144(%esp), %ebx
	call	___tzset
	testl	%ebx, %ebx
	je	L748
	cmpl	$1, 32(%ebx)
	jle	L725
	movl	$1, 32(%ebx)
L725:
	leal	28(%esp), %edx
	movl	%ebx, %eax
	call	_time2.constprop.8
	movl	28(%esp), %edi
	testl	%edi, %edi
	jne	L724
	movl	32(%ebx), %edx
	testl	%edx, %edx
	js	L724
	movl	_lclmem+8, %esi
	leal	32(%esp), %eax
	testl	%esi, %esi
	leal	(%eax,%esi,4), %ecx
	jle	L730
	.p2align 4,,7
L729:
	movl	$0, (%eax)
	addl	$4, %eax
	cmpl	%ecx, %eax
	jne	L729
L730:
	movl	_lclmem+4, %eax
	movl	%eax, %ecx
	decl	%ecx
	js	L728
	addl	$_lclmem+4823, %eax
	xorl	%ebp, %ebp
	.p2align 4,,7
L732:
	xorl	%ecx, %ecx
	movb	(%eax), %cl
	movl	32(%esp,%ecx,4), %esi
	testl	%esi, %esi
	jne	L731
	movl	%ecx, 72(%esp,%ebp,4)
	movl	$1, 32(%esp,%ecx,4)
	incl	%ebp
L731:
	decl	%eax
	cmpl	$_lclmem+4823, %eax
	jne	L732
	testl	%ebp, %ebp
	je	L728
	movl	$0, 8(%esp)
	movl	%ebp, 4(%esp)
	jmp	L737
	.p2align 4,,7
L736:
	movl	8(%esp), %ecx
	incl	%ecx
	movl	%ecx, 8(%esp)
	movl	4(%esp), %ecx
	cmpl	%ecx, 8(%esp)
	je	L728
	movl	32(%ebx), %edx
L737:
	movl	8(%esp), %ecx
	movl	72(%esp,%ecx,4), %eax
	leal	(%eax,%eax,4), %eax
	cmpl	%edx, _lclmem+6028(,%eax,4)
	jne	L736
	xorl	%esi, %esi
	movl	%eax, 12(%esp)
	jmp	L733
	.p2align 4,,7
L749:
	movl	8(%edi), %edx
	movl	8(%ebp), %eax
	subl	%edx, %eax
	movl	(%ebx), %ecx
	movl	32(%ebx), %edi
	addl	%eax, %ecx
	testl	%edi, %edi
	movl	%ecx, (%ebx)
	sete	%al
	andl	$255, %eax
	movl	%eax, 32(%ebx)
L735:
	incl	%esi
	cmpl	4(%esp), %esi
	je	L736
	movl	32(%ebx), %edx
L733:
	movl	72(%esp,%esi,4), %eax
	leal	(%eax,%eax,4), %eax
	leal	_lclmem+6016(,%eax,4), %edi
	cmpl	%edx, 12(%edi)
	je	L735
	movl	12(%esp), %ecx
	movl	8(%edi), %eax
	leal	_lclmem+6016(,%ecx,4), %ebp
	movl	8(%ebp), %ecx
	subl	%ecx, %eax
	movl	(%ebx), %ecx
	addl	%eax, %ecx
	testl	%edx, %edx
	sete	%al
	andl	$255, %eax
	leal	28(%esp), %edx
	movl	%eax, 32(%ebx)
	movl	%ecx, (%ebx)
	movl	%ebx, %eax
	call	_time2.constprop.8
	movl	28(%esp), %edx
	testl	%edx, %edx
	je	L749
L724:
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
L748:
	.cfi_restore_state
	movl	$14, _errno
	addl	$124, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 20
	orl	$-1, %eax
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
L728:
	.cfi_restore_state
	addl	$124, %esp
	.cfi_def_cfa_offset 20
	orl	$-1, %eax
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
	.cfi_endproc
LFE38:
	.globl	_tzname
	.section .data
	.p2align 2
_tzname:
	.long	_wildabbr
	.long	_wildabbr
	.globl	__posixrules_data
	.p2align 4
__posixrules_data:
	.byte	84
	.byte	90
	.byte	105
	.byte	102
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
	.byte	4
	.byte	0
	.byte	0
	.byte	0
	.byte	4
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	-21
	.byte	0
	.byte	0
	.byte	0
	.byte	4
	.byte	0
	.byte	0
	.byte	0
	.byte	16
	.byte	-98
	.byte	-90
	.byte	30
	.byte	112
	.byte	-97
	.byte	-70
	.byte	-21
	.byte	96
	.byte	-96
	.byte	-122
	.byte	0
	.byte	112
	.byte	-95
	.byte	-102
	.byte	-51
	.byte	96
	.byte	-94
	.byte	101
	.byte	-30
	.byte	112
	.byte	-93
	.byte	-125
	.byte	-23
	.byte	-32
	.byte	-92
	.byte	106
	.byte	-82
	.byte	112
	.byte	-91
	.byte	53
	.byte	-89
	.byte	96
	.byte	-90
	.byte	83
	.byte	-54
	.byte	-16
	.byte	-89
	.byte	21
	.byte	-119
	.byte	96
	.byte	-88
	.byte	51
	.byte	-84
	.byte	-16
	.byte	-88
	.byte	-2
	.byte	-91
	.byte	-32
	.byte	-86
	.byte	19
	.byte	-114
	.byte	-16
	.byte	-86
	.byte	-34
	.byte	-121
	.byte	-32
	.byte	-85
	.byte	-13
	.byte	112
	.byte	-16
	.byte	-84
	.byte	-66
	.byte	105
	.byte	-32
	.byte	-83
	.byte	-45
	.byte	82
	.byte	-16
	.byte	-82
	.byte	-98
	.byte	75
	.byte	-32
	.byte	-81
	.byte	-77
	.byte	52
	.byte	-16
	.byte	-80
	.byte	126
	.byte	45
	.byte	-32
	.byte	-79
	.byte	-100
	.byte	81
	.byte	112
	.byte	-78
	.byte	103
	.byte	74
	.byte	96
	.byte	-77
	.byte	124
	.byte	51
	.byte	112
	.byte	-76
	.byte	71
	.byte	44
	.byte	96
	.byte	-75
	.byte	92
	.byte	21
	.byte	112
	.byte	-74
	.byte	39
	.byte	14
	.byte	96
	.byte	-73
	.byte	59
	.byte	-9
	.byte	112
	.byte	-72
	.byte	6
	.byte	-16
	.byte	96
	.byte	-71
	.byte	27
	.byte	-39
	.byte	112
	.byte	-71
	.byte	-26
	.byte	-46
	.byte	96
	.byte	-69
	.byte	4
	.byte	-11
	.byte	-16
	.byte	-69
	.byte	-58
	.byte	-76
	.byte	96
	.byte	-68
	.byte	-28
	.byte	-41
	.byte	-16
	.byte	-67
	.byte	-81
	.byte	-48
	.byte	-32
	.byte	-66
	.byte	-60
	.byte	-71
	.byte	-16
	.byte	-65
	.byte	-113
	.byte	-78
	.byte	-32
	.byte	-64
	.byte	-92
	.byte	-101
	.byte	-16
	.byte	-63
	.byte	111
	.byte	-108
	.byte	-32
	.byte	-62
	.byte	-124
	.byte	125
	.byte	-16
	.byte	-61
	.byte	79
	.byte	118
	.byte	-32
	.byte	-60
	.byte	100
	.byte	95
	.byte	-16
	.byte	-59
	.byte	47
	.byte	88
	.byte	-32
	.byte	-58
	.byte	77
	.byte	124
	.byte	112
	.byte	-57
	.byte	15
	.byte	58
	.byte	-32
	.byte	-56
	.byte	45
	.byte	94
	.byte	112
	.byte	-56
	.byte	-8
	.byte	87
	.byte	96
	.byte	-54
	.byte	13
	.byte	64
	.byte	112
	.byte	-54
	.byte	-40
	.byte	57
	.byte	96
	.byte	-53
	.byte	-120
	.byte	-16
	.byte	112
	.byte	-46
	.byte	35
	.byte	-12
	.byte	112
	.byte	-46
	.byte	96
	.byte	-5
	.byte	-32
	.byte	-45
	.byte	117
	.byte	-28
	.byte	-16
	.byte	-44
	.byte	64
	.byte	-35
	.byte	-32
	.byte	-43
	.byte	85
	.byte	-58
	.byte	-16
	.byte	-42
	.byte	32
	.byte	-65
	.byte	-32
	.byte	-41
	.byte	53
	.byte	-88
	.byte	-16
	.byte	-40
	.byte	0
	.byte	-95
	.byte	-32
	.byte	-39
	.byte	21
	.byte	-118
	.byte	-16
	.byte	-39
	.byte	-32
	.byte	-125
	.byte	-32
	.byte	-38
	.byte	-2
	.byte	-89
	.byte	112
	.byte	-37
	.byte	-64
	.byte	101
	.byte	-32
	.byte	-36
	.byte	-34
	.byte	-119
	.byte	112
	.byte	-35
	.byte	-87
	.byte	-126
	.byte	96
	.byte	-34
	.byte	-66
	.byte	107
	.byte	112
	.byte	-33
	.byte	-119
	.byte	100
	.byte	96
	.byte	-32
	.byte	-98
	.byte	77
	.byte	112
	.byte	-31
	.byte	105
	.byte	70
	.byte	96
	.byte	-30
	.byte	126
	.byte	47
	.byte	112
	.byte	-29
	.byte	73
	.byte	40
	.byte	96
	.byte	-28
	.byte	94
	.byte	17
	.byte	112
	.byte	-27
	.byte	87
	.byte	46
	.byte	-32
	.byte	-26
	.byte	71
	.byte	45
	.byte	-16
	.byte	-25
	.byte	55
	.byte	16
	.byte	-32
	.byte	-24
	.byte	39
	.byte	15
	.byte	-16
	.byte	-23
	.byte	22
	.byte	-14
	.byte	-32
	.byte	-22
	.byte	6
	.byte	-15
	.byte	-16
	.byte	-22
	.byte	-10
	.byte	-44
	.byte	-32
	.byte	-21
	.byte	-26
	.byte	-45
	.byte	-16
	.byte	-20
	.byte	-42
	.byte	-74
	.byte	-32
	.byte	-19
	.byte	-58
	.byte	-75
	.byte	-16
	.byte	-18
	.byte	-65
	.byte	-45
	.byte	96
	.byte	-17
	.byte	-81
	.byte	-46
	.byte	112
	.byte	-16
	.byte	-97
	.byte	-75
	.byte	96
	.byte	-15
	.byte	-113
	.byte	-76
	.byte	112
	.byte	-14
	.byte	127
	.byte	-105
	.byte	96
	.byte	-13
	.byte	111
	.byte	-106
	.byte	112
	.byte	-12
	.byte	95
	.byte	121
	.byte	96
	.byte	-11
	.byte	79
	.byte	120
	.byte	112
	.byte	-10
	.byte	63
	.byte	91
	.byte	96
	.byte	-9
	.byte	47
	.byte	90
	.byte	112
	.byte	-8
	.byte	40
	.byte	119
	.byte	-32
	.byte	-7
	.byte	15
	.byte	60
	.byte	112
	.byte	-6
	.byte	8
	.byte	89
	.byte	-32
	.byte	-6
	.byte	-8
	.byte	88
	.byte	-16
	.byte	-5
	.byte	-24
	.byte	59
	.byte	-32
	.byte	-4
	.byte	-40
	.byte	58
	.byte	-16
	.byte	-3
	.byte	-56
	.byte	29
	.byte	-32
	.byte	-2
	.byte	-72
	.byte	28
	.byte	-16
	.byte	-1
	.byte	-89
	.byte	-1
	.byte	-32
	.byte	0
	.byte	-105
	.byte	-2
	.byte	-16
	.byte	1
	.byte	-121
	.byte	-31
	.byte	-32
	.byte	2
	.byte	119
	.byte	-32
	.byte	-16
	.byte	3
	.byte	112
	.byte	-2
	.byte	96
	.byte	4
	.byte	96
	.byte	-3
	.byte	112
	.byte	5
	.byte	80
	.byte	-32
	.byte	96
	.byte	6
	.byte	64
	.byte	-33
	.byte	112
	.byte	7
	.byte	48
	.byte	-62
	.byte	96
	.byte	7
	.byte	-115
	.byte	25
	.byte	112
	.byte	9
	.byte	16
	.byte	-92
	.byte	96
	.byte	9
	.byte	-83
	.byte	-108
	.byte	-16
	.byte	10
	.byte	-16
	.byte	-122
	.byte	96
	.byte	11
	.byte	-32
	.byte	-123
	.byte	112
	.byte	12
	.byte	-39
	.byte	-94
	.byte	-32
	.byte	13
	.byte	-64
	.byte	103
	.byte	112
	.byte	14
	.byte	-71
	.byte	-124
	.byte	-32
	.byte	15
	.byte	-87
	.byte	-125
	.byte	-16
	.byte	16
	.byte	-103
	.byte	102
	.byte	-32
	.byte	17
	.byte	-119
	.byte	101
	.byte	-16
	.byte	18
	.byte	121
	.byte	72
	.byte	-32
	.byte	19
	.byte	105
	.byte	71
	.byte	-16
	.byte	20
	.byte	89
	.byte	42
	.byte	-32
	.byte	21
	.byte	73
	.byte	41
	.byte	-16
	.byte	22
	.byte	57
	.byte	12
	.byte	-32
	.byte	23
	.byte	41
	.byte	11
	.byte	-16
	.byte	24
	.byte	34
	.byte	41
	.byte	96
	.byte	25
	.byte	8
	.byte	-19
	.byte	-16
	.byte	26
	.byte	2
	.byte	11
	.byte	96
	.byte	26
	.byte	-14
	.byte	10
	.byte	112
	.byte	27
	.byte	-31
	.byte	-19
	.byte	96
	.byte	28
	.byte	-47
	.byte	-20
	.byte	112
	.byte	29
	.byte	-63
	.byte	-49
	.byte	96
	.byte	30
	.byte	-79
	.byte	-50
	.byte	112
	.byte	31
	.byte	-95
	.byte	-79
	.byte	96
	.byte	32
	.byte	118
	.byte	0
	.byte	-16
	.byte	33
	.byte	-127
	.byte	-109
	.byte	96
	.byte	34
	.byte	85
	.byte	-30
	.byte	-16
	.byte	35
	.byte	106
	.byte	-81
	.byte	-32
	.byte	36
	.byte	53
	.byte	-60
	.byte	-16
	.byte	37
	.byte	74
	.byte	-111
	.byte	-32
	.byte	38
	.byte	21
	.byte	-90
	.byte	-16
	.byte	39
	.byte	42
	.byte	115
	.byte	-32
	.byte	39
	.byte	-2
	.byte	-61
	.byte	112
	.byte	41
	.byte	10
	.byte	85
	.byte	-32
	.byte	41
	.byte	-34
	.byte	-91
	.byte	112
	.byte	42
	.byte	-22
	.byte	55
	.byte	-32
	.byte	43
	.byte	-66
	.byte	-121
	.byte	112
	.byte	44
	.byte	-45
	.byte	84
	.byte	96
	.byte	45
	.byte	-98
	.byte	105
	.byte	112
	.byte	46
	.byte	-77
	.byte	54
	.byte	96
	.byte	47
	.byte	126
	.byte	75
	.byte	112
	.byte	48
	.byte	-109
	.byte	24
	.byte	96
	.byte	49
	.byte	103
	.byte	103
	.byte	-16
	.byte	50
	.byte	114
	.byte	-6
	.byte	96
	.byte	51
	.byte	71
	.byte	73
	.byte	-16
	.byte	52
	.byte	82
	.byte	-36
	.byte	96
	.byte	53
	.byte	39
	.byte	43
	.byte	-16
	.byte	54
	.byte	50
	.byte	-66
	.byte	96
	.byte	55
	.byte	7
	.byte	13
	.byte	-16
	.byte	56
	.byte	27
	.byte	-38
	.byte	-32
	.byte	56
	.byte	-26
	.byte	-17
	.byte	-16
	.byte	57
	.byte	-5
	.byte	-68
	.byte	-32
	.byte	58
	.byte	-58
	.byte	-47
	.byte	-16
	.byte	59
	.byte	-37
	.byte	-98
	.byte	-32
	.byte	60
	.byte	-81
	.byte	-18
	.byte	112
	.byte	61
	.byte	-69
	.byte	-128
	.byte	-32
	.byte	62
	.byte	-113
	.byte	-48
	.byte	112
	.byte	63
	.byte	-101
	.byte	98
	.byte	-32
	.byte	64
	.byte	111
	.byte	-78
	.byte	112
	.byte	65
	.byte	-124
	.byte	127
	.byte	96
	.byte	66
	.byte	79
	.byte	-108
	.byte	112
	.byte	67
	.byte	100
	.byte	97
	.byte	96
	.byte	68
	.byte	47
	.byte	118
	.byte	112
	.byte	69
	.byte	68
	.byte	67
	.byte	96
	.byte	69
	.byte	-13
	.byte	-88
	.byte	-16
	.byte	71
	.byte	45
	.byte	95
	.byte	-32
	.byte	71
	.byte	-45
	.byte	-118
	.byte	-16
	.byte	73
	.byte	13
	.byte	65
	.byte	-32
	.byte	73
	.byte	-77
	.byte	108
	.byte	-16
	.byte	74
	.byte	-19
	.byte	35
	.byte	-32
	.byte	75
	.byte	-100
	.byte	-119
	.byte	112
	.byte	76
	.byte	-42
	.byte	64
	.byte	96
	.byte	77
	.byte	124
	.byte	107
	.byte	112
	.byte	78
	.byte	-74
	.byte	34
	.byte	96
	.byte	79
	.byte	92
	.byte	77
	.byte	112
	.byte	80
	.byte	-106
	.byte	4
	.byte	96
	.byte	81
	.byte	60
	.byte	47
	.byte	112
	.byte	82
	.byte	117
	.byte	-26
	.byte	96
	.byte	83
	.byte	28
	.byte	17
	.byte	112
	.byte	84
	.byte	85
	.byte	-56
	.byte	96
	.byte	84
	.byte	-5
	.byte	-13
	.byte	112
	.byte	86
	.byte	53
	.byte	-86
	.byte	96
	.byte	86
	.byte	-27
	.byte	15
	.byte	-16
	.byte	88
	.byte	30
	.byte	-58
	.byte	-32
	.byte	88
	.byte	-60
	.byte	-15
	.byte	-16
	.byte	89
	.byte	-2
	.byte	-88
	.byte	-32
	.byte	90
	.byte	-92
	.byte	-45
	.byte	-16
	.byte	91
	.byte	-34
	.byte	-118
	.byte	-32
	.byte	92
	.byte	-124
	.byte	-75
	.byte	-16
	.byte	93
	.byte	-66
	.byte	108
	.byte	-32
	.byte	94
	.byte	100
	.byte	-105
	.byte	-16
	.byte	95
	.byte	-98
	.byte	78
	.byte	-32
	.byte	96
	.byte	77
	.byte	-76
	.byte	112
	.byte	97
	.byte	-121
	.byte	107
	.byte	96
	.byte	98
	.byte	45
	.byte	-106
	.byte	112
	.byte	99
	.byte	103
	.byte	77
	.byte	96
	.byte	100
	.byte	13
	.byte	120
	.byte	112
	.byte	101
	.byte	71
	.byte	47
	.byte	96
	.byte	101
	.byte	-19
	.byte	90
	.byte	112
	.byte	103
	.byte	39
	.byte	17
	.byte	96
	.byte	103
	.byte	-51
	.byte	60
	.byte	112
	.byte	105
	.byte	6
	.byte	-13
	.byte	96
	.byte	105
	.byte	-83
	.byte	30
	.byte	112
	.byte	106
	.byte	-26
	.byte	-43
	.byte	96
	.byte	107
	.byte	-106
	.byte	58
	.byte	-16
	.byte	108
	.byte	-49
	.byte	-15
	.byte	-32
	.byte	109
	.byte	118
	.byte	28
	.byte	-16
	.byte	110
	.byte	-81
	.byte	-45
	.byte	-32
	.byte	111
	.byte	85
	.byte	-2
	.byte	-16
	.byte	112
	.byte	-113
	.byte	-75
	.byte	-32
	.byte	113
	.byte	53
	.byte	-32
	.byte	-16
	.byte	114
	.byte	111
	.byte	-105
	.byte	-32
	.byte	115
	.byte	21
	.byte	-62
	.byte	-16
	.byte	116
	.byte	79
	.byte	121
	.byte	-32
	.byte	116
	.byte	-2
	.byte	-33
	.byte	112
	.byte	118
	.byte	56
	.byte	-106
	.byte	96
	.byte	118
	.byte	-34
	.byte	-63
	.byte	112
	.byte	120
	.byte	24
	.byte	120
	.byte	96
	.byte	120
	.byte	-66
	.byte	-93
	.byte	112
	.byte	121
	.byte	-8
	.byte	90
	.byte	96
	.byte	122
	.byte	-98
	.byte	-123
	.byte	112
	.byte	123
	.byte	-40
	.byte	60
	.byte	96
	.byte	124
	.byte	126
	.byte	103
	.byte	112
	.byte	125
	.byte	-72
	.byte	30
	.byte	96
	.byte	126
	.byte	94
	.byte	73
	.byte	112
	.byte	127
	.byte	-104
	.byte	0
	.byte	96
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	2
	.byte	3
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	-1
	.byte	-1
	.byte	-57
	.byte	-64
	.byte	1
	.byte	0
	.byte	-1
	.byte	-1
	.byte	-71
	.byte	-80
	.byte	0
	.byte	4
	.byte	-1
	.byte	-1
	.byte	-57
	.byte	-64
	.byte	1
	.byte	8
	.byte	-1
	.byte	-1
	.byte	-57
	.byte	-64
	.byte	1
	.byte	12
	.byte	69
	.byte	68
	.byte	84
	.byte	0
	.byte	69
	.byte	83
	.byte	84
	.byte	0
	.byte	69
	.byte	87
	.byte	84
	.byte	0
	.byte	69
	.byte	80
	.byte	84
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	1
	.byte	0
	.byte	0
	.byte	0
	.byte	1
.lcomm _lcl_is_set,4,4
.lcomm _lclmem,6880,16
	.p2align 2
_tzdir_bss_count.2653:
	.long	-1
.lcomm _dir.2652,261,16
.lcomm _cp.2651,4,4
_wildabbr:
	.ascii "   \0"
.lcomm _zttinfo.2821,20,16
	.section .text
	.p2align 2
_year_lengths:
	.long	365
	.long	366
	.p2align 4
_mon_lengths:
	.long	31
	.long	28
	.long	31
	.long	30
	.long	31
	.long	30
	.long	31
	.long	31
	.long	30
	.long	31
	.long	30
	.long	31
	.long	31
	.long	29
	.long	31
	.long	30
	.long	31
	.long	30
	.long	31
	.long	31
	.long	30
	.long	31
	.long	30
	.long	31
_gmt:
	.ascii "GMT\0"
.lcomm _last_env_changed.2857,4,4
.lcomm _lcl_TZname,256,16
.lcomm _tm.2892,44,16
.lcomm _tm.2906,44,16
.lcomm _gmt_is_set,4,4
.lcomm _gmtmem,6880,16
	.p2align 4
_mon_name.2964:
	.ascii "Jan"
	.ascii "Feb"
	.ascii "Mar"
	.ascii "Apr"
	.ascii "May"
	.ascii "Jun"
	.ascii "Jul"
	.ascii "Aug"
	.ascii "Sep"
	.ascii "Oct"
	.ascii "Nov"
	.ascii "Dec"
	.p2align 4
_wday_name.2963:
	.ascii "Sun"
	.ascii "Mon"
	.ascii "Tue"
	.ascii "Wed"
	.ascii "Thu"
	.ascii "Fri"
	.ascii "Sat"
.lcomm _result.2968,26,16
	.ident	"GCC: (GNU) 4.7.4"
