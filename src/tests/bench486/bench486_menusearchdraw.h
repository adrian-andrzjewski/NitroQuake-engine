/* Exact C/assembly parity for the multiplayer search menu draw path. */
/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
#ifndef BENCH486_MENU_SEARCH_DRAW_H
#define BENCH486_MENU_SEARCH_DRAW_H

#if defined(BENCH486) && defined(ASM486_SCREEN_OVERLAYS)

#define BMSD_MULTI_TITLE_PATH 29U
#define BMSD_PRECISION_COUNT 3U
#define BMSD_ROUNDING_COUNT 4U

extern int m_state;
extern qboolean m_entersound;
extern qboolean m_return_onerror;
extern char m_return_reason[32];
extern int m_multiplayer_cursor;
extern int m_net_cursor;
extern int lanConfig_cursor;
extern int lanConfig_port;
extern char lanConfig_portname[6];
extern int slist_cursor;
extern qboolean slist_sorted;
extern qboolean searchComplete;
extern double searchCompleteTime;
extern int hostCacheCount;
extern qboolean slistInProgress;

#define BMSD_CASE_UNCHECKED (-1)

typedef struct bench486_menu_search_draw_case_s
{
	const char *name;
	int in_progress;
	int search_complete;
	unsigned long long realtime_bits;
	unsigned long long completed_bits;
	int host_cache_count;
	int poll_host_cache_count;
	unsigned video_width;
	unsigned picture_width;
	int multiplayer_cursor;
	int net_cursor;
	int lan_cursor;
	int expected_state;
	int expected_search_complete;
	int expected_poll_count;
	int expected_lan_cursor;
	int expected_slist_sorted;
	int expected_slist_cursor;
	int expected_entersound;
} bench486_menu_search_draw_case_t;

typedef struct bench486_menu_search_draw_result_s
{
	bench486_menu_text_trace_t text;
	bench486_menu_picture_trace_t picture;
	unsigned abi;
	unsigned short cw_before;
	unsigned short cw_after;
	int state;
	int key_destination;
	int entersound;
	int return_onerror;
	char return_reason[32];
	int search_complete;
	double search_complete_time;
	int in_progress;
	int host_cache_count;
	int poll_count;
	int lan_cursor;
	int lan_port;
	char lan_portname[6];
	int slist_cursor;
	int slist_sorted;
} bench486_menu_search_draw_result_t;

static const unsigned bench486_menu_search_draw_precisions[
		BMSD_PRECISION_COUNT] = { 0U, 2U, 3U };
static bench486_menu_search_draw_result_t
		bench486_menu_search_draw_reference;
static bench486_menu_search_draw_result_t
		bench486_menu_search_draw_candidate;
static int bench486_menu_search_draw_fixture_active;
static int bench486_menu_search_draw_poll_count;
static int bench486_menu_search_draw_poll_host_count;

void Bench486MenuSearchNetPoll (void)
{
	if (!bench486_menu_search_draw_fixture_active)
	{
		NET_Poll ();
		return;
	}
	bench486_menu_search_draw_poll_count++;
	slistInProgress = false;
	hostCacheCount = bench486_menu_search_draw_poll_host_count;
}

static unsigned short Bench486MenuSearchDrawControlWord (
		unsigned short base, unsigned precision, unsigned rounding)
{
	return (unsigned short)((base & 0xf0ffU) |
			((precision & 3U) << 8) | ((rounding & 3U) << 10));
}

static void Bench486MenuSearchDrawSetDouble (double *target,
		unsigned long long bits)
{
	Q_memcpy (target, &bits, sizeof(bits));
}

static void Bench486MenuSearchDrawPrepare (
		const bench486_menu_search_draw_case_t *test_case)
{
	vid.width = test_case->video_width;
	bench486_menu_picture_fake_pic[BMSD_MULTI_TITLE_PATH * 4U] =
			test_case->picture_width;
	bench486_menu_text_trace_active = 1;
	bench486_menu_search_draw_poll_count = 0;
	bench486_menu_search_draw_poll_host_count =
			test_case->poll_host_cache_count;
	bench486_menu_search_draw_fixture_active = 1;

	m_state = MD_STATE_SEARCH;
	key_dest = key_menu;
	m_entersound = false;
	m_return_onerror = true;
	Q_memset (m_return_reason, 'R', sizeof(m_return_reason));
	searchComplete = test_case->search_complete;
	slistInProgress = test_case->in_progress;
	hostCacheCount = test_case->host_cache_count;
	searchCompleteTime = 0.0;
	Bench486MenuSearchDrawSetDouble (&realtime,
			test_case->realtime_bits);
	Bench486MenuSearchDrawSetDouble (&searchCompleteTime,
			test_case->completed_bits);
	m_multiplayer_cursor = test_case->multiplayer_cursor;
	m_net_cursor = test_case->net_cursor;
	lanConfig_cursor = test_case->lan_cursor;
	lanConfig_port = -1;
	Q_memset (lanConfig_portname, 0x5a, sizeof(lanConfig_portname));
	slist_cursor = 7;
	slist_sorted = true;

	Bench486MenuTextInitTrace ();
	Bench486MenuPictureInitTrace ();
}

static void Bench486MenuSearchDrawCapture (
		bench486_menu_search_draw_result_t *result, unsigned abi,
		unsigned short cw_before, unsigned short cw_after)
{
	Q_memset (result, 0, sizeof(*result));
	Q_memcpy (&result->text, &bench486_menu_text_trace,
			sizeof(result->text));
	Q_memcpy (&result->picture, &bench486_menu_picture_trace,
			sizeof(result->picture));
	result->abi = abi;
	result->cw_before = cw_before;
	result->cw_after = cw_after;
	result->state = m_state;
	result->key_destination = key_dest;
	result->entersound = m_entersound;
	result->return_onerror = m_return_onerror;
	Q_memcpy (result->return_reason, m_return_reason,
			sizeof(result->return_reason));
	result->search_complete = searchComplete;
	Q_memcpy (&result->search_complete_time, &searchCompleteTime,
			sizeof(result->search_complete_time));
	result->in_progress = slistInProgress;
	result->host_cache_count = hostCacheCount;
	result->poll_count = bench486_menu_search_draw_poll_count;
	result->lan_cursor = lanConfig_cursor;
	result->lan_port = lanConfig_port;
	Q_memcpy (result->lan_portname, lanConfig_portname,
			sizeof(result->lan_portname));
	result->slist_cursor = slist_cursor;
	result->slist_sorted = slist_sorted;
}

static unsigned Bench486MenuSearchDrawRun (
		const bench486_menu_search_draw_case_t *test_case,
		unsigned short control_word, void (*function)(void),
		bench486_menu_search_draw_result_t *result)
{
	unsigned abi;
	unsigned short cw_before, cw_after;

	Bench486MenuSearchDrawPrepare (test_case);
	__asm__ __volatile__ ("fldcw %0" : : "m" (control_word));
	cw_before = Bench486MenuTextGetControlWord ();
	abi = Bench486Call_asm486 (function, 0, NULL, NULL);
	cw_after = Bench486MenuTextGetControlWord ();
	bench486_menu_text_trace_active = 0;
	Bench486MenuSearchDrawCapture (result, abi, cw_before, cw_after);
	if ((abi & 0x20U) || cw_before != cw_after || cw_before != control_word)
		return 0x4d534401U;
	return 0;
}

static unsigned Bench486MenuSearchDrawExpected (
		const bench486_menu_search_draw_case_t *test_case,
		const bench486_menu_search_draw_result_t *result)
{
	if ((test_case->expected_state != BMSD_CASE_UNCHECKED &&
			result->state != test_case->expected_state) ||
			result->key_destination != key_menu ||
			result->search_complete != test_case->expected_search_complete ||
			result->poll_count != test_case->expected_poll_count ||
			(test_case->expected_lan_cursor != BMSD_CASE_UNCHECKED &&
			 result->lan_cursor != test_case->expected_lan_cursor) ||
			(test_case->expected_slist_sorted != BMSD_CASE_UNCHECKED &&
			 result->slist_sorted != test_case->expected_slist_sorted) ||
			(test_case->expected_slist_cursor != BMSD_CASE_UNCHECKED &&
			 result->slist_cursor != test_case->expected_slist_cursor) ||
			(test_case->expected_entersound != BMSD_CASE_UNCHECKED &&
			 result->entersound != test_case->expected_entersound) ||
			result->text.overflow || result->picture.overflow ||
			result->picture.cache_error || result->picture.count < 2U ||
			result->text.count < 11U)
		return 0x4d534410U;
	if (result->text.before[0] != 0x4d540000U ||
			result->text.before[1] != 0x4d540001U ||
			result->text.after[0] != 0x4d54f000U ||
			result->text.after[1] != 0x4d54f001U ||
			result->picture.before[0] != 0x4d500000U ||
			result->picture.before[1] != 0x4d500001U ||
			result->picture.after[0] != 0x4d50f000U ||
			result->picture.after[1] != 0x4d50f001U)
		return 0x4d534420U;
	return 0;
}

static unsigned Bench486MenuSearchDrawDifference (
		bench486_menu_search_draw_result_t *reference,
		bench486_menu_search_draw_result_t *candidate)
{
	if (reference->abi != candidate->abi ||
			reference->cw_before != candidate->cw_before ||
			reference->cw_after != candidate->cw_after ||
			reference->state != candidate->state ||
			reference->key_destination != candidate->key_destination ||
			reference->entersound != candidate->entersound ||
			reference->return_onerror != candidate->return_onerror ||
			Q_memcmp (reference->return_reason, candidate->return_reason,
					sizeof(reference->return_reason)) ||
			reference->search_complete != candidate->search_complete ||
			Q_memcmp (&reference->search_complete_time,
					&candidate->search_complete_time,
					sizeof(reference->search_complete_time)) ||
			reference->in_progress != candidate->in_progress ||
			reference->host_cache_count != candidate->host_cache_count ||
			reference->poll_count != candidate->poll_count ||
			reference->lan_cursor != candidate->lan_cursor ||
			reference->lan_port != candidate->lan_port ||
			Q_memcmp (reference->lan_portname, candidate->lan_portname,
					sizeof(reference->lan_portname)) ||
			reference->slist_cursor != candidate->slist_cursor ||
			reference->slist_sorted != candidate->slist_sorted ||
			Q_memcmp (&reference->text, &candidate->text,
					sizeof(reference->text)) ||
			Q_memcmp (&reference->picture, &candidate->picture,
					sizeof(reference->picture)))
		return 0x4d534430U;
	return 0;
}

static void Bench486MenuSearchDrawSave (
		bench486_menu_search_draw_result_t *saved,
		viddef_t *saved_vid, double *saved_realtime,
		int *saved_multiplayer_cursor, int *saved_net_cursor)
{
	Q_memset (saved, 0, sizeof(*saved));
	saved->state = m_state;
	saved->key_destination = key_dest;
	saved->entersound = m_entersound;
	saved->return_onerror = m_return_onerror;
	Q_memcpy (saved->return_reason, m_return_reason,
			sizeof(saved->return_reason));
	saved->search_complete = searchComplete;
	Q_memcpy (&saved->search_complete_time, &searchCompleteTime,
			sizeof(saved->search_complete_time));
	saved->in_progress = slistInProgress;
	saved->host_cache_count = hostCacheCount;
	saved->lan_cursor = lanConfig_cursor;
	saved->lan_port = lanConfig_port;
	Q_memcpy (saved->lan_portname, lanConfig_portname,
			sizeof(saved->lan_portname));
	saved->slist_cursor = slist_cursor;
	saved->slist_sorted = slist_sorted;
	*saved_vid = vid;
	Q_memcpy (saved_realtime, &realtime, sizeof(*saved_realtime));
	*saved_multiplayer_cursor = m_multiplayer_cursor;
	*saved_net_cursor = m_net_cursor;
}

static void Bench486MenuSearchDrawRestore (
		bench486_menu_search_draw_result_t *saved,
		const viddef_t *saved_vid, double *saved_realtime,
		int saved_multiplayer_cursor, int saved_net_cursor)
{
	m_state = saved->state;
	key_dest = (keydest_t)saved->key_destination;
	m_entersound = saved->entersound;
	m_return_onerror = saved->return_onerror;
	Q_memcpy (m_return_reason, saved->return_reason,
			sizeof(saved->return_reason));
	searchComplete = saved->search_complete;
	Q_memcpy (&searchCompleteTime, &saved->search_complete_time,
			sizeof(searchCompleteTime));
	slistInProgress = saved->in_progress;
	hostCacheCount = saved->host_cache_count;
	lanConfig_cursor = saved->lan_cursor;
	lanConfig_port = saved->lan_port;
	Q_memcpy (lanConfig_portname, saved->lan_portname,
			sizeof(lanConfig_portname));
	slist_cursor = saved->slist_cursor;
	slist_sorted = saved->slist_sorted;
	vid = *saved_vid;
	Q_memcpy (&realtime, saved_realtime, sizeof(realtime));
	m_multiplayer_cursor = saved_multiplayer_cursor;
	m_net_cursor = saved_net_cursor;
}

void Bench486MenuSearchDrawCases (void)
{
	static const bench486_menu_search_draw_case_t cases[] = {
		{"poll-pending", 1, 0, 0x4016000000000000ULL,
			0x3ff0000000000000ULL, 0, 0, 320, 95, 0, 3, -1,
			MD_STATE_SEARCH, 0, 1, -1, 1, 7, 0},
		{"poll-discovers-hosts", 1, 0, 0x4016000000000000ULL,
			0x3ff0000000000000ULL, 0, 2, 641, 321, 0, 3, -1,
			MD_STATE_SEARCH, 0, 1, -1, 1, 7, 0},
		{"new-search-no-hosts", 0, 0, 0x4016000000000000ULL,
			0x3ff0000000000000ULL, 0, 0, 320, 96, 0, 3, -1,
			MD_STATE_SEARCH, 1, 0, -1, 1, 7, 0},
		{"recent-search-no-hosts", 0, 1, 0x4016000000000000ULL,
			0x4008000000000000ULL, 0, 0, 1024, 320, 0, 3, -1,
			MD_STATE_SEARCH, 1, 0, -1, 1, 7, 0},
		{"search-results", 0, 0, 0x4016000000000000ULL,
			0x3ff0000000000000ULL, 2, 0, 640, 99, 0, 3, -1,
			MD_STATE_SERVERLIST, 1, 0, -1, 0, 0, 1},
		{"exact-three-second-timeout", 0, 1, 0x401c000000000000ULL,
			0x4010000000000000ULL, 0, 0, 319, 320, 0, 3, -1,
			MD_STATE_LANCONFIG, 1, 0, 2, 1, 7, 1},
		{"past-three-second-timeout", 0, 1, 0x4020000000000000ULL,
			0x4010000000000000ULL, 0, 0, 320, 321, 0, 3, -1,
			MD_STATE_LANCONFIG, 1, 0, 2, 1, 7, 1},
		{"nan-time-delta", 0, 1, 0x7ff8000000000000ULL,
			0x0000000000000000ULL, 0, 0, 320, 80, 0, 3, -1,
			MD_STATE_SEARCH, 1, 0, -1, 1, 7, 0},
		{"assignment-low-bits", 0, 0, 0x3ff0000000000001ULL,
			0x0000000000000000ULL, 0, 0, 319, 321, 0, 3, -1,
			MD_STATE_SEARCH, 1, 0, -1, 1, 7, 0},
		{"threshold-rounding-edge", 0, 1, 0x401bffffffffffffULL,
			0x4010000000000000ULL, 0, 0, 640, 91, 0, 3, -1,
			BMSD_CASE_UNCHECKED, 1, 0, BMSD_CASE_UNCHECKED,
			BMSD_CASE_UNCHECKED, BMSD_CASE_UNCHECKED,
			BMSD_CASE_UNCHECKED}
	};
	bench486_menu_search_draw_result_t saved;
	viddef_t saved_vid;
	double saved_realtime;
	unsigned saved_fake_width;
	int saved_multiplayer_cursor, saved_net_cursor;
	int saved_trace_active, saved_fixture_active;
	bench486_menu_text_trace_t saved_text_trace;
	bench486_menu_picture_trace_t saved_picture_trace;
	unsigned short saved_cw;
	unsigned i, precision, rounding, case_count = 0, failure = 0;
	unsigned short base_cw;

	Bench486MenuSearchDrawSave (&saved, &saved_vid, &saved_realtime,
			&saved_multiplayer_cursor, &saved_net_cursor);
	saved_fake_width = bench486_menu_picture_fake_pic[
			BMSD_MULTI_TITLE_PATH * 4U];
	saved_trace_active = bench486_menu_text_trace_active;
	saved_fixture_active = bench486_menu_search_draw_fixture_active;
	Q_memcpy (&saved_text_trace, &bench486_menu_text_trace,
			sizeof(saved_text_trace));
	Q_memcpy (&saved_picture_trace, &bench486_menu_picture_trace,
			sizeof(saved_picture_trace));
	saved_cw = Bench486MenuTextGetControlWord ();
	base_cw = saved_cw;
	for (i = 0; i < sizeof(cases) / sizeof(cases[0]) && !failure; i++)
	for (precision = 0; precision < BMSD_PRECISION_COUNT && !failure;
			precision++)
	for (rounding = 0; rounding < BMSD_ROUNDING_COUNT && !failure;
			rounding++)
	{
		unsigned short cw = Bench486MenuSearchDrawControlWord (base_cw,
				bench486_menu_search_draw_precisions[precision], rounding);
		unsigned reference_failure, candidate_failure, difference;
		failure |= Bench486MenuSearchDrawRun (&cases[i], cw,
				M_Search_Draw_C, &bench486_menu_search_draw_reference);
		reference_failure = Bench486MenuSearchDrawExpected (&cases[i],
				&bench486_menu_search_draw_reference);
		failure |= Bench486MenuSearchDrawRun (&cases[i], cw,
				M_Search_Draw, &bench486_menu_search_draw_candidate);
		candidate_failure = Bench486MenuSearchDrawExpected (&cases[i],
				&bench486_menu_search_draw_candidate);
		difference = Bench486MenuSearchDrawDifference (
				&bench486_menu_search_draw_reference,
				&bench486_menu_search_draw_candidate);
		case_count++;
		if (reference_failure || candidate_failure || difference || failure)
		{
			Bench486Printf ("menu search draw C/ASM FAIL case %s precision %u rounding %u code %08x/%08x/%08x\n",
					cases[i].name,
					bench486_menu_search_draw_precisions[precision], rounding,
					reference_failure, candidate_failure, difference | failure);
			failure |= reference_failure | candidate_failure | difference;
			break;
		}
	}
	bench486_menu_text_trace_active = 0;
	bench486_menu_search_draw_fixture_active = 0;
	bench486_menu_search_draw_poll_count = 0;
	Bench486MenuSearchDrawRestore (&saved, &saved_vid, &saved_realtime,
			saved_multiplayer_cursor, saved_net_cursor);
	bench486_menu_picture_fake_pic[BMSD_MULTI_TITLE_PATH * 4U] =
			saved_fake_width;
	bench486_menu_text_trace_active = saved_trace_active;
	bench486_menu_search_draw_fixture_active = saved_fixture_active;
	Q_memcpy (&bench486_menu_text_trace, &saved_text_trace,
			sizeof(saved_text_trace));
	Q_memcpy (&bench486_menu_picture_trace, &saved_picture_trace,
			sizeof(saved_picture_trace));
	__asm__ __volatile__ ("fldcw %0" : : "m" (saved_cw));
	if (failure)
		bench486_memory_failures++;
	else
		Bench486Printf ("menu search draw C/ASM parity PASS (%u cases across 3 x87 precisions and 4 rounding modes)\n",
				case_count);
}

#undef BMSD_ROUNDING_COUNT
#undef BMSD_PRECISION_COUNT
#undef BMSD_MULTI_TITLE_PATH

#endif
#endif
