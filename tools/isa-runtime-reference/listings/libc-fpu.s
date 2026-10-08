 .global __detect_80387
__detect_80387:
 pushl %esi
 pushl %eax
 movl %esp,%esi
 fninit
 movw $0x5a5a,(%esi)
 fnstsw (%esi)
 cmpb $0,(%esi)
 jne Lno_387
 fnstcw (%esi)
 movl (%esi),%eax
 andl $0x103f,%eax
 cmpl $0x3f,%eax
 jne Lno_387
 fld1
 fldz
 .byte 0xde,0xf9
 fld %st
 fchs
 fcompp
 fstsw (%esi)
 movzwl (%esi),%eax
 sahf
 je Lno_387
 fninit
 fnstcw (%esi)
 wait
 andw $0x0fffa,(%esi)
 fldcw (%esi)
 movl $1,%eax
 jmp Lexit
Lno_387:
 xorl %eax,%eax
Lexit:
 popl %esi
 popl %esi
 ret
