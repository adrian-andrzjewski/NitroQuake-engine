/* C-reference versus i486 VESA resource-lifecycle cases. */
#ifndef BENCH486_VESA_LIFECYCLE_H
#define BENCH486_VESA_LIFECYCLE_H

#include "video/asm_vesalifecycle.h"

#define BVLC_EVENT_CAPACITY 4U

typedef struct bench486_vesa_lifecycle_result_s
{
	qboolean mapped;
	qboolean palette_ok;
	byte *palette;
	byte *membase;
	vmode_t *current_mode;
	__dpmi_meminfo mapping;
	unsigned event_count;
	unsigned events[BVLC_EVENT_CAPACITY];
	void *event_pointers[BVLC_EVENT_CAPACITY];
} bench486_vesa_lifecycle_result_t;

static byte bench486_vesa_lifecycle_palette[64];
static byte bench486_vesa_lifecycle_video[64];
static vmode_t bench486_vesa_lifecycle_mode;
static unsigned bench486_vesa_lifecycle_event_count;
static unsigned bench486_vesa_lifecycle_events[BVLC_EVENT_CAPACITY];
static void *bench486_vesa_lifecycle_event_pointers[BVLC_EVENT_CAPACITY];

void Bench486VesaLifecycleFreeMapping (void *mapping)
{
	if (bench486_vesa_lifecycle_event_count >= BVLC_EVENT_CAPACITY)
		return;
	bench486_vesa_lifecycle_events[bench486_vesa_lifecycle_event_count] = 1U;
	bench486_vesa_lifecycle_event_pointers[
			bench486_vesa_lifecycle_event_count++] = mapping;
}

void Bench486VesaLifecycleFreeDosMemory (void *memory)
{
	if (bench486_vesa_lifecycle_event_count >= BVLC_EVENT_CAPACITY)
		return;
	bench486_vesa_lifecycle_events[bench486_vesa_lifecycle_event_count] = 2U;
	bench486_vesa_lifecycle_event_pointers[
			bench486_vesa_lifecycle_event_count++] = memory;
}

static void Bench486VesaLifecycleResetEvents (void)
{
	bench486_vesa_lifecycle_event_count = 0;
	Q_memset (bench486_vesa_lifecycle_events, 0,
			sizeof(bench486_vesa_lifecycle_events));
	Q_memset (bench486_vesa_lifecycle_event_pointers, 0,
			sizeof(bench486_vesa_lifecycle_event_pointers));
}

static void Bench486VesaLifecycleSetState (int mapped, int has_palette,
		int palette_ok, int has_membase, int has_mode, unsigned seed)
{
	int i;
	for (i = 0; i < sizeof(bench486_vesa_lifecycle_palette); i++)
		bench486_vesa_lifecycle_palette[i] = (byte)(i * 11U + seed);
	for (i = 0; i < sizeof(bench486_vesa_lifecycle_video); i++)
		bench486_vesa_lifecycle_video[i] = (byte)(i * 7U + seed * 3U);
	Q_memset (&VID_extra_mapping, (int)(0x31U + seed),
			sizeof(VID_extra_mapping));
	VID_extra_mapped = mapped;
	VID_extra_palette_ok = palette_ok;
	VID_extra_palette = has_palette ? bench486_vesa_lifecycle_palette + seed : NULL;
	VID_membase = has_membase ? bench486_vesa_lifecycle_video + seed : NULL;
	VGA_pcurmode = has_mode ? &bench486_vesa_lifecycle_mode : NULL;
	Bench486VesaLifecycleResetEvents ();
}

static void Bench486VesaLifecycleCapture (
		bench486_vesa_lifecycle_result_t *result)
{
	result->mapped = VID_extra_mapped;
	result->palette_ok = VID_extra_palette_ok;
	result->palette = VID_extra_palette;
	result->membase = VID_membase;
	result->current_mode = VGA_pcurmode;
	Q_memcpy (&result->mapping, &VID_extra_mapping,
			sizeof(result->mapping));
	result->event_count = bench486_vesa_lifecycle_event_count;
	Q_memcpy (result->events, bench486_vesa_lifecycle_events,
			sizeof(result->events));
	Q_memcpy (result->event_pointers,
			bench486_vesa_lifecycle_event_pointers,
			sizeof(result->event_pointers));
}

static int Bench486VesaLifecycleEqual (
		const bench486_vesa_lifecycle_result_t *left,
		const bench486_vesa_lifecycle_result_t *right)
{
	return left->mapped == right->mapped &&
			left->palette_ok == right->palette_ok &&
			left->palette == right->palette &&
			left->membase == right->membase &&
			left->current_mode == right->current_mode &&
			left->event_count == right->event_count &&
			!Q_memcmp ((void *)left->events, (void *)right->events,
				sizeof(left->events)) &&
			!Q_memcmp ((void *)left->event_pointers,
				(void *)right->event_pointers,
				sizeof(left->event_pointers)) &&
			!Q_memcmp ((void *)&left->mapping, (void *)&right->mapping,
				sizeof(left->mapping));
}

static unsigned Bench486VesaLifecycleRunOne (int shutdown,
		int mapped, int has_palette, int palette_ok, int has_membase,
		int has_mode, unsigned seed)
{
	static bench486_vesa_lifecycle_result_t reference, candidate;
	byte saved_mapping[sizeof(VID_extra_mapping)];
	byte case_mapping[sizeof(VID_extra_mapping)];
	byte *saved_palette = VID_extra_palette;
	byte *saved_membase = VID_membase;
	vmode_t *saved_mode = VGA_pcurmode;
	byte *expected_palette = has_palette ?
			bench486_vesa_lifecycle_palette + seed : NULL;
	qboolean saved_mapped = VID_extra_mapped;
	qboolean saved_palette_ok = VID_extra_palette_ok;
	void (*reference_function)(void) = shutdown ?
			VID_ShutdownExtra_C : VID_ExtraReleaseMode_C;
	void (*candidate_function)(void) = shutdown ?
			VID_ShutdownExtra : VID_ExtraReleaseMode;
	unsigned reference_abi, candidate_abi, failure = 0;

	Q_memcpy (saved_mapping, &VID_extra_mapping, sizeof(saved_mapping));
	Bench486VesaLifecycleSetState (mapped, has_palette, palette_ok,
			has_membase, has_mode, seed);
	Q_memcpy (case_mapping, &VID_extra_mapping, sizeof(case_mapping));
	reference_abi = Bench486Call_asm486 (reference_function, 0, NULL, NULL);
	Bench486VesaLifecycleCapture (&reference);
	Bench486VesaLifecycleSetState (mapped, has_palette, palette_ok,
			has_membase, has_mode, seed);
	candidate_abi = Bench486Call_asm486 (candidate_function, 0, NULL, NULL);
	Bench486VesaLifecycleCapture (&candidate);
	if (reference_abi || candidate_abi)
		failure |= 1U;
	if (!Bench486VesaLifecycleEqual (&reference, &candidate))
		failure |= 2U;
	if (candidate.mapped || candidate.membase || candidate.current_mode ||
			!candidate.palette_ok)
		failure |= 4U;
	if (candidate.event_count != ((mapped ? 1U : 0U) +
				(shutdown && has_palette ? 1U : 0U)))
		failure |= 8U;
	if (mapped && (candidate.events[0] != 1U ||
			candidate.event_pointers[0] != &VID_extra_mapping))
		failure |= 16U;
	if (shutdown && has_palette && (!candidate.event_count ||
			candidate.events[candidate.event_count - 1U] != 2U ||
			candidate.event_pointers[candidate.event_count - 1U] !=
				expected_palette))
		failure |= 32U;
	if (shutdown && candidate.palette)
		failure |= 64U;
	if (!shutdown && candidate.palette != expected_palette)
		failure |= 128U;
	if (Q_memcmp ((void *)&candidate.mapping, (void *)case_mapping,
			sizeof(case_mapping)))
		failure |= 256U;

	Q_memcpy (&VID_extra_mapping, saved_mapping, sizeof(saved_mapping));
	VID_extra_palette = saved_palette;
	VID_membase = saved_membase;
	VGA_pcurmode = saved_mode;
	VID_extra_mapped = saved_mapped;
	VID_extra_palette_ok = saved_palette_ok;
	Bench486VesaLifecycleResetEvents ();
	return failure;
}

static unsigned Bench486VesaLifecyclePaletteCase (int palette_ok)
{
	qboolean c_result, asm_result;
	unsigned c_abi, asm_abi;
	VID_extra_palette_ok = palette_ok;
	c_result = VID_ExtraPaletteOK_C ();
	asm_result = VID_ExtraPaletteOK ();
	c_abi = Bench486Call_asm486 (
			(void (*)(void))VID_ExtraPaletteOK_C, 0, NULL, NULL);
	asm_abi = Bench486Call_asm486 (
			(void (*)(void))VID_ExtraPaletteOK, 0, NULL, NULL);
	return c_result == palette_ok && asm_result == palette_ok &&
			c_result == asm_result && !c_abi && !asm_abi ? 0U : 1U;
}

int Bench486VesaLifecycleCases (void)
{
	byte saved_mapping[sizeof(VID_extra_mapping)];
	byte *saved_palette = VID_extra_palette;
	byte *saved_membase = VID_membase;
	vmode_t *saved_mode = VGA_pcurmode;
	qboolean saved_mapped = VID_extra_mapped;
	qboolean saved_palette_ok = VID_extra_palette_ok;
	unsigned cases = 0, failures = 0;
	int mapped, has_palette, palette_ok;

	Q_memcpy (saved_mapping, &VID_extra_mapping, sizeof(saved_mapping));
	failures += Bench486VesaLifecyclePaletteCase (false);
	cases++;
	failures += Bench486VesaLifecyclePaletteCase (true);
	cases++;
	for (mapped = 0; mapped < 2; mapped++)
	for (has_palette = 0; has_palette < 2; has_palette++)
	for (palette_ok = 0; palette_ok < 2; palette_ok++)
	{
		failures += Bench486VesaLifecycleRunOne (0, mapped, has_palette,
				palette_ok, (mapped + has_palette) & 1,
				(mapped + palette_ok) & 1, cases);
		cases++;
		failures += Bench486VesaLifecycleRunOne (1, mapped, has_palette,
				palette_ok, (has_palette + palette_ok) & 1,
				(mapped + has_palette + palette_ok) & 1, cases);
		cases++;
	}
	Q_memcpy (&VID_extra_mapping, saved_mapping, sizeof(saved_mapping));
	VID_extra_palette = saved_palette;
	VID_membase = saved_membase;
	VGA_pcurmode = saved_mode;
	VID_extra_mapped = saved_mapped;
	VID_extra_palette_ok = saved_palette_ok;
	Bench486VesaLifecycleResetEvents ();
	Bench486Printf ("VESA lifecycle: %u C/assembly release, shutdown, palette-state, and ABI cases %s (%u failures)\n",
			cases, failures ? "FAIL" : "PASS", failures);
	return failures;
}

#undef BVLC_EVENT_CAPACITY

#endif
