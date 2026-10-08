 .file "d0102.S"
 .comm ___dpmi_error,2
 .text
 .globl ___dpmi_resize_dos_memory; ___dpmi_resize_dos_memory:
 pushl %ebp; movl %esp,%ebp; pushl %ebx;
 movl 8(%ebp), %edx
 movl 12(%ebp), %ebx
 movw $(0x0102),%ax; int $0x31; movw %ax,___dpmi_error; jc L_error
 xorl %eax,%eax
 jmp L_leave
L_error:
 movl 16(%ebp), %ecx
 movzwl %bx, %ebx
 movl %ebx, (%ecx)
 movl $-1, %eax
 L_leave: popl %ebx; movl %ebp,%esp; popl %ebp; ret
