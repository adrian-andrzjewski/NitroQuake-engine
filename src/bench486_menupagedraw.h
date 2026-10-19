/* C/assembly parity for the main and single-player menu picture pages. */
#ifndef BENCH486_MENUPAGEDRAW_H
#define BENCH486_MENUPAGEDRAW_H

#if defined(BENCH486) && defined(ASM486_SCREEN_OVERLAYS)

#include "asm_menutext.h"

#define BMPD_PATH_QLAQUE 10
#define BMPD_PATH_MAIN_TITLE 11
#define BMPD_PATH_MAIN_CONTENT 12
#define BMPD_PATH_SINGLE_TITLE 13
#define BMPD_PATH_SINGLE_CONTENT 14
#define BMPD_PATH_DOT_FIRST 15
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
extern double host_time;

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
#undef BMPD_PATH_MAIN_CONTENT
#undef BMPD_PATH_MAIN_TITLE
#undef BMPD_PATH_QLAQUE

#endif

#endif
