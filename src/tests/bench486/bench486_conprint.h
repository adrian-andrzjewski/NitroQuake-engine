/* Exact C/i486 parity for the console scrollback insertion path. */
/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
#ifndef BENCH486_CONPRINT_H
#define BENCH486_CONPRINT_H

#if defined(BENCH486)

#include "client/asm_consolecheckresize.h"

#define BCP_GUARD_WORDS 4
#define BCP_SOUND_BYTES 32
#define BCP_NOTIFY_COUNT 4

extern int con_linewidth, con_totallines;
extern int con_current, con_x, con_backscroll;
extern char *con_text;
extern float con_times[BCP_NOTIFY_COUNT];
extern double realtime;
extern int con_print_cr_bench, con_print_cr_asm486;
extern int bench486_memory_failures;
extern unsigned Bench486Call_asm486 (void (*function)(void), unsigned words,
		const unsigned *arguments, float *float_return);
#ifdef ASM486_CONSOLE_INPUT
extern void Con_Print_Console_C (char *text);
extern void Con_Linefeed_Console_C (void);
#define BCP_CON_PRINT_C Con_Print_Console_C
#define BCP_CON_LINEFEED_C Con_Linefeed_Console_C
#else
extern void Con_Print (char *text);
extern void Con_Linefeed (void);
#define BCP_CON_PRINT_C Con_Print
#define BCP_CON_LINEFEED_C Con_Linefeed
#endif
extern void Con_Print_asm486 (char *text);
extern void Con_Linefeed_asm486 (void);

int bench486_console_print_capture_active;
int bench486_console_print_sound_count;
char bench486_console_print_sound_name[BCP_SOUND_BYTES];

void Bench486ConPrintSound (char *sample)
{
	int i;
	if (!bench486_console_print_capture_active)
	{
		S_LocalSound (sample);
		return;
	}
	bench486_console_print_sound_count++;
	for (i = 0; i < BCP_SOUND_BYTES - 1 && sample[i]; i++)
		bench486_console_print_sound_name[i] = sample[i];
	bench486_console_print_sound_name[i] = 0;
}

typedef struct
{
	unsigned before[BCP_GUARD_WORDS];
	char text[ccr_textsize];
	unsigned after[BCP_GUARD_WORDS];
} bench486_conprint_buffer_t;

typedef struct
{
	const char *name;
	const char *first_text;
	const char *second_text;
	int width;
	int total_lines;
	int current;
	int x;
	int backscroll;
	int seed;
	int initial_cr;
	double realtime_value;
	int expected_sounds;
} bench486_conprint_case_t;

typedef struct
{
	char text[ccr_textsize];
	unsigned before[BCP_GUARD_WORDS];
	unsigned after[BCP_GUARD_WORDS];
	int linewidth;
	int total_lines;
	int current;
	int x;
	int backscroll;
	int carriage_return;
	float times[BCP_NOTIFY_COUNT];
	int sound_count;
	char sound_name[BCP_SOUND_BYTES];
	unsigned abi;
} bench486_conprint_result_t;

typedef struct
{
	char *text;
	int linewidth;
	int total_lines;
	int current;
	int x;
	int backscroll;
	int carriage_return_c;
	int carriage_return_asm;
	float times[BCP_NOTIFY_COUNT];
	double realtime_value;
	int sound_capture;
	int sound_count;
	char sound_name[BCP_SOUND_BYTES];
} bench486_conprint_saved_t;

static bench486_conprint_buffer_t bench486_conprint_buffer;
static bench486_conprint_result_t bench486_conprint_c_result;
static bench486_conprint_result_t bench486_conprint_asm_result;

static char bench486_conprint_high_bytes[] = {
	(char)0x80, (char)0xff, 'Q', '\n', 0
};

static unsigned short Bench486ConPrintGetControlWord (void)
{
	unsigned short control_word;
	__asm__ __volatile__ ("fnstcw %0" : "=m" (control_word));
	return control_word;
}

static void Bench486ConPrintSetControlWord (unsigned short control_word)
{
	__asm__ __volatile__ ("fldcw %0" : : "m" (control_word));
}

static void Bench486ConPrintSave (bench486_conprint_saved_t *saved)
{
	saved->text = con_text;
	saved->linewidth = con_linewidth;
	saved->total_lines = con_totallines;
	saved->current = con_current;
	saved->x = con_x;
	saved->backscroll = con_backscroll;
	saved->carriage_return_c = con_print_cr_bench;
	saved->carriage_return_asm = con_print_cr_asm486;
	Q_memcpy (saved->times, con_times, sizeof(saved->times));
	saved->realtime_value = realtime;
	saved->sound_capture = bench486_console_print_capture_active;
	saved->sound_count = bench486_console_print_sound_count;
	Q_memcpy (saved->sound_name, bench486_console_print_sound_name,
			sizeof(saved->sound_name));
}

static void Bench486ConPrintRestore (	const bench486_conprint_saved_t *saved)
{
	con_text = saved->text;
	con_linewidth = saved->linewidth;
	con_totallines = saved->total_lines;
	con_current = saved->current;
	con_x = saved->x;
	con_backscroll = saved->backscroll;
	con_print_cr_bench = saved->carriage_return_c;
	con_print_cr_asm486 = saved->carriage_return_asm;
	Q_memcpy (con_times, (void *)saved->times, sizeof(saved->times));
	realtime = saved->realtime_value;
	bench486_console_print_capture_active = saved->sound_capture;
	bench486_console_print_sound_count = saved->sound_count;
	Q_memcpy (bench486_console_print_sound_name, (void *)saved->sound_name,
			sizeof(saved->sound_name));
}

static void Bench486ConPrintInstall (
		const bench486_conprint_case_t *test_case)
{
	unsigned i;
	for (i = 0; i < BCP_GUARD_WORDS; i++)
	{
		bench486_conprint_buffer.before[i] = 0x486c3100U + i;
		bench486_conprint_buffer.after[i] = 0x486c3200U + i;
	}
	for (i = 0; i < ccr_textsize; i++)
		bench486_conprint_buffer.text[i] = (char)(32U +
				((i * 13U + (unsigned)test_case->seed) % 95U));
	con_text = bench486_conprint_buffer.text;
	con_linewidth = test_case->width;
	con_totallines = test_case->total_lines;
	con_current = test_case->current;
	con_x = test_case->x;
	con_backscroll = test_case->backscroll;
	con_print_cr_bench = test_case->initial_cr;
	con_print_cr_asm486 = test_case->initial_cr;
	realtime = test_case->realtime_value;
	for (i = 0; i < BCP_NOTIFY_COUNT; i++)
		con_times[i] = (float)(-2.25 + (double)i * 1.125);
	bench486_console_print_sound_count = 0;
	Q_memset (bench486_console_print_sound_name, 0,
			sizeof(bench486_console_print_sound_name));
}

static void Bench486ConPrintCapture (bench486_conprint_result_t *result,
		int assembly, unsigned abi)
{
	Q_memset (result, 0, sizeof(*result));
	Q_memcpy (result->text, bench486_conprint_buffer.text,
			sizeof(result->text));
	Q_memcpy (result->before, bench486_conprint_buffer.before,
			sizeof(result->before));
	Q_memcpy (result->after, bench486_conprint_buffer.after,
			sizeof(result->after));
	result->linewidth = con_linewidth;
	result->total_lines = con_totallines;
	result->current = con_current;
	result->x = con_x;
	result->backscroll = con_backscroll;
	result->carriage_return = assembly ? con_print_cr_asm486 :
			con_print_cr_bench;
	Q_memcpy (result->times, con_times, sizeof(result->times));
	result->sound_count = bench486_console_print_sound_count;
	Q_memcpy (result->sound_name, bench486_console_print_sound_name,
			sizeof(result->sound_name));
	result->abi = abi;
}

static unsigned Bench486ConPrintInvoke (void (*function)(void),
		const char *text)
{
	unsigned argument;
	argument = (unsigned)text;
	return Bench486Call_asm486 (function, 1, &argument, NULL);
}

static unsigned Bench486ConPrintRun (
		const bench486_conprint_case_t *test_case,
		void (*function)(void), bench486_conprint_result_t *result,
		int assembly)
{
	unsigned abi;
	Bench486ConPrintInstall (test_case);
	bench486_console_print_capture_active = 1;
	abi = Bench486ConPrintInvoke (function, test_case->first_text);
	if (test_case->second_text)
		abi |= Bench486ConPrintInvoke (function, test_case->second_text);
	bench486_console_print_capture_active = 0;
	Bench486ConPrintCapture (result, assembly, abi);
	return abi;
}

static void Bench486ConPrintCase (
		const bench486_conprint_case_t *test_case, unsigned rounding_mode)
{
	bench486_conprint_saved_t saved;
	unsigned original_control_word, test_control_word;
	unsigned abi_c, abi_asm;
	int passed, i;
	Bench486ConPrintSave (&saved);
	original_control_word = Bench486ConPrintGetControlWord ();
	test_control_word = (original_control_word & ~0x0c00U) | rounding_mode;
	Bench486ConPrintSetControlWord ((unsigned short)test_control_word);
	abi_c = Bench486ConPrintRun (test_case, (void (*)(void))
			BCP_CON_PRINT_C, &bench486_conprint_c_result, 0);
	Bench486ConPrintSetControlWord ((unsigned short)test_control_word);
	abi_asm = Bench486ConPrintRun (test_case, (void (*)(void))
			Con_Print_asm486, &bench486_conprint_asm_result, 1);
	Bench486ConPrintSetControlWord ((unsigned short)original_control_word);
	passed = !Q_memcmp (&bench486_conprint_c_result,
			&bench486_conprint_asm_result, sizeof(bench486_conprint_c_result)) &&
			!abi_c && !abi_asm &&
			bench486_conprint_asm_result.backscroll == 0 &&
			bench486_conprint_asm_result.sound_count ==
				test_case->expected_sounds &&
			!bench486_conprint_asm_result.abi;
	for (i = 0; i < BCP_GUARD_WORDS; i++)
		if (bench486_conprint_asm_result.before[i] != 0x486c3100U + i ||
				bench486_conprint_asm_result.after[i] != 0x486c3200U + i)
			passed = 0;
	if (test_case->expected_sounds &&
			Q_strcmp (bench486_conprint_asm_result.sound_name,
					"misc/talk.wav"))
		passed = 0;
	if (!passed)
	{
		int difference;
		bench486_memory_failures++;
		difference = -1;
		for (i = 0; i < ccr_textsize; i++)
			if (bench486_conprint_c_result.text[i] !=
					bench486_conprint_asm_result.text[i])
			{
				difference = i;
				break;
			}
		Bench486Printf ("Con_Print %s mode 0x%x FAIL ABI %u/%u state current/x %d/%d vs %d/%d text-byte %d sounds %d/%d\n",
				(char *)test_case->name, rounding_mode, abi_c, abi_asm,
				bench486_conprint_c_result.current,
				bench486_conprint_c_result.x,
				bench486_conprint_asm_result.current,
				bench486_conprint_asm_result.x, difference,
				bench486_conprint_c_result.sound_count,
				bench486_conprint_asm_result.sound_count);
	}
	Bench486ConPrintRestore (&saved);
}

static void Bench486ConPrintLinefeedCase (void)
{
	bench486_conprint_case_t test_case;
	bench486_conprint_saved_t saved;
	static bench486_conprint_result_t c_result, asm_result;
	unsigned abi_c, abi_asm;
	int i, passed;
	Q_memset (&test_case, 0, sizeof(test_case));
	test_case.name = "direct-linefeed-wrap";
	test_case.width = 13;
	test_case.total_lines = 7;
	test_case.current = 6;
	test_case.x = 9;
	test_case.backscroll = 4;
	test_case.seed = 23;
	test_case.realtime_value = 371.375;
	Bench486ConPrintSave (&saved);
	Bench486ConPrintInstall (&test_case);
	abi_c = Bench486Call_asm486 ((void (*)(void))BCP_CON_LINEFEED_C,
			0, NULL, NULL);
	Bench486ConPrintCapture (&c_result, 0, abi_c);
	Bench486ConPrintInstall (&test_case);
	abi_asm = Bench486Call_asm486 ((void (*)(void))Con_Linefeed_asm486,
			0, NULL, NULL);
	Bench486ConPrintCapture (&asm_result, 1, abi_asm);
	passed = !Q_memcmp (&c_result, &asm_result, sizeof(c_result)) &&
			!abi_c && !abi_asm && asm_result.current == 7 && asm_result.x == 0;
	for (i = 0; i < BCP_GUARD_WORDS; i++)
		if (asm_result.before[i] != 0x486c3100U + i ||
				asm_result.after[i] != 0x486c3200U + i)
			passed = 0;
	if (!passed)
	{
		bench486_memory_failures++;
		Bench486Printf ("Con_Linefeed direct C/ASM parity FAIL ABI %u/%u current %d/%d\n",
				abi_c, abi_asm, c_result.current, asm_result.current);
	}
	Bench486ConPrintRestore (&saved);
}

static void Bench486ConPrintCases (void)
{
	static const bench486_conprint_case_t cases[] = {
		{ "word-wrap-newline-ring-wrap", " ABCD\nxy", NULL,
			8, 8, 7, 6, 3, 1, 0, 123.5, 0 },
		{ "talk-marker-and-color", "\1talk text\n", NULL,
			12, 8, 3, 0, 7, 2, 0, 0.1, 1 },
		{ "color-marker-two", "\2color\r", NULL,
			8, 7, 6, 0, 5, 3, 0, 49.25, 0 },
		{ "carriage-return-across-call", "abc\r", "Z\nnext",
			6, 8, 7, 0, 4, 4, 0, 809.75, 0 },
		{ "word-wrap-existing-column", "world!\n", NULL,
			9, 9, 4, 6, 2, 5, 0, 17.125, 0 },
		{ "long-unbroken-word", "ABCDEFGHIJKLMN", NULL,
			5, 6, 4, 0, 2, 6, 0, 93.625, 0 },
		{ "pending-carriage-return", "X\n", NULL,
			10, 8, 5, 0, 3, 7, 1, 655.375, 0 },
		{ "high-bit-bytes", bench486_conprint_high_bytes, NULL,
			7, 8, 7, 0, 1, 8, 0, 1.1, 0 },
		{ "empty-text-backscroll-reset", "", NULL,
			11, 7, 3, 5, 6, 9, 0, 5.5, 0 }
	};
	static const unsigned rounding_modes[] =
		{ 0x0000U, 0x0400U, 0x0800U, 0x0c00U };
	bench486_conprint_saved_t saved;
	unsigned i, mode, failures_before;
	Bench486ConPrintSave (&saved);
	failures_before = bench486_memory_failures;
	Bench486Printf ("Con_Print C/ASM scrollback parity begin (%u cases x %u x87 rounding modes)\n",
			(unsigned)(sizeof(cases) / sizeof(cases[0])),
			(unsigned)(sizeof(rounding_modes) / sizeof(rounding_modes[0])));
	for (i = 0; i < sizeof(cases) / sizeof(cases[0]); i++)
		for (mode = 0; mode < sizeof(rounding_modes) /
				sizeof(rounding_modes[0]); mode++)
			Bench486ConPrintCase (&cases[i], rounding_modes[mode]);
	Bench486ConPrintLinefeedCase ();
	Bench486ConPrintRestore (&saved);
	if (bench486_memory_failures == failures_before)
		Bench486Printf ("Con_Print/Con_Linefeed exact buffer, notify-time, sound-hook, guard and ABI parity PASS (%u cases x %u modes plus direct linefeed)\n",
				(unsigned)(sizeof(cases) / sizeof(cases[0])),
				(unsigned)(sizeof(rounding_modes) / sizeof(rounding_modes[0])));
	else
		Bench486Printf ("Con_Print/Con_Linefeed exact parity FAIL\n");
}

#undef BCP_GUARD_WORDS
#undef BCP_SOUND_BYTES
#undef BCP_NOTIFY_COUNT

#endif /* BENCH486 */
#endif /* BENCH486_CONPRINT_H */
