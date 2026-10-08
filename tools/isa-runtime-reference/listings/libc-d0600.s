 .file "d0600.S"
 .comm ___dpmi_error,2
 .text
 .text
 .globl ___dpmi_lock_linear_region; ___dpmi_lock_linear_region:
 pushl %ebp; movl %esp,%ebp; pushl %ebx; pushl %esi; pushl %edi;
 movl 8(%ebp), %eax
 movw 8(%eax), %cx
 movw 10(%eax), %bx
 movw 4(%eax), %di
 movw 6(%eax), %si
 movw $(0x0600),%ax; int $0x31; jnc L_noerror; movw %ax,___dpmi_error; movl $-1,%eax; jmp L_leave; L_noerror:
 xorl %eax,%eax
 L_leave: popl %edi; popl %esi; popl %ebx; movl %ebp,%esp; popl %ebp; ret
