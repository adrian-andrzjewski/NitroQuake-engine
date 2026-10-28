#ifndef BENCH486_VGA_SWAP_H
#define BENCH486_VGA_SWAP_H

#if defined(BENCH486) && defined(ASM486_VGA_PRESENTATION_FIXTURE)
#define BENCH486_VGA_SWAP_GUARD 16
#define BENCH486_VGA_SWAP_SOURCE_SIZE (BENCH486_VGA_SWAP_GUARD + 64 * 8 + BENCH486_VGA_SWAP_GUARD)
#define BENCH486_VGA_SWAP_DEST_SIZE (BENCH486_VGA_SWAP_GUARD + 80 * 8 + BENCH486_VGA_SWAP_GUARD)

static byte bench486_vga_swap_source[BENCH486_VGA_SWAP_SOURCE_SIZE];
static byte bench486_vga_swap_c_dest[BENCH486_VGA_SWAP_DEST_SIZE];
static byte bench486_vga_swap_asm_dest[BENCH486_VGA_SWAP_DEST_SIZE];
static byte bench486_vga_swap_expected[BENCH486_VGA_SWAP_DEST_SIZE];

static void Bench486VgaSwapFill (byte *buffer, int size, byte value)
{
	int i;

	for (i = 0; i < size; i++)
		buffer[i] = value;
}

static int Bench486VgaSwapEqual (const byte *left, const byte *right, int size)
{
	int i;

	for (i = 0; i < size; i++)
		if (left[i] != right[i])
			return false;

	return true;
}

static void Bench486VgaSwapSeedSource (void)
{
	int i;

	for (i = 0; i < BENCH486_VGA_SWAP_SOURCE_SIZE; i++)
		bench486_vga_swap_source[i] = (byte)(i * 29 + 7);
}

static void Bench486VgaSwapSeedRects (vrect_t *rects)
{
	Q_memset (rects, 0, 3 * sizeof(*rects));
	rects[0].x = 4;
	rects[0].y = 1;
	rects[0].width = 11;
	rects[0].height = 3;
	rects[0].pnext = &rects[1];
	rects[1].x = 20;
	rects[1].y = 4;
	rects[1].width = 14;
	rects[1].height = 2;
	rects[1].pnext = &rects[2];
	rects[2].x = 40;
	rects[2].y = 1;
	rects[2].width = 9;
	rects[2].height = 6;
	rects[2].pnext = NULL;
}

static void Bench486VgaSwapBuildExpected (const vrect_t *rects)
{
	const vrect_t *rect;
	int row, column;
	int source_offset, dest_offset;

	Bench486VgaSwapFill (bench486_vga_swap_expected,
		BENCH486_VGA_SWAP_DEST_SIZE, 0xa7);
	for (rect = rects; rect; rect = rect->pnext)
	{
		for (row = 0; row < rect->height; row++)
		{
			source_offset = BENCH486_VGA_SWAP_GUARD +
				(rect->y + row) * 64 + rect->x;
			dest_offset = BENCH486_VGA_SWAP_GUARD +
				(rect->y + row) * 80 + rect->x;
			for (column = 0; column < rect->width; column++)
				bench486_vga_swap_expected[dest_offset + column] =
					bench486_vga_swap_source[source_offset + column];
		}
	}
}

int Bench486VgaPresentationCases (void)
{
	viddef_t vid;
	vmode_t mode;
	vrect_t rects[3];
	byte *saved_pagebase;
	int saved_planar, saved_rowbytes, saved_bufferrowbytes;
	int saved_width, saved_height;
	float saved_wait;
	int failures;

	saved_pagebase = VGA_pagebase;
	saved_planar = VGA_planar;
	saved_rowbytes = VGA_rowbytes;
	saved_bufferrowbytes = VGA_bufferrowbytes;
	saved_width = VGA_width;
	saved_height = VGA_height;
	saved_wait = vid_wait.value;
	failures = 0;

	Q_memset (&vid, 0, sizeof(vid));
	Q_memset (&mode, 0, sizeof(mode));
	vid.buffer = bench486_vga_swap_source + BENCH486_VGA_SWAP_GUARD;
	vid.rowbytes = 64;
	vid.width = 56;
	vid.height = 8;
	Bench486VgaSwapSeedSource ();
	Bench486VgaSwapSeedRects (rects);
	VGA_planar = 0;
	VGA_rowbytes = 80;
	VGA_width = 56;
	VGA_height = 8;
	VGA_bufferrowbytes = 64;
	vid_wait.value = VID_WAIT_NONE;

	/* Three dirty rectangles, row padding, and untouched canaries. */
	Bench486VgaSwapFill (bench486_vga_swap_c_dest,
		BENCH486_VGA_SWAP_DEST_SIZE, 0xa7);
	Bench486VgaSwapFill (bench486_vga_swap_asm_dest,
		BENCH486_VGA_SWAP_DEST_SIZE, 0xa7);
	Bench486VgaSwapBuildExpected (rects);
	VGA_pagebase = bench486_vga_swap_c_dest + BENCH486_VGA_SWAP_GUARD;
	VGA_SwapBuffersCopy_C (&vid, &mode, rects);
	VGA_pagebase = bench486_vga_swap_asm_dest + BENCH486_VGA_SWAP_GUARD;
	VGA_SwapBuffersCopy (&vid, &mode, rects);
	if (!Bench486VgaSwapEqual (bench486_vga_swap_c_dest,
			bench486_vga_swap_asm_dest, BENCH486_VGA_SWAP_DEST_SIZE) ||
		!Bench486VgaSwapEqual (bench486_vga_swap_c_dest,
			bench486_vga_swap_expected, BENCH486_VGA_SWAP_DEST_SIZE))
		failures |= 1;

	/* A null rectangle list is a no-op in linear mode. */
	Bench486VgaSwapFill (bench486_vga_swap_c_dest,
		BENCH486_VGA_SWAP_DEST_SIZE, 0x5c);
	Bench486VgaSwapFill (bench486_vga_swap_asm_dest,
		BENCH486_VGA_SWAP_DEST_SIZE, 0x5c);
	VGA_pagebase = bench486_vga_swap_c_dest + BENCH486_VGA_SWAP_GUARD;
	VGA_SwapBuffersCopy_C (&vid, &mode, NULL);
	VGA_pagebase = bench486_vga_swap_asm_dest + BENCH486_VGA_SWAP_GUARD;
	VGA_SwapBuffersCopy (&vid, &mode, NULL);
	if (!Bench486VgaSwapEqual (bench486_vga_swap_c_dest,
			bench486_vga_swap_asm_dest, BENCH486_VGA_SWAP_DEST_SIZE))
		failures |= 2;

	/* The public swap entry preserves the C no-wait decision and call order. */
	Bench486VgaSwapFill (bench486_vga_swap_c_dest,
		BENCH486_VGA_SWAP_DEST_SIZE, 0x31);
	Bench486VgaSwapFill (bench486_vga_swap_asm_dest,
		BENCH486_VGA_SWAP_DEST_SIZE, 0x31);
	VGA_pagebase = bench486_vga_swap_c_dest + BENCH486_VGA_SWAP_GUARD;
	VGA_SwapBuffers_C (&vid, &mode, rects);
	VGA_pagebase = bench486_vga_swap_asm_dest + BENCH486_VGA_SWAP_GUARD;
	VGA_SwapBuffers (&vid, &mode, rects);
	if (!Bench486VgaSwapEqual (bench486_vga_swap_c_dest,
			bench486_vga_swap_asm_dest, BENCH486_VGA_SWAP_DEST_SIZE))
		failures |= 4;

	/* Planar mode ignores dirty rectangles and delegates a full-page copy. */
	VGA_planar = 1;
	VGA_width = 32;
	VGA_height = 2;
	VGA_bufferrowbytes = 32;
	VGA_rowbytes = 8;
	Bench486VgaSwapFill (bench486_vga_swap_c_dest,
		BENCH486_VGA_SWAP_DEST_SIZE, 0xd2);
	Bench486VgaSwapFill (bench486_vga_swap_asm_dest,
		BENCH486_VGA_SWAP_DEST_SIZE, 0xd2);
	VGA_pagebase = bench486_vga_swap_c_dest + BENCH486_VGA_SWAP_GUARD;
	VGA_SwapBuffersCopy_C (&vid, &mode, NULL);
	outportb (0x3c4, 2);
	outportb (0x3c5, 0x0f);
	VGA_pagebase = bench486_vga_swap_asm_dest + BENCH486_VGA_SWAP_GUARD;
	VGA_SwapBuffersCopy (&vid, &mode, rects);
	outportb (0x3c4, 2);
	outportb (0x3c5, 0x0f);
	if (!Bench486VgaSwapEqual (bench486_vga_swap_c_dest,
			bench486_vga_swap_asm_dest, BENCH486_VGA_SWAP_DEST_SIZE))
		failures |= 8;

	/* Exercise both real VGA retrace wait loops before comparing the copy. */
	VGA_planar = 0;
	VGA_width = 56;
	VGA_height = 8;
	VGA_bufferrowbytes = 64;
	VGA_rowbytes = 80;
	vid_wait.value = VID_WAIT_VSYNC;
	Bench486VgaSwapFill (bench486_vga_swap_c_dest,
		BENCH486_VGA_SWAP_DEST_SIZE, 0x9b);
	Bench486VgaSwapFill (bench486_vga_swap_asm_dest,
		BENCH486_VGA_SWAP_DEST_SIZE, 0x9b);
	VGA_pagebase = bench486_vga_swap_c_dest + BENCH486_VGA_SWAP_GUARD;
	VGA_SwapBuffers_C (&vid, &mode, rects);
	VGA_pagebase = bench486_vga_swap_asm_dest + BENCH486_VGA_SWAP_GUARD;
	VGA_SwapBuffers (&vid, &mode, rects);
	if (!Bench486VgaSwapEqual (bench486_vga_swap_c_dest,
			bench486_vga_swap_asm_dest, BENCH486_VGA_SWAP_DEST_SIZE))
		failures |= 16;

	VGA_pagebase = saved_pagebase;
	VGA_planar = saved_planar;
	VGA_rowbytes = saved_rowbytes;
	VGA_bufferrowbytes = saved_bufferrowbytes;
	VGA_width = saved_width;
	VGA_height = saved_height;
	vid_wait.value = saved_wait;
	return failures;
}

#undef BENCH486_VGA_SWAP_GUARD
#undef BENCH486_VGA_SWAP_SOURCE_SIZE
#undef BENCH486_VGA_SWAP_DEST_SIZE
#endif /* BENCH486 && ASM486_VGA_PRESENTATION_FIXTURE */

#endif /* BENCH486_VGA_SWAP_H */
