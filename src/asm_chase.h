/* Original chase storage contracts and independent benchmark boundaries. */
#ifndef ASM_CHASE_H
#define ASM_CHASE_H
#ifndef __ASSEMBLER__
#include <stddef.h>
extern cvar_t chase_back,chase_up,chase_right,chase_active;
extern vec3_t chase_pos,chase_angles,chase_dest,chase_dest_angles;
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
typedef char chase_pointer_size_must_match[(sizeof(void *)==4U)?1:-1];
typedef char chase_float_size_must_match[(sizeof(float)==4U)?1:-1];
typedef char chase_integer_size_must_match[(sizeof(int)==4U)?1:-1];
typedef char chase_trace_size_must_match[(sizeof(trace_t)==52U)?1:-1];
typedef char chase_client_size_must_match[(sizeof(client_state_t)==2900U)?1:-1];
typedef char chase_model_size_must_match[(sizeof(model_t)==392U)?1:-1];
typedef char chase_refdef_size_must_match[(sizeof(refdef_t)==148U)?1:-1];
typedef char chase_cvar_size_must_match[(sizeof(cvar_t)==24U)?1:-1];
typedef char chase_hull_size_must_match[(sizeof(hull_t)==40U)?1:-1];
typedef char chase_trace_t_allsolid_must_match[(offsetof(trace_t,allsolid)==0U)?1:-1];
typedef char chase_trace_t_startsolid_must_match[(offsetof(trace_t,startsolid)==4U)?1:-1];
typedef char chase_trace_t_inopen_must_match[(offsetof(trace_t,inopen)==8U)?1:-1];
typedef char chase_trace_t_inwater_must_match[(offsetof(trace_t,inwater)==12U)?1:-1];
typedef char chase_trace_t_fraction_must_match[(offsetof(trace_t,fraction)==16U)?1:-1];
typedef char chase_trace_t_endpos_must_match[(offsetof(trace_t,endpos)==20U)?1:-1];
typedef char chase_trace_t_plane_must_match[(offsetof(trace_t,plane)==32U)?1:-1];
typedef char chase_trace_t_ent_must_match[(offsetof(trace_t,ent)==48U)?1:-1];
typedef char chase_client_state_t_viewangles_must_match[(offsetof(client_state_t,viewangles)==444U)?1:-1];
typedef char chase_client_state_t_worldmodel_must_match[(offsetof(client_state_t,worldmodel)==2692U)?1:-1];
typedef char chase_model_t_hulls_must_match[(offsetof(model_t,hulls)==208U)?1:-1];
typedef char chase_refdef_t_vieworg_must_match[(offsetof(refdef_t,vieworg)==112U)?1:-1];
typedef char chase_refdef_t_viewangles_must_match[(offsetof(refdef_t,viewangles)==124U)?1:-1];
typedef char chase_cvar_t_value_must_match[(offsetof(cvar_t,value)==16U)?1:-1];
#endif
#endif
