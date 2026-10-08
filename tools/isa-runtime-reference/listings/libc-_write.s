	.file	"_write.c"
	.section .text
	.p2align 4,,15
___FSEXT_func_wrapper.constprop.0:
LFB27:
	.cfi_startproc
	subl	$28, %esp
	.cfi_def_cfa_offset 32
	leal	44(%esp), %eax
	movl	$4, (%esp)
	movl	%eax, 8(%esp)
	movl	40(%esp), %eax
	movl	%eax, 4(%esp)
	call	*32(%esp)
	addl	$28, %esp
	.cfi_def_cfa_offset 4
	ret
	.cfi_endproc
LFE27:
	.p2align 4,,15
	.globl	__write_int
__write_int:
LFB26:
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
	subl	$124, %esp
	.cfi_def_cfa_offset 144
	movl	__go32_info_block+16, %eax
	movl	152(%esp), %edx
	movl	156(%esp), %ecx
	movl	%edx, 24(%esp)
	movl	%ecx, 28(%esp)
	movl	24(%esp), %ecx
	movl	148(%esp), %ebx
	movl	%ecx, 44(%esp)
	movl	28(%esp), %ecx
	cmpl	$0, %ecx
	ja	L5
	cmpl	%eax, 44(%esp)
	ja	L5
L4:
	movl	144(%esp), %esi
	movl	$0, 36(%esp)
	jmp	L12
	.p2align 4,,7
L8:
	movl	__go32_info_block+12, %edx
	movl	$33, (%esp)
	movl	%edx, %eax
	movw	$16384, 88(%esp)
	andl	$15, %eax
	movw	%si, 76(%esp)
	movw	%ax, 80(%esp)
	leal	60(%esp), %eax
	shrl	$4, %edx
	movl	%eax, 4(%esp)
	movw	%di, 84(%esp)
	movw	%dx, 96(%esp)
	call	___dpmi_int
	testb	$1, 92(%esp)
	jne	L26
	movl	88(%esp), %ebp
	xorl	%edx, %edx
	movl	%ebp, %ecx
	andl	$65535, %ecx
	subl	%ecx, 24(%esp)
	sbbl	%edx, 28(%esp)
	movl	36(%esp), %edx
	addl	%ecx, %edx
	movl	%edx, 36(%esp)
	cmpb	$0, 43(%esp)
	je	L13
	addl	%ecx, %ebx
L11:
	movl	28(%esp), %edx
	orl	24(%esp), %edx
	je	L10
	andl	$65535, %ebp
	cmpl	%edi, %ebp
	jne	L27
L12:
	movl	28(%esp), %eax
	movl	24(%esp), %edi
	cmpl	$0, %eax
	ja	L7
	cmpl	44(%esp), %edi
	jbe	L6
L7:
	movl	44(%esp), %edi
L6:
	testl	%ebx, %ebx
	setne	43(%esp)
	testl	%edi, %edi
	je	L8
	cmpb	$0, 43(%esp)
	je	L8
	movl	__go32_info_block+12, %eax
	movl	%edi, 4(%esp)
	movl	%eax, 8(%esp)
	movl	%ebx, (%esp)
	call	___dosmemput
	jmp	L8
	.p2align 4,,7
L27:
	movl	36(%esp), %eax
	testl	%eax, %eax
	jne	L10
	movl	$26, _errno
	movl	$-1, 36(%esp)
	.p2align 4,,7
L10:
	movl	36(%esp), %eax
	addl	$124, %esp
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
L13:
	.cfi_restore_state
	xorl	%ebx, %ebx
	jmp	L11
	.p2align 4,,7
L5:
	movl	%eax, 44(%esp)
	jmp	L4
	.p2align 4,,7
L26:
	movl	88(%esp), %eax
	andl	$65535, %eax
	movl	%eax, (%esp)
	call	___doserr_to_errno
	movl	$-1, 36(%esp)
	movl	%eax, _errno
	movl	36(%esp), %eax
	addl	$124, %esp
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
LFE26:
	.p2align 4,,15
	.globl	__write_fill_seek_gap
__write_fill_seek_gap:
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
	subl	$44, %esp
	.cfi_def_cfa_offset 64
	movl	___fd_properties, %eax
	movl	64(%esp), %ebx
	leal	0(,%ebx,4), %ebp
	movl	(%eax,%ebp), %edx
	movl	8(%edx), %eax
	movl	%eax, %ecx
	andl	$-3, %ecx
	testb	$4, %al
	movl	%ecx, 8(%edx)
	je	L29
L47:
	xorl	%eax, %eax
L30:
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
	.p2align 4,,7
L29:
	.cfi_restore_state
	movl	%ebx, (%esp)
	call	__get_dev_info
	testb	$-128, %al
	je	L31
	movl	___fd_properties, %eax
	movl	(%eax,%ebp), %eax
	orl	$4, 8(%eax)
	jmp	L47
	.p2align 4,,7
L31:
	movl	%ebx, (%esp)
	call	___lfilelength
	movl	%eax, %esi
	movl	%edx, %edi
	testl	%edx, %edx
	js	L47
	movl	$1, 12(%esp)
	movl	$0, 4(%esp)
	movl	$0, 8(%esp)
	movl	%ebx, (%esp)
	call	___llseek
	movl	%edx, 28(%esp)
	movl	%eax, 24(%esp)
	movl	28(%esp), %ecx
	testl	%ecx, %ecx
	js	L47
	cmpl	28(%esp), %edi
	jg	L47
	jl	L38
	cmpl	24(%esp), %esi
	jae	L47
L38:
	movl	$0, 12(%esp)
	movl	%esi, 4(%esp)
	movl	%edi, 8(%esp)
	movl	%ebx, (%esp)
	call	___llseek
	andl	%edx, %eax
	incl	%eax
	je	L47
	movl	___fd_properties, %eax
	movl	(%eax,%ebp), %eax
	movl	8(%eax), %edx
	andl	$-3, %edx
	movl	%edx, 8(%eax)
	movl	24(%esp), %eax
	subl	%esi, %eax
	movl	28(%esp), %edx
	sbbl	%edi, %edx
	movl	__go32_info_block+16, %esi
	movl	%eax, %ebp
	cmpl	$0, %edx
	jl	L34
	jg	L35
	cmpl	%esi, %eax
	ja	L35
	.p2align 4,,7
L34:
/APP
# 169 "c:/djgpp/include/libc/farptrgs.h" 1
	movw __go32_info_block+26,%gs
# 0 "" 2
/NO_APP
	testl	%ebp, %ebp
	je	L36
	movl	__go32_info_block+12, %edi
	xorl	%ecx, %ecx
	.p2align 4,,7
L37:
	leal	(%ecx,%edi), %esi
/APP
# 208 "c:/djgpp/include/libc/farptrgs.h" 1
	.byte 0x65
	movl $0,(%esi)
# 0 "" 2
/NO_APP
	addl	$4, %ecx
	cmpl	%ecx, %ebp
	ja	L37
L36:
	movl	%eax, 8(%esp)
	movl	%edx, 12(%esp)
	movl	$0, 4(%esp)
	movl	%ebx, (%esp)
	call	__write_int
	jmp	L30
L35:
	movl	%esi, %ebp
	jmp	L34
	.cfi_endproc
LFE25:
	.p2align 4,,15
	.globl	__write
__write:
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
	subl	$48, %esp
	.cfi_def_cfa_offset 64
	movl	64(%esp), %ebx
	movl	68(%esp), %esi
	movl	%ebx, (%esp)
	movl	72(%esp), %edi
	call	___FSEXT_get_function
	testl	%eax, %eax
	je	L49
	leal	44(%esp), %edx
	movl	%edi, 20(%esp)
	movl	%esi, 16(%esp)
	movl	%ebx, 12(%esp)
	movl	%edx, 8(%esp)
	movl	$4, 4(%esp)
	movl	%eax, (%esp)
	call	___FSEXT_func_wrapper.constprop.0
	testl	%eax, %eax
	jne	L67
L49:
	testl	%ebx, %ebx
	js	L53
	movl	___fd_properties, %eax
	testl	%eax, %eax
	je	L53
	movl	(%eax,%ebx,4), %eax
	testl	%eax, %eax
	je	L53
	testb	$2, 8(%eax)
	jne	L68
L53:
	movl	%edi, 8(%esp)
	movl	$0, 12(%esp)
	movl	%esi, 4(%esp)
	movl	%ebx, (%esp)
	call	__write_int
L65:
	addl	$48, %esp
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
	movl	44(%esp), %eax
	addl	$48, %esp
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
L68:
	.cfi_restore_state
	movl	%ebx, (%esp)
	call	__write_fill_seek_gap
	testl	%eax, %eax
	jns	L53
	orl	$-1, %eax
	jmp	L65
	.cfi_endproc
LFE24:
	.ident	"GCC: (GNU) 4.7.4"
