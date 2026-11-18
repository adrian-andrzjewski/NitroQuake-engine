/* Layout contract for screen.c:SCR_DrawTurtle. */
/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
#ifndef ASM_SCREEN_TURTLE_H
#define ASM_SCREEN_TURTLE_H

#define ST_CVAR_VALUE 16
#define ST_VRECT_X 0
#define ST_VRECT_Y 4
#define ST_VRECT_SIZE 20

#ifndef __ASSEMBLER__
#include <stddef.h>

typedef char st_cvar_value_must_match[
		(offsetof(cvar_t, value) == ST_CVAR_VALUE) ? 1 : -1];
typedef char st_vrect_x_must_match[
		(offsetof(vrect_t, x) == ST_VRECT_X) ? 1 : -1];
typedef char st_vrect_y_must_match[
		(offsetof(vrect_t, y) == ST_VRECT_Y) ? 1 : -1];
typedef char st_vrect_size_must_match[
		(sizeof(vrect_t) == ST_VRECT_SIZE) ? 1 : -1];

#ifdef ASM486_SCREEN_TURTLE
void SCR_DrawTurtle_asm486 (void);
#ifdef BENCH486
void SCR_DrawTurtle_Screen_C (void);
extern int bench486_screen_turtle_c_count;
extern int scr_turtle_count_asm486;
extern int bench486_screen_turtle_fixture_active;
void Bench486ScreenTurtleRecordDrawPic (int x, int y, qpic_t *pic);
void Bench486ScreenTurtleCases (void);
#endif
#endif

#endif

#endif /* ASM_SCREEN_TURTLE_H */
