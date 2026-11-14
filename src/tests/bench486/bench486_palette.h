/* Exact, independent view.c palette/gamma oracles; BENCH486 only. */
extern byte gammatable[256], bench486_gamma_before[32], bench486_gamma_after[32];
extern cvar_t v_gamma;
extern cshift_t cshift_empty, cshift_water, cshift_slime, cshift_lava;
extern void BuildGammaTable_C (float gamma);
extern void BuildGammaTable_asm486 (float gamma);
extern void V_SetContentsColor_C (int contents);
extern void V_SetContentsColor_asm486 (int contents);
extern void V_CalcPowerupCshift_C (void);
extern void V_CalcPowerupCshift_asm486 (void);
extern void V_BonusFlash_C (void);
extern void V_BonusFlash_f (void);
extern void V_BonusFlash_asm486 (void);
extern void V_cshift_f_C (void);
extern void V_cshift_f (void);
extern void V_cshift_f_asm486 (void);
extern void V_UpdatePalette_C (void);
extern void V_UpdatePalette_asm486 (void);
extern void Bench486PaletteSetHook (void (*hook)(byte *));
extern void Bench486GammaState_C (unsigned *word, int restore);
extern void Bench486GammaState_asm486 (unsigned *word, int restore);
extern unsigned bench486_palette_stack_failures;

typedef struct {
    cshift_t shifts[NUM_CSHIFTS], previous[NUM_CSHIFTS];
    byte gamma[256];
    unsigned oldgamma;
    int recalc;
} bench486_palette_state_t;

static struct {
    unsigned first;
    byte bytes[768];
    unsigned last;
} bench486_palette_capture;
static int bench486_palette_dispatches;

static void Bench486PaletteCapture (byte *palette)
{
    bench486_palette_dispatches++;
    Q_memcpy(bench486_palette_capture.bytes,palette,768);
}

static void Bench486PaletteDeliberateGuardFault (byte *palette)
{
    /* The assembly fixture explicitly allocates these two guard bytes. */
    palette[-1] ^= 1;
    palette[768] ^= 1;
}

static int Bench486GammaGuards (void)
{
    int i;
    for(i=0 ; i<32 ; i++)
        if(bench486_gamma_before[i]!=0xa5 || bench486_gamma_after[i]!=0xa5)
            return false;
    return true;
}

static void Bench486PaletteRead (bench486_palette_state_t *state, int assembly)
{
    Q_memcpy(state->shifts,cl.cshifts,sizeof(state->shifts));
    Q_memcpy(state->previous,cl.prev_cshifts,sizeof(state->previous));
    Q_memcpy(state->gamma,gammatable,256);
    state->recalc=vid.recalc_refdef;
    if(assembly) Bench486GammaState_asm486(&state->oldgamma,0);
    else Bench486GammaState_C(&state->oldgamma,0);
}

static void Bench486PaletteWrite (bench486_palette_state_t *state, int assembly)
{
    Q_memcpy(cl.cshifts,state->shifts,sizeof(state->shifts));
    Q_memcpy(cl.prev_cshifts,state->previous,sizeof(state->previous));
    Q_memcpy(gammatable,state->gamma,256);
    vid.recalc_refdef=state->recalc;
    if(assembly) Bench486GammaState_asm486(&state->oldgamma,1);
    else Bench486GammaState_C(&state->oldgamma,1);
}

static void Bench486BonusFlashCases (void)
{
    static client_state_t saved,initial,expected,c_state;
    unsigned pattern,index,c_abi,a_abi,public_abi,cases=0,failures=0;

    Q_memcpy(&saved,&cl,sizeof(cl));
    for(pattern=0;pattern<256;pattern++)
    {
        for(index=0;index<sizeof(cl);index++)
            ((byte *)&cl)[index]=(byte)(pattern*73U+index*37U+(index>>4));
        Q_memcpy(&initial,&cl,sizeof(cl));
        Q_memcpy(&expected,&initial,sizeof(cl));
        expected.cshifts[CSHIFT_BONUS].destcolor[0]=215;
        expected.cshifts[CSHIFT_BONUS].destcolor[1]=186;
        expected.cshifts[CSHIFT_BONUS].destcolor[2]=69;
        expected.cshifts[CSHIFT_BONUS].percent=50;

        c_abi=Bench486Call_asm486(V_BonusFlash_C,0,NULL,NULL);
        Q_memcpy(&c_state,&cl,sizeof(cl));
        Q_memcpy(&cl,&initial,sizeof(cl));
        a_abi=Bench486Call_asm486(V_BonusFlash_asm486,0,NULL,NULL);
        if(c_abi || a_abi || Q_memcmp(&c_state,&expected,sizeof(cl)) ||
                Q_memcmp(&cl,&expected,sizeof(cl)))
            failures++;

        Q_memcpy(&cl,&initial,sizeof(cl));
        public_abi=Bench486Call_asm486(V_BonusFlash_f,0,NULL,NULL);
        if(public_abi || Q_memcmp(&cl,&expected,sizeof(cl)))
            failures++;
        cases++;
    }
    Q_memcpy(&cl,&saved,sizeof(cl));
    if(failures) bench486_memory_failures++;
    Bench486Printf("bonus flash C/ASM/public state and ABI %s (%u patterns; %u failures)\n",
            failures?"FAIL":"PASS",cases,failures);
}

static unsigned Bench486CshiftCall (void (*function)(void), const char *line,
        const cshift_t *initial, cshift_t *result)
{
    static char command[128];
    unsigned abi;

    /* These legacy Quake helpers predate const-qualified source arguments. */
    Q_memcpy(&cshift_empty,(void *)initial,sizeof(cshift_empty));
    Q_strcpy(command,(char *)line);
    Cmd_TokenizeString(command);
    abi=Bench486Call_asm486(function,0,NULL,NULL);
    Q_memcpy(result,&cshift_empty,sizeof(*result));
    return abi;
}

static void Bench486CshiftCases (void)
{
    static const struct {
        const char *line;
        int color[3],percent;
    } cases[]={
        {"v_cshift 12 -3 255 96",{12,-3,255},96},
        {"v_cshift +17junk -08 0x10 +40tail",{17,-8,0},40},
        {"v_cshift nope -4 9x -1",{0,-4,9},-1},
        {"v_cshift 21",{21,0,0},0},
        {"v_cshift 300 -10 0 999 ignored",{300,-10,0},999},
        {"v_cshift -2147483648 2147483647 -2147483647 2147483646",
            {(-2147483647-1),2147483647,-2147483647},2147483646},
        {"v_cshift",{0,0,0},0}
    };
    static cshift_t saved,initial,expected,c_result,a_result,public_result;
    static client_state_t saved_client,expected_client,c_client,a_client,public_client;
    static char saved_command[1024];
    unsigned c_abi,a_abi,public_abi,c_set_abi,a_set_abi,public_set_abi;
    unsigned args[1],cases_run=0,failures=0;
    int i;

    Q_memcpy(&saved,&cshift_empty,sizeof(saved));
    Q_memcpy(&saved_client,&cl,sizeof(cl));
    saved_command[0]=0;
    if(Cmd_Argc()>0)
    {
        Q_strcpy(saved_command,Cmd_Argv(0));
        if(Cmd_Argc()>1 && Cmd_Args() && Cmd_Args()[0])
        {
            strcat(saved_command," ");
            strcat(saved_command,Cmd_Args());
        }
    }

    for(i=0;i<sizeof(cases)/sizeof(cases[0]);i++)
    {
        initial.destcolor[0]=101+i;
        initial.destcolor[1]=121+i;
        initial.destcolor[2]=141+i;
        initial.percent=161+i;
        expected=initial;
        expected.destcolor[0]=cases[i].color[0];
        expected.destcolor[1]=cases[i].color[1];
        expected.destcolor[2]=cases[i].color[2];
        expected.percent=cases[i].percent;

        Q_memcpy(&cl,&saved_client,sizeof(cl));
        c_abi=Bench486CshiftCall(V_cshift_f_C,cases[i].line,&initial,&c_result);
        expected_client=saved_client;
        expected_client.cshifts[CSHIFT_CONTENTS]=expected;
        args[0]=CONTENTS_EMPTY;
        c_set_abi=Bench486Call_asm486((void (*)(void))V_SetContentsColor_C,1,args,NULL);
        Q_memcpy(&c_client,&cl,sizeof(cl));

        Q_memcpy(&cl,&saved_client,sizeof(cl));
        a_abi=Bench486CshiftCall(V_cshift_f_asm486,cases[i].line,&initial,&a_result);
        a_set_abi=Bench486Call_asm486((void (*)(void))V_SetContentsColor_asm486,1,args,NULL);
        Q_memcpy(&a_client,&cl,sizeof(cl));

        Q_memcpy(&cl,&saved_client,sizeof(cl));
        public_abi=Bench486CshiftCall(V_cshift_f,cases[i].line,&initial,&public_result);
        public_set_abi=Bench486Call_asm486((void (*)(void))V_SetContentsColor_asm486,1,args,NULL);
        Q_memcpy(&public_client,&cl,sizeof(cl));
        if(c_abi || a_abi || public_abi || c_set_abi || a_set_abi || public_set_abi ||
                Q_memcmp(&c_result,&expected,sizeof(expected)) ||
                Q_memcmp(&a_result,&expected,sizeof(expected)) ||
                Q_memcmp(&public_result,&expected,sizeof(expected)) ||
                Q_memcmp(&c_client,&expected_client,sizeof(cl)) ||
                Q_memcmp(&a_client,&expected_client,sizeof(cl)) ||
                Q_memcmp(&public_client,&expected_client,sizeof(cl)))
            failures++;
        cases_run++;
    }

    Q_memcpy(&cshift_empty,&saved,sizeof(saved));
    Q_memcpy(&cl,&saved_client,sizeof(cl));
    Cmd_TokenizeString(saved_command);
    if(failures) bench486_memory_failures++;
    Bench486Printf("v_cshift C/ASM/public state, contents shift and ABI %s (%u token cases; %u failures)\n",
            failures?"FAIL":"PASS",cases_run,failures);
}

static void Bench486PaletteStep (int sequence, unsigned short cw,
        bench486_palette_state_t *reference, bench486_palette_state_t *assembly)
{
    static const float gammas[]={1,0.7f,0.5f,1.2f,2,3,1.000001f,0.999999f};
    static const double times[]={0,0.0783,0.0001,1.0,0.01,10.0,0.005,0.0000000001};
    byte c_output[768];
    unsigned c_abi, a_abi, bonus_abi;
    int c_calls, i, itemmask;

    itemmask=sequence & 15;
    cl.items=((itemmask&1)?IT_QUAD:0) | ((itemmask&2)?IT_SUIT:0) |
        ((itemmask&4)?IT_INVISIBILITY:0) | ((itemmask&8)?IT_INVULNERABILITY:0);
    host_frametime=times[sequence%8];
    v_gamma.value=gammas[(sequence/113)%8];
    for(i=0 ; i<2 ; i++)
    {
        bench486_palette_state_t *state=i?assembly:reference;
        if(sequence%19==0)
        {
            state->shifts[CSHIFT_DAMAGE].percent=150;
            state->shifts[CSHIFT_DAMAGE].destcolor[0]=255;
            state->shifts[CSHIFT_DAMAGE].destcolor[1]=50;
            state->shifts[CSHIFT_DAMAGE].destcolor[2]=25;
            Bench486PaletteWrite(state,i);
            bonus_abi=Bench486Call_asm486(i?V_BonusFlash_asm486:V_BonusFlash_C,
                    0,NULL,NULL);
            Bench486PaletteRead(state,i);
            if(bonus_abi) bench486_memory_failures++;
        }
        if(sequence%7==0)
        {
            state->shifts[CSHIFT_CONTENTS].percent=sequence%257;
            state->shifts[CSHIFT_CONTENTS].destcolor[0]=(sequence*17)&255;
            state->shifts[CSHIFT_CONTENTS].destcolor[1]=(sequence*23)&255;
            state->shifts[CSHIFT_CONTENTS].destcolor[2]=(sequence*31)&255;
        }
    }
    Bench486PaletteWrite(reference,0);
    Q_memset(bench486_palette_capture.bytes,0x5a,768);
    bench486_palette_dispatches=0;
    c_abi=Bench486Call_asm486(V_UpdatePalette_C,0,NULL,NULL);
    c_calls=bench486_palette_dispatches;
    Q_memcpy(c_output,bench486_palette_capture.bytes,768);
    Bench486PaletteRead(reference,0);
    Bench486PaletteWrite(assembly,1);
    Q_memset(bench486_palette_capture.bytes,0x5a,768);
    bench486_palette_dispatches=0;
    a_abi=Bench486Call_asm486(V_UpdatePalette_asm486,0,NULL,NULL);
    Bench486PaletteRead(assembly,1);
    if(c_abi || a_abi || c_calls!=bench486_palette_dispatches ||
            Q_memcmp(c_output,bench486_palette_capture.bytes,768) ||
            Q_memcmp(reference,assembly,sizeof(*reference)) ||
            !Bench486GammaGuards() || bench486_palette_stack_failures ||
            bench486_palette_capture.first!=0x486a1357 ||
            bench486_palette_capture.last!=0x486b2468)
    {
        bench486_memory_failures++;
        if(bench486_memory_failures<20)
            Bench486Printf("palette FAIL frame %d cw %04x ABI %x/%x calls %d/%d state %d pixels %d guards %d/%u\n",
                    sequence,cw,c_abi,a_abi,c_calls,bench486_palette_dispatches,
                    Q_memcmp(reference,assembly,sizeof(*reference)),
                    Q_memcmp(c_output,bench486_palette_capture.bytes,768),
                    Bench486GammaGuards(),bench486_palette_stack_failures);
    }
}

static void Bench486PaletteCases (void)
{
    static const float gammas[]={1,0,0.5f,0.7f,1.000001f,0.999999f,1.2f,2,3,8,32,-1,-8,-32};
    static const int contents[]={CONTENTS_EMPTY,CONTENTS_SOLID,CONTENTS_WATER,
        CONTENTS_SLIME,CONTENTS_LAVA,0,1,-6,2147483647,(-2147483647-1)};
    static struct { unsigned first; byte bytes[768]; unsigned last; } basepal;
    bench486_palette_state_t saved, reference, assembly;
    cshift_t initial[NUM_CSHIFTS], c_contents[NUM_CSHIFTS];
    byte c_gamma[256], saved_before[32],saved_after[32];
    byte *saved_basepal;
    double saved_time;
    float saved_gamma;
    unsigned saved_asm_old, saved_stack, args[1], c_abi, a_abi;
    unsigned short saved_cw,cw;
    int saved_items, precision, mode, i,j,mask,sequence,before,direct,frames;

    Bench486PaletteRead(&saved,0);
    Bench486GammaState_asm486(&saved_asm_old,0);
    saved_stack=bench486_palette_stack_failures;
    saved_basepal=host_basepal; saved_time=host_frametime;
    saved_gamma=v_gamma.value; saved_items=cl.items;
    Q_memcpy(saved_before,bench486_gamma_before,32);
    Q_memcpy(saved_after,bench486_gamma_after,32);
    Q_memset(bench486_gamma_before,0xa5,32);
    Q_memset(bench486_gamma_after,0xa5,32);
    basepal.first=0x486a1357; basepal.last=0x486b2468;
    for(i=0 ; i<768 ; i++) basepal.bytes[i]=(byte)((i*73+i/7)&255);
    host_basepal=basepal.bytes;
    bench486_palette_capture.first=0x486a1357;
    bench486_palette_capture.last=0x486b2468;
    bench486_palette_stack_failures=0;
    before=bench486_memory_failures; direct=frames=0;
    Bench486CshiftCases();
    Bench486BonusFlashCases();
    /* V_Init calls the public getter before this startup command executes. */
    for(i=0 ; i<256 ; i++) if(gammatable[i]!=(byte)i)
    {
        bench486_memory_failures++;
        Bench486Printf("palette startup gamma FAIL index %d value %d expected %d\n",i,gammatable[i],i);
        break;
    }
    __asm__ __volatile__("fnstcw %0" : "=m"(saved_cw));
    for(precision=0 ; precision<=3 ; precision++)
    {
        if(precision==1) continue;
        for(mode=0 ; mode<4 ; mode++)
        {
            cw=(saved_cw&~0x0f00)|(precision<<8)|(mode<<10);
            __asm__ __volatile__("fldcw %0" : : "m"(cw));
            for(i=0 ; i<sizeof(gammas)/sizeof(gammas[0]) ; i++,direct++)
            {
                Q_memcpy(args,(void *)&gammas[i],4);
                c_abi=Bench486Call_asm486((void (*)(void))BuildGammaTable_C,1,args,NULL);
                Q_memcpy(c_gamma,gammatable,256);
                a_abi=Bench486Call_asm486((void (*)(void))BuildGammaTable_asm486,1,args,NULL);
                if(c_abi || a_abi || Q_memcmp(c_gamma,gammatable,256) || !Bench486GammaGuards())
                {
                    bench486_memory_failures++;
                    if(bench486_memory_failures<20)
                        Bench486Printf("gamma FAIL case %d cw %04x ABI %x/%x\n",i,cw,c_abi,a_abi);
                }
            }
            for(mask=0 ; mask<16 ; mask++,direct++)
            {
                cl.items=((mask&1)?IT_QUAD:0)|((mask&2)?IT_SUIT:0)|
                    ((mask&4)?IT_INVISIBILITY:0)|((mask&8)?IT_INVULNERABILITY:0);
                Q_memset(cl.cshifts,0x5a,sizeof(cl.cshifts));
                Q_memcpy(initial,cl.cshifts,sizeof(initial));
                c_abi=Bench486Call_asm486(V_CalcPowerupCshift_C,0,NULL,NULL);
                Q_memcpy(c_contents,cl.cshifts,sizeof(c_contents));
                Q_memcpy(cl.cshifts,initial,sizeof(initial));
                a_abi=Bench486Call_asm486(V_CalcPowerupCshift_asm486,0,NULL,NULL);
                if(c_abi || a_abi || Q_memcmp(c_contents,cl.cshifts,sizeof(c_contents)))
                    bench486_memory_failures++;
            }
            for(i=0 ; i<sizeof(contents)/sizeof(contents[0]) ; i++,direct++)
            {
                args[0]=contents[i];
                Q_memset(cl.cshifts,0x5a,sizeof(cl.cshifts));
                Q_memcpy(initial,cl.cshifts,sizeof(initial));
                c_abi=Bench486Call_asm486((void (*)(void))V_SetContentsColor_C,1,args,NULL);
                Q_memcpy(c_contents,cl.cshifts,sizeof(c_contents));
                Q_memcpy(cl.cshifts,initial,sizeof(initial));
                a_abi=Bench486Call_asm486((void (*)(void))V_SetContentsColor_asm486,1,args,NULL);
                if(c_abi || a_abi || Q_memcmp(c_contents,cl.cshifts,sizeof(c_contents)))
                    bench486_memory_failures++;
            }
            Q_memset(&reference,0,sizeof(reference));
            Q_memset(reference.gamma,0x5a,256);
            assembly=reference;
            Bench486PaletteSetHook(Bench486PaletteCapture);
            for(sequence=0 ; sequence<128 ; sequence++,frames++)
                Bench486PaletteStep(sequence,cw,&reference,&assembly);
        }
    }
    __asm__ __volatile__("fldcw %0" : : "m"(saved_cw));
    Q_memset(&reference,0,sizeof(reference));
    Q_memset(reference.gamma,0x5a,256);
    assembly=reference;
    for(sequence=0 ; sequence<8192 ; sequence++,frames++)
        Bench486PaletteStep(sequence,saved_cw,&reference,&assembly);

    /* Prove the assembly palette's local redzones detect an actual write. */
    Bench486PaletteSetHook(Bench486PaletteDeliberateGuardFault);
    v_gamma.value=0.75f;
    V_UpdatePalette_asm486();
    if(bench486_palette_stack_failures!=1) bench486_memory_failures++;
    bench486_palette_stack_failures=0;
    Bench486PaletteSetHook(NULL);
    if(basepal.first!=0x486a1357 || basepal.last!=0x486b2468)
        bench486_memory_failures++;
    for(i=0 ; i<768 ; i++) if(basepal.bytes[i]!=(byte)((i*73+i/7)&255))
        bench486_memory_failures++;
    Bench486PaletteWrite(&saved,0);
    Bench486GammaState_asm486(&saved_asm_old,1);
    bench486_palette_stack_failures=saved_stack;
    host_basepal=saved_basepal; host_frametime=saved_time;
    v_gamma.value=saved_gamma; cl.items=saved_items;
    Q_memcpy(bench486_gamma_before,saved_before,32);
    Q_memcpy(bench486_gamma_after,saved_after,32);
    Bench486Printf("palette exact gamma/contents/powerup/state/output/ABI/guards %s (%d direct cases; %d frames; %d failures)\n",
            before==bench486_memory_failures?"PASS":"FAIL",direct,frames,bench486_memory_failures-before);
}
