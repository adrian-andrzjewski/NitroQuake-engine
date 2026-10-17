#ifndef ASM_HUNKNAMEDALLOC_H
#define ASM_HUNKNAMEDALLOC_H

#define HNA_HUNK_SENTINAL_OFFSET 0
#define HNA_HUNK_SIZE_OFFSET 4
#define HNA_HUNK_NAME_OFFSET 8
#define HNA_HUNK_NAME_SIZE 8
#define HNA_HUNK_SIZE 16
#define HNA_HUNK_SENTINAL_VALUE 0x1df001ed

#include "asm_hunkprint.h"

#ifndef __ASSEMBLER__
#include <stddef.h>

typedef char hna_hunk_sentinal_offset_must_match[
	(offsetof(hunk_t, sentinal) == HNA_HUNK_SENTINAL_OFFSET) ? 1 : -1];
typedef char hna_hunk_size_offset_must_match[
	(offsetof(hunk_t, size) == HNA_HUNK_SIZE_OFFSET) ? 1 : -1];
typedef char hna_hunk_name_offset_must_match[
	(offsetof(hunk_t, name) == HNA_HUNK_NAME_OFFSET) ? 1 : -1];
typedef char hna_hunk_name_size_must_match[
	(sizeof(((hunk_t *)0)->name) == HNA_HUNK_NAME_SIZE) ? 1 : -1];
typedef char hna_hunk_size_must_match[
	(sizeof(hunk_t) == HNA_HUNK_SIZE) ? 1 : -1];

void *Hunk_AllocName_C (int size, char *name);
void *Hunk_HighAllocName_C (int size, char *name);
#if defined(BENCH486) && defined(ASM486_HUNK_NAMED_ALLOC) && defined(ASM486_SCREEN_CENTER_STRING)
void Bench486HunkNamedAllocTrace (int phase, int x, int y, int character);
#endif
#endif

#endif
