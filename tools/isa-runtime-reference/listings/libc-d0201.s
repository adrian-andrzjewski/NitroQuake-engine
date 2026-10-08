 .file "d0201.S"
 .comm ___dpmi_error,2
 .text
 .text
 .globl ___dpmi_set_real_mode_interrupt_vector; ___dpmi_set_real_mode_interrupt_vector:
 pushl %ebp; movl %esp,%ebp; pushl %ebx;
 movl 12(%ebp), %ebx
 movw (%ebx), %dx
 movw 2(%ebx), %cx
 movb 8(%ebp), %bl
 movw $(0x201),%ax; int $0x31; jnc L_noerror; movw %ax,___dpmi_error; movl $-1,%eax; jmp L_leave; L_noerror:
 xorl %eax,%eax
 L_leave: popl %ebx; movl %ebp,%esp; popl %ebp; ret
