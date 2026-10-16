#ifndef BENCH486_HULLCHECK_H
#define BENCH486_HULLCHECK_H

#include "bench486_hullforentity.h"

#if defined(BENCH486) && defined(ASM486_CLIP_TO_LINKS) && !defined(QUAKE2)
#include "asm_cliplinks.h"
#endif

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

#if defined(BENCH486) && defined(ASM486_CLIP_TO_LINKS) && !defined(QUAKE2)
typedef struct {
	unsigned before[4];
	moveclip_t clip;
	unsigned after[4];
} bench486_cliptolinks_guard_t;

static edict_t bench486_cliptolinks_edicts[4];
static areanode_t bench486_cliptolinks_nodes[3];
static bench486_cliptolinks_guard_t bench486_cliptolinks_reference;
static bench486_cliptolinks_guard_t bench486_cliptolinks_candidate;

static int Bench486ClipToLinksEntityIndex(edict_t *entity)
{
	unsigned i;
	for (i = 0; i < 4; ++i)
		if (entity == &bench486_cliptolinks_edicts[i])
			return (int)i;
	return -1;
}

static void Bench486ClipToLinksList(areanode_t *node, unsigned first, unsigned count)
{
	unsigned i;
	link_t *head;
	head = &node->solid_edicts;
	head->next = head;
	head->prev = head;
	for (i = 0; i < count; ++i) {
		link_t *link;
		link = &bench486_cliptolinks_edicts[first + i].area;
		link->prev = head->prev;
		link->next = head;
		head->prev->next = link;
		head->prev = link;
	}
}

static void Bench486ClipToLinksInit(unsigned scenario)
{
	static const float regular_mins[3] = { -1.0f, -1.0f, -1.0f };
	static const float regular_maxs[3] = { 1.0f, 1.0f, 1.0f };
	static const float monster_mins[3] = { -3.0f, -2.0f, -2.0f };
	static const float monster_maxs[3] = { 3.0f, 2.0f, 2.0f };
	static float start[3] = { -32.0f, 0.0f, 0.0f };
	static float end[3] = { 32.0f, 0.0f, 0.0f };
	unsigned i;
	Q_memset(bench486_cliptolinks_edicts, 0, sizeof(bench486_cliptolinks_edicts));
	Q_memset(bench486_cliptolinks_nodes, 0, sizeof(bench486_cliptolinks_nodes));
	Q_memset(&bench486_cliptolinks_reference, 0, sizeof(bench486_cliptolinks_reference));
	for (i = 0; i < 4; ++i) {
		bench486_cliptolinks_reference.before[i] = 0x2468ace0U;
		bench486_cliptolinks_reference.after[i] = 0x0eca8642U;
		bench486_cliptolinks_edicts[i].v.solid = SOLID_BBOX;
		bench486_cliptolinks_edicts[i].v.mins[0] = -8.0f;
		bench486_cliptolinks_edicts[i].v.mins[1] = -8.0f;
		bench486_cliptolinks_edicts[i].v.mins[2] = -8.0f;
		bench486_cliptolinks_edicts[i].v.maxs[0] = 8.0f;
		bench486_cliptolinks_edicts[i].v.maxs[1] = 8.0f;
		bench486_cliptolinks_edicts[i].v.maxs[2] = 8.0f;
		bench486_cliptolinks_edicts[i].v.absmin[0] = -8.0f;
		bench486_cliptolinks_edicts[i].v.absmin[1] = -8.0f;
		bench486_cliptolinks_edicts[i].v.absmin[2] = -8.0f;
		bench486_cliptolinks_edicts[i].v.absmax[0] = 8.0f;
		bench486_cliptolinks_edicts[i].v.absmax[1] = 8.0f;
		bench486_cliptolinks_edicts[i].v.absmax[2] = 8.0f;
		bench486_cliptolinks_edicts[i].v.origin[0] = i == 0 ? -10.0f : (i == 1 ? 10.0f : 0.0f);
	}
	bench486_cliptolinks_edicts[2].v.solid = SOLID_NOT;
	bench486_cliptolinks_edicts[3].v.origin[0] = 100.0f;
	bench486_cliptolinks_edicts[3].v.absmin[0] = 92.0f;
	bench486_cliptolinks_edicts[3].v.absmax[0] = 108.0f;

	bench486_cliptolinks_nodes[0].axis = -1;
	bench486_cliptolinks_nodes[1].axis = -1;
	bench486_cliptolinks_nodes[2].axis = -1;
	Bench486ClipToLinksList(&bench486_cliptolinks_nodes[0], 0, 4);
	bench486_cliptolinks_reference.clip.boxmins[0] = -40.0f;
	bench486_cliptolinks_reference.clip.boxmins[1] = -4.0f;
	bench486_cliptolinks_reference.clip.boxmins[2] = -4.0f;
	bench486_cliptolinks_reference.clip.boxmaxs[0] = 40.0f;
	bench486_cliptolinks_reference.clip.boxmaxs[1] = 4.0f;
	bench486_cliptolinks_reference.clip.boxmaxs[2] = 4.0f;
	bench486_cliptolinks_reference.clip.mins = (float *)regular_mins;
	bench486_cliptolinks_reference.clip.maxs = (float *)regular_maxs;
	bench486_cliptolinks_reference.clip.mins2[0] = monster_mins[0];
	bench486_cliptolinks_reference.clip.mins2[1] = monster_mins[1];
	bench486_cliptolinks_reference.clip.mins2[2] = monster_mins[2];
	bench486_cliptolinks_reference.clip.maxs2[0] = monster_maxs[0];
	bench486_cliptolinks_reference.clip.maxs2[1] = monster_maxs[1];
	bench486_cliptolinks_reference.clip.maxs2[2] = monster_maxs[2];
	bench486_cliptolinks_reference.clip.start = (float *)start;
	bench486_cliptolinks_reference.clip.end = (float *)end;
	bench486_cliptolinks_reference.clip.type = MOVE_NORMAL;
	bench486_cliptolinks_reference.clip.trace.fraction = 1.0f;
	Q_memcpy(bench486_cliptolinks_reference.clip.trace.endpos, end, sizeof(vec3_t));

	if (scenario == 1) {
		bench486_cliptolinks_reference.clip.type = MOVE_NOMONSTERS;
	}
	else if (scenario == 2) {
		bench486_cliptolinks_reference.clip.passedict = &bench486_cliptolinks_edicts[0];
	}
	else if (scenario == 3) {
		bench486_cliptolinks_reference.clip.passedict = &bench486_cliptolinks_edicts[3];
		bench486_cliptolinks_edicts[3].v.size[0] = 1.0f;
		bench486_cliptolinks_edicts[0].v.size[0] = 0.0f;
		bench486_cliptolinks_edicts[1].v.size[0] = 1.0f;
	}
	else if (scenario == 4) {
		bench486_cliptolinks_reference.clip.passedict = &bench486_cliptolinks_edicts[3];
		bench486_cliptolinks_edicts[0].v.owner = (int)((byte *)&bench486_cliptolinks_edicts[3] - (byte *)bench486_cliptolinks_edicts);
	}
	else if (scenario == 5) {
		bench486_cliptolinks_edicts[0].v.flags = (float)FL_MONSTER;
	}
	else if (scenario == 6) {
		bench486_cliptolinks_nodes[0].axis = 0;
		bench486_cliptolinks_nodes[0].dist = 0.0f;
		bench486_cliptolinks_nodes[0].children[0] = &bench486_cliptolinks_nodes[1];
		bench486_cliptolinks_nodes[0].children[1] = &bench486_cliptolinks_nodes[2];
		Bench486ClipToLinksList(&bench486_cliptolinks_nodes[0], 0, 0);
		Bench486ClipToLinksList(&bench486_cliptolinks_nodes[1], 0, 1);
		Bench486ClipToLinksList(&bench486_cliptolinks_nodes[2], 1, 1);
	}
	else if (scenario == 7) {
		bench486_cliptolinks_reference.clip.trace.startsolid = true;
	}
	Q_memcpy(&bench486_cliptolinks_candidate, &bench486_cliptolinks_reference,
		sizeof(bench486_cliptolinks_candidate));
}

static unsigned Bench486ClipToLinksCases(void)
{
	static const unsigned scenarios = 8;
	unsigned scenario, failures, calls_before;
	edict_t *saved_edicts;
	failures = 0;
	saved_edicts = sv.edicts;
	SV_InitBoxHull();
	for (scenario = 0; scenario < scenarios; ++scenario) {
		unsigned i;
		unsigned case_failed;
		edict_t *expected_ent;
		Bench486ClipToLinksInit(scenario);
		expected_ent = scenario == 1 || scenario == 2 ? NULL :
			(scenario == 3 || scenario == 4 ?
			&bench486_cliptolinks_edicts[1] : &bench486_cliptolinks_edicts[0]);
		sv.edicts = bench486_cliptolinks_edicts;
#if defined(ASM486_HULLCHECK)
		bench486_hullcheck_dispatch_asm = 0;
#endif
#if defined(ASM486_HULL_FOR_ENTITY) && !defined(QUAKE2)
		bench486_hullforentity_dispatch_asm = 0;
#endif
		SV_ClipToLinks_C(&bench486_cliptolinks_nodes[0],
			&bench486_cliptolinks_reference.clip);
#if defined(ASM486_HULLCHECK)
		bench486_hullcheck_dispatch_asm = 1;
#endif
#if defined(ASM486_HULL_FOR_ENTITY) && !defined(QUAKE2)
		bench486_hullforentity_dispatch_asm = 1;
#endif
		calls_before = bench486_cliptolinks_asm_calls;
		SV_ClipToLinks(&bench486_cliptolinks_nodes[0],
			&bench486_cliptolinks_candidate.clip);
		case_failed = 0;
		if (bench486_cliptolinks_asm_calls == calls_before ||
				Q_memcmp(&bench486_cliptolinks_reference.clip,
					&bench486_cliptolinks_candidate.clip, sizeof(moveclip_t)) ||
				bench486_cliptolinks_reference.clip.trace.ent != expected_ent)
			case_failed = 1;
		for (i = 0; i < 4; ++i) {
			if (bench486_cliptolinks_reference.before[i] != 0x2468ace0U ||
					bench486_cliptolinks_reference.after[i] != 0x0eca8642U ||
					bench486_cliptolinks_candidate.before[i] != 0x2468ace0U ||
					bench486_cliptolinks_candidate.after[i] != 0x0eca8642U)
				case_failed = 1;
		}
		if (case_failed) {
			++failures;
			Bench486Printf("clip-links case %u ref %.6f/all%u/start%u/ent%d asm %.6f/all%u/start%u/ent%d expected%d\n",
				scenario,
				bench486_cliptolinks_reference.clip.trace.fraction,
				(unsigned)bench486_cliptolinks_reference.clip.trace.allsolid,
				(unsigned)bench486_cliptolinks_reference.clip.trace.startsolid,
				Bench486ClipToLinksEntityIndex(bench486_cliptolinks_reference.clip.trace.ent),
				bench486_cliptolinks_candidate.clip.trace.fraction,
				(unsigned)bench486_cliptolinks_candidate.clip.trace.allsolid,
				(unsigned)bench486_cliptolinks_candidate.clip.trace.startsolid,
				Bench486ClipToLinksEntityIndex(bench486_cliptolinks_candidate.clip.trace.ent),
				Bench486ClipToLinksEntityIndex(expected_ent));
		}
	}
	sv.edicts = saved_edicts;
#if defined(ASM486_HULLCHECK)
	bench486_hullcheck_dispatch_asm = 1;
#endif
#if defined(ASM486_HULL_FOR_ENTITY) && !defined(QUAKE2)
	bench486_hullforentity_dispatch_asm = 1;
#endif
	Bench486Printf("area-link entity clipping exact C/ASM %s (%u cases; %u assembly entries; guard sentinels; %u failures)\n",
		failures ? "FAIL" : "PASS", scenarios, bench486_cliptolinks_asm_calls, failures);
	if (failures)
		bench486_memory_failures += failures;
	return failures;
}
#endif

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
#if defined(ASM486_CLIP_TO_LINKS) && !defined(QUAKE2)
	Bench486ClipToLinksCases();
#endif
#if defined(ASM486_FIND_TOUCHED_LEAFS) && !defined(QUAKE2)
	Bench486FindTouchedLeafsCases();
#endif
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
