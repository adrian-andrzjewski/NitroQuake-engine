/* C/assembly parity for the menu frame dispatcher. */
#ifndef BENCH486_MENUDRAW_H
#define BENCH486_MENUDRAW_H

#if defined(BENCH486) && defined(ASM486_SCREEN_OVERLAYS)

#include "client/asm_menutext.h"

#define BMD_MAX_EVENTS 8
#define BMD_GUARD_WORDS 2

typedef struct bench486_menu_dispatch_event_s
{
	int kind;
	int value;
} bench486_menu_dispatch_event_t;

typedef struct bench486_menu_dispatch_trace_s
{
	unsigned before[BMD_GUARD_WORDS];
	unsigned count;
	unsigned overflow;
	bench486_menu_dispatch_event_t events[BMD_MAX_EVENTS];
	unsigned after[BMD_GUARD_WORDS];
} bench486_menu_dispatch_trace_t;

typedef struct bench486_menu_dispatch_result_s
{
	bench486_menu_dispatch_trace_t trace;
	unsigned abi;
	unsigned short cw_before;
	unsigned short cw_after;
	int state;
	int destination;
	int enter_sound;
	int recursive_draw;
	int copy_everything;
	int full_update;
	unsigned console_bits;
} bench486_menu_dispatch_result_t;

typedef struct bench486_menu_dispatch_case_s
{
	const char *name;
	int state;
	int destination;
	int recursive_draw;
	int enter_sound;
	unsigned console_bits;
	int copy_everything;
	int full_update;
	unsigned video_height;
} bench486_menu_dispatch_case_t;

typedef struct bench486_menu_dispatch_saved_s
{
	int state;
	int destination;
	int enter_sound;
	int recursive_draw;
	int copy_everything;
	int full_update;
	unsigned video_height;
	unsigned console_bits;
} bench486_menu_dispatch_saved_t;

extern int m_state;
extern qboolean m_entersound;
extern qboolean m_recursiveDraw;
extern int scr_copyeverything;
extern int scr_fullupdate;
extern float scr_con_current;
extern unsigned Bench486Call_asm486 (void (*function)(void), unsigned words,
		const unsigned *arguments, float *float_return);

int bench486_menu_dispatch_fixture_active;
static bench486_menu_dispatch_trace_t bench486_menu_dispatch_trace;
static bench486_menu_dispatch_result_t bench486_menu_dispatch_reference;
static bench486_menu_dispatch_result_t bench486_menu_dispatch_candidate;

#define BMD_STATE_CASE(label, value) \
	{ label, value, MD_KEY_MENU, 1, 0, 0, 7, 11, 200 }

static const bench486_menu_dispatch_case_t bench486_menu_dispatch_cases[] =
{
	{ "none-early-return", MD_STATE_NONE, MD_KEY_MENU, 0, 1,
		0x42480000U, 4, 8, 200 },
	{ "wrong-destination-early-return", MD_STATE_MAIN, 0, 0, 1,
		0x42480000U, 4, 8, 200 },
	BMD_STATE_CASE ("state-main", MD_STATE_MAIN),
	BMD_STATE_CASE ("state-singleplayer", MD_STATE_SINGLEPLAYER),
	BMD_STATE_CASE ("state-load", MD_STATE_LOAD),
	BMD_STATE_CASE ("state-save", MD_STATE_SAVE),
	BMD_STATE_CASE ("state-multiplayer", MD_STATE_MULTIPLAYER),
	BMD_STATE_CASE ("state-setup", MD_STATE_SETUP),
	BMD_STATE_CASE ("state-net", MD_STATE_NET),
	BMD_STATE_CASE ("state-options", MD_STATE_OPTIONS),
	BMD_STATE_CASE ("state-video", MD_STATE_VIDEO),
	BMD_STATE_CASE ("state-keys", MD_STATE_KEYS),
	BMD_STATE_CASE ("state-help", MD_STATE_HELP),
	BMD_STATE_CASE ("state-quit", MD_STATE_QUIT),
	BMD_STATE_CASE ("state-serialconfig", MD_STATE_SERIALCONFIG),
	BMD_STATE_CASE ("state-modemconfig", MD_STATE_MODEMCONFIG),
	BMD_STATE_CASE ("state-lanconfig", MD_STATE_LANCONFIG),
	BMD_STATE_CASE ("state-gameoptions", MD_STATE_GAMEOPTIONS),
	BMD_STATE_CASE ("state-search", MD_STATE_SEARCH),
	BMD_STATE_CASE ("state-serverlist", MD_STATE_SERVERLIST),
	{ "fade-and-enter-sound", MD_STATE_MAIN, MD_KEY_MENU, 0, 1,
		0, 0, 9, 240 },
	{ "console-nan-and-enter-sound", MD_STATE_MAIN, MD_KEY_MENU, 0, 1,
		0x7fc00001U, 0, 9, 240 },
	{ "console-negative-zero", MD_STATE_SETUP, MD_KEY_MENU, 0, 0,
		0x80000000U, 0, 9, 240 },
	{ "console-subnormal", MD_STATE_HELP, MD_KEY_MENU, 0, 0,
		1U, 0, 9, 240 },
	{ "recursive-sound", MD_STATE_OPTIONS, MD_KEY_MENU, 1, 1,
		0x42480000U, 6, 10, 200 },
	{ "invalid-negative-state", -1, MD_KEY_MENU, 0, 0,
		0, 2, 5, 200 },
	{ "invalid-high-state", 99, MD_KEY_MENU, 1, 0,
		0, 2, 5, 200 }
};

static unsigned short Bench486MenuDispatchGetControlWord (void)
{
	unsigned short control_word;
	__asm__ __volatile__ ("fnstcw %0" : "=m" (control_word));
	return control_word;
}

static int Bench486MenuDispatchPathEquals (const char *left,
		const char *right)
{
	while (*left && *left == *right)
	{
		left++;
		right++;
	}
	return *left == *right;
}

void Bench486MenuDispatchRecord (int event, int value)
{
	bench486_menu_dispatch_event_t *entry;

	if (!bench486_menu_dispatch_fixture_active)
		return;
	if (bench486_menu_dispatch_trace.count < BMD_MAX_EVENTS)
	{
		entry = &bench486_menu_dispatch_trace.events[
				bench486_menu_dispatch_trace.count];
		entry->kind = event;
		entry->value = value;
	}
	else
		bench486_menu_dispatch_trace.overflow = 1;
	bench486_menu_dispatch_trace.count++;
}

void Bench486MenuDispatchSound (char *path)
{
	if (!bench486_menu_dispatch_fixture_active)
	{
		S_LocalSound (path);
		return;
	}
	if (Bench486MenuDispatchPathEquals (path, "misc/menu2.wav"))
	{
		Bench486MenuDispatchRecord (MD_EVENT_MENU_SOUND, 1);
	}
	else
	{
		Bench486MenuDispatchRecord (MD_EVENT_BAD_SOUND, 0);
	}
}

static void Bench486MenuDispatchInitTrace (void)
{
	unsigned i;
	Q_memset (&bench486_menu_dispatch_trace, 0,
			sizeof(bench486_menu_dispatch_trace));
	for (i = 0; i < BMD_GUARD_WORDS; i++)
	{
		bench486_menu_dispatch_trace.before[i] = 0x4d440000U + i;
		bench486_menu_dispatch_trace.after[i] = 0x4d44f000U + i;
	}
}

static void Bench486MenuDispatchSaveState (
		bench486_menu_dispatch_saved_t *saved)
{
	saved->state = m_state;
	saved->destination = key_dest;
	saved->enter_sound = m_entersound;
	saved->recursive_draw = m_recursiveDraw;
	saved->copy_everything = scr_copyeverything;
	saved->full_update = scr_fullupdate;
	saved->video_height = vid.height;
	Q_memcpy (&saved->console_bits, &scr_con_current,
			sizeof(saved->console_bits));
}

static void Bench486MenuDispatchRestoreState (
		const bench486_menu_dispatch_saved_t *saved)
{
	m_state = saved->state;
	key_dest = saved->destination;
	m_entersound = saved->enter_sound;
	m_recursiveDraw = saved->recursive_draw;
	scr_copyeverything = saved->copy_everything;
	scr_fullupdate = saved->full_update;
	vid.height = saved->video_height;
	Q_memcpy (&scr_con_current, (void *)&saved->console_bits,
			sizeof(saved->console_bits));
}

static void Bench486MenuDispatchPrepare (
		const bench486_menu_dispatch_case_t *test_case)
{
	Bench486MenuDispatchInitTrace ();
	m_state = test_case->state;
	key_dest = (keydest_t)test_case->destination;
	m_recursiveDraw = test_case->recursive_draw;
	m_entersound = test_case->enter_sound;
	scr_copyeverything = test_case->copy_everything;
	scr_fullupdate = test_case->full_update;
	vid.height = test_case->video_height;
	Q_memcpy (&scr_con_current, (void *)&test_case->console_bits,
			sizeof(test_case->console_bits));
}

static void Bench486MenuDispatchCapture (
		bench486_menu_dispatch_result_t *result, unsigned abi,
		unsigned short cw_before, unsigned short cw_after)
{
	Q_memset (result, 0, sizeof(*result));
	Q_memcpy (&result->trace, &bench486_menu_dispatch_trace,
			sizeof(result->trace));
	result->abi = abi;
	result->cw_before = cw_before;
	result->cw_after = cw_after;
	result->state = m_state;
	result->destination = key_dest;
	result->enter_sound = m_entersound;
	result->recursive_draw = m_recursiveDraw;
	result->copy_everything = scr_copyeverything;
	result->full_update = scr_fullupdate;
	Q_memcpy (&result->console_bits, &scr_con_current,
			sizeof(result->console_bits));
}

static unsigned Bench486MenuDispatchRun (
		const bench486_menu_dispatch_case_t *test_case,
		void (*function)(void), bench486_menu_dispatch_result_t *result)
{
	unsigned arguments[1];
	unsigned abi;
	unsigned short cw_before, cw_after;

	arguments[0] = 0;
	Bench486MenuDispatchPrepare (test_case);
	cw_before = Bench486MenuDispatchGetControlWord ();
	bench486_menu_dispatch_fixture_active = 1;
	abi = Bench486Call_asm486 (function, 0, arguments, NULL);
	bench486_menu_dispatch_fixture_active = 0;
	cw_after = Bench486MenuDispatchGetControlWord ();
	Bench486MenuDispatchCapture (result, abi, cw_before, cw_after);
	if ((abi & 0x20U) || cw_before != cw_after)
	{
		Bench486Printf (
				"menu dispatch ABI/x87 FAIL case %s abi %08x cw %04x/%04x\n",
				test_case->name, abi, cw_before, cw_after);
		return 1;
	}
	return 0;
}

static unsigned Bench486MenuDispatchExpectEvent (
		const bench486_menu_dispatch_result_t *result, unsigned index,
		int event, int value)
{
	if (index >= result->trace.count ||
			result->trace.events[index].kind != event ||
			result->trace.events[index].value != value)
		return 0x4d440100U + index;
	return 0;
}

static unsigned Bench486MenuDispatchExpected (
		const bench486_menu_dispatch_case_t *test_case,
		const bench486_menu_dispatch_result_t *result)
{
	unsigned i, count = 0;
	int early = test_case->state == MD_STATE_NONE ||
			test_case->destination != MD_KEY_MENU;
	unsigned console_magnitude = test_case->console_bits & 0x7fffffffU;
	int console_visible = console_magnitude != 0 &&
			!((console_magnitude & 0x7f800000U) == 0x7f800000U &&
			  (console_magnitude & 0x007fffffU) != 0);
	int expected_copy = test_case->copy_everything;
	int expected_full = test_case->full_update;
	int expected_recursive = test_case->recursive_draw;
	int expected_sound = test_case->enter_sound;
	unsigned failure = 0;

	if (!early)
	{
		if (test_case->recursive_draw)
			expected_recursive = 0;
		else
		{
			expected_copy = 1;
			expected_full = 0;
			if (console_visible)
			{
				failure |= Bench486MenuDispatchExpectEvent (result, count++,
						MD_EVENT_CONSOLE_BACKGROUND,
						(int)test_case->video_height);
				failure |= Bench486MenuDispatchExpectEvent (result, count++,
						MD_EVENT_EXTRA_UPDATE, 0);
			}
			else
				failure |= Bench486MenuDispatchExpectEvent (result, count++,
						MD_EVENT_FADE_SCREEN, 0);
		}
		if (test_case->state >= MD_STATE_MAIN &&
				test_case->state <= MD_STATE_LAST)
			failure |= Bench486MenuDispatchExpectEvent (result, count++,
						MD_EVENT_DRAW_BASE + test_case->state, 0);
		if (test_case->enter_sound)
		{
			expected_sound = 0;
			failure |= Bench486MenuDispatchExpectEvent (result, count++,
						MD_EVENT_MENU_SOUND, 1);
		}
		failure |= Bench486MenuDispatchExpectEvent (result, count++,
				MD_EVENT_EXTRA_UPDATE, 0);
	}
	if (failure)
		return failure;
	if (result->trace.overflow || result->trace.count != count)
		return 0x4d440140U;
	for (i = 0; i < BMD_GUARD_WORDS; i++)
		if (result->trace.before[i] != 0x4d440000U + i ||
				result->trace.after[i] != 0x4d44f000U + i)
			return 0x4d440150U + i;
	if (result->state != test_case->state ||
			result->destination != test_case->destination ||
			result->enter_sound != expected_sound ||
			result->recursive_draw != expected_recursive ||
			result->copy_everything != expected_copy ||
			result->full_update != expected_full ||
			result->console_bits != test_case->console_bits)
		return 0x4d440160U;
	return 0;
}

static unsigned Bench486MenuDispatchDifference (
		const bench486_menu_dispatch_result_t *reference,
		const bench486_menu_dispatch_result_t *candidate)
{
	if (reference->abi != candidate->abi ||
			reference->cw_before != candidate->cw_before ||
			reference->cw_after != candidate->cw_after ||
			reference->state != candidate->state ||
			reference->destination != candidate->destination ||
			reference->enter_sound != candidate->enter_sound ||
			reference->recursive_draw != candidate->recursive_draw ||
			reference->copy_everything != candidate->copy_everything ||
			reference->full_update != candidate->full_update ||
			reference->console_bits != candidate->console_bits)
		return 0x4d440170U;
	if (Q_memcmp ((void *)&reference->trace, (void *)&candidate->trace,
			sizeof(reference->trace)))
		return 0x4d440171U;
	return 0;
}

void Bench486MenuDispatchCases (void)
{
	unsigned i, total, failure = 0, reference_failure;
	unsigned candidate_failure, difference;
	bench486_menu_dispatch_saved_t saved;
	void (*c_function)(void) = (void (*)(void))M_Draw_C;
	void (*asm_function)(void) = (void (*)(void))M_Draw;

	Bench486MenuDispatchSaveState (&saved);
	total = sizeof(bench486_menu_dispatch_cases) /
			sizeof(bench486_menu_dispatch_cases[0]);
	for (i = 0; i < total; i++)
	{
		failure |= Bench486MenuDispatchRun (
				&bench486_menu_dispatch_cases[i], c_function,
				&bench486_menu_dispatch_reference);
		failure |= Bench486MenuDispatchRun (
				&bench486_menu_dispatch_cases[i], asm_function,
				&bench486_menu_dispatch_candidate);
		reference_failure = Bench486MenuDispatchExpected (
				&bench486_menu_dispatch_cases[i],
				&bench486_menu_dispatch_reference);
		candidate_failure = Bench486MenuDispatchExpected (
				&bench486_menu_dispatch_cases[i],
				&bench486_menu_dispatch_candidate);
		difference = Bench486MenuDispatchDifference (
				&bench486_menu_dispatch_reference,
				&bench486_menu_dispatch_candidate);
		if (reference_failure || candidate_failure || difference)
			Bench486ReportPrintf (
					"menu dispatch compare case %u expected %08x/%08x diff %08x counts %u/%u\n",
					i, reference_failure, candidate_failure, difference,
					bench486_menu_dispatch_reference.trace.count,
					bench486_menu_dispatch_candidate.trace.count);
		failure |= reference_failure | candidate_failure | difference;
		if (failure)
		{
			Bench486ReportPrintf (
					"menu dispatch C/assembly FAIL case %s code %08x\n",
					bench486_menu_dispatch_cases[i].name, failure);
			break;
		}
	}
	bench486_menu_dispatch_fixture_active = 0;
	Bench486MenuDispatchRestoreState (&saved);
	if (failure)
		bench486_memory_failures++;
	else
		Bench486Printf (
				"menu frame dispatch: %u exact C/assembly state/event cases PASS\n",
				total);
}

#undef BMD_GUARD_WORDS
#undef BMD_MAX_EVENTS
#undef BMD_STATE_CASE

#endif

#endif
