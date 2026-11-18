/* Direct Cache_Check C/assembly parity over controlled LRU rings. */
/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
#if defined(BENCH486) && defined(ASM486_CACHE_CHECK_FIXTURE)

typedef struct
{
	int result_index;
	int count;
	int order[3];
	int links_ok;
	int users_ok;
#ifdef PROFILE486
	unsigned long checks;
	unsigned long hits;
	unsigned long misses;
	unsigned long relinks;
#endif
} bench486_cache_check_snapshot_t;

static int Bench486CacheCheckIndex (cache_system_t *node,
		cache_system_t *blocks)
{
	int i;
	for (i = 0; i < 3; i++)
		if (node == &blocks[i])
			return i;
	return -1;
}

static void Bench486CacheCheckRun (void *(*entry)(cache_user_t *), int target,
		bench486_cache_check_snapshot_t *snapshot)
{
	cache_system_t saved_head;
	cache_system_t blocks[3];
	cache_user_t users[3], missing;
	cache_system_t *node, *previous;
	void *result;
	int i, index;
#ifdef PROFILE486
	unsigned long saved_checks, saved_hits, saved_misses, saved_relinks;
	saved_checks = bench486_cache_checks;
	saved_hits = bench486_cache_hits;
	saved_misses = bench486_cache_misses;
	saved_relinks = bench486_cache_lru_relinks;
	bench486_cache_checks = 0;
	bench486_cache_hits = 0;
	bench486_cache_misses = 0;
	bench486_cache_lru_relinks = 0;
#endif
	Q_memset (snapshot, 0, sizeof (*snapshot));
	saved_head = cache_head;
	Q_memset (blocks, 0, sizeof (blocks));
	Q_memset (users, 0, sizeof (users));
	missing.data = NULL;
	for (i = 0; i < 3; i++)
	{
		users[i].data = (void *)(&blocks[i] + 1);
		blocks[i].user = &users[i];
		blocks[i].lru_prev = i ? &blocks[i - 1] : &cache_head;
		blocks[i].lru_next = i < 2 ? &blocks[i + 1] : &cache_head;
	}
	cache_head.lru_next = &blocks[0];
	cache_head.lru_prev = &blocks[2];

	result = entry (target < 0 ? &missing : &users[target]);
	snapshot->result_index = result ? -2 : -1;
	for (i = 0; i < 3; i++)
		if (result == users[i].data)
			snapshot->result_index = i;
	snapshot->count = 0;
	snapshot->links_ok = 1;
	snapshot->users_ok = 1;
	previous = &cache_head;
	node = cache_head.lru_next;
	while (node != &cache_head && snapshot->count < 3)
	{
		index = Bench486CacheCheckIndex (node, blocks);
		if (index < 0 || node->lru_prev != previous)
		{
			snapshot->links_ok = 0;
			break;
		}
		snapshot->order[snapshot->count++] = index;
		previous = node;
		node = node->lru_next;
	}
	if (node != &cache_head || snapshot->count != 3 ||
			cache_head.lru_prev != previous ||
			cache_head.lru_prev->lru_next != &cache_head)
		snapshot->links_ok = 0;
	for (i = 0; i < 3; i++)
		if (users[i].data != (void *)(&blocks[i] + 1) ||
				blocks[i].user != &users[i])
			snapshot->users_ok = 0;
#ifdef PROFILE486
	snapshot->checks = bench486_cache_checks;
	snapshot->hits = bench486_cache_hits;
	snapshot->misses = bench486_cache_misses;
	snapshot->relinks = bench486_cache_lru_relinks;
#endif
	cache_head = saved_head;
#ifdef PROFILE486
	bench486_cache_checks = saved_checks;
	bench486_cache_hits = saved_hits;
	bench486_cache_misses = saved_misses;
	bench486_cache_lru_relinks = saved_relinks;
#endif
}

int Bench486CacheCheckCases (void)
{
	static const int targets[4] = { -1, 0, 1, 2 };
	static const int expected_order[4][3] = {
		{ 0, 1, 2 }, { 0, 1, 2 }, { 1, 0, 2 }, { 2, 0, 1 }
	};
	bench486_cache_check_snapshot_t c, a;
	int i, j, failures, valid;
	failures = 0;
	for (i = 0; i < 4; i++)
	{
		Bench486CacheCheckRun (Cache_Check_C, targets[i], &c);
		Bench486CacheCheckRun (Cache_Check, targets[i], &a);
		valid = c.result_index == a.result_index && c.count == a.count &&
				c.links_ok && a.links_ok && c.users_ok && a.users_ok;
		for (j = 0; j < 3; j++)
			if (c.order[j] != a.order[j] || a.order[j] != expected_order[i][j])
				valid = 0;
		if (c.result_index != targets[i])
			valid = 0;
#ifdef PROFILE486
		if (c.checks != a.checks || c.hits != a.hits ||
				c.misses != a.misses || c.relinks != a.relinks ||
				c.checks != 1 || c.hits != (i ? 1 : 0) ||
				c.misses != (i ? 0 : 1) || c.relinks != (i > 1 ? 1 : 0))
			valid = 0;
#endif
		if (!valid)
			failures |= 1 << i;
	}
	return failures;
}

#endif
