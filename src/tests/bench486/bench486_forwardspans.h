/* Direct C-oracle parity coverage for the legacy forward span generator. */
/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
#ifndef BENCH486_FORWARDSPANS_H
#define BENCH486_FORWARDSPANS_H

#ifdef BENCH486

#include <stddef.h>

#define BFS_GUARD_WORDS 8
#define BFS_SURFACE_COUNT 8
#define BFS_EDGE_CAPACITY 8
#define BFS_SPAN_CAPACITY 64
#define BFS_VIEW_RIGHT 320
#define BFS_FIXED_U(pixel, fraction) (((pixel) << 20) + (fraction))

extern surf_t *surfaces;
extern espan_t *span_p, *max_span_p;
extern int edge_head_u_shift20, edge_tail_u_shift20, current_iv;
extern float fv;
extern int r_bmodelactive;
extern void R_GenerateSpans_C (void);
extern void R_GenerateSpans_asm486 (void);
extern unsigned Bench486Call_asm486 (void (*function)(void), unsigned words,
		const unsigned *arguments, float *float_return);

typedef struct
{
	unsigned first[BFS_GUARD_WORDS];
	surf_t data[BFS_SURFACE_COUNT];
	unsigned last[BFS_GUARD_WORDS];
} bench486_forwardspans_surface_buffer_t;

typedef struct
{
	unsigned first[BFS_GUARD_WORDS];
	edge_t data[BFS_EDGE_CAPACITY];
	unsigned last[BFS_GUARD_WORDS];
} bench486_forwardspans_edge_buffer_t;

typedef struct
{
	unsigned first[BFS_GUARD_WORDS];
	espan_t data[BFS_SPAN_CAPACITY];
	unsigned last[BFS_GUARD_WORDS];
} bench486_forwardspans_span_buffer_t;

typedef struct
{
	int u;
	unsigned short leaving, entering;
} bench486_forwardspans_input_edge_t;

typedef struct
{
	const char *name;
	unsigned edge_count;
	bench486_forwardspans_input_edge_t edges[4];
	unsigned mode;
	unsigned expected_spans;
} bench486_forwardspans_case_t;

typedef struct
{
	bench486_forwardspans_surface_buffer_t surfaces;
	bench486_forwardspans_edge_buffer_t edges;
	bench486_forwardspans_span_buffer_t spans;
	edge_t edge_head, edge_tail;
	unsigned span_count;
	int bmodel_active, head_u, tail_u, scanline;
	float fv_value;
	unsigned short x87_cw, x87_sw, x87_top_before;
	unsigned abi;
	int state_valid, state_reason;
} bench486_forwardspans_result_t;

enum
{
	BFS_MODE_DEFAULT = 0,
	BFS_MODE_EQUAL_KEYS,
	BFS_MODE_NESTED_SURFACES,
	BFS_MODE_BMODEL_BOTTOM_PASS,
	BFS_MODE_BMODEL_SLOPE_WINS,
	BFS_MODE_BMODEL_SLOPE_KEEPS,
	BFS_MODE_BMODEL_OUTSIDE_WINDOW,
	BFS_MODE_BMODEL_LEGACY_CONSTANT_MISMATCH,
	BFS_MODE_BMODEL_BOTTOM_PRECISION,
	BFS_MODE_BMODEL_TOP_PRECISION,
	BFS_MODE_BMODEL_FU_BOUNDARY
};

#define BFS_EDGE(px, frac, left, right) \
	{ BFS_FIXED_U((px), (frac)), (left), (right) }

static const bench486_forwardspans_case_t bench486_forwardspans_cases[] =
{
	{ "empty-background", 0, { { 0, 0, 0 } }, BFS_MODE_DEFAULT, 1 },
	{ "opaque-surface", 2, {
		{ BFS_FIXED_U(32, 0xfffff), 0, 2 },
		{ BFS_FIXED_U(288, 0x00000), 2, 0 }
	}, BFS_MODE_DEFAULT, 3 },
	{ "nested-surfaces", 4, {
		{ BFS_FIXED_U(32, 0x00001), 0, 2 },
		{ BFS_FIXED_U(80, 0x7ffff), 0, 3 },
		{ BFS_FIXED_U(160, 0x80001), 3, 0 },
		{ BFS_FIXED_U(256, 0xfffff), 2, 0 }
	}, BFS_MODE_NESTED_SURFACES, 5 },
	{ "same-edge-surface-transition", 3, {
		{ BFS_FIXED_U(32, 0x00001), 0, 2 },
		{ BFS_FIXED_U(64, 0xfffff), 2, 3 },
		{ BFS_FIXED_U(288, 0x00001), 3, 0 }
	}, BFS_MODE_DEFAULT, 4 },
	{ "close-before-open-inverted", 2, {
		{ BFS_FIXED_U(32, 0x00000), 2, 0 },
		{ BFS_FIXED_U(64, 0x00000), 0, 2 }
	}, BFS_MODE_DEFAULT, 1 },
	{ "zero-width-surface", 2, {
		{ BFS_FIXED_U(64, 0x00000), 0, 2 },
		{ BFS_FIXED_U(64, 0x00000), 2, 0 }
	}, BFS_MODE_DEFAULT, 2 },
	{ "equal-key-non-bmodel", 4, {
		{ BFS_FIXED_U(32, 0x00000), 0, 2 },
		{ BFS_FIXED_U(64, 0x00000), 0, 3 },
		{ BFS_FIXED_U(160, 0x00000), 3, 0 },
		{ BFS_FIXED_U(256, 0x00000), 2, 0 }
	}, BFS_MODE_EQUAL_KEYS, 3 },
	{ "bmodel-bottom-threshold", 4, {
		{ BFS_FIXED_U(32, 0x00000), 0, 2 },
		{ BFS_FIXED_U(64, 0xfffff), 0, 3 },
		{ BFS_FIXED_U(160, 0x00000), 3, 0 },
		{ BFS_FIXED_U(256, 0x00000), 2, 0 }
	}, BFS_MODE_BMODEL_BOTTOM_PASS, 5 },
	{ "bmodel-slope-tiebreak-wins", 4, {
		{ BFS_FIXED_U(32, 0x00000), 0, 2 },
		{ BFS_FIXED_U(64, 0xfffff), 0, 3 },
		{ BFS_FIXED_U(160, 0x00000), 3, 0 },
		{ BFS_FIXED_U(256, 0x00000), 2, 0 }
	}, BFS_MODE_BMODEL_SLOPE_WINS, 5 },
	{ "bmodel-slope-tiebreak-keeps", 4, {
		{ BFS_FIXED_U(32, 0x00000), 0, 2 },
		{ BFS_FIXED_U(64, 0xfffff), 0, 3 },
		{ BFS_FIXED_U(160, 0x00000), 3, 0 },
		{ BFS_FIXED_U(256, 0x00000), 2, 0 }
	}, BFS_MODE_BMODEL_SLOPE_KEEPS, 3 },
	{ "bmodel-outside-depth-window", 4, {
		{ BFS_FIXED_U(32, 0x00000), 0, 2 },
		{ BFS_FIXED_U(64, 0xfffff), 0, 3 },
		{ BFS_FIXED_U(160, 0x00000), 3, 0 },
		{ BFS_FIXED_U(256, 0x00000), 2, 0 }
	}, BFS_MODE_BMODEL_OUTSIDE_WINDOW, 3 },
	{ "bmodel-legacy-constant-boundary", 4, {
		{ BFS_FIXED_U(32, 0x00000), 0, 2 },
		{ BFS_FIXED_U(64, 0xfffff), 0, 3 },
		{ BFS_FIXED_U(160, 0x00000), 3, 0 },
		{ BFS_FIXED_U(256, 0x00000), 2, 0 }
	}, BFS_MODE_BMODEL_LEGACY_CONSTANT_MISMATCH, 3 },
	{ "bmodel-bottom-double-boundary", 4, {
		{ BFS_FIXED_U(32, 0x00000), 0, 2 },
		{ BFS_FIXED_U(64, 0xfffff), 0, 3 },
		{ BFS_FIXED_U(160, 0x00000), 3, 0 },
		{ BFS_FIXED_U(256, 0x00000), 2, 0 }
	}, BFS_MODE_BMODEL_BOTTOM_PRECISION, 3 },
	{ "bmodel-top-double-boundary", 4, {
		{ BFS_FIXED_U(32, 0x00000), 0, 2 },
		{ BFS_FIXED_U(64, 0xfffff), 0, 3 },
		{ BFS_FIXED_U(160, 0x00000), 3, 0 },
		{ BFS_FIXED_U(256, 0x00000), 2, 0 }
	}, BFS_MODE_BMODEL_TOP_PRECISION, 5 },
	{ "bmodel-fu-fixed-point-boundary", 4, {
		{ BFS_FIXED_U(32, 0x00000), 0, 2 },
		{ BFS_FIXED_U(256, 0x00010), 0, 3 },
		{ BFS_FIXED_U(288, 0x00000), 3, 0 },
		{ BFS_FIXED_U(300, 0x00000), 2, 0 }
	}, BFS_MODE_BMODEL_FU_BOUNDARY, 3 },
	{ "fractional-u-pixel-boundary", 2, {
		{ BFS_FIXED_U(0, 0xfffff), 0, 2 },
		{ BFS_FIXED_U(1, 0x00000), 2, 0 }
	}, BFS_MODE_DEFAULT, 2 }
};

static bench486_forwardspans_surface_buffer_t bench486_forwardspans_surface_buffer;
static bench486_forwardspans_edge_buffer_t bench486_forwardspans_edge_buffer;
static bench486_forwardspans_span_buffer_t bench486_forwardspans_span_buffer;
static bench486_forwardspans_result_t bench486_forwardspans_c_result;
static bench486_forwardspans_result_t bench486_forwardspans_asm_result;
static unsigned short bench486_forwardspans_x87_env[14];
static edge_t bench486_forwardspans_expected_head, bench486_forwardspans_expected_tail;
static byte bench486_forwardspans_expected_edges[
		sizeof(bench486_forwardspans_edge_buffer_t)];

static float Bench486ForwardSpansExpectedFv (
		const bench486_forwardspans_case_t *test)
{
	if (test->mode == BFS_MODE_BMODEL_TOP_PRECISION)
		return 1321.0f / 67108864.0f;
	if (test->mode == BFS_MODE_BMODEL_FU_BOUNDARY)
		return 0.5f;
	return 0.0f;
}

static void Bench486ForwardSpansSetGuards (void)
{
	int i;
	for (i = 0; i < BFS_GUARD_WORDS; i++)
	{
		bench486_forwardspans_surface_buffer.first[i] = 0x486671a5U;
		bench486_forwardspans_surface_buffer.last[i] = 0xa51f09ceU;
		bench486_forwardspans_edge_buffer.first[i] = 0x486671a5U;
		bench486_forwardspans_edge_buffer.last[i] = 0xa51f09ceU;
		bench486_forwardspans_span_buffer.first[i] = 0x486671a5U;
		bench486_forwardspans_span_buffer.last[i] = 0xa51f09ceU;
	}
}

static void Bench486ForwardSpansPrepare (
		const bench486_forwardspans_case_t *test)
{
	unsigned i;

	Q_memset (&bench486_forwardspans_surface_buffer, 0xa5,
			sizeof(bench486_forwardspans_surface_buffer));
	Q_memset (&bench486_forwardspans_edge_buffer, 0x5a,
			sizeof(bench486_forwardspans_edge_buffer));
	Q_memset (&bench486_forwardspans_span_buffer, 0xcc,
			sizeof(bench486_forwardspans_span_buffer));
	Q_memset (bench486_forwardspans_surface_buffer.data, 0,
			sizeof(bench486_forwardspans_surface_buffer.data));
	Q_memset (bench486_forwardspans_edge_buffer.data, 0,
			sizeof(bench486_forwardspans_edge_buffer.data));
	Q_memset (&edge_head, 0, sizeof(edge_head));
	Q_memset (&edge_tail, 0, sizeof(edge_tail));
	Bench486ForwardSpansSetGuards ();

	for (i = 1; i < BFS_SURFACE_COUNT; i++)
	{
		bench486_forwardspans_surface_buffer.data[i].key = 20 + (int)i * 10;
		bench486_forwardspans_surface_buffer.data[i].last_u = 0;
	}
	bench486_forwardspans_surface_buffer.data[1].key = 0x7fffffff;
	bench486_forwardspans_surface_buffer.data[1].next =
			&bench486_forwardspans_surface_buffer.data[1];
	bench486_forwardspans_surface_buffer.data[1].prev =
			&bench486_forwardspans_surface_buffer.data[1];
	if (test->mode == BFS_MODE_EQUAL_KEYS ||
			test->mode >= BFS_MODE_BMODEL_BOTTOM_PASS)
	{
		bench486_forwardspans_surface_buffer.data[2].key = 7;
		bench486_forwardspans_surface_buffer.data[3].key = 7;
	}
	if (test->mode >= BFS_MODE_BMODEL_BOTTOM_PASS)
	{
		bench486_forwardspans_surface_buffer.data[2].insubmodel = true;
		bench486_forwardspans_surface_buffer.data[3].insubmodel = true;
	}
	switch (test->mode)
	{
	case BFS_MODE_NESTED_SURFACES:
		bench486_forwardspans_surface_buffer.data[2].key = 50;
		bench486_forwardspans_surface_buffer.data[3].key = 40;
		break;
	case BFS_MODE_BMODEL_BOTTOM_PASS:
		bench486_forwardspans_surface_buffer.data[2].d_ziorigin = 1.0f;
		bench486_forwardspans_surface_buffer.data[3].d_ziorigin = 1.02f;
		break;
	case BFS_MODE_BMODEL_SLOPE_WINS:
		bench486_forwardspans_surface_buffer.data[2].d_ziorigin = 1.0f;
		bench486_forwardspans_surface_buffer.data[3].d_ziorigin = -15.0f;
		bench486_forwardspans_surface_buffer.data[3].d_zistepu = 0.25f;
		break;
	case BFS_MODE_BMODEL_SLOPE_KEEPS:
		bench486_forwardspans_surface_buffer.data[2].d_ziorigin = 1.0f;
		bench486_forwardspans_surface_buffer.data[2].d_zistepu = 0.25f;
		bench486_forwardspans_surface_buffer.data[3].d_ziorigin = 17.0f;
		break;
	case BFS_MODE_BMODEL_OUTSIDE_WINDOW:
		bench486_forwardspans_surface_buffer.data[2].d_ziorigin = 1.0f;
		bench486_forwardspans_surface_buffer.data[3].d_ziorigin = 0.98f;
		break;
	case BFS_MODE_BMODEL_LEGACY_CONSTANT_MISMATCH:
		bench486_forwardspans_surface_buffer.data[2].d_ziorigin = -7.0f;
		bench486_forwardspans_surface_buffer.data[2].d_zistepu = 0.125f;
		bench486_forwardspans_surface_buffer.data[3].d_ziorigin = 1.002f;
		break;
	case BFS_MODE_BMODEL_BOTTOM_PRECISION:
		bench486_forwardspans_surface_buffer.data[2].d_ziorigin = 0.99f;
		bench486_forwardspans_surface_buffer.data[3].d_ziorigin = 1.64f;
		bench486_forwardspans_surface_buffer.data[3].d_zistepu = -0.01f;
		break;
	case BFS_MODE_BMODEL_TOP_PRECISION:
		bench486_forwardspans_surface_buffer.data[2].d_ziorigin = 1.01f;
		bench486_forwardspans_surface_buffer.data[2].d_zistepv =
				32513.0f / 67108864.0f;
		bench486_forwardspans_surface_buffer.data[3].d_ziorigin = 1.0f;
		break;
	case BFS_MODE_BMODEL_FU_BOUNDARY:
		bench486_forwardspans_surface_buffer.data[2].d_ziorigin =
				307.19921875f;
		bench486_forwardspans_surface_buffer.data[2].d_zistepu = 99.8f;
		bench486_forwardspans_surface_buffer.data[2].d_zistepv = 0.00002f;
		bench486_forwardspans_surface_buffer.data[3].d_zistepu = 100.0f;
		break;
	default:
		break;
	}
	for (i = 0; i < test->edge_count; i++)
	{
		edge_t *edge;
		edge = &bench486_forwardspans_edge_buffer.data[i];
		edge->u = test->edges[i].u;
		edge->surfs[0] = test->edges[i].leaving;
		edge->surfs[1] = test->edges[i].entering;
		edge->next = i + 1 < test->edge_count ?
				&bench486_forwardspans_edge_buffer.data[i+1] : &edge_tail;
	}
	edge_head.next = test->edge_count ?
			&bench486_forwardspans_edge_buffer.data[0] : &edge_tail;
	edge_tail.u = BFS_FIXED_U (BFS_VIEW_RIGHT, 0);
	edge_tail.next = NULL;
	edge_head_u_shift20 = 0;
	edge_tail_u_shift20 = BFS_VIEW_RIGHT;
	current_iv = 37;
	fv = Bench486ForwardSpansExpectedFv (test);
	r_bmodelactive = 23;
	surfaces = bench486_forwardspans_surface_buffer.data;
	span_p = bench486_forwardspans_span_buffer.data;
	max_span_p = bench486_forwardspans_span_buffer.data + BFS_SPAN_CAPACITY;
	Q_memcpy (&bench486_forwardspans_expected_head, &edge_head, sizeof(edge_head));
	Q_memcpy (&bench486_forwardspans_expected_tail, &edge_tail, sizeof(edge_tail));
	Q_memcpy (bench486_forwardspans_expected_edges,
			&bench486_forwardspans_edge_buffer,
			sizeof(bench486_forwardspans_edge_buffer));
}

static int Bench486ForwardSpansGuardsValid (void)
{
	int i;
	for (i = 0; i < BFS_GUARD_WORDS; i++)
	{
		if (bench486_forwardspans_surface_buffer.first[i] != 0x486671a5U ||
				bench486_forwardspans_surface_buffer.last[i] != 0xa51f09ceU ||
				bench486_forwardspans_edge_buffer.first[i] != 0x486671a5U ||
				bench486_forwardspans_edge_buffer.last[i] != 0xa51f09ceU ||
				bench486_forwardspans_span_buffer.first[i] != 0x486671a5U ||
				bench486_forwardspans_span_buffer.last[i] != 0xa51f09ceU)
			return 0;
	}
	return 1;
}

static int Bench486ForwardSpansSurfacePointerValid (surf_t *surface)
{
	unsigned address, first, end;
	address = (unsigned)surface;
	first = (unsigned)&bench486_forwardspans_surface_buffer.data[1];
	end = (unsigned)&bench486_forwardspans_surface_buffer.data[BFS_SURFACE_COUNT];
	return address >= first && address < end &&
			((address - first) % sizeof(surf_t)) == 0;
}

static int Bench486ForwardSpansStateReason (
		const bench486_forwardspans_case_t *test, unsigned expected_spans,
		unsigned short test_cw, unsigned short top_before,
		bench486_forwardspans_result_t *result)
{
	surf_t *surface, *previous;
	espan_t *span;
	unsigned address, span_base, span_limit, used;
	unsigned visited, links, total_links, i;
	float expected_fv;

	used = (unsigned)(((unsigned)span_p -
			(unsigned)bench486_forwardspans_span_buffer.data) / sizeof(espan_t));
	result->span_count = used;
	if (used > BFS_SPAN_CAPACITY || used != expected_spans)
		return 1;
	if (!Bench486ForwardSpansGuardsValid ())
		return 2;
	if ((unsigned)span_p != (unsigned)(bench486_forwardspans_span_buffer.data + used))
		return 3;
	if (Q_memcmp (&edge_head, &bench486_forwardspans_expected_head,
			sizeof(edge_head)) ||
			Q_memcmp (&edge_tail, &bench486_forwardspans_expected_tail,
				sizeof(edge_tail)) ||
			Q_memcmp (&bench486_forwardspans_edge_buffer,
				bench486_forwardspans_expected_edges,
				sizeof(bench486_forwardspans_edge_buffer)))
		return 4;

	previous = &surfaces[1];
	surface = surfaces[1].next;
	visited = 0;
	while (surface != &surfaces[1])
	{
		if (!Bench486ForwardSpansSurfacePointerValid (surface) ||
				++visited >= BFS_SURFACE_COUNT)
			return 5;
		if (surface->prev != previous || previous->next != surface)
			return 5;
		previous = surface;
		surface = surface->next;
	}
	if (surfaces[1].prev != previous || previous->next != &surfaces[1])
		return 5;

	span_base = (unsigned)bench486_forwardspans_span_buffer.data;
	span_limit = span_base + used * sizeof(espan_t);
	total_links = 0;
	for (i = 1; i < BFS_SURFACE_COUNT; i++)
	{
		links = 0;
		span = surfaces[i].spans;
		while (span)
		{
			address = (unsigned)span;
			if (address < span_base || address >= span_limit ||
					((address - span_base) % sizeof(espan_t)) != 0 ||
					++links > used || span->count <= 0 ||
					span->v != current_iv || span->u < 0 ||
					span->u + span->count > BFS_VIEW_RIGHT)
				return 6;
			span = span->pnext;
		}
		total_links += links;
		if (surfaces[i].spanstate != 0)
			return 7;
	}
	if (total_links != used)
		return 10;
	expected_fv = Bench486ForwardSpansExpectedFv (test);
	if (surfaces != bench486_forwardspans_surface_buffer.data ||
			edge_head_u_shift20 != 0 || edge_tail_u_shift20 != BFS_VIEW_RIGHT ||
			r_bmodelactive != 0 || current_iv != 37 || fv != expected_fv)
		return 8;
	if (result->x87_cw != test_cw ||
			(result->x87_sw & 0x3800) != top_before || result->abi != 0)
		return 9;
	return 0;
}

static void Bench486ForwardSpansRunSide (void (*function)(void),
		const bench486_forwardspans_case_t *test, unsigned expected_spans,
		unsigned short test_cw, int assembly,
		bench486_forwardspans_result_t *result)
{
	unsigned short top_before;

	Bench486ForwardSpansPrepare (test);
	if (assembly)
		R_SurfacePatch ();
	__asm__ __volatile__ ("fnclex\n\tfldcw %0" : : "m" (test_cw));
	__asm__ __volatile__ ("fnstsw %0" : "=m" (top_before));
	result->abi = Bench486Call_asm486 (function, 0, NULL, NULL);
	__asm__ __volatile__ ("fnstcw %0\n\tfnstsw %1"
			: "=m" (result->x87_cw), "=m" (result->x87_sw));
	result->x87_top_before = top_before & 0x3800;
	Q_memcpy (&result->surfaces, &bench486_forwardspans_surface_buffer,
			sizeof(bench486_forwardspans_surface_buffer));
	Q_memcpy (&result->edges, &bench486_forwardspans_edge_buffer,
			sizeof(bench486_forwardspans_edge_buffer));
	Q_memcpy (&result->spans, &bench486_forwardspans_span_buffer,
			sizeof(bench486_forwardspans_span_buffer));
	Q_memcpy (&result->edge_head, &edge_head, sizeof(edge_head));
	Q_memcpy (&result->edge_tail, &edge_tail, sizeof(edge_tail));
	result->bmodel_active = r_bmodelactive;
	result->head_u = edge_head_u_shift20;
	result->tail_u = edge_tail_u_shift20;
	result->scanline = current_iv;
	result->fv_value = fv;
	result->state_reason = Bench486ForwardSpansStateReason (test,
			expected_spans, test_cw, result->x87_top_before, result);
	result->state_valid = result->state_reason == 0;
}

static void Bench486ForwardSpansCompare (
		const bench486_forwardspans_case_t *test, int rounding_mode,
		unsigned short base_cw)
{
	unsigned short test_cw;
	unsigned expected_spans;
	int equal;

	expected_spans = test->expected_spans;
	test_cw = (unsigned short)((base_cw & ~0x0c00U) |
			((rounding_mode & 3) << 10));
	Bench486ForwardSpansRunSide (R_GenerateSpans_C, test,
		expected_spans, test_cw, 0,
		&bench486_forwardspans_c_result);
	Bench486ForwardSpansRunSide (R_GenerateSpans_asm486, test,
		expected_spans, test_cw, 1,
		&bench486_forwardspans_asm_result);
	equal = bench486_forwardspans_c_result.state_valid &&
			bench486_forwardspans_asm_result.state_valid &&
			bench486_forwardspans_c_result.span_count ==
				bench486_forwardspans_asm_result.span_count &&
			bench486_forwardspans_c_result.bmodel_active ==
				bench486_forwardspans_asm_result.bmodel_active &&
			bench486_forwardspans_c_result.head_u ==
				bench486_forwardspans_asm_result.head_u &&
			bench486_forwardspans_c_result.tail_u ==
				bench486_forwardspans_asm_result.tail_u &&
			bench486_forwardspans_c_result.scanline ==
				bench486_forwardspans_asm_result.scanline &&
			!Q_memcmp (&bench486_forwardspans_c_result.fv_value,
				&bench486_forwardspans_asm_result.fv_value, sizeof(float)) &&
			bench486_forwardspans_c_result.x87_cw ==
				bench486_forwardspans_asm_result.x87_cw &&
			bench486_forwardspans_c_result.x87_top_before ==
				bench486_forwardspans_asm_result.x87_top_before &&
			!Q_memcmp (&bench486_forwardspans_c_result.surfaces,
				&bench486_forwardspans_asm_result.surfaces,
				sizeof(bench486_forwardspans_surface_buffer)) &&
			!Q_memcmp (&bench486_forwardspans_c_result.edges,
				&bench486_forwardspans_asm_result.edges,
				sizeof(bench486_forwardspans_edge_buffer)) &&
			!Q_memcmp (&bench486_forwardspans_c_result.spans,
				&bench486_forwardspans_asm_result.spans,
				sizeof(bench486_forwardspans_span_buffer)) &&
			!Q_memcmp (&bench486_forwardspans_c_result.edge_head,
				&bench486_forwardspans_asm_result.edge_head, sizeof(edge_t)) &&
			!Q_memcmp (&bench486_forwardspans_c_result.edge_tail,
				&bench486_forwardspans_asm_result.edge_tail, sizeof(edge_t));
	if (!equal)
	{
		Bench486Printf ("forward-spans %s rm%d FAIL c-reason %d asm-reason %d spans %u/%u abi %u/%u cw %04x/%04x sw %04x/%04x\n",
				test->name, rounding_mode,
				bench486_forwardspans_c_result.state_reason,
				bench486_forwardspans_asm_result.state_reason,
				bench486_forwardspans_c_result.span_count,
				bench486_forwardspans_asm_result.span_count,
				bench486_forwardspans_c_result.abi,
				bench486_forwardspans_asm_result.abi,
				bench486_forwardspans_c_result.x87_cw,
				bench486_forwardspans_asm_result.x87_cw,
				bench486_forwardspans_c_result.x87_sw,
				bench486_forwardspans_asm_result.x87_sw);
		bench486_memory_failures++;
	}
	else
		Bench486Printf ("forward-spans %s rm%d PASS (%u spans, guarded state exact)\n",
				test->name, rounding_mode,
				bench486_forwardspans_c_result.span_count);
}

static void Bench486ForwardSpansCases (void)
{
	static struct
	{
		surf_t *surface_base;
		espan_t *span_cursor, *span_limit;
		edge_t head, tail;
		int bmodel_active, head_u, tail_u, scanline;
		float fv_value;
	} saved;
	unsigned short saved_cw;
	unsigned case_index, mode, case_count, failures_before;

	saved.surface_base = surfaces;
	saved.span_cursor = span_p;
	saved.span_limit = max_span_p;
	Q_memcpy (&saved.head, &edge_head, sizeof(edge_head));
	Q_memcpy (&saved.tail, &edge_tail, sizeof(edge_tail));
	saved.bmodel_active = r_bmodelactive;
	saved.head_u = edge_head_u_shift20;
	saved.tail_u = edge_tail_u_shift20;
	saved.scanline = current_iv;
	saved.fv_value = fv;
	__asm__ __volatile__ ("fnstenv %0\n\tfldenv %0"
			: "=m" (bench486_forwardspans_x87_env));
	saved_cw = bench486_forwardspans_x87_env[0];
	failures_before = bench486_memory_failures;
	case_count = sizeof(bench486_forwardspans_cases) /
			sizeof(bench486_forwardspans_cases[0]);
	Bench486Printf ("forward-spans C/ASM begin (%u cases; four x87 rounding modes; guarded surface, edge and span pools)\n",
			case_count);
	for (case_index = 0; case_index < case_count; case_index++)
		for (mode = 0; mode < 4; mode++)
			Bench486ForwardSpansCompare (&bench486_forwardspans_cases[case_index],
					(int)mode, saved_cw);

	__asm__ __volatile__ ("fnclex\n\tfldcw %0" : : "m" (saved_cw));
	surfaces = saved.surface_base;
	span_p = saved.span_cursor;
	max_span_p = saved.span_limit;
	Q_memcpy (&edge_head, &saved.head, sizeof(edge_head));
	Q_memcpy (&edge_tail, &saved.tail, sizeof(edge_tail));
	r_bmodelactive = saved.bmodel_active;
	edge_head_u_shift20 = saved.head_u;
	edge_tail_u_shift20 = saved.tail_u;
	current_iv = saved.scanline;
	fv = saved.fv_value;
	R_SurfacePatch ();
	__asm__ __volatile__ ("fldenv %0" : : "m" (bench486_forwardspans_x87_env));
	Bench486Printf ("forward-spans C/ASM %s (%u cases, %u comparisons, %u failures)\n",
			failures_before == bench486_memory_failures ? "PASS" : "FAIL",
			case_count, case_count * 4,
			bench486_memory_failures - failures_before);
}

#undef BFS_EDGE
#undef BFS_FIXED_U

#endif /* BENCH486 */

#endif /* BENCH486_FORWARDSPANS_H */
