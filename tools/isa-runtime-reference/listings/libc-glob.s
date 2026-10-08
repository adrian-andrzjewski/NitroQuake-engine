	.file	"glob.c"
	.section .text
	.p2align 4,,15
_str_compare:
LFB4:
	.cfi_startproc
	movl	8(%esp), %eax
	movl	(%eax), %eax
	movl	%eax, 8(%esp)
	movl	4(%esp), %eax
	movl	(%eax), %eax
	movl	%eax, 4(%esp)
	jmp	_strcmp
	.cfi_endproc
LFE4:
	.p2align 4,,15
_add:
LFB1:
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
	movl	_save_list, %ebx
	testl	%ebx, %ebx
	jne	L12
	jmp	L8
	.p2align 4,,7
L17:
	movl	(%ebx), %ebx
	testl	%ebx, %ebx
	je	L8
L12:
	movl	%esi, 4(%esp)
	movl	4(%ebx), %edx
	movl	%edx, (%esp)
	call	___stricmp
	testl	%eax, %eax
	jne	L17
	xorl	%eax, %eax
L6:
	addl	$20, %esp
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
L8:
	.cfi_restore_state
	movl	$8, (%esp)
	call	_malloc
	movl	%eax, %ebx
	testl	%eax, %eax
	je	L18
	movl	%esi, (%esp)
	call	_strlen
	incl	%eax
	movl	%eax, (%esp)
	call	_malloc
	movl	%eax, 4(%ebx)
	testl	%eax, %eax
	je	L19
	movl	%esi, 4(%esp)
	movl	%eax, (%esp)
	call	_strcpy
	movl	_save_list, %eax
	movl	%eax, (%ebx)
	movl	_save_count, %eax
	incl	%eax
	movl	%ebx, _save_list
	movl	%eax, _save_count
	addl	$20, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 12
	xorl	%eax, %eax
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 8
	popl	%esi
	.cfi_restore 6
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L18:
	.cfi_restore_state
	addl	$20, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 12
	movl	$1, %eax
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 8
	popl	%esi
	.cfi_restore 6
	.cfi_def_cfa_offset 4
	ret
L19:
	.cfi_restore_state
	movl	%ebx, (%esp)
	call	_free
	movl	$1, %eax
	jmp	L6
	.cfi_endproc
LFE1:
LC0:
	.ascii ".\0"
LC1:
	.ascii "..\0"
	.p2align 4,,15
_glob_dirs.isra.1:
LFB7:
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
	subl	$348, %esp
	.cfi_def_cfa_offset 368
	movl	%eax, %ebx
	testl	%ecx, %ecx
	movl	%edx, 28(%esp)
	je	L22
	cmpb	$0, (%eax)
	jne	L79
	movl	28(%esp), %edx
	movl	_pathbuf, %eax
	cmpl	%eax, %edx
	movzbl	-1(%edx), %esi
	movb	$0, (%edx)
	je	L80
	movl	28(%esp), %edx
	movb	$0, -1(%edx)
L27:
	movl	%eax, (%esp)
	call	___file_exists
	testl	%eax, %eax
	jne	L28
L30:
	movl	28(%esp), %edx
	movl	%esi, %eax
	movb	%al, -1(%edx)
L22:
	movl	28(%esp), %edx
	leal	46(%esp), %ebp
	movl	$2764330, (%edx)
	movl	$16, 8(%esp)
	movl	_pathbuf, %eax
	movl	%ebp, 4(%esp)
	movl	%eax, (%esp)
	call	___findfirst
	leal	76(%esp), %edx
	movl	%edx, 24(%esp)
	leal	89(%esp), %edx
	movl	%edx, 20(%esp)
	testl	%eax, %eax
	je	L63
	jmp	L41
	.p2align 4,,7
L36:
	movl	28(%esp), %edx
	leal	76(%esp), %eax
	movl	%edx, (%esp)
	movl	%eax, 4(%esp)
	call	_stpcpy
	movl	_wildcard_nesting, %ecx
	movb	_slash, %dl
	incl	%ecx
	movb	%dl, (%eax)
	movb	$0, 1(%eax)
	movl	%eax, %esi
	leal	1(%eax), %edi
	movl	%ecx, _wildcard_nesting
	cmpb	$0, (%ebx)
	jne	L81
	testb	$8, _flags
	setne	%al
	negl	%eax
	andl	%eax, %edx
	movl	_pathbuf, %eax
	movb	%dl, (%esi)
	call	_add
	testl	%eax, %eax
	jne	L29
	movb	_slash, %dl
	movb	%dl, (%esi)
L39:
	cmpb	$0, _preserve_case
	sete	%al
	andl	$255, %eax
	movb	$0, 1(%esi)
	xorl	%ecx, %ecx
	movl	%eax, (%esp)
	movl	%edi, %edx
	movl	%ebx, %eax
	call	_glob_dirs.isra.1
	cmpl	$3, %eax
	je	L29
	movl	_wildcard_nesting, %eax
	decl	%eax
	movl	%eax, _wildcard_nesting
	.p2align 4,,7
L32:
	movl	%ebp, (%esp)
	call	___findnext
	testl	%eax, %eax
	jne	L41
L63:
	testb	$16, 67(%esp)
	je	L32
	movl	$LC0, %edi
	movl	$2, %ecx
	movl	24(%esp), %esi
	repe cmpsb
	je	L32
	movl	$LC1, %edi
	movl	$3, %ecx
	movl	24(%esp), %esi
	repe cmpsb
	je	L32
	movl	368(%esp), %esi
	testl	%esi, %esi
	je	L36
	leal	76(%esp), %eax
	movl	%eax, (%esp)
	call	__is_DOS83
	testl	%eax, %eax
	je	L36
	movsbl	76(%esp), %edx
	testb	%dl, %dl
	je	L36
	leal	76(%esp), %eax
	.p2align 4,,7
L38:
	leal	-65(%edx), %ecx
	cmpl	$25, %ecx
	ja	L37
	addl	$32, %edx
L37:
	movb	%dl, (%eax)
	movsbl	1(%eax), %edx
	testb	%dl, %dl
	je	L36
	incl	%eax
	cmpl	20(%esp), %eax
	jne	L38
	jmp	L36
	.p2align 4,,7
L81:
	cmpb	$0, _preserve_case
	sete	%cl
	andl	$255, %ecx
	movl	%edi, %edx
	movl	%ecx, (%esp)
	movl	%ebx, %eax
	call	_glob2
	cmpl	$3, %eax
	jne	L39
	.p2align 4,,7
L29:
	addl	$348, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 20
	movl	$3, %eax
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
L41:
	.cfi_restore_state
	addl	$348, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 20
	xorl	%eax, %eax
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
L79:
	.cfi_restore_state
	cmpb	$0, _preserve_case
	sete	%cl
	andl	$255, %ecx
	movl	%ecx, (%esp)
	call	_glob2
	cmpl	$3, %eax
	jne	L22
	jmp	L29
L80:
	movb	$46, (%edx)
	movb	$0, 1(%edx)
	jmp	L27
L28:
	movl	_pathbuf, %eax
	call	_add
	testl	%eax, %eax
	jne	L29
	jmp	L30
	.cfi_endproc
LFE7:
LC2:
	.ascii "...\0"
	.p2align 4,,15
_glob2:
LFB3:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%edi
	pushl	%esi
	pushl	%ebx
	subl	$380, %esp
	.cfi_offset 7, -12
	.cfi_offset 6, -16
	.cfi_offset 3, -20
	movl	%eax, %esi
	movl	%ecx, -364(%ebp)
	movl	%eax, -360(%ebp)
	movl	%edx, -356(%ebp)
	movl	$4, %ecx
	movl	$LC2, %edi
	repe cmpsb
	je	L221
	movl	$3, %ecx
	movl	-360(%ebp), %esi
	movl	$LC2, %edi
	repe cmpsb
	je	L222
L85:
	movl	-356(%ebp), %edx
	movl	%edx, %esi
	movb	$0, (%edx)
	movl	_pathbuf_end, %edx
	decl	%esi
	movl	%edx, -344(%ebp)
	cmpl	%edx, -356(%ebp)
	jae	L135
	cmpb	$0, _preserve_case
	sete	-352(%ebp)
	movb	-352(%ebp), %dl
	movb	_use_lfn, %al
	andl	$255, %edx
	movb	%al, -334(%ebp)
	movl	%edx, -340(%ebp)
	movl	-360(%ebp), %edx
	incl	%edx
	movl	-356(%ebp), %ebx
	movl	-364(%ebp), %edi
	.p2align 4,,7
L99:
	movb	-1(%edx), %al
	leal	-1(%edx), %ecx
	movl	%edx, -348(%ebp)
	cmpb	$92, %al
	je	L88
	cmpb	$58, %al
	je	L88
	cmpb	$47, %al
	je	L88
	cmpb	$63, %al
	je	L95
	cmpb	$42, %al
	je	L95
	cmpb	$91, %al
	je	L95
	testb	%al, %al
	je	L138
	cmpb	$0, -352(%ebp)
	je	L91
	leal	-65(%eax), %ecx
	cmpb	$25, %cl
	ja	L91
	xorl	%edi, %edi
	cmpb	$0, -334(%ebp)
	je	L91
	movl	$0, 8(%ebp)
	.p2align 4,,7
L91:
	movb	%al, (%ebx)
	incl	%ebx
	incl	%edx
	cmpl	-344(%ebp), %ebx
	jne	L99
L87:
	movb	$0, (%ebx)
L134:
	movl	-348(%ebp), %edx
	cmpb	$0, (%edx)
	jne	L109
L103:
	movl	_pathbuf, %eax
	movl	%eax, (%esp)
	call	___file_exists
	testl	%eax, %eax
	je	L109
	testb	$8, _flags
	jne	L105
	movl	_pathbuf, %ebx
L106:
	movl	%ebx, %eax
	call	_add
	testl	%eax, %eax
	jne	L120
	.p2align 4,,7
L109:
	leal	-12(%ebp), %esp
	xorl	%eax, %eax
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
L88:
	.cfi_restore_state
	movl	$4, %ecx
	movl	%edx, %esi
	movl	$LC2, %edi
	repe cmpsb
	seta	-333(%ebp)
	setb	%cl
	cmpb	%cl, -333(%ebp)
	je	L90
	movl	$3, %ecx
	movl	%edx, %esi
	movl	$LC2, %edi
	repe cmpsb
	seta	-333(%ebp)
	setb	%cl
	cmpb	%cl, -333(%ebp)
	jne	L137
	movb	3(%edx), %cl
	cmpb	$92, %cl
	je	L90
	cmpb	$47, %cl
	je	L90
L137:
	movl	-340(%ebp), %ecx
	movl	%ebx, %esi
	movb	%al, (%ebx)
	incl	%ebx
	incl	%edx
	movl	%ecx, 8(%ebp)
	movl	%ecx, %edi
	cmpl	-344(%ebp), %ebx
	jne	L99
	jmp	L87
	.p2align 4,,7
L222:
	movl	-360(%ebp), %esi
	movb	3(%esi), %al
	cmpb	$47, %al
	je	L144
	cmpb	$92, %al
	jne	L85
L144:
	movb	%al, _slash
	movl	-360(%ebp), %eax
	addl	$4, %eax
	jmp	L220
	.p2align 4,,7
L90:
	cmpb	$58, %al
	je	L93
	movb	%al, _slash
L93:
	movb	%al, (%ebx)
	movl	-340(%ebp), %eax
	incl	%ebx
	movl	%eax, 8(%ebp)
	movl	%eax, -364(%ebp)
L94:
	movb	$0, (%ebx)
	cmpl	-344(%ebp), %ebx
	jae	L134
	movl	-348(%ebp), %edx
	movb	(%edx), %al
	testb	%al, %al
	je	L103
	movl	_wildcard_nesting, %ecx
	testl	%ecx, %ecx
	jne	L223
L110:
	cmpb	$92, %al
	je	L140
	testb	%al, %al
	je	L140
	cmpb	$47, %al
	je	L141
	movl	-348(%ebp), %esi
	movb	_preserve_case, %dl
	movb	_use_lfn, %cl
	movl	%esi, -344(%ebp)
	movl	8(%ebp), %edi
	jmp	L116
	.p2align 4,,7
L225:
	testb	%al, %al
	je	L145
	cmpb	$47, %al
	je	L224
L116:
	testb	%dl, %dl
	jne	L113
	subl	$65, %eax
	cmpb	$25, %al
	ja	L113
	testb	%cl, %cl
	movl	$0, -364(%ebp)
	sete	%al
	andl	$255, %eax
	negl	%eax
	andl	%eax, %edi
L113:
	incl	%esi
	movb	(%esi), %al
	cmpb	$92, %al
	jne	L225
L145:
	movl	-348(%ebp), %edx
	movl	%esi, -344(%ebp)
	subl	%edx, %esi
	movl	%edi, 8(%ebp)
	leal	1(%esi), %edx
L111:
	testb	%al, %al
	jne	L133
L117:
	leal	30(%edx), %eax
	movl	-348(%ebp), %edx
	andl	$-16, %eax
	movl	$LC2, %edi
	subl	%eax, %esp
	leal	27(%esp), %ecx
	movl	%esi, 8(%esp)
	andl	$-16, %ecx
	movl	%edx, 4(%esp)
	movl	%ecx, (%esp)
	movl	%ecx, -340(%ebp)
	call	_strncpy
	movl	-340(%ebp), %ecx
	movb	$0, (%ecx,%esi)
	movl	$4, %ecx
	movl	-340(%ebp), %esi
	repe cmpsb
	jne	L118
	movl	-344(%ebp), %esi
	movl	$1, %ecx
	cmpb	$0, _preserve_case
	sete	%al
	andl	$255, %eax
	cmpb	$1, (%esi)
	sbbl	$-1, %esi
	movl	%eax, (%esp)
	movl	%ebx, %edx
	movl	%esi, %eax
	call	_glob_dirs.isra.1
	cmpl	$3, %eax
	jne	L109
L120:
	leal	-12(%ebp), %esp
	movl	$3, %eax
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
L221:
	.cfi_restore_state
	movl	-360(%ebp), %eax
	addl	$3, %eax
L220:
	cmpb	$0, _preserve_case
	sete	%dl
	andl	$255, %edx
	movl	$1, %ecx
	movl	%edx, (%esp)
	movl	-356(%ebp), %edx
	call	_glob_dirs.isra.1
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
L141:
	.cfi_restore_state
	movl	-348(%ebp), %edx
	xorl	%esi, %esi
	movl	%edx, -344(%ebp)
	movb	$47, %al
	movl	$1, %edx
	.p2align 4,,7
L133:
	movb	%al, _slash
	jmp	L117
	.p2align 4,,7
L95:
	movl	_pathbuf, %eax
	movl	%edi, -364(%ebp)
	cmpl	%esi, %eax
	jb	L226
L98:
	movl	-356(%ebp), %ebx
	movl	-360(%ebp), %ecx
	subl	%ebx, %esi
	movl	-356(%ebp), %ebx
	leal	1(%esi), %eax
	addl	%eax, %ecx
	addl	%eax, %ebx
	movl	%ecx, -348(%ebp)
	jmp	L94
	.p2align 4,,7
L224:
	movl	-348(%ebp), %eax
	movl	%esi, -344(%ebp)
	subl	%eax, %esi
	movl	%edi, 8(%ebp)
	movb	$47, %al
	leal	1(%esi), %edx
	jmp	L133
	.p2align 4,,7
L223:
	movl	_pathbuf, %eax
	movzbl	-1(%ebx), %esi
	movb	$0, -1(%ebx)
	movl	%eax, (%esp)
	call	___file_exists
	testl	%eax, %eax
	je	L109
	movl	%esi, %ecx
	movl	-348(%ebp), %edx
	movb	%cl, -1(%ebx)
	movb	(%edx), %al
	jmp	L110
L138:
	movl	%edi, -364(%ebp)
	movl	%ecx, -348(%ebp)
	jmp	L94
L118:
	movl	$2764330, (%ebx)
	leal	-314(%ebp), %eax
	movl	%eax, 4(%esp)
	movl	_pathbuf, %eax
	movl	$53, 8(%esp)
	movl	%eax, (%esp)
	call	___findfirst
	testl	%eax, %eax
	jne	L109
	movl	$1, -352(%ebp)
	leal	-284(%ebp), %esi
	movl	-352(%ebp), %edi
	movl	%ebx, -348(%ebp)
	subl	%ebx, %edi
	movl	%esi, -332(%ebp)
	movl	%edi, -352(%ebp)
	movl	-364(%ebp), %ebx
	jmp	L132
	.p2align 4,,7
L127:
	cmpl	$1, 8(%ebp)
	sbbl	%eax, %eax
	movl	-340(%ebp), %esi
	andl	$-8, %eax
	movl	%esi, (%esp)
	addl	$11, %eax
	movl	%eax, 8(%esp)
	leal	-284(%ebp), %eax
	movl	%eax, 4(%esp)
	call	___fnmatch
	testl	%eax, %eax
	je	L227
L123:
	leal	-314(%ebp), %ecx
	movl	%ecx, (%esp)
	call	___findnext
	testl	%eax, %eax
	jne	L109
L132:
	testb	$16, -293(%ebp)
	je	L121
	movl	$LC0, %edi
	movl	$2, %ecx
	movl	-332(%ebp), %esi
	repe cmpsb
	je	L123
	movl	$LC1, %edi
	movl	$3, %ecx
	movl	-332(%ebp), %esi
	repe cmpsb
	je	L123
	.p2align 4,,7
L121:
	testl	%ebx, %ebx
	je	L127
	leal	-284(%ebp), %eax
	movl	%eax, (%esp)
	call	__is_DOS83
	testl	%eax, %eax
	je	L127
	movsbl	-284(%ebp), %edx
	testb	%dl, %dl
	je	L127
	leal	-284(%ebp), %eax
	leal	-271(%ebp), %esi
	.p2align 4,,7
L129:
	leal	-65(%edx), %ecx
	cmpl	$25, %ecx
	ja	L128
	addl	$32, %edx
L128:
	movb	%dl, (%eax)
	movsbl	1(%eax), %edx
	testb	%dl, %dl
	je	L127
	incl	%eax
	cmpl	%esi, %eax
	jne	L129
	jmp	L127
	.p2align 4,,7
L227:
	leal	-284(%ebp), %edx
	movl	%edx, 4(%esp)
	movl	-348(%ebp), %edx
	movl	%edx, (%esp)
	call	_stpcpy
	movl	-344(%ebp), %ecx
	movb	(%ecx), %dl
	testb	%dl, %dl
	jne	L228
	testb	$16, -293(%ebp)
	je	L131
	testb	$8, _flags
	je	L131
	movl	-348(%ebp), %edx
	movl	-352(%ebp), %esi
	addl	%edx, %eax
	movl	-348(%ebp), %edx
	movb	$0, (%eax,%esi)
	movl	%edx, (%esp)
	call	_strlen
	movl	-348(%ebp), %edx
	movb	_slash, %cl
	movb	%cl, (%edx,%eax)
L131:
	movl	_pathbuf, %eax
	call	_add
	testl	%eax, %eax
	je	L123
	jmp	L120
	.p2align 4,,7
L228:
	movl	_wildcard_nesting, %esi
	movb	%dl, (%eax)
	incl	%esi
	movb	$0, 1(%eax)
	cmpb	$0, _preserve_case
	sete	%cl
	andl	$255, %ecx
	leal	1(%eax), %edx
	movl	-344(%ebp), %eax
	movl	%ecx, (%esp)
	incl	%eax
	movl	%esi, _wildcard_nesting
	call	_glob2
	cmpl	$3, %eax
	je	L120
	movl	_wildcard_nesting, %ecx
	decl	%ecx
	movl	%ecx, _wildcard_nesting
	jmp	L123
L226:
	movl	%esi, %edx
	movl	-360(%ebp), %ecx
	subl	%eax, %edx
	movl	%ecx, 4(%esp)
	movl	%edx, 8(%esp)
	movl	-356(%ebp), %edx
	movl	%edx, (%esp)
	call	_strncpy
	jmp	L98
L105:
	leal	-314(%ebp), %eax
	movl	$53, 8(%esp)
	movl	%eax, 4(%esp)
	movl	_pathbuf, %eax
	movl	%eax, (%esp)
	call	___findfirst
	movl	_pathbuf, %ebx
	testb	$16, -293(%ebp)
	je	L106
	movl	%ebx, (%esp)
	call	_strlen
	addl	%ebx, %eax
	movb	$47, (%eax)
	movb	$0, 1(%eax)
	jmp	L106
L140:
	movl	-348(%ebp), %edx
	xorl	%esi, %esi
	movl	%edx, -344(%ebp)
	movl	$1, %edx
	jmp	L111
L135:
	movl	-360(%ebp), %esi
	movl	-356(%ebp), %ebx
	movl	%esi, -348(%ebp)
	jmp	L87
	.cfi_endproc
LFE3:
	.p2align 4,,15
	.globl	___glob
___glob:
LFB5:
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
	subl	$2060, %esp
	.cfi_def_cfa_offset 2080
	movl	$0, _wildcard_nesting
	movl	$0, _save_count
	movl	$0, _save_list
	leal	48(%esp), %eax
	movl	2080(%esp), %esi
	movl	%eax, _pathbuf
	leal	2047(%esp), %eax
	movl	2084(%esp), %edi
	movl	%eax, _pathbuf_end
	movl	%esi, (%esp)
	movl	2088(%esp), %eax
	movl	%edi, _flags
	movl	2092(%esp), %ebx
	movl	%eax, _errfunc
	call	__use_lfn
	movb	%al, _use_lfn
	call	__preserve_fncase
	movb	$47, _slash
	movb	%al, _preserve_case
	andl	$1, %edi
	jne	L231
	movl	$0, (%ebx)
	movl	$0, 4(%ebx)
	testb	$2, _flags
	je	L260
L231:
	testb	%al, %al
	movl	_pathbuf, %edx
	sete	%cl
	andl	$255, %ecx
	movl	%esi, %eax
	movl	%ecx, (%esp)
	call	_glob2
	cmpl	$3, %eax
	je	L236
	movl	_save_count, %edx
	movl	%edx, 24(%esp)
	testl	%edx, %edx
	jne	L235
	movl	$2, %eax
	testb	$16, _flags
	je	L234
	movl	%esi, %eax
	call	_add
	testl	%eax, %eax
	jne	L236
	movl	_save_count, %edx
	movl	%edx, 24(%esp)
	.p2align 4,,7
L235:
	movl	_flags, %edx
	xorl	%ebp, %ebp
	movl	%edx, 28(%esp)
	andl	$2, %edx
	je	L237
	movl	8(%ebx), %ebp
L237:
	testb	$1, 28(%esp)
	jne	L261
	movl	24(%esp), %edx
	addl	%ebp, %edx
	movl	%edx, 20(%esp)
	leal	4(,%edx,4), %eax
	movl	%eax, (%esp)
	call	_malloc
	movl	%eax, 4(%ebx)
	testl	%eax, %eax
	je	L236
	testl	%ebp, %ebp
	jne	L262
	movl	24(%esp), %edx
	movl	%edx, 20(%esp)
L239:
	movl	20(%esp), %edx
	movl	$0, (%eax,%edx,4)
	movl	_save_list, %eax
	testl	%eax, %eax
	je	L240
	movl	%edx, %edi
	decl	%edi
	movl	%edi, %edx
	leal	0(,%edi,4), %ebp
	movl	%ebx, %edi
	movl	%edx, %ebx
	jmp	L241
	.p2align 4,,7
L263:
	decl	%ebx
L241:
	movl	4(%edi), %edx
	movl	4(%eax), %esi
	movl	%ebx, 20(%esp)
	movl	%esi, (%edx,%ebp)
	subl	$4, %ebp
	movl	(%eax), %esi
	movl	%eax, (%esp)
	movl	%esi, _save_list
	call	_free
	movl	%esi, %eax
	testl	%esi, %esi
	jne	L263
	movl	%edi, %ebx
L240:
	testb	$64, 28(%esp)
	je	L264
L242:
	movl	24(%esp), %eax
	movl	20(%esp), %esi
	addl	%eax, %esi
	xorl	%eax, %eax
	movl	%esi, (%ebx)
	addl	$2060, %esp
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
L236:
	.cfi_restore_state
	movl	$3, %eax
L234:
	addl	$2060, %esp
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
L260:
	.cfi_restore_state
	movl	$0, 8(%ebx)
	jmp	L231
	.p2align 4,,7
L261:
	movl	(%ebx), %eax
	movl	24(%esp), %edx
	leal	1(%edx,%eax), %eax
	addl	%ebp, %eax
	sall	$2, %eax
	movl	%eax, 4(%esp)
	movl	4(%ebx), %eax
	movl	%eax, (%esp)
	call	_realloc
	movl	%eax, 4(%ebx)
	testl	%eax, %eax
	je	L236
	movl	(%ebx), %esi
	movl	24(%esp), %edx
	addl	%ebp, %esi
	addl	%edx, %esi
	movl	%esi, 20(%esp)
	jmp	L239
	.p2align 4,,7
L264:
	movl	24(%esp), %edx
	movl	$_str_compare, 12(%esp)
	movl	%edx, 4(%esp)
	movl	$4, 8(%esp)
	movl	4(%ebx), %eax
	movl	20(%esp), %edx
	leal	(%eax,%edx,4), %eax
	movl	%eax, (%esp)
	call	_qsort
	movl	_save_count, %edx
	movl	%edx, 24(%esp)
	jmp	L242
	.p2align 4,,7
L262:
	sall	$2, %ebp
	movl	$0, 4(%esp)
	movl	%ebp, 8(%esp)
	movl	%eax, (%esp)
	call	_memset
	movl	4(%ebx), %eax
	jmp	L239
	.cfi_endproc
LFE5:
.lcomm _pathbuf,4,4
.lcomm _pathbuf_end,4,4
.lcomm _flags,4,4
.lcomm _errfunc,4,4
.lcomm _wildcard_nesting,4,4
.lcomm _save_count,4,4
.lcomm _save_list,4,4
.lcomm _use_lfn,1,1
.lcomm _preserve_case,1,1
.lcomm _slash,1,1
	.ident	"GCC: (GNU) 4.7.4"
