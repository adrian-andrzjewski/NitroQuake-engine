/* C/assembly parity for menu glyph positioning and byte-to-glyph loops. */
#ifndef BENCH486_MENUTEXT_H
#define BENCH486_MENUTEXT_H

#if defined(BENCH486) && defined(ASM486_SCREEN_OVERLAYS)

#include "asm_menutext.h"

#define BMT_MAX_GLYPHS 64
#define BMT_GUARD_WORDS 2
#define BMP_MAX_EVENTS 128
#define BMP_GUARD_WORDS 2

#define BMP_EVENT_TRANSPIC 1
#define BMP_EVENT_PIC 2
#define BMP_EVENT_TRANSPIC_TRANSLATE 3
#define BMP_EVENT_CACHEPIC 4

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

typedef struct bench486_menu_picture_event_s
{
	int kind;
	int x;
	int y;
	qpic_t *pic;
	byte *translation;
} bench486_menu_picture_event_t;

typedef struct bench486_menu_picture_trace_s
{
	unsigned before[BMP_GUARD_WORDS];
	unsigned count;
	unsigned overflow;
	unsigned cache_error;
	bench486_menu_picture_event_t events[BMP_MAX_EVENTS];
	unsigned after[BMP_GUARD_WORDS];
} bench486_menu_picture_trace_t;

typedef struct bench486_menu_picture_result_s
{
	bench486_menu_picture_trace_t trace;
	unsigned abi;
	unsigned short cw_before;
	unsigned short cw_after;
} bench486_menu_picture_result_t;

typedef struct bench486_menu_picture_case_s
{
	const char *name;
	int kind;
	unsigned width;
	int x;
	int y;
	qpic_t *pic;
} bench486_menu_picture_case_t;

typedef struct bench486_menu_textbox_case_s
{
	const char *name;
	unsigned video_width;
	int x;
	int y;
	int width;
	int lines;
} bench486_menu_textbox_case_t;

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
static unsigned bench486_menu_picture_fake_pic[128];
static bench486_menu_picture_trace_t bench486_menu_picture_trace;
static bench486_menu_picture_result_t bench486_menu_picture_reference;
static bench486_menu_picture_result_t bench486_menu_picture_candidate;

static const bench486_menu_picture_case_t bench486_menu_picture_cases[] =
{
	{ "transpic-centered", BMP_EVENT_TRANSPIC, 320, 16, 8,
		(qpic_t *)bench486_menu_picture_fake_pic },
	{ "transpic-wide-negative-origin", BMP_EVENT_TRANSPIC, 640, -7, 12,
		(qpic_t *)bench486_menu_picture_fake_pic },
	{ "pic-narrow-width", BMP_EVENT_PIC, 319, 3, 1,
		(qpic_t *)bench486_menu_picture_fake_pic },
	{ "pic-wide", BMP_EVENT_PIC, 1024, 24, 56,
		(qpic_t *)(bench486_menu_picture_fake_pic + 1) },
	{ "translate-narrow-width", BMP_EVENT_TRANSPIC_TRANSLATE, 319, 11, 72,
		(qpic_t *)(bench486_menu_picture_fake_pic + 2) },
	{ "translate-wide-negative-origin", BMP_EVENT_TRANSPIC_TRANSLATE,
		640, -19, 40, (qpic_t *)(bench486_menu_picture_fake_pic + 3) }
};

static const char *bench486_menu_cache_paths[] =
{
	"gfx/box_tl.lmp",
	"gfx/box_ml.lmp",
	"gfx/box_bl.lmp",
	"gfx/box_tm.lmp",
	"gfx/box_mm.lmp",
	"gfx/box_mm2.lmp",
	"gfx/box_bm.lmp",
	"gfx/box_tr.lmp",
	"gfx/box_mr.lmp",
	"gfx/box_br.lmp",
	"gfx/qplaque.lmp",
	"gfx/ttl_main.lmp",
	"gfx/mainmenu.lmp",
	"gfx/ttl_sgl.lmp",
	"gfx/sp_menu.lmp",
	"gfx/menudot1.lmp",
	"gfx/menudot2.lmp",
	"gfx/menudot3.lmp",
	"gfx/menudot4.lmp",
	"gfx/menudot5.lmp",
	"gfx/menudot6.lmp",
	"gfx/help0.lmp",
	"gfx/help1.lmp",
	"gfx/help2.lmp",
	"gfx/help3.lmp",
	"gfx/help4.lmp",
	"gfx/help5.lmp"
};

static const bench486_menu_textbox_case_t bench486_menu_textbox_cases[] =
{
	{ "textbox-zero-width", 320, 16, 20, 0, 0 },
	{ "textbox-one-column", 640, -8, 32, 2, 1 },
	{ "textbox-odd-width-multirow", 640, 24, 48, 5, 3 },
	{ "textbox-mm2-narrow-screen", 319, 10, 72, 6, 4 },
	{ "textbox-negative-width", 1024, -12, 64, -1, 2 }
};

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

void Bench486MenuTextDrawPic (int kind, int x, int y, qpic_t *pic,
		byte *translation)
{
	bench486_menu_picture_event_t *event;

	if (!bench486_menu_text_trace_active)
	{
		if (kind == BMP_EVENT_TRANSPIC)
			Draw_TransPic (x, y, pic);
		else if (kind == BMP_EVENT_PIC)
			Draw_Pic (x, y, pic);
		else if (kind == BMP_EVENT_TRANSPIC_TRANSLATE)
			Draw_TransPicTranslate (x, y, pic, translation);
		return;
	}

	if (bench486_menu_picture_trace.count < BMP_MAX_EVENTS)
	{
		event = &bench486_menu_picture_trace.events[
				bench486_menu_picture_trace.count];
		event->kind = kind;
		event->x = x;
		event->y = y;
		event->pic = pic;
		event->translation = translation;
	}
	else
		bench486_menu_picture_trace.overflow = 1;
	bench486_menu_picture_trace.count++;
}

static int Bench486MenuTextPathEquals (const char *left, const char *right)
{
	while (*left && *left == *right)
	{
		left++;
		right++;
	}
	return *left == *right;
}

qpic_t *Bench486MenuTextCachePic (char *path)
{
	unsigned i;
	qpic_t *pic;
	bench486_menu_picture_event_t *event;

	if (!bench486_menu_text_trace_active)
		return Draw_CachePic (path);
	for (i = 0; i < sizeof(bench486_menu_cache_paths) /
				sizeof(bench486_menu_cache_paths[0]); i++)
	{
		if (!Bench486MenuTextPathEquals (path,
				bench486_menu_cache_paths[i]))
			continue;
		pic = (qpic_t *)(bench486_menu_picture_fake_pic + i * 4);
		if (bench486_menu_picture_trace.count < BMP_MAX_EVENTS)
		{
			event = &bench486_menu_picture_trace.events[
					bench486_menu_picture_trace.count];
			event->kind = BMP_EVENT_CACHEPIC;
			event->x = 0;
			event->y = 0;
			event->pic = pic;
			event->translation = NULL;
		}
		else
			bench486_menu_picture_trace.overflow = 1;
		bench486_menu_picture_trace.count++;
		return pic;
	}
	bench486_menu_picture_trace.cache_error = 1;
	return NULL;
}

static void Bench486MenuPictureInitTrace (void)
{
	unsigned i;
	Q_memset (&bench486_menu_picture_trace, 0,
			sizeof(bench486_menu_picture_trace));
	for (i = 0; i < BMP_GUARD_WORDS; i++)
	{
		bench486_menu_picture_trace.before[i] = 0x4d500000U + i;
		bench486_menu_picture_trace.after[i] = 0x4d50f000U + i;
	}
}

static void Bench486MenuPictureCapture (bench486_menu_picture_result_t *result,
		unsigned abi, unsigned short cw_before, unsigned short cw_after)
{
	Q_memset (result, 0, sizeof(*result));
	Q_memcpy (&result->trace, &bench486_menu_picture_trace,
			sizeof(result->trace));
	result->abi = abi;
	result->cw_before = cw_before;
	result->cw_after = cw_after;
}

static unsigned Bench486MenuPictureRun (
		const bench486_menu_picture_case_t *test_case,
		void (*function)(void), bench486_menu_picture_result_t *result)
{
	unsigned arguments[3];
	unsigned abi;
	unsigned short cw_before, cw_after;

	Bench486MenuPictureInitTrace ();
	vid.width = test_case->width;
	arguments[0] = (unsigned)test_case->x;
	arguments[1] = (unsigned)test_case->y;
	arguments[2] = (unsigned)test_case->pic;
	cw_before = Bench486MenuTextGetControlWord ();
	bench486_menu_text_trace_active = 1;
	abi = Bench486Call_asm486 (function, 3, arguments, NULL);
	bench486_menu_text_trace_active = 0;
	cw_after = Bench486MenuTextGetControlWord ();
	Bench486MenuPictureCapture (result, abi, cw_before, cw_after);
	if ((abi & 0x20U) || cw_before != cw_after)
	{
		Bench486Printf (
				"menu picture ABI/x87 FAIL case %s abi %08x cw %04x/%04x\n",
				test_case->name, abi, cw_before, cw_after);
		return 1;
	}
	return 0;
}

static unsigned Bench486MenuPictureExpected (
		const bench486_menu_picture_case_t *test_case,
		const bench486_menu_picture_result_t *result)
{
	unsigned i;
	unsigned offset = (test_case->width - 320U) >> 1;
	int expected_x = (int)((unsigned)test_case->x + offset);
	const bench486_menu_picture_event_t *event;

	if (result->trace.overflow || result->trace.cache_error ||
			result->trace.count != 1)
		return 0x4d500001U;
	event = &result->trace.events[0];
	if (event->kind != test_case->kind ||
			event->x != expected_x ||
			event->y != test_case->y || event->pic != test_case->pic ||
			event->translation != (test_case->kind ==
				BMP_EVENT_TRANSPIC_TRANSLATE ? translationTable : NULL))
		return 0x4d500002U;
	for (i = 0; i < BMP_GUARD_WORDS; i++)
		if (result->trace.before[i] != 0x4d500000U + i ||
				result->trace.after[i] != 0x4d50f000U + i)
			return 0x4d500010U + i;
	return 0;
}

static unsigned Bench486MenuPictureDifference (
		const bench486_menu_picture_result_t *reference,
		const bench486_menu_picture_result_t *candidate)
{
	if (reference->abi != candidate->abi ||
			reference->cw_before != candidate->cw_before ||
			reference->cw_after != candidate->cw_after)
		return 0x4d500020U;
	if (Q_memcmp ((void *)&reference->trace, (void *)&candidate->trace,
			sizeof(reference->trace)))
		return 0x4d500021U;
	return 0;
}

static unsigned Bench486MenuTextBoxRun (
		const bench486_menu_textbox_case_t *test_case,
		void (*function)(void), bench486_menu_picture_result_t *result)
{
	unsigned arguments[4];
	unsigned abi;
	unsigned short cw_before, cw_after;

	Bench486MenuPictureInitTrace ();
	vid.width = test_case->video_width;
	arguments[0] = (unsigned)test_case->x;
	arguments[1] = (unsigned)test_case->y;
	arguments[2] = (unsigned)test_case->width;
	arguments[3] = (unsigned)test_case->lines;
	cw_before = Bench486MenuTextGetControlWord ();
	bench486_menu_text_trace_active = 1;
	abi = Bench486Call_asm486 (function, 4, arguments, NULL);
	bench486_menu_text_trace_active = 0;
	cw_after = Bench486MenuTextGetControlWord ();
	Bench486MenuPictureCapture (result, abi, cw_before, cw_after);
	if ((abi & 0x20U) || cw_before != cw_after)
	{
		Bench486Printf (
				"menu text box ABI/x87 FAIL case %s abi %08x cw %04x/%04x\n",
				test_case->name, abi, cw_before, cw_after);
		return 1;
	}
	return 0;
}

static unsigned Bench486MenuTextBoxExpected (
		const bench486_menu_textbox_case_t *test_case,
		const bench486_menu_picture_result_t *result)
{
	unsigned i, draw_count, cache_count, middle_columns, line_count;
	unsigned expected_count, offset, box_mm2_count = 0;
	int left_x, right_x, bottom_y;
	const bench486_menu_picture_event_t *event;
	const qpic_t *box_tl = (const qpic_t *)bench486_menu_picture_fake_pic;
	const qpic_t *box_br = (const qpic_t *)(bench486_menu_picture_fake_pic + 36);

	line_count = test_case->lines > 0 ? (unsigned)test_case->lines : 0;
	middle_columns = test_case->width > 0 ?
			((unsigned)test_case->width + 1U) / 2U : 0;
	draw_count = (middle_columns + 2U) * (line_count + 2U);
	cache_count = 6U + middle_columns *
			(3U + (line_count > 1U ? 1U : 0U));
	expected_count = draw_count + cache_count;
	offset = (test_case->video_width - 320U) >> 1;
	left_x = (int)((unsigned)test_case->x + offset);
	right_x = (int)((unsigned)test_case->x + offset + 8U +
			middle_columns * 16U);
	bottom_y = test_case->y + (int)((line_count + 1U) * 8U);
	if (result->trace.overflow || result->trace.cache_error ||
			result->trace.count != expected_count)
		return 0x4d540101U;
	for (i = 0; i < BMP_GUARD_WORDS; i++)
		if (result->trace.before[i] != 0x4d500000U + i ||
				result->trace.after[i] != 0x4d50f000U + i)
			return 0x4d540102U + i;
	event = &result->trace.events[0];
	if (event->kind != BMP_EVENT_CACHEPIC || event->pic != box_tl)
		return 0x4d540104U;
	event = &result->trace.events[1];
	if (event->kind != BMP_EVENT_TRANSPIC || event->x != left_x ||
			event->y != test_case->y || event->pic != box_tl ||
			event->translation)
		return 0x4d540105U;
	event = &result->trace.events[expected_count - 2U];
	if (event->kind != BMP_EVENT_CACHEPIC || event->pic != box_br)
		return 0x4d540106U;
	event = &result->trace.events[expected_count - 1U];
	if (event->kind != BMP_EVENT_TRANSPIC || event->x != right_x ||
			event->y != bottom_y || event->pic != box_br ||
		event->translation)
		return 0x4d540107U;
	for (i = 0; i < expected_count; i++)
	{
		event = &result->trace.events[i];
		if (event->kind == BMP_EVENT_CACHEPIC)
		{
			if (event->x || event->y || !event->pic || event->translation)
				return 0x4d540110U + i;
			if (event->pic == (const qpic_t *)(bench486_menu_picture_fake_pic + 20))
				box_mm2_count++;
		}
		else if (event->kind != BMP_EVENT_TRANSPIC || !event->pic ||
				event->translation)
			return 0x4d540120U + i;
	}
	if (box_mm2_count != (line_count > 1U ? middle_columns : 0U))
		return 0x4d540130U;
	return 0;
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

void Bench486MenuPictureCases (void)
{
	unsigned i, total, failure = 0;
	unsigned saved_width = vid.width;
	byte saved_translation[256];
	void (*c_function)(void);
	void (*asm_function)(void);

	Q_memcpy (saved_translation, translationTable, sizeof(saved_translation));
	total = sizeof(bench486_menu_picture_cases) /
			sizeof(bench486_menu_picture_cases[0]);
	for (i = 0; i < total; i++)
	{
		if (bench486_menu_picture_cases[i].kind == BMP_EVENT_TRANSPIC)
		{
			c_function = (void (*)(void))M_DrawTransPic_C;
			asm_function = (void (*)(void))M_DrawTransPic;
		}
		else if (bench486_menu_picture_cases[i].kind == BMP_EVENT_PIC)
		{
			c_function = (void (*)(void))M_DrawPic_C;
			asm_function = (void (*)(void))M_DrawPic;
		}
		else
		{
			c_function = (void (*)(void))M_DrawTransPicTranslate_C;
			asm_function = (void (*)(void))M_DrawTransPicTranslate;
		}
		failure |= Bench486MenuPictureRun (&bench486_menu_picture_cases[i],
				c_function, &bench486_menu_picture_reference);
		failure |= Bench486MenuPictureRun (&bench486_menu_picture_cases[i],
				asm_function, &bench486_menu_picture_candidate);
		failure |= Bench486MenuPictureExpected (
				&bench486_menu_picture_cases[i],
				&bench486_menu_picture_reference);
		failure |= Bench486MenuPictureExpected (
				&bench486_menu_picture_cases[i],
				&bench486_menu_picture_candidate);
		failure |= Bench486MenuPictureDifference (
				&bench486_menu_picture_reference,
				&bench486_menu_picture_candidate);
		if (failure)
		{
			Bench486Printf (
					"menu picture C/assembly FAIL case %s code %08x\n",
					bench486_menu_picture_cases[i].name, failure);
			break;
		}
	}
	bench486_menu_text_trace_active = 0;
	vid.width = saved_width;
	Q_memcpy (translationTable, saved_translation, sizeof(saved_translation));
	if (failure)
		bench486_memory_failures++;
	else
		Bench486Printf (
				"centered menu picture wrappers: %u exact C/assembly cases PASS\n",
				total);
}

void Bench486MenuTextBoxCases (void)
{
	unsigned i, total, failure = 0;
	unsigned saved_width = vid.width;
	void (*c_function)(void) = (void (*)(void))M_DrawTextBox_C;
	void (*asm_function)(void) = (void (*)(void))M_DrawTextBox;

	total = sizeof(bench486_menu_textbox_cases) /
			sizeof(bench486_menu_textbox_cases[0]);
	for (i = 0; i < total; i++)
	{
		failure |= Bench486MenuTextBoxRun (
				&bench486_menu_textbox_cases[i], c_function,
				&bench486_menu_picture_reference);
		failure |= Bench486MenuTextBoxRun (
				&bench486_menu_textbox_cases[i], asm_function,
				&bench486_menu_picture_candidate);
		failure |= Bench486MenuTextBoxExpected (
				&bench486_menu_textbox_cases[i],
				&bench486_menu_picture_reference);
		failure |= Bench486MenuTextBoxExpected (
				&bench486_menu_textbox_cases[i],
				&bench486_menu_picture_candidate);
		failure |= Bench486MenuPictureDifference (
				&bench486_menu_picture_reference,
				&bench486_menu_picture_candidate);
		if (failure)
		{
			Bench486Printf (
					"menu text box C/assembly FAIL case %s code %08x\n",
					bench486_menu_textbox_cases[i].name, failure);
			break;
		}
	}
	bench486_menu_text_trace_active = 0;
	vid.width = saved_width;
	if (failure)
		bench486_memory_failures++;
	else
		Bench486Printf (
				"menu text box tile/draw sequence: %u exact C/assembly cases PASS\n",
				total);
}

#undef BMT_GUARD_WORDS
#undef BMT_MAX_GLYPHS
#undef BMP_GUARD_WORDS
#undef BMP_MAX_EVENTS
#undef BMP_EVENT_TRANSPIC_TRANSLATE
#undef BMP_EVENT_PIC
#undef BMP_EVENT_TRANSPIC
#undef BMP_EVENT_CACHEPIC

#endif

#endif
