#ifndef ASM_MENUTEXT_H
#define ASM_MENUTEXT_H

#define MT_VID_WIDTH_OFFSET 20
#define MT_VID_HEIGHT_OFFSET 24
#define MENU_SAVE_SLOT_COUNT 12
#define MENU_SAVE_FILENAME_STRIDE 40
#define MD_KEY_BIND_COUNT 18

#define MD_STATE_NONE 0
#define MD_STATE_MAIN 1
#define MD_STATE_SINGLEPLAYER 2
#define MD_STATE_LOAD 3
#define MD_STATE_SAVE 4
#define MD_STATE_MULTIPLAYER 5
#define MD_STATE_SETUP 6
#define MD_STATE_NET 7
#define MD_STATE_OPTIONS 8
#define MD_STATE_VIDEO 9
#define MD_STATE_KEYS 10
#define MD_STATE_HELP 11
#define MD_STATE_QUIT 12
#define MD_STATE_SERIALCONFIG 13
#define MD_STATE_MODEMCONFIG 14
#define MD_STATE_LANCONFIG 15
#define MD_STATE_GAMEOPTIONS 16
#define MD_STATE_SEARCH 17
#define MD_STATE_SERVERLIST 18
#define MD_STATE_LAST MD_STATE_SERVERLIST
#define MD_KEY_MENU 3

#define MD_EVENT_FADE_SCREEN 1
#define MD_EVENT_CONSOLE_BACKGROUND 2
#define MD_EVENT_EXTRA_UPDATE 3
#define MD_EVENT_MENU_SOUND 4
#define MD_EVENT_BAD_SOUND 5
#define MD_EVENT_DRAW_BASE 100

#ifndef __ASSEMBLER__
#include <stddef.h>

typedef char mt_vid_width_offset_must_match[
		(offsetof(viddef_t, width) == MT_VID_WIDTH_OFFSET) ? 1 : -1];
typedef char mt_cvar_value_offset_must_match[
		(offsetof(cvar_t, value) == 16) ? 1 : -1];

void M_DrawCharacter (int cx, int line, int num);
void M_Print (int cx, int cy, char *str);
void M_PrintWhite (int cx, int cy, char *str);
void M_DrawTransPic (int x, int y, qpic_t *pic);
void M_DrawPic (int x, int y, qpic_t *pic);
void M_DrawTransPicTranslate (int x, int y, qpic_t *pic);
void M_DrawTextBox (int x, int y, int width, int lines);
void M_Draw (void);
void M_Video_Draw (void);
void M_Keys_Draw (void);
void M_Options_Draw (void);
void M_DrawSlider (int x, int y, float range);
void M_DrawCheckbox (int x, int y, int on);
void M_Quit_Draw (void);
void M_Main_Draw (void);
void M_SinglePlayer_Draw (void);
void M_MultiPlayer_Draw (void);
void M_Setup_Draw (void);
void M_Net_Draw (void);
void M_SerialConfig_Draw (void);
void M_ModemConfig_Draw (void);
void M_LanConfig_Draw (void);
void M_GameOptions_Draw (void);
void M_Search_Draw (void);
void M_Help_Draw (void);
void M_Load_Draw (void);
void M_Save_Draw (void);
void M_FindKeysForCommand (char *command, int *twokeys);
extern byte translationTable[256];
extern int load_cursor;
extern char m_filenames[MENU_SAVE_SLOT_COUNT][MENU_SAVE_FILENAME_STRIDE];
extern int m_net_cursor;
extern int m_net_items;
extern char *net_helpMessage[16];
extern int m_multiplayer_cursor;
extern int modemConfig_cursor;
extern int modemConfig_cursor_table[5];
extern char modemConfig_dialing;
extern char modemConfig_clear[16];
extern char modemConfig_init[32];
extern char modemConfig_hangup[16];
extern qboolean serialAvailable;
extern qboolean ipxAvailable;
extern qboolean tcpipAvailable;

#if defined(BENCH486) && defined(ASM486_SCREEN_OVERLAYS)
void M_DrawCharacter_C (int cx, int line, int num);
void M_Print_C (int cx, int cy, char *str);
void M_PrintWhite_C (int cx, int cy, char *str);
void M_DrawTransPic_C (int x, int y, qpic_t *pic);
void M_DrawPic_C (int x, int y, qpic_t *pic);
void M_DrawTransPicTranslate_C (int x, int y, qpic_t *pic);
void M_DrawTextBox_C (int x, int y, int width, int lines);
void M_Draw_C (void);
void M_Video_Draw_C (void);
void M_Keys_Draw_C (void);
void M_Main_Draw_C (void);
void M_SinglePlayer_Draw_C (void);
void M_MultiPlayer_Draw_C (void);
void M_Setup_Draw_C (void);
void M_Net_Draw_C (void);
void M_Options_Draw_C (void);
void M_GameOptions_Draw_C (void);
void M_Search_Draw_C (void);
void M_DrawSlider_C (int x, int y, float range);
void M_DrawCheckbox_C (int x, int y, int on);
void M_Quit_Draw_C (void);
void M_SerialConfig_Draw_C (void);
void M_ModemConfig_Draw_C (void);
void M_LanConfig_Draw_C (void);
void M_Help_Draw_C (void);
void M_Load_Draw_C (void);
void M_Save_Draw_C (void);
void M_FindKeysForCommand_C (char *command, int *twokeys);
void Bench486MenuTextDrawCharacter (int x, int y, int num);
void Bench486MenuTextDrawPic (int kind, int x, int y, qpic_t *pic,
		byte *translation);
qpic_t *Bench486MenuTextCachePic (char *path);
void Bench486MenuTextCases (void);
void Bench486MenuSearchNetPoll (void);
void Bench486MenuPictureCases (void);
void Bench486MenuTextBoxCases (void);
extern int bench486_menu_dispatch_fixture_active;
void Bench486MenuDispatchRecord (int event, int value);
void Bench486MenuDispatchSound (char *path);
void Bench486MenuDispatchCases (void);
#endif
#endif

#endif
