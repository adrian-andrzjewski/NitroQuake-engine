// r_lightasm.s
//
// i486 assembly implementation of the renderer's BSP dynamic-light marking
// walk. Arithmetic order and the existing plane / lightmap-rectangle culls
// follow R_MarkLights_C in r_light.c. The fourth internal argument carries
// the surface array so recursive calls do not depend on client-state offsets.

#include "asm_i386.h"
#include "renderer/asm_light.h"

#ifdef BENCH486
#include "tests/bench486/bench486_light_probe.h"
#endif

#ifdef ASM486_MARK_LIGHTS

        .extern C(r_dlightframecount)
#ifdef BENCH486
        .extern C(bench486_mark_lights_probe)
#endif

        .text
        .p2align 4,,15

        .set ML_NODE,              -16
        .set ML_LIGHT,             -20
        .set ML_BIT,               -24
        .set ML_SURFACES,          -28
        .set ML_DIST,              -32
        .set ML_NEG_RADIUS,        -36
        .set ML_SPLITPLANE,        -40
        .set ML_SURF,              -44
        .set ML_SURF_LEFT,         -48
        .set ML_SURF_PLANE,        -52
        .set ML_PLANEDIST,         -56
        .set ML_RAD,               -60
        .set ML_FMIN,              -64
        .set ML_FMIN_SCALED,       -68
        .set ML_IMPACT0,           -72
        .set ML_IMPACT1,           -76
        .set ML_IMPACT2,           -80
        .set ML_LOCAL0,            -84
        .set ML_LOCAL1,            -88
        .set ML_CS,                -92
        .set ML_CT,                -96
        .set ML_SD,               -100
        .set ML_TD,               -104
        .set ML_IDIST,            -108
        .set ML_TEXINFO,          -112
        .set ML_CW,               -116
        .set ML_CW_UP,            -118
        .set ML_CW_TRUNC,         -120
#ifdef BENCH486
        .set ML_PROBE,            -124
#endif

// void R_MarkLightsTree_asm486(dlight_t *light, int bit, mnode_t *node,
//                              msurface_t *surfaces)
// Callee-saved registers: EBX=node, ESI=surface base, EDI=light.
// Every float assigned to a C float local is rounded through an FSTP m32.
C(R_MarkLightsTree_asm486):
        .globl C(R_MarkLightsTree_asm486)
        pushl   %ebp
        movl    %esp,%ebp
        pushl   %ebx
        pushl   %esi
        pushl   %edi
#ifdef BENCH486
        subl    $112,%esp
#else
        subl    $108,%esp
#endif

        movl    8(%ebp),%edi
        movl    %edi,ML_LIGHT(%ebp)
        movl    12(%ebp),%eax
        movl    %eax,ML_BIT(%ebp)
        movl    16(%ebp),%ebx
        movl    %ebx,ML_NODE(%ebp)
        movl    20(%ebp),%esi
        movl    %esi,ML_SURFACES(%ebp)

        cmpl    $0,ml_node_contents(%ebx)
        js      .Lmark_lights_return

        movl    ml_node_plane(%ebx),%eax
        movl    %eax,ML_SPLITPLANE(%ebp)

        // dist = DotProduct(light->origin, plane->normal) - plane->dist.
        flds   ml_dlight_origin(%edi)
        fmuls   ml_plane_normal(%eax)
        flds   ml_dlight_origin+4(%edi)
        fmuls   ml_plane_normal+4(%eax)
        faddp   %st(0),%st(1)
        flds   ml_dlight_origin+8(%edi)
        fmuls   ml_plane_normal+8(%eax)
        faddp   %st(0),%st(1)
        fsubs   ml_plane_dist(%eax)
        fstps   ML_DIST(%ebp)

        // The strict comparisons preserve the original front/back ownership
        // when the light sphere just touches the node plane.
        flds   ML_DIST(%ebp)
        fcomps  ml_dlight_radius(%edi)
        fnstsw  %ax
        sahf
        ja      .Lmark_lights_front_only

        flds   ml_dlight_radius(%edi)
        fchs
        fstps   ML_NEG_RADIUS(%ebp)
        flds   ML_DIST(%ebp)
        fcomps  ML_NEG_RADIUS(%ebp)
        fnstsw  %ax
        sahf
        jb      .Lmark_lights_back_only

        // Node plane intersects the light. Visit its surfaces before children.
        movzwl  ml_node_firstsurface(%ebx),%eax
        shll    $6,%eax
        leal    (%esi,%eax),%eax
        movl    %eax,ML_SURF(%ebp)
        movzwl  ml_node_numsurfaces(%ebx),%eax
        movl    %eax,ML_SURF_LEFT(%ebp)

.Lmark_lights_surface_loop:
        cmpl    $0,ML_SURF_LEFT(%ebp)
        jle     .Lmark_lights_recurse_both

        movl    ML_SURF(%ebp),%edx
#ifdef BENCH486
        // BENCH-only per-surface diagnostics; excluded from release code.
        movl    C(bench486_mark_lights_probe),%eax
        testl   %eax,%eax
        jz      .Lmark_lights_probe_ready
        movl    %edx,%ecx
        subl    %esi,%ecx
        shrl    $6,%ecx
        imull   $ml_probe_size,%ecx,%ecx
        addl    %ecx,%eax
        movl    %eax,ML_PROBE(%ebp)
        movl    $1,ml_probe_stage(%eax)
        jmp     .Lmark_lights_probe_done
.Lmark_lights_probe_ready:
        movl    $0,ML_PROBE(%ebp)
.Lmark_lights_probe_done:
#endif
        movl    ml_surface_plane(%edx),%eax
        movl    %eax,ML_SURF_PLANE(%ebp)

        // planedist = DotProduct(light origin, surface normal) - plane dist.
        flds   ml_dlight_origin(%edi)
        fmuls   ml_plane_normal(%eax)
        flds   ml_dlight_origin+4(%edi)
        fmuls   ml_plane_normal+4(%eax)
        faddp   %st(0),%st(1)
        flds   ml_dlight_origin+8(%edi)
        fmuls   ml_plane_normal+8(%eax)
        faddp   %st(0),%st(1)
        fsubs   ml_plane_dist(%eax)
        fstps   ML_PLANEDIST(%ebp)
#ifdef BENCH486
        movl    ML_PROBE(%ebp),%eax
        testl   %eax,%eax
        jz      .Lmark_lights_probe_no_planedist
        flds    ML_PLANEDIST(%ebp)
        fstps   ml_probe_planedist(%eax)
.Lmark_lights_probe_no_planedist:
#endif

        // rad = radius - fabs(planedist); faces below minlight cannot receive
        // this light and keep their current cache state.
        flds   ml_dlight_radius(%edi)
        flds   ML_PLANEDIST(%ebp)
        fabs
        fsubrp  %st(0),%st(1)
        fstps   ML_RAD(%ebp)
#ifdef BENCH486
        movl    ML_PROBE(%ebp),%eax
        testl   %eax,%eax
        jz      .Lmark_lights_probe_no_rad
        flds    ML_RAD(%ebp)
        fstps   ml_probe_rad(%eax)
.Lmark_lights_probe_no_rad:
#endif
        flds   ML_RAD(%ebp)
        fcomps  ml_dlight_minlight(%edi)
        fnstsw  %ax
        sahf
        jb      .Lmark_lights_rad_reject

        // fmin_scaled = ceil((rad - minlight) * 256).  Change only the x87
        // rounding-control bits and restore the caller's word immediately.
        flds   ML_RAD(%ebp)
        fsubs   ml_dlight_minlight(%edi)
        fstps   ML_FMIN(%ebp)
        fnstcw  ML_CW(%ebp)
        movw    ML_CW(%ebp),%ax
        andw    $0xf3ff,%ax
        orw     $0x0800,%ax
        movw    %ax,ML_CW_UP(%ebp)
        fldcw   ML_CW_UP(%ebp)
        flds   ML_FMIN(%ebp)
        fmuls   .Lmark_lights_256
        frndint
        fistpl  ML_FMIN_SCALED(%ebp)
        fldcw   ML_CW(%ebp)
#ifdef BENCH486
        movl    ML_PROBE(%ebp),%eax
        testl   %eax,%eax
        jz      .Lmark_lights_probe_no_fmin
        flds    ML_FMIN(%ebp)
        fstps   ml_probe_fmin(%eax)
        movl    ML_FMIN_SCALED(%ebp),%ecx
        movl    %ecx,ml_probe_fmin_scaled(%eax)
        movl    $3,ml_probe_stage(%eax)
.Lmark_lights_probe_no_fmin:
#endif

        // impact = light origin - surface normal * planedist.
        movl    ML_SURF_PLANE(%ebp),%eax
        flds   ml_dlight_origin(%edi)
        flds   ml_plane_normal(%eax)
        fmuls   ML_PLANEDIST(%ebp)
        fsubrp  %st(0),%st(1)
        fstps   ML_IMPACT0(%ebp)
        flds   ml_dlight_origin+4(%edi)
        flds   ml_plane_normal+4(%eax)
        fmuls   ML_PLANEDIST(%ebp)
        fsubrp  %st(0),%st(1)
        fstps   ML_IMPACT1(%ebp)
        flds   ml_dlight_origin+8(%edi)
        flds   ml_plane_normal+8(%eax)
        fmuls   ML_PLANEDIST(%ebp)
        fsubrp  %st(0),%st(1)
        fstps   ML_IMPACT2(%ebp)

        movl    ML_SURF(%ebp),%edx
        movl    ml_surface_texinfo(%edx),%eax
        movl    %eax,ML_TEXINFO(%ebp)

        // Convert the impact point to lightmap-local s/t coordinates.
        flds   ML_IMPACT0(%ebp)
        fmuls   ml_texinfo_vecs(%eax)
        flds   ML_IMPACT1(%ebp)
        fmuls   ml_texinfo_vecs+4(%eax)
        faddp   %st(0),%st(1)
        flds   ML_IMPACT2(%ebp)
        fmuls   ml_texinfo_vecs+8(%eax)
        faddp   %st(0),%st(1)
        fadds   ml_texinfo_vecs+12(%eax)
        fisubs  ml_surface_texturemins(%edx)
        fstps   ML_LOCAL0(%ebp)
#ifdef BENCH486
        movl    ML_PROBE(%ebp),%ecx
        testl   %ecx,%ecx
        jz      .Lmark_lights_probe_no_local0
        flds    ML_LOCAL0(%ebp)
        fstps   ml_probe_local0(%ecx)
.Lmark_lights_probe_no_local0:
#endif

        flds   ML_IMPACT0(%ebp)
        fmuls   ml_texinfo_vecs+16(%eax)
        flds   ML_IMPACT1(%ebp)
        fmuls   ml_texinfo_vecs+20(%eax)
        faddp   %st(0),%st(1)
        flds   ML_IMPACT2(%ebp)
        fmuls   ml_texinfo_vecs+24(%eax)
        faddp   %st(0),%st(1)
        fadds   ml_texinfo_vecs+28(%eax)
        fisubs  ml_surface_texturemins+2(%edx)
        fstps   ML_LOCAL1(%ebp)
#ifdef BENCH486
        movl    ML_PROBE(%ebp),%eax
        testl   %eax,%eax
        jz      .Lmark_lights_probe_no_local1
        flds    ML_LOCAL1(%ebp)
        fstps   ml_probe_local1(%eax)
.Lmark_lights_probe_no_local1:
#endif

        // Clamp the impact point to the lightmap rectangle. Keep the same
        // sequential comparisons as the C source, including zero extents.
        flds   ML_LOCAL0(%ebp)
        ftst
        fnstsw  %ax
        sahf
        fstp    %st(0)
        jb      .Lmark_lights_cs_zero
        filds   ml_surface_extents(%edx)
        fcomps  ML_LOCAL0(%ebp)
        fnstsw  %ax
        sahf
        jb      .Lmark_lights_cs_extent
        movl    ML_LOCAL0(%ebp),%eax
        movl    %eax,ML_CS(%ebp)
        jmp     .Lmark_lights_clamp_t
.Lmark_lights_cs_zero:
        movl    $0,ML_CS(%ebp)
        jmp     .Lmark_lights_clamp_t
.Lmark_lights_cs_extent:
        filds   ml_surface_extents(%edx)
        fstps   ML_CS(%ebp)

.Lmark_lights_clamp_t:
#ifdef BENCH486
        movl    ML_PROBE(%ebp),%eax
        testl   %eax,%eax
        jz      .Lmark_lights_probe_no_cs
        flds    ML_CS(%ebp)
        fstps   ml_probe_cs(%eax)
.Lmark_lights_probe_no_cs:
#endif
        flds   ML_LOCAL1(%ebp)
        ftst
        fnstsw  %ax
        sahf
        fstp    %st(0)
        jb      .Lmark_lights_ct_zero
        filds   ml_surface_extents+2(%edx)
        fcomps  ML_LOCAL1(%ebp)
        fnstsw  %ax
        sahf
        jb      .Lmark_lights_ct_extent
        movl    ML_LOCAL1(%ebp),%eax
        movl    %eax,ML_CT(%ebp)
        jmp     .Lmark_lights_distance
.Lmark_lights_ct_zero:
        movl    $0,ML_CT(%ebp)
        jmp     .Lmark_lights_distance
.Lmark_lights_ct_extent:
        filds   ml_surface_extents+2(%edx)
        fstps   ML_CT(%ebp)

.Lmark_lights_distance:
#ifdef BENCH486
        movl    ML_PROBE(%ebp),%eax
        testl   %eax,%eax
        jz      .Lmark_lights_probe_no_ct
        flds    ML_CT(%ebp)
        fstps   ml_probe_ct(%eax)
.Lmark_lights_probe_no_ct:
#endif
        // C float-to-int conversion truncates toward zero, independent of the
        // current x87 rounding mode. Preserve the ambient control word.
        movw    ML_CW(%ebp),%ax
        andw    $0xf3ff,%ax
        orw     $0x0c00,%ax
        movw    %ax,ML_CW_TRUNC(%ebp)
        fldcw   ML_CW_TRUNC(%ebp)
        flds   ML_LOCAL0(%ebp)
        fsubs   ML_CS(%ebp)
        fistpl  ML_SD(%ebp)
        fldcw   ML_CW(%ebp)
        cmpl    $0,ML_SD(%ebp)
        jge     .Lmark_lights_sd_abs
        negl    ML_SD(%ebp)
.Lmark_lights_sd_abs:
        fldcw   ML_CW_TRUNC(%ebp)
        flds   ML_LOCAL1(%ebp)
        fsubs   ML_CT(%ebp)
        fistpl  ML_TD(%ebp)
        fldcw   ML_CW(%ebp)
        cmpl    $0,ML_TD(%ebp)
        jge     .Lmark_lights_td_abs
        negl    ML_TD(%ebp)
.Lmark_lights_td_abs:

        // idist = max(sd,td) + min(sd,td)/2, then reject at the source's
        // strict fixed-point cutoff.
        movl    ML_SD(%ebp),%eax
        cmpl    ML_TD(%ebp),%eax
        jg      .Lmark_lights_sd_major
        movl    ML_TD(%ebp),%eax
        movl    ML_SD(%ebp),%ecx
        sarl    $1,%ecx
        addl    %ecx,%eax
        jmp     .Lmark_lights_idist_ready
.Lmark_lights_sd_major:
        movl    ML_TD(%ebp),%ecx
        sarl    $1,%ecx
        addl    %ecx,%eax
.Lmark_lights_idist_ready:
        movl    %eax,ML_IDIST(%ebp)
#ifdef BENCH486
        movl    ML_PROBE(%ebp),%ecx
        testl   %ecx,%ecx
        jz      .Lmark_lights_probe_no_idist
        movl    ML_SD(%ebp),%edx
        movl    %edx,ml_probe_sd(%ecx)
        movl    ML_TD(%ebp),%edx
        movl    %edx,ml_probe_td(%ecx)
        movl    ML_IDIST(%ebp),%edx
        movl    %edx,ml_probe_idist(%ecx)
        movl    $4,ml_probe_stage(%ecx)
        movl    $0,ml_probe_marked(%ecx)
.Lmark_lights_probe_no_idist:
#endif
        shll    $8,%eax
        cmpl    ML_FMIN_SCALED(%ebp),%eax
        jae     .Lmark_lights_next_surface

        // A stale surface starts a fresh bitset for this dlight frame.
        movl    ML_SURF(%ebp),%edx
        movl    C(r_dlightframecount),%ecx
        cmpl    %ecx,ml_surface_dlightframe(%edx)
        je      .Lmark_lights_or_bit
        movl    %ecx,ml_surface_dlightframe(%edx)
        movl    $0,ml_surface_dlightbits(%edx)
.Lmark_lights_or_bit:
        movl    ML_BIT(%ebp),%eax
        orl     %eax,ml_surface_dlightbits(%edx)
#ifdef BENCH486
        movl    ML_PROBE(%ebp),%eax
        testl   %eax,%eax
        jz      .Lmark_lights_probe_no_mark
        movl    $5,ml_probe_stage(%eax)
        movl    $1,ml_probe_marked(%eax)
.Lmark_lights_probe_no_mark:
#endif

.Lmark_lights_next_surface:
.Lmark_lights_advance_surface:
#ifdef BENCH486
        movl    ML_PROBE(%ebp),%eax
        testl   %eax,%eax
        jz      .Lmark_lights_probe_no_advance
.Lmark_lights_probe_no_advance:
#endif
        addl    $ml_surface_size,ML_SURF(%ebp)
        decl    ML_SURF_LEFT(%ebp)
        jmp     .Lmark_lights_surface_loop

.Lmark_lights_rad_reject:
#ifdef BENCH486
        movl    ML_PROBE(%ebp),%eax
        testl   %eax,%eax
        jz      .Lmark_lights_rad_reject_no_probe
        movl    $2,ml_probe_stage(%eax)
.Lmark_lights_rad_reject_no_probe:
#endif
        jmp     .Lmark_lights_advance_surface

.Lmark_lights_front_only:
        movl    ML_NODE(%ebp),%ebx
        movl    ml_node_children(%ebx),%eax
        pushl   ML_SURFACES(%ebp)
        pushl   %eax
        pushl   ML_BIT(%ebp)
        pushl   ML_LIGHT(%ebp)
        call    C(R_MarkLightsTree_asm486)
        addl    $16,%esp
        jmp     .Lmark_lights_return

.Lmark_lights_back_only:
        movl    ML_NODE(%ebp),%ebx
        movl    ml_node_children+4(%ebx),%eax
        pushl   ML_SURFACES(%ebp)
        pushl   %eax
        pushl   ML_BIT(%ebp)
        pushl   ML_LIGHT(%ebp)
        call    C(R_MarkLightsTree_asm486)
        addl    $16,%esp
        jmp     .Lmark_lights_return

.Lmark_lights_recurse_both:
        movl    ML_NODE(%ebp),%ebx
        movl    ml_node_children(%ebx),%eax
        pushl   ML_SURFACES(%ebp)
        pushl   %eax
        pushl   ML_BIT(%ebp)
        pushl   ML_LIGHT(%ebp)
        call    C(R_MarkLightsTree_asm486)
        addl    $16,%esp

        movl    ML_NODE(%ebp),%ebx
        movl    ml_node_children+4(%ebx),%eax
        pushl   ML_SURFACES(%ebp)
        pushl   %eax
        pushl   ML_BIT(%ebp)
        pushl   ML_LIGHT(%ebp)
        call    C(R_MarkLightsTree_asm486)
        addl    $16,%esp

.Lmark_lights_return:
        leal    -12(%ebp),%esp
        popl    %edi
        popl    %esi
        popl    %ebx
        popl    %ebp
        ret

        .section .rodata
        .p2align 2
.Lmark_lights_256:
        .float   256.0

#endif

// void R_PushDlights_asm486(double time, int frameCount,
//                           dlight_t *lights, mnode_t *world)
// The C wrapper supplies the view time and world root without exposing client
// or model structure offsets here.  ESI walks the 32 fixed-size lights, EDI is
// the bit index, and EBX holds the world root across R_MarkLights calls.
// The deadline comparison promotes float die to the same double domain as
// cl.time.  FCOMPP/FNSTSW/SAHF and FTST preserve the original C predicates;
// all opcodes in this loop predate the 486.
#ifdef ASM486_DYNAMIC_LIGHT_PUSH
        .text
        .p2align 4,,15
C(R_PushDlights_asm486):
        .globl C(R_PushDlights_asm486)
        pushl   %ebp
        movl    %esp,%ebp
        pushl   %ebx
        pushl   %esi
        pushl   %edi

        movl    16(%ebp),%eax
        incl    %eax
        movl    %eax,C(r_dlightframecount)

        movl    20(%ebp),%esi
        movl    24(%ebp),%ebx
        xorl    %edi,%edi

.Lpush_dlights_loop:
        // C tests float die < double cl.time.  Load time first and die second
        // so ST(0) is die when FCOMPP compares ST(0) against ST(1).
        fldl    8(%ebp)
        flds    ml_dlight_die(%esi)
        fcompp
        fnstsw  %ax
        sahf
        jp      .Lpush_dlights_check_radius
        jb      .Lpush_dlights_next

.Lpush_dlights_check_radius:
        flds    ml_dlight_radius(%esi)
        ftst
        fnstsw  %ax
        sahf
        fstp    %st(0)
        jp      .Lpush_dlights_mark
        jz      .Lpush_dlights_next

.Lpush_dlights_mark:
        movl    %edi,%ecx
        movl    $1,%eax
        shll    %cl,%eax
        pushl   %ebx
        pushl   %eax
        pushl   %esi
        call    C(R_MarkLights)
        addl    $12,%esp

.Lpush_dlights_next:
        addl    $ml_dlight_size,%esi
        incl    %edi
        cmpl    $32,%edi
        jne     .Lpush_dlights_loop

        leal    -12(%ebp),%esp
        popl    %edi
        popl    %esi
        popl    %ebx
        popl    %ebp
        ret
#endif
