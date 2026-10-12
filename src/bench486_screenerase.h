/* Direct SCR_EraseCenterString state, tile-clear trace and ABI parity. */
#ifndef BENCH486_SCREEN_ERASE_H
#define BENCH486_SCREEN_ERASE_H

#if defined(BENCH486) && defined(ASM486_SCREEN_ERASE_CENTER_STRING)

#define BSE_GUARD_WORDS 4

/* Assembly uses the trace hook only while its direct parity fixture runs. */
int bench486_screen_erase_fixture_active;

#include "asm_screenerase.h"

extern unsigned Bench486Call_asm486 (void (*function)(void), unsigned words,
		const unsigned *arguments, float *float_return);
extern viddef_t vid;
extern int scr_erase_center;
extern int scr_erase_lines;
extern int scr_copytop;
extern int scr_copyeverything;
extern int scr_center_lines;

typedef struct
{
	int x, y, width, height;
} bench486_screen_erase_tile_call_t;

typedef struct
{
	unsigned before[BSE_GUARD_WORDS];
	unsigned call_count;
	unsigned overflow;
	bench486_screen_erase_tile_call_t call;
	unsigned after[BSE_GUARD_WORDS];
} bench486_screen_erase_trace_t;

typedef struct
{
	viddef_t video;
	bench486_screen_erase_trace_t trace;
	int erase_center;
	int erase_lines;
	int copytop;
	int copyeverything;
	int center_lines;
	unsigned abi;
	unsigned short cw_before;
	unsigned short cw_after;
} bench486_screen_erase_result_t;

typedef struct
{
	const char *name;
	unsigned width;
	unsigned height;
	int numpages;
	int erase_center;
	int erase_lines;
	int copytop;
	int copyeverything;
	int center_lines;
	int active_path;
	int expected_y;
} bench486_screen_erase_case_t;

typedef struct
{
	byte bytes[28];
} bench486_screen_erase_x87_environment_t;

static bench486_screen_erase_trace_t bench486_screen_erase_trace;
static bench486_screen_erase_result_t bench486_screen_erase_reference;
static bench486_screen_erase_result_t bench486_screen_erase_candidate;
static viddef_t bench486_screen_erase_saved_video;
static viddef_t bench486_screen_erase_expected_video;
static int bench486_screen_erase_saved_erase_center;
static int bench486_screen_erase_saved_erase_lines;
static int bench486_screen_erase_saved_copytop;
static int bench486_screen_erase_saved_copyeverything;
static int bench486_screen_erase_saved_center_lines;
static unsigned short bench486_screen_erase_saved_cw;
static bench486_screen_erase_x87_environment_t bench486_screen_erase_saved_environment;

/* screen.c's C oracle and the assembly entry both route their one drawing call
   through this trace. The fixture deliberately compares the call boundary,
   since TileClear's separate implementation is shared by both paths. */
void Bench486ScreenEraseTileClear (int x, int y, int width, int height)
{
	if (bench486_screen_erase_trace.call_count == 0)
	{
		bench486_screen_erase_trace.call.x = x;
		bench486_screen_erase_trace.call.y = y;
		bench486_screen_erase_trace.call.width = width;
		bench486_screen_erase_trace.call.height = height;
	}
	else
		bench486_screen_erase_trace.overflow = 1;
	bench486_screen_erase_trace.call_count++;
}

static unsigned short Bench486ScreenEraseGetControlWord (void)
{
	unsigned short control_word;
	__asm__ __volatile__ ("fnstcw %0" : "=m" (control_word));
	return control_word;
}

static void Bench486ScreenEraseSetControlWord (unsigned short control_word)
{
	__asm__ __volatile__ ("fldcw %0" : : "m" (control_word));
}

static void Bench486ScreenEraseSaveEnvironment (
		bench486_screen_erase_x87_environment_t *environment)
{
	__asm__ __volatile__ ("fnstenv %0\n\tfldenv %0"
			: "=m" (*environment));
}

static void Bench486ScreenEraseRestoreEnvironment (
		const bench486_screen_erase_x87_environment_t *environment)
{
	__asm__ __volatile__ ("fldenv %0" : : "m" (*environment));
}

static void Bench486ScreenEraseInitTrace (void)
{
	unsigned i;
	Q_memset (&bench486_screen_erase_trace, 0,
			sizeof(bench486_screen_erase_trace));
	for (i = 0; i < BSE_GUARD_WORDS; i++)
	{
		bench486_screen_erase_trace.before[i] = 0x486e6100U + i;
		bench486_screen_erase_trace.after[i] = 0x5a13e900U + i;
	}
}

static void Bench486ScreenErasePrepare (
		const bench486_screen_erase_case_t *test_case)
{
	/* Keep the live console/video fields valid while the fixture runs. The
	   original version poisoned the whole viddef_t, which made diagnostic
	   output itself dependent on a zero console width. Only fields used by
	   SCR_EraseCenterString are varied; all others are guarded by parity. The
	   caller restores the live video dimensions before emitting diagnostics. */
	Q_memcpy (&vid, &bench486_screen_erase_saved_video, sizeof(vid));
	vid.width = test_case->width;
	vid.height = test_case->height;
	vid.numpages = test_case->numpages;
	Q_memcpy (&bench486_screen_erase_expected_video, &vid, sizeof(vid));
	scr_erase_center = test_case->erase_center;
	scr_erase_lines = test_case->erase_lines;
	scr_copytop = test_case->copytop;
	scr_copyeverything = test_case->copyeverything;
	scr_center_lines = test_case->center_lines;
	Bench486ScreenEraseInitTrace ();
}

static void Bench486ScreenEraseSaveState (void)
{
	Q_memcpy (&bench486_screen_erase_saved_video, &vid, sizeof(vid));
	bench486_screen_erase_saved_erase_center = scr_erase_center;
	bench486_screen_erase_saved_erase_lines = scr_erase_lines;
	bench486_screen_erase_saved_copytop = scr_copytop;
	bench486_screen_erase_saved_copyeverything = scr_copyeverything;
	bench486_screen_erase_saved_center_lines = scr_center_lines;
	Bench486ScreenEraseSaveEnvironment (&bench486_screen_erase_saved_environment);
	bench486_screen_erase_saved_cw = Bench486ScreenEraseGetControlWord ();
}

static void Bench486ScreenEraseRestoreState (void)
{
	Q_memcpy (&vid, &bench486_screen_erase_saved_video, sizeof(vid));
	scr_erase_center = bench486_screen_erase_saved_erase_center;
	scr_erase_lines = bench486_screen_erase_saved_erase_lines;
	scr_copytop = bench486_screen_erase_saved_copytop;
	scr_copyeverything = bench486_screen_erase_saved_copyeverything;
	scr_center_lines = bench486_screen_erase_saved_center_lines;
	Bench486ScreenEraseRestoreEnvironment (&bench486_screen_erase_saved_environment);
}

static void Bench486ScreenEraseCapture (
		bench486_screen_erase_result_t *result, unsigned abi,
		unsigned short cw_before, unsigned short cw_after)
{
	Q_memset (result, 0, sizeof(*result));
	Q_memcpy (&result->video, &vid, sizeof(vid));
	Q_memcpy (&result->trace, &bench486_screen_erase_trace,
			sizeof(result->trace));
	result->erase_center = scr_erase_center;
	result->erase_lines = scr_erase_lines;
	result->copytop = scr_copytop;
	result->copyeverything = scr_copyeverything;
	result->center_lines = scr_center_lines;
	result->abi = abi;
	result->cw_before = cw_before;
	result->cw_after = cw_after;
}

static int Bench486ScreenEraseGuardsIntact (void)
{
	unsigned i;
	for (i = 0; i < BSE_GUARD_WORDS; i++)
		if (bench486_screen_erase_trace.before[i] != 0x486e6100U + i ||
				bench486_screen_erase_trace.after[i] != 0x5a13e900U + i)
			return 0;
	return 1;
}

static unsigned Bench486ScreenEraseRun (
		const bench486_screen_erase_case_t *test_case,
		const char *implementation, void (*function)(void),
		bench486_screen_erase_result_t *result)
{
	unsigned abi;
	unsigned short cw_before, cw_after;

	Bench486ScreenErasePrepare (test_case);
	cw_before = Bench486ScreenEraseGetControlWord ();
	bench486_screen_erase_fixture_active = 1;
	abi = Bench486Call_asm486 (function, 0, NULL, NULL);
	bench486_screen_erase_fixture_active = 0;
	cw_after = Bench486ScreenEraseGetControlWord ();
	Bench486ScreenEraseCapture (result, abi, cw_before, cw_after);
	/* Con_Printf uses live video dimensions. Restore them before the fixture
	   reports parity or progress for a case using a synthetic mode. */
	Q_memcpy (&vid, &bench486_screen_erase_saved_video, sizeof(vid));
	if ((abi & 0x20U) || cw_before != cw_after)
	{
		Bench486Printf ("screen erase x87 CW FAIL case %s implementation %s before %04x after %04x probe %u\n",
				test_case->name, implementation, cw_before, cw_after, abi & 0x20U);
		return 1;
	}
	return (abi != 0) || bench486_screen_erase_trace.overflow ||
			!Bench486ScreenEraseGuardsIntact ();
}

static unsigned Bench486ScreenEraseDifference (
		const bench486_screen_erase_result_t *reference,
		const bench486_screen_erase_result_t *candidate)
{
	unsigned i;

	if (reference->abi != candidate->abi)
		return 0x10000001U;
	if (reference->cw_before != candidate->cw_before ||
			reference->cw_after != candidate->cw_after)
		return 0x10000002U;
	if (Q_memcmp ((void *)&reference->video, (void *)&candidate->video,
			sizeof(viddef_t)))
		return 0x10000003U;
	if (reference->erase_center != candidate->erase_center ||
			reference->erase_lines != candidate->erase_lines ||
			reference->copytop != candidate->copytop ||
			reference->copyeverything != candidate->copyeverything ||
			reference->center_lines != candidate->center_lines)
		return 0x10000004U;
	if (reference->trace.call_count != candidate->trace.call_count ||
			reference->trace.overflow != candidate->trace.overflow)
		return 0x10000005U;
	if (Q_memcmp ((void *)reference->trace.before,
			(void *)candidate->trace.before,
			sizeof(reference->trace.before)) ||
			Q_memcmp ((void *)reference->trace.after,
				(void *)candidate->trace.after,
				sizeof(reference->trace.after)))
		return 0x10000006U;
	for (i = 0; i < reference->trace.call_count && i < 1; i++)
		if (reference->trace.call.x != candidate->trace.call.x ||
				reference->trace.call.y != candidate->trace.call.y ||
				reference->trace.call.width != candidate->trace.call.width ||
				reference->trace.call.height != candidate->trace.call.height)
			return 0x40000000U | i;
	if (reference->trace.call_count > 1 || candidate->trace.call_count > 1)
		return 0x10000007U;
	return 0;
}

/* Pin the C oracle's documented boundary behavior as well as comparing the
   assembly result against it: an early exit preserves copytop and makes no
   tile-clear call; every active path calls TileClear, including height zero. */
static unsigned Bench486ScreenEraseExpected (
		const bench486_screen_erase_case_t *test_case,
		const bench486_screen_erase_result_t *result)
{
	if (result->erase_center != test_case->erase_center + 1)
		return 0x20000001U;
	if (result->erase_lines != (test_case->active_path ?
			test_case->erase_lines : 0))
		return 0x20000002U;
	if (result->copytop != (test_case->active_path ? 1 : test_case->copytop))
		return 0x20000003U;
	if (result->copyeverything != test_case->copyeverything ||
			result->center_lines != test_case->center_lines)
		return 0x20000004U;
	if (result->trace.call_count != (unsigned)test_case->active_path ||
			result->trace.overflow)
		return 0x20000005U;
	if (Q_memcmp ((void *)&result->video,
			(void *)&bench486_screen_erase_expected_video, sizeof(viddef_t)))
		return 0x20000006U;
	if (!Bench486ScreenEraseGuardsIntact ())
		return 0x20000007U;
	if (test_case->active_path &&
			(result->trace.call.x != 0 ||
			 (test_case->expected_y >= 0 &&
				result->trace.call.y != test_case->expected_y) ||
			 (unsigned)result->trace.call.width != test_case->width ||
			 result->trace.call.height != 8 * test_case->erase_lines))
		return 0x20000008U;
	return 0;
}

void Bench486ScreenEraseCenterCases (void)
{
	static const bench486_screen_erase_case_t cases[] = {
		{ "below-pages-four-lines-fractional", 320, 201, 2, 1, 3, 7, 9, 4, 1, 70 },
		{ "equal-pages-four-lines-zero-height", 640, 201, 2, 2, 0, 5, 11, 4, 1, 70 },
		{ "above-pages-five-lines", 640, 240, 2, 3, 4, 13, 17, 5, 0, 0 },
		{ "zero-pages-equal-five-lines", 320, 200, 0, 0, 2, 19, 23, 5, 1, 48 },
		{ "zero-pages-above-boundary", 321, 239, 0, 1, 6, 29, 31, 4, 0, 0 },
		{ "four-lines-with-zero-erase-height", 320, 199, 1, 1, 0, 37, 41, 4, 1, 69 },
		{ "unsigned-height-high-bit", 320, 0x80000001U, 1, 1, 2, 43, 47, 4, 1, -1 }
	};
	static const unsigned short rounding_bits[4] = { 0x0000, 0x0400, 0x0800, 0x0c00 };
	static const unsigned short precision_bits[3] = { 0x0000, 0x0200, 0x0300 };
	static const char *rounding_names[4] = { "nearest", "down", "up", "truncate" };
	static const char *precision_names[3] = { "single", "double", "extended" };
	unsigned case_index, precision, rounding, failures, difference, progress;
	unsigned short control_word;

	Bench486ScreenEraseSaveState ();
	failures = 0;
	progress = 0;
	Bench486Printf ("screen erase begin cases %u RC modes 4 PC modes 3\n",
			(unsigned)(sizeof(cases) / sizeof(cases[0])));
	Bench486Printf ("screen erase fixture state saved\n");
	for (case_index = 0; case_index < sizeof(cases) / sizeof(cases[0]); case_index++)
	{
		for (precision = 0; precision < 3; precision++)
		{
			for (rounding = 0; rounding < 4; rounding++)
			{
				control_word = (unsigned short)((bench486_screen_erase_saved_cw &
						(unsigned short)~0x0f00U) |
						precision_bits[precision] | rounding_bits[rounding]);
				Bench486ScreenEraseSetControlWord (control_word);
				Bench486Printf ("screen erase %u/252 %s PC=%s RC=%s C\n",
						++progress, cases[case_index].name,
						precision_names[precision], rounding_names[rounding]);
				failures += Bench486ScreenEraseRun (&cases[case_index], "C oracle",
						SCR_EraseCenterString_Screen_C,
						&bench486_screen_erase_reference);
				difference = Bench486ScreenEraseExpected (&cases[case_index],
						&bench486_screen_erase_reference);
				if (difference)
				{
					failures++;
					Bench486Printf ("screen erase C expected mismatch %s/%s/%s detail %u\n",
							cases[case_index].name, precision_names[precision],
							rounding_names[rounding], difference);
				}
				Bench486ScreenEraseSetControlWord (control_word);
				Bench486Printf ("screen erase %u/252 %s PC=%s RC=%s ASM\n",
						++progress, cases[case_index].name,
						precision_names[precision], rounding_names[rounding]);
				failures += Bench486ScreenEraseRun (&cases[case_index], "assembly",
						SCR_EraseCenterString_asm486,
						&bench486_screen_erase_candidate);
				difference = Bench486ScreenEraseDifference (
						&bench486_screen_erase_reference,
						&bench486_screen_erase_candidate);
				if (difference)
				{
					failures++;
					Bench486Printf ("screen erase mismatch %s/%s/%s detail %u\n",
							cases[case_index].name, precision_names[precision],
							rounding_names[rounding], difference);
				}
				Bench486ScreenEraseSetControlWord (control_word);
				Bench486Printf ("screen erase %u/252 %s PC=%s RC=%s PUBLIC\n",
						++progress, cases[case_index].name,
						precision_names[precision], rounding_names[rounding]);
				failures += Bench486ScreenEraseRun (&cases[case_index], "public entry",
						SCR_EraseCenterString,
						&bench486_screen_erase_candidate);
				difference = Bench486ScreenEraseDifference (
						&bench486_screen_erase_reference,
						&bench486_screen_erase_candidate);
				if (difference)
				{
					failures++;
					Bench486Printf ("screen erase public mismatch %s/%s/%s detail %u\n",
							cases[case_index].name, precision_names[precision],
							rounding_names[rounding], difference);
				}
			}
		}
	}
	Bench486ScreenEraseRestoreState ();
	bench486_memory_failures += failures;
	Bench486Printf ("screen erase end %s failures %u\n",
			failures ? "FAIL" : "PASS", failures);
}

#endif /* BENCH486 && ASM486_SCREEN_ERASE_CENTER_STRING */

#endif
