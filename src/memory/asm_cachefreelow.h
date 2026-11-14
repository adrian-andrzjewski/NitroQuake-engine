#ifndef ASM_CACHEFREELOW_H
#define ASM_CACHEFREELOW_H

#define CFL_CACHE_SYSTEM_SIZE 40
#define CFL_CACHE_NEXT_OFFSET 28
#define CFL_CACHE_HEAD_NEXT_OFFSET CFL_CACHE_NEXT_OFFSET

#ifndef __ASSEMBLER__
#include <stddef.h>

typedef char cfl_cache_system_size_must_match[
	(sizeof(cache_system_t) == CFL_CACHE_SYSTEM_SIZE) ? 1 : -1];
typedef char cfl_cache_next_offset_must_match[
	(offsetof(cache_system_t, next) == CFL_CACHE_NEXT_OFFSET) ? 1 : -1];

void Cache_FreeLow_C (int new_low_hunk);

#endif

#endif
