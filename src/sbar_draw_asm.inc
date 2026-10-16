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
#else
#define SBAR_DRAW_TILE_CLEAR _Draw_TileClear
#define SBAR_DRAW_INVENTORY _Sbar_DrawInventory
#define SBAR_DRAW_FRAGS _Sbar_DrawFrags
#define SBAR_DRAW_PIC _Sbar_DrawPic
#define SBAR_DRAW_SCOREBOARD _Sbar_DrawScoreboard
#define SBAR_DRAW_NUM _Sbar_DrawNum
#define SBAR_DRAW_FACE _Sbar_DrawFace
#define SBAR_DRAW_MINI_DEATHMATCH _Sbar_MiniDeathmatchOverlay
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

#undef SBAR_DRAW_TILE_CLEAR
#undef SBAR_DRAW_INVENTORY
#undef SBAR_DRAW_FRAGS
#undef SBAR_DRAW_PIC
#undef SBAR_DRAW_SCOREBOARD
#undef SBAR_DRAW_NUM
#undef SBAR_DRAW_FACE
#undef SBAR_DRAW_MINI_DEATHMATCH
#undef SBAR_CALL_PIC
#undef SBAR_CALL_NUM
