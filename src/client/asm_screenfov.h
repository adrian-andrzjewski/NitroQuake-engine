/* Assembly entry and benchmark oracle for screen.c:CalcFov. */
/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
#ifndef ASM_SCREEN_FOV_H
#define ASM_SCREEN_FOV_H

#ifndef __ASSEMBLER__
float CalcFov_asm486 (float fov_x, float width, float height);

#ifdef BENCH486
float CalcFov_C (float fov_x, float width, float height);
void Bench486CalcFovSysError (const char *message, double value);
extern unsigned bench486_calcfov_error_calls;
extern const char *bench486_calcfov_error_message;
extern unsigned bench486_calcfov_error_bits[2];
#endif
#endif

#endif
