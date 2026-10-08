 .file "d0008.S"
 .comm ___dpmi_error,2
 .text
 .globl ___dpmi_set_segment_limit; ___dpmi_set_segment_limit:
 pushl %ebp; movl %esp,%ebp; pushl %ebx;
 movl 8(%ebp), %ebx
 movw 12(%ebp), %dx
 movw 14(%ebp),%cx
 movw $(0x0008),%ax; int $0x31; jnc L_noerror; movw %ax,___dpmi_error; movl $-1,%eax; jmp L_leave; L_noerror:
 xorl %eax,%eax
 L_leave: popl %ebx; movl %ebp,%esp; popl %ebp; ret
