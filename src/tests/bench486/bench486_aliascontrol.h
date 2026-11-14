/* Independent original C control, live vertex state, triangle routing and ABI. */
#include "renderer/asm_aliascontrol.h"
#ifdef ASM486_ALIAS_CONTROL
extern int a_skinwidth,r_anumverts,r_amodels_drawn,r_ambientlight;
extern mdl_t *pmdl;
extern aliashdr_t *paliashdr;
extern trivertx_t *r_apverts;
extern finalvert_t *pfinalverts;
extern auxvert_t *pauxverts;
extern float aliastransform[3][4],ziscale,r_shadelight;
extern vec3_t r_plightvec;
extern void *acolormap;
extern float r_aliastransition,r_resfudge;
typedef struct {unsigned before[8];model_t value;unsigned after[8];} ac_model_t;
typedef struct {unsigned before[8];entity_t value;unsigned after[8];} ac_entity_t;
typedef struct {unsigned before[8];union {double align;byte bytes[65536];} data;unsigned after[8];} ac_blob_t;
typedef struct {unsigned before[8];finalvert_t values[MAXALIASVERTS];unsigned after[8];} ac_final_t;
typedef struct {unsigned before[8];auxvert_t values[MAXALIASVERTS];unsigned after[8];} ac_aux_t;
typedef struct {
    unsigned phase,count,words[3];affinetridesc_t affine;char text[256];
} ac_event_t;
typedef struct {
    unsigned count,errors,live,vertices;ac_event_t events[64];
    finalvert_t final[MAXALIASVERTS];auxvert_t aux[MAXALIASVERTS];
} ac_trace_t;
typedef struct {
    client_state_t client;refdef_t reference;entity_t entity;entity_t *current,*cached;
    model_t *model;mdl_t *mdl;aliashdr_t *header;trivertx_t *vertices;
    finalvert_t *final;auxvert_t *aux;maliasskindesc_t *skin;
    int mode,numvertices,skinwidth,models,ambient,recursive;
    float transform[3][4],view[3][4],matrix[3][4],depth,shade,transition,fudge,projection[4];
    vec3_t forward,right,up,light,origin;affinetridesc_t affine;void *colormap;
    unsigned result,ticks;
#ifdef PROFILE486
    qboolean profile_active;unsigned long profile_models,profile_vertices;double seconds;
#endif
} ac_state_t;
typedef struct {
    ac_model_t model;ac_entity_t entity;ac_blob_t blob;ac_final_t final;ac_aux_t aux;
    byte colormap[65536];vec3_t lightvector;alight_t light;
    ac_trace_t trace;
    ac_state_t saved,initial,reference,assembly;
    byte before_final[sizeof(finalvert_t)*MAXALIASVERTS+32];
    byte before_aux[sizeof(auxvert_t)*MAXALIASVERTS+32];
    byte c_final[sizeof(finalvert_t)*MAXALIASVERTS+32];
    byte c_aux[sizeof(auxvert_t)*MAXALIASVERTS+32];
    byte saved_trace[sizeof(ac_trace_t)];
} ac_workspace_t;
/* The large synthetic fixture is only live while -benchaliascontrol runs.
   Keeping it in .bss reduced the real demo heap by about 600 KiB whenever the
   assembly selector was enabled, making the visual integration run fail
   during map sign-on before it reached the renderer. */
static ac_workspace_t *ac_workspace;
#define ac_model (ac_workspace->model)
#define ac_entity (ac_workspace->entity)
#define ac_blob (ac_workspace->blob)
#define ac_final (ac_workspace->final)
#define ac_aux (ac_workspace->aux)
#define ac_colormap (ac_workspace->colormap)
#define ac_lightvector (ac_workspace->lightvector)
#define ac_light (ac_workspace->light)
#define ac_trace (ac_workspace->trace)
static unsigned ac_count,ac_drawing,ac_unclipped,ac_time_ticks,ac_live_bytes,ac_live_aux_bytes;
static void AC_Save(ac_state_t *s,unsigned normalize)
{
    Q_memset(s,0,sizeof(*s));Q_memcpy(&s->client,&cl,sizeof(cl));Q_memcpy(&s->reference,&r_refdef,sizeof(r_refdef));
    s->entity=ac_entity.value;s->current=currententity;s->cached=aliascontrol_alias_transform_entity;
    s->model=aliascontrol_pmodel;s->mdl=pmdl;s->header=paliashdr;s->vertices=r_apverts;
    s->final=normalize?NULL:pfinalverts;s->aux=normalize?NULL:pauxverts;s->skin=aliascontrol_pskindesc;
    s->mode=aliascontrol_alias_transform_mode;s->numvertices=r_anumverts;s->skinwidth=a_skinwidth;
    s->models=r_amodels_drawn;s->ambient=r_ambientlight;s->recursive=r_recursiveaffinetriangles;
    Q_memcpy(s->transform,aliastransform,48);Q_memcpy(s->view,aliascontrol_alias_viewmatrix,48);
    Q_memcpy(s->matrix,aliascontrol_tmatrix,48);s->depth=ziscale;s->shade=r_shadelight;
    s->transition=r_aliastransition;s->fudge=r_resfudge;
    s->projection[0]=aliasxscale;s->projection[1]=aliasyscale;s->projection[2]=aliasxcenter;s->projection[3]=aliasycenter;
    Q_memcpy(s->forward,aliascontrol_alias_forward,12);Q_memcpy(s->right,aliascontrol_alias_right,12);
    Q_memcpy(s->up,aliascontrol_alias_up,12);Q_memcpy(s->light,r_plightvec,12);Q_memcpy(s->origin,modelorg,12);
    s->affine=r_affinetridesc;if(normalize)s->affine.pfinalverts=NULL;s->colormap=acolormap;
    s->result=bench486_aliascontrol_bbox_result;s->ticks=ac_time_ticks;
#ifdef PROFILE486
    s->profile_active=bench486_profile_frame_active;s->profile_models=bench486_alias_models;
    s->profile_vertices=bench486_alias_vertices;s->seconds=bench486_alias_seconds;
#endif
}
static void AC_Restore(const ac_state_t *s)
{
    Q_memcpy(&cl,(void *)&s->client,sizeof(cl));Q_memcpy(&r_refdef,(void *)&s->reference,sizeof(r_refdef));
    ac_entity.value=s->entity;currententity=s->current;aliascontrol_alias_transform_entity=s->cached;
    aliascontrol_pmodel=s->model;pmdl=s->mdl;paliashdr=s->header;r_apverts=s->vertices;
    pfinalverts=s->final;pauxverts=s->aux;aliascontrol_pskindesc=s->skin;
    aliascontrol_alias_transform_mode=s->mode;r_anumverts=s->numvertices;a_skinwidth=s->skinwidth;
    r_amodels_drawn=s->models;r_ambientlight=s->ambient;r_recursiveaffinetriangles=s->recursive;
    Q_memcpy(aliastransform,(void *)s->transform,48);Q_memcpy(aliascontrol_alias_viewmatrix,(void *)s->view,48);
    Q_memcpy(aliascontrol_tmatrix,(void *)s->matrix,48);ziscale=s->depth;r_shadelight=s->shade;
    r_aliastransition=s->transition;r_resfudge=s->fudge;
    aliasxscale=s->projection[0];aliasyscale=s->projection[1];aliasxcenter=s->projection[2];aliasycenter=s->projection[3];
    Q_memcpy(aliascontrol_alias_forward,(void *)s->forward,12);Q_memcpy(aliascontrol_alias_right,(void *)s->right,12);
    Q_memcpy(aliascontrol_alias_up,(void *)s->up,12);Q_memcpy(r_plightvec,(void *)s->light,12);Q_memcpy(modelorg,(void *)s->origin,12);
    r_affinetridesc=s->affine;acolormap=s->colormap;bench486_aliascontrol_bbox_result=s->result;ac_time_ticks=s->ticks;
#ifdef PROFILE486
    bench486_profile_frame_active=s->profile_active;bench486_alias_models=s->profile_models;
    bench486_alias_vertices=s->profile_vertices;bench486_alias_seconds=s->seconds;
#endif
}
static ac_event_t *AC_Event(unsigned phase,unsigned count,const unsigned *words)
{
    ac_event_t *event;unsigned i;
    if(ac_trace.count==64 || count>3){ac_trace.errors++;return NULL;}
    event=&ac_trace.events[ac_trace.count++];event->phase=phase;event->count=count;
    for(i=0;i<count;i++)event->words[i]=words[i];return event;
}
static void AC_Live(void)
{
    unsigned i,j;finalvert_t *fv;
    if(ac_trace.live)return;ac_trace.live=1;ac_trace.vertices=ac_count;
    if(ac_drawing && ((unsigned)pfinalverts&(CACHE_SIZE-1)))ac_trace.errors++;
    for(i=0;i<ac_count;i++){
        fv=&pfinalverts[i];
        /* Reserved padding and screen coordinates of Z-clipped vertices are
           uninitialized by the original DrawModel stack scratch. Only read
           fields the original algorithm defines at this stage. */
        ac_trace.final[i].flags=fv->flags;
        for(j=2;j<=4;j++)ac_trace.final[i].v[j]=fv->v[j];
        if(ac_unclipped || !(fv->flags&ALIAS_Z_CLIP)){
            ac_trace.final[i].v[0]=fv->v[0];ac_trace.final[i].v[1]=fv->v[1];ac_trace.final[i].v[5]=fv->v[5];}
        if(!ac_unclipped)ac_trace.aux[i]=pauxverts[i];
    }
}
static void AC_Observe(unsigned phase,unsigned count,const unsigned *words)
{
    ac_event_t *event=AC_Event(phase,count,words);if(!event)return;
    if(phase==1){Q_strncpy(event->text,(char *)words[0],sizeof(event->text)-1);event->words[0]=0;}
    if(phase==2 || phase==4 || phase==5){
        AC_Live();event->affine=r_affinetridesc;
        if(ac_drawing)event->affine.pfinalverts=NULL;
        if(phase==5){if((finalvert_t *)words[0]!=pfinalverts || words[1]!=ac_count)ac_trace.errors++;
            event->words[0]=0;}
        if(phase==4){mtriangle_t *tri=(mtriangle_t *)words[0];
            if(tri<(mtriangle_t *)(ac_blob.data.bytes+paliashdr->triangles) ||
               tri>=(mtriangle_t *)(ac_blob.data.bytes+paliashdr->triangles)+pmdl->numtris)ac_trace.errors++;}
    }
    if(phase==6 && words[0]!=(unsigned)currententity->colormap)ac_trace.errors++;
}
static aliashdr_t *AC_Model(model_t *model)
{unsigned argument=(unsigned)model;AC_Event(10,1,&argument);
 if(model!=&ac_model.value)ac_trace.errors++;return (aliashdr_t *)ac_blob.data.bytes;}
static double AC_Time(void){ac_time_ticks++;return ac_time_ticks*0.125;}
static unsigned AC_ReadOnly(void)
{
    unsigned i,hash=2166136261U,word;
    for(i=0;i<sizeof(ac_model.value);i++)hash=(hash^((byte *)&ac_model.value)[i])*16777619U;
    /* Mix every resource/frame byte, four at a time. The fixture checks this
       unchanged input after both backends; a bytewise FNV pass dominated the
       8,192-call sequence on the emulated 486. */
    for(i=0;i<49152;i+=4){
        word=(unsigned)ac_blob.data.bytes[i]|
            ((unsigned)ac_blob.data.bytes[i+1]<<8)|
            ((unsigned)ac_blob.data.bytes[i+2]<<16)|
            ((unsigned)ac_blob.data.bytes[i+3]<<24);
        hash=((hash<<5)|(hash>>27))^word;
    }
    return hash;
}
static int AC_Guards(void)
{
    unsigned i;byte *ftail=(byte *)ac_final.values+ac_live_bytes,*atail=(byte *)ac_aux.values+ac_live_aux_bytes;
    for(i=0;i<8;i++){
        if(ac_model.before[i]!=0x5a5a5a5aU || ac_model.after[i]!=0xa5a5a5a5U ||
           ac_entity.before[i]!=0x5a5a5a5aU || ac_entity.after[i]!=0xa5a5a5a5U ||
           ac_blob.before[i]!=0x5a5a5a5aU || ac_blob.after[i]!=0xa5a5a5a5U ||
           ac_final.before[i]!=0x5a5a5a5aU || ac_aux.before[i]!=0x5a5a5a5aU)return 0;
    }
    for(i=0;i<32;i++)if(ftail[i]!=(byte)(0xa5^(i*13)) || atail[i]!=(byte)(0xa5^(i*13)))return 0;
    return 1;
}
static void AC_Inputs(unsigned pattern,unsigned sequence,unsigned pair)
{
    static const unsigned counts[]={3,4,8,16,32,64,127,256,1024,2000};
    static const float depths[]={-32,-0.0f,0,4.999f,5,5.001f,16,128,8192,65536};
    static const float scales[]={0.03125f,0.5f,1,2,16};
    unsigned i,j,offset;mdl_t *mdl;aliashdr_t *header;maliasgroup_t *group;maliasskingroup_t *skins;
    stvert_t *st;mtriangle_t *tri;trivertx_t *vertices;float *intervals;
    if(!sequence){r_amodels_drawn=(pattern>>3)&65535;r_ambientlight=5;r_shadelight=0;
        Q_memset(aliascontrol_tmatrix,0,48);Q_memset(aliascontrol_alias_viewmatrix,0,48);}
    Q_memset(ac_blob.data.bytes,0,49152);Q_memset(&ac_model.value,0,sizeof(model_t));
    Q_strcpy(ac_model.value.name,"alias-control-fixture.mdl");ac_model.value.type=mod_alias;
    ac_count=sequence?counts[pattern%8]:counts[pattern%10];ac_live_bytes=ac_count*sizeof(finalvert_t);ac_live_aux_bytes=ac_count*sizeof(auxvert_t);
    header=(aliashdr_t *)ac_blob.data.bytes;header->model=128;header->stverts=256;header->triangles=24256;
    header->skindesc=24800;mdl=(mdl_t *)(ac_blob.data.bytes+128);
    mdl->numverts=ac_count;mdl->numtris=1+(pattern%32);mdl->numframes=3;mdl->numskins=3;
    mdl->skinwidth=16<<(pattern%3);mdl->skinheight=8<<(pattern%2);mdl->size=1+(pattern%64);
    for(i=0;i<3;i++){
        mdl->scale[i]=scales[(pattern+i)%5];mdl->scale_origin[i]=((int)((pattern>>(i*3))%129)-64)*0.125f;
        header->frames[i].type=i==1?ALIAS_GROUP:ALIAS_SINGLE;header->frames[i].frame=i==1?24900:25000+i*8000;
        for(j=0;j<3;j++){header->frames[i].bboxmin.v[j]=0;header->frames[i].bboxmax.v[j]=255;}
    }
    group=(maliasgroup_t *)(ac_blob.data.bytes+24900);group->numframes=3;group->intervals=24948;
    for(i=0;i<3;i++)group->frames[i].frame=25000+i*4000;
    intervals=(float *)(ac_blob.data.bytes+24948);intervals[0]=0.125f;intervals[1]=0.25f;intervals[2]=0.5f;
    for(i=0;i<3;i++){
        maliasskindesc_t *skin=(maliasskindesc_t *)(ac_blob.data.bytes+24800)+i;
        skin->type=i==1?ALIAS_SKIN_GROUP:ALIAS_SKIN_SINGLE;skin->skin=i==1?24840:39900;
    }
    skins=(maliasskingroup_t *)(ac_blob.data.bytes+24840);skins->numskins=3;skins->intervals=24888;
    for(i=0;i<3;i++){skins->skindescs[i].type=ALIAS_SKIN_SINGLE;skins->skindescs[i].skin=39900+i*16;}
    intervals=(float *)(ac_blob.data.bytes+24888);intervals[0]=0.125f;intervals[1]=0.375f;intervals[2]=0.5f;
    st=(stvert_t *)(ac_blob.data.bytes+256);tri=(mtriangle_t *)(ac_blob.data.bytes+24256);
    for(i=0;i<ac_count;i++){st[i].onseam=(i&1)?ALIAS_ONSEAM:0;st[i].s=(i%mdl->skinwidth)<<16;st[i].t=(i%mdl->skinheight)<<16;}
    for(i=0;i<(unsigned)mdl->numtris;i++){tri[i].facesfront=i&1;for(j=0;j<3;j++)tri[i].vertindex[j]=(i*3+j)%ac_count;}
    /* Five independent frame arrays fit below the guarded model tail. */
    for(offset=25000;offset<=41000;offset+=4000){vertices=(trivertx_t *)(ac_blob.data.bytes+offset);
        for(i=0;i<ac_count && offset+i*4+4<=sizeof(ac_blob.data.bytes);i++){
            for(j=0;j<3;j++)vertices[i].v[j]=(byte)(i*7+j*53+pattern);vertices[i].lightnormalindex=(i+pattern)%162;}}
    Q_memset(&ac_entity.value,0,sizeof(entity_t));ac_entity.value.model=&ac_model.value;
    ac_entity.value.frame=(int)(pattern%5)-1;ac_entity.value.skinnum=(int)((pattern>>3)%5)-1;
    ac_entity.value.syncbase=((int)(pattern%33)-16)*0.03125f;ac_entity.value.colormap=ac_colormap;
    ac_entity.value.trivial_accept=(pattern>>4)&3;currententity=(pattern&64)?&cl.viewent:&ac_entity.value;
    if(currententity==&cl.viewent)cl.viewent=ac_entity.value;
    cl.time=(sequence?pattern&65535:pattern&0xfffff)*0.0783;
    pmdl=mdl;paliashdr=header;r_apverts=(trivertx_t *)(ac_blob.data.bytes+25000);
    pfinalverts=ac_final.values;pauxverts=ac_aux.values;aliascontrol_pmodel=&ac_model.value;
    r_affinetridesc.pfinalverts=pfinalverts;r_affinetridesc.ptriangles=tri;r_affinetridesc.numtriangles=mdl->numtris;
    r_affinetridesc.drawtype=pattern&1;r_recursiveaffinetriangles=(pattern>>1)&1;
    aliascontrol_alias_transform_entity=(pattern&2)?currententity:NULL;
    aliascontrol_alias_transform_mode=(pattern&4)?currententity->trivial_accept:5;
    ac_drawing=pair==8;ac_unclipped=pair==4 || (ac_drawing&&currententity->trivial_accept);
    r_anumverts=ac_count;r_aliastransition=32+(pattern&255);r_resfudge=0.25f;
    aliasxscale=32+(pattern&127);aliasyscale=48+(pattern&63);aliasxcenter=160;aliasycenter=100;
    r_refdef.fvrectx=0;r_refdef.fvrecty=0;r_refdef.fvrectright=319;r_refdef.fvrectbottom=199;
    r_refdef.aliasvrect.x=0;r_refdef.aliasvrect.y=0;r_refdef.aliasvrectright=319;r_refdef.aliasvrectbottom=199;
    for(i=0;i<3;i++){
        currententity->angles[i]=((int)((pattern>>(i*5))%2881)-1440)*0.25f;
        modelorg[i]=((int)((pattern>>(i*3))%257)-128)*0.125f;
        ac_lightvector[i]=((int)((pattern>>(i*4))%65)-32)*0.03125f;
        for(j=0;j<4;j++){aliascontrol_alias_viewmatrix[i][j]=j==i?1:0;aliastransform[i][j]=j==i?0.125f:0;}
        aliascontrol_alias_forward[i]=i==0;aliascontrol_alias_right[i]=i==1?-1:0;aliascontrol_alias_up[i]=i==2;
    }
    /* Unclipped primitive input must be in front of the near plane. Pure bbox,
       projection and clipped control fixtures also cover exact near boundaries. */
    aliastransform[2][3]=ac_unclipped?16:depths[(pattern>>7)%10];
    if(ac_unclipped)for(i=0;i<3;i++)for(j=0;j<4;j++)aliastransform[i][j]*=1.0f/2147483648.0f;
    ziscale=(pattern&1)?2147483648.0f:6442450944.0f;
    ac_light.ambientlight=(pattern%300);ac_light.shadelight=(int)((pattern>>6)%129)-32;ac_light.plightvec=ac_lightvector;
    Q_memset(ac_final.values,0x55,ac_live_bytes);Q_memset(ac_aux.values,0x66,ac_live_aux_bytes);
    ac_aux.values[0].fv[0]=((int)(pattern%1025)-512)*0.125f;ac_aux.values[0].fv[1]=-ac_aux.values[0].fv[0];
    ac_aux.values[0].fv[2]=depths[(pattern>>4)%10];
    for(i=0;i<32;i++){((byte *)ac_final.values)[ac_live_bytes+i]=(byte)(0xa5^(i*13));
        ((byte *)ac_aux.values)[ac_live_aux_bytes+i]=(byte)(0xa5^(i*13));}
    bench486_aliascontrol_bbox_result=0x486ac000;ac_time_ticks=0;
#ifdef PROFILE486
    bench486_profile_frame_active=(pattern>>7)&1;bench486_alias_models=pattern&255;
    bench486_alias_vertices=pattern&65535;bench486_alias_seconds=0.5;
#endif
}
typedef struct {const char *name;void (*c)(void),(*a)(void);unsigned words,adapter;} ac_pair_t;
static const ac_pair_t ac_pairs[]={
    {"R_AliasCheckBBox",(void(*)(void))R_AliasCheckBBox_AliasControl_C,(void(*)(void))R_AliasCheckBBox,0,2},
    {"R_AliasPreparePoints",R_AliasPreparePoints_AliasControl_C,R_AliasPreparePoints,0,0},
    {"R_AliasSetUpTransform",(void(*)(void))R_AliasSetUpTransform_AliasControl_C,(void(*)(void))R_AliasSetUpTransform,1,0},
    {"R_AliasProjectFinalVert",(void(*)(void))R_AliasProjectFinalVert_AliasControl_C,(void(*)(void))R_AliasProjectFinalVert,2,0},
    {"R_AliasPrepareUnclippedPoints",R_AliasPrepareUnclippedPoints_AliasControl_C,R_AliasPrepareUnclippedPoints,0,0},
    {"R_AliasSetupSkin",R_AliasSetupSkin_AliasControl_C,R_AliasSetupSkin,0,0},
    {"R_AliasSetupLighting",(void(*)(void))R_AliasSetupLighting_AliasControl_C,(void(*)(void))R_AliasSetupLighting,1,0},
    {"R_AliasSetupFrame",R_AliasSetupFrame_AliasControl_C,R_AliasSetupFrame,0,0},
    {"R_AliasDrawModel",(void(*)(void))R_AliasDrawModel_AliasControl_C,(void(*)(void))R_AliasDrawModel,1,1}};
static void AC_Step(unsigned pair,unsigned pattern,unsigned sequence)
{
    ac_state_t *initial=&ac_workspace->initial,*reference=&ac_workspace->reference,*assembly=&ac_workspace->assembly;
    byte *before_final=ac_workspace->before_final,*before_aux=ac_workspace->before_aux;
    byte *c_final=ac_workspace->c_final,*c_aux=ac_workspace->c_aux,*saved_trace=ac_workspace->saved_trace;
    unsigned args[2],adapter[2],c_abi,a_abi,hash,fb,ab,i;int failed;
    AC_Inputs(pattern,sequence,pair);AC_Save(initial,0);hash=AC_ReadOnly();
    fb=ac_live_bytes+32;ab=ac_live_aux_bytes+32;
    Q_memcpy(before_final,ac_final.values,fb);Q_memcpy(before_aux,ac_aux.values,ab);
    args[0]=pair==2?currententity->trivial_accept:pair==3?(unsigned)pfinalverts:(unsigned)&ac_light;
    args[1]=(unsigned)pauxverts;adapter[1]=(unsigned)&ac_light;
    adapter[0]=(unsigned)ac_pairs[pair].c;Q_memset(&ac_trace,0,sizeof(ac_trace));
    c_abi=Bench486Call_asm486(ac_pairs[pair].adapter==1?Bench486AliasControlRegCall:ac_pairs[pair].adapter==2?Bench486AliasControlBBoxCall:ac_pairs[pair].c,
        ac_pairs[pair].adapter?ac_pairs[pair].adapter==1?2:1:ac_pairs[pair].words,ac_pairs[pair].adapter?adapter:args,NULL);
    AC_Save(reference,ac_drawing);Q_memcpy(c_final,ac_final.values,fb);Q_memcpy(c_aux,ac_aux.values,ab);
    Q_memcpy(saved_trace,&ac_trace,sizeof(ac_trace));failed=!AC_Guards() || hash!=AC_ReadOnly() || ac_trace.errors;
    AC_Restore(initial);Q_memcpy(ac_final.values,before_final,fb);Q_memcpy(ac_aux.values,before_aux,ab);
    adapter[0]=(unsigned)ac_pairs[pair].a;Q_memset(&ac_trace,0,sizeof(ac_trace));
    a_abi=Bench486Call_asm486(ac_pairs[pair].adapter==1?Bench486AliasControlRegCall:ac_pairs[pair].adapter==2?Bench486AliasControlBBoxCall:ac_pairs[pair].a,
        ac_pairs[pair].adapter?ac_pairs[pair].adapter==1?2:1:ac_pairs[pair].words,ac_pairs[pair].adapter?adapter:args,NULL);
    AC_Save(assembly,ac_drawing);
    failed|=c_abi || a_abi || !AC_Guards() || hash!=AC_ReadOnly() || ac_trace.errors ||
        Q_memcmp(reference,assembly,sizeof(*reference)) || Q_memcmp(saved_trace,&ac_trace,sizeof(ac_trace)) ||
        Q_memcmp(c_final,ac_final.values,fb) || Q_memcmp(c_aux,ac_aux.values,ab);
    if(failed){bench486_memory_failures++;
        if(bench486_memory_failures<32){for(i=0;i<sizeof(*reference);i++)if(((byte *)reference)[i]!=((byte *)assembly)[i])break;
            Bench486Printf("alias-control %s FAIL pattern %u ABI %x/%x state-byte %u trace %u/%u\n",
                ac_pairs[pair].name,pattern,c_abi,a_abi,i,((unsigned *)saved_trace)[0],ac_trace.count);}}
    /* Sequence state remains from the candidate; only the dead stack pointers
       are replaced by valid caller-owned scratch before the next invocation. */
}
static void Bench486AliasControlCases(void)
{
    ac_state_t *saved;unsigned short cw,control;int hunk_mark;
    static const unsigned modes[]={0x007f,0x047f,0x087f,0x0c7f,0x027f,0x067f,0x0a7f,0x0e7f,0x037f,0x077f,0x0b7f,0x0f7f};
    aliashdr_t *(*model_probe)(model_t *);void (*probe)(unsigned,unsigned,const unsigned *);double (*time_probe)(void);
    unsigned i,mode,step,pair,cases=0,negative=0,failures=bench486_memory_failures;
    hunk_mark=Hunk_LowMark();
    ac_workspace=(ac_workspace_t *)Hunk_AllocName(sizeof(*ac_workspace),"aliasctl");
    saved=&ac_workspace->saved;
    AC_Save(saved,0);model_probe=bench486_aliascontrol_model_probe;probe=bench486_aliascontrol_probe;time_probe=bench486_aliascontrol_time_probe;
    bench486_aliascontrol_model_probe=AC_Model;bench486_aliascontrol_probe=AC_Observe;bench486_aliascontrol_time_probe=AC_Time;
    for(i=0;i<8;i++){
        ac_model.before[i]=ac_entity.before[i]=ac_blob.before[i]=ac_final.before[i]=ac_aux.before[i]=0x5a5a5a5aU;
        ac_model.after[i]=ac_entity.after[i]=ac_blob.after[i]=ac_final.after[i]=ac_aux.after[i]=0xa5a5a5a5U;
    }
    __asm__ __volatile__("fnstcw %0":"=m"(cw));
    for(mode=0;mode<12;mode++){
        Bench486Printf("alias-control precision/rounding mode %u begin\n",mode);
        control=(cw&~0x0f00U)|(modes[mode]&0x0f00U);__asm__ __volatile__("fldcw %0"::"m"(control));
        for(step=0;step<32;step++)for(pair=0;pair<9;pair++){AC_Step(pair,step*0x1020305U+pair*0x486U,0);cases++;}
    }
    Bench486Printf("alias-control continuous sequence begin\n");AC_Inputs(0,0,0);
    for(step=0;step<8192;step++){AC_Step(step%9,step*0x9e3779b9U,1);cases++;}
    __asm__ __volatile__("fldcw %0"::"m"(cw));
    for(i=0;i<8;i++){
#define AC_NEGATIVE(n) n.before[i]^=1;if(!AC_Guards())negative++;n.before[i]^=1
        AC_NEGATIVE(ac_model);AC_NEGATIVE(ac_entity);AC_NEGATIVE(ac_blob);AC_NEGATIVE(ac_final);AC_NEGATIVE(ac_aux);
#undef AC_NEGATIVE
        ac_model.after[i]^=1;if(!AC_Guards())negative++;ac_model.after[i]^=1;
        ac_entity.after[i]^=1;if(!AC_Guards())negative++;ac_entity.after[i]^=1;
        ac_blob.after[i]^=1;if(!AC_Guards())negative++;ac_blob.after[i]^=1;
    }
    for(i=0;i<32;i++){
        ((byte *)ac_final.values)[ac_live_bytes+i]^=1;if(!AC_Guards())negative++;((byte *)ac_final.values)[ac_live_bytes+i]^=1;
        ((byte *)ac_aux.values)[ac_live_aux_bytes+i]^=1;if(!AC_Guards())negative++;((byte *)ac_aux.values)[ac_live_aux_bytes+i]^=1;
    }
    if(negative!=128)bench486_memory_failures++;
    bench486_aliascontrol_model_probe=model_probe;bench486_aliascontrol_probe=probe;bench486_aliascontrol_time_probe=time_probe;AC_Restore(saved);
    Bench486Printf("alias pipeline exact bbox/transform/skin/frame/light/triangle/live-state/ABI %s (9 entries; %u cases; 12 control words; 8192 sequence calls; %u guard checks; %u failures)\n",
        failures==bench486_memory_failures?"PASS":"FAIL",cases,negative,bench486_memory_failures-failures);
    Hunk_FreeToLowMark(hunk_mark);ac_workspace=NULL;
}
#else
static void Bench486AliasControlCases(void)
{bench486_memory_failures++;Bench486Printf("alias pipeline fixture requires AliasControlImplementation=asm\n");}
#endif
