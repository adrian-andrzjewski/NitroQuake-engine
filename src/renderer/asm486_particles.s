/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
// asm486_particles.s
// Particle update and drawing routines.

#include "asm_i386.h"
#include "renderer/d_ifacea.h"
#include "renderer/asm_draw.h"

.text

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
