/* Layout and selector contract for SCR_DrawScreenOverlays. */
/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
#ifndef ASM_SCREEN_OVERLAYS_H
#define ASM_SCREEN_OVERLAYS_H

#define SO_CLIENT_INTERMISSION 548
#define SO_CLIENT_PAUSED 536
#define SO_KEY_GAME 0
#define SO_KEY_MESSAGE 2
#define SO_CVAR_VALUE 16
#define SO_VID_WIDTH 20
#define SO_VID_HEIGHT 24
#define SO_QPIC_WIDTH 0
#define SO_QPIC_HEIGHT 4

#define SO_EVENT_SBAR_DRAW 1
#define SO_EVENT_FADE_SCREEN 2
#define SO_EVENT_NOTIFY_STRING 3
#define SO_EVENT_DRAW_LOADING 4
#define SO_EVENT_INTERMISSION 5
#define SO_EVENT_FINALE 6
#define SO_EVENT_CHECK_CENTER 7
#define SO_EVENT_DRAW_RAM 8
#define SO_EVENT_DRAW_NET 9
#define SO_EVENT_DRAW_TURTLE 10
#define SO_EVENT_DRAW_PAUSE 11
#define SO_EVENT_DRAW_CONSOLE 12
#define SO_EVENT_MENU_DRAW 13

#ifndef __ASSEMBLER__
#include <stddef.h>

typedef char so_client_intermission_must_match[
		(offsetof(client_state_t, intermission) == SO_CLIENT_INTERMISSION) ? 1 : -1];
typedef char so_client_paused_must_match[
		(offsetof(client_state_t, paused) == SO_CLIENT_PAUSED) ? 1 : -1];
typedef char so_cvar_value_must_match[
		(offsetof(cvar_t, value) == SO_CVAR_VALUE) ? 1 : -1];
typedef char so_vid_width_must_match[
		(offsetof(viddef_t, width) == SO_VID_WIDTH) ? 1 : -1];
typedef char so_vid_height_must_match[
		(offsetof(viddef_t, height) == SO_VID_HEIGHT) ? 1 : -1];
typedef char so_qpic_width_must_match[
		(offsetof(qpic_t, width) == SO_QPIC_WIDTH) ? 1 : -1];
typedef char so_qpic_height_must_match[
		(offsetof(qpic_t, height) == SO_QPIC_HEIGHT) ? 1 : -1];
typedef char so_key_game_must_match[(key_game == SO_KEY_GAME) ? 1 : -1];
typedef char so_key_message_must_match[
		(key_message == SO_KEY_MESSAGE) ? 1 : -1];

void SCR_DrawScreenOverlays_asm486 (unsigned trace_update_index,
		qboolean trace_this_update);
void SCR_DrawPause (void);
void SCR_DrawLoading (void);
void SCR_DrawPause_asm486 (void);
void SCR_DrawLoading_asm486 (void);
void SCR_DrawConsole (void);

#if defined(BENCH486) && defined(ASM486_SCREEN_OVERLAYS)
void SCR_DrawScreenOverlays_Screen_C (unsigned trace_update_index,
		qboolean trace_this_update);
void SCR_DrawPause_Screen_C (void);
void SCR_DrawLoading_Screen_C (void);
void SCR_DrawConsole_Screen_C (void);
extern int bench486_screen_overlays_fixture_active;
extern int bench486_screen_overlay_widget_fixture_active;
void Bench486ScreenOverlaysRecordCall (int event);
qpic_t *Bench486ScreenOverlayCachePic (char *path);
void Bench486ScreenOverlayDrawPic (int x, int y, qpic_t *pic);
void Bench486ScreenConsoleDrawCall (int lines, qboolean drawinput);
void Bench486ScreenNotifyDrawCall (void);
void Bench486ScreenConsoleDrawCases (void);
void Bench486ScreenOverlayWidgetCases (void);
void Bench486ScreenOverlaysCases (void);
#endif
#endif

#endif
