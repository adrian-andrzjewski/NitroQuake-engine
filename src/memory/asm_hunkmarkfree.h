/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
#ifndef ASM_HUNKMARKFREE_H
#define ASM_HUNKMARKFREE_H

#ifndef __ASSEMBLER__
void Hunk_FreeToLowMark_C (int mark);
void Hunk_FreeToHighMark_C (int mark);
int Hunk_HighMark_C (void);
#endif

#endif
