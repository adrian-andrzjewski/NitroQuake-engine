#ifndef ASM_FINDTOUCHEDLEAFS_H
#define ASM_FINDTOUCHEDLEAFS_H

#define FTL_NODE_CONTENTS 0
#define FTL_NODE_PLANE 24
#define FTL_NODE_CHILDREN 28
#define FTL_LEAF_SIZE 48
#define FTL_PLANE_DIST 12
#define FTL_PLANE_TYPE 16
#define FTL_EDICT_NUM_LEAFS 12
#define FTL_EDICT_LEAFNUMS 16
#define FTL_EDICT_ABSMIN 100
#define FTL_EDICT_ABSMAX 112
#define FTL_SERVER_WORLDMODEL 160
#define FTL_MODEL_LEAFS 140
#define FTL_MAX_LEAFS 16
#define FTL_CONTENTS_SOLID -2

#ifndef __ASSEMBLER__
#include <stddef.h>

void SV_FindTouchedLeafs(edict_t *ent, mnode_t *node);

#ifdef BENCH486
void SV_FindTouchedLeafs_C(edict_t *ent, mnode_t *node);
extern unsigned bench486_findtouchedleafs_asm_calls;
#endif

typedef char ftl_pointer_size_must_match[(sizeof(void *) == 4U) ? 1 : -1];
typedef char ftl_short_size_must_match[(sizeof(short) == 2U) ? 1 : -1];
typedef char ftl_node_size_must_match[(sizeof(mnode_t) == 40U) ? 1 : -1];
typedef char ftl_node_contents_offset_must_match[(offsetof(mnode_t, contents) == FTL_NODE_CONTENTS) ? 1 : -1];
typedef char ftl_node_plane_offset_must_match[(offsetof(mnode_t, plane) == FTL_NODE_PLANE) ? 1 : -1];
typedef char ftl_node_children_offset_must_match[(offsetof(mnode_t, children) == FTL_NODE_CHILDREN) ? 1 : -1];
typedef char ftl_leaf_size_must_match[(sizeof(mleaf_t) == FTL_LEAF_SIZE) ? 1 : -1];
typedef char ftl_plane_size_must_match[(sizeof(mplane_t) == 20U) ? 1 : -1];
typedef char ftl_plane_dist_offset_must_match[(offsetof(mplane_t, dist) == FTL_PLANE_DIST) ? 1 : -1];
typedef char ftl_plane_type_offset_must_match[(offsetof(mplane_t, type) == FTL_PLANE_TYPE) ? 1 : -1];
typedef char ftl_edict_num_leafs_offset_must_match[(offsetof(edict_t, num_leafs) == FTL_EDICT_NUM_LEAFS) ? 1 : -1];
typedef char ftl_edict_leafnums_offset_must_match[(offsetof(edict_t, leafnums) == FTL_EDICT_LEAFNUMS) ? 1 : -1];
typedef char ftl_edict_absmin_offset_must_match[(offsetof(edict_t, v) + offsetof(entvars_t, absmin) == FTL_EDICT_ABSMIN) ? 1 : -1];
typedef char ftl_edict_absmax_offset_must_match[(offsetof(edict_t, v) + offsetof(entvars_t, absmax) == FTL_EDICT_ABSMAX) ? 1 : -1];
typedef char ftl_server_worldmodel_offset_must_match[(offsetof(server_t, worldmodel) == FTL_SERVER_WORLDMODEL) ? 1 : -1];
typedef char ftl_model_leafs_offset_must_match[(offsetof(model_t, leafs) == FTL_MODEL_LEAFS) ? 1 : -1];
typedef char ftl_max_leafs_must_match[(MAX_ENT_LEAFS == FTL_MAX_LEAFS) ? 1 : -1];
typedef char ftl_contents_solid_must_match[(CONTENTS_SOLID == FTL_CONTENTS_SOLID) ? 1 : -1];
#endif

#endif
