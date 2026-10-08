	.file	"clock.c"
	.section .text
	.p2align 4,,15
	.globl	_clock
_clock:
LFB18:
	.cfi_startproc
	movl	___bss_count, %eax
	pushl	%edi
	.cfi_def_cfa_offset 8
	.cfi_offset 7, -8
	cmpl	%eax, _clock_bss
	pushl	%esi
	.cfi_def_cfa_offset 12
	.cfi_offset 6, -12
	pushl	%ebx
	.cfi_def_cfa_offset 16
	.cfi_offset 3, -16
	je	L10
	movl	%eax, _clock_bss
	movl	$0, _base.1661
	xorl	%edi, %edi
	xorl	%esi, %esi
L3:
	movw	__go32_info_block+26, %cx
	movl	$1132, %edx
	.p2align 4,,7
L4:
/APP
# 158 "c:/djgpp/include/libc/farptrgs.h" 1
	movw %cx,%gs
	.byte 0x65
	movl (%edx),%ebx
# 0 "" 2
# 158 "c:/djgpp/include/libc/farptrgs.h" 1
	movw %cx,%gs
	.byte 0x65
	movl (%edx),%eax
# 0 "" 2
/NO_APP
	cmpl	%eax, %ebx
	jne	L4
	testl	%esi, %esi
	jne	L5
	movl	%eax, _base.1661
	movl	%eax, %esi
L5:
	cmpl	%eax, %edi
	jbe	L6
	subl	$1573040, %esi
	movl	%esi, _base.1661
L6:
	movl	%eax, _last_tics.1662
	subl	%esi, %eax
	popl	%ebx
	.cfi_remember_state
	.cfi_restore 3
	.cfi_def_cfa_offset 12
	popl	%esi
	.cfi_restore 6
	.cfi_def_cfa_offset 8
	leal	(%eax,%eax,4), %eax
	popl	%edi
	.cfi_restore 7
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L10:
	.cfi_restore_state
	movl	_base.1661, %esi
	movl	_last_tics.1662, %edi
	jmp	L3
	.cfi_endproc
LFE18:
	.section .data
	.p2align 2
_clock_bss:
	.long	-1
.lcomm _last_tics.1662,4,4
.lcomm _base.1661,4,4
	.ident	"GCC: (GNU) 4.7.4"
