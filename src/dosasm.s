#include "asm_i386.h"

.data
fpenv:	.long	0, 0, 0, 0, 0, 0, 0, 0

.text
#ifndef TARGET_I386
// These two routines drive MSR 0x11, the CESR, through RDMSR/WRMSR.  Both are
// Pentium-class instructions, and the CESR is a Pentium Pro / Cyrix-6x86
// register, so this pair is unusable on an i486 as well as on an i386.  They are
// also unreachable: nothing in src references StartMSRInterval or
// EndMSRInterval, so excluding them from the i386 build removes dead code and
// changes no behaviour.  Retained in full for the i486 build.
.globl	C(StartMSRInterval)
C(StartMSRInterval):
	movl	$0x11,%ecx	// read the CESR
	.byte	0x0F
	.byte	0x32		// RDMSR

	andl	$0xFE3FFE3F,%eax	// stop both counters
	.byte	0x0F
	.byte	0x30		// WRMSR

	movl	4(%esp),%eax	// point counter 0 to desired event, with counters
	andl	$0x3F,%eax		//  still stopped
	movl	$0x11,%ecx
	.byte	0x0F
	.byte	0x30		// WRMSR

	movl	$0x12,%ecx	// set counter 0 to the value 0
	subl	%eax,%eax
	subl	%edx,%edx
	.byte	0x0F
	.byte	0x30		// WRMSR
	
	movl	4(%esp),%eax // restart counter 0 with selected event
	andl	$0x3F,%eax
	subl	%edx,%edx
	orl		$0xC0,%eax
	movl	$0x11,%ecx	// control and event select
	.byte	0x0F
	.byte	0x30		// WRMSR

	ret

.globl	C(EndMSRInterval)
C(EndMSRInterval):
	movl	$0x12,%ecx	// counter 0
	.byte	0x0F
	.byte	0x32		// RDMSR

	ret					// lower 32 bits of count in %eax
#endif

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

