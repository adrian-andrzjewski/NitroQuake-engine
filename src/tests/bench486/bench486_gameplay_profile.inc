/* Bounded live-server measurement; BENCH486 only, never normal game code. */
#include <stdlib.h>
static int bench486_gameplay_pending;
static int bench486_gameplay_remaining;
static int bench486_gameplay_frames;
static int bench486_gameplay_control;
static double bench486_gameplay_start;

static void Bench486Gameplay_f (void)
{
	int frames;
	if (cmd_source != src_command || Cmd_Argc() != 2 || !sv.active ||
			cls.signon != SIGNONS || cls.demoplayback)
	{
		Con_Printf ("benchprofile <frames>: requires a signed-on local game\n");
		return;
	}
	frames = Q_atoi (Cmd_Argv(1));
	if (frames < 1 || frames > 4096 || bench486_gameplay_pending ||
			bench486_gameplay_remaining)
		Sys_Error ("Invalid or already active gameplay capture");
	bench486_gameplay_pending = frames;
}

void Bench486GameplayFrameStart (void)
{
	int i;
	if (!bench486_gameplay_pending)
		return;
	bench486_gameplay_remaining = bench486_gameplay_pending;
	bench486_gameplay_pending = 0;
	bench486_gameplay_frames = 0;
	bench486_gameplay_control = COM_CheckParm ("-profileoff") != 0;
	srand (1);
	for (i=0 ; i<progs->numfunctions ; i++)
		pr_functions[i].profile = 0;
#ifdef PROFILE486
	Bench486ResetTimedemoCounters ();
	if (!bench486_gameplay_control)
	{
		bench486_profile_frame_active = !bench486_profile_coarse_mode;
		bench486_profile_coarse_active = bench486_profile_coarse_mode;
	}
#endif
	bench486_gameplay_start = Sys_FloatTime ();
}

void Bench486GameplayFrameEnd (void)
{
	int handle, i, j;
	unsigned state = 0;
	float *value;
	edict_t *ent;
	double seconds;
	char text[512];
	if (!bench486_gameplay_remaining)
		return;
	bench486_gameplay_frames++;
	if (--bench486_gameplay_remaining)
		return;
	seconds = Sys_FloatTime () - bench486_gameplay_start;
#ifdef PROFILE486
	bench486_profile_frame_active = false;
	bench486_profile_coarse_active = false;
#endif
	handle = Sys_FileOpenWrite ("GAMEPROF.TXT");
	if (handle == -1)
		Sys_Error ("Cannot write GAMEPROF.TXT");
	sprintf (text, "%d frames %.6f seconds %.6f fps\n",
			bench486_gameplay_frames, seconds, bench486_gameplay_frames / seconds);
	Sys_FileWrite (handle, text, Q_strlen(text));
	sprintf (text, "map %s width %d height %d server %d edicts %d simulation-time %.6f sound %d rate %d channels %d bits %d\n",
			sv.name, vid.width, vid.height, sv.active, sv.num_edicts, sv.time,
			shm != NULL, shm ? shm->speed : 0, shm ? shm->channels : 0,
			shm ? shm->samplebits : 0);
	Sys_FileWrite (handle, text, Q_strlen(text));
	/* Hash selected numeric state, never pointers or edict padding. */
	for (i=0 ; i<sv.num_edicts ; i++)
	{
		ent = EDICT_NUM(i);
		state = state * 33 + ent->free;
		value = ent->v.origin;
		for (j=0 ; j<3 ; j++)
			state = state * 33 + Bench486Checksum ((byte *)&value[j], sizeof(float));
		state = state * 33 + Bench486Checksum ((byte *)&ent->v.health, sizeof(float));
		state = state * 33 + Bench486Checksum ((byte *)&ent->v.frame, sizeof(float));
		state = state * 33 + Bench486Checksum ((byte *)&ent->v.nextthink, sizeof(float));
	}
	sprintf (text, "simulation-checksum %u\n", state);
	Sys_FileWrite (handle, text, Q_strlen(text));
	Bench486WriteTimedemoFrameChecksum (handle);
#ifdef PROFILE486
	if (!bench486_gameplay_control)
		Bench486WriteTimedemoCounters (handle, bench486_gameplay_frames, seconds);
#endif
	Sys_FileClose (handle);
	handle = Sys_FileOpenWrite ("QCPROF.CSV");
	if (handle == -1)
		Sys_Error ("Cannot write QCPROF.CSV");
	strcpy (text, "function,statements\n");
	Sys_FileWrite (handle, text, Q_strlen(text));
	for (i=0 ; i<progs->numfunctions ; i++)
		if (pr_functions[i].profile)
		{
			sprintf (text, "%s,%d\n", pr_strings + pr_functions[i].s_name,
					pr_functions[i].profile);
			Sys_FileWrite (handle, text, Q_strlen(text));
		}
	Sys_FileClose (handle);
	Sys_Quit ();
}
