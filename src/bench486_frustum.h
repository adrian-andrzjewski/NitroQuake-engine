/* Direct C/i486 parity fixture for R_TransformFrustum's numerical core. */
#ifndef BENCH486_FRUSTUM_H
#define BENCH486_FRUSTUM_H

#include "asm_frustum.h"

#define FR_BENCH_GUARD_WORDS 8
#define FR_BENCH_PLANES 4

typedef struct
{
	unsigned before[FR_BENCH_GUARD_WORDS];
	mplane_t value[FR_BENCH_PLANES];
	unsigned after[FR_BENCH_GUARD_WORDS];
} fr_bench_screen_t;

typedef struct
{
	unsigned before[FR_BENCH_GUARD_WORDS];
	clipplane_t value[FR_BENCH_PLANES];
	unsigned after[FR_BENCH_GUARD_WORDS];
} fr_bench_clip_t;

typedef struct
{
	unsigned before[FR_BENCH_GUARD_WORDS];
	float value[3];
	unsigned after[FR_BENCH_GUARD_WORDS];
} fr_bench_vector_t;

typedef struct
{
	fr_bench_screen_t screen;
	fr_bench_clip_t clip;
	fr_bench_vector_t origin;
	fr_bench_vector_t forward;
	fr_bench_vector_t right;
	fr_bench_vector_t up;
} fr_bench_state_t;

static fr_bench_state_t fr_bench_state;
static fr_bench_state_t fr_bench_initial;
static fr_bench_state_t fr_bench_c_result;
static fr_bench_state_t fr_bench_asm_result;
static clipplane_t fr_bench_public_c[FR_BENCH_PLANES];
static clipplane_t fr_bench_public_initial[FR_BENCH_PLANES];
static unsigned fr_bench_failures;

extern unsigned Bench486Call_asm486 (void (*function)(void), unsigned words,
		const unsigned *arguments, float *float_return);
extern void Bench486Printf (char *format, ...);

static float Bench486FrustumFloat (unsigned bits)
{
	union
	{
		unsigned bits;
		float value;
	} convert;

	convert.bits = bits;
	return convert.value;
}

static unsigned Bench486FrustumBits (float value)
{
	union
	{
		unsigned bits;
		float value;
	} convert;

	convert.value = value;
	return convert.bits;
}

static void Bench486FrustumSetGuard (unsigned *before, unsigned *after)
{
	unsigned i;

	for (i = 0; i < FR_BENCH_GUARD_WORDS; i++)
	{
		before[i] = 0x5a5a5a5aU;
		after[i] = 0xa5a5a5a5U;
	}
}

static int Bench486FrustumGuards (const fr_bench_state_t *state)
{
	unsigned i;

	for (i = 0; i < FR_BENCH_GUARD_WORDS; i++)
	{
#define FR_CHECK_GUARD(member) \
		if (state->member.before[i] != 0x5a5a5a5aU || \
				state->member.after[i] != 0xa5a5a5a5U) return 0
		FR_CHECK_GUARD(screen);
		FR_CHECK_GUARD(clip);
		FR_CHECK_GUARD(origin);
		FR_CHECK_GUARD(forward);
		FR_CHECK_GUARD(right);
		FR_CHECK_GUARD(up);
#undef FR_CHECK_GUARD
	}
	return 1;
}

static void Bench486FrustumInputs (unsigned sequence)
{
	static const unsigned value_bits[] = {
		0x00000000U, 0x80000000U, 0x3f800000U, 0xbf800000U,
		0x3f000000U, 0xbf000000U, 0x3eaaaaabU, 0xbeaaaaabU,
		0x00800000U, 0x00000001U, 0x7f7fffffU, 0xff7fffffU,
		0x4b800000U, 0xcb800000U, 0x322bcc77U, 0xb22bcc77U
	};
	unsigned i, j;
	unsigned value_count = sizeof(value_bits) / sizeof(value_bits[0]);

	Q_memset (&fr_bench_state, 0x5a, sizeof(fr_bench_state));
	Q_memset (&fr_bench_state.screen.value, 0,
			sizeof(fr_bench_state.screen.value));
	Q_memset (&fr_bench_state.clip.value, 0xc3,
			sizeof(fr_bench_state.clip.value));
	Bench486FrustumSetGuard (fr_bench_state.screen.before,
			fr_bench_state.screen.after);
	Bench486FrustumSetGuard (fr_bench_state.clip.before,
			fr_bench_state.clip.after);
	Bench486FrustumSetGuard (fr_bench_state.origin.before,
			fr_bench_state.origin.after);
	Bench486FrustumSetGuard (fr_bench_state.forward.before,
			fr_bench_state.forward.after);
	Bench486FrustumSetGuard (fr_bench_state.right.before,
			fr_bench_state.right.after);
	Bench486FrustumSetGuard (fr_bench_state.up.before,
			fr_bench_state.up.after);

	for (j = 0; j < 3; j++)
	{
		fr_bench_state.origin.value[j] = Bench486FrustumFloat (
				value_bits[(sequence * (j + 5) + j * 3) % value_count]);
		fr_bench_state.forward.value[j] = Bench486FrustumFloat (
				value_bits[(sequence * (j + 7) + j * 11 + 2) % value_count]);
		fr_bench_state.right.value[j] = Bench486FrustumFloat (
				value_bits[(sequence * (j + 9) + j * 13 + 4) % value_count]);
		fr_bench_state.up.value[j] = Bench486FrustumFloat (
				value_bits[(sequence * (j + 11) + j * 17 + 6) % value_count]);
	}

	for (i = 0; i < FR_BENCH_PLANES; i++)
	{
		for (j = 0; j < 3; j++)
			fr_bench_state.screen.value[i].normal[j] = Bench486FrustumFloat (
					value_bits[(sequence * 3 + i * 7 + j * 5 + 1) % value_count]);
		fr_bench_state.screen.value[i].dist = Bench486FrustumFloat (
				value_bits[(sequence * 13 + i * 9 + 3) % value_count]);
	}
}

static unsigned short Bench486FrustumStatus (void)
{
	unsigned short status;
	__asm__ __volatile__ ("fnstsw %0" : "=m" (status));
	return status;
}

static int Bench486FrustumStep (unsigned sequence)
{
	unsigned arguments[6], c_abi, asm_abi;
	unsigned short c_status, asm_status;
	int failed;

	Bench486FrustumInputs (sequence);
	Q_memcpy (&fr_bench_initial, &fr_bench_state, sizeof(fr_bench_state));
	arguments[0] = (unsigned)(size_t)&fr_bench_state.screen.value[0];
	arguments[1] = (unsigned)(size_t)&fr_bench_state.clip.value[0];
	arguments[2] = (unsigned)(size_t)&fr_bench_state.origin.value[0];
	arguments[3] = (unsigned)(size_t)&fr_bench_state.forward.value[0];
	arguments[4] = (unsigned)(size_t)&fr_bench_state.right.value[0];
	arguments[5] = (unsigned)(size_t)&fr_bench_state.up.value[0];

	__asm__ __volatile__ ("fnclex");
	c_abi = Bench486Call_asm486 ((void (*)(void))R_TransformFrustumCore_C,
			6, arguments, NULL);
	c_status = Bench486FrustumStatus ();
	Q_memcpy (&fr_bench_c_result, &fr_bench_state, sizeof(fr_bench_state));

	Q_memcpy (&fr_bench_state, &fr_bench_initial, sizeof(fr_bench_state));
	__asm__ __volatile__ ("fnclex");
	asm_abi = Bench486Call_asm486 (
			(void (*)(void))R_TransformFrustumCore_asm486,
			6, arguments, NULL);
	asm_status = Bench486FrustumStatus ();
	Q_memcpy (&fr_bench_asm_result, &fr_bench_state, sizeof(fr_bench_state));

	failed = c_abi || asm_abi || c_status != asm_status ||
			!Bench486FrustumGuards (&fr_bench_state) ||
			Q_memcmp (&fr_bench_initial.screen, &fr_bench_c_result.screen,
					sizeof(fr_bench_initial.screen)) ||
			Q_memcmp (&fr_bench_initial.origin, &fr_bench_c_result.origin,
					sizeof(fr_bench_initial.origin)) ||
			Q_memcmp (&fr_bench_initial.forward, &fr_bench_c_result.forward,
					sizeof(fr_bench_initial.forward)) ||
			Q_memcmp (&fr_bench_initial.right, &fr_bench_c_result.right,
					sizeof(fr_bench_initial.right)) ||
			Q_memcmp (&fr_bench_initial.up, &fr_bench_c_result.up,
					sizeof(fr_bench_initial.up)) ||
			Q_memcmp (&fr_bench_c_result, &fr_bench_asm_result,
					sizeof(fr_bench_state));
	if (failed)
	{
		fr_bench_failures++;
		if (fr_bench_failures < 20)
			Bench486Printf ("frustum core case %u FAIL ABI %x/%x x87 %x/%x guards %s\n",
					sequence, c_abi, asm_abi, c_status, asm_status,
					Bench486FrustumGuards (&fr_bench_state) ? "ok" : "bad");
		if (sequence == 0)
		{
			unsigned plane;
			for (plane = 0; plane < FR_BENCH_PLANES; plane++)
				Bench486Printf ("frustum plane %u C %08x %08x %08x %08x ASM %08x %08x %08x %08x\n",
						plane,
						Bench486FrustumBits (fr_bench_c_result.clip.value[plane].normal[0]),
						Bench486FrustumBits (fr_bench_c_result.clip.value[plane].normal[1]),
						Bench486FrustumBits (fr_bench_c_result.clip.value[plane].normal[2]),
						Bench486FrustumBits (fr_bench_c_result.clip.value[plane].dist),
						Bench486FrustumBits (fr_bench_asm_result.clip.value[plane].normal[0]),
						Bench486FrustumBits (fr_bench_asm_result.clip.value[plane].normal[1]),
						Bench486FrustumBits (fr_bench_asm_result.clip.value[plane].normal[2]),
						Bench486FrustumBits (fr_bench_asm_result.clip.value[plane].dist));
		}
	}
	return failed;
}

static int Bench486FrustumPublicStep (unsigned sequence)
{
	mplane_t saved_screen[FR_BENCH_PLANES];
	clipplane_t saved_clip[FR_BENCH_PLANES];
	float saved_origin[3], saved_forward[3], saved_right[3], saved_up[3];
	unsigned i, c_abi, asm_abi;
	unsigned short c_status, asm_status;
	int failed;

	Bench486FrustumInputs (sequence);
	Q_memcpy (saved_screen, screenedge, sizeof(saved_screen));
	Q_memcpy (saved_clip, view_clipplanes, sizeof(saved_clip));
	Q_memcpy (saved_origin, modelorg, sizeof(saved_origin));
	Q_memcpy (saved_forward, vpn, sizeof(saved_forward));
	Q_memcpy (saved_right, vright, sizeof(saved_right));
	Q_memcpy (saved_up, vup, sizeof(saved_up));
	Q_memcpy (screenedge, fr_bench_state.screen.value, sizeof(saved_screen));
	Q_memcpy (modelorg, fr_bench_state.origin.value, sizeof(saved_origin));
	Q_memcpy (vpn, fr_bench_state.forward.value, sizeof(saved_forward));
	Q_memcpy (vright, fr_bench_state.right.value, sizeof(saved_right));
	Q_memcpy (vup, fr_bench_state.up.value, sizeof(saved_up));
	for (i = 0; i < FR_BENCH_PLANES; i++)
		Q_memset (&view_clipplanes[i], 0xc3, sizeof(view_clipplanes[i]));
	Q_memcpy (fr_bench_public_initial, view_clipplanes,
			sizeof(fr_bench_public_initial));

	__asm__ __volatile__ ("fnclex");
	c_abi = Bench486Call_asm486 ((void (*)(void))R_TransformFrustum_C,
			0, NULL, NULL);
	c_status = Bench486FrustumStatus ();
	Q_memcpy (fr_bench_public_c, view_clipplanes,
			sizeof(fr_bench_public_c));
	Q_memcpy (view_clipplanes, fr_bench_public_initial,
			sizeof(fr_bench_public_initial));
	__asm__ __volatile__ ("fnclex");
	asm_abi = Bench486Call_asm486 ((void (*)(void))R_TransformFrustum,
			0, NULL, NULL);
	asm_status = Bench486FrustumStatus ();
	failed = c_abi || asm_abi || c_status != asm_status ||
			Q_memcmp (fr_bench_public_c, view_clipplanes,
					sizeof(fr_bench_public_c));

	Q_memcpy (screenedge, saved_screen, sizeof(saved_screen));
	Q_memcpy (view_clipplanes, saved_clip, sizeof(saved_clip));
	Q_memcpy (modelorg, saved_origin, sizeof(saved_origin));
	Q_memcpy (vpn, saved_forward, sizeof(saved_forward));
	Q_memcpy (vright, saved_right, sizeof(saved_right));
	Q_memcpy (vup, saved_up, sizeof(saved_up));
	if (failed)
	{
		fr_bench_failures++;
		if (fr_bench_failures < 20)
			Bench486Printf ("frustum public case %u FAIL ABI %x/%x x87 %x/%x\n",
					sequence, c_abi, asm_abi, c_status, asm_status);
	}
	return failed;
}

static void Bench486FrustumCases (void)
{
	static const unsigned short modes[12] = {
		0x007f, 0x047f, 0x087f, 0x0c7f, 0x027f, 0x067f,
		0x0a7f, 0x0e7f, 0x037f, 0x077f, 0x0b7f, 0x0f7f
	};
	unsigned short saved_cw, control;
	unsigned mode, pattern, step, cases;
	int old_failures;

	__asm__ __volatile__ ("fnstcw %0" : "=m" (saved_cw));
	old_failures = bench486_memory_failures;
	fr_bench_failures = 0;
	cases = 0;
	for (mode = 0; mode < 12; mode++)
	{
		Bench486Printf ("frustum transform x87 mode %u/12 begin\n", mode + 1);
		control = (saved_cw & ~0x0f00U) | (modes[mode] & 0x0f00U);
		__asm__ __volatile__ ("fldcw %0" : : "m" (control));
		for (pattern = 0; pattern < 128; pattern++)
		{
			Bench486FrustumStep (mode * 128U + pattern);
			cases++;
		}
	}

	Bench486Printf ("frustum transform continuous sequence begin\n");
	for (step = 0; step < 4096; step++)
	{
		if ((step & 511U) == 0)
			Bench486Printf ("frustum sequence progress %u/4096\n", step);
		Bench486FrustumStep (step * 0x9e3779b9U);
		cases++;
	}

	Bench486Printf ("frustum public-entry sequence begin\n");
	for (step = 0; step < 128; step++)
	{
		Bench486FrustumPublicStep (step * 0x85ebca6bU);
		cases++;
	}

	__asm__ __volatile__ ("fldcw %0" : : "m" (saved_cw));
	bench486_memory_failures += fr_bench_failures;
	Bench486Printf ("frustum transform C/ASM exact vectors, plane distances, x87 status, guards and ABI %s (%u cases; 12 control words; 4096 continuous calls; %u failures)\n",
			bench486_memory_failures == old_failures ? "PASS" : "FAIL",
			cases, fr_bench_failures);
}

#endif /* BENCH486_FRUSTUM_H */
