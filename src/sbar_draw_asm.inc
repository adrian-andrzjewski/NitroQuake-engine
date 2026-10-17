/* Per-frame status-bar composition from src/sbar.c:Sbar_Draw. */
#if defined(BENCH486) && defined(ASM486_SBAR_DRAW_FIXTURE)
#define SBAR_DRAW_TILE_CLEAR _Bench486SbarDrawTileClear
#define SBAR_DRAW_INVENTORY _Bench486SbarDrawInventory
#define SBAR_DRAW_FRAGS _Bench486SbarDrawFrags
#define SBAR_DRAW_PIC _Bench486SbarDrawPic
#define SBAR_DRAW_SCOREBOARD _Bench486SbarDrawScoreboard
#define SBAR_DRAW_NUM _Bench486SbarDrawNum
#define SBAR_DRAW_FACE _Bench486SbarDrawFace
#define SBAR_DRAW_MINI_DEATHMATCH _Bench486SbarDrawMiniDeathmatch
#elif defined(ASM486_SBAR_INVENTORY)
#define SBAR_DRAW_TILE_CLEAR _Draw_TileClear
#define SBAR_DRAW_INVENTORY _Sbar_DrawInventory_asm486
#if defined(ASM486_SBAR_FRAGS)
#define SBAR_DRAW_FRAGS _Sbar_DrawFrags_asm486
#else
#define SBAR_DRAW_FRAGS _Sbar_DrawFrags
#endif
#define SBAR_DRAW_PIC _Sbar_DrawPic
#define SBAR_DRAW_SCOREBOARD _Sbar_DrawScoreboard
#define SBAR_DRAW_NUM _Sbar_DrawNum
#define SBAR_DRAW_FACE _Sbar_DrawFace
#define SBAR_DRAW_MINI_DEATHMATCH _Sbar_MiniDeathmatchOverlay
#else
#define SBAR_DRAW_TILE_CLEAR _Draw_TileClear
#define SBAR_DRAW_INVENTORY _Sbar_DrawInventory
#if defined(ASM486_SBAR_FRAGS)
#define SBAR_DRAW_FRAGS _Sbar_DrawFrags_asm486
#else
#define SBAR_DRAW_FRAGS _Sbar_DrawFrags
#endif
#define SBAR_DRAW_PIC _Sbar_DrawPic
#define SBAR_DRAW_SCOREBOARD _Sbar_DrawScoreboard
#define SBAR_DRAW_NUM _Sbar_DrawNum
#define SBAR_DRAW_FACE _Sbar_DrawFace
#define SBAR_DRAW_MINI_DEATHMATCH _Sbar_MiniDeathmatchOverlay
#endif

#if defined(BENCH486) && defined(ASM486_SBAR_DRAW_FIXTURE)
#define SBAR_FACE_PIC _Bench486SbarFacePic
#define SBAR_FACE_CHARACTER _Bench486SbarFaceCharacter
#define SBAR_FACE_FILL _Bench486SbarFaceFill
#else
#define SBAR_FACE_PIC _Sbar_DrawPic
#define SBAR_FACE_CHARACTER _Sbar_DrawCharacter
#define SBAR_FACE_FILL _Draw_Fill
#endif

.extern _cl
.extern _vid
.extern _scr_con_current
.extern _scr_copyeverything
.extern _sb_updates
.extern _sb_lines
.extern _sb_showscores
.extern _sb_sbar
.extern _sb_scorebar
.extern _sb_items
.extern _sb_armor
.extern _sb_ammo
.extern _rsb_ammo
.extern _draw_disc
.extern _hipnotic
.extern _rogue
.extern SBAR_DRAW_TILE_CLEAR
.extern SBAR_DRAW_INVENTORY
.extern SBAR_DRAW_FRAGS
.extern SBAR_DRAW_PIC
.extern SBAR_DRAW_SCOREBOARD
.extern SBAR_DRAW_NUM
.extern SBAR_DRAW_FACE
.extern SBAR_DRAW_MINI_DEATHMATCH
.extern SBAR_FACE_PIC
.extern SBAR_FACE_CHARACTER
.extern SBAR_FACE_FILL

.macro SBAR_CALL_PIC x,y,pic
	subl	$12,%esp
	pushl	\pic
	pushl	\y
	pushl	\x
	call	SBAR_DRAW_PIC
	addl	$24,%esp
.endm

.macro SBAR_CALL_NUM x,y,number,digits,color
	subl	$12,%esp
	pushl	\color
	pushl	\digits
	pushl	\number
	pushl	\y
	pushl	\x
	call	SBAR_DRAW_NUM
	addl	$32,%esp
.endm

.text
.p2align 2
.globl _Sbar_Draw
.globl _Sbar_Draw_asm486
_Sbar_Draw:
_Sbar_Draw_asm486:
	/* Align outgoing cdecl calls to the toolchain's 16-byte boundary. */
	subl	$28,%esp
	fildl	_vid+SBAR_VID_HEIGHT_OFFSET
	fcomps	_scr_con_current
	fnstsw	%ax
	sahf
	jp	.Lsbar_draw_check_pages
	je	.Lsbar_draw_return

.Lsbar_draw_check_pages:
	movl	_sb_updates,%eax
	cmpl	_vid+SBAR_VID_NUMPAGES_OFFSET,%eax
	jge	.Lsbar_draw_return
	movl	$1,_scr_copyeverything
	incl	_sb_updates

	movl	_sb_lines,%eax
	testl	%eax,%eax
	je	.Lsbar_draw_inventory
	movl	_vid+SBAR_VID_WIDTH_OFFSET,%ecx
	cmpl	$320,%ecx
	jbe	.Lsbar_draw_inventory
	movl	_vid+SBAR_VID_HEIGHT_OFFSET,%edx
	subl	%eax,%edx
	pushl	%eax
	pushl	%ecx
	pushl	%edx
	pushl	$0
	call	SBAR_DRAW_TILE_CLEAR
	addl	$16,%esp

.Lsbar_draw_inventory:
	movl	_sb_lines,%eax
	cmpl	$24,%eax
	jle	.Lsbar_draw_score_test
	call	SBAR_DRAW_INVENTORY
	cmpl	$1,_cl+SBAR_CL_MAXCLIENTS_OFFSET
	je	.Lsbar_draw_score_test
	call	SBAR_DRAW_FRAGS

.Lsbar_draw_score_test:
	movl	_sb_showscores,%eax
	testl	%eax,%eax
	jne	.Lsbar_draw_scoreboard
	cmpl	$0,_cl+SBAR_CL_STATS_OFFSET+(SBAR_STAT_HEALTH*4)
	jle	.Lsbar_draw_scoreboard
	movl	_sb_lines,%eax
	testl	%eax,%eax
	je	.Lsbar_draw_post_bar

	SBAR_CALL_PIC $0,$0,_sb_sbar

	movl	_hipnotic,%eax
	testl	%eax,%eax
	je	.Lsbar_draw_armor
	movl	_cl+SBAR_CL_ITEMS_OFFSET,%eax
	testl	$SBAR_IT_KEY1,%eax
	je	.Lsbar_draw_key2
	movl	_sb_items,%eax
	SBAR_CALL_PIC $209,$3,%eax
.Lsbar_draw_key2:
	movl	_cl+SBAR_CL_ITEMS_OFFSET,%eax
	testl	$SBAR_IT_KEY2,%eax
	je	.Lsbar_draw_armor
	movl	_sb_items+4,%eax
	SBAR_CALL_PIC $209,$12,%eax

.Lsbar_draw_armor:
	movl	_cl+SBAR_CL_ITEMS_OFFSET,%eax
	testl	$SBAR_IT_INVULNERABILITY,%eax
	je	.Lsbar_draw_armor_value
	SBAR_CALL_NUM $24,$0,$666,$3,$1
	SBAR_CALL_PIC $0,$0,_draw_disc
	jmp	.Lsbar_draw_face

.Lsbar_draw_armor_value:
	movl	_cl+SBAR_CL_STATS_OFFSET+(SBAR_STAT_ARMOR*4),%eax
	xorl	%edx,%edx
	cmpl	$25,%eax
	setle	%dl
	SBAR_CALL_NUM $24,$0,%eax,$3,%edx

	movl	_cl+SBAR_CL_ITEMS_OFFSET,%eax
	cmpl	$0,_rogue
	jne	.Lsbar_draw_rogue_armor
	testl	$SBAR_IT_ARMOR3,%eax
	jne	.Lsbar_draw_armor3
	testl	$SBAR_IT_ARMOR2,%eax
	jne	.Lsbar_draw_armor2
	testl	$SBAR_IT_ARMOR1,%eax
	je	.Lsbar_draw_face
	movl	_sb_armor,%eax
	jmp	.Lsbar_draw_armor_pic

.Lsbar_draw_rogue_armor:
	testl	$SBAR_RIT_ARMOR3,%eax
	jne	.Lsbar_draw_armor3
	testl	$SBAR_RIT_ARMOR2,%eax
	jne	.Lsbar_draw_armor2
	testl	$SBAR_RIT_ARMOR1,%eax
	je	.Lsbar_draw_face
	movl	_sb_armor,%eax
	jmp	.Lsbar_draw_armor_pic

.Lsbar_draw_armor3:
	movl	_sb_armor+8,%eax
	jmp	.Lsbar_draw_armor_pic
.Lsbar_draw_armor2:
	movl	_sb_armor+4,%eax
.Lsbar_draw_armor_pic:
	SBAR_CALL_PIC $0,$0,%eax

.Lsbar_draw_face:
	call	SBAR_DRAW_FACE
	movl	_cl+SBAR_CL_STATS_OFFSET+(SBAR_STAT_HEALTH*4),%eax
	xorl	%edx,%edx
	cmpl	$25,%eax
	setle	%dl
	SBAR_CALL_NUM $136,$0,%eax,$3,%edx

	movl	_cl+SBAR_CL_ITEMS_OFFSET,%eax
	cmpl	$0,_rogue
	jne	.Lsbar_draw_rogue_ammo
	testl	$SBAR_IT_SHELLS,%eax
	jne	.Lsbar_draw_ammo_shells
	testl	$SBAR_IT_NAILS,%eax
	jne	.Lsbar_draw_ammo_nails
	testl	$SBAR_IT_ROCKETS,%eax
	jne	.Lsbar_draw_ammo_rockets
	testl	$SBAR_IT_CELLS,%eax
	je	.Lsbar_draw_ammo_number
	movl	_sb_ammo+12,%eax
	jmp	.Lsbar_draw_ammo_pic

.Lsbar_draw_rogue_ammo:
	testl	$SBAR_RIT_SHELLS,%eax
	jne	.Lsbar_draw_ammo_shells
	testl	$SBAR_RIT_NAILS,%eax
	jne	.Lsbar_draw_ammo_nails
	testl	$SBAR_RIT_ROCKETS,%eax
	jne	.Lsbar_draw_ammo_rockets
	testl	$SBAR_RIT_CELLS,%eax
	je	.Lsbar_draw_rogue_extra_ammo
	movl	_sb_ammo+12,%eax
	jmp	.Lsbar_draw_ammo_pic

.Lsbar_draw_rogue_extra_ammo:
	testl	$SBAR_RIT_LAVA_NAILS,%eax
	jne	.Lsbar_draw_lava_nails
	testl	$SBAR_RIT_PLASMA_AMMO,%eax
	jne	.Lsbar_draw_plasma_ammo
	testl	$SBAR_RIT_MULTI_ROCKETS,%eax
	je	.Lsbar_draw_ammo_number
	movl	_rsb_ammo+8,%eax
	jmp	.Lsbar_draw_ammo_pic

.Lsbar_draw_lava_nails:
	movl	_rsb_ammo,%eax
	jmp	.Lsbar_draw_ammo_pic
.Lsbar_draw_plasma_ammo:
	movl	_rsb_ammo+4,%eax
	jmp	.Lsbar_draw_ammo_pic
.Lsbar_draw_ammo_shells:
	movl	_sb_ammo,%eax
	jmp	.Lsbar_draw_ammo_pic
.Lsbar_draw_ammo_nails:
	movl	_sb_ammo+4,%eax
	jmp	.Lsbar_draw_ammo_pic
.Lsbar_draw_ammo_rockets:
	movl	_sb_ammo+8,%eax

.Lsbar_draw_ammo_pic:
	SBAR_CALL_PIC $224,$0,%eax

.Lsbar_draw_ammo_number:
	movl	_cl+SBAR_CL_STATS_OFFSET+(SBAR_STAT_AMMO*4),%eax
	xorl	%edx,%edx
	cmpl	$10,%eax
	setle	%dl
	SBAR_CALL_NUM $248,$0,%eax,$3,%edx
	jmp	.Lsbar_draw_post_bar

.Lsbar_draw_scoreboard:
	SBAR_CALL_PIC $0,$0,_sb_scorebar
	call	SBAR_DRAW_SCOREBOARD
	movl	$0,_sb_updates

.Lsbar_draw_post_bar:
	cmpl	$320,_vid+SBAR_VID_WIDTH_OFFSET
	jbe	.Lsbar_draw_return
	cmpl	$SBAR_GAME_DEATHMATCH,_cl+SBAR_CL_GAMETYPE_OFFSET
	jne	.Lsbar_draw_return
	call	SBAR_DRAW_MINI_DEATHMATCH

.Lsbar_draw_return:
	addl	$28,%esp
	ret

/* The C routine remains Sbar_DrawFace_C as the parity oracle. */
.text
.p2align 2
.globl _Sbar_DrawFace
.globl _Sbar_DrawFace_asm486
_Sbar_DrawFace:
_Sbar_DrawFace_asm486:
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	subl	$32,%esp

	/* Rogue team colors are shown only for teamplay values strictly in (3,7). */
	cmpl	$0,_rogue
	je	.Lsbar_face_powerups
	cmpl	$1,_cl+SBAR_CL_MAXCLIENTS_OFFSET
	je	.Lsbar_face_powerups
	flds	_teamplay+SBAR_CVAR_VALUE_OFFSET
	fcomps	.Lsbar_face_teamplay_three
	fnstsw	%ax
	sahf
	jbe	.Lsbar_face_powerups
	flds	_teamplay+SBAR_CVAR_VALUE_OFFSET
	fcomps	.Lsbar_face_teamplay_seven
	fnstsw	%ax
	sahf
	jp	.Lsbar_face_powerups
	jae	.Lsbar_face_powerups

	/* scoreboard_t is 44 bytes of fields plus 64 color translation rows. */
	movl	_cl+SBAR_CL_VIEWENTITY_OFFSET,%eax
	decl	%eax
	imull	$SBAR_SCOREBOARD_SIZE,%eax,%eax
	addl	_cl+SBAR_CL_SCORES_OFFSET,%eax
	movl	SBAR_SCOREBOARD_COLORS_OFFSET(%eax),%ebx
	movl	%ebx,%ecx
	andl	$0xf0,%ecx
	addl	$8,%ecx
	movl	%ecx,-28(%ebp)
	andl	$15,%ebx
	shll	$4,%ebx
	addl	$8,%ebx
	movl	%ebx,-32(%ebp)
	movl	SBAR_SCOREBOARD_FRAGS_OFFSET(%eax),%ebx
	movl	%ebx,-16(%ebp)

	cmpl	$SBAR_GAME_DEATHMATCH,_cl+SBAR_CL_GAMETYPE_OFFSET
	jne	.Lsbar_face_team_wide
	movl	$113,%edi
	jmp	.Lsbar_face_team_positioned
.Lsbar_face_team_wide:
	movl	_vid+SBAR_VID_WIDTH_OFFSET,%edi
	subl	$320,%edi
	sarl	$1,%edi
	addl	$113,%edi
.Lsbar_face_team_positioned:

	pushl	_rsb_teambord
	pushl	$0
	pushl	$112
	call	SBAR_FACE_PIC
	addl	$12,%esp

	/* Draw_Fill(x, y, width, height, color); retain 16-byte call alignment. */
	subl	$8,%esp
	pushl	-28(%ebp)
	pushl	$9
	pushl	$22
	movl	_vid+SBAR_VID_HEIGHT_OFFSET,%eax
	subl	$21,%eax
	pushl	%eax
	pushl	%edi
	call	SBAR_FACE_FILL
	addl	$28,%esp

	subl	$8,%esp
	pushl	-32(%ebp)
	pushl	$9
	pushl	$22
	movl	_vid+SBAR_VID_HEIGHT_OFFSET,%eax
	subl	$12,%eax
	pushl	%eax
	pushl	%edi
	call	SBAR_FACE_FILL
	addl	$28,%esp

	/* Match sprintf("%3i"): left-pad short values and preserve long signs. */
	subl	$4,%esp
	leal	-44(%ebp),%eax
	pushl	%eax
	pushl	-16(%ebp)
	call	_Sbar_itoa
	addl	$12,%esp
	movl	%eax,-20(%ebp)
	movl	$0,-24(%ebp)
	cmpl	$3,%eax
	jge	.Lsbar_face_team_digits
	movl	$3,%ecx
	subl	%eax,%ecx
	movl	%ecx,-24(%ebp)
.Lsbar_face_team_digits:
	xorl	%ebx,%ebx
.Lsbar_face_team_digit_loop:
	movl	%ebx,%ecx
	cmpl	-24(%ebp),%ecx
	jl	.Lsbar_face_team_digit_space
	subl	-24(%ebp),%ecx
	movzbl	-44(%ebp,%ecx),%eax
	jmp	.Lsbar_face_team_digit_ready
.Lsbar_face_team_digit_space:
	movl	$' ',%eax
.Lsbar_face_team_digit_ready:
	cmpl	$8,-28(%ebp)
	jne	.Lsbar_face_team_digit_draw
	cmpl	$' ',%eax
	je	.Lsbar_face_team_digit_next
	addl	$18-'0',%eax
.Lsbar_face_team_digit_draw:
	leal	(%ebx,%ebx,2),%edx
	leal	109(%ebx,%edx,2),%edx
	pushl	%eax
	pushl	$3
	pushl	%edx
	call	SBAR_FACE_CHARACTER
	addl	$12,%esp
.Lsbar_face_team_digit_next:
	incl	%ebx
	cmpl	$3,%ebx
	jl	.Lsbar_face_team_digit_loop
	jmp	.Lsbar_face_return

.Lsbar_face_powerups:
	movl	_cl+SBAR_CL_ITEMS_OFFSET,%eax
	movl	%eax,%ecx
	andl	$(SBAR_IT_INVISIBILITY|SBAR_IT_INVULNERABILITY),%ecx
	cmpl	$(SBAR_IT_INVISIBILITY|SBAR_IT_INVULNERABILITY),%ecx
	je	.Lsbar_face_invis_invuln
	testl	$SBAR_IT_QUAD,%eax
	jne	.Lsbar_face_quad
	testl	$SBAR_IT_INVISIBILITY,%eax
	jne	.Lsbar_face_invis
	testl	$SBAR_IT_INVULNERABILITY,%eax
	jne	.Lsbar_face_invuln

	movl	_cl+SBAR_CL_STATS_OFFSET+(SBAR_STAT_HEALTH*4),%ebx
	cmpl	$100,%ebx
	jge	.Lsbar_face_health_max
	movl	%ebx,%eax
	cltd
	movl	$20,%ecx
	idivl	%ecx
	movl	%eax,%ebx
	jmp	.Lsbar_face_health_ready
.Lsbar_face_health_max:
	movl	$4,%ebx
.Lsbar_face_health_ready:
	fldl	_cl+SBAR_CL_TIME_OFFSET
	fcomps	_cl+SBAR_CL_FACEANIMTIME_OFFSET
	fnstsw	%ax
	sahf
	jp	.Lsbar_face_static
	ja	.Lsbar_face_static
	movl	$1,%edx
	movl	$0,_sb_updates
	jmp	.Lsbar_face_health_picture
.Lsbar_face_static:
	xorl	%edx,%edx
.Lsbar_face_health_picture:
	leal	(%ebx,%ebx),%ecx
	addl	%edx,%ecx
	movl	_sb_faces(,%ecx,4),%eax
	jmp	.Lsbar_face_draw_picture

.Lsbar_face_invis_invuln:
	movl	_sb_face_invis_invuln,%eax
	jmp	.Lsbar_face_draw_picture
.Lsbar_face_quad:
	movl	_sb_face_quad,%eax
	jmp	.Lsbar_face_draw_picture
.Lsbar_face_invis:
	movl	_sb_face_invis,%eax
	jmp	.Lsbar_face_draw_picture
.Lsbar_face_invuln:
	movl	_sb_face_invuln,%eax
.Lsbar_face_draw_picture:
	pushl	%eax
	pushl	$0
	pushl	$112
	call	SBAR_FACE_PIC
	addl	$12,%esp

.Lsbar_face_return:
	leal	-12(%ebp),%esp
	popl	%edi
	popl	%esi
	popl	%ebx
	popl	%ebp
	ret

.section .rodata
.p2align 2
.Lsbar_face_teamplay_three:
	.float	3.0
.Lsbar_face_teamplay_seven:
	.float	7.0
.text

#undef SBAR_DRAW_TILE_CLEAR
#undef SBAR_DRAW_INVENTORY
#undef SBAR_DRAW_FRAGS
#undef SBAR_DRAW_PIC
#undef SBAR_DRAW_SCOREBOARD
#undef SBAR_DRAW_NUM
#undef SBAR_DRAW_FACE
#undef SBAR_DRAW_MINI_DEATHMATCH
#undef SBAR_FACE_PIC
#undef SBAR_FACE_CHARACTER
#undef SBAR_FACE_FILL
#undef SBAR_CALL_PIC
#undef SBAR_CALL_NUM
