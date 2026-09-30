/*
 * Host-native build of the four 486 fidelity probes from WinQuake/host_cmd.c.
 *
 * Purpose: validate the PROBES, not the emulator. The DOSBox-X run scored 0/4,
 * and that result is only meaningful if the probes are sound. Running them on
 * real x86 silicon shows whether they actually detect a real x87 latency gap,
 * a real FISTPL/FIST difference, a real L1 capacity cliff, and real cache-set
 * aliasing. If they separate here and tie in DOSBox-X, the tie is the
 * emulator's, not the probe's.
 *
 * This does NOT gate a promotion and is not a substitute for a 486-accurate
 * reference: this host is not a 486. It exists to establish that the probes
 * measure what they claim to.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#define ITERATIONS 20000000
#define ALIAS_SPAN 2048
#define L1_FIT_BYTES 4096
#define L1_MISS_BYTES 24576

static double now_sec(void)
{
	struct timespec ts;
	clock_gettime(CLOCK_MONOTONIC, &ts);
	return (double)ts.tv_sec + (double)ts.tv_nsec * 1e-9;
}

static volatile int sink;

/* Probe 2: 32-bit FISTPL against 16-bit FIST. */
static void probe_fpu(int use_fist)
{
	double start, elapsed;
	int i, wide = 0;
	short narrow = 0;
	float a = 1.0001f, b = 0.9999f;

	start = now_sec();
	for (i = 0; i < ITERATIONS; i++) {
		float value = (a * b) + a;
		if (use_fist) {
			__asm__ __volatile__ ("fistps %0" : "=m" (narrow) : "t" (value));
		} else {
			__asm__ __volatile__ ("fistpl %0" : "=m" (wide) : "t" (value));
		}
		/* Keep values in a narrow range so neither store takes the
		 * integer-indefinite path, which would distort the comparison. */
		a = 1.0f + (float)(wide & 0xff) * 0.0001f + (float)(narrow & 0xff) * 0.0001f;
	}
	elapsed = now_sec() - start;
	sink = wide + narrow;
	printf("fidelity fpu %s %d ops %.6f sec %.3f ns/op checksum %d\n",
	       use_fist ? "fist16" : "fistp32", ITERATIONS, elapsed,
	       elapsed * 1e9 / ITERATIONS, wide + narrow);
}

/* Probe 1: a serialized x87 chain with a real divide, the d_draw16.s:145-198
 * shape. Memory operands, exactly as the real prologue references its globals,
 * so the chain stays serialized and a latency-accurate core cannot hide it. */
static void probe_x87chain(void)
{
	double start, elapsed;
	int i, s = 0, t = 0;
	float sdivzstepu = 0.5f, sdivzstepv = 0.25f, sdivzorigin = 0.125f;
	float tdivzstepu = 0.5f, tdivzstepv = 0.25f, tdivzorigin = 0.5f;
	float zistepu = 0.0625f, zistepv = 0.03125f, ziorigin = 1.0f;
	float fp64k = 65536.0f;

	start = now_sec();
	for (i = 0; i < ITERATIONS; i++) {
		int dv = i, du = i ^ 0x5a5a;
		__asm__ __volatile__(
			"fildl %2\n\t"
			"fildl %3\n\t"
			"fmuls %4\n\t"
			"fmuls %5\n\t"
			"faddp %%st(0),%%st(1)\n\t"
			"fadds %6\n\t"
			"fmuls %7\n\t"
			"fmuls %8\n\t"
			"faddp %%st(0),%%st(1)\n\t"
			"fadds %9\n\t"
			"fmuls %10\n\t"
			"fmuls %11\n\t"
			"faddp %%st(0),%%st(1)\n\t"
			"fadds %12\n\t"
			"flds %13\n\t"
			"fdivr %%st(0),%%st(1)\n\t"
			"fistpl %0\n\t"
			"fistpl %1\n\t"
			: "=m" (s), "=m" (t)
			: "m" (dv), "m" (du), "m" (sdivzstepu), "m" (sdivzstepv),
			  "m" (sdivzorigin), "m" (tdivzstepu), "m" (tdivzstepv),
			  "m" (tdivzorigin), "m" (zistepu), "m" (zistepv),
			  "m" (ziorigin), "m" (fp64k));
	}
	elapsed = now_sec() - start;
	sink = s + t;
	printf("fidelity x87chain %d ops %.6f sec %.3f ns/op checksum %d\n",
	       ITERATIONS, elapsed, elapsed * 1e9 / ITERATIONS, s + t);
}

/* Probe 3: a working set that fits L1 against one that cannot. */
static void probe_l1(int bytes)
{
	double start, elapsed;
	int i, count = bytes / 4;
	int *buffer = (int *)malloc((size_t)bytes + 64);

	if (!buffer) {
		printf("fidelity l1-%d skipped: allocation failed\n", bytes);
		return;
	}
	for (i = 0; i < count; i++)
		buffer[i] = i;

	start = now_sec();
	for (i = 0; i < ITERATIONS; i++) {
		int index = (i * 4) & (count - 1);
		buffer[index] += 1;
	}
	elapsed = now_sec() - start;
	sink = buffer[0];
	printf("fidelity l1-%d %d ops %.6f sec %.3f ns/op checksum %d\n",
	       bytes, ITERATIONS, elapsed, elapsed * 1e9 / ITERATIONS, buffer[0]);
	free(buffer);
}

/* Probe 4: two buffers sharing an L1 set index against two that do not.
 * The 486DX L1 is 8 KB, 4-way, 32-byte lines, 64 sets, so the set index is
 * A[11:5] and two addresses share a set when they agree modulo 2048 bytes.
 * Offset 0 aliases; offset 64 does not. This is the vid_vga.c:299-304 shape. */
static void probe_alias(int offset)
{
	double start, elapsed;
	int i, count = 1024;
	unsigned char *region = (unsigned char *)malloc(ALIAS_SPAN * 2 + 8192);
	unsigned char *first, *second;

	if (!region) {
		printf("fidelity alias-%d skipped: allocation failed\n", offset);
		return;
	}
	first = region + 1024;
	second = first + offset;
	memset(first, 1, count);
	memset(second, 2, count);

	start = now_sec();
	for (i = 0; i < ITERATIONS; i++) {
		int value = first[i & (count - 1)];
		second[i & (count - 1)] = (unsigned char)(value + 1);
	}
	elapsed = now_sec() - start;
	sink = first[0] + second[0];
	printf("fidelity alias-%d %d ops %.6f sec %.3f ns/op checksum %d\n",
	       offset, ITERATIONS, elapsed, elapsed * 1e9 / ITERATIONS,
	       first[0] + second[0]);
	free(region);
}

int main(void)
{
	probe_x87chain();
	probe_fpu(0);
	probe_fpu(1);
	probe_l1(L1_FIT_BYTES);
	probe_l1(L1_MISS_BYTES);
	probe_alias(0);
	probe_alias(64);
	return 0;
}
