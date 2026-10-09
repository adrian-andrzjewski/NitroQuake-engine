/* Layout and cdecl contract for the view-frustum transform assembly. */
#ifndef ASM_FRUSTUM_H
#define ASM_FRUSTUM_H

#define FR_SCREEN_NORMAL_X 0
#define FR_SCREEN_NORMAL_Y 4
#define FR_SCREEN_NORMAL_Z 8
#define FR_SCREEN_STRIDE 20

#define FR_CLIP_NORMAL_X 0
#define FR_CLIP_NORMAL_Y 4
#define FR_CLIP_NORMAL_Z 8
#define FR_CLIP_DIST 12
#define FR_CLIP_STRIDE 24

#ifndef __ASSEMBLER__
#include <stddef.h>
typedef char fr_pointer_size_must_match[(sizeof(void *) == 4U) ? 1 : -1];
typedef char fr_float_size_must_match[(sizeof(float) == 4U) ? 1 : -1];
typedef char fr_mplane_size_must_match[(sizeof(mplane_t) == FR_SCREEN_STRIDE) ? 1 : -1];
typedef char fr_mplane_normal_must_match[(offsetof(mplane_t, normal) == FR_SCREEN_NORMAL_X) ? 1 : -1];
typedef char fr_mplane_dist_must_match[(offsetof(mplane_t, dist) == 12U) ? 1 : -1];
typedef char fr_clipplane_size_must_match[(sizeof(clipplane_t) == FR_CLIP_STRIDE) ? 1 : -1];
typedef char fr_clipplane_normal_must_match[(offsetof(clipplane_t, normal) == FR_CLIP_NORMAL_X) ? 1 : -1];
typedef char fr_clipplane_dist_must_match[(offsetof(clipplane_t, dist) == FR_CLIP_DIST) ? 1 : -1];

void R_TransformFrustumCore_asm486 (const mplane_t *screen,
		clipplane_t *clip, const float *origin, const float *forward,
		const float *right, const float *up);
#ifdef BENCH486
void R_TransformFrustumCore_C (const mplane_t *screen, clipplane_t *clip,
		const float *origin, const float *forward, const float *right,
		const float *up);
void R_TransformFrustum_C (void);
#endif
#endif
#endif
