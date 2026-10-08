	.file	"setmode.c"
	.section .text
	.p2align 4,,15
	.globl	___setmode
___setmode:
LFB0:
	.cfi_startproc
	pushl	%esi
	.cfi_def_cfa_offset 8
	.cfi_offset 6, -8
	pushl	%ebx
	.cfi_def_cfa_offset 12
	.cfi_offset 3, -12
	subl	$84, %esp
	.cfi_def_cfa_offset 96
	movl	96(%esp), %ebx
	movl	%ebx, (%esp)
	call	__get_dev_info
	cmpw	$-1, %ax
	je	L9
	movl	100(%esp), %esi
	movl	%eax, %edx
	andl	$4, %esi
	jne	L12
	andl	$-33, %edx
	movswl	%dx, %edx
L4:
	testb	$-128, %al
	je	L6
	leal	28(%esp), %eax
	andl	$255, %edx
	movl	%eax, 4(%esp)
	movl	$33, (%esp)
	movw	$17409, 56(%esp)
	movw	%bx, 44(%esp)
	movw	%dx, 48(%esp)
	call	___dpmi_int
	testb	$1, 60(%esp)
	jne	L13
	testl	%ebx, %ebx
	je	L14
L6:
	movl	___file_handle_modes, %eax
	movzbl	(%eax,%ebx), %esi
	movl	%esi, %edx
	movl	100(%esp), %eax
	andl	$-13, %edx
	andl	$12, %eax
	movsbl	%dl, %edx
	orl	%eax, %edx
	movl	%ebx, (%esp)
	movl	%edx, 4(%esp)
	call	___file_handle_set
	movl	%esi, %eax
	andl	$12, %eax
L2:
	addl	$84, %esp
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
L12:
	.cfi_restore_state
	orl	$32, %edx
	movswl	%dx, %edx
	jmp	L4
	.p2align 4,,7
L14:
	testl	%esi, %esi
	sete	%al
	andl	$255, %eax
	movl	%eax, (%esp)
	call	___djgpp_set_ctrl_c
	jmp	L6
	.p2align 4,,7
L9:
	orl	$-1, %eax
	jmp	L2
L13:
	movl	56(%esp), %eax
	andl	$65535, %eax
	movl	%eax, (%esp)
	call	___doserr_to_errno
	movl	%eax, _errno
	orl	$-1, %eax
	jmp	L2
	.cfi_endproc
LFE0:
.comm ___setmode_stdio_hook,16
	.ident	"GCC: (GNU) 4.7.4"
