	.file	"nmalloc.c"
	.section .text
	.p2align 4,,15
_sethook:
LFB1:
	.cfi_startproc
	movl	4(%esp), %edx
	cmpl	$5, %edx
	ja	L3
	movl	8(%esp), %ecx
	movl	_hookptr(,%edx,4), %eax
	movl	%ecx, _hookptr(,%edx,4)
	ret
	.p2align 4,,7
L3:
	xorl	%eax, %eax
	ret
	.cfi_endproc
LFE1:
	.p2align 4,,15
_extractfree:
LFB6:
	.cfi_startproc
	pushl	%esi
	.cfi_def_cfa_offset 8
	.cfi_offset 6, -8
	testl	%eax, %eax
	pushl	%ebx
	.cfi_def_cfa_offset 12
	.cfi_offset 3, -12
	je	L5
	movl	8(%eax), %edx
	xorl	%ecx, %ecx
	testl	%edx, %edx
	jne	L8
L7:
	movl	12(%eax), %edx
	movl	%edx, %ebx
	cmpl	$_freehdrs+4, %edx
	je	L26
	movl	16(%eax), %esi
	cmpl	$_freehdrs+4, %esi
	je	L27
L10:
	testl	%ebx, %ebx
	je	L11
L28:
	movl	%esi, 16(%ebx)
	movl	16(%eax), %ebx
	testl	%ebx, %ebx
	je	L12
L14:
	movl	%edx, 12(%ebx)
L13:
	movl	$0, 16(%eax)
	movl	$0, 12(%eax)
L5:
	popl	%ebx
	.cfi_remember_state
	.cfi_restore 3
	.cfi_def_cfa_offset 8
	popl	%esi
	.cfi_restore 6
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L8:
	.cfi_restore_state
	incl	%ecx
	shrl	%edx
	je	L7
	incl	%ecx
	shrl	%edx
	jne	L8
	jmp	L7
	.p2align 4,,7
L26:
	movl	16(%eax), %esi
	xorl	%ebx, %ebx
	movl	$0, 12(%eax)
	cmpl	$_freehdrs+4, %esi
	jne	L10
	.p2align 4,,7
L27:
	movl	$0, 16(%eax)
	testl	%ebx, %ebx
	jne	L28
L11:
	movl	16(%eax), %ebx
	testl	%ebx, %ebx
	jne	L14
	movl	$0, _freehdrs(,%ecx,4)
	jmp	L13
	.p2align 4,,7
L12:
	movl	%edx, _freehdrs(,%ecx,4)
	jmp	L13
	.cfi_endproc
LFE6:
	.p2align 4,,15
_searchfree:
LFB11:
	.cfi_startproc
	xorl	%edx, %edx
	testl	%eax, %eax
	je	L30
	movl	%eax, %ecx
L31:
	incl	%edx
	shrl	%ecx
	jne	L31
L30:
	movl	_freehdrs(,%edx,4), %ecx
	testl	%ecx, %ecx
	je	L42
	cmpl	8(%ecx), %eax
	jbe	L33
	.p2align 4,,7
L42:
	incl	%edx
	cmpl	$31, %edx
	jg	L39
	movl	_freehdrs(,%edx,4), %eax
	testl	%eax, %eax
	je	L42
L34:
	movl	%edx, %eax
	ret
	.p2align 4,,7
L33:
	cmpl	$31, %edx
	jle	L34
L39:
	xorl	%edx, %edx
	movl	%edx, %eax
	ret
	.cfi_endproc
LFE11:
LC0:
	.ascii ": memory fouled\12\0"
	.p2align 4,,15
_badcallabort.isra.0:
LFB22:
	.cfi_startproc
	subl	$28, %esp
	.cfi_def_cfa_offset 32
	movl	%edx, 8(%esp)
	movl	%eax, 4(%esp)
	movl	$2, (%esp)
	call	_write
	movl	$16, 8(%esp)
	movl	$LC0, 4(%esp)
	movl	$2, (%esp)
	call	_write
	movl	$288, (%esp)
	call	_raise
	addl	$28, %esp
	.cfi_def_cfa_offset 4
	ret
	.cfi_endproc
LFE22:
LC1:
	.ascii "combinehi\0"
	.p2align 4,,15
_combinehi:
LFB8:
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
	testl	%eax, %eax
	je	L50
	movl	4(%eax), %esi
	testl	%esi, %esi
	je	L50
	movl	(%esi), %ebx
	cmpl	%eax, %ebx
	jne	L64
	cmpl	_freehdrs, %esi
	je	L52
	movl	%esi, %eax
	call	_extractfree
L52:
	movl	4(%ebx), %eax
	movl	4(%eax), %eax
	movl	%eax, 4(%ebx)
	testl	%eax, %eax
	je	L53
	movl	%ebx, (%eax)
L53:
	movl	8(%esi), %eax
	movl	8(%ebx), %edx
	addl	%eax, %edx
	movl	%edx, 8(%ebx)
L50:
	addl	$16, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 16
	movl	%edi, %eax
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
L64:
	.cfi_restore_state
	movl	$9, %edx
	movl	$LC1, %eax
	call	_badcallabort.isra.0
	movl	$1, (%esp)
	call	_exit
	.cfi_endproc
LFE8:
	.p2align 4,,15
_mv2freelist:
LFB9:
	.cfi_startproc
	testl	%eax, %eax
	je	L94
	subl	$12, %esp
	.cfi_def_cfa_offset 16
	movl	4(%eax), %edx
	testl	%edx, %edx
	je	L67
	cmpl	$_freehdrs+4, %edx
	je	L67
	movl	12(%edx), %ecx
	testl	%ecx, %ecx
	je	L67
	movl	16(%edx), %edx
	testl	%edx, %edx
	je	L67
	call	_combinehi
L67:
	movl	8(%eax), %ecx
	xorl	%edx, %edx
	testl	%ecx, %ecx
	jne	L69
L68:
	movl	_freehdrs, %ecx
	testl	%ecx, %ecx
	je	L70
	cmpl	4(%eax), %ecx
	je	L96
L70:
	movl	_freehdrs(,%edx,4), %ecx
	testl	%ecx, %ecx
	je	L71
	movl	%ecx, 12(%eax)
	movl	_freehdrs(,%edx,4), %ecx
	movl	%eax, 16(%ecx)
L72:
	movl	$_freehdrs+4, 16(%eax)
	movl	_freehdrs(,%edx,4), %ecx
	testl	%ecx, %ecx
	je	L73
	movl	%eax, 16(%ecx)
L73:
	movl	%eax, _freehdrs(,%edx,4)
L65:
	addl	$12, %esp
	.cfi_def_cfa_offset 4
L94:
	ret
	.p2align 4,,7
L69:
	.cfi_def_cfa_offset 16
	incl	%edx
	shrl	%ecx
	je	L68
	incl	%edx
	shrl	%ecx
	jne	L69
	jmp	L68
	.p2align 4,,7
L71:
	movl	$_freehdrs+4, 12(%eax)
	jmp	L72
	.p2align 4,,7
L96:
	call	_combinehi
	movl	%eax, _freehdrs
	movl	$0, 16(%eax)
	movl	$0, 12(%eax)
	jmp	L65
	.cfi_endproc
LFE9:
	.p2align 4,,15
_extendsbrk:
LFB13:
	.cfi_startproc
	pushl	%edi
	.cfi_def_cfa_offset 8
	.cfi_offset 7, -8
	pushl	%esi
	.cfi_def_cfa_offset 12
	.cfi_offset 6, -12
	leal	32(%eax), %esi
	pushl	%ebx
	.cfi_def_cfa_offset 16
	.cfi_offset 3, -16
	subl	$16, %esp
	.cfi_def_cfa_offset 32
	cmpl	$1023, %esi
	ja	L98
	movl	$1024, %esi
L98:
	movl	_freehdrs, %eax
	testl	%eax, %eax
	je	L107
	movl	8(%eax), %edi
	addl	%eax, %edi
	movl	%edi, %eax
	andl	$7, %eax
	je	L99
	subl	%eax, %esi
	addl	$8, %esi
L99:
	movl	%esi, (%esp)
	call	_sbrk
	movl	%eax, %ebx
	cmpl	$-1, %eax
	je	L108
	cmpl	%edi, %eax
	je	L115
	movl	%ebx, %edx
	xorl	%eax, %eax
	andl	$7, %edx
	je	L102
	movb	$8, %al
	subl	%edx, %eax
	addl	%eax, %ebx
L102:
	subl	%eax, %esi
	movl	$0, 4(%ebx)
	movl	$0, (%ebx)
	movl	$0, 12(%ebx)
	movl	_freehdrs, %eax
	movl	%esi, 8(%ebx)
	call	_mv2freelist
	movl	_lastsbrkbgn, %eax
	movl	%ebx, _freehdrs
	cmpl	$98, %eax
	jg	L100
	testl	%eax, %eax
	jle	L103
	cmpl	_sbrkbgn, %ebx
	je	L100
	xorl	%edx, %edx
	jmp	L104
	.p2align 4,,7
L105:
	cmpl	_sbrkbgn(,%edx,4), %ebx
	je	L100
L104:
	incl	%edx
	cmpl	%eax, %edx
	jne	L105
L103:
	movl	%ebx, _sbrkbgn(,%eax,4)
	incl	%eax
	movl	%eax, _lastsbrkbgn
L100:
	addl	$16, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 16
	movl	%ebx, %eax
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
	.p2align 4,,7
L107:
	.cfi_restore_state
	xorl	%edi, %edi
	jmp	L99
	.p2align 4,,7
L115:
	movl	_freehdrs, %ebx
	movl	8(%ebx), %eax
	addl	%esi, %eax
	movl	%eax, 8(%ebx)
	addl	$16, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 16
	movl	%ebx, %eax
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
L108:
	.cfi_restore_state
	xorl	%ebx, %ebx
	jmp	L100
	.cfi_endproc
LFE13:
LC2:
	.ascii "combinelo\0"
	.p2align 4,,15
_dofree:
LFB15:
	.cfi_startproc
	pushl	%esi
	.cfi_def_cfa_offset 8
	.cfi_offset 6, -8
	pushl	%ebx
	.cfi_def_cfa_offset 12
	.cfi_offset 3, -12
	subl	$20, %esp
	.cfi_def_cfa_offset 32
	movl	%eax, %ebx
	movl	$_freehdrs+4, 16(%eax)
	movl	$_freehdrs+4, 12(%eax)
	movl	4(%eax), %eax
	testl	%eax, %eax
	je	L117
	cmpl	$_freehdrs+4, %eax
	je	L117
	movl	12(%eax), %edx
	testl	%edx, %edx
	je	L117
	movl	16(%eax), %eax
	testl	%eax, %eax
	je	L117
	movl	%ebx, %eax
	call	_combinehi
	movl	%eax, %ebx
L117:
	movl	(%ebx), %esi
	testl	%esi, %esi
	je	L118
	cmpl	$_freehdrs+4, %esi
	je	L118
	movl	12(%esi), %eax
	testl	%eax, %eax
	je	L118
	movl	16(%esi), %ecx
	testl	%ecx, %ecx
	je	L118
	cmpl	4(%esi), %ebx
	jne	L142
	movl	%esi, %eax
	call	_extractfree
	movl	4(%ebx), %eax
	movl	%eax, 4(%esi)
	testl	%eax, %eax
	je	L120
	movl	%esi, (%eax)
L120:
	movl	8(%ebx), %eax
	movl	8(%esi), %edx
	addl	%eax, %edx
	movl	%esi, %ebx
	movl	%edx, 8(%esi)
L118:
	movl	_freehdrs, %eax
	testl	%eax, %eax
	je	L121
	cmpl	(%ebx), %eax
	je	L116
L121:
	addl	$20, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 12
	movl	%ebx, %eax
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 8
	popl	%esi
	.cfi_restore 6
	.cfi_def_cfa_offset 4
	jmp	_mv2freelist
	.p2align 4,,7
L116:
	.cfi_restore_state
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
L142:
	.cfi_restore_state
	movl	$9, %edx
	movl	$LC2, %eax
	call	_badcallabort.isra.0
	movl	$1, (%esp)
	call	_exit
	.cfi_endproc
LFE15:
LC3:
	.ascii "memblockpsz\0"
LC4:
	.ascii "memblockpnxt\0"
	.p2align 4,,15
_split:
LFB12:
	.cfi_startproc
	pushl	%esi
	.cfi_def_cfa_offset 8
	.cfi_offset 6, -8
	pushl	%ebx
	.cfi_def_cfa_offset 12
	.cfi_offset 3, -12
	subl	$20, %esp
	.cfi_def_cfa_offset 32
	leal	16(%edx), %esi
	movl	(%eax), %ecx
	leal	(%ecx,%edx), %ebx
	cmpl	%esi, 8(%ecx)
	jb	L151
	movl	(%ecx), %esi
	movl	%esi, (%ebx)
	movl	4(%ecx), %esi
	movl	%esi, 4(%ebx)
	movl	8(%ecx), %esi
	movl	%esi, 8(%ebx)
	movl	12(%ecx), %esi
	movl	%ecx, (%ebx)
	movl	%esi, 12(%ebx)
	movl	%ebx, 4(%ecx)
	movl	8(%ecx), %esi
	movl	$0, 12(%ecx)
	subl	%edx, %esi
	movl	%esi, 8(%ebx)
	movl	%edx, 8(%ecx)
	movl	%ebx, (%eax)
	movl	4(%ebx), %eax
	testl	%eax, %eax
	je	L145
	cmpl	%ecx, (%eax)
	jne	L152
	movl	%ebx, (%eax)
L145:
	addl	$20, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 12
	movl	%ecx, %eax
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 8
	popl	%esi
	.cfi_restore 6
	.cfi_def_cfa_offset 4
	ret
L151:
	.cfi_restore_state
	movl	$11, %edx
	movl	$LC3, %eax
	call	_badcallabort.isra.0
	movl	$1, (%esp)
	call	_exit
L152:
	movl	$12, %edx
	movl	$LC4, %eax
	call	_badcallabort.isra.0
	movl	$1, (%esp)
	call	_exit
	.cfi_endproc
LFE12:
	.p2align 4,,15
_mv2lastsbrk:
LFB17:
	.cfi_startproc
	pushl	%esi
	.cfi_def_cfa_offset 8
	.cfi_offset 6, -8
	pushl	%ebx
	.cfi_def_cfa_offset 12
	.cfi_offset 3, -12
	subl	$20, %esp
	.cfi_def_cfa_offset 32
	movl	%eax, %ebx
	movl	$_freehdrs, %eax
	call	_split
	movl	8(%ebx), %ecx
	leal	16(%ebx), %edx
	movl	%eax, %esi
	subl	$16, %ecx
	leal	16(%eax), %eax
	movl	%ecx, 8(%esp)
	movl	%edx, 4(%esp)
	movl	%eax, (%esp)
	call	_memcpy
	movl	%ebx, %eax
	call	_dofree
	addl	$20, %esp
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
LFE17:
	.p2align 4,,15
	.globl	__sysmalloc
__sysmalloc:
LFB0:
	.cfi_startproc
	movl	4(%esp), %eax
	movl	_sysquery, %edx
	movl	%edx, (%eax)
	movl	_sysquery+4, %edx
	movl	%edx, 4(%eax)
	movl	_sysquery+8, %edx
	movl	%edx, 8(%eax)
	movl	_sysquery+12, %edx
	movl	%edx, 12(%eax)
	movl	_sysquery+16, %edx
	movl	%edx, 16(%eax)
	ret	$4
	.cfi_endproc
LFE0:
LC5:
	.ascii "rmvfromfree\0"
	.p2align 4,,15
	.globl	_malloc
_malloc:
LFB14:
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
	movl	64(%esp), %edi
	testl	%edi, %edi
	je	L174
	leal	7(%edi), %esi
	andl	$-8, %esi
	leal	16(%esi), %ebp
	cmpl	$2147418110, %ebp
	ja	L170
	movl	%ebp, %eax
	call	_searchfree
	testl	%eax, %eax
	jne	L195
L159:
	movl	_freehdrs, %eax
	testl	%eax, %eax
	je	L169
	leal	32(%esi), %edx
	cmpl	%edx, 8(%eax)
	jae	L194
L169:
	movl	%ebp, %eax
	call	_extendsbrk
	movl	%eax, %ebx
	movl	%eax, 28(%esp)
	testl	%eax, %eax
	je	L170
	addl	$40, %esi
	cmpl	%esi, 8(%eax)
	jae	L194
L173:
	addl	$16, %ebx
L158:
	movl	_hookptr, %eax
	testl	%eax, %eax
	je	L171
	movl	%ebx, 4(%esp)
	movl	%edi, (%esp)
	call	*%eax
L171:
	testl	%ebx, %ebx
	je	L196
L172:
	addl	$44, %esp
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
L174:
	.cfi_restore_state
	movl	$24, %ebp
	movl	$8, %esi
	movl	%ebp, %eax
	call	_searchfree
	testl	%eax, %eax
	je	L159
L195:
	movl	_freehdrs(,%eax,4), %ebx
	movl	%ebx, 28(%esp)
	testl	%ebx, %ebx
	je	L197
	movl	8(%ebx), %edx
	xorl	%eax, %eax
	testl	%edx, %edx
	je	L162
	movl	%edx, %ecx
L163:
	incl	%eax
	shrl	%ecx
	jne	L163
L162:
	cmpl	_freehdrs(,%eax,4), %ebx
	jne	L198
	movl	12(%ebx), %ecx
	cmpl	$_freehdrs+4, %ecx
	je	L199
	movl	%ecx, _freehdrs(,%eax,4)
	movl	$_freehdrs+4, 16(%ecx)
L166:
	movl	$0, 12(%ebx)
L161:
	addl	$40, %esi
	cmpl	%edx, %esi
	ja	L173
	movl	%ebp, %edx
	leal	28(%esp), %eax
	call	_split
	movl	%eax, %ebx
	movl	28(%esp), %eax
	call	_mv2freelist
	jmp	L168
	.p2align 4,,7
L194:
	movl	%ebp, %edx
	movl	$_freehdrs, %eax
	call	_split
	movl	%eax, %ebx
L168:
	testl	%ebx, %ebx
	jne	L173
	.p2align 4,,7
L170:
	xorl	%ebx, %ebx
	jmp	L158
	.p2align 4,,7
L196:
	movl	_hookptr+4, %eax
	testl	%eax, %eax
	je	L172
	movl	%edi, (%esp)
	movl	$0, 4(%esp)
	call	*%eax
	addl	$44, %esp
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
L199:
	.cfi_restore_state
	movl	$0, _freehdrs(,%eax,4)
	jmp	L166
	.p2align 4,,7
L197:
	movl	8, %edx
	jmp	L161
L198:
	movl	$11, %edx
	movl	$LC5, %eax
	call	_badcallabort.isra.0
	movl	$1, (%esp)
	call	_exit
	.cfi_endproc
LFE14:
LC6:
	.ascii "free\0"
	.p2align 4,,15
	.globl	_free
_free:
LFB16:
	.cfi_startproc
	pushl	%ebx
	.cfi_def_cfa_offset 8
	.cfi_offset 3, -8
	subl	$24, %esp
	.cfi_def_cfa_offset 32
	movl	_hookptr+8, %eax
	movl	32(%esp), %ebx
	testl	%eax, %eax
	je	L201
	movl	%ebx, 4(%esp)
	movl	$0, (%esp)
	call	*%eax
L201:
	testl	%ebx, %ebx
	je	L202
	movl	%ebx, %eax
	subl	$16, %eax
	je	L203
	cmpl	$_freehdrs+4, %eax
	je	L203
	movl	-4(%ebx), %ecx
	testl	%ecx, %ecx
	je	L203
	movl	(%ebx), %edx
	testl	%edx, %edx
	je	L203
L204:
	addl	$24, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 8
	movl	$4, %edx
	movl	$LC6, %eax
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 4
	jmp	_badcallabort.isra.0
	.p2align 4,,7
L203:
	.cfi_restore_state
	movl	_freehdrs, %ecx
	testl	%ecx, %ecx
	je	L204
	movl	-4(%ebx), %edx
	testl	%edx, %edx
	jne	L204
	addl	$24, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 8
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 4
	jmp	_dofree
	.p2align 4,,7
L202:
	.cfi_restore_state
	movl	_hookptr+12, %eax
	testl	%eax, %eax
	je	L200
	movl	$0, 4(%esp)
	movl	$0, (%esp)
	call	*%eax
L200:
	addl	$24, %esp
	.cfi_def_cfa_offset 8
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 4
	ret
	.cfi_endproc
LFE16:
LC7:
	.ascii "realloc\0"
	.p2align 4,,15
	.globl	_realloc
_realloc:
LFB18:
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
	movl	_hookptr+16, %eax
	movl	96(%esp), %ebx
	movl	100(%esp), %esi
	testl	%eax, %eax
	je	L221
	movl	%ebx, 4(%esp)
	movl	%esi, (%esp)
	call	*%eax
L221:
	testl	%ebx, %ebx
	je	L305
	leal	-16(%ebx), %edi
	testl	%esi, %esi
	movl	%edi, 60(%esp)
	je	L252
	leal	7(%esi), %ebp
	andl	$-8, %ebp
	testl	%edi, %edi
	leal	16(%ebp), %edx
	je	L225
L306:
	cmpl	$_freehdrs+4, %edi
	je	L225
	movl	-4(%ebx), %eax
	testl	%eax, %eax
	je	L225
	movl	(%ebx), %eax
	testl	%eax, %eax
	je	L225
L226:
	movl	$7, %edx
	movl	$LC7, %eax
	call	_badcallabort.isra.0
L251:
	movl	_hookptr+4, %eax
	testl	%eax, %eax
	je	L254
	movl	%ebx, 4(%esp)
	movl	%esi, (%esp)
	call	*%eax
	xorl	%eax, %eax
L247:
	movl	_hookptr+20, %edx
	testl	%edx, %edx
	je	L268
L302:
	movl	%eax, 4(%esp)
	movl	%eax, 28(%esp)
	movl	%esi, (%esp)
	call	*%edx
	movl	28(%esp), %eax
L268:
	addl	$76, %esp
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
L252:
	.cfi_restore_state
	movl	$24, %edx
	movl	$8, %ebp
	testl	%edi, %edi
	jne	L306
	.p2align 4,,7
L225:
	movl	_freehdrs, %ecx
	movl	%ecx, 20(%esp)
	testl	%ecx, %ecx
	je	L226
	movl	-4(%ebx), %eax
	testl	%eax, %eax
	jne	L226
	movl	-8(%ebx), %ecx
	movl	%ecx, 32(%esp)
	cmpl	%edx, %ecx
	jae	L307
	cmpl	$2147418111, %edx
	ja	L251
	movl	-12(%ebx), %eax
	movl	%eax, 40(%esp)
	testl	%eax, %eax
	je	L232
	cmpl	$_freehdrs+4, %eax
	je	L233
	movl	12(%eax), %ecx
	testl	%ecx, %ecx
	je	L233
	movl	16(%eax), %ecx
	testl	%ecx, %ecx
	je	L233
	movl	32(%esp), %ecx
	addl	8(%eax), %ecx
	cmpl	%edx, %ecx
	jae	L308
L233:
	movl	40(%esp), %eax
	cmpl	%eax, 20(%esp)
	je	L309
L232:
	movl	-16(%ebx), %eax
	movl	%eax, 40(%esp)
	testl	%eax, %eax
	je	L235
	cmpl	$_freehdrs+4, %eax
	je	L235
	movl	12(%eax), %ecx
	testl	%ecx, %ecx
	je	L235
	movl	16(%eax), %ecx
	testl	%ecx, %ecx
	je	L235
	movl	32(%esp), %ecx
	addl	8(%eax), %ecx
	cmpl	%edx, %ecx
	jae	L310
L235:
	movl	%edx, %eax
	movl	%edx, 28(%esp)
	call	_searchfree
	movl	28(%esp), %edx
	testl	%eax, %eax
	jne	L311
	movl	20(%esp), %ecx
	addl	$40, %ebp
	cmpl	8(%ecx), %ebp
	jbe	L312
	movl	%edx, %eax
	movl	%edx, 28(%esp)
	call	_extendsbrk
	movl	28(%esp), %edx
	movl	%eax, 60(%esp)
	testl	%eax, %eax
	je	L251
	movl	-12(%ebx), %eax
	cmpl	%eax, _freehdrs
	movl	%edi, %eax
	je	L301
	call	_mv2lastsbrk
	movl	%eax, %edi
	.p2align 4,,7
L230:
	testl	%edi, %edi
	je	L251
L250:
	movl	%edi, %eax
	addl	$16, %eax
	jne	L247
	jmp	L251
	.p2align 4,,7
L254:
	xorl	%eax, %eax
	jmp	L247
	.p2align 4,,7
L305:
	movl	%esi, (%esp)
	call	_malloc
	movl	_hookptr+20, %edx
	testl	%edx, %edx
	jne	L302
	jmp	L268
	.p2align 4,,7
L307:
	movl	%ecx, %eax
	subl	%edx, %eax
	cmpl	$23, %eax
	jbe	L230
L300:
	leal	60(%esp), %eax
	call	_split
	movl	%eax, %edi
	movl	60(%esp), %eax
	call	_mv2freelist
	jmp	L230
L311:
	movl	_freehdrs(,%eax,4), %eax
	movl	%eax, 36(%esp)
	movl	%eax, 60(%esp)
	testl	%eax, %eax
	je	L313
	movl	36(%esp), %eax
	movl	$0, 40(%esp)
	movl	8(%eax), %eax
	movl	%eax, 44(%esp)
	testl	%eax, %eax
	je	L239
	xorl	%ecx, %ecx
L240:
	incl	%ecx
	shrl	%eax
	jne	L240
	movl	%ecx, 40(%esp)
	movl	_freehdrs(,%ecx,4), %ecx
	movl	%ecx, 20(%esp)
L239:
	movl	20(%esp), %ecx
	cmpl	%ecx, 36(%esp)
	jne	L314
	movl	36(%esp), %ecx
	movl	12(%ecx), %eax
	cmpl	$_freehdrs+4, %eax
	je	L315
	movl	40(%esp), %ecx
	movl	%eax, _freehdrs(,%ecx,4)
	movl	$_freehdrs+4, 16(%eax)
L243:
	movl	36(%esp), %eax
	movl	$0, 12(%eax)
L238:
	addl	$40, %ebp
	cmpl	44(%esp), %ebp
	jbe	L316
L244:
	movl	36(%esp), %eax
	movl	32(%esp), %edx
	subl	$16, %edx
	addl	$16, %eax
	movl	%edx, 8(%esp)
	movl	%ebx, 4(%esp)
	movl	%eax, (%esp)
	call	_memcpy
	movl	%edi, %eax
	call	_dofree
	movl	36(%esp), %edi
	jmp	L230
L308:
	movl	%edi, %eax
	movl	%edx, 28(%esp)
	call	_combinehi
	movl	%eax, %edi
	movl	%eax, 60(%esp)
L304:
	movl	8(%edi), %eax
	movl	28(%esp), %edx
	subl	%edx, %eax
	cmpl	$23, %eax
	jbe	L250
	jmp	L300
L310:
	movl	%eax, 60(%esp)
	movl	%edx, 28(%esp)
	call	_extractfree
	movl	60(%esp), %eax
	movl	-8(%ebx), %ecx
	movl	8(%eax), %edx
	addl	%ecx, %edx
	movl	-12(%ebx), %ecx
	movl	%edx, 8(%eax)
	movl	%ecx, 4(%eax)
	testl	%ecx, %ecx
	movl	28(%esp), %edx
	je	L236
	movl	%eax, (%ecx)
L236:
	movl	-8(%ebx), %ecx
	addl	$16, %eax
	subl	$16, %ecx
	movl	%ebx, 4(%esp)
	movl	%ecx, 8(%esp)
	movl	%eax, (%esp)
	movl	%edx, 28(%esp)
	call	_memmove
	movl	60(%esp), %edi
	jmp	L304
L309:
	leal	40(%ebp), %ecx
	movl	32(%esp), %eax
	movl	%ecx, 40(%esp)
	movl	20(%esp), %ecx
	addl	8(%ecx), %eax
	cmpl	%eax, 40(%esp)
	ja	L232
	movl	%edi, %eax
	movl	%edx, 28(%esp)
L301:
	call	_combinehi
	movl	28(%esp), %edx
	movl	%eax, 60(%esp)
	leal	60(%esp), %eax
	call	_split
	movl	%eax, %edi
	movl	60(%esp), %eax
	movl	%eax, _freehdrs
	jmp	L230
L312:
	movl	%edi, %eax
	call	_mv2lastsbrk
	movl	%eax, %edi
	jmp	L230
L316:
	leal	60(%esp), %eax
	call	_split
	movl	%eax, 36(%esp)
	movl	60(%esp), %eax
	call	_mv2freelist
	movl	-8(%ebx), %ecx
	movl	%ecx, 32(%esp)
	jmp	L244
L315:
	movl	40(%esp), %eax
	movl	$0, _freehdrs(,%eax,4)
	jmp	L243
L313:
	movl	8, %eax
	movl	%eax, 44(%esp)
	jmp	L238
L314:
	movl	$11, %edx
	movl	$LC5, %eax
	call	_badcallabort.isra.0
	movl	$1, (%esp)
	call	_exit
	.cfi_endproc
LFE18:
	.p2align 4,,15
	.globl	_calloc
_calloc:
LFB19:
	.cfi_startproc
	pushl	%esi
	.cfi_def_cfa_offset 8
	.cfi_offset 6, -8
	pushl	%ebx
	.cfi_def_cfa_offset 12
	.cfi_offset 3, -12
	subl	$20, %esp
	.cfi_def_cfa_offset 32
	movl	32(%esp), %ecx
	testl	%ecx, %ecx
	je	L318
	orl	$-1, %eax
	xorl	%edx, %edx
	divl	%ecx
	cmpl	36(%esp), %eax
	jbe	L320
L318:
	movl	36(%esp), %esi
	imull	%ecx, %esi
	movl	%esi, (%esp)
	call	_malloc
	movl	%eax, %ebx
	testl	%eax, %eax
	je	L320
	movl	%esi, 8(%esp)
	movl	$0, 4(%esp)
	movl	%eax, (%esp)
	call	_memset
	addl	$20, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 12
	movl	%ebx, %eax
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 8
	popl	%esi
	.cfi_restore 6
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L320:
	.cfi_restore_state
	addl	$20, %esp
	.cfi_def_cfa_offset 12
	xorl	%ebx, %ebx
	movl	%ebx, %eax
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 8
	popl	%esi
	.cfi_restore 6
	.cfi_def_cfa_offset 4
	ret
	.cfi_endproc
LFE19:
	.p2align 4,,15
	.globl	_memalign
_memalign:
LFB21:
	.cfi_startproc
	pushl	%esi
	.cfi_def_cfa_offset 8
	.cfi_offset 6, -8
	pushl	%ebx
	.cfi_def_cfa_offset 12
	.cfi_offset 3, -12
	subl	$20, %esp
	.cfi_def_cfa_offset 32
	movl	36(%esp), %esi
	movl	32(%esp), %ebx
	testl	%esi, %esi
	je	L333
	leal	7(%esi), %eax
	andl	$-8, %eax
	cmpl	$2147418110, %esi
	leal	16(%eax), %edx
	ja	L330
	leal	-1(%ebx), %eax
	cmpl	$65535, %eax
	ja	L330
L339:
	testl	%ebx, %eax
	jne	L330
	cmpl	$8, %ebx
	jbe	L338
	leal	24(%edx,%ebx), %eax
	movl	%eax, (%esp)
	call	_malloc
	movl	%eax, %ecx
	testl	%eax, %eax
	je	L330
	xorl	%edx, %edx
	divl	%ebx
	testl	%edx, %edx
	jne	L330
	movl	%esi, 36(%esp)
	movl	%ecx, 32(%esp)
	addl	$20, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 12
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 8
	popl	%esi
	.cfi_restore 6
	.cfi_def_cfa_offset 4
	jmp	_realloc
	.p2align 4,,7
L333:
	.cfi_restore_state
	leal	-1(%ebx), %eax
	movl	$24, %edx
	cmpl	$65535, %eax
	jbe	L339
L330:
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
L338:
	.cfi_restore_state
	movl	%edx, 32(%esp)
	addl	$20, %esp
	.cfi_def_cfa_offset 12
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 8
	popl	%esi
	.cfi_restore 6
	.cfi_def_cfa_offset 4
	jmp	_malloc
	.cfi_endproc
LFE21:
	.p2align 4
_sysquery:
	.byte	16
	.byte	-1
	.byte	8
	.byte	16
	.byte	12
	.byte	4
	.byte	0
	.byte	20
	.long	_freehdrs+4
	.long	_sbrkbgn
	.long	_sethook
.lcomm _freehdrs,128,16
.lcomm _sbrkbgn,400,16
.lcomm _hookptr,24,16
.lcomm _lastsbrkbgn,4,4
	.ident	"GCC: (GNU) 4.7.4"
