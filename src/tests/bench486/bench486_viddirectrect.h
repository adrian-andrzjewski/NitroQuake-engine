/* Direct C/assembly parity for the DOS VGA direct-rectangle path. */
/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
#if defined(BENCH486) && defined(ASM486_VID_UPDATE_FIXTURE)
#ifndef BENCH486_VIDDIRECTRECT_H
#define BENCH486_VIDDIRECTRECT_H

#define BVD_FRAME_BYTES (8192 + 32)
#define BVD_BACKING_BYTES (48 * 24)

static union
{
	unsigned long align;
	byte bytes[BVD_FRAME_BYTES];
} bvd_c_frame, bvd_asm_frame;
static byte bvd_seed_frame[BVD_FRAME_BYTES];
static byte bvd_c_begin_frame[BVD_FRAME_BYTES];
static byte bvd_c_end_frame[BVD_FRAME_BYTES];
static byte bvd_source[24 * 24];
static byte bvd_seed_backing[BVD_BACKING_BYTES];
static byte bvd_c_begin_backing[BVD_BACKING_BYTES];
static byte bvd_saved_backing[BVD_BACKING_BYTES];
static viddef_t bvd_saved_vid;
static vmode_t *bvd_saved_mode;
static int bvd_saved_rowbytes;

static void Bench486VidDirectRectSetState (byte *direct, float aspect,
		vmode_t *mode)
{
	Q_memset (&vid, 0, sizeof(vid));
	vid.direct = direct;
	vid.aspect = aspect;
	pcurrentmode = mode;
}

static void Bench486VidDirectRectSeed (void)
{
	int i;

	for (i=0 ; i<BVD_FRAME_BYTES ; i++)
		bvd_seed_frame[i] = (byte)(i * 29 + (i >> 2) + 0x37);
	for (i=0 ; i<BVD_BACKING_BYTES ; i++)
		bvd_seed_backing[i] = (byte)(i * 17 + 0x91);
	for (i=0 ; i<(int)sizeof(bvd_source) ; i++)
		bvd_source[i] = (byte)(i * 13 + 0x2b);
}

static int Bench486VidDirectRectGuards (byte *frame)
{
	return Q_memcmp (frame, bvd_seed_frame, 16) == 0 &&
		Q_memcmp (frame + BVD_FRAME_BYTES - 16,
			bvd_seed_frame + BVD_FRAME_BYTES - 16, 16) == 0;
}

int Bench486VidDirectRectCases (void)
{
	static const struct
	{
		int planar;
		float aspect;
		int x, y, width, height;
	} valid_cases[] = {
		{ 0, 1.0f, 12, 3, 4, 4 },
		{ 0, 1.5f, 20, 2, 24, 24 },
		{ 0, 2.0f, 8, 1, 12, 8 },
		{ 1, 1.0f, 19, 3, 16, 8 },
		{ 1, 1.5f, 21, 1, 24, 12 },
		{ 1, 2.0f, 8, 2, 8, 24 }
	};
	static const struct
	{
		int end;
		int direct;
		int mode;
		int width, height;
	} invalid_cases[] = {
		{ 0, 0, 1, 4, 4 }, { 0, 1, 0, 4, 4 },
		{ 0, 1, 1, 0, 4 }, { 0, 1, 1, 6, 4 },
		{ 0, 1, 1, 28, 4 }, { 0, 1, 1, 4, 28 },
		{ 1, 0, 1, 4, 4 }, { 1, 1, 0, 4, 4 },
		{ 1, 1, 1, 0, 4 }, { 1, 1, 1, 6, 4 },
		{ 1, 1, 1, 4, 6 }, { 1, 1, 1, 28, 4 },
		{ 1, 1, 1, 4, 28 }
	};
	static vmode_t c_mode, asm_mode;
	byte *c_direct, *asm_direct;
	int failures, i;

	bvd_saved_vid = vid;
	bvd_saved_mode = pcurrentmode;
	bvd_saved_rowbytes = VGA_rowbytes;
	Q_memcpy (bvd_saved_backing, VGA_directrect_backingbuf,
		BVD_BACKING_BYTES);
	Bench486VidDirectRectSeed ();
	c_direct = bvd_c_frame.bytes + 16;
	asm_direct = bvd_asm_frame.bytes + 16;
	VGA_rowbytes = 80;
	failures = 0;

	Q_memset (&c_mode, 0, sizeof(c_mode));
	Q_memset (&asm_mode, 0, sizeof(asm_mode));
	c_mode.begindirectrect = VGA_BeginDirectRect_C;
	c_mode.enddirectrect = VGA_EndDirectRect_C;
	asm_mode.begindirectrect = VGA_BeginDirectRect;
	asm_mode.enddirectrect = VGA_EndDirectRect;

	for (i=0 ; i<(int)(sizeof(valid_cases)/sizeof(valid_cases[0])) ; i++)
	{
		const int planar = valid_cases[i].planar;
		const float aspect = valid_cases[i].aspect;
		const int x = valid_cases[i].x;
		const int y = valid_cases[i].y;
		const int width = valid_cases[i].width;
		const int height = valid_cases[i].height;

		c_mode.planar = planar;
		asm_mode.planar = planar;
		Q_memcpy (bvd_c_frame.bytes, bvd_seed_frame, BVD_FRAME_BYTES);
		Q_memcpy (bvd_asm_frame.bytes, bvd_seed_frame, BVD_FRAME_BYTES);
		Q_memcpy (VGA_directrect_backingbuf, bvd_seed_backing,
			BVD_BACKING_BYTES);
		Bench486VidDirectRectSetState (c_direct, aspect, &c_mode);
		D_BeginDirectRect_C (x, y, bvd_source, width, height);
		Q_memcpy (bvd_c_begin_frame, bvd_c_frame.bytes,
			BVD_FRAME_BYTES);
		Q_memcpy (bvd_c_begin_backing, VGA_directrect_backingbuf,
			BVD_BACKING_BYTES);

		Q_memcpy (VGA_directrect_backingbuf, bvd_seed_backing,
			BVD_BACKING_BYTES);
		Bench486VidDirectRectSetState (asm_direct, aspect, &asm_mode);
		D_BeginDirectRect (x, y, bvd_source, width, height);
		if (Q_memcmp (bvd_c_begin_frame, bvd_asm_frame.bytes,
				BVD_FRAME_BYTES) != 0 ||
			Q_memcmp (bvd_c_begin_backing, VGA_directrect_backingbuf,
				BVD_BACKING_BYTES) != 0 ||
			!Bench486VidDirectRectGuards (bvd_c_frame.bytes) ||
			!Bench486VidDirectRectGuards (bvd_asm_frame.bytes))
			failures++;

		Bench486VidDirectRectSetState (c_direct, aspect, &c_mode);
		Q_memcpy (VGA_directrect_backingbuf, bvd_c_begin_backing,
			BVD_BACKING_BYTES);
		D_EndDirectRect_C (x, y, width, height);
		Q_memcpy (bvd_c_end_frame, bvd_c_frame.bytes,
			BVD_FRAME_BYTES);

		Q_memcpy (bvd_asm_frame.bytes, bvd_c_begin_frame,
			BVD_FRAME_BYTES);
		Q_memcpy (VGA_directrect_backingbuf, bvd_c_begin_backing,
			BVD_BACKING_BYTES);
		Bench486VidDirectRectSetState (asm_direct, aspect, &asm_mode);
		D_EndDirectRect (x, y, width, height);
		if (Q_memcmp (bvd_c_end_frame, bvd_asm_frame.bytes,
				BVD_FRAME_BYTES) != 0 ||
			!Bench486VidDirectRectGuards (bvd_c_end_frame) ||
			!Bench486VidDirectRectGuards (bvd_asm_frame.bytes))
			failures++;
	}

	for (i=0 ; i<(int)(sizeof(invalid_cases)/sizeof(invalid_cases[0])) ; i++)
	{
		int width, height, end, direct_ok, mode_ok;

		end = invalid_cases[i].end;
		direct_ok = invalid_cases[i].direct;
		mode_ok = invalid_cases[i].mode;
		width = invalid_cases[i].width;
		height = invalid_cases[i].height;
		c_mode.planar = 0;
		asm_mode.planar = 0;
		Q_memcpy (bvd_c_frame.bytes, bvd_seed_frame, BVD_FRAME_BYTES);
		Q_memcpy (bvd_asm_frame.bytes, bvd_seed_frame, BVD_FRAME_BYTES);
		Q_memcpy (VGA_directrect_backingbuf, bvd_seed_backing,
			BVD_BACKING_BYTES);
		Bench486VidDirectRectSetState (direct_ok ? c_direct : NULL,
			1.0f, mode_ok ? &c_mode : NULL);
		if (end)
			D_EndDirectRect_C (8, 4, width, height);
		else
			D_BeginDirectRect_C (8, 4, bvd_source, width, height);
		if (Q_memcmp (bvd_seed_frame, bvd_c_frame.bytes,
				BVD_FRAME_BYTES) != 0 ||
			Q_memcmp (bvd_seed_backing, VGA_directrect_backingbuf,
				BVD_BACKING_BYTES) != 0)
			failures++;

		Q_memcpy (VGA_directrect_backingbuf, bvd_seed_backing,
			BVD_BACKING_BYTES);
		Bench486VidDirectRectSetState (direct_ok ? asm_direct : NULL,
			1.0f, mode_ok ? &asm_mode : NULL);
		if (end)
			D_EndDirectRect (8, 4, width, height);
		else
			D_BeginDirectRect (8, 4, bvd_source, width, height);
		if (Q_memcmp (bvd_c_frame.bytes, bvd_asm_frame.bytes,
				BVD_FRAME_BYTES) != 0 ||
			Q_memcmp (bvd_seed_frame, bvd_asm_frame.bytes,
				BVD_FRAME_BYTES) != 0 ||
			Q_memcmp (bvd_seed_backing, VGA_directrect_backingbuf,
				BVD_BACKING_BYTES) != 0)
			failures++;
	}

	vid = bvd_saved_vid;
	pcurrentmode = bvd_saved_mode;
	VGA_rowbytes = bvd_saved_rowbytes;
	Q_memcpy (VGA_directrect_backingbuf, bvd_saved_backing,
		BVD_BACKING_BYTES);
	return failures;
}

#endif /* BENCH486_VIDDIRECTRECT_H */
#endif /* BENCH486 && ASM486_VID_UPDATE_FIXTURE */
