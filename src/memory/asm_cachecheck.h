/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
#ifndef ASM_CACHECHECK_H
#define ASM_CACHECHECK_H

#define CC_CACHE_SYSTEM_SIZE 40
#define CC_CACHE_LRU_PREV_OFFSET 32
#define CC_CACHE_LRU_NEXT_OFFSET 36
#define CC_CACHE_HEAD_LRU_NEXT_OFFSET 36

#ifndef __ASSEMBLER__
#include <stddef.h>

typedef char cc_cache_system_size_must_match[
		(sizeof(cache_system_t) == CC_CACHE_SYSTEM_SIZE) ? 1 : -1];
typedef char cc_cache_lru_prev_must_match[
		(offsetof(cache_system_t, lru_prev) == CC_CACHE_LRU_PREV_OFFSET) ? 1 : -1];
typedef char cc_cache_lru_next_must_match[
		(offsetof(cache_system_t, lru_next) == CC_CACHE_LRU_NEXT_OFFSET) ? 1 : -1];
typedef char cc_cache_user_data_must_match[
		(offsetof(cache_user_t, data) == 0) ? 1 : -1];

#endif

#endif
