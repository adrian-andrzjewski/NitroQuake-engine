 .file "d0300.S"
 .comm ___dpmi_error,2
 .text
 .text
 .globl ___dpmi_simulate_real_mode_interrupt; ___dpmi_simulate_real_mode_interrupt:
 pushl %ebp; movl %esp,%ebp; pushl %ebx; pushl %edi;
 pushl %es
 movw ___djgpp_ds_alias, %ax
 movw %ax, %es
 movl 8(%ebp), %ebx
 movl $0, %ecx
 movl 12(%ebp), %edi
 movw $(0x0300),%ax; int $0x31; jnc L_noerror; movw %ax,___dpmi_error; movl $-1,%eax; jmp L_leave; L_noerror:
 xorl %eax, %eax
 L_leave: popl %es; popl %edi; popl %ebx; movl %ebp,%esp; popl %ebp; ret
