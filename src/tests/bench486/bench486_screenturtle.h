/* Direct and stateful C/assembly parity for SCR_DrawTurtle. */
/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
#ifndef BENCH486_SCREEN_TURTLE_H
#define BENCH486_SCREEN_TURTLE_H

#if defined(BENCH486) && defined(ASM486_SCREEN_TURTLE)

#include "client/asm_screenturtle.h"

#define BST_CASE_COUNT 14U
#define BST_ROUNDING_COUNT 4U
#define BST_SEQUENCE_COUNT 2048U
#define BST_EXPECT_ANY 0xffffffffU

int bench486_screen_turtle_fixture_active;

extern unsigned Bench486Call_asm486 (void (*function)(void), unsigned words,
		const unsigned *arguments, float *float_return);
extern double host_frametime;
extern cvar_t scr_showturtle;
extern vrect_t scr_vrect;
extern qpic_t *scr_turtle;

typedef struct
{
	const char *name;
	unsigned show_bits;
	unsigned frame_time_kind;
	int start_count;
	int x, y;
	unsigned pic_key;
	unsigned expected_draw;
	int expected_count;
} bench486_screen_turtle_case_t;

typedef struct
{
	unsigned calls;
	int x, y;
	unsigned pic;
	unsigned abi;
	int count_after;
	unsigned short cw_before, cw_after;
	unsigned short sw_before, sw_after;
} bench486_screen_turtle_result_t;

typedef struct
{
	unsigned calls;
	int x, y;
	unsigned pic;
} bench486_screen_turtle_trace_t;

typedef struct
{
	byte bytes[28];
} bench486_screen_turtle_x87_environment_t;

typedef struct
{
	double frame_time;
	float show_turtle;
	vrect_t view_rect;
	qpic_t *turtle_pic;
	int c_count;
	int asm_count;
} bench486_screen_turtle_saved_state_t;

typedef struct
{
	const char *name;
	unsigned short bits;
} bench486_screen_turtle_rounding_t;

static const bench486_screen_turtle_case_t bench486_screen_turtle_cases[BST_CASE_COUNT] = {
	{ "hidden-keeps-count", 0x00000000U, 4, 2, 3, 5, 1, 0, 2 },
	{ "negative-zero-hidden", 0x80000000U, 4, 2, 7, 9, 2, 0, 2 },
	{ "enabled-short-resets-zero", 0x3f800000U, 0, 0, 11, 13, 3, 0, 0 },
	{ "enabled-below-resets-two", 0x3f800000U, 1, 2, 15, 17, 4, 0, 0 },
	{ "threshold-equal-first", 0x3f800000U, 2, 0, 19, 21, 5, 0, 1 },
	{ "threshold-equal-second", 0x3f800000U, 2, 1, 23, 25, 6, 0, 2 },
	{ "threshold-equal-third-draw", 0x3f800000U, 2, 2, 27, 29, 7, 1, 3 },
	{ "slow-continuous-draw", 0x3f800000U, 4, 5, 31, 33, 8, 1, 6 },
	{ "unordered-frame-counts", 0x3f800000U, 5, 2, 35, 37, 9, 1, 3 },
	{ "positive-infinity-counts", 0x3f800000U, 6, 2, 39, 41, 10, 1, 3 },
	{ "negative-infinity-resets", 0x3f800000U, 7, 2, 43, 45, 11, 0, 0 },
	{ "unordered-show-cvar", 0x7fc12345U, 4, 2, 47, 49, 12, 0, 2 },
	{ "negative-show-cvar", 0xbf800000U, 4, 2, 51, 53, 13, 1, 3 },
	{ "extreme-coordinates", 0x3f800000U, 4, 2, 2147483647, (-2147483647 - 1), 14, 1, 3 }
};

static const bench486_screen_turtle_rounding_t bench486_screen_turtle_rounding[BST_ROUNDING_COUNT] = {
	{ "nearest", 0x0000 },
	{ "down", 0x0400 },
	{ "up", 0x0800 },
	{ "truncate", 0x0c00 }
};

static bench486_screen_turtle_trace_t bench486_screen_turtle_trace;
static bench486_screen_turtle_saved_state_t bench486_screen_turtle_saved_state;
static bench486_screen_turtle_x87_environment_t bench486_screen_turtle_saved_environment;
static bench486_screen_turtle_result_t bench486_screen_turtle_sequence_reference[BST_SEQUENCE_COUNT];

static unsigned short Bench486ScreenTurtleGetControlWord (void)
{
	unsigned short word;
	__asm__ __volatile__ ("fnstcw %0" : "=m" (word));
	return word;
}

static unsigned short Bench486ScreenTurtleGetStatusWord (void)
{
	unsigned short word;
	__asm__ __volatile__ ("fnstsw %0" : "=m" (word));
	return word;
}

static void Bench486ScreenTurtleSetControlWord (unsigned short word)
{
	__asm__ __volatile__ ("fldcw %0" : : "m" (word));
}

static void Bench486ScreenTurtleSaveEnvironment (
		bench486_screen_turtle_x87_environment_t *environment)
{
	/* FNSTENV masks exceptions; reload it immediately to preserve live state. */
	__asm__ __volatile__ ("fnstenv %0\n\tfldenv %0" : "=m" (*environment));
}

static void Bench486ScreenTurtleRestoreEnvironment (
		const bench486_screen_turtle_x87_environment_t *environment)
{
	__asm__ __volatile__ ("fldenv %0" : : "m" (*environment));
}

static void Bench486ScreenTurtleSaveState (void)
{
	bench486_screen_turtle_saved_state.frame_time = host_frametime;
	bench486_screen_turtle_saved_state.show_turtle = scr_showturtle.value;
	Q_memcpy (&bench486_screen_turtle_saved_state.view_rect, &scr_vrect,
			sizeof(scr_vrect));
	bench486_screen_turtle_saved_state.turtle_pic = scr_turtle;
	bench486_screen_turtle_saved_state.c_count = bench486_screen_turtle_c_count;
	bench486_screen_turtle_saved_state.asm_count = scr_turtle_count_asm486;
	Bench486ScreenTurtleSaveEnvironment (&bench486_screen_turtle_saved_environment);
}

static void Bench486ScreenTurtleRestoreState (void)
{
	host_frametime = bench486_screen_turtle_saved_state.frame_time;
	scr_showturtle.value = bench486_screen_turtle_saved_state.show_turtle;
	Q_memcpy (&scr_vrect, &bench486_screen_turtle_saved_state.view_rect,
			sizeof(scr_vrect));
	scr_turtle = bench486_screen_turtle_saved_state.turtle_pic;
	bench486_screen_turtle_c_count = bench486_screen_turtle_saved_state.c_count;
	scr_turtle_count_asm486 = bench486_screen_turtle_saved_state.asm_count;
	Bench486ScreenTurtleRestoreEnvironment (&bench486_screen_turtle_saved_environment);
}

void Bench486ScreenTurtleRecordDrawPic (int x, int y, qpic_t *pic)
{
	bench486_screen_turtle_trace.calls++;
	if (bench486_screen_turtle_trace.calls == 1)
	{
		bench486_screen_turtle_trace.x = x;
		bench486_screen_turtle_trace.y = y;
		bench486_screen_turtle_trace.pic = (unsigned)pic;
	}
}

static double Bench486ScreenTurtleFrameTime (unsigned kind)
{
	union { unsigned words[2]; double value; } number;
	switch (kind)
	{
	case 0: return 0.05;
	case 1: return 0.099999;
	case 2: return 0.1;
	case 3: return 0.100001;
	case 4: return 0.125;
	case 5:
		number.words[0] = 0;
		number.words[1] = 0x7ff80000U;
		return number.value;
	case 6:
		number.words[0] = 0;
		number.words[1] = 0x7ff00000U;
		return number.value;
	case 7:
		number.words[0] = 0;
		number.words[1] = 0xfff00000U;
		return number.value;
	default: return -0.0;
	}
}

static float Bench486ScreenTurtleShowValue (unsigned bits)
{
	union { unsigned bits; float value; } number;
	number.bits = bits;
	return number.value;
}

static void Bench486ScreenTurtlePrepare (
		const bench486_screen_turtle_case_t *test_case)
{
	scr_showturtle.value = Bench486ScreenTurtleShowValue (test_case->show_bits);
	host_frametime = Bench486ScreenTurtleFrameTime (test_case->frame_time_kind);
	scr_vrect.x = test_case->x;
	scr_vrect.y = test_case->y;
	scr_turtle = (qpic_t *)(0x486e0000U + test_case->pic_key * 4U);
	Q_memset (&bench486_screen_turtle_trace, 0,
			sizeof(bench486_screen_turtle_trace));
}

static unsigned Bench486ScreenTurtleRun (
		const bench486_screen_turtle_case_t *test_case, const char *implementation,
		void (*function)(void), int *count,
		unsigned short control_word, bench486_screen_turtle_result_t *result)
{
	unsigned short status_before, status_after;

	Bench486ScreenTurtlePrepare (test_case);
	__asm__ __volatile__ ("fninit");
	Bench486ScreenTurtleSetControlWord (control_word);
	result->cw_before = Bench486ScreenTurtleGetControlWord ();
	status_before = Bench486ScreenTurtleGetStatusWord ();
	bench486_screen_turtle_fixture_active = 1;
	result->abi = Bench486Call_asm486 (function, 0, NULL, NULL);
	bench486_screen_turtle_fixture_active = 0;
	result->cw_after = Bench486ScreenTurtleGetControlWord ();
	status_after = Bench486ScreenTurtleGetStatusWord ();
	result->sw_before = status_before;
	result->sw_after = status_after;
	result->calls = bench486_screen_turtle_trace.calls;
	result->x = bench486_screen_turtle_trace.x;
	result->y = bench486_screen_turtle_trace.y;
	result->pic = bench486_screen_turtle_trace.pic;
	result->count_after = *count;

	if (result->abi || result->cw_before != result->cw_after ||
			((status_before >> 11) & 7U) != ((status_after >> 11) & 7U))
	{
		Bench486Printf ("screen turtle ABI/x87 FAIL %s case %s ABI %u CW %04x/%04x SW %04x/%04x\n",
				implementation, test_case->name, result->abi,
				result->cw_before, result->cw_after, status_before, status_after);
		return 1;
	}
	if (test_case->expected_draw != BST_EXPECT_ANY &&
			(result->calls != test_case->expected_draw ||
			result->count_after != test_case->expected_count))
	{
		Bench486Printf ("screen turtle reference expectation FAIL %s case %s calls %u/%u count %d/%d\n",
				implementation, test_case->name, result->calls,
				test_case->expected_draw, result->count_after,
				test_case->expected_count);
		return 1;
	}
	if (result->calls > 1U || (result->calls &&
			(result->x != test_case->x || result->y != test_case->y ||
			result->pic != (unsigned)scr_turtle)))
	{
		Bench486Printf ("screen turtle draw arguments FAIL %s case %s calls %u x/y %d/%d pic %08x\n",
				implementation, test_case->name, result->calls,
				result->x, result->y, result->pic);
		return 1;
	}
	return 0;
}

static unsigned Bench486ScreenTurtleDifferent (
		const bench486_screen_turtle_result_t *reference,
		const bench486_screen_turtle_result_t *candidate)
{
	return reference->calls != candidate->calls ||
			reference->x != candidate->x || reference->y != candidate->y ||
			reference->pic != candidate->pic || reference->abi != candidate->abi ||
			reference->count_after != candidate->count_after ||
			reference->cw_before != candidate->cw_before ||
			reference->cw_after != candidate->cw_after ||
			reference->sw_before != candidate->sw_before ||
			reference->sw_after != candidate->sw_after;
}

static void Bench486ScreenTurtlePrepareSequenceCase (
		unsigned index, bench486_screen_turtle_case_t *test_case)
{
	static const unsigned show_values[8] = {
		0x00000000U, 0x80000000U, 0x3f800000U, 0xbf800000U,
		0x7fc12345U, 0x7f800000U, 0x00000001U, 0x3e800000U
	};
	test_case->name = "long-sequence";
	test_case->show_bits = show_values[(index * 13U + index / 7U) & 7U];
	test_case->frame_time_kind = index & 7U;
	test_case->start_count = 0;
	test_case->x = (index & 1U) ? -(int)(index * 3U) : (int)(index * 3U);
	test_case->y = (index & 2U) ? -(int)(index * 5U) : (int)(index * 5U);
	test_case->pic_key = index + 100U;
	test_case->expected_draw = BST_EXPECT_ANY;
	test_case->expected_count = 0;
}

static unsigned Bench486ScreenTurtleLongSequence (
		unsigned short control_word, unsigned mode_index)
{
	unsigned i, failures = 0;
	bench486_screen_turtle_case_t test_case;
	bench486_screen_turtle_result_t candidate;

	bench486_screen_turtle_c_count = 0;
	for (i = 0; i < BST_SEQUENCE_COUNT; i++)
	{
		Bench486ScreenTurtlePrepareSequenceCase (i, &test_case);
		if (Bench486ScreenTurtleRun (&test_case, "C sequence",
				SCR_DrawTurtle_Screen_C, &bench486_screen_turtle_c_count,
				control_word, &bench486_screen_turtle_sequence_reference[i]))
			failures++;
	}

	bench486_screen_turtle_c_count = 0;
	scr_turtle_count_asm486 = 0;
	for (i = 0; i < BST_SEQUENCE_COUNT; i++)
	{
		Bench486ScreenTurtlePrepareSequenceCase (i, &test_case);
		if (Bench486ScreenTurtleRun (&test_case, "assembly sequence",
				SCR_DrawTurtle_asm486, &scr_turtle_count_asm486,
				control_word, &candidate))
			failures++;
		if (Bench486ScreenTurtleDifferent (
				&bench486_screen_turtle_sequence_reference[i], &candidate))
		{
			Bench486Printf ("screen turtle sequence mismatch frame %u mode %s calls %u/%u count %d/%d SW %04x/%04x\n",
					i, bench486_screen_turtle_rounding[mode_index].name,
					bench486_screen_turtle_sequence_reference[i].calls,
					candidate.calls,
					bench486_screen_turtle_sequence_reference[i].count_after,
					candidate.count_after,
					bench486_screen_turtle_sequence_reference[i].sw_after,
					candidate.sw_after);
			failures++;
			break;
		}
	}
	return failures;
}

void Bench486ScreenTurtleCases (void)
{
	static const unsigned short rounding_bits[BST_ROUNDING_COUNT] = {
		0x0000, 0x0400, 0x0800, 0x0c00
	};
	unsigned case_index, rounding_index;
	unsigned before = bench486_memory_failures;
	unsigned short control_word = Bench486ScreenTurtleGetControlWord ();
	bench486_screen_turtle_result_t reference, candidate;

	Bench486ScreenTurtleSaveState ();
	for (rounding_index = 0; rounding_index < BST_ROUNDING_COUNT; rounding_index++)
	{
		for (case_index = 0; case_index < BST_CASE_COUNT; case_index++)
		{
			const bench486_screen_turtle_case_t *test_case =
					&bench486_screen_turtle_cases[case_index];
			unsigned short test_control =
					(unsigned short)(0x037fU | rounding_bits[rounding_index]);
			bench486_screen_turtle_c_count = test_case->start_count;
			scr_turtle_count_asm486 = test_case->start_count;
			if (Bench486ScreenTurtleRun (test_case, "C",
					SCR_DrawTurtle_Screen_C,
					&bench486_screen_turtle_c_count,
					test_control, &reference))
				bench486_memory_failures++;
			if (Bench486ScreenTurtleRun (test_case, "assembly",
					SCR_DrawTurtle_asm486,
					&scr_turtle_count_asm486,
					test_control, &candidate))
				bench486_memory_failures++;
			if (Bench486ScreenTurtleDifferent (&reference, &candidate))
			{
				Bench486Printf ("screen turtle C/assembly mismatch case %s mode %s calls %u/%u count %d/%d x/y %d/%d %d/%d SW %04x/%04x\n",
						test_case->name,
						bench486_screen_turtle_rounding[rounding_index].name,
						reference.calls, candidate.calls,
						reference.count_after, candidate.count_after,
						reference.x, reference.y, candidate.x, candidate.y,
						reference.sw_after, candidate.sw_after);
				bench486_memory_failures++;
			}
		}
		bench486_screen_turtle_c_count = 0;
		scr_turtle_count_asm486 = 0;
		bench486_memory_failures += Bench486ScreenTurtleLongSequence (
				(unsigned short)(0x037fU | rounding_bits[rounding_index]),
				rounding_index);
	}
	Bench486ScreenTurtleSetControlWord (control_word);
	Bench486ScreenTurtleRestoreState ();
	if (bench486_memory_failures == before)
	{
		Bench486Printf ("SCR_DrawTurtle %u exact C/assembly cases x %u x87 rounding modes PASS\n",
				BST_CASE_COUNT, BST_ROUNDING_COUNT);
		Bench486Printf ("SCR_DrawTurtle %u-frame stateful sequence x %u rounding modes PASS\n",
				BST_SEQUENCE_COUNT, BST_ROUNDING_COUNT);
	}
}

#endif

#endif /* BENCH486_SCREEN_TURTLE_H */
