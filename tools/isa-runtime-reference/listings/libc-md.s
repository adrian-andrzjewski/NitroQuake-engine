 .file "md.S"
 .globl ___movedata; ___movedata:
 pushl %ebp; movl %esp,%ebp; pushl %esi; pushl %edi;
 pushw %ds
 pushw %es
 movw 8(%ebp),%ds
 movw 16(%ebp),%es
 movl 12(%ebp),%esi
 movl 20(%ebp),%edi
 movl 24(%ebp),%ecx
 call ___dj_movedata
 popw %es
 popw %ds
 L_leave: popl %edi; popl %esi; movl %ebp,%esp; popl %ebp; ret
