/* Audited view/camera storage and constant contracts. */
#ifndef ASM_VIEWCONTROL_H
#define ASM_VIEWCONTROL_H

/* Assembly-visible offsets used by the view-control module.  Keep these
   numeric contracts paired with the offsetof/sizeof checks below. */
#define VC_REFDEF_VIEWORG 112
#define VC_REFDEF_VIEWANGLES 124
#define VC_REFDEF_AMBIENTLIGHT 144
#define VC_REFDEF_SIZE 148
#define VC_VRECT_X 0
#define VC_VRECT_Y 4
#define VC_VRECT_WIDTH 8
#define VC_VRECT_HEIGHT 12
#define VC_VRECT_SIZE 20
#define VC_VID_WIDTH 20
#define VC_VID_HEIGHT 24
#define VC_VID_ASPECT 28
#define VC_VID_MAXWARPWIDTH 56
#define VC_VID_MAXWARPHEIGHT 60
#define VC_VID_SIZE 68
#define VC_CVAR_VALUE 16
#define VC_CVAR_SIZE 24
#define VC_CLIENT_MAXCLIENTS 2684
#define VC_CLIENT_WORLDMODEL 2692
#define VC_SERVER_ACTIVE 0
#define VC_MLEAF_CONTENTS 0
#define VC_SURFACE_SIZE 64
#define VC_EDGE_SIZE 32

#ifndef __ASSEMBLER__
#include <stddef.h>
typedef char vc_pointer_size_must_match[(sizeof(void *)==4U)?1:-1];
typedef char vc_float_size_must_match[(sizeof(float)==4U)?1:-1];
typedef char vc_double_size_must_match[(sizeof(double)==8U)?1:-1];
typedef char vc_integer_size_must_match[(sizeof(int)==4U)?1:-1];
typedef char vc_client_state_t_size_must_match[(sizeof(client_state_t)==2900U)?1:-1];
typedef char vc_client_state_t_cmd_must_match[(offsetof(client_state_t,cmd)==4U)?1:-1];
typedef char vc_client_state_t_driftmove_must_match[(offsetof(client_state_t,driftmove)==516U)?1:-1];
typedef char vc_client_state_t_idealpitch_must_match[(offsetof(client_state_t,idealpitch)==504U)?1:-1];
typedef char vc_client_state_t_intermission_must_match[(offsetof(client_state_t,intermission)==548U)?1:-1];
typedef char vc_client_state_t_inwater_must_match[(offsetof(client_state_t,inwater)==544U)?1:-1];
typedef char vc_client_state_t_laststop_must_match[(offsetof(client_state_t,laststop)==520U)?1:-1];
typedef char vc_client_state_t_maxclients_must_match[(offsetof(client_state_t,maxclients)==2684U)?1:-1];
typedef char vc_client_state_t_model_precache_must_match[(offsetof(client_state_t,model_precache)==592U)?1:-1];
typedef char vc_client_state_t_nodrift_must_match[(offsetof(client_state_t,nodrift)==512U)?1:-1];
typedef char vc_client_state_t_oldtime_must_match[(offsetof(client_state_t,oldtime)==580U)?1:-1];
typedef char vc_client_state_t_onground_must_match[(offsetof(client_state_t,onground)==540U)?1:-1];
typedef char vc_client_state_t_paused_must_match[(offsetof(client_state_t,paused)==536U)?1:-1];
typedef char vc_client_state_t_pitchvel_must_match[(offsetof(client_state_t,pitchvel)==508U)?1:-1];
typedef char vc_client_state_t_punchangle_must_match[(offsetof(client_state_t,punchangle)==492U)?1:-1];
typedef char vc_client_state_t_stats_must_match[(offsetof(client_state_t,stats)==28U)?1:-1];
typedef char vc_client_state_t_time_must_match[(offsetof(client_state_t,time)==572U)?1:-1];
typedef char vc_client_state_t_velocity_must_match[(offsetof(client_state_t,velocity)==480U)?1:-1];
typedef char vc_client_state_t_viewangles_must_match[(offsetof(client_state_t,viewangles)==444U)?1:-1];
typedef char vc_client_state_t_viewent_must_match[(offsetof(client_state_t,viewent)==2708U)?1:-1];
typedef char vc_client_state_t_viewentity_must_match[(offsetof(client_state_t,viewentity)==2680U)?1:-1];
typedef char vc_client_state_t_viewheight_must_match[(offsetof(client_state_t,viewheight)==528U)?1:-1];
typedef char vc_client_static_t_size_must_match[(sizeof(client_static_t)==2308U)?1:-1];
typedef char vc_client_static_t_demoplayback_must_match[(offsetof(client_static_t,demoplayback)==2252U)?1:-1];
typedef char vc_entity_t_size_must_match[(sizeof(entity_t)==180U)?1:-1];
typedef char vc_entity_t_origin_must_match[(offsetof(entity_t,origin)==84U)?1:-1];
typedef char vc_entity_t_angles_must_match[(offsetof(entity_t,angles)==120U)?1:-1];
typedef char vc_entity_t_model_must_match[(offsetof(entity_t,model)==132U)?1:-1];
typedef char vc_entity_t_frame_must_match[(offsetof(entity_t,frame)==140U)?1:-1];
typedef char vc_entity_t_colormap_must_match[(offsetof(entity_t,colormap)==148U)?1:-1];
typedef char vc_refdef_t_size_must_match[(sizeof(refdef_t)==148U)?1:-1];
typedef char vc_refdef_t_vieworg_must_match[(offsetof(refdef_t,vieworg)==112U)?1:-1];
typedef char vc_refdef_t_viewangles_must_match[(offsetof(refdef_t,viewangles)==124U)?1:-1];
typedef char vc_refdef_t_vrect_must_match[(offsetof(refdef_t,vrect)==0U)?1:-1];
typedef char vc_vrect_t_size_must_match[(sizeof(vrect_t)==20U)?1:-1];
typedef char vc_vrect_t_x_must_match[(offsetof(vrect_t,x)==0U)?1:-1];
typedef char vc_vrect_t_y_must_match[(offsetof(vrect_t,y)==4U)?1:-1];
typedef char vc_vrect_t_width_must_match[(offsetof(vrect_t,width)==8U)?1:-1];
typedef char vc_vrect_t_height_must_match[(offsetof(vrect_t,height)==12U)?1:-1];
typedef char vc_viddef_t_size_must_match[(sizeof(viddef_t)==68U)?1:-1];
typedef char vc_viddef_t_buffer_must_match[(offsetof(viddef_t,buffer)==0U)?1:-1];
typedef char vc_viddef_t_rowbytes_must_match[(offsetof(viddef_t,rowbytes)==16U)?1:-1];
typedef char vc_viddef_t_aspect_must_match[(offsetof(viddef_t,aspect)==28U)?1:-1];
typedef char vc_viddef_t_colormap_must_match[(offsetof(viddef_t,colormap)==4U)?1:-1];
typedef char vc_view_refdef_vieworg_must_match[(offsetof(refdef_t,vieworg)==VC_REFDEF_VIEWORG)?1:-1];
typedef char vc_view_refdef_viewangles_must_match[(offsetof(refdef_t,viewangles)==VC_REFDEF_VIEWANGLES)?1:-1];
typedef char vc_view_refdef_ambientlight_must_match[(offsetof(refdef_t,ambientlight)==VC_REFDEF_AMBIENTLIGHT)?1:-1];
typedef char vc_view_vid_width_must_match[(offsetof(viddef_t,width)==VC_VID_WIDTH)?1:-1];
typedef char vc_view_vid_height_must_match[(offsetof(viddef_t,height)==VC_VID_HEIGHT)?1:-1];
typedef char vc_view_vid_maxwarpwidth_must_match[(offsetof(viddef_t,maxwarpwidth)==VC_VID_MAXWARPWIDTH)?1:-1];
typedef char vc_view_vid_maxwarpheight_must_match[(offsetof(viddef_t,maxwarpheight)==VC_VID_MAXWARPHEIGHT)?1:-1];
typedef char vc_view_client_worldmodel_must_match[(offsetof(client_state_t,worldmodel)==VC_CLIENT_WORLDMODEL)?1:-1];
typedef char vc_view_server_active_must_match[(offsetof(server_t,active)==VC_SERVER_ACTIVE)?1:-1];
typedef char vc_view_leaf_contents_must_match[(offsetof(mleaf_t,contents)==VC_MLEAF_CONTENTS)?1:-1];
typedef char vc_view_surface_size_must_match[(sizeof(surf_t)==VC_SURFACE_SIZE)?1:-1];
typedef char vc_view_edge_size_must_match[(sizeof(edge_t)==VC_EDGE_SIZE)?1:-1];
typedef char vc_cvar_t_size_must_match[(sizeof(cvar_t)==24U)?1:-1];
typedef char vc_cvar_t_value_must_match[(offsetof(cvar_t,value)==16U)?1:-1];
typedef char vc_usercmd_t_size_must_match[(sizeof(usercmd_t)==24U)?1:-1];
typedef char vc_usercmd_t_forwardmove_must_match[(offsetof(usercmd_t,forwardmove)==12U)?1:-1];
typedef char vc_PITCH_must_match[(PITCH==0U)?1:-1];
typedef char vc_YAW_must_match[(YAW==1U)?1:-1];
typedef char vc_ROLL_must_match[(ROLL==2U)?1:-1];
typedef char vc_STAT_HEALTH_must_match[(STAT_HEALTH==0U)?1:-1];
typedef char vc_STAT_WEAPON_must_match[(STAT_WEAPON==2U)?1:-1];
typedef char vc_STAT_WEAPONFRAME_must_match[(STAT_WEAPONFRAME==5U)?1:-1];
typedef char vc_MAX_EDICTS_must_match[(MAX_EDICTS==600U)?1:-1];
typedef char vc_MAX_MODELS_must_match[(MAX_MODELS==256U)?1:-1];
extern float viewcontrol_oldyaw,viewcontrol_oldpitch,viewcontrol_oldz;
extern vec3_t forward,right,up;
extern cvar_t scr_ofsx,scr_ofsy,scr_ofsz;
float angledelta(float);
void CalcGunAngle(void),V_BoundOffsets(void),V_AddIdle(void),V_CalcViewRoll(void);
void V_StartPitchDrift(void),V_StopPitchDrift(void),V_DriftPitch(void);
float V_CalcBob(void);
void V_CalcIntermissionRefdef(void),V_CalcRefdef(void);
#ifdef BENCH486
void R_SetupFrame_View_C(void);
void Bench486ViewCvarSet(const char *,const char *);
void Bench486ViewPushLights(void),Bench486ViewRender(void),Bench486ViewChase(void);
void Bench486ViewCharacter(int,int,int);
void Bench486ViewProfileEnter(unsigned),Bench486ViewProfileLeave(void);
#endif
#endif
#endif
