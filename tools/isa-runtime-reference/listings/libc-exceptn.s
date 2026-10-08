 .data
 .balign 8
 .comm exception_stack, 8000
 .text
 .balign 16,,7
 .global ___djgpp_exception_table
___djgpp_exception_table:
pushl $0 ; jmp exception_handler
pushl $1 ; jmp exception_handler
pushl $2 ; jmp exception_handler
pushl $3 ; jmp exception_handler
pushl $4 ; jmp exception_handler
pushl $5 ; jmp exception_handler
pushl $6 ; jmp exception_handler
pushl $7 ; jmp exception_handler
pushl $8 ; jmp exception_handler
pushl $9 ; jmp exception_handler
pushl $10 ; jmp exception_handler
pushl $11 ; jmp exception_handler
pushl $12 ; jmp exception_handler
pushl $13 ; jmp exception_handler
pushl $14 ; jmp exception_handler
pushl $15 ; jmp exception_handler
pushl $16 ; jmp exception_handler
pushl $17 ; jmp exception_handler
exception_handler:
 pushl %ebx
 pushl %ds
    .byte 0x2e
 cmpb $0, forced
 je not_forced
 call limitFix
    .byte 0x2e
 movzbl forced,%ebx
 movl %ebx,8(%esp)
not_forced:
 movw %cs:___djgpp_our_DS, %ds
 movl $0x10000, forced
 movl $exception_state, %ebx
 popl 42(%ebx)
 popl 4(%ebx)
 popl 56(%ebx)
 movl %esi, 16(%ebx)
 movl %edi, 20(%ebx)
 movl %ebp, 24(%ebx)
 movl %eax, 0(%ebx)
 movl %ecx, 8(%ebx)
 movl %edx, 12(%ebx)
 movw %es, 44(%ebx)
 movw %fs, 46(%ebx)
 movw %gs, 48(%ebx)
 movl ___djgpp_exception_state_ptr, %eax
 movl %eax, 60(%ebx)
 pushl %ebp
 movl %esp, %ebp
 movl 12(%ebp), %eax
 movl %eax, 52(%ebx)
 movl 16(%ebp), %eax
 movl %eax, 32(%ebx)
 movl 20(%ebp), %eax
 movw %ax, 40(%ebx)
 movl 24(%ebp), %eax
 movl %eax, 36(%ebx)
 andb $0xfe, %ah
 movl %eax, 24(%ebp)
 movl 28(%ebp), %eax
 movl %eax, 28(%ebx)
 movl 32(%ebp), %eax
 movw %ax, 50(%ebx)
 movl $dpmi_exception_proc1, 16(%ebp)
 movw %cs, 20(%ebp)
 movw %ds, %ax
 cmpb $12,56(%ebx)
 je 1f
 cmpw %ax,32(%ebp)
 je stack_ok
 .byte 0x2e
 movw ___excep_ds_alias,%di
 cmpw %di,32(%ebp)
 jne 1f
 movw %ax,32(%ebp)
 jmp stack_ok
1: movl $exception_stack+8000, 28(%ebp)
 movw %ax, 32(%ebp)
stack_ok:
 movw %ax, %es
 movl %ebx,%esi
 movl 28(%ebp), %edi
 subl $92, %edi
 movl %edi, 28(%ebp)
 movl %edi, ___djgpp_exception_state_ptr
 movl $16, %ecx
 cld
 rep
 movsl
 movl 0(%ebx), %eax
 movl 16(%ebx), %esi
 movl 20(%ebx), %edi
 movl 8(%ebx), %ecx
 movw 44(%ebx), %es
 popl %ebp
 pushl 4(%ebx)
 pushl 42(%ebx)
 movb $0, forced+2
 popl %ds
 popl %ebx
 lret
 .balign 16,,7
limitFix:
 pushl %eax
 pushl %ecx
 pushl %edx
    .byte 0x2e
 movl ___djgpp_app_DS, %ebx
    .byte 0x2e
 movl ds_limit, %edx
 movl %edx, %ecx
 shrl $16, %ecx
 movw $0x0008, %ax
 int $0x31
 popl %edx
 popl %ecx
 popl %eax
 ret
 .balign 16,,7
dpmi_exception_proc1:
 cld
    .byte 0x2e
 movw ___djgpp_our_DS, %bx
 movw %bx, %ds
 movw %bx, %es
 jmp ___djgpp_exception_processor
 .balign 16,,7
 .globl ___djgpp_save_interrupt_regs
___djgpp_save_interrupt_regs:
 pushl %esi
 pushl %ds
 movw %cs:___djgpp_our_DS, %ds
 movl $exception_state, %esi
 popl 42(%esi)
 popl 16(%esi)
 movl %edi, 20(%esi)
 movl %ebp, 24(%esi)
 movl %eax, 0(%esi)
 movl %ebx, 4(%esi)
 movl %ecx, 8(%esi)
 movl %edx, 12(%esi)
 popl %edx
 popl 32(%esi)
 popl %eax
 movw %ax,40(%esi)
 popl 36(%esi)
 movl %esp, 28(%esi)
 movw %es, 44(%esi)
 movw %fs, 46(%esi)
 movw %gs, 48(%esi)
 movw %ss, 50(%esi)
 movl ___djgpp_exception_state_ptr, %eax
 movl %eax, 60(%esi)
 cld
 movw %ds, %ax
 movw %ax, %es
 movw %ss, %bx
 cmpw %ax, %bx
 je Lss_ok
 movw %ax, %ss
 movl $exception_stack+8000, %esp
Lss_ok: subl $92, %esp
 movl %esp, %edi
 movl $16, %ecx
 movl %edi, ___djgpp_exception_state_ptr
 rep
 movsl
 jmp *%edx
 .balign 8
 .global ___djgpp_hw_lock_start
___djgpp_hw_lock_start:
ds_limit: .long 0
forced: .long 0
 .global ___djgpp_cbrk_count
___djgpp_cbrk_count: .long 0
 .global ___djgpp_timer_countdown
___djgpp_timer_countdown: .long 0
 .global ___djgpp_our_DS
___djgpp_our_DS: .word 0
 .global ___djgpp_app_DS
___djgpp_app_DS: .word 0
 .global ___djgpp_dos_sel
___djgpp_dos_sel: .word 0
 .global ___djgpp_hwint_flags
___djgpp_hwint_flags: .word 0
 .global ___djgpp_sigint_key
___djgpp_sigint_key: .word 0
 .global ___djgpp_sigint_mask
___djgpp_sigint_mask: .word 0
 .global ___djgpp_sigquit_key
___djgpp_sigquit_key: .word 0
 .global ___djgpp_sigquit_mask
___djgpp_sigquit_mask: .word 0
 .global ___djgpp_old_kbd
___djgpp_old_kbd: .long 0,0
 .global ___djgpp_old_timer
___djgpp_old_timer: .long 0,0
 .global ___djgpp_exception_state_ptr
___djgpp_exception_state_ptr: .long 0
exception_state: .space 64
 .global ___excep_ds_alias
___excep_ds_alias: .word 0
 .balign 16,,7
 .global ___djgpp_npx_hdlr
___djgpp_npx_hdlr:
 pushl %eax
 xorl %eax,%eax
 outb %al,$0x0f0
 movb $0x20,%al
 outb %al,$0x0a0
 outb %al,$0x020
 movb $0x75,%al
hw_to_excp:
 call ___djgpp_hw_exception
 popl %eax
 sti
 iret
 .balign 16,,7
 .global ___djgpp_kbd_hdlr
___djgpp_kbd_hdlr:
 pushl %eax
 pushl %ebx
 pushl %ds
    .byte 0x2e
 testb $1, ___djgpp_hwint_flags
 jne Lkbd_chain
 movw %cs:___djgpp_dos_sel, %ds
 movb 0x417,%ah
 testb $1,%ah
 je 6f
 orb $2,%ah
6:
 inb $0x60,%al
99:
 movb %ah,%bh
 andb %cs:___djgpp_sigint_mask, %ah
 cmpw %cs:___djgpp_sigint_key, %ax
 jne 7f
 movb $0x79,%bh
 jmp 98f
7:
 movb %bh,%ah
 andb %cs:___djgpp_sigquit_mask, %ah
 cmpw %cs:___djgpp_sigquit_key, %ax
 jne Lkbd_chain
 movb $0x7a,%bh
98:
 movb %bh,%al
 call ___djgpp_hw_exception
Lkbd_chain:
 popl %ds
 popl %ebx
 popl %eax
 ljmp *%cs:___djgpp_old_kbd
 .balign 16,,7
 .global ___djgpp_kbd_hdlr_pc98
___djgpp_kbd_hdlr_pc98:
 pushl %eax
 pushl %ebx
 pushl %ds
    .byte 0x2e
 testb $1, ___djgpp_hwint_flags
 jne Lkbd_chain
 movw %cs:___djgpp_dos_sel, %ds
 movb 0x053a,%al
 movb %al,%ah
 andb $0x09,%ah
 testb $0x02,%al
 je 981f
 orb $0x40,%ah
981: testb $0x10,%al
 je 982f
 orb $0x04,%ah
982: testb $0x01,%al
 je 983f
 orb $0x02,%ah
983: testb $0x04,%al
 je 984f
 orb $0x20,%ah
984: inb $0x41,%al
 jmp 99b
 .balign 16,,7
 .global ___djgpp_timer_hdlr
___djgpp_timer_hdlr:
    .byte 0x2e
 cmpl $0,___djgpp_timer_countdown
 je 4f
 pushl %ds
 movw %cs:___excep_ds_alias, %ds
 decl ___djgpp_timer_countdown
 popl %ds
 jmp 3f
4:
 pushl %eax
 movb $0x78,%al
 call ___djgpp_hw_exception
 popl %eax
3:
    .byte 0x2e
 testb $4, ___djgpp_hwint_flags
 jne 2f
 ljmp *%cs:___djgpp_old_timer
2:
 pushl %eax
 movb $0x20,%al
 outb %al,$0x020
 popl %eax
 iret
 .balign 16,,7
 .global ___djgpp_cbrk_hdlr
___djgpp_cbrk_hdlr:
 cld
 lodsl
 movl %eax, %es:0x2a(%edi)
 lodsl
 movw %ax, %es:0x20(%edi)
 addw $6, %es:0x2e(%edi)
 movb $0x1b,%al
    .byte 0x2e
 testb $2, ___djgpp_hwint_flags
 jne 1f
 call ___djgpp_hw_exception
 iret
1:
 incl %es:___djgpp_cbrk_count
 iret
 .global ___djgpp_i24
 .global ___djgpp_iret
___djgpp_i24:
 movb $3,%al
___djgpp_iret:
 iret
 .balign 16,,7
 .global ___djgpp_hw_exception
___djgpp_hw_exception:
    .byte 0x2e
 cmpl $0, forced
 jne already_forced
 pushl %ebx
 pushl %ecx
 pushl %edx
 pushl %ds
 movw %cs:___djgpp_our_DS, %ds
 movl ___djgpp_app_DS, %ebx
 lsl %ebx, %ecx
 movl %ecx, ds_limit
 movb %al, forced
 xorl %ecx, %ecx
 movw $0xfff, %dx
 movw $0x0008, %ax
 int $0x31
5: popl %ds
 popl %edx
 popl %ecx
 popl %ebx
already_forced:
 ret
 .global ___djgpp_hw_lock_end
___djgpp_hw_lock_end:
 ret
