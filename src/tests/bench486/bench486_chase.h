/* Independent original camera C, real hull traversal, full state and cdecl ABI. */
/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
#ifdef ASM486_CHASE
typedef struct {unsigned first[8];model_t model;unsigned last[8];} bench486_chase_model_t;
typedef struct {unsigned first[8];dclipnode_t nodes[32];mplane_t planes[32];unsigned last[8];} bench486_chase_hull_t;
typedef struct {unsigned first[8];vec3_t start,end,impact;unsigned last[8];} bench486_chase_vectors_t;
static bench486_chase_model_t bench486_chase_model;
static bench486_chase_hull_t bench486_chase_hull;
static bench486_chase_vectors_t bench486_chase_vectors;
static unsigned bench486_chase_hull_use_asm;
static cvar_t *bench486_chase_controls[]={&chase_back,&chase_up,&chase_right,&chase_active};
typedef struct {
    client_state_t client;refdef_t reference;cvar_t controls[4];
    vec3_t position,angles,destination,destination_angles;
    bench486_chase_vectors_t vectors;
} bench486_chase_state_t;
static void Bench486ChaseSave(bench486_chase_state_t *s)
{
    unsigned i;Q_memset(s,0,sizeof(*s));
    Q_memcpy(&s->client,&cl,sizeof(cl));Q_memcpy(&s->reference,&r_refdef,sizeof(r_refdef));
    for(i=0;i<4;i++)Q_memcpy(&s->controls[i],bench486_chase_controls[i],sizeof(cvar_t));
    Q_memcpy(s->position,chase_pos,12);Q_memcpy(s->angles,chase_angles,12);
    Q_memcpy(s->destination,chase_dest,12);Q_memcpy(s->destination_angles,chase_dest_angles,12);
    Q_memcpy(&s->vectors,&bench486_chase_vectors,sizeof(bench486_chase_vectors));
}
static void Bench486ChaseRestore(const bench486_chase_state_t *s)
{
    unsigned i;Q_memcpy(&cl,(void *)&s->client,sizeof(cl));Q_memcpy(&r_refdef,(void *)&s->reference,sizeof(r_refdef));
    for(i=0;i<4;i++)Q_memcpy(bench486_chase_controls[i],(void *)&s->controls[i],sizeof(cvar_t));
    Q_memcpy(chase_pos,(void *)s->position,12);Q_memcpy(chase_angles,(void *)s->angles,12);
    Q_memcpy(chase_dest,(void *)s->destination,12);Q_memcpy(chase_dest_angles,(void *)s->destination_angles,12);
    Q_memcpy(&bench486_chase_vectors,(void *)&s->vectors,sizeof(bench486_chase_vectors));
}
typedef struct {
    unsigned phase,pointer,node,first,last,result;
    vec3_t start,end;trace_t before,after;
} bench486_chase_event_t;
static struct {unsigned count,errors;bench486_chase_event_t events[8];} bench486_chase_trace;
static void Bench486ChaseRegisterFixture(cvar_t *value)
{
    bench486_chase_event_t *event;unsigned i;
    if(bench486_chase_trace.count>=8){bench486_chase_trace.errors++;return;}
    event=&bench486_chase_trace.events[bench486_chase_trace.count++];event->phase=1;event->pointer=(unsigned)value;
    for(i=0;i<4;i++)if(value==bench486_chase_controls[i])break;
    if(i==4){bench486_chase_trace.errors++;return;}
    value->value=(int)i*16-8;
}
static qboolean Bench486ChaseHullFixture(hull_t *hull,int node,int first_bits,int last_bits,vec3_t start,vec3_t end,trace_t *trace)
{
    bench486_chase_event_t *event;static const byte zero[sizeof(trace_t)]={0};qboolean result;float first,last;
    if(bench486_chase_trace.count>=8){bench486_chase_trace.errors++;return false;}
    event=&bench486_chase_trace.events[bench486_chase_trace.count++];event->phase=2;
    event->pointer=(unsigned)hull;event->node=node;event->first=first_bits;event->last=last_bits;
    Q_memcpy(event->start,start,12);Q_memcpy(event->end,end,12);Q_memcpy(&event->before,trace,sizeof(*trace));
    if(hull!=bench486_chase_model.model.hulls || node!=0 || first_bits!=0 || last_bits!=1 || Q_memcmp(trace,(void *)zero,sizeof(*trace)))
        bench486_chase_trace.errors++;
    /* Exercise the real independent collision helper, including no-hit zero
       endpos, open/water leaves, near-plane epsilon and depth-32 clipping. */
    Q_memcpy(&first,&first_bits,4);Q_memcpy(&last,&last_bits,4);
    result=bench486_chase_hull_use_asm?
        SV_RecursiveHullCheck_asm486(hull,node,first,last,start,end,trace):
        Bench486ChaseOriginalHull(hull,node,first,last,start,end,trace);
    event->result=result;Q_memcpy(&event->after,trace,sizeof(*trace));return result;
}
static int Bench486ChaseGuards(void)
{
    unsigned i;for(i=0;i<8;i++){
        if(bench486_chase_model.first[i]!=0x5a5a5a5aU || bench486_chase_model.last[i]!=0xa5a5a5a5U ||
           bench486_chase_hull.first[i]!=0x5a5a5a5aU || bench486_chase_hull.last[i]!=0xa5a5a5a5U ||
           bench486_chase_vectors.first[i]!=0x5a5a5a5aU || bench486_chase_vectors.last[i]!=0xa5a5a5a5U)return 0;
    }return 1;
}
static unsigned Bench486ChaseReadOnlyHash(void)
{
    unsigned i,hash=2166136261U;
    for(i=0;i<sizeof(bench486_chase_model.model);i++)hash=(hash^((byte *)&bench486_chase_model.model)[i])*16777619U;
    for(i=0;i<sizeof(bench486_chase_hull.nodes)+sizeof(bench486_chase_hull.planes);i++)
        hash=(hash^((byte *)bench486_chase_hull.nodes)[i])*16777619U;
    return hash;
}
static void Bench486ChaseInputs(unsigned pattern,unsigned sequence)
{
    static const float coordinates[]={0,-0.0f,0.03125f,-0.03125f,1,-1,64,-64,8192,-8192,1048576,-1048576,1.0e20f,-1.0e20f};
    static const float distances[]={0,-0.0f,0.03125f,-0.03125f,100,-100,1024,-1024,1.0e15f,-1.0e15f};
    unsigned i,j,depth=1+(pattern%32),axis;hull_t *hull;
    if(!sequence){Q_memset(&cl,0,sizeof(cl));Q_memset(&r_refdef,0,sizeof(r_refdef));
        for(i=0;i<3;i++){chase_pos[i]=coordinates[(pattern+i+4)%14];chase_angles[i]=(int)(pattern%81)-40;
            chase_dest[i]=coordinates[(pattern+i+7)%14];chase_dest_angles[i]=-chase_angles[i];}}
    for(i=0;i<3;i++){
        cl.viewangles[i]=((int)((pattern>>(i*5))%2881)-1440)*0.25f;
        r_refdef.viewangles[i]=((int)(pattern%181)-90)*0.5f;
        if(!sequence)r_refdef.vieworg[i]=coordinates[(pattern+i)%14];
        bench486_chase_vectors.start[i]=coordinates[(pattern+i+2)%14];
        bench486_chase_vectors.end[i]=coordinates[(pattern+i+8)%14];
        bench486_chase_vectors.impact[i]=coordinates[(pattern+i+11)%14];
    }
    chase_back.value=sequence?((int)(pattern%33)-16):distances[(pattern>>1)%10];
    chase_right.value=sequence?((int)(pattern%9)-4):distances[(pattern>>3)%10];
    chase_up.value=sequence?((int)(pattern%17)-8)*0.125f:distances[(pattern>>6)%10];
    chase_active.value=(pattern>>7)&1;cl.time=pattern*0.0783;
    Q_memset(&bench486_chase_model.model,0,sizeof(model_t));
    Q_memset(bench486_chase_hull.nodes,0,sizeof(bench486_chase_hull.nodes));
    Q_memset(bench486_chase_hull.planes,0,sizeof(bench486_chase_hull.planes));
    cl.worldmodel=&bench486_chase_model.model;hull=cl.worldmodel->hulls;
    hull->clipnodes=bench486_chase_hull.nodes;hull->planes=bench486_chase_hull.planes;
    hull->firstclipnode=0;hull->lastclipnode=depth-1;
    for(i=0;i<depth;i++){
        mplane_t *plane=&bench486_chase_hull.planes[i];dclipnode_t *node=&bench486_chase_hull.nodes[i];
        axis=(pattern+i)%4;plane->type=axis;
        for(j=0;j<3;j++)plane->normal[j]=axis<3?(axis==j?1:0):(j==0?0.6f:j==1?-0.8f:0);
        plane->dist=((int)(pattern%257)-128)*0.03125f+i*0.25f;
        node->planenum=i;node->children[0]=i+1<depth?i+1:CONTENTS_EMPTY;
        node->children[1]=(pattern&(1U<<(i%16)))?CONTENTS_SOLID:((pattern&128)?CONTENTS_WATER:CONTENTS_EMPTY);
    }
}
typedef struct {const char *name;void (*reference)(void),(*assembly)(void);unsigned arguments;} bench486_chase_pair_t;
static const bench486_chase_pair_t bench486_chase_pairs[]={
    {"Chase_Init",Chase_Init_Chase_C,Chase_Init,0},{"Chase_Reset",Chase_Reset_Chase_C,Chase_Reset,0},
    {"TraceLine",(void (*)(void))TraceLine_Chase_C,(void (*)(void))TraceLine,3},
    {"Chase_Update",Chase_Update_Chase_C,Chase_Update,0}};
static void Bench486ChaseStep(unsigned pair,unsigned pattern,unsigned sequence)
{
    static bench486_chase_state_t initial,reference,assembly;static byte trace[sizeof(bench486_chase_trace)];
    unsigned arguments[3],c_abi,a_abi,hash,i;int failed;
    Bench486ChaseInputs(pattern,sequence);Bench486ChaseSave(&initial);hash=Bench486ChaseReadOnlyHash();
    arguments[0]=(unsigned)bench486_chase_vectors.start;arguments[1]=(unsigned)bench486_chase_vectors.end;
    arguments[2]=(pattern&3)==1?arguments[0]:(pattern&3)==2?arguments[1]:(unsigned)bench486_chase_vectors.impact;
    Q_memset(&bench486_chase_trace,0,sizeof(bench486_chase_trace));
    bench486_chase_hull_use_asm=0;
    c_abi=Bench486Call_asm486(bench486_chase_pairs[pair].reference,bench486_chase_pairs[pair].arguments,arguments,NULL);
    Bench486ChaseSave(&reference);Q_memcpy(trace,&bench486_chase_trace,sizeof(trace));
    failed=!Bench486ChaseGuards() || hash!=Bench486ChaseReadOnlyHash() || bench486_chase_trace.errors;
    Bench486ChaseRestore(&initial);Q_memset(&bench486_chase_trace,0,sizeof(bench486_chase_trace));
    bench486_chase_hull_use_asm=1;
    a_abi=Bench486Call_asm486(bench486_chase_pairs[pair].assembly,bench486_chase_pairs[pair].arguments,arguments,NULL);
    bench486_chase_hull_use_asm=0;
    Bench486ChaseSave(&assembly);
    failed|=c_abi || a_abi || !Bench486ChaseGuards() || hash!=Bench486ChaseReadOnlyHash() || bench486_chase_trace.errors ||
        Q_memcmp(trace,&bench486_chase_trace,sizeof(trace)) || Q_memcmp(&reference,&assembly,sizeof(reference));
    if(failed){bench486_memory_failures++;
        if(bench486_memory_failures<24){for(i=0;i<sizeof(reference);i++)if(((byte *)&reference)[i]!=((byte *)&assembly)[i])break;
            Bench486Printf("chase %s FAIL pattern %u ABI %x/%x state-byte %u trace %u\n",
                bench486_chase_pairs[pair].name,pattern,c_abi,a_abi,i,bench486_chase_trace.count);}}
}
static void Bench486ChaseCases(void)
{
    static bench486_chase_state_t saved;unsigned short cw,control;
    static const unsigned modes[]={0x007f,0x047f,0x087f,0x0c7f,0x027f,0x067f,0x0a7f,0x0e7f,0x037f,0x077f,0x0b7f,0x0f7f};
    void (*register_probe)(cvar_t *);qboolean (*hull_probe)(hull_t *,int,int,int,vec3_t,vec3_t,trace_t *);
    unsigned i,mode,step,pair,cases=0,negative=0,failures=bench486_memory_failures;
    Bench486ChaseSave(&saved);register_probe=bench486_chase_register_probe;hull_probe=bench486_chase_hull_probe;
    bench486_chase_register_probe=Bench486ChaseRegisterFixture;bench486_chase_hull_probe=Bench486ChaseHullFixture;
    for(i=0;i<8;i++){
        bench486_chase_model.first[i]=bench486_chase_hull.first[i]=bench486_chase_vectors.first[i]=0x5a5a5a5aU;
        bench486_chase_model.last[i]=bench486_chase_hull.last[i]=bench486_chase_vectors.last[i]=0xa5a5a5a5U;
    }
    __asm__ __volatile__("fnstcw %0":"=m"(cw));
    for(mode=0;mode<12;mode++){Bench486Printf("chase precision/rounding mode %u begin\n",mode);
        control=(cw&~0x0f00U)|(modes[mode]&0x0f00U);__asm__ __volatile__("fldcw %0"::"m"(control));
        for(step=0;step<128;step++)for(pair=0;pair<4;pair++){Bench486ChaseStep(pair,step*0x1020305U+pair*0x486U,0);cases++;}}
    Bench486Printf("chase continuous sequence begin\n");Bench486ChaseInputs(0,0);
    for(step=0;step<8192;step++){Bench486ChaseStep(step%4,step*0x9e3779b9U,1);cases++;}
    __asm__ __volatile__("fldcw %0"::"m"(cw));
    for(i=0;i<8;i++){
#define CHASE_GUARD(n) n.first[i]^=1;if(!Bench486ChaseGuards())negative++;n.first[i]^=1; \
        n.last[i]^=1;if(!Bench486ChaseGuards())negative++;n.last[i]^=1
        CHASE_GUARD(bench486_chase_model);CHASE_GUARD(bench486_chase_hull);CHASE_GUARD(bench486_chase_vectors);
#undef CHASE_GUARD
    }
    if(negative!=48)bench486_memory_failures++;
    bench486_chase_register_probe=register_probe;bench486_chase_hull_probe=hull_probe;Bench486ChaseRestore(&saved);
    Bench486Printf("chase camera exact C/ASM hull/destination/trace/clamp/ABI %s (4 entries; %u cases; 12 control words; 8192 sequence calls; %u guard checks; %u failures)\n",
        failures==bench486_memory_failures?"PASS":"FAIL",cases,negative,bench486_memory_failures-failures);
}
#else
static void Bench486ChaseCases(void)
{bench486_memory_failures++;Bench486Printf("chase camera fixture requires ChaseImplementation=asm\n");}
#endif
