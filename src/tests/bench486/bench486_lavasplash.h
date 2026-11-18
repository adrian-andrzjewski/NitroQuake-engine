/* Exact C-oracle versus i486 state/RNG coverage for TE_LAVASPLASH particles. */
/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
#ifndef BENCH486_LAVASPLASH_H
#define BENCH486_LAVASPLASH_H

#ifdef ASM486_LAVA_SPLASH

#include <limits.h>
#include <stddef.h>
#include <stdlib.h>

#define LS_GUARD_WORDS 8
#define LS_FREE_BASE 1
#define LS_EMIT_LIMIT 1024
#define LS_FREE_MAX (LS_EMIT_LIMIT + 1)
#define LS_ACTIVE_HEAD (LS_FREE_BASE + LS_FREE_MAX)
#define LS_ACTIVE_TAIL (LS_ACTIVE_HEAD + 1)
#define LS_NODE_COUNT (LS_ACTIVE_TAIL + 1)
#define LS_RANDOM_PATTERN_COUNT 19

extern particle_t *active_particles, *free_particles;
extern int (*bench486_lavasplash_rand_probe) (void);
extern unsigned bench486_lavasplash_rand_calls;
extern void R_LavaSplash_C (vec3_t org);
extern void R_LavaSplash_asm486 (vec3_t org);
extern unsigned Bench486Call_asm486 (void (*function)(void), unsigned words,
		const unsigned *arguments, float *float_return);

typedef char bench486_lavasplash_pointer32[
		(sizeof(void *) == 4 && sizeof(int) == 4 && sizeof(unsigned) == 4) ?
		1 : -1];
typedef char bench486_lavasplash_layout[
		(offsetof(particle_t, org) == 0 &&
		offsetof(particle_t, color) == 12 &&
		offsetof(particle_t, type) == 13 &&
		offsetof(particle_t, next) == 16 &&
		offsetof(particle_t, vel) == 20 &&
		offsetof(particle_t, ramp) == 32 &&
		offsetof(particle_t, die) == 36 && sizeof(particle_t) == 40 &&
		offsetof(client_state_t, time) == 572 &&
		sizeof(((client_state_t *)0)->time) == 8 && pt_slowgrav == 2) ?
		1 : -1];

typedef struct
{
	unsigned before[LS_GUARD_WORDS];
	particle_t nodes[LS_NODE_COUNT];
	unsigned after[LS_GUARD_WORDS];
} bench486_lavasplash_fixture_t;

typedef struct
{
	const char *name;
	int free_count;
	double time;
	unsigned seed;
	unsigned script_start;
	qboolean scripted;
} bench486_lavasplash_case_t;

static bench486_lavasplash_fixture_t bench486_lavasplash_fixture;
static byte bench486_lavasplash_reference[
		sizeof(bench486_lavasplash_fixture)];
static unsigned bench486_lavasplash_script_index;
static int bench486_lavasplash_state_reason;

/* Mask-oriented values exercise signed bit patterns while remaining defined. */
static const int bench486_lavasplash_script[LS_RANDOM_PATTERN_COUNT] =
{
	0, 1, 7, 8, 31, 32, 63, 64, 127, 255, 511, 1023,
	-1, -2, -7, -32, -63, INT_MIN, INT_MAX
};

static int Bench486LavaSplashScript (void)
{
	unsigned index;

	index = bench486_lavasplash_script_index % LS_RANDOM_PATTERN_COUNT;
	bench486_lavasplash_script_index++;
	return bench486_lavasplash_script[index];
}

static int Bench486LavaSplashScriptPeek (void)
{
	return bench486_lavasplash_script[
			bench486_lavasplash_script_index % LS_RANDOM_PATTERN_COUNT];
}

static void Bench486LavaSplashPrepare (int free_count)
{
	int i;

	Q_memset (&bench486_lavasplash_fixture, 0x5a,
			sizeof(bench486_lavasplash_fixture));
	for (i = 0 ; i < LS_GUARD_WORDS ; i++)
	{
		bench486_lavasplash_fixture.before[i] = 0x5a5a5a5aU;
		bench486_lavasplash_fixture.after[i] = 0xa5a5a5a5U;
	}
	bench486_lavasplash_fixture.nodes[LS_ACTIVE_HEAD].next =
			&bench486_lavasplash_fixture.nodes[LS_ACTIVE_TAIL];
	bench486_lavasplash_fixture.nodes[LS_ACTIVE_TAIL].next = NULL;
	for (i = 0 ; i < free_count ; i++)
		bench486_lavasplash_fixture.nodes[LS_FREE_BASE+i].next =
				i+1 < free_count ?
				&bench486_lavasplash_fixture.nodes[LS_FREE_BASE+i+1] : NULL;

	active_particles = &bench486_lavasplash_fixture.nodes[LS_ACTIVE_HEAD];
	free_particles = free_count ?
			&bench486_lavasplash_fixture.nodes[LS_FREE_BASE] : NULL;
}

static int Bench486LavaSplashStateValid (
		const bench486_lavasplash_case_t *test, const float *org)
{
	int i, emitted, outer, inner, axis;
	particle_t *expected_active, *expected_free;

	emitted = test->free_count < LS_EMIT_LIMIT ?
		test->free_count : LS_EMIT_LIMIT;
	expected_free = test->free_count > emitted ?
			&bench486_lavasplash_fixture.nodes[LS_FREE_BASE+emitted] : NULL;
	expected_active = emitted ?
			&bench486_lavasplash_fixture.nodes[LS_FREE_BASE+emitted-1] :
			&bench486_lavasplash_fixture.nodes[LS_ACTIVE_HEAD];
	if (free_particles != expected_free || active_particles != expected_active ||
			bench486_lavasplash_fixture.nodes[LS_ACTIVE_HEAD].next !=
				&bench486_lavasplash_fixture.nodes[LS_ACTIVE_TAIL] ||
			bench486_lavasplash_fixture.nodes[LS_ACTIVE_TAIL].next != NULL)
	{
		bench486_lavasplash_state_reason = 1;
		return 0;
	}

	for (i = 0 ; i < emitted ; i++)
	{
		particle_t *particle, *expected_next;
		float dir[3], expected_org[3], expected_vel[3], expected_die, vel;
		unsigned actual_die_bits, expected_die_bits;
		int random_index, random_value, expected_color;

		particle = &bench486_lavasplash_fixture.nodes[LS_FREE_BASE+i];
		expected_next = i ?
				&bench486_lavasplash_fixture.nodes[LS_FREE_BASE+i-1] :
				&bench486_lavasplash_fixture.nodes[LS_ACTIVE_HEAD];
		if (particle->next != expected_next || particle->type != pt_slowgrav)
		{
			bench486_lavasplash_state_reason = 2;
			return 0;
		}

		outer = i / 32;
		inner = i % 32;
		if (test->scripted)
		{
			random_index = (int)((test->script_start + (unsigned)(i * 6)) %
					LS_RANDOM_PATTERN_COUNT);
			random_value = bench486_lavasplash_script[random_index];
			expected_die = (float)(test->time + 2 +
					(random_value & 31) * 0.02);
			/* Compare stored bytes: x87 excess precision can make `!=` lie. */
			if (Q_memcmp (&particle->die, &expected_die,
					sizeof(expected_die)) != 0)
			{
				bench486_lavasplash_state_reason = 3;
				if (test->free_count == 1 && i == 0)
				{
					Q_memcpy (&actual_die_bits, &particle->die,
							sizeof(actual_die_bits));
					Q_memcpy (&expected_die_bits, &expected_die,
							sizeof(expected_die_bits));
					Bench486Printf (
							"lava-splash die bits actual %08lx expected %08lx rand %d start %u\n",
							(unsigned long)actual_die_bits,
							(unsigned long)expected_die_bits, random_value,
							test->script_start);
				}
				return 0;
			}
			random_index = (random_index + 1) % LS_RANDOM_PATTERN_COUNT;
			expected_color = 224 +
					(bench486_lavasplash_script[random_index] & 7);
			if (particle->color != (byte)expected_color)
			{
				bench486_lavasplash_state_reason = 4;
				return 0;
			}

			random_index = (random_index + 1) % LS_RANDOM_PATTERN_COUNT;
			dir[0] = (-16 + inner) * 8 +
					(bench486_lavasplash_script[random_index] & 7);
			random_index = (random_index + 1) % LS_RANDOM_PATTERN_COUNT;
			dir[1] = (-16 + outer) * 8 +
					(bench486_lavasplash_script[random_index] & 7);
			dir[2] = 256;
			random_index = (random_index + 1) % LS_RANDOM_PATTERN_COUNT;
			expected_org[2] = org[2] +
					(bench486_lavasplash_script[random_index] & 63);
			random_index = (random_index + 1) % LS_RANDOM_PATTERN_COUNT;
			vel = 50 +
					(bench486_lavasplash_script[random_index] & 63);
			expected_org[0] = org[0] + dir[0];
			expected_org[1] = org[1] + dir[1];
			VectorNormalize (dir);
			VectorScale (dir, vel, expected_vel);
			if (Q_memcmp (particle->org, expected_org,
					sizeof(expected_org)) != 0)
			{
				bench486_lavasplash_state_reason = 5;
				return 0;
			}
			if (Q_memcmp (particle->vel, expected_vel,
					sizeof(expected_vel)) != 0)
			{
				bench486_lavasplash_state_reason = 6;
				return 0;
			}
		}
		else
		{
			if (particle->die < (float)(test->time + 2.0) ||
					particle->die > (float)(test->time + 2.62) ||
					particle->color < 224 || particle->color > 231)
			{
				bench486_lavasplash_state_reason = 7;
				return 0;
			}
			if (particle->org[0] < org[0] + (-16 + inner) * 8 ||
					particle->org[0] > org[0] + (-16 + inner) * 8 + 7 ||
					particle->org[1] < org[1] + (-16 + outer) * 8 ||
					particle->org[1] > org[1] + (-16 + outer) * 8 + 7 ||
					particle->org[2] < org[2] ||
					particle->org[2] > org[2] + 63)
			{
				bench486_lavasplash_state_reason = 8;
				return 0;
			}
			for (axis = 0 ; axis < 3 ; axis++)
				if (particle->vel[axis] < -113.0f ||
						particle->vel[axis] > 113.0f)
				{
					bench486_lavasplash_state_reason = 9;
					return 0;
				}
		}

		/* Keep ABI padding and the unused ramp field untouched. */
		if (((byte *)particle)[14] != 0x5a || ((byte *)particle)[15] != 0x5a ||
				((byte *)particle)[32] != 0x5a ||
				((byte *)particle)[33] != 0x5a ||
				((byte *)particle)[34] != 0x5a ||
				((byte *)particle)[35] != 0x5a)
		{
			bench486_lavasplash_state_reason = 10;
			return 0;
		}
	}

	for (i = emitted ; i < test->free_count ; i++)
	{
		particle_t *expected_next;

		expected_next = i+1 < test->free_count ?
				&bench486_lavasplash_fixture.nodes[LS_FREE_BASE+i+1] : NULL;
		if (bench486_lavasplash_fixture.nodes[LS_FREE_BASE+i].next !=
				expected_next)
		{
			bench486_lavasplash_state_reason = 11;
			return 0;
		}
	}

	for (i = 0 ; i < LS_GUARD_WORDS ; i++)
		if (bench486_lavasplash_fixture.before[i] != 0x5a5a5a5aU ||
				bench486_lavasplash_fixture.after[i] != 0xa5a5a5a5U)
		{
			bench486_lavasplash_state_reason = 12;
			return 0;
		}
	bench486_lavasplash_state_reason = 0;
	return 1;
}

static unsigned Bench486LavaSplashCall (
		void (*function)(void), const float *org)
{
	unsigned arguments[1];

	arguments[0] = (unsigned)org;
	return Bench486Call_asm486 (function, 1, arguments, NULL);
}

static unsigned Bench486LavaSplashRunSide (
		void (*function)(void), const bench486_lavasplash_case_t *test,
		const float *org, byte *snapshot, particle_t **active_result,
		particle_t **free_result, unsigned *rand_calls,
		unsigned *script_index, int *next_random, int *valid)
{
	unsigned abi;
	double time_after;

	Bench486LavaSplashPrepare (test->free_count);
	cl.time = test->time;
	bench486_lavasplash_rand_probe = test->scripted ?
			Bench486LavaSplashScript : NULL;
	bench486_lavasplash_rand_calls = 0;
	bench486_lavasplash_script_index = test->script_start;
	srand (test->seed);
	abi = Bench486LavaSplashCall (function, org);
	*rand_calls = bench486_lavasplash_rand_calls;
	*script_index = bench486_lavasplash_script_index;
	*next_random = test->scripted ? Bench486LavaSplashScriptPeek () : rand ();
	*active_result = active_particles;
	*free_result = free_particles;
	Q_memcpy (&time_after, &cl.time, sizeof(time_after));
	*valid = Bench486LavaSplashStateValid (test, org);
	if (Q_memcmp (&time_after, (void *)&test->time,
			sizeof(time_after)) != 0)
	{
		*valid = 0;
		bench486_lavasplash_state_reason = 13;
	}
	Q_memcpy (snapshot, &bench486_lavasplash_fixture,
			sizeof(bench486_lavasplash_fixture));
	return abi;
}

/*
 * The last case uses libc rand and checks the next value after the emitter.
 * BENCH486 runs this fixture with -benchexit because libc RNG state cannot be
 * restored by the C runtime. Scripted cases cover empty, partial, near-full,
 * exactly-full, and over-capacity free lists without relying on libc details.
 */
static void Bench486LavaSplashCases (void)
{
	static const bench486_lavasplash_case_t cases[] = {
		{ "empty", 0, 23.125, 0x48630001U, 3, 1 },
		{ "one", 1, 23.625, 0x48630002U, 8, 1 },
		{ "partial", 37, 24.125, 0x48630003U, 13, 1 },
		{ "almost-full", 1023, 24.625, 0x48630004U, 4, 1 },
		{ "full", 1024, 25.125, 0x48630005U, 0, 1 },
		{ "one-extra", 1025, 25.625, 0x48630006U, 7, 1 },
		{ "libc-rng-continuation", 19, 26.125, 0x48630007U, 0, 0 }
	};
	static const float org[3] = { -123.25f, 8.5f, 1024.75f };
	particle_t *saved_active, *saved_free;
	double saved_time;
	int (*saved_probe) (void);
	unsigned saved_rand_calls, saved_script_index;
	particle_t *c_active, *c_free, *a_active, *a_free;
	unsigned c_abi, a_abi, c_calls, a_calls, c_script, a_script;
	int c_next, a_next, c_valid, a_valid, c_reason, a_reason;
	int i, failures, emitted;

	saved_active = active_particles;
	saved_free = free_particles;
	Q_memcpy (&saved_time, &cl.time, sizeof(saved_time));
	saved_probe = bench486_lavasplash_rand_probe;
	saved_rand_calls = bench486_lavasplash_rand_calls;
	saved_script_index = bench486_lavasplash_script_index;
	failures = 0;
	Bench486Printf ("lava-splash C/ASM begin (%d cases)\n",
			(int)(sizeof(cases)/sizeof(cases[0])));

	for (i = 0 ; i < (int)(sizeof(cases)/sizeof(cases[0])) ; i++)
	{
		Bench486Printf ("lava-splash %d/%d %s\n", i+1,
				(int)(sizeof(cases)/sizeof(cases[0])), cases[i].name);
		c_abi = Bench486LavaSplashRunSide (
				(void (*)(void))R_LavaSplash_C, &cases[i], org,
				bench486_lavasplash_reference, &c_active, &c_free,
				&c_calls, &c_script, &c_next, &c_valid);
		c_reason = bench486_lavasplash_state_reason;
		a_abi = Bench486LavaSplashRunSide (
				(void (*)(void))R_LavaSplash_asm486, &cases[i], org,
				(byte *)&bench486_lavasplash_fixture, &a_active, &a_free,
				&a_calls, &a_script, &a_next, &a_valid);
		a_reason = bench486_lavasplash_state_reason;
		emitted = cases[i].free_count < LS_EMIT_LIMIT ?
				cases[i].free_count : LS_EMIT_LIMIT;
		if (c_abi || a_abi || c_calls != (unsigned)(emitted * 6) ||
				a_calls != (unsigned)(emitted * 6) || c_script != a_script ||
				c_next != a_next || !c_valid || !a_valid ||
				(cases[i].scripted &&
				 (c_script != cases[i].script_start + (unsigned)(emitted * 6) ||
				  a_script != cases[i].script_start + (unsigned)(emitted * 6))) ||
				c_active != a_active || c_free != a_free ||
				Q_memcmp (bench486_lavasplash_reference,
						&bench486_lavasplash_fixture,
						sizeof(bench486_lavasplash_fixture)))
		{
			failures++;
			if (failures < 20)
				Bench486Printf (
						"lava-splash FAIL %s ABI %x/%x calls %u/%u next %d/%d state %d/%d reason %d/%d\n",
						cases[i].name, c_abi, a_abi, c_calls, a_calls,
						c_next, a_next, c_valid, a_valid, c_reason, a_reason);
		}
	}

	active_particles = saved_active;
	free_particles = saved_free;
	Q_memcpy (&cl.time, &saved_time, sizeof(saved_time));
	bench486_lavasplash_rand_probe = saved_probe;
	bench486_lavasplash_rand_calls = saved_rand_calls;
	bench486_lavasplash_script_index = saved_script_index;
	bench486_memory_failures += failures;
	Bench486Printf (
			"lava-splash C/ASM full-state and RNG continuation %s (%d cases; %d failures)\n",
			failures ? "FAIL" : "PASS",
			(int)(sizeof(cases)/sizeof(cases[0])), failures);
}

#endif /* ASM486_LAVA_SPLASH */
#endif /* BENCH486 */
