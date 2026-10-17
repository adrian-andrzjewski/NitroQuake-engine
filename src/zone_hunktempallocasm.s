/* i486 temporary high-hunk allocation wrapper. */
#include "asm_i386.h"
#include "asm_hunktempalloc.h"
#undef i386
.arch i486
.code32

#ifdef ASM486_HUNK_TEMP_ALLOC
.text
.p2align 2
.globl C(Hunk_TempAlloc)
C(Hunk_TempAlloc):
	pushl	%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	movl	20(%esp),%ebx		/* requested temporary size */
	addl	$15,%ebx
	andl	$-16,%ebx			/* match (size + 15) & ~15 */

	cmpl	$0,C(hunk_tempactive)
	je	.Lhunk_temp_alloc_mark
	pushl	C(hunk_tempmark)
	call	C(Hunk_FreeToHighMark)
	addl	$4,%esp
	movl	$0,C(hunk_tempactive)

.Lhunk_temp_alloc_mark:
	call	C(Hunk_HighMark)
	movl	%eax,C(hunk_tempmark)

	pushl	$.Lhunk_temp_alloc_name
	pushl	%ebx
	call	C(Hunk_HighAllocName)
	addl	$8,%esp
	movl	$1,C(hunk_tempactive)

	popl	%edi
	popl	%esi
	popl	%ebx
	popl	%ebp
	ret

.section .rodata
.Lhunk_temp_alloc_name:
	.asciz	"temp"
#endif /* ASM486_HUNK_TEMP_ALLOC */
