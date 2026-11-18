/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
#ifndef BENCH486_PLAYERTRANSLATION_H
#define BENCH486_PLAYERTRANSLATION_H

#include "client/asm_playertranslation.h"

#define BENCH486_PT_GUARD_BYTES 16

typedef struct
{
	byte before[BENCH486_PT_GUARD_BYTES];
	scoreboard_t score;
	byte after[BENCH486_PT_GUARD_BYTES];
} bench486_player_translation_score_t;

static int Bench486PlayerTranslationCases (void)
{
	static byte saved_identity[PT_IDENTITY_BYTES];
	static byte saved_translation[PT_IDENTITY_BYTES];
	static byte expected_identity[PT_IDENTITY_BYTES];
	static byte expected_translation[PT_IDENTITY_BYTES];
	static byte expected_player[VID_GRADES * PT_ROW_BYTES];
	static struct
	{
		byte before[BENCH486_PT_GUARD_BYTES];
		byte colormap[VID_GRADES * PT_ROW_BYTES];
		byte after[BENCH486_PT_GUARD_BYTES];
	} source_guard;
	static bench486_player_translation_score_t fixture_score;
	static byte guard_value[BENCH486_PT_GUARD_BYTES];
	byte *saved_colormap;
	scoreboard_t *saved_scores;
	int saved_maxclients;
	int top, bottom, i;
	int failures;
	unsigned arguments[2];
	unsigned abi;

	failures = 0;
	Q_memcpy (saved_identity, identityTable, sizeof(saved_identity));
	Q_memcpy (saved_translation, translationTable, sizeof(saved_translation));

	for (top = 0; top <= 240; top += 16)
	{
		for (bottom = 0; bottom <= 240; bottom += 16)
		{
			M_BuildTranslationTable_C (top, bottom);
			Q_memcpy (expected_identity, identityTable,
					sizeof(expected_identity));
			Q_memcpy (expected_translation, translationTable,
					sizeof(expected_translation));
			arguments[0] = (unsigned)top;
			arguments[1] = (unsigned)bottom;
			abi = Bench486Call_asm486 (
					(void (*)(void))M_BuildTranslationTable, 2, arguments, NULL);
			if (abi || Q_memcmp (identityTable, expected_identity,
					sizeof(expected_identity)) ||
				Q_memcmp (translationTable, expected_translation,
					sizeof(expected_translation)))
				failures |= 1;
		}
	}

	Q_memcpy (identityTable, saved_identity, sizeof(saved_identity));
	Q_memcpy (translationTable, saved_translation, sizeof(saved_translation));

	for (i = 0; i < BENCH486_PT_GUARD_BYTES; i++)
		guard_value[i] = 0xa5;
	Q_memset (&source_guard, 0, sizeof(source_guard));
	Q_memset (&fixture_score, 0, sizeof(fixture_score));
	Q_memset (source_guard.before, 0xa5, sizeof(source_guard.before));
	Q_memset (source_guard.after, 0xa5, sizeof(source_guard.after));
	Q_memset (fixture_score.before, 0xa5, sizeof(fixture_score.before));
	Q_memset (fixture_score.after, 0xa5, sizeof(fixture_score.after));
	for (i = 0; i < VID_GRADES * PT_ROW_BYTES; i++)
		source_guard.colormap[i] = (byte)(i * 37 + (i >> 8) * 13);

	saved_colormap = vid.colormap;
	saved_scores = cl.scores;
	saved_maxclients = cl.maxclients;
	vid.colormap = source_guard.colormap;
	cl.scores = &fixture_score.score;
	cl.maxclients = 0;

	for (top = 0; top <= 240; top += 16)
	{
		for (bottom = 0; bottom <= 240; bottom += 16)
		{
			fixture_score.score.colors = top | (bottom >> 4);
			CL_NewTranslation_C (0);
			Q_memcpy (expected_player, fixture_score.score.translations,
					sizeof(expected_player));
			arguments[0] = 0;
			abi = Bench486Call_asm486 (
					(void (*)(void))CL_NewTranslation, 1, arguments, NULL);
			if (abi || Q_memcmp (fixture_score.score.translations,
					expected_player, sizeof(expected_player)))
				failures |= 2;
		}
	}

	vid.colormap = saved_colormap;
	cl.scores = saved_scores;
	cl.maxclients = saved_maxclients;
	if (Q_memcmp (source_guard.before, guard_value, sizeof(guard_value)) ||
			Q_memcmp (source_guard.after, guard_value, sizeof(guard_value)) ||
			Q_memcmp (fixture_score.before, guard_value, sizeof(guard_value)) ||
			Q_memcmp (fixture_score.after, guard_value, sizeof(guard_value)))
		failures |= 4;

	return failures;
}

#endif
