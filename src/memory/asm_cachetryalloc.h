/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
#ifndef ASM_CACHETRYALLOC_H
#define ASM_CACHETRYALLOC_H

#define CTA_CACHE_SYSTEM_SIZE 40
#define CTA_CACHE_SIZE_OFFSET 0
#define CTA_CACHE_NAME_OFFSET 8
#define CTA_CACHE_PREV_OFFSET 24
#define CTA_CACHE_NEXT_OFFSET 28
#define CTA_CACHE_LRU_PREV_OFFSET 32
#define CTA_CACHE_LRU_NEXT_OFFSET 36
#define CTA_CACHE_HEAD_PREV_OFFSET CTA_CACHE_PREV_OFFSET
#define CTA_CACHE_HEAD_NEXT_OFFSET CTA_CACHE_NEXT_OFFSET
#define CTA_CACHE_HEAD_LRU_NEXT_OFFSET CTA_CACHE_LRU_NEXT_OFFSET

#ifndef __ASSEMBLER__
#include <stddef.h>

typedef char cta_cache_system_size_must_match[
	(sizeof(cache_system_t) == CTA_CACHE_SYSTEM_SIZE) ? 1 : -1];
typedef char cta_cache_size_offset_must_match[
	(offsetof(cache_system_t, size) == CTA_CACHE_SIZE_OFFSET) ? 1 : -1];
typedef char cta_cache_name_offset_must_match[
	(offsetof(cache_system_t, name) == CTA_CACHE_NAME_OFFSET) ? 1 : -1];
typedef char cta_cache_prev_offset_must_match[
	(offsetof(cache_system_t, prev) == CTA_CACHE_PREV_OFFSET) ? 1 : -1];
typedef char cta_cache_next_offset_must_match[
	(offsetof(cache_system_t, next) == CTA_CACHE_NEXT_OFFSET) ? 1 : -1];
typedef char cta_cache_lru_prev_offset_must_match[
	(offsetof(cache_system_t, lru_prev) == CTA_CACHE_LRU_PREV_OFFSET) ? 1 : -1];
typedef char cta_cache_lru_next_offset_must_match[
	(offsetof(cache_system_t, lru_next) == CTA_CACHE_LRU_NEXT_OFFSET) ? 1 : -1];

void Cache_Print_C (void);

#endif

#endif
