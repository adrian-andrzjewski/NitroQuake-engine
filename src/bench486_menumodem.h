#ifndef BENCH486_MENUMODEM_H
#define BENCH486_MENUMODEM_H

#if defined(BENCH486) && defined(ASM486_SCREEN_OVERLAYS)

#include "asm_menutext.h"

#define BMM_MULTI_TITLE_PATH 29U
#define BMM_EXPECTED_PICTURES 244U
#define BMM_MAX_GLYPHS 512U
#define BMM_TEXT_GUARD_WORDS 2U
#define BMM_PICTURE_GUARD_WORDS 2U
#define BMM_EVENT_PIC 2
#define BMM_EVENT_TRANSPIC 1
#define BMM_EVENT_CACHEPIC 4

typedef struct bench486_menu_modem_case_s
{
	const char *name;
	unsigned video_width;
	int cursor;
	int dialing;
	unsigned clear_length;
	unsigned init_length;
	unsigned hangup_length;
	unsigned phase;
	unsigned short control_word;
} bench486_menu_modem_case_t;

static bench486_menu_text_result_t bench486_menu_modem_text_reference;
static bench486_menu_text_result_t bench486_menu_modem_text_candidate;
static bench486_menu_picture_result_t bench486_menu_modem_picture_reference;
static bench486_menu_picture_result_t bench486_menu_modem_picture_candidate;

static void Bench486MenuModemAppendString (
		bench486_menu_text_trace_t *expected, unsigned video_width,
		int x, int y, const char *string)
{
	unsigned offset = (video_width - 320U) >> 1;
	int actual_x = (int)((unsigned)x + offset);
	while (*string)
	{
		bench486_menu_text_glyph_t *glyph;
		if (expected->count >= BMM_MAX_GLYPHS)
			return;
		glyph = &expected->glyphs[expected->count++];
		glyph->x = actual_x;
		glyph->y = y;
		glyph->num = (unsigned char)*string + 128;
		actual_x += 8;
		string++;
	}
}

static void Bench486MenuModemAppendCharacter (
		bench486_menu_text_trace_t *expected, unsigned video_width,
		int x, int y, int num)
{
	unsigned offset = (video_width - 320U) >> 1;
	bench486_menu_text_glyph_t *glyph;
	if (expected->count >= BMM_MAX_GLYPHS)
		return;
	glyph = &expected->glyphs[expected->count++];
	glyph->x = (int)((unsigned)x + offset);
	glyph->y = y;
	glyph->num = num;
}

static unsigned Bench486MenuModemExpectedText (
		const bench486_menu_modem_case_t *test_case,
		const bench486_menu_text_result_t *result)
{
	bench486_menu_text_trace_t expected;
	const char *dialing_text = test_case->dialing == 'P' ?
			"Pulse Dialing" : "Touch Tone Dialing";
	unsigned i;
	int base_x = (320 - (int)bench486_menu_picture_fake_pic[
			BMM_MULTI_TITLE_PATH * 4U]) / 2;
	int rows[5];
	unsigned lengths[3];
	char clear_text[16];
	char init_text[32];
	char hangup_text[16];

	Q_memset (&expected, 0, sizeof(expected));
	for (i = 0; i < BMM_TEXT_GUARD_WORDS; i++)
	{
		expected.before[i] = 0x4d540000U + i;
		expected.after[i] = 0x4d54f000U + i;
	}
	rows[0] = 40;
	rows[1] = 56;
	rows[2] = 88;
	rows[3] = 120;
	rows[4] = 156;
	lengths[0] = test_case->clear_length;
	lengths[1] = test_case->init_length;
	lengths[2] = test_case->hangup_length;
	for (i = 0; i < lengths[0]; i++)
		clear_text[i] = (char)('a' + i % 26U);
	clear_text[lengths[0]] = 0;
	for (i = 0; i < lengths[1]; i++)
		init_text[i] = (char)('A' + i % 26U);
	init_text[lengths[1]] = 0;
	for (i = 0; i < lengths[2]; i++)
		hangup_text[i] = (char)('0' + i % 10U);
	hangup_text[lengths[2]] = 0;

	Bench486MenuModemAppendString (&expected, test_case->video_width,
			base_x + 8, rows[0], dialing_text);
	Bench486MenuModemAppendString (&expected, test_case->video_width,
			base_x + 8, rows[1], "Clear");
	Bench486MenuModemAppendString (&expected, test_case->video_width,
			base_x + 16, rows[1] + 12, clear_text);
	if (test_case->cursor == 1)
		Bench486MenuModemAppendCharacter (&expected, test_case->video_width,
				base_x + 16 + (int)(lengths[0] * 8U), rows[1] + 12,
				10 + (int)test_case->phase);
	Bench486MenuModemAppendString (&expected, test_case->video_width,
			base_x + 8, rows[2], "Init");
	Bench486MenuModemAppendString (&expected, test_case->video_width,
			base_x + 16, rows[2] + 12, init_text);
	if (test_case->cursor == 2)
		Bench486MenuModemAppendCharacter (&expected, test_case->video_width,
				base_x + 16 + (int)(lengths[1] * 8U), rows[2] + 12,
				10 + (int)test_case->phase);
	Bench486MenuModemAppendString (&expected, test_case->video_width,
			base_x + 8, rows[3], "Hangup");
	Bench486MenuModemAppendString (&expected, test_case->video_width,
			base_x + 16, rows[3] + 12, hangup_text);
	if (test_case->cursor == 3)
		Bench486MenuModemAppendCharacter (&expected, test_case->video_width,
				base_x + 16 + (int)(lengths[2] * 8U), rows[3] + 12,
				10 + (int)test_case->phase);
	Bench486MenuModemAppendString (&expected, test_case->video_width,
			base_x + 16, rows[4], "OK");
	Bench486MenuModemAppendCharacter (&expected, test_case->video_width,
			base_x, rows[test_case->cursor],
			12 + (int)test_case->phase);

	if (result->trace.overflow || result->trace.count != expected.count)
		return 0x4d4d0001U;
	for (i = 0; i < BMM_TEXT_GUARD_WORDS; i++)
		if (result->trace.before[i] != expected.before[i] ||
				result->trace.after[i] != expected.after[i])
			return 0x4d4d0010U + i;
	for (i = 0; i < expected.count; i++)
		if (result->trace.glyphs[i].x != expected.glyphs[i].x ||
				result->trace.glyphs[i].y != expected.glyphs[i].y ||
				result->trace.glyphs[i].num != expected.glyphs[i].num)
			return 0x4d4d0100U + i;
	return 0;
}

static unsigned Bench486MenuModemExpectedPicture (
		const bench486_menu_modem_case_t *test_case,
		const bench486_menu_picture_result_t *result)
{
	unsigned i;
	unsigned offset = (test_case->video_width - 320U) >> 1;
	int base_x = (320 - (int)bench486_menu_picture_fake_pic[
			BMM_MULTI_TITLE_PATH * 4U]) / 2;
	const bench486_menu_picture_event_t *event;
	qpic_t *plaque = (qpic_t *)(bench486_menu_picture_fake_pic + 10U * 4U);
	qpic_t *title = (qpic_t *)(bench486_menu_picture_fake_pic +
			BMM_MULTI_TITLE_PATH * 4U);

	if (result->trace.overflow || result->trace.cache_error ||
			result->trace.count != BMM_EXPECTED_PICTURES)
		return 0x4d4d0201U;
	for (i = 0; i < BMM_PICTURE_GUARD_WORDS; i++)
		if (result->trace.before[i] != 0x4d500000U + i ||
				result->trace.after[i] != 0x4d50f000U + i)
			return 0x4d4d0210U + i;
	event = &result->trace.events[0];
	if (event->kind != BMM_EVENT_CACHEPIC || event->pic != plaque)
		return 0x4d4d0220U;
	event = &result->trace.events[1];
	if (event->kind != BMM_EVENT_TRANSPIC ||
			event->x != (int)(16U + offset) || event->y != 4 ||
			event->pic != plaque || event->translation)
		return 0x4d4d0221U;
	event = &result->trace.events[2];
	if (event->kind != BMM_EVENT_CACHEPIC || event->pic != title)
		return 0x4d4d0222U;
	event = &result->trace.events[3];
	if (event->kind != BMM_EVENT_PIC ||
			event->x != (int)((unsigned)base_x + offset) ||
			event->y != 4 || event->pic != title || event->translation)
		return 0x4d4d0223U;
	for (i = 0; i < result->trace.count; i++)
		if (!result->trace.events[i].pic || result->trace.events[i].translation)
			return 0x4d4d0230U + i;
	return 0;
}

static unsigned Bench486MenuModemRun (
		const bench486_menu_modem_case_t *test_case,
		void (*function)(void), bench486_menu_text_result_t *text_result,
		bench486_menu_picture_result_t *picture_result)
{
	unsigned i, abi;
	unsigned short cw_before, cw_after;
	static const int cursor_rows[5] = { 40, 56, 88, 120, 156 };

	vid.width = test_case->video_width;
	modemConfig_cursor = test_case->cursor;
	modemConfig_dialing = (char)test_case->dialing;
	for (i = 0; i < 5; i++)
		modemConfig_cursor_table[i] = cursor_rows[i];
	Q_memset (modemConfig_clear, 0, sizeof(modemConfig_clear));
	Q_memset (modemConfig_init, 0, sizeof(modemConfig_init));
	Q_memset (modemConfig_hangup, 0, sizeof(modemConfig_hangup));
	for (i = 0; i < test_case->clear_length; i++)
		modemConfig_clear[i] = (char)('a' + i % 26U);
	for (i = 0; i < test_case->init_length; i++)
		modemConfig_init[i] = (char)('A' + i % 26U);
	for (i = 0; i < test_case->hangup_length; i++)
		modemConfig_hangup[i] = (char)('0' + i % 10U);
	realtime = test_case->phase ? 0.375 : 0.125;
	__asm__ __volatile__ ("fldcw %0" : : "m" (test_case->control_word));

	Bench486MenuTextInitTrace ();
	Bench486MenuPictureInitTrace ();
	cw_before = Bench486MenuTextGetControlWord ();
	bench486_menu_text_trace_active = 1;
	abi = Bench486Call_asm486 (function, 0, NULL, NULL);
	bench486_menu_text_trace_active = 0;
	cw_after = Bench486MenuTextGetControlWord ();
	Bench486MenuTextCapture (text_result, abi, cw_before, cw_after);
	Bench486MenuPictureCapture (picture_result, abi, cw_before, cw_after);
	if ((abi & 0x20U) || cw_before != cw_after)
		return 0x4d4d0301U;
	return 0;
}

void Bench486MenuModemCases (void)
{
	static const unsigned widths[4] = { 319, 320, 640, 1024 };
	static const unsigned precisions[3] = { 0, 2, 3 };
	static const unsigned clear_lengths[3] = { 0, 1, 15 };
	static const unsigned init_lengths[3] = { 0, 4, 31 };
	static const unsigned hangup_lengths[3] = { 0, 2, 15 };
	bench486_menu_modem_case_t test_case;
	bench486_menu_text_trace_t saved_text_trace;
	bench486_menu_picture_trace_t saved_picture_trace;
	char saved_clear[sizeof(modemConfig_clear)];
	char saved_init[sizeof(modemConfig_init)];
	char saved_hangup[sizeof(modemConfig_hangup)];
	int saved_rows[5];
	unsigned saved_width = vid.width;
	unsigned saved_title_width = bench486_menu_picture_fake_pic[
			BMM_MULTI_TITLE_PATH * 4U];
	int saved_cursor = modemConfig_cursor;
	char saved_dialing = modemConfig_dialing;
	unsigned short saved_control_word = Bench486MenuTextGetControlWord ();
	double saved_realtime = realtime;
	unsigned cursor, mode, pattern, width_index, phase, rounding;
	unsigned precision_index, total = 0, failure = 0;

	Q_memcpy (saved_clear, modemConfig_clear, sizeof(saved_clear));
	Q_memcpy (saved_init, modemConfig_init, sizeof(saved_init));
	Q_memcpy (saved_hangup, modemConfig_hangup, sizeof(saved_hangup));
	Q_memcpy (saved_rows, modemConfig_cursor_table, sizeof(saved_rows));
	Q_memcpy (&saved_text_trace, &bench486_menu_text_trace,
			sizeof(saved_text_trace));
	Q_memcpy (&saved_picture_trace, &bench486_menu_picture_trace,
			sizeof(saved_picture_trace));
	bench486_menu_picture_fake_pic[BMM_MULTI_TITLE_PATH * 4U] = 91;
	test_case.name = "modem-config-menu";

	for (cursor = 0; cursor < 5 && !failure; cursor++)
	for (mode = 0; mode < 2 && !failure; mode++)
	for (pattern = 0; pattern < 3 && !failure; pattern++)
	for (width_index = 0; width_index < 4 && !failure; width_index++)
	for (phase = 0; phase < 2 && !failure; phase++)
	for (rounding = 0; rounding < 4 && !failure; rounding++)
	for (precision_index = 0; precision_index < 3 && !failure;
			precision_index++)
	{
		unsigned text_ref_code, text_asm_code;
		unsigned picture_ref_code, picture_asm_code;
		unsigned text_diff, picture_diff;
		unsigned glyph_index, glyph_limit;
		test_case.video_width = widths[width_index];
		test_case.cursor = (int)cursor;
		test_case.dialing = mode ? 'T' : 'P';
		test_case.clear_length = clear_lengths[pattern];
		test_case.init_length = init_lengths[pattern];
		test_case.hangup_length = hangup_lengths[pattern];
		test_case.phase = phase;
		test_case.control_word = Bench486MenuPageControlWord (
				saved_control_word, precisions[precision_index], rounding);
		total++;
		failure = Bench486MenuModemRun (&test_case, M_ModemConfig_Draw_C,
				&bench486_menu_modem_text_reference,
				&bench486_menu_modem_picture_reference);
		failure |= Bench486MenuModemRun (&test_case, M_ModemConfig_Draw,
				&bench486_menu_modem_text_candidate,
				&bench486_menu_modem_picture_candidate);
		text_ref_code = Bench486MenuModemExpectedText (&test_case,
				&bench486_menu_modem_text_reference);
		text_asm_code = Bench486MenuModemExpectedText (&test_case,
				&bench486_menu_modem_text_candidate);
		picture_ref_code = Bench486MenuModemExpectedPicture (&test_case,
				&bench486_menu_modem_picture_reference);
		picture_asm_code = Bench486MenuModemExpectedPicture (&test_case,
				&bench486_menu_modem_picture_candidate);
		text_diff = Bench486MenuTextDifference (
				&bench486_menu_modem_text_reference,
				&bench486_menu_modem_text_candidate);
		picture_diff = Bench486MenuPictureDifference (
				&bench486_menu_modem_picture_reference,
				&bench486_menu_modem_picture_candidate);
		failure |= text_ref_code | text_asm_code |
				picture_ref_code | picture_asm_code | text_diff | picture_diff;
		if (failure)
		{
			Bench486Printf ("modem-config C/assembly FAIL cursor %u mode %u pattern %u width %u phase %u rounding %u precision %u code %08x checks %08x/%08x/%08x/%08x/%08x/%08x counts %u/%u %u/%u\n",
					cursor, mode, pattern, width_index, phase, rounding,
					precision_index, failure, text_ref_code, text_asm_code,
					picture_ref_code, picture_asm_code, text_diff, picture_diff,
					bench486_menu_modem_text_reference.trace.count,
					bench486_menu_modem_text_candidate.trace.count,
					bench486_menu_modem_picture_reference.trace.count,
					bench486_menu_modem_picture_candidate.trace.count);
			glyph_limit = bench486_menu_modem_text_reference.trace.count;
			if (bench486_menu_modem_text_candidate.trace.count < glyph_limit)
				glyph_limit = bench486_menu_modem_text_candidate.trace.count;
			for (glyph_index = 0; glyph_index < glyph_limit; glyph_index++)
			{
				bench486_menu_text_glyph_t *left =
						&bench486_menu_modem_text_reference.trace.glyphs[glyph_index];
				bench486_menu_text_glyph_t *right =
						&bench486_menu_modem_text_candidate.trace.glyphs[glyph_index];
				if (left->x != right->x || left->y != right->y ||
						left->num != right->num)
				{
					Bench486Printf ("modem first glyph diff %u C(%d,%d,%d) asm(%d,%d,%d)\n",
							glyph_index, left->x, left->y, left->num,
							right->x, right->y, right->num);
					break;
				}
			}
			break;
		}
	}

	bench486_menu_text_trace_active = 0;
	vid.width = saved_width;
	modemConfig_cursor = saved_cursor;
	modemConfig_dialing = saved_dialing;
	Q_memcpy (modemConfig_cursor_table, saved_rows, sizeof(saved_rows));
	Q_memcpy (modemConfig_clear, saved_clear, sizeof(saved_clear));
	Q_memcpy (modemConfig_init, saved_init, sizeof(saved_init));
	Q_memcpy (modemConfig_hangup, saved_hangup, sizeof(saved_hangup));
	Q_memcpy (&bench486_menu_text_trace, &saved_text_trace,
			sizeof(saved_text_trace));
	Q_memcpy (&bench486_menu_picture_trace, &saved_picture_trace,
			sizeof(saved_picture_trace));
	bench486_menu_picture_fake_pic[BMM_MULTI_TITLE_PATH * 4U] = saved_title_width;
	realtime = saved_realtime;
	__asm__ __volatile__ ("fldcw %0" : : "m" (saved_control_word));
	if (failure)
		bench486_memory_failures++;
	else
		Bench486Printf ("modem-config menu drawing: %u exact C/assembly cases PASS\n",
				total);
}

#endif

#endif
