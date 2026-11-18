/* Direct C/assembly SCR_UpdateScreen state, call-order and rect parity. */
/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
#ifndef BENCH486_SCREEN_UPDATE_H
#define BENCH486_SCREEN_UPDATE_H

#if defined(BENCH486) && defined(ASM486_SCREEN_UPDATE)

#include "client/asm_screenupdate.h"

#define BSU_MAX_EVENTS 24
#define BSU_GUARD_WORDS 4

extern unsigned Bench486Call_asm486 (void (*function)(void), unsigned words,
		const unsigned *arguments, float *float_return);
extern qboolean con_initialized;
extern double realtime;
extern float scr_disabled_time;
extern cvar_t scr_fov;
extern qboolean scr_initialized;
extern int sb_lines;
extern float oldscreensize, oldfov;
extern float scr_update_old_viewsize, scr_update_old_lcd_x;
#if defined(ASM486_SCREEN_CENTER_STRING)
extern int bench486_screen_center_trace_active;
extern unsigned bench486_screen_update_trace_update_count;
#endif

typedef struct
{
	unsigned before[BSU_GUARD_WORDS];
	unsigned count;
	unsigned overflow;
	int events[BSU_MAX_EVENTS];
	unsigned after[BSU_GUARD_WORDS];
	unsigned has_vid_rect;
	vrect_t vid_rect;
} bench486_screen_update_trace_t;

typedef struct
{
	bench486_screen_update_trace_t trace;
	int copytop;
	int copyeverything;
	int fullupdate;
	int recalc_refdef;
	int disabled_for_loading;
	int cls_state;
	int screen_initialized;
	int console_initialized;
	int pconupdate_set;
	unsigned old_viewsize_bits;
	unsigned old_lcd_bits;
	unsigned old_fov_bits;
	unsigned old_screensize_bits;
	unsigned abi;
	unsigned short cw_before;
	unsigned short cw_after;
	unsigned short x87_top_before;
	unsigned short x87_top_after;
} bench486_screen_update_result_t;

typedef struct
{
	const char *name;
	unsigned variant;
	unsigned should_finish;
	unsigned expect_print;
	unsigned expect_refdef;
	unsigned expect_full_clear;
	unsigned expect_console_rects;
} bench486_screen_update_case_t;

static const bench486_screen_update_case_t bench486_screen_update_cases[] =
{
	{"skip-update-preserves-flags", 0, 0, 0, 0, 0, 0},
	{"block-drawing-preserves-flags", 1, 0, 0, 0, 0, 0},
	{"loading-wait-resets-flags", 2, 0, 0, 0, 0, 0},
	{"loading-expired-and-top-copy", 3, 1, 1, 0, 0, 1},
	{"loading-expired-before-dedicated-return", 4, 0, 1, 0, 0, 0},
	{"dedicated-return", 5, 0, 0, 0, 0, 0},
	{"screen-not-initialized", 6, 0, 0, 0, 0, 0},
	{"console-not-initialized", 7, 0, 0, 0, 0, 0},
	{"first-page-refdef-and-full-clear", 8, 1, 0, 1, 1, 1},
	{"copy-top-unsigned-height-wrap", 9, 1, 0, 0, 0, 0},
	{"normal-view-rectangle", 10, 1, 0, 0, 0, 0},
	{"unordered-fov-reference-branch", 11, 1, 0, 0, 0, 0},
	{"signed-zero-viewsize-is-unchanged", 12, 1, 0, 0, 0, 0},
	{"preexisting-refdef-request", 13, 1, 0, 1, 0, 0},
	{"loading-timeout-strict-boundary", 14, 0, 0, 0, 0, 0}
};

static bench486_screen_update_trace_t bench486_screen_update_trace;
static bench486_screen_update_result_t bench486_screen_update_reference;
static bench486_screen_update_result_t bench486_screen_update_candidate;
static vrect_t bench486_screen_update_console_rect;
static int bench486_screen_update_mock_console_rects;
static int bench486_screen_update_mock_copytop;
static int bench486_screen_update_mock_copyeverything;
static unsigned short bench486_screen_update_saved_cw;
static unsigned long bench486_screen_update_saved_fp_state[27];
int bench486_screen_update_fixture_active;

typedef char bench486_screen_update_fp_state_size_must_be_108[
		(sizeof(bench486_screen_update_saved_fp_state) == 108) ? 1 : -1];

static void Bench486ScreenUpdateSaveFpuState (void)
{
	/* 32-bit FSAVE environment plus eight 80-bit registers. */
	__asm__ __volatile__ ("fnsave %0\n\tfrstor %0"
			: "+m" (bench486_screen_update_saved_fp_state) : : "memory");
}

static void Bench486ScreenUpdateResetFpuState (void)
{
	/* Each reference/candidate starts with an empty x87 stack and caller CW. */
	__asm__ __volatile__ ("fninit\n\tfldcw %0"
			: : "m" (bench486_screen_update_saved_cw) : "memory");
}

static void Bench486ScreenUpdateRestoreFpuState (void)
{
	__asm__ __volatile__ ("frstor %0"
			: : "m" (bench486_screen_update_saved_fp_state) : "memory");
}

typedef struct
{
	viddef_t vid;
	vrect_t scr_vrect;
	vrect_t *pconupdate;
	float realtime_bits[2];
	float scr_disabled_time;
	float scr_viewsize, scr_fov, lcd_x;
	float old_viewsize, old_lcd_x, old_fov, old_screensize;
	int scr_copytop, scr_copyeverything, scr_fullupdate, sb_lines;
	int recalc_refdef, scr_disabled, scr_skipupdate, block_drawing;
	int scr_initialized, con_initialized, cls_state, cls_demoplayback;
#if defined(ASM486_SCREEN_CENTER_STRING)
	int center_trace_active;
	unsigned trace_update_count;
#endif
} bench486_screen_update_saved_t;

static bench486_screen_update_saved_t bench486_screen_update_saved;

static unsigned short Bench486ScreenUpdateGetControlWord (void)
{
	unsigned short control_word;
	__asm__ __volatile__ ("fnstcw %0" : "=m" (control_word));
	return control_word;
}

static unsigned short Bench486ScreenUpdateGetX87Top (void)
{
	unsigned short status;
	__asm__ __volatile__ ("fnstsw %0" : "=am" (status));
	return (unsigned short)(status & 0x3800U);
}

static void Bench486ScreenUpdateInitTrace (void)
{
	unsigned i;
	Q_memset (&bench486_screen_update_trace, 0,
			sizeof(bench486_screen_update_trace));
	for (i = 0; i < BSU_GUARD_WORDS; i++)
	{
		bench486_screen_update_trace.before[i] = 0x53551000U + i;
		bench486_screen_update_trace.after[i] = 0x53552000U + i;
	}
}

void Bench486ScreenUpdateRecordCall (int event)
{
	if (bench486_screen_update_trace.count < BSU_MAX_EVENTS)
		bench486_screen_update_trace.events[
				bench486_screen_update_trace.count] = event;
	else
		bench486_screen_update_trace.overflow = 1;
	bench486_screen_update_trace.count++;

	if (event == SU_EVENT_CALC_REFDEF)
		vid.recalc_refdef = 0;
	else if (event == SU_EVENT_SETUP_CONSOLE)
		pconupdate = bench486_screen_update_mock_console_rects ?
				&bench486_screen_update_console_rect : NULL;
	else if (event == SU_EVENT_OVERLAYS)
	{
		if (bench486_screen_update_mock_copyeverything)
			scr_copyeverything = 1;
		if (bench486_screen_update_mock_copytop)
			scr_copytop = 1;
	}
}

void Bench486ScreenUpdateRecordVidRect (const vrect_t *rect)
{
	Bench486ScreenUpdateRecordCall (SU_EVENT_VID_UPDATE);
	bench486_screen_update_trace.has_vid_rect = 1;
	Q_memcpy (&bench486_screen_update_trace.vid_rect, (void *)rect,
			sizeof(*rect));
}

static void Bench486ScreenUpdateSaveState (void)
{
	Q_memcpy (&bench486_screen_update_saved.vid, &vid, sizeof(vid));
	Q_memcpy (&bench486_screen_update_saved.scr_vrect, &scr_vrect,
			sizeof(scr_vrect));
	bench486_screen_update_saved.pconupdate = pconupdate;
	Q_memcpy (bench486_screen_update_saved.realtime_bits, &realtime,
			sizeof(realtime));
	bench486_screen_update_saved.scr_disabled_time = scr_disabled_time;
	bench486_screen_update_saved.scr_viewsize = scr_viewsize.value;
	bench486_screen_update_saved.scr_fov = scr_fov.value;
	bench486_screen_update_saved.lcd_x = lcd_x.value;
	bench486_screen_update_saved.old_viewsize = scr_update_old_viewsize;
	bench486_screen_update_saved.old_lcd_x = scr_update_old_lcd_x;
	bench486_screen_update_saved.old_fov = oldfov;
	bench486_screen_update_saved.old_screensize = oldscreensize;
	bench486_screen_update_saved.scr_copytop = scr_copytop;
	bench486_screen_update_saved.scr_copyeverything = scr_copyeverything;
	bench486_screen_update_saved.scr_fullupdate = scr_fullupdate;
	bench486_screen_update_saved.sb_lines = sb_lines;
	bench486_screen_update_saved.recalc_refdef = vid.recalc_refdef;
	bench486_screen_update_saved.scr_disabled = scr_disabled_for_loading;
	bench486_screen_update_saved.scr_skipupdate = scr_skipupdate;
	bench486_screen_update_saved.block_drawing = block_drawing;
	bench486_screen_update_saved.scr_initialized = scr_initialized;
	bench486_screen_update_saved.con_initialized = con_initialized;
	bench486_screen_update_saved.cls_state = cls.state;
	bench486_screen_update_saved.cls_demoplayback = cls.demoplayback;
#if defined(ASM486_SCREEN_CENTER_STRING)
	bench486_screen_update_saved.center_trace_active =
			bench486_screen_center_trace_active;
	bench486_screen_update_saved.trace_update_count =
			bench486_screen_update_trace_update_count;
#endif
}

static void Bench486ScreenUpdateRestoreState (void)
{
	Q_memcpy (&vid, &bench486_screen_update_saved.vid, sizeof(vid));
	Q_memcpy (&scr_vrect, &bench486_screen_update_saved.scr_vrect,
			sizeof(scr_vrect));
	pconupdate = bench486_screen_update_saved.pconupdate;
	Q_memcpy (&realtime, bench486_screen_update_saved.realtime_bits,
			sizeof(realtime));
	scr_disabled_time = bench486_screen_update_saved.scr_disabled_time;
	scr_viewsize.value = bench486_screen_update_saved.scr_viewsize;
	scr_fov.value = bench486_screen_update_saved.scr_fov;
	lcd_x.value = bench486_screen_update_saved.lcd_x;
	scr_update_old_viewsize = bench486_screen_update_saved.old_viewsize;
	scr_update_old_lcd_x = bench486_screen_update_saved.old_lcd_x;
	oldfov = bench486_screen_update_saved.old_fov;
	oldscreensize = bench486_screen_update_saved.old_screensize;
	scr_copytop = bench486_screen_update_saved.scr_copytop;
	scr_copyeverything = bench486_screen_update_saved.scr_copyeverything;
	scr_fullupdate = bench486_screen_update_saved.scr_fullupdate;
	sb_lines = bench486_screen_update_saved.sb_lines;
	scr_disabled_for_loading = bench486_screen_update_saved.scr_disabled;
	scr_skipupdate = bench486_screen_update_saved.scr_skipupdate;
	block_drawing = bench486_screen_update_saved.block_drawing;
	scr_initialized = bench486_screen_update_saved.scr_initialized;
	con_initialized = bench486_screen_update_saved.con_initialized;
	cls.state = bench486_screen_update_saved.cls_state;
	cls.demoplayback = bench486_screen_update_saved.cls_demoplayback;
#if defined(ASM486_SCREEN_CENTER_STRING)
	bench486_screen_center_trace_active =
			bench486_screen_update_saved.center_trace_active;
	bench486_screen_update_trace_update_count =
			bench486_screen_update_saved.trace_update_count;
#endif
}

static void Bench486ScreenUpdatePrepare (
		const bench486_screen_update_case_t *test_case)
{
	static unsigned nan_bits = 0x7fc00001U;
	static unsigned negative_zero_bits = 0x80000000U;
	static const unsigned double_100_bits[2] = {0x00000000U, 0x40590000U};
	static const unsigned double_105_bits[2] = {0x00000000U, 0x405a4000U};
	static const unsigned double_160_bits[2] = {0x00000000U, 0x40640000U};
	static const unsigned double_160_5_bits[2] = {0x00000000U, 0x40641000U};
	static const unsigned float_90_bits = 0x42b40000U;
	static const unsigned float_100_bits = 0x42c80000U;
	static const unsigned float_zero_bits = 0x00000000U;
	unsigned positive_zero_bits;

	Q_memset (&vid, 0, sizeof(vid));
	vid.width = 320;
	vid.height = 200;
	vid.numpages = 2;
	vid.recalc_refdef = 0;
	scr_vrect.x = 11;
	scr_vrect.y = 13;
	scr_vrect.width = 207;
	scr_vrect.height = 151;
	scr_vrect.pnext = NULL;
	pconupdate = NULL;
	/* Load fixture floats as bytes: GCC may leave x87 temporaries live when
	 * these literals are inlined, which would accumulate across test cases. */
	Q_memcpy (&realtime, (void *)double_100_bits, sizeof(realtime));
	Q_memcpy (&scr_disabled_time, (void *)&float_100_bits,
			sizeof(scr_disabled_time));
	Q_memcpy (&scr_viewsize.value, (void *)&float_100_bits,
			sizeof(scr_viewsize.value));
	Q_memcpy (&scr_fov.value, (void *)&float_90_bits,
			sizeof(scr_fov.value));
	Q_memcpy (&lcd_x.value, (void *)&float_zero_bits, sizeof(lcd_x.value));
	Q_memcpy (&scr_update_old_viewsize, (void *)&float_100_bits,
			sizeof(scr_update_old_viewsize));
	Q_memcpy (&scr_update_old_lcd_x, (void *)&float_zero_bits,
			sizeof(scr_update_old_lcd_x));
	Q_memcpy (&oldfov, (void *)&float_90_bits, sizeof(oldfov));
	Q_memcpy (&oldscreensize, (void *)&float_100_bits,
			sizeof(oldscreensize));
	scr_copytop = 7;
	scr_copyeverything = 9;
	scr_fullupdate = 2;
	sb_lines = 24;
	scr_disabled_for_loading = false;
	scr_skipupdate = false;
	block_drawing = false;
	scr_initialized = true;
	con_initialized = true;
	cls.state = ca_connected;
	cls.demoplayback = false;
	bench486_screen_update_mock_console_rects = 0;
	bench486_screen_update_mock_copytop = 0;
	bench486_screen_update_mock_copyeverything = 0;
	bench486_screen_update_console_rect.x = 3;
	bench486_screen_update_console_rect.y = 4;
	bench486_screen_update_console_rect.width = 80;
	bench486_screen_update_console_rect.height = 16;
	bench486_screen_update_console_rect.pnext = NULL;
#if defined(ASM486_SCREEN_CENTER_STRING)
	bench486_screen_center_trace_active = 0;
	bench486_screen_update_trace_update_count = 0;
#endif

	switch (test_case->variant)
	{
	case 0:
		scr_skipupdate = true;
		break;
	case 1:
		block_drawing = true;
		break;
	case 2:
		scr_disabled_for_loading = true;
		Q_memcpy (&realtime, (void *)double_105_bits, sizeof(realtime));
		break;
	case 3:
		scr_disabled_for_loading = true;
		Q_memcpy (&realtime, (void *)double_160_5_bits, sizeof(realtime));
		bench486_screen_update_mock_console_rects = 1;
		bench486_screen_update_mock_copytop = 1;
		break;
	case 4:
		scr_disabled_for_loading = true;
		Q_memcpy (&realtime, (void *)double_160_5_bits, sizeof(realtime));
		cls.state = ca_dedicated;
		break;
	case 5:
		cls.state = ca_dedicated;
		break;
	case 6:
		scr_initialized = false;
		break;
	case 7:
		con_initialized = false;
		break;
	case 8:
		scr_update_old_viewsize = 90.0f;
		oldfov = 80.0f;
		scr_update_old_lcd_x = 1.0f;
		oldscreensize = 90.0f;
		scr_fullupdate = 0;
		bench486_screen_update_mock_console_rects = 1;
		bench486_screen_update_mock_copyeverything = 1;
		break;
	case 9:
		bench486_screen_update_mock_copytop = 1;
		sb_lines = 250;
		break;
	case 10:
		break;
	case 11:
		Q_memcpy (&scr_fov.value, (void *)&nan_bits, sizeof(nan_bits));
		break;
	case 12:
		positive_zero_bits = 0;
		Q_memcpy (&scr_viewsize.value, &positive_zero_bits,
				sizeof(positive_zero_bits));
		Q_memcpy (&scr_update_old_viewsize, (void *)&negative_zero_bits,
				sizeof(negative_zero_bits));
		Q_memcpy (&oldscreensize, &positive_zero_bits,
				sizeof(positive_zero_bits));
		break;
	case 13:
		vid.recalc_refdef = 1;
		break;
	case 14:
		scr_disabled_for_loading = true;
		Q_memcpy (&realtime, (void *)double_160_bits, sizeof(realtime));
		break;
	}
}

static void Bench486ScreenUpdateCapture (bench486_screen_update_result_t *result,
		unsigned abi, unsigned short cw_before, unsigned short cw_after,
		unsigned short top_before, unsigned short top_after)
{
	Q_memset (result, 0, sizeof(*result));
	Q_memcpy (&result->trace, &bench486_screen_update_trace,
			sizeof(result->trace));
	result->copytop = scr_copytop;
	result->copyeverything = scr_copyeverything;
	result->fullupdate = scr_fullupdate;
	result->recalc_refdef = vid.recalc_refdef;
	result->disabled_for_loading = scr_disabled_for_loading;
	result->cls_state = cls.state;
	result->screen_initialized = scr_initialized;
	result->console_initialized = con_initialized;
	result->pconupdate_set = pconupdate != NULL;
	Q_memcpy (&result->old_viewsize_bits, &scr_update_old_viewsize,
			sizeof(scr_update_old_viewsize));
	Q_memcpy (&result->old_lcd_bits, &scr_update_old_lcd_x,
			sizeof(scr_update_old_lcd_x));
	Q_memcpy (&result->old_fov_bits, &oldfov, sizeof(oldfov));
	Q_memcpy (&result->old_screensize_bits, &oldscreensize,
			sizeof(oldscreensize));
	result->abi = abi;
	result->cw_before = cw_before;
	result->cw_after = cw_after;
	result->x87_top_before = top_before;
	result->x87_top_after = top_after;
}

static unsigned Bench486ScreenUpdateRun (
		const bench486_screen_update_case_t *test_case,
		void (*function)(void), bench486_screen_update_result_t *result)
{
	unsigned abi;
	unsigned short cw_before, cw_after, top_before, top_after;

	Bench486ScreenUpdatePrepare (test_case);
	Bench486ScreenUpdateResetFpuState ();
	Bench486ScreenUpdateInitTrace ();
	cw_before = Bench486ScreenUpdateGetControlWord ();
	top_before = Bench486ScreenUpdateGetX87Top ();
	bench486_screen_update_fixture_active = 1;
	abi = Bench486Call_asm486 (function, 0, NULL, NULL);
	bench486_screen_update_fixture_active = 0;
	top_after = Bench486ScreenUpdateGetX87Top ();
	cw_after = Bench486ScreenUpdateGetControlWord ();
	Bench486ScreenUpdateCapture (result, abi, cw_before, cw_after,
			top_before, top_after);
	if ((abi & 0x20U) || cw_before != cw_after ||
			top_before != top_after)
	{
		Bench486ReportPrintf ("screen update ABI/x87 FAIL case %s abi %08x cw %04x/%04x top %04x/%04x\n",
				test_case->name, abi, cw_before, cw_after,
				top_before, top_after);
		return 1;
	}
	return 0;
}

static unsigned Bench486ScreenUpdateExpectedEvents (
		const bench486_screen_update_case_t *test_case,
		const bench486_screen_update_result_t *result)
{
	int expected[BSU_MAX_EVENTS];
	unsigned count = 0;
	unsigned i;

	if (test_case->expect_print)
		expected[count++] = SU_EVENT_CON_PRINT;
	if (test_case->should_finish)
	{
		if (test_case->expect_refdef)
			expected[count++] = SU_EVENT_CALC_REFDEF;
		expected[count++] = SU_EVENT_ENABLE_BACKBUFFER;
		if (test_case->expect_full_clear)
		{
			expected[count++] = SU_EVENT_TILE_CLEAR;
			expected[count++] = SU_EVENT_SBAR_CHANGED;
		}
		expected[count++] = SU_EVENT_SETUP_CONSOLE;
		expected[count++] = SU_EVENT_ERASE_CENTER;
		expected[count++] = SU_EVENT_DISABLE_BACKBUFFER;
		expected[count++] = SU_EVENT_LOCK_BUFFER;
		expected[count++] = SU_EVENT_RENDER_VIEW;
		expected[count++] = SU_EVENT_UNLOCK_BUFFER;
		expected[count++] = SU_EVENT_ENABLE_BACKBUFFER;
		expected[count++] = SU_EVENT_OVERLAYS;
		expected[count++] = SU_EVENT_DISABLE_BACKBUFFER;
		if (test_case->expect_console_rects)
			expected[count++] = SU_EVENT_UPDATE_RECTS;
		expected[count++] = SU_EVENT_UPDATE_PALETTE;
		expected[count++] = SU_EVENT_VID_UPDATE;
	}
	if (result->trace.overflow || result->trace.count != count ||
			!result->trace.has_vid_rect != !test_case->should_finish)
		return 0x53550001U;
	for (i = 0; i < BSU_GUARD_WORDS; i++)
		if (result->trace.before[i] != 0x53551000U + i ||
				result->trace.after[i] != 0x53552000U + i)
			return 0x53550010U + i;
	for (i = 0; i < count; i++)
		if (result->trace.events[i] != expected[i])
			return 0x53550020U + i;
	if (test_case->expect_full_clear && result->copyeverything != 1)
		return 0x53550040U;
	if (test_case->expect_console_rects != (unsigned)result->pconupdate_set)
		return 0x53550041U;
	if (test_case->variant <= 1)
	{
		if (result->copytop != 7 || result->copyeverything != 9)
			return 0x53550042U;
	}
	else if (result->copytop != bench486_screen_update_mock_copytop ||
			result->copyeverything !=
				(test_case->expect_full_clear ||
				 bench486_screen_update_mock_copyeverything))
		return 0x53550043U;
	if (result->fullupdate != (test_case->variant == 8 ? 1 :
			(test_case->should_finish ? 3 : 2)))
		return 0x53550044U;
	if (result->disabled_for_loading !=
			(unsigned)(test_case->variant == 2 || test_case->variant == 14))
		return 0x53550045U;
	return 0;
}

static unsigned Bench486ScreenUpdateDifference (
		const bench486_screen_update_result_t *reference,
		const bench486_screen_update_result_t *candidate)
{
	if (reference->abi != candidate->abi ||
			reference->cw_before != candidate->cw_before ||
			reference->cw_after != candidate->cw_after ||
			reference->x87_top_before != candidate->x87_top_before ||
			reference->x87_top_after != candidate->x87_top_after)
		return 0x53550100U;
	if (Q_memcmp ((void *)&reference->trace, (void *)&candidate->trace,
			sizeof(reference->trace)))
		return 0x53550101U;
	if (reference->copytop != candidate->copytop ||
			reference->copyeverything != candidate->copyeverything ||
			reference->fullupdate != candidate->fullupdate ||
			reference->recalc_refdef != candidate->recalc_refdef ||
			reference->disabled_for_loading != candidate->disabled_for_loading ||
			reference->cls_state != candidate->cls_state ||
			reference->screen_initialized != candidate->screen_initialized ||
			reference->console_initialized != candidate->console_initialized ||
			reference->pconupdate_set != candidate->pconupdate_set ||
			reference->old_viewsize_bits != candidate->old_viewsize_bits ||
			reference->old_lcd_bits != candidate->old_lcd_bits ||
			reference->old_fov_bits != candidate->old_fov_bits ||
			reference->old_screensize_bits != candidate->old_screensize_bits)
		return 0x53550102U;
	return 0;
}

static unsigned Bench486ScreenUpdateExpectedRect (
		const bench486_screen_update_case_t *test_case,
		const bench486_screen_update_result_t *result)
{
	vrect_t expected;

	if (result->copyeverything)
	{
		expected.x = 0;
		expected.y = 0;
		expected.width = vid.width;
		expected.height = vid.height;
	}
	else if (result->copytop)
	{
		expected.x = 0;
		expected.y = 0;
		expected.width = vid.width;
		expected.height = vid.height - sb_lines;
	}
	else
	{
		expected = scr_vrect;
	}
	expected.pnext = NULL;
	if (test_case->should_finish &&
			Q_memcmp (&expected, (void *)&result->trace.vid_rect,
					sizeof(expected)))
		return 0x53550050U;
	return 0;
}

void Bench486ScreenUpdateCases (void)
{
	unsigned i;
	unsigned total = sizeof(bench486_screen_update_cases) /
			sizeof(bench486_screen_update_cases[0]);
	unsigned failure = 0;
	unsigned short cw_after;

	Bench486ScreenUpdateSaveFpuState ();
	bench486_screen_update_saved_cw = Bench486ScreenUpdateGetControlWord ();
	Bench486ScreenUpdateSaveState ();
	for (i = 0; i < total; i++)
	{
		Bench486ReportPrintf ("screen update case %u/%u %s C begin\n",
				i + 1, total, bench486_screen_update_cases[i].name);
		failure |= Bench486ScreenUpdateRun (
				&bench486_screen_update_cases[i],
				SCR_UpdateScreen_Screen_C,
				&bench486_screen_update_reference);
		Bench486ReportPrintf ("screen update case %u/%u %s C end\n",
				i + 1, total, bench486_screen_update_cases[i].name);
		failure |= Bench486ScreenUpdateExpectedEvents (
				&bench486_screen_update_cases[i],
				&bench486_screen_update_reference);
		failure |= Bench486ScreenUpdateExpectedRect (
				&bench486_screen_update_cases[i],
				&bench486_screen_update_reference);
		Bench486ReportPrintf ("screen update case %u/%u %s asm begin\n",
				i + 1, total, bench486_screen_update_cases[i].name);
		failure |= Bench486ScreenUpdateRun (
				&bench486_screen_update_cases[i],
				SCR_UpdateScreen_asm486,
				&bench486_screen_update_candidate);
		Bench486ReportPrintf ("screen update case %u/%u %s asm end\n",
				i + 1, total, bench486_screen_update_cases[i].name);
		failure |= Bench486ScreenUpdateExpectedEvents (
				&bench486_screen_update_cases[i],
				&bench486_screen_update_candidate);
		failure |= Bench486ScreenUpdateExpectedRect (
				&bench486_screen_update_cases[i],
				&bench486_screen_update_candidate);
		failure |= Bench486ScreenUpdateDifference (
				&bench486_screen_update_reference,
				&bench486_screen_update_candidate);
		if (failure)
		{
			Bench486ReportPrintf ("screen update FAIL case %s code %08x\n",
					bench486_screen_update_cases[i].name, failure);
			break;
		}
	}
	Bench486ScreenUpdateRestoreState ();
	Bench486ScreenUpdateRestoreFpuState ();
	cw_after = Bench486ScreenUpdateGetControlWord ();
	if (cw_after != bench486_screen_update_saved_cw)
		failure |= 0x53550080U;
	if (failure)
		bench486_memory_failures++;
	else
		Bench486ReportPrintf ("SCR_UpdateScreen %u exact C/assembly control, call-order and update-rectangle cases PASS\n",
				total);
}

#endif
#endif
