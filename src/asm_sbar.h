#ifndef ASM_SBAR_H
#define ASM_SBAR_H

#define SBAR_CL_GAMETYPE_OFFSET 2688
#define SBAR_CL_MAXCLIENTS_OFFSET 2684
#define SBAR_CL_STATS_OFFSET 28
#define SBAR_CL_ITEMS_OFFSET 156
#define SBAR_VID_WIDTH_OFFSET 20
#define SBAR_VID_HEIGHT_OFFSET 24
#define SBAR_VID_NUMPAGES_OFFSET 32
#define SBAR_GAME_DEATHMATCH 1
#define SBAR_HEIGHT 24
#define SBAR_NUM_FRAMES 11
#define SBAR_NUM_COLOR_STRIDE 44
#define SBAR_STAT_HEALTH 0
#define SBAR_STAT_AMMO 3
#define SBAR_STAT_ARMOR 4
#define SBAR_IT_SHELLS 256
#define SBAR_IT_NAILS 512
#define SBAR_IT_ROCKETS 1024
#define SBAR_IT_CELLS 2048
#define SBAR_IT_ARMOR1 8192
#define SBAR_IT_ARMOR2 16384
#define SBAR_IT_ARMOR3 32768
#define SBAR_IT_KEY1 131072
#define SBAR_IT_KEY2 262144
#define SBAR_IT_INVULNERABILITY 1048576
#define SBAR_RIT_SHELLS 128
#define SBAR_RIT_NAILS 256
#define SBAR_RIT_ROCKETS 512
#define SBAR_RIT_CELLS 1024
#define SBAR_RIT_ARMOR1 8388608
#define SBAR_RIT_ARMOR2 16777216
#define SBAR_RIT_ARMOR3 33554432
#define SBAR_RIT_LAVA_NAILS 67108864
#define SBAR_RIT_PLASMA_AMMO 134217728
#define SBAR_RIT_MULTI_ROCKETS 268435456

#define SBAR_CAPTURE_PIC 1
#define SBAR_CAPTURE_TRANSPIC 2
#define SBAR_CAPTURE_CHARACTER 3
#define SBAR_CAPTURE_STRING 4

#ifndef __ASSEMBLER__
#include <stddef.h>

extern qpic_t *sb_nums[2][SBAR_NUM_FRAMES];

typedef char sbar_client_gametype_offset_must_match[
		(offsetof(client_state_t, gametype) == SBAR_CL_GAMETYPE_OFFSET) ? 1 : -1];
typedef char sbar_client_maxclients_offset_must_match[
		(offsetof(client_state_t, maxclients) == SBAR_CL_MAXCLIENTS_OFFSET) ? 1 : -1];
typedef char sbar_client_stats_offset_must_match[
		(offsetof(client_state_t, stats) == SBAR_CL_STATS_OFFSET) ? 1 : -1];
typedef char sbar_client_items_offset_must_match[
		(offsetof(client_state_t, items) == SBAR_CL_ITEMS_OFFSET) ? 1 : -1];
typedef char sbar_vid_width_offset_must_match[
		(offsetof(viddef_t, width) == SBAR_VID_WIDTH_OFFSET) ? 1 : -1];
typedef char sbar_vid_height_offset_must_match[
		(offsetof(viddef_t, height) == SBAR_VID_HEIGHT_OFFSET) ? 1 : -1];
typedef char sbar_vid_numpages_offset_must_match[
		(offsetof(viddef_t, numpages) == SBAR_VID_NUMPAGES_OFFSET) ? 1 : -1];
typedef char sbar_deathmatch_constant_must_match[
		(GAME_DEATHMATCH == SBAR_GAME_DEATHMATCH) ? 1 : -1];
typedef char sbar_stat_health_must_match[(STAT_HEALTH == SBAR_STAT_HEALTH) ? 1 : -1];
typedef char sbar_stat_ammo_must_match[(STAT_AMMO == SBAR_STAT_AMMO) ? 1 : -1];
typedef char sbar_stat_armor_must_match[(STAT_ARMOR == SBAR_STAT_ARMOR) ? 1 : -1];
typedef char sbar_it_shells_must_match[(IT_SHELLS == SBAR_IT_SHELLS) ? 1 : -1];
typedef char sbar_it_nails_must_match[(IT_NAILS == SBAR_IT_NAILS) ? 1 : -1];
typedef char sbar_it_rockets_must_match[(IT_ROCKETS == SBAR_IT_ROCKETS) ? 1 : -1];
typedef char sbar_it_cells_must_match[(IT_CELLS == SBAR_IT_CELLS) ? 1 : -1];
typedef char sbar_it_armor1_must_match[(IT_ARMOR1 == SBAR_IT_ARMOR1) ? 1 : -1];
typedef char sbar_it_armor2_must_match[(IT_ARMOR2 == SBAR_IT_ARMOR2) ? 1 : -1];
typedef char sbar_it_armor3_must_match[(IT_ARMOR3 == SBAR_IT_ARMOR3) ? 1 : -1];
typedef char sbar_it_key1_must_match[(IT_KEY1 == SBAR_IT_KEY1) ? 1 : -1];
typedef char sbar_it_key2_must_match[(IT_KEY2 == SBAR_IT_KEY2) ? 1 : -1];
typedef char sbar_it_invulnerability_must_match[
		(IT_INVULNERABILITY == SBAR_IT_INVULNERABILITY) ? 1 : -1];
typedef char sbar_rit_shells_must_match[(RIT_SHELLS == SBAR_RIT_SHELLS) ? 1 : -1];
typedef char sbar_rit_nails_must_match[(RIT_NAILS == SBAR_RIT_NAILS) ? 1 : -1];
typedef char sbar_rit_rockets_must_match[(RIT_ROCKETS == SBAR_RIT_ROCKETS) ? 1 : -1];
typedef char sbar_rit_cells_must_match[(RIT_CELLS == SBAR_RIT_CELLS) ? 1 : -1];
typedef char sbar_rit_armor1_must_match[(RIT_ARMOR1 == SBAR_RIT_ARMOR1) ? 1 : -1];
typedef char sbar_rit_armor2_must_match[(RIT_ARMOR2 == SBAR_RIT_ARMOR2) ? 1 : -1];
typedef char sbar_rit_armor3_must_match[(RIT_ARMOR3 == SBAR_RIT_ARMOR3) ? 1 : -1];
typedef char sbar_rit_lava_nails_must_match[
		(RIT_LAVA_NAILS == SBAR_RIT_LAVA_NAILS) ? 1 : -1];
typedef char sbar_rit_plasma_ammo_must_match[
		(RIT_PLASMA_AMMO == SBAR_RIT_PLASMA_AMMO) ? 1 : -1];
typedef char sbar_rit_multi_rockets_must_match[
		(RIT_MULTI_ROCKETS == SBAR_RIT_MULTI_ROCKETS) ? 1 : -1];
typedef char sbar_number_color_stride_must_match[
		(sizeof(sb_nums[0]) == SBAR_NUM_COLOR_STRIDE) ? 1 : -1];
typedef char sbar_pointer_size_must_match[(sizeof(void *) == 4) ? 1 : -1];

#if defined(BENCH486) && defined(ASM486_SBAR_DRAW)
void Sbar_Draw_C (void);
void Sbar_Draw_asm486 (void);
#endif
#if defined(BENCH486) && defined(ASM486_SBAR_DRAW_FIXTURE)
void Bench486SbarDrawTileClear (int x, int y, int width, int height);
void Bench486SbarDrawInventory (void);
void Bench486SbarDrawFrags (void);
void Bench486SbarDrawPic (int x, int y, qpic_t *pic);
void Bench486SbarDrawScoreboard (void);
void Bench486SbarDrawNum (int x, int y, int number, int digits, int color);
void Bench486SbarDrawFace (void);
void Bench486SbarDrawMiniDeathmatch (void);
#endif
#endif

#endif
