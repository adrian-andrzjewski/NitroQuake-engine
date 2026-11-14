#ifndef ASM_CACHEFREEHIGH_H
#define ASM_CACHEFREEHIGH_H

#define CFH_CACHE_SYSTEM_SIZE 40
#define CFH_CACHE_USER_OFFSET 4
#define CFH_CACHE_HEAD_PREV_OFFSET 24

#ifndef __ASSEMBLER__
#include <stddef.h>

typedef char cfh_cache_system_size_must_match[
	(sizeof(cache_system_t) == CFH_CACHE_SYSTEM_SIZE) ? 1 : -1];
typedef char cfh_cache_user_offset_must_match[
	(offsetof(cache_system_t, user) == CFH_CACHE_USER_OFFSET) ? 1 : -1];
typedef char cfh_cache_head_prev_offset_must_match[
	(offsetof(cache_system_t, prev) == CFH_CACHE_HEAD_PREV_OFFSET) ? 1 : -1];

void Cache_FreeHigh_C (int new_high_hunk);

#endif

#endif
