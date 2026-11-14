/* Direct V_Init registration/gamma parity fixture; BENCH486 only. */
#ifndef BENCH486_VINIT_H
#define BENCH486_VINIT_H

#if defined(BENCH486) && defined(ASM486_VIEW_CONTROL)

#define BVINIT_COMMAND_COUNT 3
#define BVINIT_PRE_GAMMA_CVAR_COUNT 25
#define BVINIT_CVAR_COUNT 26
#define BVINIT_EVENT_COUNT (BVINIT_COMMAND_COUNT + BVINIT_CVAR_COUNT)
#define BVINIT_EVENT_CAPACITY 32
#define BVINIT_NAME_CAPACITY 24
#define BVINIT_EVENT_COMMAND 1
#define BVINIT_EVENT_CVAR 2

extern void V_Init_View_C (void);
extern void V_Init_asm486 (void);
extern void V_Init (void);
extern void V_Init_SetBenchHooks (void (*addcmd)(char *, void (*)(void)),
		void (*regvar)(cvar_t *));
extern void V_Init_ClearBenchHooks (void);
extern unsigned Bench486Call_asm486 (void (*function)(void), unsigned words,
		const unsigned *arguments, float *float_return);
extern byte gammatable[256];

extern cvar_t lcd_x, lcd_yaw;
extern cvar_t v_centermove, v_centerspeed;
extern cvar_t v_iyaw_cycle, v_iroll_cycle, v_ipitch_cycle;
extern cvar_t v_iyaw_level, v_iroll_level, v_ipitch_level;
extern cvar_t v_idlescale, crosshair, cl_crossx, cl_crossy;
extern cvar_t scr_ofsx, scr_ofsy, scr_ofsz;
extern cvar_t cl_rollspeed, cl_rollangle, cl_bob, cl_bobcycle, cl_bobup;
extern cvar_t v_kicktime, v_kickroll, v_kickpitch, v_gamma;

extern void V_cshift_f (void);
extern void V_BonusFlash_f (void);
extern void V_StartPitchDrift (void);

typedef char bench486_vinit_requires_i386[
		(sizeof(void *) == 4 && sizeof(int) == 4 && sizeof(unsigned) == 4) ?
		1 : -1];

typedef struct
{
	int kind;
	char name[BVINIT_NAME_CAPACITY];
	void (*command)(void);
	cvar_t *variable;
} bench486_vinit_event_t;

typedef struct
{
	bench486_vinit_event_t events[BVINIT_EVENT_CAPACITY];
	unsigned count;
	unsigned overflow;
	unsigned abi;
	byte gamma[256];
} bench486_vinit_result_t;

static bench486_vinit_result_t bench486_vinit_capture;
static byte bench486_vinit_saved_gamma[256];
static bench486_vinit_result_t bench486_vinit_c_result;
static bench486_vinit_result_t bench486_vinit_asm_result;
static bench486_vinit_result_t bench486_vinit_public_result;

static const bench486_vinit_event_t bench486_vinit_expected[BVINIT_EVENT_COUNT] =
{
	{ BVINIT_EVENT_COMMAND, "v_cshift", V_cshift_f, NULL },
	{ BVINIT_EVENT_COMMAND, "bf", V_BonusFlash_f, NULL },
	{ BVINIT_EVENT_COMMAND, "centerview", V_StartPitchDrift, NULL },
	{ BVINIT_EVENT_CVAR, "lcd_x", NULL, &lcd_x },
	{ BVINIT_EVENT_CVAR, "lcd_yaw", NULL, &lcd_yaw },
	{ BVINIT_EVENT_CVAR, "v_centermove", NULL, &v_centermove },
	{ BVINIT_EVENT_CVAR, "v_centerspeed", NULL, &v_centerspeed },
	{ BVINIT_EVENT_CVAR, "v_iyaw_cycle", NULL, &v_iyaw_cycle },
	{ BVINIT_EVENT_CVAR, "v_iroll_cycle", NULL, &v_iroll_cycle },
	{ BVINIT_EVENT_CVAR, "v_ipitch_cycle", NULL, &v_ipitch_cycle },
	{ BVINIT_EVENT_CVAR, "v_iyaw_level", NULL, &v_iyaw_level },
	{ BVINIT_EVENT_CVAR, "v_iroll_level", NULL, &v_iroll_level },
	{ BVINIT_EVENT_CVAR, "v_ipitch_level", NULL, &v_ipitch_level },
	{ BVINIT_EVENT_CVAR, "v_idlescale", NULL, &v_idlescale },
	{ BVINIT_EVENT_CVAR, "crosshair", NULL, &crosshair },
	{ BVINIT_EVENT_CVAR, "cl_crossx", NULL, &cl_crossx },
	{ BVINIT_EVENT_CVAR, "cl_crossy", NULL, &cl_crossy },
	{ BVINIT_EVENT_CVAR, "scr_ofsx", NULL, &scr_ofsx },
	{ BVINIT_EVENT_CVAR, "scr_ofsy", NULL, &scr_ofsy },
	{ BVINIT_EVENT_CVAR, "scr_ofsz", NULL, &scr_ofsz },
	{ BVINIT_EVENT_CVAR, "cl_rollspeed", NULL, &cl_rollspeed },
	{ BVINIT_EVENT_CVAR, "cl_rollangle", NULL, &cl_rollangle },
	{ BVINIT_EVENT_CVAR, "cl_bob", NULL, &cl_bob },
	{ BVINIT_EVENT_CVAR, "cl_bobcycle", NULL, &cl_bobcycle },
	{ BVINIT_EVENT_CVAR, "cl_bobup", NULL, &cl_bobup },
	{ BVINIT_EVENT_CVAR, "v_kicktime", NULL, &v_kicktime },
	{ BVINIT_EVENT_CVAR, "v_kickroll", NULL, &v_kickroll },
	{ BVINIT_EVENT_CVAR, "v_kickpitch", NULL, &v_kickpitch },
	{ BVINIT_EVENT_CVAR, "gamma", NULL, &v_gamma }
};

static void Bench486VInitCopyName (char *destination, const char *source)
{
	unsigned i;

	for (i = 0; i < BVINIT_NAME_CAPACITY - 1 && source && source[i]; i++)
		destination[i] = source[i];
	destination[i] = 0;
}

static bench486_vinit_event_t *Bench486VInitNextEvent (void)
{
	bench486_vinit_event_t *event;

	if (bench486_vinit_capture.count >= BVINIT_EVENT_CAPACITY)
	{
		bench486_vinit_capture.overflow++;
		return NULL;
	}
	event = &bench486_vinit_capture.events[bench486_vinit_capture.count++];
	Q_memset (event, 0, sizeof(*event));
	return event;
}

static void Bench486VInitAddCommand (char *name, void (*function)(void))
{
	bench486_vinit_event_t *event = Bench486VInitNextEvent ();

	if (!event)
		return;
	event->kind = BVINIT_EVENT_COMMAND;
	Bench486VInitCopyName (event->name, name);
	event->command = function;
}

static void Bench486VInitRegisterVariable (cvar_t *variable)
{
	bench486_vinit_event_t *event = Bench486VInitNextEvent ();

	if (!event)
		return;
	event->kind = BVINIT_EVENT_CVAR;
	if (variable)
	{
		Bench486VInitCopyName (event->name, variable->name);
		event->variable = variable;
	}
}

static void Bench486VInitRun (void (*function)(void),
		bench486_vinit_result_t *result)
{
	int i;

	Q_memset (&bench486_vinit_capture, 0, sizeof(bench486_vinit_capture));
	for (i = 0; i < 256; i++)
		gammatable[i] = (byte)(255 - i);
	V_Init_SetBenchHooks (Bench486VInitAddCommand,
			Bench486VInitRegisterVariable);
	result->abi = Bench486Call_asm486 (function, 0, NULL, NULL);
	V_Init_ClearBenchHooks ();
	Q_memcpy (result->events, bench486_vinit_capture.events,
			sizeof(result->events));
	result->count = bench486_vinit_capture.count;
	result->overflow = bench486_vinit_capture.overflow;
	Q_memcpy (result->gamma, gammatable, sizeof(result->gamma));
}

static int Bench486VInitResultMatches (const bench486_vinit_result_t *result)
{
	int i;

	if (result->abi || result->count != BVINIT_EVENT_COUNT || result->overflow)
		return 0;
	if (Q_memcmp ((void *)result->events, (void *)bench486_vinit_expected,
			BVINIT_EVENT_COUNT * sizeof(bench486_vinit_expected[0])))
		return 0;
	for (i = 0; i < 256; i++)
		if (result->gamma[i] != (byte)i)
			return 0;
	return 1;
}

static void Bench486VInitCases (void)
{
	int i;
	unsigned failures = 0;

	Q_memcpy (bench486_vinit_saved_gamma, gammatable,
			sizeof(bench486_vinit_saved_gamma));
	Bench486Printf ("v-init C/ASM/public registration and gamma begin\n");
	Bench486VInitRun (V_Init_View_C, &bench486_vinit_c_result);
	Bench486VInitRun (V_Init_asm486, &bench486_vinit_asm_result);
	Bench486VInitRun (V_Init, &bench486_vinit_public_result);
	V_Init_ClearBenchHooks ();
	Q_memcpy (gammatable, bench486_vinit_saved_gamma,
			sizeof(bench486_vinit_saved_gamma));

	if (!Bench486VInitResultMatches (&bench486_vinit_c_result)) failures++;
	if (!Bench486VInitResultMatches (&bench486_vinit_asm_result)) failures++;
	if (!Bench486VInitResultMatches (&bench486_vinit_public_result)) failures++;
	if (bench486_vinit_c_result.abi != bench486_vinit_asm_result.abi ||
			bench486_vinit_c_result.count != bench486_vinit_asm_result.count ||
			Q_memcmp ((void *)bench486_vinit_c_result.events,
					(void *)bench486_vinit_asm_result.events,
					sizeof(bench486_vinit_c_result.events)) ||
			Q_memcmp ((void *)bench486_vinit_c_result.gamma,
					(void *)bench486_vinit_asm_result.gamma, 256))
		failures++;
	if (bench486_vinit_c_result.abi != bench486_vinit_public_result.abi ||
			bench486_vinit_c_result.count != bench486_vinit_public_result.count ||
			Q_memcmp ((void *)bench486_vinit_c_result.events,
					(void *)bench486_vinit_public_result.events,
					sizeof(bench486_vinit_c_result.events)) ||
			Q_memcmp ((void *)bench486_vinit_c_result.gamma,
					(void *)bench486_vinit_public_result.gamma, 256))
		failures++;
	for (i = 0; i < 3; i++)
	{
		bench486_vinit_result_t *result;
		if (i == 0) result = &bench486_vinit_c_result;
		else if (i == 1) result = &bench486_vinit_asm_result;
		else result = &bench486_vinit_public_result;
		if (result->abi || result->count != BVINIT_EVENT_COUNT || result->overflow)
			Bench486Printf ("  V_Init path %d ABI %x events %u overflow %u\n",
					i, result->abi, result->count, result->overflow);
	}
	if (failures)
		bench486_memory_failures += failures;
	Bench486Printf ("v-init C/ASM/public registration/gamma %s (%u commands, %u cvars: %u before gamma; %u failures)\n",
			failures ? "FAIL" : "PASS", BVINIT_COMMAND_COUNT,
			BVINIT_CVAR_COUNT, BVINIT_PRE_GAMMA_CVAR_COUNT, failures);
}

#undef BVINIT_COMMAND_COUNT
#undef BVINIT_PRE_GAMMA_CVAR_COUNT
#undef BVINIT_CVAR_COUNT
#undef BVINIT_EVENT_COUNT
#undef BVINIT_EVENT_CAPACITY
#undef BVINIT_NAME_CAPACITY
#undef BVINIT_EVENT_COMMAND
#undef BVINIT_EVENT_CVAR

#endif /* BENCH486 && ASM486_VIEW_CONTROL */
#endif /* BENCH486_VINIT_H */
