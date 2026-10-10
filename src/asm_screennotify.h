/* Shared viddef layout for SCR_DrawNotifyString's 486 assembly path. */
#ifndef ASM_SCREEN_NOTIFY_H
#define ASM_SCREEN_NOTIFY_H

#define sn_vid_width_offset  20
#define sn_vid_height_offset 24

#ifndef __ASSEMBLER__
#include <stddef.h>
typedef char screen_notify_vid_width_offset_must_match[
		(offsetof(viddef_t, width) == sn_vid_width_offset) ? 1 : -1];
typedef char screen_notify_vid_height_offset_must_match[
		(offsetof(viddef_t, height) == sn_vid_height_offset) ? 1 : -1];
typedef char screen_notify_viddef_size_must_match[
		(sizeof(viddef_t) == 68) ? 1 : -1];

#if defined(BENCH486) && defined(ASM486_SCREEN_NOTIFY)
void Bench486ScreenNotifyCharacter (int x, int y, int num);
#endif
#endif

#endif
