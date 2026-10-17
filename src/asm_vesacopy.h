#ifndef ASM_VESACOPY_H
#define ASM_VESACOPY_H

#define VC_RECT_X_OFFSET 0
#define VC_RECT_Y_OFFSET 4
#define VC_RECT_WIDTH_OFFSET 8
#define VC_RECT_HEIGHT_OFFSET 12
#define VC_RECT_NEXT_OFFSET 16
#define VC_RECT_SIZE 20

#ifndef __ASSEMBLER__
#include <stddef.h>

typedef char vc_rect_x_must_match[
		(offsetof(vrect_t, x) == VC_RECT_X_OFFSET) ? 1 : -1];
typedef char vc_rect_y_must_match[
		(offsetof(vrect_t, y) == VC_RECT_Y_OFFSET) ? 1 : -1];
typedef char vc_rect_width_must_match[
		(offsetof(vrect_t, width) == VC_RECT_WIDTH_OFFSET) ? 1 : -1];
typedef char vc_rect_height_must_match[
		(offsetof(vrect_t, height) == VC_RECT_HEIGHT_OFFSET) ? 1 : -1];
typedef char vc_rect_next_must_match[
		(offsetof(vrect_t, pnext) == VC_RECT_NEXT_OFFSET) ? 1 : -1];
typedef char vc_rect_size_must_match[
		(sizeof(vrect_t) == VC_RECT_SIZE) ? 1 : -1];

#endif

#endif
