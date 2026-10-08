	.file	"fixpath.c"
	.section .text
	.p2align 4,,15
	.globl	___canonicalize_path
___canonicalize_path:
LFB12:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%edi
	pushl	%esi
	pushl	%ebx
	subl	$684, %esp
	.cfi_offset 7, -12
	.cfi_offset 6, -16
	.cfi_offset 3, -20
	movl	8(%ebp), %ebx
	call	__preserve_fncase
	movl	_errno, %esi
	movb	%al, -665(%ebp)
	movl	%ebx, (%esp)
	call	__use_lfn
	movl	16(%ebp), %edx
	movsbl	%al, %eax
	movl	%eax, _use_lfn
	movl	%esi, _errno
	movl	%edx, -664(%ebp)
	cmpl	$260, %edx
	jbe	L2
	movl	$260, -664(%ebp)
L2:
	movl	12(%ebp), %ecx
	movl	-664(%ebp), %esi
	addl	%esi, %ecx
	movl	%ecx, -660(%ebp)
	movl	%ebx, (%esp)
	leal	-544(%ebp), %ebx
	call	__put_path
	movl	%ebx, 8(%esp)
	movl	$260, 4(%esp)
	movl	__go32_info_block+12, %eax
	movl	%eax, (%esp)
	call	___dosmemget
	movb	-544(%ebp), %al
	movb	%al, %dl
	andl	$-33, %edx
	subl	$65, %edx
	cmpb	$25, %dl
	ja	L3
	cmpb	$58, -543(%ebp)
	je	L93
L3:
	leal	-648(%ebp), %eax
	movb	$25, -619(%ebp)
	movl	%eax, 4(%esp)
	movl	$33, (%esp)
	call	___dpmi_int
	movb	-620(%ebp), %dl
	xorl	%ecx, %ecx
	movb	%dl, %cl
	cmpl	$25, %ecx
	movl	%ecx, -656(%ebp)
	setle	%al
	decl	%eax
	andl	$-32, %eax
	leal	97(%edx,%eax), %eax
	movl	12(%ebp), %edx
	movl	%edx, %esi
	movb	%al, (%edx)
	movb	$58, 1(%edx)
	addl	$2, %esi
L7:
	movb	(%ebx), %al
	movsbl	%al, %edx
	cmpl	$92, %edx
	jne	L94
L73:
	movl	12(%ebp), %edi
	addl	$2, %edi
	.p2align 4,,7
L82:
	testb	%al, %al
	je	L95
L36:
	movsbl	%al, %edx
	cmpl	$92, %edx
	je	L63
	cmpl	$47, %edx
	jne	L21
L63:
	movb	1(%ebx), %al
	incl	%ebx
	testb	%al, %al
	jne	L36
L95:
	movl	12(%ebp), %ebx
	addl	$2, %ebx
	cmpl	%ebx, %esi
	je	L96
L37:
	cmpl	-660(%ebp), %esi
	jae	L91
	movl	-664(%ebp), %edx
	movl	12(%ebp), %eax
	addl	$15, %edx
	movb	$0, (%esi)
	andl	$-16, %edx
	movl	12(%ebp), %esi
	addl	$3, %esi
	movl	%edx, -660(%ebp)
	cmpb	$0, 2(%eax)
	je	L85
	movl	%esi, %edi
	jmp	L74
	.p2align 4,,7
L40:
	movb	(%edi), %al
	cmpb	$92, %al
	je	L97
	cmpb	$0, -665(%ebp)
	jne	L45
L43:
	testb	%al, %al
	je	L64
	cmpb	$47, %al
	je	L64
L44:
	movl	-656(%ebp), %esp
L41:
	incl	%edi
	cmpb	$0, (%ebx)
	je	L85
L74:
	movl	-660(%ebp), %eax
	movl	%esp, -656(%ebp)
	subl	%eax, %esp
	movl	___dj_mb_cur_max, %eax
	movl	%eax, 4(%esp)
	movl	%edi, (%esp)
	call	_mblen
	leal	12(%esp), %esi
	cmpl	$1, %eax
	jle	L40
	leal	-1(%edi,%eax), %edi
	movl	-656(%ebp), %esp
	jmp	L41
	.p2align 4,,7
L21:
	cmpb	$46, %al
	je	L98
L24:
	cmpl	-660(%ebp), %esi
	jae	L91
	movb	$47, (%esi)
	incl	%esi
	.p2align 4,,7
L32:
	movb	(%ebx), %al
	movsbl	%al, %edx
	cmpl	$92, %edx
	je	L82
	cmpl	$47, %edx
	je	L82
	testl	%edx, %edx
	je	L82
	movl	___dj_mb_cur_max, %eax
	movl	%ebx, (%esp)
	movl	%eax, 4(%esp)
	call	_mblen
	cmpl	$1, %eax
	jle	L56
	xorl	%edx, %edx
	.p2align 4,,7
L33:
	movb	(%ebx,%edx), %cl
	movb	%cl, (%esi,%edx)
	incl	%edx
	cmpl	%eax, %edx
	jne	L33
	addl	%edx, %esi
	addl	%edx, %ebx
L34:
	cmpl	-660(%ebp), %esi
	jb	L32
L91:
	movl	$19, _errno
	movl	$0, 12(%ebp)
L85:
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
L56:
	.cfi_restore_state
	movb	(%ebx), %al
	incl	%ebx
	movb	%al, (%esi)
	incl	%esi
	jmp	L34
L98:
	movb	1(%ebx), %al
	movsbl	%al, %edx
	cmpl	$92, %edx
	je	L25
	cmpl	$47, %edx
	jne	L99
L25:
	incl	%ebx
	jmp	L82
L99:
	testl	%edx, %edx
	je	L25
	cmpb	$46, %al
	jne	L24
	movb	2(%ebx), %al
	movsbl	%al, %edx
	cmpl	$92, %edx
	je	L27
	cmpl	$47, %edx
	jne	L100
L27:
	movl	12(%ebp), %edx
	leal	2(%ebx), %ecx
	cmpb	$46, 2(%edx)
	je	L101
L28:
	movl	%ecx, %ebx
	cmpl	%edi, %esi
	jbe	L82
L84:
	decl	%esi
	movsbl	(%esi), %edx
	cmpl	$92, %edx
	je	L59
	cmpl	$47, %edx
	jne	L84
L59:
	movl	%ecx, %ebx
	jmp	L82
	.p2align 4,,7
L94:
	cmpl	$47, %edx
	je	L73
	leal	-596(%ebp), %ecx
	xorl	%eax, %eax
	movl	%ecx, -652(%ebp)
	movl	$13, %ecx
	movl	-652(%ebp), %edi
	rep stosl
	movl	_use_lfn, %ecx
	movw	$1, -564(%ebp)
	testl	%ecx, %ecx
	jne	L102
	movb	$71, -567(%ebp)
L11:
	movb	-656(%ebp), %al
	movb	%al, -666(%ebp)
	leal	1(%eax), %edi
	movl	%edi, %eax
	movl	%ebx, %edi
	movb	%al, %bl
	jmp	L13
	.p2align 4,,7
L103:
	movl	$0, _use_lfn
	movb	$71, -567(%ebp)
L13:
	movl	__go32_info_block+12, %eax
	leal	-596(%ebp), %edx
	shrl	$4, %eax
	movb	%bl, -576(%ebp)
	movw	$0, -592(%ebp)
	movw	%ax, -560(%ebp)
	movl	%edx, 4(%esp)
	movl	$33, (%esp)
	call	___dpmi_int
	cmpw	$28928, -568(%ebp)
	je	L103
	movl	%edi, %ebx
	testb	$1, -564(%ebp)
	je	L14
	movb	$46, (%esi)
	incl	%esi
L15:
	movb	(%ebx), %al
	jmp	L73
L93:
	leal	-97(%eax), %edx
	cmpb	$25, %dl
	movsbl	%al, %edx
	jbe	L104
	subl	$65, %edx
	cmpb	$90, %al
	movl	%edx, -656(%ebp)
	jg	L6
	movl	12(%ebp), %ecx
	movb	-656(%ebp), %al
	addl	$97, %eax
	movl	%ecx, %esi
	movb	%al, (%ecx)
	incl	%esi
L5:
	movb	$58, (%esi)
	leal	-542(%ebp), %ebx
	incl	%esi
	jmp	L7
L102:
	movw	$28999, -568(%ebp)
	jmp	L11
L104:
	subl	$97, %edx
	movl	%edx, -656(%ebp)
	movl	12(%ebp), %edx
	movl	%edx, %esi
	movb	%al, (%edx)
	incl	%esi
	jmp	L5
L100:
	testl	%edx, %edx
	je	L27
	jmp	L24
	.p2align 4,,7
L45:
	testb	%al, %al
	jne	L44
	movl	-656(%ebp), %esp
	jmp	L85
L97:
	movb	$47, (%edi)
	cmpb	$0, -665(%ebp)
	jne	L44
	movb	$47, %al
	jmp	L43
L14:
	leal	-284(%ebp), %edi
	movl	$260, 4(%esp)
	movl	%edi, 8(%esp)
	movl	__go32_info_block+12, %eax
	movl	%eax, (%esp)
	call	___dosmemget
	leal	1(%esi), %ecx
	movl	%edi, 4(%esp)
	movl	%ecx, -672(%ebp)
	movl	%ecx, (%esp)
	call	_strcpy
	cmpb	$0, 1(%esi)
	jne	L105
	cmpw	$1330, __os_trueversion
	jne	L15
	movl	_use_lfn, %edx
	testl	%edx, %edx
	je	L15
	movl	__go32_info_block+12, %eax
	movw	$29024, -568(%ebp)
	shrl	$4, %eax
	movw	$-32766, -572(%ebp)
	movw	%ax, -562(%ebp)
	movb	-666(%ebp), %al
	addl	$65, %eax
	movw	$260, -596(%ebp)
	movb	%al, -284(%ebp)
	movb	$58, -283(%ebp)
	movb	$46, -282(%ebp)
	movb	$0, -281(%ebp)
	movl	%edi, (%esp)
	call	__put_path
	leal	-596(%ebp), %eax
	movl	%eax, 4(%esp)
	movl	$33, (%esp)
	call	___dpmi_int
	testb	$1, -564(%ebp)
	je	L106
L17:
	movb	$46, (%esi)
	movl	-672(%ebp), %esi
	movb	(%ebx), %al
	jmp	L73
	.p2align 4,,7
L64:
	movl	%edi, %ecx
	leal	1(%ebx), %eax
	subl	%ebx, %ecx
	movl	%eax, 4(%esp)
	decl	%ecx
	movl	%esi, (%esp)
	movl	%ecx, 8(%esp)
	movl	%ecx, -676(%ebp)
	call	_memcpy
	movl	-676(%ebp), %ecx
	movb	$0, (%esi,%ecx)
	movl	%esi, (%esp)
	call	__is_DOS83
	testl	%eax, %eax
	jne	L62
	movl	%edi, %ebx
	jmp	L44
L62:
	movl	%ebx, %esi
L86:
	leal	1(%esi), %ebx
	cmpl	%ebx, %edi
	jbe	L44
L50:
	movl	___dj_mb_cur_max, %eax
	movl	%ebx, (%esp)
	movl	%eax, 4(%esp)
	call	_mblen
	cmpl	$1, %eax
	jle	L48
	leal	-1(%ebx,%eax), %esi
	leal	1(%esi), %ebx
	cmpl	%ebx, %edi
	ja	L50
	jmp	L44
L48:
	movb	1(%esi), %al
	leal	-65(%eax), %edx
	cmpb	$25, %dl
	ja	L62
	addl	$32, %eax
	movb	%al, 1(%esi)
	movl	%ebx, %esi
	jmp	L86
L6:
	movl	12(%ebp), %edx
	movl	%edx, %esi
	movb	%al, (%edx)
	incl	%esi
	jmp	L5
L105:
	movb	$47, (%esi)
	movl	%esi, (%esp)
	call	_strlen
	addl	%eax, %esi
	movb	(%ebx), %al
	jmp	L73
L101:
	cmpb	$46, -1(%esi)
	jne	L28
	movb	$47, (%esi)
	movb	$46, 1(%esi)
	movb	$46, 2(%esi)
	addl	$3, %esi
	movb	2(%ebx), %al
	movl	%ecx, %ebx
	jmp	L82
L96:
	movl	12(%ebp), %eax
	movl	%eax, %esi
	movb	$47, 2(%eax)
	addl	$3, %esi
	jmp	L37
L106:
	movl	%edi, 8(%esp)
	movl	$260, 4(%esp)
	movl	__go32_info_block+12, %eax
	addl	$260, %eax
	movl	%eax, (%esp)
	call	___dosmemget
	movl	-656(%ebp), %edx
	movsbl	-284(%ebp), %eax
	addl	$65, %edx
	cmpl	%edx, %eax
	je	L18
	movl	-656(%ebp), %edx
	addl	$97, %edx
	cmpl	%edx, %eax
	jne	L17
L18:
	cmpb	$58, -283(%ebp)
	jne	L17
	cmpb	$92, -282(%ebp)
	jne	L19
	cmpb	$0, -281(%ebp)
	je	L15
L19:
	leal	-282(%ebp), %eax
	movl	%esi, (%esp)
	movl	%eax, 4(%esp)
	call	_stpcpy
	movl	%eax, %esi
	movb	(%ebx), %al
	jmp	L73
	.cfi_endproc
LFE12:
	.p2align 4,,15
	.globl	__fixpath
__fixpath:
LFB13:
	.cfi_startproc
	subl	$28, %esp
	.cfi_def_cfa_offset 32
	movl	36(%esp), %eax
	movl	$260, 8(%esp)
	movl	%eax, 4(%esp)
	movl	32(%esp), %eax
	movl	%eax, (%esp)
	call	___canonicalize_path
	addl	$28, %esp
	.cfi_def_cfa_offset 4
	ret
	.cfi_endproc
LFE13:
.lcomm _use_lfn,4,4
	.ident	"GCC: (GNU) 4.7.4"
