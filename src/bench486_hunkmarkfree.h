/* Exact C/assembly parity for low/high hunk mark reclamation. */
#if defined(BENCH486) && defined(ASM486_HUNK_MARK_RELEASE_FIXTURE)
#define BHMF_ARENA_SIZE 512

typedef struct bench486_hunk_mark_free_snapshot_s
{
	byte arena[BHMF_ARENA_SIZE];
	int low_used;
	int high_used;
	int temp_active;
	int temp_mark;
	int result;
} bench486_hunk_mark_free_snapshot_t;

static union
{
	long alignment[4];
	byte bytes[BHMF_ARENA_SIZE];
} bench486_hunk_mark_free_arena;

static int Bench486HunkMarkFreeSetup (int is_high, int case_index)
{
	int i;
	for (i = 0; i < BHMF_ARENA_SIZE; i++)
		bench486_hunk_mark_free_arena.bytes[i] = (byte)(i * 29 + 17);
	hunk_base = bench486_hunk_mark_free_arena.bytes;
	hunk_size = BHMF_ARENA_SIZE;
	hunk_low_used = 64;
	hunk_high_used = 96;
	hunk_tempactive = false;
	hunk_tempmark = 0;
	if (is_high)
	{
		switch (case_index)
		{
		case 0: hunk_high_used = 0; return 0;
		case 1: hunk_high_used = 160; return 160;
		case 2: hunk_high_used = 160; return 0;
		case 3: hunk_high_used = 160; return 64;
		case 4:
			hunk_high_used = 160;
			hunk_tempactive = true;
			hunk_tempmark = 96;
			return 32;
		case 5:
			hunk_high_used = 160;
			hunk_tempactive = true;
			hunk_tempmark = 96;
			return 96;
		case 6:
			hunk_high_used = 224;
			hunk_tempactive = true;
			hunk_tempmark = 96;
			return 48;
		}
	}
	else
	{
		switch (case_index)
		{
		case 0: hunk_low_used = 0; return 0;
		case 1: hunk_low_used = 160; return 160;
		case 2: hunk_low_used = 160; return 0;
		case 3:
			hunk_low_used = 160;
			hunk_high_used = 96;
			return 64;
		case 4:
			hunk_low_used = 224;
			hunk_high_used = 128;
			return 96;
		}
	}
	return 0;
}

static void Bench486HunkMarkFreeCapture (
		bench486_hunk_mark_free_snapshot_t *snapshot)
{
	memcpy (snapshot->arena, bench486_hunk_mark_free_arena.bytes,
		sizeof (snapshot->arena));
	snapshot->low_used = hunk_low_used;
	snapshot->high_used = hunk_high_used;
	snapshot->temp_active = hunk_tempactive;
	snapshot->temp_mark = hunk_tempmark;
	snapshot->result = 0;
}

static int Bench486HunkHighMarkSetup (int case_index)
{
	int i;
	for (i = 0; i < BHMF_ARENA_SIZE; i++)
		bench486_hunk_mark_free_arena.bytes[i] = (byte)(i * 29 + 17);
	hunk_base = bench486_hunk_mark_free_arena.bytes;
	hunk_size = BHMF_ARENA_SIZE;
	hunk_low_used = 64;
	hunk_high_used = 160;
	hunk_tempactive = false;
	hunk_tempmark = 96;
	switch (case_index)
	{
	case 0: hunk_high_used = 0; return 0;
	case 1: return 160;
	case 2:
		hunk_tempactive = true;
		hunk_tempmark = 96;
		return 96;
	case 3:
		hunk_high_used = 96;
		hunk_tempactive = true;
		hunk_tempmark = 96;
		return 96;
	case 4:
		hunk_high_used = 224;
		hunk_tempactive = true;
		hunk_tempmark = 0;
		return 0;
	}
	return 0;
}

static void Bench486HunkHighMarkCapture (
		bench486_hunk_mark_free_snapshot_t *snapshot, int result)
{
	Bench486HunkMarkFreeCapture (snapshot);
	snapshot->result = result;
}

static int Bench486HunkHighMarkRun (int case_index, int use_asm,
		bench486_hunk_mark_free_snapshot_t *snapshot)
{
	int expected, result;
	expected = Bench486HunkHighMarkSetup (case_index);
	result = use_asm ? Hunk_HighMark () : Hunk_HighMark_C ();
	Bench486HunkHighMarkCapture (snapshot, result);
	return result != expected;
}

static int Bench486HunkMarkFreeBytesEqual (const void *left,
		const void *right, unsigned size)
{
	const byte *a = left, *b = right;
	while (size--)
		if (*a++ != *b++) return false;
	return true;
}

static int Bench486HunkMarkFreeRun (int is_high, int case_index,
		int use_asm, bench486_hunk_mark_free_snapshot_t *snapshot)
{
	int mark = Bench486HunkMarkFreeSetup (is_high, case_index);
	if (is_high)
	{
		if (use_asm) Hunk_FreeToHighMark (mark);
		else Hunk_FreeToHighMark_C (mark);
	}
	else
	{
		if (use_asm) Hunk_FreeToLowMark (mark);
		else Hunk_FreeToLowMark_C (mark);
	}
	Bench486HunkMarkFreeCapture (snapshot);
	return 0;
}

int Bench486HunkMarkFreeCases (void)
{
	bench486_hunk_mark_free_snapshot_t c, a;
	byte *saved_hunk_base = hunk_base;
	int saved_hunk_size = hunk_size;
	int saved_low_used = hunk_low_used;
	int saved_high_used = hunk_high_used;
	qboolean saved_tempactive = hunk_tempactive;
	int saved_tempmark = hunk_tempmark;
	int case_index, is_high, limit, failures = 0;
	for (is_high = 0; is_high <= 1; is_high++)
	{
		limit = is_high ? 7 : 5;
		for (case_index = 0; case_index < limit; case_index++)
		{
			Bench486HunkMarkFreeRun (is_high, case_index, 0, &c);
			Bench486HunkMarkFreeRun (is_high, case_index, 1, &a);
			if (!Bench486HunkMarkFreeBytesEqual (&c, &a, sizeof (c)))
				failures |= 1 << (is_high ? case_index + 5 : case_index);
		}
	}
	for (case_index = 0; case_index < 5; case_index++)
	{
		int c_failed, a_failed;
		c_failed = Bench486HunkHighMarkRun (case_index, 0, &c);
		a_failed = Bench486HunkHighMarkRun (case_index, 1, &a);
		if (c_failed || a_failed ||
				!Bench486HunkMarkFreeBytesEqual (&c, &a, sizeof (c)))
			failures |= 1 << (case_index + 12);
	}
	hunk_base = saved_hunk_base;
	hunk_size = saved_hunk_size;
	hunk_low_used = saved_low_used;
	hunk_high_used = saved_high_used;
	hunk_tempactive = saved_tempactive;
	hunk_tempmark = saved_tempmark;
	return failures;
}

#undef BHMF_ARENA_SIZE
#endif
