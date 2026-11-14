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
#ifndef BENCH486
#define _Mod_Extradata _Mod_Extradata_asm486
#endif

/* Mod_Extradata's hot alias-model cache lookup. model_t.cache is pinned by
 * asm_aliascontrol.h; Cache_Check preserves the cache manager's LRU behavior. */
.extern _Cache_Check
.extern _Sys_Error
.section .rodata
.p2align 2
.LModExtradataCacheError:
	.asciz "Mod_Extradata: caching failed"
.text
.p2align 3
.globl _Mod_Extradata_asm486
_Mod_Extradata_asm486:
	pushl	%ebx
	movl	8(%esp),%ebx
	leal	388(%ebx),%eax
	pushl	%eax
	call	_Cache_Check
	addl	$4,%esp
	testl	%eax,%eax
	jne	.LModExtradataReturn
	pushl	$1
	pushl	%ebx
	call	_Mod_LoadModel
	addl	$8,%esp
	movl	388(%ebx),%eax
	testl	%eax,%eax
	jne	.LModExtradataReturn
	pushl	$.LModExtradataCacheError
	call	_Sys_Error
	addl	$4,%esp
	movl	388(%ebx),%eax
.LModExtradataReturn:
	popl	%ebx
	ret

#define ASM486_ALIAS_MODEL_OCCLUSION 1

#ifdef PROFILE486
#include "renderer/r_aliasbounds_profile.inc"
#include "renderer/r_aliastransform_profile.inc"
#include "renderer/r_aliascontrol_profile.inc"
#include "renderer/r_aliasconstants_profile.inc"
#else
#include "renderer/r_aliasbounds_release.inc"
#include "renderer/r_aliastransform_release.inc"
#include "renderer/r_aliascontrol_release.inc"
#include "renderer/r_aliasconstants_release.inc"
#endif
#if defined(BENCH486) && defined(ASM486_ALIAS_MODEL_LOAD_FIXTURE)
#define MODEL_LOAD_CACHE_CHECK _Bench486AliasLoadCacheCheck
#define MODEL_LOAD_STACK_FILE _Bench486AliasLoadStackFile
#define MODEL_LOAD_FILE_BASE _Bench486AliasLoadFileBase
#define MODEL_LOAD_ALIAS _Bench486AliasLoadAliasModel
#define MODEL_LOAD_SPRITE _Bench486AliasLoadSpriteModel
#define MODEL_LOAD_BRUSH _Bench486AliasLoadBrushModel
#define MODEL_LOAD_ERROR _Bench486AliasLoadError
#else
#define MODEL_LOAD_CACHE_CHECK _Cache_Check
#define MODEL_LOAD_STACK_FILE _COM_LoadStackFile
#define MODEL_LOAD_FILE_BASE _COM_FileBase
#define MODEL_LOAD_ALIAS _Mod_LoadAliasModel
#define MODEL_LOAD_SPRITE _Mod_LoadSpriteModel
#define MODEL_LOAD_BRUSH _Mod_LoadBrushModel
#define MODEL_LOAD_ERROR _Sys_Error
#endif
#include "renderer/r_modelloadasm.inc"
#undef MODEL_LOAD_CACHE_CHECK
#undef MODEL_LOAD_STACK_FILE
#undef MODEL_LOAD_FILE_BASE
#undef MODEL_LOAD_ALIAS
#undef MODEL_LOAD_SPRITE
#undef MODEL_LOAD_BRUSH
#undef MODEL_LOAD_ERROR
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
