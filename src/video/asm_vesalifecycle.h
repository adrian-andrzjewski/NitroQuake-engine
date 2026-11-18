/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
#ifndef ASM_VESA_LIFECYCLE_H
#define ASM_VESA_LIFECYCLE_H

#ifndef __ASSEMBLER__
#include <dpmi.h>

extern byte *VID_extra_palette;
extern byte *VID_membase;
extern __dpmi_meminfo VID_extra_mapping;
extern qboolean VID_extra_mapped;
extern qboolean VID_extra_palette_ok;

void VID_ExtraReleaseMode_C (void);
void VID_ShutdownExtra_C (void);
qboolean VID_ExtraPaletteOK_C (void);

#if defined(BENCH486) && defined(ASM486_VESA_LIFECYCLE_FIXTURE)
void Bench486VesaLifecycleFreeMapping (void *mapping);
void Bench486VesaLifecycleFreeDosMemory (void *memory);
int Bench486VesaLifecycleCases (void);
#endif
#endif

#endif
