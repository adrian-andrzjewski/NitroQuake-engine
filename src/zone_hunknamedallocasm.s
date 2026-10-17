/* i486 low/high named hunk allocation. */
#include "asm_i386.h"
#include "asm_hunknamedalloc.h"
#undef i386
.arch i486
.code32

#if defined(BENCH486) && defined(ASM486_SCREEN_CENTER_STRING)
.macro HNA_TRACE phase, x, y, character
    pushl \character
    pushl \y
    pushl \x
    pushl $\phase
    call C(Bench486HunkNamedAllocTrace)
    addl $16,%esp
.endm
#else
.macro HNA_TRACE phase, x, y, character
.endm
#endif

#ifdef ASM486_HUNK_NAMED_ALLOC
.text
.p2align 2
.globl C(Hunk_AllocName)
C(Hunk_AllocName):
	pushl	%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	movl	20(%esp),%ebx		/* requested payload size */
	movl	24(%esp),%ebp		/* allocation name */
	HNA_TRACE 72,%ebx,C(hunk_low_used),C(hunk_high_used)

#ifdef PARANOID
	call	C(Hunk_Check)
#endif
	testl	%ebx,%ebx
	js	.Lhunk_alloc_name_bad_size
	jmp	.Lhunk_alloc_name_align

.Lhunk_alloc_name_bad_size:
	pushl	%ebx
	pushl	$.Lhunk_alloc_name_bad_size_text
	call	C(Sys_Error)
	addl	$8,%esp
	/* Match the C path if Sys_Error unexpectedly returns. */

.Lhunk_alloc_name_align:
	leal	15(%ebx),%edi
	andl	$-16,%edi
	addl	$HNA_HUNK_SIZE,%edi	/* header plus aligned payload */

	movl	C(hunk_size),%eax
	subl	C(hunk_low_used),%eax
	subl	C(hunk_high_used),%eax
	HNA_TRACE 73,%edi,%eax,C(hunk_size)
	movl	C(hunk_size),%eax
	subl	C(hunk_low_used),%eax
	subl	C(hunk_high_used),%eax
	cmpl	%edi,%eax
	jge	.Lhunk_alloc_name_space
	pushl	%edi
	pushl	$.Lhunk_alloc_name_failed_text
	call	C(Sys_Error)
	addl	$8,%esp
	/* Match the C path if Sys_Error unexpectedly returns. */

.Lhunk_alloc_name_space:
	movl	C(hunk_base),%esi
	addl	C(hunk_low_used),%esi
#ifdef PROFILE486
	incl	C(bench486_hunk_low_calls)
	addl	%edi,C(bench486_hunk_low_bytes)
#endif
	movl	C(hunk_low_used),%eax
	addl	%edi,%eax
	movl	%eax,C(hunk_low_used)
	pushl	%eax
	call	C(Cache_FreeLow)
	addl	$4,%esp
	HNA_TRACE 74,%edi,C(hunk_low_used),C(hunk_high_used)

	pushl	%edi
	pushl	$0
	pushl	%esi
	call	C(memset)
	addl	$12,%esp
	HNA_TRACE 75,%edi,C(hunk_low_used),$0
	movl	%edi,HNA_HUNK_SIZE_OFFSET(%esi)
	movl	$HNA_HUNK_SENTINAL_VALUE,HNA_HUNK_SENTINAL_OFFSET(%esi)
	pushl	$HNA_HUNK_NAME_SIZE
	pushl	%ebp
	leal	HNA_HUNK_NAME_OFFSET(%esi),%eax
	pushl	%eax
	call	C(Q_strncpy)
	addl	$12,%esp
	HNA_TRACE 76,%edi,C(hunk_low_used),$0
	leal	HNA_HUNK_SIZE(%esi),%eax

	popl	%edi
	popl	%esi
	popl	%ebx
	popl	%ebp
	ret

.p2align 2
.globl C(Hunk_Alloc)
C(Hunk_Alloc):
	movl	4(%esp),%eax
	pushl	$.Lhunk_alloc_unknown_name
	pushl	%eax
	call	C(Hunk_AllocName)
	addl	$8,%esp
	ret

.p2align 2
.globl C(Hunk_HighAllocName)
C(Hunk_HighAllocName):
	pushl	%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	movl	20(%esp),%ebx		/* requested payload size */
	movl	24(%esp),%ebp		/* allocation name */
	HNA_TRACE 77,%ebx,C(hunk_low_used),C(hunk_high_used)
	testl	%ebx,%ebx
	js	.Lhunk_high_alloc_bad_size
	jmp	.Lhunk_high_alloc_temp

.Lhunk_high_alloc_bad_size:
	pushl	%ebx
	pushl	$.Lhunk_high_alloc_bad_size_text
	call	C(Sys_Error)
	addl	$8,%esp
	/* Match the C path if Sys_Error unexpectedly returns. */

.Lhunk_high_alloc_temp:
	cmpl	$0,C(hunk_tempactive)
	je	.Lhunk_high_alloc_check
	pushl	C(hunk_tempmark)
	call	C(Hunk_FreeToHighMark)
	addl	$4,%esp
	movl	$0,C(hunk_tempactive)

.Lhunk_high_alloc_check:
#ifdef PARANOID
	call	C(Hunk_Check)
#endif
	leal	15(%ebx),%edi
	andl	$-16,%edi
	addl	$HNA_HUNK_SIZE,%edi	/* header plus aligned payload */

	movl	C(hunk_size),%eax
	subl	C(hunk_low_used),%eax
	subl	C(hunk_high_used),%eax
	HNA_TRACE 78,%edi,%eax,C(hunk_size)
	movl	C(hunk_size),%eax
	subl	C(hunk_low_used),%eax
	subl	C(hunk_high_used),%eax
	cmpl	%edi,%eax
	jge	.Lhunk_high_alloc_space
	pushl	%edi
	pushl	$.Lhunk_high_alloc_failed_text
	call	C(Con_Printf)
	addl	$8,%esp
	xorl	%eax,%eax
	jmp	.Lhunk_high_alloc_done

.Lhunk_high_alloc_space:
	movl	C(hunk_high_used),%eax
	addl	%edi,%eax
	movl	%eax,C(hunk_high_used)
	HNA_TRACE 79,%edi,C(hunk_low_used),C(hunk_high_used)
#ifdef PROFILE486
	incl	C(bench486_hunk_high_calls)
	addl	%edi,C(bench486_hunk_high_bytes)
#endif
	pushl	%eax
	call	C(Cache_FreeHigh)
	addl	$4,%esp
	HNA_TRACE 80,%edi,C(hunk_low_used),C(hunk_high_used)

	movl	C(hunk_base),%esi
	addl	C(hunk_size),%esi
	subl	C(hunk_high_used),%esi
	pushl	%edi
	pushl	$0
	pushl	%esi
	call	C(memset)
	addl	$12,%esp
	movl	%edi,HNA_HUNK_SIZE_OFFSET(%esi)
	movl	$HNA_HUNK_SENTINAL_VALUE,HNA_HUNK_SENTINAL_OFFSET(%esi)
	pushl	$HNA_HUNK_NAME_SIZE
	pushl	%ebp
	leal	HNA_HUNK_NAME_OFFSET(%esi),%eax
	pushl	%eax
	call	C(Q_strncpy)
	addl	$12,%esp
	HNA_TRACE 81,%edi,C(hunk_low_used),C(hunk_high_used)
	leal	HNA_HUNK_SIZE(%esi),%eax

.Lhunk_high_alloc_done:
	popl	%edi
	popl	%esi
	popl	%ebx
	popl	%ebp
	ret

.section .rodata
.Lhunk_alloc_unknown_name:
	.asciz	"unknown"
.Lhunk_alloc_name_bad_size_text:
	.asciz	"Hunk_Alloc: bad size: %i"
.Lhunk_alloc_name_failed_text:
	.asciz	"Hunk_Alloc: failed on %i bytes"
.Lhunk_high_alloc_bad_size_text:
	.asciz	"Hunk_HighAllocName: bad size: %i"
.Lhunk_high_alloc_failed_text:
	.asciz	"Hunk_HighAlloc: failed on %i bytes\n"
#endif /* ASM486_HUNK_NAMED_ALLOC */
