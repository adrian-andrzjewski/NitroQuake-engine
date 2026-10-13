/* Direct C/assembly call, control-flow and x87-state parity for SCR_DrawNet. */
#ifndef BENCH486_SCREEN_NET_H
#define BENCH486_SCREEN_NET_H

#if defined(BENCH486) && defined(ASM486_SCREEN_NET)

#include "asm_screennet.h"

#define BSN_CASE_COUNT 10U
#define BSN_ROUNDING_COUNT 4U

int bench486_screen_net_fixture_active;

extern unsigned Bench486Call_asm486 (void (*function)(void), unsigned words,
		const unsigned *arguments, float *float_return);
extern double realtime;
extern client_state_t cl;
extern client_static_t cls;
extern vrect_t scr_vrect;
extern qpic_t *scr_net;

typedef struct
{
	const char *name;
	unsigned time_kind;
	unsigned message_kind;
	int demo_playback;
	int view_x, view_y;
	unsigned expected_draw;
} bench486_screen_net_case_t;

typedef struct
{
	unsigned calls;
	int x, y;
	unsigned pic;
	unsigned abi;
	unsigned short cw_before, cw_after;
	unsigned short sw_before, sw_after;
} bench486_screen_net_result_t;

typedef struct
{
	byte bytes[28];
} bench486_screen_net_x87_environment_t;

typedef struct
{
	double realtime_value;
	float last_message;
	int demo_playback;
	vrect_t view_rect;
	qpic_t *net_pic;
} bench486_screen_net_saved_state_t;

typedef struct
{
	const char *name;
	unsigned short bits;
} bench486_screen_net_rounding_t;

static const bench486_screen_net_case_t bench486_screen_net_cases[BSN_CASE_COUNT] = {
	{ "recent-message", 0, 0, 0, 5, 7, 0 },
	{ "threshold-below", 1, 0, 0, 9, 11, 0 },
	{ "threshold-equal", 2, 0, 0, 13, 15, 1 },
	{ "threshold-above", 3, 0, 0, 17, 19, 1 },
	{ "demo-playback-stale", 4, 2, 1, 21, 23, 0 },
	{ "unordered-current-time", 5, 0, 0, 25, 27, 0 },
	{ "positive-infinity", 6, 0, 0, 29, 31, 1 },
	{ "negative-infinity", 7, 0, 0, 33, 35, 0 },
	{ "unordered-message-time", 8, 1, 0, 37, 39, 0 },
	{ "stale-live-message", 4, 2, 0, 41, 43, 1 }
};

static const bench486_screen_net_rounding_t bench486_screen_net_rounding[BSN_ROUNDING_COUNT] = {
	{ "nearest", 0x0000 },
	{ "down", 0x0400 },
	{ "up", 0x0800 },
	{ "truncate", 0x0c00 }
};

static bench486_screen_net_result_t bench486_screen_net_trace;
static bench486_screen_net_saved_state_t bench486_screen_net_saved_state;
static bench486_screen_net_x87_environment_t bench486_screen_net_saved_environment;

static unsigned short Bench486ScreenNetGetControlWord (void)
{
	unsigned short word;
	__asm__ __volatile__ ("fnstcw %0" : "=m" (word));
	return word;
}

static unsigned short Bench486ScreenNetGetStatusWord (void)
{
	unsigned short word;
	__asm__ __volatile__ ("fnstsw %0" : "=m" (word));
	return word;
}

static void Bench486ScreenNetSetControlWord (unsigned short word)
{
	__asm__ __volatile__ ("fldcw %0" : : "m" (word));
}

static void Bench486ScreenNetSaveEnvironment (
		bench486_screen_net_x87_environment_t *environment)
{
	/* FNSTENV masks exceptions; reload it immediately to leave the live FPU intact. */
	__asm__ __volatile__ ("fnstenv %0\n\tfldenv %0" : "=m" (*environment));
}

static void Bench486ScreenNetRestoreEnvironment (
		const bench486_screen_net_x87_environment_t *environment)
{
	__asm__ __volatile__ ("fldenv %0" : : "m" (*environment));
}

static void Bench486ScreenNetSaveState (void)
{
	bench486_screen_net_saved_state.realtime_value = realtime;
	bench486_screen_net_saved_state.last_message = cl.last_received_message;
	bench486_screen_net_saved_state.demo_playback = cls.demoplayback;
	Q_memcpy (&bench486_screen_net_saved_state.view_rect, &scr_vrect,
			sizeof(scr_vrect));
	bench486_screen_net_saved_state.net_pic = scr_net;
	Bench486ScreenNetSaveEnvironment (&bench486_screen_net_saved_environment);
}

static void Bench486ScreenNetRestoreState (void)
{
	realtime = bench486_screen_net_saved_state.realtime_value;
	cl.last_received_message = bench486_screen_net_saved_state.last_message;
	cls.demoplayback = bench486_screen_net_saved_state.demo_playback;
	Q_memcpy (&scr_vrect, &bench486_screen_net_saved_state.view_rect,
			sizeof(scr_vrect));
	scr_net = bench486_screen_net_saved_state.net_pic;
	Bench486ScreenNetRestoreEnvironment (&bench486_screen_net_saved_environment);
}

void Bench486ScreenNetRecordDrawPic (int x, int y, qpic_t *pic)
{
	bench486_screen_net_trace.calls++;
	if (bench486_screen_net_trace.calls == 1)
	{
		bench486_screen_net_trace.x = x;
		bench486_screen_net_trace.y = y;
		bench486_screen_net_trace.pic = (unsigned)pic;
	}
}

static double Bench486ScreenNetTimeValue (unsigned kind)
{
	union { unsigned words[2]; double value; } number;
	switch (kind)
	{
	case 0: return 100.0;
	case 1: return 0.29999;
	case 2: return 0.3;
	case 3: return 0.30001;
	case 4: return 100.0;
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
	default: return 0.0;
	}
}

static float Bench486ScreenNetMessageValue (unsigned kind)
{
	union { unsigned bits; float value; } number;
	if (kind == 1)
	{
		number.bits = 0x7fc12345U;
		return number.value;
	}
	if (kind == 2)
	{
		number.bits = 0x00000000U;
		return number.value;
	}
	return kind == 0 ? 99.8f : 0.0f;
}

static void Bench486ScreenNetPrepare (const bench486_screen_net_case_t *test_case)
{
	realtime = Bench486ScreenNetTimeValue (test_case->time_kind);
	cl.last_received_message = test_case->time_kind == 1 ||
			test_case->time_kind == 2 || test_case->time_kind == 3 ? 0.0f :
			Bench486ScreenNetMessageValue (test_case->message_kind);
	cls.demoplayback = test_case->demo_playback;
	scr_vrect.x = test_case->view_x;
	scr_vrect.y = test_case->view_y;
	scr_net = (qpic_t *)(0x486e0000U + test_case->view_x);
	Q_memset (&bench486_screen_net_trace, 0, sizeof(bench486_screen_net_trace));
}

static unsigned Bench486ScreenNetRun (
		const bench486_screen_net_case_t *test_case, const char *implementation,
		void (*function)(void), unsigned short control_word,
		bench486_screen_net_result_t *result)
{
	unsigned short status_before, status_after;

	Bench486ScreenNetPrepare (test_case);
	/* FNINIT also clears the comparison-condition bits left by the prior call. */
	__asm__ __volatile__ ("fninit");
	Bench486ScreenNetSetControlWord (control_word);
	result->cw_before = Bench486ScreenNetGetControlWord ();
	status_before = Bench486ScreenNetGetStatusWord ();
	bench486_screen_net_fixture_active = 1;
	result->abi = Bench486Call_asm486 (function, 0, NULL, NULL);
	bench486_screen_net_fixture_active = 0;
	result->cw_after = Bench486ScreenNetGetControlWord ();
	status_after = Bench486ScreenNetGetStatusWord ();
	result->sw_before = status_before;
	result->sw_after = status_after;
	result->calls = bench486_screen_net_trace.calls;
	result->x = bench486_screen_net_trace.x;
	result->y = bench486_screen_net_trace.y;
	result->pic = bench486_screen_net_trace.pic;

	if (result->abi || result->cw_before != result->cw_after ||
			((status_before >> 11) & 7U) != ((status_after >> 11) & 7U))
	{
		Bench486Printf ("screen net ABI/x87 FAIL %s case %s ABI %u CW %04x/%04x SW %04x/%04x\n",
				implementation, test_case->name, result->abi,
				result->cw_before, result->cw_after, status_before, status_after);
		return 1;
	}
	if (result->calls != test_case->expected_draw || result->calls > 1U ||
			(result->calls && (result->x != test_case->view_x + 64 ||
			result->y != test_case->view_y ||
			result->pic != (unsigned)scr_net)))
	{
		Bench486Printf ("screen net branch/call FAIL %s case %s calls %u expected %u x/y %d/%d\n",
				implementation, test_case->name, result->calls,
				test_case->expected_draw, result->x, result->y);
		return 1;
	}
	return 0;
}

static unsigned Bench486ScreenNetDifferent (
		const bench486_screen_net_result_t *reference,
		const bench486_screen_net_result_t *candidate)
{
	return reference->calls != candidate->calls ||
			reference->x != candidate->x || reference->y != candidate->y ||
			reference->pic != candidate->pic || reference->abi != candidate->abi ||
			reference->cw_before != candidate->cw_before ||
			reference->cw_after != candidate->cw_after ||
			reference->sw_before != candidate->sw_before ||
			reference->sw_after != candidate->sw_after;
}

void Bench486ScreenNetCases (void)
{
	static const unsigned short rounding_bits[BSN_ROUNDING_COUNT] = {
		0x0000, 0x0400, 0x0800, 0x0c00
	};
	unsigned case_index, rounding_index;
	unsigned before = bench486_memory_failures;
	unsigned short control_word = Bench486ScreenNetGetControlWord ();
	bench486_screen_net_result_t reference, candidate;

	Bench486ScreenNetSaveState ();
	for (rounding_index = 0; rounding_index < BSN_ROUNDING_COUNT; rounding_index++)
		for (case_index = 0; case_index < BSN_CASE_COUNT; case_index++)
		{
			const bench486_screen_net_case_t *test_case =
					&bench486_screen_net_cases[case_index];
			unsigned short test_control =
					(unsigned short)(0x037fU | rounding_bits[rounding_index]);
			if (Bench486ScreenNetRun (test_case, "C",
					SCR_DrawNet_Screen_C, test_control, &reference))
				bench486_memory_failures++;
			if (Bench486ScreenNetRun (test_case, "assembly",
					SCR_DrawNet_asm486, test_control, &candidate))
				bench486_memory_failures++;
			if (Bench486ScreenNetDifferent (&reference, &candidate))
			{
				Bench486Printf ("screen net C/assembly mismatch case %s rounding %s "
						"calls %u/%u x %d/%d y %d/%d pic %08x/%08x "
						"ABI %u/%u CW %04x/%04x SW %04x/%04x\n",
						test_case->name,
						bench486_screen_net_rounding[rounding_index].name,
						reference.calls, candidate.calls,
						reference.x, candidate.x, reference.y, candidate.y,
						reference.pic, candidate.pic, reference.abi, candidate.abi,
						reference.cw_after, candidate.cw_after,
						reference.sw_after, candidate.sw_after);
				bench486_memory_failures++;
			}
		}
	Bench486ScreenNetSetControlWord (control_word);
	Bench486ScreenNetRestoreState ();
	if (bench486_memory_failures == before)
		Bench486Printf ("SCR_DrawNet %u exact C/assembly cases x %u x87 rounding modes PASS\n",
				BSN_CASE_COUNT, BSN_ROUNDING_COUNT);
}

#endif

#endif /* BENCH486_SCREEN_NET_H */
