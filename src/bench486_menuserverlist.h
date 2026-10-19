/* C/assembly parity for server-cache sorting and server-list menu drawing. */
#ifndef BENCH486_MENU_SERVERLIST_H
#define BENCH486_MENU_SERVERLIST_H

#if defined(BENCH486) && defined(ASM486_SCREEN_OVERLAYS)

#include "asm_menutext.h"

#define BMSL_MULTI_TITLE_PATH 29U
#define BMSL_PATTERN_COUNT 4U
#define BMSL_GUARD_WORDS 2U
#define BMSL_MAX_GLYPHS 1024U
#define BMSL_EVENT_PIC 2
#define BMSL_EVENT_CACHEPIC 4

extern unsigned Bench486Call_asm486 (void (*function)(void), unsigned words,
		const unsigned *arguments, float *float_return);
extern int hostCacheCount;
extern hostcache_t hostcache[HOSTCACHESIZE];
extern int slist_cursor;
extern qboolean slist_sorted;
extern double realtime;
extern char m_return_reason[32];

typedef struct bench486_menu_serverlist_case_s
{
	unsigned video_width;
	unsigned title_width;
	int host_cache_count;
	int sorted;
	int cursor;
	unsigned pattern;
	unsigned long long realtime_bits;
	unsigned short control_word;
} bench486_menu_serverlist_case_t;

typedef struct bench486_menu_serverlist_result_s
{
	bench486_menu_text_result_t text;
	bench486_menu_picture_result_t picture;
	hostcache_t cache[HOSTCACHESIZE];
	unsigned long long realtime_bits;
	char return_reason[32];
	int host_cache_count;
	int sorted;
	int cursor;
	unsigned video_width;
	unsigned title_width;
} bench486_menu_serverlist_result_t;

static const char *bench486_menu_serverlist_names[BMSL_PATTERN_COUNT][
		HOSTCACHESIZE] =
{
	{ "server-h", "server-g", "server-f", "server-e", "server-d",
		"server-c", "server-b", "server-a" },
	{ "delta", "alpha", "hotel", "bravo", "golf", "charlie",
		"foxtrot", "echo" },
	{ "same", "alpha", "same", "beta", "alpha", "same", "beta",
		"alpha" },
	{ "\x80" "north", "\x7f" "south", "abcdefghijklmno", "short",
		"\x80" "east", "abcdefghijklmnn", "middle", "\x7f" "west" }
};

static const char *bench486_menu_serverlist_maps[HOSTCACHESIZE] =
{
	"start", "e1m1", "e2m2", "dm2", "base", "castle", "hip1m1",
	"end"
};

static const unsigned bench486_menu_serverlist_widths[4] =
	{ 319U, 320U, 640U, 1024U };
static const unsigned bench486_menu_serverlist_title_widths[4] =
	{ 0U, 95U, 320U, 321U };
static const int bench486_menu_serverlist_counts[5] = { 0, 1, 2, 5, 8 };
static const int bench486_menu_serverlist_cursors[4] = { 0, -1, 3, 8 };
static const unsigned long long bench486_menu_serverlist_times[4] =
{
	0x3fc0000000000000ULL, /* 0.125 */
	0x3fd8000000000000ULL, /* 0.375 */
	0x3fcfffffffffffffULL, /* just below 0.25 */
	0xbfc0000000000000ULL  /* -0.125 */
};
static const unsigned bench486_menu_serverlist_precisions[3] =
	{ 0U, 2U, 3U };

static bench486_menu_serverlist_result_t
		bench486_menu_serverlist_reference;
static bench486_menu_serverlist_result_t
		bench486_menu_serverlist_candidate;
static bench486_menu_text_trace_t bench486_menu_serverlist_expected_text;
static bench486_menu_picture_trace_t
		bench486_menu_serverlist_expected_picture;
static viddef_t bench486_menu_serverlist_saved_vid;
static hostcache_t bench486_menu_serverlist_saved_cache[HOSTCACHESIZE];
static bench486_menu_text_trace_t bench486_menu_serverlist_saved_text_trace;
static bench486_menu_picture_trace_t
		bench486_menu_serverlist_saved_picture_trace;
static double bench486_menu_serverlist_saved_realtime;
static char bench486_menu_serverlist_saved_return_reason[32];
static unsigned bench486_menu_serverlist_saved_title_width;
static unsigned bench486_menu_serverlist_saved_video_width;
static unsigned short bench486_menu_serverlist_saved_control_word;
static int bench486_menu_serverlist_saved_count;
static int bench486_menu_serverlist_saved_sorted;
static int bench486_menu_serverlist_saved_cursor;
static int bench486_menu_serverlist_saved_trace_active;

static unsigned short Bench486MenuServerListControlWord (
		unsigned short base, unsigned precision, unsigned rounding)
{
	return (unsigned short)((base & 0xf0ffU) |
			((precision & 3U) << 8) | ((rounding & 3U) << 10));
}

static void Bench486MenuServerListSetDouble (double *target,
		unsigned long long bits)
{
	Q_memcpy (target, &bits, sizeof(bits));
}

static void Bench486MenuServerListSeed (unsigned pattern)
{
	static const unsigned users[HOSTCACHESIZE] =
		{ 0U, 9U, 10U, 99U, 100U, 255U, 7U, 42U };
	unsigned i, j;

	pattern %= BMSL_PATTERN_COUNT;
	for (i = 0; i < HOSTCACHESIZE; i++)
	{
		Q_memset (&hostcache[i], (int)(0xa0U + i), sizeof(hostcache[i]));
		Q_strcpy (hostcache[i].name, (char *)
				bench486_menu_serverlist_names[pattern][i]);
		Q_strcpy (hostcache[i].map, (char *)
				bench486_menu_serverlist_maps[(i + pattern) & 7U]);
		Q_strcpy (hostcache[i].cname, "server-address");
		hostcache[i].users = (int)users[(i + pattern) & 7U];
		hostcache[i].maxusers = (int)((i + pattern) % 3U);
		hostcache[i].driver = 0x1000 + (int)(pattern * 16U + i);
		hostcache[i].ldriver = 0x2000 + (int)(pattern * 16U + i);
		hostcache[i].addr.sa_family = (short)(pattern * 16U + i);
		for (j = 0; j < sizeof(hostcache[i].addr.sa_data); j++)
			hostcache[i].addr.sa_data[j] =
					(unsigned char)(pattern * 17U + i * 3U + j);
	}

	if (pattern == 0U)
	{
		for (i = 0; i < HOSTCACHESIZE; i++)
			hostcache[i].maxusers = 0;
	}
	else if (pattern == 1U)
	{
		for (i = 0; i < HOSTCACHESIZE; i++)
			hostcache[i].maxusers = 8 + (int)i;
	}
	else if (pattern == 2U)
	{
		for (i = 0; i < HOSTCACHESIZE; i++)
			hostcache[i].maxusers = (int)(i % 2U);
	}
	else
	{
		hostcache[0].users = -1;
		hostcache[0].maxusers = 1;
		hostcache[1].users = 9;
		hostcache[1].maxusers = 0;
		hostcache[2].users = 255;
		hostcache[2].maxusers = 100;
	}
}

static void Bench486MenuServerListPrepare (
		const bench486_menu_serverlist_case_t *test_case)
{
	unsigned i;

	vid.width = test_case->video_width;
	bench486_menu_picture_fake_pic[BMSL_MULTI_TITLE_PATH * 4U] =
			test_case->title_width;
	hostCacheCount = test_case->host_cache_count;
	slist_sorted = test_case->sorted;
	slist_cursor = test_case->cursor;
	Bench486MenuServerListSeed (test_case->pattern);
	Bench486MenuServerListSetDouble (&realtime, test_case->realtime_bits);
	Q_memset (m_return_reason, 0, sizeof(m_return_reason));
	if (test_case->pattern == 1U)
		Q_strcpy (m_return_reason, "No Quake servers found");
	else if (test_case->pattern == 2U)
		Q_strcpy (m_return_reason, "Server list changed");
	else if (test_case->pattern == 3U)
	{
		for (i = 0; i < sizeof(m_return_reason) - 1U; i++)
			m_return_reason[i] = (char)(0x80U + i);
	}
	__asm__ __volatile__ ("fldcw %0" : : "m" (test_case->control_word));
}

static void Bench486MenuServerListCapture (
		bench486_menu_serverlist_result_t *result, unsigned abi,
		unsigned short cw_before, unsigned short cw_after)
{
	unsigned long long realtime_bits;

	Bench486MenuTextCapture (&result->text, abi, cw_before, cw_after);
	Bench486MenuPictureCapture (&result->picture, abi, cw_before, cw_after);
	Q_memcpy (result->cache, hostcache, sizeof(result->cache));
	Q_memcpy (&realtime_bits, &realtime, sizeof(realtime_bits));
	result->realtime_bits = realtime_bits;
	Q_memcpy (result->return_reason, m_return_reason,
			sizeof(result->return_reason));
	result->host_cache_count = hostCacheCount;
	result->sorted = slist_sorted;
	result->cursor = slist_cursor;
	result->video_width = vid.width;
	result->title_width = bench486_menu_picture_fake_pic[
			BMSL_MULTI_TITLE_PATH * 4U];
}

static unsigned Bench486MenuServerListRun (
		const bench486_menu_serverlist_case_t *test_case,
		void (*function)(void), bench486_menu_serverlist_result_t *result)
{
	unsigned abi;
	unsigned short cw_before, cw_after;

	Bench486MenuServerListPrepare (test_case);
	Bench486MenuTextInitTrace ();
	Bench486MenuPictureInitTrace ();
	cw_before = Bench486MenuTextGetControlWord ();
	bench486_menu_text_trace_active = 1;
	abi = Bench486Call_asm486 (function, 0U, NULL, NULL);
	bench486_menu_text_trace_active = 0;
	cw_after = Bench486MenuTextGetControlWord ();
	Bench486MenuServerListCapture (result, abi, cw_before, cw_after);
	if ((abi & 0x20U) || cw_before != cw_after)
		return 0x4d534c01U;
	return 0;
}

static void Bench486MenuServerListAppendString (
		bench486_menu_text_trace_t *expected, unsigned video_width,
		int x, int y, const char *string, int white)
{
	unsigned offset = (video_width - 320U) >> 1;
	int actual_x = (int)((unsigned)x + offset);

	while (*string)
	{
		bench486_menu_text_glyph_t *glyph;
		if (expected->count >= BMSL_MAX_GLYPHS)
		{
			expected->overflow = 1;
			return;
		}
		glyph = &expected->glyphs[expected->count++];
		glyph->x = actual_x;
		glyph->y = y;
		glyph->num = white ? (int)(signed char)*string :
				(int)(signed char)*string + 128;
		actual_x += 8;
		string++;
	}
}

static unsigned Bench486MenuServerListExpectedText (
		const bench486_menu_serverlist_case_t *test_case,
		const bench486_menu_serverlist_result_t *result)
{
	bench486_menu_text_trace_t expected;
	double test_realtime;
	unsigned long long realtime_bits = result->realtime_bits;
	unsigned i;
	int phase;
	char row[64];

	Q_memset (&expected, 0, sizeof(expected));
	for (i = 0; i < BMSL_GUARD_WORDS; i++)
	{
		expected.before[i] = 0x4d540000U + i;
		expected.after[i] = 0x4d54f000U + i;
	}
	Q_memcpy (&test_realtime, &realtime_bits, sizeof(test_realtime));
	for (i = 0; i < (unsigned)result->host_cache_count; i++)
	{
		const hostcache_t *host = &result->cache[i];
		if (host->maxusers)
			sprintf (row, "%-15.15s %-15.15s %2u/%2u\n", host->name,
					host->map, (unsigned)host->users,
					(unsigned)host->maxusers);
		else
			sprintf (row, "%-15.15s %-15.15s\n", host->name, host->map);
		Bench486MenuServerListAppendString (&expected,
				result->video_width, 16, 32 + 8 * (int)i, row, 0);
	}
	phase = ((int)(test_realtime * 4.0)) & 1;
	if (expected.count >= BMSL_MAX_GLYPHS)
		expected.overflow = 1;
	else
	{
		bench486_menu_text_glyph_t *glyph =
				&expected.glyphs[expected.count++];
		unsigned offset = (result->video_width - 320U) >> 1;
		glyph->x = (int)offset;
		glyph->y = 32 + test_case->cursor * 8;
		glyph->num = 12 + phase;
	}
	if (result->return_reason[0])
		Bench486MenuServerListAppendString (&expected,
				result->video_width, 16, 148,
				result->return_reason, 1);
	if (result->text.trace.overflow ||
			Q_memcmp ((void *)&expected, (void *)&result->text.trace,
					sizeof(expected)))
		return 0x4d534c10U;
	return 0;
}

static unsigned Bench486MenuServerListExpectedPicture (
		const bench486_menu_serverlist_case_t *test_case,
		const bench486_menu_serverlist_result_t *result)
{
	bench486_menu_picture_trace_t expected;
	bench486_menu_picture_event_t *event;
	unsigned offset = (test_case->video_width - 320U) >> 1;
	int base_x = (320 - (int)test_case->title_width) / 2;
	qpic_t *title = (qpic_t *)(bench486_menu_picture_fake_pic +
			BMSL_MULTI_TITLE_PATH * 4U);
	unsigned i;

	Q_memset (&expected, 0, sizeof(expected));
	for (i = 0; i < BMSL_GUARD_WORDS; i++)
	{
		expected.before[i] = 0x4d500000U + i;
		expected.after[i] = 0x4d50f000U + i;
	}
	expected.count = 2U;
	expected.events[0].kind = BMSL_EVENT_CACHEPIC;
	expected.events[0].pic = title;
	event = &expected.events[1];
	event->kind = BMSL_EVENT_PIC;
	event->x = (int)((unsigned)base_x + offset);
	event->y = 4;
	event->pic = title;
	if (result->picture.trace.overflow ||
			result->picture.trace.cache_error ||
			Q_memcmp ((void *)&expected, (void *)&result->picture.trace,
					sizeof(expected)))
		return 0x4d534c20U;
	return 0;
}

static unsigned Bench486MenuServerListDifference (
		const bench486_menu_serverlist_result_t *reference,
		const bench486_menu_serverlist_result_t *candidate)
{
	if (reference->host_cache_count != candidate->host_cache_count ||
			reference->sorted != candidate->sorted ||
			reference->cursor != candidate->cursor ||
			reference->video_width != candidate->video_width ||
			reference->title_width != candidate->title_width ||
			reference->realtime_bits != candidate->realtime_bits ||
			Q_memcmp ((void *)reference->return_reason,
					(void *)candidate->return_reason,
					sizeof(reference->return_reason)) ||
			Q_memcmp ((void *)reference->cache, (void *)candidate->cache,
					sizeof(reference->cache)))
		return 0x4d534c30U;
	if (Bench486MenuTextDifference (&reference->text, &candidate->text) ||
			Bench486MenuPictureDifference (&reference->picture,
					&candidate->picture))
		return 0x4d534c31U;
	return 0;
}

static void Bench486MenuServerListSaveState (void)
{
	Q_memcpy (bench486_menu_serverlist_saved_cache, hostcache,
			sizeof(bench486_menu_serverlist_saved_cache));
	Q_memcpy (&bench486_menu_serverlist_saved_vid, &vid,
			sizeof(bench486_menu_serverlist_saved_vid));
	Q_memcpy (&bench486_menu_serverlist_saved_realtime, &realtime,
			sizeof(realtime));
	Q_memcpy (bench486_menu_serverlist_saved_return_reason, m_return_reason,
			sizeof(bench486_menu_serverlist_saved_return_reason));
	Q_memcpy (&bench486_menu_serverlist_saved_text_trace,
			&bench486_menu_text_trace,
			sizeof(bench486_menu_serverlist_saved_text_trace));
	Q_memcpy (&bench486_menu_serverlist_saved_picture_trace,
			&bench486_menu_picture_trace,
			sizeof(bench486_menu_serverlist_saved_picture_trace));
	bench486_menu_serverlist_saved_video_width = vid.width;
	bench486_menu_serverlist_saved_title_width =
			bench486_menu_picture_fake_pic[BMSL_MULTI_TITLE_PATH * 4U];
	bench486_menu_serverlist_saved_count = hostCacheCount;
	bench486_menu_serverlist_saved_sorted = slist_sorted;
	bench486_menu_serverlist_saved_cursor = slist_cursor;
	bench486_menu_serverlist_saved_control_word =
			Bench486MenuTextGetControlWord ();
	bench486_menu_serverlist_saved_trace_active =
			bench486_menu_text_trace_active;
}

static void Bench486MenuServerListRestoreState (void)
{
	Q_memcpy (hostcache, bench486_menu_serverlist_saved_cache,
			sizeof(bench486_menu_serverlist_saved_cache));
	Q_memcpy (&vid, &bench486_menu_serverlist_saved_vid, sizeof(vid));
	Q_memcpy (&realtime, &bench486_menu_serverlist_saved_realtime,
			sizeof(realtime));
	Q_memcpy (m_return_reason, bench486_menu_serverlist_saved_return_reason,
			sizeof(m_return_reason));
	Q_memcpy (&bench486_menu_text_trace,
			&bench486_menu_serverlist_saved_text_trace,
			sizeof(bench486_menu_text_trace));
	Q_memcpy (&bench486_menu_picture_trace,
			&bench486_menu_serverlist_saved_picture_trace,
			sizeof(bench486_menu_picture_trace));
	bench486_menu_picture_fake_pic[BMSL_MULTI_TITLE_PATH * 4U] =
			bench486_menu_serverlist_saved_title_width;
	vid.width = bench486_menu_serverlist_saved_video_width;
	hostCacheCount = bench486_menu_serverlist_saved_count;
	slist_sorted = bench486_menu_serverlist_saved_sorted;
	slist_cursor = bench486_menu_serverlist_saved_cursor;
	bench486_menu_text_trace_active =
			bench486_menu_serverlist_saved_trace_active;
	__asm__ __volatile__ ("fldcw %0" : :
			"m" (bench486_menu_serverlist_saved_control_word));
}

void Bench486MenuServerListCases (void)
{
	bench486_menu_serverlist_case_t test_case;
	unsigned width_index, count_index, sorted_index, pattern;
	unsigned rounding, precision_index, total = 0, failure = 0;

	Bench486MenuServerListSaveState ();
	for (width_index = 0; width_index < 4U && !failure; width_index++)
	for (count_index = 0; count_index < 5U && !failure; count_index++)
	for (sorted_index = 0; sorted_index < 2U && !failure; sorted_index++)
	for (pattern = 0; pattern < BMSL_PATTERN_COUNT && !failure; pattern++)
	for (rounding = 0; rounding < 4U && !failure; rounding++)
	for (precision_index = 0; precision_index < 3U && !failure;
			precision_index++)
	{
		unsigned text_c, text_asm, picture_c, picture_asm;
		unsigned text_diff, picture_diff;
		unsigned scenario = width_index + count_index + pattern +
				rounding + precision_index;
		unsigned short saved_cw = Bench486MenuTextGetControlWord ();

		test_case.video_width = bench486_menu_serverlist_widths[width_index];
		test_case.title_width = bench486_menu_serverlist_title_widths[
				scenario & 3U];
		test_case.host_cache_count =
				bench486_menu_serverlist_counts[count_index];
		test_case.sorted = (int)sorted_index;
		test_case.cursor = bench486_menu_serverlist_cursors[pattern];
		test_case.pattern = pattern;
		test_case.realtime_bits =
				bench486_menu_serverlist_times[scenario & 3U];
		test_case.control_word = Bench486MenuServerListControlWord (
				saved_cw, bench486_menu_serverlist_precisions[precision_index],
				rounding);
		total++;
		failure = Bench486MenuServerListRun (&test_case,
				M_ServerList_Draw_C, &bench486_menu_serverlist_reference);
		failure |= Bench486MenuServerListRun (&test_case,
				M_ServerList_Draw, &bench486_menu_serverlist_candidate);
		text_c = Bench486MenuServerListExpectedText (&test_case,
				&bench486_menu_serverlist_reference);
		text_asm = Bench486MenuServerListExpectedText (&test_case,
				&bench486_menu_serverlist_candidate);
		picture_c = Bench486MenuServerListExpectedPicture (&test_case,
				&bench486_menu_serverlist_reference);
		picture_asm = Bench486MenuServerListExpectedPicture (&test_case,
				&bench486_menu_serverlist_candidate);
		text_diff = Bench486MenuTextDifference (
				&bench486_menu_serverlist_reference.text,
				&bench486_menu_serverlist_candidate.text);
		picture_diff = Bench486MenuPictureDifference (
				&bench486_menu_serverlist_reference.picture,
				&bench486_menu_serverlist_candidate.picture);
		failure |= text_c | text_asm | picture_c | picture_asm |
				text_diff | picture_diff |
				Bench486MenuServerListDifference (
						&bench486_menu_serverlist_reference,
						&bench486_menu_serverlist_candidate);
		if (failure)
			Bench486Printf ("server-list draw FAIL width %u count %u sorted %u pattern %u rounding %u precision %u code %08x checks %08x/%08x/%08x/%08x/%08x/%08x text %u/%u picture %u/%u\n",
					width_index, count_index, sorted_index, pattern,
					rounding, precision_index, failure, text_c, text_asm,
					picture_c, picture_asm, text_diff, picture_diff,
					bench486_menu_serverlist_reference.text.trace.count,
					bench486_menu_serverlist_candidate.text.trace.count,
					bench486_menu_serverlist_reference.picture.trace.count,
					bench486_menu_serverlist_candidate.picture.trace.count);
	}

	Bench486MenuServerListRestoreState ();
	if (failure)
		bench486_memory_failures++;
	else
		Bench486Printf ("server-list menu drawing: %u exact C/assembly sort, text, picture, x87 and ABI cases PASS\n",
				total);
}

#endif

#endif
