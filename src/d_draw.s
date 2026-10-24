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
// d_draw.s
// x86 assembly-language horizontal 8-bpp span-drawing code.
//

#include "asm_i386.h"
#include "quakeasm.h"
#include "asm_draw.h"
#include "d_ifacea.h"

#ifdef PROFILE486
	.extern C(bench486_zspan_pixels)
	.extern C(bench486_zspan_spans)
#endif

#if	id386

#ifdef TARGET_I386
// Z-pair packing for the i386 target.
//
// The 486 build packs two 16-bit Z values into one dword with
//
//	shldl $16,%edx,%eax		// %eax = (%eax << 16) | (%edx >> 16)
//	rorl  $16,%eax			// swap the halves back into pixel order
//
// which, given that %eax holds one depth high word and %edx holds the next
// running 1/z sample, packs the same two words as the 386 fallback below.
//
//	%eax = (%eax & 0x0000FFFF) | (%edx & 0xFFFF0000)
//
// SHLD is an i486 instruction and does not exist on a 386, so the i386 build
// computes the same value directly.  That fallback uses %esi as scratch, so
// the remaining pixel count is saved on the stack across its pair loop and
// restored for the final odd-pixel test.
//
// The two spellings must stay bit-identical; the i386 timedemo framebuffer
// checksum is what checks it, and it is why the mask goes on %eax rather than on
// the freshly loaded %edx.
//
// This is a gas .macro rather than a cpp macro because the preprocessor splices
// continuation lines before it substitutes, which would fold the body onto one
// line.
	.macro	ZPACK16
	movl	%edx,%esi		// scratch = the 1/z sample
	andl	$0xFFFF0000,%esi	// keep its high word
	andl	$0x0000FFFF,%eax	// keep the previous high word
	orl	%esi,%eax		// assemble the pixel pair
	.endm
#else
	.macro	ZPACK16
	shldl	$16,%edx,%eax
	rorl	$16,%eax
	.endm
#endif

//----------------------------------------------------------------------
// 8-bpp horizontal span drawing code for polygons, with no transparency.
//
// Assumes there is at least one span in pspans, and that every span
// contains at least one pixel
//----------------------------------------------------------------------

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
	movl	$2048,%ebp
	jmp		LClampReentry2
LClampHigh2:
	movl	C(bbextents),%ebp
	jmp		LClampReentry2

LClampLow3:
	movl	$2048,%ecx
	jmp		LClampReentry3
LClampHigh3:
	movl	C(bbextentt),%ecx
	jmp		LClampReentry3

LClampLow4:
	movl	$2048,%eax
	jmp		LClampReentry4
LClampHigh4:
	movl	C(bbextents),%eax
	jmp		LClampReentry4

LClampLow5:
	movl	$2048,%ebx
	jmp		LClampReentry5
LClampHigh5:
	movl	C(bbextentt),%ebx
	jmp		LClampReentry5


#define pspans	4+16

	.p2align 4,,15
.globl C(D_DrawSpans8)
C(D_DrawSpans8):
	pushl	%ebp				// preserve caller's stack frame
	pushl	%edi
	pushl	%esi				// preserve register variables
	pushl	%ebx

//
// set up scaled-by-8 steps, for 8-long segments; also set up cacheblock
// and span list pointers
//
// TODO: any overlap from rearranging?
	flds	C(d_sdivzstepu)
	fmuls	fp_8
	movl	C(cacheblock),%edx
	flds	C(d_tdivzstepu)
	fmuls	fp_8
	movl	pspans(%esp),%ebx	// point to the first span descriptor
	flds	C(d_zistepu)
	fmuls	fp_8
	movl	%edx,pbase			// pbase = cacheblock
	fstps	zi8stepu
	fstps	tdivz8stepu
	fstps	sdivz8stepu

LSpanLoop:
//
// set up the initial s/z, t/z, and 1/z on the FP stack, and generate the
// initial s and t values
//
// FIXME: pipeline FILD?
	fildl	espan_t_v(%ebx)
	fildl	espan_t_u(%ebx)

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
	movl	espan_t_v(%ebx),%eax
	movl	%ebx,pspantemp	// preserve spans pointer

	movl	C(tadjust),%edx
	movl	C(sadjust),%esi
	movl	C(viewspantable)(,%eax,4),%edi	// row base
	movl	espan_t_u(%ebx),%ecx
	addl	%ecx,%edi				// pdest = &pdestspan[scans->u];
	movl	espan_t_count(%ebx),%ecx

//
// now start the FDIV for the end of the span
//
	cmpl	$8,%ecx
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
// finish up the s and t calcs
	fxch	%st(1)			// z*64k | 1/z | t/z | s/z

	fld		%st(0)			// z*64k | z*64k | 1/z | t/z | s/z
	fmul	%st(4),%st(0)	// s | z*64k | 1/z | t/z | s/z
	fxch	%st(1)			// z*64k | s | 1/z | t/z | s/z
	fmul	%st(3),%st(0)	// t | s | 1/z | t/z | s/z
	fxch	%st(1)			// s | t | 1/z | t/z | s/z
	fistpl	s				// 1/z | t | t/z | s/z
	fistpl	t				// 1/z | t/z | s/z

	fadds	zi8stepu
	fxch	%st(2)
	fadds	sdivz8stepu
	fxch	%st(2)
	flds	tdivz8stepu
	faddp	%st(0),%st(2)
	flds	fp_64k
	fdiv	%st(1),%st(0)	// z = 1/1/z
							// this is what we've gone to all this trouble to
							//  overlap
LFDIVInFlight1:

	addl	s,%esi
	addl	t,%edx
	movl	C(bbextents),%ebx
	movl	C(bbextentt),%ebp
	cmpl	%ebx,%esi
	ja		LClampHighOrLow0
LClampReentry0:
	movl	%esi,s
	movl	pbase,%ebx
	shll	$16,%esi
	cmpl	%ebp,%edx
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
	movl	C(cachewidth),%edx
	imull	%edx,%eax				// (tfrac >> 16) * cachewidth
	addl	%ebx,%esi
	addl	%eax,%esi				// psource = pbase + (sfrac >> 16) +
									//           ((tfrac >> 16) * cachewidth);

//
// determine whether last span or not
//
	cmpl	$8,%ecx
	jna		LLastSegment

//
// not the last segment; do full 8-wide segment
//
LNotLastSegment:

//
// advance s/z, t/z, and 1/z, and calculate s & t at end of span and steps to
// get there
//

// pick up after the FDIV that was left in flight previously

	fld		%st(0)			// duplicate it
	fmul	%st(4),%st(0)	// s = s/z * z
	fxch	%st(1)
	fmul	%st(3),%st(0)	// t = t/z * z
	fxch	%st(1)
	fistpl	snext
	fistpl	tnext
	movl	snext,%eax
	movl	tnext,%edx

	movb	(%esi),%bl	// get first source texel
	subl	$8,%ecx		// count off this segments' pixels
	movl	C(sadjust),%ebp
	movl	%ecx,counttemp	// remember count of remaining pixels

	movl	C(tadjust),%ecx
	movb	%bl,(%edi)	// store first dest pixel

	addl	%eax,%ebp
	addl	%edx,%ecx

	movl	C(bbextents),%eax
	movl	C(bbextentt),%edx

	cmpl	$2048,%ebp
	jl		LClampLow2
	cmpl	%eax,%ebp
	ja		LClampHigh2
LClampReentry2:

	cmpl	$2048,%ecx
	jl		LClampLow3
	cmpl	%edx,%ecx
	ja		LClampHigh3
LClampReentry3:

	movl	%ebp,snext
	movl	%ecx,tnext

	subl	s,%ebp
	subl	t,%ecx
	
//
// set up advancetable
//
	movl	%ecx,%eax
	movl	%ebp,%edx
	sarl	$19,%eax			// tstep >>= 16;
	jz		LZero
	sarl	$19,%edx			// sstep >>= 16;
	movl	C(cachewidth),%ebx
	imull	%ebx,%eax
	jmp		LSetUp1

LZero:
	sarl	$19,%edx			// sstep >>= 16;
	movl	C(cachewidth),%ebx

LSetUp1:

	addl	%edx,%eax			// add in sstep
								// (tstep >> 16) * cachewidth + (sstep >> 16);
	movl	tfracf,%edx
	movl	%eax,advancetable+4	// advance base in t
	addl	%ebx,%eax			// ((tstep >> 16) + 1) * cachewidth +
								//  (sstep >> 16);
	shll	$13,%ebp			// left-justify sstep fractional part
	movl	sfracf,%ebx
	shll	$13,%ecx			// left-justify tstep fractional part
	movl	%eax,advancetable	// advance extra in t

	movl	%ecx,tstep
	addl	%ecx,%edx			// advance tfrac fractional part by tstep frac

	sbbl	%ecx,%ecx			// turn tstep carry into -1 (0 if none)
	addl	%ebp,%ebx			// advance sfrac fractional part by sstep frac
	adcl	advancetable+4(,%ecx,4),%esi	// point to next source texel

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


//
// start FDIV for end of next segment in flight, so it can overlap
//
	movl	counttemp,%ecx
	cmpl	$8,%ecx			// more than one segment after this?
	ja		LSetupNotLast2	// yes

	decl	%ecx
	jz		LFDIVInFlight2	// if only one pixel, no need to start an FDIV
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
	fadds	zi8stepu
	fxch	%st(2)
	fadds	sdivz8stepu
	fxch	%st(2)
	flds	tdivz8stepu
	faddp	%st(0),%st(2)
	flds	fp_64k
	fdiv	%st(1),%st(0)	// z = 1/1/z
							// this is what we've gone to all this trouble to
							//  overlap
LFDIVInFlight2:
	movl	%ecx,counttemp

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

	addl	$8,%edi
	movl	%edx,tfracf
	movl	snext,%edx
	movl	%ebx,sfracf
	movl	tnext,%ebx
	movl	%edx,s
	movl	%ebx,t

	movl	counttemp,%ecx		// retrieve count

//
// determine whether last span or not
//
	cmpl	$8,%ecx				// are there multiple segments remaining?
	movb	%al,-1(%edi)
	ja		LNotLastSegment		// yes

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

// pick up after the FDIV that was left in flight previously


	fld		%st(0)			// duplicate it
	fmul	%st(4),%st(0)	// s = s/z * z
	fxch	%st(1)
	fmul	%st(3),%st(0)	// t = t/z * z
	fxch	%st(1)
	fistpl	snext
	fistpl	tnext

	movb	(%esi),%al		// load first texel in segment
	movl	C(tadjust),%ebx
	movb	%al,(%edi)		// store first pixel in segment
	movl	C(sadjust),%eax

	addl	snext,%eax
	addl	tnext,%ebx

	movl	C(bbextents),%ebp
	movl	C(bbextentt),%edx

	cmpl	$2048,%eax
	jl		LClampLow4
	cmpl	%ebp,%eax
	ja		LClampHigh4
LClampReentry4:
	movl	%eax,snext

	cmpl	$2048,%ebx
	jl		LClampLow5
	cmpl	%edx,%ebx
	ja		LClampHigh5
LClampReentry5:

	cmpl	$1,%ecx			// don't bother 
	je		LOnlyOneStep	// if two pixels in segment, there's only one step,
							//  of the segment length
	subl	s,%eax
	subl	t,%ebx

	addl	%eax,%eax		// convert to 15.17 format so multiply by 1.31
	addl	%ebx,%ebx		//  reciprocal yields 16.48

	imull	reciprocal_table-8(,%ecx,4) // sstep = (snext - s) / (spancount-1)
	movl	%edx,%ebp

	movl	%ebx,%eax
	imull	reciprocal_table-8(,%ecx,4) // tstep = (tnext - t) / (spancount-1)

LSetEntryvec:
//
// set up advancetable
//
	movl	entryvec_table(,%ecx,4),%ebx
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

	jmp		*jumptemp			// jump to the number-of-pixels handler

//----------------------------------------

LNoSteps:
	movb	(%esi),%al		// load first texel in segment
	subl	$7,%edi			// adjust for hardwired offset
	jmp		LEndSpan


LOnlyOneStep:
	subl	s,%eax
	subl	t,%ebx
	movl	%eax,%ebp
	movl	%ebx,%edx
	jmp		LSetEntryvec

//----------------------------------------

.globl	Entry2_8
Entry2_8:
	subl	$6,%edi		// adjust for hardwired offsets
	movb	(%esi),%al
	jmp		LLEntry2_8

//----------------------------------------

.globl	Entry3_8
Entry3_8:
	subl	$5,%edi		// adjust for hardwired offsets
	addl	%eax,%edx
	movb	(%esi),%al
	sbbl	%ecx,%ecx
	addl	%ebp,%ebx
	adcl	advancetable+4(,%ecx,4),%esi
	jmp		LLEntry3_8

//----------------------------------------

.globl	Entry4_8
Entry4_8:
	subl	$4,%edi		// adjust for hardwired offsets
	addl	%eax,%edx
	movb	(%esi),%al
	sbbl	%ecx,%ecx
	addl	%ebp,%ebx
	adcl	advancetable+4(,%ecx,4),%esi
	addl	tstep,%edx
	jmp		LLEntry4_8

//----------------------------------------

.globl	Entry5_8
Entry5_8:
	subl	$3,%edi		// adjust for hardwired offsets
	addl	%eax,%edx
	movb	(%esi),%al
	sbbl	%ecx,%ecx
	addl	%ebp,%ebx
	adcl	advancetable+4(,%ecx,4),%esi
	addl	tstep,%edx
	jmp		LLEntry5_8

//----------------------------------------

.globl	Entry6_8
Entry6_8:
	subl	$2,%edi		// adjust for hardwired offsets
	addl	%eax,%edx
	movb	(%esi),%al
	sbbl	%ecx,%ecx
	addl	%ebp,%ebx
	adcl	advancetable+4(,%ecx,4),%esi
	addl	tstep,%edx
	jmp		LLEntry6_8

//----------------------------------------

.globl	Entry7_8
Entry7_8:
	decl	%edi		// adjust for hardwired offsets
	addl	%eax,%edx
	movb	(%esi),%al
	sbbl	%ecx,%ecx
	addl	%ebp,%ebx
	adcl	advancetable+4(,%ecx,4),%esi
	addl	tstep,%edx
	jmp		LLEntry7_8

//----------------------------------------

.globl	Entry8_8
Entry8_8:
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
LLEntry7_8:
	sbbl	%ecx,%ecx
	movb	%al,2(%edi)
	addl	%ebp,%ebx
	movb	(%esi),%al
	adcl	advancetable+4(,%ecx,4),%esi
	addl	tstep,%edx
LLEntry6_8:
	sbbl	%ecx,%ecx
	movb	%al,3(%edi)
	addl	%ebp,%ebx
	movb	(%esi),%al
	adcl	advancetable+4(,%ecx,4),%esi
	addl	tstep,%edx
LLEntry5_8:
	sbbl	%ecx,%ecx
	movb	%al,4(%edi)
	addl	%ebp,%ebx
	movb	(%esi),%al
	adcl	advancetable+4(,%ecx,4),%esi
	addl	tstep,%edx
LLEntry4_8:
	sbbl	%ecx,%ecx
	movb	%al,5(%edi)
	addl	%ebp,%ebx
	movb	(%esi),%al
	adcl	advancetable+4(,%ecx,4),%esi
LLEntry3_8:
	movb	%al,6(%edi)
	movb	(%esi),%al
LLEntry2_8:

LEndSpan:

//
// clear s/z, t/z, 1/z from FP stack
//
	fstp %st(0)
	fstp %st(0)
	fstp %st(0)

	movl	pspantemp,%ebx				// restore spans pointer
	movl	espan_t_pnext(%ebx),%ebx	// point to next span
	testl	%ebx,%ebx			// any more spans?
	movb	%al,7(%edi)
	jnz		LSpanLoop			// more spans

	popl	%ebx				// restore register variables
	popl	%esi
	popl	%edi
	popl	%ebp				// restore the caller's stack frame
	ret

//----------------------------------------------------------------------
// 8-bpp horizontal span z drawing codefor polygons, with no transparency.
// Row addresses come from zspantable (filled in D_VidStart) instead of
// IMUL d_zrowbytes.  The C D_DrawZSpans path remains the multiply reference.
//
// Assumes there is at least one span in pzspans, and that every span
// contains at least one pixel
//----------------------------------------------------------------------

	.text

// z-clamp on a non-negative gradient span
LClamp:
	movl	$0x40000000,%edx
	xorl	%ebx,%ebx
	fstp	%st(0)
	jmp		LZDraw

// z-clamp on a negative gradient span
LClampNeg:
	movl	$0x40000000,%edx
	xorl	%ebx,%ebx
	fstp	%st(0)
	jmp		LZDrawNeg


#define pzspans	4+20

	.macro ZSPAN_ADD_PAIR negative_label
	movl	%edx,%eax
	js	\negative_label
	addl	%ebx,%edx
	shrl	$16,%eax
	ZPACK16
	addl	%ebx,%edx
	movl	%eax,(%edi)
	leal	4(%edi),%edi
	.endm

	.macro ZSPAN_ADD_PAIR_NONNEGATIVE
	movl	%edx,%eax
	addl	%ebx,%edx
	shrl	$16,%eax
	ZPACK16
	addl	%ebx,%edx
	movl	%eax,(%edi)
	leal	4(%edi),%edi
	.endm

	.macro ZSPAN_ADD_NEGATIVE_PAIR next_label
	addl	%ebx,%edx
	shrl	$16,%eax
	ZPACK16
	orl	$0xffff0000,%eax
	addl	%ebx,%edx
	movl	%eax,(%edi)
	leal	4(%edi),%edi
	jmp	\next_label
	.endm

	.macro ZSPAN_SUB_PAIR negative_label
	movl	%edx,%eax
	js	\negative_label
	subl	%ebx,%edx
	shrl	$16,%eax
	ZPACK16
	subl	%ebx,%edx
	movl	%eax,(%edi)
	leal	4(%edi),%edi
	.endm

	.macro ZSPAN_SUB_NEGATIVE_PAIR next_label
	subl	%ebx,%edx
	shrl	$16,%eax
	ZPACK16
	orl	$0xffff0000,%eax
	subl	%ebx,%edx
	movl	%eax,(%edi)
	leal	4(%edi),%edi
	jmp	\next_label
	.endm

.globl C(D_DrawZSpans)
C(D_DrawZSpans):
	pushl	%ebp				// preserve caller's stack frame
	pushl	%edi
	pushl	%esi				// preserve register variables
	pushl	%ebx
	subl	$4,%esp			// local saved and truncate-mode x87 control words
	fnstcw	0(%esp)
	movw	0(%esp),%ax
	orw	$0x0c00,%ax			// C float-to-int casts truncate toward zero
	movw	%ax,2(%esp)

	flds	C(d_zistepu)
	movl	C(d_zistepu),%eax
	movl	pzspans(%esp),%ebp
	testl	%eax,%eax
	jz		LFNegSpan

	fmuls	Float2ToThe31nd
	fldcw	2(%esp)
	fistpl	izistep		// note: we are relying on FP exceptions being turned
						// off here to avoid range problems
	fldcw	0(%esp)
	movl	izistep,%ebx	// remains loaded for all spans
	testl	%ebx,%ebx
	jz		LZeroStepSpanLoop

LFSpanLoop:
// set up the initial 1/z value
	fildl	espan_t_v(%ebp)
	fildl	espan_t_u(%ebp)
	movl	espan_t_v(%ebp),%ecx
	fmuls	C(d_zistepu)
	fxch	%st(1)
	movl	C(zspantable)(,%ecx,4),%edi
	fmuls	C(d_zistepv)
	fxch	%st(1)
	fadds	C(d_ziorigin)
	movl	espan_t_u(%ebp),%edx
	faddp	%st(0),%st(1)

// clamp if z is nearer than 2 (1/z > 0.5)
	fcoms	float_point5
	leal	(%edi,%edx,2),%edi
movl	espan_t_count(%ebp),%ecx
	fnstsw	%ax
	testb	$0x45,%ah
	jz		LClamp
#ifdef PROFILE486
	// Z-span population.  z-spans is 7.90% of frame and the only part of it
	// ever priced was the x87 prologue, so the per-pixel loop has never had a
	// denominator.  One accumulation at the span head, where the span's pixel
	// count is already in a register, so this is exact and costs nothing in
	// release.
	addl	%ecx,C(bench486_zspan_pixels)
	incl	C(bench486_zspan_spans)
#endif

	fmuls	Float2ToThe31nd
	fldcw	2(%esp)
	fistpl	izi			// note: we are relying on FP exceptions being turned
						// off here to avoid problems when the span is closer
						// than 1/(2**31)
	fldcw	0(%esp)
	movl	izi,%edx

// at this point:
// %ebx = izistep
// %ecx = count
// %edx = izi
// %edi = pdest
// %ebp = current span (list cursor)

LZDraw:
	#ifndef TARGET_I386
	// A nonnegative start and end prove every fixed-step sample stays
	// nonnegative. The 64-bit product avoids overflow in this test.
	testl	%edx,%edx
	js	.LZDrawGeneral
	cmpl	$18,%ecx
	jb		.LZDrawGeneral
	movl	%edx,%esi
	leal	-1(%ecx),%eax
	imull	%ebx
	addl	%esi,%eax
	adcl	$0,%edx
	testl	%edx,%edx
	jnz	.LZDrawRestoreGeneral
	testl	%eax,%eax
	js	.LZDrawRestoreGeneral
	movl	%esi,%edx
	jmp	.LZDrawNonnegative
.LZDrawRestoreGeneral:
	movl	%esi,%edx
	#endif
.LZDrawGeneral:

// do a single pixel up front, if necessary to dword align the destination
	testl	$2,%edi
	jz		LFMiddle
	movl	%edx,%eax
	addl	%ebx,%edx
	shrl	$16,%eax
	decl	%ecx
	movw	%ax,(%edi)
	addl	$2,%edi
	#ifndef TARGET_I386
	jmp		LFMiddle
.LZDrawNonnegative:
	// This copy uses the endpoint proof above to omit per-pair sign branches.
	testl	$2,%edi
	jz		.LZDrawNonnegativeMiddle
	movl	%edx,%eax
	addl	%ebx,%edx
	shrl	$16,%eax
	decl	%ecx
	movw	%ax,(%edi)
	addl	$2,%edi

.LZDrawNonnegativeMiddle:
	movl	%ecx,%esi
	shrl	$4,%ecx
	jz		.LZDrawNonnegativeGroups16Done
.LZDrawNonnegativeGroup16Loop:
	ZSPAN_ADD_PAIR_NONNEGATIVE
	ZSPAN_ADD_PAIR_NONNEGATIVE
	ZSPAN_ADD_PAIR_NONNEGATIVE
	ZSPAN_ADD_PAIR_NONNEGATIVE
	ZSPAN_ADD_PAIR_NONNEGATIVE
	ZSPAN_ADD_PAIR_NONNEGATIVE
	ZSPAN_ADD_PAIR_NONNEGATIVE
	ZSPAN_ADD_PAIR_NONNEGATIVE
	decl	%ecx
	jnz		.LZDrawNonnegativeGroup16Loop

.LZDrawNonnegativeGroups16Done:
	testl	$8,%esi
	jz		.LZDrawNonnegativeGroups8Done
	ZSPAN_ADD_PAIR_NONNEGATIVE
	ZSPAN_ADD_PAIR_NONNEGATIVE
	ZSPAN_ADD_PAIR_NONNEGATIVE
	ZSPAN_ADD_PAIR_NONNEGATIVE

.LZDrawNonnegativeGroups8Done:
	testl	$4,%esi
	jz		.LZDrawNonnegativeGroup4Done
	ZSPAN_ADD_PAIR_NONNEGATIVE
	ZSPAN_ADD_PAIR_NONNEGATIVE

.LZDrawNonnegativeGroup4Done:
	testl	$2,%esi
	jz		LFPairDone
	ZSPAN_ADD_PAIR_NONNEGATIVE
	jmp		LFPairDone
	#endif

// Keep the remaining pixel count for the odd-pixel test. The i386 packing
// fallback uses %esi as scratch; the i486 packer leaves it available.
LFMiddle:
	#ifndef TARGET_I386
	movl	%ecx,%esi
	shrl	$4,%ecx				// sixteen pixels per main-loop group
	jz	.LFMiddleGroups16Done
.LFMiddleGroup16Loop:
// The previous pair's final ADD sets the next sample's sign in SF.
	testl	%edx,%edx
.LFMiddleGroup16Pair1:
	ZSPAN_ADD_PAIR .LFMiddleGroup16NegativeFirst
.LFMiddleGroup16Pair2:
	ZSPAN_ADD_PAIR .LFMiddleGroup16NegativeSecond
.LFMiddleGroup16Pair3:
	ZSPAN_ADD_PAIR .LFMiddleGroup16NegativeThird
.LFMiddleGroup16Pair4:
	ZSPAN_ADD_PAIR .LFMiddleGroup16NegativeFourth
.LFMiddleGroup16Pair5:
	ZSPAN_ADD_PAIR .LFMiddleGroup16NegativeFifth
.LFMiddleGroup16Pair6:
	ZSPAN_ADD_PAIR .LFMiddleGroup16NegativeSixth
.LFMiddleGroup16Pair7:
	ZSPAN_ADD_PAIR .LFMiddleGroup16NegativeSeventh
.LFMiddleGroup16Pair8:
	ZSPAN_ADD_PAIR .LFMiddleGroup16NegativeEighth
.LFMiddleGroup16End:
	decl	%ecx
	jnz	.LFMiddleGroup16Loop

.LFMiddleGroups16Done:
	testl	$8,%esi
	jz	.LFMiddleGroups8Done
	testl	%edx,%edx
.LFMiddleGroup8Pair1:
	ZSPAN_ADD_PAIR .LFMiddleGroup8NegativeFirst
.LFMiddleGroup8Pair2:
	ZSPAN_ADD_PAIR .LFMiddleGroup8NegativeSecond
.LFMiddleGroup8Pair3:
	ZSPAN_ADD_PAIR .LFMiddleGroup8NegativeThird
.LFMiddleGroup8Pair4:
	ZSPAN_ADD_PAIR .LFMiddleGroup8NegativeFourth
.LFMiddleGroup8End:
.LFMiddleGroups8Done:
	// An eight-pixel group leaves at most one four-pixel chunk and one pair.
	testl	$4,%esi
	jz	.LFMiddleGroup4Done
	testl	%edx,%edx
.LFMiddleGroup4Pair1:
	ZSPAN_ADD_PAIR .LFMiddleGroup4NegativeFirst
.LFMiddleGroup4Pair2:
	ZSPAN_ADD_PAIR .LFMiddleGroup4NegativeSecond
.LFMiddleGroup4Done:
	testl	$2,%esi
	jz	LFPairDone
	testl	%edx,%edx
	ZSPAN_ADD_PAIR .LFMiddleTailNegative
	#else
	#ifdef TARGET_I386
	pushl	%ecx
	#else
	movl	%ecx,%esi
	#endif
	shrl	$1,%ecx				// aligned dword count = pixels / 2
	jz		LFPairDone
LFMiddleLoop:
	movl	%edx,%eax
	testl	%eax,%eax
	js		LFNegativeDepthPair
	addl	%ebx,%edx
	shrl	$16,%eax
	ZPACK16
	movl	%eax,(%edi)
	addl	%ebx,%edx
	addl	$4,%edi
	decl	%ecx
	jnz		LFMiddleLoop
	jmp		LFPairDone

// The C oracle's signed `izi >> 16` sign-extends before ORing in the second
// sample. For negative inverse depth, that makes the packed second word 0xffff.
// This matters for SURF_DRAWBACKGROUND, whose historical inverse depth is -0.9.
LFNegativeDepthPair:
	addl	%ebx,%edx
	shrl	$16,%eax
	ZPACK16
	orl	$0xffff0000,%eax
	movl	%eax,(%edi)
	addl	%ebx,%edx
	addl	$4,%edi
	decl	%ecx
	jnz		LFMiddleLoop
	#endif

LFPairDone:
	#ifdef TARGET_I386
	popl	%esi				// recover remaining pixels for LFLast
	#endif
LFLast:
// do the last, unaligned pixel, if there is one
	testl	$1,%esi			// is there an odd pixel left to do?
	jz		LFSpanDone		// no
	shrl	$16,%edx
	movw	%dx,(%edi)		// do the final pixel's z

LFSpanDone:
	movl	espan_t_pnext(%ebp),%ebp
	testl	%ebp,%ebp
	jnz		LFSpanLoop

	jmp		LFDone
LFNegSpan:
	fmuls	FloatMinus2ToThe31nd
	fldcw	2(%esp)
	fistpl	izistep		// note: we are relying on FP exceptions being turned
						// off here to avoid range problems
	fldcw	0(%esp)
	movl	izistep,%ebx	// remains loaded for all spans
	testl	%ebx,%ebx
	jz		LZeroStepSpanLoop

LFNegSpanLoop:
// set up the initial 1/z value
	fildl	espan_t_v(%ebp)
	fildl	espan_t_u(%ebp)
	movl	espan_t_v(%ebp),%ecx
	fmuls	C(d_zistepu)
	fxch	%st(1)
	movl	C(zspantable)(,%ecx,4),%edi
	fmuls	C(d_zistepv)
	fxch	%st(1)
	fadds	C(d_ziorigin)
	movl	espan_t_u(%ebp),%edx
	faddp	%st(0),%st(1)

// clamp if z is nearer than 2 (1/z > 0.5)
	fcoms	float_point5
	leal	(%edi,%edx,2),%edi
	movl	espan_t_count(%ebp),%ecx
	fnstsw	%ax
	testb	$0x45,%ah
	jz		LClampNeg

	fmuls	Float2ToThe31nd
	fldcw	2(%esp)
	fistpl	izi			// note: we are relying on FP exceptions being turned
						// off here to avoid problems when the span is closer
						// than 1/(2**31)
	fldcw	0(%esp)
	movl	izi,%edx

// at this point:
// %ebx = izistep
// %ecx = count
// %edx = izi
// %edi = pdest
// %ebp = current span (list cursor)

LZDrawNeg:

// do a single pixel up front, if necessary to dword align the destination
	testl	$2,%edi
	jz		LFNegMiddle
	movl	%edx,%eax
	subl	%ebx,%edx
	shrl	$16,%eax
	decl	%ecx
	movw	%ax,(%edi)
	addl	$2,%edi

// Keep the remaining count for the odd-pixel test; only the 386 fallback
// requires saving it on the stack around %esi scratch use.
LFNegMiddle:
	#ifndef TARGET_I386
	movl	%ecx,%esi
	shrl	$4,%ecx				// sixteen pixels per main-loop group
	jz	.LFNegMiddleGroups16Done
.LFNegMiddleGroup16Loop:
	testl	%edx,%edx
.LFNegMiddleGroup16Pair1:
	ZSPAN_SUB_PAIR .LFNegMiddleGroup16NegativeFirst
.LFNegMiddleGroup16Pair2:
	ZSPAN_SUB_PAIR .LFNegMiddleGroup16NegativeSecond
.LFNegMiddleGroup16Pair3:
	ZSPAN_SUB_PAIR .LFNegMiddleGroup16NegativeThird
.LFNegMiddleGroup16Pair4:
	ZSPAN_SUB_PAIR .LFNegMiddleGroup16NegativeFourth
.LFNegMiddleGroup16Pair5:
	ZSPAN_SUB_PAIR .LFNegMiddleGroup16NegativeFifth
.LFNegMiddleGroup16Pair6:
	ZSPAN_SUB_PAIR .LFNegMiddleGroup16NegativeSixth
.LFNegMiddleGroup16Pair7:
	ZSPAN_SUB_PAIR .LFNegMiddleGroup16NegativeSeventh
.LFNegMiddleGroup16Pair8:
	ZSPAN_SUB_PAIR .LFNegMiddleGroup16NegativeEighth
.LFNegMiddleGroup16End:
	decl	%ecx
	jnz	.LFNegMiddleGroup16Loop

.LFNegMiddleGroups16Done:
	testl	$8,%esi
	jz	.LFNegMiddleGroups8Done
	testl	%edx,%edx
.LFNegMiddleGroup8Pair1:
	ZSPAN_SUB_PAIR .LFNegMiddleGroup8NegativeFirst
.LFNegMiddleGroup8Pair2:
	ZSPAN_SUB_PAIR .LFNegMiddleGroup8NegativeSecond
.LFNegMiddleGroup8Pair3:
	ZSPAN_SUB_PAIR .LFNegMiddleGroup8NegativeThird
.LFNegMiddleGroup8Pair4:
	ZSPAN_SUB_PAIR .LFNegMiddleGroup8NegativeFourth
.LFNegMiddleGroup8End:
.LFNegMiddleGroups8Done:

	testl	$4,%esi
	jz	.LFNegMiddleGroup4Done
	testl	%edx,%edx
.LFNegMiddleGroup4Pair1:
	ZSPAN_SUB_PAIR .LFNegMiddleGroup4NegativeFirst
.LFNegMiddleGroup4Pair2:
	ZSPAN_SUB_PAIR .LFNegMiddleGroup4NegativeSecond
.LFNegMiddleGroup4Done:
	testl	$2,%esi
	jz	LFNegPairDone
	testl	%edx,%edx
	ZSPAN_SUB_PAIR .LFNegMiddleTailNegative
	#else
	#ifdef TARGET_I386
	pushl	%ecx
	#else
	movl	%ecx,%esi
	#endif
	shrl	$1,%ecx
	jz		LFNegPairDone
LFNegMiddleLoop:
	movl	%edx,%eax
	testl	%eax,%eax
	js		LFNegNegativeDepthPair
	subl	%ebx,%edx
	shrl	$16,%eax
	ZPACK16
	movl	%eax,(%edi)
	subl	%ebx,%edx
	addl	$4,%edi
	decl	%ecx
	jnz		LFNegMiddleLoop
	jmp		LFNegPairDone

LFNegNegativeDepthPair:
	subl	%ebx,%edx
	shrl	$16,%eax
	ZPACK16
	orl	$0xffff0000,%eax
	movl	%eax,(%edi)
	subl	%ebx,%edx
	addl	$4,%edi
	decl	%ecx
	jnz		LFNegMiddleLoop
	#endif

LFNegPairDone:
	#ifdef TARGET_I386
	popl	%esi
	#endif

LFNegLast:
// do the last, unaligned pixel, if there is one
	testl	$1,%esi			// is there an odd pixel left to do?
	jz		LFNegSpanDone	// no
	shrl	$16,%edx
	movw	%dx,(%edi)		// do the final pixel's z

LFNegSpanDone:
	movl	espan_t_pnext(%ebp),%ebp
	testl	%ebp,%ebp
	jnz		LFNegSpanLoop

// A zero fixed-point z step writes the same depth word for every pixel in
// the span.  Keep the initial-Z and clamp arithmetic above, but avoid the
// per-pixel add/subtract and packed-pair setup in the normal gradient loops.
LZeroStepSpanLoop:
	fildl	espan_t_v(%ebp)
	fildl	espan_t_u(%ebp)
	movl	espan_t_v(%ebp),%ecx
	fmuls	C(d_zistepu)
	fxch	%st(1)
	movl	C(zspantable)(,%ecx,4),%edi
	fmuls	C(d_zistepv)
	fxch	%st(1)
	fadds	C(d_ziorigin)
	movl	espan_t_u(%ebp),%edx
	faddp	%st(0),%st(1)

	fcoms	float_point5
	leal	(%edi,%edx,2),%edi
	movl	espan_t_count(%ebp),%ecx
	fnstsw	%ax
	testb	$0x45,%ah
	jz		LZeroStepClamp

	fmuls	Float2ToThe31nd
	fldcw	2(%esp)
	fistpl	izi
	fldcw	0(%esp)
	movl	izi,%edx
	jmp		LZeroStepStore

LZeroStepClamp:
	movl	$0x40000000,%edx
	fstp	%st(0)

LZeroStepStore:
	movl	%edx,%eax
	shrl	$16,%eax
	testl	%edx,%edx
	js		LZeroStepNegativeStore
	rep
	stosw
	jmp		LZeroStepDone

// Match the C pair packer's sign extension for negative background depth:
// after an optional alignment pixel, each pair is [depth-high-word, 0xffff].
LZeroStepNegativeStore:
	testl	$2,%edi
	jz		LZeroStepNegativePairs
	movl	%edx,%eax
	shrl	$16,%eax
	movw	%ax,(%edi)
	addl	$2,%edi
	decl	%ecx
LZeroStepNegativePairs:
	cmpl	$2,%ecx
	jb		LZeroStepNegativeLast
	movl	%edx,%eax
	shrl	$16,%eax
	orl	$0xffff0000,%eax
	movl	%eax,(%edi)
	addl	$4,%edi
	subl	$2,%ecx
	jmp		LZeroStepNegativePairs
LZeroStepNegativeLast:
	testl	%ecx,%ecx
	jz		LZeroStepDone
	movl	%edx,%eax
	shrl	$16,%eax
	movw	%ax,(%edi)
LZeroStepDone:

	movl	espan_t_pnext(%ebp),%ebp
	testl	%ebp,%ebp
	jnz		LZeroStepSpanLoop

	jmp		LFDone

	#ifndef TARGET_I386
.LFMiddleGroup16NegativeFirst:
	ZSPAN_ADD_NEGATIVE_PAIR .LFMiddleGroup16Pair2

.LFMiddleGroup16NegativeSecond:
	ZSPAN_ADD_NEGATIVE_PAIR .LFMiddleGroup16Pair3

.LFMiddleGroup16NegativeThird:
	ZSPAN_ADD_NEGATIVE_PAIR .LFMiddleGroup16Pair4

.LFMiddleGroup16NegativeFourth:
	ZSPAN_ADD_NEGATIVE_PAIR .LFMiddleGroup16Pair5

.LFMiddleGroup16NegativeFifth:
	ZSPAN_ADD_NEGATIVE_PAIR .LFMiddleGroup16Pair6

.LFMiddleGroup16NegativeSixth:
	ZSPAN_ADD_NEGATIVE_PAIR .LFMiddleGroup16Pair7

.LFMiddleGroup16NegativeSeventh:
	ZSPAN_ADD_NEGATIVE_PAIR .LFMiddleGroup16Pair8

.LFMiddleGroup16NegativeEighth:
	ZSPAN_ADD_NEGATIVE_PAIR .LFMiddleGroup16End

.LFMiddleGroup8NegativeFirst:
	ZSPAN_ADD_NEGATIVE_PAIR .LFMiddleGroup8Pair2

.LFMiddleGroup8NegativeSecond:
	ZSPAN_ADD_NEGATIVE_PAIR .LFMiddleGroup8Pair3

.LFMiddleGroup8NegativeThird:
	ZSPAN_ADD_NEGATIVE_PAIR .LFMiddleGroup8Pair4

.LFMiddleGroup8NegativeFourth:
	ZSPAN_ADD_NEGATIVE_PAIR .LFMiddleGroup8End

.LFMiddleGroup4NegativeFirst:
	ZSPAN_ADD_NEGATIVE_PAIR .LFMiddleGroup4Pair2

.LFMiddleGroup4NegativeSecond:
	ZSPAN_ADD_NEGATIVE_PAIR .LFMiddleGroup4Done

.LFNegMiddleGroup16NegativeFirst:
	ZSPAN_SUB_NEGATIVE_PAIR .LFNegMiddleGroup16Pair2

.LFNegMiddleGroup16NegativeSecond:
	ZSPAN_SUB_NEGATIVE_PAIR .LFNegMiddleGroup16Pair3

.LFNegMiddleGroup16NegativeThird:
	ZSPAN_SUB_NEGATIVE_PAIR .LFNegMiddleGroup16Pair4

.LFNegMiddleGroup16NegativeFourth:
	ZSPAN_SUB_NEGATIVE_PAIR .LFNegMiddleGroup16Pair5

.LFNegMiddleGroup16NegativeFifth:
	ZSPAN_SUB_NEGATIVE_PAIR .LFNegMiddleGroup16Pair6

.LFNegMiddleGroup16NegativeSixth:
	ZSPAN_SUB_NEGATIVE_PAIR .LFNegMiddleGroup16Pair7

.LFNegMiddleGroup16NegativeSeventh:
	ZSPAN_SUB_NEGATIVE_PAIR .LFNegMiddleGroup16Pair8

.LFNegMiddleGroup16NegativeEighth:
	ZSPAN_SUB_NEGATIVE_PAIR .LFNegMiddleGroup16End

.LFNegMiddleGroup8NegativeFirst:
	ZSPAN_SUB_NEGATIVE_PAIR .LFNegMiddleGroup8Pair2

.LFNegMiddleGroup8NegativeSecond:
	ZSPAN_SUB_NEGATIVE_PAIR .LFNegMiddleGroup8Pair3

.LFNegMiddleGroup8NegativeThird:
	ZSPAN_SUB_NEGATIVE_PAIR .LFNegMiddleGroup8Pair4

.LFNegMiddleGroup8NegativeFourth:
	ZSPAN_SUB_NEGATIVE_PAIR .LFNegMiddleGroup8End

.LFNegMiddleGroup4NegativeFirst:
	ZSPAN_SUB_NEGATIVE_PAIR .LFNegMiddleGroup4Pair2

.LFNegMiddleGroup4NegativeSecond:
	ZSPAN_SUB_NEGATIVE_PAIR .LFNegMiddleGroup4Done

.LFMiddleTailNegative:
	ZSPAN_ADD_NEGATIVE_PAIR LFPairDone

.LFNegMiddleTailNegative:
	ZSPAN_SUB_NEGATIVE_PAIR LFNegPairDone
	#endif

LFDone:
	fldcw	0(%esp)
	addl	$4,%esp
	popl	%ebx				// restore register variables
	popl	%esi
	popl	%edi
	popl	%ebp				// restore the caller's stack frame
	ret

#endif	// id386
