#ifndef ASM_VIDMENU_H
#define ASM_VIDMENU_H

#define VM_MODE_COUNT 33
#define VM_MAX_COLUMN_SIZE 11
#define VM_MODE_MODE_NUMBER_OFFSET 0
#define VM_MODE_DESCRIPTION_OFFSET 4
#define VM_MODE_IS_CURRENT_OFFSET 8
#define VM_MODE_ENTRY_SIZE 12

#ifndef __ASSEMBLER__
#include <stddef.h>

typedef struct vid_menu_mode_description_s
{
	int modenum;
	char *desc;
	int iscur;
} vid_menu_mode_description_t;

typedef char vm_mode_desc_offset_must_match[
		(offsetof(vid_menu_mode_description_t, desc) ==
		VM_MODE_DESCRIPTION_OFFSET) ? 1 : -1];
typedef char vm_mode_iscur_offset_must_match[
		(offsetof(vid_menu_mode_description_t, iscur) ==
		VM_MODE_IS_CURRENT_OFFSET) ? 1 : -1];
typedef char vm_mode_size_must_match[
		(sizeof(vid_menu_mode_description_t) == VM_MODE_ENTRY_SIZE) ? 1 : -1];

extern int vid_line;
extern int vid_wmodes;
extern int vid_column_size;
extern vid_menu_mode_description_t vid_modedescs[VM_MODE_COUNT];
extern int vid_modenum;
extern int vid_testingmode;

void VID_MenuDraw (void);

#if defined(BENCH486) && defined(ASM486_SCREEN_OVERLAYS)
void VID_MenuDraw_C (void);
int Bench486VIDMenuNumModes (void);
char *Bench486VIDMenuGetModeDescription (int mode);
qpic_t *Bench486VIDMenuCachePic (char *path);
#endif

#endif

#endif
