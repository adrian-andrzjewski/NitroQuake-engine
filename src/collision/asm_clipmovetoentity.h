#ifndef ASM_CLIP_MOVE_TO_ENTITY_H
#define ASM_CLIP_MOVE_TO_ENTITY_H

#ifndef __ASSEMBLER__
#include <stddef.h>
#include "collision/asm_hullcheck.h"

trace_t SV_ClipMoveToEntity(edict_t *, vec3_t, vec3_t, vec3_t, vec3_t);

#ifdef BENCH486
trace_t SV_ClipMoveToEntity_C(edict_t *, vec3_t, vec3_t, vec3_t, vec3_t);
extern unsigned bench486_clipmovetoentity_asm_calls;
#endif

typedef char clipmove_pointer_size_must_match[(sizeof(void *) == 4U) ? 1 : -1];
typedef char clipmove_trace_size_must_match[(sizeof(trace_t) == 52U) ? 1 : -1];
typedef char clipmove_trace_fraction_offset_must_match[(offsetof(trace_t, fraction) == 16U) ? 1 : -1];
typedef char clipmove_trace_endpos_offset_must_match[(offsetof(trace_t, endpos) == 20U) ? 1 : -1];
typedef char clipmove_trace_plane_offset_must_match[(offsetof(trace_t, plane) == 32U) ? 1 : -1];
typedef char clipmove_trace_ent_offset_must_match[(offsetof(trace_t, ent) == 48U) ? 1 : -1];
#endif

#endif
