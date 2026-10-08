	.file	"fstat.c"
	.section .text
	.p2align 4,,15
_set_fstat_times.isra.0.part.1:
LFB37:
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
	movl	%edx, %esi
	subl	$16, %esp
	.cfi_def_cfa_offset 32
	movl	%ecx, %edi
	movl	%eax, %ebx
	movl	$2, 4(%esp)
	movl	%eax, (%esp)
	call	__lfn_get_ftime
	movl	%eax, (%esp)
	call	__file_time_stamp
	cmpl	(%esi), %eax
	jbe	L2
	movl	%eax, (%esi)
L2:
	movl	$1, 4(%esp)
	movl	%ebx, (%esp)
	call	__lfn_get_ftime
	testl	%eax, %eax
	je	L1
	movl	%eax, (%esp)
	call	__file_time_stamp
	movl	%eax, (%edi)
L1:
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
LFE37:
	.p2align 4,,15
___FSEXT_func_wrapper.constprop.2:
LFB38:
	.cfi_startproc
	subl	$28, %esp
	.cfi_def_cfa_offset 32
	leal	44(%esp), %eax
	movl	$14, (%esp)
	movl	%eax, 8(%esp)
	movl	40(%esp), %eax
	movl	%eax, 4(%esp)
	call	*32(%esp)
	addl	$28, %esp
	.cfi_def_cfa_offset 4
	ret
	.cfi_endproc
LFE38:
LC0:
	.ascii "\0"
	.p2align 4,,15
	.globl	_fstat
_fstat:
LFB35:
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
	subl	$316, %esp
	.cfi_def_cfa_offset 336
	movl	_errno, %eax
	movl	340(%esp), %ebx
	movl	336(%esp), %ebp
	movl	%eax, 52(%esp)
	testl	%ebx, %ebx
	je	L213
	movl	%ebp, (%esp)
	call	___FSEXT_get_function
	testl	%eax, %eax
	je	L14
	leal	140(%esp), %edx
	movl	%ebx, 16(%esp)
	movl	%ebp, 12(%esp)
	movl	%edx, 8(%esp)
	movl	$14, 4(%esp)
	movl	%eax, (%esp)
	call	___FSEXT_func_wrapper.constprop.2
	testl	%eax, %eax
	jne	L214
L14:
	testl	%ebp, %ebp
	js	L15
	movl	___fd_properties, %eax
	testl	%eax, %eax
	je	L15
	movl	(%eax,%ebp,4), %eax
	testl	%eax, %eax
	je	L15
	testb	$32, 8(%eax)
	je	L15
	movl	4(%eax), %eax
	testl	%eax, %eax
	je	L15
	movl	%ebx, 4(%esp)
	movl	%eax, (%esp)
	call	_stat
L203:
	addl	$316, %esp
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
L214:
	.cfi_restore_state
	movl	140(%esp), %eax
	addl	$316, %esp
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
L15:
	.cfi_restore_state
	movl	%ebp, (%esp)
	call	__get_dev_info
	cmpw	$-1, %ax
	movl	%eax, %esi
	je	L94
	movw	$0, __djstat_fail_bits
	testb	$35, __djstat_flags
	jne	L98
	movw	_fstat_init_bits, %ax
	movw	%ax, __djstat_fail_bits
	movl	___bss_count, %eax
/APP
# 36 "c:/djgpp/include/sys/segments.h" 1
	movw %ds,%dx
# 0 "" 2
/NO_APP
	cmpl	%eax, _fstat_count
	movw	%dx, 48(%esp)
	je	L19
	movl	%eax, _fstat_count
	movw	$0, _dos_major
L19:
	leal	200(%esp), %eax
	movl	$33, (%esp)
	movl	%eax, 4(%esp)
	movb	$98, 229(%esp)
	call	___dpmi_int
	movl	216(%esp), %eax
	andl	$65535, %eax
	sall	$4, %eax
	movl	%eax, _psp_addr
	cmpw	$0, _dos_major
	je	L215
L20:
	testl	%ebp, %ebp
	js	L24
	movl	$20, %eax
	cmpw	$2, __osmajor
	jbe	L25
	movl	_psp_addr, %eax
	addl	$50, %eax
/APP
# 145 "c:/djgpp/include/libc/farptrgs.h" 1
	movw __go32_info_block+26, %gs 
	.byte 0x65 
	movw (%eax),%ax 

# 0 "" 2
/NO_APP
	andl	$65535, %eax
L25:
	cmpl	%eax, %ebp
	jge	L24
	movl	_htbl_ptr_addr, %ecx
	movw	__go32_info_block+26, %dx
	leal	2(%ecx), %eax
/APP
# 145 "c:/djgpp/include/libc/farptrgs.h" 1
	movw %dx, %gs 
	.byte 0x65 
	movw (%eax),%ax 

# 0 "" 2
# 145 "c:/djgpp/include/libc/farptrgs.h" 1
	movw %dx, %gs 
	.byte 0x65 
	movw (%ecx),%cx 

# 0 "" 2
/NO_APP
	andl	$65535, %ecx
	andl	$65535, %eax
	sall	$4, %eax
	addl	%ebp, %ecx
	addl	%ecx, %eax
/APP
# 132 "c:/djgpp/include/libc/farptrgs.h" 1
	movw %dx,%gs 
	.byte 0x65 
	movb (%eax),%al
# 0 "" 2
/NO_APP
	movw	_sft_start_seg, %cx
	andl	$255, %eax
	andl	$65535, %ecx
	movw	%ax, 58(%esp)
	sall	$4, %ecx
	movw	_sft_start_off, %ax
	cmpw	$-1, %ax
	je	L26
	andl	$65535, %eax
	addl	%ecx, %eax
	leal	4(%eax), %edi
/APP
# 145 "c:/djgpp/include/libc/farptrgs.h" 1
	movw %dx, %gs 
	.byte 0x65 
	movw (%edi),%di 

# 0 "" 2
/NO_APP
	cmpw	%di, 58(%esp)
	movw	58(%esp), %cx
	jge	L29
	jmp	L27
	.p2align 4,,7
L30:
	andl	$65535, %edi
	addl	%edi, %eax
	leal	4(%eax), %edi
/APP
# 145 "c:/djgpp/include/libc/farptrgs.h" 1
	movw %dx, %gs 
	.byte 0x65 
	movw (%edi),%di 

# 0 "" 2
/NO_APP
	cmpw	%cx, %di
	jg	L27
L29:
	subl	%edi, %ecx
/APP
# 145 "c:/djgpp/include/libc/farptrgs.h" 1
	movw %dx, %gs 
	.byte 0x65 
	movw (%eax),%di 

# 0 "" 2
/NO_APP
	addl	$2, %eax
/APP
# 145 "c:/djgpp/include/libc/farptrgs.h" 1
	movw %dx, %gs 
	.byte 0x65 
	movw (%eax),%ax 

# 0 "" 2
/NO_APP
	andl	$65535, %eax
	sall	$4, %eax
	cmpw	$-1, %di
	jne	L30
L26:
	orw	$2048, __djstat_fail_bits
	movw	$-2, 58(%esp)
	jmp	L18
	.p2align 4,,7
L98:
	movw	$-1, 58(%esp)
L18:
	movl	%ebx, %edi
	movl	$48, %edx
	testb	$1, %bl
	jne	L216
L31:
	testl	$2, %edi
	jne	L217
L32:
	movl	%edx, %ecx
	xorl	%eax, %eax
	shrl	$2, %ecx
	rep stosl
	testb	$2, %dl
	je	L33
	movw	$0, (%edi)
	addl	$2, %edi
L33:
	andl	$1, %edx
	je	L34
	movb	$0, (%edi)
L34:
	leal	144(%esp), %eax
	movl	%ebp, (%esp)
	movl	%eax, 4(%esp)
	movl	$0, 144(%esp)
	call	__getftime
	testl	%eax, %eax
	je	L218
	movl	$0, 96(%esp)
	movw	$0, 80(%esp)
	movw	$0, 104(%esp)
	xorl	%edi, %edi
L35:
	testl	$128, %esi
	jne	L104
	movl	%esi, %edx
	movl	%edi, %ecx
	shrw	$15, %dx
	movb	$0, 60(%esp)
	orw	%si, %cx
	movb	%dl, 64(%esp)
	je	L219
L36:
	call	_getuid
	movl	%eax, 40(%ebx)
	call	_getgid
	movl	$1, 28(%ebx)
	movl	%eax, 12(%ebx)
	testl	%ebp, %ebp
	js	L115
	movl	___fd_properties, %eax
	testl	%eax, %eax
	je	L115
	movl	(%eax,%ebp,4), %eax
	testl	%eax, %eax
	je	L115
	movl	4(%eax), %eax
	movl	%eax, 48(%esp)
	testl	%eax, %eax
	je	L115
	movl	48(%esp), %edx
	cmpb	$0, (%edx)
	jne	L220
L39:
	movl	__go32_info_block+16, %eax
	movl	%eax, 36(%ebx)
L40:
	movw	__djstat_flags, %ax
	testb	$35, %al
	jne	L41
	cmpw	$0, 58(%esp)
	js	L41
	movw	_dos_major, %dx
	cmpw	$2, %dx
	je	L43
	cmpw	$3, %dx
	je	L221
	movb	_sft_buf+5, %cl
	movl	$11, 124(%esp)
	andl	$63, %ecx
	movl	$13, 112(%esp)
	movb	%cl, 107(%esp)
	movl	$17, 116(%esp)
	movl	$15, %ecx
	movl	$40, 108(%esp)
	movl	$32, 100(%esp)
	movl	$4, 120(%esp)
L45:
	cmpb	$0, 60(%esp)
	je	L46
	movl	$-1, 8(%ebx)
	testb	$1, %al
	jne	L210
	movl	100(%esp), %edi
	movl	100(%esp), %ecx
	addl	$_sft_buf, %ecx
	movl	$1683765824, 252(%esp)
	movb	_sft_buf(%edi), %al
	movl	$542930533, 256(%esp)
	movl	$538976288, 260(%esp)
	movl	$2105376, 264(%esp)
	cmpb	$32, %al
	je	L49
	movb	%al, 259(%esp)
	xorl	%eax, %eax
	.p2align 4,,7
L97:
	movb	1(%ecx,%eax), %dl
	cmpb	$32, %dl
	je	L49
	movb	%dl, 260(%esp,%eax)
	incl	%eax
	cmpl	$7, %eax
	jne	L97
L49:
	leal	252(%esp), %eax
	movl	$0, 8(%esp)
	movl	$0, 4(%esp)
	movl	%eax, (%esp)
	call	__invent_inode
	movl	%eax, 16(%ebx)
	.p2align 4,,7
L210:
	orl	$8612, 20(%ebx)
	movl	$0, (%esp)
	call	_time
	movl	$0, 144(%esp)
	movl	%eax, 24(%ebx)
	movl	%eax, (%ebx)
	movl	$0, (%esp)
	call	__file_time_stamp
	movl	%eax, 4(%ebx)
	jmp	L51
	.p2align 4,,7
L41:
	testw	%di, %di
	je	L94
	cmpb	$0, 60(%esp)
	je	L77
	testb	$1, %al
	je	L78
	testl	$15, %esi
	je	L79
	movl	$1683765824, 252(%esp)
	movl	$6059621, 256(%esp)
	testl	$3, %esi
	jne	L222
	testl	$4, %esi
	jne	L223
	andl	$8, %esi
	jne	L224
L81:
	leal	252(%esp), %eax
	movl	$0, 8(%esp)
	movl	$0, 4(%esp)
	movl	%eax, (%esp)
	call	__invent_inode
	movl	%eax, 16(%ebx)
	jmp	L83
	.p2align 4,,7
L104:
	movb	$0, 64(%esp)
	movb	$1, 60(%esp)
	jmp	L36
	.p2align 4,,7
L219:
	cmpw	$1330, __os_trueversion
	sete	60(%esp)
	jmp	L36
	.p2align 4,,7
L46:
	testw	%di, %di
	je	L94
	movl	100(%esp), %edx
	movw	_sft_buf(%ecx), %di
	movl	112(%esp), %ecx
	addl	$_sft_buf, %edx
	movl	%edx, 36(%esp)
	movl	116(%esp), %edx
	movw	_sft_buf(%ecx), %cx
	movw	%cx, 112(%esp)
	movl	100(%esp), %ecx
	movl	_sft_buf(%edx), %edx
	addl	$_sft_buf+11, %ecx
	orl	$292, 20(%ebx)
	movl	%edx, 60(%esp)
	cmpl	%ecx, 36(%esp)
	jae	L52
	movl	100(%esp), %edx
	cmpb	$32, _sft_buf(%edx)
	jne	L53
	movl	36(%esp), %edx
	jmp	L171
	.p2align 4,,7
L225:
	cmpb	$32, (%edx)
	jne	L53
L171:
	incl	%edx
	cmpl	%ecx, %edx
	jne	L225
L52:
	orw	$512, __djstat_fail_bits
L77:
	testb	$1, %al
	je	L226
L84:
	cmpl	$510, 96(%esp)
	je	L227
L85:
	orl	$292, 20(%ebx)
	testb	$38, __djstat_flags
	jne	L228
L88:
	movl	$0, (%esp)
	call	__use_lfn
	testb	%al, %al
	jne	L229
L89:
	testb	$4, __djstat_flags
	je	L230
L87:
	andl	$63, %esi
	movl	96(%esp), %eax
	movl	%esi, 8(%ebx)
	movl	%eax, 32(%ebx)
L212:
	movl	144(%esp), %eax
	movl	%eax, (%esp)
	call	__file_time_stamp
	movl	%eax, 24(%ebx)
	movl	%eax, 4(%ebx)
	movl	%eax, (%ebx)
	movl	$0, (%esp)
	call	__use_lfn
	testb	%al, %al
	je	L51
	leal	4(%ebx), %ecx
	movl	%ebx, %edx
	movl	%ebp, %eax
	call	_set_fstat_times.isra.0.part.1
	.p2align 4,,7
L51:
	movl	52(%esp), %ebx
	xorl	%eax, %eax
	movl	%ebx, _errno
	addl	$316, %esp
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
L215:
	.cfi_restore_state
	addl	$52, %eax
	movl	$33, (%esp)
	movl	%eax, _htbl_ptr_addr
	leal	252(%esp), %eax
	movl	%eax, 4(%esp)
	movb	$82, 281(%esp)
	call	___dpmi_int
	movw	__os_trueversion, %dx
	movl	%edx, %eax
	andl	$255, %edx
	shrw	$8, %ax
	movw	%dx, _dos_minor
	movw	286(%esp), %cx
	movl	268(%esp), %edi
	movw	%ax, _dos_major
	movl	$3, %edx
	cmpw	$4, %ax
	ja	L21
	andl	$65535, %eax
	leal	-1(%eax), %edx
L21:
	movl	_sft_size_list(,%edx,4), %eax
	movl	%eax, _sft_size
	testl	%eax, %eax
	je	L231
	addl	$4, %edi
	andl	$65535, %ecx
	andl	$65535, %edi
	movw	__go32_info_block+26, %ax
	sall	$4, %ecx
	addl	%edi, %ecx
/APP
# 145 "c:/djgpp/include/libc/farptrgs.h" 1
	movw %ax, %gs 
	.byte 0x65 
	movw (%ecx),%dx 

# 0 "" 2
/NO_APP
	movw	%dx, _sft_start_off
	addl	$2, %ecx
/APP
# 145 "c:/djgpp/include/libc/farptrgs.h" 1
	movw %ax, %gs 
	.byte 0x65 
	movw (%ecx),%ax 

# 0 "" 2
/NO_APP
	movw	%ax, _sft_start_seg
	jmp	L20
	.p2align 4,,7
L115:
	movl	$LC0, 48(%esp)
	movl	48(%esp), %edx
	cmpb	$0, (%edx)
	je	L39
L220:
	movl	%edx, (%esp)
	call	__get_cached_blksize
	movl	%eax, 36(%ebx)
	incl	%eax
	jne	L40
	jmp	L94
	.p2align 4,,7
L79:
	movl	$0, 8(%esp)
	movl	$0, 4(%esp)
	movl	$LC0, (%esp)
	call	__invent_inode
	movl	%eax, 16(%ebx)
L83:
	orw	$16, __djstat_fail_bits
L78:
	movl	$-1, 8(%ebx)
	jmp	L210
	.p2align 4,,7
L218:
	movl	%ebp, (%esp)
	call	___filelength
	movl	%eax, 96(%esp)
	incl	%eax
	je	L103
	movl	144(%esp), %eax
	movl	$1, %edi
	movw	%ax, 104(%esp)
	shrl	$16, %eax
	movw	%ax, 80(%esp)
	jmp	L35
	.p2align 4,,7
L27:
	movl	_sft_size, %edi
	andl	$65535, %edx
	movl	%edi, 16(%esp)
	movl	48(%esp), %edi
	andl	$65535, %edi
	movl	$_sft_buf, 12(%esp)
	movl	%edi, 8(%esp)
	movl	_sft_size, %edi
	movswl	%cx, %ecx
	imull	%edi, %ecx
	movl	%edx, (%esp)
	leal	6(%eax,%ecx), %eax
	movl	%eax, 4(%esp)
	call	___movedata
	jmp	L18
	.p2align 4,,7
L228:
	orw	$128, __djstat_fail_bits
	jmp	L88
	.p2align 4,,7
L231:
	movw	__djstat_fail_bits, %ax
	movw	$-2, 58(%esp)
	orl	$2, %eax
	movw	%ax, __djstat_fail_bits
	movw	%ax, _fstat_init_bits
	jmp	L18
L24:
	movl	$6, _errno
L94:
	orl	$-1, %eax
	jmp	L203
	.p2align 4,,7
L221:
	movb	_sft_buf+5, %cl
	movl	$11, 124(%esp)
	andl	$63, %ecx
	movl	$13, 112(%esp)
	cmpw	$1, _dos_minor
	sbbl	%edx, %edx
	movb	%cl, 107(%esp)
	xorl	$-1, %edx
	movl	$15, %ecx
	addl	$41, %edx
	movl	$17, 116(%esp)
	cmpw	$1, _dos_minor
	movl	%edx, 108(%esp)
	movl	$4, 120(%esp)
	sbbl	%edx, %edx
	xorl	$-1, %edx
	addl	$33, %edx
	movl	%edx, 100(%esp)
	jmp	L45
	.p2align 4,,7
L43:
	movb	_sft_buf+3, %cl
	movl	$28, 124(%esp)
	decl	%ecx
	movl	$25, 112(%esp)
	movb	%cl, 107(%esp)
	movl	$19, 116(%esp)
	movl	$23, %ecx
	movl	$11, 108(%esp)
	movl	$4, 100(%esp)
	movl	$2, 120(%esp)
	movb	$0, 64(%esp)
	jmp	L45
	.p2align 4,,7
L226:
	movl	96(%esp), %eax
	movl	48(%esp), %edx
	movl	%eax, 8(%esp)
	movl	144(%esp), %eax
	movl	%eax, 4(%esp)
	movl	%edx, (%esp)
	orw	$16, __djstat_fail_bits
	call	__invent_inode
	movl	%eax, 16(%ebx)
	jmp	L84
	.p2align 4,,7
L216:
	movb	$0, (%ebx)
	leal	1(%ebx), %edi
	movb	$47, %dl
	jmp	L31
	.p2align 4,,7
L217:
	movw	$0, (%edi)
	subl	$2, %edx
	addl	$2, %edi
	jmp	L32
	.p2align 4,,7
L53:
	cmpw	80(%esp), %di
	jne	L52
	movl	104(%esp), %edi
	cmpw	%di, 112(%esp)
	jne	L52
	movl	96(%esp), %ecx
	cmpl	%ecx, 60(%esp)
	jne	L52
	movl	108(%esp), %eax
	movl	$0, 200(%esp)
	leal	_sft_buf+2(%eax), %edx
	addl	$2, %eax
	cmpb	$32, _sft_buf(%eax)
	jne	L110
	leal	-1(%edx), %edi
	cmpb	$32, -1(%edx)
	jne	L111
	leal	-2(%edx), %edi
	cmpb	$32, -2(%edx)
	jne	L112
	xorl	%ecx, %ecx
	leal	-3(%edx), %edi
	leal	199(%esp), %esi
	cmpb	$32, -3(%edx)
	jne	L56
L57:
	cmpl	$510, 60(%esp)
	je	L232
L59:
	movl	120(%esp), %edi
	testb	$7, _sft_buf(%edi)
	jne	L63
	orl	$128, 20(%ebx)
L63:
	leal	200(%esp), %eax
	movl	%ebp, 4(%esp)
	movl	%eax, 8(%esp)
	movl	$0, (%esp)
	call	__is_executable
	testl	%eax, %eax
	je	L64
	orl	$73, 20(%ebx)
L64:
	cmpw	$3, _dos_major
	jbe	L62
	testb	$32, _sft_buf+6
	je	L62
	orl	$16384, 20(%ebx)
L62:
	movsbl	107(%esp), %eax
	testb	$1, __djstat_flags
	movl	%eax, 8(%ebx)
	jne	L66
	cmpb	$0, 64(%esp)
	jne	L70
	movl	124(%esp), %edx
	movw	_sft_buf(%edx), %ax
	andl	$65535, %eax
	movl	%eax, 16(%ebx)
	testl	%eax, %eax
	je	L70
L66:
	movl	60(%esp), %ecx
	movl	%ecx, 32(%ebx)
	jmp	L212
	.p2align 4,,7
L103:
	movw	$0, 80(%esp)
	movw	$0, 104(%esp)
	xorl	%edi, %edi
	jmp	L35
	.p2align 4,,7
L230:
	movl	$0, 8(%esp)
	movl	%ebp, 4(%esp)
	movl	$0, (%esp)
	call	__is_executable
	testl	%eax, %eax
	je	L87
	orl	$73, 20(%ebx)
	jmp	L87
	.p2align 4,,7
L229:
	movl	__go32_info_block+12, %eax
	movl	$33, (%esp)
	shrl	$4, %eax
	movw	$1, 180(%esp)
	movw	%ax, 184(%esp)
	leal	148(%esp), %eax
	movl	%eax, 4(%esp)
	movw	$29094, 176(%esp)
	movw	%bp, 164(%esp)
	movw	$0, 168(%esp)
	call	___dpmi_int
	testb	$1, 180(%esp)
	jne	L89
	cmpw	$28928, 176(%esp)
	je	L89
	movl	__go32_info_block+12, %eax
/APP
# 158 "c:/djgpp/include/libc/farptrgs.h" 1
	movw __go32_info_block+26,%gs
	.byte 0x65
	movl (%eax),%eax
# 0 "" 2
/NO_APP
	testb	$7, %al
	jne	L89
	orl	$128, 20(%ebx)
	jmp	L89
	.p2align 4,,7
L227:
	leal	252(%esp), %eax
	movl	$1, 12(%esp)
	movl	%eax, 8(%esp)
	movl	%ebp, 4(%esp)
	movl	$0, (%esp)
	movl	_errno, %edi
	call	___internal_readlink
	incl	%eax
	je	L86
	movl	$32768, 20(%ebx)
	jmp	L87
L213:
	movl	$11, _errno
	orl	$-1, %eax
	jmp	L203
L222:
	movl	$542003011, 259(%esp)
	movl	$538976288, 263(%esp)
	movb	$0, 267(%esp)
	jmp	L81
L223:
	movl	$541873486, 259(%esp)
	movl	$538976288, 263(%esp)
	movb	$0, 267(%esp)
	jmp	L81
L224:
	movl	$1129270339, 259(%esp)
	movl	$538977355, 263(%esp)
	movb	$0, 267(%esp)
	jmp	L81
L86:
	movl	%edi, _errno
	jmp	L85
L70:
	movswl	58(%esp), %edx
	movl	100(%esp), %ecx
	movl	$_name_pat.3687, 4(%esp)
	leal	(%edx,%edx,4), %eax
	addl	$7, %ecx
	movl	%ecx, 48(%esp)
	movl	%ecx, %edi
	leal	(%edx,%eax,8), %eax
	movl	%edx, %ecx
	sall	$5, %eax
	addl	$_sft_buf, %edi
	subl	%edx, %eax
	sall	$2, %eax
	subl	%edx, %eax
	movl	$1717986919, %edx
	shrl	$16, %eax
	movl	%eax, %esi
	movw	58(%esp), %ax
	sarw	$15, %ax
	sarw	$3, %si
	subl	%eax, %esi
	movswl	%si, %eax
	leal	(%eax,%eax,4), %eax
	leal	(%eax,%eax,4), %eax
	sall	$2, %eax
	subl	%eax, %ecx
	movl	%ecx, %eax
	movl	%ecx, 44(%esp)
	imull	%edx
	sarl	$2, %edx
	movl	%ecx, %eax
	sarl	$31, %eax
	subl	%eax, %edx
	leal	252(%esp), %eax
	movl	%eax, (%esp)
	movl	%edx, 40(%esp)
	call	_strcpy
	movb	107(%esp), %al
	addl	$65, %eax
	movl	40(%esp), %edx
	movb	%al, 252(%esp)
	leal	48(%esi), %eax
	movb	%al, 258(%esp)
	leal	48(%edx), %eax
	movb	%al, 259(%esp)
	leal	(%edx,%edx,4), %eax
	addl	%eax, %eax
	movl	44(%esp), %ecx
	subl	%eax, %ecx
	movl	$0, 262(%esp)
	movl	%ecx, %eax
	movl	$0, 266(%esp)
	addl	$48, %eax
	movl	$0, 270(%esp)
	movb	%al, 260(%esp)
	movl	48(%esp), %eax
	movb	$0, 274(%esp)
	movl	$7, %edx
	leal	269(%esp), %ecx
	cmpb	$32, _sft_buf(%eax)
	jne	L233
L169:
	decl	%edi
	decl	%ecx
	cmpb	$32, (%edi)
	jne	L72
	decl	%edx
	cmpl	$-1, %edx
	jne	L169
L73:
	cmpb	$0, 200(%esp)
	jne	L234
L75:
	movl	60(%esp), %ecx
	movl	144(%esp), %eax
	leal	252(%esp), %edi
	movl	%ecx, 8(%esp)
	movl	%eax, 4(%esp)
	movl	%edi, (%esp)
	call	__invent_inode
	orw	$16, __djstat_fail_bits
	movl	%eax, 16(%ebx)
	jmp	L66
L232:
	leal	252(%esp), %eax
	movl	$1, 12(%esp)
	movl	%eax, 8(%esp)
	movl	%ebp, 4(%esp)
	movl	$0, (%esp)
	movl	_errno, %esi
	call	___internal_readlink
	incl	%eax
	je	L61
	movl	$32768, 20(%ebx)
	jmp	L62
L72:
	leal	-1(%edx), %eax
	testl	%edx, %edx
	je	L73
L74:
	movl	%edx, %esi
	negl	%esi
	addl	%esi, %edi
	leal	(%ecx,%esi), %edx
	movl	%ecx, %esi
L168:
	movb	1(%edi,%eax), %cl
	movb	%cl, 1(%edx,%eax)
	decl	%eax
	cmpl	$-1, %eax
	jne	L168
	movl	%esi, %ecx
	jmp	L73
L234:
	movb	$46, 1(%ecx)
	leal	200(%esp), %edi
	addl	$2, %ecx
	movl	%edi, 4(%esp)
	movl	%ecx, (%esp)
	call	_strcpy
	jmp	L75
L112:
	movl	$1, %ecx
	leal	200(%esp), %esi
L56:
	leal	-1(%ecx), %eax
	movl	%edi, %edx
	testl	%ecx, %ecx
	je	L57
L60:
	movl	%ecx, %edi
	negl	%edi
	addl	%edi, %edx
	leal	(%esi,%edi), %ecx
	movl	%ebx, %esi
L170:
	movb	1(%edx,%eax), %bl
	movb	%bl, 1(%ecx,%eax)
	decl	%eax
	cmpl	$-1, %eax
	jne	L170
	movl	%esi, %ebx
	jmp	L57
L61:
	movl	%esi, _errno
	jmp	L59
L233:
	movb	$8, %dl
	movl	$7, %eax
	jmp	L74
L111:
	movl	$2, %ecx
	leal	201(%esp), %esi
	jmp	L56
L110:
	movl	$2, %eax
	leal	202(%esp), %esi
	movl	$3, %ecx
	jmp	L60
	.cfi_endproc
LFE35:
.lcomm _dos_major,2,2
.lcomm _sft_buf,64,16
.lcomm _dos_minor,2,2
	.section .data
	.p2align 4
_name_pat.3687:
	.ascii " :sft-   \\            \0"
.lcomm _fstat_init_bits,2,2
	.p2align 2
_fstat_count:
	.long	-1
.lcomm _psp_addr,4,4
.lcomm _htbl_ptr_addr,4,4
.lcomm _sft_start_off,2,2
.lcomm _sft_start_seg,2,2
.lcomm _sft_size,4,4
	.section .text
	.p2align 4
_sft_size_list:
	.long	0
	.long	40
	.long	53
	.long	59
	.ident	"GCC: (GNU) 4.7.4"
