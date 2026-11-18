/* Layout and cdecl contract for the view-frustum transform/index assembly. */
/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
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
#define FR_INDEX_PLANES 4
#define FR_INDEX_AXES 3
#define FR_INDEX_HALF 3
#define FR_INDEX_HALF_OFFSET 12
#define FR_INDEX_STRIDE 24

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
typedef char fr_clipplane_count_must_match[(sizeof(view_clipplanes) / sizeof(view_clipplanes[0]) == FR_INDEX_PLANES) ? 1 : -1];
typedef char fr_index_table_size_must_match[(sizeof(r_frustum_indexes) / sizeof(r_frustum_indexes[0]) == FR_INDEX_PLANES * FR_INDEX_AXES * 2) ? 1 : -1];
typedef char fr_index_pointer_table_size_must_match[(sizeof(pfrustum_indexes) / sizeof(pfrustum_indexes[0]) == FR_INDEX_PLANES) ? 1 : -1];

void R_TransformFrustumCore_asm486 (const mplane_t *screen,
		clipplane_t *clip, const float *origin, const float *forward,
		const float *right, const float *up);
void R_SetUpFrustumIndexes (void);
#ifdef BENCH486
void R_TransformFrustumCore_C (const mplane_t *screen, clipplane_t *clip,
		const float *origin, const float *forward, const float *right,
		const float *up);
void R_TransformFrustum_C (void);
void R_SetUpFrustumIndexes_C (void);
#endif
#endif
#endif
