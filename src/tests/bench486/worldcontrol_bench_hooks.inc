/* Typed BENCH486 call boundaries; the production algorithms are unchanged. */
/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
void (*bench486_worldcontrol_probe)(unsigned,unsigned,const unsigned *);
void Bench486WorldControlPrint(char *message,...)
{
    unsigned argument=(unsigned)message;
    /* The original fragment allocator has one literal, with no conversions. */
    if(strcmp(message,"Too many efrags!\n"))Sys_Error("world-control: unexpected fragment diagnostic");
    if(bench486_worldcontrol_probe)bench486_worldcontrol_probe(1,1,&argument);
    else Con_Printf("%s",message);
}
void Bench486WorldControlPoly(msurface_t *surface,int clipflags)
{
    unsigned arguments[2];arguments[0]=(unsigned)surface;arguments[1]=clipflags;
    if(bench486_worldcontrol_probe)bench486_worldcontrol_probe(2,2,arguments);
    else R_RenderPoly(surface,clipflags);
}
void Bench486WorldControlFrustum(void)
{
    if(bench486_worldcontrol_probe)bench486_worldcontrol_probe(3,0,NULL);
    /* Compare the real frustum results, rather than substituting a stub. */
    R_TransformFrustum();
}
