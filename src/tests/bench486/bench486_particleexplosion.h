/* Exact C-oracle versus i486 state/RNG coverage for TE_EXPLOSION particles. */
/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
#ifndef BENCH486_PARTICLEEXPLOSION_H
#define BENCH486_PARTICLEEXPLOSION_H

#ifdef ASM486_PARTICLE_EXPLOSION

#include <limits.h>
#include <stdlib.h>

#define PE_GUARD_WORDS 8
#define PE_FREE_BASE 1
#define PE_EMIT_LIMIT 1024
#define PE_FREE_MAX (PE_EMIT_LIMIT + 1)
#define PE_ACTIVE_HEAD (PE_FREE_BASE + PE_FREE_MAX)
#define PE_ACTIVE_TAIL (PE_ACTIVE_HEAD + 1)
#define PE_NODE_COUNT (PE_ACTIVE_TAIL + 1)
#define PE_RANDOM_PATTERN_COUNT 17

extern particle_t *active_particles, *free_particles;
extern int ramp1[8];
extern int (*bench486_particleexplosion_rand_probe) (void);
extern unsigned bench486_particleexplosion_rand_calls;
extern int Bench486ParticleExplosionRand (void);
extern void R_ParticleExplosion_C (vec3_t org);
extern void R_ParticleExplosion_asm486 (vec3_t org);
extern unsigned Bench486Call_asm486 (void (*function)(void), unsigned words,
		const unsigned *arguments, float *float_return);

typedef char bench486_particleexplosion_pointer32[
		(sizeof(void *) == 4 && sizeof(int) == 4 && sizeof(unsigned) == 4) ?
		1 : -1];

typedef struct
{
	unsigned before[PE_GUARD_WORDS];
	particle_t nodes[PE_NODE_COUNT];
	unsigned after[PE_GUARD_WORDS];
} bench486_particleexplosion_fixture_t;

typedef struct
{
	const char *name;
	int free_count;
	double time;
	unsigned seed;
	unsigned script_start;
	qboolean scripted;
} bench486_particleexplosion_case_t;

static bench486_particleexplosion_fixture_t bench486_particleexplosion_fixture;
static byte bench486_particleexplosion_reference[
		sizeof(bench486_particleexplosion_fixture)];
static unsigned bench486_particleexplosion_script_index;

static const int bench486_particleexplosion_script[PE_RANDOM_PATTERN_COUNT] =
{
	0, 1, 31, 32, 33, 511, 512, 513,
	-1, -31, -32, -33, -511, -512, -513, INT_MIN, INT_MAX
};

static int Bench486ParticleExplosionScript (void)
{
	unsigned index;

	index = bench486_particleexplosion_script_index %
			PE_RANDOM_PATTERN_COUNT;
	bench486_particleexplosion_script_index++;
	return bench486_particleexplosion_script[index];
}

static int Bench486ParticleExplosionScriptPeek (void)
{
	return bench486_particleexplosion_script[
			bench486_particleexplosion_script_index %
			PE_RANDOM_PATTERN_COUNT];
}

static void Bench486ParticleExplosionPrepare (int free_count)
{
	int i;

	Q_memset (&bench486_particleexplosion_fixture, 0x5a,
			sizeof(bench486_particleexplosion_fixture));
	for (i = 0 ; i < PE_GUARD_WORDS ; i++)
	{
		bench486_particleexplosion_fixture.before[i] = 0x5a5a5a5aU;
		bench486_particleexplosion_fixture.after[i] = 0xa5a5a5a5U;
	}

	bench486_particleexplosion_fixture.nodes[PE_ACTIVE_HEAD].next =
			&bench486_particleexplosion_fixture.nodes[PE_ACTIVE_TAIL];
	bench486_particleexplosion_fixture.nodes[PE_ACTIVE_TAIL].next = NULL;
	for (i = 0 ; i < free_count ; i++)
		bench486_particleexplosion_fixture.nodes[PE_FREE_BASE+i].next =
				i+1 < free_count ?
				&bench486_particleexplosion_fixture.nodes[PE_FREE_BASE+i+1] :
				NULL;

	active_particles = &bench486_particleexplosion_fixture.nodes[PE_ACTIVE_HEAD];
	free_particles = free_count ?
			&bench486_particleexplosion_fixture.nodes[PE_FREE_BASE] : NULL;
}

static int Bench486ParticleExplosionStateValid (
		const bench486_particleexplosion_case_t *test, float expected_die)
{
	int i, emitted;
	particle_t *expected_active, *expected_free;

	emitted = test->free_count < PE_EMIT_LIMIT ?
		test->free_count : PE_EMIT_LIMIT;
	expected_free = test->free_count > emitted ?
			&bench486_particleexplosion_fixture.nodes[
				PE_FREE_BASE+emitted] : NULL;
	expected_active = emitted ?
			&bench486_particleexplosion_fixture.nodes[
				PE_FREE_BASE+emitted-1] :
			&bench486_particleexplosion_fixture.nodes[PE_ACTIVE_HEAD];
	if (free_particles != expected_free || active_particles != expected_active ||
			bench486_particleexplosion_fixture.nodes[PE_ACTIVE_HEAD].next !=
				&bench486_particleexplosion_fixture.nodes[PE_ACTIVE_TAIL])
		return 0;

	for (i = 0 ; i < emitted ; i++)
	{
		particle_t *particle, *expected_next;
		byte expected_type;

		particle = &bench486_particleexplosion_fixture.nodes[PE_FREE_BASE+i];
		expected_next = i ?
				&bench486_particleexplosion_fixture.nodes[PE_FREE_BASE+i-1] :
				&bench486_particleexplosion_fixture.nodes[PE_ACTIVE_HEAD];
		expected_type = (byte)(i & 1 ? pt_explode : pt_explode2);
		if (particle->next != expected_next || particle->color != (byte)ramp1[0] ||
				particle->type != expected_type ||
				(particle->ramp != 0.0f && particle->ramp != 1.0f &&
				 particle->ramp != 2.0f && particle->ramp != 3.0f) ||
				Q_memcmp(&particle->die, &expected_die, sizeof(expected_die)))
			return 0;
	}

	for (i = emitted ; i < test->free_count ; i++)
	{
		particle_t *expected_next;

		expected_next = i+1 < test->free_count ?
				&bench486_particleexplosion_fixture.nodes[PE_FREE_BASE+i+1] :
				NULL;
		if (bench486_particleexplosion_fixture.nodes[PE_FREE_BASE+i].next !=
				expected_next)
			return 0;
	}

	for (i = 0 ; i < PE_GUARD_WORDS ; i++)
		if (bench486_particleexplosion_fixture.before[i] != 0x5a5a5a5aU ||
				bench486_particleexplosion_fixture.after[i] != 0xa5a5a5a5U)
			return 0;
	return 1;
}

static unsigned Bench486ParticleExplosionCall (
		void (*function)(void), const float *org)
{
	unsigned arguments[1];

	arguments[0] = (unsigned)org;
	return Bench486Call_asm486 (function, 1, arguments, NULL);
}

static unsigned Bench486ParticleExplosionRunSide (
		void (*function)(void), const bench486_particleexplosion_case_t *test,
		const float *org, byte *snapshot, particle_t **active_result,
		particle_t **free_result, unsigned *rand_calls,
		unsigned *script_index, int *next_random, int *valid)
{
	float expected_die;
	int time_unchanged;
	unsigned abi;

	Bench486ParticleExplosionPrepare (test->free_count);
	cl.time = test->time;
	bench486_particleexplosion_rand_probe = test->scripted ?
			Bench486ParticleExplosionScript : NULL;
	bench486_particleexplosion_rand_calls = 0;
	bench486_particleexplosion_script_index = test->script_start;
	srand (test->seed);
	abi = Bench486ParticleExplosionCall (function, org);
	*rand_calls = bench486_particleexplosion_rand_calls;
	*script_index = bench486_particleexplosion_script_index;
	*next_random = test->scripted ? Bench486ParticleExplosionScriptPeek () : rand ();
	*active_result = active_particles;
	*free_result = free_particles;
	expected_die = (float)(test->time + 5.0);
	*valid = Bench486ParticleExplosionStateValid (test, expected_die);
	time_unchanged = Q_memcmp (&cl.time, (void *)&test->time,
			sizeof(test->time)) == 0;
	*valid = *valid && time_unchanged;
	Q_memcpy (snapshot, &bench486_particleexplosion_fixture,
			sizeof(bench486_particleexplosion_fixture));
	return abi;
}

/*
 * The scripted cases include negative returns to distinguish signed C % from
 * masking. A final libc-rand case also compares the real seeded RNG's next
 * value. Like the existing particle fixture, this changes libc rand state;
 * run it in the disposable BENCH486 process that exits after the check.
 */
static void Bench486ParticleExplosionCases (void)
{
	static const bench486_particleexplosion_case_t cases[] = {
		{ "empty", 0, 23.125, 0x48610001U, 3, 1 },
		{ "single-signed-remainders", 1, 23.625, 0x48610002U, 8, 1 },
		{ "alternating-types", 2, 24.125, 0x48610003U, 13, 1 },
		{ "short", 7, 24.625, 0x48610004U, 4, 1 },
		{ "almost-full", 1023, 25.125, 0x48610005U, 0, 1 },
		{ "full", 1024, 25.625, 0x48610006U, 7, 1 },
		{ "one-extra-libc-rand", 1025, 26.125, 0x48610007U, 0, 0 }
	};
	static const float org[3] = { -123.25f, 8.5f, 1024.75f };
	particle_t *saved_active, *saved_free;
	double saved_time;
	int (*saved_probe) (void);
	unsigned saved_rand_calls;
	unsigned saved_script_index;
	particle_t *c_active, *c_free, *a_active, *a_free;
	unsigned c_abi, a_abi, c_calls, a_calls, c_script, a_script;
	int c_next, a_next, c_valid, a_valid;
	int i, failures, emitted;

	saved_active = active_particles;
	saved_free = free_particles;
	Q_memcpy (&saved_time, &cl.time, sizeof(saved_time));
	saved_probe = bench486_particleexplosion_rand_probe;
	saved_rand_calls = bench486_particleexplosion_rand_calls;
	saved_script_index = bench486_particleexplosion_script_index;
	failures = 0;
	Bench486Printf ("particle-explosion C/ASM begin (%d cases)\n",
			(int)(sizeof(cases)/sizeof(cases[0])));

	for (i = 0 ; i < (int)(sizeof(cases)/sizeof(cases[0])) ; i++)
	{
		Bench486Printf ("particle-explosion %d/%d %s\n", i+1,
				(int)(sizeof(cases)/sizeof(cases[0])), cases[i].name);
		c_abi = Bench486ParticleExplosionRunSide (
				(void (*)(void))R_ParticleExplosion_C, &cases[i], org,
				bench486_particleexplosion_reference, &c_active, &c_free,
				&c_calls, &c_script, &c_next, &c_valid);

		a_abi = Bench486ParticleExplosionRunSide (
				(void (*)(void))R_ParticleExplosion_asm486, &cases[i], org,
				(byte *)&bench486_particleexplosion_fixture, &a_active, &a_free,
				&a_calls, &a_script, &a_next, &a_valid);
		emitted = cases[i].free_count < PE_EMIT_LIMIT ?
				cases[i].free_count : PE_EMIT_LIMIT;
		if (c_abi || a_abi || c_calls != (unsigned)(emitted * 7) ||
				a_calls != (unsigned)(emitted * 7) ||
				c_script != a_script || c_next != a_next || !c_valid || !a_valid ||
				(cases[i].scripted && (c_script != cases[i].script_start +
						(unsigned)(emitted * 7) || a_script != cases[i].script_start +
						(unsigned)(emitted * 7))) ||
				c_active != a_active || c_free != a_free ||
				Q_memcmp(bench486_particleexplosion_reference,
						&bench486_particleexplosion_fixture,
						sizeof(bench486_particleexplosion_fixture)))
		{
			failures++;
			if (failures < 20)
				Bench486Printf (
						"particle-explosion FAIL %s ABI %x/%x calls %u/%u next %d/%d state %d/%d\n",
						cases[i].name, c_abi, a_abi, c_calls, a_calls,
						c_next, a_next, c_valid, a_valid);
		}
	}

	active_particles = saved_active;
	free_particles = saved_free;
	Q_memcpy (&cl.time, &saved_time, sizeof(saved_time));
	bench486_particleexplosion_rand_probe = saved_probe;
	bench486_particleexplosion_rand_calls = saved_rand_calls;
	bench486_particleexplosion_script_index = saved_script_index;
	bench486_memory_failures += failures;
	Bench486Printf ("particle-explosion C/ASM full-state and RNG continuation %s (%d cases; %d failures)\n",
			failures ? "FAIL" : "PASS",
			(int)(sizeof(cases)/sizeof(cases[0])), failures);
}

#endif /* ASM486_PARTICLE_EXPLOSION */
#endif /* BENCH486_PARTICLEEXPLOSION_H */
