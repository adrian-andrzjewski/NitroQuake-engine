/* Direct SCR_DrawCenterString C/assembly state, ABI and framebuffer parity. */
#ifndef BENCH486_SCREEN_CENTER_H
#define BENCH486_SCREEN_CENTER_H

#if defined(BENCH486) && defined(ASM486_SCREEN_CENTER_STRING)

#define BSC_GUARD_WORDS 8
#define BSC_FONT_BYTES 16384
#define BSC_ROW_BYTES 672
#define BSC_FRAME_ROWS 256
/* Holds the centered 640x480 title line at the 16-bit 1280-byte stride. */
#define BSC_FRAME_BYTES (256U * 1024U)
#define BSC_MAX_CALLS 512

/* Assembly uses the trace hook only while its direct parity fixture runs. */
int bench486_screen_center_fixture_active;
/* The C oracle uses this flag to reach the same production glyph renderer. */
int bench486_screen_center_live_character_active;

#include "asm_screencenter.h"

extern void Draw_Character (int x, int y, int num);
extern byte *draw_chars;
extern int r_pixbytes;
extern char scr_centerstring[1024];
extern int scr_center_lines;
extern int scr_erase_center;
extern float scr_centertime_start;
extern cvar_t scr_printspeed;
extern unsigned Bench486Call_asm486 (void (*function)(void), unsigned words,
		const unsigned *arguments, float *float_return);

typedef struct
{
	unsigned before[BSC_GUARD_WORDS];
	byte pixels[BSC_FRAME_BYTES];
	unsigned after[BSC_GUARD_WORDS];
} bench486_screen_center_frame_t;

typedef struct
{
	int x, y, character;
} bench486_screen_center_call_t;

typedef struct
{
	bench486_screen_center_frame_t frame;
	bench486_screen_center_call_t calls[BSC_MAX_CALLS];
	unsigned call_count;
	unsigned trace_overflow;
	unsigned abi;
	unsigned short cw_before, cw_after;
	int erase_center;
} bench486_screen_center_result_t;

typedef struct
{
	const char *name;
	const char *text;
	unsigned width, height;
	int lines;
	int intermission;
	float time, start, speed;
} bench486_screen_center_case_t;

typedef struct
{
	byte bytes[28];
} bench486_screen_center_x87_environment_t;

static struct
{
	unsigned before[4];
	byte pixels[BSC_FONT_BYTES];
	unsigned after[4];
} bench486_screen_center_font;
static bench486_screen_center_result_t bench486_screen_center_reference;
static bench486_screen_center_result_t bench486_screen_center_candidate;
static unsigned bench486_screen_center_call_count;
static unsigned bench486_screen_center_trace_overflow;
static viddef_t bench486_screen_center_saved_video;
static byte *bench486_screen_center_saved_characters;
static int bench486_screen_center_saved_pixel_bytes;
static int bench486_screen_center_saved_erase;
static int bench486_screen_center_saved_lines;
static float bench486_screen_center_saved_start;
static float bench486_screen_center_saved_speed;
static int bench486_screen_center_saved_intermission;
static float bench486_screen_center_saved_time;
static char bench486_screen_center_saved_text[1024];
static unsigned short bench486_screen_center_saved_cw;
static bench486_screen_center_x87_environment_t bench486_screen_center_saved_environment;
static char bench486_screen_center_line_40[41];
static char bench486_screen_center_overlong[48];
static const char bench486_screen_center_high_bits[] = {
	(char)0x80, (char)0xff, 'Q', 0
};

static void Bench486ScreenCenterInitData (void)
{
	unsigned i;

	for (i = 0; i < 4; i++)
	{
		bench486_screen_center_font.before[i] = 0x486e4100U + i;
		bench486_screen_center_font.after[i] = 0x486e4200U + i;
	}
	for (i = 0; i < BSC_FONT_BYTES; i++)
	{
		unsigned pattern;

		pattern = i * 37U + (i >> 5);
		/* Quake conchars uses zero for transparent pixels. Keep this font
		   deterministic while exercising both store and skip branches. */
		bench486_screen_center_font.pixels[i] =
				(pattern & 3U) == 0 ? 0 : (byte)(1U + pattern % 255U);
	}
	for (i = 0; i < 40; i++)
		bench486_screen_center_line_40[i] = (char)('A' + i % 26);
	bench486_screen_center_line_40[40] = 0;
	for (i = 0; i < 45; i++)
		bench486_screen_center_overlong[i] = (char)('K' + i % 15);
	bench486_screen_center_overlong[45] = '\n';
	bench486_screen_center_overlong[46] = 'Z';
	bench486_screen_center_overlong[47] = 0;
}

/* Record each character request and render it into the guarded indexed frame. */
void Bench486ScreenCenterStringCharacter (int x, int y, int num)
{
	if (bench486_screen_center_live_character_active)
	{
		Draw_Character (x, y, num);
		return;
	}

	if (bench486_screen_center_call_count < BSC_MAX_CALLS)
	{
		bench486_screen_center_candidate.calls[bench486_screen_center_call_count].x = x;
		bench486_screen_center_candidate.calls[bench486_screen_center_call_count].y = y;
		bench486_screen_center_candidate.calls[bench486_screen_center_call_count].character = num;
		bench486_screen_center_call_count++;
	}
	else
		bench486_screen_center_trace_overflow = 1;

	/* Preserve out-of-screen calls in the trace but keep Draw_Character inside
	   the bounded fixture image for unsigned-width and narrow-screen cases. */
	if (x < 0 || (unsigned)x > vid.width - 8U ||
			(unsigned)x > BSC_ROW_BYTES - 8U || y < 0 ||
			(unsigned)y > vid.height - 8U ||
			(unsigned)y > BSC_FRAME_ROWS - 8U)
		return;

	Draw_Character (x, y, num);
}

static unsigned short Bench486ScreenCenterGetControlWord (void)
{
	unsigned short control_word;
	__asm__ __volatile__ ("fnstcw %0" : "=m" (control_word));
	return control_word;
}

static void Bench486ScreenCenterSetControlWord (unsigned short control_word)
{
	__asm__ __volatile__ ("fldcw %0" : : "m" (control_word));
}

static void Bench486ScreenCenterSaveEnvironment (
		bench486_screen_center_x87_environment_t *environment)
{
	__asm__ __volatile__ ("fnstenv %0\n\tfldenv %0" : "=m" (*environment));
}

static void Bench486ScreenCenterRestoreEnvironment (
		const bench486_screen_center_x87_environment_t *environment)
{
	__asm__ __volatile__ ("fldenv %0" : : "m" (*environment));
}

static void Bench486ScreenCenterPrepare (
		const bench486_screen_center_case_t *test_case)
{
	bench486_screen_center_frame_t *frame;
	unsigned i;
	frame = &bench486_screen_center_candidate.frame;

	for (i = 0; i < BSC_GUARD_WORDS; i++)
	{
		frame->before[i] = 0x486e5100U + i;
		frame->after[i] = 0x5a13d900U + i;
	}
	for (i = 0; i < BSC_FRAME_BYTES; i++)
		frame->pixels[i] = (byte)(0x43U + i * 29U);

	vid.buffer = frame->pixels;
	vid.colormap = NULL;
	vid.colormap16 = NULL;
	vid.fullbright = 0;
	vid.rowbytes = BSC_ROW_BYTES;
	vid.width = test_case->width;
	vid.height = test_case->height;
	vid.aspect = 1.0f;
	vid.numpages = 1;
	vid.recalc_refdef = 0;
	vid.conbuffer = frame->pixels;
	vid.conrowbytes = BSC_ROW_BYTES;
	vid.conwidth = test_case->width;
	vid.conheight = BSC_FRAME_ROWS;
	vid.maxwarpwidth = 0;
	vid.maxwarpheight = 0;
	vid.direct = NULL;
	draw_chars = bench486_screen_center_font.pixels;
	r_pixbytes = 1;
	Q_memset (scr_centerstring, 0, sizeof(scr_centerstring));
	strncpy (scr_centerstring, test_case->text, sizeof(scr_centerstring) - 1);
	scr_center_lines = test_case->lines;
	scr_erase_center = 7;
	cl.intermission = test_case->intermission;
	cl.time = test_case->time;
	scr_centertime_start = test_case->start;
	scr_printspeed.value = test_case->speed;
	bench486_screen_center_call_count = 0;
	bench486_screen_center_trace_overflow = 0;
}

static void Bench486ScreenCenterRestoreState (void)
{
	Q_memcpy (&vid, &bench486_screen_center_saved_video, sizeof(vid));
	draw_chars = bench486_screen_center_saved_characters;
	r_pixbytes = bench486_screen_center_saved_pixel_bytes;
	scr_erase_center = bench486_screen_center_saved_erase;
	scr_center_lines = bench486_screen_center_saved_lines;
	scr_centertime_start = bench486_screen_center_saved_start;
	scr_printspeed.value = bench486_screen_center_saved_speed;
	cl.intermission = bench486_screen_center_saved_intermission;
	cl.time = bench486_screen_center_saved_time;
	Q_memcpy (scr_centerstring, bench486_screen_center_saved_text,
			sizeof(bench486_screen_center_saved_text));
}

static void Bench486ScreenCenterCapture (bench486_screen_center_result_t *result,
		unsigned abi, unsigned short cw_before, unsigned short cw_after)
{
	/* The candidate frame doubles as the active draw buffer. Keep it in place
	   after the assembly run; snapshot it only when retaining the C oracle. */
	if (result != &bench486_screen_center_candidate)
	{
		Q_memset (result, 0, sizeof(*result));
		Q_memcpy (&result->frame, &bench486_screen_center_candidate.frame,
				sizeof(result->frame));
		Q_memcpy (result->calls, bench486_screen_center_candidate.calls,
				bench486_screen_center_call_count * sizeof(result->calls[0]));
	}
	result->call_count = bench486_screen_center_call_count;
	result->trace_overflow = bench486_screen_center_trace_overflow;
	result->abi = abi;
	result->cw_before = cw_before;
	result->cw_after = cw_after;
	result->erase_center = scr_erase_center;
}

static int Bench486ScreenCenterGuardsIntact (void)
{
	unsigned i;

	for (i = 0; i < BSC_GUARD_WORDS; i++)
		if (bench486_screen_center_candidate.frame.before[i] != 0x486e5100U + i ||
				bench486_screen_center_candidate.frame.after[i] != 0x5a13d900U + i)
			return 0;
	for (i = 0; i < 4; i++)
		if (bench486_screen_center_font.before[i] != 0x486e4100U + i ||
				bench486_screen_center_font.after[i] != 0x486e4200U + i)
			return 0;
	return 1;
}

static unsigned Bench486ScreenCenterRun (
		const bench486_screen_center_case_t *test_case,
		const char *implementation, void (*function)(void),
		bench486_screen_center_result_t *result)
{
	unsigned abi;
	unsigned short cw_before, cw_after;

	Bench486ScreenCenterPrepare (test_case);
	cw_before = Bench486ScreenCenterGetControlWord ();
	bench486_screen_center_fixture_active = 1;
	abi = Bench486Call_asm486 (function, 0, NULL, NULL);
	bench486_screen_center_fixture_active = 0;
	cw_after = Bench486ScreenCenterGetControlWord ();
	Bench486ScreenCenterCapture (result, abi, cw_before, cw_after);
	if ((abi & 0x20U) || cw_before != cw_after)
	{
		Bench486Printf ("screen center x87 CW FAIL case %s implementation %s before %04x after %04x probe %u\n",
				test_case->name, implementation, cw_before, cw_after, abi & 0x20U);
		return 1;
	}
	return abi || result->trace_overflow || !Bench486ScreenCenterGuardsIntact ();
}

static unsigned Bench486ScreenCenterDifference (
		const bench486_screen_center_result_t *reference,
		const bench486_screen_center_result_t *candidate)
{
	unsigned i;

	if (reference->call_count != candidate->call_count)
		return 0x10000001U;
	if (reference->trace_overflow != candidate->trace_overflow)
		return 0x10000002U;
	if (reference->abi != candidate->abi)
		return 0x10000003U;
	if (reference->cw_before != candidate->cw_before)
		return 0x10000004U;
	if (reference->cw_after != candidate->cw_after)
		return 0x10000005U;
	if (reference->erase_center != candidate->erase_center)
		return 0x10000006U;
	for (i = 0; i < reference->call_count; i++)
		if (reference->calls[i].x != candidate->calls[i].x ||
				reference->calls[i].y != candidate->calls[i].y ||
				reference->calls[i].character != candidate->calls[i].character)
			return 0x40000000U | i;
	for (i = 0; i < sizeof(reference->frame); i++)
		if (((const byte *)&reference->frame)[i] !=
				((const byte *)&candidate->frame)[i])
			return 0x80000000U | i;
	return 0;
}

/* Verify that the fixture-disabled assembly branch reaches the real glyph
   renderer and produces the same indexed framebuffer as the C algorithm. */
static unsigned Bench486ScreenCenterLiveCharacterCase (void)
{
	static const bench486_screen_center_case_t test_cases[] = {
		{ "live-vga-draw-character-route", "\002the Necropolis", 320, 200, 1, 0,
			0.0f, 0.0f, 8.0f },
		{ "live-vesa-draw-character-route", "\002the Necropolis", 640, 480, 1, 0,
			0.0f, 0.0f, 8.0f }
	};
	unsigned abi, failures, difference, pixel_bytes, stride, i, mode;
	unsigned short cw_before, cw_after;
	unsigned short saved_8to16[256];

	failures = 0;
	Q_memcpy (saved_8to16, d_8to16table, sizeof(saved_8to16));
	for (i = 0; i < 256; i++)
		d_8to16table[i] = (unsigned short)(i * 251U + 0x4861U);
	for (mode = 0; mode < sizeof(test_cases) / sizeof(test_cases[0]); mode++)
	{
		for (pixel_bytes = 1; pixel_bytes <= 2; pixel_bytes++)
		{
			stride = test_cases[mode].width * pixel_bytes;
			Bench486ScreenCenterPrepare (&test_cases[mode]);
			vid.rowbytes = stride;
			vid.conrowbytes = stride;
			r_pixbytes = (int)pixel_bytes;
			if (bench486_screen_center_saved_characters)
				draw_chars = bench486_screen_center_saved_characters;
			bench486_screen_center_live_character_active = 1;
			bench486_screen_center_fixture_active = 0;
			cw_before = Bench486ScreenCenterGetControlWord ();
			abi = Bench486Call_asm486 (SCR_DrawCenterString_Screen_C, 0, NULL, NULL);
			cw_after = Bench486ScreenCenterGetControlWord ();
			bench486_screen_center_live_character_active = 0;
			Bench486ScreenCenterCapture (&bench486_screen_center_reference, abi,
					cw_before, cw_after);
			if (abi || cw_before != cw_after || !Bench486ScreenCenterGuardsIntact ())
				failures++;

			Bench486ScreenCenterPrepare (&test_cases[mode]);
			vid.rowbytes = stride;
			vid.conrowbytes = stride;
			r_pixbytes = (int)pixel_bytes;
			if (bench486_screen_center_saved_characters)
				draw_chars = bench486_screen_center_saved_characters;
			bench486_screen_center_fixture_active = 0;
			cw_before = Bench486ScreenCenterGetControlWord ();
			abi = Bench486Call_asm486 (SCR_DrawCenterString_asm486, 0, NULL, NULL);
			cw_after = Bench486ScreenCenterGetControlWord ();
			Bench486ScreenCenterCapture (&bench486_screen_center_candidate, abi,
					cw_before, cw_after);
			if (abi || cw_before != cw_after || !Bench486ScreenCenterGuardsIntact ())
				failures++;

			difference = Bench486ScreenCenterDifference (
					&bench486_screen_center_reference,
					&bench486_screen_center_candidate);
			if (difference)
			{
				failures++;
				Bench486Printf ("screen center live Draw_Character mode %u pixel bytes %u difference %u\n",
						mode, pixel_bytes, difference);
			}
		}
	}
	Q_memcpy (d_8to16table, saved_8to16, sizeof(saved_8to16));
	Bench486ScreenCenterRestoreState ();
	if (failures)
		Bench486Printf ("screen center live Draw_Character route FAIL failures %u\n",
				failures);
	else
		Bench486Printf ("screen center live Draw_Character 8/16-bit routes exact framebuffer parity PASS\n");
	return failures;
}

static void Bench486ScreenCenterCases (void)
{
	/* These extremes keep derived coordinates representable: max-width cases
	   return before the C loop increment, and the callbacks clip away the frame. */
	static const bench486_screen_center_case_t cases[] = {
		{ "empty", "", 320, 200, 1, 0, 0.0f, 0.0f, 8.0f },
		{ "one-line", "QUAKE", 320, 200, 1, 0, 0.0f, 0.0f, 8.0f },
		{ "wrapped-lines", "A\nB", 321, 201, 2, 0, 0.0f, 0.0f, 8.0f },
		{ "five-lines", "A\nB\nC\nD\nE", 640, 240, 5, 0, 0.0f, 0.0f, 8.0f },
		{ "line-40", bench486_screen_center_line_40, 640, 224, 1, 0, 0.0f, 0.0f, 8.0f },
		{ "overlong-suffix", bench486_screen_center_overlong, 641, 201, 2, 0, 0.0f, 0.0f, 8.0f },
		{ "narrow-view-40-char-line", bench486_screen_center_line_40, 240, 200, 1, 0, 0.0f, 0.0f, 8.0f },
		{ "signed-high-bytes", bench486_screen_center_high_bits, 321, 239, 1, 0, 0.0f, 0.0f, 8.0f },
		{ "wide-offscreen-center", "Q", 2048, 200, 1, 0, 0.0f, 0.0f, 8.0f },
		{ "high-bit-width", "Q", 0x80000000U, 200, 1, 0, 0.0f, 0.0f, 8.0f },
		{ "high-bit-height", "Q", 320, 0x80000000U, 1, 0, 0.0f, 0.0f, 8.0f },
		{ "maximum-unsigned-width", "Q", 0xffffffffU, 200, 1, 1, 1.0f, 1.0f, 0.0f },
		{ "maximum-unsigned-height", "Q", 320, 0xffffffffU, 1, 1, 1.0f, 1.0f, 0.0f },
		{ "large-mode-height", "Q", 640, 480, 1, 0, 0.0f, 0.0f, 8.0f },
		{ "five-lines-highres", "A\nB\nC\nD\nE", 640, 480, 5, 0, 0.0f, 0.0f, 8.0f },
		{ "zero-intermission-budget", "ABC", 320, 200, 1, 1, 3.0f, 1.0f, 0.0f },
		{ "positive-intermission-budget", "ABCDE", 320, 200, 1, 1, 2.0f, 1.0f, 2.0f },
		{ "negative-intermission-budget", "ABCDE", 320, 200, 1, 1, 0.0f, 1.0f, 2.0f },
		{ "fractional-intermission-budget", "ABCDE", 321, 201, 1, 1, 3.0f, 1.0f, 0.7f }
	};
	static const char *rounding_names[4] = { "nearest", "down", "up", "truncate" };
	static const unsigned short rounding_bits[4] = { 0x0000, 0x0400, 0x0800, 0x0c00 };
	static const unsigned short precision_bits[3] = { 0x0000, 0x0200, 0x0300 };
	static const char *precision_names[3] = { "single", "double", "extended" };
	unsigned case_index, precision, rounding, failures, difference;
	unsigned short control_word;
	const bench486_screen_center_case_t *test_case;

	Bench486ScreenCenterSaveEnvironment (&bench486_screen_center_saved_environment);
	bench486_screen_center_saved_cw = Bench486ScreenCenterGetControlWord ();
	Q_memcpy (&bench486_screen_center_saved_video, &vid, sizeof(vid));
	bench486_screen_center_saved_characters = draw_chars;
	bench486_screen_center_saved_pixel_bytes = r_pixbytes;
	bench486_screen_center_saved_erase = scr_erase_center;
	bench486_screen_center_saved_lines = scr_center_lines;
	bench486_screen_center_saved_start = scr_centertime_start;
	bench486_screen_center_saved_speed = scr_printspeed.value;
	bench486_screen_center_saved_intermission = cl.intermission;
	bench486_screen_center_saved_time = cl.time;
	Q_memcpy (bench486_screen_center_saved_text, scr_centerstring,
			sizeof(bench486_screen_center_saved_text));
	Bench486ScreenCenterInitData ();
	failures = 0;
	Bench486Printf ("screen center begin cases %u RC modes 4 PC modes 3\n",
			(unsigned)(sizeof(cases) / sizeof(cases[0])));

	for (case_index = 0; case_index < sizeof(cases) / sizeof(cases[0]); case_index++)
	{
		if (case_index >= 7)
			Bench486Printf ("screen center case %u/%u begin %s\n",
					case_index + 1, (unsigned)(sizeof(cases) / sizeof(cases[0])),
					cases[case_index].name);
		for (precision = 0; precision < 3; precision++)
		{
			for (rounding = 0; rounding < 4; rounding++)
			{
				unsigned short precision_control;
				const char *precision_name;

				test_case = &cases[case_index];
				precision_control = precision_bits[precision];
				precision_name = precision_names[precision];
				control_word = (unsigned short)((bench486_screen_center_saved_cw &
						(unsigned short)~0x0f00U) | precision_control | rounding_bits[rounding]);
				Bench486ScreenCenterSetControlWord (control_word);
				failures += Bench486ScreenCenterRun (test_case, "C oracle",
						SCR_DrawCenterString_Screen_C, &bench486_screen_center_reference);
				Bench486ScreenCenterSetControlWord (control_word);
				failures += Bench486ScreenCenterRun (test_case, "assembly",
						SCR_DrawCenterString_asm486, &bench486_screen_center_candidate);
				difference = Bench486ScreenCenterDifference (
						&bench486_screen_center_reference,
						&bench486_screen_center_candidate);
				if (difference)
				{
					failures++;
					Bench486Printf ("screen center mismatch %s/%s/%s detail %u\n",
							test_case->name, precision_name,
							rounding_names[rounding], difference);
					if (difference == 0x10000001U)
						Bench486Printf ("screen center calls C %u assembly %u\n",
								bench486_screen_center_reference.call_count,
								bench486_screen_center_candidate.call_count);
				}
				Bench486ScreenCenterSetControlWord (control_word);
				failures += Bench486ScreenCenterRun (test_case, "public entry",
						SCR_DrawCenterString, &bench486_screen_center_candidate);
				difference = Bench486ScreenCenterDifference (
						&bench486_screen_center_reference,
						&bench486_screen_center_candidate);
				if (difference)
				{
					failures++;
					Bench486Printf ("screen center public mismatch %s/%s/%s detail %u\n",
							test_case->name, precision_name,
							rounding_names[rounding], difference);
					if (difference == 0x10000001U)
						Bench486Printf ("screen center calls C %u public %u\n",
								bench486_screen_center_reference.call_count,
								bench486_screen_center_candidate.call_count);
				}
			}
		}
		Bench486ScreenCenterRestoreState ();
		Bench486Printf ("screen center progress %u/%u; failures %u\n",
				case_index + 1, (unsigned)(sizeof(cases) / sizeof(cases[0])), failures);
	}

	failures += Bench486ScreenCenterLiveCharacterCase ();
	Bench486ScreenCenterRestoreState ();
	Bench486ScreenCenterRestoreEnvironment (&bench486_screen_center_saved_environment);
	bench486_memory_failures += failures;
	Bench486Printf ("screen center cases %u RC modes 4 PC modes 3; failures %u\n",
			(unsigned)(sizeof(cases) / sizeof(cases[0])), failures);
}

#endif /* BENCH486 && ASM486_SCREEN_CENTER_STRING */

#endif
