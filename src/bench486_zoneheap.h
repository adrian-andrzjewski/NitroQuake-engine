/* Exact C/assembly parity for the zone heap core. */
#if defined(BENCH486) && defined(ASM486_ZONE_HEAP_FIXTURE)
#define BZH_ARENA_SIZE 1024
#define BZH_RESULT_COUNT 8
#define BZH_CASE_COUNT 15
#define BZH_MEMORY_SIZE 65536
#define BZH_COMMAND_NAME_SIZE 16
#define BZH_ERROR_COUNT 4
#define BZH_ERROR_SIZE 80
#define BZH_HUNK_CHECK_SIZE 128
#define BZH_PRINT_EVENT_COUNT 64

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

typedef struct bench486_zone_init_snapshot_s
{
	cache_system_t cache_head;
	int command_count;
	char command_name[BZH_COMMAND_NAME_SIZE];
	xcommand_t command_function;
} bench486_zone_init_snapshot_t;

typedef struct bench486_memory_init_snapshot_s
{
	byte arena[BZH_MEMORY_SIZE];
	byte *hunk_base;
	int hunk_size;
	int hunk_low_used;
	int hunk_high_used;
	memzone_t *mainzone;
	cache_system_t cache_head;
	int command_count;
	char command_name[BZH_COMMAND_NAME_SIZE];
	xcommand_t command_function;
#ifdef PROFILE486
	unsigned long hunk_low_calls;
	unsigned long hunk_low_bytes;
#endif
} bench486_memory_init_snapshot_t;

typedef struct bench486_checker_snapshot_s
{
	byte arena[BZH_ARENA_SIZE];
	int error_count;
	char errors[BZH_ERROR_COUNT][BZH_ERROR_SIZE];
#ifdef PROFILE486
	unsigned long check_calls;
	unsigned long check_blocks;
#endif
} bench486_checker_snapshot_t;

typedef struct bench486_hunk_checker_snapshot_s
{
	byte arena[BZH_HUNK_CHECK_SIZE];
	int hunk_size;
	int hunk_low_used;
	int error_count;
	char errors[BZH_ERROR_COUNT][BZH_ERROR_SIZE];
} bench486_hunk_checker_snapshot_t;

typedef struct bench486_zone_print_event_s
{
	int kind;
	memzone_t *zone;
	memblock_t *block;
	int zone_size;
	int block_size;
	int block_tag;
} bench486_zone_print_event_t;

typedef struct bench486_zone_print_snapshot_s
{
	int event_count;
	bench486_zone_print_event_t events[BZH_PRINT_EVENT_COUNT];
} bench486_zone_print_snapshot_t;

typedef struct bench486_cache_lru_snapshot_s
{
	cache_system_t head;
	cache_system_t nodes[2];
	int error_count;
	char errors[BZH_ERROR_COUNT][BZH_ERROR_SIZE];
} bench486_cache_lru_snapshot_t;

static union
{
	long alignment[4];
	byte bytes[BZH_MEMORY_SIZE];
} bench486_memory_init_arena;
static bench486_zone_init_snapshot_t bench486_zone_init_c;
static bench486_zone_init_snapshot_t bench486_zone_init_asm;
static bench486_memory_init_snapshot_t bench486_memory_init_c;
static bench486_memory_init_snapshot_t bench486_memory_init_asm;
static cache_system_t bench486_cache_lru_nodes[2];
static int bench486_memory_add_command_count;
static char bench486_memory_add_command_name[BZH_COMMAND_NAME_SIZE];
static xcommand_t bench486_memory_add_command_function;
static int bench486_zone_heap_error_count;
static char bench486_zone_heap_errors[BZH_ERROR_COUNT][BZH_ERROR_SIZE];
static int bench486_zone_print_event_count;
static bench486_zone_print_event_t
	bench486_zone_print_events[BZH_PRINT_EVENT_COUNT];

void Bench486MemoryAddCommand (char *cmd_name, xcommand_t function)
{
	int i;
	bench486_memory_add_command_count++;
	for (i = 0; i < BZH_COMMAND_NAME_SIZE - 1 && cmd_name[i]; i++)
		bench486_memory_add_command_name[i] = cmd_name[i];
	bench486_memory_add_command_name[i] = 0;
	while (++i < BZH_COMMAND_NAME_SIZE)
		bench486_memory_add_command_name[i] = 0;
	bench486_memory_add_command_function = function;
}

void Bench486ZoneHeapError (char *message)
{
	int slot = bench486_zone_heap_error_count++;
	int i;
	if (slot < 0 || slot >= BZH_ERROR_COUNT)
		return;
	for (i = 0; i < BZH_ERROR_SIZE - 1 && message[i]; i++)
		bench486_zone_heap_errors[slot][i] = message[i];
	bench486_zone_heap_errors[slot][i] = 0;
	while (++i < BZH_ERROR_SIZE)
		bench486_zone_heap_errors[slot][i] = 0;
}

void Bench486ZonePrintEvent (int kind, memzone_t *zone, memblock_t *block)
{
	int slot = bench486_zone_print_event_count++;
	bench486_zone_print_event_t *event;
	if (slot < 0 || slot >= BZH_PRINT_EVENT_COUNT)
		return;
	event = &bench486_zone_print_events[slot];
	memset (event, 0, sizeof (*event));
	event->kind = kind;
	event->zone = zone;
	event->block = block;
	if (zone)
		event->zone_size = zone->size;
	if (block)
	{
		event->block_size = block->size;
		event->block_tag = block->tag;
	}
}

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

static void Bench486ZoneCacheInitRun (int use_asm,
		bench486_zone_init_snapshot_t *snapshot)
{
	memset (&cache_head, 0xa5, sizeof (cache_head));
	bench486_memory_add_command_count = 0;
	memset (bench486_memory_add_command_name, 0,
		sizeof (bench486_memory_add_command_name));
	bench486_memory_add_command_function = NULL;
	if (use_asm)
		Cache_Init ();
	else
		Cache_Init_C ();
	snapshot->cache_head = cache_head;
	snapshot->command_count = bench486_memory_add_command_count;
	Q_memcpy (snapshot->command_name, bench486_memory_add_command_name,
		sizeof (snapshot->command_name));
	snapshot->command_function = bench486_memory_add_command_function;
}

static void Bench486MemoryInitRun (int use_asm, int use_zone_argument,
		bench486_memory_init_snapshot_t *snapshot)
{
	static char *default_argv[1] = { "quake" };
	static char *zone_argv[3] = { "quake", "-zone", "32" };
	int i;

	for (i = 0; i < BZH_MEMORY_SIZE; i++)
		bench486_memory_init_arena.bytes[i] = (byte)(i * 17 + 3);
	hunk_base = NULL;
	hunk_size = 0x13579;
	hunk_low_used = 123;
	hunk_high_used = 321;
	mainzone = NULL;
	memset (&cache_head, 0xa5, sizeof (cache_head));
	bench486_memory_add_command_count = 0;
	memset (bench486_memory_add_command_name, 0,
		sizeof (bench486_memory_add_command_name));
	bench486_memory_add_command_function = NULL;
	if (use_zone_argument)
	{
		com_argc = 3;
		com_argv = zone_argv;
	}
	else
	{
		com_argc = 1;
		com_argv = default_argv;
	}
#ifdef PROFILE486
	bench486_hunk_low_calls = 0;
	bench486_hunk_low_bytes = 0;
#endif
	if (use_asm)
		Memory_Init (bench486_memory_init_arena.bytes, BZH_MEMORY_SIZE);
	else
		Memory_Init_C (bench486_memory_init_arena.bytes, BZH_MEMORY_SIZE);

	Q_memcpy (snapshot->arena, bench486_memory_init_arena.bytes,
		sizeof (snapshot->arena));
	snapshot->hunk_base = hunk_base;
	snapshot->hunk_size = hunk_size;
	snapshot->hunk_low_used = hunk_low_used;
	snapshot->hunk_high_used = hunk_high_used;
	snapshot->mainzone = mainzone;
	snapshot->cache_head = cache_head;
	snapshot->command_count = bench486_memory_add_command_count;
	Q_memcpy (snapshot->command_name, bench486_memory_add_command_name,
		sizeof (snapshot->command_name));
	snapshot->command_function = bench486_memory_add_command_function;
#ifdef PROFILE486
	snapshot->hunk_low_calls = bench486_hunk_low_calls;
	snapshot->hunk_low_bytes = bench486_hunk_low_bytes;
#endif
}

static int Bench486ZoneHeapExpectedError (
		const bench486_checker_snapshot_t *snapshot, const char *expected)
{
	int i;
	if (snapshot->error_count != (expected ? 1 : 0))
		return false;
	if (!expected)
		return true;
	for (i = 0; i < BZH_ERROR_SIZE; i++)
	{
		if (snapshot->errors[0][i] != expected[i])
			return false;
		if (!expected[i])
			return true;
	}
	return false;
}

static void Bench486ZoneHeapCheckRun (int case_index, int use_asm,
		bench486_checker_snapshot_t *snapshot)
{
	void *payload;
	memblock_t *sentinel, *first, *second;
	int old_size;

	Bench486ZoneHeapSetup (0);
	bench486_zone_heap_error_count = 0;
	memset (bench486_zone_heap_errors, 0,
		sizeof (bench486_zone_heap_errors));
	switch (case_index)
	{
	case 0: /* The cleared zone has one valid free block. */
		break;
	case 1: /* A tagged allocation followed by a free block is valid. */
		Z_TagMalloc_C (8, 1);
		break;
	case 2: /* The block size no longer reaches its next block. */
		payload = Z_TagMalloc_C (8, 1);
		if (payload)
		{
			first = (memblock_t *)((byte *)payload - sizeof (memblock_t));
			first->size++;
		}
		break;
	case 3: /* The next block has an invalid backlink. */
		payload = Z_TagMalloc_C (8, 1);
		if (payload)
		{
			first = (memblock_t *)((byte *)payload - sizeof (memblock_t));
			first->next->prev = &mainzone->blocklist;
		}
		break;
	case 4: /* Two adjacent free blocks violate zone coalescing. */
		sentinel = &mainzone->blocklist;
		first = sentinel->next;
		old_size = first->size;
		second = (memblock_t *)((byte *)first + 128);
		first->size = 128;
		first->next = second;
		second->size = old_size - 128;
		second->tag = 0;
		second->id = ZONEID;
		second->prev = first;
		second->next = sentinel;
		sentinel->prev = second;
		mainzone->rover = first;
		break;
	}
	if (use_asm)
		Z_CheckHeap ();
	else
		Z_CheckHeap_C ();

	memset (snapshot, 0, sizeof (*snapshot));
	Q_memcpy (snapshot->arena, bench486_zone_heap_arena.bytes,
		sizeof (snapshot->arena));
	snapshot->error_count = bench486_zone_heap_error_count;
	Q_memcpy (snapshot->errors, bench486_zone_heap_errors,
		sizeof (snapshot->errors));
#ifdef PROFILE486
	snapshot->check_calls = bench486_zone_check_calls;
	snapshot->check_blocks = bench486_zone_check_blocks;
#endif
}

static int Bench486ZoneStructureCheckerCases (void)
{
	static const char *expected[] = {
		NULL,
		NULL,
		"Z_CheckHeap: block size does not touch the next block\n",
		"Z_CheckHeap: next block doesn't have proper back link\n",
		"Z_CheckHeap: two consecutive free blocks\n"
	};
	bench486_checker_snapshot_t c, a;
	memzone_t *saved_mainzone = mainzone;
	int case_index, failures = 0;
	int saved_error_count = bench486_zone_heap_error_count;
	char saved_errors[BZH_ERROR_COUNT][BZH_ERROR_SIZE];
#ifdef PROFILE486
	unsigned long saved_check_calls = bench486_zone_check_calls;
	unsigned long saved_check_blocks = bench486_zone_check_blocks;
#endif
	Q_memcpy (saved_errors, bench486_zone_heap_errors, sizeof (saved_errors));
	for (case_index = 0; case_index < 5; case_index++)
	{
		Bench486ZoneHeapCheckRun (case_index, 0, &c);
		Bench486ZoneHeapCheckRun (case_index, 1, &a);
		if (!Bench486ZoneHeapBytesEqual (&c, &a, sizeof (c)) ||
				!Bench486ZoneHeapExpectedError (&c, expected[case_index]) ||
				!Bench486ZoneHeapExpectedError (&a, expected[case_index]))
			failures |= 1 << (18 + case_index);
	}
	mainzone = saved_mainzone;
	bench486_zone_heap_error_count = saved_error_count;
	Q_memcpy (bench486_zone_heap_errors, saved_errors, sizeof (saved_errors));
#ifdef PROFILE486
	bench486_zone_check_calls = saved_check_calls;
	bench486_zone_check_blocks = saved_check_blocks;
#endif
	return failures;
}

static int Bench486HunkCheckExpectedError (
		const bench486_hunk_checker_snapshot_t *snapshot,
		const char *expected)
{
	int i;
	if (snapshot->error_count != (expected ? 1 : 0))
		return false;
	if (!expected)
		return true;
	for (i = 0; i < BZH_ERROR_SIZE; i++)
	{
		if (snapshot->errors[0][i] != expected[i])
			return false;
		if (!expected[i])
			return true;
	}
	return false;
}

static void Bench486HunkCheckRun (int case_index, int use_asm,
		bench486_hunk_checker_snapshot_t *snapshot)
{
	hunk_t *hunk;
	int i;
	for (i = 0; i < BZH_HUNK_CHECK_SIZE; i++)
		bench486_memory_init_arena.bytes[i] = (byte)(i * 23 + 7);
	hunk_base = bench486_memory_init_arena.bytes;
	hunk_size = 64;
	hunk_low_used = 0;
	hunk_high_used = 0;
	bench486_zone_heap_error_count = 0;
	memset (bench486_zone_heap_errors, 0,
		sizeof (bench486_zone_heap_errors));
	hunk = (hunk_t *)hunk_base;
	switch (case_index)
	{
	case 0: /* No low hunk records. */
		break;
	case 1:
		hunk->sentinal = HUNK_SENTINAL;
		hunk->size = 16;
		hunk_low_used = 16;
		break;
	case 2:
		hunk[0].sentinal = HUNK_SENTINAL;
		hunk[0].size = 16;
		hunk[1].sentinal = HUNK_SENTINAL;
		hunk[1].size = 16;
		hunk_low_used = 32;
		break;
	case 3:
		hunk->sentinal = 0;
		hunk->size = 16;
		hunk_low_used = 16;
		break;
	case 4:
		hunk->sentinal = HUNK_SENTINAL;
		hunk->size = 8;
		hunk_low_used = 8;
		break;
	case 5:
		hunk->sentinal = HUNK_SENTINAL;
		hunk->size = 80;
		hunk_low_used = 80;
		break;
	}
	if (use_asm)
		Hunk_Check ();
	else
		Hunk_Check_C ();

	memset (snapshot, 0, sizeof (*snapshot));
	Q_memcpy (snapshot->arena, bench486_memory_init_arena.bytes,
		sizeof (snapshot->arena));
	snapshot->hunk_size = hunk_size;
	snapshot->hunk_low_used = hunk_low_used;
	snapshot->error_count = bench486_zone_heap_error_count;
	Q_memcpy (snapshot->errors, bench486_zone_heap_errors,
		sizeof (snapshot->errors));
}

static int Bench486HunkCheckerCases (void)
{
	static const char *expected[] = {
		NULL,
		NULL,
		NULL,
		"Hunk_Check: trahsed sentinal",
		"Hunk_Check: bad size",
		"Hunk_Check: bad size"
	};
	bench486_hunk_checker_snapshot_t c, a;
	byte *saved_hunk_base = hunk_base;
	int saved_hunk_size = hunk_size;
	int saved_hunk_low_used = hunk_low_used;
	int saved_hunk_high_used = hunk_high_used;
	int saved_error_count = bench486_zone_heap_error_count;
	char saved_errors[BZH_ERROR_COUNT][BZH_ERROR_SIZE];
	int case_index, failures = 0;
	Q_memcpy (saved_errors, bench486_zone_heap_errors, sizeof (saved_errors));
	for (case_index = 0; case_index < 6; case_index++)
	{
		Bench486HunkCheckRun (case_index, 0, &c);
		Bench486HunkCheckRun (case_index, 1, &a);
		if (!Bench486ZoneHeapBytesEqual (&c, &a, sizeof (c)) ||
				!Bench486HunkCheckExpectedError (&c, expected[case_index]) ||
				!Bench486HunkCheckExpectedError (&a, expected[case_index]))
			failures |= 1 << (23 + case_index);
	}
	hunk_base = saved_hunk_base;
	hunk_size = saved_hunk_size;
	hunk_low_used = saved_hunk_low_used;
	hunk_high_used = saved_hunk_high_used;
	bench486_zone_heap_error_count = saved_error_count;
	Q_memcpy (bench486_zone_heap_errors, saved_errors, sizeof (saved_errors));
	return failures;
}

static int Bench486ZoneHeapCheckerCases (void);

static void Bench486CacheLruRun (int case_index, int use_asm,
		bench486_cache_lru_snapshot_t *snapshot)
{
	cache_system_t *node = &bench486_cache_lru_nodes[0];
	memset (&cache_head, 0, sizeof (cache_head));
	memset (bench486_cache_lru_nodes, 0, sizeof (bench486_cache_lru_nodes));
	bench486_zone_heap_error_count = 0;
	memset (bench486_zone_heap_errors, 0,
		sizeof (bench486_zone_heap_errors));
	switch (case_index)
	{
	case 0: /* Unlink one node and repair the empty-list sentinel. */
		cache_head.lru_next = node;
		cache_head.lru_prev = node;
		node->lru_prev = &cache_head;
		node->lru_next = &cache_head;
		if (use_asm)
			Cache_UnlinkLRU (node);
		else
			Cache_UnlinkLRU_C (node);
		break;
	case 1: /* Reject a node with a missing forward link. */
		node->lru_prev = &cache_head;
		if (use_asm)
			Cache_UnlinkLRU (node);
		else
			Cache_UnlinkLRU_C (node);
		break;
	case 2: /* Promote a node, then reject the already active link. */
		cache_head.lru_next = &cache_head;
		cache_head.lru_prev = &cache_head;
		if (use_asm)
		{
			Cache_MakeLRU (node);
			Cache_MakeLRU (node);
		}
		else
		{
			Cache_MakeLRU_C (node);
			Cache_MakeLRU_C (node);
		}
		break;
	}
	memset (snapshot, 0, sizeof (*snapshot));
	snapshot->head = cache_head;
	Q_memcpy (snapshot->nodes, bench486_cache_lru_nodes,
		sizeof (snapshot->nodes));
	snapshot->error_count = bench486_zone_heap_error_count;
	Q_memcpy (snapshot->errors, bench486_zone_heap_errors,
		sizeof (snapshot->errors));
}

static int Bench486CacheLruExpectedError (
		const bench486_cache_lru_snapshot_t *snapshot, const char *expected)
{
	int i;
	if (snapshot->error_count != (expected ? 1 : 0))
		return false;
	if (!expected)
		return true;
	for (i = 0; i < BZH_ERROR_SIZE; i++)
	{
		if (snapshot->errors[0][i] != expected[i])
			return false;
		if (!expected[i])
			return true;
	}
	return false;
}

static int Bench486CacheLruCases (void)
{
	static const char *expected[] = {
		NULL,
		"Cache_UnlinkLRU: NULL link",
		"Cache_MakeLRU: active link"
	};
	bench486_cache_lru_snapshot_t c, a;
	cache_system_t saved_head = cache_head;
	cache_system_t saved_nodes[2];
	int saved_error_count = bench486_zone_heap_error_count;
	char saved_errors[BZH_ERROR_COUNT][BZH_ERROR_SIZE];
	int case_index, failures = 0;
	Q_memcpy (saved_nodes, bench486_cache_lru_nodes, sizeof (saved_nodes));
	Q_memcpy (saved_errors, bench486_zone_heap_errors, sizeof (saved_errors));
	for (case_index = 0; case_index < 3; case_index++)
	{
		Bench486CacheLruRun (case_index, 0, &c);
		Bench486CacheLruRun (case_index, 1, &a);
		if (!Bench486ZoneHeapBytesEqual (&c, &a, sizeof (c)) ||
				!Bench486CacheLruExpectedError (&c, expected[case_index]) ||
				!Bench486CacheLruExpectedError (&a, expected[case_index]))
			failures |= 1 << (29 + case_index);
	}
	cache_head = saved_head;
	Q_memcpy (bench486_cache_lru_nodes, saved_nodes, sizeof (saved_nodes));
	bench486_zone_heap_error_count = saved_error_count;
	Q_memcpy (bench486_zone_heap_errors, saved_errors, sizeof (saved_errors));
	return failures;
}

static void Bench486ZonePrintRun (int case_index, int use_asm,
		bench486_zone_print_snapshot_t *snapshot)
{
	void *blocks[3];
	memblock_t *sentinel, *first, *second;
	int i, old_size;

	for (i = 0; i < 3; i++)
		blocks[i] = NULL;
	Bench486ZoneHeapSetup (0);
	switch (case_index)
	{
	case 0:
		break;
	case 1:
	case 2:
	case 3:
	case 4:
		blocks[0] = Z_TagMalloc_C (16, 1);
		blocks[1] = Z_TagMalloc_C (24, 2);
		blocks[2] = Z_TagMalloc_C (32, 3);
		if (case_index == 2)
			Z_Free_C (blocks[1]);
		else if (case_index == 3 && blocks[0])
		{
			first = (memblock_t *)((byte *)blocks[0] - sizeof (memblock_t));
			first->size++;
		}
		else if (case_index == 4 && blocks[0])
		{
			first = (memblock_t *)((byte *)blocks[0] - sizeof (memblock_t));
			first->next->prev = &mainzone->blocklist;
		}
		break;
	case 5:
		sentinel = &mainzone->blocklist;
		first = sentinel->next;
		old_size = first->size;
		second = (memblock_t *)((byte *)first + 128);
		first->size = 128;
		first->next = second;
		second->size = old_size - 128;
		second->tag = 0;
		second->id = ZONEID;
		second->prev = first;
		second->next = sentinel;
		sentinel->prev = second;
		mainzone->rover = first;
		break;
	}

	bench486_zone_print_event_count = 0;
	memset (bench486_zone_print_events, 0,
		sizeof (bench486_zone_print_events));
	if (use_asm)
		Z_Print (mainzone);
	else
		Z_Print_C (mainzone);

	memset (snapshot, 0, sizeof (*snapshot));
	snapshot->event_count = bench486_zone_print_event_count;
	Q_memcpy (snapshot->events, bench486_zone_print_events,
		sizeof (snapshot->events));
}

static int Bench486ZonePrintCases (void)
{
	static const int expected_count[] = { 2, 5, 5, 6, 6, 4 };
	static const int expected_kind[6][6] = {
		{ ZH_PRINT_ZONE_HEADER, ZH_PRINT_ZONE_BLOCK, 0, 0, 0, 0 },
		{ ZH_PRINT_ZONE_HEADER, ZH_PRINT_ZONE_BLOCK, ZH_PRINT_ZONE_BLOCK,
			ZH_PRINT_ZONE_BLOCK, ZH_PRINT_ZONE_BLOCK, 0 },
		{ ZH_PRINT_ZONE_HEADER, ZH_PRINT_ZONE_BLOCK, ZH_PRINT_ZONE_BLOCK,
			ZH_PRINT_ZONE_BLOCK, ZH_PRINT_ZONE_BLOCK, 0 },
		{ ZH_PRINT_ZONE_HEADER, ZH_PRINT_ZONE_BLOCK,
			ZH_PRINT_ZONE_BAD_BOUNDARY, ZH_PRINT_ZONE_BLOCK,
			ZH_PRINT_ZONE_BLOCK, ZH_PRINT_ZONE_BLOCK },
		{ ZH_PRINT_ZONE_HEADER, ZH_PRINT_ZONE_BLOCK,
			ZH_PRINT_ZONE_BAD_BACKLINK, ZH_PRINT_ZONE_BLOCK,
			ZH_PRINT_ZONE_BLOCK, ZH_PRINT_ZONE_BLOCK },
		{ ZH_PRINT_ZONE_HEADER, ZH_PRINT_ZONE_BLOCK,
			ZH_PRINT_ZONE_ADJACENT_FREE, ZH_PRINT_ZONE_BLOCK, 0, 0 }
	};
	bench486_zone_print_snapshot_t c, a;
	memzone_t *saved_mainzone = mainzone;
	int case_index, i, failed = false;
	for (case_index = 0; case_index < 6; case_index++)
	{
		Bench486ZonePrintRun (case_index, 0, &c);
		Bench486ZonePrintRun (case_index, 1, &a);
		if (!Bench486ZoneHeapBytesEqual (&c, &a, sizeof (c)) ||
				c.event_count != expected_count[case_index])
			failed = true;
		for (i = 0; i < expected_count[case_index]; i++)
			if (c.events[i].kind != expected_kind[case_index][i] ||
					a.events[i].kind != expected_kind[case_index][i])
				failed = true;
	}
	mainzone = saved_mainzone;
	bench486_zone_print_event_count = 0;
	memset (bench486_zone_print_events, 0,
		sizeof (bench486_zone_print_events));
	return failed ? (int)0x80000000UL : 0;
}

static int Bench486ZoneHeapCheckerCases (void)
{
	return Bench486ZoneStructureCheckerCases () |
		Bench486HunkCheckerCases () | Bench486CacheLruCases ();
}

static int Bench486ZoneMemoryInitCases (void)
{
	byte *saved_hunk_base = hunk_base;
	int saved_hunk_size = hunk_size;
	int saved_hunk_low_used = hunk_low_used;
	int saved_hunk_high_used = hunk_high_used;
	memzone_t *saved_mainzone = mainzone;
	cache_system_t saved_cache_head = cache_head;
	int saved_com_argc = com_argc;
	char **saved_com_argv = com_argv;
	int saved_command_count = bench486_memory_add_command_count;
	char saved_command_name[BZH_COMMAND_NAME_SIZE];
	xcommand_t saved_command_function = bench486_memory_add_command_function;
	int failures = 0;
#ifdef PROFILE486
	unsigned long saved_hunk_low_calls = bench486_hunk_low_calls;
	unsigned long saved_hunk_low_bytes = bench486_hunk_low_bytes;
#endif
	Q_memcpy (saved_command_name, bench486_memory_add_command_name,
		sizeof (saved_command_name));

	Bench486ZoneCacheInitRun (0, &bench486_zone_init_c);
	Bench486ZoneCacheInitRun (1, &bench486_zone_init_asm);
	if (Q_memcmp (&bench486_zone_init_c, &bench486_zone_init_asm,
			sizeof (bench486_zone_init_c)) ||
			bench486_zone_init_c.command_count != 1 ||
			Q_memcmp (bench486_zone_init_c.command_name, "flush", 6) ||
			bench486_zone_init_c.command_function != Cache_Flush)
		failures |= 1 << 15;

	Bench486MemoryInitRun (0, 0, &bench486_memory_init_c);
	Bench486MemoryInitRun (1, 0, &bench486_memory_init_asm);
	if (Q_memcmp (&bench486_memory_init_c, &bench486_memory_init_asm,
			sizeof (bench486_memory_init_c)) ||
			bench486_memory_init_c.command_count != 1 ||
			Q_memcmp (bench486_memory_init_c.command_name, "flush", 6) ||
			bench486_memory_init_c.command_function != Cache_Flush ||
			bench486_memory_init_c.hunk_low_used <= 0)
		failures |= 1 << 16;

	Bench486MemoryInitRun (0, 1, &bench486_memory_init_c);
	Bench486MemoryInitRun (1, 1, &bench486_memory_init_asm);
	if (Q_memcmp (&bench486_memory_init_c, &bench486_memory_init_asm,
			sizeof (bench486_memory_init_c)) ||
			bench486_memory_init_c.command_count != 1 ||
			Q_memcmp (bench486_memory_init_c.command_name, "flush", 6) ||
			bench486_memory_init_c.command_function != Cache_Flush ||
			bench486_memory_init_c.hunk_low_used <= 0)
		failures |= 1 << 17;

	hunk_base = saved_hunk_base;
	hunk_size = saved_hunk_size;
	hunk_low_used = saved_hunk_low_used;
	hunk_high_used = saved_hunk_high_used;
	mainzone = saved_mainzone;
	cache_head = saved_cache_head;
	com_argc = saved_com_argc;
	com_argv = saved_com_argv;
	bench486_memory_add_command_count = saved_command_count;
	Q_memcpy (bench486_memory_add_command_name, saved_command_name,
		sizeof (saved_command_name));
	bench486_memory_add_command_function = saved_command_function;
#ifdef PROFILE486
	bench486_hunk_low_calls = saved_hunk_low_calls;
	bench486_hunk_low_bytes = saved_hunk_low_bytes;
#endif
	return failures;
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
	failures |= Bench486ZoneHeapCheckerCases ();
	failures |= Bench486ZonePrintCases ();

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
	failures |= Bench486ZoneMemoryInitCases ();
	return failures;
}

#undef BZH_CASE_COUNT
#undef BZH_HUNK_CHECK_SIZE
#undef BZH_PRINT_EVENT_COUNT
#undef BZH_ERROR_SIZE
#undef BZH_ERROR_COUNT
#undef BZH_COMMAND_NAME_SIZE
#undef BZH_MEMORY_SIZE
#undef BZH_RESULT_COUNT
#undef BZH_ARENA_SIZE
#endif
