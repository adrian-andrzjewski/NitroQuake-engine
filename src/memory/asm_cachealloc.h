#ifndef ASM_CACHEALLOC_H
#define ASM_CACHEALLOC_H

#define CA_CACHE_SYSTEM_SIZE 40
#define CA_CACHE_SYSTEM_SIZE_OFFSET 0
#define CA_CACHE_SYSTEM_USER_OFFSET 4
#define CA_CACHE_SYSTEM_NAME_OFFSET 8
#define CA_CACHE_SYSTEM_NAME_SIZE 16
#define CA_CACHE_HEAD_LRU_PREV_OFFSET 32
#define CA_CACHE_USER_DATA_OFFSET 0
#define CA_CACHE_ALIGNMENT 16

#ifndef __ASSEMBLER__
#include <stddef.h>

typedef char ca_cache_system_size_must_match[
	(sizeof(cache_system_t) == CA_CACHE_SYSTEM_SIZE) ? 1 : -1];
typedef char ca_cache_system_size_offset_must_match[
	(offsetof(cache_system_t, size) == CA_CACHE_SYSTEM_SIZE_OFFSET) ? 1 : -1];
typedef char ca_cache_system_user_offset_must_match[
	(offsetof(cache_system_t, user) == CA_CACHE_SYSTEM_USER_OFFSET) ? 1 : -1];
typedef char ca_cache_system_name_offset_must_match[
	(offsetof(cache_system_t, name) == CA_CACHE_SYSTEM_NAME_OFFSET) ? 1 : -1];
typedef char ca_cache_system_name_size_must_match[
	(sizeof(((cache_system_t *)0)->name) == CA_CACHE_SYSTEM_NAME_SIZE) ? 1 : -1];
typedef char ca_cache_head_lru_prev_offset_must_match[
	(offsetof(cache_system_t, lru_prev) == CA_CACHE_HEAD_LRU_PREV_OFFSET) ? 1 : -1];
typedef char ca_cache_user_data_offset_must_match[
	(offsetof(cache_user_t, data) == CA_CACHE_USER_DATA_OFFSET) ? 1 : -1];

#endif

#endif
