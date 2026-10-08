 .file "htonl.S"
 .globl _htonl; _htonl:
 movl 4(%esp), %eax
 xchgb %ah, %al
 rorl $16, %eax
 xchgb %ah, %al
 ret
