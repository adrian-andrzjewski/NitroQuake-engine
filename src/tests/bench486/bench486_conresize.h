/* Direct C/assembly state, buffer and ABI parity for console resize. */
/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
#if defined(BENCH486) && defined(ASM486_SCREEN_CONSOLE_SETUP)
#ifndef BENCH486_CON_RESIZE_H
#define BENCH486_CON_RESIZE_H

#define BCR_GUARD_BYTES 16
#define BCR_BUFFER_BYTES (ccr_textsize + BCR_GUARD_BYTES * 2)

typedef struct
{
	unsigned long align;
	byte bytes[BCR_BUFFER_BYTES];
} bench486_conresize_buffer_t;

typedef struct
{
	int linewidth;
	int totallines;
	int current;
	int backscroll;
	int cursor;
	int text_pointer_preserved;
	unsigned abi;
	float notify[ccr_notify_count];
} bench486_conresize_result_t;

typedef struct
{
	const char *name;
	unsigned video_width;
	int old_width;
	int current;
	int backscroll;
	int cursor;
	byte seed;
} bench486_conresize_case_t;

extern unsigned Bench486Call_asm486 (void (*function)(void), unsigned words,
		const unsigned *arguments, float *float_return);

static bench486_conresize_buffer_t bench486_conresize_c_buffer;
static bench486_conresize_buffer_t bench486_conresize_asm_buffer;
static byte bench486_conresize_c_output[BCR_BUFFER_BYTES];
static byte bench486_conresize_asm_output[BCR_BUFFER_BYTES];
static viddef_t bench486_conresize_saved_vid;
static char *bench486_conresize_saved_text;
static int bench486_conresize_saved_linewidth;
static int bench486_conresize_saved_totallines;
static int bench486_conresize_saved_current;
static int bench486_conresize_saved_backscroll;
static int bench486_conresize_saved_cursor;
static float bench486_conresize_saved_notify[ccr_notify_count];

static int Bench486ConResizeGuards (const byte *buffer)
{
	int i;

	for (i=0 ; i<BCR_GUARD_BYTES ; i++)
	{
		if (buffer[i] != 0xd5 ||
			buffer[BCR_GUARD_BYTES + ccr_textsize + i] != 0xd5)
			return 0;
	}
	return 1;
}

static void Bench486ConResizePrepare (
		const bench486_conresize_case_t *test_case,
		bench486_conresize_buffer_t *buffer)
{
	int i;

	Q_memset (buffer->bytes, 0xd5, BCR_BUFFER_BYTES);
	for (i=0 ; i<ccr_textsize ; i++)
		buffer->bytes[BCR_GUARD_BYTES + i] =
			(byte)(i * 29 + (i >> 4) + test_case->seed);
	con_text = (char *)(buffer->bytes + BCR_GUARD_BYTES);
	vid.width = test_case->video_width;
	con_linewidth = test_case->old_width;
	con_totallines = test_case->old_width > 0 ?
		ccr_textsize / test_case->old_width : 0;
	con_current = test_case->current;
	con_backscroll = test_case->backscroll;
	con_x = test_case->cursor;
	for (i=0 ; i<ccr_notify_count ; i++)
		con_times[i] = (float)(test_case->seed + i * 7) * 0.25f;
}

static void Bench486ConResizeRun (
		void (*function)(void),
		const bench486_conresize_case_t *test_case,
		bench486_conresize_buffer_t *buffer,
		byte *output,
		bench486_conresize_result_t *result)
{
	Q_memset (result, 0, sizeof(*result));
	Bench486ConResizePrepare (test_case, buffer);
	result->abi = Bench486Call_asm486 (function, 0, NULL, NULL);
	result->linewidth = con_linewidth;
	result->totallines = con_totallines;
	result->current = con_current;
	result->backscroll = con_backscroll;
	result->cursor = con_x;
	result->text_pointer_preserved =
		con_text == (char *)(buffer->bytes + BCR_GUARD_BYTES);
	Q_memcpy (result->notify, con_times, sizeof(con_times));
	Q_memcpy (output, buffer->bytes, BCR_BUFFER_BYTES);
}

int Bench486ConsoleResizeCases (void)
{
	static const bench486_conresize_case_t cases[] = {
		{ "unchanged-width", 320, 38, 430, 19, 7, 0x19 },
		{ "wider-scrollback", 256, 40, 401, 9, 3, 0x2b },
		{ "narrower-scrollback", 1280, 80, 2, 14, 5, 0x3d },
		{ "wrapped-current", 640, 64, 0, 128, 11, 0x4f },
		{ "one-column", 24, 128, 63, 4, 17, 0x61 },
		{ "pre-video-fallback", 16, 80, 201, 3, 23, 0x73 },
		{ "initial-buffer", 320, -1, 0, 0, 29, 0x85 }
	};
	bench486_conresize_result_t c_result, asm_result;
	int failures, i;

	Q_memcpy (&bench486_conresize_saved_vid, &vid, sizeof(vid));
	bench486_conresize_saved_text = con_text;
	bench486_conresize_saved_linewidth = con_linewidth;
	bench486_conresize_saved_totallines = con_totallines;
	bench486_conresize_saved_current = con_current;
	bench486_conresize_saved_backscroll = con_backscroll;
	bench486_conresize_saved_cursor = con_x;
	Q_memcpy (bench486_conresize_saved_notify, con_times, sizeof(con_times));
	failures = 0;

	for (i=0 ; i<(int)(sizeof(cases)/sizeof(cases[0])) ; i++)
	{
		Bench486ConResizeRun (Con_CheckResize_C, &cases[i],
			&bench486_conresize_c_buffer, bench486_conresize_c_output,
			&c_result);
		Bench486ConResizeRun (Con_CheckResize, &cases[i],
			&bench486_conresize_asm_buffer, bench486_conresize_asm_output,
			&asm_result);

		if (c_result.linewidth != asm_result.linewidth ||
				c_result.totallines != asm_result.totallines ||
				c_result.current != asm_result.current ||
				c_result.backscroll != asm_result.backscroll ||
				c_result.cursor != asm_result.cursor ||
				c_result.text_pointer_preserved != 1 ||
				asm_result.text_pointer_preserved != 1 ||
				c_result.abi != 0 || asm_result.abi != 0 ||
				Q_memcmp (c_result.notify, asm_result.notify,
					sizeof(c_result.notify)) != 0 ||
				Q_memcmp (bench486_conresize_c_output,
					bench486_conresize_asm_output, BCR_BUFFER_BYTES) != 0 ||
				!Bench486ConResizeGuards (bench486_conresize_c_output) ||
				!Bench486ConResizeGuards (bench486_conresize_asm_output))
			failures |= 1 << i;
	}

	Q_memcpy (&vid, &bench486_conresize_saved_vid, sizeof(vid));
	con_text = bench486_conresize_saved_text;
	con_linewidth = bench486_conresize_saved_linewidth;
	con_totallines = bench486_conresize_saved_totallines;
	con_current = bench486_conresize_saved_current;
	con_backscroll = bench486_conresize_saved_backscroll;
	con_x = bench486_conresize_saved_cursor;
	Q_memcpy (con_times, bench486_conresize_saved_notify, sizeof(con_times));
	return failures;
}

#endif /* BENCH486_CON_RESIZE_H */
#endif /* BENCH486 && ASM486_SCREEN_CONSOLE_SETUP */
