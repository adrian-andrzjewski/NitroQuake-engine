/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
#ifndef ASM_CLIPLINKS_H
#define ASM_CLIPLINKS_H

#define ACL_NODE_AXIS 0
#define ACL_NODE_DIST 4
#define ACL_NODE_CHILDREN 8
#define ACL_NODE_SOLID_EDICTS 24
#define ACL_NODE_SOLID_NEXT 28
#define ACL_LINK_PREV 0
#define ACL_LINK_NEXT 4

#define ACL_MOVECLIP_BOXMINS 0
#define ACL_MOVECLIP_BOXMAXS 12
#define ACL_MOVECLIP_MINS 24
#define ACL_MOVECLIP_MAXS 28
#define ACL_MOVECLIP_MINS2 32
#define ACL_MOVECLIP_MAXS2 44
#define ACL_MOVECLIP_START 56
#define ACL_MOVECLIP_END 60
#define ACL_MOVECLIP_TRACE 64
#define ACL_MOVECLIP_TYPE 116
#define ACL_MOVECLIP_PASSEDICT 120
#define ACL_MOVECLIP_SIZE 124

#define ACL_EDICT_AREA 4
#define ACL_EDICT_SOLID 132
#define ACL_EDICT_ABSMIN 100
#define ACL_EDICT_ABSMAX 112
#define ACL_EDICT_SIZE 252
#define ACL_EDICT_FLAGS 400
#define ACL_EDICT_OWNER 476
#define ACL_SERVER_EDICTS 3500

#ifndef __ASSEMBLER__
#include <stddef.h>

typedef struct areanode_s
{
	int axis;
	float dist;
	struct areanode_s *children[2];
	link_t trigger_edicts;
	link_t solid_edicts;
} areanode_t;

typedef struct
{
	vec3_t boxmins, boxmaxs;
	float *mins, *maxs;
	vec3_t mins2, maxs2;
	float *start, *end;
	trace_t trace;
	int type;
	edict_t *passedict;
} moveclip_t;

void SV_ClipToLinks(areanode_t *node, moveclip_t *clip);

#ifdef BENCH486
void SV_ClipToLinks_C(areanode_t *node, moveclip_t *clip);
extern unsigned bench486_cliptolinks_asm_calls;
#endif

typedef char acl_pointer_size_must_match[(sizeof(void *) == 4U) ? 1 : -1];
typedef char acl_node_size_must_match[(sizeof(areanode_t) == 32U) ? 1 : -1];
typedef char acl_node_axis_offset_must_match[(offsetof(areanode_t, axis) == ACL_NODE_AXIS) ? 1 : -1];
typedef char acl_node_dist_offset_must_match[(offsetof(areanode_t, dist) == ACL_NODE_DIST) ? 1 : -1];
typedef char acl_node_children_offset_must_match[(offsetof(areanode_t, children) == ACL_NODE_CHILDREN) ? 1 : -1];
typedef char acl_node_solid_offset_must_match[(offsetof(areanode_t, solid_edicts) == ACL_NODE_SOLID_EDICTS) ? 1 : -1];
typedef char acl_link_prev_offset_must_match[(offsetof(link_t, prev) == ACL_LINK_PREV) ? 1 : -1];
typedef char acl_link_next_offset_must_match[(offsetof(link_t, next) == ACL_LINK_NEXT) ? 1 : -1];
typedef char acl_trace_size_must_match[(sizeof(trace_t) == 52U) ? 1 : -1];
typedef char acl_trace_fraction_offset_must_match[(offsetof(trace_t, fraction) == 16U) ? 1 : -1];
typedef char acl_trace_ent_offset_must_match[(offsetof(trace_t, ent) == 48U) ? 1 : -1];
typedef char acl_moveclip_size_must_match[(sizeof(moveclip_t) == ACL_MOVECLIP_SIZE) ? 1 : -1];
typedef char acl_moveclip_boxmins_offset_must_match[(offsetof(moveclip_t, boxmins) == ACL_MOVECLIP_BOXMINS) ? 1 : -1];
typedef char acl_moveclip_boxmaxs_offset_must_match[(offsetof(moveclip_t, boxmaxs) == ACL_MOVECLIP_BOXMAXS) ? 1 : -1];
typedef char acl_moveclip_mins_offset_must_match[(offsetof(moveclip_t, mins) == ACL_MOVECLIP_MINS) ? 1 : -1];
typedef char acl_moveclip_maxs_offset_must_match[(offsetof(moveclip_t, maxs) == ACL_MOVECLIP_MAXS) ? 1 : -1];
typedef char acl_moveclip_mins2_offset_must_match[(offsetof(moveclip_t, mins2) == ACL_MOVECLIP_MINS2) ? 1 : -1];
typedef char acl_moveclip_maxs2_offset_must_match[(offsetof(moveclip_t, maxs2) == ACL_MOVECLIP_MAXS2) ? 1 : -1];
typedef char acl_moveclip_start_offset_must_match[(offsetof(moveclip_t, start) == ACL_MOVECLIP_START) ? 1 : -1];
typedef char acl_moveclip_end_offset_must_match[(offsetof(moveclip_t, end) == ACL_MOVECLIP_END) ? 1 : -1];
typedef char acl_moveclip_trace_offset_must_match[(offsetof(moveclip_t, trace) == ACL_MOVECLIP_TRACE) ? 1 : -1];
typedef char acl_moveclip_type_offset_must_match[(offsetof(moveclip_t, type) == ACL_MOVECLIP_TYPE) ? 1 : -1];
typedef char acl_moveclip_passedict_offset_must_match[(offsetof(moveclip_t, passedict) == ACL_MOVECLIP_PASSEDICT) ? 1 : -1];
typedef char acl_edict_area_offset_must_match[(offsetof(edict_t, area) == ACL_EDICT_AREA) ? 1 : -1];
typedef char acl_edict_solid_offset_must_match[(offsetof(edict_t, v) + offsetof(entvars_t, solid) == ACL_EDICT_SOLID) ? 1 : -1];
typedef char acl_edict_absmin_offset_must_match[(offsetof(edict_t, v) + offsetof(entvars_t, absmin) == ACL_EDICT_ABSMIN) ? 1 : -1];
typedef char acl_edict_absmax_offset_must_match[(offsetof(edict_t, v) + offsetof(entvars_t, absmax) == ACL_EDICT_ABSMAX) ? 1 : -1];
typedef char acl_edict_size_offset_must_match[(offsetof(edict_t, v) + offsetof(entvars_t, size) == ACL_EDICT_SIZE) ? 1 : -1];
typedef char acl_edict_flags_offset_must_match[(offsetof(edict_t, v) + offsetof(entvars_t, flags) == ACL_EDICT_FLAGS) ? 1 : -1];
typedef char acl_edict_owner_offset_must_match[(offsetof(edict_t, v) + offsetof(entvars_t, owner) == ACL_EDICT_OWNER) ? 1 : -1];
typedef char acl_server_edicts_offset_must_match[(offsetof(server_t, edicts) == ACL_SERVER_EDICTS) ? 1 : -1];
typedef char acl_move_nomonsters_value_must_match[(MOVE_NOMONSTERS == 1) ? 1 : -1];
typedef char acl_solid_not_value_must_match[(SOLID_NOT == 0) ? 1 : -1];
typedef char acl_solid_trigger_value_must_match[(SOLID_TRIGGER == 1) ? 1 : -1];
typedef char acl_solid_bsp_value_must_match[(SOLID_BSP == 4) ? 1 : -1];
typedef char acl_monster_value_must_match[(FL_MONSTER == 32) ? 1 : -1];
#endif

#endif
