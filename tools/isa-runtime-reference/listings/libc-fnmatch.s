	.file	"fnmatch.c"
	.section .text
LC0:
	.ascii "*?[\\\0"
	.p2align 4,,15
	.globl	___fnmatch
___fnmatch:
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
	subl	$60, %esp
	.cfi_def_cfa_offset 80
	movl	80(%esp), %esi
	movl	88(%esp), %ebx
	andl	$1, %ebx
	movl	88(%esp), %edx
	andl	$2, %edx
	movl	88(%esp), %ecx
	movl	%ebx, 40(%esp)
	movb	(%esi), %bl
	andl	$8, %ecx
	movl	84(%esp), %ebp
	movl	%edx, 32(%esp)
	leal	1(%esi), %edi
	cmpb	$63, %bl
	je	L6
	.p2align 4,,7
L142:
	jg	L9
	testb	%bl, %bl
	je	L4
	cmpb	$42, %bl
	je	L141
L3:
	cmpb	$47, %bl
	je	L40
	cmpb	$92, %bl
	je	L40
	movb	0(%ebp), %al
L44:
	incl	%ebp
	testl	%ecx, %ecx
	je	L46
	andl	$255, %eax
	andl	$255, %ebx
	movb	___dj_ctype_toupper+1(%eax), %dl
	cmpb	%dl, ___dj_ctype_toupper+1(%ebx)
	jne	L65
L11:
	movl	%edi, %esi
L144:
	movb	(%esi), %bl
	leal	1(%esi), %edi
	cmpb	$63, %bl
	jne	L142
L6:
	movb	0(%ebp), %al
	incl	%ebp
	testb	%al, %al
	je	L65
	cmpb	$47, %al
	jne	L143
L66:
	movl	32(%esp), %eax
	testl	%eax, %eax
	je	L11
	.p2align 4,,7
L65:
	movl	$1, %eax
L10:
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
L9:
	.cfi_restore_state
	cmpb	$91, %bl
	je	L7
	cmpb	$92, %bl
	jne	L3
	movl	40(%esp), %eax
	testl	%eax, %eax
	jne	L40
	movsbl	2(%esi), %eax
	testb	%al, %al
	je	L40
	movl	%eax, 4(%esp)
	movl	$LC0, (%esp)
	movl	%ecx, 20(%esp)
	call	_strchr
	movl	20(%esp), %ecx
	testl	%eax, %eax
	je	L40
	movb	1(%esi), %al
	testb	%al, %al
	je	L41
	leal	2(%esi), %edi
	movb	%al, %bl
L41:
	movb	0(%ebp), %al
	incl	%ebp
	cmpb	%al, %bl
	jne	L65
	movl	%edi, %esi
	jmp	L144
	.p2align 4,,7
L40:
	movb	0(%ebp), %al
	cmpb	$47, %al
	jne	L145
	incl	%ebp
L152:
	movl	%edi, %esi
	jmp	L144
	.p2align 4,,7
L141:
	movb	1(%esi), %al
	cmpb	$42, %al
	jne	L13
	.p2align 4,,7
L105:
	incl	%edi
	movb	(%edi), %al
	cmpb	$42, %al
	je	L105
L13:
	testb	%al, %al
	je	L146
	cmpb	$47, %al
	jne	L147
L21:
	movl	32(%esp), %eax
	testl	%eax, %eax
	je	L23
	movb	0(%ebp), %al
	testb	%al, %al
	jne	L27
	jmp	L65
	.p2align 4,,7
L148:
	cmpb	$92, %al
	je	L11
	incl	%ebp
	movb	0(%ebp), %al
	testb	%al, %al
	je	L65
L27:
	cmpb	$47, %al
	jne	L148
	movl	%edi, %esi
	jmp	L144
	.p2align 4,,7
L4:
	cmpb	$0, 0(%ebp)
	setne	%al
	addl	$60, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 20
	andl	$255, %eax
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
L7:
	.cfi_restore_state
	movb	0(%ebp), %dl
	testb	%dl, %dl
	je	L65
	cmpb	$47, %dl
	jne	L149
L69:
	movl	32(%esp), %ebx
	testl	%ebx, %ebx
	jne	L65
L31:
	movb	1(%esi), %al
	cmpb	$33, %al
	sete	%bl
	andl	$255, %ebx
	movl	%ebx, 36(%esp)
	testl	%ebx, %ebx
	jne	L150
L33:
	xorl	%ebx, %ebx
	movl	%ebp, 44(%esp)
	movb	%dl, %bl
	movl	$0, 24(%esp)
	movl	%ebx, 28(%esp)
	movl	%ecx, %ebp
	jmp	L34
	.p2align 4,,7
L35:
	cmpb	%al, %dl
	je	L61
	testl	%ebp, %ebp
	je	L38
	movl	28(%esp), %ebx
	andl	$255, %eax
	movb	___dj_ctype_toupper+1(%ebx), %bl
	cmpb	%bl, ___dj_ctype_toupper+1(%eax)
	je	L61
L38:
	movb	%cl, %al
	movl	%esi, %edi
L34:
	leal	1(%edi), %esi
	cmpb	$93, %al
	je	L151
	testb	%al, %al
	je	L65
	movb	1(%edi), %cl
	cmpb	$45, %cl
	jne	L35
	movb	2(%edi), %bl
	testb	%bl, %bl
	je	L35
	cmpb	$93, %bl
	je	L35
	cmpb	%bl, %dl
	jg	L36
	cmpb	%al, %dl
	jl	L36
	movl	$1, 24(%esp)
L36:
	testl	%ebp, %ebp
	je	L37
	movl	28(%esp), %esi
	andl	$255, %eax
	movb	___dj_ctype_toupper+1(%esi), %cl
	cmpb	%cl, ___dj_ctype_toupper+1(%eax)
	ja	L37
	andl	$255, %ebx
	cmpb	___dj_ctype_toupper+1(%ebx), %cl
	ja	L37
	movl	$1, 24(%esp)
	.p2align 4,,7
L37:
	leal	3(%edi), %esi
	movb	3(%edi), %cl
	jmp	L38
	.p2align 4,,7
L61:
	movl	$1, 24(%esp)
	jmp	L38
	.p2align 4,,7
L46:
	cmpb	%al, %bl
	jne	L65
	movl	%edi, %esi
	jmp	L144
	.p2align 4,,7
L143:
	cmpb	$92, %al
	je	L66
	movl	%edi, %esi
	jmp	L144
	.p2align 4,,7
L150:
	leal	2(%esi), %edi
	movb	2(%esi), %al
	jmp	L33
	.p2align 4,,7
L145:
	cmpb	$92, %al
	jne	L44
	incl	%ebp
	jmp	L152
	.p2align 4,,7
L151:
	movl	24(%esp), %eax
	movl	%ebp, %ecx
	cmpl	%eax, 36(%esp)
	movl	44(%esp), %ebp
	je	L65
	testl	%esi, %esi
	je	L65
	movl	%esi, %edi
	incl	%ebp
	movl	%edi, %esi
	jmp	L144
	.p2align 4,,7
L149:
	cmpb	$92, %dl
	je	L69
	jmp	L31
L147:
	cmpb	$92, %al
	je	L21
L23:
	movb	0(%ebp), %bl
	movl	88(%esp), %esi
	andl	$2, %esi
	testb	%bl, %bl
	je	L65
	movl	%esi, 24(%esp)
	movl	88(%esp), %esi
	jmp	L104
	.p2align 4,,7
L153:
	cmpb	$47, %bl
	je	L68
	cmpb	$92, %bl
	jne	L28
L68:
	movl	24(%esp), %eax
	testl	%eax, %eax
	jne	L65
L28:
	incl	%ebp
	movb	0(%ebp), %bl
	testb	%bl, %bl
	je	L65
L104:
	movl	%esi, 8(%esp)
	movl	%ebp, 4(%esp)
	movl	%edi, (%esp)
	call	___fnmatch
	testl	%eax, %eax
	jne	L153
	xorl	%eax, %eax
	jmp	L10
L146:
	xorl	%eax, %eax
	testb	$2, 88(%esp)
	je	L10
	movb	0(%ebp), %dl
	testb	%dl, %dl
	je	L10
	cmpb	$47, %dl
	je	L65
	cmpb	$92, %dl
	jne	L103
	jmp	L65
	.p2align 4,,7
L20:
	cmpb	$47, %al
	je	L67
	cmpb	$92, %al
	je	L67
L103:
	incl	%ebp
	movb	0(%ebp), %al
	testb	%al, %al
	jne	L20
	xorl	%eax, %eax
	jmp	L10
L67:
	testl	%ebp, %ebp
	setne	%al
	andl	$255, %eax
	jmp	L10
	.cfi_endproc
LFE2:
	.ident	"GCC: (GNU) 4.7.4"
