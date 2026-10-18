#ifndef ASM_MENUTEXT_H
#define ASM_MENUTEXT_H

#define MT_VID_WIDTH_OFFSET 20

#ifndef __ASSEMBLER__
#include <stddef.h>

typedef char mt_vid_width_offset_must_match[
		(offsetof(viddef_t, width) == MT_VID_WIDTH_OFFSET) ? 1 : -1];

void M_DrawCharacter (int cx, int line, int num);
void M_Print (int cx, int cy, char *str);
void M_PrintWhite (int cx, int cy, char *str);
void M_DrawTransPic (int x, int y, qpic_t *pic);
void M_DrawPic (int x, int y, qpic_t *pic);
void M_DrawTransPicTranslate (int x, int y, qpic_t *pic);
extern byte translationTable[256];

#if defined(BENCH486) && defined(ASM486_SCREEN_OVERLAYS)
void M_DrawCharacter_C (int cx, int line, int num);
void M_Print_C (int cx, int cy, char *str);
void M_PrintWhite_C (int cx, int cy, char *str);
void M_DrawTransPic_C (int x, int y, qpic_t *pic);
void M_DrawPic_C (int x, int y, qpic_t *pic);
void M_DrawTransPicTranslate_C (int x, int y, qpic_t *pic);
void Bench486MenuTextDrawCharacter (int x, int y, int num);
void Bench486MenuTextDrawPic (int kind, int x, int y, qpic_t *pic,
		byte *translation);
void Bench486MenuTextCases (void);
void Bench486MenuPictureCases (void);
#endif
#endif

#endif
