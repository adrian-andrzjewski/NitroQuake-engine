/* i486 cache free-block search and address/LRU list insertion. */
#include "asm_i386.h"
#include "asm_cachefree.h"
#include "asm_cachealloc.h"
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

/* Cache_Flush shares the cache-free selector and repeatedly frees the
   current address-list head, reloading it after each unlink. */
.p2align 2
.globl C(Cache_Flush)
C(Cache_Flush):
.Lcache_flush_next:
	movl	C(cache_head)+CF_CACHE_NEXT_OFFSET,%eax
	leal	C(cache_head),%ecx
	cmpl	%ecx,%eax
	je	.Lcache_flush_done
	pushl	CA_CACHE_SYSTEM_USER_OFFSET(%eax)
	call	C(Cache_Free)
	addl	$4,%esp
	jmp	.Lcache_flush_next

.Lcache_flush_done:
	ret

.section .rodata
.Lcache_free_unallocated_message:
	.asciz	"Cache_Free: not allocated"
.Lcache_free_bad_lru_message:
	.asciz	"Cache_UnlinkLRU: NULL link"
#endif /* ASM486_CACHE_FREE */

#ifdef ASM486_CACHE_ALLOC
.text
.p2align 2
.globl C(Cache_Alloc)
C(Cache_Alloc):
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	movl	8(%ebp),%esi		/* cache_user_t * */
	movl	12(%ebp),%ebx		/* requested payload size */
	movl	16(%ebp),%edi		/* name */
	movl	CA_CACHE_USER_DATA_OFFSET(%esi),%eax
	testl	%eax,%eax
	je	.Lcache_alloc_unallocated
	pushl	$.Lcache_alloc_already_allocated_message
	call	C(Sys_Error)
	addl	$4,%esp

.Lcache_alloc_unallocated:
	cmpl	$0,%ebx
	jg	.Lcache_alloc_size_valid
	pushl	%ebx
	pushl	$.Lcache_alloc_bad_size_message
	call	C(Sys_Error)
	addl	$8,%esp

.Lcache_alloc_size_valid:
	addl	$(CA_CACHE_SYSTEM_SIZE + CA_CACHE_ALIGNMENT - 1),%ebx
	andl	$-CA_CACHE_ALIGNMENT,%ebx

.Lcache_alloc_retry:
	pushl	$0
	pushl	%ebx
	call	C(Cache_TryAlloc)
	addl	$8,%esp
	testl	%eax,%eax
	je	.Lcache_alloc_failed
	movl	%eax,%ebx			/* cache_system_t * */
#ifdef PROFILE486
	incl	C(bench486_cache_allocations)
#endif
	leal	CA_CACHE_SYSTEM_NAME_OFFSET(%ebx),%eax
	pushl	$(CA_CACHE_SYSTEM_NAME_SIZE - 1)
	pushl	%edi
	pushl	%eax
	call	C(strncpy)
	addl	$12,%esp
	movl	%esi,CA_CACHE_SYSTEM_USER_OFFSET(%ebx)
	leal	CA_CACHE_SYSTEM_SIZE(%ebx),%eax
	movl	%eax,CA_CACHE_USER_DATA_OFFSET(%esi)
	movl	CA_CACHE_USER_DATA_OFFSET(%esi),%eax
	jmp	.Lcache_alloc_return

.Lcache_alloc_failed:
	leal	C(cache_head),%eax
	movl	CA_CACHE_HEAD_LRU_PREV_OFFSET(%eax),%edx
	cmpl	%eax,%edx
	jne	.Lcache_alloc_evict
	pushl	$.Lcache_alloc_oom_message
	call	C(Sys_Error)
	addl	$4,%esp

.Lcache_alloc_evict:
#ifdef PROFILE486
	incl	C(bench486_cache_evictions)
#endif
	pushl	CA_CACHE_SYSTEM_USER_OFFSET(%edx)
	call	C(Cache_Free)
	addl	$4,%esp
	jmp	.Lcache_alloc_retry

.Lcache_alloc_return:
	popl	%edi
	popl	%esi
	popl	%ebx
	leave
	ret

.section .rodata
.Lcache_alloc_already_allocated_message:
	.asciz	"Cache_Alloc: allready allocated"
.Lcache_alloc_bad_size_message:
	.asciz	"Cache_Alloc: size %i"
.Lcache_alloc_oom_message:
	.asciz	"Cache_Alloc: out of memory"
#endif /* ASM486_CACHE_ALLOC */

#ifdef ASM486_CACHE_MOVE
.text
.p2align 2
.globl C(Cache_Move)
C(Cache_Move):
	pushl	%ebp
	movl	%esp,%ebp
	subl	$4,%esp			/* saved destination header */
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	movl	8(%ebp),%esi		/* old cache_system_t * */
	movl	CA_CACHE_SYSTEM_USER_OFFSET(%esi),%edi
	movl	CA_CACHE_SYSTEM_SIZE_OFFSET(%esi),%ebx
	pushl	$1			/* nobottom = true */
	pushl	%ebx
	call	C(Cache_TryAlloc)
	addl	$8,%esp
	movl	%eax,-4(%ebp)
#ifdef PROFILE486
	incl	C(bench486_cache_moves)
	movl	CA_CACHE_SYSTEM_SIZE_OFFSET(%esi),%eax
	subl	$CA_CACHE_SYSTEM_SIZE,%eax
	addl	%eax,C(bench486_cache_move_bytes)
#endif
	cmpl	$0,-4(%ebp)
	je	.Lcache_move_failed

	movl	CA_CACHE_SYSTEM_SIZE_OFFSET(%esi),%ebx
	subl	$CA_CACHE_SYSTEM_SIZE,%ebx
	movl	-4(%ebp),%eax
	leal	CA_CACHE_SYSTEM_SIZE(%eax),%edx
	leal	CA_CACHE_SYSTEM_SIZE(%esi),%ecx
	pushl	%ebx
	pushl	%ecx
	pushl	%edx
	call	C(Q_memcpy)
	addl	$12,%esp

	movl	-4(%ebp),%eax
	movl	%edi,CA_CACHE_SYSTEM_USER_OFFSET(%eax)
	leal	CA_CACHE_SYSTEM_NAME_OFFSET(%esi),%ecx
	leal	CA_CACHE_SYSTEM_NAME_OFFSET(%eax),%edx
	pushl	$CA_CACHE_SYSTEM_NAME_SIZE
	pushl	%ecx
	pushl	%edx
	call	C(Q_memcpy)
	addl	$12,%esp

	pushl	%edi
	call	C(Cache_Free)
	addl	$4,%esp
	movl	-4(%ebp),%eax
	leal	CA_CACHE_SYSTEM_SIZE(%eax),%edx
	movl	%edx,CA_CACHE_USER_DATA_OFFSET(%edi)
	jmp	.Lcache_move_return

.Lcache_move_failed:
	pushl	%edi
	call	C(Cache_Free)
	addl	$4,%esp

.Lcache_move_return:
	popl	%edi
	popl	%esi
	popl	%ebx
	leave
	ret
#endif /* ASM486_CACHE_MOVE */
