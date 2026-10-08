 .file "d0000.S"
 .comm ___dpmi_error,2
 .text
 .globl ___dpmi_allocate_ldt_descriptors; ___dpmi_allocate_ldt_descriptors:
 pushl %ebp; movl %esp,%ebp;
 movl 8(%ebp), %ecx
 movw $(0x0000),%ax; int $0x31; jnc L_noerror; movw %ax,___dpmi_error; movl $-1,%eax; jmp L_leave; L_noerror:
 movzwl %ax,%eax
 L_leave: movl %ebp,%esp; popl %ebp; ret
