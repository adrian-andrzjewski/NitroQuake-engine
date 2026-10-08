 .file "clear87.S"
 .text
 .globl __clear87; __clear87:
 fstsw %ax
 movzwl %ax, %eax
 fclex
 ret
