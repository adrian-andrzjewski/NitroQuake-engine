 .file "d0604.S"
 .comm ___dpmi_error,2
 .text
 .text
 .globl ___dpmi_get_page_size; ___dpmi_get_page_size:
 pushl %ebp; movl %esp,%ebp; pushl %ebx;
 movw $(0x0604),%ax; int $0x31; jnc L_noerror; movw %ax,___dpmi_error; movl $-1,%eax; jmp L_leave; L_noerror:
 movl 8(%ebp), %edx
 movw %cx, (%edx)
 movw %bx, 2(%edx)
 xorl %eax,%eax
 L_leave: popl %ebx; movl %ebp,%esp; popl %ebp; ret
