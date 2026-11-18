/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
#ifndef ASM_PLAYERTRANSLATION_H
#define ASM_PLAYERTRANSLATION_H

#define PT_IDENTITY_BYTES 256
#define PT_ROW_BYTES 256
#define PT_RANGE_BYTES 16
#define PT_TOP_RANGE 16
#define PT_BOTTOM_RANGE 96

#ifndef __ASSEMBLER__
#include <stddef.h>

typedef char pt_top_range_must_match[(TOP_RANGE == PT_TOP_RANGE) ? 1 : -1];
typedef char pt_bottom_range_must_match[(BOTTOM_RANGE == PT_BOTTOM_RANGE) ? 1 : -1];
typedef char pt_vid_grades_must_be_power_of_two[(VID_GRADES == 64) ? 1 : -1];

void M_BuildTranslationTable_asm486 (int top, int bottom);
void M_TranslatePlayerColors_asm486 (byte *dest, byte *source, int top,
		int bottom, int rows);
void M_BuildTranslationTable (int top, int bottom);
extern byte identityTable[PT_IDENTITY_BYTES];
extern byte translationTable[PT_IDENTITY_BYTES];

#if defined(BENCH486) && defined(ASM486_PLAYER_TRANSLATION_FIXTURE)
void M_BuildTranslationTable_C (int top, int bottom);
void CL_NewTranslation_C (int slot);
unsigned Bench486Call_asm486 (void (*function)(void), unsigned words,
		const unsigned *arguments, float *return_value);
#endif
#endif

#endif
