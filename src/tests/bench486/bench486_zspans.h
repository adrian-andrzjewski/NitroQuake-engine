/* Exact C-oracle parity coverage for the active i486 Z-span renderer. */
#ifndef BENCH486_ZSPANS_H
#define BENCH486_ZSPANS_H

#ifdef BENCH486

#define BZS_ROWS 16
#define BZS_STRIDE 64
#define BZS_SPAN_COUNT 3
#define BZS_GUARD_WORDS 8

typedef struct
{
	unsigned int before[BZS_GUARD_WORDS];
	short pixels[BZS_ROWS * BZS_STRIDE];
	unsigned int after[BZS_GUARD_WORDS];
} bench486_zspans_buffer_t;

typedef struct
{
	const char *name;
	float origin;
	float step_u;
	float step_v;
} bench486_zspans_gradient_t;

static const int bench486_zspans_lengths[] =
{
	1, 2, 3, 4, 5, 7, 8, 9, 15, 16, 31, 32, 33
};

static const bench486_zspans_gradient_t bench486_zspans_gradients[] =
{
	{ "flat", 0.125f, 0.0f, 0.0f },
	{ "positive-gradient", 0.125f, 1.0f / 32768.0f,
		1.0f / 65536.0f },
	{ "negative-gradient", 0.375f, -1.0f / 32768.0f,
		-1.0f / 65536.0f },
	{ "negative-depth", -0.125f, 1.0f / 32768.0f,
		1.0f / 65536.0f },
	/* Three samples cross a 16-bit depth boundary only if the C cast's
	 * truncate-toward-zero rule is preserved (1/98302 * 2^31 = 21845.77...). */
	{ "truncate-boundary", 0.125f, 1.0f / 98302.0f, 0.0f },
	{ "maximum-depth", 0.5f, 0.0f, 0.0f },
	{ "vertical-gradient", 0.125f, 0.0f, 1.0f / 65536.0f },
	{ "negative-vertical-gradient", 0.375f, 0.0f,
		-1.0f / 65536.0f },
	/* D_DrawSurfaces assigns -0.9 to SURF_DRAWBACKGROUND before calling the
	 * Z-span writer. Its negative packed-pair words are part of the reference. */
	{ "background-depth", -0.9f, 0.0f, 0.0f },
	/* These nonzero steps quantize to exactly one 2^-31 unit per pixel.
	 * The first pair exercises equal high words in the positive and negative
	 * long-span shortcuts; the second pair crosses a 16-bit boundary and must
	 * fall back to the normal per-pixel writer. */
	{ "constant-positive", 0.125f, 1.0f / 2147483648.0f, 0.0f },
	{ "constant-negative", 0.125f + 1.0f / 32768.0f +
			2.0f / 67108864.0f, -1.0f / 2147483648.0f, 0.0f },
	{ "boundary-positive", 0.125f + 1.0f / 32768.0f -
			1.0f / 67108864.0f, 1.0f / 2147483648.0f, 0.0f },
	{ "boundary-negative", 0.125f + 1.0f / 32768.0f,
			-1.0f / 2147483648.0f, 0.0f }
};

static bench486_zspans_buffer_t bench486_zspans_c_buffer;
static bench486_zspans_buffer_t bench486_zspans_asm_buffer;

extern unsigned Bench486Call_asm486 (void (*function)(void), unsigned words,
		const unsigned *arguments, float *float_result);

static void Bench486ZSpansSetRows (short *pixels)
{
	int row;
	for (row = 0; row < BZS_ROWS; row++)
		zspantable[row] = pixels + row * BZS_STRIDE;
}

static void Bench486ZSpansCases (void)
{
	short *saved_rows[BZS_ROWS];
	short *saved_zbuffer;
	unsigned int saved_zwidth;
	float saved_origin, saved_step_u, saved_step_v;
	unsigned short original_cw, test_cw, c_cw, asm_cw;
	unsigned short baseline_sw, c_sw, asm_before_sw, asm_sw;
	unsigned int arguments[1];
	espan_t spans[BZS_SPAN_COUNT];
	int gradient_index, length_index, span_index, row;
	int byte_index, failures, cases, abi;
	const int length_count = sizeof(bench486_zspans_lengths) /
			sizeof(bench486_zspans_lengths[0]);
	const int gradient_count = sizeof(bench486_zspans_gradients) /
			sizeof(bench486_zspans_gradients[0]);
	const int span_count = BZS_SPAN_COUNT;
	unsigned char *c_bytes, *asm_bytes;

	__asm__ __volatile__ ("fnstcw %0" : "=m" (original_cw));
	saved_zbuffer = d_pzbuffer;
	saved_zwidth = d_zwidth;
	saved_origin = d_ziorigin;
	saved_step_u = d_zistepu;
	saved_step_v = d_zistepv;
	for (row = 0; row < BZS_ROWS; row++)
		saved_rows[row] = zspantable[row];

	d_zwidth = BZS_STRIDE;
	failures = 0;
	cases = 0;
	for (gradient_index = 0; gradient_index < gradient_count;
			gradient_index++)
	{
		d_ziorigin = bench486_zspans_gradients[gradient_index].origin;
		d_zistepu = bench486_zspans_gradients[gradient_index].step_u;
		d_zistepv = bench486_zspans_gradients[gradient_index].step_v;
		for (length_index = 0; length_index < length_count; length_index++)
		{
			for (span_index = 0; span_index < span_count; span_index++)
			{
				int u;
				spans[span_index].u =
						gradient_index == 10 ? 1 :
						(gradient_index == 4 || gradient_index >= 9) ? 0 :
						2 + ((length_index + span_index) & 1);
				spans[span_index].v = 1 + span_index * 3;
				spans[span_index].count = bench486_zspans_lengths[
						(length_index + span_index * 5) % length_count];
				spans[span_index].pnext = span_index + 1 < span_count ?
						&spans[span_index + 1] : NULL;
				u = spans[span_index].u;
				if (u + spans[span_index].count > BZS_STRIDE)
					spans[span_index].count = BZS_STRIDE - u;
			}

			Q_memset (&bench486_zspans_c_buffer, 0xa5,
					sizeof(bench486_zspans_c_buffer));
			Q_memset (&bench486_zspans_asm_buffer, 0xa5,
					sizeof(bench486_zspans_asm_buffer));
			d_pzbuffer = bench486_zspans_c_buffer.pixels;
			Bench486ZSpansSetRows (bench486_zspans_c_buffer.pixels);
			__asm__ __volatile__ ("fldcw %0" : : "m" (original_cw));
			__asm__ __volatile__ ("fnstsw %0" : "=m" (baseline_sw));
			D_DrawZSpans_C (spans);
			__asm__ __volatile__ ("fnstcw %0" : "=m" (c_cw));
			__asm__ __volatile__ ("fnstsw %0" : "=m" (c_sw));

			d_pzbuffer = bench486_zspans_asm_buffer.pixels;
			Bench486ZSpansSetRows (bench486_zspans_asm_buffer.pixels);
			arguments[0] = (unsigned int)spans;
			__asm__ __volatile__ ("fldcw %0" : : "m" (original_cw));
			__asm__ __volatile__ ("fnstsw %0" : "=m" (asm_before_sw));
			abi = Bench486Call_asm486 ((void (*)(void))D_DrawZSpans,
					1, arguments, NULL);
			__asm__ __volatile__ ("fnstcw %0" : "=m" (asm_cw));
			__asm__ __volatile__ ("fnstsw %0" : "=m" (asm_sw));
			cases++;

			c_bytes = (unsigned char *)&bench486_zspans_c_buffer;
			asm_bytes = (unsigned char *)&bench486_zspans_asm_buffer;
			byte_index = -1;
			if (Q_memcmp (&bench486_zspans_c_buffer,
					&bench486_zspans_asm_buffer,
					sizeof(bench486_zspans_c_buffer)) != 0)
			{
				for (row = 0; row < sizeof(bench486_zspans_c_buffer); row++)
					if (c_bytes[row] != asm_bytes[row])
					{
						byte_index = row;
						break;
					}
			}
			if (byte_index >= 0 || abi != 0 || c_cw != original_cw ||
					asm_cw != original_cw ||
					((c_sw ^ baseline_sw) & 0x3800) != 0 ||
					((asm_sw ^ asm_before_sw) & 0x3800) != 0)
			{
				failures++;
				bench486_memory_failures++;
				Bench486Printf ("zspans FAIL %s len %d byte %d c/asm %u/%u abi %u cw %04x/%04x top %u/%u\n",
						bench486_zspans_gradients[gradient_index].name,
						bench486_zspans_lengths[length_index], byte_index,
						byte_index >= 0 ? c_bytes[byte_index] : 0,
						byte_index >= 0 ? asm_bytes[byte_index] : 0,
						abi, c_cw, asm_cw, (unsigned)(c_sw >> 11) & 7,
						(unsigned)(asm_sw >> 11) & 7);
			}
		}
	}

	d_pzbuffer = saved_zbuffer;
	d_zwidth = saved_zwidth;
	d_ziorigin = saved_origin;
	d_zistepu = saved_step_u;
	d_zistepv = saved_step_v;
	for (row = 0; row < BZS_ROWS; row++)
		zspantable[row] = saved_rows[row];
	__asm__ __volatile__ ("fldcw %0" : : "m" (original_cw));
	Bench486Printf ("D_DrawZSpans C/asm parity %s (%d exact cases; %d mismatches)\n",
			failures ? "FAIL" : "PASS", cases, failures);
}

#undef BZS_ROWS
#undef BZS_STRIDE
#undef BZS_SPAN_COUNT
#undef BZS_GUARD_WORDS

#endif

#endif
