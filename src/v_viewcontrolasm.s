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
