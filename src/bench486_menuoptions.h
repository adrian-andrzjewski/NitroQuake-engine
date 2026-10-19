/* C/assembly parity for the options page, sliders, and checkboxes. */
#ifndef BENCH486_MENUOPTIONS_H
#define BENCH486_MENUOPTIONS_H

#if defined(BENCH486) && defined(ASM486_SCREEN_OVERLAYS)

#include "asm_menutext.h"

#define BMO_OPTION_TITLE_PATH 40U
#define BMO_FLOAT_COUNT 9U
#define BMO_VALUE_PROFILES 8U
#define BMO_TEXT_GUARD_WORDS 2U
#define BMO_PICTURE_GUARD_WORDS 2U
#define BMO_EVENT_TRANSPIC 1
#define BMO_EVENT_PIC 2
#define BMO_EVENT_CACHEPIC 4

extern cvar_t scr_viewsize, v_gamma, sensitivity, bgmvolume, volume;
extern cvar_t cl_forwardspeed, m_pitch, lookspring, lookstrafe;
extern int options_cursor;
extern double realtime;
extern void (*vid_menudrawfn)(void);

typedef struct bench486_menu_options_case_s
{
	unsigned value_profile;
	unsigned video_width;
	int cursor;
	unsigned time_index;
	int video_enabled;
	unsigned short control_word;
} bench486_menu_options_case_t;

static const unsigned bench486_menu_options_values[BMO_VALUE_PROFILES]
		[BMO_FLOAT_COUNT] =
{
	/* view size, gamma, sensitivity, CD volume, sound volume, forward speed,
	 * pitch, lookspring, lookstrafe */
	{ 0x42c80000U, 0x3f333333U, 0x40a00000U, 0x3e800000U, 0x3f400000U,
		0x43480000U, 0xbf800000U, 0x3f800000U, 0x00000000U },
	{ 0xc2b40000U, 0xc0000000U, 0xbf800000U, 0xbf800000U, 0xbe800000U,
		0x4347ffffU, 0x80000001U, 0x3f400000U, 0xbf400000U },
	{ 0x43700000U, 0x40000000U, 0x41400000U, 0x3fc00000U, 0x40000000U,
		0x43480001U, 0x3f800000U, 0x3ff33333U, 0xbff33333U },
	{ 0x7f800000U, 0x7fc00001U, 0xff800000U, 0x7fc00002U, 0x7f800000U,
		0x7fc00003U, 0x7fc00004U, 0x7f800000U, 0xff800000U },
	{ 0xff800000U, 0x7f800000U, 0x7fc00005U, 0xff800000U, 0x7fc00006U,
		0x43480000U, 0xff800000U, 0xff800000U, 0x7fc00007U },
	{ 0x41f0cccdU, 0x3f000000U, 0x3f8ccccdU, 0x00000000U, 0x3f7fffacU,
		0x4347ffffU, 0x80000000U, 0x3f7ff972U, 0xbf7ff972U },
	{ 0x42f00000U, 0x3f800000U, 0x41300000U, 0x3f800000U, 0x3f800000U,
		0x43480001U, 0x80000001U, 0xbf800000U, 0x3f800000U },
	{ 0x42960000U, 0x3f400000U, 0x00000000U, 0x3f000000U, 0x3f000000U,
		0x7f800000U, 0x00000000U, 0x3f000000U, 0xbf000000U }
};

static const unsigned bench486_menu_options_widths[4] =
	{ 319U, 320U, 640U, 1024U };
static const unsigned bench486_menu_options_precisions[3] = { 0U, 2U, 3U };
static const int bench486_menu_options_cursors[4] = { 0, 5, 11, 12 };
static const double bench486_menu_options_times[8] =
	{ 0.0, 0.125, 0.375, -0.125, -0.375, 0.1, 0.3, 1.25 };

static bench486_menu_text_result_t bench486_menu_options_text_reference;
static bench486_menu_text_result_t bench486_menu_options_text_candidate;
static bench486_menu_picture_result_t bench486_menu_options_picture_reference;
static bench486_menu_picture_result_t bench486_menu_options_picture_candidate;

static float Bench486MenuOptionsFloatFromBits (unsigned bits)
{
	union
	{
		unsigned bits;
		float value;
	} representation;
	representation.bits = bits;
	return representation.value;
}

static void Bench486MenuOptionsSetValues (unsigned profile)
{
	static cvar_t *cvars[BMO_FLOAT_COUNT] =
	{
		&scr_viewsize, &v_gamma, &sensitivity, &bgmvolume, &volume,
		&cl_forwardspeed, &m_pitch, &lookspring, &lookstrafe
	};
	unsigned i;
	for (i = 0; i < BMO_FLOAT_COUNT; i++)
		cvars[i]->value = Bench486MenuOptionsFloatFromBits (
				bench486_menu_options_values[profile][i]);
}

static void Bench486MenuOptionsVideoDrawStub (void)
{
}

static unsigned short Bench486MenuOptionsControlWord (
		unsigned short base, unsigned precision, unsigned rounding)
{
	return (unsigned short)((base & 0xf0ffU) |
			((precision & 3U) << 8) | ((rounding & 3U) << 10));
}

static unsigned Bench486MenuOptionsRun (
		const bench486_menu_options_case_t *test_case,
		void (*function)(void), bench486_menu_text_result_t *text_result,
		bench486_menu_picture_result_t *picture_result)
{
	unsigned abi;
	unsigned short cw_before, cw_after;

	vid.width = test_case->video_width;
	options_cursor = test_case->cursor;
	realtime = bench486_menu_options_times[test_case->time_index];
	vid_menudrawfn = test_case->video_enabled ?
			Bench486MenuOptionsVideoDrawStub : NULL;
	Bench486MenuOptionsSetValues (test_case->value_profile);
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
		return 0x4d4f0001U;
	return 0;
}

static unsigned Bench486MenuOptionsExpected (
		const bench486_menu_options_case_t *test_case,
		const bench486_menu_text_result_t *text_result,
		const bench486_menu_picture_result_t *picture_result)
{
	unsigned i;
	unsigned viewport_offset = (test_case->video_width - 320U) >> 1;
	unsigned title_width = bench486_menu_picture_fake_pic[
			BMO_OPTION_TITLE_PATH * 4U];
	int title_x = (320 - (int)title_width) / 2;
	const bench486_menu_picture_event_t *event;
	qpic_t *plaque = (qpic_t *)(bench486_menu_picture_fake_pic + 10U * 4U);
	qpic_t *title = (qpic_t *)(bench486_menu_picture_fake_pic +
			BMO_OPTION_TITLE_PATH * 4U);

	if (text_result->trace.overflow || text_result->trace.count < 330U ||
			text_result->trace.count > 400U)
		return 0x4d4f0010U;
	for (i = 0; i < BMO_TEXT_GUARD_WORDS; i++)
		if (text_result->trace.before[i] != 0x4d540000U + i ||
				text_result->trace.after[i] != 0x4d54f000U + i)
			return 0x4d4f0020U + i;
	if (picture_result->trace.overflow || picture_result->trace.cache_error ||
			picture_result->trace.count != 4U)
		return 0x4d4f0030U;
	for (i = 0; i < BMO_PICTURE_GUARD_WORDS; i++)
		if (picture_result->trace.before[i] != 0x4d500000U + i ||
				picture_result->trace.after[i] != 0x4d50f000U + i)
			return 0x4d4f0040U + i;
	event = &picture_result->trace.events[0];
	if (event->kind != BMO_EVENT_CACHEPIC || event->pic != plaque)
		return 0x4d4f0050U;
	event = &picture_result->trace.events[1];
	if (event->kind != BMO_EVENT_TRANSPIC ||
			event->x != (int)(viewport_offset + 16U) || event->y != 4 ||
			event->pic != plaque || event->translation)
		return 0x4d4f0051U;
	event = &picture_result->trace.events[2];
	if (event->kind != BMO_EVENT_CACHEPIC || event->pic != title)
		return 0x4d4f0052U;
	event = &picture_result->trace.events[3];
	if (event->kind != BMO_EVENT_PIC ||
			event->x != (int)(viewport_offset + (unsigned)title_x) ||
			event->y != 4 || event->pic != title || event->translation)
		return 0x4d4f0053U;
	return 0;
}

void Bench486MenuOptionsCases (void)
{
	static cvar_t *cvars[BMO_FLOAT_COUNT] =
	{
		&scr_viewsize, &v_gamma, &sensitivity, &bgmvolume, &volume,
		&cl_forwardspeed, &m_pitch, &lookspring, &lookstrafe
	};
	static const unsigned rounding_modes[4] = { 0U, 1U, 2U, 3U };
	static const unsigned saved_title_index = BMO_OPTION_TITLE_PATH * 4U;
	float saved_values[BMO_FLOAT_COUNT];
	bench486_menu_text_trace_t saved_text_trace;
	bench486_menu_picture_trace_t saved_picture_trace;
	unsigned saved_width = vid.width;
	unsigned saved_title_width = bench486_menu_picture_fake_pic[saved_title_index];
	int saved_cursor = options_cursor;
	int saved_text_active = bench486_menu_text_trace_active;
	void (*saved_video_draw)(void) = vid_menudrawfn;
	double saved_realtime = realtime;
	unsigned short saved_control_word = Bench486MenuTextGetControlWord ();
	unsigned precision_index, rounding, profile, width_index;
	unsigned cases = 0, failure = 0, i;
	bench486_menu_options_case_t test_case;

	for (i = 0; i < BMO_FLOAT_COUNT; i++)
		saved_values[i] = cvars[i]->value;
	Q_memcpy (&saved_text_trace, &bench486_menu_text_trace,
			sizeof(saved_text_trace));
	Q_memcpy (&saved_picture_trace, &bench486_menu_picture_trace,
			sizeof(saved_picture_trace));
	bench486_menu_picture_fake_pic[saved_title_index] = 101U;

	for (profile = 0; profile < BMO_VALUE_PROFILES && !failure; profile++)
	for (precision_index = 0; precision_index < 3 && !failure;
			precision_index++)
	for (rounding = 0; rounding < 4 && !failure; rounding++)
	for (width_index = 0; width_index < 4 && !failure; width_index++)
	{
		unsigned case_failure;
		test_case.value_profile = profile;
		test_case.video_width = bench486_menu_options_widths[width_index];
		test_case.cursor = bench486_menu_options_cursors[
				(profile + rounding + width_index) % 4U];
		test_case.time_index =
				(profile + rounding + width_index + precision_index) % 8U;
		test_case.video_enabled = (int)((profile + rounding + width_index) & 1U);
		test_case.control_word = Bench486MenuOptionsControlWord (
				saved_control_word,
				bench486_menu_options_precisions[precision_index],
				rounding_modes[rounding]);
		case_failure = Bench486MenuOptionsRun (&test_case,
				M_Options_Draw_C, &bench486_menu_options_text_reference,
				&bench486_menu_options_picture_reference);
		case_failure |= Bench486MenuOptionsExpected (&test_case,
				&bench486_menu_options_text_reference,
				&bench486_menu_options_picture_reference);
		case_failure |= Bench486MenuOptionsRun (&test_case,
				M_Options_Draw, &bench486_menu_options_text_candidate,
				&bench486_menu_options_picture_candidate);
		case_failure |= Bench486MenuOptionsExpected (&test_case,
				&bench486_menu_options_text_candidate,
				&bench486_menu_options_picture_candidate);
		case_failure |= Bench486MenuTextDifference (
				&bench486_menu_options_text_reference,
				&bench486_menu_options_text_candidate);
		case_failure |= Bench486MenuPictureDifference (
				&bench486_menu_options_picture_reference,
				&bench486_menu_options_picture_candidate);
		cases++;
		if (case_failure)
		{
			Bench486Printf (
					"menu options C/assembly FAIL profile %u precision %u rounding %u width %u cursor %d time %u video %d code %08x glyphs %u/%u\n",
					profile, bench486_menu_options_precisions[precision_index],
				rounding, width_index, test_case.cursor, test_case.time_index,
				test_case.video_enabled, case_failure,
				bench486_menu_options_text_reference.trace.count,
				bench486_menu_options_text_candidate.trace.count);
			failure = case_failure;
		}
	}

	bench486_menu_text_trace_active = saved_text_active;
	vid.width = saved_width;
	options_cursor = saved_cursor;
	realtime = saved_realtime;
	vid_menudrawfn = saved_video_draw;
	bench486_menu_picture_fake_pic[saved_title_index] = saved_title_width;
	for (i = 0; i < BMO_FLOAT_COUNT; i++)
		cvars[i]->value = saved_values[i];
	Q_memcpy (&bench486_menu_text_trace, &saved_text_trace,
			sizeof(saved_text_trace));
	Q_memcpy (&bench486_menu_picture_trace, &saved_picture_trace,
			sizeof(saved_picture_trace));
	__asm__ __volatile__ ("fldcw %0" : : "m" (saved_control_word));
	if (failure)
		bench486_memory_failures++;
	else
		Bench486Printf (
				"menu options: %u exact C/assembly slider, checkbox, cache, video-option, and x87 cases PASS\n",
				cases);
}

#endif
#endif
