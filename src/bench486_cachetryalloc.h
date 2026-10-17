/* Direct Cache_TryAlloc C/assembly parity over bounded hunk layouts. */
#if defined(BENCH486) && defined(ASM486_CACHE_TRY_ALLOC_FIXTURE)
typedef struct bench486_cache_tryalloc_snapshot_s
{
	int result_offset;
	cache_system_t head;
	byte arena[512];
#ifdef PROFILE486
	unsigned long scans;
	unsigned long failures;
#endif
} bench486_cache_tryalloc_snapshot_t;

static union
{
	long alignment[4];
	byte bytes[512];
} bench486_cache_tryalloc_arena;

static void Bench486CacheTryAllocInitNode (cache_system_t *node, int size)
{
	memset (node, 0, sizeof (*node));
	node->size = size;
}

static void Bench486CacheTryAllocSetup (int layout)
{
	cache_system_t *first, *second;

	memset (bench486_cache_tryalloc_arena.bytes, 0xcd,
			sizeof (bench486_cache_tryalloc_arena.bytes));
	hunk_base = bench486_cache_tryalloc_arena.bytes;
	hunk_size = sizeof (bench486_cache_tryalloc_arena.bytes);
	hunk_low_used = 64;
	hunk_high_used = 64;
	memset (&cache_head, 0, sizeof (cache_head));
	cache_head.next = cache_head.prev = &cache_head;
	cache_head.lru_next = cache_head.lru_prev = &cache_head;

	if (layout == 0)
		return;

	if (layout == 4)
	{
		first = (cache_system_t *)(hunk_base + 64);
		second = (cache_system_t *)(hunk_base + 256);
		Bench486CacheTryAllocInitNode (first, 192);
		Bench486CacheTryAllocInitNode (second, 192);
	}
	else
	{
		first = (cache_system_t *)(hunk_base + 128);
		Bench486CacheTryAllocInitNode (first, 64);
		if (layout == 1 || layout == 2)
		{
			second = (cache_system_t *)(hunk_base + 256);
			Bench486CacheTryAllocInitNode (second, 64);
		}
		else
			second = NULL;
	}

	cache_head.next = first;
	cache_head.prev = second ? second : first;
	first->prev = &cache_head;
	first->next = second ? second : &cache_head;
	if (second)
	{
		second->prev = first;
		second->next = &cache_head;
	}

	cache_head.lru_next = first;
	first->lru_prev = &cache_head;
	first->lru_next = second ? second : &cache_head;
	if (second)
	{
		second->lru_prev = first;
		second->lru_next = &cache_head;
	}
	cache_head.lru_prev = second ? second : first;
}

static void Bench486CacheTryAllocRun (int layout, int size, int nobottom,
		int use_asm, bench486_cache_tryalloc_snapshot_t *snapshot)
{
	cache_system_t *result;

	Bench486CacheTryAllocSetup (layout);
#ifdef PROFILE486
	bench486_cache_tryalloc_scans = 0;
	bench486_cache_tryalloc_failures = 0;
#endif
	result = use_asm ? Cache_TryAlloc (size, nobottom) :
			Cache_TryAlloc_C (size, nobottom);
	snapshot->result_offset = result ? (int)((byte *)result - hunk_base) : -1;
	snapshot->head = cache_head;
	Q_memcpy (snapshot->arena, bench486_cache_tryalloc_arena.bytes,
			sizeof (snapshot->arena));
#ifdef PROFILE486
	snapshot->scans = bench486_cache_tryalloc_scans;
	snapshot->failures = bench486_cache_tryalloc_failures;
#endif
}

int Bench486CacheTryAllocCases (void)
{
	static const int layouts[5] = { 0, 1, 2, 3, 4 };
	static const int sizes[5] = { 48, 48, 64, 256, 32 };
	static const int nobottom[5] = { 0, 0, 1, 1, 0 };
	static const int expected_offsets[5] = { 64, 64, 192, 192, -1 };
	static const unsigned long expected_scans[5] = { 0, 1, 2, 1, 2 };
	static const unsigned long expected_failures[5] = { 0, 0, 0, 0, 1 };
	bench486_cache_tryalloc_snapshot_t c, a;
	cache_system_t saved_head;
	byte *saved_hunk_base;
	int saved_hunk_size, saved_hunk_low_used, saved_hunk_high_used;
	int i, failures;
#ifdef PROFILE486
	unsigned long saved_scans, saved_tryalloc_failures;
	saved_scans = bench486_cache_tryalloc_scans;
	saved_tryalloc_failures = bench486_cache_tryalloc_failures;
#endif
	saved_head = cache_head;
	saved_hunk_base = hunk_base;
	saved_hunk_size = hunk_size;
	saved_hunk_low_used = hunk_low_used;
	saved_hunk_high_used = hunk_high_used;
	failures = 0;
	for (i = 0; i < 5; i++)
	{
		Bench486CacheTryAllocRun (layouts[i], sizes[i], nobottom[i], 0, &c);
		Bench486CacheTryAllocRun (layouts[i], sizes[i], nobottom[i], 1, &a);
		if (c.result_offset != a.result_offset ||
				c.result_offset != expected_offsets[i] ||
				Q_memcmp (&c.head, &a.head, sizeof (c.head)) ||
				Q_memcmp (c.arena, a.arena, sizeof (c.arena)))
			failures |= 1 << i;
#ifdef PROFILE486
		if (c.scans != a.scans || c.failures != a.failures ||
				c.scans != expected_scans[i] ||
				c.failures != expected_failures[i])
			failures |= 1 << (i + 5);
#endif
	}
	cache_head = saved_head;
	hunk_base = saved_hunk_base;
	hunk_size = saved_hunk_size;
	hunk_low_used = saved_hunk_low_used;
	hunk_high_used = saved_hunk_high_used;
#ifdef PROFILE486
	bench486_cache_tryalloc_scans = saved_scans;
	bench486_cache_tryalloc_failures = saved_tryalloc_failures;
#endif
	return failures;
}
#endif
