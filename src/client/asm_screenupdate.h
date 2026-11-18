/* Layout and selector contract for screen.c:SCR_UpdateScreen. */
/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
#ifndef ASM_SCREEN_UPDATE_H
#define ASM_SCREEN_UPDATE_H

#define SU_VRECT_X 0
#define SU_VRECT_Y 4
#define SU_VRECT_WIDTH 8
#define SU_VRECT_HEIGHT 12
#define SU_VRECT_PNEXT 16
#define SU_VRECT_SIZE 20
#define SU_VID_WIDTH 20
#define SU_VID_HEIGHT 24
#define SU_VID_NUMPAGES 32
#define SU_VID_RECALC_REFDEF 36
#define SU_VID_SIZE 68
#define SU_CVAR_VALUE 16
#define SU_CLIENT_STATE 0
#define SU_CLIENT_DEMOPLAYBACK 2252
#define SU_CLIENT_STATIC_SIZE 2308
#define SU_CA_DEDICATED 0

#define SU_EVENT_CON_PRINT 1
#define SU_EVENT_CALC_REFDEF 2
#define SU_EVENT_ENABLE_BACKBUFFER 3
#define SU_EVENT_TILE_CLEAR 4
#define SU_EVENT_SBAR_CHANGED 5
#define SU_EVENT_SETUP_CONSOLE 6
#define SU_EVENT_ERASE_CENTER 7
#define SU_EVENT_DISABLE_BACKBUFFER 8
#define SU_EVENT_LOCK_BUFFER 9
#define SU_EVENT_RENDER_VIEW 10
#define SU_EVENT_UNLOCK_BUFFER 11
#define SU_EVENT_OVERLAYS 12
#define SU_EVENT_UPDATE_RECTS 13
#define SU_EVENT_UPDATE_PALETTE 14
#define SU_EVENT_VID_UPDATE 15

#ifndef __ASSEMBLER__
#include <stddef.h>

typedef char su_vrect_x_must_match[(offsetof(vrect_t, x) == SU_VRECT_X) ? 1 : -1];
typedef char su_vrect_y_must_match[(offsetof(vrect_t, y) == SU_VRECT_Y) ? 1 : -1];
typedef char su_vrect_width_must_match[(offsetof(vrect_t, width) == SU_VRECT_WIDTH) ? 1 : -1];
typedef char su_vrect_height_must_match[(offsetof(vrect_t, height) == SU_VRECT_HEIGHT) ? 1 : -1];
typedef char su_vrect_pnext_must_match[(offsetof(vrect_t, pnext) == SU_VRECT_PNEXT) ? 1 : -1];
typedef char su_vrect_size_must_match[(sizeof(vrect_t) == SU_VRECT_SIZE) ? 1 : -1];
typedef char su_vid_width_must_match[(offsetof(viddef_t, width) == SU_VID_WIDTH) ? 1 : -1];
typedef char su_vid_height_must_match[(offsetof(viddef_t, height) == SU_VID_HEIGHT) ? 1 : -1];
typedef char su_vid_numpages_must_match[(offsetof(viddef_t, numpages) == SU_VID_NUMPAGES) ? 1 : -1];
typedef char su_vid_recalc_must_match[(offsetof(viddef_t, recalc_refdef) == SU_VID_RECALC_REFDEF) ? 1 : -1];
typedef char su_vid_size_must_match[(sizeof(viddef_t) == SU_VID_SIZE) ? 1 : -1];
typedef char su_cvar_value_must_match[(offsetof(cvar_t, value) == SU_CVAR_VALUE) ? 1 : -1];
typedef char su_client_state_must_match[(offsetof(client_static_t, state) == SU_CLIENT_STATE) ? 1 : -1];
typedef char su_client_demoplayback_must_match[
		(offsetof(client_static_t, demoplayback) == SU_CLIENT_DEMOPLAYBACK) ? 1 : -1];
typedef char su_client_static_size_must_match[
		(sizeof(client_static_t) == SU_CLIENT_STATIC_SIZE) ? 1 : -1];
typedef char su_ca_dedicated_must_match[(ca_dedicated == SU_CA_DEDICATED) ? 1 : -1];

void SCR_UpdateScreen_asm486 (void);

#if defined(BENCH486) && defined(ASM486_SCREEN_UPDATE)
void SCR_UpdateScreen_Screen_C (void);
extern int bench486_screen_update_fixture_active;
void Bench486ScreenUpdateRecordCall (int event);
void Bench486ScreenUpdateRecordVidRect (const vrect_t *rect);
void Bench486ScreenUpdateCases (void);
#endif

#endif

#endif
