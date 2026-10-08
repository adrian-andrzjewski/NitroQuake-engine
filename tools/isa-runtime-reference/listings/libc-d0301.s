 .file "d0301.S"
 .comm ___dpmi_error,2
 .text
 .text
 .globl ___dpmi_simulate_real_mode_procedure_retf; ___dpmi_simulate_real_mode_procedure_retf:
 pushl %ebp; movl %esp,%ebp; pushl %ebx; pushl %edi;
 pushl %es
 movw ___djgpp_ds_alias, %ax
 movw %ax, %es
 movl $0, %ebx
 movl $0, %ecx
 movl 8(%ebp), %edi
 movw $(0x0301),%ax; int $0x31; jnc L_noerror; movw %ax,___dpmi_error; movl $-1,%eax; jmp L_leave; L_noerror:
 xorl %eax, %eax
 L_leave: popl %es; popl %edi; popl %ebx; movl %ebp,%esp; popl %ebp; ret
