/* C/assembly parity for menu glyph positioning and byte-to-glyph loops. */
#ifndef BENCH486_MENUTEXT_H
#define BENCH486_MENUTEXT_H

#if defined(BENCH486) && defined(ASM486_SCREEN_OVERLAYS)

#include "asm_menutext.h"

#define BMT_MAX_GLYPHS 64
#define BMT_GUARD_WORDS 2

typedef struct bench486_menu_text_glyph_s
{
	int x;
	int y;
	int num;
} bench486_menu_text_glyph_t;

typedef struct bench486_menu_text_trace_s
{
	unsigned before[BMT_GUARD_WORDS];
	unsigned count;
	unsigned overflow;
	bench486_menu_text_glyph_t glyphs[BMT_MAX_GLYPHS];
	unsigned after[BMT_GUARD_WORDS];
} bench486_menu_text_trace_t;

typedef struct bench486_menu_text_result_s
{
	bench486_menu_text_trace_t trace;
	unsigned abi;
	unsigned short cw_before;
	unsigned short cw_after;
} bench486_menu_text_result_t;

typedef struct bench486_menu_text_case_s
{
	const char *name;
	int kind; /* 0 = one glyph, 1 = M_Print, 2 = M_PrintWhite */
	unsigned width;
	int x;
	int y;
	int num;
	const char *text;
} bench486_menu_text_case_t;

static const char bench486_menu_text_high_bytes[] =
	{ 'A', (char)0x80, (char)0xff, 'Z', 0 };

static const bench486_menu_text_case_t bench486_menu_text_cases[] =
{
	{ "single-centered", 0, 320, 16, 8, 91, NULL },
	{ "single-wide-negative-origin", 0, 640, -7, 12, -31, NULL },
	{ "single-unsigned-width-wrap", 0, 319, 3, 1, 255, NULL },
	{ "print-ascii", 1, 320, 8, 40, 0, "Quake Menu" },
	{ "print-high-bytes", 1, 640, 24, 56, 0,
		bench486_menu_text_high_bytes },
	{ "print-white-high-bytes", 2, 319, 32, 72, 0,
		bench486_menu_text_high_bytes },
	{ "print-white-empty", 2, 1024, 1, 2, 0, "" }
};

static bench486_menu_text_trace_t bench486_menu_text_trace;
static bench486_menu_text_result_t bench486_menu_text_reference;
static bench486_menu_text_result_t bench486_menu_text_candidate;
int bench486_menu_text_trace_active;

extern unsigned Bench486Call_asm486 (void (*function)(void), unsigned words,
		const unsigned *arguments, float *float_return);

static unsigned short Bench486MenuTextGetControlWord (void)
{
	unsigned short control_word;
	__asm__ __volatile__ ("fnstcw %0" : "=m" (control_word));
	return control_word;
}

void Bench486MenuTextDrawCharacter (int x, int y, int num)
{
	if (!bench486_menu_text_trace_active)
	{
		Draw_Character (x, y, num);
		return;
	}

	if (bench486_menu_text_trace.count < BMT_MAX_GLYPHS)
	{
		bench486_menu_text_glyph_t *glyph =
				&bench486_menu_text_trace.glyphs[
					bench486_menu_text_trace.count];
		glyph->x = x;
		glyph->y = y;
		glyph->num = num;
	}
	else
		bench486_menu_text_trace.overflow = 1;
	bench486_menu_text_trace.count++;
}

static void Bench486MenuTextInitTrace (void)
{
	unsigned i;
	Q_memset (&bench486_menu_text_trace, 0,
			sizeof(bench486_menu_text_trace));
	for (i = 0; i < BMT_GUARD_WORDS; i++)
	{
		bench486_menu_text_trace.before[i] = 0x4d540000U + i;
		bench486_menu_text_trace.after[i] = 0x4d54f000U + i;
	}
}

static void Bench486MenuTextCapture (bench486_menu_text_result_t *result,
		unsigned abi, unsigned short cw_before, unsigned short cw_after)
{
	Q_memset (result, 0, sizeof(*result));
	Q_memcpy (&result->trace, &bench486_menu_text_trace,
			sizeof(result->trace));
	result->abi = abi;
	result->cw_before = cw_before;
	result->cw_after = cw_after;
}

static unsigned Bench486MenuTextRun (const bench486_menu_text_case_t *test_case,
		void (*function)(void), bench486_menu_text_result_t *result)
{
	unsigned arguments[3];
	unsigned abi;
	unsigned short cw_before, cw_after;

	Bench486MenuTextInitTrace ();
	vid.width = test_case->width;
	arguments[0] = (unsigned)test_case->x;
	arguments[1] = (unsigned)test_case->y;
	arguments[2] = test_case->kind ?
			(unsigned long)test_case->text : (unsigned)test_case->num;
	cw_before = Bench486MenuTextGetControlWord ();
	bench486_menu_text_trace_active = 1;
	abi = Bench486Call_asm486 (function, 3, arguments, NULL);
	bench486_menu_text_trace_active = 0;
	cw_after = Bench486MenuTextGetControlWord ();
	Bench486MenuTextCapture (result, abi, cw_before, cw_after);
	if ((abi & 0x20U) || cw_before != cw_after)
	{
		Bench486Printf ("menu text ABI/x87 FAIL case %s abi %08x cw %04x/%04x\n",
				test_case->name, abi, cw_before, cw_after);
		return 1;
	}
	return 0;
}

static unsigned Bench486MenuTextExpected (
		const bench486_menu_text_case_t *test_case,
		const bench486_menu_text_result_t *result)
{
	unsigned i, expected_count = 0;
	unsigned offset = (test_case->width - 320U) >> 1;
	int x;

	if (test_case->kind == 0)
	{
		expected_count = 1;
		if (result->trace.overflow || result->trace.count != expected_count ||
				result->trace.glyphs[0].x !=
					(int)((unsigned)test_case->x + offset) ||
				result->trace.glyphs[0].y != test_case->y ||
				result->trace.glyphs[0].num != test_case->num)
			return 0x4d540001U;
	}
	else
	{
		x = (int)((unsigned)test_case->x + offset);
		for (i = 0; test_case->text[i]; i++)
		{
			int num = test_case->text[i];
			if (test_case->kind == 1)
				num += 128;
			if (i >= BMT_MAX_GLYPHS ||
					result->trace.glyphs[i].x != x ||
					result->trace.glyphs[i].y != test_case->y ||
					result->trace.glyphs[i].num != num)
				return 0x4d540010U + i;
			x += 8;
			expected_count++;
		}
		if (result->trace.overflow ||
				result->trace.count != expected_count)
			return 0x4d540020U;
	}

	for (i = 0; i < BMT_GUARD_WORDS; i++)
		if (result->trace.before[i] != 0x4d540000U + i ||
				result->trace.after[i] != 0x4d54f000U + i)
			return 0x4d540030U + i;
	return 0;
}

static unsigned Bench486MenuTextDifference (
		const bench486_menu_text_result_t *reference,
		const bench486_menu_text_result_t *candidate)
{
	if (reference->abi != candidate->abi ||
			reference->cw_before != candidate->cw_before ||
			reference->cw_after != candidate->cw_after)
		return 0x4d540040U;
	if (Q_memcmp ((void *)&reference->trace, (void *)&candidate->trace,
			sizeof(reference->trace)))
		return 0x4d540041U;
	return 0;
}

void Bench486MenuTextCases (void)
{
	unsigned i, total, failure = 0;
	unsigned saved_width = vid.width;
	void (*c_function)(void);
	void (*asm_function)(void);

	total = sizeof(bench486_menu_text_cases) /
			sizeof(bench486_menu_text_cases[0]);
	for (i = 0; i < total; i++)
	{
		if (bench486_menu_text_cases[i].kind == 1)
		{
			c_function = (void (*)(void))M_Print_C;
			asm_function = (void (*)(void))M_Print;
		}
		else if (bench486_menu_text_cases[i].kind == 2)
		{
			c_function = (void (*)(void))M_PrintWhite_C;
			asm_function = (void (*)(void))M_PrintWhite;
		}
		else
		{
			c_function = (void (*)(void))M_DrawCharacter_C;
			asm_function = (void (*)(void))M_DrawCharacter;
		}
		failure |= Bench486MenuTextRun (&bench486_menu_text_cases[i],
				c_function,
				&bench486_menu_text_reference);
		failure |= Bench486MenuTextRun (&bench486_menu_text_cases[i],
				asm_function, &bench486_menu_text_candidate);
		failure |= Bench486MenuTextExpected (&bench486_menu_text_cases[i],
				&bench486_menu_text_reference);
		failure |= Bench486MenuTextExpected (&bench486_menu_text_cases[i],
				&bench486_menu_text_candidate);
		failure |= Bench486MenuTextDifference (&bench486_menu_text_reference,
				&bench486_menu_text_candidate);
		if (failure)
		{
			Bench486Printf ("menu text C/assembly FAIL case %s code %08x\n",
					bench486_menu_text_cases[i].name, failure);
			break;
		}
	}
	bench486_menu_text_trace_active = 0;
	vid.width = saved_width;
	if (failure)
		bench486_memory_failures++;
	else
		Bench486Printf ("menu glyph positioning and text loops: %u exact C/assembly cases PASS\n",
				total);
}

#undef BMT_GUARD_WORDS
#undef BMT_MAX_GLYPHS

#endif

#endif
