	.file	"k_standard.c"
	.section .text
LC0:
	.ascii "acos\0"
LC1:
	.ascii "acosf\0"
LC2:
	.ascii "asin\0"
LC3:
	.ascii "asinf\0"
LC4:
	.ascii "atan2\0"
LC5:
	.ascii "atan2f\0"
LC6:
	.ascii "hypot\0"
LC7:
	.ascii "hypotf\0"
LC8:
	.ascii "cosh\0"
LC9:
	.ascii "coshf\0"
LC10:
	.ascii "exp\0"
LC11:
	.ascii "expf\0"
LC12:
	.ascii "y0\0"
LC13:
	.ascii "y0f\0"
LC14:
	.ascii "y1\0"
LC15:
	.ascii "y1f\0"
LC16:
	.ascii "yn\0"
LC17:
	.ascii "ynf\0"
LC18:
	.ascii "lgamma\0"
LC19:
	.ascii "lgammaf\0"
LC20:
	.ascii "log\0"
LC21:
	.ascii "logf\0"
LC22:
	.ascii "log10\0"
LC23:
	.ascii "log10f\0"
LC24:
	.ascii "pow\0"
LC25:
	.ascii "powf\0"
LC26:
	.ascii "sinh\0"
LC27:
	.ascii "sinhf\0"
LC30:
	.ascii "sqrt\0"
LC31:
	.ascii "sqrtf\0"
LC32:
	.ascii "fmod\0"
LC33:
	.ascii "fmodf\0"
LC34:
	.ascii "remainder\0"
LC35:
	.ascii "remainderf\0"
LC36:
	.ascii "acosh\0"
LC37:
	.ascii "acoshf\0"
LC38:
	.ascii "atanh\0"
LC39:
	.ascii "atanhf\0"
LC40:
	.ascii "scalb\0"
LC41:
	.ascii "scalbf\0"
LC42:
	.ascii "j0\0"
LC43:
	.ascii "j0f\0"
LC44:
	.ascii "j1\0"
LC45:
	.ascii "j1f\0"
LC46:
	.ascii "jn\0"
LC47:
	.ascii "jnf\0"
LC48:
	.ascii "gamma\0"
LC49:
	.ascii "gammaf\0"
LC50:
	.ascii "acos: DOMAIN error\12\0"
LC51:
	.ascii "asin: DOMAIN error\12\0"
LC53:
	.ascii "atan2: DOMAIN error\12\0"
LC54:
	.ascii "y0: DOMAIN error\12\0"
LC55:
	.ascii "y1: DOMAIN error\12\0"
LC56:
	.ascii "yn: DOMAIN error\12\0"
LC57:
	.ascii "lgamma: SING error\12\0"
LC58:
	.ascii "log: SING error\12\0"
LC59:
	.ascii "log: DOMAIN error\12\0"
LC60:
	.ascii "log10: SING error\12\0"
LC61:
	.ascii "log10: DOMAIN error\12\0"
LC63:
	.ascii "pow(0,0): DOMAIN error\12\0"
LC65:
	.ascii "pow(0,neg): DOMAIN error\12\0"
	.p2align 2
LC66:
	.ascii "neg**non-integral: DOMAIN error\12\0"
LC67:
	.ascii "sqrt: DOMAIN error\12\0"
LC68:
	.ascii "fmod:  DOMAIN error\12\0"
LC69:
	.ascii "remainder: DOMAIN error\12\0"
LC70:
	.ascii "acosh: DOMAIN error\12\0"
LC71:
	.ascii "atanh: DOMAIN error\12\0"
LC72:
	.ascii "atanh: SING error\12\0"
LC74:
	.ascii ": TLOSS error\12\0"
LC75:
	.ascii "gamma: SING error\12\0"
	.p2align 4,,15
	.globl	___kernel_standard
___kernel_standard:
LFB0:
	.cfi_startproc
	subl	$108, %esp
	.cfi_def_cfa_offset 112
	fldl	112(%esp)
	fldl	120(%esp)
	fxch	%st(1)
	movl	128(%esp), %eax
	movl	$0, 92(%esp)
	fstl	68(%esp)
	fxch	%st(1)
	cmpl	$142, %eax
	fstl	76(%esp)
	ja	L355
	jmp	*L45(,%eax,4)
	.p2align 2
	.p2align 2
L45:
	.long	L356
	.long	L3
	.long	L4
	.long	L5
	.long	L6
	.long	L7
	.long	L8
	.long	L9
	.long	L11
	.long	L11
	.long	L13
	.long	L13
	.long	L15
	.long	L15
	.long	L16
	.long	L17
	.long	L18
	.long	L19
	.long	L20
	.long	L21
	.long	L22
	.long	L23
	.long	L24
	.long	L25
	.long	L26
	.long	L27
	.long	L28
	.long	L29
	.long	L30
	.long	L31
	.long	L32
	.long	L33
	.long	L34
	.long	L35
	.long	L36
	.long	L37
	.long	L38
	.long	L39
	.long	L40
	.long	L41
	.long	L42
	.long	L43
	.long	L44
	.long	L356
	.long	L356
	.long	L356
	.long	L356
	.long	L356
	.long	L356
	.long	L356
	.long	L356
	.long	L356
	.long	L356
	.long	L356
	.long	L356
	.long	L356
	.long	L356
	.long	L356
	.long	L356
	.long	L356
	.long	L356
	.long	L356
	.long	L356
	.long	L356
	.long	L356
	.long	L356
	.long	L356
	.long	L356
	.long	L356
	.long	L356
	.long	L356
	.long	L356
	.long	L356
	.long	L356
	.long	L356
	.long	L356
	.long	L356
	.long	L356
	.long	L356
	.long	L356
	.long	L356
	.long	L356
	.long	L356
	.long	L356
	.long	L356
	.long	L356
	.long	L356
	.long	L356
	.long	L356
	.long	L356
	.long	L356
	.long	L356
	.long	L356
	.long	L356
	.long	L356
	.long	L356
	.long	L356
	.long	L356
	.long	L356
	.long	L356
	.long	L356
	.long	L3
	.long	L4
	.long	L5
	.long	L6
	.long	L7
	.long	L8
	.long	L9
	.long	L11
	.long	L11
	.long	L13
	.long	L13
	.long	L15
	.long	L15
	.long	L16
	.long	L17
	.long	L18
	.long	L19
	.long	L20
	.long	L21
	.long	L22
	.long	L23
	.long	L24
	.long	L25
	.long	L26
	.long	L27
	.long	L28
	.long	L29
	.long	L30
	.long	L31
	.long	L32
	.long	L33
	.long	L34
	.long	L35
	.long	L36
	.long	L37
	.long	L38
	.long	L39
	.long	L40
	.long	L41
	.long	L42
	.long	L43
	.long	L44
	.p2align 4,,7
L15:
	fstp	%st(0)
	fstp	%st(0)
	movl	$1, 60(%esp)
	movl	$LC17, %edx
	cmpl	$99, %eax
	jg	L99
	movl	$LC16, %edx
L99:
	movl	___fdlib_version, %eax
	movl	%edx, 64(%esp)
	testl	%eax, %eax
	jne	L100
	movl	$-536870912, 84(%esp)
	movl	$-940572673, 88(%esp)
L101:
	leal	60(%esp), %eax
	movl	%eax, (%esp)
	call	_matherr
	testl	%eax, %eax
	jne	L303
	movl	___fdlib_version, %ecx
	testl	%ecx, %ecx
	je	L351
	.p2align 4,,7
L242:
	movl	$1, _errno
L303:
	movl	92(%esp), %eax
L48:
	testl	%eax, %eax
	je	L243
	movl	%eax, _errno
	jmp	L243
	.p2align 4,,7
L355:
	fstp	%st(0)
	fstp	%st(0)
	jmp	L243
	.p2align 4,,7
L356:
	fstp	%st(0)
	fstp	%st(0)
	.p2align 4,,7
L243:
	fldl	84(%esp)
	addl	$108, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L13:
	.cfi_restore_state
	fstp	%st(0)
	fstp	%st(0)
	movl	$1, 60(%esp)
	movl	$LC15, %edx
	cmpl	$99, %eax
	jg	L89
	movl	$LC14, %edx
L89:
	movl	___fdlib_version, %eax
	movl	%edx, 64(%esp)
	testl	%eax, %eax
	jne	L90
	movl	$-536870912, 84(%esp)
	movl	$-940572673, 88(%esp)
L91:
	leal	60(%esp), %eax
	movl	%eax, (%esp)
	call	_matherr
	testl	%eax, %eax
	jne	L303
	movl	___fdlib_version, %eax
	testl	%eax, %eax
	jne	L242
	movl	$___dj_stderr, 12(%esp)
	movl	$17, 8(%esp)
	movl	$1, 4(%esp)
	movl	$LC55, (%esp)
	call	_fwrite
	jmp	L242
	.p2align 4,,7
L11:
	fstp	%st(0)
	fstp	%st(0)
	movl	$1, 60(%esp)
	movl	$LC13, %edx
	cmpl	$99, %eax
	jg	L79
	movl	$LC12, %edx
L79:
	movl	___fdlib_version, %eax
	movl	%edx, 64(%esp)
	testl	%eax, %eax
	jne	L80
	movl	$-536870912, 84(%esp)
	movl	$-940572673, 88(%esp)
L81:
	leal	60(%esp), %eax
	movl	%eax, (%esp)
	call	_matherr
	testl	%eax, %eax
	jne	L303
	movl	___fdlib_version, %eax
	testl	%eax, %eax
	jne	L242
	movl	$___dj_stderr, 12(%esp)
	movl	$17, 8(%esp)
	movl	$1, 4(%esp)
	movl	$LC54, (%esp)
	call	_fwrite
	jmp	L242
	.p2align 4,,7
L19:
	fstp	%st(0)
	fstp	%st(0)
	movl	$1, 60(%esp)
	movl	$LC21, %edx
	cmpl	$99, %eax
	jg	L118
	movl	$LC20, %edx
L118:
	movl	___fdlib_version, %eax
	movl	%edx, 64(%esp)
	testl	%eax, %eax
	jne	L119
	movl	$-536870912, 84(%esp)
	movl	$-940572673, 88(%esp)
L120:
	leal	60(%esp), %eax
	movl	%eax, (%esp)
	call	_matherr
	testl	%eax, %eax
	jne	L303
	movl	___fdlib_version, %eax
	testl	%eax, %eax
	jne	L242
	movl	$___dj_stderr, 12(%esp)
	movl	$18, 8(%esp)
	movl	$1, 4(%esp)
	movl	$LC59, (%esp)
	call	_fwrite
	jmp	L242
	.p2align 4,,7
L18:
	fstp	%st(0)
	fstp	%st(0)
	movl	$2, 60(%esp)
	movl	$LC21, %edx
	cmpl	$99, %eax
	jg	L113
	movl	$LC20, %edx
L113:
	movl	___fdlib_version, %eax
	movl	%edx, 64(%esp)
	testl	%eax, %eax
	jne	L114
	movl	$-536870912, 84(%esp)
	movl	$-940572673, 88(%esp)
L115:
	leal	60(%esp), %eax
	movl	%eax, (%esp)
	call	_matherr
	testl	%eax, %eax
	jne	L303
	movl	___fdlib_version, %eax
	testl	%eax, %eax
	jne	L242
	movl	$___dj_stderr, 12(%esp)
	movl	$16, 8(%esp)
	movl	$1, 4(%esp)
	movl	$LC58, (%esp)
	call	_fwrite
	jmp	L242
	.p2align 4,,7
L17:
	fstp	%st(0)
	fstp	%st(0)
	movl	$2, 60(%esp)
	movl	$LC19, %edx
	cmpl	$99, %eax
	jg	L108
	movl	$LC18, %edx
L108:
	movl	___fdlib_version, %eax
	movl	%edx, 64(%esp)
	testl	%eax, %eax
	jne	L109
	movl	$-536870912, 84(%esp)
	movl	$1206910975, 88(%esp)
L110:
	leal	60(%esp), %eax
	movl	%eax, (%esp)
	call	_matherr
	testl	%eax, %eax
	jne	L303
	movl	___fdlib_version, %edx
	testl	%edx, %edx
	jne	L242
	movl	$___dj_stderr, 12(%esp)
	movl	$19, 8(%esp)
	movl	$1, 4(%esp)
	movl	$LC57, (%esp)
	call	_fwrite
	jmp	L242
	.p2align 4,,7
L21:
	fstp	%st(0)
	fstp	%st(0)
	movl	$1, 60(%esp)
	movl	$LC23, %edx
	cmpl	$99, %eax
	jg	L128
	movl	$LC22, %edx
L128:
	movl	___fdlib_version, %eax
	movl	%edx, 64(%esp)
	testl	%eax, %eax
	jne	L129
	movl	$-536870912, 84(%esp)
	movl	$-940572673, 88(%esp)
L130:
	leal	60(%esp), %eax
	movl	%eax, (%esp)
	call	_matherr
	testl	%eax, %eax
	jne	L303
	movl	___fdlib_version, %eax
	testl	%eax, %eax
	jne	L242
	movl	$___dj_stderr, 12(%esp)
	movl	$20, 8(%esp)
	movl	$1, 4(%esp)
	movl	$LC61, (%esp)
	call	_fwrite
	jmp	L242
	.p2align 4,,7
L16:
	fstp	%st(0)
	fstp	%st(0)
	movl	$3, 60(%esp)
	movl	$LC19, %edx
	cmpl	$99, %eax
	jg	L230
	movl	$LC18, %edx
	.p2align 4,,7
L230:
	movl	___fdlib_version, %eax
	movl	%edx, 64(%esp)
	testl	%eax, %eax
	jne	L231
	movl	$-536870912, 84(%esp)
	movl	$1206910975, 88(%esp)
	jmp	L232
	.p2align 4,,7
L357:
	fstp	%st(0)
	.p2align 4,,7
L232:
	leal	60(%esp), %eax
	movl	%eax, (%esp)
	call	_matherr
	testl	%eax, %eax
	jne	L303
L233:
	movl	$2, _errno
	movl	92(%esp), %eax
	jmp	L48
	.p2align 4,,7
L20:
	fstp	%st(0)
	fstp	%st(0)
	movl	$2, 60(%esp)
	movl	$LC23, %edx
	cmpl	$99, %eax
	jg	L123
	movl	$LC22, %edx
L123:
	movl	___fdlib_version, %eax
	movl	%edx, 64(%esp)
	testl	%eax, %eax
	jne	L124
	movl	$-536870912, 84(%esp)
	movl	$-940572673, 88(%esp)
L125:
	leal	60(%esp), %eax
	movl	%eax, (%esp)
	call	_matherr
	testl	%eax, %eax
	jne	L303
	movl	___fdlib_version, %eax
	testl	%eax, %eax
	jne	L242
	movl	$___dj_stderr, 12(%esp)
	movl	$18, 8(%esp)
	movl	$1, 4(%esp)
	movl	$LC60, (%esp)
	call	_fwrite
	jmp	L242
	.p2align 4,,7
L37:
	fstp	%st(0)
	fstp	%st(0)
	movl	$5, 60(%esp)
	movl	$LC13, %edx
	cmpl	$99, %eax
	jg	L226
	movl	$LC12, %edx
	.p2align 4,,7
L226:
	movl	%edx, 64(%esp)
	movl	$0, 84(%esp)
	movl	$0, 88(%esp)
	cmpl	$2, ___fdlib_version
	je	L305
	leal	60(%esp), %eax
	movl	%eax, (%esp)
	call	_matherr
	testl	%eax, %eax
	jne	L303
	movl	___fdlib_version, %edx
	testl	%edx, %edx
	jne	L233
	movl	64(%esp), %eax
	movl	$___dj_stderr, 4(%esp)
	movl	%eax, (%esp)
	call	_fputs
	movl	$___dj_stderr, 12(%esp)
	movl	$14, 8(%esp)
	movl	$1, 4(%esp)
	movl	$LC74, (%esp)
	call	_fwrite
	jmp	L233
	.p2align 4,,7
L31:
	fstp	%st(0)
	fstp	%st(0)
	movl	$1, 60(%esp)
	movl	$LC37, %edx
	cmpl	$99, %eax
	jg	L181
	movl	$LC36, %edx
L181:
	movl	%edx, 64(%esp)
	call	_nan
	cmpl	$2, ___fdlib_version
	fstpl	84(%esp)
	je	L242
	leal	60(%esp), %eax
	movl	%eax, (%esp)
	call	_matherr
	testl	%eax, %eax
	jne	L303
	movl	___fdlib_version, %eax
	testl	%eax, %eax
	jne	L242
	movl	$___dj_stderr, 12(%esp)
	movl	$20, 8(%esp)
	movl	$1, 4(%esp)
	movl	$LC70, (%esp)
	call	_fwrite
	jmp	L242
	.p2align 4,,7
L39:
	fstp	%st(0)
	fstp	%st(0)
	movl	$5, 60(%esp)
	movl	$LC15, %edx
	cmpl	$99, %eax
	jg	L226
	movl	$LC14, %edx
	jmp	L226
	.p2align 4,,7
L38:
	fstp	%st(0)
	fstp	%st(0)
	movl	$5, 60(%esp)
	movl	$LC45, %edx
	cmpl	$99, %eax
	jg	L226
	movl	$LC44, %edx
	jmp	L226
	.p2align 4,,7
L44:
	fstp	%st(0)
	movl	$1, 60(%esp)
	movl	$LC25, %edx
	cmpl	$99, %eax
	jg	L239
	movl	$LC24, %edx
L239:
	movl	___fdlib_version, %eax
	movl	%edx, 64(%esp)
	fstpl	84(%esp)
	cmpl	$2, %eax
	jne	L352
L292:
	movl	$0, 84(%esp)
	movl	$1072693248, 88(%esp)
	jmp	L243
	.p2align 4,,7
L9:
	fstp	%st(0)
	fstp	%st(0)
	movl	$4, 60(%esp)
	movl	$LC11, %edx
	cmpl	$99, %eax
	jg	L145
	movl	$LC10, %edx
L145:
	movl	%edx, 64(%esp)
	movl	$0, 84(%esp)
	movl	$0, 88(%esp)
	cmpl	$2, ___fdlib_version
	jne	L232
	.p2align 4,,7
L305:
	fldl	84(%esp)
	movl	$2, _errno
	addl	$108, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L23:
	.cfi_restore_state
	movl	$3, 60(%esp)
	movl	$LC25, %edx
	cmpl	$99, %eax
	jg	L136
	movl	$LC24, %edx
L136:
	movl	___fdlib_version, %eax
	movl	%edx, 64(%esp)
	testl	%eax, %eax
	jne	L137
	fldz
	fucomp	%st(2)
	fnstsw	%ax
	fstp	%st(1)
	movl	$-536870912, 84(%esp)
	movl	$1206910975, 88(%esp)
	testb	$69, %ah
	jne	L357
	fmuls	LC64
	fstl	(%esp)
	fstpl	16(%esp)
	call	_rint
	fldl	16(%esp)
	fxch	%st(1)
	fucompp
	fnstsw	%ax
	andb	$69, %ah
	xorb	$64, %ah
	je	L302
	movl	$-536870912, 84(%esp)
	movl	$-940572673, 88(%esp)
	movl	___fdlib_version, %eax
L141:
	cmpl	$2, %eax
	je	L233
	jmp	L232
	.p2align 4,,7
L22:
	fstp	%st(0)
	fstp	%st(0)
	movl	$1, 60(%esp)
	movl	$LC25, %edx
	cmpl	$99, %eax
	jg	L133
	movl	$LC24, %edx
L133:
	movl	___fdlib_version, %eax
	movl	%edx, 64(%esp)
	movl	$0, 84(%esp)
	movl	$0, 88(%esp)
	testl	%eax, %eax
	jne	L292
	leal	60(%esp), %eax
	movl	%eax, (%esp)
	call	_matherr
	testl	%eax, %eax
	jne	L303
	movl	$___dj_stderr, 12(%esp)
	movl	$23, 8(%esp)
	movl	$1, 4(%esp)
	movl	$LC63, (%esp)
	call	_fwrite
	movl	$1, _errno
	movl	92(%esp), %eax
	jmp	L48
	.p2align 4,,7
L6:
	fstp	%st(0)
	fstp	%st(0)
	movl	$3, 60(%esp)
	movl	$LC7, %edx
	cmpl	$99, %eax
	jg	L230
	movl	$LC6, %edx
	jmp	L230
	.p2align 4,,7
L5:
	fstpl	68(%esp)
	movl	$1, 60(%esp)
	movl	$LC5, %edx
	fstpl	76(%esp)
	cmpl	$99, %eax
	jg	L55
	movl	$LC4, %edx
L55:
	movl	%edx, 64(%esp)
	movl	$0, 84(%esp)
	movl	$0, 88(%esp)
	cmpl	$2, ___fdlib_version
	je	L304
	leal	60(%esp), %eax
	movl	%eax, (%esp)
	call	_matherr
	testl	%eax, %eax
	jne	L303
	movl	___fdlib_version, %eax
	testl	%eax, %eax
	jne	L242
	movl	$___dj_stderr, 12(%esp)
	movl	$20, 8(%esp)
	movl	$1, 4(%esp)
	movl	$LC53, (%esp)
	call	_fwrite
	jmp	L242
	.p2align 4,,7
L4:
	fstp	%st(0)
	fstp	%st(0)
	movl	$1, 60(%esp)
	movl	$LC3, %edx
	cmpl	$99, %eax
	jg	L51
	movl	$LC2, %edx
L51:
	movl	%edx, 64(%esp)
	call	_nan
	cmpl	$2, ___fdlib_version
	fstpl	84(%esp)
	je	L242
	leal	60(%esp), %eax
	movl	%eax, (%esp)
	call	_matherr
	testl	%eax, %eax
	jne	L303
	movl	___fdlib_version, %eax
	testl	%eax, %eax
	jne	L242
	movl	$___dj_stderr, 12(%esp)
	movl	$19, 8(%esp)
	movl	$1, 4(%esp)
	movl	$LC51, (%esp)
	call	_fwrite
	jmp	L242
	.p2align 4,,7
L35:
	fstp	%st(0)
	movl	$4, 60(%esp)
	movl	$LC41, %edx
	cmpl	$99, %eax
	jg	L202
	movl	$LC40, %edx
L202:
	fxam
	fnstsw	%ax
	fstp	%st(0)
	movl	%edx, 64(%esp)
	fldz
	testb	$2, %ah
	je	L203
	fstp	%st(0)
	fldz
L325:
	fchs
L203:
	fstpl	84(%esp)
	cmpl	$2, ___fdlib_version
	jne	L232
	jmp	L305
	.p2align 4,,7
L34:
	fstp	%st(0)
	movl	$3, 60(%esp)
	movl	$LC41, %edx
	cmpl	$99, %eax
	jg	L196
	movl	$LC40, %edx
L196:
	fldz
	fxch	%st(1)
	fucompp
	fnstsw	%ax
	movl	%edx, 64(%esp)
	fldl	___dj_huge_val
	testb	$69, %ah
	je	L203
	jmp	L325
	.p2align 4,,7
L33:
	fstp	%st(0)
	movl	$2, 60(%esp)
	movl	$LC39, %edx
	cmpl	$99, %eax
	jg	L189
	movl	$LC38, %edx
L189:
	fldz
	fucompp
	fnstsw	%ax
	movl	%edx, 64(%esp)
	testb	$69, %ah
	je	L353
	call	_infinity
L192:
	fstpl	84(%esp)
	cmpl	$2, ___fdlib_version
	je	L242
	leal	60(%esp), %eax
	movl	%eax, (%esp)
	call	_matherr
	testl	%eax, %eax
	jne	L303
	movl	___fdlib_version, %ecx
	testl	%ecx, %ecx
	jne	L242
	movl	$___dj_stderr, 12(%esp)
	movl	$18, 8(%esp)
	movl	$1, 4(%esp)
	movl	$LC72, (%esp)
	call	_fwrite
	jmp	L242
	.p2align 4,,7
L32:
	fstp	%st(0)
	fstp	%st(0)
	movl	$1, 60(%esp)
	movl	$LC39, %edx
	cmpl	$99, %eax
	jg	L185
	movl	$LC38, %edx
L185:
	movl	%edx, 64(%esp)
	call	_nan
	cmpl	$2, ___fdlib_version
	fstpl	84(%esp)
	je	L242
	leal	60(%esp), %eax
	movl	%eax, (%esp)
	call	_matherr
	testl	%eax, %eax
	jne	L303
	movl	___fdlib_version, %eax
	testl	%eax, %eax
	jne	L242
	movl	$___dj_stderr, 12(%esp)
	movl	$20, 8(%esp)
	movl	$1, 4(%esp)
	movl	$LC71, (%esp)
	call	_fwrite
	jmp	L242
	.p2align 4,,7
L36:
	fstp	%st(0)
	fstp	%st(0)
	movl	$5, 60(%esp)
	movl	$LC43, %edx
	cmpl	$99, %eax
	jg	L226
	movl	$LC42, %edx
	jmp	L226
	.p2align 4,,7
L8:
	fstp	%st(0)
	fstp	%st(0)
	movl	$3, 60(%esp)
	movl	$LC11, %edx
	cmpl	$99, %eax
	jg	L230
	movl	$LC10, %edx
	jmp	L230
	.p2align 4,,7
L7:
	fstp	%st(0)
	fstp	%st(0)
	movl	$3, 60(%esp)
	movl	$LC9, %edx
	cmpl	$99, %eax
	jg	L230
	movl	$LC8, %edx
	jmp	L230
	.p2align 4,,7
L42:
	fstp	%st(0)
	fstp	%st(0)
	movl	$3, 60(%esp)
	movl	$LC49, %edx
	cmpl	$99, %eax
	jg	L230
	movl	$LC48, %edx
	jmp	L230
	.p2align 4,,7
L43:
	fstp	%st(0)
	fstp	%st(0)
	movl	$2, 60(%esp)
	movl	$LC49, %edx
	cmpl	$99, %eax
	jg	L234
	movl	$LC48, %edx
L234:
	movl	___fdlib_version, %eax
	movl	%edx, 64(%esp)
	testl	%eax, %eax
	jne	L235
	movl	$-536870912, 84(%esp)
	movl	$1206910975, 88(%esp)
L236:
	leal	60(%esp), %eax
	movl	%eax, (%esp)
	call	_matherr
	testl	%eax, %eax
	jne	L303
	movl	___fdlib_version, %eax
	testl	%eax, %eax
	jne	L242
	movl	$___dj_stderr, 12(%esp)
	movl	$18, 8(%esp)
	movl	$1, 4(%esp)
	movl	$LC75, (%esp)
	call	_fwrite
	jmp	L242
	.p2align 4,,7
L27:
	fstp	%st(0)
	movl	$3, 60(%esp)
	movl	$LC27, %edx
	cmpl	$99, %eax
	jg	L158
	movl	$LC26, %edx
L158:
	movl	%edx, 64(%esp)
	movl	___fdlib_version, %edx
	fldz
	fxch	%st(1)
	fucompp
	fnstsw	%ax
	testl	%edx, %edx
	jne	L159
	testb	$69, %ah
	jne	L299
	flds	LC28
L160:
	fstpl	84(%esp)
	jmp	L232
	.p2align 4,,7
L41:
	fstp	%st(0)
	fstp	%st(0)
	movl	$5, 60(%esp)
	movl	$LC17, %edx
	cmpl	$99, %eax
	jg	L226
	movl	$LC16, %edx
	jmp	L226
	.p2align 4,,7
L40:
	fstp	%st(0)
	fstp	%st(0)
	movl	$5, 60(%esp)
	movl	$LC47, %edx
	cmpl	$99, %eax
	jg	L226
	movl	$LC46, %edx
	jmp	L226
	.p2align 4,,7
L29:
	fstp	%st(0)
	movl	$1, 60(%esp)
	movl	$LC33, %edx
	cmpl	$99, %eax
	jg	L172
	movl	$LC32, %edx
L172:
	movl	___fdlib_version, %eax
	movl	%edx, 64(%esp)
	testl	%eax, %eax
	jne	L173
	fstpl	84(%esp)
L174:
	leal	60(%esp), %eax
	movl	%eax, (%esp)
	call	_matherr
	testl	%eax, %eax
	jne	L303
	movl	___fdlib_version, %eax
	testl	%eax, %eax
	jne	L242
	movl	$___dj_stderr, 12(%esp)
	movl	$20, 8(%esp)
	movl	$1, 4(%esp)
	movl	$LC68, (%esp)
	call	_fwrite
	jmp	L242
	.p2align 4,,7
L30:
	fstp	%st(0)
	fstp	%st(0)
	movl	$1, 60(%esp)
	movl	$LC35, %edx
	cmpl	$99, %eax
	jg	L177
	movl	$LC34, %edx
L177:
	movl	%edx, 64(%esp)
	call	_nan
	cmpl	$2, ___fdlib_version
	fstpl	84(%esp)
	je	L242
	leal	60(%esp), %eax
	movl	%eax, (%esp)
	call	_matherr
	testl	%eax, %eax
	jne	L303
	movl	___fdlib_version, %eax
	testl	%eax, %eax
	jne	L242
	movl	$___dj_stderr, 12(%esp)
	movl	$24, 8(%esp)
	movl	$1, 4(%esp)
	movl	$LC69, (%esp)
	call	_fwrite
	jmp	L242
	.p2align 4,,7
L3:
	fstp	%st(0)
	fstp	%st(0)
	movl	$1, 60(%esp)
	movl	$LC1, %edx
	cmpl	$99, %eax
	jg	L46
	movl	$LC0, %edx
L46:
	movl	%edx, 64(%esp)
	call	_nan
	cmpl	$2, ___fdlib_version
	fstpl	84(%esp)
	je	L242
	leal	60(%esp), %eax
	movl	%eax, (%esp)
	call	_matherr
	testl	%eax, %eax
	jne	L303
	movl	___fdlib_version, %eax
	testl	%eax, %eax
	jne	L242
	movl	$___dj_stderr, 12(%esp)
	movl	$19, 8(%esp)
	movl	$1, 4(%esp)
	movl	$LC50, (%esp)
	call	_fwrite
	jmp	L242
	.p2align 4,,7
L25:
	fstp	%st(0)
	fstp	%st(0)
	movl	$1, 60(%esp)
	movl	$LC25, %edx
	cmpl	$99, %eax
	jg	L148
	movl	$LC24, %edx
L148:
	movl	___fdlib_version, %eax
	movl	%edx, 64(%esp)
	testl	%eax, %eax
	jne	L149
	movl	$0, 84(%esp)
	movl	$0, 88(%esp)
L150:
	leal	60(%esp), %eax
	movl	%eax, (%esp)
	call	_matherr
	testl	%eax, %eax
	jne	L303
	movl	___fdlib_version, %ecx
	testl	%ecx, %ecx
	jne	L242
	movl	$___dj_stderr, 12(%esp)
	movl	$25, 8(%esp)
	movl	$1, 4(%esp)
	movl	$LC65, (%esp)
	call	_fwrite
	jmp	L242
	.p2align 4,,7
L24:
	fstp	%st(0)
	fstp	%st(0)
	movl	$4, 60(%esp)
	movl	$LC25, %edx
	cmpl	$99, %eax
	jg	L145
	movl	$LC24, %edx
	jmp	L145
	.p2align 4,,7
L28:
	fstp	%st(0)
	fstp	%st(0)
	movl	$1, 60(%esp)
	movl	$LC31, %edx
	cmpl	$99, %eax
	jg	L167
	movl	$LC30, %edx
L167:
	movl	___fdlib_version, %eax
	movl	%edx, 64(%esp)
	testl	%eax, %eax
	jne	L168
	movl	$0, 84(%esp)
	movl	$0, 88(%esp)
L169:
	leal	60(%esp), %eax
	movl	%eax, (%esp)
	call	_matherr
	testl	%eax, %eax
	jne	L303
	movl	___fdlib_version, %eax
	testl	%eax, %eax
	jne	L242
	movl	$___dj_stderr, 12(%esp)
	movl	$19, 8(%esp)
	movl	$1, 4(%esp)
	movl	$LC67, (%esp)
	call	_fwrite
	jmp	L242
	.p2align 4,,7
L26:
	fstp	%st(0)
	fstp	%st(0)
	movl	$1, 60(%esp)
	movl	$LC25, %edx
	cmpl	$99, %eax
	jg	L153
	movl	$LC24, %edx
L153:
	movl	___fdlib_version, %eax
	movl	%edx, 64(%esp)
	testl	%eax, %eax
	jne	L154
	movl	$0, 84(%esp)
	movl	$0, 88(%esp)
L155:
	leal	60(%esp), %eax
	movl	%eax, (%esp)
	call	_matherr
	testl	%eax, %eax
	jne	L303
	movl	___fdlib_version, %edx
	testl	%edx, %edx
	jne	L242
	movl	$___dj_stderr, 12(%esp)
	movl	$32, 8(%esp)
	movl	$1, 4(%esp)
	movl	$LC66, (%esp)
	call	_fwrite
	jmp	L242
	.p2align 4,,7
L235:
	fldl	___dj_huge_val
	cmpl	$2, %eax
	fstpl	84(%esp)
	jne	L236
	.p2align 4,,7
L304:
	fldl	84(%esp)
	movl	$1, _errno
	addl	$108, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L231:
	.cfi_restore_state
	fldl	___dj_huge_val
	cmpl	$2, %eax
	fstpl	84(%esp)
	je	L305
	jmp	L232
	.p2align 4,,7
L100:
	fldl	___dj_huge_val
	fchs
	cmpl	$2, %eax
	fstpl	84(%esp)
	je	L304
	jmp	L101
	.p2align 4,,7
L80:
	fldl	___dj_huge_val
	fchs
	cmpl	$2, %eax
	fstpl	84(%esp)
	je	L304
	jmp	L81
	.p2align 4,,7
L90:
	fldl	___dj_huge_val
	fchs
	cmpl	$2, %eax
	fstpl	84(%esp)
	je	L304
	jmp	L91
	.p2align 4,,7
L124:
	fldl	___dj_huge_val
	fchs
	cmpl	$2, %eax
	fstpl	84(%esp)
	je	L305
	jmp	L125
	.p2align 4,,7
L119:
	fldl	___dj_huge_val
	fchs
	cmpl	$2, %eax
	fstpl	84(%esp)
	je	L304
	jmp	L120
	.p2align 4,,7
L109:
	fldl	___dj_huge_val
	cmpl	$2, %eax
	fstpl	84(%esp)
	je	L304
	jmp	L110
	.p2align 4,,7
L114:
	fldl	___dj_huge_val
	fchs
	cmpl	$2, %eax
	fstpl	84(%esp)
	je	L305
	jmp	L115
	.p2align 4,,7
L129:
	fldl	___dj_huge_val
	fchs
	cmpl	$2, %eax
	fstpl	84(%esp)
	je	L304
	jmp	L130
	.p2align 4,,7
L159:
	fldl	___dj_huge_val
	testb	$69, %ah
	jne	L354
L165:
	fstpl	84(%esp)
	cmpl	$2, %edx
	je	L305
	jmp	L232
	.p2align 4,,7
L149:
	fldl	___dj_huge_val
	fchs
	cmpl	$2, %eax
	fstpl	84(%esp)
	je	L304
	jmp	L150
	.p2align 4,,7
L154:
	fldz
	fdiv	%st(0), %st
	cmpl	$2, %eax
	fstpl	84(%esp)
	je	L304
	jmp	L155
	.p2align 4,,7
L168:
	fldz
	fdiv	%st(0), %st
	cmpl	$2, %eax
	fstpl	84(%esp)
	je	L304
	jmp	L169
	.p2align 4,,7
L137:
	fxch	%st(1)
	fstpl	32(%esp)
	fstpl	16(%esp)
	call	_infinity
	fstpl	84(%esp)
	fldz
	fldl	32(%esp)
	fxch	%st(1)
	fucompp
	fnstsw	%ax
	testb	$69, %ah
	fldl	16(%esp)
	jne	L358
	fmuls	LC64
	fstl	(%esp)
	fstpl	16(%esp)
	call	_rint
	fldl	16(%esp)
	fxch	%st(1)
	fucompp
	fnstsw	%ax
	andb	$69, %ah
	xorb	$64, %ah
	je	L302
	call	_infinity
	fchs
	fstpl	84(%esp)
	jmp	L302
	.p2align 4,,7
L358:
	fstp	%st(0)
L302:
	movl	___fdlib_version, %eax
	jmp	L141
L352:
	incl	%eax
	je	L292
	leal	60(%esp), %eax
	movl	%eax, (%esp)
	call	_matherr
	testl	%eax, %eax
	je	L242
	jmp	L303
L173:
	fstp	%st(0)
	call	_nan
	cmpl	$2, ___fdlib_version
	fstpl	84(%esp)
	je	L242
	jmp	L174
	.p2align 4,,7
L353:
	call	_infinity
	fchs
	jmp	L192
L351:
	movl	$___dj_stderr, 12(%esp)
	movl	$17, 8(%esp)
	movl	$1, 4(%esp)
	movl	$LC56, (%esp)
	call	_fwrite
	jmp	L242
L299:
	flds	LC29
	jmp	L160
L354:
	fchs
	jmp	L165
	.cfi_endproc
LFE0:
	.p2align 2
LC28:
	.long	2139095039
	.p2align 2
LC29:
	.long	-8388609
	.p2align 2
LC64:
	.long	1056964608
	.ident	"GCC: (GNU) 4.7.4"
