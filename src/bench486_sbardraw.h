/* Direct C/assembly parity for the per-frame status-bar dispatcher. */
#if defined(BENCH486) && defined(ASM486_SBAR_DRAW_FIXTURE)
#ifndef BENCH486_SBAR_DRAW_H
#define BENCH486_SBAR_DRAW_H

#include "asm_sbar.h"

extern int bench486_memory_failures;
extern unsigned Bench486Call_asm486 (void (*function)(void), unsigned words,
		const unsigned *arguments, float *float_return);
extern qboolean hipnotic, rogue;
extern int sb_lines, sb_updates;
extern qboolean sb_showscores;
extern int scr_copyeverything;
extern float scr_con_current;
extern cvar_t teamplay;
extern qpic_t *sb_faces[7][2];
extern qpic_t *sb_face_invis;
extern qpic_t *sb_face_quad;
extern qpic_t *sb_face_invuln;
extern qpic_t *sb_face_invis_invuln;
extern qpic_t *rsb_teambord;

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

void Bench486SbarFacePic (int x, int y, qpic_t *pic)
{
	Bench486SbarCapture (SBAR_CAPTURE_PIC, x, y, (unsigned long)pic);
}

void Bench486SbarFaceCharacter (int x, int y, int num)
{
	Bench486SbarCapture (SBAR_CAPTURE_CHARACTER, x, y, (unsigned long)num);
}

void Bench486SbarFaceFill (int x, int y, int width, int height, int color)
{
	unsigned long packed;
	packed = ((unsigned long)(width & 255) << 16) |
			((unsigned long)(height & 255) << 8) | (unsigned long)(color & 255);
	Bench486SbarCapture (SBAR_CAPTURE_FILL, x, y, packed);
}

void Bench486SbarMiniFill (int x, int y, int width, int height, int color)
{
	unsigned long packed;
	packed = ((unsigned long)(width & 255) << 16) |
			((unsigned long)(height & 255) << 8) | (unsigned long)(color & 255);
	if (bench486_sbar_capture_active)
		Bench486SbarCapture (SBAR_CAPTURE_FILL, x, y, packed);
	else
		Draw_Fill (x, y, width, height, color);
}

void Bench486SbarMiniCharacter (int x, int y, int character)
{
	if (bench486_sbar_capture_active)
		Bench486SbarCapture (SBAR_CAPTURE_CHARACTER, x, y,
				(unsigned long)character);
	else
		Draw_Character (x, y, character);
}

void Bench486SbarMiniString (int x, int y, char *string)
{
	if (bench486_sbar_capture_active)
		Bench486SbarCapture (SBAR_CAPTURE_STRING, x, y,
				(unsigned long)string);
	else
		Draw_String (x, y, string);
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

typedef struct
{
	const char *name;
	int rogue_game;
	int maxclients;
	float teamplay_value;
	int gametype;
	int width;
	int height;
	int viewentity;
	int health;
	int items;
	double time;
	float faceanimtime;
	int frags;
	int colors;
	int expected_events;
	int expected_updates;
} bench486_sbar_face_case_t;

typedef struct
{
	int updates;
	int viewentity;
	int maxclients;
	int gametype;
	int health;
	int items;
	int width;
	int height;
	double time;
	float faceanimtime;
	float teamplay_value;
	qboolean rogue_game;
	scoreboard_t *scores;
	qpic_t *faces[7][2];
	qpic_t *face_invis;
	qpic_t *face_quad;
	qpic_t *face_invuln;
	qpic_t *face_invis_invuln;
	qpic_t *team_border;
} bench486_sbar_face_saved_t;

static scoreboard_t bench486_sbar_face_scores[4];

static void Bench486SbarFaceCallC (void)
{
	Sbar_DrawFace_C ();
}

static void Bench486SbarFaceCallAsm (void)
{
	Sbar_DrawFace_asm486 ();
}

static void Bench486SbarFaceSave (bench486_sbar_face_saved_t *saved)
{
	saved->updates = sb_updates;
	saved->viewentity = cl.viewentity;
	saved->maxclients = cl.maxclients;
	saved->gametype = cl.gametype;
	saved->health = cl.stats[STAT_HEALTH];
	saved->items = cl.items;
	saved->width = vid.width;
	saved->height = vid.height;
	saved->time = cl.time;
	saved->faceanimtime = cl.faceanimtime;
	saved->teamplay_value = teamplay.value;
	saved->rogue_game = rogue;
	saved->scores = cl.scores;
	Q_memcpy (saved->faces, sb_faces, sizeof(saved->faces));
	saved->face_invis = sb_face_invis;
	saved->face_quad = sb_face_quad;
	saved->face_invuln = sb_face_invuln;
	saved->face_invis_invuln = sb_face_invis_invuln;
	saved->team_border = rsb_teambord;
}

static void Bench486SbarFaceRestore (
		const bench486_sbar_face_saved_t *saved)
{
	sb_updates = saved->updates;
	cl.viewentity = saved->viewentity;
	cl.maxclients = saved->maxclients;
	cl.gametype = saved->gametype;
	cl.stats[STAT_HEALTH] = saved->health;
	cl.items = saved->items;
	vid.width = saved->width;
	vid.height = saved->height;
	cl.time = saved->time;
	cl.faceanimtime = saved->faceanimtime;
	teamplay.value = saved->teamplay_value;
	rogue = saved->rogue_game;
	cl.scores = saved->scores;
	Q_memcpy (sb_faces, (void *)saved->faces, sizeof(saved->faces));
	sb_face_invis = saved->face_invis;
	sb_face_quad = saved->face_quad;
	sb_face_invuln = saved->face_invuln;
	sb_face_invis_invuln = saved->face_invis_invuln;
	rsb_teambord = saved->team_border;
}

static void Bench486SbarFaceInstall (
		const bench486_sbar_face_case_t *test_case)
{
	int i, frame;
	rogue = test_case->rogue_game;
	teamplay.value = test_case->teamplay_value;
	cl.maxclients = test_case->maxclients;
	cl.gametype = test_case->gametype;
	vid.width = test_case->width;
	vid.height = test_case->height;
	cl.viewentity = test_case->viewentity;
	cl.stats[STAT_HEALTH] = test_case->health;
	cl.items = test_case->items;
	cl.time = test_case->time;
	cl.faceanimtime = test_case->faceanimtime;
	cl.scores = bench486_sbar_face_scores;
	bench486_sbar_face_scores[test_case->viewentity - 1].frags =
			test_case->frags;
	bench486_sbar_face_scores[test_case->viewentity - 1].colors =
			test_case->colors;
	sb_updates = 17;
	for (i = 0; i < 7; i++)
		for (frame = 0; frame < 2; frame++)
			sb_faces[i][frame] = (qpic_t *)(unsigned long)
					(0x10000 + (i * 2 + frame) * 32);
	sb_face_invis = (qpic_t *)(unsigned long)0x11000;
	sb_face_quad = (qpic_t *)(unsigned long)0x11020;
	sb_face_invuln = (qpic_t *)(unsigned long)0x11040;
	sb_face_invis_invuln = (qpic_t *)(unsigned long)0x11060;
	rsb_teambord = (qpic_t *)(unsigned long)0x11080;
}

static void Bench486SbarFaceCase (
		const bench486_sbar_face_case_t *test_case)
{
	bench486_sbar_face_saved_t saved;
	int passed;
	Bench486SbarFaceSave (&saved);
	Bench486SbarFaceInstall (test_case);
	passed = Bench486SbarCapturedPair ((char *)test_case->name,
			Bench486SbarFaceCallC, Bench486SbarFaceCallAsm);
	if (bench486_sbar_capture_count != test_case->expected_events ||
		bench486_sbar_capture_overflow ||
		sb_updates != test_case->expected_updates)
		passed = 0;
	if (!passed)
	{
		bench486_memory_failures++;
		Bench486ReportPrintf ("sbar face %s FAIL events %d expected %d updates %d expected %d\n",
				test_case->name, bench486_sbar_capture_count,
				test_case->expected_events, sb_updates,
				test_case->expected_updates);
	}
	else
		Bench486ReportPrintf ("sbar face %s PASS\n", test_case->name);
	Bench486SbarFaceRestore (&saved);
}

static void Bench486SbarDrawFaceCases (void)
{
	static const bench486_sbar_face_case_t cases[] = {
		{ "healthy static", 0, 1, 0.0f, GAME_DEATHMATCH, 320, 200,
			1, 100, 0, 1.0, 0.0f, 0, 0, 1, 17 },
		{ "health face animation equality", 0, 1, 0.0f, 0, 320, 200,
			1, 40, 0, 2.25, 2.25f, 0, 0, 1, 0 },
		{ "health face animation expired", 0, 1, 0.0f, 0, 320, 200,
			1, 99, 0, 2.2501, 2.25f, 0, 0, 1, 17 },
		{ "combined invisibility precedence", 0, 1, 0.0f, 0, 320, 200,
			1, 40, IT_INVISIBILITY | IT_INVULNERABILITY | IT_QUAD,
			1.0, 0.0f, 0, 0, 1, 17 },
		{ "quad precedes invisibility", 0, 1, 0.0f, 0, 320, 200,
			1, 40, IT_INVISIBILITY | IT_QUAD, 1.0, 0.0f, 0, 0, 1, 17 },
		{ "invisibility face", 0, 1, 0.0f, 0, 320, 200,
			1, 40, IT_INVISIBILITY, 1.0, 0.0f, 0, 0, 1, 17 },
		{ "invulnerability face", 0, 1, 0.0f, 0, 320, 200,
			1, 40, IT_INVULNERABILITY, 1.0, 0.0f, 0, 0, 1, 17 },
		{ "team border deathmatch", 1, 4, 3.5f, GAME_DEATHMATCH, 320, 200,
			2, 100, 0, 1.0, 0.0f, 7, 0x21, 6, 17 },
		{ "team border wide cooperative", 1, 8, 6.5f, 0, 640, 480,
			3, 100, 0, 1.0, 0.0f, 1234, 0x21, 6, 17 },
		{ "zero top color suppresses spaces", 1, 4, 4.0f, 0, 320, 200,
			2, 100, 0, 1.0, 0.0f, -1, 0x0f, 5, 17 },
		{ "signed long team frags", 1, 4, 4.0f, 0, 640, 480,
			2, 100, 0, 1.0, 0.0f, -123, 0x21, 6, 17 },
		{ "teamplay lower limit", 1, 4, 3.0f, 0, 320, 200,
			2, 100, 0, 1.0, 0.0f, 7, 0x21, 1, 17 },
		{ "teamplay upper limit", 1, 4, 7.0f, 0, 320, 200,
			2, 100, 0, 1.0, 0.0f, 7, 0x21, 1, 17 },
		{ "single player team colors disabled", 1, 1, 4.0f, 0, 320, 200,
			1, 100, 0, 1.0, 0.0f, 7, 0x21, 1, 17 },
		{ "negative health truncates toward zero", 0, 1, 0.0f, 0, 320, 200,
			1, -5, 0, 1.0, 0.0f, 0, 0, 1, 17 }
	};
	int i;
	bench486_sbar_face_saved_t saved;
	Bench486SbarFaceSave (&saved);
	bench486_sbar_first_diff_logged = 0;
	for (i = 0; i < sizeof(cases) / sizeof(cases[0]); i++)
		Bench486SbarFaceCase (&cases[i]);
	Bench486SbarFaceRestore (&saved);
}

typedef struct
{
	const char *name;
	int width;
	int height;
	int lines;
	int maxclients;
	int viewentity;
	int updates;
	int copy_everything;
	int fullupdate;
	unsigned present_mask;
	int frag_pattern;
	int expected_scoreboardlines;
	int expected_events;
	int expected_copy_everything;
	int expected_fullupdate;
} bench486_sbar_mini_case_t;

extern int scoreboardlines;
extern int fragsort[MAX_SCOREBOARD];

typedef struct
{
	int copy_everything;
	int fullupdate;
	int updates;
	int scoreboardlines;
	int fragsort[MAX_SCOREBOARD];
	int event_count;
	int overflow;
	bench486_sbar_capture_t events[BENCH486_SBAR_CAPTURE_CAPACITY];
	unsigned abi;
} bench486_sbar_mini_result_t;

typedef struct
{
	int lines;
	int updates;
	int copy_everything;
	int fullupdate;
	int maxclients;
	int viewentity;
	int gametype;
	int width;
	int height;
	int scoreboardlines;
	scoreboard_t *scores;
	int fragsort[MAX_SCOREBOARD];
} bench486_sbar_mini_saved_t;

static scoreboard_t bench486_sbar_mini_scores[MAX_SCOREBOARD];
static bench486_sbar_mini_result_t bench486_sbar_mini_c;
static bench486_sbar_mini_result_t bench486_sbar_mini_asm;

static void Bench486SbarMiniCallC (void)
{
	Sbar_MiniDeathmatchOverlay_C ();
}

static void Bench486SbarMiniCallAsm (void)
{
	Sbar_MiniDeathmatchOverlay_asm486 ();
}

static void Bench486SbarMiniSave (bench486_sbar_mini_saved_t *saved)
{
	int i;
	saved->lines = sb_lines;
	saved->updates = sb_updates;
	saved->copy_everything = scr_copyeverything;
	saved->fullupdate = scr_fullupdate;
	saved->maxclients = cl.maxclients;
	saved->viewentity = cl.viewentity;
	saved->gametype = cl.gametype;
	saved->width = vid.width;
	saved->height = vid.height;
	saved->scoreboardlines = scoreboardlines;
	saved->scores = cl.scores;
	for (i = 0; i < MAX_SCOREBOARD; i++)
		saved->fragsort[i] = fragsort[i];
}

static void Bench486SbarMiniRestore (
		const bench486_sbar_mini_saved_t *saved)
{
	int i;
	sb_lines = saved->lines;
	sb_updates = saved->updates;
	scr_copyeverything = saved->copy_everything;
	scr_fullupdate = saved->fullupdate;
	cl.maxclients = saved->maxclients;
	cl.viewentity = saved->viewentity;
	cl.gametype = saved->gametype;
	vid.width = saved->width;
	vid.height = saved->height;
	scoreboardlines = saved->scoreboardlines;
	cl.scores = saved->scores;
	for (i = 0; i < MAX_SCOREBOARD; i++)
		fragsort[i] = saved->fragsort[i];
}

static void Bench486SbarMiniInstall (
		const bench486_sbar_mini_case_t *test_case)
{
	int i;
	Q_memset (bench486_sbar_mini_scores, 0,
			sizeof(bench486_sbar_mini_scores));
	for (i = 0; i < test_case->maxclients; i++)
	{
		scoreboard_t *score;
		score = &bench486_sbar_mini_scores[i];
		if (test_case->present_mask & (1U << i))
		{
			score->name[0] = 'P';
			score->name[1] = (char)('A' + i);
			score->name[2] = 0;
		}
		if (test_case->frag_pattern == 0)
			score->frags = i * 10 - 30;
		else if (test_case->frag_pattern == 1)
			score->frags = 100 - i * 7;
		else
			score->frags = (i % 4) * 10 - 10;
		score->colors = ((i * 19) & 0xf0) | ((i * 7) & 15);
	}

	vid.width = test_case->width;
	vid.height = test_case->height;
	sb_lines = test_case->lines;
	sb_updates = test_case->updates;
	scr_copyeverything = test_case->copy_everything;
	scr_fullupdate = test_case->fullupdate;
	cl.maxclients = test_case->maxclients;
	cl.viewentity = test_case->viewentity;
	cl.gametype = GAME_DEATHMATCH;
	cl.scores = bench486_sbar_mini_scores;
	scoreboardlines = -19;
	for (i = 0; i < MAX_SCOREBOARD; i++)
		fragsort[i] = -101 - i;
}

static void Bench486SbarMiniRun (
		void (*function)(void),
		bench486_sbar_mini_result_t *result)
{
	int i;
	Q_memset (result, 0, sizeof(*result));
	bench486_sbar_capture_active = 1;
	bench486_sbar_capture_count = 0;
	bench486_sbar_capture_overflow = 0;
	result->abi = Bench486Call_asm486 (function, 0, NULL, NULL);
	bench486_sbar_capture_active = 0;
	result->copy_everything = scr_copyeverything;
	result->fullupdate = scr_fullupdate;
	result->updates = sb_updates;
	result->scoreboardlines = scoreboardlines;
	for (i = 0; i < MAX_SCOREBOARD; i++)
		result->fragsort[i] = fragsort[i];
	result->event_count = bench486_sbar_capture_count;
	result->overflow = bench486_sbar_capture_overflow;
	for (i = 0; i < result->event_count; i++)
		result->events[i] = bench486_sbar_capture[i];
}

static int Bench486SbarMiniResultsMatch (
		const bench486_sbar_mini_result_t *left,
		const bench486_sbar_mini_result_t *right)
{
	int i;
	if (left->copy_everything != right->copy_everything ||
			left->fullupdate != right->fullupdate ||
			left->updates != right->updates ||
			left->scoreboardlines != right->scoreboardlines ||
			left->event_count != right->event_count ||
			left->overflow != right->overflow ||
			left->abi != right->abi ||
			Q_memcmp ((void *)left->fragsort, (void *)right->fragsort,
					sizeof(left->fragsort)))
		return 0;
	for (i = 0; i < left->event_count; i++)
		if (left->events[i].kind != right->events[i].kind ||
				left->events[i].x != right->events[i].x ||
				left->events[i].y != right->events[i].y ||
				left->events[i].value != right->events[i].value)
			return 0;
	return 1;
}

static void Bench486SbarMiniCase (
		const bench486_sbar_mini_case_t *test_case)
{
	bench486_sbar_mini_saved_t saved;
	int passed, i;
	Bench486SbarMiniSave (&saved);
	Bench486SbarMiniInstall (test_case);
	Bench486SbarMiniRun (Bench486SbarMiniCallC, &bench486_sbar_mini_c);
	Bench486SbarMiniInstall (test_case);
	Bench486SbarMiniRun (Bench486SbarMiniCallAsm, &bench486_sbar_mini_asm);
	passed = Bench486SbarMiniResultsMatch (
			&bench486_sbar_mini_c, &bench486_sbar_mini_asm) &&
			bench486_sbar_mini_asm.event_count == test_case->expected_events &&
			bench486_sbar_mini_asm.scoreboardlines ==
					test_case->expected_scoreboardlines &&
			bench486_sbar_mini_asm.updates == test_case->updates &&
			bench486_sbar_mini_asm.copy_everything ==
					test_case->expected_copy_everything &&
			bench486_sbar_mini_asm.fullupdate ==
					test_case->expected_fullupdate &&
			bench486_sbar_mini_asm.abi == 0 &&
			!bench486_sbar_mini_asm.overflow;
	if (!passed)
	{
		bench486_memory_failures++;
		Bench486ReportPrintf (
				"sbar mini-deathmatch %s FAIL events %d/%d expected %d lines %d/%d ABI %u/%u\n",
				test_case->name, bench486_sbar_mini_c.event_count,
				bench486_sbar_mini_asm.event_count,
				test_case->expected_events,
				bench486_sbar_mini_c.scoreboardlines,
				bench486_sbar_mini_asm.scoreboardlines,
				bench486_sbar_mini_c.abi, bench486_sbar_mini_asm.abi);
		for (i = 0; i < MAX_SCOREBOARD; i++)
			if (bench486_sbar_mini_c.fragsort[i] !=
					bench486_sbar_mini_asm.fragsort[i])
			{
				Bench486ReportPrintf (
						"sbar mini-deathmatch %s fragsort[%d] C %d ASM %d\n",
						test_case->name, i,
						bench486_sbar_mini_c.fragsort[i],
						bench486_sbar_mini_asm.fragsort[i]);
				break;
			}
		for (i = 0; i < bench486_sbar_mini_c.event_count &&
				i < bench486_sbar_mini_asm.event_count; i++)
			if (bench486_sbar_mini_c.events[i].kind !=
					bench486_sbar_mini_asm.events[i].kind ||
				bench486_sbar_mini_c.events[i].x !=
					bench486_sbar_mini_asm.events[i].x ||
				bench486_sbar_mini_c.events[i].y !=
					bench486_sbar_mini_asm.events[i].y ||
				bench486_sbar_mini_c.events[i].value !=
					bench486_sbar_mini_asm.events[i].value)
			{
				Bench486ReportPrintf (
						"sbar mini-deathmatch %s event[%d] C %d,%d,%d,%lu ASM %d,%d,%d,%lu\n",
						test_case->name, i,
						bench486_sbar_mini_c.events[i].kind,
						bench486_sbar_mini_c.events[i].x,
						bench486_sbar_mini_c.events[i].y,
						bench486_sbar_mini_c.events[i].value,
						bench486_sbar_mini_asm.events[i].kind,
						bench486_sbar_mini_asm.events[i].x,
						bench486_sbar_mini_asm.events[i].y,
						bench486_sbar_mini_asm.events[i].value);
				break;
			}
	}
	else
		Bench486ReportPrintf ("sbar mini-deathmatch %s PASS\n",
				test_case->name);
	Bench486SbarMiniRestore (&saved);
}

static void Bench486SbarMiniDeathmatchCases (void)
{
	static const bench486_sbar_mini_case_t cases[] = {
		{ "below-wide-threshold", 511, 240, 48, 6, 4, 5, 7, 9,
			0x003f, 0, -19, 0, 7, 9 },
		{ "zero-bar-lines", 640, 240, 0, 6, 4, 6, 5, 8,
			0x003f, 0, -19, 0, 5, 8 },
		{ "fewer-than-three-rows", 640, 240, 16, 6, 4, 7, 6, 10,
			0x003f, 0, 6, 0, 1, 0 },
		{ "centered-negative-frags", 640, 240, 32, 6, 4, 8, 3, 7,
			0x003f, 0, 6, 20, 1, 0 },
		{ "missing-viewer-falls-back-to-top", 640, 240, 32, 6, 12, 9, 2, 6,
			0x003f, 0, 6, 18, 1, 0 },
		{ "bottom-window-clamp", 800, 320, 40, 10, 1, 10, 4, 5,
			0x03ff, 0, 10, 24, 1, 0 },
		{ "seven-row-tied-frags-and-marker", 640, 400, 64, 12, 8, 11, 0, 4,
			0x0fff, 2, 12, 44, 1, 0 },
		{ "empty-score-list", 640, 240, 24, 0, 1, 12, 0, 3,
			0, 0, 0, 0, 1, 0 }
	};
	bench486_sbar_mini_saved_t saved;
	unsigned failures_before;
	int i;
	failures_before = bench486_memory_failures;
	Bench486SbarMiniSave (&saved);
	for (i = 0; i < sizeof(cases) / sizeof(cases[0]); i++)
		Bench486SbarMiniCase (&cases[i]);
	Bench486SbarMiniRestore (&saved);
	if (bench486_memory_failures == failures_before)
		Bench486ReportPrintf (
				"sbar mini-deathmatch 8 exact C/ASM scoreboard/draw/state/ABI cases PASS\n");
	else
		Bench486ReportPrintf (
				"sbar mini-deathmatch 8 exact C/ASM scoreboard/draw/state/ABI cases FAIL\n");
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
	Bench486SbarDrawFaceCases ();
	Bench486SbarMiniDeathmatchCases ();
}

#endif /* BENCH486 && ASM486_SBAR_DRAW_FIXTURE */
#endif /* BENCH486_SBAR_DRAW_H */
