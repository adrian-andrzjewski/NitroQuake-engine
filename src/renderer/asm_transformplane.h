/* C/assembly layout contract for R_TransformPlane. */
/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
#ifndef ASM_TRANSFORMPLANE_H
#define ASM_TRANSFORMPLANE_H

#include "asm_i386.h"

#define TP_PLANE_NORMAL 0
#define TP_PLANE_DIST   12
#define TP_PLANE_SIZE   20

#ifndef __ASSEMBLER__
#if id386 && (defined(ASM486_TRANSFORM_PLANE) || defined(BENCH486))
#include <stddef.h>
typedef char tp_pointer_size_must_match[(sizeof(void *) == 4U) ? 1 : -1];
typedef char tp_float_size_must_match[(sizeof(float) == 4U) ? 1 : -1];
typedef char tp_plane_size_must_match[(sizeof(mplane_t) == TP_PLANE_SIZE) ? 1 : -1];
typedef char tp_plane_normal_must_match[
		(offsetof(mplane_t, normal) == TP_PLANE_NORMAL) ? 1 : -1];
typedef char tp_plane_dist_must_match[
		(offsetof(mplane_t, dist) == TP_PLANE_DIST) ? 1 : -1];

void R_TransformPlane_asm486 (mplane_t *p, float *normal, float *dist);
#if defined(BENCH486) && defined(ASM486_TRANSFORM_PLANE)
void R_TransformPlane_C (mplane_t *p, float *normal, float *dist);
#endif
#endif
#endif /* !__ASSEMBLER__ */

#endif /* ASM_TRANSFORMPLANE_H */
