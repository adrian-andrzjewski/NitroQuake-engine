/* Exact C/assembly parity for the zone heap core. */
#if defined(BENCH486) && defined(ASM486_ZONE_HEAP_FIXTURE)
#define BZH_ARENA_SIZE 1024
#define BZH_RESULT_COUNT 8
#define BZH_CASE_COUNT 10

typedef struct bench486_zone_heap_snapshot_s
{
	byte arena[BZH_ARENA_SIZE];
	int result_offsets[BZH_RESULT_COUNT];
#ifdef PROFILE486
	unsigned long scan_iterations;
	unsigned long splits;
	unsigned long coalesces;
	unsigned long failed_allocations;
#endif
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
#endif
}

static void Bench486ZoneHeapRun (int case_index, int use_asm,
		bench486_zone_heap_snapshot_t *snapshot)
{
	void *blocks[BZH_RESULT_COUNT];
	int i;

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
	default: /* Rover is allowed to point at an allocated block. */
		blocks[0] = Bench486ZoneHeapAlloc (use_asm, 20, 1);
		blocks[1] = Bench486ZoneHeapAlloc (use_asm, 28, 2);
		blocks[2] = Bench486ZoneHeapAlloc (use_asm, 36, 3);
		Bench486ZoneHeapFree (use_asm, blocks[0]);
		mainzone->rover = (memblock_t *)((byte *)blocks[1] - sizeof (memblock_t));
		Bench486ZoneHeapFree (use_asm, blocks[1]);
		break;
	}

	Bench486ZoneHeapCapture (blocks, snapshot);
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
#endif

	for (case_index = 0; case_index < BZH_CASE_COUNT; case_index++)
	{
		Bench486ZoneHeapRun (case_index, 0, &c);
		Bench486ZoneHeapRun (case_index, 1, &a);
		if (!Bench486ZoneHeapBytesEqual (&c, &a, sizeof (c)))
			failures |= 1 << case_index;
	}

	mainzone = saved_mainzone;
#ifdef PROFILE486
	bench486_zone_scan_iterations = saved_scan_iterations;
	bench486_zone_splits = saved_splits;
	bench486_zone_coalesces = saved_coalesces;
	bench486_zone_failed_allocations = saved_failed_allocations;
#endif
	return failures;
}

#undef BZH_CASE_COUNT
#undef BZH_RESULT_COUNT
#undef BZH_ARENA_SIZE
#endif
