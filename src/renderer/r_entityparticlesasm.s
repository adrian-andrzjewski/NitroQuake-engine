/*
 * Assembly equivalent of src/renderer/r_part.c:R_EntityParticles.
 *
 * The x87 stack follows the i486 C reference's FSIN/FCOS ordering. In
 * particular, keep angle and forward-vector intermediates in x87 registers
 * until the final particle-origin stores; the reference's -ffast-math build
 * does not round those intermediates to float memory locations.
 */
#include "asm_i386.h"
#include "quakeasm.h"

#if id386 && (defined(ASM486_ENTITY_PARTICLES) || defined(BENCH486))

	.arch i486
	.arch .387
	.code32

	.set ep_particle_color, 12
	.set ep_particle_next, 16
	.set ep_particle_die, 36
	.set ep_entity_origin, 84
	.set ep_client_time, 572
	.set ep_vertex_stride, 12
	.set ep_vertex_count, 162
	.set ep_velocity_count, 486

	.extern C(active_particles)
	.extern C(avelocities)
	.extern C(avelocities_initialized)
	.extern C(beamlength)
	.extern C(cl)
	.extern C(free_particles)
	.extern C(r_avertexnormals)
#ifdef BENCH486
	.extern C(Bench486EntityParticlesRand)
#define ENTITY_PARTICLES_RAND C(Bench486EntityParticlesRand)
#else
	.extern C(rand)
#define ENTITY_PARTICLES_RAND C(rand)
#endif

	.text
	.p2align 4,,15
	.globl C(R_EntityParticles_asm486)
#ifdef ASM486_ENTITY_PARTICLES
	.globl C(R_EntityParticles)
#endif
C(R_EntityParticles_asm486):
#ifdef ASM486_ENTITY_PARTICLES
C(R_EntityParticles):
#endif
	/* cdecl entity pointer; ESI and EBX are the only saved working registers. */
	pushl	%esi
	pushl	%ebx
	subl	$20,%esp
	movl	32(%esp),%esi			/* entity_t *ent */
	fldl	C(cl)+ep_client_time
	fstps	12(%esp)			/* C float narrowing: time = cl.time */
	movl	C(avelocities_initialized),%eax
	testl	%eax,%eax
	jne	.Lep_initialized
	xorl	%ebx,%ebx

.Lep_initialize_velocities:
	call	ENTITY_PARTICLES_RAND
	andl	$255,%eax
	/* (rand() & 255) * double 0.01, then the C float array store. */
	movl	%eax,8(%esp)
	fldl	.Lep_hundredth
	fimull	8(%esp)
	fstps	C(avelocities)(,%ebx,4)
	incl	%ebx
	cmpl	$ep_velocity_count,%ebx
	jne	.Lep_initialize_velocities
	movl	$1,C(avelocities_initialized)

.Lep_initialized:
	xorl	%edx,%edx			/* byte offset in avelocities/normals */
	fldl	.Lep_hundredth
	fadds	12(%esp)			/* time + 0.01, held at x87 precision */
	jmp	.Lep_angles

.Lep_emit:
	/* Move the retained die value to ST0 before the single-precision store. */
	fxch	%st(3)
	movl	ep_particle_next(%eax),%ecx
	movl	%ecx,C(free_particles)
	movl	C(active_particles),%ebx
	movl	%ebx,ep_particle_next(%eax)
	movl	%eax,C(active_particles)
	fsts	ep_particle_die(%eax)
	movw	$0x046f,ep_particle_color(%eax)	/* color 0x6f, pt_explode 4 */

	/*
	 * Emit origin[0]. The two adds retain the exact source order:
	 * ent.x + normal.x * 64 + forward.x * beamlength.
	 */
	flds	.Lep_dist
	flds	C(r_avertexnormals)(%edx)
	fmul	%st(1),%st
	fadds	ep_entity_origin(%esi)
	fxch	%st(4)
	fmuls	C(beamlength)
	faddp	%st,%st(4)
	fxch	%st(3)
	fstps	(%eax)

	/* origin[1] = ent.y + normal.y * 64 + forward.y * beamlength. */
	flds	C(beamlength)
	flds	C(r_avertexnormals)+4(%edx)
	fmul	%st(4),%st
	fadds	ep_entity_origin+4(%esi)
	fxch	%st(3)
	fmul	%st(1),%st
	faddp	%st,%st(3)
	fxch	%st(2)
	fstps	4(%eax)

	/* origin[2] = ent.z + normal.z * 64 - sin(pitch) * beamlength. */
	fxch	%st(2)
	fmuls	C(r_avertexnormals)+8(%edx)
	fadds	ep_entity_origin+8(%esi)
	fxch	%st(1)
	fmulp	%st,%st(3)
	fsubp	%st,%st(2)
	fxch	%st(1)
	fstps	8(%eax)

	addl	$ep_vertex_stride,%edx
	cmpl	$(ep_vertex_count*ep_vertex_stride),%edx
	je	.Lep_done

.Lep_angles:
	/* Match the reference's x87 angle and sin/cos sequence exactly. */
	flds	12(%esp)
	flds	C(avelocities)(%edx)
	fmul	%st(1),%st
	fld	%st(0)
	fsin
	fxch	%st(1)
	fcos
	fxch	%st(2)
	fmuls	C(avelocities)+4(%edx)
	fld	%st(0)
	fsin
	fxch	%st(1)
	fcos
	fmul	%st,%st(3)
	fmulp	%st,%st(2)

	movl	C(free_particles),%eax
	testl	%eax,%eax
	jne	.Lep_emit			/* angles are computed before the empty test */
	fstp	%st(0)
	fstp	%st(0)
	fstp	%st(0)
	fstp	%st(0)
	jmp	.Lep_return

.Lep_done:
	fstp	%st(0)			/* discard retained die value */
.Lep_return:
	addl	$20,%esp
	popl	%ebx
	popl	%esi
	ret

	.section .rodata
	.p2align 3
.Lep_hundredth:
	.double	0.01
	.p2align 2
.Lep_dist:
	.float	64.0

#endif
