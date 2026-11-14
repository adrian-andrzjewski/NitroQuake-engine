/*
 * Assembly equivalent of src/renderer/r_part.c:R_RocketTrail.
 *
 * Keep the normalization result and every len decrement rounded through a
 * float stack slot, as in the C locals. In particular, start is the caller's
 * writable vector: it advances only after a particle has been fully emitted.
 * The tracer counter is private to this implementation and advances only for
 * types 3 and 5. A BENCH486 fixture starts both independent counters at zero
 * and compares the two implementations in lockstep before gameplay begins.
 */
#include "asm_i386.h"
#include "quakeasm.h"

#if id386 && (defined(ASM486_ROCKET_TRAIL) || defined(BENCH486))

	.arch i486
	.arch .387
	.code32

	.set rt_particle_org, 0
	.set rt_particle_color, 12
	.set rt_particle_type, 13
	.set rt_particle_next, 16
	.set rt_particle_vel, 20
	.set rt_particle_ramp, 32
	.set rt_particle_die, 36
	.set rt_client_time, 572

	.extern C(active_particles)
	.extern C(free_particles)
	.extern C(vec3_origin)
	.extern C(cl)
	.extern C(ramp3)
	.extern C(VectorNormalize)
#ifdef BENCH486
	.extern C(Bench486RocketTrailRand)
#define ROCKET_TRAIL_RAND C(Bench486RocketTrailRand)
#define RT_TRACERCOUNT C(bench486_rockettrail_asm_tracercount)
#else
	.extern C(rand)
#define ROCKET_TRAIL_RAND C(rand)
#define RT_TRACERCOUNT .Lrt_tracercount
#endif

	.text
	.p2align 4,,15
	.globl C(R_RocketTrail_asm486)
#ifdef ASM486_ROCKET_TRAIL
	.globl C(R_RocketTrail)
C(R_RocketTrail):
#endif
C(R_RocketTrail_asm486):
	/* cdecl: start/end/type at 8/12/16(%ebp); save EBX, ESI, EDI. */
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	subl	$28,%esp

	movl	8(%ebp),%esi			/* caller-owned, advancing start */
	movl	12(%ebp),%ebx			/* read-only end */
	movl	16(%ebp),%eax
	movl	%eax,-16(%ebp)			/* local type */

	/* VectorSubtract(end,start,vec), with each float assignment rounded. */
	flds	0(%ebx)
	fsubs	0(%esi)
	fstps	-40(%ebp)
	flds	4(%ebx)
	fsubs	4(%esi)
	fstps	-36(%ebp)
	flds	8(%ebx)
	fsubs	8(%esi)
	fstps	-32(%ebp)

	/* len = VectorNormalize(vec); round its float result into the C local. */
	leal	-40(%ebp),%eax
	pushl	%eax
	call	C(VectorNormalize)
	addl	$4,%esp
	fstps	-24(%ebp)

	cmpl	$128,-16(%ebp)
	jl	.Lrt_long_step
	movl	$1,-20(%ebp)			/* dec */
	subl	$128,-16(%ebp)			/* normalize encoded effect type once */
	jmp	.Lrt_loop_test
.Lrt_long_step:
	movl	$3,-20(%ebp)

.Lrt_loop_test:
	/* C's len > 0: JBE also exits for zero and unordered (NaN). */
	flds	-24(%ebp)
	ftst
	fnstsw	%ax
	fstp	%st(0)
	sahf
	jbe	.Lrt_return

	/* len -= dec, storing back to the float local before the body. */
	fildl	-20(%ebp)
	fchs
	fadds	-24(%ebp)
	fstps	-24(%ebp)

	/* Stop before touching lists when the pool is exhausted. */
	movl	C(free_particles),%edi
	testl	%edi,%edi
	jz	.Lrt_return

	/* Pop free head, then prepend it to active_particles. */
	movl	rt_particle_next(%edi),%eax
	movl	%eax,C(free_particles)
	movl	C(active_particles),%eax
	movl	%eax,rt_particle_next(%edi)
	movl	%edi,C(active_particles)

	/* VectorCopy(vec3_origin,p->vel): preserve the source global exactly. */
	movl	C(vec3_origin),%eax
	movl	%eax,rt_particle_vel(%edi)
	movl	C(vec3_origin)+4,%eax
	movl	%eax,rt_particle_vel+4(%edi)
	movl	C(vec3_origin)+8,%eax
	movl	%eax,rt_particle_vel+8(%edi)

	/* p->die = cl.time + 2; C stores the double expression as float. */
	fldl	C(cl)+rt_client_time
	faddl	.Lrt_two
	fstps	rt_particle_die(%edi)

	cmpl	$0,-16(%ebp)
	je	.Lrt_type_0
	cmpl	$1,-16(%ebp)
	je	.Lrt_type_1
	cmpl	$2,-16(%ebp)
	je	.Lrt_type_2
	cmpl	$3,-16(%ebp)
	je	.Lrt_type_tracer
	cmpl	$4,-16(%ebp)
	je	.Lrt_type_4
	cmpl	$5,-16(%ebp)
	je	.Lrt_type_tracer
	cmpl	$6,-16(%ebp)
	je	.Lrt_type_6
	jmp	.Lrt_advance_start			/* C default leaves type/org/color/ramp */

.Lrt_type_0:
	call	ROCKET_TRAIL_RAND
	andl	$3,%eax
	pushl	%eax
	fildl	(%esp)
	fstps	rt_particle_ramp(%edi)
	addl	$4,%esp
	movl	C(ramp3)(,%eax,4),%edx
	movb	%dl,rt_particle_color(%edi)
	movb	$3,rt_particle_type(%edi)	/* pt_fire */
	jmp	.Lrt_jitter_six

.Lrt_type_1:
	call	ROCKET_TRAIL_RAND
	andl	$3,%eax
	addl	$2,%eax
	pushl	%eax
	fildl	(%esp)
	fstps	rt_particle_ramp(%edi)
	addl	$4,%esp
	movl	C(ramp3)(,%eax,4),%edx
	movb	%dl,rt_particle_color(%edi)
	movb	$3,rt_particle_type(%edi)	/* pt_fire */
	jmp	.Lrt_jitter_six

.Lrt_type_2:
	movb	$1,rt_particle_type(%edi)	/* pt_grav */
	call	ROCKET_TRAIL_RAND
	andl	$3,%eax
	addl	$67,%eax
	movb	%al,rt_particle_color(%edi)
	jmp	.Lrt_jitter_six

.Lrt_type_4:
	movb	$1,rt_particle_type(%edi)	/* pt_grav */
	call	ROCKET_TRAIL_RAND
	andl	$3,%eax
	addl	$67,%eax
	movb	%al,rt_particle_color(%edi)
	jmp	.Lrt_jitter_six

.Lrt_type_6:
	call	ROCKET_TRAIL_RAND
	andl	$3,%eax
	addl	$152,%eax			/* 9*16 + 8 + (rand()&3) */
	movb	%al,rt_particle_color(%edi)
	movb	$0,rt_particle_type(%edi)	/* pt_static */
	fldl	C(cl)+rt_client_time
	faddl	.Lrt_point_three
	fstps	rt_particle_die(%edi)
	movl	$0,-28(%ebp)
.Lrt_type_6_axis:
	call	ROCKET_TRAIL_RAND
	andl	$15,%eax
	subl	$8,%eax
	pushl	%eax
	movl	-28(%ebp),%ecx
	flds	(%esi,%ecx,4)
	fildl	(%esp)
	faddp	%st(0),%st(1)
	fstps	rt_particle_org(%edi,%ecx,4)
	addl	$4,%esp
	incl	-28(%ebp)
	cmpl	$3,-28(%ebp)
	jl	.Lrt_type_6_axis
	jmp	.Lrt_advance_start

.Lrt_type_tracer:
	fldl	C(cl)+rt_client_time
	faddl	.Lrt_half
	fstps	rt_particle_die(%edi)
	movb	$0,rt_particle_type(%edi)	/* pt_static */
	movl	RT_TRACERCOUNT,%eax		/* color uses count before increment */
	andl	$4,%eax
	shll	$1,%eax
	cmpl	$3,-16(%ebp)
	je	.Lrt_type_3_color
	addl	$230,%eax
	jmp	.Lrt_store_tracer_color
.Lrt_type_3_color:
	addl	$52,%eax
.Lrt_store_tracer_color:
	movb	%al,rt_particle_color(%edi)
	incl	RT_TRACERCOUNT			/* both tracer types share this counter */

	/* VectorCopy(start,p->org), preserving the current three float words. */
	movl	0(%esi),%eax
	movl	%eax,rt_particle_org(%edi)
	movl	4(%esi),%eax
	movl	%eax,rt_particle_org+4(%edi)
	movl	8(%esi),%eax
	movl	%eax,rt_particle_org+8(%edi)

	testl	$1,RT_TRACERCOUNT		/* velocity parity uses count after increment */
	jz	.Lrt_tracer_even
	flds	-36(%ebp)				/* p->vel[0] = 30 * vec[1] */
	fmuls	.Lrt_thirty
	fstps	rt_particle_vel(%edi)
	flds	-40(%ebp)				/* p->vel[1] = 30 * -vec[0] */
	fchs
	fmuls	.Lrt_thirty
	fstps	rt_particle_vel+4(%edi)
	jmp	.Lrt_advance_start
.Lrt_tracer_even:
	flds	-36(%ebp)				/* p->vel[0] = 30 * -vec[1] */
	fchs
	fmuls	.Lrt_thirty
	fstps	rt_particle_vel(%edi)
	flds	-40(%ebp)				/* p->vel[1] = 30 * vec[0] */
	fmuls	.Lrt_thirty
	fstps	rt_particle_vel+4(%edi)
	jmp	.Lrt_advance_start

.Lrt_jitter_six:
	movl	$0,-28(%ebp)
.Lrt_jitter_six_axis:
	call	ROCKET_TRAIL_RAND
	cltd
	movl	$6,%ecx
	idivl	%ecx				/* preserve signed C rand()%6 */
	subl	$3,%edx
	pushl	%edx
	movl	-28(%ebp),%ecx
	flds	(%esi,%ecx,4)
	fildl	(%esp)
	faddp	%st(0),%st(1)
	fstps	rt_particle_org(%edi,%ecx,4)
	addl	$4,%esp
	incl	-28(%ebp)
	cmpl	$3,-28(%ebp)
	jl	.Lrt_jitter_six_axis
	cmpl	$4,-16(%ebp)
	je	.Lrt_type_4_extra_decrement
	jmp	.Lrt_advance_start

.Lrt_type_4_extra_decrement:
	/* The extra len -= 3 follows all three origin assignments. */
	pushl	$3
	fildl	(%esp)
	fchs
	fadds	-24(%ebp)
	fstps	-24(%ebp)
	addl	$4,%esp

.Lrt_advance_start:
	/* VectorAdd(start,vec,start) intentionally mutates the caller's input. */
	flds	0(%esi)
	fadds	-40(%ebp)
	fstps	0(%esi)
	flds	4(%esi)
	fadds	-36(%ebp)
	fstps	4(%esi)
	flds	8(%esi)
	fadds	-32(%ebp)
	fstps	8(%esi)
	jmp	.Lrt_loop_test

.Lrt_return:
	addl	$28,%esp
	popl	%edi
	popl	%esi
	popl	%ebx
	popl	%ebp
	ret

	.section .bss
	.p2align 2
#ifdef BENCH486
	.globl C(bench486_rockettrail_asm_tracercount)
C(bench486_rockettrail_asm_tracercount):
	.long	0
#else
.Lrt_tracercount:
	.long	0
#endif

	.section .rodata
	.p2align 3
.Lrt_two:
	.double	2.0
.Lrt_half:
	.double	0.5
.Lrt_point_three:
	.double	0.3
.Lrt_thirty:
	.float	30.0

#undef ROCKET_TRAIL_RAND
#undef RT_TRACERCOUNT
#endif
