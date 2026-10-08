/* Independent original C camera algorithms; exact state, trace and ABI checks. */
#ifdef ASM486_VIEW_CONTROL
extern void (*bench486_view_probe)(unsigned,unsigned,const unsigned *);
extern cvar_t lcd_x,lcd_yaw,scr_ofsx,scr_ofsy,scr_ofsz,cl_rollspeed,cl_rollangle;
extern cvar_t cl_bob,cl_bobcycle,cl_bobup,v_kicktime,v_kickroll,v_kickpitch;
extern cvar_t v_iyaw_cycle,v_iroll_cycle,v_ipitch_cycle,v_iyaw_level,v_iroll_level,v_ipitch_level;
extern cvar_t v_idlescale,crosshair,cl_crossx,cl_crossy,v_centermove,v_centerspeed,scr_viewsize;
extern float v_dmg_time,v_dmg_roll,v_dmg_pitch;
extern qboolean noclip_anglehack,con_forcedup;
extern vrect_t scr_vrect;
extern float V_CalcRoll_View_C(vec3_t,vec3_t),V_CalcBob_View_C(void),angledelta_View_C(float);
extern void V_StartPitchDrift_View_C(void),V_StopPitchDrift_View_C(void),V_DriftPitch_View_C(void);
extern void CalcGunAngle_View_C(void),V_BoundOffsets_View_C(void),V_AddIdle_View_C(void);
extern void V_CalcViewRoll_View_C(void),V_CalcIntermissionRefdef_View_C(void),V_CalcRefdef_View_C(void),V_RenderView_View_C(void);
extern void Bench486ViewFloatCall(void);
float bench486_view_float_result;

static cvar_t *bench486_view_controls[]={&lcd_x,&lcd_yaw,&scr_ofsx,&scr_ofsy,&scr_ofsz,
    &cl_rollspeed,&cl_rollangle,&cl_bob,&cl_bobcycle,&cl_bobup,&v_kicktime,&v_kickroll,&v_kickpitch,
    &v_iyaw_cycle,&v_iroll_cycle,&v_ipitch_cycle,&v_iyaw_level,&v_iroll_level,&v_ipitch_level,
    &v_idlescale,&crosshair,&cl_crossx,&cl_crossy,&v_centermove,&v_centerspeed,&scr_viewsize,
    &chase_active,&cl_forwardspeed};
typedef struct {
    client_state_t client;viddef_t video;refdef_t reference;vrect_t rectangle;
    entity_t entities[4];vec3_t forward,right,up;
    float variables[28],oldyaw,oldpitch,oldz,damage_time,damage_roll,damage_pitch,result;
    int demo,noclip,console;
} bench486_view_state_t;
static void Bench486ViewSave(bench486_view_state_t *s)
{
    unsigned i;Q_memset(s,0,sizeof(*s));
    Q_memcpy(&s->client,&cl,sizeof(cl));Q_memcpy(&s->video,&vid,sizeof(vid));
    Q_memcpy(&s->reference,&r_refdef,sizeof(r_refdef));Q_memcpy(&s->rectangle,&scr_vrect,sizeof(scr_vrect));
    Q_memcpy(s->entities,cl_entities,sizeof(s->entities));
    Q_memcpy(s->forward,forward,12);Q_memcpy(s->right,right,12);Q_memcpy(s->up,up,12);
    for(i=0;i<28;i++)Q_memcpy(&s->variables[i],&bench486_view_controls[i]->value,4);
    Q_memcpy(&s->oldyaw,&viewcontrol_oldyaw,4);Q_memcpy(&s->oldpitch,&viewcontrol_oldpitch,4);Q_memcpy(&s->oldz,&viewcontrol_oldz,4);
    Q_memcpy(&s->damage_time,&v_dmg_time,4);Q_memcpy(&s->damage_roll,&v_dmg_roll,4);Q_memcpy(&s->damage_pitch,&v_dmg_pitch,4);
    Q_memcpy(&s->result,&bench486_view_float_result,4);
    s->demo=cls.demoplayback;s->noclip=noclip_anglehack;s->console=con_forcedup;
}
static void Bench486ViewRestore(const bench486_view_state_t *s)
{
    unsigned i;Q_memcpy(&cl,(void *)&s->client,sizeof(cl));Q_memcpy(&vid,(void *)&s->video,sizeof(vid));
    Q_memcpy(&r_refdef,(void *)&s->reference,sizeof(r_refdef));Q_memcpy(&scr_vrect,(void *)&s->rectangle,sizeof(scr_vrect));
    Q_memcpy(cl_entities,(void *)s->entities,sizeof(s->entities));
    Q_memcpy(forward,(void *)s->forward,12);Q_memcpy(right,(void *)s->right,12);Q_memcpy(up,(void *)s->up,12);
    for(i=0;i<28;i++)Q_memcpy(&bench486_view_controls[i]->value,(void *)&s->variables[i],4);
    Q_memcpy(&viewcontrol_oldyaw,(void *)&s->oldyaw,4);Q_memcpy(&viewcontrol_oldpitch,(void *)&s->oldpitch,4);Q_memcpy(&viewcontrol_oldz,(void *)&s->oldz,4);
    Q_memcpy(&v_dmg_time,(void *)&s->damage_time,4);Q_memcpy(&v_dmg_roll,(void *)&s->damage_roll,4);Q_memcpy(&v_dmg_pitch,(void *)&s->damage_pitch,4);
    Q_memcpy(&bench486_view_float_result,(void *)&s->result,4);
    cls.demoplayback=s->demo;noclip_anglehack=s->noclip;con_forcedup=s->console;
}
typedef struct {unsigned phase,count,words[3];refdef_t reference;unsigned buffer;int rowbytes;float aspect;} bench486_view_event_t;
static struct {unsigned count,errors;bench486_view_event_t events[20];} bench486_view_trace;
static unsigned Bench486ViewString(const char *s)
{unsigned hash=2166136261U;while(*s){hash=(hash^(byte)*s++)*16777619U;}return hash;}
static void Bench486ViewObserveFixture(unsigned phase,unsigned count,const unsigned *words)
{
    unsigned i;bench486_view_event_t *e;
    if(bench486_view_trace.count>=20 || count>3){bench486_view_trace.errors++;return;}
    e=&bench486_view_trace.events[bench486_view_trace.count++];e->phase=phase;e->count=count;
    for(i=0;i<count;i++)e->words[i]=phase==1?Bench486ViewString((char *)words[i]):words[i];
    Q_memcpy(&e->reference,&r_refdef,sizeof(r_refdef));e->buffer=(unsigned)vid.buffer;e->rowbytes=vid.rowbytes;
    Q_memcpy(&e->aspect,&vid.aspect,4);
    /* Deterministic effects make subsequent call ordering/restoration observable. */
    if(phase==3)r_refdef.vrect.height=(r_refdef.vrect.height+1)/2;
    if(phase==5)r_refdef.vieworg[0]+=0.25f;
}
static struct {unsigned first[8];byte data[640*480];unsigned last[8];} bench486_view_buffer;
static model_t bench486_view_models[2];
static int Bench486ViewGuards(void)
{unsigned i;for(i=0;i<8;i++)if(bench486_view_buffer.first[i]!=0x5a5a5a5aU || bench486_view_buffer.last[i]!=0xa5a5a5a5U)return 0;return 1;}
typedef struct {const char *name;void (*c)(void),(*a)(void);unsigned floating;} bench486_view_pair_t;
#define VC_PAIR(n,f) {#n,(void (*)(void))n##_View_C,(void (*)(void))n,f}
static const bench486_view_pair_t bench486_view_pairs[]={
    VC_PAIR(V_CalcRoll,1),VC_PAIR(V_CalcBob,1),VC_PAIR(V_StartPitchDrift,0),VC_PAIR(V_StopPitchDrift,0),
    VC_PAIR(V_DriftPitch,0),VC_PAIR(angledelta,1),VC_PAIR(CalcGunAngle,0),VC_PAIR(V_BoundOffsets,0),
    VC_PAIR(V_AddIdle,0),VC_PAIR(V_CalcViewRoll,0),VC_PAIR(V_CalcIntermissionRefdef,0),VC_PAIR(V_CalcRefdef,0),VC_PAIR(V_RenderView,0)};
#undef VC_PAIR
static void Bench486ViewInputs(unsigned pattern,unsigned sequence)
{
    static const float coordinates[]={0,-0.0f,0.03125f,-0.03125f,12,14,22,30,-8192,8192,1048576,-1048576,1.0e20f,-1.0e20f};
    static const float speeds[]={0,-0.0f,0.000001f,1,199.999f,200,200.001f,400,-400,1.0e15f,-1.0e15f};
    unsigned i,j;float value;
    if(!sequence){Q_memset(&cl,0,sizeof(cl));Q_memset(&r_refdef,0,sizeof(r_refdef));Q_memset(cl_entities,0,sizeof(entity_t)*4);
        viewcontrol_oldyaw=((int)(pattern%41)-20)*0.5f;viewcontrol_oldpitch=-viewcontrol_oldyaw;viewcontrol_oldz=coordinates[(pattern>>1)%14];}
    for(i=0;i<28;i++)bench486_view_controls[i]->value=0;
    cl_rollspeed.value=200;cl_rollangle.value=(pattern&1)?2:-2;cl_bob.value=(pattern&2)?0.02f:0;
    cl_bobcycle.value=(pattern&4)?0.6f:1;cl_bobup.value=(pattern&8)?0.5f:0.25f;
    v_kicktime.value=(pattern&16)?0.5f:1;v_centermove.value=0.15f;v_centerspeed.value=500;cl_forwardspeed.value=200;
    v_iyaw_cycle.value=2;v_iroll_cycle.value=0.5f;v_ipitch_cycle.value=1;
    v_iyaw_level.value=0.3f;v_iroll_level.value=0.1f;v_ipitch_level.value=0.3f;v_idlescale.value=(pattern>>5)&3;
    scr_viewsize.value=80+(pattern%4)*10;scr_ofsx.value=(int)(pattern%33)-16;scr_ofsy.value=-scr_ofsx.value;scr_ofsz.value=0.5f;
    crosshair.value=(pattern>>7)&1;cl_crossx.value=((int)(pattern%9)-4)*0.5f;cl_crossy.value=-cl_crossx.value;
    chase_active.value=(pattern>>8)&1;lcd_x.value=(pattern>>9)&1;lcd_yaw.value=0.25f;
    cl.time=((int)(pattern%100000)-50000)*0.0783;cl.oldtime=cl.time-((pattern&32)?0.0783:-0.0783);
    cl.laststop=(pattern&64)?cl.time:cl.time-0.0783;cl.nodrift=(pattern>>10)&1;cl.onground=(pattern>>11)&1;
    cl.pitchvel=((int)(pattern%11)-5)*10;cl.driftmove=(pattern%5)*0.1f;cl.idealpitch=((int)(pattern%61)-30);
    cl.viewheight=22;cl.maxclients=(pattern>>12)&1?2:1;cl.paused=(pattern>>13)&1;cl.intermission=(pattern>>14)&1;
    cl.viewentity=pattern%4;cl.stats[STAT_HEALTH]=(pattern&128)?100:0;cl.stats[STAT_WEAPON]=pattern%MAX_MODELS;
    cl.stats[STAT_WEAPONFRAME]=pattern&31;cl.model_precache[cl.stats[STAT_WEAPON]]=&bench486_view_models[pattern&1];
    cl.cmd.forwardmove=speeds[(pattern>>1)%11];cls.demoplayback=(pattern>>15)&1;noclip_anglehack=(pattern>>16)&1;con_forcedup=(pattern>>17)&1;
    v_dmg_time=((int)(pattern%21)-10)*0.1f;v_dmg_roll=0.7f;v_dmg_pitch=-0.3f;
    for(i=0;i<3;i++){
        cl.velocity[i]=speeds[(pattern+i)%11];cl.viewangles[i]=((int)((pattern>>(i*3))%721)-360)*0.25f;
        cl.punchangle[i]=((int)(pattern%17)-8)*0.125f;r_refdef.viewangles[i]=cl.viewangles[i];
        value=coordinates[(pattern+i)%14];r_refdef.vieworg[i]=value;
        for(j=0;j<4;j++){cl_entities[j].origin[i]=coordinates[(pattern+i+j)%14];cl_entities[j].angles[i]=cl.viewangles[i];}
        forward[i]=i==0?1:0;right[i]=i==1?1:0;up[i]=i==2?1:0;
    }
    vid.buffer=bench486_view_buffer.data;vid.rowbytes=640;vid.width=320;vid.height=200;vid.aspect=(pattern&256)?1.2f:0.8f;
    scr_vrect.x=pattern%17;scr_vrect.y=pattern%13;scr_vrect.width=320;scr_vrect.height=200;
    r_refdef.vrect=scr_vrect;bench486_view_float_result=0;
}
static void Bench486ViewStep(unsigned pair,unsigned pattern,unsigned sequence)
{
    static bench486_view_state_t initial,c_state,a_state;
    static byte c_trace[sizeof(bench486_view_trace)];unsigned args[3],c_abi,a_abi,i;int failed;float angle;
    Bench486ViewInputs(pattern,sequence);Bench486ViewSave(&initial);
    args[1]=(unsigned)cl.viewangles;args[2]=(unsigned)cl.velocity;
    if(pair==5){angle=((int)(pattern%8193)-4096)*0.25f;Q_memcpy(&args[1],&angle,4);args[2]=0;}
    Q_memset(&bench486_view_trace,0,sizeof(bench486_view_trace));
    args[0]=(unsigned)bench486_view_pairs[pair].c;
    c_abi=Bench486Call_asm486(bench486_view_pairs[pair].floating?Bench486ViewFloatCall:bench486_view_pairs[pair].c,
        bench486_view_pairs[pair].floating?3:0,args,NULL);
    Bench486ViewSave(&c_state);Q_memcpy(c_trace,&bench486_view_trace,sizeof(c_trace));failed=!Bench486ViewGuards();
    Bench486ViewRestore(&initial);Q_memset(&bench486_view_trace,0,sizeof(bench486_view_trace));
    args[0]=(unsigned)bench486_view_pairs[pair].a;
    a_abi=Bench486Call_asm486(bench486_view_pairs[pair].floating?Bench486ViewFloatCall:bench486_view_pairs[pair].a,
        bench486_view_pairs[pair].floating?3:0,args,NULL);
    Bench486ViewSave(&a_state);
    failed|=c_abi || a_abi || !Bench486ViewGuards() || bench486_view_trace.errors ||
        Q_memcmp(c_trace,&bench486_view_trace,sizeof(c_trace)) || Q_memcmp(&c_state,&a_state,sizeof(c_state));
    if(failed){bench486_memory_failures++;
        if(bench486_memory_failures<24){for(i=0;i<sizeof(c_state);i++)if(((byte *)&c_state)[i]!=((byte *)&a_state)[i])break;
            Bench486Printf("view %s FAIL pattern %u ABI %x/%x state-byte %u trace %u\n",bench486_view_pairs[pair].name,pattern,c_abi,a_abi,i,bench486_view_trace.count);
            if(i<sizeof(c_state))Bench486Printf("view state C %02x assembly %02x\n",((byte *)&c_state)[i],((byte *)&a_state)[i]);}}
}
static void Bench486ViewControlCases(void)
{
    static bench486_view_state_t saved;unsigned short cw,control;
    static const unsigned modes[]={0x007f,0x047f,0x087f,0x0c7f,0x027f,0x067f,0x0a7f,0x0e7f,0x037f,0x077f,0x0b7f,0x0f7f};
    void (*probe)(unsigned,unsigned,const unsigned *);unsigned i,mode,step,pair,cases=0,failures=bench486_memory_failures,negative=0,hash;
    double frametime=host_frametime;Bench486ViewSave(&saved);probe=bench486_view_probe;bench486_view_probe=Bench486ViewObserveFixture;
    host_frametime=0.0783;__asm__ __volatile__("fnstcw %0":"=m"(cw));
    for(i=0;i<8;i++){bench486_view_buffer.first[i]=0x5a5a5a5aU;bench486_view_buffer.last[i]=0xa5a5a5a5U;}
    for(i=0;i<sizeof(bench486_view_buffer.data);i++)bench486_view_buffer.data[i]=(byte)(i*37);
    hash=2166136261U;for(i=0;i<sizeof(bench486_view_buffer.data);i++)hash=(hash^bench486_view_buffer.data[i])*16777619U;
    for(mode=0;mode<12;mode++){control=(cw&~0x0f00U)|(modes[mode]&0x0f00U);__asm__ __volatile__("fldcw %0"::"m"(control));
        for(step=0;step<64;step++)for(pair=0;pair<13;pair++){Bench486ViewStep(pair,step*0x1020305U+pair*0x486U,0);cases++;}}
    for(step=0;step<8192;step++){Bench486ViewStep(step%13,step*0x9e3779b9U,1);cases++;}
    __asm__ __volatile__("fldcw %0"::"m"(cw));
    {unsigned after=2166136261U;for(i=0;i<sizeof(bench486_view_buffer.data);i++)after=(after^bench486_view_buffer.data[i])*16777619U;if(hash!=after)bench486_memory_failures++;}
    for(i=0;i<8;i++){bench486_view_buffer.first[i]^=1;if(!Bench486ViewGuards())negative++;bench486_view_buffer.first[i]^=1;
        bench486_view_buffer.last[i]^=1;if(!Bench486ViewGuards())negative++;bench486_view_buffer.last[i]^=1;}
    if(negative!=16)bench486_memory_failures++;
    bench486_view_probe=probe;Bench486ViewRestore(&saved);host_frametime=frametime;
    Bench486Printf("view control exact camera/gun/drift/stereo/trace/ABI %s (13 entries; %u cases; 12 control words; 8192 sequence calls; %u guard checks; %u failures)\n",
        failures==bench486_memory_failures?"PASS":"FAIL",cases,negative,bench486_memory_failures-failures);
}
#else
static void Bench486ViewControlCases(void)
{bench486_memory_failures++;Bench486Printf("view control fixture requires ViewControlImplementation=asm\n");}
#endif
