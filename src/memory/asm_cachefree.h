#ifndef ASM_CACHEFREE_H
#define ASM_CACHEFREE_H

#define CF_CACHE_SYSTEM_SIZE 40
#define CF_CACHE_USER_DATA_OFFSET 0
#define CF_CACHE_PREV_OFFSET 24
#define CF_CACHE_NEXT_OFFSET 28
#define CF_CACHE_LRU_PREV_OFFSET 32
#define CF_CACHE_LRU_NEXT_OFFSET 36

#ifndef __ASSEMBLER__
#include <stddef.h>

void Cache_Free_C (cache_user_t *c);
void Cache_Flush_C (void);

typedef char cf_cache_system_size_must_match[
	(sizeof(cache_system_t) == CF_CACHE_SYSTEM_SIZE) ? 1 : -1];
typedef char cf_cache_user_data_offset_must_match[
	(offsetof(cache_user_t, data) == CF_CACHE_USER_DATA_OFFSET) ? 1 : -1];
typedef char cf_cache_prev_offset_must_match[
	(offsetof(cache_system_t, prev) == CF_CACHE_PREV_OFFSET) ? 1 : -1];
typedef char cf_cache_next_offset_must_match[
	(offsetof(cache_system_t, next) == CF_CACHE_NEXT_OFFSET) ? 1 : -1];
typedef char cf_cache_lru_prev_offset_must_match[
	(offsetof(cache_system_t, lru_prev) == CF_CACHE_LRU_PREV_OFFSET) ? 1 : -1];
typedef char cf_cache_lru_next_offset_must_match[
	(offsetof(cache_system_t, lru_next) == CF_CACHE_LRU_NEXT_OFFSET) ? 1 : -1];

#endif

#endif
