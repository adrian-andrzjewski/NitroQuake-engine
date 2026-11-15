/* Layout and constants shared by the console scrollback resize routine. */
#ifndef ASM_CONSOLE_CHECK_RESIZE_H
#define ASM_CONSOLE_CHECK_RESIZE_H

#define ccr_vid_width_offset 20
#define ccr_textsize 16384
#define ccr_notify_count 4

#ifndef __ASSEMBLER__
#include <stddef.h>

typedef char ccr_486_data_model_must_match[
	(sizeof(void *) == 4 && sizeof(int) == 4 && sizeof(float) == 4) ? 1 : -1];
typedef char ccr_vid_width_offset_must_match[
	(offsetof(viddef_t, width) == ccr_vid_width_offset) ? 1 : -1];

#endif

#endif
