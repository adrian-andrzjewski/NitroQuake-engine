	.file	"xstat.c"
	.section .text
	.p2align 4,,15
	.globl	__file_time_stamp
__file_time_stamp:
LFB21:
	.cfi_startproc
	pushl	%edi
	.cfi_def_cfa_offset 8
	.cfi_offset 7, -8
	pushl	%ebx
	.cfi_def_cfa_offset 12
	.cfi_offset 3, -12
	subl	$68, %esp
	.cfi_def_cfa_offset 80
	xorl	%eax, %eax
	movl	$11, %ecx
	leal	20(%esp), %ebx
	movl	80(%esp), %edx
	movl	%ebx, %edi
	rep stosl
	movl	%edx, %eax
	movl	%ebx, (%esp)
	andl	$31, %eax
	movl	$-1, 52(%esp)
	addl	%eax, %eax
	movl	%eax, 20(%esp)
	movl	%edx, %eax
	shrl	$5, %eax
	andl	$63, %eax
	movl	%eax, 24(%esp)
	movl	%edx, %eax
	shrl	$11, %eax
	andl	$31, %eax
	movl	%eax, 28(%esp)
	movl	%edx, %eax
	shrl	$16, %eax
	andl	$31, %eax
	movl	%eax, 32(%esp)
	movl	%edx, %eax
	shrl	$21, %eax
	shrl	$25, %edx
	andl	$15, %eax
	decl	%eax
	addl	$80, %edx
	movl	%eax, 36(%esp)
	movl	%edx, 40(%esp)
	call	_mktime
	addl	$68, %esp
	.cfi_def_cfa_offset 12
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 8
	popl	%edi
	.cfi_restore 7
	.cfi_def_cfa_offset 4
	ret
	.cfi_endproc
LFE21:
	.p2align 4,,15
	.globl	__getftime
__getftime:
LFB22:
	.cfi_startproc
	subl	$92, %esp
	.cfi_def_cfa_offset 96
	movl	96(%esp), %eax
	movl	$33, (%esp)
	movw	%ax, 44(%esp)
	leal	28(%esp), %eax
	movl	%eax, 4(%esp)
	movw	$22272, 56(%esp)
	call	___dpmi_int
	testb	$1, 60(%esp)
	jne	L8
	movl	48(%esp), %eax
	movl	52(%esp), %edx
	sall	$16, %eax
	andl	$65535, %edx
	addl	%eax, %edx
	movl	100(%esp), %eax
	movl	%edx, (%eax)
	xorl	%eax, %eax
L5:
	addl	$92, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L8:
	.cfi_restore_state
	movl	56(%esp), %eax
	andl	$65535, %eax
	movl	%eax, (%esp)
	call	___doserr_to_errno
	movl	%eax, _errno
	orl	$-1, %eax
	jmp	L5
	.cfi_endproc
LFE22:
	.p2align 4,,15
	.globl	__get_cached_blksize
__get_cached_blksize:
LFB23:
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
	subl	$64, %esp
	.cfi_def_cfa_offset 80
	movl	___bss_count, %eax
	movl	80(%esp), %ebx
	cmpl	%eax, _cache_blksize_count
	je	L10
	movl	$_cache_blksize, %edx
	movl	%eax, _cache_blksize_count
	movl	$32, %ecx
	xorl	%eax, %eax
	movl	%edx, %edi
	rep stosl
	movl	$512, _cache_blksize+4
	movl	$512, _cache_blksize
L10:
	movsbl	(%ebx), %eax
	leal	-97(%eax), %edx
	leal	-97(%eax), %esi
	cmpb	$25, %dl
	jbe	L12
	movl	%eax, %esi
	subl	$65, %esi
	js	L13
	cmpl	$31, %esi
	jg	L13
L12:
	movl	_cache_blksize(,%esi,4), %eax
	testl	%eax, %eax
	je	L19
L14:
	addl	$64, %esp
	.cfi_remember_state
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
	.p2align 4,,7
L19:
	.cfi_restore_state
	movl	%esi, (%esp)
	call	__is_remote_drive
	testl	%eax, %eax
	je	L16
	movl	$4096, _cache_blksize(,%esi,4)
	addl	$64, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 16
	movl	$4096, %eax
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
L16:
	.cfi_restore_state
	leal	24(%esp), %eax
	movl	%ebx, (%esp)
	movl	%eax, 4(%esp)
	call	___statfs
	testl	%eax, %eax
	jne	L17
	movl	28(%esp), %eax
	movl	%eax, _cache_blksize(,%esi,4)
	jmp	L14
	.p2align 4,,7
L13:
	movl	$21, _errno
	orl	$-1, %eax
	jmp	L14
L17:
	orl	$-1, %eax
	jmp	L14
	.cfi_endproc
LFE23:
	.p2align 4,,15
	.globl	__invent_inode
__invent_inode:
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
	subl	$44, %esp
	.cfi_def_cfa_offset 64
	movl	___bss_count, %eax
	movl	64(%esp), %ebx
	movl	68(%esp), %esi
	cmpl	%eax, _xstat_count
	je	L21
	movl	$_name_list.3206, %edx
	movl	%eax, _xstat_count
	movl	$256, %ecx
	xorl	%eax, %eax
	movl	%edx, %edi
	movl	$268435457, _inode_count.3207
	rep stosl
L21:
	testl	%ebx, %ebx
	je	L53
	movsbl	(%ebx), %ecx
	testb	%cl, %cl
	je	L24
	movb	1(%ebx), %dl
	cmpb	$58, %dl
	je	L54
L25:
	movl	%ebx, %eax
	xorl	%edi, %edi
	jmp	L27
	.p2align 4,,7
L28:
	movsbl	%dl, %ecx
	movb	1(%eax), %dl
L27:
	addl	%ecx, %edi
	incl	%eax
	testb	%dl, %dl
	jne	L28
	andl	$255, %edi
	movl	_name_list.3206(,%edi,4), %ebp
	testl	%ebp, %ebp
	jne	L50
	jmp	L57
	.p2align 4,,7
L30:
	movl	0(%ebp), %eax
	testl	%eax, %eax
	je	L29
	movl	%eax, %ebp
L50:
	movl	4(%ebp), %eax
	movl	%ebx, (%esp)
	movl	%eax, 4(%esp)
	call	_strcmp
	testl	%eax, %eax
	jne	L30
	cmpl	%esi, 8(%ebp)
	jne	L30
	movl	72(%esp), %eax
	cmpl	%eax, 12(%ebp)
	jne	L30
	movl	16(%ebp), %eax
	jmp	L46
	.p2align 4,,7
L24:
	movl	_inode_count.3207, %eax
	leal	1(%eax), %edx
	movl	%edx, _inode_count.3207
L46:
	addl	$44, %esp
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
L57:
	.cfi_restore_state
	xorl	%ebp, %ebp
	.p2align 4,,7
L29:
	movl	$20, (%esp)
	call	_malloc
	movl	%eax, %edx
	testl	%eax, %eax
	je	L53
	movl	$0, (%edx)
	movl	%ebx, (%esp)
	movl	%edx, 28(%esp)
	call	_strlen
	incl	%eax
	movl	%eax, (%esp)
	call	_malloc
	movl	28(%esp), %edx
	testl	%eax, %eax
	movl	%eax, 4(%edx)
	je	L56
	movl	%ebx, 4(%esp)
	movl	%eax, (%esp)
	movl	%edx, 28(%esp)
	call	_strcpy
	movl	28(%esp), %edx
	movl	72(%esp), %eax
	testl	%ebp, %ebp
	movl	%eax, 12(%edx)
	movl	_inode_count.3207, %eax
	movl	%esi, 8(%edx)
	movl	%eax, 16(%edx)
	je	L34
	movl	%edx, 0(%ebp)
L35:
	leal	1(%eax), %edx
	movl	%edx, _inode_count.3207
	jmp	L46
L56:
	movl	%edx, (%esp)
	call	_free
	.p2align 4,,7
L53:
	addl	$44, %esp
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
	.p2align 4,,7
L54:
	.cfi_restore_state
	movb	2(%ebx), %al
	cmpb	$47, %al
	je	L41
	cmpb	$92, %al
	jne	L25
L41:
	movsbl	3(%ebx), %ecx
	movl	$1, %eax
	testb	%cl, %cl
	je	L46
	movb	4(%ebx), %dl
	addl	$3, %ebx
	jmp	L25
L34:
	movl	%edx, _name_list.3206(,%edi,4)
	jmp	L35
	.cfi_endproc
LFE24:
	.section .data
	.p2align 2
_cache_blksize_count:
	.long	-1
.lcomm _cache_blksize,128,16
	.p2align 2
_xstat_count:
	.long	-1
	.p2align 2
_inode_count.3207:
	.long	268435457
.lcomm _name_list.3206,1024,16
	.ident	"GCC: (GNU) 4.7.4"
