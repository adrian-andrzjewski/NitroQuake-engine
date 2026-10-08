 .file "stat87.S"
 .text
 .globl __status87; __status87:
 fstsw %ax
 movzwl %ax, %eax
 ret
