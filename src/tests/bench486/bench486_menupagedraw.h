/* C/assembly parity for menu page picture drawing. */
/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
#ifndef BENCH486_MENUPAGEDRAW_H
#define BENCH486_MENUPAGEDRAW_H

#if defined(BENCH486) && defined(ASM486_SCREEN_OVERLAYS)

#include "client/asm_menutext.h"

#define BMPD_PATH_QLAQUE 10
#define BMPD_PATH_MAIN_TITLE 11
#define BMPD_PATH_MAIN_CONTENT 12
#define BMPD_PATH_SINGLE_TITLE 13
#define BMPD_PATH_SINGLE_CONTENT 14
#define BMPD_PATH_DOT_FIRST 15
#define BMPD_PATH_HELP_FIRST 21
#define BMPD_PATH_MULTI_TITLE 29
#define BMPD_PATH_MULTI_CONTENT 30
#define BMPD_PAGE_MAIN 0
#define BMPD_PAGE_SINGLE 1
#define BMPD_CASES_PER_MODE 6
#define BMPD_GUARD_WORDS 2
#define BMPD_EVENT_TRANSPIC 1
#define BMPD_EVENT_PIC 2
#define BMPD_EVENT_CACHEPIC 4

typedef struct bench486_menu_page_draw_case_s
{
	const char *name;
	int page;
	unsigned video_width;
	int cursor;
	double host_time;
	unsigned short control_word;
	unsigned dot_frame;
} bench486_menu_page_draw_case_t;

extern int m_main_cursor;
extern int m_singleplayer_cursor;
extern int m_multiplayer_cursor;
extern int help_page;
extern double host_time;
extern qboolean serialAvailable;
extern qboolean ipxAvailable;
extern qboolean tcpipAvailable;

static const double bench486_menu_page_times[BMPD_CASES_PER_MODE] =
{
	0.05, 0.15, 0.25, 0.35, 0.45, 0.55
};

static const unsigned bench486_menu_page_widths[] =
{
	320, 640, 319, 1024
};

static const unsigned bench486_menu_page_precisions[] =
{
	0, 2, 3
};

static bench486_menu_picture_result_t bench486_menu_page_reference;
static bench486_menu_picture_result_t bench486_menu_page_candidate;

static qpic_t *Bench486MenuPageFakePicture (unsigned path_index)
{
	return (qpic_t *)(bench486_menu_picture_fake_pic + path_index * 4);
}

static unsigned short Bench486MenuPageControlWord (
		unsigned short base, unsigned precision, unsigned rounding)
{
	return (unsigned short)((base & 0xf0ffU) |
			((precision & 3U) << 8) | ((rounding & 3U) << 10));
}

static unsigned Bench486MenuPageDrawRun (
		const bench486_menu_page_draw_case_t *test_case,
		void (*function)(void), bench486_menu_picture_result_t *result)
{
	unsigned abi;
	unsigned short cw_before, cw_after;

	vid.width = test_case->video_width;
	m_main_cursor = test_case->cursor;
	m_singleplayer_cursor = test_case->cursor;
	host_time = test_case->host_time;
	__asm__ __volatile__ ("fldcw %0" : : "m" (test_case->control_word));
	Bench486MenuPictureInitTrace ();
	cw_before = Bench486MenuTextGetControlWord ();
	bench486_menu_text_trace_active = 1;
	abi = Bench486Call_asm486 (function, 0, NULL, NULL);
	bench486_menu_text_trace_active = 0;
	cw_after = Bench486MenuTextGetControlWord ();
	Bench486MenuPictureCapture (result, abi, cw_before, cw_after);
	if ((abi & 0x20U) || cw_before != cw_after)
	{
		Bench486Printf (
				"menu page ABI/x87 FAIL %s page %d width %u cursor %d abi %08x cw %04x/%04x\n",
				test_case->name, test_case->page, test_case->video_width,
				test_case->cursor, abi, cw_before, cw_after);
		return 0x4d510001U;
	}
	return 0;
}

static unsigned Bench486MenuPageExpectEvent (
		const bench486_menu_picture_result_t *result, unsigned index,
		int kind, int x, int y, qpic_t *pic)
{
	const bench486_menu_picture_event_t *event;

	if (index >= result->trace.count)
		return 0x4d510010U + index;
	event = &result->trace.events[index];
	if (event->kind != kind || event->x != x || event->y != y ||
			event->pic != pic || event->translation != NULL)
		return 0x4d510020U + index;
	return 0;
}

static unsigned Bench486MenuPageExpected (
		const bench486_menu_page_draw_case_t *test_case,
		const bench486_menu_picture_result_t *result)
{
	unsigned i;
	unsigned viewport_offset = (test_case->video_width - 320U) >> 1;
	unsigned title_path = test_case->page == BMPD_PAGE_MAIN ?
			BMPD_PATH_MAIN_TITLE : BMPD_PATH_SINGLE_TITLE;
	unsigned content_path = test_case->page == BMPD_PAGE_MAIN ?
			BMPD_PATH_MAIN_CONTENT : BMPD_PATH_SINGLE_CONTENT;
	unsigned title_width = bench486_menu_picture_fake_pic[title_path * 4];
	int title_x = (320 - (int)title_width) / 2;
	int cursor_y = 32 + test_case->cursor * 20;
	unsigned failure = 0;

	if (result->trace.overflow || result->trace.cache_error ||
			result->trace.count != 8)
		return 0x4d510002U;
	failure |= Bench486MenuPageExpectEvent (result, 0,
			BMPD_EVENT_CACHEPIC, 0, 0,
			Bench486MenuPageFakePicture (BMPD_PATH_QLAQUE));
	failure |= Bench486MenuPageExpectEvent (result, 1,
			BMPD_EVENT_TRANSPIC, (int)(viewport_offset + 16U), 4,
			Bench486MenuPageFakePicture (BMPD_PATH_QLAQUE));
	failure |= Bench486MenuPageExpectEvent (result, 2,
			BMPD_EVENT_CACHEPIC, 0, 0,
			Bench486MenuPageFakePicture (title_path));
	failure |= Bench486MenuPageExpectEvent (result, 3,
			BMPD_EVENT_PIC, (int)(viewport_offset + (unsigned)title_x), 4,
			Bench486MenuPageFakePicture (title_path));
	failure |= Bench486MenuPageExpectEvent (result, 4,
			BMPD_EVENT_CACHEPIC, 0, 0,
			Bench486MenuPageFakePicture (content_path));
	failure |= Bench486MenuPageExpectEvent (result, 5,
			BMPD_EVENT_TRANSPIC, (int)(viewport_offset + 72U), 32,
			Bench486MenuPageFakePicture (content_path));
	failure |= Bench486MenuPageExpectEvent (result, 6,
			BMPD_EVENT_CACHEPIC, 0, 0,
			Bench486MenuPageFakePicture (
					BMPD_PATH_DOT_FIRST + test_case->dot_frame - 1));
	failure |= Bench486MenuPageExpectEvent (result, 7,
			BMPD_EVENT_TRANSPIC, (int)(viewport_offset + 54U), cursor_y,
			Bench486MenuPageFakePicture (
					BMPD_PATH_DOT_FIRST + test_case->dot_frame - 1));
	for (i = 0; i < BMPD_GUARD_WORDS; i++)
		if (result->trace.before[i] != 0x4d500000U + i ||
				result->trace.after[i] != 0x4d50f000U + i)
			failure |= 0x4d510030U + i;
	return failure;
}

static unsigned Bench486MenuHelpExpected (int page, unsigned video_width,
		const bench486_menu_picture_result_t *result)
{
	unsigned i;
	unsigned viewport_offset = (video_width - 320U) >> 1;
	unsigned help_path = BMPD_PATH_HELP_FIRST + (unsigned)page;
	unsigned failure = 0;

	if (result->trace.overflow || result->trace.cache_error ||
			result->trace.count != 2)
		return 0x4d510040U;
	failure |= Bench486MenuPageExpectEvent (result, 0,
			BMPD_EVENT_CACHEPIC, 0, 0,
			Bench486MenuPageFakePicture (help_path));
	failure |= Bench486MenuPageExpectEvent (result, 1,
			BMPD_EVENT_PIC, (int)viewport_offset, 0,
			Bench486MenuPageFakePicture (help_path));
	for (i = 0; i < BMPD_GUARD_WORDS; i++)
		if (result->trace.before[i] != 0x4d500000U + i ||
				result->trace.after[i] != 0x4d50f000U + i)
			failure |= 0x4d510050U + i;
	return failure;
}

static unsigned Bench486MenuHelpRun (int page, unsigned video_width,
		unsigned short control_word, void (*function)(void),
		bench486_menu_picture_result_t *result)
{
	unsigned abi;
	unsigned short cw_before, cw_after;
	unsigned failure = 0;
	unsigned saved_width = vid.width;
	int saved_help_page = help_page;

	vid.width = video_width;
	help_page = page;
	__asm__ __volatile__ ("fldcw %0" : : "m" (control_word));
	Bench486MenuPictureInitTrace ();
	cw_before = Bench486MenuTextGetControlWord ();
	bench486_menu_text_trace_active = 1;
	abi = Bench486Call_asm486 (function, 0, NULL, NULL);
	bench486_menu_text_trace_active = 0;
	cw_after = Bench486MenuTextGetControlWord ();
	Bench486MenuPictureCapture (result, abi, cw_before, cw_after);
	if ((abi & 0x20U) || cw_before != cw_after)
		failure |= 0x4d510060U;
	if (vid.width != video_width || help_page != page)
		failure |= 0x4d510061U;
	vid.width = saved_width;
	help_page = saved_help_page;
	return failure;
}

static void Bench486MenuHelpPageCases (void)
{
	unsigned page, width_index, rounding, cases = 0, failure = 0;
	unsigned widths = sizeof (bench486_menu_page_widths) /
			sizeof (bench486_menu_page_widths[0]);
	unsigned short original_cw = Bench486MenuTextGetControlWord ();
	unsigned saved_width = vid.width;
	int saved_help_page = help_page;
	bench486_menu_picture_result_t reference, candidate;

	for (page = 0; page < 6 && !failure; page++)
		for (width_index = 0; width_index < widths && !failure; width_index++)
			for (rounding = 0; rounding < 4; rounding++)
			{
				unsigned video_width = bench486_menu_page_widths[width_index];
				unsigned short control_word = Bench486MenuPageControlWord (
						original_cw, 0, rounding);
				unsigned case_failure;

				case_failure = Bench486MenuHelpRun ((int)page, video_width,
						control_word, M_Help_Draw_C, &reference);
				case_failure |= Bench486MenuHelpRun ((int)page, video_width,
						control_word, M_Help_Draw, &candidate);
				case_failure |= Bench486MenuHelpExpected ((int)page,
						video_width, &reference);
				case_failure |= Bench486MenuHelpExpected ((int)page,
						video_width, &candidate);
				case_failure |= Bench486MenuPictureDifference (
						&reference, &candidate);
				cases++;
				if (case_failure)
				{
					Bench486Printf (
							"menu help-page C/assembly FAIL page %u width %u rounding %u code %08x\n",
							page, video_width, rounding, case_failure);
					failure = case_failure;
					break;
				}
			}
	vid.width = saved_width;
	help_page = saved_help_page;
	__asm__ __volatile__ ("fldcw %0" : : "m" (original_cw));
	bench486_menu_text_trace_active = 0;
	if (failure)
		bench486_memory_failures++;
	else
		Bench486Printf (
				"menu help pages: %u exact C/assembly cache, draw, and ABI cases PASS\n",
				cases);
}

void Bench486MenuPageDrawCases (void)
{
	unsigned page, precision_index, rounding, frame, cases = 0;
	unsigned failure = 0;
	unsigned short original_cw = Bench486MenuTextGetControlWord ();
	unsigned saved_width = vid.width;
	int saved_main_cursor = m_main_cursor;
	int saved_single_cursor = m_singleplayer_cursor;
	double saved_host_time = host_time;
	unsigned saved_main_title_width =
			bench486_menu_picture_fake_pic[BMPD_PATH_MAIN_TITLE * 4];
	unsigned saved_single_title_width =
			bench486_menu_picture_fake_pic[BMPD_PATH_SINGLE_TITLE * 4];
	unsigned widths = sizeof(bench486_menu_page_widths) /
			sizeof(bench486_menu_page_widths[0]);
	unsigned precisions = sizeof(bench486_menu_page_precisions) /
			sizeof(bench486_menu_page_precisions[0]);
	void (*c_function)(void);
	void (*asm_function)(void);
	bench486_menu_page_draw_case_t test_case;

	bench486_menu_picture_fake_pic[BMPD_PATH_MAIN_TITLE * 4] = 96;
	bench486_menu_picture_fake_pic[BMPD_PATH_SINGLE_TITLE * 4] = 124;
	for (page = BMPD_PAGE_MAIN; page <= BMPD_PAGE_SINGLE; page++)
	{
		c_function = page == BMPD_PAGE_MAIN ?
				M_Main_Draw_C : M_SinglePlayer_Draw_C;
		asm_function = page == BMPD_PAGE_MAIN ?
				M_Main_Draw : M_SinglePlayer_Draw;
		for (precision_index = 0; precision_index < precisions;
				precision_index++)
			for (rounding = 0; rounding < 4; rounding++)
			for (frame = 0; frame < BMPD_CASES_PER_MODE; frame++)
			{
				unsigned mode_index = precision_index * 4 + rounding + frame;
				unsigned case_failure;

				test_case.name = "animated-page-layout";
				test_case.page = page;
				test_case.video_width = bench486_menu_page_widths[
						(page + mode_index) % widths];
				test_case.cursor = (int)((frame + rounding) %
						(page == BMPD_PAGE_MAIN ? 5U : 3U));
				test_case.host_time = bench486_menu_page_times[frame];
				test_case.control_word = Bench486MenuPageControlWord (
						original_cw,
						bench486_menu_page_precisions[precision_index],
						rounding);
				test_case.dot_frame = frame + 1;
				case_failure = Bench486MenuPageDrawRun (&test_case,
						c_function, &bench486_menu_page_reference);
				case_failure |= Bench486MenuPageDrawRun (&test_case,
						asm_function, &bench486_menu_page_candidate);
				case_failure |= Bench486MenuPageExpected (&test_case,
						&bench486_menu_page_reference);
				case_failure |= Bench486MenuPageExpected (&test_case,
						&bench486_menu_page_candidate);
				case_failure |= Bench486MenuPictureDifference (
						&bench486_menu_page_reference,
						&bench486_menu_page_candidate);
				cases++;
				if (case_failure)
				{
					Bench486Printf (
							"menu page C/assembly FAIL page %u precision %u rounding %u frame %u code %08x\n",
							page, bench486_menu_page_precisions[precision_index],
							rounding, frame + 1, case_failure);
					failure = case_failure;
					break;
				}
			}
		if (failure)
			break;
	}
	bench486_menu_text_trace_active = 0;
	vid.width = saved_width;
	m_main_cursor = saved_main_cursor;
	m_singleplayer_cursor = saved_single_cursor;
	host_time = saved_host_time;
	bench486_menu_picture_fake_pic[BMPD_PATH_MAIN_TITLE * 4] =
			saved_main_title_width;
	bench486_menu_picture_fake_pic[BMPD_PATH_SINGLE_TITLE * 4] =
			saved_single_title_width;
	__asm__ __volatile__ ("fldcw %0" : : "m" (original_cw));
	if (failure)
		bench486_memory_failures++;
	else
		Bench486Printf (
				"menu main/single-player pages: %u exact C/assembly cache, draw, and x87 cases PASS\n",
				cases);
}

static bench486_menu_picture_result_t
		bench486_menu_multiplayer_picture_reference;
static bench486_menu_picture_result_t
		bench486_menu_multiplayer_picture_candidate;
static bench486_menu_text_result_t bench486_menu_multiplayer_text_reference;
static bench486_menu_text_result_t bench486_menu_multiplayer_text_candidate;

static const int bench486_menu_multiplayer_network_states[][3] =
{
	{ 0, 0, 0 },
	{ 1, 0, 0 },
	{ 0, 1, 0 },
	{ 0, 0, 1 }
};

static unsigned Bench486MenuMultiPlayerRun (
		const bench486_menu_page_draw_case_t *test_case,
		int serial_available, int ipx_available, int tcpip_available,
		void (*function)(void), bench486_menu_picture_result_t *picture_result,
		bench486_menu_text_result_t *text_result)
{
	unsigned abi;
	unsigned short cw_before, cw_after;
	unsigned saved_width = vid.width;
	int saved_cursor = m_multiplayer_cursor;
	double saved_host_time = host_time;
	qboolean saved_serial = serialAvailable;
	qboolean saved_ipx = ipxAvailable;
	qboolean saved_tcpip = tcpipAvailable;
	unsigned failure = 0;

	vid.width = test_case->video_width;
	m_multiplayer_cursor = test_case->cursor;
	host_time = test_case->host_time;
	serialAvailable = serial_available;
	ipxAvailable = ipx_available;
	tcpipAvailable = tcpip_available;
	__asm__ __volatile__ ("fldcw %0" : : "m" (test_case->control_word));
	Bench486MenuPictureInitTrace ();
	Bench486MenuTextInitTrace ();
	cw_before = Bench486MenuTextGetControlWord ();
	bench486_menu_text_trace_active = 1;
	abi = Bench486Call_asm486 (function, 0, NULL, NULL);
	bench486_menu_text_trace_active = 0;
	cw_after = Bench486MenuTextGetControlWord ();
	Bench486MenuPictureCapture (picture_result, abi, cw_before, cw_after);
	Bench486MenuTextCapture (text_result, abi, cw_before, cw_after);
	if ((abi & 0x20U) || cw_before != cw_after)
		failure |= 0x4d580001U;
	if (vid.width != test_case->video_width ||
			m_multiplayer_cursor != test_case->cursor ||
			host_time != test_case->host_time ||
			serialAvailable != serial_available ||
			ipxAvailable != ipx_available ||
			tcpipAvailable != tcpip_available)
		failure |= 0x4d580002U;
	vid.width = saved_width;
	m_multiplayer_cursor = saved_cursor;
	host_time = saved_host_time;
	serialAvailable = saved_serial;
	ipxAvailable = saved_ipx;
	tcpipAvailable = saved_tcpip;
	return failure;
}

static unsigned Bench486MenuMultiPlayerExpectedPicture (
		const bench486_menu_page_draw_case_t *test_case,
		const bench486_menu_picture_result_t *result)
{
	unsigned viewport_offset = (test_case->video_width - 320U) >> 1;
	unsigned title_width = bench486_menu_picture_fake_pic[
			BMPD_PATH_MULTI_TITLE * 4];
	unsigned dot_path = BMPD_PATH_DOT_FIRST + test_case->dot_frame - 1;
	int title_x = (320 - (int)title_width) / 2;
	int cursor_y = 32 + test_case->cursor * 20;
	unsigned i;
	unsigned failure = 0;

	if (result->trace.overflow || result->trace.cache_error ||
			result->trace.count != 8)
		return 0x4d580010U;
	failure |= Bench486MenuPageExpectEvent (result, 0,
			BMPD_EVENT_CACHEPIC, 0, 0,
			Bench486MenuPageFakePicture (BMPD_PATH_QLAQUE));
	failure |= Bench486MenuPageExpectEvent (result, 1,
			BMPD_EVENT_TRANSPIC, (int)(viewport_offset + 16U), 4,
			Bench486MenuPageFakePicture (BMPD_PATH_QLAQUE));
	failure |= Bench486MenuPageExpectEvent (result, 2,
			BMPD_EVENT_CACHEPIC, 0, 0,
			Bench486MenuPageFakePicture (BMPD_PATH_MULTI_TITLE));
	failure |= Bench486MenuPageExpectEvent (result, 3,
			BMPD_EVENT_PIC, (int)(viewport_offset + (unsigned)title_x), 4,
			Bench486MenuPageFakePicture (BMPD_PATH_MULTI_TITLE));
	failure |= Bench486MenuPageExpectEvent (result, 4,
			BMPD_EVENT_CACHEPIC, 0, 0,
			Bench486MenuPageFakePicture (BMPD_PATH_MULTI_CONTENT));
	failure |= Bench486MenuPageExpectEvent (result, 5,
			BMPD_EVENT_TRANSPIC, (int)(viewport_offset + 72U), 32,
			Bench486MenuPageFakePicture (BMPD_PATH_MULTI_CONTENT));
	failure |= Bench486MenuPageExpectEvent (result, 6,
			BMPD_EVENT_CACHEPIC, 0, 0,
			Bench486MenuPageFakePicture (dot_path));
	failure |= Bench486MenuPageExpectEvent (result, 7,
			BMPD_EVENT_TRANSPIC, (int)(viewport_offset + 54U), cursor_y,
			Bench486MenuPageFakePicture (dot_path));
	for (i = 0; i < BMPD_GUARD_WORDS; i++)
		if (result->trace.before[i] != 0x4d500000U + i ||
				result->trace.after[i] != 0x4d50f000U + i)
			failure |= 0x4d580020U + i;
	return failure;
}

static unsigned Bench486MenuMultiPlayerExpectedText (
		unsigned video_width, int has_network,
		const bench486_menu_text_result_t *result)
{
	static const char message[] = "No Communications Available";
	unsigned viewport_offset = (video_width - 320U) >> 1;
	unsigned expected_count = has_network ? 0 : sizeof(message) - 1;
	unsigned i;

	if (result->trace.overflow || result->trace.count != expected_count)
		return 0x4d580030U;
	for (i = 0; i < expected_count; i++)
		if (result->trace.glyphs[i].x !=
				(int)(viewport_offset + 52U + i * 8U) ||
				result->trace.glyphs[i].y != 148 ||
				result->trace.glyphs[i].num != (int)message[i])
			return 0x4d580040U + i;
	for (i = 0; i < BMPD_GUARD_WORDS; i++)
		if (result->trace.before[i] != 0x4d540000U + i ||
				result->trace.after[i] != 0x4d54f000U + i)
			return 0x4d580060U + i;
	return 0;
}

void Bench486MenuMultiPlayerCases (void)
{
	unsigned state, precision_index, rounding, frame, width_index;
	unsigned cases = 0, failure = 0;
	unsigned widths = sizeof (bench486_menu_page_widths) /
			sizeof (bench486_menu_page_widths[0]);
	unsigned precisions = sizeof (bench486_menu_page_precisions) /
			sizeof (bench486_menu_page_precisions[0]);
	unsigned states = sizeof (bench486_menu_multiplayer_network_states) /
			sizeof (bench486_menu_multiplayer_network_states[0]);
	unsigned short original_cw = Bench486MenuTextGetControlWord ();
	unsigned saved_width = vid.width;
	unsigned saved_title_width =
			bench486_menu_picture_fake_pic[BMPD_PATH_MULTI_TITLE * 4];
	int saved_cursor = m_multiplayer_cursor;
	double saved_host_time = host_time;
	qboolean saved_serial = serialAvailable;
	qboolean saved_ipx = ipxAvailable;
	qboolean saved_tcpip = tcpipAvailable;
	bench486_menu_page_draw_case_t test_case;

	bench486_menu_picture_fake_pic[BMPD_PATH_MULTI_TITLE * 4] = 91;
	for (state = 0; state < states && !failure; state++)
		for (precision_index = 0; precision_index < precisions && !failure;
				precision_index++)
			for (rounding = 0; rounding < 4 && !failure; rounding++)
				for (frame = 0; frame < BMPD_CASES_PER_MODE && !failure; frame++)
					for (width_index = 0; width_index < widths; width_index++)
					{
						unsigned case_failure;
						int serial =
							bench486_menu_multiplayer_network_states[state][0];
						int ipx =
							bench486_menu_multiplayer_network_states[state][1];
						int tcpip =
							bench486_menu_multiplayer_network_states[state][2];
						int has_network = serial || ipx || tcpip;

					test_case.name = "multiplayer-menu-page";
					test_case.page = 0;
					test_case.video_width = bench486_menu_page_widths[
							(width_index + frame + state) % widths];
					test_case.cursor = (int)((frame + rounding + state) % 3U);
					test_case.host_time = bench486_menu_page_times[frame];
					test_case.control_word = Bench486MenuPageControlWord (
							original_cw,
							bench486_menu_page_precisions[precision_index],
							rounding);
					test_case.dot_frame = frame + 1;
					case_failure = Bench486MenuMultiPlayerRun (&test_case,
							serial, ipx, tcpip, M_MultiPlayer_Draw_C,
							&bench486_menu_multiplayer_picture_reference,
							&bench486_menu_multiplayer_text_reference);
					case_failure |= Bench486MenuMultiPlayerRun (&test_case,
							serial, ipx, tcpip, M_MultiPlayer_Draw,
							&bench486_menu_multiplayer_picture_candidate,
							&bench486_menu_multiplayer_text_candidate);
					case_failure |= Bench486MenuMultiPlayerExpectedPicture (
							&test_case,
							&bench486_menu_multiplayer_picture_reference);
					case_failure |= Bench486MenuMultiPlayerExpectedPicture (
							&test_case,
							&bench486_menu_multiplayer_picture_candidate);
					case_failure |= Bench486MenuMultiPlayerExpectedText (
							test_case.video_width, has_network,
							&bench486_menu_multiplayer_text_reference);
					case_failure |= Bench486MenuMultiPlayerExpectedText (
							test_case.video_width, has_network,
							&bench486_menu_multiplayer_text_candidate);
					case_failure |= Bench486MenuPictureDifference (
							&bench486_menu_multiplayer_picture_reference,
							&bench486_menu_multiplayer_picture_candidate);
					case_failure |= Bench486MenuTextDifference (
							&bench486_menu_multiplayer_text_reference,
							&bench486_menu_multiplayer_text_candidate);
					cases++;
					if (case_failure)
					{
						Bench486Printf (
								"menu multiplayer C/assembly FAIL state %u precision %u rounding %u frame %u width %u code %08x\n",
								state,
								bench486_menu_page_precisions[precision_index],
								rounding, frame + 1, test_case.video_width,
								case_failure);
						failure = case_failure;
						break;
					}
				}
	bench486_menu_text_trace_active = 0;
	vid.width = saved_width;
	m_multiplayer_cursor = saved_cursor;
	host_time = saved_host_time;
	serialAvailable = saved_serial;
	ipxAvailable = saved_ipx;
	tcpipAvailable = saved_tcpip;
	bench486_menu_picture_fake_pic[BMPD_PATH_MULTI_TITLE * 4] =
			saved_title_width;
	__asm__ __volatile__ ("fldcw %0" : : "m" (original_cw));
	if (failure)
		bench486_memory_failures++;
	else
		Bench486Printf (
				"menu multiplayer page: %u exact C/assembly animation, network, picture, text, and x87 cases PASS\n",
				cases);
}

#undef BMPD_CASES_PER_MODE
#undef BMPD_EVENT_CACHEPIC
#undef BMPD_EVENT_PIC
#undef BMPD_EVENT_TRANSPIC
#undef BMPD_GUARD_WORDS
#undef BMPD_PAGE_SINGLE
#undef BMPD_PAGE_MAIN
#undef BMPD_PATH_DOT_FIRST
#undef BMPD_PATH_SINGLE_CONTENT
#undef BMPD_PATH_SINGLE_TITLE
#undef BMPD_PATH_HELP_FIRST
#undef BMPD_PATH_MULTI_CONTENT
#undef BMPD_PATH_MULTI_TITLE
#undef BMPD_PATH_MAIN_CONTENT
#undef BMPD_PATH_MAIN_TITLE
#undef BMPD_PATH_QLAQUE

#endif

#endif
