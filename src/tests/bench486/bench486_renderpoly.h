/* Direct C/assembly parity fixture for the polygon transform and projection.
   D_DrawPoly is the lifetime boundary: both implementations keep pverts in
   their stack frame, so the BENCH-only driver hook copies the descriptor and
   vertex records before that frame returns. */
/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
#ifndef BENCH486_RENDERPOLY_H
#define BENCH486_RENDERPOLY_H

#if defined(BENCH486) && defined(ASM486_PUBLIC_BINDINGS) && \
        defined(ASM486_RENDER_POLY)

#define RPP_INPUT_VERTS 8
#define RPP_OUTPUT_VERTS 32
#define RPP_FNSAVE_BYTES 108
#define RPP_EXPECTED_PAIRS 168

extern unsigned Bench486Call_asm486 (void (*function)(void), unsigned words,
		const unsigned *arguments, float *float_return);
extern float r_nearzi;

typedef struct
{
	model_t model;
	entity_t entity;
	msurface_t surface;
	mplane_t faceplane;
	medge_t edges[RPP_INPUT_VERTS];
	int surfedges[RPP_INPUT_VERTS];
	mvertex_t vertices[RPP_INPUT_VERTS];
} bench486_renderpoly_fixture_t;

typedef struct
{
	unsigned calls;
	unsigned errors;
	int callback_numverts;
	float callback_nearzi;
	msurface_t *callback_face;
	polyvert_t vertices[RPP_OUTPUT_VERTS];
	int numverts;
	float nearzi;
	msurface_t *face;
	float global_nearzi;
	mvertex_t *current_vertices;
	medge_t *current_edge;
	clipplane_t *clip_next[4];
	unsigned abi;
	unsigned short x87_status;
} bench486_renderpoly_result_t;

typedef struct
{
	entity_t *currententity;
	mvertex_t *current_vertices;
	medge_t *current_edge;
	polydesc_t polydesc;
	float nearzi;
	clipplane_t view_clipplanes[4];
	refdef_t refdef;
	vec3_t modelorg;
	vec3_t vright;
	vec3_t vup;
	vec3_t vpn;
	float xscale, yscale, xcenter, ycenter;
	void (*draw_hook)(void);
} bench486_renderpoly_saved_state_t;

/* Defined here once by bench486_harness.c through
   bench486_publicbindings.h and read by the C D_DrawPoly seam in d_edge.c. */
void (*bench486_renderpoly_draw_hook)(void);
extern medge_t *r_pedge;

static bench486_renderpoly_fixture_t bench486_renderpoly_fixture;
static bench486_renderpoly_result_t bench486_renderpoly_c_result;
static bench486_renderpoly_result_t bench486_renderpoly_asm_result;
static bench486_renderpoly_result_t *bench486_renderpoly_active_result;
static bench486_renderpoly_saved_state_t bench486_renderpoly_saved_state;
static clipplane_t bench486_renderpoly_clip_sentinel;
static msurface_t bench486_renderpoly_face_sentinel;
static polyvert_t bench486_renderpoly_vertex_sentinel;
static unsigned char bench486_renderpoly_x87_state[RPP_FNSAVE_BYTES]
		__attribute__((aligned(4)));

static void Bench486RenderPolyCapture (void)
{
	bench486_renderpoly_result_t *result;
	int count;

	result = bench486_renderpoly_active_result;
	if (!result)
		return;
	result->calls++;
	if (result->calls != 1)
		result->errors++;
	result->callback_numverts = r_polydesc.numverts;
	Q_memcpy (&result->callback_nearzi, &r_polydesc.nearzi,
			sizeof(result->callback_nearzi));
	result->callback_face = r_polydesc.pcurrentface;
	count = r_polydesc.numverts;
	if (count < 0 || count > RPP_OUTPUT_VERTS ||
			(count && !r_polydesc.pverts))
	{
		result->errors++;
		return;
	}
	if (count)
		Q_memcpy (result->vertices, r_polydesc.pverts,
				count * sizeof(result->vertices[0]));
}

static void Bench486RenderPolySaveState (void)
{
	bench486_renderpoly_saved_state_t *saved;

	/* FNSAVE records the whole 387 state (environment and register stack) and
	   resets it. The saved image is restored after all cases. */
	__asm__ __volatile__ ("fnsave %0" : "=m" (bench486_renderpoly_x87_state)
			: : "memory");
	saved = &bench486_renderpoly_saved_state;
	saved->currententity = currententity;
	saved->current_vertices = r_pcurrentvertbase;
	saved->current_edge = r_pedge;
	Q_memcpy (&saved->polydesc, &r_polydesc, sizeof(saved->polydesc));
	Q_memcpy (&saved->nearzi, &r_nearzi, sizeof(saved->nearzi));
	Q_memcpy (saved->view_clipplanes, view_clipplanes,
			sizeof(saved->view_clipplanes));
	Q_memcpy (&saved->refdef, &r_refdef, sizeof(saved->refdef));
	Q_memcpy (saved->modelorg, modelorg, sizeof(saved->modelorg));
	Q_memcpy (saved->vright, vright, sizeof(saved->vright));
	Q_memcpy (saved->vup, vup, sizeof(saved->vup));
	Q_memcpy (saved->vpn, vpn, sizeof(saved->vpn));
	Q_memcpy (&saved->xscale, &xscale, sizeof(saved->xscale));
	Q_memcpy (&saved->yscale, &yscale, sizeof(saved->yscale));
	Q_memcpy (&saved->xcenter, &xcenter, sizeof(saved->xcenter));
	Q_memcpy (&saved->ycenter, &ycenter, sizeof(saved->ycenter));
	saved->draw_hook = bench486_renderpoly_draw_hook;
}

static void Bench486RenderPolyRestoreState (void)
{
	bench486_renderpoly_saved_state_t *saved;

	saved = &bench486_renderpoly_saved_state;
	currententity = saved->currententity;
	r_pcurrentvertbase = saved->current_vertices;
	r_pedge = saved->current_edge;
	Q_memcpy (&r_polydesc, &saved->polydesc, sizeof(r_polydesc));
	Q_memcpy (&r_nearzi, &saved->nearzi, sizeof(r_nearzi));
	Q_memcpy (view_clipplanes, saved->view_clipplanes,
			sizeof(saved->view_clipplanes));
	Q_memcpy (&r_refdef, &saved->refdef, sizeof(saved->refdef));
	Q_memcpy (modelorg, saved->modelorg, sizeof(saved->modelorg));
	Q_memcpy (vright, saved->vright, sizeof(saved->vright));
	Q_memcpy (vup, saved->vup, sizeof(saved->vup));
	Q_memcpy (vpn, saved->vpn, sizeof(saved->vpn));
	Q_memcpy (&xscale, &saved->xscale, sizeof(xscale));
	Q_memcpy (&yscale, &saved->yscale, sizeof(yscale));
	Q_memcpy (&xcenter, &saved->xcenter, sizeof(xcenter));
	Q_memcpy (&ycenter, &saved->ycenter, sizeof(ycenter));
	bench486_renderpoly_draw_hook = saved->draw_hook;
	bench486_renderpoly_active_result = NULL;
	__asm__ __volatile__ ("frstor %0" : : "m" (bench486_renderpoly_x87_state)
			: "memory");
}

static unsigned short Bench486RenderPolyX87Status (void)
{
	unsigned short status;

	__asm__ __volatile__ ("fnstsw %0" : "=m" (status));
	return status;
}

static void Bench486RenderPolyBuildCase (unsigned which, int plane_type,
		int *clipflags)
{
	static const float triangle[3][3] = {
		{-1.0f, -1.0f, 5.0f}, {1.0f, -1.0f, 5.0f}, {0.0f, 1.0f, 5.0f}
	};
	static const float crossing_quad[4][3] = {
		{-2.0f, -1.0f, 5.0f}, {2.0f, -1.0f, 5.0f},
		{2.0f, 1.0f, 5.0f}, {-2.0f, 1.0f, 5.0f}
	};
	static const float two_plane_quad[4][3] = {
		{-2.0f, -2.0f, 6.0f}, {2.0f, -2.0f, 6.0f},
		{2.0f, 2.0f, 6.0f}, {-2.0f, 2.0f, 6.0f}
	};
	static const float outside_quad[4][3] = {
		{-3.0f, -1.0f, 4.0f}, {-2.0f, -1.0f, 4.0f},
		{-2.0f, 1.0f, 4.0f}, {-3.0f, 1.0f, 4.0f}
	};
	static const float boundary_quad[4][3] = {
		{0.0f, -1.0f, 5.0f}, {2.0f, -1.0f, 5.0f},
		{2.0f, 1.0f, 5.0f}, {0.0f, 1.0f, 5.0f}
	};
	static const float near_triangle[3][3] = {
		{-4.0f, -4.0f, 0.005f}, {4.0f, -4.0f, 0.005f},
		{0.0f, 4.0f, 0.02f}
	};
	const float (*positions)[3];
	unsigned negative_edges;
	int count, i;
	bench486_renderpoly_fixture_t *fixture;

	fixture = &bench486_renderpoly_fixture;
	Q_memset (fixture, 0, sizeof(*fixture));
	negative_edges = 0;
	*clipflags = 0;
	positions = triangle;
	count = 3;

	switch (which)
	{
	case 1:
		positions = crossing_quad;
		count = 4;
		negative_edges = 0x05;
		*clipflags = 0x01;
		break;
	case 2:
		positions = two_plane_quad;
		count = 4;
		negative_edges = 0x0a;
		*clipflags = 0x03;
		break;
	case 3:
		positions = outside_quad;
		count = 4;
		*clipflags = 0x01;
		break;
	case 4:
		/* At x == 0, clipping crosses only when the previous/current strict
		   positive-side tests differ; points on the plane are retained by the
		   separate >= 0 test in the reference algorithm. */
		positions = boundary_quad;
		count = 4;
		*clipflags = 0x01;
		break;
	case 5:
		positions = near_triangle;
		count = 3;
		break;
	case 6:
		positions = crossing_quad;
		count = 4;
		*clipflags = 0x04;
		break;
	case 7:
		positions = crossing_quad;
		count = 4;
		*clipflags = 0x08;
		break;
	case 8:
		positions = two_plane_quad;
		count = 4;
		negative_edges = 0x05;
		*clipflags = 0x0f;
		break;
	default:
		negative_edges = 0x02;
		break;
	}

	for (i = 0; i < count; i++)
	{
		fixture->vertices[i].position[0] = positions[i][0];
		fixture->vertices[i].position[1] = positions[i][1];
		fixture->vertices[i].position[2] = positions[i][2];
		if (negative_edges & (1U << i))
		{
			fixture->surfedges[i] = -(i + 1);
			fixture->edges[i + 1].v[0] = (unsigned short)((i + 1) % count);
			fixture->edges[i + 1].v[1] = (unsigned short)i;
		}
		else
		{
			fixture->surfedges[i] = i + 1;
			fixture->edges[i + 1].v[0] = (unsigned short)i;
			fixture->edges[i + 1].v[1] = (unsigned short)((i + 1) % count);
		}
	}
	fixture->model.numedges = count + 1;
	fixture->model.edges = fixture->edges;
	fixture->model.numsurfedges = count;
	fixture->model.surfedges = fixture->surfedges;
	fixture->entity.model = &fixture->model;
	fixture->surface.plane = &fixture->faceplane;
	fixture->surface.numedges = count;
	fixture->surface.firstedge = 0;
	fixture->faceplane.type = (byte)plane_type;
}

static void Bench486RenderPolySeedGlobals (unsigned which)
{
	int i;

	currententity = &bench486_renderpoly_fixture.entity;
	r_pcurrentvertbase = bench486_renderpoly_fixture.vertices;
	r_nearzi = -123.0f;
	r_polydesc.numverts = -1234;
	r_polydesc.nearzi = -321.0f;
	r_polydesc.pcurrentface = &bench486_renderpoly_face_sentinel;
	r_polydesc.pverts = &bench486_renderpoly_vertex_sentinel;
	Q_memset (view_clipplanes, 0, sizeof(view_clipplanes));
	for (i = 0; i < 4; i++)
	{
		view_clipplanes[i].normal[0] = 1.0f;
		view_clipplanes[i].next = &bench486_renderpoly_clip_sentinel;
	}
	if (which == 1 || which == 3 || which == 4)
	{
		view_clipplanes[0].normal[0] = 1.0f;
		view_clipplanes[0].dist = 0.0f;
	}
	else if (which == 2)
	{
		view_clipplanes[0].normal[0] = 1.0f;
		view_clipplanes[0].dist = -1.0f;
		view_clipplanes[1].normal[0] = 0.0f;
		view_clipplanes[1].normal[1] = 1.0f;
		view_clipplanes[1].dist = -0.5f;
	}
	else if (which == 6)
	{
		view_clipplanes[2].normal[0] = 1.0f;
		view_clipplanes[2].dist = 0.0f;
	}
	else if (which == 7)
	{
		view_clipplanes[3].normal[0] = 0.0f;
		view_clipplanes[3].normal[1] = 1.0f;
		view_clipplanes[3].dist = 0.0f;
	}
	else if (which == 8)
	{
		/* The four half-spaces retain the safe square [-1,1] x [-1,1]. */
		view_clipplanes[0].normal[0] = 1.0f;
		view_clipplanes[0].dist = -1.0f;
		view_clipplanes[1].normal[0] = -1.0f;
		view_clipplanes[1].dist = -1.0f;
		view_clipplanes[2].normal[0] = 0.0f;
		view_clipplanes[2].normal[1] = 1.0f;
		view_clipplanes[2].dist = -1.0f;
		view_clipplanes[3].normal[0] = 0.0f;
		view_clipplanes[3].normal[1] = -1.0f;
		view_clipplanes[3].dist = -1.0f;
	}

	Q_memset (&r_refdef, 0, sizeof(r_refdef));
	r_refdef.fvrectx_adj = 0.0f;
	r_refdef.fvrecty_adj = 0.0f;
	r_refdef.fvrectright_adj = 319.0f;
	r_refdef.fvrectbottom_adj = 199.0f;
	modelorg[0] = modelorg[1] = modelorg[2] = 0.0f;
	vright[0] = 1.0f; vright[1] = 0.0f; vright[2] = 0.0f;
	vup[0] = 0.0f; vup[1] = 1.0f; vup[2] = 0.0f;
	vpn[0] = 0.0f; vpn[1] = 0.0f; vpn[2] = 1.0f;
	xcenter = 160.0f;
	ycenter = 100.0f;
	xscale = 160.0f;
	yscale = 160.0f;
}

static void Bench486RenderPolyRecordOutput (
		bench486_renderpoly_result_t *result)
{
	int i;

	result->numverts = r_polydesc.numverts;
	Q_memcpy (&result->nearzi, &r_polydesc.nearzi,
			sizeof(result->nearzi));
	result->face = r_polydesc.pcurrentface;
	Q_memcpy (&result->global_nearzi, &r_nearzi,
			sizeof(result->global_nearzi));
	result->current_vertices = r_pcurrentvertbase;
	result->current_edge = r_pedge;
	for (i = 0; i < 4; i++)
		result->clip_next[i] = view_clipplanes[i].next;
}

static void Bench486RenderPolyRun (unsigned which, int plane_type,
		unsigned short control, void (*function)(void),
		bench486_renderpoly_result_t *result)
{
	unsigned arguments[2];
	int clipflags;

	Bench486RenderPolyBuildCase (which, plane_type, &clipflags);
	Bench486RenderPolySeedGlobals (which);
	Q_memset (result, 0, sizeof(*result));
	bench486_renderpoly_active_result = result;
	bench486_renderpoly_draw_hook = Bench486RenderPolyCapture;
	arguments[0] = (unsigned)(size_t)&bench486_renderpoly_fixture.surface;
	arguments[1] = (unsigned)clipflags;
	__asm__ __volatile__ ("fninit\n\tfldcw %0" : : "m" (control) : "memory");
	result->abi = Bench486Call_asm486 (function, 2, arguments, NULL);
	result->x87_status = Bench486RenderPolyX87Status ();
	Bench486RenderPolyRecordOutput (result);
	bench486_renderpoly_active_result = NULL;
}

static unsigned Bench486RenderPolyFloatBits (const float *value)
{
	unsigned bits;

	Q_memcpy (&bits, (void *)value, sizeof(bits));
	return bits;
}

static unsigned Bench486RenderPolyPointerBits (const void *value)
{
	return (unsigned)(size_t)value;
}

/* Return the first actionable difference. Float and pointer values are
   reported as raw 32-bit payloads; pverts itself is intentionally excluded. */
static int Bench486RenderPolyFirstDifference (
		const bench486_renderpoly_result_t *c,
		const bench486_renderpoly_result_t *a,
		unsigned expected_calls, const char **field, int *index,
		unsigned *left, unsigned *right)
{
	int i;
	unsigned component;
	const float *ccomponents[5];
	const float *acomponents[5];
	static const char *vertex_fields[5] = {
		"C/ASM.vertex.u", "C/ASM.vertex.v",
		"C/ASM.vertex.zi", "C/ASM.vertex.s",
		"C/ASM.vertex.t"
	};

#define RPP_DIFFER(name, element, lhs, rhs) \
	do { \
		unsigned rpp_left, rpp_right; \
		rpp_left = (unsigned)(lhs); \
		rpp_right = (unsigned)(rhs); \
		if (rpp_left != rpp_right) \
		{ \
			*field = (name); \
			*index = (element); \
			*left = rpp_left; \
			*right = rpp_right; \
			return 1; \
		} \
	} while (0)

#define RPP_FLOAT_DIFFER(name, element, lhs, rhs) \
	RPP_DIFFER ((name), (element), \
		Bench486RenderPolyFloatBits (&(lhs)), \
		Bench486RenderPolyFloatBits (&(rhs)))

	RPP_DIFFER ("C/ASM.callback_count", -1, c->calls, a->calls);
	if (c->calls != expected_calls)
		RPP_DIFFER ("C.callback_count_expected", -1,
				c->calls, expected_calls);
	if (a->calls != expected_calls)
		RPP_DIFFER ("ASM.callback_count_expected", -1,
				a->calls, expected_calls);
	RPP_DIFFER ("C/ASM.capture_errors", -1, c->errors, a->errors);
	if (c->errors)
		RPP_DIFFER ("C.capture_errors_expected", -1, c->errors, 0);
	if (a->errors)
		RPP_DIFFER ("ASM.capture_errors_expected", -1, a->errors, 0);
	RPP_DIFFER ("C/ASM.result.numverts", -1, c->numverts, a->numverts);
	RPP_FLOAT_DIFFER ("C/ASM.result.nearzi", -1, c->nearzi, a->nearzi);
	RPP_DIFFER ("C/ASM.result.face", -1,
			Bench486RenderPolyPointerBits (c->face),
			Bench486RenderPolyPointerBits (a->face));
	RPP_FLOAT_DIFFER ("C/ASM.global.r_nearzi", -1,
			c->global_nearzi, a->global_nearzi);
	RPP_DIFFER ("C/ASM.global.r_pcurrentvertbase", -1,
			Bench486RenderPolyPointerBits (c->current_vertices),
			Bench486RenderPolyPointerBits (a->current_vertices));
	RPP_DIFFER ("C/ASM.global.r_pedge", -1,
			Bench486RenderPolyPointerBits (c->current_edge),
			Bench486RenderPolyPointerBits (a->current_edge));
	RPP_DIFFER ("C/ASM.abi_result", -1, c->abi, a->abi);
	/* C1 (bit 9) has instruction-dependent meaning. With IE and SF clear it
	   records rounding direction; with either flag set it can describe an x87
	   exception. Reject either exception flag, then compare every other FSW bit. */
	RPP_DIFFER ("C.x87_invalid_or_stack_fault_expected_clear", -1,
			c->x87_status & 0x0041U, 0);
	RPP_DIFFER ("ASM.x87_invalid_or_stack_fault_expected_clear", -1,
			a->x87_status & 0x0041U, 0);
	RPP_DIFFER ("C/ASM.x87_status_except_C1", -1,
			c->x87_status & ~0x0200U, a->x87_status & ~0x0200U);
	if (c->abi)
		RPP_DIFFER ("C.abi_expected", -1, c->abi, 0);
	if (a->abi)
		RPP_DIFFER ("ASM.abi_expected", -1, a->abi, 0);
	RPP_DIFFER ("C/ASM.callback.numverts", -1,
			c->callback_numverts, a->callback_numverts);
	RPP_FLOAT_DIFFER ("C/ASM.callback.nearzi", -1,
			c->callback_nearzi, a->callback_nearzi);
	RPP_DIFFER ("C/ASM.callback.face", -1,
			Bench486RenderPolyPointerBits (c->callback_face),
			Bench486RenderPolyPointerBits (a->callback_face));
	if (c->calls)
	{
		RPP_DIFFER ("C.callback.numverts_vs_result", -1,
				c->callback_numverts, c->numverts);
		RPP_DIFFER ("ASM.callback.numverts_vs_result", -1,
				a->callback_numverts, a->numverts);
		RPP_DIFFER ("C.callback.face_vs_result", -1,
				Bench486RenderPolyPointerBits (c->callback_face),
				Bench486RenderPolyPointerBits (c->face));
		RPP_DIFFER ("ASM.callback.face_vs_result", -1,
				Bench486RenderPolyPointerBits (a->callback_face),
				Bench486RenderPolyPointerBits (a->face));
		RPP_FLOAT_DIFFER ("C.callback.nearzi_vs_result", -1,
				c->callback_nearzi, c->nearzi);
		RPP_FLOAT_DIFFER ("ASM.callback.nearzi_vs_result", -1,
				a->callback_nearzi, a->nearzi);
		if (c->numverts >= 0 && c->numverts <= RPP_OUTPUT_VERTS &&
			a->numverts >= 0 && a->numverts <= RPP_OUTPUT_VERTS)
		{
			for (i = 0; i < c->numverts; i++)
			{
				ccomponents[0] = &c->vertices[i].u;
				ccomponents[1] = &c->vertices[i].v;
				ccomponents[2] = &c->vertices[i].zi;
				ccomponents[3] = &c->vertices[i].s;
				ccomponents[4] = &c->vertices[i].t;
				acomponents[0] = &a->vertices[i].u;
				acomponents[1] = &a->vertices[i].v;
				acomponents[2] = &a->vertices[i].zi;
				acomponents[3] = &a->vertices[i].s;
				acomponents[4] = &a->vertices[i].t;
				for (component = 0; component < 5; component++)
				{
					unsigned c_bits, a_bits;
					c_bits = Bench486RenderPolyFloatBits (
							ccomponents[component]);
					a_bits = Bench486RenderPolyFloatBits (
							acomponents[component]);
					if (c_bits != a_bits)
					{
						*field = vertex_fields[component];
						*index = i;
						*left = c_bits;
						*right = a_bits;
						return 1;
					}
				}
			}
		}
	}
	for (i = 0; i < 4; i++)
	{
		RPP_DIFFER ("C/ASM.clip_next", i,
				Bench486RenderPolyPointerBits (c->clip_next[i]),
				Bench486RenderPolyPointerBits (a->clip_next[i]));
	}
#undef RPP_FLOAT_DIFFER
#undef RPP_DIFFER
	return 0;
}

static void Bench486RenderPolyCases (void)
{
	static const int axis_types[6] = {
		PLANE_X, PLANE_Y, PLANE_Z, PLANE_ANYX, PLANE_ANYY, PLANE_ANYZ
	};
	static const unsigned short control_words[12] = {
		0x007f, 0x047f, 0x087f, 0x0c7f,
		0x027f, 0x067f, 0x0a7f, 0x0e7f,
		0x037f, 0x077f, 0x0b7f, 0x0f7f
	};
	unsigned cases, failures, mode, expected_calls, c1_differences;
	unsigned c1_first_geometry, c1_first_axis, c1_first_plane;
	unsigned short c1_first_c_status, c1_first_asm_status;
	unsigned short c1_first_control_word;
	int axis, which, plane_type, failed, difference_index;
	const char *difference_field;
	unsigned difference_left, difference_right;
	void (*saved_hook)(void);

	saved_hook = bench486_renderpoly_draw_hook;
	Bench486RenderPolySaveState ();
	cases = failures = c1_differences = 0;
	c1_first_geometry = c1_first_axis = c1_first_plane = 0;
	c1_first_c_status = c1_first_asm_status = 0;
	c1_first_control_word = 0;
	for (mode = 0; mode < 12; mode++)
	{
		for (which = 0; which <= 8; which++)
		{
			int axis_count;
			axis_count = (which == 0) ? 6 : 1;
			for (axis = 0; axis < axis_count; axis++)
			{
				plane_type = (which == 0) ? axis_types[axis] :
						(which == 1) ? PLANE_Y :
						(which == 2) ? PLANE_Z :
						(which == 3) ? PLANE_ANYZ :
						(which == 4) ? PLANE_ANYX : PLANE_ANYY;
				Bench486RenderPolyRun ((unsigned)which, plane_type,
						control_words[mode],
						(void (*)(void))R_RenderPoly_C,
						&bench486_renderpoly_c_result);
				Bench486RenderPolyRun ((unsigned)which, plane_type,
						control_words[mode],
						(void (*)(void))R_RenderPoly,
						&bench486_renderpoly_asm_result);
				expected_calls = (which == 3) ? 0 : 1;
				difference_field = "none";
				difference_index = -1;
				difference_left = difference_right = 0;
				failed = Bench486RenderPolyFirstDifference (
						&bench486_renderpoly_c_result,
						&bench486_renderpoly_asm_result, expected_calls,
						&difference_field, &difference_index,
						&difference_left, &difference_right);
				if ((bench486_renderpoly_c_result.x87_status ^
						bench486_renderpoly_asm_result.x87_status) & 0x0200U)
				{
					if (!c1_differences)
					{
						c1_first_geometry = (unsigned)which;
						c1_first_axis = (unsigned)axis;
						c1_first_plane = (unsigned)plane_type;
						c1_first_control_word = control_words[mode];
						c1_first_c_status = bench486_renderpoly_c_result.x87_status;
						c1_first_asm_status = bench486_renderpoly_asm_result.x87_status;
					}
					c1_differences++;
				}
				if (failed)
				{
					failures++;
					if (failures <= 12)
					{
						Bench486Printf ("render-poly pair %u mode %u geometry %u axis %d FAIL first=%s[%d]\n",
								cases, mode, which, plane_type,
								difference_field, difference_index);
						Bench486Printf ("render-poly pair %u values left=%08x right=%08x calls %u/%u verts %d/%d ABI %x/%x x87 %x/%x\n",
								cases,
								difference_left, difference_right,
								bench486_renderpoly_c_result.calls,
								bench486_renderpoly_asm_result.calls,
								bench486_renderpoly_c_result.numverts,
								bench486_renderpoly_asm_result.numverts,
								bench486_renderpoly_c_result.abi,
								bench486_renderpoly_asm_result.abi,
								bench486_renderpoly_c_result.x87_status,
								bench486_renderpoly_asm_result.x87_status);
					}
				}
				cases++;
			}
		}
	}
	if (cases != RPP_EXPECTED_PAIRS)
	{
		failures++;
		if (failures <= 12)
			Bench486Printf ("render-poly coverage FAIL expected %u pairs, ran %u\n",
					RPP_EXPECTED_PAIRS, cases);
	}
	Bench486RenderPolyRestoreState ();
	bench486_renderpoly_draw_hook = saved_hook;
	bench486_memory_failures += failures;
	/* Bench486Printf formats into a 192-byte stack buffer. Keep each progress
	   record short so diagnostics cannot overwrite this fixture's stack frame. */
	Bench486Printf ("render-poly C/ASM descriptor/projection/callback/ABI parity %s (%u/%u pairs; 14 geometry/axis variants; 12 control words; %u failures)\n",
			failures ? "FAIL" : "PASS", cases, RPP_EXPECTED_PAIRS,
			failures);
	Bench486Printf ("render-poly x87 C1 differences=%u first geometry=%u axis=%u plane=%u CW=%04x C-FSW=%04x ASM-FSW=%04x\n",
			c1_differences, c1_first_geometry, c1_first_axis,
			c1_first_plane, (unsigned)c1_first_control_word,
			(unsigned)c1_first_c_status,
			(unsigned)c1_first_asm_status);
}

#endif /* BENCH486 && ASM486_PUBLIC_BINDINGS && ASM486_RENDER_POLY */
#endif /* BENCH486_RENDERPOLY_H */
