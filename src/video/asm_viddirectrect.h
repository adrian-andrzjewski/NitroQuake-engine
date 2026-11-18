/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
#ifndef ASM_VIDDIRECTRECT_H
#define ASM_VIDDIRECTRECT_H

#define VD_VID_ASPECT_OFFSET 28
#define VD_VID_DIRECT_OFFSET 64
#define VD_MODE_PLANAR_OFFSET 28
#define VD_MODE_BEGIN_DIRECTRECT_OFFSET 52
#define VD_MODE_END_DIRECTRECT_OFFSET 56
#define VD_MODE_SIZE 60
#define VD_BACKINGBUF_SIZE (48 * 24)

#ifndef __ASSEMBLER__
#include <stddef.h>

typedef char vd_pointer_size_must_match[(sizeof(void *) == 4) ? 1 : -1];
typedef char vd_vid_aspect_must_match[
	(offsetof(viddef_t, aspect) == VD_VID_ASPECT_OFFSET) ? 1 : -1];
typedef char vd_vid_direct_must_match[
	(offsetof(viddef_t, direct) == VD_VID_DIRECT_OFFSET) ? 1 : -1];
typedef char vd_mode_planar_must_match[
	(offsetof(vmode_t, planar) == VD_MODE_PLANAR_OFFSET) ? 1 : -1];
typedef char vd_mode_begin_directrect_must_match[
	(offsetof(vmode_t, begindirectrect) ==
	 VD_MODE_BEGIN_DIRECTRECT_OFFSET) ? 1 : -1];
typedef char vd_mode_end_directrect_must_match[
	(offsetof(vmode_t, enddirectrect) ==
	 VD_MODE_END_DIRECTRECT_OFFSET) ? 1 : -1];
typedef char vd_mode_size_must_match[
	(sizeof(vmode_t) == VD_MODE_SIZE) ? 1 : -1];
#endif

#endif
