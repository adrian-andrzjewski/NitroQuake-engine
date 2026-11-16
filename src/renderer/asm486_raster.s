// asm486_raster.s
// Rectangle fills and turbulent surface rasterization.

#include "asm_i386.h"
#include "renderer/d_ifacea.h"
#include "renderer/asm_draw.h"

	.data
	.p2align 2
Lturbulent_speed:
	.float	20.0
Lturbulent_65536:
	.float	65536.0
Lturbulent_16:
	.float	16.0
	.text
	.p2align 4,,15

#ifdef ASM486_FILLRECT
C(D_FillRect):
	.globl C(D_FillRect)
	pushl	%ebp
	movl	%esp,%ebp
	subl	$40,%esp
	pushl	%ebx
	pushl	%esi
	pushl	%edi

	movl	8(%ebp),%eax		// rect
	movl	0(%eax),%ecx
	movl	%ecx,-4(%ebp)		// rx
	movl	4(%eax),%ecx
	movl	%ecx,-8(%ebp)		// ry
	movl	8(%eax),%ecx
	movl	%ecx,-12(%ebp)		// rwidth
	movl	12(%eax),%ecx
	movl	%ecx,-16(%ebp)		// rheight
	movl	C(vid)+16,%eax
	movl	%eax,-24(%ebp)		// rowbytes
	movl	C(vid)+20,%eax
	movl	%eax,-32(%ebp)		// screen width
	movl	C(vid)+24,%eax
	movl	%eax,-36(%ebp)		// screen height
	movl	12(%ebp),%eax
	movl	%eax,-28(%ebp)		// color

	cmpl	$0,-4(%ebp)
	jge	.Lfillrect_x_nonnegative
	movl	-4(%ebp),%eax
	addl	%eax,-12(%ebp)
	movl	$0,-4(%ebp)
.Lfillrect_x_nonnegative:
	cmpl	$0,-8(%ebp)
	jge	.Lfillrect_y_nonnegative
	movl	-8(%ebp),%eax
	addl	%eax,-16(%ebp)
	movl	$0,-8(%ebp)
.Lfillrect_y_nonnegative:
	movl	-4(%ebp),%eax
	cmpl	-32(%ebp),%eax
	jge	.Lfillrect_done
	movl	-8(%ebp),%eax
	cmpl	-36(%ebp),%eax
	jge	.Lfillrect_done
	movl	-4(%ebp),%eax
	addl	-12(%ebp),%eax
	cmpl	-32(%ebp),%eax
	jle	.Lfillrect_width_clipped
	movl	-32(%ebp),%eax
	subl	-4(%ebp),%eax
	movl	%eax,-12(%ebp)
.Lfillrect_width_clipped:
	movl	-8(%ebp),%eax
	addl	-16(%ebp),%eax
	cmpl	-36(%ebp),%eax
	jle	.Lfillrect_height_clipped
	movl	-36(%ebp),%eax
	subl	-8(%ebp),%eax
	movl	%eax,-16(%ebp)
.Lfillrect_height_clipped:
	cmpl	$1,-12(%ebp)
	jl	.Lfillrect_done
	cmpl	$1,-16(%ebp)
	jl	.Lfillrect_done

	// Initial destination = buffer + ry*rowbytes + rx. MUL is available
	// on the 386; this avoids the slower two-register form on 486-class CPUs.
	movl	-8(%ebp),%eax
	mull	-24(%ebp)
	addl	C(vid),%eax
	addl	-4(%ebp),%eax
	movl	%eax,-20(%ebp)

	movl	-12(%ebp),%eax
	cmpl	$16,%eax
	jge	.Lfillrect_large_rows
	testl	$3,%eax
	jnz	.Lfillrect_small_byte_rows
	testl	$3,-20(%ebp)
	jnz	.Lfillrect_small_byte_rows

	// Match C's color += color << 16; color += color << 8 exactly.
	movl	-28(%ebp),%eax
	movl	%eax,%edx
	shll	$16,%edx
	addl	%edx,%eax
	movl	%eax,%edx
	shll	$8,%edx
	addl	%edx,%eax
	movl	%eax,-40(%ebp)
	movl	-12(%ebp),%esi
	shrl	$2,%esi
	movl	-16(%ebp),%ebx
.Lfillrect_small_dword_row:
	movl	-20(%ebp),%edi
	movl	-40(%ebp),%eax
	movl	%esi,%ecx
	rep stosl
	movl	-20(%ebp),%eax
	addl	-24(%ebp),%eax
	movl	%eax,-20(%ebp)
	decl	%ebx
	jnz	.Lfillrect_small_dword_row
	jmp	.Lfillrect_done

.Lfillrect_small_byte_rows:
	movl	-16(%ebp),%ebx
.Lfillrect_small_byte_row:
	movl	-20(%ebp),%edi
	movl	-12(%ebp),%ecx
	movl	-28(%ebp),%eax
	rep stosb
	movl	-20(%ebp),%eax
	addl	-24(%ebp),%eax
	movl	%eax,-20(%ebp)
	decl	%ebx
	jnz	.Lfillrect_small_byte_row
	jmp	.Lfillrect_done

.Lfillrect_large_rows:
	// Form the repeated low-byte pattern used by Q_memset.
	movl	-28(%ebp),%eax
	andl	$0xff,%eax
	movl	%eax,%edx
	shll	$8,%edx
	orl	%edx,%eax
	movl	%eax,%edx
	shll	$16,%edx
	orl	%edx,%eax
	movl	%eax,-40(%ebp)
	movl	-16(%ebp),%ebx
.Lfillrect_large_row:
	movl	-20(%ebp),%edi		// row start
	movl	%edi,%esi			// preserve row start
	movl	-12(%ebp),%ecx
.Lfillrect_align:
	testl	$3,%edi
	jz	.Lfillrect_aligned
	movl	-40(%ebp),%eax
	movb	%al,(%edi)
	incl	%edi
	decl	%ecx
	jz	.Lfillrect_large_row_done
	jmp	.Lfillrect_align
.Lfillrect_aligned:
	shrl	$2,%ecx
	movl	-40(%ebp),%eax
	rep stosl
	// Remaining 0..3 bytes = width - bytes already written.
	movl	-12(%ebp),%ecx
	movl	%edi,%edx
	subl	%esi,%edx
	subl	%edx,%ecx
	movl	-40(%ebp),%eax
	rep stosb
.Lfillrect_large_row_done:
	movl	-20(%ebp),%eax
	addl	-24(%ebp),%eax
	movl	%eax,-20(%ebp)
	decl	%ebx
	jnz	.Lfillrect_large_row

.Lfillrect_done:
	popl	%edi
	popl	%esi
	popl	%ebx
	movl	%ebp,%esp
	popl	%ebp
	ret
#endif

#ifdef ASM486_TURBULENT_SCAN

// Locals for Turbulent8. The three interpolants use 80-bit slots because GCC's
// i386 C path keeps them in x87 registers between span chunks.
.set TURB_COUNT,      -20
.set TURB_SPAN,       -24
.set TURB_OLD_CW,     -26
.set TURB_TRUNC_CW,   -28
.set TURB_SDIVZ,      -40
.set TURB_TDIVZ,      -52
.set TURB_ZI,         -64
.set TURB_Z,          -76
.set TURB_SNEXT,      -80
.set TURB_TNEXT,      -84
.set TURB_MINUS1,     -88
.set TURB_MINUS1_INT, -92
.set TURB_SSTEP16,    -96
.set TURB_TSTEP16,   -100
.set TURB_ZSTEP16,   -104
.set TURB_PROFILE_START, -120

.macro TURB_SCAN_FISTP destination
	fldcw	TURB_TRUNC_CW(%ebp)
	fistpl	\destination(%ebp)
	fldcw	TURB_OLD_CW(%ebp)
.endm

.macro TURB_SCAN_MAKE_Z zi
	fldt	\zi(%ebp)
	fdivrs	Lturbulent_65536
	fstpt	TURB_Z(%ebp)
.endm

.macro TURB_SCAN_FIXED_CAST source, destination
	fldt	\source(%ebp)
	fldt	TURB_Z(%ebp)
	fmulp	%st,%st(1)
	TURB_SCAN_FISTP \destination
.endm

	.p2align 4,,15
.globl C(Turbulent8)
C(Turbulent8):
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	subl	$128,%esp

	// C casts to int truncate toward zero and restore the caller's x87 control
	// word after each conversion. Do the same for the phase and every fixed value.
	fnstcw	TURB_OLD_CW(%ebp)
	movw	TURB_OLD_CW(%ebp),%dx
	orw	$0x0c00,%dx
	movw	%dx,TURB_TRUNC_CW(%ebp)

#ifdef PROFILE486
	cmpl	$0,C(bench486_profile_frame_active)
	je	.Lturb_profile_start_done
	call	C(Sys_FloatTime)
	fstpl	TURB_PROFILE_START(%ebp)
.Lturb_profile_start_done:
#endif

	// r_turb_turb = sintable + ((int)(cl.time * 20) & (CYCLE - 1)).
	flds	Lturbulent_speed
	fmull	C(cl)+0x23c
	TURB_SCAN_FISTP TURB_COUNT
	movl	TURB_COUNT(%ebp),%eax
	andl	$(CYCLE-1),%eax
	leal	C(sintable)(,%eax,4),%eax
	movl	%eax,C(r_turb_turb)

	movl	$0,C(r_turb_sstep)
	movl	$0,C(r_turb_tstep)
	movl	C(cacheblock),%eax
	movl	%eax,C(r_turb_pbase)

	// The 16-pixel increments are exact powers-of-two scalings of the C floats.
	flds	C(d_sdivzstepu)
	fmuls	Lturbulent_16
	fstps	TURB_SSTEP16(%ebp)
	flds	C(d_tdivzstepu)
	fmuls	Lturbulent_16
	fstps	TURB_TSTEP16(%ebp)
	flds	C(d_zistepu)
	fmuls	Lturbulent_16
	fstps	TURB_ZSTEP16(%ebp)

	movl	8(%ebp),%ebx
	movl	%ebx,TURB_SPAN(%ebp)

.Lturb_row:
	movzwl	espan_t_v(%ebx),%eax
	movl	C(viewspantable)(,%eax,4),%edx
	movzwl	espan_t_u(%ebx),%ecx
	addl	%ecx,%edx
	movl	%edx,C(r_turb_pdest)
	movl	espan_t_count(%ebx),%eax
	movl	%eax,TURB_COUNT(%ebp)
#ifdef PROFILE486
	incl	C(bench486_turbulent_rows)
	addl	%eax,C(bench486_turbulent_pixels)
#endif

	// GCC's -ffast-math x87 output adds the two products before the origin.
	// Preserve that emitted order and excess precision through the final casts.
	filds	espan_t_v(%ebx)
	fmuls	C(d_sdivzstepv)
	filds	espan_t_u(%ebx)
	fmuls	C(d_sdivzstepu)
	faddp	%st,%st(1)
	flds	C(d_sdivzorigin)
	faddp	%st,%st(1)
	fstpt	TURB_SDIVZ(%ebp)

	filds	espan_t_v(%ebx)
	fmuls	C(d_tdivzstepv)
	filds	espan_t_u(%ebx)
	fmuls	C(d_tdivzstepu)
	faddp	%st,%st(1)
	flds	C(d_tdivzorigin)
	faddp	%st,%st(1)
	fstpt	TURB_TDIVZ(%ebp)

	filds	espan_t_v(%ebx)
	fmuls	C(d_zistepv)
	filds	espan_t_u(%ebx)
	fmuls	C(d_zistepu)
	faddp	%st,%st(1)
	flds	C(d_ziorigin)
	faddp	%st,%st(1)
	fstpt	TURB_ZI(%ebp)

	TURB_SCAN_MAKE_Z TURB_ZI
	TURB_SCAN_FIXED_CAST TURB_SDIVZ,TURB_SNEXT
	movl	TURB_SNEXT(%ebp),%eax
	addl	C(sadjust),%eax
	cmpl	C(bbextents),%eax
	jle	.Lturb_initial_s_lower
	movl	C(bbextents),%eax
	jmp	.Lturb_initial_s_store
.Lturb_initial_s_lower:
	testl	%eax,%eax
	jns	.Lturb_initial_s_store
	xorl	%eax,%eax
.Lturb_initial_s_store:
	movl	%eax,C(r_turb_s)

	TURB_SCAN_FIXED_CAST TURB_TDIVZ,TURB_TNEXT
	movl	TURB_TNEXT(%ebp),%eax
	addl	C(tadjust),%eax
	cmpl	C(bbextentt),%eax
	jle	.Lturb_initial_t_lower
	movl	C(bbextentt),%eax
	jmp	.Lturb_initial_t_store
.Lturb_initial_t_lower:
	testl	%eax,%eax
	jns	.Lturb_initial_t_store
	xorl	%eax,%eax
.Lturb_initial_t_store:
	movl	%eax,C(r_turb_t)

.Lturb_chunk:
	movl	TURB_COUNT(%ebp),%eax
	cmpl	$16,%eax
	jl	.Lturb_short_chunk
	movl	$16,C(r_turb_spancount)
	jmp	.Lturb_chunk_count_ready
.Lturb_short_chunk:
	movl	%eax,C(r_turb_spancount)
.Lturb_chunk_count_ready:
	subl	C(r_turb_spancount),%eax
	movl	%eax,TURB_COUNT(%ebp)
	testl	%eax,%eax
	jne	.Lturb_interpolate_16

	// Final shortened chunk: evaluate the endpoint at spanCount - 1 and divide
	// the fixed-point delta with signed integer division, as in C.
	movl	C(r_turb_spancount),%eax
	decl	%eax
	movl	%eax,TURB_MINUS1_INT(%ebp)
	fildl	TURB_MINUS1_INT(%ebp)
	fstps	TURB_MINUS1(%ebp)

	flds	C(d_sdivzstepu)
	fmuls	TURB_MINUS1(%ebp)
	fldt	TURB_SDIVZ(%ebp)
	faddp	%st,%st(1)
	fstpt	TURB_SDIVZ(%ebp)
	flds	C(d_tdivzstepu)
	fmuls	TURB_MINUS1(%ebp)
	fldt	TURB_TDIVZ(%ebp)
	faddp	%st,%st(1)
	fstpt	TURB_TDIVZ(%ebp)
	flds	C(d_zistepu)
	fmuls	TURB_MINUS1(%ebp)
	fldt	TURB_ZI(%ebp)
	faddp	%st,%st(1)
	fstpt	TURB_ZI(%ebp)
	TURB_SCAN_MAKE_Z TURB_ZI

	TURB_SCAN_FIXED_CAST TURB_SDIVZ,TURB_SNEXT
	movl	TURB_SNEXT(%ebp),%eax
	addl	C(sadjust),%eax
	cmpl	C(bbextents),%eax
	jle	1f
	movl	C(bbextents),%eax
	jmp	2f
1:
	cmpl	$16,%eax
	jge	2f
	movl	$16,%eax
2:
	movl	%eax,TURB_SNEXT(%ebp)

	TURB_SCAN_FIXED_CAST TURB_TDIVZ,TURB_TNEXT
	movl	TURB_TNEXT(%ebp),%eax
	addl	C(tadjust),%eax
	cmpl	C(bbextentt),%eax
	jle	3f
	movl	C(bbextentt),%eax
	jmp	4f
3:
	cmpl	$16,%eax
	jge	4f
	movl	$16,%eax
4:
	movl	%eax,TURB_TNEXT(%ebp)

	cmpl	$1,C(r_turb_spancount)
	jle	.Lturb_fixed_steps_ready
	movl	TURB_SNEXT(%ebp),%eax
	subl	C(r_turb_s),%eax
	cltd
	movl	C(r_turb_spancount),%ecx
	decl	%ecx
	idivl	%ecx
	movl	%eax,C(r_turb_sstep)
	movl	TURB_TNEXT(%ebp),%eax
	subl	C(r_turb_t),%eax
	cltd
	movl	C(r_turb_spancount),%ecx
	decl	%ecx
	idivl	%ecx
	movl	%eax,C(r_turb_tstep)
	jmp	.Lturb_fixed_steps_ready

.Lturb_interpolate_16:
	fldt	TURB_SDIVZ(%ebp)
	flds	TURB_SSTEP16(%ebp)
	faddp	%st,%st(1)
	fstpt	TURB_SDIVZ(%ebp)
	fldt	TURB_TDIVZ(%ebp)
	flds	TURB_TSTEP16(%ebp)
	faddp	%st,%st(1)
	fstpt	TURB_TDIVZ(%ebp)
	fldt	TURB_ZI(%ebp)
	flds	TURB_ZSTEP16(%ebp)
	faddp	%st,%st(1)
	fstpt	TURB_ZI(%ebp)
	TURB_SCAN_MAKE_Z TURB_ZI

	TURB_SCAN_FIXED_CAST TURB_SDIVZ,TURB_SNEXT
	movl	TURB_SNEXT(%ebp),%eax
	addl	C(sadjust),%eax
	cmpl	C(bbextents),%eax
	jle	5f
	movl	C(bbextents),%eax
	jmp	6f
5:
	cmpl	$16,%eax
	jge	6f
	movl	$16,%eax
6:
	movl	%eax,TURB_SNEXT(%ebp)

	TURB_SCAN_FIXED_CAST TURB_TDIVZ,TURB_TNEXT
	movl	TURB_TNEXT(%ebp),%eax
	addl	C(tadjust),%eax
	cmpl	C(bbextentt),%eax
	jle	7f
	movl	C(bbextentt),%eax
	jmp	8f
7:
	cmpl	$16,%eax
	jge	8f
	movl	$16,%eax
8:
	movl	%eax,TURB_TNEXT(%ebp)

	movl	TURB_SNEXT(%ebp),%eax
	subl	C(r_turb_s),%eax
	sarl	$4,%eax
	movl	%eax,C(r_turb_sstep)
	movl	TURB_TNEXT(%ebp),%eax
	subl	C(r_turb_t),%eax
	sarl	$4,%eax
	movl	%eax,C(r_turb_tstep)

.Lturb_fixed_steps_ready:
	andl	$((CYCLE<<16)-1),C(r_turb_s)
	andl	$((CYCLE<<16)-1),C(r_turb_t)
#ifdef ASM486_TURBULENT_C
	call	C(D_DrawTurbulent8Span_C)
#else
	call	C(D_DrawTurbulent8Span_asm486)
#endif
#ifdef PROFILE486
	incl	C(bench486_turbulent_chunks)
#endif
	movl	TURB_SNEXT(%ebp),%eax
	movl	%eax,C(r_turb_s)
	movl	TURB_TNEXT(%ebp),%eax
	movl	%eax,C(r_turb_t)
	cmpl	$0,TURB_COUNT(%ebp)
	jg	.Lturb_chunk

	movl	TURB_SPAN(%ebp),%ebx
	movl	espan_t_pnext(%ebx),%ebx
	movl	%ebx,TURB_SPAN(%ebp)
	testl	%ebx,%ebx
	jne	.Lturb_row

#ifdef PROFILE486
	cmpl	$0,C(bench486_profile_frame_active)
	je	.Lturb_profile_end_done
	call	C(Sys_FloatTime)
	// ST(0) is end time: memory subtraction expresses end - start directly.
	fsubl	TURB_PROFILE_START(%ebp)
	faddl	C(bench486_turbulent_seconds)
	fstpl	C(bench486_turbulent_seconds)
.Lturb_profile_end_done:
#endif

	leal	-12(%ebp),%esp
	popl	%edi
	popl	%esi
	popl	%ebx
	movl	%ebp,%esp
	popl	%ebp
	ret

#endif // ASM486_TURBULENT_SCAN
