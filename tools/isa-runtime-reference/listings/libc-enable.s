	.file	"enable.c"
	.section .text
	.p2align 4,,15
	.globl	_enable
_enable:
LFB6:
	.cfi_startproc
/APP
# 12 "enable.c" 1
	pushf; popl %eax
# 0 "" 2
/NO_APP
	sarl	$9, %eax
/APP
# 14 "enable.c" 1
	sti
# 0 "" 2
/NO_APP
	andl	$1, %eax
	ret
	.cfi_endproc
LFE6:
	.ident	"GCC: (GNU) 4.7.4"
