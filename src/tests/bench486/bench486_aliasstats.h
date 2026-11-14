/* Exact console-output fixture for src/renderer/r_misc.c:R_PrintAliasStats. */
#ifndef BENCH486_ALIASSTATS_H
#define BENCH486_ALIASSTATS_H

#include <stdio.h>

#define AS_FIXTURE_WIDTH       80
#define AS_FIXTURE_ROWS         8
#define AS_FIXTURE_GUARD_BYTES 32

extern int con_linewidth;
extern int con_current;
extern int con_x;
extern char *con_text;
extern float con_times[4];
extern qboolean con_debuglog;
extern int r_amodels_drawn;
extern void R_PrintAliasStats_C (void);
extern void R_PrintAliasStats_asm486 (void);

typedef struct
{
	byte before[AS_FIXTURE_GUARD_BYTES];
	byte text[AS_FIXTURE_WIDTH * AS_FIXTURE_ROWS];
	byte after[AS_FIXTURE_GUARD_BYTES];
} bench486_aliasstats_ring_t;

typedef struct
{
	bench486_aliasstats_ring_t ring;
	char *buffer_pointer;
	int current;
	int x;
	int backscroll;
	int linewidth;
	int totallines;
	float times[4];
	double realtime_value;
	int model_count;
	qboolean initialized;
	qboolean debuglog;
	cactive_t client_state;
	int signon;
	qboolean screen_disabled;
} bench486_aliasstats_result_t;

typedef struct
{
	int con_linewidth;
	int con_totallines;
	int con_backscroll;
	int con_current;
	int con_x;
	char *con_text;
	float con_times[4];
	qboolean con_initialized;
	qboolean con_debuglog;
	cactive_t cls_state;
	int cls_signon;
	qboolean scr_disabled_for_loading;
	double realtime_value;
	int model_count;
} bench486_aliasstats_saved_t;

typedef void (*bench486_aliasstats_fn_t) (void);

typedef struct
{
	const char *name;
	int model_count;
	int start_current;
} bench486_aliasstats_case_t;

static bench486_aliasstats_ring_t bench486_aliasstats_ring;

static void Bench486AliasStatsSave (bench486_aliasstats_saved_t *saved)
{
	saved->con_linewidth = con_linewidth;
	saved->con_totallines = con_totallines;
	saved->con_backscroll = con_backscroll;
	saved->con_current = con_current;
	saved->con_x = con_x;
	saved->con_text = con_text;
	Q_memcpy (saved->con_times, con_times, sizeof(saved->con_times));
	saved->con_initialized = con_initialized;
	saved->con_debuglog = con_debuglog;
	saved->cls_state = cls.state;
	saved->cls_signon = cls.signon;
	saved->scr_disabled_for_loading = scr_disabled_for_loading;
	saved->realtime_value = realtime;
	saved->model_count = r_amodels_drawn;
}

static void Bench486AliasStatsRestore (const bench486_aliasstats_saved_t *saved)
{
	con_linewidth = saved->con_linewidth;
	con_totallines = saved->con_totallines;
	con_backscroll = saved->con_backscroll;
	con_current = saved->con_current;
	con_x = saved->con_x;
	con_text = saved->con_text;
	/* Q_memcpy keeps its legacy non-const source signature. */
	Q_memcpy (con_times, (void *)saved->con_times, sizeof(saved->con_times));
	con_initialized = saved->con_initialized;
	con_debuglog = saved->con_debuglog;
	cls.state = saved->cls_state;
	cls.signon = saved->cls_signon;
	scr_disabled_for_loading = saved->scr_disabled_for_loading;
	realtime = saved->realtime_value;
	r_amodels_drawn = saved->model_count;
}

static void Bench486AliasStatsFillRing (void)
{
	unsigned i;

	for (i = 0 ; i < AS_FIXTURE_GUARD_BYTES ; i++)
	{
		bench486_aliasstats_ring.before[i] = (byte)(0x51U + i);
		bench486_aliasstats_ring.after[i] = (byte)(0xa1U + i);
	}
	for (i = 0 ; i < sizeof(bench486_aliasstats_ring.text) ; i++)
		bench486_aliasstats_ring.text[i] = (byte)(0x30U + (i * 29U) % 0x50U);
}

static void Bench486AliasStatsConfigure (int model_count, int start_current)
{
	unsigned i;

	Bench486AliasStatsFillRing ();
	con_linewidth = AS_FIXTURE_WIDTH;
	con_totallines = AS_FIXTURE_ROWS;
	con_backscroll = 5;
	con_current = start_current;
	con_x = 0;
	con_text = (char *)bench486_aliasstats_ring.text;
	for (i = 0 ; i < 4 ; i++)
		con_times[i] = (float)(10 + (int)i);
	con_initialized = true;
	con_debuglog = false;
	cls.state = ca_connected;
	cls.signon = SIGNONS;
	scr_disabled_for_loading = true;
	realtime = 123.25;
	r_amodels_drawn = model_count;
}

static void Bench486AliasStatsCapture (bench486_aliasstats_result_t *result)
{
	Q_memset (result, 0, sizeof(*result));
	Q_memcpy (&result->ring, &bench486_aliasstats_ring, sizeof(result->ring));
	result->buffer_pointer = con_text;
	result->current = con_current;
	result->x = con_x;
	result->backscroll = con_backscroll;
	result->linewidth = con_linewidth;
	result->totallines = con_totallines;
	Q_memcpy (result->times, con_times, sizeof(result->times));
	result->realtime_value = realtime;
	result->model_count = r_amodels_drawn;
	result->initialized = con_initialized;
	result->debuglog = con_debuglog;
	result->client_state = cls.state;
	result->signon = cls.signon;
	result->screen_disabled = scr_disabled_for_loading;
}

static int Bench486AliasStatsFirstDifference (
		const bench486_aliasstats_result_t *left,
		const bench486_aliasstats_result_t *right)
{
	unsigned i;
	const byte *left_bytes = (const byte *)left;
	const byte *right_bytes = (const byte *)right;

	for (i = 0 ; i < sizeof(*left) ; i++)
		if (left_bytes[i] != right_bytes[i])
			return (int)i;
	return -1;
}

static int Bench486AliasStatsGuardsIntact (
		const bench486_aliasstats_result_t *result)
{
	unsigned i;

	for (i = 0 ; i < AS_FIXTURE_GUARD_BYTES ; i++)
		if (result->ring.before[i] != (byte)(0x51U + i) ||
				result->ring.after[i] != (byte)(0xa1U + i))
			return 0;
	return 1;
}

/* Model the single output line independently of Con_Print's ring writes. */
static int Bench486AliasStatsBuildExpected (
		const bench486_aliasstats_result_t *baseline, int model_count,
		bench486_aliasstats_result_t *expected)
{
	char formatted[64];
	int i, length, row;

	/* Q_memcpy keeps its legacy non-const source signature. */
	Q_memcpy (expected, (void *)baseline, sizeof(*expected));
	length = sprintf (formatted, "%3i polygon model drawn\n", model_count);
	if (length <= 0 || length >= (int)sizeof(formatted) ||
			formatted[length - 1] != '\n')
		return 0;

	expected->current++;
	expected->backscroll = 0;
	expected->x = 0;
	row = expected->current % AS_FIXTURE_ROWS;
	Q_memset (&expected->ring.text[row * AS_FIXTURE_WIDTH], ' ',
			AS_FIXTURE_WIDTH);
	for (i = 0 ; i < length - 1 ; i++)
		expected->ring.text[row * AS_FIXTURE_WIDTH + i] = (byte)formatted[i];
	expected->times[expected->current % 4] = (float)expected->realtime_value;
	return 1;
}

static void Bench486AliasStatsRun (
		bench486_aliasstats_fn_t function, int model_count, int start_current,
		bench486_aliasstats_result_t *baseline,
		bench486_aliasstats_result_t *result)
{
	Bench486AliasStatsConfigure (model_count, start_current);

	/*
	 * Con_Print has private CR state. A newline at the start of each trial
	 * canonicalizes it, then the same initial ring/global state is used for
	 * both implementations. The call is safe because the console is redirected
	 * to this guarded ring, logging is disabled, and screen updates are gated.
	 */
	Con_Printf ("\n");
	Bench486AliasStatsCapture (baseline);
	function ();
	Bench486AliasStatsCapture (result);
}

static void Bench486AliasStatsCases (void)
{
	static const bench486_aliasstats_case_t cases[] =
	{
		{ "zero-wrap-0", 0, 0 },
		{ "single-digit-wrap-3", 7, 3 },
		{ "three-digit-wrap-7", 999, 7 },
		{ "negative-width-three", -99, 0 },
		{ "negative-width-four", -100, 7 },
		{ "negative-count", -42, 2 },
		{ "wide-positive-count", 12345, 6 },
		{ "signed-minimum", (-2147483647 - 1), 7 },
		{ "signed-maximum", 2147483647, 4 }
	};
	bench486_aliasstats_saved_t saved;
	bench486_aliasstats_result_t baseline_c, baseline_asm;
	bench486_aliasstats_result_t result_c, result_asm, expected;
	const char *first_failure_name = 0;
	int first_baseline_difference = -1, first_c_difference = -1;
	int first_asm_difference = -1, first_pair_difference = -1;
	int first_c_guards = 0, first_asm_guards = 0, first_expected_ok = 0;
	int first_c_pointer_ok = 0, first_asm_pointer_ok = 0;
	unsigned i, failures = 0;
	unsigned case_count = (unsigned)(sizeof(cases) / sizeof(cases[0]));

	Bench486Printf ("aliasstats fixture begin (%u cases; ring %dx%d)\n",
			case_count, AS_FIXTURE_WIDTH, AS_FIXTURE_ROWS);
	Bench486AliasStatsSave (&saved);
	for (i = 0 ; i < case_count ; i++)
	{
		int baseline_difference, c_difference, asm_difference, pair_difference;
		int c_guards, asm_guards, expected_ok;
		int c_pointer_ok, asm_pointer_ok;

		/* Keep progress on the real console, then save its post-message state. */
		Bench486AliasStatsRestore (&saved);
		Bench486Printf ("aliasstats %u/%u %s\n", i + 1, case_count,
				cases[i].name);
		Bench486AliasStatsSave (&saved);
		Bench486AliasStatsRun (R_PrintAliasStats_C,
				cases[i].model_count, cases[i].start_current,
				&baseline_c, &result_c);
		Bench486AliasStatsRun (R_PrintAliasStats_asm486,
				cases[i].model_count, cases[i].start_current,
				&baseline_asm, &result_asm);
		expected_ok = Bench486AliasStatsBuildExpected (&baseline_c,
				cases[i].model_count, &expected);
		baseline_difference = Bench486AliasStatsFirstDifference (
				&baseline_c, &baseline_asm);
		c_difference = Bench486AliasStatsFirstDifference (&result_c, &expected);
		asm_difference = Bench486AliasStatsFirstDifference (&result_asm, &expected);
		pair_difference = Bench486AliasStatsFirstDifference (&result_c, &result_asm);
		c_guards = Bench486AliasStatsGuardsIntact (&result_c);
		asm_guards = Bench486AliasStatsGuardsIntact (&result_asm);
		c_pointer_ok = result_c.buffer_pointer ==
				(char *)bench486_aliasstats_ring.text;
		asm_pointer_ok = result_asm.buffer_pointer ==
				(char *)bench486_aliasstats_ring.text;
		if (!expected_ok || baseline_difference >= 0 || c_difference >= 0 ||
				asm_difference >= 0 || pair_difference >= 0 ||
				!c_guards || !asm_guards || !c_pointer_ok || !asm_pointer_ok)
		{
			failures++;
			if (!first_failure_name)
			{
				first_failure_name = cases[i].name;
				first_baseline_difference = baseline_difference;
				first_c_difference = c_difference;
				first_asm_difference = asm_difference;
				first_pair_difference = pair_difference;
				first_c_guards = c_guards;
				first_asm_guards = asm_guards;
				first_expected_ok = expected_ok;
				first_c_pointer_ok = c_pointer_ok;
				first_asm_pointer_ok = asm_pointer_ok;
			}
		}
	}
	Bench486AliasStatsRestore (&saved);
	bench486_memory_failures += (int)failures;
	if (first_failure_name)
		Bench486Printf (
				"aliasstats %s FAIL baseline/C/ASM/pair %d/%d/%d/%d guards %d/%d pointers %d/%d expected %d\n",
				first_failure_name, first_baseline_difference, first_c_difference,
				first_asm_difference, first_pair_difference, first_c_guards,
				first_asm_guards, first_c_pointer_ok, first_asm_pointer_ok,
				first_expected_ok);
	Bench486Printf ("aliasstats exact console state %s (%u cases; %u failures)\n",
			failures ? "FAIL" : "PASS", case_count, failures);
}

#endif /* BENCH486_ALIASSTATS_H */
