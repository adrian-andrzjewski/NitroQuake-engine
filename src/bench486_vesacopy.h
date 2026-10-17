/* Direct VESA C/assembly rectangle-copy parity over guarded frame buffers. */
#if defined(BENCH486) && defined(ASM486_VESA_COPY_RECTS_FIXTURE)

static void Bench486VesaRect (vrect_t *rect, int x, int y, int width,
		int height, vrect_t *next)
{
	rect->x = x;
	rect->y = y;
	rect->width = width;
	rect->height = height;
	rect->pnext = next;
}

static void Bench486VesaCopyReference (vrect_t *rects,
		const byte *srcbase, byte *dstbase, int vidwidth, int vidheight,
		int srcrowbytes, int destrowbytes)
{
	int x, y;
	for (; rects; rects = rects->pnext)
	{
		if (rects->width <= 0 || rects->height <= 0 ||
			rects->x < 0 || rects->y < 0 ||
			(unsigned)rects->width > (unsigned)vidwidth ||
			(unsigned)rects->height > (unsigned)vidheight ||
			(unsigned)rects->x > (unsigned)(vidwidth - rects->width) ||
			(unsigned)rects->y > (unsigned)(vidheight - rects->height))
			continue;
		for (y = 0; y < rects->height; y++)
			for (x = 0; x < rects->width; x++)
				dstbase[(rects->y + y) * destrowbytes + rects->x + x] =
					srcbase[(rects->y + y) * srcrowbytes + rects->x + x];
	}
}

int Bench486VesaCopyRectsCases (void)
{
	byte source[28 * 12], source_saved[28 * 12];
	byte c_output[32 * 14], asm_output[32 * 14], expected[32 * 14];
	vrect_t rects[9];
	int i, failures;
	for (i = 0; i < (int)sizeof (source); i++)
		source[i] = (byte)(i * 37 + 11);
	Q_memcpy (source_saved, source, sizeof (source));
	for (i = 0; i < (int)sizeof (c_output); i++)
		c_output[i] = asm_output[i] = expected[i] = 0xcd;
	Bench486VesaRect (&rects[0], 2, 1, 0, 3, &rects[1]);
	Bench486VesaRect (&rects[1], -1, 0, 4, 2, &rects[2]);
	Bench486VesaRect (&rects[2], 22, 0, 4, 2, &rects[3]);
	Bench486VesaRect (&rects[3], 0, -1, 4, 2, &rects[4]);
	Bench486VesaRect (&rects[4], 0, 11, 4, 2, &rects[5]);
	Bench486VesaRect (&rects[5], 3, 1, 5, 3, &rects[6]);
	Bench486VesaRect (&rects[6], 7, 5, 8, 4, &rects[7]);
	Bench486VesaRect (&rects[7], 21, 2, 3, 4, &rects[8]);
	Bench486VesaRect (&rects[8], 0, 0, 24, 1, NULL);
	Bench486VesaCopyReference (rects, source, expected, 24, 12, 28, 32);
	VESA_CopyRects_C (rects, source, c_output, 24, 12, 28, 32);
	VESA_CopyRects (rects, source, asm_output, 24, 12, 28, 32);
	failures = 0;
	if (Q_memcmp (c_output, expected, sizeof (expected))) failures |= 1;
	if (Q_memcmp (asm_output, expected, sizeof (expected))) failures |= 2;
	if (Q_memcmp (source, source_saved, sizeof (source))) failures |= 4;

	/* Equal full-width pitches exercise the flattened contiguous copy shape. */
	for (i = 0; i < (int)sizeof (c_output); i++)
		c_output[i] = asm_output[i] = expected[i] = 0xcd;
	Bench486VesaRect (&rects[0], 0, 0, 24, 12, NULL);
	Bench486VesaCopyReference (&rects[0], source, expected, 24, 12, 24, 24);
	VESA_CopyRects_C (&rects[0], source, c_output, 24, 12, 24, 24);
	VESA_CopyRects (&rects[0], source, asm_output, 24, 12, 24, 24);
	if (Q_memcmp (c_output, expected, sizeof (expected))) failures |= 8;
	if (Q_memcmp (asm_output, expected, sizeof (expected))) failures |= 16;

	/* A null rectangle chain must leave all guarded destination bytes intact. */
	for (i = 0; i < (int)sizeof (c_output); i++)
		c_output[i] = asm_output[i] = expected[i] = 0x6b;
	VESA_CopyRects_C (NULL, source, c_output, 24, 12, 28, 32);
	VESA_CopyRects (NULL, source, asm_output, 24, 12, 28, 32);
	if (Q_memcmp (c_output, expected, sizeof (expected))) failures |= 32;
	if (Q_memcmp (asm_output, expected, sizeof (expected))) failures |= 64;
	return failures;
}

#endif
