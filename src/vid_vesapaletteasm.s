#include "asm_i386.h"
#include "asm_vesapalette.h"

#if defined(ASM486_VESA_PALETTE) || defined(BENCH486)
	.text
	.p2align 4,,15
	.globl C(VID_BuildVESAPalette_asm486)
C(VID_BuildVESAPalette_asm486):
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%esi
	pushl	%edi

	movl	8(%ebp),%edi
	movl	12(%ebp),%esi
	movl	$VP_PALETTE_ENTRIES,%ecx
.Lvp_palette_loop:
	movzbl	2(%esi),%eax
	shrl	$2,%eax
	movb	%al,(%edi)
	movzbl	1(%esi),%eax
	shrl	$2,%eax
	movb	%al,1(%edi)
	movzbl	(%esi),%eax
	shrl	$2,%eax
	movb	%al,2(%edi)
	movb	$0,3(%edi)
	addl	$3,%esi
	addl	$4,%edi
	loop	.Lvp_palette_loop

	popl	%edi
	popl	%esi
	popl	%ebp
	ret
#endif
