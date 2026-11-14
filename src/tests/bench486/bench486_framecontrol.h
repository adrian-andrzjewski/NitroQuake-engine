/* Independent BENCH486 oracles for viewport, frustum and visibility control.
 * Frame submission is also checked by the paired full-renderer demo suite. */
#ifdef ASM486_FRAME_CONTROL
extern void R_SetVrect_C (vrect_t *, vrect_t *, int);
extern void R_ViewChanged_C (vrect_t *, int, float);
extern int R_BmodelCheckBBox_C (model_t *, float *);
extern int R_BmodelCheckBBox (model_t *, float *);
extern void R_MarkLeaves_C (void);
extern void R_MarkLeaves (void);
extern int hunk_low_used;
extern float xscaleinv, yscaleinv, pixelAspect, screenAspect;
extern float verticalFieldOfView, xOrigin, yOrigin, r_aliastransition, r_resfudge;
extern mplane_t screenedge[4];
extern qboolean r_viewchanged, r_fov_greater_than_90;
extern mleaf_t *r_oldviewleaf;
extern int *pfrustum_indexes[4];
extern cvar_t scr_fov;

typedef struct
{
	refdef_t refdef;
	mplane_t planes[4];
	float scalar[20];
	int viewchanged, wide;
	int driver[10];
	float driver_scale;
	int scan[MAXHEIGHT];
	short *zscan[MAXHEIGHT];
} bench486_frame_view_state;

static void Bench486FrameViewState (bench486_frame_view_state *state, int restore)
{
	float *values[] = { &xcenter,&ycenter,&xscale,&yscale,&xscaleinv,&yscaleinv,
		&xscaleshrink,&yscaleshrink,&aliasxscale,&aliasyscale,&aliasxcenter,&aliasycenter,
		&pixelAspect,&screenAspect,&verticalFieldOfView,&xOrigin,&yOrigin,
		&r_aliastransition,&r_resfudge,&r_aliasuvscale };
	int *driver[] = { &d_zrowbytes,&d_zwidth,&d_pix_min,&d_pix_max,&d_pix_shift,
		&d_y_aspect_shift,&d_vrectx,&d_vrecty,&d_vrectright_particle,&d_vrectbottom_particle };
	int i;
	if (restore)
	{
		Q_memcpy(&r_refdef,&state->refdef,sizeof(r_refdef));
		Q_memcpy(screenedge,state->planes,sizeof(screenedge));
		for(i=0 ; i<20 ; i++) *values[i] = state->scalar[i];
		for(i=0 ; i<10 ; i++) *driver[i] = state->driver[i];
		r_viewchanged = state->viewchanged; r_fov_greater_than_90 = state->wide;
		scale_for_mip = state->driver_scale;
		Q_memcpy(d_scantable,state->scan,sizeof(state->scan));
		Q_memcpy(zspantable,state->zscan,sizeof(state->zscan));
	}
	else
	{
		Q_memset(state,0,sizeof(*state));
		Q_memcpy(&state->refdef,&r_refdef,sizeof(r_refdef));
		Q_memcpy(state->planes,screenedge,sizeof(screenedge));
		for(i=0 ; i<20 ; i++) state->scalar[i] = *values[i];
		for(i=0 ; i<10 ; i++) state->driver[i] = *driver[i];
		state->viewchanged = r_viewchanged; state->wide = r_fov_greater_than_90;
		state->driver_scale = scale_for_mip;
		Q_memcpy(state->scan,d_scantable,sizeof(state->scan));
		Q_memcpy(state->zscan,zspantable,sizeof(state->zscan));
	}
}

static void Bench486FrameFailure (const char *name, int phase, unsigned short cw,
		unsigned c_abi, unsigned a_abi)
{
	bench486_memory_failures++;
	if (bench486_memory_failures < 24)
		Bench486Printf("frame-control %s FAIL case %d cw %04x ABI %x/%x\n",
				name,phase,cw,c_abi,a_abi);
}

static void Bench486FrameViewportStep (int phase, unsigned short cw, int projection)
{
	static const float sizes[] = { 0.01f,20,29.999f,30,50,79.999f,80,99.999f,100,110 };
	static const float fovs[] = { 0.0001f,0.01f,1,10,30,60,89.999f,90,90.001f,120,170,179.5f };
	static const float aspects[] = { 0.5f,0.8333333f,1,1.4f,1.400001f,2 };
	struct { unsigned first; vrect_t input,output; unsigned last; } c_rect, a_rect;
	static bench486_frame_view_state before, c_state, a_state;
	unsigned args[3], c_abi, a_abi, color_before, color_after;
	float aspect;
	int bytes;
	Q_memset(&c_rect,0x5a,sizeof(c_rect));
	c_rect.first = 0x486a1357; c_rect.last = 0x486b2468;
	c_rect.input.x = phase%17; c_rect.input.y = phase%13;
	c_rect.input.width = 320 - (phase%12)*8;
	c_rect.input.height = 200 - (phase%8)*2;
	c_rect.input.pnext = NULL;
	c_rect.output = c_rect.input;
	a_rect = c_rect;
	scr_viewsize.value = sizes[phase%10];
	cl.intermission = phase%19 == 0;
	lcd_x.value = phase%3 == 0;
	args[0] = (unsigned)((phase%11 == 0 && !projection) ? &c_rect.output : &c_rect.input);
	args[1] = projection ? phase%49 : (unsigned)&c_rect.output;
	args[2] = phase%49;
	if (!projection)
	{
		c_abi = Bench486Call_asm486((void (*)(void))R_SetVrect_C,3,args,NULL);
		args[0] = (unsigned)((phase%11 == 0) ? &a_rect.output : &a_rect.input);
		args[1] = (unsigned)&a_rect.output;
		a_abi = Bench486Call_asm486((void (*)(void))R_SetVrect,3,args,NULL);
		if (c_abi || a_abi || Q_memcmp(&c_rect,&a_rect,sizeof(c_rect)) ||
				c_rect.first != 0x486a1357 || c_rect.last != 0x486b2468)
			Bench486FrameFailure("viewport",phase,cw,c_abi,a_abi);
		return;
	}
	r_refdef.fov_x = fovs[phase%12];
	scr_fov.value = r_refdef.fov_x;
	r_refdef.xOrigin = 0.125f + (phase%4)*0.25f;
	r_refdef.yOrigin = 0.125f + ((phase/3)%4)*0.25f;
	r_aliasuvscale = 0.5f + (phase%4)*0.5f;
	aspect = aspects[phase%6];
	Q_memcpy(&args[2],&aspect,sizeof(aspect));
	bytes = vid.rowbytes * vid.height;
	color_before = vid.buffer ? Bench486Checksum(vid.buffer,bytes) : 0;
	Bench486FrameViewState(&before,0);
	c_abi = Bench486Call_asm486((void (*)(void))R_ViewChanged_C,3,args,NULL);
	Bench486FrameViewState(&c_state,0);
	Bench486FrameViewState(&before,1);
	args[0] = (unsigned)&a_rect.input;
	a_abi = Bench486Call_asm486((void (*)(void))R_ViewChanged,3,args,NULL);
	Bench486FrameViewState(&a_state,0);
	color_after = vid.buffer ? Bench486Checksum(vid.buffer,bytes) : 0;
	if (c_abi || a_abi || Q_memcmp(&c_state,&a_state,sizeof(c_state)) ||
			Q_memcmp(&c_rect,&a_rect,sizeof(c_rect)) || color_before != color_after ||
			c_rect.first != 0x486a1357 || c_rect.last != 0x486b2468)
		Bench486FrameFailure("projection",phase,cw,c_abi,a_abi);
}

static void Bench486FrameBBoxStep (int phase, unsigned short cw)
{
	static const float coordinates[] = { 0,0.00001f,-0.00001f,1,-1,32768.25f,-65536.5f,1.0e20f,-1.0e20f };
	struct { unsigned first; model_t model; unsigned last; } model, saved_model;
	struct { unsigned first; float v[6]; unsigned last; } bounds, saved_bounds;
	entity_t entity, saved_entity;
	unsigned args[2], c_abi, a_abi;
	int indexes[4][6], i, j, c_flags, a_flags;
	Q_memset(&model,0,sizeof(model));Q_memset(&bounds,0,sizeof(bounds));
	Q_memset(&entity,0,sizeof(entity));
	model.first = bounds.first = 0x486a1357;
	model.last = bounds.last = 0x486b2468;
	model.model.radius = 0.125f + (phase%31)*1.75f;
	for(i=0 ; i<3 ; i++)
	{
		entity.origin[i] = coordinates[(phase+i)%9];
		entity.angles[i] = (phase%2) ? (float)(phase*11-i*7) : 0;
		bounds.v[i] = entity.origin[i] - model.model.radius;
		bounds.v[i+3] = entity.origin[i] + model.model.radius;
	}
	for(i=0 ; i<4 ; i++)
	{
		for(j=0 ; j<3 ; j++)
		{
			view_clipplanes[i].normal[j] = ((phase+i+j)%3-1)*0.5f;
			indexes[i][j] = (view_clipplanes[i].normal[j] >= 0) ? j+3 : j;
			indexes[i][j+3] = (view_clipplanes[i].normal[j] >= 0) ? j : j+3;
		}
		view_clipplanes[i].dist = coordinates[(phase+i+4)%9];
		pfrustum_indexes[i] = indexes[i];
	}
	currententity = &entity;
	saved_model = model; saved_bounds = bounds; saved_entity = entity;
	args[0] = (unsigned)&model.model; args[1] = (unsigned)bounds.v;
	c_flags = R_BmodelCheckBBox_C(&model.model,bounds.v);
	c_abi = Bench486Call_asm486((void (*)(void))R_BmodelCheckBBox_C,2,args,NULL);
	a_flags = R_BmodelCheckBBox(&model.model,bounds.v);
	a_abi = Bench486Call_asm486((void (*)(void))R_BmodelCheckBBox,2,args,NULL);
	if (c_abi || a_abi || c_flags != a_flags || Q_memcmp(&model,&saved_model,sizeof(model)) ||
			Q_memcmp(&bounds,&saved_bounds,sizeof(bounds)) || Q_memcmp(&entity,&saved_entity,sizeof(entity)))
		Bench486FrameFailure("bbox",phase,cw,c_abi,a_abi);
}

static struct { unsigned first; mleaf_t leaf[65]; unsigned last; } bench486_fc_leafs;
static struct { unsigned first; mnode_t node[16]; unsigned last; } bench486_fc_nodes;
static model_t bench486_fc_world;
static byte bench486_fc_vis[16];

static void Bench486FrameVisibilityStep (int phase, unsigned short cw)
{
	static mleaf_t original_leafs[65], c_leafs[65];
	static mnode_t original_nodes[16], c_nodes[16];
	mleaf_t *original_old, *c_old;
	unsigned c_abi, a_abi;
	int i, n, old_count, c_count;
	n = 0;
	for(i=0 ; i<8 ; i++)
	{
		byte value = (byte)(phase*17+i*31);
		bench486_fc_vis[n++] = value;
		if (!value) bench486_fc_vis[n++] = 1;
	}
	for(i=0 ; i<65 ; i++) bench486_fc_leafs.leaf[i].compressed_vis = phase%23 ? bench486_fc_vis : NULL;
	r_viewleaf = &bench486_fc_leafs.leaf[phase%65];
	if (phase%13 == 0) r_oldviewleaf = r_viewleaf;
	Q_memcpy(original_leafs,bench486_fc_leafs.leaf,sizeof(original_leafs));
	Q_memcpy(original_nodes,bench486_fc_nodes.node,sizeof(original_nodes));
	original_old = r_oldviewleaf; old_count = r_visframecount;
	c_abi = Bench486Call_asm486(R_MarkLeaves_C,0,NULL,NULL);
	c_old = r_oldviewleaf; c_count = r_visframecount;
	Q_memcpy(c_leafs,bench486_fc_leafs.leaf,sizeof(c_leafs));
	Q_memcpy(c_nodes,bench486_fc_nodes.node,sizeof(c_nodes));
	Q_memcpy(bench486_fc_leafs.leaf,original_leafs,sizeof(original_leafs));
	Q_memcpy(bench486_fc_nodes.node,original_nodes,sizeof(original_nodes));
	r_oldviewleaf = original_old; r_visframecount = old_count;
	a_abi = Bench486Call_asm486(R_MarkLeaves,0,NULL,NULL);
	if (c_abi || a_abi || c_old != r_oldviewleaf || c_count != r_visframecount ||
			Q_memcmp(c_leafs,bench486_fc_leafs.leaf,sizeof(c_leafs)) ||
			Q_memcmp(c_nodes,bench486_fc_nodes.node,sizeof(c_nodes)) ||
			bench486_fc_leafs.first != 0x486a1357 || bench486_fc_leafs.last != 0x486b2468 ||
			bench486_fc_nodes.first != 0x486a1357 || bench486_fc_nodes.last != 0x486b2468)
		Bench486FrameFailure("visibility",phase,cw,c_abi,a_abi);
}

static void Bench486FrameControlCases (void)
{
	static bench486_frame_view_state saved_view;
	entity_t *saved_entity;
	model_t *saved_world;
	mleaf_t *saved_leaf, *saved_old;
	clipplane_t saved_clip[4];
	int *saved_indexes[4];
	float saved_size, saved_lcd, saved_fov;
	int saved_intermission, saved_viscount, saved_hunk_mark;
	int i, precision, mode, phase, count, before, mark_index, mark_count, c_mark, a_mark;
	unsigned c_mark_abi, a_mark_abi;
	static const int hunk_marks[] = { 0,1,3,4,15,16,31,32,4096,0x12345678,-1 };
	unsigned short saved_cw, cw;
	before = bench486_memory_failures; count = 0;
	Bench486FrameViewState(&saved_view,0);
	saved_entity = currententity; saved_world = cl.worldmodel;
	saved_leaf = r_viewleaf; saved_old = r_oldviewleaf; saved_viscount = r_visframecount;
	saved_size = scr_viewsize.value; saved_lcd = lcd_x.value; saved_fov = scr_fov.value;
	saved_intermission = cl.intermission;
	Q_memcpy(saved_clip,view_clipplanes,sizeof(saved_clip));
	Q_memcpy(saved_indexes,pfrustum_indexes,sizeof(saved_indexes));
	saved_hunk_mark = hunk_low_used;
	mark_count = sizeof(hunk_marks) / sizeof(hunk_marks[0]);
	__asm__ __volatile__("fnstcw %0" : "=m"(saved_cw));
	for(mark_index=0 ; mark_index<mark_count ; mark_index++)
	{
		hunk_low_used = hunk_marks[mark_index];
		c_mark = Hunk_LowMark_C();
		a_mark = Hunk_LowMark();
		c_mark_abi = Bench486Call_asm486((void (*)(void))Hunk_LowMark_C,0,NULL,NULL);
		a_mark_abi = Bench486Call_asm486((void (*)(void))Hunk_LowMark,0,NULL,NULL);
		if (c_mark != a_mark || c_mark_abi || a_mark_abi)
		{
			bench486_memory_failures++;
			if (bench486_memory_failures < 24)
				Bench486Printf("frame-control hunk-mark FAIL case %d cw %04x C %08x ASM %08x ABI %x/%x\n",
						mark_index,saved_cw,(unsigned)c_mark,(unsigned)a_mark,c_mark_abi,a_mark_abi);
		}
		count++;
	}
	hunk_low_used = saved_hunk_mark;
	Q_memset(&bench486_fc_world,0,sizeof(bench486_fc_world));
	Q_memset(&bench486_fc_leafs,0,sizeof(bench486_fc_leafs));
	Q_memset(&bench486_fc_nodes,0,sizeof(bench486_fc_nodes));
	bench486_fc_leafs.first = bench486_fc_nodes.first = 0x486a1357;
	bench486_fc_leafs.last = bench486_fc_nodes.last = 0x486b2468;
	bench486_fc_world.numleafs = 64; bench486_fc_world.leafs = bench486_fc_leafs.leaf;
	bench486_fc_world.nodes = bench486_fc_nodes.node;
	for(i=0 ; i<16 ; i++) bench486_fc_nodes.node[i].parent = i ? &bench486_fc_nodes.node[(i-1)/2] : NULL;
	for(i=0 ; i<65 ; i++)
	{
		bench486_fc_leafs.leaf[i].contents = CONTENTS_EMPTY;
		bench486_fc_leafs.leaf[i].parent = &bench486_fc_nodes.node[8+(i%8)];
	}
	cl.worldmodel = &bench486_fc_world; r_oldviewleaf = NULL;
	r_visframecount = (int)0x7ffffff0u;
	for(precision=0 ; precision<4 ; precision++)
	{
		if (precision == 1) continue;
		for(mode=0 ; mode<4 ; mode++)
		{
			cw = (saved_cw & ~0x0f00) | (precision<<8) | (mode<<10);
			__asm__ __volatile__("fldcw %0" : : "m"(cw));
			for(phase=0 ; phase<128 ; phase++)
			{
				Bench486FrameViewportStep(phase,cw,0);
				Bench486FrameViewportStep(phase,cw,1);
				Bench486FrameBBoxStep(phase,cw);
				Bench486FrameVisibilityStep(phase,cw);
				count += 4;
			}
		}
	}
	__asm__ __volatile__("fldcw %0" : : "m"(saved_cw));
	for(phase=0 ; phase<8192 ; phase++)
	{
		Bench486FrameBBoxStep(phase,saved_cw);
		Bench486FrameVisibilityStep(phase,saved_cw);
		count += 2;
	}
	Bench486FrameViewState(&saved_view,1);
	currententity = saved_entity; cl.worldmodel = saved_world;
	r_viewleaf = saved_leaf; r_oldviewleaf = saved_old; r_visframecount = saved_viscount;
	scr_viewsize.value = saved_size; lcd_x.value = saved_lcd; scr_fov.value = saved_fov;
	cl.intermission = saved_intermission;
	Q_memcpy(view_clipplanes,saved_clip,sizeof(saved_clip));
	Q_memcpy(pfrustum_indexes,saved_indexes,sizeof(saved_indexes));
	Bench486Printf("frame-control exact viewport/projection/bbox/visibility/hunk-mark/ABI/guards %s (%d cases; %d Hunk_LowMark states; 8192 continuous visibility steps; %d failures)\n",
			bench486_memory_failures == before ? "PASS" : "FAIL",count,mark_count,bench486_memory_failures-before);
}
#else
static void Bench486FrameControlCases (void)
{
	bench486_memory_failures++;
	Bench486Printf("frame-control FAIL: select FrameControlImplementation asm to enable independent C and assembly oracles\n");
}
#endif
