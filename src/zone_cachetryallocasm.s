/* i486 cache free-block search and address/LRU list insertion. */
#include "asm_i386.h"
#include "asm_cachefree.h"
#include "asm_cachetryalloc.h"
#undef i386
.arch i486
.code32

#ifdef ASM486_CACHE_TRY_ALLOC
.text
.p2align 2
.globl C(Cache_TryAlloc)
C(Cache_TryAlloc):
	pushl	%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	cld
	movl	20(%esp),%edx		/* requested block size */
	movl	24(%esp),%ebx		/* nobottom */

/* Match Cache_TryAlloc's empty-list fast path, including its error contract. */
	testl	%ebx,%ebx
	jne	.Lcache_tryalloc_scan_init
	leal	C(cache_head),%eax
	cmpl	%eax,C(cache_head)+CTA_CACHE_HEAD_PREV_OFFSET
	jne	.Lcache_tryalloc_scan_init
	movl	C(hunk_size),%eax
	subl	C(hunk_high_used),%eax
	subl	C(hunk_low_used),%eax
	cmpl	%edx,%eax
	jl	.Lcache_tryalloc_empty_error
	movl	C(hunk_base),%edi
	addl	C(hunk_low_used),%edi
	leal	C(cache_head),%esi
	jmp	.Lcache_tryalloc_insert

.Lcache_tryalloc_empty_error:
	pushl	%edx
	pushl	$.Lcache_tryalloc_error_message
	call	C(Sys_Error)
	addl	$8,%esp
	/* Sys_Error does not return; keep the function safe if a test stub does. */
	jmp	.Lcache_tryalloc_fail

/* Search address-ordered cache blocks from the low hunk mark upward. */
.Lcache_tryalloc_scan_init:
	movl	C(hunk_base),%edi
	addl	C(hunk_low_used),%edi
	movl	C(cache_head)+CTA_CACHE_HEAD_NEXT_OFFSET,%esi
.Lcache_tryalloc_scan:
#ifdef PROFILE486
	incl	C(bench486_cache_tryalloc_scans)
#endif
	testl	%ebx,%ebx
	je	.Lcache_tryalloc_test_gap
	cmpl	C(cache_head)+CTA_CACHE_HEAD_NEXT_OFFSET,%esi
	je	.Lcache_tryalloc_next
.Lcache_tryalloc_test_gap:
	movl	%esi,%eax
	subl	%edi,%eax
	cmpl	%edx,%eax
	jge	.Lcache_tryalloc_insert

.Lcache_tryalloc_next:
	movl	CTA_CACHE_SIZE_OFFSET(%esi),%eax
	leal	(%esi,%eax),%edi
	movl	CTA_CACHE_NEXT_OFFSET(%esi),%esi
	leal	C(cache_head),%eax
	cmpl	%eax,%esi
	jne	.Lcache_tryalloc_scan

/* The final free region ends at hunk_base + hunk_size - hunk_high_used. */
	movl	C(hunk_base),%eax
	addl	C(hunk_size),%eax
	subl	C(hunk_high_used),%eax
	subl	%edi,%eax
	cmpl	%edx,%eax
	jl	.Lcache_tryalloc_fail
	leal	C(cache_head),%esi

/* Initialize the header, insert by address, and promote to the LRU head. */
.Lcache_tryalloc_insert:
	movl	%edi,%ebp
	movl	%edi,%edi
	xorl	%eax,%eax
	movl	$(CTA_CACHE_SYSTEM_SIZE/4),%ecx
	rep	stosl
	movl	%ebp,%edi
	movl	%edx,CTA_CACHE_SIZE_OFFSET(%edi)
	movl	CTA_CACHE_PREV_OFFSET(%esi),%eax
	movl	%esi,CTA_CACHE_NEXT_OFFSET(%edi)
	movl	%eax,CTA_CACHE_PREV_OFFSET(%edi)
	movl	%edi,CTA_CACHE_NEXT_OFFSET(%eax)
	movl	%edi,CTA_CACHE_PREV_OFFSET(%esi)

	leal	C(cache_head),%eax
	movl	CTA_CACHE_HEAD_LRU_NEXT_OFFSET(%eax),%ecx
	movl	%eax,CTA_CACHE_LRU_PREV_OFFSET(%edi)
	movl	%ecx,CTA_CACHE_LRU_NEXT_OFFSET(%edi)
	movl	%edi,CTA_CACHE_LRU_PREV_OFFSET(%ecx)
	movl	%edi,CTA_CACHE_HEAD_LRU_NEXT_OFFSET(%eax)
	movl	%ebp,%eax
	jmp	.Lcache_tryalloc_return

.Lcache_tryalloc_fail:
#ifdef PROFILE486
	incl	C(bench486_cache_tryalloc_failures)
#endif
	xorl	%eax,%eax
.Lcache_tryalloc_return:
	popl	%edi
	popl	%esi
	popl	%ebx
	popl	%ebp
	ret

.section .rodata
.Lcache_tryalloc_error_message:
	.asciz	"Cache_TryAlloc: %i is greater then free hunk"
#endif /* ASM486_CACHE_TRY_ALLOC */

#ifdef ASM486_CACHE_FREE
.text
.p2align 2
.globl C(Cache_Free)
C(Cache_Free):
	pushl	%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	movl	20(%esp),%eax		/* cache_user_t * */
	movl	CF_CACHE_USER_DATA_OFFSET(%eax),%edx
	testl	%edx,%edx
	je	.Lcache_free_unallocated
	leal	-CF_CACHE_SYSTEM_SIZE(%edx),%esi
#ifdef PROFILE486
	incl	C(bench486_cache_frees)
#endif

/* Remove from the address-ordered list, then clear the cache user handle. */
	movl	CF_CACHE_PREV_OFFSET(%esi),%ebx
	movl	CF_CACHE_NEXT_OFFSET(%esi),%edi
	movl	%edi,CF_CACHE_NEXT_OFFSET(%ebx)
	movl	%ebx,CF_CACHE_PREV_OFFSET(%edi)
	movl	$0,CF_CACHE_PREV_OFFSET(%esi)
	movl	$0,CF_CACHE_NEXT_OFFSET(%esi)
	movl	$0,CF_CACHE_USER_DATA_OFFSET(%eax)

/* Match Cache_UnlinkLRU's validation and unlink order. */
	movl	CF_CACHE_LRU_NEXT_OFFSET(%esi),%edi
	testl	%edi,%edi
	je	.Lcache_free_bad_lru_link
	movl	CF_CACHE_LRU_PREV_OFFSET(%esi),%ebx
	testl	%ebx,%ebx
	je	.Lcache_free_bad_lru_link
	movl	%ebx,CF_CACHE_LRU_PREV_OFFSET(%edi)
	movl	%edi,CF_CACHE_LRU_NEXT_OFFSET(%ebx)
	movl	$0,CF_CACHE_LRU_PREV_OFFSET(%esi)
	movl	$0,CF_CACHE_LRU_NEXT_OFFSET(%esi)
	jmp	.Lcache_free_return

.Lcache_free_unallocated:
	pushl	$.Lcache_free_unallocated_message
	call	C(Sys_Error)
	addl	$4,%esp
	jmp	.Lcache_free_return

.Lcache_free_bad_lru_link:
	pushl	$.Lcache_free_bad_lru_message
	call	C(Sys_Error)
	addl	$4,%esp

.Lcache_free_return:
	popl	%edi
	popl	%esi
	popl	%ebx
	popl	%ebp
	ret

.section .rodata
.Lcache_free_unallocated_message:
	.asciz	"Cache_Free: not allocated"
.Lcache_free_bad_lru_message:
	.asciz	"Cache_UnlinkLRU: NULL link"
#endif /* ASM486_CACHE_FREE */
