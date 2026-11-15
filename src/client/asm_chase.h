/* Original chase storage contracts and independent benchmark boundaries. */
#ifndef ASM_CHASE_H
#define ASM_CHASE_H
#ifndef __ASSEMBLER__
#include <stddef.h>
#include "collision/asm_hullcheck.h"
void TraceLine(vec3_t,vec3_t,vec3_t);
#ifdef BENCH486
extern void (*bench486_chase_register_probe)(cvar_t *);
/* The original implicit declaration passes integer 0/1 bits to the float
   fractions. Keep those stack bits; do not silently normalize 1 to 1.0f. */
extern qboolean (*bench486_chase_hull_probe)(hull_t *,int,int,int,vec3_t,vec3_t,trace_t *);
void Bench486ChaseRegister(cvar_t *);
qboolean Bench486ChaseHullCheck(hull_t *,int,int,int,vec3_t,vec3_t,trace_t *);
/* Typed alias avoids changing the original C call's implicit prototype. */
qboolean Bench486ChaseOriginalHull(hull_t *,int,float,float,vec3_t,vec3_t,trace_t *)
    __asm__("_SV_RecursiveHullCheck");
void Chase_Init_Chase_C(void),Chase_Reset_Chase_C(void),Chase_Update_Chase_C(void);
void TraceLine_Chase_C(vec3_t,vec3_t,vec3_t);
#endif
typedef char chase_client_size_must_match[(sizeof(client_state_t)==2900U)?1:-1];
typedef char chase_model_size_must_match[(sizeof(model_t)==392U)?1:-1];
typedef char chase_refdef_size_must_match[(sizeof(refdef_t)==148U)?1:-1];
typedef char chase_cvar_size_must_match[(sizeof(cvar_t)==24U)?1:-1];
typedef char chase_client_state_t_viewangles_must_match[(offsetof(client_state_t,viewangles)==444U)?1:-1];
typedef char chase_client_state_t_worldmodel_must_match[(offsetof(client_state_t,worldmodel)==2692U)?1:-1];
typedef char chase_model_t_hulls_must_match[(offsetof(model_t,hulls)==208U)?1:-1];
typedef char chase_refdef_t_vieworg_must_match[(offsetof(refdef_t,vieworg)==112U)?1:-1];
typedef char chase_refdef_t_viewangles_must_match[(offsetof(refdef_t,viewangles)==124U)?1:-1];
typedef char chase_cvar_t_value_must_match[(offsetof(cvar_t,value)==16U)?1:-1];
#endif
#endif
