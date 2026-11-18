/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
#ifndef ASM_VIDMODE_H
#define ASM_VIDMODE_H

#define VM_MODE_NEXT_OFFSET 0
#define VM_MODE_NAME_OFFSET 4
#define VM_MODE_HEADER_OFFSET 8
#define VM_MODE_WIDTH_OFFSET 12
#define VM_MODE_HEIGHT_OFFSET 16
#define VM_MODE_ASPECT_OFFSET 20
#define VM_MODE_ROWBYTES_OFFSET 24
#define VM_MODE_SETMODE_OFFSET 40
#define VM_MODE_SETPALETTE_OFFSET 48
#define VM_MODE_SIZE 60

#define VM_VID_ROWBYTES_OFFSET 16
#define VM_VID_WIDTH_OFFSET 20
#define VM_VID_HEIGHT_OFFSET 24
#define VM_VID_ASPECT_OFFSET 28
#define VM_VID_RECALC_REFDEF_OFFSET 36
#define VM_VID_DIRECT_OFFSET 64
#define VM_REG_AX_OFFSET 28

#ifndef __ASSEMBLER__
#include <stddef.h>
#include "platform/dos/dosisms.h"

typedef char vm_pointer_size_must_match[(sizeof(void *) == 4) ? 1 : -1];
typedef char vm_mode_next_must_match[
	(offsetof(vmode_t, pnext) == VM_MODE_NEXT_OFFSET) ? 1 : -1];
typedef char vm_mode_name_must_match[
	(offsetof(vmode_t, name) == VM_MODE_NAME_OFFSET) ? 1 : -1];
typedef char vm_mode_header_must_match[
	(offsetof(vmode_t, header) == VM_MODE_HEADER_OFFSET) ? 1 : -1];
typedef char vm_mode_width_must_match[
	(offsetof(vmode_t, width) == VM_MODE_WIDTH_OFFSET) ? 1 : -1];
typedef char vm_mode_height_must_match[
	(offsetof(vmode_t, height) == VM_MODE_HEIGHT_OFFSET) ? 1 : -1];
typedef char vm_mode_aspect_must_match[
	(offsetof(vmode_t, aspect) == VM_MODE_ASPECT_OFFSET) ? 1 : -1];
typedef char vm_mode_rowbytes_must_match[
	(offsetof(vmode_t, rowbytes) == VM_MODE_ROWBYTES_OFFSET) ? 1 : -1];
typedef char vm_mode_setmode_must_match[
	(offsetof(vmode_t, setmode) == VM_MODE_SETMODE_OFFSET) ? 1 : -1];
typedef char vm_mode_setpalette_must_match[
	(offsetof(vmode_t, setpalette) == VM_MODE_SETPALETTE_OFFSET) ? 1 : -1];
typedef char vm_mode_size_must_match[
	(sizeof(vmode_t) == VM_MODE_SIZE) ? 1 : -1];
typedef char vm_vid_rowbytes_must_match[
	(offsetof(viddef_t, rowbytes) == VM_VID_ROWBYTES_OFFSET) ? 1 : -1];
typedef char vm_vid_width_must_match[
	(offsetof(viddef_t, width) == VM_VID_WIDTH_OFFSET) ? 1 : -1];
typedef char vm_vid_height_must_match[
	(offsetof(viddef_t, height) == VM_VID_HEIGHT_OFFSET) ? 1 : -1];
typedef char vm_vid_aspect_must_match[
	(offsetof(viddef_t, aspect) == VM_VID_ASPECT_OFFSET) ? 1 : -1];
typedef char vm_vid_recalc_refdef_must_match[
	(offsetof(viddef_t, recalc_refdef) == VM_VID_RECALC_REFDEF_OFFSET) ? 1 : -1];
typedef char vm_vid_direct_must_match[
	(offsetof(viddef_t, direct) == VM_VID_DIRECT_OFFSET) ? 1 : -1];
typedef char vm_regs_ax_must_match[
	(offsetof(regs_t, x.ax) == VM_REG_AX_OFFSET) ? 1 : -1];

#if defined(BENCH486) && defined(ASM486_VID_UPDATE)
vmode_t *VID_GetModePtr_C (int modenum);
char *VID_ModeInfo_C (int modenum, char **ppheader);
int VID_SetMode_C (int modenum, unsigned char *palette);
void VID_SetPalette_C (unsigned char *palette);
void VID_ShiftPalette_C (unsigned char *palette);
void VID_Shutdown_C (void);
#endif

#if defined(BENCH486) && defined(ASM486_VID_UPDATE_FIXTURE)
void Bench486VidModeSetValue (char *name, float value);
void Bench486VidModePrintf (char *format, ...);
void Bench486VidModeError (char *text);
void Bench486VidModeReleaseExtra (void);
int Bench486VidModePaletteOK (void);
int Bench486VidShutdownInt86 (int vector);
void Bench486VidShutdownExtra (void);
int Bench486VidModeCases (void);
#endif
#endif

#endif
