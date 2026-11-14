#ifndef ASM_VIDUPDATE_H
#define ASM_VIDUPDATE_H

#define VU_RECT_X_OFFSET 0
#define VU_RECT_Y_OFFSET 4
#define VU_RECT_WIDTH_OFFSET 8
#define VU_RECT_HEIGHT_OFFSET 12
#define VU_RECT_NEXT_OFFSET 16
#define VU_RECT_SIZE 20

#define VU_CVAR_VALUE_OFFSET 16
#define VU_VMODE_SWAPBUFFERS_OFFSET 44
#define VU_PROFILE_PRESENT 41

#ifndef __ASSEMBLER__
#include <stddef.h>

typedef char vu_rect_x_must_match[
	(offsetof(vrect_t, x) == VU_RECT_X_OFFSET) ? 1 : -1];
typedef char vu_rect_y_must_match[
	(offsetof(vrect_t, y) == VU_RECT_Y_OFFSET) ? 1 : -1];
typedef char vu_rect_width_must_match[
	(offsetof(vrect_t, width) == VU_RECT_WIDTH_OFFSET) ? 1 : -1];
typedef char vu_rect_height_must_match[
	(offsetof(vrect_t, height) == VU_RECT_HEIGHT_OFFSET) ? 1 : -1];
typedef char vu_rect_next_must_match[
	(offsetof(vrect_t, pnext) == VU_RECT_NEXT_OFFSET) ? 1 : -1];
typedef char vu_rect_size_must_match[
	(sizeof(vrect_t) == VU_RECT_SIZE) ? 1 : -1];
typedef char vu_cvar_value_must_match[
	(offsetof(cvar_t, value) == VU_CVAR_VALUE_OFFSET) ? 1 : -1];
typedef char vu_vmode_swapbuffers_must_match[
	(offsetof(vmode_t, swapbuffers) == VU_VMODE_SWAPBUFFERS_OFFSET) ? 1 : -1];

extern int vid_firstupdate;
extern qboolean vid_startup_mode_requested;
extern qboolean vid_nomodecheck;

void VID_Update_C (vrect_t *rects);
void VID_Update_asm486 (vrect_t *rects);

#if defined(BENCH486) && defined(ASM486_VID_UPDATE_FIXTURE)
int Bench486VidUpdateSetMode (int mode, unsigned char *palette);
int Bench486VidUpdateDefaultMode (void);
void Bench486VidUpdateSetValue (char *name, float value);
void Bench486VidUpdateNoVesaMessage (char *text);
int Bench486VidUpdateCases (void);
#endif

#if defined(PROFILE486)
typedef char vu_profile_present_must_match[
	(BENCH486_PROFILE_PRESENT == VU_PROFILE_PRESENT) ? 1 : -1];
#endif

#endif /* __ASSEMBLER__ */

#endif /* ASM_VIDUPDATE_H */
