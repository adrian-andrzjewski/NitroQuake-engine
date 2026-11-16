// asm486_alias.s
//
// Hand-written i486 alias-model transforms and clipping.

#include "asm_i386.h"
#include "renderer/d_ifacea.h"
#include "renderer/asm_draw.h"

	.data
	.p2align 4,,15
Lalias_transform_coords:
	.long	0, 0, 0
Lalias_transform_temp:
	.long	0
	.text

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

#define ASM486_ALIAS_MODEL_OCCLUSION 1
#if ASM486_ALIAS_MODEL_OCCLUSION
#define bbox_occ_minx	0
#define bbox_occ_maxx	4
#define bbox_occ_miny	8
#define bbox_occ_maxy	12
#define bbox_occ_maxzi	16
	.extern C(alias_occlusion_projection)
#endif


C(R_AliasCheckBBoxProject_asm486):
	.globl C(R_AliasCheckBBoxProject_asm486)
	pushl	%ebp
	pushl	%edi
	pushl	%esi
	pushl	%ebx
#if ASM486_ALIAS_MODEL_OCCLUSION
	subl	$20,%esp
	movl	C(r_refdef)+bbox_r_fvrectright,%eax
	movl	%eax,bbox_occ_minx(%esp)
	movl	C(r_refdef)+bbox_r_fvrectx,%eax
	movl	%eax,bbox_occ_maxx(%esp)
	movl	C(r_refdef)+bbox_r_fvrectbottom,%eax
	movl	%eax,bbox_occ_miny(%esp)
	movl	C(r_refdef)+bbox_r_fvrecty,%eax
	movl	%eax,bbox_occ_maxy(%esp)
	movl	$0,bbox_occ_maxzi(%esp)
	movl	40(%esp),%esi		// viewaux
	movl	44(%esp),%edi		// viewpts
	movl	48(%esp),%ecx		// numv
#else
	movl	20(%esp),%esi		// viewaux
	movl	24(%esp),%edi		// viewpts
	movl	28(%esp),%ecx		// numv
#endif
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
#if ASM486_ALIAS_MODEL_OCCLUSION
	fcoms	bbox_occ_minx(%esp)
	fnstsw	%ax
	testb	$1,%ah
	jz	.Lalias_bbox_project_occ_minx_done
	fst	bbox_occ_minx(%esp)
.Lalias_bbox_project_occ_minx_done:
	fcoms	bbox_occ_maxx(%esp)
	fnstsw	%ax
	testb	$0x45,%ah
	jnz	.Lalias_bbox_project_occ_maxx_done
	fst	bbox_occ_maxx(%esp)
.Lalias_bbox_project_occ_maxx_done:
#endif
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
#if ASM486_ALIAS_MODEL_OCCLUSION
	fcoms	bbox_occ_miny(%esp)
	fnstsw	%ax
	testb	$1,%ah
	jz	.Lalias_bbox_project_occ_miny_done
	fst	bbox_occ_miny(%esp)
.Lalias_bbox_project_occ_miny_done:
	fcoms	bbox_occ_maxy(%esp)
	fnstsw	%ax
	testb	$0x45,%ah
	jnz	.Lalias_bbox_project_occ_maxy_done
	fst	bbox_occ_maxy(%esp)
.Lalias_bbox_project_occ_maxy_done:
#endif
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
#if ASM486_ALIAS_MODEL_OCCLUSION
	fcoms	bbox_occ_maxzi(%esp)
	fnstsw	%ax
	testb	$0x45,%ah
	jnz	.Lalias_bbox_project_occ_maxzi_done
	fst	bbox_occ_maxzi(%esp)
.Lalias_bbox_project_occ_maxzi_done:
#endif
	fstp	%st(0)			// discard zi

	orl	%ebp,%edx
	andl	%ebp,%ebx

.Lalias_bbox_project_next:
	addl	$bbox_aux_size,%esi
	addl	$bbox_fv_size,%edi
	decl	%ecx
	jnz	.Lalias_bbox_project_loop

.Lalias_bbox_project_done:
#if ASM486_ALIAS_MODEL_OCCLUSION
	flds	bbox_occ_minx(%esp)
	fstps	C(alias_occlusion_projection)+0
	flds	bbox_occ_miny(%esp)
	fstps	C(alias_occlusion_projection)+4
	flds	bbox_occ_maxx(%esp)
	fstps	C(alias_occlusion_projection)+8
	flds	bbox_occ_maxy(%esp)
	fstps	C(alias_occlusion_projection)+12
	flds	bbox_occ_maxzi(%esp)
	fstps	C(alias_occlusion_projection)+16
	addl	$20,%esp
#endif
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
