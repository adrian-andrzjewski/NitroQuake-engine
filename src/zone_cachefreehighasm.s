/* i486 cache reclamation from the high hunk boundary. */
#include "asm_i386.h"
#include "asm_cachefreehigh.h"
#undef i386
.arch i486
.code32

#ifdef ASM486_CACHE_FREE_HIGH
.text
.p2align 2
.globl C(Cache_FreeHigh)
C(Cache_FreeHigh):
	pushl	%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	movl	20(%esp),%ebx		/* new high hunk mark */
	leal	C(cache_head),%ebp
	xorl	%esi,%esi			/* previous cache block */

.Lcache_free_high_scan:
	movl	CFH_CACHE_HEAD_PREV_OFFSET(%ebp),%edi
	cmpl	%ebp,%edi
	je	.Lcache_free_high_done
	movl	0(%edi),%eax
	addl	%edi,%eax			/* end of the highest block */
	movl	C(hunk_base),%edx
	addl	C(hunk_size),%edx
	subl	%ebx,%edx			/* high hunk boundary */
	cmpl	%edx,%eax
	jbe	.Lcache_free_high_done
	cmpl	%esi,%edi
	jne	.Lcache_free_high_move
	pushl	CFH_CACHE_USER_OFFSET(%edi)
	call	C(Cache_Free)
	addl	$4,%esp
	jmp	.Lcache_free_high_scan

.Lcache_free_high_move:
	movl	%edi,%esi
	pushl	%edi
	call	C(Cache_Move)
	addl	$4,%esp
	jmp	.Lcache_free_high_scan

.Lcache_free_high_done:
	popl	%edi
	popl	%esi
	popl	%ebx
	popl	%ebp
	ret
#endif /* ASM486_CACHE_FREE_HIGH */
