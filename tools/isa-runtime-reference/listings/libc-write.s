	.file	"write.c"
	.section .text
	.p2align 4,,15
___FSEXT_func_wrapper.constprop.0:
LFB25:
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
LFE25:
	.p2align 4,,15
	.globl	___write
___write:
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
	subl	$76, %esp
	.cfi_def_cfa_offset 96
	movl	96(%esp), %eax
	movl	100(%esp), %ebp
	movl	%eax, (%esp)
	call	___FSEXT_get_function
	movl	%eax, %ebx
	movl	___libc_write_termios_hook, %eax
	testl	%eax, %eax
	je	L4
	leal	56(%esp), %edx
	movl	%ebp, 4(%esp)
	movl	%edx, 12(%esp)
	movl	104(%esp), %edx
	movl	%edx, 8(%esp)
	movl	96(%esp), %edx
	movl	%edx, (%esp)
	call	*%eax
	testl	%eax, %eax
	jne	L54
L4:
	movl	104(%esp), %ecx
	xorl	%eax, %eax
	testl	%ecx, %ecx
	je	L40
	movl	96(%esp), %edx
	testl	%edx, %edx
	js	L7
	movl	___fd_properties, %eax
	testl	%eax, %eax
	je	L7
	movl	96(%esp), %edx
	movl	(%eax,%edx,4), %eax
	testl	%eax, %eax
	je	L7
	movl	8(%eax), %eax
	testb	$32, %al
	jne	L55
	testb	$16, %al
	jne	L56
L7:
	movl	___file_handle_modes, %eax
	movl	96(%esp), %edx
	testb	$4, (%eax,%edx)
	jne	L57
	testl	%ebx, %ebx
	je	L11
	movl	96(%esp), %eax
	movl	104(%esp), %edx
	movl	%eax, 12(%esp)
	leal	60(%esp), %eax
	movl	%edx, 20(%esp)
	movl	%ebp, 16(%esp)
	movl	%eax, 8(%esp)
	movl	$4, 4(%esp)
	movl	%ebx, (%esp)
	call	___FSEXT_func_wrapper.constprop.0
	testl	%eax, %eax
	jne	L58
L11:
	movl	96(%esp), %eax
	testl	%eax, %eax
	js	L14
	movl	___fd_properties, %eax
	testl	%eax, %eax
	je	L14
	movl	96(%esp), %edx
	movl	(%eax,%edx,4), %eax
	testl	%eax, %eax
	je	L14
	testb	$2, 8(%eax)
	jne	L59
L14:
	xorl	%esi, %esi
	.p2align 4,,7
L13:
/APP
# 169 "c:/djgpp/include/libc/farptrgs.h" 1
	movw __go32_info_block+26,%gs
# 0 "" 2
/NO_APP
	movl	__go32_info_block+16, %edi
	testl	%edi, %edi
	je	L29
	cmpl	%esi, 104(%esp)
	jbe	L29
	leal	-1(%edi), %edx
	movl	__go32_info_block+12, %ecx
	xorl	%ebx, %ebx
	movl	%edx, 44(%esp)
	jmp	L21
	.p2align 4,,7
L18:
	leal	(%ebx,%ecx), %edx
/APP
# 188 "c:/djgpp/include/libc/farptrgs.h" 1
	.byte 0x65
	movb %al,(%edx)
# 0 "" 2
/NO_APP
	incl	%ebx
	incl	%esi
	cmpl	%edi, %ebx
	jae	L52
	cmpl	%esi, 104(%esp)
	jbe	L52
L21:
	movb	0(%ebp,%esi), %al
	cmpb	$10, %al
	jne	L18
	cmpl	%ebx, 44(%esp)
	je	L52
	leal	(%ebx,%ecx), %edx
/APP
# 188 "c:/djgpp/include/libc/farptrgs.h" 1
	.byte 0x65
	movb $13,(%edx)
# 0 "" 2
/NO_APP
	incl	%ebx
	jmp	L18
L59:
	movl	96(%esp), %eax
	movl	%eax, (%esp)
	call	__write_fill_seek_gap
	testl	%eax, %eax
	jns	L14
L16:
	orl	$-1, %eax
	.p2align 4,,7
L40:
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
L54:
	.cfi_restore_state
	movl	56(%esp), %eax
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
L52:
	.cfi_restore_state
	movl	%ebx, %eax
	xorl	%edx, %edx
L17:
	movl	%eax, 8(%esp)
	movl	96(%esp), %eax
	movl	%edx, 12(%esp)
	movl	$0, 4(%esp)
	movl	%eax, (%esp)
	call	__write_int
	testl	%eax, %eax
	js	L16
	cmpl	%ebx, %eax
	jb	L60
	cmpl	%esi, 104(%esp)
	ja	L13
	movl	104(%esp), %eax
	jmp	L40
L58:
	movl	60(%esp), %eax
	jmp	L40
L56:
	movl	96(%esp), %eax
	movl	$2, 12(%esp)
	movl	$0, 4(%esp)
	movl	$0, 8(%esp)
	movl	%eax, (%esp)
	call	___llseek
	andl	%edx, %eax
	incl	%eax
	jne	L7
	jmp	L16
	.p2align 4,,7
L60:
	addl	%esi, %eax
	movl	104(%esp), %edx
	movl	$26, _errno
	addl	$76, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 20
	subl	%eax, %edx
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 16
	movl	%edx, %eax
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
	movl	104(%esp), %eax
	movl	%ebp, 4(%esp)
	movl	%eax, 8(%esp)
	movl	%edx, (%esp)
	call	__write
	jmp	L40
L29:
	xorl	%eax, %eax
	xorl	%edx, %edx
	xorl	%ebx, %ebx
	jmp	L17
L55:
	movl	$6, _errno
	orl	$-1, %eax
	jmp	L40
	.cfi_endproc
LFE24:
	.ident	"GCC: (GNU) 4.7.4"
