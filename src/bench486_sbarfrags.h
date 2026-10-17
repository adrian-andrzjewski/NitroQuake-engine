/* Exact C/assembly parity for status-bar frag-strip composition. */
#ifndef BENCH486_SBARFRAGS_H
#define BENCH486_SBARFRAGS_H

#include "asm_sbar.h"
#include <limits.h>

#define BENCH486_SBAR_FRAGS_EVENT_CAPACITY 64

enum
{
	BENCH486_SBAR_FRAGS_FILL = 1,
	BENCH486_SBAR_FRAGS_CHARACTER
};

typedef struct
{
	int kind;
	unsigned long args[5];
} bench486_sbar_frags_event_t;

typedef struct
{
	int event_count;
	int overflow;
	int scoreboardlines;
	int fragsort[MAX_SCOREBOARD];
	bench486_sbar_frags_event_t events[
			BENCH486_SBAR_FRAGS_EVENT_CAPACITY];
} bench486_sbar_frags_snapshot_t;

typedef struct
{
	int slot;
	const char *name;
	int frags;
	int colors;
} bench486_sbar_frags_player_t;

typedef struct
{
	const char *name;
	int maxclients;
	int gametype;
	int width;
	int height;
	int viewentity;
	int player_count;
	bench486_sbar_frags_player_t players[MAX_SCOREBOARD];
} bench486_sbar_frags_case_t;

typedef struct
{
	scoreboard_t *scores;
	int maxclients;
	int gametype;
	int viewentity;
	int width;
	int height;
	int scoreboardlines;
	int fragsort[MAX_SCOREBOARD];
} bench486_sbar_frags_saved_t;

extern int fragsort[MAX_SCOREBOARD];
extern int scoreboardlines;
extern void Sbar_DrawFrags_C (void);
extern void Sbar_DrawFrags_asm486 (void);

static scoreboard_t bench486_sbar_frags_scores[MAX_SCOREBOARD];
static bench486_sbar_frags_event_t
	bench486_sbar_frags_events[BENCH486_SBAR_FRAGS_EVENT_CAPACITY];
static int bench486_sbar_frags_event_count;
static int bench486_sbar_frags_overflow;

static void Bench486SbarFragsRecord (int kind, unsigned long a,
		unsigned long b, unsigned long c, unsigned long d,
		unsigned long e)
{
	bench486_sbar_frags_event_t *event;
	if (bench486_sbar_frags_event_count >=
			BENCH486_SBAR_FRAGS_EVENT_CAPACITY)
	{
		bench486_sbar_frags_overflow = 1;
		return;
	}
	event = &bench486_sbar_frags_events[bench486_sbar_frags_event_count++];
	event->kind = kind;
	event->args[0] = a;
	event->args[1] = b;
	event->args[2] = c;
	event->args[3] = d;
	event->args[4] = e;
}

void Bench486SbarFragsFill (int x, int y, int width, int height, int color)
{
	Bench486SbarFragsRecord (BENCH486_SBAR_FRAGS_FILL,
			(unsigned long)x, (unsigned long)y, (unsigned long)width,
			(unsigned long)height, (unsigned long)color);
}

void Bench486SbarFragsCharacter (int x, int y, int character)
{
	Bench486SbarFragsRecord (BENCH486_SBAR_FRAGS_CHARACTER,
			(unsigned long)x, (unsigned long)y, (unsigned long)character,
			0, 0);
}

static void Bench486SbarFragsSave (bench486_sbar_frags_saved_t *saved)
{
	saved->scores = cl.scores;
	saved->maxclients = cl.maxclients;
	saved->gametype = cl.gametype;
	saved->viewentity = cl.viewentity;
	saved->width = vid.width;
	saved->height = vid.height;
	saved->scoreboardlines = scoreboardlines;
	Q_memcpy (saved->fragsort, fragsort, sizeof (saved->fragsort));
}

static void Bench486SbarFragsRestore (
		const bench486_sbar_frags_saved_t *saved)
{
	cl.scores = saved->scores;
	cl.maxclients = saved->maxclients;
	cl.gametype = saved->gametype;
	cl.viewentity = saved->viewentity;
	vid.width = saved->width;
	vid.height = saved->height;
	scoreboardlines = saved->scoreboardlines;
	Q_memcpy (fragsort, (void *)saved->fragsort,
			sizeof (saved->fragsort));
}

static void Bench486SbarFragsInstall (
		const bench486_sbar_frags_case_t *test_case)
{
	int i;
	Q_memset (bench486_sbar_frags_scores, 0,
			sizeof (bench486_sbar_frags_scores));
	cl.scores = bench486_sbar_frags_scores;
	cl.maxclients = test_case->maxclients;
	cl.gametype = test_case->gametype;
	cl.viewentity = test_case->viewentity;
	vid.width = test_case->width;
	vid.height = test_case->height;
	for (i = 0; i < MAX_SCOREBOARD; i++)
		fragsort[i] = 0x5a5a0000 + i;
	scoreboardlines = -17;
	for (i = 0; i < test_case->player_count; i++)
	{
		const bench486_sbar_frags_player_t *player;
		scoreboard_t *score;
		player = &test_case->players[i];
		score = &bench486_sbar_frags_scores[player->slot];
		score->frags = player->frags;
		score->colors = player->colors;
		if (player->name)
		{
			strncpy (score->name, player->name, sizeof (score->name) - 1);
			score->name[sizeof (score->name) - 1] = 0;
		}
	}
}

static void Bench486SbarFragsRun (const bench486_sbar_frags_case_t *test_case,
		int use_asm, bench486_sbar_frags_snapshot_t *snapshot)
{
	int saved_width, saved_height;
	saved_width = vid.width;
	saved_height = vid.height;
	Q_memset (bench486_sbar_frags_events, 0,
			sizeof (bench486_sbar_frags_events));
	bench486_sbar_frags_event_count = 0;
	bench486_sbar_frags_overflow = 0;
	Bench486SbarFragsInstall (test_case);
	if (use_asm)
		Sbar_DrawFrags_asm486 ();
	else
		Sbar_DrawFrags_C ();
	snapshot->event_count = bench486_sbar_frags_event_count;
	snapshot->overflow = bench486_sbar_frags_overflow;
	snapshot->scoreboardlines = scoreboardlines;
	Q_memcpy (snapshot->fragsort, fragsort, sizeof (snapshot->fragsort));
	Q_memcpy (snapshot->events, bench486_sbar_frags_events,
			bench486_sbar_frags_event_count * sizeof (snapshot->events[0]));
	/* Keep later BENCH logging on the real console geometry. */
	vid.width = saved_width;
	vid.height = saved_height;
}

static int Bench486SbarFragsEqual (
		const bench486_sbar_frags_snapshot_t *left,
		const bench486_sbar_frags_snapshot_t *right)
{
	int i;
	if (left->event_count != right->event_count || left->overflow ||
		right->overflow || left->scoreboardlines != right->scoreboardlines ||
		Q_memcmp ((void *)left->fragsort, (void *)right->fragsort,
				sizeof (left->fragsort)))
		return 0;
	for (i = 0; i < left->event_count; i++)
		if (left->events[i].kind != right->events[i].kind ||
				Q_memcmp ((void *)left->events[i].args,
						(void *)right->events[i].args,
						sizeof (left->events[i].args)))
			return 0;
	return 1;
}

static void Bench486SbarFragsExplain (
		const bench486_sbar_frags_snapshot_t *left,
		const bench486_sbar_frags_snapshot_t *right)
{
	int i, j;
	for (i = 0; i < MAX_SCOREBOARD; i++)
		if (left->fragsort[i] != right->fragsort[i])
		{
			Bench486Printf ("  sort[%d] C %d ASM %d\n", i,
					left->fragsort[i], right->fragsort[i]);
			return;
		}
	for (i = 0; i < left->event_count && i < right->event_count; i++)
	{
		if (left->events[i].kind != right->events[i].kind)
		{
			Bench486Printf ("  event %d kind C %d ASM %d\n", i,
					left->events[i].kind, right->events[i].kind);
			return;
		}
		for (j = 0; j < 5; j++)
			if (left->events[i].args[j] != right->events[i].args[j])
			{
				Bench486Printf ("  event %d arg %d C %d ASM %d\n", i, j,
						(int)left->events[i].args[j],
						(int)right->events[i].args[j]);
				return;
			}
	}
}

static void Bench486SbarFragsCase (
		const bench486_sbar_frags_case_t *test_case)
{
	bench486_sbar_frags_snapshot_t c_result, asm_result;
	Bench486Printf ("sbar frags %s C start\n", test_case->name);
	Bench486SbarFragsRun (test_case, 0, &c_result);
	Bench486Printf ("sbar frags %s ASM start\n", test_case->name);
	Bench486SbarFragsRun (test_case, 1, &asm_result);
	if (!Bench486SbarFragsEqual (&c_result, &asm_result))
	{
		bench486_memory_failures++;
		Bench486Printf ("sbar frags %s FAIL events %d/%d lines %d/%d overflow %d/%d\n",
				test_case->name, c_result.event_count, asm_result.event_count,
				c_result.scoreboardlines, asm_result.scoreboardlines,
				c_result.overflow, asm_result.overflow);
		Bench486SbarFragsExplain (&c_result, &asm_result);
	}
	else
		Bench486Printf ("sbar frags %s PASS (%d draw events)\n",
				test_case->name, asm_result.event_count);
}

static void Bench486SbarFragsCases (void)
{
	static const bench486_sbar_frags_case_t cases[] = {
		{ "empty scoreboard", 4, GAME_DEATHMATCH, 320, 200, 1, 0, {{0}} },
		{ "deathmatch self and zero frags", 2, GAME_DEATHMATCH, 320, 200,
			2, 1, {{1, "self", 0, 0xf0}} },
		{ "wide cooperative ties and blank name", 6, 0, 640, 480,
			1, 5, {{0, "alpha", 10, 0x01}, {1, "", 99, 0xff},
			{2, "beta", 10, 0xf2}, {3, "minus", -12, 0x80},
			{5, "seven", 7, 0x4f}} },
		{ "signed extreme formatting and four-player limit", 5,
			GAME_DEATHMATCH, 320, 200, 2, 5,
			{{0, "max", 2147483647, 0x21},
			{1, "min", (-2147483647 - 1), 0x30},
			{2, "thousand", 1000, 0x42},
			{3, "negative", -1000, 0x53},
			{4, "small", 7, 0x64}} },
		{ "narrow centered viewport", 3, 0, 300, 240, 3, 2,
			{{0, "one", 1, 0x0f}, {2, "self", -1, 0xa5}} },
		{ "all scoreboard slots and stable ties", 16, GAME_DEATHMATCH,
			320, 200, 8, 16,
			{{0, "zero", 5, 0x01}, {1, "one", -10, 0x12},
			{2, "two", 5, 0x23}, {3, "three", 0, 0x34},
			{4, "four", 10, 0x45}, {5, "five", -1, 0x56},
			{6, "six", 10, 0x67}, {7, "seven", 5, 0x78},
			{8, "eight", (-2147483647 - 1), 0x89},
			{9, "nine", 10, 0x9a}, {10, "ten", 0, 0xab},
			{11, "eleven", 5, 0xbc}, {12, "twelve", -1, 0xcd},
			{13, "thirteen", 0, 0xde}, {14, "fourteen", 5, 0xef},
			{15, "fifteen", 2147483647, 0xf0}} }
	};
	bench486_sbar_frags_saved_t saved;
	int i;
	Bench486SbarFragsSave (&saved);
	for (i = 0; i < sizeof (cases) / sizeof (cases[0]); i++)
		Bench486SbarFragsCase (&cases[i]);
	Bench486SbarFragsRestore (&saved);
}

#endif /* BENCH486_SBARFRAGS_H */
