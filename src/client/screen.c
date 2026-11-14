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
// screen.c -- master for refresh, status bar, console, chat, notify, etc

#include "quakedef.h"
#include "renderer/r_local.h"
#include "client/asm_screenfov.h"
#include "client/asm_screennotify.h"
#include "client/asm_screenerase.h"
#include "client/asm_screencenter.h"
#include "client/asm_screenconsolesetup.h"
#include "client/asm_screenrefdef.h"
#include "client/asm_screendrawram.h"
#include "client/asm_screenoverlays.h"
#include "client/asm_screenupdate.h"
#include "client/asm_screennet.h"
#include "client/asm_screenturtle.h"

#if defined(BENCH486) && defined(ASM486_SCREEN_CENTER_STRING)
extern int bench486_screen_center_trace_active;
extern void Bench486ScreenCenterTraceGlyph (int phase, int x, int y, int character);
#endif

// only the refresh window will be updated unless these variables are flagged 
int			scr_copytop;
int			scr_copyeverything;

float		scr_con_current;
float		scr_conlines;		// lines of console to display

float		oldscreensize, oldfov;
float		scr_update_old_viewsize;
float		scr_update_old_lcd_x;
#if defined(BENCH486) && defined(ASM486_SCREEN_CENTER_STRING)
unsigned	bench486_screen_update_trace_update_count;
#endif
cvar_t		scr_viewsize = {"viewsize","100", true};
cvar_t		scr_fov = {"fov","90"};	// 10 - 170
cvar_t		scr_conspeed = {"scr_conspeed","300"};
cvar_t		scr_centertime = {"scr_centertime","2"};
cvar_t		scr_showram = {"showram","1"};
cvar_t		scr_showturtle = {"showturtle","0"};
cvar_t		scr_showpause = {"showpause","1"};
cvar_t		scr_printspeed = {"scr_printspeed","8"};

qboolean	scr_initialized;		// ready to draw

qpic_t		*scr_ram;
qpic_t		*scr_net;
qpic_t		*scr_turtle;

int			scr_fullupdate;

int			clearconsole;
int			clearnotify;

viddef_t	vid;				// global video state

vrect_t		*pconupdate;
vrect_t		scr_vrect;

qboolean	scr_disabled_for_loading;
qboolean	scr_drawloading;
float		scr_disabled_time;
qboolean	scr_skipupdate;

qboolean	block_drawing;

void SCR_ScreenShot_f (void);

/*
===============================================================================

CENTER PRINTING

===============================================================================
*/

char		scr_centerstring[1024];
float		scr_centertime_start;	// for slow victory printing
float		scr_centertime_off;
int			scr_center_lines;
int			scr_erase_lines;
int			scr_erase_center;

/*
==============
SCR_CenterPrint

Called for important messages that should stay in the center of the screen
for a few moments
==============
*/
void SCR_CenterPrint (char *str)
{
	strncpy (scr_centerstring, str, sizeof(scr_centerstring)-1);
	scr_centertime_off = scr_centertime.value;
	scr_centertime_start = cl.time;

// count the number of lines for centering
	scr_center_lines = 1;
	while (*str)
	{
		if (*str == '\n')
			scr_center_lines++;
		str++;
	}
}

#if defined(ASM486_SCREEN_ERASE_CENTER_STRING) && defined(BENCH486)
#define SCREEN_ERASE_CENTER_C SCR_EraseCenterString_Screen_C
#elif !defined(ASM486_SCREEN_ERASE_CENTER_STRING)
#define SCREEN_ERASE_CENTER_C SCR_EraseCenterString
#endif

#if !defined(ASM486_SCREEN_ERASE_CENTER_STRING) || defined(BENCH486)
void SCREEN_ERASE_CENTER_C (void)
{
	int		y;

	if (scr_erase_center++ > vid.numpages)
	{
		scr_erase_lines = 0;
		return;
	}

	if (scr_center_lines <= 4)
		y = vid.height*0.35;
	else
		y = 48;

	scr_copytop = 1;
#if defined(BENCH486) && defined(ASM486_SCREEN_ERASE_CENTER_STRING)
	Bench486ScreenEraseTileClear (0, y,vid.width, 8*scr_erase_lines);
#else
	Draw_TileClear (0, y,vid.width, 8*scr_erase_lines);
#endif
}
#endif

#undef SCREEN_ERASE_CENTER_C

#if defined(ASM486_SCREEN_CENTER_STRING) && defined(BENCH486)
#define SCR_CENTER_DRAW_CHARACTER Bench486ScreenCenterStringCharacter
#define SCR_DRAW_CENTER_STRING_C SCR_DrawCenterString_Screen_C
#elif !defined(ASM486_SCREEN_CENTER_STRING)
#define SCR_CENTER_DRAW_CHARACTER Draw_Character
#define SCR_DRAW_CENTER_STRING_C SCR_DrawCenterString
#endif

#if !defined(ASM486_SCREEN_CENTER_STRING) || defined(BENCH486)
void SCR_DRAW_CENTER_STRING_C (void)
{
	char	*start;
	int		l;
	int		j;
	int		x, y;
	int		remaining;

// the finale prints the characters one at a time
	if (cl.intermission)
		remaining = scr_printspeed.value * (cl.time - scr_centertime_start);
	else
		remaining = 9999;

	scr_erase_center = 0;
	start = scr_centerstring;

	if (scr_center_lines <= 4)
		y = vid.height*0.35;
	else
		y = 48;

	do	
	{
	// scan the width of the line
		for (l=0 ; l<40 ; l++)
			if (start[l] == '\n' || !start[l])
				break;
		x = (vid.width - l*8)/2;
		for (j=0 ; j<l ; j++, x+=8)
		{
			SCR_CENTER_DRAW_CHARACTER (x, y, start[j]);
			if (!remaining--)
				return;
		}
			
		y += 8;

		while (*start && *start != '\n')
			start++;

		if (!*start)
			break;
		start++;		// skip the \n
	} while (1);
}
#endif

#undef SCR_DRAW_CENTER_STRING_C
#undef SCR_CENTER_DRAW_CHARACTER

#if defined(BENCH486) && defined(ASM486_SCREEN_CENTER_STRING)
#define SCR_CHECK_CENTER_C SCR_CheckDrawCenterString_Screen_C
#define SCR_CHECK_CENTER_DRAW Bench486ScreenCenterCheckDraw
#elif !defined(ASM486_SCREEN_CENTER_STRING)
#define SCR_CHECK_CENTER_C SCR_CheckDrawCenterString
#define SCR_CHECK_CENTER_DRAW SCR_DrawCenterString
#endif

#if !defined(ASM486_SCREEN_CENTER_STRING) || defined(BENCH486)
void SCR_CHECK_CENTER_C (void)
{
	scr_copytop = 1;
	if (scr_center_lines > scr_erase_lines)
		scr_erase_lines = scr_center_lines;

	scr_centertime_off -= host_frametime;
	
	if (scr_centertime_off <= 0 && !cl.intermission)
		return;
	if (key_dest != key_game)
		return;

	SCR_CHECK_CENTER_DRAW ();
}
#endif

#undef SCR_CHECK_CENTER_C
#undef SCR_CHECK_CENTER_DRAW

//=============================================================================

/*
====================
CalcFov
====================
*/
#if defined(ASM486_VIEW_CONTROL)
#define SCREEN_CALC_FOV_C CalcFov_C
#else
#define SCREEN_CALC_FOV_C CalcFov
#endif
#if !defined(ASM486_VIEW_CONTROL) || defined(BENCH486)
#if defined(BENCH486) && defined(ASM486_VIEW_CONTROL)
#define SCREEN_CALC_FOV_ERROR Bench486CalcFovSysError
#else
#define SCREEN_CALC_FOV_ERROR Sys_Error
#endif
float SCREEN_CALC_FOV_C (float fov_x, float width, float height)
{
        if (fov_x < 1 || fov_x > 179)
                SCREEN_CALC_FOV_ERROR ("Bad fov: %f", fov_x);

        /* Keep this original C expression as the differential oracle. */
        {
                float x;
                float a;
                x = width/tan(fov_x/360*M_PI);
                a = atan (height/x);
                a = a*360/M_PI;
                return a;
        }
}
#endif

#undef SCREEN_CALC_FOV_ERROR
#undef SCREEN_CALC_FOV_C

/*
=================
SCR_CalcRefdef

Must be called whenever vid changes
Internal use only
=================
*/
#if defined(ASM486_SCREEN_REFDEF) && defined(BENCH486)
#define SCR_REFDEF_ENTRY SCR_CalcRefdef_Screen_C
#define SCR_REFDEF_LINKAGE
#define SCR_REFDEF_BUILD_C 1
#define SCR_REFDEF_SBAR_CHANGED Bench486ScreenRefdefSbarChanged
#define SCR_REFDEF_CVAR_SET Bench486ScreenRefdefCvarSet
#define SCR_REFDEF_VIEW_CHANGED Bench486ScreenRefdefViewChanged
#elif !defined(ASM486_SCREEN_REFDEF)
#define SCR_REFDEF_ENTRY SCR_CalcRefdef
#if defined(ASM486_SCREEN_UPDATE)
#define SCR_REFDEF_LINKAGE
#else
#define SCR_REFDEF_LINKAGE static
#endif
#define SCR_REFDEF_BUILD_C 1
#define SCR_REFDEF_SBAR_CHANGED Sbar_Changed
#define SCR_REFDEF_CVAR_SET Cvar_Set
#define SCR_REFDEF_VIEW_CHANGED R_ViewChanged
#endif

#ifdef SCR_REFDEF_BUILD_C
SCR_REFDEF_LINKAGE void SCR_REFDEF_ENTRY (void)
{
	vrect_t		vrect;
	float		size;

	scr_fullupdate = 0;		// force a background redraw
	vid.recalc_refdef = 0;

// force the status bar to redraw
	SCR_REFDEF_SBAR_CHANGED ();

//========================================
	
// bound viewsize
	if (scr_viewsize.value < 30)
		SCR_REFDEF_CVAR_SET ("viewsize","30");
	if (scr_viewsize.value > 120)
		SCR_REFDEF_CVAR_SET ("viewsize","120");

// bound field of view
	if (scr_fov.value < 10)
		SCR_REFDEF_CVAR_SET ("fov","10");
	if (scr_fov.value > 170)
		SCR_REFDEF_CVAR_SET ("fov","170");

	r_refdef.fov_x = scr_fov.value;
#ifdef ASM486_VIEW_CONTROL
	r_refdef.fov_y = CalcFov_asm486 (r_refdef.fov_x, r_refdef.vrect.width, r_refdef.vrect.height);
#else
	r_refdef.fov_y = CalcFov (r_refdef.fov_x, r_refdef.vrect.width, r_refdef.vrect.height);
#endif

// intermission is always full screen	
	if (cl.intermission)
		size = 120;
	else
		size = scr_viewsize.value;

	if (size >= 120)
		sb_lines = 0;		// no status bar at all
	else if (size >= 110)
		sb_lines = 24;		// no inventory
	else
		sb_lines = 24+16+8;

// these calculations mirror those in R_Init() for r_refdef, but take no
// account of water warping
	vrect.x = 0;
	vrect.y = 0;
	vrect.width = vid.width;
	vrect.height = vid.height;

	R_SetVrect (&vrect, &scr_vrect, sb_lines);

// guard against going from one mode to another that's less than half the
// vertical resolution
	if (scr_con_current > vid.height)
		scr_con_current = vid.height;

// notify the refresh of the change
	SCR_REFDEF_VIEW_CHANGED (&vrect, sb_lines, vid.aspect);
}
#endif

#undef SCR_REFDEF_VIEW_CHANGED
#undef SCR_REFDEF_CVAR_SET
#undef SCR_REFDEF_SBAR_CHANGED
#undef SCR_REFDEF_BUILD_C
#undef SCR_REFDEF_LINKAGE
#undef SCR_REFDEF_ENTRY


/*
=================
SCR_SizeUp_f

Keybinding command
=================
*/
void SCR_SizeUp_f (void)
{
	Cvar_SetValue ("viewsize",scr_viewsize.value+10);
	vid.recalc_refdef = 1;
}


/*
=================
SCR_SizeDown_f

Keybinding command
=================
*/
void SCR_SizeDown_f (void)
{
	Cvar_SetValue ("viewsize",scr_viewsize.value-10);
	vid.recalc_refdef = 1;
}

//============================================================================

/*
==================
SCR_Init
==================
*/
void SCR_Init (void)
{
	Cvar_RegisterVariable (&scr_fov);
	Cvar_RegisterVariable (&scr_viewsize);
	Cvar_RegisterVariable (&scr_conspeed);
	Cvar_RegisterVariable (&scr_showram);
	Cvar_RegisterVariable (&scr_showturtle);
	Cvar_RegisterVariable (&scr_showpause);
	Cvar_RegisterVariable (&scr_centertime);
	Cvar_RegisterVariable (&scr_printspeed);

//
// register our commands
//
	Cmd_AddCommand ("screenshot",SCR_ScreenShot_f);
	Cmd_AddCommand ("sizeup",SCR_SizeUp_f);
	Cmd_AddCommand ("sizedown",SCR_SizeDown_f);

	scr_ram = Draw_PicFromWad ("ram");
	scr_net = Draw_PicFromWad ("net");
	scr_turtle = Draw_PicFromWad ("turtle");

	scr_initialized = true;
}



/*
==============
SCR_DrawRam
==============
*/
#if defined(ASM486_SCREEN_DRAW_RAM) && defined(BENCH486)
#define SCR_DRAW_RAM_C SCR_DrawRam_Screen_C
#elif !defined(ASM486_SCREEN_DRAW_RAM)
#define SCR_DRAW_RAM_C SCR_DrawRam
#endif

#if !defined(ASM486_SCREEN_DRAW_RAM) || defined(BENCH486)
void SCR_DRAW_RAM_C (void)
{
	if (!scr_showram.value)
		return;

	if (!r_cache_thrash)
		return;

	Draw_Pic (scr_vrect.x+32, scr_vrect.y, scr_ram);
}
#endif

#undef SCR_DRAW_RAM_C

/*
==============
SCR_DrawTurtle
==============
*/
#if defined(ASM486_SCREEN_TURTLE) && defined(BENCH486)
int bench486_screen_turtle_c_count;
#define SCR_DRAW_TURTLE_C SCR_DrawTurtle_Screen_C
#define SCR_TURTLE_COUNT bench486_screen_turtle_c_count
#elif !defined(ASM486_SCREEN_TURTLE)
static int scr_turtle_count;
#define SCR_DRAW_TURTLE_C SCR_DrawTurtle
#define SCR_TURTLE_COUNT scr_turtle_count
#endif

#if !defined(ASM486_SCREEN_TURTLE) || defined(BENCH486)
#if defined(BENCH486) && defined(ASM486_SCREEN_TURTLE)
#define SCR_TURTLE_DRAW_PIC(x, y, pic) \
	do { \
		if (bench486_screen_turtle_fixture_active) \
			Bench486ScreenTurtleRecordDrawPic (x, y, pic); \
		else \
			Draw_Pic (x, y, pic); \
	} while (0)
#else
#define SCR_TURTLE_DRAW_PIC(x, y, pic) Draw_Pic (x, y, pic)
#endif

void SCR_DRAW_TURTLE_C (void)
{
	if (!scr_showturtle.value)
		return;

	if (host_frametime < 0.1)
	{
		SCR_TURTLE_COUNT = 0;
		return;
	}

	SCR_TURTLE_COUNT++;
	if (SCR_TURTLE_COUNT < 3)
		return;

	SCR_TURTLE_DRAW_PIC (scr_vrect.x, scr_vrect.y, scr_turtle);
}
#endif

#undef SCR_TURTLE_DRAW_PIC
#undef SCR_TURTLE_COUNT
#undef SCR_DRAW_TURTLE_C

/*
==============
SCR_DrawNet
==============
*/
#if defined(ASM486_SCREEN_NET) && defined(BENCH486)
#define SCR_DRAW_NET_C SCR_DrawNet_Screen_C
#elif !defined(ASM486_SCREEN_NET)
#define SCR_DRAW_NET_C SCR_DrawNet
#endif

#if !defined(ASM486_SCREEN_NET) || defined(BENCH486)
#if defined(BENCH486) && defined(ASM486_SCREEN_NET)
#define SCR_DRAW_NET_PIC(x, y, pic) \
	do { \
		if (bench486_screen_net_fixture_active) \
			Bench486ScreenNetRecordDrawPic (x, y, pic); \
		else \
			Draw_Pic (x, y, pic); \
	} while (0)
#else
#define SCR_DRAW_NET_PIC(x, y, pic) Draw_Pic (x, y, pic)
#endif

void SCR_DRAW_NET_C (void)
{
	if (realtime - cl.last_received_message < 0.3)
		return;
	if (cls.demoplayback)
		return;

	SCR_DRAW_NET_PIC (scr_vrect.x+64, scr_vrect.y, scr_net);
}
#endif

#undef SCR_DRAW_NET_PIC
#undef SCR_DRAW_NET_C

/*
==============
DrawPause
==============
*/
#if defined(BENCH486) && defined(ASM486_SCREEN_OVERLAYS)
#define SCR_DRAW_PAUSE_C_ENTRY SCR_DrawPause_Screen_C
#define SCR_DRAW_LOADING_C_ENTRY SCR_DrawLoading_Screen_C
#define SCR_DRAW_PAUSE_C_CALL SCR_DrawPause_Screen_C ()
#define SCR_DRAW_LOADING_C_CALL SCR_DrawLoading_Screen_C ()
#define SCREEN_OVERLAY_CACHEPIC Bench486ScreenOverlayCachePic
#define SCREEN_OVERLAY_DRAW_PIC Bench486ScreenOverlayDrawPic
#elif !defined(ASM486_SCREEN_OVERLAYS)
#define SCR_DRAW_PAUSE_C_ENTRY SCR_DrawPause
#define SCR_DRAW_LOADING_C_ENTRY SCR_DrawLoading
#define SCR_DRAW_PAUSE_C_CALL SCR_DrawPause ()
#define SCR_DRAW_LOADING_C_CALL SCR_DrawLoading ()
#define SCREEN_OVERLAY_CACHEPIC Draw_CachePic
#define SCREEN_OVERLAY_DRAW_PIC Draw_Pic
#endif

#if !defined(ASM486_SCREEN_OVERLAYS) || defined(BENCH486)
void SCR_DRAW_PAUSE_C_ENTRY (void)
{
	qpic_t	*pic;

	if (!scr_showpause.value)		// turn off for screenshots
		return;

	if (!cl.paused)
		return;

	pic = SCREEN_OVERLAY_CACHEPIC ("gfx/pause.lmp");
	SCREEN_OVERLAY_DRAW_PIC ( (vid.width - pic->width)/2,
		(vid.height - 48 - pic->height)/2, pic);
}
#endif



/*
==============
SCR_DrawLoading
==============
*/
#if !defined(ASM486_SCREEN_OVERLAYS) || defined(BENCH486)
void SCR_DRAW_LOADING_C_ENTRY (void)
{
	qpic_t	*pic;

	if (!scr_drawloading)
		return;
		
	pic = SCREEN_OVERLAY_CACHEPIC ("gfx/loading.lmp");
	SCREEN_OVERLAY_DRAW_PIC ( (vid.width - pic->width)/2,
		(vid.height - 48 - pic->height)/2, pic);
}
#endif

#undef SCREEN_OVERLAY_CACHEPIC
#undef SCREEN_OVERLAY_DRAW_PIC



//=============================================================================


/*
==================
SCR_SetUpToDrawConsole
==================
*/
#if defined(ASM486_SCREEN_CONSOLE_SETUP) && defined(BENCH486)
#define SCR_CONSOLE_SETUP_C SCR_SetUpToDrawConsole_Screen_C
#define SCR_CONSOLE_SETUP_CHECK_RESIZE Bench486ScreenConsoleSetupCheckResize
#define SCR_CONSOLE_SETUP_TILE_CLEAR Bench486ScreenConsoleSetupTileClear
#define SCR_CONSOLE_SETUP_SBAR_CHANGED Bench486ScreenConsoleSetupSbarChanged
#elif !defined(ASM486_SCREEN_CONSOLE_SETUP)
#define SCR_CONSOLE_SETUP_C SCR_SetUpToDrawConsole
#define SCR_CONSOLE_SETUP_CHECK_RESIZE Con_CheckResize
#define SCR_CONSOLE_SETUP_TILE_CLEAR Draw_TileClear
#define SCR_CONSOLE_SETUP_SBAR_CHANGED Sbar_Changed
#endif

#if !defined(ASM486_SCREEN_CONSOLE_SETUP) || defined(BENCH486)
void SCR_CONSOLE_SETUP_C (void)
{
	SCR_CONSOLE_SETUP_CHECK_RESIZE ();
	
	if (scr_drawloading)
		return;		// never a console with loading plaque
		
// decide on the height of the console
	con_forcedup = !cl.worldmodel || cls.signon != SIGNONS;

	if (con_forcedup)
	{
		scr_conlines = vid.height;		// full screen
		scr_con_current = scr_conlines;
	}
	else if (key_dest == key_console)
		scr_conlines = vid.height/2;	// half screen
	else
		scr_conlines = 0;				// none visible
	
	if (scr_conlines < scr_con_current)
	{
		scr_con_current -= scr_conspeed.value*host_frametime;
		if (scr_conlines > scr_con_current)
			scr_con_current = scr_conlines;

	}
	else if (scr_conlines > scr_con_current)
	{
		scr_con_current += scr_conspeed.value*host_frametime;
		if (scr_conlines < scr_con_current)
			scr_con_current = scr_conlines;
	}

	if (clearconsole++ < vid.numpages)
	{
		scr_copytop = 1;
		SCR_CONSOLE_SETUP_TILE_CLEAR (0,(int)scr_con_current,vid.width, vid.height - (int)scr_con_current);
		SCR_CONSOLE_SETUP_SBAR_CHANGED ();
	}
	else if (clearnotify++ < vid.numpages)
	{
		scr_copytop = 1;
		SCR_CONSOLE_SETUP_TILE_CLEAR (0,0,vid.width, con_notifylines);
	}
	else
		con_notifylines = 0;
}
#endif

#undef SCR_CONSOLE_SETUP_C
#undef SCR_CONSOLE_SETUP_CHECK_RESIZE
#undef SCR_CONSOLE_SETUP_TILE_CLEAR
#undef SCR_CONSOLE_SETUP_SBAR_CHANGED
	
/*
==================
SCR_DrawConsole
==================
*/
#if defined(BENCH486) && defined(ASM486_SCREEN_OVERLAYS)
#define SCR_DRAW_CONSOLE_C SCR_DrawConsole_Screen_C
#define SCR_DRAW_CONSOLE_DRAW_CALL Bench486ScreenConsoleDrawCall
#define SCR_DRAW_CONSOLE_NOTIFY_CALL Bench486ScreenNotifyDrawCall
#elif !defined(ASM486_SCREEN_OVERLAYS)
#define SCR_DRAW_CONSOLE_C SCR_DrawConsole
#define SCR_DRAW_CONSOLE_DRAW_CALL Con_DrawConsole
#define SCR_DRAW_CONSOLE_NOTIFY_CALL Con_DrawNotify
#endif

#if !defined(ASM486_SCREEN_OVERLAYS) || defined(BENCH486)
void SCR_DRAW_CONSOLE_C (void)
{
	if (scr_con_current)
	{
		scr_copyeverything = 1;
		SCR_DRAW_CONSOLE_DRAW_CALL (scr_con_current, true);
		clearconsole = 0;
	}
	else
	{
		if (key_dest == key_game || key_dest == key_message)
			SCR_DRAW_CONSOLE_NOTIFY_CALL ();	// only draw notify in game
	}
}
#endif

#undef SCR_DRAW_CONSOLE_C
#undef SCR_DRAW_CONSOLE_DRAW_CALL
#undef SCR_DRAW_CONSOLE_NOTIFY_CALL


/* 
============================================================================== 
 
						SCREEN SHOTS 
 
============================================================================== 
*/ 
 

typedef struct
{
    char	manufacturer;
    char	version;
    char	encoding;
    char	bits_per_pixel;
    unsigned short	xmin,ymin,xmax,ymax;
    unsigned short	hres,vres;
    unsigned char	palette[48];
    char	reserved;
    char	color_planes;
    unsigned short	bytes_per_line;
    unsigned short	palette_type;
    char	filler[58];
    unsigned char	data;			// unbounded
} pcx_t;

/* 
============== 
WritePCXfile 
============== 
*/ 
void WritePCXfile (char *filename, byte *data, int width, int height,
	int rowbytes, byte *palette) 
{
	int		i, j, length;
	pcx_t	*pcx;
	byte		*pack;
	  
	pcx = Hunk_TempAlloc (width*height*2+1000);
	if (pcx == NULL)
	{
		Con_Printf("SCR_ScreenShot_f: not enough memory\n");
		return;
	} 
 
	pcx->manufacturer = 0x0a;	// PCX id
	pcx->version = 5;			// 256 color
 	pcx->encoding = 1;		// uncompressed
	pcx->bits_per_pixel = 8;		// 256 color
	pcx->xmin = 0;
	pcx->ymin = 0;
	pcx->xmax = LittleShort((short)(width-1));
	pcx->ymax = LittleShort((short)(height-1));
	pcx->hres = LittleShort((short)width);
	pcx->vres = LittleShort((short)height);
	Q_memset (pcx->palette,0,sizeof(pcx->palette));
	pcx->color_planes = 1;		// chunky image
	pcx->bytes_per_line = LittleShort((short)width);
	pcx->palette_type = LittleShort(2);		// not a grey scale
	Q_memset (pcx->filler,0,sizeof(pcx->filler));

// pack the image
	pack = &pcx->data;
	
	for (i=0 ; i<height ; i++)
	{
		for (j=0 ; j<width ; j++)
		{
			if ( (*data & 0xc0) != 0xc0)
				*pack++ = *data++;
			else
			{
				*pack++ = 0xc1;
				*pack++ = *data++;
			}
		}

		data += rowbytes - width;
	}
			
// write the palette
	*pack++ = 0x0c;	// palette ID byte
	for (i=0 ; i<768 ; i++)
		*pack++ = *palette++;
		
// write output file 
	length = pack - (byte *)pcx;
	COM_WriteFile (filename, pcx, length);
} 
 


/* 
================== 
SCR_ScreenShot_f
================== 
*/  
void SCR_ScreenShot_f (void) 
{ 
	int     i; 
	char		pcxname[80]; 
	char		checkname[MAX_OSPATH];

// 
// find a file name to save it to 
// 
	strcpy(pcxname,"quake00.pcx");
		
	for (i=0 ; i<=99 ; i++) 
	{ 
		pcxname[5] = i/10 + '0'; 
		pcxname[6] = i%10 + '0'; 
		sprintf (checkname, "%s/%s", com_gamedir, pcxname);
		if (Sys_FileTime(checkname) == -1)
			break;	// file doesn't exist
	} 
	if (i==100) 
	{
		Con_Printf ("SCR_ScreenShot_f: Couldn't create a PCX file\n"); 
		return;
 	}

// 
// save the pcx file 
// 
	D_EnableBackBufferAccess ();	// enable direct drawing of console to back
									//  buffer

	WritePCXfile (pcxname, vid.buffer, vid.width, vid.height, vid.rowbytes,
				  host_basepal);

	D_DisableBackBufferAccess ();	// for adapters that can't stay mapped in
									//  for linear writes all the time

	Con_Printf ("Wrote %s\n", pcxname);
} 


//=============================================================================


/*
===============
SCR_BeginLoadingPlaque

================
*/
void SCR_BeginLoadingPlaque (void)
{
	S_StopAllSounds (true);

	if (cls.state != ca_connected)
		return;
	if (cls.signon != SIGNONS)
		return;
	
// redraw with no console and the loading plaque
	Con_ClearNotify ();
	scr_centertime_off = 0;
	scr_con_current = 0;

	scr_drawloading = true;
	scr_fullupdate = 0;
	Sbar_Changed ();
	SCR_UpdateScreen ();
	scr_drawloading = false;

	scr_disabled_for_loading = true;
	scr_disabled_time = realtime;
	scr_fullupdate = 0;
}

/*
===============
SCR_EndLoadingPlaque

================
*/
void SCR_EndLoadingPlaque (void)
{
	scr_disabled_for_loading = false;
	scr_fullupdate = 0;
	Con_ClearNotify ();
}

//=============================================================================

char	*scr_notifystring;
qboolean	scr_drawdialog;

#if defined(ASM486_SCREEN_NOTIFY) && defined(BENCH486)
#define SCR_NOTIFY_DRAW_CHARACTER Bench486ScreenNotifyCharacter
#define SCR_DRAW_NOTIFY_C SCR_DrawNotifyString_Screen_C
#elif !defined(ASM486_SCREEN_NOTIFY)
#define SCR_NOTIFY_DRAW_CHARACTER Draw_Character
#define SCR_DRAW_NOTIFY_C SCR_DrawNotifyString
#endif

#if !defined(ASM486_SCREEN_NOTIFY) || defined(BENCH486)
void SCR_DRAW_NOTIFY_C (void)
{
	char	*start;
	int		l;
	int		j;
	int		x, y;

	start = scr_notifystring;

	y = vid.height*0.35;

	do	
	{
	// scan the width of the line
		for (l=0 ; l<40 ; l++)
			if (start[l] == '\n' || !start[l])
				break;
		x = (vid.width - l*8)/2;
		for (j=0 ; j<l ; j++, x+=8)
			SCR_NOTIFY_DRAW_CHARACTER (x, y, start[j]);

		y += 8;

		while (*start && *start != '\n')
			start++;

		if (!*start)
			break;
		start++;		// skip the \n
	} while (1);
}
#endif

#undef SCR_DRAW_NOTIFY_C
#undef SCR_NOTIFY_DRAW_CHARACTER

/*
==================
SCR_ModalMessage

Displays a text string in the center of the screen and waits for a Y or N
keypress.  
==================
*/
int SCR_ModalMessage (char *text)
{
	if (cls.state == ca_dedicated)
		return true;

	scr_notifystring = text;
 
// draw a fresh screen
	scr_fullupdate = 0;
	scr_drawdialog = true;
	SCR_UpdateScreen ();
	scr_drawdialog = false;
	
	S_ClearBuffer ();		// so dma doesn't loop current sound

	do
	{
		key_count = -1;		// wait for a key down and up
		Sys_SendKeyEvents ();
	} while (key_lastpress != 'y' && key_lastpress != 'n' && key_lastpress != K_ESCAPE);

	scr_fullupdate = 0;
	SCR_UpdateScreen ();

	return key_lastpress == 'y';
}


//=============================================================================

/*
===============
SCR_BringDownConsole

Brings the console down and fades the palettes back to normal
================
*/
void SCR_BringDownConsole (void)
{
	int		i;
	
	scr_centertime_off = 0;
	
	for (i=0 ; i<20 && scr_conlines != scr_con_current ; i++)
		SCR_UpdateScreen ();

	cl.cshifts[0].percent = 0;		// no area contents palette on next frame
	VID_SetPalette (host_basepal);
}


#if defined(ASM486_SCREEN_OVERLAYS) && defined(BENCH486)
#define SCR_SCREEN_OVERLAYS_C SCR_DrawScreenOverlays_Screen_C
#elif !defined(ASM486_SCREEN_OVERLAYS)
#define SCR_SCREEN_OVERLAYS_C SCR_DrawScreenOverlays
#endif

#if !defined(ASM486_SCREEN_OVERLAYS) || defined(BENCH486)
#if defined(BENCH486) && defined(ASM486_SCREEN_OVERLAYS)
#define SCREEN_OVERLAY_CALL(event, call) \
	do { \
		if (bench486_screen_overlays_fixture_active) \
			Bench486ScreenOverlaysRecordCall (event); \
		else \
			call; \
	} while (0)
#else
#define SCREEN_OVERLAY_CALL(event, call) do { call; } while (0)
#endif

void SCR_SCREEN_OVERLAYS_C (unsigned trace_update_index,
		qboolean trace_this_update)
{
#if !defined(BENCH486) || !defined(ASM486_SCREEN_CENTER_STRING)
	(void)trace_update_index;
	(void)trace_this_update;
#endif
	if (scr_drawdialog)
	{
		SCREEN_OVERLAY_CALL (SO_EVENT_SBAR_DRAW, Sbar_Draw ());
		SCREEN_OVERLAY_CALL (SO_EVENT_FADE_SCREEN, Draw_FadeScreen ());
		SCREEN_OVERLAY_CALL (SO_EVENT_NOTIFY_STRING, SCR_DrawNotifyString ());
		scr_copyeverything = true;
	}
	else if (scr_drawloading)
	{
		SCREEN_OVERLAY_CALL (SO_EVENT_DRAW_LOADING,
				SCR_DRAW_LOADING_C_CALL);
		SCREEN_OVERLAY_CALL (SO_EVENT_SBAR_DRAW, Sbar_Draw ());
	}
	else if (cl.intermission == 1 && key_dest == key_game)
	{
		SCREEN_OVERLAY_CALL (SO_EVENT_INTERMISSION, Sbar_IntermissionOverlay ());
	}
	else if (cl.intermission == 2 && key_dest == key_game)
	{
		SCREEN_OVERLAY_CALL (SO_EVENT_FINALE, Sbar_FinaleOverlay ());
		SCREEN_OVERLAY_CALL (SO_EVENT_CHECK_CENTER, SCR_CheckDrawCenterString ());
	}
	else if (cl.intermission == 3 && key_dest == key_game)
	{
		SCREEN_OVERLAY_CALL (SO_EVENT_CHECK_CENTER, SCR_CheckDrawCenterString ());
	}
	else
	{
#if defined(ASM486_SCREEN_DRAW_RAM)
		SCREEN_OVERLAY_CALL (SO_EVENT_DRAW_RAM, SCR_DrawRam_asm486 ());
#else
		SCREEN_OVERLAY_CALL (SO_EVENT_DRAW_RAM, SCR_DrawRam ());
#endif
#if defined(ASM486_SCREEN_NET)
		SCREEN_OVERLAY_CALL (SO_EVENT_DRAW_NET, SCR_DrawNet_asm486 ());
#else
		SCREEN_OVERLAY_CALL (SO_EVENT_DRAW_NET, SCR_DrawNet ());
#endif
#if defined(ASM486_SCREEN_TURTLE)
		SCREEN_OVERLAY_CALL (SO_EVENT_DRAW_TURTLE, SCR_DrawTurtle_asm486 ());
#else
		SCREEN_OVERLAY_CALL (SO_EVENT_DRAW_TURTLE, SCR_DrawTurtle ());
#endif
		SCREEN_OVERLAY_CALL (SO_EVENT_DRAW_PAUSE,
				SCR_DRAW_PAUSE_C_CALL);
#if defined(BENCH486) && defined(ASM486_SCREEN_CENTER_STRING)
		if (trace_this_update)
			Bench486ScreenCenterTraceGlyph (9, trace_update_index, 0, 0);
#endif
		SCREEN_OVERLAY_CALL (SO_EVENT_CHECK_CENTER, SCR_CheckDrawCenterString ());
#if defined(BENCH486) && defined(ASM486_SCREEN_CENTER_STRING)
		if (trace_this_update)
			Bench486ScreenCenterTraceGlyph (10, trace_update_index, 0, 0);
#endif
		SCREEN_OVERLAY_CALL (SO_EVENT_SBAR_DRAW, Sbar_Draw ());
		SCREEN_OVERLAY_CALL (SO_EVENT_DRAW_CONSOLE, SCR_DrawConsole ());
		SCREEN_OVERLAY_CALL (SO_EVENT_MENU_DRAW, M_Draw ());
	}
}

#undef SCREEN_OVERLAY_CALL
#endif

#undef SCR_SCREEN_OVERLAYS_C
#undef SCR_DRAW_PAUSE_C_ENTRY
#undef SCR_DRAW_LOADING_C_ENTRY
#undef SCR_DRAW_PAUSE_C_CALL
#undef SCR_DRAW_LOADING_C_CALL


/*
==================
SCR_UpdateScreen

This is called every frame, and can also be called explicitly to flush
text to the screen.

WARNING: be very careful calling this from elsewhere, because the refresh
needs almost the entire 256k of stack space!
==================
*/
#if defined(ASM486_SCREEN_UPDATE) && defined(BENCH486)
#define SCR_UPDATE_SCREEN_C SCR_UpdateScreen_Screen_C
#elif !defined(ASM486_SCREEN_UPDATE)
#define SCR_UPDATE_SCREEN_C SCR_UpdateScreen
#endif

#if !defined(ASM486_SCREEN_UPDATE) || defined(BENCH486)
#if defined(BENCH486) && defined(ASM486_SCREEN_UPDATE)
#define SCR_UPDATE_CALL(event, call) \
	do { \
		if (bench486_screen_update_fixture_active) \
			Bench486ScreenUpdateRecordCall (event); \
		else \
			call; \
	} while (0)
#define SCR_UPDATE_VID_RECT(rect) \
	do { \
		if (bench486_screen_update_fixture_active) \
			Bench486ScreenUpdateRecordVidRect (rect); \
		else \
			VID_Update (rect); \
	} while (0)
#else
#define SCR_UPDATE_CALL(event, call) do { call; } while (0)
#define SCR_UPDATE_VID_RECT(rect) VID_Update (rect)
#endif

void SCR_UPDATE_SCREEN_C (void)
{
#if defined(BENCH486) && defined(ASM486_SCREEN_CENTER_STRING)
	unsigned bench486_trace_update_index;
	qboolean bench486_trace_this_update;
#endif
	vrect_t		vrect;
#ifdef PROFILE486
	double		bench486_render_start;
#endif

#if defined(BENCH486) && defined(ASM486_SCREEN_CENTER_STRING)
	bench486_trace_this_update = false;
	bench486_trace_update_index = 0;
	if (bench486_screen_center_trace_active && cls.demoplayback &&
			!scr_disabled_for_loading && !scr_skipupdate && !block_drawing &&
			bench486_screen_update_trace_update_count < 8)
	{
		bench486_screen_update_trace_update_count++;
		bench486_trace_update_index = bench486_screen_update_trace_update_count;
		bench486_trace_this_update = true;
		Bench486ScreenCenterTraceGlyph (5, bench486_trace_update_index, 0, 0);
	}
#endif
	
	if (scr_skipupdate || block_drawing)
		return;

	scr_copytop = 0;
	scr_copyeverything = 0;

	if (scr_disabled_for_loading)
	{
		if (realtime - scr_disabled_time > 60)
		{
			scr_disabled_for_loading = false;
			SCR_UPDATE_CALL (SU_EVENT_CON_PRINT, Con_Printf ("load failed.\n"));
		}
		else
			return;
	}

	if (cls.state == ca_dedicated)
		return;				// stdout only

	if (!scr_initialized || !con_initialized)
		return;				// not initialized yet

	if (scr_viewsize.value != scr_update_old_viewsize)
	{
		scr_update_old_viewsize = scr_viewsize.value;
		vid.recalc_refdef = 1;
	}
	
//
// check for vid changes
//
	if (oldfov != scr_fov.value)
	{
		oldfov = scr_fov.value;
		vid.recalc_refdef = true;
	}
	
	if (scr_update_old_lcd_x != lcd_x.value)
	{
		scr_update_old_lcd_x = lcd_x.value;
		vid.recalc_refdef = true;
	}
	
	if (oldscreensize != scr_viewsize.value)
	{
		oldscreensize = scr_viewsize.value;
		vid.recalc_refdef = true;
	}
	
	if (vid.recalc_refdef)
	{
	// something changed, so reorder the screen
#if defined(ASM486_SCREEN_REFDEF)
		SCR_UPDATE_CALL (SU_EVENT_CALC_REFDEF, SCR_CalcRefdef_asm486 ());
#else
		SCR_UPDATE_CALL (SU_EVENT_CALC_REFDEF, SCR_CalcRefdef ());
#endif
	}

//
// do 3D refresh drawing, and then update the screen
//
	SCR_UPDATE_CALL (SU_EVENT_ENABLE_BACKBUFFER,
			D_EnableBackBufferAccess ());	// of all overlay stuff if drawing directly

	if (scr_fullupdate++ < vid.numpages)
	{	// clear the entire screen
		scr_copyeverything = 1;
		SCR_UPDATE_CALL (SU_EVENT_TILE_CLEAR,
				Draw_TileClear (0,0,vid.width,vid.height));
		SCR_UPDATE_CALL (SU_EVENT_SBAR_CHANGED, Sbar_Changed ());
	}

	pconupdate = NULL;


	SCR_UPDATE_CALL (SU_EVENT_SETUP_CONSOLE, SCR_SetUpToDrawConsole ());
	SCR_UPDATE_CALL (SU_EVENT_ERASE_CENTER, SCR_EraseCenterString ());

	SCR_UPDATE_CALL (SU_EVENT_DISABLE_BACKBUFFER,
			D_DisableBackBufferAccess ());	// for adapters that can't stay mapped in
									//  for linear writes all the time

	SCR_UPDATE_CALL (SU_EVENT_LOCK_BUFFER, VID_LockBuffer ());

#ifdef PROFILE486
	if (bench486_profile_frame_active)
		bench486_render_start = Sys_FloatTime ();
#endif
	BENCH486_PROFILE_ENTER (BENCH486_PROFILE_VIEW);
	#if defined(BENCH486) && defined(ASM486_SCREEN_CENTER_STRING)
	if (bench486_trace_this_update)
		Bench486ScreenCenterTraceGlyph (6, bench486_trace_update_index, 0, 0);
	#endif
	SCR_UPDATE_CALL (SU_EVENT_RENDER_VIEW, V_RenderView ());
	#if defined(BENCH486) && defined(ASM486_SCREEN_CENTER_STRING)
	if (bench486_trace_this_update)
		Bench486ScreenCenterTraceGlyph (7, bench486_trace_update_index, 0, 0);
	#endif
	BENCH486_PROFILE_LEAVE ();
#ifdef PROFILE486
	if (bench486_profile_frame_active)
		bench486_render_seconds += Sys_FloatTime () - bench486_render_start;
#endif

	SCR_UPDATE_CALL (SU_EVENT_UNLOCK_BUFFER, VID_UnlockBuffer ());

	SCR_UPDATE_CALL (SU_EVENT_ENABLE_BACKBUFFER,
			D_EnableBackBufferAccess ());	// of all overlay stuff if drawing directly

	BENCH486_PROFILE_ENTER (BENCH486_PROFILE_OVERLAY);
	#if defined(BENCH486) && defined(ASM486_SCREEN_CENTER_STRING)
	if (bench486_trace_this_update)
		Bench486ScreenCenterTraceGlyph (8, bench486_trace_update_index, 0, 0);
	#endif
#if defined(BENCH486) && defined(ASM486_SCREEN_CENTER_STRING)
	#if defined(ASM486_SCREEN_OVERLAYS)
	SCR_UPDATE_CALL (SU_EVENT_OVERLAYS,
			SCR_DrawScreenOverlays_asm486 (bench486_trace_update_index,
					bench486_trace_this_update));
	#else
	SCR_UPDATE_CALL (SU_EVENT_OVERLAYS,
			SCR_DrawScreenOverlays (bench486_trace_update_index,
					bench486_trace_this_update));
	#endif
#else
	#if defined(ASM486_SCREEN_OVERLAYS)
	SCR_UPDATE_CALL (SU_EVENT_OVERLAYS,
			SCR_DrawScreenOverlays_asm486 (0, false));
	#else
	SCR_UPDATE_CALL (SU_EVENT_OVERLAYS,
			SCR_DrawScreenOverlays (0, false));
	#endif
#endif

	#if defined(BENCH486) && defined(ASM486_SCREEN_CENTER_STRING)
	if (bench486_trace_this_update)
		Bench486ScreenCenterTraceGlyph (11, bench486_trace_update_index, 0, 0);
	#endif
	SCR_UPDATE_CALL (SU_EVENT_DISABLE_BACKBUFFER,
			D_DisableBackBufferAccess ());	// for adapters that can't stay mapped in
									//  for linear writes all the time
	if (pconupdate)
	{
		SCR_UPDATE_CALL (SU_EVENT_UPDATE_RECTS, D_UpdateRects (pconupdate));
	}
	BENCH486_PROFILE_LEAVE ();

	BENCH486_PROFILE_ENTER (BENCH486_PROFILE_PALETTE);
	SCR_UPDATE_CALL (SU_EVENT_UPDATE_PALETTE, V_UpdatePalette ());
	#if defined(BENCH486) && defined(ASM486_SCREEN_CENTER_STRING)
	if (bench486_trace_this_update)
		Bench486ScreenCenterTraceGlyph (12, bench486_trace_update_index, 0, 0);
	#endif
	BENCH486_PROFILE_LEAVE ();

//
// update one of three areas
//

	if (scr_copyeverything)
	{
		vrect.x = 0;
		vrect.y = 0;
		vrect.width = vid.width;
		vrect.height = vid.height;
		vrect.pnext = 0;
	
		SCR_UPDATE_VID_RECT (&vrect);
	}
	else if (scr_copytop)
	{
		vrect.x = 0;
		vrect.y = 0;
		vrect.width = vid.width;
		vrect.height = vid.height - sb_lines;
		vrect.pnext = 0;
	
		SCR_UPDATE_VID_RECT (&vrect);
	}	
	else
	{
		vrect.x = scr_vrect.x;
		vrect.y = scr_vrect.y;
		vrect.width = scr_vrect.width;
		vrect.height = scr_vrect.height;
		vrect.pnext = 0;
	
		SCR_UPDATE_VID_RECT (&vrect);
	}
	#if defined(BENCH486) && defined(ASM486_SCREEN_CENTER_STRING)
	if (bench486_trace_this_update)
		Bench486ScreenCenterTraceGlyph (13, bench486_trace_update_index, 0, 0);
	#endif
}
#endif

#undef SCR_UPDATE_CALL
#undef SCR_UPDATE_VID_RECT
#undef SCR_UPDATE_SCREEN_C


/*
==================
SCR_UpdateWholeScreen
==================
*/
void SCR_UpdateWholeScreen (void)
{
	scr_fullupdate = 0;
	SCR_UpdateScreen ();
}
