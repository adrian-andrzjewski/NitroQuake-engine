/* Exact C-reference and i486 coverage for R_TimeGraph's history and layout. */
/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
#ifndef BENCH486_TIMEGRAPH_H
#define BENCH486_TIMEGRAPH_H

#include "renderer/r_timegraph_state.h"

#define TG_FIXTURE_ROWBYTES       336
#define TG_FIXTURE_VISIBLE        328
#define TG_FIXTURE_ROWS           64
#define TG_FIXTURE_GUARD_WORDS    8
#define TG_FIXTURE_FRAMES         257
#define TG_FIXTURE_ROUNDING_MODES 4

typedef struct
{
	unsigned before[TG_FIXTURE_GUARD_WORDS];
	byte pixels[TG_FIXTURE_ROWBYTES * TG_FIXTURE_ROWS];
	unsigned after[TG_FIXTURE_GUARD_WORDS];
} bench486_timegraph_buffer_t;

typedef struct
{
	bench486_timegraph_buffer_t initial;
	bench486_timegraph_buffer_t expected;
	bench486_timegraph_buffer_t reference;
	bench486_timegraph_buffer_t assembly;
} bench486_timegraph_workspace_t;

static bench486_timegraph_workspace_t *bench486_timegraph_workspace;

extern double Bench486TimeGraphTime (void);
extern void Bench486TimeGraphSetClock (int enabled, double value);

#if defined(ASM486_TIME_GRAPH)
extern void R_TimeGraph_C (void);
#endif

static byte Bench486TimeGraphPaddingValue (unsigned row, unsigned column)
{
	return (byte)(0x80U + ((row * 13U + column * 7U) % 0x7fU));
}

static void Bench486TimeGraphFillBuffer (bench486_timegraph_buffer_t *buffer,
		unsigned seed)
{
	unsigned i, row, column;

	Q_memset (buffer, 0, sizeof(*buffer));
	for (i = 0 ; i < TG_FIXTURE_GUARD_WORDS ; i++)
	{
		buffer->before[i] = 0x5a5a5a5aU;
		buffer->after[i] = 0xa5a5a5a5U;
	}
	for (i = 0 ; i < sizeof(buffer->pixels) ; i++)
		buffer->pixels[i] = (byte)(i * 37U + seed * 19U + 7U);
	for (row = 0 ; row < TG_FIXTURE_ROWS ; row++)
		for (column = TG_FIXTURE_VISIBLE ; column < TG_FIXTURE_ROWBYTES; column++)
			buffer->pixels[row * TG_FIXTURE_ROWBYTES + column] =
					Bench486TimeGraphPaddingValue (row, column);
}

static int Bench486TimeGraphCanariesAreValid (
		const bench486_timegraph_buffer_t *buffer)
{
	unsigned i, row, column;

	for (i = 0 ; i < TG_FIXTURE_GUARD_WORDS ; i++)
		if (buffer->before[i] != 0x5a5a5a5aU ||
				buffer->after[i] != 0xa5a5a5a5U)
			return 0;
	for (row = 0 ; row < TG_FIXTURE_ROWS ; row++)
		for (column = TG_FIXTURE_VISIBLE ; column < TG_FIXTURE_ROWBYTES; column++)
			if (buffer->pixels[row * TG_FIXTURE_ROWBYTES + column] !=
					Bench486TimeGraphPaddingValue (row, column))
				return 0;
	return 1;
}

static int Bench486TimeGraphFirstDifference (const byte *left,
		const byte *right, unsigned count)
{
	unsigned i;

	for (i = 0 ; i < count ; i++)
		if (left[i] != right[i])
			return (int)i;
	return -1;
}

static unsigned Bench486TimeGraphChecksum (const byte *pixels, unsigned count)
{
	unsigned i, hash = 0x74696d65U;

	for (i = 0 ; i < count ; i++)
		hash = (hash * 33U) ^ pixels[i];
	return hash;
}

static unsigned short Bench486TimeGraphReadControlWord (void)
{
	unsigned short word;

	__asm__ __volatile__ ("fnstcw %0" : "=m" (word));
	return word;
}

static unsigned short Bench486TimeGraphReadTop (void)
{
	unsigned short status;

	__asm__ __volatile__ ("fnstsw %0" : "=m" (status));
	return (unsigned short)(status & 0x3800U);
}

static void Bench486TimeGraphWriteControlWord (unsigned short word)
{
	__asm__ __volatile__ ("fldcw %0" : : "m" (word));
}

/* Independent model of the original C ring, x placement, and two-row painter. */
static void Bench486TimeGraphBuildExpected (r_timegraph_state_t *state,
		bench486_timegraph_buffer_t *buffer, int width, int height,
		int view_x, int view_y, int graph_rows, int sample)
{
	int x, a, i, h;

	state->timings[state->timex] = (byte)sample;
	a = state->timex;
	if (width <= TG_MAX_TIMINGS)
		x = width - 1;
	else
		x = width - (width - TG_MAX_TIMINGS) / 2;
	do
	{
		int row;
		unsigned offset;

		h = state->timings[a];
		if (h > graph_rows)
			h = graph_rows;
		for (i = 0 ; i < graph_rows ; i++)
		{
			row = view_y + height - 2 - i * 2;
			offset = (unsigned)row * TG_FIXTURE_ROWBYTES +
					(unsigned)(view_x + x);
			buffer->pixels[offset] = (byte)(i < h ? 0xff : 0x30);
			buffer->pixels[offset - TG_FIXTURE_ROWBYTES] = 0x30;
		}
		if (x == 0)
			break;
		x--;
		a--;
		if (a == -1)
			a = TG_MAX_TIMINGS - 1;
	} while (a != state->timex);

	state->timex = (state->timex + 1) % TG_MAX_TIMINGS;
}

static void Bench486TimeGraphSetInputs (byte *buffer, int width,
		int height, float graphheight)
{
	vid.buffer = buffer;
	vid.rowbytes = TG_FIXTURE_ROWBYTES;
	r_refdef.vrect.x = 2;
	r_refdef.vrect.y = 2;
	r_refdef.vrect.width = width;
	r_refdef.vrect.height = height;
	r_graphheight.value = graphheight;
}

static void Bench486TimeGraphCases (void)
{
	static const int sample_numerators[8] = { 0, 2, 9, 16, 240, 328, -5, 454 };
	static const int sample_values[8] = { 0, 1, 7, 12, 187, 256, -3, 354 };
	static const int widths[5] = { 1, 99, 100, 101, 320 };
	static const float heights[5] = { 0.0f, 0.99f, 1.75f, 8.5f, 12.75f };
	static const int graph_rows[5] = { 0, 0, 1, 8, 12 };
	static const unsigned short rounding_bits[4] =
		{ 0x0000U, 0x0400U, 0x0800U, 0x0c00U };
	static const char *rounding_names[4] =
		{ "nearest", "down", "up", "truncate" };
	r_timegraph_state_t saved_state, reference_state, assembly_state, expected_state;
	byte *saved_buffer;
	int saved_rowbytes, saved_view_x, saved_view_y, saved_view_width, saved_view_height;
	float saved_graphheight, saved_time1;
	unsigned short saved_control_word;
	unsigned round, frame, failures = 0, reported = 0;
	int run_assembly = 0;

	if (!bench486_timegraph_workspace)
		bench486_timegraph_workspace = (bench486_timegraph_workspace_t *)
				Hunk_AllocName (sizeof(*bench486_timegraph_workspace), "tg-parity");
	if (!bench486_timegraph_workspace)
	{
		bench486_memory_failures++;
		Bench486Printf ("timegraph fixture FAIL workspace allocation\n");
		return;
	}

	saved_buffer = vid.buffer;
	saved_rowbytes = vid.rowbytes;
	saved_view_x = r_refdef.vrect.x;
	saved_view_y = r_refdef.vrect.y;
	saved_view_width = r_refdef.vrect.width;
	saved_view_height = r_refdef.vrect.height;
	saved_graphheight = r_graphheight.value;
	saved_time1 = r_time1;
	saved_control_word = Bench486TimeGraphReadControlWord ();
	Q_memcpy (&saved_state, &r_timegraph_state, sizeof(saved_state));

#if defined(ASM486_TIME_GRAPH)
	run_assembly = 1;
#endif
	Bench486Printf ("timegraph fixture begin (%d frames x %d x87 modes; assembly %s)\n",
			TG_FIXTURE_FRAMES, TG_FIXTURE_ROUNDING_MODES,
			run_assembly ? "enabled" : "C reference only");
	r_time1 = 0.5f;
	for (round = 0 ; round < TG_FIXTURE_ROUNDING_MODES ; round++)
	{
		unsigned short test_control_word;

		test_control_word = (unsigned short)((saved_control_word & 0xf3ffU) |
				rounding_bits[round]);
		Bench486TimeGraphWriteControlWord (test_control_word);
		Q_memset (&expected_state, 0, sizeof(expected_state));
		Q_memset (&reference_state, 0, sizeof(reference_state));
		Q_memset (&assembly_state, 0, sizeof(assembly_state));
		Bench486TimeGraphFillBuffer (&bench486_timegraph_workspace->initial, round);
		Q_memcpy (&bench486_timegraph_workspace->expected,
				&bench486_timegraph_workspace->initial,
			sizeof(bench486_timegraph_workspace->expected));
		Q_memcpy (&bench486_timegraph_workspace->reference,
				&bench486_timegraph_workspace->initial,
			sizeof(bench486_timegraph_workspace->reference));
		Q_memcpy (&bench486_timegraph_workspace->assembly,
				&bench486_timegraph_workspace->initial,
			sizeof(bench486_timegraph_workspace->assembly));
		Bench486Printf ("timegraph rounding %s (%u/%u)\n",
				rounding_names[round], round + 1, TG_FIXTURE_ROUNDING_MODES);

		for (frame = 0 ; frame < TG_FIXTURE_FRAMES ; frame++)
		{
			unsigned sample_index = frame & 7U;
			unsigned width_index = frame % 5U;
			unsigned height_index = (frame / 3U) % 5U;
			double now = 0.5 + (double)sample_numerators[sample_index] / 128.0;
			unsigned short before_cw, after_cw, before_top, after_top;
			int c_difference, state_difference, canaries_ok;

			Bench486TimeGraphBuildExpected (&expected_state,
					&bench486_timegraph_workspace->expected,
					widths[width_index], 40, 2, 2, graph_rows[height_index],
					sample_values[sample_index]);
			Bench486TimeGraphSetClock (1, now);
			Bench486TimeGraphSetInputs (
					bench486_timegraph_workspace->reference.pixels,
					widths[width_index], 40, heights[height_index]);
			Q_memcpy (&r_timegraph_state, &reference_state, sizeof(reference_state));
			before_cw = Bench486TimeGraphReadControlWord ();
			before_top = Bench486TimeGraphReadTop ();
#if defined(ASM486_TIME_GRAPH)
			R_TimeGraph_C ();
#else
			R_TimeGraph ();
#endif
			after_cw = Bench486TimeGraphReadControlWord ();
			after_top = Bench486TimeGraphReadTop ();
			Q_memcpy (&reference_state, &r_timegraph_state, sizeof(reference_state));
			c_difference = Bench486TimeGraphFirstDifference (
					(const byte *)&bench486_timegraph_workspace->reference,
					(const byte *)&bench486_timegraph_workspace->expected,
					sizeof(bench486_timegraph_workspace->reference));
			state_difference = Bench486TimeGraphFirstDifference (
					(const byte *)&reference_state, (const byte *)&expected_state,
					sizeof(reference_state));
			canaries_ok = Bench486TimeGraphCanariesAreValid (
					&bench486_timegraph_workspace->reference);
			if (c_difference >= 0 || state_difference >= 0 || !canaries_ok ||
					after_cw != before_cw || after_top != before_top)
			{
				failures++;
				if (reported++ < 8)
					Bench486Printf ("timegraph %s frame %u C/reference FAIL pixels %d state %d canaries %d cw %04x/%04x top %04x/%04x\n",
							rounding_names[round], frame, c_difference,
							state_difference, canaries_ok, before_cw, after_cw,
							before_top, after_top);
			}

			if (run_assembly)
			{
				int asm_difference, pair_difference, asm_state_difference;

				Bench486TimeGraphSetInputs (
						bench486_timegraph_workspace->assembly.pixels,
						widths[width_index], 40, heights[height_index]);
				Q_memcpy (&r_timegraph_state, &assembly_state, sizeof(assembly_state));
				before_cw = Bench486TimeGraphReadControlWord ();
				before_top = Bench486TimeGraphReadTop ();
				R_TimeGraph ();
				after_cw = Bench486TimeGraphReadControlWord ();
				after_top = Bench486TimeGraphReadTop ();
				Q_memcpy (&assembly_state, &r_timegraph_state, sizeof(assembly_state));
				asm_difference = Bench486TimeGraphFirstDifference (
						(const byte *)&bench486_timegraph_workspace->assembly,
						(const byte *)&bench486_timegraph_workspace->expected,
						sizeof(bench486_timegraph_workspace->assembly));
				pair_difference = Bench486TimeGraphFirstDifference (
						(const byte *)&bench486_timegraph_workspace->assembly,
						(const byte *)&bench486_timegraph_workspace->reference,
						sizeof(bench486_timegraph_workspace->assembly));
				asm_state_difference = Bench486TimeGraphFirstDifference (
						(const byte *)&assembly_state, (const byte *)&expected_state,
						sizeof(assembly_state));
				canaries_ok = Bench486TimeGraphCanariesAreValid (
						&bench486_timegraph_workspace->assembly);
				if (asm_difference >= 0 || pair_difference >= 0 ||
						asm_state_difference >= 0 || !canaries_ok ||
						after_cw != before_cw || after_top != before_top)
				{
					failures++;
					if (reported++ < 8)
						Bench486Printf ("timegraph %s frame %u ASM/reference FAIL pixels %d pair %d state %d canaries %d cw %04x/%04x top %04x/%04x\n",
								rounding_names[round], frame, asm_difference,
								pair_difference, asm_state_difference, canaries_ok,
								before_cw, after_cw, before_top, after_top);
				}
			}

			if ((frame & 63U) == 63U)
				Bench486Printf ("timegraph progress %s %u/%u frames\n",
						rounding_names[round], frame + 1, TG_FIXTURE_FRAMES);
		}

		bench486_sink ^= Bench486TimeGraphChecksum (
				bench486_timegraph_workspace->expected.pixels,
				sizeof(bench486_timegraph_workspace->expected.pixels));
	}

	Bench486TimeGraphSetClock (0, 0.0);
	Bench486TimeGraphWriteControlWord (saved_control_word);
	Q_memcpy (&r_timegraph_state, &saved_state, sizeof(saved_state));
	vid.buffer = saved_buffer;
	vid.rowbytes = saved_rowbytes;
	r_refdef.vrect.x = saved_view_x;
	r_refdef.vrect.y = saved_view_y;
	r_refdef.vrect.width = saved_view_width;
	r_refdef.vrect.height = saved_view_height;
	r_graphheight.value = saved_graphheight;
	r_time1 = saved_time1;
	bench486_memory_failures += (int)failures;
	Bench486Printf ("timegraph exact framebuffer/ring/control-word %s (%u frames, %u x87 modes, %u failures)\n",
			failures ? "FAIL" : "PASS",
			TG_FIXTURE_FRAMES * TG_FIXTURE_ROUNDING_MODES,
			TG_FIXTURE_ROUNDING_MODES, failures);
}

#endif /* BENCH486_TIMEGRAPH_H */
