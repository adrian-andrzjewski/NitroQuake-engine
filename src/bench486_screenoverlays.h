/* Direct C/assembly call-order and state parity for screen overlay dispatch. */
#ifndef BENCH486_SCREEN_OVERLAYS_H
#define BENCH486_SCREEN_OVERLAYS_H

#if defined(BENCH486) && defined(ASM486_SCREEN_OVERLAYS)

#include "asm_screenoverlays.h"

#define BSOD_MAX_EVENTS 16
#define BSOD_GUARD_WORDS 4

int bench486_screen_overlays_fixture_active;

extern unsigned Bench486Call_asm486 (void (*function)(void), unsigned words,
		const unsigned *arguments, float *float_return);
extern qboolean scr_drawdialog;
extern qboolean scr_drawloading;
extern int scr_copyeverything;
extern cvar_t scr_showpause;
extern int clearconsole;
extern float scr_con_current;
extern client_state_t cl;
extern keydest_t key_dest;
extern viddef_t vid;

#define BSDC_EVENT_DRAW_CONSOLE 1
#define BSDC_EVENT_DRAW_NOTIFY 2

typedef struct
{
	unsigned count;
	unsigned overflow;
	int event;
	int lines;
	int drawinput;
} bench486_screen_console_draw_trace_t;

typedef struct
{
	int copyeverything;
	int clearconsole;
	int key_destination;
	float console_current;
	bench486_screen_console_draw_trace_t trace;
	unsigned abi;
	unsigned short cw_before;
	unsigned short cw_after;
} bench486_screen_console_draw_result_t;

typedef struct
{
	const char *name;
	float console_current;
	int key_destination;
	int initial_copyeverything;
	int initial_clearconsole;
	int expected_event;
	int expected_lines;
} bench486_screen_console_draw_case_t;

int bench486_screen_console_draw_fixture_active;

static bench486_screen_console_draw_trace_t
		bench486_screen_console_draw_trace;
static bench486_screen_console_draw_result_t
		bench486_screen_console_draw_reference;
static bench486_screen_console_draw_result_t
		bench486_screen_console_draw_candidate;

void Bench486ScreenConsoleDrawCall (int lines, qboolean drawinput)
{
	if (!bench486_screen_console_draw_fixture_active)
	{
		Con_DrawConsole (lines, drawinput);
		return;
	}
	if (bench486_screen_console_draw_trace.count)
		bench486_screen_console_draw_trace.overflow = 1;
	bench486_screen_console_draw_trace.count++;
	bench486_screen_console_draw_trace.event = BSDC_EVENT_DRAW_CONSOLE;
	bench486_screen_console_draw_trace.lines = lines;
	bench486_screen_console_draw_trace.drawinput = drawinput;
}

void Bench486ScreenNotifyDrawCall (void)
{
	if (!bench486_screen_console_draw_fixture_active)
	{
		Con_DrawNotify ();
		return;
	}
	if (bench486_screen_console_draw_trace.count)
		bench486_screen_console_draw_trace.overflow = 1;
	bench486_screen_console_draw_trace.count++;
	bench486_screen_console_draw_trace.event = BSDC_EVENT_DRAW_NOTIFY;
}

typedef struct
{
	unsigned before[BSOD_GUARD_WORDS];
	unsigned count;
	unsigned overflow;
	int events[BSOD_MAX_EVENTS];
	unsigned after[BSOD_GUARD_WORDS];
} bench486_screen_overlays_trace_t;

#define BSOW_PAUSE_PATH 1
#define BSOW_LOADING_PATH 2
#define BSOW_FUNCTION_PAUSE 1
#define BSOW_FUNCTION_LOADING 2

typedef struct
{
	unsigned cache_calls;
	unsigned draw_calls;
	unsigned overflow;
	int path;
	int x;
	int y;
	int pic_match;
} bench486_screen_overlay_widget_trace_t;

typedef struct
{
	const char *name;
	int function;
	unsigned width;
	unsigned height;
	int picture_width;
	int picture_height;
	unsigned showpause_bits;
	int paused;
	int loading;
	int expected_draw;
} bench486_screen_overlay_widget_case_t;

typedef struct
{
	bench486_screen_overlay_widget_trace_t trace;
	unsigned abi;
	unsigned width_after;
	unsigned height_after;
	int paused_after;
	int loading_after;
	unsigned showpause_after;
	unsigned short cw_before;
	unsigned short cw_after;
} bench486_screen_overlay_widget_result_t;

int bench486_screen_overlay_widget_fixture_active;
static qpic_t bench486_screen_overlay_widget_pic;
static bench486_screen_overlay_widget_trace_t
		bench486_screen_overlay_widget_trace;

static int Bench486ScreenOverlayPathEquals (const char *path,
		const char *expected)
{
	int i;
	if (!path)
		return 0;
	for (i = 0; path[i] && expected[i] && path[i] == expected[i]; i++)
		;
	return !path[i] && !expected[i];
}

qpic_t *Bench486ScreenOverlayCachePic (char *path)
{
	if (!bench486_screen_overlay_widget_fixture_active)
		return Draw_CachePic (path);
	if (bench486_screen_overlay_widget_trace.cache_calls)
		bench486_screen_overlay_widget_trace.overflow = 1;
	bench486_screen_overlay_widget_trace.cache_calls++;
	if (Bench486ScreenOverlayPathEquals (path, "gfx/pause.lmp"))
		bench486_screen_overlay_widget_trace.path = BSOW_PAUSE_PATH;
	else if (Bench486ScreenOverlayPathEquals (path, "gfx/loading.lmp"))
		bench486_screen_overlay_widget_trace.path = BSOW_LOADING_PATH;
	else
		bench486_screen_overlay_widget_trace.overflow = 1;
	return &bench486_screen_overlay_widget_pic;
}

void Bench486ScreenOverlayDrawPic (int x, int y, qpic_t *pic)
{
	if (!bench486_screen_overlay_widget_fixture_active)
	{
		Draw_Pic (x, y, pic);
		return;
	}
	if (bench486_screen_overlay_widget_trace.draw_calls)
		bench486_screen_overlay_widget_trace.overflow = 1;
	bench486_screen_overlay_widget_trace.draw_calls++;
	bench486_screen_overlay_widget_trace.x = x;
	bench486_screen_overlay_widget_trace.y = y;
	bench486_screen_overlay_widget_trace.pic_match =
			pic == &bench486_screen_overlay_widget_pic;
}

typedef struct
{
	bench486_screen_overlays_trace_t trace;
	int copyeverything;
	int drawdialog;
	int drawloading;
	int intermission;
	int key_destination;
	unsigned abi;
	unsigned short cw_before;
	unsigned short cw_after;
} bench486_screen_overlays_result_t;

typedef struct
{
	const char *name;
	int drawdialog;
	int drawloading;
	int intermission;
	int key_destination;
	int copyeverything;
	unsigned expected_count;
	int expected[8];
} bench486_screen_overlays_case_t;

static const bench486_screen_overlays_case_t bench486_screen_overlays_cases[] =
{
	{"dialog-priority", 1, 1, 2, key_game, 0, 3,
		{SO_EVENT_SBAR_DRAW, SO_EVENT_FADE_SCREEN, SO_EVENT_NOTIFY_STRING}},
	{"loading-priority", 0, 1, 2, key_game, 0, 2,
		{SO_EVENT_DRAW_LOADING, SO_EVENT_SBAR_DRAW}},
	{"intermission-one-game", 0, 0, 1, key_game, 0, 1,
		{SO_EVENT_INTERMISSION}},
	{"intermission-two-game", 0, 0, 2, key_game, 0, 2,
		{SO_EVENT_FINALE, SO_EVENT_CHECK_CENTER}},
	{"intermission-three-game", 0, 0, 3, key_game, 0, 1,
		{SO_EVENT_CHECK_CENTER}},
	{"intermission-two-menu", 0, 0, 2, key_menu, 0, 8,
		{SO_EVENT_DRAW_RAM, SO_EVENT_DRAW_NET, SO_EVENT_DRAW_TURTLE,
		 SO_EVENT_DRAW_PAUSE, SO_EVENT_CHECK_CENTER, SO_EVENT_SBAR_DRAW,
		 SO_EVENT_DRAW_CONSOLE, SO_EVENT_MENU_DRAW}},
	{"intermission-one-console", 0, 0, 1, key_console, 0, 8,
		{SO_EVENT_DRAW_RAM, SO_EVENT_DRAW_NET, SO_EVENT_DRAW_TURTLE,
		 SO_EVENT_DRAW_PAUSE, SO_EVENT_CHECK_CENTER, SO_EVENT_SBAR_DRAW,
		 SO_EVENT_DRAW_CONSOLE, SO_EVENT_MENU_DRAW}},
	{"default-preserves-copy", 0, 0, 0, key_game, 1, 8,
		{SO_EVENT_DRAW_RAM, SO_EVENT_DRAW_NET, SO_EVENT_DRAW_TURTLE,
		 SO_EVENT_DRAW_PAUSE, SO_EVENT_CHECK_CENTER, SO_EVENT_SBAR_DRAW,
		 SO_EVENT_DRAW_CONSOLE, SO_EVENT_MENU_DRAW}}
};

static bench486_screen_overlays_trace_t bench486_screen_overlays_trace;
static bench486_screen_overlays_result_t bench486_screen_overlays_reference;
static bench486_screen_overlays_result_t bench486_screen_overlays_candidate;
static qboolean bench486_screen_overlays_saved_dialog;
static qboolean bench486_screen_overlays_saved_loading;
static int bench486_screen_overlays_saved_copyeverything;
static int bench486_screen_overlays_saved_intermission;
static keydest_t bench486_screen_overlays_saved_destination;
static unsigned short bench486_screen_overlays_saved_cw;

void Bench486ScreenOverlaysRecordCall (int event)
{
	if (bench486_screen_overlays_trace.count < BSOD_MAX_EVENTS)
		bench486_screen_overlays_trace.events[
				bench486_screen_overlays_trace.count] = event;
	else
		bench486_screen_overlays_trace.overflow = 1;
	bench486_screen_overlays_trace.count++;
}

static unsigned short Bench486ScreenOverlaysGetControlWord (void)
{
	unsigned short control_word;
	__asm__ __volatile__ ("fnstcw %0" : "=m" (control_word));
	return control_word;
}

#include "bench486_menutext.h"
#include "bench486_vidmenudraw.h"
#include "bench486_menugameoptions.h"
#include "bench486_menuoptions.h"
#include "bench486_menusaveload.h"
#include "bench486_menupagedraw.h"
#include "bench486_menunet.h"
#include "bench486_menumodem.h"
#include "bench486_menuserialconfig.h"
#include "bench486_menuserverlist.h"
#include "bench486_menustateentries.h"
#include "bench486_menulanconfigdraw.h"
#include "bench486_menudraw.h"
#include "bench486_menuquit.h"
#include "bench486_menukeys.h"
#include "bench486_menusetup.h"
#include "bench486_menusearchdraw.h"

static void Bench486ScreenOverlaysInitTrace (void)
{
	unsigned i;
	Q_memset (&bench486_screen_overlays_trace, 0,
			sizeof(bench486_screen_overlays_trace));
	for (i = 0; i < BSOD_GUARD_WORDS; i++)
	{
		bench486_screen_overlays_trace.before[i] = 0x534f1000U + i;
		bench486_screen_overlays_trace.after[i] = 0x534f2000U + i;
	}
}

static void Bench486ScreenOverlaysSaveState (void)
{
	bench486_screen_overlays_saved_dialog = scr_drawdialog;
	bench486_screen_overlays_saved_loading = scr_drawloading;
	bench486_screen_overlays_saved_copyeverything = scr_copyeverything;
	bench486_screen_overlays_saved_intermission = cl.intermission;
	bench486_screen_overlays_saved_destination = key_dest;
	bench486_screen_overlays_saved_cw = Bench486ScreenOverlaysGetControlWord ();
}

static void Bench486ScreenOverlaysRestoreState (void)
{
	scr_drawdialog = bench486_screen_overlays_saved_dialog;
	scr_drawloading = bench486_screen_overlays_saved_loading;
	scr_copyeverything = bench486_screen_overlays_saved_copyeverything;
	cl.intermission = bench486_screen_overlays_saved_intermission;
	key_dest = bench486_screen_overlays_saved_destination;
}

static void Bench486ScreenOverlaysPrepare (
		const bench486_screen_overlays_case_t *test_case)
{
	scr_drawdialog = test_case->drawdialog;
	scr_drawloading = test_case->drawloading;
	scr_copyeverything = test_case->copyeverything;
	cl.intermission = test_case->intermission;
	key_dest = (keydest_t)test_case->key_destination;
	Bench486ScreenOverlaysInitTrace ();
}

static const bench486_screen_console_draw_case_t
		bench486_screen_console_draw_cases[] =
{
	{"zero-game-notifies", 0.0f, key_game, 0, 7,
		BSDC_EVENT_DRAW_NOTIFY, 0},
	{"negative-zero-message-notifies", -0.0f, key_message, 1, 9,
		BSDC_EVENT_DRAW_NOTIFY, 0},
	{"zero-console-suppressed", 0.0f, key_console, 0, 11, 0, 0},
	{"zero-menu-suppressed", 0.0f, key_menu, 1, 13, 0, 0},
	{"positive-fraction-truncates", 12.75f, key_game, 0, 15,
		BSDC_EVENT_DRAW_CONSOLE, 12},
	{"negative-fraction-truncates", -12.75f, key_message, 1, 17,
		BSDC_EVENT_DRAW_CONSOLE, -12},
	{"positive-subunit-still-draws", 0.75f, key_menu, 0, 19,
		BSDC_EVENT_DRAW_CONSOLE, 0},
	{"negative-subunit-still-draws", -0.75f, key_console, 1, 21,
		BSDC_EVENT_DRAW_CONSOLE, 0},
	{"integer-console-height", 200.0f, key_game, 0, 23,
		BSDC_EVENT_DRAW_CONSOLE, 200}
};

static void Bench486ScreenConsoleDrawPrepare (
		const bench486_screen_console_draw_case_t *test_case)
{
	Q_memset (&bench486_screen_console_draw_trace, 0,
			sizeof(bench486_screen_console_draw_trace));
	scr_con_current = test_case->console_current;
	key_dest = (keydest_t)test_case->key_destination;
	scr_copyeverything = test_case->initial_copyeverything;
	clearconsole = test_case->initial_clearconsole;
}

static unsigned Bench486ScreenConsoleDrawRun (
		void (*function)(void),
		const bench486_screen_console_draw_case_t *test_case,
		bench486_screen_console_draw_result_t *result)
{
	Q_memset (result, 0, sizeof(*result));
	Bench486ScreenConsoleDrawPrepare (test_case);
	result->cw_before = Bench486ScreenOverlaysGetControlWord ();
	bench486_screen_console_draw_fixture_active = 1;
	result->abi = Bench486Call_asm486 (function, 0, NULL, NULL);
	bench486_screen_console_draw_fixture_active = 0;
	result->cw_after = Bench486ScreenOverlaysGetControlWord ();
	result->copyeverything = scr_copyeverything;
	result->clearconsole = clearconsole;
	result->key_destination = key_dest;
	result->console_current = scr_con_current;
	Q_memcpy (&result->trace, &bench486_screen_console_draw_trace,
			sizeof(result->trace));
	return result->abi;
}

static unsigned Bench486ScreenConsoleDrawExpected (
		const bench486_screen_console_draw_case_t *test_case,
		const bench486_screen_console_draw_result_t *result)
{
	int expected_copyeverything;
	int expected_clearconsole;

	expected_copyeverything = test_case->initial_copyeverything;
	expected_clearconsole = test_case->initial_clearconsole;
	if (test_case->expected_event == BSDC_EVENT_DRAW_CONSOLE)
	{
		expected_copyeverything = 1;
		expected_clearconsole = 0;
	}
	if (result->copyeverything != expected_copyeverything ||
			result->clearconsole != expected_clearconsole ||
			result->key_destination != test_case->key_destination ||
			Q_memcmp ((void *)&result->console_current,
					(void *)&test_case->console_current, sizeof(float)) ||
			result->trace.overflow ||
			result->trace.count !=
				(test_case->expected_event ? 1U : 0U))
		return 0x53430001U;
	if (test_case->expected_event &&
			result->trace.event != test_case->expected_event)
		return 0x53430002U;
	if (test_case->expected_event == BSDC_EVENT_DRAW_CONSOLE &&
			(result->trace.lines != test_case->expected_lines ||
			 result->trace.drawinput != 1))
		return 0x53430003U;
	if (result->cw_before != result->cw_after ||
			(result->abi & 0x20U))
		return 0x53430004U;
	return 0;
}

void Bench486ScreenConsoleDrawCases (void)
{
	unsigned i, mode, failure;
	unsigned short saved_cw, test_cw;
	float saved_current;
	int saved_copyeverything, saved_clearconsole;
	keydest_t saved_destination;
	unsigned case_count;

	saved_current = scr_con_current;
	saved_destination = key_dest;
	saved_copyeverything = scr_copyeverything;
	saved_clearconsole = clearconsole;
	saved_cw = Bench486ScreenOverlaysGetControlWord ();
	case_count = sizeof(bench486_screen_console_draw_cases) /
			sizeof(bench486_screen_console_draw_cases[0]);
	failure = 0;
	for (mode = 0; mode < 4 && !failure; mode++)
	{
		test_cw = (unsigned short)((saved_cw & ~0x0c00U) | (mode << 10));
		__asm__ __volatile__ ("fldcw %0" : : "m" (test_cw));
		for (i = 0; i < case_count; i++)
		{
			unsigned c_abi, asm_abi;

			c_abi = Bench486ScreenConsoleDrawRun (
					SCR_DrawConsole_Screen_C,
					&bench486_screen_console_draw_cases[i],
					&bench486_screen_console_draw_reference);
			failure |= Bench486ScreenConsoleDrawExpected (
					&bench486_screen_console_draw_cases[i],
					&bench486_screen_console_draw_reference);
			asm_abi = Bench486ScreenConsoleDrawRun (
					SCR_DrawConsole,
					&bench486_screen_console_draw_cases[i],
					&bench486_screen_console_draw_candidate);
			failure |= Bench486ScreenConsoleDrawExpected (
					&bench486_screen_console_draw_cases[i],
					&bench486_screen_console_draw_candidate);
			if (c_abi != asm_abi || Q_memcmp (
					&bench486_screen_console_draw_reference,
					&bench486_screen_console_draw_candidate,
					sizeof(bench486_screen_console_draw_reference)))
				failure |= 0x53430010U;
			if (failure)
			{
				Bench486Printf ("screen console draw FAIL case %s x87 round %u code %08x\n",
						bench486_screen_console_draw_cases[i].name,
						mode, failure);
				break;
			}
		}
	}
	bench486_screen_console_draw_fixture_active = 0;
	scr_con_current = saved_current;
	key_dest = saved_destination;
	scr_copyeverything = saved_copyeverything;
	clearconsole = saved_clearconsole;
	__asm__ __volatile__ ("fldcw %0" : : "m" (saved_cw));
	if (failure)
		bench486_memory_failures++;
	else
		Bench486Printf ("screen console draw %u exact C/assembly state, call and ABI cases x 4 x87 rounding modes PASS\n",
				case_count);
}

static void Bench486ScreenOverlaysCapture (
		bench486_screen_overlays_result_t *result, unsigned abi,
		unsigned short cw_before, unsigned short cw_after)
{
	Q_memset (result, 0, sizeof(*result));
	Q_memcpy (&result->trace, &bench486_screen_overlays_trace,
			sizeof(result->trace));
	result->copyeverything = scr_copyeverything;
	result->drawdialog = scr_drawdialog;
	result->drawloading = scr_drawloading;
	result->intermission = cl.intermission;
	result->key_destination = key_dest;
	result->abi = abi;
	result->cw_before = cw_before;
	result->cw_after = cw_after;
}

static unsigned Bench486ScreenOverlaysRun (
		const bench486_screen_overlays_case_t *test_case,
		const char *implementation,
		void (*function)(unsigned, qboolean),
		bench486_screen_overlays_result_t *result)
{
	unsigned arguments[2];
	unsigned abi;
	unsigned short cw_before, cw_after;

	Bench486ScreenOverlaysPrepare (test_case);
	arguments[0] = 0;
	arguments[1] = 0;
	cw_before = Bench486ScreenOverlaysGetControlWord ();
	bench486_screen_overlays_fixture_active = 1;
	abi = Bench486Call_asm486 ((void (*)(void))function, 2, arguments, NULL);
	bench486_screen_overlays_fixture_active = 0;
	cw_after = Bench486ScreenOverlaysGetControlWord ();
	Bench486ScreenOverlaysCapture (result, abi, cw_before, cw_after);
	if ((abi & 0x20U) || cw_before != cw_after ||
			cw_before != bench486_screen_overlays_saved_cw)
	{
		Bench486Printf ("screen overlays ABI/x87 FAIL case %s implementation %s abi %08x cw %04x/%04x saved %04x\n",
				test_case->name, implementation, abi, cw_before, cw_after,
				bench486_screen_overlays_saved_cw);
		return 1;
	}
	return 0;
}

static unsigned Bench486ScreenOverlaysDifference (
		const bench486_screen_overlays_result_t *reference,
		const bench486_screen_overlays_result_t *candidate)
{
	if (reference->abi != candidate->abi ||
			reference->cw_before != candidate->cw_before ||
			reference->cw_after != candidate->cw_after)
		return 0x534f0001U;
	if (reference->copyeverything != candidate->copyeverything ||
			reference->drawdialog != candidate->drawdialog ||
			reference->drawloading != candidate->drawloading ||
			reference->intermission != candidate->intermission ||
			reference->key_destination != candidate->key_destination)
		return 0x534f0002U;
	if (Q_memcmp ((void *)&reference->trace, (void *)&candidate->trace,
			sizeof(reference->trace)))
		return 0x534f0003U;
	return 0;
}

static unsigned Bench486ScreenOverlaysExpected (
		const bench486_screen_overlays_case_t *test_case,
		const bench486_screen_overlays_result_t *result)
{
	unsigned i;
	int expected_copyeverything;

	expected_copyeverything = test_case->copyeverything;
	if (test_case->drawdialog)
		expected_copyeverything = 1;
	if (result->copyeverything != expected_copyeverything ||
			result->drawdialog != test_case->drawdialog ||
			result->drawloading != test_case->drawloading ||
			result->intermission != test_case->intermission ||
			result->key_destination != test_case->key_destination ||
			result->trace.overflow ||
			result->trace.count != test_case->expected_count)
		return 0x534f0010U;
	for (i = 0; i < BSOD_GUARD_WORDS; i++)
		if (result->trace.before[i] != 0x534f1000U + i ||
				result->trace.after[i] != 0x534f2000U + i)
			return 0x534f0020U + i;
	for (i = 0; i < test_case->expected_count; i++)
		if (result->trace.events[i] != test_case->expected[i])
			return 0x534f0030U + i;
	return 0;
}

static void Bench486ScreenOverlayWidgetInstall (
		const bench486_screen_overlay_widget_case_t *test_case)
{
	vid.width = test_case->width;
	vid.height = test_case->height;
	bench486_screen_overlay_widget_pic.width = test_case->picture_width;
	bench486_screen_overlay_widget_pic.height = test_case->picture_height;
	Q_memcpy (&scr_showpause.value, (void *)&test_case->showpause_bits,
			sizeof(scr_showpause.value));
	cl.paused = test_case->paused;
	scr_drawloading = test_case->loading;
	Q_memset (&bench486_screen_overlay_widget_trace, 0,
			sizeof(bench486_screen_overlay_widget_trace));
}

static unsigned Bench486ScreenOverlayWidgetRun (
		const bench486_screen_overlay_widget_case_t *test_case,
		void (*function)(void),
		bench486_screen_overlay_widget_result_t *result)
{
	Q_memset (result, 0, sizeof(*result));
	Bench486ScreenOverlayWidgetInstall (test_case);
	result->cw_before = Bench486ScreenOverlaysGetControlWord ();
	bench486_screen_overlay_widget_fixture_active = 1;
	result->abi = Bench486Call_asm486 (function, 0, NULL, NULL);
	bench486_screen_overlay_widget_fixture_active = 0;
	result->cw_after = Bench486ScreenOverlaysGetControlWord ();
	result->width_after = vid.width;
	result->height_after = vid.height;
	result->paused_after = cl.paused;
	result->loading_after = scr_drawloading;
	Q_memcpy (&result->showpause_after, &scr_showpause.value,
			sizeof(scr_showpause.value));
	Q_memcpy (&result->trace, &bench486_screen_overlay_widget_trace,
			sizeof(result->trace));
	return result->abi;
}

static unsigned Bench486ScreenOverlayWidgetExpected (
		const bench486_screen_overlay_widget_case_t *test_case,
		const bench486_screen_overlay_widget_result_t *result)
{
	unsigned expected_path;
	int expected_x, expected_y;
	expected_path = test_case->function == BSOW_FUNCTION_PAUSE ?
			BSOW_PAUSE_PATH : BSOW_LOADING_PATH;
	if (result->trace.overflow ||
			result->trace.cache_calls != (unsigned)test_case->expected_draw ||
			result->trace.draw_calls != (unsigned)test_case->expected_draw ||
			result->width_after != test_case->width ||
			result->height_after != test_case->height ||
			result->paused_after != test_case->paused ||
			result->loading_after != test_case->loading ||
			result->showpause_after != test_case->showpause_bits ||
			result->cw_before != result->cw_after ||
			(result->abi & 0x20U))
		return 0x534f1001U;
	if (!test_case->expected_draw)
	{
		if (result->trace.path || result->trace.x || result->trace.y ||
				result->trace.pic_match)
			return 0x534f1002U;
		return 0;
	}
	expected_x = (int)((test_case->width -
			(unsigned)test_case->picture_width) / 2U);
	expected_y = (int)((test_case->height - 48U -
			(unsigned)test_case->picture_height) / 2U);
	if (result->trace.path != (int)expected_path ||
			result->trace.x != expected_x ||
			result->trace.y != expected_y ||
			!result->trace.pic_match)
		return 0x534f1003U;
	return 0;
}

void Bench486ScreenOverlayWidgetCases (void)
{
	static const bench486_screen_overlay_widget_case_t cases[] = {
		{"pause-positive-zero-hidden", BSOW_FUNCTION_PAUSE,
			320, 200, 64, 24, 0x00000000U, 1, 0, 0},
		{"pause-negative-zero-hidden", BSOW_FUNCTION_PAUSE,
			320, 200, 64, 24, 0x80000000U, 1, 0, 0},
		{"pause-not-paused", BSOW_FUNCTION_PAUSE,
			320, 200, 64, 24, 0x3f800000U, 0, 0, 0},
		{"pause-centered-odd", BSOW_FUNCTION_PAUSE,
			641, 481, 272, 33, 0x3f800000U, 1, 0, 1},
		{"pause-unsigned-underflow", BSOW_FUNCTION_PAUSE,
			319, 47, 320, 64, 0x3f800000U, 1, 0, 1},
		{"pause-nan-x87-branch", BSOW_FUNCTION_PAUSE,
			400, 200, 80, 24, 0x7fc00000U, 1, 0, 0},
		{"loading-hidden", BSOW_FUNCTION_LOADING,
			320, 200, 64, 24, 0x3f800000U, 1, 0, 0},
		{"loading-wide-centered", BSOW_FUNCTION_LOADING,
			640, 400, 320, 64, 0x3f800000U, 1, 1, 1},
		{"loading-positive-odd", BSOW_FUNCTION_LOADING,
			321, 480, 320, 33, 0x3f800000U, 1, 1, 1},
		{"loading-unsigned-underflow", BSOW_FUNCTION_LOADING,
			319, 47, 320, 64, 0x3f800000U, 1, 1, 1}
	};
	bench486_screen_overlay_widget_result_t reference, candidate;
	viddef_t saved_vid;
	float saved_showpause;
	int saved_paused, saved_loading;
	unsigned i, failure;
	unsigned short saved_cw;

	saved_vid = vid;
	saved_showpause = scr_showpause.value;
	saved_paused = cl.paused;
	saved_loading = scr_drawloading;
	saved_cw = Bench486ScreenOverlaysGetControlWord ();
	failure = 0;
	for (i = 0; i < sizeof(cases) / sizeof(cases[0]) && !failure; i++)
	{
		void (*c_function)(void);
		void (*asm_function)(void);
		unsigned c_abi, asm_abi;
		c_function = cases[i].function == BSOW_FUNCTION_PAUSE ?
				SCR_DrawPause_Screen_C : SCR_DrawLoading_Screen_C;
		asm_function = cases[i].function == BSOW_FUNCTION_PAUSE ?
				SCR_DrawPause : SCR_DrawLoading;
		c_abi = Bench486ScreenOverlayWidgetRun (&cases[i], c_function,
				&reference);
		failure |= Bench486ScreenOverlayWidgetExpected (&cases[i],
				&reference);
		asm_abi = Bench486ScreenOverlayWidgetRun (&cases[i], asm_function,
				&candidate);
		failure |= Bench486ScreenOverlayWidgetExpected (&cases[i],
				&candidate);
		if (c_abi != asm_abi || Q_memcmp (&reference, &candidate,
				sizeof(reference)))
			failure |= 0x534f1010U;
		if (failure)
			Bench486Printf ("screen overlay widget %s FAIL code %08x C/ASM x %d/%d y %d/%d\n",
					cases[i].name, failure, reference.trace.x,
					candidate.trace.x, reference.trace.y,
					candidate.trace.y);
	}
	bench486_screen_overlay_widget_fixture_active = 0;
	vid = saved_vid;
	scr_showpause.value = saved_showpause;
	cl.paused = saved_paused;
	scr_drawloading = saved_loading;
	__asm__ __volatile__ ("fldcw %0" : : "m" (saved_cw));
	if (failure)
		bench486_memory_failures++;
	else
		Bench486Printf ("screen overlay pause/loading 10 exact C/ASM visibility, path, placement and ABI cases PASS\n");
}

void Bench486ScreenOverlaysCases (void)
{
	unsigned i;
	unsigned failure;
	unsigned total;
	unsigned short cw_after;

	Bench486ScreenOverlaysSaveState ();
	failure = 0;
	total = sizeof(bench486_screen_overlays_cases) /
			sizeof(bench486_screen_overlays_cases[0]);
	for (i = 0; i < total; i++)
	{
		failure |= Bench486ScreenOverlaysRun (
				&bench486_screen_overlays_cases[i], "C",
				SCR_DrawScreenOverlays_Screen_C,
				&bench486_screen_overlays_reference);
		failure |= Bench486ScreenOverlaysExpected (
				&bench486_screen_overlays_cases[i],
				&bench486_screen_overlays_reference);
		failure |= Bench486ScreenOverlaysRun (
				&bench486_screen_overlays_cases[i], "assembly",
				SCR_DrawScreenOverlays_asm486,
				&bench486_screen_overlays_candidate);
		failure |= Bench486ScreenOverlaysExpected (
				&bench486_screen_overlays_cases[i],
				&bench486_screen_overlays_candidate);
		failure |= Bench486ScreenOverlaysDifference (
				&bench486_screen_overlays_reference,
				&bench486_screen_overlays_candidate);
		if (failure)
		{
			Bench486Printf ("screen overlays FAIL case %s code %08x\n",
					bench486_screen_overlays_cases[i].name, failure);
			break;
		}
	}
	Bench486ScreenOverlaysRestoreState ();
	cw_after = Bench486ScreenOverlaysGetControlWord ();
	if (cw_after != bench486_screen_overlays_saved_cw)
		failure |= 0x534f0040U;
	if (failure)
		bench486_memory_failures++;
	else
		Bench486Printf ("screen overlay dispatch %u exact C/assembly branch cases; event and state parity PASS\n",
				total);

	Bench486ScreenOverlayWidgetCases ();
	Bench486MenuTextCases ();
	Bench486MenuPictureCases ();
	Bench486VIDMenuDrawCases ();
	Bench486MenuGameOptionsCases ();
	Bench486MenuPageDrawCases ();
	Bench486MenuOptionsCases ();
	Bench486MenuMultiPlayerCases ();
	Bench486MenuNetCases ();
	Bench486MenuModemCases ();
	Bench486MenuSerialConfigCases ();
	Bench486MenuLanConfigCases ();
	Bench486MenuHelpPageCases ();
	Bench486MenuSaveLoadCases ();
	Bench486MenuTextBoxCases ();
	Bench486MenuDispatchCases ();
	Bench486MenuQuitCases ();
	Bench486MenuKeysCases ();
	Bench486MenuSetupCases ();
	Bench486MenuSearchDrawCases ();
	Bench486MenuServerListCases ();
	Bench486MenuStateEntryCases ();
	Bench486ScreenConsoleDrawCases ();
}

#endif
#endif
