/* Audited structure contracts for screen.c:SCR_CalcRefdef. */
#ifndef ASM_SCREEN_REFDEF_H
#define ASM_SCREEN_REFDEF_H

#define SR_VRECT_X 0
#define SR_VRECT_Y 4
#define SR_VRECT_WIDTH 8
#define SR_VRECT_HEIGHT 12
#define SR_VRECT_PNEXT 16
#define SR_VRECT_SIZE 20
#define SR_VID_WIDTH 20
#define SR_VID_HEIGHT 24
#define SR_VID_ASPECT 28
#define SR_VID_NUMPAGES 32
#define SR_VID_RECALC_REFDEF 36
#define SR_VID_SIZE 68
#define SR_CVAR_VALUE 16
#define SR_CVAR_SIZE 24
#define SR_CLIENT_INTERMISSION 548
#define SR_CLIENT_STATE_SIZE 2900
#define SR_REFDEF_FOV_X 136
#define SR_REFDEF_FOV_Y 140
#define SR_REFDEF_SIZE 148

#ifndef __ASSEMBLER__
#include <stddef.h>

typedef char sr_vrect_size_must_match[(sizeof(vrect_t) == SR_VRECT_SIZE) ? 1 : -1];
typedef char sr_vrect_width_must_match[(offsetof(vrect_t, width) == SR_VRECT_WIDTH) ? 1 : -1];
typedef char sr_vrect_height_must_match[(offsetof(vrect_t, height) == SR_VRECT_HEIGHT) ? 1 : -1];
typedef char sr_vid_width_must_match[(offsetof(viddef_t, width) == SR_VID_WIDTH) ? 1 : -1];
typedef char sr_vid_height_must_match[(offsetof(viddef_t, height) == SR_VID_HEIGHT) ? 1 : -1];
typedef char sr_vid_aspect_must_match[(offsetof(viddef_t, aspect) == SR_VID_ASPECT) ? 1 : -1];
typedef char sr_vid_recalc_must_match[(offsetof(viddef_t, recalc_refdef) == SR_VID_RECALC_REFDEF) ? 1 : -1];
typedef char sr_vid_size_must_match[(sizeof(viddef_t) == SR_VID_SIZE) ? 1 : -1];
typedef char sr_cvar_value_must_match[(offsetof(cvar_t, value) == SR_CVAR_VALUE) ? 1 : -1];
typedef char sr_cvar_size_must_match[(sizeof(cvar_t) == SR_CVAR_SIZE) ? 1 : -1];
typedef char sr_client_intermission_must_match[
		(offsetof(client_state_t, intermission) == SR_CLIENT_INTERMISSION) ? 1 : -1];
typedef char sr_client_size_must_match[
		(sizeof(client_state_t) == SR_CLIENT_STATE_SIZE) ? 1 : -1];
typedef char sr_refdef_fov_x_must_match[(offsetof(refdef_t, fov_x) == SR_REFDEF_FOV_X) ? 1 : -1];
typedef char sr_refdef_fov_y_must_match[(offsetof(refdef_t, fov_y) == SR_REFDEF_FOV_Y) ? 1 : -1];
typedef char sr_refdef_size_must_match[(sizeof(refdef_t) == SR_REFDEF_SIZE) ? 1 : -1];

#if defined(BENCH486) && defined(ASM486_SCREEN_REFDEF)
void SCR_CalcRefdef_Screen_C (void);
void SCR_CalcRefdef_asm486 (void);
void Bench486ScreenRefdefSbarChanged (void);
void Bench486ScreenRefdefCvarSet (const char *name, const char *value);
void Bench486ScreenRefdefViewChanged (vrect_t *rect, int lineadj, float aspect);
void Bench486ScreenRefdefCases (void);
#endif
#endif

#endif
