#include "asm_i386.h"

.data
fpenv:	.long	0, 0, 0, 0, 0, 0, 0, 0

.text
#if 0
	.data
Lxxx:	.long	0

	.text

.globl C(setstackcheck)
C(setstackcheck):

	movl	%esp,%eax
	subl	$0x38000,%eax
	movl	$0x5A5A5A5A,(%eax)
	movl	%eax,Lxxx

	ret


.globl C(dostackcheck)
C(dostackcheck):

	movl	Lxxx,%edx
	movl	$0,%eax

	cmpl	$0x5A5A5A5A,(%edx)
	jz		qqq
	incl	%eax
qqq:

	ret
#endif

