/* Exact C/assembly parity for the zone heap core. */
#if defined(BENCH486) && defined(ASM486_ZONE_HEAP_FIXTURE)
#define BZH_ARENA_SIZE 1024
#define BZH_RESULT_COUNT 8
#define BZH_CASE_COUNT 15

typedef struct bench486_zone_heap_snapshot_s
{
	byte arena[BZH_ARENA_SIZE];
	int result_offsets[BZH_RESULT_COUNT];
#ifdef PROFILE486
	unsigned long scan_iterations;
	unsigned long splits;
	unsigned long coalesces;
	unsigned long failed_allocations;
	unsigned long malloc_calls;
	unsigned long malloc_bytes;
	unsigned long check_calls;
	unsigned long check_blocks;
#endif
	int zero_fill_failures;
} bench486_zone_heap_snapshot_t;

static union
{
	long alignment[4];
	byte bytes[BZH_ARENA_SIZE];
} bench486_zone_heap_arena;

static void Bench486ZoneHeapSetup (int use_asm)
{
	int i;
	for (i = 0; i < BZH_ARENA_SIZE; i++)
		bench486_zone_heap_arena.bytes[i] = (byte)(i * 29 + 11);
	mainzone = (memzone_t *)bench486_zone_heap_arena.bytes;
	mainzone->size = BZH_ARENA_SIZE;
#ifdef PROFILE486
	bench486_zone_scan_iterations = 0;
	bench486_zone_splits = 0;
	bench486_zone_coalesces = 0;
	bench486_zone_failed_allocations = 0;
	bench486_zone_malloc_calls = 0;
	bench486_zone_malloc_bytes = 0;
	bench486_zone_check_calls = 0;
	bench486_zone_check_blocks = 0;
#endif
	if (use_asm)
		Z_ClearZone (mainzone, BZH_ARENA_SIZE);
	else
		Z_ClearZone_C (mainzone, BZH_ARENA_SIZE);
}

static void *Bench486ZoneHeapAlloc (int use_asm, int size, int tag)
{
	return use_asm ? Z_TagMalloc (size, tag) : Z_TagMalloc_C (size, tag);
}

static void *Bench486ZoneHeapMalloc (int use_asm, int size)
{
	return use_asm ? Z_Malloc (size) : Z_Malloc_C (size);
}

static void Bench486ZoneHeapCheckZero (void *buffer, int size,
		int *failures)
{
	const byte *bytes = (const byte *)buffer;
	if (!bytes)
	{
		(*failures)++;
		return;
	}
	while (size--)
		if (*bytes++)
		{
			(*failures)++;
			return;
		}
}

static void Bench486ZoneHeapFree (int use_asm, void *ptr)
{
	if (use_asm)
		Z_Free (ptr);
	else
		Z_Free_C (ptr);
}

static void Bench486ZoneHeapCapture (void **results,
		bench486_zone_heap_snapshot_t *snapshot)
{
	int i;
	memset (snapshot, 0, sizeof (*snapshot));
	memcpy (snapshot->arena, bench486_zone_heap_arena.bytes,
		sizeof (snapshot->arena));
	for (i = 0; i < BZH_RESULT_COUNT; i++)
		snapshot->result_offsets[i] = results[i] ?
			(int)((byte *)results[i] - bench486_zone_heap_arena.bytes) : -1;
#ifdef PROFILE486
	snapshot->scan_iterations = bench486_zone_scan_iterations;
	snapshot->splits = bench486_zone_splits;
	snapshot->coalesces = bench486_zone_coalesces;
	snapshot->failed_allocations = bench486_zone_failed_allocations;
	snapshot->malloc_calls = bench486_zone_malloc_calls;
	snapshot->malloc_bytes = bench486_zone_malloc_bytes;
	snapshot->check_calls = bench486_zone_check_calls;
	snapshot->check_blocks = bench486_zone_check_blocks;
#endif
}

static void Bench486ZoneHeapRun (int case_index, int use_asm,
		bench486_zone_heap_snapshot_t *snapshot)
{
	void *blocks[BZH_RESULT_COUNT];
	int i, zero_fill_failures = 0;

	for (i = 0; i < BZH_RESULT_COUNT; i++)
		blocks[i] = NULL;
	Bench486ZoneHeapSetup (use_asm);

	switch (case_index)
	{
	case 0:
		break;
	case 1:
		blocks[0] = Bench486ZoneHeapAlloc (use_asm, 0, 1);
		blocks[1] = Bench486ZoneHeapAlloc (use_asm, 1, 2);
		blocks[2] = Bench486ZoneHeapAlloc (use_asm, 7, 3);
		blocks[3] = Bench486ZoneHeapAlloc (use_asm, 8, 4);
		blocks[4] = Bench486ZoneHeapAlloc (use_asm, 9, 5);
		blocks[5] = Bench486ZoneHeapAlloc (use_asm, 15, 6);
		blocks[6] = Bench486ZoneHeapAlloc (use_asm, 31, 7);
		break;
	case 2: /* Exactly MINFRAGMENT remains, so the block is not split. */
		blocks[0] = Bench486ZoneHeapAlloc (use_asm, 900, 1);
		break;
	case 3: /* 72 bytes remain, so a free fragment is linked after the block. */
		blocks[0] = Bench486ZoneHeapAlloc (use_asm, 892, 1);
		break;
	case 4: /* Scan the complete list and fail without changing its blocks. */
		blocks[0] = Bench486ZoneHeapAlloc (use_asm, 1000, 1);
		break;
	case 5: /* Skip a too-small tail and reuse the earlier freed fit. */
		blocks[0] = Bench486ZoneHeapAlloc (use_asm, 100, 1);
		blocks[1] = Bench486ZoneHeapAlloc (use_asm, 700, 2);
		Bench486ZoneHeapFree (use_asm, blocks[0]);
		blocks[2] = Bench486ZoneHeapAlloc (use_asm, 100, 3);
		break;
	case 6: /* Freeing the second block merges into the previous free block. */
		blocks[0] = Bench486ZoneHeapAlloc (use_asm, 20, 1);
		blocks[1] = Bench486ZoneHeapAlloc (use_asm, 28, 2);
		blocks[2] = Bench486ZoneHeapAlloc (use_asm, 36, 3);
		Bench486ZoneHeapFree (use_asm, blocks[0]);
		Bench486ZoneHeapFree (use_asm, blocks[1]);
		break;
	case 7: /* Freeing the last block merges its free successor and moves rover. */
		blocks[0] = Bench486ZoneHeapAlloc (use_asm, 20, 1);
		blocks[1] = Bench486ZoneHeapAlloc (use_asm, 28, 2);
		blocks[2] = Bench486ZoneHeapAlloc (use_asm, 36, 3);
		Bench486ZoneHeapFree (use_asm, blocks[2]);
		break;
	case 8: /* Merge previous and next free blocks around the released block. */
		blocks[0] = Bench486ZoneHeapAlloc (use_asm, 10, 1);
		blocks[1] = Bench486ZoneHeapAlloc (use_asm, 18, 2);
		blocks[2] = Bench486ZoneHeapAlloc (use_asm, 26, 3);
		blocks[3] = Bench486ZoneHeapAlloc (use_asm, 34, 4);
		Bench486ZoneHeapFree (use_asm, blocks[1]);
		Bench486ZoneHeapFree (use_asm, blocks[3]);
		Bench486ZoneHeapFree (use_asm, blocks[2]);
		break;
	case 9: /* Rover is allowed to point at an allocated block. */
		blocks[0] = Bench486ZoneHeapAlloc (use_asm, 20, 1);
		blocks[1] = Bench486ZoneHeapAlloc (use_asm, 28, 2);
		blocks[2] = Bench486ZoneHeapAlloc (use_asm, 36, 3);
		Bench486ZoneHeapFree (use_asm, blocks[0]);
		mainzone->rover = (memblock_t *)((byte *)blocks[1] - sizeof (memblock_t));
		Bench486ZoneHeapFree (use_asm, blocks[1]);
		break;
	case 10:
		blocks[0] = Bench486ZoneHeapMalloc (use_asm, 1);
		Bench486ZoneHeapCheckZero (blocks[0], 1, &zero_fill_failures);
		break;
	case 11:
		blocks[0] = Bench486ZoneHeapMalloc (use_asm, 8);
		Bench486ZoneHeapCheckZero (blocks[0], 8, &zero_fill_failures);
		break;
	case 12:
		blocks[0] = Bench486ZoneHeapMalloc (use_asm, 31);
		blocks[1] = Bench486ZoneHeapMalloc (use_asm, 64);
		Bench486ZoneHeapCheckZero (blocks[0], 31, &zero_fill_failures);
		Bench486ZoneHeapCheckZero (blocks[1], 64, &zero_fill_failures);
		break;
	case 13:
		blocks[0] = Bench486ZoneHeapMalloc (use_asm, 64);
		if (blocks[0])
			memset (blocks[0], 0x6d, 64);
		Bench486ZoneHeapFree (use_asm, blocks[0]);
		blocks[1] = Bench486ZoneHeapMalloc (use_asm, 32);
		Bench486ZoneHeapCheckZero (blocks[1], 32, &zero_fill_failures);
		break;
	case 14:
		blocks[0] = Bench486ZoneHeapMalloc (use_asm, 5);
		blocks[1] = Bench486ZoneHeapMalloc (use_asm, 72);
		if (blocks[0])
		{
			memset (blocks[0], 0xa7, 5);
			mainzone->rover = (memblock_t *)((byte *)blocks[0] -
				sizeof (memblock_t));
		}
		if (blocks[1])
			memset (blocks[1], 0xb8, 72);
		Bench486ZoneHeapFree (use_asm, blocks[0]);
		blocks[2] = Bench486ZoneHeapMalloc (use_asm, 5);
		blocks[3] = Bench486ZoneHeapMalloc (use_asm, 32);
		Bench486ZoneHeapCheckZero (blocks[2], 5, &zero_fill_failures);
		Bench486ZoneHeapCheckZero (blocks[3], 32, &zero_fill_failures);
		break;
	}

	Bench486ZoneHeapCapture (blocks, snapshot);
	snapshot->zero_fill_failures = zero_fill_failures;
}

static int Bench486ZoneHeapBytesEqual (const void *left, const void *right,
		unsigned size)
{
	const byte *a = left, *b = right;
	while (size--)
		if (*a++ != *b++) return false;
	return true;
}

int Bench486ZoneHeapCases (void)
{
	bench486_zone_heap_snapshot_t c, a;
	memzone_t *saved_mainzone = mainzone;
	int case_index, failures = 0;
#ifdef PROFILE486
	unsigned long saved_scan_iterations = bench486_zone_scan_iterations;
	unsigned long saved_splits = bench486_zone_splits;
	unsigned long saved_coalesces = bench486_zone_coalesces;
	unsigned long saved_failed_allocations = bench486_zone_failed_allocations;
	unsigned long saved_malloc_calls = bench486_zone_malloc_calls;
	unsigned long saved_malloc_bytes = bench486_zone_malloc_bytes;
	unsigned long saved_check_calls = bench486_zone_check_calls;
	unsigned long saved_check_blocks = bench486_zone_check_blocks;
#endif

	for (case_index = 0; case_index < BZH_CASE_COUNT; case_index++)
	{
		Bench486ZoneHeapRun (case_index, 0, &c);
		Bench486ZoneHeapRun (case_index, 1, &a);
		if (c.zero_fill_failures || a.zero_fill_failures ||
				!Bench486ZoneHeapBytesEqual (&c, &a, sizeof (c)))
			failures |= 1 << case_index;
	}

	mainzone = saved_mainzone;
#ifdef PROFILE486
	bench486_zone_scan_iterations = saved_scan_iterations;
	bench486_zone_splits = saved_splits;
	bench486_zone_coalesces = saved_coalesces;
	bench486_zone_failed_allocations = saved_failed_allocations;
	bench486_zone_malloc_calls = saved_malloc_calls;
	bench486_zone_malloc_bytes = saved_malloc_bytes;
	bench486_zone_check_calls = saved_check_calls;
	bench486_zone_check_blocks = saved_check_blocks;
#endif
	return failures;
}

#undef BZH_CASE_COUNT
#undef BZH_RESULT_COUNT
#undef BZH_ARENA_SIZE
#endif
