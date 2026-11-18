/* Direct Con_DrawInput C/assembly state and indexed-framebuffer parity. */
/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
#ifndef BENCH486_CONSOLE_INPUT_H
#define BENCH486_CONSOLE_INPUT_H

#if defined(BENCH486) && defined(ASM486_CONSOLE_INPUT)

#include <stdlib.h>

#define BCI_LINE_COUNT 32
#define BCI_LINE_BYTES 256
#define BCI_FONT_BYTES 16384
#define BCI_GUARD_WORDS 8
#define BCI_ROW_BYTES 128
#define BCI_FRAME_ROWS 48
#define BCI_FRAME_BYTES (BCI_ROW_BYTES * BCI_FRAME_ROWS)
#define BCD_MAX_FRAME_BYTES (320 * 200 * 2)
#define BCN_LINE_WIDTH 12
#define BCN_TOTAL_LINES 4
#define BCN_TEXT_BYTES (BCN_LINE_WIDTH * BCN_TOTAL_LINES)

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
extern int con_current, con_backscroll, con_totallines, con_notifylines;
extern char *con_text;
extern float con_times[4];
extern cvar_t con_notifytime;
extern int clearnotify, scr_copytop;
extern char chat_buffer[32];

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
static byte bench486_console_draw_c_frame[BCD_MAX_FRAME_BYTES];
static byte bench486_console_notify_c_frame[BCI_FRAME_BYTES];
static char bench486_console_notify_text[BCN_TEXT_BYTES];

extern void Con_DrawConsole_Console_C (int lines, qboolean drawinput);
extern void Con_DrawConsole_asm486 (int lines, qboolean drawinput);
extern void Con_DrawNotify_Console_C (void);
extern void Con_DrawNotify_asm486 (void);
extern void Con_DrawNotify (void);

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

static void Bench486ConsoleDrawCases (void)
{
	static const char *case_names[] =
		{ "one-line", "partial-row", "one-row", "multi-row", "full-console" };
	static viddef_t saved_video;
	int lines[5];
	int saved_visible, saved_current, saved_backscroll, saved_width;
	unsigned bytes, arguments[2], i, j, difference, failures = 0;
	int c_visible;
	unsigned c_abi, asm_abi;
	byte *saved_frame;
	
	if (!vid.conbuffer || vid.conrowbytes <= 0 || vid.conheight <= 0 ||
			vid.conrowbytes * vid.conheight > BCD_MAX_FRAME_BYTES ||
			!con_text || con_totallines <= 0 || con_linewidth <= 0)
	{
		bench486_memory_failures++;
		Bench486Printf ("console draw C/ASM parity FAIL: initialized console video and scrollback required\n");
		return;
	}

	bytes = (unsigned)(vid.conrowbytes * vid.conheight);
	saved_frame = malloc (bytes);
	if (!saved_frame)
	{
		bench486_memory_failures++;
		Bench486Printf ("console draw C/ASM parity FAIL: could not allocate %u-byte framebuffer snapshot\n",
				bytes);
		return;
	}
	lines[0] = 1;
	lines[1] = 15;
	lines[2] = 16;
	lines[3] = 24;
	lines[4] = vid.conheight;
	saved_visible = con_vislines;
	saved_current = con_current;
	saved_backscroll = con_backscroll;
	saved_width = con_linewidth;
	Q_memcpy (&saved_video, &vid, sizeof(vid));
	Q_memcpy (saved_frame, vid.conbuffer, bytes);
	
	for (i = 0; i < sizeof(lines) / sizeof(lines[0]); i++)
	{
		if (lines[i] > vid.conheight)
			lines[i] = vid.conheight;
		arguments[0] = (unsigned)lines[i];
		arguments[1] = 0;
		Q_memcpy (vid.conbuffer, saved_frame, bytes);
		con_vislines = saved_visible;
		c_abi = Bench486Call_asm486 ((void (*)(void))Con_DrawConsole_Console_C,
				2, arguments, NULL);
		c_visible = con_vislines;
		Q_memcpy (bench486_console_draw_c_frame, vid.conbuffer, bytes);
		
		Q_memcpy (vid.conbuffer, saved_frame, bytes);
		con_vislines = saved_visible;
		asm_abi = Bench486Call_asm486 ((void (*)(void))Con_DrawConsole_asm486,
				2, arguments, NULL);
		difference = bytes;
		for (j = 0; j < bytes; j++)
			if (bench486_console_draw_c_frame[j] != vid.conbuffer[j])
			{
				difference = j;
				break;
			}
		if (c_abi || asm_abi || c_visible != lines[i] ||
				con_vislines != lines[i] || difference != bytes ||
				Q_memcmp ((void *)&vid, (void *)&saved_video, sizeof(vid)) ||
				con_current != saved_current || con_backscroll != saved_backscroll ||
				con_linewidth != saved_width)
		{
			failures++;
			Bench486Printf ("  console draw %s FAIL C/ASM ABI %x/%x visible %d/%d first-pixel %u\n",
					(char *)case_names[i], c_abi, asm_abi, c_visible,
					con_vislines, difference);
		}
	}

	Q_memcpy (vid.conbuffer, saved_frame, bytes);
	free (saved_frame);
	con_vislines = saved_visible;
	if (failures)
		bench486_memory_failures += failures;
	Bench486Printf ("console draw C/ASM framebuffer and state parity %s (%u cases; %u failures)\n",
			failures ? "FAIL" : "PASS",
			(unsigned)(sizeof(lines) / sizeof(lines[0])), failures);
}

typedef struct
{
	const char *name;
	int current;
	float times[4];
	double realtime_value;
	float notify_time;
	keydest_t destination;
	float cursor_speed;
	const char *chat;
	int clear_notify, copy_top, notify_lines;
} bench486_console_notify_case_t;

static void Bench486ConsoleNotifyPrepare (
		const bench486_console_notify_case_t *test_case)
{
	unsigned i;

	for (i = 0; i < BCI_GUARD_WORDS; i++)
	{
		bench486_console_input_frame.before[i] = 0x486d3100U + i;
		bench486_console_input_frame.after[i] = 0x5a13c800U + i;
	}
	for (i = 0; i < BCI_FRAME_BYTES; i++)
		bench486_console_input_frame.data[i] = (byte)(0x71U + i * 19U);
	for (i = 0; i < BCN_TEXT_BYTES; i++)
		bench486_console_notify_text[i] = (char)(0x21U + (i * 11U) % 0x50U);

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

	con_current = test_case->current;
	con_totallines = BCN_TOTAL_LINES;
	con_linewidth = BCN_LINE_WIDTH;
	con_vislines = 7;
	con_text = bench486_console_notify_text;
	for (i = 0; i < 4; i++)
		con_times[i] = test_case->times[i];
	realtime = test_case->realtime_value;
	con_notifytime.value = test_case->notify_time;
	con_cursorspeed = test_case->cursor_speed;
	key_dest = test_case->destination;
	clearnotify = test_case->clear_notify;
	scr_copytop = test_case->copy_top;
	con_notifylines = test_case->notify_lines;
	Q_memset (chat_buffer, 0, sizeof(chat_buffer));
	Q_strcpy (chat_buffer, (char *)test_case->chat);
}

static int Bench486ConsoleNotifyGuardsIntact (void)
{
	unsigned i;

	for (i = 0; i < BCI_GUARD_WORDS; i++)
		if (bench486_console_input_frame.before[i] != 0x486d3100U + i ||
				bench486_console_input_frame.after[i] != 0x5a13c800U + i)
			return 0;
	for (i = 0; i < 4; i++)
		if (bench486_console_input_font.before[i] != 0x486c1000U + i ||
				bench486_console_input_font.after[i] != 0x486c2000U + i)
			return 0;
	return 1;
}

static void Bench486ConsoleNotifyCases (void)
{
	static const bench486_console_notify_case_t cases[] =
	{
		{ "no-lines", -1, { 0, 0, 0, 0 }, 20.0, 3.0f,
			key_game, 4.0f, "", 2, 7, 4 },
		{ "recent-line", 0, { 19, 0, 0, 0 }, 20.0, 3.0f,
			key_game, 4.0f, "", 2, 7, 4 },
		{ "ring-wrap-four-lines", 13, { 19, 19, 19, 19 }, 20.0, 3.0f,
			key_game, 4.0f, "", 2, 7, 0 },
		{ "exact-expiry", 0, { 17, 0, 0, 0 }, 20.0, 3.0f,
			key_game, 4.0f, "", 2, 7, 0 },
		{ "expired-line", 0, { 16, 0, 0, 0 }, 20.0, 3.0f,
			key_game, 4.0f, "", 2, 7, 0 },
		{ "chat-empty", -1, { 0, 0, 0, 0 }, 20.0, 3.0f,
			key_message, 4.0f, "", 1, 0, 0 },
		{ "chat-cursor-boundary", -1, { 0, 0, 0, 0 },
			0.499999999999, 3.0f, key_message, 1.0f, "abc", 1, 0, 0 },
		{ "mixed-lines-chat", 3, { 19, 0, 18, 0 }, 20.0, 3.0f,
			key_message, 4.0f, "ok", 1, 0, 0 }
	};
	static const unsigned rounding_modes[] =
		{ 0x0000U, 0x0400U, 0x0800U, 0x0c00U };
	static viddef_t saved_video;
	static float saved_times[4];
	static char saved_chat[32];
	static bench486_console_input_x87_environment_t saved_x87_environment;
	char *saved_text;
	byte *saved_characters;
	int saved_pixel_bytes, saved_current, saved_total, saved_backscroll;
	int saved_width, saved_visible, saved_notify_lines, saved_clear, saved_copy;
	keydest_t saved_destination;
	float saved_notify_time, saved_cursor_speed;
	double saved_realtime;
	unsigned short original_control_word, test_control_word;
	unsigned i, mode, j, failures = 0;
	unsigned c_abi, asm_abi, public_abi, difference;
	int c_guards_ok, asm_guards_ok, public_guards_ok;
	int c_clear, c_copy, c_notify_lines, c_visible, c_current, c_destination;

	Bench486ConsoleInputSaveEnvironment (&saved_x87_environment);
	Q_memcpy (&saved_video, &vid, sizeof(saved_video));
	Q_memcpy (saved_times, con_times, sizeof(saved_times));
	Q_memcpy (saved_chat, chat_buffer, sizeof(saved_chat));
	saved_text = con_text;
	saved_characters = draw_chars;
	saved_pixel_bytes = r_pixbytes;
	saved_current = con_current;
	saved_total = con_totallines;
	saved_backscroll = con_backscroll;
	saved_width = con_linewidth;
	saved_visible = con_vislines;
	saved_notify_lines = con_notifylines;
	saved_clear = clearnotify;
	saved_copy = scr_copytop;
	saved_destination = key_dest;
	saved_notify_time = con_notifytime.value;
	saved_cursor_speed = con_cursorspeed;
	saved_realtime = realtime;
	original_control_word = Bench486ConsoleInputGetControlWord ();
	Bench486ConsoleInputInitFont ();

	for (i = 0; i < sizeof(cases) / sizeof(cases[0]); i++)
		for (mode = 0; mode < sizeof(rounding_modes) / sizeof(rounding_modes[0]); mode++)
		{
			Bench486ConsoleNotifyPrepare (&cases[i]);
			test_control_word = (unsigned short)((original_control_word & ~0x0c00U) |
					rounding_modes[mode]);
			Bench486ConsoleInputSetControlWord (test_control_word);
			c_abi = Bench486Call_asm486 ((void (*)(void))Con_DrawNotify_Console_C,
					0, NULL, NULL);
			Bench486ConsoleInputSetControlWord (original_control_word);
			c_guards_ok = Bench486ConsoleNotifyGuardsIntact ();
			c_clear = clearnotify;
			c_copy = scr_copytop;
			c_notify_lines = con_notifylines;
			c_visible = con_vislines;
			c_current = con_current;
			c_destination = key_dest;
			Q_memcpy (bench486_console_notify_c_frame,
					bench486_console_input_frame.data, BCI_FRAME_BYTES);

			Bench486ConsoleNotifyPrepare (&cases[i]);
			Bench486ConsoleInputSetControlWord (test_control_word);
			asm_abi = Bench486Call_asm486 ((void (*)(void))Con_DrawNotify_asm486,
					0, NULL, NULL);
			Bench486ConsoleInputSetControlWord (original_control_word);
			difference = BCI_FRAME_BYTES;
			for (j = 0; j < BCI_FRAME_BYTES; j++)
				if (bench486_console_notify_c_frame[j] !=
						bench486_console_input_frame.data[j])
				{
					difference = j;
					break;
				}
			asm_guards_ok = Bench486ConsoleNotifyGuardsIntact ();
			if (c_abi || asm_abi || difference != BCI_FRAME_BYTES ||
					c_clear != clearnotify || c_copy != scr_copytop ||
					c_notify_lines != con_notifylines || c_visible != con_vislines ||
					c_current != con_current || c_destination != key_dest ||
					!c_guards_ok || !asm_guards_ok)
			{
				failures++;
				Bench486Printf ("  console notify %s mode %u C/ASM ABI %x/%x state %d/%d/%d first-pixel %u\n",
						(char *)cases[i].name, mode, c_abi, asm_abi,
						clearnotify, scr_copytop, con_notifylines, difference);
			}

			Bench486ConsoleNotifyPrepare (&cases[i]);
			Bench486ConsoleInputSetControlWord (test_control_word);
			public_abi = Bench486Call_asm486 ((void (*)(void))Con_DrawNotify,
					0, NULL, NULL);
			Bench486ConsoleInputSetControlWord (original_control_word);
			public_guards_ok = Bench486ConsoleNotifyGuardsIntact ();
			difference = BCI_FRAME_BYTES;
			for (j = 0; j < BCI_FRAME_BYTES; j++)
				if (bench486_console_notify_c_frame[j] !=
						bench486_console_input_frame.data[j])
				{
					difference = j;
					break;
				}
			if (public_abi || difference != BCI_FRAME_BYTES ||
					c_clear != clearnotify || c_copy != scr_copytop ||
					c_notify_lines != con_notifylines || c_visible != con_vislines ||
					c_current != con_current || c_destination != key_dest ||
					!public_guards_ok)
			{
				failures++;
				Bench486Printf ("  console notify public %s mode %u C/public ABI %x/%x first-pixel %u\n",
						(char *)cases[i].name, mode, c_abi, public_abi, difference);
			}
		}

	Q_memcpy (&vid, &saved_video, sizeof(saved_video));
	Q_memcpy (con_times, saved_times, sizeof(saved_times));
	Q_memcpy (chat_buffer, saved_chat, sizeof(saved_chat));
	con_text = saved_text;
	draw_chars = saved_characters;
	r_pixbytes = saved_pixel_bytes;
	con_current = saved_current;
	con_totallines = saved_total;
	con_backscroll = saved_backscroll;
	con_linewidth = saved_width;
	con_vislines = saved_visible;
	con_notifylines = saved_notify_lines;
	clearnotify = saved_clear;
	scr_copytop = saved_copy;
	key_dest = saved_destination;
	con_notifytime.value = saved_notify_time;
	con_cursorspeed = saved_cursor_speed;
	realtime = saved_realtime;
	if (failures)
		bench486_memory_failures += failures;
	Bench486Printf ("console notification C/ASM/public framebuffer, state and four x87 rounding-mode parity %s (%u cases x %u modes; %u failures)\n",
			failures ? "FAIL" : "PASS",
			(unsigned)(sizeof(cases) / sizeof(cases[0])),
			(unsigned)(sizeof(rounding_modes) / sizeof(rounding_modes[0])), failures);
	Bench486ConsoleInputRestoreEnvironment (&saved_x87_environment);
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
	Bench486ConsoleDrawCases ();
	Bench486ConsoleNotifyCases ();
	Bench486ConsoleInputRestoreEnvironment (&saved_x87_environment);
}

#undef BCI_LINE_COUNT
#undef BCI_LINE_BYTES
#undef BCI_FONT_BYTES
#undef BCI_GUARD_WORDS
#undef BCI_ROW_BYTES
#undef BCI_FRAME_ROWS
#undef BCI_FRAME_BYTES
#undef BCD_MAX_FRAME_BYTES
#undef BCN_LINE_WIDTH
#undef BCN_TOTAL_LINES
#undef BCN_TEXT_BYTES

#endif /* BENCH486 && ASM486_CONSOLE_INPUT */
#endif /* BENCH486_CONSOLE_INPUT_H */
