/* Exact C-oracle versus i486 state/RNG coverage for TE_TAREXPLOSION particles. */
#ifndef BENCH486_BLOBEXPLOSION_H
#define BENCH486_BLOBEXPLOSION_H

#ifdef ASM486_BLOB_EXPLOSION

#include <limits.h>
#include <stddef.h>
#include <stdlib.h>

#define BE_GUARD_WORDS 8
#define BE_FREE_BASE 1
#define BE_EMIT_LIMIT 1024
#define BE_FREE_MAX (BE_EMIT_LIMIT + 1)
#define BE_ACTIVE_HEAD (BE_FREE_BASE + BE_FREE_MAX)
#define BE_ACTIVE_TAIL (BE_ACTIVE_HEAD + 1)
#define BE_NODE_COUNT (BE_ACTIVE_TAIL + 1)
#define BE_RANDOM_PATTERN_COUNT 31

extern particle_t *active_particles, *free_particles;
extern int (*bench486_blobexplosion_rand_probe) (void);
extern unsigned bench486_blobexplosion_rand_calls;
extern void R_BlobExplosion_C (vec3_t org);
extern void R_BlobExplosion_asm486 (vec3_t org);
extern unsigned Bench486Call_asm486 (void (*function)(void), unsigned words,
		const unsigned *arguments, float *float_return);

/* r_part.c supplies this BENCH486-only hook for both the C oracle and asm. */
int Bench486BlobExplosionRand (void);

typedef char bench486_blobexplosion_pointer32[
		(sizeof(void *) == 4 && sizeof(int) == 4 && sizeof(unsigned) == 4) ?
		1 : -1];
typedef char bench486_blobexplosion_layout[
		(offsetof(particle_t, org) == 0 &&
		offsetof(particle_t, color) == 12 &&
		offsetof(particle_t, type) == 13 &&
		offsetof(particle_t, next) == 16 &&
		offsetof(particle_t, vel) == 20 &&
		offsetof(particle_t, die) == 36 && sizeof(particle_t) == 40 &&
		offsetof(client_state_t, time) == 572 &&
		sizeof(((client_state_t *)0)->time) == 8 &&
		pt_blob == 6 && pt_blob2 == 7) ? 1 : -1];

typedef struct
{
	unsigned before[BE_GUARD_WORDS];
	particle_t nodes[BE_NODE_COUNT];
	unsigned after[BE_GUARD_WORDS];
} bench486_blobexplosion_fixture_t;

typedef struct
{
	const char *name;
	int free_count;
	double time;
	unsigned seed;
	unsigned script_start;
	qboolean scripted;
} bench486_blobexplosion_case_t;

static bench486_blobexplosion_fixture_t bench486_blobexplosion_fixture;
static byte bench486_blobexplosion_reference[
		sizeof(bench486_blobexplosion_fixture)];
static unsigned bench486_blobexplosion_script_index;

/*
 * Values span the rand() contract boundary intentionally.  IDIV must match
 * C's signed remainder for the test provider's negative values; the ordinary
 * seeded-libc case below separately exercises the standard nonnegative path.
 */
static const int bench486_blobexplosion_script[BE_RANDOM_PATTERN_COUNT] =
{
	0, 1, 5, 6, 3, -1, -5, -6, -7, 15, 16, 17, INT_MIN, INT_MAX,
	2, 4, 9, 10, 11, 31, 32, 33, 511, 512, 513, -31, -32, -33,
	-511, -512, -513
};

static int Bench486BlobExplosionScript (void)
{
	unsigned index;

	index = bench486_blobexplosion_script_index % BE_RANDOM_PATTERN_COUNT;
	bench486_blobexplosion_script_index++;
	return bench486_blobexplosion_script[index];
}

static int Bench486BlobExplosionScriptPeek (void)
{
	return bench486_blobexplosion_script[
			bench486_blobexplosion_script_index % BE_RANDOM_PATTERN_COUNT];
}

static void Bench486BlobExplosionPrepare (int free_count)
{
	int i;

	Q_memset (&bench486_blobexplosion_fixture, 0x5a,
			sizeof(bench486_blobexplosion_fixture));
	for (i = 0 ; i < BE_GUARD_WORDS ; i++)
	{
		bench486_blobexplosion_fixture.before[i] = 0x5a5a5a5aU;
		bench486_blobexplosion_fixture.after[i] = 0xa5a5a5a5U;
	}

	bench486_blobexplosion_fixture.nodes[BE_ACTIVE_HEAD].next =
			&bench486_blobexplosion_fixture.nodes[BE_ACTIVE_TAIL];
	bench486_blobexplosion_fixture.nodes[BE_ACTIVE_TAIL].next = NULL;
	for (i = 0 ; i < free_count ; i++)
		bench486_blobexplosion_fixture.nodes[BE_FREE_BASE+i].next =
				i+1 < free_count ?
				&bench486_blobexplosion_fixture.nodes[BE_FREE_BASE+i+1] : NULL;

	active_particles = &bench486_blobexplosion_fixture.nodes[BE_ACTIVE_HEAD];
	free_particles = free_count ?
			&bench486_blobexplosion_fixture.nodes[BE_FREE_BASE] : NULL;
}

static int Bench486BlobExplosionStateValid (
		const bench486_blobexplosion_case_t *test, const float *org)
{
	int i, emitted, axis, expected_color;
	unsigned random_index;
	particle_t *expected_active, *expected_free;

	emitted = test->free_count < BE_EMIT_LIMIT ?
		test->free_count : BE_EMIT_LIMIT;
	expected_free = test->free_count > emitted ?
			&bench486_blobexplosion_fixture.nodes[BE_FREE_BASE+emitted] : NULL;
	expected_active = emitted ?
			&bench486_blobexplosion_fixture.nodes[BE_FREE_BASE+emitted-1] :
			&bench486_blobexplosion_fixture.nodes[BE_ACTIVE_HEAD];
	if (free_particles != expected_free || active_particles != expected_active ||
			bench486_blobexplosion_fixture.nodes[BE_ACTIVE_HEAD].next !=
				&bench486_blobexplosion_fixture.nodes[BE_ACTIVE_TAIL] ||
			bench486_blobexplosion_fixture.nodes[BE_ACTIVE_TAIL].next != NULL)
		return 0;

	for (i = 0 ; i < emitted ; i++)
	{
		particle_t *particle, *expected_next;
		byte expected_type;

		particle = &bench486_blobexplosion_fixture.nodes[BE_FREE_BASE+i];
		expected_next = i ?
				&bench486_blobexplosion_fixture.nodes[BE_FREE_BASE+i-1] :
				&bench486_blobexplosion_fixture.nodes[BE_ACTIVE_HEAD];
		expected_type = (byte)(i & 1 ? pt_blob : pt_blob2);
		if (test->scripted)
		{
			random_index = (test->script_start + (unsigned)(i * 8) + 1) %
					BE_RANDOM_PATTERN_COUNT;
			expected_color = (i & 1 ? 66 : 150) +
					bench486_blobexplosion_script[random_index] % 6;
		}
		else
			expected_color = -1;
		if (particle->next != expected_next || particle->type != expected_type ||
				(test->scripted ? particle->color != (byte)expected_color :
				 (i & 1 ? (particle->color < 66 || particle->color > 71) :
				  (particle->color < 150 || particle->color > 155))) ||
				particle->die < test->time || particle->die > test->time + 2.0)
			return 0;

		/* The two ABI padding bytes must stay untouched by both implementations. */
		if (((byte *)particle)[14] != 0x5a || ((byte *)particle)[15] != 0x5a)
				return 0;
		for (axis = 0 ; axis < 3 ; axis++)
		{
			if (test->scripted)
			{
				random_index = (test->script_start + (unsigned)(i * 8) +
						2 + (unsigned)(axis * 2)) % BE_RANDOM_PATTERN_COUNT;
				if (particle->org[axis] != org[axis] +
						((bench486_blobexplosion_script[random_index] % 32) - 16))
					return 0;
				random_index = (random_index + 1) % BE_RANDOM_PATTERN_COUNT;
				if (particle->vel[axis] != (float)(
						(bench486_blobexplosion_script[random_index] % 512) - 256))
					return 0;
			}
			else if (particle->org[axis] < org[axis] - 16.0f ||
					particle->org[axis] > org[axis] + 15.0f ||
					particle->vel[axis] < -256.0f || particle->vel[axis] > 255.0f)
				return 0;
		}
	}

	for (i = emitted ; i < test->free_count ; i++)
	{
		particle_t *expected_next;

		expected_next = i+1 < test->free_count ?
				&bench486_blobexplosion_fixture.nodes[BE_FREE_BASE+i+1] : NULL;
		if (bench486_blobexplosion_fixture.nodes[BE_FREE_BASE+i].next !=
				expected_next)
			return 0;
	}

	for (i = 0 ; i < BE_GUARD_WORDS ; i++)
		if (bench486_blobexplosion_fixture.before[i] != 0x5a5a5a5aU ||
				bench486_blobexplosion_fixture.after[i] != 0xa5a5a5a5U)
			return 0;
	return 1;
}

static unsigned Bench486BlobExplosionCall (
		void (*function)(void), const float *org)
{
	unsigned arguments[1];

	arguments[0] = (unsigned)org;
	return Bench486Call_asm486 (function, 1, arguments, NULL);
}

static unsigned Bench486BlobExplosionRunSide (
		void (*function)(void), const bench486_blobexplosion_case_t *test,
		const float *org, byte *snapshot, particle_t **active_result,
		particle_t **free_result, unsigned *rand_calls,
		unsigned *script_index, int *next_random, int *valid)
{
	unsigned abi;
	double time_after;

	Bench486BlobExplosionPrepare (test->free_count);
	cl.time = test->time;
	bench486_blobexplosion_rand_probe = test->scripted ?
			Bench486BlobExplosionScript : NULL;
	bench486_blobexplosion_rand_calls = 0;
	bench486_blobexplosion_script_index = test->script_start;
	srand (test->seed);
	abi = Bench486BlobExplosionCall (function, org);
	*rand_calls = bench486_blobexplosion_rand_calls;
	*script_index = bench486_blobexplosion_script_index;
	*next_random = test->scripted ? Bench486BlobExplosionScriptPeek () : rand ();
	*active_result = active_particles;
	*free_result = free_particles;
	Q_memcpy (&time_after, &cl.time, sizeof(time_after));
	*valid = Bench486BlobExplosionStateValid (test, org) &&
			Q_memcmp (&time_after, &test->time, sizeof(time_after)) == 0;
	Q_memcpy (snapshot, &bench486_blobexplosion_fixture,
			sizeof(bench486_blobexplosion_fixture));
	return abi;
}

/*
 * Scripted cases exercise signed remainders, both blob types, exhaustion at
 * every small-list boundary and the 1024-particle cap.  The final case uses
 * libc rand and compares the continuation value.  It should run in the
 * disposable BENCH486 process because libc RNG state is not restored.
 */
static void Bench486BlobExplosionCases (void)
{
	static const bench486_blobexplosion_case_t cases[] = {
		{ "empty", 0, 23.125, 0x48620001U, 3, 1 },
		{ "one", 1, 23.625, 0x48620002U, 8, 1 },
		{ "alternating", 2, 24.125, 0x48620003U, 13, 1 },
		{ "short", 7, 24.625, 0x48620004U, 4, 1 },
		{ "almost-full", 1023, 25.125, 0x48620005U, 0, 1 },
		{ "full", 1024, 25.625, 0x48620006U, 7, 1 },
		{ "one-extra-libc-rand", 1025, 26.125, 0x48620007U, 0, 0 }
	};
	static const float org[3] = { -123.25f, 8.5f, 1024.75f };
	particle_t *saved_active, *saved_free;
	double saved_time;
	int (*saved_probe) (void);
	unsigned saved_rand_calls, saved_script_index;
	particle_t *c_active, *c_free, *a_active, *a_free;
	unsigned c_abi, a_abi, c_calls, a_calls, c_script, a_script;
	int c_next, a_next, c_valid, a_valid;
	int i, failures, emitted;

	saved_active = active_particles;
	saved_free = free_particles;
	Q_memcpy (&saved_time, &cl.time, sizeof(saved_time));
	saved_probe = bench486_blobexplosion_rand_probe;
	saved_rand_calls = bench486_blobexplosion_rand_calls;
	saved_script_index = bench486_blobexplosion_script_index;
	failures = 0;
	Bench486Printf ("blob-explosion C/ASM begin (%d cases)\n",
			(int)(sizeof(cases)/sizeof(cases[0])));

	for (i = 0 ; i < (int)(sizeof(cases)/sizeof(cases[0])) ; i++)
	{
		Bench486Printf ("blob-explosion %d/%d %s\n", i+1,
				(int)(sizeof(cases)/sizeof(cases[0])), cases[i].name);
		c_abi = Bench486BlobExplosionRunSide (
				(void (*)(void))R_BlobExplosion_C, &cases[i], org,
				bench486_blobexplosion_reference, &c_active, &c_free,
				&c_calls, &c_script, &c_next, &c_valid);
		a_abi = Bench486BlobExplosionRunSide (
				(void (*)(void))R_BlobExplosion_asm486, &cases[i], org,
				(byte *)&bench486_blobexplosion_fixture, &a_active, &a_free,
				&a_calls, &a_script, &a_next, &a_valid);
		emitted = cases[i].free_count < BE_EMIT_LIMIT ?
				cases[i].free_count : BE_EMIT_LIMIT;
		if (c_abi || a_abi || c_calls != (unsigned)(emitted * 8) ||
				a_calls != (unsigned)(emitted * 8) || c_script != a_script ||
				c_next != a_next || !c_valid || !a_valid ||
				(cases[i].scripted &&
				 (c_script != cases[i].script_start + (unsigned)(emitted * 8) ||
				  a_script != cases[i].script_start + (unsigned)(emitted * 8))) ||
				c_active != a_active || c_free != a_free ||
				Q_memcmp (bench486_blobexplosion_reference,
						&bench486_blobexplosion_fixture,
						sizeof(bench486_blobexplosion_fixture)))
		{
			failures++;
			if (failures < 20)
				Bench486Printf (
						"blob-explosion FAIL %s ABI %x/%x calls %u/%u next %d/%d state %d/%d\n",
						cases[i].name, c_abi, a_abi, c_calls, a_calls,
						c_next, a_next, c_valid, a_valid);
		}
	}

	active_particles = saved_active;
	free_particles = saved_free;
	Q_memcpy (&cl.time, &saved_time, sizeof(saved_time));
	bench486_blobexplosion_rand_probe = saved_probe;
	bench486_blobexplosion_rand_calls = saved_rand_calls;
	bench486_blobexplosion_script_index = saved_script_index;
	bench486_memory_failures += failures;
	Bench486Printf (
			"blob-explosion C/ASM full-state and RNG continuation %s (%d cases; %d failures)\n",
			failures ? "FAIL" : "PASS",
			(int)(sizeof(cases)/sizeof(cases[0])), failures);
}

#endif /* ASM486_BLOB_EXPLOSION */
#endif /* BENCH486_BLOBEXPLOSION_H */
