	.file	"lconv.c"
	.section .text
	.p2align 4,,15
	.globl	_localeconv
_localeconv:
LFB0:
	.cfi_startproc
	movl	$___lconv_, %eax
	ret
	.cfi_endproc
LFE0:
	.section .data
	.p2align 4
___lconv_:
	.long	_ESTR
	.long	_DSTR
	.long	_ESTR
	.long	_ESTR
	.long	_ESTR
	.long	_ESTR
	.long	_ESTR
	.long	_ESTR
	.long	_ESTR
	.long	_ESTR
	.byte	127
	.byte	127
	.byte	127
	.byte	127
	.byte	127
	.byte	127
	.byte	127
	.byte	127
	.byte	127
	.byte	127
	.byte	127
	.byte	127
	.byte	127
	.byte	127
	.space 2
.lcomm _ESTR,1,1
_DSTR:
	.ascii ".\0"
	.ident	"GCC: (GNU) 4.7.4"
