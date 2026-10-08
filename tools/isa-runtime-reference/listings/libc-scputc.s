	.file	"scputc.c"
	.section .text
	.p2align 4,,15
	.globl	_ScreenPutChar
_ScreenPutChar:
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
	movl	28(%esp), %ebx
	movl	%ebx, %eax
	shrl	$31, %eax
	je	L8
L1:
	popl	%ebx
	.cfi_remember_state
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
L8:
	.cfi_restore_state
	movl	24(%esp), %eax
	shrl	$31, %eax
	jne	L1
	call	_ScreenCols
	cmpl	%eax, 24(%esp)
	jge	L1
	call	_ScreenRows
	cmpl	%eax, %ebx
	jge	L1
	movl	20(%esp), %edi
	movl	__go32_info_block+4, %esi
	sall	$8, %edi
	call	_ScreenCols
	imull	%ebx, %eax
	movzbl	16(%esp), %edx
	orl	%edx, %edi
	movl	24(%esp), %edx
	addl	%edx, %eax
	leal	(%esi,%eax,2), %eax
/APP
# 108 "c:/djgpp/include/libc/farptrgs.h" 1
	movw __go32_info_block+26,%gs 
	.byte 0x65 
	movw %di,(%eax)
# 0 "" 2
/NO_APP
	jmp	L1
	.cfi_endproc
LFE23:
	.ident	"GCC: (GNU) 4.7.4"
