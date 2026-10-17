#ifndef ASM_ZONEHEAP_H
#define ASM_ZONEHEAP_H

#define ZH_MEMBLOCK_SIZE_OFFSET 0
#define ZH_MEMBLOCK_TAG_OFFSET 4
#define ZH_MEMBLOCK_ID_OFFSET 8
#define ZH_MEMBLOCK_NEXT_OFFSET 12
#define ZH_MEMBLOCK_PREV_OFFSET 16
#define ZH_MEMBLOCK_PAD_OFFSET 20
#define ZH_MEMBLOCK_SIZE 24

#define ZH_MEMZONE_SIZE_OFFSET 0
#define ZH_MEMZONE_BLOCKLIST_OFFSET 4
#define ZH_MEMZONE_BLOCKLIST_TAG_OFFSET 8
#define ZH_MEMZONE_BLOCKLIST_ID_OFFSET 12
#define ZH_MEMZONE_BLOCKLIST_NEXT_OFFSET 16
#define ZH_MEMZONE_BLOCKLIST_PREV_OFFSET 20
#define ZH_MEMZONE_BLOCKLIST_SIZE_OFFSET 4
#define ZH_MEMZONE_ROVER_OFFSET 28
#define ZH_MEMZONE_SIZE 32

#define ZH_ZONE_ID 0x1d4a11
#define ZH_MIN_FRAGMENT 64

#define ZH_CACHE_HEAD_PREV_OFFSET 24
#define ZH_CACHE_HEAD_NEXT_OFFSET 28
#define ZH_CACHE_HEAD_LRU_PREV_OFFSET 32
#define ZH_CACHE_HEAD_LRU_NEXT_OFFSET 36
#define ZH_CACHE_SYSTEM_SIZE 40

#ifndef __ASSEMBLER__
#include <stddef.h>

typedef char zh_memblock_size_offset_must_match[
	(offsetof(memblock_t, size) == ZH_MEMBLOCK_SIZE_OFFSET) ? 1 : -1];
typedef char zh_memblock_tag_offset_must_match[
	(offsetof(memblock_t, tag) == ZH_MEMBLOCK_TAG_OFFSET) ? 1 : -1];
typedef char zh_memblock_id_offset_must_match[
	(offsetof(memblock_t, id) == ZH_MEMBLOCK_ID_OFFSET) ? 1 : -1];
typedef char zh_memblock_next_offset_must_match[
	(offsetof(memblock_t, next) == ZH_MEMBLOCK_NEXT_OFFSET) ? 1 : -1];
typedef char zh_memblock_prev_offset_must_match[
	(offsetof(memblock_t, prev) == ZH_MEMBLOCK_PREV_OFFSET) ? 1 : -1];
typedef char zh_memblock_pad_offset_must_match[
	(offsetof(memblock_t, pad) == ZH_MEMBLOCK_PAD_OFFSET) ? 1 : -1];
typedef char zh_memblock_size_must_match[
	(sizeof(memblock_t) == ZH_MEMBLOCK_SIZE) ? 1 : -1];
typedef char zh_memzone_size_offset_must_match[
	(offsetof(memzone_t, size) == ZH_MEMZONE_SIZE_OFFSET) ? 1 : -1];
typedef char zh_memzone_blocklist_offset_must_match[
	(offsetof(memzone_t, blocklist) == ZH_MEMZONE_BLOCKLIST_OFFSET) ? 1 : -1];
typedef char zh_memzone_rover_offset_must_match[
	(offsetof(memzone_t, rover) == ZH_MEMZONE_ROVER_OFFSET) ? 1 : -1];
typedef char zh_memzone_size_must_match[
	(sizeof(memzone_t) == ZH_MEMZONE_SIZE) ? 1 : -1];
void Z_ClearZone_C (memzone_t *zone, int size);
void Z_Free_C (void *ptr);
void *Z_TagMalloc_C (int size, int tag);
void *Z_Malloc_C (int size);
void Z_CheckHeap_C (void);
void Hunk_Check_C (void);
void Cache_Init_C (void);
void Memory_Init_C (void *buf, int size);
#endif

#endif
