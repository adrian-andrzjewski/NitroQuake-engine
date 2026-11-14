#ifndef BENCH486_HULLFORENTITY_H
#define BENCH486_HULLFORENTITY_H

#if defined(BENCH486) && defined(ASM486_HULL_FOR_ENTITY) && !defined(QUAKE2)
#include "collision/asm_hullforentity.h"
extern void SV_InitBoxHull(void);

typedef struct
{
	unsigned before[4];
	vec3_t offset;
	unsigned after[4];
} bench486_hullforentity_offset_t;

static model_t bench486_hullforentity_model;
static edict_t bench486_hullforentity_entity;
static bench486_hullforentity_offset_t bench486_hullforentity_reference_offset;
static bench486_hullforentity_offset_t bench486_hullforentity_assembly_offset;

static qboolean Bench486HullForEntityGuards(void)
{
	int i;
	for (i = 0; i < 4; ++i)
	{
		if (bench486_hullforentity_reference_offset.before[i] != 0x13579bdfU ||
				bench486_hullforentity_reference_offset.after[i] != 0xfdb97531U ||
				bench486_hullforentity_assembly_offset.before[i] != 0x13579bdfU ||
				bench486_hullforentity_assembly_offset.after[i] != 0xfdb97531U)
			return false;
	}
	return true;
}

static void Bench486HullForEntityResetGuards(void)
{
	int i;
	for (i = 0; i < 4; ++i)
	{
		bench486_hullforentity_reference_offset.before[i] = 0x13579bdfU;
		bench486_hullforentity_reference_offset.after[i] = 0xfdb97531U;
		bench486_hullforentity_assembly_offset.before[i] = 0x13579bdfU;
		bench486_hullforentity_assembly_offset.after[i] = 0xfdb97531U;
	}
}

static void Bench486HullForEntityCases(void)
{
	static const float widths[4] = { 2.0f, 3.0f, 32.0f, 33.0f };
	static const unsigned expectedHull[4] = { 0, 1, 1, 2 };
	static const float movingMins[3] = { -1.0f, 1.25f, -4.0f };
	vec3_t movingMaxs = { 0.0f, 3.5f, 2.0f };
	static const float boxMins[3] = { -13.0f, 7.0f, -2.5f };
	static const float boxMaxs[3] = { 18.0f, 29.0f, 44.0f };
	static const float origin[3] = { 123.25f, -77.5f, 19.0f };
	model_t *savedModel;
	mplane_t referencePlanes[6];
	hull_t *referenceHull;
	hull_t *assemblyHull;
	unsigned boxCallsBefore;
	unsigned entityCallsBefore;
	unsigned cases = 0;
	unsigned failures = 0;
	unsigned i;

	Q_memset(&bench486_hullforentity_model, 0, sizeof(bench486_hullforentity_model));
	Q_memset(&bench486_hullforentity_entity, 0, sizeof(bench486_hullforentity_entity));
	bench486_hullforentity_model.type = mod_brush;
	bench486_hullforentity_model.hulls[0].clip_mins[0] = -16.0f;
	bench486_hullforentity_model.hulls[0].clip_mins[1] = -8.0f;
	bench486_hullforentity_model.hulls[0].clip_mins[2] = -24.0f;
	bench486_hullforentity_model.hulls[1].clip_mins[0] = -32.0f;
	bench486_hullforentity_model.hulls[1].clip_mins[1] = -12.0f;
	bench486_hullforentity_model.hulls[1].clip_mins[2] = -28.0f;
	bench486_hullforentity_model.hulls[2].clip_mins[0] = -64.0f;
	bench486_hullforentity_model.hulls[2].clip_mins[1] = -20.0f;
	bench486_hullforentity_model.hulls[2].clip_mins[2] = -36.0f;
	bench486_hullforentity_entity.v.movetype = MOVETYPE_PUSH;
	bench486_hullforentity_entity.v.modelindex = 1;
	bench486_hullforentity_entity.v.origin[0] = origin[0];
	bench486_hullforentity_entity.v.origin[1] = origin[1];
	bench486_hullforentity_entity.v.origin[2] = origin[2];
	savedModel = sv.models[1];
	sv.models[1] = &bench486_hullforentity_model;
	bench486_hullforentity_dispatch_asm = 1;

	for (i = 0; i < 4; ++i)
	{
		movingMaxs[0] = widths[i] - 1.0f;
		bench486_hullforentity_entity.v.solid = SOLID_BSP;
		bench486_hullforentity_entity.v.mins[0] = -1.0f;
		bench486_hullforentity_entity.v.mins[1] = 1.25f;
		bench486_hullforentity_entity.v.mins[2] = -4.0f;
		bench486_hullforentity_entity.v.maxs[0] = widths[i] - 1.0f;
		bench486_hullforentity_entity.v.maxs[1] = 3.5f;
		bench486_hullforentity_entity.v.maxs[2] = 2.0f;
		Bench486HullForEntityResetGuards();
		referenceHull = SV_HullForEntity_C(&bench486_hullforentity_entity,
			(vec_t *)movingMins, movingMaxs,
			bench486_hullforentity_reference_offset.offset);
		entityCallsBefore = bench486_hullforentity_asm_calls;
		assemblyHull = SV_HullForEntity(&bench486_hullforentity_entity,
			(vec_t *)movingMins, movingMaxs,
			bench486_hullforentity_assembly_offset.offset);
		++cases;
		if (bench486_hullforentity_asm_calls == entityCallsBefore ||
				referenceHull != &bench486_hullforentity_model.hulls[expectedHull[i]] ||
				assemblyHull != referenceHull ||
				Q_memcmp(bench486_hullforentity_reference_offset.offset,
					bench486_hullforentity_assembly_offset.offset, sizeof(vec3_t)) ||
				!Bench486HullForEntityGuards())
			++failures;
	}

	/* Compare the public six-plane box builder, including every plane field. */
	SV_InitBoxHull();
	boxCallsBefore = bench486_hullforbox_asm_calls;
	referenceHull = SV_HullForBox_C((vec_t *)boxMins, (vec_t *)boxMaxs);
	Q_memcpy(referencePlanes, box_planes, sizeof(referencePlanes));
	assemblyHull = SV_HullForBox((vec_t *)boxMins, (vec_t *)boxMaxs);
	++cases;
	if (bench486_hullforbox_asm_calls == boxCallsBefore || assemblyHull != referenceHull ||
			Q_memcmp(referencePlanes, box_planes, sizeof(referencePlanes)))
		++failures;

	/* Compare entity-created bbox planes and the returned origin offset. */
	bench486_hullforentity_entity.v.solid = SOLID_BBOX;
	bench486_hullforentity_entity.v.mins[0] = -13.0f;
	bench486_hullforentity_entity.v.mins[1] = 7.0f;
	bench486_hullforentity_entity.v.mins[2] = -2.5f;
	bench486_hullforentity_entity.v.maxs[0] = 18.0f;
	bench486_hullforentity_entity.v.maxs[1] = 29.0f;
	bench486_hullforentity_entity.v.maxs[2] = 44.0f;
	Bench486HullForEntityResetGuards();
	SV_InitBoxHull();
	referenceHull = SV_HullForEntity_C(&bench486_hullforentity_entity,
		(vec_t *)movingMins, movingMaxs,
		bench486_hullforentity_reference_offset.offset);
	Q_memcpy(referencePlanes, box_planes, sizeof(referencePlanes));
	entityCallsBefore = bench486_hullforentity_asm_calls;
	assemblyHull = SV_HullForEntity(&bench486_hullforentity_entity,
		(vec_t *)movingMins, movingMaxs,
		bench486_hullforentity_assembly_offset.offset);
	++cases;
	if (bench486_hullforentity_asm_calls == entityCallsBefore ||
			assemblyHull != referenceHull || assemblyHull != &box_hull ||
			Q_memcmp(bench486_hullforentity_reference_offset.offset,
				bench486_hullforentity_assembly_offset.offset, sizeof(vec3_t)) ||
			Q_memcmp(referencePlanes, box_planes, sizeof(referencePlanes)) ||
			!Bench486HullForEntityGuards())
		++failures;

	sv.models[1] = savedModel;
	Bench486Printf("entity hull helpers exact C/ASM %s (%u cases; %u entity entries; %u box entries; %u failures)\n",
		failures ? "FAIL" : "PASS", cases, bench486_hullforentity_asm_calls,
		bench486_hullforbox_asm_calls, failures);
	if (failures)
		bench486_memory_failures += failures;
}
#else
static void Bench486HullForEntityCases(void)
{
}
#endif

#endif
