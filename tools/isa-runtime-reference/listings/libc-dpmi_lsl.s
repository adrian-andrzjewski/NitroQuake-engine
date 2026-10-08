 .file "dpmi_lsl.s"
 .file "dpmi_lsl.S"
 .comm ___dpmi_error,2
 .text
 .globl ___dpmi_get_segment_limit; ___dpmi_get_segment_limit:
 pushl %ebp; movl %esp,%ebp;
 movw 8(%ebp), %ax
 lsl %eax, %eax
 jz 1f
 xorl %eax, %eax
1:
 L_leave: movl %ebp,%esp; popl %ebp; ret
