 .file "d0101.S"
 .comm ___dpmi_error,2
 .text
 .globl ___dpmi_free_dos_memory; ___dpmi_free_dos_memory:
 pushl %ebp; movl %esp,%ebp;
 movl 8(%ebp), %edx
 movw $(0x0101),%ax; int $0x31; jnc L_noerror; movw %ax,___dpmi_error; movl $-1,%eax; jmp L_leave; L_noerror:
 xorl %eax,%eax
 L_leave: movl %ebp,%esp; popl %ebp; ret
