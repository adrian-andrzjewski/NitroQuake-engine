/* C/assembly parity for the player setup menu. */
/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
#ifndef BENCH486_MENUSETUP_H
#define BENCH486_MENUSETUP_H

#if defined(BENCH486) && defined(ASM486_SCREEN_OVERLAYS)

#include "client/asm_menutext.h"
#include "client/asm_playertranslation.h"

#define BMSETUP_EVENT_TRANSPIC 1
#define BMSETUP_EVENT_PIC 2
#define BMSETUP_EVENT_CACHEPIC 4
#define BMSETUP_PICTURE_GUARD_WORDS 2U
#define BMSETUP_TEXT_GUARD_WORDS 2U

extern int setup_cursor;
extern int setup_cursor_table[5];
extern char setup_hostname[16];
extern char setup_myname[16];
extern int setup_top;
extern int setup_bottom;
extern double realtime;
extern viddef_t vid;
extern int bench486_menu_dispatch_fixture_active;

typedef struct bench486_menu_setup_case_s
{
	unsigned width;
	int cursor;
	int top;
	int bottom;
	const char *hostname;
	const char *myname;
	double time;
	unsigned title_width;
	unsigned short control_word;
} bench486_menu_setup_case_t;

typedef struct bench486_menu_setup_result_s
{
	bench486_menu_picture_result_t picture;
	bench486_menu_text_result_t text;
	byte identity[PT_IDENTITY_BYTES];
	byte translation[PT_IDENTITY_BYTES];
} bench486_menu_setup_result_t;

static const unsigned bench486_menu_setup_widths[4] =
	{ 319U, 320U, 640U, 1024U };
static const unsigned bench486_menu_setup_precisions[3] = { 0U, 2U, 3U };
static const unsigned bench486_menu_setup_roundings[4] =
	{ 0U, 1U, 2U, 3U };
static const int bench486_menu_setup_colors[6] = { 0, 1, 7, 8, 14, 15 };
static const unsigned bench486_menu_setup_title_widths[3] =
	{ 96U, 127U, 321U };
static const char *const bench486_menu_setup_names[4] =
	{ "", "A", "NitroHost", "123456789012345" };
static const double bench486_menu_setup_times[8] =
	{ 0.05, 0.15, 0.25, 0.35, 0.45, 0.55, 1.25, -0.125 };

static bench486_menu_setup_result_t bench486_menu_setup_reference;
static bench486_menu_setup_result_t bench486_menu_setup_candidate;
static byte bench486_menu_setup_saved_identity[PT_IDENTITY_BYTES];
static byte bench486_menu_setup_saved_translation[PT_IDENTITY_BYTES];

static unsigned Bench486MenuSetupFindPathIndex (const char *path)
{
	unsigned i;
	unsigned count = sizeof(bench486_menu_cache_paths) /
			sizeof(bench486_menu_cache_paths[0]);

	for (i = 0; i < count; i++)
	{
		const char *left = path;
		const char *right = bench486_menu_cache_paths[i];
		while (*left && *right && *left == *right)
		{
			left++;
			right++;
		}
		if (!*left && !*right)
			return i;
	}
	return count;
}

static unsigned short Bench486MenuSetupControlWord (
		unsigned short base, unsigned precision, unsigned rounding)
{
	return (unsigned short)((base & 0xf0ffU) |
			((precision & 3U) << 8) | ((rounding & 3U) << 10));
}

static unsigned Bench486MenuSetupRun (
		const bench486_menu_setup_case_t *test_case,
		void (*function)(void), bench486_menu_setup_result_t *result)
{
	unsigned abi;
	unsigned short cw_before, cw_after;

	vid.width = test_case->width;
	setup_cursor = test_case->cursor;
	setup_top = test_case->top;
	setup_bottom = test_case->bottom;
	Q_strcpy (setup_hostname, (char *)test_case->hostname);
	Q_strcpy (setup_myname, (char *)test_case->myname);
	realtime = test_case->time;
	bench486_menu_dispatch_fixture_active = 0;
	__asm__ __volatile__ ("fldcw %0" : : "m" (test_case->control_word));
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
	Q_memcpy (result->identity, identityTable, sizeof(result->identity));
	Q_memcpy (result->translation, translationTable,
			sizeof(result->translation));
	if ((abi & 0x20U) || cw_before != cw_after)
		return 0x4d530001U;
	return 0;
}

static unsigned Bench486MenuSetupExpected (
		const bench486_menu_setup_case_t *test_case,
		unsigned plaque_index, unsigned title_index,
		const bench486_menu_setup_result_t *result)
{
	unsigned i;
	unsigned viewport_offset = (test_case->width - 320U) >> 1;
	unsigned plaque_pic = plaque_index * 4U;
	unsigned title_pic = title_index * 4U;
	int title_x = (320 - (int)test_case->title_width) / 2;
	int expected_title_x = (int)((unsigned)title_x + viewport_offset);
	int cursor_bit = ((int)(test_case->time * 4.0)) & 1;
	int logical_cursor_x = 56;
	int cursor_character = 12 + cursor_bit;
	int cursor_y = setup_cursor_table[test_case->cursor];
	const bench486_menu_picture_event_t *event;
	unsigned failure = 0;

	if (result->picture.trace.overflow || result->picture.trace.cache_error ||
			result->picture.trace.count < 4U)
		return 0x4d530010U;
	event = &result->picture.trace.events[0];
	if (event->kind != BMSETUP_EVENT_CACHEPIC || event->x || event->y ||
			event->pic != (qpic_t *)(bench486_menu_picture_fake_pic + plaque_pic) ||
			event->translation)
		failure |= 0x4d530011U;
	event = &result->picture.trace.events[1];
	if (event->kind != BMSETUP_EVENT_TRANSPIC ||
			event->x != (int)((unsigned)16 + viewport_offset) || event->y != 4 ||
			event->pic != (qpic_t *)(bench486_menu_picture_fake_pic + plaque_pic) ||
			event->translation)
		failure |= 0x4d530012U;
	event = &result->picture.trace.events[2];
	if (event->kind != BMSETUP_EVENT_CACHEPIC || event->x || event->y ||
			event->pic != (qpic_t *)(bench486_menu_picture_fake_pic + title_pic) ||
			event->translation)
		failure |= 0x4d530013U;
	event = &result->picture.trace.events[3];
	if (event->kind != BMSETUP_EVENT_PIC ||
			event->x != expected_title_x || event->y != 4 ||
			event->pic != (qpic_t *)(bench486_menu_picture_fake_pic + title_pic) ||
			event->translation)
		failure |= 0x4d530014U;
	for (i = 0; i < BMSETUP_PICTURE_GUARD_WORDS; i++)
		if (result->picture.trace.before[i] != 0x4d500000U + i ||
				result->picture.trace.after[i] != 0x4d50f000U + i)
			failure |= 0x4d530020U + i;

	if (test_case->cursor == 0)
	{
		logical_cursor_x = 168 + 8 * (int)strlen(test_case->hostname);
		cursor_character = 10 + cursor_bit;
	}
	else if (test_case->cursor == 1)
	{
		logical_cursor_x = 168 + 8 * (int)strlen(test_case->myname);
		cursor_character = 10 + cursor_bit;
	}
	if (result->text.trace.overflow || !result->text.trace.count)
		failure |= 0x4d530030U;
	else
	{
		const bench486_menu_text_glyph_t *glyph =
				&result->text.trace.glyphs[result->text.trace.count - 1U];
		int expected_cursor_x = (int)((unsigned)logical_cursor_x +
				viewport_offset);
		if (glyph->x != expected_cursor_x || glyph->y != cursor_y ||
				glyph->num != cursor_character)
			failure |= 0x4d530031U;
	}
	for (i = 0; i < BMSETUP_TEXT_GUARD_WORDS; i++)
		if (result->text.trace.before[i] != 0x4d540000U + i ||
				result->text.trace.after[i] != 0x4d54f000U + i)
			failure |= 0x4d530040U + i;

	for (i = 0; i < PT_IDENTITY_BYTES; i++)
	{
		byte expected_identity = (byte)i;
		byte expected_translation = (byte)i;
		if (i >= PT_TOP_RANGE && i < PT_TOP_RANGE + PT_RANGE_BYTES)
		{
			unsigned offset = i - PT_TOP_RANGE;
			unsigned top = (unsigned)test_case->top * PT_RANGE_BYTES;
			expected_translation = (byte)(top +
					(top < 128U ? offset : 15U - offset));
		}
		else if (i >= PT_BOTTOM_RANGE &&
				i < PT_BOTTOM_RANGE + PT_RANGE_BYTES)
		{
			unsigned offset = i - PT_BOTTOM_RANGE;
			unsigned bottom = (unsigned)test_case->bottom * PT_RANGE_BYTES;
			expected_translation = (byte)(bottom +
					(bottom < 128U ? offset : 15U - offset));
		}
		if (result->identity[i] != expected_identity ||
				result->translation[i] != expected_translation)
			failure |= 0x4d530050U;
	}
	return failure;
}

static unsigned Bench486MenuSetupDifference (
		const bench486_menu_setup_result_t *reference,
		const bench486_menu_setup_result_t *candidate)
{
	unsigned failure = Bench486MenuPictureDifference (
			&reference->picture, &candidate->picture);
	failure |= Bench486MenuTextDifference (
			&reference->text, &candidate->text);
	if (Q_memcmp ((void *)reference->identity, (void *)candidate->identity,
			sizeof(reference->identity)) ||
			Q_memcmp ((void *)reference->translation,
				(void *)candidate->translation,
			sizeof(reference->translation)))
		failure |= 0x4d530060U;
	return failure;
}

void Bench486MenuSetupCases (void)
{
	unsigned cursor, width_index, precision_index, rounding;
	unsigned cases = 0;
	unsigned failure = 0;
	unsigned short original_cw = Bench486MenuTextGetControlWord ();
	unsigned saved_width = vid.width;
	unsigned plaque_index = Bench486MenuSetupFindPathIndex ("gfx/qplaque.lmp");
	unsigned title_index = Bench486MenuSetupFindPathIndex ("gfx/p_multi.lmp");
	unsigned saved_title_width = 0;
	int saved_cursor = setup_cursor;
	int saved_top = setup_top;
	int saved_bottom = setup_bottom;
	char saved_hostname[16];
	char saved_myname[16];
	double saved_time = realtime;
	int saved_text_active = bench486_menu_text_trace_active;
	int saved_dispatch_active = bench486_menu_dispatch_fixture_active;
	bench486_menu_text_trace_t saved_text_trace;
	bench486_menu_picture_trace_t saved_picture_trace;
	unsigned saved_text_width, saved_picture_width;

	Q_memcpy (saved_hostname, setup_hostname, sizeof(saved_hostname));
	Q_memcpy (saved_myname, setup_myname, sizeof(saved_myname));
	Q_memcpy (bench486_menu_setup_saved_identity, identityTable,
			sizeof(bench486_menu_setup_saved_identity));
	Q_memcpy (bench486_menu_setup_saved_translation, translationTable,
			sizeof(bench486_menu_setup_saved_translation));
	Q_memcpy (&saved_text_trace, &bench486_menu_text_trace,
			sizeof(saved_text_trace));
	Q_memcpy (&saved_picture_trace, &bench486_menu_picture_trace,
			sizeof(saved_picture_trace));
	saved_text_width = bench486_menu_picture_fake_pic[title_index * 4U];
	saved_picture_width = bench486_menu_picture_fake_pic[plaque_index * 4U];
	if (plaque_index >= sizeof(bench486_menu_cache_paths) /
			sizeof(bench486_menu_cache_paths[0]) ||
			title_index >= sizeof(bench486_menu_cache_paths) /
			sizeof(bench486_menu_cache_paths[0]))
		failure = 0x4d530070U;

	for (cursor = 0; cursor < 5U && !failure; cursor++)
	for (width_index = 0; width_index < 4U && !failure; width_index++)
	for (precision_index = 0; precision_index < 3U && !failure;
			precision_index++)
	for (rounding = 0; rounding < 4U && !failure; rounding++)
	{
		bench486_menu_setup_case_t test_case;
		unsigned case_failure, reference_expected, candidate_expected;
		unsigned parity_failure;
		unsigned color_index = (cursor + width_index + rounding) % 6U;
		unsigned bottom_index = (cursor * 2U + width_index +
				precision_index + rounding) % 6U;
		unsigned name_index = (cases + cursor + width_index) % 4U;
		unsigned myname_index = (cases + cursor + width_index + 1U) % 4U;
		unsigned title_width = bench486_menu_setup_title_widths[
				(cursor + width_index + rounding) % 3U];
		unsigned short control_word = Bench486MenuSetupControlWord (
				original_cw, bench486_menu_setup_precisions[precision_index],
				bench486_menu_setup_roundings[rounding]);

		test_case.width = bench486_menu_setup_widths[width_index];
		test_case.cursor = (int)cursor;
		test_case.top = bench486_menu_setup_colors[color_index];
		test_case.bottom = bench486_menu_setup_colors[bottom_index];
		test_case.hostname = bench486_menu_setup_names[name_index];
		test_case.myname = bench486_menu_setup_names[myname_index];
		test_case.time = bench486_menu_setup_times[
				(cases + precision_index + rounding) % 8U];
		test_case.title_width = title_width;
		test_case.control_word = control_word;
		bench486_menu_picture_fake_pic[title_index * 4U] = title_width;
		case_failure = Bench486MenuSetupRun (&test_case, M_Setup_Draw_C,
				&bench486_menu_setup_reference);
		case_failure |= Bench486MenuSetupRun (&test_case, M_Setup_Draw,
				&bench486_menu_setup_candidate);
		reference_expected = Bench486MenuSetupExpected (&test_case,
				plaque_index, title_index,
				&bench486_menu_setup_reference);
		candidate_expected = Bench486MenuSetupExpected (&test_case,
				plaque_index, title_index,
				&bench486_menu_setup_candidate);
		parity_failure = Bench486MenuSetupDifference (
				&bench486_menu_setup_reference,
				&bench486_menu_setup_candidate);
		case_failure |= reference_expected | candidate_expected |
				parity_failure;
		cases++;
		if (case_failure)
		{
			Bench486Printf (
				"menu setup C/assembly FAIL cursor %u width %u top %d bottom %d precision %u rounding %u code %08x expected %08x/%08x parity %08x glyphs %u/%u pictures %u/%u\n",
					cursor, width_index, test_case.top, test_case.bottom,
					bench486_menu_setup_precisions[precision_index], rounding,
				case_failure, reference_expected, candidate_expected,
				parity_failure,
					bench486_menu_setup_reference.text.trace.count,
					bench486_menu_setup_candidate.text.trace.count,
					bench486_menu_setup_reference.picture.trace.count,
					bench486_menu_setup_candidate.picture.trace.count);
			failure = case_failure;
		}
	}
	vid.width = saved_width;
	setup_cursor = saved_cursor;
	setup_top = saved_top;
	setup_bottom = saved_bottom;
	Q_memcpy (setup_hostname, saved_hostname, sizeof(saved_hostname));
	Q_memcpy (setup_myname, saved_myname, sizeof(saved_myname));
	realtime = saved_time;
	bench486_menu_text_trace_active = saved_text_active;
	bench486_menu_dispatch_fixture_active = saved_dispatch_active;
	bench486_menu_picture_fake_pic[title_index * 4U] = saved_text_width;
	bench486_menu_picture_fake_pic[plaque_index * 4U] = saved_picture_width;
	Q_memcpy (identityTable, bench486_menu_setup_saved_identity,
			sizeof(bench486_menu_setup_saved_identity));
	Q_memcpy (translationTable, bench486_menu_setup_saved_translation,
			sizeof(bench486_menu_setup_saved_translation));
	Q_memcpy (&bench486_menu_text_trace, &saved_text_trace,
			sizeof(saved_text_trace));
	Q_memcpy (&bench486_menu_picture_trace, &saved_picture_trace,
			sizeof(saved_picture_trace));
	__asm__ __volatile__ ("fldcw %0" : : "m" (original_cw));
	if (failure)
		bench486_memory_failures++;
	else
		Bench486Printf (
				"menu setup: %u exact C/assembly picture, text, translation, and x87 cases PASS\n",
				cases);
}

#undef BMSETUP_EVENT_TRANSPIC
#undef BMSETUP_EVENT_PIC
#undef BMSETUP_EVENT_CACHEPIC
#undef BMSETUP_PICTURE_GUARD_WORDS
#undef BMSETUP_TEXT_GUARD_WORDS

#endif
#endif
