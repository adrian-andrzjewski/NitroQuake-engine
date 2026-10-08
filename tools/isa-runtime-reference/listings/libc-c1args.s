	.file	"c1args.c"
	.section .text
	.p2align 4,,15
_count_args:
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
	subl	$12, %esp
	.cfi_def_cfa_offset 32
	movl	(%eax), %edi
	testl	%edi, %edi
	jle	L9
	movl	4(%eax), %ebp
	xorl	%esi, %esi
	xorl	%ebx, %ebx
	.p2align 4,,7
L8:
	movl	0(%ebp,%ebx,4), %eax
	movl	4(%eax), %ecx
	testl	%ecx, %ecx
	je	L3
	movl	(%ecx), %eax
	xorl	%edx, %edx
	testl	%eax, %eax
	je	L4
	.p2align 4,,7
L5:
	incl	%edx
	movl	(%ecx,%edx,4), %eax
	testl	%eax, %eax
	jne	L5
L4:
	addl	%edx, %esi
L6:
	incl	%ebx
	cmpl	%edi, %ebx
	jne	L8
L2:
	addl	$12, %esp
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
	.p2align 4,,7
L3:
	.cfi_restore_state
	movl	8(%eax), %eax
	testl	%eax, %eax
	je	L7
	call	_count_args
	addl	%eax, %esi
	jmp	L6
L7:
	incl	%esi
	jmp	L6
L9:
	xorl	%esi, %esi
	jmp	L2
	.cfi_endproc
LFE27:
	.p2align 4,,15
_fill_args:
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
	subl	$12, %esp
	.cfi_def_cfa_offset 32
	movl	%edx, %edi
	movl	(%edx), %edx
	testl	%edx, %edx
	jle	L16
	xorl	%ebp, %ebp
	.p2align 4,,7
L21:
	movl	4(%edi), %ecx
	leal	0(,%ebp,4), %edx
	movl	(%ecx,%edx), %ebx
	movl	4(%ebx), %ecx
	testl	%ecx, %ecx
	je	L17
	movl	(%ecx), %ebx
	testl	%ebx, %ebx
	je	L18
	movl	%eax, %ecx
	xorl	%esi, %esi
	.p2align 4,,7
L19:
	movl	%ebx, (%ecx)
	addl	$4, %ecx
	movl	4(%edi), %ebx
	movl	(%ebx,%edx), %ebx
	movl	4(%ebx), %ebx
	movl	$0, (%ebx,%esi)
	movl	%ecx, %esi
	movl	4(%edi), %ebx
	subl	%eax, %esi
	movl	(%ebx,%edx), %ebx
	movl	4(%ebx), %ebx
	movl	(%ebx,%esi), %ebx
	testl	%ebx, %ebx
	jne	L19
	movl	%ecx, %eax
L18:
	incl	%ebp
	cmpl	%ebp, (%edi)
	jg	L21
L16:
	addl	$12, %esp
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
	movl	8(%ebx), %ecx
	testl	%ecx, %ecx
	je	L20
	movl	%ecx, %edx
	call	_fill_args
	jmp	L18
L20:
	movl	(%ebx), %ecx
	movl	%ecx, (%eax)
	addl	$4, %eax
	movl	4(%edi), %ecx
	movl	(%ecx,%edx), %edx
	movl	$0, (%edx)
	jmp	L18
	.cfi_endproc
LFE28:
	.p2align 4,,15
_delete_arglist:
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
	subl	$28, %esp
	.cfi_def_cfa_offset 48
	movl	%eax, %edi
	movl	(%eax), %eax
	xorl	%esi, %esi
	testl	%eax, %eax
	jle	L35
	.p2align 4,,7
L45:
	movl	4(%edi), %eax
	movl	(%eax,%esi,4), %ebx
	movl	(%ebx), %eax
	testl	%eax, %eax
	je	L30
	movl	%eax, (%esp)
	call	_free
L30:
	movl	4(%ebx), %eax
	testl	%eax, %eax
	je	L31
	movl	(%eax), %edx
	testl	%edx, %edx
	je	L32
	movl	$4, %ebp
	.p2align 4,,7
L33:
	movl	%edx, (%esp)
	call	_free
	movl	4(%ebx), %eax
	movl	(%eax,%ebp), %edx
	addl	$4, %ebp
	testl	%edx, %edx
	jne	L33
L32:
	movl	%eax, (%esp)
	call	_free
L31:
	movl	8(%ebx), %eax
	testl	%eax, %eax
	je	L34
	call	_delete_arglist
L34:
	movl	%ebx, (%esp)
	incl	%esi
	call	_free
	cmpl	%esi, (%edi)
	jg	L45
L35:
	movl	4(%edi), %eax
	movl	%eax, (%esp)
	call	_free
	movl	%edi, (%esp)
	call	_free
	addl	$28, %esp
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
LFE23:
LC0:
	.ascii "'\"\0"
LC1:
	.ascii "[?*\0"
LC2:
	.ascii "...\0"
	.p2align 4,,15
_parse_arg:
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
	subl	$60, %esp
	.cfi_def_cfa_offset 80
	movl	%eax, %ebx
	xorl	%ebp, %ebp
	movl	%eax, 36(%esp)
	movl	%eax, 28(%esp)
	movl	%edx, %eax
	movl	%edx, 44(%esp)
	decl	%eax
	movl	%ecx, 32(%esp)
	movl	%eax, 40(%esp)
	.p2align 4,,7
L84:
	testl	%ebp, %ebp
	je	L85
L64:
	cmpl	44(%esp), %ebx
	jae	L67
	movb	(%ebx), %dl
	movsbl	%dl, %eax
	cmpl	%ebp, %eax
	je	L88
L56:
	cmpb	$92, %dl
	je	L89
L60:
	testl	%ebp, %ebp
	je	L62
	movsbl	%dl, %eax
	movl	%eax, 4(%esp)
	movl	$LC1, (%esp)
	movb	%dl, 20(%esp)
	call	_strchr
	movb	20(%esp), %dl
	testl	%eax, %eax
	je	L90
L63:
	movl	32(%esp), %ecx
	testl	%ecx, %ecx
	je	L62
	movl	84(%esp), %eax
	movl	$1, (%eax)
	movb	(%ebx), %dl
L62:
	movl	28(%esp), %eax
	incl	%ebx
	movb	%dl, (%eax)
	incl	%eax
	movl	%eax, 28(%esp)
	testl	%ebp, %ebp
	jne	L64
L85:
	xorl	%eax, %eax
	movb	(%ebx), %al
	testb	$1, ___dj_ctype_flags+3(%eax,%eax)
	jne	L67
L91:
	cmpl	44(%esp), %ebx
	jae	L67
	movb	(%ebx), %dl
	cmpb	$34, %dl
	je	L69
	cmpb	$39, %dl
	jne	L56
L69:
	movl	32(%esp), %edi
	incl	%ebx
	movsbl	%dl, %ebp
	testl	%edi, %edi
	jne	L84
	movl	28(%esp), %eax
	movb	%dl, (%eax)
	incl	%eax
	movl	%eax, 28(%esp)
	jmp	L84
	.p2align 4,,7
L89:
	movb	1(%ebx), %cl
	movl	$LC0, (%esp)
	movsbl	%cl, %eax
	movl	%eax, 4(%esp)
	movb	%dl, 20(%esp)
	movb	%cl, 24(%esp)
	call	_strchr
	movb	20(%esp), %dl
	testl	%eax, %eax
	movb	24(%esp), %cl
	je	L60
	cmpl	40(%esp), %ebx
	jae	L60
	movl	32(%esp), %esi
	testl	%esi, %esi
	jne	L61
	movl	28(%esp), %eax
	movb	$92, (%eax)
	incl	%eax
	movl	%eax, 28(%esp)
	movb	1(%ebx), %cl
L61:
	movl	28(%esp), %eax
	addl	$2, %ebx
	movb	%cl, (%eax)
	incl	%eax
	movl	%eax, 28(%esp)
	jmp	L84
	.p2align 4,,7
L88:
	movl	32(%esp), %ebp
	testl	%ebp, %ebp
	jne	L57
	movl	28(%esp), %eax
	movb	%dl, (%eax)
	incl	%eax
	movl	%eax, 28(%esp)
L57:
	incl	%ebx
	xorl	%eax, %eax
	xorl	%ebp, %ebp
	movb	(%ebx), %al
	testb	$1, ___dj_ctype_flags+3(%eax,%eax)
	je	L91
L67:
	movl	36(%esp), %eax
	movl	28(%esp), %edx
	subl	%eax, %edx
	movl	80(%esp), %eax
	movl	%edx, (%eax)
	addl	$60, %esp
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
L90:
	.cfi_restore_state
	movl	$LC2, %edi
	movl	%ebx, %esi
	movl	$3, %ecx
	repe cmpsb
	jne	L62
	jmp	L63
	.cfi_endproc
LFE24:
	.p2align 4,,15
_expand_wildcards:
LFB30:
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
	movl	%eax, %edi
	subl	$16, %esp
	.cfi_def_cfa_offset 32
	xorl	%ebx, %ebx
	movl	(%eax), %edx
	testl	%edx, %edx
	jg	L98
	jmp	L92
	.p2align 4,,7
L101:
	call	_expand_wildcards
L95:
	incl	%ebx
	cmpl	%ebx, (%edi)
	jle	L92
L98:
	movl	4(%edi), %eax
	movl	(%eax,%ebx,4), %esi
	movl	8(%esi), %eax
	testl	%eax, %eax
	jne	L101
	movl	16(%esi), %eax
	testl	%eax, %eax
	jne	L95
	movl	(%esi), %eax
	incl	%ebx
	movl	%eax, (%esp)
	call	___crt0_glob_function
	cmpl	%ebx, (%edi)
	movl	%eax, 4(%esi)
	jg	L98
	.p2align 4,,7
L92:
	addl	$16, %esp
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
LFE30:
	.p2align 2
LC3:
	.ascii "No memory to gather arguments\15\12\0"
	.p2align 4,,15
_c1xmalloc:
LFB17:
	.cfi_startproc
	subl	$28, %esp
	.cfi_def_cfa_offset 32
	movl	%eax, (%esp)
	call	_malloc
	testl	%eax, %eax
	je	L105
	addl	$28, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 4
	ret
L105:
	.cfi_restore_state
	movl	$31, 8(%esp)
	movl	$LC3, 4(%esp)
	movl	$2, (%esp)
	call	__write
	movl	$1, (%esp)
	call	__exit
	.cfi_endproc
LFE17:
	.p2align 4,,15
_new_arglist:
LFB22:
	.cfi_startproc
	pushl	%esi
	.cfi_def_cfa_offset 8
	.cfi_offset 6, -8
	pushl	%ebx
	.cfi_def_cfa_offset 12
	.cfi_offset 3, -12
	subl	$20, %esp
	.cfi_def_cfa_offset 32
	movl	%eax, %esi
	movl	$8, %eax
	call	_c1xmalloc
	movl	%eax, %ebx
	movl	%esi, (%eax)
	leal	4(,%esi,4), %esi
	movl	%esi, %eax
	call	_c1xmalloc
	movl	%eax, 4(%ebx)
	movl	%esi, 8(%esp)
	movl	$0, 4(%esp)
	movl	%eax, (%esp)
	call	_memset
	addl	$20, %esp
	.cfi_def_cfa_offset 12
	movl	%ebx, %eax
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 8
	popl	%esi
	.cfi_restore 6
	.cfi_def_cfa_offset 4
	ret
	.cfi_endproc
LFE22:
	.p2align 4,,15
_new_arg:
LFB20:
	.cfi_startproc
	subl	$12, %esp
	.cfi_def_cfa_offset 16
	movl	$20, %eax
	call	_c1xmalloc
	movl	$0, (%eax)
	movl	$0, 4(%eax)
	movl	$0, 8(%eax)
	movl	$0, 12(%eax)
	movl	$0, 16(%eax)
	addl	$12, %esp
	.cfi_def_cfa_offset 4
	ret
	.cfi_endproc
LFE20:
	.p2align 4,,15
_parse_bytes:
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
	subl	$60, %esp
	.cfi_def_cfa_offset 80
	leal	(%eax,%edx), %esi
	cmpl	%esi, %eax
	movl	%ecx, 28(%esp)
	jae	L138
	movl	%eax, %ebx
	leal	40(%esp), %ebp
	movl	$0, 20(%esp)
	.p2align 4,,7
L111:
	xorl	%eax, %eax
	movb	(%ebx), %al
	testb	$1, ___dj_ctype_flags+3(%eax,%eax)
	je	L113
	cmpl	%ebx, %esi
	ja	L126
	jmp	L113
	.p2align 4,,7
L139:
	cmpl	%esi, %ebx
	je	L115
L126:
	incl	%ebx
	xorl	%eax, %eax
	movb	(%ebx), %al
	testb	$1, ___dj_ctype_flags+3(%eax,%eax)
	jne	L139
L113:
	cmpl	%esi, %ebx
	je	L115
	call	_new_arg
	movl	%esi, %edx
	movl	%eax, 0(%ebp)
	movl	%eax, %edi
	leal	16(%eax), %eax
	movl	28(%esp), %ecx
	movl	%eax, 4(%esp)
	leal	44(%esp), %eax
	movl	%eax, (%esp)
	movl	%ebx, %eax
	call	_parse_arg
	movl	20(%esp), %ecx
	movl	%eax, 24(%esp)
	movl	44(%esp), %eax
	incl	%ecx
	incl	%eax
	movl	%ecx, 20(%esp)
	call	_c1xmalloc
	movl	44(%esp), %edx
	movl	%eax, (%edi)
	movl	%edx, 8(%esp)
	movl	%ebx, 4(%esp)
	movl	%eax, (%esp)
	leal	12(%edi), %ebp
	call	_memcpy
	movl	(%edi), %edx
	movl	44(%esp), %eax
	movl	24(%esp), %ebx
	incl	%ebx
	movb	$0, (%edx,%eax)
	cmpl	%ebx, %esi
	ja	L111
	movl	20(%esp), %eax
	call	_new_arglist
	movl	40(%esp), %ecx
L117:
	xorl	%edx, %edx
	movl	20(%esp), %esi
	.p2align 4,,7
L120:
	movl	4(%eax), %ebx
	movl	%ecx, (%ebx,%edx,4)
	incl	%edx
	movl	12(%ecx), %ecx
	cmpl	%esi, %edx
	jne	L120
L134:
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
L115:
	.cfi_restore_state
	movl	20(%esp), %eax
	call	_new_arglist
	movl	20(%esp), %edx
	movl	40(%esp), %ecx
	testl	%edx, %edx
	jne	L117
	jmp	L134
L138:
	xorl	%eax, %eax
	call	_new_arglist
	jmp	L134
	.cfi_endproc
LFE25:
	.p2align 4,,15
_expand_response_files:
LFB29:
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
	subl	$92, %esp
	.cfi_def_cfa_offset 112
	xorl	%edi, %edi
	movl	(%eax), %esi
	movl	%eax, %ebp
	testl	%esi, %esi
	jle	L140
	.p2align 4,,7
L161:
	leal	0(,%edi,4), %esi
	movl	4(%ebp), %eax
	movl	(%eax,%esi), %eax
	movl	16(%eax), %ebx
	testl	%ebx, %ebx
	jne	L143
	movl	(%eax), %eax
	cmpb	$64, (%eax)
	je	L168
L143:
	incl	%edi
	cmpl	%edi, 0(%ebp)
	jg	L161
L140:
	addl	$92, %esp
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
L168:
	.cfi_restore_state
	incl	%eax
	movl	$0, 4(%esp)
	movl	%eax, (%esp)
	call	__open
	movl	%eax, %ebx
	testl	%eax, %eax
	js	L143
	movl	$2, 8(%esp)
	movl	$0, 4(%esp)
	movl	%eax, (%esp)
	call	___lseek
	movl	$0, 8(%esp)
	movl	$0, 4(%esp)
	movl	%ebx, (%esp)
	movl	%eax, 24(%esp)
	call	___lseek
	movl	24(%esp), %ecx
	movl	%ecx, %edx
	xorl	$-1, %edx
	sarl	$31, %edx
	andl	%ecx, %edx
	movl	%edx, 24(%esp)
	leal	1(%edx), %eax
	call	_c1xmalloc
	movl	24(%esp), %edx
	movl	%edx, 8(%esp)
	movl	%eax, 4(%esp)
	movl	%ebx, (%esp)
	movl	%eax, 36(%esp)
	call	__read
	movl	%ebx, (%esp)
	testl	%eax, %eax
	js	L146
	movl	%eax, 24(%esp)
	call	__close
	movl	24(%esp), %edx
	testl	%edx, %edx
	je	L147
	movl	36(%esp), %ecx
	movb	-1(%ecx,%edx), %al
	cmpb	$26, %al
	je	L169
L148:
	testb	%al, %al
	je	L170
L149:
	movl	4(%ebp), %eax
	testb	$64, __crt0_startup_flags+1
	sete	%cl
	movl	(%eax,%esi), %ebx
	andl	$255, %ecx
	movl	36(%esp), %eax
	call	_parse_bytes
	movl	%eax, 8(%ebx)
L153:
	movl	4(%ebp), %eax
	movl	(%eax,%esi), %eax
	movl	8(%eax), %eax
	call	_expand_response_files
	movl	36(%esp), %eax
	movl	%eax, (%esp)
	call	_free
	jmp	L143
L169:
	decl	%edx
	je	L149
	movb	-1(%ecx,%edx), %al
	jmp	L148
L146:
	call	__close
L147:
	xorl	%edx, %edx
	jmp	L149
L170:
	movl	4(%ebp), %eax
	movl	36(%esp), %ecx
	addl	%ecx, %edx
	movl	(%eax,%esi), %eax
	movl	%edx, 44(%esp)
	movl	%eax, 48(%esp)
	cmpl	%edx, 36(%esp)
	jae	L150
	movl	36(%esp), %edx
	leal	76(%esp), %ecx
	movl	%esi, 52(%esp)
	movl	$0, 28(%esp)
	movl	%ecx, 32(%esp)
	movl	%edx, %esi
	movl	%edi, 56(%esp)
	movl	%ebp, 60(%esp)
	.p2align 4,,7
L151:
	movl	%esi, (%esp)
	call	_strlen
	movl	%eax, %ebp
	leal	1(%eax), %edi
	leal	(%esi,%edi), %edx
	movl	%edx, 40(%esp)
	call	_new_arg
	movl	32(%esp), %ecx
	movl	%eax, %ebx
	leal	12(%eax), %edx
	movl	%eax, (%ecx)
	movl	$1, 16(%eax)
	movl	28(%esp), %eax
	movl	%edx, 32(%esp)
	incl	%eax
	movl	%eax, 28(%esp)
	movl	%edi, %eax
	call	_c1xmalloc
	movl	%eax, (%ebx)
	movl	%esi, 4(%esp)
	movl	%ebp, 8(%esp)
	movl	%eax, (%esp)
	call	_memcpy
	movl	(%ebx), %eax
	movl	40(%esp), %esi
	movb	$0, (%eax,%ebp)
	cmpl	%esi, 44(%esp)
	ja	L151
	movl	52(%esp), %esi
	movl	28(%esp), %eax
	movl	56(%esp), %edi
	movl	60(%esp), %ebp
	call	_new_arglist
	movl	76(%esp), %ecx
	xorl	%edx, %edx
	movl	%esi, 32(%esp)
	movl	28(%esp), %ebx
	.p2align 4,,7
L152:
	movl	4(%eax), %esi
	movl	%ecx, (%esi,%edx,4)
	incl	%edx
	movl	12(%ecx), %ecx
	cmpl	%ebx, %edx
	jne	L152
	movl	32(%esp), %esi
L155:
	movl	48(%esp), %edx
	movl	%eax, 8(%edx)
	jmp	L153
L150:
	xorl	%eax, %eax
	call	_new_arglist
	jmp	L155
	.cfi_endproc
LFE29:
LC4:
	.ascii "CMDLINE\0"
	.p2align 4,,15
	.globl	___crt0_setup_arguments
___crt0_setup_arguments:
LFB31:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%edi
	pushl	%esi
	pushl	%ebx
	subl	$236, %esp
	.cfi_offset 7, -12
	.cfi_offset 6, -16
	.cfi_offset 3, -20
	movl	___dos_argv0, %edx
	testb	$8, __crt0_startup_flags
	je	L173
	cmpb	$58, 1(%edx)
	je	L262
L173:
	movb	(%edx), %al
	leal	1(%edx), %ecx
	movl	%edx, %esi
	testb	%al, %al
	jne	L242
	jmp	L278
	.p2align 4,,7
L265:
	cmpb	$58, %al
	je	L176
	cmpb	$47, %al
	je	L176
	movb	(%ecx), %al
	incl	%ecx
	testb	%al, %al
	je	L264
L242:
	cmpb	$92, %al
	jne	L265
L176:
	movb	(%ecx), %al
	movl	%ecx, %esi
	incl	%ecx
	testb	%al, %al
	jne	L242
L264:
	movl	%esi, %ecx
	movl	%esi, %edi
	subl	%edx, %ecx
	leal	1(%ecx), %eax
	movl	%eax, -176(%ebp)
L175:
	movl	__stubinfo, %eax
	movl	%eax, -184(%ebp)
	cmpb	$0, 52(%eax)
	je	L215
	addl	$52, %eax
	movl	%eax, -172(%ebp)
	movl	%eax, %ebx
L179:
	movl	%ebx, (%esp)
	movl	%ecx, -208(%ebp)
	movl	%edx, -212(%ebp)
	call	_strlen
	movl	-176(%ebp), %edx
	movl	$1, (%esp)
	addl	%edx, %eax
	movl	%eax, 4(%esp)
	call	_calloc
	movl	-212(%ebp), %edx
	movl	%eax, -192(%ebp)
	cmpl	%edx, %esi
	movl	-208(%ebp), %ecx
	je	L266
	movl	-192(%ebp), %eax
	movl	%ecx, 8(%esp)
	movl	%edx, 4(%esp)
	movl	%eax, (%esp)
	call	_strncpy
	movl	-192(%ebp), %eax
	movl	$16, 8(%esp)
	movl	%ebx, 4(%esp)
	movl	%eax, (%esp)
	call	_strncat
L181:
	movl	__crt0_startup_flags, %edx
	movl	___dos_argv0, %eax
	subl	%eax, %edi
	movl	%edx, -180(%ebp)
	movl	%edi, -188(%ebp)
	movl	-180(%ebp), %esi
	movl	-180(%ebp), %edi
	xorl	%edx, %edx
	andl	$2, %edi
	andl	$1, %esi
	movl	-192(%ebp), %eax
	cmpl	-172(%ebp), %ebx
	je	L267
	.p2align 4,,7
L185:
	cmpb	$0, (%eax)
	setne	%cl
	testb	%cl, %cl
	je	L268
L187:
	testl	%edi, %edi
	jne	L183
	cmpb	$92, (%eax)
	je	L269
L183:
	testl	%esi, %esi
	jne	L184
	xorl	%ecx, %ecx
	movb	(%eax), %cl
	incl	%ecx
	testb	$2, ___dj_ctype_flags+1(%ecx,%ecx)
	je	L184
	movb	___dj_ctype_tolower(%ecx), %cl
	movb	%cl, (%eax)
L184:
	incl	%edx
	incl	%eax
	cmpl	-172(%ebp), %ebx
	jne	L185
L267:
	cmpl	%edx, -188(%ebp)
	setg	%cl
	testb	%cl, %cl
	jne	L187
	.p2align 4,,7
L268:
	testb	$4, -180(%ebp)
	je	L188
	movl	-192(%ebp), %edx
L189:
	movl	(%edx), %ecx
	addl	$4, %edx
	leal	-16843009(%ecx), %eax
	xorl	$-1, %ecx
	andl	%ecx, %eax
	andl	$-2139062144, %eax
	je	L189
	testl	$32896, %eax
	je	L270
	addb	%al, %al
	sbbl	$3, %edx
	leal	-4(%edx), %eax
	cmpb	$46, -4(%edx)
	je	L271
	.p2align 4,,7
L188:
/APP
# 36 "c:/djgpp/include/sys/segments.h" 1
	movw %ds,%ax
# 0 "" 2
/NO_APP
	movl	-184(%ebp), %ecx
	andl	$65535, %eax
	leal	-152(%ebp), %esi
	movl	$128, 16(%esp)
	movl	%esi, 12(%esp)
	movl	%eax, 8(%esp)
	movl	$128, 4(%esp)
	movw	38(%ecx), %ax
	andl	$65535, %eax
	movl	%eax, (%esp)
	call	___movedata
	movb	-152(%ebp), %dl
	cmpb	$127, %dl
	je	L272
L192:
	testb	$64, __crt0_startup_flags+1
	leal	-151(%ebp), %eax
	sete	%cl
	andl	$255, %ecx
	andl	$127, %edx
	call	_parse_bytes
	movl	%eax, %ebx
L194:
	movl	$___PROXY, (%esp)
	call	_getenv
	movl	%eax, -172(%ebp)
	testl	%eax, %eax
	je	L197
	movl	%eax, (%esp)
	call	_strlen
	movl	___PROXY_LEN, %ecx
	leal	1(%ecx), %edx
	movl	$___PROXY, 4(%esp)
	movl	%edx, 8(%esp)
	movl	%esi, (%esp)
	movl	%eax, %edi
	movl	%edx, -212(%ebp)
	movl	%ecx, -208(%ebp)
	call	_strncpy
	movl	-208(%ebp), %ecx
	leal	1(%edi), %eax
	movl	%eax, 8(%esp)
	movl	-172(%ebp), %eax
	movb	$32, -152(%ebp,%ecx)
	movl	%eax, 4(%esp)
	movl	-212(%ebp), %edx
	addl	%esi, %edx
	movl	%edx, (%esp)
	call	_strncpy
	movl	%ebx, %eax
	call	_delete_arglist
	movl	___PROXY_LEN, %eax
	xorl	%ecx, %ecx
	leal	1(%edi,%eax), %edx
	movl	%esi, %eax
	call	_parse_bytes
	movl	%eax, %ebx
L197:
	cmpl	$3, (%ebx)
	jle	L217
	movl	4(%ebx), %esi
	movl	$___PROXY+1, 4(%esp)
	movl	(%esi), %eax
	movl	(%eax), %eax
	movl	%eax, (%esp)
	call	_strcmp
	testl	%eax, %eax
	je	L273
L217:
	movl	$4, %esi
	movl	$1, -204(%ebp)
	movl	$1, %edi
L198:
	testb	$16, __crt0_startup_flags
	je	L274
L212:
	movl	-204(%ebp), %eax
	testl	%eax, %eax
	jne	L275
L213:
	movl	%ebx, %eax
	call	_count_args
	addl	%edi, %eax
	movl	%eax, ___crt0_argc
	leal	4(,%eax,4), %eax
	call	_c1xmalloc
	testl	%edi, %edi
	movl	%eax, ___crt0_argv
	je	L214
	movl	-192(%ebp), %ecx
	movl	%ecx, (%eax)
	movl	___crt0_argv, %eax
L214:
	addl	%esi, %eax
	movl	%ebx, %edx
	call	_fill_args
	movl	$0, (%eax)
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
L269:
	.cfi_restore_state
	movb	$47, (%eax)
	jmp	L183
	.p2align 4,,7
L215:
	movl	-184(%ebp), %eax
	movl	%esi, %ebx
	addl	$52, %eax
	movl	%eax, -172(%ebp)
	jmp	L179
L273:
	movl	4(%esi), %eax
	xorl	%edi, %edi
	movl	(%eax), %ecx
	movb	(%ecx), %al
	testb	%al, %al
	je	L199
	.p2align 4,,7
L201:
	movsbl	%al, %edx
	leal	-48(%edx), %eax
	cmpl	$9, %eax
	jle	L200
	leal	-55(%edx), %eax
L200:
	incl	%ecx
	andl	$15, %eax
	sall	$4, %edi
	addl	%eax, %edi
	movb	(%ecx), %al
	testb	%al, %al
	jne	L201
L199:
	movl	8(%esi), %eax
	movl	%edi, ___crt0_argc
	movl	(%eax), %ecx
	movb	(%ecx), %al
	testb	%al, %al
	je	L219
	xorl	%edi, %edi
	.p2align 4,,7
L204:
	movsbl	%al, %edx
	leal	-48(%edx), %eax
	cmpl	$9, %eax
	jle	L203
	leal	-55(%edx), %eax
L203:
	incl	%ecx
	andl	$15, %eax
	sall	$4, %edi
	addl	%eax, %edi
	movb	(%ecx), %al
	testb	%al, %al
	jne	L204
	sall	$4, %edi
	movl	%edi, -180(%ebp)
L202:
	movl	12(%esi), %eax
	xorl	%esi, %esi
	movl	(%eax), %edx
	movsbl	(%edx), %ecx
	testb	%cl, %cl
	je	L205
	.p2align 4,,7
L207:
	leal	-48(%ecx), %eax
	cmpl	$9, %eax
	jle	L206
	leal	-55(%ecx), %eax
L206:
	incl	%edx
	andl	$15, %eax
	sall	$4, %esi
	movsbl	(%edx), %ecx
	addl	%eax, %esi
	testb	%cl, %cl
	jne	L207
L205:
	movl	%ebx, %eax
	call	_delete_arglist
	movl	___crt0_argc, %edx
	addl	%edx, %edx
	leal	30(%edx), %eax
	andl	$-16, %eax
	subl	%eax, %esp
/APP
# 36 "c:/djgpp/include/sys/segments.h" 1
	movw %ds,%ax
# 0 "" 2
/NO_APP
	movl	%edx, 16(%esp)
	movl	%eax, %edx
	movl	-180(%ebp), %eax
	leal	35(%esp), %edi
	addl	%eax, %esi
	movw	__go32_info_block+26, %ax
	andl	$65535, %edx
	andl	$65535, %eax
	andl	$-16, %edi
	movl	%edx, 8(%esp)
	movl	%esi, 4(%esp)
	movl	%eax, (%esp)
	movl	%edi, 12(%esp)
	movl	%edx, -212(%ebp)
	call	___movedata
	movl	___crt0_argc, %eax
	call	_new_arglist
	movl	-212(%ebp), %edx
	movl	%eax, %ebx
	movl	-172(%ebp), %eax
	testl	%eax, %eax
	setne	-193(%ebp)
	movb	-193(%ebp), %cl
	movl	___crt0_argc, %eax
	andl	$255, %ecx
	xorl	%esi, %esi
	movl	%ecx, -204(%ebp)
	testl	%eax, %eax
	jle	L221
	movl	%edx, -200(%ebp)
	.p2align 4,,7
L211:
	movw	(%edi,%esi,2), %cx
	movl	-180(%ebp), %eax
	andl	$65535, %ecx
	addl	%eax, %ecx
/APP
# 169 "c:/djgpp/include/libc/farptrgs.h" 1
	movw __go32_info_block+26,%gs
# 0 "" 2
# 218 "c:/djgpp/include/libc/farptrgs.h" 1
	.byte 0x65
	movb (%ecx),%al
# 0 "" 2
/NO_APP
	testb	%al, %al
	je	L222
	movl	%ecx, %eax
	.p2align 4,,7
L209:
	incl	%eax
/APP
# 218 "c:/djgpp/include/libc/farptrgs.h" 1
	.byte 0x65
	movb (%eax),%dl
# 0 "" 2
/NO_APP
	testb	%dl, %dl
	jne	L209
	subl	%ecx, %eax
	movl	%eax, -184(%ebp)
	incl	%eax
	movl	%eax, -176(%ebp)
L208:
	movl	4(%ebx), %edx
	leal	0(,%esi,4), %eax
	movl	%eax, -172(%ebp)
	addl	%edx, %eax
	movl	%eax, -188(%ebp)
	call	_new_arg
	movl	-188(%ebp), %edx
	movl	-172(%ebp), %ecx
	movl	%eax, (%edx)
	movl	4(%ebx), %eax
	movl	(%eax,%ecx), %edx
	movl	-176(%ebp), %eax
	movl	%edx, -212(%ebp)
	call	_c1xmalloc
	movl	-212(%ebp), %edx
	movl	-172(%ebp), %ecx
	movl	%eax, (%edx)
	movl	-176(%ebp), %edx
	movl	%edx, 16(%esp)
	movl	4(%ebx), %eax
	movl	(%eax,%ecx), %eax
	movl	-180(%ebp), %ecx
	movl	(%eax), %eax
	movl	%eax, 12(%esp)
	movl	-200(%ebp), %eax
	movl	%eax, 8(%esp)
	movw	(%edi,%esi,2), %ax
	andl	$65535, %eax
	addl	%ecx, %eax
	movl	%eax, 4(%esp)
	movw	__go32_info_block+26, %ax
	andl	$65535, %eax
	movl	%eax, (%esp)
	call	___movedata
	cmpb	$0, -193(%ebp)
	je	L210
	testb	$64, __crt0_startup_flags+1
	je	L276
L210:
	incl	%esi
	cmpl	%esi, ___crt0_argc
	jg	L211
	xorl	%esi, %esi
	xorl	%edi, %edi
	testb	$16, __crt0_startup_flags
	jne	L212
L274:
	movl	%ebx, %eax
	call	_expand_response_files
	movl	-204(%ebp), %eax
	testl	%eax, %eax
	je	L213
L275:
	movl	%ebx, %eax
	call	_expand_wildcards
	jmp	L213
	.p2align 4,,7
L276:
	movl	4(%ebx), %eax
	movl	-172(%ebp), %edx
	movl	(%eax,%edx), %ecx
	movl	-184(%ebp), %edx
	movl	(%ecx), %eax
	addl	$16, %ecx
	movl	%ecx, 4(%esp)
	leal	-156(%ebp), %ecx
	addl	%eax, %edx
	movl	%ecx, (%esp)
	movl	$1, %ecx
	call	_parse_arg
	movl	4(%ebx), %eax
	movl	-172(%ebp), %edx
	movl	(%eax,%edx), %eax
	movl	(%eax), %edx
	movl	-156(%ebp), %eax
	movb	$0, (%edx,%eax)
	jmp	L210
	.p2align 4,,7
L272:
	movl	$LC4, (%esp)
	call	_getenv
	testl	%eax, %eax
	je	L277
	movb	(%eax), %dl
	cmpb	$39, %dl
	je	L195
	cmpb	$34, %dl
	je	L195
	cmpb	$32, %dl
	je	L195
	.p2align 4,,7
L241:
	incl	%eax
	cmpb	$32, (%eax)
	jne	L241
L195:
	leal	1(%eax), %ebx
	movl	%ebx, (%esp)
	call	_strlen
	testb	$64, __crt0_startup_flags+1
	sete	%cl
	movl	%eax, %edx
	andl	$255, %ecx
	movl	%ebx, %eax
	call	_parse_bytes
	movl	%eax, %ebx
	jmp	L194
L222:
	movl	$0, -184(%ebp)
	movl	$1, -176(%ebp)
	jmp	L208
L262:
	addl	$2, %edx
	movl	%edx, ___dos_argv0
	jmp	L173
L270:
	shrl	$16, %eax
	addl	$2, %edx
	addb	%al, %al
	sbbl	$3, %edx
	leal	-4(%edx), %eax
	cmpb	$46, -4(%edx)
	jne	L188
L271:
	movb	-3(%edx), %dl
	andl	$-33, %edx
	cmpb	$69, %dl
	jne	L188
	movb	2(%eax), %dl
	andl	$-33, %edx
	cmpb	$88, %dl
	jne	L188
	movb	3(%eax), %dl
	andl	$-33, %edx
	cmpb	$69, %dl
	jne	L188
	movb	$0, (%eax)
	jmp	L188
L266:
	movl	$16, 8(%esp)
	movl	%ebx, 4(%esp)
	movl	%eax, (%esp)
	call	_strncpy
	jmp	L181
L278:
	movl	%edx, %edi
	movl	$1, -176(%ebp)
	xorl	%ecx, %ecx
	jmp	L175
L277:
	movb	-152(%ebp), %dl
	jmp	L192
L219:
	movl	$0, -180(%ebp)
	jmp	L202
L221:
	xorl	%edi, %edi
	jmp	L198
	.cfi_endproc
LFE31:
	.ident	"GCC: (GNU) 4.7.4"
