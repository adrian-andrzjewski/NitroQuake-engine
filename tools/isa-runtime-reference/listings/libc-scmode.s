	.file	"scmode.c"
	.section .text
	.p2align 4,,15
	.globl	_ScreenMode
_ScreenMode:
LFB23:
	.cfi_startproc
	movl	$1097, %eax
/APP
# 132 "c:/djgpp/include/libc/farptrgs.h" 1
	movw __go32_info_block+26,%gs 
	.byte 0x65 
	movb (%eax),%al
# 0 "" 2
/NO_APP
	andl	$255, %eax
	ret
	.cfi_endproc
LFE23:
	.ident	"GCC: (GNU) 4.7.4"
