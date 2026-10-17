/* Direct Cache_Free C/assembly parity over address and LRU list removals. */
#if defined(BENCH486) && defined(ASM486_CACHE_FREE_FIXTURE)
typedef struct bench486_cache_free_snapshot_s
{
	cache_system_t head;
	byte arena[512];
	cache_user_t users[3];
	int address_order[3];
	int lru_order[3];
	int address_count;
	int lru_count;
	int links_ok;
#ifdef PROFILE486
	unsigned long frees;
#endif
} bench486_cache_free_snapshot_t;

static union
{
	long alignment[4];
	byte bytes[512];
} bench486_cache_free_arena;
static cache_user_t bench486_cache_free_users[3];

static int Bench486CacheFreeIndex (cache_system_t *node)
{
	int i;
	for (i = 0; i < 3; i++)
		if (node == (cache_system_t *)(bench486_cache_free_arena.bytes + 64 + i * 96))
			return i;
	return -1;
}

static void Bench486CacheFreeSetup (void)
{
	static const int lru_order[3] = { 2, 0, 1 };
	cache_system_t *nodes[3];
	int i, j, index;

	memset (bench486_cache_free_arena.bytes, 0xc5,
			sizeof (bench486_cache_free_arena.bytes));
	memset (bench486_cache_free_users, 0, sizeof (bench486_cache_free_users));
	memset (&cache_head, 0, sizeof (cache_head));
	cache_head.next = cache_head.prev = &cache_head;
	cache_head.lru_next = cache_head.lru_prev = &cache_head;
	for (i = 0; i < 3; i++)
	{
		nodes[i] = (cache_system_t *)(bench486_cache_free_arena.bytes + 64 + i * 96);
		memset (nodes[i], 0, sizeof (*nodes[i]));
		nodes[i]->size = 96;
		nodes[i]->user = &bench486_cache_free_users[i];
		for (j = 0; j < (int)sizeof (nodes[i]->name); j++)
			nodes[i]->name[j] = (char)(i * 19 + j * 7);
		bench486_cache_free_users[i].data = (void *)(nodes[i] + 1);
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

static void Bench486CacheFreeRun (int target, int use_asm,
		bench486_cache_free_snapshot_t *snapshot)
{
	cache_system_t *node, *previous;
	int index;

	Bench486CacheFreeSetup ();
#ifdef PROFILE486
	bench486_cache_frees = 0;
#endif
	if (use_asm)
		Cache_Free (&bench486_cache_free_users[target]);
	else
		Cache_Free_C (&bench486_cache_free_users[target]);

	snapshot->head = cache_head;
	Q_memcpy (snapshot->arena, bench486_cache_free_arena.bytes,
			sizeof (snapshot->arena));
	Q_memcpy (snapshot->users, bench486_cache_free_users,
			sizeof (snapshot->users));
	snapshot->address_count = 0;
	snapshot->lru_count = 0;
	snapshot->links_ok = 1;
	previous = &cache_head;
	node = cache_head.next;
	while (node != &cache_head && snapshot->address_count < 3)
	{
		index = Bench486CacheFreeIndex (node);
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
	while (node != &cache_head && snapshot->lru_count < 3)
	{
		index = Bench486CacheFreeIndex (node);
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
	for (index = 0; index < 3; index++)
	{
		cache_system_t *block;
		block = (cache_system_t *)(bench486_cache_free_arena.bytes + 64 + index * 96);
		if (index == target)
		{
			if (bench486_cache_free_users[index].data || block->prev || block->next ||
					block->lru_prev || block->lru_next)
				snapshot->links_ok = 0;
		}
		else if (bench486_cache_free_users[index].data != (void *)(block + 1) ||
				block->user != &bench486_cache_free_users[index])
			snapshot->links_ok = 0;
	}
#ifdef PROFILE486
	snapshot->frees = bench486_cache_frees;
#endif
}

static void Bench486CacheFlushRun (int use_asm, int populated,
		bench486_cache_free_snapshot_t *snapshot)
{
	cache_system_t *node;
	int i;

	if (populated)
		Bench486CacheFreeSetup ();
	else
	{
		memset (bench486_cache_free_arena.bytes, 0xc5,
				sizeof (bench486_cache_free_arena.bytes));
		memset (bench486_cache_free_users, 0,
				sizeof (bench486_cache_free_users));
		memset (&cache_head, 0, sizeof (cache_head));
		cache_head.next = cache_head.prev = &cache_head;
		cache_head.lru_next = cache_head.lru_prev = &cache_head;
	}

#ifdef PROFILE486
	bench486_cache_frees = 0;
#endif
	if (use_asm)
		Cache_Flush ();
	else
		Cache_Flush_C ();

	snapshot->head = cache_head;
	Q_memcpy (snapshot->arena, bench486_cache_free_arena.bytes,
			sizeof (snapshot->arena));
	Q_memcpy (snapshot->users, bench486_cache_free_users,
			sizeof (snapshot->users));
	snapshot->address_count = cache_head.next == &cache_head ? 0 : 1;
	snapshot->lru_count = cache_head.lru_next == &cache_head ? 0 : 1;
	snapshot->links_ok = cache_head.next == &cache_head &&
		cache_head.prev == &cache_head && cache_head.lru_next == &cache_head &&
		cache_head.lru_prev == &cache_head;
	for (i = 0; i < 3; i++)
	{
		if (bench486_cache_free_users[i].data)
			snapshot->links_ok = 0;
		if (populated)
		{
			node = (cache_system_t *)(bench486_cache_free_arena.bytes +
					64 + i * 96);
			if (node->prev || node->next || node->lru_prev || node->lru_next)
				snapshot->links_ok = 0;
		}
	}
#ifdef PROFILE486
	snapshot->frees = bench486_cache_frees;
#endif
}

int Bench486CacheFreeCases (void)
{
	static const int initial_lru[3] = { 2, 0, 1 };
	bench486_cache_free_snapshot_t c, a;
	cache_system_t saved_head;
	#ifdef PROFILE486
	unsigned long saved_frees;
	#endif
	int target, i, c_address, a_address, c_lru, a_lru, failures;
#ifdef PROFILE486
	saved_frees = bench486_cache_frees;
#endif
	saved_head = cache_head;
	failures = 0;
	for (target = 0; target < 3; target++)
	{
		Bench486CacheFreeRun (target, 0, &c);
		Bench486CacheFreeRun (target, 1, &a);
		if (Q_memcmp (&c.head, &a.head, sizeof (c.head)) ||
				Q_memcmp (c.arena, a.arena, sizeof (c.arena)) ||
				Q_memcmp (c.users, a.users, sizeof (c.users)) ||
				!c.links_ok || !a.links_ok || c.address_count != 2 ||
				c.address_count != a.address_count || c.lru_count != 2 ||
				c.lru_count != a.lru_count)
			failures |= 1 << target;
		c_address = 0;
		a_address = 0;
		c_lru = 0;
		a_lru = 0;
		for (i = 0; i < 3; i++)
		{
			if (i != target)
			{
				if (c.address_order[c_address] != i ||
					a.address_order[a_address] != i)
					failures |= 1 << (target + 3);
				c_address++;
				a_address++;
			}
			if (initial_lru[i] != target)
			{
				if (c.lru_order[c_lru] != initial_lru[i] ||
					a.lru_order[a_lru] != initial_lru[i])
					failures |= 1 << (target + 3);
				c_lru++;
				a_lru++;
			}
		}
#ifdef PROFILE486
		if (c.frees != 1 || a.frees != 1)
			failures |= 1 << (target + 6);
#endif
	}
	Bench486CacheFlushRun (0, 1, &c);
	Bench486CacheFlushRun (1, 1, &a);
	if (Q_memcmp (&c.head, &a.head, sizeof (c.head)) ||
			Q_memcmp (c.arena, a.arena, sizeof (c.arena)) ||
			Q_memcmp (c.users, a.users, sizeof (c.users)) ||
			!c.links_ok || !a.links_ok || c.address_count || a.address_count ||
			c.lru_count || a.lru_count)
		failures |= 1 << 9;
#ifdef PROFILE486
	if (c.frees != 3 || a.frees != 3)
		failures |= 1 << 10;
#endif
	Bench486CacheFlushRun (0, 0, &c);
	Bench486CacheFlushRun (1, 0, &a);
	if (Q_memcmp (&c.head, &a.head, sizeof (c.head)) ||
			Q_memcmp (c.arena, a.arena, sizeof (c.arena)) ||
			Q_memcmp (c.users, a.users, sizeof (c.users)) ||
			!c.links_ok || !a.links_ok || c.address_count || a.address_count ||
			c.lru_count || a.lru_count)
		failures |= 1 << 11;
#ifdef PROFILE486
	if (c.frees || a.frees)
		failures |= 1 << 12;
#endif
	cache_head = saved_head;
#ifdef PROFILE486
	bench486_cache_frees = saved_frees;
#endif
	return failures;
}
#endif
