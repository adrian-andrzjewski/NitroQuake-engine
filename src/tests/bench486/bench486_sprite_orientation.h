/* Included only by the test-owned BENCH486 harness. The original C functions
 * remain independent oracles, compiled in their original translation units. */
#include "tests/bench486/bench486_sprite_hooks.h"

extern unsigned Bench486Call_asm486 (void (*function)(void), unsigned words,
		const unsigned *arguments, float *float_result);

static int bench486_sprite_dispatch_count;

extern void Bench486FaultEBX_asm486 (void);
extern void Bench486FaultCW_asm486 (void);
extern void Bench486FaultESP_asm486 (void);
extern void Bench486FaultX87_asm486 (void);
extern void Bench486FaultDF_asm486 (void);

static void Bench486ABIFault (char *name, void (*function)(void), unsigned expected)
{
	unsigned actual;
	actual = Bench486Call_asm486 (function,0,NULL,NULL);
	if (actual != expected)
	{
		bench486_memory_failures++;
		Bench486Printf ("ABI fault detector %s FAIL expected %x actual %x\n",name,expected,actual);
	}
	else Bench486Printf ("ABI fault detector %s PASS mask %x\n",name,actual);
}

static void Bench486SpriteObserveDispatch (void)
{
	bench486_sprite_dispatch_count++;
}

static void Bench486RendererMathCases (void)
{
	static const float vectors[][3] = {
		{0,0,0}, {-0.0f,0,-0.0f}, {1,0,0}, {-1,0,0}, {3,4,0},
		{0.001f,-0.002f,0.003f}, {1.0e-20f,-2.0e-20f,3.0e-20f},
		{1.0e20f,-2.0e20f,3.0e20f}, {-32768.25f,65535.5f,-131072.75f},
		{0.999848f,0.017453f,0.0001f}, {37.125f,-91.75f,0.0000001f}
	};
	static const float angles[][3] = {
		{0,0,0}, {90,0,0}, {0,90,0}, {0,0,90}, {-90,180,-270},
		{17.125f,-31.75f,43.5f}, {0.001f,-0.002f,0.003f},
		{359.999f,-360.001f,720.125f}, {1048576.25f,-524288.5f,262144.75f},
		{-1.0e-20f,2.0e-20f,-3.0e-20f}
	};
	struct { unsigned first; float v[3]; unsigned last; } c_vector, a_vector;
	float c_length, a_length, c_axes[9], a_axes[9];
	unsigned arguments[4], c_abi, a_abi;
	unsigned short saved_cw, test_cw;
	int mode, precision, i, count, failures;

	__asm__ __volatile__ ("fnstcw %0" : "=m" (saved_cw));
	Bench486ABIFault ("callee-register",Bench486FaultEBX_asm486,1);
	Bench486ABIFault ("control-word",Bench486FaultCW_asm486,32);
	Bench486ABIFault ("stack-pointer",Bench486FaultESP_asm486,16);
	Bench486ABIFault ("x87-stack",Bench486FaultX87_asm486,192);
	Bench486ABIFault ("direction-flag",Bench486FaultDF_asm486,512);
	count = failures = 0;
	for (precision=0 ; precision<=3 ; precision++)
	{
		if (precision == 1) continue; /* Reserved x87 precision encoding. */
		for (mode=0 ; mode<4 ; mode++)
		{
			test_cw = (saved_cw & ~0x0f00) | (precision << 8) | (mode << 10);
			__asm__ __volatile__ ("fldcw %0" : : "m" (test_cw));
			for (i=0 ; i<sizeof(vectors)/sizeof(vectors[0]) ; i++)
			{
				c_vector.first = a_vector.first = 0x486a1357;
				c_vector.last = a_vector.last = 0x486b2468;
				Q_memcpy (c_vector.v, (void *)vectors[i], sizeof(c_vector.v));
				Q_memcpy (a_vector.v, (void *)vectors[i], sizeof(a_vector.v));
				arguments[0] = (unsigned)c_vector.v;
				c_abi = Bench486Call_asm486 ((void (*)(void))VectorNormalize_C,
						1, arguments, &c_length);
				arguments[0] = (unsigned)a_vector.v;
				a_abi = Bench486Call_asm486 ((void (*)(void))VectorNormalize_asm486,
						1, arguments, &a_length);
				if (c_abi || a_abi || Q_memcmp (&c_vector,&a_vector,sizeof(c_vector)) ||
						Q_memcmp (&c_length,&a_length,sizeof(c_length)) ||
						c_vector.first != 0x486a1357 || c_vector.last != 0x486b2468)
				{
					failures++; bench486_memory_failures++;
					Bench486Printf ("normalize parity FAIL case %d cw %04x ABI %x/%x\n",
							i, test_cw, c_abi, a_abi);
				}
				count++;
			}
			for (i=0 ; i<sizeof(angles)/sizeof(angles[0]) ; i++)
			{
				arguments[0] = (unsigned)angles[i];
				arguments[1] = (unsigned)c_axes;
				arguments[2] = (unsigned)(c_axes+3);
				arguments[3] = (unsigned)(c_axes+6);
				c_abi = Bench486Call_asm486 ((void (*)(void))AngleVectors_C,
						4, arguments, NULL);
				arguments[1] = (unsigned)a_axes;
				arguments[2] = (unsigned)(a_axes+3);
				arguments[3] = (unsigned)(a_axes+6);
				a_abi = Bench486Call_asm486 ((void (*)(void))AngleVectors_asm486,
						4, arguments, NULL);
				if (c_abi || a_abi || Q_memcmp(c_axes,a_axes,sizeof(c_axes)))
				{
					int word;
					failures++; bench486_memory_failures++;
					for (word=0 ; word<9 ; word++)
						if (Q_memcmp(c_axes+word,a_axes+word,sizeof(float))) break;
					Bench486Printf ("angle-vectors parity FAIL case %d cw %04x ABI %x/%x word %d\n",
							i, test_cw, c_abi, a_abi, word);
				}
				count++;
			}
		}
	}
	__asm__ __volatile__ ("fldcw %0" : : "m" (saved_cw));
	Bench486Printf ("renderer-math exact output/ABI %s (%d cases; %d failures)\n",
			failures ? "FAIL" : "PASS", count, failures);
}

static void Bench486SpriteOrientationCase (int sequence, unsigned short cw)
{
	entity_t entity, *saved_entity;
	model_t model;
	msprite_t sprite;
	mspriteframe_t frame;
	spritedesc_t saved_desc, initial_desc, c_desc;
	vec3_t saved_org, saved_origin, saved_up, saved_right, saved_normal;
	vec3_t c_org, c_origin;
	int saved_width, saved_height, c_width, c_height, c_dispatch;
	unsigned c_abi, a_abi;
	void (*saved_hook)(void);

	Q_memset (&entity, 0, sizeof(entity));
	Q_memset (&model, 0, sizeof(model));
	Q_memset (&sprite, 0, sizeof(sprite));
	Q_memset (&frame, 0, sizeof(frame));
	sprite.type = sequence % 5;
	sprite.numframes = 1;
	sprite.frames[0].type = SPR_SINGLE;
	sprite.frames[0].frameptr = &frame;
	sprite.beamlength = (sequence & 1) ? 3.125f : -0.375f;
	frame.width = 17 + (sequence % 37);
	frame.height = 19 + (sequence % 29);
	model.cache.data = &sprite;
	entity.model = &model;
	entity.frame = sequence == 31 ? -1 : sequence == 36 ? 4 : 0;
	entity.angles[0] = (sequence - 17) * 13.125f;
	entity.angles[1] = (sequence - 13) * -17.25f;
	entity.angles[2] = (sequence - 11) * 33.375f;

	saved_entity = currententity;
	saved_hook = bench486_sprite_setup_hook;
	Q_memcpy (&saved_desc,&r_spritedesc,sizeof(saved_desc));
	Q_memcpy (saved_org,modelorg,sizeof(saved_org));
	Q_memcpy (saved_origin,r_entorigin,sizeof(saved_origin));
	Q_memcpy (saved_up,vup,sizeof(saved_up));
	Q_memcpy (saved_right,vright,sizeof(saved_right));
	Q_memcpy (saved_normal,vpn,sizeof(saved_normal));
	saved_width = sprite_width; saved_height = sprite_height;
	currententity = &entity;
	bench486_sprite_setup_hook = Bench486SpriteObserveDispatch;
	Q_memset (&r_spritedesc,0x5a,sizeof(r_spritedesc));
	Q_memcpy (&initial_desc,&r_spritedesc,sizeof(initial_desc));
	modelorg[0] = -37.125f; modelorg[1] = 22.75f; modelorg[2] = -120.25f;
	r_entorigin[0] = 73.5f; r_entorigin[1] = -31.75f; r_entorigin[2] = 80.125f;
	vright[0] = 0.87f; vright[1] = -0.31f; vright[2] = 0.12f;
	vup[0] = -0.20f; vup[1] = 0.91f; vup[2] = 0.24f;
	vpn[0] = 0.43f; vpn[1] = -0.17f; vpn[2] = 0.89f;
	/* Upright strict rejection on both sides, including adjacent float values. */
	if (sequence / 5 == 1) vpn[2] = 0.9998479f;
	if (sequence / 5 == 2) vpn[2] = 0.999848f;
	if (sequence / 5 == 3) vpn[2] = -0.9998479f;
	if (sequence / 5 == 4) vpn[2] = -0.999848f;
	if (sequence / 5 == 5)
		modelorg[0] = modelorg[1] = modelorg[2] = 0;
	if (sequence / 5 == 6) { modelorg[0] = 0; modelorg[1] = 0; modelorg[2] = -1; }
	if (sequence / 5 == 7) { modelorg[0] = 0; modelorg[1] = 0; modelorg[2] = 1; }
	if (sequence / 5 == 8) { modelorg[0] = -0.017455f; modelorg[1] = 0; modelorg[2] = -1; }
	if (sequence / 5 == 9) { modelorg[0] = -0.017454f; modelorg[1] = 0; modelorg[2] = 1; }
	Q_memcpy (c_org,modelorg,sizeof(c_org));
	Q_memcpy (c_origin,r_entorigin,sizeof(c_origin));
	bench486_sprite_dispatch_count = 0;
	c_abi = Bench486Call_asm486 (R_DrawSprite_C,0,NULL,NULL);
	Q_memcpy (&c_desc,&r_spritedesc,sizeof(c_desc));
	c_width = sprite_width; c_height = sprite_height;
	c_dispatch = bench486_sprite_dispatch_count;
	/* Preserve C outputs, then restore identical inputs for the assembly call. */
	{
		vec3_t input_org, input_origin;
		Q_memcpy (input_org,c_org,sizeof(input_org));
		Q_memcpy (input_origin,c_origin,sizeof(input_origin));
		Q_memcpy (c_org,modelorg,sizeof(c_org));
		Q_memcpy (c_origin,r_entorigin,sizeof(c_origin));
		Q_memcpy (modelorg,input_org,sizeof(input_org));
		Q_memcpy (r_entorigin,input_origin,sizeof(input_origin));
	}
	Q_memcpy (&r_spritedesc,&initial_desc,sizeof(initial_desc));
	bench486_sprite_dispatch_count = 0;
	a_abi = Bench486Call_asm486 (R_DrawSprite_asm486,0,NULL,NULL);
	if (c_abi || a_abi || Q_memcmp(&c_desc,&r_spritedesc,sizeof(c_desc)) ||
			Q_memcmp(c_org,modelorg,sizeof(c_org)) ||
			Q_memcmp(c_origin,r_entorigin,sizeof(c_origin)) ||
			c_width != sprite_width || c_height != sprite_height ||
			c_dispatch != bench486_sprite_dispatch_count)
	{
		int word;
		bench486_memory_failures++;
		for (word=0 ; word<sizeof(c_desc)/sizeof(unsigned) ; word++)
			if (Q_memcmp((byte *)&c_desc+word*4,(byte *)&r_spritedesc+word*4,4)) break;
		Bench486Printf ("sprite-orientation parity FAIL sequence %d type %d cw %04x ABI %x/%x dispatch %d/%d word %d\n",
				sequence,sprite.type,cw,c_abi,a_abi,c_dispatch,
				bench486_sprite_dispatch_count,word);
	}
	currententity = saved_entity;
	bench486_sprite_setup_hook = saved_hook;
	Q_memcpy (&r_spritedesc,&saved_desc,sizeof(saved_desc));
	Q_memcpy (modelorg,saved_org,sizeof(saved_org));
	Q_memcpy (r_entorigin,saved_origin,sizeof(saved_origin));
	Q_memcpy (vup,saved_up,sizeof(saved_up));
	Q_memcpy (vright,saved_right,sizeof(saved_right));
	Q_memcpy (vpn,saved_normal,sizeof(saved_normal));
	sprite_width = saved_width; sprite_height = saved_height;
}

static void Bench486SpriteOrientationCases (void)
{
	unsigned short saved_cw,test_cw;
	int mode,precision,sequence,before,count;
	__asm__ __volatile__ ("fnstcw %0" : "=m" (saved_cw));
	before = bench486_memory_failures;
	count = 0;
	for (precision=0 ; precision<=3 ; precision++)
	{
		if (precision == 1) continue;
		for (mode=0 ; mode<4 ; mode++)
		{
			test_cw = (saved_cw & ~0x0f00) | (precision << 8) | (mode << 10);
			__asm__ __volatile__ ("fldcw %0" : : "m" (test_cw));
			for (sequence=0 ; sequence<50 ; sequence++)
			{
				Bench486SpriteOrientationCase(sequence,test_cw);
				count++;
			}
		}
	}
	__asm__ __volatile__ ("fldcw %0" : : "m" (saved_cw));
	/* Consecutive changing entity state: expose stack/register/state leakage. */
	for (sequence=0 ; sequence<2048 ; sequence++)
	{
		Bench486SpriteOrientationCase(sequence,saved_cw);
		count++;
	}
	Bench486Printf ("sprite-orientation exact axes/frame/beam/dispatch/ABI %s (%d cases; %d failures)\n",
			before == bench486_memory_failures ? "PASS" : "FAIL",count,
			bench486_memory_failures-before);
}
