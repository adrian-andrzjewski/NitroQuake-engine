	.file	"disable.c"
	.section .text
	.p2align 4,,15
	.globl	_disable
_disable:
LFB6:
	.cfi_startproc
/APP
# 12 "disable.c" 1
	pushf; popl %eax
# 0 "" 2
/NO_APP
	sarl	$9, %eax
/APP
# 14 "disable.c" 1
	cli
# 0 "" 2
/NO_APP
	andl	$1, %eax
	ret
	.cfi_endproc
LFE6:
	.ident	"GCC: (GNU) 4.7.4"
