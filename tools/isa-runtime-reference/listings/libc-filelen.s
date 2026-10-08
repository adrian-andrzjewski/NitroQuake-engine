	.file	"filelen.c"
	.section .text
	.p2align 4,,15
	.globl	___filelength
___filelength:
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
	movl	$0, (%esp)
	movl	112(%esp), %ebx
	call	__use_lfn
	testb	%al, %al
	je	L2
	testl	%ebx, %ebx
	jne	L3
	cmpw	$1330, __os_trueversion
	je	L9
L3:
	movw	%bx, 44(%esp)
	movl	__go32_info_block+12, %eax
	movl	%ebx, %esi
	leal	28(%esp), %ebx
	shrl	$4, %eax
	movl	%ebx, 4(%esp)
	movl	$33, (%esp)
	movw	$1, 60(%esp)
	movw	$29094, 56(%esp)
	movw	%ax, 64(%esp)
	movw	$0, 48(%esp)
	call	___dpmi_int
	testb	$1, 60(%esp)
	je	L16
L4:
	movl	%ebx, 4(%esp)
	movl	$33, (%esp)
	movw	$16897, 56(%esp)
	movw	%si, 44(%esp)
	movw	$0, 48(%esp)
	movw	$0, 52(%esp)
	call	___dpmi_int
	testb	$1, 60(%esp)
	jne	L14
	movl	%ebx, 4(%esp)
	movl	$33, (%esp)
	movl	48(%esp), %ebp
	movl	56(%esp), %edi
	movw	$0, 48(%esp)
	movw	$0, 52(%esp)
	movw	$16898, 56(%esp)
	call	___dpmi_int
	testb	$1, 60(%esp)
	jne	L14
	movl	48(%esp), %eax
	movl	56(%esp), %esi
	sall	$16, %eax
	andl	$65535, %esi
	movl	%ebx, 4(%esp)
	movl	$33, (%esp)
	addl	%eax, %esi
	movw	$16896, 56(%esp)
	movw	%bp, 52(%esp)
	movw	%di, 48(%esp)
	call	___dpmi_int
	testb	$1, 60(%esp)
	jne	L14
L6:
	addl	$92, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 20
	movl	%esi, %eax
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
L16:
	.cfi_restore_state
	cmpw	$28928, 56(%esp)
	je	L4
	movl	__go32_info_block+12, %edx
	movw	__go32_info_block+26, %ax
	leal	36(%edx), %esi
/APP
# 158 "c:/djgpp/include/libc/farptrgs.h" 1
	movw %ax,%gs
	.byte 0x65
	movl (%esi),%esi
# 0 "" 2
/NO_APP
	addl	$32, %edx
/APP
# 158 "c:/djgpp/include/libc/farptrgs.h" 1
	movw %ax,%gs
	.byte 0x65
	movl (%edx),%eax
# 0 "" 2
/NO_APP
	testl	%eax, %eax
	jne	L5
	cmpl	$-1, %esi
	jne	L6
L5:
	movl	$40, _errno
	orl	$-1, %esi
	jmp	L6
	.p2align 4,,7
L2:
	movl	%ebx, %esi
	leal	28(%esp), %ebx
	jmp	L4
	.p2align 4,,7
L9:
	xorl	%esi, %esi
	leal	28(%esp), %ebx
	jmp	L4
	.p2align 4,,7
L14:
	movl	56(%esp), %eax
	orl	$-1, %esi
	andl	$65535, %eax
	movl	%eax, (%esp)
	call	___doserr_to_errno
	movl	%eax, _errno
	jmp	L6
	.cfi_endproc
LFE23:
	.ident	"GCC: (GNU) 4.7.4"
