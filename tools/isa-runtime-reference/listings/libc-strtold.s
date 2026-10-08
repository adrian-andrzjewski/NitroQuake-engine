	.file	"strtold.c"
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
	.globl	__strtold
__strtold:
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
	subl	$140, %esp
	.cfi_def_cfa_offset 160
	movl	164(%esp), %edi
	movl	160(%esp), %ebp
	call	_localeconv
	testl	%edi, %edi
	movl	4(%eax), %eax
	movb	(%eax), %bl
	je	L2
	movl	%ebp, (%edi)
	jmp	L2
	.p2align 4,,7
L221:
	incl	%ebp
L2:
	xorl	%edx, %edx
	movb	0(%ebp), %al
	movb	%al, %dl
	testb	$1, ___dj_ctype_flags+3(%edx,%edx)
	jne	L221
	testb	%al, %al
	je	L115
	cmpb	$43, %al
	je	L222
	movl	$1, 32(%esp)
	cmpb	$45, %al
	je	L223
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
	cmpl	$-1, 32(%esp)
	je	L224
L214:
	addl	$140, %esp
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
L115:
	.cfi_restore_state
	addl	$140, %esp
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
L222:
	.cfi_restore_state
	incl	%ebp
	movl	$1, 32(%esp)
	jmp	L7
	.p2align 4,,7
L10:
	movl	%ebx, (%edi)
	flds	___dj_huge_valf
	cmpl	$-1, 32(%esp)
	jne	L214
L224:
	fchs
	jmp	L214
	.p2align 4,,7
L8:
	movl	$3, 8(%esp)
	movl	%ebp, 4(%esp)
	movl	$LC4, (%esp)
	call	___strnicmp
	testl	%eax, %eax
	jne	L13
	flds	___dj_nan
	cmpl	$-1, 32(%esp)
	fstpt	96(%esp)
	je	L225
L14:
	cmpb	$40, 3(%ebp)
	je	L226
L15:
	testl	%edi, %edi
	je	L20
	addl	$3, %ebp
	movl	%ebp, (%edi)
L20:
	fldt	96(%esp)
	addl	$140, %esp
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
L223:
	.cfi_restore_state
	incl	%ebp
	movl	$-1, 32(%esp)
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
	movb	%bl, 40(%esp)
	movl	%esi, %edx
	addl	$2, %ebp
	movl	$0, 24(%esp)
	movl	$0, 28(%esp)
	movl	$0, 36(%esp)
	movl	$0, 68(%esp)
	xorl	%ecx, %ecx
	xorl	%ebx, %ebx
	xorl	%esi, %esi
	movl	%edi, 56(%esp)
	jmp	L26
	.p2align 4,,7
L229:
	leal	-48(%edx), %eax
	cmpb	$9, %al
	ja	L227
	movl	%ecx, %esi
	movl	%ebx, %edi
	shldl	$4, %esi, %edi
	sall	$4, %esi
	movl	%edi, 28(%esp)
	movl	%esi, 24(%esp)
L113:
	movsbl	%dl, %edx
	leal	-48(%edx), %esi
L28:
	movl	%esi, %edx
	movl	28(%esp), %ebx
	sarl	$31, %edx
	movl	24(%esp), %ecx
	orl	%edx, %ebx
	orl	%esi, %ecx
	movl	%ebx, %eax
	orl	%ecx, %eax
	cmpl	$1, %eax
	leal	1(%ebp), %eax
	sbbl	$-1, 36(%esp)
	cmpl	$15, 36(%esp)
	jg	L228
	movb	1(%ebp), %dl
	movl	$1, %esi
	movl	%eax, %ebp
L26:
	movb	%dl, %al
	andl	$-33, %eax
	subl	$65, %eax
	cmpb	$5, %al
	ja	L229
	movl	%ecx, %esi
	movl	%ebx, %edi
	shldl	$4, %esi, %edi
	leal	-48(%edx), %eax
	movl	%edi, 28(%esp)
	sall	$4, %esi
	cmpb	$9, %al
	movl	%esi, 24(%esp)
	jbe	L113
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
	ja	L230
	fldz
	flds	LC6
	.p2align 4,,7
L85:
	subl	$48, %eax
	incl	%ebp
	movl	%eax, 76(%esp)
	fmul	%st, %st(1)
	movsbl	0(%ebp), %eax
	fildl	76(%esp)
	faddp	%st, %st(2)
	leal	-48(%eax), %edx
	cmpb	$9, %dl
	jbe	L85
	fstp	%st(0)
	movl	$1, %edx
L23:
	cmpb	%al, %bl
	je	L231
L86:
	testl	%edx, %edx
	jne	L127
	fstp	%st(0)
L219:
	movl	$14, _errno
	fldz
	jmp	L214
L225:
	orb	$-128, 105(%esp)
	jmp	L14
L226:
	leal	4(%ebp), %eax
	leal	92(%esp), %edx
	movl	$0, 8(%esp)
	movl	%edx, 4(%esp)
	movl	%eax, (%esp)
	movl	%eax, 92(%esp)
	call	_strtoull
	movl	92(%esp), %ecx
	cmpb	$41, (%ecx)
	jne	L15
	andl	$2147483647, %edx
	movl	%edx, %ebx
	orl	%eax, %ebx
	je	L17
	orl	$-2147483648, %edx
	movl	%eax, 96(%esp)
	movl	%edx, 100(%esp)
L17:
	testl	%edi, %edi
	je	L20
	incl	%ecx
	movl	%ecx, (%edi)
	jmp	L20
L228:
	movzbl	1(%ebp), %esi
	movl	%ebx, 28(%esp)
	movl	%ecx, 24(%esp)
	movb	40(%esp), %bl
	movl	%eax, 16(%esp)
	movl	56(%esp), %edi
	movl	$1, 68(%esp)
L32:
	movl	16(%esp), %ebp
	movl	%esi, %edx
	movl	%ebp, %eax
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
	movl	%esi, 40(%esp)
	movl	%edx, %esi
	movl	36(%esp), %edx
	movl	%eax, 16(%esp)
	xorl	%eax, %eax
	leal	-1(,%edx,4), %edx
	movl	%edx, 72(%esp)
	xorl	%edx, %edx
	movb	72(%esp), %cl
	testb	$32, %cl
	sete	%al
	setne	%dl
	sall	%cl, %eax
	sall	%cl, %edx
	movl	%eax, 48(%esp)
	movl	%edx, 52(%esp)
	movl	24(%esp), %eax
	movl	48(%esp), %edx
	andl	%eax, %edx
	movl	52(%esp), %ecx
	movl	28(%esp), %eax
	andl	%eax, %ecx
	orl	%ecx, %edx
	jne	L38
	movl	16(%esp), %edx
	movb	%bl, 56(%esp)
	movl	%edx, 64(%esp)
	movl	%ebp, 60(%esp)
	movl	72(%esp), %ecx
	movl	48(%esp), %eax
	movl	52(%esp), %edx
L181:
	shrdl	$1, %edx, %eax
	movl	24(%esp), %ebx
	movl	28(%esp), %ebp
	shrl	%edx
	andl	%eax, %ebx
	andl	%edx, %ebp
	decl	%ecx
	orl	%ebx, %ebp
	je	L181
	movl	%ecx, 72(%esp)
	movl	64(%esp), %ecx
	movb	56(%esp), %bl
	movl	60(%esp), %ebp
	movl	%eax, 48(%esp)
	movl	%edx, 52(%esp)
	movl	%ecx, 16(%esp)
L38:
	movl	40(%esp), %eax
	movl	72(%esp), %ecx
	movl	40(%esp), %edx
	leal	(%ecx,%eax,4), %eax
	movl	%eax, 56(%esp)
	movl	36(%esp), %eax
	addl	%eax, %edx
	movl	16(%esp), %eax
	movl	%edx, 64(%esp)
L35:
	movl	64(%esp), %ecx
	movl	%esi, %edx
	movl	%ecx, 40(%esp)
	cmpb	%dl, %bl
	je	L232
L40:
	movl	68(%esp), %ebx
	testl	%ebx, %ebx
	je	L219
	testl	%edi, %edi
	je	L53
	movl	%ebp, (%edi)
L53:
	cmpl	$15, 40(%esp)
	jle	L54
	movb	(%eax), %dl
	leal	-48(%edx), %eax
	cmpb	$9, %al
	ja	L55
	movsbl	%dl, %eax
	subl	$48, %eax
L56:
	cmpl	$7, %eax
	jg	L57
L54:
	movl	28(%esp), %ebx
	orl	24(%esp), %ebx
	jne	L110
	.p2align 4,,7
L193:
	movb	0(%ebp), %al
	movb	%al, %dl
	andl	$-33, %edx
	leal	-65(%edx), %ecx
	cmpb	$5, %cl
	jbe	L62
	subl	$48, %eax
	cmpb	$9, %al
	ja	L233
L62:
	incl	%ebp
	jmp	L193
L233:
	movl	%ebp, %ecx
	cmpb	$80, %dl
	jne	L63
	movb	1(%ebp), %dl
	cmpb	$43, %dl
	sete	%bl
	cmpb	$45, %dl
	sete	40(%esp)
	jne	L234
L131:
	movb	2(%ebp), %al
	movb	%al, 36(%esp)
	subl	$48, %eax
	movb	%al, 64(%esp)
	cmpb	$9, %al
	ja	L64
	testb	%bl, %bl
	je	L68
	movl	56(%esp), %eax
	addl	$2, %ebp
	movl	%eax, %edx
	movl	%eax, 48(%esp)
	sarl	$31, %edx
	movl	%edx, 52(%esp)
	cmpl	$0, %edx
	jl	L123
	jle	L235
L124:
	xorl	%edx, %edx
L71:
	movl	56(%esp), %ecx
	addl	%edx, %ecx
	movl	%ecx, 56(%esp)
	cmpb	$9, 64(%esp)
	ja	L63
L178:
	incl	%ebp
	movb	0(%ebp), %al
	subl	$48, %eax
	cmpb	$9, %al
	jbe	L178
L63:
	testl	%edi, %edi
	je	L80
	movl	%ebp, (%edi)
L80:
	movl	28(%esp), %ecx
	orl	24(%esp), %ecx
	je	L81
	cmpl	$16383, 56(%esp)
	jle	L82
	fildl	32(%esp)
	fldt	___dj_huge_vall
	movl	$2, _errno
	fmulp	%st, %st(1)
	jmp	L214
L127:
	xorl	%ecx, %ecx
L88:
	testl	%edi, %edi
	je	L89
	movl	%ebp, (%edi)
L89:
	movb	0(%ebp), %al
	andl	$-33, %eax
	cmpb	$69, %al
	jne	L128
	movsbl	1(%ebp), %eax
	cmpb	$43, %al
	sete	36(%esp)
	cmpb	$45, %al
	sete	24(%esp)
	je	L135
	cmpb	$0, 36(%esp)
	je	L91
L135:
	movb	2(%ebp), %dl
	leal	-48(%edx), %esi
	movl	%esi, %ebx
	cmpb	$9, %bl
	ja	L91
	cmpb	$0, 36(%esp)
	je	L95
	addl	$2, %ebp
	movl	$1, %ebx
	movsbl	%dl, %eax
L96:
	xorl	%edx, %edx
	movl	%ecx, %esi
L100:
	incl	%ebp
	leal	(%edx,%edx,4), %edx
	leal	-48(%eax,%edx,2), %edx
	movsbl	0(%ebp), %eax
	leal	-48(%eax), %ecx
	cmpb	$9, %cl
	jbe	L100
	movl	%esi, %ecx
L99:
	cmpl	$-1, %ebx
	jne	L90
	negl	%edx
	movl	$1, %ebx
L90:
	subl	%ecx, %edx
	cmpl	$-4096, %edx
	jge	L101
	fldt	LC7
	fmulp	%st, %st(1)
	addl	$2048, %edx
L102:
	negl	%edx
	negl	%ebx
L103:
	cmpl	$8191, %edx
	jg	L130
	testl	%edx, %edx
	jne	L104
L105:
	testl	%edi, %edi
	je	L109
	movl	%ebp, (%edi)
L109:
	fildl	32(%esp)
	fmulp	%st, %st(1)
	jmp	L214
L128:
	movl	$1, %ebx
	xorl	%edx, %edx
	jmp	L90
L130:
	movl	$8191, %edx
L104:
	movl	$_powten, %eax
	fld1
	.p2align 4,,7
L107:
	testb	$1, %dl
	je	L106
	fldt	(%eax)
	fmulp	%st, %st(1)
L106:
	addl	$12, %eax
	sarl	%edx
	jne	L107
	testl	%ebx, %ebx
	jle	L108
	fmulp	%st, %st(1)
	jmp	L105
L101:
	testl	%edx, %edx
	jns	L103
	jmp	L102
	.p2align 4,,7
L231:
	movb	1(%ebp), %bl
	leal	1(%ebp), %eax
	leal	-48(%ebx), %ecx
	cmpb	$9, %cl
	ja	L126
	xorl	%ecx, %ecx
	flds	LC6
L87:
	movsbl	%bl, %edx
	subl	$48, %edx
	incl	%eax
	movl	%edx, 76(%esp)
	fmul	%st, %st(1)
	movb	(%eax), %bl
	incl	%ecx
	fildl	76(%esp)
	faddp	%st, %st(2)
	leal	-48(%ebx), %edx
	cmpb	$9, %dl
	jbe	L87
	fstp	%st(0)
	movl	%eax, %ebp
	jmp	L88
L91:
	leal	-48(%eax), %edx
	cmpb	$9, %dl
	ja	L128
L95:
	leal	1(%ebp), %ebx
	cmpb	$0, 24(%esp)
	jne	L97
	movl	%ebx, %ebp
	leal	-48(%eax), %edx
	movl	$1, %ebx
L98:
	cmpb	$9, %dl
	jbe	L96
	xorl	%edx, %edx
	jmp	L99
	.p2align 4,,7
L227:
	movl	36(%esp), %eax
	movl	%ebx, 28(%esp)
	movl	%esi, 68(%esp)
	movl	%ecx, 24(%esp)
	movb	40(%esp), %bl
	movl	%edx, %esi
	movl	56(%esp), %edi
	movl	%eax, 64(%esp)
	testl	%eax, %eax
	jne	L236
	movl	$0, 48(%esp)
	movl	$0, 52(%esp)
	movl	$0, 56(%esp)
	xorl	%eax, %eax
	jmp	L35
L57:
	addl	$1, 24(%esp)
	adcl	$0, 28(%esp)
	movl	48(%esp), %edx
	movl	24(%esp), %eax
	movl	52(%esp), %ecx
	andl	%edx, %eax
	movl	28(%esp), %edx
	andl	%ecx, %edx
	orl	%eax, %edx
	jne	L110
	movl	28(%esp), %edx
	movl	24(%esp), %eax
	shrdl	$1, %edx, %eax
	shrl	%edx
	movl	56(%esp), %esi
	movl	%edx, %ecx
	incl	%esi
	orl	$-2147483648, %ecx
	movl	%eax, 24(%esp)
	movl	%ecx, 28(%esp)
	movl	%esi, 56(%esp)
L110:
	movl	28(%esp), %ebx
	testl	%ebx, %ebx
	js	L193
	movl	24(%esp), %eax
	movl	28(%esp), %edx
L179:
	shldl	$1, %eax, %edx
	addl	%eax, %eax
	testl	%edx, %edx
	jns	L179
	movl	%eax, 24(%esp)
	movl	%edx, 28(%esp)
	jmp	L193
L81:
	fildl	32(%esp)
	fmuls	LC0
	jmp	L214
L232:
	leal	1(%ebp), %esi
	cmpl	$15, %ecx
	jg	L119
	incl	%ecx
	movl	$0, 36(%esp)
	movl	%ecx, 40(%esp)
	movl	64(%esp), %ecx
	decl	%ecx
	movl	68(%esp), %edx
	subl	%ebp, %ecx
	movl	%edi, 72(%esp)
	movl	%ecx, 60(%esp)
	jmp	L42
L237:
	leal	-48(%ecx), %eax
	cmpb	$9, %al
	ja	L120
	movl	24(%esp), %eax
	movl	28(%esp), %edx
	shldl	$4, %eax, %edx
	sall	$4, %eax
	movl	40(%esp), %ebp
L114:
	leal	-48(%ecx), %edi
L44:
	movl	%edi, %ebx
	orl	%eax, %edi
	sarl	$31, %ebx
	movl	%edi, 24(%esp)
	movl	%ebx, %edi
	movl	24(%esp), %eax
	orl	%edx, %edi
	movl	$1, %edx
	orl	%edi, %eax
	movl	%edi, 28(%esp)
	cmpl	$1, %eax
	movl	40(%esp), %edi
	adcl	$0, 36(%esp)
	movl	%ebp, %eax
	movl	36(%esp), %ecx
	incl	%edi
	subl	%ecx, %eax
	incl	%esi
	movl	%edi, 40(%esp)
	cmpl	$15, %eax
	jg	L120
L42:
	movsbl	(%esi), %ecx
	movb	%cl, %al
	movl	60(%esp), %ebp
	andl	$-33, %eax
	addl	%esi, %ebp
	subl	$65, %eax
	cmpb	$5, %al
	ja	L237
	movl	24(%esp), %eax
	movl	28(%esp), %edx
	leal	-48(%ecx), %ebx
	movl	40(%esp), %ebp
	shldl	$4, %eax, %edx
	sall	$4, %eax
	cmpb	$9, %bl
	jbe	L114
	leal	-65(%ecx), %ebx
	leal	-55(%ecx), %edi
	cmpb	$5, %bl
	jbe	L44
	leal	-87(%ecx), %edi
	jmp	L44
L120:
	movl	%ebp, 40(%esp)
	movl	%edx, 68(%esp)
	movl	72(%esp), %edi
	movl	%esi, %ebp
L41:
	movl	24(%esp), %edx
	orl	28(%esp), %edx
	je	L49
	movl	64(%esp), %ebx
	testl	%ebx, %ebx
	jne	L49
	movl	36(%esp), %eax
	movl	40(%esp), %ebx
	negl	%eax
	sall	$2, %eax
	xorl	%edx, %edx
	movl	%eax, 56(%esp)
	leal	(%eax,%ebx,4), %ecx
	xorl	%eax, %eax
	testb	$32, %cl
	sete	%al
	setne	%dl
	sall	%cl, %edx
	sall	%cl, %eax
	movl	%eax, 48(%esp)
	movl	%edx, 52(%esp)
	movl	48(%esp), %eax
	movl	24(%esp), %ebx
	movl	52(%esp), %edx
	movl	28(%esp), %ecx
	andl	%ebx, %eax
	andl	%ecx, %edx
	orl	%eax, %edx
	jne	L122
	movl	48(%esp), %eax
	movl	52(%esp), %edx
L180:
	movl	56(%esp), %ecx
	movl	28(%esp), %ebx
	decl	%ecx
	shrdl	$1, %edx, %eax
	shrl	%edx
	movl	%ecx, 56(%esp)
	movl	24(%esp), %ecx
	andl	%edx, %ebx
	andl	%eax, %ecx
	orl	%ecx, %ebx
	je	L180
L218:
	movl	%eax, 48(%esp)
	movl	%edx, 52(%esp)
	movl	%esi, %eax
	jmp	L40
L234:
	testb	%bl, %bl
	jne	L131
L64:
	leal	-48(%edx), %eax
	cmpb	$9, %al
	ja	L63
L68:
	incl	%ebp
	cmpb	$0, 40(%esp)
	jne	L72
	leal	-48(%edx), %ecx
	movb	%dl, 36(%esp)
	movb	%cl, 64(%esp)
	movl	$1, 40(%esp)
	movl	$0, 44(%esp)
	movl	$1, 60(%esp)
L73:
	movl	56(%esp), %eax
	movl	%eax, %edx
	movl	%eax, 48(%esp)
	sarl	$31, %edx
	movl	%edx, 52(%esp)
	cmpl	$0, %edx
	jg	L124
	jl	L133
	cmpl	$16383, %eax
	ja	L124
L133:
	cmpb	$9, 64(%esp)
	ja	L238
L69:
	xorl	%ecx, %ecx
	xorl	%ebx, %ebx
	movl	%edi, 64(%esp)
L78:
	movl	%ecx, %eax
	movl	%ebx, %edx
	shldl	$1, %eax, %edx
	shldl	$3, %ecx, %ebx
	addl	%eax, %eax
	movl	40(%esp), %edi
	sall	$3, %ecx
	leal	1(%ebp), %esi
	addl	%ecx, %eax
	movsbl	36(%esp), %ecx
	adcl	%ebx, %edx
	subl	$48, %ecx
	movl	%ecx, %ebx
	sarl	$31, %ebx
	addl	%eax, %ecx
	adcl	%edx, %ebx
	movl	44(%esp), %eax
	imull	%ecx, %eax
	imull	%ebx, %edi
	addl	%eax, %edi
	movl	40(%esp), %eax
	mull	%ecx
	movl	%eax, 16(%esp)
	addl	%edi, %edx
	movl	16(%esp), %eax
	movl	%edx, 20(%esp)
	addl	48(%esp), %eax
	movl	20(%esp), %edx
	adcl	52(%esp), %edx
	cmpl	$0, %edx
	jl	L76
	jle	L239
L134:
	movb	1(%ebp), %al
	movl	60(%esp), %edx
	subl	$48, %eax
	movl	64(%esp), %edi
	imull	%ecx, %edx
	movb	%al, 64(%esp)
	movl	%esi, %ebp
	jmp	L71
L239:
	cmpl	$16383, %eax
	ja	L134
L76:
	movb	(%esi), %dl
	movl	%esi, %ebp
	movb	%dl, %al
	movb	%dl, 36(%esp)
	subl	$48, %eax
	cmpb	$9, %al
	jbe	L78
	movl	60(%esp), %esi
	movl	64(%esp), %edi
	imull	%ecx, %esi
L75:
	movl	56(%esp), %eax
	addl	%esi, %eax
	movl	%eax, 56(%esp)
	jmp	L63
L49:
	movl	40(%esp), %ecx
	movl	64(%esp), %eax
	subl	%eax, %ecx
	testl	%ecx, %ecx
	jle	L122
	sall	$2, %ecx
	movl	48(%esp), %eax
	movl	52(%esp), %edx
	shldl	%cl, %eax, %edx
	sall	%cl, %eax
	testb	$32, %cl
	je	L218
	movl	%eax, %edx
	xorl	%eax, %eax
	jmp	L218
L230:
	xorl	%edx, %edx
	fldz
	jmp	L23
L108:
	fdivrp	%st, %st(1)
	jmp	L105
L82:
	cmpl	$-16382, 56(%esp)
	jge	L83
	movl	$2, _errno
	fldz
	jmp	L214
L55:
	leal	-65(%edx), %eax
	cmpb	$5, %al
	jbe	L57
	movsbl	%dl, %eax
	subl	$87, %eax
	jmp	L56
L72:
	leal	2(%ecx), %ebp
	movb	2(%ecx), %cl
	movb	%cl, 36(%esp)
	subl	$48, %ecx
	movb	%cl, 64(%esp)
	movl	$-1, 40(%esp)
	movl	$-1, 44(%esp)
	movl	$-1, 60(%esp)
	jmp	L73
L97:
	movsbl	2(%ebp), %eax
	orl	$-1, %ebx
	addl	$2, %ebp
	leal	-48(%eax), %edx
	jmp	L98
L83:
	cmpl	$1, 32(%esp)
	movb	121(%esp), %al
	movl	24(%esp), %ebx
	setne	%dl
	sall	$7, %edx
	andl	$127, %eax
	orl	%edx, %eax
	movl	56(%esp), %edx
	movb	%al, 121(%esp)
	addl	$16383, %edx
	movl	120(%esp), %eax
	andl	$32767, %edx
	andl	$-32768, %eax
	movl	%ebx, 112(%esp)
	orl	%edx, %eax
	movw	%ax, 120(%esp)
	movl	28(%esp), %eax
	movl	%eax, 116(%esp)
	fldt	112(%esp)
	jmp	L214
L126:
	movl	%eax, %ebp
	jmp	L86
L235:
	cmpl	$16383, %eax
	ja	L124
L123:
	movl	$1, 40(%esp)
	movl	$0, 44(%esp)
	movl	$1, 60(%esp)
	jmp	L69
L122:
	movl	%esi, %eax
	jmp	L40
L238:
	xorl	%esi, %esi
	jmp	L75
L119:
	movl	64(%esp), %eax
	movl	%esi, %ebp
	movl	%eax, 40(%esp)
	movl	$0, 36(%esp)
	jmp	L41
L236:
	movl	%ebp, 16(%esp)
	jmp	L32
	.cfi_endproc
LFE0:
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
	.p2align 2
LC0:
	.long	0
	.p2align 2
LC6:
	.long	1092616192
	.p2align 4
LC7:
	.long	875965924
	.long	-827436209
	.long	9579
	.ident	"GCC: (GNU) 4.7.4"
