// asm486_sprite.s
//
// i486 sprite rendering routines.

#include "asm_i386.h"
#include "renderer/d_ifacea.h"
#include "renderer/asm_draw.h"

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
	cmpl	$0,C(clip_current)
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
