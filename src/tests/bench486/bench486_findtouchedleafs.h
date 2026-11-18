/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
#ifndef BENCH486_FINDTOUCHEDLEAFS_H
#define BENCH486_FINDTOUCHEDLEAFS_H

#if defined(BENCH486) && defined(ASM486_FIND_TOUCHED_LEAFS) && !defined(QUAKE2)
#include "collision/asm_findtouchedleafs.h"

typedef struct {
	unsigned before[4];
	edict_t entity;
	unsigned after[4];
} bench486_findtouchedleafs_guard_t;

static bench486_findtouchedleafs_guard_t bench486_findtouchedleafs_reference;
static bench486_findtouchedleafs_guard_t bench486_findtouchedleafs_candidate;
static model_t bench486_findtouchedleafs_model;
static mnode_t bench486_findtouchedleafs_nodes[2];
static mleaf_t bench486_findtouchedleafs_leaves[5];
static mplane_t bench486_findtouchedleafs_planes[2];
static mnode_t *bench486_findtouchedleafs_root;

static void Bench486FindTouchedLeafsInit(unsigned scenario)
{
	unsigned i;
	Q_memset(&bench486_findtouchedleafs_reference, 0,
		sizeof(bench486_findtouchedleafs_reference));
	Q_memset(&bench486_findtouchedleafs_model, 0,
		sizeof(bench486_findtouchedleafs_model));
	Q_memset(bench486_findtouchedleafs_nodes, 0,
		sizeof(bench486_findtouchedleafs_nodes));
	Q_memset(bench486_findtouchedleafs_leaves, 0,
		sizeof(bench486_findtouchedleafs_leaves));
	Q_memset(bench486_findtouchedleafs_planes, 0,
		sizeof(bench486_findtouchedleafs_planes));

	for (i = 0; i < 4; ++i) {
		bench486_findtouchedleafs_reference.before[i] = 0x31415926U;
		bench486_findtouchedleafs_reference.after[i] = 0x27182818U;
	}
	for (i = 0; i < MAX_ENT_LEAFS; ++i)
		bench486_findtouchedleafs_reference.entity.leafnums[i] = (short)(0x3100U + i);
	bench486_findtouchedleafs_reference.entity.v.absmin[0] = -10.0f;
	bench486_findtouchedleafs_reference.entity.v.absmin[1] = -10.0f;
	bench486_findtouchedleafs_reference.entity.v.absmin[2] = -2.0f;
	bench486_findtouchedleafs_reference.entity.v.absmax[0] = 10.0f;
	bench486_findtouchedleafs_reference.entity.v.absmax[1] = 10.0f;
	bench486_findtouchedleafs_reference.entity.v.absmax[2] = 2.0f;

	bench486_findtouchedleafs_model.leafs = bench486_findtouchedleafs_leaves;
	bench486_findtouchedleafs_leaves[0].contents = CONTENTS_SOLID;
	bench486_findtouchedleafs_leaves[1].contents = CONTENTS_EMPTY;
	bench486_findtouchedleafs_leaves[2].contents = CONTENTS_WATER;
	bench486_findtouchedleafs_leaves[3].contents = CONTENTS_SLIME;
	bench486_findtouchedleafs_leaves[4].contents = CONTENTS_LAVA;

	bench486_findtouchedleafs_planes[0].normal[0] = 1.0f;
	bench486_findtouchedleafs_planes[0].dist = 0.0f;
	bench486_findtouchedleafs_planes[0].type = 0;
	bench486_findtouchedleafs_planes[0].signbits = 0;
	bench486_findtouchedleafs_planes[1].normal[0] = 1.0f;
	bench486_findtouchedleafs_planes[1].normal[1] = 1.0f;
	bench486_findtouchedleafs_planes[1].dist = 0.0f;
	bench486_findtouchedleafs_planes[1].type = 3;
	bench486_findtouchedleafs_planes[1].signbits = 0;

	bench486_findtouchedleafs_nodes[0].plane = &bench486_findtouchedleafs_planes[0];
	bench486_findtouchedleafs_nodes[0].children[0] = &bench486_findtouchedleafs_nodes[1];
	bench486_findtouchedleafs_nodes[0].children[1] =
		(mnode_t *)&bench486_findtouchedleafs_leaves[3];
	bench486_findtouchedleafs_nodes[1].plane = &bench486_findtouchedleafs_planes[1];
	bench486_findtouchedleafs_nodes[1].children[0] =
		(mnode_t *)&bench486_findtouchedleafs_leaves[1];
	bench486_findtouchedleafs_nodes[1].children[1] =
		(mnode_t *)&bench486_findtouchedleafs_leaves[2];
	bench486_findtouchedleafs_root = &bench486_findtouchedleafs_nodes[0];

	if (scenario == 0)
		bench486_findtouchedleafs_nodes[0].contents = CONTENTS_SOLID;
	else if (scenario == 1) {
		bench486_findtouchedleafs_reference.entity.v.absmin[0] = 10.0f;
		bench486_findtouchedleafs_reference.entity.v.absmax[0] = 12.0f;
		bench486_findtouchedleafs_reference.entity.v.absmin[1] = 10.0f;
		bench486_findtouchedleafs_reference.entity.v.absmax[1] = 12.0f;
	}
	else if (scenario == 2) {
		bench486_findtouchedleafs_reference.entity.v.absmin[0] = 10.0f;
		bench486_findtouchedleafs_reference.entity.v.absmax[0] = 12.0f;
		bench486_findtouchedleafs_reference.entity.v.absmin[1] = -20.0f;
		bench486_findtouchedleafs_reference.entity.v.absmax[1] = -18.0f;
	}
	else if (scenario == 3) {
		bench486_findtouchedleafs_reference.entity.v.absmin[0] = -12.0f;
		bench486_findtouchedleafs_reference.entity.v.absmax[0] = -10.0f;
	}
	else if (scenario == 5)
		bench486_findtouchedleafs_reference.entity.num_leafs = MAX_ENT_LEAFS - 1;
	else if (scenario == 6)
		bench486_findtouchedleafs_root =
			(mnode_t *)&bench486_findtouchedleafs_leaves[4];
	else if (scenario == 7)
		bench486_findtouchedleafs_reference.entity.num_leafs = MAX_ENT_LEAFS;
	else if (scenario == 8) {
		/* The axial BOX_ON_PLANE_SIDE macro includes max-bound equality. */
		bench486_findtouchedleafs_reference.entity.v.absmin[0] = -2.0f;
		bench486_findtouchedleafs_reference.entity.v.absmax[0] = 0.0f;
	}
	else if (scenario == 9) {
		/* General BoxOnPlaneSide excludes min-bound equality from side two. */
		bench486_findtouchedleafs_reference.entity.v.absmin[0] = -2.0f;
		bench486_findtouchedleafs_reference.entity.v.absmax[0] = 2.0f;
		bench486_findtouchedleafs_reference.entity.v.absmin[1] = 2.0f;
		bench486_findtouchedleafs_reference.entity.v.absmax[1] = 4.0f;
	}

	Q_memcpy(&bench486_findtouchedleafs_candidate,
		&bench486_findtouchedleafs_reference,
		sizeof(bench486_findtouchedleafs_candidate));
}

static unsigned Bench486FindTouchedLeafsExpected(unsigned scenario,
	const bench486_findtouchedleafs_guard_t *result)
{
	static const unsigned expected_counts[10] = { 0, 1, 1, 1, 3, 16, 1, 16, 1, 2 };
	unsigned i;
	if (result->entity.num_leafs != (int)expected_counts[scenario])
		return 0;
	for (i = 0; i < 4; ++i)
		if (result->before[i] != 0x31415926U || result->after[i] != 0x27182818U)
			return 0;
	for (i = 0; i < MAX_ENT_LEAFS; ++i) {
		short expected;
		expected = (short)(0x3100U + i);
		if (scenario == 1 && i == 0)
			expected = 0;
		else if (scenario == 2 && i == 0)
			expected = 1;
		else if (scenario == 3 && i == 0)
			expected = 2;
		else if (scenario == 4 && i < 3)
			expected = (short)i;
		else if (scenario == 8 && i == 0)
			expected = 2;
		else if (scenario == 9 && i == 0)
			expected = 0;
		else if (scenario == 9 && i == 1)
			expected = 2;
		else if (scenario == 5 && i == MAX_ENT_LEAFS - 1)
			expected = 0;
		else if (scenario == 6 && i == 0)
			expected = 3;
		if (result->entity.leafnums[i] != expected)
			return 0;
	}
	return 1;
}

static unsigned Bench486FindTouchedLeafsCases(void)
{
	static const unsigned scenarios = 10;
	unsigned scenario, failures, calls_before;
	model_t *saved_worldmodel;
	failures = 0;
	saved_worldmodel = sv.worldmodel;
	sv.worldmodel = &bench486_findtouchedleafs_model;
	for (scenario = 0; scenario < scenarios; ++scenario) {
		Bench486FindTouchedLeafsInit(scenario);
		SV_FindTouchedLeafs_C(&bench486_findtouchedleafs_reference.entity,
		bench486_findtouchedleafs_root);
		calls_before = bench486_findtouchedleafs_asm_calls;
		SV_FindTouchedLeafs(&bench486_findtouchedleafs_candidate.entity,
			bench486_findtouchedleafs_root);
		if (bench486_findtouchedleafs_asm_calls == calls_before ||
				Q_memcmp(&bench486_findtouchedleafs_reference,
					&bench486_findtouchedleafs_candidate,
					sizeof(bench486_findtouchedleafs_reference)) ||
				!Bench486FindTouchedLeafsExpected(scenario,
					&bench486_findtouchedleafs_reference) ||
				!Bench486FindTouchedLeafsExpected(scenario,
					&bench486_findtouchedleafs_candidate))
			++failures;
	}
	sv.worldmodel = saved_worldmodel;
	Bench486Printf("BSP entity leaf traversal exact C/ASM %s (%u cases; %u assembly entries; full edict and guard comparison; %u failures)\n",
		failures ? "FAIL" : "PASS", scenarios,
		bench486_findtouchedleafs_asm_calls, failures);
	if (failures)
		bench486_memory_failures += failures;
	return failures;
}
#endif

#endif
