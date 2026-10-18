#ifndef BENCH486_VESADEFAULTMODE_H
#define BENCH486_VESADEFAULTMODE_H

#include "asm_vesadefaultmode.h"

#define BENCH486_VD_GUARD_BYTES 16
#define BENCH486_VD_MODE_COUNT 6

typedef struct
{
	byte before[BENCH486_VD_GUARD_BYTES];
	vmode_t modes[BENCH486_VD_MODE_COUNT];
	byte after[BENCH486_VD_GUARD_BYTES];
} bench486_vesa_default_modes_t;

typedef struct
{
	byte before[BENCH486_VD_GUARD_BYTES];
	vesa_info_t info[BENCH486_VD_MODE_COUNT];
	byte after[BENCH486_VD_GUARD_BYTES];
} bench486_vesa_default_info_t;

static int Bench486VesaDefaultSetMode (viddef_t *vid, vmode_t *mode)
{
	UNUSED (vid);
	UNUSED (mode);
	return 1;
}

static int Bench486VesaOtherSetMode (viddef_t *vid, vmode_t *mode)
{
	UNUSED (vid);
	UNUSED (mode);
	return 1;
}

static void Bench486VesaDefaultBuild (bench486_vesa_default_modes_t *modes,
		bench486_vesa_default_info_t *info, int count, int linear_mask,
		int candidate_mask, int wrong_size_mask)
{
	int i;
	Q_memset (modes, 0, sizeof (*modes));
	Q_memset (info, 0, sizeof (*info));
	Q_memset (modes->before, 0xa5, sizeof (modes->before));
	Q_memset (modes->after, 0xa5, sizeof (modes->after));
	Q_memset (info->before, 0x5a, sizeof (info->before));
	Q_memset (info->after, 0x5a, sizeof (info->after));
	for (i = 0; i < count; i++)
	{
		modes->modes[i].pnext = i + 1 < count ? &modes->modes[i + 1] : NULL;
		modes->modes[i].width = (wrong_size_mask & (1 << i)) ? 640 : 320;
		modes->modes[i].height = (wrong_size_mask & (1 << i)) ? 400 : 200;
		modes->modes[i].setmode = (candidate_mask & (1 << i)) ?
			Bench486VesaDefaultSetMode : Bench486VesaOtherSetMode;
		modes->modes[i].pextradata = &info->info[i];
		info->info[i].linear = (linear_mask & (1 << i)) != 0;
	}
}

static int Bench486VesaDefaultOne (int count, int linear_mask,
		int candidate_mask, int wrong_size_mask, int expected)
{
	static bench486_vesa_default_modes_t modes;
	static bench486_vesa_default_info_t info;
	static bench486_vesa_default_modes_t saved_modes;
	static bench486_vesa_default_info_t saved_info;
	vmode_t *list;
	unsigned arguments[2], abi;
	int c_result, asm_result, failures;

	Bench486VesaDefaultBuild (&modes, &info, count, linear_mask,
			candidate_mask, wrong_size_mask);
	Q_memcpy (&saved_modes, &modes, sizeof (modes));
	Q_memcpy (&saved_info, &info, sizeof (info));
	list = count ? &modes.modes[0] : NULL;
	c_result = VID_SelectVesaDefaultMode_C (list, Bench486VesaDefaultSetMode);
	asm_result = VID_SelectVesaDefaultMode_asm486 (list,
			Bench486VesaDefaultSetMode);
	arguments[0] = (unsigned)list;
	arguments[1] = (unsigned)Bench486VesaDefaultSetMode;
	abi = Bench486Call_asm486 ((void (*)(void))VID_SelectVesaDefaultMode_asm486,
			2, arguments, NULL);
	failures = 0;
	if (c_result != expected || asm_result != expected || c_result != asm_result)
		failures |= 1;
	if (abi)
		failures |= 2;
	if (Q_memcmp (&modes, &saved_modes, sizeof (modes)) ||
		Q_memcmp (&info, &saved_info, sizeof (info)))
		failures |= 4;
	return failures;
}

static int Bench486VesaDefaultModeCases (void)
{
	int failures;
	failures = 0;
	failures |= Bench486VesaDefaultOne (0, 0, 0, 0, 0);
	/* Non-VESA mode with matching dimensions is ignored. */
	failures |= Bench486VesaDefaultOne (1, 1, 0, 0, 0);
	/* Width/height mismatches and a different setter are skipped. */
	failures |= Bench486VesaDefaultOne (4, 0, 8, 3, 3);
	/* Keep the first banked fallback unless a later linear mode is found. */
	failures |= Bench486VesaDefaultOne (5, 16, 22, 0, 4);
	failures |= Bench486VesaDefaultOne (5, 0, 6, 0, 1);
	/* A linear candidate wins immediately, including when it is index zero. */
	failures |= Bench486VesaDefaultOne (5, 5, 7, 0, 0);
	return failures;
}

#endif
