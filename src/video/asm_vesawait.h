/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
#ifndef ASM_VESA_WAIT_H
#define ASM_VESA_WAIT_H

#define VWA_CVAR_VALUE_OFFSET 16

#ifndef __ASSEMBLER__
#include <stddef.h>

typedef char vwa_cvar_value_must_match[
		(offsetof(cvar_t, value) == VWA_CVAR_VALUE_OFFSET) ? 1 : -1];

extern qboolean VID_extra_vsync_exists;
extern qboolean VID_extra_display_enable_exists;

void VID_ExtraWaitDisplayIfRequested_C (void);
void VID_ExtraWaitVsyncIfRequested_C (void);
int VID_ExtraDisplayStartWaitFlags_C (void);

#if defined(BENCH486) && defined(ASM486_VESA_WAIT_FIXTURE)
extern int bench486_vesa_wait_fixture_active;
void VID_ExtraWaitDisplayIfRequested (void);
void VID_ExtraWaitVsyncIfRequested (void);
int VID_ExtraDisplayStartWaitFlags (void);
int Bench486VesaWaitReadStatus (unsigned port);
int Bench486VesaWaitCases (void);
#endif
#endif

#endif
