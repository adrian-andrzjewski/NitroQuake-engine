#ifndef BENCH486_HULLCHECK_H
#define BENCH486_HULLCHECK_H

#include "bench486_hullforentity.h"

#if defined(BENCH486) && defined(ASM486_HULLCHECK)
extern unsigned bench486_hullcheck_dispatch_asm;
extern unsigned bench486_hullcheck_asm_calls;
#if defined(ASM486_CLIP_MOVE_TO_ENTITY) && !defined(QUAKE2)
extern unsigned bench486_clipmovetoentity_asm_calls;
extern trace_t SV_ClipMoveToEntity_C(edict_t *, vec3_t, vec3_t, vec3_t, vec3_t);
#endif
extern hull_t *SV_HullForBox(vec3_t, vec3_t);
extern void SV_InitBoxHull(void);
extern trace_t SV_ClipMoveToEntity(edict_t *, vec3_t, vec3_t, vec3_t, vec3_t);

typedef struct {
	unsigned before[8];
	edict_t entity;
	unsigned after[8];
} bench486_hullcheck_entity_t;

static bench486_hullcheck_entity_t bench486_hullcheck_entity;
static model_t bench486_hullcheck_model;

static int Bench486HullCheckGuards(void)
{
	unsigned i;
	for (i = 0; i < 8; ++i)
		if (bench486_hullcheck_entity.before[i] != 0x5a5a5a5aU ||
				bench486_hullcheck_entity.after[i] != 0xa5a5a5a5U)
			return 0;
	return 1;
}

static void Bench486HullCheckCases(void)
{
	static const float origins[7][3] = {
		{ 0, 0, 0 }, { 8, -6, 3 }, { -5, 7, -2 }, { 2, 4, 1 },
		{ -3, 6, 0 }, { 5, -2, 4 }, { 0, 0, 0 }
	};
	static const float starts[7][3] = {
		{ -48, 0, 0 }, { 0, -48, 0 }, { 0, 0, -64 }, { -48, 40, 0 },
		{ 0, 0, 0 }, { -48, 0, 0 }, { 0, 0, 0 }
	};
	static const float ends[7][3] = {
		{ 48, 0, 0 }, { 0, 48, 0 }, { 0, 0, 64 }, { 48, 40, 0 },
		{ 48, 0, 0 }, { 0, 0, 0 }, { 4, 0, 0 }
	};
	static model_t *saved_model;
	static trace_t reference, candidate;
	static vec3_t mins, maxs, start, end, hullmins, hullmaxs;
	unsigned i, target, cases = 0, failures = 0, asm_entries = 0;
	unsigned clipmove_entries = 0;
	unsigned *before, *after;

	Q_memset(&bench486_hullcheck_entity, 0, sizeof(bench486_hullcheck_entity));
	Q_memset(&bench486_hullcheck_model, 0, sizeof(bench486_hullcheck_model));
	before = bench486_hullcheck_entity.before;
	after = bench486_hullcheck_entity.after;
	for (i = 0; i < 8; ++i) {
		before[i] = 0x5a5a5a5aU;
		after[i] = 0xa5a5a5a5U;
	}

	bench486_hullcheck_entity.entity.v.mins[0] = -16;
	bench486_hullcheck_entity.entity.v.mins[1] = -16;
	bench486_hullcheck_entity.entity.v.mins[2] = -24;
	bench486_hullcheck_entity.entity.v.maxs[0] = 16;
	bench486_hullcheck_entity.entity.v.maxs[1] = 16;
	bench486_hullcheck_entity.entity.v.maxs[2] = 32;
	bench486_hullcheck_model.type = mod_brush;
	hullmins[0] = -16; hullmins[1] = -16; hullmins[2] = -24;
	hullmaxs[0] = 16; hullmaxs[1] = 16; hullmaxs[2] = 32;
	SV_InitBoxHull();
	bench486_hullcheck_model.hulls[0] = *SV_HullForBox(hullmins, hullmaxs);
	bench486_hullcheck_model.hulls[1] = bench486_hullcheck_model.hulls[0];
	bench486_hullcheck_model.hulls[2] = bench486_hullcheck_model.hulls[0];

	saved_model = sv.models[1];
	sv.models[1] = &bench486_hullcheck_model;
	mins[0] = mins[1] = mins[2] = -1;
	maxs[0] = maxs[1] = maxs[2] = 1;
	bench486_hullcheck_dispatch_asm = 0;
#if defined(ASM486_HULL_FOR_ENTITY) && !defined(QUAKE2)
	bench486_hullforentity_dispatch_asm = 0;
#endif

	for (target = 0; target < 2; ++target) {
		if (target) {
			SV_InitBoxHull();
			SV_HullForBox(hullmins, hullmaxs);
		}
		for (i = 0; i < 7; ++i) {
			unsigned axis;
			unsigned assembly_calls_before;
			edict_t *entity = &bench486_hullcheck_entity.entity;
			entity->v.solid = target ? SOLID_BSP : SOLID_BBOX;
			entity->v.movetype = MOVETYPE_PUSH;
			entity->v.modelindex = 1;
			for (axis = 0; axis < 3; ++axis) {
				entity->v.origin[axis] = origins[i][axis];
				start[axis] = origins[i][axis] + starts[i][axis];
				end[axis] = origins[i][axis] + ends[i][axis];
			}

			bench486_hullcheck_dispatch_asm = 0;
#if defined(ASM486_HULL_FOR_ENTITY) && !defined(QUAKE2)
			bench486_hullforentity_dispatch_asm = 0;
#endif
#if defined(ASM486_CLIP_MOVE_TO_ENTITY) && !defined(QUAKE2)
			reference = SV_ClipMoveToEntity_C(entity, start, mins, maxs, end);
			bench486_hullcheck_dispatch_asm = 1;
#if defined(ASM486_HULL_FOR_ENTITY) && !defined(QUAKE2)
			bench486_hullforentity_dispatch_asm = 1;
#endif
			{
				unsigned clip_calls_before = bench486_clipmovetoentity_asm_calls;
				assembly_calls_before = bench486_hullcheck_asm_calls;
				candidate = SV_ClipMoveToEntity(entity, start, mins, maxs, end);
				if (bench486_clipmovetoentity_asm_calls == clip_calls_before)
					failures++;
				else
					clipmove_entries += bench486_clipmovetoentity_asm_calls - clip_calls_before;
			}
#else
			reference = SV_ClipMoveToEntity(entity, start, mins, maxs, end);
			bench486_hullcheck_dispatch_asm = 1;
#if defined(ASM486_HULL_FOR_ENTITY) && !defined(QUAKE2)
			bench486_hullforentity_dispatch_asm = 1;
#endif
			assembly_calls_before = bench486_hullcheck_asm_calls;
			candidate = SV_ClipMoveToEntity(entity, start, mins, maxs, end);
#endif
			cases++;
			if (bench486_hullcheck_asm_calls == assembly_calls_before)
				failures++;
			else
				asm_entries += bench486_hullcheck_asm_calls - assembly_calls_before;
			if (Q_memcmp(&reference, &candidate, sizeof(reference)) ||
					!Bench486HullCheckGuards()) {
				failures++;
				if (failures < 8)
					Bench486Printf("entity/world hull route mismatch target %u case %u fraction %g/%g\n",
						target, i, reference.fraction, candidate.fraction);
			}
		}
	}

	Bench486HullForEntityCases();
	bench486_hullcheck_dispatch_asm = 1;
#if defined(ASM486_HULL_FOR_ENTITY) && !defined(QUAKE2)
	bench486_hullforentity_dispatch_asm = 1;
#endif
	sv.models[1] = saved_model;
#if defined(ASM486_CLIP_MOVE_TO_ENTITY) && !defined(QUAKE2)
	Bench486Printf("entity/world BSP trace exact C/ASM %s (%u traces; %u clip assembly entries; %u recursion entries; 16 edge sentinels; %u failures)\n",
		failures ? "FAIL" : "PASS", cases, clipmove_entries, asm_entries, failures);
#else
	Bench486Printf("entity/world BSP hull dispatch exact C/ASM %s (%u traces; %u assembly entries; 16 edge sentinels; %u failures)\n",
		failures ? "FAIL" : "PASS", cases, asm_entries, failures);
#endif
	if (failures)
		bench486_memory_failures += failures;
}
#else
static void Bench486HullCheckCases(void)
{
	bench486_memory_failures++;
	Bench486Printf("entity/world hull fixture requires HullCheckImplementation=asm\n");
}
#endif

#endif
