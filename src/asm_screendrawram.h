/* Structure contracts for screen.c:SCR_DrawRam. */
#ifndef ASM_SCREEN_DRAW_RAM_H
#define ASM_SCREEN_DRAW_RAM_H

#define SDR_CVAR_VALUE 16
#define SDR_VRECT_X 0
#define SDR_VRECT_Y 4
#define SDR_VRECT_SIZE 20

#ifndef __ASSEMBLER__
#include <float.h>
#include <stddef.h>

typedef char sdr_float_binary32_must_match[
		(sizeof(float) == 4 && FLT_RADIX == 2 && FLT_MANT_DIG == 24 &&
		FLT_MAX_EXP == 128) ? 1 : -1];
typedef char sdr_cvar_value_must_match[
		(offsetof(cvar_t, value) == SDR_CVAR_VALUE) ? 1 : -1];
typedef char sdr_vrect_x_must_match[
		(offsetof(vrect_t, x) == SDR_VRECT_X) ? 1 : -1];
typedef char sdr_vrect_y_must_match[
		(offsetof(vrect_t, y) == SDR_VRECT_Y) ? 1 : -1];
typedef char sdr_vrect_size_must_match[
		(sizeof(vrect_t) == SDR_VRECT_SIZE) ? 1 : -1];

#ifdef ASM486_SCREEN_DRAW_RAM
void SCR_DrawRam_asm486 (void);
#ifdef BENCH486
void SCR_DrawRam_Screen_C (void);
#endif
#endif

#endif

#endif /* ASM_SCREEN_DRAW_RAM_H */
