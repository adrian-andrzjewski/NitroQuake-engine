/* Exact C/assembly state parity for screen.c:SCR_CalcRefdef. */
/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
#ifndef BENCH486_SCREEN_REFDEF_H
#define BENCH486_SCREEN_REFDEF_H

#if defined(BENCH486) && defined(ASM486_SCREEN_REFDEF)

#include "client/asm_screenrefdef.h"

#define BSR_CASE_COUNT 12
#define BSR_MAX_EVENTS 4

extern unsigned Bench486Call_asm486 (void (*function)(void), unsigned words,
		const unsigned *arguments, float *float_return);
extern viddef_t vid;
extern refdef_t r_refdef;
extern vrect_t scr_vrect;
extern cvar_t scr_viewsize, scr_fov;
extern float scr_con_current;
extern int scr_fullupdate, sb_lines;
extern client_state_t cl;

enum
{
	BSR_EVENT_SBAR_CHANGED = 1,
	BSR_EVENT_CVAR_SET = 2,
	BSR_EVENT_VIEW_CHANGED = 3
};

typedef struct
{
	unsigned event_count;
	unsigned overflow;
	unsigned events[BSR_MAX_EVENTS];
	unsigned cvar_count;
	char cvar_names[2][12];
	char cvar_values[2][8];
	vrect_t changed_rect;
	int changed_lineadj;
	unsigned changed_aspect_bits;
} bench486_screen_refdef_trace_t;

typedef struct
{
	int fullupdate;
	int recalc_refdef;
	int status_lines;
	unsigned console_current_bits;
	unsigned viewsize_bits;
	unsigned fov_bits;
	unsigned refdef_fov_x_bits;
	unsigned refdef_fov_y_bits;
	int screen_rect[5];
	bench486_screen_refdef_trace_t trace;
	unsigned abi;
	unsigned short cw_before;
	unsigned short cw_after;
	unsigned short x87_top_before;
	unsigned short x87_top_after;
} bench486_screen_refdef_result_t;

typedef struct
{
	const char *name;
	unsigned width;
	unsigned height;
	float aspect;
	float viewsize;
	float fov;
	float console_current;
	int intermission;
} bench486_screen_refdef_case_t;

static bench486_screen_refdef_trace_t bench486_screen_refdef_trace;
static bench486_screen_refdef_result_t bench486_screen_refdef_c;
static bench486_screen_refdef_result_t bench486_screen_refdef_asm;
int bench486_screen_refdef_fixture_active;
static viddef_t bench486_screen_refdef_saved_vid;
static refdef_t bench486_screen_refdef_saved_refdef;
static vrect_t bench486_screen_refdef_saved_rect;
static cvar_t bench486_screen_refdef_saved_viewsize;
static cvar_t bench486_screen_refdef_saved_fov;
static float bench486_screen_refdef_saved_console_current;
static int bench486_screen_refdef_saved_fullupdate;
static int bench486_screen_refdef_saved_status_lines;
static int bench486_screen_refdef_saved_intermission;

static unsigned Bench486ScreenRefdefFloatBits (float value)
{
	union { float f; unsigned u; } bits;
	bits.f = value;
	return bits.u;
}

static unsigned short Bench486ScreenRefdefGetControlWord (void)
{
	unsigned short word;
	__asm__ __volatile__ ("fnstcw %0" : "=m" (word));
	return word;
}

static unsigned short Bench486ScreenRefdefGetStatusWord (void)
{
	unsigned short word;
	__asm__ __volatile__ ("fnstsw %0" : "=m" (word));
	return word;
}

static void Bench486ScreenRefdefSetControlWord (unsigned short word)
{
	__asm__ __volatile__ ("fldcw %0" : : "m" (word));
}

static void Bench486ScreenRefdefEvent (unsigned event)
{
	if (bench486_screen_refdef_trace.event_count < BSR_MAX_EVENTS)
		bench486_screen_refdef_trace.events[
				bench486_screen_refdef_trace.event_count] = event;
	else
		bench486_screen_refdef_trace.overflow = 1;
	bench486_screen_refdef_trace.event_count++;
}

void Bench486ScreenRefdefSbarChanged (void)
{
	Bench486ScreenRefdefEvent (BSR_EVENT_SBAR_CHANGED);
}

void Bench486ScreenRefdefCvarSet (const char *name, const char *value)
{
	unsigned index = bench486_screen_refdef_trace.cvar_count++;
	unsigned i;
	if (index < 2)
	{
		for (i = 0; i < sizeof(bench486_screen_refdef_trace.cvar_names[index])-1 && name[i]; i++)
			bench486_screen_refdef_trace.cvar_names[index][i] = name[i];
		bench486_screen_refdef_trace.cvar_names[index][i] = 0;
		for (i = 0; i < sizeof(bench486_screen_refdef_trace.cvar_values[index])-1 && value[i]; i++)
			bench486_screen_refdef_trace.cvar_values[index][i] = value[i];
		bench486_screen_refdef_trace.cvar_values[index][i] = 0;
	}
	Bench486ScreenRefdefEvent (BSR_EVENT_CVAR_SET);

	if (name[0] == 'v' && name[1] == 'i' && name[2] == 'e')
	{
		if (value[0] == '3')
			scr_viewsize.value = 30.0f;
		else if (value[0] == '1')
			scr_viewsize.value = 120.0f;
		else
			bench486_memory_failures++;
	}
	else if (name[0] == 'f')
	{
		if (value[1] == '0')
			scr_fov.value = 10.0f;
		else if (value[1] == '7')
			scr_fov.value = 170.0f;
		else
			bench486_memory_failures++;
	}
	else
		bench486_memory_failures++;
}

void Bench486ScreenRefdefViewChanged (vrect_t *rect, int lineadj, float aspect)
{
	Bench486ScreenRefdefEvent (BSR_EVENT_VIEW_CHANGED);
	bench486_screen_refdef_trace.changed_rect = *rect;
	/* SCR_CalcRefdef sets the four viewport coordinates but leaves this local
	   linked-list pointer indeterminate. R_SetVrect and R_ViewChanged only use
	   those coordinates, so normalize the non-semantic field for deterministic
	   C/assembly comparison. */
	bench486_screen_refdef_trace.changed_rect.pnext = NULL;
	bench486_screen_refdef_trace.changed_lineadj = lineadj;
	bench486_screen_refdef_trace.changed_aspect_bits =
			Bench486ScreenRefdefFloatBits (aspect);
}

static void Bench486ScreenRefdefSetInputs (
		const bench486_screen_refdef_case_t *test_case)
{
	vid = bench486_screen_refdef_saved_vid;
	r_refdef = bench486_screen_refdef_saved_refdef;
	scr_vrect = bench486_screen_refdef_saved_rect;
	scr_viewsize = bench486_screen_refdef_saved_viewsize;
	scr_fov = bench486_screen_refdef_saved_fov;
	scr_viewsize.value = test_case->viewsize;
	scr_fov.value = test_case->fov;
	vid.width = test_case->width;
	vid.height = test_case->height;
	vid.aspect = test_case->aspect;
	vid.recalc_refdef = 1;
	r_refdef.vrect.x = 0;
	r_refdef.vrect.y = 0;
	r_refdef.vrect.width = test_case->width;
	r_refdef.vrect.height = test_case->height;
	r_refdef.vrect.pnext = 0;
	cl.intermission = test_case->intermission;
	scr_con_current = test_case->console_current;
	scr_fullupdate = 91;
	sb_lines = 37;
	Q_memset (&bench486_screen_refdef_trace, 0,
			sizeof(bench486_screen_refdef_trace));
}

static void Bench486ScreenRefdefCapture (
		bench486_screen_refdef_result_t *result, unsigned abi,
		unsigned short cw_before, unsigned short status_before)
{
	Q_memset (result, 0, sizeof(*result));
	result->fullupdate = scr_fullupdate;
	result->recalc_refdef = vid.recalc_refdef;
	result->status_lines = sb_lines;
	result->console_current_bits = Bench486ScreenRefdefFloatBits (scr_con_current);
	result->viewsize_bits = Bench486ScreenRefdefFloatBits (scr_viewsize.value);
	result->fov_bits = Bench486ScreenRefdefFloatBits (scr_fov.value);
	result->refdef_fov_x_bits = Bench486ScreenRefdefFloatBits (r_refdef.fov_x);
	result->refdef_fov_y_bits = Bench486ScreenRefdefFloatBits (r_refdef.fov_y);
	result->screen_rect[0] = scr_vrect.x;
	result->screen_rect[1] = scr_vrect.y;
	result->screen_rect[2] = scr_vrect.width;
	result->screen_rect[3] = scr_vrect.height;
	result->screen_rect[4] = (int)(unsigned long)scr_vrect.pnext;
	result->trace = bench486_screen_refdef_trace;
	result->abi = abi;
	result->cw_before = cw_before;
	result->cw_after = Bench486ScreenRefdefGetControlWord ();
	result->x87_top_before = (status_before >> 11) & 7;
	result->x87_top_after = (Bench486ScreenRefdefGetStatusWord () >> 11) & 7;
}

static void Bench486ScreenRefdefRun (
		void (*function)(void), const bench486_screen_refdef_case_t *test_case,
		bench486_screen_refdef_result_t *result, unsigned short control_word)
{
	unsigned short cw_before, status_before;
	unsigned abi;
	Bench486ScreenRefdefSetInputs (test_case);
	Bench486ScreenRefdefSetControlWord (control_word);
	cw_before = Bench486ScreenRefdefGetControlWord ();
	status_before = Bench486ScreenRefdefGetStatusWord ();
	bench486_screen_refdef_fixture_active = 1;
	abi = Bench486Call_asm486 (function, 0, NULL, NULL);
	bench486_screen_refdef_fixture_active = 0;
	Bench486ScreenRefdefCapture (result, abi, cw_before, status_before);
}

static int Bench486ScreenRefdefResultsEqual (
		const bench486_screen_refdef_result_t *a,
		const bench486_screen_refdef_result_t *b)
{
	return a->fullupdate == b->fullupdate &&
		a->recalc_refdef == b->recalc_refdef &&
		a->status_lines == b->status_lines &&
		a->console_current_bits == b->console_current_bits &&
		a->viewsize_bits == b->viewsize_bits &&
		a->fov_bits == b->fov_bits &&
		a->refdef_fov_x_bits == b->refdef_fov_x_bits &&
		a->refdef_fov_y_bits == b->refdef_fov_y_bits &&
		Q_memcmp ((void *)a->screen_rect, (void *)b->screen_rect,
				sizeof(a->screen_rect)) == 0 &&
		Q_memcmp ((void *)&a->trace, (void *)&b->trace, sizeof(a->trace)) == 0 &&
		a->cw_before == a->cw_after && b->cw_before == b->cw_after &&
		a->cw_before == b->cw_before &&
		a->x87_top_before == a->x87_top_after &&
		b->x87_top_before == b->x87_top_after &&
		a->x87_top_before == b->x87_top_before &&
		!(a->abi & 0x20U) && !(b->abi & 0x20U);
}

static void Bench486ScreenRefdefReportDifference (
		const bench486_screen_refdef_result_t *a,
		const bench486_screen_refdef_result_t *b)
{
	unsigned i;
	if (a->fullupdate != b->fullupdate || a->recalc_refdef != b->recalc_refdef ||
			a->status_lines != b->status_lines)
		Bench486Printf (" screen full/recalc/status C %d/%d/%d asm %d/%d/%d\n",
				a->fullupdate, a->recalc_refdef, a->status_lines,
				b->fullupdate, b->recalc_refdef, b->status_lines);
	if (a->console_current_bits != b->console_current_bits ||
			a->viewsize_bits != b->viewsize_bits || a->fov_bits != b->fov_bits ||
			a->refdef_fov_x_bits != b->refdef_fov_x_bits ||
			a->refdef_fov_y_bits != b->refdef_fov_y_bits)
		Bench486Printf (" screen floats con/view/fov/fovx/fovy C %08x/%08x/%08x/%08x/%08x asm %08x/%08x/%08x/%08x/%08x\n",
				a->console_current_bits, a->viewsize_bits, a->fov_bits,
				a->refdef_fov_x_bits, a->refdef_fov_y_bits,
				b->console_current_bits, b->viewsize_bits, b->fov_bits,
				b->refdef_fov_x_bits, b->refdef_fov_y_bits);
	for (i = 0; i < 5; i++)
		if (a->screen_rect[i] != b->screen_rect[i])
			Bench486Printf (" screen rect[%u] C %d asm %d\n", i,
					a->screen_rect[i], b->screen_rect[i]);
	if (Q_memcmp ((void *)&a->trace, (void *)&b->trace, sizeof(a->trace)))
	{
		for (i = 0; i < sizeof(a->trace); i++)
			if (((const byte *)&a->trace)[i] != ((const byte *)&b->trace)[i])
			{
				Bench486Printf (" screen trace first byte %u C %u asm %u; events %u/%u cvars %u/%u\n",
						i, ((const byte *)&a->trace)[i], ((const byte *)&b->trace)[i],
						a->trace.event_count, b->trace.event_count,
						a->trace.cvar_count, b->trace.cvar_count);
				break;
			}
		Bench486Printf (" screen trace event C %u/%u/%u/%u asm %u/%u/%u/%u; line/aspect %d/%08x asm %d/%08x\n",
				a->trace.events[0], a->trace.events[1], a->trace.events[2], a->trace.events[3],
				b->trace.events[0], b->trace.events[1], b->trace.events[2], b->trace.events[3],
				a->trace.changed_lineadj, a->trace.changed_aspect_bits,
				b->trace.changed_lineadj, b->trace.changed_aspect_bits);
		Bench486Printf (" screen trace C cvar %s=%s,%s=%s asm %s=%s,%s=%s\n",
				a->trace.cvar_names[0], a->trace.cvar_values[0],
				a->trace.cvar_names[1], a->trace.cvar_values[1],
				b->trace.cvar_names[0], b->trace.cvar_values[0],
				b->trace.cvar_names[1], b->trace.cvar_values[1]);
	}
	if (a->abi != b->abi || a->cw_before != a->cw_after ||
			b->cw_before != b->cw_after || a->cw_before != b->cw_before ||
		a->x87_top_before != a->x87_top_after ||
			b->x87_top_before != b->x87_top_after ||
			a->x87_top_before != b->x87_top_before)
		Bench486Printf (" screen ABI C/asm %x/%x CW C %04x>%04x asm %04x>%04x TOP C %u>%u asm %u>%u\n",
				a->abi, b->abi, a->cw_before, a->cw_after,
				b->cw_before, b->cw_after, a->x87_top_before, a->x87_top_after,
				b->x87_top_before, b->x87_top_after);
}

void Bench486ScreenRefdefCases (void)
{
	static const bench486_screen_refdef_case_t cases[BSR_CASE_COUNT] =
	{
		{"viewsize-and-fov-low-clamp",320,200,1.6f,29.0f,9.0f,250.0f,0},
		{"viewsize-and-fov-minimum",320,240,1.3333334f,30.0f,10.0f,180.0f,0},
		{"middle-view",320,200,1.6f,50.0f,90.0f,40.0f,0},
		{"statusbar-boundary",640,480,1.3333334f,109.0f,170.0f,100.0f,0},
		{"inventory-boundary-and-fov-high-clamp",320,240,1.3333334f,110.0f,171.0f,241.0f,0},
		{"below-full-view",640,400,1.6f,119.5f,9.5f,401.0f,0},
		{"full-view",640,480,1.3333334f,120.0f,90.0f,500.0f,0},
		{"viewsize-high-clamp",320,200,1.6f,121.0f,90.0f,201.0f,0},
		{"intermission-one-full-view",320,240,1.3333334f,50.0f,170.0f,250.0f,1},
		{"intermission-two-full-view",640,480,1.3333334f,30.0f,10.0f,30.0f,2},
		{"intermission-three-full-view",320,200,1.6f,109.0f,90.0f,200.0f,3},
		{"high-resolution-console-clamp",800,600,1.3333334f,120.0f,170.0f,650.0f,0}
	};
	static const unsigned short round_bits[4] = {0x0000,0x0400,0x0800,0x0c00};
	unsigned short original_cw;
	unsigned failures = 0, comparisons = 0;
	unsigned i, r;

	bench486_screen_refdef_saved_vid = vid;
	bench486_screen_refdef_saved_refdef = r_refdef;
	bench486_screen_refdef_saved_rect = scr_vrect;
	bench486_screen_refdef_saved_viewsize = scr_viewsize;
	bench486_screen_refdef_saved_fov = scr_fov;
	bench486_screen_refdef_saved_console_current = scr_con_current;
	bench486_screen_refdef_saved_fullupdate = scr_fullupdate;
	bench486_screen_refdef_saved_status_lines = sb_lines;
	bench486_screen_refdef_saved_intermission = cl.intermission;
	original_cw = Bench486ScreenRefdefGetControlWord ();

	for (r = 0; r < 4; r++)
		for (i = 0; i < BSR_CASE_COUNT; i++)
		{
			unsigned short test_cw = (original_cw & ~0x0f00U) | 0x0300U | round_bits[r];
			Bench486ScreenRefdefRun ((void (*)(void))SCR_CalcRefdef_Screen_C,
					&cases[i], &bench486_screen_refdef_c, test_cw);
			Bench486ScreenRefdefRun ((void (*)(void))SCR_CalcRefdef_asm486,
					&cases[i], &bench486_screen_refdef_asm, test_cw);
			comparisons++;
			if (!Bench486ScreenRefdefResultsEqual (&bench486_screen_refdef_c,
					&bench486_screen_refdef_asm))
			{
				failures++;
				if (failures <= 8)
				{
					Bench486Printf ("screen refdef mismatch %s rounding %u c=%u asm=%u\n",
							cases[i].name, r, bench486_screen_refdef_c.refdef_fov_y_bits,
							bench486_screen_refdef_asm.refdef_fov_y_bits);
					Bench486ScreenRefdefReportDifference (&bench486_screen_refdef_c,
							&bench486_screen_refdef_asm);
				}
			}
		}

	vid = bench486_screen_refdef_saved_vid;
	r_refdef = bench486_screen_refdef_saved_refdef;
	scr_vrect = bench486_screen_refdef_saved_rect;
	scr_viewsize = bench486_screen_refdef_saved_viewsize;
	scr_fov = bench486_screen_refdef_saved_fov;
	scr_con_current = bench486_screen_refdef_saved_console_current;
	scr_fullupdate = bench486_screen_refdef_saved_fullupdate;
	sb_lines = bench486_screen_refdef_saved_status_lines;
	cl.intermission = bench486_screen_refdef_saved_intermission;
	Bench486ScreenRefdefSetControlWord (original_cw);
	bench486_sink += comparisons + failures;
	Bench486Printf ("screen refdef %u/%u exact C/assembly cases %s\n",
			comparisons, BSR_CASE_COUNT * 4U,
			failures ? "FAIL" : "PASS");
	bench486_memory_failures += failures;
}

#endif

#endif
