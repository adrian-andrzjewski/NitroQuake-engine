/* Multi-frame C-oracle parity for the 486 particle update loop. */
/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
#ifndef BENCH486_PARTICLEUPDATE_H
#define BENCH486_PARTICLEUPDATE_H

#if defined(BENCH486) && defined(ASM486_PARTICLE_UPDATE) && \
		defined(ASM486_PARTICLE_DRAW)

#include "tests/bench486/bench486_particledraw_layout.h"

#define BPU_POOL_COUNT 13
#define BPU_ACTIVE_COUNT 10
#define BPU_FRAME_COUNT 10
#define BPU_MODE_COUNT 4

extern particle_t *active_particles, *free_particles, *particles;
extern int r_numparticles;
extern cvar_t sv_gravity;
extern void R_DrawParticles_C (void);
extern void R_DrawParticles_asm486 (float time, double oldtime, float gravity
#ifdef PROFILE486
		, unsigned long *particle_count, unsigned long *gib_trail_count
#endif
		);

#ifdef PROFILE486
extern int bench486_profile_frame_active;
#endif

typedef struct
{
	unsigned long before[4];
	particle_t nodes[BPU_POOL_COUNT];
	unsigned long after[4];
} bench486_particleupdate_pool_t;

typedef struct
{
	particle_t *active;
	particle_t *free;
	float right[3];
	float up[3];
	float normal[3];
	unsigned short cw;
} bench486_particleupdate_state_t;

typedef struct
{
	bench486_particledraw_saved_t draw;
	vec3_t view_right;
	vec3_t view_up;
	vec3_t view_normal;
	float xscale;
	float yscale;
	double client_time;
	double client_oldtime;
	float gravity;
	particle_t *active;
	particle_t *free;
	particle_t *pool;
	int particle_count;
	unsigned short cw;
#ifdef PROFILE486
	int profile_active;
#endif
} bench486_particleupdate_saved_t;

static bench486_particleupdate_pool_t bench486_particleupdate_pool;
static bench486_particleupdate_pool_t
		bench486_particleupdate_reference_pool[BPU_MODE_COUNT][BPU_FRAME_COUNT];
static bench486_particleupdate_state_t
		bench486_particleupdate_reference_state[BPU_MODE_COUNT][BPU_FRAME_COUNT];
static byte bench486_particleupdate_reference_color
		[BPU_MODE_COUNT][BPU_FRAME_COUNT][BPD_COLOR_TOTAL];
static short bench486_particleupdate_reference_depth
		[BPU_MODE_COUNT][BPU_FRAME_COUNT][BPD_DEPTH_TOTAL];

static void Bench486ParticleUpdateSaveDrawState (
		bench486_particledraw_saved_t *saved)
{
	int i;

	Q_memcpy (saved->origin, r_origin, sizeof(saved->origin));
	Q_memcpy (saved->right, r_pright, sizeof(saved->right));
	Q_memcpy (saved->up, r_pup, sizeof(saved->up));
	Q_memcpy (saved->normal, r_ppn, sizeof(saved->normal));
	saved->xcenter = xcenter;
	saved->ycenter = ycenter;
	saved->viewbuffer = d_viewbuffer;
	saved->pzbuffer = d_pzbuffer;
	saved->zrowbytes = d_zrowbytes;
	saved->zwidth = d_zwidth;
	saved->screenwidth = screenwidth;
	saved->pix_shift = d_pix_shift;
	saved->pix_min = d_pix_min;
	saved->pix_max = d_pix_max;
	saved->aspect_shift = d_y_aspect_shift;
	saved->left = d_vrectx;
	saved->top = d_vrecty;
	saved->right_edge = d_vrectright_particle;
	saved->bottom_edge = d_vrectbottom_particle;
	for (i=0 ; i<BPD_ROWS ; i++)
	{
		saved->scantable[i] = d_scantable[i];
		saved->viewrows[i] = viewspantable[i];
		saved->zrows[i] = zspantable[i];
	}
	saved->dp_u = bench486_particledraw_dp_u;
	saved->dp_v = bench486_particledraw_dp_v;
	saved->dp_pix = bench486_particledraw_dp_pix;
	saved->izi = bench486_particledraw_izi;
	saved->dp_cw = bench486_particledraw_dp_cw;
}

static void Bench486ParticleUpdateRestoreDrawState (
		bench486_particledraw_saved_t *saved)
{
	int i;

	Q_memcpy (r_origin, saved->origin, sizeof(saved->origin));
	Q_memcpy (r_pright, saved->right, sizeof(saved->right));
	Q_memcpy (r_pup, saved->up, sizeof(saved->up));
	Q_memcpy (r_ppn, saved->normal, sizeof(saved->normal));
	xcenter = saved->xcenter;
	ycenter = saved->ycenter;
	d_viewbuffer = saved->viewbuffer;
	d_pzbuffer = saved->pzbuffer;
	d_zrowbytes = saved->zrowbytes;
	d_zwidth = saved->zwidth;
	screenwidth = saved->screenwidth;
	d_pix_shift = saved->pix_shift;
	d_pix_min = saved->pix_min;
	d_pix_max = saved->pix_max;
	d_y_aspect_shift = saved->aspect_shift;
	d_vrectx = saved->left;
	d_vrecty = saved->top;
	d_vrectright_particle = saved->right_edge;
	d_vrectbottom_particle = saved->bottom_edge;
	for (i=0 ; i<BPD_ROWS ; i++)
	{
		d_scantable[i] = saved->scantable[i];
		viewspantable[i] = saved->viewrows[i];
		zspantable[i] = saved->zrows[i];
	}
	bench486_particledraw_dp_u = saved->dp_u;
	bench486_particledraw_dp_v = saved->dp_v;
	bench486_particledraw_dp_pix = saved->dp_pix;
	bench486_particledraw_izi = saved->izi;
	bench486_particledraw_dp_cw = saved->dp_cw;
}

static void Bench486ParticleUpdateSaveState (
		bench486_particleupdate_saved_t *saved)
{
	Bench486ParticleUpdateSaveDrawState (&saved->draw);
	Q_memcpy (saved->view_right, vright, sizeof(saved->view_right));
	Q_memcpy (saved->view_up, vup, sizeof(saved->view_up));
	Q_memcpy (saved->view_normal, vpn, sizeof(saved->view_normal));
	saved->xscale = xscaleshrink;
	saved->yscale = yscaleshrink;
	saved->client_time = cl.time;
	saved->client_oldtime = cl.oldtime;
	saved->gravity = sv_gravity.value;
	saved->active = active_particles;
	saved->free = free_particles;
	saved->pool = particles;
	saved->particle_count = r_numparticles;
	__asm__ __volatile__ ("fnstcw %0" : "=m" (saved->cw));
#ifdef PROFILE486
	saved->profile_active = bench486_profile_frame_active;
	bench486_profile_frame_active = false;
#endif
}

static void Bench486ParticleUpdateRestoreState (
		bench486_particleupdate_saved_t *saved)
{
	Bench486ParticleUpdateRestoreDrawState (&saved->draw);
	Q_memcpy (vright, saved->view_right, sizeof(saved->view_right));
	Q_memcpy (vup, saved->view_up, sizeof(saved->view_up));
	Q_memcpy (vpn, saved->view_normal, sizeof(saved->view_normal));
	xscaleshrink = saved->xscale;
	yscaleshrink = saved->yscale;
	cl.time = saved->client_time;
	cl.oldtime = saved->client_oldtime;
	sv_gravity.value = saved->gravity;
	active_particles = saved->active;
	free_particles = saved->free;
	particles = saved->pool;
	r_numparticles = saved->particle_count;
#ifdef PROFILE486
	bench486_profile_frame_active = saved->profile_active;
#endif
	__asm__ __volatile__ ("fldcw %0" : : "m" (saved->cw));
}

static void Bench486ParticleUpdateConfigureParticle (int index, int type,
		float x, float y, float z, float vx, float vy, float vz,
		float ramp, float die, byte color)
{
	particle_t *p;

	p = &bench486_particleupdate_pool.nodes[index];
	p->org[0] = x;
	p->org[1] = y;
	p->org[2] = z;
	p->color = color;
	p->type = type;
	p->vel[0] = vx;
	p->vel[1] = vy;
	p->vel[2] = vz;
	p->ramp = ramp;
	p->die = die;
}

static void Bench486ParticleUpdatePrepare (void)
{
	int i;
	float ox, oy, oz;

	Q_memset (&bench486_particleupdate_pool, 0xa5,
			sizeof(bench486_particleupdate_pool));
	Q_memset (bench486_particleupdate_pool.nodes, 0,
			sizeof(bench486_particleupdate_pool.nodes));
	for (i=0 ; i<4 ; i++)
	{
		bench486_particleupdate_pool.before[i] = 0x48620000UL + i;
		bench486_particleupdate_pool.after[i] = 0xa5c20000UL + i;
	}
	for (i=0 ; i<BPU_ACTIVE_COUNT-1 ; i++)
		bench486_particleupdate_pool.nodes[i].next =
				&bench486_particleupdate_pool.nodes[i+1];
	bench486_particleupdate_pool.nodes[BPU_ACTIVE_COUNT-1].next = NULL;
	for (i=BPU_ACTIVE_COUNT ; i<BPU_POOL_COUNT-1 ; i++)
		bench486_particleupdate_pool.nodes[i].next =
				&bench486_particleupdate_pool.nodes[i+1];
	bench486_particleupdate_pool.nodes[BPU_POOL_COUNT-1].next = NULL;
	active_particles = &bench486_particleupdate_pool.nodes[0];
	free_particles = &bench486_particleupdate_pool.nodes[BPU_ACTIVE_COUNT];
	particles = bench486_particleupdate_pool.nodes;
	r_numparticles = BPU_POOL_COUNT;

	ox = 10.0f;
	oy = -20.0f;
	oz = 5.0f;
	Bench486ParticleUpdateConfigureParticle (0, pt_slowgrav,
		ox, oy, oz+32.0f, 5.25f, -3.5f, 11.75f, 0.0f, 1.0f, 0x4a);
	Bench486ParticleUpdateConfigureParticle (1, pt_slowgrav,
		ox+4.0f, oy+2.0f, oz+40.0f, -2.5f, 1.75f, -4.125f,
		0.0f, 0.3132f, 0x59);
	Bench486ParticleUpdateConfigureParticle (2, pt_slowgrav,
		ox-5.0f, oy+3.0f, oz+48.0f, 1.125f, -0.875f, 7.75f,
		0.0f, 0.1f, 0x68);
	Bench486ParticleUpdateConfigureParticle (3, pt_grav,
		ox+2.0f, oy-4.0f, oz+56.0f, 0.5f, 0.25f, 13.0f,
		0.0f, 1.2f, 0x77);
	Bench486ParticleUpdateConfigureParticle (4, pt_fire,
		ox, oy+4.0f, oz+64.0f, 2.0f, 0.0f, 3.0f,
		1.25f, 1.2f, 0x86);
	Bench486ParticleUpdateConfigureParticle (5, pt_explode,
		ox-3.0f, oy-2.0f, oz+40.0f, 6.0f, -1.0f, 9.0f,
		0.5f, 1.2f, 0x95);
	Bench486ParticleUpdateConfigureParticle (6, pt_explode2,
		ox+2.0f, oy+2.0f, oz+48.0f, -4.0f, 2.0f, 5.0f,
		0.75f, 1.2f, 0xa4);
	Bench486ParticleUpdateConfigureParticle (7, pt_blob,
		ox+4.0f, oy-1.0f, oz+52.0f, 1.125f, -2.5f, 3.5f,
		0.0f, 1.2f, 0xb3);
	Bench486ParticleUpdateConfigureParticle (8, pt_blob2,
		ox-2.0f, oy+3.0f, oz+44.0f, -1.75f, 2.25f, 6.5f,
		0.0f, 1.2f, 0xc2);
	Bench486ParticleUpdateConfigureParticle (9, pt_static,
		ox, oy, oz+36.0f, 0.0f, 0.0f, 0.0f,
		0.0f, 0.4698f, 0xd1);

	r_origin[0] = 10.0f;
	r_origin[1] = -20.0f;
	r_origin[2] = 5.0f;
	vright[0] = 0.6f; vright[1] = 0.8f; vright[2] = 0.0f;
	vup[0] = -0.8f; vup[1] = 0.6f; vup[2] = 0.0f;
	vpn[0] = 0.0f; vpn[1] = 0.0f; vpn[2] = 1.0f;
	xscaleshrink = 8.0f;
	yscaleshrink = 8.0f;
	xcenter = 19.5f;
	ycenter = 15.5f;
	d_vrectx = 8;
	d_vrecty = 8;
	d_vrectright_particle = 31;
	d_vrectbottom_particle = 31;
	d_zwidth = BPD_DEPTH_STRIDE;
	d_zrowbytes = BPD_DEPTH_STRIDE * sizeof(short);
	screenwidth = BPD_COLOR_STRIDE;
	d_pix_shift = 7;
	d_pix_min = 1;
	d_pix_max = 5;
	d_y_aspect_shift = 0;
	cl.time = 0.0;
	cl.oldtime = 0.0;
	sv_gravity.value = 800.0f;
}

static void Bench486ParticleUpdateSetFrame (int frame)
{
	static const double times[BPU_FRAME_COUNT] = {
		0.0783, 0.1566, 0.2349, 0.3132, 0.3915,
		0.4698, 0.5481, 0.6264, 0.7047, 0.7830
	};

	cl.oldtime = frame ? times[frame-1] : 0.0;
	cl.time = times[frame];
}

static void Bench486ParticleUpdateSaveReference (int mode, int frame,
		unsigned short cw)
{
	bench486_particleupdate_state_t *state;

	Q_memcpy (&bench486_particleupdate_reference_pool[mode][frame],
			&bench486_particleupdate_pool,
			sizeof(bench486_particleupdate_pool));
	Q_memcpy (bench486_particleupdate_reference_color[mode][frame],
			bench486_particledraw_c_color,
			sizeof(bench486_particledraw_c_color));
	Q_memcpy (bench486_particleupdate_reference_depth[mode][frame],
			bench486_particledraw_c_depth,
			sizeof(bench486_particledraw_c_depth));
	state = &bench486_particleupdate_reference_state[mode][frame];
	Q_memset (state, 0, sizeof(*state));
	state->active = active_particles;
	state->free = free_particles;
	Q_memcpy (state->right, r_pright, sizeof(state->right));
	Q_memcpy (state->up, r_pup, sizeof(state->up));
	Q_memcpy (state->normal, r_ppn, sizeof(state->normal));
	state->cw = cw;
}

static unsigned Bench486ParticleUpdateCompareAssembly (int mode, int frame,
		unsigned short cw)
{
	bench486_particleupdate_state_t state;
	int pool_diff, color_diff, depth_diff, state_diff, failures;
	int pool_node, pool_member_offset;
	unsigned c_bits, a_bits;

	Q_memset (&state, 0, sizeof(state));
	state.active = active_particles;
	state.free = free_particles;
	Q_memcpy (state.right, r_pright, sizeof(state.right));
	Q_memcpy (state.up, r_pup, sizeof(state.up));
	Q_memcpy (state.normal, r_ppn, sizeof(state.normal));
	state.cw = cw;
	pool_diff = Bench486ParticleDrawFirstDifference (
			&bench486_particleupdate_reference_pool[mode][frame],
			&bench486_particleupdate_pool,
			sizeof(bench486_particleupdate_pool));
	color_diff = Bench486ParticleDrawFirstDifference (
			bench486_particleupdate_reference_color[mode][frame],
			bench486_particledraw_a_color,
			sizeof(bench486_particledraw_a_color));
	depth_diff = Bench486ParticleDrawFirstDifference (
			bench486_particleupdate_reference_depth[mode][frame],
			bench486_particledraw_a_depth,
			sizeof(bench486_particledraw_a_depth));
	state_diff = Bench486ParticleDrawFirstDifference (
			&bench486_particleupdate_reference_state[mode][frame],
			&state, sizeof(state));
	failures = 0;
	if (pool_diff >= 0)
	{
		Bench486Printf ("particle-update state mismatch RC%d frame %d byte %d\n",
				mode, frame, pool_diff);
		if (pool_diff >= (int)sizeof(bench486_particleupdate_pool.before) &&
				pool_diff < (int)(sizeof(bench486_particleupdate_pool.before) +
				sizeof(bench486_particleupdate_pool.nodes)))
		{
			pool_node = (pool_diff -
					(int)sizeof(bench486_particleupdate_pool.before)) /
					(int)sizeof(particle_t);
			pool_member_offset = (pool_diff -
					(int)sizeof(bench486_particleupdate_pool.before)) %
					(int)sizeof(particle_t);
			Q_memcpy (&c_bits,
					(byte *)&bench486_particleupdate_reference_pool[mode][frame] +
					pool_diff, sizeof(c_bits));
			Q_memcpy (&a_bits,
					(byte *)&bench486_particleupdate_pool + pool_diff,
					sizeof(a_bits));
			Bench486Printf ("particle-update pool detail node %d member-byte %d C=%08x ASM=%08x\n",
					pool_node, pool_member_offset, c_bits, a_bits);
		}
		failures++;
	}
	if (state_diff >= 0)
	{
		Bench486Printf ("particle-update list/projection/CW mismatch RC%d frame %d byte %d\n",
				mode, frame, state_diff);
		failures++;
	}
	if (color_diff >= 0)
	{
		Bench486Printf ("particle-update framebuffer mismatch RC%d frame %d byte %d\n",
				mode, frame, color_diff);
		failures++;
	}
	if (depth_diff >= 0)
	{
		Bench486Printf ("particle-update depthbuffer mismatch RC%d frame %d byte %d\n",
				mode, frame, depth_diff);
		failures++;
	}
	if (cw != bench486_particleupdate_reference_state[mode][frame].cw)
	{
		Bench486Printf ("particle-update CW mismatch RC%d frame %d expected %04x actual %04x\n",
				mode, frame,
			bench486_particleupdate_reference_state[mode][frame].cw, cw);
		failures++;
	}
	if (!Bench486ParticleDrawColorGuard (bench486_particledraw_a_color) ||
			!Bench486ParticleDrawDepthGuard (bench486_particledraw_a_depth))
	{
		Bench486Printf ("particle-update framebuffer canary FAIL RC%d frame %d\n",
				mode, frame);
		failures++;
	}
	return (unsigned)failures;
}

static void Bench486ParticleUpdateAsmFrame (void)
{
#ifdef PROFILE486
	unsigned long particle_count, gib_trail_count;

	particle_count = 0;
	gib_trail_count = 0;
#endif
	D_StartParticles ();
#ifdef PROFILE486
	R_DrawParticles_asm486 ((float)cl.time, cl.oldtime, sv_gravity.value,
			&particle_count, &gib_trail_count);
#else
	R_DrawParticles_asm486 ((float)cl.time, cl.oldtime, sv_gravity.value);
#endif
	D_EndParticles ();
}

static void Bench486ParticleUpdateCases (void)
{
	bench486_particleupdate_saved_t saved;
	unsigned short saved_cw, test_cw, frame_cw;
	unsigned c_abi, a_abi;
	unsigned long frames_run, failures;
	int mode, frame;

	Bench486ParticleUpdateSaveState (&saved);
	saved_cw = saved.cw;
	frames_run = 0;
	failures = 0;
	Bench486Printf ("particle-update C/ASM begin (%d frames; slowgrav; non-axis view; four x87 rounding modes)\n",
			BPU_FRAME_COUNT);
	for (mode=0 ; mode<BPU_MODE_COUNT ; mode++)
	{
		test_cw = (unsigned short)((saved_cw & (unsigned short)~0x0c3f) |
				0x003f | (mode << 10));
		Bench486ParticleUpdatePrepare ();
		for (frame=0 ; frame<BPU_FRAME_COUNT ; frame++)
		{
			Bench486ParticleUpdateSetFrame (frame);
			Bench486ParticleDrawPrepareBuffers (
					(unsigned)(mode * 37 + frame + 0x4860));
			Bench486ParticleDrawInstallBuffers (0);
			__asm__ __volatile__ ("fnclex\n\tfldcw %0" : : "m" (test_cw));
			c_abi = Bench486Call_asm486 (
					(void (*)(void))R_DrawParticles_C, 0, NULL, NULL);
			__asm__ __volatile__ ("fnstcw %0" : "=m" (frame_cw));
			if (c_abi || frame_cw != test_cw ||
					!Bench486ParticleDrawColorGuard (
							bench486_particledraw_c_color) ||
					!Bench486ParticleDrawDepthGuard (
							bench486_particledraw_c_depth))
			{
				Bench486Printf ("particle-update C ABI/CW/guard FAIL RC%d frame %d ABI %x CW %04x\n",
						mode, frame, c_abi, frame_cw);
				failures++;
			}
			Bench486ParticleUpdateSaveReference (mode, frame, frame_cw);
			frames_run++;
		}

		Bench486ParticleUpdatePrepare ();
		for (frame=0 ; frame<BPU_FRAME_COUNT ; frame++)
		{
			Bench486ParticleUpdateSetFrame (frame);
			Bench486ParticleDrawPrepareBuffers (
					(unsigned)(mode * 37 + frame + 0x4860));
			Bench486ParticleDrawInstallBuffers (1);
			__asm__ __volatile__ ("fnclex\n\tfldcw %0" : : "m" (test_cw));
			a_abi = Bench486Call_asm486 (
					(void (*)(void))Bench486ParticleUpdateAsmFrame,
					0, NULL, NULL);
			__asm__ __volatile__ ("fnstcw %0" : "=m" (frame_cw));
			if (a_abi)
			{
				Bench486Printf ("particle-update ASM ABI FAIL RC%d frame %d mask %x\n",
						mode, frame, a_abi);
				failures++;
			}
			failures += Bench486ParticleUpdateCompareAssembly (
					mode, frame, frame_cw);
		}
	}
	Bench486ParticleUpdateRestoreState (&saved);
	bench486_memory_failures += failures;
	Bench486Printf ("particle-update C/ASM %s (%lu frames across four x87 modes; %lu failures)\n",
			failures ? "FAIL" : "PASS", frames_run, failures);
}

#endif /* BENCH486 && ASM486_PARTICLE_UPDATE && ASM486_PARTICLE_DRAW */
#endif /* BENCH486_PARTICLEUPDATE_H */
