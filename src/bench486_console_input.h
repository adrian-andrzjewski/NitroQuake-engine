/* Direct Con_DrawInput C/assembly state and indexed-framebuffer parity. */
#ifndef BENCH486_CONSOLE_INPUT_H
#define BENCH486_CONSOLE_INPUT_H

#if defined(BENCH486) && defined(ASM486_CONSOLE_INPUT)

#define BCI_LINE_COUNT 32
#define BCI_LINE_BYTES 256
#define BCI_FONT_BYTES 16384
#define BCI_GUARD_WORDS 8
#define BCI_ROW_BYTES 128
#define BCI_FRAME_ROWS 48
#define BCI_FRAME_BYTES (BCI_ROW_BYTES * BCI_FRAME_ROWS)

/* Expected integration symbols: the C oracle is renamed in console.c, while
   the public symbol dispatches to the selected assembly implementation. */
extern void Con_DrawInput_Console_C (void);
extern void Con_DrawInput_asm486 (void);
extern void Con_DrawInput (void);
extern void Draw_Character (int x, int y, int num);
extern unsigned Bench486Call_asm486 (void (*function)(void), unsigned words,
		const unsigned *arguments, float *float_return);

extern char key_lines[BCI_LINE_COUNT][BCI_LINE_BYTES];
extern int edit_line, key_linepos;
extern keydest_t key_dest;
extern int con_linewidth, con_vislines;
extern qboolean con_forcedup;
extern float con_cursorspeed;
extern double realtime;
extern byte *draw_chars;
extern int r_pixbytes;

typedef char bench486_console_input_requires_i386[
		(sizeof(void *) == 4 && sizeof(int) == 4 && sizeof(unsigned) == 4) ?
		1 : -1];

typedef struct
{
	unsigned before[BCI_GUARD_WORDS];
	byte data[BCI_FRAME_BYTES];
	unsigned after[BCI_GUARD_WORDS];
} bench486_console_input_frame_t;

typedef struct
{
	bench486_console_input_frame_t frame;
	char lines[BCI_LINE_COUNT][BCI_LINE_BYTES];
	viddef_t video;
	byte *characters;
	int pixel_bytes;
	int edit_line_value, line_position, destination;
	int forced, visible_lines, line_width;
	float cursor_speed;
	double realtime_value;
	unsigned abi;
} bench486_console_input_result_t;

typedef struct
{
	const char *name;
	int width, position;
	keydest_t destination;
	int forced, visible_lines;
	float cursor_speed;
	double realtime_value;
} bench486_console_input_case_t;

typedef struct
{
	/* FNSTENV in 32-bit protected mode stores the 28-byte env image. */
	byte bytes[28];
} bench486_console_input_x87_environment_t;

static struct
{
	unsigned before[4];
	byte data[BCI_FONT_BYTES];
	unsigned after[4];
} bench486_console_input_font;
static bench486_console_input_frame_t bench486_console_input_frame;
static bench486_console_input_frame_t bench486_console_input_initial_frame;
static char bench486_console_input_initial_lines[BCI_LINE_COUNT][BCI_LINE_BYTES];
static char bench486_console_input_saved_lines[BCI_LINE_COUNT][BCI_LINE_BYTES];
static viddef_t bench486_console_input_expected_video;
static bench486_console_input_result_t bench486_console_input_c_result;
static bench486_console_input_result_t bench486_console_input_asm_result;
static bench486_console_input_result_t bench486_console_input_public_result;

static void Bench486ConsoleInputInitFont (void)
{
	unsigned i;

	for (i = 0; i < 4; i++)
	{
		bench486_console_input_font.before[i] = 0x486c1000U + i;
		bench486_console_input_font.after[i] = 0x486c2000U + i;
	}
	for (i = 0; i < BCI_FONT_BYTES; i++)
		bench486_console_input_font.data[i] = (byte)(i * 37U + (i >> 5));
}

static void Bench486ConsoleInputPrepare (
		const bench486_console_input_case_t *test_case)
{
	unsigned row, column, i;

	for (row = 0; row < BCI_LINE_COUNT; row++)
		for (column = 0; column < BCI_LINE_BYTES; column++)
			key_lines[row][column] = (char)(0x31U +
					((row * 17U + column * 29U) % 0x50U));
	edit_line = 5;
	key_linepos = test_case->position;
	key_dest = test_case->destination;
	con_forcedup = test_case->forced;
	con_vislines = test_case->visible_lines;
	con_linewidth = test_case->width;
	con_cursorspeed = test_case->cursor_speed;
	realtime = test_case->realtime_value;
	key_lines[edit_line][0] = '>';
	key_lines[edit_line][key_linepos] = 0;

	for (i = 0; i < BCI_GUARD_WORDS; i++)
	{
		bench486_console_input_frame.before[i] = 0x486d3100U + i;
		bench486_console_input_frame.after[i] = 0x5a13c800U + i;
	}
	for (i = 0; i < BCI_FRAME_BYTES; i++)
		bench486_console_input_frame.data[i] = (byte)(0x5aU + i * 31U);

	Q_memset (&vid, 0, sizeof(vid));
	vid.buffer = bench486_console_input_frame.data;
	vid.width = 112;
	vid.height = BCI_FRAME_ROWS;
	vid.conbuffer = bench486_console_input_frame.data;
	vid.conrowbytes = BCI_ROW_BYTES;
	vid.conwidth = 112;
	vid.conheight = BCI_FRAME_ROWS;
	draw_chars = bench486_console_input_font.data;
	r_pixbytes = 1;
	Q_memcpy (&bench486_console_input_expected_video, &vid, sizeof(vid));
	Q_memcpy (bench486_console_input_initial_lines, key_lines,
			sizeof(bench486_console_input_initial_lines));
	Q_memcpy (&bench486_console_input_initial_frame,
			&bench486_console_input_frame,
			sizeof(bench486_console_input_initial_frame));
}

static void Bench486ConsoleInputCapture (
		bench486_console_input_result_t *result, unsigned abi)
{
	Q_memset (result, 0, sizeof(*result));
	Q_memcpy (&result->frame, &bench486_console_input_frame,
			sizeof(result->frame));
	Q_memcpy (result->lines, key_lines, sizeof(result->lines));
	Q_memcpy (&result->video, &vid, sizeof(result->video));
	result->characters = draw_chars;
	result->pixel_bytes = r_pixbytes;
	result->edit_line_value = edit_line;
	result->line_position = key_linepos;
	result->destination = key_dest;
	result->forced = con_forcedup;
	result->visible_lines = con_vislines;
	result->line_width = con_linewidth;
	result->cursor_speed = con_cursorspeed;
	result->realtime_value = realtime;
	result->abi = abi;
}

static unsigned short Bench486ConsoleInputGetControlWord (void)
{
	unsigned short control_word;
	__asm__ __volatile__ ("fnstcw %0" : "=m" (control_word));
	return control_word;
}

static void Bench486ConsoleInputSetControlWord (unsigned short control_word)
{
	__asm__ __volatile__ ("fldcw %0" : : "m" (control_word));
}

static void Bench486ConsoleInputSaveEnvironment (
		bench486_console_input_x87_environment_t *environment)
{
	/* FNSTENV masks exceptions, so reload immediately to preserve live state. */
	__asm__ __volatile__ ("fnstenv %0\n\tfldenv %0" : "=m" (*environment));
}

static void Bench486ConsoleInputRestoreEnvironment (
		const bench486_console_input_x87_environment_t *environment)
{
	__asm__ __volatile__ ("fldenv %0" : : "m" (*environment));
}

static int Bench486ConsoleInputGuardsIntact (
		const bench486_console_input_result_t *result)
{
	unsigned i;

	for (i = 0; i < BCI_GUARD_WORDS; i++)
		if (result->frame.before[i] != 0x486d3100U + i ||
				result->frame.after[i] != 0x5a13c800U + i)
			return 0;
	for (i = 0; i < 4; i++)
		if (bench486_console_input_font.before[i] != 0x486c1000U + i ||
				bench486_console_input_font.after[i] != 0x486c2000U + i)
			return 0;
	return 1;
}

static int Bench486ConsoleInputExpected (
		const bench486_console_input_case_t *test_case,
		const bench486_console_input_result_t *result)
{
	static char expected_lines[BCI_LINE_COUNT][BCI_LINE_BYTES];
	int i, visible;

	visible = test_case->destination == key_console || test_case->forced;
	Q_memcpy (expected_lines, bench486_console_input_initial_lines,
			sizeof(expected_lines));
	if (visible)
	{
		for (i = test_case->position + 1; i < test_case->width; i++)
			expected_lines[5][i] = ' ';
		expected_lines[5][test_case->position] = 0;
	}
	if (Q_memcmp ((void *)result->lines, expected_lines,
			sizeof(expected_lines)))
		return 0;
	if (Q_memcmp ((void *)&result->video,
			(void *)&bench486_console_input_expected_video,
			sizeof(result->video)))
		return 0;
	if (result->characters != bench486_console_input_font.data ||
			result->pixel_bytes != 1 || result->edit_line_value != 5 ||
			result->line_position != test_case->position ||
			result->destination != test_case->destination ||
			result->forced != test_case->forced ||
			result->visible_lines != test_case->visible_lines ||
			result->line_width != test_case->width ||
			result->cursor_speed != test_case->cursor_speed ||
			result->realtime_value != test_case->realtime_value ||
			!Bench486ConsoleInputGuardsIntact (result))
		return 0;
	if (!visible && Q_memcmp ((void *)result->frame.data,
			(void *)bench486_console_input_initial_frame.data,
			BCI_FRAME_BYTES))
		return 0;
	return 1;
}

static int Bench486ConsoleInputFirstDifference (
		const bench486_console_input_result_t *left,
		const bench486_console_input_result_t *right)
{
	unsigned i;
	const byte *left_bytes = (const byte *)left;
	const byte *right_bytes = (const byte *)right;

	for (i = 0; i < sizeof(*left); i++)
		if (left_bytes[i] != right_bytes[i])
			return (int)i;
	return -1;
}

static unsigned Bench486ConsoleInputRun (
		const bench486_console_input_case_t *test_case,
		void (*function)(void), bench486_console_input_result_t *result,
		unsigned rounding_mode)
{
	unsigned abi;
	unsigned short original_control_word, test_control_word;

	Bench486ConsoleInputPrepare (test_case);
	original_control_word = Bench486ConsoleInputGetControlWord ();
	test_control_word = (unsigned short)((original_control_word & ~0x0c00U) |
			rounding_mode);
	Bench486ConsoleInputSetControlWord (test_control_word);
	abi = Bench486Call_asm486 (function, 0, NULL, NULL);
	Bench486ConsoleInputSetControlWord (original_control_word);
	Bench486ConsoleInputCapture (result, abi);
	return abi || !Bench486ConsoleInputExpected (test_case, result);
}

static void Bench486ConsoleInputCases (void)
{
	static const bench486_console_input_case_t cases[] =
	{
		{ "hidden", 8, 2, key_game, 0, 32, 4.0f, 0.0 },
		{ "forced-visible", 8, 2, key_game, 1, 32, 4.0f, 0.25 },
		{ "cursor-even", 8, 2, key_console, 0, 32, 4.0f, 0.0 },
		{ "cursor-odd", 8, 2, key_console, 0, 32, 4.0f, 0.25 },
		{ "cursor-negative-truncate", 8, 2, key_console, 0, 32, 4.0f, -0.49999995 },
		{ "cursor-near-even-below", 8, 2, key_console, 0, 32, 4.0f, 0.499999999999 },
		{ "cursor-near-even-above", 8, 2, key_console, 0, 32, 4.0f, 0.500000000001 },
		{ "cursor-nonintegral-speed", 8, 2, key_console, 0, 32, 0.1f, 25.0 },
		{ "cursor-negative-speed-product", 8, 2, key_console, 0, 32, 0.1f, -25.0 },
		{ "cursor-int-min", 8, 2, key_console, 0, 32, 4.0f, -536870912.0 },
		{ "cursor-int-max", 8, 2, key_console, 0, 32, 4.0f, 536870911.75 },
		{ "blank-tail", 8, 1, key_console, 0, 32, 4.0f, 0.0 },
		{ "scroll-before-boundary", 8, 7, key_console, 0, 32, 4.0f, 0.25 },
		{ "scroll-at-boundary", 8, 8, key_console, 0, 32, 4.0f, 0.0 },
		{ "scroll-after-boundary", 8, 11, key_console, 0, 32, 4.0f, 0.25 },
		{ "wide-scroll", 12, 15, key_console, 0, 32, 4.0f, 0.0 },
		{ "top-partial-clip", 8, 3, key_console, 0, 12, 4.0f, 0.25 },
		{ "top-edge", 8, 3, key_console, 0, 16, 4.0f, 0.0 },
		{ "top-fully-clipped", 8, 3, key_console, 0, 8, 4.0f, 0.25 },
		{ "bottom-valid", 8, 3, key_console, 0, 48, 4.0f, 0.0 },
		{ "last-line-byte", 8, BCI_LINE_BYTES - 1, key_console, 0, 32, 4.0f, 0.0 }
	};
	static const unsigned rounding_modes[] =
		{ 0x0000U, 0x0400U, 0x0800U, 0x0c00U };
	static viddef_t saved_video;
	static byte *saved_characters;
	static int saved_pixel_bytes, saved_line_position, saved_edit_line;
	static keydest_t saved_destination;
	static int saved_forced, saved_visible_lines, saved_line_width;
	static float saved_cursor_speed;
	static double saved_realtime;
	static bench486_console_input_x87_environment_t saved_x87_environment;
	unsigned i, mode, failures = 0;

	Bench486ConsoleInputSaveEnvironment (&saved_x87_environment);
	Q_memcpy (bench486_console_input_saved_lines, key_lines,
			sizeof(bench486_console_input_saved_lines));
	Q_memcpy (&saved_video, &vid, sizeof(saved_video));
	saved_characters = draw_chars;
	saved_pixel_bytes = r_pixbytes;
	saved_line_position = key_linepos;
	saved_edit_line = edit_line;
	saved_destination = key_dest;
	saved_forced = con_forcedup;
	saved_visible_lines = con_vislines;
	saved_line_width = con_linewidth;
	saved_cursor_speed = con_cursorspeed;
	saved_realtime = realtime;
	Bench486ConsoleInputInitFont ();

	Bench486Printf ("console input C/ASM state and framebuffer begin (%u directed cases)\n",
			(unsigned)(sizeof(cases) / sizeof(cases[0])));
	for (i = 0; i < sizeof(cases) / sizeof(cases[0]); i++)
	for (mode = 0; mode < sizeof(rounding_modes) / sizeof(rounding_modes[0]); mode++)
	{
		unsigned case_failures = 0;
		case_failures += Bench486ConsoleInputRun (&cases[i],
				Con_DrawInput_Console_C, &bench486_console_input_c_result,
				rounding_modes[mode]);
		case_failures += Bench486ConsoleInputRun (&cases[i],
				Con_DrawInput_asm486, &bench486_console_input_asm_result,
				rounding_modes[mode]);
		case_failures += Bench486ConsoleInputRun (&cases[i],
				Con_DrawInput, &bench486_console_input_public_result,
				rounding_modes[mode]);
		if (Q_memcmp ((void *)&bench486_console_input_c_result,
				(void *)&bench486_console_input_asm_result,
				sizeof(bench486_console_input_c_result)))
			case_failures++;
		if (Q_memcmp ((void *)&bench486_console_input_c_result,
				(void *)&bench486_console_input_public_result,
				sizeof(bench486_console_input_c_result)))
			case_failures++;
		failures += case_failures;
		if (case_failures)
		{
		int difference = Bench486ConsoleInputFirstDifference (
					&bench486_console_input_c_result,
					&bench486_console_input_asm_result);
			if (difference < 0)
				difference = Bench486ConsoleInputFirstDifference (
						&bench486_console_input_c_result,
						&bench486_console_input_public_result);
			Bench486Printf ("  console input %s mode %u FAIL C/ASM/public ABI %x/%x/%x state-byte %d\n",
					(char *)cases[i].name,
					mode,
					bench486_console_input_c_result.abi,
					bench486_console_input_asm_result.abi,
					bench486_console_input_public_result.abi, difference);
		}
	}

	Q_memcpy (key_lines, bench486_console_input_saved_lines,
			sizeof(bench486_console_input_saved_lines));
	Q_memcpy (&vid, &saved_video, sizeof(vid));
	draw_chars = saved_characters;
	r_pixbytes = saved_pixel_bytes;
	key_linepos = saved_line_position;
	edit_line = saved_edit_line;
	key_dest = saved_destination;
	con_forcedup = saved_forced;
	con_vislines = saved_visible_lines;
	con_linewidth = saved_line_width;
	con_cursorspeed = saved_cursor_speed;
	realtime = saved_realtime;

	if (failures)
		bench486_memory_failures += failures;
	Bench486Printf ("console input C/ASM semantic, framebuffer, canary, and four x87 rounding-mode parity %s (%u cases x %u modes; %u failures)\n",
			failures ? "FAIL" : "PASS",
			(unsigned)(sizeof(cases) / sizeof(cases[0])),
			(unsigned)(sizeof(rounding_modes) / sizeof(rounding_modes[0])), failures);
	Bench486ConsoleInputRestoreEnvironment (&saved_x87_environment);
}

#undef BCI_LINE_COUNT
#undef BCI_LINE_BYTES
#undef BCI_FONT_BYTES
#undef BCI_GUARD_WORDS
#undef BCI_ROW_BYTES
#undef BCI_FRAME_ROWS
#undef BCI_FRAME_BYTES

#endif /* BENCH486 && ASM486_CONSOLE_INPUT */
#endif /* BENCH486_CONSOLE_INPUT_H */
