/* Hot cache lookup and exact LRU promotion from src/zone.c:Cache_Check. */
#include "asm_i386.h"
#include "asm_cachecheck.h"
#undef i386
.arch i486
.code32

#ifdef ASM486_CACHE_CHECK
.text
.p2align 2
.globl C(Cache_Check)
C(Cache_Check):
#ifdef PROFILE486
	incl C(bench486_cache_checks)
#endif
	movl 4(%esp),%eax
	movl (%eax),%edx
	testl %edx,%edx
	je .Lcache_check_miss
	subl $CC_CACHE_SYSTEM_SIZE,%edx
	cmpl C(cache_head)+CC_CACHE_HEAD_LRU_NEXT_OFFSET,%edx
	je .Lcache_check_hit

#ifdef PROFILE486
	incl C(bench486_cache_lru_relinks)
#endif
	/* Cache_UnlinkLRU(cs), preserving its pointer update order. */
	movl CC_CACHE_LRU_NEXT_OFFSET(%edx),%ecx
	movl CC_CACHE_LRU_PREV_OFFSET(%edx),%eax
	movl %eax,CC_CACHE_LRU_PREV_OFFSET(%ecx)
	movl %ecx,CC_CACHE_LRU_NEXT_OFFSET(%eax)
	movl $0,CC_CACHE_LRU_PREV_OFFSET(%edx)
	movl $0,CC_CACHE_LRU_NEXT_OFFSET(%edx)

	/* Cache_MakeLRU(cs). */
	movl C(cache_head)+CC_CACHE_HEAD_LRU_NEXT_OFFSET,%ecx
	movl %edx,CC_CACHE_LRU_PREV_OFFSET(%ecx)
	movl %ecx,CC_CACHE_LRU_NEXT_OFFSET(%edx)
	movl $C(cache_head),%eax
	movl %eax,CC_CACHE_LRU_PREV_OFFSET(%edx)
	movl %edx,C(cache_head)+CC_CACHE_HEAD_LRU_NEXT_OFFSET

.Lcache_check_hit:
#ifdef PROFILE486
	incl C(bench486_cache_hits)
#endif
	movl 4(%esp),%eax
	movl (%eax),%eax
	ret

.Lcache_check_miss:
#ifdef PROFILE486
	incl C(bench486_cache_misses)
#endif
	xorl %eax,%eax
	ret
#endif /* ASM486_CACHE_CHECK */
