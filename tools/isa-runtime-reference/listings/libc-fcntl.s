	.file	"fcntl.c"
	.section .text
	.p2align 4,,15
__get_sft_entry_ptr:
LFB24:
	.cfi_startproc
	pushl	%ebx
	.cfi_def_cfa_offset 8
	.cfi_offset 3, -8
	subl	$88, %esp
	.cfi_def_cfa_offset 96
	leal	28(%esp), %ebx
	movl	$47, (%esp)
	movl	%ebx, 4(%esp)
	movw	$4640, 56(%esp)
	movw	%ax, 44(%esp)
	call	___dpmi_int
	movl	60(%esp), %edx
	testb	$1, %dl
	jne	L9
	movw	62(%esp), %ax
	movl	28(%esp), %ecx
	andl	$65535, %eax
	andl	$65535, %ecx
	sall	$4, %eax
	addl	%ecx, %eax
/APP
# 132 "c:/djgpp/include/libc/farptrgs.h" 1
	movw __go32_info_block+26,%gs 
	.byte 0x65 
	movb (%eax),%al
# 0 "" 2
/NO_APP
	orl	$1, %edx
	cmpb	$-1, %al
	je	L5
	andl	$255, %eax
	movl	%ebx, 4(%esp)
	movl	$47, (%esp)
	movw	$4630, 56(%esp)
	movw	%ax, 44(%esp)
	call	___dpmi_int
	movl	60(%esp), %edx
L5:
	andl	$1, %edx
	jne	L10
	movw	62(%esp), %dx
	movl	28(%esp), %eax
	andl	$65535, %edx
	addl	$88, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 8
	sall	$4, %edx
	andl	$65535, %eax
	addl	%edx, %eax
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L10:
	.cfi_restore_state
	movl	$6, _errno
	addl	$88, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 8
	xorl	%eax, %eax
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L9:
	.cfi_restore_state
	xorl	%eax, %eax
	movb	56(%esp), %al
	movl	%eax, (%esp)
	call	___doserr_to_errno
	movl	%eax, _errno
	addl	$88, %esp
	.cfi_def_cfa_offset 8
	xorl	%eax, %eax
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 4
	ret
	.cfi_endproc
LFE24:
	.p2align 4,,15
___FSEXT_func_wrapper.constprop.2:
LFB31:
	.cfi_startproc
	subl	$28, %esp
	.cfi_def_cfa_offset 32
	leal	44(%esp), %eax
	movl	$7, (%esp)
	movl	%eax, 8(%esp)
	movl	40(%esp), %eax
	movl	%eax, 4(%esp)
	call	*32(%esp)
	addl	$28, %esp
	.cfi_def_cfa_offset 4
	ret
	.cfi_endproc
LFE31:
	.p2align 4,,15
__fcntl_lk64:
LFB27:
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
	movl	%eax, %ebx
	movl	%edx, %edi
	movl	%ecx, %esi
	testl	%eax, %eax
	js	L14
	movl	___fd_properties, %eax
	testl	%eax, %eax
	je	L14
	movl	(%eax,%ebx,4), %eax
	testl	%eax, %eax
	je	L14
	testb	$32, 8(%eax)
	jne	L52
L14:
	leal	76(%esp), %eax
	movl	$47, (%esp)
	movl	%eax, 4(%esp)
	movw	$4096, 104(%esp)
	call	___dpmi_int
	cmpb	$-1, 104(%esp)
	je	L17
	xorl	%eax, %eax
	cmpl	$9, %edi
	je	L53
L43:
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
L53:
	.cfi_restore_state
	movw	$0, 20(%esi)
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
L17:
	.cfi_restore_state
	movl	$1, 12(%esp)
	movl	$0, 4(%esp)
	movl	$0, 8(%esp)
	movl	%ebx, (%esp)
	call	___llseek
	movl	%eax, 52(%esp)
	movl	%edx, %ebp
	testl	%edx, %edx
	js	L51
	movswl	22(%esi), %eax
	movl	%eax, 12(%esp)
	movl	12(%esi), %eax
	movl	16(%esi), %edx
	movl	%edx, 8(%esp)
	movl	%eax, 4(%esp)
	movl	%ebx, (%esp)
	call	___llseek
	movl	%eax, 40(%esp)
	movl	%edx, 44(%esp)
	testl	%edx, %edx
	js	L51
	movl	(%esi), %eax
	movl	4(%esi), %edx
	movl	%edx, 36(%esp)
	movl	%eax, 32(%esp)
	orl	%eax, %edx
	je	L54
L21:
	movl	52(%esp), %eax
	movl	$0, 12(%esp)
	movl	%eax, 4(%esp)
	movl	%ebp, 8(%esp)
	movl	%ebx, (%esp)
	call	___llseek
	testl	%edx, %edx
	js	L51
	cmpl	$0, 36(%esp)
	jle	L55
L22:
	movl	20(%esi), %eax
	testw	%ax, %ax
	je	L56
	decl	%eax
	cmpw	$1, %ax
	jbe	L57
	movl	$27, _errno
L51:
	addl	$140, %esp
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
	.p2align 4,,7
L52:
	.cfi_restore_state
	movl	$14, _errno
	orl	$-1, %eax
	jmp	L43
	.p2align 4,,7
L54:
	movl	%ebx, (%esp)
	call	___lfilelength
	movl	%eax, 56(%esp)
	subl	40(%esp), %eax
	movl	%edx, 60(%esp)
	movl	%eax, 32(%esp)
	sbbl	44(%esp), %edx
	movl	%edx, 36(%esp)
	testl	%edx, %edx
	jns	L21
	negl	32(%esp)
	adcl	$0, 36(%esp)
	movl	52(%esp), %eax
	movl	$0, 12(%esp)
	movl	%eax, 4(%esp)
	movl	%ebp, 8(%esp)
	movl	%ebx, (%esp)
	negl	36(%esp)
	call	___llseek
	testl	%edx, %edx
	js	L51
	movl	56(%esp), %eax
	movl	60(%esp), %edx
	movl	%eax, 40(%esp)
	movl	%edx, 44(%esp)
	jmp	L22
	.p2align 4,,7
L56:
	movl	32(%esp), %eax
	movl	36(%esp), %edx
	movl	%eax, 12(%esp)
	movl	%edx, 16(%esp)
	movl	40(%esp), %eax
	movl	44(%esp), %edx
	movl	%eax, 4(%esp)
	movl	%edx, 8(%esp)
	movl	%ebx, (%esp)
	call	__dos_unlk64
	testl	%eax, %eax
	jne	L48
L29:
	xorl	%eax, %eax
	jmp	L43
	.p2align 4,,7
L55:
	jl	L36
	cmpl	$0, 32(%esp)
	ja	L22
L36:
	movl	32(%esp), %eax
	movl	36(%esp), %edx
	addl	%eax, 40(%esp)
	adcl	%edx, 44(%esp)
	negl	%eax
	adcl	$0, %edx
	movl	%eax, 32(%esp)
	negl	%edx
	movl	%edx, 36(%esp)
	jmp	L22
L48:
	movl	%eax, (%esp)
	movl	%eax, __doserrno
	call	___doserr_to_errno
	movl	%eax, _errno
	orl	$-1, %eax
	jmp	L43
	.p2align 4,,7
L57:
	movl	32(%esp), %eax
	movl	36(%esp), %edx
	movl	%eax, 12(%esp)
	movl	%edx, 16(%esp)
	movl	40(%esp), %eax
	movl	44(%esp), %edx
	movl	%eax, 4(%esp)
	movl	%edx, 8(%esp)
	movl	%ebx, (%esp)
	call	__dos_lk64
	cmpl	$9, %edi
	je	L58
	testl	%eax, %eax
	je	L29
	cmpl	$11, %edi
	jne	L48
	movl	32(%esp), %esi
	movl	36(%esp), %edi
	jmp	L44
	.p2align 4,,7
L33:
	call	___dpmi_yield
L44:
	movl	40(%esp), %eax
	movl	44(%esp), %edx
	movl	%esi, 12(%esp)
	movl	%edi, 16(%esp)
	movl	%eax, 4(%esp)
	movl	%edx, 8(%esp)
	movl	%ebx, (%esp)
	call	__dos_lk64
	testl	%eax, %eax
	jne	L33
	xorl	%eax, %eax
	jmp	L43
L58:
	testl	%eax, %eax
	jne	L48
	movl	32(%esp), %eax
	movl	36(%esp), %edx
	movl	%eax, 12(%esp)
	movl	%edx, 16(%esp)
	movl	40(%esp), %eax
	movl	44(%esp), %edx
	movl	%eax, 4(%esp)
	movl	%edx, 8(%esp)
	movl	%ebx, (%esp)
	call	__dos_unlk64
	movw	$0, 20(%esi)
	xorl	%eax, %eax
	jmp	L43
	.cfi_endproc
LFE27:
	.p2align 4,,15
	.globl	_fcntl
_fcntl:
LFB28:
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
	subl	$220, %esp
	.cfi_def_cfa_offset 240
	movl	240(%esp), %ebx
	movl	%ebx, (%esp)
	call	__get_dev_info
	cmpw	$-1, %ax
	movl	%eax, %esi
	je	L119
	movl	%ebx, (%esp)
	call	___FSEXT_get_function
	testl	%eax, %eax
	je	L62
	leal	24(%esp), %edx
	movl	%ebx, 12(%esp)
	movl	%edx, 8(%esp)
	movl	$7, 4(%esp)
	movl	%eax, (%esp)
	call	___FSEXT_func_wrapper.constprop.2
	testl	%eax, %eax
	jne	L121
L62:
	movl	_errno, %edi
	cmpl	$11, 244(%esp)
	jbe	L122
L120:
	movl	$27, _errno
	.p2align 4,,7
L119:
	orl	$-1, %eax
L100:
	addl	$220, %esp
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
L122:
	.cfi_restore_state
	movl	244(%esp), %eax
	jmp	*L72(,%eax,4)
	.p2align 2
	.p2align 2
L72:
	.long	L120
	.long	L65
	.long	L66
	.long	L67
	.long	L68
	.long	L69
	.long	L70
	.long	L68
	.long	L68
	.long	L71
	.long	L71
	.long	L71
	.p2align 4,,7
L71:
	movl	248(%esp), %ecx
	movl	244(%esp), %edx
	movl	%ebx, %eax
	call	__fcntl_lk64
	jmp	L100
	.p2align 4,,7
L70:
	cmpb	$1, 248(%esp)
	sbbl	%eax, %eax
	xorl	$-1, %eax
	jmp	L100
	.p2align 4,,7
L69:
	movl	248(%esp), %edi
	cmpl	$17, %ebx
	jg	L123
	movl	_inherit_bit_visible.2608, %edx
	cmpl	$-1, %edx
	je	L124
L81:
	xorl	%ebp, %ebp
	testl	%edx, %edx
	je	L125
L82:
	movl	%esi, %ecx
	andb	$239, %ch
	andl	$1, %edi
	je	L84
	movl	%esi, %ecx
	orb	$16, %ch
L84:
	testl	%edx, %edx
	jne	L126
	leal	5(%ebp), %eax
/APP
# 108 "c:/djgpp/include/libc/farptrgs.h" 1
	movw __go32_info_block+26,%gs 
	.byte 0x65 
	movw %cx,(%eax)
# 0 "" 2
/NO_APP
	xorl	%eax, %eax
	jmp	L100
	.p2align 4,,7
L68:
	movl	248(%esp), %esi
	movl	244(%esp), %ecx
	movl	12(%esi), %eax
	movl	_CSWTCH.41-16(,%ecx,4), %edx
	movw	%ax, 48(%esp)
	movl	8(%esi), %eax
	movl	%eax, 40(%esp)
	movl	%eax, %ecx
	sarl	$31, %ecx
	movw	14(%esi), %ax
	movw	%ax, 50(%esp)
	movl	(%esi), %eax
	movl	%ecx, 44(%esp)
	movl	%eax, %ecx
	sarl	$31, %ecx
	movl	%eax, 28(%esp)
	movl	%ecx, 32(%esp)
	movl	%ebx, %eax
	leal	28(%esp), %ecx
	call	__fcntl_lk64
	movl	48(%esp), %edx
	movw	%dx, 12(%esi)
	movl	40(%esp), %edx
	movl	%edx, 8(%esi)
	movw	50(%esp), %dx
	movw	%dx, 14(%esi)
	movl	28(%esp), %edx
	movl	%edx, (%esi)
	jmp	L100
	.p2align 4,,7
L67:
	movl	%ebx, %eax
	call	__get_sft_entry_ptr
	movl	%eax, %edx
	movl	$2, %eax
	testl	%edx, %edx
	je	L86
	leal	2(%edx), %eax
/APP
# 145 "c:/djgpp/include/libc/farptrgs.h" 1
	movw __go32_info_block+26, %gs 
	.byte 0x65 
	movw (%eax),%ax 

# 0 "" 2
/NO_APP
	andl	$7, %eax
	leal	-1(%eax), %edx
	xorl	%eax, %eax
	cmpb	$1, %dl
	ja	L86
	xorl	%eax, %eax
	movb	%dl, %al
	movl	_CSWTCH.39(,%eax,4), %eax
	.p2align 4,,7
L86:
	testl	%ebx, %ebx
	js	L100
	movl	___fd_properties, %edx
	testl	%edx, %edx
	je	L100
	movl	(%edx,%ebx,4), %edx
	testl	%edx, %edx
	je	L100
	testb	$16, 8(%edx)
	je	L100
	orb	$16, %ah
	jmp	L100
	.p2align 4,,7
L66:
	movl	$1, %eax
	cmpl	$17, %ebx
	jg	L100
	movl	_inherit_bit_visible.2608, %eax
	cmpl	$-1, %eax
	je	L127
L76:
	testl	%eax, %eax
	je	L128
L77:
	shrw	$12, %si
	movl	%esi, %eax
	andl	$1, %eax
	jmp	L100
	.p2align 4,,7
L65:
	movl	248(%esp), %esi
	call	___getdtablesize
	movl	%eax, %ebp
	cmpl	%eax, %esi
	jl	L107
	jmp	L73
	.p2align 4,,7
L129:
	incl	%esi
	cmpl	%ebp, %esi
	je	L73
L107:
	movl	%esi, (%esp)
	call	__get_dev_info
	incw	%ax
	jne	L129
	movl	%esi, 4(%esp)
	movl	%ebx, (%esp)
	movl	%edi, _errno
	call	___dup2
	jmp	L100
	.p2align 4,,7
L121:
	movl	24(%esp), %eax
	addl	$220, %esp
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
L123:
	.cfi_restore_state
	xorl	%eax, %eax
	andl	$1, %edi
	je	L120
	jmp	L100
	.p2align 4,,7
L73:
	movl	$17, _errno
	orl	$-1, %eax
	jmp	L100
L128:
	movl	%ebx, %eax
	call	__get_sft_entry_ptr
	testl	%eax, %eax
	je	L119
	addl	$5, %eax
/APP
# 145 "c:/djgpp/include/libc/farptrgs.h" 1
	movw __go32_info_block+26, %gs 
	.byte 0x65 
	movw (%eax),%si 

# 0 "" 2
/NO_APP
	jmp	L77
L125:
	movl	%ebx, %eax
	call	__get_sft_entry_ptr
	movl	%eax, %ebp
	orl	$-1, %eax
	testl	%ebp, %ebp
	je	L100
	leal	5(%ebp), %esi
/APP
# 145 "c:/djgpp/include/libc/farptrgs.h" 1
	movw __go32_info_block+26, %gs 
	.byte 0x65 
	movw (%esi),%si 

# 0 "" 2
/NO_APP
	movl	_inherit_bit_visible.2608, %edx
	jmp	L82
L126:
	leal	52(%esp), %eax
	movl	$33, (%esp)
	movl	%eax, 4(%esp)
	movw	$17409, 80(%esp)
	movw	%bx, 68(%esp)
	movw	%cx, 72(%esp)
	call	___dpmi_int
	xorl	%eax, %eax
	jmp	L100
L127:
	leal	104(%esp), %eax
	movl	%esi, %edi
	orl	$4096, %edi
	movl	%eax, 4(%esp)
	movl	$33, (%esp)
	movw	$17409, 132(%esp)
	movw	%bx, 120(%esp)
	movw	%di, 124(%esp)
	call	___dpmi_int
	movl	%ebx, (%esp)
	call	__get_dev_info
	cmpw	%ax, %di
	sete	%al
	andl	$255, %eax
	movl	%eax, _inherit_bit_visible.2608
	jmp	L76
L124:
	leal	156(%esp), %eax
	movl	%esi, %ebp
	orl	$4096, %ebp
	movl	%eax, 4(%esp)
	movl	$33, (%esp)
	movw	$17409, 184(%esp)
	movw	%bx, 172(%esp)
	movw	%bp, 176(%esp)
	call	___dpmi_int
	movl	%ebx, (%esp)
	call	__get_dev_info
	cmpw	%ax, %bp
	sete	%dl
	andl	$255, %edx
	movl	%edx, _inherit_bit_visible.2608
	jmp	L81
	.cfi_endproc
LFE28:
	.section .data
	.p2align 2
_inherit_bit_visible.2608:
	.long	-1
	.section .text
	.p2align 2
_CSWTCH.39:
	.long	1
	.long	2
	.p2align 4
_CSWTCH.41:
	.long	9
	.long	-1
	.long	-1
	.long	10
	.long	11
	.ident	"GCC: (GNU) 4.7.4"
