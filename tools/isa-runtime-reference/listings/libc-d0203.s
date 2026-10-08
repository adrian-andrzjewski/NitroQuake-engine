 .file "d0203.S"
 .comm ___dpmi_error,2
 .text
 .text
 .globl ___dpmi_set_processor_exception_handler_vector; ___dpmi_set_processor_exception_handler_vector:
 pushl %ebp; movl %esp,%ebp; pushl %ebx;
 movb 8(%ebp), %bl
 movl 12(%ebp), %eax
 movl (%eax), %edx
 movw 4(%eax), %cx
 movw $(0x0203),%ax; int $0x31; jnc L_noerror; movw %ax,___dpmi_error; movl $-1,%eax; jmp L_leave; L_noerror:
 xorl %eax,%eax
 L_leave: popl %ebx; movl %ebp,%esp; popl %ebp; ret
