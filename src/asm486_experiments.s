// asm486_experiments.s
//
// Hand-written i486 paths for DOS software-renderer functions.
// The C references and independent build-time selectors remain available while
// the renderer is migrated and each assembly path is checked for parity.

#include "asm_i386.h"
#include "d_ifacea.h"
#include "asm_draw.h"

#ifdef ASM486_SURFACE_GRADIENTS
	.extern C(D_CalcGradientsProfileBegin_asm486)
	.extern C(D_CalcGradientsProfileEnd_asm486)
	.extern C(D_CalcGradientsProfileAxisHit_asm486)
	.extern C(D_CalcGradientsProfileAxisMiss_asm486)
	.extern C(TransformVector)
	.extern C(d_gradient_miplevel)
	.extern C(d_mipscale_values)
	.extern C(d_mip_xscale)
	.extern C(d_mip_yscale)
	.extern C(d_mip_t16)
	.extern C(d_texaxis_cache_asm)
	.extern C(d_texaxis_cache_mask)
	.extern C(transformed_modelorg)
	.extern C(currententity)
	.extern C(r_framecount)
	.extern C(d_sdivzstepu)
	.extern C(d_sdivzstepv)
	.extern C(d_tdivzstepu)
	.extern C(d_tdivzstepv)
	.extern C(d_sdivzorigin)
	.extern C(d_tdivzorigin)
	.extern C(sadjust)
	.extern C(tadjust)
	.extern C(bbextents)
	.extern C(bbextentt)
	.extern C(xcenter)
	.extern C(ycenter)
	.section .rodata
	.p2align 2
.Ldgradient_fixed16:
	.float 65536.0
.Ldgradient_half:
	.float 0.5
	.text
#endif

// R_RotateSprite: translate a beam sprite along its viewing normal.
#if defined(ASM486_SPRITE_BEAM) || defined(BENCH486)
// cdecl: one 32-bit float argument; caller-saved EAX and the x87 stack only.
// Keep the scaled vector as three single-precision temporaries, matching
// VectorScale's stores before the origin/model-origin updates.
// DJGPP 32-bit spritedesc_t offsets: vpn=36 (nump=0, pointers=4/8,
// vup=12, vright=24). Reload beamlength after each temporary store pops x87.
.extern C(r_spritedesc)
.extern C(r_entorigin)
.extern C(modelorg)
.globl C(R_RotateSprite_asm486)
C(R_RotateSprite_asm486):
	subl	$12,%esp
	flds	16(%esp)
	ftst
	fnstsw	%ax
	andb	$0x45,%ah
	cmpb	$0x40,%ah
	je	.Lrotate_sprite_zero
	fchs
	flds	C(r_spritedesc)+36
	fmulp	%st,%st(1)
	fstps	0(%esp)
	flds	16(%esp)
	fchs
	flds	C(r_spritedesc)+40
	fmulp	%st,%st(1)
	fstps	4(%esp)
	flds	16(%esp)
	fchs
	flds	C(r_spritedesc)+44
	fmulp	%st,%st(1)
	fstps	8(%esp)
	flds	C(r_entorigin)
	fadds	0(%esp)
	fstps	C(r_entorigin)
	flds	C(r_entorigin)+4
	fadds	4(%esp)
	fstps	C(r_entorigin)+4
	flds	C(r_entorigin)+8
	fadds	8(%esp)
	fstps	C(r_entorigin)+8
	flds	C(modelorg)
	fsubs	0(%esp)
	fstps	C(modelorg)
	flds	C(modelorg)+4
	fsubs	4(%esp)
	fstps	C(modelorg)+4
	flds	C(modelorg)+8
	fsubs	8(%esp)
	fstps	C(modelorg)+8
	jmp	.Lrotate_sprite_return
.Lrotate_sprite_zero:
	fstp	%st(0)
.Lrotate_sprite_return:
	addl	$12,%esp
	ret
#endif

// R_ClipSpriteFace: clip one five-float sprite winding against a plane.
// clip_verts is two arrays of 20 vec5_t records (400 bytes each); keep that
// stride synchronized with MAXWORKINGVERTS in r_shared.h. clip_current and
// clip_verts are externally visible for this separately assembled routine and
// for the direct C-vs-assembly fixture.
#if defined(ASM486_SPRITE_CLIP) || defined(BENCH486)
.extern C(clip_current)
.extern C(clip_verts)
.globl C(R_ClipSpriteFace_asm486)
C(R_ClipSpriteFace_asm486):
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	subl	$120,%esp

	/* Locals: in=-16, out=-20, plane=-24, nump=-28, outcount=-32;
	   dists[0..20]=-116..-36. Keep frac extended on the x87 stack. */
	movl	8(%ebp),%eax
	movl	%eax,-28(%ebp)
	movl	12(%ebp),%eax
	movl	%eax,-24(%ebp)
	movl	C(clip_current),%eax
	testl	%eax,%eax
	je	.Lsprite_clip_input_zero
	leal	C(clip_verts)+400,%eax
	movl	%eax,-16(%ebp)
	leal	C(clip_verts),%eax
	movl	%eax,-20(%ebp)
	movl	$0,C(clip_current)
	jmp	.Lsprite_clip_buffers_ready
.Lsprite_clip_input_zero:
	leal	C(clip_verts),%eax
	movl	%eax,-16(%ebp)
	leal	C(clip_verts)+400,%eax
	movl	%eax,-20(%ebp)
	movl	$1,C(clip_current)
.Lsprite_clip_buffers_ready:

	/* dists[i] = ((x*nx + y*ny) + z*nz) - plane.dist, rounded to float. */
	movl	-24(%ebp),%edx
	movl	-16(%ebp),%esi
	leal	-116(%ebp),%edi
	movl	-28(%ebp),%ebx
.Lsprite_clip_distance_loop:
	testl	%ebx,%ebx
	jle	.Lsprite_clip_distances_done
	flds	(%esi)
	fmuls	0(%edx)
	flds	4(%esi)
	fmuls	4(%edx)
	faddp	%st(0),%st(1)
	fsubs	12(%edx)
	flds	8(%esi)
	fmuls	8(%edx)
	faddp	%st(0),%st(1)
	fstps	(%edi)
	addl	$20,%esi
	addl	$4,%edi
	decl	%ebx
	jmp	.Lsprite_clip_distance_loop
.Lsprite_clip_distances_done:

	/* Match dists[nump]=dists[0] and the five-float input wrap copy. */
	movl	-28(%ebp),%eax
	movl	-116(%ebp),%edx
	movl	%edx,-116(%ebp,%eax,4)
	movl	-16(%ebp),%esi
	leal	(%eax,%eax,4),%eax
	shll	$2,%eax
	addl	%eax,%esi
	movl	-16(%ebp),%edx
	movl	0(%edx),%eax
	movl	%eax,0(%esi)
	movl	4(%edx),%eax
	movl	%eax,4(%esi)
	movl	8(%edx),%eax
	movl	%eax,8(%esi)
	movl	12(%edx),%eax
	movl	%eax,12(%esi)
	movl	16(%edx),%eax
	movl	%eax,16(%esi)

	movl	-16(%ebp),%esi
	movl	-20(%ebp),%edi
	leal	-116(%ebp),%ecx
	movl	-28(%ebp),%ebx
	movl	$0,-32(%ebp)
.Lsprite_clip_vertex_loop:
	testl	%ebx,%ebx
	jle	.Lsprite_clip_return_count

	/* dists[i] >= 0 accepts either zero and ordered positive values. */
	movl	(%ecx),%eax
	cmpl	$0x7f800000,%eax
	jbe	.Lsprite_clip_current_nonnegative
	cmpl	$0x80000000,%eax
	jne	.Lsprite_clip_front_done
.Lsprite_clip_current_nonnegative:
	movl	0(%esi),%eax
	movl	%eax,0(%edi)
	movl	4(%esi),%eax
	movl	%eax,4(%edi)
	movl	8(%esi),%eax
	movl	%eax,8(%edi)
	movl	12(%esi),%eax
	movl	%eax,12(%edi)
	movl	16(%esi),%eax
	movl	%eax,16(%edi)
	addl	$20,%edi
	incl	-32(%ebp)
.Lsprite_clip_front_done:

	/* Equality checks precede the side test in the reference routine. */
	movl	(%ecx),%eax
	andl	$0x7fffffff,%eax
	testl	%eax,%eax
	je	.Lsprite_clip_next_vertex
	movl	4(%ecx),%eax
	andl	$0x7fffffff,%eax
	testl	%eax,%eax
	je	.Lsprite_clip_next_vertex

	/* Strict > 0 tests: unordered values are treated as not in front. */
	movl	(%ecx),%eax
	decl	%eax
	cmpl	$0x7f7fffff,%eax
	ja	.Lsprite_clip_current_back
	movl	4(%ecx),%eax
	decl	%eax
	cmpl	$0x7f7fffff,%eax
	jbe	.Lsprite_clip_next_vertex
	jmp	.Lsprite_clip_crossing
.Lsprite_clip_current_back:
	movl	4(%ecx),%eax
	decl	%eax
	cmpl	$0x7f7fffff,%eax
	ja	.Lsprite_clip_next_vertex

.Lsprite_clip_crossing:
	/* frac = dists[i] / (dists[i] - dists[i+1]), rounded to float. */
	flds	(%ecx)
	flds	4(%ecx)
	fsubr	%st(1),%st(0)
	fdivrp	%st(0),%st(1)
	leal	20(%esi),%edx
	/* Interpolate x,y,z,s,t in source expression order. */
	flds	0(%edx)
	fsubs	0(%esi)
	fmul	%st(1),%st(0)
	fadds	0(%esi)
	fstps	0(%edi)
	flds	4(%edx)
	fsubs	4(%esi)
	fmul	%st(1),%st(0)
	fadds	4(%esi)
	fstps	4(%edi)
	flds	8(%edx)
	fsubs	8(%esi)
	fmul	%st(1),%st(0)
	fadds	8(%esi)
	fstps	8(%edi)
	flds	12(%edx)
	fsubs	12(%esi)
	fmul	%st(1),%st(0)
	fadds	12(%esi)
	fstps	12(%edi)
	flds	16(%edx)
	fsubs	16(%esi)
	fmul	%st(1),%st(0)
	fadds	16(%esi)
	fstps	16(%edi)
	fstp	%st(0)
	addl	$20,%edi
	incl	-32(%ebp)

.Lsprite_clip_next_vertex:
	addl	$20,%esi
	addl	$4,%ecx
	decl	%ebx
	jmp	.Lsprite_clip_vertex_loop
.Lsprite_clip_return_count:
	movl	-32(%ebp),%eax
	addl	$120,%esp
	popl	%edi
	popl	%esi
	popl	%ebx
	popl	%ebp
	ret
#endif

// R_GetSpriteframe: select a single frame or an animated group member.
// The C wrapper sanitizes/logs the entity frame and passes current time and
// syncbase explicitly, keeping entity/client structure offsets out of assembly.
#if defined(ASM486_SPRITE_FRAME) || defined(BENCH486)
.globl C(R_GetSpriteframe_asm486)
C(R_GetSpriteframe_asm486):
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	subl	$16,%esp

	/* Locals: saved control word=-16, truncate control word=-18,
	   integer quotient=-20, group frame count=-24, group pointer=-28. */
	movl	8(%ebp),%ebx
	movl	12(%ebp),%esi
	leal	24(%ebx,%esi,8),%edi
	movl	0(%edi),%eax
	testl	%eax,%eax
	jne	.Lsprite_frame_group
	movl	4(%edi),%eax
	jmp	.Lsprite_frame_return

.Lsprite_frame_group:
	movl	4(%edi),%esi
	movl	%esi,-28(%ebp)
	movl	0(%esi),%eax
	movl	%eax,-24(%ebp)
	movl	4(%esi),%edi

	/* Keep the reference x87 order: time=syncbase+cl.time, then divide by
	   fullinterval and truncate the quotient toward zero using a saved CW. */
	flds	-4(%edi,%eax,4)
	flds	24(%ebp)
	faddl	16(%ebp)
	fld	%st(0)
	fdiv	%st(2),%st(0)
	fnstcw	-16(%ebp)
	movw	-16(%ebp),%dx
	orb	$0x0c,%dh
	movw	%dx,-18(%ebp)
	fldcw	-18(%ebp)
	fistpl	-20(%ebp)
	fldcw	-16(%ebp)
	fxch	%st(1)
	fimull	-20(%ebp)
	fsubrp	%st,%st(1)

	/* Scan while i < numframes-1; equality chooses the following frame. */
	movl	-24(%ebp),%ebx
	decl	%ebx
	xorl	%edx,%edx
	testl	%ebx,%ebx
	jle	.Lsprite_frame_select
.Lsprite_frame_interval_loop:
	fcoms	(%edi,%edx,4)
	fnstsw	%ax
	testb	$0x01,%ah
	jnz	.Lsprite_frame_select
	incl	%edx
	cmpl	%ebx,%edx
	jl	.Lsprite_frame_interval_loop
.Lsprite_frame_select:
	fstp	%st(0)
	movl	-28(%ebp),%eax
	movl	8(%eax,%edx,4),%eax

.Lsprite_frame_return:
	addl	$16,%esp
	popl	%edi
	popl	%esi
	popl	%ebx
	popl	%ebp
	ret
#endif

#if defined(ASM486_SPRITE_GRADIENTS) || defined(BENCH486)
.extern C(TransformVector)
.extern C(r_spritedesc)
.extern C(modelorg)
.extern C(vright)
.extern C(vup)
.extern C(vpn)
.extern C(xscaleinv)
.extern C(yscaleinv)
.extern C(xcenter)
.extern C(ycenter)
.extern C(cachewidth)
.extern C(d_sdivzstepu)
.extern C(d_tdivzstepu)
.extern C(d_sdivzstepv)
.extern C(d_tdivzstepv)
.extern C(d_zistepu)
.extern C(d_zistepv)
.extern C(d_sdivzorigin)
.extern C(d_tdivzorigin)
.extern C(d_ziorigin)
.extern C(sadjust)
.extern C(tadjust)
.extern C(bbextents)
.extern C(bbextentt)
	.section .rodata
	.p2align 2
.Lsprgrad_one:
	.float 1.0
.Lsprgrad_fixed16:
	.float 65536.0
.Lsprgrad_half:
	.float 0.5
	.text
	.p2align 4,,15
	.globl C(D_SpriteCalculateGradients_asm486)
C(D_SpriteCalculateGradients_asm486):
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	subl	$64,%esp
	movl	8(%ebp),%ebx		// sprite_height from C-owned raster state

	// TransformVector retains Quake's view-axis products and addition order.
	leal	-12(%ebp),%eax		// p_normal
	pushl	%eax
	leal	C(r_spritedesc)+36,%eax	// spritedesc.vpn
	pushl	%eax
	call	C(TransformVector)
	addl	$8,%esp
	leal	-24(%ebp),%eax		// p_saxis
	pushl	%eax
	leal	C(r_spritedesc)+24,%eax	// spritedesc.vright
	pushl	%eax
	call	C(TransformVector)
	addl	$8,%esp
	leal	-36(%ebp),%eax		// p_taxis
	pushl	%eax
	leal	C(r_spritedesc)+12,%eax	// spritedesc.vup
	pushl	%eax
	call	C(TransformVector)
	addl	$8,%esp
	flds	-36(%ebp)
	fchs
	fstps	-36(%ebp)
	flds	-32(%ebp)
	fchs
	fstps	-32(%ebp)
	flds	-28(%ebp)
	fchs
	fstps	-28(%ebp)

	// distinv = 1 / -DotProduct(modelorg, vpn), rounded to float.
	flds	C(modelorg)
	fmuls	C(r_spritedesc)+36
	flds	C(modelorg)+4
	fmuls	C(r_spritedesc)+40
	faddp	%st(0),%st(1)
	flds	C(modelorg)+8
	fmuls	C(r_spritedesc)+44
	faddp	%st(0),%st(1)
	fchs
	fdivrs	.Lsprgrad_one
	// GCC's C reference keeps distinv extended in an x87 register instead of
	// rounding the float local to memory. Keep it below subsequent temporaries.

	// The six per-pixel steps are stored as floats before origin calculation.
	flds	-24(%ebp)
	fmuls	C(xscaleinv)
	fstps	C(d_sdivzstepu)
	flds	-36(%ebp)
	fmuls	C(xscaleinv)
	fstps	C(d_tdivzstepu)
	flds	-20(%ebp)
	fmuls	C(yscaleinv)
	fchs
	fstps	C(d_sdivzstepv)
	flds	-32(%ebp)
	fmuls	C(yscaleinv)
	fchs
	fstps	C(d_tdivzstepv)
	flds	-12(%ebp)
	fmuls	C(xscaleinv)
	fmul	%st(1),%st(0)
	fsts	C(d_zistepu)		// keep the extended result for d_ziorigin
	flds	-8(%ebp)
	fmuls	C(yscaleinv)
	fchs
	fmul	%st(2),%st(0)
	fsts	C(d_zistepv)		// C keeps both z steps live in x87 registers

	// axis[2] - xcenter*stepu - ycenter*stepv, using stored float steps.
	flds	-16(%ebp)
	flds	C(xcenter)
	fmuls	C(d_sdivzstepu)
	fsubrp	%st(0),%st(1)
	flds	C(ycenter)
	fmuls	C(d_sdivzstepv)
	fsubrp	%st(0),%st(1)
	fstps	C(d_sdivzorigin)
	flds	-28(%ebp)
	flds	C(xcenter)
	fmuls	C(d_tdivzstepu)
	fsubrp	%st(0),%st(1)
	flds	C(ycenter)
	fmuls	C(d_tdivzstepv)
	fsubrp	%st(0),%st(1)
	fstps	C(d_tdivzorigin)
	flds	-4(%ebp)
	fmul	%st(3),%st(0)		// p_normal[2] * extended distinv
	flds	C(xcenter)
	fmul	%st(3),%st(0)		// xcenter * extended d_zistepu
	fsubrp	%st(0),%st(1)
	flds	C(ycenter)
	fmul	%st(2),%st(0)		// ycenter * extended d_zistepv
	fsubrp	%st(0),%st(1)
	fstps	C(d_ziorigin)
	fstp	%st(0)			// discard retained extended d_zistepv
	fstp	%st(0)			// discard retained extended d_zistepu
	fstp	%st(0)			// discard retained extended distinv

	// Dot products for sadjust/tadjust use the C x87 order and truncation.
	leal	-48(%ebp),%eax		// p_temp1 = TransformVector(modelorg)
	pushl	%eax
	pushl	$C(modelorg)
	call	C(TransformVector)
	addl	$8,%esp
	flds	-48(%ebp)
	fmuls	-24(%ebp)
	flds	-44(%ebp)
	fmuls	-20(%ebp)
	faddp	%st(0),%st(1)
	flds	-40(%ebp)
	fmuls	-16(%ebp)
	faddp	%st(0),%st(1)
	fmuls	.Lsprgrad_fixed16
	fadds	.Lsprgrad_half
	fnstcw	-54(%ebp)
	movw	-54(%ebp),%ax
	orb	$0x0c,%ah		// C float-to-int casts truncate toward zero
	movw	%ax,-56(%ebp)
	fldcw	-56(%ebp)
	fistpl	-60(%ebp)
	fldcw	-54(%ebp)
	movl	C(cachewidth),%eax
	sarl	$1,%eax
	shll	$16,%eax
	addl	-60(%ebp),%eax
	movl	%eax,C(sadjust)

	flds	-48(%ebp)
	fmuls	-36(%ebp)
	flds	-44(%ebp)
	fmuls	-32(%ebp)
	faddp	%st(0),%st(1)
	flds	-40(%ebp)
	fmuls	-28(%ebp)
	faddp	%st(0),%st(1)
	fmuls	.Lsprgrad_fixed16
	fadds	.Lsprgrad_half
	fldcw	-56(%ebp)
	fistpl	-60(%ebp)
	fldcw	-54(%ebp)
	movl	%ebx,%eax
	sarl	$1,%eax
	shll	$16,%eax
	addl	-60(%ebp),%eax
	movl	%eax,C(tadjust)

	movl	C(cachewidth),%eax
	shll	$16,%eax
	decl	%eax
	movl	%eax,C(bbextents)
	movl	%ebx,%eax
	shll	$16,%eax
	decl	%eax
	movl	%eax,C(bbextentt)

	leal	-4(%ebp),%esp
	popl	%ebx
	leave
	ret
#endif

#if defined(ASM486_SPRITE_SCAN_LEFT) || defined(BENCH486)
	.section .rodata
	.p2align 2
.Lsprscanleft_fixed16:
	.float 65536.0
	.text
	.p2align 4,,15
	.globl C(D_SpriteScanLeftEdge_asm486)
C(D_SpriteScanLeftEdge_asm486):
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	subl	$72,%esp
	movl	8(%ebp),%edi		// output sspan_t cursor
	movl	12(%ebp),%ebx		// minindex
	movl	16(%ebp),%eax		// maxindex, with zero meaning nump
	movl	20(%ebp),%ecx		// nump
	movl	%ecx,-72(%ebp)
	movl	24(%ebp),%esi		// emitpoint_t array
	movl	%eax,-24(%ebp)
	testl	%ebx,%ebx
	jne	.Lsprscanleft_min_ready
	movl	%ecx,%ebx
.Lsprscanleft_min_ready:
	cmpl	$0,-24(%ebp)
	jne	.Lsprscanleft_max_ready
	movl	%ecx,-24(%ebp)
.Lsprscanleft_max_ready:

	fnstcw	-64(%ebp)
	movw	-64(%ebp),%ax
	andb	$0xf3,%ah
	orb	$0x08,%ah		// FRNDINT rounds toward +infinity for ceil
	movw	%ax,-66(%ebp)
	movw	-64(%ebp),%ax
	orb	$0x0c,%ah		// C float-to-int casts truncate toward zero
	movw	%ax,-68(%ebp)

.Lsprscanleft_segment:
	movl	%ebx,%eax
	imull	$20,%eax
	leal	(%esi,%eax),%edx	// pvert = &pverts[i]
	flds	4(%edx)
	fldcw	-66(%ebp)
	frndint
	fldcw	-64(%ebp)
	fstps	-28(%ebp)		// vtop = ceil(pvert->v), rounded to float

	leal	-20(%edx),%ecx		// pnext = pvert - 1 emitpoint_t
	flds	4(%ecx)
	fldcw	-66(%ebp)
	frndint
	fldcw	-64(%ebp)
	fstps	-32(%ebp)		// vbottom = ceil(pnext->v)

	flds	-28(%ebp)
	fcoms	-32(%ebp)
	fnstsw	%ax
	sahf
	fstp	%st(0)
	jae	.Lsprscanleft_next_segment

	// slope=(pnext.u-pvert.u)/(pnext.v-pvert.v), kept as a float local.
	flds	(%ecx)
	fsubs	(%edx)
	fstps	-36(%ebp)		// du
	flds	4(%ecx)
	fsubs	4(%edx)
	fstps	-40(%ebp)		// dv
	flds	-36(%ebp)
	fdivs	-40(%ebp)
	fstps	-44(%ebp)		// slope

	// u_step=(int)(slope*65536), with the caller's rounding mode preserved.
	flds	-44(%ebp)
	fmuls	.Lsprscanleft_fixed16
	fldcw	-68(%ebp)
	fistpl	-52(%ebp)		// u_step
	fldcw	-64(%ebp)

	// Ceil the fixed-point edge start after evaluating the source expression.
	flds	-28(%ebp)
	fsubs	4(%edx)			// vtop - pvert.v
	fmuls	-44(%ebp)
	fadds	(%edx)			// pvert.u + slope*(vtop-pvert.v)
	fmuls	.Lsprscanleft_fixed16
	fldcw	-68(%ebp)
	fistpl	-48(%ebp)		// u before the integer-pixel ceiling bias
	fldcw	-64(%ebp)
	addl	$65535,-48(%ebp)	// ceil the integer portion

	// v boundaries are integral after ceil(); use explicit C-style casts.
	flds	-28(%ebp)
	fldcw	-68(%ebp)
	fistpl	-56(%ebp)		// itop
	fldcw	-64(%ebp)
	flds	-32(%ebp)
	fldcw	-68(%ebp)
	fistpl	-60(%ebp)		// ibottom
	fldcw	-64(%ebp)

	movl	-56(%ebp),%ecx
.Lsprscanleft_row:
	cmpl	-60(%ebp),%ecx
	jge	.Lsprscanleft_next_segment
	movl	-48(%ebp),%eax
	sarl	$16,%eax
	movl	%eax,0(%edi)		// span.u
	movl	%ecx,4(%edi)		// span.v
	movl	-52(%ebp),%edx
	addl	%edx,-48(%ebp)
	addl	$12,%edi
	incl	%ecx
	jmp	.Lsprscanleft_row

.Lsprscanleft_next_segment:
	movl	-32(%ebp),%eax
	movl	%eax,-28(%ebp)		// vtop = vbottom
	decl	%ebx
	jnz	.Lsprscanleft_check_end
	movl	-72(%ebp),%ebx		// wrap vertex index zero to nump
.Lsprscanleft_check_end:
	cmpl	-24(%ebp),%ebx
	jne	.Lsprscanleft_segment

	leal	-12(%ebp),%esp
	popl	%edi
	popl	%esi
	popl	%ebx
	leave
	ret
#endif

#if defined(ASM486_SPRITE_SCAN_RIGHT) || defined(BENCH486)
	.section .rodata
	.p2align 2
.Lsprscanright_fixed16:
	.float 65536.0
	.text
	.p2align 4,,15
	.globl C(D_SpriteScanRightEdge_asm486)
C(D_SpriteScanRightEdge_asm486):
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	subl	$92,%esp
	movl	8(%ebp),%edi		// output sspan_t cursor
	movl	12(%ebp),%ebx		// first vertex
	movl	16(%ebp),%eax		// stop vertex
	movl	20(%ebp),%ecx		// nump
	movl	%eax,-28(%ebp)
	movl	%ecx,-24(%ebp)
	movl	24(%ebp),%esi		// emitpoint_t array, with duplicate at nump
	movl	28(%ebp),%eax
	movl	%eax,-32(%ebp)		// fvrectx_adj
	movl	32(%ebp),%eax
	movl	%eax,-36(%ebp)		// fvrectright_adj
	movl	36(%ebp),%eax
	movl	%eax,-40(%ebp)		// fvrecty_adj
	movl	40(%ebp),%eax
	movl	%eax,-44(%ebp)		// fvrectbottom_adj

	fnstcw	-98(%ebp)
	movw	-98(%ebp),%ax
	andb	$0xf3,%ah
	orb	$0x08,%ah		// FRNDINT rounds toward +infinity for ceil
	movw	%ax,-100(%ebp)
	movw	-98(%ebp),%ax
	orb	$0x0c,%ah		// C float-to-int casts truncate toward zero
	movw	%ax,-102(%ebp)

	// vvert = clamp(pverts[minindex].v, fvrecty_adj, fvrectbottom_adj).
	movl	%ebx,%eax
	imull	$20,%eax
	leal	(%esi,%eax),%edx
	flds	4(%edx)
	fcoms	-40(%ebp)
	fnstsw	%ax
	sahf
	jae	.Lsprscanright_initial_v_not_top
	jp	.Lsprscanright_initial_v_not_top
	fstp	%st(0)
	flds	-40(%ebp)
	jmp	.Lsprscanright_initial_v_check_bottom
.Lsprscanright_initial_v_not_top:
.Lsprscanright_initial_v_check_bottom:
	fcoms	-44(%ebp)
	fnstsw	%ax
	sahf
	jbe	.Lsprscanright_initial_v_store
	fstp	%st(0)
	flds	-44(%ebp)
.Lsprscanright_initial_v_store:
	fstps	-56(%ebp)		// clipped vvert
	flds	-56(%ebp)
	fldcw	-100(%ebp)
	frndint
	fldcw	-98(%ebp)
	fstps	-48(%ebp)		// vtop=ceil(vvert)

.Lsprscanright_segment:
	movl	%ebx,%eax
	imull	$20,%eax
	leal	(%esi,%eax),%edx	// pvert = &pverts[i]
	leal	20(%edx),%ecx		// pnext = pvert + 1

	// vnext = clamp(pnext->v, fvrecty_adj, fvrectbottom_adj).
	flds	4(%ecx)
	fcoms	-40(%ebp)
	fnstsw	%ax
	sahf
	jae	.Lsprscanright_vnext_not_top
	jp	.Lsprscanright_vnext_not_top
	fstp	%st(0)
	flds	-40(%ebp)
	jmp	.Lsprscanright_vnext_check_bottom
.Lsprscanright_vnext_not_top:
.Lsprscanright_vnext_check_bottom:
	fcoms	-44(%ebp)
	fnstsw	%ax
	sahf
	jbe	.Lsprscanright_vnext_store
	fstp	%st(0)
	flds	-44(%ebp)
.Lsprscanright_vnext_store:
	fstps	-60(%ebp)		// clipped vnext
	flds	-60(%ebp)
	fldcw	-100(%ebp)
	frndint
	fldcw	-98(%ebp)
	fstps	-52(%ebp)		// vbottom=ceil(vnext)

	flds	-48(%ebp)
	fcoms	-52(%ebp)
	fnstsw	%ax
	sahf
	fstp	%st(0)
	jae	.Lsprscanright_next_segment

	// uvert = clamp(pvert->u, fvrectx_adj, fvrectright_adj).
	flds	(%edx)
	fcoms	-32(%ebp)
	fnstsw	%ax
	sahf
	jae	.Lsprscanright_uvert_not_left
	jp	.Lsprscanright_uvert_not_left
	fstp	%st(0)
	flds	-32(%ebp)
	jmp	.Lsprscanright_uvert_check_right
.Lsprscanright_uvert_not_left:
.Lsprscanright_uvert_check_right:
	fcoms	-36(%ebp)
	fnstsw	%ax
	sahf
	jbe	.Lsprscanright_uvert_store
	fstp	%st(0)
	flds	-36(%ebp)
.Lsprscanright_uvert_store:
	fstps	-64(%ebp)

	// unext = clamp(pnext->u, fvrectx_adj, fvrectright_adj).
	flds	(%ecx)
	fcoms	-32(%ebp)
	fnstsw	%ax
	sahf
	jae	.Lsprscanright_unext_not_left
	jp	.Lsprscanright_unext_not_left
	fstp	%st(0)
	flds	-32(%ebp)
	jmp	.Lsprscanright_unext_check_right
.Lsprscanright_unext_not_left:
.Lsprscanright_unext_check_right:
	fcoms	-36(%ebp)
	fnstsw	%ax
	sahf
	jbe	.Lsprscanright_unext_store
	fstp	%st(0)
	flds	-36(%ebp)
.Lsprscanright_unext_store:
	fstps	-68(%ebp)

	// slope=(unext-uvert)/(vnext-vvert), stored as the C float locals are.
	flds	-68(%ebp)
	fsubs	-64(%ebp)
	fstps	-72(%ebp)		// du
	flds	-60(%ebp)
	fsubs	-56(%ebp)
	fstps	-76(%ebp)		// dv
	flds	-72(%ebp)
	fdivs	-76(%ebp)
	fstps	-80(%ebp)		// slope

	// u_step=(int)(slope*65536), truncating independently of caller RC.
	flds	-80(%ebp)
	fmuls	.Lsprscanright_fixed16
	fldcw	-102(%ebp)
	fistpl	-84(%ebp)
	fldcw	-98(%ebp)

	// Preserve the reference expression order before applying the pixel bias.
	flds	-48(%ebp)
	fsubs	-56(%ebp)			// vtop - vvert
	fmuls	-80(%ebp)
	fadds	-64(%ebp)			// uvert + slope*(vtop-vvert)
	fmuls	.Lsprscanright_fixed16
	fldcw	-102(%ebp)
	fistpl	-88(%ebp)
	fldcw	-98(%ebp)
	addl	$65535,-88(%ebp)	// ceil the integer-pixel portion

	flds	-48(%ebp)
	fldcw	-102(%ebp)
	fistpl	-92(%ebp)		// itop
	fldcw	-98(%ebp)
	flds	-52(%ebp)
	fldcw	-102(%ebp)
	fistpl	-96(%ebp)		// ibottom
	fldcw	-98(%ebp)

	movl	-92(%ebp),%eax
.Lsprscanright_row:
	cmpl	-96(%ebp),%eax
	jge	.Lsprscanright_next_segment
	movl	-88(%ebp),%edx
	sarl	$16,%edx
	subl	0(%edi),%edx
	movl	%edx,8(%edi)		// count = right_u - left_u
	movl	-84(%ebp),%edx
	addl	%edx,-88(%ebp)
	addl	$12,%edi
	incl	%eax
	jmp	.Lsprscanright_row

.Lsprscanright_next_segment:
	movl	-52(%ebp),%eax
	movl	%eax,-48(%ebp)		// vtop = vbottom
	movl	-60(%ebp),%eax
	movl	%eax,-56(%ebp)		// vvert = vnext
	incl	%ebx
	cmpl	-24(%ebp),%ebx
	jne	.Lsprscanright_check_end
	xorl	%ebx,%ebx
.Lsprscanright_check_end:
	cmpl	-28(%ebp),%ebx
	jne	.Lsprscanright_segment

	movl	$-128,8(%edi)		// DS_SPAN_LIST_END
	leal	-12(%ebp),%esp
	popl	%edi
	popl	%esi
	popl	%ebx
	leave
	ret
#endif

#if defined(ASM486_SPRITE_DRAW) || defined(BENCH486)
	.extern C(sprite_spans)
	.extern C(sprite_height)
	.extern C(minindex)
	.extern C(maxindex)
	.extern C(cachewidth)
	.extern C(cacheblock)
	.extern C(D_SpriteCalculateGradients)
	.extern C(D_SpriteScanLeftEdge)
	.extern C(D_SpriteScanRightEdge)
	.extern C(D_SpriteDrawSpans)
	.section .rodata
	.p2align 2
.Ldrawsprite_ymin_initial:
	.float 999999.9
.Ldrawsprite_ymax_initial:
	.float -999999.9
	.text
	.p2align 4,,15
	.globl C(D_DrawSprite_asm486)
C(D_DrawSprite_asm486):
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	// 1025 sspan_t records (12300 bytes), with separate locals above them.
	subl	$12352,%esp
	movl	8(%ebp),%eax
	movl	%eax,-16(%ebp)		// nump
	movl	12(%ebp),%esi
	movl	%esi,-20(%ebp)		// pverts
	movl	16(%ebp),%eax
	movl	%eax,-24(%ebp)		// frame width
	movl	20(%ebp),%eax
	movl	%eax,-28(%ebp)		// frame height
	movl	24(%ebp),%eax
	movl	%eax,-32(%ebp)		// frame pixels
	leal	-12364(%ebp),%edi	// local spans[MAXHEIGHT+1]
	movl	%edi,-36(%ebp)
	movl	%edi,C(sprite_spans)

	flds	.Ldrawsprite_ymin_initial
	fstps	-40(%ebp)		// ymin
	flds	.Ldrawsprite_ymax_initial
	fstps	-44(%ebp)		// ymax

	xorl	%ebx,%ebx			// i=0
.Ldrawsprite_vertex_loop:
	cmpl	-16(%ebp),%ebx
	jge	.Ldrawsprite_vertex_done
	movl	%ebx,%eax
	imull	$20,%eax
	leal	(%esi,%eax),%edx	// pvert

	// if (pvert->v < ymin), retaining the original float value.
	flds	4(%edx)
	fcoms	-40(%ebp)
	fnstsw	%ax
	sahf
	jae	.Ldrawsprite_min_unchanged
	jp	.Ldrawsprite_min_unchanged
	fstps	-40(%ebp)
	movl	%ebx,C(minindex)
	jmp	.Ldrawsprite_check_max
.Ldrawsprite_min_unchanged:
	fstp	%st(0)

.Ldrawsprite_check_max:
	// if (pvert->v > ymax), also retaining the source float value.
	flds	4(%edx)
	fcoms	-44(%ebp)
	fnstsw	%ax
	sahf
	jbe	.Ldrawsprite_max_unchanged
	fstps	-44(%ebp)
	movl	%ebx,C(maxindex)
	jmp	.Ldrawsprite_next_vertex
.Ldrawsprite_max_unchanged:
	fstp	%st(0)

.Ldrawsprite_next_vertex:
	incl	%ebx
	jmp	.Ldrawsprite_vertex_loop

.Ldrawsprite_vertex_done:
	fnstcw	-46(%ebp)
	movw	-46(%ebp),%ax
	andb	$0xf3,%ah
	orb	$0x08,%ah		// FRNDINT rounds upward for ceil
	movw	%ax,-48(%ebp)
	flds	-40(%ebp)
	fldcw	-48(%ebp)
	frndint
	fldcw	-46(%ebp)
	fstps	-40(%ebp)
	flds	-44(%ebp)
	fldcw	-48(%ebp)
	frndint
	fldcw	-46(%ebp)
	fstps	-44(%ebp)

	// The C path returns when ceil(ymin) >= ceil(ymax).
	flds	-40(%ebp)
	fcoms	-44(%ebp)
	fnstsw	%ax
	sahf
	fstp	%st(0)
	jae	.Ldrawsprite_return

	movl	-24(%ebp),%eax
	movl	%eax,C(cachewidth)
	movl	-28(%ebp),%eax
	movl	%eax,C(sprite_height)
	movl	-32(%ebp),%eax
	movl	%eax,C(cacheblock)

	// pverts[nump] = pverts[0], copying the complete 20-byte emitpoint_t.
	movl	-20(%ebp),%esi
	movl	-16(%ebp),%eax
	imull	$20,%eax
	leal	(%esi,%eax),%edi
	movl	0(%esi),%eax
	movl	%eax,0(%edi)
	movl	4(%esi),%eax
	movl	%eax,4(%edi)
	movl	8(%esi),%eax
	movl	%eax,8(%edi)
	movl	12(%esi),%eax
	movl	%eax,12(%edi)
	movl	16(%esi),%eax
	movl	%eax,16(%edi)

	call	C(D_SpriteCalculateGradients)
	call	C(D_SpriteScanLeftEdge)
	call	C(D_SpriteScanRightEdge)
	pushl	-36(%ebp)
	call	C(D_SpriteDrawSpans)
	addl	$4,%esp

.Ldrawsprite_return:
	leal	-12(%ebp),%esp
	popl	%edi
	popl	%esi
	popl	%ebx
	leave
	ret
#endif

#if defined(ASM486_SPRITE_SETUP) || defined(BENCH486)
	.extern C(clip_current)
	.extern C(clip_verts)
	.extern C(sprite_width)
	.extern C(sprite_height)
	.extern C(r_spritedesc)
	.extern C(r_entorigin)
	.extern C(r_origin)
	.extern C(modelorg)
	.extern C(view_clipplanes)
	.extern C(vright)
	.extern C(vup)
	.extern C(vpn)
	.extern C(xscale)
	.extern C(yscale)
	.extern C(xcenter)
	.extern C(ycenter)
	.extern C(R_ClipSpriteFace)
	.extern C(TransformVector)
	.extern C(D_DrawSprite)
	.extern C(Sys_Error)
	.section .rodata
	.p2align 2
.Lsprite_setup_zero:
	.float 0.0
.Lsprite_setup_near_clip:
	.float 0.01
.Lsprite_setup_nearzi_initial:
	.float -999999.0
.Lsprite_setup_too_many:
	.string "R_SetupAndDrawSprite: too many points"
	.text
	.p2align 4,,15
	.globl C(R_SetupAndDrawSprite_asm486)
C(R_SetupAndDrawSprite_asm486):
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	// 21 emitpoint_t outputs occupy 420 bytes; the remaining locals sit above.
	subl	$640,%esp
	leal	-652(%ebp),%edi
	movl	%edi,-32(%ebp)		// outverts
	movl	C(r_spritedesc)+8,%eax
	movl	%eax,-16(%ebp)		// pspriteframe

	// Backface cull: dot(vpn, modelorg) >= 0 returns without touching spans.
	flds	C(r_spritedesc)+36
	fmuls	C(modelorg)
	flds	C(r_spritedesc)+40
	fmuls	C(modelorg)+4
	faddp	%st,%st(1)
	flds	C(r_spritedesc)+44
	fmuls	C(modelorg)+8
	faddp	%st,%st(1)
	fstps	-120(%ebp)
	flds	-120(%ebp)
	fcoms	.Lsprite_setup_zero
	fnstsw	%ax
	sahf
	fstp	%st(0)
	jae	.Lsprite_setup_return

	// Scale frame bounds along the sprite's world-space up and right axes.
	movl	-16(%ebp),%eax
	flds	C(r_spritedesc)+24
	fmuls	24(%eax)			// frame.right
	fstps	-72(%ebp)
	flds	C(r_spritedesc)+28
	fmuls	24(%eax)
	fstps	-76(%ebp)
	flds	C(r_spritedesc)+32
	fmuls	24(%eax)
	fstps	-80(%ebp)
	flds	C(r_spritedesc)+24
	fmuls	20(%eax)			// frame.left
	fstps	-48(%ebp)
	flds	C(r_spritedesc)+28
	fmuls	20(%eax)
	fstps	-52(%ebp)
	flds	C(r_spritedesc)+32
	fmuls	20(%eax)
	fstps	-56(%ebp)
	flds	C(r_spritedesc)+12
	fmuls	12(%eax)			// frame.up
	fstps	-60(%ebp)
	flds	C(r_spritedesc)+16
	fmuls	12(%eax)
	fstps	-64(%ebp)
	flds	C(r_spritedesc)+20
	fmuls	12(%eax)
	fstps	-68(%ebp)
	flds	C(r_spritedesc)+12
	fmuls	16(%eax)			// frame.down
	fstps	-84(%ebp)
	flds	C(r_spritedesc)+16
	fmuls	16(%eax)
	fstps	-88(%ebp)
	flds	C(r_spritedesc)+20
	fmuls	16(%eax)
	fstps	-92(%ebp)

	// Construct the four (x,y,z,s,t) poster corners in original order.
	flds	C(r_entorigin)
	fadds	-60(%ebp)
	fadds	-48(%ebp)
	fstps	C(clip_verts)
	flds	C(r_entorigin)+4
	fadds	-64(%ebp)
	fadds	-52(%ebp)
	fstps	C(clip_verts)+4
	flds	C(r_entorigin)+8
	fadds	-68(%ebp)
	fadds	-56(%ebp)
	fstps	C(clip_verts)+8

	flds	C(r_entorigin)
	fadds	-60(%ebp)
	fadds	-72(%ebp)
	fstps	C(clip_verts)+20
	flds	C(r_entorigin)+4
	fadds	-64(%ebp)
	fadds	-76(%ebp)
	fstps	C(clip_verts)+24
	flds	C(r_entorigin)+8
	fadds	-68(%ebp)
	fadds	-80(%ebp)
	fstps	C(clip_verts)+28

	flds	C(r_entorigin)
	fadds	-84(%ebp)
	fadds	-72(%ebp)
	fstps	C(clip_verts)+40
	flds	C(r_entorigin)+4
	fadds	-88(%ebp)
	fadds	-76(%ebp)
	fstps	C(clip_verts)+44
	flds	C(r_entorigin)+8
	fadds	-92(%ebp)
	fadds	-80(%ebp)
	fstps	C(clip_verts)+48

	flds	C(r_entorigin)
	fadds	-84(%ebp)
	fadds	-48(%ebp)
	fstps	C(clip_verts)+60
	flds	C(r_entorigin)+4
	fadds	-88(%ebp)
	fadds	-52(%ebp)
	fstps	C(clip_verts)+64
	flds	C(r_entorigin)+8
	fadds	-92(%ebp)
	fadds	-56(%ebp)
	fstps	C(clip_verts)+68

	movl	$0,C(clip_verts)+12
	movl	$0,C(clip_verts)+16
	fildl	C(sprite_width)
	fstps	C(clip_verts)+32
	movl	$0,C(clip_verts)+36
	fildl	C(sprite_width)
	fstps	C(clip_verts)+52
	fildl	C(sprite_height)
	fstps	C(clip_verts)+56
	movl	$0,C(clip_verts)+72
	fildl	C(sprite_height)
	fstps	C(clip_verts)+76

	// Each face clip toggles clip_current and writes the next winding buffer.
	movl	$0,C(clip_current)
	movl	$4,-20(%ebp)		// nump
	xorl	%ebx,%ebx
.Lsprite_setup_clip_loop:
	cmpl	$4,%ebx
	jge	.Lsprite_setup_clipped
	movl	%ebx,%eax
	imull	$24,%eax			// sizeof(clipplane_t), layout asserted in C
	leal	C(view_clipplanes)(%eax),%eax
	pushl	%eax
	pushl	-20(%ebp)
	call	C(R_ClipSpriteFace)
	addl	$8,%esp
	movl	%eax,-20(%ebp)
	cmpl	$3,%eax
	jl	.Lsprite_setup_return
	cmpl	$20,%eax			// MAXWORKINGVERTS, layout asserted in C
	jl	.Lsprite_setup_clip_next
	pushl	$.Lsprite_setup_too_many
	call	C(Sys_Error)
	addl	$4,%esp
	jmp	.Lsprite_setup_return
.Lsprite_setup_clip_next:
	incl	%ebx
	jmp	.Lsprite_setup_clip_loop

.Lsprite_setup_clipped:
	movl	C(clip_current),%eax
	imull	$400,%eax			// sizeof(clip_verts[0]), asserted in C
	leal	C(clip_verts)(%eax),%esi
	flds	.Lsprite_setup_nearzi_initial
	fstps	C(r_spritedesc)+48
	xorl	%ebx,%ebx			// i=0
.Lsprite_setup_project_loop:
	cmpl	-20(%ebp),%ebx
	jge	.Lsprite_setup_project_done
	movl	%ebx,%eax
	imull	$20,%eax
	leal	(%esi,%eax),%edx		// pv
	movl	%edx,-36(%ebp)
	// local = pv.xyz - r_origin, then use the legacy assembly TransformVector.
	flds	(%edx)
	fsubs	C(r_origin)
	fstps	-104(%ebp)
	flds	4(%edx)
	fsubs	C(r_origin)+4
	fstps	-100(%ebp)
	flds	8(%edx)
	fsubs	C(r_origin)+8
	fstps	-96(%ebp)
	leal	-116(%ebp),%eax		// transformed output: x,y,z occupy -116..-108
	leal	-104(%ebp),%edx		// contiguous local input: x,y,z at -104..-96
	pushl	%eax
	pushl	%edx
	call	C(TransformVector)
	addl	$8,%esp

	// Preserve the reference near-plane clamp before calculating reciprocal z.
	flds	-108(%ebp)
	fcoms	.Lsprite_setup_near_clip
	fnstsw	%ax
	sahf
	fstp	%st(0)
	jp	.Lsprite_setup_depth_ready
	jae	.Lsprite_setup_depth_ready
	flds	.Lsprite_setup_near_clip
	fstps	-108(%ebp)
.Lsprite_setup_depth_ready:
	fld1
	fdivs	-108(%ebp)
	fstps	16(%edi)			// pout->zi
	flds	16(%edi)
	fcoms	C(r_spritedesc)+48
	fnstsw	%ax
	sahf
	jbe	.Lsprite_setup_nearzi_unchanged
	fstps	C(r_spritedesc)+48
	jmp	.Lsprite_setup_nearzi_done
.Lsprite_setup_nearzi_unchanged:
	fstp	%st(0)
.Lsprite_setup_nearzi_done:

	movl	-36(%ebp),%edx
	movl	12(%edx),%eax
	movl	%eax,8(%edi)		// pout->s
	movl	16(%edx),%eax
	movl	%eax,12(%edi)		// pout->t
	flds	C(xscale)
	fmuls	16(%edi)
	fstps	-40(%ebp)			// scale = xscale * zi
	flds	-40(%ebp)
	fmuls	-116(%ebp)
	fadds	C(xcenter)
	fstps	(%edi)			// pout->u
	flds	C(yscale)
	fmuls	16(%edi)
	fstps	-44(%ebp)			// scale = yscale * zi
	flds	-44(%ebp)
	fmuls	-112(%ebp)
	fchs
	fadds	C(ycenter)
	fstps	4(%edi)			// pout->v = ycenter - scale * transformed.y
	addl	$20,%edi
	incl	%ebx
	jmp	.Lsprite_setup_project_loop

.Lsprite_setup_project_done:
	movl	-20(%ebp),%eax
	movl	%eax,C(r_spritedesc)		// nump
	movl	-32(%ebp),%eax
	movl	%eax,C(r_spritedesc)+4	// pverts = outverts
	call	C(D_DrawSprite)

.Lsprite_setup_return:
	leal	-12(%ebp),%esp
	popl	%edi
	popl	%esi
	popl	%ebx
	leave
	ret
#endif

#ifdef ASM486_EDGE_DRAWING
	.extern C(auxedges)
	.extern C(r_edges)
	.extern C(r_surfsonstack)
	.extern C(r_cnumsurfs)
	.extern C(surfaces)
	.extern C(surf_max)
	.extern C(r_dspeeds)
	.extern C(r_drawpolys)
	.extern C(r_drawculledpolys)
	.extern C(rw_time1)
	.extern C(rw_time2)
	.extern C(db_time1)
	.extern C(db_time2)
	.extern C(se_time1)
	.extern C(R_SurfacePatch)
	.extern C(R_BeginEdgeFrame)
	.extern C(R_RenderWorld)
	.extern C(R_ScanEdges)
	.extern C(D_TurnZOn)
	.extern C(R_DrawBEntitiesOnList)
	.extern C(S_ExtraUpdate)
	.extern C(Sys_FloatTime)
#ifdef PROFILE486
	.extern C(R_EdgeDrawingProfileEnter_asm486)
	.extern C(R_EdgeDrawingProfileLeave_asm486)
	.extern C(R_EdgeDrawingProfileWorldStart_asm486)
	.extern C(R_EdgeDrawingProfileWorldEnd_asm486)
	.extern C(R_EdgeDrawingProfileBrushEnter_asm486)
	.extern C(R_EdgeDrawingProfileBrushLeave_asm486)
#endif

	.text
	.p2align 4,,15
	.globl C(R_EdgeDrawing_asm486)
C(R_EdgeDrawing_asm486):
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	/*
	 * R_EdgeDrawing's local arrays are 2401 edge_t records (32 bytes each)
	 * and 801 surf_t records (64 bytes each), with each base aligned to 32.
	 * The C layout checks in r_main.c pin these sizes and counts. 128160 bytes
	 * includes the worst-case alignment slop for both arrays.
	 */
	subl	$128160,%esp

#ifdef PROFILE486
	call	C(R_EdgeDrawingProfileEnter_asm486)
#endif

	/* r_edges uses the caller-provided buffer when one exists. */
	movl	C(auxedges),%eax
	testl	%eax,%eax
	jz	.Ledge_drawing_local_edges
	movl	%eax,C(r_edges)
	jmp	.Ledge_drawing_edges_ready
.Ledge_drawing_local_edges:
	leal	31(%esp),%esi
	andl	$-32,%esi
	movl	%esi,C(r_edges)
.Ledge_drawing_edges_ready:

	/* Preserve the original stack-surface path and dummy surface zero. */
	cmpl	$0,C(r_surfsonstack)
	je	.Ledge_drawing_surfaces_ready
	leal	31(%esp),%esi
	andl	$-32,%esi
	leal	76863(%esi),%edi	/* end of the 2401-entry edge array + align pad */
	andl	$-32,%edi
	movl	%edi,C(surfaces)
	movl	C(r_cnumsurfs),%eax
	shll	$6,%eax
	addl	%edi,%eax
	movl	%eax,C(surf_max)
	subl	$64,%edi
	movl	%edi,C(surfaces)
	call	C(R_SurfacePatch)
.Ledge_drawing_surfaces_ready:

	call	C(R_BeginEdgeFrame)

	/* C's float truth test treats signed zero as false and NaN as true. */
	call	.Ledge_drawing_dspeeds_enabled
	testl	%eax,%eax
	jz	.Ledge_drawing_after_rw_start_time
	call	C(Sys_FloatTime)
	fstps	C(rw_time1)
.Ledge_drawing_after_rw_start_time:

#ifdef PROFILE486
	call	C(R_EdgeDrawingProfileWorldStart_asm486)
#endif
	call	C(R_RenderWorld)
#ifdef PROFILE486
	call	C(R_EdgeDrawingProfileWorldEnd_asm486)
#endif

	cmpl	$0,C(r_drawculledpolys)
	je	.Ledge_drawing_after_culled_scan
	call	C(R_ScanEdges)
.Ledge_drawing_after_culled_scan:

	/* Only the world is drawn back-to-front without Z compares. */
	call	C(D_TurnZOn)

	call	.Ledge_drawing_dspeeds_enabled
	testl	%eax,%eax
	jz	.Ledge_drawing_after_entity_start_time
	call	C(Sys_FloatTime)
	fstps	C(rw_time2)
	movl	C(rw_time2),%eax
	movl	%eax,C(db_time1)
.Ledge_drawing_after_entity_start_time:

#ifdef PROFILE486
	call	C(R_EdgeDrawingProfileBrushEnter_asm486)
#endif
	call	C(R_DrawBEntitiesOnList)
#ifdef PROFILE486
	call	C(R_EdgeDrawingProfileBrushLeave_asm486)
#endif

	call	.Ledge_drawing_dspeeds_enabled
	testl	%eax,%eax
	jz	.Ledge_drawing_after_entity_end_time
	call	C(Sys_FloatTime)
	fstps	C(db_time2)
	movl	C(db_time2),%eax
	movl	%eax,C(se_time1)
.Ledge_drawing_after_entity_end_time:

	call	.Ledge_drawing_dspeeds_enabled
	testl	%eax,%eax
	jnz	.Ledge_drawing_after_extra_update
	call	C(S_ExtraUpdate)
.Ledge_drawing_after_extra_update:

	/* Scan once at the end unless a polygon mode already scans explicitly. */
	movl	C(r_drawpolys),%eax
	orl	C(r_drawculledpolys),%eax
	testl	%eax,%eax
	jnz	.Ledge_drawing_after_final_scan
	call	C(R_ScanEdges)
.Ledge_drawing_after_final_scan:

#ifdef PROFILE486
	call	C(R_EdgeDrawingProfileLeave_asm486)
#endif

	leal	-12(%ebp),%esp
	popl	%edi
	popl	%esi
	popl	%ebx
	popl	%ebp
	ret

.Ledge_drawing_dspeeds_enabled:
	flds	C(r_dspeeds)+16
	ftst
	fnstsw	%ax
	fstp	%st(0)
	sahf
	jp	.Ledge_drawing_dspeeds_true
	jne	.Ledge_drawing_dspeeds_true
	xorl	%eax,%eax
	ret
.Ledge_drawing_dspeeds_true:
	movl	$1,%eax
	ret
#endif

#ifdef ASM486_SCAN_EDGES
	.extern C(newedges)
	.extern C(removeedges)
	.extern C(current_iv)
	.extern C(edge_head_u_shift20)
	.extern C(edge_tail_u_shift20)
	.extern C(pdrawfunc)
	.extern C(edge_head)
	.extern C(edge_tail)
	.extern C(edge_aftertail)
	.extern C(edge_sentinel)
	.extern C(fv)
	.extern C(max_span_p)
	.extern C(span_p)
	.extern C(surface_p)
	.extern C(surfaces)
	.extern C(r_refdef)
	.extern C(r_drawculledpolys)
	.extern C(R_InsertNewEdges)
	.extern C(R_RemoveEdges)
	.extern C(R_StepActiveU)
	.extern C(R_DrawCulledPolys)
	.extern C(D_DrawSurfaces)
	.extern C(S_ExtraUpdate)
#ifdef PROFILE486
	.extern C(bench486_profile_frame_active)
	.extern C(bench486_scanlines)
	.extern C(bench486_edge_insert_calls)
	.extern C(bench486_edge_remove_calls)
	.extern C(bench486_edge_step_calls)
	.extern C(bench486_span_flushes)
	.extern C(R_ScanEdgesProfileBegin_asm486)
	.extern C(R_ScanEdgesProfileEnd_asm486)
#endif

	.text
	.p2align 4,,15
	.globl C(R_ScanEdges_asm486)
C(R_ScanEdges_asm486):
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	/* 3000 espan_t records plus 32 bytes of alignment slack and locals. */
	subl	$48096,%esp
	leal	31(%esp),%esi
	andl	$-32,%esi

#ifdef PROFILE486
	movl	C(bench486_scanlines),%eax
	movl	%eax,-16(%ebp)
	leal	-24(%ebp),%eax
	pushl	%eax
	call	C(R_ScanEdgesProfileBegin_asm486)
	addl	$4,%esp
#endif

	/* span_p and max_span_p point into this invocation's aligned stack spans. */
	movl	%esi,C(span_p)
	movl	C(r_refdef)+rd_vrect_width,%eax
	negl	%eax
	addl	$3000,%eax
	shll	$4,%eax
	addl	%esi,%eax
	movl	%eax,C(max_span_p)

	/* Establish the background edge pair and terminal sentinels. */
	movl	C(r_refdef)+rd_vrect_x,%eax
	shll	$20,%eax
	movl	%eax,C(edge_head)+et_u
	sarl	$20,%eax
	movl	%eax,C(edge_head_u_shift20)
	movl	$0,C(edge_head)+et_u_step
	movl	$0,C(edge_head)+et_prev
	leal	C(edge_tail),%edx
	movl	%edx,C(edge_head)+et_next
	movw	$0,C(edge_head)+et_surfs
	movw	$1,C(edge_head)+et_surfs+2

	movl	C(r_refdef)+rd_vrectright,%eax
	shll	$20,%eax
	addl	$0xfffff,%eax
	movl	%eax,C(edge_tail)+et_u
	sarl	$20,%eax
	movl	%eax,C(edge_tail_u_shift20)
	movl	$0,C(edge_tail)+et_u_step
	leal	C(edge_head),%edx
	movl	%edx,C(edge_tail)+et_prev
	leal	C(edge_aftertail),%edx
	movl	%edx,C(edge_tail)+et_next
	movw	$1,C(edge_tail)+et_surfs
	movw	$0,C(edge_tail)+et_surfs+2

	movl	$-1,C(edge_aftertail)+et_u
	movl	$0,C(edge_aftertail)+et_u_step
	leal	C(edge_sentinel),%edx
	movl	%edx,C(edge_aftertail)+et_next
	leal	C(edge_tail),%edx
	movl	%edx,C(edge_aftertail)+et_prev
	movl	$0xd0000000,C(edge_sentinel)+et_u
	leal	C(edge_aftertail),%edx
	movl	%edx,C(edge_sentinel)+et_prev

	/* The C loop scans [vrect.y, vrectbottom - 1), then draws the final row. */
	movl	C(r_refdef)+rd_vrectbottom,%edi
	decl	%edi
	movl	C(r_refdef)+rd_vrect_y,%ebx
.Lscan_edges_row:
	cmpl	%edi,%ebx
	jge	.Lscan_edges_last_row
#ifdef PROFILE486
	cmpl	$0,C(bench486_profile_frame_active)
	je	.Lscan_edges_count_row_done
	incl	C(bench486_scanlines)
.Lscan_edges_count_row_done:
#endif
	movl	%ebx,C(current_iv)
	fildl	C(current_iv)
	fstps	C(fv)
	movl	C(surfaces),%eax
	movl	$1,st_spanstate+64(%eax)

	movl	C(newedges)(,%ebx,4),%eax
	testl	%eax,%eax
	je	.Lscan_edges_no_new_edges
#ifdef PROFILE486
	cmpl	$0,C(bench486_profile_frame_active)
	je	.Lscan_edges_insert_count_done
	incl	C(bench486_edge_insert_calls)
.Lscan_edges_insert_count_done:
#endif
	movl	C(edge_head)+et_next,%edx
	pushl	%edx
	pushl	%eax
	call	C(R_InsertNewEdges)
	addl	$8,%esp
.Lscan_edges_no_new_edges:
	movl	C(pdrawfunc),%eax
	call	*%eax

	/* Flush spans before the next line when the reserved span buffer is low. */
	movl	C(span_p),%eax
	cmpl	C(max_span_p),%eax
	jb	.Lscan_edges_no_flush
	call	C(S_ExtraUpdate)
	cmpl	$0,C(r_drawculledpolys)
	jne	.Lscan_edges_flush_culled
#ifdef PROFILE486
	cmpl	$0,C(bench486_profile_frame_active)
	je	.Lscan_edges_span_count_done
	incl	C(bench486_span_flushes)
.Lscan_edges_span_count_done:
#endif
	call	C(D_DrawSurfaces)
	jmp	.Lscan_edges_clear_spans
.Lscan_edges_flush_culled:
	call	C(R_DrawCulledPolys)
.Lscan_edges_clear_spans:
	movl	C(surfaces),%eax
	leal	st_size(%eax),%eax
	movl	C(surface_p),%edx
.Lscan_edges_clear_span_loop:
	cmpl	%edx,%eax
	jae	.Lscan_edges_spans_cleared
	movl	$0,st_spans(%eax)
	addl	$st_size,%eax
	jmp	.Lscan_edges_clear_span_loop
.Lscan_edges_spans_cleared:
	movl	%esi,C(span_p)
.Lscan_edges_no_flush:

	movl	C(removeedges)(,%ebx,4),%eax
	testl	%eax,%eax
	je	.Lscan_edges_no_removedges
#ifdef PROFILE486
	cmpl	$0,C(bench486_profile_frame_active)
	je	.Lscan_edges_remove_count_done
	incl	C(bench486_edge_remove_calls)
.Lscan_edges_remove_count_done:
#endif
	pushl	%eax
	call	C(R_RemoveEdges)
	addl	$4,%esp
.Lscan_edges_no_removedges:
	movl	C(edge_head)+et_next,%eax
	leal	C(edge_tail),%edx
	cmpl	%edx,%eax
	je	.Lscan_edges_no_step
#ifdef PROFILE486
	cmpl	$0,C(bench486_profile_frame_active)
	je	.Lscan_edges_step_count_done
	incl	C(bench486_edge_step_calls)
.Lscan_edges_step_count_done:
#endif
	pushl	%eax
	call	C(R_StepActiveU)
	addl	$4,%esp
.Lscan_edges_no_step:
	incl	%ebx
	jmp	.Lscan_edges_row

.Lscan_edges_last_row:
#ifdef PROFILE486
	cmpl	$0,C(bench486_profile_frame_active)
	je	.Lscan_edges_last_count_done
	incl	C(bench486_scanlines)
.Lscan_edges_last_count_done:
#endif
	movl	%ebx,C(current_iv)
	fildl	C(current_iv)
	fstps	C(fv)
	movl	C(surfaces),%eax
	movl	$1,st_spanstate+64(%eax)
	movl	C(newedges)(,%ebx,4),%eax
	testl	%eax,%eax
	je	.Lscan_edges_last_no_edges
#ifdef PROFILE486
	cmpl	$0,C(bench486_profile_frame_active)
	je	.Lscan_edges_last_insert_count_done
	incl	C(bench486_edge_insert_calls)
.Lscan_edges_last_insert_count_done:
#endif
	movl	C(edge_head)+et_next,%edx
	pushl	%edx
	pushl	%eax
	call	C(R_InsertNewEdges)
	addl	$8,%esp
.Lscan_edges_last_no_edges:
	movl	C(pdrawfunc),%eax
	call	*%eax

	cmpl	$0,C(r_drawculledpolys)
	jne	.Lscan_edges_final_culled
#ifdef PROFILE486
	cmpl	$0,C(bench486_profile_frame_active)
	je	.Lscan_edges_final_count_done
	incl	C(bench486_span_flushes)
.Lscan_edges_final_count_done:
#endif
	call	C(D_DrawSurfaces)
	jmp	.Lscan_edges_profile_end
.Lscan_edges_final_culled:
	call	C(R_DrawCulledPolys)

.Lscan_edges_profile_end:
#ifdef PROFILE486
	pushl	-16(%ebp)
	leal	-24(%ebp),%eax
	pushl	%eax
	call	C(R_ScanEdgesProfileEnd_asm486)
	addl	$8,%esp
#endif
	leal	-12(%ebp),%esp
	popl	%edi
	popl	%esi
	popl	%ebx
	popl	%ebp
	ret
#endif

#ifdef ASM486_EDGE_LIST
	.extern C(edge_aftertail)
	.extern C(edge_tail)

	.text
	.p2align 4,,15
	.globl C(R_InsertNewEdges_asm486)
C(R_InsertNewEdges_asm486):
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	movl	16(%esp),%ebx		/* edge to insert */
	movl	20(%esp),%esi		/* sorted active-list cursor */
.Linsert_new_edges_next:
	movl	et_next(%ebx),%edi	/* preserve the source-chain successor */
.Linsert_new_edges_search:
	movl	et_u(%esi),%eax
	cmpl	et_u(%ebx),%eax
	jge	.Linsert_new_edges_found
	movl	et_next(%esi),%esi
	movl	et_u(%esi),%eax
	cmpl	et_u(%ebx),%eax
	jge	.Linsert_new_edges_found
	movl	et_next(%esi),%esi
	movl	et_u(%esi),%eax
	cmpl	et_u(%ebx),%eax
	jge	.Linsert_new_edges_found
	movl	et_next(%esi),%esi
	movl	et_u(%esi),%eax
	cmpl	et_u(%ebx),%eax
	jge	.Linsert_new_edges_found
	movl	et_next(%esi),%esi
	jmp	.Linsert_new_edges_search
.Linsert_new_edges_found:
	movl	%esi,et_next(%ebx)
	movl	et_prev(%esi),%eax
	movl	%eax,et_prev(%ebx)
	movl	%ebx,et_next(%eax)
	movl	%ebx,et_prev(%esi)
	movl	%edi,%ebx
	testl	%ebx,%ebx
	jne	.Linsert_new_edges_next
	popl	%edi
	popl	%esi
	popl	%ebx
	ret

	.p2align 4,,15
	.globl C(R_RemoveEdges_asm486)
C(R_RemoveEdges_asm486):
	pushl	%ebx
	movl	8(%esp),%ebx
.Lremove_edges_loop:
	movl	et_next(%ebx),%eax
	movl	et_prev(%ebx),%edx
	movl	%edx,et_prev(%eax)
	movl	%eax,et_next(%edx)
	movl	et_nextremove(%ebx),%ebx
	testl	%ebx,%ebx
	jne	.Lremove_edges_loop
	popl	%ebx
	ret

	.p2align 4,,15
	.globl C(R_StepActiveU_asm486)
C(R_StepActiveU_asm486):
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	movl	16(%esp),%ebx
.Lstep_active_u_group:
	/* Keep the original four-edge unroll used by the C reference. */
	movl	et_u(%ebx),%eax
	addl	et_u_step(%ebx),%eax
	movl	%eax,et_u(%ebx)
	movl	et_prev(%ebx),%edx
	cmpl	et_u(%edx),%eax
	jl	.Lstep_active_u_pushback
	movl	et_next(%ebx),%ebx

	movl	et_u(%ebx),%eax
	addl	et_u_step(%ebx),%eax
	movl	%eax,et_u(%ebx)
	movl	et_prev(%ebx),%edx
	cmpl	et_u(%edx),%eax
	jl	.Lstep_active_u_pushback
	movl	et_next(%ebx),%ebx

	movl	et_u(%ebx),%eax
	addl	et_u_step(%ebx),%eax
	movl	%eax,et_u(%ebx)
	movl	et_prev(%ebx),%edx
	cmpl	et_u(%edx),%eax
	jl	.Lstep_active_u_pushback
	movl	et_next(%ebx),%ebx

	movl	et_u(%ebx),%eax
	addl	et_u_step(%ebx),%eax
	movl	%eax,et_u(%ebx)
	movl	et_prev(%ebx),%edx
	cmpl	et_u(%edx),%eax
	jl	.Lstep_active_u_pushback
	movl	et_next(%ebx),%ebx
	jmp	.Lstep_active_u_group

.Lstep_active_u_pushback:
	leal	C(edge_aftertail),%eax
	cmpl	%eax,%ebx
	je	.Lstep_active_u_done
	movl	et_next(%ebx),%esi		/* pnext_edge */
	movl	et_prev(%ebx),%edx
	movl	et_next(%ebx),%eax
	movl	%edx,et_prev(%eax)
	movl	%eax,et_next(%edx)
	movl	et_prev(%edx),%edi		/* previous edge's previous edge */
.Lstep_active_u_find:
	movl	et_u(%edi),%eax
	cmpl	et_u(%ebx),%eax
	jle	.Lstep_active_u_reinsert
	movl	et_prev(%edi),%edi
	jmp	.Lstep_active_u_find
.Lstep_active_u_reinsert:
	movl	et_next(%edi),%eax
	movl	%eax,et_next(%ebx)
	movl	%edi,et_prev(%ebx)
	movl	%ebx,et_prev(%eax)
	movl	%ebx,et_next(%edi)
	movl	%esi,%ebx
	leal	C(edge_tail),%eax
	cmpl	%eax,%ebx
	jne	.Lstep_active_u_group
.Lstep_active_u_done:
	popl	%edi
	popl	%esi
	popl	%ebx
	ret
#endif

#ifdef ASM486_BACKWARD_SPANS
	.extern C(r_bmodelactive)
	.extern C(surfaces)
	.extern C(span_p)
	.extern C(current_iv)
	.extern C(edge_head_u_shift20)
	.extern C(edge_tail_u_shift20)
	.extern C(edge_head)
	.extern C(edge_tail)

	.p2align 4,,15
	.globl C(R_CleanupSpan_asm486)
C(R_CleanupSpan_asm486):
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	movl	C(surfaces),%eax
	leal	st_size(%eax),%edi		// surfaces[1]
	movl	st_next(%edi),%ebx		// current top
	movl	C(edge_tail_u_shift20),%eax
	cmpl	st_last_u(%ebx),%eax
	jle	.Lbackspan_cleanup_reset
	movl	C(span_p),%esi
	movl	st_last_u(%ebx),%edx
	movl	%edx,espan_t_u(%esi)
	subl	%edx,%eax
	movl	%eax,espan_t_count(%esi)
	movl	C(current_iv),%eax
	movl	%eax,espan_t_v(%esi)
	movl	st_spans(%ebx),%eax
	movl	%eax,espan_t_pnext(%esi)
	movl	%esi,st_spans(%ebx)
	leal	espan_t_size(%esi),%eax
	movl	%eax,C(span_p)

.Lbackspan_cleanup_reset:
	movl	C(surfaces),%eax
	leal	st_size(%eax),%edi		// surfaces[1]
	movl	st_next(%edi),%ebx
.Lbackspan_cleanup_loop:
	movl	$0,st_spanstate(%ebx)
	movl	st_next(%ebx),%ebx
	cmpl	%edi,%ebx
	jne	.Lbackspan_cleanup_loop
	popl	%edi
	popl	%esi
	popl	%ebx
	ret

	.p2align 4,,15
	.globl C(R_TrailingEdge_asm486)
C(R_TrailingEdge_asm486):
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	movl	16(%esp),%edi			// surf
	movl	20(%esp),%ebx			// edge
	decl	st_spanstate(%edi)
	jnz	.Lbackspan_trailing_return
	cmpl	$0,st_insubmodel(%edi)
	je	.Lbackspan_trailing_top_test
	decl	C(r_bmodelactive)
.Lbackspan_trailing_top_test:
	movl	C(surfaces),%eax
	leal	st_size(%eax),%eax
	cmpl	st_next(%eax),%edi
	jne	.Lbackspan_trailing_unlink
	movl	et_u(%ebx),%esi
	sarl	$20,%esi				// iu = edge->u >> 20
	cmpl	st_last_u(%edi),%esi
	jle	.Lbackspan_trailing_update_below
	movl	C(span_p),%eax
	movl	st_last_u(%edi),%edx
	movl	%edx,espan_t_u(%eax)
	movl	%esi,%ecx
	subl	%edx,%ecx
	movl	%ecx,espan_t_count(%eax)
	movl	C(current_iv),%ecx
	movl	%ecx,espan_t_v(%eax)
	movl	st_spans(%edi),%ecx
	movl	%ecx,espan_t_pnext(%eax)
	movl	%eax,st_spans(%edi)
	leal	espan_t_size(%eax),%eax
	movl	%eax,C(span_p)
.Lbackspan_trailing_update_below:
	movl	st_next(%edi),%edx
	movl	%esi,st_last_u(%edx)
.Lbackspan_trailing_unlink:
	movl	st_next(%edi),%eax
	movl	st_prev(%edi),%edx
	movl	%eax,st_next(%edx)
	movl	%edx,st_prev(%eax)
.Lbackspan_trailing_return:
	popl	%edi
	popl	%esi
	popl	%ebx
	ret

	.p2align 4,,15
	.globl C(R_LeadingEdgeBackwards_asm486)
C(R_LeadingEdgeBackwards_asm486):
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	movl	16(%esp),%ebx			// edge
	movl	C(surfaces),%eax
	movzwl	et_surfs+2(%ebx),%edx
	shll	$6,%edx
	leal	(%eax,%edx),%edi		// surf = surfaces[edge->surfs[1]]
	incl	st_spanstate(%edi)
	cmpl	$1,st_spanstate(%edi)
	jne	.Lbackspan_leading_return
	movl	C(surfaces),%eax
	leal	st_size(%eax),%esi		// surfaces[1]
	movl	st_next(%esi),%esi		// surf2 = current top
	movl	st_key(%edi),%eax
	cmpl	st_key(%esi),%eax
	jg	.Lbackspan_leading_newtop
	cmpl	st_key(%esi),%eax
	jne	.Lbackspan_leading_search
	cmpl	$0,st_insubmodel(%edi)
	jne	.Lbackspan_leading_newtop

.Lbackspan_leading_search:
	movl	st_key(%edi),%eax
.Lbackspan_leading_search_next:
	movl	st_next(%esi),%esi
	cmpl	st_key(%esi),%eax
	jl	.Lbackspan_leading_search_next
	cmpl	st_key(%esi),%eax
	jne	.Lbackspan_leading_insert
	cmpl	$0,st_insubmodel(%edi)
	je	.Lbackspan_leading_search_next
	jmp	.Lbackspan_leading_insert

.Lbackspan_leading_newtop:
	movl	et_u(%ebx),%eax
	sarl	$20,%eax				// iu = edge->u >> 20
	cmpl	st_last_u(%esi),%eax
	jle	.Lbackspan_leading_set_last
	movl	C(span_p),%edx
	movl	st_last_u(%esi),%ecx
	movl	%ecx,espan_t_u(%edx)
	subl	%ecx,%eax
	movl	%eax,espan_t_count(%edx)
	movl	C(current_iv),%eax
	movl	%eax,espan_t_v(%edx)
	movl	st_spans(%esi),%eax
	movl	%eax,espan_t_pnext(%edx)
	movl	%edx,st_spans(%esi)
	leal	espan_t_size(%edx),%edx
	movl	%edx,C(span_p)
	movl	et_u(%ebx),%eax
	sarl	$20,%eax
.Lbackspan_leading_set_last:
	movl	%eax,st_last_u(%edi)

.Lbackspan_leading_insert:
	movl	st_prev(%esi),%eax
	movl	%esi,st_next(%edi)
	movl	%eax,st_prev(%edi)
	movl	%edi,st_next(%eax)
	movl	%edi,st_prev(%esi)
.Lbackspan_leading_return:
	popl	%edi
	popl	%esi
	popl	%ebx
	ret

	.p2align 4,,15
	.globl C(R_GenerateSpansBackward_asm486)
C(R_GenerateSpansBackward_asm486):
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	movl	$0,C(r_bmodelactive)
	movl	C(surfaces),%eax
	leal	st_size(%eax),%edi		// surfaces[1]
	movl	%edi,st_next(%edi)
	movl	%edi,st_prev(%edi)
	movl	C(edge_head_u_shift20),%eax
	movl	%eax,st_last_u(%edi)
	movl	C(edge_head)+et_next,%ebx
.Lbackspan_generate_loop:
	cmpl	$C(edge_tail),%ebx
	je	.Lbackspan_generate_cleanup
	movzwl	et_surfs(%ebx),%eax
	testl	%eax,%eax
	je	.Lbackspan_generate_leading
	movl	C(surfaces),%edi
	shll	$6,%eax
	addl	%eax,%edi
	pushl	%ebx
	pushl	%edi
	call	C(R_TrailingEdge_asm486)
	addl	$8,%esp
.Lbackspan_generate_leading:
	movzwl	et_surfs+2(%ebx),%eax
	testl	%eax,%eax
	je	.Lbackspan_generate_next
	pushl	%ebx
	call	C(R_LeadingEdgeBackwards_asm486)
	addl	$4,%esp
.Lbackspan_generate_next:
	movl	et_next(%ebx),%ebx
	jmp	.Lbackspan_generate_loop
.Lbackspan_generate_cleanup:
	call	C(R_CleanupSpan_asm486)
	popl	%edi
	popl	%esi
	popl	%ebx
	ret
#endif

#ifdef ASM486_EMIT_CACHED_EDGE
	.extern C(r_pedge)
	.extern C(r_edges)
	.extern C(surface_p)
	.extern C(surfaces)
	.extern C(r_nearzi)
	.extern C(r_emitted)
#ifdef PROFILE486
	.extern C(bench486_profile_frame_active)
	.extern C(bench486_emitcachededge_calls)
#endif

	.text
	.p2align 4,,15
	.globl C(R_EmitCachedEdge_asm486)
C(R_EmitCachedEdge_asm486):
#ifdef PROFILE486
	cmpl	$0,C(bench486_profile_frame_active)
	je	.Lemit_cached_profile_done
	incl	C(bench486_emitcachededge_calls)
.Lemit_cached_profile_done:
#endif

	/* The cached edge offset is relative to the active frame edge buffer. */
	movl	C(r_pedge),%edx
	movl	me_cachededgeoffset(%edx),%ecx
	addl	C(r_edges),%ecx

	/* Fill the first empty surface slot, matching the C short stores. */
	cmpw	$0,et_surfs(%ecx)
	jne	.Lemit_cached_surf1
	movl	C(surface_p),%eax
	subl	C(surfaces),%eax
	sarl	$SURF_T_SHIFT,%eax
	movw	%ax,et_surfs(%ecx)
	jmp	.Lemit_cached_nearzi
.Lemit_cached_surf1:
	movl	C(surface_p),%eax
	subl	C(surfaces),%eax
	sarl	$SURF_T_SHIFT,%eax
	movw	%ax,et_surfs+2(%ecx)

.Lemit_cached_nearzi:
	/* Strict ordered comparison; always pop the temporary x87 value. */
	flds	et_nearzi(%ecx)
	fcoms	C(r_nearzi)
	fnstsw	%ax
	testb	$0x45,%ah
	jnz	.Lemit_cached_keep_nearzi
	fstps	C(r_nearzi)
	jmp	.Lemit_cached_nearzi_done
.Lemit_cached_keep_nearzi:
	fstp	%st(0)
.Lemit_cached_nearzi_done:
	movl	$1,C(r_emitted)
	ret
#endif

#ifdef ASM486_RENDER_FACE
	.extern C(R_ClipEdge)
	.extern C(R_RenderFaceGradient_asm486)
	.extern C(c_faceclip)
	.extern C(r_currentkey)
	.extern C(r_polycount)
	.extern C(r_outofsurfaces)
	.extern C(r_outofedges)
	.extern C(surf_max)
	.extern C(surface_p)
	.extern C(surfaces)
	.extern C(edge_p)
	.extern C(edge_max)
	.extern C(r_edges)
	.extern C(insubmodel)
	.extern C(r_pedge)
	.extern C(r_leftclipped)
	.extern C(r_rightclipped)
	.extern C(makeleftedge)
	.extern C(makerightedge)
	.extern C(r_nearzionly)
	.extern C(r_nearzi)
	.extern C(r_emitted)
	.extern C(r_lastvertvalid)
	.extern C(cacheoffset)
	.extern C(r_framecount)
	.extern C(r_pcurrentvertbase)
	.extern C(view_clipplanes)
	.extern C(r_leftexit)
	.extern C(r_leftenter)
	.extern C(r_rightexit)
	.extern C(r_rightenter)
	.extern C(currententity)

#ifdef PROFILE486
	.extern C(bench486_profile_frame_active)
	.extern C(bench486_renderface_calls)
	.extern C(bench486_renderface_emitted)
	.extern C(bench486_renderface_edge_setups)
	.extern C(bench486_renderface_early_surfs)
	.extern C(bench486_renderface_early_edges)
	.extern C(bench486_renderface_faces)
	.extern C(bench486_renderface_general_edges)
	.extern C(bench486_emitcachededge_calls)
#endif

	.equ RF_PCLIP, -16
	.equ RF_TEDGE, -24
	.equ RF_INDEX, -28
	.equ RF_MEDGE, -32
	.equ RF_VERT0, -36
	.equ RF_VERT1, -40

	.text
	.globl C(R_RenderFace_asm486)
C(R_RenderFace_asm486):
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	subl	$28,%esp

	movl	8(%ebp),%ebx			/* msurface_t *fa */
	movl	20(%ebp),%esi			/* model surfedges + firstedge */

#ifdef PROFILE486
	cmpl	$0,C(bench486_profile_frame_active)
	je	.Lrf_profile_entry_done
	incl	C(bench486_renderface_calls)
	movl	24(%ebx),%eax
	addl	%eax,C(bench486_renderface_edge_setups)
	movl	12(%ebp),%eax
	andl	$15,%eax
	movl	%eax,%edx
	shrl	$1,%edx
	andl	$5,%eax
	andl	$5,%edx
	addl	%edx,%eax
	movl	%eax,%edx
	shrl	$2,%edx
	andl	$3,%eax
	andl	$3,%edx
	addl	%edx,%eax
	andl	$15,%eax
	addl	%eax,C(bench486_renderface_faces)
.Lrf_profile_entry_done:
#endif

	/* if ((surface_p) >= surf_max) */
	movl	C(surface_p),%eax
	movl	24(%ebx),%edx
	cmpl	C(surf_max),%eax
	jae	.Lrf_early_surfaces

	/* if (edge_p + fa->numedges + 4) >= edge_max */
	leal	4(%edx),%ecx
	shll	$5,%ecx
	addl	C(edge_p),%ecx
	cmpl	C(edge_max),%ecx
	jae	.Lrf_early_edges

	incl	C(c_faceclip)

	/* Build the same 3..0 clip chain as the C reference. */
	xorl	%eax,%eax
	movl	12(%ebp),%edx
	testl	$8,%edx
	je	.Lrf_clip2
	movl	$C(view_clipplanes)+72,%ecx
	movl	%eax,16(%ecx)
	movl	%ecx,%eax
.Lrf_clip2:
	testl	$4,%edx
	je	.Lrf_clip1
	movl	$C(view_clipplanes)+48,%ecx
	movl	%eax,16(%ecx)
	movl	%ecx,%eax
.Lrf_clip1:
	testl	$2,%edx
	je	.Lrf_clip0
	movl	$C(view_clipplanes)+24,%ecx
	movl	%eax,16(%ecx)
	movl	%ecx,%eax
.Lrf_clip0:
	testl	$1,%edx
	je	.Lrf_clip_ready
	movl	$C(view_clipplanes),%ecx
	movl	%eax,16(%ecx)
	movl	%ecx,%eax
.Lrf_clip_ready:
	movl	%eax,RF_PCLIP(%ebp)

	movl	$0,C(r_emitted)
	movl	$0,C(r_nearzi)
	movl	$0,C(r_nearzionly)
	movl	$0,C(makeleftedge)
	movl	$0,C(makerightedge)
	movl	$0,C(r_lastvertvalid)

#ifdef PROFILE486
	cmpl	$0,C(bench486_profile_frame_active)
	je	.Lrf_profile_edges_done
	movl	24(%ebx),%eax
	testl	%eax,%eax
	jle	.Lrf_profile_edges_done
	cmpl	$3,%eax
	je	.Lrf_profile_edges_done
	cmpl	$4,%eax
	je	.Lrf_profile_edges_done
	addl	%eax,C(bench486_renderface_general_edges)
.Lrf_profile_edges_done:
#endif

	movl	$0,RF_INDEX(%ebp)
.Lrf_edge_loop:
	movl	RF_INDEX(%ebp),%edi
	cmpl	24(%ebx),%edi
	jge	.Lrf_edges_done
	movl	(%esi,%edi,4),%eax
	movl	16(%ebp),%ecx			/* medge_t *pedges */
	testl	%eax,%eax
	jle	.Lrf_reverse_edge
	leal	(%ecx,%eax,8),%edx
	movl	%edx,RF_MEDGE(%ebp)
	movl	%edx,C(r_pedge)
	movzwl	0(%edx),%eax
	movzwl	2(%edx),%edx
	jmp	.Lrf_edge_vertices
.Lrf_reverse_edge:
	negl	%eax
	leal	(%ecx,%eax,8),%edx
	movl	%edx,RF_MEDGE(%ebp)
	movl	%edx,C(r_pedge)
	movzwl	2(%edx),%eax
	movzwl	0(%edx),%edx
.Lrf_edge_vertices:
	/* EAX/EDX are the ordered vertex indices; form byte addresses. */
	movl	C(r_pcurrentvertbase),%ecx
	leal	(%eax,%eax,2),%eax
	leal	(%ecx,%eax,4),%eax
	movl	%eax,RF_VERT0(%ebp)
	movl	C(r_pcurrentvertbase),%ecx
	leal	(%edx,%edx,2),%edx
	leal	(%ecx,%edx,4),%edx
	movl	%edx,RF_VERT1(%ebp)

	cmpl	$0,C(insubmodel)
	jne	.Lrf_clip_edge
	movl	RF_MEDGE(%ebp),%ecx
	movl	4(%ecx),%eax
	testl	$0x80000000,%eax
	je	.Lrf_check_regular_cache
	andl	$0x7fffffff,%eax
	cmpl	C(r_framecount),%eax
	jne	.Lrf_clip_edge
	movl	$0,C(r_lastvertvalid)
	jmp	.Lrf_next_edge

.Lrf_check_regular_cache:
	movl	C(edge_p),%eax
	subl	C(r_edges),%eax
	cmpl	4(%ecx),%eax
	jbe	.Lrf_clip_edge
	movl	4(%ecx),%edx
	addl	C(r_edges),%edx
	movl	28(%edx),%eax
	cmpl	%ecx,%eax
	jne	.Lrf_clip_edge

	/* Match the cached-edge surface assignment used by R_EmitCachedEdge. */
#ifdef PROFILE486
	cmpl	$0,C(bench486_profile_frame_active)
	je	.Lrf_cached_profile_done
	incl	C(bench486_emitcachededge_calls)
.Lrf_cached_profile_done:
#endif
	movzwl	16(%edx),%eax
	testl	%eax,%eax
	jne	.Lrf_cached_surf1
	movl	C(surface_p),%eax
	subl	C(surfaces),%eax
	sarl	$6,%eax
	movw	%ax,16(%edx)
	jmp	.Lrf_cached_nearzi
.Lrf_cached_surf1:
	/* edge_t.surfs[] are unsigned shorts; never overwrite both slots. */
	movl	C(surface_p),%eax
	subl	C(surfaces),%eax
	sarl	$6,%eax
	movw	%ax,18(%edx)
.Lrf_cached_nearzi:
	flds	24(%edx)
	fcoms	C(r_nearzi)
	fnstsw	%ax
	testb	$0x45,%ah
	jnz	.Lrf_cached_nearzi_keep
	fstps	C(r_nearzi)
	jmp	.Lrf_cached_nearzi_done
.Lrf_cached_nearzi_keep:
	fstp	%st(0)
.Lrf_cached_nearzi_done:
	movl	$1,C(r_emitted)
	movl	$0,C(r_lastvertvalid)
	jmp	.Lrf_next_edge

.Lrf_clip_edge:
	movl	C(edge_p),%eax
	subl	C(r_edges),%eax
	movl	%eax,C(cacheoffset)
	movl	$0,C(r_leftclipped)
	movl	$0,C(r_rightclipped)
	pushl	RF_PCLIP(%ebp)
	pushl	RF_VERT1(%ebp)
	pushl	RF_VERT0(%ebp)
	call	C(R_ClipEdge)
	addl	$12,%esp
	movl	RF_MEDGE(%ebp),%ecx
	movl	C(cacheoffset),%eax
	movl	%eax,4(%ecx)
	cmpl	$0,C(r_leftclipped)
	je	.Lrf_left_flag_done
	movl	$1,C(makeleftedge)
.Lrf_left_flag_done:
	cmpl	$0,C(r_rightclipped)
	je	.Lrf_right_flag_done
	movl	$1,C(makerightedge)
.Lrf_right_flag_done:
	movl	$1,C(r_lastvertvalid)

.Lrf_next_edge:
	incl	RF_INDEX(%ebp)
	jmp	.Lrf_edge_loop

.Lrf_edges_done:
	cmpl	$0,C(makeleftedge)
	je	.Lrf_right_clip
	leal	RF_TEDGE(%ebp),%eax
	movl	%eax,C(r_pedge)
	movl	$0,C(r_lastvertvalid)
	movl	RF_PCLIP(%ebp),%eax
	movl	16(%eax),%eax
	pushl	%eax
	pushl	$C(r_leftenter)
	pushl	$C(r_leftexit)
	call	C(R_ClipEdge)
	addl	$12,%esp

.Lrf_right_clip:
	cmpl	$0,C(makerightedge)
	je	.Lrf_post_surface
	leal	RF_TEDGE(%ebp),%eax
	movl	%eax,C(r_pedge)
	movl	$0,C(r_lastvertvalid)
	movl	$1,C(r_nearzionly)
	movl	C(view_clipplanes)+40,%eax
	pushl	%eax
	pushl	$C(r_rightenter)
	pushl	$C(r_rightexit)
	call	C(R_ClipEdge)
	addl	$12,%esp

.Lrf_post_surface:
	cmpl	$0,C(r_emitted)
	je	.Lrf_return
#ifdef PROFILE486
	cmpl	$0,C(bench486_profile_frame_active)
	je	.Lrf_profile_emitted_done
	incl	C(bench486_renderface_emitted)
.Lrf_profile_emitted_done:
#endif
	incl	C(r_polycount)
	movl	C(surface_p),%eax
	movl	%ebx,28(%eax)
	movl	C(r_nearzi),%edx
	movl	%edx,36(%eax)
	movl	16(%ebx),%edx
	movl	%edx,24(%eax)
	movl	C(insubmodel),%edx
	movl	%edx,40(%eax)
	movl	$0,20(%eax)
	movl	C(currententity),%edx
	movl	%edx,32(%eax)
	movl	C(r_currentkey),%edx
	movl	%edx,12(%eax)
	incl	C(r_currentkey)
	movl	$0,8(%eax)
	movl	12(%ebx),%eax
	pushl	%eax
	call	C(R_RenderFaceGradient_asm486)
	addl	$4,%esp
	movl	C(surface_p),%eax
	addl	$64,%eax
	movl	%eax,C(surface_p)
	jmp	.Lrf_return

.Lrf_early_surfaces:
	incl	C(r_outofsurfaces)
#ifdef PROFILE486
	cmpl	$0,C(bench486_profile_frame_active)
	je	.Lrf_return
	incl	C(bench486_renderface_early_surfs)
#endif
	jmp	.Lrf_return

.Lrf_early_edges:
	movl	24(%ebx),%eax
	addl	%eax,C(r_outofedges)
#ifdef PROFILE486
	cmpl	$0,C(bench486_profile_frame_active)
	je	.Lrf_return
	incl	C(bench486_renderface_early_edges)
#endif

.Lrf_return:
	leal	-12(%ebp),%esp
	popl	%edi
	popl	%esi
	popl	%ebx
	popl	%ebp
	ret

#endif

#ifdef ASM486_RENDER_BMODEL_FACE
	.extern C(R_ClipEdge)
	.extern C(R_RenderBmodelFaceGradient_asm486)
	.extern C(c_faceclip)
	.extern C(r_polycount)
	.extern C(r_outofsurfaces)
	.extern C(r_outofedges)
	.extern C(surf_max)
	.extern C(surface_p)
	.extern C(r_currentbkey)
	.extern C(edge_p)
	.extern C(edge_max)
	.extern C(r_clipflags)
	.extern C(r_pedge)
	.extern C(r_leftclipped)
	.extern C(r_rightclipped)
	.extern C(makeleftedge)
	.extern C(makerightedge)
	.extern C(r_nearzionly)
	.extern C(r_nearzi)
	.extern C(r_emitted)
	.extern C(r_lastvertvalid)
	.extern C(view_clipplanes)
	.extern C(r_leftexit)
	.extern C(r_leftenter)
	.extern C(r_rightexit)
	.extern C(r_rightenter)
	.extern C(currententity)

.equ RBMF_PCLIP, -16
	.equ RBMF_TEDGE, -28

	.text
	.globl C(R_RenderBmodelFace_asm486)
C(R_RenderBmodelFace_asm486):
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	subl	$16,%esp

	movl	12(%ebp),%ebx			/* msurface_t *psurf */
	movl	8(%ebp),%esi			/* bedge_t *pedges */

	/* if (surface_p >= surf_max) */
	movl	C(surface_p),%eax
	cmpl	C(surf_max),%eax
	jae	.Lrbmf_early_surfaces

	/* if ((edge_p + psurf->numedges + 4) >= edge_max) */
	movl	24(%ebx),%edx
	leal	4(%edx),%ecx
	shll	$5,%ecx
	addl	C(edge_p),%ecx
	cmpl	C(edge_max),%ecx
	jae	.Lrbmf_early_edges

	incl	C(c_faceclip)

	/* The clipped bmodel edge path uses this temporary owner for all edges. */
	leal	RBMF_TEDGE(%ebp),%eax
	movl	%eax,C(r_pedge)

	/* Build the same 3..0 clip chain as the C reference. */
	xorl	%eax,%eax
	movl	C(r_clipflags),%edx
	testl	$8,%edx
	je	.Lrbmf_clip2
	movl	$C(view_clipplanes)+72,%ecx
	movl	%eax,16(%ecx)
	movl	%ecx,%eax
.Lrbmf_clip2:
	testl	$4,%edx
	je	.Lrbmf_clip1
	movl	$C(view_clipplanes)+48,%ecx
	movl	%eax,16(%ecx)
	movl	%ecx,%eax
.Lrbmf_clip1:
	testl	$2,%edx
	je	.Lrbmf_clip0
	movl	$C(view_clipplanes)+24,%ecx
	movl	%eax,16(%ecx)
	movl	%ecx,%eax
.Lrbmf_clip0:
	testl	$1,%edx
	je	.Lrbmf_clip_ready
	movl	$C(view_clipplanes),%ecx
	movl	%eax,16(%ecx)
	movl	%ecx,%eax
.Lrbmf_clip_ready:
	movl	%eax,RBMF_PCLIP(%ebp)

	movl	$0,C(r_emitted)
	movl	$0,C(r_nearzi)
	movl	$0,C(r_nearzionly)
	movl	$0,C(makeleftedge)
	movl	$0,C(makerightedge)
	movl	$0,C(r_lastvertvalid)

.Lrbmf_edge_loop:
	testl	%esi,%esi
	je	.Lrbmf_edges_done
	movl	$0,C(r_leftclipped)
	movl	$0,C(r_rightclipped)
	pushl	RBMF_PCLIP(%ebp)
	pushl	4(%esi)				/* bedge_t::v[1] */
	pushl	0(%esi)				/* bedge_t::v[0] */
	call	C(R_ClipEdge)
	addl	$12,%esp
	cmpl	$0,C(r_leftclipped)
	je	.Lrbmf_left_flag_done
	movl	$1,C(makeleftedge)
.Lrbmf_left_flag_done:
	cmpl	$0,C(r_rightclipped)
	je	.Lrbmf_right_flag_done
	movl	$1,C(makerightedge)
.Lrbmf_right_flag_done:
	movl	8(%esi),%esi			/* bedge_t::pnext */
	jmp	.Lrbmf_edge_loop

.Lrbmf_edges_done:
	cmpl	$0,C(makeleftedge)
	je	.Lrbmf_right_clip
	leal	RBMF_TEDGE(%ebp),%eax
	movl	%eax,C(r_pedge)
	movl	RBMF_PCLIP(%ebp),%eax
	movl	16(%eax),%eax
	pushl	%eax
	pushl	$C(r_leftenter)
	pushl	$C(r_leftexit)
	call	C(R_ClipEdge)
	addl	$12,%esp

.Lrbmf_right_clip:
	cmpl	$0,C(makerightedge)
	je	.Lrbmf_post_surface
	leal	RBMF_TEDGE(%ebp),%eax
	movl	%eax,C(r_pedge)
	movl	$1,C(r_nearzionly)
	movl	C(view_clipplanes)+40,%eax
	pushl	%eax
	pushl	$C(r_rightenter)
	pushl	$C(r_rightexit)
	call	C(R_ClipEdge)
	addl	$12,%esp

.Lrbmf_post_surface:
	cmpl	$0,C(r_emitted)
	je	.Lrbmf_return
	incl	C(r_polycount)
	movl	C(surface_p),%edi
	movl	%ebx,28(%edi)			/* data = psurf */
	movl	C(r_nearzi),%eax
	movl	%eax,36(%edi)
	movl	16(%ebx),%eax
	movl	%eax,24(%edi)			/* flags */
	movl	$1,40(%edi)			/* insubmodel = true */
	movl	$0,20(%edi)			/* spanstate */
	movl	C(currententity),%eax
	movl	%eax,32(%edi)
	movl	C(r_currentbkey),%eax
	movl	%eax,12(%edi)
	movl	$0,8(%edi)			/* spans */
	movl	12(%ebx),%eax			/* psurf->plane */
	pushl	%eax
	call	C(R_RenderBmodelFaceGradient_asm486)
	addl	$4,%esp
	movl	C(surface_p),%eax
	addl	$64,%eax
	movl	%eax,C(surface_p)
	jmp	.Lrbmf_return

.Lrbmf_early_surfaces:
	incl	C(r_outofsurfaces)
	jmp	.Lrbmf_return

.Lrbmf_early_edges:
	movl	24(%ebx),%eax
	addl	%eax,C(r_outofedges)

.Lrbmf_return:
	leal	-12(%ebp),%esp
	popl	%edi
	popl	%esi
	popl	%ebx
	popl	%ebp
	ret

#endif

#ifdef ASM486_RENDER_POLY
	.extern C(currententity)
	.extern C(view_clipplanes)
	.extern C(r_pcurrentvertbase)
	.extern C(r_pedge)
	.extern C(r_nearzi)
	.extern C(r_polydesc)
	.extern C(modelorg)
	.extern C(xscale)
	.extern C(yscale)
	.extern C(xcenter)
	.extern C(ycenter)
	.extern C(r_refdef)
	.extern C(TransformVector)
	.extern C(D_DrawPoly)

	.equ RPX_ENTITY_MODEL, 132
	.equ RPX_MODEL_EDGES, 156
	.equ RPX_MODEL_SURFEDGES, 188
	.equ RPX_SURFACE_PLANE, 12
	.equ RPX_SURFACE_FIRSTEDGE, 20
	.equ RPX_SURFACE_NUMEDGES, 24
	.equ RPX_MEDGE_SIZE, 8
	.equ RPX_MVERTEX_SIZE, 12
	.equ RPX_CLIP_DIST, 12
	.equ RPX_CLIP_NEXT, 16
	.equ RPX_CLIP_SIZE, 24
	.equ RPX_POLYVERT_SIZE, 20
	.equ RPX_VERTEX_PAGE_SIZE, 1200
	.equ RPX_STACK_BYTES, 4608
	.equ RPX_VERTS, -4608
	.equ RPX_PVERTS, -2208

	.equ RPX_I, -4
	.equ RPX_MASK, -8
	.equ RPX_LNUMVERTS, -12
	.equ RPX_SAXIS, -16
	.equ RPX_TAXIS, -20
	.equ RPX_LZI, -32
	.equ RPX_DIST, -160
	.equ RPX_LASTDIST, -172
	.equ RPX_FRAC, -184
	.equ RPX_PCLIP, -40
	.equ RPX_PEDGES, -44
	.equ RPX_SURFEDGES, -48
	.equ RPX_CURRPAGE, -52
	.equ RPX_NEWPAGE, -56
	.equ RPX_LASTVERT, -60
	.equ RPX_VISIBLE, -64
	.equ RPX_NEWVERTS, -68
	.equ RPX_MODEL, -72
	.equ RPX_EDGE_CURSOR, -76
	.equ RPX_VERTBASE, -80
	.equ RPX_SRC, -84
	.equ RPX_DST, -88
	.equ RPX_LOCAL, -104
	.equ RPX_TRANSFORMED, -116
	.equ RPX_PVERT_PTR, -120
	.equ RPX_LAST_VERTEX, -124
	.equ RPX_LAST_POSITIVE, -128
	.equ RPX_DIST_POSITIVE, -132
	.equ RPX_CLIP_FLAGS, -136
	.equ RPX_PPLANE, -140

	.section .rodata
	.p2align 3
.Lrpx_near_clip_double:
	.double 0.01
.Lrpx_near_clip_float:
	.long 0x3c23d70a
.Lrpx_reciprocal_numerator:
	.long 0x3f800000
.Lrpx_near_clip_reciprocal:
	.long 0x42c80000

	.text
	.globl C(R_RenderPoly_asm486)
C(R_RenderPoly_asm486):
	pushl	%ebp
	movl	%esp,%ebp
	/* Keep the EBP-relative locals clear of the saved callee registers. */
	subl	$RPX_STACK_BYTES,%esp
	pushl	%ebx
	pushl	%esi
	pushl	%edi

	// Build the linked clip-plane chain in the same descending plane order as C.
	movl	$0,RPX_PCLIP(%ebp)
	movl	12(%ebp),%eax
	movl	%eax,RPX_CLIP_FLAGS(%ebp)
	movl	$3,RPX_I(%ebp)
	movl	$8,RPX_MASK(%ebp)
.Lrpx_clip_chain:
	movl	RPX_CLIP_FLAGS(%ebp),%eax
	testl	RPX_MASK(%ebp),%eax
	je	.Lrpx_clip_chain_next
	movl	RPX_I(%ebp),%eax
	imull	$RPX_CLIP_SIZE,%eax,%eax
	movl	$C(view_clipplanes),%edx
	addl	%eax,%edx
	movl	RPX_PCLIP(%ebp),%ecx
	movl	%ecx,RPX_CLIP_NEXT(%edx)
	movl	%edx,RPX_PCLIP(%ebp)
.Lrpx_clip_chain_next:
	shrl	$1,RPX_MASK(%ebp)
	decl	RPX_I(%ebp)
	jns	.Lrpx_clip_chain

	// Reconstruct the polygon from the model's surfedge and edge tables.
	movl	C(currententity),%eax
	movl	RPX_ENTITY_MODEL(%eax),%eax
	movl	%eax,RPX_MODEL(%ebp)
	movl	RPX_MODEL_EDGES(%eax),%edx
	movl	%edx,RPX_PEDGES(%ebp)
	movl	RPX_MODEL_SURFEDGES(%eax),%edx
	movl	%edx,RPX_SURFEDGES(%ebp)
	movl	8(%ebp),%eax
	movl	RPX_SURFACE_NUMEDGES(%eax),%edx
	cmpl	$100,%edx
	jg	.Lrpx_return
	movl	%edx,RPX_LNUMVERTS(%ebp)
	// The running edge pointer is surfedges + firstedge.
	movl	8(%ebp),%eax
	movl	RPX_SURFACE_FIRSTEDGE(%eax),%ecx
	movl	RPX_SURFEDGES(%ebp),%eax
	leal	(%eax,%ecx,4),%eax
	movl	%eax,RPX_EDGE_CURSOR(%ebp)
	movl	$0,RPX_I(%ebp)
.Lrpx_reconstruct:
	movl	RPX_I(%ebp),%ecx
	cmpl	RPX_LNUMVERTS(%ebp),%ecx
	jge	.Lrpx_reconstruct_done
	movl	RPX_EDGE_CURSOR(%ebp),%eax
	movl	(%eax),%edx
	addl	$4,%eax
	movl	%eax,RPX_EDGE_CURSOR(%ebp)
	testl	%edx,%edx
	jg	.Lrpx_edge_forward
	negl	%edx
	movl	RPX_PEDGES(%ebp),%eax
	leal	(%eax,%edx,RPX_MEDGE_SIZE),%eax
	movl	%eax,C(r_pedge)
	movzwl	2(%eax),%edx
	jmp	.Lrpx_edge_vertex
.Lrpx_edge_forward:
	movl	RPX_PEDGES(%ebp),%eax
	leal	(%eax,%edx,RPX_MEDGE_SIZE),%eax
	movl	%eax,C(r_pedge)
	movzwl	(%eax),%edx
.Lrpx_edge_vertex:
	movl	C(r_pcurrentvertbase),%esi
	leal	(%edx,%edx,2),%edx
	leal	(%esi,%edx,4),%esi
	movl	RPX_I(%ebp),%ecx
	leal	(%ecx,%ecx,2),%ecx
	shll	$2,%ecx
	leal	RPX_VERTS(%ebp,%ecx),%edi
	movl	(%esi),%eax
	movl	%eax,(%edi)
	movl	4(%esi),%eax
	movl	%eax,4(%edi)
	movl	8(%esi),%eax
	movl	%eax,8(%edi)
	incl	RPX_I(%ebp)
	jmp	.Lrpx_reconstruct
.Lrpx_reconstruct_done:

	// Clip against each selected plane, alternating the two 100-vertex pages.
	movl	$0,RPX_CURRPAGE(%ebp)
.Lrpx_clip_loop:
	movl	RPX_PCLIP(%ebp),%edx
	testl	%edx,%edx
	je	.Lrpx_clipping_done
	movl	RPX_LNUMVERTS(%ebp),%eax
	decl	%eax
	movl	%eax,RPX_LASTVERT(%ebp)
	movl	RPX_CURRPAGE(%ebp),%eax
	imull	$RPX_VERTEX_PAGE_SIZE,%eax,%eax
	leal	RPX_VERTS(%ebp,%eax),%esi
	movl	%esi,RPX_VERTBASE(%ebp)
	movl	RPX_LASTVERT(%ebp),%eax
	leal	(%eax,%eax,2),%eax
	leal	(%esi,%eax,4),%edi
	movl	%edi,RPX_LAST_VERTEX(%ebp)
	// lastdist = dot(last.position, plane.normal) - plane.dist.
	flds	(%edi)
	fmuls	(%edx)
	flds	4(%edi)
	fmuls	4(%edx)
	faddp	%st(0),%st(1)
	fsubs	RPX_CLIP_DIST(%edx)
	flds	8(%edi)
	fmuls	8(%edx)
	faddp	%st(0),%st(1)
	fstpt	RPX_LASTDIST(%ebp)

	movl	RPX_CURRPAGE(%ebp),%eax
	xorl	$1,%eax
	movl	%eax,RPX_NEWPAGE(%ebp)
	imull	$RPX_VERTEX_PAGE_SIZE,%eax,%eax
	leal	RPX_VERTS(%ebp,%eax),%eax
	movl	%eax,RPX_DST(%ebp)
	movl	RPX_VERTBASE(%ebp),%eax
	movl	%eax,RPX_SRC(%ebp)
	movl	$0,RPX_NEWVERTS(%ebp)
	movl	$0,RPX_VISIBLE(%ebp)
	movl	$0,RPX_I(%ebp)
.Lrpx_clip_vertex:
	movl	RPX_I(%ebp),%eax
	cmpl	RPX_LNUMVERTS(%ebp),%eax
	jge	.Lrpx_clip_plane_done
	movl	RPX_SRC(%ebp),%esi
	movl	RPX_PCLIP(%ebp),%edx
	// dist = dot(current.position, plane.normal) - plane.dist.
	flds	(%esi)
	fmuls	(%edx)
	flds	4(%esi)
	fmuls	4(%edx)
	faddp	%st(0),%st(1)
	fsubs	RPX_CLIP_DIST(%edx)
	flds	8(%esi)
	fmuls	8(%edx)
	faddp	%st(0),%st(1)
	fstpt	RPX_DIST(%ebp)

	// A crossing occurs when the strict-positive side changes.
	fldt	RPX_LASTDIST(%ebp)
	ftst
	fnstsw	%ax
	sahf
	fstp	%st(0)
	seta	%al
	movzbl	%al,%eax
	movl	%eax,RPX_LAST_POSITIVE(%ebp)
	fldt	RPX_DIST(%ebp)
	ftst
	fnstsw	%ax
	sahf
	fstp	%st(0)
	seta	%al
	movzbl	%al,%eax
	movl	%eax,RPX_DIST_POSITIVE(%ebp)
	movl	RPX_LAST_POSITIVE(%ebp),%eax
	cmpl	RPX_DIST_POSITIVE(%ebp),%eax
	je	.Lrpx_test_inside

	// frac = dist / (dist - lastdist), using Quake's fsubr/fdivrp ordering.
	fldt	RPX_DIST(%ebp)
	fldt	RPX_LASTDIST(%ebp)
	fsubr	%st(1),%st(0)
	fdivrp	%st(0),%st(1)
	fstpt	RPX_FRAC(%ebp)
	movl	RPX_LAST_VERTEX(%ebp),%eax
	movl	RPX_DST(%ebp),%edi
	// New intersection position: current + (previous - current) * frac.
	cmpl	$100,RPX_NEWVERTS(%ebp)
	jae	.Lrpx_return
	flds	(%eax)
	fsubs	(%esi)
	fldt	RPX_FRAC(%ebp)
	fmulp	%st(0),%st(1)
	fadds	(%esi)
	fstps	(%edi)
	flds	4(%eax)
	fsubs	4(%esi)
	fldt	RPX_FRAC(%ebp)
	fmulp	%st(0),%st(1)
	fadds	4(%esi)
	fstps	4(%edi)
	flds	8(%eax)
	fsubs	8(%esi)
	fldt	RPX_FRAC(%ebp)
	fmulp	%st(0),%st(1)
	fadds	8(%esi)
	fstps	8(%edi)
	addl	$RPX_MVERTEX_SIZE,RPX_DST(%ebp)
	incl	RPX_NEWVERTS(%ebp)

.Lrpx_test_inside:
	fldt	RPX_DIST(%ebp)
	ftst
	fnstsw	%ax
	sahf
	fstp	%st(0)
	jae	.Lrpx_keep_vertex
	jmp	.Lrpx_clip_advance
.Lrpx_keep_vertex:
	cmpl	$100,RPX_NEWVERTS(%ebp)
	jae	.Lrpx_return
	movl	RPX_SRC(%ebp),%esi
	movl	RPX_DST(%ebp),%edi
	movl	(%esi),%eax
	movl	%eax,(%edi)
	movl	4(%esi),%eax
	movl	%eax,4(%edi)
	movl	8(%esi),%eax
	movl	%eax,8(%edi)
	addl	$RPX_MVERTEX_SIZE,RPX_DST(%ebp)
	incl	RPX_NEWVERTS(%ebp)
	movl	$1,RPX_VISIBLE(%ebp)

.Lrpx_clip_advance:
	movl	RPX_SRC(%ebp),%eax
	movl	%eax,RPX_LAST_VERTEX(%ebp)
	addl	$RPX_MVERTEX_SIZE,RPX_SRC(%ebp)
	fldt	RPX_DIST(%ebp)
	fstpt	RPX_LASTDIST(%ebp)
	incl	RPX_I(%ebp)
	jmp	.Lrpx_clip_vertex

.Lrpx_clip_plane_done:
	cmpl	$0,RPX_VISIBLE(%ebp)
	je	.Lrpx_return
	cmpl	$3,RPX_NEWVERTS(%ebp)
	jl	.Lrpx_return
	movl	RPX_NEWVERTS(%ebp),%eax
	movl	%eax,RPX_LNUMVERTS(%ebp)
	movl	RPX_NEWPAGE(%ebp),%eax
	movl	%eax,RPX_CURRPAGE(%ebp)
	movl	RPX_PCLIP(%ebp),%eax
	movl	RPX_CLIP_NEXT(%eax),%eax
	movl	%eax,RPX_PCLIP(%ebp)
	jmp	.Lrpx_clip_loop
.Lrpx_clipping_done:
	// Resolve the face plane's texture axes; unknown types retain C's 0,0 pair.
	movl	8(%ebp),%eax
	movl	RPX_SURFACE_PLANE(%eax),%edx
	movl	%edx,RPX_PPLANE(%ebp)
	movzbl	16(%edx),%ecx
	movl	$0,RPX_SAXIS(%ebp)
	movl	$0,RPX_TAXIS(%ebp)
	cmpl	$0,%ecx
	je	.Lrpx_axis_x
	cmpl	$3,%ecx
	je	.Lrpx_axis_x
	cmpl	$1,%ecx
	je	.Lrpx_axis_y
	cmpl	$4,%ecx
	je	.Lrpx_axis_y
	cmpl	$2,%ecx
	je	.Lrpx_axis_z
	cmpl	$5,%ecx
	jne	.Lrpx_axes_done
.Lrpx_axis_z:
	movl	$1,RPX_TAXIS(%ebp)
	jmp	.Lrpx_axes_done
.Lrpx_axis_y:
	movl	$2,RPX_TAXIS(%ebp)
	jmp	.Lrpx_axes_done
.Lrpx_axis_x:
	movl	$1,RPX_SAXIS(%ebp)
	movl	$2,RPX_TAXIS(%ebp)
.Lrpx_axes_done:
	movl	$0,C(r_nearzi)
	movl	RPX_CURRPAGE(%ebp),%eax
	imull	$RPX_VERTEX_PAGE_SIZE,%eax,%eax
	leal	RPX_VERTS(%ebp,%eax),%eax
	movl	%eax,RPX_SRC(%ebp)
	leal	RPX_PVERTS(%ebp),%eax
	movl	%eax,RPX_PVERT_PTR(%ebp)
	movl	$0,RPX_I(%ebp)
.Lrpx_project_vertex:
	movl	RPX_I(%ebp),%eax
	cmpl	RPX_LNUMVERTS(%ebp),%eax
	jge	.Lrpx_project_done
	movl	RPX_SRC(%ebp),%esi
	flds	(%esi)
	fsubs	C(modelorg)
	fstps	RPX_LOCAL(%ebp)
	flds	4(%esi)
	fsubs	C(modelorg)+4
	fstps	RPX_LOCAL+4(%ebp)
	flds	8(%esi)
	fsubs	C(modelorg)+8
	fstps	RPX_LOCAL+8(%ebp)
	leal	RPX_TRANSFORMED(%ebp),%eax
	pushl	%eax
	leal	RPX_LOCAL(%ebp),%eax
	pushl	%eax
	call	C(TransformVector)
	addl	$8,%esp

	// C compares transformed z with the double literal and stores float 0.01.
	flds	RPX_TRANSFORMED+8(%ebp)
	fcompl	.Lrpx_near_clip_double
	fnstsw	%ax
	testb	$1,%ah
	je	.Lrpx_near_clip_not_applied
	movl	.Lrpx_near_clip_float,%eax
	movl	%eax,RPX_TRANSFORMED+8(%ebp)
	// GCC folds the clamped 1.0 / 0.01f path to the exact float 100.0f.
	flds	.Lrpx_near_clip_reciprocal
	fstpt	RPX_LZI(%ebp)
	jmp	.Lrpx_lzi_ready
.Lrpx_near_clip_not_applied:
	// Match GCC's C-reference reverse divide: float 1.0 / transformed z.
	flds	RPX_TRANSFORMED+8(%ebp)
	fdivrs	.Lrpx_reciprocal_numerator
	fstpt	RPX_LZI(%ebp)
.Lrpx_lzi_ready:
	fldt	RPX_LZI(%ebp)
	fcoms	C(r_nearzi)
	fnstsw	%ax
	sahf
	fstp	%st(0)
	jbe	.Lrpx_nearzi_done
	fldt	RPX_LZI(%ebp)
	fstps	C(r_nearzi)
.Lrpx_nearzi_done:

	movl	RPX_PVERT_PTR(%ebp),%edi
	// u = xcenter + xscale * lzi * transformed.x, clamped to the adjusted rect.
	fldt	RPX_LZI(%ebp)
	flds	C(xscale)
	fmuls	RPX_TRANSFORMED(%ebp)
	fmulp	%st(0),%st(1)
	fadds	C(xcenter)
	fld		%st(0)
	fcomps	C(r_refdef)+68
	fnstsw	%ax
	sahf
	jb	.Lrpx_u_low
	fld		%st(0)
	fcomps	C(r_refdef)+84
	fnstsw	%ax
	sahf
	ja	.Lrpx_u_high
	jmp	.Lrpx_u_store
.Lrpx_u_low:
	fstp	%st(0)
	flds	C(r_refdef)+68
	jmp	.Lrpx_u_store
.Lrpx_u_high:
	fstp	%st(0)
	flds	C(r_refdef)+84
.Lrpx_u_store:
	fstps	(%edi)

	// v = ycenter - yscale * lzi * transformed.y, clamped to the adjusted rect.
	fldt	RPX_LZI(%ebp)
	flds	C(yscale)
	fmuls	RPX_TRANSFORMED+4(%ebp)
	fmulp	%st(0),%st(1)
	fsubrs	C(ycenter)
	fld		%st(0)
	fcomps	C(r_refdef)+72
	fnstsw	%ax
	sahf
	jb	.Lrpx_v_low
	fld		%st(0)
	fcomps	C(r_refdef)+88
	fnstsw	%ax
	sahf
	ja	.Lrpx_v_high
	jmp	.Lrpx_v_store
.Lrpx_v_low:
	fstp	%st(0)
	flds	C(r_refdef)+72
	jmp	.Lrpx_v_store
.Lrpx_v_high:
	fstp	%st(0)
	flds	C(r_refdef)+88
.Lrpx_v_store:
	fstps	4(%edi)
	fldt	RPX_LZI(%ebp)
	fstps	8(%edi)
	movl	RPX_SAXIS(%ebp),%eax
	movl	(%esi,%eax,4),%edx
	movl	%edx,12(%edi)
	movl	RPX_TAXIS(%ebp),%eax
	movl	(%esi,%eax,4),%edx
	movl	%edx,16(%edi)
	addl	$RPX_MVERTEX_SIZE,RPX_SRC(%ebp)
	addl	$RPX_POLYVERT_SIZE,RPX_PVERT_PTR(%ebp)
	incl	RPX_I(%ebp)
	jmp	.Lrpx_project_vertex
.Lrpx_project_done:
	movl	RPX_LNUMVERTS(%ebp),%eax
	movl	%eax,C(r_polydesc)
	movl	C(r_nearzi),%eax
	movl	%eax,C(r_polydesc)+4
	movl	8(%ebp),%eax
	movl	%eax,C(r_polydesc)+8
	leal	RPX_PVERTS(%ebp),%eax
	movl	%eax,C(r_polydesc)+12
	call	C(D_DrawPoly)

.Lrpx_return:
	leal	-(RPX_STACK_BYTES+12)(%ebp),%esp
	popl	%edi
	popl	%esi
	popl	%ebx
	movl	%ebp,%esp
	popl	%ebp
	ret
#endif

#ifdef ASM486_EFRAG_STORE
	.extern C(Sys_Error)
	.extern C(cl_numvisedicts)
	.extern C(cl_visedicts)
	.extern C(r_framecount)

	.equ EF_LEAFNEXT, 4
	.equ EF_ENTITY, 8
	.equ ENTITY_MODEL, 132
	.equ ENTITY_VISFRAME, 160
	.equ MODEL_TYPE, 68
	.equ MAX_VISEDICTS, 256

	.section .rodata
.Lefrag_store_bad_type:
	.asciz "R_StoreEfrags: Bad entity type %d\n"

	.text
	.globl C(R_StoreEfrags_asm486)
C(R_StoreEfrags_asm486):
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	movl	8(%ebp),%esi			/* efrag_t **ppefrag */

.Lefrag_store_loop:
	movl	(%esi),%ebx			/* pefrag = *ppefrag */
	testl	%ebx,%ebx
	je	.Lefrag_store_done
	movl	EF_ENTITY(%ebx),%edi		/* pent = pefrag->entity */
	movl	ENTITY_MODEL(%edi),%eax	/* clmodel = pent->model */
	movl	MODEL_TYPE(%eax),%edx
	cmpl	$2,%edx				/* mod_brush, mod_sprite, mod_alias */
	ja	.Lefrag_store_bad

	movl	ENTITY_VISFRAME(%edi),%eax
	cmpl	C(r_framecount),%eax
	je	.Lefrag_store_next
	movl	C(cl_numvisedicts),%eax
	cmpl	$MAX_VISEDICTS,%eax
	jge	.Lefrag_store_next
	movl	%edi,C(cl_visedicts)(,%eax,4)
	incl	C(cl_numvisedicts)
	movl	C(r_framecount),%eax
	movl	%eax,ENTITY_VISFRAME(%edi)

.Lefrag_store_next:
	leal	EF_LEAFNEXT(%ebx),%esi		/* ppefrag = &pefrag->leafnext */
	jmp	.Lefrag_store_loop

.Lefrag_store_bad:
	pushl	%edx
	pushl	$.Lefrag_store_bad_type
	call	C(Sys_Error)
	addl	$8,%esp
	/* Sys_Error does not return. Preserve the C reference's bad-list behavior
	 * if a test stub does return: retry the same invalid efrag. */
	jmp	.Lefrag_store_loop

.Lefrag_store_done:
	leal	-12(%ebp),%esp
	popl	%edi
	popl	%esi
	popl	%ebx
	popl	%ebp
	ret
#endif

#ifdef ASM486_SURFACE_DISPATCH
	.extern C(surfaces)
	.extern C(surface_p)
	.extern C(cl_entities)
	.extern C(currententity)
	.extern C(modelorg)
	.extern C(transformed_modelorg)
	.extern C(base_modelorg)
	.extern C(base_vpn)
	.extern C(base_vup)
	.extern C(base_vright)
	.extern C(vpn)
	.extern C(vup)
	.extern C(vright)
	.extern C(r_origin)
	.extern C(r_drawflat)
	.extern C(r_clearcolor)
	.extern C(r_skymade)
	.extern C(r_drawnpolycount)
	.extern C(scale_for_mip)
	.extern C(xscaleinv)
	.extern C(yscaleinv)
	.extern C(d_mipscale_values)
	.extern C(d_mip_xscale)
	.extern C(d_mip_yscale)
	.extern C(d_gradient_miplevel)
	.extern C(d_zistepu)
	.extern C(d_zistepv)
	.extern C(d_ziorigin)
	.extern C(cachewidth)
	.extern C(cacheblock)
	.extern C(d_drawspans)
	.extern C(D_DrawSurfacesProfileBegin_asm486)
	.extern C(D_DrawSurfacesProfileFinish_asm486)
	.extern C(D_DrawSurfacesProfileRecordSurface_asm486)
	.extern C(D_DrawSurfacesProfileEnter_asm486)
	.extern C(D_DrawSurfacesProfileLeave_asm486)
	.extern C(D_DrawSurfacesProfileWork_asm486)
	.extern C(D_DrawSurfacesProfileTimedStart_asm486)
	.extern C(D_DrawSurfacesProfileTimedFinish_asm486)
	.extern C(D_DrawSurfacesProfileTextureStart_asm486)
	.extern C(D_DrawSurfacesProfileTextureFinish_asm486)
	.extern C(D_DrawSurfacesProfileTextureWidth_asm486)
	.extern C(D_DrawSolidSurface)
	.extern C(D_DrawZSpans)
	.extern C(D_DrawSkyScans8)
	.extern C(D_DrawSurfacesCalcGradients_asm486)
	.extern C(Turbulent8)
	.extern C(D_MipLevelForScale)
	.extern C(D_CacheSurface)
	.extern C(R_MakeSky)
	.extern C(TransformVector)
	.extern C(R_RotateBmodelCached)
	.extern C(R_TransformFrustum)
	.section .rodata
	.p2align 2
.Lds_background_z:
	.float -0.9
	.text
#endif

#ifdef ASM486_BSP_WALK
	.extern C(cl)
	.extern C(r_visframecount)
	.extern C(r_framecount)
	.extern C(r_currentkey)
	.extern C(r_drawpolys)
	.extern C(r_worldpolysbacktofront)
	.extern C(numbtofpolys)
	.extern C(pbtofpolys)
	.extern C(R_RecursiveWorldNodePlaneDot_asm486)
	.extern C(R_RecursiveWorldNodeClip_asm486)
	.extern C(R_StoreEfrags)
	.extern C(R_RenderFace)
	.extern C(R_RenderPoly)
#ifdef PROFILE486
	.extern C(bench486_profile_frame_active)
	.extern C(bench486_bsp_nodes)
	.extern C(bench486_bsp_solid_culls)
	.extern C(bench486_bsp_visibility_culls)
	.extern C(bench486_bsp_leaf_nodes)
	.extern C(bench486_bsp_internal_nodes)
	.extern C(bench486_bsp_surface_tests)
	.extern C(R_BspProfileRenderFaceEnter_asm486)
	.extern C(R_BspProfileRenderFaceLeave_asm486)
#endif
	.section .rodata
	.p2align 3
.Lbsp_walk_negative_backface_epsilon:
	.double -0.01
.Lbsp_walk_positive_backface_epsilon:
	.double 0.01
	.text
#endif

#ifdef ASM486_SURFACE_CACHE_CHECK
	.extern C(sc_base)
	.extern C(sc_rover)
	.extern C(sc_size)
	.extern C(msg_suppress_1)
	.extern C(Con_Printf)
	.extern C(com_argv)
	.extern C(COM_CheckParm)
	.extern C(Q_atoi)
	.extern C(d_roverwrapped)
	.extern C(d_initial_rover)
	.extern C(r_cache_thrash)
	.extern C(D_CheckCacheGuard)
	.extern C(Sys_Error)
	.extern C(c_surf)
	.extern C(R_DrawSurface)
	.extern C(currententity)
	.extern C(r_drawsurf)
	.extern C(d_lightstylevalue)
	.extern C(r_framecount)
	.extern C(r_dlight_contributed)
	.extern C(R_TextureAnimation)
#ifdef PROFILE486
	.extern C(bench486_profile_frame_active)
	.extern C(bench486_surface_cache_allocations)
	.extern C(bench486_surface_cache_requested_bytes)
	.extern C(bench486_surface_cache_wraps)
	.extern C(bench486_surface_cache_invalidated_blocks)
	.extern C(bench486_surface_cache_reclaimed_bytes)
	.extern C(bench486_surface_cache_thrash_frames)
	.extern C(D_CacheSurfaceProfileBegin_asm486)
	.extern C(D_CacheSurfaceProfileHit_asm486)
	.extern C(D_CacheSurfaceProfileMiss_asm486)
	.extern C(D_CacheSurfaceProfileAllocBegin_asm486)
	.extern C(D_CacheSurfaceProfileAllocEnd_asm486)
	.extern C(D_CacheSurfaceProfileDrawBegin_asm486)
	.extern C(D_CacheSurfaceProfileDrawEnd_asm486)
	.extern C(D_CacheSurfaceProfileFinish_asm486)
#endif
#endif
#ifdef ASM486_TEXTURE_ANIMATION
	.extern C(cl)
	.extern C(currententity)
#endif
#ifdef ASM486_SURFACE_DRAW
	.extern C(r_drawsurf)
	.extern C(blocklights)
	.extern C(R_BuildLightMap)
	.extern C(R_DrawSurfaceBlock8_mip0)
	.extern C(R_DrawSurfaceBlock8_mip1)
	.extern C(R_DrawSurfaceBlock8_mip2)
	.extern C(R_DrawSurfaceBlock8_mip3)
	.extern C(surfrowbytes)
	.extern C(blocksize)
	.extern C(sourcetstep)
	.extern C(blockdivshift)
	.extern C(blockdivmask)
	.extern C(prowdestbase)
	.extern C(pbasesource)
	.extern C(r_lightptr)
	.extern C(r_stepback)
	.extern C(r_lightwidth)
	.extern C(r_numhblocks)
	.extern C(r_numvblocks)
	.extern C(r_source)
	.extern C(r_sourcemax)
#ifdef PROFILE486
	.extern C(R_DrawSurfaceProfileBegin_asm486_C)
	.extern C(R_DrawSurfaceProfileAfterLightmap_asm486_C)
	.extern C(R_DrawSurfaceProfileCountBlocks_asm486_C)
	.extern C(R_DrawSurfaceProfileStartBlocks_asm486_C)
	.extern C(R_DrawSurfaceProfileFinish_asm486_C)
#endif
#endif

#ifdef ASM486_SURFACE_ZGRADIENTS
	.extern C(r_zgradient_asm_cache_frame)
	.extern C(r_zgradient_asm_cache_plane)
	.extern C(r_zgradient_asm_cache_entity)
	.extern C(r_zgradient_asm_cache_zistepu)
	.extern C(r_zgradient_asm_cache_zistepv)
	.extern C(r_zgradient_asm_cache_ziorigin)
	.extern C(r_framecount)
	.extern C(currententity)
	.extern C(surface_p)
	.extern C(modelorg)
	.extern C(xscaleinv)
	.extern C(yscaleinv)
	.extern C(xcenter)
	.extern C(ycenter)
	.extern C(TransformVector)
#endif

#ifdef DEBUG
#define SURFCACHE_HEIGHT_OFFSET 36
#define SURFCACHE_TEXTURE_OFFSET 44
#define SURFCACHE_DATA_OFFSET 48
#else
#define SURFCACHE_HEIGHT_OFFSET 0
#define SURFCACHE_TEXTURE_OFFSET 40
#define SURFCACHE_DATA_OFFSET 44
#endif

#if defined(ASM486_FILLRECT) || defined(ASM486_WARP_SCREEN) || defined(ASM486_SKY_SPAN)
	.extern C(vid)
#endif
#ifdef ASM486_ZPOINT
	.extern C(r_zpointdesc)
	.extern C(zspantable)
	.extern C(d_viewbuffer)
	.extern C(d_scantable)
#endif
#ifdef ASM486_SOLID_SURFACE
	.extern C(viewspantable)
#ifdef PROFILE486
	.extern C(bench486_profile_frame_active)
	.extern C(bench486_solid_span_count)
#endif
#endif
#ifdef ASM486_LIGHTMAP_BUILD
	.extern C(cl)
	.extern C(r_drawsurf)
	.extern C(r_fullbright)
	.extern C(r_refdef)
	.extern C(r_framecount)
	.extern C(r_dlight_contributed)
	.extern C(blocklights)
	.extern C(lightmap_single_table)
	.extern C(lightmap_single_first)
	.extern C(lightmap_single_inverse_scale)
	.extern C(lightmap_single_table_valid)
	.extern C(R_AddDynamicLights)
#ifdef PROFILE486
	.extern C(bench486_lm_single_texels)
	.extern C(bench486_lm_fused_texels)
	.extern C(bench486_lm_fused_maps)
#endif
#endif
#ifdef ASM486_DYNAMIC_LIGHT_PROJECTION
	.extern C(cl_dlights)
#endif
#ifdef ASM486_DYNAMIC_LIGHT_ORCHESTRATION
#ifndef ASM486_LIGHTMAP_BUILD
	.extern C(r_drawsurf)
#endif
	.extern C(blocklights)
	.extern C(r_dlight_contributed)
	.extern C(R_AddDynamicLightSamples_C)
#ifdef ASM486_DYNAMIC_LIGHTS
	.extern C(R_AddDynamicLightSamples_asm486)
#endif
#endif
#ifdef ASM486_TURBULENT_SCAN
	.extern C(cl)
	.extern C(sintable)
	.extern C(cacheblock)
	.extern C(viewspantable)
	.extern C(d_sdivzstepu)
	.extern C(d_tdivzstepu)
	.extern C(d_zistepu)
	.extern C(d_sdivzstepv)
	.extern C(d_tdivzstepv)
	.extern C(d_zistepv)
	.extern C(d_sdivzorigin)
	.extern C(d_tdivzorigin)
	.extern C(d_ziorigin)
	.extern C(sadjust)
	.extern C(tadjust)
	.extern C(bbextents)
	.extern C(bbextentt)
	.extern C(r_turb_pbase)
	.extern C(r_turb_pdest)
	.extern C(r_turb_s)
	.extern C(r_turb_t)
	.extern C(r_turb_sstep)
	.extern C(r_turb_tstep)
	.extern C(r_turb_turb)
	.extern C(r_turb_spancount)
#ifdef PROFILE486
	.extern C(bench486_profile_frame_active)
	.extern C(bench486_turbulent_rows)
	.extern C(bench486_turbulent_chunks)
	.extern C(bench486_turbulent_pixels)
	.extern C(bench486_turbulent_seconds)
	.extern C(Sys_FloatTime)
#endif
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

Ltexture_animation_broken:
	.ascii	"R_TextureAnimation: broken cycle\0"
Ltexture_animation_infinite:
	.ascii	"R_TextureAnimation: infinite cycle\0"
#ifdef ASM486_TEXTURE_ANIMATION
	.p2align 3
Ltexture_animation_ten:
	.double	10.0
#endif
#ifdef ASM486_DYNAMIC_LIGHT_PROJECTION
	.p2align 2
.Ldlight_project_256:
	.float	256.0
#endif
	.p2align 4,,15
Lalias_transform_coords:
	.long	0, 0, 0
Lalias_transform_temp:
	.long	0
#ifdef ASM486_ZPOINT
Lzpoint_scale:
	.float	32768.0
#endif
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
#ifdef ASM486_TURBULENT_SCAN
	.p2align 2
Lturbulent_speed:
	.float	20.0
Lturbulent_65536:
	.float	65536.0
Lturbulent_16:
	.float	16.0
#endif

#ifdef TARGET_I386
	.p2align 4,,15
// i386 replacements for the i486 register-form BT and BTR in
// R_RecursiveWorldNodeClip_asm486.
//
// BT r/m32,r32 and BTR r/m32,r32 do not exist on a 386; only the immediate form
// (0F BA) does.  The bit index there is the frustum plane loop counter, which
// runs 0..3 and exits at 4, so a four-entry mask table expresses both
// operations exactly -- and, unlike a ROLL through CL, it needs no scratch
// register, which matters because all six registers are live in that loop.
// Emitted only for the i386 build so the i486 object keeps its current .data.
Lplane_bit_masks:
	.long	1, 2, 4, 8
#endif

	.text
	.p2align 4,,15

// void Q_memset_asm486(void *dest, int fill, int count)
C(Q_memset_asm486):
	.globl C(Q_memset_asm486)
	pushl	%edi
	movl	8(%esp),%edi		// dest
	movl	12(%esp),%eax		// fill
	movl	16(%esp),%ecx		// count
	testl	%ecx,%ecx
	jle	.Lmemset_done

	andl	$0xff,%eax

// Align the destination with byte stores.  The remaining count is kept in
// ECX until the dword count and tail count are split below.
.Lmemset_align:
	testl	$3,%edi
	jz	.Lmemset_aligned
	movb	%al,(%edi)
	incl	%edi
	decl	%ecx
	jnz	.Lmemset_align
	jmp	.Lmemset_done

.Lmemset_aligned:
// Expand the byte into a repeated dword pattern without newer instructions.
	movl	%eax,%edx
	shll	$8,%edx
	orl	%edx,%eax
	movl	%eax,%edx
	shll	$16,%edx
	orl	%edx,%eax

	movl	%ecx,%edx			// preserve the byte tail count
	shrl	$2,%ecx
	jz	.Lmemset_tail
	cld
	rep
	stosl

.Lmemset_tail:
	andl	$3,%edx
	jz	.Lmemset_done
	movl	%edx,%ecx
	cld
	rep
	stosb

.Lmemset_done:
	popl	%edi
	ret

	.p2align 4,,15

// void Q_memcpy_asm486(void *dest, void *src, int count)
// Matches the existing Q_memcpy contract: forward copy, no overlap handling.
C(Q_memcpy_asm486):
	.globl C(Q_memcpy_asm486)
	pushl	%edi
	pushl	%esi
	movl	12(%esp),%edi		// dest
	movl	16(%esp),%esi		// src
	movl	20(%esp),%ecx		// count
	testl	%ecx,%ecx
	jle	.Lmemcpy_done

// A dword loop is safe only when both pointers have the same alignment.
	movl	%edi,%eax
xorl	%esi,%eax
	testl	$3,%eax
jnz	.Lmemcpy_bytes

.Lmemcpy_align:
	testl	$3,%edi
	jz	.Lmemcpy_aligned
	movb	(%esi),%al
	movb	%al,(%edi)
	incl	%esi
	incl	%edi
	decl	%ecx
	jnz	.Lmemcpy_align
	jmp	.Lmemcpy_done

.Lmemcpy_aligned:
	movl	%ecx,%edx			// preserve the byte tail count
	shrl	$2,%ecx
	jz	.Lmemcpy_tail
	cld
	rep
	movsl

.Lmemcpy_tail:
	andl	$3,%edx
	jz	.Lmemcpy_done
	movl	%edx,%ecx
	cld
	rep
	movsb
	jmp	.Lmemcpy_done

.Lmemcpy_bytes:
	cld
	rep
	movsb

.Lmemcpy_done:
	popl	%esi
	popl	%edi
	ret

	.p2align 4,,15

// void *D_GetTextureAxesHit_asm486(void *entry, void *texinfo,
//     void *entity, int frame)
// Probe the three-key texture-axis cache record without touching the cached
// axis vectors.  The caller performs the hash/index calculation and handles
// the miss path in C.
C(D_GetTextureAxesHit_asm486):
	.globl C(D_GetTextureAxesHit_asm486)
	movl	4(%esp),%eax		// entry
	testl	%eax,%eax
	jz	.Ltexaxis_miss
	movl	8(%esp),%edx		// texinfo
	cmpl	(%eax),%edx
	jne	.Ltexaxis_miss
	movl	12(%esp),%edx		// entity
	cmpl	4(%eax),%edx
	jne	.Ltexaxis_miss
	movl	16(%esp),%edx		// frame
	cmpl	8(%eax),%edx
	jne	.Ltexaxis_miss
	ret

.Ltexaxis_miss:
	xorl	%eax,%eax
	ret

#ifdef ASM486_SURFACE_GRADIENTS
	.p2align 4,,15

// void D_CalcGradients_asm486(msurface_t *pface)
// Calculate the perspective texture gradients and maintain an independent
// 256-entry view-axis cache.  The x87 operation order follows D_CalcGradients.
C(D_CalcGradients_asm486):
	.globl C(D_CalcGradients_asm486)
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	subl	$48,%esp
	movl	8(%ebp),%esi		// pface
#ifdef PROFILE486
	pushl	%esi
	call	C(D_CalcGradientsProfileBegin_asm486)
	addl	$4,%esp
#endif

	movl	52(%esi),%edi		// pface->texinfo
	movl	C(currententity),%edx
	movl	%edi,%eax
	shrl	$4,%eax
	movl	%edx,%ecx
	shrl	$4,%ecx
	xorl	%ecx,%eax
	andl	C(d_texaxis_cache_mask),%eax
	leal	(%eax,%eax,8),%eax
	shll	$2,%eax			// 36-byte cache entries
	leal	C(d_texaxis_cache_asm)(%eax),%ebx
	movl	C(r_framecount),%ecx
	cmpl	%edi,(%ebx)
	jne	.Lgradient_cache_miss
	cmpl	%edx,4(%ebx)
	jne	.Lgradient_cache_miss
	cmpl	%ecx,8(%ebx)
	jne	.Lgradient_cache_miss
#ifdef PROFILE486
	call	C(D_CalcGradientsProfileAxisHit_asm486)
#endif
	jmp	.Lgradient_cache_ready

.Lgradient_cache_miss:
	leal	12(%ebx),%eax		// entry->saxis
	pushl	%eax
	pushl	%edi			// texinfo->vecs[0]
	call	C(TransformVector)
	addl	$8,%esp
	leal	24(%ebx),%eax		// entry->taxis
	leal	16(%edi),%edx		// texinfo->vecs[1]
	pushl	%eax
	pushl	%edx
	call	C(TransformVector)
	addl	$8,%esp
	movl	%edi,(%ebx)
	movl	C(currententity),%eax
	movl	%eax,4(%ebx)
	movl	C(r_framecount),%eax
	movl	%eax,8(%ebx)
#ifdef PROFILE486
	call	C(D_CalcGradientsProfileAxisMiss_asm486)
#endif

.Lgradient_cache_ready:
	movl	C(d_gradient_miplevel),%ecx

	// u/v derivatives.  The negative v term matches the source's unary minus
	// before multiplication and each destination is rounded to float here.
	flds	12(%ebx)
	fmuls	C(d_mip_xscale)(,%ecx,4)
	fstps	C(d_sdivzstepu)
	flds	24(%ebx)
	fmuls	C(d_mip_xscale)(,%ecx,4)
	fstps	C(d_tdivzstepu)
	flds	16(%ebx)
	fchs
	fmuls	C(d_mip_yscale)(,%ecx,4)
	fstps	C(d_sdivzstepv)
	flds	28(%ebx)
	fchs
	fmuls	C(d_mip_yscale)(,%ecx,4)
	fstps	C(d_tdivzstepv)

	// axis[2]*mipscale - xcenter*stepu - ycenter*stepv
	flds	20(%ebx)
	fmuls	C(d_mipscale_values)(,%ecx,4)
	flds	C(xcenter)
	fmuls	C(d_sdivzstepu)
	fsubrp	%st(0),%st(1)
	flds	C(ycenter)
	fmuls	C(d_sdivzstepv)
	fsubrp	%st(0),%st(1)
	fstps	C(d_sdivzorigin)
	flds	32(%ebx)
	fmuls	C(d_mipscale_values)(,%ecx,4)
	flds	C(xcenter)
	fmuls	C(d_tdivzstepu)
	fsubrp	%st(0),%st(1)
	flds	C(ycenter)
	fmuls	C(d_tdivzstepv)
	fsubrp	%st(0),%st(1)
	fstps	C(d_tdivzorigin)

	// VectorScale stores the three scaled model-origin components as floats;
	// retain those stores before the two dot products to match the C reference.
	flds	C(transformed_modelorg)
	fmuls	C(d_mipscale_values)(,%ecx,4)
	fstps	-24(%ebp)
	flds	C(transformed_modelorg)+4
	fmuls	C(d_mipscale_values)(,%ecx,4)
	fstps	-20(%ebp)
	flds	C(transformed_modelorg)+8
	fmuls	C(d_mipscale_values)(,%ecx,4)
	fstps	-16(%ebp)

	// sadjust's first fixed-point conversion is part of the source expression.
	flds	-24(%ebp)
	fmuls	12(%ebx)
	flds	-20(%ebp)
	fmuls	16(%ebx)
	faddp	%st(0),%st(1)
	flds	-16(%ebp)
	fmuls	20(%ebx)
	faddp	%st(0),%st(1)
	fmuls	.Ldgradient_fixed16
	fadds	.Ldgradient_half
	fnstcw	-42(%ebp)
	movw	-42(%ebp),%ax
	orb	$12,%ah			// C float-to-int casts truncate toward zero
	movw	%ax,-44(%ebp)
	fldcw	-44(%ebp)
	fistpl	-28(%ebp)
	fldcw	-42(%ebp)
	movswl	44(%esi),%eax		// texturemins[0] << 16 >> mip
	shll	$16,%eax
	sarl	%cl,%eax
	subl	%eax,-28(%ebp)
	flds	12(%edi)
	fmuls	C(d_mip_t16)(,%ecx,4)
	fiaddl	-28(%ebp)
	fldcw	-44(%ebp)
	fistpl	C(sadjust)
	fldcw	-42(%ebp)

	flds	-24(%ebp)
	fmuls	24(%ebx)
	flds	-20(%ebp)
	fmuls	28(%ebx)
	faddp	%st(0),%st(1)
	flds	-16(%ebp)
	fmuls	32(%ebx)
	faddp	%st(0),%st(1)
	fmuls	.Ldgradient_fixed16
	fadds	.Ldgradient_half
	fnstcw	-42(%ebp)
	movw	-42(%ebp),%ax
	orb	$12,%ah
	movw	%ax,-44(%ebp)
	fldcw	-44(%ebp)
	fistpl	-28(%ebp)
	fldcw	-42(%ebp)
	movswl	46(%esi),%eax		// texturemins[1] << 16 >> mip
	shll	$16,%eax
	sarl	%cl,%eax
	subl	%eax,-28(%ebp)
	flds	28(%edi)
	fmuls	C(d_mip_t16)(,%ecx,4)
	fiaddl	-28(%ebp)
	fldcw	-44(%ebp)
	fistpl	C(tadjust)
	fldcw	-42(%ebp)

	movswl	48(%esi),%eax		// extents[0] << 16 >> mip, minus epsilon
	shll	$16,%eax
	sarl	%cl,%eax
	subl	$1,%eax
	movl	%eax,C(bbextents)
	movswl	50(%esi),%eax		// extents[1] << 16 >> mip, minus epsilon
	shll	$16,%eax
	sarl	%cl,%eax
	subl	$1,%eax
	movl	%eax,C(bbextentt)

#ifdef PROFILE486
	call	C(D_CalcGradientsProfileEnd_asm486)
#endif
	leal	-12(%ebp),%esp
	popl	%edi
	popl	%esi
	popl	%ebx
	leave
	ret
#endif

	.p2align 4,,15

// void *D_CacheSurfaceHit_asm486(void *cache, int surface_dlightframe,
//     int frame, void *texture, int *lightadj, msurface_t *surface)
// Match the C cache hit predicate, including the unused-style sentinel and
// the discrete dynamic-light probe for phantom dlight marks.
C(D_CacheSurfaceHit_asm486):
	.globl C(D_CacheSurfaceHit_asm486)
	pushl	%ebx
	movl	8(%esp),%ebx		// cache
	testl	%ebx,%ebx
	jz	.Lsurface_cache_miss
	cmpl	$0,24(%ebx)		// cache->dlight
	jne	.Lsurface_cache_miss
	movl	20(%esp),%edx		// r_drawsurf.texture
	cmpl	SURFCACHE_TEXTURE_OFFSET(%ebx),%edx	// cache->texture
	jne	.Lsurface_cache_miss
	movl	24(%esp),%edx		// r_drawsurf.lightadj
	movl	(%edx),%ecx
	cmpl	8(%ebx),%ecx
	jne	.Lsurface_cache_miss
	movl	28(%esp),%edx		// surface
	cmpb	$255,57(%edx)		// styles[1] unused
	je	.Lsurface_cache_check_dlight
	movl	24(%esp),%edx		// r_drawsurf.lightadj
	movl	4(%edx),%ecx
	cmpl	12(%ebx),%ecx
	jne	.Lsurface_cache_miss
	movl	8(%edx),%ecx
	cmpl	16(%ebx),%ecx
	jne	.Lsurface_cache_miss
	movl	12(%edx),%ecx
	cmpl	20(%ebx),%ecx
	jne	.Lsurface_cache_miss

.Lsurface_cache_check_dlight:
	movl	12(%esp),%edx		// surface->dlightframe
	cmpl	16(%esp),%edx		// current frame
	jne	.Lsurface_cache_hit
	pushl	28(%esp)			// R_DlightContributes(surface)
	call	C(R_DlightContributes)
	addl	$4,%esp
	testl	%eax,%eax
	jne	.Lsurface_cache_miss
.Lsurface_cache_hit:
	movl	%ebx,%eax
	popl	%ebx
	ret

.Lsurface_cache_miss:
	xorl	%eax,%eax
	popl	%ebx
	ret

	.p2align 4,,15

#ifdef ASM486_SURFACE_CACHE_CHECK
// int D_SurfaceCacheForRes(int width, int height)
// Own resolution scaling and the default 320x200 cache baseline. Keep command
// line token lookup and atoi in their shared C helpers.
C(D_SurfaceCacheForRes):
	.globl C(D_SurfaceCacheForRes)
	pushl	%ebp
	movl	%esp,%ebp
	subl	$4,%esp
	pushl	$.Ldsc_surface_cache_size_argument
	call	C(COM_CheckParm)
	addl	$4,%esp
	testl	%eax,%eax
	jne	.Ldsc_surface_cache_override
	movl	8(%ebp),%eax		// width
	imull	12(%ebp),%eax		// width * height, low 32 bits
	cmpl	$64000,%eax
	jg	.Ldsc_surface_cache_scale
	movl	$2457600,%eax		// SURFCACHE_SIZE_AT_320X200
	jmp	.Ldsc_surface_cache_done
.Ldsc_surface_cache_scale:
	subl	$64000,%eax
	leal	(%eax,%eax,2),%eax	// (pixels - 64000) * 3
	addl	$2457600,%eax		// SURFCACHE_SIZE_AT_320X200
	jmp	.Ldsc_surface_cache_done
.Ldsc_surface_cache_override:
	movl	%eax,-4(%ebp)		// argument index
	movl	C(com_argv),%edx
	movl	-4(%ebp),%eax
	movl	4(%edx,%eax,4),%eax	// com_argv[index + 1]
	pushl	%eax
	call	C(Q_atoi)
	addl	$4,%esp
	shll	$10,%eax			// * 1024
.Ldsc_surface_cache_done:
	leave
	ret

	.section .rodata
.Ldsc_surface_cache_size_argument:
	.asciz	"-surfcachesize"
	.text

// void D_InitCaches(void *buffer, int size)
// Initialize the surface-cache sentinel and trailing guard bytes. Console
// formatting remains in Con_Printf; cache state and guard setup are owned here.
C(D_InitCaches):
	.globl C(D_InitCaches)
	cmpl	$0,C(msg_suppress_1)
	jne	.Ldinit_caches_state
	movl	8(%esp),%eax		// size
	cltd
	movl	$1024,%ecx
	idivl	%ecx
	pushl	%eax
	pushl	$.Ldinit_caches_message
	call	C(Con_Printf)
	addl	$8,%esp
.Ldinit_caches_state:
	movl	4(%esp),%eax		// buffer
	movl	8(%esp),%edx		// size
	subl	$4,%edx			// GUARDSIZE
	movl	%edx,C(sc_size)
	movl	%eax,C(sc_base)
	movl	%eax,C(sc_rover)
	movl	$0,0(%eax)			// sc_base->next
	movl	$0,4(%eax)			// sc_base->owner
	movl	%edx,28(%eax)		// sc_base->size
	leal	(%eax,%edx),%ecx		// cache guard starts at buffer + sc_size
	movb	$0,0(%ecx)
	movb	$1,1(%ecx)
	movb	$2,2(%ecx)
	movb	$3,3(%ecx)
	ret

	.section .rodata
.Ldinit_caches_message:
	.asciz	"%ik surface cache\n"
	.text

#if !defined(ASM486_DRAWING_DRIVER)
// In the complete drawing-driver profile, d_driverasm.s owns this entry.
C(D_FlushCaches):
	.globl C(D_FlushCaches)
	pushl	%esi
	pushl	%edi
	movl	C(sc_base),%esi
	testl	%esi,%esi
	je	.Ldflush_caches_return
.Ldflush_caches_owner:
	movl	4(%esi),%edi		// owner
	testl	%edi,%edi
	je	.Ldflush_caches_next
	movl	$0,(%edi)			// *owner = NULL
.Ldflush_caches_next:
	movl	0(%esi),%esi		// next
	testl	%esi,%esi
	jne	.Ldflush_caches_owner
	movl	C(sc_base),%eax
	movl	%eax,C(sc_rover)
	movl	$0,0(%eax)			// sc_base->next
	movl	$0,4(%eax)			// sc_base->owner
	movl	C(sc_size),%edx
	movl	%edx,28(%eax)		// sc_base->size
.Ldflush_caches_return:
	popl	%edi
	popl	%esi
	ret
#endif

// surfcache_t *D_SCAlloc_asm486(int width, int payload_size)
// Walk/reclaim the rover chain, split a sufficiently large tail block, and
// update wrap/thrash state. The C allocator remains the benchmark reference.
C(D_SCAlloc):
	.globl C(D_SCAlloc)
C(D_SCAlloc_asm486):
	.globl C(D_SCAlloc_asm486)
	pushl	%ebp
	pushl	%edi
	pushl	%esi
	pushl	%ebx
	subl	$16,%esp

	// Locals: 0=aligned block size, 4=width, 8=new block, 12=wrapped flag.
	movl	36(%esp),%ebx		// width
	testl	%ebx,%ebx
	js	.Ldsc_bad_width
	cmpl	$256,%ebx
	jg	.Ldsc_bad_width
	movl	%ebx,4(%esp)
	movl	40(%esp),%edx		// payload size
	testl	%edx,%edx
	jle	.Ldsc_bad_size
	cmpl	$0x10000,%edx
	jg	.Ldsc_bad_size

#ifdef PROFILE486
	cmpl	$0,C(bench486_profile_frame_active)
	je	.Ldsc_profile_request_done
	incl	C(bench486_surface_cache_allocations)
	movl	40(%esp),%eax
	addl	%eax,C(bench486_surface_cache_requested_bytes)
.Ldsc_profile_request_done:
#endif

	addl	$SURFCACHE_DATA_OFFSET,%edx
	addl	$3,%edx
	andl	$-4,%edx
	movl	%edx,0(%esp)
	cmpl	C(sc_size),%edx
	jle	.Ldsc_size_fits
	pushl	%edx
	pushl	$.Ldsc_too_large
	call	C(Sys_Error)
	addl	$8,%esp
	xorl	%eax,%eax
	jmp	.Ldsc_return

.Ldsc_size_fits:
	movl	$0,12(%esp)			// wrapped_this_time
	movl	C(sc_rover),%edi
	testl	%edi,%edi
	jz	.Ldsc_wrap
	movl	C(sc_size),%eax
	subl	0(%esp),%eax			// free bytes after sc_base
	movl	C(sc_base),%edx
	subl	%edx,%edi
	cmpl	%eax,%edi
	jle	.Ldsc_rover_ready

.Ldsc_wrap:
	cmpl	$0,C(sc_rover)
	je	.Ldsc_set_rover_base
	movl	$1,12(%esp)
#ifdef PROFILE486
	cmpl	$0,C(bench486_profile_frame_active)
	je	.Ldsc_set_rover_base
	incl	C(bench486_surface_cache_wraps)
#endif
.Ldsc_set_rover_base:
	movl	C(sc_base),%edi
	movl	%edi,C(sc_rover)

.Ldsc_rover_ready:
	movl	C(sc_rover),%edi		// restore pointer after extent comparison
	movl	%edi,8(%esp)			// new = sc_rover
	movl	4(%edi),%eax			// owner
	testl	%eax,%eax
	jz	.Ldsc_collect
	movl	$0,(%eax)				// *owner = NULL
#ifdef PROFILE486
	cmpl	$0,C(bench486_profile_frame_active)
	je	.Ldsc_collect
	incl	C(bench486_surface_cache_invalidated_blocks)
	movl	28(%edi),%eax
	addl	%eax,C(bench486_surface_cache_reclaimed_bytes)
#endif

.Ldsc_collect:
	movl	8(%esp),%esi			// new
	movl	28(%esi),%eax
	cmpl	0(%esp),%eax
	jge	.Ldsc_collect_done

.Ldsc_collect_next:
	movl	0(%edi),%edi			// sc_rover = sc_rover->next
	testl	%edi,%edi
	jnz	.Ldsc_have_next
	pushl	$.Ldsc_end_of_memory
	call	C(Sys_Error)
	addl	$4,%esp
	xorl	%eax,%eax
	jmp	.Ldsc_return

.Ldsc_have_next:
	movl	%edi,C(sc_rover)
	movl	4(%edi),%eax
	testl	%eax,%eax
	jz	.Ldsc_add_next
	movl	$0,(%eax)
#ifdef PROFILE486
	cmpl	$0,C(bench486_profile_frame_active)
	je	.Ldsc_add_next
	incl	C(bench486_surface_cache_invalidated_blocks)
	movl	28(%edi),%eax
	addl	%eax,C(bench486_surface_cache_reclaimed_bytes)
#endif

.Ldsc_add_next:
	movl	28(%esi),%eax
	addl	28(%edi),%eax
	movl	%eax,28(%esi)
	movl	0(%edi),%eax
	movl	%eax,0(%esi)
	movl	28(%esi),%eax
	cmpl	0(%esp),%eax
	jl	.Ldsc_collect_next

.Ldsc_collect_done:
	movl	28(%esi),%eax
	subl	0(%esp),%eax
	cmpl	$256,%eax
	jle	.Ldsc_keep_block

	// A remainder above 256 bytes becomes the new rover fragment.
	movl	%esi,%edi
	addl	0(%esp),%edi
	movl	%edi,C(sc_rover)
	movl	%eax,28(%edi)
	movl	0(%esi),%edx
	movl	%edx,0(%edi)
	movl	$0,32(%edi)			// width
	movl	$0,4(%edi)			// owner
	movl	%edi,0(%esi)
	movl	0(%esp),%eax
	movl	%eax,28(%esi)
	jmp	.Ldsc_block_ready

.Ldsc_keep_block:
	movl	0(%esi),%edi
	movl	%edi,C(sc_rover)

.Ldsc_block_ready:
	movl	4(%esp),%eax
	movl	%eax,32(%esi)			// width
#ifdef DEBUG
	testl	%eax,%eax
	jz	.Ldsc_debug_height_done
	movl	0(%esp),%eax
	subl	$SURFCACHE_DATA_OFFSET,%eax
	xorl	%edx,%edx
	divl	4(%esp)
	movl	%eax,SURFCACHE_HEIGHT_OFFSET(%esi)
.Ldsc_debug_height_done:
#endif
	movl	$0,4(%esi)			// owner = NULL

	cmpl	$0,C(d_roverwrapped)
	je	.Ldsc_not_yet_wrapped
	movl	12(%esp),%eax
	testl	%eax,%eax
	jnz	.Ldsc_mark_thrash
	movl	C(sc_rover),%eax
	cmpl	C(d_initial_rover),%eax
	jb	.Ldsc_finish
	jmp	.Ldsc_mark_thrash

.Ldsc_not_yet_wrapped:
	cmpl	$0,12(%esp)
	je	.Ldsc_finish
	movl	$1,C(d_roverwrapped)
	jmp	.Ldsc_finish

.Ldsc_mark_thrash:
	cmpl	$0,C(r_cache_thrash)
	jne	.Ldsc_finish
	movl	$1,C(r_cache_thrash)
#ifdef PROFILE486
	cmpl	$0,C(bench486_profile_frame_active)
	je	.Ldsc_finish
	incl	C(bench486_surface_cache_thrash_frames)
#endif

.Ldsc_finish:
#ifdef DEBUG
	call	C(D_CheckCacheGuard)
#endif
	movl	%esi,%eax

.Ldsc_return:
	addl	$16,%esp
	popl	%ebx
	popl	%esi
	popl	%edi
	popl	%ebp
	ret

.Ldsc_bad_width:
	pushl	%ebx
	pushl	$.Ldsc_bad_width_message
	call	C(Sys_Error)
	addl	$8,%esp
	xorl	%eax,%eax
	jmp	.Ldsc_return

.Ldsc_bad_size:
	pushl	40(%esp)
	pushl	$.Ldsc_bad_size_message
	call	C(Sys_Error)
	addl	$8,%esp
	xorl	%eax,%eax
	jmp	.Ldsc_return

	.section .rodata
.Ldsc_bad_width_message:
	.asciz "D_SCAlloc: bad cache width %d\n"
.Ldsc_bad_size_message:
	.asciz "D_SCAlloc: bad cache size %d\n"
.Ldsc_too_large:
	.asciz "D_SCAlloc: %i > cache size"
.Ldsc_end_of_memory:
	.asciz "D_SCAlloc: hit the end of memory"
	.text

// void D_CacheSurfaceSetup_asm486(msurface_t *surface, int miplevel,
//                                  drawsurf_t *drawsurf)
// Set the four miss-path fields consumed by R_DrawSurface. Structure offsets
// are checked against C at compile time in d_surf.c.
C(D_CacheSurfaceSetup_asm486):
	.globl C(D_CacheSurfaceSetup_asm486)
	movl	4(%esp),%eax		// surface
	movl	8(%esp),%ecx		// miplevel
	movl	12(%esp),%edx		// drawsurf
	movl	%ecx,32(%edx)		// surfmip
	movswl	48(%eax),%eax		// extents[0]
	sarl	%cl,%eax
	movl	%eax,36(%edx)		// surfwidth
	movl	%eax,4(%edx)		// rowbytes
	movl	4(%esp),%eax		// reload surface
	movswl	50(%eax),%eax		// extents[1]
	sarl	%cl,%eax
	movl	%eax,40(%edx)		// surfheight
	ret

// void D_CacheSurfaceKeys_asm486(msurface_t *surface, texture_t *texture,
//                                drawsurf_t *drawsurf, int *lightstylevalues)
// Resolve the four surface styles and stage the animated texture/cache key.
C(D_CacheSurfaceKeys_asm486):
	.globl C(D_CacheSurfaceKeys_asm486)
	pushl	%esi
	pushl	%edi
	movl	12(%esp),%eax		// surface
	movl	16(%esp),%esi		// texture
	movl	20(%esp),%ecx		// drawsurf
	movl	24(%esp),%edx		// d_lightstylevalue
	movl	%esi,28(%ecx)		// texture
	movzbl	56(%eax),%esi		// styles[0]
	movl	(%edx,%esi,4),%edi
	movl	%edi,12(%ecx)		// lightadj[0]
	movzbl	57(%eax),%esi		// styles[1]
	movl	(%edx,%esi,4),%edi
	movl	%edi,16(%ecx)		// lightadj[1]
	movzbl	58(%eax),%esi		// styles[2]
	movl	(%edx,%esi,4),%edi
	movl	%edi,20(%ecx)		// lightadj[2]
	movzbl	59(%eax),%esi		// styles[3]
	movl	(%edx,%esi,4),%edi
	movl	%edi,24(%ecx)		// lightadj[3]
	popl	%edi
	popl	%esi
	ret

// void D_CacheSurfaceStoreTags_asm486(surfcache_t *cache,
//                                      drawsurf_t *drawsurf)
// Copy the texture and four light-style cache tags from the prepared draw.
C(D_CacheSurfaceStoreTags_asm486):
	.globl C(D_CacheSurfaceStoreTags_asm486)
	movl	4(%esp),%eax		// cache
	movl	8(%esp),%edx		// drawsurf
	movl	12(%edx),%ecx
	movl	%ecx,8(%eax)		// cache->lightadj[0]
	movl	16(%edx),%ecx
	movl	%ecx,12(%eax)		// cache->lightadj[1]
	movl	20(%edx),%ecx
	movl	%ecx,16(%eax)		// cache->lightadj[2]
	movl	24(%edx),%ecx
	movl	%ecx,20(%eax)		// cache->lightadj[3]
	movl	28(%edx),%ecx
	movl	%ecx,SURFCACHE_TEXTURE_OFFSET(%eax)	// cache->texture
	ret

// void D_CacheSurfaceAttach_asm486(msurface_t *surface, int mip,
//     surfcache_t *cache, drawsurf_t *drawsurf, int cache_created)
// Attach newly allocated blocks once; always point R_DrawSurface at cache data.
C(D_CacheSurfaceAttach_asm486):
	.globl C(D_CacheSurfaceAttach_asm486)
	movl	4(%esp),%eax		// surface
	movl	8(%esp),%ecx		// mip level
	leal	28(%eax,%ecx,4),%ecx	// &surface->cachespots[mip]
	movl	12(%esp),%edx		// cache
	cmpl	$0,20(%esp)
	je	.Ldsc_attach_data
	movl	%edx,(%ecx)			// surface->cachespots[mip] = cache
	movl	%ecx,4(%edx)			// cache->owner = slot
.Ldsc_attach_data:
	movl	16(%esp),%eax		// drawsurf
	leal	SURFCACHE_DATA_OFFSET(%edx),%edx
	movl	%edx,(%eax)			// drawsurf->surfdat = cache->data
	ret

// void D_CacheSurfaceDispatch_asm486(msurface_t *surface,
//                                     drawsurf_t *drawsurf)
// Complete the cache-miss draw handoff and call the existing surface drawer.
C(D_CacheSurfaceDispatch_asm486):
	.globl C(D_CacheSurfaceDispatch_asm486)
	movl	4(%esp),%eax		// surface
	movl	8(%esp),%edx		// drawsurf
	movl	%eax,8(%edx)			// drawsurf->surf
	incl	C(c_surf)
	call	C(R_DrawSurface)
	ret

// void D_CacheSurfaceSetDlight_asm486(surfcache_t *cache, int surf_frame,
//                                      int frame, int contributed)
C(D_CacheSurfaceSetDlight_asm486):
	.globl C(D_CacheSurfaceSetDlight_asm486)
	movl	4(%esp),%eax		// cache
	movl	8(%esp),%edx		// surface dlight frame
	cmpl	12(%esp),%edx		// current frame
	jne	.Ldsc_clear_dlight
	movl	16(%esp),%edx		// contributed sample flag
	movl	%edx,24(%eax)			// cache->dlight
	ret
.Ldsc_clear_dlight:
	movl	$0,24(%eax)
	ret

	.p2align 4,,15

// surfcache_t *D_CacheSurface(msurface_t *surface, int miplevel)
// Own texture-animation selection, cache-key preparation and hit/miss flow;
// the focused helpers below this boundary keep their independent C or ASM
// selectors and the C dispatcher remains available in benchmark builds.
C(D_CacheSurface):
	.globl C(D_CacheSurface)
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	subl	$52,%esp
	movl	8(%ebp),%esi		// surface
	movl	12(%ebp),%ebx		// miplevel
#ifdef PROFILE486
	leal	-64(%ebp),%eax
	pushl	%eax
	call C(D_CacheSurfaceProfileBegin_asm486)
	addl	$4,%esp
#endif
	// Match R_TextureAnimation's call guard: static textures avoid the call;
	// alternate animations are consulted only for nonzero entity frames.
	movl	cs_surface_texinfo(%esi),%edx
	movl	cs_texinfo_texture(%edx),%edi
	cmpl	$0,cs_texture_anim_total(%edi)
	jne	.Lcache_surface_animate
	movl	C(currententity),%eax
	cmpl	$0,cs_entity_frame(%eax)
	je	.Lcache_surface_static_texture
	cmpl	$0,cs_texture_alternate_anims(%edi)
	je	.Lcache_surface_static_texture
.Lcache_surface_animate:
	pushl	%edi
	call	C(R_TextureAnimation)
	addl	$4,%esp
	movl	%eax,%edi
.Lcache_surface_static_texture:
	movl	cs_surface_cachespots(%esi,%ebx,4),%eax
	movl	%eax,-16(%ebp)		// cache
	movl	%edi,-20(%ebp)		// texture
	pushl	$C(d_lightstylevalue)
	pushl	$C(r_drawsurf)
	pushl	%edi
	pushl	%esi
	call	C(D_CacheSurfaceKeys_asm486)
	addl	$16,%esp
	movl	$C(r_drawsurf),%eax
	leal	12(%eax),%eax		// &r_drawsurf.lightadj[0]
	pushl	%esi			// surface for C-equivalent hit predicate
	pushl	%eax
	pushl	%edi
	pushl	C(r_framecount)
	movl	cs_surface_dlightframe(%esi),%eax
	pushl	%eax
	pushl	-16(%ebp)
	call	C(D_CacheSurfaceHit_asm486)
	addl	$24,%esp
	testl	%eax,%eax
	jz	.Lcache_surface_miss
	movl	%eax,-16(%ebp)
#ifdef PROFILE486
	leal	-64(%ebp),%eax
	pushl	%eax
	call	C(D_CacheSurfaceProfileHit_asm486)
	addl	$4,%esp
#endif
	movl	-16(%ebp),%eax
	jmp	.Lcache_surface_return

.Lcache_surface_miss:
#ifdef PROFILE486
	leal	-64(%ebp),%eax
	pushl	%esi
	pushl	%eax
	call	C(D_CacheSurfaceProfileMiss_asm486)
	addl	$8,%esp
#endif
	movl	$0,-24(%ebp)		// cache_created
	pushl	$C(r_drawsurf)
	pushl	%ebx
	pushl	%esi
	call	C(D_CacheSurfaceSetup_asm486)
	addl	$12,%esp
	cmpl	$0,-16(%ebp)
	jne	.Lcache_surface_have_cache
#ifdef PROFILE486
	leal	-64(%ebp),%eax
	pushl	%eax
	call	C(D_CacheSurfaceProfileAllocBegin_asm486)
	addl	$4,%esp
#endif
	movl	C(r_drawsurf)+36,%eax	// surfwidth
	movl	C(r_drawsurf)+40,%ecx	// surfheight
	mull	%ecx			// i486 one-operand multiply
	pushl	%eax			// width * height
	pushl	C(r_drawsurf)+36	// width
	call	C(D_SCAlloc)
	addl	$8,%esp
	movl	%eax,-16(%ebp)
#ifdef PROFILE486
	leal	-64(%ebp),%eax
	pushl	%eax
	call	C(D_CacheSurfaceProfileAllocEnd_asm486)
	addl	$4,%esp
#endif
	movl	$1,-24(%ebp)
.Lcache_surface_have_cache:
	pushl	-24(%ebp)
	pushl	$C(r_drawsurf)
	pushl	-16(%ebp)
	pushl	%ebx
	pushl	%esi
	call	C(D_CacheSurfaceAttach_asm486)
	addl	$20,%esp
	pushl	$C(r_drawsurf)
	pushl	-16(%ebp)
	call	C(D_CacheSurfaceStoreTags_asm486)
	addl	$8,%esp
#ifdef PROFILE486
	leal	-64(%ebp),%eax
	pushl	%eax
	call	C(D_CacheSurfaceProfileDrawBegin_asm486)
	addl	$4,%esp
#endif
	pushl	$C(r_drawsurf)
	pushl	%esi
	call	C(D_CacheSurfaceDispatch_asm486)
	addl	$8,%esp
#ifdef PROFILE486
	leal	-64(%ebp),%eax
	pushl	%eax
	call	C(D_CacheSurfaceProfileDrawEnd_asm486)
	addl	$4,%esp
#endif
	pushl	C(r_dlight_contributed)
	pushl	C(r_framecount)
	movl	cs_surface_dlightframe(%esi),%eax
	pushl	%eax
	pushl	-16(%ebp)
	call	C(D_CacheSurfaceSetDlight_asm486)
	addl	$16,%esp
#ifdef PROFILE486
	leal	-64(%ebp),%eax
	pushl	%eax
	call	C(D_CacheSurfaceProfileFinish_asm486)
	addl	$4,%esp
#endif
	movl	cs_surface_cachespots(%esi,%ebx,4),%eax

.Lcache_surface_return:
	addl	$52,%esp
	popl	%edi
	popl	%esi
	popl	%ebx
	leave
	ret
#endif

	.p2align 4,,15

// int D_MipLevelForScale_asm486(float scale)
// Use the 486 x87 compare flags for the three descending mip thresholds.
// fcomps pops the temporary scale, leaving no value on the FP stack.
#ifdef ASM486_MIP_LEVEL
C(D_MipLevelForScale):
	.globl C(D_MipLevelForScale)
#endif
C(D_MipLevelForScale_asm486):
	.globl C(D_MipLevelForScale_asm486)
	flds	4(%esp)
	fcoms	C(d_scalemip)
	fnstsw	%ax
	testb	$1,%ah			// C0: scale < d_scalemip[0]
	jnz	.Lmip_check_1
	xorl	%eax,%eax
	fstp	%st(0)
	jmp	.Lmip_clamp

.Lmip_check_1:
	fcoms	C(d_scalemip)+4
	fnstsw	%ax
	testb	$1,%ah			// C0: scale < d_scalemip[1]
	jnz	.Lmip_check_2
	movl	$1,%eax
	fstp	%st(0)
	jmp	.Lmip_clamp

.Lmip_check_2:
	fcomps	C(d_scalemip)+8
	fnstsw	%ax
	testb	$1,%ah			// C0: scale < d_scalemip[2]
	jnz	.Lmip_level_3
	movl	$2,%eax
	fstp	%st(0)
	jmp	.Lmip_clamp

.Lmip_level_3:
	movl	$3,%eax

.Lmip_clamp:
	movl	C(d_minmip),%edx
	cmpl	%edx,%eax
	jge	.Lmip_return
	movl	%edx,%eax
.Lmip_return:
	ret


#ifdef ASM486_SURFACE_ZGRADIENTS
	.p2align 4,,15

// void R_SetSurfaceZGradients_asm486(mplane_t *plane)
// Reuse the previous plane/entity/frame result, otherwise transform the plane
// normal and build the three 1/z gradients with the original x87 operation order.
#ifdef ASM486_SURFACE_ZGRADIENTS
.globl C(R_SetSurfaceZGradients)
C(R_SetSurfaceZGradients):
#endif
.globl C(R_SetSurfaceZGradients_asm486)
C(R_SetSurfaceZGradients_asm486):
	pushl	%ebp
	movl	%esp,%ebp
	subl	$20,%esp
	movl	8(%ebp),%eax
	movl	%eax,-4(%ebp)		// plane

	movl	C(r_zgradient_asm_cache_frame),%eax
	cmpl	C(r_framecount),%eax
	jne	.Lzgradient_miss
	movl	C(r_zgradient_asm_cache_plane),%eax
	cmpl	-4(%ebp),%eax
	jne	.Lzgradient_miss
	movl	C(r_zgradient_asm_cache_entity),%eax
	cmpl	C(currententity),%eax
	jne	.Lzgradient_miss
	movl	C(surface_p),%edx
	movl	C(r_zgradient_asm_cache_zistepu),%eax
	movl	%eax,st_d_zistepu(%edx)
	movl	C(r_zgradient_asm_cache_zistepv),%eax
	movl	%eax,st_d_zistepv(%edx)
	movl	C(r_zgradient_asm_cache_ziorigin),%eax
	movl	%eax,st_d_ziorigin(%edx)
	leave
	ret

.Lzgradient_miss:
	leal	-20(%ebp),%eax		// p_normal output
	pushl	%eax
	pushl	-4(%ebp)			// plane->normal begins at offset zero
	call	C(TransformVector)
	addl	$8,%esp

	// Match the compiler's C expression order: dist - (term0 + term1),
	// then subtract term2 before taking the reciprocal.
	movl	-4(%ebp),%eax
	flds	C(modelorg)
	fmuls	pl_normal(%eax)
	flds	C(modelorg)+4
	fmuls	pl_normal+4(%eax)
	faddp	%st,%st(1)
	fsubrs	pl_dist(%eax)
	flds	C(modelorg)+8
	fmuls	pl_normal+8(%eax)
	fsubrp	%st,%st(1)
	fld1
	fdivp	%st,%st(1)		// 1 / (dist - dot)

	flds	-20(%ebp)			// p_normal[0]
	fmuls	C(xscaleinv)
	fmul	%st(1),%st
	fsts	C(r_zgradient_asm_cache_zistepu)

	flds	-16(%ebp)			// p_normal[1]
	fmuls	C(yscaleinv)
	fmul	%st(2),%st
	fchs
	fsts	C(r_zgradient_asm_cache_zistepv)

	fxch	%st(2)			// reciprocal | zistepu | zistepv
	fmuls	-12(%ebp)			// p_normal[2] * distinv
	flds	C(xcenter)
	fmul	%st(2),%st
	fsubrp	%st,%st(1)		// subtract xcenter * extended zistepu
	flds	C(ycenter)
	fmul	%st(3),%st
	fsubrp	%st,%st(1)		// subtract ycenter * extended zistepv
	fsts	C(r_zgradient_asm_cache_ziorigin)

	movl	-4(%ebp),%eax
	movl	%eax,C(r_zgradient_asm_cache_plane)
	movl	C(currententity),%eax
	movl	%eax,C(r_zgradient_asm_cache_entity)
	movl	C(r_framecount),%eax
	movl	%eax,C(r_zgradient_asm_cache_frame)

	movl	C(surface_p),%edx
	fxch	%st(1)
	fstps	st_d_zistepu(%edx)
	fxch	%st(1)
	fstps	st_d_zistepv(%edx)
	fstps	st_d_ziorigin(%edx)
	leave
	ret
#endif

	.p2align 4,,15

// texture_t *R_TextureAnimationFrame_asm486(texture_t *base, int relative)
// Select the frame whose [anim_min, anim_max) interval contains relative.
// The caller handles alternate animations, the no-animation fast path, and
// the relative-time calculation.  Keep the C loop as the reference path.
C(R_TextureAnimationFrame_asm486):
	.globl C(R_TextureAnimationFrame_asm486)
	movl	4(%esp),%eax		// base
	movl	8(%esp),%edx		// relative
	xorl	%ecx,%ecx			// count

.Ltexture_animation_check:
	cmpl	%edx,cs_texture_anim_min(%eax)	// base->anim_min > relative
	jg	.Ltexture_animation_next
	cmpl	%edx,cs_texture_anim_max(%eax)	// base->anim_max <= relative
	jle	.Ltexture_animation_next
	ret

.Ltexture_animation_next:
	movl	cs_texture_anim_next(%eax),%eax	// base->anim_next
	testl	%eax,%eax
	jz	.Ltexture_animation_broken
	incl	%ecx
	cmpl	$100,%ecx
	jg	.Ltexture_animation_infinite
	jmp	.Ltexture_animation_check

.Ltexture_animation_broken:
	pushl	$Ltexture_animation_broken
	call	C(Sys_Error)
	addl	$4,%esp
	xorl	%eax,%eax
	ret

.Ltexture_animation_infinite:
	pushl	$Ltexture_animation_infinite
	call	C(Sys_Error)
	addl	$4,%esp
	xorl	%eax,%eax
	ret

#ifdef ASM486_TEXTURE_ANIMATION
	.p2align 4,,15

// texture_t *R_TextureAnimation_asm486(texture_t *base)
// Match the C wrapper, including alternate-anims selection, the static-texture
// fast path, truncation of cl.time*10 toward zero, signed remainder, and the
// assembly frame resolver. The x87 control word is restored around FISTP.
C(R_TextureAnimation_asm486):
	.globl C(R_TextureAnimation_asm486)
	pushl	%ebx
	subl	$8,%esp
	movl	16(%esp),%ebx		// base
	movl	C(currententity),%eax
	cmpl	$0,cs_entity_frame(%eax)
	je	.Ltexture_animation_entry_primary
	movl	cs_texture_alternate_anims(%ebx),%eax
	testl	%eax,%eax
	jz	.Ltexture_animation_entry_primary
	movl	%eax,%ebx

.Ltexture_animation_entry_primary:
	movl	cs_texture_anim_total(%ebx),%ecx
	testl	%ecx,%ecx
	jz	.Ltexture_animation_entry_return_base

	fnstcw	0(%esp)
	movw	0(%esp),%dx
	orw	$0x0c00,%dx
	movw	%dx,2(%esp)
	fldl	C(cl)+cs_cl_time
	fmull	Ltexture_animation_ten
	fldcw	2(%esp)
	fistpl	4(%esp)
	fldcw	0(%esp)
	movl	4(%esp),%eax
	cdq
	idivl	%ecx			// C signed remainder, truncated toward zero
	movl	%edx,%ecx			// relative phase
	movl	%ebx,%eax			// current texture
	xorl	%edx,%edx			// links followed

.Ltexture_animation_entry_check:
	cmpl	%ecx,cs_texture_anim_min(%eax)
	jg	.Ltexture_animation_entry_next
	cmpl	%ecx,cs_texture_anim_max(%eax)
	jle	.Ltexture_animation_entry_next
	jmp	.Ltexture_animation_entry_return

.Ltexture_animation_entry_next:
	movl	cs_texture_anim_next(%eax),%eax
	testl	%eax,%eax
	jz	.Ltexture_animation_entry_broken
	incl	%edx
	cmpl	$100,%edx
	jg	.Ltexture_animation_entry_infinite
	jmp	.Ltexture_animation_entry_check

.Ltexture_animation_entry_broken:
	pushl	$Ltexture_animation_broken
	call	C(Sys_Error)
	addl	$4,%esp
	xorl	%eax,%eax
	jmp	.Ltexture_animation_entry_return

.Ltexture_animation_entry_infinite:
	pushl	$Ltexture_animation_infinite
	call	C(Sys_Error)
	addl	$4,%esp
	xorl	%eax,%eax
	jmp	.Ltexture_animation_entry_return

.Ltexture_animation_entry_return_base:
	movl	%ebx,%eax
.Ltexture_animation_entry_return:
	addl	$8,%esp
	popl	%ebx
	ret
#endif

	.p2align 4,,15

// void R_BuildLightMapStyles_asm486(unsigned *dest, byte *lightmap,
//                                    int size, int maps, unsigned scale,
//                                    unsigned *lightadj)
// Combine contiguous 8-bit lightmap planes in the same order as the C
// reference.  The first plane includes ambient scale; later planes add.
C(R_BuildLightMapStyles_asm486):
	.globl C(R_BuildLightMapStyles_asm486)
	pushl	%ebp
	pushl	%edi
	pushl	%esi
	pushl	%ebx
	movl	20(%esp),%edi		// dest
	movl	24(%esp),%esi		// lightmap
	movl	32(%esp),%ebp		// maps
	movl	40(%esp),%ebx		// lightadj
	cmpl	$0,28(%esp)
	jle	.Llightmap_styles_done
	testl	%ebp,%ebp
	jle	.Llightmap_styles_done

	xorl	%ecx,%ecx			// pixel index
.Llightmap_styles_first:
	movzbl	(%esi,%ecx),%eax
	mull	(%ebx)
	addl	36(%esp),%eax		// scale
	movl	%eax,(%edi,%ecx,4)
	incl	%ecx
	cmpl	28(%esp),%ecx
	jb	.Llightmap_styles_first

	decl	%ebp
	jz	.Llightmap_styles_done
	addl	28(%esp),%esi			// next lightmap plane
	addl	$4,%ebx			// next style adjustment

.Llightmap_styles_extra:
	xorl	%ecx,%ecx
.Llightmap_styles_extra_loop:
	movzbl	(%esi,%ecx),%eax
	mull	(%ebx)
	addl	%eax,(%edi,%ecx,4)
	incl	%ecx
	cmpl	28(%esp),%ecx
	jb	.Llightmap_styles_extra_loop

	decl	%ebp
	jz	.Llightmap_styles_done
	addl	28(%esp),%esi
	addl	$4,%ebx
	jmp	.Llightmap_styles_extra

.Llightmap_styles_done:
	popl	%ebx
	popl	%esi
	popl	%edi
	popl	%ebp
	ret

// void D_FillRect(vrect_t *rect, int color)
//
// The rectangle coordinates and clipping arithmetic are kept in 32-bit
// registers, matching D_FillRect_C. Large rows use an aligned REP STOSL body
// with byte prologue/tail. The small aligned dword case intentionally retains
// the original two 32-bit add operations used to replicate color; for palette
// colors 0..255 this is a repeated byte, and for other inputs it preserves the
// C routine's historical result exactly.
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
	movl	espan_t_v(%ebx),%eax
	movl	C(viewspantable)(,%eax,4),%edx
	addl	espan_t_u(%ebx),%edx
	movl	%edx,C(r_turb_pdest)
	movl	espan_t_count(%ebx),%eax
	movl	%eax,TURB_COUNT(%ebp)
#ifdef PROFILE486
	incl	C(bench486_turbulent_rows)
	addl	%eax,C(bench486_turbulent_pixels)
#endif

	// GCC's -ffast-math x87 output adds the two products before the origin.
	// Preserve that emitted order and excess precision through the final casts.
	fildl	espan_t_v(%ebx)
	fmuls	C(d_sdivzstepv)
	fildl	espan_t_u(%ebx)
	fmuls	C(d_sdivzstepu)
	faddp	%st,%st(1)
	flds	C(d_sdivzorigin)
	faddp	%st,%st(1)
	fstpt	TURB_SDIVZ(%ebp)

	fildl	espan_t_v(%ebx)
	fmuls	C(d_tdivzstepv)
	fildl	espan_t_u(%ebx)
	fmuls	C(d_tdivzstepu)
	faddp	%st,%st(1)
	flds	C(d_tdivzorigin)
	faddp	%st,%st(1)
	fstpt	TURB_TDIVZ(%ebp)

	fildl	espan_t_v(%ebx)
	fmuls	C(d_zistepv)
	fildl	espan_t_u(%ebx)
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
	movl	(%ebx),%eax
	movl	%eax,-28(%ebp)		// u
	movl	4(%ebx),%eax
	movl	%eax,-32(%ebp)		// v
	movl	8(%ebx),%eax
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
	movl	12(%eax),%eax		// pnext
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

.Lwarp_pixels_group:
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
	decl	%edx
	jnz	.Lwarp_pixels_group

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
// The original function's C wrapper only supplied two automatic lookup
// arrays. Allocate those arrays here as well, then keep ratio setup, table
// generation, time-phase selection, destination calculation, and pixel copy
// in the assembly path.
	.equ	WARP_ROW_COUNT, 1030		// MAXHEIGHT + AMP2*2
	.equ	WARP_COL_COUNT, 1286		// MAXWIDTH + AMP2*2
	.equ	WARP_ROW_BYTES, WARP_ROW_COUNT * 4
	.equ	WARP_COL_BYTES, WARP_COL_COUNT * 4
	.equ	WARP_LOCAL, WARP_ROW_BYTES + WARP_COL_BYTES
	.equ	WARP_FRAME_BYTES, WARP_LOCAL + 16
	.equ	WARP_OLD_CW, WARP_LOCAL
	.equ	WARP_TRUNC_CW, WARP_LOCAL + 2
	.equ	WARP_PHASE, WARP_LOCAL + 4
	.equ	WARP_HRATIO, WARP_LOCAL + 8
	.equ	WARP_WRATIO, WARP_LOCAL + 12

	.p2align 4,,15
C(D_WarpScreen):
	.globl C(D_WarpScreen)
	pushl	%ebx
	pushl	%ebp
	pushl	%esi
	pushl	%edi
	subl	$WARP_FRAME_BYTES,%esp
	movl	%esp,%ebp			// stable base for local arrays and scalars
	leal	WARP_ROW_BYTES(%ebp),%esi	// column array

	// C stored each ratio as a float before entering the lookup loops.
	fildl	C(r_refdef)+8		// view width
	fildl	C(scr_vrect)+8		// screen rectangle width
	fdivrp	%st,%st(1)
	fstps	WARP_WRATIO(%ebp)
	fildl	C(r_refdef)+12		// view height
	fildl	C(scr_vrect)+12		// screen rectangle height
	fdivp	%st,%st(1)
	fstps	WARP_HRATIO(%ebp)

	// Build rowptr and column with the same 32-bit arguments as the C setup.
	pushl	WARP_WRATIO(%ebp)
	pushl	WARP_HRATIO(%ebp)
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

	// turb = intsintable + ((int)(cl.time * SPEED) & (CYCLE - 1)).
	fnstcw	WARP_OLD_CW(%ebp)
	movw	WARP_OLD_CW(%ebp),%dx
	orw	$0x0c00,%dx
	movw	%dx,WARP_TRUNC_CW(%ebp)
	flds	Lwarp_speed
	fmull	C(cl)+0x23c
	fldcw	WARP_TRUNC_CW(%ebp)
	fistpl	WARP_PHASE(%ebp)
	fldcw	WARP_OLD_CW(%ebp)
	movl	WARP_PHASE(%ebp),%ebx
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

	movl	%ebp,%esp
	addl	$WARP_FRAME_BYTES,%esp
	popl	%edi
	popl	%esi
	popl	%ebp
	popl	%ebx
	ret
#endif

	.p2align 4,,15

// void R_BuildLightMapFusedNoDlights_asm486(unsigned *dest, byte *lightmap,
//                                            int size, int maps,
//                                            unsigned scale, int *lightadj)
// Fused no-dlight accumulation plus inverse/shift/clamp for maps 2..4.
#define FUSED_LOAD_BASE(adj) \
	movzbl	(%esi,%ecx),%eax; \
	mull	adj(%ebx); \
	addl	%eax,%ebp
#define FUSED_LOAD_PLANE(plane,adj) \
	movl	plane(%esp),%edx; \
	movzbl	(%edx,%ecx),%eax; \
	mull	adj(%ebx); \
	addl	%eax,%ebp
#define FUSED_FINISH(clamp,loop) \
	movl	$65280,%eax; \
	subl	%ebp,%eax; \
	sarl	$2,%eax; \
	cmpl	$64,%eax; \
	jge	clamp; \
	movl	$64,%eax; \
clamp:	\
	movl	%eax,(%edi,%ecx,4); \
	incl	%ecx; \
	cmpl	40(%esp),%ecx; \
	jb	loop

C(R_BuildLightMapFusedNoDlights_asm486):
	.globl C(R_BuildLightMapFusedNoDlights_asm486)
	pushl	%ebp
	pushl	%edi
	pushl	%esi
	pushl	%ebx
	subl	$12,%esp
	movl	32(%esp),%edi		// dest
	movl	36(%esp),%esi		// lightmap
	movl	40(%esp),%edx		// size
	movl	52(%esp),%ebx		// lightadj
	leal	(%esi,%edx),%eax
	movl	%eax,0(%esp)
	addl	%edx,%eax
	movl	%eax,4(%esp)
	addl	%edx,%eax
	movl	%eax,8(%esp)
	movl	44(%esp),%eax		// maps
	cmpl	$2,%eax
	je	.Lfused_maps2
	cmpl	$3,%eax
	je	.Lfused_maps3
	cmpl	$4,%eax
	je	.Lfused_maps4
	jmp	.Lfused_done

.Lfused_maps2:
	xorl	%ecx,%ecx
.Lfused_loop2:
	movl	48(%esp),%ebp
	FUSED_LOAD_BASE(0)
	FUSED_LOAD_PLANE(0,4)
	FUSED_FINISH(.Lfused_clamp2,.Lfused_loop2)
	jmp	.Lfused_done

.Lfused_maps3:
	xorl	%ecx,%ecx
.Lfused_loop3:
	movl	48(%esp),%ebp
	FUSED_LOAD_BASE(0)
	FUSED_LOAD_PLANE(0,4)
	FUSED_LOAD_PLANE(4,8)
	FUSED_FINISH(.Lfused_clamp3,.Lfused_loop3)
	jmp	.Lfused_done

.Lfused_maps4:
	xorl	%ecx,%ecx
.Lfused_loop4:
	movl	48(%esp),%ebp
	FUSED_LOAD_BASE(0)
	FUSED_LOAD_PLANE(0,4)
	FUSED_LOAD_PLANE(4,8)
	FUSED_LOAD_PLANE(8,12)
	FUSED_FINISH(.Lfused_clamp4,.Lfused_loop4)

.Lfused_done:
	addl	$12,%esp
	popl	%ebx
	popl	%esi
	popl	%edi
	popl	%ebp
	ret

#undef FUSED_LOAD_BASE
#undef FUSED_LOAD_PLANE
#undef FUSED_FINISH

	.p2align 4,,15

// void R_BuildLightMapNormalize_asm486(unsigned *lights, int size)
// Invert and clamp a lightmap in place.  Keep the array pointer and count in
// registers and perform one store per element; the C compiler emits an
// additional pre-clamp store in the original inline loop on the 486 target.
C(R_BuildLightMapNormalize_asm486):
	.globl C(R_BuildLightMapNormalize_asm486)
	pushl	%edi
	pushl	%esi
	movl	12(%esp),%edi		// lights
	movl	16(%esp),%esi		// size
	movl	$0xff00,%edx		// 255 << 8
	testl	%esi,%esi
	jle	.Llightmap_normalize_done

.Llightmap_normalize_loop4:
	movl	%esi,%ecx
	shrl	$2,%ecx
	jz	.Llightmap_normalize_tail

.Llightmap_normalize_unrolled:
	movl	%edx,%eax
	subl	(%edi),%eax
	sarl	$2,%eax			// (8 - VID_CBITS), with VID_CBITS == 6
	cmpl	$64,%eax
	jge	.Llightmap_normalize_store0
	movl	$64,%eax
	.Llightmap_normalize_store0:
	movl	%eax,(%edi)

	movl	%edx,%eax
	subl	4(%edi),%eax
	sarl	$2,%eax
	cmpl	$64,%eax
	jge	.Llightmap_normalize_store1
	movl	$64,%eax
	.Llightmap_normalize_store1:
	movl	%eax,4(%edi)

	movl	%edx,%eax
	subl	8(%edi),%eax
	sarl	$2,%eax
	cmpl	$64,%eax
	jge	.Llightmap_normalize_store2
	movl	$64,%eax
	.Llightmap_normalize_store2:
	movl	%eax,8(%edi)

	movl	%edx,%eax
	subl	12(%edi),%eax
	sarl	$2,%eax
	cmpl	$64,%eax
	jge	.Llightmap_normalize_store3
	movl	$64,%eax
	.Llightmap_normalize_store3:
	movl	%eax,12(%edi)
	addl	$16,%edi

	decl	%ecx
	jnz	.Llightmap_normalize_unrolled

	andl	$3,%esi
	jz	.Llightmap_normalize_done

.Llightmap_normalize_tail:
	movl	%edx,%eax
	subl	(%edi),%eax
	sarl	$2,%eax
	cmpl	$64,%eax
	jge	.Llightmap_normalize_tail_store
	movl	$64,%eax
.Llightmap_normalize_tail_store:
	movl	%eax,(%edi)
	addl	$4,%edi
	decl	%esi
	jnz	.Llightmap_normalize_tail
	jmp	.Llightmap_normalize_done
.Llightmap_normalize_done:
	popl	%esi
	popl	%edi
	ret

	.p2align 4,,15

// int R_AddDynamicLightSamples_asm486(unsigned *blocklights, int smax,
//                                     int tmax, int local0, int local1,
//                                     float local1_float, int idist_limit,
//                                     int irad, int all_lit)
// Walk one sample rectangle while preserving C's per-row float-to-int
// truncation.  A positive fractional t coordinate becomes one unit closer to
// zero after its row crosses into negative values.
#define DLIGHT_SAMPLE_PIXEL_AT(offset) \
	movl	%edx,%eax; \
	subl	$16,%edx; \
	testl	%eax,%eax; \
	jge	1f; \
	negl	%eax; \
1: 	cmpl	%ecx,%eax; \
	jg	2f; \
	sarl	$1,%eax; \
	addl	%ecx,%eax; \
	jmp	3f; \
2: 	addl	%ebp,%eax; \
	3: 	cmpl	%ebx,%eax; \
	jge	4f; \
	sall	$8,%eax; \
	negl	%eax; \
	addl	64(%esp),%eax; \
	addl	%eax,offset(%esi); \
	incl	%edi; \
4:

#define DLIGHT_SAMPLE_ALL_AT(offset) \
	movl	%edx,%eax; \
	subl	$16,%edx; \
	testl	%eax,%eax; \
	jge	1f; \
	negl	%eax; \
1:  	cmpl	%ecx,%eax; \
	jg	2f; \
	sarl	$1,%eax; \
	addl	%ecx,%eax; \
	jmp	3f; \
2:  	addl	%ebp,%eax; \
3:  	sall	$8,%eax; \
	negl	%eax; \
	addl	64(%esp),%eax; \
	addl	%eax,offset(%esi)

C(R_AddDynamicLightSamples_asm486):
	.globl C(R_AddDynamicLightSamples_asm486)
	pushl	%ebp
	pushl	%edi
	pushl	%esi
	pushl	%ebx
	subl	$16,%esp

	// Four saved registers plus the 16-byte local block precede the args.
	movl	36(%esp),%esi		// blocklights
	movl	60(%esp),%ebx		// idist_limit
	xorl	%edi,%edi			// contributed count
	movl	44(%esp),%eax		// tmax
	movl	%eax,12(%esp)
	movl	52(%esp),%eax		// signed td for the current row
	movl	%eax,0(%esp)
	movl	$0,4(%esp)		// positive fractional t-coordinate flag
	cmpl	$0,%eax
	jl	.Ldlight_fraction_ready
	fildl	52(%esp)
	flds	56(%esp)
	fcompp
	fwait
	fnstsw	%ax
	sahf
	jbe	.Ldlight_fraction_ready
	movl	$1,4(%esp)
.Ldlight_fraction_ready:
	cmpl	$0,68(%esp)		// all sampled distances pass
	jz	.Ldlight_row
	movl	$1,%edi
	jmp	.Ldlight_all_row

.Ldlight_row:
	// ECX is the absolute row distance and EBP is td >> 1.  Keep the
	// signed row distance in the local block for the next row.
	movl	0(%esp),%eax
	cmpl	$0,4(%esp)
	je	.Ldlight_row_t_ready
	testl	%eax,%eax
	jge	.Ldlight_row_t_ready
	incl	%eax
.Ldlight_row_t_ready:
	movl	%eax,%ecx
	sarl	$31,%eax
	xorl	%eax,%ecx
	subl	%eax,%ecx
	movl	%ecx,%ebp
	sarl	$1,%ebp
	movl	48(%esp),%edx		// reset signed sd for this row
	movl	40(%esp),%eax		// smax / 4
	shrl	$2,%eax
	movl	%eax,8(%esp)
	testl	%eax,%eax
	jz	.Ldlight_tail_select

.Ldlight_quad:
	DLIGHT_SAMPLE_PIXEL_AT(0)
	DLIGHT_SAMPLE_PIXEL_AT(4)
	DLIGHT_SAMPLE_PIXEL_AT(8)
	DLIGHT_SAMPLE_PIXEL_AT(12)
	addl	$16,%esi
	decl	8(%esp)
	jnz	.Ldlight_quad

.Ldlight_tail_select:
	movl	40(%esp),%eax
	andl	$3,%eax
	jmp	.Ldlight_tail_table(,%eax,4)

.Ldlight_tail3:
	DLIGHT_SAMPLE_PIXEL_AT(0)
	addl	$4,%esi
.Ldlight_tail2:
	DLIGHT_SAMPLE_PIXEL_AT(0)
	addl	$4,%esi
.Ldlight_tail1:
	DLIGHT_SAMPLE_PIXEL_AT(0)
	addl	$4,%esi
	jmp	.Ldlight_row_done

.Ldlight_all_row:
	movl	0(%esp),%eax
	cmpl	$0,4(%esp)
	je	.Ldlight_all_row_t_ready
	testl	%eax,%eax
	jge	.Ldlight_all_row_t_ready
	incl	%eax
.Ldlight_all_row_t_ready:
	movl	%eax,%ecx
	sarl	$31,%eax
	xorl	%eax,%ecx
	subl	%eax,%ecx
	movl	%ecx,%ebp
	sarl	$1,%ebp
	movl	48(%esp),%edx		// reset signed sd for this row
	movl	40(%esp),%eax		// smax / 4
	shrl	$2,%eax
	movl	%eax,8(%esp)
	testl	%eax,%eax
	jz	.Ldlight_all_tail_select

.Ldlight_all_quad:
	DLIGHT_SAMPLE_ALL_AT(0)
	DLIGHT_SAMPLE_ALL_AT(4)
	DLIGHT_SAMPLE_ALL_AT(8)
	DLIGHT_SAMPLE_ALL_AT(12)
	addl	$16,%esi
	decl	8(%esp)
	jnz	.Ldlight_all_quad

.Ldlight_all_tail_select:
	movl	40(%esp),%eax
	andl	$3,%eax
	jmp	.Ldlight_all_tail_table(,%eax,4)

.Ldlight_all_tail3:
	DLIGHT_SAMPLE_ALL_AT(0)
	addl	$4,%esi
.Ldlight_all_tail2:
	DLIGHT_SAMPLE_ALL_AT(0)
	addl	$4,%esi
.Ldlight_all_tail1:
	DLIGHT_SAMPLE_ALL_AT(0)
	addl	$4,%esi
	jmp	.Ldlight_row_done

.Ldlight_row_done:
	subl	$16,0(%esp)
	decl	12(%esp)
	jnz	.Ldlight_row

	movl	%edi,%eax
	addl	$16,%esp
	popl	%ebx
	popl	%esi
	popl	%edi
	popl	%ebp
	ret

	// Keep jump-table data out of .text so the linear ISA audit only decodes
	// instructions.  The 32-bit flat DOS target can use these relocated entries.
	.section .rodata
.Ldlight_tail_table:
	.long .Ldlight_row_done, .Ldlight_tail1, .Ldlight_tail2, .Ldlight_tail3
.Ldlight_all_tail_table:
	.long .Ldlight_row_done, .Ldlight_all_tail1, .Ldlight_all_tail2, .Ldlight_all_tail3
	.text

	.p2align 4,,15

// Shared plane-dot body for the selector benchmark and the BSP walk.  The
// walker reaches this once per visible internal node, so expanding the body
// there avoids a stack argument, call/return, and cleanup on a hot path.
.macro BSP_PLANE_DOT plane_reg
	movzbl	16(\plane_reg),%eax		// plane->type
	testl	%eax,%eax
	jz	.Lbsp_plane_dot_x_\@
	cmpl	$1,%eax
	je	.Lbsp_plane_dot_y_\@
	cmpl	$2,%eax
	je	.Lbsp_plane_dot_z_\@

	flds	C(modelorg)
	fmuls	(\plane_reg)
	flds	C(modelorg)+4
	fmuls	4(\plane_reg)
	faddp	%st,%st(1)
	flds	C(modelorg)+8
	fmuls	8(\plane_reg)
	faddp	%st,%st(1)
	fsubs	12(\plane_reg)
	jmp	.Lbsp_plane_dot_done_\@

.Lbsp_plane_dot_x_\@:
	flds	C(modelorg)
	fsubs	12(\plane_reg)
	jmp	.Lbsp_plane_dot_done_\@

.Lbsp_plane_dot_y_\@:
	flds	C(modelorg)+4
	fsubs	12(\plane_reg)
	jmp	.Lbsp_plane_dot_done_\@

.Lbsp_plane_dot_z_\@:
	flds	C(modelorg)+8
	fsubs	12(\plane_reg)
.Lbsp_plane_dot_done_\@:
.endm

// double R_RecursiveWorldNodePlaneDot_asm486(mplane_t *plane)
// Calculate the viewpoint/plane dot used to choose the front BSP child.
// Axis-aligned planes avoid the three x87 multiplies; arbitrary planes keep
// the same left-to-right multiply/add order as the C DotProduct macro.
C(R_RecursiveWorldNodePlaneDot_asm486):
	.globl C(R_RecursiveWorldNodePlaneDot_asm486)
	movl	4(%esp),%edx		// plane
	BSP_PLANE_DOT %edx
	ret

	.p2align 4,,15

// int R_RecursiveWorldNodeClip_asm486(mnode_t *node, int clipflags)
// Unrolled i486 x87 schedule: retain each plane normal across both box tests.
C(R_RecursiveWorldNodeClip_asm486):
	.globl C(R_RecursiveWorldNodeClip_asm486)
	pushl	%ebx
	movl	8(%esp), %edx
	movl	12(%esp), %ecx
	testb	$1, %cl
	je	.Lbspclip_fast_132
	movl	C(pfrustum_indexes), %ebx
	flds	C(view_clipplanes)
	flds	C(view_clipplanes)+4
	flds	C(view_clipplanes)+8
	movl	4(%ebx), %eax
	fld	%st(1)
	fimuls	8(%edx,%eax,2)
	movl	(%ebx), %eax
	fld	%st(3)
	fimuls	8(%edx,%eax,2)
	faddp	%st, %st(1)
	movl	8(%ebx), %eax
	fld	%st(1)
	fimuls	8(%edx,%eax,2)
	faddp	%st, %st(1)
	flds	C(view_clipplanes)+12
	fsubr	%st, %st(1)
	fxch	%st(1)
	ftst
	fnstsw	%ax
	fstp	%st(0)
	testb	$69, %ah
	jne	.Lbspclip_fast_162
	fxch	%st(2)
	movl	16(%ebx), %eax
	fimuls	8(%edx,%eax,2)
	fxch	%st(3)
	movl	12(%ebx), %eax
	fimuls	8(%edx,%eax,2)
	faddp	%st, %st(3)
	movl	20(%ebx), %ebx
	fimuls	8(%edx,%ebx,2)
	faddp	%st, %st(2)
	fsubrp	%st, %st(1)
	ftst
	fnstsw	%ax
	fstp	%st(0)
	testb	$5, %ah
	jne	.Lbspclip_fast_132
	andl	$-2, %ecx
.Lbspclip_fast_132:
	testb	$2, %cl
	je	.Lbspclip_fast_135
	movl	C(pfrustum_indexes)+4, %ebx
	flds	C(view_clipplanes)+24
	flds	C(view_clipplanes)+28
	flds	C(view_clipplanes)+32
	movl	4(%ebx), %eax
	fld	%st(1)
	fimuls	8(%edx,%eax,2)
	movl	(%ebx), %eax
	fld	%st(3)
	fimuls	8(%edx,%eax,2)
	faddp	%st, %st(1)
	movl	8(%ebx), %eax
	fld	%st(1)
	fimuls	8(%edx,%eax,2)
	faddp	%st, %st(1)
	flds	C(view_clipplanes)+36
	fsubr	%st, %st(1)
	fxch	%st(1)
	ftst
	fnstsw	%ax
	fstp	%st(0)
	testb	$69, %ah
	jne	.Lbspclip_fast_163
	fxch	%st(3)
	movl	12(%ebx), %eax
	fimuls	8(%edx,%eax,2)
	fxch	%st(2)
	movl	16(%ebx), %eax
	fimuls	8(%edx,%eax,2)
	faddp	%st, %st(2)
	movl	20(%ebx), %ebx
	fimuls	8(%edx,%ebx,2)
	faddp	%st, %st(1)
	fsubp	%st, %st(1)
	ftst
	fnstsw	%ax
	fstp	%st(0)
	testb	$5, %ah
	jne	.Lbspclip_fast_135
	andl	$-3, %ecx
.Lbspclip_fast_135:
	testb	$4, %cl
	je	.Lbspclip_fast_137
	movl	C(pfrustum_indexes)+8, %ebx
	flds	C(view_clipplanes)+48
	flds	C(view_clipplanes)+52
	flds	C(view_clipplanes)+56
	movl	(%ebx), %eax
	fld	%st(2)
	fimuls	8(%edx,%eax,2)
	movl	4(%ebx), %eax
	fld	%st(2)
	fimuls	8(%edx,%eax,2)
	faddp	%st, %st(1)
	movl	8(%ebx), %eax
	fld	%st(1)
	fimuls	8(%edx,%eax,2)
	faddp	%st, %st(1)
	flds	C(view_clipplanes)+60
	fsubr	%st, %st(1)
	fxch	%st(1)
	ftst
	fnstsw	%ax
	fstp	%st(0)
	testb	$69, %ah
	jne	.Lbspclip_fast_164
	fxch	%st(3)
	movl	12(%ebx), %eax
	fimuls	8(%edx,%eax,2)
	fxch	%st(2)
	movl	16(%ebx), %eax
	fimuls	8(%edx,%eax,2)
	faddp	%st, %st(2)
	movl	20(%ebx), %ebx
	fimuls	8(%edx,%ebx,2)
	faddp	%st, %st(1)
	fsubp	%st, %st(1)
	ftst
	fnstsw	%ax
	fstp	%st(0)
	testb	$5, %ah
	jne	.Lbspclip_fast_137
	andl	$-5, %ecx
.Lbspclip_fast_137:
	testb	$8, %cl
	je	.Lbspclip_fast_139
	movl	C(pfrustum_indexes)+12, %ebx
	flds	C(view_clipplanes)+72
	flds	C(view_clipplanes)+76
	flds	C(view_clipplanes)+80
	movl	(%ebx), %eax
	fld	%st(2)
	fimuls	8(%edx,%eax,2)
	movl	4(%ebx), %eax
	fld	%st(2)
	fimuls	8(%edx,%eax,2)
	faddp	%st, %st(1)
	movl	8(%ebx), %eax
	fld	%st(1)
	fimuls	8(%edx,%eax,2)
	faddp	%st, %st(1)
	flds	C(view_clipplanes)+84
	fsubr	%st, %st(1)
	fxch	%st(1)
	ftst
	fnstsw	%ax
	fstp	%st(0)
	testb	$69, %ah
	jne	.Lbspclip_fast_165
	fxch	%st(3)
	movl	12(%ebx), %eax
	fimuls	8(%edx,%eax,2)
	fxch	%st(2)
	movl	16(%ebx), %eax
	fimuls	8(%edx,%eax,2)
	faddp	%st, %st(2)
	movl	20(%ebx), %ebx
	fimuls	8(%edx,%ebx,2)
	faddp	%st, %st(1)
	fsubp	%st, %st(1)
	ftst
	fnstsw	%ax
	fstp	%st(0)
	testb	$5, %ah
	jne	.Lbspclip_fast_139
	andl	$-9, %ecx
.Lbspclip_fast_139:
	movl	%ecx, %eax
	popl	%ebx
	ret
.Lbspclip_fast_162:
	fstp	%st(0)
	fstp	%st(0)
	fstp	%st(0)
	fstp	%st(0)
	jmp	.Lbspclip_fast_144
.Lbspclip_fast_163:
	fstp	%st(0)
	fstp	%st(0)
	fstp	%st(0)
	fstp	%st(0)
	jmp	.Lbspclip_fast_144
.Lbspclip_fast_164:
	fstp	%st(0)
	fstp	%st(0)
	fstp	%st(0)
	fstp	%st(0)
	jmp	.Lbspclip_fast_144
.Lbspclip_fast_165:
	fstp	%st(0)
	fstp	%st(0)
	fstp	%st(0)
	fstp	%st(0)
.Lbspclip_fast_144:
	movl	$-1, %eax
	popl	%ebx
	ret

#ifdef ASM486_BSP_WALK
	.p2align 4,,15

#ifdef ASM486_BSP_FRAME_COUNT
	.equ BSP_WALK_RECORD_BYTES, 28
#else
	.equ BSP_WALK_RECORD_BYTES, 24
#endif

// void R_RecursiveWorldNode_asm486(mnode_t *node, int clipflags)
// regparm(2): EAX=node and EDX=clipflags.  Use explicit records on the
// caller's stack to keep depth-first order without a function call per child.
// A parent record holds its front-to-back continuation while both subtrees
// are visited. The plane-dot and frustum helpers keep their reference order.
C(R_RecursiveWorldNode_asm486):
	.globl C(R_RecursiveWorldNode_asm486)
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	subl	$48,%esp
	movl	%esp,-52(%ebp)		// bottom of the explicit continuation stack
	movl	%eax,-56(%ebp)		// current node
	movl	%edx,-60(%ebp)		// current clip flags

.Lbsp_walk_node_enter:
	movl	-56(%ebp),%ebx
	movl	-60(%ebp),%eax
	movl	%eax,-20(%ebp)		// clipflags

#ifdef PROFILE486
	cmpl	$0,C(bench486_profile_frame_active)
	je	.Lbsp_walk_profile_node_done
	incl	C(bench486_bsp_nodes)
	cmpl	$-2,0(%ebx)			// CONTENTS_SOLID
	je	.Lbsp_walk_profile_solid
	movl	C(r_visframecount),%eax
	cmpl	%eax,4(%ebx)
	jne	.Lbsp_walk_profile_visibility
	cmpl	$0,0(%ebx)
	jl	.Lbsp_walk_profile_leaf
	incl	C(bench486_bsp_internal_nodes)
	jmp	.Lbsp_walk_profile_node_done
.Lbsp_walk_profile_solid:
	incl	C(bench486_bsp_solid_culls)
	jmp	.Lbsp_walk_profile_node_done
.Lbsp_walk_profile_visibility:
	incl	C(bench486_bsp_visibility_culls)
	jmp	.Lbsp_walk_profile_node_done
.Lbsp_walk_profile_leaf:
	incl	C(bench486_bsp_leaf_nodes)
.Lbsp_walk_profile_node_done:
#endif

	cmpl	$-2,0(%ebx)			// solid
	je	.Lbsp_walk_node_complete
	movl	C(r_visframecount),%eax
	cmpl	%eax,4(%ebx)
	jne	.Lbsp_walk_node_complete

	cmpl	$0,-20(%ebp)
	je	.Lbsp_walk_clip_done
	pushl	-20(%ebp)
	pushl	%ebx
	call	C(R_RecursiveWorldNodeClip_asm486)
	addl	$8,%esp
	testl	%eax,%eax
	js	.Lbsp_walk_node_complete
	movl	%eax,-20(%ebp)
.Lbsp_walk_clip_done:

#ifdef ASM486_BSP_FRAME_COUNT
	movl	C(r_framecount),%eax
	movl	%eax,-24(%ebp)
#endif

	cmpl	$0,0(%ebx)
	jl	.Lbsp_walk_leaf

// Internal node: choose the front child from the assembly plane dot.
	movl	24(%ebx),%edx		// node->plane
	BSP_PLANE_DOT %edx
	fstpl	-32(%ebp)
	movl	$1,%edi			// side defaults to back for unordered dot
	/* The stored IEEE double is >= 0 through +infinity, plus exactly -0. */
	movl	-28(%ebp),%eax
	cmpl	$0x7ff00000,%eax
	ja	.Lbsp_walk_dot_special
	jne	.Lbsp_walk_dot_front
	cmpl	$0,-32(%ebp)		// +infinity is ordered; NaNs have nonzero low bits
	je	.Lbsp_walk_dot_front
	jmp	.Lbsp_walk_side_ready
.Lbsp_walk_dot_special:
	cmpl	$0x80000000,%eax	// only negative zero reaches the front side
	jne	.Lbsp_walk_side_ready
	cmpl	$0,-32(%ebp)
	jne	.Lbsp_walk_side_ready
.Lbsp_walk_dot_front:
	movl	$0,%edi			// positive or zero
.Lbsp_walk_side_ready:
	// Save the parent continuation, then enter its front child. Record layout:
	// node, clip flags, double plane dot, side, stage, and optional framecount.
	subl	$BSP_WALK_RECORD_BYTES,%esp
	movl	%ebx,0(%esp)
	movl	-20(%ebp),%eax
	movl	%eax,4(%esp)
	movl	-32(%ebp),%eax
	movl	%eax,8(%esp)
	movl	-28(%ebp),%eax
	movl	%eax,12(%esp)
	movl	%edi,16(%esp)
	movl	$1,20(%esp)			// resume after front child
#ifdef ASM486_BSP_FRAME_COUNT
	movl	-24(%ebp),%eax
	movl	%eax,24(%esp)
#endif
	movl	%edi,%eax
	movl	28(%ebx,%eax,4),%eax
	movl	%eax,-56(%ebp)
	movl	-20(%ebp),%eax
	movl	%eax,-60(%ebp)
	jmp	.Lbsp_walk_node_enter

// Visit this node's marked surfaces in the same order as the C traversal.
.Lbsp_walk_resume_after_front:
	movl	$2,20(%esp)			// parent now awaits its back child
	movl	0(%esp),%ebx
	movl	4(%esp),%eax
	movl	%eax,-20(%ebp)
	movl	8(%esp),%eax
	movl	%eax,-32(%ebp)
	movl	12(%esp),%eax
	movl	%eax,-28(%ebp)
	movl	16(%esp),%edi
#ifdef ASM486_BSP_FRAME_COUNT
	movl	24(%esp),%eax
	movl	%eax,-24(%ebp)
#endif

.Lbsp_walk_surface_start:
	movzwl	38(%ebx),%eax		// unsigned short numsurfaces
	movl	%eax,-40(%ebp)
#ifdef PROFILE486
	cmpl	$0,C(bench486_profile_frame_active)
	je	.Lbsp_walk_profile_surfaces_done
	addl	%eax,C(bench486_bsp_surface_tests)
.Lbsp_walk_profile_surfaces_done:
#endif
	testl	%eax,%eax
	je	.Lbsp_walk_back_child

	movl	C(cl)+2692,%eax		// cl.worldmodel
	movl	180(%eax),%eax		// model_t.surfaces
	movzwl	36(%ebx),%edx		// firstsurface
	shll	$6,%edx			// sizeof(msurface_t) == 64
	addl	%edx,%eax
	movl	%eax,-36(%ebp)

	// C executes these comparisons in order and treats unordered as false.
	fldl	-32(%ebp)
	fcompl	.Lbsp_walk_negative_backface_epsilon
	fnstsw	%ax
	sahf
	jp	.Lbsp_walk_surface_sequence_done
	jb	.Lbsp_walk_back_surfaces
	fldl	-32(%ebp)
	fcompl	.Lbsp_walk_positive_backface_epsilon
	fnstsw	%ax
	sahf
	jp	.Lbsp_walk_surface_sequence_done
	ja	.Lbsp_walk_front_surfaces
	jmp	.Lbsp_walk_surface_sequence_done

.Lbsp_walk_back_surfaces:
	movl	$2,-48(%ebp)		// require SURF_PLANEBACK
	jmp	.Lbsp_walk_surface_loop_begin
.Lbsp_walk_front_surfaces:
	movl	$0,-48(%ebp)		// require front-facing surface flag
.Lbsp_walk_surface_loop_begin:
	movl	-40(%ebp),%eax
	testl	%eax,%eax
	je	.Lbsp_walk_surface_sequence_done
#ifdef ASM486_BSP_FRAME_COUNT
	movl	-24(%ebp),%ebx
#else
	movl	C(r_framecount),%ebx
#endif
.Lbsp_walk_surface_loop:
	movl	-36(%ebp),%esi
	cmpl	%ebx,0(%esi)
	jne	.Lbsp_walk_surface_next
	movl	16(%esi),%eax		// flags
	andl	$2,%eax
	cmpl	-48(%ebp),%eax
	jne	.Lbsp_walk_surface_next

	cmpl	$0,C(r_drawpolys)
	je	.Lbsp_walk_render_face
	cmpl	$0,C(r_worldpolysbacktofront)
	je	.Lbsp_walk_render_poly
	movl	C(numbtofpolys),%eax
	cmpl	$5000,%eax			// MAX_BTOFPOLYS
	jge	.Lbsp_walk_surface_next
	movl	C(pbtofpolys),%edx
	movl	-20(%ebp),%ecx
	movl	%ecx,(%edx,%eax,8)
	movl	%esi,4(%edx,%eax,8)
	incl	%eax
	movl	%eax,C(numbtofpolys)
	jmp	.Lbsp_walk_surface_next

.Lbsp_walk_render_poly:
	pushl	-20(%ebp)
	pushl	%esi
	call	C(R_RenderPoly)
	addl	$8,%esp
	jmp	.Lbsp_walk_surface_next

.Lbsp_walk_render_face:
#ifdef PROFILE486
	call	C(R_BspProfileRenderFaceEnter_asm486)
#endif
	pushl	-20(%ebp)
	pushl	%esi
	call	C(R_RenderFace)
	addl	$8,%esp
#ifdef PROFILE486
	call	C(R_BspProfileRenderFaceLeave_asm486)
#endif

.Lbsp_walk_surface_next:
	addl	$64,-36(%ebp)
	decl	-40(%ebp)
	jnz	.Lbsp_walk_surface_loop

.Lbsp_walk_surface_sequence_done:
	incl	C(r_currentkey)		// all surfaces on the node share one key

.Lbsp_walk_back_child:
	movl	0(%esp),%ebx			// restore the current node from its continuation
	movl	%edi,%eax
	xorl	$1,%eax			// !side
	movl	28(%ebx,%eax,4),%eax
	movl	%eax,-56(%ebp)
	movl	-20(%ebp),%eax
	movl	%eax,-60(%ebp)
	jmp	.Lbsp_walk_node_enter

.Lbsp_walk_leaf:
	movl	36(%ebx),%ecx		// nummarksurfaces
	testl	%ecx,%ecx
	jz	.Lbsp_walk_leaf_efrags
	movl	32(%ebx),%esi		// firstmarksurface
.Lbsp_walk_leaf_marks:
	movl	(%esi),%edi
#ifdef ASM486_BSP_FRAME_COUNT
	movl	-24(%ebp),%eax
#else
	movl	C(r_framecount),%eax
#endif
	movl	%eax,0(%edi)
	addl	$4,%esi
	decl	%ecx
	jnz	.Lbsp_walk_leaf_marks

.Lbsp_walk_leaf_efrags:
	cmpl	$0,28(%ebx)
	je	.Lbsp_walk_leaf_key
	leal	28(%ebx),%eax		// address of pleaf->efrags
	pushl	%eax
	call	C(R_StoreEfrags)
	addl	$4,%esp
.Lbsp_walk_leaf_key:
	movl	C(r_currentkey),%eax
	movl	%eax,40(%ebx)		// pleaf->key
	incl	C(r_currentkey)

.Lbsp_walk_node_complete:
	movl	-52(%ebp),%eax
	cmpl	%eax,%esp
	je	.Lbsp_walk_return
	cmpl	$1,20(%esp)
	je	.Lbsp_walk_resume_after_front
	addl	$BSP_WALK_RECORD_BYTES,%esp
	jmp	.Lbsp_walk_node_complete

.Lbsp_walk_return:
	leal	-12(%ebp),%esp
	popl	%edi
	popl	%esi
	popl	%ebx
	popl	%ebp
	ret
#endif

	.p2align 4,,15

// int R_AliasCheckBBoxProject_asm486(auxvert_t *viewaux,
//                                    finalvert_t *viewpts, int numv)
// Project the unclipped alias bounding-box vertices and return anyclip in the
// low byte and allclip in the next byte.  Keep the reciprocal and both screen
// coordinates in the x87 stack while the integer registers hold the loop
// state and clip masks.
#define bbox_aux_size	12
#define bbox_fv_flags	24
#define bbox_fv_size	32
#define bbox_r_fvrectx	60
#define bbox_r_fvrecty	64
#define bbox_r_fvrectright	92
#define bbox_r_fvrectbottom	96

C(R_AliasCheckBBoxProject_asm486):
	.globl C(R_AliasCheckBBoxProject_asm486)
	pushl	%ebp
	pushl	%edi
	pushl	%esi
	pushl	%ebx
	movl	20(%esp),%esi		// viewaux
	movl	24(%esp),%edi		// viewpts
	movl	28(%esp),%ecx		// numv
	xorl	%edx,%edx			// anyclip
	movl	$0x000f,%ebx			// allclip
	testl	%ecx,%ecx
	jle	.Lalias_bbox_project_done

.Lalias_bbox_project_loop:
	xorl	%ebp,%ebp			// flags
	testl	$0x0010,bbox_fv_flags(%edi)
	jnz	.Lalias_bbox_project_next

	// zi = 1.0 / viewaux->fv[2]; keep zi below the projected value.
	fld1
	fdivs	8(%esi)

	// v0 = viewaux->fv[0] * aliasxscale * zi + aliasxcenter.
	flds	0(%esi)
	fmuls	C(aliasxscale)
	fmul	%st(1),%st
	fadds	C(aliasxcenter)
	fcoms	C(r_refdef)+bbox_r_fvrectx
	fnstsw	%ax
	testb	$1,%ah
	jz	.Lalias_bbox_project_no_left
	orl	$0x0001,%ebp
.Lalias_bbox_project_no_left:
	fcoms	C(r_refdef)+bbox_r_fvrectright
	fnstsw	%ax
	testb	$0x45,%ah
	jnz	.Lalias_bbox_project_no_right
	orl	$0x0004,%ebp
.Lalias_bbox_project_no_right:
	fstp	%st(0)			// discard v0, leave zi

	// v1 = viewaux->fv[1] * aliasyscale * zi + aliasycenter.
	flds	4(%esi)
	fmuls	C(aliasyscale)
	fmul	%st(1),%st
	fadds	C(aliasycenter)
	fcoms	C(r_refdef)+bbox_r_fvrecty
	fnstsw	%ax
	testb	$1,%ah
	jz	.Lalias_bbox_project_no_top
	orl	$0x0002,%ebp
.Lalias_bbox_project_no_top:
	fcoms	C(r_refdef)+bbox_r_fvrectbottom
	fnstsw	%ax
	testb	$0x45,%ah
	jnz	.Lalias_bbox_project_no_bottom
	orl	$0x0008,%ebp
.Lalias_bbox_project_no_bottom:
	fstp	%st(0)			// discard v1
	fstp	%st(0)			// discard zi

	orl	%ebp,%edx
	andl	%ebp,%ebx

.Lalias_bbox_project_next:
	addl	$bbox_aux_size,%esi
	addl	$bbox_fv_size,%edi
	decl	%ecx
	jnz	.Lalias_bbox_project_loop

.Lalias_bbox_project_done:
	shll	$8,%ebx
	movl	%ebx,%eax
	orl	%edx,%eax
	popl	%ebx
	popl	%esi
	popl	%edi
	popl	%ebp
	ret

	.p2align 4,,15

// void R_AliasTransformVector_asm486(vec3_t in, vec3_t out)
// Transform one alias bounding-box corner.  Match the reference C build's
// x87 order: accumulate coordinates 0 and 1, add translation, then add 2.
C(R_AliasTransformVector_asm486):
	.globl C(R_AliasTransformVector_asm486)
	pushl	%esi
	pushl	%edi
	movl	12(%esp),%esi		// input vector
	movl	16(%esp),%edi		// output vector

	flds	0(%esi)
	fmuls	C(aliastransform)+0
	flds	4(%esi)
	fmuls	C(aliastransform)+4
	faddp	%st(0),%st(1)
	fadds	C(aliastransform)+12
	flds	8(%esi)
	fmuls	C(aliastransform)+8
	faddp	%st(0),%st(1)
	fstps	0(%edi)

	flds	0(%esi)
	fmuls	C(aliastransform)+16
	flds	4(%esi)
	fmuls	C(aliastransform)+20
	faddp	%st(0),%st(1)
	fadds	C(aliastransform)+28
	flds	8(%esi)
	fmuls	C(aliastransform)+24
	faddp	%st(0),%st(1)
	fstps	4(%edi)

	flds	0(%esi)
	fmuls	C(aliastransform)+32
	flds	4(%esi)
	fmuls	C(aliastransform)+36
	faddp	%st(0),%st(1)
	fadds	C(aliastransform)+44
	flds	8(%esi)
	fmuls	C(aliastransform)+40
	faddp	%st(0),%st(1)
	fstps	8(%edi)

	popl	%edi
	popl	%esi
	ret

	.p2align 4,,15

// Keep this operand order tied to the DJGPP reference disassembly of
// R_ConcatTransforms: accumulate products 0 and 1, add the row translation
// for column 3, then add product 2.  Each output is stored as a float before
// the next expression, as in C.  The macro expands only to i386/x87 forms.
	.macro	CONCAT_TRANSFORM out, a0, b0, a1, b1, a2, b2, translation
	flds	\a0(%eax)
	fmuls	\b0(%edx)
	flds	\a1(%eax)
	fmuls	\b1(%edx)
	faddp	%st(0),%st(1)
	.if	\translation >= 0
	fadds	\translation(%eax)
	.endif
	flds	\a2(%eax)
	fmuls	\b2(%edx)
	faddp	%st(0),%st(1)
	fstps	\out(%ecx)
	.endm

// void R_ConcatTransforms_asm486(float in1[3][4], float in2[3][4],
//                                float out[3][4])
// Cdecl; only caller-saved integer registers are used.  Every x87 result is
// popped by FSTPS, so the routine returns with the x87 stack balanced.
C(R_ConcatTransforms_asm486):
	.globl	C(R_ConcatTransforms_asm486)
	movl	4(%esp),%eax		// in1
	movl	8(%esp),%edx		// in2
	movl	12(%esp),%ecx		// out

	CONCAT_TRANSFORM 0, 0, 0, 4, 16, 8, 32, -1
	CONCAT_TRANSFORM 4, 0, 4, 4, 20, 8, 36, -1
	CONCAT_TRANSFORM 8, 0, 8, 4, 24, 8, 40, -1
	CONCAT_TRANSFORM 12, 0, 12, 4, 28, 8, 44, 12
	CONCAT_TRANSFORM 16, 16, 0, 20, 16, 24, 32, -1
	CONCAT_TRANSFORM 20, 16, 4, 20, 20, 24, 36, -1
	CONCAT_TRANSFORM 24, 16, 8, 20, 24, 24, 40, -1
	CONCAT_TRANSFORM 28, 16, 12, 20, 28, 24, 44, 28
	CONCAT_TRANSFORM 32, 32, 0, 36, 16, 40, 32, -1
	CONCAT_TRANSFORM 36, 32, 4, 36, 20, 40, 36, -1
	CONCAT_TRANSFORM 40, 32, 8, 36, 24, 40, 40, -1
	CONCAT_TRANSFORM 44, 32, 12, 36, 28, 40, 44, 44
	ret

#ifdef ASM486_ALIAS_MATRIX_COMPOSE_ASM
	.p2align 4,,15
// void R_AliasSetViewMatrix_asm486(const float *right, const float *up,
//                                  const float *forward, float *out)
// Copy the three view basis vectors into the 3x4 alias matrix and negate the
// up row by flipping its IEEE-754 sign bits, exactly matching VectorInverse.
// The fourth element of each row is deliberately untouched, like VectorCopy.
C(R_AliasSetViewMatrix_asm486):
	.globl C(R_AliasSetViewMatrix_asm486)
	pushl	%ebx
	pushl	%edi
	movl	12(%esp),%eax		// right
	movl	16(%esp),%ecx		// up
	movl	20(%esp),%edx		// forward
	movl	24(%esp),%edi		// output
	movl	(%eax),%ebx
	movl	%ebx,0(%edi)
	movl	4(%eax),%ebx
	movl	%ebx,4(%edi)
	movl	8(%eax),%ebx
	movl	%ebx,8(%edi)
	movl	(%ecx),%ebx
	xorl	$0x80000000,%ebx
	movl	%ebx,16(%edi)
	movl	4(%ecx),%ebx
	xorl	$0x80000000,%ebx
	movl	%ebx,20(%edi)
	movl	8(%ecx),%ebx
	xorl	$0x80000000,%ebx
	movl	%ebx,24(%edi)
	movl	(%edx),%ebx
	movl	%ebx,32(%edi)
	movl	4(%edx),%ebx
	movl	%ebx,36(%edi)
	movl	8(%edx),%ebx
	movl	%ebx,40(%edi)
	popl	%edi
	popl	%ebx
	ret
#endif

	.p2align 4,,15

// void R_AliasTransformFinalVert_asm486(finalvert_t *fv, auxvert_t *av,
//                                        trivertx_t *pverts,
//                                        stvert_t *pstverts)
// Transform one clipped alias vertex and calculate its lighting value.  The
// input bytes are expanded once, then reused for all three x87 dot products.
C(R_AliasTransformFinalVert_asm486):
	.globl C(R_AliasTransformFinalVert_asm486)
	pushl	%ebp
	pushl	%edi
	pushl	%esi
	pushl	%ebx
	movl	20(%esp),%edi		// fv
	movl	24(%esp),%ebp		// av
	movl	28(%esp),%esi		// pverts
	movl	32(%esp),%ebx		// pstverts
	subl	$4,%esp
	fnstcw	0(%esp)
	movw	0(%esp),%dx
	orw	$0x0c00,%dx			// C's float-to-int cast truncates toward zero
	movw	%dx,2(%esp)

	movzbl	0(%esi),%eax
	movl	%eax,Lalias_transform_coords
	movzbl	1(%esi),%eax
	movl	%eax,Lalias_transform_coords+4
	movzbl	2(%esi),%eax
	movl	%eax,Lalias_transform_coords+8

	// Preserve the reference compiler's x87 evaluation order for each row:
	// accumulate the first two products, add translation, then add the third.
	fildl	Lalias_transform_coords
	fmuls	C(aliastransform)+0
	fildl	Lalias_transform_coords+4
	fmuls	C(aliastransform)+4
	faddp	%st(0),%st(1)
	fadds	C(aliastransform)+12
	fildl	Lalias_transform_coords+8
	fmuls	C(aliastransform)+8
	faddp	%st(0),%st(1)
	fstps	0(%ebp)

	fildl	Lalias_transform_coords
	fmuls	C(aliastransform)+16
	fildl	Lalias_transform_coords+4
	fmuls	C(aliastransform)+20
	faddp	%st(0),%st(1)
	fadds	C(aliastransform)+28
	fildl	Lalias_transform_coords+8
	fmuls	C(aliastransform)+24
	faddp	%st(0),%st(1)
	fstps	4(%ebp)

	fildl	Lalias_transform_coords
	fmuls	C(aliastransform)+32
	fildl	Lalias_transform_coords+4
	fmuls	C(aliastransform)+36
	faddp	%st(0),%st(1)
	fadds	C(aliastransform)+44
	fildl	Lalias_transform_coords+8
	fmuls	C(aliastransform)+40
	faddp	%st(0),%st(1)
	fstps	8(%ebp)

	movl	stv_s(%ebx),%eax
	movl	%eax,fv_v+8(%edi)
	movl	stv_t(%ebx),%eax
	movl	%eax,fv_v+12(%edi)
	movl	stv_onseam(%ebx),%eax
	movl	%eax,fv_flags(%edi)

	movzbl	tv_lightnormalindex(%esi),%eax
	leal	(%eax,%eax,2),%eax
	flds	C(r_avertexnormals)(,%eax,4)
	fmuls	C(r_plightvec)
	flds	C(r_avertexnormals)+4(,%eax,4)
	fmuls	C(r_plightvec)+4
	faddp	%st(0),%st(1)
	flds	C(r_avertexnormals)+8(,%eax,4)
	fmuls	C(r_plightvec)+8
	faddp	%st(0),%st(1)
	fsts	Lalias_transform_temp
	movl	C(r_ambientlight),%eax
	movb	Lalias_transform_temp+3,%dl
	testb	$0x80,%dl
	jnz	.Lalias_transform_shaded
	fstp	%st(0)
	jmp	.Lalias_transform_store_light

.Lalias_transform_shaded:
	fmuls	C(r_shadelight)
	fldcw	2(%esp)
	fistpl	Lalias_transform_temp
	fldcw	0(%esp)
	addl	Lalias_transform_temp,%eax
	jns	.Lalias_transform_store_light
	xorl	%eax,%eax

.Lalias_transform_store_light:
	movl	%eax,fv_v+16(%edi)
	addl	$4,%esp
	popl	%ebx
	popl	%esi
	popl	%edi
	popl	%ebp
	ret

#if defined(ASM486_ALIAS_SETUP_LIGHTING) || defined(BENCH486)
	.extern C(r_ambientlight)
	.extern C(r_plightvec)
	.extern C(r_shadelight)

	.section .rodata
	.p2align 2
.Lalias_setup_lighting_grades:
	.float 64.0

	.text
	.p2align 4,,15

// void R_AliasSetupLighting_asm486(alight_t *lighting,
//        const float *forward, const float *right, const float *up)
// Keep the original 32-bit stores between the scalar conversions and the
// vector dot products.  Each dot accumulates X and Y, then adds Z, matching
// Quake's left-to-right DotProduct expression and the clipped-vertex helper.
C(R_AliasSetupLighting_asm486):
	.globl C(R_AliasSetupLighting_asm486)
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	movl	8(%ebp),%esi		// alight_t *lighting
	movl	12(%ebp),%edi		// alias forward
	movl	16(%ebp),%ebx		// negative alias right
	movl	20(%ebp),%ecx		// alias up

	// Match the two lower clamps and VID_CBITS transform in the C reference.
	movl	0(%esi),%eax
	cmpl	$5,%eax
	jge	.Lalias_setup_ambient_minimum
	movl	$5,%eax
.Lalias_setup_ambient_minimum:
	movl	$255,%edx
	subl	%eax,%edx
	shll	$6,%edx
	cmpl	$5,%edx
	jge	.Lalias_setup_store_ambient
	movl	$5,%edx
.Lalias_setup_store_ambient:
	movl	%edx,C(r_ambientlight)

	// C first converts the integer to float, clamps negatives, then scales.
	fildl	4(%esi)
	fstps	C(r_shadelight)
	cmpl	$0,4(%esi)
	jge	.Lalias_setup_shade_nonnegative
	fldz
	fstps	C(r_shadelight)
.Lalias_setup_shade_nonnegative:
	flds	C(r_shadelight)
	fmuls	.Lalias_setup_lighting_grades
	fstps	C(r_shadelight)

	movl	8(%esi),%edx		// float *plightvec
	flds	0(%edi)
	fmuls	0(%edx)
	flds	4(%edi)
	fmuls	4(%edx)
	faddp	%st(0),%st(1)
	flds	8(%edi)
	fmuls	8(%edx)
	faddp	%st(0),%st(1)
	fstps	C(r_plightvec)

	flds	0(%ebx)
	fmuls	0(%edx)
	flds	4(%ebx)
	fmuls	4(%edx)
	faddp	%st(0),%st(1)
	flds	8(%ebx)
	fmuls	8(%edx)
	faddp	%st(0),%st(1)
	fchs
	fstps	C(r_plightvec)+4

	flds	0(%ecx)
	fmuls	0(%edx)
	flds	4(%ecx)
	fmuls	4(%edx)
	faddp	%st(0),%st(1)
	flds	8(%ecx)
	fmuls	8(%edx)
	faddp	%st(0),%st(1)
	fstps	C(r_plightvec)+8

	popl	%edi
	popl	%esi
	popl	%ebx
	popl	%ebp
	ret
#endif

#if defined(ASM486_ALIAS_SETUP_FRAME) || defined(BENCH486)
	.extern C(paliashdr)
	.extern C(r_apverts)

	.text
	.p2align 4,,15
// void R_AliasSetupFrame_asm486(int frame, double cltime, float syncbase)
// Resolve the normalized alias frame exactly as R_AliasSetupFrame_C does.
// The public C wrapper retains the entity-range diagnostic and frame-zero
// fallback; this helper handles one descriptor and either a single frame or
// an interval group. Alias file offsets are relative to paliashdr.
C(R_AliasSetupFrame_asm486):
	.globl C(R_AliasSetupFrame_asm486)
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	subl	$16,%esp

	// Locals: saved CW=-16, truncate CW=-18, quotient=-20,
	// group frame count=-24, group pointer=-28.
	movl	C(paliashdr),%esi
	movl	8(%ebp),%eax
	shll	$5,%eax
	leal	16(%esi,%eax),%edi	// aliashdr.frames[frame], stride 32
	cmpl	$0,0(%edi)			// ALIAS_SINGLE == 0
	jne	.Lalias_setup_frame_group
	movl	12(%edi),%eax
	addl	%esi,%eax
	movl	%eax,C(r_apverts)
	jmp	.Lalias_setup_frame_done

.Lalias_setup_frame_group:
	movl	12(%edi),%ebx
	addl	%esi,%ebx			// maliasgroup_t *
	movl	%ebx,-28(%ebp)
	movl	0(%ebx),%eax
	movl	%eax,-24(%ebp)
	movl	4(%ebx),%edi
	addl	%esi,%edi			// float *intervals

	// fullinterval = intervals[numframes-1].
	movl	-24(%ebp),%eax
	flds	-4(%edi,%eax,4)

	// Keep the sprite selector's proven x87 ordering: compute time as the
	// double cl.time plus float syncbase, divide by fullinterval, truncate the
	// quotient toward zero with a temporary CW, then form targettime. The
	// original C locals are float; the compiler's i386 x87 expression handling
	// and the focused C-vs-assembly fixture pin the resulting single values.
	flds	20(%ebp)
	faddl	12(%ebp)
	fld	%st(0)
	fdiv	%st(2),%st(0)
	fnstcw	-16(%ebp)
	movw	-16(%ebp),%dx
	orb	$0x0c,%dh
	movw	%dx,-18(%ebp)
	fldcw	-18(%ebp)
	fistpl	-20(%ebp)
	fldcw	-16(%ebp)
	fxch	%st(1)
	fimull	-20(%ebp)
	fsubrp	%st,%st(1)

	// Scan i in [0,numframes-2]; equality selects the next interval.
	movl	-24(%ebp),%ebx
	decl	%ebx
	xorl	%edx,%edx
	testl	%ebx,%ebx
	jle	.Lalias_setup_frame_select
.Lalias_setup_frame_interval_loop:
	fcoms	(%edi,%edx,4)
	fnstsw	%ax
	testb	$0x01,%ah			// C0: targettime < intervals[i]
	jnz	.Lalias_setup_frame_select
	incl	%edx
	cmpl	%ebx,%edx
	jl	.Lalias_setup_frame_interval_loop
.Lalias_setup_frame_select:
	fstp	%st(0)
	movl	-28(%ebp),%eax
	leal	(%edx,%edx,2),%ecx		// 3*i for 12-byte frame descriptors
	movl	16(%eax,%ecx,4),%eax
	addl	%esi,%eax
	movl	%eax,C(r_apverts)

.Lalias_setup_frame_done:
	addl	$16,%esp
	popl	%edi
	popl	%esi
	popl	%ebx
	popl	%ebp
	ret
#endif

#if defined(ASM486_ALIAS_SETUP_SKIN) || defined(BENCH486)
	.extern C(paliashdr)

	.text
	.p2align 4,,15
// maliasskindesc_t *R_AliasSetupSkinSelect_asm486(
//     int skinnum, double cltime, float syncbase)
// Resolve one single or grouped alias skin descriptor. The public C wrapper
// retains the entity-range diagnostic and skin-zero fallback; all file offsets
// here are relative to paliashdr, and group intervals select the first value
// strictly greater than the wrapped target time, matching Mod_LoadAliasSkinGroup.
C(R_AliasSetupSkinSelect_asm486):
	.globl C(R_AliasSetupSkinSelect_asm486)
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	subl	$16,%esp

	// Locals: saved CW=-16, truncate CW=-18, quotient=-20,
	// group skin count=-24, group pointer=-28.
	movl	C(paliashdr),%esi
	movl	8(%esi),%edi
	addl	%esi,%edi			// maliasskindesc_t * at header->skindesc
	movl	8(%ebp),%eax
	leal	(%eax,%eax,2),%eax
	leal	(%edi,%eax,4),%edi	// 12-byte top-level skin descriptor stride
	cmpl	$0,0(%edi)			// ALIAS_SKIN_SINGLE == 0
	jne	.Lalias_setup_skin_group
	movl	%edi,%eax
	jmp	.Lalias_setup_skin_done

.Lalias_setup_skin_group:
	movl	8(%edi),%ebx
	addl	%esi,%ebx			// maliasskingroup_t *
	movl	%ebx,-28(%ebp)
	movl	0(%ebx),%eax
	movl	%eax,-24(%ebp)
	movl	4(%ebx),%edi
	addl	%esi,%edi			// float *intervals

	// fullskininterval = intervals[numskins-1].
	movl	-24(%ebp),%eax
	flds	-4(%edi,%eax,4)

	// Preserve the source expression order: double cl.time plus float
	// syncbase, truncation toward zero for the integer quotient, then the
	// interval subtraction. The focused fixture covers all x87 RC modes.
	flds	20(%ebp)
	faddl	12(%ebp)
	fld	%st(0)
	fdiv	%st(2),%st(0)
	fnstcw	-16(%ebp)
	movw	-16(%ebp),%dx
	orb	$0x0c,%dh
	movw	%dx,-18(%ebp)
	fldcw	-18(%ebp)
	fistpl	-20(%ebp)
	fldcw	-16(%ebp)
	fxch	%st(1)
	fimull	-20(%ebp)
	fsubrp	%st,%st(1)

	// Scan i in [0,numskins-2]; equality advances to the next skin.
	movl	-24(%ebp),%ebx
	decl	%ebx
	xorl	%edx,%edx
	testl	%ebx,%ebx
	jle	.Lalias_setup_skin_select
.Lalias_setup_skin_interval_loop:
	fcoms	(%edi,%edx,4)
	fnstsw	%ax
	testb	$0x01,%ah			// C0: targettime < intervals[i]
	jnz	.Lalias_setup_skin_select
	incl	%edx
	cmpl	%ebx,%edx
	jl	.Lalias_setup_skin_interval_loop
.Lalias_setup_skin_select:
	fstp	%st(0)
	movl	-28(%ebp),%eax
	leal	(%edx,%edx,2),%ecx	// 3*i for 12-byte skin descriptors
	leal	8(%eax,%ecx,4),%eax

.Lalias_setup_skin_done:
	addl	$16,%esp
	popl	%edi
	popl	%esi
	popl	%ebx
	popl	%ebp
	ret
#endif

#ifdef ASM486_ALIAS_PREPARE
	.extern C(r_apverts)
	.extern C(r_refdef)
	.extern C(R_AliasTransformFinalVert)
	.extern C(R_AliasTransformFinalVert_asm486)
	.extern C(R_AliasProjectFinalVert)
	.extern C(R_AliasProjectFinalVert_asm486)

	.section .rodata
	.p2align 2
.Lalias_prepare_z_clip_plane:
	.float 5.0

	.text
	.p2align 4,,15
	.set ALIAPV_PSTVERTS, -16
	.set ALIAPV_COUNT,    -20

// void R_AliasPreparePointsVertices_asm486(finalvert_t *fv, auxvert_t *av,
//        trivertx_t *pverts, stvert_t *pstverts, int numverts)
// Transform each clipped alias vertex, project vertices in front of the near
// plane, and accumulate the same screen-clip bits as R_AliasPreparePoints.
C(R_AliasPreparePointsVertices_asm486):
	.globl C(R_AliasPreparePointsVertices_asm486)
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	subl	$8,%esp

	movl	8(%ebp),%esi		// finalvert_t *fv
	movl	12(%ebp),%edi		// auxvert_t *av
	movl	16(%ebp),%ebx		// trivertx_t *pverts
	movl	20(%ebp),%eax		// stvert_t *pstverts
	movl	%eax,ALIAPV_PSTVERTS(%ebp)
	movl	24(%ebp),%eax		// numverts
	movl	%eax,ALIAPV_COUNT(%ebp)
	testl	%eax,%eax
	jle	.Lalias_prepare_vertices_done

.Lalias_prepare_vertices_loop:
	movl	ALIAPV_PSTVERTS(%ebp),%eax
	pushl	%eax
	pushl	%ebx
	pushl	%edi
	pushl	%esi
#ifdef ASM486_ALIAS_TRANSFORM_FINAL
	call	C(R_AliasTransformFinalVert_asm486)
#else
	call	C(R_AliasTransformFinalVert)
#endif
	addl	$16,%esp

	// C's '< 5' treats unordered values as false, so project those as well.
	flds	8(%edi)
	fcoms	.Lalias_prepare_z_clip_plane
	fnstsw	%ax
	sahf
	fstp	%st(0)
	jp	.Lalias_prepare_project
	jb	.Lalias_prepare_z_clipped

.Lalias_prepare_project:
	pushl	%edi
	pushl	%esi
#ifdef ASM486_ALIAS_PROJECT
	call	C(R_AliasProjectFinalVert_asm486)
#else
	call	C(R_AliasProjectFinalVert)
#endif
	addl	$8,%esp

	movl	fv_v+0(%esi),%eax
	cmpl	C(r_refdef)+rd_aliasvrect,%eax
	jl	.Lalias_prepare_left
.Lalias_prepare_left_done:
	movl	fv_v+4(%esi),%eax
	cmpl	C(r_refdef)+rd_aliasvrect+4,%eax
	jl	.Lalias_prepare_top
.Lalias_prepare_top_done:
	movl	fv_v+0(%esi),%eax
	cmpl	C(r_refdef)+rd_aliasvrectright,%eax
	jg	.Lalias_prepare_right
.Lalias_prepare_right_done:
	movl	fv_v+4(%esi),%eax
	cmpl	C(r_refdef)+rd_aliasvrectbottom,%eax
	jg	.Lalias_prepare_bottom
	jmp	.Lalias_prepare_vertices_next

.Lalias_prepare_left:
	orl	$0x0001,fv_flags(%esi)
	jmp	.Lalias_prepare_left_done
.Lalias_prepare_top:
	orl	$0x0002,fv_flags(%esi)
	jmp	.Lalias_prepare_top_done
.Lalias_prepare_right:
	orl	$0x0004,fv_flags(%esi)
	jmp	.Lalias_prepare_right_done
.Lalias_prepare_bottom:
	orl	$0x0008,fv_flags(%esi)
	jmp	.Lalias_prepare_vertices_next

.Lalias_prepare_z_clipped:
	orl	$0x0010,fv_flags(%esi)

.Lalias_prepare_vertices_next:
	addl	$fv_size,%esi
	addl	$12,%edi			// sizeof(auxvert_t)
	addl	$tv_size,%ebx
	addl	$stv_size,ALIAPV_PSTVERTS(%ebp)
	decl	ALIAPV_COUNT(%ebp)
	jne	.Lalias_prepare_vertices_loop

.Lalias_prepare_vertices_done:
	movl	%ebx,C(r_apverts)
	leal	-12(%ebp),%esp
	popl	%edi
	popl	%esi
	popl	%ebx
	popl	%ebp
	ret
#endif

#ifdef ASM486_ALIAS_CLIP
	.extern C(r_refdef)

	.text
	.p2align 4,,15
	.set AC_FLAG,       -16
	.set AC_COUNT,      -20
	.set AC_I,          -24
	.set AC_J,          -28
	.set AC_K,          -32
	.set AC_OLDFLAGS,   -36
	.set AC_FLAGS,      -40
	.set AC_CURPTR,     -44
	.set AC_PREVPTR,    -48
	.set AC_OUTPTR,     -52
	.set AC_CLIP,       -56

// int R_AliasClip_asm486(finalvert_t *in, finalvert_t *out, int flag,
//                        int count, clipfn_t clip)
// One Sutherland-Hodgman pass over an alias polygon. The clip callback owns
// edge interpolation; this routine owns edge classification, output order,
// viewport flag reconstruction, and complete finalvert_t copies.
C(R_AliasClip_asm486):
	.globl C(R_AliasClip_asm486)
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	subl	$48,%esp

	movl	8(%ebp),%esi		// input polygon
	movl	12(%ebp),%edi		// output polygon
	movl	16(%ebp),%eax		// active clip bit
	movl	%eax,AC_FLAG(%ebp)
	movl	20(%ebp),%eax		// input vertex count
	movl	%eax,AC_COUNT(%ebp)
	movl	24(%ebp),%eax		// edge interpolation callback
	movl	%eax,AC_CLIP(%ebp)
	movl	$0,AC_I(%ebp)
	movl	$0,AC_K(%ebp)
	cmpl	$0,AC_COUNT(%ebp)
	jle	.Lalias_clip_return
	movl	AC_COUNT(%ebp),%eax
	decl	%eax
	movl	%eax,AC_J(%ebp)

.Lalias_clip_loop:
	movl	AC_I(%ebp),%eax
	cmpl	AC_COUNT(%ebp),%eax
	jge	.Lalias_clip_return

	// Cache pointers to the previous and current input vertices.
	movl	AC_I(%ebp),%eax
	shll	$5,%eax
	leal	(%esi,%eax),%edx
	movl	%edx,AC_CURPTR(%ebp)
	movl	fv_flags(%edx),%eax
	andl	AC_FLAG(%ebp),%eax
	movl	%eax,AC_FLAGS(%ebp)

	movl	AC_J(%ebp),%eax
	shll	$5,%eax
	leal	(%esi,%eax),%edx
	movl	%edx,AC_PREVPTR(%ebp)
	movl	fv_flags(%edx),%eax
	andl	AC_FLAG(%ebp),%eax
	movl	%eax,AC_OLDFLAGS(%ebp)

	// Both endpoints outside this plane contribute no output.
	cmpl	$0,AC_FLAGS(%ebp)
	je	.Lalias_clip_check_crossing
	cmpl	$0,AC_OLDFLAGS(%ebp)
	jne	.Lalias_clip_next

.Lalias_clip_check_crossing:
	movl	AC_FLAGS(%ebp),%eax
	xorl	AC_OLDFLAGS(%ebp),%eax
	je	.Lalias_clip_inside_copy

	// A crossing emits an interpolated point before any inside endpoint.
	movl	AC_K(%ebp),%eax
	shll	$5,%eax
	leal	(%edi,%eax),%edx
	movl	%edx,AC_OUTPTR(%ebp)
	pushl	%edx
	pushl	AC_CURPTR(%ebp)
	pushl	AC_PREVPTR(%ebp)
	call	*AC_CLIP(%ebp)
	addl	$12,%esp

	// R_AliasClip recomputes only XY clip bits for a generated point.
	movl	AC_OUTPTR(%ebp),%edx
	movl	$0,fv_flags(%edx)
	movl	fv_v+0(%edx),%eax
	cmpl	C(r_refdef)+rd_aliasvrect,%eax
	jge	.Lalias_clip_left_done
	orl	$0x0001,fv_flags(%edx)
.Lalias_clip_left_done:
	movl	fv_v+4(%edx),%eax
	cmpl	C(r_refdef)+rd_aliasvrect+4,%eax
	jge	.Lalias_clip_top_done
	orl	$0x0002,fv_flags(%edx)
.Lalias_clip_top_done:
	movl	fv_v+0(%edx),%eax
	cmpl	C(r_refdef)+rd_aliasvrectright,%eax
	jle	.Lalias_clip_right_done
	orl	$0x0004,fv_flags(%edx)
.Lalias_clip_right_done:
	movl	fv_v+4(%edx),%eax
	cmpl	C(r_refdef)+rd_aliasvrectbottom,%eax
	jle	.Lalias_clip_bottom_done
	orl	$0x0008,fv_flags(%edx)
.Lalias_clip_bottom_done:
	incl	AC_K(%ebp)

.Lalias_clip_inside_copy:
	cmpl	$0,AC_FLAGS(%ebp)
	jne	.Lalias_clip_next

	// Copy the complete 32-byte finalvert_t, including its reserved field.
	pushl	%esi
	pushl	%edi
	movl	AC_CURPTR(%ebp),%esi
	movl	AC_K(%ebp),%eax
	shll	$5,%eax
	leal	(%edi,%eax),%edi
	movl	$8,%ecx
	cld
	rep
	movsl
	popl	%edi
	popl	%esi
	incl	AC_K(%ebp)

.Lalias_clip_next:
	movl	AC_I(%ebp),%eax
	movl	%eax,AC_J(%ebp)
	incl	AC_I(%ebp)
	jmp	.Lalias_clip_loop

.Lalias_clip_return:
	movl	AC_K(%ebp),%eax
	leal	-12(%ebp),%esp
	popl	%edi
	popl	%esi
	popl	%ebx
	popl	%ebp
	ret
#endif

#ifdef ASM486_ALIAS_CLIP
	.extern C(R_AliasClip_fv)
	.extern C(R_AliasClip_av)
	.extern C(pfinalverts)
	.extern C(pauxverts)
	.extern C(r_affinetridesc)
#ifdef ASM486_ALIAS_CLIP_Z
	#ifdef PROFILE486
	.extern C(R_Alias_clip_z_bench)
	#else
	.extern C(R_Alias_clip_z_asm486)
	#endif
#else
	.extern C(R_Alias_clip_z_C)
#endif
	.extern C(R_Alias_clip_left)
	.extern C(R_Alias_clip_right)
	.extern C(R_Alias_clip_bottom)
	.extern C(R_Alias_clip_top)
	.extern C(R_AliasClip_asm486)
	.extern C(D_PolysetDraw)
	.extern C(r_refdef)

	.text
	.p2align 4,,15
	.set ACT_PTRI,          -16
	.set ACT_FACESFRONT,    -20
	.set ACT_CLIPFLAGS,     -24
	.set ACT_K,             -28
	.set ACT_PINGPONG,      -32
	.set ACT_I,             -36
	.set ACT_PFINAL,        -40
	.set ACT_PAUX,          -44
	.set ACT_MTRI,          -64
	.set ACT_VERTEX_BYTES,  32
	.set ACT_BUFFER_BYTES,  256
	.set ACT_AUX_BYTES,     12
	.set ACZ_START,         -16
	.set ACZ_END,           -20
	.set ACZ_PAVSTART,      -24
	.set ACZ_PAVEND,        -28
	.set ACZ_AVOUT,         -40
	.set ACZ_CW,            -42
	.set ACZ_CW_NEW,        -44
	.set ACZ_TEMP,          -48

// void R_AliasClipTriangle_asm486(mtriangle_t *ptri)
// Copy the input triangle and auxiliary vertices, preserve seam correction,
// run the Z and viewport clip passes in the C order, clamp the final vertices,
// then replay the clipped fan through D_PolysetDraw.
C(R_AliasClipTriangle_asm486):
	.globl C(R_AliasClipTriangle_asm486)
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	subl	$64,%esp

	movl	8(%ebp),%ebx
	movl	%ebx,ACT_PTRI(%ebp)
	movl	mtri_facesfront(%ebx),%eax
	movl	%eax,ACT_FACESFRONT(%ebp)
	movl	%eax,ACT_MTRI+mtri_facesfront(%ebp)
	movl	C(pfinalverts),%eax
	movl	%eax,ACT_PFINAL(%ebp)
	movl	C(pauxverts),%eax
	movl	%eax,ACT_PAUX(%ebp)

	// Copy the three full finalvert_t records. Back-facing triangles apply
	// the seam fixup only to vertices carrying ALIAS_ONSEAM.
	movl	$0,ACT_I(%ebp)
.Lalias_clip_triangle_copy:
	movl	ACT_I(%ebp),%eax
	cmpl	$3,%eax
	jge	.Lalias_clip_triangle_copy_done
	movl	ACT_PTRI(%ebp),%ebx
	movl	mtri_vertindex(%ebx,%eax,4),%edx
	movl	ACT_PFINAL(%ebp),%esi
	shll	$5,%edx
	addl	%edx,%esi
	leal	C(R_AliasClip_fv),%edi
	movl	ACT_I(%ebp),%ecx
	shll	$5,%ecx
	addl	%ecx,%edi
	movl	$8,%ecx
	cld
	rep
	movsl

	cmpl	$0,ACT_FACESFRONT(%ebp)
	jne	.Lalias_clip_triangle_copy_next
	movl	ACT_I(%ebp),%eax
	shll	$5,%eax
	leal	C(R_AliasClip_fv),%edi
	addl	%eax,%edi
	movl	fv_flags(%edi),%eax
	testl	$0x0020,%eax
	je	.Lalias_clip_triangle_copy_next
	movl	C(r_affinetridesc)+atd_seamfixupX16,%eax
	addl	%eax,fv_v+8(%edi)

.Lalias_clip_triangle_copy_next:
	incl	ACT_I(%ebp)
	jmp	.Lalias_clip_triangle_copy

.Lalias_clip_triangle_copy_done:
	leal	C(R_AliasClip_fv),%eax
	movl	fv_flags+0(%eax),%edx
	orl	fv_flags+ACT_VERTEX_BYTES(%eax),%edx
	orl	fv_flags+(2*ACT_VERTEX_BYTES)(%eax),%edx
	movl	%edx,ACT_CLIPFLAGS(%ebp)
	testl	$0x0010,%edx
	je	.Lalias_clip_triangle_no_z

	// R_Alias_clip_z indexes R_AliasClip_av relative to fv[0][0], so the
	// auxiliary records must use the same three original vertex indices.
	movl	$0,ACT_I(%ebp)
.Lalias_clip_triangle_copy_aux:
	movl	ACT_I(%ebp),%eax
	cmpl	$3,%eax
	jge	.Lalias_clip_triangle_copy_aux_done
	movl	ACT_PTRI(%ebp),%ebx
	movl	mtri_vertindex(%ebx,%eax,4),%edx
	imull	$ACT_AUX_BYTES,%edx,%edx
	movl	ACT_PAUX(%ebp),%esi
	addl	%edx,%esi
	leal	C(R_AliasClip_av),%edi
	movl	ACT_I(%ebp),%ecx
	imull	$ACT_AUX_BYTES,%ecx,%ecx
	addl	%ecx,%edi
	movl	$3,%ecx
	cld
	rep
	movsl
	incl	ACT_I(%ebp)
	jmp	.Lalias_clip_triangle_copy_aux

.Lalias_clip_triangle_copy_aux_done:
	leal	C(R_AliasClip_fv),%eax
	leal	ACT_BUFFER_BYTES(%eax),%edx
#ifdef ASM486_ALIAS_CLIP_Z
	#ifdef PROFILE486
	pushl	$C(R_Alias_clip_z_bench)
	#else
	pushl	$C(R_Alias_clip_z_asm486)
	#endif
#else
	pushl	$C(R_Alias_clip_z_C)
#endif
	pushl	$3
	pushl	$0x0010
	pushl	%edx
	pushl	%eax
	call	C(R_AliasClip_asm486)
	addl	$20,%esp
	movl	%eax,ACT_K(%ebp)
	testl	%eax,%eax
	je	.Lalias_clip_triangle_done
	movl	$1,ACT_PINGPONG(%ebp)
	leal	C(R_AliasClip_fv),%edx
	addl	$ACT_BUFFER_BYTES,%edx
	movl	fv_flags+0(%edx),%eax
	orl	fv_flags+ACT_VERTEX_BYTES(%edx),%eax
	orl	fv_flags+(2*ACT_VERTEX_BYTES)(%edx),%eax
	movl	%eax,ACT_CLIPFLAGS(%ebp)
	jmp	.Lalias_clip_triangle_clip_left

.Lalias_clip_triangle_no_z:
	movl	$0,ACT_PINGPONG(%ebp)
	movl	$3,ACT_K(%ebp)

.Lalias_clip_triangle_clip_left:
	movl	ACT_CLIPFLAGS(%ebp),%eax
	testl	$0x0001,%eax
	je	.Lalias_clip_triangle_clip_right
	movl	ACT_PINGPONG(%ebp),%eax
	movl	%eax,%ecx
	shll	$8,%eax
	xorl	$1,%ecx
	shll	$8,%ecx
	leal	C(R_AliasClip_fv),%esi
	addl	%eax,%esi
	leal	C(R_AliasClip_fv),%edi
	addl	%ecx,%edi
	pushl	$C(R_Alias_clip_left)
	pushl	ACT_K(%ebp)
	pushl	$0x0001
	pushl	%edi
	pushl	%esi
	call	C(R_AliasClip_asm486)
	addl	$20,%esp
	movl	%eax,ACT_K(%ebp)
	testl	%eax,%eax
	je	.Lalias_clip_triangle_done
	xorl	$1,ACT_PINGPONG(%ebp)

.Lalias_clip_triangle_clip_right:
	movl	ACT_CLIPFLAGS(%ebp),%eax
	testl	$0x0004,%eax
	je	.Lalias_clip_triangle_clip_bottom
	movl	ACT_PINGPONG(%ebp),%eax
	movl	%eax,%ecx
	shll	$8,%eax
	xorl	$1,%ecx
	shll	$8,%ecx
	leal	C(R_AliasClip_fv),%esi
	addl	%eax,%esi
	leal	C(R_AliasClip_fv),%edi
	addl	%ecx,%edi
	pushl	$C(R_Alias_clip_right)
	pushl	ACT_K(%ebp)
	pushl	$0x0004
	pushl	%edi
	pushl	%esi
	call	C(R_AliasClip_asm486)
	addl	$20,%esp
	movl	%eax,ACT_K(%ebp)
	testl	%eax,%eax
	je	.Lalias_clip_triangle_done
	xorl	$1,ACT_PINGPONG(%ebp)

.Lalias_clip_triangle_clip_bottom:
	movl	ACT_CLIPFLAGS(%ebp),%eax
	testl	$0x0008,%eax
	je	.Lalias_clip_triangle_clip_top
	movl	ACT_PINGPONG(%ebp),%eax
	movl	%eax,%ecx
	shll	$8,%eax
	xorl	$1,%ecx
	shll	$8,%ecx
	leal	C(R_AliasClip_fv),%esi
	addl	%eax,%esi
	leal	C(R_AliasClip_fv),%edi
	addl	%ecx,%edi
	pushl	$C(R_Alias_clip_bottom)
	pushl	ACT_K(%ebp)
	pushl	$0x0008
	pushl	%edi
	pushl	%esi
	call	C(R_AliasClip_asm486)
	addl	$20,%esp
	movl	%eax,ACT_K(%ebp)
	testl	%eax,%eax
	je	.Lalias_clip_triangle_done
	xorl	$1,ACT_PINGPONG(%ebp)

.Lalias_clip_triangle_clip_top:
	movl	ACT_CLIPFLAGS(%ebp),%eax
	testl	$0x0002,%eax
	je	.Lalias_clip_triangle_clamp_start
	movl	ACT_PINGPONG(%ebp),%eax
	movl	%eax,%ecx
	shll	$8,%eax
	xorl	$1,%ecx
	shll	$8,%ecx
	leal	C(R_AliasClip_fv),%esi
	addl	%eax,%esi
	leal	C(R_AliasClip_fv),%edi
	addl	%ecx,%edi
	pushl	$C(R_Alias_clip_top)
	pushl	ACT_K(%ebp)
	pushl	$0x0002
	pushl	%edi
	pushl	%esi
	call	C(R_AliasClip_asm486)
	addl	$20,%esp
	movl	%eax,ACT_K(%ebp)
	testl	%eax,%eax
	je	.Lalias_clip_triangle_done
	xorl	$1,ACT_PINGPONG(%ebp)

.Lalias_clip_triangle_clamp_start:
	movl	$0,ACT_I(%ebp)
.Lalias_clip_triangle_clamp:
	movl	ACT_I(%ebp),%eax
	cmpl	ACT_K(%ebp),%eax
	jge	.Lalias_clip_triangle_draw_setup
	movl	ACT_PINGPONG(%ebp),%eax
	shll	$8,%eax
	leal	C(R_AliasClip_fv),%edi
	addl	%eax,%edi
	movl	ACT_I(%ebp),%eax
	shll	$5,%eax
	addl	%eax,%edi

	movl	fv_v+0(%edi),%eax
	movl	C(r_refdef)+rd_aliasvrect,%edx
	cmpl	%edx,%eax
	jge	.Lalias_clip_triangle_clamp_x_max
	movl	%edx,fv_v+0(%edi)
	jmp	.Lalias_clip_triangle_clamp_y
.Lalias_clip_triangle_clamp_x_max:
	movl	C(r_refdef)+rd_aliasvrectright,%edx
	cmpl	%edx,%eax
	jle	.Lalias_clip_triangle_clamp_y
	movl	%edx,fv_v+0(%edi)

.Lalias_clip_triangle_clamp_y:
	movl	fv_v+4(%edi),%eax
	movl	C(r_refdef)+rd_aliasvrect+4,%edx
	cmpl	%edx,%eax
	jge	.Lalias_clip_triangle_clamp_y_max
	movl	%edx,fv_v+4(%edi)
	jmp	.Lalias_clip_triangle_clamp_flags
.Lalias_clip_triangle_clamp_y_max:
	movl	C(r_refdef)+rd_aliasvrectbottom,%edx
	cmpl	%edx,%eax
	jle	.Lalias_clip_triangle_clamp_flags
	movl	%edx,fv_v+4(%edi)

.Lalias_clip_triangle_clamp_flags:
	movl	$0,fv_flags(%edi)
	incl	ACT_I(%ebp)
	jmp	.Lalias_clip_triangle_clamp

.Lalias_clip_triangle_draw_setup:
	movl	ACT_FACESFRONT(%ebp),%eax
	movl	%eax,ACT_MTRI+mtri_facesfront(%ebp)
	leal	ACT_MTRI(%ebp),%eax
	movl	%eax,C(r_affinetridesc)+atd_ptriangles
	movl	ACT_PINGPONG(%ebp),%eax
	shll	$8,%eax
	leal	C(R_AliasClip_fv),%edx
	addl	%eax,%edx
	movl	%edx,C(r_affinetridesc)+atd_pfinalverts
	movl	$0,ACT_MTRI+mtri_vertindex(%ebp)
	movl	$1,ACT_I(%ebp)

.Lalias_clip_triangle_draw:
	movl	ACT_K(%ebp),%eax
	decl	%eax
	cmpl	%eax,ACT_I(%ebp)
	jge	.Lalias_clip_triangle_done
	movl	ACT_I(%ebp),%eax
	movl	%eax,ACT_MTRI+mtri_vertindex+4(%ebp)
	incl	%eax
	movl	%eax,ACT_MTRI+mtri_vertindex+8(%ebp)
	call	C(D_PolysetDraw)
	incl	ACT_I(%ebp)
	jmp	.Lalias_clip_triangle_draw

.Lalias_clip_triangle_done:
	leal	-12(%ebp),%esp
	popl	%edi
	popl	%esi
	popl	%ebx
	popl	%ebp
	ret

#ifdef ASM486_ALIAS_CLIP_Z
	.section .rodata
	.p2align 2
.Lalias_clip_z_plane:
	.float 5.0
	.text
	.p2align 4,,15
#ifdef ASM486_ALIAS_PROJECT
	.extern C(R_AliasProjectFinalVert_asm486)
#else
	.extern C(R_AliasProjectFinalVert)
#endif

// void R_Alias_clip_z_asm486(finalvert_t *pfv0, finalvert_t *pfv1,
//                            finalvert_t *out)
// Intersect one alias edge with the Z plane. Keep the scale in x87 extended
// precision across both auxiliary-coordinate interpolation and integer
// interpolation, use 32-bit integer operands, and truncate like the C cast.
C(R_Alias_clip_z_asm486):
	.globl C(R_Alias_clip_z_asm486)
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	subl	$36,%esp

	movl	8(%ebp),%esi		// pfv0
	movl	12(%ebp),%edi		// pfv1
	movl	16(%ebp),%ebx		// output vertex
	movl	fv_v+4(%esi),%eax
	cmpl	fv_v+4(%edi),%eax
	jge	.Lalias_clip_z_forward
	movl	%edi,ACZ_START(%ebp)
	movl	%esi,ACZ_END(%ebp)
	jmp	.Lalias_clip_z_selected
.Lalias_clip_z_forward:
	movl	%esi,ACZ_START(%ebp)
	movl	%edi,ACZ_END(%ebp)

.Lalias_clip_z_selected:
	// Map the selected final vertices to their auxiliary coordinates.
	movl	ACZ_START(%ebp),%eax
	subl	$C(R_AliasClip_fv),%eax
	sarl	$5,%eax
	imull	$ACT_AUX_BYTES,%eax,%eax
	leal	C(R_AliasClip_av),%edx
	addl	%eax,%edx
	movl	%edx,ACZ_PAVSTART(%ebp)
	movl	ACZ_END(%ebp),%eax
	subl	$C(R_AliasClip_fv),%eax
	sarl	$5,%eax
	imull	$ACT_AUX_BYTES,%eax,%eax
	leal	C(R_AliasClip_av),%edx
	addl	%eax,%edx
	movl	%edx,ACZ_PAVEND(%ebp)

	// scale = (5 - start.z) / (end.z - start.z), retaining the x87
	// extended intermediate used by the C build.
	movl	ACZ_PAVSTART(%ebp),%eax
	flds	.Lalias_clip_z_plane
	fsubs	8(%eax)
	movl	ACZ_PAVEND(%ebp),%edx
	flds	8(%edx)
	fsubs	8(%eax)
	fdivrp	%st,%st(1)

	// avout.x = start.x + (end.x - start.x) * scale.
	movl	ACZ_PAVSTART(%ebp),%eax
	flds	0(%eax)
	movl	ACZ_PAVEND(%ebp),%edx
	flds	0(%edx)
	fsubp	%st,%st(1)
	fmul	%st(1),%st
	movl	ACZ_PAVSTART(%ebp),%eax
	flds	0(%eax)
	faddp	%st,%st(1)
	fstps	ACZ_AVOUT+0(%ebp)

	// avout.y uses the same extended scale and operation order.
	movl	ACZ_PAVSTART(%ebp),%eax
	flds	4(%eax)
	movl	ACZ_PAVEND(%ebp),%edx
	flds	4(%edx)
	fsubp	%st,%st(1)
	fmul	%st(1),%st
	movl	ACZ_PAVSTART(%ebp),%eax
	flds	4(%eax)
	faddp	%st,%st(1)
	fstps	ACZ_AVOUT+4(%ebp)
	movl	$0x40a00000,ACZ_AVOUT+8(%ebp)	// 5.0f

	// C converts each interpolated integer coordinate by truncating toward
	// zero, independent of the caller's current x87 rounding mode.
	fnstcw	ACZ_CW(%ebp)
	movw	ACZ_CW(%ebp),%dx
	orw	$0x0c00,%dx
	movw	%dx,ACZ_CW_NEW(%ebp)

	// v[2]
	movl	ACZ_START(%ebp),%eax
	movl	fv_v+8(%eax),%edx
	movl	ACZ_END(%ebp),%eax
	movl	fv_v+8(%eax),%ecx
	subl	%edx,%ecx
	movl	%ecx,ACZ_TEMP(%ebp)
	fld	%st(0)
	fimull	ACZ_TEMP(%ebp)
	movl	%edx,ACZ_TEMP(%ebp)
	fiaddl	ACZ_TEMP(%ebp)
	fldcw	ACZ_CW_NEW(%ebp)
	fistpl	fv_v+8(%ebx)
	fldcw	ACZ_CW(%ebp)

	// v[3]
	movl	ACZ_START(%ebp),%eax
	movl	fv_v+12(%eax),%edx
	movl	ACZ_END(%ebp),%eax
	movl	fv_v+12(%eax),%ecx
	subl	%edx,%ecx
	movl	%ecx,ACZ_TEMP(%ebp)
	fld	%st(0)
	fimull	ACZ_TEMP(%ebp)
	movl	%edx,ACZ_TEMP(%ebp)
	fiaddl	ACZ_TEMP(%ebp)
	fldcw	ACZ_CW_NEW(%ebp)
	fistpl	fv_v+12(%ebx)
	fldcw	ACZ_CW(%ebp)

	// v[4]
	movl	ACZ_START(%ebp),%eax
	movl	fv_v+16(%eax),%edx
	movl	ACZ_END(%ebp),%eax
	movl	fv_v+16(%eax),%ecx
	subl	%edx,%ecx
	movl	%ecx,ACZ_TEMP(%ebp)
	fld	%st(0)
	fimull	ACZ_TEMP(%ebp)
	movl	%edx,ACZ_TEMP(%ebp)
	fiaddl	ACZ_TEMP(%ebp)
	fldcw	ACZ_CW_NEW(%ebp)
	fistpl	fv_v+16(%ebx)
	fldcw	ACZ_CW(%ebp)
	fstp	%st(0)			// discard extended scale

	// R_AliasProjectFinalVertDispatch uses the selected project routine.
	leal	ACZ_AVOUT(%ebp),%eax
	pushl	%eax
	pushl	%ebx
#ifdef ASM486_ALIAS_PROJECT
	call	C(R_AliasProjectFinalVert_asm486)
#else
	call	C(R_AliasProjectFinalVert)
#endif
	addl	$8,%esp

	movl	fv_v+0(%ebx),%eax
	cmpl	C(r_refdef)+rd_aliasvrect,%eax
	jge	.Lalias_clip_z_left_done
	orl	$0x0001,fv_flags(%ebx)
.Lalias_clip_z_left_done:
	movl	fv_v+4(%ebx),%eax
	cmpl	C(r_refdef)+rd_aliasvrect+4,%eax
	jge	.Lalias_clip_z_top_done
	orl	$0x0002,fv_flags(%ebx)
.Lalias_clip_z_top_done:
	movl	fv_v+0(%ebx),%eax
	cmpl	C(r_refdef)+rd_aliasvrectright,%eax
	jle	.Lalias_clip_z_right_done
	orl	$0x0004,fv_flags(%ebx)
.Lalias_clip_z_right_done:
	movl	fv_v+4(%ebx),%eax
	cmpl	C(r_refdef)+rd_aliasvrectbottom,%eax
	jle	.Lalias_clip_z_bottom_done
	orl	$0x0008,fv_flags(%ebx)
.Lalias_clip_z_bottom_done:

	leal	-12(%ebp),%esp
	popl	%edi
	popl	%esi
	popl	%ebx
	popl	%ebp
	ret
#endif
#endif /* ASM486_ALIAS_CLIP_Z */

#ifdef ASM486_ZPOINT
	.p2align 4,,15
// void D_DrawZPoint(void)
// Draw one z-buffered pixel using the descriptor and video globals. Preserve
// the C conversion's truncate-toward-zero rule by changing only the x87
// rounding-control bits around FISTPL, then restoring the caller's control word.
C(D_DrawZPoint):
	.globl C(D_DrawZPoint)
	pushl	%ebp
	movl	%esp,%ebp
	subl	$24,%esp
	pushl	%ebx
	pushl	%esi
	pushl	%edi

	movl	C(r_zpointdesc)+4,%eax	// v
	movl	%eax,-24(%ebp)
	movl	C(r_zpointdesc),%ecx	// u
	movl	%ecx,-20(%ebp)

	// Pixel index is d_scantable[v] + u bytes.
	movl	-24(%ebp),%eax
	movl	C(d_scantable)(,%eax,4),%eax
	addl	-20(%ebp),%eax
	addl	C(d_viewbuffer),%eax
	movl	%eax,-16(%ebp)

	fnstcw	-8(%ebp)
	movw	-8(%ebp),%dx
	orw	$0x0c00,%dx
	movw	%dx,-10(%ebp)
	fldcw	-10(%ebp)
	flds	C(r_zpointdesc)+8
	fmuls	Lzpoint_scale
	fistpl	-4(%ebp)
	fldcw	-8(%ebp)

	// zspantable[v] is the precomputed short* for the start of this row.
	movl	-24(%ebp),%eax
	movl	C(zspantable)(,%eax,4),%edi
	movl	-20(%ebp),%ecx
	leal	(%edi,%ecx,2),%edi
	movswl	(%edi),%eax
	cmpl	-4(%ebp),%eax
	jg	.Lzpoint_done
	movl	-4(%ebp),%eax
	movw	%ax,(%edi)
	movl	-16(%ebp),%edi
	movl	C(r_zpointdesc)+12,%eax
	movb	%al,(%edi)

.Lzpoint_done:
	popl	%edi
	popl	%esi
	popl	%ebx
	movl	%ebp,%esp
	popl	%ebp
	ret
#endif

#ifdef ASM486_SOLID_SURFACE
	.p2align 4,,15
// void D_DrawSolidSurface(surf_t *surf, int color)
// Fill each span with the low byte of color. The C small-span path writes one
// pixel even for a non-positive count; retain that edge behavior as well.
C(D_DrawSolidSurface):
	.globl C(D_DrawSolidSurface)
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	subl	$8,%esp		// next span and u2 locals

	movl	8(%ebp),%eax
	movl	8(%eax),%esi	// surf_t.spans
	movl	12(%ebp),%ebx
	movl	%ebx,%eax
	shll	$24,%ebx
	movl	%eax,%edx
	shll	$16,%edx
	orl	%edx,%ebx
	movl	%eax,%edx
	shll	$8,%edx
	orl	%edx,%ebx
	orl	%eax,%ebx

.Lsolid_surface_span:
	testl	%esi,%esi
	jz	.Lsolid_surface_done
#ifdef PROFILE486
	cmpl	$0,C(bench486_profile_frame_active)
	je	.Lsolid_surface_unprofiled
	incl	C(bench486_solid_span_count)
.Lsolid_surface_unprofiled:
#endif


	movl	%esi,%eax
	movl	espan_t_pnext(%eax),%edx
	movl	%edx,-16(%ebp)
	movl	espan_t_count(%eax),%ecx
	movl	espan_t_v(%eax),%eax
	movl	C(viewspantable)(,%eax,4),%edi
	movl	espan_t_u(%esi),%eax
	addl	%eax,%edi
	cmpl	$16,%ecx
	jge	.Lsolid_surface_large_span
	leal	-1(%eax,%ecx),%edx	// u2 = u + count - 1
	movl	%edx,-20(%ebp)
	subl	%eax,%edx
	cmpl	$8,%edx
	movl	-20(%ebp),%edx
	movb	%bl,(%edi)
	jge	.Lsolid_surface_alignment_path
	incl	%eax
	incl	%edi
.Lsolid_surface_short_tail:
	cmpl	%edx,%eax
	jg	.Lsolid_surface_next_span
	movb	%bl,(%edi)
	incl	%eax
	incl	%edi
	jmp	.Lsolid_surface_short_tail

.Lsolid_surface_alignment_path:
	incl	%eax
	incl	%edi
.Lsolid_surface_align:
	testl	$3,%eax
	jz	.Lsolid_surface_aligned
	movb	%bl,(%edi)
	incl	%eax
	incl	%edi
	jmp	.Lsolid_surface_align
.Lsolid_surface_aligned:
	subl	$4,%edx
.Lsolid_surface_words:
	cmpl	%edx,%eax
	jg	.Lsolid_surface_word_tail_start
	movl	%ebx,(%edi)
	addl	$4,%eax
	addl	$4,%edi
	jmp	.Lsolid_surface_words
.Lsolid_surface_word_tail_start:
	addl	$4,%edx
.Lsolid_surface_word_tail:
	cmpl	%edx,%eax
	jg	.Lsolid_surface_next_span
	movb	%bl,(%edi)
	incl	%eax
	incl	%edi
	jmp	.Lsolid_surface_word_tail

.Lsolid_surface_large_span:
	movl	%ebx,%eax
	cld
	rep stosb

.Lsolid_surface_next_span:
	movl	-16(%ebp),%esi
	jmp	.Lsolid_surface_span

.Lsolid_surface_done:
	leal	-12(%ebp),%esp
	popl	%edi
	popl	%esi
	popl	%ebx
	movl	%ebp,%esp
	popl	%ebp
	ret
#endif

#ifdef ASM486_SURFACE_DRAW

.set RDS_SURF,       -4
.set RDS_TEXTURE,    -8
.set RDS_MIP,       -12
.set RDS_TEXWIDTH,  -16
.set RDS_TMAX,      -20
.set RDS_BASEPTR,   -24
.set RDS_SOFFSET,   -28
.set RDS_SMAX,      -32
.set RDS_BLOCKSIZE, -36
.set RDS_HBLOCKS,   -40
.set RDS_DEST,      -44
.set RDS_SMASK,     -48
.set RDS_DRAWER,    -52
.set RDS_LIGHTPTR,  -56
.set RDS_STEPBACK,  -60
.set RDS_COUNT,     -64

.macro RDS_PREPARE_BLOCK
	movl	RDS_LIGHTPTR(%ebp),%eax
	movl	%eax,C(r_lightptr)
	addl	$4,RDS_LIGHTPTR(%ebp)
	movl	RDS_DEST(%ebp),%eax
	movl	%eax,C(prowdestbase)
	addl	RDS_BLOCKSIZE(%ebp),%eax
	movl	%eax,RDS_DEST(%ebp)
	movl	RDS_BASEPTR(%ebp),%eax
	addl	RDS_SOFFSET(%ebp),%eax
	movl	%eax,C(pbasesource)
.endm

.macro RDS_ADVANCE_POWER
	movl	RDS_SOFFSET(%ebp),%eax
	addl	RDS_BLOCKSIZE(%ebp),%eax
	andl	RDS_SMASK(%ebp),%eax
	movl	%eax,RDS_SOFFSET(%ebp)
.endm

.macro RDS_ADVANCE_NONPOWER
	movl	RDS_SOFFSET(%ebp),%eax
	addl	RDS_BLOCKSIZE(%ebp),%eax
	cmpl	RDS_SMAX(%ebp),%eax
	jl	9f
	xorl	%eax,%eax
9:
	movl	%eax,RDS_SOFFSET(%ebp)
.endm

	.p2align 4,,15
// void R_DrawSurface(void)
// Build block lighting, prepare wrapped texture addresses, and draw every
// horizontal block through the existing i486 mip drawers.
C(R_DrawSurface):
	.globl C(R_DrawSurface)
	pushl	%ebp
	movl	%esp,%ebp
	subl	$64,%esp
	pushl	%ebx
	pushl	%esi
	pushl	%edi

#ifdef PROFILE486
	call	C(R_DrawSurfaceProfileBegin_asm486_C)
#endif
	call	C(R_BuildLightMap)
#ifdef PROFILE486
	call	C(R_DrawSurfaceProfileAfterLightmap_asm486_C)
#endif

	movl	C(r_drawsurf)+sd_drawsurf_surf,%eax
	movl	%eax,RDS_SURF(%ebp)
	movl	C(r_drawsurf)+sd_drawsurf_texture,%edx
	movl	%edx,RDS_TEXTURE(%ebp)
	movl	C(r_drawsurf)+sd_drawsurf_surfmip,%ecx
	movl	%ecx,RDS_MIP(%ebp)

	movl	C(r_drawsurf)+sd_drawsurf_rowbytes,%eax
	movl	%eax,C(surfrowbytes)

	movl	16(%edx),%eax		// mip width
	movl	20(%edx),%ebx		// mip height
	shrl	%cl,%eax
	shrl	%cl,%ebx
	movl	%eax,RDS_TEXWIDTH(%ebp)
	movl	%ebx,RDS_TMAX(%ebp)

	movl	$16,%edx
	shrl	%cl,%edx
	movl	%edx,RDS_BLOCKSIZE(%ebp)
	movl	%edx,C(blocksize)

	movl	$4,%eax
	subl	%ecx,%eax
	movl	%eax,C(blockdivshift)
	movl	$1,%edx
	movb	%al,%cl
	shll	%cl,%edx
	decl	%edx
	movl	%edx,C(blockdivmask)

	movl	RDS_SURF(%ebp),%esi
	movswl	sd_surface_extents(%esi),%eax
	sarl	$4,%eax
	incl	%eax
	movl	%eax,C(r_lightwidth)

	movl	C(r_drawsurf)+sd_drawsurf_surfwidth,%eax
	movl	C(blockdivshift),%ecx
	sarl	%cl,%eax
	movl	%eax,C(r_numhblocks)
	movl	C(r_drawsurf)+sd_drawsurf_surfheight,%eax
	sarl	%cl,%eax
	movl	%eax,C(r_numvblocks)

#ifdef PROFILE486
	call	C(R_DrawSurfaceProfileCountBlocks_asm486_C)
#endif

	movl	RDS_TEXTURE(%ebp),%edx
	movl	RDS_MIP(%ebp),%ecx
	movl	sd_texture_offsets(%edx,%ecx,4),%eax
	addl	%edx,%eax
	movl	%eax,C(r_source)

	movl	RDS_TEXWIDTH(%ebp),%eax
	movl	%eax,C(sourcetstep)
	movl	RDS_TMAX(%ebp),%eax
	mull	RDS_TEXWIDTH(%ebp)
	movl	%eax,RDS_STEPBACK(%ebp)
	movl	%eax,C(r_stepback)
	addl	C(r_source),%eax
	movl	%eax,C(r_sourcemax)

	movl	RDS_SURF(%ebp),%esi
	movswl	sd_surface_texturemins(%esi),%eax
	movl	RDS_MIP(%ebp),%ecx
	sarl	%cl,%eax
	movl	RDS_TEXWIDTH(%ebp),%edx
	shll	$16,%edx
	addl	%edx,%eax
	movl	RDS_TEXWIDTH(%ebp),%ecx
	testl	%ecx,%ecx
	jz	.Lrds_soffset_modulo
	leal	-1(%ecx),%edx
	testl	%edx,%ecx
	jnz	.Lrds_soffset_modulo
	andl	%edx,%eax
	jmp	.Lrds_soffset_ready
.Lrds_soffset_modulo:
	cdq
	idivl	%ecx
	movl	%edx,%eax
.Lrds_soffset_ready:
	movl	%eax,RDS_SOFFSET(%ebp)
	movl	RDS_TEXWIDTH(%ebp),%eax
	movl	%eax,RDS_SMAX(%ebp)

	movswl	sd_surface_texturemins+2(%esi),%eax
	movl	RDS_MIP(%ebp),%ecx
	sarl	%cl,%eax
	movl	RDS_TMAX(%ebp),%edx
	shll	$16,%edx
	addl	%edx,%eax
	movl	RDS_TMAX(%ebp),%ecx
	testl	%ecx,%ecx
	jz	.Lrds_toffset_modulo
	leal	-1(%ecx),%edx
	testl	%edx,%ecx
	jnz	.Lrds_toffset_modulo
	andl	%edx,%eax
	jmp	.Lrds_toffset_ready
.Lrds_toffset_modulo:
	cdq
	idivl	%ecx
	movl	%edx,%eax
.Lrds_toffset_ready:
	mull	RDS_TEXWIDTH(%ebp)
	addl	C(r_source),%eax
	movl	%eax,RDS_BASEPTR(%ebp)

	movl	$C(blocklights),%eax
	movl	%eax,RDS_LIGHTPTR(%ebp)
	movl	C(r_drawsurf)+sd_drawsurf_surfdat,%eax
	movl	%eax,RDS_DEST(%ebp)
	movl	RDS_MIP(%ebp),%ecx
	movl	.Lrds_drawer_table(,%ecx,4),%eax
	movl	%eax,RDS_DRAWER(%ebp)
	movl	C(r_numhblocks),%eax
	movl	%eax,RDS_HBLOCKS(%ebp)

#ifdef PROFILE486
	call	C(R_DrawSurfaceProfileStartBlocks_asm486_C)
#endif

	movl	RDS_SMAX(%ebp),%eax
	testl	%eax,%eax
	jz	.Lrds_draw_non_power_of_two
	leal	-1(%eax),%edx
	testl	%edx,%eax
	jnz	.Lrds_draw_non_power_of_two
	movl	%edx,RDS_SMASK(%ebp)
	movl	RDS_HBLOCKS(%ebp),%eax
	movl	%eax,RDS_COUNT(%ebp)
	movl	RDS_MIP(%ebp),%ecx
	testl	%ecx,%ecx
	jz	.Lrds_power_mip0
	cmpl	$1,%ecx
	je	.Lrds_power_mip1
	cmpl	$2,%ecx
	je	.Lrds_power_mip2
	cmpl	$3,%ecx
	je	.Lrds_power_mip3
	jmp	.Lrds_power_indirect

.Lrds_power_mip0:
.Lrds_power_mip0_loop:
	cmpl	$0,RDS_COUNT(%ebp)
	jle	.Lrds_draw_complete
	RDS_PREPARE_BLOCK
	call	C(R_DrawSurfaceBlock8_mip0)
	RDS_ADVANCE_POWER
	decl	RDS_COUNT(%ebp)
	jg	.Lrds_power_mip0_loop
	jmp	.Lrds_draw_complete

.Lrds_power_mip1:
.Lrds_power_mip1_loop:
	cmpl	$0,RDS_COUNT(%ebp)
	jle	.Lrds_draw_complete
	RDS_PREPARE_BLOCK
	call	C(R_DrawSurfaceBlock8_mip1)
	RDS_ADVANCE_POWER
	decl	RDS_COUNT(%ebp)
	jg	.Lrds_power_mip1_loop
	jmp	.Lrds_draw_complete

.Lrds_power_mip2:
.Lrds_power_mip2_loop:
	cmpl	$0,RDS_COUNT(%ebp)
	jle	.Lrds_draw_complete
	RDS_PREPARE_BLOCK
	call	C(R_DrawSurfaceBlock8_mip2)
	RDS_ADVANCE_POWER
	decl	RDS_COUNT(%ebp)
	jg	.Lrds_power_mip2_loop
	jmp	.Lrds_draw_complete

.Lrds_power_mip3:
.Lrds_power_mip3_loop:
	cmpl	$0,RDS_COUNT(%ebp)
	jle	.Lrds_draw_complete
	RDS_PREPARE_BLOCK
	call	C(R_DrawSurfaceBlock8_mip3)
	RDS_ADVANCE_POWER
	decl	RDS_COUNT(%ebp)
	jg	.Lrds_power_mip3_loop
	jmp	.Lrds_draw_complete

.Lrds_power_indirect:
.Lrds_power_indirect_loop:
	cmpl	$0,RDS_COUNT(%ebp)
	jle	.Lrds_draw_complete
	RDS_PREPARE_BLOCK
	call	*RDS_DRAWER(%ebp)
	RDS_ADVANCE_POWER
	decl	RDS_COUNT(%ebp)
	jg	.Lrds_power_indirect_loop
	jmp	.Lrds_draw_complete

.Lrds_draw_non_power_of_two:
	movl	RDS_HBLOCKS(%ebp),%eax
	movl	%eax,RDS_COUNT(%ebp)
	movl	RDS_MIP(%ebp),%ecx
	testl	%ecx,%ecx
	jz	.Lrds_nonpower_mip0
	cmpl	$1,%ecx
	je	.Lrds_nonpower_mip1
	cmpl	$2,%ecx
	je	.Lrds_nonpower_mip2
	cmpl	$3,%ecx
	je	.Lrds_nonpower_mip3
	jmp	.Lrds_nonpower_indirect

.Lrds_nonpower_mip0:
.Lrds_nonpower_mip0_loop:
	cmpl	$0,RDS_COUNT(%ebp)
	jle	.Lrds_draw_complete
	RDS_PREPARE_BLOCK
	call	C(R_DrawSurfaceBlock8_mip0)
	RDS_ADVANCE_NONPOWER
	decl	RDS_COUNT(%ebp)
	jg	.Lrds_nonpower_mip0_loop
	jmp	.Lrds_draw_complete

.Lrds_nonpower_mip1:
.Lrds_nonpower_mip1_loop:
	cmpl	$0,RDS_COUNT(%ebp)
	jle	.Lrds_draw_complete
	RDS_PREPARE_BLOCK
	call	C(R_DrawSurfaceBlock8_mip1)
	RDS_ADVANCE_NONPOWER
	decl	RDS_COUNT(%ebp)
	jg	.Lrds_nonpower_mip1_loop
	jmp	.Lrds_draw_complete

.Lrds_nonpower_mip2:
.Lrds_nonpower_mip2_loop:
	cmpl	$0,RDS_COUNT(%ebp)
	jle	.Lrds_draw_complete
	RDS_PREPARE_BLOCK
	call	C(R_DrawSurfaceBlock8_mip2)
	RDS_ADVANCE_NONPOWER
	decl	RDS_COUNT(%ebp)
	jg	.Lrds_nonpower_mip2_loop
	jmp	.Lrds_draw_complete

.Lrds_nonpower_mip3:
.Lrds_nonpower_mip3_loop:
	cmpl	$0,RDS_COUNT(%ebp)
	jle	.Lrds_draw_complete
	RDS_PREPARE_BLOCK
	call	C(R_DrawSurfaceBlock8_mip3)
	RDS_ADVANCE_NONPOWER
	decl	RDS_COUNT(%ebp)
	jg	.Lrds_nonpower_mip3_loop
	jmp	.Lrds_draw_complete

.Lrds_nonpower_indirect:
.Lrds_nonpower_indirect_loop:
	cmpl	$0,RDS_COUNT(%ebp)
	jle	.Lrds_draw_complete
	RDS_PREPARE_BLOCK
	call	*RDS_DRAWER(%ebp)
	RDS_ADVANCE_NONPOWER
	decl	RDS_COUNT(%ebp)
	jg	.Lrds_nonpower_indirect_loop

.Lrds_draw_complete:
#ifdef PROFILE486
	call	C(R_DrawSurfaceProfileFinish_asm486_C)
#endif
	popl	%edi
	popl	%esi
	popl	%ebx
	leave
	ret

	.section .rodata
.Lrds_drawer_table:
	.long C(R_DrawSurfaceBlock8_mip0)
	.long C(R_DrawSurfaceBlock8_mip1)
	.long C(R_DrawSurfaceBlock8_mip2)
	.long C(R_DrawSurfaceBlock8_mip3)
	.text

#endif

#ifdef ASM486_LIGHTMAP_BUILD

.set LMB_SURF,       -4
.set LMB_SMAX,       -8
.set LMB_TMAX,      -12
.set LMB_SIZE,      -16
.set LMB_LIGHTMAP,  -20
.set LMB_SCALE,     -24
.set LMB_MAPS,      -28
.set LMB_FIRST,     -32
.set LMB_INVERSE,   -36
.set LMB_INDEX,     -40

	.p2align 4,,15
// void R_BuildLightMap(void)
// Convert the C dispatcher and its inline fill/table loops to 32-bit i486
// assembly. The style, fused-style, dynamic-light, and normalization helpers
// remain independently selectable at their existing C/ASM seams.
C(R_BuildLightMap):
	.globl C(R_BuildLightMap)
	pushl	%ebp
	movl	%esp,%ebp
	subl	$40,%esp
	pushl	%ebx
	pushl	%esi
	pushl	%edi

	movl	C(r_drawsurf)+lm_drawsurf_surf,%esi
	movl	%esi,LMB_SURF(%ebp)
	movswl	lm_surface_extents(%esi),%eax
	sarl	$4,%eax
	incl	%eax
	movl	%eax,LMB_SMAX(%ebp)
	movswl	lm_surface_extents+2(%esi),%eax
	sarl	$4,%eax
	incl	%eax
	movl	%eax,LMB_TMAX(%ebp)
	movl	LMB_SMAX(%ebp),%eax
	mull	LMB_TMAX(%ebp)
	movl	%eax,LMB_SIZE(%ebp)
	movl	lm_surface_samples(%esi),%eax
	movl	%eax,LMB_LIGHTMAP(%ebp)

	// C float truth is false only for +0 and -0. Test the magnitude bits;
	// subnormals and NaNs remain true.
	testl	$0x7fffffff,C(r_fullbright)+lm_cvar_value
	jne	.Llightmap_fullbright
	movl	C(cl)+lm_client_worldmodel,%eax
	cmpl	$0,lm_model_lightdata(%eax)
	je	.Llightmap_fullbright

	movl	C(r_refdef)+lm_refdef_ambientlight,%eax
	shll	$8,%eax
	movl	%eax,LMB_SCALE(%ebp)

	// If style zero exists, first try the no-dlight fused fast paths.
	movl	LMB_LIGHTMAP(%ebp),%eax
	testl	%eax,%eax
	je	.Llightmap_ambient_only
	cmpb	$255,lm_surface_styles(%esi)
	je	.Llightmap_ambient_only
	movl	C(r_drawsurf)+lm_drawsurf_lightadj,%eax
	movl	%eax,LMB_FIRST(%ebp)
	movl	lm_surface_dlightframe(%esi),%eax
	cmpl	C(r_framecount),%eax
	je	.Llightmap_style_accumulate

	// A single style has a cached 256-entry invert/clamp table. Rebuild it
	// only when the first-style adjustment or ambient scale changes.
	cmpb	$255,lm_surface_styles+1(%esi)
	jne	.Llightmap_fused_styles
	movl	$65280,%eax
	subl	LMB_SCALE(%ebp),%eax
	movl	%eax,LMB_INVERSE(%ebp)
	cmpl	$0,C(lightmap_single_table_valid)
	je	.Llightmap_single_rebuild
	movl	C(lightmap_single_first),%edx
	cmpl	LMB_FIRST(%ebp),%edx
	jne	.Llightmap_single_rebuild
	movl	C(lightmap_single_inverse_scale),%edx
	cmpl	LMB_INVERSE(%ebp),%edx
	je	.Llightmap_single_table_ready

.Llightmap_single_rebuild:
	movl	$0,LMB_INDEX(%ebp)
	movl	$C(lightmap_single_table),%edi
.Llightmap_single_table_loop:
	movl	LMB_INDEX(%ebp),%eax
	mull	LMB_FIRST(%ebp)
	subl	LMB_INVERSE(%ebp),%eax
	negl	%eax
	sarl	$2,%eax
	cmpl	$64,%eax
	jge	.Llightmap_single_table_store
	movl	$64,%eax
.Llightmap_single_table_store:
	movl	LMB_INDEX(%ebp),%ecx
	movl	%eax,(%edi,%ecx,4)
	incl	LMB_INDEX(%ebp)
	cmpl	$256,LMB_INDEX(%ebp)
	jl	.Llightmap_single_table_loop
	movl	LMB_FIRST(%ebp),%eax
	movl	%eax,C(lightmap_single_first)
	movl	LMB_INVERSE(%ebp),%eax
	movl	%eax,C(lightmap_single_inverse_scale)
	movl	$1,C(lightmap_single_table_valid)

.Llightmap_single_table_ready:
#ifdef PROFILE486
	movl	C(bench486_lm_single_texels),%eax
	addl	LMB_SIZE(%ebp),%eax
	movl	%eax,C(bench486_lm_single_texels)
#endif
	movl	LMB_LIGHTMAP(%ebp),%esi
	movl	$C(lightmap_single_table),%ebx
	movl	$C(blocklights),%edi
	movl	LMB_SIZE(%ebp),%ecx
.Llightmap_single_output_loop:
	movzbl	(%esi),%eax
	movl	(%ebx,%eax,4),%eax
	movl	%eax,(%edi)
	incl	%esi
	addl	$4,%edi
	decl	%ecx
	jnz	.Llightmap_single_output_loop
	jmp	.Llightmap_return

.Llightmap_fused_styles:
	cmpb	$255,lm_surface_styles+2(%esi)
	jne	.Llightmap_fused_check_map3
	movl	$2,LMB_MAPS(%ebp)
	jmp	.Llightmap_fused_dispatch
.Llightmap_fused_check_map3:
	cmpb	$255,lm_surface_styles+3(%esi)
	jne	.Llightmap_fused_map4
	movl	$3,LMB_MAPS(%ebp)
	jmp	.Llightmap_fused_dispatch
.Llightmap_fused_map4:
	movl	$4,LMB_MAPS(%ebp)
.Llightmap_fused_dispatch:
#ifdef PROFILE486
	movl	C(bench486_lm_fused_texels),%eax
	addl	LMB_SIZE(%ebp),%eax
	movl	%eax,C(bench486_lm_fused_texels)
	movl	LMB_MAPS(%ebp),%edx
	shll	$2,%edx
	movl	LMB_SIZE(%ebp),%eax
	addl	%eax,C(bench486_lm_fused_maps)(,%edx,1)
#endif
	leal	lm_drawsurf_lightadj+C(r_drawsurf),%eax
	pushl	%eax
	pushl	LMB_SCALE(%ebp)
	pushl	LMB_MAPS(%ebp)
	pushl	LMB_SIZE(%ebp)
	pushl	LMB_LIGHTMAP(%ebp)
	pushl	$C(blocklights)
#ifdef ASM486_FUSED_LIGHTMAP
	call	C(R_BuildLightMapFusedNoDlights_asm486)
#else
	call	C(R_BuildLightMapFusedNoDlights_C)
#endif
	addl	$24,%esp
	jmp	.Llightmap_return

.Llightmap_style_accumulate:
	movl	$1,LMB_MAPS(%ebp)
.Llightmap_count_styles:
	movl	LMB_MAPS(%ebp),%eax
	cmpl	$4,%eax
	jge	.Llightmap_styles_dispatch
	cmpb	$255,lm_surface_styles(%esi,%eax)
	je	.Llightmap_styles_dispatch
	incl	LMB_MAPS(%ebp)
	jmp	.Llightmap_count_styles
.Llightmap_styles_dispatch:
	leal	lm_drawsurf_lightadj+C(r_drawsurf),%eax
	pushl	%eax
	pushl	LMB_SCALE(%ebp)
	pushl	LMB_MAPS(%ebp)
	pushl	LMB_SIZE(%ebp)
	pushl	LMB_LIGHTMAP(%ebp)
	pushl	$C(blocklights)
#ifdef ASM486_LIGHTMAP_STYLES
	call	C(R_BuildLightMapStyles_asm486)
#else
	call	C(R_BuildLightMapStyles_C)
#endif
	addl	$24,%esp
	jmp	.Llightmap_dynamic_lights

.Llightmap_ambient_only:
	movl	$C(blocklights),%edi
	movl	LMB_SIZE(%ebp),%ecx
	movl	LMB_SCALE(%ebp),%eax
	cld
	rep	stosl

.Llightmap_dynamic_lights:
	movl	LMB_SURF(%ebp),%esi
	movl	lm_surface_dlightframe(%esi),%eax
	cmpl	C(r_framecount),%eax
	jne	.Llightmap_normalize
	movl	$0,C(r_dlight_contributed)
	call	C(R_AddDynamicLights)

.Llightmap_normalize:
	pushl	LMB_SIZE(%ebp)
	pushl	$C(blocklights)
#ifdef ASM486_LIGHTMAP_NORMALIZE
	call	C(R_BuildLightMapNormalize_asm486)
#else
	call	C(R_BuildLightMapNormalize_C)
#endif
	addl	$8,%esp
	jmp	.Llightmap_return

.Llightmap_fullbright:
	movl	$C(blocklights),%edi
	movl	LMB_SIZE(%ebp),%ecx
	xorl	%eax,%eax
	cld
	rep	stosl

.Llightmap_return:
	popl	%edi
	popl	%esi
	popl	%ebx
	movl	%ebp,%esp
	popl	%ebp
	ret

#endif

#ifdef ASM486_SURFACE_DISPATCH
	.p2align 4,,15

// The surface stack and renderer layouts are pinned by compile-time C asserts
// in d_edge.c. These offsets are therefore an explicit ABI for this routine.
.set DS_SPANS, 8
.set DS_FLAGS, 24
.set DS_DATA, 28
.set DS_ENTITY, 32
.set DS_NEARZI, 36
.set DS_INSUBMODEL, 40
.set DS_ZIORIGIN, 44
.set DS_ZISTEPU, 48
.set DS_ZISTEPV, 52
.set DS_SURFACE_SIZE, 64
.set DS_ENTITY_ORIGIN, 84
.set DS_TEXINFO, 52
.set DS_TEXINFO_MIPADJUST, 32
.set DS_TEXINFO_TEXTURE, 36
.set DS_TEXTURE_OFFSETS, 44
.set DS_MIPTEX_OFFSET, 44
.set DS_CACHE_WIDTH, 32
#define SURF_DRAWSKY 4
#define SURF_DRAWTURB 0x10
#define SURF_DRAWBACKGROUND 0x40
#ifdef DEBUG
.set DS_CACHE_DATA, 48
#else
.set DS_CACHE_DATA, 44
#endif
.set DS_CVAR_VALUE, 16

#ifdef PROFILE486
.macro DS_PROFILE_BEGIN
	call C(D_DrawSurfacesProfileBegin_asm486)
.endm
.macro DS_PROFILE_FINISH
	call C(D_DrawSurfacesProfileFinish_asm486)
.endm
.macro DS_PROFILE_NOTE kind
	pushl	$\kind
	pushl	%esi
	call	C(D_DrawSurfacesProfileRecordSurface_asm486)
	addl	$8,%esp
.endm
.macro DS_PROFILE_ENTER kind
	pushl	$\kind
	call	C(D_DrawSurfacesProfileEnter_asm486)
	addl	$4,%esp
.endm
.macro DS_PROFILE_LEAVE
	call C(D_DrawSurfacesProfileLeave_asm486)
.endm
.macro DS_PROFILE_WORK kind
	pushl	$\kind
	call	C(D_DrawSurfacesProfileWork_asm486)
	addl	$4,%esp
.endm
.macro DS_PROFILE_TIMED_START
	call C(D_DrawSurfacesProfileTimedStart_asm486)
.endm
.macro DS_PROFILE_TIMED_FINISH
	call C(D_DrawSurfacesProfileTimedFinish_asm486)
.endm
.macro DS_PROFILE_TEXTURE_START
	call C(D_DrawSurfacesProfileTextureStart_asm486)
.endm
.macro DS_PROFILE_TEXTURE_FINISH
	call C(D_DrawSurfacesProfileTextureFinish_asm486)
.endm
.macro DS_PROFILE_TEXTURE_WIDTH
	pushl	DS_SPANS(%esi)
	pushl	-48(%ebp)
	pushl	-44(%ebp)
	pushl	%esi
	call C(D_DrawSurfacesProfileTextureWidth_asm486)
	addl	$16,%esp
.endm
#else
.macro DS_PROFILE_BEGIN
.endm
.macro DS_PROFILE_FINISH
.endm
.macro DS_PROFILE_NOTE kind
.endm
.macro DS_PROFILE_ENTER kind
.endm
.macro DS_PROFILE_LEAVE
.endm
.macro DS_PROFILE_WORK kind
.endm
.macro DS_PROFILE_TIMED_START
.endm
.macro DS_PROFILE_TIMED_FINISH
.endm
.macro DS_PROFILE_TEXTURE_START
.endm
.macro DS_PROFILE_TEXTURE_FINISH
.endm
.macro DS_PROFILE_TEXTURE_WIDTH
.endm
#endif

.macro DS_CALC_GRADIENTS
	call C(D_DrawSurfacesCalcGradients_asm486)
.endm


// Restore the base world view after a brush model changed the view axes.
// void D_RestoreWorldDrawingState_asm486(entity_t **rotated, float *world)
C(D_RestoreWorldDrawingState_asm486):
	.globl C(D_RestoreWorldDrawingState_asm486)
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	movl	8(%ebp),%eax
	cmpl	$0,(%eax)
	je	.Lds_restore_done
	movl	12(%ebp),%esi
	// cl_entities is an array symbol, not a pointer.
	leal	C(cl_entities),%eax
	movl	%eax,C(currententity)
	leal	C(transformed_modelorg),%edi
	movl	(%esi),%eax
	movl	%eax,(%edi)
	movl	4(%esi),%eax
	movl	%eax,4(%edi)
	movl	8(%esi),%eax
	movl	%eax,8(%edi)
	movl	C(base_vpn),%eax
	movl	%eax,C(vpn)
	movl	C(base_vpn)+4,%eax
	movl	%eax,C(vpn)+4
	movl	C(base_vpn)+8,%eax
	movl	%eax,C(vpn)+8
	movl	C(base_vup),%eax
	movl	%eax,C(vup)
	movl	C(base_vup)+4,%eax
	movl	%eax,C(vup)+4
	movl	C(base_vup)+8,%eax
	movl	%eax,C(vup)+8
	movl	C(base_vright),%eax
	movl	%eax,C(vright)
	movl	C(base_vright)+4,%eax
	movl	%eax,C(vright)+4
	movl	C(base_vright)+8,%eax
	movl	%eax,C(vright)+8
	movl	C(base_modelorg),%eax
	movl	%eax,C(modelorg)
	movl	C(base_modelorg)+4,%eax
	movl	%eax,C(modelorg)+4
	movl	C(base_modelorg)+8,%eax
	movl	%eax,C(modelorg)+8
	call	C(R_TransformFrustum)
	movl	8(%ebp),%eax
	movl	$0,(%eax)
.Lds_restore_done:
	popl	%edi
	popl	%esi
	popl	%ebx
	movl	%ebp,%esp
	popl	%ebp
	ret

// void D_SetBmodelDrawingState_asm486(entity_t **rotated, surf_t *s,
//         float *local, float *world)
C(D_SetBmodelDrawingState_asm486):
	.globl C(D_SetBmodelDrawingState_asm486)
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	movl	8(%ebp),%edx
	movl	12(%ebp),%esi
	movl	DS_ENTITY(%esi),%ebx
	cmpl	%ebx,(%edx)
	je	.Lds_set_done
	pushl	20(%ebp)
	pushl	%edx
	call	C(D_RestoreWorldDrawingState_asm486)
	addl	$8,%esp
	movl	%ebx,C(currententity)
	movl	16(%ebp),%edi
	flds	C(r_origin)
	fsubs	DS_ENTITY_ORIGIN(%ebx)
	fstps	(%edi)
	flds	C(r_origin)+4
	fsubs	DS_ENTITY_ORIGIN+4(%ebx)
	fstps	4(%edi)
	flds	C(r_origin)+8
	fsubs	DS_ENTITY_ORIGIN+8(%ebx)
	fstps	8(%edi)
	leal	C(transformed_modelorg),%eax
	pushl	%eax
	pushl	%edi
	call	C(TransformVector)
	addl	$8,%esp
	call	C(R_RotateBmodelCached)
	movl	8(%ebp),%edx
	movl	%ebx,(%edx)
.Lds_set_done:
	popl	%edi
	popl	%esi
	popl	%ebx
	movl	%ebp,%esp
	popl	%ebp
	ret

// Surface dispatcher locals: world modelorg (-24..-16), local modelorg
// (-36..-28), rotated entity (-40), face (-44), cache (-48), loop index (-52),
// x87 control words (-54/-56), and float-to-int result (-60).
C(D_DrawSurfaces):
	.globl C(D_DrawSurfaces)
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	subl	$48,%esp
	DS_PROFILE_BEGIN

	leal	C(cl_entities),%eax
	movl	%eax,C(currententity)
	leal	C(transformed_modelorg),%eax
	pushl	%eax
	leal	C(modelorg),%eax
	pushl	%eax
	call	C(TransformVector)
	addl	$8,%esp
	movl	C(transformed_modelorg),%eax
	movl	%eax,-24(%ebp)
	movl	C(transformed_modelorg)+4,%eax
	movl	%eax,-20(%ebp)
	movl	C(transformed_modelorg)+8,%eax
	movl	%eax,-16(%ebp)
	movl	$0,-40(%ebp)

	// D_DrawSurfaces recomputes both mip-scale tables every invocation.
	xorl	%ecx,%ecx
.Lds_mip_setup:
	flds	C(xscaleinv)
	fmuls	C(d_mipscale_values)(,%ecx,4)
	fstps	C(d_mip_xscale)(,%ecx,4)
	flds	C(yscaleinv)
	fmuls	C(d_mipscale_values)(,%ecx,4)
	fstps	C(d_mip_yscale)(,%ecx,4)
	incl	%ecx
	cmpl	$4,%ecx
	jl	.Lds_mip_setup

	movl	C(r_drawflat)+DS_CVAR_VALUE,%eax
	andl	$0x7fffffff,%eax
	testl	%eax,%eax
	jne	.Lds_drawflat

	// Textured and special surfaces share the source surface-stack order.
	movl	C(surfaces),%esi
	addl	$DS_SURFACE_SIZE,%esi
	movl	C(surface_p),%edi
.Lds_surface_loop:
	cmpl	%edi,%esi
	jae	.Lds_surface_done
	cmpl	$0,DS_SPANS(%esi)
	je	.Lds_surface_next
	incl	C(r_drawnpolycount)
	movl	DS_ZISTEPU(%esi),%eax
	movl	%eax,C(d_zistepu)
	movl	DS_ZISTEPV(%esi),%eax
	movl	%eax,C(d_zistepv)
	movl	DS_ZIORIGIN(%esi),%eax
	movl	%eax,C(d_ziorigin)
	movl	DS_FLAGS(%esi),%eax
	testl	$SURF_DRAWSKY,%eax
	jne	.Lds_sky
	testl	$SURF_DRAWBACKGROUND,%eax
	jne	.Lds_background
	testl	$SURF_DRAWTURB,%eax
	jne	.Lds_turbulent
	jmp	.Lds_texture

.Lds_sky:
	leal	-24(%ebp),%eax
	pushl	%eax
	leal	-40(%ebp),%eax
	pushl	%eax
	call	C(D_RestoreWorldDrawingState_asm486)
	addl	$8,%esp
	DS_PROFILE_NOTE 1
	cmpl	$0,C(r_skymade)
	jne	.Lds_sky_ready
	call	C(R_MakeSky)
.Lds_sky_ready:
	DS_PROFILE_TIMED_START
	DS_PROFILE_ENTER 2
	pushl	DS_SPANS(%esi)
	call	C(D_DrawSkyScans8)
	addl	$4,%esp
	DS_PROFILE_LEAVE
	DS_PROFILE_WORK 2
	DS_PROFILE_TIMED_FINISH
	DS_PROFILE_ENTER 1
	pushl	DS_SPANS(%esi)
	call	C(D_DrawZSpans)
	addl	$4,%esp
	DS_PROFILE_LEAVE
	jmp	.Lds_surface_next

.Lds_background:
	leal	-24(%ebp),%eax
	pushl	%eax
	leal	-40(%ebp),%eax
	pushl	%eax
	call	C(D_RestoreWorldDrawingState_asm486)
	addl	$8,%esp
	DS_PROFILE_NOTE 2
	movl	$0,C(d_zistepu)
	movl	$0,C(d_zistepv)
	flds	.Lds_background_z
	fstps	C(d_ziorigin)
	DS_PROFILE_ENTER 0
	fnstcw	-54(%ebp)
	movw	-54(%ebp),%ax
	orb	$12,%ah
	movw	%ax,-56(%ebp)
	fldcw	-56(%ebp)
	flds	C(r_clearcolor)+DS_CVAR_VALUE
	fistpl	-60(%ebp)
	fldcw	-54(%ebp)
	movl	-60(%ebp),%eax
	andl	$0xff,%eax
	pushl	%eax
	pushl	%esi
	call	C(D_DrawSolidSurface)
	addl	$8,%esp
	DS_PROFILE_LEAVE
	DS_PROFILE_ENTER 1
	pushl	DS_SPANS(%esi)
	call	C(D_DrawZSpans)
	addl	$4,%esp
	DS_PROFILE_LEAVE
	jmp	.Lds_surface_next

.Lds_turbulent:
	DS_PROFILE_NOTE 3
	movl	DS_DATA(%esi),%eax
	movl	%eax,-44(%ebp)
	movl	$0,C(d_gradient_miplevel)
	movl	DS_TEXINFO(%eax),%edx
	movl	DS_TEXINFO_TEXTURE(%edx),%edx
	movl	DS_TEXTURE_OFFSETS(%edx),%ecx
	addl	%edx,%ecx
	movl	%ecx,C(cacheblock)
	movl	$64,C(cachewidth)
	cmpl	$0,DS_INSUBMODEL(%esi)
	je	.Lds_turb_world
	leal	-24(%ebp),%eax
	pushl	%eax
	leal	-28(%ebp),%eax
	pushl	%eax
	pushl	%esi
	leal	-40(%ebp),%eax
	pushl	%eax
	call	C(D_SetBmodelDrawingState_asm486)
	addl	$16,%esp
	jmp	.Lds_turb_state_ready
.Lds_turb_world:
	leal	-24(%ebp),%eax
	pushl	%eax
	leal	-40(%ebp),%eax
	pushl	%eax
	call	C(D_RestoreWorldDrawingState_asm486)
	addl	$8,%esp
.Lds_turb_state_ready:
	pushl	-44(%ebp)
	DS_CALC_GRADIENTS
	addl	$4,%esp
	DS_PROFILE_ENTER 3
	pushl	DS_SPANS(%esi)
	call	C(Turbulent8)
	addl	$4,%esp
	DS_PROFILE_LEAVE
	DS_PROFILE_WORK 3
	DS_PROFILE_ENTER 1
	pushl	DS_SPANS(%esi)
	call	C(D_DrawZSpans)
	addl	$4,%esp
	DS_PROFILE_LEAVE
	jmp	.Lds_surface_next

.Lds_texture:
	DS_PROFILE_NOTE 4
	cmpl	$0,DS_INSUBMODEL(%esi)
	je	.Lds_texture_world
	leal	-24(%ebp),%eax
	pushl	%eax
	leal	-28(%ebp),%eax
	pushl	%eax
	pushl	%esi
	leal	-40(%ebp),%eax
	pushl	%eax
	call	C(D_SetBmodelDrawingState_asm486)
	addl	$16,%esp
	jmp	.Lds_texture_state_ready
.Lds_texture_world:
	leal	-24(%ebp),%eax
	pushl	%eax
	leal	-40(%ebp),%eax
	pushl	%eax
	call	C(D_RestoreWorldDrawingState_asm486)
	addl	$8,%esp
.Lds_texture_state_ready:
	movl	DS_DATA(%esi),%eax
	movl	%eax,-44(%ebp)
	movl	DS_TEXINFO(%eax),%edx
	flds	DS_NEARZI(%esi)
	fmuls	C(scale_for_mip)
	fmuls	DS_TEXINFO_MIPADJUST(%edx)
	subl	$4,%esp
	fstps	(%esp)
	call	C(D_MipLevelForScale)
	addl	$4,%esp
	movl	%eax,C(d_gradient_miplevel)
	pushl	%eax
	pushl	-44(%ebp)
	call	C(D_CacheSurface)
	addl	$8,%esp
	movl	%eax,-48(%ebp)
	leal	DS_CACHE_DATA(%eax),%edx
	movl	%edx,C(cacheblock)
	movl	DS_CACHE_WIDTH(%eax),%edx
	movl	%edx,C(cachewidth)
	pushl	-44(%ebp)
	DS_CALC_GRADIENTS
	addl	$4,%esp
	DS_PROFILE_TEXTURE_WIDTH
	DS_PROFILE_TEXTURE_START
	DS_PROFILE_ENTER 4
	pushl	DS_SPANS(%esi)
	movl	C(d_drawspans),%eax
	call	*%eax
	addl	$4,%esp
	DS_PROFILE_LEAVE
	DS_PROFILE_TEXTURE_FINISH
	DS_PROFILE_ENTER 1
	pushl	DS_SPANS(%esi)
	call	C(D_DrawZSpans)
	addl	$4,%esp
	DS_PROFILE_LEAVE

.Lds_surface_next:
	addl	$DS_SURFACE_SIZE,%esi
	jmp	.Lds_surface_loop

.Lds_surface_done:
	leal	-24(%ebp),%eax
	pushl	%eax
	leal	-40(%ebp),%eax
	pushl	%eax
	call	C(D_RestoreWorldDrawingState_asm486)
	addl	$8,%esp
	jmp	.Lds_dispatch_finish

.Lds_drawflat:
	movl	C(surfaces),%esi
	addl	$DS_SURFACE_SIZE,%esi
	movl	C(surface_p),%edi
.Lds_flat_loop:
	cmpl	%edi,%esi
	jae	.Lds_dispatch_finish
	cmpl	$0,DS_SPANS(%esi)
	je	.Lds_flat_next
	DS_PROFILE_NOTE 0
	movl	DS_ZISTEPU(%esi),%eax
	movl	%eax,C(d_zistepu)
	movl	DS_ZISTEPV(%esi),%eax
	movl	%eax,C(d_zistepv)
	movl	DS_ZIORIGIN(%esi),%eax
	movl	%eax,C(d_ziorigin)
	DS_PROFILE_ENTER 0
	movl	DS_DATA(%esi),%eax
	andl	$0xff,%eax
	pushl	%eax
	pushl	%esi
	call	C(D_DrawSolidSurface)
	addl	$8,%esp
	DS_PROFILE_LEAVE
	DS_PROFILE_ENTER 1
	pushl	DS_SPANS(%esi)
	call	C(D_DrawZSpans)
	addl	$4,%esp
	DS_PROFILE_LEAVE
.Lds_flat_next:
	addl	$DS_SURFACE_SIZE,%esi
	jmp	.Lds_flat_loop

.Lds_dispatch_finish:
	DS_PROFILE_FINISH
	addl	$48,%esp
	popl	%edi
	popl	%esi
	popl	%ebx
	movl	%ebp,%esp
	popl	%ebp
	ret

#endif

#ifdef ASM486_DYNAMIC_LIGHT_PROJECTION

.set DLP_FIST_TMP, 4
.set DLP_CW_CEIL,  10
.set DLP_CW_CHOP,  12
.set DLP_CW_OLD,   14

	.p2align 4,,15
// int R_AddDynamicLightProject_asm486(int lnum, msurface_t *surf,
//     int smax, int tmax, float *local0, float *local1, int *local0_int,
//     int *local1_int, int *idist_limit, int *irad, int *all_lit)
// Preserve the x87 evaluation order and temporary rounding modes emitted by
// the optimized C reference. The scratch area mirrors its CW and conversion
// temporaries while the projection and all surface decisions run in assembly.
C(R_AddDynamicLightProject_asm486):
	.globl C(R_AddDynamicLightProject_asm486)
	pushl	%ebp
	pushl	%edi
	pushl	%esi
	pushl	%ebx
	subl	$20,%esp

	movl	40(%esp),%ecx		// lnum
	shll	$5,%ecx
	movl	44(%esp),%esi		// surf
	movl	64(%esp),%edi		// local0_int output
	movl	72(%esp),%ebx		// idist_limit output
	movl	12(%esi),%eax		// surf->plane

	// Keep planedist in extended precision as the C compiler does.
	flds	C(cl_dlights)(%ecx)
	fmuls	pl_normal(%eax)
	flds	C(cl_dlights)+4(%ecx)
	fmuls	pl_normal+4(%eax)
	faddp	%st,%st(1)
	fsubs	pl_dist(%eax)
	flds	C(cl_dlights)+8(%ecx)
	fmuls	pl_normal+8(%eax)
	faddp	%st,%st(1)

	// rad = radius - fabs(planedist); reject when rad < minlight.
	fld	%st(0)
	fabs
	fsubrs	C(cl_dlights)+12(%ecx)
	flds	C(cl_dlights)+24(%ecx)
	fcom	%st(1)
	fnstsw	%ax
	testb	$0x45,%ah
	je	.Ldlight_project_reject
	movl	52(%esi),%edx		// surf->texinfo

	// irad = trunc(rad * 256), using C's round-toward-zero conversion.
	flds	.Ldlight_project_256
	fld	%st(2)
	fmul	%st(1),%st
	fnstcw	DLP_CW_OLD(%esp)
	movw	DLP_CW_OLD(%esp),%bp
	orl	$0x0c00,%ebp
	movw	%bp,DLP_CW_CHOP(%esp)
	movl	76(%esp),%eax		// irad output
	fldcw	DLP_CW_CHOP(%esp)
	fistpl	(%eax)
	fldcw	DLP_CW_OLD(%esp)

	// idist_limit = ceil((rad - minlight) * 256).
	fxch	%st(2)
	fsubp	%st,%st(1)
	fmulp	%st,%st(1)
	fnstcw	DLP_CW_OLD(%esp)
	movw	DLP_CW_OLD(%esp),%bp
	andl	$0xfffff3ff,%ebp
	orl	$0x0800,%ebp
	movw	%bp,DLP_CW_CEIL(%esp)
	fldcw	DLP_CW_CEIL(%esp)
	frndint
	fldcw	DLP_CW_OLD(%esp)
	fldcw	DLP_CW_CHOP(%esp)
	fistpl	DLP_FIST_TMP(%esp)
	fldcw	DLP_CW_OLD(%esp)
	movl	DLP_FIST_TMP(%esp),%eax
	addl	$255,%eax
	sarl	$8,%eax
	movl	%eax,(%ebx)

	// Project the light onto the plane and into both texture axes.
	movl	12(%esi),%ebp		// surf->plane
	flds	pl_normal(%ebp)
	fmul	%st(1),%st
	fsubrs	C(cl_dlights)(%ecx)
	flds	pl_normal+4(%ebp)
	fmul	%st(2),%st
	fsubrs	C(cl_dlights)+4(%ecx)
	fxch	%st(2)
	fmuls	pl_normal+8(%ebp)
	fsubrs	C(cl_dlights)+8(%ecx)
	flds	12(%edx)
	fisubs	44(%esi)
	flds	(%edx)
	fmul	%st(3),%st
	faddp	%st,%st(1)
	flds	4(%edx)
	fmul	%st(4),%st
	faddp	%st,%st(1)
	flds	8(%edx)
	fmul	%st(2),%st
	faddp	%st,%st(1)
	flds	28(%edx)
	fisubs	46(%esi)
	fxch	%st(3)
	fmuls	16(%edx)
	faddp	%st,%st(3)
	fxch	%st(3)
	fmuls	20(%edx)
	faddp	%st,%st(2)
	fmuls	24(%edx)
	faddp	%st,%st(1)
	fxch	%st(1)
	movl	56(%esp),%esi		// local0 output
	fsts	(%esi)
	fxch	%st(1)
	movl	60(%esp),%ecx		// local1 output
	fsts	(%ecx)
	fxch	%st(1)
	fldcw	DLP_CW_CHOP(%esp)
	fistpl	(%edi)
	fldcw	DLP_CW_OLD(%esp)
	fldcw	DLP_CW_CHOP(%esp)
	fistpl	DLP_FIST_TMP(%esp)
	fldcw	DLP_CW_OLD(%esp)
	movl	DLP_FIST_TMP(%esp),%ebp
	movl	68(%esp),%edx		// local1_int output
	movl	%ebp,(%edx)
	movl	(%edi),%esi		// local0_int

	// Match the C nearest-rectangle surface-edge cull.
	movl	%esi,%eax
	testl	%esi,%esi
	js	.Ldlight_project_abs_s
.Ldlight_project_s_ready:
	movl	48(%esp),%edi		// smax
	leal	-1(%edi),%ecx
	shll	$4,%ecx
	movl	%esi,%edx
	subl	%ecx,%edx
	js	.Ldlight_project_abs_s_edge
.Ldlight_project_s_edge_ready:
	cmpl	%edx,%eax
	jl	.Ldlight_project_use_s_edge
.Ldlight_project_sd_ready:
	movl	%ebp,%edx			// local1_int
	testl	%ebp,%ebp
	js	.Ldlight_project_abs_t
.Ldlight_project_t_ready:
	movl	52(%esp),%esi		// tmax
	leal	-1(%esi),%ecx
	shll	$4,%ecx
	movl	%ebp,%edi
	subl	%ecx,%edi
	js	.Ldlight_project_abs_t_edge
.Ldlight_project_t_edge_ready:
	cmpl	%edi,%edx
	jl	.Ldlight_project_use_t_edge
.Ldlight_project_td_ready:
	cmpl	%edx,%eax
	jl	.Ldlight_project_td_larger
	sarl	$1,%edx
	addl	%edx,%eax
	jmp	.Ldlight_project_store_all_lit
.Ldlight_project_td_larger:
	sarl	$1,%eax
	addl	%eax,%edx
	movl	%edx,%eax
.Ldlight_project_store_all_lit:
	xorl	%ecx,%ecx
	cmpl	(%ebx),%eax
	setl	%cl
	movl	80(%esp),%ebx		// all_lit output
	movl	%ecx,(%ebx)
	movl	$1,%eax
	jmp	.Ldlight_project_return

.Ldlight_project_abs_s:
	negl	%eax
	jmp	.Ldlight_project_s_ready
.Ldlight_project_abs_s_edge:
	negl	%edx
	jmp	.Ldlight_project_s_edge_ready
.Ldlight_project_use_s_edge:
	movl	%edx,%eax
	jmp	.Ldlight_project_sd_ready
.Ldlight_project_abs_t:
	negl	%edx
	jmp	.Ldlight_project_t_ready
.Ldlight_project_abs_t_edge:
	negl	%edi
	jmp	.Ldlight_project_t_edge_ready
.Ldlight_project_use_t_edge:
	movl	%edi,%edx
	jmp	.Ldlight_project_td_ready

.Ldlight_project_reject:
	fstp	%st(0)
	fstp	%st(0)
	fstp	%st(0)
	xorl	%eax,%eax
.Ldlight_project_return:
	addl	$20,%esp
	popl	%ebx
	popl	%esi
	popl	%edi
	popl	%ebp
	ret

#endif

#ifdef ASM486_DYNAMIC_LIGHT_ORCHESTRATION

.set DLO_SURF,        -4
.set DLO_SMAX,        -8
.set DLO_TMAX,       -12
.set DLO_BITS,       -16
.set DLO_CONTRIB,    -20
.set DLO_LOCAL0,     -24
.set DLO_LOCAL1,     -28
.set DLO_LOCAL0_INT, -32
.set DLO_LOCAL1_INT, -36
.set DLO_LIMIT,      -40
.set DLO_IRAD,       -44
.set DLO_ALL_LIT,    -48
	.p2align 4,,15
// void R_AddDynamicLights(void)
// Keep the sparse surface-bit scan and the C/ASM sample-loop choice here.
// Projection and surface culling run in the separate assembly x87 helper.
C(R_AddDynamicLights):
	.globl C(R_AddDynamicLights)
	pushl	%ebp
	movl	%esp,%ebp
	subl	$48,%esp
	pushl	%ebx
	pushl	%esi
	pushl	%edi

	movl	C(r_drawsurf)+dl_drawsurf_surf,%esi
	movl	%esi,DLO_SURF(%ebp)
	movswl	dl_surface_extents(%esi),%eax
	sarl	$4,%eax
	incl	%eax
	movl	%eax,DLO_SMAX(%ebp)
	movswl	dl_surface_extents+2(%esi),%eax
	sarl	$4,%eax
	incl	%eax
	movl	%eax,DLO_TMAX(%ebp)
	movl	dl_surface_dlightbits(%esi),%eax
	movl	%eax,DLO_BITS(%ebp)
	movl	C(r_dlight_contributed),%eax
	movl	%eax,DLO_CONTRIB(%ebp)

.Ldlight_orchestration_next:
	movl	DLO_BITS(%ebp),%eax
	testl	%eax,%eax
	je	.Ldlight_orchestration_done
	bsfl	%eax,%ebx
	leal	-1(%eax),%edx
	andl	%edx,%eax
	movl	%eax,DLO_BITS(%ebp)

	// int project(lnum, surf, smax, tmax, &local0, &local1,
	//             &local0_int, &local1_int, &limit, &irad, &all_lit)
	leal	DLO_ALL_LIT(%ebp),%eax
	pushl	%eax
	leal	DLO_IRAD(%ebp),%eax
	pushl	%eax
	leal	DLO_LIMIT(%ebp),%eax
	pushl	%eax
	leal	DLO_LOCAL1_INT(%ebp),%eax
	pushl	%eax
	leal	DLO_LOCAL0_INT(%ebp),%eax
	pushl	%eax
	leal	DLO_LOCAL1(%ebp),%eax
	pushl	%eax
	leal	DLO_LOCAL0(%ebp),%eax
	pushl	%eax
	pushl	DLO_TMAX(%ebp)
	pushl	DLO_SMAX(%ebp)
	pushl	DLO_SURF(%ebp)
	pushl	%ebx
	call	C(R_AddDynamicLightProject_asm486)
	addl	$44,%esp
	testl	%eax,%eax
	je	.Ldlight_orchestration_next

#ifdef ASM486_DYNAMIC_LIGHTS
	// Keep integer s coordinates while preserving C's fractional t-row rounding.
	pushl	DLO_ALL_LIT(%ebp)
	pushl	DLO_IRAD(%ebp)
	pushl	DLO_LIMIT(%ebp)
	pushl	DLO_LOCAL1(%ebp)
	pushl	DLO_LOCAL1_INT(%ebp)
	pushl	DLO_LOCAL0_INT(%ebp)
	pushl	DLO_TMAX(%ebp)
	pushl	DLO_SMAX(%ebp)
	pushl	$C(blocklights)
	call	C(R_AddDynamicLightSamples_asm486)
	addl	$36,%esp
#else
	// The selectable C reference consumes the original floating coordinates.
	pushl	DLO_IRAD(%ebp)
	pushl	DLO_LIMIT(%ebp)
	pushl	DLO_LOCAL1(%ebp)
	pushl	DLO_LOCAL0(%ebp)
	pushl	DLO_TMAX(%ebp)
	pushl	DLO_SMAX(%ebp)
	pushl	$C(blocklights)
	call	C(R_AddDynamicLightSamples_C)
	addl	$28,%esp
#endif
	orl	%eax,DLO_CONTRIB(%ebp)
	jmp	.Ldlight_orchestration_next

.Ldlight_orchestration_done:
	movl	DLO_CONTRIB(%ebp),%eax
	movl	%eax,C(r_dlight_contributed)
	popl	%edi
	popl	%esi
	popl	%ebx
	movl	%ebp,%esp
	popl	%ebp
	ret

#endif

#ifdef ASM486_DLIGHT_CONTRIBUTES

.set DLC_SURF,        -4
.set DLC_SMAX,        -8
.set DLC_TMAX,       -12
.set DLC_BITS,       -16
.set DLC_LOCAL0,     -20
.set DLC_LOCAL1,     -24
.set DLC_LOCAL0_INT, -28
.set DLC_LOCAL1_INT, -32
.set DLC_LIMIT,      -36
.set DLC_IRAD,       -40
.set DLC_ALL_LIT,    -44
	.p2align 4,,15
// int R_DlightContributes_asm486(msurface_t *surf)
// Test the nearest clamped texel for each sparse surface light bit. The
// projection helper supplies the same ceil distance limit used by the full
// dynamic-light sample loop, so an eligible texel is exactly idist < limit.
	.globl C(R_DlightContributes_asm486)
	.globl C(R_DlightContributes)
C(R_DlightContributes_asm486):
C(R_DlightContributes):
	pushl	%ebp
	movl	%esp,%ebp
	subl	$44,%esp
	pushl	%ebx
	pushl	%esi
	pushl	%edi

	movl	8(%ebp),%esi
	movl	%esi,DLC_SURF(%ebp)
	movswl	dl_surface_extents(%esi),%eax
	sarl	$4,%eax
	incl	%eax
	movl	%eax,DLC_SMAX(%ebp)
	movswl	dl_surface_extents+2(%esi),%eax
	sarl	$4,%eax
	incl	%eax
	movl	%eax,DLC_TMAX(%ebp)
	movl	dl_surface_dlightbits(%esi),%eax
	movl	%eax,DLC_BITS(%ebp)

.Ldlight_contributes_next:
	movl	DLC_BITS(%ebp),%eax
	testl	%eax,%eax
	je	.Ldlight_contributes_no
	bsfl	%eax,%ebx
	leal	-1(%eax),%edx
	andl	%edx,%eax
	movl	%eax,DLC_BITS(%ebp)

	// Project this light and retain C's float coordinates and int truncation.
	leal	DLC_ALL_LIT(%ebp),%eax
	pushl	%eax
	leal	DLC_IRAD(%ebp),%eax
	pushl	%eax
	leal	DLC_LIMIT(%ebp),%eax
	pushl	%eax
	leal	DLC_LOCAL1_INT(%ebp),%eax
	pushl	%eax
	leal	DLC_LOCAL0_INT(%ebp),%eax
	pushl	%eax
	leal	DLC_LOCAL1(%ebp),%eax
	pushl	%eax
	leal	DLC_LOCAL0(%ebp),%eax
	pushl	%eax
	pushl	DLC_TMAX(%ebp)
	pushl	DLC_SMAX(%ebp)
	pushl	DLC_SURF(%ebp)
	pushl	%ebx
	call	C(R_AddDynamicLightProject_asm486)
	addl	$44,%esp
	testl	%eax,%eax
	je	.Ldlight_contributes_next

	// C clamps (local + 8) / 16 to the nearest sample, then measures sd/td.
	movl	DLC_LOCAL0_INT(%ebp),%eax
	testl	%eax,%eax
	jle	.Ldlight_contributes_s_zero
	addl	$8,%eax
	sarl	$4,%eax
	cmpl	DLC_SMAX(%ebp),%eax
	jl	.Ldlight_contributes_s_ready
	movl	DLC_SMAX(%ebp),%eax
	decl	%eax
	jmp	.Ldlight_contributes_s_ready
.Ldlight_contributes_s_zero:
	xorl	%eax,%eax
.Ldlight_contributes_s_ready:
	shll	$4,%eax
	movl	DLC_LOCAL0_INT(%ebp),%esi
	subl	%eax,%esi
	testl	%esi,%esi
	jge	.Ldlight_contributes_sd_ready
	negl	%esi
.Ldlight_contributes_sd_ready:

	movl	DLC_LOCAL1_INT(%ebp),%eax
	testl	%eax,%eax
	jle	.Ldlight_contributes_t_zero
	addl	$8,%eax
	sarl	$4,%eax
	cmpl	DLC_TMAX(%ebp),%eax
	jl	.Ldlight_contributes_t_ready
	movl	DLC_TMAX(%ebp),%eax
	decl	%eax
	jmp	.Ldlight_contributes_t_ready
.Ldlight_contributes_t_zero:
	xorl	%eax,%eax
.Ldlight_contributes_t_ready:
	shll	$4,%eax
	movl	DLC_LOCAL1_INT(%ebp),%edx
	subl	%eax,%edx
	testl	%edx,%edx
	jge	.Ldlight_contributes_td_ready
	negl	%edx
.Ldlight_contributes_td_ready:

	cmpl	%edx,%esi
	jle	.Ldlight_contributes_td_dominant
	movl	%esi,%eax
	sarl	$1,%edx
	addl	%edx,%eax
	jmp	.Ldlight_contributes_test
.Ldlight_contributes_td_dominant:
	movl	%edx,%eax
	sarl	$1,%esi
	addl	%esi,%eax
.Ldlight_contributes_test:
	cmpl	DLC_LIMIT(%ebp),%eax
	jl	.Ldlight_contributes_yes
	jmp	.Ldlight_contributes_next

.Ldlight_contributes_yes:
	movl	$1,%eax
	jmp	.Ldlight_contributes_return
.Ldlight_contributes_no:
	xorl	%eax,%eax
.Ldlight_contributes_return:
	popl	%edi
	popl	%esi
	popl	%ebx
	movl	%ebp,%esp
	popl	%ebp
	ret

#endif

#ifdef ASM486_RENDER_WORLD
	.equ RW_POLY_BASE, -40016
	.equ RW_POLY_BYTES, 5000*8
	.equ RW_LOCAL_BYTES, RW_POLY_BYTES+4
	.equ RW_PROFILE_START, -16

	.p2align 4,,15
	.globl C(R_RenderWorld_asm486)
C(R_RenderWorld_asm486):
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	subl	$RW_LOCAL_BYTES,%esp

#ifdef PROFILE486
	movl	C(bench486_bsp_nodes),%eax
	movl	%eax,RW_PROFILE_START(%ebp)
	call	C(R_RenderWorldProfileEnter_asm486)
#endif

	// pbtofpolys points at this frame's full 5000-entry back-to-front queue.
	leal	RW_POLY_BASE(%ebp),%eax
	movl	%eax,C(pbtofpolys)
	leal	C(cl_entities),%eax
	movl	%eax,C(currententity)

	// VectorCopy(r_origin, modelorg) preserves all three float bit patterns.
	movl	C(r_origin),%eax
	movl	%eax,C(modelorg)
	movl	C(r_origin)+4,%eax
	movl	%eax,C(modelorg)+4
	movl	C(r_origin)+8,%eax
	movl	%eax,C(modelorg)+8

	// clmodel is cl_entities[0].model; publish its vertex base before the BSP walk.
	movl	C(currententity),%eax
	movl	132(%eax),%ebx
	movl	148(%ebx),%eax
	movl	%eax,C(r_pcurrentvertbase)
	movl	164(%ebx),%eax
	movl	$15,%edx
	call	C(R_RecursiveWorldNode)

	// Replay queued polygons from back to front, including element zero.
	cmpl	$0,C(r_worldpolysbacktofront)
	je	.Lrw_profile_finish
	movl	C(numbtofpolys),%esi
	decl	%esi
.Lrw_poly_loop:
	cmpl	$0,%esi
	jl	.Lrw_profile_finish
	leal	RW_POLY_BASE(%ebp,%esi,8),%eax
	pushl	0(%eax)			// clipflags, second C argument
	pushl	4(%eax)			// psurf, first C argument
	call	C(R_RenderPoly)
	addl	$8,%esp
	decl	%esi
	jmp	.Lrw_poly_loop

.Lrw_profile_finish:
#ifdef PROFILE486
	pushl	RW_PROFILE_START(%ebp)
	call	C(R_RenderWorldProfileWork_asm486)
	addl	$4,%esp
	call	C(R_RenderWorldProfileLeave_asm486)
#endif

	leal	-12(%ebp),%esp
	popl	%edi
	popl	%esi
	popl	%ebx
	popl	%ebp
	ret
#endif

#ifdef ASM486_DRAW_SUBMODEL_POLYGONS
	.extern C(R_RenderFace)
	.extern C(currententity)
	.extern C(modelorg)
	.extern C(r_currentkey)
#ifdef PROFILE486
	.extern C(R_DrawSubmodelPolygonsProfileEntry_asm486)
	.extern C(R_DrawSubmodelPolygonsProfileFaceEnter_asm486)
	.extern C(R_DrawSubmodelPolygonsProfileFaceLeave_asm486)
#endif

	.section .rodata
	.p2align 3
.Lsubmodel_backface_negative_epsilon:
	.double -0.01
.Lsubmodel_backface_positive_epsilon:
	.double 0.01
	.text

	.p2align 4,,15
	.globl C(R_DrawSubmodelPolygons_asm486)
C(R_DrawSubmodelPolygons_asm486):
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi

	movl	8(%ebp),%ebx		// pmodel, first C argument
	movl	12(%ebp),%edi		// clipflags, second C argument
	movl	116(%ebx),%ecx		// nummodelsurfaces
	movl	180(%ebx),%esi		// surfaces
	movl	112(%ebx),%eax		// firstmodelsurface
	shll	$6,%eax			// sizeof(msurface_t) == 64
	addl	%eax,%esi

#ifdef PROFILE486
	pushl	%ecx
	call	C(R_DrawSubmodelPolygonsProfileEntry_asm486)
	addl	$4,%esp
	movl	116(%ebx),%ecx
#endif

	testl	%ecx,%ecx
	jle	.Lsubmodel_polygons_finish

.Lsubmodel_polygons_loop:
	movl	12(%esi),%eax		// psurf->plane
	flds	C(modelorg)
	fmuls	0(%eax)
	flds	C(modelorg)+4
	fmuls	4(%eax)
	faddp	%st,%st(1)
	flds	C(modelorg)+8
	fmuls	8(%eax)
	faddp	%st,%st(1)
	// Keep the x87 extended dot live through the epsilon test. GCC's C path
	// compares this value directly; a float store here culls near-plane faces
	// differently.
	fsubs	12(%eax)

	movl	16(%esi),%eax		// psurf->flags
	testl	$2,%eax			// SURF_PLANEBACK
	jz	.Lsubmodel_polygons_front
	fcompl	.Lsubmodel_backface_negative_epsilon
	fnstsw	%ax
	sahf
	// Match GCC's C output for the negative-side test: it checks C0 only, so
	// unordered x87 results follow the same branch as "below".
	jb	.Lsubmodel_polygons_visible
	jmp	.Lsubmodel_polygons_next

.Lsubmodel_polygons_front:
	fcompl	.Lsubmodel_backface_positive_epsilon
	fnstsw	%ax
	sahf
	jp	.Lsubmodel_polygons_next
	ja	.Lsubmodel_polygons_visible
	jmp	.Lsubmodel_polygons_next

.Lsubmodel_polygons_visible:
	movl	C(currententity),%eax
	movl	176(%eax),%eax		// entity->topnode
	movl	40(%eax),%eax		// mleaf->key
	movl	%eax,C(r_currentkey)

	pushl	%ecx
#ifdef PROFILE486
	call	C(R_DrawSubmodelPolygonsProfileFaceEnter_asm486)
#endif
	pushl	%edi			// clipflags, second C argument
	pushl	%esi			// psurf, first C argument
	call	C(R_RenderFace)
	addl	$8,%esp
#ifdef PROFILE486
	call	C(R_DrawSubmodelPolygonsProfileFaceLeave_asm486)
#endif
	popl	%ecx

.Lsubmodel_polygons_next:
	addl	$64,%esi
	decl	%ecx
	jne	.Lsubmodel_polygons_loop

.Lsubmodel_polygons_finish:
	leal	-12(%ebp),%esp
	popl	%edi
	popl	%esi
	popl	%ebx
	popl	%ebp
	ret
#endif

#ifdef ASM486_BMODEL_POLYGON_CLIP
	.extern C(pbverts)
	.extern C(pbedges)
	.extern C(numbverts)
	.extern C(numbedges)
	.extern C(pfrontenter)
	.extern C(pfrontexit)
	.extern C(makeclippededge)
	.extern C(entity_rotation)
	.extern C(r_entorigin)
	.extern C(r_visframecount)
	.extern C(r_currentbkey)
	.extern C(R_RenderBmodelFace)
	.extern C(Con_Printf)

	.section .rodata
	.p2align 2
.Lbpc_out_of_edges:
	.asciz "Out of edges for bmodel\n"

	.text
	.p2align 4,,15
	.set BPC_SIDE0,       -16
	.set BPC_SIDE1,       -20
	.set BPC_EDGE,        -24
	.set BPC_NEXT,        -28
	.set BPC_SPLIT,       -32
	.set BPC_TDIST,       -36
	.set BPC_TNORMAL0,    -48
	.set BPC_TNORMAL1,    -44
	.set BPC_TNORMAL2,    -40
	.set BPC_LASTDIST,    -52
	.set BPC_DIST,        -56
	.set BPC_FRAC,        -60
	.set BPC_LASTSIDE,    -64
	.set BPC_SIDE,        -68
	.set BPC_PLAST,       -72
	.set BPC_PVERT,       -76
	.set BPC_PTVERT,      -80
	.set BPC_PTEDGE,      -84
	.set BPC_I,           -88
	.set BPC_PN,          -92
	.set BPC_CHILD,       -96

	.macro BPC_DOT3 left, right
	flds	0(\left)
	fmuls	0(\right)
	flds	4(\left)
	fmuls	4(\right)
	faddp	%st(0),%st(1)
	flds	8(\left)
	fmuls	8(\right)
	faddp	%st(0),%st(1)
	.endm

	.globl C(R_RecursiveClipBPoly_asm486)
C(R_RecursiveClipBPoly_asm486):
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	subl	$96,%esp

	movl	8(%ebp),%eax
	movl	%eax,BPC_EDGE(%ebp)
	movl	$0,BPC_SIDE0(%ebp)
	movl	$0,BPC_SIDE1(%ebp)
	movl	$0,C(makeclippededge)

	/* Transform the BSP splitter plane into this brush model's coordinates. */
	movl	12(%ebp),%eax
	movl	24(%eax),%eax
	movl	%eax,BPC_SPLIT(%ebp)
	leal	C(r_entorigin),%esi
	movl	BPC_SPLIT(%ebp),%edi
	BPC_DOT3	%esi,%edi
	fchs
	fadds	12(%edi)
	fstps	BPC_TDIST(%ebp)

	leal	C(entity_rotation),%esi
	movl	BPC_SPLIT(%ebp),%edi
	BPC_DOT3	%esi,%edi
	fstps	BPC_TNORMAL0(%ebp)
	addl	$12,%esi
	BPC_DOT3	%esi,%edi
	fstps	BPC_TNORMAL1(%ebp)
	addl	$12,%esi
	BPC_DOT3	%esi,%edi
	fstps	BPC_TNORMAL2(%ebp)

.Lbpclip_edge_loop:
	movl	BPC_EDGE(%ebp),%ebx
	testl	%ebx,%ebx
	je	.Lbpclip_edges_done
	movl	8(%ebx),%eax
	movl	%eax,BPC_NEXT(%ebp)
	movl	0(%ebx),%eax
	movl	%eax,BPC_PLAST(%ebp)
	movl	4(%ebx),%eax
	movl	%eax,BPC_PVERT(%ebp)

	/* lastdist = dot(v[0], tplane.normal) - tplane.dist. */
	movl	BPC_PLAST(%ebp),%esi
	leal	BPC_TNORMAL0(%ebp),%edi
	BPC_DOT3	%esi,%edi
	fsubs	BPC_TDIST(%ebp)
	fstps	BPC_LASTDIST(%ebp)
	/* IEEE single bits are positive iff bits-1 is <= 0x7f7fffff. */
	movl	BPC_LASTDIST(%ebp),%eax
	decl	%eax
	cmpl	$0x7f7fffff,%eax
	jbe	.Lbpclip_last_front
	movl	$1,BPC_LASTSIDE(%ebp)
	jmp	.Lbpclip_last_side_ready
.Lbpclip_last_front:
	movl	$0,BPC_LASTSIDE(%ebp)
.Lbpclip_last_side_ready:

	/* dist = dot(v[1], tplane.normal) - tplane.dist. */
	movl	BPC_PVERT(%ebp),%esi
	leal	BPC_TNORMAL0(%ebp),%edi
	BPC_DOT3	%esi,%edi
	fsubs	BPC_TDIST(%ebp)
	fstps	BPC_DIST(%ebp)
	movl	BPC_DIST(%ebp),%eax
	decl	%eax
	cmpl	$0x7f7fffff,%eax
	jbe	.Lbpclip_front
	movl	$1,BPC_SIDE(%ebp)
	jmp	.Lbpclip_side_ready
.Lbpclip_front:
	movl	$0,BPC_SIDE(%ebp)
.Lbpclip_side_ready:
	movl	BPC_SIDE(%ebp),%eax
	cmpl	BPC_LASTSIDE(%ebp),%eax
	je	.Lbpclip_keep_edge

	/* A crossing creates one model vertex and two directed edge records. */
	cmpl	$500,C(numbverts)
	jae	.Lbpclip_return
	flds	BPC_LASTDIST(%ebp)
	flds	BPC_DIST(%ebp)
	fsubr	%st(1),%st(0)
	/* frac = lastdist / (lastdist - dist); match the x87 stack order. */
	fdivrp	%st(0),%st(1)
	fstps	BPC_FRAC(%ebp)

	movl	C(numbverts),%eax
	incl	%eax
	movl	%eax,C(numbverts)
	decl	%eax
	leal	(%eax,%eax,2),%eax
	shll	$2,%eax
	movl	C(pbverts),%edi
	leal	(%edi,%eax),%edi
	movl	%edi,BPC_PTVERT(%ebp)

	/* Interpolate v[0] + frac * (v[1] - v[0]) in x87 precision. */	movl	BPC_PLAST(%ebp),%esi
	movl	BPC_PVERT(%ebp),%edi
	movl	BPC_PTVERT(%ebp),%ebx
	flds	(%edi)
	fsubs	(%esi)
	fmuls	BPC_FRAC(%ebp)
	fadds	(%esi)
	fstps	(%ebx)
	flds	4(%edi)
	fsubs	4(%esi)
	fmuls	BPC_FRAC(%ebp)
	fadds	4(%esi)
	fstps	4(%ebx)
	flds	8(%edi)
	fsubs	8(%esi)
	fmuls	BPC_FRAC(%ebp)
	fadds	8(%esi)
	fstps	8(%ebx)

	cmpl	$999,C(numbedges)
	jae	.Lbpclip_edges_overflow
	movl	C(numbedges),%eax
	leal	(%eax,%eax,2),%eax
	shll	$2,%eax
	movl	C(pbedges),%edi
	leal	(%edi,%eax),%edi
	movl	%edi,BPC_PTEDGE(%ebp)

	movl	BPC_LASTSIDE(%ebp),%eax
	testl	%eax,%eax
	jne	.Lbpclip_first_back
	movl	BPC_SIDE0(%ebp),%edx
	jmp	.Lbpclip_first_link
.Lbpclip_first_back:
	movl	BPC_SIDE1(%ebp),%edx
.Lbpclip_first_link:
	movl	BPC_PTEDGE(%ebp),%edi
	movl	%edx,8(%edi)
	testl	%eax,%eax
	jne	.Lbpclip_first_set_back
	movl	%edi,BPC_SIDE0(%ebp)
	jmp	.Lbpclip_first_head_ready
.Lbpclip_first_set_back:
	movl	%edi,BPC_SIDE1(%ebp)
.Lbpclip_first_head_ready:
	movl	BPC_PLAST(%ebp),%edx
	movl	%edx,0(%edi)
	movl	BPC_PTVERT(%ebp),%edx
	movl	%edx,4(%edi)

	movl	BPC_PTEDGE(%ebp),%edi
	leal	12(%edi),%edi
	movl	BPC_SIDE(%ebp),%eax
	testl	%eax,%eax
	jne	.Lbpclip_second_back
	movl	BPC_SIDE0(%ebp),%edx
	jmp	.Lbpclip_second_link
.Lbpclip_second_back:
	movl	BPC_SIDE1(%ebp),%edx
.Lbpclip_second_link:
	movl	%edx,8(%edi)
	testl	%eax,%eax
	jne	.Lbpclip_second_set_back
	movl	%edi,BPC_SIDE0(%ebp)
	jmp	.Lbpclip_second_head_ready
.Lbpclip_second_set_back:
	movl	%edi,BPC_SIDE1(%ebp)
.Lbpclip_second_head_ready:
	movl	BPC_PTVERT(%ebp),%edx
	movl	%edx,0(%edi)
	movl	BPC_PVERT(%ebp),%edx
	movl	%edx,4(%edi)
	addl	$2,C(numbedges)

	cmpl	$0,BPC_SIDE(%ebp)
	jne	.Lbpclip_cross_back
	movl	BPC_PTVERT(%ebp),%eax
	movl	%eax,C(pfrontenter)
	jmp	.Lbpclip_mark_clipped
.Lbpclip_cross_back:
	movl	BPC_PTVERT(%ebp),%eax
	movl	%eax,C(pfrontexit)
.Lbpclip_mark_clipped:
	movl	$1,C(makeclippededge)
	jmp	.Lbpclip_edge_next

.Lbpclip_keep_edge:
	movl	BPC_SIDE(%ebp),%eax
	movl	BPC_EDGE(%ebp),%edx
	testl	%eax,%eax
	jne	.Lbpclip_keep_back
	movl	BPC_SIDE0(%ebp),%ecx
	movl	%ecx,8(%edx)
	movl	%edx,BPC_SIDE0(%ebp)
	jmp	.Lbpclip_edge_next
.Lbpclip_keep_back:
	movl	BPC_SIDE1(%ebp),%ecx
	movl	%ecx,8(%edx)
	movl	%edx,BPC_SIDE1(%ebp)

.Lbpclip_edge_next:
	movl	BPC_NEXT(%ebp),%eax
	movl	%eax,BPC_EDGE(%ebp)
	jmp	.Lbpclip_edge_loop

.Lbpclip_edges_done:
	cmpl	$0,C(makeclippededge)
	je	.Lbpclip_visit_children
	cmpl	$998,C(numbedges)
	jae	.Lbpclip_edges_overflow
	movl	C(numbedges),%eax
	leal	(%eax,%eax,2),%eax
	shll	$2,%eax
	movl	C(pbedges),%edi
	leal	(%edi,%eax),%edi
	movl	%edi,BPC_PTEDGE(%ebp)
	movl	BPC_SIDE0(%ebp),%eax
	movl	%eax,8(%edi)
	movl	C(pfrontexit),%eax
	movl	%eax,0(%edi)
	movl	C(pfrontenter),%eax
	movl	%eax,4(%edi)
	movl	%edi,BPC_SIDE0(%ebp)

	leal	12(%edi),%edi
	movl	BPC_SIDE1(%ebp),%eax
	movl	%eax,8(%edi)
	movl	C(pfrontenter),%eax
	movl	%eax,0(%edi)
	movl	C(pfrontexit),%eax
	movl	%eax,4(%edi)
	movl	%edi,BPC_SIDE1(%ebp)
	addl	$2,C(numbedges)

.Lbpclip_visit_children:
	movl	$0,BPC_I(%ebp)
.Lbpclip_child_loop:
	movl	BPC_I(%ebp),%eax
	cmpl	$2,%eax
	jae	.Lbpclip_return
	cmpl	$0,%eax
	jne	.Lbpclip_child_back
	movl	BPC_SIDE0(%ebp),%edx
	jmp	.Lbpclip_child_edges_ready
.Lbpclip_child_back:
	movl	BPC_SIDE1(%ebp),%edx
.Lbpclip_child_edges_ready:
	testl	%edx,%edx
	je	.Lbpclip_child_next
	movl	12(%ebp),%ecx
	movl	28(%ecx,%eax,4),%ecx
	movl	%ecx,BPC_CHILD(%ebp)
	movl	C(r_visframecount),%eax
	cmpl	%eax,4(%ecx)
	jne	.Lbpclip_child_next
	cmpl	$0,0(%ecx)
	jl	.Lbpclip_child_leaf
	movl	BPC_SIDE0(%ebp),%eax
	cmpl	$0,BPC_I(%ebp)
	jne	.Lbpclip_recurse_back
	jmp	.Lbpclip_recurse_call
.Lbpclip_recurse_back:
	movl	BPC_SIDE1(%ebp),%eax
.Lbpclip_recurse_call:
	pushl	16(%ebp)
	pushl	BPC_CHILD(%ebp)
	pushl	%eax
	call	C(R_RecursiveClipBPoly_asm486)
	addl	$12,%esp
	jmp	.Lbpclip_child_next

.Lbpclip_child_leaf:
	cmpl	$-2,0(%ecx)
	je	.Lbpclip_child_next
	movl	40(%ecx),%eax
	movl	%eax,C(r_currentbkey)
	cmpl	$0,BPC_I(%ebp)
	jne	.Lbpclip_draw_back
	movl	BPC_SIDE0(%ebp),%eax
	jmp	.Lbpclip_draw_call
.Lbpclip_draw_back:
	movl	BPC_SIDE1(%ebp),%eax
.Lbpclip_draw_call:
	pushl	16(%ebp)
	pushl	%eax
	call	C(R_RenderBmodelFace)
	addl	$8,%esp

.Lbpclip_child_next:
	incl	BPC_I(%ebp)
	jmp	.Lbpclip_child_loop

.Lbpclip_edges_overflow:
	pushl	$.Lbpc_out_of_edges
	call	C(Con_Printf)
	addl	$4,%esp
.Lbpclip_return:
	leal	-12(%ebp),%esp
	popl	%edi
	popl	%esi
	popl	%ebx
	popl	%ebp
	ret
#endif

#ifdef ASM486_DRAW_SOLID_CLIPPED_SUBMODEL_POLYGONS
	.extern C(pbverts)
	.extern C(pbedges)
	.extern C(numbverts)
	.extern C(numbedges)
	.extern C(modelorg)
	.extern C(currententity)
	.extern C(r_pcurrentvertbase)
	.extern C(R_RecursiveClipBPoly)
	.extern C(Sys_Error)

	.section .rodata
	.p2align 3
.Lsolid_bmodel_backface_negative_epsilon:
	.double -0.01
.Lsolid_bmodel_backface_positive_epsilon:
	.double 0.01
.Lsolid_bmodel_no_edges:
	.asciz "no edges in bmodel"

	.text
	.p2align 4,,15
	.set SBCSP_I,          -16
	.set SBCSP_J,          -20
	.set SBCSP_LINDEX,     -24
	.set SBCSP_DOT,        -28
	.set SBCSP_SURF,       -32
	.set SBCSP_NUMSURFS,   -36
	.set SBCSP_PEDGES,     -40
	.set SBCSP_PPLANE,     -44
	.set SBCSP_PBEDGE,     -48
	.set SBCSP_PSURFEDGES, -52
	.set SBCSP_EDGEBASE,   -56
	.set SBCSP_VERTBASE,   -60
	.set SBCSP_PEDGE,      -64
	.set SBCSP_NUMEDGES,   -68

	.globl C(R_DrawSolidClippedSubmodelPolygons_asm486)
C(R_DrawSolidClippedSubmodelPolygons_asm486):
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	/*
	 * C keeps bedges[1000] (12000 bytes) and bverts[500] (6000 bytes)
	 * in this function's frame. Keep the edge records at the low end of this
	 * reservation and vertices above them; locals remain above -68(%ebp).
	 */
	subl	$18064,%esp

	movl	8(%ebp),%ebx			// model
	movl	116(%ebx),%eax		// model->nummodelsurfaces
	movl	%eax,SBCSP_NUMSURFS(%ebp)
	movl	180(%ebx),%eax		// model->surfaces
	movl	112(%ebx),%edx		// model->firstmodelsurface
	shll	$6,%edx				// sizeof(msurface_t) == 64
	addl	%edx,%eax
	movl	%eax,SBCSP_SURF(%ebp)
	movl	156(%ebx),%eax		// model->edges
	movl	%eax,SBCSP_PEDGES(%ebp)

	leal	-18076(%ebp),%eax	// 1000 bedge_t records, 12 bytes each
	movl	%eax,SBCSP_EDGEBASE(%ebp)
	leal	12000(%eax),%edx	// 500 mvertex_t records, 12 bytes each
	movl	%edx,SBCSP_VERTBASE(%ebp)
	movl	$0,SBCSP_I(%ebp)

.Lsolid_bmodel_surface_loop:
	movl	SBCSP_I(%ebp),%eax
	cmpl	SBCSP_NUMSURFS(%ebp),%eax
	jae	.Lsolid_bmodel_return
	movl	SBCSP_SURF(%ebp),%esi
	movl	12(%esi),%edi			// msurface_t::plane
	movl	%edi,SBCSP_PPLANE(%ebp)

	/* dot = DotProduct(modelorg, plane.normal) - plane.dist; */
	leal	C(modelorg),%esi
	flds	0(%esi)
	fmuls	0(%edi)
	flds	4(%esi)
	fmuls	4(%edi)
	faddp	%st(0),%st(1)
	flds	8(%esi)
	fmuls	8(%edi)
	faddp	%st(0),%st(1)
	fsubs	12(%edi)
	fstps	SBCSP_DOT(%ebp)

	movl	SBCSP_SURF(%ebp),%esi
	testl	$2,16(%esi)			// SURF_PLANEBACK
	je	.Lsolid_bmodel_test_front
	fldl	.Lsolid_bmodel_backface_negative_epsilon
	flds	SBCSP_DOT(%ebp)
	fcompp
	fnstsw	%ax
	sahf
	jp	.Lsolid_bmodel_next_surface	// C comparison is false for NaN
	jb	.Lsolid_bmodel_visible		// dot < -BACKFACE_EPSILON
	jmp	.Lsolid_bmodel_next_surface

.Lsolid_bmodel_test_front:
	fldl	.Lsolid_bmodel_backface_positive_epsilon
	flds	SBCSP_DOT(%ebp)
	fcompp
	fnstsw	%ax
	sahf
	jp	.Lsolid_bmodel_next_surface
	ja	.Lsolid_bmodel_visible		// dot > BACKFACE_EPSILON
	jmp	.Lsolid_bmodel_next_surface

.Lsolid_bmodel_visible:
	/* Each visible surface starts with private 500-vertex/1000-edge buffers. */
	movl	SBCSP_VERTBASE(%ebp),%eax
	movl	%eax,C(pbverts)
	movl	SBCSP_EDGEBASE(%ebp),%eax
	movl	%eax,C(pbedges)
	movl	$0,C(numbverts)
	movl	$0,C(numbedges)

	movl	SBCSP_SURF(%ebp),%esi
	movl	24(%esi),%ecx			// msurface_t::numedges
	testl	%ecx,%ecx
	jle	.Lsolid_bmodel_no_edges_error
	movl	%ecx,SBCSP_NUMEDGES(%ebp)
	movl	%ecx,C(numbedges)
	movl	SBCSP_EDGEBASE(%ebp),%eax
	movl	%eax,SBCSP_PBEDGE(%ebp)

	movl	8(%ebp),%ebx
	movl	188(%ebx),%eax		// model->surfedges
	movl	20(%esi),%edx		// msurface_t::firstedge
	leal	(%eax,%edx,4),%eax
	movl	%eax,SBCSP_PSURFEDGES(%ebp)
	movl	$0,SBCSP_J(%ebp)

.Lsolid_bmodel_edge_loop:
	movl	SBCSP_J(%ebp),%eax
	cmpl	SBCSP_NUMEDGES(%ebp),%eax
	jae	.Lsolid_bmodel_edges_done
	movl	SBCSP_PSURFEDGES(%ebp),%edx
	movl	(%edx,%eax,4),%ecx
	movl	%ecx,SBCSP_LINDEX(%ebp)
	testl	%ecx,%ecx
	jg	.Lsolid_bmodel_edge_forward
	negl	%ecx				// reverse surfedge indexes its source medge
.Lsolid_bmodel_load_medge:
	movl	SBCSP_PEDGES(%ebp),%esi
	leal	(,%ecx,8),%edx		// sizeof(medge_t) == 8
	addl	%edx,%esi
	movl	%esi,SBCSP_PEDGE(%ebp)

	movl	SBCSP_J(%ebp),%eax
	leal	(%eax,%eax,2),%eax
	shll	$2,%eax				// j * sizeof(bedge_t), 12 bytes
	movl	SBCSP_PBEDGE(%ebp),%edi
	addl	%eax,%edi

	cmpl	$0,SBCSP_LINDEX(%ebp)
	jle	.Lsolid_bmodel_edge_reverse
	/* Positive surfedges preserve medge.v[0], then medge.v[1]. */
	movzwl	0(%esi),%eax
	leal	(%eax,%eax,2),%eax
	movl	C(r_pcurrentvertbase),%edx
	leal	(%edx,%eax,4),%eax
	movl	%eax,0(%edi)
	movzwl	2(%esi),%eax
	leal	(%eax,%eax,2),%eax
	movl	C(r_pcurrentvertbase),%edx
	leal	(%edx,%eax,4),%eax
	movl	%eax,4(%edi)
	jmp	.Lsolid_bmodel_edge_link

.Lsolid_bmodel_edge_reverse:
	/* Negative or zero surfedges reverse the source medge winding. */
	movzwl	2(%esi),%eax
	leal	(%eax,%eax,2),%eax
	movl	C(r_pcurrentvertbase),%edx
	leal	(%edx,%eax,4),%eax
	movl	%eax,0(%edi)
	movzwl	0(%esi),%eax
	leal	(%eax,%eax,2),%eax
	movl	C(r_pcurrentvertbase),%edx
	leal	(%edx,%eax,4),%eax
	movl	%eax,4(%edi)

.Lsolid_bmodel_edge_link:
	leal	12(%edi),%eax
	movl	%eax,8(%edi)
	incl	SBCSP_J(%ebp)
	jmp	.Lsolid_bmodel_edge_loop

.Lsolid_bmodel_edge_forward:
	jmp	.Lsolid_bmodel_load_medge

.Lsolid_bmodel_edges_done:
	movl	SBCSP_J(%ebp),%eax
	decl	%eax
	leal	(%eax,%eax,2),%eax
	shll	$2,%eax
	movl	SBCSP_PBEDGE(%ebp),%edi
	addl	%eax,%edi
	movl	$0,8(%edi)			// mark the input edge list end

	movl	C(currententity),%eax
	movl	176(%eax),%edx		// entity_t::topnode
	pushl	SBCSP_SURF(%ebp)
	pushl	%edx
	pushl	SBCSP_PBEDGE(%ebp)
	call	C(R_RecursiveClipBPoly)
	addl	$12,%esp
	jmp	.Lsolid_bmodel_next_surface

.Lsolid_bmodel_no_edges_error:
	pushl	$.Lsolid_bmodel_no_edges
	call	C(Sys_Error)
	addl	$4,%esp

.Lsolid_bmodel_next_surface:
	incl	SBCSP_I(%ebp)
	addl	$64,SBCSP_SURF(%ebp)
	jmp	.Lsolid_bmodel_surface_loop

.Lsolid_bmodel_return:
	leal	-12(%ebp),%esp
	popl	%edi
	popl	%esi
	popl	%ebx
	popl	%ebp
	ret
#endif

#ifdef ASM486_PARTICLE_UPDATE
	.extern C(active_particles)
	.extern C(free_particles)
	.extern C(ramp1)
	.extern C(ramp2)
	.extern C(ramp3)
	.extern C(vright)
	.extern C(vup)
	.extern C(vpn)
	.extern C(xscaleshrink)
	.extern C(yscaleshrink)
	.extern C(r_pright)
	.extern C(r_pup)
	.extern C(r_ppn)
	.extern C(D_DrawParticle)
#ifdef PROFILE486
	.extern C(bench486_profile_frame_active)
#endif

	.section .rodata
	.p2align 2
.Lparticle_five:
	.float 5.0
.Lparticle_ten:
	.float 10.0
.Lparticle_fifteen:
	.float 15.0
.Lparticle_point_zero_five:
	.double 0.05
.Lparticle_four:
	.float 4.0
.Lparticle_one:
	.float 1.0
.Lparticle_six:
	.float 6.0
.Lparticle_eight:
	.float 8.0
.Lparticle_twenty:
	.float 20.0
	.text
	.p2align 4,,15
	.globl C(R_DrawParticles_asm486)
C(R_DrawParticles_asm486):
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	subl	$48,%esp

	/* Keep the caller's x87 rounding mode.  Ramp-to-index casts use truncation
	   only around FISTP, then restore it before the next renderer call. */
	fnstcw	-46(%ebp)
	movzwl	-46(%ebp),%eax
	orl	$0x0c00,%eax
	movw	%ax,-48(%ebp)

	/* VectorScale/VectorCopy setup is performed on every invocation, including
	   the empty-list case, as in the C reference. */
	flds	C(vright)
	fmuls	C(xscaleshrink)
	fstps	C(r_pright)
	flds	C(vright)+4
	fmuls	C(xscaleshrink)
	fstps	C(r_pright)+4
	flds	C(vright)+8
	fmuls	C(xscaleshrink)
	fstps	C(r_pright)+8
	flds	C(vup)
	fmuls	C(yscaleshrink)
	fstps	C(r_pup)
	flds	C(vup)+4
	fmuls	C(yscaleshrink)
	fstps	C(r_pup)+4
	flds	C(vup)+8
	fmuls	C(yscaleshrink)
	fstps	C(r_pup)+8
	movl	C(vpn),%eax
	movl	%eax,C(r_ppn)
	movl	C(vpn)+4,%eax
	movl	%eax,C(r_ppn)+4
	movl	C(vpn)+8,%eax
	movl	%eax,C(r_ppn)+8

	flds	8(%ebp)
	fstps	-16(%ebp)			// time
	flds	8(%ebp)
	fsubl	12(%ebp)
	fstpt	-60(%ebp)			// retain C's x87-extended expression
	fldt	-60(%ebp)
	fstps	-20(%ebp)			// rounded frametime local used for movement
	fldt	-60(%ebp)
	fmuls	.Lparticle_fifteen
	fstps	-24(%ebp)			// time3
	fldt	-60(%ebp)
	fmuls	.Lparticle_ten
	fstps	-28(%ebp)			// time2
	fldt	-60(%ebp)
	fmuls	.Lparticle_five
	fstps	-32(%ebp)			// time1
	fldt	-60(%ebp)
	fmuls	20(%ebp)
	fmull	.Lparticle_point_zero_five
	fstps	-36(%ebp)			// grav
	fldt	-60(%ebp)
	fmuls	.Lparticle_four
	fstps	-40(%ebp)			// dvel

	leal	C(active_particles),%esi	// link = &active_particles
.Lparticle_loop:
	movl	(%esi),%ebx
	testl	%ebx,%ebx
	jz	.Lparticle_return

	/* C: if (p->die < time), with unordered comparisons taking the live path. */
	flds	-16(%ebp)
	fcomps	pt_die(%ebx)
	fnstsw	%ax
	sahf
	jp	.Lparticle_live
	ja	.Lparticle_remove
	jmp	.Lparticle_live

.Lparticle_remove:
	movl	pt_next(%ebx),%eax
	movl	%eax,(%esi)
	movl	C(free_particles),%eax
	movl	%eax,pt_next(%ebx)
	movl	%ebx,C(free_particles)
	jmp	.Lparticle_loop

.Lparticle_live:
#ifdef PROFILE486
	movl	24(%ebp),%eax
	addl	$1,(%eax)
	cmpb	$PT_GRAV,pt_type(%ebx)
	jne	.Lparticle_profile_done
	movl	28(%ebp),%eax
	addl	$1,(%eax)
.Lparticle_profile_done:
#endif
	pushl	%ebx
	call	C(D_DrawParticle)
	addl	$4,%esp

	/* The optional reference optimization avoids two zero-velocity updates
	   for pt_grav blood trails. */
#ifdef ASM486_GIB_TRAIL_SKIP_ZERO_XY
	cmpb	$PT_GRAV,pt_type(%ebx)
	jne	.Lparticle_move_all
	flds	pt_vel+8(%ebx)
	fmuls	-20(%ebp)
	fadds	pt_org+8(%ebx)
	fstps	pt_org+8(%ebx)
#ifdef QUAKE2
	flds	pt_vel+8(%ebx)
	flds	-36(%ebp)
	fmuls	.Lparticle_twenty
	fsubrp	%st,%st(1)
#else
	flds	pt_vel+8(%ebx)
	fsubs	-36(%ebp)
#endif
	fstps	pt_vel+8(%ebx)
	leal	pt_next(%ebx),%esi
	jmp	.Lparticle_loop
.Lparticle_move_all:
#endif

	/* All live particles move before their type-specific velocity update. */
	flds	pt_vel(%ebx)
	fmuls	-20(%ebp)
	fadds	pt_org(%ebx)
	fstps	pt_org(%ebx)
	flds	pt_vel+4(%ebx)
	fmuls	-20(%ebp)
	fadds	pt_org+4(%ebx)
	fstps	pt_org+4(%ebx)
	flds	pt_vel+8(%ebx)
	fmuls	-20(%ebp)
	fadds	pt_org+8(%ebx)
	fstps	pt_org+8(%ebx)

	cmpb	$PT_STATIC,pt_type(%ebx)
	je	.Lparticle_next
	cmpb	$PT_FIRE,pt_type(%ebx)
	je	.Lparticle_fire
	cmpb	$PT_EXPLODE,pt_type(%ebx)
	je	.Lparticle_explode
	cmpb	$PT_EXPLODE2,pt_type(%ebx)
	je	.Lparticle_explode2
	cmpb	$PT_BLOB,pt_type(%ebx)
	je	.Lparticle_blob
	cmpb	$PT_BLOB2,pt_type(%ebx)
	je	.Lparticle_blob2
	cmpb	$PT_GRAV,pt_type(%ebx)
	je	.Lparticle_grav
	cmpb	$PT_SLOWGRAV,pt_type(%ebx)
	je	.Lparticle_slowgrav
	jmp	.Lparticle_next

.Lparticle_fire:
	flds	pt_ramp(%ebx)
	fadds	-32(%ebp)
	fstps	pt_ramp(%ebx)
	flds	pt_ramp(%ebx)
	fcomps	.Lparticle_six
	fnstsw	%ax
	sahf
	jp	.Lparticle_fire_color
	jae	.Lparticle_ramp_dead
.Lparticle_fire_color:
	flds	pt_ramp(%ebx)
	fldcw	-48(%ebp)
	fistpl	-44(%ebp)
	fldcw	-46(%ebp)
	movl	-44(%ebp),%eax
	movb	C(ramp3)(,%eax,4),%al
	movb	%al,pt_color(%ebx)
	jmp	.Lparticle_fire_gravity

.Lparticle_ramp_dead:
	movl	$0xbf800000,pt_die(%ebx)
.Lparticle_fire_gravity:
	flds	pt_vel+8(%ebx)
	fadds	-36(%ebp)
	fstps	pt_vel+8(%ebx)
	jmp	.Lparticle_next

.Lparticle_explode:
	flds	pt_ramp(%ebx)
	fadds	-28(%ebp)
	fstps	pt_ramp(%ebx)
	flds	pt_ramp(%ebx)
	fcomps	.Lparticle_eight
	fnstsw	%ax
	sahf
	jp	.Lparticle_explode_color
	jae	.Lparticle_ramp_dead_explode
.Lparticle_explode_color:
	flds	pt_ramp(%ebx)
	fldcw	-48(%ebp)
	fistpl	-44(%ebp)
	fldcw	-46(%ebp)
	movl	-44(%ebp),%eax
	movb	C(ramp1)(,%eax,4),%al
	movb	%al,pt_color(%ebx)
	jmp	.Lparticle_explode_velocity
.Lparticle_ramp_dead_explode:
	movl	$0xbf800000,pt_die(%ebx)
.Lparticle_explode_velocity:
	/* GCC -ffast-math folds v += v*dvel into v *= 1+dvel. */
	flds	-40(%ebp)
	fadds	.Lparticle_one
	fld	%st(0)
	fmuls	pt_vel(%ebx)
	fstps	pt_vel(%ebx)
	fld	%st(0)
	fmuls	pt_vel+4(%ebx)
	fstps	pt_vel+4(%ebx)
	fld	%st(0)
	fmuls	pt_vel+8(%ebx)
	/* C retains the Z product in x87 precision through the gravity subtraction. */
	fsubs	-36(%ebp)
	fstps	pt_vel+8(%ebx)
	fstp	%st(0)
	jmp	.Lparticle_next

.Lparticle_explode2:
	flds	pt_ramp(%ebx)
	fadds	-24(%ebp)
	fstps	pt_ramp(%ebx)
	flds	pt_ramp(%ebx)
	fcomps	.Lparticle_eight
	fnstsw	%ax
	sahf
	jp	.Lparticle_explode2_color
	jae	.Lparticle_ramp_dead_explode2
.Lparticle_explode2_color:
	flds	pt_ramp(%ebx)
	fldcw	-48(%ebp)
	fistpl	-44(%ebp)
	fldcw	-46(%ebp)
	movl	-44(%ebp),%eax
	movb	C(ramp2)(,%eax,4),%al
	movb	%al,pt_color(%ebx)
	jmp	.Lparticle_explode2_velocity
.Lparticle_ramp_dead_explode2:
	movl	$0xbf800000,pt_die(%ebx)
.Lparticle_explode2_velocity:
	/* Match GCC's v *= 1-frametime sequence, retaining the x87 value. */
	fldt	-60(%ebp)
	fld1
	fsubp	%st,%st(1)
	fld	%st(0)
	fmuls	pt_vel(%ebx)
	fstps	pt_vel(%ebx)
	fld	%st(0)
	fmuls	pt_vel+4(%ebx)
	fstps	pt_vel+4(%ebx)
	fld	%st(0)
	fmuls	pt_vel+8(%ebx)
	/* Match C's single final store after the following gravity subtraction. */
	fsubs	-36(%ebp)
	fstps	pt_vel+8(%ebx)
	fstp	%st(0)
	jmp	.Lparticle_next

.Lparticle_blob:
	/* GCC -ffast-math folds v += v*dvel into v *= 1+dvel. */
	flds	-40(%ebp)
	fadds	.Lparticle_one
	fld	%st(0)
	fmuls	pt_vel(%ebx)
	fstps	pt_vel(%ebx)
	fld	%st(0)
	fmuls	pt_vel+4(%ebx)
	fstps	pt_vel+4(%ebx)
	fld	%st(0)
	fmuls	pt_vel+8(%ebx)
	/* C retains the Z product in x87 precision through the gravity subtraction. */
	fsubs	-36(%ebp)
	fstps	pt_vel+8(%ebx)
	fstp	%st(0)
	jmp	.Lparticle_next

.Lparticle_blob2:
	/* Match GCC's v *= 1-dvel sequence. */
	flds	-40(%ebp)
	fld1
	fsubp	%st,%st(1)
	fld	%st(0)
	fmuls	pt_vel(%ebx)
	fstps	pt_vel(%ebx)
	fld	%st(0)
	fmuls	pt_vel+4(%ebx)
	fstps	pt_vel+4(%ebx)
	fstp	%st(0)
	flds	pt_vel+8(%ebx)
	fsubs	-36(%ebp)
	fstps	pt_vel+8(%ebx)
	jmp	.Lparticle_next

.Lparticle_grav:
#ifdef QUAKE2
	flds	pt_vel+8(%ebx)
	flds	-36(%ebp)
	fmuls	.Lparticle_twenty
	fsubrp	%st,%st(1)
	fstps	pt_vel+8(%ebx)
	jmp	.Lparticle_next
#else
	jmp	.Lparticle_slowgrav
#endif
.Lparticle_slowgrav:
	flds	pt_vel+8(%ebx)
	fsubs	-36(%ebp)
	fstps	pt_vel+8(%ebx)

.Lparticle_next:
	leal	pt_next(%ebx),%esi
	jmp	.Lparticle_loop

.Lparticle_return:
	fldcw	-46(%ebp)
	leal	-12(%ebp),%esp
	popl	%edi
	popl	%esi
	popl	%ebx
	popl	%ebp
	ret
#endif

#if defined(ASM486_CHASE) || defined(ASM486_HULLCHECK)
#include "sv_hullcheck_asm.inc"
#endif

#if defined(ASM486_HULL_FOR_ENTITY) && !defined(QUAKE2)
#include "sv_hullforentity_asm.inc"
#endif

#if defined(ASM486_CLIP_MOVE_TO_ENTITY) && !defined(QUAKE2)
#include "sv_clipmovetoentity_asm.inc"
#endif

#if defined(ASM486_CLIP_TO_LINKS) && !defined(QUAKE2)
#include "sv_cliptolinks_asm.inc"
#endif

#if defined(ASM486_FIND_TOUCHED_LEAFS) && !defined(QUAKE2)
#include "sv_findtouchedleafs_asm.inc"
#endif
