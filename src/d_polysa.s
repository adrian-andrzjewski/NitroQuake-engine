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
// d_polysa.s
// x86 assembly-language polygon model drawing code
//

#include "asm_i386.h"
#include "quakeasm.h"
#include "asm_draw.h"
#include "d_ifacea.h"

#if	id386

// !!! if this is changed, it must be changed in d_polyse.c too !!!
#define DPS_MAXSPANS			MAXHEIGHT+1	
									// 1 extra for spanpackage that marks end

//#define	SPAN_SIZE	(((DPS_MAXSPANS + 1 + ((CACHE_SIZE - 1) / spanpackage_t_size)) + 1) * spanpackage_t_size)
#define SPAN_SIZE (1024+1+1+1)*32


	.data

	.p2align 4,,15
p10_minus_p20:	.single		0
p01_minus_p21:	.single		0
temp0:			.single		0
temp1:			.single		0
Ltemp:			.single		0

aff8entryvec_table:	.long	LDraw8, LDraw7, LDraw6, LDraw5
				.long	LDraw4, LDraw3, LDraw2, LDraw1

lzistepx:		.long	0


	.text

#ifdef ASM486_ALIAS_SPAN_BRANCH_ADDRESS
// Opt-in alias-span address-update experiment.  Test the T-carry mask before
// the S update so the ADC below still consumes the S carry.  The control
// expansion is the original indexed two-entry advance-table operation.
.macro ALIAS_SPAN_ADVANCE
	testl	%eax,%eax
	jz	.LAliasSpanNoCarry\@
	addl	C(a_sstepxfrac),%ebx
	adcl	advancetable,%esi
	jmp	.LAliasSpanDone\@
.LAliasSpanNoCarry\@:
	addl	C(a_sstepxfrac),%ebx
	adcl	advancetable+4,%esi
.LAliasSpanDone\@:
.endm
#else
.macro ALIAS_SPAN_ADVANCE
	addl	C(a_sstepxfrac),%ebx
	adcl	advancetable+4(,%eax,4),%esi
.endm
#endif

	.extern C(D_PolysetSetEdgeTable)
	.extern C(edgetables)
	.extern C(pedgetable)
	.extern C(r_p0)
	.extern C(r_p1)
	.extern C(r_p2)
	.extern C(r_affinetridesc)
	.extern C(skintable)
	.extern C(skinstart)
	.extern C(skinwidth)
	.extern C(D_RasterizeAliasPolySmooth)
	.extern C(D_PolysetSetUpForLineScan_C)
	.extern C(adivtab)
	.extern C(d_xdenom_int)
	.extern C(D_PolysetSetUpForLineScan)
	.extern C(D_PolysetCalcGradients)
	.extern C(D_PolysetScanLeftEdge)
	.extern C(D_PolysetDrawSpans8)
	.extern C(pedgetable)
	.extern C(a_spans)
	.extern C(r_affinetridesc)
	.extern C(d_pedgespanpackage)
	.extern C(d_aspancount)
	.extern C(d_ptex)
	.extern C(d_sfrac)
	.extern C(d_tfrac)
	.extern C(d_light)
	.extern C(d_zi)
	.extern C(d_pdest)
	.extern C(d_pz)
	.extern C(viewspantable)
	.extern C(zspantable)
	.extern C(d_zwidth)
	.extern C(screenwidth)
	.extern C(ubasestep)
	.extern C(erroradjustup)
	.extern C(erroradjustdown)
	.extern C(errorterm)
	.extern C(d_pzbasestep)
	.extern C(d_pzextrastep)
	.extern C(d_pdestbasestep)
	.extern C(d_pdestextrastep)
	.extern C(d_countextrastep)
	.extern C(r_lstepx)
	.extern C(r_lstepy)
	.extern C(r_sstepx)
	.extern C(r_sstepy)
	.extern C(r_tstepx)
	.extern C(r_tstepy)
	.extern C(r_zistepx)
	.extern C(r_zistepy)
	.extern C(d_ptexbasestep)
	.extern C(d_sfracbasestep)
	.extern C(d_tfracbasestep)
	.extern C(d_lightbasestep)
	.extern C(d_zibasestep)
	.extern C(d_ptexextrastep)
	.extern C(d_sfracextrastep)
	.extern C(d_tfracextrastep)
	.extern C(d_lightextrastep)
	.extern C(d_ziextrastep)
#ifdef PROFILE486
	.extern C(D_PolysetCalcGradientsProfiled)
	.extern C(D_PolysetScanLeftEdgeProfiled)
	.extern C(D_PolysetDrawSpansProfiled)
#endif

//----------------------------------------------------------------------
// affine triangle gradient calculation code
//----------------------------------------------------------------------

#define skinwidth	4+0

.globl C(D_PolysetCalcGradients_asm486)
C(D_PolysetCalcGradients_asm486):

//	p00_minus_p20 = r_p0[0] - r_p2[0];
//	p01_minus_p21 = r_p0[1] - r_p2[1];
//	p10_minus_p20 = r_p1[0] - r_p2[0];
//	p11_minus_p21 = r_p1[1] - r_p2[1];
//
//	xstepdenominv = 1.0 / (p10_minus_p20 * p01_minus_p21 -
//			     p00_minus_p20 * p11_minus_p21);
//
//	ystepdenominv = -xstepdenominv;

	fildl	C(r_p0)+0		// r_p0[0]
	fildl	C(r_p2)+0		// r_p2[0] | r_p0[0]
	fildl	C(r_p0)+4		// r_p0[1] | r_p2[0] | r_p0[0]
	fildl	C(r_p2)+4		// r_p2[1] | r_p0[1] | r_p2[0] | r_p0[0]
	fildl	C(r_p1)+0		// r_p1[0] | r_p2[1] | r_p0[1] | r_p2[0] | r_p0[0]
	fildl	C(r_p1)+4		// r_p1[1] | r_p1[0] | r_p2[1] | r_p0[1] |
							//  r_p2[0] | r_p0[0]
	fxch	%st(3)			// r_p0[1] | r_p1[0] | r_p2[1] | r_p1[1] |
							//  r_p2[0] | r_p0[0]
	fsub	%st(2),%st(0)	// p01_minus_p21 | r_p1[0] | r_p2[1] | r_p1[1] |
							//  r_p2[0] | r_p0[0]
	fxch	%st(1)			// r_p1[0] | p01_minus_p21 | r_p2[1] | r_p1[1] |
							//  r_p2[0] | r_p0[0]
	fsub	%st(4),%st(0)	// p10_minus_p20 | p01_minus_p21 | r_p2[1] |
							//  r_p1[1] | r_p2[0] | r_p0[0]
	fxch	%st(5)			// r_p0[0] | p01_minus_p21 | r_p2[1] |
							//  r_p1[1] | r_p2[0] | p10_minus_p20
	fsubp	%st(0),%st(4)	// p01_minus_p21 | r_p2[1] | r_p1[1] |
							//  p00_minus_p20 | p10_minus_p20
	fxch	%st(2)			// r_p1[1] | r_p2[1] | p01_minus_p21 |
							//  p00_minus_p20 | p10_minus_p20
	fsubp	%st(0),%st(1)	// p11_minus_p21 | p01_minus_p21 |
							//  p00_minus_p20 | p10_minus_p20
	fxch	%st(1)			// p01_minus_p21 | p11_minus_p21 |
							//  p00_minus_p20 | p10_minus_p20
	flds	C(d_xdenom)		// d_xdenom | p01_minus_p21 | p11_minus_p21 |
							//  p00_minus_p20 | p10_minus_p20
	fxch	%st(4)			// p10_minus_p20 | p01_minus_p21 | p11_minus_p21 |
							//  p00_minus_p20 | d_xdenom
	fstps	p10_minus_p20	// p01_minus_p21 | p11_minus_p21 |
							//  p00_minus_p20 | d_xdenom
	fstps	p01_minus_p21	// p11_minus_p21 | p00_minus_p20 | xstepdenominv
	fxch	%st(2)			// xstepdenominv | p00_minus_p20 | p11_minus_p21

//// ceil () for light so positive steps are exaggerated, negative steps
//// diminished,  pushing us away from underflow toward overflow. Underflow is
//// very visible, overflow is very unlikely, because of ambient lighting
//	t0 = r_p0[4] - r_p2[4];
//	t1 = r_p1[4] - r_p2[4];

	fildl	C(r_p2)+16		// r_p2[4] | xstepdenominv | p00_minus_p20 |
							//  p11_minus_p21
	fildl	C(r_p0)+16		// r_p0[4] | r_p2[4] | xstepdenominv |
							//  p00_minus_p20 | p11_minus_p21
	fildl	C(r_p1)+16		// r_p1[4] | r_p0[4] | r_p2[4] | xstepdenominv |
							//  p00_minus_p20 | p11_minus_p21
	fxch	%st(2)			// r_p2[4] | r_p0[4] | r_p1[4] | xstepdenominv |
							//  p00_minus_p20 | p11_minus_p21
	fld		%st(0)			// r_p2[4] | r_p2[4] | r_p0[4] | r_p1[4] |
							//  xstepdenominv | p00_minus_p20 | p11_minus_p21
	fsubrp	%st(0),%st(2)	// r_p2[4] | t0 | r_p1[4] | xstepdenominv |
							//  p00_minus_p20 | p11_minus_p21
	fsubrp	%st(0),%st(2)	// t0 | t1 | xstepdenominv | p00_minus_p20 |
							//  p11_minus_p21

//	r_lstepx = (int)
//			ceil((t1 * p01_minus_p21 - t0 * p11_minus_p21) * xstepdenominv);
//	r_lstepy = (int)
//			ceil((t1 * p00_minus_p20 - t0 * p10_minus_p20) * ystepdenominv);

	fld		%st(0)			// t0 | t0 | t1 | xstepdenominv | p00_minus_p20 |
							//  p11_minus_p21
	fmul	%st(5),%st(0)	// t0*p11_minus_p21 | t0 | t1 | xstepdenominv |
							//  p00_minus_p20 | p11_minus_p21
	fxch	%st(2)			// t1 | t0 | t0*p11_minus_p21 | xstepdenominv |
							//  p00_minus_p20 | p11_minus_p21
	fld		%st(0)			// t1 | t1 | t0 | t0*p11_minus_p21 |
							//  xstepdenominv | p00_minus_p20 | p11_minus_p21
	fmuls	p01_minus_p21	// t1*p01_minus_p21 | t1 | t0 | t0*p11_minus_p21 |
							//  xstepdenominv | p00_minus_p20 | p11_minus_p21
	fxch	%st(2)			// t0 | t1 | t1*p01_minus_p21 | t0*p11_minus_p21 |
							//  xstepdenominv | p00_minus_p20 | p11_minus_p21
	fmuls	p10_minus_p20	// t0*p10_minus_p20 | t1 | t1*p01_minus_p21 |
							//  t0*p11_minus_p21 | xstepdenominv |
							//  p00_minus_p20 | p11_minus_p21
	fxch	%st(1)			// t1 | t0*p10_minus_p20 | t1*p01_minus_p21 |
							//  t0*p11_minus_p21 | xstepdenominv |
							//  p00_minus_p20 | p11_minus_p21
	fmul	%st(5),%st(0)	// t1*p00_minus_p20 | t0*p10_minus_p20 |
							//  t1*p01_minus_p21 | t0*p11_minus_p21 |
							//  xstepdenominv | p00_minus_p20 | p11_minus_p21
	fxch	%st(2)			// t1*p01_minus_p21 | t0*p10_minus_p20 |
							//  t1*p00_minus_p20 | t0*p11_minus_p21 |
							//  xstepdenominv | p00_minus_p20 | p11_minus_p21
	fsubp	%st(0),%st(3)	// t0*p10_minus_p20 | t1*p00_minus_p20 |
							//  t1*p01_minus_p21 - t0*p11_minus_p21 |
							//  xstepdenominv | p00_minus_p20 | p11_minus_p21
	fsubrp	%st(0),%st(1)	// t1*p00_minus_p20 - t0*p10_minus_p20 |
							//  t1*p01_minus_p21 - t0*p11_minus_p21 |
							//  xstepdenominv | p00_minus_p20 | p11_minus_p21
	fld		%st(2)			// xstepdenominv |
							//  t1*p00_minus_p20 - t0*p10_minus_p20 |
							//  t1*p01_minus_p21 - t0*p11_minus_p21 |
							//  xstepdenominv | p00_minus_p20 | p11_minus_p21
	fmuls	float_minus_1	// ystepdenominv |
							//  t1*p00_minus_p20 - t0*p10_minus_p20 |
							//  t1*p01_minus_p21 - t0*p11_minus_p21 |
							//  xstepdenominv | p00_minus_p20 | p11_minus_p21
	fxch	%st(2)			// t1*p01_minus_p21 - t0*p11_minus_p21 |
							//  t1*p00_minus_p20 - t0*p10_minus_p20 |
							//  ystepdenominv | xstepdenominv | p00_minus_p20 |
							//  p11_minus_p21
	fmul	%st(3),%st(0)	// (t1*p01_minus_p21 - t0*p11_minus_p21)*
							//   xstepdenominv |
							//  t1*p00_minus_p20 - t0*p10_minus_p20 |
							//   | ystepdenominv | xstepdenominv |
							//   p00_minus_p20 | p11_minus_p21
	fxch	%st(1)			// t1*p00_minus_p20 - t0*p10_minus_p20 |
							//  (t1*p01_minus_p21 - t0*p11_minus_p21)*
							//   xstepdenominv | ystepdenominv |
							//   xstepdenominv | p00_minus_p20 | p11_minus_p21
	fmul	%st(2),%st(0)	// (t1*p00_minus_p20 - t0*p10_minus_p20)*
							//  ystepdenominv |
							//  (t1*p01_minus_p21 - t0*p11_minus_p21)*
							//  xstepdenominv | ystepdenominv |
							//  xstepdenominv | p00_minus_p20 | p11_minus_p21
	fldcw	ceil_cw
	fistpl	C(r_lstepy)		// r_lstepx | ystepdenominv | xstepdenominv |
							//  p00_minus_p20 | p11_minus_p21
	fistpl	C(r_lstepx)		// ystepdenominv | xstepdenominv | p00_minus_p20 |
							//  p11_minus_p21
	fldcw	single_cw

//	t0 = r_p0[2] - r_p2[2];
//	t1 = r_p1[2] - r_p2[2];

	fildl	C(r_p2)+8		// r_p2[2] | ystepdenominv | xstepdenominv |
							//  p00_minus_p20 | p11_minus_p21
	fildl	C(r_p0)+8		// r_p0[2] | r_p2[2] | ystepdenominv |
							//   xstepdenominv | p00_minus_p20 | p11_minus_p21
	fildl	C(r_p1)+8		// r_p1[2] | r_p0[2] | r_p2[2] | ystepdenominv |
							//  xstepdenominv | p00_minus_p20 | p11_minus_p21
	fxch	%st(2)			// r_p2[2] | r_p0[2] | r_p1[2] | ystepdenominv |
							//  xstepdenominv | p00_minus_p20 | p11_minus_p21
	fld		%st(0)			// r_p2[2] | r_p2[2] | r_p0[2] | r_p1[2] |
							//  ystepdenominv | xstepdenominv | p00_minus_p20 |
							//  p11_minus_p21
	fsubrp	%st(0),%st(2)	// r_p2[2] | t0 | r_p1[2] | ystepdenominv |
							//  xstepdenominv | p00_minus_p20 | p11_minus_p21
	fsubrp	%st(0),%st(2)	// t0 | t1 | ystepdenominv | xstepdenominv |
							//  p00_minus_p20 | p11_minus_p21

//	r_sstepx = (int)((t1 * p01_minus_p21 - t0 * p11_minus_p21) *
//			xstepdenominv);
//	r_sstepy = (int)((t1 * p00_minus_p20 - t0 * p10_minus_p20) *
//			ystepdenominv);

	fld		%st(0)			// t0 | t0 | t1 | ystepdenominv | xstepdenominv
	fmul	%st(6),%st(0)	// t0*p11_minus_p21 | t0 | t1 | ystepdenominv |
							//  xstepdenominv | p00_minus_p20 | p11_minus_p21
	fxch	%st(2)			// t1 | t0 | t0*p11_minus_p21 | ystepdenominv |
							//  xstepdenominv | p00_minus_p20 | p11_minus_p21
	fld		%st(0)			// t1 | t1 | t0 | t0*p11_minus_p21 |
							//  ystepdenominv | xstepdenominv | p00_minus_p20 |
							//  p11_minus_p21
	fmuls	p01_minus_p21	// t1*p01_minus_p21 | t1 | t0 | t0*p11_minus_p21 |
							//  ystepdenominv | xstepdenominv | p00_minus_p20 |
							//  p11_minus_p21
	fxch	%st(2)			// t0 | t1 | t1*p01_minus_p21 | t0*p11_minus_p21 |
							//  ystepdenominv | xstepdenominv | p00_minus_p20 |
							//  p11_minus_p21
	fmuls	p10_minus_p20	// t0*p10_minus_p20 | t1 | t1*p01_minus_p21 |
							//  t0*p11_minus_p21 | ystepdenominv |
							//  xstepdenominv | p00_minus_p20 | p11_minus_p21
	fxch	%st(1)			// t1 | t0*p10_minus_p20 | t1*p01_minus_p21 |
							//  t0*p11_minus_p21 | ystepdenominv |
							//  xstepdenominv | p00_minus_p20 | p11_minus_p21
	fmul	%st(6),%st(0)	// t1*p00_minus_p20 | t0*p10_minus_p20 |
							//  t1*p01_minus_p21 | t0*p11_minus_p21 |
							//  ystepdenominv | xstepdenominv | p00_minus_p20 |
							//  p11_minus_p21
	fxch	%st(2)			// t1*p01_minus_p21 | t0*p10_minus_p20 |
							//  t1*p00_minus_p20 | t0*p11_minus_p21 |
							//  ystepdenominv | xstepdenominv | p00_minus_p20 |
							//  p11_minus_p21
	fsubp	%st(0),%st(3)	// t0*p10_minus_p20 | t1*p00_minus_p20 |
							//  t1*p01_minus_p21 - t0*p11_minus_p21 |
							//  ystepdenominv | xstepdenominv | p00_minus_p20 |
							//  p11_minus_p21
	fsubrp	%st(0),%st(1)	// t1*p00_minus_p20 - t0*p10_minus_p20 |
							//  t1*p01_minus_p21 - t0*p11_minus_p21 |
							//  ystepdenominv | xstepdenominv | p00_minus_p20 |
							//  p11_minus_p21
	fmul	%st(2),%st(0)	// (t1*p00_minus_p20 - t0*p10_minus_p20)*
							//   ystepdenominv |
							//  t1*p01_minus_p21 - t0*p11_minus_p21 |
							//  ystepdenominv | xstepdenominv | p00_minus_p20 |
							//  p11_minus_p21
	fxch	%st(1)			// t1*p01_minus_p21 - t0*p11_minus_p21 |
							//  (t1*p00_minus_p20 - t0*p10_minus_p20)*
							//   ystepdenominv | ystepdenominv |
							//  xstepdenominv | p00_minus_p20 | p11_minus_p21
	fmul	%st(3),%st(0)	// (t1*p01_minus_p21 - t0*p11_minus_p21)*
							//  xstepdenominv |
							//  (t1*p00_minus_p20 - t0*p10_minus_p20)*
							//  ystepdenominv | ystepdenominv |
							//  xstepdenominv | p00_minus_p20 | p11_minus_p21
	fxch	%st(1)			// (t1*p00_minus_p20 - t0*p10_minus_p20)*
							//  ystepdenominv |
							//  (t1*p01_minus_p21 - t0*p11_minus_p21)*
							//  xstepdenominv | ystepdenominv |
							//  xstepdenominv | p00_minus_p20 | p11_minus_p21
	fistpl	C(r_sstepy)		// r_sstepx | ystepdenominv | xstepdenominv |
							//  p00_minus_p20 | p11_minus_p21
	fistpl	C(r_sstepx)		// ystepdenominv | xstepdenominv | p00_minus_p20 |
							//  p11_minus_p21

//	t0 = r_p0[3] - r_p2[3];
//	t1 = r_p1[3] - r_p2[3];

	fildl	C(r_p2)+12		// r_p2[3] | ystepdenominv | xstepdenominv |
							//  p00_minus_p20 | p11_minus_p21
	fildl	C(r_p0)+12		// r_p0[3] | r_p2[3] | ystepdenominv |
							//  xstepdenominv | p00_minus_p20 | p11_minus_p21
	fildl	C(r_p1)+12		// r_p1[3] | r_p0[3] | r_p2[3] | ystepdenominv |
							//  xstepdenominv | p00_minus_p20 | p11_minus_p21
	fxch	%st(2)			// r_p2[3] | r_p0[3] | r_p1[3] | ystepdenominv |
							//  xstepdenominv | p00_minus_p20 | p11_minus_p21
	fld		%st(0)			// r_p2[3] | r_p2[3] | r_p0[3] | r_p1[3] |
							//  ystepdenominv | xstepdenominv | p00_minus_p20 |
							//  p11_minus_p21
	fsubrp	%st(0),%st(2)	// r_p2[3] | t0 | r_p1[3] | ystepdenominv |
							//  xstepdenominv | p00_minus_p20 | p11_minus_p21
	fsubrp	%st(0),%st(2)	// t0 | t1 | ystepdenominv | xstepdenominv |
							//  p00_minus_p20 | p11_minus_p21

//	r_tstepx = (int)((t1 * p01_minus_p21 - t0 * p11_minus_p21) *
//			xstepdenominv);
//	r_tstepy = (int)((t1 * p00_minus_p20 - t0 * p10_minus_p20) *
//			ystepdenominv);

	fld		%st(0)			// t0 | t0 | t1 | ystepdenominv | xstepdenominv |
							//  p00_minus_p20 | p11_minus_p21
	fmul	%st(6),%st(0)	// t0*p11_minus_p21 | t0 | t1 | ystepdenominv |
							//  xstepdenominv | p00_minus_p20 | p11_minus_p21
	fxch	%st(2)			// t1 | t0 | t0*p11_minus_p21 | ystepdenominv |
							//  xstepdenominv | p00_minus_p20 | p11_minus_p21
	fld		%st(0)			// t1 | t1 | t0 | t0*p11_minus_p21 |
							//  ystepdenominv | xstepdenominv | p00_minus_p20 |
							//  p11_minus_p21
	fmuls	p01_minus_p21	// t1*p01_minus_p21 | t1 | t0 | t0*p11_minus_p21 |
							//  ystepdenominv | xstepdenominv | p00_minus_p20 |
							//  p11_minus_p21
	fxch	%st(2)			// t0 | t1 | t1*p01_minus_p21 | t0*p11_minus_p21 |
							//  ystepdenominv | xstepdenominv | p00_minus_p20 |
							//  p11_minus_p21
	fmuls	p10_minus_p20	// t0*p10_minus_p20 | t1 | t1*p01_minus_p21 |
							//  t0*p11_minus_p21 | ystepdenominv |
							//  xstepdenominv | p00_minus_p20 | p11_minus_p21
	fxch	%st(1)			// t1 | t0*p10_minus_p20 | t1*p01_minus_p21 |
							//  t0*p11_minus_p21 | ystepdenominv |
							//  xstepdenominv | p00_minus_p20 | p11_minus_p21
	fmul	%st(6),%st(0)	// t1*p00_minus_p20 | t0*p10_minus_p20 |
							//  t1*p01_minus_p21 | t0*p11_minus_p21 |
							//  ystepdenominv | xstepdenominv | p00_minus_p20 |
							//  p11_minus_p21
	fxch	%st(2)			// t1*p01_minus_p21 | t0*p10_minus_p20 |
							//  t1*p00_minus_p20 | t0*p11_minus_p21 |
							//  ystepdenominv | xstepdenominv | p00_minus_p20 |
							//  p11_minus_p21
	fsubp	%st(0),%st(3)	// t0*p10_minus_p20 | t1*p00_minus_p20 |
							//  t1*p01_minus_p21 - t0*p11_minus_p21 |
							//  ystepdenominv | xstepdenominv | p00_minus_p20 |
							//  p11_minus_p21
	fsubrp	%st(0),%st(1)	// t1*p00_minus_p20 - t0*p10_minus_p20 |
							//  t1*p01_minus_p21 - t0*p11_minus_p21 |
							//  ystepdenominv | xstepdenominv | p00_minus_p20 |
							//  p11_minus_p21
	fmul	%st(2),%st(0)	// (t1*p00_minus_p20 - t0*p10_minus_p20)*
							//   ystepdenominv |
							//  t1*p01_minus_p21 - t0*p11_minus_p21 |
							//  ystepdenominv | xstepdenominv | p00_minus_p20 |
							//  p11_minus_p21
	fxch	%st(1)			// t1*p01_minus_p21 - t0*p11_minus_p21 |
							//  (t1*p00_minus_p20 - t0*p10_minus_p20)*
							//  ystepdenominv | ystepdenominv |
							//  xstepdenominv | p00_minus_p20 | p11_minus_p21
	fmul	%st(3),%st(0)	// (t1*p01_minus_p21 - t0*p11_minus_p21)*
							//  xstepdenominv |
							//  (t1*p00_minus_p20 - t0*p10_minus_p20)*
							//  ystepdenominv | ystepdenominv |
							//  xstepdenominv | p00_minus_p20 | p11_minus_p21
	fxch	%st(1)			// (t1*p00_minus_p20 - t0*p10_minus_p20)*
							//  ystepdenominv |
							//  (t1*p01_minus_p21 - t0*p11_minus_p21)*
							//  xstepdenominv | ystepdenominv |
							//  xstepdenominv | p00_minus_p20 | p11_minus_p21
	fistpl	C(r_tstepy)		// r_tstepx | ystepdenominv | xstepdenominv |
							//  p00_minus_p20 | p11_minus_p21
	fistpl	C(r_tstepx)		// ystepdenominv | xstepdenominv | p00_minus_p20 |
							//  p11_minus_p21

//	t0 = r_p0[5] - r_p2[5];
//	t1 = r_p1[5] - r_p2[5];

	fildl	C(r_p2)+20		// r_p2[5] | ystepdenominv | xstepdenominv |
							//  p00_minus_p20 | p11_minus_p21
	fildl	C(r_p0)+20		// r_p0[5] | r_p2[5] | ystepdenominv |
							//  xstepdenominv | p00_minus_p20 | p11_minus_p21
	fildl	C(r_p1)+20		// r_p1[5] | r_p0[5] | r_p2[5] | ystepdenominv |
							//  xstepdenominv | p00_minus_p20 | p11_minus_p21
	fxch	%st(2)			// r_p2[5] | r_p0[5] | r_p1[5] | ystepdenominv |
							//  xstepdenominv | p00_minus_p20 | p11_minus_p21
	fld		%st(0)			// r_p2[5] | r_p2[5] | r_p0[5] | r_p1[5] |
							//  ystepdenominv | xstepdenominv | p00_minus_p20 |
							//  p11_minus_p21
	fsubrp	%st(0),%st(2)	// r_p2[5] | t0 | r_p1[5] | ystepdenominv |
							//  xstepdenominv | p00_minus_p20 | p11_minus_p21
	fsubrp	%st(0),%st(2)	// t0 | t1 | ystepdenominv | xstepdenominv |
							//  p00_minus_p20 | p11_minus_p21

//	r_zistepx = (int)((t1 * p01_minus_p21 - t0 * p11_minus_p21) *
//			xstepdenominv);
//	r_zistepy = (int)((t1 * p00_minus_p20 - t0 * p10_minus_p20) *
//			ystepdenominv);

	fld		%st(0)			// t0 | t0 | t1 | ystepdenominv | xstepdenominv |
							//  p00_minus_p20 | p11_minus_p21
	fmulp	%st(0),%st(6)	// t0 | t1 | ystepdenominv | xstepdenominv |
							//  p00_minus_p20 | t0*p11_minus_p21
	fxch	%st(1)			// t1 | t0 | ystepdenominv | xstepdenominv |
							//  p00_minus_p20 | t0*p11_minus_p21
	fld		%st(0)			// t1 | t1 | t0 | ystepdenominv | xstepdenominv |
							//  p00_minus_p20 | t0*p11_minus_p21
	fmuls	p01_minus_p21	// t1*p01_minus_p21 | t1 | t0 | ystepdenominv |
							//  xstepdenominv | p00_minus_p20 |
							//  t0*p11_minus_p21
	fxch	%st(2)			// t0 | t1 | t1*p01_minus_p21 | ystepdenominv |
							//  xstepdenominv | p00_minus_p20 |
							//  t0*p11_minus_p21
	fmuls	p10_minus_p20	// t0*p10_minus_p20 | t1 | t1*p01_minus_p21 |
							//  ystepdenominv | xstepdenominv | p00_minus_p20 |
							//  t0*p11_minus_p21
	fxch	%st(1)			// t1 | t0*p10_minus_p20 | t1*p01_minus_p21 |
							//  ystepdenominv | xstepdenominv | p00_minus_p20 |
							//  t0*p11_minus_p21
	fmulp	%st(0),%st(5)	// t0*p10_minus_p20 | t1*p01_minus_p21 |
							//  ystepdenominv | xstepdenominv |
							//  t1*p00_minus_p20 | t0*p11_minus_p21
	fxch	%st(5)			// t0*p11_minus_p21 | t1*p01_minus_p21 |
							//  ystepdenominv | xstepdenominv |
							//  t1*p00_minus_p20 | t0*p10_minus_p20
	fsubrp	%st(0),%st(1)	// t1*p01_minus_p21 - t0*p11_minus_p21 |
							//  ystepdenominv | xstepdenominv |
							//  t1*p00_minus_p20 | t0*p10_minus_p20
	fxch	%st(3)			// t1*p00_minus_p20 | ystepdenominv |
							//  xstepdenominv |
							//  t1*p01_minus_p21 - t0*p11_minus_p21 |
							//  t0*p10_minus_p20
	fsubp	%st(0),%st(4)	// ystepdenominv | xstepdenominv |
							//  t1*p01_minus_p21 - t0*p11_minus_p21 |
							//  t1*p00_minus_p20 - t0*p10_minus_p20
	fxch	%st(1)			// xstepdenominv | ystepdenominv |
							//  t1*p01_minus_p21 - t0*p11_minus_p21 |
							//  t1*p00_minus_p20 - t0*p10_minus_p20
	fmulp	%st(0),%st(2)	// ystepdenominv |
							//  (t1*p01_minus_p21 - t0*p11_minus_p21) *
							//  xstepdenominv |
							//  t1*p00_minus_p20 - t0*p10_minus_p20
	fmulp	%st(0),%st(2)	// (t1*p01_minus_p21 - t0*p11_minus_p21) *
							//  xstepdenominv |
							//  (t1*p00_minus_p20 - t0*p10_minus_p20) *
							//  ystepdenominv
	fistpl	C(r_zistepx)	// (t1*p00_minus_p20 - t0*p10_minus_p20) *
							//  ystepdenominv
	fistpl	C(r_zistepy)

//	a_sstepxfrac = r_sstepx << 16;
//	a_tstepxfrac = r_tstepx << 16;
//
//	a_ststepxwhole = r_affinetridesc.skinwidth * (r_tstepx >> 16) +
//			(r_sstepx >> 16);

	movl	C(r_sstepx),%eax
	movl	C(r_tstepx),%edx
	shll	$16,%eax
	shll	$16,%edx
	movl	%eax,C(a_sstepxfrac)
	movl	%edx,C(a_tstepxfrac)

	movl	C(r_sstepx),%ecx
	movl	C(r_tstepx),%eax
	sarl	$16,%ecx
	sarl	$16,%eax
	imull	skinwidth(%esp)
	addl	%ecx,%eax
	movl	%eax,C(a_ststepxwhole)

	ret


//----------------------------------------------------------------------
// Bresenham-style line-scan setup for alias triangle edges.
// The small-step table is the C adivtab[64*64] (two 32-bit integers per row).
// Larger positive edge heights use integer division. Negative horizontal
// deltas use an unsigned magnitude divide and exact floor correction, avoiding
// a second divide. Non-positive large heights retain the reference C path.
//----------------------------------------------------------------------

.globl C(D_PolysetSetUpForLineScan_asm486)
C(D_PolysetSetUpForLineScan_asm486):
	pushl	%ebp
	movl	%esp,%ebp
	movl	16(%ebp),%eax		// tm = endvertu - startvertu
	subl	8(%ebp),%eax
	movl	20(%ebp),%ecx		// tn = endvertv - startvertv
	subl	12(%ebp),%ecx
	movl	$-1,C(errorterm)

	cmpl	$32,%eax
	jg	.LPolysetLineScanLarge
	cmpl	$-31,%eax
	jl	.LPolysetLineScanLarge
	cmpl	$32,%ecx
	jg	.LPolysetLineScanLarge
	cmpl	$-31,%ecx
	jl	.LPolysetLineScanLarge

// The original fast path covers every pair in [-31,32], including the
// table's historical values for non-positive tn. Keep those exact entries.
	leal	31(%eax),%edx
	shll	$6,%edx
	leal	31(%ecx),%eax
	addl	%eax,%edx
	movl	C(adivtab)(,%edx,8),%eax
	movl	%eax,C(ubasestep)
	movl	C(adivtab)+4(,%edx,8),%eax
	movl	%eax,C(erroradjustup)
	movl	%ecx,C(erroradjustdown)
	leave
	ret

.LPolysetLineScanLarge:
	testl	%ecx,%ecx
	jle	.LPolysetLineScanC
	movl	%ecx,C(erroradjustdown)
	testl	%eax,%eax
	js	.LPolysetLineScanNegative
	cdq
	idivl	%ecx
	movl	%eax,C(ubasestep)
	movl	%edx,C(erroradjustup)
	leave
	ret

.LPolysetLineScanNegative:
	// Preserve the legacy C result for INT_MIN, whose signed magnitude
	// overflows even though rasterizer edge deltas never reach it.
	cmpl	$0x80000000,%eax
	je	.LPolysetLineScanC
	// Floor division of a negative numerator can be derived from one unsigned
	// divide of its magnitude: -m/d = -q when rem is zero, otherwise -q-1.
	// The remainder accumulator is d-rem in the non-exact case.
	negl	%eax
	xorl	%edx,%edx
	divl	%ecx
	testl	%edx,%edx
	jz	.LPolysetLineScanNegativeExact
	negl	%eax
	decl	%eax
	movl	%eax,C(ubasestep)
	subl	%edx,%ecx
	movl	%ecx,C(erroradjustup)
	leave
	ret

.LPolysetLineScanNegativeExact:
	negl	%eax
	movl	%eax,C(ubasestep)
	movl	%edx,C(erroradjustup)
	leave
	ret

.LPolysetLineScanC:
	pushl	20(%ebp)		// forward original cdecl parameters
	pushl	16(%ebp)
	pushl	12(%ebp)
	pushl	8(%ebp)
	call	C(D_PolysetSetUpForLineScan_C)
	addl	$16,%esp
	leave
	ret


//----------------------------------------------------------------------
// recursive subdivision affine triangle drawing code
//
// not C-callable because of stdcall return
//----------------------------------------------------------------------

#define lp1	4+16
#define lp2	8+16
#define lp3	12+16

.globl C(D_PolysetRecursiveTriangle)
C(D_PolysetRecursiveTriangle):
	pushl	%ebp				// preserve caller stack frame pointer
	pushl	%esi				// preserve register variables
	pushl	%edi
	pushl	%ebx

//	int		*temp;
//	int		d;
//	int		new[6];
//	int		i;
//	int		z;
//	short	*zbuf;
	movl	lp2(%esp),%esi
	movl	lp1(%esp),%ebx
	movl	lp3(%esp),%edi

//	d = lp2[0] - lp1[0];
//	if (d < -1 || d > 1)
//		goto split;
	movl	0(%esi),%eax
	subl	0(%ebx),%eax
	incl	%eax
	cmpl	$2,%eax
	ja		LSplit

//	d = lp2[1] - lp1[1];
//	if (d < -1 || d > 1)
//		goto split;
	// y only needed for |dy|; LSplit reloads from memory.
	movl	4(%esi),%eax
	subl	4(%ebx),%eax
	incl	%eax
	cmpl	$2,%eax
	ja		LSplit
	// lp3[0] only needed for the next edge check; LSplit overwrites %eax.
	movl	0(%edi),%eax

//	d = lp3[0] - lp2[0];
//	if (d < -1 || d > 1)
//		goto split2;
	subl	0(%esi),%eax
	incl	%eax
	cmpl	$2,%eax
	ja		LSplit2

//	d = lp3[1] - lp2[1];
//	if (d < -1 || d > 1)
//		goto split2;
	movl	4(%edi),%eax
	subl	4(%esi),%eax
	incl	%eax
	cmpl	$2,%eax
	ja		LSplit2
	// lp1[0] only needed for the next edge check; LSplit2 overwrites %eax.
	movl	0(%ebx),%eax

//	d = lp1[0] - lp3[0];
//	if (d < -1 || d > 1)
//		goto split3;
	subl	0(%edi),%eax
	incl	%eax
	cmpl	$2,%eax
	ja		LSplit3

//	d = lp1[1] - lp3[1];
//	if (d < -1 || d > 1)
//	{
//split3:
//		temp = lp1;
//		lp3 = lp2;
//		lp1 = lp3;
//		lp2 = temp;
//		goto split;
//	}
//
//	return;			// entire tri is filled
//
	movl	4(%ebx),%eax
	subl	4(%edi),%eax
	incl	%eax
	cmpl	$2,%eax
	jna		LDone

LSplit3:
	// Rotate lp1<-lp3, lp2<-lp1, lp3<-lp2 (%edx was lp3[0] on |dx| path).
	movl	%ebx,%edx
	movl	%edi,%ebx
	movl	%esi,%edi
	movl	%edx,%esi
	jmp		LSplit

//split2:
LSplit2:

//	temp = lp1;
//	lp1 = lp2;
//	lp2 = lp3;
//	lp3 = temp;
	movl	%ebx,%eax
	movl	%esi,%ebx
	movl	%edi,%esi
	movl	%eax,%edi

//split:
LSplit:

	subl	$24,%esp		// allocate space for a new vertex

//// split this edge
//	new[0] = (lp1[0] + lp2[0]) >> 1;
//	new[1] = (lp1[1] + lp2[1]) >> 1;
//	new[2] = (lp1[2] + lp2[2]) >> 1;
//	new[3] = (lp1[3] + lp2[3]) >> 1;
//	new[5] = (lp1[5] + lp2[5]) >> 1;
// Memory addl for s/t/zi midpoints (drop lp2 preloads into %edx).
// Keep lp1.y live in %eax; load lp1.x only on the equal-Y tie-break path.
	movl	8(%ebx),%eax
	addl	8(%esi),%eax
	sarl	$1,%eax
	movl	%eax,8(%esp)

	movl	12(%ebx),%ecx
	addl	12(%esi),%ecx
	sarl	$1,%ecx
	movl	%ecx,12(%esp)

	movl	20(%ebx),%eax
	addl	20(%esi),%eax
	sarl	$1,%eax
	movl	%eax,20(%esp)

	movl	0(%esi),%edx
	addl	0(%ebx),%edx
	sarl	$1,%edx
	movl	%edx,0(%esp)

	movl	4(%ebx),%eax
	movl	4(%esi),%ebp
	addl	%eax,%ebp
	sarl	$1,%ebp
	movl	%ebp,4(%esp)

//// draw the point if splitting a leading edge
//	if (lp2[1] > lp1[1])
//		goto nodraw;
	cmpl	%eax,4(%esi)
	jg		LNoDraw

//	if ((lp2[1] == lp1[1]) && (lp2[0] < lp1[0]))
//		goto nodraw;
// Keep new[0]/new[1] live in %edx/%ebp into LDraw (unequal-y is common).
// Equal-y must not clobber %edx with lp2[0].
	jnz		LDraw
	movl	0(%esi),%eax
	cmpl	0(%ebx),%eax
	jl		LNoDraw

LDraw:

// z = new[5] >> 16;  %edx=new[0], %ebp=new[1] already live
	movl	20(%esp),%eax
	sarl	$16,%eax
	movl	C(zspantable)(,%ebp,4),%ecx

//	if (z >= *zbuf)
//	{
	cmpw	(%ecx,%edx,2),%ax
	jnge	LNoDraw

//		int		pix;
//		
//		*zbuf = z;
	movw	%ax,(%ecx,%edx,2)

//		pix = d_pcolormap[skintable[new[3]>>16][new[2]>>16]];
	movl	12(%esp),%eax
	sarl	$16,%eax
	movl	8(%esp),%ecx
	sarl	$16,%ecx
	// %ebp/%edx still hold new[1]/new[0]
	movl	C(skintable)(,%eax,4),%eax
	movzbl	(%eax,%ecx),%ecx
	movl	C(d_pcolormap),%eax
	movb	(%eax,%ecx,),%cl

//		d_viewbuffer[d_scantable[new[1]] + new[0]] = pix;
	movl	C(viewspantable)(,%ebp,4),%eax
	movb	%cl,(%eax,%edx)

//	}
//
//nodraw:
LNoDraw:

//// recursively continue
//	D_PolysetRecursiveTriangle (lp3, lp1, new);
	pushl	%esp
	pushl	%ebx
	pushl	%edi
	call	C(D_PolysetRecursiveTriangle)

//	D_PolysetRecursiveTriangle (lp3, new, lp2);
	movl	%esp,%ebx
	pushl	%esi
	pushl	%ebx
	pushl	%edi
	call	C(D_PolysetRecursiveTriangle)
	addl	$24,%esp

LDone:
	popl	%ebx				// restore register variables
	popl	%edi
	popl	%esi
	popl	%ebp				// restore caller stack frame pointer
	ret		$12


//----------------------------------------------------------------------
// 8-bpp horizontal span drawing code for affine polygons, with smooth
// shading and no transparency
//----------------------------------------------------------------------

#define pspans	4+8

.globl C(D_PolysetAff8Start)
C(D_PolysetAff8Start):

.globl C(D_PolysetDrawSpans8)
C(D_PolysetDrawSpans8):
	pushl	%esi				// preserve register variables
	pushl	%ebx

	movl	pspans(%esp),%esi	// point to the first span descriptor
	movl	C(r_zistepx),%ecx

	pushl	%ebp				// preserve caller's stack frame
	pushl	%edi

	rorl	$16,%ecx			// put high 16 bits of 1/z step in low word
	movl	%ecx,lzistepx

// Triangle-constant skin steps: build once per call (same as lzistepx).
	movl	C(a_ststepxwhole),%ecx

	movl	%ecx,advancetable+4	// advance base in t
	addl	C(r_affinetridesc)+atd_skinwidth,%ecx

	movl	%ecx,advancetable	// advance extra in t
	movl	C(a_tstepxfrac),%ecx

	movw	C(r_lstepx),%cx
	movl	%ecx,tstep

	movl	spanpackage_t_count(%esi),%edx

LSpanLoop:

//		lcount = d_aspancount - pspanpackage->count;
//
//		errorterm += erroradjustup;
//		if (errorterm >= 0)
//		{
//			d_aspancount += d_countextrastep;
//			errorterm -= erroradjustdown;
//		}
//		else
//		{
//			d_aspancount += ubasestep;
//		}
	movl	C(d_aspancount),%eax
	subl	%edx,%eax

	movl	C(errorterm),%ebx
	addl	C(erroradjustup),%ebx
	js		LNoTurnover

	movl	C(erroradjustdown),%edx
	movl	C(d_countextrastep),%edi
	subl	%edx,%ebx
	movl	C(d_aspancount),%ebp
	movl	%ebx,C(errorterm)
	addl	%edi,%ebp
	movl	%ebp,C(d_aspancount)
	jmp		LRightEdgeStepped

LNoTurnover:
	movl	C(d_aspancount),%edi
	movl	%ebx,C(errorterm)
	addl	C(ubasestep),%edi
	movl	%edi,C(d_aspancount)

LRightEdgeStepped:
	decl	%eax
	jle		.LAff8ShortOrEmpty

	movl	%eax,%edx			// count
	addl	$8,%edx

	shrl	$3,%edx				// count of full and partial loops
	movl	spanpackage_t_sfrac(%esi),%ebx

	movw	%dx,%bx
	movl	spanpackage_t_pz(%esi),%ecx

	notl	%eax

	movl	spanpackage_t_pdest(%esi),%edi
	andl	$7,%eax		// 0->0, 1->7, 2->6, ... , 7->1

	subl	%eax,%edi	// compensate for hardwired offsets
	subl	%eax,%ecx

	subl	%eax,%ecx
	movl	spanpackage_t_tfrac(%esi),%edx

	movw	spanpackage_t_light(%esi),%dx
	movl	spanpackage_t_zi(%esi),%ebp

	rorl	$16,%ebp	// put high 16 bits of 1/z in low word
	pushl	%esi

	movl	spanpackage_t_ptex(%esi),%esi
	jmp		aff8entryvec_table(,%eax,4)

// %bx = count of full and partial loops
// %ebx high word = sfrac
// %ecx = pz
// %dx = light
// %edx high word = tfrac
// %esi = ptex
// %edi = pdest
// %ebp = 1/z
// tstep low word = C(r_lstepx)
// tstep high word = C(a_tstepxfrac)
// C(a_sstepxfrac) low word = 0
// C(a_sstepxfrac) high word = C(a_sstepxfrac)

LDrawLoop:

// FIXME: do we need to clamp light? We may need at least a buffer bit to
// keep it from poking into tfrac and causing problems

LDraw8:
	cmpw	(%ecx),%bp
	jl		Lp1
	movzbl	(%esi),%eax
	movb	%dh,%ah
	movw	%bp,(%ecx)
	movb	0x12345678(%eax),%al
LPatch8:
	movb	%al,(%edi)
Lp1:
	addl	tstep,%edx
	sbbl	%eax,%eax
	addl	lzistepx,%ebp
	adcl	$0,%ebp
	ALIAS_SPAN_ADVANCE

LDraw7:
	cmpw	2(%ecx),%bp
	jl		Lp2
	movzbl	(%esi),%eax
	movb	%dh,%ah
	movw	%bp,2(%ecx)
	movb	0x12345678(%eax),%al
LPatch7:
	movb	%al,1(%edi)
Lp2:
	addl	tstep,%edx
	sbbl	%eax,%eax
	addl	lzistepx,%ebp
	adcl	$0,%ebp
	ALIAS_SPAN_ADVANCE

LDraw6:
	cmpw	4(%ecx),%bp
	jl		Lp3
	movzbl	(%esi),%eax
	movb	%dh,%ah
	movw	%bp,4(%ecx)
	movb	0x12345678(%eax),%al
LPatch6:
	movb	%al,2(%edi)
Lp3:
	addl	tstep,%edx
	sbbl	%eax,%eax
	addl	lzistepx,%ebp
	adcl	$0,%ebp
	ALIAS_SPAN_ADVANCE

LDraw5:
	cmpw	6(%ecx),%bp
	jl		Lp4
	movzbl	(%esi),%eax
	movb	%dh,%ah
	movw	%bp,6(%ecx)
	movb	0x12345678(%eax),%al
LPatch5:
	movb	%al,3(%edi)
Lp4:
	addl	tstep,%edx
	sbbl	%eax,%eax
	addl	lzistepx,%ebp
	adcl	$0,%ebp
	ALIAS_SPAN_ADVANCE

LDraw4:
	cmpw	8(%ecx),%bp
	jl		Lp5
	movzbl	(%esi),%eax
	movb	%dh,%ah
	movw	%bp,8(%ecx)
	movb	0x12345678(%eax),%al
LPatch4:
	movb	%al,4(%edi)
Lp5:
	addl	tstep,%edx
	sbbl	%eax,%eax
	addl	lzistepx,%ebp
	adcl	$0,%ebp
	ALIAS_SPAN_ADVANCE

LDraw3:
	cmpw	10(%ecx),%bp
	jl		Lp6
	movzbl	(%esi),%eax
	movb	%dh,%ah
	movw	%bp,10(%ecx)
	movb	0x12345678(%eax),%al
LPatch3:
	movb	%al,5(%edi)
Lp6:
	addl	tstep,%edx
	sbbl	%eax,%eax
	addl	lzistepx,%ebp
	adcl	$0,%ebp
	ALIAS_SPAN_ADVANCE

LDraw2:
	cmpw	12(%ecx),%bp
	jl		Lp7
	movzbl	(%esi),%eax
	movb	%dh,%ah
	movw	%bp,12(%ecx)
	movb	0x12345678(%eax),%al
LPatch2:
	movb	%al,6(%edi)
Lp7:
	addl	tstep,%edx
	sbbl	%eax,%eax
	addl	lzistepx,%ebp
	adcl	$0,%ebp
	ALIAS_SPAN_ADVANCE

LDraw1:
	cmpw	14(%ecx),%bp
	jl		Lp8
	movzbl	(%esi),%eax
	movb	%dh,%ah
	movw	%bp,14(%ecx)
	movb	0x12345678(%eax),%al
LPatch1:
	movb	%al,7(%edi)
Lp8:
// Finish the first half of a paired Aff8 group.
	decw	%bx
	jz		LAff8LastGroup

	addl	tstep,%edx
	sbbl	%eax,%eax
	addl	lzistepx,%ebp
	adcl	$0,%ebp
// a_sstepxfrac low word is 0, so %bx (already decremented) is preserved.
	ALIAS_SPAN_ADVANCE

	addl	$8,%edi
	addl	$16,%ecx

// The second half is duplicated so the common 16-pixel case does not need
// to jump through LDrawLoop between the two eight-pixel groups.
LDraw16:
	cmpw	(%ecx),%bp
	jl		Lq16p1
	movzbl	(%esi),%eax
	movb	%dh,%ah
	movw	%bp,(%ecx)
	movb	0x12345678(%eax),%al
LPatch16:
	movb	%al,(%edi)
Lq16p1:
	addl	tstep,%edx
	sbbl	%eax,%eax
	addl	lzistepx,%ebp
	adcl	$0,%ebp
	ALIAS_SPAN_ADVANCE

LDraw15:
	cmpw	2(%ecx),%bp
	jl		Lq16p2
	movzbl	(%esi),%eax
	movb	%dh,%ah
	movw	%bp,2(%ecx)
	movb	0x12345678(%eax),%al
LPatch15:
	movb	%al,1(%edi)
Lq16p2:
	addl	tstep,%edx
	sbbl	%eax,%eax
	addl	lzistepx,%ebp
	adcl	$0,%ebp
	ALIAS_SPAN_ADVANCE

LDraw14:
	cmpw	4(%ecx),%bp
	jl		Lq16p3
	movzbl	(%esi),%eax
	movb	%dh,%ah
	movw	%bp,4(%ecx)
	movb	0x12345678(%eax),%al
LPatch14:
	movb	%al,2(%edi)
Lq16p3:
	addl	tstep,%edx
	sbbl	%eax,%eax
	addl	lzistepx,%ebp
	adcl	$0,%ebp
	ALIAS_SPAN_ADVANCE

LDraw13:
	cmpw	6(%ecx),%bp
	jl		Lq16p4
	movzbl	(%esi),%eax
	movb	%dh,%ah
	movw	%bp,6(%ecx)
	movb	0x12345678(%eax),%al
LPatch13:
	movb	%al,3(%edi)
Lq16p4:
	addl	tstep,%edx
	sbbl	%eax,%eax
	addl	lzistepx,%ebp
	adcl	$0,%ebp
	ALIAS_SPAN_ADVANCE

LDraw12:
	cmpw	8(%ecx),%bp
	jl		Lq16p5
	movzbl	(%esi),%eax
	movb	%dh,%ah
	movw	%bp,8(%ecx)
	movb	0x12345678(%eax),%al
LPatch12:
	movb	%al,4(%edi)
Lq16p5:
	addl	tstep,%edx
	sbbl	%eax,%eax
	addl	lzistepx,%ebp
	adcl	$0,%ebp
	ALIAS_SPAN_ADVANCE

LDraw11:
	cmpw	10(%ecx),%bp
	jl		Lq16p6
	movzbl	(%esi),%eax
	movb	%dh,%ah
	movw	%bp,10(%ecx)
	movb	0x12345678(%eax),%al
LPatch11:
	movb	%al,5(%edi)
Lq16p6:
	addl	tstep,%edx
	sbbl	%eax,%eax
	addl	lzistepx,%ebp
	adcl	$0,%ebp
	ALIAS_SPAN_ADVANCE

LDraw10:
	cmpw	12(%ecx),%bp
	jl		Lq16p7
	movzbl	(%esi),%eax
	movb	%dh,%ah
	movw	%bp,12(%ecx)
	movb	0x12345678(%eax),%al
LPatch10:
	movb	%al,6(%edi)
Lq16p7:
	addl	tstep,%edx
	sbbl	%eax,%eax
	addl	lzistepx,%ebp
	adcl	$0,%ebp
	ALIAS_SPAN_ADVANCE

LDraw9:
	cmpw	14(%ecx),%bp
	jl		Lq16p8
	movzbl	(%esi),%eax
	movb	%dh,%ah
	movw	%bp,14(%ecx)
	movb	0x12345678(%eax),%al
LPatch9b:
	movb	%al,7(%edi)
Lq16p8:
	decw	%bx
	jz		LAff8LastGroup

	addl	tstep,%edx
	sbbl	%eax,%eax
	addl	lzistepx,%ebp
	adcl	$0,%ebp
	ALIAS_SPAN_ADVANCE

	addl	$8,%edi
	addl	$16,%ecx
	jmp		LDrawLoop

LAff8LastGroup:
	popl	%esi				// restore spans pointer
LNextSpan:
	addl	$(spanpackage_t_size),%esi	// point to next span
LNextSpanESISet:
	movl	spanpackage_t_count(%esi),%edx
	cmpl	$-999999,%edx		// any more spans?
	jnz		LSpanLoop			// yes

	popl	%edi
	popl	%ebp				// restore the caller's stack frame
	popl	%ebx				// restore register variables
	popl	%esi
	ret

.LAff8ShortOrEmpty:
	jz		LExactlyOneLong
	jmp		LNextSpan

// draw a one-long span

LExactlyOneLong:

	movl	spanpackage_t_pz(%esi),%ecx
	movl	spanpackage_t_zi(%esi),%ebp

	rorl	$16,%ebp	// put high 16 bits of 1/z in low word
	cmpw	(%ecx),%bp
	jl		LNextSpan
	// ptex only needed when the pixel passes Z (same deferral as pdest/light).
	movl	spanpackage_t_ptex(%esi),%ebx
	movzbl	(%ebx),%eax
	movl	spanpackage_t_pdest(%esi),%edi
	movb	spanpackage_t_light+1(%esi),%ah
	addl	$(spanpackage_t_size),%esi	// point to next span
	movw	%bp,(%ecx)
	movb	0x12345678(%eax),%al
LPatch9:
	movb	%al,(%edi)

	jmp		LNextSpanESISet

.globl C(D_PolysetAff8End)
C(D_PolysetAff8End):


#define pcolormap		4

.globl C(D_Aff8Patch)
C(D_Aff8Patch):
	movl	pcolormap(%esp),%eax
	movl	%eax,LPatch1-4
	movl	%eax,LPatch2-4
	movl	%eax,LPatch3-4
	movl	%eax,LPatch4-4
	movl	%eax,LPatch5-4
	movl	%eax,LPatch6-4
	movl	%eax,LPatch7-4
	movl	%eax,LPatch8-4
	movl	%eax,LPatch9-4
	movl	%eax,LPatch10-4
	movl	%eax,LPatch11-4
	movl	%eax,LPatch12-4
	movl	%eax,LPatch13-4
	movl	%eax,LPatch14-4
	movl	%eax,LPatch15-4
	movl	%eax,LPatch16-4
	movl	%eax,LPatch9b-4

	ret


//----------------------------------------------------------------------
// Alias model polygon dispatching code, combined with subdivided affine
// triangle drawing code
//----------------------------------------------------------------------

.globl C(D_PolysetDraw)
C(D_PolysetDraw):

//	spanpackage_t	spans[DPS_MAXSPANS + 1 +
//			((CACHE_SIZE - 1) / sizeof(spanpackage_t)) + 1];
//						// one extra because of cache line pretouching
//
//	a_spans = (spanpackage_t *)
//			(((long)&spans[0] + CACHE_SIZE - 1) & ~(CACHE_SIZE - 1));
	subl	$(SPAN_SIZE),%esp
	movl	%esp,%eax
	addl	$(CACHE_SIZE - 1),%eax
	andl	$(~(CACHE_SIZE - 1)),%eax
	movl	%eax,C(a_spans)

//	if (r_affinetridesc.drawtype)
//		D_DrawSubdiv ();
//	else
//		D_DrawNonSubdiv ();
	movl	C(r_affinetridesc)+atd_drawtype,%eax
	testl	%eax,%eax
	jz		C(D_DrawNonSubdiv)

	pushl	%ebp				// preserve caller stack frame pointer

//	lnumtriangles = r_affinetridesc.numtriangles;
	movl	C(r_affinetridesc)+atd_numtriangles,%ebp

	pushl	%esi				// preserve register variables
	shll	$4,%ebp

	pushl	%ebx
//	ptri = r_affinetridesc.ptriangles;
	movl	C(r_affinetridesc)+atd_ptriangles,%ebx

	pushl	%edi

//	mtriangle_t		*ptri;
//	finalvert_t		*pfv, *index0, *index1, *index2;
//	int				i;
//	int				lnumtriangles;
//	int				s0, s1, s2;

//	pfv = r_affinetridesc.pfinalverts;
	movl	C(r_affinetridesc)+atd_pfinalverts,%edi

//	for (i=0 ; i<lnumtriangles ; i++)
//	{

Llooptop:

//		index0 = pfv + ptri[i].vertindex[0];
//		index1 = pfv + ptri[i].vertindex[1];
//		index2 = pfv + ptri[i].vertindex[2];
	movl	mtri_vertindex-16+0(%ebx,%ebp,),%ecx
	movl	mtri_vertindex-16+4(%ebx,%ebp,),%esi

	shll	$(fv_shift),%ecx
	movl	mtri_vertindex-16+8(%ebx,%ebp,),%edx

	shll	$(fv_shift),%esi
	addl	%edi,%ecx

	shll	$(fv_shift),%edx
	addl	%edi,%esi

	addl	%edi,%edx

//		if (((index0->v[1]-index1->v[1]) *
//				(index0->v[0]-index2->v[0]) -
//				(index0->v[0]-index1->v[0])*(index0->v[1]-index2->v[1])) >= 0)
//		{
//			continue;
//		}
//
//		d_pcolormap = &((byte *)acolormap)[index0->v[4] & 0xFF00];
// The vertex coordinates are integer screen positions.  Use the same exact
// integer determinant as D_DrawNonSubdiv instead of round-tripping it through
// the x87; restore the stable final-vertex base after using %edi as scratch.
	movl	fv_v+4(%ecx),%eax
	movl	fv_v+0(%ecx),%edi
	subl	fv_v+4(%esi),%eax
	subl	fv_v+0(%edx),%edi
	imull	%edi,%eax
	movl	%eax,temp0
	movl	fv_v+0(%ecx),%edi
	movl	fv_v+4(%ecx),%eax
	subl	fv_v+0(%esi),%edi
	subl	fv_v+4(%edx),%eax
	imull	%edi,%eax
	subl	%eax,temp0
	movl	C(r_affinetridesc)+atd_pfinalverts,%edi
	jns		Lskip

	// Match C: set colormap only when the triangle will be drawn.
	movl	fv_v+16(%ecx),%eax
	andl	$0xFF00,%eax
	addl	C(acolormap),%eax
	movl	%eax,C(d_pcolormap)

//		if (ptri[i].facesfront)
//		{
//			D_PolysetRecursiveTriangle(index0->v, index1->v, index2->v);
	movl	mtri_facesfront-16(%ebx,%ebp,),%eax
	testl	%eax,%eax
	jz		Lfacesback

	pushl	%edx
	pushl	%esi
	pushl	%ecx
	call	C(D_PolysetRecursiveTriangle)

	subl	$16,%ebp
	jnz		Llooptop
	jmp		Ldone2

//		}
//		else
//		{
Lfacesback:

//			s0 = index0->v[2];
//			s1 = index1->v[2];
//			s2 = index2->v[2];
	movl	fv_v+8(%ecx),%eax
	pushl	%eax
	movl	fv_v+8(%esi),%eax
	pushl	%eax
	movl	fv_v+8(%edx),%eax
	pushl	%eax
	pushl	%ecx
	pushl	%edx

//			if (index0->flags & ALIAS_ONSEAM)
//				index0->v[2] += r_affinetridesc.seamfixupX16;
	movl	C(r_affinetridesc)+atd_seamfixupX16,%eax
	testl	$(ALIAS_ONSEAM),fv_flags(%ecx)
	jz		Lp11
	addl	%eax,fv_v+8(%ecx)
Lp11:

//			if (index1->flags & ALIAS_ONSEAM)
//				index1->v[2] += r_affinetridesc.seamfixupX16;
	testl	$(ALIAS_ONSEAM),fv_flags(%esi)
	jz		Lp12
	addl	%eax,fv_v+8(%esi)
Lp12:

//			if (index2->flags & ALIAS_ONSEAM)
//				index2->v[2] += r_affinetridesc.seamfixupX16;
	testl	$(ALIAS_ONSEAM),fv_flags(%edx)
	jz		Lp13
	addl	%eax,fv_v+8(%edx)
Lp13:

//			D_PolysetRecursiveTriangle(index0->v, index1->v, index2->v);
	pushl	%edx
	pushl	%esi
	pushl	%ecx
	call	C(D_PolysetRecursiveTriangle)

//			index0->v[2] = s0;
//			index1->v[2] = s1;
//			index2->v[2] = s2;
	popl	%edx
	popl	%ecx
	popl	%eax
	movl	%eax,fv_v+8(%edx)
	popl	%eax
	movl	%eax,fv_v+8(%esi)
	popl	%eax
	movl	%eax,fv_v+8(%ecx)

//		}
//	}
Lskip:
	subl	$16,%ebp
	jnz		Llooptop

Ldone2:
	popl	%edi				// restore the caller's stack frame
	popl	%ebx
	popl	%esi				// restore register variables
	popl	%ebp

	addl	$(SPAN_SIZE),%esp

	ret


//----------------------------------------------------------------------
// Alias model triangle left-edge scanning code
//----------------------------------------------------------------------

#define height	4+16

.globl C(D_PolysetScanLeftEdge)
C(D_PolysetScanLeftEdge):
	pushl	%ebp				// preserve caller stack frame pointer
	pushl	%esi				// preserve register variables
	pushl	%edi
	pushl	%ebx

	movl	C(d_sfrac),%ecx
	movl	C(d_ptex),%ebx
	movl	C(d_pedgespanpackage),%esi
	// The height occupies only the low 16-bit scan counter in ECX.
	orw	height(%esp),%cx
	movl	C(d_tfrac),%edx

// Spill light/zi/aspancount so %edi/%ebp can hold running d_pdest/d_pz
// cursors and aspancount avoids a per-row global RMW.
	movl	C(d_light),%eax
	pushl	%eax				// 8(%esp) after zi/aspancount pushes
	movl	C(d_zi),%eax
	pushl	%eax				// 4(%esp) = zi
	movl	C(d_aspancount),%eax
	pushl	%eax				// 0(%esp) = aspancount
	movl	C(d_pdest),%edi
	movl	C(d_pz),%ebp

// %eax: scratch
// %ebx: d_ptex
// %ecx: d_sfrac in high word, count in low word
// %edx: d_tfrac
// %esi: d_pedgespanpackage (live list cursor)
// %edi: d_pdest (live)
// %ebp: d_pz (live)
// 0(%esp): d_aspancount, 4(%esp): d_zi, 8(%esp): d_light

//	do
//	{

LScanLoop:

//		d_pedgespanpackage->ptex = ptex;
//		d_pedgespanpackage->pdest = d_pdest;
//		d_pedgespanpackage->pz = d_pz;
//		d_pedgespanpackage->count = d_aspancount;
//		d_pedgespanpackage->light = d_light;
//		d_pedgespanpackage->zi = d_zi;
//		d_pedgespanpackage->sfrac = d_sfrac << 16;
//		d_pedgespanpackage->tfrac = d_tfrac << 16;
	movl	%ebx,spanpackage_t_ptex(%esi)
	movl	%edi,spanpackage_t_pdest(%esi)
	movl	%ebp,spanpackage_t_pz(%esi)
	movl	(%esp),%eax
	movl	%eax,spanpackage_t_count(%esi)
	movl	8(%esp),%eax
	movl	%eax,spanpackage_t_light(%esi)
	movl	4(%esp),%eax
	movl	%eax,spanpackage_t_zi(%esi)
	movl	%ecx,spanpackage_t_sfrac(%esi)
	movl	%edx,spanpackage_t_tfrac(%esi)

//		d_pedgespanpackage++;
	addl	$(spanpackage_t_size),%esi

// Last packaged row: Bresenham step is dead (caller re-inits or
// right-edge SetUpForLineScan).  Same pattern as Aff8 last-group skip.
	decw	%cx
	jz		LScanDone

//		errorterm += erroradjustup;
	movl	C(errorterm),%eax
	addl	C(erroradjustup),%eax

//		if (errorterm >= 0)
//		{
	js		LNoLeftEdgeTurnover

//			errorterm -= erroradjustdown;
//			d_pdest += d_pdestextrastep;
	subl	C(erroradjustdown),%eax
	movl	%eax,C(errorterm)
	addl	C(d_pdestextrastep),%edi

//			d_pz += d_pzextrastep;
//			d_aspancount += d_countextrastep;
//			d_ptex += d_ptexextrastep;
//			d_sfrac += d_sfracextrastep;
//			d_ptex += d_sfrac >> 16;
//			d_sfrac &= 0xFFFF;
//			d_tfrac += d_tfracextrastep;
	addl	C(d_pzextrastep),%ebp
	movl	C(d_countextrastep),%eax
	addl	%eax,(%esp)
	addl	C(d_sfracextrastep),%ecx
	adcl	C(d_ptexextrastep),%ebx
	addl	C(d_tfracextrastep),%edx

//			if (d_tfrac & 0x10000)
//			{
	jnc		LSkip1

//				d_ptex += r_affinetridesc.skinwidth;
//				d_tfrac &= 0xFFFF;
	addl	C(r_affinetridesc)+atd_skinwidth,%ebx

//			}

LSkip1:

//			d_light += d_lightextrastep;
//			d_zi += d_ziextrastep;
	movl	C(d_lightextrastep),%eax
	addl	%eax,8(%esp)
	movl	C(d_ziextrastep),%eax
	addl	%eax,4(%esp)

//		}
	jmp		LScanLoop

LScanDone:
	movl	(%esp),%eax
	movl	%eax,C(d_aspancount)
	movl	%esi,C(d_pedgespanpackage)
	addl	$12,%esp
	popl	%ebx
	popl	%edi
	popl	%esi
	popl	%ebp
	ret

//		else
//		{

LNoLeftEdgeTurnover:
	movl	%eax,C(errorterm)

//			d_pdest += d_pdestbasestep;
	addl	C(d_pdestbasestep),%edi

//			d_pz += d_pzbasestep;
//			d_aspancount += ubasestep;
//			d_ptex += d_ptexbasestep;
//			d_sfrac += d_sfracbasestep;
//			d_ptex += d_sfrac >> 16;
//			d_sfrac &= 0xFFFF;
	addl	C(d_pzbasestep),%ebp
	movl	C(ubasestep),%eax
	addl	%eax,(%esp)
	addl	C(d_sfracbasestep),%ecx
	adcl	C(d_ptexbasestep),%ebx

//			d_tfrac += d_tfracbasestep;
	addl	C(d_tfracbasestep),%edx

//			if (d_tfrac & 0x10000)
//			{
	jnc		LSkip2

//				d_ptex += r_affinetridesc.skinwidth;
//				d_tfrac &= 0xFFFF;
	addl	C(r_affinetridesc)+atd_skinwidth,%ebx

//			}

LSkip2:

//			d_light += d_lightbasestep;
//			d_zi += d_zibasestep;
	movl	C(d_lightbasestep),%eax
	addl	%eax,8(%esp)
	movl	C(d_zibasestep),%eax
	addl	%eax,4(%esp)

//		}
//	} while (--height);
	jmp		LScanLoop


//----------------------------------------------------------------------
// Alias model vertex drawing code
//----------------------------------------------------------------------

#define fv			4+8
#define	numverts	8+8

.globl C(D_PolysetDrawFinalVerts)
C(D_PolysetDrawFinalVerts):
	pushl	%ebp				// preserve caller stack frame pointer
	pushl	%ebx

//	int		i, z;
//	short	*zbuf;

	movl	numverts(%esp),%ecx
	movl	fv(%esp),%ebx

	pushl	%esi				// preserve register variables
	pushl	%edi
	movl	C(r_refdef)+rd_vrectright,%ebp
	movl	C(r_refdef)+rd_vrectbottom,%eax
	pushl	%eax				// clipbottom; vrectright stays in %ebp

LFVLoop:

//	for (i=0 ; i<numverts ; i++, fv++)
//	{
//	// valid triangle coordinates for filling can include the bottom and
//	// right clip edges, due to the fill rule; these shouldn't be drawn
//		if ((fv->v[0] < r_refdef.vrectright) &&
//			(fv->v[1] < r_refdef.vrectbottom))
//		{
	movl	fv_v+0(%ebx),%eax
	cmpl	%ebp,%eax
	jge		LNextVert
	movl	fv_v+4(%ebx),%esi
	cmpl	(%esp),%esi
	jge		LNextVert

//			zbuf = zspantable[fv->v[1]] + fv->v[0];
	movl	C(zspantable)(,%esi,4),%edi

//			z = fv->v[5]>>16;
	movl	fv_v+20(%ebx),%edx
	shrl	$16,%edx

//			if (z >= *zbuf)
//			{
//				int		pix;
	cmpw	(%edi,%eax,2),%dx
	jl		LNextVert

//				*zbuf = z;
	movw	%dx,(%edi,%eax,2)

//				pix = skintable[fv->v[3]>>16][fv->v[2]>>16];
	movl	fv_v+12(%ebx),%edi
	shrl	$16,%edi
	movl	C(skintable)(,%edi,4),%edi
	movl	fv_v+8(%ebx),%edx
	shrl	$16,%edx
	movzbl	(%edi,%edx),%edx

//				pix = ((byte *)acolormap)[pix + (fv->v[4] & 0xFF00)];
// Aff8-style: (light<<8)|texel via high byte of v[4] into %dh.
	movb	fv_v+16+1(%ebx),%dh
	movl	C(acolormap),%edi
	movb	(%edi,%edx,1),%dl

//				d_viewbuffer[d_scantable[fv->v[1]] + fv->v[0]] = pix;
	movl	C(viewspantable)(,%esi,4),%edi
	movb	%dl,(%edi,%eax)

//			}
//		}
//	}
LNextVert:
	addl	$(fv_size),%ebx
	decl	%ecx
	jnz		LFVLoop

	popl	%eax				// drop clipbottom
	popl	%edi
	popl	%esi
	popl	%ebx
	popl	%ebp
	ret


//----------------------------------------------------------------------
// Alias model non-subdivided polygon dispatching code
//
// not C-callable because of stack buffer cleanup
//----------------------------------------------------------------------

.globl C(D_DrawNonSubdiv)
C(D_DrawNonSubdiv):
	pushl	%ebp				// preserve caller stack frame pointer
	movl	C(r_affinetridesc)+atd_numtriangles,%ebp
	pushl	%ebx
	shll	$(mtri_shift),%ebp
	pushl	%esi				// preserve register variables
	movl	C(r_affinetridesc)+atd_ptriangles,%esi
	pushl	%edi

//	mtriangle_t		*ptri;
//	finalvert_t		*pfv, *index0, *index1, *index2;
//	int				i;
//	int				lnumtriangles;

//	pfv = r_affinetridesc.pfinalverts;
//	ptri = r_affinetridesc.ptriangles;
//	lnumtriangles = r_affinetridesc.numtriangles;

LNDLoop:

//	for (i=0 ; i<lnumtriangles ; i++, ptri++)
//	{
//		index0 = pfv + ptri->vertindex[0];
//		index1 = pfv + ptri->vertindex[1];
//		index2 = pfv + ptri->vertindex[2];
	movl	C(r_affinetridesc)+atd_pfinalverts,%edi
	movl	mtri_vertindex+0-mtri_size(%esi,%ebp,1),%ecx
	shll	$(fv_shift),%ecx
	movl	mtri_vertindex+4-mtri_size(%esi,%ebp,1),%edx
	shll	$(fv_shift),%edx
	movl	mtri_vertindex+8-mtri_size(%esi,%ebp,1),%ebx
	shll	$(fv_shift),%ebx
	addl	%edi,%ecx
	addl	%edi,%edx
	addl	%edi,%ebx

//		d_xdenom = (index0->v[1]-index1->v[1]) *
//				(index0->v[0]-index2->v[0]) -
//				(index0->v[0]-index1->v[0])*(index0->v[1]-index2->v[1]);
	movl	fv_v+4(%ecx),%eax
	movl	fv_v+0(%ecx),%esi
	subl	fv_v+4(%edx),%eax
	subl	fv_v+0(%ebx),%esi
	imull	%esi,%eax
	movl	fv_v+0(%ecx),%esi
	movl	fv_v+4(%ecx),%edi
	subl	fv_v+0(%edx),%esi
	subl	fv_v+4(%ebx),%edi
	imull	%esi,%edi
	subl	%edi,%eax

//		if (d_xdenom >= 0)
//		{
//			continue;
	jns		LNextTri

//		}

	movl	%eax,C(d_xdenom)
	movl	%eax,C(d_xdenom_int)
	fildl	C(d_xdenom)

//		r_p0[0] = index0->v[0];		// u
//		r_p0[1] = index0->v[1];		// v
//		r_p0[2] = index0->v[2];		// s
//		r_p0[3] = index0->v[3];		// t
//		r_p0[4] = index0->v[4];		// light
//		r_p0[5] = index0->v[5];		// iz
	movl	fv_v+0(%ecx),%eax
	movl	fv_v+4(%ecx),%esi
	movl	%eax,C(r_p0)+0
	movl	%esi,C(r_p0)+4
	movl	fv_v+8(%ecx),%eax
	movl	fv_v+12(%ecx),%esi
	movl	%eax,C(r_p0)+8
	movl	%esi,C(r_p0)+12
	movl	fv_v+16(%ecx),%eax
	movl	fv_v+20(%ecx),%esi
	movl	%eax,C(r_p0)+16
	movl	%esi,C(r_p0)+20

	fdivrs	float_1

//		r_p1[0] = index1->v[0];
//		r_p1[1] = index1->v[1];
//		r_p1[2] = index1->v[2];
//		r_p1[3] = index1->v[3];
//		r_p1[4] = index1->v[4];
//		r_p1[5] = index1->v[5];
	movl	fv_v+0(%edx),%eax
	movl	fv_v+4(%edx),%esi
	movl	%eax,C(r_p1)+0
	movl	%esi,C(r_p1)+4
	movl	fv_v+8(%edx),%eax
	movl	fv_v+12(%edx),%esi
	movl	%eax,C(r_p1)+8
	movl	%esi,C(r_p1)+12
	movl	fv_v+16(%edx),%eax
	movl	fv_v+20(%edx),%esi
	movl	%eax,C(r_p1)+16
	movl	%esi,C(r_p1)+20

//		r_p2[0] = index2->v[0];
//		r_p2[1] = index2->v[1];
//		r_p2[2] = index2->v[2];
//		r_p2[3] = index2->v[3];
//		r_p2[4] = index2->v[4];
//		r_p2[5] = index2->v[5];
	movl	fv_v+0(%ebx),%eax
	movl	fv_v+4(%ebx),%esi
	movl	%eax,C(r_p2)+0
	movl	%esi,C(r_p2)+4
	movl	fv_v+8(%ebx),%eax
	movl	fv_v+12(%ebx),%esi
	movl	%eax,C(r_p2)+8
	movl	%esi,C(r_p2)+12
	movl	fv_v+16(%ebx),%eax
	movl	fv_v+20(%ebx),%esi
	movl	%eax,C(r_p2)+16
	movl	C(r_affinetridesc)+atd_ptriangles,%edi
	movl	%esi,C(r_p2)+20
	movl	mtri_facesfront-mtri_size(%edi,%ebp,1),%eax

//		if (!ptri->facesfront)
//		{
	testl	%eax,%eax
	jnz		LFacesFront

//			if (index0->flags & ALIAS_ONSEAM)
//				r_p0[2] += r_affinetridesc.seamfixupX16;
	movl	fv_flags(%ecx),%eax
	movl	fv_flags(%edx),%esi
	movl	fv_flags(%ebx),%edi
	testl	$(ALIAS_ONSEAM),%eax
	movl	C(r_affinetridesc)+atd_seamfixupX16,%eax
	jz		LOnseamDone0
	addl	%eax,C(r_p0)+8
LOnseamDone0:

//			if (index1->flags & ALIAS_ONSEAM)
// 				r_p1[2] += r_affinetridesc.seamfixupX16;
	testl	$(ALIAS_ONSEAM),%esi
	jz		LOnseamDone1
	addl	%eax,C(r_p1)+8
LOnseamDone1:

//			if (index2->flags & ALIAS_ONSEAM)
//				r_p2[2] += r_affinetridesc.seamfixupX16;
	testl	$(ALIAS_ONSEAM),%edi
	jz		LOnseamDone2
	addl	%eax,C(r_p2)+8
LOnseamDone2:

//		}

LFacesFront:

	fstps	C(d_xdenom)

//		D_PolysetSetEdgeTable ();
//		D_RasterizeAliasPolySmooth ();
		call	C(D_PolysetSetEdgeTable)
		call	C(D_RasterizeAliasPolySmooth)

LNextTri:
		movl	C(r_affinetridesc)+atd_ptriangles,%esi
		subl	$16,%ebp
		jnz		LNDLoop
//	}

	popl	%edi
	popl	%esi
	popl	%ebx
	popl	%ebp

	addl	$(SPAN_SIZE),%esp

	ret


// Select the original edgetables[] entry from the three already-ordered
// screen-space Y coordinates. The equal-Y cases deliberately keep the
// original hand-written table choices from D_PolysetSetEdgeTable_C.
.globl C(D_PolysetSetEdgeTable_asm486)
C(D_PolysetSetEdgeTable_asm486):
	movl	C(r_p0)+4,%eax
	movl	C(r_p1)+4,%ecx
	xorl	%edx,%edx
	cmpl	%ecx,%eax
	jl	.LAliasEdgeY01Ready
	je	.LAliasEdgeY01Equal
	movl	$1,%edx
	jmp	.LAliasEdgeCompareY2

.LAliasEdgeY01Equal:
	cmpl	C(r_p2)+4,%eax
	jl	.LAliasEdgeEqualTop
	movl	$5,%edx
	jmp	.LAliasEdgeStore
.LAliasEdgeEqualTop:
	movl	$2,%edx
	jmp	.LAliasEdgeStore

.LAliasEdgeY01Ready:
.LAliasEdgeCompareY2:
	cmpl	C(r_p2)+4,%eax
	jne	.LAliasEdgeCheckY12
	testl	%edx,%edx
	jz	.LAliasEdgeY02NoIndex
	movl	$8,%edx
	jmp	.LAliasEdgeStore
.LAliasEdgeY02NoIndex:
	movl	$9,%edx
	jmp	.LAliasEdgeStore

.LAliasEdgeCheckY12:
	cmpl	C(r_p2)+4,%ecx
	jne	.LAliasEdgeDistinct
	testl	%edx,%edx
	jz	.LAliasEdgeY12NoIndex
	movl	$10,%edx
	jmp	.LAliasEdgeStore
.LAliasEdgeY12NoIndex:
	movl	$11,%edx
	jmp	.LAliasEdgeStore

.LAliasEdgeDistinct:
	cmpl	C(r_p2)+4,%eax
	jle	.LAliasEdgeY02Ordered
	addl	$2,%edx
.LAliasEdgeY02Ordered:
	cmpl	C(r_p2)+4,%ecx
	jle	.LAliasEdgeStore
	addl	$4,%edx

.LAliasEdgeStore:
	leal	(%edx,%edx,8),%eax
	leal	C(edgetables)(,%eax,4),%eax
	movl	%eax,C(pedgetable)
	ret


// Rebuild the 480-row skin pointer table only when either part of its cache
// key changes. This preserves D_PolysetUpdateTables_C's byte-stride layout.
.globl C(D_PolysetUpdateTables_asm486)
C(D_PolysetUpdateTables_asm486):
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	movl	C(r_affinetridesc)+atd_skinwidth,%ecx
	movl	C(r_affinetridesc)+atd_pskin,%eax
	cmpl	C(skinwidth),%ecx
	jne	.LAliasSkinTableRebuild
	cmpl	C(skinstart),%eax
	je	.LAliasSkinTableDone

.LAliasSkinTableRebuild:
	movl	%ecx,C(skinwidth)
	movl	%eax,C(skinstart)
	movl	%eax,%ebx
	movl	$C(skintable),%esi
	movl	$480,%edi

.LAliasSkinTableLoop:
	movl	%ebx,(%esi)
	addl	%ecx,%ebx
	addl	$4,%esi
	decl	%edi
	jnz	.LAliasSkinTableLoop

.LAliasSkinTableDone:
	popl	%edi
	popl	%esi
	popl	%ebx
	ret


// Assemble the C-owned triangle rasterization glue. Vertex arrays are six
// 32-bit values (x, y, s, t, light, zi); edgetable_t is the original 36-byte
// layout. This routine preserves that setup order and delegates only gradient,
// line-scan, left-edge span emission, and span drawing to their existing paths.
.macro ALIAS_STORE_SPAN_PACKAGE
	movl	C(d_pedgespanpackage),%eax
	movl	C(d_pdest),%ecx
	movl	%ecx,spanpackage_t_pdest(%eax)
	movl	C(d_pz),%ecx
	movl	%ecx,spanpackage_t_pz(%eax)
	movl	C(d_aspancount),%ecx
	movl	%ecx,spanpackage_t_count(%eax)
	movl	C(d_ptex),%ecx
	movl	%ecx,spanpackage_t_ptex(%eax)
	movl	C(d_sfrac),%ecx
	movl	%ecx,spanpackage_t_sfrac(%eax)
	movl	C(d_tfrac),%ecx
	movl	%ecx,spanpackage_t_tfrac(%eax)
	movl	C(d_light),%ecx
	movl	%ecx,spanpackage_t_light(%eax)
	movl	C(d_zi),%ecx
	movl	%ecx,spanpackage_t_zi(%eax)
	addl	$spanpackage_t_size,%eax
	movl	%eax,C(d_pedgespanpackage)
.endm

.macro ALIAS_CALL_LINE_SCAN topoff, bottomoff
	movl	\bottomoff(%ebp),%ecx
	pushl	4(%ecx)
	pushl	(%ecx)
	movl	\topoff(%ebp),%eax
	pushl	4(%eax)
	pushl	(%eax)
	call	C(D_PolysetSetUpForLineScan)
	addl	$16,%esp
.endm

.macro ALIAS_CALL_SCAN_LEFT heightoff
	pushl	\heightoff(%ebp)
#ifdef PROFILE486
	call	C(D_PolysetScanLeftEdgeProfiled)
#else
	call	C(D_PolysetScanLeftEdge)
#endif
	addl	$4,%esp
.endm

.macro ALIAS_SET_LEFT_EDGE_STEPS
	// Depth rows are 16-bit pixels in the 386 renderer: one base step is two
	// bytes per scanline and the extra step advances one additional pixel.
	movl	C(d_zwidth),%eax
	addl	C(ubasestep),%eax
	shll	$1,%eax
	movl	%eax,C(d_pzbasestep)
	addl	$2,%eax
	movl	%eax,C(d_pzextrastep)

	movl	C(screenwidth),%eax
	addl	C(ubasestep),%eax
	movl	%eax,C(d_pdestbasestep)
	addl	$1,%eax
	movl	%eax,C(d_pdestextrastep)

	movl	C(r_lstepx),%eax
	cmpl	$0,C(ubasestep)
	jge	.LAliasRasterLightStepReady\@
	decl	%eax
.LAliasRasterLightStepReady\@:
	movl	%eax,-40(%ebp)

	movl	C(r_affinetridesc)+atd_skinwidth,%eax
	movl	%eax,-48(%ebp)
	movl	C(ubasestep),%ecx
	movl	C(r_sstepx),%eax
	imull	%ecx,%eax
	addl	C(r_sstepy),%eax
	movl	%eax,-52(%ebp)
	movl	C(r_tstepx),%eax
	imull	%ecx,%eax
	addl	C(r_tstepy),%eax
	movl	%eax,-56(%ebp)

	leal	1(%ecx),%eax
	movl	%eax,C(d_countextrastep)

	movl	-56(%ebp),%eax
	sarl	$16,%eax
	imull	-48(%ebp),%eax
	movl	-52(%ebp),%edx
	sarl	$16,%edx
	addl	%edx,%eax
	movl	%eax,C(d_ptexbasestep)

	movl	-52(%ebp),%eax
	shll	$16,%eax
	movl	%eax,C(d_sfracbasestep)
	movl	-56(%ebp),%eax
	shll	$16,%eax
	movl	%eax,C(d_tfracbasestep)

	movl	-40(%ebp),%eax
	imull	C(ubasestep),%eax
	addl	C(r_lstepy),%eax
	movl	%eax,C(d_lightbasestep)
	movl	C(r_zistepx),%eax
	imull	C(ubasestep),%eax
	addl	C(r_zistepy),%eax
	movl	%eax,C(d_zibasestep)

	movl	-52(%ebp),%eax
	addl	C(r_sstepx),%eax
	movl	%eax,-60(%ebp)
	movl	-56(%ebp),%eax
	addl	C(r_tstepx),%eax
	movl	%eax,-64(%ebp)
	movl	-64(%ebp),%eax
	sarl	$16,%eax
	imull	-48(%ebp),%eax
	movl	-60(%ebp),%edx
	sarl	$16,%edx
	addl	%edx,%eax
	movl	%eax,C(d_ptexextrastep)

	movl	-60(%ebp),%eax
	shll	$16,%eax
	movl	%eax,C(d_sfracextrastep)
	movl	-64(%ebp),%eax
	shll	$16,%eax
	movl	%eax,C(d_tfracextrastep)
	movl	C(d_lightbasestep),%eax
	addl	-40(%ebp),%eax
	movl	%eax,C(d_lightextrastep)
	movl	C(d_zibasestep),%eax
	addl	C(r_zistepx),%eax
	movl	%eax,C(d_ziextrastep)
.endm

.globl C(D_RasterizeAliasPolySmooth_asm486)
C(D_RasterizeAliasPolySmooth_asm486):
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	subl	$60,%esp

	// locals: left height -16, right height -20, left top -24, right top -28,
	// left bottom -32, right bottom -36, working light step -40,
	// original right count -44, skin width -48, s/t base -52/-56,
	// s/t extra -60/-64, edge height -68, span start -72.
	// These triangle-constant pointers survive the cdecl helpers below.
	movl	C(pedgetable),%esi
	movl	C(a_spans),%ebx
	movl	8(%esi),%eax
	movl	%eax,-24(%ebp)
	movl	24(%esi),%eax
	movl	%eax,-28(%ebp)
	movl	12(%esi),%eax
	movl	%eax,-32(%ebp)
	movl	28(%esi),%eax
	movl	%eax,-36(%ebp)
	movl	-32(%ebp),%eax
	movl	-24(%ebp),%ecx
	movl	4(%eax),%edx
	subl	4(%ecx),%edx
	movl	%edx,-16(%ebp)
	movl	-36(%ebp),%eax
	movl	-28(%ebp),%ecx
	movl	4(%eax),%edx
	subl	4(%ecx),%edx
	movl	%edx,-20(%ebp)

	// Gradients are shared by all three edges of the triangle.
#ifdef PROFILE486
	pushl	C(r_affinetridesc)+atd_skinwidth
	call	C(D_PolysetCalcGradientsProfiled)
#else
	pushl	C(r_affinetridesc)+atd_skinwidth
	call	C(D_PolysetCalcGradients)
#endif
	addl	$4,%esp

	// Top (or only) left edge: initialize the first span package.
	movl	%ebx,%eax
	movl	%eax,C(d_pedgespanpackage)
	movl	-24(%ebp),%edi
	movl	4(%edi),%eax
	movl	%eax,-68(%ebp)
	movl	%eax,%ecx
	movl	-28(%ebp),%edx
	movl	(%edi),%eax
	subl	(%edx),%eax
	movl	%eax,C(d_aspancount)

	movl	C(r_affinetridesc)+atd_skinwidth,%ecx
	movl	8(%edi),%eax
	sarl	$16,%eax
	movl	12(%edi),%edx
	sarl	$16,%edx
	imull	%ecx,%edx
	addl	%edx,%eax
	addl	C(r_affinetridesc)+atd_pskin,%eax
	movl	%eax,C(d_ptex)

	movl	8(%edi),%eax
	shll	$16,%eax
	movl	%eax,C(d_sfrac)
	movl	12(%edi),%eax
	shll	$16,%eax
	movl	%eax,C(d_tfrac)
	movl	16(%edi),%eax
	movl	%eax,C(d_light)
	movl	20(%edi),%eax
	movl	%eax,C(d_zi)

	movl	-68(%ebp),%eax
	movl	C(viewspantable)(,%eax,4),%ecx
	movl	(%edi),%edx
	leal	(%ecx,%edx),%ecx
	movl	%ecx,C(d_pdest)
	movl	C(zspantable)(,%eax,4),%ecx
	leal	(%ecx,%edx,2),%ecx
	movl	%ecx,C(d_pz)

	cmpl	$1,-16(%ebp)
	jne	.LAliasRasterLeftTopWalk
	ALIAS_STORE_SPAN_PACKAGE
	jmp	.LAliasRasterLeftBottom

.LAliasRasterLeftTopWalk:
	ALIAS_CALL_LINE_SCAN -24,-32
	ALIAS_SET_LEFT_EDGE_STEPS
	ALIAS_CALL_SCAN_LEFT -16

.LAliasRasterLeftBottom:
	cmpl	$2,4(%esi)
	jne	.LAliasRasterRightTop
	movl	-32(%ebp),%eax
	movl	%eax,-24(%ebp)
	movl	16(%esi),%eax
	movl	%eax,-32(%ebp)
	movl	-32(%ebp),%eax
	movl	-24(%ebp),%ecx
	movl	4(%eax),%edx
	subl	4(%ecx),%edx
	movl	%edx,-68(%ebp)

	// The C reference starts this lower segment with zero S/T fraction.
	movl	-24(%ebp),%edi
	movl	4(%edi),%eax
	movl	%eax,-72(%ebp)
	movl	-28(%ebp),%edx
	movl	(%edi),%eax
	subl	(%edx),%eax
	movl	%eax,C(d_aspancount)
	movl	C(r_affinetridesc)+atd_skinwidth,%ecx
	movl	8(%edi),%eax
	sarl	$16,%eax
	movl	12(%edi),%edx
	sarl	$16,%edx
	imull	%ecx,%edx
	addl	%edx,%eax
	addl	C(r_affinetridesc)+atd_pskin,%eax
	movl	%eax,C(d_ptex)
	movl	$0,C(d_sfrac)
	movl	$0,C(d_tfrac)
	movl	16(%edi),%eax
	movl	%eax,C(d_light)
	movl	20(%edi),%eax
	movl	%eax,C(d_zi)
	movl	-72(%ebp),%eax
	movl	C(viewspantable)(,%eax,4),%ecx
	movl	(%edi),%edx
	leal	(%ecx,%edx),%ecx
	movl	%ecx,C(d_pdest)
	movl	C(zspantable)(,%eax,4),%ecx
	leal	(%ecx,%edx,2),%ecx
	movl	%ecx,C(d_pz)

	cmpl	$1,-68(%ebp)
	jne	.LAliasRasterLeftBottomWalk
	ALIAS_STORE_SPAN_PACKAGE
	jmp	.LAliasRasterRightTop

.LAliasRasterLeftBottomWalk:
	ALIAS_CALL_LINE_SCAN -24,-32
	ALIAS_SET_LEFT_EDGE_STEPS
	ALIAS_CALL_SCAN_LEFT -68

.LAliasRasterRightTop:
	movl	%ebx,%eax
	movl	%eax,C(d_pedgespanpackage)
	ALIAS_CALL_LINE_SCAN -28,-36
	movl	$0,C(d_aspancount)
	movl	C(ubasestep),%eax
	incl	%eax
	movl	%eax,C(d_countextrastep)

	movl	%ebx,%eax
	movl	-20(%ebp),%ecx
	shll	$5,%ecx
	addl	%ecx,%eax
	movl	spanpackage_t_count(%eax),%edx
	movl	%edx,-44(%ebp)
	movl	$-999999,spanpackage_t_count(%eax)
#ifdef PROFILE486
	pushl	%ebx
	call	C(D_PolysetDrawSpansProfiled)
#else
	pushl	%ebx
	call	C(D_PolysetDrawSpans8)
#endif
	addl	$4,%esp

	// Optional lower right edge starts at the saved top-edge span count.
	cmpl	$2,20(%esi)
	jne	.LAliasRasterDone
	movl	%ebx,%eax
	movl	-20(%ebp),%ecx
	shll	$5,%ecx
	addl	%ecx,%eax
	movl	%eax,-72(%ebp)
	movl	-44(%ebp),%edx
	movl	%edx,spanpackage_t_count(%eax)

	movl	-36(%ebp),%edx
	movl	-28(%ebp),%eax
	movl	(%edx),%ecx
	subl	(%eax),%ecx
	movl	%ecx,C(d_aspancount)
	movl	%edx,-28(%ebp)
	movl	32(%esi),%eax
	movl	%eax,-36(%ebp)
	movl	-36(%ebp),%eax
	movl	-28(%ebp),%ecx
	movl	4(%eax),%edx
	subl	4(%ecx),%edx
	movl	%edx,-68(%ebp)

	ALIAS_CALL_LINE_SCAN -28,-36
	movl	C(ubasestep),%eax
	incl	%eax
	movl	%eax,C(d_countextrastep)
	movl	%ebx,%eax
	movl	-20(%ebp),%ecx
	addl	-68(%ebp),%ecx
	shll	$5,%ecx
	addl	%ecx,%eax
	movl	$-999999,spanpackage_t_count(%eax)
#ifdef PROFILE486
	pushl	-72(%ebp)
	call	C(D_PolysetDrawSpansProfiled)
#else
	pushl	-72(%ebp)
	call	C(D_PolysetDrawSpans8)
#endif
	addl	$4,%esp

.LAliasRasterDone:
	addl	$60,%esp
	popl	%edi
	popl	%esi
	popl	%ebx
	leave
	ret


#endif	// id386
