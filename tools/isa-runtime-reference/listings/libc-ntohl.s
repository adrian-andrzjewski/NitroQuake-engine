 .file "ntohl.S"
 .globl _ntohl; _ntohl:
 movl 4(%esp), %eax
 xchgb %ah, %al
 rorl $16, %eax
 xchgb %ah, %al
 ret
