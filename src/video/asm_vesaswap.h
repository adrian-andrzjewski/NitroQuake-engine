/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
#ifndef ASM_VESASWAP_H
#define ASM_VESASWAP_H

#define VS_VID_BUFFER_OFFSET 0
#define VS_VID_ROWBYTES_OFFSET 16
#define VS_VID_WIDTH_OFFSET 20
#define VS_VID_HEIGHT_OFFSET 24
#define VS_VID_NUMPAGES_OFFSET 32
#define VS_VID_CONBUFFER_OFFSET 40
#define VS_VID_DIRECT_OFFSET 64

#ifndef __ASSEMBLER__
#include <stddef.h>

typedef char vs_vid_buffer_must_match[
		(offsetof(viddef_t, buffer) == VS_VID_BUFFER_OFFSET) ? 1 : -1];
typedef char vs_vid_rowbytes_must_match[
		(offsetof(viddef_t, rowbytes) == VS_VID_ROWBYTES_OFFSET) ? 1 : -1];
typedef char vs_vid_width_must_match[
		(offsetof(viddef_t, width) == VS_VID_WIDTH_OFFSET) ? 1 : -1];
typedef char vs_vid_height_must_match[
		(offsetof(viddef_t, height) == VS_VID_HEIGHT_OFFSET) ? 1 : -1];
typedef char vs_vid_numpages_must_match[
		(offsetof(viddef_t, numpages) == VS_VID_NUMPAGES_OFFSET) ? 1 : -1];
typedef char vs_vid_conbuffer_must_match[
		(offsetof(viddef_t, conbuffer) == VS_VID_CONBUFFER_OFFSET) ? 1 : -1];
typedef char vs_vid_direct_must_match[
		(offsetof(viddef_t, direct) == VS_VID_DIRECT_OFFSET) ? 1 : -1];
typedef char vs_viddef_size_must_match[(sizeof(viddef_t) == 68) ? 1 : -1];

void VID_ExtraWaitDisplayIfRequested (void);
void VID_ExtraWaitVsyncIfRequested (void);
void VID_ExtraProbeWaitIfNeeded (vmode_t *mode);
int VID_ExtraDisplayStartWaitFlags (void);
void VID_ExtraSetDisplayStart (int x, int y, int waitflags);
void VID_ExtraCopyRects (vrect_t *rects, byte *srcbase, byte *dstbase,
		int vidwidth, int vidheight, int srcrowbytes, int destrowbytes);

#ifdef ASM486_VESA_SWAP_BUFFERS
void VID_ExtraSwapBuffers_ASM (viddef_t *lvid, vmode_t *mode,
		vrect_t *rects);
#endif

#if defined(BENCH486) && defined(ASM486_VESA_SWAP_BUFFERS_FIXTURE)
extern int bench486_vesa_swap_fixture_active;
int Bench486VesaSwapBuffersCases (void);
#endif

#endif /* __ASSEMBLER__ */

#endif /* ASM_VESASWAP_H */
