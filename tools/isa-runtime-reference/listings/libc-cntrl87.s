 .file "cntrl87.S"
 .text
 .globl __control87; __control87:
 pushl %ebp; movl %esp,%ebp;
 pushl %eax
 fstcw (%esp)
 fwait
 popl %eax
 andl $0xffff, %eax
 movl 12(%ebp), %ecx
 notl %ecx
 andl %eax, %ecx
 movl 12(%ebp), %edx
 andl 8(%ebp), %edx
 orl %ecx, %edx
 pushl %edx
 fldcw (%esp)
 popl %edx
 L_leave: movl %ebp,%esp; popl %ebp; ret
