/* Direct C/assembly state and call-trace parity for SCR_SetUpToDrawConsole. */
#ifndef BENCH486_SCREEN_CONSOLE_SETUP_H
#define BENCH486_SCREEN_CONSOLE_SETUP_H

#if defined(BENCH486) && defined(ASM486_SCREEN_CONSOLE_SETUP)

#include "asm_screenconsolesetup.h"

#define BSCS_MAX_EVENTS 8
#define BSCS_MAX_TILE_CALLS 2

/* Assembly uses the trace hooks only while its direct parity fixture runs. */
int bench486_screen_console_setup_fixture_active;

extern unsigned Bench486Call_asm486 (void (*function)(void), unsigned words,
		const unsigned *arguments, float *float_return);
extern float scr_con_current, scr_conlines;
extern cvar_t scr_conspeed;
extern qboolean scr_drawloading, con_forcedup;
extern int clearconsole, clearnotify, con_notifylines;
extern int scr_copytop, scr_copyeverything;
extern double host_frametime;
extern keydest_t key_dest;

typedef char bench486_screen_console_setup_requires_i386[
		(sizeof(void *) == 4 && sizeof(int) == 4 && sizeof(unsigned) == 4) ?
		1 : -1];

enum
{
	BSCS_EVENT_RESIZE = 1,
	BSCS_EVENT_TILE_CLEAR = 2,
	BSCS_EVENT_SBAR_CHANGED = 3
};

typedef struct
{
	int x, y, width, height;
} bench486_screen_console_setup_tile_call_t;

typedef struct
{
	unsigned event_count;
	unsigned overflow;
	unsigned resize_count;
	unsigned tile_count;
	unsigned sbar_count;
	int events[BSCS_MAX_EVENTS];
	bench486_screen_console_setup_tile_call_t tiles[BSCS_MAX_TILE_CALLS];
} bench486_screen_console_setup_trace_t;

typedef struct
{
	viddef_t video;
	bench486_screen_console_setup_trace_t trace;
	unsigned current_bits;
	unsigned lines_bits;
	unsigned speed_bits;
	unsigned frame_time_bits[2];
	int forced;
	int loading;
	int copytop;
	int copyeverything;
	int clearconsole_count;
	int clearnotify_count;
	int notify_lines;
	int destination;
	int has_worldmodel;
	int signon;
	unsigned abi;
	unsigned short cw_before;
	unsigned short cw_after;
	unsigned short tag_before;
	unsigned short tag_after;
	unsigned short top_before;
	unsigned short top_after;
} bench486_screen_console_setup_result_t;

typedef struct
{
	const char *name;
	unsigned width;
	unsigned height;
	int numpages;
	int loading;
	int worldmodel;
	int signon;
	int destination;
	float current;
	float lines;
	float speed;
	double frame_time;
	int forced;
	int clearconsole_count;
	int clearnotify_count;
	int notify_lines;
	int copytop;
	int copyeverything;
} bench486_screen_console_setup_case_t;

typedef struct
{
	byte bytes[28];
} bench486_screen_console_setup_x87_environment_t;

static bench486_screen_console_setup_trace_t bench486_screen_console_setup_trace;
static bench486_screen_console_setup_result_t bench486_screen_console_setup_reference;
static bench486_screen_console_setup_result_t bench486_screen_console_setup_candidate;
static viddef_t bench486_screen_console_setup_saved_video;
static float bench486_screen_console_setup_saved_current;
static float bench486_screen_console_setup_saved_lines;
static float bench486_screen_console_setup_saved_speed;
static double bench486_screen_console_setup_saved_frame_time;
static qboolean bench486_screen_console_setup_saved_loading;
static qboolean bench486_screen_console_setup_saved_forced;
static int bench486_screen_console_setup_saved_copytop;
static int bench486_screen_console_setup_saved_copyeverything;
static int bench486_screen_console_setup_saved_clearconsole;
static int bench486_screen_console_setup_saved_clearnotify;
static int bench486_screen_console_setup_saved_notify_lines;
static keydest_t bench486_screen_console_setup_saved_destination;
static struct model_s *bench486_screen_console_setup_saved_worldmodel;
static int bench486_screen_console_setup_saved_signon;
static unsigned short bench486_screen_console_setup_saved_cw;
static bench486_screen_console_setup_x87_environment_t bench486_screen_console_setup_saved_environment;
static bench486_screen_console_setup_x87_environment_t bench486_screen_console_setup_call_environment;
static bench486_screen_console_setup_x87_environment_t bench486_screen_console_setup_after_environment;
static int bench486_screen_console_setup_dummy_worldmodel;

static unsigned short Bench486ScreenConsoleSetupGetControlWord (void)
{
	unsigned short control_word;
	__asm__ __volatile__ ("fnstcw %0" : "=m" (control_word));
	return control_word;
}

static void Bench486ScreenConsoleSetupSetControlWord (unsigned short control_word)
{
	__asm__ __volatile__ ("fldcw %0" : : "m" (control_word));
}

static void Bench486ScreenConsoleSetupSaveEnvironment (
		bench486_screen_console_setup_x87_environment_t *environment)
{
	/* FNSTENV masks exceptions, so reload immediately to preserve live state. */
	__asm__ __volatile__ ("fnstenv %0\n\tfldenv %0" : "=m" (*environment));
}

static void Bench486ScreenConsoleSetupRestoreEnvironment (
		const bench486_screen_console_setup_x87_environment_t *environment)
{
	__asm__ __volatile__ ("fldenv %0" : : "m" (*environment));
}

static unsigned short Bench486ScreenConsoleSetupEnvironmentWord (
		const bench486_screen_console_setup_x87_environment_t *environment,
		unsigned word_index)
{
	unsigned short value;
	Q_memcpy (&value, (void *)(environment->bytes + word_index * 4U), sizeof(value));
	return value;
}

static void Bench486ScreenConsoleSetupRecordEvent (int event)
{
	if (bench486_screen_console_setup_trace.event_count < BSCS_MAX_EVENTS)
		bench486_screen_console_setup_trace.events[
				bench486_screen_console_setup_trace.event_count++] = event;
	else
		bench486_screen_console_setup_trace.overflow = 1;
}

void Bench486ScreenConsoleSetupCheckResize (void)
{
	bench486_screen_console_setup_trace.resize_count++;
	Bench486ScreenConsoleSetupRecordEvent (BSCS_EVENT_RESIZE);
}

void Bench486ScreenConsoleSetupTileClear (int x, int y, int width, int height)
{
	unsigned call = bench486_screen_console_setup_trace.tile_count++;
	Bench486ScreenConsoleSetupRecordEvent (BSCS_EVENT_TILE_CLEAR);
	if (call < BSCS_MAX_TILE_CALLS)
	{
		bench486_screen_console_setup_trace.tiles[call].x = x;
		bench486_screen_console_setup_trace.tiles[call].y = y;
		bench486_screen_console_setup_trace.tiles[call].width = width;
		bench486_screen_console_setup_trace.tiles[call].height = height;
	}
	else
		bench486_screen_console_setup_trace.overflow = 1;
}

void Bench486ScreenConsoleSetupSbarChanged (void)
{
	bench486_screen_console_setup_trace.sbar_count++;
	Bench486ScreenConsoleSetupRecordEvent (BSCS_EVENT_SBAR_CHANGED);
}

static void Bench486ScreenConsoleSetupInitTrace (void)
{
	Q_memset (&bench486_screen_console_setup_trace, 0,
			sizeof(bench486_screen_console_setup_trace));
}

static void Bench486ScreenConsoleSetupSaveState (void)
{
	Q_memcpy (&bench486_screen_console_setup_saved_video, &vid, sizeof(vid));
	bench486_screen_console_setup_saved_current = scr_con_current;
	bench486_screen_console_setup_saved_lines = scr_conlines;
	bench486_screen_console_setup_saved_speed = scr_conspeed.value;
	bench486_screen_console_setup_saved_frame_time = host_frametime;
	bench486_screen_console_setup_saved_loading = scr_drawloading;
	bench486_screen_console_setup_saved_forced = con_forcedup;
	bench486_screen_console_setup_saved_copytop = scr_copytop;
	bench486_screen_console_setup_saved_copyeverything = scr_copyeverything;
	bench486_screen_console_setup_saved_clearconsole = clearconsole;
	bench486_screen_console_setup_saved_clearnotify = clearnotify;
	bench486_screen_console_setup_saved_notify_lines = con_notifylines;
	bench486_screen_console_setup_saved_destination = key_dest;
	bench486_screen_console_setup_saved_worldmodel = cl.worldmodel;
	bench486_screen_console_setup_saved_signon = cls.signon;
	Bench486ScreenConsoleSetupSaveEnvironment (
			&bench486_screen_console_setup_saved_environment);
	bench486_screen_console_setup_saved_cw = Bench486ScreenConsoleSetupGetControlWord ();
}

static void Bench486ScreenConsoleSetupRestoreState (void)
{
	Q_memcpy (&vid, &bench486_screen_console_setup_saved_video, sizeof(vid));
	scr_con_current = bench486_screen_console_setup_saved_current;
	scr_conlines = bench486_screen_console_setup_saved_lines;
	scr_conspeed.value = bench486_screen_console_setup_saved_speed;
	host_frametime = bench486_screen_console_setup_saved_frame_time;
	scr_drawloading = bench486_screen_console_setup_saved_loading;
	con_forcedup = bench486_screen_console_setup_saved_forced;
	scr_copytop = bench486_screen_console_setup_saved_copytop;
	scr_copyeverything = bench486_screen_console_setup_saved_copyeverything;
	clearconsole = bench486_screen_console_setup_saved_clearconsole;
	clearnotify = bench486_screen_console_setup_saved_clearnotify;
	con_notifylines = bench486_screen_console_setup_saved_notify_lines;
	key_dest = bench486_screen_console_setup_saved_destination;
	cl.worldmodel = bench486_screen_console_setup_saved_worldmodel;
	cls.signon = bench486_screen_console_setup_saved_signon;
	Bench486ScreenConsoleSetupRestoreEnvironment (
			&bench486_screen_console_setup_saved_environment);
}

static void Bench486ScreenConsoleSetupPrepare (
		const bench486_screen_console_setup_case_t *test_case)
{
	Q_memcpy (&vid, &bench486_screen_console_setup_saved_video, sizeof(vid));
	vid.width = test_case->width;
	vid.height = test_case->height;
	vid.numpages = test_case->numpages;
	scr_drawloading = test_case->loading;
	con_forcedup = test_case->forced;
	key_dest = (keydest_t)test_case->destination;
	cl.worldmodel = test_case->worldmodel ?
			(struct model_s *)&bench486_screen_console_setup_dummy_worldmodel : NULL;
	cls.signon = test_case->signon;
	scr_con_current = test_case->current;
	scr_conlines = test_case->lines;
	scr_conspeed.value = test_case->speed;
	host_frametime = test_case->frame_time;
	clearconsole = test_case->clearconsole_count;
	clearnotify = test_case->clearnotify_count;
	con_notifylines = test_case->notify_lines;
	scr_copytop = test_case->copytop;
	scr_copyeverything = test_case->copyeverything;
	Bench486ScreenConsoleSetupInitTrace ();
}

static void Bench486ScreenConsoleSetupCapture (
		bench486_screen_console_setup_result_t *result, unsigned abi,
		unsigned short cw_before, unsigned short cw_after,
		const bench486_screen_console_setup_x87_environment_t *before_environment,
		const bench486_screen_console_setup_x87_environment_t *after_environment)
{
	Q_memset (result, 0, sizeof(*result));
	Q_memcpy (&result->video, &vid, sizeof(vid));
	Q_memcpy (&result->trace, &bench486_screen_console_setup_trace,
			sizeof(result->trace));
	Q_memcpy (&result->current_bits, &scr_con_current, sizeof(scr_con_current));
	Q_memcpy (&result->lines_bits, &scr_conlines, sizeof(scr_conlines));
	Q_memcpy (&result->speed_bits, &scr_conspeed.value, sizeof(scr_conspeed.value));
	Q_memcpy (result->frame_time_bits, &host_frametime, sizeof(host_frametime));
	result->forced = con_forcedup;
	result->loading = scr_drawloading;
	result->copytop = scr_copytop;
	result->copyeverything = scr_copyeverything;
	result->clearconsole_count = clearconsole;
	result->clearnotify_count = clearnotify;
	result->notify_lines = con_notifylines;
	result->destination = key_dest;
	result->has_worldmodel = cl.worldmodel != NULL;
	result->signon = cls.signon;
	result->abi = abi;
	result->cw_before = cw_before;
	result->cw_after = cw_after;
	result->tag_before = Bench486ScreenConsoleSetupEnvironmentWord (
			before_environment, 2);
	result->tag_after = Bench486ScreenConsoleSetupEnvironmentWord (
			after_environment, 2);
	result->top_before = (unsigned short)(Bench486ScreenConsoleSetupEnvironmentWord (
			before_environment, 1) & 0x3800U);
	result->top_after = (unsigned short)(Bench486ScreenConsoleSetupEnvironmentWord (
			after_environment, 1) & 0x3800U);
}

static void Bench486ScreenConsoleSetupRun (
		void (*function)(void),
		const bench486_screen_console_setup_case_t *test_case,
		unsigned short control_word,
		bench486_screen_console_setup_result_t *result)
{
	unsigned abi;
	unsigned short cw_before, cw_after;
	Bench486ScreenConsoleSetupRestoreEnvironment (
			&bench486_screen_console_setup_saved_environment);
	Bench486ScreenConsoleSetupSetControlWord (control_word);
	Bench486ScreenConsoleSetupPrepare (test_case);
	Bench486ScreenConsoleSetupSaveEnvironment (
			&bench486_screen_console_setup_call_environment);
	cw_before = Bench486ScreenConsoleSetupGetControlWord ();
	bench486_screen_console_setup_fixture_active = 1;
	abi = Bench486Call_asm486 (function, 0, NULL, NULL);
	bench486_screen_console_setup_fixture_active = 0;
	cw_after = Bench486ScreenConsoleSetupGetControlWord ();
	Bench486ScreenConsoleSetupSaveEnvironment (
			&bench486_screen_console_setup_after_environment);
	Bench486ScreenConsoleSetupCapture (result, abi, cw_before, cw_after,
			&bench486_screen_console_setup_call_environment,
			&bench486_screen_console_setup_after_environment);
}

static int Bench486ScreenConsoleSetupCompare (
		const bench486_screen_console_setup_case_t *test_case,
		unsigned short control_word)
{
	if (Q_memcmp (&bench486_screen_console_setup_reference,
			&bench486_screen_console_setup_candidate,
			(int)sizeof(bench486_screen_console_setup_reference)) != 0)
	{
		Bench486Printf ("screen console setup parity FAIL case %s CW %04x current C/ASM %08x/%08x lines %08x/%08x counters %d/%d %d/%d trace %u/%u ABI %u/%u\n",
				test_case->name, control_word,
				bench486_screen_console_setup_reference.current_bits,
				bench486_screen_console_setup_candidate.current_bits,
				bench486_screen_console_setup_reference.lines_bits,
				bench486_screen_console_setup_candidate.lines_bits,
				bench486_screen_console_setup_reference.clearconsole_count,
				bench486_screen_console_setup_candidate.clearconsole_count,
				bench486_screen_console_setup_reference.clearnotify_count,
				bench486_screen_console_setup_candidate.clearnotify_count,
				bench486_screen_console_setup_reference.trace.event_count,
				bench486_screen_console_setup_candidate.trace.event_count,
				bench486_screen_console_setup_reference.abi,
				bench486_screen_console_setup_candidate.abi);
		return 1;
	}
	if (bench486_screen_console_setup_reference.cw_before != control_word ||
			bench486_screen_console_setup_reference.cw_after != control_word ||
			bench486_screen_console_setup_candidate.cw_before != control_word ||
			bench486_screen_console_setup_candidate.cw_after != control_word ||
			bench486_screen_console_setup_reference.tag_before !=
				bench486_screen_console_setup_reference.tag_after ||
			bench486_screen_console_setup_candidate.tag_before !=
				bench486_screen_console_setup_candidate.tag_after ||
			bench486_screen_console_setup_reference.top_before !=
				bench486_screen_console_setup_reference.top_after ||
			bench486_screen_console_setup_candidate.top_before !=
				bench486_screen_console_setup_candidate.top_after ||
			(bench486_screen_console_setup_candidate.abi & 0x20U))
	{
		Bench486Printf ("screen console setup ABI/x87 FAIL case %s CW %04x C %04x/%04x ASM %04x/%04x tags %04x/%04x tops %04x/%04x ABI %u\n",
				test_case->name, control_word,
				bench486_screen_console_setup_reference.cw_before,
				bench486_screen_console_setup_reference.cw_after,
				bench486_screen_console_setup_candidate.cw_before,
				bench486_screen_console_setup_candidate.cw_after,
				bench486_screen_console_setup_candidate.tag_before,
				bench486_screen_console_setup_candidate.tag_after,
				bench486_screen_console_setup_candidate.top_before,
				bench486_screen_console_setup_candidate.top_after,
				bench486_screen_console_setup_candidate.abi);
		return 1;
	}
	return 0;
}

void Bench486ScreenConsoleSetupCases (void)
{
	static const bench486_screen_console_setup_case_t cases[] = {
		{ "loading-early-return", 320, 200, 2, 1, 1, 4, key_console,
			25.5f, 7.25f, 300.0f, 0.016, 0, 7, 4, 19, 0, 1 },
		{ "forced-without-world", 320, 200, 2, 0, 0, 4, key_game,
			12.5f, 0.0f, 300.0f, 0.016, 0, 0, 0, 11, 0, 0 },
		{ "forced-before-signon", 321, 201, 2, 0, 1, 3, key_menu,
			2.25f, 0.0f, 300.0f, 0.016, 0, 0, 0, 12, 0, 0 },
		{ "open-half-odd-height", 320, 201, 2, 0, 1, 4, key_console,
			30.25f, 0.0f, 100.0f, 0.125, 0, 0, 0, 13, 0, 1 },
		{ "open-rise-clamp", 320, 200, 2, 0, 1, 4, key_console,
			90.0f, 0.0f, 1000.0f, 0.25, 0, 0, 0, 14, 0, 0 },
		{ "closed-fall-fraction", 320, 200, 2, 0, 1, 4, key_game,
			23.5f, 0.0f, 80.0f, 0.1, 0, 0, 0, 15, 0, 1 },
		{ "closed-fall-clamp", 320, 200, 2, 0, 1, 4, key_game,
			2.0f, 0.0f, 1000.0f, 0.25, 0, 0, 0, 16, 0, 0 },
		{ "target-equal", 320, 200, 2, 0, 1, 4, key_game,
			0.0f, 0.0f, 275.0f, 0.03125, 0, 0, 0, 17, 0, 1 },
		{ "bottom-page-before-boundary", 320, 200, 2, 0, 1, 4, key_game,
			12.75f, 0.0f, 0.0f, 0.0, 0, 1, 0, 18, 0, 1 },
		{ "notify-at-clear-boundary", 321, 201, 2, 0, 1, 4, key_game,
			-0.75f, 0.0f, 0.0f, 0.0, 0, 2, 1, 27, 0, 0 },
		{ "notify-after-clear-boundary", 320, 200, 2, 0, 1, 4, key_game,
			12.5f, 0.0f, 0.0f, 0.0, 0, 3, 2, 31, 0, 1 },
		{ "zero-pages", 320, 200, 0, 0, 1, 4, key_game,
			0.0f, 0.0f, 0.0f, 0.0, 0, 0, 0, 23, 0, 1 },
		{ "negative-frame-step", 320, 200, 2, 0, 1, 4, key_console,
			0.0f, 0.0f, 100.0f, -0.1, 0, 0, 0, 25, 0, 0 },
		{ "unsigned-large-full-height", 320, 0xf1234567U, 0, 0, 0, 4, key_game,
			1.0f, 3.0f, 300.0f, 0.016, 0, 0, 0, 29, 0, 1 }
	};
	static const unsigned short precision_modes[] = { 0x0000U, 0x0200U, 0x0300U };
	static const unsigned short rounding_modes[] = { 0x0000U, 0x0400U, 0x0800U, 0x0c00U };
	unsigned case_index, precision_index, rounding_index, failures = 0;
	unsigned short control_word;

	Bench486ScreenConsoleSetupSaveState ();
	for (case_index = 0; case_index <
			(unsigned)(sizeof(cases) / sizeof(cases[0])); case_index++)
	{
		for (precision_index = 0; precision_index <
				(unsigned)(sizeof(precision_modes) / sizeof(precision_modes[0]));
				precision_index++)
		{
			for (rounding_index = 0; rounding_index <
					(unsigned)(sizeof(rounding_modes) / sizeof(rounding_modes[0]));
					rounding_index++)
			{
				control_word = (unsigned short)(
						(bench486_screen_console_setup_saved_cw & ~0x0f00U) |
						precision_modes[precision_index] |
						rounding_modes[rounding_index]);
				Bench486ScreenConsoleSetupRun (SCR_SetUpToDrawConsole_Screen_C,
						&cases[case_index], control_word,
						&bench486_screen_console_setup_reference);
				Bench486ScreenConsoleSetupRun (SCR_SetUpToDrawConsole_asm486,
						&cases[case_index], control_word,
						&bench486_screen_console_setup_candidate);
				failures += Bench486ScreenConsoleSetupCompare (&cases[case_index],
						control_word);
			}
		}
	}
	Bench486ScreenConsoleSetupRestoreState ();
	if (failures)
		bench486_memory_failures += (int)failures;
	Bench486Printf ("screen console setup C/ASM state, call-trace, ABI, and x87 precision/rounding parity %s (%u cases x 12 modes; %u failures)\n",
			failures ? "FAIL" : "PASS",
			(unsigned)(sizeof(cases) / sizeof(cases[0])), failures);
}

#endif

#endif
