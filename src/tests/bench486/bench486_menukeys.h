/* C/assembly parity for the key-binding menu and its lookup helper. */
#ifndef BENCH486_MENUKEYS_H
#define BENCH486_MENUKEYS_H

#if defined(BENCH486) && defined(ASM486_SCREEN_OVERLAYS)

#include "client/asm_menutext.h"

#define BMK_TITLE_PATH_INDEX 41U /* gfx/ttl_cstm.lmp */
#define BMK_BINDING_COUNT MD_KEY_BIND_COUNT
#define BMK_EVENT_PIC 2
#define BMK_EVENT_CACHEPIC 4
#define BMK_PICTURE_GUARD_WORDS 2U
#define BMK_TEXT_GUARD_WORDS 2U

extern char *bindnames[][2];
extern char *keybindings[256];
extern int keys_cursor;
extern int bind_grab;
extern double realtime;
extern viddef_t vid;
extern int bench486_menu_dispatch_fixture_active;

typedef struct bench486_menu_keys_find_result_s
{
	unsigned before[2];
	int keys[2];
	unsigned after[2];
	unsigned abi;
	unsigned short cw_before;
	unsigned short cw_after;
} bench486_menu_keys_find_result_t;

typedef struct bench486_menu_keys_result_s
{
	bench486_menu_picture_result_t picture;
	bench486_menu_text_result_t text;
} bench486_menu_keys_result_t;

typedef struct bench486_menu_keys_find_case_s
{
	const char *name;
	const char *command;
	unsigned pattern;
} bench486_menu_keys_find_case_t;

static char bench486_menu_keys_bind_attack[] = "+attack";
static char bench486_menu_keys_bind_attack_extra[] = "+attack2";
static char bench486_menu_keys_bind_attack_suffix[] = "+attack alt";
static char bench486_menu_keys_bind_jump[] = "+jump";
static char bench486_menu_keys_bind_short[] = "+attac";
static char bench486_menu_keys_bind_long[] = "long-command-extra";
static char bench486_menu_keys_bind_empty[] = "";

static const bench486_menu_keys_find_case_t bench486_menu_keys_find_cases[] =
{
	{ "no-match", "+attack", 0 },
	{ "single-exact-late", "+attack", 1 },
	{ "two-prefix-matches", "+attack", 2 },
	{ "empty-command-prefix", "", 3 },
	{ "last-key-match", "+attack", 4 },
	{ "short-binding", "+attack", 5 },
	{ "long-command-prefix", "long-command", 6 },
	{ "full-table-scan", "+attack", 7 }
};

static const unsigned bench486_menu_keys_widths[4] =
	{ 319U, 320U, 640U, 1024U };
static const unsigned bench486_menu_keys_precisions[3] = { 0U, 2U, 3U };
static const unsigned bench486_menu_keys_roundings[4] =
	{ 0U, 1U, 2U, 3U };
static const unsigned bench486_menu_keys_title_widths[3] =
	{ 96U, 127U, 321U };
static const double bench486_menu_keys_times[8] =
	{ 0.05, 0.15, 0.25, 0.35, 0.45, 0.55, 1.25, -0.125 };

static bench486_menu_keys_find_result_t bench486_menu_keys_find_reference;
static bench486_menu_keys_find_result_t bench486_menu_keys_find_candidate;
static bench486_menu_keys_result_t bench486_menu_keys_reference;
static bench486_menu_keys_result_t bench486_menu_keys_candidate;
static char *bench486_menu_keys_saved_bindings[256];

static unsigned short Bench486MenuKeysControlWord (
		unsigned short base, unsigned precision, unsigned rounding)
{
	return (unsigned short)((base & 0xf0ffU) |
			((precision & 3U) << 8) | ((rounding & 3U) << 10));
}

static void Bench486MenuKeysSaveBindings (void)
{
	unsigned i;
	for (i = 0; i < 256U; i++)
		bench486_menu_keys_saved_bindings[i] = keybindings[i];
}

static void Bench486MenuKeysRestoreBindings (void)
{
	unsigned i;
	for (i = 0; i < 256U; i++)
		keybindings[i] = bench486_menu_keys_saved_bindings[i];
}

static void Bench486MenuKeysClearBindings (void)
{
	unsigned i;
	for (i = 0; i < 256U; i++)
		keybindings[i] = NULL;
}

static void Bench486MenuKeysFindBindings (unsigned pattern)
{
	unsigned i;
	Bench486MenuKeysClearBindings ();
	switch (pattern)
	{
	case 0:
		keybindings[1] = bench486_menu_keys_bind_jump;
		keybindings[255] = bench486_menu_keys_bind_attack_extra;
		break;
	case 1:
		keybindings[127] = bench486_menu_keys_bind_attack;
		break;
	case 2:
		keybindings[4] = bench486_menu_keys_bind_attack_extra;
		keybindings[9] = bench486_menu_keys_bind_attack;
		keybindings[17] = bench486_menu_keys_bind_attack_suffix;
		break;
	case 3:
		keybindings[3] = bench486_menu_keys_bind_empty;
		keybindings[11] = bench486_menu_keys_bind_jump;
		keybindings[255] = bench486_menu_keys_bind_empty;
		break;
	case 4:
		keybindings[255] = bench486_menu_keys_bind_attack;
		break;
	case 5:
		keybindings[0] = bench486_menu_keys_bind_short;
		break;
	case 6:
		keybindings[242] = bench486_menu_keys_bind_long;
		break;
	default:
		for (i = 1; i < 255U; i += 2U)
			keybindings[i] = bench486_menu_keys_bind_jump;
		keybindings[255] = bench486_menu_keys_bind_attack;
		break;
	}
}

static unsigned Bench486MenuKeysFindRun (const char *command,
		void (*function)(void), bench486_menu_keys_find_result_t *result)
{
	unsigned arguments[2];
	unsigned abi;
	unsigned short cw_before, cw_after;

	Q_memset (result, 0, sizeof(*result));
	result->before[0] = 0x4d4b1000U;
	result->before[1] = 0x4d4b1001U;
	result->after[0] = 0x4d4bf000U;
	result->after[1] = 0x4d4bf001U;
	arguments[0] = (unsigned)command;
	arguments[1] = (unsigned)result->keys;
	cw_before = Bench486MenuTextGetControlWord ();
	abi = Bench486Call_asm486 (function, 2, arguments, NULL);
	cw_after = Bench486MenuTextGetControlWord ();
	result->abi = abi;
	result->cw_before = cw_before;
	result->cw_after = cw_after;
	if ((abi & 0x20U) || cw_before != cw_after ||
			result->before[0] != 0x4d4b1000U ||
			result->before[1] != 0x4d4b1001U ||
			result->after[0] != 0x4d4bf000U ||
			result->after[1] != 0x4d4bf001U)
		return 0x4d4b0001U;
	return 0;
}

static unsigned Bench486MenuKeysFindDifference (
		const bench486_menu_keys_find_result_t *reference,
		const bench486_menu_keys_find_result_t *candidate)
{
	if (reference->keys[0] != candidate->keys[0] ||
			reference->keys[1] != candidate->keys[1])
		return 0x4d4b0010U;
	if (reference->abi != candidate->abi ||
			reference->cw_before != candidate->cw_before ||
			reference->cw_after != candidate->cw_after)
		return 0x4d4b0011U;
	return 0;
}

static unsigned Bench486MenuKeysRun (unsigned width, int cursor, int grab,
		double time, unsigned short control_word, void (*function)(void),
		bench486_menu_keys_result_t *result)
{
	unsigned abi;
	unsigned short cw_before, cw_after;

	vid.width = width;
	keys_cursor = cursor;
	bind_grab = grab;
	realtime = time;
	bench486_menu_dispatch_fixture_active = 0;
	__asm__ __volatile__ ("fldcw %0" : : "m" (control_word));
	Bench486MenuTextInitTrace ();
	Bench486MenuPictureInitTrace ();
	cw_before = Bench486MenuTextGetControlWord ();
	bench486_menu_text_trace_active = 1;
	abi = Bench486Call_asm486 (function, 0, NULL, NULL);
	bench486_menu_text_trace_active = 0;
	cw_after = Bench486MenuTextGetControlWord ();
	Q_memset (result, 0, sizeof(*result));
	Bench486MenuTextCapture (&result->text, abi, cw_before, cw_after);
	Bench486MenuPictureCapture (&result->picture, abi,
			cw_before, cw_after);
	if ((abi & 0x20U) || cw_before != cw_after)
		return 0x4d4b0020U;
	return 0;
}

static unsigned Bench486MenuKeysExpected (unsigned width, int cursor,
		int grab, double time, unsigned title_width,
		const bench486_menu_keys_result_t *result)
{
	unsigned i;
	unsigned viewport_offset = (width - 320U) >> 1;
	unsigned title_path_index = BMK_TITLE_PATH_INDEX;
	int expected_x = (int)((unsigned)((320 - (int)title_width) / 2) +
			viewport_offset);
	int cursor_x = (int)(130U + viewport_offset);
	int cursor_y = 48 + cursor * 8;
	int cursor_num = grab ? '=' : 12 + (((int)(time * 4.0)) & 1);
	const bench486_menu_picture_event_t *cache_event;
	const bench486_menu_picture_event_t *draw_event;
	unsigned failure = 0;

	if (result->picture.trace.overflow ||
			result->picture.trace.cache_error ||
			result->picture.trace.count != 2U)
		return 0x4d4b0030U;
	cache_event = &result->picture.trace.events[0];
	draw_event = &result->picture.trace.events[1];
	if (cache_event->kind != BMK_EVENT_CACHEPIC || cache_event->x ||
			cache_event->y || cache_event->pic !=
			(qpic_t *)(bench486_menu_picture_fake_pic +
			title_path_index * 4U) || cache_event->translation)
		failure |= 0x4d4b0031U;
	if (draw_event->kind != BMK_EVENT_PIC ||
			draw_event->x != expected_x || draw_event->y != 4 ||
			draw_event->pic != cache_event->pic || draw_event->translation)
		failure |= 0x4d4b0032U;
	for (i = 0; i < BMK_PICTURE_GUARD_WORDS; i++)
		if (result->picture.trace.before[i] != 0x4d500000U + i ||
				result->picture.trace.after[i] != 0x4d50f000U + i)
			failure |= 0x4d4b0033U + i;
	if (result->text.trace.overflow || !result->text.trace.count)
		failure |= 0x4d4b0040U;
	else
	{
		const bench486_menu_text_glyph_t *glyph =
				&result->text.trace.glyphs[
					result->text.trace.count - 1U];
		if (glyph->x != cursor_x || glyph->y != cursor_y ||
				glyph->num != cursor_num)
			failure |= 0x4d4b0041U;
	}
	for (i = 0; i < BMK_TEXT_GUARD_WORDS; i++)
		if (result->text.trace.before[i] != 0x4d540000U + i ||
				result->text.trace.after[i] != 0x4d54f000U + i)
			failure |= 0x4d4b0050U + i;
	return failure;
}

static unsigned Bench486MenuKeysDifference (
		const bench486_menu_keys_result_t *reference,
		const bench486_menu_keys_result_t *candidate)
{
	unsigned failure = Bench486MenuPictureDifference (
			&reference->picture, &candidate->picture);
	failure |= Bench486MenuTextDifference (
			&reference->text, &candidate->text);
	return failure;
}

static void Bench486MenuKeysFindCases (void)
{
	unsigned i;
	unsigned failure = 0;
	unsigned count = sizeof(bench486_menu_keys_find_cases) /
			sizeof(bench486_menu_keys_find_cases[0]);
	unsigned short saved_cw = Bench486MenuTextGetControlWord ();

	Bench486MenuKeysSaveBindings ();
	for (i = 0; i < count && !failure; i++)
	{
		const bench486_menu_keys_find_case_t *test_case =
				&bench486_menu_keys_find_cases[i];
		unsigned case_failure;
		Bench486MenuKeysFindBindings (test_case->pattern);
		case_failure = Bench486MenuKeysFindRun (test_case->command,
				(void (*)(void))M_FindKeysForCommand_C,
				&bench486_menu_keys_find_reference);
		case_failure |= Bench486MenuKeysFindRun (test_case->command,
				(void (*)(void))M_FindKeysForCommand,
				&bench486_menu_keys_find_candidate);
		case_failure |= Bench486MenuKeysFindDifference (
				&bench486_menu_keys_find_reference,
				&bench486_menu_keys_find_candidate);
		if (case_failure)
		{
			Bench486Printf (
					"menu key lookup C/assembly FAIL %s code %08x keys %d/%d and %d/%d\n",
					test_case->name, case_failure,
					bench486_menu_keys_find_reference.keys[0],
					bench486_menu_keys_find_candidate.keys[0],
					bench486_menu_keys_find_reference.keys[1],
					bench486_menu_keys_find_candidate.keys[1]);
			failure = case_failure;
		}
	}
	Bench486MenuKeysRestoreBindings ();
	__asm__ __volatile__ ("fldcw %0" : : "m" (saved_cw));
	if (failure)
		bench486_memory_failures++;
	else
		Bench486Printf ("menu key lookup: %u exact C/assembly scan cases PASS\n",
				count);
}

void Bench486MenuKeysCases (void)
{
	unsigned profile, width_index, precision_index, rounding, grab;
	unsigned cases = 0;
	unsigned failure = 0;
	unsigned short original_cw = Bench486MenuTextGetControlWord ();
	unsigned saved_width = vid.width;
	int saved_cursor = keys_cursor;
	int saved_grab = bind_grab;
	double saved_time = realtime;
	int saved_text_active = bench486_menu_text_trace_active;
	int saved_dispatch_active = bench486_menu_dispatch_fixture_active;
	unsigned saved_title_width =
			bench486_menu_picture_fake_pic[BMK_TITLE_PATH_INDEX * 4U];
static bench486_menu_text_trace_t saved_text_trace;
static bench486_menu_picture_trace_t saved_picture_trace;

	Q_memcpy (&saved_text_trace, &bench486_menu_text_trace,
			sizeof(saved_text_trace));
	Q_memcpy (&saved_picture_trace, &bench486_menu_picture_trace,
			sizeof(saved_picture_trace));
	Bench486MenuKeysSaveBindings ();
	Bench486MenuKeysFindCases ();
	for (profile = 0; profile < 3U && !failure; profile++)
	for (width_index = 0; width_index < 4U && !failure; width_index++)
	for (precision_index = 0; precision_index < 3U && !failure;
			precision_index++)
	for (rounding = 0; rounding < 4U && !failure; rounding++)
	for (grab = 0; grab < 2U && !failure; grab++)
	{
		unsigned case_failure;
		unsigned title_width = bench486_menu_keys_title_widths[
				(profile + width_index + precision_index + rounding) % 3U];
		unsigned short control_word = Bench486MenuKeysControlWord (
				original_cw, bench486_menu_keys_precisions[precision_index],
				bench486_menu_keys_roundings[rounding]);
		double test_time = bench486_menu_keys_times[
				(profile + width_index + precision_index + rounding) % 8U];
		int cursor = (int)((cases + profile + width_index) %
				BMK_BINDING_COUNT);

		Bench486MenuKeysFindBindings (profile);
		bench486_menu_picture_fake_pic[BMK_TITLE_PATH_INDEX * 4U] =
				title_width;
		case_failure = Bench486MenuKeysRun (
				bench486_menu_keys_widths[width_index], cursor, grab,
				test_time, control_word, M_Keys_Draw_C,
				&bench486_menu_keys_reference);
		case_failure |= Bench486MenuKeysRun (
				bench486_menu_keys_widths[width_index], cursor, grab,
				test_time, control_word, M_Keys_Draw,
				&bench486_menu_keys_candidate);
		case_failure |= Bench486MenuKeysExpected (
				bench486_menu_keys_widths[width_index], cursor, grab,
				test_time, title_width, &bench486_menu_keys_reference);
		case_failure |= Bench486MenuKeysExpected (
				bench486_menu_keys_widths[width_index], cursor, grab,
				test_time, title_width, &bench486_menu_keys_candidate);
		case_failure |= Bench486MenuKeysDifference (
				&bench486_menu_keys_reference,
				&bench486_menu_keys_candidate);
		cases++;
		if (case_failure)
		{
			Bench486Printf (
					"menu keys C/assembly FAIL profile %u width %u precision %u rounding %u grab %u code %08x glyphs %u/%u pictures %u/%u\n",
					profile, width_index,
				bench486_menu_keys_precisions[precision_index], rounding,
				grab, case_failure,
				bench486_menu_keys_reference.text.trace.count,
				bench486_menu_keys_candidate.text.trace.count,
				bench486_menu_keys_reference.picture.trace.count,
				bench486_menu_keys_candidate.picture.trace.count);
			failure = case_failure;
		}
	}
	Bench486MenuKeysRestoreBindings ();
	vid.width = saved_width;
	keys_cursor = saved_cursor;
	bind_grab = saved_grab;
	realtime = saved_time;
	bench486_menu_text_trace_active = saved_text_active;
	bench486_menu_dispatch_fixture_active = saved_dispatch_active;
	bench486_menu_picture_fake_pic[BMK_TITLE_PATH_INDEX * 4U] =
			saved_title_width;
	Q_memcpy (&bench486_menu_text_trace, &saved_text_trace,
			sizeof(saved_text_trace));
	Q_memcpy (&bench486_menu_picture_trace, &saved_picture_trace,
			sizeof(saved_picture_trace));
	__asm__ __volatile__ ("fldcw %0" : : "m" (original_cw));
	if (failure)
		bench486_memory_failures++;
	else
		Bench486Printf (
				"menu keys: %u exact C/assembly binding, text, picture, and x87 cases PASS\n",
				cases);
}

#endif
#endif
