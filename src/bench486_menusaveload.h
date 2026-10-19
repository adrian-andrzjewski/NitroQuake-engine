/* C/assembly parity for the shared load and save menu renderer. */
#ifndef BENCH486_MENUSAVELOAD_H
#define BENCH486_MENUSAVELOAD_H

#if defined(BENCH486) && defined(ASM486_SCREEN_OVERLAYS)

#include "asm_menutext.h"

#define BSL_PATH_LOAD 27
#define BSL_PATH_SAVE 28
#define BSL_CURSORS 2
#define BSL_TIMES 4
#define BSL_PICTURE_EVENT_PIC 2
#define BSL_PICTURE_EVENT_CACHEPIC 4
#define BSL_TEXT_GUARD_WORDS (sizeof (bench486_menu_saveload_text_reference.trace.before) / sizeof (unsigned))
#define BSL_PICTURE_GUARD_WORDS (sizeof (bench486_menu_saveload_picture_reference.trace.before) / sizeof (unsigned))
#define BSL_TEXT_GLYPH_CAPACITY (sizeof (bench486_menu_saveload_text_reference.trace.glyphs) / sizeof (bench486_menu_saveload_text_reference.trace.glyphs[0]))

static const unsigned bench486_menu_saveload_widths[] =
{
	320, 640, 319, 1024
};

static const unsigned bench486_menu_saveload_precisions[] =
{
	0, 2, 3
};

static const int bench486_menu_saveload_cursors[BSL_CURSORS] =
{
	0, MENU_SAVE_SLOT_COUNT - 1
};

static const double bench486_menu_saveload_times[BSL_TIMES] =
{
	0.125, 0.25, 0.375, 0.5
};

static const int bench486_menu_saveload_cursor_chars[BSL_TIMES] =
{
	12, 13, 13, 12
};

static const char bench486_menu_saveload_long_name[] =
	"ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abc";

static const char *bench486_menu_saveload_names[MENU_SAVE_SLOT_COUNT] =
{
	bench486_menu_saveload_long_name,
	"",
	"E1M1: START",
	"BASE",
	"QF1",
	"slot 05",
	"\200BINARY",
	"UPPER_lower",
	"unused slot",
	"MAP10",
	"FINAL",
	"LAST SAVE"
};

static char bench486_menu_saveload_original_files[
		MENU_SAVE_SLOT_COUNT][MENU_SAVE_FILENAME_STRIDE];
static char bench486_menu_saveload_expected_files[
		MENU_SAVE_SLOT_COUNT][MENU_SAVE_FILENAME_STRIDE];
static bench486_menu_text_result_t bench486_menu_saveload_text_reference;
static bench486_menu_text_result_t bench486_menu_saveload_text_candidate;
static bench486_menu_picture_result_t bench486_menu_saveload_picture_reference;
static bench486_menu_picture_result_t bench486_menu_saveload_picture_candidate;

static unsigned short Bench486MenuSaveLoadControlWord (
		unsigned short base, unsigned precision, unsigned rounding)
{
	return (unsigned short)((base & 0xf0ffU) |
			((precision & 3U) << 8) | ((rounding & 3U) << 10));
}

static void Bench486MenuSaveLoadBuildFiles (void)
{
	unsigned i, j;
	for (i = 0; i < MENU_SAVE_SLOT_COUNT; i++)
	{
		Q_memset (m_filenames[i], 0, MENU_SAVE_FILENAME_STRIDE);
		for (j = 0; j + 1 < MENU_SAVE_FILENAME_STRIDE &&
				bench486_menu_saveload_names[i][j]; j++)
			m_filenames[i][j] = bench486_menu_saveload_names[i][j];
	}
	Q_memcpy (bench486_menu_saveload_expected_files, m_filenames,
			sizeof (bench486_menu_saveload_expected_files));
}

static unsigned Bench486MenuSaveLoadRun (unsigned video_width,
		int cursor, double time, unsigned short control_word,
		void (*function)(void), bench486_menu_text_result_t *text_result,
		bench486_menu_picture_result_t *picture_result)
{
	unsigned abi;
	unsigned short cw_before, cw_after;
	unsigned saved_width = vid.width;
	int saved_cursor = load_cursor;
	double saved_time = realtime;
	unsigned failure = 0;

	vid.width = video_width;
	load_cursor = cursor;
	realtime = time;
	__asm__ __volatile__ ("fldcw %0" : : "m" (control_word));
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
		failure |= 0x4d530001U;
	if (vid.width != video_width || load_cursor != cursor || realtime != time)
		failure |= 0x4d530002U;
	if (Q_memcmp (m_filenames, bench486_menu_saveload_expected_files,
			sizeof (bench486_menu_saveload_expected_files)))
		failure |= 0x4d530003U;
	vid.width = saved_width;
	load_cursor = saved_cursor;
	realtime = saved_time;
	return failure;
}

static unsigned Bench486MenuSaveLoadExpected (int is_save,
		unsigned video_width, int cursor, int cursor_character,
		const bench486_menu_text_result_t *text_result,
		const bench486_menu_picture_result_t *picture_result)
{
	unsigned i, j, glyph = 0;
	unsigned path = is_save ? BSL_PATH_SAVE : BSL_PATH_LOAD;
	unsigned offset = (video_width - 320U) >> 1;
	unsigned picture_width = bench486_menu_picture_fake_pic[path * 4];
	int title_x = (320 - (int)picture_width) / 2;
	int glyph_x, glyph_y;
	unsigned failure = 0;

	if (picture_result->trace.overflow ||
			picture_result->trace.cache_error ||
			picture_result->trace.count != 2)
		return 0x4d530010U;
	if (picture_result->trace.events[0].kind != BSL_PICTURE_EVENT_CACHEPIC ||
			picture_result->trace.events[0].pic !=
					(qpic_t *)(bench486_menu_picture_fake_pic + path * 4) ||
			picture_result->trace.events[1].kind != BSL_PICTURE_EVENT_PIC ||
			picture_result->trace.events[1].x !=
					(int)((unsigned)title_x + offset) ||
			picture_result->trace.events[1].y != 4 ||
			picture_result->trace.events[1].pic !=
					(qpic_t *)(bench486_menu_picture_fake_pic + path * 4) ||
			picture_result->trace.events[1].translation != NULL)
		failure |= 0x4d530011U;
	for (i = 0; i < BSL_PICTURE_GUARD_WORDS; i++)
		if (picture_result->trace.before[i] != 0x4d500000U + i ||
				picture_result->trace.after[i] != 0x4d50f000U + i)
			failure |= 0x4d530012U + i;

	glyph_x = (int)(16U + offset);
	for (i = 0; i < MENU_SAVE_SLOT_COUNT; i++)
	{
		glyph_y = 32 + (int)(i * 8U);
		for (j = 0; j < MENU_SAVE_FILENAME_STRIDE &&
				m_filenames[i][j]; j++)
		{
			int character = (char)m_filenames[i][j] + 128;
			if (glyph >= BSL_TEXT_GLYPH_CAPACITY ||
					text_result->trace.glyphs[glyph].x !=
							(int)((unsigned)glyph_x + j * 8U) ||
					text_result->trace.glyphs[glyph].y != glyph_y ||
					text_result->trace.glyphs[glyph].num != character)
				failure |= 0x4d530020U + (glyph & 0xfU);
			glyph++;
		}
	}
	if (glyph >= BSL_TEXT_GLYPH_CAPACITY || text_result->trace.glyphs[glyph].x !=
			(int)(8U + offset) || text_result->trace.glyphs[glyph].y !=
			32 + cursor * 8 || text_result->trace.glyphs[glyph].num !=
			cursor_character)
		failure |= 0x4d530030U;
	glyph++;
	if (text_result->trace.overflow || text_result->trace.count != glyph)
		failure |= 0x4d530031U;
	for (i = 0; i < BSL_TEXT_GUARD_WORDS; i++)
		if (text_result->trace.before[i] != 0x4d540000U + i ||
				text_result->trace.after[i] != 0x4d54f000U + i)
			failure |= 0x4d530040U + i;
	return failure;
}

void Bench486MenuSaveLoadCases (void)
{
	unsigned page, cursor_index, time_index, width_index, precision_index;
	unsigned rounding, cases = 0, failure = 0;
	unsigned widths = sizeof (bench486_menu_saveload_widths) /
			sizeof (bench486_menu_saveload_widths[0]);
	unsigned precisions = sizeof (bench486_menu_saveload_precisions) /
			sizeof (bench486_menu_saveload_precisions[0]);
	unsigned short original_cw = Bench486MenuTextGetControlWord ();
	unsigned original_load_width =
			bench486_menu_picture_fake_pic[BSL_PATH_LOAD * 4];
	unsigned original_save_width =
			bench486_menu_picture_fake_pic[BSL_PATH_SAVE * 4];
	unsigned saved_width = vid.width;
	int saved_cursor = load_cursor;
	double saved_time = realtime;
	void (*c_function)(void);
	void (*asm_function)(void);

	Q_memcpy (bench486_menu_saveload_original_files, m_filenames,
			sizeof (bench486_menu_saveload_original_files));
	Bench486MenuSaveLoadBuildFiles ();
	bench486_menu_picture_fake_pic[BSL_PATH_LOAD * 4] = 95;
	bench486_menu_picture_fake_pic[BSL_PATH_SAVE * 4] = 321;
	for (page = 0; page < 2 && !failure; page++)
	{
		c_function = page ? M_Save_Draw_C : M_Load_Draw_C;
		asm_function = page ? M_Save_Draw : M_Load_Draw;
		for (cursor_index = 0; cursor_index < BSL_CURSORS && !failure;
				cursor_index++)
		for (time_index = 0; time_index < BSL_TIMES && !failure; time_index++)
		for (width_index = 0; width_index < widths && !failure; width_index++)
		for (precision_index = 0; precision_index < precisions && !failure;
				precision_index++)
		for (rounding = 0; rounding < 4; rounding++)
		{
			unsigned video_width =
					bench486_menu_saveload_widths[width_index];
			int cursor = bench486_menu_saveload_cursors[cursor_index];
			double time = bench486_menu_saveload_times[time_index];
			unsigned short control_word = Bench486MenuSaveLoadControlWord (
					original_cw,
					bench486_menu_saveload_precisions[precision_index],
					rounding);
			unsigned case_failure;

			case_failure = Bench486MenuSaveLoadRun (video_width, cursor,
					time, control_word, c_function,
					&bench486_menu_saveload_text_reference,
					&bench486_menu_saveload_picture_reference);
			case_failure |= Bench486MenuSaveLoadRun (video_width, cursor,
					time, control_word, asm_function,
					&bench486_menu_saveload_text_candidate,
					&bench486_menu_saveload_picture_candidate);
			case_failure |= Bench486MenuSaveLoadExpected ((int)page,
					video_width, cursor,
					bench486_menu_saveload_cursor_chars[time_index],
					&bench486_menu_saveload_text_reference,
					&bench486_menu_saveload_picture_reference);
			case_failure |= Bench486MenuSaveLoadExpected ((int)page,
					video_width, cursor,
					bench486_menu_saveload_cursor_chars[time_index],
					&bench486_menu_saveload_text_candidate,
					&bench486_menu_saveload_picture_candidate);
			case_failure |= Bench486MenuTextDifference (
					&bench486_menu_saveload_text_reference,
					&bench486_menu_saveload_text_candidate);
			case_failure |= Bench486MenuPictureDifference (
					&bench486_menu_saveload_picture_reference,
					&bench486_menu_saveload_picture_candidate);
			cases++;
			if (case_failure)
			{
				Bench486Printf (
						"menu load/save C/assembly FAIL page %u cursor %d time %.3f width %u precision %u rounding %u code %08x\n",
						page, cursor, time, video_width,
						bench486_menu_saveload_precisions[precision_index],
						rounding, case_failure);
				failure = case_failure;
				break;
			}
		}
	}
	bench486_menu_text_trace_active = 0;
	vid.width = saved_width;
	load_cursor = saved_cursor;
	realtime = saved_time;
	Q_memcpy (m_filenames, bench486_menu_saveload_original_files,
			sizeof (bench486_menu_saveload_original_files));
	bench486_menu_picture_fake_pic[BSL_PATH_LOAD * 4] = original_load_width;
	bench486_menu_picture_fake_pic[BSL_PATH_SAVE * 4] = original_save_width;
	__asm__ __volatile__ ("fldcw %0" : : "m" (original_cw));
	if (failure)
		bench486_memory_failures++;
	else
		Bench486Printf (
				"menu load/save pages: %u exact C/assembly cache, text, cursor, and x87 cases PASS\n",
				cases);
}

#undef BSL_TEXT_GLYPH_CAPACITY
#undef BSL_PICTURE_GUARD_WORDS
#undef BSL_TEXT_GUARD_WORDS
#undef BSL_PICTURE_EVENT_CACHEPIC
#undef BSL_PICTURE_EVENT_PIC
#undef BSL_TIMES
#undef BSL_CURSORS
#undef BSL_PATH_SAVE
#undef BSL_PATH_LOAD

#endif

#endif
