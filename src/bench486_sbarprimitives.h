/* Exact C/assembly parity for the status-bar digit and coordinate primitives. */
#ifndef BENCH486_SBAR_PRIMITIVES_H
#define BENCH486_SBAR_PRIMITIVES_H

#include "asm_sbar.h"

#define BENCH486_SBAR_CAPTURE_CAPACITY 64

typedef struct
{
	int kind;
	int x;
	int y;
	unsigned long value;
} bench486_sbar_capture_t;

typedef void (*bench486_sbar_action_t) (void);

int bench486_sbar_capture_active;
static bench486_sbar_capture_t bench486_sbar_capture[ BENCH486_SBAR_CAPTURE_CAPACITY ];
static int bench486_sbar_capture_count;
static int bench486_sbar_capture_overflow;
static int bench486_sbar_first_diff_logged;

static int bench486_sbar_x;
static int bench486_sbar_y;
static int bench486_sbar_num;
static int bench486_sbar_digits;
static int bench486_sbar_color;
static qpic_t *bench486_sbar_pic;
static char *bench486_sbar_string;

extern void Sbar_DrawPic (int x, int y, qpic_t *pic);
extern void Sbar_DrawTransPic (int x, int y, qpic_t *pic);
extern void Sbar_DrawCharacter (int x, int y, int num);
extern void Sbar_DrawString (int x, int y, char *str);
extern int Sbar_itoa (int num, char *buf);
extern void Sbar_DrawNum (int x, int y, int num, int digits, int color);

extern void Sbar_DrawPic_C (int x, int y, qpic_t *pic);
extern void Sbar_DrawTransPic_C (int x, int y, qpic_t *pic);
extern void Sbar_DrawCharacter_C (int x, int y, int num);
extern void Sbar_DrawString_C (int x, int y, char *str);
extern int Sbar_itoa_C (int num, char *buf);
extern void Sbar_DrawNum_C (int x, int y, int num, int digits, int color);

void Bench486SbarCapture (int kind, int x, int y, unsigned long value)
{
	if (bench486_sbar_capture_count >= BENCH486_SBAR_CAPTURE_CAPACITY)
	{
		bench486_sbar_capture_overflow = 1;
		return;
	}

	bench486_sbar_capture[bench486_sbar_capture_count].kind = kind;
	bench486_sbar_capture[bench486_sbar_capture_count].x = x;
	bench486_sbar_capture[bench486_sbar_capture_count].y = y;
	bench486_sbar_capture[bench486_sbar_capture_count].value = value;
	bench486_sbar_capture_count++;
}

static void Bench486SbarResetCapture (void)
{
	bench486_sbar_capture_count = 0;
	bench486_sbar_capture_overflow = 0;
}

static void Bench486SbarPicC (void)
{
	Sbar_DrawPic_C (bench486_sbar_x, bench486_sbar_y, bench486_sbar_pic);
}

static void Bench486SbarPicAsm (void)
{
	Sbar_DrawPic (bench486_sbar_x, bench486_sbar_y, bench486_sbar_pic);
}

static void Bench486SbarTransPicC (void)
{
	Sbar_DrawTransPic_C (bench486_sbar_x, bench486_sbar_y, bench486_sbar_pic);
}

static void Bench486SbarTransPicAsm (void)
{
	Sbar_DrawTransPic (bench486_sbar_x, bench486_sbar_y, bench486_sbar_pic);
}

static void Bench486SbarCharacterC (void)
{
	Sbar_DrawCharacter_C (bench486_sbar_x, bench486_sbar_y, bench486_sbar_num);
}

static void Bench486SbarCharacterAsm (void)
{
	Sbar_DrawCharacter (bench486_sbar_x, bench486_sbar_y, bench486_sbar_num);
}

static void Bench486SbarStringC (void)
{
	Sbar_DrawString_C (bench486_sbar_x, bench486_sbar_y, bench486_sbar_string);
}

static void Bench486SbarStringAsm (void)
{
	Sbar_DrawString (bench486_sbar_x, bench486_sbar_y, bench486_sbar_string);
}

static void Bench486SbarNumberC (void)
{
	Sbar_DrawNum_C (bench486_sbar_x, bench486_sbar_y, bench486_sbar_num,
			bench486_sbar_digits, bench486_sbar_color);
}

static void Bench486SbarNumberAsm (void)
{
	Sbar_DrawNum (bench486_sbar_x, bench486_sbar_y, bench486_sbar_num,
			bench486_sbar_digits, bench486_sbar_color);
}

static int Bench486SbarCapturedPair (char *name,
		bench486_sbar_action_t c_function, bench486_sbar_action_t asm_function)
{
	bench486_sbar_capture_t expected[BENCH486_SBAR_CAPTURE_CAPACITY];
	int expected_count, expected_overflow, i, failures;

	bench486_sbar_capture_active = 1;
	Bench486SbarResetCapture ();
	c_function ();
	expected_count = bench486_sbar_capture_count;
	expected_overflow = bench486_sbar_capture_overflow;
	for (i = 0; i < expected_count; i++)
		expected[i] = bench486_sbar_capture[i];

	Bench486SbarResetCapture ();
	asm_function ();
	bench486_sbar_capture_active = 0;

	failures = expected_overflow || bench486_sbar_capture_overflow ||
			expected_count != bench486_sbar_capture_count;
	for (i = 0; !failures && i < expected_count; i++)
		if (expected[i].kind != bench486_sbar_capture[i].kind ||
			expected[i].x != bench486_sbar_capture[i].x ||
			expected[i].y != bench486_sbar_capture[i].y ||
			expected[i].value != bench486_sbar_capture[i].value)
			failures = 1;

	if (failures)
	{
		for (i = 0; i < expected_count &&
				i < bench486_sbar_capture_count; i++)
			if (expected[i].kind != bench486_sbar_capture[i].kind ||
				expected[i].x != bench486_sbar_capture[i].x ||
				expected[i].y != bench486_sbar_capture[i].y ||
				expected[i].value != bench486_sbar_capture[i].value)
			{
				if (!bench486_sbar_first_diff_logged)
				{
					Bench486Printf ("sbar %s first diff #%d C=(%d,%d,%d,%lu) ASM=(%d,%d,%d,%lu)\n",
							name, i, expected[i].kind, expected[i].x,
							expected[i].y, expected[i].value,
							bench486_sbar_capture[i].kind,
							bench486_sbar_capture[i].x,
							bench486_sbar_capture[i].y,
							bench486_sbar_capture[i].value);
					bench486_sbar_first_diff_logged = 1;
				}
				break;
			}
		Bench486Printf ("sbar %s C/ASM capture FAIL count %d/%d overflow %d/%d\n",
				name, expected_count, bench486_sbar_capture_count,
				expected_overflow, bench486_sbar_capture_overflow);
		return 0;
	}
	return 1;
}

static int Bench486SbarBytesEqual (const char *left, const char *right,
		int count)
{
	while (count--)
		if (*left++ != *right++)
			return 0;
	return 1;
}

static int Bench486SbarTextEqual (const char *left, const char *right)
{
	while (*left && *left == *right)
	{
		left++;
		right++;
	}
	return *left == *right;
}

static void Bench486SbarPrimitiveCases (void)
{
	static const int values[] = {
		0, 1, 9, 10, 19, 99, 100, 999, 1000, 12345,
		999999999, -1, -9, -19, -123, -999999999
	};
	static const int widths[] = { 256, 320, 640, 800 };
	static char test_string[] = "status-bar parity";
	qpic_t *saved_nums[2][SBAR_NUM_FRAMES];
	char c_text[12], asm_text[12];
	qboolean saved_gametype;
	int saved_width, saved_height;
	int i, j, color, digits, value_index, game, failures, c_length, asm_length;

	failures = 0;
	saved_gametype = cl.gametype;
	saved_width = vid.width;
	saved_height = vid.height;
	for (color = 0; color < 2; color++)
		for (i = 0; i < SBAR_NUM_FRAMES; i++)
		{
			saved_nums[color][i] = sb_nums[color][i];
			sb_nums[color][i] = (qpic_t *)(unsigned long)
					(0x10000 + (color * SBAR_NUM_FRAMES + i) * 32);
		}

	for (value_index = 0; value_index < sizeof(values) / sizeof(values[0]); value_index++)
	{
		c_length = Sbar_itoa_C (values[value_index], c_text);
		asm_length = Sbar_itoa (values[value_index], asm_text);
		if (c_length != asm_length ||
				!Bench486SbarBytesEqual (c_text, asm_text, c_length + 1))
		{
			failures++;
			Bench486Printf ("sbar itoa C/ASM FAIL value %d length %d/%d text %s/%s\n",
					values[value_index], c_length, asm_length, c_text, asm_text);
		}
	}

	asm_length = Sbar_itoa ((int)0x80000000UL, asm_text);
	if (asm_length != 11 ||
			!Bench486SbarTextEqual (asm_text, "-2147483648"))
	{
		failures++;
		Bench486Printf ("sbar itoa INT_MIN boundary FAIL length %d text %s\n",
				asm_length, asm_text);
	}
	asm_length = Sbar_itoa (2147483647, asm_text);
	if (asm_length != 10 ||
			!Bench486SbarTextEqual (asm_text, "2147483647"))
	{
		failures++;
		Bench486Printf ("sbar itoa INT_MAX boundary FAIL length %d text %s\n",
				asm_length, asm_text);
	}

	for (game = 0; game < 2; game++)
		for (i = 0; i < sizeof(widths) / sizeof(widths[0]); i++)
		{
			cl.gametype = game ? GAME_DEATHMATCH : 0;
			vid.width = widths[i];
			vid.height = 200 + i * 40;
			bench486_sbar_x = -13 + i * 17;
			bench486_sbar_y = 5 - i * 3;
			bench486_sbar_pic = (qpic_t *)(unsigned long)(0x20000 + i * 64);
			bench486_sbar_num = 239 - i;
			bench486_sbar_string = test_string;
			failures += !Bench486SbarCapturedPair ("pic",
					Bench486SbarPicC, Bench486SbarPicAsm);
			failures += !Bench486SbarCapturedPair ("transpic",
					Bench486SbarTransPicC, Bench486SbarTransPicAsm);
			failures += !Bench486SbarCapturedPair ("character",
					Bench486SbarCharacterC, Bench486SbarCharacterAsm);
			failures += !Bench486SbarCapturedPair ("string",
					Bench486SbarStringC, Bench486SbarStringAsm);

			for (value_index = 0; value_index < sizeof(values) / sizeof(values[0]); value_index++)
				for (digits = 1; digits <= 4; digits++)
					for (color = 0; color < 2; color++)
					{
						bench486_sbar_num = values[value_index];
						bench486_sbar_digits = digits;
						bench486_sbar_color = color;
						failures += !Bench486SbarCapturedPair ("number",
								Bench486SbarNumberC, Bench486SbarNumberAsm);
					}
		}

	bench486_sbar_capture_active = 0;
	cl.gametype = saved_gametype;
	vid.width = saved_width;
	vid.height = saved_height;
	for (color = 0; color < 2; color++)
		for (j = 0; j < SBAR_NUM_FRAMES; j++)
			sb_nums[color][j] = saved_nums[color][j];

	if (failures)
		bench486_memory_failures += failures;
	Bench486Printf ("sbar number and coordinate primitives C/ASM %s (%d failures; %d formatter and %d scene-state cases)\n",
			failures ? "FAIL" : "PASS", failures,
		(int)(sizeof(values) / sizeof(values[0])) + 2,
		2 * (int)(sizeof(widths) / sizeof(widths[0])) *
			(4 + (int)(sizeof(values) / sizeof(values[0])) * 4));
}

#endif /* BENCH486_SBAR_PRIMITIVES_H */
