 .file "d0304.S"
 .comm ___dpmi_error,2
 .text
 .text
 .globl ___dpmi_free_real_mode_callback; ___dpmi_free_real_mode_callback:
 pushl %ebp; movl %esp,%ebp;
 movl 8(%ebp), %eax
 movw (%eax), %dx
 movw 2(%eax), %cx
 movw $(0x0304),%ax; int $0x31; jnc L_noerror; movw %ax,___dpmi_error; movl $-1,%eax; jmp L_leave; L_noerror:
 xorl %eax, %eax
 L_leave: movl %ebp,%esp; popl %ebp; ret
