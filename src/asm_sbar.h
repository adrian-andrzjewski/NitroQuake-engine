#ifndef ASM_SBAR_H
#define ASM_SBAR_H

#define SBAR_CL_GAMETYPE_OFFSET 2688
#define SBAR_VID_WIDTH_OFFSET 20
#define SBAR_VID_HEIGHT_OFFSET 24
#define SBAR_GAME_DEATHMATCH 1
#define SBAR_HEIGHT 24
#define SBAR_NUM_FRAMES 11
#define SBAR_NUM_COLOR_STRIDE 44

#define SBAR_CAPTURE_PIC 1
#define SBAR_CAPTURE_TRANSPIC 2
#define SBAR_CAPTURE_CHARACTER 3
#define SBAR_CAPTURE_STRING 4

#ifndef __ASSEMBLER__
#include <stddef.h>

extern qpic_t *sb_nums[2][SBAR_NUM_FRAMES];

typedef char sbar_client_gametype_offset_must_match[
		(offsetof(client_state_t, gametype) == SBAR_CL_GAMETYPE_OFFSET) ? 1 : -1];
typedef char sbar_vid_width_offset_must_match[
		(offsetof(viddef_t, width) == SBAR_VID_WIDTH_OFFSET) ? 1 : -1];
typedef char sbar_vid_height_offset_must_match[
		(offsetof(viddef_t, height) == SBAR_VID_HEIGHT_OFFSET) ? 1 : -1];
typedef char sbar_deathmatch_constant_must_match[
		(GAME_DEATHMATCH == SBAR_GAME_DEATHMATCH) ? 1 : -1];
typedef char sbar_number_color_stride_must_match[
		(sizeof(sb_nums[0]) == SBAR_NUM_COLOR_STRIDE) ? 1 : -1];
typedef char sbar_pointer_size_must_match[(sizeof(void *) == 4) ? 1 : -1];
#endif

#endif
