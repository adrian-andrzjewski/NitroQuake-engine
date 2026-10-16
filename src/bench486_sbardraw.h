/* Direct C/assembly parity for the per-frame status-bar dispatcher. */
#if defined(BENCH486) && defined(ASM486_SBAR_DRAW_FIXTURE)
#ifndef BENCH486_SBAR_DRAW_H
#define BENCH486_SBAR_DRAW_H

#include "asm_sbar.h"

extern int bench486_memory_failures;
extern qboolean hipnotic, rogue;
extern int sb_lines, sb_updates;
extern qboolean sb_showscores;
extern int scr_copyeverything;
extern float scr_con_current;

#define BENCH486_SBAR_DRAW_EVENT_CAPACITY 32

enum
{
	BENCH486_SBAR_DRAW_TILE_CLEAR = 1,
	BENCH486_SBAR_DRAW_INVENTORY,
	BENCH486_SBAR_DRAW_FRAGS,
	BENCH486_SBAR_DRAW_PIC,
	BENCH486_SBAR_DRAW_SCOREBOARD,
	BENCH486_SBAR_DRAW_NUM,
	BENCH486_SBAR_DRAW_FACE,
	BENCH486_SBAR_DRAW_MINI
};

typedef struct
{
	int kind;
	unsigned long args[5];
} bench486_sbar_draw_event_t;

typedef struct
{
	int updates;
	int copy_everything;
	int event_count;
	int overflow;
	bench486_sbar_draw_event_t events[BENCH486_SBAR_DRAW_EVENT_CAPACITY];
} bench486_sbar_draw_snapshot_t;

typedef struct
{
	char *name;
	float console_current;
	unsigned width;
	unsigned height;
	int numpages;
	int updates;
	int lines;
	int copy_everything;
	int show_scores;
	int maxclients;
	int health;
	int armor;
	int ammo;
	int items;
	int hipnotic_game;
	int rogue_game;
	int gametype;
	int expected_events;
	int expected_updates;
	int expected_copy_everything;
} bench486_sbar_draw_case_t;

typedef struct
{
	int updates;
	int lines;
	qboolean show_scores;
	int copy_everything;
	float console_current;
	unsigned width;
	unsigned height;
	int numpages;
	int maxclients;
	int health;
	int armor;
	int ammo;
	int items;
	int gametype;
	int hipnotic_game;
	int rogue_game;
} bench486_sbar_draw_saved_t;

static bench486_sbar_draw_event_t
	bench486_sbar_draw_events[BENCH486_SBAR_DRAW_EVENT_CAPACITY];
static int bench486_sbar_draw_event_count;
static int bench486_sbar_draw_overflow;
static int bench486_sbar_draw_first_diff_logged;

static void Bench486SbarDrawRecord (int kind, unsigned long a,
		unsigned long b, unsigned long c, unsigned long d,
		unsigned long e)
{
	bench486_sbar_draw_event_t *event;
	if (bench486_sbar_draw_event_count >= BENCH486_SBAR_DRAW_EVENT_CAPACITY)
	{
		bench486_sbar_draw_overflow = 1;
		return;
	}
	event = &bench486_sbar_draw_events[bench486_sbar_draw_event_count++];
	event->kind = kind;
	event->args[0] = a;
	event->args[1] = b;
	event->args[2] = c;
	event->args[3] = d;
	event->args[4] = e;
}

void Bench486SbarDrawTileClear (int x, int y, int width, int height)
{
	Bench486SbarDrawRecord (BENCH486_SBAR_DRAW_TILE_CLEAR,
			(unsigned long)x, (unsigned long)y, (unsigned long)width,
			(unsigned long)height, 0);
}

void Bench486SbarDrawInventory (void)
{
	Bench486SbarDrawRecord (BENCH486_SBAR_DRAW_INVENTORY, 0, 0, 0, 0, 0);
}

void Bench486SbarDrawFrags (void)
{
	Bench486SbarDrawRecord (BENCH486_SBAR_DRAW_FRAGS, 0, 0, 0, 0, 0);
}

void Bench486SbarDrawPic (int x, int y, qpic_t *pic)
{
	Bench486SbarDrawRecord (BENCH486_SBAR_DRAW_PIC,
			(unsigned long)x, (unsigned long)y, (unsigned long)pic, 0, 0);
}

void Bench486SbarDrawScoreboard (void)
{
	Bench486SbarDrawRecord (BENCH486_SBAR_DRAW_SCOREBOARD, 0, 0, 0, 0, 0);
}

void Bench486SbarDrawNum (int x, int y, int number, int digits, int color)
{
	Bench486SbarDrawRecord (BENCH486_SBAR_DRAW_NUM,
			(unsigned long)x, (unsigned long)y, (unsigned long)number,
			(unsigned long)digits, (unsigned long)color);
}

void Bench486SbarDrawFace (void)
{
	Bench486SbarDrawRecord (BENCH486_SBAR_DRAW_FACE, 0, 0, 0, 0, 0);
}

void Bench486SbarDrawMiniDeathmatch (void)
{
	Bench486SbarDrawRecord (BENCH486_SBAR_DRAW_MINI, 0, 0, 0, 0, 0);
}

static void Bench486SbarDrawResetCapture (void)
{
	Q_memset (bench486_sbar_draw_events, 0,
			sizeof (bench486_sbar_draw_events));
	bench486_sbar_draw_event_count = 0;
	bench486_sbar_draw_overflow = 0;
}

static void Bench486SbarDrawSaveGlobals (bench486_sbar_draw_saved_t *saved)
{
	saved->updates = sb_updates;
	saved->lines = sb_lines;
	saved->show_scores = sb_showscores;
	saved->copy_everything = scr_copyeverything;
	saved->console_current = scr_con_current;
	saved->width = vid.width;
	saved->height = vid.height;
	saved->numpages = vid.numpages;
	saved->maxclients = cl.maxclients;
	saved->health = cl.stats[STAT_HEALTH];
	saved->armor = cl.stats[STAT_ARMOR];
	saved->ammo = cl.stats[STAT_AMMO];
	saved->items = cl.items;
	saved->gametype = cl.gametype;
	saved->hipnotic_game = hipnotic;
	saved->rogue_game = rogue;
}

static void Bench486SbarDrawRestoreGlobals (
		const bench486_sbar_draw_saved_t *saved)
{
	sb_updates = saved->updates;
	sb_lines = saved->lines;
	sb_showscores = saved->show_scores;
	scr_copyeverything = saved->copy_everything;
	scr_con_current = saved->console_current;
	vid.width = saved->width;
	vid.height = saved->height;
	vid.numpages = saved->numpages;
	cl.maxclients = saved->maxclients;
	cl.stats[STAT_HEALTH] = saved->health;
	cl.stats[STAT_ARMOR] = saved->armor;
	cl.stats[STAT_AMMO] = saved->ammo;
	cl.items = saved->items;
	cl.gametype = saved->gametype;
	hipnotic = saved->hipnotic_game;
	rogue = saved->rogue_game;
}

static void Bench486SbarDrawInstallCase (
		const bench486_sbar_draw_case_t *test_case)
{
	sb_updates = test_case->updates;
	sb_lines = test_case->lines;
	sb_showscores = test_case->show_scores;
	scr_copyeverything = test_case->copy_everything;
	scr_con_current = test_case->console_current;
	vid.width = test_case->width;
	vid.height = test_case->height;
	vid.numpages = test_case->numpages;
	cl.maxclients = test_case->maxclients;
	cl.stats[STAT_HEALTH] = test_case->health;
	cl.stats[STAT_ARMOR] = test_case->armor;
	cl.stats[STAT_AMMO] = test_case->ammo;
	cl.items = test_case->items;
	cl.gametype = test_case->gametype;
	hipnotic = test_case->hipnotic_game;
	rogue = test_case->rogue_game;
}

static void Bench486SbarDrawCaptureSnapshot (
		bench486_sbar_draw_snapshot_t *snapshot)
{
	Q_memset (snapshot, 0, sizeof (*snapshot));
	snapshot->updates = sb_updates;
	snapshot->copy_everything = scr_copyeverything;
	snapshot->event_count = bench486_sbar_draw_event_count;
	snapshot->overflow = bench486_sbar_draw_overflow;
	Q_memcpy (snapshot->events, bench486_sbar_draw_events,
			bench486_sbar_draw_event_count * sizeof (snapshot->events[0]));
}

static void Bench486SbarDrawRun (const bench486_sbar_draw_case_t *test_case,
		int use_asm, bench486_sbar_draw_snapshot_t *snapshot)
{
	Bench486SbarDrawInstallCase (test_case);
	Bench486SbarDrawResetCapture ();
	if (use_asm)
		Sbar_Draw_asm486 ();
	else
		Sbar_Draw_C ();
	Bench486SbarDrawCaptureSnapshot (snapshot);
}

static int Bench486SbarDrawSnapshotsMatch (
		const bench486_sbar_draw_snapshot_t *c,
		const bench486_sbar_draw_snapshot_t *a)
{
	int i;
	if (c->updates != a->updates ||
		c->copy_everything != a->copy_everything ||
		c->event_count != a->event_count || c->overflow || a->overflow)
		return 0;
	for (i = 0; i < c->event_count; i++)
		if (c->events[i].kind != a->events[i].kind ||
			Q_memcmp ((void *)c->events[i].args, (void *)a->events[i].args,
					sizeof (c->events[i].args)))
			return 0;
	return 1;
}

static void Bench486SbarDrawCase (const bench486_sbar_draw_case_t *test_case)
{
	bench486_sbar_draw_snapshot_t c, a;
	bench486_sbar_draw_saved_t saved;
	int passed;

	Bench486SbarDrawSaveGlobals (&saved);
	Bench486SbarDrawRun (test_case, 0, &c);
	Bench486SbarDrawRun (test_case, 1, &a);
	passed = Bench486SbarDrawSnapshotsMatch (&c, &a) &&
			c.event_count == test_case->expected_events &&
			c.updates == test_case->expected_updates &&
			c.copy_everything == test_case->expected_copy_everything;
	if (!passed)
	{
		bench486_memory_failures++;
		if (!bench486_sbar_draw_first_diff_logged)
		{
			Bench486ReportPrintf (
				"sbar draw %s C/ASM events %d/%d, updates %d/%d, copy %d/%d expected %d/%d\n",
				test_case->name, c.event_count, a.event_count,
				c.updates, a.updates, c.copy_everything, a.copy_everything,
				test_case->expected_events, test_case->expected_updates);
			bench486_sbar_draw_first_diff_logged = 1;
		}
		Bench486ReportPrintf ("sbar draw %s FAIL\n", test_case->name);
	}
	else
		Bench486ReportPrintf ("sbar draw %s PASS\n", test_case->name);
	Bench486SbarDrawRestoreGlobals (&saved);
}

static void Bench486SbarDrawCases (void)
{
	static const bench486_sbar_draw_case_t cases[] = {
		{ "console full", 200.0f, 320, 200, 2, 0, 24, 0, 0, 1,
			100, 50, 10, 0, 0, 0, 0, 0, 0, 0 },
		{ "updates saturated", 0.0f, 320, 200, 2, 2, 24, 7, 0, 1,
			100, 50, 10, 0, 0, 0, 0, 0, 2, 7 },
		{ "fractional console", 199.5f, 320, 200, 2, 0, 0, 0, 0, 1,
			100, 50, 10, 0, 0, 0, 0, 0, 1, 1 },
		{ "compact base HUD", 0.0f, 320, 200, 2, 0, 24, 0, 0, 1,
			100, 50, 25, IT_ARMOR1 | IT_SHELLS, 0, 0, 0, 7, 1, 1 },
		{ "wide hipnotic HUD", 0.0f, 640, 480, 3, 0, 48, 0, 0, 4,
			25, 20, 5, IT_KEY1 | IT_KEY2 | IT_INVULNERABILITY | IT_SHELLS,
			1, 0, GAME_DEATHMATCH, 13, 1, 1 },
		{ "base armor priority", 0.0f, 320, 200, 2, 0, 24, 0, 0, 1,
			80, 50, 12, IT_ARMOR1 | IT_ARMOR2 | IT_ARMOR3 |
			IT_SHELLS | IT_NAILS, 0, 0, 0, 7, 1, 1 },
		{ "base low stats", 0.0f, 320, 200, 2, 0, 24, 0, 0, 1,
			10, 0, 0, 0, 0, 0, 0, 5, 1, 1 },
		{ "rogue plasma fallback", 0.0f, 320, 200, 2, 0, 24, 0, 0, 1,
			25, 10, 5, RIT_ARMOR1 | RIT_PLASMA_AMMO,
			0, 1, 0, 7, 1, 1 },
		{ "rogue multi-rocket fallback", 0.0f, 320, 200, 2, 0, 24, 0, 0, 1,
			80, 50, 10, RIT_ARMOR2 | RIT_MULTI_ROCKETS,
			0, 1, 0, 7, 1, 1 },
		{ "score request", 0.0f, 640, 480, 3, 1, 48, 0, 1, 4,
			80, 50, 10, 0, 0, 0, GAME_DEATHMATCH, 6, 0, 1 },
		{ "dead player scoreboard", 0.0f, 320, 200, 2, 0, 0, 0, 0, 1,
			0, 0, 0, 0, 0, 0, 0, 2, 0, 1 },
		{ "widescreen deathmatch mini", 0.0f, 640, 480, 3, 0, 0, 0, 0, 1,
			80, 50, 10, 0, 0, 0, GAME_DEATHMATCH, 1, 1, 1 },
		{ "rogue cell selection", 0.0f, 320, 200, 2, 0, 24, 0, 0, 1,
			80, 30, 20, RIT_ARMOR2 | RIT_CELLS, 0, 1, 0, 7, 1, 1 },
		{ "inventory threshold", 0.0f, 320, 200, 2, 0, 25, 0, 0, 2,
			80, 30, 20, 0, 0, 0, 0, 7, 1, 1 }
	};
	bench486_sbar_draw_saved_t saved;
	int i;
	Bench486SbarDrawSaveGlobals (&saved);
	bench486_sbar_draw_first_diff_logged = 0;
	for (i = 0; i < sizeof (cases) / sizeof (cases[0]); i++)
		Bench486SbarDrawCase (&cases[i]);
	Bench486SbarDrawRestoreGlobals (&saved);
}

#endif /* BENCH486 && ASM486_SBAR_DRAW_FIXTURE */
#endif /* BENCH486_SBAR_DRAW_H */
