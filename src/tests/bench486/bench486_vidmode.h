/* Direct C/assembly parity for DOS video mode lookup and transitions. */
#if defined(BENCH486) && defined(ASM486_VID_UPDATE_FIXTURE)
#ifndef BENCH486_VIDMODE_H
#define BENCH486_VIDMODE_H

#include <stdarg.h>
#include <string.h>

#define BVM_EVENT_SET_CVAR 1
#define BVM_EVENT_PRINTF 2
#define BVM_EVENT_ERROR 3
#define BVM_EVENT_RELEASE_EXTRA 4
#define BVM_EVENT_SET_MODE 5
#define BVM_EVENT_SET_PALETTE 6
#define BVM_EVENT_PALETTE_OK 7
#define BVM_EVENT_SHUTDOWN_INT86 8
#define BVM_EVENT_SHUTDOWN_EXTRA 9
#define BVM_EVENT_CAPACITY 40
#define BVM_MODE_COUNT 3

typedef struct bench486_vidmode_event_s
{
	int kind;
	int int_value;
	int mode_index;
	int video_matches;
	int palette_matches;
	int palette_is_current;
	unsigned reg_eax;
	unsigned width;
	unsigned height;
	unsigned rowbytes;
	float aspect;
	float float_value;
	char text[128];
} bench486_vidmode_event_t;

typedef struct bench486_vidmode_record_s
{
	bench486_vidmode_event_t events[BVM_EVENT_CAPACITY];
	int event_count;
	int overflow;
} bench486_vidmode_record_t;

typedef struct bench486_vidmode_case_s
{
	const char *name;
	int requested_mode;
	int current_mode;
	int initial_mode_number;
	int initial_screen_disabled;
	int expected_result;
	int expected_mode_number;
	int mode_result_count;
	int mode_results[4];
	int palette_result_count;
	int palette_results[4];
} bench486_vidmode_case_t;

typedef struct bench486_vidpalette_case_s
{
	const char *name;
	int use_shift_entry;
	int input_is_current_palette;
	int palette_result_count;
	int palette_results[4];
	int mode_result_count;
	int mode_results[4];
	int expected_mode_number;
	int expected_palette_calls;
	int expected_error_count;
} bench486_vidpalette_case_t;

typedef struct bench486_vidmode_snapshot_s
{
	int result;
	viddef_t video;
	byte palette[768];
	vmode_t *current_mode;
	int mode_number;
	int no_mode_check;
	int screen_disabled;
	int testing_mode;
	float mode_cvar_value;
	regs_t registers;
	bench486_vidmode_record_t record;
} bench486_vidmode_snapshot_t;

static vmode_t bench486_vidmode_modes[BVM_MODE_COUNT];
static byte bench486_vidmode_input_palette[768];
static int bench486_vidmode_mode_results[4];
static int bench486_vidmode_mode_result_count;
static int bench486_vidmode_mode_result_index;
static int bench486_vidmode_palette_results[4];
static int bench486_vidmode_palette_result_count;
static int bench486_vidmode_palette_result_index;
static bench486_vidmode_record_t bench486_vidmode_record;

static int Bench486VidModeBytesEqual (const void *left,
		const void *right, unsigned count)
{
	const unsigned char *left_bytes, *right_bytes;
	unsigned i;

	left_bytes = (const unsigned char *)left;
	right_bytes = (const unsigned char *)right;
	for (i = 0; i < count; i++)
		if (left_bytes[i] != right_bytes[i])
			return 0;
	return 1;
}

static int Bench486VidModeTextEqual (const char *left, const char *right)
{
	if (left == NULL || right == NULL)
		return left == right;
	while (*left && *left == *right)
	{
		left++;
		right++;
	}
	return *left == *right;
}

static bench486_vidmode_event_t *Bench486VidModeAppend (int kind)
{
	bench486_vidmode_event_t *event;

	if (bench486_vidmode_record.event_count >= BVM_EVENT_CAPACITY)
	{
		bench486_vidmode_record.overflow = 1;
		return NULL;
	}
	event = &bench486_vidmode_record.events[
			bench486_vidmode_record.event_count++];
	memset (event, 0, sizeof(*event));
	event->kind = kind;
	event->mode_index = -1;
	return event;
}

void Bench486VidModeSetValue (char *name, float value)
{
	bench486_vidmode_event_t *event;

	event = Bench486VidModeAppend (BVM_EVENT_SET_CVAR);
	if (event)
	{
		if (name)
			strncpy (event->text, name, sizeof(event->text) - 1);
		event->float_value = value;
	}
	if (name && Bench486VidModeTextEqual (name, "vid_mode"))
		vid_mode.value = value;
}

void Bench486VidModePrintf (char *format, ...)
{
	bench486_vidmode_event_t *event;
	va_list arguments;

	event = Bench486VidModeAppend (BVM_EVENT_PRINTF);
	if (!event)
		return;
	va_start (arguments, format);
	vsprintf (event->text, format, arguments);
	va_end (arguments);
}

void Bench486VidModeError (char *text)
{
	bench486_vidmode_event_t *event;

	event = Bench486VidModeAppend (BVM_EVENT_ERROR);
	if (event && text)
		strncpy (event->text, text, sizeof(event->text) - 1);
}

void Bench486VidModeReleaseExtra (void)
{
	Bench486VidModeAppend (BVM_EVENT_RELEASE_EXTRA);
}

int Bench486VidModePaletteOK (void)
{
	bench486_vidmode_event_t *event;
	int result;

	result = 1;
	if (bench486_vidmode_palette_result_index <
			bench486_vidmode_palette_result_count)
		result = bench486_vidmode_palette_results[
				bench486_vidmode_palette_result_index];
	bench486_vidmode_palette_result_index++;
	event = Bench486VidModeAppend (BVM_EVENT_PALETTE_OK);
	if (event)
		event->int_value = result;
	return result;
}

int Bench486VidShutdownInt86 (int vector)
{
	bench486_vidmode_event_t *event;

	event = Bench486VidModeAppend (BVM_EVENT_SHUTDOWN_INT86);
	if (event)
	{
		event->int_value = vector;
		event->reg_eax = regs.d.eax;
	}
	regs.d.eax = 0x4f138069;
	regs.x.flags = 0x55aa;
	return -1;
}

void Bench486VidShutdownExtra (void)
{
	Bench486VidModeAppend (BVM_EVENT_SHUTDOWN_EXTRA);
	vid_testingmode = 7;
}

static int Bench486VidModeIndex (vmode_t *mode)
{
	int i;

	for (i = 0; i < BVM_MODE_COUNT; i++)
		if (mode == &bench486_vidmode_modes[i])
			return i;
	return -1;
}

static int Bench486VidModeSetHardware (viddef_t *video, vmode_t *mode)
{
	bench486_vidmode_event_t *event;
	int result;

	result = 1;
	if (bench486_vidmode_mode_result_index <
			bench486_vidmode_mode_result_count)
		result = bench486_vidmode_mode_results[
				bench486_vidmode_mode_result_index];
	bench486_vidmode_mode_result_index++;
	event = Bench486VidModeAppend (BVM_EVENT_SET_MODE);
	if (event)
	{
		event->int_value = result;
		event->mode_index = Bench486VidModeIndex (mode);
		event->video_matches = video == &vid;
		event->width = video->width;
		event->height = video->height;
		event->rowbytes = video->rowbytes;
		event->aspect = video->aspect;
	}
	return result;
}

static void Bench486VidModeSetHardwarePalette (viddef_t *video,
		vmode_t *mode, unsigned char *palette)
{
	bench486_vidmode_event_t *event;

	event = Bench486VidModeAppend (BVM_EVENT_SET_PALETTE);
	if (event)
	{
		event->mode_index = Bench486VidModeIndex (mode);
		event->video_matches = video == &vid;
		event->palette_matches = palette == bench486_vidmode_input_palette;
		event->palette_is_current = palette == vid_current_palette;
	}
}

static void Bench486VidModeResetRecord (void)
{
	memset (&bench486_vidmode_record, 0, sizeof(bench486_vidmode_record));
	bench486_vidmode_mode_result_index = 0;
	bench486_vidmode_palette_result_index = 0;
}

static void Bench486VidModeInitModes (void)
{
	static char *names[BVM_MODE_COUNT] = {
		"VGA 320x200", "VESA 640x480", "VESA 800x600"
	};
	static char *headers[BVM_MODE_COUNT] = {
		"Standard VGA", "Linear VESA", "Banked VESA"
	};
	int i;

	memset (bench486_vidmode_modes, 0, sizeof(bench486_vidmode_modes));
	for (i = 0; i < BVM_MODE_COUNT; i++)
	{
		bench486_vidmode_modes[i].pnext = i + 1 < BVM_MODE_COUNT ?
				&bench486_vidmode_modes[i + 1] : NULL;
		bench486_vidmode_modes[i].name = names[i];
		bench486_vidmode_modes[i].header = headers[i];
		bench486_vidmode_modes[i].width = i == 0 ? 320 : 640 + (i - 1) * 160;
		bench486_vidmode_modes[i].height = i == 0 ? 200 : 480 + (i - 1) * 120;
		bench486_vidmode_modes[i].aspect = i == 0 ? 1.2f : 1.3333333f;
		bench486_vidmode_modes[i].rowbytes = bench486_vidmode_modes[i].width;
		bench486_vidmode_modes[i].numpages = i == 2 ? 2 : 1;
		bench486_vidmode_modes[i].setmode = Bench486VidModeSetHardware;
		bench486_vidmode_modes[i].setpalette =
				Bench486VidModeSetHardwarePalette;
	}
}

static void Bench486VidModeConfigure (const bench486_vidmode_case_t *test)
{
	int i;

	Bench486VidModeResetRecord ();
	Bench486VidModeInitModes ();
	pvidmodes = &bench486_vidmode_modes[0];
	numvidmodes = BVM_MODE_COUNT;
	pcurrentmode = test->current_mode < 0 ? NULL :
			&bench486_vidmode_modes[test->current_mode];
	vid_modenum = test->initial_mode_number;
	vid_mode.value = (float)test->initial_mode_number;
	vid_nomodecheck = false;
	scr_disabled_for_loading = test->initial_screen_disabled;
	memset (&vid, 0xa5, sizeof(vid));
	vid.rowbytes = 97;
	vid.width = 211;
	vid.height = 133;
	vid.aspect = 0.75f;
	vid.recalc_refdef = 0;
	vid.direct = (byte *)0x12340;
	for (i = 0; i < sizeof(bench486_vidmode_input_palette); i++)
	{
		bench486_vidmode_input_palette[i] = (byte)(i * 37 + 11);
		vid_current_palette[i] = (byte)(i ^ 0x5a);
	}
	memset (bench486_vidmode_mode_results, 0,
			sizeof(bench486_vidmode_mode_results));
	memset (bench486_vidmode_palette_results, 0,
			sizeof(bench486_vidmode_palette_results));
	for (i = 0; i < test->mode_result_count && i < 4; i++)
		bench486_vidmode_mode_results[i] = test->mode_results[i];
	for (i = 0; i < test->palette_result_count && i < 4; i++)
		bench486_vidmode_palette_results[i] = test->palette_results[i];
	bench486_vidmode_mode_result_count = test->mode_result_count;
	bench486_vidmode_palette_result_count = test->palette_result_count;
}

static void Bench486VidModeCapture (int result,
		bench486_vidmode_snapshot_t *snapshot)
{
	memset (snapshot, 0, sizeof(*snapshot));
	snapshot->result = result;
	snapshot->video = vid;
	memcpy (snapshot->palette, vid_current_palette,
			sizeof(snapshot->palette));
	snapshot->current_mode = pcurrentmode;
	snapshot->mode_number = vid_modenum;
	snapshot->no_mode_check = vid_nomodecheck;
	snapshot->screen_disabled = scr_disabled_for_loading;
	snapshot->testing_mode = vid_testingmode;
	snapshot->mode_cvar_value = vid_mode.value;
	memcpy (&snapshot->registers, &regs, sizeof(snapshot->registers));
	snapshot->record = bench486_vidmode_record;
}

static int Bench486VidModeRecordsEqual (	const bench486_vidmode_record_t *left,
		const bench486_vidmode_record_t *right)
{
	if (left->event_count != right->event_count ||
			left->overflow != right->overflow)
		return 0;
	return Bench486VidModeBytesEqual (left->events, right->events,
			left->event_count * sizeof(left->events[0]));
}

static int Bench486VidModeSnapshotsEqual (
		const bench486_vidmode_snapshot_t *left,
		const bench486_vidmode_snapshot_t *right)
{
	return left->result == right->result &&
			Bench486VidModeBytesEqual (&left->video, &right->video,
					sizeof(left->video)) &&
			Bench486VidModeBytesEqual (left->palette, right->palette,
					sizeof(left->palette)) &&
			left->current_mode == right->current_mode &&
			left->mode_number == right->mode_number &&
			left->no_mode_check == right->no_mode_check &&
			left->screen_disabled == right->screen_disabled &&
			left->testing_mode == right->testing_mode &&
			Bench486VidModeBytesEqual (&left->mode_cvar_value,
					&right->mode_cvar_value,
					sizeof(left->mode_cvar_value)) &&
			Bench486VidModeBytesEqual (&left->registers,
					&right->registers, sizeof(left->registers)) &&
			Bench486VidModeRecordsEqual (&left->record, &right->record);
}

static const bench486_vidmode_case_t bench486_vidmode_cases[] = {
	{ "already selected", 1, 1, 1, 0, 1, 1, 0, {0,0,0,0}, 0, {0,0,0,0} },
	{ "invalid mode preserves current", -1, 1, 1, 0, 0, 1, 0, {0,0,0,0}, 0, {0,0,0,0} },
	{ "requested mode succeeds", 1, 0, 0, 0, 1, 1, 1, {1,0,0,0}, 1, {1,0,0,0} },
	{ "mode set falls back to VGA", 1, 0, 0, 0, 0, 0, 2, {0,1,0,0}, 1, {1,0,0,0} },
	{ "palette failure falls back", 1, 0, 0, 0, 0, 0, 2, {1,1,0,0}, 2, {0,1,0,0} },
	{ "invalid startup chooses VGA", 99, -1, 0, 0, 0, 0, 1, {1,0,0,0}, 1, {1,0,0,0} },
	{ "screen suppression is restored", 2, 0, 0, 1, 1, 2, 1, {1,0,0,0}, 1, {1,0,0,0} },
	{ "VGA failure reaches error path", 0, 1, 1, 0, 1, 0, 2, {0,0,0,0}, 0, {0,0,0,0} }
};

static const bench486_vidpalette_case_t bench486_vidpalette_cases[] = {
	{ "same palette pointer", 0, 1, 1, {1,0,0,0}, 0, {0,0,0,0}, 1, 1, 0 },
	{ "copy palette through shift entry", 1, 0, 1, {1,0,0,0}, 0, {0,0,0,0}, 1, 1, 0 },
	{ "palette rejection falls back to VGA", 0, 0, 2, {0,1,0,0}, 1, {1,0,0,0}, 0, 2, 0 },
	{ "VGA retry failure reports errors", 1, 0, 1, {0,0,0,0}, 2, {0,0,0,0}, 0, 1, 2 }
};

static int Bench486VidModeRunCase (const bench486_vidmode_case_t *test,
		int use_assembly, bench486_vidmode_snapshot_t *snapshot)
{
	int result;

	Bench486VidModeConfigure (test);
	if (use_assembly)
		result = VID_SetMode (test->requested_mode,
				bench486_vidmode_input_palette);
	else
		result = VID_SetMode_C (test->requested_mode,
				bench486_vidmode_input_palette);
	Bench486VidModeCapture (result, snapshot);
	return result;
}

static void Bench486VidModeRunPaletteCase (
		const bench486_vidpalette_case_t *test, int use_assembly,
		bench486_vidmode_snapshot_t *snapshot)
{
	unsigned char *palette;
	int i;

	Bench486VidModeConfigure (&bench486_vidmode_cases[0]);
	memset (bench486_vidmode_mode_results, 0,
			sizeof(bench486_vidmode_mode_results));
	memset (bench486_vidmode_palette_results, 0,
			sizeof(bench486_vidmode_palette_results));
	for (i = 0; i < test->mode_result_count && i < 4; i++)
		bench486_vidmode_mode_results[i] = test->mode_results[i];
	for (i = 0; i < test->palette_result_count && i < 4; i++)
		bench486_vidmode_palette_results[i] = test->palette_results[i];
	bench486_vidmode_mode_result_count = test->mode_result_count;
	bench486_vidmode_palette_result_count = test->palette_result_count;
	bench486_vidmode_mode_result_index = 0;
	bench486_vidmode_palette_result_index = 0;
	palette = test->input_is_current_palette ? vid_current_palette :
			bench486_vidmode_input_palette;
	if (use_assembly)
	{
		if (test->use_shift_entry)
			VID_ShiftPalette (palette);
		else
			VID_SetPalette (palette);
	}
	else
	{
		if (test->use_shift_entry)
			VID_ShiftPalette_C (palette);
		else
			VID_SetPalette_C (palette);
	}
	Bench486VidModeCapture (0, snapshot);
}

static int Bench486VidModePaletteSnapshotExpected (
		const bench486_vidpalette_case_t *test,
		const bench486_vidmode_snapshot_t *snapshot)
{
	int palette_calls, error_count, i;
	byte expected;

	palette_calls = 0;
	error_count = 0;
	for (i = 0; i < snapshot->record.event_count; i++)
	{
		const bench486_vidmode_event_t *event =
				&snapshot->record.events[i];
		if (event->kind == BVM_EVENT_SET_PALETTE)
		{
			palette_calls++;
			if (!event->video_matches || !event->palette_is_current ||
					event->mode_index < 0)
				return 0;
		}
		else if (event->kind == BVM_EVENT_ERROR)
			error_count++;
	}
	if (palette_calls != test->expected_palette_calls ||
			error_count != test->expected_error_count ||
			snapshot->mode_number != test->expected_mode_number ||
			snapshot->current_mode !=
					&bench486_vidmode_modes[test->expected_mode_number])
		return 0;
	for (i = 0; i < sizeof(snapshot->palette); i++)
	{
		expected = test->input_is_current_palette ?
				(byte)(i ^ 0x5a) : (byte)(i * 37 + 11);
		if (snapshot->palette[i] != expected)
			return 0;
	}
	return 1;
}

static void Bench486VidModeRunShutdown (int use_assembly,
		bench486_vidmode_snapshot_t *snapshot)
{
	Bench486VidModeResetRecord ();
	memset (&regs, 0xa5, sizeof(regs));
	regs.d.eax = 0xa1b2c3d4;
	vid_testingmode = 1;
	if (use_assembly)
		VID_Shutdown ();
	else
		VID_Shutdown_C ();
	Bench486VidModeCapture (0, snapshot);
}

static int Bench486VidModeShutdownSnapshotExpected (
		const bench486_vidmode_snapshot_t *snapshot)
{
	return snapshot->record.event_count == 2 &&
			!snapshot->record.overflow &&
			snapshot->record.events[0].kind == BVM_EVENT_SHUTDOWN_INT86 &&
			snapshot->record.events[0].int_value == 0x10 &&
			snapshot->record.events[0].reg_eax == 0xa1b20003 &&
			snapshot->record.events[1].kind == BVM_EVENT_SHUTDOWN_EXTRA &&
			snapshot->registers.d.eax == 0x4f138069 &&
			snapshot->registers.x.flags == 0x55aa &&
			snapshot->testing_mode == 0;
}

int Bench486VidModeCases (void)
{
	viddef_t saved_video;
	regs_t saved_regs;
	vmode_t *saved_current_mode, *saved_mode_list;
	cvar_t saved_mode_cvar;
	byte saved_palette[768];
	int saved_mode_number, saved_mode_count, saved_no_mode_check;
	int saved_screen_disabled, saved_testing_mode;
	bench486_vidmode_snapshot_t c_snapshot, asm_snapshot;
	bench486_vidmode_record_t c_record;
	vmode_t *c_mode, *asm_mode;
	char *c_name, *asm_name, *c_header, *asm_header;
	int failures, i;

	saved_video = vid;
	saved_current_mode = pcurrentmode;
	saved_mode_list = pvidmodes;
	saved_mode_cvar = vid_mode;
	memcpy (saved_palette, vid_current_palette, sizeof(saved_palette));
	saved_mode_number = vid_modenum;
	saved_mode_count = numvidmodes;
	saved_no_mode_check = vid_nomodecheck;
	saved_screen_disabled = scr_disabled_for_loading;
	saved_testing_mode = vid_testingmode;
	memcpy (&saved_regs, &regs, sizeof(saved_regs));
	failures = 0;
	Bench486VidModeInitModes ();
	pvidmodes = &bench486_vidmode_modes[0];
	numvidmodes = BVM_MODE_COUNT;

	for (i = 0; i < BVM_MODE_COUNT; i++)
	{
		Bench486VidModeResetRecord ();
		c_mode = VID_GetModePtr_C (i);
		c_record = bench486_vidmode_record;
		Bench486VidModeResetRecord ();
		asm_mode = VID_GetModePtr (i);
		if (c_mode != asm_mode ||
				!Bench486VidModeRecordsEqual (&c_record,
						&bench486_vidmode_record))
			failures |= 1;

		c_header = (char *)0x1234;
		Bench486VidModeResetRecord ();
		c_name = VID_ModeInfo_C (i, &c_header);
		c_record = bench486_vidmode_record;
		asm_header = (char *)0x1234;
		Bench486VidModeResetRecord ();
		asm_name = VID_ModeInfo (i, &asm_header);
		if (!Bench486VidModeTextEqual (c_name, asm_name) ||
				c_header != asm_header ||
				!Bench486VidModeRecordsEqual (&c_record,
						&bench486_vidmode_record))
			failures |= 2;
	}
	Bench486VidModeResetRecord ();
	c_name = VID_ModeInfo_C (1, NULL);
	c_record = bench486_vidmode_record;
	Bench486VidModeResetRecord ();
	asm_name = VID_ModeInfo (1, NULL);
	if (!Bench486VidModeTextEqual (c_name, asm_name) ||
			!Bench486VidModeRecordsEqual (&c_record,
					&bench486_vidmode_record))
		failures |= 4;

	pvidmodes = NULL;
	numvidmodes = 0;
	Bench486VidModeResetRecord ();
	c_mode = VID_GetModePtr_C (0);
	c_record = bench486_vidmode_record;
	Bench486VidModeResetRecord ();
	asm_mode = VID_GetModePtr (0);
	if (c_mode != asm_mode ||
			!Bench486VidModeRecordsEqual (&c_record,
					&bench486_vidmode_record))
		failures |= 8;
	Bench486VidModeResetRecord ();
	c_header = (char *)0x1234;
	c_name = VID_ModeInfo_C (0, &c_header);
	c_record = bench486_vidmode_record;
	Bench486VidModeResetRecord ();
	asm_header = (char *)0x1234;
	asm_name = VID_ModeInfo (0, &asm_header);
	if (!Bench486VidModeTextEqual (c_name, asm_name) || c_header != asm_header ||
			!Bench486VidModeRecordsEqual (&c_record,
					&bench486_vidmode_record))
		failures |= 16;

	Bench486VidModeInitModes ();
	pvidmodes = &bench486_vidmode_modes[0];
	numvidmodes = BVM_MODE_COUNT;
	bench486_vidmode_modes[0].pnext = NULL;
	Bench486VidModeResetRecord ();
	c_mode = VID_GetModePtr_C (1);
	c_record = bench486_vidmode_record;
	Bench486VidModeResetRecord ();
	asm_mode = VID_GetModePtr (1);
	if (c_mode != asm_mode ||
			!Bench486VidModeRecordsEqual (&c_record,
					&bench486_vidmode_record))
		failures |= 32;
	Bench486VidModeResetRecord ();
	c_header = (char *)0x1234;
	c_name = VID_ModeInfo_C (1, &c_header);
	c_record = bench486_vidmode_record;
	Bench486VidModeResetRecord ();
	asm_header = (char *)0x1234;
	asm_name = VID_ModeInfo (1, &asm_header);
	if (!Bench486VidModeTextEqual (c_name, asm_name) || c_header != asm_header ||
			!Bench486VidModeRecordsEqual (&c_record,
					&bench486_vidmode_record))
		failures |= 64;

	for (i = 0; i < sizeof(bench486_vidmode_cases) /
			sizeof(bench486_vidmode_cases[0]); i++)
	{
		const bench486_vidmode_case_t *test = &bench486_vidmode_cases[i];
		unsigned bit = (unsigned)1 << (8 + i);

		Bench486VidModeRunCase (test, 0, &c_snapshot);
		Bench486VidModeRunCase (test, 1, &asm_snapshot);
		if (!Bench486VidModeSnapshotsEqual (&c_snapshot, &asm_snapshot) ||
				c_snapshot.result != test->expected_result ||
				asm_snapshot.result != test->expected_result ||
				c_snapshot.mode_number != test->expected_mode_number ||
				asm_snapshot.mode_number != test->expected_mode_number)
			failures |= bit;
	}
	for (i = 0; i < sizeof(bench486_vidpalette_cases) /
			sizeof(bench486_vidpalette_cases[0]); i++)
	{
		const bench486_vidpalette_case_t *test =
				&bench486_vidpalette_cases[i];
		unsigned bit = (unsigned)1 << (16 + i);

		Bench486VidModeRunPaletteCase (test, 0, &c_snapshot);
		Bench486VidModeRunPaletteCase (test, 1, &asm_snapshot);
		if (!Bench486VidModeSnapshotsEqual (&c_snapshot, &asm_snapshot) ||
				!Bench486VidModePaletteSnapshotExpected (test, &c_snapshot) ||
				!Bench486VidModePaletteSnapshotExpected (test, &asm_snapshot))
			failures |= bit;
	}

	Bench486VidModeRunShutdown (0, &c_snapshot);
	Bench486VidModeRunShutdown (1, &asm_snapshot);
	if (!Bench486VidModeSnapshotsEqual (&c_snapshot, &asm_snapshot) ||
			!Bench486VidModeShutdownSnapshotExpected (&c_snapshot) ||
			!Bench486VidModeShutdownSnapshotExpected (&asm_snapshot))
		failures |= (unsigned)1 << 20;

	vid = saved_video;
	pcurrentmode = saved_current_mode;
	pvidmodes = saved_mode_list;
	vid_mode = saved_mode_cvar;
	memcpy (vid_current_palette, saved_palette, sizeof(saved_palette));
	vid_modenum = saved_mode_number;
	numvidmodes = saved_mode_count;
	vid_nomodecheck = saved_no_mode_check;
	scr_disabled_for_loading = saved_screen_disabled;
	vid_testingmode = saved_testing_mode;
	memcpy (&regs, &saved_regs, sizeof(regs));
	return failures;
}

#endif /* BENCH486_VIDMODE_H */
#endif /* BENCH486 && ASM486_VID_UPDATE_FIXTURE */
