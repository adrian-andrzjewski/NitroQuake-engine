	.file	"dpmiexcp.c"
	.section .text
	.p2align 4,,15
_itox:
LFB23:
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
	subl	$28, %esp
	.cfi_def_cfa_offset 48
	testl	%edx, %edx
	je	L6
	movl	$_buf.3468+7, %edi
	movl	$_buf.3468+7, %ebp
	subl	%edx, %edi
	movl	%ebp, %ecx
	jmp	L5
	.p2align 4,,7
L11:
	leal	48(%esi), %ebx
	movb	%bl, (%ecx)
	decl	%ecx
	cmpl	%edi, %ecx
	je	L10
L5:
	movl	%eax, %ebx
	sarl	$4, %eax
	andl	$15, %ebx
	movl	%ebx, %esi
	cmpl	$9, %ebx
	jle	L11
	leal	87(%esi), %ebx
	movb	%bl, (%ecx)
	decl	%ecx
	cmpl	%edi, %ecx
	jne	L5
L10:
	movl	%ebp, %eax
	subl	%edx, %eax
L2:
	subl	%eax, %ebp
	incl	%eax
	movl	%ebp, 8(%esp)
	movl	%eax, 4(%esp)
	movl	$2, (%esp)
	call	__write
	addl	$28, %esp
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
L6:
	.cfi_restore_state
	movl	$_buf.3468+7, %ebp
	movl	%ebp, %eax
	jmp	L2
	.cfi_endproc
LFE23:
LC0:
	.ascii "Exiting due to signal \0"
LC1:
	.ascii "SIG\0"
LC2:
	.ascii "0x\0"
LC3:
	.ascii "\15\12\0"
	.p2align 4,,15
_print_signal_name:
LFB29:
	.cfi_startproc
	pushl	%esi
	.cfi_def_cfa_offset 8
	.cfi_offset 6, -8
	pushl	%ebx
	.cfi_def_cfa_offset 12
	.cfi_offset 3, -12
	subl	$20, %esp
	.cfi_def_cfa_offset 32
	movl	%eax, %ebx
	movl	$22, 8(%esp)
	movl	$LC0, 4(%esp)
	movl	$2, (%esp)
	leal	-288(%ebx), %esi
	call	__write
	cmpl	$14, %esi
	jbe	L16
	movl	$2, 8(%esp)
	movl	$LC2, 4(%esp)
	movl	$2, (%esp)
	call	__write
	movl	$4, %edx
	movl	%ebx, %eax
	call	_itox
L14:
	movl	$2, 8(%esp)
	movl	$LC3, 4(%esp)
	movl	$2, (%esp)
	call	__write
	addl	$20, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 12
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 8
	popl	%esi
	.cfi_restore 6
	.cfi_def_cfa_offset 4
	ret
L16:
	.cfi_restore_state
	movl	$3, 8(%esp)
	movl	$LC1, 4(%esp)
	movl	$2, (%esp)
	call	__write
	leal	_signames(,%esi,4), %eax
	movl	$4, 8(%esp)
	movl	%eax, 4(%esp)
	movl	$2, (%esp)
	call	__write
	jmp	L14
	.cfi_endproc
LFE29:
LC4:
	.ascii ": sel=\0"
LC5:
	.ascii "  invalid\0"
LC6:
	.ascii "  base=\0"
LC7:
	.ascii "  limit=\0"
	.p2align 4,,15
_dump_selector:
LFB26:
	.cfi_startproc
	pushl	%ebx
	.cfi_def_cfa_offset 8
	.cfi_offset 3, -8
	movl	%edx, %ebx
	subl	$40, %esp
	.cfi_def_cfa_offset 48
	movl	$2, 8(%esp)
	movl	%eax, 4(%esp)
	movl	$2, (%esp)
	call	__write
	movl	$6, 8(%esp)
	movl	$LC4, 4(%esp)
	movl	$2, (%esp)
	call	__write
	movl	$4, %edx
	movl	%ebx, %eax
	call	_itox
	testl	%ebx, %ebx
	jne	L24
L18:
	movl	$2, 8(%esp)
	movl	$LC3, 4(%esp)
	movl	$2, (%esp)
	call	__write
	addl	$40, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 8
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 4
	ret
L24:
	.cfi_restore_state
	leal	28(%esp), %eax
	movl	%ebx, (%esp)
	movl	%eax, 4(%esp)
	call	___dpmi_get_segment_base_address
	testl	%eax, %eax
	jne	L25
	movl	$7, 8(%esp)
	movl	$LC6, 4(%esp)
	movl	$2, (%esp)
	call	__write
	movl	$8, %edx
	movl	28(%esp), %eax
	call	_itox
	movl	%ebx, (%esp)
	call	___dpmi_get_segment_limit
	movl	$8, 8(%esp)
	movl	%eax, %ebx
	movl	$LC7, 4(%esp)
	movl	$2, (%esp)
	call	__write
	movl	$8, %edx
	movl	%ebx, %eax
	call	_itox
	jmp	L18
L25:
	movl	$9, 8(%esp)
	movl	$LC5, 4(%esp)
	movl	$2, (%esp)
	call	__write
	jmp	L18
	.cfi_endproc
LFE26:
	.p2align 4,,15
_except_to_sig:
LFB24:
	.cfi_startproc
	cmpl	$16, %eax
	jbe	L39
L27:
	cmpl	$117, %eax
	je	L35
	cmpl	$120, %eax
	je	L36
	cmpl	$27, %eax
	je	L37
	cmpl	$121, %eax
	je	L37
	cmpl	$122, %eax
	sete	%al
	andl	$255, %eax
	leal	290(,%eax,8), %eax
	ret
L39:
	jmp	*L32(,%eax,4)
	.p2align 2
	.p2align 2
L32:
	.long	L35
	.long	L29
	.long	L27
	.long	L29
	.long	L35
	.long	L30
	.long	L27
	.long	L31
	.long	L30
	.long	L30
	.long	L27
	.long	L30
	.long	L30
	.long	L30
	.long	L30
	.long	L27
	.long	L35
L35:
	movl	$289, %eax
	ret
L31:
	movl	$301, %eax
	ret
L30:
	movl	$291, %eax
	ret
L29:
	movl	$302, %eax
	ret
L37:
	movl	$295, %eax
	ret
L36:
	movl	$303, %eax
	ret
	.cfi_endproc
LFE24:
	.p2align 4,,15
	.globl	_signal
_signal:
LFB28:
	.cfi_startproc
	movl	4(%esp), %eax
	leal	-1(%eax), %edx
	cmpl	$319, %edx
	ja	L44
	cmpl	$296, %eax
	je	L44
	movl	8(%esp), %ecx
	movl	_signal_list(,%edx,4), %eax
	movl	%ecx, _signal_list(,%edx,4)
	ret
	.p2align 4,,7
L44:
	movl	$14, _errno
	movl	$1, %eax
	ret
	.cfi_endproc
LFE28:
	.p2align 4,,15
	.globl	___djgpp_exception_toggle
___djgpp_exception_toggle:
LFB33:
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
	xorl	%edi, %edi
	subl	$32, %esp
	.cfi_def_cfa_offset 48
	movl	$1, %ebx
	leal	24(%esp), %esi
	.p2align 4,,7
L46:
	movl	%esi, 4(%esp)
	movl	%edi, (%esp)
	call	___dpmi_get_processor_exception_handler_vector
	cmpl	$2, %edi
	jne	L47
	testb	$2, __crt0_startup_flags+1
	jne	L47
	movl	24(%esp), %eax
	movl	28(%esp), %edx
	movl	%eax, _except_ori+16
	movl	%edx, _except_ori+20
L49:
	incl	%edi
	incl	%ebx
	jmp	L46
	.p2align 4,,7
L47:
	leal	_except_ori(,%edi,8), %eax
	movl	%edi, (%esp)
	movl	%eax, 4(%esp)
	call	___dpmi_set_processor_exception_handler_vector
	movl	24(%esp), %eax
	movl	28(%esp), %edx
	movl	%eax, _except_ori(,%edi,8)
	movl	%edx, _except_ori+4(,%edi,8)
	cmpl	$18, %ebx
	jne	L49
	movl	%esi, 4(%esp)
	movl	$117, (%esp)
	call	___dpmi_get_protected_mode_interrupt_vector
	movl	$_npx_ori, 4(%esp)
	movl	$117, (%esp)
	call	___dpmi_set_protected_mode_interrupt_vector
	movl	28(%esp), %edx
	movl	24(%esp), %eax
	movl	%esi, 4(%esp)
	movl	$9, (%esp)
	movl	%edx, _npx_ori+4
	movl	%eax, _npx_ori
	call	___dpmi_get_protected_mode_interrupt_vector
	movl	$_kbd_ori, 4(%esp)
	movl	$9, (%esp)
	call	___dpmi_set_protected_mode_interrupt_vector
	movl	24(%esp), %eax
	movl	28(%esp), %edx
	movl	%eax, _kbd_ori
	movl	_cbrk_vect, %eax
	movl	%edx, _kbd_ori+4
	cmpb	$0, _cbrk_hooked
	movl	$_cbrk_ori, 4(%esp)
	movl	%eax, (%esp)
	je	L50
	call	___dpmi_set_real_mode_interrupt_vector
	movl	$_cbrk_rmcb, (%esp)
	call	___dpmi_free_real_mode_callback
	movb	$0, _cbrk_hooked
L51:
	movl	___djgpp_old_timer+4, %eax
	testw	%ax, %ax
	je	L45
	movl	___djgpp_old_timer, %edx
	testl	%edx, %edx
	je	L45
	cmpw	_timer_ori+4, %ax
	je	L61
L53:
	movl	$_timer_ori, 4(%esp)
	movl	$8, (%esp)
	call	___dpmi_set_protected_mode_interrupt_vector
	movl	___djgpp_old_timer, %eax
	movl	___djgpp_old_timer+4, %edx
	movl	%eax, _timer_ori
	movl	%edx, _timer_ori+4
L45:
	addl	$32, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 16
	popl	%ebx
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
L50:
	.cfi_restore_state
	call	___dpmi_get_real_mode_interrupt_vector
	movl	$_cbrk_rmcb, 8(%esp)
	movl	$_cbrk_regs, 4(%esp)
	movl	$___djgpp_cbrk_hdlr, (%esp)
	call	___dpmi_allocate_real_mode_callback
	movl	_cbrk_vect, %eax
	movl	$_cbrk_rmcb, 4(%esp)
	movl	%eax, (%esp)
	call	___dpmi_set_real_mode_interrupt_vector
	movb	$1, _cbrk_hooked
	jmp	L51
	.p2align 4,,7
L61:
	cmpl	_timer_ori, %edx
	jne	L53
	movl	$_timer_ori, 4(%esp)
	movl	$8, (%esp)
	call	___dpmi_get_protected_mode_interrupt_vector
	movl	$___djgpp_old_timer, 4(%esp)
	movl	$8, (%esp)
	call	___dpmi_set_protected_mode_interrupt_vector
	jmp	L45
	.cfi_endproc
LFE33:
	.p2align 4,,15
	.globl	___djgpp_set_sigint_key
___djgpp_set_sigint_key:
LFB35:
	.cfi_startproc
	pushl	%ebx
	.cfi_def_cfa_offset 8
	.cfi_offset 3, -8
	movw	___djgpp_sigint_key, %ax
	movl	8(%esp), %ecx
	andl	$65535, %eax
	movw	%cx, ___djgpp_sigint_key
	movl	$15, %ebx
	shrw	$8, %cx
	testb	$1, %cl
	sete	%dl
	andl	$255, %edx
	subl	%edx, %ebx
	andl	$12, %ecx
	movw	%bx, ___djgpp_sigint_mask
	je	L65
	andw	$-3, ___djgpp_sigint_mask
L65:
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 4
	ret
	.cfi_endproc
LFE35:
	.p2align 4,,15
	.globl	___djgpp_set_sigquit_key
___djgpp_set_sigquit_key:
LFB36:
	.cfi_startproc
	pushl	%ebx
	.cfi_def_cfa_offset 8
	.cfi_offset 3, -8
	movw	___djgpp_sigquit_key, %ax
	movl	8(%esp), %ecx
	andl	$65535, %eax
	movw	%cx, ___djgpp_sigquit_key
	movl	$15, %ebx
	shrw	$8, %cx
	testb	$1, %cl
	sete	%dl
	andl	$255, %edx
	subl	%edx, %ebx
	andl	$12, %ecx
	movw	%bx, ___djgpp_sigquit_mask
	je	L73
	andw	$-3, ___djgpp_sigquit_mask
L73:
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 4
	ret
	.cfi_endproc
LFE36:
	.p2align 4,,15
	.globl	___djgpp_exception_setup
___djgpp_exception_setup:
LFB37:
	.cfi_startproc
	pushl	%ebx
	.cfi_def_cfa_offset 8
	.cfi_offset 3, -8
	subl	$56, %esp
	.cfi_def_cfa_offset 64
	movw	___djgpp_ds_alias, %ax
	movw	%ax, ___excep_ds_alias
	cmpl	$655360, __go32_info_block+4
	je	L79
	movl	$1070, (%esp)
	call	___djgpp_set_sigint_key
	movl	$1067, (%esp)
	call	___djgpp_set_sigquit_key
L80:
	xorl	%eax, %eax
	.p2align 4,,7
L81:
	movl	$0, _signal_list(,%eax,4)
	incl	%eax
	cmpl	$320, %eax
	jne	L81
/APP
# 540 "dpmiexcp.c" 1
	mov %ds,___djgpp_app_DS
# 0 "" 2
# 541 "dpmiexcp.c" 1
	mov %ds,___djgpp_our_DS
# 0 "" 2
/NO_APP
	movw	__go32_info_block+26, %ax
	movw	%ax, ___djgpp_dos_sel
	movl	___djgpp_base_address, %eax
	addl	$___djgpp_hw_lock_start, %eax
	movl	%eax, 44(%esp)
	movl	$___djgpp_hw_lock_end, %eax
	subl	$___djgpp_hw_lock_start, %eax
	movl	%eax, 40(%esp)
	leal	36(%esp), %eax
	movl	%eax, (%esp)
	call	___dpmi_lock_linear_region
/APP
# 550 "dpmiexcp.c" 1
	mov %cs,32(%esp)
# 0 "" 2
/NO_APP
	xorl	%ecx, %ecx
	movl	$___djgpp_exception_table, 28(%esp)
	.p2align 4,,7
L82:
	movl	28(%esp), %eax
	movl	32(%esp), %edx
	movl	%eax, _except_ori(,%ecx,8)
	movl	28(%esp), %eax
	addl	$4, %eax
	movl	%edx, _except_ori+4(,%ecx,8)
	incl	%ecx
	movl	%eax, 28(%esp)
	cmpl	$18, %ecx
	jne	L82
	movl	32(%esp), %eax
	movl	$___djgpp_npx_hdlr, _npx_ori
	movw	%ax, _npx_ori+4
	movw	%ax, _kbd_ori+4
	cmpl	$655360, __go32_info_block+4
	je	L83
	movl	$___djgpp_kbd_hdlr, _kbd_ori
	leal	28(%esp), %ebx
L84:
	movl	%ebx, 4(%esp)
	movl	$36, (%esp)
	movl	$___djgpp_i24, 28(%esp)
	call	___dpmi_set_protected_mode_interrupt_vector
	movl	$___djgpp_old_kbd, 4(%esp)
	movl	$9, (%esp)
	call	___dpmi_get_protected_mode_interrupt_vector
	movl	$_timer_ori, 4(%esp)
	movl	$8, (%esp)
	call	___dpmi_get_protected_mode_interrupt_vector
	call	___djgpp_exception_toggle
	movl	$1097, %eax
/APP
# 132 "c:/djgpp/include/libc/farptrgs.h" 1
	movw __go32_info_block+26,%gs 
	.byte 0x65 
	movb (%eax),%al
# 0 "" 2
/NO_APP
	movb	%al, _old_video_mode
	addl	$56, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 8
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 4
	ret
L79:
	.cfi_restore_state
	movl	$1067, (%esp)
	call	___djgpp_set_sigint_key
	movl	$1037, (%esp)
	call	___djgpp_set_sigquit_key
	jmp	L80
L83:
	leal	28(%esp), %ebx
	movl	$35, (%esp)
	movl	%ebx, 4(%esp)
	movl	$___djgpp_iret, 28(%esp)
	movl	$___djgpp_kbd_hdlr_pc98, _kbd_ori
	movl	$6, _cbrk_vect
	call	___dpmi_set_protected_mode_interrupt_vector
	jmp	L84
	.cfi_endproc
LFE37:
	.p2align 4,,15
	.globl	___djgpp_set_ctrl_c
___djgpp_set_ctrl_c:
LFB38:
	.cfi_startproc
	movw	___djgpp_hwint_flags, %dx
	movl	%edx, %eax
	xorl	$-1, %eax
	andl	$1, %eax
	cmpl	$0, 4(%esp)
	jl	L89
	jne	L91
	orl	$1, %edx
	movw	%dx, ___djgpp_hwint_flags
L89:
	ret
	.p2align 4,,7
L91:
	andl	$-2, %edx
	movw	%dx, ___djgpp_hwint_flags
	ret
	.cfi_endproc
LFE38:
	.p2align 4,,15
	.globl	___maybe_fix_w2k_ntvdm_bug
___maybe_fix_w2k_ntvdm_bug:
LFB39:
	.cfi_startproc
	cmpw	$1330, __os_trueversion
	je	L98
	ret
	.p2align 4,,7
L98:
	movl	__stubinfo, %edx
	pushl	%ebx
	.cfi_def_cfa_offset 8
	.cfi_offset 3, -8
	cmpl	$83, 16(%edx)
	jbe	L99
/APP
# 642 "dpmiexcp.c" 1
	movw 38(%edx), %bx                           
                  movb $0x50, %ah                        
                  int  $0x21                              
# 0 "" 2
/NO_APP
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 4
L100:
	ret
	.p2align 4,,7
L99:
	.cfi_def_cfa_offset 8
	.cfi_offset 3, -8
/APP
# 634 "dpmiexcp.c" 1
	movb $0x51, %ah                        
                  int  $0x21                              
                  movb $0x50, %ah                        
                  int  $0x21                              
# 0 "" 2
/NO_APP
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 4
	jmp	L100
	.cfi_endproc
LFE39:
	.p2align 4,,15
	.globl	__exit
__exit:
LFB40:
	.cfi_startproc
	subl	$28, %esp
	.cfi_def_cfa_offset 32
	call	___maybe_fix_w2k_ntvdm_bug
	movl	__8087, %eax
	testl	%eax, %eax
	jne	L105
L102:
	movl	_kbd_ori, %eax
	cmpl	%eax, ___djgpp_old_kbd
	je	L106
L103:
	movl	32(%esp), %eax
	movl	%eax, (%esp)
	call	___exit
L105:
	call	__clear87
	jmp	L102
L106:
	movl	_kbd_ori+4, %eax
	cmpw	%ax, ___djgpp_old_kbd+4
	jne	L103
	call	___djgpp_exception_toggle
	jmp	L103
	.cfi_endproc
LFE40:
LC8:
	.ascii "<**UNKNOWN**>\0"
LC9:
	.ascii "QUIT key Pressed\0"
LC10:
	.ascii "INTR key Pressed\0"
LC11:
	.ascii "Control-Break Pressed\0"
LC12:
	.ascii "Floating Point exception\0"
LC13:
	.ascii "Raised\0"
LC14:
	.ascii " at eip=\0"
LC15:
	.ascii "Exception \0"
LC16:
	.ascii ", error=\0"
LC17:
	.ascii ", x87 status=\0"
LC18:
	.ascii "\15\12eax=\0"
LC19:
	.ascii " ebx=\0"
LC20:
	.ascii " ecx=\0"
LC21:
	.ascii " edx=\0"
LC22:
	.ascii " esi=\0"
LC23:
	.ascii " edi=\0"
LC24:
	.ascii "\15\12ebp=\0"
LC25:
	.ascii " esp=\0"
LC26:
	.ascii " program=\0"
LC27:
	.ascii "cs\0"
LC28:
	.ascii "ds\0"
LC29:
	.ascii "es\0"
LC30:
	.ascii "fs\0"
LC31:
	.ascii "gs\0"
LC32:
	.ascii "ss\0"
LC33:
	.ascii "App stack: [\0"
LC34:
	.ascii "..\0"
LC35:
	.ascii "]  Exceptn stack: [\0"
LC36:
	.ascii "]\15\12\0"
	.p2align 2
LC37:
	.ascii "Call frame traceback EIPs:\15\12  0x\0"
LC38:
	.ascii "\15\12  0x\0"
	.p2align 4,,15
_do_faulting_finish_message:
LFB27:
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
	subl	$28, %esp
	.cfi_def_cfa_offset 48
	movl	%eax, %edi
	movl	___djgpp_exception_state_ptr, %edx
	cmpl	$655360, __go32_info_block+4
	movl	56(%edx), %ebx
	je	L108
	movl	$1097, %eax
/APP
# 132 "c:/djgpp/include/libc/farptrgs.h" 1
	movw __go32_info_block+26,%gs 
	.byte 0x65 
	movb (%eax),%al
# 0 "" 2
/NO_APP
	cmpb	%al, _old_video_mode
	je	L108
/APP
# 200 "dpmiexcp.c" 1
	pusha;movzbl _old_video_mode,%eax; int $0x10;popa;nop
# 0 "" 2
/NO_APP
L108:
	cmpl	$17, %ebx
	ja	L109
	movl	_exception_names(,%ebx,4), %esi
L110:
	cmpl	$121, %ebx
	je	L133
	cmpl	$122, %ebx
	je	L134
	testl	%esi, %esi
	jne	L112
	testl	%edi, %edi
	je	L113
	movl	$6, 8(%esp)
	movl	$LC13, 4(%esp)
	movl	$2, (%esp)
	call	__write
	movl	$8, 8(%esp)
	movl	$LC14, 4(%esp)
	movl	$2, (%esp)
	call	__write
	jmp	L114
L109:
	movl	$LC12, %esi
	cmpl	$117, %ebx
	jne	L146
L112:
	movl	%esi, (%esp)
	call	_strlen
	movl	%esi, 4(%esp)
	movl	%eax, 8(%esp)
	movl	$2, (%esp)
	call	__write
	movl	$8, 8(%esp)
	movl	$LC14, 4(%esp)
	movl	$2, (%esp)
	call	__write
	movl	___djgpp_exception_state_ptr, %eax
	testl	%edi, %edi
	je	L115
L114:
	movl	___djgpp_exception_state_ptr, %eax
/APP
# 28 "c:/djgpp/include/sys/segments.h" 1
	movw %cs,%dx
# 0 "" 2
/NO_APP
	cmpw	%dx, 40(%eax)
	je	L147
L115:
	movl	32(%eax), %eax
	movl	$8, %edx
	call	_itox
L117:
	cmpl	$121, %ebx
	je	L148
	cmpl	$18, %ebx
	jbe	L149
L119:
	movl	%ebx, %eax
	call	_except_to_sig
	cmpl	$289, %eax
	je	L150
L120:
	movl	$6, 8(%esp)
	movl	$LC18, 4(%esp)
	movl	$2, (%esp)
	call	__write
	movl	___djgpp_exception_state_ptr, %eax
	movl	$8, %edx
	movl	(%eax), %eax
	call	_itox
	movl	$5, 8(%esp)
	movl	$LC19, 4(%esp)
	movl	$2, (%esp)
	call	__write
	movl	___djgpp_exception_state_ptr, %eax
	movl	$8, %edx
	movl	4(%eax), %eax
	call	_itox
	movl	$5, 8(%esp)
	movl	$LC20, 4(%esp)
	movl	$2, (%esp)
	call	__write
	movl	___djgpp_exception_state_ptr, %eax
	movl	$8, %edx
	movl	8(%eax), %eax
	call	_itox
	movl	$5, 8(%esp)
	movl	$LC21, 4(%esp)
	movl	$2, (%esp)
	call	__write
	movl	___djgpp_exception_state_ptr, %eax
	movl	$8, %edx
	movl	12(%eax), %eax
	call	_itox
	movl	$5, 8(%esp)
	movl	$LC22, 4(%esp)
	movl	$2, (%esp)
	call	__write
	movl	___djgpp_exception_state_ptr, %eax
	movl	$8, %edx
	movl	16(%eax), %eax
	call	_itox
	movl	$5, 8(%esp)
	movl	$LC23, 4(%esp)
	movl	$2, (%esp)
	call	__write
	movl	___djgpp_exception_state_ptr, %eax
	movl	$8, %edx
	movl	20(%eax), %eax
	call	_itox
	movl	$6, 8(%esp)
	movl	$LC24, 4(%esp)
	movl	$2, (%esp)
	call	__write
	movl	___djgpp_exception_state_ptr, %eax
	movl	$8, %edx
	movl	24(%eax), %eax
	call	_itox
	movl	$5, 8(%esp)
	movl	$LC25, 4(%esp)
	movl	$2, (%esp)
	call	__write
	movl	___djgpp_exception_state_ptr, %eax
	movl	$8, %edx
	movl	28(%eax), %eax
	call	_itox
	movl	$9, 8(%esp)
	movl	$LC26, 4(%esp)
	movl	$2, (%esp)
	call	__write
	movl	___dos_argv0, %edx
	testl	%edx, %edx
	je	L151
L121:
	cmpb	$0, (%edx)
	je	L135
	xorl	%eax, %eax
	.p2align 4,,7
L123:
	incl	%eax
	movl	%eax, %ecx
	cmpb	$0, (%edx,%eax)
	jne	L123
L122:
	movl	%ecx, 8(%esp)
	movl	%edx, 4(%esp)
	movl	$2, (%esp)
	call	__write
	movl	$2, 8(%esp)
	movl	$LC3, 4(%esp)
	movl	$2, (%esp)
	call	__write
	movl	___djgpp_exception_state_ptr, %eax
	movl	40(%eax), %edx
	movl	$LC27, %eax
	andl	$65535, %edx
	call	_dump_selector
	movl	___djgpp_exception_state_ptr, %eax
	movw	42(%eax), %dx
	movl	$LC28, %eax
	andl	$65535, %edx
	call	_dump_selector
	movl	___djgpp_exception_state_ptr, %eax
	movl	44(%eax), %edx
	movl	$LC29, %eax
	andl	$65535, %edx
	call	_dump_selector
	movl	___djgpp_exception_state_ptr, %eax
	movw	46(%eax), %dx
	movl	$LC30, %eax
	andl	$65535, %edx
	call	_dump_selector
	movl	___djgpp_exception_state_ptr, %eax
	movl	48(%eax), %edx
	movl	$LC31, %eax
	andl	$65535, %edx
	call	_dump_selector
	movl	___djgpp_exception_state_ptr, %eax
	movw	50(%eax), %dx
	movl	$LC32, %eax
	andl	$65535, %edx
	call	_dump_selector
	movl	$12, 8(%esp)
	movl	$LC33, 4(%esp)
	movl	$2, (%esp)
	call	__write
	movl	$8, %edx
	movl	___djgpp_stack_top, %eax
	call	_itox
	movl	$2, 8(%esp)
	movl	$LC34, 4(%esp)
	movl	$2, (%esp)
	call	__write
	movl	$8, %edx
	movl	___djgpp_stack_limit, %eax
	call	_itox
	movl	$19, 8(%esp)
	movl	$LC35, 4(%esp)
	movl	$2, (%esp)
	call	__write
	movl	$8, %edx
	movl	$exception_stack+8000, %eax
	call	_itox
	movl	$2, 8(%esp)
	movl	$LC34, 4(%esp)
	movl	$2, (%esp)
	call	__write
	movl	$8, %edx
	movl	$exception_stack, %eax
	call	_itox
	movl	$3, 8(%esp)
	movl	$LC36, 4(%esp)
	movl	$2, (%esp)
	call	__write
	movl	$2, 8(%esp)
	movl	$LC3, 4(%esp)
	movl	$2, (%esp)
	call	__write
	movl	___djgpp_exception_state_ptr, %edx
/APP
# 28 "c:/djgpp/include/sys/segments.h" 1
	movw %cs,%ax
# 0 "" 2
/NO_APP
	cmpw	%ax, 40(%edx)
	je	L152
L124:
	movl	$-1, (%esp)
	call	__exit
L149:
	cmpb	$0, _has_error(%ebx)
	je	L119
	movl	___djgpp_exception_state_ptr, %eax
	movl	52(%eax), %eax
	movl	%eax, %esi
	andl	$65535, %esi
	je	L119
	movl	$8, 8(%esp)
	movl	$LC16, 4(%esp)
	movl	$2, (%esp)
	call	__write
	movl	$4, %edx
	movl	%esi, %eax
	call	_itox
	jmp	L119
L146:
	movl	$LC11, %esi
	cmpl	$27, %ebx
	je	L112
	xorl	%esi, %esi
	jmp	L110
L113:
	movl	$10, 8(%esp)
	movl	$LC15, 4(%esp)
	movl	$2, (%esp)
	call	__write
	movl	$2, %edx
	movl	%ebx, %eax
	call	_itox
	movl	$8, 8(%esp)
	movl	$LC14, 4(%esp)
	movl	$2, (%esp)
	call	__write
	movl	___djgpp_exception_state_ptr, %eax
	jmp	L115
L133:
	movl	$LC10, %esi
	jmp	L112
L147:
	movl	24(%eax), %edx
	cmpl	28(%eax), %edx
	jb	L115
	cmpl	$end, %edx
	jb	L115
	cmpl	___djgpp_selector_limit, %edx
	jae	L115
	movl	4(%edx), %eax
	movl	$8, %edx
	call	_itox
	jmp	L117
L148:
	movl	$2, 8(%esp)
	movl	$LC3, 4(%esp)
	movl	$2, (%esp)
	call	__write
	movl	$-1, (%esp)
	call	_exit
L151:
	movl	$LC8, %edx
	jmp	L121
L150:
	movl	$13, 8(%esp)
	movl	$LC17, 4(%esp)
	movl	$2, (%esp)
	call	__write
	call	__status87
	movl	$4, %edx
	call	_itox
	jmp	L120
L152:
	movl	$2, (%esp)
	call	___isatty
	testl	%eax, %eax
	je	L125
	movl	$1156, %eax
/APP
# 132 "c:/djgpp/include/libc/farptrgs.h" 1
	movw __go32_info_block+26,%gs 
	.byte 0x65 
	movb (%eax),%al
# 0 "" 2
/NO_APP
	andl	$255, %eax
	movl	$10, %esi
	leal	-9(%eax), %edx
	cmpl	$65, %edx
	jbe	L153
L126:
	movl	___djgpp_exception_state_ptr, %eax
	movl	___djgpp_selector_limit, %ebp
	decl	%esi
	movl	24(%eax), %ebx
	movl	$32, 8(%esp)
	movl	$LC37, 4(%esp)
	movl	$2, (%esp)
	call	__write
	movl	___djgpp_exception_state_ptr, %eax
	movl	$8, %edx
	movl	32(%eax), %eax
	call	_itox
L127:
	movl	___djgpp_exception_state_ptr, %eax
	cmpl	28(%eax), %ebx
	jb	L129
	cmpl	$end, %ebx
	jb	L129
	cmpl	%ebx, %ebp
	jbe	L129
	movl	(%ebx), %edi
	testl	%edi, %edi
	je	L129
	movl	4(%ebx), %ebx
	movl	$6, 8(%esp)
	movl	$LC38, 4(%esp)
	movl	$2, (%esp)
	call	__write
	decl	%esi
	movl	$8, %edx
	movl	%ebx, %eax
	call	_itox
	testl	%esi, %esi
	jle	L129
	movl	%edi, %ebx
	jmp	L127
L129:
	movl	$2, 8(%esp)
	movl	$LC3, 4(%esp)
	movl	$2, (%esp)
	call	__write
	jmp	L124
L134:
	movl	$LC9, %esi
	jmp	L112
L135:
	xorl	%ecx, %ecx
	jmp	L122
L125:
	movl	__stklen, %esi
	shrl	$3, %esi
	jmp	L126
L153:
	leal	-14(%eax), %esi
	jmp	L126
	.cfi_endproc
LFE27:
	.p2align 2
LC39:
	.ascii "Bad longjmp to __djgpp_exception_state--aborting\15\12\0"
	.p2align 4,,15
	.globl	___djgpp_traceback_exit
___djgpp_traceback_exit:
LFB30:
	.cfi_startproc
	subl	$204, %esp
	.cfi_def_cfa_offset 208
	movl	208(%esp), %eax
	subl	$288, %eax
	cmpl	$14, %eax
	ja	L155
	movl	___djgpp_exception_state_ptr, %eax
	testl	%eax, %eax
	je	L159
L155:
	movl	208(%esp), %eax
	call	_print_signal_name
	movl	___djgpp_exception_state_ptr, %eax
	testl	%eax, %eax
	je	L157
	leal	20(%esp), %edx
	cmpl	%edx, %eax
	sete	%al
	andl	$255, %eax
	call	_do_faulting_finish_message
L157:
	movl	$-1, (%esp)
	call	__exit
L159:
	leal	20(%esp), %eax
	movl	%eax, (%esp)
	movl	%eax, ___djgpp_exception_state_ptr
	call	_setjmp
	testl	%eax, %eax
	jne	L160
	movl	208(%esp), %edx
	movl	___djgpp_exception_state_ptr, %eax
	subl	$165, %edx
	movl	%edx, 56(%eax)
	jmp	L155
L160:
	movl	$50, 8(%esp)
	movl	$LC39, 4(%esp)
	movl	$2, (%esp)
	call	__write
	xorl	%eax, %eax
	call	_do_faulting_finish_message
	.cfi_endproc
LFE30:
LC40:
	.ascii "Bad signal handler, \0"
	.p2align 4,,15
	.globl	_raise
_raise:
LFB31:
	.cfi_startproc
	pushl	%ebx
	.cfi_def_cfa_offset 8
	.cfi_offset 3, -8
	subl	$24, %esp
	.cfi_def_cfa_offset 32
	movl	32(%esp), %ebx
	testl	%ebx, %ebx
	jle	L167
	cmpl	$320, %ebx
	jg	L167
	movl	_signal_list-4(,%ebx,4), %eax
	cmpl	$-1, %eax
	je	L169
	testl	%eax, %eax
	je	L173
	cmpl	$4095, %eax
	jbe	L174
	movl	%ebx, (%esp)
	call	*%eax
	xorl	%eax, %eax
L162:
	addl	$24, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 8
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L169:
	.cfi_restore_state
	addl	$24, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 8
	xorl	%eax, %eax
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L173:
	.cfi_restore_state
	cmpl	$298, %ebx
	je	L169
L172:
	movl	%ebx, (%esp)
	call	___djgpp_traceback_exit
	.p2align 4,,7
L167:
	orl	$-1, %eax
	jmp	L162
L174:
	movl	$20, 8(%esp)
	movl	$LC40, 4(%esp)
	movl	$2, (%esp)
	call	__write
	jmp	L172
	.cfi_endproc
LFE31:
	.p2align 2
LC41:
	.ascii "Cannot continue from exception, \0"
	.p2align 4,,15
	.globl	___djgpp_exception_processor
___djgpp_exception_processor:
LFB32:
	.cfi_startproc
	pushl	%ebx
	.cfi_def_cfa_offset 8
	.cfi_offset 3, -8
	subl	$24, %esp
	.cfi_def_cfa_offset 32
	movl	___djgpp_exception_state_ptr, %eax
	movl	56(%eax), %eax
	call	_except_to_sig
	movl	%eax, (%esp)
	movl	%eax, %ebx
	call	_raise
	movl	___djgpp_exception_state_ptr, %edx
	cmpl	$17, 56(%edx)
	jbe	L176
	movl	(%edx), %eax
	movl	%edx, (%esp)
	movl	%eax, 4(%esp)
	call	_longjmp
L176:
	movl	$32, 8(%esp)
	movl	$LC41, 4(%esp)
	movl	$2, (%esp)
	call	__write
	movl	%ebx, %eax
	call	_print_signal_name
	xorl	%eax, %eax
	call	_do_faulting_finish_message
	.cfi_endproc
LFE32:
.lcomm _signal_list,1280,16
	.p2align 4
_signames:
	.ascii "ABRTFPE ILL SEGVTERMALRMHUP INT KILLPIPEQUITUSR1USR2NOFPTRAP\0"
.lcomm _buf.3468,9,1
	.section .data
_old_video_mode:
	.byte	3
	.section .text
LC42:
	.ascii "Division by Zero\0"
LC43:
	.ascii "Debug\0"
LC44:
	.ascii "NMI\0"
LC45:
	.ascii "Breakpoint\0"
LC46:
	.ascii "Overflow\0"
LC47:
	.ascii "Bounds Check\0"
LC48:
	.ascii "Invalid Opcode\0"
LC49:
	.ascii "Coprocessor not available\0"
LC50:
	.ascii "Double Fault\0"
LC51:
	.ascii "Coprocessor overrun\0"
LC52:
	.ascii "Invalid TSS\0"
LC53:
	.ascii "Segment Not Present\0"
LC54:
	.ascii "Stack Fault\0"
LC55:
	.ascii "General Protection Fault\0"
LC56:
	.ascii "Page fault\0"
LC57:
	.ascii "Coprocessor Error\0"
LC58:
	.ascii "Alignment Check\0"
	.p2align 4
_exception_names:
	.long	LC42
	.long	LC43
	.long	LC44
	.long	LC45
	.long	LC46
	.long	LC47
	.long	LC48
	.long	LC49
	.long	LC50
	.long	LC51
	.long	LC52
	.long	LC53
	.long	LC54
	.long	LC55
	.long	LC56
	.long	0
	.long	LC57
	.long	LC58
	.p2align 4
_has_error:
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	1
	.byte	0
	.byte	1
	.byte	1
	.byte	1
	.byte	1
	.byte	1
	.byte	0
	.byte	0
	.byte	1
.lcomm _except_ori,144,16
.lcomm _npx_ori,8,4
.lcomm _kbd_ori,8,4
.lcomm _cbrk_hooked,1,1
	.section .data
	.p2align 2
_cbrk_vect:
	.long	27
.lcomm _cbrk_ori,4,2
.lcomm _cbrk_rmcb,4,2
.lcomm _cbrk_regs,52,16
.lcomm _timer_ori,8,4
	.ident	"GCC: (GNU) 4.7.4"
