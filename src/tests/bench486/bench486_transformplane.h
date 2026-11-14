/* Direct C-oracle/assembly state and ABI coverage for R_TransformPlane. */
#ifndef BENCH486_TRANSFORMPLANE_H
#define BENCH486_TRANSFORMPLANE_H

#ifdef ASM486_TRANSFORM_PLANE

#include "renderer/asm_transformplane.h"

extern unsigned Bench486Call_asm486 (void (*function)(void), unsigned words,
		const unsigned *arguments, float *float_return);

#define TP_BENCH_GUARD_WORDS 8

typedef struct
{
	unsigned before[TP_BENCH_GUARD_WORDS];
	mplane_t plane;
	unsigned plane_after[TP_BENCH_GUARD_WORDS];
	unsigned output_before[TP_BENCH_GUARD_WORDS];
	float normal[3];
	float dist;
	unsigned output_after[TP_BENCH_GUARD_WORDS];
	unsigned after[TP_BENCH_GUARD_WORDS];
} bench486_transformplane_fixture_t;

typedef struct
{
	const char *name;
	float normal[3];
	float dist;
	float origin[3];
	float right[3];
	float up[3];
	float forward[3];
} bench486_transformplane_case_t;

static bench486_transformplane_fixture_t bench486_transformplane_fixture;
static bench486_transformplane_fixture_t bench486_transformplane_reference;
static mplane_t bench486_transformplane_expected_plane;

static const bench486_transformplane_case_t bench486_transformplane_cases[] = {
	{ "identity-positive", { 1.0f, 0.0f, 0.0f }, 5.0f,
		{ 2.0f, 3.0f, 4.0f }, { 1.0f, 0.0f, 0.0f },
		{ 0.0f, 1.0f, 0.0f }, { 0.0f, 0.0f, 1.0f } },
	{ "signed-oblique", { -2.5f, 0.75f, -4.0f }, -8.0f,
		{ -0.5f, 2.0f, 1.25f }, { 0.5f, -0.25f, 1.0f },
		{ -1.0f, 0.5f, 0.0f }, { 0.0f, -1.0f, 0.125f } },
	{ "positive-zero", { 0.0f, 0.0f, 0.0f }, 7.25f,
		{ 1.0f, 2.0f, 3.0f }, { 1.0f, 0.0f, 0.0f },
		{ 0.0f, 1.0f, 0.0f }, { 0.0f, 0.0f, 1.0f } },
	{ "signed-zero", { -0.0f, 0.0f, -0.0f }, -0.0f,
		{ 1.0f, -2.0f, 3.0f }, { -0.0f, 1.0f, -0.0f },
		{ 0.0f, -1.0f, 0.0f }, { -0.0f, 0.0f, 1.0f } },
	{ "cancel-and-round", { 1024.5f, -256.25f, 32.125f }, 128.5f,
		{ -0.25f, 0.5f, 2.0f }, { 0.125f, 0.5f, -1.0f },
		{ -0.5f, 0.25f, 0.75f }, { 1.0f, -0.125f, 0.5f } },
	{ "negative-distance", { 0.125f, -0.5f, 1.75f }, -16.0f,
		{ 8.0f, -4.0f, 0.25f }, { -1.0f, 0.0f, 0.25f },
		{ 0.5f, -0.75f, 0.0f }, { 0.0f, 1.0f, -0.5f } },
	{ "precision-sensitive-cancel", { 16777216.0f, 1.0f, -16777216.0f }, 10.0f,
		{ 1.0f, 1.0f, 1.0f }, { 1.0f, 0.0f, 0.0f },
		{ 0.0f, 1.0f, 0.0f }, { 0.0f, 0.0f, 1.0f } }
};

static void Bench486TransformPlaneSetGuards (void)
{
	int i;
	for (i = 0; i < TP_BENCH_GUARD_WORDS; i++)
	{
		bench486_transformplane_fixture.before[i] = 0x4a312f0dU;
		bench486_transformplane_fixture.plane_after[i] = 0x7b284e16U;
		bench486_transformplane_fixture.output_before[i] = 0x9531c84aU;
		bench486_transformplane_fixture.output_after[i] = 0x6d42a197U;
		bench486_transformplane_fixture.after[i] = 0xb26d0f48U;
	}
}

static void Bench486TransformPlanePrepare (
		const bench486_transformplane_case_t *test)
{
	Q_memset (&bench486_transformplane_fixture, 0x5a,
			sizeof(bench486_transformplane_fixture));
	Q_memset (&bench486_transformplane_fixture.plane, 0x3c,
			sizeof(bench486_transformplane_fixture.plane));
	Q_memcpy (bench486_transformplane_fixture.plane.normal, (void *)test->normal,
			sizeof(test->normal));
	bench486_transformplane_fixture.plane.dist = test->dist;
	Q_memcpy (&bench486_transformplane_expected_plane,
			&bench486_transformplane_fixture.plane,
			sizeof(bench486_transformplane_expected_plane));
	Q_memset (bench486_transformplane_fixture.normal, 0xa5,
			sizeof(bench486_transformplane_fixture.normal));
	Q_memset (&bench486_transformplane_fixture.dist, 0xa5,
			sizeof(bench486_transformplane_fixture.dist));
	Bench486TransformPlaneSetGuards ();
	Q_memcpy (r_origin, (void *)test->origin, sizeof(test->origin));
	Q_memcpy (vright, (void *)test->right, sizeof(test->right));
	Q_memcpy (vup, (void *)test->up, sizeof(test->up));
	Q_memcpy (vpn, (void *)test->forward, sizeof(test->forward));
}

static int Bench486TransformPlaneStateValid (
		const bench486_transformplane_case_t *test, int test_index)
{
	static const float axis_normal[3] = { 1.0f, 0.0f, 0.0f };
	static const float zero_normal[3] = { 0.0f, 0.0f, 0.0f };
	static const float axis_dist = 3.0f;
	static const float zero_dist = 7.25f;
	int i;

	if (Q_memcmp (&bench486_transformplane_fixture.plane,
			&bench486_transformplane_expected_plane,
			sizeof(bench486_transformplane_expected_plane)))
		return 0;
	if (Q_memcmp (r_origin, (void *)test->origin, sizeof(test->origin)) ||
			Q_memcmp (vright, (void *)test->right, sizeof(test->right)) ||
			Q_memcmp (vup, (void *)test->up, sizeof(test->up)) ||
			Q_memcmp (vpn, (void *)test->forward, sizeof(test->forward)))
		return 0;
	for (i = 0; i < TP_BENCH_GUARD_WORDS; i++)
		if (bench486_transformplane_fixture.before[i] != 0x4a312f0dU ||
				bench486_transformplane_fixture.plane_after[i] != 0x7b284e16U ||
				bench486_transformplane_fixture.output_before[i] != 0x9531c84aU ||
				bench486_transformplane_fixture.output_after[i] != 0x6d42a197U ||
				bench486_transformplane_fixture.after[i] != 0xb26d0f48U)
			return 0;

	/* These simple cases have independent, exact output values. */
	if (test_index == 0 &&
			(Q_memcmp (bench486_transformplane_fixture.normal, (void *)axis_normal,
				sizeof(axis_normal)) ||
			Q_memcmp (&bench486_transformplane_fixture.dist, (void *)&axis_dist,
				sizeof(axis_dist))))
		return 0;
	if (test_index == 2 &&
			(Q_memcmp (bench486_transformplane_fixture.normal, (void *)zero_normal,
				sizeof(zero_normal)) ||
			Q_memcmp (&bench486_transformplane_fixture.dist, (void *)&zero_dist,
				sizeof(zero_dist))))
		return 0;
	return 1;
}

static unsigned Bench486TransformPlaneCall (
		void (*function)(void), mplane_t *plane, float *normal, float *dist)
{
	unsigned arguments[3];
	arguments[0] = (unsigned)plane;
	arguments[1] = (unsigned)normal;
	arguments[2] = (unsigned)dist;
	return Bench486Call_asm486 (function, 3, arguments, NULL);
}

static void Bench486TransformPlaneCases (void)
{
	vec3_t saved_origin, saved_right, saved_up, saved_forward;
	int i, failures, c_valid, a_valid;
	unsigned c_abi, a_abi;

	Q_memcpy (saved_origin, r_origin, sizeof(saved_origin));
	Q_memcpy (saved_right, vright, sizeof(saved_right));
	Q_memcpy (saved_up, vup, sizeof(saved_up));
	Q_memcpy (saved_forward, vpn, sizeof(saved_forward));
	failures = 0;
	Bench486Printf ("transform-plane C/ASM begin (%d cases)\n",
			(int)(sizeof(bench486_transformplane_cases) /
			sizeof(bench486_transformplane_cases[0])));

	for (i = 0; i < sizeof(bench486_transformplane_cases) /
			sizeof(bench486_transformplane_cases[0]); i++)
	{
		const bench486_transformplane_case_t *test =
				&bench486_transformplane_cases[i];
		Bench486Printf ("transform-plane %d/%d %s\n", i + 1,
				(int)(sizeof(bench486_transformplane_cases) /
				sizeof(bench486_transformplane_cases[0])), test->name);
		Bench486TransformPlanePrepare (test);
		c_abi = Bench486TransformPlaneCall (
				(void (*)(void))R_TransformPlane_C,
				&bench486_transformplane_fixture.plane,
				bench486_transformplane_fixture.normal,
				&bench486_transformplane_fixture.dist);
		c_valid = Bench486TransformPlaneStateValid (test, i);
		Q_memcpy (&bench486_transformplane_reference,
				&bench486_transformplane_fixture,
				sizeof(bench486_transformplane_fixture));

		Bench486TransformPlanePrepare (test);
		a_abi = Bench486TransformPlaneCall (
				(void (*)(void))R_TransformPlane_asm486,
				&bench486_transformplane_fixture.plane,
				bench486_transformplane_fixture.normal,
				&bench486_transformplane_fixture.dist);
		a_valid = Bench486TransformPlaneStateValid (test, i);
		if (c_abi || a_abi || !c_valid || !a_valid ||
				Q_memcmp (&bench486_transformplane_reference,
						&bench486_transformplane_fixture,
						sizeof(bench486_transformplane_fixture)))
		{
			failures++;
			if (failures < 20)
				Bench486Printf ("transform-plane FAIL %s ABI %x/%x\n",
						test->name, c_abi, a_abi);
		}
	}

	Q_memcpy (r_origin, saved_origin, sizeof(saved_origin));
	Q_memcpy (vright, saved_right, sizeof(saved_right));
	Q_memcpy (vup, saved_up, sizeof(saved_up));
	Q_memcpy (vpn, saved_forward, sizeof(saved_forward));
	bench486_memory_failures += failures;
	Bench486Printf ("transform-plane exact output/state parity %s (%d cases; %d failures)\n",
			failures ? "FAIL" : "PASS",
			(int)(sizeof(bench486_transformplane_cases) /
			sizeof(bench486_transformplane_cases[0])), failures);
}

#endif /* ASM486_TRANSFORM_PLANE */
#endif /* BENCH486_TRANSFORMPLANE_H */
