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
// view.c -- player eye positioning

#include "quakedef.h"
#if defined(ASM486_PALETTE) || defined(BENCH486)
#include <stddef.h>
#include "asm_palette.h"
typedef char palette_client_layout[(offsetof(client_state_t,items)==p_client_items &&
    offsetof(client_state_t,cshifts)==p_client_shifts &&
    offsetof(client_state_t,prev_cshifts)==p_client_previous) ? 1 : -1];
typedef char palette_shift_layout[(sizeof(cshift_t)==p_shift_bytes &&
    offsetof(cshift_t,percent)==p_shift_percent && NUM_CSHIFTS==p_shift_count) ? 1 : -1];
typedef char palette_cvar_vid_layout[(offsetof(cvar_t,value)==p_cvar_value &&
    offsetof(viddef_t,recalc_refdef)==p_vid_recalc && sizeof(void*)==4) ? 1 : -1];
typedef char palette_item_layout[(IT_QUAD==p_item_quad && IT_SUIT==p_item_suit &&
    IT_INVISIBILITY==p_item_invisibility && IT_INVULNERABILITY==p_item_invulnerability) ? 1 : -1];
#endif

void BuildGammaTable (float g);
void BuildGammaTable_C (float g);
qboolean V_CheckGamma_C (void);
void V_CalcPowerupCshift_C (void);

#include "r_local.h"
#include "asm_viewcontrol.h"
#include "asm_vdamage.h"
/* Same process-lifetime camera latches, shared with independent test oracles. */
float viewcontrol_oldyaw,viewcontrol_oldpitch,viewcontrol_oldz;
#if defined(BENCH486) && defined(ASM486_VIEW_CONTROL)
void (*bench486_view_probe)(unsigned,unsigned,const unsigned *);
static int Bench486ViewObserve(unsigned phase,unsigned count,const unsigned *words)
{if(!bench486_view_probe)return 0;bench486_view_probe(phase,count,words);return 1;}
void Bench486ViewCvarSet(const char *name,const char *value)
{unsigned args[2];args[0]=(unsigned)name;args[1]=(unsigned)value;
 if(Bench486ViewObserve(1,2,args)){
  if(!strcmp(name,"scr_ofsx"))scr_ofsx.value=0;
  if(!strcmp(name,"scr_ofsy"))scr_ofsy.value=0;
  if(!strcmp(name,"scr_ofsz"))scr_ofsz.value=0;
 }else Cvar_Set((char *)name,(char *)value);}
void Bench486ViewPushLights(void){if(!Bench486ViewObserve(2,0,NULL))R_PushDlights();}
void Bench486ViewRender(void){if(!Bench486ViewObserve(3,0,NULL))R_RenderView();}
void Bench486ViewCharacter(int x,int y,int n)
{unsigned args[3];args[0]=x;args[1]=y;args[2]=n;if(!Bench486ViewObserve(4,3,args))Draw_Character(x,y,n);}
void Bench486ViewChase(void){if(!Bench486ViewObserve(5,0,NULL))Chase_Update();}
void Bench486ViewProfileEnter(unsigned phase)
{unsigned arg=phase;if(!Bench486ViewObserve(6,1,&arg)){
#ifdef PROFILE486
 Bench486ProfileEnter(phase);
#endif
}}
void Bench486ViewProfileLeave(void){if(!Bench486ViewObserve(7,0,NULL)){
#ifdef PROFILE486
 Bench486ProfileLeave();
#endif
}}
#endif


/*

The view is allowed to move slightly from it's true position for bobbing,
but if it exceeds 8 pixels linear distance (spherical, not box), the list of
entities sent from the server may not include everything in the pvs, especially
when crossing a water boudnary.

*/

cvar_t		lcd_x = {"lcd_x","0"};
cvar_t		lcd_yaw = {"lcd_yaw","0"};

cvar_t	scr_ofsx = {"scr_ofsx","0", false};
cvar_t	scr_ofsy = {"scr_ofsy","0", false};
cvar_t	scr_ofsz = {"scr_ofsz","0", false};

cvar_t	cl_rollspeed = {"cl_rollspeed", "200"};
cvar_t	cl_rollangle = {"cl_rollangle", "2.0"};

cvar_t	cl_bob = {"cl_bob","0.02", false};
cvar_t	cl_bobcycle = {"cl_bobcycle","0.6", false};
cvar_t	cl_bobup = {"cl_bobup","0.5", false};

cvar_t	v_kicktime = {"v_kicktime", "0.5", false};
cvar_t	v_kickroll = {"v_kickroll", "0.6", false};
cvar_t	v_kickpitch = {"v_kickpitch", "0.6", false};

cvar_t	v_iyaw_cycle = {"v_iyaw_cycle", "2", false};
cvar_t	v_iroll_cycle = {"v_iroll_cycle", "0.5", false};
cvar_t	v_ipitch_cycle = {"v_ipitch_cycle", "1", false};
cvar_t	v_iyaw_level = {"v_iyaw_level", "0.3", false};
cvar_t	v_iroll_level = {"v_iroll_level", "0.1", false};
cvar_t	v_ipitch_level = {"v_ipitch_level", "0.3", false};

cvar_t	v_idlescale = {"v_idlescale", "0", false};

cvar_t	crosshair = {"crosshair", "0", true};
cvar_t	cl_crossx = {"cl_crossx", "0", false};
cvar_t	cl_crossy = {"cl_crossy", "0", false};

float	v_dmg_time, v_dmg_roll, v_dmg_pitch;

extern	int			in_forward, in_forward2, in_back;


/*
===============
V_CalcRoll

Used by view and sv_user
===============
*/
vec3_t	forward, right, up;

#if !defined(ASM486_VIEW_CONTROL)
float V_CalcRoll (vec3_t angles, vec3_t velocity)
{
	float	sign;
	float	side;
	float	value;
	
	AngleVectors (angles, forward, right, up);
	side = DotProduct (velocity, right);
	sign = side < 0 ? -1 : 1;
	side = fabs(side);
	
	value = cl_rollangle.value;
//	if (cl.inwater)
//		value *= 6;

	if (side < cl_rollspeed.value)
		side = side * value / cl_rollspeed.value;
	else
		side = value;
	
	return side*sign;
	
}
#endif


/*
===============
V_CalcBob

===============
*/
#if !defined(ASM486_VIEW_CONTROL)
float V_CalcBob (void)
{
	float	bob;
	float	cycle;
	
	cycle = cl.time - (int)(cl.time/cl_bobcycle.value)*cl_bobcycle.value;
	cycle /= cl_bobcycle.value;
	if (cycle < cl_bobup.value)
		cycle = M_PI * cycle / cl_bobup.value;
	else
		cycle = M_PI + M_PI*(cycle-cl_bobup.value)/(1.0 - cl_bobup.value);

// bob is proportional to velocity in the xy plane
// (don't count Z, or jumping messes it up)

	bob = sqrt(cl.velocity[0]*cl.velocity[0] + cl.velocity[1]*cl.velocity[1]) * cl_bob.value;
//Con_Printf ("speed: %5.1f\n", Length(cl.velocity));
	bob = bob*0.3 + bob*0.7*sin(cycle);
	if (bob > 4)
		bob = 4;
	else if (bob < -7)
		bob = -7;
	return bob;
	
}
#endif


//=============================================================================


cvar_t	v_centermove = {"v_centermove", "0.15", false};
cvar_t	v_centerspeed = {"v_centerspeed","500"};


#if !defined(ASM486_VIEW_CONTROL)
void V_StartPitchDrift (void)
{
#if 1
	if (cl.laststop == cl.time)
	{
		return;		// something else is keeping it from drifting
	}
#endif
	if (cl.nodrift || !cl.pitchvel)
	{
		cl.pitchvel = v_centerspeed.value;
		cl.nodrift = false;
		cl.driftmove = 0;
	}
}
#endif

#if !defined(ASM486_VIEW_CONTROL)
void V_StopPitchDrift (void)
{
	cl.laststop = cl.time;
	cl.nodrift = true;
	cl.pitchvel = 0;
}
#endif

/*
===============
V_DriftPitch

Moves the client pitch angle towards cl.idealpitch sent by the server.

If the user is adjusting pitch manually, either with lookup/lookdown,
mlook and mouse, or klook and keyboard, pitch drifting is constantly stopped.

Drifting is enabled when the center view key is hit, mlook is released and
lookspring is non 0, or when 
===============
*/
#if !defined(ASM486_VIEW_CONTROL)
void V_DriftPitch (void)
{
	float		delta, move;

	if (noclip_anglehack || !cl.onground || cls.demoplayback )
	{
		cl.driftmove = 0;
		cl.pitchvel = 0;
		return;
	}

// don't count small mouse motion
	if (cl.nodrift)
	{
		if ( fabs(cl.cmd.forwardmove) < cl_forwardspeed.value)
			cl.driftmove = 0;
		else
			cl.driftmove += host_frametime;
	
		if ( cl.driftmove > v_centermove.value)
		{
			V_StartPitchDrift ();
		}
		return;
	}
	
	delta = cl.idealpitch - cl.viewangles[PITCH];

	if (!delta)
	{
		cl.pitchvel = 0;
		return;
	}

	move = host_frametime * cl.pitchvel;
	cl.pitchvel += host_frametime * v_centerspeed.value;
	
//Con_Printf ("move: %f (%f)\n", move, host_frametime);

	if (delta > 0)
	{
		if (move > delta)
		{
			cl.pitchvel = 0;
			move = delta;
		}
		cl.viewangles[PITCH] += move;
	}
	else if (delta < 0)
	{
		if (move > -delta)
		{
			cl.pitchvel = 0;
			move = -delta;
		}
		cl.viewangles[PITCH] -= move;
	}
}
#endif





/*
============================================================================== 
 
						PALETTE FLASHES 
 
============================================================================== 
*/ 
 
 
cshift_t	cshift_empty = { {130,80,50}, 0 };
cshift_t	cshift_water = { {130,80,50}, 128 };
cshift_t	cshift_slime = { {0,25,5}, 150 };
cshift_t	cshift_lava = { {255,80,0}, 150 };

cvar_t		v_gamma = {"gamma", "1", true};

static float palette_oldgammavalue_C;

#ifdef BENCH486
static void (*bench486_palette_hook)(byte *palette);
void Bench486PaletteSetHook (void (*hook)(byte *palette))
{
    bench486_palette_hook = hook;
}
void Bench486PaletteDispatch (byte *palette)
{
    if (bench486_palette_hook) bench486_palette_hook(palette);
    else VID_ShiftPalette(palette);
}
void Bench486GammaState_C (unsigned *word, int restore)
{
    if (restore) Q_memcpy(&palette_oldgammavalue_C,word,4);
    else Q_memcpy(word,&palette_oldgammavalue_C,4);
}
#endif

#ifdef BENCH486
extern byte gammatable[256]; // benchmark assembly storage adds exact redzones
#else
byte gammatable[256]; // palette is sent through this
#endif

#if !defined(ASM486_PALETTE) || defined(BENCH486)
void BuildGammaTable_C (float g)
{
	int		i, inf;
	
	if (g == 1.0)
	{
		for (i=0 ; i<256 ; i++)
			gammatable[i] = i;
		return;
	}
	
	for (i=0 ; i<256 ; i++)
	{
		inf = 255 * pow ( (i+0.5)/255.5 , g ) + 0.5;
		if (inf < 0)
			inf = 0;
		if (inf > 255)
			inf = 255;
		gammatable[i] = inf;
	}
}
#endif
#ifndef ASM486_PALETTE
void BuildGammaTable (float g)
{
	BuildGammaTable_C (g);
}
#endif

/*
=================
V_CheckGamma
=================
*/
#if !defined(ASM486_PALETTE) || defined(BENCH486)
qboolean V_CheckGamma_C (void)
{

	
	if (v_gamma.value == palette_oldgammavalue_C)
		return false;
	palette_oldgammavalue_C = v_gamma.value;
	
	BuildGammaTable_C (v_gamma.value);
	vid.recalc_refdef = 1;				// force a surface cache flush
	
	return true;
}
#endif
#ifndef ASM486_PALETTE
qboolean V_CheckGamma (void)
{
	return V_CheckGamma_C ();
}
#endif



/*
===============
V_ParseDamage
===============
*/
#if defined(BENCH486) || defined(ASM486_V_PARSE_DAMAGE)
#define V_PARSE_DAMAGE_C_NAME V_ParseDamage_C
#else
#define V_PARSE_DAMAGE_C_NAME V_ParseDamage
#endif

#if defined(BENCH486) || !defined(ASM486_V_PARSE_DAMAGE)
void V_PARSE_DAMAGE_C_NAME (void)
{
	int		armor, blood;
	vec3_t	from;
	int		i;
	vec3_t	forward, right, up;
	entity_t	*ent;
	float	side;
	float	count;
	
	armor = MSG_ReadByte ();
	blood = MSG_ReadByte ();
	for (i=0 ; i<3 ; i++)
		from[i] = MSG_ReadCoord ();

	count = blood*0.5 + armor*0.5;
	if (count < 10)
		count = 10;

	cl.faceanimtime = cl.time + 0.2;		// but sbar face into pain frame

	cl.cshifts[CSHIFT_DAMAGE].percent += 3*count;
	if (cl.cshifts[CSHIFT_DAMAGE].percent < 0)
		cl.cshifts[CSHIFT_DAMAGE].percent = 0;
	if (cl.cshifts[CSHIFT_DAMAGE].percent > 150)
		cl.cshifts[CSHIFT_DAMAGE].percent = 150;

	if (armor > blood)		
	{
		cl.cshifts[CSHIFT_DAMAGE].destcolor[0] = 200;
		cl.cshifts[CSHIFT_DAMAGE].destcolor[1] = 100;
		cl.cshifts[CSHIFT_DAMAGE].destcolor[2] = 100;
	}
	else if (armor)
	{
		cl.cshifts[CSHIFT_DAMAGE].destcolor[0] = 220;
		cl.cshifts[CSHIFT_DAMAGE].destcolor[1] = 50;
		cl.cshifts[CSHIFT_DAMAGE].destcolor[2] = 50;
	}
	else
	{
		cl.cshifts[CSHIFT_DAMAGE].destcolor[0] = 255;
		cl.cshifts[CSHIFT_DAMAGE].destcolor[1] = 0;
		cl.cshifts[CSHIFT_DAMAGE].destcolor[2] = 0;
	}

//
// calculate view angle kicks
//
	ent = &cl_entities[cl.viewentity];
	
	VectorSubtract (from, ent->origin, from);
	VectorNormalize (from);
	
	AngleVectors (ent->angles, forward, right, up);

	side = DotProduct (from, right);
	v_dmg_roll = count*side*v_kickroll.value;
	
	side = DotProduct (from, forward);
	v_dmg_pitch = count*side*v_kickpitch.value;

	v_dmg_time = v_kicktime.value;
}
#undef V_PARSE_DAMAGE_C_NAME
#endif /* BENCH486 || !ASM486_V_PARSE_DAMAGE */

#if defined(ASM486_V_PARSE_DAMAGE)
void V_ParseDamage (void)
{
	V_ParseDamage_asm486 ();
}
#elif defined(BENCH486)
void V_ParseDamage (void)
{
	V_ParseDamage_C ();
}
#endif


/*
==================
V_cshift_f
==================
*/
void V_cshift_f (void)
{
	cshift_empty.destcolor[0] = atoi(Cmd_Argv(1));
	cshift_empty.destcolor[1] = atoi(Cmd_Argv(2));
	cshift_empty.destcolor[2] = atoi(Cmd_Argv(3));
	cshift_empty.percent = atoi(Cmd_Argv(4));
}


/*
==================
V_BonusFlash_f

When you run over an item, the server sends this command
==================
*/
void V_BonusFlash_f (void)
{
	cl.cshifts[CSHIFT_BONUS].destcolor[0] = 215;
	cl.cshifts[CSHIFT_BONUS].destcolor[1] = 186;
	cl.cshifts[CSHIFT_BONUS].destcolor[2] = 69;
	cl.cshifts[CSHIFT_BONUS].percent = 50;
}

/*
=============
V_SetContentsColor

Underwater, lava, etc each has a color shift
=============
*/
#if !defined(ASM486_PALETTE) || defined(BENCH486)
void V_SetContentsColor_C (int contents)
{
	switch (contents)
	{
	case CONTENTS_EMPTY:
	case CONTENTS_SOLID:
		cl.cshifts[CSHIFT_CONTENTS] = cshift_empty;
		break;
	case CONTENTS_LAVA:
		cl.cshifts[CSHIFT_CONTENTS] = cshift_lava;
		break;
	case CONTENTS_SLIME:
		cl.cshifts[CSHIFT_CONTENTS] = cshift_slime;
		break;
	default:
		cl.cshifts[CSHIFT_CONTENTS] = cshift_water;
	}
}
#endif
#ifndef ASM486_PALETTE
void V_SetContentsColor (int contents)
{
	V_SetContentsColor_C (contents);
}
#endif

/*
=============
V_CalcPowerupCshift
=============
*/
#if !defined(ASM486_PALETTE) || defined(BENCH486)
void V_CalcPowerupCshift_C (void)
{
	if (cl.items & IT_QUAD)
	{
		cl.cshifts[CSHIFT_POWERUP].destcolor[0] = 0;
		cl.cshifts[CSHIFT_POWERUP].destcolor[1] = 0;
		cl.cshifts[CSHIFT_POWERUP].destcolor[2] = 255;
		cl.cshifts[CSHIFT_POWERUP].percent = 30;
	}
	else if (cl.items & IT_SUIT)
	{
		cl.cshifts[CSHIFT_POWERUP].destcolor[0] = 0;
		cl.cshifts[CSHIFT_POWERUP].destcolor[1] = 255;
		cl.cshifts[CSHIFT_POWERUP].destcolor[2] = 0;
		cl.cshifts[CSHIFT_POWERUP].percent = 20;
	}
	else if (cl.items & IT_INVISIBILITY)
	{
		cl.cshifts[CSHIFT_POWERUP].destcolor[0] = 100;
		cl.cshifts[CSHIFT_POWERUP].destcolor[1] = 100;
		cl.cshifts[CSHIFT_POWERUP].destcolor[2] = 100;
		cl.cshifts[CSHIFT_POWERUP].percent = 100;
	}
	else if (cl.items & IT_INVULNERABILITY)
	{
		cl.cshifts[CSHIFT_POWERUP].destcolor[0] = 255;
		cl.cshifts[CSHIFT_POWERUP].destcolor[1] = 255;
		cl.cshifts[CSHIFT_POWERUP].destcolor[2] = 0;
		cl.cshifts[CSHIFT_POWERUP].percent = 30;
	}
	else
		cl.cshifts[CSHIFT_POWERUP].percent = 0;
}
#endif
#ifndef ASM486_PALETTE
void V_CalcPowerupCshift (void)
{
	V_CalcPowerupCshift_C ();
}
#endif


/*
=============
V_UpdatePalette
=============
*/
#if !defined(ASM486_PALETTE) || defined(BENCH486)
void V_UpdatePalette_C (void)
{
	int		i, j;
	qboolean	new;
	byte	*basepal, *newpal;
	byte	pal[768];
	int		r,g,b;
	qboolean force;

	V_CalcPowerupCshift_C ();
	
	new = false;
	
	for (i=0 ; i<NUM_CSHIFTS ; i++)
	{
		if (cl.cshifts[i].percent != cl.prev_cshifts[i].percent)
		{
			new = true;
			cl.prev_cshifts[i].percent = cl.cshifts[i].percent;
		}
		for (j=0 ; j<3 ; j++)
			if (cl.cshifts[i].destcolor[j] != cl.prev_cshifts[i].destcolor[j])
			{
				new = true;
				cl.prev_cshifts[i].destcolor[j] = cl.cshifts[i].destcolor[j];
			}
	}
	
// drop the damage value
	cl.cshifts[CSHIFT_DAMAGE].percent -= host_frametime*150;
	if (cl.cshifts[CSHIFT_DAMAGE].percent <= 0)
		cl.cshifts[CSHIFT_DAMAGE].percent = 0;

// drop the bonus value
	cl.cshifts[CSHIFT_BONUS].percent -= host_frametime*100;
	if (cl.cshifts[CSHIFT_BONUS].percent <= 0)
		cl.cshifts[CSHIFT_BONUS].percent = 0;

	force = V_CheckGamma_C ();
	if (!new && !force)
		return;
			
	basepal = host_basepal;
	newpal = pal;
	
	for (i=0 ; i<256 ; i++)
	{
		r = basepal[0];
		g = basepal[1];
		b = basepal[2];
		basepal += 3;
	
		for (j=0 ; j<NUM_CSHIFTS ; j++)	
		{
			r += (cl.cshifts[j].percent*(cl.cshifts[j].destcolor[0]-r))>>8;
			g += (cl.cshifts[j].percent*(cl.cshifts[j].destcolor[1]-g))>>8;
			b += (cl.cshifts[j].percent*(cl.cshifts[j].destcolor[2]-b))>>8;
		}
		
		newpal[0] = gammatable[r];
		newpal[1] = gammatable[g];
		newpal[2] = gammatable[b];
		newpal += 3;
	}

	#ifdef BENCH486
    Bench486PaletteDispatch (pal);
#else
    VID_ShiftPalette (pal);
#endif
}
#endif
#ifndef ASM486_PALETTE
void V_UpdatePalette (void)
{
	V_UpdatePalette_C ();
}
#endif


/* 
============================================================================== 
 
						VIEW RENDERING 
 
============================================================================== 
*/ 

#if !defined(ASM486_VIEW_CONTROL)
float angledelta (float a)
{
	a = anglemod(a);
	if (a > 180)
		a -= 360;
	return a;
}
#endif

/*
==================
CalcGunAngle
==================
*/
#if !defined(ASM486_VIEW_CONTROL)
void CalcGunAngle (void)
{	
	float	yaw, pitch, move;
	
	yaw = r_refdef.viewangles[YAW];
	pitch = -r_refdef.viewangles[PITCH];

	yaw = angledelta(yaw - r_refdef.viewangles[YAW]) * 0.4;
	if (yaw > 10)
		yaw = 10;
	if (yaw < -10)
		yaw = -10;
	pitch = angledelta(-pitch - r_refdef.viewangles[PITCH]) * 0.4;
	if (pitch > 10)
		pitch = 10;
	if (pitch < -10)
		pitch = -10;
	move = host_frametime*20;
	if (yaw > viewcontrol_oldyaw)
	{
		if (viewcontrol_oldyaw + move < yaw)
			yaw = viewcontrol_oldyaw + move;
	}
	else
	{
		if (viewcontrol_oldyaw - move > yaw)
			yaw = viewcontrol_oldyaw - move;
	}
	
	if (pitch > viewcontrol_oldpitch)
	{
		if (viewcontrol_oldpitch + move < pitch)
			pitch = viewcontrol_oldpitch + move;
	}
	else
	{
		if (viewcontrol_oldpitch - move > pitch)
			pitch = viewcontrol_oldpitch - move;
	}
	
	viewcontrol_oldyaw = yaw;
	viewcontrol_oldpitch = pitch;

	cl.viewent.angles[YAW] = r_refdef.viewangles[YAW] + yaw;
	cl.viewent.angles[PITCH] = - (r_refdef.viewangles[PITCH] + pitch);

	cl.viewent.angles[ROLL] -= v_idlescale.value * sin(cl.time*v_iroll_cycle.value) * v_iroll_level.value;
	cl.viewent.angles[PITCH] -= v_idlescale.value * sin(cl.time*v_ipitch_cycle.value) * v_ipitch_level.value;
	cl.viewent.angles[YAW] -= v_idlescale.value * sin(cl.time*v_iyaw_cycle.value) * v_iyaw_level.value;
}
#endif

/*
==============
V_BoundOffsets
==============
*/
#if !defined(ASM486_VIEW_CONTROL)
void V_BoundOffsets (void)
{
	entity_t	*ent;
	
	ent = &cl_entities[cl.viewentity];

// absolutely bound refresh reletive to entity clipping hull
// so the view can never be inside a solid wall

	if (r_refdef.vieworg[0] < ent->origin[0] - 14)
		r_refdef.vieworg[0] = ent->origin[0] - 14;
	else if (r_refdef.vieworg[0] > ent->origin[0] + 14)
		r_refdef.vieworg[0] = ent->origin[0] + 14;
	if (r_refdef.vieworg[1] < ent->origin[1] - 14)
		r_refdef.vieworg[1] = ent->origin[1] - 14;
	else if (r_refdef.vieworg[1] > ent->origin[1] + 14)
		r_refdef.vieworg[1] = ent->origin[1] + 14;
	if (r_refdef.vieworg[2] < ent->origin[2] - 22)
		r_refdef.vieworg[2] = ent->origin[2] - 22;
	else if (r_refdef.vieworg[2] > ent->origin[2] + 30)
		r_refdef.vieworg[2] = ent->origin[2] + 30;
}
#endif

/*
==============
V_AddIdle

Idle swaying
==============
*/
#if !defined(ASM486_VIEW_CONTROL)
void V_AddIdle (void)
{
	r_refdef.viewangles[ROLL] += v_idlescale.value * sin(cl.time*v_iroll_cycle.value) * v_iroll_level.value;
	r_refdef.viewangles[PITCH] += v_idlescale.value * sin(cl.time*v_ipitch_cycle.value) * v_ipitch_level.value;
	r_refdef.viewangles[YAW] += v_idlescale.value * sin(cl.time*v_iyaw_cycle.value) * v_iyaw_level.value;
}
#endif


/*
==============
V_CalcViewRoll

Roll is induced by movement and damage
==============
*/
#if !defined(ASM486_VIEW_CONTROL)
void V_CalcViewRoll (void)
{
	float		side;
		
	side = V_CalcRoll (cl_entities[cl.viewentity].angles, cl.velocity);
	r_refdef.viewangles[ROLL] += side;

	if (v_dmg_time > 0)
	{
		r_refdef.viewangles[ROLL] += v_dmg_time/v_kicktime.value*v_dmg_roll;
		r_refdef.viewangles[PITCH] += v_dmg_time/v_kicktime.value*v_dmg_pitch;
		v_dmg_time -= host_frametime;
	}

	if (cl.stats[STAT_HEALTH] <= 0)
	{
		r_refdef.viewangles[ROLL] = 80;	// dead view angle
		return;
	}

}
#endif


/*
==================
V_CalcIntermissionRefdef

==================
*/
#if !defined(ASM486_VIEW_CONTROL)
void V_CalcIntermissionRefdef (void)
{
	entity_t	*ent, *view;
	float		old;

// ent is the player model (visible when out of body)
	ent = &cl_entities[cl.viewentity];
// view is the weapon model (only visible from inside body)
	view = &cl.viewent;

	VectorCopy (ent->origin, r_refdef.vieworg);
	VectorCopy (ent->angles, r_refdef.viewangles);
	view->model = NULL;

// allways idle in intermission
	old = v_idlescale.value;
	v_idlescale.value = 1;
	V_AddIdle ();
	v_idlescale.value = old;
}
#endif

/*
==================
V_CalcRefdef

==================
*/
#if !defined(ASM486_VIEW_CONTROL)
void V_CalcRefdef (void)
{
	entity_t	*ent, *view;
	int			i;
	vec3_t		forward, right, up;
	vec3_t		angles;
	float		bob;

	V_DriftPitch ();

// ent is the player model (visible when out of body)
	ent = &cl_entities[cl.viewentity];
// view is the weapon model (only visible from inside body)
	view = &cl.viewent;
	

// transform the view offset by the model's matrix to get the offset from
// model origin for the view
	ent->angles[YAW] = cl.viewangles[YAW];	// the model should face
										// the view dir
	ent->angles[PITCH] = -cl.viewangles[PITCH];	// the model should face
										// the view dir
										
	
	bob = V_CalcBob ();
	
// refresh position
	VectorCopy (ent->origin, r_refdef.vieworg);
	r_refdef.vieworg[2] += cl.viewheight + bob;

// never let it sit exactly on a node line, because a water plane can
// dissapear when viewed with the eye exactly on it.
// the server protocol only specifies to 1/16 pixel, so add 1/32 in each axis
	r_refdef.vieworg[0] += 1.0/32;
	r_refdef.vieworg[1] += 1.0/32;
	r_refdef.vieworg[2] += 1.0/32;

	VectorCopy (cl.viewangles, r_refdef.viewangles);
	V_CalcViewRoll ();
	V_AddIdle ();

// offsets
	angles[PITCH] = -ent->angles[PITCH];	// because entity pitches are
											//  actually backward
	angles[YAW] = ent->angles[YAW];
	angles[ROLL] = ent->angles[ROLL];

	AngleVectors (angles, forward, right, up);

	for (i=0 ; i<3 ; i++)
		r_refdef.vieworg[i] += scr_ofsx.value*forward[i]
			+ scr_ofsy.value*right[i]
			+ scr_ofsz.value*up[i];
	
	
	V_BoundOffsets ();
		
// set up gun position
	VectorCopy (cl.viewangles, view->angles);
	
	CalcGunAngle ();

	VectorCopy (ent->origin, view->origin);
	view->origin[2] += cl.viewheight;

	for (i=0 ; i<3 ; i++)
	{
		view->origin[i] += forward[i]*bob*0.4;
//		view->origin[i] += right[i]*bob*0.4;
//		view->origin[i] += up[i]*bob*0.8;
	}
	view->origin[2] += bob;

// fudge position around to keep amount of weapon visible
// roughly equal with different FOV

#if 0
	if (cl.model_precache[cl.stats[STAT_WEAPON]] && strcmp (cl.model_precache[cl.stats[STAT_WEAPON]]->name,  "progs/v_shot2.mdl"))
#endif
	if (scr_viewsize.value == 110)
		view->origin[2] += 1;
	else if (scr_viewsize.value == 100)
		view->origin[2] += 2;
	else if (scr_viewsize.value == 90)
		view->origin[2] += 1;
	else if (scr_viewsize.value == 80)
		view->origin[2] += 0.5;

	view->model = cl.model_precache[cl.stats[STAT_WEAPON]];
	view->frame = cl.stats[STAT_WEAPONFRAME];
	view->colormap = vid.colormap;

// set up the refresh position
	VectorAdd (r_refdef.viewangles, cl.punchangle, r_refdef.viewangles);

// smooth out stair step ups
if (cl.onground && ent->origin[2] - viewcontrol_oldz > 0)
{
	float steptime;
	
	steptime = cl.time - cl.oldtime;
	if (steptime < 0)
//FIXME		I_Error ("steptime < 0");
		steptime = 0;

	viewcontrol_oldz += steptime * 80;
	if (viewcontrol_oldz > ent->origin[2])
		viewcontrol_oldz = ent->origin[2];
	if (ent->origin[2] - viewcontrol_oldz > 12)
		viewcontrol_oldz = ent->origin[2] - 12;
	r_refdef.vieworg[2] += viewcontrol_oldz - ent->origin[2];
	view->origin[2] += viewcontrol_oldz - ent->origin[2];
}
else
	viewcontrol_oldz = ent->origin[2];

	if (chase_active.value)
		Chase_Update ();
}
#endif

/*
==================
V_RenderView

The player's clipping box goes from (-16 -16 -24) to (16 16 32) from
the entity origin, so any view position inside that will be valid
==================
*/
extern vrect_t	scr_vrect;

#if !defined(ASM486_VIEW_CONTROL)
void V_RenderView (void)
{
	if (con_forcedup)
		return;

// don't allow cheats in multiplayer
	if (cl.maxclients > 1)
	{
		Cvar_Set ("scr_ofsx", "0");
		Cvar_Set ("scr_ofsy", "0");
		Cvar_Set ("scr_ofsz", "0");
	}

	if (cl.intermission)
	{	// intermission / finale rendering
		V_CalcIntermissionRefdef ();	
	}
	else
	{
		if (!cl.paused /* && (sv.maxclients > 1 || key_dest == key_game) */ )
			V_CalcRefdef ();
	}

	BENCH486_PROFILE_ENTER (BENCH486_PROFILE_VIEW_LIGHTS);
	R_PushDlights ();
	BENCH486_PROFILE_LEAVE ();

	if (lcd_x.value)
	{
		//
		// render two interleaved views
		//
		int		i;

		vid.rowbytes <<= 1;
		vid.aspect *= 0.5;

		r_refdef.viewangles[YAW] -= lcd_yaw.value;
		for (i=0 ; i<3 ; i++)
			r_refdef.vieworg[i] -= right[i]*lcd_x.value;
		R_RenderView ();

		vid.buffer += vid.rowbytes>>1;

			BENCH486_PROFILE_ENTER (BENCH486_PROFILE_VIEW_LIGHTS);
			R_PushDlights ();
			BENCH486_PROFILE_LEAVE ();

		r_refdef.viewangles[YAW] += lcd_yaw.value*2;
		for (i=0 ; i<3 ; i++)
			r_refdef.vieworg[i] += 2*right[i]*lcd_x.value;
		R_RenderView ();

		vid.buffer -= vid.rowbytes>>1;

		r_refdef.vrect.height <<= 1;

		vid.rowbytes >>= 1;
		vid.aspect *= 2;
	}
	else
	{
		R_RenderView ();
	}

	if (crosshair.value)
		Draw_Character (scr_vrect.x + scr_vrect.width/2 + cl_crossx.value, 
			scr_vrect.y + scr_vrect.height/2 + cl_crossy.value, '+');
		
}
#endif

//============================================================================

/*
=============
V_Init
=============
*/
void V_Init (void)
{
	Cmd_AddCommand ("v_cshift", V_cshift_f);	
	Cmd_AddCommand ("bf", V_BonusFlash_f);
	Cmd_AddCommand ("centerview", V_StartPitchDrift);

	Cvar_RegisterVariable (&lcd_x);
	Cvar_RegisterVariable (&lcd_yaw);

	Cvar_RegisterVariable (&v_centermove);
	Cvar_RegisterVariable (&v_centerspeed);

	Cvar_RegisterVariable (&v_iyaw_cycle);
	Cvar_RegisterVariable (&v_iroll_cycle);
	Cvar_RegisterVariable (&v_ipitch_cycle);
	Cvar_RegisterVariable (&v_iyaw_level);
	Cvar_RegisterVariable (&v_iroll_level);
	Cvar_RegisterVariable (&v_ipitch_level);

	Cvar_RegisterVariable (&v_idlescale);
	Cvar_RegisterVariable (&crosshair);
	Cvar_RegisterVariable (&cl_crossx);
	Cvar_RegisterVariable (&cl_crossy);

	Cvar_RegisterVariable (&scr_ofsx);
	Cvar_RegisterVariable (&scr_ofsy);
	Cvar_RegisterVariable (&scr_ofsz);
	Cvar_RegisterVariable (&cl_rollspeed);
	Cvar_RegisterVariable (&cl_rollangle);
	Cvar_RegisterVariable (&cl_bob);
	Cvar_RegisterVariable (&cl_bobcycle);
	Cvar_RegisterVariable (&cl_bobup);

	Cvar_RegisterVariable (&v_kicktime);
	Cvar_RegisterVariable (&v_kickroll);
	Cvar_RegisterVariable (&v_kickpitch);	
	
	BuildGammaTable (1.0);	// no gamma yet
	Cvar_RegisterVariable (&v_gamma);
}



#if defined(BENCH486) && defined(ASM486_VIEW_CONTROL)
float V_CalcRoll_View_C (vec3_t angles, vec3_t velocity);
float V_CalcBob_View_C (void);
void V_StartPitchDrift_View_C (void);
void V_StopPitchDrift_View_C (void);
void V_DriftPitch_View_C (void);
float angledelta_View_C (float a);
void CalcGunAngle_View_C (void);
void V_BoundOffsets_View_C (void);
void V_AddIdle_View_C (void);
void V_CalcViewRoll_View_C (void);
void V_CalcIntermissionRefdef_View_C (void);
void V_CalcRefdef_View_C (void);
void V_RenderView_View_C (void);
#define Bench486ProfileEnter Bench486ViewProfileEnter
#define Bench486ProfileLeave Bench486ViewProfileLeave
float V_CalcRoll_View_C (vec3_t angles, vec3_t velocity)
{
	float	sign;
	float	side;
	float	value;

	AngleVectors (angles, forward, right, up);
	side = DotProduct (velocity, right);
	sign = side < 0 ? -1 : 1;
	side = fabs(side);

	value = cl_rollangle.value;
//	if (cl.inwater)
//		value *= 6;

	if (side < cl_rollspeed.value)
		side = side * value / cl_rollspeed.value;
	else
		side = value;

	return side*sign;

}

float V_CalcBob_View_C (void)
{
	float	bob;
	float	cycle;

	cycle = cl.time - (int)(cl.time/cl_bobcycle.value)*cl_bobcycle.value;
	cycle /= cl_bobcycle.value;
	if (cycle < cl_bobup.value)
		cycle = M_PI * cycle / cl_bobup.value;
	else
		cycle = M_PI + M_PI*(cycle-cl_bobup.value)/(1.0 - cl_bobup.value);

// bob is proportional to velocity in the xy plane
// (don't count Z, or jumping messes it up)

	bob = sqrt(cl.velocity[0]*cl.velocity[0] + cl.velocity[1]*cl.velocity[1]) * cl_bob.value;
//Con_Printf ("speed: %5.1f\n", Length(cl.velocity));
	bob = bob*0.3 + bob*0.7*sin(cycle);
	if (bob > 4)
		bob = 4;
	else if (bob < -7)
		bob = -7;
	return bob;

}

void V_StartPitchDrift_View_C (void)
{
#if 1
	if (cl.laststop == cl.time)
	{
		return;		// something else is keeping it from drifting
	}
#endif
	if (cl.nodrift || !cl.pitchvel)
	{
		cl.pitchvel = v_centerspeed.value;
		cl.nodrift = false;
		cl.driftmove = 0;
	}
}

void V_StopPitchDrift_View_C (void)
{
	cl.laststop = cl.time;
	cl.nodrift = true;
	cl.pitchvel = 0;
}

void V_DriftPitch_View_C (void)
{
	float		delta, move;

	if (noclip_anglehack || !cl.onground || cls.demoplayback )
	{
		cl.driftmove = 0;
		cl.pitchvel = 0;
		return;
	}

// don't count small mouse motion
	if (cl.nodrift)
	{
		if ( fabs(cl.cmd.forwardmove) < cl_forwardspeed.value)
			cl.driftmove = 0;
		else
			cl.driftmove += host_frametime;

		if ( cl.driftmove > v_centermove.value)
		{
			V_StartPitchDrift_View_C ();
		}
		return;
	}

	delta = cl.idealpitch - cl.viewangles[PITCH];

	if (!delta)
	{
		cl.pitchvel = 0;
		return;
	}

	move = host_frametime * cl.pitchvel;
	cl.pitchvel += host_frametime * v_centerspeed.value;

//Con_Printf ("move: %f (%f)\n", move, host_frametime);

	if (delta > 0)
	{
		if (move > delta)
		{
			cl.pitchvel = 0;
			move = delta;
		}
		cl.viewangles[PITCH] += move;
	}
	else if (delta < 0)
	{
		if (move > -delta)
		{
			cl.pitchvel = 0;
			move = -delta;
		}
		cl.viewangles[PITCH] -= move;
	}
}

float angledelta_View_C (float a)
{
	a = anglemod(a);
	if (a > 180)
		a -= 360;
	return a;
}

void CalcGunAngle_View_C (void)
{
	float	yaw, pitch, move;

	yaw = r_refdef.viewangles[YAW];
	pitch = -r_refdef.viewangles[PITCH];

	yaw = angledelta_View_C(yaw - r_refdef.viewangles[YAW]) * 0.4;
	if (yaw > 10)
		yaw = 10;
	if (yaw < -10)
		yaw = -10;
	pitch = angledelta_View_C(-pitch - r_refdef.viewangles[PITCH]) * 0.4;
	if (pitch > 10)
		pitch = 10;
	if (pitch < -10)
		pitch = -10;
	move = host_frametime*20;
	if (yaw > viewcontrol_oldyaw)
	{
		if (viewcontrol_oldyaw + move < yaw)
			yaw = viewcontrol_oldyaw + move;
	}
	else
	{
		if (viewcontrol_oldyaw - move > yaw)
			yaw = viewcontrol_oldyaw - move;
	}

	if (pitch > viewcontrol_oldpitch)
	{
		if (viewcontrol_oldpitch + move < pitch)
			pitch = viewcontrol_oldpitch + move;
	}
	else
	{
		if (viewcontrol_oldpitch - move > pitch)
			pitch = viewcontrol_oldpitch - move;
	}

	viewcontrol_oldyaw = yaw;
	viewcontrol_oldpitch = pitch;

	cl.viewent.angles[YAW] = r_refdef.viewangles[YAW] + yaw;
	cl.viewent.angles[PITCH] = - (r_refdef.viewangles[PITCH] + pitch);

	cl.viewent.angles[ROLL] -= v_idlescale.value * sin(cl.time*v_iroll_cycle.value) * v_iroll_level.value;
	cl.viewent.angles[PITCH] -= v_idlescale.value * sin(cl.time*v_ipitch_cycle.value) * v_ipitch_level.value;
	cl.viewent.angles[YAW] -= v_idlescale.value * sin(cl.time*v_iyaw_cycle.value) * v_iyaw_level.value;
}

void V_BoundOffsets_View_C (void)
{
	entity_t	*ent;

	ent = &cl_entities[cl.viewentity];

// absolutely bound refresh reletive to entity clipping hull
// so the view can never be inside a solid wall

	if (r_refdef.vieworg[0] < ent->origin[0] - 14)
		r_refdef.vieworg[0] = ent->origin[0] - 14;
	else if (r_refdef.vieworg[0] > ent->origin[0] + 14)
		r_refdef.vieworg[0] = ent->origin[0] + 14;
	if (r_refdef.vieworg[1] < ent->origin[1] - 14)
		r_refdef.vieworg[1] = ent->origin[1] - 14;
	else if (r_refdef.vieworg[1] > ent->origin[1] + 14)
		r_refdef.vieworg[1] = ent->origin[1] + 14;
	if (r_refdef.vieworg[2] < ent->origin[2] - 22)
		r_refdef.vieworg[2] = ent->origin[2] - 22;
	else if (r_refdef.vieworg[2] > ent->origin[2] + 30)
		r_refdef.vieworg[2] = ent->origin[2] + 30;
}

void V_AddIdle_View_C (void)
{
	r_refdef.viewangles[ROLL] += v_idlescale.value * sin(cl.time*v_iroll_cycle.value) * v_iroll_level.value;
	r_refdef.viewangles[PITCH] += v_idlescale.value * sin(cl.time*v_ipitch_cycle.value) * v_ipitch_level.value;
	r_refdef.viewangles[YAW] += v_idlescale.value * sin(cl.time*v_iyaw_cycle.value) * v_iyaw_level.value;
}

void V_CalcViewRoll_View_C (void)
{
	float		side;

	side = V_CalcRoll_View_C (cl_entities[cl.viewentity].angles, cl.velocity);
	r_refdef.viewangles[ROLL] += side;

	if (v_dmg_time > 0)
	{
		r_refdef.viewangles[ROLL] += v_dmg_time/v_kicktime.value*v_dmg_roll;
		r_refdef.viewangles[PITCH] += v_dmg_time/v_kicktime.value*v_dmg_pitch;
		v_dmg_time -= host_frametime;
	}

	if (cl.stats[STAT_HEALTH] <= 0)
	{
		r_refdef.viewangles[ROLL] = 80;	// dead view angle
		return;
	}

}

void V_CalcIntermissionRefdef_View_C (void)
{
	entity_t	*ent, *view;
	float		old;

// ent is the player model (visible when out of body)
	ent = &cl_entities[cl.viewentity];
// view is the weapon model (only visible from inside body)
	view = &cl.viewent;

	VectorCopy (ent->origin, r_refdef.vieworg);
	VectorCopy (ent->angles, r_refdef.viewangles);
	view->model = NULL;

// allways idle in intermission
	old = v_idlescale.value;
	v_idlescale.value = 1;
	V_AddIdle_View_C ();
	v_idlescale.value = old;
}

void V_CalcRefdef_View_C (void)
{
	entity_t	*ent, *view;
	int			i;
	vec3_t		forward, right, up;
	vec3_t		angles;
	float		bob;

	V_DriftPitch_View_C ();

// ent is the player model (visible when out of body)
	ent = &cl_entities[cl.viewentity];
// view is the weapon model (only visible from inside body)
	view = &cl.viewent;


// transform the view offset by the model's matrix to get the offset from
// model origin for the view
	ent->angles[YAW] = cl.viewangles[YAW];	// the model should face
										// the view dir
	ent->angles[PITCH] = -cl.viewangles[PITCH];	// the model should face
										// the view dir


	bob = V_CalcBob_View_C ();

// refresh position
	VectorCopy (ent->origin, r_refdef.vieworg);
	r_refdef.vieworg[2] += cl.viewheight + bob;

// never let it sit exactly on a node line, because a water plane can
// dissapear when viewed with the eye exactly on it.
// the server protocol only specifies to 1/16 pixel, so add 1/32 in each axis
	r_refdef.vieworg[0] += 1.0/32;
	r_refdef.vieworg[1] += 1.0/32;
	r_refdef.vieworg[2] += 1.0/32;

	VectorCopy (cl.viewangles, r_refdef.viewangles);
	V_CalcViewRoll_View_C ();
	V_AddIdle_View_C ();

// offsets
	angles[PITCH] = -ent->angles[PITCH];	// because entity pitches are
											//  actually backward
	angles[YAW] = ent->angles[YAW];
	angles[ROLL] = ent->angles[ROLL];

	AngleVectors (angles, forward, right, up);

	for (i=0 ; i<3 ; i++)
		r_refdef.vieworg[i] += scr_ofsx.value*forward[i]
			+ scr_ofsy.value*right[i]
			+ scr_ofsz.value*up[i];


	V_BoundOffsets_View_C ();

// set up gun position
	VectorCopy (cl.viewangles, view->angles);

	CalcGunAngle_View_C ();

	VectorCopy (ent->origin, view->origin);
	view->origin[2] += cl.viewheight;

	for (i=0 ; i<3 ; i++)
	{
		view->origin[i] += forward[i]*bob*0.4;
//		view->origin[i] += right[i]*bob*0.4;
//		view->origin[i] += up[i]*bob*0.8;
	}
	view->origin[2] += bob;

// fudge position around to keep amount of weapon visible
// roughly equal with different FOV

#if 0
	if (cl.model_precache[cl.stats[STAT_WEAPON]] && strcmp (cl.model_precache[cl.stats[STAT_WEAPON]]->name,  "progs/v_shot2.mdl"))
#endif
	if (scr_viewsize.value == 110)
		view->origin[2] += 1;
	else if (scr_viewsize.value == 100)
		view->origin[2] += 2;
	else if (scr_viewsize.value == 90)
		view->origin[2] += 1;
	else if (scr_viewsize.value == 80)
		view->origin[2] += 0.5;

	view->model = cl.model_precache[cl.stats[STAT_WEAPON]];
	view->frame = cl.stats[STAT_WEAPONFRAME];
	view->colormap = vid.colormap;

// set up the refresh position
	VectorAdd (r_refdef.viewangles, cl.punchangle, r_refdef.viewangles);

// smooth out stair step ups
if (cl.onground && ent->origin[2] - viewcontrol_oldz > 0)
{
	float steptime;

	steptime = cl.time - cl.oldtime;
	if (steptime < 0)
//FIXME		I_Error ("steptime < 0");
		steptime = 0;

	viewcontrol_oldz += steptime * 80;
	if (viewcontrol_oldz > ent->origin[2])
		viewcontrol_oldz = ent->origin[2];
	if (ent->origin[2] - viewcontrol_oldz > 12)
		viewcontrol_oldz = ent->origin[2] - 12;
	r_refdef.vieworg[2] += viewcontrol_oldz - ent->origin[2];
	view->origin[2] += viewcontrol_oldz - ent->origin[2];
}
else
	viewcontrol_oldz = ent->origin[2];

	if (chase_active.value)
		Bench486ViewChase ();
}

void V_RenderView_View_C (void)
{
	if (con_forcedup)
		return;

// don't allow cheats in multiplayer
	if (cl.maxclients > 1)
	{
		Bench486ViewCvarSet ("scr_ofsx", "0");
		Bench486ViewCvarSet ("scr_ofsy", "0");
		Bench486ViewCvarSet ("scr_ofsz", "0");
	}

	if (cl.intermission)
	{	// intermission / finale rendering
		V_CalcIntermissionRefdef_View_C ();
	}
	else
	{
		if (!cl.paused /* && (sv.maxclients > 1 || key_dest == key_game) */ )
			V_CalcRefdef_View_C ();
	}

	BENCH486_PROFILE_ENTER (BENCH486_PROFILE_VIEW_LIGHTS);
	Bench486ViewPushLights ();
	BENCH486_PROFILE_LEAVE ();

	if (lcd_x.value)
	{
		//
		// render two interleaved views
		//
		int		i;

		vid.rowbytes <<= 1;
		vid.aspect *= 0.5;

		r_refdef.viewangles[YAW] -= lcd_yaw.value;
		for (i=0 ; i<3 ; i++)
			r_refdef.vieworg[i] -= right[i]*lcd_x.value;
		Bench486ViewRender ();

		vid.buffer += vid.rowbytes>>1;

			BENCH486_PROFILE_ENTER (BENCH486_PROFILE_VIEW_LIGHTS);
			Bench486ViewPushLights ();
			BENCH486_PROFILE_LEAVE ();

		r_refdef.viewangles[YAW] += lcd_yaw.value*2;
		for (i=0 ; i<3 ; i++)
			r_refdef.vieworg[i] += 2*right[i]*lcd_x.value;
		Bench486ViewRender ();

		vid.buffer -= vid.rowbytes>>1;

		r_refdef.vrect.height <<= 1;

		vid.rowbytes >>= 1;
		vid.aspect *= 2;
	}
	else
	{
		Bench486ViewRender ();
	}

	if (crosshair.value)
		Bench486ViewCharacter (scr_vrect.x + scr_vrect.width/2 + cl_crossx.value,
			scr_vrect.y + scr_vrect.height/2 + cl_crossy.value, '+');

}
#undef Bench486ProfileEnter
#undef Bench486ProfileLeave
#endif
