/* Exact C/assembly parity for high-hunk cache reclamation. */
/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
#if defined(BENCH486) && defined(ASM486_CACHE_FREE_HIGH_FIXTURE)
#define BCFH_ARENA_SIZE 512
#define BCFH_USER_COUNT 3

typedef struct bench486_cache_free_high_snapshot_s
{
	cache_system_t head;
	byte arena[BCFH_ARENA_SIZE];
	cache_user_t users[BCFH_USER_COUNT];
	int address_order[BCFH_USER_COUNT];
	int lru_order[BCFH_USER_COUNT];
	int address_count;
	int lru_count;
	int links_ok;
	int user_offsets[BCFH_USER_COUNT];
} bench486_cache_free_high_snapshot_t;

static union
{
	long alignment[4];
	byte bytes[BCFH_ARENA_SIZE];
} bench486_cache_free_high_arena;
static cache_user_t bench486_cache_free_high_users[BCFH_USER_COUNT];
static int bench486_cache_free_high_sizes[BCFH_USER_COUNT];

static int Bench486CacheFreeHighUserIndex (cache_system_t *node)
{
	int i;
	for (i = 0; i < BCFH_USER_COUNT; i++)
		if (node->user == &bench486_cache_free_high_users[i])
			return i;
	return -1;
}

static int Bench486CacheFreeHighSetup (int case_index)
{
	cache_system_t *nodes[BCFH_USER_COUNT];
	int offsets[BCFH_USER_COUNT], block_count, i, j, arena_size, high_mark;

	memset (bench486_cache_free_high_arena.bytes, 0xb7,
		sizeof (bench486_cache_free_high_arena.bytes));
	memset (bench486_cache_free_high_users, 0,
		sizeof (bench486_cache_free_high_users));
	memset (bench486_cache_free_high_sizes, 0,
		sizeof (bench486_cache_free_high_sizes));
	memset (&cache_head, 0, sizeof (cache_head));
	cache_head.next = cache_head.prev = &cache_head;
	cache_head.lru_next = cache_head.lru_prev = &cache_head;
	hunk_base = bench486_cache_free_high_arena.bytes;
	hunk_low_used = 0;
	hunk_high_used = 0;
	arena_size = case_index == 3 ? 256 : BCFH_ARENA_SIZE;
	block_count = case_index == 0 ? 0 : case_index == 1 ? 1 :
		case_index == 3 ? 2 : 3;
	high_mark = case_index == 0 ? 96 : case_index == 1 ? 0 :
		case_index == 2 ? 112 : case_index == 3 ? 64 : 312;
	hunk_size = arena_size;
	if (case_index == 1)
	{
		offsets[0] = 384;
		bench486_cache_free_high_sizes[0] = 128;
	}
	else if (case_index == 3)
	{
		offsets[0] = 0;
		offsets[1] = 128;
		bench486_cache_free_high_sizes[0] = 128;
		bench486_cache_free_high_sizes[1] = 128;
	}
	else if (case_index == 4)
	{
		offsets[0] = 0;
		offsets[1] = 128;
		offsets[2] = 384;
		bench486_cache_free_high_sizes[0] = 128;
		bench486_cache_free_high_sizes[1] = 256;
		bench486_cache_free_high_sizes[2] = 128;
	}
	else if (case_index == 2)
	{
		offsets[0] = 0;
		offsets[1] = 128;
		offsets[2] = 384;
		bench486_cache_free_high_sizes[0] = 128;
		bench486_cache_free_high_sizes[1] = 128;
		bench486_cache_free_high_sizes[2] = 128;
	}

	/* Initialize every cache node before connecting either circular list. */
	for (i = 0; i < block_count; i++)
	{
		nodes[i] = (cache_system_t *)(bench486_cache_free_high_arena.bytes +
			offsets[i]);
		memset (nodes[i], 0, sizeof (*nodes[i]));
		nodes[i]->size = bench486_cache_free_high_sizes[i];
		nodes[i]->user = &bench486_cache_free_high_users[i];
		for (j = 0; j < (int)sizeof (nodes[i]->name); j++)
			nodes[i]->name[j] = (char)(i * 23 + j * 5 + 1);
		bench486_cache_free_high_users[i].data = (void *)(nodes[i] + 1);
		for (j = 0; j < nodes[i]->size - (int)sizeof (*nodes[i]); j++)
			((byte *)(nodes[i] + 1))[j] = (byte)(i * 37 + j * 3 + 9);
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
	return high_mark;
}

static int Bench486CacheFreeHighBytesEqual (const void *left,
		const void *right, unsigned size)
{
	const byte *a = left, *b = right;
	while (size--)
		if (*a++ != *b++) return false;
	return true;
}

static int Bench486CacheFreeHighCapture (
		bench486_cache_free_high_snapshot_t *snapshot)
{
	cache_system_t *node, *previous;
	int i, j, index, failures = 0;
	memset (snapshot, 0, sizeof (*snapshot));
	memcpy (&snapshot->head, &cache_head, sizeof (cache_head));
	memcpy (snapshot->arena, bench486_cache_free_high_arena.bytes,
		sizeof (snapshot->arena));
	memcpy (snapshot->users, bench486_cache_free_high_users,
		sizeof (snapshot->users));
	for (i = 0; i < BCFH_USER_COUNT; i++)
	{
		snapshot->user_offsets[i] = -1;
		if (bench486_cache_free_high_users[i].data)
		{
			cache_system_t *owner = (cache_system_t *)
				bench486_cache_free_high_users[i].data - 1;
			if (owner->user != &bench486_cache_free_high_users[i] ||
				owner->size != bench486_cache_free_high_sizes[i])
				failures |= 1;
			snapshot->user_offsets[i] = (int)((byte *)owner -
				bench486_cache_free_high_arena.bytes);
			for (j = 0; j < owner->size - (int)sizeof (*owner); j++)
				if (((byte *)(owner + 1))[j] != (byte)(i * 37 + j * 3 + 9))
					failures |= 2;
		}
	}
	snapshot->links_ok = 1;
	previous = &cache_head;
	node = cache_head.next;
	while (node != &cache_head && snapshot->address_count < BCFH_USER_COUNT)
	{
		index = Bench486CacheFreeHighUserIndex (node);
		if (index < 0 || node->prev != previous || node->next->prev != node ||
			bench486_cache_free_high_users[index].data != (void *)(node + 1))
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
	while (node != &cache_head && snapshot->lru_count < BCFH_USER_COUNT)
	{
		index = Bench486CacheFreeHighUserIndex (node);
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

static int Bench486CacheFreeHighRun (int case_index, int use_asm,
		bench486_cache_free_high_snapshot_t *snapshot)
{
	int high_mark, failures;
	high_mark = Bench486CacheFreeHighSetup (case_index);
	if (use_asm)
		Cache_FreeHigh (high_mark);
	else
		Cache_FreeHigh_C (high_mark);
	failures = Bench486CacheFreeHighCapture (snapshot);
	switch (case_index)
	{
	case 0:
		if (snapshot->address_count || snapshot->lru_count ||
			bench486_cache_free_high_users[0].data ||
			bench486_cache_free_high_users[1].data ||
			bench486_cache_free_high_users[2].data)
			failures |= 8;
		break;
	case 1:
		if (snapshot->address_count != 1 || snapshot->lru_count != 1 ||
			snapshot->user_offsets[0] != 384 ||
			bench486_cache_free_high_users[1].data)
			failures |= 8;
		break;
	case 2:
		if (snapshot->address_count != 3 || snapshot->lru_count != 3 ||
			snapshot->user_offsets[0] != 0 || snapshot->user_offsets[1] != 128 ||
			snapshot->user_offsets[2] != 256 ||
			snapshot->address_order[0] != 0 || snapshot->address_order[1] != 1 ||
			snapshot->address_order[2] != 2 || snapshot->lru_order[0] != 2 ||
			snapshot->lru_order[1] != 1 || snapshot->lru_order[2] != 0)
			failures |= 8;
		break;
	case 3:
		if (snapshot->address_count != 1 || snapshot->lru_count != 1 ||
			snapshot->user_offsets[0] != 0 ||
			bench486_cache_free_high_users[1].data)
			failures |= 8;
		break;
	case 4:
		if (snapshot->address_count != 1 || snapshot->lru_count != 1 ||
			snapshot->user_offsets[0] != 0 ||
			bench486_cache_free_high_users[1].data ||
			bench486_cache_free_high_users[2].data)
			failures |= 8;
		break;
	}
	return failures;
}

int Bench486CacheFreeHighCases (void)
{
	bench486_cache_free_high_snapshot_t c, a;
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
		failures |= Bench486CacheFreeHighRun (i, 0, &c);
		failures |= Bench486CacheFreeHighRun (i, 1, &a);
		if (!Bench486CacheFreeHighBytesEqual (&c, &a, sizeof(c)))
			failures |= 16;
	}
	cache_head = saved_head;
	hunk_base = saved_hunk_base;
	hunk_size = saved_hunk_size;
	hunk_low_used = saved_hunk_low_used;
	hunk_high_used = saved_hunk_high_used;
	return failures;
}

#undef BCFH_ARENA_SIZE
#undef BCFH_USER_COUNT
#endif
