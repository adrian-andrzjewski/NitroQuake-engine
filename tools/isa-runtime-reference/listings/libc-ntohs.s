 .file "ntohs.S"
 .globl _ntohs; _ntohs:
 movl 4(%esp), %eax
 xchgb %ah, %al
 ret
