 .file "d0300_z.S"
 .comm ___dpmi_error,2
 .text
 .comm ___dpmi_int_ss, 2
 .comm ___dpmi_int_sp, 2
 .comm ___dpmi_int_flags, 2
 .lcomm dpmi_busy, 1
 .text
 .globl ___dpmi_int; ___dpmi_int:
 pushl %ebp; movl %esp,%ebp; pushl %ebx; pushl %edi;
 pushl %es
 pushl %ss
 movw ___djgpp_ds_alias, %ax
 movw %ax, %es
 movw %ax, %ss
 movl 8(%ebp), %ebx
 movl $0, %ecx
 movl 12(%ebp), %edi
 incb dpmi_busy
 cmpb $1, dpmi_busy
 jne L_is_busy
 movw ___dpmi_int_flags, %ax
 movw %ax, 0x20(%edi)
 movw ___dpmi_int_sp, %ax
 movw %ax, 0x2e(%edi)
 movw ___dpmi_int_ss, %ax
 movw %ax, 0x30(%edi)
 jmp L_not_busy
L_is_busy:
 movw $0, 0x20(%edi)
 movw $0, 0x2e(%edi)
 movw $0, 0x30(%edi)
L_not_busy:
 movw $(0x0300),%ax; int $0x31; jnc L_noerror; movw %ax,___dpmi_error; movl $-1,%eax; jmp L_leave; L_noerror:
 xorl %eax,%eax
 L_leave: decb dpmi_busy; popl %ss; popl %es; popl %edi; popl %ebx; movl %ebp,%esp; popl %ebp; ret
