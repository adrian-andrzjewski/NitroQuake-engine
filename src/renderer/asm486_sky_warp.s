/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
// asm486_sky_warp.s
// Sky-span and underwater screen-warp routines.

#include "asm_i386.h"
#include "renderer/d_ifacea.h"
#include "renderer/asm_draw.h"

#if defined(ASM486_WARP_SCREEN) || defined(ASM486_SKY_SPAN)
	.extern C(vid)
#endif

#ifdef ASM486_WARP_SCREEN
	.extern C(r_refdef)
	.extern C(scr_vrect)
	.extern C(d_viewbuffer)
	.extern C(screenwidth)
	.extern C(cl)
	.extern C(intsintable)
#endif
#ifdef ASM486_SKY_SPAN
	.extern C(r_skysource)
	.extern C(screenwidth)
	.extern C(d_viewbuffer)
	.extern C(r_refdef)
	.extern C(skytime)
	.extern C(skyspeed)
	.extern C(vpn)
	.extern C(vright)
	.extern C(vup)
#endif

.data
	.align 1

#ifdef ASM486_SKY_SPAN
Lsky_8192:
	.float	8192.0
Lsky_4096:
	.float	4096.0
Lsky_three:
	.float	3.0
Lsky_378:
	.float	378.0
Lsky_65536:
	.float	65536.0
#endif
#ifdef ASM486_WARP_SCREEN
	.p2align 2
Lwarp_speed:
	.float	20.0
#endif

	.text

#ifdef ASM486_SKY_SPAN
	.p2align 4,,15
// void D_SkyDrawPixels_asm486(byte *source, byte *dest, int count,
//                             int s, int t, int sstep, int tstep)
// The sky source is 128 columns by 256 rows. The C masks and shifts are
// asserted in d_sky.c; this routine preserves their signed 32-bit stepping.
C(D_SkyDrawPixels_asm486):
	.globl C(D_SkyDrawPixels_asm486)
	pushl	%ebx
	pushl	%ebp
	pushl	%esi
	pushl	%edi
	movl	20(%esp),%ebp		// 128x256 source
	movl	24(%esp),%edx		// destination
	movl	28(%esp),%ecx		// pixel count
	testl	%ecx,%ecx
	jle	.Lsky_span_done
	leal	(%edx,%ecx),%edi	// one-past-the-end pointer
	movl	32(%esp),%ebx		// s
	movl	36(%esp),%esi		// t

.Lsky_span_pixel:
	movl	%esi,%eax
	shrl	$8,%eax
	andl	$0x00007f00,%eax
	movl	%ebx,%ecx
	shrl	$16,%ecx
	andl	$0x0000007f,%ecx
	orl	%ecx,%eax
	movb	(%ebp,%eax),%al
	movb	%al,(%edx)
	incl	%edx
	addl	40(%esp),%ebx
	addl	44(%esp),%esi
	cmpl	%edi,%edx
	jne	.Lsky_span_pixel

.Lsky_span_done:
	popl	%edi
	popl	%esi
	popl	%ebp
	popl	%ebx
	ret

.p2align 4,,15
// float D_SkyVectorNormalize_asm486(float *v)
// Mirrors VectorNormalize's x87 instruction order, without calling C/libm.
C(D_SkyVectorNormalize_asm486):
	.globl C(D_SkyVectorNormalize_asm486)
	movl	4(%esp),%edx
	flds	(%edx)
	flds	4(%edx)
	flds	8(%edx)
	fld	%st(2)
	fmul	%st(3),%st
	fld	%st(2)
	fmul	%st(3),%st
	faddp	%st,%st(1)
	fld	%st(1)
	fmul	%st(2),%st
	faddp	%st,%st(1)
	fsqrt
	ftst
	fnstsw	%ax
	testb	$0x40,%ah
	jne	.Lsky_norm_zero
	fld1
	fdiv	%st(1),%st
	fmul	%st,%st(4)
	fxch	%st(4)
	fstps	(%edx)
	fxch	%st(2)
	fmul	%st(3),%st
	fstps	4(%edx)
	fmulp	%st,%st(2)
	fxch	%st(1)
	fstps	8(%edx)
	ret
.Lsky_norm_zero:
	fstp	%st(2)
	fstp	%st
	fstp	%st(1)
	ret

	.p2align 4,,15
// void D_SkyUVToST_asm486(int u, int v, float sky_temp,
//                         float skytime_offset, int *s, int *t)
// The x87 sequence follows the C reference; the normalizer above is its
// assembly dependency and preserves the C function's extended precision.
C(D_SkyUVToST_asm486):
	.globl C(D_SkyUVToST_asm486)
	subl	$0x38,%esp
	flds	0x44(%esp)			// sky_temp
	movl	C(vid)+20,%edx
	sarl	$1,%edx
	movl	0x3c(%esp),%eax		// u
	subl	%edx,%eax
	movl	%eax,0x14(%esp)
	fildl	0x14(%esp)
	flds	Lsky_8192
	fmul	%st,%st(1)
	fxch	%st(1)
	fdiv	%st(2),%st
	movl	C(vid)+24,%ecx
	sarl	$1,%ecx
	subl	0x40(%esp),%ecx		// v
	movl	%ecx,0x14(%esp)
	fildl	0x14(%esp)
	fmulp	%st,%st(2)
	fxch	%st(1)
	fdivp	%st,%st(2)
	flds	Lsky_4096
	flds	C(vpn)
	fmul	%st(1),%st
	flds	C(vup)
	fmul	%st(4),%st
	faddp	%st,%st(1)
	flds	C(vright)
	fmul	%st(3),%st
	faddp	%st,%st(1)
	fstps	0x20(%esp)			// end[0]
	flds	C(vpn)+4
	fmul	%st(1),%st
	flds	C(vup)+4
	fmul	%st(4),%st
	faddp	%st,%st(1)
	flds	C(vright)+4
	fmul	%st(3),%st
	faddp	%st,%st(1)
	fstps	0x24(%esp)			// end[1]
	fmuls	C(vpn)+8
	fxch	%st(2)
	fmuls	C(vup)+8
	faddp	%st,%st(2)
	fmuls	C(vright)+8
	faddp	%st,%st(1)
	fmuls	Lsky_three
	fstps	0x28(%esp)			// end[2]
	leal	0x20(%esp),%edx
	pushl	%edx
	call	C(D_SkyVectorNormalize_asm486)
	fstp	%st(0)
	flds	Lsky_378
	flds	0x24(%esp)			// normalized end[0] after stack argument push
	fmul	%st(1),%st
	fadds	0x4c(%esp)			// skytime_offset (arg shifts with push)
	flds	Lsky_65536
	fmul	%st,%st(1)
	fxch	%st(1)
	fnstcw	0x1e(%esp)
	movw	0x1e(%esp),%ax
	orb	$0x0c,%ah
	movw	%ax,0x1c(%esp)
	movl	0x50(%esp),%ecx		// s output
	fldcw	0x1c(%esp)
	fistpl	(%ecx)
	fldcw	0x1e(%esp)
	fxch	%st(1)
	fmuls	0x28(%esp)			// normalized end[1]
	fadds	0x4c(%esp)
	fmulp	%st,%st(1)
	movl	0x54(%esp),%edx		// t output
	fldcw	0x1c(%esp)
	fistpl	(%edx)
	fldcw	0x1e(%esp)
	addl	$0x3c,%esp			// locals and pushed VectorNormalize argument
	ret

	.p2align 4,,15
// void D_DrawSkyScans8(espan_t *pspan)
// Full scan conversion, including UV projection and sky-phase setup, is in
// assembly. The C scan and UV functions remain benchmark references.
C(D_DrawSkyScans8):
	.globl C(D_DrawSkyScans8)
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	subl	$56,%esp
	movl	8(%ebp),%eax
	movl	%eax,-16(%ebp)		// current espan
	movl	C(r_refdef)+8,%eax		// viewport width
	movl	C(r_refdef)+12,%ecx		// viewport height
	cmpl	%ecx,%eax
	jge	.Lsky_scan_temp_ready
	movl	%ecx,%eax
.Lsky_scan_temp_ready:
	movl	%eax,-64(%ebp)
	fildl	-64(%ebp)
	fstps	-64(%ebp)			// sky_temp as float
	flds	C(skytime)
	fmuls	C(skyspeed)
	fstps	-68(%ebp)			// skytime_offset as float

.Lsky_scan_span:
	movl	-16(%ebp),%ebx
	movzwl	espan_t_u(%ebx),%eax
	movl	%eax,-28(%ebp)		// u
	movzwl	espan_t_v(%ebx),%eax
	movl	%eax,-32(%ebp)		// v
	movl	espan_t_count(%ebx),%eax
	movl	%eax,-20(%ebp)		// remaining count

	// pdest = d_viewbuffer + screenwidth*v + u
	movl	-32(%ebp),%eax
	movl	C(screenwidth),%ecx
	mull	%ecx
	addl	C(d_viewbuffer),%eax
	addl	-28(%ebp),%eax
	movl	%eax,-36(%ebp)

	// Initial texture coordinate at the first span sample.
	leal	-44(%ebp),%eax		// t output (last cdecl argument)
	pushl	%eax
	leal	-40(%ebp),%eax		// s output
	pushl	%eax
	pushl	-68(%ebp)			// skytime_offset
	pushl	-64(%ebp)			// sky_temp
	pushl	-32(%ebp)			// v
	pushl	-28(%ebp)			// u
	call	C(D_SkyUVToST_asm486)
	addl	$24,%esp

.Lsky_scan_chunk:
	movl	-20(%ebp),%eax
	cmpl	$32,%eax
	jge	.Lsky_scan_chunk32
	movl	%eax,-24(%ebp)		// spancount = count
	jmp	.Lsky_scan_chunk_ready
.Lsky_scan_chunk32:
	movl	$32,-24(%ebp)
.Lsky_scan_chunk_ready:
	subl	-24(%ebp),%eax
	movl	%eax,-20(%ebp)		// count -= spancount
	testl	%eax,%eax
	jz	.Lsky_scan_last_chunk

	// Calculate the 32-pixel endpoint, then use the C arithmetic shift step.
	movl	-28(%ebp),%eax
	addl	-24(%ebp),%eax
	movl	%eax,-28(%ebp)
	leal	-52(%ebp),%eax		// tnext output (last cdecl argument)
	pushl	%eax
	leal	-48(%ebp),%eax		// snext output
	pushl	%eax
	pushl	-68(%ebp)
	pushl	-64(%ebp)
	pushl	-32(%ebp)
	pushl	-28(%ebp)
	call	C(D_SkyUVToST_asm486)
	addl	$24,%esp
	movl	-48(%ebp),%eax
	subl	-40(%ebp),%eax
	sarl	$5,%eax
	movl	%eax,-56(%ebp)		// sstep
	movl	-52(%ebp),%eax
	subl	-44(%ebp),%eax
	sarl	$5,%eax
	movl	%eax,-60(%ebp)		// tstep
	jmp	.Lsky_scan_draw_chunk

.Lsky_scan_last_chunk:
	movl	-24(%ebp),%edi
	decl	%edi				// spancountminus1
	testl	%edi,%edi
	jle	.Lsky_scan_single_pixel
	movl	-28(%ebp),%eax
	addl	%edi,%eax
	movl	%eax,-28(%ebp)
	leal	-52(%ebp),%eax
	pushl	%eax
	leal	-48(%ebp),%eax
	pushl	%eax
	pushl	-68(%ebp)
	pushl	-64(%ebp)
	pushl	-32(%ebp)
	pushl	-28(%ebp)
	call	C(D_SkyUVToST_asm486)
	addl	$24,%esp
	movl	-48(%ebp),%eax
	subl	-40(%ebp),%eax
	cdq
	idivl	%edi
	movl	%eax,-56(%ebp)
	movl	-52(%ebp),%eax
	subl	-44(%ebp),%eax
	cdq
	idivl	%edi
	movl	%eax,-60(%ebp)
	jmp	.Lsky_scan_draw_chunk
.Lsky_scan_single_pixel:
	movl	-40(%ebp),%eax
	movl	%eax,-48(%ebp)
	movl	-44(%ebp),%eax
	movl	%eax,-52(%ebp)
	xorl	%eax,%eax
	movl	%eax,-56(%ebp)
	movl	%eax,-60(%ebp)

.Lsky_scan_draw_chunk:
	movl	C(r_skysource),%ebx
	movl	-36(%ebp),%esi
	movl	-24(%ebp),%edi
.Lsky_scan_pixel:
	movl	-44(%ebp),%eax
	shrl	$8,%eax
	andl	$0x00007f00,%eax
	movl	-40(%ebp),%edx
	shrl	$16,%edx
	andl	$0x0000007f,%edx
	addl	%edx,%eax
	movb	(%ebx,%eax),%al
	movb	%al,(%esi)
	incl	%esi
	movl	-40(%ebp),%eax
	addl	-56(%ebp),%eax
	movl	%eax,-40(%ebp)
	movl	-44(%ebp),%eax
	addl	-60(%ebp),%eax
	movl	%eax,-44(%ebp)
	decl	%edi
	jnz	.Lsky_scan_pixel
	movl	%esi,-36(%ebp)
	movl	-48(%ebp),%eax
	movl	%eax,-40(%ebp)
	movl	-52(%ebp),%eax
	movl	%eax,-44(%ebp)
	cmpl	$0,-20(%ebp)
	jg	.Lsky_scan_chunk

	movl	-16(%ebp),%eax
	movl	espan_t_pnext(%eax),%eax	// pnext
	movl	%eax,-16(%ebp)
	testl	%eax,%eax
	jnz	.Lsky_scan_span

	addl	$56,%esp
	popl	%edi
	popl	%esi
	popl	%ebx
	popl	%ebp
	ret
#endif

#ifdef ASM486_WARP_SCREEN
	.p2align 4,,15
// void D_WarpBuildTables_asm486(byte **rowptr, int *column,
//                               byte *viewbase, int screenwidth,
//                               int rowcount, int colcount, int h, int w,
//                               int hdenominator, int wdenominator,
//                               int x_origin, float hratio, float wratio)
// Build the row and column lookup tables with the same x87 operation order
// and truncating float-to-int conversion as D_WarpScreen's C loops.
C(D_WarpBuildTables_asm486):
	.globl C(D_WarpBuildTables_asm486)
	pushl	%ebx
	pushl	%ebp
	pushl	%esi
	pushl	%edi
	subl	$16,%esp

	fnstcw	0(%esp)
	movw	0(%esp),%dx
	orw	$0x0c00,%dx
	movw	%dx,2(%esp)
	movl	36(%esp),%ebp		// row pointer table
	movl	44(%esp),%edi		// top row of the unwarped view
	xorl	%ebx,%ebx			// row index v
	movl	52(%esp),%ecx		// rowcount
	testl	%ecx,%ecx
	jle	.Lwarp_tables_columns
	flds	80(%esp)			// hratio
	fimull	60(%esp)			// fold h into the per-row scale, as C does
	fidivl	68(%esp)			// divide by h + AMP2*2 before the loop

.Lwarp_tables_row:
	fld	%st(0)			// retain the scaled factor across iterations
	movl	%ebx,8(%esp)
	fildl	8(%esp)
	fmulp	%st,%st(1)		// row index * scaled factor
	fldcw	2(%esp)
	fistpl	4(%esp)			// truncate like the C cast
	 fldcw	0(%esp)
	 movl	4(%esp),%eax
	movl	48(%esp),%ecx
	mull	%ecx				// screenwidth * row offset (486 MUL)
	addl	%edi,%eax
	movl	%eax,(%ebp,%ebx,4)
	incl	%ebx
	cmpl	52(%esp),%ebx
	jl	.Lwarp_tables_row
	fstp	%st(0)			// release the retained factor

.Lwarp_tables_columns:
	movl	40(%esp),%ebp		// column table
	xorl	%ebx,%ebx			// column index u
	movl	56(%esp),%ecx		// colcount
	testl	%ecx,%ecx
	jle	.Lwarp_tables_done
	flds	84(%esp)			// wratio
	fimull	64(%esp)			// fold w into the per-column scale
	fidivl	72(%esp)			// divide by w + AMP2*2 before the loop

.Lwarp_tables_column:
	fld	%st(0)
	movl	%ebx,8(%esp)
	fildl	8(%esp)
	fmulp	%st,%st(1)		// column index * scaled factor
	fldcw	2(%esp)
	fistpl	4(%esp)
	fldcw	0(%esp)
	movl	76(%esp),%eax		// x origin
	addl	4(%esp),%eax
	movl	%eax,(%ebp,%ebx,4)
	incl	%ebx
	cmpl	56(%esp),%ebx
	jl	.Lwarp_tables_column
	fstp	%st(0)			// release the retained factor

.Lwarp_tables_done:
	addl	$16,%esp
	popl	%edi
	popl	%esi
	popl	%ebp
	popl	%ebx
	ret

	.p2align 4,,15
// void D_WarpPixels_asm486(byte *dest, byte **rowptr, int *column,
//                          int *turb, int width, int height, int rowbytes)
// Copy the four pixels in each D_WarpScreen C iteration. Warp table creation
// and floating-point coordinate setup remain in C.
C(D_WarpPixels_asm486):
	.globl C(D_WarpPixels_asm486)
	pushl	%ebx
	pushl	%ebp
	pushl	%esi
	pushl	%edi
	subl	$16,%esp
	movl	36(%esp),%edi		// destination
	movl	40(%esp),%ebp		// row pointer table at row zero
	movl	44(%esp),%eax		// column table
	movl	%eax,8(%esp)
	movl	48(%esp),%ebx		// turb table at row zero
	movl	%ebx,12(%esp)
	movl	52(%esp),%ecx		// width; C writes four pixels per step
	addl	$3,%ecx
	sarl	$2,%ecx
	movl	%ecx,0(%esp)
	movl	56(%esp),%eax		// row count
	movl	%eax,4(%esp)
	testl	%eax,%eax
	jle	.Lwarp_pixels_done
	testl	%ecx,%ecx
	jle	.Lwarp_pixels_done

.Lwarp_pixels_row:
	movl	12(%esp),%edx		// turb[v] selects the column base
	movl	(%edx),%eax
	movl	8(%esp),%esi
	leal	(%esi,%eax,4),%esi	// column + turb[v]
	movl	48(%esp),%ebx		// pixel rows always index turb[u]
	movl	0(%esp),%edx		// four-pixel groups
	shrl	$1,%edx			// process pairs of groups; CF is an odd tail
	jnc	.Lwarp_pixels_group8

// Keep an odd four-pixel tail first so stores remain left-to-right.
	movl	(%ebx),%ecx
	movl	(%ebp,%ecx,4),%eax
	movl	(%esi),%ecx
	movb	(%eax,%ecx),%cl
	movb	%cl,(%edi)

	movl	4(%ebx),%ecx
	movl	(%ebp,%ecx,4),%eax
	movl	4(%esi),%ecx
	movb	(%eax,%ecx),%cl
	movb	%cl,1(%edi)

	movl	8(%ebx),%ecx
	movl	(%ebp,%ecx,4),%eax
	movl	8(%esi),%ecx
	movb	(%eax,%ecx),%cl
	movb	%cl,2(%edi)

	movl	12(%ebx),%ecx
	movl	(%ebp,%ecx,4),%eax
	movl	12(%esi),%ecx
	movb	(%eax,%ecx),%cl
	movb	%cl,3(%edi)

	addl	$16,%ebx
	addl	$16,%esi
	addl	$4,%edi
	testl	%edx,%edx
	jz	.Lwarp_pixels_row_done

.Lwarp_pixels_group8:
	movl	(%ebx),%ecx
	movl	(%ebp,%ecx,4),%eax
	movl	(%esi),%ecx
	movb	(%eax,%ecx),%cl
	movb	%cl,(%edi)

	movl	4(%ebx),%ecx
	movl	(%ebp,%ecx,4),%eax
	movl	4(%esi),%ecx
	movb	(%eax,%ecx),%cl
	movb	%cl,1(%edi)

	movl	8(%ebx),%ecx
	movl	(%ebp,%ecx,4),%eax
	movl	8(%esi),%ecx
	movb	(%eax,%ecx),%cl
	movb	%cl,2(%edi)

	movl	12(%ebx),%ecx
	movl	(%ebp,%ecx,4),%eax
	movl	12(%esi),%ecx
	movb	(%eax,%ecx),%cl
	movb	%cl,3(%edi)

	movl	16(%ebx),%ecx
	movl	(%ebp,%ecx,4),%eax
	movl	16(%esi),%ecx
	movb	(%eax,%ecx),%cl
	movb	%cl,4(%edi)

	movl	20(%ebx),%ecx
	movl	(%ebp,%ecx,4),%eax
	movl	20(%esi),%ecx
	movb	(%eax,%ecx),%cl
	movb	%cl,5(%edi)

	movl	24(%ebx),%ecx
	movl	(%ebp,%ecx,4),%eax
	movl	24(%esi),%ecx
	movb	(%eax,%ecx),%cl
	movb	%cl,6(%edi)

	movl	28(%ebx),%ecx
	movl	(%ebp,%ecx,4),%eax
	movl	28(%esi),%ecx
	movb	(%eax,%ecx),%cl
	movb	%cl,7(%edi)

	addl	$32,%ebx
	addl	$32,%esi
	addl	$8,%edi
	decl	%edx
	jnz	.Lwarp_pixels_group8

.Lwarp_pixels_row_done:
	movl	0(%esp),%eax
	shll	$2,%eax
	subl	%eax,%edi			// rewind the padded span width
	addl	60(%esp),%edi		// rowbytes
	addl	$4,%ebp
	addl	$4,12(%esp)		// next turb[v] entry
	decl	4(%esp)
	jnz	.Lwarp_pixels_row

.Lwarp_pixels_done:
	addl	$16,%esp
	popl	%edi
	popl	%esi
	popl	%ebp
	popl	%ebx
	ret

// D_WarpScreen(void)
// Geometry tables depend only on viewport, source buffer/stride and x87 CW.
// Retain them between calls; phase selection and pixel copying remain per-frame.
// Single-threaded renderer: no table pointers escape this routine.
	.equ	WARP_ROW_COUNT, 1030		// MAXHEIGHT + AMP2*2
	.equ	WARP_COL_COUNT, 1286		// MAXWIDTH + AMP2*2
	.equ	WARP_ROW_BYTES, WARP_ROW_COUNT * 4
	.equ	WARP_COL_BYTES, WARP_COL_COUNT * 4
	.equ	WARP_LOCAL, 0
	.equ	WARP_FRAME_BYTES, 16
	.equ	WARP_OLD_CW, WARP_LOCAL
	.equ	WARP_TRUNC_CW, WARP_LOCAL + 2
	.equ	WARP_PHASE, WARP_LOCAL + 4
	.equ	WARP_HRATIO, WARP_LOCAL + 8
	.equ	WARP_WRATIO, WARP_LOCAL + 12

	.section .bss
	.p2align 4
.Lwarp_cache_rows:
	.space WARP_ROW_BYTES
.Lwarp_cache_columns:
	.space WARP_COL_BYTES
.Lwarp_cache_key:
	.space 36
.Lwarp_cache_valid:
	.space 4
	.text

	.p2align 4,,15
C(D_WarpScreen):
	.globl C(D_WarpScreen)
	pushl	%ebx
	pushl	%ebp
	pushl	%esi
	pushl	%edi
	subl	$WARP_FRAME_BYTES,%esp
	movl	$.Lwarp_cache_rows,%ebp
	movl	$.Lwarp_cache_columns,%esi
	fnstcw	WARP_OLD_CW(%esp)
	cmpl	$0,.Lwarp_cache_valid
	je	.Lwarp_rebuild_tables

	movl	C(r_refdef),%eax
	cmpl	%eax,.Lwarp_cache_key+0
	jne	.Lwarp_rebuild_tables
	movl	C(r_refdef)+4,%eax
	cmpl	%eax,.Lwarp_cache_key+4
	jne	.Lwarp_rebuild_tables
	movl	C(r_refdef)+8,%eax
	cmpl	%eax,.Lwarp_cache_key+8
	jne	.Lwarp_rebuild_tables
	movl	C(r_refdef)+12,%eax
	cmpl	%eax,.Lwarp_cache_key+12
	jne	.Lwarp_rebuild_tables
	movl	C(scr_vrect)+8,%eax
	cmpl	%eax,.Lwarp_cache_key+16
	jne	.Lwarp_rebuild_tables
	movl	C(scr_vrect)+12,%eax
	cmpl	%eax,.Lwarp_cache_key+20
	jne	.Lwarp_rebuild_tables
	movl	C(screenwidth),%eax
	cmpl	%eax,.Lwarp_cache_key+24
	jne	.Lwarp_rebuild_tables
	movl	C(d_viewbuffer),%eax
	cmpl	%eax,.Lwarp_cache_key+28
	jne	.Lwarp_rebuild_tables
	movzwl	WARP_OLD_CW(%esp),%eax
	cmpl	%eax,.Lwarp_cache_key+32
	jne	.Lwarp_rebuild_tables
	jmp	.Lwarp_tables_ready

.Lwarp_rebuild_tables:
	movl	C(r_refdef),%eax
	movl	%eax,.Lwarp_cache_key+0
	movl	C(r_refdef)+4,%eax
	movl	%eax,.Lwarp_cache_key+4
	movl	C(r_refdef)+8,%eax
	movl	%eax,.Lwarp_cache_key+8
	movl	C(r_refdef)+12,%eax
	movl	%eax,.Lwarp_cache_key+12
	movl	C(scr_vrect)+8,%eax
	movl	%eax,.Lwarp_cache_key+16
	movl	C(scr_vrect)+12,%eax
	movl	%eax,.Lwarp_cache_key+20
	movl	C(screenwidth),%eax
	movl	%eax,.Lwarp_cache_key+24
	movl	C(d_viewbuffer),%eax
	movl	%eax,.Lwarp_cache_key+28
	movzwl	WARP_OLD_CW(%esp),%eax
	movl	%eax,.Lwarp_cache_key+32

	// C stored each ratio as a float before entering the lookup loops.
	fildl	C(r_refdef)+8		// view width
	fildl	C(scr_vrect)+8		// screen rectangle width
	fdivrp	%st,%st(1)
	fstps	WARP_WRATIO(%esp)
	fildl	C(r_refdef)+12		// view height
	fildl	C(scr_vrect)+12		// screen rectangle height
	fdivp	%st,%st(1)
	fstps	WARP_HRATIO(%esp)

	// Build rowptr and column with the same 32-bit arguments as the C setup.
	movl	WARP_WRATIO(%esp),%eax
	movl	WARP_HRATIO(%esp),%edx
	pushl	%eax
	pushl	%edx
	pushl	C(r_refdef)			// x origin
	movl	C(r_refdef)+8,%eax
	addl	$6,%eax
	pushl	%eax				// w + AMP2*2
	movl	C(r_refdef)+12,%eax
	addl	$6,%eax
	pushl	%eax				// h + AMP2*2
	pushl	C(r_refdef)+8		// w
	pushl	C(r_refdef)+12		// h
	movl	C(scr_vrect)+8,%eax
	addl	$6,%eax
	pushl	%eax				// column count
	movl	C(scr_vrect)+12,%eax
	addl	$6,%eax
	pushl	%eax				// row count
	pushl	C(screenwidth)
	movl	C(r_refdef)+4,%eax
	movl	C(screenwidth),%ecx
	mull	%ecx
	addl	C(d_viewbuffer),%eax
	pushl	%eax				// unwarped view's top row
	pushl	%esi				// column array
	pushl	%ebp				// rowptr array
	call	C(D_WarpBuildTables_asm486)
	addl	$52,%esp
	movl	$1,.Lwarp_cache_valid

.Lwarp_tables_ready:

	// turb = intsintable + ((int)(cl.time * SPEED) & (CYCLE - 1)).
	fnstcw	WARP_OLD_CW(%esp)
	movw	WARP_OLD_CW(%esp),%dx
	orw	$0x0c00,%dx
	movw	%dx,WARP_TRUNC_CW(%esp)
	flds	Lwarp_speed
	fmull	C(cl)+0x23c
	fldcw	WARP_TRUNC_CW(%esp)
	fistpl	WARP_PHASE(%esp)
	fldcw	WARP_OLD_CW(%esp)
	movl	WARP_PHASE(%esp),%ebx
	andl	$127,%ebx
	leal	C(intsintable)(,%ebx,4),%ebx

	// dest = vid.buffer + scr_vrect.y*vid.rowbytes + scr_vrect.x.
	movl	C(scr_vrect)+4,%edi
	movl	C(vid)+16,%ecx
	movl	%edi,%eax
	mull	%ecx
	movl	%eax,%edi
	addl	C(vid),%edi
	addl	C(scr_vrect),%edi

	pushl	C(vid)+16			// rowbytes
	pushl	C(scr_vrect)+12		// height
	pushl	C(scr_vrect)+8		// width
	pushl	%ebx				// turbulence table
	pushl	%esi				// column array
	pushl	%ebp				// rowptr array
	pushl	%edi				// destination
	call	C(D_WarpPixels_asm486)
	addl	$28,%esp

	addl	$WARP_FRAME_BYTES,%esp
	popl	%edi
	popl	%esi
	popl	%ebp
	popl	%ebx
	ret
#endif

