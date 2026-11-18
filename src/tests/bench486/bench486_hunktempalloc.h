/* Exact C/assembly parity for temporary high-hunk allocation. */
/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
#if defined(BENCH486) && defined(ASM486_HUNK_TEMP_ALLOC_FIXTURE)
#define BHTA_ARENA_SIZE 512
#define BHTA_CASE_COUNT 10

typedef struct bench486_hunk_temp_alloc_snapshot_s
{
	byte arena[BHTA_ARENA_SIZE];
	cache_system_t cache_sentinel;
	int low_used;
	int high_used;
	int temp_active;
	int temp_mark;
	int first_result_offset;
	int result_offset;
} bench486_hunk_temp_alloc_snapshot_t;

static union
{
	long alignment[4];
	byte bytes[BHTA_ARENA_SIZE];
} bench486_hunk_temp_alloc_arena;

static int Bench486HunkTempAllocSize (int case_index)
{
	switch (case_index)
	{
	case 0: return 0;
	case 1: return 1;
	case 2: return 15;
	case 3: return 17;
	case 4: return 33;
	case 5: return 0;
	case 6: return 16;
	case 7: return -1;
	case 8: return 32;
	default: return 33;
	}
}

static void Bench486HunkTempAllocSetup (int case_index)
{
	int i;
	for (i = 0; i < BHTA_ARENA_SIZE; i++)
		bench486_hunk_temp_alloc_arena.bytes[i] = (byte)(i * 37 + 11);
	hunk_base = bench486_hunk_temp_alloc_arena.bytes;
	hunk_size = BHTA_ARENA_SIZE;
	hunk_low_used = 64;
	hunk_high_used = 0;
	hunk_tempactive = false;
	hunk_tempmark = 0;

	cache_head.size = 0;
	cache_head.user = NULL;
	cache_head.name[0] = 0;
	cache_head.prev = cache_head.next = &cache_head;
	cache_head.lru_prev = cache_head.lru_next = &cache_head;

	switch (case_index)
	{
	case 0: hunk_high_used = 0; break;
	case 1: hunk_high_used = 64; hunk_tempmark = 16; break;
	case 2:
		hunk_high_used = 160;
		hunk_tempactive = true;
		hunk_tempmark = 64;
		break;
	case 3:
		hunk_high_used = 224;
		hunk_tempactive = true;
		hunk_tempmark = 128;
		break;
	case 4: hunk_high_used = 128; hunk_tempmark = 64; break;
	case 5:
		hunk_high_used = 80;
		hunk_tempactive = true;
		hunk_tempmark = 80;
		break;
	case 6:
		hunk_high_used = 96;
		hunk_tempactive = true;
		hunk_tempmark = 32;
		break;
	case 7: hunk_high_used = 352; break;
	case 8:
		hunk_high_used = 288;
		hunk_tempactive = true;
		hunk_tempmark = 224;
		break;
	case 9: hunk_high_used = 32; break;
	}
}

static int Bench486HunkTempAllocRun (int case_index, int use_asm,
		bench486_hunk_temp_alloc_snapshot_t *snapshot)
{
	void *first_result = NULL;
	void *result;
	int size = Bench486HunkTempAllocSize (case_index);
	Bench486HunkTempAllocSetup (case_index);
	if (case_index == 9)
	{
		if (use_asm)
			first_result = Hunk_TempAlloc (17);
		else
			first_result = Hunk_TempAlloc_C (17);
		if (use_asm)
			result = Hunk_TempAlloc (size);
		else
			result = Hunk_TempAlloc_C (size);
	}
	else if (use_asm)
		result = Hunk_TempAlloc (size);
	else
		result = Hunk_TempAlloc_C (size);

	memcpy (snapshot->arena, bench486_hunk_temp_alloc_arena.bytes,
		sizeof (snapshot->arena));
	snapshot->cache_sentinel = cache_head;
	snapshot->low_used = hunk_low_used;
	snapshot->high_used = hunk_high_used;
	snapshot->temp_active = hunk_tempactive;
	snapshot->temp_mark = hunk_tempmark;
	snapshot->first_result_offset = first_result ?
		(int)((byte *)first_result - hunk_base) : -1;
	snapshot->result_offset = result ?
		(int)((byte *)result - hunk_base) : -1;
	return 0;
}

static int Bench486HunkTempAllocBytesEqual (const void *left,
		const void *right, unsigned size)
{
	const byte *a = left, *b = right;
	while (size--)
		if (*a++ != *b++) return false;
	return true;
}

int Bench486HunkTempAllocCases (void)
{
	bench486_hunk_temp_alloc_snapshot_t c, a;
	byte *saved_hunk_base = hunk_base;
	int saved_hunk_size = hunk_size;
	int saved_low_used = hunk_low_used;
	int saved_high_used = hunk_high_used;
	qboolean saved_tempactive = hunk_tempactive;
	int saved_tempmark = hunk_tempmark;
	cache_system_t saved_cache_head = cache_head;
	int case_index, failures = 0;
#ifdef PROFILE486
	unsigned long saved_hunk_high_calls = bench486_hunk_high_calls;
	unsigned long saved_hunk_high_bytes = bench486_hunk_high_bytes;
#endif

	for (case_index = 0; case_index < BHTA_CASE_COUNT; case_index++)
	{
#ifdef PROFILE486
		bench486_hunk_high_calls = saved_hunk_high_calls;
		bench486_hunk_high_bytes = saved_hunk_high_bytes;
#endif
		Bench486HunkTempAllocRun (case_index, 0, &c);
#ifdef PROFILE486
		bench486_hunk_high_calls = saved_hunk_high_calls;
		bench486_hunk_high_bytes = saved_hunk_high_bytes;
#endif
		Bench486HunkTempAllocRun (case_index, 1, &a);
		if (!Bench486HunkTempAllocBytesEqual (&c, &a, sizeof (c)))
			failures |= 1 << case_index;
	}

	hunk_base = saved_hunk_base;
	hunk_size = saved_hunk_size;
	hunk_low_used = saved_low_used;
	hunk_high_used = saved_high_used;
	hunk_tempactive = saved_tempactive;
	hunk_tempmark = saved_tempmark;
	cache_head = saved_cache_head;
#ifdef PROFILE486
	bench486_hunk_high_calls = saved_hunk_high_calls;
	bench486_hunk_high_bytes = saved_hunk_high_bytes;
#endif
	return failures;
}

#undef BHTA_CASE_COUNT
#undef BHTA_ARENA_SIZE
#endif
