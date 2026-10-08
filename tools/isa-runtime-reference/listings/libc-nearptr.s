	.file	"nearptr.c"
	.section .text
	.p2align 4,,15
	.globl	___djgpp_nearptr_enable
___djgpp_nearptr_enable:
LFB3:
	.cfi_startproc
	pushl	%ebx
	.cfi_def_cfa_offset 8
	.cfi_offset 3, -8
	subl	$24, %esp
	.cfi_def_cfa_offset 32
/APP
# 36 "c:/djgpp/include/sys/segments.h" 1
	movw %ds,%bx
# 0 "" 2
/NO_APP
	andl	$65535, %ebx
	movl	$-1, 4(%esp)
	movl	%ebx, (%esp)
	call	___dpmi_set_segment_limit
	testl	%eax, %eax
	je	L2
L4:
	xorl	%eax, %eax
L3:
	addl	$24, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 8
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L2:
	.cfi_restore_state
	movl	%ebx, (%esp)
	call	___dpmi_get_segment_limit
	incl	%eax
	jne	L4
	movw	___djgpp_ds_alias, %ax
	movl	$-1, 4(%esp)
	andl	$65535, %eax
	movl	%eax, (%esp)
	call	___dpmi_set_segment_limit
	movl	$-1, 4(%esp)
/APP
# 28 "c:/djgpp/include/sys/segments.h" 1
	movw %cs,%ax
# 0 "" 2
/NO_APP
	andl	$65535, %eax
	movl	%eax, (%esp)
	call	___dpmi_set_segment_limit
	movl	$1, %eax
	orl	$128, __crt0_startup_flags
	jmp	L3
	.cfi_endproc
LFE3:
	.p2align 4,,15
	.globl	___djgpp_nearptr_disable
___djgpp_nearptr_disable:
LFB4:
	.cfi_startproc
	subl	$28, %esp
	.cfi_def_cfa_offset 32
	movl	___djgpp_selector_limit, %eax
	orl	$4095, %eax
/APP
# 28 "c:/djgpp/include/sys/segments.h" 1
	movw %cs,%dx
# 0 "" 2
/NO_APP
	movl	%eax, 4(%esp)
	movl	%edx, %eax
	andl	$65535, %eax
	movl	%eax, (%esp)
	call	___dpmi_set_segment_limit
	movl	___djgpp_selector_limit, %eax
	orl	$4095, %eax
	movl	%eax, 4(%esp)
	movw	___djgpp_ds_alias, %ax
	andl	$65535, %eax
	movl	%eax, (%esp)
	call	___dpmi_set_segment_limit
	movl	___djgpp_selector_limit, %eax
/APP
# 36 "c:/djgpp/include/sys/segments.h" 1
	movw %ds,%dx
# 0 "" 2
/NO_APP
	orl	$4095, %eax
	movl	%eax, 4(%esp)
	movl	%edx, %eax
	andl	$65535, %eax
	movl	%eax, (%esp)
	call	___dpmi_set_segment_limit
	movl	__crt0_startup_flags, %eax
	andb	$127, %al
	movl	%eax, __crt0_startup_flags
	addl	$28, %esp
	.cfi_def_cfa_offset 4
	ret
	.cfi_endproc
LFE4:
	.ident	"GCC: (GNU) 4.7.4"
