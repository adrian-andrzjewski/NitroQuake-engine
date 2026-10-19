/* Direct C/assembly parity for the DOS video-mode menu renderer. */
#ifndef BENCH486_VIDMENUDRAW_H
#define BENCH486_VIDMENUDRAW_H

#if defined(BENCH486) && defined(ASM486_SCREEN_OVERLAYS)

#include "asm_vidmenu.h"
#include "bench486_menutext.h"

#define BVM_MAX_TEST_MODES 40
#define BVM_X87_PRECISION_COUNT 3
#define BVM_X87_ROUNDING_COUNT 4
#define BVM_GLYPH_CAPACITY 1024
#define BVM_GUARD_WORDS 2
#define BVM_PICTURE_EVENT_CAPACITY 256
#define BVM_EVENT_PIC 2
#define BVM_EVENT_CACHEPIC 4

typedef struct bench486_vid_menu_case_s
{
	const char *name;
	const char *const *descriptions;
	int mode_count;
	int current_mode;
	int cursor_line;
	int testing_mode;
	float default_mode;
	double now;
	int video_width;
	int expected_mode_count;
	int expected_column_size;
} bench486_vid_menu_case_t;

typedef struct bench486_vid_menu_result_s
{
	bench486_menu_text_result_t text;
	bench486_menu_picture_result_t pictures;
	vid_menu_mode_description_t modes[VM_MODE_COUNT];
	int mode_count;
	int column_size;
	int cursor_line;
	unsigned abi;
	unsigned short cw_before;
	unsigned short cw_after;
} bench486_vid_menu_result_t;

static const char *const bench486_vid_menu_descriptions[] =
{
	"Standard VGA 320x200",
	"Standard VGA 320x240",
	"Standard VGA 320x200",
	"VESA 320x240",
	"VESA 320x240",
	NULL,
	"VESA 640x480",
	"VESA 640x480",
	"VESA 800x600",
	"VESA 1024x768",
	"VESA 1280x720",
	"VESA 1280x720"
};

static const char *const bench486_vid_menu_testing_descriptions[] =
{
	"Standard VGA 320x200",
	"Standard VGA 320x240",
	"Standard VGA 320x200",
	"VESA 320x240",
	"VESA 640x480",
	NULL,
	"VESA 800x600",
	"VESA 800x600",
	"VESA 1024x768"
};

static const char *const bench486_vid_menu_single_description[] =
{
	"Standard VGA 320x200",
	"Standard VGA 320x240"
};

static char bench486_vid_menu_generated_text[BVM_MAX_TEST_MODES][32];
static const char *bench486_vid_menu_generated_descriptions[
		BVM_MAX_TEST_MODES];

static bench486_vid_menu_case_t bench486_vid_menu_cases[] =
{
	{ "duplicate and missing descriptions", bench486_vid_menu_descriptions,
		12, 7, 5, 0, 9.0f, 0.2499999850988388, 320, 6, 2 },
	{ "testing overlay and duplicate current mode",
		bench486_vid_menu_testing_descriptions, 9, 7, 2, 1, 8.0f,
		0.5, 640, 5, 2 },
	{ "33-entry cap and three columns",
		bench486_vid_menu_generated_descriptions, BVM_MAX_TEST_MODES,
		32, 32, 0, 6.0f, 1.2499999403953552, 1024, VM_MODE_COUNT, 11 },
	{ "single-entry one-column cursor",
		bench486_vid_menu_single_description, 2, 0, 0, 0, 0.0f,
		0.25, 319, 1, 1 }
};

static const bench486_vid_menu_case_t *bench486_vid_menu_case_active;
static qpic_t bench486_vid_menu_fake_pic;
static unsigned bench486_vid_menu_callback_calls;

extern void (*vid_menudrawfn)(void);
extern cvar_t _vid_default_mode;
extern int VID_NumModes (void);
extern char *VID_GetModeDescription (int mode);

/* bench486_menutext.h declares Bench486Call_asm486 and the trace helpers. */
extern unsigned Bench486Call_asm486 (void (*function)(void), unsigned words,
		const unsigned *arguments, float *float_return);

int Bench486VIDMenuNumModes (void)
{
	if (bench486_vid_menu_case_active)
		return bench486_vid_menu_case_active->mode_count;
	return VID_NumModes ();
}

char *Bench486VIDMenuGetModeDescription (int mode)
{
	if (!bench486_vid_menu_case_active)
		return VID_GetModeDescription (mode);
	if (mode < 0 || mode >= bench486_vid_menu_case_active->mode_count)
		return NULL;
	return (char *)bench486_vid_menu_case_active->descriptions[mode];
}

qpic_t *Bench486VIDMenuCachePic (char *path)
{
	bench486_menu_picture_event_t *event;

	if (!bench486_vid_menu_case_active || !bench486_menu_text_trace_active)
		return Draw_CachePic (path);
	if (!Bench486MenuTextPathEquals (path, "gfx/vidmodes.lmp"))
	{
		bench486_menu_picture_trace.cache_error = 1;
		return NULL;
	}
	bench486_vid_menu_fake_pic.width = 184;
	bench486_vid_menu_fake_pic.height = 32;
	if (bench486_menu_picture_trace.count < BVM_PICTURE_EVENT_CAPACITY)
	{
		event = &bench486_menu_picture_trace.events[
				bench486_menu_picture_trace.count];
		event->kind = BVM_EVENT_CACHEPIC;
		event->x = 0;
		event->y = 0;
		event->pic = &bench486_vid_menu_fake_pic;
		event->translation = NULL;
	}
	else
		bench486_menu_picture_trace.overflow = 1;
	bench486_menu_picture_trace.count++;
	return &bench486_vid_menu_fake_pic;
}

static void Bench486VIDMenuCallback (void)
{
	bench486_vid_menu_callback_calls++;
}

static void Bench486VIDMenuSetControlWord (unsigned short control_word)
{
	__asm__ __volatile__ ("fldcw %0" : : "m" (control_word));
}

static unsigned Bench486VIDMenuRun (const bench486_vid_menu_case_t *test_case,
		void (*function)(void), bench486_vid_menu_result_t *result)
{
	unsigned arguments[1] = { 0 };
	unsigned abi;
	unsigned i;
	unsigned short cw_before, cw_after;

	bench486_vid_menu_case_active = test_case;
	vid.width = test_case->video_width;
	vid_modenum = test_case->current_mode;
	vid_line = test_case->cursor_line;
	vid_testingmode = test_case->testing_mode;
	_vid_default_mode.value = test_case->default_mode;
	realtime = test_case->now;
	vid_wmodes = 0x13579bdf;
	vid_column_size = 0x2468ace0;
	for (i = 0; i < VM_MODE_COUNT; i++)
	{
		vid_modedescs[i].modenum = (int)(0x41410000U + i);
		vid_modedescs[i].desc = (char *)(0x53540000U + i * 16U);
		vid_modedescs[i].iscur = (int)(0x61610000U + i);
	}
	Bench486MenuTextInitTrace ();
	Bench486MenuPictureInitTrace ();
	bench486_menu_text_trace_active = 1;
	cw_before = Bench486MenuTextGetControlWord ();
	abi = (unsigned)(unsigned long)Bench486Call_asm486 (function, 0,
			arguments, NULL);
	cw_after = Bench486MenuTextGetControlWord ();
	bench486_menu_text_trace_active = 0;
	bench486_vid_menu_case_active = NULL;

	Q_memset (result, 0, sizeof(*result));
	Bench486MenuTextCapture (&result->text, abi, cw_before, cw_after);
	Bench486MenuPictureCapture (&result->pictures, abi, cw_before, cw_after);
	Q_memcpy (result->modes, vid_modedescs, sizeof(result->modes));
	result->mode_count = vid_wmodes;
	result->column_size = vid_column_size;
	result->cursor_line = vid_line;
	result->abi = abi;
	result->cw_before = cw_before;
	result->cw_after = cw_after;
	return ((abi & 0x20U) || cw_before != cw_after) ? 1U : 0U;
}

static unsigned Bench486VIDMenuExpected (
		const bench486_vid_menu_case_t *test_case,
		const bench486_vid_menu_result_t *result)
{
	unsigned i;
	const bench486_menu_picture_trace_t *pictures =
			&result->pictures.trace;
	const bench486_menu_text_trace_t *text = &result->text.trace;

	if (result->mode_count != test_case->expected_mode_count ||
			result->column_size != test_case->expected_column_size ||
			result->cursor_line != test_case->cursor_line)
		return 0x564d0001U;
	if (text->overflow || text->count == 0 ||
			text->count > BVM_GLYPH_CAPACITY || pictures->overflow ||
			pictures->cache_error || pictures->count != 2)
		return 0x564d0002U;
	if (pictures->events[0].kind != BVM_EVENT_CACHEPIC ||
			pictures->events[0].pic != &bench486_vid_menu_fake_pic ||
			pictures->events[1].kind != BVM_EVENT_PIC ||
			pictures->events[1].pic != &bench486_vid_menu_fake_pic)
		return 0x564d0003U;
	for (i = 0; i < BVM_GUARD_WORDS; i++)
		if (text->before[i] != 0x4d540000U + i ||
				text->after[i] != 0x4d54f000U + i)
			return 0x564d0010U + i;
	for (i = 0; i < BVM_GUARD_WORDS; i++)
		if (pictures->before[i] != 0x4d500000U + i ||
				pictures->after[i] != 0x4d50f000U + i)
			return 0x564d0020U + i;
	return 0;
}

static unsigned Bench486VIDMenuDifference (
		const bench486_vid_menu_result_t *reference,
		const bench486_vid_menu_result_t *candidate)
{
	if (reference->abi != candidate->abi ||
			reference->cw_before != candidate->cw_before ||
			reference->cw_after != candidate->cw_after ||
			reference->mode_count != candidate->mode_count ||
			reference->column_size != candidate->column_size ||
			reference->cursor_line != candidate->cursor_line)
		return 0x564d0030U;
	if (Q_memcmp ((void *)reference->modes, (void *)candidate->modes,
			sizeof(reference->modes)))
		return 0x564d0031U;
	if (Q_memcmp ((void *)&reference->text.trace,
			(void *)&candidate->text.trace,
			sizeof(reference->text.trace)))
		return 0x564d0032U;
	if (Q_memcmp ((void *)&reference->pictures.trace,
			(void *)&candidate->pictures.trace,
			sizeof(reference->pictures.trace)))
		return 0x564d0033U;
	return 0;
}

int Bench486VIDMenuDrawCases (void)
{
	unsigned short original_cw;
	unsigned short control_word;
	unsigned short precision_bits[BVM_X87_PRECISION_COUNT] =
			{ 0x0000U, 0x0200U, 0x0300U };
	unsigned precision, rounding, i, total = 0, failure = 0;
	unsigned saved_width = vid.width;
	int saved_modenum = vid_modenum;
	int saved_line = vid_line;
	int saved_testing_mode = vid_testingmode;
	int saved_wmodes = vid_wmodes;
	int saved_column_size = vid_column_size;
	float saved_default_mode = _vid_default_mode.value;
	vid_menu_mode_description_t saved_modes[VM_MODE_COUNT];
	void (*saved_video_draw)(void) = vid_menudrawfn;
	bench486_vid_menu_result_t reference, candidate;
	unsigned char saved_float[sizeof(realtime)];

	Q_memcpy (saved_modes, vid_modedescs, sizeof(saved_modes));
	Q_memcpy (saved_float, &realtime, sizeof(saved_float));
	for (i = 0; i < BVM_MAX_TEST_MODES; i++)
	{
		sprintf (bench486_vid_menu_generated_text[i],
				"Mode %02u %ux%u", i, 320U + i * 16U, 200U + i * 8U);
		bench486_vid_menu_generated_descriptions[i] =
				bench486_vid_menu_generated_text[i];
	}
	original_cw = Bench486MenuTextGetControlWord ();
	for (i = 0; i < sizeof(bench486_vid_menu_cases) /
				sizeof(bench486_vid_menu_cases[0]); i++)
	{
		for (precision = 0; precision < BVM_X87_PRECISION_COUNT; precision++)
		{
			for (rounding = 0; rounding < BVM_X87_ROUNDING_COUNT; rounding++)
			{
				control_word = (unsigned short)((original_cw & 0xf0ffU) |
						precision_bits[precision] | (rounding << 10));
				Bench486VIDMenuSetControlWord (control_word);
				failure |= Bench486VIDMenuRun (&bench486_vid_menu_cases[i],
						(void (*)(void))VID_MenuDraw_C, &reference);
				failure |= Bench486VIDMenuRun (&bench486_vid_menu_cases[i],
						(void (*)(void))VID_MenuDraw, &candidate);
				failure |= Bench486VIDMenuExpected (
						&bench486_vid_menu_cases[i], &reference);
				failure |= Bench486VIDMenuExpected (
						&bench486_vid_menu_cases[i], &candidate);
				failure |= Bench486VIDMenuDifference (&reference, &candidate);
				total++;
				if (failure)
				{
					Bench486Printf (
							"video menu C/assembly FAIL case %s precision %u rounding %u code %08x\n",
							bench486_vid_menu_cases[i].name, precision,
							rounding, failure);
					goto done;
				}
			}
		}
	}

	bench486_vid_menu_callback_calls = 0;
	vid_menudrawfn = Bench486VIDMenuCallback;
	Bench486VIDMenuSetControlWord (original_cw);
	failure |= (unsigned)(unsigned long)Bench486Call_asm486 (
			(void (*)(void))M_Video_Draw_C, 0, NULL, NULL);
	if (bench486_vid_menu_callback_calls != 1)
		failure |= 0x564d0040U;
	bench486_vid_menu_callback_calls = 0;
	failure |= (unsigned)(unsigned long)Bench486Call_asm486 (
			(void (*)(void))M_Video_Draw, 0, NULL, NULL);
	if (bench486_vid_menu_callback_calls != 1)
		failure |= 0x564d0041U;

done:
	Bench486VIDMenuSetControlWord (original_cw);
	vid.width = saved_width;
	vid_modenum = saved_modenum;
	vid_line = saved_line;
	vid_testingmode = saved_testing_mode;
	vid_wmodes = saved_wmodes;
	vid_column_size = saved_column_size;
	_vid_default_mode.value = saved_default_mode;
	Q_memcpy (&realtime, saved_float, sizeof(saved_float));
	Q_memcpy (vid_modedescs, saved_modes, sizeof(saved_modes));
	vid_menudrawfn = saved_video_draw;
	bench486_menu_text_trace_active = 0;
	bench486_vid_menu_case_active = NULL;
	if (failure)
	{
		bench486_memory_failures++;
		return (int)failure;
	}
	Bench486Printf (
			"video mode menu: %u exact C/assembly cases across x87 modes plus dispatch ABI PASS\n",
			total);
	return 0;
}

#undef BVM_X87_ROUNDING_COUNT
#undef BVM_X87_PRECISION_COUNT
#undef BVM_EVENT_CACHEPIC
#undef BVM_EVENT_PIC
#undef BVM_PICTURE_EVENT_CAPACITY
#undef BVM_GUARD_WORDS
#undef BVM_GLYPH_CAPACITY
#undef BVM_MAX_TEST_MODES

#endif

#endif
