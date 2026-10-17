/* Exact C/assembly parity for low/high named hunk allocation. */
#if defined(BENCH486) && defined(ASM486_HUNK_NAMED_ALLOC_FIXTURE)
#define BHNA_ARENA_SIZE 1024
#define BHNA_CASE_COUNT 6

typedef struct bench486_hunk_named_alloc_snapshot_s
{
	byte arena[BHNA_ARENA_SIZE];
	cache_system_t cache_sentinel;
	int low_used;
	int high_used;
	int temp_active;
	int temp_mark;
	int result_offset;
#ifdef PROFILE486
	unsigned long low_calls;
	unsigned long low_bytes;
	unsigned long high_calls;
	unsigned long high_bytes;
#endif
} bench486_hunk_named_alloc_snapshot_t;

static union
{
	long alignment[4];
	byte bytes[BHNA_ARENA_SIZE];
} bench486_hunk_named_alloc_arena;

static int Bench486HunkNamedAllocSize (int case_index)
{
	switch (case_index)
	{
	case 0: return 0;
	case 1: return 1;
	case 2: return 15;
	case 3: return 16;
	case 4: return 17;
	default: return 33;
	}
}

static char *Bench486HunkNamedAllocName (int case_index)
{
	static char *names[BHNA_CASE_COUNT] = {
		"zero", "one", "fifteen", "sixteen", "seventeen", "longname-123"
	};
	return names[case_index];
}

static void Bench486HunkNamedAllocSetup (int is_high, int case_index)
{
	int i;
	for (i = 0; i < BHNA_ARENA_SIZE; i++)
		bench486_hunk_named_alloc_arena.bytes[i] = (byte)(i * 23 + 7);
	hunk_base = bench486_hunk_named_alloc_arena.bytes;
	hunk_size = BHNA_ARENA_SIZE;
	hunk_tempactive = false;
	hunk_tempmark = 0;

	memset (&cache_head, 0, sizeof (cache_head));
	cache_head.prev = cache_head.next = &cache_head;
	cache_head.lru_prev = cache_head.lru_next = &cache_head;

	if (!is_high)
	{
		static int low_used[BHNA_CASE_COUNT] = { 0, 32, 128, 64, 192, 256 };
		static int high_used[BHNA_CASE_COUNT] = { 0, 64, 160, 0, 128, 128 };
		hunk_low_used = low_used[case_index];
		hunk_high_used = high_used[case_index];
		return;
	}

	hunk_low_used = 64;
	switch (case_index)
	{
	case 0: hunk_high_used = 0; break;
	case 1: hunk_high_used = 64; break;
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
	case 4:
		hunk_high_used = 128;
		hunk_tempmark = 64;
		break;
	default:
		hunk_high_used = 352;
		hunk_tempactive = true;
		hunk_tempmark = 288;
		break;
	}
}

static void Bench486HunkNamedAllocCapture (void *result,
		bench486_hunk_named_alloc_snapshot_t *snapshot)
{
	memcpy (snapshot->arena, bench486_hunk_named_alloc_arena.bytes,
		sizeof (snapshot->arena));
	snapshot->cache_sentinel = cache_head;
	snapshot->low_used = hunk_low_used;
	snapshot->high_used = hunk_high_used;
	snapshot->temp_active = hunk_tempactive;
	snapshot->temp_mark = hunk_tempmark;
	snapshot->result_offset = result ? (int)((byte *)result - hunk_base) : -1;
#ifdef PROFILE486
	snapshot->low_calls = bench486_hunk_low_calls;
	snapshot->low_bytes = bench486_hunk_low_bytes;
	snapshot->high_calls = bench486_hunk_high_calls;
	snapshot->high_bytes = bench486_hunk_high_bytes;
#endif
}

static void Bench486HunkNamedAllocRun (int is_high, int case_index,
		int use_asm, bench486_hunk_named_alloc_snapshot_t *snapshot)
{
	void *result;
	int size = Bench486HunkNamedAllocSize (case_index);
	char *name = Bench486HunkNamedAllocName (case_index);
	Bench486HunkNamedAllocSetup (is_high, case_index);
	if (is_high)
	{
		if (use_asm)
			result = Hunk_HighAllocName (size, name);
		else
			result = Hunk_HighAllocName_C (size, name);
	}
	else
	{
		if (use_asm)
			result = Hunk_AllocName (size, name);
		else
			result = Hunk_AllocName_C (size, name);
	}
	Bench486HunkNamedAllocCapture (result, snapshot);
}

static int Bench486HunkNamedAllocBytesEqual (const void *left,
		const void *right, unsigned size)
{
	const byte *a = left, *b = right;
	while (size--)
		if (*a++ != *b++) return false;
	return true;
}

int Bench486HunkNamedAllocCases (void)
{
	bench486_hunk_named_alloc_snapshot_t c, a;
	byte *saved_hunk_base = hunk_base;
	int saved_hunk_size = hunk_size;
	int saved_low_used = hunk_low_used;
	int saved_high_used = hunk_high_used;
	qboolean saved_tempactive = hunk_tempactive;
	int saved_tempmark = hunk_tempmark;
	cache_system_t saved_cache_head = cache_head;
	int case_index, is_high, failures = 0;
#ifdef PROFILE486
	unsigned long saved_low_calls = bench486_hunk_low_calls;
	unsigned long saved_low_bytes = bench486_hunk_low_bytes;
	unsigned long saved_high_calls = bench486_hunk_high_calls;
	unsigned long saved_high_bytes = bench486_hunk_high_bytes;
#endif
#if defined(ASM486_SCREEN_CENTER_STRING)
	int saved_trace_active = bench486_screen_center_trace_active;
	bench486_screen_center_trace_active = 0;
#endif

	for (is_high = 0; is_high <= 1; is_high++)
	{
		for (case_index = 0; case_index < BHNA_CASE_COUNT; case_index++)
		{
#ifdef PROFILE486
			bench486_hunk_low_calls = saved_low_calls;
			bench486_hunk_low_bytes = saved_low_bytes;
			bench486_hunk_high_calls = saved_high_calls;
			bench486_hunk_high_bytes = saved_high_bytes;
#endif
			Bench486HunkNamedAllocRun (is_high, case_index, 0, &c);
#ifdef PROFILE486
			bench486_hunk_low_calls = saved_low_calls;
			bench486_hunk_low_bytes = saved_low_bytes;
			bench486_hunk_high_calls = saved_high_calls;
			bench486_hunk_high_bytes = saved_high_bytes;
#endif
			Bench486HunkNamedAllocRun (is_high, case_index, 1, &a);
			if (!Bench486HunkNamedAllocBytesEqual (&c, &a, sizeof (c)))
				failures |= 1 << (is_high * BHNA_CASE_COUNT + case_index);
		}
	}

	hunk_base = saved_hunk_base;
	hunk_size = saved_hunk_size;
	hunk_low_used = saved_low_used;
	hunk_high_used = saved_high_used;
	hunk_tempactive = saved_tempactive;
	hunk_tempmark = saved_tempmark;
	cache_head = saved_cache_head;
#ifdef PROFILE486
	bench486_hunk_low_calls = saved_low_calls;
	bench486_hunk_low_bytes = saved_low_bytes;
	bench486_hunk_high_calls = saved_high_calls;
	bench486_hunk_high_bytes = saved_high_bytes;
#endif
#if defined(ASM486_SCREEN_CENTER_STRING)
	bench486_screen_center_trace_active = saved_trace_active;
#endif
	return failures;
}

#undef BHNA_CASE_COUNT
#undef BHNA_ARENA_SIZE
#endif
