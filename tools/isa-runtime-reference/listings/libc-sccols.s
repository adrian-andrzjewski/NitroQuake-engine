	.file	"sccols.c"
	.section .text
	.p2align 4,,15
	.globl	_ScreenCols
_ScreenCols:
LFB23:
	.cfi_startproc
	movl	$1098, %eax
/APP
# 145 "c:/djgpp/include/libc/farptrgs.h" 1
	movw __go32_info_block+26, %gs 
	.byte 0x65 
	movw (%eax),%ax 

# 0 "" 2
/NO_APP
	andl	$65535, %eax
	ret
	.cfi_endproc
LFE23:
	.ident	"GCC: (GNU) 4.7.4"
