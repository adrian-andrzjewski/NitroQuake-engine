	.file	"putpath.c"
	.section .text
LC0:
	.ascii "nul\0"
LC1:
	.ascii "con\0"
LC2:
	.ascii "/dev/\0"
LC3:
	.ascii "null\0"
LC4:
	.ascii "tty\0"
LC5:
	.ascii "env\0"
	.p2align 4,,15
	.globl	__put_path2
__put_path2:
LFB19:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%edi
	pushl	%esi
	pushl	%ebx
	subl	$124, %esp
	.cfi_offset 7, -12
	.cfi_offset 6, -16
	.cfi_offset 3, -20
	movl	__go32_info_block+12, %eax
	movl	12(%ebp), %edx
	addl	%eax, %edx
	movl	%eax, -108(%ebp)
	movl	__go32_info_block+16, %ecx
	movl	12(%ebp), %eax
	subl	%eax, %ecx
	movl	8(%ebp), %ebx
	movl	%ecx, -96(%ebp)
	testl	%ebx, %ebx
	je	L101
/APP
# 169 "c:/djgpp/include/libc/farptrgs.h" 1
	movw __go32_info_block+26,%gs
# 0 "" 2
/NO_APP
	movb	(%ebx), %al
	movl	%ebx, -104(%ebp)
	testb	%al, %al
	je	L3
	cmpb	$58, 1(%ebx)
	je	L102
L3:
	movl	$5, %ecx
	movl	$LC2, %edi
	movl	-104(%ebp), %esi
	repe cmpsb
	setb	-100(%ebp)
	seta	%cl
	cmpb	-100(%ebp), %cl
	jne	L42
	movl	-104(%ebp), %esi
	movl	$5, %ecx
	addl	$5, %esi
	movl	$LC3, %edi
	movl	%esi, -100(%ebp)
	repe cmpsb
	setb	-109(%ebp)
	seta	%cl
	cmpb	-109(%ebp), %cl
	jne	L103
	movb	$110, %al
	movl	$LC0, %ebx
L5:
	movl	%edx, -92(%ebp)
	movl	-96(%ebp), %ecx
	cmpb	$47, %al
	jne	L32
	.p2align 4,,7
L90:
	cmpb	$47, 1(%ebx)
	jne	L32
L33:
	incl	%ebx
	cmpb	$47, 1(%ebx)
	jne	L32
	jmp	L33
	.p2align 4,,7
L42:
	movl	%edx, -92(%ebp)
L4:
	testb	%al, %al
	je	L30
	movl	-96(%ebp), %ecx
	jmp	L74
	.p2align 4,,7
L32:
/APP
# 188 "c:/djgpp/include/libc/farptrgs.h" 1
	.byte 0x65
	movb %al,(%edx)
# 0 "" 2
/NO_APP
	decl	%ecx
	incl	%edx
	cmpl	$1, %ecx
	jle	L30
	movb	1(%ebx), %al
	incl	%ebx
	testb	%al, %al
	je	L30
L74:
	cmpb	$47, %al
	jne	L32
	jmp	L90
	.p2align 4,,7
L30:
	leal	-2(%edx), %eax
	cmpl	-92(%ebp), %eax
	jb	L35
	leal	-1(%edx), %ecx
/APP
# 218 "c:/djgpp/include/libc/farptrgs.h" 1
	.byte 0x65
	movb (%ecx),%bl
# 0 "" 2
/NO_APP
	cmpb	$47, %bl
	je	L104
L35:
/APP
# 188 "c:/djgpp/include/libc/farptrgs.h" 1
	.byte 0x65
	movb $0,(%edx)
# 0 "" 2
/NO_APP
	movl	-108(%ebp), %eax
	subl	%eax, %edx
	movl	%edx, 12(%ebp)
L89:
	movl	12(%ebp), %eax
	leal	-12(%ebp), %esp
	popl	%ebx
	.cfi_remember_state
	.cfi_restore 3
	popl	%esi
	.cfi_restore 6
	popl	%edi
	.cfi_restore 7
	popl	%ebp
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.p2align 4,,7
L103:
	.cfi_restore_state
	movl	$4, %ecx
	movl	$LC4, %edi
	movl	-100(%ebp), %esi
	repe cmpsb
	setb	-109(%ebp)
	seta	%cl
	cmpb	-109(%ebp), %cl
	je	L41
	movl	$4, %ecx
	movl	-100(%ebp), %esi
	movl	$LC5, %edi
	repe cmpsb
	setb	-109(%ebp)
	seta	%cl
	cmpb	-109(%ebp), %cl
	je	L42
	movl	-104(%ebp), %esi
	movb	5(%esi), %cl
	movb	%cl, %al
	andl	$-33, %eax
	subl	$65, %eax
	cmpb	$25, %al
	jbe	L105
L6:
	movl	$3, %ecx
	movl	-100(%ebp), %esi
	movl	$LC5, %edi
	repe cmpsb
	jne	L8
	movl	-104(%ebp), %esi
	movb	8(%esi), %al
	cmpb	$92, %al
	jne	L106
L52:
	movl	-104(%ebp), %esi
	movb	9(%esi), %cl
	testb	%cl, %cl
	jne	L107
L8:
	movl	(%ebx), %eax
/APP
# 208 "c:/djgpp/include/libc/farptrgs.h" 1
	.byte 0x65
	movl %eax,(%edx)
# 0 "" 2
/NO_APP
	leal	4(%edx), %eax
	movl	4(%ebx), %ecx
/APP
# 208 "c:/djgpp/include/libc/farptrgs.h" 1
	.byte 0x65
	movl %ecx,(%eax)
# 0 "" 2
/NO_APP
	cmpb	$47, 4(%ebx)
	je	L97
	leal	6(%edx), %eax
L97:
/APP
# 188 "c:/djgpp/include/libc/farptrgs.h" 1
	.byte 0x65
	movb $0,(%eax)
# 0 "" 2
/NO_APP
	movl	-108(%ebp), %eax
	movl	$33, (%esp)
	shrl	$4, %eax
	movl	%edx, -120(%ebp)
	movw	%ax, -40(%ebp)
	leal	-76(%ebp), %eax
	movl	%eax, 4(%esp)
	movw	$17152, -48(%ebp)
	movw	$0, -56(%ebp)
	call	___dpmi_int
	testb	$1, -44(%ebp)
	movl	-120(%ebp), %edx
	jne	L28
	testb	$16, -52(%ebp)
	jne	L98
L28:
	movl	-104(%ebp), %esi
	movb	5(%esi), %al
	testb	%al, %al
	je	L98
	movl	-100(%ebp), %ebx
L29:
	movl	__go32_info_block+12, %ecx
	movl	12(%ebp), %esi
	addl	%ecx, %esi
	movl	%ecx, -108(%ebp)
	movl	%esi, -92(%ebp)
	jmp	L4
	.p2align 4,,7
L102:
	leal	2(%ebx), %esi
	movl	%esi, -104(%ebp)
	jmp	L3
	.p2align 4,,7
L104:
/APP
# 218 "c:/djgpp/include/libc/farptrgs.h" 1
	.byte 0x65
	movb (%eax),%al
# 0 "" 2
/NO_APP
	cmpb	$58, %al
	je	L35
	movl	%ecx, %edx
	jmp	L35
	.p2align 4,,7
L41:
	movb	$99, %al
	movl	$LC1, %ebx
	jmp	L5
L105:
	movb	6(%esi), %al
	cmpb	$92, %al
	je	L7
	cmpb	$47, %al
	je	L7
	testb	%al, %al
	jne	L6
L7:
/APP
# 188 "c:/djgpp/include/libc/farptrgs.h" 1
	.byte 0x65
	movb %cl,(%edx)
# 0 "" 2
/NO_APP
	leal	2(%edx), %ecx
	leal	1(%edx), %ebx
/APP
# 188 "c:/djgpp/include/libc/farptrgs.h" 1
	.byte 0x65
	movb $58,(%ebx)
# 0 "" 2
/NO_APP
	movl	-96(%ebp), %esi
	movl	-104(%ebp), %ebx
	subl	$2, %esi
	movl	%edx, -92(%ebp)
	addl	$6, %ebx
	movl	%esi, -96(%ebp)
	movl	%ecx, %edx
	jmp	L4
L98:
	movb	(%ebx), %al
	jmp	L29
L106:
	cmpb	$47, %al
	jne	L8
	jmp	L52
L107:
	addl	$9, %esi
	movl	%edx, -120(%ebp)
	movl	%esi, (%esp)
	movb	%cl, -116(%ebp)
	call	_strlen
	movb	-116(%ebp), %cl
	addl	$31, %eax
	movl	-120(%ebp), %edx
	andl	$-16, %eax
	subl	%eax, %esp
	leal	23(%esp), %ebx
	andl	$-16, %ebx
	cmpb	$47, %cl
	movl	%ebx, %eax
	je	L10
	cmpb	$92, %cl
	je	L10
	movl	%edx, %edi
	jmp	L13
	.p2align 4,,7
L108:
	movb	(%esi), %dl
	movl	%esi, %ecx
L12:
	movb	%dl, (%eax)
	leal	1(%ecx), %esi
	movb	1(%ecx), %cl
	incl	%eax
	cmpb	$47, %cl
	je	L93
	testb	%cl, %cl
	je	L93
	cmpb	$92, %cl
	je	L93
L13:
	cmpb	$126, %cl
	jne	L108
	cmpb	$126, 1(%esi)
	jne	L93
	leal	1(%esi), %ecx
	movb	$126, %dl
	jmp	L12
L93:
	movl	%edi, %edx
L10:
	movb	$0, (%eax)
	movl	%ebx, (%esp)
	movl	%edx, -120(%ebp)
	call	_getenv
	movl	-120(%ebp), %edx
	testl	%eax, %eax
	je	L46
	cmpb	$0, (%eax)
	je	L46
/APP
# 25 "putpath.c" 1
	movl %esp,%ecx

# 0 "" 2
/NO_APP
	movl	___djgpp_stack_limit, %edi
	subl	%edi, %ecx
	cmpl	$4096, %ecx
	jg	L15
L99:
	movl	$25, _errno
	jmp	L89
L46:
	movl	$1, %edi
L14:
	movb	(%esi), %al
	cmpb	$126, %al
	je	L109
L17:
	cmpb	$92, %al
	je	L24
	cmpb	$47, %al
	je	L24
	movl	__go32_info_block+12, %ecx
	movl	%esi, %ebx
	movl	%ecx, -108(%ebp)
	movl	12(%ebp), %ecx
	movl	-108(%ebp), %edi
	addl	%edi, %ecx
	movl	%ecx, -92(%ebp)
	jmp	L4
L24:
	movl	__go32_info_block+12, %ecx
	leal	-1(%edx), %edi
	movl	%ecx, -108(%ebp)
	movl	12(%ebp), %ecx
	movl	-108(%ebp), %ebx
	addl	%ebx, %ecx
	movl	%esi, %ebx
	movl	%ecx, -92(%ebp)
	cmpl	%ecx, %edi
	jb	L4
/APP
# 218 "c:/djgpp/include/libc/farptrgs.h" 1
	.byte 0x65
	movb (%edi),%cl
# 0 "" 2
/NO_APP
	andl	$255, %ecx
	cmpl	$47, %ecx
	je	L25
	cmpl	$92, %ecx
	jne	L4
L25:
	movl	%edi, %edx
	movl	%esi, %ebx
	jmp	L4
L109:
	movb	1(%esi), %cl
	leal	1(%esi), %eax
	movb	%cl, -104(%ebp)
	testb	%cl, %cl
	movl	%eax, %esi
	movl	%ebx, %ecx
	je	L18
	movl	%edx, -92(%ebp)
	jmp	L21
	.p2align 4,,7
L19:
	testl	%edi, %edi
	je	L20
	movb	(%eax), %dl
	movb	%dl, (%ecx)
	incl	%ecx
L20:
	leal	1(%eax), %esi
	movb	1(%eax), %al
	movb	%al, -104(%ebp)
	testb	%al, %al
	je	L94
L21:
	movl	%esi, %eax
	cmpb	$126, -104(%ebp)
	jne	L19
	cmpb	$126, 1(%esi)
	jne	L94
	incl	%eax
	jmp	L19
L101:
	movl	$11, _errno
	call	_abort
L15:
	movl	12(%ebp), %ecx
	movl	%eax, (%esp)
	movl	%ecx, 4(%esp)
	movl	%edx, -120(%ebp)
	call	__put_path2
	movl	12(%ebp), %ecx
	subl	%eax, %ecx
	movl	-96(%ebp), %edx
	addl	%ecx, %edx
	movl	12(%ebp), %ecx
	movl	%edx, -96(%ebp)
	subl	%ecx, %eax
	movl	-120(%ebp), %edx
	xorl	%edi, %edi
	addl	%eax, %edx
	jmp	L14
L94:
	movl	-92(%ebp), %edx
L18:
	testl	%edi, %edi
	je	L22
	movb	$0, (%ecx)
/APP
# 25 "putpath.c" 1
	movl %esp,%eax

# 0 "" 2
/NO_APP
	movl	___djgpp_stack_limit, %edi
	subl	%edi, %eax
	cmpl	$4096, %eax
	jle	L99
	movl	12(%ebp), %eax
	movl	%ebx, (%esp)
	movl	%eax, 4(%esp)
	movl	%edx, -120(%ebp)
	call	__put_path2
	movl	12(%ebp), %ecx
	subl	%eax, %ecx
	movl	-96(%ebp), %edx
	addl	%ecx, %edx
	movl	12(%ebp), %ecx
	movl	%edx, -96(%ebp)
	subl	%ecx, %eax
	movl	-120(%ebp), %edx
	addl	%eax, %edx
L22:
	movb	(%esi), %al
	cmpb	$126, %al
	jne	L17
	movb	1(%esi), %al
	incl	%esi
	jmp	L17
	.cfi_endproc
LFE19:
	.p2align 4,,15
	.globl	__put_path
__put_path:
LFB18:
	.cfi_startproc
	subl	$28, %esp
	.cfi_def_cfa_offset 32
	movl	32(%esp), %eax
	movl	$0, 4(%esp)
	movl	%eax, (%esp)
	call	__put_path2
	addl	$28, %esp
	.cfi_def_cfa_offset 4
	ret
	.cfi_endproc
LFE18:
	.ident	"GCC: (GNU) 4.7.4"
