 .file "d0e01.S"
 .comm ___dpmi_error,2
 .text
 .text
 .globl ___dpmi_set_coprocessor_emulation; ___dpmi_set_coprocessor_emulation:
 pushl %ebp; movl %esp,%ebp; pushl %ebx; pushl %esi; pushl %edi;
 movl 8(%ebp), %ebx
 movw $(0x0e01),%ax; int $0x31; jnc L_noerror; movw %ax,___dpmi_error; movl $-1,%eax; jmp L_leave; L_noerror:
 xorl %eax,%eax
 L_leave: popl %edi; popl %esi; popl %ebx; movl %ebp,%esp; popl %ebp; ret
