/* C-reference versus i486 presentation-state fixtures. */
/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
#ifndef BENCH486_VESASWAP_H
#define BENCH486_VESASWAP_H

#define BVSWAP_TEST_BYTES (3 * 65536 + 32)
#define BVSWAP_EVENT_CAPACITY 8

static byte bench486_vesa_swap_memory[BVSWAP_TEST_BYTES];
static byte bench486_vesa_swap_c_memory[BVSWAP_TEST_BYTES];
static byte bench486_vesa_swap_source[320 * 200];
static viddef_t bench486_vesa_swap_c_vid;
static viddef_t bench486_vesa_swap_asm_vid;
static vmode_t bench486_vesa_swap_mode;
static vesa_info_t bench486_vesa_swap_info;
static vrect_t bench486_vesa_swap_rects[2];
static int bench486_vesa_swap_events[BVSWAP_EVENT_CAPACITY];
static int bench486_vesa_swap_event_count;
static int bench486_vesa_swap_probe_vsync;
static int bench486_vesa_swap_probe_display;
static int bench486_vesa_swap_start_x;
static int bench486_vesa_swap_start_y;
static int bench486_vesa_swap_start_flags;
static int bench486_vesa_swap_failures;

static byte *bench486_vesa_swap_saved_membase;
static byte *bench486_vesa_swap_saved_pagebase;
static int bench486_vesa_swap_saved_currentpage;
static int bench486_vesa_swap_saved_displayedpage;
static int bench486_vesa_swap_saved_pagesize;
static int bench486_vesa_swap_saved_rowbytes;
static float bench486_vesa_swap_saved_wait;
static qboolean bench486_vesa_swap_saved_vsync;
static qboolean bench486_vesa_swap_saved_display;
static qboolean bench486_vesa_swap_saved_probed;

static int Bench486VesaSwapBytesEqual (const void *left, const void *right,
		unsigned size)
{
	const byte *a = left, *b = right;
	while (size--)
		if (*a++ != *b++) return false;
	return true;
}

static void Bench486VesaSwapEvent (int event)
{
	if (bench486_vesa_swap_event_count >= BVSWAP_EVENT_CAPACITY)
	{
		bench486_vesa_swap_failures++;
		return;
	}
	bench486_vesa_swap_events[bench486_vesa_swap_event_count++] = event;
}

void Bench486VesaSwapWaitVsync (void)
{
	Bench486VesaSwapEvent (2);
}

void Bench486VesaSwapWaitDisplayEnable (void)
{
	Bench486VesaSwapEvent (1);
}

static void Bench486VesaSwapProbeWait (void)
{
	Bench486VesaSwapEvent (3);
	vsync_exists = bench486_vesa_swap_probe_vsync;
	de_exists = bench486_vesa_swap_probe_display;
	wait_probed = true;
}

static void Bench486VesaSwapDisplayStart (int x, int y, int waitflags)
{
	Bench486VesaSwapEvent (4);
	bench486_vesa_swap_start_x = x;
	bench486_vesa_swap_start_y = y;
	bench486_vesa_swap_start_flags = waitflags;
}

static void Bench486VesaSwapResetEvents (void)
{
	bench486_vesa_swap_event_count = 0;
	bench486_vesa_swap_start_x = -1;
	bench486_vesa_swap_start_y = -1;
	bench486_vesa_swap_start_flags = -1;
	memset (bench486_vesa_swap_events, 0, sizeof(bench486_vesa_swap_events));
}

static void Bench486VesaSwapInit (viddef_t *video, int pages, int currentpage,
		int pagesize, int waitmode, int has_vsync, int has_display,
		int wait_was_probed, unsigned attributes)
{
	int i;
	memset (video, 0, sizeof(*video));
	for (i = 0; i < BVSWAP_TEST_BYTES; i++)
		bench486_vesa_swap_memory[i] = (byte)(i * 29 + 7);
	for (i = 0; i < sizeof(bench486_vesa_swap_source); i++)
		bench486_vesa_swap_source[i] = (byte)(i * 13 + 5);
	memset (&bench486_vesa_swap_info, 0, sizeof(bench486_vesa_swap_info));
	bench486_vesa_swap_info.attributes = attributes;
	memset (&bench486_vesa_swap_mode, 0, sizeof(bench486_vesa_swap_mode));
	bench486_vesa_swap_mode.pextradata = &bench486_vesa_swap_info;
	video->buffer = pages == 1 ? bench486_vesa_swap_source :
		bench486_vesa_swap_memory + 16 + currentpage * pagesize;
	video->conbuffer = video->buffer;
	video->direct = bench486_vesa_swap_memory + 16;
	video->rowbytes = 320;
	video->width = 320;
	video->height = 200;
	video->numpages = pages;
	VID_membase = bench486_vesa_swap_memory + 16;
	VID_currentpage = currentpage;
	VID_displayedpage = 0;
	VID_pagesize = pagesize;
	VGA_pagebase = VID_membase + currentpage * pagesize;
	VGA_rowbytes = pagesize == 65536 ? 328 : 320;
	vid_wait.value = waitmode;
	vsync_exists = has_vsync;
	de_exists = has_display;
	wait_probed = wait_was_probed;
	bench486_vesa_swap_probe_vsync = 1;
	bench486_vesa_swap_probe_display = 1;
	Bench486VesaSwapResetEvents ();
}

static int Bench486VesaSwapCheck (int pages, int currentpage,
		int pagesize, int waitmode, int has_vsync, int has_display,
		int wait_was_probed, unsigned attributes, int expected_event_count,
		const int *expected_events, int expected_x, int expected_y,
		int expected_flags, int expect_probe, int expect_vsync,
		int expect_display)
{
	viddef_t c_before, asm_before;
	byte *c_pagebase;
	int c_currentpage, c_displayedpage, c_vsync, c_display, c_probed;
	int c_events[BVSWAP_EVENT_CAPACITY], c_event_count;
	int c_x, c_y, c_flags, i, failures = 0;
	Bench486VesaSwapInit (&bench486_vesa_swap_c_vid, pages, currentpage,
		pagesize, waitmode, has_vsync, has_display, wait_was_probed,
		attributes);
	memcpy (&bench486_vesa_swap_asm_vid, &bench486_vesa_swap_c_vid,
		sizeof(bench486_vesa_swap_asm_vid));
	bench486_vesa_swap_rects[0].x = 3;
	bench486_vesa_swap_rects[0].y = 4;
	bench486_vesa_swap_rects[0].width = 7;
	bench486_vesa_swap_rects[0].height = 2;
	bench486_vesa_swap_rects[0].pnext = &bench486_vesa_swap_rects[1];
	bench486_vesa_swap_rects[1].x = 319;
	bench486_vesa_swap_rects[1].y = 0;
	bench486_vesa_swap_rects[1].width = 2;
	bench486_vesa_swap_rects[1].height = 1;
	bench486_vesa_swap_rects[1].pnext = NULL;
	memcpy (&c_before, &bench486_vesa_swap_c_vid, sizeof(c_before));
	bench486_vesa_swap_fixture_active = true;
	VID_ExtraSwapBuffers_C (&bench486_vesa_swap_c_vid,
		&bench486_vesa_swap_mode, bench486_vesa_swap_rects);
	bench486_vesa_swap_fixture_active = false;
	memcpy (bench486_vesa_swap_c_memory, bench486_vesa_swap_memory,
		sizeof(bench486_vesa_swap_c_memory));
	c_pagebase = VGA_pagebase;
	c_currentpage = VID_currentpage;
	c_displayedpage = VID_displayedpage;
	c_vsync = vsync_exists;
	c_display = de_exists;
	c_probed = wait_probed;
	c_event_count = bench486_vesa_swap_event_count;
	memcpy (c_events, bench486_vesa_swap_events, sizeof(c_events));
	c_x = bench486_vesa_swap_start_x;
	c_y = bench486_vesa_swap_start_y;
	c_flags = bench486_vesa_swap_start_flags;

	Bench486VesaSwapInit (&bench486_vesa_swap_asm_vid, pages, currentpage,
		pagesize, waitmode, has_vsync, has_display, wait_was_probed,
		attributes);
	memcpy (&asm_before, &bench486_vesa_swap_asm_vid, sizeof(asm_before));
	bench486_vesa_swap_fixture_active = true;
	VID_ExtraSwapBuffers_ASM (&bench486_vesa_swap_asm_vid,
		&bench486_vesa_swap_mode, bench486_vesa_swap_rects);
	bench486_vesa_swap_fixture_active = false;

	if (!Bench486VesaSwapBytesEqual (&c_before, &asm_before, sizeof(c_before)) ||
		!Bench486VesaSwapBytesEqual (&bench486_vesa_swap_c_vid,
			&bench486_vesa_swap_asm_vid, sizeof(bench486_vesa_swap_c_vid)) ||
		!Bench486VesaSwapBytesEqual (bench486_vesa_swap_c_memory,
			bench486_vesa_swap_memory, sizeof(bench486_vesa_swap_memory)) ||
		c_pagebase != VGA_pagebase || c_currentpage != VID_currentpage ||
		c_displayedpage != VID_displayedpage || c_vsync != vsync_exists ||
		c_display != de_exists || c_probed != wait_probed ||
		c_event_count != bench486_vesa_swap_event_count ||
		!Bench486VesaSwapBytesEqual (c_events, bench486_vesa_swap_events,
			sizeof(c_events)) ||
		c_x != bench486_vesa_swap_start_x || c_y != bench486_vesa_swap_start_y ||
		c_flags != bench486_vesa_swap_start_flags)
		failures |= 1;
	if (bench486_vesa_swap_event_count != expected_event_count ||
		!Bench486VesaSwapBytesEqual (bench486_vesa_swap_events, expected_events,
			expected_event_count * sizeof(expected_events[0])) ||
		bench486_vesa_swap_start_x != expected_x ||
		bench486_vesa_swap_start_y != expected_y ||
		bench486_vesa_swap_start_flags != expected_flags ||
		vsync_exists != expect_vsync || de_exists != expect_display ||
		wait_probed != (wait_was_probed || expect_probe))
		failures |= 2;
	if (pages > 1)
	{
		int next = currentpage + 1;
		if (next >= pages) next = 0;
		if (VID_currentpage != next || VID_displayedpage != currentpage ||
			VGA_pagebase != VID_membase + next * pagesize ||
			bench486_vesa_swap_asm_vid.direct != VID_membase + currentpage * pagesize ||
			bench486_vesa_swap_asm_vid.buffer != VGA_pagebase ||
			bench486_vesa_swap_asm_vid.conbuffer != VGA_pagebase)
			failures |= 4;
	}
	else if (bench486_vesa_swap_memory[16 + 4 * VGA_rowbytes + 3] !=
		bench486_vesa_swap_source[4 * 320 + 3] ||
		bench486_vesa_swap_memory[16 + 4 * VGA_rowbytes + 10] !=
		(byte)((16 + 4 * VGA_rowbytes + 10) * 29 + 7))
		failures |= 8;
	bench486_vesa_swap_failures |= failures;
	return failures;
}

int Bench486VesaSwapBuffersCases (void)
{
	static const int display_wait_events[] = { 1, 4 };
	static const int flip_events[] = { 4 };
	static const int vsync_probe_events[] = { 3, 2 };
	static const int display_probe_events[] = { 3, 1 };
	int failures = 0;
	bench486_vesa_swap_saved_membase = VID_membase;
	bench486_vesa_swap_saved_pagebase = VGA_pagebase;
	bench486_vesa_swap_saved_currentpage = VID_currentpage;
	bench486_vesa_swap_saved_displayedpage = VID_displayedpage;
	bench486_vesa_swap_saved_pagesize = VID_pagesize;
	bench486_vesa_swap_saved_rowbytes = VGA_rowbytes;
	bench486_vesa_swap_saved_wait = vid_wait.value;
	bench486_vesa_swap_saved_vsync = vsync_exists;
	bench486_vesa_swap_saved_display = de_exists;
	bench486_vesa_swap_saved_probed = wait_probed;
	bench486_vesa_swap_failures = 0;
	failures |= Bench486VesaSwapCheck (3, 2, 64000,
		VID_WAIT_DISPLAY_ENABLE, 0, 1, 1, 0, 2, display_wait_events,
		0, 400, 0, 0, 0, 1);
	failures |= Bench486VesaSwapCheck (2, 1, 65536,
		VID_WAIT_VSYNC, 1, 0, 1, 0, 1, flip_events,
		65536 % 328, 65536 / 328, 0x80, 0, 1, 0);
	failures |= Bench486VesaSwapCheck (1, 0, 64000,
		VID_WAIT_VSYNC, 0, 0, 0, 0, 2, vsync_probe_events,
		-1, -1, -1, 1, 1, 1);
	failures |= Bench486VesaSwapCheck (1, 0, 64000,
		VID_WAIT_DISPLAY_ENABLE, 0, 0, 0, 0, 2, display_probe_events,
		-1, -1, -1, 1, 1, 1);
	failures |= Bench486VesaSwapCheck (1, 0, 64000,
		VID_WAIT_DISPLAY_ENABLE, 0, 1, 0, 0x20, 1,
		display_probe_events + 1, -1, -1, -1, 0, 0, 1);
	VID_membase = bench486_vesa_swap_saved_membase;
	VGA_pagebase = bench486_vesa_swap_saved_pagebase;
	VID_currentpage = bench486_vesa_swap_saved_currentpage;
	VID_displayedpage = bench486_vesa_swap_saved_displayedpage;
	VID_pagesize = bench486_vesa_swap_saved_pagesize;
	VGA_rowbytes = bench486_vesa_swap_saved_rowbytes;
	vid_wait.value = bench486_vesa_swap_saved_wait;
	vsync_exists = bench486_vesa_swap_saved_vsync;
	de_exists = bench486_vesa_swap_saved_display;
	wait_probed = bench486_vesa_swap_saved_probed;
	bench486_vesa_swap_fixture_active = false;
	return failures | bench486_vesa_swap_failures;
}

#endif
