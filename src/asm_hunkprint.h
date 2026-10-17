#ifndef ASM_HUNKPRINT_H
#define ASM_HUNKPRINT_H

#define HNA_HUNK_PRINT_TOTAL_SIZE 0
#define HNA_HUNK_PRINT_SEPARATOR 1
#define HNA_HUNK_PRINT_REMAINING 2
#define HNA_HUNK_PRINT_ALLOCATION 3
#define HNA_HUNK_PRINT_GROUP_TOTAL 4
#define HNA_HUNK_PRINT_BLOCKS 5

#define HNA_HUNK_PRINT_ERROR_SENTINAL 0
#define HNA_HUNK_PRINT_ERROR_SIZE 1

#ifndef __ASSEMBLER__
void Hunk_Print_C (qboolean all);
void Zone_HunkPrintTrace (int kind, void *hunk, int value);
void Zone_HunkPrintError (int kind);
#endif

#endif
