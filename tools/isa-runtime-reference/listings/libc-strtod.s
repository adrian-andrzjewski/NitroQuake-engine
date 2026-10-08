	.file	"strtod.c"
	.section .text
LC2:
	.ascii "INF\0"
LC3:
	.ascii "INITY\0"
LC4:
	.ascii "NAN\0"
LC5:
	.ascii "0x\0"
	.p2align 4,,15
	.globl	_strtod
_strtod:
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
	movl	148(%esp), %edi
	movl	144(%esp), %ebp
	call	_localeconv
	testl	%edi, %edi
	movl	4(%eax), %eax
	movb	(%eax), %bl
	je	L2
	movl	%ebp, (%edi)
	jmp	L2
	.p2align 4,,7
L199:
	incl	%ebp
L2:
	xorl	%edx, %edx
	movb	0(%ebp), %al
	movb	%al, %dl
	testb	$1, ___dj_ctype_flags+3(%edx,%edx)
	jne	L199
	testb	%al, %al
	je	L110
	cmpb	$43, %al
	je	L200
	movl	$1, 44(%esp)
	cmpb	$45, %al
	je	L201
L7:
	movl	$3, 8(%esp)
	movl	%ebp, 4(%esp)
	movl	$LC2, (%esp)
	call	___strnicmp
	testl	%eax, %eax
	jne	L8
	testl	%edi, %edi
	je	L9
	leal	3(%ebp), %ebx
	movl	$5, 8(%esp)
	movl	%ebx, 4(%esp)
	movl	$LC3, (%esp)
	call	___strnicmp
	testl	%eax, %eax
	jne	L10
	addl	$8, %ebp
	movl	%ebp, (%edi)
L9:
	flds	___dj_huge_valf
	cmpl	$-1, 44(%esp)
	je	L202
L192:
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
L110:
	.cfi_restore_state
	addl	$124, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 20
	fldz
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
L200:
	.cfi_restore_state
	incl	%ebp
	movl	$1, 44(%esp)
	jmp	L7
	.p2align 4,,7
L10:
	movl	%ebx, (%edi)
	flds	___dj_huge_valf
	cmpl	$-1, 44(%esp)
	jne	L192
L202:
	fchs
	jmp	L192
	.p2align 4,,7
L8:
	movl	$3, 8(%esp)
	movl	%ebp, 4(%esp)
	movl	$LC4, (%esp)
	call	___strnicmp
	testl	%eax, %eax
	jne	L13
	flds	___dj_nan
	cmpl	$-1, 44(%esp)
	fstpl	32(%esp)
	je	L203
L14:
	cmpb	$40, 3(%ebp)
	je	L204
L15:
	testl	%edi, %edi
	je	L20
	addl	$3, %ebp
	movl	%ebp, (%edi)
L20:
	fldl	32(%esp)
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
L201:
	.cfi_restore_state
	incl	%ebp
	movl	$-1, 44(%esp)
	jmp	L7
L13:
	movl	$2, 8(%esp)
	movl	%ebp, 4(%esp)
	movl	$LC5, (%esp)
	call	___strnicmp
	testl	%eax, %eax
	jne	L25
	movzbl	2(%ebp), %esi
	movl	%esi, %eax
	cmpb	$46, %al
	je	L24
	andl	$-33, %eax
	subl	$65, %eax
	cmpb	$5, %al
	jbe	L24
	leal	-48(%esi), %eax
	cmpb	$9, %al
	ja	L25
L24:
	movb	%bl, 52(%esp)
	movl	%esi, %edx
	addl	$2, %ebp
	movl	$0, 32(%esp)
	movl	$0, 36(%esp)
	movl	$0, 48(%esp)
	movl	$0, 76(%esp)
	xorl	%ecx, %ecx
	xorl	%ebx, %ebx
	xorl	%esi, %esi
	movl	%edi, 64(%esp)
	jmp	L26
	.p2align 4,,7
L207:
	leal	-48(%edx), %eax
	cmpb	$9, %al
	ja	L205
	movl	%ecx, %esi
	movl	%ebx, %edi
	shldl	$4, %esi, %edi
	sall	$4, %esi
	movl	%edi, 36(%esp)
	movl	%esi, 32(%esp)
L108:
	movsbl	%dl, %edx
	leal	-48(%edx), %esi
L28:
	movl	%esi, %edx
	movl	36(%esp), %ebx
	sarl	$31, %edx
	movl	32(%esp), %ecx
	orl	%edx, %ebx
	orl	%esi, %ecx
	movl	%ebx, %eax
	orl	%ecx, %eax
	cmpl	$1, %eax
	leal	1(%ebp), %eax
	sbbl	$-1, 48(%esp)
	cmpl	$14, 48(%esp)
	jg	L206
	movb	1(%ebp), %dl
	movl	$1, %esi
	movl	%eax, %ebp
L26:
	movb	%dl, %al
	andl	$-33, %eax
	subl	$65, %eax
	cmpb	$5, %al
	ja	L207
	movl	%ecx, %esi
	movl	%ebx, %edi
	shldl	$4, %esi, %edi
	leal	-48(%edx), %eax
	movl	%edi, 36(%esp)
	sall	$4, %esi
	cmpb	$9, %al
	movl	%esi, 32(%esp)
	jbe	L108
	leal	-65(%edx), %eax
	movsbl	%dl, %edx
	cmpb	$5, %al
	leal	-55(%edx), %esi
	jbe	L28
	leal	-87(%edx), %esi
	jmp	L28
L25:
	movsbl	0(%ebp), %eax
	leal	-48(%eax), %edx
	cmpb	$9, %dl
	ja	L208
	fldz
	flds	LC6
	.p2align 4,,7
L81:
	subl	$48, %eax
	incl	%ebp
	movl	%eax, 84(%esp)
	fmul	%st, %st(1)
	movsbl	0(%ebp), %eax
	fildl	84(%esp)
	faddp	%st, %st(2)
	leal	-48(%eax), %edx
	cmpb	$9, %dl
	jbe	L81
	fstp	%st(0)
	movl	$1, %edx
L23:
	cmpb	%al, %bl
	je	L209
L82:
	testl	%edx, %edx
	jne	L84
	fstp	%st(0)
L197:
	movl	$14, _errno
	fldz
	jmp	L192
L203:
	movl	36(%esp), %eax
	orl	$-2147483648, %eax
	movl	%eax, 36(%esp)
	jmp	L14
L209:
	movsbl	1(%ebp), %eax
	leal	1(%ebp), %ecx
	leal	-48(%eax), %ebx
	cmpb	$9, %bl
	ja	L118
	fldt	LC1
	movl	%ecx, %ebp
	fld	%st(0)
L83:
	subl	$48, %eax
	incl	%ebp
	movl	%eax, 84(%esp)
	fildl	84(%esp)
	fmul	%st(2), %st
	movsbl	0(%ebp), %eax
	faddp	%st, %st(3)
	leal	-48(%eax), %edx
	cmpb	$9, %dl
	fmul	%st, %st(1)
	jbe	L83
	fstp	%st(0)
	fstp	%st(0)
L84:
	testl	%edi, %edi
	je	L85
	movl	%ebp, (%edi)
L85:
	movb	0(%ebp), %al
	andl	$-33, %eax
	cmpb	$69, %al
	jne	L86
	movsbl	1(%ebp), %ecx
	cmpb	$43, %cl
	sete	%al
	cmpb	$45, %cl
	sete	32(%esp)
	je	L120
	testb	%al, %al
	je	L87
L120:
	movb	2(%ebp), %bl
	leal	-48(%ebx), %esi
	movl	%esi, %edx
	cmpb	$9, %dl
	ja	L87
	testb	%al, %al
	je	L91
	movsbl	%bl, %ecx
	addl	$2, %ebp
	movl	$1, %ebx
L92:
	xorl	%edx, %edx
L95:
	leal	(%edx,%edx,4), %eax
	incl	%ebp
	leal	-48(%ecx,%eax,2), %edx
	movsbl	0(%ebp), %ecx
	leal	-48(%ecx), %eax
	cmpb	$9, %al
	jbe	L95
	incl	%ebx
	jne	L210
	testl	%edx, %edx
	jle	L86
	fldt	LC1
	fmul	%st, %st(1)
	fldt	LC8
	fucomp	%st(2)
	fnstsw	%ax
	testb	$69, %ah
	je	L217
	movl	$1, %ecx
	jmp	L100
	.p2align 4,,7
L102:
	fmul	%st, %st(1)
	fldt	LC8
	fucomp	%st(2)
	fnstsw	%ax
	testb	$69, %ah
	je	L218
L100:
	incl	%ecx
	cmpl	%ecx, %edx
	jge	L102
	fstp	%st(0)
L86:
	testl	%edi, %edi
	je	L105
	movl	%ebp, (%edi)
L105:
	fildl	44(%esp)
	fmulp	%st, %st(1)
	fstpl	88(%esp)
	fldl	88(%esp)
	jmp	L192
L204:
	leal	4(%ebp), %eax
	leal	108(%esp), %edx
	movl	$16, 8(%esp)
	movl	%edx, 4(%esp)
	movl	%eax, (%esp)
	movl	%eax, 108(%esp)
	call	_strtoull
	movl	108(%esp), %ecx
	cmpb	$41, (%ecx)
	jne	L15
	andl	$1048575, %edx
	movl	%edx, %ebx
	orl	%eax, %ebx
	je	L17
	movl	%eax, 32(%esp)
	movl	36(%esp), %eax
	andl	$-1048576, %eax
	orl	%edx, %eax
	movl	%eax, 36(%esp)
L17:
	testl	%edi, %edi
	je	L20
	incl	%ecx
	movl	%ecx, (%edi)
	jmp	L20
L206:
	movzbl	1(%ebp), %esi
	movl	%ebx, 36(%esp)
	movl	%ecx, 32(%esp)
	movb	52(%esp), %bl
	movl	64(%esp), %edi
	movl	$1, 76(%esp)
L32:
	movl	%eax, %ebp
	movl	%esi, %edx
	jmp	L36
	.p2align 4,,7
L37:
	incl	%ebp
	movb	0(%ebp), %dl
L36:
	movb	%dl, %cl
	movl	%ebp, %esi
	andl	$-33, %ecx
	subl	%eax, %esi
	subl	$65, %ecx
	cmpb	$5, %cl
	jbe	L37
	leal	-48(%edx), %ecx
	cmpb	$9, %cl
	jbe	L37
	movl	%esi, 52(%esp)
	movl	%edx, %esi
	movl	48(%esp), %edx
	xorl	%eax, %eax
	leal	-1(,%edx,4), %ecx
	xorl	%edx, %edx
	testb	$32, %cl
	sete	%al
	setne	%dl
	sall	%cl, %eax
	sall	%cl, %edx
	movl	%eax, 56(%esp)
	movl	%edx, 60(%esp)
	movl	56(%esp), %eax
	movl	32(%esp), %edx
	andl	%edx, %eax
	movl	60(%esp), %edx
	andl	36(%esp), %edx
	orl	%eax, %edx
	jne	L38
	movb	%bl, 64(%esp)
	movl	%ebp, 68(%esp)
	movl	56(%esp), %eax
	movl	60(%esp), %edx
L162:
	shrdl	$1, %edx, %eax
	movl	32(%esp), %ebx
	movl	36(%esp), %ebp
	shrl	%edx
	andl	%eax, %ebx
	andl	%edx, %ebp
	decl	%ecx
	orl	%ebx, %ebp
	je	L162
	movb	64(%esp), %bl
	movl	68(%esp), %ebp
	movl	%eax, 56(%esp)
	movl	%edx, 60(%esp)
L38:
	movl	52(%esp), %edx
	movl	48(%esp), %eax
	leal	(%ecx,%edx,4), %ecx
	addl	%eax, %edx
	movl	%ecx, 64(%esp)
	movl	%edx, 72(%esp)
L35:
	movl	72(%esp), %eax
	movl	%esi, %edx
	movl	%eax, 52(%esp)
	cmpb	%dl, %bl
	je	L211
L40:
	movl	76(%esp), %eax
	testl	%eax, %eax
	je	L197
	testl	%edi, %edi
	je	L53
	movl	%ebp, (%edi)
L53:
	cmpl	$14, 52(%esp)
	jle	L54
	movl	32(%esp), %eax
	andl	$15, %eax
	cmpl	$7, %eax
	jle	L54
	addl	$16, 32(%esp)
	adcl	$0, 36(%esp)
	movl	32(%esp), %edx
	movl	56(%esp), %ebx
	movl	36(%esp), %eax
	movl	60(%esp), %esi
	andl	%ebx, %edx
	andl	%esi, %eax
	orl	%edx, %eax
	jne	L55
	movl	36(%esp), %edx
	movl	32(%esp), %eax
	movl	64(%esp), %ecx
	shrdl	$1, %edx, %eax
	incl	%ecx
	movl	%eax, 32(%esp)
	shrl	%edx
	movl	%ecx, 64(%esp)
	movl	%edx, 36(%esp)
L54:
	movl	36(%esp), %edx
	orl	32(%esp), %edx
	jne	L55
	.p2align 4,,7
L173:
	movb	0(%ebp), %al
	movb	%al, %dl
	andl	$-33, %edx
	leal	-65(%edx), %ecx
	cmpb	$5, %cl
	jbe	L60
	subl	$48, %eax
	cmpb	$9, %al
	ja	L212
L60:
	incl	%ebp
	jmp	L173
L212:
	movl	%ebp, %ebx
	cmpb	$80, %dl
	jne	L61
	movb	1(%ebp), %dl
	cmpb	$43, %dl
	sete	48(%esp)
	cmpb	$45, %dl
	sete	52(%esp)
	jne	L213
L119:
	movsbl	2(%ebp), %ecx
	leal	-48(%ecx), %eax
	cmpb	$9, %al
	ja	L62
	cmpb	$0, 48(%esp)
	je	L66
	addl	$2, %ebp
	movl	$1, 48(%esp)
	cmpl	$1023, 64(%esp)
	jg	L196
L67:
	xorl	%edx, %edx
	jmp	L74
L72:
	movsbl	1(%ebp), %ecx
	movl	%ebx, %ebp
	leal	-48(%ecx), %eax
	cmpb	$9, %al
	ja	L71
L74:
	leal	(%edx,%edx,4), %eax
	movl	48(%esp), %esi
	leal	1(%ebp), %ebx
	leal	-48(%ecx,%eax,2), %edx
	movl	64(%esp), %eax
	imull	%edx, %esi
	addl	%eax, %esi
	cmpl	$1023, %esi
	jle	L72
	movb	1(%ebp), %al
	movl	%esi, 64(%esp)
	subl	$48, %eax
	movl	%ebx, %ebp
	jmp	L196
	.p2align 4,,7
L159:
	incl	%ebp
	movb	0(%ebp), %al
	subl	$48, %eax
L196:
	cmpb	$9, %al
	jbe	L159
L61:
	testl	%edi, %edi
	je	L76
	movl	%ebp, (%edi)
L76:
	movl	36(%esp), %esi
	orl	32(%esp), %esi
	je	L77
	cmpl	$1023, 64(%esp)
	jle	L78
	fildl	44(%esp)
	movl	$2, _errno
	fmull	___dj_huge_val
	jmp	L192
L87:
	leal	-48(%ecx), %eax
	cmpb	$9, %al
	ja	L86
L91:
	leal	1(%ebp), %eax
	cmpb	$0, 32(%esp)
	jne	L93
	leal	-48(%ecx), %edx
	movl	%eax, %ebp
	movl	$1, %ebx
L94:
	cmpb	$9, %dl
	jbe	L92
	jmp	L86
	.p2align 4,,7
L205:
	movl	48(%esp), %eax
	movl	%ebx, 36(%esp)
	movl	%esi, 76(%esp)
	movl	%ecx, 32(%esp)
	movb	52(%esp), %bl
	movl	%edx, %esi
	movl	64(%esp), %edi
	movl	%eax, 72(%esp)
	testl	%eax, %eax
	jne	L214
	movl	$0, 56(%esp)
	movl	$0, 60(%esp)
	movl	$0, 64(%esp)
	jmp	L35
L55:
	movl	36(%esp), %edx
	testl	%edx, %edx
	js	L57
	movl	32(%esp), %eax
	movl	36(%esp), %edx
L160:
	shldl	$1, %eax, %edx
	addl	%eax, %eax
	testl	%edx, %edx
	jns	L160
	movl	%eax, 32(%esp)
	movl	%edx, 36(%esp)
L57:
	movl	36(%esp), %esi
	movl	32(%esp), %ebx
	shrdl	$11, %esi, %ebx
	shrl	$11, %esi
	movl	%ebx, 32(%esp)
	movl	%esi, 36(%esp)
	jmp	L173
L211:
	leal	1(%ebp), %esi
	cmpl	$14, %eax
	jg	L114
	movl	72(%esp), %ebx
	incl	%eax
	decl	%ebx
	movl	%eax, 52(%esp)
	subl	%ebp, %ebx
	movl	$0, 48(%esp)
	movl	%ebx, 68(%esp)
	movl	76(%esp), %edx
	movl	%edi, 80(%esp)
	jmp	L42
L215:
	leal	-48(%ecx), %eax
	cmpb	$9, %al
	ja	L115
	movl	32(%esp), %eax
	movl	36(%esp), %edx
	shldl	$4, %eax, %edx
	sall	$4, %eax
	movl	52(%esp), %ebp
L109:
	leal	-48(%ecx), %edi
L44:
	movl	%edi, %ebx
	orl	%eax, %edi
	sarl	$31, %ebx
	movl	%edi, 32(%esp)
	movl	%ebx, %edi
	movl	32(%esp), %eax
	orl	%edx, %edi
	movl	$1, %edx
	orl	%edi, %eax
	movl	%edi, 36(%esp)
	cmpl	$1, %eax
	movl	52(%esp), %edi
	adcl	$0, 48(%esp)
	movl	%ebp, %eax
	movl	48(%esp), %ecx
	incl	%edi
	subl	%ecx, %eax
	incl	%esi
	movl	%edi, 52(%esp)
	cmpl	$14, %eax
	jg	L115
L42:
	movsbl	(%esi), %ecx
	movb	%cl, %al
	movl	68(%esp), %ebp
	andl	$-33, %eax
	addl	%esi, %ebp
	subl	$65, %eax
	cmpb	$5, %al
	ja	L215
	movl	32(%esp), %eax
	movl	36(%esp), %edx
	leal	-48(%ecx), %ebx
	movl	52(%esp), %ebp
	shldl	$4, %eax, %edx
	sall	$4, %eax
	cmpb	$9, %bl
	jbe	L109
	leal	-65(%ecx), %ebx
	leal	-55(%ecx), %edi
	cmpb	$5, %bl
	jbe	L44
	leal	-87(%ecx), %edi
	jmp	L44
L115:
	movl	%ebp, 52(%esp)
	movl	%edx, 76(%esp)
	movl	80(%esp), %edi
	movl	%esi, %ebp
L41:
	movl	32(%esp), %edx
	orl	36(%esp), %edx
	je	L49
	movl	72(%esp), %ebx
	testl	%ebx, %ebx
	jne	L49
	movl	48(%esp), %eax
	movl	52(%esp), %ebx
	negl	%eax
	sall	$2, %eax
	xorl	%edx, %edx
	movl	%eax, 64(%esp)
	leal	(%eax,%ebx,4), %ecx
	xorl	%eax, %eax
	testb	$32, %cl
	sete	%al
	setne	%dl
	sall	%cl, %eax
	sall	%cl, %edx
	movl	%eax, 56(%esp)
	movl	%edx, 60(%esp)
	movl	56(%esp), %eax
	movl	32(%esp), %edx
	andl	%edx, %eax
	movl	36(%esp), %ecx
	movl	60(%esp), %edx
	andl	%ecx, %edx
	orl	%eax, %edx
	jne	L40
	movl	64(%esp), %ecx
	movl	56(%esp), %eax
	movl	60(%esp), %edx
L161:
	shrdl	$1, %edx, %eax
	movl	32(%esp), %ebx
	movl	36(%esp), %esi
	shrl	%edx
	andl	%eax, %ebx
	andl	%edx, %esi
	decl	%ecx
	orl	%ebx, %esi
	je	L161
	movl	%ecx, 64(%esp)
	movl	%eax, 56(%esp)
	movl	%edx, 60(%esp)
	jmp	L40
L77:
	fildl	44(%esp)
	fmuls	LC0
	jmp	L192
L213:
	cmpb	$0, 48(%esp)
	jne	L119
L62:
	leal	-48(%edx), %eax
	cmpb	$9, %al
	ja	L61
L66:
	incl	%ebp
	cmpb	$0, 52(%esp)
	jne	L69
	leal	-48(%edx), %eax
	movl	$1, 48(%esp)
	movsbl	%dl, %ecx
L70:
	cmpl	$1023, 64(%esp)
	jg	L196
	cmpb	$9, %al
	jbe	L67
	movl	64(%esp), %esi
	movl	%ebp, %ebx
L71:
	movl	%esi, 64(%esp)
	movl	%ebx, %ebp
	jmp	L61
L208:
	xorl	%edx, %edx
	fldz
	jmp	L23
L49:
	movl	52(%esp), %ecx
	movl	72(%esp), %eax
	subl	%eax, %ecx
	testl	%ecx, %ecx
	jle	L40
	sall	$2, %ecx
	movl	56(%esp), %ebx
	movl	60(%esp), %esi
	shldl	%cl, %ebx, %esi
	sall	%cl, %ebx
	testb	$32, %cl
	je	L216
	movl	%ebx, %esi
	xorl	%ebx, %ebx
L216:
	movl	%ebx, 56(%esp)
	movl	%esi, 60(%esp)
	jmp	L40
L78:
	cmpl	$-1022, 64(%esp)
	jge	L79
	movl	$2, _errno
	fldz
	jmp	L192
L217:
	fstp	%st(0)
	fstp	%st(0)
	jmp	L99
	.p2align 4,,7
L218:
	fstp	%st(0)
	fstp	%st(0)
L99:
	movl	$2, _errno
	fldz
	jmp	L86
L79:
	cmpl	$1, 44(%esp)
	setne	%bl
	xorl	%edx, %edx
	andl	$255, %ebx
	movl	%edx, %ecx
	movl	32(%esp), %eax
	sall	$31, %ebx
	andl	$2147483647, %ecx
	orl	%ebx, %ecx
	movl	64(%esp), %ebx
	addl	$1023, %ebx
	andl	$-2146435073, %ecx
	andl	$2047, %ebx
	movl	%eax, 24(%esp)
	sall	$20, %ebx
	orl	%ebx, %ecx
	movl	36(%esp), %ebx
	andl	$-1048576, %ecx
	andl	$1048575, %ebx
	movl	%ecx, %edx
	orl	%ebx, %edx
	movl	%edx, 28(%esp)
	fldl	24(%esp)
	jmp	L192
L69:
	movsbl	2(%ebx), %ecx
	leal	2(%ebx), %ebp
	movl	$-1, 48(%esp)
	leal	-48(%ecx), %eax
	jmp	L70
L93:
	movsbl	2(%ebp), %ecx
	orl	$-1, %ebx
	addl	$2, %ebp
	leal	-48(%ecx), %edx
	jmp	L94
L118:
	movl	%ecx, %ebp
	jmp	L82
L214:
	movl	%ebp, %eax
	jmp	L32
L114:
	movl	72(%esp), %eax
	movl	%esi, %ebp
	movl	%eax, 52(%esp)
	movl	$0, 48(%esp)
	jmp	L41
L210:
	testl	%edx, %edx
	jle	L86
	flds	LC6
	fmul	%st, %st(1)
	fldl	LC7
	fxch	%st(2)
	fucom	%st(2)
	fnstsw	%ax
	fstp	%st(2)
	testb	$69, %ah
	je	L219
	movl	$1, %ecx
	jmp	L98
L104:
	fmul	%st, %st(1)
	fldl	LC7
	fxch	%st(2)
	fucom	%st(2)
	fnstsw	%ax
	fstp	%st(2)
	testb	$69, %ah
	je	L220
L98:
	incl	%ecx
	cmpl	%ecx, %edx
	jge	L104
	fstp	%st(0)
	jmp	L86
L219:
	fstp	%st(0)
	fstp	%st(0)
	jmp	L97
	.p2align 4,,7
L220:
	fstp	%st(0)
	fstp	%st(0)
L97:
	movl	$2, _errno
	fldl	___dj_huge_val
	jmp	L86
	.cfi_endproc
LFE0:
	.p2align 2
LC0:
	.long	0
	.p2align 4
LC1:
	.long	-858993459
	.long	-858993460
	.long	16379
	.p2align 2
LC6:
	.long	1092616192
	.p2align 3
LC7:
	.long	-1
	.long	2146435071
	.p2align 4
LC8:
	.long	0
	.long	-2147483648
	.long	15308
	.ident	"GCC: (GNU) 4.7.4"
