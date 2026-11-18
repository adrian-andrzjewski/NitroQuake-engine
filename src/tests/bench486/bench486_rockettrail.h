/* Exact C-oracle versus i486 state, ABI, and RNG coverage for R_RocketTrail. */
/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
#ifndef BENCH486_ROCKETTRAIL_H
#define BENCH486_ROCKETTRAIL_H

#ifdef ASM486_ROCKET_TRAIL

#include <limits.h>
#include <stdlib.h>

#define RT_GUARD_WORDS 8
#define RT_FREE_BASE 1
#define RT_FREE_LIMIT 32
#define RT_ACTIVE_HEAD (RT_FREE_BASE + RT_FREE_LIMIT)
#define RT_ACTIVE_TAIL (RT_ACTIVE_HEAD + 1)
#define RT_NODE_COUNT (RT_ACTIVE_TAIL + 1)
#define RT_SCRIPT_COUNT 19

extern particle_t *active_particles, *free_particles;
extern int ramp3[8];
extern vec3_t vec3_origin;
extern int (*bench486_rockettrail_rand_probe) (void);
extern unsigned bench486_rockettrail_rand_calls;
extern int bench486_rockettrail_c_tracercount;
extern int bench486_rockettrail_asm_tracercount;
extern int Bench486RocketTrailRand (void);
extern void R_RocketTrail_C (vec3_t start, vec3_t end, int type);
extern void R_RocketTrail_asm486 (vec3_t start, vec3_t end, int type);
extern unsigned Bench486Call_asm486 (void (*function)(void), unsigned words,
		const unsigned *arguments, float *float_return);

typedef char bench486_rockettrail_pointer32[
		(sizeof(void *) == 4 && sizeof(int) == 4 && sizeof(unsigned) == 4) ?
		1 : -1];

typedef struct
{
	unsigned before[RT_GUARD_WORDS];
	particle_t nodes[RT_NODE_COUNT];
	unsigned after[RT_GUARD_WORDS];
} bench486_rockettrail_fixture_t;

typedef struct
{
	const char *name;
	float start[3];
	float end[3];
	int type;
	int free_count;
	int iterations;
	double time;
	unsigned seed;
	unsigned script_start;
	qboolean scripted;
	int tracer_before;
} bench486_rockettrail_case_t;

static bench486_rockettrail_fixture_t bench486_rockettrail_fixture;
static byte bench486_rockettrail_reference[sizeof(bench486_rockettrail_fixture)];
static float bench486_rockettrail_start[3];
static float bench486_rockettrail_end[3];
static unsigned bench486_rockettrail_script_index;

static const int bench486_rockettrail_script[RT_SCRIPT_COUNT] =
{
	0, 1, 5, 6, 3, -1, -5, -6, -7, 15, 16, 17, INT_MIN, INT_MAX, 2, 4, 9, 10, 11
};

static int Bench486RocketTrailScript (void)
{
	unsigned index;

	index = bench486_rockettrail_script_index % RT_SCRIPT_COUNT;
	bench486_rockettrail_script_index++;
	return bench486_rockettrail_script[index];
}

static int Bench486RocketTrailScriptPeek (void)
{
	return bench486_rockettrail_script[
			bench486_rockettrail_script_index % RT_SCRIPT_COUNT];
}

static int Bench486RocketTrailType (int type)
{
	return type >= 128 ? type - 128 : type;
}

static int Bench486RocketTrailRandCalls (int type, int emitted)
{
	type = Bench486RocketTrailType (type);
	if (type == 0 || type == 1 || type == 2 || type == 4 || type == 6)
		return emitted * 4;
	return 0;
}

static void Bench486RocketTrailPrepare (int free_count)
{
	int i;

	Q_memset (&bench486_rockettrail_fixture, 0x5a,
			sizeof(bench486_rockettrail_fixture));
	for (i = 0 ; i < RT_GUARD_WORDS ; i++)
	{
		bench486_rockettrail_fixture.before[i] = 0x5a5a5a5aU;
		bench486_rockettrail_fixture.after[i] = 0xa5a5a5a5U;
	}
	bench486_rockettrail_fixture.nodes[RT_ACTIVE_HEAD].next =
			&bench486_rockettrail_fixture.nodes[RT_ACTIVE_TAIL];
	bench486_rockettrail_fixture.nodes[RT_ACTIVE_TAIL].next = NULL;
	for (i = 0 ; i < free_count ; i++)
		bench486_rockettrail_fixture.nodes[RT_FREE_BASE+i].next =
				i+1 < free_count ?
				&bench486_rockettrail_fixture.nodes[RT_FREE_BASE+i+1] : NULL;
	active_particles =
			&bench486_rockettrail_fixture.nodes[RT_ACTIVE_HEAD];
	free_particles = free_count ?
			&bench486_rockettrail_fixture.nodes[RT_FREE_BASE] : NULL;
}

static int Bench486RocketTrailStateValid (
		const bench486_rockettrail_case_t *test, int emitted)
{
	int i, type, expected_color, expected_type;
	float expected_die;
	particle_t *expected_active, *expected_free;

	type = Bench486RocketTrailType (test->type);
	expected_free = test->free_count > emitted ?
			&bench486_rockettrail_fixture.nodes[RT_FREE_BASE+emitted] : NULL;
	expected_active = emitted ?
			&bench486_rockettrail_fixture.nodes[RT_FREE_BASE+emitted-1] :
			&bench486_rockettrail_fixture.nodes[RT_ACTIVE_HEAD];
	if (free_particles != expected_free || active_particles != expected_active ||
			bench486_rockettrail_fixture.nodes[RT_ACTIVE_HEAD].next !=
				&bench486_rockettrail_fixture.nodes[RT_ACTIVE_TAIL] ||
			bench486_rockettrail_fixture.nodes[RT_ACTIVE_TAIL].next != NULL)
		return 0;

	for (i = 0 ; i < emitted ; i++)
	{
		particle_t *p, *expected_next;
		byte *raw;
		int axis;

		p = &bench486_rockettrail_fixture.nodes[RT_FREE_BASE+i];
		expected_next = i ?
				&bench486_rockettrail_fixture.nodes[RT_FREE_BASE+i-1] :
				&bench486_rockettrail_fixture.nodes[RT_ACTIVE_HEAD];
		if (p->next != expected_next)
			return 0;
		raw = (byte *)p;
		if (raw[14] != 0x5a || raw[15] != 0x5a)
			return 0;

		if (type == 0 || type == 1)
		{
			expected_type = pt_fire;
			if (p->ramp < (float)(type ? 2 : 0) ||
					p->ramp > (float)(type ? 5 : 3) ||
					p->color != (byte)ramp3[(int)p->ramp])
				return 0;
		}
		else if (type == 2 || type == 4)
		{
			expected_type = pt_grav;
			if (p->color < 67 || p->color > 70 ||
					Q_memcmp (&p->ramp, "ZZZZ", 4))
				return 0;
		}
		else if (type == 3 || type == 5)
		{
			expected_type = pt_static;
			expected_color = (type == 3 ? 52 : 230) +
					(((test->tracer_before+i) & 4) << 1);
			if (p->color != (byte)expected_color ||
					Q_memcmp (&p->ramp, "ZZZZ", 4) ||
					Q_memcmp (&p->vel[2], &vec3_origin[2], sizeof(float)))
				return 0;
		}
		else if (type == 6)
		{
			expected_type = pt_static;
			if (p->color < 152 || p->color > 155 ||
					Q_memcmp (&p->ramp, "ZZZZ", 4))
				return 0;
		}
		else
		{
			expected_type = 0x5a;
			for (axis = 0 ; axis < sizeof(p->org) ; axis++)
				if (((byte *)p->org)[axis] != 0x5a)
					return 0;
			if (p->color != 0x5a || p->type != 0x5a ||
					Q_memcmp (&p->ramp, "ZZZZ", 4))
				return 0;
		}
		if (p->type != (byte)expected_type)
			return 0;

		expected_die = (float)(test->time + 2.0);
		if (type == 3 || type == 5)
			expected_die = (float)(test->time + 0.5);
		else if (type == 6)
			expected_die = (float)(test->time + 0.3);
		if (Q_memcmp (&p->die, &expected_die, sizeof(expected_die)))
			return 0;
	}

	for (i = emitted ; i < test->free_count ; i++)
	{
		particle_t *expected_next;

		expected_next = i+1 < test->free_count ?
				&bench486_rockettrail_fixture.nodes[RT_FREE_BASE+i+1] : NULL;
		if (bench486_rockettrail_fixture.nodes[RT_FREE_BASE+i].next !=
				expected_next)
			return 0;
	}

	for (i = 0 ; i < RT_GUARD_WORDS ; i++)
		if (bench486_rockettrail_fixture.before[i] != 0x5a5a5a5aU ||
				bench486_rockettrail_fixture.after[i] != 0xa5a5a5a5U)
			return 0;
	return 1;
}

static unsigned Bench486RocketTrailCall (void (*function)(void), int type)
{
	unsigned arguments[3];

	arguments[0] = (unsigned)bench486_rockettrail_start;
	arguments[1] = (unsigned)bench486_rockettrail_end;
	arguments[2] = (unsigned)type;
	return Bench486Call_asm486 (function, 3, arguments, NULL);
}

static unsigned Bench486RocketTrailRunSide (
		void (*function)(void), const bench486_rockettrail_case_t *test,
		byte *snapshot, particle_t **active_result, particle_t **free_result,
		float *start_result, float *end_result, unsigned *rand_calls,
		unsigned *script_index, int *next_random, int *valid, int assembly_side)
{
	float expected_start[3];
	float saved_origin[3];
	int i, emitted, type, axis_aligned, expected_tracercount;
	unsigned abi;
	double expected_time;

	Bench486RocketTrailPrepare (test->free_count);
	Q_memcpy (bench486_rockettrail_start, (void *)test->start, sizeof(test->start));
	Q_memcpy (bench486_rockettrail_end, (void *)test->end, sizeof(test->end));
	Q_memcpy (saved_origin, vec3_origin, sizeof(saved_origin));
	cl.time = test->time;
	bench486_rockettrail_rand_probe = test->scripted ?
			Bench486RocketTrailScript : NULL;
	bench486_rockettrail_rand_calls = 0;
	bench486_rockettrail_script_index = test->script_start;
	srand (test->seed);
	abi = Bench486RocketTrailCall (function, test->type);

	emitted = test->free_count < test->iterations ?
			test->free_count : test->iterations;
	*rand_calls = bench486_rockettrail_rand_calls;
	*script_index = bench486_rockettrail_script_index;
	*next_random = test->scripted ? Bench486RocketTrailScriptPeek () : rand ();
	*active_result = active_particles;
	*free_result = free_particles;
	Q_memcpy (start_result, bench486_rockettrail_start, sizeof(test->start));
	Q_memcpy (end_result, bench486_rockettrail_end, sizeof(test->end));
	*valid = Bench486RocketTrailStateValid (test, emitted);
	type = Bench486RocketTrailType (test->type);
	expected_tracercount = test->tracer_before;
	if (type == 3 || type == 5)
		expected_tracercount += emitted;
	if (assembly_side)
	{
		if (bench486_rockettrail_asm_tracercount != expected_tracercount)
			*valid = 0;
	}
	else if (bench486_rockettrail_c_tracercount != expected_tracercount)
		*valid = 0;

	expected_time = test->time;
	if (Q_memcmp (&cl.time, &expected_time, sizeof(expected_time)) ||
			Q_memcmp (saved_origin, vec3_origin, sizeof(saved_origin)) ||
			Q_memcmp (bench486_rockettrail_end, (void *)test->end, sizeof(test->end)))
		*valid = 0;

	axis_aligned =
			(test->start[1] == test->end[1] &&
			 test->start[2] == test->end[2]);
	if (axis_aligned)
	{
		Q_memcpy (expected_start, (void *)test->start, sizeof(expected_start));
		if (test->end[0] > test->start[0])
			expected_start[0] += (float)emitted;
		else if (test->end[0] < test->start[0])
			expected_start[0] -= (float)emitted;
		if (Q_memcmp (expected_start, bench486_rockettrail_start,
				sizeof(expected_start)))
			*valid = 0;
	}

	if (test->scripted)
	{
		if (*script_index != test->script_start + *rand_calls)
			*valid = 0;
	}
	if (*rand_calls != (unsigned)Bench486RocketTrailRandCalls (
			test->type, emitted))
		*valid = 0;
	Q_memcpy (snapshot, &bench486_rockettrail_fixture,
			sizeof(bench486_rockettrail_fixture));
	return abi;
}

/*
 * The C function and the assembly routine each own a private static tracer
 * counter. This sequence starts in a fresh process (both counters are zero),
 * runs C then assembly for each case with the same tracer history, and exits
 * via -benchexit so test calls cannot advance gameplay's tracer phase.
 */
static void Bench486RocketTrailCases (void)
{
	static const bench486_rockettrail_case_t cases[] = {
		{ "zero-length", {1,2,3}, {1,2,3}, 0, 0, 0, 20.125, 0x48670001U, 2, 1, 0 },
		{ "rocket-under-step", {0,1,2}, {2,1,2}, 0, 1, 1, 20.375, 0x48670002U, 4, 1, 0 },
		{ "smoke-exact-step", {0,0,0}, {3,0,0}, 1, 1, 1, 20.625, 0x48670003U, 0, 1, 0 },
		{ "blood-two-particles", {0,0,0}, {4,0,0}, 2, 2, 2, 20.875, 0x48670004U, 7, 1, 0 },
		{ "slight-blood-extra-step", {0,0,0}, {7,0,0}, 4, 2, 2, 21.125, 0x48670005U, 11, 1, 0 },
		{ "tracer-colors-and-directions", {0,0,0}, {18,24,0}, 3, 10, 10, 21.375, 0x48670006U, 1, 1, 0 },
		{ "tracer2-shared-counter", {1,2,3}, {4,6,3}, 5, 2, 2, 21.625, 0x48670007U, 5, 1, 10 },
		{ "tracer-exhaustion", {0,0,0}, {20,0,0}, 3, 1, 7, 21.875, 0x48670008U, 0, 1, 12 },
		{ "voor-mask-jitter", {0,0,0}, {2.5f,0,0}, 6, 1, 1, 22.125, 0x48670009U, 9, 1, 13 },
		{ "default-fields-retained", {0,0,0}, {4,0,0}, 7, 2, 2, 22.375, 0x4867000aU, 3, 1, 13 },
		{ "encoded-rocket-type", {0,0,0}, {2.25f,0,0}, 128, 3, 3, 22.625, 0x4867000bU, 14, 1, 13 },
		{ "encoded-slight-blood", {0,0,0}, {2.25f,0,0}, 132, 1, 1, 22.875, 0x4867000cU, 8, 1, 13 },
		{ "subtract-128-once", {0,0,0}, {2.25f,0,0}, 256, 3, 3, 23.125, 0x4867000dU, 6, 1, 13 },
		{ "negative-default-type", {5,0,0}, {0,0,0}, -1, 2, 2, 23.375, 0x4867000eU, 12, 1, 13 },
		{ "free-list-exhaustion", {0,0,0}, {20,0,0}, 0, 2, 7, 23.625, 0x4867000fU, 3, 1, 13 },
		{ "libc-rand-continuation", {0,0,0}, {1,0,0}, 2, 1, 1, 23.875, 0x48670010U, 0, 0, 13 }
	};
	particle_t *saved_active, *saved_free;
	double saved_time;
	vec3_t saved_origin;
	int saved_ramp3[8];
	int (*saved_probe) (void);
	int saved_c_tracercount, saved_asm_tracercount;
	unsigned saved_rand_calls, saved_script_index;
	particle_t *c_active, *c_free, *a_active, *a_free;
	float c_start[3], a_start[3], c_end[3], a_end[3];
	unsigned c_abi, a_abi, c_calls, a_calls, c_script, a_script;
	int c_next, a_next, c_valid, a_valid;
	int i, failures, emitted, expected_tracercount;

	saved_active = active_particles;
	saved_free = free_particles;
	Q_memcpy (&saved_time, &cl.time, sizeof(saved_time));
	Q_memcpy (saved_origin, vec3_origin, sizeof(saved_origin));
	Q_memcpy (saved_ramp3, ramp3, sizeof(saved_ramp3));
	saved_probe = bench486_rockettrail_rand_probe;
	saved_c_tracercount = bench486_rockettrail_c_tracercount;
	saved_asm_tracercount = bench486_rockettrail_asm_tracercount;
	saved_rand_calls = bench486_rockettrail_rand_calls;
	saved_script_index = bench486_rockettrail_script_index;
	failures = 0;
	expected_tracercount = 0;
	bench486_rockettrail_c_tracercount = 0;
	bench486_rockettrail_asm_tracercount = 0;
	Bench486Printf ("rocket-trail C/ASM begin (%d cases)\n",
			(int)(sizeof(cases)/sizeof(cases[0])));

	for (i = 0 ; i < (int)(sizeof(cases)/sizeof(cases[0])) ; i++)
	{
		Bench486Printf ("rocket-trail %d/%d %s\n", i+1,
				(int)(sizeof(cases)/sizeof(cases[0])), cases[i].name);
		if (cases[i].tracer_before != expected_tracercount)
			failures++;
		c_abi = Bench486RocketTrailRunSide (
				(void (*)(void))R_RocketTrail_C, &cases[i],
				bench486_rockettrail_reference, &c_active, &c_free,
				c_start, c_end, &c_calls, &c_script, &c_next, &c_valid, 0);
		a_abi = Bench486RocketTrailRunSide (
				(void (*)(void))R_RocketTrail_asm486, &cases[i],
				(byte *)&bench486_rockettrail_fixture, &a_active, &a_free,
				a_start, a_end, &a_calls, &a_script, &a_next, &a_valid, 1);
		emitted = cases[i].free_count < cases[i].iterations ?
				cases[i].free_count : cases[i].iterations;
		if (Bench486RocketTrailType (cases[i].type) == 3 ||
				Bench486RocketTrailType (cases[i].type) == 5)
			expected_tracercount += emitted;
		if (c_abi || a_abi || !c_valid || !a_valid ||
				c_calls != a_calls || c_script != a_script || c_next != a_next ||
				c_active != a_active || c_free != a_free ||
				Q_memcmp (c_start, a_start, sizeof(c_start)) ||
				Q_memcmp (c_end, a_end, sizeof(c_end)) ||
				Q_memcmp (bench486_rockettrail_reference,
						&bench486_rockettrail_fixture,
						sizeof(bench486_rockettrail_fixture)))
		{
			failures++;
			if (failures < 20)
				Bench486Printf (
						"rocket-trail FAIL %s ABI %x/%x calls %u/%u next %d/%d valid %d/%d\n",
						cases[i].name, c_abi, a_abi, c_calls, a_calls,
						c_next, a_next, c_valid, a_valid);
		}
	}

	active_particles = saved_active;
	free_particles = saved_free;
	Q_memcpy (&cl.time, &saved_time, sizeof(saved_time));
	Q_memcpy (vec3_origin, saved_origin, sizeof(saved_origin));
	Q_memcpy (ramp3, saved_ramp3, sizeof(saved_ramp3));
	bench486_rockettrail_c_tracercount = saved_c_tracercount;
	bench486_rockettrail_asm_tracercount = saved_asm_tracercount;
	bench486_rockettrail_rand_probe = saved_probe;
	bench486_rockettrail_rand_calls = saved_rand_calls;
	bench486_rockettrail_script_index = saved_script_index;
	bench486_memory_failures += failures;
	Bench486Printf ("rocket-trail C/ASM full-state and RNG continuation %s (%d cases; %d failures)\n",
			failures ? "FAIL" : "PASS",
			(int)(sizeof(cases)/sizeof(cases[0])), failures);
}

#endif /* ASM486_ROCKET_TRAIL */
#endif /* BENCH486_ROCKETTRAIL_H */
