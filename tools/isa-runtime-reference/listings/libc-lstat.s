	.file	"lstat.c"
	.section .text
LC0:
	.ascii "LFN32\0"
LC1:
	.ascii "FAT\0"
	.p2align 4,,15
_stat_assist:
LFB29:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%edi
	pushl	%esi
	pushl	%ebx
	.cfi_offset 7, -12
	.cfi_offset 6, -16
	.cfi_offset 3, -20
	movl	%edx, %ebx
	subl	$1036, %esp
	movl	%edx, %edi
	movl	%eax, %esi
	movw	$0, __djstat_fail_bits
	movl	$48, %edx
	testb	$1, %bl
	jne	L203
	testl	$2, %edi
	jne	L204
L3:
	movl	%edx, %ecx
	xorl	%eax, %eax
	shrl	$2, %ecx
	rep stosl
	testb	$2, %dl
	je	L4
	movw	$0, (%edi)
	addl	$2, %edi
L4:
	andl	$1, %edx
	je	L5
	movb	$0, (%edi)
L5:
	call	_getuid
	movl	%eax, 40(%ebx)
	call	_getgid
	movl	$1, 28(%ebx)
	movl	%eax, 12(%ebx)
	leal	-574(%ebp), %eax
	movl	%eax, 4(%esp)
	movl	%esi, (%esp)
	call	__fixpath
	leal	-574(%ebp), %edx
	movl	%edx, (%esp)
	call	__get_cached_blksize
	movl	%eax, 36(%ebx)
	incl	%eax
	je	L201
	xorl	%eax, %eax
	leal	-834(%ebp), %ecx
	movb	-574(%ebp), %al
	movl	%ecx, 4(%esp)
	movl	%esi, (%esp)
	movl	%ecx, -956(%ebp)
	movb	___dj_ctype_toupper+1(%eax), %al
	andl	$255, %eax
	leal	-65(%eax), %edi
	call	__truename
	testl	%eax, %eax
	je	L8
L196:
L9:
	movb	-832(%ebp), %al
	cmpb	$47, %al
	je	L205
	movb	-834(%ebp), %dl
	leal	-65(%edx), %ecx
	cmpb	$57, %cl
	ja	L15
	cmpb	$58, -833(%ebp)
	je	L206
L15:
	leal	-314(%ebp), %esi
	leal	-574(%ebp), %edx
	movl	$55, 8(%esp)
	movl	%esi, 4(%esp)
	movl	%edx, (%esp)
	movl	%esi, -960(%ebp)
	call	___findfirst
	testl	%eax, %eax
	jne	L19
	movw	-290(%ebp), %dx
	movl	-292(%ebp), %eax
	sall	$16, %edx
	andl	$65535, %eax
	addl	%edx, %eax
	testb	$1, __djstat_flags
	movl	%eax, -964(%ebp)
	je	L207
L21:
	movl	20(%ebx), %eax
	movl	-288(%ebp), %edx
	movl	%eax, %ecx
	movl	%edx, 32(%ebx)
	orl	$292, %ecx
	movl	%ecx, 20(%ebx)
	movb	-293(%ebp), %cl
	testb	$7, %cl
	jne	L53
	orl	$420, %eax
	movl	%eax, 20(%ebx)
L53:
	cmpw	$1330, __os_trueversion
	je	L208
L54:
	cmpb	$64, %cl
	je	L55
	andl	$16, %ecx
	je	L61
	orl	$12361, 20(%ebx)
L62:
	movswl	%di, %eax
	movl	-964(%ebp), %edx
	movl	%eax, 8(%ebx)
	movl	%edx, (%esp)
	movl	$LC0, %edi
	call	__file_time_stamp
	movl	$6, %ecx
	movl	%eax, 4(%ebx)
	movl	%eax, 24(%ebx)
	movl	%eax, (%ebx)
	movl	-960(%ebp), %esi
	repe cmpsb
	jne	L83
	movl	-304(%ebp), %edx
	movw	-306(%ebp), %ax
	sall	$16, %edx
	andl	$65535, %eax
	orl	%edx, %eax
	jne	L209
L84:
	movl	-300(%ebp), %eax
	movw	-302(%ebp), %dx
	sall	$16, %eax
	andl	$65535, %edx
	orl	%edx, %eax
	cmpl	-964(%ebp), %eax
	ja	L210
L83:
	movl	20(%ebx), %eax
	andl	$61440, %eax
	cmpl	$12288, %eax
	je	L86
L200:
	xorl	%eax, %eax
L187:
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
L19:
	.cfi_restore_state
	testb	$8, __djstat_fail_bits
	je	L68
	cmpl	$38, _errno
	je	L211
L201:
	leal	-12(%ebp), %esp
	orl	$-1, %eax
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
L68:
	.cfi_restore_state
	cmpb	$0, -571(%ebp)
	jne	L70
	movb	-572(%ebp), %al
	cmpb	$92, %al
	je	L111
	cmpb	$47, %al
	je	L111
L70:
	leal	-574(%ebp), %esi
	movl	_errno, %ecx
	movl	%esi, (%esp)
	movl	%ecx, -964(%ebp)
	call	_strlen
	movl	$8, 8(%esp)
	movl	%eax, -968(%ebp)
	leal	-314(%ebp), %eax
	movl	%eax, 4(%esp)
	movl	%esi, (%esp)
	call	___findfirst
	testl	%eax, %eax
	jne	L75
	leal	-284(%ebp), %esi
	movl	-968(%ebp), %ecx
	decl	%ecx
	movl	%esi, (%esp)
	movl	%ecx, -980(%ebp)
	movl	%esi, -972(%ebp)
	call	_strlen
	leal	-1(%eax), %edx
	cmpl	%edx, -980(%ebp)
	jl	L76
	movl	%edx, %ecx
	subl	$0, %ecx
	js	L76
	movl	-980(%ebp), %esi
	subl	$0, %esi
	js	L76
	xorl	%ecx, %ecx
	movl	-980(%ebp), %esi
	movb	-284(%ebp,%edx), %cl
	movl	%ecx, -976(%ebp)
	xorl	%ecx, %ecx
	movb	-574(%ebp,%esi), %cl
	movl	-976(%ebp), %esi
	movb	___dj_ctype_toupper+1(%ecx), %cl
	cmpb	%cl, ___dj_ctype_toupper+1(%esi)
	jne	L75
	movl	-968(%ebp), %esi
	leal	-574(%ebp), %ecx
	subl	%eax, %esi
	movw	%di, -968(%ebp)
	movl	%esi, %eax
	movl	%ebx, -976(%ebp)
	addl	%ecx, %eax
	movl	-980(%ebp), %esi
	movl	%eax, %edi
	jmp	L191
	.p2align 4,,7
L212:
	movl	%edx, %ebx
	subl	$0, %ebx
	js	L194
	movl	-972(%ebp), %eax
	xorl	%ecx, %ecx
	movb	(%eax,%edx), %cl
	xorl	%eax, %eax
	movb	(%edi,%edx), %al
	movb	___dj_ctype_toupper+1(%eax), %bl
	cmpb	%bl, ___dj_ctype_toupper+1(%ecx)
	jne	L75
L191:
	decl	%edx
	decl	%esi
	jns	L212
L194:
	movl	-968(%ebp), %edi
	movl	%esi, -980(%ebp)
	movl	-976(%ebp), %ebx
L76:
	testl	%edx, %edx
	jns	L75
	movl	-980(%ebp), %esi
	cmpb	$47, -574(%ebp,%esi)
	jne	L75
	movl	$20772, 20(%ebx)
	movl	$1, 16(%ebx)
	movl	$0, 32(%ebx)
L73:
	movw	-290(%ebp), %dx
	movl	-292(%ebp), %eax
	sall	$16, %edx
	andl	$65535, %eax
	addl	%edx, %eax
	movl	%eax, -964(%ebp)
	jmp	L62
	.p2align 4,,7
L86:
	testb	$8, __djstat_flags
	jne	L200
	leal	-574(%ebp), %ecx
	movl	%ecx, (%esp)
	call	_strlen
	leal	-574(%ebp), %ecx
	movl	%eax, %esi
	movb	-575(%ebp,%eax), %dl
	leal	40(%eax), %eax
	andl	$-16, %eax
	movb	%dl, -964(%ebp)
	subl	%eax, %esp
	leal	1(%esi), %eax
	leal	35(%esp), %edx
	movl	%eax, 8(%esp)
	andl	$-16, %edx
	movl	%ecx, 4(%esp)
	movl	%edx, (%esp)
	movl	%edx, -1008(%ebp)
	call	_memcpy
	movl	-1008(%ebp), %edx
	cmpb	$47, -964(%ebp)
	je	L213
	addl	%edx, %esi
	movl	$707668527, (%esi)
	movb	$0, 4(%esi)
L89:
	movl	32(%ebx), %esi
	testl	%esi, %esi
	je	L90
L92:
	movl	$0, -968(%ebp)
L91:
	leal	-314(%ebp), %esi
	movl	$55, 8(%esp)
	movl	%esi, 4(%esp)
	movl	%edx, (%esp)
	call	___findfirst
	testl	%eax, %eax
	jne	L109
	movl	%ebx, -972(%ebp)
	movl	$0, -964(%ebp)
	xorl	%edi, %edi
	xorl	%esi, %esi
	movl	-968(%ebp), %ebx
	jmp	L98
	.p2align 4,,7
L95:
	movb	-293(%ebp), %al
	incl	%esi
	andl	$16, %eax
	cmpb	$1, %al
	sbbl	$-1, %edi
	testl	%ebx, %ebx
	jne	L214
L96:
	leal	-314(%ebp), %edx
	movl	%edx, (%esp)
	call	___findnext
	testl	%eax, %eax
	jne	L215
L98:
	cmpb	$46, -284(%ebp)
	jne	L95
	movb	-283(%ebp), %al
	testb	%al, %al
	je	L96
	cmpb	$46, %al
	jne	L95
	cmpb	$0, -282(%ebp)
	je	L96
	jmp	L95
	.p2align 4,,7
L206:
	cmpb	$92, %al
	jne	L15
	andl	$255, %edx
	xorl	%eax, %eax
	movb	___dj_ctype_toupper+1(%edx), %al
	leal	-65(%eax), %edi
	jmp	L15
	.p2align 4,,7
L209:
	movl	%eax, (%esp)
	call	__file_time_stamp
	movl	%eax, 4(%ebx)
	jmp	L84
	.p2align 4,,7
L210:
	movl	%eax, (%esp)
	call	__file_time_stamp
	movl	%eax, (%ebx)
	jmp	L83
	.p2align 4,,7
L211:
	movl	$21, _errno
	orl	$-1, %eax
	jmp	L187
	.p2align 4,,7
L111:
	orl	$12781, 20(%ebx)
	movl	$1, 16(%ebx)
	movl	$0, -288(%ebp)
	movl	$0, -964(%ebp)
	testb	$16, __djstat_flags
	jne	L62
	leal	-574(%ebp), %esi
	movl	%esi, 4(%esp)
	leal	-888(%ebp), %esi
	movl	%esi, (%esp)
	call	_stpcpy
	movl	$2764330, (%eax)
	leal	-314(%ebp), %eax
	movl	$8, 8(%esp)
	movl	%eax, 4(%esp)
	movl	%esi, (%esp)
	call	___findfirst
	testl	%eax, %eax
	jne	L72
	.p2align 4,,7
L199:
	testb	$6, -293(%ebp)
	je	L73
	leal	-314(%ebp), %edx
	movl	%edx, (%esp)
	call	___findnext
	testl	%eax, %eax
	je	L199
L72:
	orw	$32, __djstat_fail_bits
	movl	$0, -964(%ebp)
	jmp	L62
	.p2align 4,,7
L75:
	cmpl	$38, -964(%ebp)
	je	L81
	movl	-964(%ebp), %edx
	movl	%edx, _errno
	jmp	L201
	.p2align 4,,7
L214:
	leal	-284(%ebp), %eax
	movl	%eax, (%esp)
	call	__is_DOS83
	testl	%eax, %eax
	jne	L96
	leal	-284(%ebp), %edx
	movl	%edx, (%esp)
	call	_strlen
	movl	-964(%ebp), %ecx
	leal	12(%eax), %edx
	movl	$1321528399, %eax
	mull	%edx
	shrl	$2, %edx
	addl	%edx, %ecx
	movl	%ecx, -964(%ebp)
	jmp	L96
	.p2align 4,,7
L207:
	movb	-574(%ebp), %al
	leal	-940(%ebp), %esi
	andl	$31, %eax
	movl	%esi, 4(%esp)
	movl	$33, (%esp)
	movw	$17425, -912(%ebp)
	movb	%al, -924(%ebp)
	movw	$2161, -916(%ebp)
	call	___dpmi_int
	testb	$1, -908(%ebp)
	jne	L22
	cmpw	$0, -912(%ebp)
	jne	L22
	movl	__go32_info_block+12, %eax
	leal	-574(%ebp), %ecx
	movl	%eax, %edx
	movl	%ecx, (%esp)
	shrl	$4, %edx
	andl	$15, %eax
	movw	%dx, -904(%ebp)
	movw	$17421, -912(%ebp)
	movw	$2161, -916(%ebp)
	movw	$1, -924(%ebp)
	movw	%ax, -920(%ebp)
	call	__put_path
	movl	%esi, 4(%esp)
	movl	$33, (%esp)
	call	___dpmi_int
	testb	$1, -908(%ebp)
	jne	L22
	movl	-920(%ebp), %edx
	movl	-912(%ebp), %eax
	sall	$16, %edx
	andl	$65535, %eax
	addl	%edx, %eax
	movl	%eax, 16(%ebx)
	cmpl	$0, %eax
	jg	L21
	jne	L99
L24:
	movw	__djstat_fail_bits, %ax
L26:
	orl	$16, %eax
	movl	-964(%ebp), %edx
	movw	%ax, __djstat_fail_bits
	leal	-834(%ebp), %ecx
	movl	-288(%ebp), %eax
	movl	%edx, 4(%esp)
	movl	%eax, 8(%esp)
	movl	%ecx, (%esp)
	call	__invent_inode
	movl	%eax, 16(%ebx)
	jmp	L21
	.p2align 4,,7
L208:
	testl	%edx, %edx
	jne	L54
	testb	$8, __djstat_fail_bits
	je	L54
	cmpw	$0, -292(%ebp)
	jne	L54
	cmpw	$33, -290(%ebp)
	jne	L54
	cmpw	$0, -306(%ebp)
	jne	L54
	cmpw	$33, -304(%ebp)
	jne	L54
	cmpw	$0, -302(%ebp)
	jne	L54
	cmpw	$33, -300(%ebp)
	jne	L54
	leal	-314(%ebp), %esi
	movl	$LC0, 4(%esp)
	movl	%esi, (%esp)
	movb	%cl, -1008(%ebp)
	call	_strcmp
	movb	-1008(%ebp), %cl
	testl	%eax, %eax
	jne	L54
	cmpb	$32, %cl
	jne	L54
	movb	$64, -293(%ebp)
	.p2align 4,,7
L55:
	leal	-834(%ebp), %eax
	movl	%eax, (%esp)
	call	_strlen
	leal	-832(%ebp), %ecx
	leal	-835(%ebp,%eax), %edx
	cmpl	%ecx, %edx
	ja	L198
	jmp	L57
	.p2align 4,,7
L216:
	decl	%edx
	cmpl	%ecx, %edx
	je	L57
L198:
	cmpb	$92, (%edx)
	jne	L216
	cmpb	$58, -833(%ebp)
	jne	L61
	movl	-956(%ebp), %esi
	movl	%edx, 4(%esp)
	subl	%edx, %esi
	movl	%ecx, (%esp)
	leal	1(%eax,%esi), %eax
	movl	%eax, 8(%esp)
	call	_memmove
	jmp	L60
L57:
	cmpb	$58, -833(%ebp)
	je	L60
	.p2align 4,,7
L61:
	leal	-888(%ebp), %eax
	leal	-574(%ebp), %edx
	movl	$1, 8(%esp)
	movl	%eax, 4(%esp)
	movl	%edx, (%esp)
	movl	_errno, %esi
	call	___readlink
	incl	%eax
	je	L63
	orl	$32768, 20(%ebx)
	movl	%esi, _errno
	jmp	L62
	.p2align 4,,7
L203:
	leal	1(%ebx), %edi
	movb	$0, (%ebx)
	movb	$47, %dl
	testl	$2, %edi
	je	L3
	.p2align 4,,7
L204:
	movw	$0, (%edi)
	subl	$2, %edx
	addl	$2, %edi
	jmp	L3
	.p2align 4,,7
L215:
	movl	-972(%ebp), %ebx
	leal	2(%edi), %eax
L94:
	movl	32(%ebx), %edx
	movl	%eax, 28(%ebx)
	testl	%edx, %edx
	jne	L200
	movl	-964(%ebp), %eax
	addl	%eax, %esi
	sall	$5, %esi
	movl	%esi, 32(%ebx)
	jmp	L200
	.p2align 4,,7
L8:
	leal	-834(%ebp), %edx
	leal	-574(%ebp), %ecx
	movl	%edx, 4(%esp)
	movl	%ecx, (%esp)
	call	__truename
	testl	%eax, %eax
	jne	L196
	leal	-834(%ebp), %edx
	leal	-574(%ebp), %ecx
	movl	%ebx, %esi
	.p2align 4,,7
L10:
	movb	(%ecx), %al
	incl	%ecx
	leal	-98(%eax), %ebx
	cmpb	$23, %bl
	ja	L17
	subl	$32, %eax
	movb	%al, (%edx)
L16:
	incl	%edx
	jmp	L10
	.p2align 4,,7
L205:
	movl	$0, -964(%ebp)
L60:
	leal	-888(%ebp), %esi
	leal	-831(%ebp), %eax
	movl	$8, 8(%esp)
	movl	%eax, 4(%esp)
	movl	%esi, (%esp)
	call	_strncpy
	leal	-827(%ebp), %eax
	movl	%esi, 4(%esp)
	movl	%eax, (%esp)
	movb	$0, -880(%ebp)
	movl	$1683765824, -834(%ebp)
	movl	$6059621, -830(%ebp)
	call	_strcpy
	movl	%esi, %edx
L12:
	movl	(%edx), %ecx
	addl	$4, %edx
	leal	-16843009(%ecx), %eax
	xorl	$-1, %ecx
	andl	%ecx, %eax
	andl	$-2139062144, %eax
	je	L12
	testl	$32896, %eax
	jne	L14
	shrl	$16, %eax
	addl	$2, %edx
L14:
	addb	%al, %al
	movl	%esi, %eax
	sbbl	$3, %edx
	leal	-834(%ebp), %esi
	subl	%edx, %eax
	movl	$_blanks_8, 4(%esp)
	addl	$8, %eax
	movl	%esi, (%esp)
	movl	%eax, 8(%esp)
	call	_strncat
	movl	$0, 8(%esp)
	movl	$0, 4(%esp)
	movl	%esi, (%esp)
	movb	$0, -819(%ebp)
	call	__invent_inode
	orl	$8612, 20(%ebx)
	movl	%eax, 16(%ebx)
	movl	$-1, 8(%ebx)
	movl	$0, (%esp)
	call	_time
	movl	-964(%ebp), %edx
	movl	%eax, 24(%ebx)
	movl	%eax, (%ebx)
	movl	%edx, (%esp)
	call	__file_time_stamp
	movl	%eax, 4(%ebx)
	xorl	%eax, %eax
	jmp	L187
	.p2align 4,,7
L17:
	movb	%al, (%edx)
	testb	%al, %al
	je	L217
	cmpb	$47, %al
	jne	L16
	movb	$92, (%edx)
	incl	%edx
	jmp	L10
	.p2align 4,,7
L81:
	movl	$22, _errno
	jmp	L201
	.p2align 4,,7
L63:
	leal	-284(%ebp), %eax
	movl	$46, 4(%esp)
	movl	%eax, (%esp)
	call	_strrchr
	movw	__djstat_flags, %dx
	andl	$6, %edx
	movl	%esi, _errno
	cmpw	$6, %dx
	je	L62
	cmpl	$1, %eax
	leal	-574(%ebp), %ecx
	sbbl	$-1, %eax
	movl	$-1, 4(%esp)
	movl	%eax, 8(%esp)
	movl	%ecx, (%esp)
	call	__is_executable
	testl	%eax, %eax
	je	L62
	orl	$73, 20(%ebx)
	jmp	L62
	.p2align 4,,7
L90:
	movl	$0, (%esp)
	movl	%edx, -1008(%ebp)
	call	__use_lfn
	movl	-1008(%ebp), %edx
	testb	%al, %al
	je	L92
	leal	-574(%ebp), %eax
	leal	-888(%ebp), %esi
	movl	%esi, 12(%esp)
	movl	$0, 8(%esp)
	movl	$0, 4(%esp)
	movl	%eax, (%esp)
	call	__get_volume_info
	movl	$0, -968(%ebp)
	testb	$64, %ah
	movl	-1008(%ebp), %edx
	je	L91
	movl	$4, %ecx
	movl	$LC1, %edi
	repe cmpsb
	sete	%cl
	andl	$255, %ecx
	movl	%ecx, -968(%ebp)
	jmp	L91
	.p2align 4,,7
L22:
	movl	$-1, 16(%ebx)
L99:
	movswl	%di, %eax
	movl	%eax, (%esp)
	call	__is_remote_drive
	testl	%eax, %eax
	jne	L24
	leal	-284(%ebp), %ecx
	movw	__go32_info_block+26, %si
	movl	%ecx, (%esp)
	movl	$46, 4(%esp)
/APP
# 36 "c:/djgpp/include/sys/segments.h" 1
	movw %ds,%dx
# 0 "" 2
/NO_APP
	movw	%si, -976(%ebp)
	movw	%dx, -994(%ebp)
	movl	%ecx, -972(%ebp)
	call	_strchr
	movl	-972(%ebp), %esi
	movl	%eax, -988(%ebp)
	movl	%esi, (%esp)
	call	_strlen
	movl	-988(%ebp), %edx
	testl	%edx, %edx
	je	L27
	movl	-988(%ebp), %edx
	decl	%eax
	subl	%esi, %edx
	subl	%edx, %eax
	movl	%edx, -984(%ebp)
	movl	%eax, -980(%ebp)
L28:
	movw	_init_dirent_table_bits, %ax
	movl	___bss_count, %edx
	orw	__djstat_fail_bits, %ax
	cmpl	%edx, _stat_count
	movw	%ax, __djstat_fail_bits
	je	L29
	movl	%edx, _stat_count
	movl	$0, _dirent_count
L30:
	movw	__os_trueversion, %dx
	movl	%edx, %ecx
	shrw	$8, %cx
	cmpb	$9, %dl
	ja	L218
L110:
	cmpw	$4, %cx
	je	L105
	jbe	L219
	movw	$435, -968(%ebp)
	movl	$23814, %edx
L32:
	andl	$-3, %eax
	movl	$33, (%esp)
	movw	%ax, __djstat_fail_bits
	leal	-888(%ebp), %eax
	movl	%eax, 4(%esp)
	movl	%ecx, -1008(%ebp)
	movw	%dx, -860(%ebp)
	call	___dpmi_int
	testb	$1, -856(%ebp)
	movl	-1008(%ebp), %ecx
	jne	L220
	movw	__djstat_fail_bits, %si
	movl	%esi, %edx
	movw	%si, -1000(%ebp)
	andl	$-2, %edx
	cmpw	$4, %cx
	movw	%dx, __djstat_fail_bits
	je	L221
	movl	-852(%ebp), %eax
	movl	-884(%ebp), %edx
	andl	$65535, %eax
	andl	$65535, %edx
	sall	$4, %eax
	movl	$1, _dirent_count
	addl	%edx, %eax
	movl	-968(%ebp), %edx
	andl	$65535, %edx
	movl	$_dirent_place, _dirent_table
	addl	%edx, %eax
	movl	%eax, _dirent_place
L43:
	movw	__djstat_fail_bits, %ax
	movl	_dirent_count, %ecx
L31:
	movl	%eax, %edx
	andl	$-9, %edx
	cmpl	$-1, %ecx
	movw	%dx, _init_dirent_table_bits
	je	L44
	movl	_dirent_table, %edx
/APP
# 169 "c:/djgpp/include/libc/farptrgs.h" 1
	movw -976(%ebp),%gs
# 0 "" 2
/NO_APP
	testl	%ecx, %ecx
	je	L52
	movl	-976(%ebp), %eax
	movl	%ecx, -968(%ebp)
	movl	-988(%ebp), %ecx
	movw	-994(%ebp), %si
	andl	$65535, %eax
	incl	%ecx
	movw	%di, -994(%ebp)
	movl	%ebx, -992(%ebp)
	andl	$65535, %esi
	movl	%eax, -976(%ebp)
	movl	%ecx, -988(%ebp)
	movl	%edx, %ebx
	movl	-972(%ebp), %edi
	.p2align 4,,7
L51:
	leal	-888(%ebp), %eax
	movl	$32, 16(%esp)
	movl	%eax, 12(%esp)
	movl	%esi, 8(%esp)
	movl	(%ebx), %eax
	movl	-976(%ebp), %edx
	movl	%eax, 4(%esp)
	movl	%edx, (%esp)
	call	___movedata
	movl	-984(%ebp), %ecx
	leal	-888(%ebp), %eax
	movl	%ecx, 8(%esp)
	movl	%edi, 4(%esp)
	movl	%eax, (%esp)
	call	_strncmp
	testl	%eax, %eax
	jne	L46
	movl	-980(%ebp), %eax
	testl	%eax, %eax
	je	L197
	movl	-980(%ebp), %edx
	movl	-988(%ebp), %ecx
	leal	-880(%ebp), %eax
	movl	%edx, 8(%esp)
	movl	%ecx, 4(%esp)
	movl	%eax, (%esp)
	call	_strncmp
	testl	%eax, %eax
	je	L197
L46:
	addl	$4, %ebx
	decl	-968(%ebp)
	jne	L51
	movw	-994(%ebp), %di
	movl	-992(%ebp), %ebx
L52:
	movw	__djstat_fail_bits, %ax
	orl	$4, %eax
L44:
	movl	$0, 16(%ebx)
	jmp	L26
	.p2align 4,,7
L213:
	movl	$2764330, (%edx,%esi)
	jmp	L89
L217:
	movl	%esi, %ebx
	orw	$8, __djstat_fail_bits
	jmp	L15
L109:
	movl	$2, %eax
	movl	$0, -964(%ebp)
	xorl	%esi, %esi
	jmp	L94
L197:
	movl	%ebx, %edx
	movw	-994(%ebp), %di
	movl	-992(%ebp), %ebx
	movl	(%edx), %eax
	addl	$26, %eax
/APP
# 229 "c:/djgpp/include/libc/farptrgs.h" 1
	.byte 0x65
	movw (%eax),%ax
# 0 "" 2
/NO_APP
	andl	$65535, %eax
	movl	%eax, 16(%ebx)
	testl	%eax, %eax
	je	L24
	xorl	%eax, %eax
	xorl	%edx, %edx
	movb	-574(%ebp), %al
	movb	-834(%ebp), %dl
	movb	___dj_ctype_toupper+1(%eax), %cl
	cmpb	%cl, ___dj_ctype_toupper+1(%edx)
	je	L21
	cmpb	$58, -833(%ebp)
	jne	L21
	cmpb	$92, -832(%ebp)
	jne	L21
	cmpb	$0, -831(%ebp)
	jne	L21
	movl	$1, 16(%ebx)
	jmp	L21
L29:
	movl	_dirent_count, %ecx
	testl	%ecx, %ecx
	jne	L31
	jmp	L30
L27:
	movl	%eax, -984(%ebp)
	movl	$0, -980(%ebp)
	jmp	L28
L220:
	orw	$1, __djstat_fail_bits
	movl	$-1, _dirent_count
L34:
	movw	__djstat_fail_bits, %ax
	movl	%eax, %edx
	andl	$-9, %edx
	movw	%dx, _init_dirent_table_bits
	jmp	L44
L218:
	cmpw	$3, %cx
	jne	L110
	movw	$423, -968(%ebp)
	movl	$23814, %edx
	jmp	L32
L219:
	orl	$2, %eax
	movl	$-1, _dirent_count
	movw	%ax, __djstat_fail_bits
	jmp	L34
L105:
	movw	$435, -968(%ebp)
	movl	$23819, %edx
	jmp	L32
L221:
	movl	-852(%ebp), %ecx
	movl	-884(%ebp), %eax
	andl	$65535, %ecx
	andl	$65535, %eax
	sall	$4, %ecx
	addl	%ecx, %eax
	movw	__go32_info_block+26, %cx
	movl	%eax, -992(%ebp)
	movw	%cx, -996(%ebp)
/APP
# 145 "c:/djgpp/include/libc/farptrgs.h" 1
	movw %cx, %gs 
	.byte 0x65 
	movw (%eax),%ax 

# 0 "" 2
/NO_APP
	andl	$65535, %eax
	movl	%edx, -1008(%ebp)
	movl	%eax, %esi
	movl	%eax, -1004(%ebp)
	sall	$2, %esi
	movl	%eax, _dirent_count
	movl	%esi, (%esp)
	call	_malloc
	movl	-1008(%ebp), %edx
	movl	%eax, _dirent_table
	testl	%eax, %eax
	je	L222
	movl	%esi, 8(%esp)
	movl	$0, 4(%esp)
	movl	%eax, (%esp)
	movl	%eax, -1008(%ebp)
	call	_memset
	movl	-1000(%ebp), %eax
	andl	$-66, %eax
	movw	%ax, __djstat_fail_bits
/APP
# 169 "c:/djgpp/include/libc/farptrgs.h" 1
	movw -996(%ebp),%gs
# 0 "" 2
/NO_APP
	imull	$6, -1004(%ebp), %eax
	movl	_dirent_count, %esi
	movl	-992(%ebp), %edx
	movl	%esi, -1000(%ebp)
	movl	-992(%ebp), %esi
	addl	$2, %edx
	movl	-1008(%ebp), %ecx
	leal	2(%esi,%eax), %eax
	movl	-968(%ebp), %esi
	andl	$65535, %esi
	movl	%eax, -992(%ebp)
	movl	%esi, -1004(%ebp)
L38:
	cmpl	-992(%ebp), %edx
	je	L223
/APP
# 240 "c:/djgpp/include/libc/farptrgs.h" 1
	.byte 0x65
	movl (%edx),%esi
# 0 "" 2
/NO_APP
	leal	4(%edx), %eax
/APP
# 229 "c:/djgpp/include/libc/farptrgs.h" 1
	.byte 0x65
	movw (%eax),%ax
# 0 "" 2
/NO_APP
	andl	$32767, %eax
	cmpw	-968(%ebp), %ax
	jbe	L39
	movl	-1004(%ebp), %eax
	addl	%esi, %eax
	movl	%eax, (%ecx)
	addl	$4, %ecx
L40:
	addl	$6, %edx
	jmp	L38
L39:
	decl	-1000(%ebp)
	jmp	L40
L223:
	movl	-1000(%ebp), %ecx
	movl	%ecx, _dirent_count
	jmp	L43
L222:
	orl	$64, %edx
	movl	$0, _dirent_count
	movw	%dx, __djstat_fail_bits
	jmp	L34
	.cfi_endproc
LFE29:
	.p2align 4,,15
___FSEXT_call_open_handlers_wrapper.constprop.0:
LFB31:
	.cfi_startproc
	subl	$28, %esp
	.cfi_def_cfa_offset 32
	leal	40(%esp), %eax
	movl	$15, (%esp)
	movl	%eax, 8(%esp)
	movl	36(%esp), %eax
	movl	%eax, 4(%esp)
	call	___FSEXT_call_open_handlers
	addl	$28, %esp
	.cfi_def_cfa_offset 4
	ret
	.cfi_endproc
LFE31:
	.p2align 4,,15
	.globl	_lstat
_lstat:
LFB30:
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
	subl	$300, %esp
	.cfi_def_cfa_offset 320
	movl	_errno, %ebp
	movl	324(%esp), %eax
	movl	320(%esp), %esi
	testl	%eax, %eax
	je	L236
	testl	%esi, %esi
	je	L236
	movl	%esi, (%esp)
	call	_strlen
	movl	%eax, %edi
	cmpl	$259, %eax
	jg	L242
	leal	28(%esp), %ebx
	movl	%esi, (%esp)
	movl	%ebx, 4(%esp)
	call	___solve_dir_symlinks
	testl	%eax, %eax
	je	L241
	movl	%edi, 8(%esp)
	movl	$42, 4(%esp)
	movl	%ebx, (%esp)
	call	_memchr
	testl	%eax, %eax
	jne	L232
	movl	%edi, 8(%esp)
	movl	$63, 4(%esp)
	movl	%ebx, (%esp)
	call	_memchr
	testl	%eax, %eax
	jne	L232
	cmpb	$0, 28(%esp)
	je	L232
	movl	324(%esp), %eax
	movl	%ebx, 8(%esp)
	movl	%eax, 12(%esp)
	leal	24(%esp), %eax
	movl	%eax, 4(%esp)
	movl	$15, (%esp)
	call	___FSEXT_call_open_handlers_wrapper.constprop.0
	testl	%eax, %eax
	je	L234
	movl	24(%esp), %eax
L229:
	addl	$300, %esp
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
L232:
	.cfi_restore_state
	movl	$22, _errno
L241:
	addl	$300, %esp
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
L234:
	.cfi_restore_state
	movl	324(%esp), %edx
	movl	%ebx, %eax
	call	_stat_assist
	incl	%eax
	je	L241
	movl	%ebp, _errno
	addl	$300, %esp
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
L242:
	.cfi_restore_state
	movl	$19, _errno
	orl	$-1, %eax
	jmp	L229
	.p2align 4,,7
L236:
	movl	$11, _errno
	orl	$-1, %eax
	jmp	L229
	.cfi_endproc
LFE30:
	.section .data
_blanks_8:
	.ascii "        \0"
.lcomm _init_dirent_table_bits,2,2
	.p2align 2
_stat_count:
	.long	-1
.lcomm _dirent_count,4,4
.lcomm _dirent_table,4,4
.lcomm _dirent_place,4,4
	.ident	"GCC: (GNU) 4.7.4"
