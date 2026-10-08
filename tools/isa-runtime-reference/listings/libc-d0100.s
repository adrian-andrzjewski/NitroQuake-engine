 .file "d0100.S"
 .comm ___dpmi_error,2
 .text
 .globl ___dpmi_allocate_dos_memory; ___dpmi_allocate_dos_memory:
 pushl %ebp; movl %esp,%ebp; pushl %ebx;
 movl 8(%ebp), %ebx
 movw $(0x0100),%ax; int $0x31; movw %ax,___dpmi_error; jc L_error
 movl 12(%ebp), %ecx
 movzwl %dx, %edx
 movl %edx, (%ecx)
 movzwl %ax,%eax
 jmp L_leave
L_error:
 movl 12(%ebp), %ecx
 cmpl $0, %ecx
 je L_no_ptr
 movzwl %bx, %ebx
 movl %ebx, (%ecx)
L_no_ptr:
 movl $-1, %eax
 L_leave: popl %ebx; movl %ebp,%esp; popl %ebp; ret
