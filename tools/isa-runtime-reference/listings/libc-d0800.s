 .file "d0800.S"
 .comm ___dpmi_error,2
 .text
 .text
 .globl ___dpmi_physical_address_mapping; ___dpmi_physical_address_mapping:
 pushl %ebp; movl %esp,%ebp; pushl %ebx; pushl %esi; pushl %edi;
 movl 8(%ebp), %eax
 movw 8(%eax), %cx
 movw 10(%eax), %bx
 movw 4(%eax), %di
 movw 6(%eax), %si
 movw $(0x0800),%ax; int $0x31; jnc L_noerror; movw %ax,___dpmi_error; movl $-1,%eax; jmp L_leave; L_noerror:
 movl 8(%ebp), %edx
 movw %cx, 8(%edx)
 movw %bx, 10(%edx)
 xorl %eax,%eax
 L_leave: popl %edi; popl %esi; popl %ebx; movl %ebp,%esp; popl %ebp; ret
