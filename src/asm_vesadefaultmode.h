#ifndef ASM_VESADEFAULTMODE_H
#define ASM_VESADEFAULTMODE_H

#define VD_MODE_NEXT_OFFSET 0
#define VD_MODE_WIDTH_OFFSET 12
#define VD_MODE_HEIGHT_OFFSET 16
#define VD_MODE_PEXTRADATA_OFFSET 36
#define VD_MODE_SETMODE_OFFSET 40
#define VD_INFO_LINEAR_OFFSET 40

#ifndef __ASSEMBLER__
#include <stddef.h>

typedef char vd_mode_next_must_match[
		(offsetof(vmode_t, pnext) == VD_MODE_NEXT_OFFSET) ? 1 : -1];
typedef char vd_mode_width_must_match[
		(offsetof(vmode_t, width) == VD_MODE_WIDTH_OFFSET) ? 1 : -1];
typedef char vd_mode_height_must_match[
		(offsetof(vmode_t, height) == VD_MODE_HEIGHT_OFFSET) ? 1 : -1];
typedef char vd_mode_extradata_must_match[
		(offsetof(vmode_t, pextradata) == VD_MODE_PEXTRADATA_OFFSET) ? 1 : -1];
typedef char vd_mode_setmode_must_match[
		(offsetof(vmode_t, setmode) == VD_MODE_SETMODE_OFFSET) ? 1 : -1];
typedef char vd_mode_size_must_match[(sizeof(vmode_t) == 60) ? 1 : -1];
typedef char vd_info_linear_must_match[
		(offsetof(vesa_info_t, linear) == VD_INFO_LINEAR_OFFSET) ? 1 : -1];
typedef char vd_info_size_must_match[(sizeof(vesa_info_t) == 44) ? 1 : -1];

int VID_SelectVesaDefaultMode_C (vmode_t *modes,
		int (*setmode)(viddef_t *vid, vmode_t *mode));
int VID_SelectVesaDefaultMode_asm486 (vmode_t *modes,
		int (*setmode)(viddef_t *vid, vmode_t *mode));
int VID_ExtraDefaultMode_C (void);
int VID_ExtraInitMode (viddef_t *vid, vmode_t *mode);

#if defined(BENCH486) && defined(ASM486_VESA_DEFAULT_MODE_FIXTURE)
unsigned Bench486Call_asm486 (void (*function)(void), unsigned words,
		const unsigned *arguments, float *return_value);
#endif
#endif

#endif
