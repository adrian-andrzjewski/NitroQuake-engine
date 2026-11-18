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
/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */

/* Full framebuffer drawing ownership; normal builds never generate instructions from C. */
#ifdef ASM486_DRAWING
.arch i486
.arch .387
.code32
#ifdef BENCH486
#define _W_GetLumpName _Bench486DrawingLump
#define _Cache_Check _Bench486DrawingCacheCheck
#define _COM_LoadCacheFile _Bench486DrawingLoad
#define _SwapPic _Bench486DrawingSwap
#define _D_BeginDirectRect _Bench486DrawingBegin
#define _D_EndDirectRect _Bench486DrawingEnd
#define _VID_UnlockBuffer _Bench486DrawingUnlock
#define _VID_LockBuffer _Bench486DrawingLock
#define _S_ExtraUpdate _Bench486DrawingSound

#endif
#ifdef PROFILE486
#include "renderer/d_drawing_profile.inc"
#else
#include "renderer/d_drawing_release.inc"
#endif
#endif
#if defined(BENCH486) && defined(ASM486_DRAWING)
.text
.globl _Bench486DrawingPointerCall
/* Test adapter passes one pointer argument and records EAX without hiding preserved registers. */
_Bench486DrawingPointerCall:
    movl 4(%esp),%eax
    pushl 8(%esp)
    call *%eax
    addl $4,%esp
    movl %eax,_bench486_drawing_pointer_result
    ret
#endif
