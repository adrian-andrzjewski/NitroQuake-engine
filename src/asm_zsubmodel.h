/* Layout contract for R_ZDrawSubmodelPolys_asm486. */
#ifndef ASM_ZSUBMODEL_H
#define ASM_ZSUBMODEL_H

#define ZSP_MODEL_FIRSTSURFACE 112
#define ZSP_MODEL_NUMSURFACES 116
#define ZSP_MODEL_SURFACES 180
#define ZSP_SURFACE_PLANE 12
#define ZSP_SURFACE_FLAGS 16
#define ZSP_SURFACE_SIZE 64
#define ZSP_PLANE_NORMAL 0
#define ZSP_PLANE_DIST 12

#ifndef __ASSEMBLER__
#include <stddef.h>

typedef char zsp_pointer_size_must_match[(sizeof(void *) == 4U) ? 1 : -1];
typedef char zsp_integer_size_must_match[(sizeof(int) == 4U) ? 1 : -1];
typedef char zsp_float_size_must_match[(sizeof(float) == 4U) ? 1 : -1];
typedef char zsp_model_firstsurface_must_match[
		(offsetof(model_t, firstmodelsurface) == ZSP_MODEL_FIRSTSURFACE) ? 1 : -1];
typedef char zsp_model_numsurfaces_must_match[
		(offsetof(model_t, nummodelsurfaces) == ZSP_MODEL_NUMSURFACES) ? 1 : -1];
typedef char zsp_model_surfaces_must_match[
		(offsetof(model_t, surfaces) == ZSP_MODEL_SURFACES) ? 1 : -1];
typedef char zsp_surface_plane_must_match[
		(offsetof(msurface_t, plane) == ZSP_SURFACE_PLANE) ? 1 : -1];
typedef char zsp_surface_flags_must_match[
		(offsetof(msurface_t, flags) == ZSP_SURFACE_FLAGS) ? 1 : -1];
typedef char zsp_surface_size_must_match[
		(sizeof(msurface_t) == ZSP_SURFACE_SIZE) ? 1 : -1];
typedef char zsp_plane_normal_must_match[
		(offsetof(mplane_t, normal) == ZSP_PLANE_NORMAL) ? 1 : -1];
typedef char zsp_plane_dist_must_match[
		(offsetof(mplane_t, dist) == ZSP_PLANE_DIST) ? 1 : -1];
typedef char zsp_planeback_must_match[(SURF_PLANEBACK == 2) ? 1 : -1];

#if defined(BENCH486) && defined(ASM486_DRAW_Z_SUBMODEL_POLYS)
extern void (*bench486_zsubmodel_render_hook)(msurface_t *surface,
		int clipflags);
void R_ZDrawSubmodelPolys_C(model_t *pmodel);
#endif
#endif /* !__ASSEMBLER__ */
#endif /* ASM_ZSUBMODEL_H */
