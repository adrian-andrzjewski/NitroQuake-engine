/* Exact C/assembly parity for low-hunk cache reclamation. */
#if defined(BENCH486) && defined(ASM486_CACHE_FREE_LOW_FIXTURE)
#define BCFL_ARENA_SIZE 512
#define BCFL_BLOCK_SIZE 160
#define BCFL_USER_COUNT 2

typedef struct bench486_cache_free_low_snapshot_s
{
	cache_system_t head;
	byte arena[BCFL_ARENA_SIZE];
	cache_user_t users[BCFL_USER_COUNT];
	int address_order[BCFL_USER_COUNT];
	int lru_order[BCFL_USER_COUNT];
	int address_count;
	int lru_count;
	int links_ok;
	int user_offsets[BCFL_USER_COUNT];
} bench486_cache_free_low_snapshot_t;

static union
{
	long alignment[4];
	byte bytes[BCFL_ARENA_SIZE];
} bench486_cache_free_low_arena;
static cache_user_t bench486_cache_free_low_users[BCFL_USER_COUNT];

static int Bench486CacheFreeLowUserIndex (cache_system_t *node)
{
	int i;
	for (i = 0; i < BCFL_USER_COUNT; i++)
		if (node->user == &bench486_cache_free_low_users[i])
			return i;
	return -1;
}

static int Bench486CacheFreeLowSetup (int case_index)
{
	cache_system_t *nodes[BCFL_USER_COUNT];
	int block_count, i, j, limit, arena_size;

	memset (bench486_cache_free_low_arena.bytes, 0xb7,
		sizeof (bench486_cache_free_low_arena.bytes));
	memset (bench486_cache_free_low_users, 0,
		sizeof (bench486_cache_free_low_users));
	memset (&cache_head, 0, sizeof (cache_head));
	cache_head.next = cache_head.prev = &cache_head;
	cache_head.lru_next = cache_head.lru_prev = &cache_head;
	hunk_base = bench486_cache_free_low_arena.bytes;
	hunk_low_used = 0;
	hunk_high_used = 0;
	block_count = case_index == 0 ? 0 : case_index == 1 ? 1 : 2;
	arena_size = case_index == 3 ? 320 : BCFL_ARENA_SIZE;
	limit = case_index == 0 ? 96 : case_index == 1 ? 0 :
		case_index == 4 ? 400 : 64;
	hunk_size = arena_size;
	for (i = 0; i < block_count; i++)
	{
		nodes[i] = (cache_system_t *)(bench486_cache_free_low_arena.bytes +
			i * BCFL_BLOCK_SIZE);
		memset (nodes[i], 0, sizeof (*nodes[i]));
		nodes[i]->size = BCFL_BLOCK_SIZE;
		nodes[i]->user = &bench486_cache_free_low_users[i];
		for (j = 0; j < (int)sizeof (nodes[i]->name); j++)
			nodes[i]->name[j] = (char)(i * 19 + j * 7);
		bench486_cache_free_low_users[i].data = (void *)(nodes[i] + 1);
		for (j = 0; j < BCFL_BLOCK_SIZE - (int)sizeof (*nodes[i]); j++)
			((byte *)(nodes[i] + 1))[j] = (byte)(i * 41 + j * 5 + 3);
	}
	if (block_count)
	{
		for (i = 0; i < block_count; i++)
		{
			nodes[i]->prev = i ? nodes[i - 1] : &cache_head;
			nodes[i]->next = i + 1 < block_count ? nodes[i + 1] : &cache_head;
		}
		cache_head.next = nodes[0];
		cache_head.prev = nodes[block_count - 1];
		for (i = 0; i < block_count; i++)
		{
			int index = block_count - i - 1;
			nodes[index]->lru_prev = i ? nodes[block_count - i] : &cache_head;
			nodes[index]->lru_next = i + 1 < block_count ?
				nodes[block_count - i - 2] : &cache_head;
		}
		cache_head.lru_next = nodes[block_count - 1];
		cache_head.lru_prev = nodes[0];
	}
	bench486_cache_free_low_users[0].data = block_count > 0 ?
		(void *)(nodes[0] + 1) : NULL;
	bench486_cache_free_low_users[1].data = block_count > 1 ?
		(void *)(nodes[1] + 1) : NULL;
	return limit;
}

static int Bench486CacheFreeLowBytesEqual (const void *left,
		const void *right, unsigned size)
{
	const byte *a = left, *b = right;
	while (size--)
		if (*a++ != *b++) return false;
	return true;
}

static int Bench486CacheFreeLowCapture (
		bench486_cache_free_low_snapshot_t *snapshot)
{
	cache_system_t *node, *previous;
	int i, j, index, failures = 0;
	memset (snapshot, 0, sizeof (*snapshot));
	memcpy (&snapshot->head, &cache_head, sizeof (cache_head));
	memcpy (snapshot->arena, bench486_cache_free_low_arena.bytes,
		sizeof (snapshot->arena));
	memcpy (snapshot->users, bench486_cache_free_low_users,
		sizeof (snapshot->users));
	for (i = 0; i < BCFL_USER_COUNT; i++)
	{
		snapshot->user_offsets[i] = -1;
		if (bench486_cache_free_low_users[i].data)
		{
			cache_system_t *owner = (cache_system_t *)
				bench486_cache_free_low_users[i].data - 1;
			if (owner->user != &bench486_cache_free_low_users[i] ||
				owner->size != BCFL_BLOCK_SIZE)
				failures |= 1;
			snapshot->user_offsets[i] = (int)((byte *)owner -
				bench486_cache_free_low_arena.bytes);
			for (j = 0; j < BCFL_BLOCK_SIZE - (int)sizeof (*owner); j++)
				if (((byte *)(owner + 1))[j] != (byte)(i * 41 + j * 5 + 3))
					failures |= 2;
		}
	}
	snapshot->links_ok = 1;
	previous = &cache_head;
	node = cache_head.next;
	while (node != &cache_head && snapshot->address_count < BCFL_USER_COUNT)
	{
		index = Bench486CacheFreeLowUserIndex (node);
		if (index < 0 || node->prev != previous || node->next->prev != node ||
			bench486_cache_free_low_users[index].data != (void *)(node + 1))
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
	while (node != &cache_head && snapshot->lru_count < BCFL_USER_COUNT)
	{
		index = Bench486CacheFreeLowUserIndex (node);
		if (index < 0 || node->lru_prev != previous ||
			node->lru_next->lru_prev != node)
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
	if (!snapshot->links_ok)
		failures |= 4;
	return failures;
}

static int Bench486CacheFreeLowRun (int case_index, int use_asm,
		bench486_cache_free_low_snapshot_t *snapshot)
{
	int limit, failures;
	limit = Bench486CacheFreeLowSetup (case_index);
	if (use_asm)
		Cache_FreeLow (limit);
	else
		Cache_FreeLow_C (limit);
	failures = Bench486CacheFreeLowCapture (snapshot);
	switch (case_index)
	{
	case 0:
		if (snapshot->address_count != 0 || snapshot->lru_count != 0 ||
			bench486_cache_free_low_users[0].data ||
			bench486_cache_free_low_users[1].data)
			failures |= 8;
		break;
	case 1:
		if (snapshot->address_count != 1 || snapshot->lru_count != 1 ||
			snapshot->user_offsets[0] != 0 ||
			bench486_cache_free_low_users[1].data)
			failures |= 8;
		break;
	case 2:
		if (snapshot->address_count != 2 || snapshot->lru_count != 2 ||
			snapshot->user_offsets[0] != 320 ||
			snapshot->user_offsets[1] != BCFL_BLOCK_SIZE ||
			snapshot->address_order[0] != 1 || snapshot->address_order[1] != 0 ||
			snapshot->lru_order[0] != 0 || snapshot->lru_order[1] != 1)
			failures |= 8;
		break;
	case 3:
		if (snapshot->address_count != 1 || snapshot->lru_count != 1 ||
			bench486_cache_free_low_users[0].data ||
			snapshot->user_offsets[1] != BCFL_BLOCK_SIZE)
			failures |= 8;
		break;
	case 4:
		if (snapshot->address_count != 0 || snapshot->lru_count != 0 ||
			bench486_cache_free_low_users[0].data ||
			bench486_cache_free_low_users[1].data)
			failures |= 8;
		break;
	}
	return failures;
}

int Bench486CacheFreeLowCases (void)
{
	bench486_cache_free_low_snapshot_t c, a;
	cache_system_t saved_head;
	byte *saved_hunk_base;
	int saved_hunk_size, saved_hunk_low_used, saved_hunk_high_used;
	int i, failures = 0;
	saved_head = cache_head;
	saved_hunk_base = hunk_base;
	saved_hunk_size = hunk_size;
	saved_hunk_low_used = hunk_low_used;
	saved_hunk_high_used = hunk_high_used;
	for (i = 0; i < 5; i++)
	{
		failures |= Bench486CacheFreeLowRun (i, 0, &c);
		failures |= Bench486CacheFreeLowRun (i, 1, &a);
		if (!Bench486CacheFreeLowBytesEqual (&c, &a, sizeof(c)))
			failures |= 16;
	}
	cache_head = saved_head;
	hunk_base = saved_hunk_base;
	hunk_size = saved_hunk_size;
	hunk_low_used = saved_hunk_low_used;
	hunk_high_used = saved_hunk_high_used;
	return failures;
}

#undef BCFL_ARENA_SIZE
#undef BCFL_BLOCK_SIZE
#undef BCFL_USER_COUNT
#endif
