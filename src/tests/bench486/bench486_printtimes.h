/* Deterministic console/state fixtures for R_PrintTimes and R_PrintDSpeeds. */
/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
#ifndef BENCH486_PRINTTIMES_H
#define BENCH486_PRINTTIMES_H

#include <stdio.h>

#define PT_FIXTURE_WIDTH       80
#define PT_FIXTURE_ROWS         8
#define PT_FIXTURE_GUARD_BYTES 32
#define PT_FIXTURE_CW      0x0c7f

extern int con_linewidth;
extern int con_current;
extern int con_x;
extern char *con_text;
extern float con_times[4];
extern qboolean con_debuglog;
extern float r_time1;
extern int c_faceclip;
extern int r_polycount;
extern int r_drawnpolycount;
extern int c_surf;
extern float dp_time1, dp_time2, rw_time1, rw_time2;
extern float db_time1, db_time2, se_time1, se_time2;
extern float de_time1, de_time2, dv_time1, dv_time2;
extern double (*bench486_printtimes_time_probe) (void);
extern void R_PrintTimes_C (void);
extern void R_PrintTimes_asm486 (void);
extern void R_PrintDSpeeds_C (void);
extern void R_PrintDSpeeds (void);

typedef struct
{
	byte before[PT_FIXTURE_GUARD_BYTES];
	byte text[PT_FIXTURE_WIDTH * PT_FIXTURE_ROWS];
	byte after[PT_FIXTURE_GUARD_BYTES];
} bench486_printtimes_ring_t;

typedef struct
{
	bench486_printtimes_ring_t ring;
	char *buffer_pointer;
	int current;
	int x;
	int backscroll;
	int linewidth;
	int totallines;
	float times[4];
	double realtime_value;
	float time1;
	int faceclip;
	int polycount;
	int drawnpolycount;
	int surf_count;
	float stage_times[12];
	unsigned timer_calls;
	unsigned abi_flags;
	unsigned short cw_before;
	unsigned short cw_after;
	unsigned short top_before;
	unsigned short top_after;
	unsigned stack_balanced;
	qboolean initialized;
	qboolean debuglog;
	cactive_t client_state;
	int signon;
	qboolean screen_disabled;
} bench486_printtimes_result_t;

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
	float time1;
	int faceclip;
	int polycount;
	int drawnpolycount;
	int surf_count;
	float stage_times[12];
	double (*time_probe) (void);
	unsigned short x87_cw;
} bench486_printtimes_saved_t;

typedef void (*bench486_printtimes_fn_t) (void);
extern unsigned Bench486Call_asm486 (bench486_printtimes_fn_t function,
		unsigned words, const unsigned *arguments, float *float_return);

typedef struct
{
	const char *name;
	float time1;
	double timer_value;
	int faceclip;
	int polycount;
	int drawnpolycount;
	int surf_count;
	int start_current;
	unsigned repeats;
	float stage_start[6];
	float stage_end[6];
} bench486_printtimes_case_t;

static bench486_printtimes_ring_t bench486_printtimes_ring;
static double bench486_printtimes_timer_value;
static unsigned bench486_printtimes_timer_calls;

static double Bench486PrintTimesFixedTimer (void)
{
	bench486_printtimes_timer_calls++;
	return bench486_printtimes_timer_value;
}

static void Bench486PrintTimesReadX87 (unsigned short *cw, unsigned short *sw)
{
	__asm__ __volatile__ ("fnstcw %0\n\tfnstsw %1"
			: "=m" (*cw), "=m" (*sw));
}

static void Bench486PrintTimesWriteX87CW (unsigned short cw)
{
	__asm__ __volatile__ ("fldcw %0" : : "m" (cw));
}

static void Bench486PrintTimesSave (bench486_printtimes_saved_t *saved)
{
	{
		unsigned short unused_status;
		Bench486PrintTimesReadX87 (&saved->x87_cw, &unused_status);
	}
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
	saved->time1 = r_time1;
	saved->faceclip = c_faceclip;
	saved->polycount = r_polycount;
	saved->drawnpolycount = r_drawnpolycount;
	saved->surf_count = c_surf;
	saved->stage_times[0] = dp_time1;
	saved->stage_times[1] = dp_time2;
	saved->stage_times[2] = rw_time1;
	saved->stage_times[3] = rw_time2;
	saved->stage_times[4] = db_time1;
	saved->stage_times[5] = db_time2;
	saved->stage_times[6] = se_time1;
	saved->stage_times[7] = se_time2;
	saved->stage_times[8] = de_time1;
	saved->stage_times[9] = de_time2;
	saved->stage_times[10] = dv_time1;
	saved->stage_times[11] = dv_time2;
	saved->time_probe = bench486_printtimes_time_probe;
}

static void Bench486PrintTimesRestore (const bench486_printtimes_saved_t *saved)
{
	con_linewidth = saved->con_linewidth;
	con_totallines = saved->con_totallines;
	con_backscroll = saved->con_backscroll;
	con_current = saved->con_current;
	con_x = saved->con_x;
	con_text = saved->con_text;
	Q_memcpy (con_times, (void *)saved->con_times, sizeof(saved->con_times));
	con_initialized = saved->con_initialized;
	con_debuglog = saved->con_debuglog;
	cls.state = saved->cls_state;
	cls.signon = saved->cls_signon;
	scr_disabled_for_loading = saved->scr_disabled_for_loading;
	realtime = saved->realtime_value;
	r_time1 = saved->time1;
	c_faceclip = saved->faceclip;
	r_polycount = saved->polycount;
	r_drawnpolycount = saved->drawnpolycount;
	c_surf = saved->surf_count;
	dp_time1 = saved->stage_times[0];
	dp_time2 = saved->stage_times[1];
	rw_time1 = saved->stage_times[2];
	rw_time2 = saved->stage_times[3];
	db_time1 = saved->stage_times[4];
	db_time2 = saved->stage_times[5];
	se_time1 = saved->stage_times[6];
	se_time2 = saved->stage_times[7];
	de_time1 = saved->stage_times[8];
	de_time2 = saved->stage_times[9];
	dv_time1 = saved->stage_times[10];
	dv_time2 = saved->stage_times[11];
	bench486_printtimes_time_probe = saved->time_probe;
	Bench486PrintTimesWriteX87CW (saved->x87_cw);
}

static void Bench486PrintTimesFillRing (void)
{
	unsigned i;

	for (i = 0 ; i < PT_FIXTURE_GUARD_BYTES ; i++)
	{
		bench486_printtimes_ring.before[i] = (byte)(0x53U + i);
		bench486_printtimes_ring.after[i] = (byte)(0xa3U + i);
	}
	for (i = 0 ; i < sizeof(bench486_printtimes_ring.text) ; i++)
		bench486_printtimes_ring.text[i] = (byte)(0x31U + (i * 31U) % 0x50U);
}

static void Bench486PrintTimesConfigure (const bench486_printtimes_case_t *test_case)
{
	Bench486PrintTimesFillRing ();
	con_linewidth = PT_FIXTURE_WIDTH;
	con_totallines = PT_FIXTURE_ROWS;
	con_backscroll = 5;
	con_current = test_case->start_current;
	con_x = 0;
	con_text = (char *)bench486_printtimes_ring.text;
	con_times[0] = 10.0f;
	con_times[1] = 11.0f;
	con_times[2] = 12.0f;
	con_times[3] = 13.0f;
	con_initialized = true;
	con_debuglog = false;
	cls.state = ca_connected;
	cls.signon = SIGNONS;
	scr_disabled_for_loading = true;
	realtime = 123.25;
	r_time1 = test_case->time1;
	c_faceclip = test_case->faceclip;
	r_polycount = test_case->polycount;
	r_drawnpolycount = test_case->drawnpolycount;
	c_surf = test_case->surf_count;
	dp_time1 = test_case->stage_start[0];
	rw_time1 = test_case->stage_start[1];
	db_time1 = test_case->stage_start[2];
	se_time1 = test_case->stage_start[3];
	de_time1 = test_case->stage_start[4];
	dv_time1 = test_case->stage_start[5];
	dp_time2 = test_case->stage_end[0];
	rw_time2 = test_case->stage_end[1];
	db_time2 = test_case->stage_end[2];
	se_time2 = test_case->stage_end[3];
	de_time2 = test_case->stage_end[4];
	dv_time2 = test_case->stage_end[5];
	bench486_printtimes_timer_value = test_case->timer_value;
	bench486_printtimes_timer_calls = 0;
	bench486_printtimes_time_probe = Bench486PrintTimesFixedTimer;
}

static void Bench486PrintTimesCapture (bench486_printtimes_result_t *result)
{
	Q_memset (result, 0, sizeof(*result));
	Q_memcpy (&result->ring, &bench486_printtimes_ring, sizeof(result->ring));
	result->buffer_pointer = con_text;
	result->current = con_current;
	result->x = con_x;
	result->backscroll = con_backscroll;
	result->linewidth = con_linewidth;
	result->totallines = con_totallines;
	Q_memcpy (result->times, con_times, sizeof(result->times));
	result->realtime_value = realtime;
	result->time1 = r_time1;
	result->faceclip = c_faceclip;
	result->polycount = r_polycount;
	result->drawnpolycount = r_drawnpolycount;
	result->surf_count = c_surf;
	result->stage_times[0] = dp_time1;
	result->stage_times[1] = dp_time2;
	result->stage_times[2] = rw_time1;
	result->stage_times[3] = rw_time2;
	result->stage_times[4] = db_time1;
	result->stage_times[5] = db_time2;
	result->stage_times[6] = se_time1;
	result->stage_times[7] = se_time2;
	result->stage_times[8] = de_time1;
	result->stage_times[9] = de_time2;
	result->stage_times[10] = dv_time1;
	result->stage_times[11] = dv_time2;
	result->timer_calls = bench486_printtimes_timer_calls;
	result->initialized = con_initialized;
	result->debuglog = con_debuglog;
	result->client_state = cls.state;
	result->signon = cls.signon;
	result->screen_disabled = scr_disabled_for_loading;
}

static int Bench486PrintTimesFirstDifference (
		const bench486_printtimes_result_t *left,
		const bench486_printtimes_result_t *right)
{
	unsigned i;
	const byte *left_bytes = (const byte *)left;
	const byte *right_bytes = (const byte *)right;

	for (i = 0 ; i < sizeof(*left) ; i++)
		if (left_bytes[i] != right_bytes[i])
			return (int)i;
	return -1;
}

static int Bench486PrintTimesGuardsIntact (
		const bench486_printtimes_result_t *result)
{
	unsigned i;

	for (i = 0 ; i < PT_FIXTURE_GUARD_BYTES ; i++)
		if (result->ring.before[i] != (byte)(0x53U + i) ||
				result->ring.after[i] != (byte)(0xa3U + i))
			return 0;
	return 1;
}

static int Bench486PrintTimesBuildExpected (
		const bench486_printtimes_result_t *baseline,
		const bench486_printtimes_result_t *observed,
		const bench486_printtimes_case_t *test_case,
		bench486_printtimes_result_t *expected)
{
	char formatted[96];
	float time2, ms;
	int i, length, row, surf;
	unsigned repeat;

	Q_memcpy (expected, (void *)baseline, sizeof(*expected));
	time2 = (float)test_case->timer_value;
	ms = 1000 * (time2 - test_case->time1);
	surf = test_case->surf_count;
	for (repeat = 0 ; repeat < test_case->repeats ; repeat++)
	{
		length = sprintf (formatted,
				"%5.1f ms %3i/%3i/%3i poly %3i surf\n",
				ms, test_case->faceclip, test_case->polycount,
				test_case->drawnpolycount, surf);
		if (length <= 0 || length >= (int)sizeof(formatted) ||
				formatted[length - 1] != '\n')
			return 0;
		expected->current++;
		expected->backscroll = 0;
		expected->x = 0;
		row = expected->current % PT_FIXTURE_ROWS;
		Q_memset (&expected->ring.text[row * PT_FIXTURE_WIDTH], ' ',
				PT_FIXTURE_WIDTH);
		for (i = 0 ; i < length - 1 ; i++)
			expected->ring.text[row * PT_FIXTURE_WIDTH + i] = (byte)formatted[i];
		expected->times[expected->current % 4] = (float)expected->realtime_value;
		expected->timer_calls++;
		expected->surf_count = 0;
		surf = 0;
	}
	expected->cw_before = observed->cw_before;
	expected->cw_after = observed->cw_before;
	expected->top_before = observed->top_before;
	expected->top_after = observed->top_before;
	expected->abi_flags = observed->abi_flags;
	expected->stack_balanced = 1;
	return 1;
}

static void Bench486PrintTimesInvoke (bench486_printtimes_fn_t function,
		unsigned short *cw_before, unsigned short *cw_after,
		unsigned short *top_before, unsigned short *top_after,
		unsigned *stack_balanced, unsigned *abi_flags_out)
{
	unsigned short before_status, after_status;
	unsigned short before_cw, before_top, after_cw, after_top;
	unsigned abi_flags;

	Bench486PrintTimesReadX87 (&before_cw, &before_status);
	before_top = (unsigned short)((before_status >> 11) & 7);
	abi_flags = Bench486Call_asm486 (function, 0, NULL, NULL);
	*abi_flags_out |= abi_flags;
	Bench486PrintTimesReadX87 (&after_cw, &after_status);
	after_top = (unsigned short)((after_status >> 11) & 7);
	if (*stack_balanced && *cw_before == 0)
	{
		*cw_before = before_cw;
		*top_before = before_top;
	}
	*cw_after = after_cw;
	*top_after = after_top;
	/* The assembly ABI probe checks callee ESP directly. Reading ESP in C
	 * around a cdecl call can observe arguments before caller cleanup. */
	*stack_balanced = *stack_balanced && !(abi_flags & 16) &&
			before_cw == after_cw && before_top == after_top &&
			(before_cw == *cw_before) && (before_top == *top_before);
}

static void Bench486PrintTimesRun (bench486_printtimes_fn_t function,
		const bench486_printtimes_case_t *test_case,
		bench486_printtimes_result_t *baseline,
		bench486_printtimes_result_t *result)
{
	unsigned repeat;
	unsigned short cw_before = 0, cw_after = 0, top_before = 0, top_after = 0;
	unsigned stack_balanced = 1;
	unsigned abi_flags = 0;

	Bench486PrintTimesConfigure (test_case);
	Con_Printf ("\n");
	Bench486PrintTimesCapture (baseline);
	for (repeat = 0 ; repeat < test_case->repeats ; repeat++)
		Bench486PrintTimesInvoke (function, &cw_before, &cw_after,
				&top_before, &top_after, &stack_balanced, &abi_flags);
	Bench486PrintTimesCapture (result);
	result->abi_flags = abi_flags;
	result->cw_before = cw_before;
	result->cw_after = cw_after;
	result->top_before = top_before;
	result->top_after = top_after;
	result->stack_balanced = stack_balanced;
}

static void Bench486PrintTimesCases (void)
{
	static const bench486_printtimes_case_t cases[] =
	{
		{ "zero", 12.5f, 12.5, 0, 0, 0, 0, 0, 1 },
		{ "double-to-float-chop", 1.0f,
			1.000000059604644775390625, 7, 12, 34, 5, 1, 1 },
		{ "positive-fraction", 1.0f, 1.125, 19, 255, 256, 17, 2, 1 },
		{ "negative-elapsed", 4.0f, 3.75, 3, -99, -100, 9, 3, 1 },
		{ "negative-zero-display", 1.0f,
			0.999999940395355224609375, 5, -42, 12345, 1, 7, 1 },
		{ "signed-extremes", -2.0f, 987.654321, 2147483647,
			(-2147483647 - 1), 2147483647, -2147483647, 6, 1 },
		{ "repeat-ring-wrap", 2.5f, 2.75, -2147483647,
			-2147483647, (-2147483647 - 1), 42, 7, 3 }
	};
	bench486_printtimes_saved_t saved;
	bench486_printtimes_result_t baseline_c, baseline_asm;
	bench486_printtimes_result_t result_c, result_asm, expected;
	const char *first_failure_name = 0;
	int first_baseline_difference = -1, first_c_difference = -1;
	int first_asm_difference = -1, first_pair_difference = -1;
	int first_c_guards = 0, first_asm_guards = 0, first_expected_ok = 0;
	int first_c_pointer_ok = 0, first_asm_pointer_ok = 0;
	unsigned first_c_abi = 0, first_asm_abi = 0;
	unsigned i, failures = 0;
	unsigned case_count = (unsigned)(sizeof(cases) / sizeof(cases[0]));
	unsigned short fixture_cw = PT_FIXTURE_CW;
	unsigned short original_cw;

	Bench486Printf ("printtimes fixture begin (%u cases; ring %dx%d; CW 0x%04x)\n",
			case_count, PT_FIXTURE_WIDTH, PT_FIXTURE_ROWS, fixture_cw);
	Bench486PrintTimesSave (&saved);
	original_cw = saved.x87_cw;
	Bench486PrintTimesWriteX87CW (fixture_cw);
	for (i = 0 ; i < case_count ; i++)
	{
		int baseline_difference, c_difference, asm_difference, pair_difference;
		int c_guards, asm_guards, expected_ok;
		int c_pointer_ok, asm_pointer_ok;

		Bench486PrintTimesWriteX87CW (fixture_cw);
		Bench486PrintTimesRestore (&saved);
		Bench486PrintTimesWriteX87CW (fixture_cw);
		Bench486Printf ("printtimes %u/%u %s\n", i + 1, case_count,
				cases[i].name);
		Bench486PrintTimesSave (&saved);
		saved.x87_cw = original_cw;
		Bench486PrintTimesWriteX87CW (fixture_cw);
		Bench486PrintTimesRun (R_PrintTimes_C, &cases[i],
				&baseline_c, &result_c);
		Bench486PrintTimesWriteX87CW (fixture_cw);
		Bench486PrintTimesRun (R_PrintTimes_asm486, &cases[i],
				&baseline_asm, &result_asm);
		expected_ok = Bench486PrintTimesBuildExpected (&baseline_c,
				&result_c, &cases[i], &expected);
		baseline_difference = Bench486PrintTimesFirstDifference (
				&baseline_c, &baseline_asm);
		c_difference = Bench486PrintTimesFirstDifference (&result_c, &expected);
		asm_difference = Bench486PrintTimesFirstDifference (&result_asm, &expected);
		pair_difference = Bench486PrintTimesFirstDifference (&result_c, &result_asm);
		c_guards = Bench486PrintTimesGuardsIntact (&result_c);
		asm_guards = Bench486PrintTimesGuardsIntact (&result_asm);
		c_pointer_ok = result_c.buffer_pointer ==
				(char *)bench486_printtimes_ring.text;
		asm_pointer_ok = result_asm.buffer_pointer ==
				(char *)bench486_printtimes_ring.text;
		if (!expected_ok || baseline_difference >= 0 || c_difference >= 0 ||
				asm_difference >= 0 || pair_difference >= 0 ||
				!c_guards || !asm_guards || !c_pointer_ok || !asm_pointer_ok ||
				result_c.timer_calls != cases[i].repeats ||
				result_asm.timer_calls != cases[i].repeats ||
				result_c.cw_before != fixture_cw ||
				result_c.cw_after != fixture_cw ||
				result_asm.cw_before != fixture_cw ||
				result_asm.cw_after != fixture_cw ||
				result_c.top_before != result_c.top_after ||
				result_asm.top_before != result_asm.top_after ||
				result_c.abi_flags || result_asm.abi_flags ||
				!result_c.stack_balanced || !result_asm.stack_balanced)
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
				first_c_abi = result_c.abi_flags;
				first_asm_abi = result_asm.abi_flags;
			}
		}
	}
	Bench486PrintTimesRestore (&saved);
	bench486_memory_failures += (int)failures;
	if (first_failure_name)
		Bench486Printf (
				"printtimes %s FAIL baseline/C/ASM/pair %d/%d/%d/%d guards %d/%d pointers %d/%d expected %d ABI %x/%x\n",
				first_failure_name, first_baseline_difference, first_c_difference,
				first_asm_difference, first_pair_difference, first_c_guards,
				first_asm_guards, first_c_pointer_ok, first_asm_pointer_ok,
				first_expected_ok, first_c_abi, first_asm_abi);
	Bench486Printf ("printtimes exact console/state %s (%u cases; %u failures)\n",
			failures ? "FAIL" : "PASS", case_count, failures);
}

static void Bench486PrintDSpeedsCases (void)
{
	static const bench486_printtimes_case_t cases[] =
	{
		{ "zero", 12.5f, 12.5, 0, 0, 0, 9, 0, 1,
			{ 0, 0, 0, 0, 0, 0 }, { 0, 0, 0, 0, 0, 0 } },
		{ "positive-fractions", 1.0f, 1.125, 7, 12, 34, 5, 1, 1,
			{ 0, -2, 0.25f, 1.0f, -4.0f, 10.0f },
			{ 0.00125f, -1.9875f, 0.3f, 0.9875f, -3.75f, 10.125f } },
		{ "negative-intervals", 1.0f, 0.875, -9, 255, -256, 17, 2, 1,
			{ 2.0f, 0.0f, 1.0f, 0.0f, -0.5f, 0.25f },
			{ 1.9975f, -0.0099f, 0.975f, -0.0125f, -0.5001f, 0.125f } },
		{ "cast-boundaries", 1.0f, 1.000000059604644775390625, 19, -42, 12345, 1, 7, 1,
			{ 0, 0, 0, 0, 0, 0 },
			{ 0.000999f, 0.012999f, -0.000999f, -0.012999f, 0.000001f, -0.000001f } },
		{ "large-safe-integers", -1.0f, 1.0, 31, -99, 100, 42, 6, 1,
			{ 0, 0, 0, 0, 0, 0 },
			{ 1.25f, 2147483.0f, -25.5f, -2147483.0f, 0.75f, 1.5f } },
		{ "repeat-console-wrap", 2.5f, 2.75, -2147483647,
			-2147483647, (-2147483647 - 1), 42, 7, 3,
			{ 1, 2, 3, 4, 5, 6 },
			{ 1.125f, 2.25f, 3.5f, 3.875f, 5.625f, 6.75f } }
	};
	static const unsigned short control_words[] =
	{
		0x037f, /* nearest */
		0x077f, /* down */
		0x0b7f, /* up */
		0x0f7f  /* truncate */
	};
	bench486_printtimes_saved_t saved;
	bench486_printtimes_result_t baseline_c, baseline_asm, result_c, result_asm;
	const char *first_failure_name = 0;
	unsigned short first_failure_cw = 0;
	int first_baseline_difference = -1, first_pair_difference = -1;
	int first_c_guards = 0, first_asm_guards = 0;
	unsigned first_c_abi = 0, first_asm_abi = 0;
	unsigned i, mode, failures = 0;
	unsigned case_count = (unsigned)(sizeof(cases) / sizeof(cases[0]));
	unsigned mode_count = (unsigned)(sizeof(control_words) / sizeof(control_words[0]));
	unsigned short original_cw;

	Bench486Printf ("printdspeeds fixture begin (%u cases x %u x87 rounding modes)\n",
			case_count, mode_count);
	Bench486PrintTimesSave (&saved);
	original_cw = saved.x87_cw;
	for (mode = 0 ; mode < mode_count ; mode++)
	{
		for (i = 0 ; i < case_count ; i++)
		{
			int baseline_difference, pair_difference;
			int c_guards, asm_guards;

			Bench486PrintTimesRestore (&saved);
			Bench486PrintTimesWriteX87CW (control_words[mode]);
			Bench486Printf ("printdspeeds %u/%u CW 0x%04x %s\n",
					i + 1, case_count, control_words[mode], cases[i].name);
			Bench486PrintTimesRun (R_PrintDSpeeds_C, &cases[i],
					&baseline_c, &result_c);
			Bench486PrintTimesRestore (&saved);
			Bench486PrintTimesWriteX87CW (control_words[mode]);
			Bench486PrintTimesRun (R_PrintDSpeeds, &cases[i],
					&baseline_asm, &result_asm);
			baseline_difference = Bench486PrintTimesFirstDifference (
					&baseline_c, &baseline_asm);
			pair_difference = Bench486PrintTimesFirstDifference (
					&result_c, &result_asm);
			c_guards = Bench486PrintTimesGuardsIntact (&result_c);
			asm_guards = Bench486PrintTimesGuardsIntact (&result_asm);
			if (baseline_difference >= 0 || pair_difference >= 0 ||
					!c_guards || !asm_guards ||
					result_c.buffer_pointer != (char *)bench486_printtimes_ring.text ||
					result_asm.buffer_pointer != (char *)bench486_printtimes_ring.text ||
					result_c.timer_calls != cases[i].repeats ||
					result_asm.timer_calls != cases[i].repeats ||
					result_c.surf_count != cases[i].surf_count ||
					result_asm.surf_count != cases[i].surf_count ||
					result_c.cw_before != control_words[mode] ||
					result_c.cw_after != control_words[mode] ||
					result_asm.cw_before != control_words[mode] ||
					result_asm.cw_after != control_words[mode] ||
					result_c.top_before != result_c.top_after ||
					result_asm.top_before != result_asm.top_after ||
					result_c.abi_flags || result_asm.abi_flags ||
					!result_c.stack_balanced || !result_asm.stack_balanced)
			{
				failures++;
				if (!first_failure_name)
				{
					first_failure_name = cases[i].name;
					first_failure_cw = control_words[mode];
					first_baseline_difference = baseline_difference;
					first_pair_difference = pair_difference;
					first_c_guards = c_guards;
					first_asm_guards = asm_guards;
					first_c_abi = result_c.abi_flags;
					first_asm_abi = result_asm.abi_flags;
				}
			}
		}
	}
	Bench486PrintTimesRestore (&saved);
	Bench486PrintTimesWriteX87CW (original_cw);
	bench486_memory_failures += (int)failures;
	if (first_failure_name)
		Bench486Printf (
				"printdspeeds %s CW 0x%04x FAIL baseline/pair %d/%d guards %d/%d ABI %x/%x\n",
				first_failure_name, first_failure_cw, first_baseline_difference,
				first_pair_difference, first_c_guards, first_asm_guards,
				first_c_abi, first_asm_abi);
	Bench486Printf ("printdspeeds exact console/state %s (%u comparisons; %u failures)\n",
			failures ? "FAIL" : "PASS", case_count * mode_count, failures);
}

#endif /* BENCH486_PRINTTIMES_H */
