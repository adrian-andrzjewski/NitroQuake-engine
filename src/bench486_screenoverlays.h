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
extern client_state_t cl;
extern keydest_t key_dest;

typedef struct
{
	unsigned before[BSOD_GUARD_WORDS];
	unsigned count;
	unsigned overflow;
	int events[BSOD_MAX_EVENTS];
	unsigned after[BSOD_GUARD_WORDS];
} bench486_screen_overlays_trace_t;

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

	Bench486MenuTextCases ();
}

#endif
#endif
