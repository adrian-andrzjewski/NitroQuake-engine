/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
#ifndef BENCH486_VESAPALETTE_H
#define BENCH486_VESAPALETTE_H

#include "video/asm_vesapalette.h"

#define BENCH486_VP_GUARD_BYTES 16

typedef struct
{
	byte before[BENCH486_VP_GUARD_BYTES];
	byte bytes[VP_SOURCE_BYTES];
	byte after[BENCH486_VP_GUARD_BYTES];
} bench486_vesa_palette_source_t;

typedef struct
{
	byte before[BENCH486_VP_GUARD_BYTES];
	byte bytes[VP_DESTINATION_BYTES];
	byte after[BENCH486_VP_GUARD_BYTES];
} bench486_vesa_palette_destination_t;

static int Bench486VesaPaletteCases (void)
{
	static bench486_vesa_palette_source_t source;
	static bench486_vesa_palette_destination_t expected, actual;
	static byte guards[BENCH486_VP_GUARD_BYTES];
	unsigned arguments[2];
	int pattern, i, j, failures;
	unsigned abi;

	failures = 0;
	Q_memset (guards, 0xa5, sizeof(guards));
	for (pattern = 0; pattern < 4; pattern++)
	{
		Q_memset (&source, 0, sizeof(source));
		Q_memset (&expected, 0xcc, sizeof(expected));
		Q_memset (&actual, 0xcc, sizeof(actual));
		Q_memset (source.before, 0xa5, sizeof(source.before));
		Q_memset (source.after, 0xa5, sizeof(source.after));
		Q_memset (expected.before, 0xa5, sizeof(expected.before));
		Q_memset (expected.after, 0xa5, sizeof(expected.after));
		Q_memset (actual.before, 0xa5, sizeof(actual.before));
		Q_memset (actual.after, 0xa5, sizeof(actual.after));
		for (i = 0; i < VP_SOURCE_BYTES; i++)
		{
			switch (pattern)
			{
			case 0: source.bytes[i] = (byte)i; break;
			case 1: source.bytes[i] = (byte)(i * 37 + (i >> 2) * 19 + 0x91); break;
			case 2: source.bytes[i] = (i & 1) ? 255 : 0; break;
			default: source.bytes[i] = (byte)(i * 53 + 3); break;
			}
		}

		VID_BuildVESAPalette_C (expected.bytes, source.bytes);
		arguments[0] = (unsigned)actual.bytes;
		arguments[1] = (unsigned)source.bytes;
		abi = Bench486Call_asm486 (
				(void (*)(void))VID_BuildVESAPalette_asm486, 2, arguments, NULL);
		if (abi)
			failures |= 1;
		if (Q_memcmp (actual.bytes, expected.bytes, sizeof(actual.bytes)))
			failures |= 2;
		if (Q_memcmp (source.before, guards, sizeof(source.before)) ||
			Q_memcmp (source.after, guards, sizeof(source.after)) ||
			Q_memcmp (expected.before, guards, sizeof(expected.before)) ||
			Q_memcmp (expected.after, guards, sizeof(expected.after)) ||
			Q_memcmp (actual.before, guards, sizeof(actual.before)) ||
			Q_memcmp (actual.after, guards, sizeof(actual.after)))
			failures |= 4;

		/* Check the channel order, six-bit reduction and zero filler byte. */
		for (j = 0; j < VP_PALETTE_ENTRIES; j++)
		{
			if (actual.bytes[j * 4] != (byte)(source.bytes[j * 3 + 2] >> 2) ||
				actual.bytes[j * 4 + 1] != (byte)(source.bytes[j * 3 + 1] >> 2) ||
				actual.bytes[j * 4 + 2] != (byte)(source.bytes[j * 3] >> 2) ||
				actual.bytes[j * 4 + 3] != 0)
				failures |= 8;
		}
	}

	return failures;
}

#endif
