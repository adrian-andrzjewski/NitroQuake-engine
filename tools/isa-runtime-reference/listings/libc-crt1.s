	.file	"crt1.c"
	.section .text
LC0:
	.ascii "\0"
	.p2align 4,,15
_setup_environment:
LFB26:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%edi
	pushl	%esi
	pushl	%ebx
	subl	$76, %esp
	.cfi_offset 7, -12
	.cfi_offset 6, -16
	.cfi_offset 3, -20
	movl	__stubinfo, %edx
/APP
# 36 "c:/djgpp/include/sys/segments.h" 1
	movw %ds,%si
# 0 "" 2
/NO_APP
	movw	42(%edx), %ax
	andl	$65535, %esi
	andl	$65535, %eax
	addl	$30, %eax
	andl	$131056, %eax
	subl	%eax, %esp
	leal	-26(%ebp), %eax
	movl	$2, 16(%esp)
	movl	%eax, 12(%esp)
	movl	%esi, 8(%esp)
	movl	$44, 4(%esp)
	movw	38(%edx), %ax
	leal	35(%esp), %ebx
	andl	$65535, %eax
	andl	$-16, %ebx
	movl	%eax, (%esp)
	call	___movedata
	movl	__stubinfo, %eax
	movw	42(%eax), %ax
	movl	%ebx, 12(%esp)
	andl	$65535, %eax
	movl	%esi, 8(%esp)
	movl	%eax, 16(%esp)
	movl	$0, 4(%esp)
	movswl	-26(%ebp), %eax
	movl	%eax, (%esp)
	call	___movedata
	movb	(%ebx), %al
	movl	%ebx, %ecx
	xorl	%edx, %edx
	.p2align 4,,7
L4:
	testb	%al, %al
	leal	1(%edx), %esi
	movl	%ecx, %eax
	je	L2
	.p2align 4,,7
L3:
	incl	%eax
	cmpb	$0, (%eax)
	jne	L3
L2:
	leal	1(%eax), %ecx
	movb	1(%eax), %al
	testb	%al, %al
	je	L22
	movl	%esi, %edx
	jmp	L4
	.p2align 4,,7
L22:
	leal	8(,%edx,4), %eax
	movl	%eax, (%esp)
	call	_malloc
	movl	%eax, %edx
	movl	%eax, __environ
	testl	%eax, %eax
	je	L1
	xorl	%esi, %esi
	.p2align 4,,7
L9:
	movl	%ebx, (%esp)
	movl	%edx, -44(%ebp)
	call	_strlen
	leal	0(,%esi,4), %edi
	incl	%eax
	incl	%esi
	movl	%eax, (%esp)
	call	_malloc
	movl	-44(%ebp), %edx
	movl	%eax, (%edx,%edi)
	movl	%ebx, 4(%esp)
	movl	__environ, %eax
	movl	(%eax,%edi), %eax
	movl	%eax, (%esp)
	call	_strcpy
	cmpb	$0, (%ebx)
	je	L6
	.p2align 4,,7
L16:
	incl	%ebx
	cmpb	$0, (%ebx)
	jne	L16
L6:
	leal	1(%ebx), %eax
	cmpb	$0, 1(%ebx)
	je	L8
	movl	__environ, %edx
	movl	%eax, %ebx
	jmp	L9
	.p2align 4,,7
L8:
	movl	__environ, %eax
	addl	$4, %ebx
	movl	$0, (%eax,%esi,4)
	movl	$LC0, (%esp)
	call	___putenv
	movl	%ebx, (%esp)
	call	_strlen
	leal	1(%eax), %esi
	movl	%esi, (%esp)
	call	_malloc
	movl	%eax, ___dos_argv0
	testl	%eax, %eax
	je	L23
	movl	%esi, 8(%esp)
	movl	%ebx, 4(%esp)
	movl	%eax, (%esp)
	call	_memcpy
L1:
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
L23:
	.cfi_restore_state
	call	_abort
	.cfi_endproc
LFE26:
	.p2align 4,,15
	.globl	___crt1_startup
___crt1_startup:
LFB29:
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
	subl	$80, %esp
	.cfi_def_cfa_offset 96
	movl	$0, ___crt0_argv
	movl	___bss_count, %edx
	incl	%edx
	movl	$1, (%esp)
	movl	%edx, ___bss_count
	call	__get_dos_version
	movl	$0, (%esp)
	movw	%ax, __os_trueversion
	call	__get_dos_version
	movl	$1, (%esp)
	movl	%eax, %edx
	andl	$255, %eax
	shrw	$8, %dx
	movw	%ax, __osminor
	movw	%dx, __osmajor
	call	___dpmi_allocate_ldt_descriptors
	cmpl	$-1, %eax
	je	L48
	movw	%ax, __go32_info_block+26
	andl	$65535, %eax
	movl	$1114111, 4(%esp)
	movl	%eax, (%esp)
	call	___dpmi_set_segment_limit
	movw	__go32_info_block+26, %ax
	movl	$1048563, %edx
/APP
# 145 "c:/djgpp/include/libc/farptrgs.h" 1
	movw %ax, %gs 
	.byte 0x65 
	movw (%edx),%dx 

# 0 "" 2
/NO_APP
	cmpw	$-640, %dx
	je	L49
	movl	$1097, %edx
/APP
# 132 "c:/djgpp/include/libc/farptrgs.h" 1
	movw %ax,%gs 
	.byte 0x65 
	movb (%edx),%al
# 0 "" 2
/NO_APP
	cmpb	$7, %al
	je	L50
	movl	$753664, __go32_info_block+4
	movl	$720896, __go32_info_block+8
L29:
	leal	20(%esp), %eax
	movl	%eax, (%esp)
	call	___dpmi_get_version
	movl	__stubinfo, %eax
	movl	36(%eax), %edx
	movl	$40, __go32_info_block
	andl	$65535, %edx
	movl	$-1, __go32_info_block+28
	sall	$4, %edx
	movl	%edx, __go32_info_block+12
	movl	32(%eax), %edx
	andl	$65535, %edx
	movw	38(%eax), %ax
	andl	$65535, %eax
	movl	%edx, __go32_info_block+16
	movb	25(%esp), %dl
	movl	$__go32_info_block+32, 4(%esp)
	movb	%dl, __go32_info_block+24
	movl	%eax, (%esp)
	movb	26(%esp), %dl
	movl	%eax, __go32_info_block+20
	movb	%dl, __go32_info_block+25
	call	___dpmi_get_segment_base_address
	xorl	%edx, %edx
	xorl	%eax, %eax
	movb	20(%esp), %dl
	movb	21(%esp), %al
	sall	$8, %edx
	movw	$4, __go32_info_block+36
	orl	%edx, %eax
	movw	%ax, __go32_info_block+38
	call	___djgpp_exception_setup
	call	_setup_environment
	movl	___environ_changed, %eax
	incl	%eax
	movl	%eax, ___environ_changed
	call	___setup_file_rec_list
	movl	$0, (%esp)
	call	__use_lfn
	movl	___dos_argv0, %ebx
	movb	(%ebx), %al
	testb	%al, %al
	je	L31
	leal	1(%ebx), %edx
	jmp	L34
	.p2align 4,,7
L51:
	cmpb	$58, %al
	je	L32
	cmpb	$47, %al
	je	L32
	movb	(%edx), %al
	incl	%edx
	testb	%al, %al
	je	L31
L34:
	cmpb	$92, %al
	jne	L51
L32:
	movb	(%edx), %al
	movl	%edx, %ebx
	incl	%edx
	testb	%al, %al
	jne	L34
L31:
	movl	__stubinfo, %eax
	cmpb	$0, 52(%eax)
	je	L35
	leal	52(%eax), %ebx
L35:
	movl	%ebx, (%esp)
	call	_strlen
	movl	$1, (%esp)
	leal	1(%eax), %edi
	movl	%edi, 4(%esp)
	call	_calloc
	movl	%edi, 8(%esp)
	movl	%eax, %esi
	movl	%ebx, 4(%esp)
	movl	%eax, (%esp)
	movl	%eax, _prog_name
	call	_memcpy
	movl	%esi, (%esp)
	call	___crt0_load_environment_file
	movl	$0, (%esp)
	call	__use_lfn
	movl	_prog_name, %eax
	movl	%eax, (%esp)
	call	_free
	call	___crt0_setup_arguments
	movl	___crt0_argv, %eax
	testl	%eax, %eax
	je	L36
	movl	(%eax), %eax
L37:
	movl	%eax, (%esp)
	call	__npxsetup
	call	__crt0_init_mcount
	call	___main
	movl	__environ, %eax
	movl	%eax, 8(%esp)
	movl	___crt0_argv, %eax
	movl	%eax, 4(%esp)
	movl	___crt0_argc, %eax
	movl	%eax, (%esp)
	movl	$0, _errno
	call	_main
	movl	%eax, (%esp)
	call	_exit
L49:
	movl	$655360, __go32_info_block+8
	movl	$655360, __go32_info_block+4
	jmp	L29
L50:
	movl	$720896, __go32_info_block+4
	movl	$753664, __go32_info_block+8
	jmp	L29
L36:
	movl	___dos_argv0, %eax
	jmp	L37
L48:
	movl	$_no_dos_ds_msg.3053, %ebx
	leal	28(%esp), %esi
	jmp	L25
L27:
	movl	%esi, 4(%esp)
	movl	$33, (%esp)
	movb	$2, 57(%esp)
	movb	%al, 48(%esp)
	call	___dpmi_int
	incl	%ebx
L25:
	movb	(%ebx), %al
	testb	%al, %al
	jne	L27
	movl	$107, (%esp)
	call	___exit
	.cfi_endproc
LFE29:
.comm __os_trueversion,16
	.globl	___PROXY_LEN
	.section .data
	.p2align 2
___PROXY_LEN:
	.long	7
	.globl	___PROXY
___PROXY:
	.ascii " !proxy\0"
.comm ___dos_argv0,16
.comm ___crt0_argv,16
.comm ___crt0_argc,16
	.globl	___bss_count
	.p2align 2
___bss_count:
	.long	1
.lcomm _prog_name,4,4
	.section .text
	.p2align 4
_no_dos_ds_msg.3053:
	.ascii "Cannot allocate selector for conventional memory; exiting\15\12\0"
	.ident	"GCC: (GNU) 4.7.4"
