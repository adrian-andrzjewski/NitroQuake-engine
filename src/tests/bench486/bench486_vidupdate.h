/* Direct C/assembly parity for the VID_Update state machine. */
#if defined(BENCH486) && defined(ASM486_VID_UPDATE_FIXTURE)
#ifndef BENCH486_VIDUPDATE_H
#define BENCH486_VIDUPDATE_H

#define BVU_EVENT_SWAP_BUFFERS 1
#define BVU_EVENT_SET_MODE 2
#define BVU_EVENT_SET_CVAR 3
#define BVU_EVENT_DEFAULT_MODE 4
#define BVU_EVENT_NO_VESA 5
#define BVU_EVENT_CAPACITY 12
#define BVU_CALL_CAPACITY 4
#define BVU_CASE_COUNT 20

extern void Bench486VidUpdateReportCase (const char *name,
		unsigned differences, unsigned c_expected, unsigned asm_expected);

typedef struct bench486_vid_update_input_s
{
	int parameter_mask;		/* bit 0: -stdvid, bit 1: +vid_mode */
	int host_frames;
	int first_update;
	int no_mode_check;
	int startup_mode_requested;
	float mode_value;
	float default_mode_value;
	int mode_number;
	int real_mode;
	int mode_count;
	int testing_mode;
	double now;
	double test_end;
	int default_mode_result;
	int rect_count;
} bench486_vid_update_input_t;

typedef struct bench486_vid_update_expected_s
{
	const int *events;
	int event_count;
	int set_mode_calls;
	int set_mode_argument;
	int set_cvar_calls;
	int default_mode_calls;
	int no_vesa_calls;
	int first_update;
	int startup_mode_requested;
	int testing_mode;
	int mode_number;
	int real_mode;
	float mode_value;
	float default_mode_value;
	int rect_count;
	unsigned long rect_pixels;
} bench486_vid_update_expected_t;

typedef struct bench486_vid_update_case_s
{
	const char *name;
	bench486_vid_update_input_t input;
	bench486_vid_update_expected_t expected;
} bench486_vid_update_case_t;

typedef struct bench486_vid_update_record_s
{
	int events[BVU_EVENT_CAPACITY];
	int event_count;
	int set_mode_calls;
	int set_mode_arguments[BVU_CALL_CAPACITY];
	int palette_matches[BVU_CALL_CAPACITY];
	int set_cvar_calls;
	char set_cvar_names[BVU_CALL_CAPACITY][32];
	float set_cvar_values[BVU_CALL_CAPACITY];
	int default_mode_calls;
	int no_vesa_calls;
	int no_vesa_text_matches;
	int swap_calls;
	int swap_video_matches;
	int swap_mode_matches;
	int swap_rects_match;
	int swap_rect_count;
	unsigned long swap_rect_pixels;
	int callback_overflow;
} bench486_vid_update_record_t;

typedef struct bench486_vid_update_snapshot_s
{
	viddef_t video;
	vrect_t rects[2];
	bench486_vid_update_record_t record;
	int first_update;
	int startup_mode_requested;
	int no_mode_check;
	int testing_mode;
	int mode_number;
	int real_mode;
	float mode_value;
	float default_mode_value;
	char mode_string[32];
	char default_mode_string[32];
} bench486_vid_update_snapshot_t;

static const int bench486_vid_update_events_swap[] = {
	BVU_EVENT_SWAP_BUFFERS
};
static const int bench486_vid_update_events_switch[] = {
	BVU_EVENT_SWAP_BUFFERS, BVU_EVENT_SET_MODE, BVU_EVENT_SET_CVAR
};
static const int bench486_vid_update_events_start_switch[] = {
	BVU_EVENT_SET_CVAR, BVU_EVENT_SWAP_BUFFERS,
	BVU_EVENT_SET_MODE, BVU_EVENT_SET_CVAR
};
static const int bench486_vid_update_events_default_switch[] = {
	BVU_EVENT_DEFAULT_MODE, BVU_EVENT_SET_CVAR,
	BVU_EVENT_SWAP_BUFFERS, BVU_EVENT_SET_MODE, BVU_EVENT_SET_CVAR
};
static const int bench486_vid_update_events_default_message_switch[] = {
	BVU_EVENT_DEFAULT_MODE, BVU_EVENT_SET_CVAR, BVU_EVENT_NO_VESA,
	BVU_EVENT_SWAP_BUFFERS, BVU_EVENT_SET_MODE, BVU_EVENT_SET_CVAR
};
static const int bench486_vid_update_events_invalid_default[] = {
	BVU_EVENT_SET_CVAR, BVU_EVENT_DEFAULT_MODE, BVU_EVENT_SET_CVAR,
	BVU_EVENT_NO_VESA, BVU_EVENT_SWAP_BUFFERS, BVU_EVENT_SET_MODE,
	BVU_EVENT_SET_CVAR
};
static const int bench486_vid_update_events_testing[] = {
	BVU_EVENT_SWAP_BUFFERS, BVU_EVENT_SET_MODE
};

#define BVU_IN(pm, hf, fu, nm, sr, mv, dv, mn, rm, mc, tm, now, end, dm, rc) \
	{ pm, hf, fu, nm, sr, mv, dv, mn, rm, mc, tm, now, end, dm, rc }
#define BVU_OUT(ev, evn, sm, sma, sc, dc, nv, fu, sr, tm, mn, rm, mv, dv, rc, px) \
	{ ev, evn, sm, sma, sc, dc, nv, fu, sr, tm, mn, rm, mv, dv, rc, px }

static const bench486_vid_update_case_t bench486_vid_update_cases[BVU_CASE_COUNT] = {
	{ "ordinary frame",
		BVU_IN(0, 1, 0, 0, 0, 2, 0, 2, 2, 8, 0, 1.0, 2.0, 6, 2),
		BVU_OUT(bench486_vid_update_events_swap, 1, 0, 0, 0, 0, 0,
			0, 0, 0, 2, 2, 2, 0, 2, 70) },
	{ "startup waits for a host frame",
		BVU_IN(0, 0, 1, 0, 0, 2, 0, 2, 2, 8, 0, 1.0, 2.0, 6, 2),
		BVU_OUT(bench486_vid_update_events_swap, 1, 0, 0, 0, 0, 0,
			1, 0, 0, 2, 2, 2, 0, 2, 70) },
	{ "mode checking disabled",
		BVU_IN(0, 1, 1, 1, 0, 2, 0, 2, 2, 8, 0, 1.0, 2.0, 6, 2),
		BVU_OUT(bench486_vid_update_events_swap, 1, 0, 0, 0, 0, 0,
			1, 0, 0, 2, 2, 2, 0, 2, 70) },
	{ "standard VGA startup",
		BVU_IN(1, 1, 1, 0, 0, 3, 0, 3, 3, 8, 0, 1.0, 2.0, 6, 2),
		BVU_OUT(bench486_vid_update_events_start_switch, 4, 1, 0, 2, 0, 0,
			0, 0, 0, 0, 0, 0, 0, 2, 70) },
	{ "saved default startup",
		BVU_IN(0, 1, 1, 0, 0, 0, 4, 0, 0, 8, 0, 1.0, 2.0, 6, 2),
		BVU_OUT(bench486_vid_update_events_start_switch, 4, 1, 4, 2, 0, 0,
			0, 0, 0, 4, 4, 4, 4, 2, 70) },
	{ "detected default startup",
		BVU_IN(0, 1, 1, 0, 0, 0, 0, 0, 0, 8, 0, 1.0, 2.0, 5, 2),
		BVU_OUT(bench486_vid_update_events_default_switch, 5, 1, 5, 2, 1, 0,
			0, 0, 0, 5, 5, 5, 0, 2, 70) },
	{ "VGA fallback message",
		BVU_IN(0, 1, 1, 0, 0, 2, 0, 2, 2, 8, 0, 1.0, 2.0, 0, 2),
		BVU_OUT(bench486_vid_update_events_default_message_switch, 6,
			1, 0, 2, 1, 1, 0, 0, 0, 0, 0, 0, 0, 2, 70) },
	{ "+vid_mode suppresses auto selection",
		BVU_IN(2, 1, 1, 0, 0, 2, 4, 2, 2, 8, 0, 1.0, 2.0, 6, 2),
		BVU_OUT(bench486_vid_update_events_swap, 1, 0, 0, 0, 0, 0,
			0, 0, 0, 2, 2, 2, 4, 2, 70) },
	{ "explicit startup mode suppresses auto selection",
		BVU_IN(0, 1, 1, 0, 1, 2, 4, 2, 2, 8, 0, 1.0, 2.0, 6, 2),
		BVU_OUT(bench486_vid_update_events_swap, 1, 0, 0, 0, 0, 0,
			0, 1, 0, 2, 2, 2, 4, 2, 70) },
	{ "invalid negative saved default",
		BVU_IN(0, 1, 1, 0, 0, 2, -1, 2, 2, 8, 0, 1.0, 2.0, 0, 2),
		BVU_OUT(bench486_vid_update_events_invalid_default, 7,
			1, 0, 3, 1, 1, 0, 0, 0, 0, 0, 0, 0, 2, 70) },
	{ "invalid upper saved default",
		BVU_IN(0, 1, 1, 0, 0, 2, 8, 2, 2, 8, 0, 1.0, 2.0, 0, 2),
		BVU_OUT(bench486_vid_update_events_invalid_default, 7,
			1, 0, 3, 1, 1, 0, 0, 0, 0, 0, 0, 0, 2, 70) },
	{ "testing mode before deadline",
		BVU_IN(0, 1, 0, 0, 0, 7, 0, 2, 2, 8, 1, 4.0, 5.0, 6, 2),
		BVU_OUT(bench486_vid_update_events_swap, 1, 0, 0, 0, 0, 0,
			0, 0, 1, 2, 2, 7, 0, 2, 70) },
	{ "testing mode expires at deadline",
		BVU_IN(0, 1, 0, 0, 0, 7, 0, 2, 2, 8, 1, 5.0, 5.0, 6, 2),
		BVU_OUT(bench486_vid_update_events_testing, 2, 1, 2, 0, 0, 0,
			0, 0, 0, 2, 2, 7, 0, 2, 70) },
	{ "fractional mode during deferred startup",
		BVU_IN(0, 0, 1, 0, 0, 3.75, 0, 2, 2, 8, 0, 1.0, 2.0, 6, 1),
		BVU_OUT(bench486_vid_update_events_switch, 3, 1, 3, 1, 0, 0,
			1, 1, 0, 3, 3, 3, 0, 1, 14) },
	{ "negative fractional mode truncates toward zero",
		BVU_IN(0, 1, 0, 0, 0, -1.75, 0, 2, 2, 8, 0, 1.0, 2.0, 6, 0),
		BVU_OUT(bench486_vid_update_events_switch, 3, 1, -1, 1, 0, 0,
			0, 0, 0, -1, -1, -1, 0, 0, 0) },
	{ "exact requested mode avoids a set",
		BVU_IN(0, 1, 0, 0, 0, 3, 0, 3, 3, 8, 0, 1.0, 2.0, 6, 1),
		BVU_OUT(bench486_vid_update_events_swap, 1, 0, 0, 0, 0, 0,
			0, 0, 0, 3, 3, 3, 0, 1, 14) },
	{ "no mode check suppresses a requested change",
		BVU_IN(0, 1, 0, 1, 0, 4, 0, 2, 2, 8, 0, 1.0, 2.0, 6, 0),
		BVU_OUT(bench486_vid_update_events_swap, 1, 0, 0, 0, 0, 0,
			0, 0, 0, 2, 2, 4, 0, 0, 0) },
	{ "-stdvid takes precedence over +vid_mode",
		BVU_IN(3, 1, 1, 0, 1, 3, 0, 3, 3, 8, 0, 1.0, 2.0, 6, 2),
		BVU_OUT(bench486_vid_update_events_start_switch, 4, 1, 0, 2, 0, 0,
			0, 1, 0, 0, 0, 0, 0, 2, 70) },
	{ "one rectangle and no rectangles",
		BVU_IN(0, 1, 0, 0, 0, 2, 0, 2, 2, 8, 0, 1.0, 2.0, 6, 1),
		BVU_OUT(bench486_vid_update_events_swap, 1, 0, 0, 0, 0, 0,
			0, 0, 0, 2, 2, 2, 0, 1, 14) },
	{ "empty rectangle list",
		BVU_IN(0, 1, 0, 0, 0, 2, 0, 2, 2, 8, 0, 1.0, 2.0, 6, 0),
		BVU_OUT(bench486_vid_update_events_swap, 1, 0, 0, 0, 0, 0,
			0, 0, 0, 2, 2, 2, 0, 0, 0) }
};

static vmode_t bench486_vid_update_mode;
static vrect_t bench486_vid_update_rects[2];
static byte bench486_vid_update_pixels[64];
static char *bench486_vid_update_argv[3];
static char bench486_vid_update_mode_strings[2][32];
static char bench486_vid_update_default_strings[2][32];
static int bench486_vid_update_default_result;
static int bench486_vid_update_expected_rect_count;
static bench486_vid_update_record_t bench486_vid_update_record;

static int Bench486VidUpdateRecordEvent (int event)
{
	if (bench486_vid_update_record.event_count >= BVU_EVENT_CAPACITY)
	{
		bench486_vid_update_record.callback_overflow = 1;
		return 0;
	}
	bench486_vid_update_record.events[
		bench486_vid_update_record.event_count++] = event;
	return 1;
}

int Bench486VidUpdateSetMode (int mode, unsigned char *palette)
{
	bench486_vid_update_record_t *record = &bench486_vid_update_record;
	int slot = record->set_mode_calls++;
	Bench486VidUpdateRecordEvent (BVU_EVENT_SET_MODE);
	if (slot >= BVU_CALL_CAPACITY)
	{
		record->callback_overflow = 1;
		return 0;
	}
	record->set_mode_arguments[slot] = mode;
	record->palette_matches[slot] = palette == vid_current_palette;
	vid_modenum = mode;
	return 1;
}

int Bench486VidUpdateDefaultMode (void)
{
	bench486_vid_update_record.default_mode_calls++;
	Bench486VidUpdateRecordEvent (BVU_EVENT_DEFAULT_MODE);
	return bench486_vid_update_default_result;
}

void Bench486VidUpdateSetValue (char *name, float value)
{
	bench486_vid_update_record_t *record = &bench486_vid_update_record;
	int slot = record->set_cvar_calls++;
	cvar_t *variable;
	char *string;
	Bench486VidUpdateRecordEvent (BVU_EVENT_SET_CVAR);
	if (slot >= BVU_CALL_CAPACITY)
	{
		record->callback_overflow = 1;
		return;
	}
	strncpy (record->set_cvar_names[slot], name,
		sizeof (record->set_cvar_names[slot]) - 1);
	record->set_cvar_values[slot] = value;
	if (!Q_strcmp (name, "vid_mode"))
	{
		variable = &vid_mode;
		string = bench486_vid_update_mode_strings[0];
	}
	else if (!Q_strcmp (name, "_vid_default_mode"))
	{
		variable = &_vid_default_mode;
		string = bench486_vid_update_default_strings[0];
	}
	else
	{
		record->callback_overflow = 1;
		return;
	}
	sprintf (string, "%f", value);
	variable->string = string;
	variable->value = Q_atof (string);
}

void Bench486VidUpdateNoVesaMessage (char *text)
{
	static const char expected[] =
		"Video: no usable VESA 320x200x8 mode; using VGA mode 13h\n";
	bench486_vid_update_record.no_vesa_calls++;
	bench486_vid_update_record.no_vesa_text_matches =
		!Q_strcmp (text, (char *)expected);
	Bench486VidUpdateRecordEvent (BVU_EVENT_NO_VESA);
}

static void Bench486VidUpdateSwapBuffers (viddef_t *video,
		vmode_t *mode, vrect_t *rects)
{
	bench486_vid_update_record_t *record = &bench486_vid_update_record;
	vrect_t *rect;
	int count = 0;
	unsigned long pixels = 0;
	Bench486VidUpdateRecordEvent (BVU_EVENT_SWAP_BUFFERS);
	record->swap_calls++;
	record->swap_video_matches = video == &vid;
	record->swap_mode_matches = mode == &bench486_vid_update_mode;
	record->swap_rects_match = rects == (bench486_vid_update_expected_rect_count
		? bench486_vid_update_rects : NULL);
	for (rect = rects; rect && count < 4; rect = rect->pnext)
	{
		count++;
		pixels += (unsigned long)rect->width *
			(unsigned long)rect->height;
	}
	if (rect)
		record->callback_overflow = 1;
	record->swap_rect_count = count;
	record->swap_rect_pixels = pixels;
}

static void Bench486VidUpdateSetup (
		const bench486_vid_update_case_t *test, int lane)
{
	int argc = 1;
	memset (&bench486_vid_update_record, 0,
		sizeof (bench486_vid_update_record));
	bench486_vid_update_default_result = test->input.default_mode_result;
	bench486_vid_update_expected_rect_count = test->input.rect_count;
	bench486_vid_update_argv[0] = "quake";
	bench486_vid_update_argv[1] = NULL;
	bench486_vid_update_argv[2] = NULL;
	if (test->input.parameter_mask & 1)
		bench486_vid_update_argv[argc++] = "-stdvid";
	if (test->input.parameter_mask & 2)
		bench486_vid_update_argv[argc++] = "+vid_mode";
	com_argc = argc;
	com_argv = bench486_vid_update_argv;
	host_framecount = test->input.host_frames;
	vid_firstupdate = test->input.first_update;
	vid_nomodecheck = test->input.no_mode_check;
	vid_startup_mode_requested = test->input.startup_mode_requested;
	vid_testingmode = test->input.testing_mode;
	vid_testendtime = test->input.test_end;
	vid_modenum = test->input.mode_number;
	vid_realmode = test->input.real_mode;
	numvidmodes = test->input.mode_count;
	realtime = test->input.now;
	vid_mode.value = test->input.mode_value;
	_vid_default_mode.value = test->input.default_mode_value;
	sprintf (bench486_vid_update_mode_strings[lane], "%f",
		test->input.mode_value);
	sprintf (bench486_vid_update_default_strings[lane], "%f",
		test->input.default_mode_value);
	vid_mode.string = bench486_vid_update_mode_strings[lane];
	_vid_default_mode.string = bench486_vid_update_default_strings[lane];
	memset (&vid, 0, sizeof (vid));
	vid.width = 320;
	vid.height = 200;
	vid.rowbytes = 320;
	vid.aspect = 1.0;
	vid.buffer = bench486_vid_update_pixels;
	vid.conbuffer = bench486_vid_update_pixels;
	vid.direct = bench486_vid_update_pixels;
	memset (&bench486_vid_update_mode, 0,
		sizeof (bench486_vid_update_mode));
	bench486_vid_update_mode.swapbuffers = Bench486VidUpdateSwapBuffers;
	pcurrentmode = &bench486_vid_update_mode;
	memset (bench486_vid_update_rects, 0,
		sizeof (bench486_vid_update_rects));
	bench486_vid_update_rects[0].x = 3;
	bench486_vid_update_rects[0].y = 4;
	bench486_vid_update_rects[0].width = 7;
	bench486_vid_update_rects[0].height = 2;
	bench486_vid_update_rects[0].pnext = test->input.rect_count > 1
		? &bench486_vid_update_rects[1] : NULL;
	bench486_vid_update_rects[1].x = 11;
	bench486_vid_update_rects[1].y = 13;
	bench486_vid_update_rects[1].width = 7;
	bench486_vid_update_rects[1].height = 8;
#ifdef PROFILE486
	bench486_profile_frame_active = false;
#endif
}

static void Bench486VidUpdateCapture (
		bench486_vid_update_snapshot_t *snapshot)
{
	memset (snapshot, 0, sizeof (*snapshot));
	snapshot->video = vid;
	memcpy (snapshot->rects, bench486_vid_update_rects,
		sizeof (snapshot->rects));
	snapshot->record = bench486_vid_update_record;
	snapshot->first_update = vid_firstupdate;
	snapshot->startup_mode_requested = vid_startup_mode_requested;
	snapshot->no_mode_check = vid_nomodecheck;
	snapshot->testing_mode = vid_testingmode;
	snapshot->mode_number = vid_modenum;
	snapshot->real_mode = vid_realmode;
	snapshot->mode_value = vid_mode.value;
	snapshot->default_mode_value = _vid_default_mode.value;
	if (vid_mode.string)
	{
		strncpy (snapshot->mode_string, vid_mode.string,
			sizeof (snapshot->mode_string) - 1);
	}
	if (_vid_default_mode.string)
	{
		strncpy (snapshot->default_mode_string, _vid_default_mode.string,
			sizeof (snapshot->default_mode_string) - 1);
	}
}

static void Bench486VidUpdateRun (	const bench486_vid_update_case_t *test,
		int use_asm, bench486_vid_update_snapshot_t *snapshot)
{
	vrect_t *rects = test->input.rect_count
		? bench486_vid_update_rects : NULL;
	if (use_asm)
		VID_Update (rects);
	else
		VID_Update_C (rects);
	Bench486VidUpdateCapture (snapshot);
}

static int Bench486VidUpdateSnapshotEqual (
		const bench486_vid_update_snapshot_t *left,
		const bench486_vid_update_snapshot_t *right)
{
	const byte *a = (const byte *)left;
	const byte *b = (const byte *)right;
	unsigned size = sizeof (*left);
	while (size--)
		if (*a++ != *b++)
			return 0;
	return 1;
}

static int Bench486VidUpdateBytesEqual (const byte *left,
		const byte *right, unsigned size)
{
	while (size--)
		if (*left++ != *right++)
			return 0;
	return 1;
}

static unsigned Bench486VidUpdateDifference (
		const bench486_vid_update_snapshot_t *left,
		const bench486_vid_update_snapshot_t *right)
{
	unsigned differences = 0;
	if (!Bench486VidUpdateBytesEqual ((const byte *)&left->video,
			(const byte *)&right->video, sizeof (left->video)))
		differences |= 1;
	if (!Bench486VidUpdateBytesEqual ((const byte *)left->rects,
			(const byte *)right->rects, sizeof (left->rects)))
		differences |= 2;
	if (!Bench486VidUpdateBytesEqual ((const byte *)&left->record,
			(const byte *)&right->record, sizeof (left->record)))
		differences |= 4;
	if (left->first_update != right->first_update ||
		left->startup_mode_requested != right->startup_mode_requested ||
		left->no_mode_check != right->no_mode_check ||
		left->testing_mode != right->testing_mode ||
		left->mode_number != right->mode_number ||
		left->real_mode != right->real_mode)
		differences |= 8;
	if (left->mode_value != right->mode_value ||
		left->default_mode_value != right->default_mode_value)
		differences |= 16;
	if (!Bench486VidUpdateBytesEqual ((const byte *)left->mode_string,
			(const byte *)right->mode_string, sizeof (left->mode_string)) ||
		!Bench486VidUpdateBytesEqual ((const byte *)left->default_mode_string,
			(const byte *)right->default_mode_string,
			sizeof (left->default_mode_string)))
		differences |= 32;
	return differences;
}

static unsigned Bench486VidUpdateExpectedDifference (
		const bench486_vid_update_case_t *test,
		const bench486_vid_update_snapshot_t *snapshot)
{
	const bench486_vid_update_expected_t *expected = &test->expected;
	const bench486_vid_update_record_t *record = &snapshot->record;
	unsigned differences = 0;
	int i;
	if (record->event_count != expected->event_count)
		differences |= 1;
	if (record->swap_calls != 1 || !record->swap_video_matches ||
		!record->swap_mode_matches || !record->swap_rects_match)
		differences |= 2;
	if (record->swap_rect_count != expected->rect_count)
		differences |= 4;
	if (record->swap_rect_pixels != expected->rect_pixels)
		differences |= 8;
	if (record->set_mode_calls != expected->set_mode_calls)
		differences |= 16;
	if (expected->set_mode_calls &&
		(record->set_mode_arguments[0] != expected->set_mode_argument ||
		 !record->palette_matches[0]))
		differences |= 32;
	if (record->set_cvar_calls != expected->set_cvar_calls)
		differences |= 64;
	if (record->default_mode_calls != expected->default_mode_calls)
		differences |= 128;
	if (record->no_vesa_calls != expected->no_vesa_calls ||
		record->no_vesa_calls != record->no_vesa_text_matches)
		differences |= 256;
	if (record->callback_overflow)
		differences |= 512;
	if (snapshot->first_update != expected->first_update ||
		snapshot->startup_mode_requested !=
			expected->startup_mode_requested ||
		snapshot->testing_mode != expected->testing_mode)
		differences |= 1024;
	if (snapshot->mode_number != expected->mode_number ||
		snapshot->real_mode != expected->real_mode)
		differences |= 2048;
	if (snapshot->mode_value != expected->mode_value ||
		snapshot->default_mode_value != expected->default_mode_value)
		differences |= 4096;
	for (i = 0; i < expected->event_count; i++)
		if (record->events[i] != expected->events[i])
			differences |= 8192;
	return differences;
}

int Bench486VidUpdateCases (void)
{
	bench486_vid_update_snapshot_t c, a;
	viddef_t saved_video;
	vmode_t *saved_mode;
	cvar_t saved_mode_cvar, saved_default_cvar;
	char **saved_argv;
	int saved_argc, saved_host_frames, saved_first_update;
	int saved_no_mode_check, saved_startup_requested, saved_testing_mode;
	int saved_mode_number, saved_real_mode, saved_mode_count;
	double saved_realtime, saved_test_end;
#ifdef PROFILE486
	int saved_profile_active;
#endif
	int failures = 0;
	int expected_failures = 0;
	int i;
	saved_video = vid;
	saved_mode = pcurrentmode;
	saved_mode_cvar = vid_mode;
	saved_default_cvar = _vid_default_mode;
	saved_argv = com_argv;
	saved_argc = com_argc;
	saved_host_frames = host_framecount;
	saved_first_update = vid_firstupdate;
	saved_no_mode_check = vid_nomodecheck;
	saved_startup_requested = vid_startup_mode_requested;
	saved_testing_mode = vid_testingmode;
	saved_mode_number = vid_modenum;
	saved_real_mode = vid_realmode;
	saved_mode_count = numvidmodes;
	saved_realtime = realtime;
	saved_test_end = vid_testendtime;
#ifdef PROFILE486
	saved_profile_active = bench486_profile_frame_active;
	bench486_profile_frame_active = false;
#endif
	for (i = 0; i < BVU_CASE_COUNT; i++)
	{
		const bench486_vid_update_case_t *test =
			&bench486_vid_update_cases[i];
		unsigned differences, c_expected, asm_expected;
		Bench486VidUpdateSetup (test, 0);
		Bench486VidUpdateRun (test, 0, &c);
		Bench486VidUpdateSetup (test, 1);
		Bench486VidUpdateRun (test, 1, &a);
		differences = Bench486VidUpdateDifference (&c, &a);
		c_expected = Bench486VidUpdateExpectedDifference (test, &c);
		asm_expected = Bench486VidUpdateExpectedDifference (test, &a);
		if (!Bench486VidUpdateSnapshotEqual (&c, &a))
			failures |= 1 << i;
		if (c_expected || asm_expected)
		expected_failures = 1;
		if (differences || c_expected || asm_expected)
			Bench486VidUpdateReportCase (test->name, differences,
				c_expected, asm_expected);
	}
	if (expected_failures)
		failures |= 1 << 30;
	vid = saved_video;
	pcurrentmode = saved_mode;
	vid_mode = saved_mode_cvar;
	_vid_default_mode = saved_default_cvar;
	com_argv = saved_argv;
	com_argc = saved_argc;
	host_framecount = saved_host_frames;
	vid_firstupdate = saved_first_update;
	vid_nomodecheck = saved_no_mode_check;
	vid_startup_mode_requested = saved_startup_requested;
	vid_testingmode = saved_testing_mode;
	vid_modenum = saved_mode_number;
	vid_realmode = saved_real_mode;
	numvidmodes = saved_mode_count;
	realtime = saved_realtime;
	vid_testendtime = saved_test_end;
#ifdef PROFILE486
	bench486_profile_frame_active = saved_profile_active;
#endif
	return failures;
}

#undef BVU_IN
#undef BVU_OUT

#endif /* BENCH486_VIDUPDATE_H */
#endif /* BENCH486 && ASM486_VID_UPDATE_FIXTURE */
