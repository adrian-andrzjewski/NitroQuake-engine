/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
// asm486_bsp.s
// BSP traversal and frustum clipping routines.

#include "asm_i386.h"
#include "renderer/d_ifacea.h"
#include "renderer/asm_draw.h"

.data

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

#ifdef ASM486_BSP_WALK
.section .rodata
.p2align 3
.Lbsp_walk_negative_backface_epsilon:
	.double -0.01
.Lbsp_walk_positive_backface_epsilon:
	.double 0.01
#endif
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

	.equ BSP_WALK_RECORD_BYTES, 20

// void R_RecursiveWorldNode_asm486(mnode_t *node, int clipflags)
// regparm(2): EAX=node and EDX=clipflags.  Use explicit records on the
// caller's stack to keep depth-first order without a function call per child.
// A parent record holds its front-to-back continuation while both subtrees
// are visited. EBX keeps the current node and EDI its clip flags across child
// transitions; ESI carries the pending side while the parent record is built.
// The plane-dot and frustum helpers keep their reference order.
C(R_RecursiveWorldNode_asm486):
	.globl C(R_RecursiveWorldNode_asm486)
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	subl	$48,%esp
	movl	%esp,-52(%ebp)		// bottom of the explicit continuation stack
	movl	%eax,%ebx			// current node stays in a callee-saved register
	movl	%edx,%edi			// current clip flags stay in a callee-saved register

#ifdef ASM486_BSP_FRAME_COUNT
	movl C(r_framecount),%eax
	movl %eax,-24(%ebp)
#endif
.Lbsp_walk_node_enter:

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

	cmpl	$0,%edi
	je	.Lbsp_walk_clip_done
	pushl	%edi
	pushl	%ebx
	call	C(R_RecursiveWorldNodeClip_asm486)
	addl	$8,%esp
	testl	%eax,%eax
	js	.Lbsp_walk_node_complete
	movl	%eax,%edi
.Lbsp_walk_clip_done:

	cmpl	$0,0(%ebx)
	jl	.Lbsp_walk_leaf

// Internal node: choose the front child from the assembly plane dot.
	movl	24(%ebx),%edx		// node->plane
	BSP_PLANE_DOT %edx
	fstpl	-32(%ebp)
	movl	$1,%esi			// side defaults to back for unordered dot
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
	movl	$0,%esi			// positive or zero
.Lbsp_walk_side_ready:

	// Save the parent continuation, then enter its front child. Record layout:
	// node, clip flags, double plane dot, and traversal state. The state packs
	// side in bit 0 and the resume phase in bit 1: 2/3 waits for front; 4/5
	// waits for back.
	subl	$BSP_WALK_RECORD_BYTES,%esp
	movl	%ebx,0(%esp)
	movl	%edi,4(%esp)			// preserve the parent clip flags
	movl	-32(%ebp),%eax
	movl	%eax,8(%esp)
	movl	-28(%ebp),%eax
	movl	%eax,12(%esp)
	leal	2(%esi),%eax
	movl	%eax,16(%esp)			// side plus front-child resume phase
	movl	%esi,%eax
	movl	28(%ebx,%eax,4),%ebx
	jmp	.Lbsp_walk_node_enter

// Visit this node's marked surfaces in the same order as the C traversal.
.Lbsp_walk_resume_after_front:
	addl	$2,16(%esp)			// parent now awaits its back child
	movl	0(%esp),%ebx
	movl	4(%esp),%edi			// restore parent clip flags
	movl	8(%esp),%eax
	movl	%eax,-32(%ebp)
	movl	12(%esp),%eax
	movl	%eax,-28(%ebp)
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
	movl	%eax,%esi			// keep the sequential surface cursor in a callee-saved register

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
	movl	%edi,%ecx			// current clip flags
	movl	%ecx,(%edx,%eax,8)
	movl	%esi,4(%edx,%eax,8)
	incl	%eax
	movl	%eax,C(numbtofpolys)
	jmp	.Lbsp_walk_surface_next

.Lbsp_walk_render_poly:
	pushl	%edi
	pushl	%esi
	call	C(R_RenderPoly)
	addl	$8,%esp
	jmp	.Lbsp_walk_surface_next

.Lbsp_walk_render_face:
#ifdef PROFILE486
	call	C(R_BspProfileRenderFaceEnter_asm486)
#endif
	pushl	%edi
	pushl	%esi
	call	C(R_RenderFace)
	addl	$8,%esp
#ifdef PROFILE486
	call	C(R_BspProfileRenderFaceLeave_asm486)
#endif

.Lbsp_walk_surface_next:
	addl	$64,%esi
	decl	-40(%ebp)
	jnz	.Lbsp_walk_surface_loop

.Lbsp_walk_surface_sequence_done:
	incl	C(r_currentkey)		// all surfaces on the node share one key

.Lbsp_walk_back_child:
	movl	0(%esp),%ebx			// restore the current node from its continuation
	movl	16(%esp),%eax			// packed side and back-child resume phase
	xorl	$5,%eax			// (side + 4) ^ 5 == !side
	movl	28(%ebx,%eax,4),%ebx
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
	testl	$4,16(%esp)
	jz	.Lbsp_walk_resume_after_front
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
