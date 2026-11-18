/* Exact C-oracle versus i486 state and RNG coverage for R_RunParticleEffect. */
/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
#ifndef BENCH486_RUNPARTICLEEFFECT_H
#define BENCH486_RUNPARTICLEEFFECT_H

#ifdef ASM486_RUN_PARTICLE_EFFECT

#include <limits.h>
#include <stddef.h>
#include <stdlib.h>

#define RPE_GUARD_WORDS 8
#define RPE_FREE_BASE 1
#define RPE_EMIT_LIMIT 1024
#define RPE_FREE_MAX (RPE_EMIT_LIMIT + 1)
#define RPE_ACTIVE_HEAD (RPE_FREE_BASE + RPE_FREE_MAX)
#define RPE_ACTIVE_TAIL (RPE_ACTIVE_HEAD + 1)
#define RPE_NODE_COUNT (RPE_ACTIVE_TAIL + 1)
#define RPE_RANDOM_PATTERN_COUNT 19

extern particle_t *active_particles, *free_particles;
extern int ramp1[8];
extern client_state_t cl;
extern int (*bench486_runparticleeffect_rand_probe) (void);
extern unsigned bench486_runparticleeffect_rand_calls;
extern int Bench486RunParticleEffectRand (void);
extern void R_RunParticleEffect_C (vec3_t org, vec3_t dir, int color, int count);
extern void R_RunParticleEffect_asm486 (vec3_t org, vec3_t dir, int color,
		int count);
extern unsigned Bench486Call_asm486 (void (*function)(void), unsigned words,
		const unsigned *arguments, float *float_return);

typedef char bench486_runparticleeffect_pointer32[
		(sizeof(void *) == 4 && sizeof(int) == 4 && sizeof(unsigned) == 4) ?
		1 : -1];
typedef char bench486_runparticleeffect_layout[
		(offsetof(particle_t, org) == 0 &&
		offsetof(particle_t, color) == 12 &&
		offsetof(particle_t, type) == 13 &&
		offsetof(particle_t, next) == 16 &&
		offsetof(particle_t, vel) == 20 &&
		offsetof(particle_t, ramp) == 32 &&
		offsetof(particle_t, die) == 36 && sizeof(particle_t) == 40 &&
		offsetof(client_state_t, time) == 572 &&
		sizeof(((client_state_t *)0)->time) == 8 && pt_slowgrav == 2 &&
		pt_explode == 4 && pt_explode2 == 5) ? 1 : -1];

typedef struct
{
	unsigned before[RPE_GUARD_WORDS];
	particle_t nodes[RPE_NODE_COUNT];
	unsigned after[RPE_GUARD_WORDS];
} bench486_runparticleeffect_fixture_t;

typedef struct
{
	const char *name;
	int count;
	int free_count;
	int color;
	double time;
	unsigned seed;
	unsigned script_start;
	qboolean scripted;
} bench486_runparticleeffect_case_t;

static bench486_runparticleeffect_fixture_t bench486_runparticleeffect_fixture;
static byte bench486_runparticleeffect_reference[
		sizeof(bench486_runparticleeffect_fixture)];
static unsigned bench486_runparticleeffect_script_index;
static int bench486_runparticleeffect_state_reason;

/* Include negative values to prove that the rocket branch uses signed % and
 * the impact branch uses the specified bit masks in the original order. */
static const int bench486_runparticleeffect_script[RPE_RANDOM_PATTERN_COUNT] =
{
	0, 1, 4, 5, 7, 8, 15, 16, 31, 32, 63, 64, 127, 255,
	-1, -2, -31, INT_MIN, INT_MAX
};

static int Bench486RunParticleEffectScript (void)
{
	unsigned index;

	index = bench486_runparticleeffect_script_index %
			RPE_RANDOM_PATTERN_COUNT;
	bench486_runparticleeffect_script_index++;
	return bench486_runparticleeffect_script[index];
}

static int Bench486RunParticleEffectScriptPeek (void)
{
	return bench486_runparticleeffect_script[
			bench486_runparticleeffect_script_index %
			RPE_RANDOM_PATTERN_COUNT];
}

static void Bench486RunParticleEffectPrepare (int free_count)
{
	int i;

	Q_memset (&bench486_runparticleeffect_fixture, 0x5a,
			sizeof(bench486_runparticleeffect_fixture));
	for (i = 0 ; i < RPE_GUARD_WORDS ; i++)
	{
		bench486_runparticleeffect_fixture.before[i] = 0x5a5a5a5aU;
		bench486_runparticleeffect_fixture.after[i] = 0xa5a5a5a5U;
	}
	bench486_runparticleeffect_fixture.nodes[RPE_ACTIVE_HEAD].next =
			&bench486_runparticleeffect_fixture.nodes[RPE_ACTIVE_TAIL];
	bench486_runparticleeffect_fixture.nodes[RPE_ACTIVE_TAIL].next = NULL;
	for (i = 0 ; i < free_count ; i++)
		bench486_runparticleeffect_fixture.nodes[RPE_FREE_BASE+i].next =
				i+1 < free_count ?
				&bench486_runparticleeffect_fixture.nodes[RPE_FREE_BASE+i+1] : NULL;

	active_particles =
			&bench486_runparticleeffect_fixture.nodes[RPE_ACTIVE_HEAD];
	free_particles = free_count ?
			&bench486_runparticleeffect_fixture.nodes[RPE_FREE_BASE] : NULL;
}

static int Bench486RunParticleEffectStateValid (
		const bench486_runparticleeffect_case_t *test, const float *org,
		const float *dir)
{
	int i, emitted, active_expected, random_index, random_value;
	particle_t *expected_active, *expected_free;

	emitted = test->count > 0 ? test->count : 0;
	if (emitted > test->free_count)
		emitted = test->free_count;
	active_expected = emitted ? RPE_FREE_BASE + emitted - 1 : RPE_ACTIVE_HEAD;
	expected_free = test->free_count > emitted ?
			&bench486_runparticleeffect_fixture.nodes[RPE_FREE_BASE+emitted] : NULL;
	expected_active =
			&bench486_runparticleeffect_fixture.nodes[active_expected];
	if (free_particles != expected_free || active_particles != expected_active ||
			bench486_runparticleeffect_fixture.nodes[RPE_ACTIVE_HEAD].next !=
				&bench486_runparticleeffect_fixture.nodes[RPE_ACTIVE_TAIL] ||
			bench486_runparticleeffect_fixture.nodes[RPE_ACTIVE_TAIL].next != NULL)
	{
		bench486_runparticleeffect_state_reason = 1;
		return 0;
	}

	for (i = 0 ; i < emitted ; i++)
	{
		particle_t *particle, *expected_next;
		int axis, call_index, base;
		unsigned ramp_bits;
		float expected_float, expected_value;

		particle = &bench486_runparticleeffect_fixture.nodes[RPE_FREE_BASE+i];
		expected_next = i ?
				&bench486_runparticleeffect_fixture.nodes[RPE_FREE_BASE+i-1] :
				&bench486_runparticleeffect_fixture.nodes[RPE_ACTIVE_HEAD];
		if (particle->next != expected_next)
		{
			bench486_runparticleeffect_state_reason = 2;
			return 0;
		}

		if (test->count == 1024)
		{
			if (particle->type != (byte)(i & 1 ? pt_explode : pt_explode2) ||
					particle->color != (byte)ramp1[0] ||
					particle->die != (float)(test->time + 5.0) ||
					particle->ramp < 0.0f || particle->ramp > 3.0f)
			{
				bench486_runparticleeffect_state_reason = 3;
				return 0;
			}
			call_index = i * 7;
			if (test->scripted)
			{
				random_index = (int)((test->script_start +
						(unsigned)call_index) % RPE_RANDOM_PATTERN_COUNT);
				random_value = bench486_runparticleeffect_script[random_index];
				expected_float = (float)(random_value & 3);
				if (Q_memcmp (&particle->ramp, &expected_float,
						sizeof(expected_float)) != 0)
				{
					bench486_runparticleeffect_state_reason = 4;
					return 0;
				}
			}
			for (axis = 0 ; axis < 3 ; axis++)
			{
				call_index++;
				if (test->scripted)
				{
					random_index = (int)((test->script_start +
							(unsigned)call_index) % RPE_RANDOM_PATTERN_COUNT);
					random_value = bench486_runparticleeffect_script[random_index];
					expected_value = org[axis] + ((random_value % 32) - 16);
					if (Q_memcmp (&particle->org[axis], &expected_value,
							sizeof(expected_value)) != 0)
					{
						bench486_runparticleeffect_state_reason = 5;
						return 0;
					}
				}
				call_index++;
				if (test->scripted)
				{
					random_index = (int)((test->script_start +
							(unsigned)call_index) % RPE_RANDOM_PATTERN_COUNT);
					random_value = bench486_runparticleeffect_script[random_index];
					expected_float = (float)((random_value % 512) - 256);
					if (Q_memcmp (&particle->vel[axis], &expected_float,
							sizeof(expected_float)) != 0)
					{
						bench486_runparticleeffect_state_reason = 6;
						return 0;
					}
				}
			}
		}
		else
		{
			Q_memcpy (&ramp_bits, &particle->ramp, sizeof(ramp_bits));
			if (particle->type != pt_slowgrav || ramp_bits != 0x5a5a5a5aU)
			{
				bench486_runparticleeffect_state_reason = 7;
				return 0;
			}
			call_index = i * 5;
			if (test->scripted)
			{
				random_index = (int)((test->script_start +
						(unsigned)call_index) % RPE_RANDOM_PATTERN_COUNT);
				random_value = bench486_runparticleeffect_script[random_index];
				expected_float = (float)(test->time +
						0.1 * (random_value % 5));
				if (Q_memcmp (&particle->die, &expected_float,
						sizeof(expected_float)) != 0)
				{
					bench486_runparticleeffect_state_reason = 8;
					return 0;
				}
				call_index++;
				random_index = (int)((test->script_start +
						(unsigned)call_index) % RPE_RANDOM_PATTERN_COUNT);
				random_value = bench486_runparticleeffect_script[random_index];
				base = (test->color & ~7) + (random_value & 7);
				if (particle->color != (byte)base)
				{
					bench486_runparticleeffect_state_reason = 9;
					return 0;
				}
			}
			for (axis = 0 ; axis < 3 ; axis++)
			{
				call_index++;
				if (test->scripted)
				{
					random_index = (int)((test->script_start +
							(unsigned)call_index) % RPE_RANDOM_PATTERN_COUNT);
					random_value = bench486_runparticleeffect_script[random_index];
					expected_float = org[axis] + ((random_value & 15) - 8);
					if (Q_memcmp (&particle->org[axis], &expected_float,
							sizeof(expected_float)) != 0)
					{
						bench486_runparticleeffect_state_reason = 10;
						return 0;
					}
				}
				expected_float = dir[axis] * 15;
			if (Q_memcmp (&particle->vel[axis], &expected_float,
						sizeof(expected_float)) != 0)
				{
					bench486_runparticleeffect_state_reason = 11;
					return 0;
			}
			}
		}
	}

	for (i = emitted ; i < test->free_count ; i++)
	{
		particle_t *expected_next;

		expected_next = i+1 < test->free_count ?
				&bench486_runparticleeffect_fixture.nodes[RPE_FREE_BASE+i+1] :
				NULL;
		if (bench486_runparticleeffect_fixture.nodes[RPE_FREE_BASE+i].next !=
				expected_next)
		{
			bench486_runparticleeffect_state_reason = 12;
			return 0;
		}
	}

	for (i = 0 ; i < RPE_GUARD_WORDS ; i++)
		if (bench486_runparticleeffect_fixture.before[i] != 0x5a5a5a5aU ||
				bench486_runparticleeffect_fixture.after[i] != 0xa5a5a5a5U)
		{
			bench486_runparticleeffect_state_reason = 13;
			return 0;
		}
	return 1;
}

static unsigned Bench486RunParticleEffectCall (void (*function)(void),
		const float *org, const float *dir, int color, int count)
{
	unsigned arguments[4];

	arguments[0] = (unsigned)org;
	arguments[1] = (unsigned)dir;
	arguments[2] = (unsigned)color;
	arguments[3] = (unsigned)count;
	return Bench486Call_asm486 (function, 4, arguments, NULL);
}

static unsigned Bench486RunParticleEffectRunSide (void (*function)(void),
		const bench486_runparticleeffect_case_t *test, const float *org,
		const float *dir, byte *snapshot, particle_t **active_result,
		particle_t **free_result, unsigned *rand_calls, unsigned *script_index,
		int *next_random, int *valid)
{
	unsigned abi;
	int time_unchanged;

	Bench486RunParticleEffectPrepare (test->free_count);
	cl.time = test->time;
	bench486_runparticleeffect_rand_probe = test->scripted ?
			Bench486RunParticleEffectScript : NULL;
	bench486_runparticleeffect_rand_calls = 0;
	bench486_runparticleeffect_script_index = test->script_start;
	srand (test->seed);
	abi = Bench486RunParticleEffectCall (function, org, dir, test->color,
			test->count);
	*rand_calls = bench486_runparticleeffect_rand_calls;
	*script_index = bench486_runparticleeffect_script_index;
	*next_random = test->scripted ?
			Bench486RunParticleEffectScriptPeek () : rand ();
	*active_result = active_particles;
	*free_result = free_particles;
	bench486_runparticleeffect_state_reason = 0;
	*valid = Bench486RunParticleEffectStateValid (test, org, dir);
	time_unchanged = Q_memcmp (&cl.time, (void *)&test->time,
			sizeof(test->time)) == 0;
	*valid = *valid && time_unchanged;
	Q_memcpy (snapshot, &bench486_runparticleeffect_fixture,
			sizeof(bench486_runparticleeffect_fixture));
	return abi;
}

static void Bench486RunParticleEffectCases (void)
{
	static const bench486_runparticleeffect_case_t cases[] = {
		{ "negative-count", -3, 4, 226, 21.125, 0x48620001U, 0, 1 },
		{ "empty-pool", 5, 0, 226, 21.250, 0x48620002U, 2, 1 },
		{ "one-impact", 1, 1, 226, 21.375, 0x48620003U, 7, 1 },
		{ "partial-impact", 7, 3, 226, 21.500, 0x48620004U, 11, 1 },
		{ "impact-extra-free-node", 4, 5, -9, 21.625, 0x48620005U, 16, 1 },
		{ "rocket-one", 1024, 1, 17, 21.750, 0x48620006U, 4, 1 },
		{ "rocket-partial", 1024, 37, 17, 21.875, 0x48620007U, 9, 1 },
		{ "rocket-almost-full", 1024, 1023, 17, 22.000, 0x48620008U, 1, 1 },
		{ "rocket-full", 1024, 1024, 17, 22.125, 0x48620009U, 13, 1 },
		{ "rocket-extra-free-node", 1024, 1025, 17, 22.250, 0x4862000aU, 6, 1 },
		{ "libc-impact-continuation", 8, 6, 226, 22.375, 0x4862000bU, 0, 0 },
		{ "libc-rocket-continuation", 1024, 5, 17, 22.500, 0x4862000cU, 0, 0 }
	};
	static const float org[3] = { -123.25f, 8.5f, 1024.75f };
	static const float dir[3] = { 0.125f, -2.5f, 3.75f };
	particle_t *saved_active, *saved_free;
	double saved_time;
	int (*saved_probe) (void);
	unsigned saved_rand_calls, saved_script_index;
	particle_t *c_active, *c_free, *a_active, *a_free;
	unsigned c_abi, a_abi, c_calls, a_calls, c_script, a_script;
	int c_next, a_next, c_valid, a_valid;
	int i, failures, emitted, expected_calls, results_equal;

	saved_active = active_particles;
	saved_free = free_particles;
	Q_memcpy (&saved_time, &cl.time, sizeof(saved_time));
	saved_probe = bench486_runparticleeffect_rand_probe;
	saved_rand_calls = bench486_runparticleeffect_rand_calls;
	saved_script_index = bench486_runparticleeffect_script_index;
	failures = 0;
	Bench486Printf ("run-particle-effect C/ASM begin (%d cases)\n",
			(int)(sizeof(cases)/sizeof(cases[0])));

	for (i = 0 ; i < (int)(sizeof(cases)/sizeof(cases[0])) ; i++)
	{
		Bench486Printf ("run-particle-effect %d/%d %s\n", i+1,
				(int)(sizeof(cases)/sizeof(cases[0])), cases[i].name);
		c_abi = Bench486RunParticleEffectRunSide (
				(void (*)(void))R_RunParticleEffect_C, &cases[i], org, dir,
				bench486_runparticleeffect_reference, &c_active, &c_free,
				&c_calls, &c_script, &c_next, &c_valid);
		a_abi = Bench486RunParticleEffectRunSide (
				(void (*)(void))R_RunParticleEffect_asm486, &cases[i], org, dir,
				(byte *)&bench486_runparticleeffect_fixture, &a_active, &a_free,
				&a_calls, &a_script, &a_next, &a_valid);
		emitted = cases[i].count > 0 ? cases[i].count : 0;
		if (emitted > cases[i].free_count)
			emitted = cases[i].free_count;
		expected_calls = emitted * (cases[i].count == 1024 ? 7 : 5);
		results_equal = c_abi == 0 && a_abi == 0 && c_valid && a_valid &&
				c_active == a_active && c_free == a_free &&
				c_calls == (unsigned)expected_calls &&
				a_calls == (unsigned)expected_calls && c_script == a_script &&
				c_next == a_next && Q_memcmp(
					bench486_runparticleeffect_reference,
					&bench486_runparticleeffect_fixture,
					sizeof(bench486_runparticleeffect_fixture)) == 0;
		if (cases[i].scripted)
			results_equal = results_equal && c_script ==
					cases[i].script_start + (unsigned)expected_calls;
		if (!results_equal)
		{
			failures++;
			Bench486Printf ("run-particle-effect case %s FAIL c-abi %u a-abi %u c-valid %d(%d) a-valid %d(%d) c-rand %u a-rand %u expected %d c-next %d a-next %d\n",
					cases[i].name, c_abi, a_abi, c_valid,
					bench486_runparticleeffect_state_reason, a_valid,
					bench486_runparticleeffect_state_reason, c_calls, a_calls,
					expected_calls, c_next, a_next);
		}
		else
			Bench486Printf ("run-particle-effect case %s PASS (%d emitted, %d RNG calls)\n",
					cases[i].name, emitted, expected_calls);
	}

	active_particles = saved_active;
	free_particles = saved_free;
	Q_memcpy (&cl.time, &saved_time, sizeof(saved_time));
	bench486_runparticleeffect_rand_probe = saved_probe;
	bench486_runparticleeffect_rand_calls = saved_rand_calls;
	bench486_runparticleeffect_script_index = saved_script_index;
	Bench486Printf ("run-particle-effect C/ASM %s (%d failures)\n",
			failures ? "FAIL" : "PASS", failures);
	if (failures)
		bench486_memory_failures++;
}

#endif /* ASM486_RUN_PARTICLE_EFFECT */

#endif /* BENCH486_RUNPARTICLEEFFECT_H */
