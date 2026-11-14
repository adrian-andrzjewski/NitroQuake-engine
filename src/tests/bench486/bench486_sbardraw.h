/* Direct C/assembly parity for the per-frame status-bar dispatcher. */
#if defined(BENCH486) && defined(ASM486_SBAR_DRAW_FIXTURE)
#ifndef BENCH486_SBAR_DRAW_H
#define BENCH486_SBAR_DRAW_H

#include "client/asm_sbar.h"

extern int bench486_memory_failures;
extern unsigned Bench486Call_asm486 (void (*function)(void), unsigned words,
		const unsigned *arguments, float *float_return);
extern qboolean hipnotic, rogue;
extern int sb_lines, sb_updates;
extern qboolean sb_showscores;
extern int scr_copyeverything;
extern int scr_fullupdate;
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
	BENCH486_SBAR_DRAW_MINI,
	BENCH486_SBAR_DRAW_STRING
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

void Bench486SbarSoloDrawString (int x, int y, char *string)
{
	unsigned long hash;
	int length;
	hash = 2166136261UL;
	length = 0;
	while (string[length])
	{
		hash ^= (unsigned char)string[length++];
		hash *= 16777619UL;
	}
	Bench486SbarDrawRecord (BENCH486_SBAR_DRAW_STRING,
			(unsigned long)x, (unsigned long)y, hash,
			(unsigned long)length, 0);
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

static qpic_t bench486_sbar_deathmatch_pic;
static int bench486_sbar_deathmatch_cache_calls;
static int bench486_sbar_deathmatch_bad_cache_path;
static int bench486_sbar_deathmatch_bad_pic;

qpic_t *Bench486SbarDeathmatchCachePic (char *path)
{
	static const char expected[] = "gfx/ranking.lmp";
	int i;
	bench486_sbar_deathmatch_cache_calls++;
	if (!path)
		bench486_sbar_deathmatch_bad_cache_path = 1;
	else
	{
		for (i = 0; expected[i] && path[i] == expected[i]; i++)
			;
		if (expected[i] || path[i])
			bench486_sbar_deathmatch_bad_cache_path = 1;
	}
	return &bench486_sbar_deathmatch_pic;
}

void Bench486SbarDeathmatchDrawPic (int x, int y, qpic_t *pic)
{
	if (pic != &bench486_sbar_deathmatch_pic)
		bench486_sbar_deathmatch_bad_pic = 1;
	Bench486SbarCapture (SBAR_CAPTURE_PIC, x, y, (unsigned long)pic);
}

static qpic_t bench486_sbar_intermission_complete_pic;
static qpic_t bench486_sbar_intermission_inter_pic;
static qpic_t bench486_sbar_finale_pic;
static int bench486_sbar_intermission_cache_calls;
static int bench486_sbar_intermission_bad_cache_path;

qpic_t *Bench486SbarIntermissionCachePic (char *path)
{
	static const char complete[] = "gfx/complete.lmp";
	static const char intermission[] = "gfx/inter.lmp";
	static const char finale[] = "gfx/finale.lmp";
	const char *expected;
	int i, path_id;
	path_id = 0;
	if (path)
	{
		expected = complete;
		for (i = 0; expected[i] && path[i] == expected[i]; i++)
			;
		if (!expected[i] && !path[i])
			path_id = 1;
		else
		{
			expected = intermission;
			for (i = 0; expected[i] && path[i] == expected[i]; i++)
				;
			if (!expected[i] && !path[i])
				path_id = 2;
			else
			{
				expected = finale;
				for (i = 0; expected[i] && path[i] == expected[i]; i++)
					;
				if (!expected[i] && !path[i])
					path_id = 3;
			}
		}
	}
	if (!path_id)
	{
		bench486_sbar_intermission_bad_cache_path = 1;
		path_id = 1;
	}
	bench486_sbar_intermission_cache_calls++;
	Bench486SbarCapture (SBAR_CAPTURE_CACHEPIC, path_id, 0, 0);
	if (path_id == 2)
		return &bench486_sbar_intermission_inter_pic;
	if (path_id == 3)
		return &bench486_sbar_finale_pic;
	return &bench486_sbar_intermission_complete_pic;
}

void Bench486SbarIntermissionDrawPic (int x, int y, qpic_t *pic)
{
	if (bench486_sbar_capture_active)
		Bench486SbarCapture (SBAR_CAPTURE_PIC, x, y, (unsigned long)pic);
	else
		Draw_Pic (x, y, pic);
}

void Bench486SbarIntermissionDrawTransPic (int x, int y, qpic_t *pic)
{
	if (bench486_sbar_capture_active)
		Bench486SbarCapture (SBAR_CAPTURE_TRANSPIC, x, y, (unsigned long)pic);
	else
		Draw_TransPic (x, y, pic);
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

typedef struct
{
	const char *name;
	int width;
	int picture_width;
	int maxclients;
	int viewentity;
	unsigned present_mask;
	int frag_pattern;
	int expected_lines;
	int expected_picture_x;
	int expected_score_x;
} bench486_sbar_deathmatch_case_t;

typedef struct
{
	int copy_everything;
	int fullupdate;
	int scoreboardlines;
	int fragsort[MAX_SCOREBOARD];
	int event_count;
	int overflow;
	int cache_calls;
	int bad_cache_path;
	int bad_pic;
	unsigned abi;
	bench486_sbar_capture_t events[BENCH486_SBAR_CAPTURE_CAPACITY];
} bench486_sbar_deathmatch_result_t;

static bench486_sbar_deathmatch_result_t bench486_sbar_deathmatch_c;
static bench486_sbar_deathmatch_result_t bench486_sbar_deathmatch_asm;

static void Bench486SbarDeathmatchCallC (void)
{
	Sbar_DeathmatchOverlay_C ();
}

static void Bench486SbarDeathmatchCallAsm (void)
{
	Sbar_DeathmatchOverlay_asm486 ();
}

static void Bench486SbarDeathmatchInstall (
		const bench486_sbar_deathmatch_case_t *test_case)
{
	static const int format_frags[MAX_SCOREBOARD] = {
		-9999, -1000, -100, -1, 0, 1, 99, 100,
		999, 1234, 321, -1234, 777, -777, 42, -42
	};
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
			score->frags = i * 31 - 73;
		else if (test_case->frag_pattern == 1)
			score->frags = (test_case->maxclients - i) * 17;
		else if (test_case->frag_pattern == 2)
			score->frags = (i % 3) * 10 - 10;
		else
			score->frags = format_frags[i];
		score->colors = ((i * 53) & 0xf0) | ((i * 9) & 15);
	}

	vid.width = test_case->width;
	cl.maxclients = test_case->maxclients;
	cl.viewentity = test_case->viewentity;
	cl.gametype = GAME_DEATHMATCH;
	cl.scores = bench486_sbar_mini_scores;
	scoreboardlines = -73;
	for (i = 0; i < MAX_SCOREBOARD; i++)
		fragsort[i] = -211 - i;
	scr_copyeverything = -13;
	scr_fullupdate = -17;
	bench486_sbar_deathmatch_pic.width = test_case->picture_width;
	bench486_sbar_deathmatch_pic.height = 64;
	bench486_sbar_deathmatch_cache_calls = 0;
	bench486_sbar_deathmatch_bad_cache_path = 0;
	bench486_sbar_deathmatch_bad_pic = 0;
}

static void Bench486SbarDeathmatchRun (void (*function)(void),
		bench486_sbar_deathmatch_result_t *result)
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
	result->scoreboardlines = scoreboardlines;
	for (i = 0; i < MAX_SCOREBOARD; i++)
		result->fragsort[i] = fragsort[i];
	result->event_count = bench486_sbar_capture_count;
	result->overflow = bench486_sbar_capture_overflow;
	result->cache_calls = bench486_sbar_deathmatch_cache_calls;
	result->bad_cache_path = bench486_sbar_deathmatch_bad_cache_path;
	result->bad_pic = bench486_sbar_deathmatch_bad_pic;
	for (i = 0; i < result->event_count; i++)
		result->events[i] = bench486_sbar_capture[i];
}

static int Bench486SbarDeathmatchResultsMatch (
		const bench486_sbar_deathmatch_result_t *left,
		const bench486_sbar_deathmatch_result_t *right)
{
	int i;
	if (left->copy_everything != right->copy_everything ||
			left->fullupdate != right->fullupdate ||
			left->scoreboardlines != right->scoreboardlines ||
			left->event_count != right->event_count ||
			left->overflow != right->overflow ||
			left->cache_calls != right->cache_calls ||
			left->bad_cache_path != right->bad_cache_path ||
			left->bad_pic != right->bad_pic || left->abi != right->abi ||
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

static void Bench486SbarDeathmatchCase (
		const bench486_sbar_deathmatch_case_t *test_case)
{
	bench486_sbar_mini_saved_t saved;
	int expected_events, has_viewer, passed, i;
	Bench486SbarMiniSave (&saved);
	Bench486SbarDeathmatchInstall (test_case);
	Bench486SbarDeathmatchRun (Bench486SbarDeathmatchCallC,
			&bench486_sbar_deathmatch_c);
	Bench486SbarDeathmatchInstall (test_case);
	Bench486SbarDeathmatchRun (Bench486SbarDeathmatchCallAsm,
			&bench486_sbar_deathmatch_asm);
	has_viewer = test_case->viewentity > 0 &&
		test_case->viewentity <= test_case->maxclients &&
		(test_case->present_mask & (1U << (test_case->viewentity - 1)));
	expected_events = 1 + test_case->expected_lines * 6 + (has_viewer ? 1 : 0);
	passed = Bench486SbarDeathmatchResultsMatch (
			&bench486_sbar_deathmatch_c, &bench486_sbar_deathmatch_asm) &&
			bench486_sbar_deathmatch_asm.copy_everything == 1 &&
			bench486_sbar_deathmatch_asm.fullupdate == 0 &&
			bench486_sbar_deathmatch_asm.scoreboardlines ==
				test_case->expected_lines &&
			bench486_sbar_deathmatch_asm.event_count == expected_events &&
			bench486_sbar_deathmatch_asm.cache_calls == 1 &&
			!bench486_sbar_deathmatch_asm.bad_cache_path &&
			!bench486_sbar_deathmatch_asm.bad_pic &&
			bench486_sbar_deathmatch_asm.abi == 0 &&
			!bench486_sbar_deathmatch_asm.overflow &&
			bench486_sbar_deathmatch_asm.events[0].kind == SBAR_CAPTURE_PIC &&
			bench486_sbar_deathmatch_asm.events[0].x ==
				test_case->expected_picture_x &&
			bench486_sbar_deathmatch_asm.events[0].y == 8;
	if (passed && test_case->expected_lines)
		passed = bench486_sbar_deathmatch_asm.events[1].kind ==
				SBAR_CAPTURE_FILL &&
			bench486_sbar_deathmatch_asm.events[1].x ==
				test_case->expected_score_x &&
			bench486_sbar_deathmatch_asm.events[1].y == 40;
	if (!passed)
	{
		bench486_memory_failures++;
		Bench486ReportPrintf (
				"sbar deathmatch %s FAIL events %d/%d expected %d lines %d/%d cache %d/%d ABI %u/%u\n",
				test_case->name, bench486_sbar_deathmatch_c.event_count,
				bench486_sbar_deathmatch_asm.event_count, expected_events,
				bench486_sbar_deathmatch_c.scoreboardlines,
				bench486_sbar_deathmatch_asm.scoreboardlines,
				bench486_sbar_deathmatch_c.cache_calls,
				bench486_sbar_deathmatch_asm.cache_calls,
				bench486_sbar_deathmatch_c.abi,
				bench486_sbar_deathmatch_asm.abi);
		for (i = 0; i < bench486_sbar_deathmatch_c.event_count &&
				i < bench486_sbar_deathmatch_asm.event_count; i++)
			if (bench486_sbar_deathmatch_c.events[i].kind !=
					bench486_sbar_deathmatch_asm.events[i].kind ||
				bench486_sbar_deathmatch_c.events[i].x !=
					bench486_sbar_deathmatch_asm.events[i].x ||
				bench486_sbar_deathmatch_c.events[i].y !=
					bench486_sbar_deathmatch_asm.events[i].y ||
				bench486_sbar_deathmatch_c.events[i].value !=
					bench486_sbar_deathmatch_asm.events[i].value)
			{
				Bench486ReportPrintf (
						"sbar deathmatch %s event[%d] C %d,%d,%d,%lu ASM %d,%d,%d,%lu\n",
						test_case->name, i,
						bench486_sbar_deathmatch_c.events[i].kind,
						bench486_sbar_deathmatch_c.events[i].x,
						bench486_sbar_deathmatch_c.events[i].y,
						bench486_sbar_deathmatch_c.events[i].value,
						bench486_sbar_deathmatch_asm.events[i].kind,
						bench486_sbar_deathmatch_asm.events[i].x,
						bench486_sbar_deathmatch_asm.events[i].y,
						bench486_sbar_deathmatch_asm.events[i].value);
				break;
			}
	}
	else
		Bench486ReportPrintf ("sbar deathmatch %s PASS\n", test_case->name);
	Bench486SbarMiniRestore (&saved);
}

static void Bench486SbarDeathmatchCases (void)
{
	static const bench486_sbar_deathmatch_case_t cases[] = {
		{ "classic-center-and-local-marker", 320, 320, 4, 2, 0x000f,
			0, 4, 0, 80 },
		{ "sub-320-negative-centering", 319, 323, 3, 1, 0x0005,
			2, 2, -1, -2147483569 },
		{ "widescreen-tied-frags-no-viewer", 640, 641, 8, 16, 0x00ff,
			2, 8, -160, 240 },
		{ "empty-roster", 640, 300, 16, 1, 0,
			0, 0, 10, 240 },
		{ "all-score-slots-signed-formats", 640, 322, 16, 8, 0xffff,
			3, 16, -1, 240 },
		{ "single-player-negative-frags", 320, 319, 1, 1, 0x0001,
			0, 1, 0, 80 }
	};
	bench486_sbar_mini_saved_t saved;
	unsigned failures_before;
	int i;
	failures_before = bench486_memory_failures;
	Bench486SbarMiniSave (&saved);
	for (i = 0; i < sizeof(cases) / sizeof(cases[0]); i++)
		Bench486SbarDeathmatchCase (&cases[i]);
	Bench486SbarMiniRestore (&saved);
	if (bench486_memory_failures == failures_before)
		Bench486ReportPrintf (
				"sbar full deathmatch 6 exact C/ASM picture/scoreboard/state/ABI cases PASS\n");
	else
		Bench486ReportPrintf (
				"sbar full deathmatch 6 exact C/ASM picture/scoreboard/state/ABI cases FAIL\n");
}

typedef struct
{
	const char *name;
	int gametype;
	int completed_time;
	int secrets;
	int total_secrets;
	int monsters;
	int total_monsters;
	int width;
	int picture_width;
	int maxclients;
	int viewentity;
	unsigned present_mask;
	int frag_pattern;
} bench486_sbar_intermission_case_t;

typedef struct
{
	int copy_everything;
	int fullupdate;
	int scoreboardlines;
	int fragsort[MAX_SCOREBOARD];
	int intermission_cache_calls;
	int intermission_bad_cache_path;
	int deathmatch_cache_calls;
	int deathmatch_bad_cache_path;
	int deathmatch_bad_pic;
	int event_count;
	int overflow;
	unsigned abi;
	bench486_sbar_capture_t events[BENCH486_SBAR_CAPTURE_CAPACITY];
} bench486_sbar_intermission_result_t;

static bench486_sbar_intermission_result_t bench486_sbar_intermission_c;
static bench486_sbar_intermission_result_t bench486_sbar_intermission_asm;

static void Bench486SbarIntermissionCallC (void)
{
	Sbar_IntermissionOverlay_C ();
}

static void Bench486SbarIntermissionCallAsm (void)
{
	Sbar_IntermissionOverlay_asm486 ();
}

static void Bench486SbarIntermissionInstall (
		const bench486_sbar_intermission_case_t *test_case)
{
	static const int format_frags[MAX_SCOREBOARD] = {
		-9999, -1000, -100, -1, 0, 1, 99, 100,
		999, 1234, 321, -1234, 777, -777, 42, -42
	};
	int i;
	Q_memset (bench486_sbar_mini_scores, 0,
			sizeof(bench486_sbar_mini_scores));
	for (i = 0; i < test_case->maxclients; i++)
	{
		scoreboard_t *score;
		score = &bench486_sbar_mini_scores[i];
		if (test_case->present_mask & (1U << i))
		{
			score->name[0] = 'I';
			score->name[1] = (char)('A' + i);
			score->name[2] = 0;
		}
		if (test_case->frag_pattern == 0)
			score->frags = i * 37 - 41;
		else
			score->frags = (test_case->maxclients - i) * 13;
		score->colors = ((i * 29) & 0xf0) | ((i * 5) & 15);
	}
	vid.width = test_case->width;
	cl.gametype = test_case->gametype;
	cl.completed_time = test_case->completed_time;
	cl.stats[STAT_SECRETS] = test_case->secrets;
	cl.stats[STAT_TOTALSECRETS] = test_case->total_secrets;
	cl.stats[STAT_MONSTERS] = test_case->monsters;
	cl.stats[STAT_TOTALMONSTERS] = test_case->total_monsters;
	cl.maxclients = test_case->maxclients;
	cl.viewentity = test_case->viewentity;
	cl.scores = bench486_sbar_mini_scores;
	scoreboardlines = -73;
	for (i = 0; i < MAX_SCOREBOARD; i++)
		fragsort[i] = -211 - i;
	scr_copyeverything = -13;
	scr_fullupdate = -17;
	bench486_sbar_deathmatch_pic.width = test_case->picture_width;
	bench486_sbar_deathmatch_pic.height = 64;
}

static void Bench486SbarIntermissionRun (void (*function)(void),
		bench486_sbar_intermission_result_t *result)
{
	int i;
	Q_memset (result, 0, sizeof(*result));
	bench486_sbar_capture_active = 1;
	bench486_sbar_capture_count = 0;
	bench486_sbar_capture_overflow = 0;
	bench486_sbar_intermission_cache_calls = 0;
	bench486_sbar_intermission_bad_cache_path = 0;
	bench486_sbar_deathmatch_cache_calls = 0;
	bench486_sbar_deathmatch_bad_cache_path = 0;
	bench486_sbar_deathmatch_bad_pic = 0;
	result->abi = Bench486Call_asm486 (function, 0, NULL, NULL);
	bench486_sbar_capture_active = 0;
	result->copy_everything = scr_copyeverything;
	result->fullupdate = scr_fullupdate;
	result->scoreboardlines = scoreboardlines;
	for (i = 0; i < MAX_SCOREBOARD; i++)
		result->fragsort[i] = fragsort[i];
	result->intermission_cache_calls = bench486_sbar_intermission_cache_calls;
	result->intermission_bad_cache_path =
			bench486_sbar_intermission_bad_cache_path;
	result->deathmatch_cache_calls = bench486_sbar_deathmatch_cache_calls;
	result->deathmatch_bad_cache_path =
			bench486_sbar_deathmatch_bad_cache_path;
	result->deathmatch_bad_pic = bench486_sbar_deathmatch_bad_pic;
	result->event_count = bench486_sbar_capture_count;
	result->overflow = bench486_sbar_capture_overflow;
	for (i = 0; i < result->event_count; i++)
		result->events[i] = bench486_sbar_capture[i];
}

static int Bench486SbarIntermissionResultsMatch (
		const bench486_sbar_intermission_result_t *left,
		const bench486_sbar_intermission_result_t *right)
{
	int i;
	if (left->copy_everything != right->copy_everything ||
			left->fullupdate != right->fullupdate ||
			left->scoreboardlines != right->scoreboardlines ||
			left->intermission_cache_calls != right->intermission_cache_calls ||
			left->intermission_bad_cache_path != right->intermission_bad_cache_path ||
			left->deathmatch_cache_calls != right->deathmatch_cache_calls ||
			left->deathmatch_bad_cache_path != right->deathmatch_bad_cache_path ||
			left->deathmatch_bad_pic != right->deathmatch_bad_pic ||
			left->event_count != right->event_count ||
			left->overflow != right->overflow || left->abi != right->abi ||
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

static void Bench486SbarIntermissionCase (
		const bench486_sbar_intermission_case_t *test_case)
{
	bench486_sbar_mini_saved_t saved;
	int saved_completed_time, saved_stats[4];
	int drawn_rows, has_viewer, expected_events, passed, i;
	Bench486SbarMiniSave (&saved);
	saved_completed_time = cl.completed_time;
	saved_stats[0] = cl.stats[STAT_SECRETS];
	saved_stats[1] = cl.stats[STAT_TOTALSECRETS];
	saved_stats[2] = cl.stats[STAT_MONSTERS];
	saved_stats[3] = cl.stats[STAT_TOTALMONSTERS];
	Bench486SbarIntermissionInstall (test_case);
	Bench486SbarIntermissionRun (Bench486SbarIntermissionCallC,
			&bench486_sbar_intermission_c);
	Bench486SbarIntermissionInstall (test_case);
	Bench486SbarIntermissionRun (Bench486SbarIntermissionCallAsm,
			&bench486_sbar_intermission_asm);
	passed = Bench486SbarIntermissionResultsMatch (
			&bench486_sbar_intermission_c, &bench486_sbar_intermission_asm) &&
			bench486_sbar_intermission_asm.copy_everything == 1 &&
			bench486_sbar_intermission_asm.fullupdate == 0 &&
			bench486_sbar_intermission_asm.abi == 0 &&
			!bench486_sbar_intermission_asm.overflow;
	if (test_case->gametype == GAME_DEATHMATCH)
	{
		drawn_rows = 0;
		for (i = 0; i < test_case->maxclients; i++)
			if (test_case->present_mask & (1U << i))
				drawn_rows++;
		has_viewer = test_case->viewentity > 0 &&
			test_case->viewentity <= test_case->maxclients &&
			(test_case->present_mask & (1U << (test_case->viewentity - 1)));
		expected_events = 1 + drawn_rows * 6 + (has_viewer ? 1 : 0);
		passed = passed &&
			bench486_sbar_intermission_asm.scoreboardlines ==
				drawn_rows &&
			bench486_sbar_intermission_asm.deathmatch_cache_calls == 1 &&
			!bench486_sbar_intermission_asm.deathmatch_bad_cache_path &&
			!bench486_sbar_intermission_asm.deathmatch_bad_pic &&
			bench486_sbar_intermission_asm.intermission_cache_calls == 0 &&
			bench486_sbar_intermission_asm.event_count == expected_events &&
			bench486_sbar_intermission_asm.events[0].kind == SBAR_CAPTURE_PIC &&
			bench486_sbar_intermission_asm.events[0].x ==
				(320 - test_case->picture_width) / 2 &&
			bench486_sbar_intermission_asm.events[0].y == 8;
	}
	else
		passed = passed &&
			bench486_sbar_intermission_asm.scoreboardlines == -73 &&
			bench486_sbar_intermission_asm.intermission_cache_calls == 2 &&
			!bench486_sbar_intermission_asm.intermission_bad_cache_path &&
			bench486_sbar_intermission_asm.deathmatch_cache_calls == 0 &&
			bench486_sbar_intermission_asm.event_count >= 12 &&
			bench486_sbar_intermission_asm.events[0].kind ==
				SBAR_CAPTURE_CACHEPIC &&
			bench486_sbar_intermission_asm.events[0].x == 1 &&
			bench486_sbar_intermission_asm.events[1].kind == SBAR_CAPTURE_PIC &&
			bench486_sbar_intermission_asm.events[1].x == 64 &&
			bench486_sbar_intermission_asm.events[1].y == 24 &&
			bench486_sbar_intermission_asm.events[2].kind ==
				SBAR_CAPTURE_CACHEPIC &&
			bench486_sbar_intermission_asm.events[2].x == 2 &&
			bench486_sbar_intermission_asm.events[3].kind ==
				SBAR_CAPTURE_TRANSPIC &&
			bench486_sbar_intermission_asm.events[3].x == 0 &&
			bench486_sbar_intermission_asm.events[3].y == 56;
	if (!passed)
	{
		bench486_memory_failures++;
		Bench486ReportPrintf (
				"sbar intermission %s FAIL events %d/%d scoreboard %d/%d ABI %u/%u\n",
				test_case->name, bench486_sbar_intermission_c.event_count,
				bench486_sbar_intermission_asm.event_count,
				bench486_sbar_intermission_c.scoreboardlines,
				bench486_sbar_intermission_asm.scoreboardlines,
				bench486_sbar_intermission_c.abi,
				bench486_sbar_intermission_asm.abi);
		for (i = 0; i < bench486_sbar_intermission_c.event_count &&
				i < bench486_sbar_intermission_asm.event_count; i++)
			if (bench486_sbar_intermission_c.events[i].kind !=
					bench486_sbar_intermission_asm.events[i].kind ||
				bench486_sbar_intermission_c.events[i].x !=
					bench486_sbar_intermission_asm.events[i].x ||
				bench486_sbar_intermission_c.events[i].y !=
					bench486_sbar_intermission_asm.events[i].y ||
				bench486_sbar_intermission_c.events[i].value !=
					bench486_sbar_intermission_asm.events[i].value)
			{
				Bench486ReportPrintf (
						"sbar intermission %s event[%d] C %d,%d,%d,%lu ASM %d,%d,%d,%lu\n",
						test_case->name, i,
						bench486_sbar_intermission_c.events[i].kind,
						bench486_sbar_intermission_c.events[i].x,
						bench486_sbar_intermission_c.events[i].y,
						bench486_sbar_intermission_c.events[i].value,
						bench486_sbar_intermission_asm.events[i].kind,
						bench486_sbar_intermission_asm.events[i].x,
						bench486_sbar_intermission_asm.events[i].y,
						bench486_sbar_intermission_asm.events[i].value);
				break;
			}
	}
	else
		Bench486ReportPrintf ("sbar intermission %s PASS\n", test_case->name);
	Bench486SbarMiniRestore (&saved);
	cl.completed_time = saved_completed_time;
	cl.stats[STAT_SECRETS] = saved_stats[0];
	cl.stats[STAT_TOTALSECRETS] = saved_stats[1];
	cl.stats[STAT_MONSTERS] = saved_stats[2];
	cl.stats[STAT_TOTALMONSTERS] = saved_stats[3];
}

static void Bench486SbarIntermissionCases (void)
{
	static const bench486_sbar_intermission_case_t cases[] = {
		{ "cooperative-time-and-counts", 0, 125, 2, 7, 3, 6,
			320, 320, 4, 2, 0x000f, 0 },
		{ "minute-rollover-and-long-minutes", 0, 36000, 1234, 9,
			-1234, 12345, 640, 322, 4, 2, 0x000f, 1 },
		{ "deathmatch-full-roster-dispatch", GAME_DEATHMATCH, 59,
			0, 0, 0, 0, 320, 322, 4, 2, 0x000f, 0 },
		{ "deathmatch-empty-roster-dispatch", GAME_DEATHMATCH, 0,
			0, 0, 0, 0, 640, 300, 4, 16, 0, 1 }
	};
	bench486_sbar_mini_saved_t saved;
	qpic_t *saved_nums[2][SBAR_NUM_FRAMES];
	qpic_t *saved_colon, *saved_slash;
	int saved_completed_time, saved_stats[4];
	int saved_rank_width, saved_rank_height;
	unsigned failures_before;
	int color, frame, i;
	Bench486SbarMiniSave (&saved);
	failures_before = bench486_memory_failures;
	saved_completed_time = cl.completed_time;
	saved_stats[0] = cl.stats[STAT_SECRETS];
	saved_stats[1] = cl.stats[STAT_TOTALSECRETS];
	saved_stats[2] = cl.stats[STAT_MONSTERS];
	saved_stats[3] = cl.stats[STAT_TOTALMONSTERS];
	saved_colon = sb_colon;
	saved_slash = sb_slash;
	saved_rank_width = bench486_sbar_deathmatch_pic.width;
	saved_rank_height = bench486_sbar_deathmatch_pic.height;
	for (color = 0; color < 2; color++)
		for (frame = 0; frame < SBAR_NUM_FRAMES; frame++)
		{
			saved_nums[color][frame] = sb_nums[color][frame];
			sb_nums[color][frame] = (qpic_t *)(unsigned long)
					(0x30000 + (color * SBAR_NUM_FRAMES + frame) * 32);
		}
	sb_colon = (qpic_t *)(unsigned long)0x31000;
	sb_slash = (qpic_t *)(unsigned long)0x31020;
	bench486_sbar_first_diff_logged = 0;
	for (i = 0; i < sizeof(cases) / sizeof(cases[0]); i++)
		Bench486SbarIntermissionCase (&cases[i]);
	Bench486SbarMiniRestore (&saved);
	cl.completed_time = saved_completed_time;
	cl.stats[STAT_SECRETS] = saved_stats[0];
	cl.stats[STAT_TOTALSECRETS] = saved_stats[1];
	cl.stats[STAT_MONSTERS] = saved_stats[2];
	cl.stats[STAT_TOTALMONSTERS] = saved_stats[3];
	sb_colon = saved_colon;
	sb_slash = saved_slash;
	bench486_sbar_deathmatch_pic.width = saved_rank_width;
	bench486_sbar_deathmatch_pic.height = saved_rank_height;
	for (color = 0; color < 2; color++)
		for (frame = 0; frame < SBAR_NUM_FRAMES; frame++)
			sb_nums[color][frame] = saved_nums[color][frame];
	if (bench486_memory_failures == failures_before)
		Bench486ReportPrintf (
				"sbar intermission overlay 4 exact C/ASM normal/deathmatch/state/ABI cases PASS\n");
}

typedef struct
{
	const char *name;
	int width;
	int picture_width;
	int copy_everything;
	int fullupdate;
} bench486_sbar_finale_case_t;

static bench486_sbar_intermission_result_t bench486_sbar_finale_c;
static bench486_sbar_intermission_result_t bench486_sbar_finale_asm;

static void Bench486SbarFinaleCallC (void)
{
	Sbar_FinaleOverlay_C ();
}

static void Bench486SbarFinaleCallAsm (void)
{
	Sbar_FinaleOverlay_asm486 ();
}

static void Bench486SbarFinaleInstall (
		const bench486_sbar_finale_case_t *test_case)
{
	int i;
	vid.width = test_case->width;
	bench486_sbar_finale_pic.width = test_case->picture_width;
	scr_copyeverything = test_case->copy_everything;
	scr_fullupdate = test_case->fullupdate;
	scoreboardlines = -73;
	for (i = 0; i < MAX_SCOREBOARD; i++)
		fragsort[i] = -211 - i;
}

static void Bench486SbarFinaleCase (
		const bench486_sbar_finale_case_t *test_case)
{
	bench486_sbar_mini_saved_t saved;
	int saved_pic_width, passed, results_match, i, expected_x;
	Bench486SbarMiniSave (&saved);
	saved_pic_width = bench486_sbar_finale_pic.width;
	Bench486SbarFinaleInstall (test_case);
	Bench486SbarIntermissionRun (Bench486SbarFinaleCallC,
			&bench486_sbar_finale_c);
	Bench486SbarFinaleInstall (test_case);
	Bench486SbarIntermissionRun (Bench486SbarFinaleCallAsm,
			&bench486_sbar_finale_asm);
	/* vid.width is unsigned; preserve its modulo subtraction before / 2. */
	expected_x = (int)(((unsigned)test_case->width -
			(unsigned)test_case->picture_width) / 2U);
	results_match = Bench486SbarIntermissionResultsMatch (
			&bench486_sbar_finale_c, &bench486_sbar_finale_asm);
	passed = results_match &&
			bench486_sbar_finale_asm.copy_everything == 1 &&
			bench486_sbar_finale_asm.fullupdate == test_case->fullupdate &&
			bench486_sbar_finale_asm.scoreboardlines == -73 &&
			bench486_sbar_finale_asm.intermission_cache_calls == 1 &&
			!bench486_sbar_finale_asm.intermission_bad_cache_path &&
			bench486_sbar_finale_asm.deathmatch_cache_calls == 0 &&
			bench486_sbar_finale_asm.event_count == 2 &&
			bench486_sbar_finale_asm.events[0].kind == SBAR_CAPTURE_CACHEPIC &&
			bench486_sbar_finale_asm.events[0].x == 3 &&
			bench486_sbar_finale_asm.events[0].y == 0 &&
			bench486_sbar_finale_asm.events[0].value == 0 &&
			bench486_sbar_finale_asm.events[1].kind == SBAR_CAPTURE_TRANSPIC &&
			bench486_sbar_finale_asm.events[1].x == expected_x &&
			bench486_sbar_finale_asm.events[1].y == 16 &&
			bench486_sbar_finale_asm.events[1].value ==
					(unsigned long)&bench486_sbar_finale_pic &&
			bench486_sbar_finale_asm.abi == 0 &&
			!bench486_sbar_finale_asm.overflow;
	for (i = 0; i < MAX_SCOREBOARD && passed; i++)
		if (bench486_sbar_finale_asm.fragsort[i] != -211 - i)
			passed = 0;
	if (!passed)
	{
		bench486_memory_failures++;
		Bench486ReportPrintf (
				"sbar finale %s FAIL events %d/%d C/ASM x %d/%d expected %d fullupdate %d/%d ABI %u/%u\n",
				test_case->name, bench486_sbar_finale_c.event_count,
				bench486_sbar_finale_asm.event_count,
				bench486_sbar_finale_c.event_count > 1 ?
						bench486_sbar_finale_c.events[1].x : 0,
				bench486_sbar_finale_asm.event_count > 1 ?
						bench486_sbar_finale_asm.events[1].x : 0,
				expected_x, bench486_sbar_finale_c.fullupdate,
				bench486_sbar_finale_asm.fullupdate,
				bench486_sbar_finale_c.abi,
				bench486_sbar_finale_asm.abi);
	}
	else
		Bench486ReportPrintf ("sbar finale %s PASS\n", test_case->name);
	Bench486SbarMiniRestore (&saved);
	bench486_sbar_finale_pic.width = saved_pic_width;
}

static void Bench486SbarFinaleCases (void)
{
	static const bench486_sbar_finale_case_t cases[] = {
		{ "standard-centered", 320, 272, -13, -17 },
		{ "wide-centered", 640, 320, 0, 0 },
		{ "unsigned-odd-width-difference", 191, 200, 9, 31 },
		{ "unsigned-one-width-difference", 639, 640, -1, -7 },
		{ "positive-odd-truncation", 641, 640, 42, 12 },
		{ "unsigned-even-width-difference", 318, 320, -99, 88 }
	};
	bench486_sbar_mini_saved_t saved;
	int saved_pic_width, i;
	unsigned failures_before;
	Bench486SbarMiniSave (&saved);
	saved_pic_width = bench486_sbar_finale_pic.width;
	failures_before = bench486_memory_failures;
	bench486_sbar_first_diff_logged = 0;
	for (i = 0; i < sizeof(cases) / sizeof(cases[0]); i++)
		Bench486SbarFinaleCase (&cases[i]);
	Bench486SbarMiniRestore (&saved);
	bench486_sbar_finale_pic.width = saved_pic_width;
	if (bench486_memory_failures == failures_before)
		Bench486ReportPrintf (
				"sbar finale overlay 6 exact C/ASM centering/state/ABI cases PASS\n");
}

typedef struct
{
	const char *name;
	int gametype;
	unsigned width;
	unsigned height;
	double time;
	int monsters;
	int total_monsters;
	int secrets;
	int total_secrets;
	const char *levelname;
} bench486_sbar_solo_case_t;

typedef struct
{
	int gametype;
	unsigned width;
	unsigned height;
	double time;
	int monsters;
	int total_monsters;
	int secrets;
	int total_secrets;
	char levelname[40];
} bench486_sbar_solo_saved_t;

static void Bench486SbarSoloInstall (
		const bench486_sbar_solo_case_t *test_case)
{
	cl.gametype = test_case->gametype;
	vid.width = test_case->width;
	vid.height = test_case->height;
	cl.time = test_case->time;
	cl.stats[STAT_MONSTERS] = test_case->monsters;
	cl.stats[STAT_TOTALMONSTERS] = test_case->total_monsters;
	cl.stats[STAT_SECRETS] = test_case->secrets;
	cl.stats[STAT_TOTALSECRETS] = test_case->total_secrets;
	Q_memset (cl.levelname, 0, sizeof (cl.levelname));
	strncpy (cl.levelname, test_case->levelname, sizeof (cl.levelname) - 1);
}

static void Bench486SbarSoloScoreboardCases (void)
{
	static const bench486_sbar_solo_case_t cases[] = {
		{ "wide centered counters", 0, 640, 480, 3661.25,
			12, 200, 3, 30, "E1M1: The Slipgate Complex" },
		{ "deathmatch negative time", GAME_DEATHMATCH, 320, 200, -61.75,
			-1, 12, 101, -2, "" },
		{ "wide long counters", 0, 800, 600, 359999.875,
			1000, 1000, 999, 999,
			"The Very Long Level Name Checks Centering" },
		{ "negative fractional time", 0, 320, 200, -1.75,
			0, 0, 0, 0, "Epilogue" }
	};
	bench486_sbar_solo_saved_t saved;
	bench486_sbar_draw_snapshot_t c, a;
	int i, event, passed, failures_before;

	failures_before = bench486_memory_failures;
	saved.gametype = cl.gametype;
	saved.width = vid.width;
	saved.height = vid.height;
	saved.time = cl.time;
	saved.monsters = cl.stats[STAT_MONSTERS];
	saved.total_monsters = cl.stats[STAT_TOTALMONSTERS];
	saved.secrets = cl.stats[STAT_SECRETS];
	saved.total_secrets = cl.stats[STAT_TOTALSECRETS];
	Q_memcpy (saved.levelname, cl.levelname, sizeof (saved.levelname));
	for (i = 0; i < sizeof (cases) / sizeof (cases[0]); i++)
	{
		Bench486SbarSoloInstall (&cases[i]);
		Bench486SbarDrawResetCapture ();
		if (cases[i].gametype == GAME_DEATHMATCH)
			Sbar_SoloScoreboard_C ();
		else
			Sbar_DrawScoreboard_C ();
		Bench486SbarDrawCaptureSnapshot (&c);

		Bench486SbarSoloInstall (&cases[i]);
		Bench486SbarDrawResetCapture ();
		if (cases[i].gametype == GAME_DEATHMATCH)
			Sbar_SoloScoreboard_asm486 ();
		else
			Sbar_DrawScoreboard_asm486 ();
		Bench486SbarDrawCaptureSnapshot (&a);

		passed = Bench486SbarDrawSnapshotsMatch (&c, &a) &&
				c.event_count == 4;
		if (!passed)
		{
			bench486_memory_failures++;
			Bench486ReportPrintf (
					"sbar solo scoreboard %s C/ASM events %d/%d FAIL\n",
					cases[i].name, c.event_count, a.event_count);
			for (event = 0; event < c.event_count && event < a.event_count; event++)
				if (c.events[event].kind != a.events[event].kind ||
						Q_memcmp ((void *)c.events[event].args,
							(void *)a.events[event].args, sizeof (c.events[event].args)))
				{
					Bench486ReportPrintf (
							"  first diff event %d kind %d/%d xy %lu,%lu/%lu,%lu hash %08lx/%08lx length %lu/%lu\n",
							event, c.events[event].kind, a.events[event].kind,
							c.events[event].args[0], c.events[event].args[1],
							a.events[event].args[0], a.events[event].args[1],
							c.events[event].args[2], a.events[event].args[2],
							c.events[event].args[3], a.events[event].args[3]);
					break;
				}
		}
		else
			Bench486ReportPrintf (
					"sbar solo scoreboard %s exact C/ASM text/position PASS\n",
					cases[i].name);
	}
	cl.gametype = saved.gametype;
	vid.width = saved.width;
	vid.height = saved.height;
	cl.time = saved.time;
	cl.stats[STAT_MONSTERS] = saved.monsters;
	cl.stats[STAT_TOTALMONSTERS] = saved.total_monsters;
	cl.stats[STAT_SECRETS] = saved.secrets;
	cl.stats[STAT_TOTALSECRETS] = saved.total_secrets;
	Q_memcpy (cl.levelname, saved.levelname, sizeof (saved.levelname));
	if (bench486_memory_failures == failures_before)
		Bench486ReportPrintf (
				"sbar solo scoreboard 4 exact C/ASM formatting/position cases PASS\n");
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
	Bench486SbarDeathmatchCases ();
	Bench486SbarIntermissionCases ();
	Bench486SbarFinaleCases ();
	Bench486SbarSoloScoreboardCases ();
}

#endif /* BENCH486 && ASM486_SBAR_DRAW_FIXTURE */
#endif /* BENCH486_SBAR_DRAW_H */
