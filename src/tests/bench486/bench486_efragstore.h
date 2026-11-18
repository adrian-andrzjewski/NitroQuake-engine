/* Exact C-oracle versus i486 state coverage for R_StoreEfrags. */
/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
#ifndef BENCH486_EFRAGSTORE_H
#define BENCH486_EFRAGSTORE_H

#if defined(BENCH486) && defined(ASM486_EFRAG_STORE)

#define BES_GUARD_WORDS 8
#define BES_ENTITY_COUNT 8
#define BES_MODEL_COUNT 3
#define BES_EFRAG_COUNT 6
#define BES_GUARD_BASE 0xefa60000U

extern void R_StoreEfrags_C (efrag_t **ppefrag);
extern void R_StoreEfrags_asm486 (efrag_t **ppefrag);
extern unsigned Bench486Call_asm486 (void (*function)(void), unsigned words,
		const unsigned *arguments, float *float_result);

typedef char bench486_efragstore_i386_layout[
		(sizeof(void *) == 4 && sizeof(int) == 4 && sizeof(unsigned) == 4 &&
		MAX_VISEDICTS == 256) ? 1 : -1];

typedef struct
{
	unsigned before[BES_GUARD_WORDS];
	entity_t data[BES_ENTITY_COUNT];
	unsigned after[BES_GUARD_WORDS];
} bench486_efragstore_entities_t;

typedef struct
{
	unsigned before[BES_GUARD_WORDS];
	model_t data[BES_MODEL_COUNT];
	unsigned after[BES_GUARD_WORDS];
} bench486_efragstore_models_t;

typedef struct
{
	unsigned before[BES_GUARD_WORDS];
	efrag_t data[BES_EFRAG_COUNT];
	unsigned after[BES_GUARD_WORDS];
} bench486_efragstore_fragments_t;

typedef struct
{
	int frame;
	int count;
	efrag_t *head;
	unsigned abi;
	unsigned guards_ok;
	entity_t *visible[MAX_VISEDICTS];
	bench486_efragstore_entities_t entities;
	bench486_efragstore_models_t models;
	bench486_efragstore_fragments_t fragments;
} bench486_efragstore_result_t;

static bench486_efragstore_entities_t bench486_efragstore_entities;
static bench486_efragstore_models_t bench486_efragstore_models;
static bench486_efragstore_fragments_t bench486_efragstore_fragments;
static bench486_efragstore_result_t bench486_efragstore_c_result;
static bench486_efragstore_result_t bench486_efragstore_asm_result;

static void Bench486EfragStoreSetGuards (unsigned *before, unsigned *after,
		unsigned salt)
{
	int i;

	for (i = 0; i < BES_GUARD_WORDS; i++)
	{
		before[i] = BES_GUARD_BASE ^ salt ^ (unsigned)i;
		after[i] = ~before[i];
	}
}

static int Bench486EfragStoreCheckGuards (void)
{
	int i;

	for (i = 0; i < BES_GUARD_WORDS; i++)
	{
		if (bench486_efragstore_entities.before[i] !=
				(BES_GUARD_BASE ^ 0x11U ^ (unsigned)i) ||
			bench486_efragstore_entities.after[i] !=
				~(BES_GUARD_BASE ^ 0x11U ^ (unsigned)i) ||
			bench486_efragstore_models.before[i] !=
				(BES_GUARD_BASE ^ 0x22U ^ (unsigned)i) ||
			bench486_efragstore_models.after[i] !=
				~(BES_GUARD_BASE ^ 0x22U ^ (unsigned)i) ||
			bench486_efragstore_fragments.before[i] !=
				(BES_GUARD_BASE ^ 0x33U ^ (unsigned)i) ||
			bench486_efragstore_fragments.after[i] !=
				~(BES_GUARD_BASE ^ 0x33U ^ (unsigned)i))
			return 0;
	}

	return 1;
}

static void Bench486EfragStoreBuild (int scenario, efrag_t **head)
{
	int i;
	int frame;

	Q_memset (&bench486_efragstore_entities, 0,
			sizeof (bench486_efragstore_entities));
	Q_memset (&bench486_efragstore_models, 0,
			sizeof (bench486_efragstore_models));
	Q_memset (&bench486_efragstore_fragments, 0,
			sizeof (bench486_efragstore_fragments));
	Bench486EfragStoreSetGuards (bench486_efragstore_entities.before,
			bench486_efragstore_entities.after, 0x11U);
	Bench486EfragStoreSetGuards (bench486_efragstore_models.before,
			bench486_efragstore_models.after, 0x22U);
	Bench486EfragStoreSetGuards (bench486_efragstore_fragments.before,
			bench486_efragstore_fragments.after, 0x33U);

	bench486_efragstore_models.data[0].type = mod_brush;
	bench486_efragstore_models.data[1].type = mod_sprite;
	bench486_efragstore_models.data[2].type = mod_alias;
	frame = 0x13579bdf;
	r_framecount = frame;
	for (i = 0; i < BES_ENTITY_COUNT; i++)
	{
		bench486_efragstore_entities.data[i].model =
				&bench486_efragstore_models.data[i % BES_MODEL_COUNT];
		bench486_efragstore_entities.data[i].visframe = frame - 1;
	}
	for (i = 0; i < BES_EFRAG_COUNT; i++)
		bench486_efragstore_fragments.data[i].entity =
				&bench486_efragstore_entities.data[i];

	cl_numvisedicts = 5;
	for (i = 0; i < MAX_VISEDICTS; i++)
		cl_visedicts[i] = &bench486_efragstore_entities.data[
				(i * 3 + 1) % BES_ENTITY_COUNT];
	*head = NULL;

	switch (scenario)
	{
	case 0: /* empty list leaves the complete visible array unchanged */
		break;

	case 1: /* mixed types, repeated entities, and an already-visible entity */
		cl_numvisedicts = 3;
		bench486_efragstore_entities.data[0].model =
				&bench486_efragstore_models.data[0];
		bench486_efragstore_entities.data[1].model =
				&bench486_efragstore_models.data[1];
		bench486_efragstore_entities.data[2].model =
				&bench486_efragstore_models.data[2];
		bench486_efragstore_entities.data[3].model =
				&bench486_efragstore_models.data[1];
		bench486_efragstore_entities.data[3].visframe = frame;
		bench486_efragstore_fragments.data[0].entity =
				&bench486_efragstore_entities.data[0];
		bench486_efragstore_fragments.data[1].entity =
				&bench486_efragstore_entities.data[1];
		bench486_efragstore_fragments.data[2].entity =
				&bench486_efragstore_entities.data[2];
		bench486_efragstore_fragments.data[3].entity =
				&bench486_efragstore_entities.data[0];
		bench486_efragstore_fragments.data[4].entity =
				&bench486_efragstore_entities.data[3];
		bench486_efragstore_fragments.data[5].entity =
				&bench486_efragstore_entities.data[1];
		for (i = 0; i < BES_EFRAG_COUNT - 1; i++)
			bench486_efragstore_fragments.data[i].leafnext =
					&bench486_efragstore_fragments.data[i + 1];
		*head = &bench486_efragstore_fragments.data[0];
		break;

	case 2: /* one free slot: append exactly at MAX_VISEDICTS - 1 */
		cl_numvisedicts = MAX_VISEDICTS - 1;
		bench486_efragstore_fragments.data[0].entity =
				&bench486_efragstore_entities.data[4];
		bench486_efragstore_fragments.data[0].leafnext =
				&bench486_efragstore_fragments.data[1];
		bench486_efragstore_fragments.data[1].entity =
				&bench486_efragstore_entities.data[5];
		*head = &bench486_efragstore_fragments.data[0];
		break;

	case 3: /* full array rejects a new entity without touching it */
		cl_numvisedicts = MAX_VISEDICTS;
		bench486_efragstore_fragments.data[0].entity =
				&bench486_efragstore_entities.data[6];
		*head = &bench486_efragstore_fragments.data[0];
		break;
	}
}

static void Bench486EfragStoreCapture (bench486_efragstore_result_t *result,
		efrag_t *head, unsigned abi)
{
	Q_memset (result, 0, sizeof (*result));
	result->frame = r_framecount;
	result->count = cl_numvisedicts;
	result->head = head;
	result->abi = abi;
	result->guards_ok = (unsigned)Bench486EfragStoreCheckGuards ();
	Q_memcpy (result->visible, cl_visedicts, sizeof (result->visible));
	Q_memcpy (&result->entities, &bench486_efragstore_entities,
			sizeof (result->entities));
	Q_memcpy (&result->models, &bench486_efragstore_models,
			sizeof (result->models));
	Q_memcpy (&result->fragments, &bench486_efragstore_fragments,
			sizeof (result->fragments));
}

static unsigned Bench486EfragStoreFirstDifference (const byte *left,
		const byte *right, unsigned size)
{
	unsigned i;

	for (i = 0; i < size; i++)
		if (left[i] != right[i])
			return i;
	return size;
}

static int Bench486EfragStoreExpected (int scenario,
		const bench486_efragstore_result_t *result)
{
	if (!result->guards_ok || result->frame != 0x13579bdf)
		return 0;

	switch (scenario)
	{
	case 0:
		return result->count == 5;
	case 1:
		return result->count == 6 &&
			result->visible[3] == &bench486_efragstore_entities.data[0] &&
			result->visible[4] == &bench486_efragstore_entities.data[1] &&
			result->visible[5] == &bench486_efragstore_entities.data[2] &&
			result->entities.data[0].visframe == result->frame &&
			result->entities.data[1].visframe == result->frame &&
			result->entities.data[2].visframe == result->frame &&
			result->entities.data[3].visframe == result->frame;
	case 2:
		return result->count == MAX_VISEDICTS &&
			result->visible[MAX_VISEDICTS - 1] ==
					&bench486_efragstore_entities.data[4] &&
			result->entities.data[4].visframe == result->frame &&
			result->entities.data[5].visframe != result->frame;
	case 3:
		return result->count == MAX_VISEDICTS &&
			result->entities.data[6].visframe != result->frame;
	}

	return 0;
}

static void Bench486EfragStoreCall (void (*function)(efrag_t **),
		int scenario, bench486_efragstore_result_t *result)
{
	efrag_t *head;
	unsigned arguments[1];
	unsigned abi;

	Bench486EfragStoreBuild (scenario, &head);
	arguments[0] = (unsigned)&head;
	abi = Bench486Call_asm486 ((void (*)(void))function, 1, arguments, NULL);
	Bench486EfragStoreCapture (result, head, abi);
}

static void Bench486EfragStoreCases (void)
{
	static const char *names[4] =
	{
		"empty-list", "mixed-types-duplicates-visible", "one-slot-left",
		"full-capacity"
	};
	entity_t *saved_visible[MAX_VISEDICTS];
	int saved_count, saved_frame;
	int c_expected, asm_expected;
	unsigned failures, cases, i, difference;

	saved_count = cl_numvisedicts;
	saved_frame = r_framecount;
	Q_memcpy (saved_visible, cl_visedicts, sizeof (saved_visible));
	failures = 0;
	cases = 4;
	Bench486Printf ("efrag-store fixture begin (%u cases; full visible-list state and ABI)\n",
		cases);

	for (i = 0; i < cases; i++)
	{
		Bench486EfragStoreCall (R_StoreEfrags_C, (int)i,
				&bench486_efragstore_c_result);
		Bench486EfragStoreCall (R_StoreEfrags_asm486, (int)i,
				&bench486_efragstore_asm_result);
		c_expected = Bench486EfragStoreExpected ((int)i,
				&bench486_efragstore_c_result);
		asm_expected = Bench486EfragStoreExpected ((int)i,
				&bench486_efragstore_asm_result);
		difference = Bench486EfragStoreFirstDifference (
				(const byte *)&bench486_efragstore_c_result,
				(const byte *)&bench486_efragstore_asm_result,
				(unsigned)sizeof (bench486_efragstore_c_result));
		if (difference != sizeof (bench486_efragstore_c_result) ||
				bench486_efragstore_c_result.abi ||
				bench486_efragstore_asm_result.abi ||
				!c_expected || !asm_expected)
		{
			failures++;
			Bench486Printf ("efrag-store %s FAIL byte %u ABI %u/%u count %d/%d expected %d/%d guards %u/%u\n",
					names[i], difference,
					bench486_efragstore_c_result.abi,
					bench486_efragstore_asm_result.abi,
					bench486_efragstore_c_result.count,
					bench486_efragstore_asm_result.count,
					c_expected, asm_expected,
					bench486_efragstore_c_result.guards_ok,
					bench486_efragstore_asm_result.guards_ok);
		}
		else
			Bench486Printf ("efrag-store %s exact C/ASM state PASS\n", names[i]);
	}

	cl_numvisedicts = saved_count;
	r_framecount = saved_frame;
	Q_memcpy (cl_visedicts, saved_visible, sizeof (saved_visible));
	if (cl_numvisedicts != saved_count || r_framecount != saved_frame ||
			Q_memcmp (cl_visedicts, saved_visible, sizeof (saved_visible)))
	{
		failures++;
		Bench486Printf ("efrag-store caller state restore FAIL\n");
	}
	if (failures)
		bench486_memory_failures += (int)failures;
	Bench486Printf ("efrag-store C/ASM %s (%u cases; %u failures)\n",
			failures ? "FAIL" : "PASS", cases, failures);
}

#undef BES_GUARD_WORDS
#undef BES_ENTITY_COUNT
#undef BES_MODEL_COUNT
#undef BES_EFRAG_COUNT
#undef BES_GUARD_BASE

#endif /* BENCH486 && ASM486_EFRAG_STORE */

#endif /* BENCH486_EFRAGSTORE_H */
