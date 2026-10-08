 .file "d0400.S"
 .comm ___dpmi_error,2
 .text
 .text
 .globl ___dpmi_get_version; ___dpmi_get_version:
 pushl %ebp; movl %esp,%ebp; pushl %ebx; pushl %esi;
 movw $(0x0400),%ax; int $0x31; jnc L_noerror; movw %ax,___dpmi_error; movl $-1,%eax; jmp L_leave; L_noerror:
 movl 8(%ebp), %esi
 movb %ah, (%esi)
 movb %al, 1(%esi)
 movw %bx, 2(%esi)
 movb %cl, 4(%esi)
 movb %dh, 5(%esi)
 movb %dl, 6(%esi)
 xorl %eax,%eax
 L_leave: popl %esi; popl %ebx; movl %ebp,%esp; popl %ebp; ret
