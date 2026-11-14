/* C reference versus i486 VESA wait-gate and retrace-port cases. */
#ifndef BENCH486_VESA_WAIT_H
#define BENCH486_VESA_WAIT_H

#include "video/asm_vesawait.h"

#define BVW_MAX_POLLS 3U

static unsigned bench486_vesa_wait_read_count;
static unsigned bench486_vesa_wait_read_failures;
/* Keep startup rendering on deterministic simulated VGA status reads too. */
int bench486_vesa_wait_fixture_active = 1;

int Bench486VesaWaitReadStatus (unsigned port)
{
	static const unsigned char display_samples[BVW_MAX_POLLS] = { 1, 1, 0 };
	static const unsigned char vsync_samples[BVW_MAX_POLLS] = { 0, 0, 8 };
	const unsigned char *samples;
	unsigned index;

	if (port != 0x3da)
	{
		bench486_vesa_wait_read_failures++;
		return 0;
	}
	if (vid_wait.value == VID_WAIT_DISPLAY_ENABLE)
		samples = display_samples;
	else if (vid_wait.value == VID_WAIT_VSYNC)
		samples = vsync_samples;
	else
	{
		bench486_vesa_wait_read_failures++;
		return 0;
	}

	index = bench486_vesa_wait_read_count++;
	if (index >= BVW_MAX_POLLS)
	{
		/* Fail extra reads, but make either branch polarity terminate. */
		bench486_vesa_wait_read_failures++;
		if (vid_wait.value == VID_WAIT_DISPLAY_ENABLE)
			return (index & 1U) ? 1 : 0;
		return (index & 1U) ? 0 : 8;
	}
	return samples[index];
}

static void Bench486VesaWaitResetReads (void)
{
	bench486_vesa_wait_read_count = 0;
	bench486_vesa_wait_read_failures = 0;
}

static unsigned Bench486VesaWaitOne (unsigned wait_bits, int has_vsync,
		int has_display)
{
	union { unsigned bits; float value; } wait_value;
	unsigned expected_reads, c_reads, asm_reads;
	unsigned c_abi_display, c_abi_vsync, c_abi_flags;
	unsigned asm_abi_display, asm_abi_vsync, asm_abi_flags;
	unsigned c_read_failures, asm_read_failures, failures = 0;
	int c_flags, asm_flags, expected_flags;

	wait_value.bits = wait_bits;
	vid_wait.value = wait_value.value;
	VID_extra_vsync_exists = has_vsync;
	VID_extra_display_enable_exists = has_display;
	bench486_vesa_wait_fixture_active = true;

	Bench486VesaWaitResetReads ();
	c_abi_display = Bench486Call_asm486 (
			VID_ExtraWaitDisplayIfRequested_C, 0, NULL, NULL);
	c_abi_vsync = Bench486Call_asm486 (
			VID_ExtraWaitVsyncIfRequested_C, 0, NULL, NULL);
	c_abi_flags = Bench486Call_asm486 (
			(void (*)(void))VID_ExtraDisplayStartWaitFlags_C,
			0, NULL, NULL);
	Bench486VesaWaitResetReads ();
	VID_ExtraWaitDisplayIfRequested_C ();
	VID_ExtraWaitVsyncIfRequested_C ();
	c_flags = VID_ExtraDisplayStartWaitFlags_C ();
	c_reads = bench486_vesa_wait_read_count;
	c_read_failures = bench486_vesa_wait_read_failures;

	Bench486VesaWaitResetReads ();
	asm_abi_display = Bench486Call_asm486 (
			VID_ExtraWaitDisplayIfRequested, 0, NULL, NULL);
	asm_abi_vsync = Bench486Call_asm486 (
			VID_ExtraWaitVsyncIfRequested, 0, NULL, NULL);
	asm_abi_flags = Bench486Call_asm486 (
			(void (*)(void))VID_ExtraDisplayStartWaitFlags,
			0, NULL, NULL);
	Bench486VesaWaitResetReads ();
	VID_ExtraWaitDisplayIfRequested ();
	VID_ExtraWaitVsyncIfRequested ();
	asm_flags = VID_ExtraDisplayStartWaitFlags ();
	asm_reads = bench486_vesa_wait_read_count;
	asm_read_failures = bench486_vesa_wait_read_failures;

	expected_reads = ((wait_bits == 0x40000000U && has_display) ||
			(wait_bits == 0x3f800000U && has_vsync)) ? BVW_MAX_POLLS : 0;
	expected_flags = wait_bits == 0x3f800000U ? 0x80 : 0;
	if (c_abi_display || c_abi_vsync || c_abi_flags || asm_abi_display ||
			asm_abi_vsync || asm_abi_flags || c_reads != expected_reads ||
			asm_reads != expected_reads || c_read_failures || asm_read_failures ||
			c_flags != expected_flags || asm_flags != expected_flags)
		failures++;
	return failures;
}

int Bench486VesaWaitCases (void)
{
	static const unsigned wait_modes[] = {
		0x00000000U, 0x80000000U, 0x3f800000U, 0x40000000U,
		0x40400000U, 0x3f000000U, 0x3f800001U, 0x40000001U,
		0x7fc12345U
	};
	float saved_wait = vid_wait.value;
	qboolean saved_vsync = VID_extra_vsync_exists;
	qboolean saved_display = VID_extra_display_enable_exists;
	int saved_fixture_active = bench486_vesa_wait_fixture_active;
	unsigned failures = 0, cases = 0, i;
	int has_vsync, has_display;

	for (i = 0; i < sizeof(wait_modes) / sizeof(wait_modes[0]); i++)
	for (has_vsync = 0; has_vsync < 2; has_vsync++)
	for (has_display = 0; has_display < 2; has_display++)
	{
		failures += Bench486VesaWaitOne (wait_modes[i], has_vsync,
				has_display);
		cases++;
	}
	vid_wait.value = saved_wait;
	VID_extra_vsync_exists = saved_vsync;
	VID_extra_display_enable_exists = saved_display;
	bench486_vesa_wait_fixture_active = saved_fixture_active;
	Bench486VesaWaitResetReads ();
	Bench486Printf ("VESA wait: %u exact C/assembly gate, polling and ABI cases %s (%u failures)\n",
			cases, failures ? "FAIL" : "PASS", failures);
	return failures;
}

#undef BVW_MAX_POLLS

#endif
