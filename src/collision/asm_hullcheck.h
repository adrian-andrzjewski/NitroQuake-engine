/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
#ifndef ASM_HULLCHECK_H
#define ASM_HULLCHECK_H

#ifndef __ASSEMBLER__
#include <stddef.h>

qboolean SV_RecursiveHullCheck_asm486(
	hull_t *, int, float, float, vec3_t, vec3_t, trace_t *);

typedef char hullcheck_pointer_size_must_match[(sizeof(void *) == 4U) ? 1 : -1];
typedef char hullcheck_float_size_must_match[(sizeof(float) == 4U) ? 1 : -1];
typedef char hullcheck_integer_size_must_match[(sizeof(int) == 4U) ? 1 : -1];
typedef char hullcheck_hull_size_must_match[(sizeof(hull_t) == 40U) ? 1 : -1];
typedef char hullcheck_hull_clipnodes_offset_must_match[(offsetof(hull_t, clipnodes) == 0U) ? 1 : -1];
typedef char hullcheck_hull_planes_offset_must_match[(offsetof(hull_t, planes) == 4U) ? 1 : -1];
typedef char hullcheck_hull_firstclipnode_offset_must_match[(offsetof(hull_t, firstclipnode) == 8U) ? 1 : -1];
typedef char hullcheck_hull_lastclipnode_offset_must_match[(offsetof(hull_t, lastclipnode) == 12U) ? 1 : -1];
typedef char hullcheck_clipnode_planenum_offset_must_match[(offsetof(dclipnode_t, planenum) == 0U) ? 1 : -1];
typedef char hullcheck_clipnode_children_offset_must_match[(offsetof(dclipnode_t, children) == 4U) ? 1 : -1];
typedef char hullcheck_clipnode_size_must_match[(sizeof(dclipnode_t) == 8U) ? 1 : -1];
typedef char hullcheck_mplane_normal_offset_must_match[(offsetof(mplane_t, normal) == 0U) ? 1 : -1];
typedef char hullcheck_mplane_dist_offset_must_match[(offsetof(mplane_t, dist) == 12U) ? 1 : -1];
typedef char hullcheck_mplane_type_offset_must_match[(offsetof(mplane_t, type) == 16U) ? 1 : -1];
typedef char hullcheck_mplane_size_must_match[(sizeof(mplane_t) == 20U) ? 1 : -1];
typedef char hullcheck_trace_size_must_match[(sizeof(trace_t) == 52U) ? 1 : -1];
typedef char hullcheck_trace_allsolid_offset_must_match[(offsetof(trace_t, allsolid) == 0U) ? 1 : -1];
typedef char hullcheck_trace_startsolid_offset_must_match[(offsetof(trace_t, startsolid) == 4U) ? 1 : -1];
typedef char hullcheck_trace_inopen_offset_must_match[(offsetof(trace_t, inopen) == 8U) ? 1 : -1];
typedef char hullcheck_trace_inwater_offset_must_match[(offsetof(trace_t, inwater) == 12U) ? 1 : -1];
typedef char hullcheck_trace_fraction_offset_must_match[(offsetof(trace_t, fraction) == 16U) ? 1 : -1];
typedef char hullcheck_trace_endpos_offset_must_match[(offsetof(trace_t, endpos) == 20U) ? 1 : -1];
typedef char hullcheck_trace_plane_offset_must_match[(offsetof(trace_t, plane) == 32U) ? 1 : -1];
typedef char hullcheck_trace_ent_offset_must_match[(offsetof(trace_t, ent) == 48U) ? 1 : -1];
#endif

#endif
