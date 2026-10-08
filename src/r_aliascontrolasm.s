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
/* Alias pipeline control with explicit 486 instruction ownership. */
#ifdef ASM486_ALIAS_CONTROL
.arch i486
.arch .387
.code32
#ifdef BENCH486
#define _Mod_Extradata _Bench486AliasControlModel
#define _Con_DPrintf _Bench486AliasControlPrint
#define _D_PolysetDraw _Bench486AliasControlRaster
#define _D_PolysetDrawFinalVerts _Bench486AliasControlFinalVerts
#define _D_PolysetUpdateTables _Bench486AliasControlTables
#define _D_Aff8Patch _Bench486AliasControlPatch
#define _R_AliasClipTriangle _Bench486AliasControlClip
#define _Bench486ProfileEnter _Bench486AliasControlProfileEnter
#define _Bench486ProfileLeave _Bench486AliasControlProfileLeave
#define _Bench486ProfileWork _Bench486AliasControlProfileWork
#define _Sys_FloatTime _Bench486AliasControlTime
#endif
#ifdef PROFILE486
#include "r_aliasbounds_profile.inc"
#include "r_aliastransform_profile.inc"
#include "r_aliascontrol_profile.inc"
#include "r_aliasconstants_profile.inc"
#else
#include "r_aliasbounds_release.inc"
#include "r_aliastransform_release.inc"
#include "r_aliascontrol_release.inc"
#include "r_aliasconstants_release.inc"
#endif
#endif
#if defined(BENCH486) && defined(ASM486_ALIAS_CONTROL)
.text
.globl _Bench486AliasControlRegCall
/* Tail adapter leaves the outer ABI probe able to see any callee-owned damage. */
_Bench486AliasControlRegCall:
    movl 4(%esp),%edx
    movl 8(%esp),%eax
    jmp *%edx
.globl _Bench486AliasControlBBoxCall
_Bench486AliasControlBBoxCall:
    subl $12,%esp
    call *16(%esp)
    addl $12,%esp
    movl %eax,_bench486_aliascontrol_bbox_result
    ret
#endif
