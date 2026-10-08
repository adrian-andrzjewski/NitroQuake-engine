 .file "d0202.S"
 .comm ___dpmi_error,2
 .text
 .text
 .globl ___dpmi_get_processor_exception_handler_vector; ___dpmi_get_processor_exception_handler_vector:
 pushl %ebp; movl %esp,%ebp; pushl %ebx;
 movb 8(%ebp), %bl
 movw $(0x0202),%ax; int $0x31; jnc L_noerror; movw %ax,___dpmi_error; movl $-1,%eax; jmp L_leave; L_noerror:
 movl 12(%ebp), %ebx
 movl %edx, (%ebx)
 movw %cx, 4(%ebx)
 xorl %eax,%eax
 L_leave: popl %ebx; movl %ebp,%esp; popl %ebp; ret
