/*
Copyright (C) 1996-1997 Id Software, Inc.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

*/
/* Independent, inspectable view/camera instruction ownership. */
#ifdef ASM486_VIEW_CONTROL
.arch i486
.arch .387
.code32
#ifdef BENCH486
#define _Cvar_Set _Bench486ViewCvarSet
#define _R_PushDlights _Bench486ViewPushLights
#define _R_RenderView _Bench486ViewRender
#define _Chase_Update _Bench486ViewChase
#define _Draw_Character _Bench486ViewCharacter
#define _Bench486ProfileEnter _Bench486ViewProfileEnter
#define _Bench486ProfileLeave _Bench486ViewProfileLeave
#endif
#ifdef PROFILE486
#include "v_viewcontrol_profile.inc"
#else
#include "v_viewcontrol_release.inc"
#endif
#include "r_setupframe_asm.inc"
#include "r_checkvariables_asm.inc"
#endif
#if defined(BENCH486) && defined(ASM486_VIEW_CONTROL)
.text
.globl _Bench486ViewFloatCall
/* ABI-transparent test adapter: pass two cdecl words, consume one FP result.
   It does not save callee-owned registers, so their corruption remains visible. */
_Bench486ViewFloatCall:
    movl 4(%esp),%eax
    pushl 12(%esp)
    pushl 12(%esp)
    call *%eax
    addl $8,%esp
    fstps _bench486_view_float_result
    ret
#endif

/* V_Init: register the view commands and cvars in source order, then build
   the initial gamma table before registering v_gamma.  No callee-saved
   registers are used; each cdecl call removes its own arguments here. */
#if defined(ASM486_VIEW_CONTROL) || defined(BENCH486)
.arch i486
.arch .387
.code32
#ifdef BENCH486
#define V_INIT_ADD_COMMAND _V_Init_BenchAddCommand
#define V_INIT_REGISTER_VARIABLE _V_Init_BenchRegisterVariable
#else
#define V_INIT_ADD_COMMAND _Cmd_AddCommand
#define V_INIT_REGISTER_VARIABLE _Cvar_RegisterVariable
#endif

.section .rodata
.p2align 2
.Lviewinit_cmd_v_cshift:   .asciz "v_cshift"
.Lviewinit_cmd_bf:         .asciz "bf"
.Lviewinit_cmd_centerview: .asciz "centerview"

.text
.p2align 4,,15
.globl _V_Init_asm486
#ifdef ASM486_VIEW_CONTROL
.globl _V_Init
_V_Init:
#endif
_V_Init_asm486:
    pushl $_V_cshift_f
    pushl $.Lviewinit_cmd_v_cshift
    call V_INIT_ADD_COMMAND
    addl $8,%esp

    pushl $_V_BonusFlash_f
    pushl $.Lviewinit_cmd_bf
    call V_INIT_ADD_COMMAND
    addl $8,%esp

    pushl $_V_StartPitchDrift
    pushl $.Lviewinit_cmd_centerview
    call V_INIT_ADD_COMMAND
    addl $8,%esp

    pushl $_lcd_x
    call V_INIT_REGISTER_VARIABLE
    addl $4,%esp
    pushl $_lcd_yaw
    call V_INIT_REGISTER_VARIABLE
    addl $4,%esp

    pushl $_v_centermove
    call V_INIT_REGISTER_VARIABLE
    addl $4,%esp
    pushl $_v_centerspeed
    call V_INIT_REGISTER_VARIABLE
    addl $4,%esp

    pushl $_v_iyaw_cycle
    call V_INIT_REGISTER_VARIABLE
    addl $4,%esp
    pushl $_v_iroll_cycle
    call V_INIT_REGISTER_VARIABLE
    addl $4,%esp
    pushl $_v_ipitch_cycle
    call V_INIT_REGISTER_VARIABLE
    addl $4,%esp
    pushl $_v_iyaw_level
    call V_INIT_REGISTER_VARIABLE
    addl $4,%esp
    pushl $_v_iroll_level
    call V_INIT_REGISTER_VARIABLE
    addl $4,%esp
    pushl $_v_ipitch_level
    call V_INIT_REGISTER_VARIABLE
    addl $4,%esp

    pushl $_v_idlescale
    call V_INIT_REGISTER_VARIABLE
    addl $4,%esp
    pushl $_crosshair
    call V_INIT_REGISTER_VARIABLE
    addl $4,%esp
    pushl $_cl_crossx
    call V_INIT_REGISTER_VARIABLE
    addl $4,%esp
    pushl $_cl_crossy
    call V_INIT_REGISTER_VARIABLE
    addl $4,%esp

    pushl $_scr_ofsx
    call V_INIT_REGISTER_VARIABLE
    addl $4,%esp
    pushl $_scr_ofsy
    call V_INIT_REGISTER_VARIABLE
    addl $4,%esp
    pushl $_scr_ofsz
    call V_INIT_REGISTER_VARIABLE
    addl $4,%esp
    pushl $_cl_rollspeed
    call V_INIT_REGISTER_VARIABLE
    addl $4,%esp
    pushl $_cl_rollangle
    call V_INIT_REGISTER_VARIABLE
    addl $4,%esp
    pushl $_cl_bob
    call V_INIT_REGISTER_VARIABLE
    addl $4,%esp
    pushl $_cl_bobcycle
    call V_INIT_REGISTER_VARIABLE
    addl $4,%esp
    pushl $_cl_bobup
    call V_INIT_REGISTER_VARIABLE
    addl $4,%esp

    pushl $_v_kicktime
    call V_INIT_REGISTER_VARIABLE
    addl $4,%esp
    pushl $_v_kickroll
    call V_INIT_REGISTER_VARIABLE
    addl $4,%esp
    pushl $_v_kickpitch
    call V_INIT_REGISTER_VARIABLE
    addl $4,%esp

    /* view.c declares BuildGammaTable(float): the literal 1.0 is converted
       to IEEE-754 single precision before its one-word cdecl push. */
    pushl $0x3f800000
    call _BuildGammaTable
    addl $4,%esp

    pushl $_v_gamma
    call V_INIT_REGISTER_VARIABLE
    addl $4,%esp
    ret
#undef V_INIT_ADD_COMMAND
#undef V_INIT_REGISTER_VARIABLE
#endif
