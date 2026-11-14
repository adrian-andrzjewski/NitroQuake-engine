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
//
// vid_dos.c: DOS-specific video routines
//

#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <dos.h>
#include <dpmi.h>
#include <go32.h>

#include "quakedef.h"
#include "tests/bench486/bench486_profile.h"
#include "renderer/d_local.h"
#include "platform/dos/dosisms.h"
#include "video/vid_dos.h"
#include "video/asm_vidupdate.h"
#include "video/asm_viddirectrect.h"
#include "video/asm_vidmode.h"
#include "video/asm_vidmenu.h"

#if defined(BENCH486) && defined(ASM486_VID_UPDATE)
#define VID_GET_MODE_PTR_C_ENTRY VID_GetModePtr_C
#define VID_MODE_INFO_C_ENTRY VID_ModeInfo_C
#define VID_SET_MODE_C_ENTRY VID_SetMode_C
#define VID_GET_MODE_PTR_C_CALL VID_GetModePtr_C
#define VID_MODE_INFO_C_CALL VID_ModeInfo_C
#define VID_SET_MODE_C_CALL VID_SetMode_C
#define VID_SET_PALETTE_C_ENTRY VID_SetPalette_C
#define VID_SHIFT_PALETTE_C_ENTRY VID_ShiftPalette_C
#else
#define VID_GET_MODE_PTR_C_ENTRY VID_GetModePtr
#define VID_MODE_INFO_C_ENTRY VID_ModeInfo
#define VID_SET_MODE_C_ENTRY VID_SetMode
#define VID_GET_MODE_PTR_C_CALL VID_GetModePtr
#define VID_MODE_INFO_C_CALL VID_ModeInfo
#define VID_SET_MODE_C_CALL VID_SetMode
#define VID_SET_PALETTE_C_ENTRY VID_SetPalette
#define VID_SHIFT_PALETTE_C_ENTRY VID_ShiftPalette
#endif

#if defined(BENCH486) && defined(ASM486_VID_UPDATE)
#define VID_SHUTDOWN_C_ENTRY VID_Shutdown_C
#else
#define VID_SHUTDOWN_C_ENTRY VID_Shutdown
#endif

#if defined(BENCH486) && defined(ASM486_VID_UPDATE_FIXTURE)
#define VID_MODE_SET_VALUE Bench486VidModeSetValue
#define VID_MODE_PRINTF Bench486VidModePrintf
#define VID_MODE_ERROR Bench486VidModeError
#define VID_MODE_RELEASE_EXTRA Bench486VidModeReleaseExtra
#define VID_MODE_PALETTE_OK Bench486VidModePaletteOK
#else
#define VID_MODE_SET_VALUE Cvar_SetValue
#define VID_MODE_PRINTF Con_Printf
#define VID_MODE_ERROR Sys_Error
#define VID_MODE_RELEASE_EXTRA VID_ExtraReleaseMode
#define VID_MODE_PALETTE_OK VID_ExtraPaletteOK
#endif

#if defined(BENCH486) && defined(ASM486_VID_UPDATE_FIXTURE)
#define VID_SHUTDOWN_INT86(vector) Bench486VidShutdownInt86 (vector)
#define VID_SHUTDOWN_EXTRA() Bench486VidShutdownExtra ()
#else
#define VID_SHUTDOWN_INT86(vector) dos_int86 (vector)
#define VID_SHUTDOWN_EXTRA() VID_ShutdownExtra ()
#endif

int			vid_modenum;
vmode_t		*pcurrentmode = NULL;
int			vid_testingmode, vid_realmode;
double		vid_testendtime;

cvar_t		vid_mode = {"vid_mode","0", false};
cvar_t		vid_wait = {"vid_wait","0"};
cvar_t		vid_nopageflip = {"vid_nopageflip","0", true};
cvar_t		_vid_wait_override = {"_vid_wait_override", "0", true};
cvar_t		_vid_default_mode = {"_vid_default_mode","0", true};
cvar_t		vid_stretch_by_2 = {"vid_stretch_by_2","1", true};
cvar_t		block_switch = {"block_switch","0", true};

int	d_con_indirect = 0;

int		numvidmodes;
vmode_t	*pvidmodes;

int	vid_firstupdate = 1;
qboolean vid_startup_mode_requested;

extern regs_t regs;

void VID_TestMode_f (void);
void VID_NumModes_f (void);
void VID_DescribeCurrentMode_f (void);
void VID_DescribeMode_f (void);
void VID_DescribeModes_f (void);

byte	vid_current_palette[768];	// save for mode changes


qboolean	vid_nomodecheck = false;

unsigned short	d_8to16table[256];	// not used in 8 bpp mode
unsigned		d_8to24table[256];	// not used in 8 bpp mode

void VID_MenuDraw (void);
void VID_MenuKey (int key);


/*
================
VID_Init
================
*/
void    VID_Init (unsigned char *palette)
{
	Cvar_RegisterVariable (&vid_mode);
	Cvar_RegisterVariable (&vid_wait);
	Cvar_RegisterVariable (&vid_nopageflip);
	Cvar_RegisterVariable (&_vid_wait_override);
	Cvar_RegisterVariable (&_vid_default_mode);
	Cvar_RegisterVariable (&vid_stretch_by_2);
	Cvar_RegisterVariable (&block_switch);

	Cmd_AddCommand ("vid_testmode", VID_TestMode_f);
	Cmd_AddCommand ("vid_nummodes", VID_NumModes_f);
	Cmd_AddCommand ("vid_describecurrentmode", VID_DescribeCurrentMode_f);
	Cmd_AddCommand ("vid_describemode", VID_DescribeMode_f);
	Cmd_AddCommand ("vid_describemodes", VID_DescribeModes_f);

// set up the mode list; note that later inits link in their modes ahead of
// earlier ones, so the standard VGA modes are always first in the list. This
// is important because mode 0 must always be VGA mode 0x13
	if (!COM_CheckParm ("-stdvid"))
		VID_InitExtra ();
	VGA_Init ();

	vid_testingmode = 0;

	vid_modenum = vid_mode.value;

	VID_ReportSystem ();
	VID_SetMode (vid_modenum, palette);

	vid_realmode = vid_modenum;
	
	vid_menudrawfn = VID_MenuDraw;
	vid_menukeyfn = VID_MenuKey;
}


/*
=================
VID_GetModePtr
=================
*/
#if !defined(ASM486_VID_UPDATE) || defined(BENCH486)
vmode_t *VID_GET_MODE_PTR_C_ENTRY (int modenum)
{
	vmode_t	*pv;

	pv = pvidmodes;
	if (!pv)
		VID_MODE_ERROR ("VID_GetModePtr: empty vid mode list");

	while (modenum--)
	{
		pv = pv->pnext;
		if (!pv)
			VID_MODE_ERROR ("VID_GetModePtr: corrupt vid mode list");
	}

	return pv;
}
#endif

/*
================
VID_NumModes
================
*/
int VID_NumModes ()
{
	return (numvidmodes);
}


/*
================
VID_ModeInfo
================
*/
#if !defined(ASM486_VID_UPDATE) || defined(BENCH486)
char *VID_MODE_INFO_C_ENTRY (int modenum, char **ppheader)
{
	static char	*badmodestr = "Bad mode number";
	vmode_t		*pv;

	pv = VID_GET_MODE_PTR_C_CALL (modenum);

	if (!pv)
	{
		if (ppheader)
			*ppheader = NULL;
		return badmodestr;
	}
	else
	{
		if (ppheader)
			*ppheader = pv->header;
		return pv->name;
	}
}
#endif


/*
================
VID_SetMode 
================
*/
#if !defined(ASM486_VID_UPDATE) || defined(BENCH486)
int VID_SET_MODE_C_ENTRY (int modenum, unsigned char *palette)
{
	int		stat, requested = modenum, attempt;
	vmode_t	*pnewmode;
	qboolean was_disabled = scr_disabled_for_loading;

	if ((modenum >= numvidmodes) || (modenum < 0))
	{
		VID_MODE_SET_VALUE ("vid_mode", (float)vid_modenum);

		vid_nomodecheck = true;
		VID_MODE_PRINTF ("No such video mode: %d\n", modenum);
		vid_nomodecheck = false;

		if (pcurrentmode == NULL)
		{
			modenum = 0;	// mode hasn't been set yet, so initialize to base
							//  mode since they gave us an invalid initial mode
		}
		else
		{
			return 0;
		}
	}

	pnewmode = VID_GET_MODE_PTR_C_CALL (modenum);

	if (pnewmode == pcurrentmode)
		return 1;	// already in the desired mode

// No recursive restoration: try the requested mode, then VGA exactly once.
// Suppress screen updates while buffers/mappings are being replaced.
	vid_nomodecheck = true;
	scr_disabled_for_loading = true;
	for (attempt = 0; attempt < 2; attempt++)
	{
		VID_MODE_RELEASE_EXTRA ();
		vid.direct = NULL;
		pcurrentmode = VID_GET_MODE_PTR_C_CALL (modenum);
		vid.width = pcurrentmode->width;
		vid.height = pcurrentmode->height;
		vid.aspect = pcurrentmode->aspect;
		vid.rowbytes = pcurrentmode->rowbytes;
		stat = (*pcurrentmode->setmode) (&vid, pcurrentmode);
		if (stat > 0)
		{
			(*pcurrentmode->setpalette) (&vid, pcurrentmode, palette);
			if (VID_MODE_PALETTE_OK ()) break;
		}
		VID_MODE_PRINTF ("Video: mode %d initialization failed; falling back to VGA mode 13h\n", modenum);
		if (modenum == 0 || attempt == 1)
			VID_MODE_ERROR ("VID_SetMode: unable to initialize VGA mode 13h");
		modenum = 0;
	}
	Q_memcpy (vid_current_palette, palette, 768);

	vid_modenum = modenum;
	VID_MODE_SET_VALUE ("vid_mode", (float)vid_modenum);
	vid.recalc_refdef = 1;

	vid_nomodecheck = true;
	VID_MODE_PRINTF ("Video mode %d: %s\n", vid_modenum,
			VID_MODE_INFO_C_CALL (vid_modenum, NULL));
	if (modenum == 0)
		VID_MODE_PRINTF ("Video: VGA BIOS 0x13 pitch 320, 1 page, RAM copy\n");
	vid_nomodecheck = false;
	scr_disabled_for_loading = was_disabled;

	return modenum == requested;
}
#endif

#undef VID_MODE_RELEASE_EXTRA
#undef VID_MODE_ERROR
#undef VID_MODE_PRINTF
#undef VID_MODE_SET_VALUE
#undef VID_MODE_INFO_C_CALL
#undef VID_GET_MODE_PTR_C_CALL
#undef VID_SET_MODE_C_ENTRY
#undef VID_MODE_INFO_C_ENTRY
#undef VID_GET_MODE_PTR_C_ENTRY


/*
================
VID_SetPalette
================
*/
#if !defined(ASM486_VID_UPDATE) || defined(BENCH486)
void VID_SET_PALETTE_C_ENTRY (unsigned char *palette)
{
	if (palette != vid_current_palette)
		Q_memcpy(vid_current_palette, palette, 768);
	(*pcurrentmode->setpalette)(&vid, pcurrentmode, vid_current_palette);
	if (!VID_MODE_PALETTE_OK ())
		VID_SET_MODE_C_CALL (0, vid_current_palette);
}


/*
================
VID_ShiftPalette
================
*/
void VID_SHIFT_PALETTE_C_ENTRY (unsigned char *palette)
{
	VID_SET_PALETTE_C_ENTRY (palette);
}
#endif

#undef VID_MODE_PALETTE_OK
#undef VID_SET_MODE_C_CALL
#undef VID_SET_PALETTE_C_ENTRY
#undef VID_SHIFT_PALETTE_C_ENTRY


/*
================
VID_Shutdown
================
*/
#if !defined(ASM486_VID_UPDATE) || defined(BENCH486)
void VID_SHUTDOWN_C_ENTRY (void)
{

	regs.h.ah = 0;
	regs.h.al = 0x3;
	VID_SHUTDOWN_INT86 (0x10);
	VID_SHUTDOWN_EXTRA ();

	vid_testingmode = 0;
}
#endif

#undef VID_SHUTDOWN_INT86
#undef VID_SHUTDOWN_EXTRA
#undef VID_SHUTDOWN_C_ENTRY


/*
================
VID_Update
================
*/
#if defined(BENCH486)
#define VID_UPDATE_C_ENTRY VID_Update_C
#else
#define VID_UPDATE_C_ENTRY VID_Update
#endif

#if !defined(ASM486_VID_UPDATE) || defined(BENCH486)
#if defined(BENCH486) && defined(ASM486_VID_UPDATE_FIXTURE)
#define VID_UPDATE_SET_MODE(mode, palette) \
	Bench486VidUpdateSetMode ((mode), (palette))
#define VID_UPDATE_DEFAULT_MODE() Bench486VidUpdateDefaultMode ()
#define VID_UPDATE_SET_CVAR(name, value) \
	Bench486VidUpdateSetValue ((name), (value))
#define VID_UPDATE_NO_VESA_MESSAGE(text) \
	Bench486VidUpdateNoVesaMessage (text)
#else
#define VID_UPDATE_SET_MODE(mode, palette) VID_SetMode ((mode), (palette))
#define VID_UPDATE_DEFAULT_MODE() VID_ExtraDefaultMode ()
#define VID_UPDATE_SET_CVAR(name, value) Cvar_SetValue ((name), (value))
#define VID_UPDATE_NO_VESA_MESSAGE(text) Con_Printf (text)
#endif

void    VID_UPDATE_C_ENTRY (vrect_t *rects)
{
#ifdef PROFILE486
	double		bench486_framebuffer_start;
	vrect_t		*profile_rect;
	unsigned long	profile_present_pixels;
	unsigned long	profile_present_rects;

	if (bench486_profile_frame_active)
		bench486_framebuffer_start = Sys_FloatTime ();
#endif
	BENCH486_PROFILE_ENTER (BENCH486_PROFILE_PRESENT);

#ifdef PROFILE486
	profile_present_pixels = 0;
	profile_present_rects = 0;
	for (profile_rect = rects ; profile_rect ;
			profile_rect = profile_rect->pnext)
	{
		profile_present_rects++;
		profile_present_pixels += (unsigned long)profile_rect->width *
				(unsigned long)profile_rect->height;
	}
#endif

	// Console printing can update the screen halfway through quake.rc.
	// Wait until a complete host frame has executed the startup commands.
	if (vid_firstupdate && host_framecount > 0 && !vid_nomodecheck)
	{
		vid_firstupdate = 0;
		if (_vid_default_mode.value < 0 || _vid_default_mode.value >= numvidmodes)
			VID_UPDATE_SET_CVAR ("_vid_default_mode", 0);
		if (COM_CheckParm("-stdvid"))
			VID_UPDATE_SET_CVAR ("vid_mode", 0);
		else if (!vid_startup_mode_requested && !COM_CheckParm("+vid_mode") && vid_mode.value == vid_modenum)
		{
			if (_vid_default_mode.value)
				VID_UPDATE_SET_CVAR ("vid_mode", _vid_default_mode.value);
			else
			{
				VID_UPDATE_SET_CVAR ("vid_mode", VID_UPDATE_DEFAULT_MODE());
				if (!vid_mode.value)
					VID_UPDATE_NO_VESA_MESSAGE (
							"Video: no usable VESA 320x200x8 mode; using VGA mode 13h\n");
			}
		}
	}

	(*pcurrentmode->swapbuffers)(&vid, pcurrentmode, rects);

#ifdef PROFILE486
	if (bench486_profile_frame_active)
		bench486_framebuffer_seconds += Sys_FloatTime () -
				bench486_framebuffer_start;
#endif

	if (!vid_nomodecheck)
	{
		if (vid_testingmode)
		{
			if (realtime >= vid_testendtime)
			{
				VID_UPDATE_SET_MODE (vid_realmode, vid_current_palette);
				vid_testingmode = 0;
			}
		}
		else
		{
			if (vid_mode.value != vid_realmode)
			{
				if (vid_firstupdate) vid_startup_mode_requested = true;
				VID_UPDATE_SET_MODE ((int)vid_mode.value, vid_current_palette);
				VID_UPDATE_SET_CVAR ("vid_mode", (float)vid_modenum);
									// so if mode set fails, we don't keep on
									//  trying to set that mode
				vid_realmode = vid_modenum;
			}
		}
	}

#ifdef PROFILE486
	if (bench486_profile_frame_active)
	{
		bench486_present_rects += profile_present_rects;
		bench486_present_pixels += profile_present_pixels;
	}
#endif
	BENCH486_PROFILE_WORK (BENCH486_PROFILE_PRESENT,
			profile_present_rects, profile_present_pixels);
	BENCH486_PROFILE_LEAVE ();
}
#undef VID_UPDATE_SET_MODE
#undef VID_UPDATE_DEFAULT_MODE
#undef VID_UPDATE_SET_CVAR
#undef VID_UPDATE_NO_VESA_MESSAGE
#endif

#if defined(BENCH486) && !defined(ASM486_VID_UPDATE)
void VID_Update (vrect_t *rects)
{
	VID_Update_C (rects);
}
#endif

#undef VID_UPDATE_C_ENTRY

#if defined(BENCH486) && defined(ASM486_VID_UPDATE_FIXTURE)
#include "tests/bench486/bench486_vidupdate.h"
#include "tests/bench486/bench486_vidmode.h"
#endif


/*
=================
VID_NumModes_f
=================
*/
void VID_NumModes_f (void)
{
	int		nummodes;

	nummodes = VID_NumModes ();
	if (nummodes == 1)
		Con_Printf ("%d video mode is available\n", VID_NumModes ());
	else
		Con_Printf ("%d video modes are available\n", VID_NumModes ());
}


/*
=================
VID_DescribeCurrentMode_f
=================
*/
void VID_DescribeCurrentMode_f (void)
{
	Con_Printf ("%s\n", VID_ModeInfo (vid_modenum, NULL));
}


/*
=================
VID_DescribeMode_f
=================
*/
void VID_DescribeMode_f (void)
{
	int		modenum;
	
	modenum = Q_atoi (Cmd_Argv(1));

	Con_Printf ("%s\n", VID_ModeInfo (modenum, NULL));
}


/*
=================
VID_DescribeModes_f
=================
*/
void VID_DescribeModes_f (void)
{
	int			i, nummodes;
	char		*pinfo, *pheader;
	vmode_t		*pv;
	qboolean	na;

	na = false;

	nummodes = VID_NumModes ();
	for (i=0 ; i<nummodes ; i++)
	{
		pv = VID_GetModePtr (i);
		pinfo = VID_ModeInfo (i, &pheader);
		if (pheader)
			Con_Printf ("\n%s\n", pheader);

		if (VGA_CheckAdequateMem (pv->width, pv->height, pv->rowbytes,
			(pv->numpages == 1) || vid_nopageflip.value))
		{
			Con_Printf ("%2d: %s\n", i, pinfo);
		}
		else
		{
			Con_Printf ("**: %s\n", pinfo);
			na = true;
		}
	}

	if (na)
	{
		Con_Printf ("\n[**: not enough system RAM for mode]\n");
	}
}


/*
=================
VID_GetModeDescription
=================
*/
char *VID_GetModeDescription (int mode)
{
	char		*pinfo, *pheader;
	vmode_t		*pv;

	pv = VID_GetModePtr (mode);
	pinfo = VID_ModeInfo (mode, &pheader);

	if (VGA_CheckAdequateMem (pv->width, pv->height, pv->rowbytes,
		(pv->numpages == 1) || vid_nopageflip.value))
	{
		return pinfo;
	}
	else
	{
		return NULL;
	}
}


/*
=================
VID_TestMode_f
=================
*/
void VID_TestMode_f (void)
{
	int		modenum;
	double	testduration;

	if (!vid_testingmode)
	{
		modenum = Q_atoi (Cmd_Argv(1));

		if (VID_SetMode (modenum, vid_current_palette))
		{
			vid_testingmode = 1;
			testduration = Q_atof (Cmd_Argv(2));
			if (testduration == 0)
				testduration = 5.0;
			vid_testendtime = realtime + testduration;
		}
	}
}


/*
================
D_BeginDirectRect
================
*/
#if defined(BENCH486) && defined(ASM486_VID_UPDATE)
#define D_BEGIN_DIRECTRECT_C_ENTRY D_BeginDirectRect_C
#define D_END_DIRECTRECT_C_ENTRY D_EndDirectRect_C
#else
#define D_BEGIN_DIRECTRECT_C_ENTRY D_BeginDirectRect
#define D_END_DIRECTRECT_C_ENTRY D_EndDirectRect
#endif

#if !defined(ASM486_VID_UPDATE) || defined(BENCH486)
void D_BEGIN_DIRECTRECT_C_ENTRY (int x, int y, byte *pbitmap,
	int width, int height)
{

	if (!vid.direct || !pcurrentmode)
		return;

	if ((width > 24) || (height > 24) || (width < 1) || (height < 1))
		return;

	if (width & 0x03)
		return;

	(*pcurrentmode->begindirectrect) (&vid, pcurrentmode, x, y, pbitmap, width,
									  height);
}


/*
================
D_EndDirectRect
================
*/
void D_END_DIRECTRECT_C_ENTRY (int x, int y, int width, int height)
{

	if (!vid.direct || !pcurrentmode)
		return;

	if ((width > 24) || (height > 24) || (width < 1) || (height < 1))
		return;

	if ((width & 0x03) || (height & 0x03))
		return;

	(*pcurrentmode->enddirectrect) (&vid, pcurrentmode, x, y, width, height);
}
#endif

#undef D_BEGIN_DIRECTRECT_C_ENTRY
#undef D_END_DIRECTRECT_C_ENTRY

#if defined(BENCH486) && defined(ASM486_VID_UPDATE_FIXTURE)
#include "tests/bench486/bench486_viddirectrect.h"
#endif


//===========================================================================

extern void M_Menu_Options_f (void);
extern void M_Print (int cx, int cy, char *str);
extern void M_PrintWhite (int cx, int cy, char *str);
extern void M_DrawCharacter (int cx, int line, int num);
extern void M_DrawTransPic (int x, int y, qpic_t *pic);
extern void M_DrawPic (int x, int y, qpic_t *pic);

#define MAX_COLUMN_SIZE	VM_MAX_COLUMN_SIZE
#define MAX_MODEDESCS	VM_MODE_COUNT

int	vid_line, vid_wmodes, vid_column_size;
vid_menu_mode_description_t vid_modedescs[VM_MODE_COUNT];

/*
================
VID_MenuDraw
================
*/
#if defined(BENCH486) && defined(ASM486_SCREEN_OVERLAYS)
#define VID_MENU_DRAW_C_ENTRY VID_MenuDraw_C
#define VID_MENU_DRAW_CACHE_PIC(path) Bench486VIDMenuCachePic (path)
#define VID_MENU_DRAW_NUM_MODES() Bench486VIDMenuNumModes ()
#define VID_MENU_DRAW_MODE_DESCRIPTION(mode) \
		Bench486VIDMenuGetModeDescription (mode)
#else
#define VID_MENU_DRAW_C_ENTRY VID_MenuDraw
#define VID_MENU_DRAW_CACHE_PIC(path) Draw_CachePic (path)
#define VID_MENU_DRAW_NUM_MODES() VID_NumModes ()
#define VID_MENU_DRAW_MODE_DESCRIPTION(mode) VID_GetModeDescription (mode)
#endif

#if !defined(ASM486_SCREEN_OVERLAYS) || defined(BENCH486)
void VID_MENU_DRAW_C_ENTRY (void)
{
	qpic_t		*p;
	char		*ptr;
	int			nummodes, i, j, column, row, dup;
	char		temp[100];

	vid_wmodes = 0;
	nummodes = VID_MENU_DRAW_NUM_MODES ();
	
	p = VID_MENU_DRAW_CACHE_PIC ("gfx/vidmodes.lmp");
	M_DrawPic ( (320-p->width)/2, 4, p);

	for (i=0 ; i<nummodes ; i++)
	{
		if (vid_wmodes < MAX_MODEDESCS)
		{
			if (i != 1)
			{
			ptr = VID_MENU_DRAW_MODE_DESCRIPTION (i);

				if (ptr)
				{
					dup = 0;

					for (j=0 ; j<vid_wmodes ; j++)
					{
						if (!strcmp (vid_modedescs[j].desc, ptr))
						{
							if (vid_modedescs[j].modenum != 0)
							{
								vid_modedescs[j].modenum = i;
								dup = 1;

								if (i == vid_modenum)
									vid_modedescs[j].iscur = 1;
							}
							else
							{
								dup = 1;
							}

							break;
						}
					}

					if (!dup)
					{
						vid_modedescs[vid_wmodes].modenum = i;
						vid_modedescs[vid_wmodes].desc = ptr;
						vid_modedescs[vid_wmodes].iscur = 0;

						if (i == vid_modenum)
							vid_modedescs[vid_wmodes].iscur = 1;

						vid_wmodes++;
					}
				}
			}
		}
	}

	vid_column_size = (vid_wmodes + 2) / 3;

	column = 16;
	row = 36;

	for (i=0 ; i<vid_wmodes ; i++)
	{
		if (vid_modedescs[i].iscur)
			M_PrintWhite (column, row, vid_modedescs[i].desc);
		else
			M_Print (column, row, vid_modedescs[i].desc);

		row += 8;

		if ((i % vid_column_size) == (vid_column_size - 1))
		{
			column += 13*8;
			row = 36;
		}
	}

// line cursor
	if (vid_testingmode)
	{
		sprintf (temp, "TESTING %s",
				vid_modedescs[vid_line].desc);
		M_Print (13*8, 36 + MAX_COLUMN_SIZE * 8 + 8*4, temp);
		M_Print (9*8, 36 + MAX_COLUMN_SIZE * 8 + 8*6,
				"Please wait 5 seconds...");
	}
	else
	{
		M_Print (9*8, 36 + MAX_COLUMN_SIZE * 8 + 8,
				"Press Enter to set mode");
		M_Print (6*8, 36 + MAX_COLUMN_SIZE * 8 + 8*3,
				"T to test mode for 5 seconds");
		ptr = VID_MENU_DRAW_MODE_DESCRIPTION (vid_modenum);
		sprintf (temp, "D to make %s the default", ptr);
		M_Print (6*8, 36 + MAX_COLUMN_SIZE * 8 + 8*5, temp);
		ptr = VID_MENU_DRAW_MODE_DESCRIPTION ((int)_vid_default_mode.value);

		if (ptr)
		{
			sprintf (temp, "Current default is %s", ptr);
			M_Print (7*8, 36 + MAX_COLUMN_SIZE * 8 + 8*6, temp);
		}

		M_Print (15*8, 36 + MAX_COLUMN_SIZE * 8 + 8*8,
				"Esc to exit");

		row = 36 + (vid_line % vid_column_size) * 8;
		column = 8 + (vid_line / vid_column_size) * 13*8;

		M_DrawCharacter (column, row, 12+((int)(realtime*4)&1));
	}
}
#endif

#undef VID_MENU_DRAW_C_ENTRY
#undef VID_MENU_DRAW_CACHE_PIC
#undef VID_MENU_DRAW_NUM_MODES
#undef VID_MENU_DRAW_MODE_DESCRIPTION


/*
================
VID_MenuKey
================
*/
void VID_MenuKey (int key)
{
	if (vid_testingmode)
		return;

	switch (key)
	{
	case K_ESCAPE:
		S_LocalSound ("misc/menu1.wav");
		M_Menu_Options_f ();
		break;

	case K_UPARROW:
		S_LocalSound ("misc/menu1.wav");
		vid_line--;

		if (vid_line < 0)
			vid_line = vid_wmodes - 1;
		break;

	case K_DOWNARROW:
		S_LocalSound ("misc/menu1.wav");
		vid_line++;

		if (vid_line >= vid_wmodes)
			vid_line = 0;
		break;

	case K_LEFTARROW:
		S_LocalSound ("misc/menu1.wav");
		vid_line -= vid_column_size;

		if (vid_line < 0)
		{
			vid_line += ((vid_wmodes + (vid_column_size - 1)) /
					vid_column_size) * vid_column_size;

			while (vid_line >= vid_wmodes)
				vid_line -= vid_column_size;
		}
		break;

	case K_RIGHTARROW:
		S_LocalSound ("misc/menu1.wav");
		vid_line += vid_column_size;

		if (vid_line >= vid_wmodes)
		{
			vid_line -= ((vid_wmodes + (vid_column_size - 1)) /
					vid_column_size) * vid_column_size;

			while (vid_line < 0)
				vid_line += vid_column_size;
		}
		break;

	case K_ENTER:
		S_LocalSound ("misc/menu1.wav");
		VID_SetMode (vid_modedescs[vid_line].modenum, vid_current_palette);
		break;

	case 'T':
	case 't':
		S_LocalSound ("misc/menu1.wav");
		if (VID_SetMode (vid_modedescs[vid_line].modenum, vid_current_palette))
		{
			vid_testingmode = 1;
			vid_testendtime = realtime + 5.0;
		}
		break;

	case 'D':
	case 'd':
		S_LocalSound ("misc/menu1.wav");
		vid_firstupdate = 0;
		Cvar_SetValue ("_vid_default_mode", vid_modenum);
		break;

	default:
		break;
	}
}

