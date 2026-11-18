/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
#ifndef ASM_HULL_FOR_ENTITY_H
#define ASM_HULL_FOR_ENTITY_H

#ifndef __ASSEMBLER__
#include <stddef.h>

hull_t *SV_HullForBox(vec3_t, vec3_t);
hull_t *SV_HullForEntity(edict_t *, vec3_t, vec3_t, vec3_t);

extern hull_t box_hull;
extern dclipnode_t box_clipnodes[6];
extern mplane_t box_planes[6];

#ifdef BENCH486
hull_t *SV_HullForBox_C(vec3_t, vec3_t);
hull_t *SV_HullForEntity_C(edict_t *, vec3_t, vec3_t, vec3_t);
extern unsigned bench486_hullforentity_dispatch_asm;
extern unsigned bench486_hullforbox_asm_calls;
extern unsigned bench486_hullforentity_asm_calls;
#endif

typedef char hfe_pointer_size_must_match[(sizeof(void *) == 4U) ? 1 : -1];
typedef char hfe_float_size_must_match[(sizeof(float) == 4U) ? 1 : -1];
typedef char hfe_integer_size_must_match[(sizeof(int) == 4U) ? 1 : -1];
typedef char hfe_server_models_offset_must_match[(offsetof(server_t, models) == 1188U) ? 1 : -1];
typedef char hfe_edict_v_offset_must_match[(offsetof(edict_t, v) == 96U) ? 1 : -1];
typedef char hfe_edict_modelindex_offset_must_match[(offsetof(edict_t, v) + offsetof(entvars_t, modelindex) == 96U) ? 1 : -1];
typedef char hfe_edict_movetype_offset_must_match[(offsetof(edict_t, v) + offsetof(entvars_t, movetype) == 128U) ? 1 : -1];
typedef char hfe_edict_solid_offset_must_match[(offsetof(edict_t, v) + offsetof(entvars_t, solid) == 132U) ? 1 : -1];
typedef char hfe_edict_origin_offset_must_match[(offsetof(edict_t, v) + offsetof(entvars_t, origin) == 136U) ? 1 : -1];
typedef char hfe_edict_mins_offset_must_match[(offsetof(edict_t, v) + offsetof(entvars_t, mins) == 228U) ? 1 : -1];
typedef char hfe_edict_maxs_offset_must_match[(offsetof(edict_t, v) + offsetof(entvars_t, maxs) == 240U) ? 1 : -1];
typedef char hfe_model_size_must_match[(sizeof(model_t) == 392U) ? 1 : -1];
typedef char hfe_model_type_offset_must_match[(offsetof(model_t, type) == 68U) ? 1 : -1];
typedef char hfe_model_hulls_offset_must_match[(offsetof(model_t, hulls) == 208U) ? 1 : -1];
typedef char hfe_hull_size_must_match[(sizeof(hull_t) == 40U) ? 1 : -1];
typedef char hfe_hull_clip_mins_offset_must_match[(offsetof(hull_t, clip_mins) == 16U) ? 1 : -1];
typedef char hfe_mplane_dist_offset_must_match[(offsetof(mplane_t, dist) == 12U) ? 1 : -1];
typedef char hfe_mplane_size_must_match[(sizeof(mplane_t) == 20U) ? 1 : -1];
typedef char hfe_box_node_count_must_match[(sizeof(box_clipnodes) == 48U) ? 1 : -1];
typedef char hfe_box_plane_count_must_match[(sizeof(box_planes) == 120U) ? 1 : -1];
typedef char hfe_solid_bsp_value_must_match[(SOLID_BSP == 4) ? 1 : -1];
typedef char hfe_movetype_push_value_must_match[(MOVETYPE_PUSH == 7) ? 1 : -1];
typedef char hfe_mod_brush_value_must_match[(mod_brush == 0) ? 1 : -1];
#endif

#endif
