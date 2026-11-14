/* C/assembly parity for the quit dialog and its recursive menu redraw. */
#ifndef BENCH486_MENUQUIT_H
#define BENCH486_MENUQUIT_H

#if defined(BENCH486) && defined(ASM486_SCREEN_OVERLAYS)

#define BMQ_MAIN_TITLE_PATH 11U
#define BMQ_SINGLE_TITLE_PATH 13U
#define BMQ_MULTI_TITLE_PATH 29U
#define BMQ_OPTION_TITLE_PATH 40U
#define BMQ_TITLE_COUNT 4U
#define BMQ_GUARD_WORDS 2U
#define BMQ_MAX_GLYPHS 512U
#define BMQ_MAX_PICTURES 256U
#define BMQ_PREVIOUS_STATES 5U

extern int msgNumber, m_quit_prevstate, m_state;
extern qboolean wasInMenus, m_recursiveDraw, m_entersound;
extern char *quitMessage[];
extern int m_main_cursor, m_singleplayer_cursor, m_multiplayer_cursor;
extern int help_page;
extern double host_time, realtime;
extern void (*vid_menudrawfn)(void);
extern int scr_copyeverything, scr_fullupdate;

typedef struct bench486_menu_quit_case_s
{
	int message;
	int previous_state;
	int was_in_menus;
	unsigned video_width;
	unsigned host_time_index;
	unsigned realtime_index;
	int video_enabled;
	unsigned short control_word;
} bench486_menu_quit_case_t;

typedef struct bench486_menu_quit_result_s
{
	bench486_menu_text_trace_t text;
	bench486_menu_picture_trace_t picture;
	unsigned abi;
	unsigned short cw_before;
	unsigned short cw_after;
	int state;
	int recursive_draw;
	int entersound;
	int copy_everything;
	int full_update;
	int key_destination;
} bench486_menu_quit_result_t;

static const unsigned bench486_menu_quit_widths[4] =
	{ 319U, 320U, 640U, 1024U };
static const unsigned bench486_menu_quit_precisions[3] = { 0U, 2U, 3U };
static const int bench486_menu_quit_previous_states[BMQ_PREVIOUS_STATES] =
	{ MD_STATE_MAIN, MD_STATE_SINGLEPLAYER, MD_STATE_MULTIPLAYER,
	  MD_STATE_OPTIONS, MD_STATE_HELP };
static const double bench486_menu_quit_host_times[4] =
	{ 0.05, 0.15, 0.35, 0.55 };
static const double bench486_menu_quit_realtime_values[4] =
	{ 0.125, 0.375, -0.125, 1.25 };

static bench486_menu_quit_result_t bench486_menu_quit_reference;
static bench486_menu_quit_result_t bench486_menu_quit_candidate;

static unsigned short Bench486MenuQuitControlWord (
		unsigned short base, unsigned precision, unsigned rounding)
{
	return (unsigned short)((base & 0xf0ffU) |
			((precision & 3U) << 8) | ((rounding & 3U) << 10));
}

static void Bench486MenuQuitVideoDrawStub (void)
{
}

static unsigned Bench486MenuQuitRun (
		const bench486_menu_quit_case_t *test_case,
		void (*function)(void), bench486_menu_quit_result_t *result)
{
	unsigned abi;
	unsigned short cw_before, cw_after;

	vid.width = test_case->video_width;
	bench486_menu_dispatch_fixture_active = 0;
	key_dest = (keydest_t)MD_KEY_MENU;
	m_state = MD_STATE_QUIT;
	m_recursiveDraw = false;
	m_entersound = false;
	msgNumber = test_case->message;
	m_quit_prevstate = test_case->previous_state;
	wasInMenus = test_case->was_in_menus;
	vid_menudrawfn = test_case->video_enabled ?
			Bench486MenuQuitVideoDrawStub : NULL;
	m_main_cursor = test_case->message % 5;
	m_singleplayer_cursor = test_case->message % 3;
	m_multiplayer_cursor = test_case->message % 3;
	options_cursor = test_case->message % 13;
	help_page = test_case->message % 6;
	host_time = bench486_menu_quit_host_times[test_case->host_time_index];
	realtime = bench486_menu_quit_realtime_values[test_case->realtime_index];
	scr_copyeverything = 7;
	scr_fullupdate = 9;
	scr_con_current = 0;
	__asm__ __volatile__ ("fldcw %0" : : "m" (test_case->control_word));
	Bench486MenuTextInitTrace ();
	Bench486MenuPictureInitTrace ();
	cw_before = Bench486MenuTextGetControlWord ();
	bench486_menu_text_trace_active = 1;
	abi = Bench486Call_asm486 (function, 0, NULL, NULL);
	bench486_menu_text_trace_active = 0;
	cw_after = Bench486MenuTextGetControlWord ();
	Q_memset (result, 0, sizeof(*result));
	Q_memcpy (&result->text, &bench486_menu_text_trace,
			sizeof(result->text));
	Q_memcpy (&result->picture, &bench486_menu_picture_trace,
			sizeof(result->picture));
	result->abi = abi;
	result->cw_before = cw_before;
	result->cw_after = cw_after;
	result->state = m_state;
	result->recursive_draw = m_recursiveDraw;
	result->entersound = m_entersound;
	result->copy_everything = scr_copyeverything;
	result->full_update = scr_fullupdate;
	result->key_destination = key_dest;
	if ((abi & 0x20U) || cw_before != cw_after)
		return 0x4d510001U;
	return 0;
}

static unsigned Bench486MenuQuitExpected (
		const bench486_menu_quit_case_t *test_case,
		const bench486_menu_quit_result_t *result)
{
	unsigned i;
	unsigned minimum_text = 0;
	unsigned row;
	const char *line;

	for (row = 0; row < 4; row++)
	{
		line = quitMessage[test_case->message * 4 + row];
		while (*line++)
			minimum_text++;
	}
	if (result->text.overflow || result->text.count < minimum_text ||
			result->text.count > BMQ_MAX_GLYPHS)
		return 0x4d510010U;
	for (i = 0; i < BMQ_GUARD_WORDS; i++)
		if (result->text.before[i] != 0x4d540000U + i ||
				result->text.after[i] != 0x4d54f000U + i)
			return 0x4d510020U + i;
	if (result->picture.overflow || result->picture.cache_error ||
			result->picture.count > BMQ_MAX_PICTURES)
		return 0x4d510030U;
	for (i = 0; i < BMQ_GUARD_WORDS; i++)
		if (result->picture.before[i] != 0x4d500000U + i ||
				result->picture.after[i] != 0x4d50f000U + i)
			return 0x4d510040U + i;
	if (result->state != MD_STATE_QUIT || result->recursive_draw ||
			result->entersound || result->key_destination != MD_KEY_MENU)
		return 0x4d510050U;
	return 0;
}

static unsigned Bench486MenuQuitDifference (
		const bench486_menu_quit_result_t *reference,
		const bench486_menu_quit_result_t *candidate)
{
	if (reference->abi != candidate->abi ||
			reference->cw_before != candidate->cw_before ||
			reference->cw_after != candidate->cw_after ||
			reference->state != candidate->state ||
			reference->recursive_draw != candidate->recursive_draw ||
			reference->entersound != candidate->entersound ||
			reference->copy_everything != candidate->copy_everything ||
			reference->full_update != candidate->full_update ||
			reference->key_destination != candidate->key_destination)
		return 0x4d510060U;
	if (Q_memcmp ((void *)&reference->text, (void *)&candidate->text,
			sizeof(reference->text)) ||
			Q_memcmp ((void *)&reference->picture,
					(void *)&candidate->picture, sizeof(reference->picture)))
		return 0x4d510061U;
	return 0;
}

void Bench486MenuQuitCases (void)
{
	static const unsigned rounding_modes[4] = { 0U, 1U, 2U, 3U };
	static const int saved_title_path[BMQ_TITLE_COUNT] =
	{
		(int)BMQ_MAIN_TITLE_PATH, (int)BMQ_SINGLE_TITLE_PATH,
		(int)BMQ_MULTI_TITLE_PATH, (int)BMQ_OPTION_TITLE_PATH
	};
	float saved_console_current = scr_con_current;
	bench486_menu_text_trace_t saved_text_trace;
	bench486_menu_picture_trace_t saved_picture_trace;
	unsigned saved_title_widths[BMQ_TITLE_COUNT];
	unsigned saved_width = vid.width;
	int saved_state = m_state;
	int saved_cursor_main = m_main_cursor;
	int saved_cursor_single = m_singleplayer_cursor;
	int saved_cursor_multi = m_multiplayer_cursor;
	int saved_cursor_options = options_cursor;
	int saved_help_page = help_page;
	int saved_recursive = m_recursiveDraw;
	int saved_entersound = m_entersound;
	int saved_message = msgNumber;
	int saved_previous_state = m_quit_prevstate;
	int saved_was_in_menus = wasInMenus;
	int saved_copy_everything = scr_copyeverything;
	int saved_full_update = scr_fullupdate;
	int saved_text_active = bench486_menu_text_trace_active;
	int saved_dispatch_active = bench486_menu_dispatch_fixture_active;
	keydest_t saved_key_destination = key_dest;
	void (*saved_video_draw)(void) = vid_menudrawfn;
	double saved_host_time = host_time;
	double saved_realtime = realtime;
	unsigned short saved_control_word = Bench486MenuTextGetControlWord ();
	unsigned profile, width_index, precision_index, rounding;
	unsigned cases = 0, failure = 0, i;
	bench486_menu_quit_case_t test_case;

	Q_memcpy (&saved_text_trace, &bench486_menu_text_trace,
			sizeof(saved_text_trace));
	Q_memcpy (&saved_picture_trace, &bench486_menu_picture_trace,
			sizeof(saved_picture_trace));
	for (i = 0; i < BMQ_TITLE_COUNT; i++)
	{
		unsigned index = (unsigned)saved_title_path[i] * 4U;
		saved_title_widths[i] = bench486_menu_picture_fake_pic[index];
		bench486_menu_picture_fake_pic[index] =
				i == 1 ? 124U : i == 2 ? 91U : i == 3 ? 101U : 96U;
	}

	/* Every message, width, precision, and rounding mode without recursion. */
	for (profile = 0; profile < 8 && !failure; profile++)
	for (width_index = 0; width_index < 4 && !failure; width_index++)
	for (precision_index = 0; precision_index < 3 && !failure;
			precision_index++)
	for (rounding = 0; rounding < 4 && !failure; rounding++)
	{
		unsigned case_failure;
		test_case.message = (int)profile;
		test_case.previous_state = MD_STATE_MAIN;
		test_case.was_in_menus = 0;
		test_case.video_width = bench486_menu_quit_widths[width_index];
		test_case.host_time_index = (profile + width_index) % 4U;
		test_case.realtime_index = (profile + rounding) % 4U;
		test_case.video_enabled = (int)((profile + width_index) & 1U);
		test_case.control_word = Bench486MenuQuitControlWord (
				saved_control_word,
				bench486_menu_quit_precisions[precision_index],
				rounding_modes[rounding]);
		case_failure = Bench486MenuQuitRun (&test_case, M_Quit_Draw_C,
				&bench486_menu_quit_reference);
		case_failure |= Bench486MenuQuitExpected (&test_case,
				&bench486_menu_quit_reference);
		case_failure |= Bench486MenuQuitRun (&test_case, M_Quit_Draw,
				&bench486_menu_quit_candidate);
		case_failure |= Bench486MenuQuitExpected (&test_case,
				&bench486_menu_quit_candidate);
		case_failure |= Bench486MenuQuitDifference (
				&bench486_menu_quit_reference,
				&bench486_menu_quit_candidate);
		cases++;
		if (case_failure)
		{
			Bench486Printf (
					"menu quit C/assembly FAIL message %u width %u precision %u rounding %u code %08x glyphs %u/%u pictures %u/%u\n",
					profile, width_index,
				bench486_menu_quit_precisions[precision_index], rounding,
				case_failure, bench486_menu_quit_reference.text.count,
				bench486_menu_quit_candidate.text.count,
				bench486_menu_quit_reference.picture.count,
				bench486_menu_quit_candidate.picture.count);
			failure = case_failure;
		}
	}

	/* Exercise the recursive redraw path through five real prior menus. */
	for (profile = 0; profile < BMQ_PREVIOUS_STATES && !failure; profile++)
	for (width_index = 0; width_index < 4 && !failure; width_index++)
	for (precision_index = 0; precision_index < 3 && !failure;
			precision_index++)
	for (rounding = 0; rounding < 4 && !failure; rounding++)
	{
		unsigned case_failure;
		test_case.message = (int)((profile + width_index +
				precision_index + rounding) & 7U);
		test_case.previous_state = bench486_menu_quit_previous_states[profile];
		test_case.was_in_menus = 1;
		test_case.video_width = bench486_menu_quit_widths[width_index];
		test_case.host_time_index = (profile + width_index + rounding) % 4U;
		test_case.realtime_index = (profile + precision_index + rounding) % 4U;
		test_case.video_enabled = (int)((profile + width_index + rounding) & 1U);
		test_case.control_word = Bench486MenuQuitControlWord (
				saved_control_word,
				bench486_menu_quit_precisions[precision_index],
				rounding_modes[rounding]);
		case_failure = Bench486MenuQuitRun (&test_case, M_Quit_Draw_C,
				&bench486_menu_quit_reference);
		case_failure |= Bench486MenuQuitExpected (&test_case,
				&bench486_menu_quit_reference);
		case_failure |= Bench486MenuQuitRun (&test_case, M_Quit_Draw,
				&bench486_menu_quit_candidate);
		case_failure |= Bench486MenuQuitExpected (&test_case,
				&bench486_menu_quit_candidate);
		case_failure |= Bench486MenuQuitDifference (
				&bench486_menu_quit_reference,
				&bench486_menu_quit_candidate);
		cases++;
		if (case_failure)
		{
			Bench486Printf (
					"menu quit recursive C/assembly FAIL state %u message %u width %u precision %u rounding %u code %08x glyphs %u/%u pictures %u/%u\n",
					profile, test_case.message, width_index,
				bench486_menu_quit_precisions[precision_index], rounding,
				case_failure, bench486_menu_quit_reference.text.count,
				bench486_menu_quit_candidate.text.count,
				bench486_menu_quit_reference.picture.count,
				bench486_menu_quit_candidate.picture.count);
			failure = case_failure;
		}
	}

	bench486_menu_text_trace_active = saved_text_active;
	bench486_menu_dispatch_fixture_active = saved_dispatch_active;
	vid.width = saved_width;
	m_state = saved_state;
	m_main_cursor = saved_cursor_main;
	m_singleplayer_cursor = saved_cursor_single;
	m_multiplayer_cursor = saved_cursor_multi;
	options_cursor = saved_cursor_options;
	help_page = saved_help_page;
	m_recursiveDraw = saved_recursive;
	m_entersound = saved_entersound;
	msgNumber = saved_message;
	m_quit_prevstate = saved_previous_state;
	wasInMenus = saved_was_in_menus;
	scr_copyeverything = saved_copy_everything;
	scr_fullupdate = saved_full_update;
	key_dest = saved_key_destination;
	vid_menudrawfn = saved_video_draw;
	host_time = saved_host_time;
	realtime = saved_realtime;
	scr_con_current = saved_console_current;
	for (i = 0; i < BMQ_TITLE_COUNT; i++)
		bench486_menu_picture_fake_pic[
				(unsigned)saved_title_path[i] * 4U] = saved_title_widths[i];
	Q_memcpy (&bench486_menu_text_trace, &saved_text_trace,
			sizeof(saved_text_trace));
	Q_memcpy (&bench486_menu_picture_trace, &saved_picture_trace,
			sizeof(saved_picture_trace));
	__asm__ __volatile__ ("fldcw %0" : : "m" (saved_control_word));
	if (failure)
		bench486_memory_failures++;
	else
		Bench486Printf (
				"menu quit: %u exact C/assembly messages, recursive redraw, picture, and x87 cases PASS\n",
				cases);
}

#endif
#endif
