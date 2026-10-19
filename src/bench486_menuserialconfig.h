#ifndef BENCH486_MENUSERIALCONFIG_H
#define BENCH486_MENUSERIALCONFIG_H

#if defined(BENCH486) && defined(ASM486_SCREEN_OVERLAYS)

#include "asm_menutext.h"

#define BMSC_PATH_QLAQUE 10U
#define BMSC_PATH_MULTI_TITLE 29U
#define BMSC_PICTURE_PREFIX_EVENTS 4U
#define BMSC_MAX_GLYPHS 512U
#define BMSC_TEXT_GUARD_WORDS 2U
#define BMSC_PICTURE_GUARD_WORDS 2U
#define BMSC_EVENT_TRANSPIC 1
#define BMSC_EVENT_PIC 2
#define BMSC_EVENT_CACHEPIC 4

extern unsigned Bench486Call_asm486 (void (*function)(void), unsigned words,
		const unsigned *arguments, float *float_return);
extern int serialConfig_cursor;
extern int serialConfig_cursor_table[6];
extern int serialConfig_comport;
extern int serialConfig_irq;
extern int serialConfig_baud;
extern int serialConfig_baudrate[6];
extern char serialConfig_phone[16];
extern char m_return_reason[32];
extern int m_multiplayer_cursor;
extern int m_net_cursor;
extern double realtime;

typedef struct bench486_menu_serialconfig_case_s
{
	unsigned video_width;
	unsigned title_width;
	unsigned phase;
	int cursor;
	int starting_game;
	int serial;
	unsigned pattern;
	unsigned short control_word;
} bench486_menu_serialconfig_case_t;

typedef struct bench486_menu_serialconfig_state_s
{
	int cursor;
	int cursor_table[6];
	int comport;
	int irq;
	int baud;
	int multiplayer_cursor;
	int net_cursor;
	unsigned video_width;
	unsigned title_width;
	double realtime;
	char phone[16];
	char return_reason[32];
} bench486_menu_serialconfig_state_t;

static bench486_menu_text_result_t bench486_menu_serialconfig_text_reference;
static bench486_menu_text_result_t bench486_menu_serialconfig_text_candidate;
static bench486_menu_picture_result_t bench486_menu_serialconfig_picture_reference;
static bench486_menu_picture_result_t bench486_menu_serialconfig_picture_candidate;
static bench486_menu_picture_result_t bench486_menu_serialconfig_picture_slice;

static void Bench486MenuSerialConfigAppendString (
		bench486_menu_text_trace_t *expected, unsigned video_width,
		int x, int y, const char *string, int white)
{
	unsigned offset = (video_width - 320U) >> 1;
	int actual_x = (int)((unsigned)x + offset);

	while (*string)
	{
		bench486_menu_text_glyph_t *glyph;
		if (expected->count >= BMSC_MAX_GLYPHS)
			return;
		glyph = &expected->glyphs[expected->count++];
		glyph->x = actual_x;
		glyph->y = y;
		glyph->num = white ? (int)(signed char)*string :
				(int)(unsigned char)*string + 128;
		actual_x += 8;
		string++;
	}
}

static void Bench486MenuSerialConfigAppendCharacter (
		bench486_menu_text_trace_t *expected, unsigned video_width,
		int x, int y, int num)
{
	unsigned offset = (video_width - 320U) >> 1;
	bench486_menu_text_glyph_t *glyph;

	if (expected->count >= BMSC_MAX_GLYPHS)
		return;
	glyph = &expected->glyphs[expected->count++];
	glyph->x = (int)((unsigned)x + offset);
	glyph->y = y;
	glyph->num = num;
}

static void Bench486MenuSerialConfigCaptureState (
		bench486_menu_serialconfig_state_t *state)
{
	Q_memset (state, 0, sizeof(*state));
	state->cursor = serialConfig_cursor;
	Q_memcpy (state->cursor_table, serialConfig_cursor_table,
			sizeof(state->cursor_table));
	state->comport = serialConfig_comport;
	state->irq = serialConfig_irq;
	state->baud = serialConfig_baud;
	state->multiplayer_cursor = m_multiplayer_cursor;
	state->net_cursor = m_net_cursor;
	state->video_width = vid.width;
	state->title_width = bench486_menu_picture_fake_pic[
			BMSC_PATH_MULTI_TITLE * 4U];
	state->realtime = realtime;
	Q_memcpy (state->phone, serialConfig_phone, sizeof(state->phone));
	Q_memcpy (state->return_reason, m_return_reason,
			sizeof(state->return_reason));
}

static int Bench486MenuSerialConfigStateMatches (
		const bench486_menu_serialconfig_state_t *expected)
{
	bench486_menu_serialconfig_state_t actual;

	Bench486MenuSerialConfigCaptureState (&actual);
	return actual.cursor == expected->cursor &&
			Q_memcmp (actual.cursor_table, (void *)expected->cursor_table,
					sizeof(actual.cursor_table)) == 0 &&
			actual.comport == expected->comport &&
			actual.irq == expected->irq && actual.baud == expected->baud &&
			actual.multiplayer_cursor == expected->multiplayer_cursor &&
			actual.net_cursor == expected->net_cursor &&
			actual.video_width == expected->video_width &&
			actual.title_width == expected->title_width &&
			actual.realtime == expected->realtime &&
			Q_memcmp (actual.phone, (void *)expected->phone,
					sizeof(actual.phone)) == 0 &&
			Q_memcmp (actual.return_reason, (void *)expected->return_reason,
					sizeof(actual.return_reason)) == 0;
}

static unsigned Bench486MenuSerialConfigExpectedText (
		const bench486_menu_serialconfig_case_t *test_case,
		const bench486_menu_text_result_t *result)
{
	bench486_menu_text_trace_t expected;
	const char *start_join = test_case->starting_game ? "New Game" : "Join Game";
	const char *protocol = test_case->serial ? "Modem" : "Direct Connect";
	char title[64];
	char comport[16];
	char irq[16];
	char baud[16];
	unsigned i;
	int base_x = (320 - (int)test_case->title_width) / 2;
	int joining = !test_case->starting_game;
	int rows[6];

	Q_memset (&expected, 0, sizeof(expected));
	for (i = 0; i < BMSC_TEXT_GUARD_WORDS; i++)
	{
		expected.before[i] = 0x4d540000U + i;
		expected.after[i] = 0x4d54f000U + i;
	}
	for (i = 0; i < 6U; i++)
		rows[i] = serialConfig_cursor_table[i];
	sprintf (title, "%s - %s", start_join, protocol);
	sprintf (comport, "COM%u", (unsigned)serialConfig_comport);
	sprintf (irq, "%u", (unsigned)serialConfig_irq);
	sprintf (baud, "%u", (unsigned)serialConfig_baudrate[
			serialConfig_baud]);

	Bench486MenuSerialConfigAppendString (&expected,
			test_case->video_width, base_x, 32, title, 0);
	base_x += 8;
	Bench486MenuSerialConfigAppendString (&expected,
			test_case->video_width, base_x, rows[0], "Port", 0);
	Bench486MenuSerialConfigAppendString (&expected,
			test_case->video_width, 168, rows[0], comport, 0);
	Bench486MenuSerialConfigAppendString (&expected,
			test_case->video_width, base_x, rows[1], "IRQ", 0);
	Bench486MenuSerialConfigAppendString (&expected,
			test_case->video_width, 168, rows[1], irq, 0);
	Bench486MenuSerialConfigAppendString (&expected,
			test_case->video_width, base_x, rows[2], "Baud", 0);
	Bench486MenuSerialConfigAppendString (&expected,
			test_case->video_width, 168, rows[2], baud, 0);
	if (test_case->serial)
	{
		Bench486MenuSerialConfigAppendString (&expected,
				test_case->video_width, base_x, rows[3],
				"Modem Setup...", 0);
		if (joining)
		{
			Bench486MenuSerialConfigAppendString (&expected,
					test_case->video_width, base_x, rows[4],
					"Phone number", 0);
			Bench486MenuSerialConfigAppendString (&expected,
					test_case->video_width, 168, rows[4],
					serialConfig_phone, 0);
		}
	}
	if (joining)
		Bench486MenuSerialConfigAppendString (&expected,
				test_case->video_width, base_x + 8, rows[5], "Connect", 0);
	else
		Bench486MenuSerialConfigAppendString (&expected,
				test_case->video_width, base_x + 8, rows[5], "OK", 0);

	Bench486MenuSerialConfigAppendCharacter (&expected,
			test_case->video_width, base_x - 8,
			rows[test_case->cursor], 12 + (int)test_case->phase);
	if (test_case->cursor == 4)
		Bench486MenuSerialConfigAppendCharacter (&expected,
				test_case->video_width,
				168 + 8 * (int)strlen(serialConfig_phone), rows[4],
				10 + (int)test_case->phase);
	if (m_return_reason[0])
		Bench486MenuSerialConfigAppendString (&expected,
				test_case->video_width, base_x, 148, m_return_reason, 1);

	if (result->trace.overflow || result->trace.count != expected.count)
		return 0x4d530001U;
	for (i = 0; i < BMSC_TEXT_GUARD_WORDS; i++)
		if (result->trace.before[i] != expected.before[i] ||
				result->trace.after[i] != expected.after[i])
			return 0x4d530010U + i;
	for (i = 0; i < expected.count; i++)
		if (result->trace.glyphs[i].x != expected.glyphs[i].x ||
				result->trace.glyphs[i].y != expected.glyphs[i].y ||
				result->trace.glyphs[i].num != expected.glyphs[i].num)
			return 0x4d530100U + i;
	return 0;
}

static unsigned Bench486MenuSerialConfigTextBoxEvents (unsigned width)
{
	unsigned middle = (width + 1U) / 2U;
	unsigned draws = (middle + 2U) * 3U;
	unsigned caches = 6U + middle * 3U;

	return draws + caches;
}

static unsigned Bench486MenuSerialConfigCheckTextBox (
		const bench486_menu_serialconfig_case_t *test_case,
		const bench486_menu_picture_result_t *result, unsigned start,
		unsigned count, int x, int y, int width)
{
	bench486_menu_textbox_case_t textbox;
	unsigned i;

	if (start + count > result->trace.count ||
			count > sizeof(bench486_menu_serialconfig_picture_slice.trace.events) /
					sizeof(result->trace.events[0]))
		return 0x4d530200U;
	Q_memset (&bench486_menu_serialconfig_picture_slice, 0,
			sizeof(bench486_menu_serialconfig_picture_slice));
	bench486_menu_serialconfig_picture_slice.trace.count = count;
	bench486_menu_serialconfig_picture_slice.trace.overflow =
			result->trace.overflow;
	bench486_menu_serialconfig_picture_slice.trace.cache_error =
			result->trace.cache_error;
	for (i = 0; i < BMSC_PICTURE_GUARD_WORDS; i++)
	{
		bench486_menu_serialconfig_picture_slice.trace.before[i] =
				result->trace.before[i];
		bench486_menu_serialconfig_picture_slice.trace.after[i] =
				result->trace.after[i];
	}
	Q_memcpy (bench486_menu_serialconfig_picture_slice.trace.events,
			(void *)(result->trace.events + start),
			count * sizeof(result->trace.events[0]));
	textbox.name = "serial-config-textbox";
	textbox.video_width = test_case->video_width;
	textbox.x = x;
	textbox.y = y;
	textbox.width = width;
	textbox.lines = 1;
	return Bench486MenuTextBoxExpected (&textbox,
			&bench486_menu_serialconfig_picture_slice);
}

static unsigned Bench486MenuSerialConfigExpectedPicture (
		const bench486_menu_serialconfig_case_t *test_case,
		const bench486_menu_picture_result_t *result)
{
	unsigned offset = (test_case->video_width - 320U) >> 1;
	unsigned count = BMSC_PICTURE_PREFIX_EVENTS;
	unsigned start = BMSC_PICTURE_PREFIX_EVENTS;
	unsigned box_count;
	unsigned final_width = test_case->starting_game ? 2U : 7U;
	int base_x = (320 - (int)test_case->title_width) / 2;
	int joining = !test_case->starting_game;
	const qpic_t *plaque = (const qpic_t *)(bench486_menu_picture_fake_pic +
			BMSC_PATH_QLAQUE * 4U);
	const qpic_t *title = (const qpic_t *)(bench486_menu_picture_fake_pic +
			BMSC_PATH_MULTI_TITLE * 4U);
	const bench486_menu_picture_event_t *event;
	unsigned failure = 0;

	count += Bench486MenuSerialConfigTextBoxEvents (4U);
	count += Bench486MenuSerialConfigTextBoxEvents (1U);
	count += Bench486MenuSerialConfigTextBoxEvents (5U);
	if (test_case->serial && joining)
		count += Bench486MenuSerialConfigTextBoxEvents (16U);
	count += Bench486MenuSerialConfigTextBoxEvents (final_width);
	if (result->trace.overflow || result->trace.cache_error ||
			result->trace.count != count)
		return 0x4d530201U;

	event = &result->trace.events[0];
	if (event->kind != BMSC_EVENT_CACHEPIC || event->pic != plaque)
		failure |= 0x4d530210U;
	event = &result->trace.events[1];
	if (event->kind != BMSC_EVENT_TRANSPIC ||
			event->x != (int)(16U + offset) || event->y != 4 ||
			event->pic != plaque || event->translation)
		failure |= 0x4d530211U;
	event = &result->trace.events[2];
	if (event->kind != BMSC_EVENT_CACHEPIC || event->pic != title)
		failure |= 0x4d530212U;
	event = &result->trace.events[3];
	if (event->kind != BMSC_EVENT_PIC ||
			event->x != (int)((unsigned)base_x + offset) || event->y != 4 ||
			event->pic != title || event->translation)
		failure |= 0x4d530213U;

	box_count = Bench486MenuSerialConfigTextBoxEvents (4U);
	failure |= Bench486MenuSerialConfigCheckTextBox (test_case, result,
			start, box_count, 160, 40, 4);
	start += box_count;
	box_count = Bench486MenuSerialConfigTextBoxEvents (1U);
	failure |= Bench486MenuSerialConfigCheckTextBox (test_case, result,
			start, box_count, 160,
			serialConfig_cursor_table[1] - 8, 1);
	start += box_count;
	box_count = Bench486MenuSerialConfigTextBoxEvents (5U);
	failure |= Bench486MenuSerialConfigCheckTextBox (test_case, result,
			start, box_count, 160,
			serialConfig_cursor_table[2] - 8, 5);
	start += box_count;
	if (test_case->serial && joining)
	{
		box_count = Bench486MenuSerialConfigTextBoxEvents (16U);
		failure |= Bench486MenuSerialConfigCheckTextBox (test_case, result,
				start, box_count, 160,
				serialConfig_cursor_table[4] - 8, 16);
		start += box_count;
	}
	box_count = Bench486MenuSerialConfigTextBoxEvents (final_width);
	failure |= Bench486MenuSerialConfigCheckTextBox (test_case, result,
			start, box_count, base_x + 8,
			serialConfig_cursor_table[5] - 8, (int)final_width);
	return failure;
}

static void Bench486MenuSerialConfigPrepare (
		const bench486_menu_serialconfig_case_t *test_case)
{
	static const unsigned phone_lengths[3] = { 0U, 1U, 15U };
	static const unsigned reason_lengths[3] = { 0U, 1U, 31U };
	static const int comport_values[3] = { 1, 2, 4 };
	static const int irq_values[3] = { 3, 4, 7 };
	static const int baud_indices[3] = { 0, 2, 5 };
	static const int row_offsets[3] = { 0, 2, -4 };
	static const int base_rows[6] = { 48, 64, 80, 96, 112, 132 };
	unsigned i;
	unsigned pattern = test_case->pattern % 3U;

	vid.width = test_case->video_width;
	bench486_menu_picture_fake_pic[BMSC_PATH_MULTI_TITLE * 4U] =
			test_case->title_width;
	m_multiplayer_cursor = test_case->starting_game ? 1 : 0;
	m_net_cursor = test_case->serial ? 0 : 1;
	serialConfig_cursor = test_case->cursor;
	for (i = 0; i < 6U; i++)
		serialConfig_cursor_table[i] = base_rows[i] + row_offsets[pattern];
	serialConfig_comport = comport_values[pattern];
	serialConfig_irq = irq_values[pattern];
	serialConfig_baud = baud_indices[pattern];
	Q_memset (serialConfig_phone, 0, sizeof(serialConfig_phone));
	Q_memset (m_return_reason, 0, sizeof(m_return_reason));
	for (i = 0; i < phone_lengths[pattern]; i++)
		serialConfig_phone[i] = (char)('0' + i % 10U);
	for (i = 0; i < reason_lengths[pattern]; i++)
		m_return_reason[i] = (char)('e' + i % 8U);
	realtime = test_case->phase ? 0.375 : 0.125;
	__asm__ __volatile__ ("fldcw %0" : : "m" (test_case->control_word));
}

static unsigned Bench486MenuSerialConfigRun (
		const bench486_menu_serialconfig_case_t *test_case,
		void (*function)(void), bench486_menu_text_result_t *text_result,
		bench486_menu_picture_result_t *picture_result)
{
	bench486_menu_serialconfig_state_t before, after;
	unsigned abi;
	unsigned short cw_before, cw_after;

	Bench486MenuSerialConfigPrepare (test_case);
	Bench486MenuTextInitTrace ();
	Bench486MenuPictureInitTrace ();
	Bench486MenuSerialConfigCaptureState (&before);
	cw_before = Bench486MenuTextGetControlWord ();
	bench486_menu_text_trace_active = 1;
	abi = Bench486Call_asm486 (function, 0U, NULL, NULL);
	bench486_menu_text_trace_active = 0;
	cw_after = Bench486MenuTextGetControlWord ();
	Bench486MenuTextCapture (text_result, abi, cw_before, cw_after);
	Bench486MenuPictureCapture (picture_result, abi, cw_before, cw_after);
	if ((abi & 0x20U) || cw_before != cw_after)
		return 0x4d530301U;
	Bench486MenuSerialConfigCaptureState (&after);
	if (!Bench486MenuSerialConfigStateMatches (&before) ||
			!Bench486MenuSerialConfigStateMatches (&after))
		return 0x4d530302U;
	return 0;
}

void Bench486MenuSerialConfigCases (void)
{
	static const unsigned widths[4] = { 319U, 320U, 640U, 1024U };
	static const unsigned title_widths[4] = { 0U, 91U, 320U, 321U };
	static const unsigned precisions[3] = { 0U, 2U, 3U };
	bench486_menu_serialconfig_case_t test_case;
	bench486_menu_text_trace_t saved_text_trace;
	bench486_menu_picture_trace_t saved_picture_trace;
	bench486_menu_serialconfig_state_t saved_state;
	unsigned saved_title_width = bench486_menu_picture_fake_pic[
			BMSC_PATH_MULTI_TITLE * 4U];
	unsigned short saved_control_word = Bench486MenuTextGetControlWord ();
	int saved_trace_active = bench486_menu_text_trace_active;
	unsigned width_index, cursor, starting_game, serial, pattern;
	unsigned rounding, precision_index, total = 0, failure = 0;

	Bench486MenuSerialConfigCaptureState (&saved_state);
	Q_memcpy (&saved_text_trace, &bench486_menu_text_trace,
			sizeof(saved_text_trace));
	Q_memcpy (&saved_picture_trace, &bench486_menu_picture_trace,
			sizeof(saved_picture_trace));

	for (width_index = 0; width_index < 4U && !failure; width_index++)
	for (cursor = 0; cursor < 6U && !failure; cursor++)
	for (starting_game = 0; starting_game < 2U && !failure; starting_game++)
	for (serial = 0; serial < 2U && !failure; serial++)
	for (pattern = 0; pattern < 3U && !failure; pattern++)
	for (rounding = 0; rounding < 4U && !failure; rounding++)
	for (precision_index = 0; precision_index < 3U && !failure;
			precision_index++)
	{
		unsigned text_c, text_asm, picture_c, picture_asm;
		unsigned text_diff, picture_diff;
		unsigned scenario = width_index + cursor + starting_game + serial +
				pattern;

		test_case.video_width = widths[width_index];
		test_case.title_width = title_widths[scenario & 3U];
		test_case.phase = (scenario + rounding + precision_index) & 1U;
		test_case.cursor = (int)cursor;
		test_case.starting_game = (int)starting_game;
		test_case.serial = (int)serial;
		test_case.pattern = pattern;
		test_case.control_word = Bench486MenuPageControlWord (
				saved_control_word, precisions[precision_index], rounding);
		total++;
		failure = Bench486MenuSerialConfigRun (&test_case,
				M_SerialConfig_Draw_C,
				&bench486_menu_serialconfig_text_reference,
				&bench486_menu_serialconfig_picture_reference);
		failure |= Bench486MenuSerialConfigRun (&test_case,
				M_SerialConfig_Draw,
				&bench486_menu_serialconfig_text_candidate,
				&bench486_menu_serialconfig_picture_candidate);
		text_c = Bench486MenuSerialConfigExpectedText (&test_case,
				&bench486_menu_serialconfig_text_reference);
		text_asm = Bench486MenuSerialConfigExpectedText (&test_case,
				&bench486_menu_serialconfig_text_candidate);
		picture_c = Bench486MenuSerialConfigExpectedPicture (&test_case,
				&bench486_menu_serialconfig_picture_reference);
		picture_asm = Bench486MenuSerialConfigExpectedPicture (&test_case,
				&bench486_menu_serialconfig_picture_candidate);
		text_diff = Bench486MenuTextDifference (
				&bench486_menu_serialconfig_text_reference,
				&bench486_menu_serialconfig_text_candidate);
		picture_diff = Bench486MenuPictureDifference (
				&bench486_menu_serialconfig_picture_reference,
				&bench486_menu_serialconfig_picture_candidate);
		failure |= text_c | text_asm | picture_c | picture_asm |
				text_diff | picture_diff;
		if (failure)
			Bench486Printf ("serial-config draw FAIL width %u cursor %u start %u serial %u pattern %u rounding %u precision %u code %08x checks %08x/%08x/%08x/%08x/%08x/%08x counts %u/%u %u/%u\n",
					width_index, cursor, starting_game, serial, pattern,
					rounding, precision_index, failure, text_c, text_asm,
					picture_c, picture_asm, text_diff, picture_diff,
					bench486_menu_serialconfig_text_reference.trace.count,
					bench486_menu_serialconfig_text_candidate.trace.count,
					bench486_menu_serialconfig_picture_reference.trace.count,
					bench486_menu_serialconfig_picture_candidate.trace.count);
	}

	bench486_menu_text_trace_active = 0;
	serialConfig_cursor = saved_state.cursor;
	Q_memcpy (serialConfig_cursor_table, saved_state.cursor_table,
			sizeof(saved_state.cursor_table));
	serialConfig_comport = saved_state.comport;
	serialConfig_irq = saved_state.irq;
	serialConfig_baud = saved_state.baud;
	m_multiplayer_cursor = saved_state.multiplayer_cursor;
	m_net_cursor = saved_state.net_cursor;
	vid.width = saved_state.video_width;
	realtime = saved_state.realtime;
	Q_memcpy (serialConfig_phone, saved_state.phone,
			sizeof(saved_state.phone));
	Q_memcpy (m_return_reason, saved_state.return_reason,
			sizeof(saved_state.return_reason));
	bench486_menu_picture_fake_pic[BMSC_PATH_MULTI_TITLE * 4U] =
			saved_title_width;
	bench486_menu_text_trace_active = saved_trace_active;
	Q_memcpy (&bench486_menu_text_trace, &saved_text_trace,
			sizeof(saved_text_trace));
	Q_memcpy (&bench486_menu_picture_trace, &saved_picture_trace,
			sizeof(saved_picture_trace));
	__asm__ __volatile__ ("fldcw %0" : : "m" (saved_control_word));
	if (failure)
		bench486_memory_failures++;
	else
		Bench486Printf ("serial config menu drawing: %u exact C/assembly text, picture, state, x87 and ABI cases PASS\n",
				total);
}

#endif

#endif
