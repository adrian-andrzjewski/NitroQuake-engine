/* Exact C-oracle versus i486 state/ABI coverage for TE_EXPLOSION2 particles. */
#ifndef BENCH486_PARTICLEEXPLOSION2_H
#define BENCH486_PARTICLEEXPLOSION2_H

#ifdef ASM486_PARTICLE_EXPLOSION2

#include <stdlib.h>

#define PE2_GUARD_WORDS 8
#define PE2_FREE_BASE   1
#define PE2_EMIT_LIMIT  512
#define PE2_FREE_MAX    (PE2_EMIT_LIMIT + 1)
#define PE2_ACTIVE_HEAD (PE2_FREE_BASE + PE2_FREE_MAX)
#define PE2_ACTIVE_TAIL (PE2_ACTIVE_HEAD + 1)
#define PE2_NODE_COUNT  (PE2_ACTIVE_TAIL + 1)

extern particle_t *active_particles, *free_particles;
extern void R_ParticleExplosion2_C (vec3_t org, int colorStart,
		int colorLength);
extern void R_ParticleExplosion2_asm486 (vec3_t org, int colorStart,
		int colorLength);

typedef char bench486_particleexplosion2_pointer32[
		(sizeof(void *) == 4 && sizeof(int) == 4 && sizeof(unsigned) == 4) ?
		1 : -1];

typedef struct
{
	unsigned before[PE2_GUARD_WORDS];
	particle_t nodes[PE2_NODE_COUNT];
	unsigned after[PE2_GUARD_WORDS];
} bench486_particleexplosion2_fixture_t;

typedef struct
{
	const char *name;
	int free_count;
	int color_start;
	int color_length;
	unsigned seed;
} bench486_particleexplosion2_case_t;

static bench486_particleexplosion2_fixture_t
		bench486_particleexplosion2_fixture;
static byte bench486_particleexplosion2_reference[
		sizeof(bench486_particleexplosion2_fixture)];

static void Bench486ParticleExplosion2Prepare (int free_count)
{
	int i;

	Q_memset (&bench486_particleexplosion2_fixture, 0x5a,
			sizeof(bench486_particleexplosion2_fixture));
	for (i=0 ; i<PE2_GUARD_WORDS ; i++)
	{
		bench486_particleexplosion2_fixture.before[i] = 0x5a5a5a5aU;
		bench486_particleexplosion2_fixture.after[i] = 0xa5a5a5a5U;
	}

	bench486_particleexplosion2_fixture.nodes[PE2_ACTIVE_HEAD].next =
			&bench486_particleexplosion2_fixture.nodes[PE2_ACTIVE_TAIL];
	bench486_particleexplosion2_fixture.nodes[PE2_ACTIVE_TAIL].next = NULL;
	for (i=0 ; i<free_count ; i++)
		bench486_particleexplosion2_fixture.nodes[PE2_FREE_BASE+i].next =
				i+1 < free_count ?
				&bench486_particleexplosion2_fixture.nodes[PE2_FREE_BASE+i+1] :
				NULL;

	active_particles = &bench486_particleexplosion2_fixture.nodes[
			PE2_ACTIVE_HEAD];
	free_particles = free_count ?
			&bench486_particleexplosion2_fixture.nodes[PE2_FREE_BASE] : NULL;
}

static int Bench486ParticleExplosion2StateValid (
		const bench486_particleexplosion2_case_t *test, float expected_die)
{
	int i, emitted;
	particle_t *expected_active;

	emitted = test->free_count < PE2_EMIT_LIMIT ?
		test->free_count : PE2_EMIT_LIMIT;
	if (free_particles != (test->free_count > emitted ?
			&bench486_particleexplosion2_fixture.nodes[
				PE2_FREE_BASE+emitted] : NULL))
		return 0;
	if (test->free_count > emitted &&
			bench486_particleexplosion2_fixture.nodes[
				PE2_FREE_BASE+emitted].next !=
			(test->free_count > emitted+1 ?
				&bench486_particleexplosion2_fixture.nodes[
					PE2_FREE_BASE+emitted+1] : NULL))
		return 0;
	expected_active = emitted ?
			&bench486_particleexplosion2_fixture.nodes[
				PE2_FREE_BASE+emitted-1] :
			&bench486_particleexplosion2_fixture.nodes[PE2_ACTIVE_HEAD];
	if (active_particles != expected_active)
		return 0;

	for (i=0 ; i<emitted ; i++)
	{
		particle_t *particle;
		particle_t *expected_next;
		byte expected_color;

		particle = &bench486_particleexplosion2_fixture.nodes[
				PE2_FREE_BASE+i];
		expected_next = i ?
				&bench486_particleexplosion2_fixture.nodes[
					PE2_FREE_BASE+i-1] :
				&bench486_particleexplosion2_fixture.nodes[PE2_ACTIVE_HEAD];
		expected_color = (byte)(test->color_start +
				(i % test->color_length));
		if (particle->next != expected_next || particle->type != pt_blob ||
				particle->color != expected_color ||
				Q_memcmp(&particle->die, &expected_die, sizeof(expected_die)))
			return 0;
	}

	for (i=0 ; i<PE2_GUARD_WORDS ; i++)
		if (bench486_particleexplosion2_fixture.before[i] != 0x5a5a5a5aU ||
				bench486_particleexplosion2_fixture.after[i] != 0xa5a5a5a5U)
			return 0;
	return 1;
}

static unsigned Bench486ParticleExplosion2Call (
		void (*function)(void), const float *org, int color_start, int color_length)
{
	unsigned arguments[3];

	arguments[0] = (unsigned)org;
	arguments[1] = (unsigned)color_start;
	arguments[2] = (unsigned)color_length;
	return Bench486Call_asm486 (function, 3, arguments, NULL);
}

/*
 * This fixture reseeds libc rand() for each side and leaves it advanced past
 * the generated particles. Run it in a disposable BENCH486 process so the
 * diagnostic cannot perturb a live gameplay random stream.
 */
static void Bench486ParticleExplosion2Cases (void)
{
	static const bench486_particleexplosion2_case_t cases[] = {
		{ "empty", 0,  12,  7, 0x48620001U },
		{ "single", 1, 250, 7, 0x48620002U },
		{ "short", 7,  42,  3, 0x48620003U },
		{ "almost-full", 511, 224, 6, 0x48620004U },
		{ "full-wrap", 512, 255, 255, 0x48620005U },
		{ "one-extra", 513, 17, 8, 0x48620006U }
	};
	static const float org[3] = { -123.25f, 8.5f, 1024.75f };
	particle_t *saved_active, *saved_free;
	double saved_time, test_time;
	float expected_die;
	particle_t *c_active, *c_free, *a_active, *a_free;
	unsigned c_abi, a_abi, c_next_rand, a_next_rand;
	int i, failures, c_valid, a_valid;

	saved_active = active_particles;
	saved_free = free_particles;
	Q_memcpy (&saved_time, &cl.time, sizeof(saved_time));
	failures = 0;
	Bench486Printf ("particle-explosion2 C/ASM begin (%d cases)\n",
			(int)(sizeof(cases)/sizeof(cases[0])));

	for (i=0 ; i<sizeof(cases)/sizeof(cases[0]) ; i++)
	{
		Bench486Printf ("particle-explosion2 %d/%d %s\n", i+1,
				(int)(sizeof(cases)/sizeof(cases[0])), cases[i].name);
		test_time = 23.125 + i * 0.5;
		expected_die = (float)(test_time + 0.3);
		cl.time = test_time;
		Bench486ParticleExplosion2Prepare (cases[i].free_count);
		srand (cases[i].seed);
		c_abi = Bench486ParticleExplosion2Call (
				(void (*)(void))R_ParticleExplosion2_C, org,
				cases[i].color_start, cases[i].color_length);
		c_next_rand = (unsigned)rand ();
		c_active = active_particles;
		c_free = free_particles;
		c_valid = Bench486ParticleExplosion2StateValid (&cases[i],
				expected_die);
		Q_memcpy (bench486_particleexplosion2_reference,
				&bench486_particleexplosion2_fixture,
				sizeof(bench486_particleexplosion2_fixture));

		cl.time = test_time;
		Bench486ParticleExplosion2Prepare (cases[i].free_count);
		srand (cases[i].seed);
		a_abi = Bench486ParticleExplosion2Call (
				(void (*)(void))R_ParticleExplosion2_asm486, org,
				cases[i].color_start, cases[i].color_length);
		a_next_rand = (unsigned)rand ();
		a_active = active_particles;
		a_free = free_particles;
		a_valid = Bench486ParticleExplosion2StateValid (&cases[i],
				expected_die);

		if (c_abi || a_abi || c_next_rand != a_next_rand || !c_valid ||
				!a_valid || c_active != a_active || c_free != a_free ||
				Q_memcmp(bench486_particleexplosion2_reference,
						&bench486_particleexplosion2_fixture,
						sizeof(bench486_particleexplosion2_fixture)))
		{
			failures++;
			if (failures < 20)
				Bench486Printf ("particle-explosion2 FAIL %s ABI %x/%x RNG %u/%u\n",
						cases[i].name, c_abi, a_abi, c_next_rand, a_next_rand);
		}
	}

	active_particles = saved_active;
	free_particles = saved_free;
	Q_memcpy (&cl.time, &saved_time, sizeof(saved_time));
	bench486_memory_failures += failures;
	Bench486Printf ("particle-explosion2 C/ASM full-state parity %s (%d cases; %d failures)\n",
			failures ? "FAIL" : "PASS",
			(int)(sizeof(cases)/sizeof(cases[0])), failures);
}

#endif /* ASM486_PARTICLE_EXPLOSION2 */
#endif /* BENCH486_PARTICLEEXPLOSION2_H */
