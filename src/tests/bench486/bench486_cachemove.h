/* Direct Cache_Move C/assembly parity for successful and failed relocation. */
/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
#if defined(BENCH486) && defined(ASM486_CACHE_MOVE_FIXTURE)
typedef struct bench486_cache_move_snapshot_s
{
	cache_system_t head;
	byte arena[512];
	cache_user_t users[2];
	int address_order[2];
	int lru_order[2];
	int address_count;
	int lru_count;
	int links_ok;
#ifdef PROFILE486
	unsigned long moves;
	unsigned long move_bytes;
	unsigned long frees;
	unsigned long tryalloc_scans;
	unsigned long tryalloc_failures;
#endif
} bench486_cache_move_snapshot_t;

static union
{
	long alignment[4];
	byte bytes[512];
} bench486_cache_move_arena;
static cache_user_t bench486_cache_move_users[2];

static int Bench486CacheMoveIndex (cache_system_t *node)
{
	int i;
	for (i = 0; i < 2; i++)
		if (node->user == &bench486_cache_move_users[i])
			return i;
	return -1;
}

static void Bench486CacheMoveSetup (int can_move)
{
	static const int lru_order[2] = { 1, 0 };
	cache_system_t *nodes[2];
	byte *payload;
	int i, j, index;

	memset (bench486_cache_move_arena.bytes, 0xb7,
			sizeof (bench486_cache_move_arena.bytes));
	memset (bench486_cache_move_users, 0,
			sizeof (bench486_cache_move_users));
	memset (&cache_head, 0, sizeof (cache_head));
	cache_head.next = cache_head.prev = &cache_head;
	cache_head.lru_next = cache_head.lru_prev = &cache_head;
	hunk_base = bench486_cache_move_arena.bytes;
	hunk_size = can_move ? 512 : 320;
	hunk_low_used = 0;
	hunk_high_used = 0;
	for (i = 0; i < 2; i++)
	{
		nodes[i] = (cache_system_t *)(bench486_cache_move_arena.bytes + i * 160);
		memset (nodes[i], 0, sizeof (*nodes[i]));
		nodes[i]->size = 160;
		nodes[i]->user = &bench486_cache_move_users[i];
		for (j = 0; j < (int)sizeof (nodes[i]->name); j++)
			nodes[i]->name[j] = (char)(i * 17 + j * 9);
		bench486_cache_move_users[i].data = (void *)(nodes[i] + 1);
		payload = (byte *)(nodes[i] + 1);
		for (j = 0; j < 120; j++)
			payload[j] = (byte)(i * 31 + j * 3);
	}
	for (i = 0; i < 2; i++)
	{
		nodes[i]->prev = i ? nodes[i - 1] : &cache_head;
		nodes[i]->next = i < 1 ? nodes[i + 1] : &cache_head;
	}
	cache_head.next = nodes[0];
	cache_head.prev = nodes[1];
	for (i = 0; i < 2; i++)
	{
		index = lru_order[i];
		nodes[index]->lru_prev = i ? nodes[lru_order[i - 1]] : &cache_head;
		nodes[index]->lru_next = i < 1 ? nodes[lru_order[i + 1]] : &cache_head;
	}
	cache_head.lru_next = nodes[lru_order[0]];
	cache_head.lru_prev = nodes[lru_order[1]];
}

static void Bench486CacheMoveRun (int can_move, int use_asm,
		bench486_cache_move_snapshot_t *snapshot)
{
	cache_system_t *node, *previous, *old_block;
	int index, i;

	Bench486CacheMoveSetup (can_move);
#ifdef PROFILE486
	bench486_cache_moves = 0;
	bench486_cache_move_bytes = 0;
	bench486_cache_frees = 0;
	bench486_cache_tryalloc_scans = 0;
	bench486_cache_tryalloc_failures = 0;
#endif
	old_block = (cache_system_t *)bench486_cache_move_arena.bytes;
	if (use_asm)
		Cache_Move (old_block);
	else
		Cache_Move_C (old_block);

	snapshot->head = cache_head;
	Q_memcpy (snapshot->arena, bench486_cache_move_arena.bytes,
			sizeof (snapshot->arena));
	Q_memcpy (snapshot->users, bench486_cache_move_users,
			sizeof (snapshot->users));
	snapshot->address_count = 0;
	snapshot->lru_count = 0;
	snapshot->links_ok = 1;
	previous = &cache_head;
	node = cache_head.next;
	while (node != &cache_head && snapshot->address_count < 2)
	{
		index = Bench486CacheMoveIndex (node);
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
	while (node != &cache_head && snapshot->lru_count < 2)
	{
		index = Bench486CacheMoveIndex (node);
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
	if (old_block->prev || old_block->next || old_block->lru_prev || old_block->lru_next)
		snapshot->links_ok = 0;
	if (can_move)
	{
		cache_system_t *new_block;
		new_block = NULL;
		if (!bench486_cache_move_users[0].data)
			snapshot->links_ok = 0;
		else
		{
			new_block = ((cache_system_t *)bench486_cache_move_users[0].data) - 1;
			if (new_block == old_block || new_block->size != 160 ||
					new_block->user != &bench486_cache_move_users[0] ||
					Q_memcmp (new_block->name, old_block->name, sizeof (old_block->name)) ||
					Q_memcmp (new_block + 1, old_block + 1, 120) ||
					bench486_cache_move_users[1].data !=
							(void *)(((cache_system_t *)(bench486_cache_move_arena.bytes + 160)) + 1))
				snapshot->links_ok = 0;
		}
		if (snapshot->address_count != 2 || snapshot->address_order[0] != 1 ||
				snapshot->address_order[1] != 0 || snapshot->lru_count != 2 ||
				snapshot->lru_order[0] != 0 || snapshot->lru_order[1] != 1)
			snapshot->links_ok = 0;
	}
	else if (bench486_cache_move_users[0].data ||
			snapshot->address_count != 1 || snapshot->address_order[0] != 1 ||
			snapshot->lru_count != 1 || snapshot->lru_order[0] != 1 ||
			bench486_cache_move_users[1].data !=
					(void *)(((cache_system_t *)(bench486_cache_move_arena.bytes + 160)) + 1))
		snapshot->links_ok = 0;
#ifdef PROFILE486
	snapshot->moves = bench486_cache_moves;
	snapshot->move_bytes = bench486_cache_move_bytes;
	snapshot->frees = bench486_cache_frees;
	snapshot->tryalloc_scans = bench486_cache_tryalloc_scans;
	snapshot->tryalloc_failures = bench486_cache_tryalloc_failures;
#endif
}

int Bench486CacheMoveCases (void)
{
	bench486_cache_move_snapshot_t c, a;
	cache_system_t saved_head;
	byte *saved_hunk_base;
	int saved_hunk_size, saved_hunk_low_used, saved_hunk_high_used;
#ifdef PROFILE486
	unsigned long saved_moves, saved_move_bytes, saved_frees;
	unsigned long saved_tryalloc_scans, saved_tryalloc_failures;
#endif
	int can_move, failures;

	saved_head = cache_head;
	saved_hunk_base = hunk_base;
	saved_hunk_size = hunk_size;
	saved_hunk_low_used = hunk_low_used;
	saved_hunk_high_used = hunk_high_used;
#ifdef PROFILE486
	saved_moves = bench486_cache_moves;
	saved_move_bytes = bench486_cache_move_bytes;
	saved_frees = bench486_cache_frees;
	saved_tryalloc_scans = bench486_cache_tryalloc_scans;
	saved_tryalloc_failures = bench486_cache_tryalloc_failures;
#endif
	failures = 0;
	for (can_move = 0; can_move <= 1; can_move++)
	{
		Bench486CacheMoveRun (can_move, 0, &c);
		Bench486CacheMoveRun (can_move, 1, &a);
		if (Q_memcmp (&c.head, &a.head, sizeof (c.head)) ||
				Q_memcmp (c.arena, a.arena, sizeof (c.arena)) ||
				Q_memcmp (c.users, a.users, sizeof (c.users)) ||
				c.address_count != a.address_count || c.lru_count != a.lru_count ||
				!c.links_ok || !a.links_ok)
			failures |= 1 << can_move;
#ifdef PROFILE486
		if (c.moves != 1 || a.moves != 1 || c.move_bytes != 120 ||
				a.move_bytes != 120 || c.frees != 1 || a.frees != 1 ||
				c.tryalloc_failures != (unsigned long)!can_move ||
				a.tryalloc_failures != (unsigned long)!can_move ||
				c.tryalloc_scans != a.tryalloc_scans)
			failures |= 1 << (can_move + 2);
#endif
	}
	cache_head = saved_head;
	hunk_base = saved_hunk_base;
	hunk_size = saved_hunk_size;
	hunk_low_used = saved_hunk_low_used;
	hunk_high_used = saved_hunk_high_used;
#ifdef PROFILE486
	bench486_cache_moves = saved_moves;
	bench486_cache_move_bytes = saved_move_bytes;
	bench486_cache_frees = saved_frees;
	bench486_cache_tryalloc_scans = saved_tryalloc_scans;
	bench486_cache_tryalloc_failures = saved_tryalloc_failures;
#endif
	return failures;
}
#endif
