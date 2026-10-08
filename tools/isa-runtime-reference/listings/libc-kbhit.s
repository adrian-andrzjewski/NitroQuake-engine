	.file	"kbhit.c"
	.section .text
	.p2align 4,,15
	.globl	_kbhit
_kbhit:
LFB23:
	.cfi_startproc
	movw	__go32_info_block+26, %ax
	movl	$1050, %ecx
/APP
# 145 "c:/djgpp/include/libc/farptrgs.h" 1
	movw %ax, %gs 
	.byte 0x65 
	movw (%ecx),%cx 

# 0 "" 2
/NO_APP
	movl	$1052, %edx
/APP
# 145 "c:/djgpp/include/libc/farptrgs.h" 1
	movw %ax, %gs 
	.byte 0x65 
	movw (%edx),%dx 

# 0 "" 2
/NO_APP
	xorl	%eax, %eax
	cmpw	%dx, %cx
	je	L6
	subl	$92, %esp
	.cfi_def_cfa_offset 96
	leal	28(%esp), %eax
	movl	$22, (%esp)
	movl	%eax, 4(%esp)
	movb	$17, 57(%esp)
	call	___dpmi_int
	movl	60(%esp), %eax
	shrw	$6, %ax
	addl	$92, %esp
	.cfi_def_cfa_offset 4
	xorl	$1, %eax
	andl	$1, %eax
L6:
	ret
	.cfi_endproc
LFE23:
	.ident	"GCC: (GNU) 4.7.4"
