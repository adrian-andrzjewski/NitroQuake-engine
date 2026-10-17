/* i486 hunk low/high mark reclamation. */
#include "asm_i386.h"
#include "asm_hunkmarkfree.h"
#undef i386
.arch i486
.code32

#ifdef ASM486_HUNK_MARK_RELEASE
.text
.p2align 2
.globl C(Hunk_FreeToLowMark)
C(Hunk_FreeToLowMark):
	pushl	%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	movl	20(%esp),%ebx		/* requested low mark */
	movl	C(hunk_low_used),%eax
	testl	%ebx,%ebx
	js	.Lhunk_free_low_badmark
	cmpl	%eax,%ebx
	jg	.Lhunk_free_low_badmark

.Lhunk_free_low_clear:
	movl	C(hunk_base),%esi
	addl	%ebx,%esi			/* bytes freed start at the new mark */
	subl	%ebx,%eax			/* number of bytes to clear */
	pushl	%eax
	pushl	$0
	pushl	%esi
	call	C(memset)
	addl	$12,%esp
	movl	%ebx,C(hunk_low_used)
	jmp	.Lhunk_free_low_done

.Lhunk_free_low_badmark:
	pushl	%ebx
	pushl	$.Lhunk_free_low_error
	call	C(Sys_Error)
	addl	$8,%esp
	/* Match the C path if Sys_Error unexpectedly returns. */
	movl	C(hunk_low_used),%eax
	jmp	.Lhunk_free_low_clear

.Lhunk_free_low_done:
	popl	%edi
	popl	%esi
	popl	%ebx
	popl	%ebp
	ret

.p2align 2
.globl C(Hunk_FreeToHighMark)
C(Hunk_FreeToHighMark):
	pushl	%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	movl	20(%esp),%ebx		/* requested high mark */
	cmpl	$0,C(hunk_tempactive)
	je	.Lhunk_free_high_validate
	movl	$0,C(hunk_tempactive)
	pushl	C(hunk_tempmark)
	call	C(Hunk_FreeToHighMark)
	addl	$4,%esp

.Lhunk_free_high_validate:
	movl	C(hunk_high_used),%eax
	testl	%ebx,%ebx
	js	.Lhunk_free_high_badmark
	cmpl	%eax,%ebx
	jg	.Lhunk_free_high_badmark

.Lhunk_free_high_clear:
	movl	C(hunk_base),%esi
	addl	C(hunk_size),%esi
	subl	%eax,%esi			/* start of current high allocation */
	subl	%ebx,%eax			/* number of bytes to clear */
	pushl	%eax
	pushl	$0
	pushl	%esi
	call	C(memset)
	addl	$12,%esp
	movl	%ebx,C(hunk_high_used)
	jmp	.Lhunk_free_high_done

.Lhunk_free_high_badmark:
	pushl	%ebx
	pushl	$.Lhunk_free_high_error
	call	C(Sys_Error)
	addl	$8,%esp
	/* Match the C path if Sys_Error unexpectedly returns. */
	movl	C(hunk_high_used),%eax
	jmp	.Lhunk_free_high_clear

.Lhunk_free_high_done:
	popl	%edi
	popl	%esi
	popl	%ebx
	popl	%ebp
	ret

.section .rodata
.Lhunk_free_low_error:
	.asciz "Hunk_FreeToLowMark: bad mark %i"
.Lhunk_free_high_error:
	.asciz "Hunk_FreeToHighMark: bad mark %i"
#endif /* ASM486_HUNK_MARK_RELEASE */
