/* Direct state/ABI comparison for R_ClearParticles's intrusive free list. */
extern particle_t *active_particles, *free_particles, *particles;
extern int r_numparticles;
extern void R_ClearParticles_C (void);

static struct
{
	unsigned long guard_before[4];
	particle_t nodes[2052];
	unsigned long guard_after[4];
} bench486_particlelist_fixture;
static byte bench486_particlelist_reference[sizeof(bench486_particlelist_fixture)];

static void Bench486ParticleListCases (void)
{
	static const struct { int count, base_index; } cases[] = {
		{1,1}, {2,1}, {3,1}, {17,1}, {512,1}, {1024,1}, {2048,1},
		{0,1}, {-1,2}
	};
	particle_t *saved_active, *saved_free, *saved_particles;
	int saved_count, i, failures, c_count, a_count;
	unsigned c_abi, a_abi;
	particle_t *c_active, *c_free, *a_active, *a_free;

	saved_active = active_particles;
	saved_free = free_particles;
	saved_particles = particles;
	saved_count = r_numparticles;
	failures = 0;
	for (i=0 ; i<sizeof(cases)/sizeof(cases[0]) ; i++)
	{
		Q_memset(&bench486_particlelist_fixture,0x5a,
				sizeof(bench486_particlelist_fixture));
		particles = &bench486_particlelist_fixture.nodes[cases[i].base_index];
		r_numparticles = cases[i].count;
		active_particles = &bench486_particlelist_fixture.nodes[4];
		free_particles = &bench486_particlelist_fixture.nodes[5];
		R_ClearParticles_C ();
		c_abi = Bench486Call_asm486 ((void (*)(void))R_ClearParticles_C,
				0, NULL, NULL);
		Q_memcpy (bench486_particlelist_reference,
				&bench486_particlelist_fixture,
				sizeof(bench486_particlelist_fixture));
		c_active = active_particles;
		c_free = free_particles;
		c_count = r_numparticles;

		Q_memset(&bench486_particlelist_fixture,0x5a,
				sizeof(bench486_particlelist_fixture));
		particles = &bench486_particlelist_fixture.nodes[cases[i].base_index];
		r_numparticles = cases[i].count;
		active_particles = &bench486_particlelist_fixture.nodes[4];
		free_particles = &bench486_particlelist_fixture.nodes[5];
			a_abi = Bench486Call_asm486 ((void (*)(void))R_ClearParticles,
				0, NULL, NULL);
		a_active = active_particles;
		a_free = free_particles;
		a_count = r_numparticles;
		if (c_abi || a_abi || c_count != a_count || c_active != a_active ||
				c_free != a_free || Q_memcmp(bench486_particlelist_reference,
				&bench486_particlelist_fixture,
				sizeof(bench486_particlelist_fixture)))
		{
			failures++;
			if (failures < 20)
				Bench486Printf("particle-list reset FAIL case %d count %d ABI %x/%x\n",
						i,cases[i].count,c_abi,a_abi);
		}
	}
	active_particles = saved_active;
	free_particles = saved_free;
	particles = saved_particles;
	r_numparticles = saved_count;
	bench486_memory_failures += failures;
	Bench486Printf("particle-list reset C/ASM state and ABI %s (%d counts; %d failures)\n",
			failures ? "FAIL" : "PASS",
			(int)(sizeof(cases)/sizeof(cases[0])),failures);
}
