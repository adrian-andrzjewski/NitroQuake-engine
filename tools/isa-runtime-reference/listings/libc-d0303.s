 .file "d0303.S"
 .comm ___dpmi_error,2
 .text
 .text
 .globl ___dpmi_allocate_real_mode_callback; ___dpmi_allocate_real_mode_callback:
 pushl %ebp; movl %esp,%ebp; pushl %esi; pushl %edi;
 pushl %es
 movw ___djgpp_ds_alias, %ax
 movw %ax, %es
 pushl %ds
 pushl %cs
 popl %ds
 movl 8(%ebp), %esi
 movl 12(%ebp), %edi
 movw $0x0303,%ax
 int $0x31
 popl %ds
 popl %es
 jnc L_noerror
 movw %ax, ___dpmi_error
 movl $-1,%eax
 jmp L_leave
L_noerror:
 movl 16(%ebp), %eax
 movw %dx, (%eax)
 movw %cx, 2(%eax)
 xorl %eax, %eax
 L_leave: popl %edi; popl %esi; movl %ebp,%esp; popl %ebp; ret
