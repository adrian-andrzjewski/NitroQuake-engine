/* Direct Cache_Alloc C/assembly parity for empty and eviction paths. */
#if defined(BENCH486) && defined(ASM486_CACHE_ALLOC_FIXTURE)
typedef struct bench486_cache_alloc_snapshot_s
{
	cache_system_t head;
	byte arena[512];
	cache_user_t users[4];
	void *result;
	int address_order[4];
	int lru_order[4];
	int address_count;
	int lru_count;
	int links_ok;
#ifdef PROFILE486
	unsigned long allocations;
	unsigned long evictions;
	unsigned long frees;
	unsigned long tryalloc_scans;
	unsigned long tryalloc_failures;
#endif
} bench486_cache_alloc_snapshot_t;

static union
{
	long alignment[4];
	byte bytes[512];
} bench486_cache_alloc_arena;
static cache_user_t bench486_cache_alloc_users[4];

static int Bench486CacheAllocIndex (cache_system_t *node)
{
	int i;
	for (i = 0; i < 4; i++)
		if (node->user == &bench486_cache_alloc_users[i])
			return i;
	return -1;
}

static void Bench486CacheAllocSetup (int fragmented)
{
	static const int lru_order[3] = { 2, 0, 1 };
	cache_system_t *nodes[3];
	int i, j, index;

	memset (bench486_cache_alloc_arena.bytes, 0xa7,
			sizeof (bench486_cache_alloc_arena.bytes));
	memset (bench486_cache_alloc_users, 0,
			sizeof (bench486_cache_alloc_users));
	memset (&cache_head, 0, sizeof (cache_head));
	cache_head.next = cache_head.prev = &cache_head;
	cache_head.lru_next = cache_head.lru_prev = &cache_head;
	hunk_base = bench486_cache_alloc_arena.bytes;
	hunk_size = sizeof (bench486_cache_alloc_arena.bytes);
	hunk_low_used = 0;
	hunk_high_used = 0;
	if (!fragmented)
		return;

	for (i = 0; i < 3; i++)
	{
		nodes[i] = (cache_system_t *)(bench486_cache_alloc_arena.bytes + i * 160);
		memset (nodes[i], 0, sizeof (*nodes[i]));
		nodes[i]->size = 160;
		nodes[i]->user = &bench486_cache_alloc_users[i];
		for (j = 0; j < (int)sizeof (nodes[i]->name); j++)
			nodes[i]->name[j] = (char)(i * 23 + j * 5);
		bench486_cache_alloc_users[i].data = (void *)(nodes[i] + 1);
	}
	for (i = 0; i < 3; i++)
	{
		nodes[i]->prev = i ? nodes[i - 1] : &cache_head;
		nodes[i]->next = i < 2 ? nodes[i + 1] : &cache_head;
	}
	cache_head.next = nodes[0];
	cache_head.prev = nodes[2];
	for (i = 0; i < 3; i++)
	{
		index = lru_order[i];
		nodes[index]->lru_prev = i ? nodes[lru_order[i - 1]] : &cache_head;
		nodes[index]->lru_next = i < 2 ? nodes[lru_order[i + 1]] : &cache_head;
	}
	cache_head.lru_next = nodes[lru_order[0]];
	cache_head.lru_prev = nodes[lru_order[2]];
}

static void Bench486CacheAllocRun (int fragmented, int use_asm,
		bench486_cache_alloc_snapshot_t *snapshot)
{
	static char allocation_name[] = "cache-alloc-fixture-name";
	cache_system_t *node, *previous, *block;
	int index, expected_size, i;

	Bench486CacheAllocSetup (fragmented);
#ifdef PROFILE486
	bench486_cache_allocations = 0;
	bench486_cache_evictions = 0;
	bench486_cache_frees = 0;
	bench486_cache_tryalloc_scans = 0;
	bench486_cache_tryalloc_failures = 0;
#endif
	if (use_asm)
		snapshot->result = Cache_Alloc (&bench486_cache_alloc_users[3],
				fragmented ? 64 : 33, allocation_name);
	else
		snapshot->result = Cache_Alloc_C (&bench486_cache_alloc_users[3],
				fragmented ? 64 : 33, allocation_name);

	snapshot->head = cache_head;
	Q_memcpy (snapshot->arena, bench486_cache_alloc_arena.bytes,
			sizeof (snapshot->arena));
	Q_memcpy (snapshot->users, bench486_cache_alloc_users,
			sizeof (snapshot->users));
	snapshot->address_count = 0;
	snapshot->lru_count = 0;
	snapshot->links_ok = 1;
	previous = &cache_head;
	node = cache_head.next;
	while (node != &cache_head && snapshot->address_count < 4)
	{
		index = Bench486CacheAllocIndex (node);
		if (index < 0 || node->prev != previous)
		{
			snapshot->links_ok = 0;
			break;
		}
		snapshot->address_order[snapshot->address_count++] = index;
		previous = node;
		node = node->next;
	}
	if (node != &cache_head || cache_head.prev != previous ||
			cache_head.prev->next != &cache_head)
		snapshot->links_ok = 0;
	previous = &cache_head;
	node = cache_head.lru_next;
	while (node != &cache_head && snapshot->lru_count < 4)
	{
		index = Bench486CacheAllocIndex (node);
		if (index < 0 || node->lru_prev != previous)
		{
			snapshot->links_ok = 0;
			break;
		}
		snapshot->lru_order[snapshot->lru_count++] = index;
		previous = node;
		node = node->lru_next;
	}
	if (node != &cache_head || cache_head.lru_prev != previous ||
			cache_head.lru_prev->lru_next != &cache_head)
		snapshot->links_ok = 0;
	expected_size = fragmented ? 112 : 80;
	if (!snapshot->result || snapshot->result != bench486_cache_alloc_users[3].data)
		snapshot->links_ok = 0;
	else
	{
		block = ((cache_system_t *)snapshot->result) - 1;
		if (block->size != expected_size || block->user != &bench486_cache_alloc_users[3] ||
				Q_strncmp (block->name, allocation_name, sizeof (block->name) - 1) ||
				block->name[sizeof (block->name) - 1] != 0)
			snapshot->links_ok = 0;
	}
	for (i = 0; i < 3; i++)
	{
		if (!fragmented || i == 1)
		{
			if (bench486_cache_alloc_users[i].data)
				snapshot->links_ok = 0;
		}
		else
		{
			block = (cache_system_t *)(bench486_cache_alloc_arena.bytes + i * 160);
			if (bench486_cache_alloc_users[i].data != (void *)(block + 1) ||
					block->user != &bench486_cache_alloc_users[i])
				snapshot->links_ok = 0;
		}
	}
#ifdef PROFILE486
	snapshot->allocations = bench486_cache_allocations;
	snapshot->evictions = bench486_cache_evictions;
	snapshot->frees = bench486_cache_frees;
	snapshot->tryalloc_scans = bench486_cache_tryalloc_scans;
	snapshot->tryalloc_failures = bench486_cache_tryalloc_failures;
#endif
}

int Bench486CacheAllocCases (void)
{
	bench486_cache_alloc_snapshot_t c, a;
	cache_system_t saved_head;
	byte *saved_hunk_base;
	int saved_hunk_size, saved_hunk_low_used, saved_hunk_high_used;
#ifdef PROFILE486
	unsigned long saved_allocations, saved_evictions, saved_frees;
	unsigned long saved_tryalloc_scans, saved_tryalloc_failures;
#endif
	int fragmented, failures;

	saved_head = cache_head;
	saved_hunk_base = hunk_base;
	saved_hunk_size = hunk_size;
	saved_hunk_low_used = hunk_low_used;
	saved_hunk_high_used = hunk_high_used;
#ifdef PROFILE486
	saved_allocations = bench486_cache_allocations;
	saved_evictions = bench486_cache_evictions;
	saved_frees = bench486_cache_frees;
	saved_tryalloc_scans = bench486_cache_tryalloc_scans;
	saved_tryalloc_failures = bench486_cache_tryalloc_failures;
#endif
	failures = 0;
	for (fragmented = 0; fragmented <= 1; fragmented++)
	{
		Bench486CacheAllocRun (fragmented, 0, &c);
		Bench486CacheAllocRun (fragmented, 1, &a);
		if (Q_memcmp (&c.head, &a.head, sizeof (c.head)) ||
				Q_memcmp (c.arena, a.arena, sizeof (c.arena)) ||
				Q_memcmp (c.users, a.users, sizeof (c.users)) ||
				c.result != a.result || c.address_count != a.address_count ||
				c.lru_count != a.lru_count || !c.links_ok || !a.links_ok)
			failures |= 1 << fragmented;
		if (fragmented)
		{
			if (c.address_count != 3 || a.address_count != 3 ||
					c.address_order[0] != 0 || c.address_order[1] != 3 ||
					c.address_order[2] != 2 || a.address_order[0] != 0 ||
					a.address_order[1] != 3 || a.address_order[2] != 2 ||
					c.lru_count != 3 || a.lru_count != 3 ||
					c.lru_order[0] != 3 || c.lru_order[1] != 2 ||
					c.lru_order[2] != 0 || a.lru_order[0] != 3 ||
					a.lru_order[1] != 2 || a.lru_order[2] != 0)
				failures |= 1 << (fragmented + 2);
		}
		else if (c.address_count != 1 || a.address_count != 1 ||
				c.address_order[0] != 3 || a.address_order[0] != 3 ||
				c.lru_count != 1 || a.lru_count != 1 ||
				c.lru_order[0] != 3 || a.lru_order[0] != 3)
			failures |= 1 << (fragmented + 2);
#ifdef PROFILE486
		if (c.allocations != 1 || a.allocations != 1 ||
				c.evictions != (unsigned long)fragmented ||
				a.evictions != (unsigned long)fragmented ||
				c.frees != (unsigned long)fragmented ||
				a.frees != (unsigned long)fragmented ||
				c.tryalloc_failures != (unsigned long)fragmented ||
				a.tryalloc_failures != (unsigned long)fragmented ||
				c.tryalloc_scans != a.tryalloc_scans)
			failures |= 1 << (fragmented + 4);
#endif
	}
	cache_head = saved_head;
	hunk_base = saved_hunk_base;
	hunk_size = saved_hunk_size;
	hunk_low_used = saved_hunk_low_used;
	hunk_high_used = saved_hunk_high_used;
#ifdef PROFILE486
	bench486_cache_allocations = saved_allocations;
	bench486_cache_evictions = saved_evictions;
	bench486_cache_frees = saved_frees;
	bench486_cache_tryalloc_scans = saved_tryalloc_scans;
	bench486_cache_tryalloc_failures = saved_tryalloc_failures;
#endif
	return failures;
}
#endif
