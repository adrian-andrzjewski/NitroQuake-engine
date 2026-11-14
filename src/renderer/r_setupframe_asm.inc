/*
 * R_SetupFrame: per-frame renderer coordination from r_misc.c.
 *
 * This intentionally keeps the original sequence and delegates the same
 * algorithms to the existing AngleVectors, Mod_PointInLeaf, R_ViewChanged,
 * frustum, sky, and drawing setup routines.  The coordinator itself is 32-bit
 * i486 integer code plus 387-compatible x87 operations.  ABI: cdecl, no
 * arguments; EBP is saved, and EAX/ECX/EDX are caller-owned.  Local vrect_t
 * layout and every accessed C structure offset are pinned in asm_viewcontrol.h.
 */
#include "client/asm_viewcontrol.h"

.macro VC_TEST_FLOAT symbol, true_label, false_label
    flds \symbol
    ftst
    fnstsw %ax
    fstp %st(0)
    sahf
    jp \true_label
    jne \true_label
    jmp \false_label
.endm

.text
.p2align 2
.globl _R_SetupFrame
_R_SetupFrame:
    pushl %ebp
    movl %esp,%ebp
    subl $56,%esp

    /* Multiplayer cvar enforcement must precede the frame's variable checks. */
    cmpl $1,_cl+VC_CLIENT_MAXCLIENTS
    jle .Lrsf_singleplayer
    pushl $.Lrsf_zero
    pushl $.Lrsf_draworder
    call _Cvar_Set
    addl $8,%esp
    pushl $.Lrsf_zero
    pushl $.Lrsf_fullbright
    call _Cvar_Set
    addl $8,%esp
    pushl $.Lrsf_zero
    pushl $.Lrsf_ambient
    call _Cvar_Set
    addl $8,%esp
    pushl $.Lrsf_zero
    pushl $.Lrsf_drawflat
    call _Cvar_Set
    addl $8,%esp
.Lrsf_singleplayer:

    /* Optional counters keep the reference's pointer-difference units. */
    VC_TEST_FLOAT _r_numsurfs+VC_CVAR_VALUE,.Lrsf_report_surfaces,.Lrsf_skip_surfaces
.Lrsf_report_surfaces:
    movl _surface_p,%eax
    subl _surfaces,%eax
    sarl $6,%eax
    movl %eax,%ecx
    cmpl _r_maxsurfsseen,%eax
    jle .Lrsf_surface_max_ready
    movl %eax,_r_maxsurfsseen
.Lrsf_surface_max_ready:
    movl _surf_max,%edx
    subl _surfaces,%edx
    sarl $6,%edx
    pushl _r_maxsurfsseen
    pushl %edx
    pushl %ecx
    pushl $.Lrsf_surface_format
    call _Con_Printf
    addl $16,%esp
.Lrsf_skip_surfaces:
    VC_TEST_FLOAT _r_numedges+VC_CVAR_VALUE,.Lrsf_report_edges,.Lrsf_skip_edges
.Lrsf_report_edges:
    movl _edge_p,%eax
    subl _r_edges,%eax
    sarl $5,%eax
    movl %eax,%ecx
    cmpl _r_maxedgesseen,%eax
    jle .Lrsf_edge_max_ready
    movl %eax,_r_maxedgesseen
.Lrsf_edge_max_ready:
    pushl _r_maxedgesseen
    pushl _r_numallocatededges
    pushl %ecx
    pushl $.Lrsf_edge_format
    call _Con_Printf
    addl $16,%esp
.Lrsf_skip_edges:

    /* C float-to-int conversion truncates independently of the x87 mode. */
    fnstcw -30(%ebp)
    movw -30(%ebp),%ax
    orw $0x0c00,%ax
    movw %ax,-32(%ebp)
    fldcw -32(%ebp)
    flds _r_ambient+VC_CVAR_VALUE
    fistpl -36(%ebp)
    fldcw -30(%ebp)
    movl -36(%ebp),%eax
    testl %eax,%eax
    jge .Lrsf_ambient_ready
    xorl %eax,%eax
.Lrsf_ambient_ready:
    movl %eax,_r_refdef+VC_REFDEF_AMBIENTLIGHT

    /* Offline/demo rendering cannot enable the behind-walls debug view. */
    cmpl $0,_sv+VC_SERVER_ACTIVE
    jne .Lrsf_server_active
    movl $0,_r_draworder+VC_CVAR_VALUE
.Lrsf_server_active:
    call _R_CheckVariables
    call _R_AnimateLight
    incl _r_framecount
    movl $0,_numbtofpolys

    /* Copy the view origin, form the camera basis, then update the alias view. */
    movl _r_refdef+VC_REFDEF_VIEWORG,%eax
    movl %eax,_modelorg
    movl %eax,_r_origin
    movl _r_refdef+VC_REFDEF_VIEWORG+4,%eax
    movl %eax,_modelorg+4
    movl %eax,_r_origin+4
    movl _r_refdef+VC_REFDEF_VIEWORG+8,%eax
    movl %eax,_modelorg+8
    movl %eax,_r_origin+8
    pushl $_vup
    pushl $_vright
    pushl $_vpn
    pushl $_r_refdef+VC_REFDEF_VIEWANGLES
    call _AngleVectors
    addl $16,%esp
    call _R_AliasSetViewMatrix

    /* Preserve old leaf before resolving the current origin in the BSP. */
    movl _r_viewleaf,%eax
    movl %eax,_r_oldviewleaf
    pushl _cl+VC_CLIENT_WORLDMODEL
    pushl $_r_origin
    call _Mod_PointInLeaf
    addl $8,%esp
    movl %eax,_r_viewleaf

    /* Water warp state uses the same cvar truth test and CONTENTS_WATER bound. */
    movl _r_dowarp,%eax
    movl %eax,_r_dowarpold
    VC_TEST_FLOAT _r_waterwarp+VC_CVAR_VALUE,.Lrsf_waterwarp_enabled,.Lrsf_waterwarp_disabled
.Lrsf_waterwarp_enabled:
    movl _r_viewleaf,%eax
    cmpl $-3,VC_MLEAF_CONTENTS(%eax)
    jg .Lrsf_waterwarp_disabled
    movl $1,_r_dowarp
    jmp .Lrsf_warp_state_ready
.Lrsf_waterwarp_disabled:
    movl $0,_r_dowarp
.Lrsf_warp_state_ready:

    movl _r_dowarp,%eax
    cmpl _r_dowarpold,%eax
    jne .Lrsf_view_changed
    cmpl $0,_r_viewchanged
    jne .Lrsf_view_changed
    VC_TEST_FLOAT _lcd_x+VC_CVAR_VALUE,.Lrsf_view_changed,.Lrsf_no_view_change
.Lrsf_view_changed:
    cmpl $0,_r_dowarp
    je .Lrsf_full_view_rect

    /* C's mixed unsigned width comparisons are retained for malformed modes. */
    movl _vid+VC_VID_WIDTH,%eax
    cmpl _vid+VC_VID_MAXWARPWIDTH,%eax
    ja .Lrsf_scaled_warp_rect
    movl _vid+VC_VID_HEIGHT,%eax
    cmpl _vid+VC_VID_MAXWARPHEIGHT,%eax
    ja .Lrsf_scaled_warp_rect
    movl $0,-20(%ebp)
    movl $0,-16(%ebp)
    movl _vid+VC_VID_WIDTH,%eax
    movl %eax,-12(%ebp)
    movl _vid+VC_VID_HEIGHT,%eax
    movl %eax,-8(%ebp)
    movl $0,-4(%ebp)
    pushl _vid+VC_VID_ASPECT
    pushl _sb_lines
    leal -20(%ebp),%eax
    pushl %eax
    call _R_ViewChanged
    addl $12,%esp
    jmp .Lrsf_view_rect_done

.Lrsf_scaled_warp_rect:
    /* Keep the original assignment order, including the height-clamp behavior. */
    fildl _vid+VC_VID_WIDTH
    fstps -24(%ebp)
    fildl _vid+VC_VID_HEIGHT
    fstps -28(%ebp)

    /* if (w > maxwarpwidth) h *= (float)maxwarpwidth / w; w = maxwarpwidth; */
    fildl _vid+VC_VID_MAXWARPWIDTH
    flds -24(%ebp)
    fcompp
    fnstsw %ax
    sahf
    jbe .Lrsf_width_not_clamped
    fildl _vid+VC_VID_MAXWARPWIDTH
    fstps -44(%ebp)
    flds -44(%ebp)
    fdivs -24(%ebp)
    fmuls -28(%ebp)
    fstps -28(%ebp)
    fildl _vid+VC_VID_MAXWARPWIDTH
    fstps -24(%ebp)
.Lrsf_width_not_clamped:

    /* C stores h=maxwarpheight before evaluating the ratio which scales w. */
    fildl _vid+VC_VID_MAXWARPHEIGHT
    flds -28(%ebp)
    fcompp
    fnstsw %ax
    sahf
    jbe .Lrsf_height_not_clamped
    fildl _vid+VC_VID_MAXWARPHEIGHT
    fstps -44(%ebp)
    flds -44(%ebp)
    fstps -28(%ebp)
    flds -44(%ebp)
    fdivs -28(%ebp)
    fmuls -24(%ebp)
    fstps -24(%ebp)
.Lrsf_height_not_clamped:

    /* Convert the two float dimensions with truncation and restore x87 state. */
    fnstcw -30(%ebp)
    movw -30(%ebp),%ax
    orw $0x0c00,%ax
    movw %ax,-32(%ebp)
    fldcw -32(%ebp)
    flds -24(%ebp)
    fistpl -36(%ebp)
    flds -28(%ebp)
    fistpl -40(%ebp)
    fldcw -30(%ebp)
    movl $0,-20(%ebp)
    movl $0,-16(%ebp)
    movl -36(%ebp),%eax
    movl %eax,-12(%ebp)
    movl -40(%ebp),%eax
    movl %eax,-8(%ebp)
    movl $0,-4(%ebp)

    /* lineadj = (int)((float)sb_lines * (h / (float)vid.height)). */
    fildl _vid+VC_VID_HEIGHT
    fstps -48(%ebp)
    flds -28(%ebp)
    fdivs -48(%ebp)
    fildl _sb_lines
    fmulp %st,%st(1)
    fnstcw -30(%ebp)
    movw -30(%ebp),%ax
    orw $0x0c00,%ax
    movw %ax,-32(%ebp)
    fldcw -32(%ebp)
    fistpl -36(%ebp)
    fldcw -30(%ebp)

    /* aspect = vid.aspect * (h / w) * (width / height), in source order. */
    fildl _vid+VC_VID_WIDTH
    fstps -44(%ebp)
    fildl _vid+VC_VID_HEIGHT
    fstps -48(%ebp)
    flds _vid+VC_VID_ASPECT
    flds -28(%ebp)
    fdivs -24(%ebp)
    fmulp %st,%st(1)
    flds -44(%ebp)
    fdivs -48(%ebp)
    fmulp %st,%st(1)
    fstps -52(%ebp)

    pushl -52(%ebp)
    pushl -36(%ebp)
    leal -20(%ebp),%eax
    pushl %eax
    call _R_ViewChanged
    addl $12,%esp
    jmp .Lrsf_view_rect_done

.Lrsf_full_view_rect:
    movl $0,-20(%ebp)
    movl $0,-16(%ebp)
    movl _vid+VC_VID_WIDTH,%eax
    movl %eax,-12(%ebp)
    movl _vid+VC_VID_HEIGHT,%eax
    movl %eax,-8(%ebp)
    movl $0,-4(%ebp)
    pushl _vid+VC_VID_ASPECT
    pushl _sb_lines
    leal -20(%ebp),%eax
    pushl %eax
    call _R_ViewChanged
    addl $12,%esp
.Lrsf_view_rect_done:
    movl $0,_r_viewchanged

.Lrsf_no_view_change:
    /* Four edge clip planes, then immutable per-frame camera bases. */
    call _R_TransformFrustum
    movl _vpn,%eax
    movl %eax,_base_vpn
    movl _vpn+4,%eax
    movl %eax,_base_vpn+4
    movl _vpn+8,%eax
    movl %eax,_base_vpn+8
    movl _vright,%eax
    movl %eax,_base_vright
    movl _vright+4,%eax
    movl %eax,_base_vright+4
    movl _vright+8,%eax
    movl %eax,_base_vright+8
    movl _vup,%eax
    movl %eax,_base_vup
    movl _vup+4,%eax
    movl %eax,_base_vup+4
    movl _vup+8,%eax
    movl %eax,_base_vup+8
    movl _modelorg,%eax
    movl %eax,_base_modelorg
    movl _modelorg+4,%eax
    movl %eax,_base_modelorg+4
    movl _modelorg+8,%eax
    movl %eax,_base_modelorg+8
    call _R_SetSkyFrame
    call _R_SetUpFrustumIndexes

    movl $0,_r_cache_thrash
    movl $0,_c_faceclip
    movl $0,_d_spanpixcount
    movl $0,_r_polycount
    movl $0,_r_drawnpolycount
    movl $0,_r_wholepolycount
    movl $0,_r_amodels_drawn
    movl $0,_r_outofsurfaces
    movl $0,_r_outofedges
    call _D_SetupFrame

    movl %ebp,%esp
    popl %ebp
    ret

.section .rodata
.p2align 2
.Lrsf_zero:
    .asciz "0"
.Lrsf_draworder:
    .asciz "r_draworder"
.Lrsf_fullbright:
    .asciz "r_fullbright"
.Lrsf_ambient:
    .asciz "r_ambient"
.Lrsf_drawflat:
    .asciz "r_drawflat"
.Lrsf_surface_format:
    .asciz "Used %d of %d surfs; %d max\n"
.Lrsf_edge_format:
    .asciz "Used %d of %d edges; %d max\n"
