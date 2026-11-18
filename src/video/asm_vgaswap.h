/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
#ifndef ASM_VGA_SWAP_H
#define ASM_VGA_SWAP_H

#define VGS_VID_BUFFER_OFFSET 0
#define VGS_VID_ROWBYTES_OFFSET 16
#define VGS_RECT_X_OFFSET 0
#define VGS_RECT_Y_OFFSET 4
#define VGS_RECT_WIDTH_OFFSET 8
#define VGS_RECT_HEIGHT_OFFSET 12
#define VGS_RECT_NEXT_OFFSET 16
#define VGS_CVAR_VALUE_OFFSET 16
#define VGS_VSYNC_VALUE 1
#define VGS_VSYNC_BITS 0x3f800000

#ifndef __ASSEMBLER__
#include <stddef.h>

typedef char vgs_vid_buffer_must_match[
	(offsetof(viddef_t, buffer) == VGS_VID_BUFFER_OFFSET) ? 1 : -1];
typedef char vgs_vid_rowbytes_must_match[
	(offsetof(viddef_t, rowbytes) == VGS_VID_ROWBYTES_OFFSET) ? 1 : -1];
typedef char vgs_rect_x_must_match[
	(offsetof(vrect_t, x) == VGS_RECT_X_OFFSET) ? 1 : -1];
typedef char vgs_rect_y_must_match[
	(offsetof(vrect_t, y) == VGS_RECT_Y_OFFSET) ? 1 : -1];
typedef char vgs_rect_width_must_match[
	(offsetof(vrect_t, width) == VGS_RECT_WIDTH_OFFSET) ? 1 : -1];
typedef char vgs_rect_height_must_match[
	(offsetof(vrect_t, height) == VGS_RECT_HEIGHT_OFFSET) ? 1 : -1];
typedef char vgs_rect_next_must_match[
	(offsetof(vrect_t, pnext) == VGS_RECT_NEXT_OFFSET) ? 1 : -1];
typedef char vgs_rect_size_must_match[(sizeof(vrect_t) == 20) ? 1 : -1];
typedef char vgs_cvar_value_must_match[
	(offsetof(cvar_t, value) == VGS_CVAR_VALUE_OFFSET) ? 1 : -1];

extern int VGA_planar;

void VGA_WaitVsync_C (void);
void VGA_SwapBuffersCopy_C (viddef_t *lvid, vmode_t *pcurrentmode,
		vrect_t *rects);
void VGA_SwapBuffers_C (viddef_t *lvid, vmode_t *pcurrentmode,
		vrect_t *rects);

#if defined(BENCH486) && defined(ASM486_VGA_PRESENTATION_FIXTURE)
int Bench486VgaPresentationCases (void);
#endif

#endif /* __ASSEMBLER__ */

#endif /* ASM_VGA_SWAP_H */
