/* Direct SCR_DrawNotifyString C/assembly argument and framebuffer parity. */
#ifndef BENCH486_SCREEN_NOTIFY_H
#define BENCH486_SCREEN_NOTIFY_H

#if defined(BENCH486) && defined(ASM486_SCREEN_NOTIFY)

#define BSN_GUARD_WORDS 8
#define BSN_FONT_BYTES 16384
#define BSN_ROW_BYTES 672
#define BSN_FRAME_ROWS 256
#define BSN_FRAME_BYTES (BSN_ROW_BYTES * BSN_FRAME_ROWS)
#define BSN_MAX_CALLS 512

/* Assembly uses the trace hook only while its direct parity fixture runs. */
int bench486_screen_notify_fixture_active;

extern void SCR_DrawNotifyString_Screen_C (void);
extern void SCR_DrawNotifyString_asm486 (void);
extern void SCR_DrawNotifyString (void);
extern void Draw_Character (int x, int y, int num);
extern byte *draw_chars;
extern int r_pixbytes;
extern char *scr_notifystring;
extern unsigned Bench486Call_asm486 (void (*function)(void), unsigned words,
		const unsigned *arguments, float *float_return);

typedef char bench486_screen_notify_requires_i386[
		(sizeof(void *) == 4 && sizeof(int) == 4 && sizeof(unsigned) == 4) ?
		1 : -1];

typedef struct
{
	unsigned before[BSN_GUARD_WORDS];
	byte pixels[BSN_FRAME_BYTES];
	unsigned after[BSN_GUARD_WORDS];
} bench486_screen_notify_frame_t;

typedef struct
{
	int x, y, character;
} bench486_screen_notify_call_t;

typedef struct
{
	bench486_screen_notify_frame_t frame;
	viddef_t video;
	byte *characters;
	char *text;
	int pixel_bytes;
	unsigned call_count;
	unsigned trace_overflow;
	unsigned abi;
	unsigned short control_word_before;
	unsigned short control_word_after;
	unsigned control_word_probe_changed;
	bench486_screen_notify_call_t calls[BSN_MAX_CALLS];
} bench486_screen_notify_result_t;

typedef struct
{
	const char *name;
	const char *text;
	unsigned width;
	unsigned height;
} bench486_screen_notify_case_t;

typedef struct
{
	byte bytes[28];
} bench486_screen_notify_x87_environment_t;

typedef struct
{
	bench486_screen_notify_frame_t frame;
	bench486_screen_notify_result_t reference;
	bench486_screen_notify_result_t candidate;
	bench486_screen_notify_call_t calls[BSN_MAX_CALLS];
} bench486_screen_notify_workspace_t;

static struct
{
	unsigned before[4];
	byte pixels[BSN_FONT_BYTES];
	unsigned after[4];
} bench486_screen_notify_font;
static bench486_screen_notify_workspace_t *bench486_screen_notify_workspace;
#define bench486_screen_notify_frame (bench486_screen_notify_workspace->frame)
#define bench486_screen_notify_reference (bench486_screen_notify_workspace->reference)
#define bench486_screen_notify_candidate (bench486_screen_notify_workspace->candidate)
#define bench486_screen_notify_calls (bench486_screen_notify_workspace->calls)
static unsigned bench486_screen_notify_call_count;
static unsigned bench486_screen_notify_trace_overflow;
static char bench486_screen_notify_first_failure[192];
static viddef_t bench486_screen_notify_saved_video;
static byte *bench486_screen_notify_saved_characters;
static char *bench486_screen_notify_saved_text;
static int bench486_screen_notify_saved_pixel_bytes;
static unsigned short bench486_screen_notify_saved_control_word;
static bench486_screen_notify_x87_environment_t bench486_screen_notify_saved_environment;
static char bench486_screen_notify_39[40];
static char bench486_screen_notify_40[41];
static char bench486_screen_notify_41[42];
static char bench486_screen_notify_long[56];
static const char bench486_screen_notify_high_bits[] = {
	(char)0x80, (char)0xff, 'Q', 0
};

static void Bench486ScreenNotifyInitData (void)
{
	unsigned i;

	for (i = 0; i < 4; i++)
	{
		bench486_screen_notify_font.before[i] = 0x486e1000U + i;
		bench486_screen_notify_font.after[i] = 0x486e2000U + i;
	}
	for (i = 0; i < BSN_FONT_BYTES; i++)
		bench486_screen_notify_font.pixels[i] = (byte)(1U + (i * 37U + (i >> 5)) % 255U);

	for (i = 0; i < 39; i++)
		bench486_screen_notify_39[i] = (char)('A' + i % 26);
	bench486_screen_notify_39[39] = 0;
	for (i = 0; i < 40; i++)
		bench486_screen_notify_40[i] = (char)('a' + i % 26);
	bench486_screen_notify_40[40] = 0;
	for (i = 0; i < 41; i++)
		bench486_screen_notify_41[i] = (char)('0' + i % 10);
	bench486_screen_notify_41[41] = 0;
	for (i = 0; i < 45; i++)
		bench486_screen_notify_long[i] = (char)('K' + i % 15);
	bench486_screen_notify_long[45] = '\n';
	bench486_screen_notify_long[46] = 'Z';
	bench486_screen_notify_long[47] = 0;
}

/* The test-only call seam records exact layout and then uses the selected
   drawing backend so the fixture also compares actual indexed pixels. */
void Bench486ScreenNotifyCharacter (int x, int y, int num)
{
	if (bench486_screen_notify_call_count < BSN_MAX_CALLS)
	{
		bench486_screen_notify_calls[bench486_screen_notify_call_count].x = x;
		bench486_screen_notify_calls[bench486_screen_notify_call_count].y = y;
		bench486_screen_notify_calls[bench486_screen_notify_call_count].character = num;
		bench486_screen_notify_call_count++;
	}
	else
		bench486_screen_notify_trace_overflow = 1;

	/* Draw_Character does not clip on the right. For narrow-screen cases the
	   C unsigned centering expression deliberately produces a huge positive x;
	   keep the raw call in the trace but avoid dereferencing outside the guarded
	   fixture framebuffer. All in-screen cases still use the selected backend. */
	if (x < 0 || (unsigned)x > vid.width - 8U ||
			(unsigned)x > BSN_ROW_BYTES - 8U || y < 0 ||
			(unsigned)y > vid.height - 8U ||
			(unsigned)y > BSN_FRAME_ROWS - 8U)
		return;

	Draw_Character (x, y, num);
}

static void Bench486ScreenNotifyPrepare (
		const bench486_screen_notify_case_t *test_case)
{
	unsigned i;

	/* The guards and every framebuffer byte are initialized below. */
	for (i = 0; i < BSN_GUARD_WORDS; i++)
	{
		bench486_screen_notify_frame.before[i] = 0x486e3100U + i;
		bench486_screen_notify_frame.after[i] = 0x5a13c900U + i;
	}
	for (i = 0; i < BSN_FRAME_BYTES; i++)
		bench486_screen_notify_frame.pixels[i] = (byte)(0x43U + i * 29U);

	Q_memset (&vid, 0, sizeof(vid));
	vid.width = test_case->width;
	vid.height = test_case->height;
	vid.conbuffer = bench486_screen_notify_frame.pixels;
	vid.conrowbytes = BSN_ROW_BYTES;
	vid.conwidth = test_case->width;
	vid.conheight = BSN_FRAME_ROWS;
	draw_chars = bench486_screen_notify_font.pixels;
	r_pixbytes = 1;
	scr_notifystring = (char *)test_case->text;
	bench486_screen_notify_call_count = 0;
	bench486_screen_notify_trace_overflow = 0;
	Q_memset (bench486_screen_notify_calls, 0, sizeof(bench486_screen_notify_calls));
}

static void Bench486ScreenNotifyCapture (
		bench486_screen_notify_result_t *result, unsigned abi,
		unsigned short control_word_before, unsigned short control_word_after)
{
	unsigned i;
	byte *destination;
	const byte *source;

	destination = (byte *)&result->frame;
	source = (const byte *)&bench486_screen_notify_frame;
	for (i = 0; i < sizeof(result->frame); i++)
		destination[i] = source[i];
	Q_memcpy (&result->video, &vid, sizeof(vid));
	result->characters = draw_chars;
	result->text = scr_notifystring;
	result->pixel_bytes = r_pixbytes;
	result->call_count = bench486_screen_notify_call_count;
	result->trace_overflow = bench486_screen_notify_trace_overflow;
	result->abi = abi;
	result->control_word_before = control_word_before;
	result->control_word_after = control_word_after;
	result->control_word_probe_changed = (abi & 0x20U) != 0;
	Q_memcpy (result->calls, bench486_screen_notify_calls,
			result->call_count * sizeof(result->calls[0]));
}

static unsigned short Bench486ScreenNotifyGetControlWord (void)
{
	unsigned short control_word;
	__asm__ __volatile__ ("fnstcw %0" : "=m" (control_word));
	return control_word;
}

static void Bench486ScreenNotifySetControlWord (unsigned short control_word)
{
	__asm__ __volatile__ ("fldcw %0" : : "m" (control_word));
}

static void Bench486ScreenNotifySaveEnvironment (
		bench486_screen_notify_x87_environment_t *environment)
{
	/* FNSTENV masks exceptions, so reload immediately to preserve live state. */
	__asm__ __volatile__ ("fnstenv %0\n\tfldenv %0" : "=m" (*environment));
}

static void Bench486ScreenNotifyRestoreEnvironment (
		const bench486_screen_notify_x87_environment_t *environment)
{
	__asm__ __volatile__ ("fldenv %0" : : "m" (*environment));
}

static int Bench486ScreenNotifyGuardsIntact (void)
{
	unsigned i;

	for (i = 0; i < BSN_GUARD_WORDS; i++)
		if (bench486_screen_notify_frame.before[i] != 0x486e3100U + i ||
				bench486_screen_notify_frame.after[i] != 0x5a13c900U + i)
			return 0;
	for (i = 0; i < 4; i++)
		if (bench486_screen_notify_font.before[i] != 0x486e1000U + i ||
				bench486_screen_notify_font.after[i] != 0x486e2000U + i)
			return 0;
	return 1;
}

static unsigned Bench486ScreenNotifyRun (
		const bench486_screen_notify_case_t *test_case,
		const char *implementation, void (*function)(void),
		bench486_screen_notify_result_t *result)
{
	unsigned abi;
	unsigned short control_word_before, control_word_after;

	Bench486ScreenNotifyPrepare (test_case);
	control_word_before = Bench486ScreenNotifyGetControlWord ();
	bench486_screen_notify_fixture_active = 1;
	abi = Bench486Call_asm486 (function, 0, NULL, NULL);
	bench486_screen_notify_fixture_active = 0;
	control_word_after = Bench486ScreenNotifyGetControlWord ();
	Bench486ScreenNotifyCapture (result, abi, control_word_before,
			control_word_after);
	if ((abi & 0x20U) || control_word_before != control_word_after)
	{
		if (!bench486_screen_notify_first_failure[0])
			sprintf (bench486_screen_notify_first_failure,
					"screen notify x87 CW FAIL case %s implementation %s before %04x after %04x probe %u",
					test_case->name, implementation, control_word_before,
					control_word_after, abi & 0x20U);
		return 1;
	}
	return abi || result->trace_overflow || !Bench486ScreenNotifyGuardsIntact ();
}

static int Bench486ScreenNotifyBytesEqual (const void *left, const void *right,
		unsigned bytes)
{
	const byte *left_bytes = (const byte *)left;
	const byte *right_bytes = (const byte *)right;
	unsigned i;

	for (i = 0; i < bytes; i++)
		if (left_bytes[i] != right_bytes[i])
			return 0;
	return 1;
}

static unsigned Bench486ScreenNotifyDifference (
		const bench486_screen_notify_result_t *reference,
		const bench486_screen_notify_result_t *candidate)
{
	unsigned i;

	if (reference->call_count != candidate->call_count ||
			reference->trace_overflow != candidate->trace_overflow ||
			reference->abi != candidate->abi ||
			reference->control_word_before != candidate->control_word_before ||
			reference->control_word_after != candidate->control_word_after ||
			reference->control_word_probe_changed != candidate->control_word_probe_changed ||
			reference->characters != candidate->characters ||
			reference->text != candidate->text ||
			reference->pixel_bytes != candidate->pixel_bytes ||
			!Bench486ScreenNotifyBytesEqual (&reference->video,
					&candidate->video, sizeof(reference->video)))
		return 0xffffffffU;
	if (!Bench486ScreenNotifyBytesEqual (&reference->frame, &candidate->frame,
			sizeof(reference->frame)))
	{
		for (i = 0; i < sizeof(reference->frame); i++)
			if (((const byte *)&reference->frame)[i] !=
					((const byte *)&candidate->frame)[i])
				return 0x80000000U | i;
	}
	for (i = 0; i < reference->call_count; i++)
		if (reference->calls[i].x != candidate->calls[i].x ||
				reference->calls[i].y != candidate->calls[i].y ||
				reference->calls[i].character != candidate->calls[i].character)
			return 0x40000000U | i;
	return 0;
}

/* Exercise the assembly's production Draw_Character branch. The main fixture
   activates the trace hook to compare character calls; this safe one-glyph
   case explicitly leaves it disabled and compares the resulting framebuffer. */
static unsigned Bench486ScreenNotifyLiveCharacterCase (void)
{
	static const bench486_screen_notify_case_t test_case = {
		"live-draw-character-route", "Q", 320, 200
	};
	unsigned abi;
	unsigned short control_word_before, control_word_after;

	Bench486ScreenNotifyRun (&test_case, "C oracle",
			SCR_DrawNotifyString_Screen_C,
			&bench486_screen_notify_reference);
	Bench486ScreenNotifyPrepare (&test_case);
	control_word_before = Bench486ScreenNotifyGetControlWord ();
	bench486_screen_notify_fixture_active = 0;
	abi = Bench486Call_asm486 (SCR_DrawNotifyString_asm486, 0, NULL, NULL);
	bench486_screen_notify_fixture_active = 0;
	control_word_after = Bench486ScreenNotifyGetControlWord ();
	Bench486ScreenNotifyCapture (&bench486_screen_notify_candidate, abi,
			control_word_before, control_word_after);
	if (abi || control_word_before != control_word_after ||
			!Bench486ScreenNotifyBytesEqual (
					&bench486_screen_notify_reference.frame,
					&bench486_screen_notify_candidate.frame,
					sizeof(bench486_screen_notify_reference.frame)) ||
			!Bench486ScreenNotifyGuardsIntact ())
		return 1;
	return 0;
}

static void Bench486ScreenNotifyCases (void)
{
	static const bench486_screen_notify_case_t cases[] = {
		{ "empty", "", 320, 200 },
		{ "one-even-width", "Q", 320, 200 },
		{ "one-odd-width", "Q", 321, 201 },
		{ "two-odd-width", "XY", 321, 224 },
		{ "narrow-even-40", bench486_screen_notify_40, 160, 200 },
		{ "narrow-odd-40", bench486_screen_notify_40, 159, 201 },
		{ "high-bit-width-40", bench486_screen_notify_40, 0x80000000U, 200 },
		{ "large-width-40", bench486_screen_notify_40, 0x7fffffffU, 200 },
		{ "high-bit-height", "Q", 320, 0x80000000U },
		{ "max-height", "Q", 320, 0xffffffffU },
		{ "line-39", bench486_screen_notify_39, 640, 224 },
		{ "line-40", bench486_screen_notify_40, 640, 240 },
		{ "line-41", bench486_screen_notify_41, 641, 200 },
		{ "overlong-suffix", bench486_screen_notify_long, 641, 201 },
		{ "leading-newline", "\nA", 640, 224 },
		{ "consecutive-newlines", "A\n\nB", 641, 240 },
		{ "trailing-newline", "A\n", 640, 200 },
		{ "only-newline", "\n", 321, 201 },
		{ "signed-high-bytes", bench486_screen_notify_high_bits, 321, 239 }
	};
	static const char *rounding_names[4] = {
		"nearest", "down", "up", "truncate"
	};
	static const unsigned short rounding_bits[4] = { 0x0000, 0x0400, 0x0800, 0x0c00 };
	static const char *precision_names[3] = { "single", "double", "extended" };
	static const unsigned short precision_bits[3] = { 0x0000, 0x0200, 0x0300 };
	unsigned case_index, precision, precision_count, rounding, failures, difference;
	unsigned live_route_failures;
	unsigned short control_word;
	int hunk_mark;
	const bench486_screen_notify_case_t *test_case;

	hunk_mark = Hunk_LowMark ();
	bench486_screen_notify_workspace = Hunk_AllocName (
			sizeof(*bench486_screen_notify_workspace), "scrnotify");
	Bench486ScreenNotifySaveEnvironment (&bench486_screen_notify_saved_environment);
	bench486_screen_notify_saved_control_word = Bench486ScreenNotifyGetControlWord ();
	Q_memcpy (&bench486_screen_notify_saved_video, &vid, sizeof(vid));
	bench486_screen_notify_saved_characters = draw_chars;
	bench486_screen_notify_saved_text = scr_notifystring;
	bench486_screen_notify_saved_pixel_bytes = r_pixbytes;
	Bench486ScreenNotifyInitData ();
	failures = 0;
	bench486_screen_notify_first_failure[0] = 0;
	Bench486Printf ("screen notify begin cases %u RC modes 4; PC modes 3 for high-bit dimensions\n",
			(unsigned)(sizeof(cases) / sizeof(cases[0])));

	for (case_index = 0; case_index < sizeof(cases) / sizeof(cases[0]); case_index++)
	{
		test_case = &cases[case_index];
		precision_count = ((test_case->width | test_case->height) & 0x80000000U) ? 3 : 1;
		for (precision = 0; precision < precision_count; precision++)
		{
			unsigned short precision_control;
			const char *precision_name;

			precision_control = precision_count == 1 ?
					(unsigned short)(bench486_screen_notify_saved_control_word & 0x0300U) :
					precision_bits[precision];
			precision_name = precision_count == 1 ? "caller" : precision_names[precision];
			for (rounding = 0; rounding < 4; rounding++)
			{
				control_word = (unsigned short)((bench486_screen_notify_saved_control_word &
						(unsigned short)~0x0f00U) | precision_control | rounding_bits[rounding]);
				Bench486ScreenNotifySetControlWord (control_word);
				failures += Bench486ScreenNotifyRun (test_case, "C oracle",
						SCR_DrawNotifyString_Screen_C,
						&bench486_screen_notify_reference);
				Bench486ScreenNotifySetControlWord (control_word);
				failures += Bench486ScreenNotifyRun (test_case, "assembly",
						SCR_DrawNotifyString_asm486,
						&bench486_screen_notify_candidate);
				difference = Bench486ScreenNotifyDifference (
						&bench486_screen_notify_reference,
						&bench486_screen_notify_candidate);
				if (difference)
				{
					failures++;
					if (!bench486_screen_notify_first_failure[0])
						sprintf (bench486_screen_notify_first_failure,
								"screen notify mismatch %s/%s/%s detail %u",
								test_case->name, precision_name,
								rounding_names[rounding], difference);
				}
				Bench486ScreenNotifySetControlWord (control_word);
				failures += Bench486ScreenNotifyRun (test_case, "public entry",
						SCR_DrawNotifyString,
						&bench486_screen_notify_candidate);
				difference = Bench486ScreenNotifyDifference (
						&bench486_screen_notify_reference,
						&bench486_screen_notify_candidate);
				if (difference)
				{
					failures++;
					if (!bench486_screen_notify_first_failure[0])
						sprintf (bench486_screen_notify_first_failure,
								"screen notify public mismatch %s/%s/%s detail %u",
								test_case->name, precision_name,
								rounding_names[rounding], difference);
				}
				Bench486ScreenNotifySetControlWord (
						bench486_screen_notify_saved_control_word);
			}
		}
	}
	live_route_failures = Bench486ScreenNotifyLiveCharacterCase ();

	Q_memcpy (&vid, &bench486_screen_notify_saved_video, sizeof(vid));
	draw_chars = bench486_screen_notify_saved_characters;
	scr_notifystring = bench486_screen_notify_saved_text;
	r_pixbytes = bench486_screen_notify_saved_pixel_bytes;
	Bench486ScreenNotifyRestoreEnvironment (&bench486_screen_notify_saved_environment);
	if (bench486_screen_notify_first_failure[0])
		Bench486Printf ("%s\n", bench486_screen_notify_first_failure);
	Bench486Printf ("screen notify live Draw_Character route exact framebuffer parity %s\n",
			live_route_failures ? "FAIL" : "PASS");
	failures += live_route_failures;
	bench486_memory_failures += failures;
	Bench486Printf ("screen notify cases %u RC modes 4, PC modes 3 for high-bit dimensions; failures %u\n",
			(unsigned)(sizeof(cases) / sizeof(cases[0])), failures);
	bench486_screen_notify_fixture_active = 0;
	bench486_screen_notify_workspace = NULL;
	Hunk_FreeToLowMark (hunk_mark);
}

#endif /* BENCH486 && ASM486_SCREEN_NOTIFY */

#endif
