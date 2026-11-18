/* Direct C-oracle/assembly differential checks for V_ParseDamage.
 *
 * Integration contract: include this header from bench486_harness.c after
 * quakedef.h and the BENCH486 declarations.  The view implementation must
 * export V_ParseDamage_C and V_ParseDamage_asm486, and the selected build
 * must define ASM486_V_PARSE_DAMAGE.  Call Bench486VParseDamageCases from
 * the BENCH486 correctness phase.  The fixture owns only private static test
 * storage and restores every global it changes.
 */
/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
#ifndef BENCH486_VDAMAGE_H
#define BENCH486_VDAMAGE_H

#ifdef ASM486_V_PARSE_DAMAGE

#define BVPD_VIEW_ENTITY 3
#define BVPD_MESSAGE_BYTES 8
#define BVPD_GUARD_WORDS 4

extern void V_ParseDamage_C (void);
extern void V_ParseDamage_asm486 (void);
extern unsigned Bench486Call_asm486 (void (*function)(void), unsigned words,
		const unsigned *arguments, float *float_return);
extern sizebuf_t net_message;
extern vec3_t forward, right, up;
extern float v_dmg_time, v_dmg_roll, v_dmg_pitch;
extern cvar_t v_kicktime, v_kickroll, v_kickpitch;

typedef char bench486_vdamage_requires_i386[
		(sizeof(void *) == 4 && sizeof(int) == 4 && sizeof(unsigned) == 4 &&
			sizeof(unsigned long) == 4) ?
		1 : -1];

typedef struct
{
	const char *name;
	int armor, blood;
	short coord[3];
	int initial_percent;
	double client_time;
	float entity_origin[3];
	float entity_angles[3];
	float kick_time, kick_roll, kick_pitch;
} bench486_vdamage_case_t;

typedef struct
{
	unsigned before[BVPD_GUARD_WORDS];
	byte bytes[BVPD_MESSAGE_BYTES];
	unsigned after[BVPD_GUARD_WORDS];
} bench486_vdamage_message_t;

typedef struct
{
	client_state_t client;
	entity_t view_entity;
	vec3_t forward, right, up;
	float damage_time, damage_roll, damage_pitch;
	int readcount;
	qboolean badread;
	int message_intact;
} bench486_vdamage_result_t;

static bench486_vdamage_message_t bench486_vdamage_message;
static byte bench486_vdamage_expected_bytes[BVPD_MESSAGE_BYTES];

static int Bench486VPDMessageIntact (int length)
{
	int i;
	for (i = 0; i < BVPD_GUARD_WORDS; i++)
		if (bench486_vdamage_message.before[i] != 0x486d31a5U ||
				bench486_vdamage_message.after[i] != 0x5a13c84eU)
			return 0;
	if (Q_memcmp (bench486_vdamage_message.bytes,
			bench486_vdamage_expected_bytes, BVPD_MESSAGE_BYTES))
		return 0;
	if (net_message.data != bench486_vdamage_message.bytes ||
			net_message.maxsize != BVPD_MESSAGE_BYTES ||
			net_message.cursize != length || net_message.allowoverflow ||
			net_message.overflowed)
		return 0;
	return 1;
}

static void Bench486VPDPrepare (	const bench486_vdamage_case_t *test,
		int message_length)
{
	int i;
	unsigned short value;

	/* Fixed, fully initialized state makes bytewise client/entity checks safe. */
	Q_memset (&cl, 0, sizeof(cl));
	cl.time = test->client_time;
	cl.viewentity = BVPD_VIEW_ENTITY;
	cl.faceanimtime = -123.25f;
	cl.cshifts[CSHIFT_DAMAGE].percent = test->initial_percent;
	cl.cshifts[CSHIFT_DAMAGE].destcolor[0] = 19;
	cl.cshifts[CSHIFT_DAMAGE].destcolor[1] = 37;
	cl.cshifts[CSHIFT_DAMAGE].destcolor[2] = 73;
	Q_memset (&cl_entities[BVPD_VIEW_ENTITY], 0,
			sizeof(cl_entities[BVPD_VIEW_ENTITY]));
	for (i = 0; i < 3; i++)
	{
		cl_entities[BVPD_VIEW_ENTITY].origin[i] = test->entity_origin[i];
		cl_entities[BVPD_VIEW_ENTITY].angles[i] = test->entity_angles[i];
	}
	/* Exact binary seeds vary by case and expose a missing AngleVectors write. */
	forward[0] = -1024.0f - test->armor;
	forward[1] = 2048.0f + test->blood;
	forward[2] = -3072.0f + test->coord[0] * 0.125f;
	right[0] = 4096.0f + test->coord[1] * 0.125f;
	right[1] = -5120.0f - test->armor;
	right[2] = 6144.0f + test->blood;
	up[0] = -7168.0f - test->coord[2] * 0.125f;
	up[1] = 8192.0f + test->armor;
	up[2] = -9216.0f - test->blood;
	v_dmg_time = -17.25f;
	v_dmg_roll = 29.5f;
	v_dmg_pitch = -31.75f;
	v_kicktime.value = test->kick_time;
	v_kickroll.value = test->kick_roll;
	v_kickpitch.value = test->kick_pitch;

	Q_memset (&bench486_vdamage_message, 0xa5,
			sizeof(bench486_vdamage_message));
	for (i = 0; i < BVPD_GUARD_WORDS; i++)
	{
		bench486_vdamage_message.before[i] = 0x486d31a5U;
		bench486_vdamage_message.after[i] = 0x5a13c84eU;
	}
	for (i = 0; i < BVPD_MESSAGE_BYTES; i++)
		bench486_vdamage_message.bytes[i] = (byte)(0xd3U ^
				((unsigned)i * 29U));
	bench486_vdamage_message.bytes[0] = (byte)test->armor;
	bench486_vdamage_message.bytes[1] = (byte)test->blood;
	for (i = 0; i < 3; i++)
	{
		value = (unsigned short)test->coord[i];
		bench486_vdamage_message.bytes[2 + i * 2] = (byte)value;
		bench486_vdamage_message.bytes[3 + i * 2] = (byte)(value >> 8);
	}
	Q_memcpy (bench486_vdamage_expected_bytes,
			bench486_vdamage_message.bytes, BVPD_MESSAGE_BYTES);

	net_message.allowoverflow = false;
	net_message.overflowed = false;
	net_message.data = bench486_vdamage_message.bytes;
	net_message.maxsize = BVPD_MESSAGE_BYTES;
	net_message.cursize = message_length;
	msg_readcount = 0;
	msg_badread = false;
}

static void Bench486VPDExpectedMessageState (int length, int *readcount,
		qboolean *badread)
{
	int i;
	*readcount = 0;
	*badread = false;
	if (length < 1)
		*badread = true;
	else
		(*readcount)++;
	if (*readcount + 1 > length)
		*badread = true;
	else
		(*readcount)++;
	for (i = 0; i < 3; i++)
	{
		if (*readcount + 2 > length)
			*badread = true;
		else
			*readcount += 2;
	}
}

static unsigned Bench486VPDCall (void (*function)(void),
		const bench486_vdamage_case_t *test, int message_length,
		unsigned short test_cw, bench486_vdamage_result_t *result,
		unsigned short *actual_cw, unsigned short *actual_sw)
{
	unsigned abi;

	Bench486VPDPrepare (test, message_length);
	__asm__ __volatile__ ("fnclex\n\tfldcw %0" : : "m" (test_cw));
	abi = Bench486Call_asm486 (function, 0, NULL, NULL);
	__asm__ __volatile__ ("fnstcw %0\n\tfnstsw %1"
			: "=m" (*actual_cw), "=m" (*actual_sw));
	Q_memcpy (&result->client, &cl, sizeof(cl));
	Q_memcpy (&result->view_entity, &cl_entities[BVPD_VIEW_ENTITY],
			sizeof(result->view_entity));
	Q_memcpy (result->forward, forward, sizeof(result->forward));
	Q_memcpy (result->right, right, sizeof(result->right));
	Q_memcpy (result->up, up, sizeof(result->up));
	result->damage_time = v_dmg_time;
	result->damage_roll = v_dmg_roll;
	result->damage_pitch = v_dmg_pitch;
	result->readcount = msg_readcount;
	result->badread = msg_badread;
	result->message_intact = Bench486VPDMessageIntact (message_length);
	return abi;
}

static int Bench486VPDSameResult (const bench486_vdamage_result_t *left,
		const bench486_vdamage_result_t *right)
{
	return !Q_memcmp ((void *)&left->client, (void *)&right->client,
				sizeof(left->client)) &&
			!Q_memcmp ((void *)&left->view_entity, (void *)&right->view_entity,
				sizeof(left->view_entity)) &&
			!Q_memcmp ((void *)left->forward, (void *)right->forward,
				sizeof(left->forward)) &&
			!Q_memcmp ((void *)left->right, (void *)right->right,
				sizeof(left->right)) &&
			!Q_memcmp ((void *)left->up, (void *)right->up,
				sizeof(left->up)) &&
			!Q_memcmp ((void *)&left->damage_time,
				(void *)&right->damage_time, sizeof(left->damage_time)) &&
			!Q_memcmp ((void *)&left->damage_roll,
				(void *)&right->damage_roll, sizeof(left->damage_roll)) &&
			!Q_memcmp ((void *)&left->damage_pitch,
				(void *)&right->damage_pitch, sizeof(left->damage_pitch)) &&
			left->readcount == right->readcount &&
			left->badread == right->badread &&
			left->message_intact && right->message_intact;
}

static unsigned Bench486VPDCompare (const bench486_vdamage_case_t *test,
		int message_length, int mode, unsigned short test_cw)
{
	/* Keep the two full client snapshots out of DOS's small benchmark stack. */
	static bench486_vdamage_result_t c_result, a_result;
	unsigned c_abi, a_abi;
	unsigned short c_cw, a_cw, c_sw, a_sw;
	int expected_readcount;
	int byte_offset;
	qboolean expected_badread;
	unsigned failures, c_roll_bits, a_roll_bits, c_pitch_bits, a_pitch_bits;
	static unsigned mismatch_details;

	c_abi = Bench486VPDCall (V_ParseDamage_C, test, message_length,
			test_cw, &c_result, &c_cw, &c_sw);
	a_abi = Bench486VPDCall (V_ParseDamage_asm486, test, message_length,
			test_cw, &a_result, &a_cw, &a_sw);
	Bench486VPDExpectedMessageState (message_length, &expected_readcount,
			&expected_badread);
	failures = 0;
	if (c_abi || a_abi)
	{
		Bench486Printf ("v-parse-damage ABI FAIL %s bytes %d RC%d C %x ASM %x\n",
				(char *)test->name, message_length, mode, c_abi, a_abi);
		failures++;
	}
	if (!Bench486VPDSameResult (&c_result, &a_result))
	{
		if (mismatch_details < 4)
		{
			mismatch_details++;
			Q_memcpy (&c_roll_bits, (void *)&c_result.damage_roll,
					sizeof(c_roll_bits));
			Q_memcpy (&a_roll_bits, (void *)&a_result.damage_roll,
					sizeof(a_roll_bits));
			Q_memcpy (&c_pitch_bits, (void *)&c_result.damage_pitch,
					sizeof(c_pitch_bits));
			Q_memcpy (&a_pitch_bits, (void *)&a_result.damage_pitch,
					sizeof(a_pitch_bits));
			Bench486Printf ("  state groups client %d entity %d vectors %d/%d/%d kicks %d/%d/%d message %d/%d\n",
					Q_memcmp ((void *)&c_result.client, (void *)&a_result.client,
							sizeof(c_result.client)) != 0,
					Q_memcmp ((void *)&c_result.view_entity,
							(void *)&a_result.view_entity,
							sizeof(c_result.view_entity)) != 0,
					Q_memcmp (c_result.forward, a_result.forward,
							sizeof(c_result.forward)) != 0,
					Q_memcmp (c_result.right, a_result.right,
							sizeof(c_result.right)) != 0,
					Q_memcmp (c_result.up, a_result.up,
							sizeof(c_result.up)) != 0,
					Q_memcmp ((void *)&c_result.damage_time,
							(void *)&a_result.damage_time,
							sizeof(c_result.damage_time)) != 0,
					Q_memcmp ((void *)&c_result.damage_roll,
							(void *)&a_result.damage_roll,
							sizeof(c_result.damage_roll)) != 0,
					Q_memcmp ((void *)&c_result.damage_pitch,
							(void *)&a_result.damage_pitch,
							sizeof(c_result.damage_pitch)) != 0,
							c_result.message_intact, a_result.message_intact);
			Bench486Printf ("  kick bits roll C %08x ASM %08x pitch C %08x ASM %08x\n",
					c_roll_bits, a_roll_bits, c_pitch_bits, a_pitch_bits);
			for (byte_offset = 0; byte_offset < sizeof(c_result.client);
					byte_offset++)
				if (((byte *)&c_result.client)[byte_offset] !=
						((byte *)&a_result.client)[byte_offset])
				{
					Bench486Printf ("  first client byte difference +%d: C %u ASM %u\n",
							byte_offset,
							((byte *)&c_result.client)[byte_offset],
							((byte *)&a_result.client)[byte_offset]);
					break;
				}
		}
		Bench486Printf ("v-parse-damage state mismatch %s bytes %d RC%d cursor %d/%d bad %d/%d\n",
				(char *)test->name, message_length, mode,
				c_result.readcount, a_result.readcount,
				c_result.badread, a_result.badread);
		failures++;
	}
	if (c_result.readcount != expected_readcount ||
			a_result.readcount != expected_readcount ||
			c_result.badread != expected_badread ||
			a_result.badread != expected_badread)
	{
		Bench486Printf ("v-parse-damage message contract FAIL %s bytes %d expected %d/%d C %d/%d ASM %d/%d\n",
				(char *)test->name, message_length, expected_readcount,
				expected_badread, c_result.readcount, c_result.badread,
				a_result.readcount, a_result.badread);
		failures++;
	}
	if (c_cw != test_cw || a_cw != test_cw)
	{
		Bench486Printf ("v-parse-damage x87 CW FAIL %s bytes %d RC%d expected %04x C %04x ASM %04x\n",
				(char *)test->name, message_length, mode, test_cw, c_cw, a_cw);
		failures++;
	}
	if ((c_sw & 0x3800) != (a_sw & 0x3800) ||
			(c_sw & 0x3800) != 0)
	{
		Bench486Printf ("v-parse-damage x87 TOP FAIL %s bytes %d RC%d C %04x ASM %04x\n",
				(char *)test->name, message_length, mode, c_sw, a_sw);
		failures++;
	}
	if ((c_sw & 0x003f) != (a_sw & 0x003f))
		Bench486Printf ("v-parse-damage x87 flags differ %s bytes %d RC%d C %04x ASM %04x (diagnostic)\n",
				(char *)test->name, message_length, mode, c_sw, a_sw);
	return failures;
}

static void Bench486VParseDamageCases (void)
{
	static const bench486_vdamage_case_t cases[] = {
		{ "minimum-zero", 0, 0, { 0, 0, 0 }, 0, 42.0,
			{ 0, 0, 0 }, { 0, 0, 0 }, 0.5f, 0.6f, 0.6f },
		{ "armor-dominates", 255, 1, { 80, -160, 240 }, -1000, 1234.567,
			{ 8, 4, 0 }, { 0, 90, 0 }, 0.25f, 1.25f, -0.75f },
		{ "equal-damage", 128, 128, { 32767, -32768, -1 }, 120, 0.125,
			{ -2048, 1024, 0.125f }, { 90, 180, 270 }, 0.75f, -0.5f, 0.25f },
		{ "blood-only", 0, 255, { -32768, 32767, 1 }, 149, 16777215.875,
			{ 4096, -4096, 0 }, { -90, 360, -360 }, 1.0f, 0.0f, 0.6f },
		{ "damage-percent-overflow", 254, 127, { 1, -1, 0 }, 1000, 0.2,
			{ 0.125f, -0.125f, 0 }, { 359.999f, -720, 1080 }, 0.125f, 2.0f, 1.5f },
		{ "zero-direction", 10, 9, { 1024, -2048, 3072 }, -20, -0.2,
			{ 128, -256, 384 }, { 0, 0, 0 }, 0.5f, 0.6f, 0.6f },
		{ "one-eighth-direction", 1, 10, { 1025, -2047, 3071 }, 0, 65535.75,
			{ 128, -256, 384 }, { 45, -135, 225 }, 0.5f, -1.0f, 0.375f },
		{ "minimum-percent-clamp", 0, 0, { -8, 16, -24 }, -999, 1.0,
			{ 1, 2, 3 }, { 180, 90, -90 }, 0.125f, 0.6f, 0.6f },
		{ "percent-upper-bound", 10, 0, { 32767, 0, -32768 }, 120, 987654.125,
			{ -4096, 0, 4096 }, { 720, -360, 180 }, 2.0f, 0.125f, -0.25f }
	};
	static const int byte_values[] = { 0, 1, 9, 10, 127, 128, 254, 255 };
	static const short coordinate_values[] = {
		(short)-32768, (short)-16384, (short)-1, (short)0,
		(short)1, (short)16384, (short)32767
	};
	static const float angle_values[] = {
		0, -0.0f, 45, -90, 180, 359.999f, 720, -1080
	};
	/* This fixture is synchronous and non-reentrant; save bulky state statically. */
	static client_state_t saved_client;
	static entity_t saved_entity;
	static vec3_t saved_forward, saved_right, saved_up;
	cvar_t saved_kicktime, saved_kickroll, saved_kickpitch;
	sizebuf_t saved_message;
	static unsigned long saved_fpu_state[27];
	float saved_damage_time, saved_damage_roll, saved_damage_pitch;
	int saved_readcount;
	qboolean saved_badread;
	unsigned short saved_cw, test_cw;
	unsigned failures, cases_run;
	int mode, i, armor_index, blood_index, axis, length;
	bench486_vdamage_case_t generated;

	Q_memcpy (&saved_client, &cl, sizeof(cl));
	Q_memcpy (&saved_entity, &cl_entities[BVPD_VIEW_ENTITY], sizeof(saved_entity));
	Q_memcpy (saved_forward, forward, sizeof(saved_forward));
	Q_memcpy (saved_right, right, sizeof(saved_right));
	Q_memcpy (saved_up, up, sizeof(saved_up));
	saved_kicktime = v_kicktime;
	saved_kickroll = v_kickroll;
	saved_kickpitch = v_kickpitch;
	saved_message = net_message;
	saved_damage_time = v_dmg_time;
	saved_damage_roll = v_dmg_roll;
	saved_damage_pitch = v_dmg_pitch;
	saved_readcount = msg_readcount;
	saved_badread = msg_badread;
	__asm__ __volatile__ ("fnstcw %0" : "=m" (saved_cw));
	__asm__ __volatile__ ("fnsave %0" : "=m" (saved_fpu_state) : : "memory");

	failures = cases_run = 0;
	Bench486Printf ("v-parse-damage C/ASM begin (9 directed cases, 64 armor/blood boundary pairs, all 8 truncated lengths; four x87 rounding modes)\n");
	for (mode = 0; mode < 4; mode++)
	{
		test_cw = (unsigned short)(((saved_cw | 0x003f) &
				(unsigned short)~0x0c00) | (mode << 10));
		Bench486Printf ("v-parse-damage rounding mode %d/4\n", mode + 1);
		for (i = 0; i < sizeof(cases) / sizeof(cases[0]); i++)
		{
			failures += Bench486VPDCompare (&cases[i], BVPD_MESSAGE_BYTES,
					mode, test_cw);
			cases_run++;
		}
		for (armor_index = 0; armor_index < 8; armor_index++)
			for (blood_index = 0; blood_index < 8; blood_index++)
			{
				generated.name = "armor-blood-boundary-grid";
				generated.armor = byte_values[armor_index];
				generated.blood = byte_values[blood_index];
				generated.initial_percent =
						((armor_index * 47 + blood_index * 23) % 351) - 100;
				generated.client_time = armor_index * 17.125 +
						blood_index * 0.03125;
				generated.kick_time = 0.125f + armor_index * 0.125f;
				generated.kick_roll = (blood_index - 3) * 0.375f;
				generated.kick_pitch = (armor_index - blood_index) * 0.25f;
				for (axis = 0; axis < 3; axis++)
				{
					generated.coord[axis] = coordinate_values[
							(armor_index + blood_index + axis * 3) % 7];
					generated.entity_origin[axis] = coordinate_values[
							(armor_index * 2 + blood_index + axis) % 7] * 0.125f;
					generated.entity_angles[axis] = angle_values[
							(armor_index + blood_index * 2 + axis) % 8];
				}
				failures += Bench486VPDCompare (&generated,
						BVPD_MESSAGE_BYTES, mode, test_cw);
				cases_run++;
			}
		for (length = 0; length < BVPD_MESSAGE_BYTES; length++)
		{
			failures += Bench486VPDCompare (&cases[1], length, mode, test_cw);
			cases_run++;
		}
	}

	/* Restore the complete ambient client and view state after direct calls. */
	Q_memcpy (&cl, &saved_client, sizeof(cl));
	Q_memcpy (&cl_entities[BVPD_VIEW_ENTITY], &saved_entity, sizeof(saved_entity));
	Q_memcpy (forward, saved_forward, sizeof(saved_forward));
	Q_memcpy (right, saved_right, sizeof(saved_right));
	Q_memcpy (up, saved_up, sizeof(saved_up));
	v_kicktime = saved_kicktime;
	v_kickroll = saved_kickroll;
	v_kickpitch = saved_kickpitch;
	net_message = saved_message;
	v_dmg_time = saved_damage_time;
	v_dmg_roll = saved_damage_roll;
	v_dmg_pitch = saved_damage_pitch;
	msg_readcount = saved_readcount;
	msg_badread = saved_badread;
	__asm__ __volatile__ ("fldcw %0" : : "m" (saved_cw));
	bench486_memory_failures += failures;
	Bench486Printf ("v-parse-damage C/ASM %s (%u direct comparisons; %u failures)\n",
			failures ? "FAIL" : "PASS", cases_run, failures);
	/* Restore incoming 387 registers, tags, status, and control after logging. */
	__asm__ __volatile__ ("frstor %0" : : "m" (saved_fpu_state) : "memory");
}

#undef BVPD_VIEW_ENTITY
#undef BVPD_MESSAGE_BYTES
#undef BVPD_GUARD_WORDS

#endif /* ASM486_V_PARSE_DAMAGE */
#endif /* BENCH486_VDAMAGE_H */
