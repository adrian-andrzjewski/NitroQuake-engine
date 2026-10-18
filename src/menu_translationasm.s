#include "asm_i386.h"
#include "asm_playertranslation.h"

#if defined(ASM486_PLAYER_TRANSLATION) || defined(BENCH486)
	.text
	.p2align 4,,15
	.globl C(M_TranslatePlayerColors_asm486)
C(M_TranslatePlayerColors_asm486):
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	subl	$20,%esp

	movl	8(%ebp),%eax
	movl	%eax,-16(%ebp)		// current destination row
	movl	12(%ebp),%eax
	movl	%eax,-20(%ebp)		// current source row
	movl	16(%ebp),%eax
	movl	%eax,-24(%ebp)		// top palette index
	movl	20(%ebp),%eax
	movl	%eax,-28(%ebp)		// bottom palette index
	movl	24(%ebp),%eax
	movl	%eax,-32(%ebp)		// remaining rows
	testl	%eax,%eax
	jle	.Lpt_done

	cld
	movl	-20(%ebp),%esi
	movl	-16(%ebp),%edi
	movl	-32(%ebp),%ecx
	shll	$6,%ecx			// 64 dwords per 256-byte color row
	rep movsl

.Lpt_row:
	movl	-16(%ebp),%edi
	addl	$PT_TOP_RANGE,%edi
	movl	-20(%ebp),%esi
	movl	-24(%ebp),%eax
	cmpl	$128,%eax
	jge	.Lpt_top_reverse
	addl	%eax,%esi
	movl	$PT_RANGE_BYTES,%ecx
	rep movsb
	jmp	.Lpt_bottom

.Lpt_top_reverse:
	addl	%eax,%esi
	addl	$(PT_RANGE_BYTES-1),%esi
	movl	$PT_RANGE_BYTES,%ecx
.Lpt_top_reverse_loop:
	movb	(%esi),%al
	movb	%al,(%edi)
	decl	%esi
	incl	%edi
	loop	.Lpt_top_reverse_loop

.Lpt_bottom:
	movl	-16(%ebp),%edi
	addl	$PT_BOTTOM_RANGE,%edi
	movl	-20(%ebp),%esi
	movl	-28(%ebp),%eax
	cmpl	$128,%eax
	jge	.Lpt_bottom_reverse
	addl	%eax,%esi
	movl	$PT_RANGE_BYTES,%ecx
	rep movsb
	jmp	.Lpt_next_row

.Lpt_bottom_reverse:
	addl	%eax,%esi
	addl	$(PT_RANGE_BYTES-1),%esi
	movl	$PT_RANGE_BYTES,%ecx
.Lpt_bottom_reverse_loop:
	movb	(%esi),%al
	movb	%al,(%edi)
	decl	%esi
	incl	%edi
	loop	.Lpt_bottom_reverse_loop

.Lpt_next_row:
	addl	$PT_ROW_BYTES,-16(%ebp)
	addl	$PT_ROW_BYTES,-20(%ebp)
	decl	-32(%ebp)
	jnz	.Lpt_row

.Lpt_done:
	addl	$20,%esp
	popl	%edi
	popl	%esi
	popl	%ebx
	popl	%ebp
	ret

	.p2align 4,,15
	.globl C(M_BuildTranslationTable_asm486)
#ifdef ASM486_PLAYER_TRANSLATION
	.globl C(M_BuildTranslationTable)
C(M_BuildTranslationTable):
#endif
C(M_BuildTranslationTable_asm486):
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi

	cld
	leal	C(identityTable),%edi
	movl	$0x03020100,%eax
	movl	$64,%ecx
.Lpt_identity_loop:
	movl	%eax,(%edi)
	addl	$0x04040404,%eax
	addl	$4,%edi
	loop	.Lpt_identity_loop

	pushl	$1
	pushl	12(%ebp)
	pushl	8(%ebp)
	pushl	$C(identityTable)
	pushl	$C(translationTable)
	call	C(M_TranslatePlayerColors_asm486)
	addl	$20,%esp

	popl	%edi
	popl	%esi
	popl	%ebx
	popl	%ebp
	ret
#endif
