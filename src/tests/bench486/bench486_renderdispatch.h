/* Compare the pinned C adapters with the assembly entries at the outgoing ABI.
   Typed C backend observers never call an assembly implementation. Backend
   algorithms retain their independent exact-output fixtures and scene tests. */
#include "tests/bench486/bench486_sprite_hooks.h"

#ifdef ASM486_RENDER_DISPATCH
extern void (*bench486_dispatch_probe)(unsigned,unsigned,const unsigned *);
extern double (*bench486_dispatch_timer)(void);
extern int sprite_height,minindex,maxindex;
extern sspan_t *sprite_spans;
extern float r_dispatch_alias_viewmatrix[3][4];
extern cvar_t sv_gravity;
extern void D_SpriteScanLeftEdge_Dispatch_C(void);
extern void D_SpriteScanRightEdge_Dispatch_C(void);
extern void D_SpriteCalculateGradients_Dispatch_C(void);
extern void D_DrawSprite_Dispatch_C(void);
extern void R_AliasSetViewMatrix_Dispatch_C(void);
extern void R_MarkLights_Dispatch_C(dlight_t *,int,mnode_t *);
extern void R_MarkLights_asm486(dlight_t *,int,mnode_t *);
extern void R_PushDlights_Dispatch_C(void);
extern void R_RenderFace_Dispatch_C(msurface_t *,int);
extern void R_RenderFaceGradient_asm486_Dispatch_C(mplane_t *);
extern void R_RenderBmodelFaceGradient_asm486_Dispatch_C(mplane_t *);
extern void R_RenderFaceGradient_asm486(mplane_t *);
extern void R_RenderBmodelFaceGradient_asm486(mplane_t *);
extern void R_DrawParticles_Dispatch_C(void);

typedef struct { unsigned phase,count,words[9]; } bench486_dispatch_event_t;
typedef struct {
    unsigned before[8],count,errors,timer_calls;
    bench486_dispatch_event_t event[8];
    byte projected[sizeof(spritedesc_t)];
    unsigned after[8];
} bench486_dispatch_trace_t;
static bench486_dispatch_trace_t bench486_dispatch_trace;
static unsigned bench486_dispatch_pattern;

static void Bench486DispatchObserve(unsigned phase,unsigned count,const unsigned *words)
{
    bench486_dispatch_event_t *event;
    unsigned i;
    if(bench486_dispatch_trace.count>=8 || count>9)
    { bench486_dispatch_trace.errors++; return; }
    event=&bench486_dispatch_trace.event[bench486_dispatch_trace.count++];
    event->phase=phase; event->count=count;
    for(i=0;i<count;i++) event->words[i]=words[i];
#ifdef PROFILE486
    if(phase==12 && count==6)
    {
        unsigned long *particles=(unsigned long *)words[4];
        unsigned long *gibs=(unsigned long *)words[5];
        if(!particles || !gibs || particles==gibs || ((words[4]|words[5])&3))
        { bench486_dispatch_trace.errors++; return; }
        if(*particles || *gibs) bench486_dispatch_trace.errors++;
        *particles=bench486_dispatch_pattern ^ 0xfedcba98U;
        *gibs=(bench486_dispatch_pattern*17U) ^ 0x12345678U;
        /* Local stack addresses differ; compare their initialization, distinct
           ownership and exact resulting counter state instead of their values. */
        event->words[4]=0x48600004U; event->words[5]=0x48600008U;
    }
#endif
}
static unsigned Bench486DispatchFloatBits(float value)
{ unsigned result; Q_memcpy(&result,&value,4); return result; }
void Bench486DispatchSpriteLeft(sspan_t *spans,int min,int max,int nump,emitpoint_t *vertices)
{ unsigned w[5]; w[0]=(unsigned)spans;w[1]=min;w[2]=max;w[3]=nump;w[4]=(unsigned)vertices;Bench486DispatchObserve(1,5,w); }
void Bench486DispatchSpriteRight(sspan_t *spans,int min,int max,int nump,emitpoint_t *vertices,
                               float left,float right,float top,float bottom)
{ unsigned w[9];w[0]=(unsigned)spans;w[1]=min;w[2]=max;w[3]=nump;w[4]=(unsigned)vertices;
  w[5]=Bench486DispatchFloatBits(left);w[6]=Bench486DispatchFloatBits(right);
  w[7]=Bench486DispatchFloatBits(top);w[8]=Bench486DispatchFloatBits(bottom);Bench486DispatchObserve(2,9,w); }
void Bench486DispatchSpriteGradients(int height)
{ unsigned w=height;Bench486DispatchObserve(3,1,&w); }
void Bench486DispatchSpriteDraw(int nump,emitpoint_t *vertices,int width,int height,byte *pixels)
{ unsigned w[5];w[0]=nump;w[1]=(unsigned)vertices;w[2]=width;w[3]=height;w[4]=(unsigned)pixels;Bench486DispatchObserve(4,5,w); }
void Bench486DispatchAliasView(const float *right,const float *up,const float *normal,float *output)
{ unsigned w[4];w[0]=(unsigned)right;w[1]=(unsigned)up;w[2]=(unsigned)normal;w[3]=(unsigned)output;Bench486DispatchObserve(5,4,w); }
void Bench486DispatchMarkTree(dlight_t *light,int bit,mnode_t *node,msurface_t *surfaces)
{ unsigned w[4];w[0]=(unsigned)light;w[1]=bit;w[2]=(unsigned)node;w[3]=(unsigned)surfaces;Bench486DispatchObserve(6,4,w); }
void Bench486DispatchPushLights(double time,int frame,dlight_t *lights,mnode_t *world)
{ unsigned w[5];Q_memcpy(w,&time,8);w[2]=frame;w[3]=(unsigned)lights;w[4]=(unsigned)world;Bench486DispatchObserve(8,5,w); }
void Bench486DispatchRenderFace(msurface_t *face,int flags,medge_t *edges,int *surfedges)
{ unsigned w[4];w[0]=(unsigned)face;w[1]=flags;w[2]=(unsigned)edges;w[3]=(unsigned)surfedges;Bench486DispatchObserve(9,4,w); }
void Bench486DispatchFaceGradient(mplane_t *plane)
{ unsigned w=(unsigned)plane;Bench486DispatchObserve(10,1,&w); }
void Bench486DispatchBmodelGradient(mplane_t *plane)
{ unsigned w=(unsigned)plane;Bench486DispatchObserve(11,1,&w); }
void Bench486DispatchParticles(float time,double oldtime,float gravity
#ifdef PROFILE486
                              ,unsigned long *particles,unsigned long *gibs
#endif
                              )
{ unsigned w[6];w[0]=Bench486DispatchFloatBits(time);Q_memcpy(w+1,&oldtime,8);
  w[3]=Bench486DispatchFloatBits(gravity);
#ifdef PROFILE486
  w[4]=(unsigned)particles;w[5]=(unsigned)gibs;Bench486DispatchObserve(12,6,w);
#else
  Bench486DispatchObserve(12,4,w);
#endif
}
void Bench486DispatchStartParticles(void) { Bench486DispatchObserve(13,0,NULL); }
void Bench486DispatchEndParticles(void) { Bench486DispatchObserve(14,0,NULL); }
double Bench486DispatchFloatTime(void)
{
    static const double times[2]={12345.125,12345.1875};
    unsigned call=bench486_dispatch_trace.timer_calls++;
    Bench486DispatchObserve(15,0,NULL);
    if(call>1) bench486_dispatch_trace.errors++;
    return times[call&1];
}
static void Bench486DispatchProject(const spritedesc_t *desc)
{
    unsigned w=(unsigned)desc;
    Bench486DispatchObserve(16,1,&w);
    Q_memcpy(bench486_dispatch_trace.projected,(void *)desc,sizeof(*desc));
}
static void Bench486DispatchResetTrace(void)
{
    unsigned i;
    Q_memset(&bench486_dispatch_trace,0,sizeof(bench486_dispatch_trace));
    for(i=0;i<8;i++)
    { bench486_dispatch_trace.before[i]=0x5a5a5a5aU;bench486_dispatch_trace.after[i]=0xa5a5a5a5U; }
}
static int Bench486DispatchTraceValid(bench486_dispatch_trace_t *trace)
{
    unsigned i;
    if(trace->errors || trace->count>8) return 0;
    for(i=0;i<8;i++)
        if(trace->before[i]!=0x5a5a5a5aU || trace->after[i]!=0xa5a5a5a5U) return 0;
    for(i=0;i<trace->count;i++) if(trace->event[i].count>9) return 0;
    return 1;
}
typedef struct {
    void (*reference)(void),(*assembly)(void);
    unsigned words,phase;
    const char *name;
} bench486_dispatch_pair_t;
static bench486_dispatch_pair_t bench486_dispatch_pairs[]={
    {NULL,NULL,0,0,"sentinel"},
#ifdef ASM486_SPRITE_SCAN_LEFT
    {D_SpriteScanLeftEdge_Dispatch_C,D_SpriteScanLeftEdge,0,1,"sprite-left"},
#endif
#ifdef ASM486_SPRITE_SCAN_RIGHT
    {D_SpriteScanRightEdge_Dispatch_C,D_SpriteScanRightEdge,0,2,"sprite-right"},
#endif
#ifdef ASM486_SPRITE_GRADIENTS
    {D_SpriteCalculateGradients_Dispatch_C,D_SpriteCalculateGradients,0,3,"sprite-gradients"},
#endif
#ifdef ASM486_SPRITE_DRAW
    {D_DrawSprite_Dispatch_C,D_DrawSprite,0,4,"sprite-draw"},
#endif
#ifdef ASM486_ALIAS_MATRIX_COMPOSE_ASM
    {R_AliasSetViewMatrix_Dispatch_C,R_AliasSetViewMatrix,0,5,"alias-view"},
#endif
#ifdef ASM486_MARK_LIGHTS
    {(void(*)(void))R_MarkLights_asm486_Dispatch_C,(void(*)(void))R_MarkLights_asm486,3,6,"mark-helper"},
    {(void(*)(void))R_MarkLights_Dispatch_C,(void(*)(void))R_MarkLights,3,6,"mark-public"},
#endif
#ifdef ASM486_DYNAMIC_LIGHT_PUSH
    {R_PushDlights_Dispatch_C,R_PushDlights,0,8,"push-lights"},
#endif
#ifdef ASM486_RENDER_FACE
    {(void(*)(void))R_RenderFace_Dispatch_C,(void(*)(void))R_RenderFace,2,9,"render-face"},
    {(void(*)(void))R_RenderFaceGradient_asm486_Dispatch_C,(void(*)(void))R_RenderFaceGradient_asm486,1,10,"face-gradient"},
#endif
#ifdef ASM486_RENDER_BMODEL_FACE
    {(void(*)(void))R_RenderBmodelFaceGradient_asm486_Dispatch_C,(void(*)(void))R_RenderBmodelFaceGradient_asm486,1,11,"bmodel-gradient"},
#endif
#ifdef ASM486_PARTICLE_UPDATE
    {R_DrawParticles_Dispatch_C,R_DrawParticles,0,12,"particles"},
#endif
};
typedef struct {
    double time,oldtime;
    model_t *worldmodel;
    entity_t *entity;
    int frame,height,min,max;
    sspan_t *spans;
    spritedesc_t desc;
    refdef_t ref;
    float gravity,right[3],up[3],normal[3],matrix[12];
} bench486_dispatch_globals_t;
static void Bench486DispatchSave(bench486_dispatch_globals_t *s)
{
    Q_memset(s,0,sizeof(*s));
    Q_memcpy(&s->time,&cl.time,8);Q_memcpy(&s->oldtime,&cl.oldtime,8);
    s->worldmodel=cl.worldmodel;s->entity=currententity;s->frame=r_framecount;
    s->height=sprite_height;s->min=minindex;s->max=maxindex;s->spans=sprite_spans;
    Q_memcpy(&s->desc,&r_spritedesc,sizeof(s->desc));Q_memcpy(&s->ref,&r_refdef,sizeof(s->ref));
    Q_memcpy(&s->gravity,&sv_gravity.value,4);Q_memcpy(s->right,vright,12);
    Q_memcpy(s->up,vup,12);Q_memcpy(s->normal,vpn,12);Q_memcpy(s->matrix,r_dispatch_alias_viewmatrix,48);
}
static void Bench486DispatchRestore(bench486_dispatch_globals_t *s)
{
    Q_memcpy(&cl.time,&s->time,8);Q_memcpy(&cl.oldtime,&s->oldtime,8);
    cl.worldmodel=s->worldmodel;currententity=s->entity;r_framecount=s->frame;
    sprite_height=s->height;minindex=s->min;maxindex=s->max;sprite_spans=s->spans;
    Q_memcpy(&r_spritedesc,&s->desc,sizeof(s->desc));Q_memcpy(&r_refdef,&s->ref,sizeof(s->ref));
    Q_memcpy(&sv_gravity.value,&s->gravity,4);Q_memcpy(vright,s->right,12);
    Q_memcpy(vup,s->up,12);Q_memcpy(vpn,s->normal,12);Q_memcpy(r_dispatch_alias_viewmatrix,s->matrix,48);
}
static struct {
    unsigned before[8]; model_t model;entity_t entity;msurface_t surface;
    medge_t edges[17];int surfedges[33];mnode_t nodes[3];mplane_t planes[3];
    dlight_t lights[3];mspriteframe_t frame;byte pixels[37];emitpoint_t vertices[8];
    sspan_t spans[8];unsigned after[8];
} bench486_dispatch_inputs,bench486_dispatch_immutable;
static void Bench486DispatchInputs(unsigned pattern,unsigned phase)
{
    static const unsigned floats[]={0,0x80000000U,0x3f800000U,0xbf800000U,0x00000001U,
        0x00800000U,0x7f7fffffU,0xff7fffffU,0x3f7fffffU,0x4b800001U,0xcb800001U,0x3eaaaaabU};
    static const double times[]={0.0,-0.0,0.125,-0.125,1.000000059604644775390625,
        65536.0625,-65536.0625,16777217.0,-16777217.0,1.0e30,-1.0e30,1.0e-40};
    unsigned i,bits;
    byte *p=(byte *)&bench486_dispatch_inputs;
    for(i=0;i<sizeof(bench486_dispatch_inputs);i++) p[i]=(byte)((i*37U)^pattern^(pattern>>8));
    for(i=0;i<8;i++)
    {bench486_dispatch_inputs.before[i]=0x5a5a5a5aU;bench486_dispatch_inputs.after[i]=0xa5a5a5a5U;}
    bench486_dispatch_inputs.model.edges=bench486_dispatch_inputs.edges;
    bench486_dispatch_inputs.model.surfedges=bench486_dispatch_inputs.surfedges;
    bench486_dispatch_inputs.model.nodes=bench486_dispatch_inputs.nodes;
    bench486_dispatch_inputs.model.surfaces=&bench486_dispatch_inputs.surface;
    bench486_dispatch_inputs.entity.model=&bench486_dispatch_inputs.model;
    bench486_dispatch_inputs.surface.firstedge=pattern%33;
    cl.worldmodel=(phase==8 && (pattern&1)) ? NULL : &bench486_dispatch_inputs.model;
    currententity=&bench486_dispatch_inputs.entity;r_framecount=pattern ^ 0x7fffffffU;
    sprite_spans=bench486_dispatch_inputs.spans;minindex=pattern;maxindex=~pattern;
    sprite_height=pattern ^ 0x80000000U;
    Q_memset(&r_spritedesc,(int)(pattern&255),sizeof(r_spritedesc));
    r_spritedesc.nump=pattern ^ 0x80000001U;
    r_spritedesc.pverts=bench486_dispatch_inputs.vertices;
    r_spritedesc.pspriteframe=&bench486_dispatch_inputs.frame;
    bench486_dispatch_inputs.frame.width=pattern;bench486_dispatch_inputs.frame.height=~pattern;
    bits=floats[pattern%12];Q_memcpy(&r_refdef.fvrectx_adj,&bits,4);
    bits=floats[(pattern+3)%12];Q_memcpy(&r_refdef.fvrectright_adj,&bits,4);
    bits=floats[(pattern+6)%12];Q_memcpy(&r_refdef.fvrecty_adj,&bits,4);
    bits=floats[(pattern+9)%12];Q_memcpy(&r_refdef.fvrectbottom_adj,&bits,4);
    bits=floats[(pattern+7)%12];Q_memcpy(&sv_gravity.value,&bits,4);
    Q_memcpy(&cl.time,(void *)&times[pattern%12],8);Q_memcpy(&cl.oldtime,(void *)&times[(pattern+5)%12],8);
    for(i=0;i<3;i++)
    {bits=floats[(pattern+i)%12];Q_memcpy(vright+i,&bits,4);Q_memcpy(vup+i,&bits,4);Q_memcpy(vpn+i,&bits,4);}
    Q_memcpy(&bench486_dispatch_immutable,&bench486_dispatch_inputs,sizeof(bench486_dispatch_inputs));
}
static void Bench486DispatchStep(bench486_dispatch_pair_t *pair,unsigned pattern)
{
    static bench486_dispatch_trace_t reference;
    static bench486_dispatch_globals_t before,after;
    unsigned args[3],c_abi,a_abi,i;
    int failed;
#ifdef PROFILE486
    unsigned long c_particles,c_gibs,before_particles,before_gibs;
    double c_seconds,before_seconds;
    qboolean saved_active;
    saved_active=bench486_profile_frame_active;
    bench486_profile_frame_active=(pattern&1) ? 0 : (int)(pattern|1);
    before_particles=bench486_particle_count=pattern^0xffffffe0U;
    before_gibs=bench486_gib_trail_particles=pattern^0xfffffff0U;
    before_seconds=bench486_particle_seconds=-0.125;
#endif
    Bench486DispatchInputs(pattern,pair->phase);Bench486DispatchSave(&before);
    args[0]=(unsigned)(pair->phase==6 ? (void *)&bench486_dispatch_inputs.lights[pattern%3] :
                     pair->phase==9 ? (void *)&bench486_dispatch_inputs.surface :
                                     (void *)&bench486_dispatch_inputs.planes[pattern%3]);
    args[1]=pattern ^ 0x80000000U;args[2]=(unsigned)&bench486_dispatch_inputs.nodes[pattern%3];
    bench486_dispatch_pattern=pattern;
    Bench486DispatchResetTrace();
    c_abi=Bench486Call_asm486(pair->reference,pair->words,args,NULL);
    Q_memcpy(&reference,&bench486_dispatch_trace,sizeof(reference));
#ifdef PROFILE486
    c_particles=bench486_particle_count;c_gibs=bench486_gib_trail_particles;
    Q_memcpy(&c_seconds,&bench486_particle_seconds,8);
    bench486_particle_count=before_particles;bench486_gib_trail_particles=before_gibs;
    Q_memcpy(&bench486_particle_seconds,&before_seconds,8);
#endif
    Bench486DispatchResetTrace();
    a_abi=Bench486Call_asm486(pair->assembly,pair->words,args,NULL);
    Bench486DispatchSave(&after);
    failed=c_abi || a_abi || !Bench486DispatchTraceValid(&reference) ||
        !Bench486DispatchTraceValid(&bench486_dispatch_trace) ||
        Q_memcmp(&reference,&bench486_dispatch_trace,sizeof(reference)) ||
        Q_memcmp(&before,&after,sizeof(before)) ||
        Q_memcmp(&bench486_dispatch_inputs,&bench486_dispatch_immutable,sizeof(bench486_dispatch_inputs));
#ifdef PROFILE486
    if(c_particles!=bench486_particle_count || c_gibs!=bench486_gib_trail_particles ||
       Q_memcmp(&c_seconds,&bench486_particle_seconds,8)) failed=1;
    bench486_profile_frame_active=saved_active;
#endif
    if(failed)
    {
        bench486_memory_failures++;
        if(bench486_memory_failures<24)
        {
            Bench486Printf("dispatch %s FAIL pattern %u ABI %x/%x events %u/%u\n",
                pair->name,pattern,c_abi,a_abi,reference.count,bench486_dispatch_trace.count);
            for(i=0;i<sizeof(reference);i++)
                if(((byte *)&reference)[i]!=((byte *)&bench486_dispatch_trace)[i]) break;
            if(i<sizeof(reference)) Bench486Printf("dispatch trace byte %u C %02x assembly %02x\n",
                i,((byte *)&reference)[i],((byte *)&bench486_dispatch_trace)[i]);
        }
    }
}
static void Bench486RenderDispatchCases(void)
{
    static const unsigned modes[12]={0x007f,0x047f,0x087f,0x0c7f,
        0x027f,0x067f,0x0a7f,0x0e7f,0x037f,0x077f,0x0b7f,0x0f7f};
    static bench486_dispatch_globals_t saved;
    void (*saved_probe)(unsigned,unsigned,const unsigned *);
    void (*saved_project)(const spritedesc_t *);
    double (*saved_timer)(void);
    unsigned short saved_cw,control;
    unsigned mode,step,pair,pairs,initial_failures,cases,negative;
#ifdef PROFILE486
    unsigned long saved_particles,saved_gibs;
    double saved_seconds;
    qboolean saved_active;
    saved_particles=bench486_particle_count;saved_gibs=bench486_gib_trail_particles;
    Q_memcpy(&saved_seconds,&bench486_particle_seconds,8);saved_active=bench486_profile_frame_active;
#endif
    Bench486DispatchSave(&saved);
    saved_probe=bench486_dispatch_probe;saved_timer=bench486_dispatch_timer;
    saved_project=bench486_sprite_project_hook;
    bench486_dispatch_probe=Bench486DispatchObserve;bench486_dispatch_timer=Bench486DispatchFloatTime;
    bench486_sprite_project_hook=Bench486DispatchProject;
    __asm__ __volatile__("fnstcw %0" : "=m"(saved_cw));
    initial_failures=bench486_memory_failures;cases=0;negative=0;
    pairs=sizeof(bench486_dispatch_pairs)/sizeof(bench486_dispatch_pairs[0]);
    for(mode=0;mode<12;mode++)
    {
        control=(saved_cw&~0x0f00U)|(modes[mode]&0x0f00U);
        __asm__ __volatile__("fldcw %0" : : "m"(control));
        for(step=0;step<128;step++) for(pair=1;pair<pairs;pair++)
        { Bench486DispatchStep(&bench486_dispatch_pairs[pair],step*0x1020305U+pair*0x486U);cases++; }
    }
    /* Every entry is revisited without resetting renderer globals between calls. */
    for(step=0;step<8192 && pairs>1;step++)
    {pair=1+step%(pairs-1);Bench486DispatchStep(&bench486_dispatch_pairs[pair],step*0x9e3779b9U);cases++;}
    __asm__ __volatile__("fldcw %0" : : "m"(saved_cw));
    for(step=0;step<16;step++)
    {
        Bench486DispatchResetTrace();
        if(step<8) bench486_dispatch_trace.before[step]^=1;
        else bench486_dispatch_trace.after[step-8]^=1;
        if(!Bench486DispatchTraceValid(&bench486_dispatch_trace)) negative++;
    }
    Bench486DispatchResetTrace();bench486_dispatch_trace.errors=1;
    if(!Bench486DispatchTraceValid(&bench486_dispatch_trace)) negative++;
    Bench486DispatchResetTrace();bench486_dispatch_trace.count=9;
    if(!Bench486DispatchTraceValid(&bench486_dispatch_trace)) negative++;
    Bench486DispatchResetTrace();bench486_dispatch_trace.count=1;bench486_dispatch_trace.event[0].count=10;
    if(!Bench486DispatchTraceValid(&bench486_dispatch_trace)) negative++;
    if(negative!=19) bench486_memory_failures++;
    bench486_dispatch_probe=saved_probe;bench486_dispatch_timer=saved_timer;
    bench486_sprite_project_hook=saved_project;Bench486DispatchRestore(&saved);
#ifdef PROFILE486
    bench486_particle_count=saved_particles;bench486_gib_trail_particles=saved_gibs;
    Q_memcpy(&bench486_particle_seconds,&saved_seconds,8);bench486_profile_frame_active=saved_active;
#endif
    Bench486Printf("render dispatch exact arguments/phases/immutable inputs/ABI %s (%u entries; %u cases; 12 control words; 8192 sequence calls; %u detector checks; PROFILE %d; %u failures)\n",
        initial_failures==bench486_memory_failures ? "PASS":"FAIL",pairs-1,cases,negative,
#ifdef PROFILE486
        1,
#else
        0,
#endif
        bench486_memory_failures-initial_failures);
}
#else
static void Bench486RenderDispatchCases(void)
{bench486_memory_failures++;Bench486Printf("render dispatch fixture requires RenderDispatchImplementation=asm\n");}
#endif
