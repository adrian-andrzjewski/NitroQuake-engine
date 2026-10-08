 .file "d0801.S"
 .comm ___dpmi_error,2
 .text
 .text
 .globl ___dpmi_free_physical_address_mapping; ___dpmi_free_physical_address_mapping:
 pushl %ebp; movl %esp,%ebp; pushl %ebx;
 movl 8(%ebp), %eax
 movw 8(%eax), %cx
 movw 10(%eax), %bx
 movw $(0x0801),%ax; int $0x31; jnc L_noerror; movw %ax,___dpmi_error; movl $-1,%eax; jmp L_leave; L_noerror:
 xorl %eax,%eax
 L_leave: popl %ebx; movl %ebp,%esp; popl %ebp; ret
