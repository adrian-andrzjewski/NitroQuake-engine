	.file	"lfilelen.c"
	.section .text
	.p2align 4,,15
	.globl	___lfilelength
___lfilelength:
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
	subl	$96, %esp
	.cfi_def_cfa_offset 112
	movl	$0, (%esp)
	movl	112(%esp), %ebx
	call	__use_lfn
	testb	%al, %al
	je	L2
	movw	%bx, 60(%esp)
	movl	__go32_info_block+12, %eax
	movl	%ebx, %esi
	leal	44(%esp), %ebx
	shrl	$4, %eax
	movl	%ebx, 4(%esp)
	movl	$33, (%esp)
	movw	$1, 76(%esp)
	movw	$29094, 72(%esp)
	movw	%ax, 80(%esp)
	movw	$0, 64(%esp)
	call	___dpmi_int
	testb	$1, 76(%esp)
	je	L14
L3:
	movl	%ebx, 4(%esp)
	movl	$33, (%esp)
	movw	$16897, 72(%esp)
	movw	%si, 60(%esp)
	movw	$0, 64(%esp)
	movw	$0, 68(%esp)
	call	___dpmi_int
	testb	$1, 76(%esp)
	jne	L12
	movl	%ebx, 4(%esp)
	movl	$33, (%esp)
	movl	64(%esp), %edi
	movl	72(%esp), %esi
	movw	$0, 64(%esp)
	movw	$0, 68(%esp)
	movw	$16898, 72(%esp)
	call	___dpmi_int
	testb	$1, 76(%esp)
	jne	L12
	movl	64(%esp), %edx
	movl	72(%esp), %eax
	andl	$65535, %edx
	andl	$65535, %eax
	xorl	%ecx, %ecx
	movl	%eax, 24(%esp)
	shldl	$16, %edx, %ecx
	sall	$16, %edx
	movl	$0, 28(%esp)
	addl	24(%esp), %edx
	movl	%ebx, 4(%esp)
	adcl	28(%esp), %ecx
	movl	$33, (%esp)
	movl	%edx, 20(%esp)
	movl	%ecx, 16(%esp)
	movw	$16896, 72(%esp)
	movw	%di, 68(%esp)
	movw	%si, 64(%esp)
	call	___dpmi_int
	testb	$1, 76(%esp)
	movl	20(%esp), %edx
	movl	16(%esp), %ecx
	jne	L12
L5:
	addl	$96, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 16
	movl	%edx, %eax
	movl	%ecx, %edx
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
L2:
	.cfi_restore_state
	movl	%ebx, %esi
	leal	44(%esp), %ebx
	jmp	L3
	.p2align 4,,7
L14:
	cmpw	$28928, 72(%esp)
	je	L3
	movl	__go32_info_block+12, %esi
	movw	__go32_info_block+26, %ax
	leal	36(%esi), %edx
/APP
# 158 "c:/djgpp/include/libc/farptrgs.h" 1
	movw %ax,%gs
	.byte 0x65
	movl (%edx),%edx
# 0 "" 2
/NO_APP
	addl	$32, %esi
/APP
# 158 "c:/djgpp/include/libc/farptrgs.h" 1
	movw %ax,%gs
	.byte 0x65
	movl (%esi),%esi
# 0 "" 2
/NO_APP
	testl	%esi, %esi
	js	L15
	movl	%esi, %edi
	movl	%edx, %ecx
	sarl	$31, %ecx
	movl	$0, %esi
	addl	%esi, %edx
	adcl	%edi, %ecx
	addl	$96, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 16
	movl	%edx, %eax
	movl	%ecx, %edx
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
L12:
	.cfi_restore_state
	movl	72(%esp), %eax
	andl	$65535, %eax
	movl	%eax, (%esp)
	call	___doserr_to_errno
	orl	$-1, %edx
	movl	%eax, _errno
	orl	$-1, %ecx
	jmp	L5
L15:
	movl	$40, _errno
	orl	$-1, %edx
	orl	$-1, %ecx
	jmp	L5
	.cfi_endproc
LFE23:
	.ident	"GCC: (GNU) 4.7.4"
