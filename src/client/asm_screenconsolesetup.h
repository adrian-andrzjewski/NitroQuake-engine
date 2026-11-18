/* Layout and entry contract for SCR_SetUpToDrawConsole's i486 assembly core. */
/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
#ifndef ASM_SCREEN_CONSOLE_SETUP_H
#define ASM_SCREEN_CONSOLE_SETUP_H

#define scs_vid_width_offset          20
#define scs_vid_height_offset         24
#define scs_vid_numpages_offset       32
#define scs_cl_worldmodel_offset    2692
#define scs_cls_signon_offset       2280
#define scs_scr_conspeed_value_offset 16
#define scs_key_console                1
#define scs_signons                   4

#ifndef __ASSEMBLER__
#include <stddef.h>

typedef char screen_console_setup_vid_width_offset_must_match[
		(offsetof(viddef_t, width) == scs_vid_width_offset) ? 1 : -1];
typedef char screen_console_setup_vid_height_offset_must_match[
		(offsetof(viddef_t, height) == scs_vid_height_offset) ? 1 : -1];
typedef char screen_console_setup_vid_numpages_offset_must_match[
		(offsetof(viddef_t, numpages) == scs_vid_numpages_offset) ? 1 : -1];
typedef char screen_console_setup_viddef_size_must_match[
		(sizeof(viddef_t) == 68) ? 1 : -1];
typedef char screen_console_setup_worldmodel_offset_must_match[
		(offsetof(client_state_t, worldmodel) == scs_cl_worldmodel_offset) ? 1 : -1];
typedef char screen_console_setup_signon_offset_must_match[
		(offsetof(client_static_t, signon) == scs_cls_signon_offset) ? 1 : -1];
typedef char screen_console_setup_cvar_value_offset_must_match[
		(offsetof(cvar_t, value) == scs_scr_conspeed_value_offset) ? 1 : -1];
typedef char screen_console_setup_key_console_value_must_match[
		(key_console == scs_key_console) ? 1 : -1];
typedef char screen_console_setup_signons_value_must_match[
		(SIGNONS == scs_signons) ? 1 : -1];

void SCR_SetUpToDrawConsole (void);

#if defined(BENCH486) && defined(ASM486_SCREEN_CONSOLE_SETUP)
void SCR_SetUpToDrawConsole_Screen_C (void);
void SCR_SetUpToDrawConsole_asm486 (void);
void Bench486ScreenConsoleSetupCheckResize (void);
void Bench486ScreenConsoleSetupTileClear (int x, int y, int width, int height);
void Bench486ScreenConsoleSetupSbarChanged (void);
#endif
#endif

#endif
