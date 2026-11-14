/* Exact C/assembly parity for the LAN configuration menu renderer. */
#ifndef BENCH486_MENULANCONFIGDRAW_H
#define BENCH486_MENULANCONFIGDRAW_H

#if defined(BENCH486) && defined(ASM486_SCREEN_OVERLAYS)

#include "client/asm_menutext.h"

#define BML_PATH_QLAQUE 10U
#define BML_PATH_MULTI_TITLE 29U
#define BML_PICTURE_PREFIX_EVENTS 4U
#define BML_MAX_GLYPHS 1024U
#define BML_TEXT_GUARD_WORDS 2U
#define BML_PICTURE_GUARD_WORDS 2U
#define BML_EVENT_TRANSPIC 1
#define BML_EVENT_PIC 2
#define BML_EVENT_CACHEPIC 4

extern unsigned Bench486Call_asm486 (void (*function)(void), unsigned words,
		const unsigned *arguments, float *float_return);
extern int lanConfig_cursor;
extern int lanConfig_cursor_table[3];
extern char lanConfig_portname[6];
extern char lanConfig_joinname[22];
extern char m_return_reason[32];
extern char my_ipx_address[64];
extern char my_tcpip_address[64];
extern double realtime;

typedef struct bench486_menu_lanconfig_case_s
{
	unsigned video_width;
	unsigned title_width;
	unsigned pattern;
	unsigned phase;
	int starting_game;
	int ipx;
	int cursor;
	unsigned short control_word;
} bench486_menu_lanconfig_case_t;

static bench486_menu_text_result_t bench486_menu_lanconfig_text_reference;
static bench486_menu_text_result_t bench486_menu_lanconfig_text_candidate;
static bench486_menu_picture_result_t bench486_menu_lanconfig_picture_reference;
static bench486_menu_picture_result_t bench486_menu_lanconfig_picture_candidate;
static bench486_menu_picture_result_t bench486_menu_lanconfig_picture_slice;

static void Bench486MenuLanConfigAppendString (
		bench486_menu_text_trace_t *expected, unsigned video_width,
		int x, int y, const char *string, int white)
{
	unsigned offset = (video_width - 320U) >> 1;
	int actual_x = (int)((unsigned)x + offset);

	while (*string)
	{
		bench486_menu_text_glyph_t *glyph;
		if (expected->count >= BML_MAX_GLYPHS)
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

static void Bench486MenuLanConfigAppendCharacter (
		bench486_menu_text_trace_t *expected, unsigned video_width,
		int x, int y, int num)
{
	unsigned offset = (video_width - 320U) >> 1;
	bench486_menu_text_glyph_t *glyph;

	if (expected->count >= BML_MAX_GLYPHS)
		return;
	glyph = &expected->glyphs[expected->count++];
	glyph->x = (int)((unsigned)x + offset);
	glyph->y = y;
	glyph->num = num;
}

static unsigned Bench486MenuLanConfigTextExpected (
		const bench486_menu_lanconfig_case_t *test_case,
		const bench486_menu_text_result_t *result)
{
	bench486_menu_text_trace_t expected;
	const char *title;
	const char *address;
	int basex = (320 - (int)test_case->title_width) / 2;
	int row0 = 72 + (int)((test_case->pattern & 1U) * 4U);
	int row1 = 92 + (int)((test_case->pattern & 1U) * 4U);
	int row2 = 124 + (int)((test_case->pattern & 1U) * 4U);
	unsigned i;

	Q_memset (&expected, 0, sizeof(expected));
	for (i = 0; i < BML_TEXT_GUARD_WORDS; i++)
	{
		expected.before[i] = 0x4d540000U + i;
		expected.after[i] = 0x4d54f000U + i;
	}
	if (test_case->starting_game)
		title = test_case->ipx ? "New Game - IPX" : "New Game - TCP/IP";
	else
		title = test_case->ipx ? "Join Game - IPX" : "Join Game - TCP/IP";
	address = test_case->ipx ? my_ipx_address : my_tcpip_address;

	Bench486MenuLanConfigAppendString (&expected, test_case->video_width,
			basex, 32, title, 0);
	basex += 8;
	Bench486MenuLanConfigAppendString (&expected, test_case->video_width,
			basex, 52, "Address:", 0);
	Bench486MenuLanConfigAppendString (&expected, test_case->video_width,
			basex + 72, 52, address, 0);
	Bench486MenuLanConfigAppendString (&expected, test_case->video_width,
			basex, row0, "Port", 0);
	Bench486MenuLanConfigAppendString (&expected, test_case->video_width,
			basex + 72, row0, lanConfig_portname, 0);
	if (!test_case->starting_game)
	{
		Bench486MenuLanConfigAppendString (&expected,
				test_case->video_width, basex, row1,
				"Search for local games...", 0);
		Bench486MenuLanConfigAppendString (&expected,
				test_case->video_width, basex, 108,
				"Join game at:", 0);
		Bench486MenuLanConfigAppendString (&expected,
				test_case->video_width, basex + 16, row2,
				lanConfig_joinname, 0);
	}
	else
		Bench486MenuLanConfigAppendString (&expected,
				test_case->video_width, basex + 8, row1, "OK", 0);

	Bench486MenuLanConfigAppendCharacter (&expected, test_case->video_width,
			basex - 8, lanConfig_cursor_table[test_case->cursor],
			12 + (int)test_case->phase);
	if (test_case->cursor == 0)
		Bench486MenuLanConfigAppendCharacter (&expected,
				test_case->video_width,
				basex + 72 + 8 * (int)strlen(lanConfig_portname),
				lanConfig_cursor_table[0], 10 + (int)test_case->phase);
	if (test_case->cursor == 2)
		Bench486MenuLanConfigAppendCharacter (&expected,
				test_case->video_width,
				basex + 16 + 8 * (int)strlen(lanConfig_joinname),
				lanConfig_cursor_table[2], 10 + (int)test_case->phase);
	if (*m_return_reason)
		Bench486MenuLanConfigAppendString (&expected,
				test_case->video_width, basex, 148, m_return_reason, 1);

	if (result->trace.overflow || result->trace.count != expected.count)
		return 0x4d4c0001U;
	for (i = 0; i < BML_TEXT_GUARD_WORDS; i++)
		if (result->trace.before[i] != expected.before[i] ||
				result->trace.after[i] != expected.after[i])
			return 0x4d4c0010U + i;
	for (i = 0; i < expected.count; i++)
		if (result->trace.glyphs[i].x != expected.glyphs[i].x ||
				result->trace.glyphs[i].y != expected.glyphs[i].y ||
				result->trace.glyphs[i].num != expected.glyphs[i].num)
			return 0x4d4c0100U + i;
	return 0;
}

static unsigned Bench486MenuLanConfigTextBoxEvents (unsigned width,
		unsigned lines)
{
	unsigned middle = (width + 1U) / 2U;
	unsigned draws = (middle + 2U) * (lines + 2U);
	unsigned caches = 6U + middle * (3U + (lines > 1U ? 1U : 0U));
	return draws + caches;
}

static unsigned Bench486MenuLanConfigCheckTextBox (
		const bench486_menu_lanconfig_case_t *test_case,
		const bench486_menu_picture_result_t *result, unsigned start,
		unsigned count, int x, int y, int width)
{
	bench486_menu_textbox_case_t textbox;
	unsigned i;

	Q_memset (&bench486_menu_lanconfig_picture_slice, 0,
			sizeof(bench486_menu_lanconfig_picture_slice));
	bench486_menu_lanconfig_picture_slice.trace.count = count;
	bench486_menu_lanconfig_picture_slice.trace.overflow =
			result->trace.overflow;
	bench486_menu_lanconfig_picture_slice.trace.cache_error =
			result->trace.cache_error;
	for (i = 0; i < BML_PICTURE_GUARD_WORDS; i++)
	{
		bench486_menu_lanconfig_picture_slice.trace.before[i] =
				result->trace.before[i];
		bench486_menu_lanconfig_picture_slice.trace.after[i] =
				result->trace.after[i];
	}
	Q_memcpy (bench486_menu_lanconfig_picture_slice.trace.events,
			(void *)(result->trace.events + start),
			count * sizeof(result->trace.events[0]));
	textbox.name = "lan-config-textbox";
	textbox.video_width = test_case->video_width;
	textbox.x = x;
	textbox.y = y;
	textbox.width = width;
	textbox.lines = 1;
	return Bench486MenuTextBoxExpected (&textbox,
			&bench486_menu_lanconfig_picture_slice);
}

static unsigned Bench486MenuLanConfigPictureExpected (
		const bench486_menu_lanconfig_case_t *test_case,
		const bench486_menu_picture_result_t *result)
{
	unsigned offset = (test_case->video_width - 320U) >> 1;
	unsigned box1_count = Bench486MenuLanConfigTextBoxEvents (6U, 1U);
	unsigned second_width = test_case->starting_game ? 2U : 22U;
	unsigned box2_count = Bench486MenuLanConfigTextBoxEvents (second_width, 1U);
	unsigned total = BML_PICTURE_PREFIX_EVENTS + box1_count + box2_count;
	int basex = (320 - (int)test_case->title_width) / 2;
	const qpic_t *plaque = (const qpic_t *)(bench486_menu_picture_fake_pic +
			BML_PATH_QLAQUE * 4U);
	const qpic_t *title = (const qpic_t *)(bench486_menu_picture_fake_pic +
			BML_PATH_MULTI_TITLE * 4U);
	const bench486_menu_picture_event_t *event;
	unsigned failure = 0;

	if (result->trace.overflow || result->trace.cache_error ||
			result->trace.count != total)
		return 0x4d4c0201U;
	event = &result->trace.events[0];
	if (event->kind != BML_EVENT_CACHEPIC || event->pic != plaque)
		failure |= 0x4d4c0210U;
	event = &result->trace.events[1];
	if (event->kind != BML_EVENT_TRANSPIC ||
			event->x != (int)(16U + offset) || event->y != 4 ||
			event->pic != plaque || event->translation)
		failure |= 0x4d4c0211U;
	event = &result->trace.events[2];
	if (event->kind != BML_EVENT_CACHEPIC || event->pic != title)
		failure |= 0x4d4c0212U;
	event = &result->trace.events[3];
	if (event->kind != BML_EVENT_PIC ||
			event->x != (int)((unsigned)basex + offset) || event->y != 4 ||
			event->pic != title || event->translation)
		failure |= 0x4d4c0213U;
	failure |= Bench486MenuLanConfigCheckTextBox (test_case, result,
			BML_PICTURE_PREFIX_EVENTS, box1_count,
			basex + 8 + 64,
			lanConfig_cursor_table[0] - 8, 6);
	if (test_case->starting_game)
		failure |= Bench486MenuLanConfigCheckTextBox (test_case, result,
				BML_PICTURE_PREFIX_EVENTS + box1_count, box2_count,
				basex + 8, lanConfig_cursor_table[1] - 8, 2);
	else
		failure |= Bench486MenuLanConfigCheckTextBox (test_case, result,
				BML_PICTURE_PREFIX_EVENTS + box1_count, box2_count,
				basex + 8 + 8, lanConfig_cursor_table[2] - 8, 22);
	return failure;
}

static void Bench486MenuLanConfigPrepare (
		const bench486_menu_lanconfig_case_t *test_case)
{
	static const unsigned port_lengths[4] = { 0U, 1U, 5U, 3U };
	static const unsigned join_lengths[4] = { 0U, 1U, 21U, 7U };
	static const unsigned address_lengths[4] = { 0U, 1U, 63U, 12U };
	static const unsigned reason_lengths[4] = { 0U, 1U, 31U, 9U };
	unsigned i;
	unsigned pattern = test_case->pattern & 3U;

	vid.width = test_case->video_width;
	bench486_menu_picture_fake_pic[BML_PATH_MULTI_TITLE * 4U] =
			test_case->title_width;
	m_multiplayer_cursor = test_case->starting_game ? 1 : 0;
	m_net_cursor = test_case->ipx ? 2 : 3;
	lanConfig_cursor = test_case->cursor;
	lanConfig_cursor_table[0] = 72 + (int)((pattern & 1U) * 4U);
	lanConfig_cursor_table[1] = 92 + (int)((pattern & 1U) * 4U);
	lanConfig_cursor_table[2] = 124 + (int)((pattern & 1U) * 4U);
	Q_memset (lanConfig_portname, 0, sizeof(lanConfig_portname));
	Q_memset (lanConfig_joinname, 0, sizeof(lanConfig_joinname));
	Q_memset (my_ipx_address, 0, 64U);
	Q_memset (my_tcpip_address, 0, 64U);
	Q_memset (m_return_reason, 0, sizeof(m_return_reason));
	for (i = 0; i < port_lengths[pattern]; i++)
		lanConfig_portname[i] = (char)('0' + i % 10U);
	for (i = 0; i < join_lengths[pattern]; i++)
		lanConfig_joinname[i] = (char)('a' + i % 26U);
	for (i = 0; i < address_lengths[pattern]; i++)
	{
		my_ipx_address[i] = (char)('A' + i % 26U);
		my_tcpip_address[i] = (char)('a' + i % 26U);
	}
	for (i = 0; i < reason_lengths[pattern]; i++)
		m_return_reason[i] = (char)('r' + i % 8U);
	realtime = test_case->phase ? 0.375 : 0.125;
	__asm__ __volatile__ ("fldcw %0" : : "m" (test_case->control_word));
}

static unsigned Bench486MenuLanConfigRun (
		const bench486_menu_lanconfig_case_t *test_case,
		void (*function)(void), bench486_menu_text_result_t *text_result,
		bench486_menu_picture_result_t *picture_result)
{
	unsigned abi;
	unsigned short cw_before, cw_after;

	Bench486MenuLanConfigPrepare (test_case);
	Bench486MenuTextInitTrace ();
	Bench486MenuPictureInitTrace ();
	cw_before = Bench486MenuTextGetControlWord ();
	bench486_menu_text_trace_active = 1;
	abi = Bench486Call_asm486 (function, 0U, NULL, NULL);
	bench486_menu_text_trace_active = 0;
	cw_after = Bench486MenuTextGetControlWord ();
	Bench486MenuTextCapture (text_result, abi, cw_before, cw_after);
	Bench486MenuPictureCapture (picture_result, abi, cw_before, cw_after);
	if ((abi & 0x20U) || cw_before != cw_after)
		return 0x4d4c0301U;
	return 0;
}

void Bench486MenuLanConfigCases (void)
{
	static const unsigned widths[4] = { 319U, 320U, 640U, 1024U };
	static const unsigned title_widths[4] = { 0U, 91U, 320U, 321U };
	static const unsigned precisions[3] = { 0U, 2U, 3U };
	bench486_menu_lanconfig_case_t test_case;
	bench486_menu_text_trace_t saved_text_trace;
	bench486_menu_picture_trace_t saved_picture_trace;
	char saved_portname[sizeof(lanConfig_portname)];
	char saved_joinname[sizeof(lanConfig_joinname)];
	char saved_reason[sizeof(m_return_reason)];
	char saved_ipx[64];
	char saved_tcpip[64];
	int saved_cursor = lanConfig_cursor;
	int saved_rows[3];
	int saved_multiplayer_cursor = m_multiplayer_cursor;
	int saved_net_cursor = m_net_cursor;
	unsigned saved_width = vid.width;
	unsigned saved_title_width = bench486_menu_picture_fake_pic[
			BML_PATH_MULTI_TITLE * 4U];
	unsigned short saved_control_word = Bench486MenuTextGetControlWord ();
	double saved_realtime = realtime;
	int saved_trace_active = bench486_menu_text_trace_active;
	unsigned scenario, rounding, precision_index;
	unsigned total = 0, failure = 0;

	Q_memcpy (saved_portname, lanConfig_portname, sizeof(saved_portname));
	Q_memcpy (saved_joinname, lanConfig_joinname, sizeof(saved_joinname));
	Q_memcpy (saved_reason, m_return_reason, sizeof(saved_reason));
	Q_memcpy (saved_ipx, my_ipx_address, sizeof(saved_ipx));
	Q_memcpy (saved_tcpip, my_tcpip_address, sizeof(saved_tcpip));
	Q_memcpy (saved_rows, lanConfig_cursor_table, sizeof(saved_rows));
	Q_memcpy (&saved_text_trace, &bench486_menu_text_trace,
			sizeof(saved_text_trace));
	Q_memcpy (&saved_picture_trace, &bench486_menu_picture_trace,
			sizeof(saved_picture_trace));

	for (scenario = 0; scenario < 12U && !failure; scenario++)
	for (rounding = 0; rounding < 4U && !failure; rounding++)
	for (precision_index = 0; precision_index < 3U && !failure;
			precision_index++)
	{
		unsigned text_c, text_asm, picture_c, picture_asm;
		unsigned text_diff, picture_diff;
		test_case.video_width = widths[scenario & 3U];
		test_case.title_width = title_widths[scenario & 3U];
		test_case.pattern = scenario & 3U;
		test_case.phase = scenario & 1U;
		test_case.cursor = (int)(scenario % 3U);
		test_case.ipx = (scenario / 3U) & 1U;
		test_case.starting_game = (scenario / 6U) & 1U;
		test_case.control_word = Bench486MenuPageControlWord (
				saved_control_word, precisions[precision_index], rounding);
		total++;
		failure = Bench486MenuLanConfigRun (&test_case,
				M_LanConfig_Draw_C,
				&bench486_menu_lanconfig_text_reference,
				&bench486_menu_lanconfig_picture_reference);
		failure |= Bench486MenuLanConfigRun (&test_case,
				M_LanConfig_Draw,
				&bench486_menu_lanconfig_text_candidate,
				&bench486_menu_lanconfig_picture_candidate);
		text_c = Bench486MenuLanConfigTextExpected (&test_case,
				&bench486_menu_lanconfig_text_reference);
		text_asm = Bench486MenuLanConfigTextExpected (&test_case,
				&bench486_menu_lanconfig_text_candidate);
		picture_c = Bench486MenuLanConfigPictureExpected (&test_case,
				&bench486_menu_lanconfig_picture_reference);
		picture_asm = Bench486MenuLanConfigPictureExpected (&test_case,
				&bench486_menu_lanconfig_picture_candidate);
		text_diff = Bench486MenuTextDifference (
				&bench486_menu_lanconfig_text_reference,
				&bench486_menu_lanconfig_text_candidate);
		picture_diff = Bench486MenuPictureDifference (
				&bench486_menu_lanconfig_picture_reference,
				&bench486_menu_lanconfig_picture_candidate);
		failure |= text_c | text_asm | picture_c | picture_asm |
				text_diff | picture_diff;
		if (failure)
		{
			Bench486Printf ("lan-config draw FAIL scenario %u rounding %u precision %u code %08x checks %08x/%08x/%08x/%08x/%08x/%08x counts %u/%u %u/%u\n",
					scenario, rounding, precision_index, failure,
					text_c, text_asm, picture_c, picture_asm,
					text_diff, picture_diff,
					bench486_menu_lanconfig_text_reference.trace.count,
					bench486_menu_lanconfig_text_candidate.trace.count,
					bench486_menu_lanconfig_picture_reference.trace.count,
					bench486_menu_lanconfig_picture_candidate.trace.count);
		}
	}

	bench486_menu_text_trace_active = 0;
	vid.width = saved_width;
	lanConfig_cursor = saved_cursor;
	m_multiplayer_cursor = saved_multiplayer_cursor;
	m_net_cursor = saved_net_cursor;
	Q_memcpy (lanConfig_cursor_table, saved_rows, sizeof(saved_rows));
	Q_memcpy (lanConfig_portname, saved_portname, sizeof(saved_portname));
	Q_memcpy (lanConfig_joinname, saved_joinname, sizeof(saved_joinname));
	Q_memcpy (m_return_reason, saved_reason, sizeof(saved_reason));
	Q_memcpy (my_ipx_address, saved_ipx, sizeof(saved_ipx));
	Q_memcpy (my_tcpip_address, saved_tcpip, sizeof(saved_tcpip));
	bench486_menu_picture_fake_pic[BML_PATH_MULTI_TITLE * 4U] =
			saved_title_width;
	realtime = saved_realtime;
	bench486_menu_text_trace_active = saved_trace_active;
	Q_memcpy (&bench486_menu_text_trace, &saved_text_trace,
			sizeof(saved_text_trace));
	Q_memcpy (&bench486_menu_picture_trace, &saved_picture_trace,
			sizeof(saved_picture_trace));
	__asm__ __volatile__ ("fldcw %0" : : "m" (saved_control_word));
	if (failure)
		bench486_memory_failures++;
	else
		Bench486Printf ("LAN config menu drawing: %u exact C/assembly text, picture, state, x87 and ABI cases PASS\n",
				total);
}

#endif

#endif
