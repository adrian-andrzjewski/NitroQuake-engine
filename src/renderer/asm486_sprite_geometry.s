// asm486_sprite_geometry.s
//
// i486 sprite beam translation and face clipping routines.

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
