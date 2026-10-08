	.file	"_use_lfn.c"
	.section .text
	.p2align 4,,15
	.globl	__get_volume_info
__get_volume_info:
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
	subl	$92, %esp
	.cfi_def_cfa_offset 112
	movl	__go32_info_block+12, %ebx
	movl	112(%esp), %eax
	movl	%ebx, %esi
	shrl	$4, %esi
	movl	116(%esp), %ebp
	movl	120(%esp), %edi
	testl	%eax, %eax
	je	L2
	cmpb	$0, (%eax)
	jne	L53
L2:
	leal	24(%esp), %eax
	movl	%eax, (%esp)
	call	__dos_getdrive
	movb	24(%esp), %al
	movw	__go32_info_block+26, %dx
	addl	$64, %eax
/APP
# 96 "c:/djgpp/include/libc/farptrgs.h" 1
	movw %dx,%gs
	.byte 0x65 
	movb %al,(%ebx)
# 0 "" 2
/NO_APP
	leal	1(%ebx), %eax
/APP
# 96 "c:/djgpp/include/libc/farptrgs.h" 1
	movw %dx,%gs
	.byte 0x65 
	movb $58,(%eax)
# 0 "" 2
/NO_APP
	leal	3(%ebx), %eax
	leal	2(%ebx), %ecx
/APP
# 96 "c:/djgpp/include/libc/farptrgs.h" 1
	movw %dx,%gs
	.byte 0x65 
	movb $92,(%ecx)
# 0 "" 2
/NO_APP
	addl	$4, %ebx
/APP
# 96 "c:/djgpp/include/libc/farptrgs.h" 1
	movw %dx,%gs
	.byte 0x65 
	movb $0,(%eax)
# 0 "" 2
/NO_APP
	movl	__go32_info_block+12, %eax
L8:
	movl	%ebx, %edx
	movl	$33, (%esp)
	subl	%eax, %edx
	leal	28(%esp), %eax
	movl	%eax, 4(%esp)
	movw	$1, 60(%esp)
	movw	$29088, 56(%esp)
	movw	%si, 64(%esp)
	movw	$0, 48(%esp)
	movw	%si, 62(%esp)
	movw	%dx, 28(%esp)
	movw	$32, 52(%esp)
	call	___dpmi_int
	testb	$1, 60(%esp)
	jne	L9
	cmpw	$28928, 56(%esp)
	je	L9
	movl	44(%esp), %eax
	andl	$65535, %eax
	testl	%ebp, %ebp
	je	L10
	movl	52(%esp), %edx
	andl	$65535, %edx
	movl	%edx, 0(%ebp)
L10:
	testl	%edi, %edi
	je	L11
	movl	48(%esp), %edx
	andl	$65535, %edx
	movl	%edx, (%edi)
L11:
	movl	124(%esp), %ecx
	testl	%ecx, %ecx
	je	L12
/APP
# 169 "c:/djgpp/include/libc/farptrgs.h" 1
	movw __go32_info_block+26,%gs
# 0 "" 2
/NO_APP
	leal	1(%ebx), %ecx
/APP
# 218 "c:/djgpp/include/libc/farptrgs.h" 1
	.byte 0x65
	movb (%ebx),%bl
# 0 "" 2
/NO_APP
	movl	124(%esp), %edx
	testb	%bl, %bl
	je	L51
	.p2align 4,,7
L14:
	movb	%bl, (%edx)
	leal	1(%ecx), %esi
	incl	%edx
/APP
# 218 "c:/djgpp/include/libc/farptrgs.h" 1
	.byte 0x65
	movb (%ecx),%bl
# 0 "" 2
/NO_APP
	movl	%esi, %ecx
	testb	%bl, %bl
	jne	L14
	jmp	L51
	.p2align 4,,7
L9:
	cmpb	$113, 57(%esp)
	je	L54
	movl	56(%esp), %eax
	andl	$65535, %eax
	movl	%eax, (%esp)
	call	___doserr_to_errno
	movl	%eax, _errno
	movl	$-2147483648, %eax
L16:
	testl	%ebp, %ebp
	je	L17
	movl	$13, 0(%ebp)
L17:
	testl	%edi, %edi
	je	L18
	movl	$80, (%edi)
L18:
	movl	124(%esp), %edx
	testl	%edx, %edx
	je	L12
	movl	124(%esp), %edx
L51:
	movb	$0, (%edx)
L12:
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
L54:
	.cfi_restore_state
	movl	$27, _errno
	xorl	%eax, %eax
	jmp	L16
	.p2align 4,,7
L53:
	movl	%eax, (%esp)
	call	__put_path
/APP
# 169 "c:/djgpp/include/libc/farptrgs.h" 1
	movw __go32_info_block+26,%gs
# 0 "" 2
/NO_APP
	leal	1(%ebx), %edx
/APP
# 218 "c:/djgpp/include/libc/farptrgs.h" 1
	.byte 0x65
	movb (%edx),%al
# 0 "" 2
/NO_APP
	cmpb	$58, %al
	je	L55
/APP
# 218 "c:/djgpp/include/libc/farptrgs.h" 1
	.byte 0x65
	movb (%ebx),%al
# 0 "" 2
/NO_APP
	cmpb	$92, %al
	je	L56
L5:
	movl	__go32_info_block+12, %eax
	cmpl	%ebx, %eax
	jne	L8
	jmp	L2
	.p2align 4,,7
L55:
	leal	3(%ebx), %ecx
	leal	2(%ebx), %edx
/APP
# 218 "c:/djgpp/include/libc/farptrgs.h" 1
	.byte 0x65
	movb (%edx),%al
# 0 "" 2
/NO_APP
	cmpb	$92, %al
	je	L4
/APP
# 188 "c:/djgpp/include/libc/farptrgs.h" 1
	.byte 0x65
	movb $92,(%edx)
# 0 "" 2
/NO_APP
L4:
	addl	$4, %ebx
/APP
# 188 "c:/djgpp/include/libc/farptrgs.h" 1
	.byte 0x65
	movb $0,(%ecx)
# 0 "" 2
/NO_APP
	jmp	L5
	.p2align 4,,7
L56:
/APP
# 218 "c:/djgpp/include/libc/farptrgs.h" 1
	.byte 0x65
	movb (%edx),%dl
# 0 "" 2
/NO_APP
	cmpb	$92, %dl
	jne	L5
	addl	$2, %ebx
/APP
# 218 "c:/djgpp/include/libc/farptrgs.h" 1
	.byte 0x65
	movb (%ebx),%al
# 0 "" 2
/NO_APP
	testb	%al, %al
	je	L6
	.p2align 4,,7
L38:
	incl	%ebx
/APP
# 218 "c:/djgpp/include/libc/farptrgs.h" 1
	.byte 0x65
	movb (%ebx),%al
# 0 "" 2
/NO_APP
	testb	%al, %al
	jne	L38
L6:
	incl	%ebx
	jmp	L5
	.cfi_endproc
LFE23:
LC0:
	.ascii "LFN\0"
	.p2align 4,,15
	.globl	__use_lfn
__use_lfn:
LFB24:
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
	xorl	%eax, %eax
	subl	$32, %esp
	.cfi_def_cfa_offset 48
	movb	__lfnenv, %bl
	testb	$4, __crt0_startup_flags+1
	movl	48(%esp), %esi
	jne	L58
	movl	___bss_count, %eax
	cmpl	%eax, _use_lfn_bss_count
	je	L59
	movl	%eax, _use_lfn_bss_count
	movl	$-2147483648, _filesystem_flags
	movb	$121, __lfnenv
	movl	$0, _last_drive
L59:
	testl	%esi, %esi
	je	L60
	cmpb	$0, (%esi)
	jne	L86
L60:
	movl	___environ_changed, %eax
	movl	$1, %edi
	cmpl	%eax, _last_env_changed
	je	L87
L62:
	movl	$LC0, (%esp)
	movl	%eax, _last_env_changed
	call	_getenv
	testl	%eax, %eax
	je	L65
	movb	(%eax), %al
	andl	$255, %eax
	cmpb	$110, ___dj_ctype_tolower+1(%eax)
	je	L88
L65:
	movb	$121, __lfnenv
L66:
	testl	%edi, %edi
	je	L67
	movl	_filesystem_flags, %edx
	cmpl	$-2147483648, %edx
	je	L67
L68:
	xorl	%eax, %eax
	andb	$64, %dh
	je	L58
	cmpb	$110, __lfnenv
	setne	%al
L58:
	addl	$32, %esp
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
L67:
	.cfi_restore_state
	movl	$0, 12(%esp)
	movl	$0, 8(%esp)
	movl	$0, 4(%esp)
	movl	%esi, (%esp)
	call	__get_volume_info
	movl	%eax, %edx
	movl	%eax, _filesystem_flags
	cmpl	$-2147483648, %eax
	jne	L68
	cmpb	$110, %bl
	movb	%bl, __lfnenv
	setne	%al
	movl	$0, _last_drive
	addl	$32, %esp
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
L86:
	.cfi_restore_state
	movl	%esi, (%esp)
	call	__put_path
	movl	__go32_info_block+12, %edx
	movw	__go32_info_block+26, %ax
	leal	1(%edx), %ecx
/APP
# 132 "c:/djgpp/include/libc/farptrgs.h" 1
	movw %ax,%gs 
	.byte 0x65 
	movb (%ecx),%cl
# 0 "" 2
/NO_APP
	cmpb	$58, %cl
	je	L89
L61:
	cmpb	$92, (%esi)
	jne	L63
	cmpb	$92, 1(%esi)
	je	L85
L63:
	leal	28(%esp), %eax
	movl	%eax, (%esp)
	call	__dos_getdrive
	movl	28(%esp), %eax
	addl	$64, %eax
	cmpl	_last_drive, %eax
	je	L60
L85:
	movl	___environ_changed, %eax
	xorl	%edi, %edi
	jmp	L62
	.p2align 4,,7
L88:
	movb	$110, __lfnenv
	movl	$0, _last_drive
	jmp	L66
	.p2align 4,,7
L87:
	movl	_filesystem_flags, %edx
	cmpl	$-2147483648, %edx
	jne	L68
	jmp	L62
	.p2align 4,,7
L89:
/APP
# 132 "c:/djgpp/include/libc/farptrgs.h" 1
	movw %ax,%gs 
	.byte 0x65 
	movb (%edx),%al
# 0 "" 2
/NO_APP
	andl	$255, %eax
	movb	___dj_ctype_toupper+1(%eax), %al
	andl	$255, %eax
	cmpl	_last_drive, %eax
	jne	L85
	jmp	L61
	.cfi_endproc
LFE24:
	.section .data
__lfnenv:
	.byte	121
	.p2align 2
_use_lfn_bss_count:
	.long	-1
	.p2align 2
_filesystem_flags:
	.long	-2147483648
.lcomm _last_drive,4,4
.lcomm _last_env_changed,4,4
	.ident	"GCC: (GNU) 4.7.4"
