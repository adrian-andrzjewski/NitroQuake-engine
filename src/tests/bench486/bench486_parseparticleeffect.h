/* Exact C-oracle versus i486 state coverage for R_ParseParticleEffect. */
/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
#ifndef BENCH486_PARSEPARTICLEEFFECT_H
#define BENCH486_PARSEPARTICLEEFFECT_H

#ifdef ASM486_PARSE_PARTICLE_EFFECT

#include <stddef.h>

#define BPPE_GUARD_WORDS 8
#define BPPE_PACKET_BYTES 11
#define BPPE_FREE_CAPACITY 2048
#define BPPE_FREE_BASE 1
#define BPPE_ACTIVE_HEAD (BPPE_FREE_BASE + BPPE_FREE_CAPACITY)
#define BPPE_ACTIVE_TAIL (BPPE_ACTIVE_HEAD + 1)
#define BPPE_NODE_COUNT (BPPE_ACTIVE_TAIL + 1)
#define BPPE_RANDOM_COUNT 19

extern particle_t *active_particles, *free_particles;
extern int ramp1[8];
extern sizebuf_t net_message;
extern int msg_readcount;
extern qboolean msg_badread;
extern int (*bench486_runparticleeffect_rand_probe) (void);
extern unsigned bench486_runparticleeffect_rand_calls;
extern void R_ParseParticleEffect_C (void);
extern void R_ParseParticleEffect_asm486 (void);
extern unsigned Bench486Call_asm486 (void (*function)(void), unsigned words,
		const unsigned *arguments, float *float_return);

typedef char bench486_parseparticleeffect_i386_layout[
		(sizeof(void *) == 4 && sizeof(int) == 4 && sizeof(unsigned) == 4 &&
		sizeof(particle_t) == 40 && offsetof(particle_t, next) == 16 &&
		offsetof(particle_t, org) == 0 && offsetof(particle_t, vel) == 20) ?
		1 : -1];

typedef struct
{
	unsigned before[BPPE_GUARD_WORDS];
	byte bytes[BPPE_PACKET_BYTES];
	unsigned after[BPPE_GUARD_WORDS];
} bench486_parseparticleeffect_message_t;

typedef struct
{
	unsigned before[BPPE_GUARD_WORDS];
	particle_t nodes[BPPE_NODE_COUNT];
	unsigned after[BPPE_GUARD_WORDS];
} bench486_parseparticleeffect_pool_t;

typedef struct
{
	const char *name;
	int packet_length;
	int message_count;
	int free_count;
	unsigned random_start;
	double time;
	int color;
} bench486_parseparticleeffect_case_t;

typedef struct
{
	byte pool[sizeof(bench486_parseparticleeffect_pool_t)];
	byte packet[sizeof(bench486_parseparticleeffect_message_t)];
	sizebuf_t message;
	particle_t *active;
	particle_t *free;
	double client_time;
	int ramp_zero;
	int readcount;
	qboolean badread;
	unsigned random_calls;
	unsigned random_index;
	int next_random;
	unsigned short x87_cw;
	unsigned short x87_sw;
	unsigned short x87_top_before;
	unsigned abi;
	int state_valid;
	int state_reason;
} bench486_parseparticleeffect_result_t;

static bench486_parseparticleeffect_message_t
		bench486_parseparticleeffect_message;
static bench486_parseparticleeffect_pool_t bench486_parseparticleeffect_pool;
static bench486_parseparticleeffect_result_t
		bench486_parseparticleeffect_c_result;
static bench486_parseparticleeffect_result_t
		bench486_parseparticleeffect_asm_result;
static unsigned short bench486_parseparticleeffect_x87_env[14];
static unsigned bench486_parseparticleeffect_random_index;
static int bench486_parseparticleeffect_state_reason;

/* Include negative values so the shared C emitter exercises signed '%' and
 * bit-mask behavior while the parser implementations receive identical RNG. */
static const int bench486_parseparticleeffect_random[BPPE_RANDOM_COUNT] =
{
	0, 1, 4, 5, 7, 8, 15, 16, 31, 32, 63, 64, 127, 255,
	-1, -2, -31, -2147483647-1, 2147483647
};

static int Bench486ParseParticleEffectRandom (void)
{
	unsigned index;

	index = bench486_parseparticleeffect_random_index % BPPE_RANDOM_COUNT;
	bench486_parseparticleeffect_random_index++;
	return bench486_parseparticleeffect_random[index];
}

static int Bench486ParseParticleEffectRandomPeek (unsigned index)
{
	return bench486_parseparticleeffect_random[index % BPPE_RANDOM_COUNT];
}

static void Bench486ParseParticleEffectWritePacket (int count, int color)
{
	static const short coords[3] = { -32768, 32767, -1 };
	static const byte directions[3] = { 0x80, 0x7f, 0xff };
	unsigned short value;
	int i;

	for (i = 0; i < 3; i++)
	{
		value = (unsigned short)coords[i];
		bench486_parseparticleeffect_message.bytes[i*2] = (byte)value;
		bench486_parseparticleeffect_message.bytes[i*2+1] =
				(byte)(value >> 8);
	}
	for (i = 0; i < 3; i++)
		bench486_parseparticleeffect_message.bytes[6+i] = directions[i];
	bench486_parseparticleeffect_message.bytes[9] = (byte)count;
	bench486_parseparticleeffect_message.bytes[10] = (byte)color;
}

static void Bench486ParseParticleEffectPrepare (
		const bench486_parseparticleeffect_case_t *test)
{
	int i;

	Q_memset (&bench486_parseparticleeffect_message, 0xa5,
			sizeof(bench486_parseparticleeffect_message));
	for (i = 0; i < BPPE_GUARD_WORDS; i++)
	{
		bench486_parseparticleeffect_message.before[i] = 0x486d31a5U;
		bench486_parseparticleeffect_message.after[i] = 0x5a13c84eU;
	}
	Bench486ParseParticleEffectWritePacket (test->message_count, test->color);

	Q_memset (&bench486_parseparticleeffect_pool, 0x5a,
			sizeof(bench486_parseparticleeffect_pool));
	for (i = 0; i < BPPE_GUARD_WORDS; i++)
	{
		bench486_parseparticleeffect_pool.before[i] = 0x486d31a5U;
		bench486_parseparticleeffect_pool.after[i] = 0x5a13c84eU;
	}
	bench486_parseparticleeffect_pool.nodes[BPPE_ACTIVE_HEAD].next =
			&bench486_parseparticleeffect_pool.nodes[BPPE_ACTIVE_TAIL];
	bench486_parseparticleeffect_pool.nodes[BPPE_ACTIVE_TAIL].next = NULL;
	for (i = 0; i < test->free_count; i++)
		bench486_parseparticleeffect_pool.nodes[BPPE_FREE_BASE+i].next =
				i+1 < test->free_count ?
				&bench486_parseparticleeffect_pool.nodes[BPPE_FREE_BASE+i+1] :
				NULL;

	active_particles =
			&bench486_parseparticleeffect_pool.nodes[BPPE_ACTIVE_HEAD];
	free_particles = test->free_count ?
			&bench486_parseparticleeffect_pool.nodes[BPPE_FREE_BASE] : NULL;
	Q_memset (&net_message, 0, sizeof(net_message));
	net_message.allowoverflow = false;
	net_message.overflowed = false;
	net_message.data = bench486_parseparticleeffect_message.bytes;
	net_message.maxsize = BPPE_PACKET_BYTES;
	net_message.cursize = test->packet_length;
	msg_readcount = 0;
	msg_badread = false;
}

static void Bench486ParseParticleEffectExpectedMessage (int length,
		int *readcount, qboolean *badread)
{
	int i, width;

	*readcount = 0;
	*badread = false;
	for (i = 0; i < 8; i++)
	{
		width = i < 3 ? 2 : 1;
		if (*readcount + width > length)
			*badread = true;
		else
			*readcount += width;
	}
}

static int Bench486ParseParticleEffectStateValid (
		const bench486_parseparticleeffect_case_t *test, unsigned emitted,
		unsigned random_calls, unsigned short test_cw,
		unsigned short top_before, const bench486_parseparticleeffect_result_t *r)
{
	static const short expected_coords[3] = { -32768, 32767, -1 };
	static const byte expected_directions[3] = { 0x80, 0x7f, 0xff };
	int i, expected_readcount, expected_emitted;
	unsigned short expected_coord;
	qboolean expected_badread;
	particle_t *expected_active, *expected_free;

	Bench486ParseParticleEffectExpectedMessage (test->packet_length,
			&expected_readcount, &expected_badread);
	expected_emitted = emitted > (unsigned)test->free_count ?
			test->free_count : (int)emitted;
	expected_active = expected_emitted ?
			&bench486_parseparticleeffect_pool.nodes[
					BPPE_FREE_BASE+expected_emitted-1] :
			&bench486_parseparticleeffect_pool.nodes[BPPE_ACTIVE_HEAD];
	expected_free = test->free_count > expected_emitted ?
			&bench486_parseparticleeffect_pool.nodes[
					BPPE_FREE_BASE+expected_emitted] : NULL;

	if (active_particles != expected_active || free_particles != expected_free ||
			bench486_parseparticleeffect_pool.nodes[BPPE_ACTIVE_HEAD].next !=
				&bench486_parseparticleeffect_pool.nodes[BPPE_ACTIVE_TAIL] ||
			bench486_parseparticleeffect_pool.nodes[BPPE_ACTIVE_TAIL].next != NULL)
	{
		bench486_parseparticleeffect_state_reason = 1;
		return 0;
	}
	for (i = 0; i < expected_emitted; i++)
	{
		particle_t *expected_next;

		expected_next = i ?
				&bench486_parseparticleeffect_pool.nodes[BPPE_FREE_BASE+i-1] :
				&bench486_parseparticleeffect_pool.nodes[BPPE_ACTIVE_HEAD];
		if (bench486_parseparticleeffect_pool.nodes[BPPE_FREE_BASE+i].next !=
				expected_next)
		{
			bench486_parseparticleeffect_state_reason = 2;
			return 0;
		}
	}
	for (i = expected_emitted; i < test->free_count; i++)
	{
		particle_t *expected_next;

		expected_next = i+1 < test->free_count ?
				&bench486_parseparticleeffect_pool.nodes[BPPE_FREE_BASE+i+1] :
				NULL;
		if (bench486_parseparticleeffect_pool.nodes[BPPE_FREE_BASE+i].next !=
				expected_next)
		{
			bench486_parseparticleeffect_state_reason = 3;
			return 0;
		}
	}
	for (i = 0; i < BPPE_GUARD_WORDS; i++)
	{
		if (bench486_parseparticleeffect_pool.before[i] != 0x486d31a5U ||
				bench486_parseparticleeffect_pool.after[i] != 0x5a13c84eU ||
			bench486_parseparticleeffect_message.before[i] != 0x486d31a5U ||
				bench486_parseparticleeffect_message.after[i] != 0x5a13c84eU)
		{
			bench486_parseparticleeffect_state_reason = 4;
			return 0;
		}
	}
	for (i = 0; i < 3; i++)
	{
		expected_coord = (unsigned short)expected_coords[i];
		if (bench486_parseparticleeffect_message.bytes[i*2] !=
				(byte)expected_coord ||
				bench486_parseparticleeffect_message.bytes[i*2+1] !=
					(byte)(expected_coord >> 8) ||
				bench486_parseparticleeffect_message.bytes[6+i] !=
					expected_directions[i])
		{
			bench486_parseparticleeffect_state_reason = 7;
			return 0;
		}
	}
	if (bench486_parseparticleeffect_message.bytes[9] !=
			(byte)test->message_count ||
			bench486_parseparticleeffect_message.bytes[10] !=
				(byte)test->color)
	{
		bench486_parseparticleeffect_state_reason = 7;
		return 0;
	}
	if (net_message.data != bench486_parseparticleeffect_message.bytes ||
			net_message.maxsize != BPPE_PACKET_BYTES ||
			net_message.cursize != test->packet_length ||
			net_message.allowoverflow || net_message.overflowed ||
			msg_readcount != expected_readcount || msg_badread != expected_badread ||
			bench486_runparticleeffect_rand_calls != random_calls ||
			bench486_parseparticleeffect_random_index !=
				test->random_start + random_calls ||
			Q_memcmp (&cl.time, (void *)&test->time, sizeof(test->time)) ||
			ramp1[0] != test->color)
	{
		bench486_parseparticleeffect_state_reason = 5;
		return 0;
	}
	if (r->x87_cw != test_cw || (r->x87_sw & 0x3800) != top_before ||
			r->abi != 0)
	{
		bench486_parseparticleeffect_state_reason = 6;
		return 0;
	}
	return 1;
}

static unsigned Bench486ParseParticleEffectRunSide (void (*function)(void),
		const bench486_parseparticleeffect_case_t *test, unsigned emitted,
		unsigned random_calls, unsigned short test_cw,
		bench486_parseparticleeffect_result_t *result)
{
	unsigned short top_before;

	Bench486ParseParticleEffectPrepare (test);
	cl.time = test->time;
	ramp1[0] = test->color;
	bench486_runparticleeffect_rand_probe =
			Bench486ParseParticleEffectRandom;
	bench486_runparticleeffect_rand_calls = 0;
	bench486_parseparticleeffect_random_index = test->random_start;
	__asm__ __volatile__ ("fnclex\n\tfldcw %0" : : "m" (test_cw));
	__asm__ __volatile__ ("fnstsw %0" : "=m" (top_before));
	result->abi = Bench486Call_asm486 (function, 0, NULL, NULL);
	__asm__ __volatile__ ("fnstcw %0\n\tfnstsw %1"
			: "=m" (result->x87_cw), "=m" (result->x87_sw));
	result->x87_top_before = top_before & 0x3800;
	result->active = active_particles;
	result->free = free_particles;
	result->client_time = cl.time;
	result->ramp_zero = ramp1[0];
	result->readcount = msg_readcount;
	result->badread = msg_badread;
	result->random_calls = bench486_runparticleeffect_rand_calls;
	result->random_index = bench486_parseparticleeffect_random_index;
	result->next_random = Bench486ParseParticleEffectRandomPeek (
			bench486_parseparticleeffect_random_index);
	Q_memcpy (result->pool, &bench486_parseparticleeffect_pool,
			sizeof(bench486_parseparticleeffect_pool));
	Q_memcpy (result->packet, &bench486_parseparticleeffect_message,
			sizeof(bench486_parseparticleeffect_message));
	result->message = net_message;
	bench486_parseparticleeffect_state_reason = 0;
	result->state_valid = Bench486ParseParticleEffectStateValid (test,
			emitted, random_calls, test_cw, result->x87_top_before, result);
	result->state_reason = 0;
	if (!result->state_valid)
		result->state_reason = bench486_parseparticleeffect_state_reason;
	return result->abi;
}

static void Bench486ParseParticleEffectCompare (
		const bench486_parseparticleeffect_case_t *test, int rounding_mode)
{
	unsigned c_abi, asm_abi, decoded_count, emitted, random_calls;
	unsigned short test_cw;
	int expected_count;
	int equal;

	expected_count = test->packet_length >= 10 ?
			(test->message_count & 255) : -1;
	decoded_count = expected_count == 255 ? 1024U :
			(expected_count > 0 ? (unsigned)expected_count : 0U);
	emitted = decoded_count > (unsigned)test->free_count ?
			(unsigned)test->free_count : decoded_count;
	random_calls = emitted * (decoded_count == 1024U ? 7U : 5U);
	__asm__ __volatile__ ("fnstcw %0" : "=m" (test_cw));
	test_cw = (unsigned short)((test_cw & ~0x0c00U) |
			((rounding_mode & 3) << 10));

	/* Rebuild the deterministic packet before each side; the first side's
	 * execution only mutates message cursor state and particle-list memory. */
	Bench486ParseParticleEffectWritePacket (test->message_count, test->color);
	c_abi = Bench486ParseParticleEffectRunSide (
			R_ParseParticleEffect_C, test, emitted, random_calls, test_cw,
			&bench486_parseparticleeffect_c_result);
	Bench486ParseParticleEffectWritePacket (test->message_count, test->color);
	asm_abi = Bench486ParseParticleEffectRunSide (
			R_ParseParticleEffect_asm486, test, emitted, random_calls, test_cw,
			&bench486_parseparticleeffect_asm_result);

	equal = c_abi == 0 && asm_abi == 0 &&
			bench486_parseparticleeffect_c_result.state_valid &&
			bench486_parseparticleeffect_asm_result.state_valid &&
			bench486_parseparticleeffect_c_result.readcount ==
				bench486_parseparticleeffect_asm_result.readcount &&
			bench486_parseparticleeffect_c_result.badread ==
				bench486_parseparticleeffect_asm_result.badread &&
			bench486_parseparticleeffect_c_result.random_calls ==
				bench486_parseparticleeffect_asm_result.random_calls &&
			bench486_parseparticleeffect_c_result.random_index ==
				bench486_parseparticleeffect_asm_result.random_index &&
			bench486_parseparticleeffect_c_result.next_random ==
				bench486_parseparticleeffect_asm_result.next_random &&
			bench486_parseparticleeffect_c_result.x87_cw ==
				bench486_parseparticleeffect_asm_result.x87_cw &&
			bench486_parseparticleeffect_c_result.x87_top_before ==
				bench486_parseparticleeffect_asm_result.x87_top_before &&
			!Q_memcmp (bench486_parseparticleeffect_c_result.pool,
				bench486_parseparticleeffect_asm_result.pool,
				sizeof(bench486_parseparticleeffect_pool)) &&
			!Q_memcmp (bench486_parseparticleeffect_c_result.packet,
				bench486_parseparticleeffect_asm_result.packet,
				sizeof(bench486_parseparticleeffect_message)) &&
			!Q_memcmp (&bench486_parseparticleeffect_c_result.message,
				&bench486_parseparticleeffect_asm_result.message,
				sizeof(net_message)) &&
			bench486_parseparticleeffect_c_result.active ==
				bench486_parseparticleeffect_asm_result.active &&
			bench486_parseparticleeffect_c_result.free ==
				bench486_parseparticleeffect_asm_result.free &&
			!Q_memcmp (&bench486_parseparticleeffect_c_result.client_time,
				&bench486_parseparticleeffect_asm_result.client_time,
				sizeof(double)) &&
			bench486_parseparticleeffect_c_result.ramp_zero ==
				bench486_parseparticleeffect_asm_result.ramp_zero;

	if (!equal)
		Bench486Printf ("parse-particle-effect %s rm%d FAIL c-abi %u asm-abi %u c-state %d asm-state %d read %d/%d bad %d/%d rng %u/%u cw %04x/%04x sw %04x/%04x\n",
				test->name, rounding_mode, c_abi, asm_abi,
				bench486_parseparticleeffect_c_result.state_reason,
				bench486_parseparticleeffect_asm_result.state_reason,
				bench486_parseparticleeffect_c_result.readcount,
				bench486_parseparticleeffect_asm_result.readcount,
				bench486_parseparticleeffect_c_result.badread,
				bench486_parseparticleeffect_asm_result.badread,
				bench486_parseparticleeffect_c_result.random_calls,
				bench486_parseparticleeffect_asm_result.random_calls,
				bench486_parseparticleeffect_c_result.x87_cw,
				bench486_parseparticleeffect_asm_result.x87_cw,
				bench486_parseparticleeffect_c_result.x87_sw,
				bench486_parseparticleeffect_asm_result.x87_sw);
	else
		Bench486Printf ("parse-particle-effect %s rm%d PASS (%u particles, %u RNG calls)\n",
				test->name, rounding_mode, emitted, random_calls);
	if (!equal)
		bench486_memory_failures++;
}

static void Bench486ParseParticleEffectCases (void)
{
	static const bench486_parseparticleeffect_case_t complete_cases[] = {
		{ "count-0-empty", 11, 0, 0, 1, 31.125, 0 },
		{ "count-0-full", 11, 0, 2048, 2, 31.250, 255 },
		{ "count-1-empty", 11, 1, 0, 3, 31.375, 17 },
		{ "count-1-one", 11, 1, 1, 4, 31.500, 226 },
		{ "count-1-full", 11, 1, 2048, 5, 31.625, 255 },
		{ "count-254-empty", 11, 254, 0, 6, 31.750, 73 },
		{ "count-254-partial", 11, 254, 17, 7, 31.875, 192 },
		{ "count-254-full", 11, 254, 2048, 8, 32.000, 255 },
		{ "count-255-empty", 11, 255, 0, 9, 32.125, 33 },
		{ "count-255-partial", 11, 255, 37, 10, 32.250, 77 },
		{ "count-255-full", 11, 255, 2048, 11, 32.375, 255 }
	};
	static const char *truncated_names[11] = {
		"truncated-0", "truncated-1", "truncated-2", "truncated-3",
		"truncated-4", "truncated-5", "truncated-6", "truncated-7",
		"truncated-8", "truncated-9", "truncated-10"
	};
	static bench486_parseparticleeffect_case_t truncated_case;
	static sizebuf_t saved_message;
	static particle_t *saved_active, *saved_free;
	static double saved_time;
	static int saved_ramp_zero, saved_readcount;
	static qboolean saved_badread;
	static int (*saved_rand_probe) (void);
	static unsigned saved_rand_calls, saved_random_index;
	static unsigned short saved_cw;
	int i, rounding_mode, failures_before;

	saved_message = net_message;
	saved_active = active_particles;
	saved_free = free_particles;
	Q_memcpy (&saved_time, &cl.time, sizeof(saved_time));
	saved_ramp_zero = ramp1[0];
	saved_readcount = msg_readcount;
	saved_badread = msg_badread;
	saved_rand_probe = bench486_runparticleeffect_rand_probe;
	saved_rand_calls = bench486_runparticleeffect_rand_calls;
	saved_random_index = bench486_parseparticleeffect_random_index;
	__asm__ __volatile__ ("fnstenv %0\n\tfldenv %0"
			: "=m" (bench486_parseparticleeffect_x87_env));
	saved_cw = bench486_parseparticleeffect_x87_env[0];
	failures_before = bench486_memory_failures;
	Bench486Printf ("parse-particle-effect C/ASM begin (%d complete, 11 truncated, four x87 rounding modes)\n",
			(int)(sizeof(complete_cases)/sizeof(complete_cases[0])));

	for (i = 0; i < (int)(sizeof(complete_cases)/sizeof(complete_cases[0])); i++)
	{
		for (rounding_mode = 0; rounding_mode < 4; rounding_mode++)
			Bench486ParseParticleEffectCompare (&complete_cases[i], rounding_mode);
	}
	for (i = 0; i <= 10; i++)
	{
		truncated_case.name = truncated_names[i];
		truncated_case.packet_length = i;
		truncated_case.message_count = 255;
		truncated_case.free_count = BPPE_FREE_CAPACITY;
		truncated_case.random_start = 101U + (unsigned)i;
		truncated_case.time = 33.0 + (double)i * 0.125;
		truncated_case.color = 255 - i;
		for (rounding_mode = 0; rounding_mode < 4; rounding_mode++)
			Bench486ParseParticleEffectCompare (&truncated_case,
					rounding_mode);
	}

	__asm__ __volatile__ ("fnclex\n\tfldcw %0" : : "m" (saved_cw));
	net_message = saved_message;
	active_particles = saved_active;
	free_particles = saved_free;
	Q_memcpy (&cl.time, &saved_time, sizeof(saved_time));
	ramp1[0] = saved_ramp_zero;
	msg_readcount = saved_readcount;
	msg_badread = saved_badread;
	bench486_runparticleeffect_rand_probe = saved_rand_probe;
	bench486_runparticleeffect_rand_calls = saved_rand_calls;
	bench486_parseparticleeffect_random_index = saved_random_index;
	__asm__ __volatile__ ("fldenv %0" : : "m" (bench486_parseparticleeffect_x87_env));
	Bench486Printf ("parse-particle-effect C/ASM %s (%d failures)\n",
			bench486_memory_failures == failures_before ? "PASS" : "FAIL",
			bench486_memory_failures - failures_before);
}

#endif /* ASM486_PARSE_PARTICLE_EFFECT */

#endif /* BENCH486_PARSEPARTICLEEFFECT_H */
