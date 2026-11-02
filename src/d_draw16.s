/*
Copyright (C) 1996-1997 Id Software, Inc.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  

See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

*/
//
// d_draw16.s
// x86 assembly-language horizontal 8-bpp span-drawing code, with 16-pixel
// subdivision.
//

#include "asm_i386.h"
#include "quakeasm.h"
#include "asm_draw.h"
#include "d_ifacea.h"

#ifdef ASM486_SPAN16_WORD_STOS
#define SPAN16_STORE_WORD(offset) stosw
#else
#define SPAN16_STORE_WORD(offset) movw %ax,offset(%edi)
#endif

#if	id386

#ifdef PROFILE486
	.extern C(bench486_profile_frame_active)
	.extern C(bench486_texture_full_tzero)
	.extern C(bench486_texture_full_tdelta_zero)
	.extern C(bench486_texture_full_tfrac_zero)
	.extern C(bench486_texture_full_sfrac_zero)
	.extern C(bench486_texture_full_sone)
	.extern C(bench486_texture_full_exact)
	.extern C(bench486_texture_final_exact)
	.extern C(bench486_texture_full_row_eligible)
	.extern C(bench486_texture_full_row_fast)
	.extern C(bench486_span_segments)
	.extern C(bench486_span_unit_stride_segments)
	.extern C(bench486_span_unit_stride_pixels)
	.extern C(bench486_texture_span_same_row_links)
#endif

//----------------------------------------------------------------------
// 8-bpp horizontal span drawing code for polygons, with no transparency and
// 16-pixel subdivision.
//
// Assumes there is at least one span in pspans, and that every span
// contains at least one pixel
//----------------------------------------------------------------------

	.data

	.text

// out-of-line, rarely-needed clamping code

LClampHigh0:
	movl	C(bbextents),%esi
	jmp		LClampReentry0
LClampHighOrLow0:
	jg		LClampHigh0
	xorl	%esi,%esi
	jmp		LClampReentry0

LClampHigh1:
	movl	C(bbextentt),%edx
	jmp		LClampReentry1
LClampHighOrLow1:
	jg		LClampHigh1
	xorl	%edx,%edx
	jmp		LClampReentry1

LClampLow2:
	movl	$4096,%ebp
	jmp		LClampReentry2
LClampHigh2:
	movl	C(bbextents),%ebp
	jmp		LClampReentry2

LClampLow3:
	movl	$4096,%ecx
	jmp		LClampReentry3
LClampHigh3:
	movl	C(bbextentt),%ecx
	jmp		LClampReentry3

LClampLow4:
	movl	$4096,%eax
	jmp		LClampReentry4
LClampHigh4:
	movl	C(bbextents),%eax
	jmp		LClampReentry4

LClampLow5:
	movl	$4096,%ebx
	jmp		LClampReentry5
LClampHigh5:
	movl	C(bbextentt),%ebx
	jmp		LClampReentry5


#define pspans	4+16

	.p2align 4,,15
.globl C(D_DrawSpans16)
C(D_DrawSpans16):
	pushl	%ebp				// preserve caller's stack frame
	pushl	%edi
	pushl	%esi				// preserve register variables
	pushl	%ebx

//
// set up scaled-by-16 steps, for 16-long segments; also set up cacheblock
// and span list pointers
//
// TODO: any overlap from rearranging?
	flds	C(d_sdivzstepu)
	fmuls	fp_16
	movl	C(cacheblock),%edx
	flds	C(d_tdivzstepu)
	fmuls	fp_16
	movl	pspans(%esp),%ebx	// point to the first span descriptor
	flds	C(d_zistepu)
	fmuls	fp_16
	movl	%edx,pbase			// pbase = cacheblock
	fstps	zi16stepu
	fstps	tdivz16stepu
	fstps	sdivz16stepu

LSpanLoop:
//
// set up the initial s/z, t/z, and 1/z on the FP stack, and generate the
// initial s and t values
//
// FIXME: pipeline FILD?
	fildl	espan_t_v(%ebx)
	fildl	espan_t_u(%ebx)
	// Keep the independent integer loads behind both x87 loads so they can
	// occupy the FPU's conversion window before the dependent arithmetic.
	movl	espan_t_v(%ebx),%eax
#ifdef PROFILE486
	cmpl	$0,C(bench486_profile_frame_active)
	jz		LSpan16SameRowStatsDone
	movl	espan_t_pnext(%ebx),%edx
	testl	%edx,%edx
	jz		LSpan16SameRowStatsDone
	cmpl	espan_t_v(%edx),%eax
	jne		LSpan16SameRowStatsDone
	incl	C(bench486_texture_span_same_row_links)
LSpan16SameRowStatsDone:
#endif
	movl	C(tadjust),%edx
	// Fetch the span's destination and continuation state while x87 setup runs.
	pushl	espan_t_pnext(%ebx)
	movl	C(sadjust),%esi
	movl	C(viewspantable)(,%eax,4),%edi
	movl	espan_t_u(%ebx),%ecx
	addl	%ecx,%edi
	movl	espan_t_count(%ebx),%ecx

	fld		%st(1)			// dv | du | dv
	fmuls	C(d_sdivzstepv)	// dv*d_sdivzstepv | du | dv
	fld		%st(1)			// du | dv*d_sdivzstepv | du | dv
	fmuls	C(d_sdivzstepu)	// du*d_sdivzstepu | dv*d_sdivzstepv | du | dv
	fld		%st(2)			// du | du*d_sdivzstepu | dv*d_sdivzstepv | du | dv
	fmuls	C(d_tdivzstepu)	// du*d_tdivzstepu | du*d_sdivzstepu |
							//  dv*d_sdivzstepv | du | dv
	fxch	%st(1)			// du*d_sdivzstepu | du*d_tdivzstepu |
							//  dv*d_sdivzstepv | du | dv
	faddp	%st(0),%st(2)	// du*d_tdivzstepu |
							//  du*d_sdivzstepu + dv*d_sdivzstepv | du | dv
	fxch	%st(1)			// du*d_sdivzstepu + dv*d_sdivzstepv |
							//  du*d_tdivzstepu | du | dv
	fld		%st(3)			// dv | du*d_sdivzstepu + dv*d_sdivzstepv |
							//  du*d_tdivzstepu | du | dv
	fmuls	C(d_tdivzstepv)	// dv*d_tdivzstepv |
							//  du*d_sdivzstepu + dv*d_sdivzstepv |
							//  du*d_tdivzstepu | du | dv
	fxch	%st(1)			// du*d_sdivzstepu + dv*d_sdivzstepv |
							//  dv*d_tdivzstepv | du*d_tdivzstepu | du | dv
	fadds	C(d_sdivzorigin)	// sdivz = d_sdivzorigin + dv*d_sdivzstepv +
							//  du*d_sdivzstepu; stays in %st(2) at end
	fxch	%st(4)			// dv | dv*d_tdivzstepv | du*d_tdivzstepu | du |
							//  s/z
	fmuls	C(d_zistepv)		// dv*d_zistepv | dv*d_tdivzstepv |
							//  du*d_tdivzstepu | du | s/z
	fxch	%st(1)			// dv*d_tdivzstepv |  dv*d_zistepv |
							//  du*d_tdivzstepu | du | s/z
	faddp	%st(0),%st(2)	// dv*d_zistepv |
							//  dv*d_tdivzstepv + du*d_tdivzstepu | du | s/z
	fxch	%st(2)			// du | dv*d_tdivzstepv + du*d_tdivzstepu |
							//  dv*d_zistepv | s/z
	fmuls	C(d_zistepu)		// du*d_zistepu |
							//  dv*d_tdivzstepv + du*d_tdivzstepu |
							//  dv*d_zistepv | s/z
	fxch	%st(1)			// dv*d_tdivzstepv + du*d_tdivzstepu |
							//  du*d_zistepu | dv*d_zistepv | s/z
	fadds	C(d_tdivzorigin)	// tdivz = d_tdivzorigin + dv*d_tdivzstepv +
							//  du*d_tdivzstepu; stays in %st(1) at end
	fxch	%st(2)			// dv*d_zistepv | du*d_zistepu | t/z | s/z
	faddp	%st(0),%st(1)	// dv*d_zistepv + du*d_zistepu | t/z | s/z

	flds	fp_64k			// fp_64k | dv*d_zistepv + du*d_zistepu | t/z | s/z
	fxch	%st(1)			// dv*d_zistepv + du*d_zistepu | fp_64k | t/z | s/z
	fadds	C(d_ziorigin)		// zi = d_ziorigin + dv*d_zistepv +
							//  du*d_zistepu; stays in %st(0) at end
							// 1/z | fp_64k | t/z | s/z
//
// calculate and clamp s & t
//
	fdivr	%st(0),%st(1)	// 1/z | z*64k | t/z | s/z

//
// point %edi to the first pixel in the span
// Row addresses come from viewspantable (filled in D_SetupFrame) instead of
// d_scantable plus d_viewbuffer.  C D_DrawSpans8 still multiplies screenwidth.
//
//
// now start the FDIV for the end of the span
//
	cmpl	$16,%ecx
	ja		LSetupNotLast1

	decl	%ecx
	jz		LCleanup1		// if only one pixel, no need to start an FDIV
	movl	%ecx,spancountminus1

// finish up the s and t calcs
	fxch	%st(1)			// z*64k | 1/z | t/z | s/z

	fld		%st(0)			// z*64k | z*64k | 1/z | t/z | s/z
	fmul	%st(4),%st(0)	// s | z*64k | 1/z | t/z | s/z
	fxch	%st(1)			// z*64k | s | 1/z | t/z | s/z
	fmul	%st(3),%st(0)	// t | s | 1/z | t/z | s/z
	fxch	%st(1)			// s | t | 1/z | t/z | s/z
	fistpl	s				// 1/z | t | t/z | s/z
	fistpl	t				// 1/z | t/z | s/z

	fildl	spancountminus1

	flds	C(d_tdivzstepu)	// C(d_tdivzstepu) | spancountminus1
	flds	C(d_zistepu)		// C(d_zistepu) | C(d_tdivzstepu) | spancountminus1
	fmul	%st(2),%st(0)	// C(d_zistepu)*scm1 | C(d_tdivzstepu) | scm1
	fxch	%st(1)			// C(d_tdivzstepu) | C(d_zistepu)*scm1 | scm1
	fmul	%st(2),%st(0)	// C(d_tdivzstepu)*scm1 | C(d_zistepu)*scm1 | scm1
	fxch	%st(2)			// scm1 | C(d_zistepu)*scm1 | C(d_tdivzstepu)*scm1
	fmuls	C(d_sdivzstepu)	// C(d_sdivzstepu)*scm1 | C(d_zistepu)*scm1 |
							//  C(d_tdivzstepu)*scm1
	fxch	%st(1)			// C(d_zistepu)*scm1 | C(d_sdivzstepu)*scm1 |
							//  C(d_tdivzstepu)*scm1
	faddp	%st(0),%st(3)	// C(d_sdivzstepu)*scm1 | C(d_tdivzstepu)*scm1
	fxch	%st(1)			// C(d_tdivzstepu)*scm1 | C(d_sdivzstepu)*scm1
	faddp	%st(0),%st(3)	// C(d_sdivzstepu)*scm1
	faddp	%st(0),%st(3)

	flds	fp_64k
	fdiv	%st(1),%st(0)	// this is what we've gone to all this trouble to
							//  overlap
	jmp		LFDIVInFlight1

LCleanup1:
// finish up the s and t calcs
	fxch	%st(1)			// z*64k | 1/z | t/z | s/z

	fld		%st(0)			// z*64k | z*64k | 1/z | t/z | s/z
	fmul	%st(4),%st(0)	// s | z*64k | 1/z | t/z | s/z
	fxch	%st(1)			// z*64k | s | 1/z | t/z | s/z
	fmul	%st(3),%st(0)	// t | s | 1/z | t/z | s/z
	fxch	%st(1)			// s | t | 1/z | t/z | s/z
	fistpl	s				// 1/z | t | t/z | s/z
	fistpl	t				// 1/z | t/z | s/z
	jmp		LFDIVInFlight1

	.p2align 4,,15
LSetupNotLast1:
	movl	%ecx,counttemp	// seed the remaining full-span count
// finish up the s and t calcs
	fxch	%st(1)			// z*64k | 1/z | t/z | s/z

	fld		%st(0)			// z*64k | z*64k | 1/z | t/z | s/z
	fmul	%st(4),%st(0)	// s | z*64k | 1/z | t/z | s/z
	fxch	%st(1)			// z*64k | s | 1/z | t/z | s/z
	fmul	%st(3),%st(0)	// t | s | 1/z | t/z | s/z
	fxch	%st(1)			// s | t | 1/z | t/z | s/z
	fistpl	s				// 1/z | t | t/z | s/z
	fistpl	t				// 1/z | t/z | s/z

	fadds	zi16stepu
	fxch	%st(2)
	fadds	sdivz16stepu
	fxch	%st(2)
	flds	tdivz16stepu
	faddp	%st(0),%st(2)
	flds	fp_64k
	fdiv	%st(1),%st(0)	// z = 1/1/z
							// this is what we've gone to all this trouble to
							//  overlap
LFDIVInFlight1:

	addl	s,%esi
	addl	t,%edx
	cmpl	C(bbextents),%esi
	ja		LClampHighOrLow0
LClampReentry0:
	movl	%esi,s
	movl	pbase,%ebx
	shll	$16,%esi
	cmpl	C(bbextentt),%edx
	movl	%esi,sfracf
	ja		LClampHighOrLow1
LClampReentry1:
	movl	%edx,t
	movl	s,%esi					// sfrac = scans->sfrac;
	shll	$16,%edx
	movl	t,%eax					// tfrac = scans->tfrac;
	sarl	$16,%esi
	movl	%edx,tfracf

//
// calculate the texture starting address
//
	sarl	$16,%eax
	// Keep cachewidth in the multiply instruction; this saves a register move.
	imull	C(cachewidth),%eax				// (tfrac >> 16) * cachewidth
	addl	%ebx,%esi
	addl	%eax,%esi				// psource = pbase + (sfrac >> 16) +
									//           ((tfrac >> 16) * cachewidth);
//
// determine whether last span or not
//
	cmpl	$16,%ecx
	jna		LLastSegment

//
// not the last segment; do full 16-wide segment
//
LNotLastSegment:

//
// advance s/z, t/z, and 1/z, and calculate s & t at end of span and steps to
// get there
//

// pick up after the FDIV that was left in flight previously

	fld		%st(0)			// duplicate it
	fmul	%st(4),%st(0)	// s = s/z * z
	fistpl	snext
	fmul	%st(2),%st(0)	// t = t/z * z after the S pop
	fistpl	tnext
	movl	snext,%eax
	movl	tnext,%edx

	movb	(%esi),%bl	// get first source texel
	subl	$16,counttemp	// count off this segment in memory
	movl	C(sadjust),%ebp

	movl	C(tadjust),%ecx
	movb	%bl,(%edi)	// store first dest pixel

	addl	%eax,%ebp
	addl	%edx,%ecx

	cmpl	$4096,%ebp
	jl		LClampLow2
	cmpl	C(bbextents),%ebp
	ja		LClampHigh2
LClampReentry2:

	cmpl	$4096,%ecx
	jl		LClampLow3
	cmpl	C(bbextentt),%ecx
	ja		LClampHigh3
LClampReentry3:

#ifdef ASM486_SPAN16_NO_ROW_CROSS
	// A non-negative segment whose clamped endpoints share a texture row
	// cannot take a row carry during its sixteen samples.  Keep every other
	// segment on the original two-axis DDA below.
	movl	%ecx,%eax
	cmpl	t,%eax
	jl		LSpan16RowCrossFallback
	sarl	$16,%eax
	movl	t,%edx
	sarl	$16,%edx
	cmpl	%edx,%eax
	jne		LSpan16RowCrossFallback

#ifdef PROFILE486
	cmpl	$0,C(bench486_profile_frame_active)
	jz		LSpan16RowStatsDone
	incl	C(bench486_texture_full_row_eligible)
LSpan16RowStatsDone:
#endif
	movl	%ebp,snext
	movl	%ecx,tnext
	subl	s,%ebp
	movl	%ebp,%eax
	sarl	$20,%eax
	movl	%eax,advancetable+4	// no t-row component in this path
	movl	tnext,%edx
	shll	$16,%edx			// final tfrac for the next segment
	shll	$12,%ebp			// sstep fractional component
	movl	sfracf,%ebx
	addl	%ebp,%ebx
	adcl	advancetable+4,%esi	// advance to the first loop sample on S only

#ifdef PROFILE486
	cmpl	$0,C(bench486_profile_frame_active)
	jz		LSpan16RowFastStatsDone
	incl	C(bench486_texture_full_row_fast)
LSpan16RowFastStatsDone:
#endif
	jmp		LSpan16NoRowCrossStores
LSpan16RowCrossFallback:
#endif

#if defined(ASM486_SPAN_SETUP_PROBE_SETUP)
	// Dead-scratch probe, 6 instructions, at the head of the per-segment
	// setup.  Every sixteen-wide segment passes this point exactly once, so
	// the count is the segment count (2,059,015 over the run) and no counter
	// is needed.
	//
	// Duplicates the first three instructions the setup performs.  %eax and
	// %edx are both dead on entry and are rewritten by the real code at the
	// `movl %ecx,%eax' / `movl %ebp,%edx' pair a few lines below, and the
	// flags `sarl' sets are dead too -- the two `subl' at s/t recompute them
	// before anything branches.  %ebp and %ecx are the live s and t values
	// and are only read.
	//
	// Why this exists: the ledger closes texture-spans on the arithmetic
	// "220 cycles of per-segment setup per sixteen pixels", but the integer
	// setup path (here through LSetUpCommon) is about 23 instructions and
	// contains no x87 at all.  Those two numbers cannot both be right.  This
	// probe measures the setup's actual price instead of reconciling it by
	// argument.
	movl	%ebp,%eax
	movl	%ecx,%edx
	sarl	$20,%eax
	movl	%ebp,%eax
	movl	%ecx,%edx
	sarl	$20,%eax
#endif

#ifdef ASM486_SPAN16_NO_ROW_CROSS
	movl	$0,jumptemp			// use the control B half
#endif
	movl	%ebp,snext
	movl	%ecx,tnext

	subl	s,%ebp
	subl	t,%ecx
	
//
// set up advancetable
//
	movl	%ecx,%eax
	movl	%ebp,%edx
	sarl	$20,%edx			// sstep >>= 16; independent of the T branch
	sarl	$20,%eax			// tstep >>= 16;
	jnz		LNonZeroSetup
	// The common zero-tstep case does not need cachewidth in a register:
	// ebx is replaced by sfracf below, so add the row stride from memory.
	// Keep the profile-only accounting in both setup arms so the release path
	// does not pay for an extra branch just to share this diagnostic block.

#ifdef PROFILE486
	cmpl	$0,C(bench486_profile_frame_active)
	jz		LProfileZeroStatsDone
	incl	C(bench486_span_segments)
	testl	%ecx,%ecx
	jnz		LProfileZeroNoTDeltaZero
	incl	C(bench486_texture_full_tdelta_zero)
LProfileZeroNoTDeltaZero:
	testl	$0xfffff,%ecx
	jnz		LProfileZeroNoTFracZero
	incl	C(bench486_texture_full_tfrac_zero)
LProfileZeroNoTFracZero:
	testl	%eax,%eax
	jnz		LProfileZeroNoTZero
	incl	C(bench486_texture_full_tzero)
LProfileZeroNoTZero:
	cmpl	$1,%edx
	jne		LProfileZeroNoSOne
	incl	C(bench486_texture_full_sone)
	// Unit-stride premise.  A sixteen-wide segment whose t step has no whole
	// texel component, whose s step is exactly one texel, and whose s step
	// has no fractional part, advances the source by exactly one byte per
	// sample with no carry: the per-pixel `addl %ebp,%ebx' /
	// `adcl advancetable+4,%esi' pair collapses to `addl $1,%esi'.  Counted
	// here, before the DDA is built, and weighted by pixels, because a
	// segment count on its own cannot be priced.
	cmpl	$0,%eax
	jne	LProfileZeroNoUnitStride
	testl	$0xfffff,%ebp
	jnz	LProfileZeroNoUnitStride
	incl	C(bench486_span_unit_stride_segments)
	addl	$16,C(bench486_span_unit_stride_pixels)
LProfileZeroNoUnitStride:
LProfileZeroNoSOne:
	testl	$0xfffff,%ebp
	jnz		LProfileZeroNoSFracZero
	incl	C(bench486_texture_full_sfrac_zero)
LProfileZeroNoSFracZero:
	testl	$0xfffff,%ebp
	jnz		LProfileZeroStatsDone
	testl	$0xfffff,%ecx
	jnz		LProfileZeroStatsDone
	incl	C(bench486_texture_full_exact)
LProfileZeroStatsDone:
#endif

	addl	%edx,%eax			// add in sstep
						// (tstep >> 16) * cachewidth + (sstep >> 16);
	movl	%eax,advancetable+4	// advance base in t
	addl	C(cachewidth),%eax	// ((tstep >> 16) + 1) * cachewidth +
						//  (sstep >> 16);
	movl	tfracf,%edx
	jmp		LSetUpCommon

LNonZeroSetup:
	imull	C(cachewidth),%eax

#ifdef PROFILE486
	cmpl	$0,C(bench486_profile_frame_active)
	jz		LProfileNonZeroStatsDone
	incl	C(bench486_span_segments)
	testl	%ecx,%ecx
	jnz		LProfileNonZeroNoTDeltaZero
	incl	C(bench486_texture_full_tdelta_zero)
LProfileNonZeroNoTDeltaZero:
	testl	$0xfffff,%ecx
	jnz		LProfileNonZeroNoTFracZero
	incl	C(bench486_texture_full_tfrac_zero)
LProfileNonZeroNoTFracZero:
	testl	%eax,%eax
	jnz		LProfileNonZeroNoTZero
	incl	C(bench486_texture_full_tzero)
LProfileNonZeroNoTZero:
	cmpl	$1,%edx
	jne		LProfileNonZeroNoSOne
	incl	C(bench486_texture_full_sone)
LProfileNonZeroNoSOne:
	testl	$0xfffff,%ebp
	jnz		LProfileNonZeroNoSFracZero
	incl	C(bench486_texture_full_sfrac_zero)
LProfileNonZeroNoSFracZero:
	testl	$0xfffff,%ebp
	jnz		LProfileNonZeroStatsDone
	testl	$0xfffff,%ecx
	jnz		LProfileNonZeroStatsDone
	incl	C(bench486_texture_full_exact)
LProfileNonZeroStatsDone:
#endif
	addl	%edx,%eax			// add in sstep
						// (tstep >> 16) * cachewidth + (sstep >> 16);
	movl	%eax,advancetable+4	// advance base in t
	addl	C(cachewidth),%eax	// ((tstep >> 16) + 1) * cachewidth +
						//  (sstep >> 16);
	movl	tfracf,%edx

LSetUpCommon:
	movl	sfracf,%ebx
	shll	$12,%ecx			// left-justify tstep fractional part
	shll	$12,%ebp			// left-justify sstep fractional part
	movl	%eax,advancetable	// advance extra in t

	addl	%ecx,%edx			// advance tfrac fractional part by tstep frac
	movl	%ecx,tstep

	sbbl	%ecx,%ecx			// turn tstep carry into -1 (0 if none)
	addl	%ebp,%ebx			// advance sfrac fractional part by sstep frac
	adcl	advancetable+4(,%ecx,4),%esi	// point to next source texel

#ifdef ASM486_SPAN16_NO_ROW_CROSS
	jmp		LSpan16ControlStoresA
#endif

#ifdef ASM486_SPAN16_NO_ROW_CROSS
// Same store schedules as the control path, but the texture address only
// advances from the S accumulator.  The row test above proves that no T
// carry can affect any of these sixteen samples.
LSpan16NoRowCrossStores:
#ifdef ASM486_SPAN16_LOOP_STOSB
	incl	%edi
	movl	$7,jumptemp
LSpan16NoRowCrossLoopA:
	movb	(%esi),%al
	addl	%ebp,%ebx
	adcl	advancetable+4,%esi
	decl	jumptemp
	stosb
	jnz		LSpan16NoRowCrossLoopA
#elif defined(ASM486_SPAN16_WORD_STORES)
	movb	(%esi),%al
	addl	%ebp,%ebx
	adcl	advancetable+4,%esi
	movb	(%esi),%ah
	addl	%ebp,%ebx
	adcl	advancetable+4,%esi
	SPAN16_STORE_WORD(1)

	movb	(%esi),%al
	addl	%ebp,%ebx
	adcl	advancetable+4,%esi
	movb	(%esi),%ah
	addl	%ebp,%ebx
	adcl	advancetable+4,%esi
	SPAN16_STORE_WORD(3)

	movb	(%esi),%al
	addl	%ebp,%ebx
	adcl	advancetable+4,%esi
	movb	(%esi),%ah
	addl	%ebp,%ebx
	adcl	advancetable+4,%esi
	SPAN16_STORE_WORD(5)

	movb	(%esi),%al
	addl	%ebp,%ebx
	adcl	advancetable+4,%esi
	movb	(%esi),%ah
	addl	%ebp,%ebx
	adcl	advancetable+4,%esi
	SPAN16_STORE_WORD(7)

#elif defined(ASM486_SPAN16_DWORD_STORES)
	movb	(%edi),%al
	movb	(%esi),%ah
	addl	%ebp,%ebx
	adcl	advancetable+4,%esi
	rorl	$16,%eax
	movb	(%esi),%al
	addl	%ebp,%ebx
	adcl	advancetable+4,%esi
	movb	(%esi),%ah
	rorl	$16,%eax
	movl	%eax,(%edi)
	addl	%ebp,%ebx
	adcl	advancetable+4,%esi

	movb	(%esi),%al
	addl	%ebp,%ebx
	adcl	advancetable+4,%esi
	movb	(%esi),%ah
	addl	%ebp,%ebx
	adcl	advancetable+4,%esi
	rorl	$16,%eax
	movb	(%esi),%al
	addl	%ebp,%ebx
	adcl	advancetable+4,%esi
	movb	(%esi),%ah
	rorl	$16,%eax
	movl	%eax,4(%edi)
	addl	%ebp,%ebx
	adcl	advancetable+4,%esi

#else
	movb	(%esi),%al
	addl	%ebp,%ebx
	movb	%al,1(%edi)
	adcl	advancetable+4,%esi

	movb	(%esi),%al
	addl	%ebp,%ebx
	movb	%al,2(%edi)
	adcl	advancetable+4,%esi

	movb	(%esi),%al
	addl	%ebp,%ebx
	movb	%al,3(%edi)
	adcl	advancetable+4,%esi

	movb	(%esi),%al
	addl	%ebp,%ebx
	movb	%al,4(%edi)
	adcl	advancetable+4,%esi

	movb	(%esi),%al
	addl	%ebp,%ebx
	movb	%al,5(%edi)
	adcl	advancetable+4,%esi

	movb	(%esi),%al
	addl	%ebp,%ebx
	movb	%al,6(%edi)
	adcl	advancetable+4,%esi

	movb	(%esi),%al
	addl	%ebp,%ebx
	movb	%al,7(%edi)
	adcl	advancetable+4,%esi
#endif
	movl	$1,jumptemp			// mark this segment for the B half
	jmp		LSpan16AfterStoresA

LSpan16ControlStoresA:
#endif

#ifdef ASM486_SPAN16_LOOP_STOSB
	incl	%edi
	movl	$7,jumptemp
LSpan16LoopA:
	addl	tstep,%edx
	sbbl	%ecx,%ecx
	addl	%ebp,%ebx
	movb	(%esi),%al
	adcl	advancetable+4(,%ecx,4),%esi
	decl	jumptemp
	stosb
	jnz		LSpan16LoopA
#elif defined(ASM486_SPAN16_WORD_STORES)
#ifdef ASM486_SPAN16_WORD_STOS
	incl	%edi
#endif
#ifdef ASM486_SPAN16_LOAD_FIRST
	// Start each independent texel load before the fixed-point updates.
	movb	(%esi),%al
	addl	tstep,%edx
	sbbl	%ecx,%ecx
	addl	%ebp,%ebx
	adcl	advancetable+4(,%ecx,4),%esi

	movb	(%esi),%ah
	addl	tstep,%edx
	sbbl	%ecx,%ecx
	addl	%ebp,%ebx
	adcl	advancetable+4(,%ecx,4),%esi
	SPAN16_STORE_WORD(1)

	movb	(%esi),%al
	addl	tstep,%edx
	sbbl	%ecx,%ecx
	addl	%ebp,%ebx
	adcl	advancetable+4(,%ecx,4),%esi

	movb	(%esi),%ah
	addl	tstep,%edx
	sbbl	%ecx,%ecx
	addl	%ebp,%ebx
	adcl	advancetable+4(,%ecx,4),%esi
	SPAN16_STORE_WORD(3)

	movb	(%esi),%al
	addl	tstep,%edx
	sbbl	%ecx,%ecx
	addl	%ebp,%ebx
	adcl	advancetable+4(,%ecx,4),%esi

	movb	(%esi),%ah
	addl	tstep,%edx
	sbbl	%ecx,%ecx
	addl	%ebp,%ebx
	adcl	advancetable+4(,%ecx,4),%esi
	SPAN16_STORE_WORD(5)

	movb	(%esi),%al
	addl	tstep,%edx
	sbbl	%ecx,%ecx
	addl	%ebp,%ebx
	adcl	advancetable+4(,%ecx,4),%esi

	movb	(%esi),%ah
	addl	tstep,%edx
	sbbl	%ecx,%ecx
	addl	%ebp,%ebx
	adcl	advancetable+4(,%ecx,4),%esi
	SPAN16_STORE_WORD(7)
#else
	addl	tstep,%edx
	movb	(%esi),%al
	sbbl	%ecx,%ecx
	addl	%ebp,%ebx
	adcl	advancetable+4(,%ecx,4),%esi

	addl	tstep,%edx
	sbbl	%ecx,%ecx
	addl	%ebp,%ebx
	movb	(%esi),%ah		// MOV preserves the S-step carry for ADC below.
	adcl	advancetable+4(,%ecx,4),%esi
	addl	tstep,%edx		// Store and byte load preserve this T-step carry.
	SPAN16_STORE_WORD(1)

	movb	(%esi),%al
	sbbl	%ecx,%ecx
	addl	%ebp,%ebx
	adcl	advancetable+4(,%ecx,4),%esi

	addl	tstep,%edx
	sbbl	%ecx,%ecx
	addl	%ebp,%ebx
	movb	(%esi),%ah
	adcl	advancetable+4(,%ecx,4),%esi
	SPAN16_STORE_WORD(3)

	addl	tstep,%edx
	movb	(%esi),%al
	sbbl	%ecx,%ecx
	addl	%ebp,%ebx
	adcl	advancetable+4(,%ecx,4),%esi

	addl	tstep,%edx
	sbbl	%ecx,%ecx
	addl	%ebp,%ebx
	movb	(%esi),%ah
	adcl	advancetable+4(,%ecx,4),%esi
	SPAN16_STORE_WORD(5)

	addl	tstep,%edx
	movb	(%esi),%al
	sbbl	%ecx,%ecx
	addl	%ebp,%ebx
	adcl	advancetable+4(,%ecx,4),%esi

	addl	tstep,%edx
	sbbl	%ecx,%ecx
	addl	%ebp,%ebx
	movb	(%esi),%ah
	adcl	advancetable+4(,%ecx,4),%esi
	SPAN16_STORE_WORD(7)
#endif

#elif defined(ASM486_SPAN16_DWORD_STORES)
	// 486-class stores: pack four sequential dest pixels and movl them.
	// Sampling/DDA stays identical; AH/AL packing is cheap on a 486 (no
	// Pentium partial-register stall). Dest may be unaligned.
	movb	(%edi),%al
	movb	(%esi),%ah
	addl	tstep,%edx
	sbbl	%ecx,%ecx
	addl	%ebp,%ebx
	adcl	advancetable+4(,%ecx,4),%esi
	rorl	$16,%eax
	movb	(%esi),%al
	addl	tstep,%edx
	sbbl	%ecx,%ecx
	addl	%ebp,%ebx
	adcl	advancetable+4(,%ecx,4),%esi
	movb	(%esi),%ah
	rorl	$16,%eax
	movl	%eax,(%edi)
	addl	tstep,%edx
	sbbl	%ecx,%ecx
	addl	%ebp,%ebx
	adcl	advancetable+4(,%ecx,4),%esi

	movb	(%esi),%al
	addl	tstep,%edx
	sbbl	%ecx,%ecx
	addl	%ebp,%ebx
	adcl	advancetable+4(,%ecx,4),%esi
	movb	(%esi),%ah
	addl	tstep,%edx
	sbbl	%ecx,%ecx
	addl	%ebp,%ebx
	adcl	advancetable+4(,%ecx,4),%esi
	rorl	$16,%eax
	movb	(%esi),%al
	addl	tstep,%edx
	sbbl	%ecx,%ecx
	addl	%ebp,%ebx
	adcl	advancetable+4(,%ecx,4),%esi
	movb	(%esi),%ah
	rorl	$16,%eax
	movl	%eax,4(%edi)
	addl	tstep,%edx
	sbbl	%ecx,%ecx
	addl	%ebp,%ebx
	adcl	advancetable+4(,%ecx,4),%esi
#else
	addl	tstep,%edx
	sbbl	%ecx,%ecx
	movb	(%esi),%al
	addl	%ebp,%ebx
	movb	%al,1(%edi)
	adcl	advancetable+4(,%ecx,4),%esi

	addl	tstep,%edx
	sbbl	%ecx,%ecx
	addl	%ebp,%ebx
	movb	(%esi),%al
	adcl	advancetable+4(,%ecx,4),%esi

	addl	tstep,%edx
	sbbl	%ecx,%ecx
	movb	%al,2(%edi)
	addl	%ebp,%ebx
	movb	(%esi),%al
	adcl	advancetable+4(,%ecx,4),%esi

	addl	tstep,%edx
	sbbl	%ecx,%ecx
	movb	%al,3(%edi)
	addl	%ebp,%ebx
	movb	(%esi),%al
	adcl	advancetable+4(,%ecx,4),%esi

	addl	tstep,%edx
	sbbl	%ecx,%ecx
	movb	%al,4(%edi)
	addl	%ebp,%ebx
	movb	(%esi),%al
	adcl	advancetable+4(,%ecx,4),%esi

	addl	tstep,%edx
	sbbl	%ecx,%ecx
	movb	%al,5(%edi)
	addl	%ebp,%ebx
	movb	(%esi),%al
	adcl	advancetable+4(,%ecx,4),%esi

	addl	tstep,%edx
	sbbl	%ecx,%ecx
	movb	%al,6(%edi)
	addl	%ebp,%ebx
	movb	(%esi),%al
	adcl	advancetable+4(,%ecx,4),%esi

	addl	tstep,%edx
	sbbl	%ecx,%ecx
	movb	%al,7(%edi)
	addl	%ebp,%ebx
	movb	(%esi),%al
	adcl	advancetable+4(,%ecx,4),%esi
#endif

LSpan16AfterStoresA:


//
// start FDIV for end of next segment in flight, so it can overlap
//
	cmpl	$16,counttemp		// full segment remains? Keep the count in memory.
	ja		LSetupNotLast2	// yes

	decl	counttemp		// test the one-pixel tail in memory
	jz		LFDIVInFlight2	// if only one pixel, no need to start an FDIV
	movl	counttemp,%ecx
	movl	%ecx,spancountminus1
	fildl	spancountminus1

	flds	C(d_zistepu)		// C(d_zistepu) | spancountminus1
	fmul	%st(1),%st(0)	// C(d_zistepu)*scm1 | scm1
	flds	C(d_tdivzstepu)	// C(d_tdivzstepu) | C(d_zistepu)*scm1 | scm1
	fmul	%st(2),%st(0)	// C(d_tdivzstepu)*scm1 | C(d_zistepu)*scm1 | scm1
	fxch	%st(1)			// C(d_zistepu)*scm1 | C(d_tdivzstepu)*scm1 | scm1
	faddp	%st(0),%st(3)	// C(d_tdivzstepu)*scm1 | scm1
	fxch	%st(1)			// scm1 | C(d_tdivzstepu)*scm1
	fmuls	C(d_sdivzstepu)	// C(d_sdivzstepu)*scm1 | C(d_tdivzstepu)*scm1
	fxch	%st(1)			// C(d_tdivzstepu)*scm1 | C(d_sdivzstepu)*scm1
	faddp	%st(0),%st(3)	// C(d_sdivzstepu)*scm1
	flds	fp_64k			// 64k | C(d_sdivzstepu)*scm1
	fxch	%st(1)			// C(d_sdivzstepu)*scm1 | 64k
	faddp	%st(0),%st(4)	// 64k

	fdiv	%st(1),%st(0)	// this is what we've gone to all this trouble to
							//  overlap
	jmp		LFDIVInFlight2

	.p2align 4,,15
LSetupNotLast2:
	fadds	zi16stepu
	fxch	%st(2)
	fadds	sdivz16stepu
	fxch	%st(2)
	flds	tdivz16stepu
	faddp	%st(0),%st(2)
	flds	fp_64k
	fdiv	%st(1),%st(0)	// z = 1/1/z
							// this is what we've gone to all this trouble to
							//  overlap
LFDIVInFlight2:
#ifdef ASM486_SPAN16_NO_ROW_CROSS
	cmpl	$1,jumptemp
	jne		LSpan16ControlStoresB
LSpan16NoRowCrossStoresB:
#ifdef ASM486_SPAN16_LOOP_STOSB
	movl	$8,jumptemp
LSpan16NoRowCrossLoopB:
	movb	(%esi),%al
	addl	%ebp,%ebx
	adcl	advancetable+4,%esi
	decl	jumptemp
	stosb
	jnz		LSpan16NoRowCrossLoopB
#elif defined(ASM486_SPAN16_WORD_STORES)
	movb	(%esi),%al
	addl	%ebp,%ebx
	adcl	advancetable+4,%esi
	movb	(%esi),%ah
	addl	%ebp,%ebx
	adcl	advancetable+4,%esi
	SPAN16_STORE_WORD(9)

	movb	(%esi),%al
	addl	%ebp,%ebx
	adcl	advancetable+4,%esi
	movb	(%esi),%ah
	addl	%ebp,%ebx
	adcl	advancetable+4,%esi
	SPAN16_STORE_WORD(11)

	movb	(%esi),%al
	addl	%ebp,%ebx
	adcl	advancetable+4,%esi
	movb	(%esi),%ah
	addl	%ebp,%ebx
	adcl	advancetable+4,%esi
	SPAN16_STORE_WORD(13)

	movb	(%esi),%al
	addl	%ebp,%ebx
	adcl	advancetable+4,%esi

#elif defined(ASM486_SPAN16_DWORD_STORES)
	movb	(%esi),%al
	addl	%ebp,%ebx
	adcl	advancetable+4,%esi
	movb	(%esi),%ah
	addl	%ebp,%ebx
	adcl	advancetable+4,%esi
	rorl	$16,%eax
	movb	(%esi),%al
	addl	%ebp,%ebx
	adcl	advancetable+4,%esi
	movb	(%esi),%ah
	rorl	$16,%eax
	movl	%eax,8(%edi)
	addl	%ebp,%ebx
	adcl	advancetable+4,%esi

	movb	(%esi),%al
	addl	%ebp,%ebx
	adcl	advancetable+4,%esi
	movb	(%esi),%ah
	addl	%ebp,%ebx
	adcl	advancetable+4,%esi
	rorl	$16,%eax
	movb	(%esi),%al
	addl	%ebp,%ebx
	adcl	advancetable+4,%esi
	movb	(%esi),%ah
	rorl	$16,%eax
	movl	%eax,12(%edi)
	addl	%ebp,%ebx
	adcl	advancetable+4,%esi
	shrl	$24,%eax

#else
	movb	%al,8(%edi)
	addl	%ebp,%ebx
	movb	(%esi),%al
	adcl	advancetable+4,%esi

	movb	%al,9(%edi)
	addl	%ebp,%ebx
	movb	(%esi),%al
	adcl	advancetable+4,%esi

	movb	%al,10(%edi)
	addl	%ebp,%ebx
	movb	(%esi),%al
	adcl	advancetable+4,%esi

	movb	%al,11(%edi)
	addl	%ebp,%ebx
	movb	(%esi),%al
	adcl	advancetable+4,%esi

	movb	%al,12(%edi)
	addl	%ebp,%ebx
	movb	(%esi),%al
	adcl	advancetable+4,%esi

	movb	%al,13(%edi)
	addl	%ebp,%ebx
	movb	(%esi),%al
	adcl	advancetable+4,%esi

	movb	%al,14(%edi)
	addl	%ebp,%ebx
	movb	(%esi),%al
	adcl	advancetable+4,%esi
#endif
	jmp		LSpan16AfterStoresB

LSpan16ControlStoresB:
#endif
#ifdef ASM486_SPAN16_LOOP_STOSB
	movl	$8,jumptemp
LSpan16LoopB:
	addl	tstep,%edx
	sbbl	%ecx,%ecx
	addl	%ebp,%ebx
	movb	(%esi),%al
	adcl	advancetable+4(,%ecx,4),%esi
	decl	jumptemp
	stosb
	jnz		LSpan16LoopB
#elif defined(ASM486_SPAN16_WORD_STORES)
#ifdef ASM486_SPAN16_LOAD_FIRST
	movb	(%esi),%al
	addl	tstep,%edx
	sbbl	%ecx,%ecx
	addl	%ebp,%ebx
	adcl	advancetable+4(,%ecx,4),%esi

	movb	(%esi),%ah
	addl	tstep,%edx
	sbbl	%ecx,%ecx
	addl	%ebp,%ebx
	adcl	advancetable+4(,%ecx,4),%esi
	SPAN16_STORE_WORD(9)

	movb	(%esi),%al
	addl	tstep,%edx
	sbbl	%ecx,%ecx
	addl	%ebp,%ebx
	adcl	advancetable+4(,%ecx,4),%esi

	movb	(%esi),%ah
	addl	tstep,%edx
	sbbl	%ecx,%ecx
	addl	%ebp,%ebx
	adcl	advancetable+4(,%ecx,4),%esi
	SPAN16_STORE_WORD(11)

	movb	(%esi),%al
	addl	tstep,%edx
	sbbl	%ecx,%ecx
	addl	%ebp,%ebx
	adcl	advancetable+4(,%ecx,4),%esi

	movb	(%esi),%ah
	addl	tstep,%edx
	sbbl	%ecx,%ecx
	addl	%ebp,%ebx
	adcl	advancetable+4(,%ecx,4),%esi
	SPAN16_STORE_WORD(13)

	movb	(%esi),%al
	addl	tstep,%edx
	sbbl	%ecx,%ecx
	addl	%ebp,%ebx
	adcl	advancetable+4(,%ecx,4),%esi
#else
	addl	tstep,%edx
	movb	(%esi),%al
	sbbl	%ecx,%ecx
	addl	%ebp,%ebx
	adcl	advancetable+4(,%ecx,4),%esi

	addl	tstep,%edx
	sbbl	%ecx,%ecx
	addl	%ebp,%ebx
	movb	(%esi),%ah
	adcl	advancetable+4(,%ecx,4),%esi
	SPAN16_STORE_WORD(9)

	addl	tstep,%edx
	movb	(%esi),%al
	sbbl	%ecx,%ecx
	addl	%ebp,%ebx
	adcl	advancetable+4(,%ecx,4),%esi

	addl	tstep,%edx
	sbbl	%ecx,%ecx
	addl	%ebp,%ebx
	movb	(%esi),%ah
	adcl	advancetable+4(,%ecx,4),%esi
	SPAN16_STORE_WORD(11)

	addl	tstep,%edx
	movb	(%esi),%al
	sbbl	%ecx,%ecx
	addl	%ebp,%ebx
	adcl	advancetable+4(,%ecx,4),%esi

	addl	tstep,%edx
	sbbl	%ecx,%ecx
	addl	%ebp,%ebx
	movb	(%esi),%ah
	adcl	advancetable+4(,%ecx,4),%esi
	SPAN16_STORE_WORD(13)

	addl	tstep,%edx
	movb	(%esi),%al
	sbbl	%ecx,%ecx
	addl	%ebp,%ebx
	adcl	advancetable+4(,%ecx,4),%esi
#endif

#endif

LSpan16AfterStoresB:

#ifdef ASM486_SPAN16_WORD_STOS
	movb	%al,(%edi)
	incl	%edi
#elif !defined(ASM486_SPAN16_LOOP_STOSB)
	addl	$16,%edi
#endif
	movl	%edx,tfracf
	movl	snext,%edx
	movl	%ebx,sfracf
	movl	tnext,%ebx
	movl	%edx,s
	movl	%ebx,t

//
// determine whether last span or not
//
	cmpl	$16,counttemp		// are there multiple segments remaining?
#ifndef ASM486_SPAN16_WORD_STOS
	movb	%al,-1(%edi)
#endif
	ja		LNotLastSegment		// yes
	movl	counttemp,%ecx		// retrieve count for the final segment

//
// last segment of scan
//
LLastSegment:

//
// advance s/z, t/z, and 1/z, and calculate s & t at end of span and steps to
// get there. The number of pixels left is variable, and we want to land on the
// last pixel, not step one past it, so we can't run into arithmetic problems
//
	testl	%ecx,%ecx
	jz		LNoSteps		// just draw the last pixel and we're done

#ifdef ASM486_SPAN16_TAIL_WORD_STORES
	// Preserve the number of samples after the first; LSetEntryvec uses ECX
	// as its texture-address carry scratch register.
	movl	%ecx,counttemp
#endif

// pick up after the FDIV that was left in flight previously


	fld		%st(0)			// duplicate it
	fmul	%st(4),%st(0)	// s = s/z * z
	fistpl	snext
	fmul	%st(2),%st(0)	// t = t/z * z after the S pop
	fistpl	tnext

	movb	(%esi),%al		// load first texel in segment
	movl	C(tadjust),%ebx
	movb	%al,(%edi)		// store first pixel in segment
	movl	C(sadjust),%eax

	addl	snext,%eax
	addl	tnext,%ebx

	cmpl	$4096,%eax
	jl		LClampLow4
	cmpl	C(bbextents),%eax
	ja		LClampHigh4
LClampReentry4:
	movl	%eax,snext

	cmpl	$4096,%ebx
	jl		LClampLow5
	cmpl	C(bbextentt),%ebx
	ja		LClampHigh5
LClampReentry5:

	cmpl	$1,%ecx			// don't bother 
	je		LOnlyOneStep	// if two pixels in segment, there's only one step,
							//  of the segment length
	subl	s,%eax
	subl	t,%ebx

#ifdef PROFILE486
	cmpl	$0,C(bench486_profile_frame_active)
	jz		LProfileFinalStatsDone
	testl	%ebx,%ebx
	jnz		LProfileFinalStatsDone
	leal	-1(%ecx),%edx
	shll	$16,%edx
	cmpl	%edx,%eax
	jne		LProfileFinalStatsDone
	incl	C(bench486_texture_final_exact)
LProfileFinalStatsDone:
#endif

	addl	%eax,%eax		// convert to 15.17 format so multiply by 1.31
	addl	%ebx,%ebx		//  reciprocal yields 16.48

	imull	reciprocal_table_16-8(,%ecx,4)	// sstep = (snext - s) /
											//  (spancount-1)
	movl	%edx,%ebp

	movl	%ebx,%eax
	imull	reciprocal_table_16-8(,%ecx,4)	// tstep = (tnext - t) /
											//  (spancount-1)
LSetEntryvec:
//
// set up advancetable
//
	movl	entryvec_table_16(,%ecx,4),%ebx
	movl	%edx,%eax
	movl	%ebx,jumptemp		// entry point into code for RET later
	movl	%ebp,%ecx
	sarl	$16,%edx			// tstep >>= 16;
	movl	C(cachewidth),%ebx
	sarl	$16,%ecx			// sstep >>= 16;
	imull	%ebx,%edx

	addl	%ecx,%edx			// add in sstep
								// (tstep >> 16) * cachewidth + (sstep >> 16);
	movl	tfracf,%ecx
	movl	%edx,advancetable+4	// advance base in t
	addl	%ebx,%edx			// ((tstep >> 16) + 1) * cachewidth +
								//  (sstep >> 16);
	shll	$16,%ebp			// left-justify sstep fractional part
	movl	sfracf,%ebx
	shll	$16,%eax			// left-justify tstep fractional part
	movl	%edx,advancetable	// advance extra in t

	movl	%eax,tstep
	movl	%ecx,%edx
	addl	%eax,%edx
	sbbl	%ecx,%ecx
	addl	%ebp,%ebx
	adcl	advancetable+4(,%ecx,4),%esi

#ifdef ASM486_SPAN16_TAIL_WORD_STORES
	jmp		LSpan16TailWordStores
#else
	jmp		*jumptemp			// jump to the number-of-pixels handler
#endif

//----------------------------------------

#ifdef ASM486_SPAN16_TAIL_WORD_STORES
// The first texel of a final segment was stored before LSetEntryvec.  Pack
// adjacent remaining texels into 16-bit stores while retaining the original
// per-sample DDA order.  Leave the last texel unadvanced, matching the
// existing entry-vector handlers.
LSpan16TailWordStores:
	movl	counttemp,%eax
	decl	%eax				// samples before the final sample
	movl	%eax,%ecx
	andl	$1,%ecx
	movl	%ecx,counttemp		// odd pre-final sample flag
	shrl	$1,%eax
	movl	%eax,jumptemp		// number of pre-final word pairs
	leal	1(%edi),%edi			// destination for sample two
	testl	%eax,%eax
	jz		LSpan16TailWordOdd

LSpan16TailWordPairLoop:
	movb	(%esi),%al
	addl	tstep,%edx
	sbbl	%ecx,%ecx
	addl	%ebp,%ebx
	adcl	advancetable+4(,%ecx,4),%esi
	movb	(%esi),%ah
	addl	tstep,%edx
	sbbl	%ecx,%ecx
	addl	%ebp,%ebx
	adcl	advancetable+4(,%ecx,4),%esi
	movw	%ax,(%edi)
	addl	$2,%edi
	decl	jumptemp
	jnz		LSpan16TailWordPairLoop

LSpan16TailWordOdd:
	cmpl	$0,counttemp
	jz		LSpan16TailWordFinal
	movb	(%esi),%al
	addl	tstep,%edx
	sbbl	%ecx,%ecx
	addl	%ebp,%ebx
	adcl	advancetable+4(,%ecx,4),%esi
	movb	%al,(%edi)
	incl	%edi

LSpan16TailWordFinal:
	movb	(%esi),%al
	movb	%al,(%edi)
	jmp		LEndSpan
#endif

LNoSteps:
	movb	(%esi),%al		// load first texel in segment
	subl	$15,%edi			// adjust for hardwired offset
	jmp		LEndSpanStore


LOnlyOneStep:
	subl	s,%eax
	subl	t,%ebx
	movl	%eax,%ebp
	movl	%ebx,%edx
	jmp		LSetEntryvec

//----------------------------------------

.globl	Entry2_16, Entry3_16, Entry4_16, Entry5_16
.globl	Entry6_16, Entry7_16, Entry8_16, Entry9_16
.globl	Entry10_16, Entry11_16, Entry12_16, Entry13_16
.globl	Entry14_16, Entry15_16, Entry16_16

Entry2_16:
	subl	$14,%edi		// adjust for hardwired offsets
	movb	(%esi),%al
	jmp		LEntry2_16

//----------------------------------------

Entry3_16:
	subl	$13,%edi		// adjust for hardwired offsets
	addl	%eax,%edx
	movb	(%esi),%al
	sbbl	%ecx,%ecx
	addl	%ebp,%ebx
	adcl	advancetable+4(,%ecx,4),%esi
	jmp		LEntry3_16

//----------------------------------------

Entry4_16:
	subl	$12,%edi		// adjust for hardwired offsets
	addl	%eax,%edx
	movb	(%esi),%al
	sbbl	%ecx,%ecx
	addl	%ebp,%ebx
	adcl	advancetable+4(,%ecx,4),%esi
	addl	tstep,%edx
	jmp		LEntry4_16

//----------------------------------------

Entry5_16:
	subl	$11,%edi		// adjust for hardwired offsets
	addl	%eax,%edx
	movb	(%esi),%al
	sbbl	%ecx,%ecx
	addl	%ebp,%ebx
	adcl	advancetable+4(,%ecx,4),%esi
	addl	tstep,%edx
	jmp		LEntry5_16

//----------------------------------------

Entry6_16:
	subl	$10,%edi		// adjust for hardwired offsets
	addl	%eax,%edx
	movb	(%esi),%al
	sbbl	%ecx,%ecx
	addl	%ebp,%ebx
	adcl	advancetable+4(,%ecx,4),%esi
	addl	tstep,%edx
	jmp		LEntry6_16

//----------------------------------------

Entry7_16:
	subl	$9,%edi		// adjust for hardwired offsets
	addl	%eax,%edx
	movb	(%esi),%al
	sbbl	%ecx,%ecx
	addl	%ebp,%ebx
	adcl	advancetable+4(,%ecx,4),%esi
	addl	tstep,%edx
	jmp		LEntry7_16

//----------------------------------------

Entry8_16:
	subl	$8,%edi		// adjust for hardwired offsets
	addl	%eax,%edx
	movb	(%esi),%al
	sbbl	%ecx,%ecx
	addl	%ebp,%ebx
	adcl	advancetable+4(,%ecx,4),%esi
	addl	tstep,%edx
	jmp		LEntry8_16

//----------------------------------------

Entry9_16:
	subl	$7,%edi		// adjust for hardwired offsets
	addl	%eax,%edx
	movb	(%esi),%al
	sbbl	%ecx,%ecx
	addl	%ebp,%ebx
	adcl	advancetable+4(,%ecx,4),%esi
	addl	tstep,%edx
	jmp		LEntry9_16

//----------------------------------------

Entry10_16:
	subl	$6,%edi		// adjust for hardwired offsets
	addl	%eax,%edx
	movb	(%esi),%al
	sbbl	%ecx,%ecx
	addl	%ebp,%ebx
	adcl	advancetable+4(,%ecx,4),%esi
	addl	tstep,%edx
	jmp		LEntry10_16

//----------------------------------------

Entry11_16:
	subl	$5,%edi		// adjust for hardwired offsets
	addl	%eax,%edx
	movb	(%esi),%al
	sbbl	%ecx,%ecx
	addl	%ebp,%ebx
	adcl	advancetable+4(,%ecx,4),%esi
	addl	tstep,%edx
	jmp		LEntry11_16

//----------------------------------------

Entry12_16:
	subl	$4,%edi		// adjust for hardwired offsets
	addl	%eax,%edx
	movb	(%esi),%al
	sbbl	%ecx,%ecx
	addl	%ebp,%ebx
	adcl	advancetable+4(,%ecx,4),%esi
	addl	tstep,%edx
	jmp		LEntry12_16

//----------------------------------------

Entry13_16:
	subl	$3,%edi		// adjust for hardwired offsets
	addl	%eax,%edx
	movb	(%esi),%al
	sbbl	%ecx,%ecx
	addl	%ebp,%ebx
	adcl	advancetable+4(,%ecx,4),%esi
	addl	tstep,%edx
	jmp		LEntry13_16

//----------------------------------------

Entry14_16:
	subl	$2,%edi		// adjust for hardwired offsets
	addl	%eax,%edx
	movb	(%esi),%al
	sbbl	%ecx,%ecx
	addl	%ebp,%ebx
	adcl	advancetable+4(,%ecx,4),%esi
	addl	tstep,%edx
	jmp		LEntry14_16

//----------------------------------------

Entry15_16:
	decl	%edi		// adjust for hardwired offsets
	addl	%eax,%edx
	movb	(%esi),%al
	sbbl	%ecx,%ecx
	addl	%ebp,%ebx
	adcl	advancetable+4(,%ecx,4),%esi
	addl	tstep,%edx
	jmp		LEntry15_16

//----------------------------------------

Entry16_16:
	addl	%eax,%edx
	movb	(%esi),%al
	sbbl	%ecx,%ecx
	addl	%ebp,%ebx
	adcl	advancetable+4(,%ecx,4),%esi

	addl	tstep,%edx
	sbbl	%ecx,%ecx
	movb	%al,1(%edi)
	addl	%ebp,%ebx
	movb	(%esi),%al
	adcl	advancetable+4(,%ecx,4),%esi
	addl	tstep,%edx
LEntry15_16:
	sbbl	%ecx,%ecx
	movb	%al,2(%edi)
	addl	%ebp,%ebx
	movb	(%esi),%al
	adcl	advancetable+4(,%ecx,4),%esi
	addl	tstep,%edx
LEntry14_16:
	sbbl	%ecx,%ecx
	movb	%al,3(%edi)
	addl	%ebp,%ebx
	movb	(%esi),%al
	adcl	advancetable+4(,%ecx,4),%esi
	addl	tstep,%edx
LEntry13_16:
	sbbl	%ecx,%ecx
	movb	%al,4(%edi)
	addl	%ebp,%ebx
	movb	(%esi),%al
	adcl	advancetable+4(,%ecx,4),%esi
	addl	tstep,%edx
LEntry12_16:
	sbbl	%ecx,%ecx
	movb	%al,5(%edi)
	addl	%ebp,%ebx
	movb	(%esi),%al
	adcl	advancetable+4(,%ecx,4),%esi
	addl	tstep,%edx
LEntry11_16:
	sbbl	%ecx,%ecx
	movb	%al,6(%edi)
	addl	%ebp,%ebx
	movb	(%esi),%al
	adcl	advancetable+4(,%ecx,4),%esi
	addl	tstep,%edx
LEntry10_16:
	sbbl	%ecx,%ecx
	movb	%al,7(%edi)
	addl	%ebp,%ebx
	movb	(%esi),%al
	adcl	advancetable+4(,%ecx,4),%esi
	addl	tstep,%edx
LEntry9_16:
	sbbl	%ecx,%ecx
	movb	%al,8(%edi)
	addl	%ebp,%ebx
	movb	(%esi),%al
	adcl	advancetable+4(,%ecx,4),%esi
	addl	tstep,%edx
LEntry8_16:
	sbbl	%ecx,%ecx
	movb	%al,9(%edi)
	addl	%ebp,%ebx
	movb	(%esi),%al
	adcl	advancetable+4(,%ecx,4),%esi
	addl	tstep,%edx
LEntry7_16:
	sbbl	%ecx,%ecx
	movb	%al,10(%edi)
	addl	%ebp,%ebx
	movb	(%esi),%al
	adcl	advancetable+4(,%ecx,4),%esi
	addl	tstep,%edx
LEntry6_16:
	sbbl	%ecx,%ecx
	movb	%al,11(%edi)
	addl	%ebp,%ebx
	movb	(%esi),%al
	adcl	advancetable+4(,%ecx,4),%esi
	addl	tstep,%edx
LEntry5_16:
	sbbl	%ecx,%ecx
	movb	%al,12(%edi)
	addl	%ebp,%ebx
	movb	(%esi),%al
	adcl	advancetable+4(,%ecx,4),%esi
	addl	tstep,%edx
LEntry4_16:
	sbbl	%ecx,%ecx
	movb	%al,13(%edi)
	addl	%ebp,%ebx
	movb	(%esi),%al
	adcl	advancetable+4(,%ecx,4),%esi
LEntry3_16:
	movb	%al,14(%edi)
	movb	(%esi),%al
LEntry2_16:

LEndSpanStore:
	movb	%al,15(%edi)

LEndSpan:

//
// clear s/z, t/z, 1/z from FP stack
//
	fstp %st(0)
	fstp %st(0)
	fstp %st(0)

	popl	%ebx					// point to the next span
	testl	%ebx,%ebx			// any more spans?
	jnz		LSpanLoop			// more spans

	popl	%ebx				// restore register variables
	popl	%esi
	popl	%edi
	popl	%ebp				// restore the caller's stack frame
	ret

#endif	// id386
