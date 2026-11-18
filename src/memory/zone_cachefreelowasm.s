/* i486 cache reclamation from the low hunk boundary. */
/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
#include "asm_i386.h"
#include "memory/asm_cachefreelow.h"
#undef i386
.arch i486
.code32

#ifdef ASM486_CACHE_FREE_LOW
.text
.p2align 2
.globl C(Cache_FreeLow)
C(Cache_FreeLow):
	pushl	%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	movl	20(%esp),%ebx		/* new low hunk mark */
	leal	C(cache_head),%esi

.Lcache_free_low_scan:
	movl	CFL_CACHE_HEAD_NEXT_OFFSET(%esi),%edi
	cmpl	%esi,%edi
	je	.Lcache_free_low_done
	movl	C(hunk_base),%eax
	addl	%ebx,%eax
	cmpl	%eax,%edi
	jae	.Lcache_free_low_done
	pushl	%edi
	call	C(Cache_Move)
	addl	$4,%esp
	jmp	.Lcache_free_low_scan

.Lcache_free_low_done:
	popl	%edi
	popl	%esi
	popl	%ebx
	popl	%ebp
	ret
#endif /* ASM486_CACHE_FREE_LOW */
