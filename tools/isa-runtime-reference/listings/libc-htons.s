 .file "htons.S"
 .globl _htons; _htons:
 movl 4(%esp), %eax
 xchgb %ah, %al
 ret
