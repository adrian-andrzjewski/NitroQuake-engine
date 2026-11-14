/* Layout and entry contract for SCR_EraseCenterString's 486 assembly path. */
#ifndef ASM_SCREEN_ERASE_H
#define ASM_SCREEN_ERASE_H

#define se_vid_height_offset   24
#define se_vid_numpages_offset 32

#ifndef __ASSEMBLER__
#include <stddef.h>

typedef char screen_erase_vid_width_offset_must_match[
		(offsetof(viddef_t, width) == 20) ? 1 : -1];
typedef char screen_erase_vid_height_offset_must_match[
		(offsetof(viddef_t, height) == se_vid_height_offset) ? 1 : -1];
typedef char screen_erase_vid_numpages_offset_must_match[
		(offsetof(viddef_t, numpages) == se_vid_numpages_offset) ? 1 : -1];
typedef char screen_erase_viddef_size_must_match[
		(sizeof(viddef_t) == 68) ? 1 : -1];

void SCR_EraseCenterString (void);

#if defined(BENCH486) && defined(ASM486_SCREEN_ERASE_CENTER_STRING)
void SCR_EraseCenterString_Screen_C (void);
void SCR_EraseCenterString_asm486 (void);
void Bench486ScreenEraseTileClear (int x, int y, int width, int height);
#endif
#endif

#endif
