/* Layout contract for the centered-message 486 assembly path. */
#ifndef ASM_SCREEN_CENTER_H
#define ASM_SCREEN_CENTER_H

#define sc_vid_width_offset 20
#define sc_vid_height_offset 24
#define sc_client_intermission_offset 548
#define sc_client_time_offset 572
#define sc_cvar_value_offset 16

#ifndef __ASSEMBLER__
#include <stddef.h>

typedef char screen_center_vid_width_offset_must_match[
		(offsetof(viddef_t, width) == sc_vid_width_offset) ? 1 : -1];
typedef char screen_center_vid_height_offset_must_match[
		(offsetof(viddef_t, height) == sc_vid_height_offset) ? 1 : -1];
typedef char screen_center_viddef_size_must_match[
		(sizeof(viddef_t) == 68) ? 1 : -1];
typedef char screen_center_client_intermission_offset_must_match[
		(offsetof(client_state_t, intermission) == sc_client_intermission_offset) ? 1 : -1];
typedef char screen_center_client_time_offset_must_match[
		(offsetof(client_state_t, time) == sc_client_time_offset) ? 1 : -1];
typedef char screen_center_client_time_size_must_match[
		(sizeof(((client_state_t *)0)->time) == 8) ? 1 : -1];
typedef char screen_center_cvar_value_offset_must_match[
		(offsetof(cvar_t, value) == sc_cvar_value_offset) ? 1 : -1];

void SCR_DrawCenterString (void);
void SCR_CheckDrawCenterString (void);

#if defined(BENCH486) && defined(ASM486_SCREEN_CENTER_STRING)
void SCR_DrawCenterString_Screen_C (void);
void SCR_DrawCenterString_asm486 (void);
void Bench486ScreenCenterStringCharacter (int x, int y, int num);
void SCR_CheckDrawCenterString_Screen_C (void);
void Bench486ScreenCenterCheckDraw (void);
void Bench486ScreenCenterCheckCases (void);
#endif
#endif

#endif
