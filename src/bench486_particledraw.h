/* Direct C-oracle versus i486 framebuffer/depth/ABI checks for D_DrawParticle. */
#ifndef BENCH486_PARTICLEDRAW_H
#define BENCH486_PARTICLEDRAW_H

#ifdef ASM486_PARTICLE_DRAW

#include "bench486_particledraw_layout.h"

extern unsigned Bench486Call_asm486 (void (*function)(void), unsigned words,
		const unsigned *arguments, float *float_result);
extern void D_DrawParticle_C (particle_t *particle);
extern void D_DrawParticle_asm486 (particle_t *particle);

/* These assembler scratch symbols are deliberately saved around the fixture. */
extern int bench486_particledraw_dp_u __asm__ ("DP_u");
extern int bench486_particledraw_dp_v __asm__ ("DP_v");
extern int bench486_particledraw_dp_pix __asm__ ("DP_Pix");
extern int bench486_particledraw_izi __asm__ ("izi");
extern unsigned int bench486_particledraw_dp_cw __asm__ ("DP_CW");

typedef char bench486_particledraw_requires_i386[
		(sizeof(void *) == 4 && sizeof(int) == 4 && sizeof(unsigned) == 4) ?
		1 : -1];

typedef struct
{
	vec3_t origin;
	vec3_t right;
	vec3_t up;
	vec3_t normal;
	float xcenter, ycenter;
	pixel_t *viewbuffer;
	short *pzbuffer;
	unsigned int zrowbytes, zwidth;
	int screenwidth;
	int pix_shift, pix_min, pix_max, aspect_shift;
	int left, top, right_edge, bottom_edge;
	int scantable[BPD_ROWS];
	pixel_t *viewrows[BPD_ROWS];
	short *zrows[BPD_ROWS];
	int dp_u, dp_v, dp_pix, izi;
	unsigned int dp_cw;
} bench486_particledraw_saved_t;

typedef struct
{
	const char *name;
	float x, y, z;
	byte color;
	int pix_shift, pix_min, pix_max, aspect_shift;
	int occlusion;
} bench486_particledraw_case_t;

static byte bench486_particledraw_c_color[BPD_COLOR_TOTAL];
static byte bench486_particledraw_a_color[BPD_COLOR_TOTAL];
static byte bench486_particledraw_reference_color[BPD_COLOR_TOTAL];
static short bench486_particledraw_c_depth[BPD_DEPTH_TOTAL];
static short bench486_particledraw_a_depth[BPD_DEPTH_TOTAL];
static short bench486_particledraw_reference_depth[BPD_DEPTH_TOTAL];

static unsigned Bench486ParticleDrawCall (void (*function)(void),
		particle_t *particle)
{
	unsigned arguments[1];

	arguments[0] = (unsigned)particle;
	return Bench486Call_asm486 (function, 1, arguments, NULL);
}

static void Bench486ParticleDrawInstallBuffers (int assembly)
{
	byte *color;
	short *depth;
	int row;

	if (assembly)
	{
		color = &bench486_particledraw_a_color[BPD_COLOR_GUARD];
		depth = &bench486_particledraw_a_depth[BPD_DEPTH_GUARD];
	}
	else
	{
		color = &bench486_particledraw_c_color[BPD_COLOR_GUARD];
		depth = &bench486_particledraw_c_depth[BPD_DEPTH_GUARD];
	}
	d_viewbuffer = (pixel_t *)color;
	d_pzbuffer = depth;
	for (row=0 ; row<BPD_ROWS ; row++)
	{
		d_scantable[row] = row * BPD_COLOR_STRIDE;
		viewspantable[row] = (pixel_t *)(color + d_scantable[row]);
		zspantable[row] = depth + row * BPD_DEPTH_STRIDE;
	}
}

static void Bench486ParticleDrawPrepareBuffers (unsigned seed)
{
	int i;

	Q_memset (bench486_particledraw_c_color, 0xa5,
			sizeof(bench486_particledraw_c_color));
	Q_memset (bench486_particledraw_a_color, 0xa5,
			sizeof(bench486_particledraw_a_color));
	Q_memset (bench486_particledraw_c_depth, 0x5a,
			sizeof(bench486_particledraw_c_depth));
	Q_memset (bench486_particledraw_a_depth, 0x5a,
			sizeof(bench486_particledraw_a_depth));
	for (i=0 ; i<BPD_COLOR_BYTES ; i++)
	{
		byte value;
		value = (byte)((i * 29 + (int)seed * 17 + 11) & 255);
		bench486_particledraw_c_color[BPD_COLOR_GUARD+i] = value;
		bench486_particledraw_a_color[BPD_COLOR_GUARD+i] = value;
	}
	Q_memset (&bench486_particledraw_c_depth[BPD_DEPTH_GUARD], 0,
			BPD_DEPTH_WORDS * sizeof(short));
	Q_memset (&bench486_particledraw_a_depth[BPD_DEPTH_GUARD], 0,
			BPD_DEPTH_WORDS * sizeof(short));
}

static int Bench486ParticleDrawColorGuard (const byte *buffer)
{
	int i;

	for (i=0 ; i<BPD_COLOR_GUARD ; i++)
		if (buffer[i] != 0xa5 ||
				buffer[BPD_COLOR_GUARD+BPD_COLOR_BYTES+i] != 0xa5)
			return 0;
	return 1;
}

static int Bench486ParticleDrawDepthGuard (const short *buffer)
{
	int i;

	for (i=0 ; i<BPD_DEPTH_GUARD ; i++)
		if ((unsigned short)buffer[i] != 0x5a5a ||
				(unsigned short)buffer[BPD_DEPTH_GUARD+BPD_DEPTH_WORDS+i] !=
				0x5a5a)
			return 0;
	return 1;
}

static int Bench486ParticleDrawFirstDifference (const void *left,
		const void *right, int bytes)
{
	const byte *a, *b;
	int i;

	a = (const byte *)left;
	b = (const byte *)right;
	for (i=0 ; i<bytes ; i++)
		if (a[i] != b[i]) return i;
	return -1;
}

static void Bench486ParticleDrawSetCase (
		const bench486_particledraw_case_t *test)
{
	/* Identity view basis keeps the world-to-screen test inputs auditable. */
	r_origin[0] = r_origin[1] = r_origin[2] = 0;
	r_pright[0] = 1; r_pright[1] = 0; r_pright[2] = 0;
	r_pup[0] = 0; r_pup[1] = 1; r_pup[2] = 0;
	r_ppn[0] = 0; r_ppn[1] = 0; r_ppn[2] = 1;
	xcenter = 19.5f;
	ycenter = 15.5f;
	d_vrectx = 8;
	d_vrecty = 8;
	d_vrectright_particle = 31;
	d_vrectbottom_particle = 31;
	d_zwidth = BPD_DEPTH_STRIDE;
	d_zrowbytes = BPD_DEPTH_STRIDE * sizeof(short);
	screenwidth = BPD_COLOR_STRIDE;
	d_pix_shift = test->pix_shift;
	d_pix_min = test->pix_min;
	d_pix_max = test->pix_max;
	d_y_aspect_shift = test->aspect_shift;
}

static void Bench486ParticleDrawReportABI (const char *side, unsigned abi,
		const char *name, int mode)
{
	if (abi)
		Bench486Printf ("particle-draw %s ABI FAIL %s RC%d mask %x\n",
				side, (char *)name, mode, abi);
}

static int Bench486ParticleDrawCompareCase (
		const bench486_particledraw_case_t *test, int mode,
		unsigned short test_cw)
{
	particle_t particle;
	unsigned c_abi, a_abi;
	unsigned short c_cw, a_cw, c_sw, a_sw;
	byte *c_color, *a_color;
	short *c_depth, *a_depth;
	int u, v, i, color_diff, depth_diff, failures;

	Q_memset (&particle, 0, sizeof(particle));
	particle.org[0] = test->x;
	particle.org[1] = test->y;
	particle.org[2] = test->z;
	particle.color = test->color;
	Bench486ParticleDrawSetCase (test);
	Bench486ParticleDrawPrepareBuffers ((unsigned)(mode * 37 + test->color));
	c_color = &bench486_particledraw_c_color[BPD_COLOR_GUARD];
	a_color = &bench486_particledraw_a_color[BPD_COLOR_GUARD];
	c_depth = &bench486_particledraw_c_depth[BPD_DEPTH_GUARD];
	a_depth = &bench486_particledraw_a_depth[BPD_DEPTH_GUARD];

	/* The equality/near/far pattern is exact for the z=16 test case. */
	if (test->occlusion)
	{
		for (i=0 ; i<BPD_DEPTH_WORDS ; i++)
		{
			c_depth[i] = a_depth[i] = 2049;
		}
		u = 20;
		v = 16;
		c_depth[v*BPD_DEPTH_STRIDE+u] = a_depth[v*BPD_DEPTH_STRIDE+u] = 2047;
		c_depth[v*BPD_DEPTH_STRIDE+u+1] = a_depth[v*BPD_DEPTH_STRIDE+u+1] = 2048;
		c_depth[(v+1)*BPD_DEPTH_STRIDE+u] =
			a_depth[(v+1)*BPD_DEPTH_STRIDE+u] = 2049;
		c_depth[(v+1)*BPD_DEPTH_STRIDE+u+1] =
			a_depth[(v+1)*BPD_DEPTH_STRIDE+u+1] = 0;
	}

	Bench486ParticleDrawInstallBuffers (0);
	__asm__ __volatile__ ("fnclex\n\tfldcw %0" : : "m" (test_cw));
	c_abi = Bench486ParticleDrawCall ((void (*)(void))D_DrawParticle_C,
			&particle);
	__asm__ __volatile__ ("fnstcw %0\n\tfnstsw %1" : "=m" (c_cw), "=m" (c_sw));

	Bench486ParticleDrawInstallBuffers (1);
	__asm__ __volatile__ ("fnclex\n\tfldcw %0" : : "m" (test_cw));
	a_abi = Bench486ParticleDrawCall ((void (*)(void))D_DrawParticle_asm486,
			&particle);
	__asm__ __volatile__ ("fnstcw %0\n\tfnstsw %1" : "=m" (a_cw), "=m" (a_sw));

	color_diff = Bench486ParticleDrawFirstDifference (
			bench486_particledraw_c_color,
			bench486_particledraw_a_color,
			sizeof(bench486_particledraw_c_color));
	depth_diff = Bench486ParticleDrawFirstDifference (
			bench486_particledraw_c_depth,
			bench486_particledraw_a_depth,
			sizeof(bench486_particledraw_c_depth));
	failures = 0;
	if (c_abi || a_abi)
	{
		Bench486ParticleDrawReportABI ("C", c_abi, test->name, mode);
		Bench486ParticleDrawReportABI ("ASM", a_abi, test->name, mode);
		failures++;
	}
	if (c_cw != test_cw || a_cw != test_cw || c_cw != a_cw)
	{
		Bench486Printf ("particle-draw CW FAIL %s RC%d expected %04x C %04x ASM %04x\n",
				(char *)test->name, mode, test_cw, c_cw, a_cw);
		failures++;
	}
	if (color_diff >= 0)
	{
		Bench486Printf ("particle-draw color mismatch %s RC%d byte %d C %u ASM %u\n",
				(char *)test->name, mode, color_diff,
				bench486_particledraw_c_color[color_diff],
				bench486_particledraw_a_color[color_diff]);
		failures++;
	}
	if (depth_diff >= 0)
	{
		Bench486Printf ("particle-draw depth mismatch %s RC%d byte %d C %02x ASM %02x\n",
				(char *)test->name, mode, depth_diff,
			((byte *)bench486_particledraw_c_depth)[depth_diff],
			((byte *)bench486_particledraw_a_depth)[depth_diff]);
		failures++;
	}
	if (!Bench486ParticleDrawColorGuard (bench486_particledraw_c_color) ||
			!Bench486ParticleDrawColorGuard (bench486_particledraw_a_color))
	{
		Bench486Printf ("particle-draw color canary FAIL %s RC%d\n",
				(char *)test->name, mode);
		failures++;
	}
	if (!Bench486ParticleDrawDepthGuard (bench486_particledraw_c_depth) ||
			!Bench486ParticleDrawDepthGuard (bench486_particledraw_a_depth))
	{
		Bench486Printf ("particle-draw depth canary FAIL %s RC%d\n",
				(char *)test->name, mode);
		failures++;
	}
	if ((c_sw & 0x003f) != (a_sw & 0x003f))
	{
		Bench486Printf ("particle-draw x87 flags differ %s RC%d C %04x ASM %04x (diagnostic)\n",
				(char *)test->name, mode, c_sw, a_sw);
	}
	if (test->z == 0.0f && ((c_sw | a_sw) & 0x0004))
	{
		Bench486Printf ("particle-draw clipped zero raised x87 divide-by-zero %s RC%d C %04x ASM %04x\n",
				(char *)test->name, mode, c_sw, a_sw);
		failures++;
	}
	return failures;
}

static unsigned Bench486ParticleDrawSequence (void (*function)(void),
		int assembly, unsigned short test_cw)
{
	particle_t particle;
	unsigned seed, abi, all_abi;
	int i, x, y, z;

	Bench486ParticleDrawInstallBuffers (assembly);
	all_abi = 0;
	seed = 0x486d2a71U;
	for (i=0 ; i<192 ; i++)
	{
		seed = seed * 1664525U + 1013904223U;
		x = ((int)((seed >> 8) % 13) - 6) * 8;
		seed = seed * 1664525U + 1013904223U;
		y = ((int)((seed >> 9) % 13) - 6) * 8;
		seed = seed * 1664525U + 1013904223U;
		z = 8 << ((seed >> 16) & 3);
		particle.org[0] = (float)x;
		particle.org[1] = (float)y;
		particle.org[2] = (float)z;
		particle.color = (byte)(seed >> 24);
		__asm__ __volatile__ ("fnclex\n\tfldcw %0" : : "m" (test_cw));
		abi = Bench486ParticleDrawCall (function, &particle);
		all_abi |= abi;
	}
	return all_abi;
}

static void Bench486ParticleDrawCases (void)
{
	static const bench486_particledraw_case_t cases[] = {
		{ "clip-below", 0, 0, 7.9999995f, 0, 7, 1, 5, 0, 0 },
		{ "clip-equal", 0, 0, 8, 255, 7, 1, 5, 0, 0 },
		{ "clip-above", 0, 0, 8.00000095f, 255, 7, 1, 5, 0, 0 },
		{ "clip-zero", 0, 0, 0, 0, 7, 1, 5, 0, 0 },
		{ "edge-left", -192, 0, 16, 0, 7, 1, 1, 0, 0 },
		{ "edge-left-out", -208, 0, 16, 255, 7, 1, 1, 0, 0 },
		{ "edge-right", 176, 0, 16, 255, 7, 1, 1, 0, 0 },
		{ "edge-right-out", 192, 0, 16, 0, 7, 1, 1, 0, 0 },
		{ "edge-top", 0, 128, 16, 0, 7, 1, 1, 0, 0 },
		{ "edge-top-out", 0, 144, 16, 255, 7, 1, 1, 0, 0 },
		{ "edge-bottom", 0, -240, 16, 255, 7, 1, 1, 0, 0 },
		{ "edge-bottom-out", 0, -256, 16, 0, 7, 1, 1, 0, 0 },
		{ "project-fraction", 12, -12, 16, 255, 7, 1, 2, 0, 0 },
		{ "occlusion-equal", 0, 0, 16, 0, 10, 2, 2, 0, 1 },
		{ "minimum-clamp", 0, 0, 32768, 255, 7, 2, 5, 0, 0 },
		{ "maximum-clamp", 0, 0, 8, 0, 7, 1, 4, 0, 0 },
		{ "size-1", 0, 0, 170.6666718f, 0, 7, 1, 5, 0, 0 },
		{ "size-2-aspect0", 0, 0, 102.4f, 255, 7, 1, 5, 0, 0 },
		{ "size-3", 0, 0, 73.1428604f, 0, 7, 1, 5, 0, 0 },
		{ "size-4-aspect0", 0, 0, 56.8888893f, 255, 7, 1, 5, 0, 0 },
		{ "size-5", 0, 0, 46.5454559f, 0, 7, 1, 5, 0, 0 },
		{ "size-1-aspect1", 0, 0, 170.6666718f, 255, 7, 1, 5, 1, 0 },
		{ "size-2-aspect1", 0, 0, 102.4f, 0, 7, 1, 5, 1, 0 },
		{ "size-3-aspect1", 0, 0, 73.1428604f, 255, 7, 1, 5, 1, 0 },
		{ "size-4-aspect1", 0, 0, 56.8888893f, 0, 7, 1, 5, 1, 0 },
		{ "size-5-aspect1", 0, 0, 46.5454559f, 255, 7, 1, 5, 1, 0 }
	};
	bench486_particledraw_saved_t saved;
	unsigned short saved_cw, test_cw, c_cw, a_cw;
	unsigned c_abi, a_abi;
	unsigned long cases_run, failures;
	int i, mode, color_diff, depth_diff, sequence_failure;

	Q_memcpy (saved.origin, r_origin, sizeof(saved.origin));
	Q_memcpy (saved.right, r_pright, sizeof(saved.right));
	Q_memcpy (saved.up, r_pup, sizeof(saved.up));
	Q_memcpy (saved.normal, r_ppn, sizeof(saved.normal));
	saved.xcenter = xcenter; saved.ycenter = ycenter;
	saved.viewbuffer = d_viewbuffer; saved.pzbuffer = d_pzbuffer;
	saved.zrowbytes = d_zrowbytes; saved.zwidth = d_zwidth;
	saved.screenwidth = screenwidth;
	saved.pix_shift = d_pix_shift; saved.pix_min = d_pix_min;
	saved.pix_max = d_pix_max; saved.aspect_shift = d_y_aspect_shift;
	saved.left = d_vrectx; saved.top = d_vrecty;
	saved.right_edge = d_vrectright_particle;
	saved.bottom_edge = d_vrectbottom_particle;
	for (i=0 ; i<BPD_ROWS ; i++)
	{
		saved.scantable[i] = d_scantable[i];
		saved.viewrows[i] = viewspantable[i];
		saved.zrows[i] = zspantable[i];
	}
	saved.dp_u = bench486_particledraw_dp_u;
	saved.dp_v = bench486_particledraw_dp_v;
	saved.dp_pix = bench486_particledraw_dp_pix;
	saved.izi = bench486_particledraw_izi;
	saved.dp_cw = bench486_particledraw_dp_cw;
	__asm__ __volatile__ ("fnstcw %0" : "=m" (saved_cw));

	Bench486Printf ("particle-draw C/ASM begin (%d direct cases; four x87 rounding modes; repeated sequence)\n",
			(int)(sizeof(cases)/sizeof(cases[0])));
	cases_run = failures = 0;
	for (mode=0 ; mode<4 ; mode++)
	{
		test_cw = (unsigned short)((saved_cw & (unsigned short)~0x0c3f) |
				0x003f | (mode << 10));
		__asm__ __volatile__ ("fldcw %0" : : "m" (test_cw));
		Bench486Printf ("particle-draw mode %d/4\n", mode+1);
		for (i=0 ; i<sizeof(cases)/sizeof(cases[0]) ; i++)
		{
			Bench486ParticleDrawSetCase (&cases[i]);
			failures += Bench486ParticleDrawCompareCase (&cases[i], mode,
					test_cw);
			cases_run++;
		}

		/* Repeat the same bounded stream from fresh state on both paths. */
		Bench486ParticleDrawSetCase (&cases[0]);
		Bench486ParticleDrawPrepareBuffers (0x4860U + mode);
		c_abi = Bench486ParticleDrawSequence ((void (*)(void))D_DrawParticle_C,
				0, test_cw);
		if (c_abi)
		{
			Bench486ParticleDrawReportABI ("C", c_abi, "sequence-first", mode);
			failures++;
		}
		Q_memcpy (bench486_particledraw_reference_color,
				bench486_particledraw_c_color,
				sizeof(bench486_particledraw_reference_color));
		Q_memcpy (bench486_particledraw_reference_depth,
				bench486_particledraw_c_depth,
				sizeof(bench486_particledraw_reference_depth));
		Bench486ParticleDrawPrepareBuffers (0x4860U + mode);
		c_abi = Bench486ParticleDrawSequence ((void (*)(void))D_DrawParticle_C,
				0, test_cw);
		color_diff = Bench486ParticleDrawFirstDifference (
				bench486_particledraw_reference_color,
				bench486_particledraw_c_color,
				sizeof(bench486_particledraw_reference_color));
		depth_diff = Bench486ParticleDrawFirstDifference (
				bench486_particledraw_reference_depth,
				bench486_particledraw_c_depth,
				sizeof(bench486_particledraw_reference_depth));
		if (c_abi || color_diff >= 0 || depth_diff >= 0)
		{
			Bench486ParticleDrawReportABI ("C", c_abi, "sequence-repeat", mode);
			Bench486Printf ("particle-draw C repeated-sequence instability RC%d ABI %x color %d depth %d\n",
					mode, c_abi, color_diff, depth_diff);
			failures++;
		}
		Bench486ParticleDrawPrepareBuffers (0x4860U + mode);
		Bench486ParticleDrawInstallBuffers (1);
		a_abi = Bench486ParticleDrawSequence (
				(void (*)(void))D_DrawParticle_asm486, 1, test_cw);
		color_diff = Bench486ParticleDrawFirstDifference (
				bench486_particledraw_reference_color,
				bench486_particledraw_a_color,
				sizeof(bench486_particledraw_reference_color));
		depth_diff = Bench486ParticleDrawFirstDifference (
				bench486_particledraw_reference_depth,
				bench486_particledraw_a_depth,
				sizeof(bench486_particledraw_reference_depth));
		if (a_abi || color_diff >= 0 || depth_diff >= 0 ||
				!Bench486ParticleDrawColorGuard (bench486_particledraw_c_color) ||
				!Bench486ParticleDrawDepthGuard (bench486_particledraw_c_depth) ||
				!Bench486ParticleDrawColorGuard (bench486_particledraw_a_color) ||
				!Bench486ParticleDrawDepthGuard (bench486_particledraw_a_depth))
		{
			Bench486ParticleDrawReportABI ("ASM", a_abi, "sequence-first", mode);
			Bench486Printf ("particle-draw repeated sequence C/ASM FAIL RC%d ABI %x color %d depth %d\n",
					mode, a_abi, color_diff, depth_diff);
			failures++;
		}
		Bench486ParticleDrawPrepareBuffers (0x4860U + mode);
		a_abi = Bench486ParticleDrawSequence (
				(void (*)(void))D_DrawParticle_asm486, 1, test_cw);
		color_diff = Bench486ParticleDrawFirstDifference (
				bench486_particledraw_reference_color,
				bench486_particledraw_a_color,
				sizeof(bench486_particledraw_reference_color));
		depth_diff = Bench486ParticleDrawFirstDifference (
				bench486_particledraw_reference_depth,
				bench486_particledraw_a_depth,
				sizeof(bench486_particledraw_reference_depth));
		if (a_abi || color_diff >= 0 || depth_diff >= 0)
		{
			Bench486ParticleDrawReportABI ("ASM", a_abi, "sequence-repeat", mode);
			Bench486Printf ("particle-draw ASM repeated-sequence instability RC%d ABI %x color %d depth %d\n",
					mode, a_abi, color_diff, depth_diff);
			failures++;
		}
		sequence_failure = 0;
		__asm__ __volatile__ ("fnstcw %0" : "=m" (c_cw));
		if (c_cw != test_cw)
		{
			Bench486Printf ("particle-draw sequence CW FAIL RC%d expected %04x actual %04x\n",
					mode, test_cw, c_cw);
			sequence_failure = 1;
		}
		failures += sequence_failure;
	}

	/* Restore every renderer global and scratch word modified by this fixture. */
	Q_memcpy (r_origin, saved.origin, sizeof(saved.origin));
	Q_memcpy (r_pright, saved.right, sizeof(saved.right));
	Q_memcpy (r_pup, saved.up, sizeof(saved.up));
	Q_memcpy (r_ppn, saved.normal, sizeof(saved.normal));
	xcenter = saved.xcenter; ycenter = saved.ycenter;
	d_viewbuffer = saved.viewbuffer; d_pzbuffer = saved.pzbuffer;
	d_zrowbytes = saved.zrowbytes; d_zwidth = saved.zwidth;
	screenwidth = saved.screenwidth;
	d_pix_shift = saved.pix_shift; d_pix_min = saved.pix_min;
	d_pix_max = saved.pix_max; d_y_aspect_shift = saved.aspect_shift;
	d_vrectx = saved.left; d_vrecty = saved.top;
	d_vrectright_particle = saved.right_edge;
	d_vrectbottom_particle = saved.bottom_edge;
	for (i=0 ; i<BPD_ROWS ; i++)
	{
		d_scantable[i] = saved.scantable[i];
		viewspantable[i] = saved.viewrows[i];
		zspantable[i] = saved.zrows[i];
	}
	bench486_particledraw_dp_u = saved.dp_u;
	bench486_particledraw_dp_v = saved.dp_v;
	bench486_particledraw_dp_pix = saved.dp_pix;
	bench486_particledraw_izi = saved.izi;
	bench486_particledraw_dp_cw = saved.dp_cw;
	__asm__ __volatile__ ("fldcw %0" : : "m" (saved_cw));
	bench486_memory_failures += failures;
	Bench486Printf ("particle-draw C/ASM %s (%lu direct cases; repeated streams in four rounding modes; %lu failures)\n",
			failures ? "FAIL" : "PASS", cases_run, failures);
}

#endif /* ASM486_PARTICLE_DRAW */
#endif /* BENCH486_PARTICLEDRAW_H */
