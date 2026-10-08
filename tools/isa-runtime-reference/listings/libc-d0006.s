 .file "d0006.S"
 .comm ___dpmi_error,2
 .text
 .globl ___dpmi_get_segment_base_address; ___dpmi_get_segment_base_address:
 pushl %ebp; movl %esp,%ebp; pushl %ebx;
 movl 8(%ebp), %ebx
 movw $(0x0006),%ax; int $0x31; jnc L_noerror; movw %ax,___dpmi_error; movl $-1,%eax; jmp L_leave; L_noerror:
 movl 12(%ebp), %ebx
 movl %edx, (%ebx)
 movw %cx, 2(%ebx)
 xorl %eax,%eax
 L_leave: popl %ebx; movl %ebp,%esp; popl %ebp; ret
