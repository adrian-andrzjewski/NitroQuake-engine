	.file	"conio.c"
/APP
	.section .ctor; .long _gppconio_init; .section .text
/NO_APP
	.section .text
	.p2align 4,,15
__scan_ungetch:
LFB49:
	.cfi_startproc
	movl	_char_avail, %edx
	movl	4(%esp), %eax
	testl	%edx, %edx
	jne	L3
	movl	%eax, _ungot_char
	movl	$1, _char_avail
	ret
	.p2align 4,,7
L3:
	orl	$-1, %eax
	ret
	.cfi_endproc
LFE49:
	.p2align 4,,15
_isEGA:
LFB63:
	.cfi_startproc
	movl	_adapter_type, %eax
	cmpl	$-1, %eax
	je	L16
	ret
	.p2align 4,,7
L16:
	pushl	%ebx
	.cfi_def_cfa_offset 8
	.cfi_offset 3, -8
	subl	$88, %esp
	.cfi_def_cfa_offset 96
	leal	28(%esp), %ebx
	movl	$16, (%esp)
	movl	%ebx, 4(%esp)
	movw	$6656, 56(%esp)
	call	___dpmi_int
	cmpb	$26, 56(%esp)
	jne	L7
	movb	44(%esp), %al
	subl	$4, %eax
	cmpb	$8, %al
	jbe	L17
L8:
	movl	$0, _adapter_type
	xorl	%eax, %eax
	jmp	L6
	.p2align 4,,7
L7:
	movl	%ebx, 4(%esp)
	movl	$16, (%esp)
	movb	$18, 57(%esp)
	movb	$16, 44(%esp)
	movb	$-1, 45(%esp)
	call	___dpmi_int
	cmpb	$-1, 45(%esp)
	setne	%al
	andl	$255, %eax
	movl	%eax, _adapter_type
L6:
	addl	$88, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 8
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L17:
	.cfi_restore_state
	andl	$255, %eax
	jmp	*L11(,%eax,4)
	.p2align 2
	.p2align 2
L11:
	.long	L9
	.long	L9
	.long	L10
	.long	L10
	.long	L10
	.long	L8
	.long	L10
	.long	L10
	.long	L10
	.p2align 4,,7
L10:
	movl	$2, _adapter_type
	movl	$2, %eax
	jmp	L6
	.p2align 4,,7
L9:
	movl	$1, _adapter_type
	movl	$1, %eax
	jmp	L6
	.cfi_endproc
LFE63:
	.p2align 4,,15
_set_scan_lines_and_font:
LFB64:
	.cfi_startproc
	pushl	%esi
	.cfi_def_cfa_offset 8
	.cfi_offset 6, -8
	pushl	%ebx
	.cfi_def_cfa_offset 12
	.cfi_offset 3, -12
	subl	$84, %esp
	.cfi_def_cfa_offset 96
	movl	%edx, %esi
	leal	28(%esp), %ebx
	movl	$16, (%esp)
	movl	%ebx, 4(%esp)
	movb	$18, 57(%esp)
	movb	%al, 56(%esp)
	movb	$48, 44(%esp)
	call	___dpmi_int
	movl	$3, %eax
	cmpb	$7, _txinfo+6
	je	L22
L19:
	movl	%ebx, 4(%esp)
	movl	$16, (%esp)
	movw	%ax, 56(%esp)
	call	___dpmi_int
	movl	%esi, %eax
	movl	%ebx, 4(%esp)
	movl	$16, (%esp)
	movb	$0, 44(%esp)
	movb	$17, 57(%esp)
	movb	%al, 56(%esp)
	call	___dpmi_int
	addl	$84, %esp
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
L22:
	.cfi_restore_state
	movb	$7, %al
	jmp	L19
	.cfi_endproc
LFE64:
	.p2align 4,,15
_refreshvirtualscreen:
LFB23:
	.cfi_startproc
	pushl	%ebx
	.cfi_def_cfa_offset 8
	.cfi_offset 3, -8
	subl	$88, %esp
	.cfi_def_cfa_offset 96
	movw	_ScreenVirtualSegment, %bx
	movw	%bx, 62(%esp)
	xorl	%ebx, %ebx
	movb	_txinfo+8, %bl
	movl	$16, (%esp)
	imull	%edx, %ebx
	movw	_ScreenVirtualOffset, %dx
	addl	%ebx, %eax
	movb	$-1, 57(%esp)
	movw	%cx, 52(%esp)
	leal	(%edx,%eax,2), %eax
	movw	%ax, 28(%esp)
	leal	28(%esp), %eax
	movl	%eax, 4(%esp)
	call	___dpmi_int
	addl	$88, %esp
	.cfi_def_cfa_offset 8
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 4
	ret
	.cfi_endproc
LFE23:
	.p2align 4,,15
_mayrefreshline:
LFB24:
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
	subl	$12, %esp
	.cfi_def_cfa_offset 32
	movl	%edx, %ebp
	movl	%eax, %ebx
	movl	%ecx, %edi
	movl	36(%esp), %esi
	movl	32(%esp), %edx
	movl	(%esi), %ecx
	movl	(%edx), %eax
	cmpl	%eax, %ecx
	je	L26
	subl	%eax, %ecx
	movl	(%edi), %edx
	call	_refreshvirtualscreen
L26:
	movl	32(%esp), %eax
	movl	%ebp, (%edi)
	movl	%ebx, (%esi)
	movl	%ebx, (%eax)
	addl	$12, %esp
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
LFE24:
	.p2align 4,,15
_getvideomode:
LFB60:
	.cfi_startproc
	pushl	%ebx
	.cfi_def_cfa_offset 8
	.cfi_offset 3, -8
	subl	$8, %esp
	.cfi_def_cfa_offset 16
	call	_ScreenMode
	movl	%eax, %ebx
	cmpl	$3, %eax
	je	L32
L29:
	addl	$8, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 8
	movl	%ebx, %eax
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L32:
	.cfi_restore_state
	call	_ScreenRows
	cmpl	$25, %eax
	jle	L29
	addl	$8, %esp
	.cfi_def_cfa_offset 8
	movb	$64, %bl
	movl	%ebx, %eax
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 4
	ret
	.cfi_endproc
LFE60:
	.p2align 4,,15
_set_scan_lines_and_8x10_font:
LFB67:
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
	leal	36(%esp), %ebx
	movl	$16, (%esp)
	movl	%ebx, 4(%esp)
	movb	$48, 52(%esp)
	movb	$18, 65(%esp)
	movb	%al, 64(%esp)
	call	___dpmi_int
	movl	$3, %eax
	cmpb	$7, _txinfo+6
	je	L52
L34:
	movl	%ebx, 4(%esp)
	movl	$16, (%esp)
	movw	%ax, 64(%esp)
	call	___dpmi_int
	movl	_font_seg, %eax
	movl	%eax, 28(%esp)
	incl	%eax
	je	L53
L35:
	movl	28(%esp), %eax
	movl	$16, (%esp)
	movw	%ax, 122(%esp)
	leal	88(%esp), %eax
	movl	%eax, 4(%esp)
	movw	$0, 96(%esp)
	movw	$0, 108(%esp)
	movw	$256, 112(%esp)
	movb	$10, 105(%esp)
	movb	$0, 104(%esp)
	movw	$4368, 116(%esp)
	call	___dpmi_int
L33:
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
L52:
	.cfi_restore_state
	movb	$7, %al
	jmp	L34
L53:
	leal	32(%esp), %eax
	movl	$160, (%esp)
	movl	%eax, 4(%esp)
	call	___dpmi_allocate_dos_memory
	movl	%eax, _font_seg
	incl	%eax
	je	L33
	leal	140(%esp), %eax
	movl	$16, (%esp)
	movl	%eax, 4(%esp)
	movb	$3, 157(%esp)
	movw	$4400, 168(%esp)
	call	___dpmi_int
	movw	174(%esp), %ax
	movl	148(%esp), %edi
	andl	$65535, %eax
	andl	$65535, %edi
	sall	$4, %eax
	addl	%eax, %edi
	movl	_font_seg, %eax
	movl	%eax, %ebp
	movl	%eax, 28(%esp)
	sall	$4, %ebp
/APP
# 169 "c:/djgpp/include/libc/farptrgs.h" 1
	movw __go32_info_block+26,%gs
# 0 "" 2
/NO_APP
	leal	9(%ebp), %esi
	addl	$2569, %ebp
	.p2align 4,,7
L38:
	leal	-8(%esi), %eax
	leal	-9(%esi), %edx
/APP
# 188 "c:/djgpp/include/libc/farptrgs.h" 1
	.byte 0x65
	movb $0,(%edx)
# 0 "" 2
/NO_APP
	movl	%edi, %edx
	.p2align 4,,7
L37:
	leal	1(%edx), %ebx
/APP
# 218 "c:/djgpp/include/libc/farptrgs.h" 1
	.byte 0x65
	movb (%edx),%dl
# 0 "" 2
/NO_APP
	leal	1(%eax), %ecx
/APP
# 188 "c:/djgpp/include/libc/farptrgs.h" 1
	.byte 0x65
	movb %dl,(%eax)
# 0 "" 2
/NO_APP
	movl	%ebx, %edx
	movl	%ecx, %eax
	cmpl	%esi, %ecx
	jne	L37
	addl	$8, %edi
/APP
# 188 "c:/djgpp/include/libc/farptrgs.h" 1
	.byte 0x65
	movb $0,(%esi)
# 0 "" 2
/NO_APP
	leal	10(%ecx), %esi
	cmpl	%ebp, %esi
	jne	L38
	cmpl	$-1, 28(%esp)
	jne	L35
	addl	$204, %esp
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
LFE67:
	.p2align 4,,15
_fillrow:
LFB41:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%edi
	pushl	%esi
	.cfi_offset 7, -12
	.cfi_offset 6, -16
	movl	%ecx, %esi
	subl	%edx, %esi
	pushl	%ebx
	subl	$44, %esp
	.cfi_offset 3, -20
	movl	%eax, -32(%ebp)
	movl	%edx, %eax
	leal	1(%esi), %edx
	movl	%edx, -28(%ebp)
	leal	16(%edx,%edx), %edx
	andl	$-16, %edx
	subl	%edx, %esp
	cmpl	%eax, %ecx
	leal	12(%esp), %edx
	jl	L59
	movl	8(%ebp), %edi
	movl	%edx, %ebx
	leal	2(%edx,%esi,2), %esi
	.p2align 4,,7
L58:
	movw	%di, (%ebx)
	addl	$2, %ebx
	cmpl	%esi, %ebx
	jne	L58
L59:
	xorl	%ecx, %ecx
	movl	-32(%ebp), %ebx
	movb	_txinfo+8, %cl
	movl	%edx, (%esp)
	imull	%ebx, %ecx
	movl	_ScreenAddress, %ebx
	addl	%eax, %ecx
	movl	%eax, -36(%ebp)
	leal	(%ebx,%ecx,2), %ecx
	movl	%ecx, 8(%esp)
	movl	-28(%ebp), %ecx
	addl	%ecx, %ecx
	movl	%ecx, 4(%esp)
	call	___dosmemput
	movl	-36(%ebp), %eax
	cmpw	$0, _ScreenVirtualSegment
	je	L54
	movl	-28(%ebp), %ecx
	movl	-32(%ebp), %edx
	call	_refreshvirtualscreen
L54:
	leal	-12(%ebp), %esp
	popl	%ebx
	.cfi_restore 3
	popl	%esi
	.cfi_restore 6
	popl	%edi
	.cfi_restore 7
	popl	%ebp
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
LFE41:
	.p2align 4,,15
__gettextinfo.constprop.0:
LFB72:
	.cfi_startproc
	subl	$92, %esp
	.cfi_def_cfa_offset 96
	movb	$1, _txinfo+1
	movb	$1, _txinfo
	call	_ScreenCols
	movb	%al, _txinfo+8
	movb	%al, _txinfo+2
	call	_ScreenRows
	movl	$16, (%esp)
	movb	%al, _txinfo+7
	movb	%al, _txinfo+3
	leal	28(%esp), %eax
	movb	$8, 57(%esp)
	movl	%eax, 4(%esp)
	movb	$0, 45(%esp)
	call	___dpmi_int
	movb	57(%esp), %al
	andl	$127, %eax
	movb	%al, _txinfo+4
	movb	%al, _ScreenAttrib
	movl	_oldattrib, %eax
	movb	%al, _txinfo+5
	call	_getvideomode
	movb	%al, _txinfo+6
	leal	24(%esp), %eax
	movl	%eax, 4(%esp)
	leal	20(%esp), %eax
	movl	%eax, (%esp)
	call	_ScreenGetCursor
	movb	24(%esp), %al
	incl	%eax
	movb	%al, _txinfo+9
	movb	20(%esp), %al
	incl	%eax
	movb	%al, _txinfo+10
	addl	$92, %esp
	.cfi_def_cfa_offset 4
	ret
	.cfi_endproc
LFE72:
	.p2align 4,,15
	.globl	_puttext
_puttext:
LFB25:
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
	movl	68(%esp), %ebx
	movl	64(%esp), %ebp
	decl	%ebx
	movl	72(%esp), %eax
	decl	%ebp
	decl	%eax
	cmpl	76(%esp), %ebx
	jge	L70
	subl	%ebp, %eax
	movl	80(%esp), %esi
	incl	%eax
	movl	%eax, %edi
	movl	%eax, 28(%esp)
	addl	%edi, %edi
	jmp	L67
	.p2align 4,,7
L66:
	incl	%ebx
	cmpl	%ebx, 76(%esp)
	jle	L70
L67:
	xorl	%eax, %eax
	movl	_ScreenAddress, %edx
	movb	_txinfo+8, %al
	movl	%esi, (%esp)
	imull	%ebx, %eax
	addl	%ebp, %eax
	movl	%edi, 4(%esp)
	addl	%edi, %esi
	leal	(%edx,%eax,2), %eax
	movl	%eax, 8(%esp)
	call	___dosmemput
	cmpw	$0, _ScreenVirtualSegment
	je	L66
	movl	%ebx, %edx
	movl	28(%esp), %ecx
	movl	%ebp, %eax
	incl	%ebx
	call	_refreshvirtualscreen
	cmpl	%ebx, 76(%esp)
	jg	L67
L70:
	addl	$44, %esp
	.cfi_def_cfa_offset 20
	movl	$1, %eax
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
LFE25:
	.p2align 4,,15
	.globl	__conio_gettext
__conio_gettext:
LFB26:
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
	subl	$28, %esp
	.cfi_def_cfa_offset 48
	movl	52(%esp), %ebx
	movl	48(%esp), %ebp
	decl	%ebx
	movl	56(%esp), %eax
	decl	%ebp
	decl	%eax
	cmpl	60(%esp), %ebx
	jge	L77
	subl	%ebp, %eax
	movl	64(%esp), %edi
	leal	2(%eax,%eax), %esi
	.p2align 4,,7
L74:
	xorl	%eax, %eax
	movl	_ScreenAddress, %ecx
	movb	_txinfo+8, %al
	movl	%edi, 8(%esp)
	imull	%ebx, %eax
	addl	%ebp, %eax
	movl	%esi, 4(%esp)
	incl	%ebx
	addl	%esi, %edi
	leal	(%ecx,%eax,2), %eax
	movl	%eax, (%esp)
	call	___dosmemget
	cmpl	%ebx, 60(%esp)
	jg	L74
L77:
	addl	$28, %esp
	.cfi_def_cfa_offset 20
	movl	$1, %eax
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
LFE26:
	.p2align 4,,15
	.globl	_gotoxy
_gotoxy:
LFB27:
	.cfi_startproc
	pushl	%ebx
	.cfi_def_cfa_offset 8
	.cfi_offset 3, -8
	xorl	%eax, %eax
	subl	$24, %esp
	.cfi_def_cfa_offset 32
	movb	_txinfo, %al
	movl	32(%esp), %edx
	movl	36(%esp), %ebx
	leal	-2(%edx,%eax), %eax
	movl	%eax, 4(%esp)
	xorl	%eax, %eax
	movb	_txinfo+1, %al
	leal	-2(%ebx,%eax), %eax
	movl	%eax, (%esp)
	call	_ScreenSetCursor
	movb	32(%esp), %al
	movb	%bl, _txinfo+10
	movb	%al, _txinfo+9
	addl	$24, %esp
	.cfi_def_cfa_offset 8
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 4
	ret
	.cfi_endproc
LFE27:
	.p2align 4,,15
	.globl	_wherex
_wherex:
LFB28:
	.cfi_startproc
	subl	$44, %esp
	.cfi_def_cfa_offset 48
	leal	28(%esp), %eax
	movl	%eax, 4(%esp)
	leal	24(%esp), %eax
	movl	%eax, (%esp)
	call	_ScreenGetCursor
	xorl	%edx, %edx
	movb	_txinfo, %dl
	movl	28(%esp), %eax
	subl	%edx, %eax
	addl	$44, %esp
	.cfi_def_cfa_offset 4
	addl	$2, %eax
	ret
	.cfi_endproc
LFE28:
	.p2align 4,,15
	.globl	_wherey
_wherey:
LFB29:
	.cfi_startproc
	subl	$44, %esp
	.cfi_def_cfa_offset 48
	leal	28(%esp), %eax
	movl	%eax, 4(%esp)
	leal	24(%esp), %eax
	movl	%eax, (%esp)
	call	_ScreenGetCursor
	xorl	%edx, %edx
	movb	_txinfo+1, %dl
	movl	24(%esp), %eax
	subl	%edx, %eax
	addl	$44, %esp
	.cfi_def_cfa_offset 4
	addl	$2, %eax
	ret
	.cfi_endproc
LFE29:
	.p2align 4,,15
	.globl	_textattr
_textattr:
LFB31:
	.cfi_startproc
	movl	4(%esp), %eax
	movb	%al, _ScreenAttrib
	movb	%al, _txinfo+4
	ret
	.cfi_endproc
LFE31:
	.p2align 4,,15
	.globl	_textcolor
_textcolor:
LFB32:
	.cfi_startproc
	movl	_intense_bg_mode, %eax
	movb	_ScreenAttrib, %dl
	testl	%eax, %eax
	je	L92
	andl	$240, %edx
	movb	$15, %al
L89:
	movl	4(%esp), %ecx
	andl	%ecx, %eax
	orl	%edx, %eax
	movb	%al, _txinfo+4
	movb	%al, _ScreenAttrib
	ret
	.p2align 4,,7
L92:
	andl	$112, %edx
	movb	$-113, %al
	jmp	L89
	.cfi_endproc
LFE32:
	.p2align 4,,15
	.globl	_textbackground
_textbackground:
LFB33:
	.cfi_startproc
	movl	_intense_bg_mode, %eax
	movb	_ScreenAttrib, %cl
	testl	%eax, %eax
	je	L99
	andl	$15, %ecx
	movl	$15, %edx
L96:
	movl	4(%esp), %eax
	andl	%edx, %eax
	sall	$4, %eax
	orl	%ecx, %eax
	movb	%al, _ScreenAttrib
	movb	%al, _txinfo+4
	ret
	.p2align 4,,7
L99:
	andl	$143, %ecx
	movl	$7, %edx
	jmp	L96
	.cfi_endproc
LFE33:
	.p2align 4,,15
	.globl	_highvideo
_highvideo:
LFB34:
	.cfi_startproc
	movb	_ScreenAttrib, %al
	orl	$8, %eax
	movb	%al, _ScreenAttrib
	movb	%al, _txinfo+4
	ret
	.cfi_endproc
LFE34:
	.p2align 4,,15
	.globl	_lowvideo
_lowvideo:
LFB35:
	.cfi_startproc
	movb	_ScreenAttrib, %al
	andl	$-9, %eax
	movb	%al, _ScreenAttrib
	movb	%al, _txinfo+4
	ret
	.cfi_endproc
LFE35:
	.p2align 4,,15
	.globl	_normvideo
_normvideo:
LFB36:
	.cfi_startproc
	movb	_txinfo+5, %al
	movb	%al, _ScreenAttrib
	movb	%al, _txinfo+4
	ret
	.cfi_endproc
LFE36:
	.p2align 4,,15
	.globl	__setcursortype
__setcursortype:
LFB37:
	.cfi_startproc
	subl	$92, %esp
	.cfi_def_cfa_offset 96
	movl	$1543, %eax
	cmpl	$1, 96(%esp)
	ja	L104
	movl	96(%esp), %edx
	movl	_CSWTCH.152(,%edx,4), %eax
L104:
	movw	%ax, 52(%esp)
	leal	28(%esp), %eax
	movl	%eax, 4(%esp)
	movl	$16, (%esp)
	movb	$1, 57(%esp)
	call	___dpmi_int
	addl	$92, %esp
	.cfi_def_cfa_offset 4
	ret
	.cfi_endproc
LFE37:
	.p2align 4,,15
	.globl	_clreol
_clreol:
LFB40:
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
	xorl	%ebx, %ebx
	subl	$560, %esp
	.cfi_def_cfa_offset 576
	movb	_ScreenAttrib, %bl
	sall	$8, %ebx
	leal	44(%esp), %eax
	movl	%eax, 4(%esp)
	leal	40(%esp), %eax
	movl	%eax, (%esp)
	orl	$32, %ebx
	call	_ScreenGetCursor
	movb	_txinfo+2, %al
	andl	$255, %eax
	movl	44(%esp), %edi
	movl	%eax, %edx
	movl	%eax, %esi
	subl	%edi, %edx
	leal	48(%esp), %ecx
	testl	%edx, %edx
	jle	L110
	movl	%ecx, %eax
	leal	(%ecx,%edx,2), %edx
	.p2align 4,,7
L109:
	movw	%bx, (%eax)
	addl	$2, %eax
	cmpl	%edx, %eax
	jne	L109
L110:
	movl	40(%esp), %eax
	incl	%edi
	incl	%eax
	movl	%esi, 8(%esp)
	movl	%edi, (%esp)
	movl	%ecx, 16(%esp)
	movl	%eax, 12(%esp)
	movl	%eax, 4(%esp)
	call	_puttext
	addl	$560, %esp
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
	.cfi_endproc
LFE40:
	.p2align 4,,15
	.globl	_clrscr
_clrscr:
LFB42:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	xorl	%eax, %eax
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%edi
	pushl	%esi
	pushl	%ebx
	subl	$28, %esp
	.cfi_offset 7, -12
	.cfi_offset 6, -16
	.cfi_offset 3, -20
	movzbl	_txinfo+2, %edi
	movb	_txinfo, %cl
	movl	%edi, %edx
	andl	$255, %edx
	movb	%cl, %al
	subl	%eax, %edx
	leal	18(%edx,%edx), %eax
	andl	$-16, %eax
	subl	%eax, %esp
	testl	%edx, %edx
	leal	12(%esp), %esi
	js	L119
	xorl	%ebx, %ebx
	movl	%esi, %eax
	movb	_ScreenAttrib, %bl
	leal	2(%esi,%edx,2), %edx
	sall	$8, %ebx
	orl	$32, %ebx
	.p2align 4,,7
L118:
	movw	%bx, (%eax)
	addl	$2, %eax
	cmpl	%edx, %eax
	jne	L118
L119:
	xorl	%ebx, %ebx
	xorl	%eax, %eax
	movb	_txinfo+1, %bl
	movb	_txinfo+3, %al
	decl	%ebx
	cmpl	%eax, %ebx
	jl	L122
	jmp	L116
	.p2align 4,,7
L120:
	xorl	%eax, %eax
	incl	%ebx
	movb	_txinfo+3, %al
	cmpl	%ebx, %eax
	jle	L116
L125:
	movzbl	_txinfo+2, %edi
	movb	_txinfo, %cl
L122:
	xorl	%edx, %edx
	andl	$255, %ecx
	movb	_txinfo+8, %dl
	movl	_ScreenAddress, %eax
	imull	%ebx, %edx
	movl	%esi, (%esp)
	leal	-1(%ecx,%edx), %edx
	leal	(%eax,%edx,2), %eax
	movl	%eax, 8(%esp)
	movl	%edi, %eax
	andl	$255, %eax
	subl	%ecx, %eax
	leal	2(%eax,%eax), %eax
	movl	%eax, 4(%esp)
	call	___dosmemput
	cmpw	$0, _ScreenVirtualSegment
	je	L120
	xorl	%eax, %eax
	xorl	%ecx, %ecx
	movb	_txinfo, %al
	movb	_txinfo+2, %cl
	subl	%eax, %ecx
	movl	%ebx, %edx
	decl	%eax
	incl	%ecx
	call	_refreshvirtualscreen
	xorl	%eax, %eax
	incl	%ebx
	movb	_txinfo+3, %al
	cmpl	%ebx, %eax
	jg	L125
L116:
	movl	$1, 4(%esp)
	movl	$1, (%esp)
	call	_gotoxy
	leal	-12(%ebp), %esp
	popl	%ebx
	.cfi_restore 3
	popl	%esi
	.cfi_restore 6
	popl	%edi
	.cfi_restore 7
	popl	%ebp
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
LFE42:
	.p2align 4,,15
	.globl	_getch
_getch:
LFB45:
	.cfi_startproc
	subl	$92, %esp
	.cfi_def_cfa_offset 96
	movl	$0, (%esp)
	call	___isatty
	testl	%eax, %eax
	je	L128
	testb	$4, ___dj_stdout+16
	jne	L145
L130:
	testb	$4, ___dj_stderr+16
	jne	L146
L128:
	movl	_char_avail, %eax
	testl	%eax, %eax
	je	L133
	movl	_ungot_char, %eax
	movl	$0, _char_avail
	addl	$92, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L133:
	.cfi_restore_state
	leal	28(%esp), %eax
	movl	$33, (%esp)
	movl	%eax, 4(%esp)
	movw	$1792, 56(%esp)
	call	___dpmi_int
	xorl	%eax, %eax
	movb	56(%esp), %al
	addl	$92, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L146:
	.cfi_restore_state
	movl	$___dj_stderr, (%esp)
	call	_fileno
	movl	%eax, (%esp)
	call	___isatty
	testl	%eax, %eax
	je	L128
	movl	$___dj_stderr, (%esp)
	call	_fflush
	jmp	L128
	.p2align 4,,7
L145:
	movl	$___dj_stdout, (%esp)
	call	_fileno
	movl	%eax, (%esp)
	call	___isatty
	testl	%eax, %eax
	je	L130
	movl	$___dj_stdout, (%esp)
	call	_fflush
	jmp	L130
	.cfi_endproc
LFE45:
	.p2align 4,,15
	.globl	_ungetch
_ungetch:
LFB46:
	.cfi_startproc
	movl	_char_avail, %edx
	movl	4(%esp), %eax
	testl	%edx, %edx
	jne	L149
	movl	%eax, _ungot_char
	movl	$1, _char_avail
	ret
	.p2align 4,,7
L149:
	orl	$-1, %eax
	ret
	.cfi_endproc
LFE46:
	.p2align 4,,15
	.globl	__conio_kbhit
__conio_kbhit:
LFB47:
	.cfi_startproc
	movl	_char_avail, %eax
	testl	%eax, %eax
	je	L152
	movl	$1, %eax
	ret
	.p2align 4,,7
L152:
	jmp	_kbhit
	.cfi_endproc
LFE47:
	.p2align 4,,15
	.globl	_insline
_insline:
LFB50:
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
	subl	$76, %esp
	.cfi_def_cfa_offset 96
	leal	60(%esp), %eax
	movl	%eax, 4(%esp)
	leal	56(%esp), %eax
	movl	%eax, (%esp)
	call	_ScreenGetCursor
	movb	_txinfo, %al
	andl	$255, %eax
	xorl	%ecx, %ecx
	movl	%eax, %esi
	xorl	%eax, %eax
	movb	_txinfo+2, %al
	decl	%esi
	movb	_txinfo+3, %cl
	leal	-1(%eax), %edx
	subl	%esi, %eax
	movl	%eax, %edi
	movl	%eax, 40(%esp)
	xorl	%eax, %eax
	decl	%ecx
	movb	_ScreenAttrib, %al
	addl	%edi, %edi
	sall	$8, %eax
	movl	%edx, 44(%esp)
	orl	$32, %eax
	movl	%eax, 36(%esp)
	movl	56(%esp), %eax
	cmpl	%eax, %ecx
	jg	L157
	jmp	L154
	.p2align 4,,7
L155:
	movl	56(%esp), %eax
	movl	%ebx, %ecx
	cmpl	%ebx, %eax
	jge	L154
L157:
	movb	_txinfo+8, %dl
	leal	-1(%ecx), %ebx
	andl	$255, %edx
	movw	__go32_info_block+26, %ax
	movl	%edx, %ebp
	movl	_ScreenAddress, %edx
	imull	%ebp, %ecx
	imull	%ebx, %ebp
	addl	%esi, %ecx
	addl	%esi, %ebp
	andl	$65535, %eax
	movl	%edi, 16(%esp)
	leal	(%edx,%ecx,2), %ecx
	leal	(%edx,%ebp,2), %edx
	movl	%ecx, 12(%esp)
	movl	%eax, 8(%esp)
	movl	%edx, 4(%esp)
	movl	%eax, (%esp)
	call	___movedata
	cmpw	$0, _ScreenVirtualSegment
	je	L155
	movl	40(%esp), %ecx
	movl	%esi, %eax
	movl	%ebx, %edx
	call	_refreshvirtualscreen
	movl	56(%esp), %eax
	movl	%ebx, %ecx
	cmpl	%ebx, %eax
	jl	L157
L154:
	movl	36(%esp), %edx
	movl	44(%esp), %ecx
	movl	%edx, (%esp)
	movl	%esi, %edx
	call	_fillrow
	addl	$76, %esp
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
LFE50:
	.p2align 4,,15
	.globl	_delline
_delline:
LFB51:
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
	subl	$76, %esp
	.cfi_def_cfa_offset 96
	leal	60(%esp), %eax
	movl	%eax, 4(%esp)
	leal	56(%esp), %eax
	movl	%eax, (%esp)
	call	_ScreenGetCursor
	movb	_txinfo, %al
	andl	$255, %eax
	movl	56(%esp), %ecx
	movl	%eax, %esi
	xorl	%eax, %eax
	movb	_txinfo+2, %al
	decl	%esi
	leal	-1(%eax), %edx
	subl	%esi, %eax
	movl	%eax, %edi
	movl	%eax, 40(%esp)
	xorl	%eax, %eax
	addl	%edi, %edi
	movb	_txinfo+3, %al
	movl	%edx, 44(%esp)
	decl	%eax
	movl	%eax, 32(%esp)
	xorl	%eax, %eax
	movb	_ScreenAttrib, %al
	sall	$8, %eax
	orl	$32, %eax
	cmpl	%ecx, 32(%esp)
	movl	%eax, 36(%esp)
	jg	L165
	jmp	L164
	.p2align 4,,7
L162:
	movl	56(%esp), %ecx
	incl	%ecx
	movl	%ecx, 56(%esp)
	cmpl	%ecx, 32(%esp)
	jle	L164
L165:
	xorl	%ebx, %ebx
	movl	%ecx, %ebp
	movb	_txinfo+8, %bl
	incl	%ecx
	imull	%ebx, %ebp
	imull	%ebx, %ecx
	movl	_ScreenAddress, %eax
	addl	%esi, %ecx
	addl	%esi, %ebp
	movw	__go32_info_block+26, %dx
	andl	$65535, %edx
	movl	%edi, 16(%esp)
	leal	(%eax,%ebp,2), %ebp
	leal	(%eax,%ecx,2), %eax
	movl	%ebp, 12(%esp)
	movl	%edx, 8(%esp)
	movl	%eax, 4(%esp)
	movl	%edx, (%esp)
	call	___movedata
	cmpw	$0, _ScreenVirtualSegment
	je	L162
	movl	40(%esp), %ecx
	movl	56(%esp), %edx
	movl	%esi, %eax
	call	_refreshvirtualscreen
	movl	56(%esp), %ecx
	incl	%ecx
	movl	%ecx, 56(%esp)
	cmpl	%ecx, 32(%esp)
	jg	L165
L164:
	movl	36(%esp), %edx
	movl	44(%esp), %ecx
	movl	%edx, (%esp)
	movl	32(%esp), %eax
	movl	%esi, %edx
	call	_fillrow
	addl	$76, %esp
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
LFE51:
	.p2align 4,,15
	.globl	_putch
_putch:
LFB43:
	.cfi_startproc
	pushl	%ebx
	.cfi_def_cfa_offset 8
	.cfi_offset 3, -8
	subl	$88, %esp
	.cfi_def_cfa_offset 96
	leal	24(%esp), %eax
	movl	96(%esp), %ebx
	movl	%eax, 4(%esp)
	leal	20(%esp), %eax
	movl	%eax, (%esp)
	call	_ScreenGetCursor
	cmpl	$10, %ebx
	je	L184
	cmpl	$13, %ebx
	je	L185
	cmpl	$8, %ebx
	je	L186
	cmpl	$7, %ebx
	je	L187
	movl	20(%esp), %eax
	movl	%ebx, (%esp)
	movl	%eax, 12(%esp)
	movl	24(%esp), %eax
	movl	%eax, 8(%esp)
	xorl	%eax, %eax
	movb	_ScreenAttrib, %al
	movl	%eax, 4(%esp)
	call	_ScreenPutChar
	cmpw	$0, _ScreenVirtualSegment
	jne	L188
L178:
	movl	24(%esp), %eax
	xorl	%ecx, %ecx
	incl	%eax
	movb	_txinfo+2, %cl
	movl	%eax, 24(%esp)
	movl	20(%esp), %edx
L172:
	cmpl	%eax, %ecx
	jg	L179
	xorl	%eax, %eax
	incl	%edx
	movb	_txinfo, %al
	movl	%edx, 20(%esp)
	decl	%eax
	movl	%eax, 24(%esp)
L179:
	xorl	%eax, %eax
	movb	_txinfo+3, %al
	cmpl	%edx, %eax
	jg	L180
	movl	__wscroll, %eax
	testl	%eax, %eax
	jne	L189
L181:
	decl	%edx
	movl	%edx, 20(%esp)
L180:
	movl	24(%esp), %eax
	movl	%edx, (%esp)
	movl	%eax, 4(%esp)
	call	_ScreenSetCursor
	movl	20(%esp), %eax
	subb	_txinfo+1, %al
	addl	$2, %eax
	movb	%al, _txinfo+10
	movl	24(%esp), %eax
	subb	_txinfo, %al
	addl	$2, %eax
	movb	%al, _txinfo+9
	addl	$88, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 8
	movl	%ebx, %eax
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L184:
	.cfi_restore_state
	movl	20(%esp), %edx
	xorl	%ecx, %ecx
	incl	%edx
	movb	_txinfo+2, %cl
	movl	%edx, 20(%esp)
	movl	24(%esp), %eax
	jmp	L172
	.p2align 4,,7
L185:
	xorl	%eax, %eax
	movb	_txinfo, %al
L183:
	decl	%eax
	xorl	%ecx, %ecx
	movl	%eax, 24(%esp)
	movb	_txinfo+2, %cl
	movl	20(%esp), %edx
	jmp	L172
	.p2align 4,,7
L186:
	xorl	%edx, %edx
	movl	24(%esp), %eax
	movb	_txinfo, %dl
	cmpl	%eax, %edx
	jle	L183
	xorl	%ecx, %ecx
	movl	20(%esp), %edx
	movb	_txinfo+1, %cl
	cmpl	%edx, %ecx
	jg	L190
	xorl	%ecx, %ecx
	decl	%edx
	movb	_txinfo+2, %cl
	movl	%edx, 20(%esp)
	leal	-1(%ecx), %eax
	movl	%eax, 24(%esp)
	jmp	L172
	.p2align 4,,7
L188:
	movl	$1, %ecx
	movl	20(%esp), %edx
	movl	24(%esp), %eax
	call	_refreshvirtualscreen
	jmp	L178
	.p2align 4,,7
L189:
	xorl	%eax, %eax
	movl	$0, 4(%esp)
	movb	_txinfo+1, %al
	decl	%eax
	movl	%eax, (%esp)
	call	_ScreenSetCursor
	call	_delline
	movl	20(%esp), %edx
	jmp	L181
	.p2align 4,,7
L187:
	leal	28(%esp), %eax
	movl	$16, (%esp)
	movl	%eax, 4(%esp)
	movb	$14, 57(%esp)
	movb	$7, 56(%esp)
	call	___dpmi_int
	xorl	%ecx, %ecx
	movl	24(%esp), %eax
	movb	_txinfo+2, %cl
	movl	20(%esp), %edx
	jmp	L172
	.p2align 4,,7
L190:
	xorl	%ecx, %ecx
	movb	_txinfo+2, %cl
	jmp	L172
	.cfi_endproc
LFE43:
	.p2align 4,,15
	.globl	_getche
_getche:
LFB44:
	.cfi_startproc
	movl	_char_avail, %eax
	testl	%eax, %eax
	jne	L194
	subl	$28, %esp
	.cfi_def_cfa_offset 32
	call	_getch
	movl	%eax, (%esp)
	call	_putch
	addl	$28, %esp
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L194:
	jmp	_getch
	.cfi_endproc
LFE44:
	.p2align 4,,15
__scan_getche:
LFB48:
	.cfi_startproc
	jmp	_getche
	.cfi_endproc
LFE48:
	.p2align 4,,15
	.globl	_window
_window:
LFB52:
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
	movl	20(%esp), %eax
	movl	16(%esp), %ecx
	movl	24(%esp), %edx
	movl	28(%esp), %edi
	testl	%eax, %eax
	jle	L196
	testl	%ecx, %ecx
	jle	L196
	movb	_txinfo+8, %bl
	andl	$255, %ebx
	cmpl	%edx, %ebx
	jl	L196
	movb	_txinfo+7, %bl
	andl	$255, %ebx
	cmpl	%edi, %ebx
	jge	L199
L196:
	popl	%ebx
	.cfi_remember_state
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
L199:
	.cfi_restore_state
	movb	%al, _txinfo+1
	movl	%edi, %eax
	movl	$1, 20(%esp)
	movl	$1, 16(%esp)
	movb	%cl, _txinfo
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 12
	movb	%dl, _txinfo+2
	popl	%esi
	.cfi_restore 6
	.cfi_def_cfa_offset 8
	movb	%al, _txinfo+3
	popl	%edi
	.cfi_restore 7
	.cfi_def_cfa_offset 4
	jmp	_gotoxy
	.cfi_endproc
LFE52:
	.p2align 4,,15
	.globl	_cputs
_cputs:
LFB53:
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
	subl	$108, %esp
	.cfi_def_cfa_offset 128
	movb	_ScreenAttrib, %al
	andl	$255, %eax
	movl	%eax, %ebp
	leal	28(%esp), %eax
	sall	$8, %ebp
	movl	%eax, 4(%esp)
	leal	24(%esp), %eax
	movl	%eax, (%esp)
	call	_ScreenGetCursor
	xorl	%edx, %edx
	movl	24(%esp), %ecx
	movb	_txinfo+8, %dl
	imull	%ecx, %edx
	movl	28(%esp), %eax
	movl	_ScreenAddress, %ebx
	addl	%eax, %edx
	movl	%eax, 40(%esp)
	movl	%eax, 36(%esp)
	xorl	%eax, %eax
	leal	(%ebx,%edx,2), %esi
	movl	128(%esp), %ebx
	movl	%ecx, 32(%esp)
	movb	(%ebx), %dl
	leal	1(%ebx), %edi
	movb	%dl, %al
	testl	%eax, %eax
	je	L218
	.p2align 4,,7
L214:
	cmpl	$10, %eax
	je	L219
	cmpl	$13, %eax
	je	L220
	cmpl	$8, %eax
	je	L221
	cmpl	$7, %eax
	je	L222
	leal	22(%esp), %eax
	andl	$255, %edx
	orl	%ebp, %edx
	movl	%esi, 8(%esp)
	movl	%eax, (%esp)
	movl	$2, 4(%esp)
	movw	%dx, 22(%esp)
	call	___dosmemput
	movl	28(%esp), %eax
	movl	40(%esp), %ebx
	incl	%eax
	incl	%ebx
	addl	$2, %esi
	movl	%eax, 28(%esp)
	movl	%ebx, 40(%esp)
	movl	24(%esp), %edx
L204:
	xorl	%ecx, %ecx
	movb	_txinfo+2, %cl
	cmpl	%eax, %ecx
	jg	L210
	xorl	%ebx, %ebx
	incl	%edx
	movb	_txinfo+8, %bl
	xorl	%eax, %eax
	imull	%edx, %ebx
	movb	_txinfo, %al
	movl	_ScreenAddress, %ecx
	decl	%eax
	movl	%edx, 24(%esp)
	addl	%eax, %ebx
	movl	%eax, 28(%esp)
	cmpw	$0, _ScreenVirtualSegment
	leal	(%ecx,%ebx,2), %esi
	jne	L223
L210:
	xorl	%eax, %eax
	movb	_txinfo+3, %al
	cmpl	%edx, %eax
	jg	L211
	cmpw	$0, _ScreenVirtualSegment
	jne	L224
L212:
	movl	__wscroll, %ecx
	testl	%ecx, %ecx
	jne	L225
L213:
	movl	24(%esp), %eax
	movl	32(%esp), %edx
	decl	%eax
	decl	%edx
	movl	%eax, 24(%esp)
	xorl	%eax, %eax
	movb	_txinfo+8, %al
	movl	%edx, 32(%esp)
	addl	%eax, %eax
	subl	%eax, %esi
L211:
	movl	%edi, %ebx
	xorl	%eax, %eax
	movb	(%ebx), %dl
	leal	1(%ebx), %edi
	movb	%dl, %al
	testl	%eax, %eax
	jne	L214
L218:
	cmpw	$0, _ScreenVirtualSegment
	je	L215
	leal	40(%esp), %eax
	leal	32(%esp), %ecx
	movl	%eax, 4(%esp)
	leal	36(%esp), %eax
	movl	%eax, (%esp)
	movl	24(%esp), %edx
	movl	28(%esp), %eax
	call	_mayrefreshline
L215:
	movl	28(%esp), %eax
	movl	%eax, 4(%esp)
	movl	24(%esp), %eax
	movl	%eax, (%esp)
	call	_ScreenSetCursor
	movl	24(%esp), %eax
	subb	_txinfo+1, %al
	addl	$2, %eax
	movb	%al, _txinfo+10
	movl	28(%esp), %eax
	subb	_txinfo, %al
	addl	$2, %eax
	movb	%al, _txinfo+9
	xorl	%eax, %eax
	movb	(%ebx), %al
	addl	$108, %esp
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
L219:
	.cfi_restore_state
	xorl	%eax, %eax
	movl	24(%esp), %edx
	movb	_txinfo+8, %al
	incl	%edx
	movl	%edx, 24(%esp)
	leal	(%esi,%eax,2), %esi
	cmpw	$0, _ScreenVirtualSegment
	jne	L203
	movl	28(%esp), %eax
	jmp	L204
	.p2align 4,,7
L220:
	xorl	%ecx, %ecx
	movl	24(%esp), %edx
	movb	_txinfo+8, %cl
	xorl	%eax, %eax
	imull	%edx, %ecx
	movb	_txinfo, %al
	movl	_ScreenAddress, %ebx
	decl	%eax
	addl	%eax, %ecx
	movl	%eax, 28(%esp)
	cmpw	$0, _ScreenVirtualSegment
	leal	(%ebx,%ecx,2), %esi
	je	L204
L217:
	leal	40(%esp), %ecx
	movl	%ecx, 4(%esp)
	leal	36(%esp), %ecx
	movl	%ecx, (%esp)
	leal	32(%esp), %ecx
	call	_mayrefreshline
	movl	28(%esp), %eax
	movl	24(%esp), %edx
	jmp	L204
	.p2align 4,,7
L221:
	xorl	%edx, %edx
	movl	28(%esp), %eax
	movb	_txinfo, %dl
	cmpl	%eax, %edx
	jg	L207
	decl	%eax
	subl	$2, %esi
	movl	%eax, 28(%esp)
	movl	24(%esp), %edx
L208:
	cmpw	$0, _ScreenVirtualSegment
	je	L204
	jmp	L217
	.p2align 4,,7
L223:
	leal	40(%esp), %ecx
	movl	%ecx, 4(%esp)
	leal	36(%esp), %ecx
	movl	%ecx, (%esp)
	leal	32(%esp), %ecx
	call	_mayrefreshline
	movl	24(%esp), %edx
	jmp	L210
	.p2align 4,,7
L225:
	xorl	%eax, %eax
	movl	$0, 4(%esp)
	movb	_txinfo+1, %al
	decl	%eax
	movl	%eax, (%esp)
	call	_ScreenSetCursor
	call	_delline
	jmp	L213
	.p2align 4,,7
L224:
	leal	40(%esp), %eax
	leal	32(%esp), %ecx
	movl	%eax, 4(%esp)
	leal	36(%esp), %eax
	movl	%eax, (%esp)
	movl	28(%esp), %eax
	call	_mayrefreshline
	jmp	L212
	.p2align 4,,7
L222:
	leal	44(%esp), %eax
	movl	$16, (%esp)
	movl	%eax, 4(%esp)
	movb	$14, 73(%esp)
	movb	$7, 72(%esp)
	call	___dpmi_int
	movl	28(%esp), %eax
	movl	24(%esp), %edx
	jmp	L204
	.p2align 4,,7
L203:
	leal	40(%esp), %eax
	leal	32(%esp), %ecx
	movl	%eax, 4(%esp)
	leal	36(%esp), %eax
	movl	%eax, (%esp)
	movl	28(%esp), %eax
	call	_mayrefreshline
	movl	28(%esp), %eax
	movl	24(%esp), %edx
	jmp	L204
	.p2align 4,,7
L207:
	xorl	%ecx, %ecx
	movl	24(%esp), %edx
	movb	_txinfo+1, %cl
	cmpl	%edx, %ecx
	jg	L208
	xorl	%ebx, %ebx
	decl	%edx
	movb	_txinfo+8, %bl
	xorl	%eax, %eax
	imull	%edx, %ebx
	movb	_txinfo+2, %al
	movl	_ScreenAddress, %ecx
	decl	%eax
	movl	%edx, 24(%esp)
	addl	%eax, %ebx
	movl	%eax, 28(%esp)
	leal	(%ecx,%ebx,2), %esi
	jmp	L208
	.cfi_endproc
LFE53:
	.p2align 4,,15
	.globl	_cprintf
_cprintf:
LFB54:
	.cfi_startproc
	pushl	%esi
	.cfi_def_cfa_offset 8
	.cfi_offset 6, -8
	pushl	%ebx
	.cfi_def_cfa_offset 12
	.cfi_offset 3, -12
	subl	$2068, %esp
	.cfi_def_cfa_offset 2080
	leal	2084(%esp), %eax
	leal	16(%esp), %ebx
	movl	%eax, 8(%esp)
	movl	2080(%esp), %eax
	movl	%ebx, (%esp)
	movl	%eax, 4(%esp)
	call	_vsprintf
	movl	%ebx, (%esp)
	movl	%eax, %esi
	call	_cputs
	addl	$2068, %esp
	.cfi_def_cfa_offset 12
	movl	%esi, %eax
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 8
	popl	%esi
	.cfi_restore 6
	.cfi_def_cfa_offset 4
	ret
	.cfi_endproc
LFE54:
LC0:
	.ascii "\10 \10\0"
	.p2align 4,,15
	.globl	_cgets
_cgets:
LFB55:
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
	movl	64(%esp), %edx
	testl	%edx, %edx
	je	L239
	movl	64(%esp), %eax
	xorl	%edx, %edx
	movl	%eax, %edi
	xorl	%ebx, %ebx
	movb	(%eax), %dl
	addl	$2, %edi
	movl	%edx, %esi
	movl	%edx, 28(%esp)
	decl	%esi
L245:
	cmpl	%esi, %ebx
	jae	L234
L237:
	call	_getch
	cmpl	$8, %eax
	je	L247
	cmpl	$13, %eax
	je	L248
	testl	%eax, %eax
	je	L249
	movl	%eax, (%esp)
	leal	(%edi,%ebx), %ebp
	call	_putch
	incl	%ebx
	movb	%al, 0(%ebp)
	cmpl	%esi, %ebx
	jb	L237
L234:
	movl	28(%esp), %edx
	movb	$0, -1(%edi,%edx)
	movl	64(%esp), %edx
	movb	%bl, 1(%edx)
L229:
	addl	$44, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 20
	movl	%edi, %eax
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
L247:
	.cfi_restore_state
	testl	%ebx, %ebx
	je	L245
	decl	%ebx
	movl	$LC0, (%esp)
	call	_cputs
	movb	$0, (%edi,%ebx)
	jmp	L245
	.p2align 4,,7
L248:
	movb	$0, (%edi,%ebx)
	jmp	L234
	.p2align 4,,7
L249:
	movl	_char_avail, %eax
	movb	$0, (%edi,%ebx)
	testl	%eax, %eax
	jne	L234
	movl	$0, _ungot_char
	movl	$1, _char_avail
	jmp	L234
L239:
	xorl	%edi, %edi
	jmp	L229
	.cfi_endproc
LFE55:
	.p2align 4,,15
	.globl	_cscanf
_cscanf:
LFB56:
	.cfi_startproc
	subl	$44, %esp
	.cfi_def_cfa_offset 48
	leal	52(%esp), %eax
	movl	$__scan_ungetch, 8(%esp)
	movl	%eax, 16(%esp)
	movl	48(%esp), %eax
	movl	%eax, 12(%esp)
	movl	$__scan_getche, 4(%esp)
	movl	$0, (%esp)
	call	__doscan_low
	addl	$44, %esp
	.cfi_def_cfa_offset 4
	ret
	.cfi_endproc
LFE56:
	.p2align 4,,15
	.globl	_movetext
_movetext:
LFB57:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%edi
	pushl	%esi
	pushl	%ebx
	subl	$44, %esp
	.cfi_offset 7, -12
	.cfi_offset 6, -16
	.cfi_offset 3, -20
	movl	20(%ebp), %edi
	movl	8(%ebp), %edx
	movl	16(%ebp), %eax
	movl	12(%ebp), %esi
	subl	%edx, %eax
	movl	%edi, %edx
	subl	%esi, %edx
	incl	%edx
	leal	2(%eax,%eax), %eax
	imull	%edx, %eax
	addl	$30, %eax
	andl	$-16, %eax
	subl	%eax, %esp
	movl	16(%ebp), %eax
	leal	35(%esp), %ebx
	movl	%eax, 8(%esp)
	andl	$-16, %ebx
	movl	8(%ebp), %eax
	movl	%ebx, 16(%esp)
	movl	%edi, 12(%esp)
	movl	%esi, 4(%esp)
	movl	%eax, (%esp)
	call	__conio_gettext
	movl	28(%ebp), %ecx
	addl	%ecx, %edi
	movl	%ebx, 16(%esp)
	subl	%esi, %edi
	movl	24(%ebp), %ebx
	movl	16(%ebp), %esi
	movl	28(%ebp), %eax
	movl	%edi, 12(%esp)
	addl	%esi, %ebx
	movl	8(%ebp), %edi
	movl	%eax, 4(%esp)
	subl	%edi, %ebx
	movl	24(%ebp), %eax
	movl	%ebx, 8(%esp)
	movl	%eax, (%esp)
	call	_puttext
	leal	-12(%ebp), %esp
	movl	$1, %eax
	popl	%ebx
	.cfi_restore 3
	popl	%esi
	.cfi_restore 6
	popl	%edi
	.cfi_restore 7
	popl	%ebp
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
LFE57:
	.p2align 4,,15
	.globl	_gettextinfo
_gettextinfo:
LFB59:
	.cfi_startproc
	movl	4(%esp), %eax
	movl	_txinfo, %edx
	movl	%edx, (%eax)
	movl	_txinfo+4, %edx
	movl	%edx, 4(%eax)
	movw	_txinfo+8, %dx
	movw	%dx, 8(%eax)
	movb	_txinfo+10, %dl
	movb	%dl, 10(%eax)
	ret
	.cfi_endproc
LFE59:
	.p2align 4,,15
	.globl	__set_screen_lines
__set_screen_lines:
LFB68:
	.cfi_startproc
	pushl	%ebx
	.cfi_def_cfa_offset 8
	.cfi_offset 3, -8
	subl	$88, %esp
	.cfi_def_cfa_offset 96
	movl	96(%esp), %eax
	subl	$25, %eax
	cmpl	$25, %eax
	ja	L256
	jmp	*L263(,%eax,4)
	.p2align 2
	.p2align 2
L263:
	.long	L257
	.long	L256
	.long	L256
	.long	L258
	.long	L256
	.long	L256
	.long	L256
	.long	L256
	.long	L256
	.long	L256
	.long	L259
	.long	L256
	.long	L256
	.long	L256
	.long	L256
	.long	L260
	.long	L256
	.long	L256
	.long	L261
	.long	L256
	.long	L256
	.long	L256
	.long	L256
	.long	L256
	.long	L256
	.long	L262
	.p2align 4,,7
L257:
	movl	_adapter_type, %eax
	leal	28(%esp), %ebx
	testl	%eax, %eax
	je	L264
	cmpl	$2, %eax
	movl	%ebx, 4(%esp)
	setge	%al
	incl	%eax
	movl	$16, (%esp)
	movb	$48, 44(%esp)
	movb	$18, 57(%esp)
	movb	%al, 56(%esp)
	call	___dpmi_int
	cmpl	$2, _adapter_type
	setge	%al
	movl	%ebx, 4(%esp)
	movl	$16, (%esp)
	leal	17(%eax,%eax,2), %eax
	movb	$0, 44(%esp)
	movb	$17, 57(%esp)
	movb	%al, 56(%esp)
	call	___dpmi_int
L264:
	movl	$3, %eax
	cmpb	$7, _txinfo+6
	je	L276
L267:
	movl	%ebx, 4(%esp)
	movl	$16, (%esp)
	movw	%ax, 56(%esp)
	call	___dpmi_int
	.p2align 4,,7
L256:
	call	__gettextinfo.constprop.0
	addl	$88, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 8
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L262:
	.cfi_restore_state
	cmpl	$1, _adapter_type
	jle	L256
	movl	$18, %edx
	movl	$2, %eax
	call	_set_scan_lines_and_font
	jmp	L256
	.p2align 4,,7
L258:
	cmpl	$1, _adapter_type
	jle	L256
	movl	$17, %edx
	movl	$2, %eax
	call	_set_scan_lines_and_font
	jmp	L256
	.p2align 4,,7
L259:
	movl	_adapter_type, %edx
	testl	%edx, %edx
	je	L256
	movl	$1, %eax
	call	_set_scan_lines_and_8x10_font
	jmp	L256
	.p2align 4,,7
L260:
	cmpl	$1, _adapter_type
	jle	L256
	movl	$2, %eax
	call	_set_scan_lines_and_8x10_font
	jmp	L256
	.p2align 4,,7
L261:
	movl	_adapter_type, %eax
	testl	%eax, %eax
	je	L256
	movl	$18, %edx
	movl	$1, %eax
	call	_set_scan_lines_and_font
	jmp	L256
	.p2align 4,,7
L276:
	movb	$7, %al
	jmp	L267
	.cfi_endproc
LFE68:
	.p2align 4,,15
	.globl	_blinkvideo
_blinkvideo:
LFB69:
	.cfi_startproc
	subl	$92, %esp
	.cfi_def_cfa_offset 96
	leal	28(%esp), %eax
	movl	$16, (%esp)
	movl	%eax, 4(%esp)
	movb	$1, 44(%esp)
	movw	$4099, 56(%esp)
	call	___dpmi_int
	movl	$1125, %eax
/APP
# 132 "c:/djgpp/include/libc/farptrgs.h" 1
	movw __go32_info_block+26,%gs 
	.byte 0x65 
	movb (%eax),%al
# 0 "" 2
/NO_APP
	shrb	$5, %al
	xorl	$1, %eax
	andl	$1, %eax
	movl	%eax, _intense_bg_mode
	addl	$92, %esp
	.cfi_def_cfa_offset 4
	ret
	.cfi_endproc
LFE69:
	.p2align 4,,15
	.globl	_intensevideo
_intensevideo:
LFB70:
	.cfi_startproc
	subl	$92, %esp
	.cfi_def_cfa_offset 96
	leal	28(%esp), %eax
	movl	$16, (%esp)
	movl	%eax, 4(%esp)
	movb	$0, 44(%esp)
	movw	$4099, 56(%esp)
	call	___dpmi_int
	movl	$1125, %eax
/APP
# 132 "c:/djgpp/include/libc/farptrgs.h" 1
	movw __go32_info_block+26,%gs 
	.byte 0x65 
	movb (%eax),%al
# 0 "" 2
/NO_APP
	shrb	$5, %al
	xorl	$1, %eax
	andl	$1, %eax
	movl	%eax, _intense_bg_mode
	addl	$92, %esp
	.cfi_def_cfa_offset 4
	ret
	.cfi_endproc
LFE70:
	.p2align 4,,15
	.globl	_gppconio_init
_gppconio_init:
LFB71:
	.cfi_startproc
	subl	$140, %esp
	.cfi_def_cfa_offset 144
	movl	___bss_count, %eax
	cmpl	%eax, _conio_count
	je	L282
	movl	%eax, _conio_count
	movl	$-1, _oldattrib
	movl	$65535, _last_mode
	movl	$-1, _font_seg
L282:
	call	_isEGA
	cmpl	$-1, _oldattrib
	je	L290
L283:
	cmpl	$65535, _last_mode
	je	L291
L284:
	call	__gettextinfo.constprop.0
	cmpb	$7, _txinfo+6
	setne	%al
	andl	$255, %eax
	decl	%eax
	andl	$-32768, %eax
	addl	$753664, %eax
	movl	%eax, _ScreenAddress
	movl	$1125, %eax
/APP
# 132 "c:/djgpp/include/libc/farptrgs.h" 1
	movw __go32_info_block+26,%gs 
	.byte 0x65 
	movb (%eax),%al
# 0 "" 2
/NO_APP
	shrb	$5, %al
	movl	$16, (%esp)
	xorl	$1, %eax
	movw	$0, 24(%esp)
	andl	$1, %eax
	movw	$0, 58(%esp)
	movl	%eax, _intense_bg_mode
	leal	24(%esp), %eax
	movl	%eax, 4(%esp)
	movb	$-2, 53(%esp)
	call	___dpmi_int
	movw	58(%esp), %ax
	movl	24(%esp), %edx
	movw	%ax, _ScreenVirtualSegment
	testw	%ax, %ax
	movw	%dx, _ScreenVirtualOffset
	je	L292
	andl	$65535, %eax
	andl	$65535, %edx
	sall	$4, %eax
	addl	%edx, %eax
	movl	%eax, _ScreenAddress
	movl	%eax, __go32_info_block+4
	addl	$140, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L292:
	.cfi_restore_state
	movl	_ScreenAddress, %eax
	movl	%eax, __go32_info_block+4
	addl	$140, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L291:
	.cfi_restore_state
	call	_getvideomode
	movl	%eax, _last_mode
	jmp	L284
	.p2align 4,,7
L290:
	leal	76(%esp), %eax
	movl	$16, (%esp)
	movl	%eax, 4(%esp)
	movb	$8, 105(%esp)
	movb	$0, 93(%esp)
	call	___dpmi_int
	movb	105(%esp), %al
	andl	$127, %eax
	movl	%eax, _oldattrib
	jmp	L283
	.cfi_endproc
LFE71:
	.p2align 4,,15
	.globl	_textmode
_textmode:
LFB30:
	.cfi_startproc
	pushl	%esi
	.cfi_def_cfa_offset 8
	.cfi_offset 6, -8
	pushl	%ebx
	.cfi_def_cfa_offset 12
	.cfi_offset 3, -12
	subl	$84, %esp
	.cfi_def_cfa_offset 96
	movl	96(%esp), %ebx
	cmpl	$-1, %ebx
	je	L311
L294:
	xorl	%eax, %eax
	movb	$0, 57(%esp)
	movb	_txinfo+6, %al
	cmpl	$64, %ebx
	movl	%eax, _last_mode
	je	L295
	leal	28(%esp), %esi
	movb	%bl, 56(%esp)
	movl	%esi, 4(%esp)
	movl	$16, (%esp)
	subl	$2, %ebx
	call	___dpmi_int
	cmpl	$1, %ebx
	jbe	L312
L296:
	call	_gppconio_init
L293:
	addl	$84, %esp
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
L311:
	.cfi_restore_state
	movl	_last_mode, %ebx
	jmp	L294
	.p2align 4,,7
L295:
	leal	28(%esp), %esi
	movl	$16, (%esp)
	movl	%esi, 4(%esp)
	movb	$3, 56(%esp)
	call	___dpmi_int
	movb	$1, %bl
L300:
	call	_isEGA
	testl	%eax, %eax
	jne	L313
L297:
	testb	%bl, %bl
	je	L296
	call	_isEGA
	testl	%eax, %eax
	je	L293
	movl	%esi, 4(%esp)
	movl	$16, (%esp)
	movw	$4370, 56(%esp)
	movw	$0, 44(%esp)
	call	___dpmi_int
	jmp	L296
	.p2align 4,,7
L313:
	movl	%esi, 4(%esp)
	movl	$16, (%esp)
	movb	$18, 57(%esp)
	movb	$52, 44(%esp)
	movb	$0, 56(%esp)
	call	___dpmi_int
	jmp	L297
L312:
	xorl	%ebx, %ebx
	jmp	L300
	.cfi_endproc
LFE30:
	.globl	_directvideo
	.section .data
	.p2align 2
_directvideo:
	.long	1
	.globl	__wscroll
	.p2align 2
__wscroll:
	.long	1
.lcomm _txinfo,11,1
	.p2align 2
_ScreenAddress:
	.long	753664
.lcomm _ScreenVirtualSegment,2,2
.lcomm _ScreenVirtualOffset,2,2
	.p2align 2
_last_mode:
	.long	65535
	.p2align 2
_adapter_type:
	.long	-1
.lcomm _intense_bg_mode,4,4
	.section .text
	.p2align 2
_CSWTCH.152:
	.long	8192
	.long	7
.lcomm _char_avail,4,4
.lcomm _ungot_char,4,4
	.section .data
	.p2align 2
_font_seg:
	.long	-1
	.p2align 2
_oldattrib:
	.long	-1
	.p2align 2
_conio_count:
	.long	-1
	.ident	"GCC: (GNU) 4.7.4"
