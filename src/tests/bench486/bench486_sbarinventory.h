/* Exact C/assembly parity for status-bar inventory composition. */
/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
#ifndef BENCH486_SBARINVENTORY_H
#define BENCH486_SBARINVENTORY_H

#include "client/asm_sbar.h"

#if defined(BENCH486) && defined(ASM486_SBAR_INVENTORY) && \
		defined(ASM486_SBAR_PRIMITIVES)

#define BENCH486_SBAR_INVENTORY_SCENARIOS 5

extern int sb_updates;
extern qboolean rogue, hipnotic;
extern qpic_t *sb_ibar;
extern qpic_t *sb_weapons[7][8];
extern qpic_t *sb_items[32];
extern qpic_t *sb_sigil[4];
extern qpic_t *rsb_invbar[2];
extern qpic_t *rsb_weapons[5];
extern qpic_t *rsb_items[2];
extern qpic_t *hsb_weapons[7][5];
extern qpic_t *hsb_items[2];
extern int hipweapons[4];

static int bench486_sbar_inventory_first_failure;

typedef struct
{
	int updates;
	int gametype;
	int width;
	int height;
	int items;
	int stats[32];
	double time;
	float item_gettime[32];
	qboolean rogue_game;
	qboolean hipnotic_game;
	qpic_t *ibar;
	qpic_t *weapons[7][8];
	qpic_t *items_pic[32];
	qpic_t *sigils[4];
	qpic_t *rogue_invbar[2];
	qpic_t *rogue_weapons[5];
	qpic_t *rogue_items[2];
	qpic_t *hip_weapons[7][5];
	qpic_t *hip_items[2];
	int hip_weapon_bits[4];
} bench486_sbar_inventory_saved_t;

static void Bench486SbarInventorySave (
		bench486_sbar_inventory_saved_t *saved)
{
	saved->updates = sb_updates;
	saved->gametype = cl.gametype;
	saved->width = vid.width;
	saved->height = vid.height;
	saved->items = cl.items;
	Q_memcpy (saved->stats, cl.stats, sizeof (saved->stats));
	saved->time = cl.time;
	Q_memcpy (saved->item_gettime, cl.item_gettime,
			sizeof (saved->item_gettime));
	saved->rogue_game = rogue;
	saved->hipnotic_game = hipnotic;
	saved->ibar = sb_ibar;
	Q_memcpy (saved->weapons, sb_weapons, sizeof (saved->weapons));
	Q_memcpy (saved->items_pic, sb_items, sizeof (saved->items_pic));
	Q_memcpy (saved->sigils, sb_sigil, sizeof (saved->sigils));
	Q_memcpy (saved->rogue_invbar, rsb_invbar,
			sizeof (saved->rogue_invbar));
	Q_memcpy (saved->rogue_weapons, rsb_weapons,
			sizeof (saved->rogue_weapons));
	Q_memcpy (saved->rogue_items, rsb_items,
			sizeof (saved->rogue_items));
	Q_memcpy (saved->hip_weapons, hsb_weapons,
			sizeof (saved->hip_weapons));
	Q_memcpy (saved->hip_items, hsb_items, sizeof (saved->hip_items));
	Q_memcpy (saved->hip_weapon_bits, hipweapons,
			sizeof (saved->hip_weapon_bits));
}

static void Bench486SbarInventoryRestore (
		bench486_sbar_inventory_saved_t *saved)
{
	sb_updates = saved->updates;
	cl.gametype = saved->gametype;
	vid.width = saved->width;
	vid.height = saved->height;
	cl.items = saved->items;
	Q_memcpy (cl.stats, saved->stats, sizeof (saved->stats));
	cl.time = saved->time;
	Q_memcpy (cl.item_gettime, saved->item_gettime,
			sizeof (saved->item_gettime));
	rogue = saved->rogue_game;
	hipnotic = saved->hipnotic_game;
	sb_ibar = saved->ibar;
	Q_memcpy (sb_weapons, saved->weapons, sizeof (saved->weapons));
	Q_memcpy (sb_items, saved->items_pic, sizeof (saved->items_pic));
	Q_memcpy (sb_sigil, saved->sigils, sizeof (saved->sigils));
	Q_memcpy (rsb_invbar, saved->rogue_invbar,
			sizeof (saved->rogue_invbar));
	Q_memcpy (rsb_weapons, saved->rogue_weapons,
			sizeof (saved->rogue_weapons));
	Q_memcpy (rsb_items, saved->rogue_items,
			sizeof (saved->rogue_items));
	Q_memcpy (hsb_weapons, saved->hip_weapons,
			sizeof (saved->hip_weapons));
	Q_memcpy (hsb_items, saved->hip_items, sizeof (saved->hip_items));
	Q_memcpy (hipweapons, saved->hip_weapon_bits,
			sizeof (saved->hip_weapon_bits));
}

static qpic_t *Bench486SbarInventoryPic (int index)
{
	return (qpic_t *)(unsigned long)(0x20000 + index * 32);
}

static void Bench486SbarInventoryInstallAssets (void)
{
	int i, j;
	int index;

	index = 0;
	sb_ibar = Bench486SbarInventoryPic (index++);
	for (i = 0; i < 7; i++)
		for (j = 0; j < 8; j++)
			sb_weapons[i][j] = Bench486SbarInventoryPic (index++);
	for (i = 0; i < 32; i++)
		sb_items[i] = Bench486SbarInventoryPic (index++);
	for (i = 0; i < 4; i++)
		sb_sigil[i] = Bench486SbarInventoryPic (index++);
	for (i = 0; i < 2; i++)
		rsb_invbar[i] = Bench486SbarInventoryPic (index++);
	for (i = 0; i < 5; i++)
		rsb_weapons[i] = Bench486SbarInventoryPic (index++);
	for (i = 0; i < 2; i++)
		rsb_items[i] = Bench486SbarInventoryPic (index++);
	for (i = 0; i < 7; i++)
		for (j = 0; j < 5; j++)
			hsb_weapons[i][j] = Bench486SbarInventoryPic (index++);
	for (i = 0; i < 2; i++)
		hsb_items[i] = Bench486SbarInventoryPic (index++);
}

static void Bench486SbarInventoryInstallScenario (int scenario)
{
	int i;

	cl.gametype = (scenario & 1) ? GAME_DEATHMATCH : 0;
	vid.width = (scenario & 1) ? 640 : 320;
	vid.height = 200 + scenario * 40;
	cl.time = 100.0 + scenario * 0.125;
	cl.items = 0;
	Q_memset (cl.stats, 0, sizeof (cl.stats));
	Q_memset (cl.item_gettime, 0, sizeof (cl.item_gettime));
	rogue = false;
	hipnotic = false;
	sb_updates = 17;

	cl.stats[STAT_ACTIVEWEAPON] = IT_SHOTGUN << 4;
	cl.stats[STAT_SHELLS] = 0;
	cl.stats[STAT_SHELLS + 1] = 7;
	cl.stats[STAT_SHELLS + 2] = 42;
	cl.stats[STAT_SHELLS + 3] = 999;
	for (i = 0; i < 32; i++)
		cl.item_gettime[i] = (float)(cl.time - 10.0);

	switch (scenario)
	{
	case 0:
		cl.stats[STAT_ACTIVEWEAPON] = 0;
		break;
	case 1:
		cl.items = 0x7f | (0x3f << 17) | (0x0f << 28);
		for (i = 0; i < 7; i++)
			cl.item_gettime[i] = (float)(cl.time - (0.25 + 0.25 * i));
		cl.item_gettime[18] = (float)(cl.time - 1.75);
		cl.item_gettime[20] = (float)(cl.time - 1.0);
		break;
	case 2:
		hipnotic = true;
		cl.items = 0x7f | (1 << 23) | (1 << 7) | (1 << 4) |
				(1 << 16) | (0x3f << 17) | (3 << 24) | (0x0f << 28);
		cl.stats[STAT_ACTIVEWEAPON] = 1 << HIT_LASER_CANNON_BIT;
		cl.item_gettime[23] = (float)(cl.time - 0.5);
		cl.item_gettime[7] = (float)(cl.time - 1.5);
		cl.item_gettime[4] = (float)(cl.time - 2.0);
		cl.item_gettime[16] = (float)(cl.time - 0.75);
		cl.item_gettime[24] = (float)(cl.time - 1.0);
		break;
	case 3:
		rogue = true;
		cl.items = 0x7f | (0x3f << 17) | (0x03 << 29) |
				RIT_SHELLS | RIT_NAILS | RIT_ROCKETS | RIT_CELLS |
				RIT_ARMOR1 | RIT_ARMOR2 | RIT_ARMOR3 | RIT_LAVA_NAILS;
		cl.stats[STAT_ACTIVEWEAPON] = RIT_LAVA_NAILGUN << 3;
		cl.item_gettime[29] = (float)(cl.time - 1.0);
		cl.item_gettime[30] = (float)(cl.time - 2.0);
		break;
	default:
		hipnotic = true;
		rogue = true;
		cl.items = 0x7f | (1 << 23) | (1 << 7) | (1 << 4) |
				(1 << 16) | (0x3f << 17) | (3 << 24) | (0x0f << 28) |
				(0x03 << 29) | RIT_LAVA_NAILS;
		cl.stats[STAT_ACTIVEWEAPON] = RIT_LAVA_NAILGUN << 4;
		cl.item_gettime[17] = (float)(cl.time - 1.0);
		cl.item_gettime[24] = (float)(cl.time - 1.5);
		cl.item_gettime[29] = (float)(cl.time - 0.5);
		break;
	}
}

static int Bench486SbarInventoryRunPair (int scenario, int rounding)
{
	bench486_sbar_capture_t expected[BENCH486_SBAR_CAPTURE_CAPACITY];
	int expected_count, expected_overflow, expected_updates;
	int i, passed;
	unsigned short old_cw, test_cw;

	Bench486SbarInventoryInstallScenario (scenario);
	__asm__ __volatile__ ("fnstcw %0" : "=m" (old_cw));
	test_cw = (unsigned short)((old_cw & 0xf3ff) | ((rounding & 3) << 10));
	__asm__ __volatile__ ("fldcw %0" : : "m" (test_cw));

	bench486_sbar_capture_active = 1;
	Bench486SbarResetCapture ();
	Sbar_DrawInventory_C ();
	expected_count = bench486_sbar_capture_count;
	expected_overflow = bench486_sbar_capture_overflow;
	expected_updates = sb_updates;
	for (i = 0; i < expected_count; i++)
		expected[i] = bench486_sbar_capture[i];

	sb_updates = 17;
	Bench486SbarResetCapture ();
	__asm__ __volatile__ ("fldcw %0" : : "m" (test_cw));
	Sbar_DrawInventory_asm486 ();
	bench486_sbar_capture_active = 0;
	__asm__ __volatile__ ("fldcw %0" : : "m" (old_cw));

	passed = !expected_overflow && !bench486_sbar_capture_overflow &&
			expected_count == bench486_sbar_capture_count &&
			expected_updates == sb_updates;
	for (i = 0; passed && i < expected_count; i++)
		if (expected[i].kind != bench486_sbar_capture[i].kind ||
			expected[i].x != bench486_sbar_capture[i].x ||
			expected[i].y != bench486_sbar_capture[i].y ||
			expected[i].value != bench486_sbar_capture[i].value)
			passed = 0;

	if (!passed && !bench486_sbar_inventory_first_failure)
	{
		Bench486Printf (
				"sbar inventory scenario %d rounding %d C/ASM events %d/%d updates %d/%d overflow %d/%d FAIL\n",
				scenario, rounding, expected_count,
				bench486_sbar_capture_count, expected_updates, sb_updates,
				expected_overflow, bench486_sbar_capture_overflow);
		bench486_sbar_inventory_first_failure = 1;
	}
	return passed;
}

static void Bench486SbarInventoryCases (void)
{
	bench486_sbar_inventory_saved_t saved;
	int scenario, rounding, failures, cases;

	Bench486SbarInventorySave (&saved);
	Bench486SbarInventoryInstallAssets ();
	failures = 0;
	cases = 0;
	for (rounding = 0; rounding < 4; rounding++)
		for (scenario = 0;
			scenario < BENCH486_SBAR_INVENTORY_SCENARIOS; scenario++)
		{
			cases++;
			failures += !Bench486SbarInventoryRunPair (scenario, rounding);
		}
	bench486_sbar_capture_active = 0;
	Bench486SbarInventoryRestore (&saved);
	if (failures)
		bench486_memory_failures += failures;
	Bench486Printf (
			"sbar inventory C/ASM draw events and state %s (%d cases, four x87 rounding modes, %d failures)\n",
			failures ? "FAIL" : "PASS", cases, failures);
}

#endif /* BENCH486 && ASM486_SBAR_INVENTORY && ASM486_SBAR_PRIMITIVES */

#endif /* BENCH486_SBARINVENTORY_H */
