/* Direct C/assembly parity fixture for R_ZDrawSubmodelPolys. */
#ifndef BENCH486_ZSUBMODEL_H
#define BENCH486_ZSUBMODEL_H

#include "renderer/asm_zsubmodel.h"

#define ZSP_CAPACITY 16
#define ZSP_GUARD_WORDS 8

void (*bench486_zsubmodel_render_hook)(msurface_t *surface, int clipflags);

typedef struct
{
	unsigned first[ZSP_GUARD_WORDS];
	model_t value;
	unsigned last[ZSP_GUARD_WORDS];
} zsp_guarded_model_t;

typedef struct
{
	unsigned first[ZSP_GUARD_WORDS];
	msurface_t value[ZSP_CAPACITY];
	unsigned last[ZSP_GUARD_WORDS];
} zsp_guarded_surfaces_t;

typedef struct
{
	unsigned first[ZSP_GUARD_WORDS];
	mplane_t value[ZSP_CAPACITY];
	unsigned last[ZSP_GUARD_WORDS];
} zsp_guarded_planes_t;

typedef struct
{
	zsp_guarded_model_t model;
	zsp_guarded_surfaces_t surfaces;
	zsp_guarded_planes_t planes;
} zsp_fixture_t;

typedef struct
{
	unsigned count;
	unsigned errors;
	unsigned surface[ZSP_CAPACITY];
	unsigned clipflags[ZSP_CAPACITY];
} zsp_trace_t;

static zsp_fixture_t zsp_fixture;
static zsp_fixture_t zsp_initial;
static zsp_fixture_t zsp_c_result;
static zsp_fixture_t zsp_a_result;
static zsp_trace_t zsp_trace;
static zsp_trace_t zsp_c_trace;
static float zsp_input_modelorg[3];
static unsigned zsp_failure_count;

extern unsigned Bench486Call_asm486 (void (*function)(void), unsigned words,
		const unsigned *arguments, float *float_return);
extern float modelorg[3];

static void Bench486ZSubmodelRecord (msurface_t *surface, int clipflags)
{
	unsigned base, address, offset;

	if (zsp_trace.count >= ZSP_CAPACITY)
	{
		zsp_trace.errors++;
		return;
	}
	base = (unsigned)(size_t)&zsp_fixture.surfaces.value[0];
	address = (unsigned)(size_t)surface;
	if (address < base || address >= base + sizeof(zsp_fixture.surfaces.value))
	{
		zsp_trace.errors++;
		return;
	}
	offset = address - base;
	if (offset % sizeof(msurface_t))
	{
		zsp_trace.errors++;
		return;
	}
	zsp_trace.surface[zsp_trace.count] = offset / sizeof(msurface_t);
	zsp_trace.clipflags[zsp_trace.count] = (unsigned)clipflags;
	if (clipflags != 15)
		zsp_trace.errors++;
	zsp_trace.count++;
}

static void Bench486ZSubmodelSetGuard (unsigned *first, unsigned *last)
{
	unsigned i;
	for (i = 0; i < ZSP_GUARD_WORDS; i++)
	{
		first[i] = 0x5a5a5a5aU;
		last[i] = 0xa5a5a5a5U;
	}
}

static int Bench486ZSubmodelGuards (void)
{
	unsigned i;
	for (i = 0; i < ZSP_GUARD_WORDS; i++)
	{
		if (zsp_fixture.model.first[i] != 0x5a5a5a5aU ||
				zsp_fixture.model.last[i] != 0xa5a5a5a5U ||
				zsp_fixture.surfaces.first[i] != 0x5a5a5a5aU ||
				zsp_fixture.surfaces.last[i] != 0xa5a5a5a5U ||
				zsp_fixture.planes.first[i] != 0x5a5a5a5aU ||
				zsp_fixture.planes.last[i] != 0xa5a5a5a5U)
			return 0;
	}
	return 1;
}

static void Bench486ZSubmodelInputs (unsigned pattern, int first, int count,
		int boundary_case)
{
	static const float values[] = {
		-1.0e20f, -8192.0f, -32.0f, -1.0f, -0.03125f,
		-0.010002f, -0.01f, -0.009998f, 0.0f, 0.009998f,
		0.01f, 0.010002f, 0.03125f, 1.0f, 8192.0f, 1.0e20f
	};
	static const float boundary_dot[8] = {
		-0.010002f, -0.01f, -0.009998f, 0.009998f,
		0.01f, 0.010002f, -1.0f, 1.0f
	};
	static const unsigned boundary_flags[8] = {
		SURF_PLANEBACK | SURF_DRAWBACKGROUND, SURF_PLANEBACK,
		SURF_PLANEBACK, 0, 0, 0, SURF_PLANEBACK, 0
	};
	unsigned i, j, value_count;

	Q_memset (&zsp_fixture, 0x5a, sizeof(zsp_fixture));
	Q_memset (&zsp_fixture.model.value, 0, sizeof(zsp_fixture.model.value));
	Q_memset (zsp_fixture.surfaces.value, 0,
			sizeof(zsp_fixture.surfaces.value));
	Q_memset (zsp_fixture.planes.value, 0, sizeof(zsp_fixture.planes.value));
	Bench486ZSubmodelSetGuard (zsp_fixture.model.first,
			zsp_fixture.model.last);
	Bench486ZSubmodelSetGuard (zsp_fixture.surfaces.first,
			zsp_fixture.surfaces.last);
	Bench486ZSubmodelSetGuard (zsp_fixture.planes.first,
			zsp_fixture.planes.last);
	zsp_fixture.model.value.surfaces = zsp_fixture.surfaces.value;
	zsp_fixture.model.value.firstmodelsurface = first;
	zsp_fixture.model.value.nummodelsurfaces = count;
	value_count = sizeof(values) / sizeof(values[0]);

	if (boundary_case)
	{
		modelorg[0] = 1.0f;
		modelorg[1] = 0.0f;
		modelorg[2] = 0.0f;
		for (i = 0; i < ZSP_CAPACITY; i++)
		{
			zsp_fixture.surfaces.value[i].plane =
					&zsp_fixture.planes.value[i];
				zsp_fixture.planes.value[i].normal[0] = 1.0f;
		}
		for (i = 0; i < 8; i++)
		{
			unsigned index = (unsigned)first + i;
			zsp_fixture.surfaces.value[index].flags = boundary_flags[i];
			zsp_fixture.planes.value[index].normal[0] = boundary_dot[i];
		}
	}
	else
	{
		for (i = 0; i < 3; i++)
			modelorg[i] = values[(pattern * (i + 3) + i * 5) % value_count];
		for (i = 0; i < ZSP_CAPACITY; i++)
		{
			mplane_t *plane = &zsp_fixture.planes.value[i];
			msurface_t *surface = &zsp_fixture.surfaces.value[i];
			surface->plane = plane;
			surface->flags = ((pattern + i * 7) & 1) ? SURF_PLANEBACK : 0;
			if ((pattern + i) & 4)
				surface->flags |= SURF_DRAWBACKGROUND;
			for (j = 0; j < 3; j++)
				plane->normal[j] = values[(pattern * 5 + i * 3 + j * 7) % value_count];
			plane->dist = values[(pattern * 11 + i * 13 + 3) % value_count];
		}
	}
	Q_memcpy (zsp_input_modelorg, modelorg, sizeof(zsp_input_modelorg));
}

static unsigned short Bench486ZSubmodelStatus (void)
{
	unsigned short status;
	__asm__ __volatile__ ("fnstsw %0" : "=m" (status));
	return status;
}

static int Bench486ZSubmodelStep (unsigned pattern, int first, int count,
		int boundary_case, const unsigned *expected, unsigned expected_count)
{
	unsigned arguments[1], c_abi, a_abi;
	unsigned short c_status, a_status;
	void (*saved_hook)(msurface_t *, int);
	int failed;

	Bench486ZSubmodelInputs (pattern, first, count, boundary_case);
	Q_memcpy (&zsp_initial, &zsp_fixture, sizeof(zsp_fixture));
	saved_hook = bench486_zsubmodel_render_hook;
	bench486_zsubmodel_render_hook = Bench486ZSubmodelRecord;
	arguments[0] = (unsigned)(size_t)&zsp_fixture.model.value;

	Q_memset (&zsp_trace, 0, sizeof(zsp_trace));
	__asm__ __volatile__ ("fnclex");
	c_abi = Bench486Call_asm486 ((void (*)(void))R_ZDrawSubmodelPolys_C,
			1, arguments, NULL);
	c_status = Bench486ZSubmodelStatus ();
	Q_memcpy (&zsp_c_result, &zsp_fixture, sizeof(zsp_fixture));
	Q_memcpy (&zsp_c_trace, &zsp_trace, sizeof(zsp_trace));

	Q_memcpy (&zsp_fixture, &zsp_initial, sizeof(zsp_fixture));
	Q_memcpy (modelorg, zsp_input_modelorg, sizeof(zsp_input_modelorg));
	Q_memset (&zsp_trace, 0, sizeof(zsp_trace));
	__asm__ __volatile__ ("fnclex");
	a_abi = Bench486Call_asm486 ((void (*)(void))R_ZDrawSubmodelPolys_asm486_test,
			1, arguments, NULL);
	a_status = Bench486ZSubmodelStatus ();
	Q_memcpy (&zsp_a_result, &zsp_fixture, sizeof(zsp_fixture));

	failed = c_abi || a_abi || !Bench486ZSubmodelGuards () ||
			Q_memcmp (&zsp_initial, &zsp_c_result, sizeof(zsp_fixture)) ||
			Q_memcmp (&zsp_initial, &zsp_a_result, sizeof(zsp_fixture)) ||
			Q_memcmp (&zsp_c_result, &zsp_a_result, sizeof(zsp_fixture)) ||
			Q_memcmp (&zsp_c_trace, &zsp_trace, sizeof(zsp_trace)) ||
			c_status != a_status || zsp_c_trace.errors || zsp_trace.errors;
	if (expected && (zsp_c_trace.count != expected_count ||
			Q_memcmp (zsp_c_trace.surface, (void *)expected,
					expected_count * sizeof(expected[0]))))
		failed = 1;
	if (expected && zsp_c_trace.count != expected_count)
		failed = 1;
	if (failed)
	{
		zsp_failure_count++;
		if (zsp_failure_count < 20)
			Bench486Printf ("z-submodel case %u FAIL ABI %x/%x status %x/%x calls %u/%u errors %u/%u\n",
					pattern, c_abi, a_abi, c_status, a_status,
					zsp_c_trace.count, zsp_trace.count,
					zsp_c_trace.errors, zsp_trace.errors);
	}
	bench486_zsubmodel_render_hook = saved_hook;
	return failed;
}

static void Bench486ZSubmodelCases (void)
{
	static const unsigned short modes[12] = {
		0x007f, 0x047f, 0x087f, 0x0c7f, 0x027f, 0x067f,
		0x0a7f, 0x0e7f, 0x037f, 0x077f, 0x0b7f, 0x0f7f
	};
	static const unsigned boundary_expected[4] = {3, 8, 9, 10};
	float saved_modelorg[3];
	unsigned short saved_cw, control;
	unsigned mode, pattern, step, cases;
	unsigned old_failures;
	void (*saved_hook)(msurface_t *, int);

	Q_memcpy (saved_modelorg, modelorg, sizeof(saved_modelorg));
	saved_hook = bench486_zsubmodel_render_hook;
	__asm__ __volatile__ ("fnstcw %0" : "=m" (saved_cw));
	old_failures = bench486_memory_failures;
	zsp_failure_count = 0;
	cases = 0;
	Bench486ZSubmodelStep (0, 3, 8, 1, boundary_expected, 4);
	cases++;
	Bench486ZSubmodelStep (1, ZSP_CAPACITY, 0, 0, NULL, 0);
	cases++;
	Bench486ZSubmodelStep (2, ZSP_CAPACITY, -1, 0, NULL, 0);
	cases++;

	for (mode = 0; mode < 12; mode++)
	{
		Bench486Printf ("z-submodel x87 mode %u/12 begin\n", mode + 1);
		control = (saved_cw & ~0x0f00U) | (modes[mode] & 0x0f00U);
		__asm__ __volatile__ ("fldcw %0" : : "m" (control));
		for (pattern = 0; pattern < 32; pattern++)
		{
			int first = (int)(pattern % 9);
			int available = ZSP_CAPACITY - first;
			int count = (int)((pattern * 7 + mode * 3) % (available + 1));
			Bench486ZSubmodelStep (pattern + mode * 32, first, count,
					0, NULL, 0);
			cases++;
		}
	}

	Bench486Printf ("z-submodel continuous sequence begin\n");
	for (step = 0; step < 4096; step++)
	{
		int first = (int)((step * 13) % 9);
		int available = ZSP_CAPACITY - first;
		int count = (int)((step * 17 + 3) % (available + 1));
		if ((step & 511U) == 0)
			Bench486Printf ("z-submodel sequence progress %u/4096\n", step);
		Bench486ZSubmodelStep (step * 0x9e3779b9U, first, count, 0,
				NULL, 0);
		cases++;
	}
	__asm__ __volatile__ ("fldcw %0" : : "m" (saved_cw));
	Q_memcpy (modelorg, saved_modelorg, sizeof(saved_modelorg));
	bench486_zsubmodel_render_hook = saved_hook;
	bench486_memory_failures += zsp_failure_count;
	Bench486Printf ("z-submodel exact C/ASM face decisions, x87 flags, guards and ABI %s (%u cases; 12 control words; 4096 continuous calls; %u failures)\n",
			bench486_memory_failures == old_failures ? "PASS" : "FAIL",
			cases, zsp_failure_count);
}

#endif /* BENCH486_ZSUBMODEL_H */
