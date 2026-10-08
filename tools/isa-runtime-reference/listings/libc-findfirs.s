	.file	"findfirs.c"
	.section .text
	.p2align 4,,15
	.globl	___findfirst
___findfirst:
LFB3:
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
	subl	$428, %esp
	.cfi_def_cfa_offset 448
	movl	$0, (%esp)
	movl	448(%esp), %ebx
	call	__use_lfn
	movl	452(%esp), %ecx
	testl	%ecx, %ecx
	je	L17
	testl	%ebx, %ebx
	je	L17
	movl	%ebx, (%esp)
	movl	%eax, %edi
	call	_strlen
	movl	%ebx, (%esp)
	movzbl	456(%esp), %ebp
	leal	1(%eax), %esi
	call	__put_path
	movl	%edi, %eax
	testb	%al, %al
	je	L5
	leal	98(%esp), %edx
	movl	%edx, %edi
	movl	%edx, 28(%esp)
	testl	$2, %edi
	movl	$318, %edx
	jne	L30
L6:
	movl	%edx, %ecx
	xorl	%eax, %eax
	shrl	$2, %ecx
	andl	$2, %edx
	rep stosl
	je	L8
	movw	$0, (%edi)
L8:
	movl	__go32_info_block+12, %eax
	movl	$318, 4(%esp)
	addl	%esi, %eax
	leal	44(%esp), %edi
	movl	%eax, 8(%esp)
	leal	98(%esp), %eax
	movl	%eax, (%esp)
	call	___dosmemput
	movl	__go32_info_block+12, %eax
	shrl	$4, %eax
	movl	%edi, 4(%esp)
	movl	$33, (%esp)
	movw	$1, 76(%esp)
	movw	$29006, 72(%esp)
	movw	%bp, 68(%esp)
	movw	$0, 64(%esp)
	movw	%ax, 80(%esp)
	movw	%si, 44(%esp)
	movw	%ax, 78(%esp)
	movw	$1, 48(%esp)
	call	___dpmi_int
	testb	$1, 76(%esp)
	jne	L15
	cmpw	$28928, 72(%esp)
	je	L16
	leal	98(%esp), %edx
	movl	$318, 4(%esp)
	movl	%edx, 8(%esp)
	movl	__go32_info_block+12, %edx
	addl	%edx, %esi
	movl	%esi, (%esp)
	call	___dosmemget
	movl	452(%esp), %edx
	movl	98(%esp), %eax
	movb	%al, 21(%edx)
	movl	118(%esp), %eax
	movw	%ax, 22(%edx)
	shrl	$16, %eax
	movw	%ax, 24(%edx)
	movl	130(%esp), %eax
	movl	%eax, 26(%edx)
	leal	142(%esp), %eax
	movl	%eax, 4(%esp)
	movl	%edx, %eax
	addl	$30, %eax
	movl	%eax, (%esp)
	call	_strcpy
	movl	452(%esp), %edx
	movl	$860767820, (%edx)
	movw	$50, 4(%edx)
	movl	$42, 4(%esp)
	movl	%ebx, (%esp)
	call	_strchr
	testl	%eax, %eax
	je	L11
L28:
	movl	72(%esp), %eax
L12:
	movl	452(%esp), %edx
	movw	%ax, 6(%edx)
	movl	102(%esp), %eax
	movw	%ax, 8(%edx)
	shrl	$16, %eax
	movw	%ax, 10(%edx)
	movl	110(%esp), %eax
	movw	%ax, 12(%edx)
	shrl	$16, %eax
	movw	%ax, 14(%edx)
	addl	$428, %esp
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
L5:
	.cfi_restore_state
	movl	__go32_info_block+12, %eax
	leal	44(%esp), %ebx
	shrl	$4, %eax
	movl	%ebx, 4(%esp)
	movl	$33, (%esp)
	movw	%si, 64(%esp)
	movw	%ax, 80(%esp)
	movb	$26, 73(%esp)
	call	___dpmi_int
	movl	__go32_info_block+12, %eax
	shrl	$4, %eax
	movl	%ebx, 4(%esp)
	movl	$33, (%esp)
	movb	$78, 73(%esp)
	movw	$0, 64(%esp)
	movw	%ax, 80(%esp)
	movw	%bp, 68(%esp)
	call	___dpmi_int
	testb	$1, 76(%esp)
	je	L31
L15:
	movl	72(%esp), %eax
L14:
	andl	$65535, %eax
	movl	%eax, (%esp)
	call	___doserr_to_errno
	movl	%eax, _errno
L4:
	addl	$428, %esp
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
L16:
	.cfi_restore_state
	movl	$28928, %eax
	jmp	L14
	.p2align 4,,7
L31:
	movl	__go32_info_block+12, %eax
	movl	452(%esp), %edx
	addl	%eax, %esi
	movl	%edx, 8(%esp)
	movl	$44, 4(%esp)
	movl	%esi, (%esp)
	call	___dosmemget
	xorl	%eax, %eax
	jmp	L4
	.p2align 4,,7
L17:
	movl	$4, _errno
	orl	$-1, %eax
	jmp	L4
	.p2align 4,,7
L30:
	movw	$0, 98(%esp)
	leal	100(%esp), %edi
	movb	$60, %dl
	jmp	L6
	.p2align 4,,7
L11:
	movl	$63, 4(%esp)
	movl	%ebx, (%esp)
	call	_strchr
	testl	%eax, %eax
	jne	L28
	movl	72(%esp), %eax
	movl	%edi, 4(%esp)
	movl	$33, (%esp)
	movw	%ax, 60(%esp)
	orw	$1, 76(%esp)
	movw	$29089, 72(%esp)
	call	___dpmi_int
	xorl	%eax, %eax
	jmp	L12
	.cfi_endproc
LFE3:
	.ident	"GCC: (GNU) 4.7.4"
