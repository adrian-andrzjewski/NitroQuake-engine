	.file	"getcwd.c"
	.section .text
	.p2align 4,,15
	.globl	___getcwd
___getcwd:
LFB23:
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
	subl	$364, %esp
	.cfi_def_cfa_offset 384
	movl	$0, (%esp)
	movl	388(%esp), %esi
	movl	384(%esp), %ebx
	call	__use_lfn
	movsbl	%al, %ebp
	call	__preserve_fncase
	testl	%esi, %esi
	movb	%al, 28(%esp)
	je	L56
	testl	%ebx, %ebx
	je	L57
L4:
	movl	__go32_info_block+16, %eax
	cmpl	%eax, %esi
	ja	L58
	testl	%ebp, %ebp
	jne	L59
L6:
	movb	$71, 69(%esp)
	leal	40(%esp), %edi
	jmp	L49
	.p2align 4,,7
L60:
	movb	$71, 69(%esp)
	xorl	%ebp, %ebp
L49:
	movl	__go32_info_block+12, %eax
	movl	%edi, 4(%esp)
	shrl	$4, %eax
	movl	$33, (%esp)
	movb	$0, 60(%esp)
	movw	$0, 44(%esp)
	movw	%ax, 76(%esp)
	call	___dpmi_int
	movl	68(%esp), %eax
	cmpw	$28928, %ax
	je	L60
	testb	$1, 72(%esp)
	jne	L61
/APP
# 169 "c:/djgpp/include/libc/farptrgs.h" 1
	movw __go32_info_block+26,%gs
# 0 "" 2
/NO_APP
	movl	__go32_info_block+12, %eax
	cmpw	$1330, __os_trueversion
	je	L11
	movl	$3, %ebp
L12:
/APP
# 218 "c:/djgpp/include/libc/farptrgs.h" 1
	.byte 0x65
	movb (%eax),%al
# 0 "" 2
/NO_APP
	testb	%al, %al
	je	L32
	xorl	%edx, %edx
	movl	%ebp, %ecx
	cmpl	%ebp, %esi
	ja	L45
	jmp	L17
	.p2align 4,,7
L18:
	leal	0(%ebp,%edx), %ecx
	cmpl	%ecx, %esi
	jbe	L17
L45:
	movb	%al, (%ebx,%ecx)
	incl	%edx
	movl	__go32_info_block+12, %eax
	addl	%edx, %eax
/APP
# 218 "c:/djgpp/include/libc/farptrgs.h" 1
	.byte 0x65
	movb (%eax),%al
# 0 "" 2
/NO_APP
	testb	%al, %al
	jne	L18
L15:
	addl	%ebx, %edx
	leal	2(%ebx), %ecx
	movb	$0, (%edx,%ebp)
	movb	28(%esp), %dl
	movb	$58, 1(%ebx)
	movb	$47, 2(%ebx)
	leal	3(%ebx), %ebp
	movl	%ebx, 28(%esp)
	jmp	L28
	.p2align 4,,7
L63:
	testb	%al, %al
	je	L37
L64:
	cmpb	$47, %al
	je	L37
L21:
	incl	%ebp
	cmpb	$0, (%ecx)
	je	L29
L28:
	movb	0(%ebp), %al
	cmpb	$92, %al
	je	L62
	testb	%dl, %dl
	je	L63
	testb	%al, %al
	jne	L21
L29:
	movl	%edi, 4(%esp)
	movl	$33, (%esp)
	movl	28(%esp), %ebx
	movb	$25, 69(%esp)
	call	___dpmi_int
	movb	68(%esp), %dl
	cmpb	$26, %dl
	sbbl	%eax, %eax
	andl	$32, %eax
	leal	65(%eax,%edx), %eax
	movb	%al, (%ebx)
L3:
	addl	$364, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 20
	movl	%ebx, %eax
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
L59:
	.cfi_restore_state
	movw	$1, 72(%esp)
	movw	$28999, 68(%esp)
	leal	40(%esp), %edi
	jmp	L49
	.p2align 4,,7
L58:
	movl	%eax, %esi
	testl	%ebp, %ebp
	je	L6
	jmp	L59
	.p2align 4,,7
L62:
	movb	$47, 0(%ebp)
	testb	%dl, %dl
	jne	L21
	movb	$47, %al
	testb	%al, %al
	jne	L64
	.p2align 4,,7
L37:
	movl	%ebp, %esi
	leal	1(%ecx), %ebx
	subl	%ecx, %esi
	leal	92(%esp), %eax
	decl	%esi
	movl	%ebx, 4(%esp)
	movl	%esi, 8(%esp)
	movl	%eax, (%esp)
	movb	%dl, 24(%esp)
	call	_memcpy
	leal	92(%esp), %eax
	movb	$0, 92(%esp,%esi)
	movl	%eax, (%esp)
	call	__is_DOS83
	movl	%ebp, %ecx
	testl	%eax, %eax
	movb	24(%esp), %dl
	je	L21
	.p2align 4,,7
L50:
	movl	%ebx, %ecx
	cmpl	%ebp, %ebx
	jae	L21
	movb	(%ebx), %al
	leal	-65(%eax), %ecx
	cmpb	$25, %cl
	ja	L54
	addl	$32, %eax
	movb	%al, (%ebx)
L54:
	incl	%ebx
	jmp	L50
	.p2align 4,,7
L17:
	movl	$2, _errno
	addl	$364, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 20
	xorl	%ebx, %ebx
	movl	%ebx, %eax
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
L11:
	.cfi_restore_state
	testl	%ebp, %ebp
	je	L65
/APP
# 218 "c:/djgpp/include/libc/farptrgs.h" 1
	.byte 0x65
	movb (%eax),%dl
# 0 "" 2
/NO_APP
	movl	$3, %ebp
	testb	%dl, %dl
	jne	L12
	movl	%eax, %edx
	movw	$29024, 68(%esp)
	shrl	$4, %edx
	movw	$-32766, 64(%esp)
	movw	%dx, 74(%esp)
	movw	$260, 44(%esp)
	movw	$0, 40(%esp)
	addl	$260, %eax
/APP
# 198 "c:/djgpp/include/libc/farptrgs.h" 1
	.byte 0x65
	movw $46,(%eax)
# 0 "" 2
/NO_APP
	movl	%edi, 4(%esp)
	movl	$33, (%esp)
	call	___dpmi_int
	movl	__go32_info_block+12, %eax
	testb	$1, 72(%esp)
	jne	L14
	xorw	%bp, %bp
	jmp	L12
	.p2align 4,,7
L65:
	movw	$3, %bp
	jmp	L12
L56:
	movl	$14, _errno
	addl	$364, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 20
	xorl	%ebx, %ebx
	movl	%ebx, %eax
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
L57:
	.cfi_restore_state
	movl	%esi, (%esp)
	call	_malloc
	movl	%eax, %ebx
	testl	%eax, %eax
	jne	L4
	movl	$25, _errno
	jmp	L3
	.p2align 4,,7
L61:
	andl	$65535, %eax
	xorl	%ebx, %ebx
	movl	%eax, (%esp)
	call	___doserr_to_errno
	movl	%eax, _errno
	jmp	L3
L32:
	xorl	%edx, %edx
	jmp	L15
L14:
/APP
# 188 "c:/djgpp/include/libc/farptrgs.h" 1
	.byte 0x65
	movb $0,(%eax)
# 0 "" 2
/NO_APP
	jmp	L12
	.cfi_endproc
LFE23:
	.ident	"GCC: (GNU) 4.7.4"
