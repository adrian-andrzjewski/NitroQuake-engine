 .file "d0500.S"
 .comm ___dpmi_error,2
 .text
 .text
 .globl ___dpmi_get_free_memory_information; ___dpmi_get_free_memory_information:
 pushl %ebp; movl %esp,%ebp; pushl %edi;
 movl 8(%ebp),%edi
 movw $(0x0500),%ax; int $0x31; jnc L_noerror; movw %ax,___dpmi_error; movl $-1,%eax; jmp L_leave; L_noerror:
 xorl %eax,%eax
 L_leave: popl %edi; movl %ebp,%esp; popl %ebp; ret
