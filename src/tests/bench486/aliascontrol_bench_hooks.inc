/* BENCH-only typed boundaries. Null probes execute the unchanged real calls. */
/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
#include <stdarg.h>
aliashdr_t *(*bench486_aliascontrol_model_probe)(model_t *);
void (*bench486_aliascontrol_probe)(unsigned,unsigned,const unsigned *);
double (*bench486_aliascontrol_time_probe)(void);
unsigned bench486_aliascontrol_bbox_result;
static int Bench486AliasControlObserve(unsigned phase,unsigned count,const unsigned *words)
{
    if(!bench486_aliascontrol_probe)return 0;
    bench486_aliascontrol_probe(phase,count,words);return 1;
}
void *Bench486AliasControlModel(model_t *model)
{
    if(bench486_aliascontrol_model_probe)return bench486_aliascontrol_model_probe(model);
#ifdef ASM486_ALIAS_CONTROL
    return Mod_Extradata_asm486(model);
#else
    return Mod_Extradata(model);
#endif
}
void Bench486AliasControlPrint(char *format,...)
{
    char text[256];unsigned argument;va_list args;
    /* All three original call sites use these fixed formats. A model name is
       MAX_QPATH bytes; even a full-width signed frame/skin number fits here.
       Keep the original vsprintf runtime, whose actual object is source-proved. */
    if(strcmp(format,"No such frame %d %s\n") &&
       strcmp(format,"R_AliasSetupSkin: no such skin # %d\n") &&
       strcmp(format,"R_AliasSetupFrame: no such frame %d\n"))
        Sys_Error("alias-control: unexpected diagnostic format");
    va_start(args,format);vsprintf(text,format,args);va_end(args);
    argument=(unsigned)text;
    if(!Bench486AliasControlObserve(1,1,&argument))Con_DPrintf("%s",text);
}
void Bench486AliasControlRaster(void)
{if(!Bench486AliasControlObserve(2,0,NULL))D_PolysetDraw();}
void Bench486AliasControlTables(void)
{if(!Bench486AliasControlObserve(3,0,NULL))D_PolysetUpdateTables();}
void Bench486AliasControlClip(mtriangle_t *triangle)
{unsigned argument=(unsigned)triangle;if(!Bench486AliasControlObserve(4,1,&argument))R_AliasClipTriangle(triangle);}
void Bench486AliasControlFinalVerts(finalvert_t *vertices,int count)
{unsigned arguments[2];arguments[0]=(unsigned)vertices;arguments[1]=count;
 if(!Bench486AliasControlObserve(5,2,arguments))D_PolysetDrawFinalVerts(vertices,count);}
void Bench486AliasControlPatch(void *colormap)
{unsigned argument=(unsigned)colormap;if(!Bench486AliasControlObserve(6,1,&argument))D_Aff8Patch(colormap);}
void Bench486AliasControlProfileEnter(unsigned phase)
{unsigned argument=phase;
#ifdef PROFILE486
 if(!Bench486AliasControlObserve(7,1,&argument))Bench486ProfileEnter(phase);
#else
 Bench486AliasControlObserve(7,1,&argument);
#endif
}
void Bench486AliasControlProfileLeave(void)
{
#ifdef PROFILE486
 if(!Bench486AliasControlObserve(8,0,NULL))Bench486ProfileLeave();
#else
 Bench486AliasControlObserve(8,0,NULL);
#endif
}
void Bench486AliasControlProfileWork(unsigned phase,unsigned long items,unsigned long bytes)
{unsigned arguments[3];arguments[0]=phase;arguments[1]=items;arguments[2]=bytes;
#ifdef PROFILE486
 if(!Bench486AliasControlObserve(9,3,arguments))Bench486ProfileWork(phase,items,bytes);
#else
 Bench486AliasControlObserve(9,3,arguments);
#endif
}
double Bench486AliasControlTime(void)
{return bench486_aliascontrol_time_probe?bench486_aliascontrol_time_probe():Sys_FloatTime();}
