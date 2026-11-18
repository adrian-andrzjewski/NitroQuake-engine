/* Exact C-oracle versus i486 framebuffer coverage for R_LineGraph. */
/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
#ifndef BENCH486_LINEGRAPH_H
#define BENCH486_LINEGRAPH_H

#define LG_FIXTURE_VISIBLE_WIDTH 64
#define LG_FIXTURE_ROWBYTES      72
#define LG_FIXTURE_ROWS          48
#define LG_FIXTURE_GUARD_WORDS   8

typedef struct
{
	unsigned before[LG_FIXTURE_GUARD_WORDS];
	byte pixels[LG_FIXTURE_ROWBYTES * LG_FIXTURE_ROWS];
	unsigned after[LG_FIXTURE_GUARD_WORDS];
} bench486_linegraph_buffer_t;

typedef struct
{
	const char *name;
	float graphheight;
	int height;
	int x;
	int y;
	int view_x;
	int view_y;
} bench486_linegraph_case_t;

static bench486_linegraph_buffer_t bench486_linegraph_initial;
static bench486_linegraph_buffer_t bench486_linegraph_work;
static bench486_linegraph_buffer_t bench486_linegraph_reference;
static bench486_linegraph_buffer_t bench486_linegraph_expected;

extern void R_LineGraph_C (int x, int y, int height);
extern void R_LineGraph_asm486 (int x, int y, int height);

static byte Bench486LineGraphPaddingValue (unsigned row, unsigned column)
{
	return (byte)(0x80U + ((row * 13U + column * 7U) % 0x7fU));
}

static void Bench486LineGraphFillInitial (unsigned seed)
{
	unsigned i, row, column;

	Q_memset (&bench486_linegraph_initial, 0, sizeof(bench486_linegraph_initial));
	for (i = 0 ; i < LG_FIXTURE_GUARD_WORDS ; i++)
	{
		bench486_linegraph_initial.before[i] = 0x5a5a5a5aU;
		bench486_linegraph_initial.after[i] = 0xa5a5a5a5U;
	}
	for (i = 0 ; i < sizeof(bench486_linegraph_initial.pixels) ; i++)
		bench486_linegraph_initial.pixels[i] = (byte)(i * 37U + seed * 19U + 7U);

	/* The full stride is allocated; mark every non-visible byte as a canary. */
	for (row = 0 ; row < LG_FIXTURE_ROWS ; row++)
		for (column = LG_FIXTURE_VISIBLE_WIDTH ;
				column < LG_FIXTURE_ROWBYTES ; column++)
			bench486_linegraph_initial.pixels[
				row * LG_FIXTURE_ROWBYTES + column] =
				Bench486LineGraphPaddingValue (row, column);
}

static int Bench486LineGraphGuards (const bench486_linegraph_buffer_t *buffer)
{
	unsigned i;

	for (i = 0 ; i < LG_FIXTURE_GUARD_WORDS ; i++)
	{
		if (buffer->before[i] != 0x5a5a5a5aU ||
				buffer->after[i] != 0xa5a5a5a5U)
			return 0;
	}
	return 1;
}

static int Bench486LineGraphPaddingCanaries (
		const bench486_linegraph_buffer_t *buffer)
{
	unsigned row, column;

	for (row = 0 ; row < LG_FIXTURE_ROWS ; row++)
		for (column = LG_FIXTURE_VISIBLE_WIDTH ;
				column < LG_FIXTURE_ROWBYTES ; column++)
			if (buffer->pixels[row * LG_FIXTURE_ROWBYTES + column] !=
					Bench486LineGraphPaddingValue (row, column))
				return 0;
	return 1;
}

static int Bench486LineGraphFirstDifference (
		const bench486_linegraph_buffer_t *left,
		const bench486_linegraph_buffer_t *right)
{
	unsigned i;
	const byte *left_bytes = (const byte *)left;
	const byte *right_bytes = (const byte *)right;

	for (i = 0 ; i < sizeof(*left) ; i++)
		if (left_bytes[i] != right_bytes[i])
			return (int)i;
	return -1;
}

static unsigned Bench486LineGraphChecksum (const byte *pixels, unsigned count)
{
	unsigned i, hash = 0x486c696eU;

	for (i = 0 ; i < count ; i++)
		hash = (hash * 33U) ^ pixels[i];
	return hash;
}

static int Bench486LineGraphInputsAreSafe (
		const bench486_linegraph_case_t *test)
{
	int s = (int)test->graphheight;
	int x = test->x + test->view_x;
	int y = test->y + test->view_y;

	if (x < 0 || x >= LG_FIXTURE_VISIBLE_WIDTH ||
			y < 0 || y >= LG_FIXTURE_ROWS)
		return 0;
	if (s > 0 && y - 2 * (s - 1) - 1 < 0)
		return 0;
	return 1;
}

/* Independent byte-pattern oracle for the original two-row graph algorithm. */
static void Bench486LineGraphBuildExpected (
		const bench486_linegraph_case_t *test)
{
	int i, s = (int)test->graphheight;
	int h = test->height;
	int x = test->x + test->view_x;
	int y = test->y + test->view_y;

	Q_memcpy (&bench486_linegraph_expected, &bench486_linegraph_initial,
			sizeof(bench486_linegraph_expected));
	if (h > s)
		h = s;
	for (i = 0 ; i < s ; i++)
	{
		int row = y - i * 2;
		unsigned offset = (unsigned)row * LG_FIXTURE_ROWBYTES + (unsigned)x;

		bench486_linegraph_expected.pixels[offset] =
				(byte)(i < h ? 0xff : 0x30);
		bench486_linegraph_expected.pixels[offset - LG_FIXTURE_ROWBYTES] = 0x30;
	}
}

static void Bench486LineGraphSetInputs (const bench486_linegraph_case_t *test)
{
	vid.buffer = bench486_linegraph_work.pixels;
	vid.rowbytes = LG_FIXTURE_ROWBYTES;
	r_refdef.vrect.x = test->view_x;
	r_refdef.vrect.y = test->view_y;
	r_graphheight.value = test->graphheight;
}

static void Bench486LineGraphCases (void)
{
	static const bench486_linegraph_case_t cases[] =
	{
		{ "fractional-height-and-offsets", 5.75f, 2, 4, 21, 3, 2 },
		{ "height-clamped-to-fractional-limit", 4.75f, 9, 6, 22, 5, 4 },
		{ "negative-input-fills-dim-graph", 3.90f, -2, 3, 21, 2, 4 },
		{ "fractional-height-below-one", 0.99f, 1, 1, 24, 4, 3 },
		{ "zero-height-fills-background", 3.40f, 0, 12, 27, 3, 4 },
		{ "negative-fractional-graphheight", -1.75f, 2, 9, 20, 4, 3 },
		{ "last-visible-column-with-padding", 1.99f, 1, 61, 8, 2, 3 }
	};
	byte *saved_buffer;
	int saved_rowbytes, saved_view_x, saved_view_y;
	float saved_graphheight;
	unsigned i, failures = 0;
	unsigned case_count = (unsigned)(sizeof(cases) / sizeof(cases[0]));

	saved_buffer = vid.buffer;
	saved_rowbytes = vid.rowbytes;
	saved_view_x = r_refdef.vrect.x;
	saved_view_y = r_refdef.vrect.y;
	saved_graphheight = r_graphheight.value;

	Bench486Printf ("linegraph fixture begin (%u cases; stride %d, visible %d)\n",
			case_count, LG_FIXTURE_ROWBYTES, LG_FIXTURE_VISIBLE_WIDTH);
	for (i = 0 ; i < case_count ; i++)
	{
		int c_guards, asm_guards, c_padding, asm_padding;
		int c_difference, asm_difference, pair_difference;

		Bench486Printf ("linegraph %u/%u %s\n", i + 1, case_count, cases[i].name);
		if (!Bench486LineGraphInputsAreSafe (&cases[i]))
		{
			failures++;
			Bench486Printf ("linegraph %s FAIL unsafe fixture coordinates\n",
					cases[i].name);
			continue;
		}

		Bench486LineGraphFillInitial (i);
		Bench486LineGraphBuildExpected (&cases[i]);

		/* Reset every byte, including row padding and outer canaries, for C. */
		Q_memcpy (&bench486_linegraph_work, &bench486_linegraph_initial,
				sizeof(bench486_linegraph_work));
		Bench486LineGraphSetInputs (&cases[i]);
		R_LineGraph_C (cases[i].x, cases[i].y, cases[i].height);
		c_guards = Bench486LineGraphGuards (&bench486_linegraph_work);
		c_padding = Bench486LineGraphPaddingCanaries (&bench486_linegraph_work);
		Q_memcpy (&bench486_linegraph_reference, &bench486_linegraph_work,
				sizeof(bench486_linegraph_reference));

		/* Independently reset the same bytes and globals before the assembly call. */
		Q_memcpy (&bench486_linegraph_work, &bench486_linegraph_initial,
				sizeof(bench486_linegraph_work));
		Bench486LineGraphSetInputs (&cases[i]);
		R_LineGraph_asm486 (cases[i].x, cases[i].y, cases[i].height);
		asm_guards = Bench486LineGraphGuards (&bench486_linegraph_work);
		asm_padding = Bench486LineGraphPaddingCanaries (&bench486_linegraph_work);

		c_difference = Bench486LineGraphFirstDifference (
				&bench486_linegraph_reference, &bench486_linegraph_expected);
		asm_difference = Bench486LineGraphFirstDifference (
				&bench486_linegraph_work, &bench486_linegraph_expected);
		pair_difference = Bench486LineGraphFirstDifference (
				&bench486_linegraph_reference, &bench486_linegraph_work);
		if (!c_guards || !asm_guards || !c_padding || !asm_padding ||
				c_difference >= 0 || asm_difference >= 0 || pair_difference >= 0)
		{
			failures++;
			if (failures < 8)
				Bench486Printf (
						"linegraph %s FAIL expected C/ASM/pair %d/%d/%d guards %d/%d padding %d/%d\n",
						cases[i].name, c_difference, asm_difference, pair_difference,
						c_guards, asm_guards, c_padding, asm_padding);
		}
		bench486_sink ^= Bench486LineGraphChecksum (
				bench486_linegraph_work.pixels,
				sizeof(bench486_linegraph_work.pixels));
	}

	vid.buffer = saved_buffer;
	vid.rowbytes = saved_rowbytes;
	r_refdef.vrect.x = saved_view_x;
	r_refdef.vrect.y = saved_view_y;
	r_graphheight.value = saved_graphheight;
	bench486_memory_failures += (int)failures;
	Bench486Printf ("linegraph exact framebuffer/canaries %s (%u cases; %u failures)\n",
			failures ? "FAIL" : "PASS", case_count, failures);
}

#endif /* BENCH486_LINEGRAPH_H */
