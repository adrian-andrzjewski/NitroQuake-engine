	.file	"statfs.c"
	.section .text
LC0:
	.ascii "/\0"
	.p2align 4,,15
	.globl	___statfs
___statfs:
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
	subl	$300, %esp
	.cfi_def_cfa_offset 320
	movl	320(%esp), %ebp
	movl	324(%esp), %ebx
	movl	%ebp, (%esp)
	call	__put_path
	movl	__go32_info_block+12, %edx
	movw	__go32_info_block+26, %ax
/APP
# 132 "c:/djgpp/include/libc/farptrgs.h" 1
	movw %ax,%gs 
	.byte 0x65 
	movb (%edx),%cl
# 0 "" 2
/NO_APP
	incl	%edx
/APP
# 132 "c:/djgpp/include/libc/farptrgs.h" 1
	movw %ax,%gs 
	.byte 0x65 
	movb (%edx),%al
# 0 "" 2
/NO_APP
	cmpb	$58, %al
	je	L42
L2:
	leal	80(%esp), %eax
	movl	$33, (%esp)
	movl	%eax, 4(%esp)
	movb	$25, 109(%esp)
	call	___dpmi_int
	movb	108(%esp), %al
	andl	$255, %eax
	movl	%eax, %esi
L3:
	leal	132(%esp), %edi
	movl	$47, (%esp)
	movl	%edi, 4(%esp)
	movw	$5387, 160(%esp)
	movw	%si, 156(%esp)
	call	___dpmi_int
	testb	$1, 164(%esp)
	movl	$0, 32(%esp)
	jne	L4
	cmpw	$-21075, 148(%esp)
	jne	L4
	cmpw	$0, 160(%esp)
	je	L4
	movl	__go32_info_block+12, %ecx
	movl	$0, 64(%esp)
	movl	%ecx, %eax
	movl	$0, 60(%esp)
	shrl	$4, %eax
	movl	$0, 76(%esp)
	movw	%ax, 66(%esp)
	leal	2(%ecx), %eax
	movl	%ebx, 44(%esp)
	movl	$0, 68(%esp)
	movl	$0, 72(%esp)
	movb	$20, 60(%esp)
	movb	$3, 62(%esp)
	movb	$4, 78(%esp)
	movw	__go32_info_block+26, %dx
	movl	$2, 36(%esp)
	movl	%esi, 40(%esp)
	movl	%eax, %ebx
L8:
/APP
# 96 "c:/djgpp/include/libc/farptrgs.h" 1
	movw %dx,%gs
	.byte 0x65 
	movb $7,(%ecx)
# 0 "" 2
/NO_APP
	leal	1(%ecx), %eax
/APP
# 96 "c:/djgpp/include/libc/farptrgs.h" 1
	movw %dx,%gs
	.byte 0x65 
	movb $0,(%eax)
# 0 "" 2
# 108 "c:/djgpp/include/libc/farptrgs.h" 1
	movw %dx,%gs 
	.byte 0x65 
	movw $0,(%ebx)
# 0 "" 2
/NO_APP
	addl	$4, %ecx
	leal	60(%esp), %ebp
	movl	%ecx, 8(%esp)
	movl	$20, 4(%esp)
	movl	%ebp, (%esp)
	call	___dosmemput
	movl	__go32_info_block+12, %eax
	shrl	$4, %eax
	movl	%edi, 4(%esp)
	movl	$47, (%esp)
	movw	$5392, 160(%esp)
	movw	%si, 156(%esp)
	movw	%ax, 166(%esp)
	movw	$4, 148(%esp)
	call	___dpmi_int
	movl	__go32_info_block+12, %ecx
	movw	__go32_info_block+26, %dx
	leal	7(%ecx), %eax
/APP
# 145 "c:/djgpp/include/libc/farptrgs.h" 1
	movw %dx, %gs 
	.byte 0x65 
	movw (%eax),%ax 

# 0 "" 2
/NO_APP
	leal	2(%ecx), %ebx
/APP
# 145 "c:/djgpp/include/libc/farptrgs.h" 1
	movw %dx, %gs 
	.byte 0x65 
	movw (%ebx),%bp 

# 0 "" 2
/NO_APP
	decl	36(%esp)
	movw	%bp, 32(%esp)
	je	L39
	movl	%eax, %ebp
	andl	$-32753, %ebp
	cmpw	$-32753, %bp
	je	L8
	.p2align 4,,7
L39:
	movw	%ax, 36(%esp)
	movl	32(%esp), %eax
	andl	$65535, %eax
	movl	%esi, %ebp
	movl	44(%esp), %ebx
	movl	40(%esp), %esi
	movl	%eax, 32(%esp)
	cmpw	$256, 36(%esp)
	je	L43
L4:
	movw	__osmajor, %ax
	subl	$7, %eax
	cmpw	$2, %ax
	jbe	L25
	leal	1(%esi), %eax
	movl	$33, (%esp)
	movb	%al, 256(%esp)
	leal	236(%esp), %eax
	movl	%eax, 4(%esp)
	movb	$54, 265(%esp)
	call	___dpmi_int
	movl	264(%esp), %edx
	cmpw	$-1, %dx
	je	L40
	movl	260(%esp), %eax
	andl	$65535, %edx
	andl	$65535, %eax
	movl	252(%esp), %ecx
	imull	%edx, %eax
	movl	256(%esp), %edi
	andl	$65535, %ecx
	andl	$65535, %edi
L11:
	movl	%eax, 4(%ebx)
	movl	%ecx, 16(%ebx)
	movl	%ecx, 12(%ebx)
	movl	%edi, 8(%ebx)
	movl	%ecx, 24(%ebx)
	movl	%edi, 20(%ebx)
	movl	$0, (%ebx)
	movl	%esi, 28(%ebx)
	movl	$0, 32(%ebx)
	movl	$72020, 36(%ebx)
	xorl	%eax, %eax
L36:
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
L42:
	.cfi_restore_state
	movl	$31, %esi
	andl	%ecx, %esi
	decl	%esi
	cmpl	$-1, %esi
	jne	L3
	jmp	L2
	.p2align 4,,7
L43:
	leal	22(%ecx), %eax
/APP
# 145 "c:/djgpp/include/libc/farptrgs.h" 1
	movw %dx, %gs 
	.byte 0x65 
	movw (%eax),%ax 

# 0 "" 2
/NO_APP
	cmpw	$4, %ax
	jne	L4
	movb	$5, 78(%esp)
/APP
# 96 "c:/djgpp/include/libc/farptrgs.h" 1
	movw %dx,%gs
	.byte 0x65 
	movb $8,(%ecx)
# 0 "" 2
/NO_APP
	leal	1(%ecx), %eax
/APP
# 120 "c:/djgpp/include/libc/farptrgs.h" 1
	movw %dx,%gs 
	.byte 0x65 
	movl $0,(%eax)
# 0 "" 2
/NO_APP
	leal	5(%ecx), %eax
	movl	$20, 4(%esp)
	movl	%eax, 8(%esp)
	leal	60(%esp), %eax
	movl	%eax, (%esp)
	call	___dosmemput
	movl	__go32_info_block+12, %eax
	shrl	$4, %eax
	movl	%edi, 4(%esp)
	movl	$47, (%esp)
	movw	$5392, 160(%esp)
	movw	%bp, 156(%esp)
	movw	%ax, 166(%esp)
	movw	$5, 148(%esp)
	call	___dpmi_int
	movl	__go32_info_block+12, %edx
	movw	__go32_info_block+26, %ax
	leal	8(%edx), %ecx
/APP
# 145 "c:/djgpp/include/libc/farptrgs.h" 1
	movw %ax, %gs 
	.byte 0x65 
	movw (%ecx),%cx 

# 0 "" 2
/NO_APP
	cmpw	$256, %cx
	jne	L4
	leal	23(%edx), %ecx
/APP
# 145 "c:/djgpp/include/libc/farptrgs.h" 1
	movw %ax, %gs 
	.byte 0x65 
	movw (%ecx),%cx 

# 0 "" 2
/NO_APP
	cmpw	$5, %cx
	jne	L4
	incl	%edx
/APP
# 158 "c:/djgpp/include/libc/farptrgs.h" 1
	movw %ax,%gs
	.byte 0x65
	movl (%edx),%edi
# 0 "" 2
/NO_APP
	movw	__osmajor, %ax
	subl	$7, %eax
	cmpw	$2, %ax
	ja	L24
	movl	$1, 36(%esp)
L10:
	movl	320(%esp), %ebp
	testl	%ebp, %ebp
	je	L12
	movl	320(%esp), %ebp
	cmpb	$0, 0(%ebp)
	je	L44
L12:
	movl	320(%esp), %ebp
	movl	$256, 4(%esp)
	movl	%ebp, (%esp)
	call	__put_path2
L13:
	movl	$2, %eax
/APP
# 108 "c:/djgpp/include/libc/farptrgs.h" 1
	movw __go32_info_block+26,%gs 
	.byte 0x65 
	movw $0,(%eax)
# 0 "" 2
/NO_APP
	movl	__go32_info_block+12, %eax
	leal	80(%esp), %ebp
	shrl	$4, %eax
	movl	%ebp, 4(%esp)
	movl	$33, (%esp)
	movw	$29443, 108(%esp)
	movw	%ax, 114(%esp)
	movw	%ax, 116(%esp)
	movw	$256, 100(%esp)
	movw	$0, 80(%esp)
	movw	$256, 104(%esp)
	call	___dpmi_int
	testb	$1, 112(%esp)
	jne	L45
	movl	__go32_info_block+12, %edi
	movw	__go32_info_block+26, %dx
	leal	12(%edi), %ecx
/APP
# 158 "c:/djgpp/include/libc/farptrgs.h" 1
	movw %dx,%gs
	.byte 0x65
	movl (%ecx),%ecx
# 0 "" 2
/NO_APP
	leal	8(%edi), %ebp
/APP
# 158 "c:/djgpp/include/libc/farptrgs.h" 1
	movw %dx,%gs
	.byte 0x65
	movl (%ebp),%ebp
# 0 "" 2
/NO_APP
	leal	4(%edi), %eax
/APP
# 158 "c:/djgpp/include/libc/farptrgs.h" 1
	movw %dx,%gs
	.byte 0x65
	movl (%eax),%eax
# 0 "" 2
/NO_APP
	imull	%ebp, %eax
	addl	$16, %edi
/APP
# 158 "c:/djgpp/include/libc/farptrgs.h" 1
	movw %dx,%gs
	.byte 0x65
	movl (%edi),%edi
# 0 "" 2
/NO_APP
	movl	36(%esp), %edx
	testl	%edx, %edx
	je	L11
	cmpl	$2048, %eax
	jle	L11
	movl	%eax, %edx
	sarl	$31, %edx
	idivl	32(%esp)
	imull	%eax, %edi
	imull	%eax, %ecx
	movl	32(%esp), %eax
	jmp	L11
	.p2align 4,,7
L45:
	movl	__go32_info_block+12, %eax
	leal	1(%esi), %edx
	shrl	$4, %eax
	movl	%ebp, 4(%esp)
	movl	$33, (%esp)
	movb	%dl, 100(%esp)
	movb	%dl, 28(%esp)
	movw	$29442, 108(%esp)
	movw	%ax, 114(%esp)
	movw	$0, 80(%esp)
	movw	$256, 104(%esp)
	call	___dpmi_int
	testb	$1, 112(%esp)
	movb	28(%esp), %dl
	je	L15
	movl	36(%esp), %ecx
	testl	%ecx, %ecx
	je	L46
L24:
	movl	32(%esp), %eax
	xorl	%ecx, %ecx
	jmp	L11
	.p2align 4,,7
L44:
	movl	$256, 4(%esp)
	movl	$LC0, (%esp)
	call	__put_path2
	jmp	L13
	.p2align 4,,7
L15:
	movl	__go32_info_block+12, %edi
	movw	__go32_info_block+26, %dx
	leal	33(%edi), %ecx
/APP
# 158 "c:/djgpp/include/libc/farptrgs.h" 1
	movw %dx,%gs
	.byte 0x65
	movl (%ecx),%ecx
# 0 "" 2
/NO_APP
	leal	4(%edi), %eax
/APP
# 145 "c:/djgpp/include/libc/farptrgs.h" 1
	movw %dx, %gs 
	.byte 0x65 
	movw (%eax),%bp 

# 0 "" 2
/NO_APP
	movw	%bp, 32(%esp)
	leal	6(%edi), %ebp
/APP
# 132 "c:/djgpp/include/libc/farptrgs.h" 1
	movw %dx,%gs 
	.byte 0x65 
	movb (%ebp),%al
# 0 "" 2
/NO_APP
	movl	%eax, %ebp
	movl	32(%esp), %eax
	andl	$255, %ebp
	andl	$65535, %eax
	incl	%ebp
	addl	$47, %edi
	imull	%ebp, %eax
/APP
# 158 "c:/djgpp/include/libc/farptrgs.h" 1
	movw %dx,%gs
	.byte 0x65
	movl (%edi),%edi
# 0 "" 2
/NO_APP
	decl	%edi
	jmp	L11
	.p2align 4,,7
L46:
	leal	184(%esp), %eax
	movl	$33, (%esp)
	movl	%eax, 4(%esp)
	movb	%dl, 204(%esp)
	movb	$54, 213(%esp)
	call	___dpmi_int
	movl	212(%esp), %edx
	cmpw	$-1, %dx
	je	L40
	movl	208(%esp), %eax
	andl	$65535, %edx
	andl	$65535, %eax
	movl	200(%esp), %ecx
	movl	204(%esp), %edi
	andl	$65535, %ecx
	imull	%edx, %eax
	andl	$65535, %edi
	jmp	L11
L40:
	movl	$21, _errno
	orl	$-1, %eax
	jmp	L36
L25:
	movl	$0, 36(%esp)
	xorl	%edi, %edi
	jmp	L10
	.cfi_endproc
LFE25:
	.ident	"GCC: (GNU) 4.7.4"
