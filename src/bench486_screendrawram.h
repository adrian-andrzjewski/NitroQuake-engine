/* Exact C/assembly framebuffer, state and ABI parity for SCR_DrawRam. */
#ifndef BENCH486_SCREEN_DRAW_RAM_H
#define BENCH486_SCREEN_DRAW_RAM_H

#if defined(BENCH486) && defined(ASM486_SCREEN_DRAW_RAM)

#include "asm_screendrawram.h"

#define BSDR_CASE_COUNT 7U
#define BSDR_CONTROL_COUNT 12U
#define BSDR_FRAME_BYTES 42000U
#define BSDR_PICTURE_BYTES 512U
#define BSDR_GUARD_WORDS 8U

extern unsigned Bench486Call_asm486 (void (*function)(void), unsigned words,
		const unsigned *arguments, float *float_return);
extern viddef_t vid;
extern cvar_t scr_showram;
extern qpic_t *scr_ram;
extern vrect_t scr_vrect;
extern qboolean r_cache_thrash;
extern int r_pixbytes;
extern unsigned short d_8to16table[256];

typedef struct
{
	const char *name;
	unsigned show_bits;
	int cache_thrash;
	int view_x, view_y;
	unsigned picture_width, picture_height;
	unsigned pixel_bytes;
	unsigned row_padding;
} bench486_screen_drawram_case_t;

typedef struct
{
	unsigned before[BSDR_GUARD_WORDS];
	byte pixels[BSDR_FRAME_BYTES];
	unsigned after[BSDR_GUARD_WORDS];
} bench486_screen_drawram_frame_t;

typedef struct
{
	unsigned before[4];
	int width, height;
	byte pixels[BSDR_PICTURE_BYTES];
	unsigned after[4];
} bench486_screen_drawram_picture_t;

typedef struct
{
	unsigned show_bits;
	unsigned cache_thrash;
	unsigned ram_pointer;
	int view_x, view_y;
	unsigned abi;
	unsigned short cw_before, cw_after;
	unsigned short top_before, top_after;
} bench486_screen_drawram_result_t;

static bench486_screen_drawram_frame_t bench486_screen_drawram_frame;
static bench486_screen_drawram_picture_t bench486_screen_drawram_picture;
static byte bench486_screen_drawram_expected[BSDR_FRAME_BYTES];
static viddef_t bench486_screen_drawram_saved_vid;
static cvar_t bench486_screen_drawram_saved_showram;
static qpic_t *bench486_screen_drawram_saved_ram;
static vrect_t bench486_screen_drawram_saved_vrect;
static qboolean bench486_screen_drawram_saved_cache_thrash;
static int bench486_screen_drawram_saved_pixbytes;
static unsigned short bench486_screen_drawram_saved_palette[256];

static unsigned short Bench486ScreenDrawRamGetControlWord (void)
{
	unsigned short word;
	__asm__ __volatile__ ("fnstcw %0" : "=m" (word));
	return word;
}

static unsigned short Bench486ScreenDrawRamGetStatusWord (void)
{
	unsigned short word;
	__asm__ __volatile__ ("fnstsw %0" : "=m" (word));
	return word;
}

static void Bench486ScreenDrawRamSetControlWord (unsigned short word)
{
	__asm__ __volatile__ ("fldcw %0" : : "m" (word));
}

static unsigned Bench486ScreenDrawRamGuardsIntact (void)
{
	unsigned i;

	for (i = 0; i < BSDR_GUARD_WORDS; i++)
		if (bench486_screen_drawram_frame.before[i] != 0x486d5100U + i ||
				bench486_screen_drawram_frame.after[i] != 0xa14c9200U + i)
			return 0;
	for (i = 0; i < 4; i++)
		if (bench486_screen_drawram_picture.before[i] != 0x486d4100U + i ||
				bench486_screen_drawram_picture.after[i] != 0x5a13d900U + i)
			return 0;
	return 1;
}

static void Bench486ScreenDrawRamPrepare (
		const bench486_screen_drawram_case_t *test_case, unsigned case_index)
{
	unsigned i, source, x, y, bytes, rowbytes;
	unsigned draw;
	unsigned short pixel;
	union { unsigned bits; float value; } show;

	Q_memset (&vid, 0, sizeof(vid));
	bytes = test_case->pixel_bytes;
	rowbytes = 320U * bytes + test_case->row_padding;
	vid.buffer = bench486_screen_drawram_frame.pixels;
	vid.width = 320;
	vid.height = 64;
	vid.rowbytes = rowbytes;
	r_pixbytes = (int)bytes;

	show.bits = test_case->show_bits;
	scr_showram.value = show.value;
	r_cache_thrash = test_case->cache_thrash;
	scr_vrect.x = test_case->view_x;
	scr_vrect.y = test_case->view_y;
	scr_vrect.width = 1;
	scr_vrect.height = 1;
	scr_vrect.pnext = NULL;

	for (i = 0; i < BSDR_GUARD_WORDS; i++)
	{
		bench486_screen_drawram_frame.before[i] = 0x486d5100U + i;
		bench486_screen_drawram_frame.after[i] = 0xa14c9200U + i;
	}
	for (i = 0; i < 4; i++)
	{
		bench486_screen_drawram_picture.before[i] = 0x486d4100U + i;
		bench486_screen_drawram_picture.after[i] = 0x5a13d900U + i;
	}
	bench486_screen_drawram_picture.width = (int)test_case->picture_width;
	bench486_screen_drawram_picture.height = (int)test_case->picture_height;
	for (i = 0; i < BSDR_PICTURE_BYTES; i++)
		bench486_screen_drawram_picture.pixels[i] =
				(byte)(i * 29U + case_index * 43U + 7U);
	scr_ram = (qpic_t *)&bench486_screen_drawram_picture.width;

	for (i = 0; i < BSDR_FRAME_BYTES; i++)
		bench486_screen_drawram_frame.pixels[i] =
				(byte)(i * 37U + case_index * 19U + bytes * 11U);
	Q_memcpy (bench486_screen_drawram_expected,
			bench486_screen_drawram_frame.pixels, BSDR_FRAME_BYTES);
	for (i = 0; i < 256; i++)
		d_8to16table[i] = (unsigned short)(i * 251U + case_index * 0x153U + 0x4861U);

	/* Build an independent exact expectation for Draw_Pic's 8/16-bit stores. */
	draw = (test_case->show_bits & 0x7fffffffU) != 0 &&
			test_case->cache_thrash != 0;
	if (!draw)
		return;
	x = (unsigned)(test_case->view_x + 32);
	y = (unsigned)test_case->view_y;
	if (x + test_case->picture_width > 320U ||
			y + test_case->picture_height > 64U ||
			test_case->picture_width * test_case->picture_height > BSDR_PICTURE_BYTES)
	{
		bench486_memory_failures++;
		return;
	}
	for (y = 0; y < test_case->picture_height; y++)
		for (x = 0; x < test_case->picture_width; x++)
		{
			source = y * test_case->picture_width + x;
			if (bytes == 1U)
				bench486_screen_drawram_expected[
						(test_case->view_y + (int)y) * (int)rowbytes +
						test_case->view_x + 32 + (int)x] =
						bench486_screen_drawram_picture.pixels[source];
			else
			{
				pixel = d_8to16table[
						bench486_screen_drawram_picture.pixels[source]];
				i = ((unsigned)test_case->view_y + y) * rowbytes +
						(unsigned)(test_case->view_x + 32 + (int)x) * 2U;
				bench486_screen_drawram_expected[i] = (byte)pixel;
				bench486_screen_drawram_expected[i + 1U] = (byte)(pixel >> 8);
			}
		}
}

static void Bench486ScreenDrawRamSaveState (void)
{
	Q_memcpy (&bench486_screen_drawram_saved_vid, &vid, sizeof(vid));
	Q_memcpy (&bench486_screen_drawram_saved_showram, &scr_showram,
			sizeof(scr_showram));
	bench486_screen_drawram_saved_ram = scr_ram;
	Q_memcpy (&bench486_screen_drawram_saved_vrect, &scr_vrect,
			sizeof(scr_vrect));
	bench486_screen_drawram_saved_cache_thrash = r_cache_thrash;
	bench486_screen_drawram_saved_pixbytes = r_pixbytes;
	Q_memcpy (bench486_screen_drawram_saved_palette, d_8to16table,
			sizeof(d_8to16table));
}

static void Bench486ScreenDrawRamRestoreState (void)
{
	Q_memcpy (&vid, &bench486_screen_drawram_saved_vid, sizeof(vid));
	Q_memcpy (&scr_showram, &bench486_screen_drawram_saved_showram,
			sizeof(scr_showram));
	scr_ram = bench486_screen_drawram_saved_ram;
	Q_memcpy (&scr_vrect, &bench486_screen_drawram_saved_vrect,
			sizeof(scr_vrect));
	r_cache_thrash = bench486_screen_drawram_saved_cache_thrash;
	r_pixbytes = bench486_screen_drawram_saved_pixbytes;
	Q_memcpy (d_8to16table, bench486_screen_drawram_saved_palette,
			sizeof(d_8to16table));
}

static unsigned Bench486ScreenDrawRamRun (
		const bench486_screen_drawram_case_t *test_case, unsigned case_index,
		void (*function)(void), const char *implementation,
		unsigned short control_word, bench486_screen_drawram_result_t *result)
{
	unsigned i;
	unsigned short status_before, status_after;

	Bench486ScreenDrawRamPrepare (test_case, case_index);
	Bench486ScreenDrawRamSetControlWord (control_word);
	result->cw_before = Bench486ScreenDrawRamGetControlWord ();
	status_before = Bench486ScreenDrawRamGetStatusWord ();
	result->top_before = (status_before >> 11) & 7U;
	result->abi = Bench486Call_asm486 (function, 0, NULL, NULL);
	result->cw_after = Bench486ScreenDrawRamGetControlWord ();
	status_after = Bench486ScreenDrawRamGetStatusWord ();
	result->top_after = (status_after >> 11) & 7U;
	result->show_bits = test_case->show_bits;
	result->cache_thrash = (unsigned)r_cache_thrash;
	result->ram_pointer = (unsigned)scr_ram;
	result->view_x = scr_vrect.x;
	result->view_y = scr_vrect.y;

	if (result->abi || result->cw_before != result->cw_after ||
			result->top_before != result->top_after ||
			!Bench486ScreenDrawRamGuardsIntact ())
	{
		Bench486Printf ("screen RAM ABI/guard FAIL %s case %s abi %u CW %04x/%04x TOP %u/%u\n",
				implementation, test_case->name, result->abi,
				result->cw_before, result->cw_after,
				result->top_before, result->top_after);
		return 1;
	}
	for (i = 0; i < BSDR_FRAME_BYTES; i++)
		if (bench486_screen_drawram_frame.pixels[i] !=
				bench486_screen_drawram_expected[i])
		{
			Bench486Printf ("screen RAM pixels FAIL %s case %s byte %u got %u expected %u\n",
					implementation, test_case->name, i,
					bench486_screen_drawram_frame.pixels[i],
					bench486_screen_drawram_expected[i]);
			return 1;
		}
	return 0;
}

static unsigned Bench486ScreenDrawRamResultDifference (
		const bench486_screen_drawram_result_t *reference,
		const bench486_screen_drawram_result_t *candidate)
{
	return reference->show_bits != candidate->show_bits ||
			reference->cache_thrash != candidate->cache_thrash ||
			reference->ram_pointer != candidate->ram_pointer ||
			reference->view_x != candidate->view_x ||
			reference->view_y != candidate->view_y ||
			reference->abi != candidate->abi ||
			reference->cw_before != candidate->cw_before ||
			reference->cw_after != candidate->cw_after ||
			reference->top_before != candidate->top_before ||
			reference->top_after != candidate->top_after;
}

static const char *const bench486_screen_drawram_rounding_names[4] = {
	"nearest", "down", "up", "truncate"
};
static const unsigned short bench486_screen_drawram_rounding_bits[4] = {
	0x0000, 0x0400, 0x0800, 0x0c00
};
static const unsigned short bench486_screen_drawram_precision_bits[3] = {
	0x0000, 0x0200, 0x0300
};

static void Bench486ScreenDrawRamCases (void)
{
	static const bench486_screen_drawram_case_t cases[BSDR_CASE_COUNT] = {
		{ "positive-zero-disabled", 0x00000000U, 1, (int)0x80000000U,
			(int)0x7fffffffU, 33, 8, 1, 0 },
		{ "negative-zero-disabled", 0x80000000U, 1, 91, 61, 7, 5, 1, 3 },
		{ "negative-zero-cache-clear", 0x80000000U, 0, 0, 0, 8, 8, 1, 0 },
		{ "quiet-nan-cache-clear", 0x7fc12345U, 0, (int)0x7fffffffU,
			(int)0x80000000U, 8, 8, 2, 4 },
		{ "vga-positive-draw", 0x3f800000U, 1, 0, 2, 13, 5, 1, 3 },
		{ "vga-infinity-right-edge", 0x7f800000U, -1, 255, 50, 33, 8, 1, 1 },
		{ "vbe-negative-draw", 0xbf800000U, 1, 249, 52, 32, 8, 2, 4 }
	};
	static const char *const precision_names[3] = {
		"single", "double", "extended"
	};
	bench486_screen_drawram_result_t reference, candidate;
	unsigned case_index, precision, rounding, failures, difference;
	unsigned short saved_control_word, control_word;

	failures = 0;
	Bench486ScreenDrawRamSaveState ();
	saved_control_word = Bench486ScreenDrawRamGetControlWord ();
	for (case_index = 0; case_index < BSDR_CASE_COUNT; case_index++)
		for (precision = 0; precision < 3; precision++)
			for (rounding = 0; rounding < 4; rounding++)
			{
				control_word = (unsigned short)((saved_control_word & 0xf0ffU) |
						bench486_screen_drawram_precision_bits[precision] |
						bench486_screen_drawram_rounding_bits[rounding]);
				failures += Bench486ScreenDrawRamRun (&cases[case_index],
						case_index, SCR_DrawRam_Screen_C, "C oracle", control_word,
						&reference);
				failures += Bench486ScreenDrawRamRun (&cases[case_index],
						case_index, SCR_DrawRam_asm486, "assembly", control_word,
						&candidate);
				difference = Bench486ScreenDrawRamResultDifference (
						&reference, &candidate);
				if (difference)
				{
					failures++;
					Bench486Printf ("screen RAM state mismatch %s/%s/%s\n",
							cases[case_index].name, precision_names[precision],
							bench486_screen_drawram_rounding_names[rounding]);
				}
			}
	Bench486ScreenDrawRamSetControlWord (saved_control_word);
	Bench486ScreenDrawRamRestoreState ();
	bench486_memory_failures += failures;
	Bench486Printf ("screen RAM indicator %u exact C/assembly cases across four RC and three PC modes; %s\n",
			BSDR_CASE_COUNT * BSDR_CONTROL_COUNT,
			failures ? "FAIL" : "framebuffer parity PASS");
}

#endif /* BENCH486 && ASM486_SCREEN_DRAW_RAM */

#endif
