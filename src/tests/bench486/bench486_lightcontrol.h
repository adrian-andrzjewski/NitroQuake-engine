/* BENCH486 direct oracles for the complete r_light.c state/sample paths. */
/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
extern void R_AnimateLight_C (void);
extern void R_AnimateLight_asm486 (void);
extern void Bench486AnimateState_C (int *state, int restore);
extern void Bench486AnimateState_asm486 (int *state, int restore);
extern int RecursiveLightPoint_C (mnode_t *node, vec3_t start, vec3_t end);
extern int RecursiveLightPoint_asm486 (mnode_t *node, vec3_t start, vec3_t end);
extern int R_LightPoint_C (vec3_t point);
extern int R_LightPoint_asm486 (vec3_t point);

static void Bench486AnimatedLightStep (int sequence, unsigned short cw)
{
	static const double discontinuities[] = {
		0.0, 0.099999999, 0.1, 0.100000001, 1.0, 12.75, -0.1,
		-12.75, -0.0, 100000.125, -100000.125, 214748364.7,
		-214748364.8, 214748364.9, -214748364.9
	};
	int c_values[MAX_LIGHTSTYLES], c_state[130], a_state[130];
	unsigned c_abi, a_abi;
	int j, k, length;

	/* Every style can change length or become empty. Non-ASCII bytes exercise
	 * the current DJGPP oracle's signed-char map arithmetic as well. */
	for (j=0 ; j<MAX_LIGHTSTYLES ; j++)
	{
		length = (j + sequence/7) % 65;
		cl_lightstyle[j].length = length;
		for (k=0 ; k<length ; k++)
			cl_lightstyle[j].map[k] = (char)((sequence + j*17 + k*5) % 256);
	}
	if (sequence < sizeof(discontinuities)/sizeof(discontinuities[0]))
		cl.time = discontinuities[sequence];
	else if (sequence % 101 == 0)
		cl.time = -sequence * 1.75;
	else if (sequence % 103 == 0)
		cl.time = sequence * 13.125;
	else
		cl.time = (sequence/31) * 0.5 + (sequence%31) * 0.1;
	R_AnimateLight_C ();
	c_abi = Bench486Call_asm486 (R_AnimateLight_C,0,NULL,NULL);
	Q_memcpy (c_values,d_lightstylevalue,sizeof(c_values));
	Bench486AnimateState_C (c_state,0);
	R_AnimateLight_asm486 ();
	a_abi = Bench486Call_asm486 (R_AnimateLight_asm486,0,NULL,NULL);
	Bench486AnimateState_asm486 (a_state,0);
	if (c_abi || a_abi || Q_memcmp(c_values,d_lightstylevalue,sizeof(c_values)) ||
			Q_memcmp(c_state,a_state,sizeof(c_state)))
	{
		bench486_memory_failures++;
		if (bench486_memory_failures < 20)
			Bench486Printf ("animated-light FAIL sequence %d cw %04x ABI %x/%x\n",
					sequence,cw,c_abi,a_abi);
	}
}

static void Bench486AnimatedLightCases (void)
{
	lightstyle_t saved_styles[MAX_LIGHTSTYLES];
	int saved_values[MAX_LIGHTSTYLES], c_saved[130], a_saved[130], reset[130];
	double saved_time;
	unsigned short saved_cw, cw;
	int precision, mode, sequence, count, before;

	saved_time = cl.time;
	Q_memcpy(saved_styles,cl_lightstyle,sizeof(saved_styles));
	Q_memcpy(saved_values,d_lightstylevalue,sizeof(saved_values));
	Bench486AnimateState_C (c_saved,0);
	Bench486AnimateState_asm486 (a_saved,0);
	Q_memset(reset,0,sizeof(reset));
	__asm__ __volatile__ ("fnstcw %0" : "=m" (saved_cw));
	before = bench486_memory_failures;
	count = 0;
	for (precision=0 ; precision<=3 ; precision++)
	{
		if (precision == 1) continue;
		for (mode=0 ; mode<4 ; mode++)
		{
			cw = (saved_cw & ~0x0f00) | (precision<<8) | (mode<<10);
			__asm__ __volatile__ ("fldcw %0" : : "m" (cw));
			Bench486AnimateState_C (reset,1);
			Bench486AnimateState_asm486 (reset,1);
			for(sequence=0 ; sequence<512 ; sequence++,count++)
				Bench486AnimatedLightStep (sequence,cw);
		}
	}
	__asm__ __volatile__ ("fldcw %0" : : "m" (saved_cw));
	Bench486AnimateState_C (reset,1);
	Bench486AnimateState_asm486 (reset,1);
	for(sequence=0 ; sequence<8192 ; sequence++,count++)
		Bench486AnimatedLightStep (sequence,saved_cw);
	Bench486AnimateState_C (c_saved,1);
	Bench486AnimateState_asm486 (a_saved,1);
	Q_memcpy(cl_lightstyle,saved_styles,sizeof(saved_styles));
	Q_memcpy(d_lightstylevalue,saved_values,sizeof(saved_values));
	cl.time = saved_time;
	Bench486Printf ("animated-light exact values/state/ABI %s (%d frames; %d failures)\n",
			before == bench486_memory_failures ? "PASS" : "FAIL",count,
			bench486_memory_failures-before);
}

static void Bench486PointLightCase (int sequence, unsigned short cw)
{
	static struct {
		unsigned first;
		mnode_t nodes[128];
		mnode_t leaf;
		mplane_t planes[128];
		msurface_t surfaces[4];
		mtexinfo_t tex;
		byte samples[4*25];
		unsigned last;
	} fixture, saved_fixture;
	model_t world;
	vec3_t start, end, saved_start, saved_end;
	unsigned arguments[3], c_abi, a_abi;
	int c_result, a_result, c_point, a_point, i, j, mode;
	mnode_t *root;

	mode = sequence % 24;
	Q_memset(&fixture,0,sizeof(fixture));
	Q_memset(&world,0,sizeof(world));
	fixture.first = 0x486a1357;
	fixture.last = 0x486b2468;
	fixture.leaf.contents = CONTENTS_EMPTY;
	fixture.tex.vecs[0][0] = 1;
	fixture.tex.vecs[1][1] = 1;
	for(i=0 ; i<128 ; i++)
	{
		fixture.nodes[i].plane = &fixture.planes[i];
		fixture.nodes[i].children[0] = &fixture.leaf;
		fixture.nodes[i].children[1] = i == 127 ? &fixture.leaf : &fixture.nodes[i+1];
		fixture.planes[i].normal[2] = 1;
		fixture.planes[i].dist = 127-i;
	}
	fixture.nodes[127].numsurfaces = 4;
	for(i=0 ; i<4 ; i++)
	{
		fixture.surfaces[i].texinfo = &fixture.tex;
		fixture.surfaces[i].texturemins[0] = -32;
		fixture.surfaces[i].texturemins[1] = -32;
		fixture.surfaces[i].extents[0] = 64;
		fixture.surfaces[i].extents[1] = 64;
		fixture.surfaces[i].samples = fixture.samples;
		for(j=0 ; j<MAXLIGHTMAPS ; j++) fixture.surfaces[i].styles[j] = j;
		if(i<3) fixture.surfaces[i].flags = SURF_DRAWTILED;
	}
	for(i=0 ; i<sizeof(fixture.samples) ; i++)
		fixture.samples[i] = (byte)((i*37 + sequence*17) & 255);
	for(i=0 ; i<MAX_LIGHTSTYLES ; i++)
		d_lightstylevalue[i] = (sequence & 1) ? 256+i*11 : (int)(0xffffffffu-i*11117u);
	start[0] = 0.125f;
	start[1] = -15.875f;
	start[2] = 256.25f;
	end[0] = start[0]; end[1] = start[1]; end[2] = -256.5f;
	root = &fixture.nodes[0];
	world.nodes = root;
	world.surfaces = fixture.surfaces;
	world.lightdata = fixture.samples;
	r_refdef.ambientlight = sequence % 23;
	if(mode == 0) root = world.nodes = &fixture.leaf;
	if(mode == 1) world.lightdata = NULL;
	if(mode == 2) fixture.surfaces[3].samples = NULL;
	if(mode >= 3 && mode <= 6) fixture.surfaces[3].styles[mode-3] = 255;
	if(mode == 7) start[0] = end[0] = -32;
	if(mode == 8) start[0] = end[0] = 32;
	if(mode == 9) start[0] = end[0] = -32.001f;
	if(mode == 10) start[0] = end[0] = 33;
	if(mode == 11) start[1] = end[1] = -32;
	if(mode == 12) start[1] = end[1] = 32;
	if(mode == 13) start[1] = end[1] = -33;
	if(mode == 14) start[1] = end[1] = 33;
	if(mode == 15) end[2] = 256;
	if(mode == 16) start[2] = -256;
	if(mode == 17) start[0] = end[0] = 1048576.25f;
	if(mode == 18) start[1] = end[1] = -1048576.25f;
	if(mode == 19) fixture.surfaces[3].flags = SURF_DRAWTILED;
	if(mode == 20)
	{
		/* Frac is retained extended, but the midpoint stores are float. */
		root = world.nodes = &fixture.nodes[127];
		fixture.planes[127].normal[0] = 0.125f;
		fixture.planes[127].normal[1] = -0.25f;
		fixture.planes[127].dist = 0.03125f;
		start[0] = -31.875f; start[1] = 15.9375f;
		end[0] = 17.25f; end[1] = -13.125f;
	}
	if(mode == 21) fixture.tex.vecs[0][3] = 31.875f;
	if(mode == 22)
	{
		/* The first eligible surface wins even when another has brighter samples. */
		fixture.surfaces[0].flags = 0;
		fixture.surfaces[0].styles[0] = 255;
	}
	if(mode == 23)
	{
		/* Texture arithmetic order, fractional truncation and distant coordinates. */
		fixture.tex.vecs[0][0] = 0.0001f;
		fixture.tex.vecs[0][1] = -0.0002f;
		fixture.tex.vecs[0][2] = 0.03125f;
		fixture.tex.vecs[0][3] = -0.125f;
		start[0] = end[0] = 131072.125f;
		start[1] = end[1] = 65536.25f;
		fixture.tex.vecs[1][1] = 0.0001f;
	}
	cl.worldmodel = &world;
	Q_memcpy(&saved_fixture,&fixture,sizeof(fixture));
	Q_memcpy(saved_start,start,sizeof(start)); Q_memcpy(saved_end,end,sizeof(end));
	c_result = RecursiveLightPoint_C (root,start,end);
	a_result = RecursiveLightPoint_asm486 (root,start,end);
	arguments[0]=(unsigned)root; arguments[1]=(unsigned)start; arguments[2]=(unsigned)end;
	c_abi=Bench486Call_asm486((void (*)(void))RecursiveLightPoint_C,3,arguments,NULL);
	a_abi=Bench486Call_asm486((void (*)(void))RecursiveLightPoint_asm486,3,arguments,NULL);
	c_point=R_LightPoint_C(start); a_point=R_LightPoint_asm486(start);
	arguments[0]=(unsigned)start;
	c_abi |= Bench486Call_asm486((void (*)(void))R_LightPoint_C,1,arguments,NULL);
	a_abi |= Bench486Call_asm486((void (*)(void))R_LightPoint_asm486,1,arguments,NULL);
	if(c_result!=a_result || c_point!=a_point || c_abi || a_abi ||
			Q_memcmp(&fixture,&saved_fixture,sizeof(fixture)) ||
			Q_memcmp(start,saved_start,sizeof(start)) || Q_memcmp(end,saved_end,sizeof(end)))
	{
		bench486_memory_failures++;
		if(bench486_memory_failures < 20)
			Bench486Printf("point-light FAIL sequence %d mode %d cw %04x recursive %d/%d point %d/%d ABI %x/%x\n",
				sequence,mode,cw,c_result,a_result,c_point,a_point,c_abi,a_abi);
	}
}

static void Bench486PointLightCases (void)
{
	model_t *saved_world;
	int saved_ambient, saved_values[MAX_LIGHTSTYLES];
	unsigned short saved_cw, cw;
	int mode, precision, sequence, count, before;

	saved_world=cl.worldmodel; saved_ambient=r_refdef.ambientlight;
	Q_memcpy(saved_values,d_lightstylevalue,sizeof(saved_values));
	__asm__ __volatile__("fnstcw %0" : "=m"(saved_cw));
	count=0; before=bench486_memory_failures;
	for(precision=0 ; precision<=3 ; precision++)
	{
		if(precision == 1) continue;
		for(mode=0 ; mode<4 ; mode++)
		{
			cw=(saved_cw & ~0x0f00) | (precision<<8) | (mode<<10);
			__asm__ __volatile__("fldcw %0" : : "m"(cw));
			for(sequence=0 ; sequence<48 ; sequence++,count++)
				Bench486PointLightCase(sequence,cw);
		}
	}
	__asm__ __volatile__("fldcw %0" : : "m"(saved_cw));
	for(sequence=0 ; sequence<1024 ; sequence++,count++)
		Bench486PointLightCase(sequence,saved_cw);
	cl.worldmodel=saved_world; r_refdef.ambientlight=saved_ambient;
	Q_memcpy(d_lightstylevalue,saved_values,sizeof(saved_values));
	Bench486Printf("point-light exact samples/input/ABI %s (%d cases; %d failures)\n",
		before == bench486_memory_failures ? "PASS" : "FAIL",count,
		bench486_memory_failures-before);
}
