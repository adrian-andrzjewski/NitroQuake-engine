/* Included only by the test-owned BENCH486 harness.
 * Independent C oracles preserve the original algorithms and call graph.
 * Exact state/result comparison; no floating-point or pixel tolerance.
 */
#ifdef ASM486_MATH_CLOSURE
extern void ProjectPointOnPlane (vec3_t, const vec3_t, const vec3_t);
extern void ProjectPointOnPlane_C (vec3_t, const vec3_t, const vec3_t);
extern void PerpendicularVector (vec3_t, const vec3_t);
extern void PerpendicularVector_C (vec3_t, const vec3_t);
extern void RotatePointAroundVector (vec3_t, const vec3_t, const vec3_t, float);
extern void RotatePointAroundVector_C (vec3_t, const vec3_t, const vec3_t, float);
extern float anglemod_C (float);
extern int VectorCompare_C (vec3_t, vec3_t);
extern void VectorMA_C (vec3_t, float, vec3_t, vec3_t);
extern vec_t _DotProduct_C (vec3_t, vec3_t);
extern void _VectorSubtract_C (vec3_t, vec3_t, vec3_t);
extern void _VectorAdd_C (vec3_t, vec3_t, vec3_t);
extern void _VectorCopy_C (vec3_t, vec3_t);
extern void CrossProduct_C (vec3_t, vec3_t, vec3_t);
extern vec_t Length_C (vec3_t);
extern void VectorInverse_C (vec3_t);
extern void VectorScale_C (vec3_t, vec_t, vec3_t);
extern int Q_log2_C (int);
extern void R_ConcatRotations_C (float[3][3], float[3][3], float[3][3]);
extern void R_ConcatTransforms_C (float[3][4], float[3][4], float[3][4]);
extern void FloorDivMod_C (double, double, int *, int *);
extern int GreatestCommonDivisor_C (int, int);

typedef void (*bench486_mathclosure_fn_t) (void);
typedef struct {
	unsigned before[4];
	float words[40];
	unsigned after[4];
} bench486_mathclosure_state_t;

static bench486_mathclosure_fn_t bench486_mc_c_functions[] = {
	(bench486_mathclosure_fn_t)ProjectPointOnPlane_C,
	(bench486_mathclosure_fn_t)PerpendicularVector_C,
	(bench486_mathclosure_fn_t)RotatePointAroundVector_C,
	(bench486_mathclosure_fn_t)anglemod_C,
	(bench486_mathclosure_fn_t)VectorCompare_C,
	(bench486_mathclosure_fn_t)VectorMA_C,
	(bench486_mathclosure_fn_t)_DotProduct_C,
	(bench486_mathclosure_fn_t)_VectorSubtract_C,
	(bench486_mathclosure_fn_t)_VectorAdd_C,
	(bench486_mathclosure_fn_t)_VectorCopy_C,
	(bench486_mathclosure_fn_t)CrossProduct_C,
	(bench486_mathclosure_fn_t)Length_C,
	(bench486_mathclosure_fn_t)VectorInverse_C,
	(bench486_mathclosure_fn_t)VectorScale_C,
	(bench486_mathclosure_fn_t)Q_log2_C,
	(bench486_mathclosure_fn_t)R_ConcatRotations_C,
	(bench486_mathclosure_fn_t)R_ConcatTransforms_C,
	(bench486_mathclosure_fn_t)FloorDivMod_C,
	(bench486_mathclosure_fn_t)GreatestCommonDivisor_C
};
static bench486_mathclosure_fn_t bench486_mc_a_functions[] = {
	(bench486_mathclosure_fn_t)ProjectPointOnPlane,
	(bench486_mathclosure_fn_t)PerpendicularVector,
	(bench486_mathclosure_fn_t)RotatePointAroundVector,
	(bench486_mathclosure_fn_t)anglemod,
	(bench486_mathclosure_fn_t)VectorCompare,
	(bench486_mathclosure_fn_t)VectorMA,
	(bench486_mathclosure_fn_t)_DotProduct,
	(bench486_mathclosure_fn_t)_VectorSubtract,
	(bench486_mathclosure_fn_t)_VectorAdd,
	(bench486_mathclosure_fn_t)_VectorCopy,
	(bench486_mathclosure_fn_t)CrossProduct,
	(bench486_mathclosure_fn_t)Length,
	(bench486_mathclosure_fn_t)VectorInverse,
	(bench486_mathclosure_fn_t)VectorScale,
	(bench486_mathclosure_fn_t)Q_log2,
	(bench486_mathclosure_fn_t)R_ConcatRotations,
	(bench486_mathclosure_fn_t)R_ConcatTransforms,
	(bench486_mathclosure_fn_t)FloorDivMod,
	(bench486_mathclosure_fn_t)GreatestCommonDivisor
};
static const char *bench486_mc_names[] = {
	"ProjectPointOnPlane", "PerpendicularVector", "RotatePointAroundVector",
	"anglemod", "VectorCompare", "VectorMA", "_DotProduct",
	"_VectorSubtract", "_VectorAdd", "_VectorCopy", "CrossProduct", "Length",
	"VectorInverse", "VectorScale", "Q_log2", "R_ConcatRotations",
	"R_ConcatTransforms", "FloorDivMod", "GreatestCommonDivisor"
};

static unsigned Bench486MCFloatWord (float value)
{
	unsigned word;
	Q_memcpy (&word, &value, sizeof(word));
	return word;
}

static void Bench486MCSeed (bench486_mathclosure_state_t *state, int phase)
{
	static const float vectors[][3] = {
		{0,0,0}, {-0.0f,0,-0.0f}, {1,0,0}, {-1,0,0}, {3,4,-5},
		{0.001f,-0.002f,0.003f}, {1.0e-20f,-2.0e-20f,3.0e-20f},
		{1.0e20f,-2.0e20f,3.0e20f}, {-32768.25f,65535.5f,-131072.75f},
		{0.999848f,0.017453f,0.0001f}, {37.125f,-91.75f,0.0000001f},
		{0.70710677f,-0.70710677f,0}
	};
	int i;
	for (i=0 ; i<4 ; i++)
	{
		state->before[i] = 0x486a1357 ^ i;
		state->after[i] = 0x486b2468 ^ i;
	}
	for (i=0 ; i<40 ; i++)
		state->words[i] = vectors[(phase + i/3) % 12][i%3];
}

/* The dispatch has no compiler jump table mixed into .text. It constructs
 * test inputs/aliases only; the routines under test perform all mathematics.
 */
static __attribute__((optimize("no-jump-tables"))) unsigned Bench486MCArguments (
		int operation, int phase, bench486_mathclosure_state_t *state,
		unsigned *arguments)
{
	static const float angles[] = {
		0,-0.0f,0.001f,-0.001f,89.999f,90,179.999f,-180,359.999f,
		-360.001f,720.125f,1048576.25f,-524288.5f,65535.5f
	};
	static const float scales[] = {0,-0.0f,1,-1,0.5f,-0.125f,1.0e-10f,32768.25f};
	static const double numerators[] = {
		0,1,-1,255,-255,65535,-65535,2147483647.0,-2147483647.0,
		1048576.0,-1048576.0,1073741823.0
	};
	static const double denominators[] = {1,2,3,7,256,65535,1048576};
	unsigned out;
	int q;
	double numerator, denominator;
	out = (unsigned)(state->words + 24);
	/* Exercise both complete and partial overlap where the C API permits it. */
	if ((phase % 5) < 3) out = (unsigned)(state->words + phase%3);
	else if ((phase % 5) == 3) out = (unsigned)(state->words + 12);
	arguments[0] = (unsigned)state->words;
	arguments[1] = (unsigned)(state->words+12);
	arguments[2] = out;
	switch (operation)
	{
	case 0:
		arguments[0] = out;
		arguments[1] = (unsigned)state->words;
		arguments[2] = (unsigned)(state->words+6);
		return 3;
	case 1:
		arguments[0] = out;
		arguments[1] = (unsigned)state->words;
		return 2;
	case 2:
		state->words[6] = (phase%3 == 0) ? 1 : 0;
		state->words[7] = (phase%3 == 1) ? 1 : 0;
		state->words[8] = (phase%3 == 2) ? -1 : 0;
		arguments[0] = out;
		arguments[1] = (unsigned)(state->words+6);
		arguments[2] = (unsigned)state->words;
		arguments[3] = Bench486MCFloatWord (angles[phase%14]);
		return 4;
	case 3:
		arguments[0] = Bench486MCFloatWord (angles[phase%14]);
		return 1;
	case 4:
		if (phase%2) Q_memcpy (state->words+12,state->words,3*sizeof(float));
		if (phase%4 == 3) state->words[14] = -state->words[14];
		return 2;
	case 5:
		arguments[1] = Bench486MCFloatWord (scales[phase%8]);
		arguments[2] = (unsigned)(state->words+12);
		arguments[3] = out;
		return 4;
	case 6: return 2;
	case 7: case 8: case 10: return 3;
	case 9:
		arguments[1] = out;
		return 2;
	case 11: case 12: return 1;
	case 13:
		arguments[1] = Bench486MCFloatWord (scales[phase%8]);
		return 3;
	case 14:
		q = phase%32;
		arguments[0] = (q == 31) ? 0x7fffffff : ((1U << q) - 1U);
		return 1;
	case 15: case 16:
		/* Matrix aliases are complete matrices, as used by the reference API. */
		arguments[2] = (phase%3 == 0) ? (unsigned)state->words :
			(phase%3 == 1) ? (unsigned)(state->words+12) : (unsigned)(state->words+24);
		return 3;
	case 17:
		numerator = numerators[phase%12];
		denominator = denominators[phase%7];
		Q_memcpy (arguments,&numerator,sizeof(numerator));
		Q_memcpy (arguments+2,&denominator,sizeof(denominator));
		arguments[4] = (unsigned)(state->words+24);
		arguments[5] = (unsigned)(state->words+25);
		return 6;
	case 18:
		arguments[0] = (phase%8 == 0) ? 0 : (0x7fffffffU >> (phase%31));
		arguments[1] = (phase%8 == 1) ? 0 : ((phase*65537U) & 0x7fffffffU);
		return 2;
	}
	return 0;
}

static int Bench486MCGuards (const bench486_mathclosure_state_t *state)
{
	int i;
	for (i=0 ; i<4 ; i++)
		if (state->before[i] != (0x486a1357U ^ i) ||
				state->after[i] != (0x486b2468U ^ i)) return 0;
	return 1;
}

static void Bench486MCDirectCase (int operation, int phase, unsigned short cw)
{
	bench486_mathclosure_state_t c_state, a_state;
	unsigned c_args[6], a_args[6], c_words, a_words, c_abi, a_abi;
	float c_float, a_float, *c_return, *a_return;
	int c_int, a_int;
	Bench486MCSeed (&c_state,phase);
	Q_memcpy (&a_state,&c_state,sizeof(c_state));
	c_words = Bench486MCArguments (operation,phase,&c_state,c_args);
	a_words = Bench486MCArguments (operation,phase,&a_state,a_args);
	c_int = a_int = 0;
	if (operation == 4)
	{
		c_int = VectorCompare_C ((float *)c_args[0],(float *)c_args[1]);
		a_int = VectorCompare ((float *)a_args[0],(float *)a_args[1]);
	}
	else if (operation == 14)
	{
		c_int = Q_log2_C (c_args[0]); a_int = Q_log2 (a_args[0]);
	}
	else if (operation == 18)
	{
		c_int = GreatestCommonDivisor_C (c_args[0],c_args[1]);
		a_int = GreatestCommonDivisor (a_args[0],a_args[1]);
	}
	c_float = a_float = 0;
	c_return = a_return = NULL;
	if (operation == 3 || operation == 6 || operation == 11)
	{
		c_return = &c_float; a_return = &a_float;
	}
	c_abi = Bench486Call_asm486 (bench486_mc_c_functions[operation],c_words,c_args,c_return);
	a_abi = Bench486Call_asm486 (bench486_mc_a_functions[operation],a_words,a_args,a_return);
	if (c_words != a_words || c_abi || a_abi || c_int != a_int ||
			Q_memcmp (&c_float,&a_float,sizeof(c_float)) ||
			Q_memcmp (&c_state,&a_state,sizeof(c_state)) ||
			!Bench486MCGuards (&c_state) || !Bench486MCGuards (&a_state))
	{
		bench486_memory_failures++;
		Bench486Printf ("math-closure FAIL %s phase %d cw %04x ABI %x/%x integer %d/%d\n",
				bench486_mc_names[operation],phase,cw,c_abi,a_abi,c_int,a_int);
	}
}

static void Bench486MCSequence (void)
{
	bench486_mathclosure_state_t c_state, a_state;
	float delta[3][3], c_out[3][3], a_out[3][3];
	float angle[3];
	unsigned c_args[3], a_args[3], c_abi, a_abi;
	int frame, i;
	Bench486MCSeed (&c_state,0);
	for (i=0 ; i<9 ; i++) c_state.words[i] = (i%4 == 0) ? 1 : 0;
	Q_memcpy (&a_state,&c_state,sizeof(c_state));
	for (frame=0 ; frame<8192 ; frame++)
	{
		angle[0] = ((frame%7)-3)*0.125f;
		angle[1] = ((frame%11)-5)*0.0625f;
		angle[2] = ((frame%13)-6)*0.03125f;
		AngleVectors_C (angle,delta[0],delta[1],delta[2]);
		c_args[0] = (unsigned)c_state.words;
		a_args[0] = (unsigned)a_state.words;
		c_args[1] = a_args[1] = (unsigned)delta;
		c_args[2] = (unsigned)c_out; a_args[2] = (unsigned)a_out;
		c_abi = Bench486Call_asm486 ((bench486_mathclosure_fn_t)R_ConcatRotations_C,3,c_args,NULL);
		a_abi = Bench486Call_asm486 ((bench486_mathclosure_fn_t)R_ConcatRotations,3,a_args,NULL);
		Q_memcpy (c_state.words,c_out,sizeof(c_out));
		Q_memcpy (a_state.words,a_out,sizeof(a_out));
		if (c_abi || a_abi || Q_memcmp (&c_state,&a_state,sizeof(c_state)) ||
				!Bench486MCGuards (&c_state) || !Bench486MCGuards (&a_state))
		{
			bench486_memory_failures++;
			Bench486Printf ("math-closure sequence FAIL frame %d ABI %x/%x\n",frame,c_abi,a_abi);
			return;
		}
	}
}
#endif

static void Bench486MathClosureCases (void)
{
#ifdef ASM486_MATH_CLOSURE
	unsigned short saved_cw, test_cw;
	int precision, mode, operation, phase, start_failures, count;
	start_failures = bench486_memory_failures;
	count = 0;
	__asm__ __volatile__ ("fnstcw %0" : "=m" (saved_cw));
	for (precision=0 ; precision<=3 ; precision++)
	{
		if (precision == 1) continue;
		for (mode=0 ; mode<4 ; mode++)
		{
			test_cw = (saved_cw & ~0x0f00) | (precision << 8) | (mode << 10);
			__asm__ __volatile__ ("fldcw %0" : : "m" (test_cw));
			for (operation=0 ; operation<19 ; operation++)
				for (phase=0 ; phase<128 ; phase++)
				{
					Bench486MCDirectCase (operation,phase,test_cw);
					count++;
				}
		}
	}
	__asm__ __volatile__ ("fldcw %0" : : "m" (saved_cw));
	Bench486MCSequence ();
	Bench486Printf ("math-closure exact output/state/ABI/guards %s (%d direct cases; 8192 sequential matrix frames; %d failures)\n",
			bench486_memory_failures == start_failures ? "PASS" : "FAIL", count,
			bench486_memory_failures-start_failures);
#else
	bench486_memory_failures++;
	Bench486Printf ("math-closure FAIL: actual assembly selection is required\n");
#endif
}
