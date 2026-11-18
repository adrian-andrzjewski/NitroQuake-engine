/* Direct C/assembly parity for the multiplayer game-options renderer. */
/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
#ifndef BENCH486_MENUGAMEOPTIONS_H
#define BENCH486_MENUGAMEOPTIONS_H

#if defined(BENCH486) && defined(ASM486_SCREEN_OVERLAYS)

#include "client/asm_menutext.h"
#include "tests/bench486/bench486_menutext.h"

#define BMG_MAX_CASES 8
#define BMG_TEXT_GUARD_WORDS 2
#define BMG_PICTURE_GUARD_WORDS 2

extern qboolean m_serverInfoMessage;
extern int maxplayers, startepisode, startlevel, gameoptions_cursor;
extern int gameoptions_cursor_table[];
extern double m_serverInfoMessageTime;
extern void M_GameOptions_Draw (void);
extern void M_GameOptions_Draw_C (void);
extern int bench486_menu_text_trace_active;

typedef struct bench486_menu_gameoptions_case_s
{
	const char *name;
	unsigned video_width;
	int title_width;
	int maxplayers;
	float coop, teamplay, skill, fraglimit, timelimit;
	int hipnotic, rogue, episode, level, cursor;
	double realtime, server_info_time;
	int server_info_message;
} bench486_menu_gameoptions_case_t;

typedef struct bench486_menu_gameoptions_result_s
{
	bench486_menu_text_trace_t text;
	bench486_menu_picture_trace_t picture;
	int server_info_message;
	double server_info_time;
	unsigned abi;
	unsigned short cw_before, cw_after;
} bench486_menu_gameoptions_result_t;

static const bench486_menu_gameoptions_case_t
		bench486_menu_gameoptions_cases[BMG_MAX_CASES] =
{
	{ "base-zero-limits", 320, 144, 8, -0.0f, 0.0f, 0.0f, 0.0f, 0.0f,
		0, 0, 0, 0, 0, 0.05, 0.0, 0 },
	{ "base-fractional-limits", 640, 400, 32, 0.0f, 2.9f, 1.0f,
		17.9f, 12.8f, 0, 0, 2, 3, 4, 0.24999999, 0.0, 0 },
	{ "base-negative-limits", 319, 0, 4, 1.0f, 1.0f, 2.0f,
		-17.9f, -0.9f, 0, 0, 4, 2, 8, 0.25, 0.0, 0 },
	{ "hipnotic-episode", 1024, 320, 16, 1.0f, 4.0f, 2.0f,
		0.0f, 30.0f, 1, 0, 3, 1, 2, 0.25000001, 0.0, 0 },
	{ "rogue-team-ctf", 640, 160, 6, 0.0f, 6.0f, 3.0f,
		100.75f, 59.8f, 0, 1, 2, 6, 6, -0.5, 0.0, 0 },
	{ "rogue-final-episode", 320, 401, 64, 0.0f, 5.0f, 2.5f,
		1.9f, 1.9f, 0, 1, 3, 0, 7, 4.99999, 0.0, 1 },
	{ "server-info-visible-rogue-tag", 1024, 123, 12, 0.0f, 3.0f, 1.0f,
		0.0f, 0.0f, 0, 1, 1, 2, 3, 4.999, 0.0, 1 },
	{ "server-info-expires-at-five", 319, 255, 8, 0.0f, 0.0f, 1.0f,
		0.0f, 0.0f, 1, 1, 5, 0, 5, 5.0, 0.0, 1 }
};

static bench486_menu_gameoptions_result_t
		bench486_menu_gameoptions_reference;
static bench486_menu_gameoptions_result_t
		bench486_menu_gameoptions_candidate;

static unsigned short Bench486MenuGameOptionsControlWord (
		unsigned short base, unsigned precision, unsigned rounding)
{
	return (unsigned short)((base & 0xf0ffU) |
			((precision & 3U) << 8) | ((rounding & 3U) << 10));
}

static unsigned Bench486MenuGameOptionsRun (
		const bench486_menu_gameoptions_case_t *test_case,
		void (*function)(void), unsigned short control_word,
		bench486_menu_gameoptions_result_t *result)
{
	unsigned abi;
	unsigned short cw_before, cw_after;

	vid.width = test_case->video_width;
	bench486_menu_picture_fake_pic[29 * 4] =
			(unsigned)test_case->title_width;
	maxplayers = test_case->maxplayers;
	coop.value = test_case->coop;
	teamplay.value = test_case->teamplay;
	skill.value = test_case->skill;
	fraglimit.value = test_case->fraglimit;
	timelimit.value = test_case->timelimit;
	hipnotic = test_case->hipnotic;
	rogue = test_case->rogue;
	startepisode = test_case->episode;
	startlevel = test_case->level;
	gameoptions_cursor = test_case->cursor;
	realtime = test_case->realtime;
	m_serverInfoMessage = test_case->server_info_message;
	m_serverInfoMessageTime = test_case->server_info_time;
	__asm__ __volatile__ ("fldcw %0" : : "m" (control_word));
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
	result->server_info_message = m_serverInfoMessage;
	result->server_info_time = m_serverInfoMessageTime;
	result->abi = abi;
	result->cw_before = cw_before;
	result->cw_after = cw_after;

	if ((abi & 0x20U) || cw_before != control_word ||
			cw_after != control_word)
		return 0x4d470001U;
	if (result->text.overflow || result->picture.overflow ||
			result->picture.cache_error || !result->text.count ||
			!result->picture.count)
		return 0x4d470002U;
	return 0;
}

static unsigned Bench486MenuGameOptionsExpected (
		const bench486_menu_gameoptions_case_t *test_case,
		const bench486_menu_gameoptions_result_t *result)
{
	unsigned i;
	int expected_message = test_case->server_info_message &&
			(test_case->realtime - test_case->server_info_time) < 5.0;

	if (result->server_info_message != expected_message ||
			result->server_info_time != test_case->server_info_time)
		return 0x4d470010U;
	for (i = 0; i < BMG_TEXT_GUARD_WORDS; i++)
		if (result->text.before[i] != 0x4d540000U + i ||
				result->text.after[i] != 0x4d54f000U + i)
			return 0x4d470020U + i;
	for (i = 0; i < BMG_PICTURE_GUARD_WORDS; i++)
		if (result->picture.before[i] != 0x4d500000U + i ||
				result->picture.after[i] != 0x4d50f000U + i)
			return 0x4d470030U + i;
	return 0;
}

static unsigned Bench486MenuGameOptionsDifference (
		const bench486_menu_gameoptions_result_t *reference,
		const bench486_menu_gameoptions_result_t *candidate)
{
	unsigned i;
	const bench486_menu_text_glyph_t *reference_glyph;
	const bench486_menu_text_glyph_t *candidate_glyph;

	if (reference->abi != candidate->abi ||
			reference->cw_before != candidate->cw_before ||
			reference->cw_after != candidate->cw_after ||
			reference->server_info_message !=
				candidate->server_info_message ||
			reference->server_info_time != candidate->server_info_time)
		return 0x4d470040U;
	if (reference->text.count != candidate->text.count)
	{
		Bench486Printf ("game-options glyph count C/ASM %u/%u\n",
				reference->text.count, candidate->text.count);
		return 0x4d470041U;
	}
	for (i = 0; i < reference->text.count && i <
			sizeof(reference->text.glyphs) /
			sizeof(reference->text.glyphs[0]); i++)
	{
		reference_glyph = &reference->text.glyphs[i];
		candidate_glyph = &candidate->text.glyphs[i];
		if (reference_glyph->x != candidate_glyph->x ||
				reference_glyph->y != candidate_glyph->y ||
				reference_glyph->num != candidate_glyph->num)
		{
			Bench486Printf ("game-options glyph %u C %d,%d,%d ASM %d,%d,%d\n",
					i, reference_glyph->x, reference_glyph->y,
					reference_glyph->num, candidate_glyph->x,
					candidate_glyph->y, candidate_glyph->num);
			return 0x4d470042U + i;
		}
	}
	if (Q_memcmp ((void *)&reference->text, (void *)&candidate->text,
			sizeof(reference->text)))
		return 0x4d470043U;
	if (Q_memcmp ((void *)&reference->picture, (void *)&candidate->picture,
			sizeof(reference->picture)))
		return 0x4d470044U;
	return 0;
}

static void Bench486MenuGameOptionsCases (void)
{
	unsigned case_index, precision, rounding, total = 0, failure = 0;
	unsigned short original_cw = Bench486MenuTextGetControlWord ();
	unsigned saved_width = vid.width;
	unsigned saved_title_width = bench486_menu_picture_fake_pic[29 * 4];
	int saved_maxplayers = maxplayers;
	float saved_coop = coop.value, saved_teamplay = teamplay.value;
	float saved_skill = skill.value, saved_fraglimit = fraglimit.value;
	float saved_timelimit = timelimit.value;
	qboolean saved_hipnotic = hipnotic, saved_rogue = rogue;
	int saved_episode = startepisode, saved_level = startlevel;
	int saved_cursor = gameoptions_cursor;
	qboolean saved_message = m_serverInfoMessage;
	double saved_realtime = realtime;
	double saved_message_time = m_serverInfoMessageTime;
	int saved_text_active = bench486_menu_text_trace_active;
	unsigned short control_word;

	for (case_index = 0; case_index < BMG_MAX_CASES && !failure;
			case_index++)
		for (precision = 0; precision < 3 && !failure; precision++)
			for (rounding = 0; rounding < 4 && !failure; rounding++)
			{
				const bench486_menu_gameoptions_case_t *test_case =
						&bench486_menu_gameoptions_cases[case_index];
				control_word = Bench486MenuGameOptionsControlWord (
						original_cw, precision == 0 ? 0 :
						(precision == 1 ? 2 : 3), rounding);
				failure = Bench486MenuGameOptionsRun (test_case,
						M_GameOptions_Draw_C, control_word,
						&bench486_menu_gameoptions_reference);
				if (!failure)
					failure = Bench486MenuGameOptionsRun (test_case,
							M_GameOptions_Draw, control_word,
							&bench486_menu_gameoptions_candidate);
				if (!failure)
					failure = Bench486MenuGameOptionsExpected (test_case,
							&bench486_menu_gameoptions_reference);
				if (!failure)
					failure = Bench486MenuGameOptionsExpected (test_case,
							&bench486_menu_gameoptions_candidate);
				if (!failure)
					failure = Bench486MenuGameOptionsDifference (
							&bench486_menu_gameoptions_reference,
							&bench486_menu_gameoptions_candidate);
				if (failure)
					Bench486Printf ("game-options C/ASM FAIL case %s precision %u rounding %u code %08x\n",
							test_case->name, precision, rounding, failure);
				total++;
			}

	vid.width = saved_width;
	bench486_menu_picture_fake_pic[29 * 4] = saved_title_width;
	maxplayers = saved_maxplayers;
	coop.value = saved_coop;
	teamplay.value = saved_teamplay;
	skill.value = saved_skill;
	fraglimit.value = saved_fraglimit;
	timelimit.value = saved_timelimit;
	hipnotic = saved_hipnotic;
	rogue = saved_rogue;
	startepisode = saved_episode;
	startlevel = saved_level;
	gameoptions_cursor = saved_cursor;
	m_serverInfoMessage = saved_message;
	realtime = saved_realtime;
	m_serverInfoMessageTime = saved_message_time;
	bench486_menu_text_trace_active = saved_text_active;
	__asm__ __volatile__ ("fldcw %0" : : "m" (original_cw));
	if (failure)
		bench486_memory_failures++;
	else
		Bench486Printf ("game-options menu %u direct C/ASM cases across x87 modes PASS\n",
				total);
}

#endif
#endif

#undef BMG_PICTURE_GUARD_WORDS
#undef BMG_TEXT_GUARD_WORDS
#undef BMG_MAX_CASES
