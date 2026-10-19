// SCR_UpdateScreen overlay decision block, split out without changing branch
// order or the order of visible subsystem calls.
#include "asm_i386.h"
#include "asm_menutext.h"
#include "asm_screenoverlays.h"
#include "asm_vidmenu.h"

#if defined(ASM486_SCREEN_OVERLAYS)
.arch i486
.arch .387
.code32

.macro SCREEN_OVERLAY_CALL event, target
#ifdef BENCH486
	cmpl	$0,C(bench486_screen_overlays_fixture_active)
	je	.Lso_real_\@
	pushl	$\event
	call	C(Bench486ScreenOverlaysRecordCall)
	addl	$4,%esp
	jmp	.Lso_done_\@
.Lso_real_\@:
	call	\target
.Lso_done_\@:
#else
	call	\target
#endif
.endm

.text
.p2align 2
.globl C(M_DrawCharacter)
C(M_DrawCharacter):
	pushl	%ebx
	movl	8(%esp),%eax		/* cx */
	movl	C(vid)+MT_VID_WIDTH_OFFSET,%ebx
	subl	$320,%ebx
	shrl	$1,%ebx
	addl	%ebx,%eax
	movl	12(%esp),%ecx		/* line */
	movl	16(%esp),%edx		/* character */
	pushl	%edx
	pushl	%ecx
	pushl	%eax
#ifdef BENCH486
	call	C(Bench486MenuTextDrawCharacter)
#else
	call	C(Draw_Character)
#endif
	addl	$12,%esp
	popl	%ebx
	ret

.p2align 2
.globl C(M_Print)
C(M_Print):
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	movl	16(%esp),%ebx		/* cx */
	movl	20(%esp),%esi		/* cy */
	movl	24(%esp),%edi		/* str */
	movl	C(vid)+MT_VID_WIDTH_OFFSET,%eax
	subl	$320,%eax
	shrl	$1,%eax
	addl	%eax,%ebx			/* center once for the whole string */

.Lm_print_loop:
	movsbl	(%edi),%eax
	testl	%eax,%eax
	je	.Lm_print_done
	addl	$128,%eax
	pushl	%eax
	pushl	%esi
	pushl	%ebx
#ifdef BENCH486
	call	C(Bench486MenuTextDrawCharacter)
#else
	call	C(Draw_Character)
#endif
	addl	$12,%esp
	addl	$8,%ebx
	incl	%edi
	jmp	.Lm_print_loop

.Lm_print_done:
	popl	%edi
	popl	%esi
	popl	%ebx
	ret

.p2align 2
.globl C(M_PrintWhite)
C(M_PrintWhite):
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	movl	16(%esp),%ebx		/* cx */
	movl	20(%esp),%esi		/* cy */
	movl	24(%esp),%edi		/* str */
	movl	C(vid)+MT_VID_WIDTH_OFFSET,%eax
	subl	$320,%eax
	shrl	$1,%eax
	addl	%eax,%ebx			/* center once for the whole string */

.Lm_print_white_loop:
	movsbl	(%edi),%eax
	testl	%eax,%eax
	je	.Lm_print_white_done
	pushl	%eax
	pushl	%esi
	pushl	%ebx
#ifdef BENCH486
	call	C(Bench486MenuTextDrawCharacter)
#else
	call	C(Draw_Character)
#endif
	addl	$12,%esp
	addl	$8,%ebx
	incl	%edi
	jmp	.Lm_print_white_loop

.Lm_print_white_done:
	popl	%edi
	popl	%esi
	popl	%ebx
	ret

/* M_DrawTextBox: preserve the original cache/draw order and tile loops. */
.macro MENU_TEXTBOX_CACHE path
	subl	$12,%esp
	pushl	$\path
#ifdef BENCH486
	call	C(Bench486MenuTextCachePic)
#else
	call	C(Draw_CachePic)
#endif
	addl	$16,%esp
	movl	%eax,-36(%ebp)
.endm

.macro MENU_TEXTBOX_DRAW yoffset
	movl	-20(%ebp),%eax
	addl	$\yoffset,%eax
	pushl	-36(%ebp)
	pushl	%eax
	pushl	-16(%ebp)
	call	C(M_DrawTransPic)
	addl	$12,%esp
.endm

.p2align 2
.globl C(M_DrawTextBox)
C(M_DrawTextBox):
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	subl	$24,%esp
	movl	8(%ebp),%eax		/* x */
	movl	%eax,-16(%ebp)		/* cx */
	movl	12(%ebp),%eax		/* y */
	movl	%eax,-20(%ebp)		/* cy */
	movl	16(%ebp),%eax		/* width */
	movl	%eax,-24(%ebp)
	movl	20(%ebp),%eax		/* lines */
	movl	%eax,-28(%ebp)

	/* Draw left side. */
	MENU_TEXTBOX_CACHE .Lmenu_box_tl
	MENU_TEXTBOX_DRAW 0
	MENU_TEXTBOX_CACHE .Lmenu_box_ml
	movl	$0,-32(%ebp)
.Lm_textbox_left_loop:
	movl	-32(%ebp),%eax
	cmpl	-28(%ebp),%eax
	jge	.Lm_textbox_left_done
	addl	$8,-20(%ebp)
	MENU_TEXTBOX_DRAW 0
	incl	-32(%ebp)
	jmp	.Lm_textbox_left_loop
.Lm_textbox_left_done:
	MENU_TEXTBOX_CACHE .Lmenu_box_bl
	MENU_TEXTBOX_DRAW 8

	/* Draw center tiles, using box_mm2 from the second interior row onward. */
	addl	$8,-16(%ebp)
.Lm_textbox_middle_loop:
	cmpl	$0,-24(%ebp)
	jle	.Lm_textbox_middle_done
	movl	12(%ebp),%eax
	movl	%eax,-20(%ebp)
	MENU_TEXTBOX_CACHE .Lmenu_box_tm
	MENU_TEXTBOX_DRAW 0
	MENU_TEXTBOX_CACHE .Lmenu_box_mm
	movl	$0,-32(%ebp)
.Lm_textbox_middle_row_loop:
	movl	-32(%ebp),%eax
	cmpl	-28(%ebp),%eax
	jge	.Lm_textbox_middle_rows_done
	addl	$8,-20(%ebp)
	cmpl	$1,-32(%ebp)
	jne	.Lm_textbox_middle_draw
	MENU_TEXTBOX_CACHE .Lmenu_box_mm2
.Lm_textbox_middle_draw:
	MENU_TEXTBOX_DRAW 0
	incl	-32(%ebp)
	jmp	.Lm_textbox_middle_row_loop
.Lm_textbox_middle_rows_done:
	MENU_TEXTBOX_CACHE .Lmenu_box_bm
	MENU_TEXTBOX_DRAW 8
	subl	$2,-24(%ebp)
	addl	$16,-16(%ebp)
	jmp	.Lm_textbox_middle_loop
.Lm_textbox_middle_done:

	/* Draw right side. */
	movl	12(%ebp),%eax
	movl	%eax,-20(%ebp)
	MENU_TEXTBOX_CACHE .Lmenu_box_tr
	MENU_TEXTBOX_DRAW 0
	MENU_TEXTBOX_CACHE .Lmenu_box_mr
	movl	$0,-32(%ebp)
.Lm_textbox_right_loop:
	movl	-32(%ebp),%eax
	cmpl	-28(%ebp),%eax
	jge	.Lm_textbox_right_done
	addl	$8,-20(%ebp)
	MENU_TEXTBOX_DRAW 0
	incl	-32(%ebp)
	jmp	.Lm_textbox_right_loop
.Lm_textbox_right_done:
	MENU_TEXTBOX_CACHE .Lmenu_box_br
	MENU_TEXTBOX_DRAW 8

	leal	-12(%ebp),%esp
	popl	%edi
	popl	%esi
	popl	%ebx
	popl	%ebp
	ret

.purgem MENU_TEXTBOX_CACHE
.purgem MENU_TEXTBOX_DRAW

/* M_Draw owns menu frame setup, state dispatch and final update calls. */
.macro MENU_DISPATCH_EFFECT event, target
#ifdef BENCH486
	cmpl	$0,C(bench486_menu_dispatch_fixture_active)
	je	.Lmd_effect_real_\@
	pushl	$0
	pushl	$\event
	call	C(Bench486MenuDispatchRecord)
	addl	$8,%esp
	jmp	.Lmd_effect_done_\@
.Lmd_effect_real_\@:
#endif
	call	C(\target)
.Lmd_effect_done_\@:
.endm

.macro MENU_DISPATCH_CONSOLE_BACKGROUND
	movl	C(vid)+MT_VID_HEIGHT_OFFSET,%eax
#ifdef BENCH486
	cmpl	$0,C(bench486_menu_dispatch_fixture_active)
	je	.Lmd_console_real_\@
	pushl	%eax
	pushl	$MD_EVENT_CONSOLE_BACKGROUND
	call	C(Bench486MenuDispatchRecord)
	addl	$8,%esp
	jmp	.Lmd_console_done_\@
.Lmd_console_real_\@:
#endif
	pushl	%eax
	call	C(Draw_ConsoleBackground)
	addl	$4,%esp
.Lmd_console_done_\@:
.endm

.macro MENU_DISPATCH_DRAW event, target
#ifdef BENCH486
	cmpl	$0,C(bench486_menu_dispatch_fixture_active)
	je	.Lmd_draw_real_\@
	pushl	$0
	pushl	$\event
	call	C(Bench486MenuDispatchRecord)
	addl	$8,%esp
	jmp	.Lmd_draw_done_\@
.Lmd_draw_real_\@:
#endif
	call	C(\target)
.Lmd_draw_done_\@:
	jmp	.Lmd_after_dispatch
.endm

.macro MENU_DISPATCH_SOUND
#ifdef BENCH486
	cmpl	$0,C(bench486_menu_dispatch_fixture_active)
	je	.Lmd_sound_real_\@
	subl	$12,%esp
	pushl	$.Lmenu_dispatch_sound
	call	C(Bench486MenuDispatchSound)
	addl	$16,%esp
	jmp	.Lmd_sound_done_\@
.Lmd_sound_real_\@:
#endif
	subl	$12,%esp
	pushl	$.Lmenu_dispatch_sound
	call	C(S_LocalSound)
	addl	$16,%esp
.Lmd_sound_done_\@:
.endm

.p2align 2
.globl C(M_Draw)
C(M_Draw):
	pushl	%ebp
	movl	%esp,%ebp
	cmpl	$MD_STATE_NONE,C(m_state)
	je	.Lmd_return
	cmpl	$MD_KEY_MENU,C(key_dest)
	jne	.Lmd_return
	cmpl	$0,C(m_recursiveDraw)
	jne	.Lmd_recursive
	movl	$1,C(scr_copyeverything)
	movl	C(scr_con_current),%eax
	andl	$0x7fffffff,%eax
	testl	%eax,%eax
	je	.Lmd_fade_screen
	/* DJGPP's C oracle treats unordered x87 comparisons like zero. */
	movl	%eax,%edx
	andl	$0x7f800000,%edx
	cmpl	$0x7f800000,%edx
	jne	.Lmd_console_visible
	andl	$0x007fffff,%eax
	jne	.Lmd_fade_screen
.Lmd_console_visible:
	MENU_DISPATCH_CONSOLE_BACKGROUND
	MENU_DISPATCH_EFFECT MD_EVENT_EXTRA_UPDATE,S_ExtraUpdate
	jmp	.Lmd_background_done
.Lmd_fade_screen:
	MENU_DISPATCH_EFFECT MD_EVENT_FADE_SCREEN,Draw_FadeScreen
.Lmd_background_done:
	movl	$0,C(scr_fullupdate)
	jmp	.Lmd_state_dispatch
.Lmd_recursive:
	movl	$0,C(m_recursiveDraw)

.Lmd_state_dispatch:
	movl	C(m_state),%eax
	cmpl	$MD_STATE_LAST,%eax
	ja	.Lmd_after_dispatch
	jmp	*.Lmenu_dispatch_states(,%eax,4)

.Lmd_state_none:
	jmp	.Lmd_after_dispatch
.Lmd_state_main:
	MENU_DISPATCH_DRAW (MD_EVENT_DRAW_BASE+MD_STATE_MAIN),M_Main_Draw
.Lmd_state_singleplayer:
	MENU_DISPATCH_DRAW (MD_EVENT_DRAW_BASE+MD_STATE_SINGLEPLAYER),M_SinglePlayer_Draw
.Lmd_state_load:
	MENU_DISPATCH_DRAW (MD_EVENT_DRAW_BASE+MD_STATE_LOAD),M_Load_Draw
.Lmd_state_save:
	MENU_DISPATCH_DRAW (MD_EVENT_DRAW_BASE+MD_STATE_SAVE),M_Save_Draw
.Lmd_state_multiplayer:
	MENU_DISPATCH_DRAW (MD_EVENT_DRAW_BASE+MD_STATE_MULTIPLAYER),M_MultiPlayer_Draw
.Lmd_state_setup:
	MENU_DISPATCH_DRAW (MD_EVENT_DRAW_BASE+MD_STATE_SETUP),M_Setup_Draw
.Lmd_state_net:
	MENU_DISPATCH_DRAW (MD_EVENT_DRAW_BASE+MD_STATE_NET),M_Net_Draw
.Lmd_state_options:
	MENU_DISPATCH_DRAW (MD_EVENT_DRAW_BASE+MD_STATE_OPTIONS),M_Options_Draw
.Lmd_state_video:
	MENU_DISPATCH_DRAW (MD_EVENT_DRAW_BASE+MD_STATE_VIDEO),M_Video_Draw
.Lmd_state_keys:
	MENU_DISPATCH_DRAW (MD_EVENT_DRAW_BASE+MD_STATE_KEYS),M_Keys_Draw
.Lmd_state_help:
	MENU_DISPATCH_DRAW (MD_EVENT_DRAW_BASE+MD_STATE_HELP),M_Help_Draw
.Lmd_state_quit:
	MENU_DISPATCH_DRAW (MD_EVENT_DRAW_BASE+MD_STATE_QUIT),M_Quit_Draw
.Lmd_state_serialconfig:
	MENU_DISPATCH_DRAW (MD_EVENT_DRAW_BASE+MD_STATE_SERIALCONFIG),M_SerialConfig_Draw
.Lmd_state_modemconfig:
	MENU_DISPATCH_DRAW (MD_EVENT_DRAW_BASE+MD_STATE_MODEMCONFIG),M_ModemConfig_Draw
.Lmd_state_lanconfig:
	MENU_DISPATCH_DRAW (MD_EVENT_DRAW_BASE+MD_STATE_LANCONFIG),M_LanConfig_Draw
.Lmd_state_gameoptions:
	MENU_DISPATCH_DRAW (MD_EVENT_DRAW_BASE+MD_STATE_GAMEOPTIONS),M_GameOptions_Draw
.Lmd_state_search:
	MENU_DISPATCH_DRAW (MD_EVENT_DRAW_BASE+MD_STATE_SEARCH),M_Search_Draw
.Lmd_state_serverlist:
	MENU_DISPATCH_DRAW (MD_EVENT_DRAW_BASE+MD_STATE_SERVERLIST),M_ServerList_Draw

.Lmd_after_dispatch:
	cmpl	$0,C(m_entersound)
	je	.Lmd_final_update
	MENU_DISPATCH_SOUND
	movl	$0,C(m_entersound)
.Lmd_final_update:
	MENU_DISPATCH_EFFECT MD_EVENT_EXTRA_UPDATE,S_ExtraUpdate
.Lmd_return:
	leave
	ret

.purgem MENU_DISPATCH_EFFECT
.purgem MENU_DISPATCH_CONSOLE_BACKGROUND
.purgem MENU_DISPATCH_DRAW
.purgem MENU_DISPATCH_SOUND

/* Main and single-player menu pages share the same animated picture layout. */
.macro MENU_PAGE_CACHE source
	subl	$12,%esp
	pushl	\source
#ifdef BENCH486
	call	C(Bench486MenuTextCachePic)
#else
	call	C(Draw_CachePic)
#endif
	addl	$16,%esp
.endm

.p2align 2
.globl C(M_Main_Draw)
C(M_Main_Draw):
	pushl	C(m_main_cursor)
	pushl	$.Lmenu_main_content
	pushl	$.Lmenu_main_title
	call	.Lmenu_page_draw
	addl	$12,%esp
	ret

.p2align 2
.globl C(M_SinglePlayer_Draw)
C(M_SinglePlayer_Draw):
	pushl	C(m_singleplayer_cursor)
	pushl	$.Lmenu_singleplayer_content
	pushl	$.Lmenu_singleplayer_title
	call	.Lmenu_page_draw
	addl	$12,%esp
	ret

.p2align 2
.globl C(M_MultiPlayer_Draw)
C(M_MultiPlayer_Draw):
	pushl	C(m_multiplayer_cursor)
	pushl	$.Lmenu_multi_content
	pushl	$.Lmenu_multi_title
	call	.Lmenu_page_draw
	addl	$12,%esp
	cmpl	$0,C(serialAvailable)
	jne	.Lmenu_multi_done
	cmpl	$0,C(ipxAvailable)
	jne	.Lmenu_multi_done
	cmpl	$0,C(tcpipAvailable)
	jne	.Lmenu_multi_done
	pushl	$.Lmenu_no_communications
	pushl	$148
	pushl	$52
	call	C(M_PrintWhite)
	addl	$12,%esp
.Lmenu_multi_done:
	ret

.p2align 2
.Lmenu_page_draw:
	pushl	%ebp
	movl	%esp,%ebp
	subl	$40,%esp

	MENU_PAGE_CACHE $.Lmenu_plaque
	movl	%eax,-12(%ebp)
	subl	$4,%esp
	pushl	-12(%ebp)
	pushl	$4
	pushl	$16
	call	C(M_DrawTransPic)
	addl	$16,%esp

	MENU_PAGE_CACHE 8(%ebp)
	movl	%eax,-16(%ebp)
	movl	$320,%edx
	subl	(%eax),%edx
	movl	%edx,%eax
	shrl	$31,%eax
	addl	%edx,%eax
	sarl	$1,%eax
	movl	%eax,-20(%ebp)
	subl	$4,%esp
	pushl	-16(%ebp)
	pushl	$4
	pushl	-20(%ebp)
	call	C(M_DrawPic)
	addl	$16,%esp

	MENU_PAGE_CACHE 12(%ebp)
	movl	%eax,-24(%ebp)
	subl	$4,%esp
	pushl	-24(%ebp)
	pushl	$32
	pushl	$72
	call	C(M_DrawTransPic)
	addl	$16,%esp

	/* Match the C compiler's temporary round-toward-zero x87 conversion. */
	flds	.Lmenu_page_ten
	fmull	C(host_time)
	fnstcw	-2(%ebp)
	movw	-2(%ebp),%dx
	orb	$12,%dh
	movw	%dx,-4(%ebp)
	fldcw	-4(%ebp)
	fistpl	-8(%ebp)
	fldcw	-2(%ebp)
	movl	-8(%ebp),%eax
	cltd
	movl	$6,%ecx
	idivl	%ecx
	movl	%edx,%ecx
	incl	%ecx

	subl	$8,%esp
	pushl	%ecx
	pushl	$.Lmenu_dot_format
	call	C(va)
	addl	$16,%esp
	MENU_PAGE_CACHE %eax
	movl	%eax,-28(%ebp)
	movl	16(%ebp),%ecx
	leal	(%ecx,%ecx,4),%edx
	leal	32(,%edx,4),%eax
	subl	$4,%esp
	pushl	-28(%ebp)
	pushl	%eax
	pushl	$54
	call	C(M_DrawTransPic)
	addl	$16,%esp
	leave
	ret

.p2align 2
.globl C(M_Net_Draw)
C(M_Net_Draw):
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	subl	$16,%esp

	MENU_PAGE_CACHE $.Lmenu_plaque
	subl	$4,%esp
	pushl	%eax
	pushl	$4
	pushl	$16
	call	C(M_DrawTransPic)
	addl	$16,%esp

	MENU_PAGE_CACHE $.Lmenu_multi_title
	movl	%eax,-16(%ebp)
	movl	$320,%edx
	subl	(%eax),%edx
	movl	%edx,%eax
	shrl	$31,%eax
	addl	%edx,%eax
	sarl	$1,%eax
	subl	$4,%esp
	pushl	-16(%ebp)
	pushl	$4
	pushl	%eax
	call	C(M_DrawPic)
	addl	$16,%esp

	cmpl	$0,C(serialAvailable)
	je	.Lmenu_net_dim_modem
	MENU_PAGE_CACHE $.Lmenu_net_modem
	jmp	.Lmenu_net_row_modem
.Lmenu_net_dim_modem:
	MENU_PAGE_CACHE $.Lmenu_net_dim_modem_pic
.Lmenu_net_row_modem:
	testl	%eax,%eax
	je	.Lmenu_net_direct
	subl	$4,%esp
	pushl	%eax
	pushl	$32
	pushl	$72
	call	C(M_DrawTransPic)
	addl	$16,%esp

.Lmenu_net_direct:
	cmpl	$0,C(serialAvailable)
	je	.Lmenu_net_dim_direct
	MENU_PAGE_CACHE $.Lmenu_net_direct_path
	jmp	.Lmenu_net_row_direct
.Lmenu_net_dim_direct:
	MENU_PAGE_CACHE $.Lmenu_net_dim_direct_path
.Lmenu_net_row_direct:
	testl	%eax,%eax
	je	.Lmenu_net_ipx
	subl	$4,%esp
	pushl	%eax
	pushl	$51
	pushl	$72
	call	C(M_DrawTransPic)
	addl	$16,%esp

.Lmenu_net_ipx:
	cmpl	$0,C(ipxAvailable)
	je	.Lmenu_net_dim_ipx
	MENU_PAGE_CACHE $.Lmenu_net_ipx_path
	jmp	.Lmenu_net_row_ipx
.Lmenu_net_dim_ipx:
	MENU_PAGE_CACHE $.Lmenu_net_dim_ipx_path
.Lmenu_net_row_ipx:
	subl	$4,%esp
	pushl	%eax
	pushl	$70
	pushl	$72
	call	C(M_DrawTransPic)
	addl	$16,%esp

	cmpl	$0,C(tcpipAvailable)
	je	.Lmenu_net_dim_tcpip
	MENU_PAGE_CACHE $.Lmenu_net_tcpip_path
	jmp	.Lmenu_net_row_tcpip
.Lmenu_net_dim_tcpip:
	MENU_PAGE_CACHE $.Lmenu_net_dim_tcpip_path
.Lmenu_net_row_tcpip:
	subl	$4,%esp
	pushl	%eax
	pushl	$89
	pushl	$72
	call	C(M_DrawTransPic)
	addl	$16,%esp

	cmpl	$5,C(m_net_items)
	jne	.Lmenu_net_help_box
	MENU_PAGE_CACHE $.Lmenu_net_fifth
	subl	$4,%esp
	pushl	%eax
	pushl	$108
	pushl	$72
	call	C(M_DrawTransPic)
	addl	$16,%esp

.Lmenu_net_help_box:
	pushl	$4
	pushl	$24
	pushl	$134
	pushl	$56
	call	C(M_DrawTextBox)
	addl	$16,%esp

	movl	C(m_net_cursor),%eax
	shll	$4,%eax
	movl	$C(net_helpMessage),%esi
	addl	%eax,%esi
	xorl	%ebx,%ebx
.Lmenu_net_help_lines:
	pushl	(%esi)
	leal	142(,%ebx,8),%eax
	pushl	%eax
	pushl	$64
	call	C(M_Print)
	addl	$12,%esp
	addl	$4,%esi
	incl	%ebx
	cmpl	$4,%ebx
	jl	.Lmenu_net_help_lines

	flds	.Lmenu_page_ten
	fmull	C(host_time)
	fnstcw	-18(%ebp)
	movw	-18(%ebp),%dx
	orb	$12,%dh
	movw	%dx,-20(%ebp)
	fldcw	-20(%ebp)
	fistpl	-24(%ebp)
	fldcw	-18(%ebp)
	movl	-24(%ebp),%eax
	cltd
	movl	$6,%ecx
	idivl	%ecx
	incl	%edx
	pushl	%edx
	pushl	$.Lmenu_dot_format
	call	C(va)
	addl	$8,%esp
	MENU_PAGE_CACHE %eax
	movl	C(m_net_cursor),%edx
	leal	(%edx,%edx,4),%edx
	shll	$2,%edx
	addl	$32,%edx
	subl	$4,%esp
	pushl	%eax
	pushl	%edx
	pushl	$54
	call	C(M_DrawTransPic)
	addl	$16,%esp

	addl	$16,%esp
	popl	%edi
	popl	%esi
	popl	%ebx
	leave
	ret

.p2align 2
.globl C(M_ModemConfig_Draw)
C(M_ModemConfig_Draw):
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	subl	$24,%esp

	/* Plaque and title use the same centered picture wrappers as the C path. */
	MENU_PAGE_CACHE $.Lmenu_plaque
	subl	$4,%esp
	pushl	%eax
	pushl	$4
	pushl	$16
	call	C(M_DrawTransPic)
	addl	$16,%esp

	MENU_PAGE_CACHE $.Lmenu_multi_title
	movl	%eax,-20(%ebp)
	movl	$320,%edx
	subl	(%eax),%edx
	movl	%edx,%eax
	shrl	$31,%eax
	addl	%edx,%eax
	sarl	$1,%eax
	movl	%eax,-16(%ebp)
	subl	$4,%esp
	pushl	-20(%ebp)
	pushl	$4
	pushl	%eax
	call	C(M_DrawPic)
	addl	$16,%esp

	/* int(realtime * 4) has C cast semantics: truncate, then restore CW. */
	fldl	C(realtime)
	fmull	.Lmenu_modem_four
	fnstcw	-26(%ebp)
	movw	-26(%ebp),%dx
	orb	$12,%dh
	movw	%dx,-28(%ebp)
	fldcw	-28(%ebp)
	fistpl	-32(%ebp)
	fldcw	-26(%ebp)
	movl	-32(%ebp),%eax
	andl	$1,%eax
	movl	%eax,-24(%ebp)

	/* Dialing mode. */
	movl	-16(%ebp),%ebx
	addl	$8,%ebx
	cmpb	$80,C(modemConfig_dialing)
	jne	.Lmenu_modem_touch_tone
	pushl	$.Lmenu_modem_pulse
	jmp	.Lmenu_modem_dial_label
.Lmenu_modem_touch_tone:
	pushl	$.Lmenu_modem_touch
.Lmenu_modem_dial_label:
	pushl	C(modemConfig_cursor_table)
	pushl	%ebx
	call	C(M_Print)
	addl	$12,%esp

	/* Clear field. */
	movl	-16(%ebp),%ebx
	addl	$8,%ebx
	pushl	$.Lmenu_modem_clear
	pushl	C(modemConfig_cursor_table)+4
	pushl	%ebx
	call	C(M_Print)
	addl	$12,%esp
	movl	C(modemConfig_cursor_table)+4,%eax
	addl	$4,%eax
	pushl	$1
	pushl	$16
	pushl	%eax
	movl	%ebx,%eax
	pushl	%eax
	call	C(M_DrawTextBox)
	addl	$16,%esp
	movl	-16(%ebp),%ebx
	addl	$16,%ebx
	movl	C(modemConfig_cursor_table)+4,%eax
	addl	$12,%eax
	pushl	$C(modemConfig_clear)
	pushl	%eax
	pushl	%ebx
	call	C(M_Print)
	addl	$12,%esp
	cmpl	$1,C(modemConfig_cursor)
	jne	.Lmenu_modem_init
	subl	$12,%esp
	pushl	$C(modemConfig_clear)
	call	C(strlen)
	addl	$16,%esp
	shll	$3,%eax
	leal	(%ebx,%eax),%eax
	movl	-24(%ebp),%ecx
	addl	$10,%ecx
	pushl	%ecx
	movl	C(modemConfig_cursor_table)+4,%edx
	addl	$12,%edx
	pushl	%edx
	pushl	%eax
	call	C(M_DrawCharacter)
	addl	$12,%esp

.Lmenu_modem_init:
	movl	-16(%ebp),%ebx
	addl	$8,%ebx
	pushl	$.Lmenu_modem_init_label
	pushl	C(modemConfig_cursor_table)+8
	pushl	%ebx
	call	C(M_Print)
	addl	$12,%esp
	movl	C(modemConfig_cursor_table)+8,%eax
	addl	$4,%eax
	pushl	$1
	pushl	$30
	pushl	%eax
	movl	%ebx,%eax
	pushl	%eax
	call	C(M_DrawTextBox)
	addl	$16,%esp
	movl	-16(%ebp),%ebx
	addl	$16,%ebx
	movl	C(modemConfig_cursor_table)+8,%eax
	addl	$12,%eax
	pushl	$C(modemConfig_init)
	pushl	%eax
	pushl	%ebx
	call	C(M_Print)
	addl	$12,%esp
	cmpl	$2,C(modemConfig_cursor)
	jne	.Lmenu_modem_hangup
	subl	$12,%esp
	pushl	$C(modemConfig_init)
	call	C(strlen)
	addl	$16,%esp
	shll	$3,%eax
	leal	(%ebx,%eax),%eax
	movl	-24(%ebp),%ecx
	addl	$10,%ecx
	pushl	%ecx
	movl	C(modemConfig_cursor_table)+8,%edx
	addl	$12,%edx
	pushl	%edx
	pushl	%eax
	call	C(M_DrawCharacter)
	addl	$12,%esp

.Lmenu_modem_hangup:
	movl	-16(%ebp),%ebx
	addl	$8,%ebx
	pushl	$.Lmenu_modem_hangup_label
	pushl	C(modemConfig_cursor_table)+12
	pushl	%ebx
	call	C(M_Print)
	addl	$12,%esp
	movl	C(modemConfig_cursor_table)+12,%eax
	addl	$4,%eax
	pushl	$1
	pushl	$16
	pushl	%eax
	movl	%ebx,%eax
	pushl	%eax
	call	C(M_DrawTextBox)
	addl	$16,%esp
	movl	-16(%ebp),%ebx
	addl	$16,%ebx
	movl	C(modemConfig_cursor_table)+12,%eax
	addl	$12,%eax
	pushl	$C(modemConfig_hangup)
	pushl	%eax
	pushl	%ebx
	call	C(M_Print)
	addl	$12,%esp
	cmpl	$3,C(modemConfig_cursor)
	jne	.Lmenu_modem_ok
	subl	$12,%esp
	pushl	$C(modemConfig_hangup)
	call	C(strlen)
	addl	$16,%esp
	shll	$3,%eax
	leal	(%ebx,%eax),%eax
	movl	-24(%ebp),%ecx
	addl	$10,%ecx
	pushl	%ecx
	movl	C(modemConfig_cursor_table)+12,%edx
	addl	$12,%edx
	pushl	%edx
	pushl	%eax
	call	C(M_DrawCharacter)
	addl	$12,%esp

.Lmenu_modem_ok:
	movl	-16(%ebp),%ebx
	addl	$8,%ebx
	movl	C(modemConfig_cursor_table)+16,%eax
	subl	$8,%eax
	pushl	$1
	pushl	$2
	pushl	%eax
	pushl	%ebx
	call	C(M_DrawTextBox)
	addl	$16,%esp
	movl	C(modemConfig_cursor_table)+16,%eax
	pushl	$.Lmenu_modem_ok_label
	pushl	%eax
	addl	$8,%ebx
	pushl	%ebx
	call	C(M_Print)
	addl	$12,%esp

	/* Final menu cursor, indexed by the selected field. */
	movl	-24(%ebp),%eax
	addl	$12,%eax
	pushl	%eax
	movl	C(modemConfig_cursor),%edx
	movl	C(modemConfig_cursor_table)(,%edx,4),%eax
	pushl	%eax
	movl	-16(%ebp),%eax
	pushl	%eax
	call	C(M_DrawCharacter)
	addl	$12,%esp

	leal	-12(%ebp),%esp
	popl	%edi
	popl	%esi
	popl	%ebx
	popl	%ebp
	ret

.p2align 2
.globl C(M_LanConfig_Draw)
C(M_LanConfig_Draw):
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	subl	$24,%esp

	/* The plaque and title keep the same cache and draw ordering as C. */
	MENU_PAGE_CACHE $.Lmenu_plaque
	subl	$4,%esp
	pushl	%eax
	pushl	$4
	pushl	$16
	call	C(M_DrawTransPic)
	addl	$16,%esp

	MENU_PAGE_CACHE $.Lmenu_multi_title
	movl	%eax,-16(%ebp)
	movl	$320,%edx
	subl	(%eax),%edx
	movl	%edx,%eax
	shrl	$31,%eax
	addl	%edx,%eax
	sarl	$1,%eax
	movl	%eax,-20(%ebp)
	subl	$4,%esp
	pushl	-16(%ebp)
	pushl	$4
	pushl	%eax
	call	C(M_DrawPic)
	addl	$16,%esp

	/* Build the same formatted title string as va("%s - %s", ...). */
	cmpl	$1,C(m_multiplayer_cursor)
	jne	.Lmenu_lanconfig_join_title
	movl	$.Lmenu_lanconfig_new_game,%esi
	jmp	.Lmenu_lanconfig_protocol
.Lmenu_lanconfig_join_title:
	movl	$.Lmenu_lanconfig_join_game,%esi
.Lmenu_lanconfig_protocol:
	cmpl	$2,C(m_net_cursor)
	jne	.Lmenu_lanconfig_tcp_title
	pushl	$.Lmenu_lanconfig_ipx
	jmp	.Lmenu_lanconfig_format_title
.Lmenu_lanconfig_tcp_title:
	pushl	$.Lmenu_lanconfig_tcpip
.Lmenu_lanconfig_format_title:
	pushl	%esi
	pushl	$.Lmenu_lanconfig_title_format
	call	C(va)
	addl	$12,%esp
	movl	-20(%ebp),%ebx
	pushl	%eax
	pushl	$32
	pushl	%ebx
	call	C(M_Print)
	addl	$12,%esp
	addl	$8,%ebx
	movl	%ebx,-20(%ebp)

	/* Address label and the selected network address. */
	pushl	$.Lmenu_lanconfig_address
	pushl	$52
	pushl	%ebx
	call	C(M_Print)
	addl	$12,%esp
	cmpl	$2,C(m_net_cursor)
	jne	.Lmenu_lanconfig_tcp_address
	movl	$C(my_ipx_address),%esi
	jmp	.Lmenu_lanconfig_print_address
.Lmenu_lanconfig_tcp_address:
	movl	$C(my_tcpip_address),%esi
.Lmenu_lanconfig_print_address:
	pushl	%esi
	pushl	$52
	leal	72(%ebx),%eax
	pushl	%eax
	call	C(M_Print)
	addl	$12,%esp

	/* Port label, textbox, and editable port value. */
	pushl	$.Lmenu_lanconfig_port
	pushl	C(lanConfig_cursor_table)
	pushl	%ebx
	call	C(M_Print)
	addl	$12,%esp
	movl	C(lanConfig_cursor_table),%eax
	subl	$8,%eax
	pushl	$1
	pushl	$6
	pushl	%eax
	leal	64(%ebx),%eax
	pushl	%eax
	call	C(M_DrawTextBox)
	addl	$16,%esp
	pushl	$C(lanConfig_portname)
	pushl	C(lanConfig_cursor_table)
	leal	72(%ebx),%eax
	pushl	%eax
	call	C(M_Print)
	addl	$12,%esp

	/* The join form and the start form have different second fields. */
	cmpl	$0,C(m_multiplayer_cursor)
	jne	.Lmenu_lanconfig_start_form
	pushl	$.Lmenu_lanconfig_search
	pushl	C(lanConfig_cursor_table)+4
	pushl	%ebx
	call	C(M_Print)
	addl	$12,%esp
	pushl	$.Lmenu_lanconfig_join_at
	pushl	$108
	pushl	%ebx
	call	C(M_Print)
	addl	$12,%esp
	movl	C(lanConfig_cursor_table)+8,%eax
	subl	$8,%eax
	pushl	$1
	pushl	$22
	pushl	%eax
	leal	8(%ebx),%eax
	pushl	%eax
	call	C(M_DrawTextBox)
	addl	$16,%esp
	pushl	$C(lanConfig_joinname)
	pushl	C(lanConfig_cursor_table)+8
	leal	16(%ebx),%eax
	pushl	%eax
	call	C(M_Print)
	addl	$12,%esp
	jmp	.Lmenu_lanconfig_cursor

.Lmenu_lanconfig_start_form:
	movl	C(lanConfig_cursor_table)+4,%eax
	subl	$8,%eax
	pushl	$1
	pushl	$2
	pushl	%eax
	pushl	%ebx
	call	C(M_DrawTextBox)
	addl	$16,%esp
	pushl	$.Lmenu_lanconfig_ok
	pushl	C(lanConfig_cursor_table)+4
	leal	8(%ebx),%eax
	pushl	%eax
	call	C(M_Print)
	addl	$12,%esp

.Lmenu_lanconfig_cursor:
	/* C casts realtime*4 with truncation and restores the incoming CW. */
	fldl	C(realtime)
	fmull	.Lmenu_modem_four
	fnstcw	-28(%ebp)
	movw	-28(%ebp),%dx
	orb	$12,%dh
	movw	%dx,-30(%ebp)
	fldcw	-30(%ebp)
	fistpl	-32(%ebp)
	fldcw	-28(%ebp)
	movl	-32(%ebp),%eax
	andl	$1,%eax
	movl	%eax,-24(%ebp)

	/* Main menu cursor marker. */
	movl	-24(%ebp),%ecx
	addl	$12,%ecx
	pushl	%ecx
	movl	C(lanConfig_cursor),%edx
	movl	C(lanConfig_cursor_table)(,%edx,4),%eax
	pushl	%eax
	leal	-8(%ebx),%eax
	pushl	%eax
	call	C(M_DrawCharacter)
	addl	$12,%esp

	/* Caret follows the editable port or address string. */
	cmpl	$0,C(lanConfig_cursor)
	jne	.Lmenu_lanconfig_join_caret
	subl	$12,%esp
	pushl	$C(lanConfig_portname)
	call	C(strlen)
	addl	$16,%esp
	shll	$3,%eax
	leal	72(%ebx,%eax),%eax
	movl	-24(%ebp),%ecx
	addl	$10,%ecx
	pushl	%ecx
	pushl	C(lanConfig_cursor_table)
	pushl	%eax
	call	C(M_DrawCharacter)
	addl	$12,%esp
.Lmenu_lanconfig_join_caret:
	cmpl	$2,C(lanConfig_cursor)
	jne	.Lmenu_lanconfig_return_reason
	subl	$12,%esp
	pushl	$C(lanConfig_joinname)
	call	C(strlen)
	addl	$16,%esp
	shll	$3,%eax
	leal	16(%ebx,%eax),%eax
	movl	-24(%ebp),%ecx
	addl	$10,%ecx
	pushl	%ecx
	pushl	C(lanConfig_cursor_table)+8
	pushl	%eax
	call	C(M_DrawCharacter)
	addl	$12,%esp

.Lmenu_lanconfig_return_reason:
	cmpb	$0,C(m_return_reason)
	je	.Lmenu_lanconfig_done
	pushl	$C(m_return_reason)
	pushl	$148
	pushl	%ebx
	call	C(M_PrintWhite)
	addl	$12,%esp

.Lmenu_lanconfig_done:
	leal	-12(%ebp),%esp
	popl	%edi
	popl	%esi
	popl	%ebx
	popl	%ebp
	ret

.p2align 2
.globl C(M_DrawSlider)
C(M_DrawSlider):
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	subl	$16,%esp
	movl	8(%ebp),%ebx		/* x */
	movl	12(%ebp),%esi		/* y */
	flds	16(%ebp)			/* range */
	fsts	-16(%ebp)
	ftst
	fnstsw	%ax
	fstp	%st(0)
	testb	$5,%ah			/* negative or unordered */
	je	.Lmenu_options_slider_nonnegative
	fldz
	fstps	-16(%ebp)
.Lmenu_options_slider_nonnegative:
	fld1
	flds	-16(%ebp)
	fcomp	%st(1)
	fnstsw	%ax
	testb	$69,%ah			/* clamp only when range > 1 */
	jne	.Lmenu_options_slider_clamped
	fstps	-16(%ebp)
	jmp	.Lmenu_options_slider_draw
.Lmenu_options_slider_clamped:
	fstp	%st(0)

.Lmenu_options_slider_draw:
	pushl	$128
	pushl	%esi
	leal	-8(%ebx),%eax
	pushl	%eax
	call	C(M_DrawCharacter)
	addl	$12,%esp
	xorl	%edi,%edi
.Lmenu_options_slider_loop:
	pushl	$129
	pushl	%esi
	leal	(%ebx,%edi,8),%eax
	pushl	%eax
	call	C(M_DrawCharacter)
	addl	$12,%esp
	incl	%edi
	cmpl	$10,%edi
	jne	.Lmenu_options_slider_loop
	pushl	$130
	pushl	%esi
	leal	80(%ebx),%eax
	pushl	%eax
	call	C(M_DrawCharacter)
	addl	$12,%esp
	flds	-16(%ebp)
	fmuls	.Lmenu_options_seventy_two
	fiaddl	8(%ebp)
	fnstcw	-22(%ebp)
	movw	-22(%ebp),%dx
	orb	$12,%dh
	movw	%dx,-24(%ebp)
	fldcw	-24(%ebp)
	fistpl	-20(%ebp)
	fldcw	-22(%ebp)
	pushl	$131
	pushl	%esi
	pushl	-20(%ebp)
	call	C(M_DrawCharacter)
	addl	$12,%esp
	leal	-12(%ebp),%esp
	popl	%edi
	popl	%esi
	popl	%ebx
	popl	%ebp
	ret

.p2align 2
.globl C(M_DrawCheckbox)
C(M_DrawCheckbox):
	cmpl	$0,12(%esp)
	je	.Lmenu_options_checkbox_off
	pushl	$.Lmenu_options_on
	jmp	.Lmenu_options_checkbox_print
.Lmenu_options_checkbox_off:
	pushl	$.Lmenu_options_off
.Lmenu_options_checkbox_print:
	pushl	12(%esp)			/* y (after string push) */
	pushl	12(%esp)			/* x */
	call	C(M_Print)
	addl	$12,%esp
	ret

.p2align 2
.globl C(M_FindKeysForCommand)
C(M_FindKeysForCommand):
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	subl	$4,%esp
	movl	8(%ebp),%esi		/* command */
	movl	12(%ebp),%edi		/* twokeys */
	movl	$-1,0(%edi)
	movl	$-1,4(%edi)
	movl	$0,-16(%ebp)		/* count */
	xorl	%ebx,%ebx		/* key number */

.Lmenu_find_keys_next:
	cmpl	$256,%ebx
	jae	.Lmenu_find_keys_done
	movl	C(keybindings)(,%ebx,4),%eax
	testl	%eax,%eax
	je	.Lmenu_find_keys_advance
	movl	%esi,%ecx

.Lmenu_find_keys_compare:
	movzbl	(%ecx),%edx
	testb	%dl,%dl
	je	.Lmenu_find_keys_match
	cmpb	%dl,(%eax)
	jne	.Lmenu_find_keys_advance
	incl	%ecx
	incl	%eax
	jmp	.Lmenu_find_keys_compare

.Lmenu_find_keys_match:
	movl	-16(%ebp),%ecx
	movl	%ebx,(%edi,%ecx,4)
	incl	%ecx
	movl	%ecx,-16(%ebp)
	cmpl	$2,%ecx
	je	.Lmenu_find_keys_done

.Lmenu_find_keys_advance:
	incl	%ebx
	jmp	.Lmenu_find_keys_next

.Lmenu_find_keys_done:
	addl	$4,%esp
	popl	%edi
	popl	%esi
	popl	%ebx
	leave
	ret

.p2align 2
.globl C(M_Keys_Draw)
C(M_Keys_Draw):
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	subl	$36,%esp

	subl	$12,%esp
	pushl	$.Lmenu_keys_title
#ifdef BENCH486
	call	C(Bench486MenuTextCachePic)
#else
	call	C(Draw_CachePic)
#endif
	addl	$16,%esp
	movl	%eax,-36(%ebp)
	movl	$320,%eax
	movl	-36(%ebp),%edx
	subl	(%edx),%eax
	movl	%eax,%edx
	sarl	$31,%edx
	andl	$1,%edx
	addl	%edx,%eax
	sarl	$1,%eax
	pushl	-36(%ebp)
	pushl	$4
	pushl	%eax
	call	C(M_DrawPic)
	addl	$12,%esp

	cmpl	$0,C(bind_grab)
	je	.Lmenu_keys_prompt_normal
	pushl	$.Lmenu_keys_prompt_grab
	pushl	$32
	pushl	$12
	call	C(M_Print)
	addl	$12,%esp
	jmp	.Lmenu_keys_rows_start

.Lmenu_keys_prompt_normal:
	pushl	$.Lmenu_keys_prompt_enter
	pushl	$32
	pushl	$18
	call	C(M_Print)
	addl	$12,%esp

.Lmenu_keys_rows_start:
	xorl	%ebx,%ebx
.Lmenu_keys_row:
	cmpl	$MD_KEY_BIND_COUNT,%ebx
	jae	.Lmenu_keys_cursor
	movl	%ebx,%eax
	shll	$3,%eax
	leal	C(bindnames)(,%eax),%esi
	leal	48(,%ebx,8),%edi
	movl	%edi,-24(%ebp)
	pushl	4(%esi)
	pushl	%edi
	pushl	$16
	call	C(M_Print)
	addl	$12,%esp

	leal	-20(%ebp),%eax		/* int keys[2] */
	pushl	%eax
	pushl	0(%esi)
	call	C(M_FindKeysForCommand)
	addl	$8,%esp
	cmpl	$-1,-20(%ebp)
	jne	.Lmenu_keys_have_binding
	pushl	$.Lmenu_keys_no_binding
	pushl	-24(%ebp)
	pushl	$140
	call	C(M_Print)
	addl	$12,%esp
	jmp	.Lmenu_keys_row_advance

.Lmenu_keys_have_binding:
	pushl	-20(%ebp)
	call	C(Key_KeynumToString)
	addl	$4,%esp
	movl	%eax,-32(%ebp)
	pushl	%eax
	pushl	-24(%ebp)
	pushl	$140
	call	C(M_Print)
	addl	$12,%esp
	pushl	-32(%ebp)
	call	C(strlen)
	addl	$4,%esp
	shll	$3,%eax
	movl	%eax,-28(%ebp)
	cmpl	$-1,-16(%ebp)
	je	.Lmenu_keys_row_advance

	movl	-28(%ebp),%eax
	addl	$148,%eax
	pushl	$.Lmenu_keys_or
	pushl	-24(%ebp)
	pushl	%eax
	call	C(M_Print)
	addl	$12,%esp
	pushl	-16(%ebp)
	call	C(Key_KeynumToString)
	addl	$4,%esp
	movl	%eax,-32(%ebp)
	movl	-28(%ebp),%eax
	addl	$172,%eax
	pushl	-32(%ebp)
	pushl	-24(%ebp)
	pushl	%eax
	call	C(M_Print)
	addl	$12,%esp

.Lmenu_keys_row_advance:
	incl	%ebx
	jmp	.Lmenu_keys_row

.Lmenu_keys_cursor:
	cmpl	$0,C(bind_grab)
	je	.Lmenu_keys_cursor_blink
	movl	$61,%eax			/* '=' */
	jmp	.Lmenu_keys_cursor_draw

.Lmenu_keys_cursor_blink:
	fnstcw	-40(%ebp)
	movw	-40(%ebp),%ax
	andw	$0xf3ff,%ax
	orw	$0x0c00,%ax		/* C float-to-int truncation */
	movw	%ax,-38(%ebp)
	fldcw	-38(%ebp)
	fldl	C(realtime)
	fmull	.Lmenu_keys_four
	fistpl	-44(%ebp)
	fldcw	-40(%ebp)
	movl	-44(%ebp),%eax
	andl	$1,%eax
	addl	$12,%eax

.Lmenu_keys_cursor_draw:
	pushl	%eax
	movl	C(keys_cursor),%eax
	leal	48(,%eax,8),%eax
	pushl	%eax
	pushl	$130
	call	C(M_DrawCharacter)
	addl	$12,%esp

	addl	$36,%esp
	popl	%edi
	popl	%esi
	popl	%ebx
	leave
	ret

.p2align 2
.globl C(M_Setup_Draw)
C(M_Setup_Draw):
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	subl	$24,%esp

	MENU_PAGE_CACHE $.Lmenu_plaque
	pushl	%eax
	pushl	$4
	pushl	$16
	call	C(M_DrawTransPic)
	addl	$12,%esp

	MENU_PAGE_CACHE $.Lmenu_multi_title
	movl	%eax,-16(%ebp)
	movl	$320,%eax
	movl	-16(%ebp),%edx
	subl	(%edx),%eax
	movl	%eax,%edx
	sarl	$31,%edx
	andl	$1,%edx
	addl	%edx,%eax
	sarl	$1,%eax
	pushl	-16(%ebp)
	pushl	$4
	pushl	%eax
	call	C(M_DrawPic)
	addl	$12,%esp

	pushl	$.Lmenu_setup_hostname_label
	pushl	$40
	pushl	$64
	call	C(M_Print)
	addl	$12,%esp
	pushl	$1
	pushl	$16
	pushl	$32
	pushl	$160
	call	C(M_DrawTextBox)
	addl	$16,%esp
	pushl	$C(setup_hostname)
	pushl	$40
	pushl	$168
	call	C(M_Print)
	addl	$12,%esp

	pushl	$.Lmenu_setup_name_label
	pushl	$56
	pushl	$64
	call	C(M_Print)
	addl	$12,%esp
	pushl	$1
	pushl	$16
	pushl	$48
	pushl	$160
	call	C(M_DrawTextBox)
	addl	$16,%esp
	pushl	$C(setup_myname)
	pushl	$56
	pushl	$168
	call	C(M_Print)
	addl	$12,%esp

	pushl	$.Lmenu_setup_shirt_label
	pushl	$80
	pushl	$64
	call	C(M_Print)
	addl	$12,%esp
	pushl	$.Lmenu_setup_pants_label
	pushl	$104
	pushl	$64
	call	C(M_Print)
	addl	$12,%esp

	pushl	$1
	pushl	$14
	pushl	$132
	pushl	$64
	call	C(M_DrawTextBox)
	addl	$16,%esp
	pushl	$.Lmenu_setup_accept_label
	pushl	$140
	pushl	$72
	call	C(M_Print)
	addl	$12,%esp

	MENU_PAGE_CACHE $.Lmenu_setup_bigbox
	pushl	%eax
	pushl	$64
	pushl	$160
	call	C(M_DrawTransPic)
	addl	$12,%esp
	MENU_PAGE_CACHE $.Lmenu_setup_player
	movl	%eax,-20(%ebp)
	movl	C(setup_bottom),%eax
	shll	$4,%eax
	pushl	%eax
	movl	C(setup_top),%eax
	shll	$4,%eax
	pushl	%eax
	call	C(M_BuildTranslationTable)
	addl	$8,%esp
	pushl	-20(%ebp)
	pushl	$72
	pushl	$172
	call	C(M_DrawTransPicTranslate)
	addl	$12,%esp

	fnstcw	-24(%ebp)
	movw	-24(%ebp),%ax
	andw	$0xf3ff,%ax
	orw	$0x0c00,%ax
	movw	%ax,-22(%ebp)
	fldcw	-22(%ebp)
	fldl	C(realtime)
	fmull	.Lmenu_keys_four
	fistpl	-28(%ebp)
	fldcw	-24(%ebp)
	andl	$1,-28(%ebp)

	movl	C(setup_cursor),%edx
	movl	C(setup_cursor_table)(,%edx,4),%eax
	movl	%eax,-32(%ebp)
	movl	-28(%ebp),%eax
	addl	$12,%eax
	pushl	%eax
	pushl	-32(%ebp)
	pushl	$56
	call	C(M_DrawCharacter)
	addl	$12,%esp
	cmpl	$0,C(setup_cursor)
	jne	.Lmenu_setup_name_cursor
	subl	$12,%esp
	pushl	$C(setup_hostname)
	call	C(strlen)
	addl	$16,%esp
	shll	$3,%eax
	addl	$168,%eax
	movl	%eax,-36(%ebp)
	movl	-28(%ebp),%eax
	addl	$10,%eax
	pushl	%eax
	pushl	-32(%ebp)
	pushl	-36(%ebp)
	call	C(M_DrawCharacter)
	addl	$12,%esp

.Lmenu_setup_name_cursor:
	cmpl	$1,C(setup_cursor)
	jne	.Lmenu_setup_draw_done
	subl	$12,%esp
	pushl	$C(setup_myname)
	call	C(strlen)
	addl	$16,%esp
	shll	$3,%eax
	addl	$168,%eax
	movl	%eax,-36(%ebp)
	movl	-28(%ebp),%eax
	addl	$10,%eax
	pushl	%eax
	pushl	-32(%ebp)
	pushl	-36(%ebp)
	call	C(M_DrawCharacter)
	addl	$12,%esp

.Lmenu_setup_draw_done:
	addl	$24,%esp
	popl	%edi
	popl	%esi
	popl	%ebx
	leave
	ret

.p2align 2
.globl C(M_Quit_Draw)
C(M_Quit_Draw):
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	cmpl	$0,C(wasInMenus)
	je	.Lmenu_quit_textbox
	movl	C(m_quit_prevstate),%eax
	movl	%eax,C(m_state)
	movl	$1,C(m_recursiveDraw)
	call	C(M_Draw)
	movl	$MD_STATE_QUIT,C(m_state)

.Lmenu_quit_textbox:
	pushl	$4
	pushl	$24
	pushl	$76
	pushl	$56
	call	C(M_DrawTextBox)
	addl	$16,%esp
	movl	C(msgNumber),%eax
	shll	$4,%eax
	leal	C(quitMessage)(,%eax),%esi
	xorl	%ebx,%ebx
.Lmenu_quit_message_loop:
	movl	(%esi,%ebx,4),%eax
	pushl	%eax
	leal	84(,%ebx,8),%eax
	pushl	%eax
	pushl	$64
	call	C(M_Print)
	addl	$12,%esp
	incl	%ebx
	cmpl	$4,%ebx
	jne	.Lmenu_quit_message_loop
	popl	%edi
	popl	%esi
	popl	%ebx
	ret

.p2align 2
.globl C(M_Options_Draw)
C(M_Options_Draw):
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	subl	$32,%esp

	MENU_PAGE_CACHE $.Lmenu_plaque
	pushl	%eax
	pushl	$4
	pushl	$16
	call	C(M_DrawTransPic)
	addl	$12,%esp
	MENU_PAGE_CACHE $.Lmenu_options_title
	movl	%eax,-16(%ebp)
	movl	$320,%edx
	subl	(%eax),%edx
	movl	%edx,%eax
	movl	%edx,%ecx
	shrl	$31,%ecx
	addl	%ecx,%eax
	sarl	$1,%eax
	pushl	-16(%ebp)
	pushl	$4
	pushl	%eax
	call	C(M_DrawPic)
	addl	$12,%esp

	pushl	$.Lmenu_options_customize
	pushl	$32
	pushl	$16
	call	C(M_Print)
	addl	$12,%esp
	pushl	$.Lmenu_options_console
	pushl	$40
	pushl	$16
	call	C(M_Print)
	addl	$12,%esp
	pushl	$.Lmenu_options_defaults
	pushl	$48
	pushl	$16
	call	C(M_Print)
	addl	$12,%esp

	pushl	$.Lmenu_options_screen_size
	pushl	$56
	pushl	$16
	call	C(M_Print)
	flds	.Lmenu_options_thirty
	fsubrs	C(scr_viewsize)+16
	fmuls	.Lmenu_options_inv_ninety
	fstps	-20(%ebp)
	addl	$12,%esp
	pushl	-20(%ebp)
	pushl	$56
	pushl	$220
	call	C(M_DrawSlider)
	addl	$12,%esp

	pushl	$.Lmenu_options_brightness
	pushl	$64
	pushl	$16
	call	C(M_Print)
	fld1
	fsubs	C(v_gamma)+16
	fadd	%st(0),%st
	fstps	-20(%ebp)
	addl	$12,%esp
	pushl	-20(%ebp)
	pushl	$64
	pushl	$220
	call	C(M_DrawSlider)
	addl	$12,%esp

	pushl	$.Lmenu_options_mouse_speed
	pushl	$72
	pushl	$16
	call	C(M_Print)
	fld1
	fsubrs	C(sensitivity)+16
	fmuls	.Lmenu_options_tenth
	fstps	-20(%ebp)
	addl	$12,%esp
	pushl	-20(%ebp)
	pushl	$72
	pushl	$220
	call	C(M_DrawSlider)
	addl	$12,%esp

	pushl	$.Lmenu_options_cd_volume
	pushl	$80
	pushl	$16
	call	C(M_Print)
	flds	C(bgmvolume)+16
	fstps	-20(%ebp)
	addl	$12,%esp
	pushl	-20(%ebp)
	pushl	$80
	pushl	$220
	call	C(M_DrawSlider)
	addl	$12,%esp

	pushl	$.Lmenu_options_sound_volume
	pushl	$88
	pushl	$16
	call	C(M_Print)
	flds	C(volume)+16
	fstps	-20(%ebp)
	addl	$12,%esp
	pushl	-20(%ebp)
	pushl	$88
	pushl	$220
	call	C(M_DrawSlider)
	addl	$12,%esp

	pushl	$.Lmenu_options_always_run
	pushl	$96
	pushl	$16
	call	C(M_Print)
	flds	C(cl_forwardspeed)+16
	fcomps	.Lmenu_options_two_hundred
	fnstsw	%ax
	testb	$69,%ah
	jne	.Lmenu_options_forward_off
	movl	$1,%eax
	jmp	.Lmenu_options_forward_ready
.Lmenu_options_forward_off:
	xorl	%eax,%eax
.Lmenu_options_forward_ready:
	addl	$12,%esp
	pushl	%eax
	pushl	$96
	pushl	$220
	call	C(M_DrawCheckbox)
	addl	$12,%esp

	pushl	$.Lmenu_options_invert_mouse
	pushl	$104
	pushl	$16
	call	C(M_Print)
	fldz
	fcomps	C(m_pitch)+16
	fnstsw	%ax
	testb	$69,%ah
	jne	.Lmenu_options_pitch_off
	movl	$1,%eax
	jmp	.Lmenu_options_pitch_ready
.Lmenu_options_pitch_off:
	xorl	%eax,%eax
.Lmenu_options_pitch_ready:
	addl	$12,%esp
	pushl	%eax
	pushl	$104
	pushl	$220
	call	C(M_DrawCheckbox)
	addl	$12,%esp

	pushl	$.Lmenu_options_lookspring
	pushl	$112
	pushl	$16
	call	C(M_Print)
	fnstcw	-22(%ebp)
	movw	-22(%ebp),%dx
	orb	$12,%dh
	movw	%dx,-24(%ebp)
	flds	C(lookspring)+16
	fldcw	-24(%ebp)
	fistpl	-28(%ebp)
	fldcw	-22(%ebp)
	addl	$12,%esp
	pushl	-28(%ebp)
	pushl	$112
	pushl	$220
	call	C(M_DrawCheckbox)
	addl	$12,%esp

	pushl	$.Lmenu_options_lookstrafe
	pushl	$120
	pushl	$16
	call	C(M_Print)
	fnstcw	-22(%ebp)
	movw	-22(%ebp),%dx
	orb	$12,%dh
	movw	%dx,-24(%ebp)
	flds	C(lookstrafe)+16
	fldcw	-24(%ebp)
	fistpl	-28(%ebp)
	fldcw	-22(%ebp)
	addl	$12,%esp
	pushl	-28(%ebp)
	pushl	$120
	pushl	$220
	call	C(M_DrawCheckbox)
	addl	$12,%esp

	cmpl	$0,C(vid_menudrawfn)
	je	.Lmenu_options_cursor
	pushl	$.Lmenu_options_video
	pushl	$128
	pushl	$16
	call	C(M_Print)
	addl	$12,%esp

.Lmenu_options_cursor:
	flds	.Lmenu_options_four
	fmull	C(realtime)
	fnstcw	-22(%ebp)
	movw	-22(%ebp),%dx
	orb	$12,%dh
	movw	%dx,-24(%ebp)
	fldcw	-24(%ebp)
	fistpl	-28(%ebp)
	fldcw	-22(%ebp)
	movl	-28(%ebp),%eax
	andl	$1,%eax
	addl	$12,%eax
	pushl	%eax
	movl	C(options_cursor),%edx
	leal	32(,%edx,8),%eax
	pushl	%eax
	pushl	$200
	call	C(M_DrawCharacter)
	addl	$12,%esp

	leal	-12(%ebp),%esp
	popl	%edi
	popl	%esi
	popl	%ebx
	popl	%ebp
	ret

.p2align 2
.globl C(M_Help_Draw)
C(M_Help_Draw):
	subl	$8,%esp
	pushl	C(help_page)
	pushl	$.Lmenu_help_format
	call	C(va)
	addl	$16,%esp
	MENU_PAGE_CACHE %eax
	subl	$4,%esp
	pushl	%eax
	pushl	$0
	pushl	$0
	call	C(M_DrawPic)
	addl	$16,%esp
	ret

.p2align 2
.globl C(M_Load_Draw)
C(M_Load_Draw):
	pushl	$.Lmenu_load_title
	call	.Lmenu_save_load_draw
	addl	$4,%esp
	ret

.p2align 2
.globl C(M_Save_Draw)
C(M_Save_Draw):
	pushl	$.Lmenu_save_title
	call	.Lmenu_save_load_draw
	addl	$4,%esp
	ret

.p2align 2
.Lmenu_save_load_draw:
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	subl	$16,%esp

	MENU_PAGE_CACHE 8(%ebp)
	movl	%eax,-16(%ebp)
	movl	$320,%edx
	subl	(%eax),%edx
	movl	%edx,%eax
	shrl	$31,%eax
	addl	%edx,%eax
	sarl	$1,%eax
	subl	$4,%esp
	pushl	-16(%ebp)
	pushl	$4
	pushl	%eax
	call	C(M_DrawPic)
	addl	$16,%esp

	xorl	%ebx,%ebx
	movl	$C(m_filenames),%esi
.Lmenu_save_load_rows:
	pushl	%esi
	leal	32(,%ebx,8),%eax
	pushl	%eax
	pushl	$16
	call	C(M_Print)
	addl	$12,%esp
	addl	$MENU_SAVE_FILENAME_STRIDE,%esi
	incl	%ebx
	cmpl	$MENU_SAVE_SLOT_COUNT,%ebx
	jl	.Lmenu_save_load_rows

	movl	C(load_cursor),%eax
	leal	32(,%eax,8),%edi
	flds	.Lmenu_save_time_four
	fmull	C(realtime)
	fnstcw	-18(%ebp)
	movw	-18(%ebp),%dx
	orb	$12,%dh
	movw	%dx,-20(%ebp)
	fldcw	-20(%ebp)
	fistpl	-24(%ebp)
	fldcw	-18(%ebp)
	movl	-24(%ebp),%edx
	andl	$1,%edx
	addl	$12,%edx
	pushl	%edx
	pushl	%edi
	pushl	$8
	call	C(M_DrawCharacter)
	addl	$12,%esp

	addl	$16,%esp
	popl	%edi
	popl	%esi
	popl	%ebx
	leave
	ret
.purgem MENU_PAGE_CACHE

/* Menu pictures share the classic 320-pixel centered coordinate system. */
.p2align 2
.globl C(M_DrawTransPic)
C(M_DrawTransPic):
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	movl	8(%ebp),%eax		/* x */
	movl	C(vid)+MT_VID_WIDTH_OFFSET,%ebx
	subl	$320,%ebx
	shrl	$1,%ebx
	addl	%ebx,%eax
#ifdef BENCH486
	pushl	$0
	pushl	16(%ebp)		/* pic */
	pushl	12(%ebp)		/* y */
	pushl	%eax
	pushl	$1
	call	C(Bench486MenuTextDrawPic)
	addl	$20,%esp
#else
	pushl	16(%ebp)		/* pic */
	pushl	12(%ebp)		/* y */
	pushl	%eax
	call	C(Draw_TransPic)
	addl	$12,%esp
#endif
	popl	%ebx
	popl	%ebp
	ret

.p2align 2
.globl C(M_DrawPic)
C(M_DrawPic):
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	movl	8(%ebp),%eax		/* x */
	movl	C(vid)+MT_VID_WIDTH_OFFSET,%ebx
	subl	$320,%ebx
	shrl	$1,%ebx
	addl	%ebx,%eax
#ifdef BENCH486
	pushl	$0
	pushl	16(%ebp)		/* pic */
	pushl	12(%ebp)		/* y */
	pushl	%eax
	pushl	$2
	call	C(Bench486MenuTextDrawPic)
	addl	$20,%esp
#else
	pushl	16(%ebp)		/* pic */
	pushl	12(%ebp)		/* y */
	pushl	%eax
	call	C(Draw_Pic)
	addl	$12,%esp
#endif
	popl	%ebx
	popl	%ebp
	ret

.p2align 2
.globl C(M_DrawTransPicTranslate)
C(M_DrawTransPicTranslate):
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	movl	8(%ebp),%eax		/* x */
	movl	C(vid)+MT_VID_WIDTH_OFFSET,%ebx
	subl	$320,%ebx
	shrl	$1,%ebx
	addl	%ebx,%eax
#ifdef BENCH486
	pushl	$C(translationTable)
	pushl	16(%ebp)		/* pic */
	pushl	12(%ebp)		/* y */
	pushl	%eax
	pushl	$3
	call	C(Bench486MenuTextDrawPic)
	addl	$20,%esp
#else
	pushl	$C(translationTable)
	pushl	16(%ebp)		/* pic */
	pushl	12(%ebp)		/* y */
	pushl	%eax
	call	C(Draw_TransPicTranslate)
	addl	$16,%esp
#endif
	popl	%ebx
	popl	%ebp
	ret

/* Pause plaque: preserve the C float truth test, pause gate and unsigned placement. */
.p2align 2
.globl C(SCR_DrawPause)
.globl C(SCR_DrawPause_asm486)
C(SCR_DrawPause):
C(SCR_DrawPause_asm486):
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	subl	$12,%esp
	/* Match the C build's x87 C3 test, including its unordered-value branch. */
	fldz
	fcomps	C(scr_showpause)+SO_CVAR_VALUE
	fnstsw	%ax
	testb	$0x40,%ah
	jne	.Lso_pause_done
	cmpl	$0,C(cl)+SO_CLIENT_PAUSED
	je	.Lso_pause_done
	subl	$12,%esp
	pushl	$.Lso_pause_path
#ifdef BENCH486
	call	C(Bench486ScreenOverlayCachePic)
#else
	call	C(Draw_CachePic)
#endif
	addl	$16,%esp
	movl	%eax,%ebx
	movl	C(vid)+SO_VID_WIDTH,%eax
	subl	SO_QPIC_WIDTH(%ebx),%eax
	shrl	$1,%eax
	movl	C(vid)+SO_VID_HEIGHT,%edx
	subl	$48,%edx
	subl	SO_QPIC_HEIGHT(%ebx),%edx
	shrl	$1,%edx
	subl	$12,%esp
	pushl	%ebx
	pushl	%edx
	pushl	%eax
#ifdef BENCH486
	call	C(Bench486ScreenOverlayDrawPic)
#else
	call	C(Draw_Pic)
#endif
	addl	$24,%esp
.Lso_pause_done:
	leal	-4(%ebp),%esp
	popl	%ebx
	popl	%ebp
	ret

/* Loading plaque: a single flag gate followed by the same unsigned placement. */
.p2align 2
.globl C(SCR_DrawLoading)
.globl C(SCR_DrawLoading_asm486)
C(SCR_DrawLoading):
C(SCR_DrawLoading_asm486):
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	subl	$12,%esp
	cmpl	$0,C(scr_drawloading)
	je	.Lso_loading_done
	subl	$12,%esp
	pushl	$.Lso_loading_path
#ifdef BENCH486
	call	C(Bench486ScreenOverlayCachePic)
#else
	call	C(Draw_CachePic)
#endif
	addl	$16,%esp
	movl	%eax,%ebx
	movl	C(vid)+SO_VID_WIDTH,%eax
	subl	SO_QPIC_WIDTH(%ebx),%eax
	shrl	$1,%eax
	movl	C(vid)+SO_VID_HEIGHT,%edx
	subl	$48,%edx
	subl	SO_QPIC_HEIGHT(%ebx),%edx
	shrl	$1,%edx
	subl	$12,%esp
	pushl	%ebx
	pushl	%edx
	pushl	%eax
#ifdef BENCH486
	call	C(Bench486ScreenOverlayDrawPic)
#else
	call	C(Draw_Pic)
#endif
	addl	$24,%esp
.Lso_loading_done:
	leal	-4(%ebp),%esp
	popl	%ebx
	popl	%ebp
	ret

.p2align 4,,15
.globl C(SCR_DrawScreenOverlays_asm486)
C(SCR_DrawScreenOverlays_asm486):
	pushl	%ebp
	movl	%esp,%ebp

	cmpl	$0,C(scr_drawdialog)
	jne	.Lso_dialog
	cmpl	$0,C(scr_drawloading)
	jne	.Lso_loading

	cmpl	$1,C(cl)+SO_CLIENT_INTERMISSION
	jne	.Lso_check_intermission_two
	cmpl	$SO_KEY_GAME,C(key_dest)
	jne	.Lso_normal
	SCREEN_OVERLAY_CALL 5,_Sbar_IntermissionOverlay
	jmp	.Lso_done

.Lso_check_intermission_two:
	cmpl	$2,C(cl)+SO_CLIENT_INTERMISSION
	jne	.Lso_check_intermission_three
	cmpl	$SO_KEY_GAME,C(key_dest)
	jne	.Lso_normal
	SCREEN_OVERLAY_CALL 6,_Sbar_FinaleOverlay
	SCREEN_OVERLAY_CALL 7,_SCR_CheckDrawCenterString
	jmp	.Lso_done

.Lso_check_intermission_three:
	cmpl	$3,C(cl)+SO_CLIENT_INTERMISSION
	jne	.Lso_normal
	cmpl	$SO_KEY_GAME,C(key_dest)
	jne	.Lso_normal
	SCREEN_OVERLAY_CALL 7,_SCR_CheckDrawCenterString
	jmp	.Lso_done

.Lso_dialog:
	SCREEN_OVERLAY_CALL 1,_Sbar_Draw
	SCREEN_OVERLAY_CALL 2,_Draw_FadeScreen
	SCREEN_OVERLAY_CALL 3,_SCR_DrawNotifyString
	movl	$1,C(scr_copyeverything)
	jmp	.Lso_done

.Lso_loading:
	SCREEN_OVERLAY_CALL 4,_SCR_DrawLoading
	SCREEN_OVERLAY_CALL 1,_Sbar_Draw
	jmp	.Lso_done

.Lso_normal:
#if defined(ASM486_SCREEN_DRAW_RAM)
	SCREEN_OVERLAY_CALL 8,_SCR_DrawRam_asm486
#else
	SCREEN_OVERLAY_CALL 8,_SCR_DrawRam
#endif
#if defined(ASM486_SCREEN_NET)
	SCREEN_OVERLAY_CALL 9,_SCR_DrawNet_asm486
#else
	SCREEN_OVERLAY_CALL 9,_SCR_DrawNet
#endif
#if defined(ASM486_SCREEN_TURTLE)
	SCREEN_OVERLAY_CALL 10,_SCR_DrawTurtle_asm486
#else
	SCREEN_OVERLAY_CALL 10,_SCR_DrawTurtle
#endif
	SCREEN_OVERLAY_CALL 11,_SCR_DrawPause
#if defined(BENCH486) && defined(ASM486_SCREEN_CENTER_STRING)
	cmpl	$0,12(%ebp)
	je	.Lso_no_trace_before_center
	pushl	$0
	pushl	$0
	pushl	8(%ebp)
	pushl	$9
	call	C(Bench486ScreenCenterTraceGlyph)
	addl	$16,%esp
.Lso_no_trace_before_center:
#endif
	SCREEN_OVERLAY_CALL 7,_SCR_CheckDrawCenterString
#if defined(BENCH486) && defined(ASM486_SCREEN_CENTER_STRING)
	cmpl	$0,12(%ebp)
	je	.Lso_no_trace_after_center
	pushl	$0
	pushl	$0
	pushl	8(%ebp)
	pushl	$10
	call	C(Bench486ScreenCenterTraceGlyph)
	addl	$16,%esp
.Lso_no_trace_after_center:
#endif
	SCREEN_OVERLAY_CALL 1,_Sbar_Draw
	SCREEN_OVERLAY_CALL 12,_SCR_DrawConsole
	SCREEN_OVERLAY_CALL 13,_M_Draw
.Lso_done:
	leave
	ret

// Per-frame console selection and state update from SCR_DrawConsole.
.p2align 4,,15
.globl C(SCR_DrawConsole)
C(SCR_DrawConsole):
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	subl	$12,%esp
	movl	C(scr_con_current),%eax
	andl	$0x7fffffff,%eax
	je	.Lscr_draw_console_notify

	// C float-to-int conversion truncates independently of the active x87 mode.
	fnstcw	-6(%ebp)
	movzwl	-6(%ebp),%eax
	andw	$0xf3ff,%ax
	orw	$0x0c00,%ax
	movw	%ax,-8(%ebp)
	fldcw	-8(%ebp)
	flds	C(scr_con_current)
	fistpl	-16(%ebp)
	fldcw	-6(%ebp)

	movl	$1,C(scr_copyeverything)
	pushl	$1
	pushl	-16(%ebp)
#ifdef BENCH486
	call	C(Bench486ScreenConsoleDrawCall)
#else
	call	C(Con_DrawConsole)
#endif
	addl	$8,%esp
	movl	$0,C(clearconsole)
	jmp	.Lscr_draw_console_done

.Lscr_draw_console_notify:
	movl	C(key_dest),%ebx
	cmpl	$SO_KEY_GAME,%ebx
	je	.Lscr_draw_console_notify_call
	cmpl	$SO_KEY_MESSAGE,%ebx
	jne	.Lscr_draw_console_done
.Lscr_draw_console_notify_call:
#ifdef BENCH486
	call	C(Bench486ScreenNotifyDrawCall)
#else
	call	C(Con_DrawNotify)
#endif

.Lscr_draw_console_done:
	addl	$12,%esp
	popl	%ebx
	leave
	ret

.text
.p2align 2
.macro MENU_GAMEOPTIONS_PRINT x, y, string
	pushl	$\string
	pushl	\y
	pushl	\x
	call	C(M_Print)
	addl	$12,%esp
.endm

.globl C(M_GameOptions_Draw)
C(M_GameOptions_Draw):
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	subl	$20,%esp

	/* Quake plaque and centered multiplayer title. */
	pushl	$.Lmenu_gameoptions_qplaque
#ifdef BENCH486
	call	C(Bench486MenuTextCachePic)
#else
	call	C(Draw_CachePic)
#endif
	addl	$4,%esp
	pushl	%eax
	pushl	$4
	pushl	$16
	call	C(M_DrawTransPic)
	addl	$12,%esp

	pushl	$.Lmenu_gameoptions_title
#ifdef BENCH486
	call	C(Bench486MenuTextCachePic)
#else
	call	C(Draw_CachePic)
#endif
	addl	$4,%esp
	movl	%eax,-16(%ebp)
	movl	(%eax),%edx
	movl	$320,%eax
	subl	%edx,%eax
	movl	%eax,%edx
	sarl	$31,%edx
	andl	$1,%edx
	addl	%edx,%eax
	sarl	$1,%eax
	pushl	-16(%ebp)
	pushl	$4
	pushl	%eax
	call	C(M_DrawPic)
	addl	$12,%esp

	pushl	$1
	pushl	$10
	pushl	$32
	pushl	$152
	call	C(M_DrawTextBox)
	addl	$16,%esp
	MENU_GAMEOPTIONS_PRINT $160,$40,.Lmenu_gameoptions_begin

	MENU_GAMEOPTIONS_PRINT $0,$56,.Lmenu_gameoptions_maxplayers
	pushl	C(maxplayers)
	pushl	$.Lmenu_gameoptions_integer
	call	C(va)
	addl	$8,%esp
	pushl	%eax
	pushl	$56
	pushl	$160
	call	C(M_Print)
	addl	$12,%esp

	MENU_GAMEOPTIONS_PRINT $0,$64,.Lmenu_gameoptions_game_type
	flds	C(coop)+16
	ftst
	fnstsw	%ax
	fstp	%st(0)
	testb	$4,%ah			/* unordered NaN remains truthy in C */
	jne	.Lmenu_gameoptions_coop
	testb	$64,%ah
	jne	.Lmenu_gameoptions_deathmatch_path
.Lmenu_gameoptions_coop:
	MENU_GAMEOPTIONS_PRINT $160,$64,.Lmenu_gameoptions_cooperative
	jmp	.Lmenu_gameoptions_teamplay
.Lmenu_gameoptions_deathmatch_path:
	MENU_GAMEOPTIONS_PRINT $160,$64,.Lmenu_gameoptions_deathmatch

.Lmenu_gameoptions_teamplay:
	MENU_GAMEOPTIONS_PRINT $0,$72,.Lmenu_gameoptions_teamplay_label
	fnstcw	-24(%ebp)
	movw	-24(%ebp),%dx
	orb	$12,%dh
	movw	%dx,-26(%ebp)
	fldcw	-26(%ebp)
	flds	C(teamplay)+16
	fistpl	-28(%ebp)
	fldcw	-24(%ebp)
	movl	-28(%ebp),%eax
	cmpl	$1,%eax
	je	.Lmenu_gameoptions_team_one
	cmpl	$2,%eax
	je	.Lmenu_gameoptions_team_two
	cmpl	$3,%eax
	je	.Lmenu_gameoptions_team_three
	cmpl	$4,%eax
	je	.Lmenu_gameoptions_team_four
	cmpl	$5,%eax
	je	.Lmenu_gameoptions_team_five
	cmpl	$6,%eax
	je	.Lmenu_gameoptions_team_six
	jmp	.Lmenu_gameoptions_team_default

.Lmenu_gameoptions_team_one:
	pushl	$.Lmenu_gameoptions_no_friendly_fire
	jmp	.Lmenu_gameoptions_team_print
.Lmenu_gameoptions_team_two:
	pushl	$.Lmenu_gameoptions_friendly_fire
	jmp	.Lmenu_gameoptions_team_print
.Lmenu_gameoptions_team_three:
	cmpl	$0,C(rogue)
	je	.Lmenu_gameoptions_team_default
	pushl	$.Lmenu_gameoptions_tag
	jmp	.Lmenu_gameoptions_team_print
.Lmenu_gameoptions_team_four:
	cmpl	$0,C(rogue)
	je	.Lmenu_gameoptions_team_default
	pushl	$.Lmenu_gameoptions_capture_flag
	jmp	.Lmenu_gameoptions_team_print
.Lmenu_gameoptions_team_five:
	cmpl	$0,C(rogue)
	je	.Lmenu_gameoptions_team_default
	pushl	$.Lmenu_gameoptions_one_flag
	jmp	.Lmenu_gameoptions_team_print
.Lmenu_gameoptions_team_six:
	cmpl	$0,C(rogue)
	je	.Lmenu_gameoptions_team_default
	pushl	$.Lmenu_gameoptions_three_team
	jmp	.Lmenu_gameoptions_team_print
.Lmenu_gameoptions_team_default:
	pushl	$.Lmenu_gameoptions_off
.Lmenu_gameoptions_team_print:
	pushl	$72
	pushl	$160
	call	C(M_Print)
	addl	$12,%esp

	MENU_GAMEOPTIONS_PRINT $0,$80,.Lmenu_gameoptions_skill
	flds	C(skill)+16
	fcomps	.Lmenu_gameoptions_float_zero
	fnstsw	%ax
	sahf
	jp	.Lmenu_gameoptions_nightmare
	je	.Lmenu_gameoptions_easy_path
	flds	C(skill)+16
	fcomps	.Lmenu_gameoptions_float_one
	fnstsw	%ax
	sahf
	jp	.Lmenu_gameoptions_nightmare
	je	.Lmenu_gameoptions_normal_path
	flds	C(skill)+16
	fcomps	.Lmenu_gameoptions_float_two
	fnstsw	%ax
	sahf
	jp	.Lmenu_gameoptions_nightmare
	je	.Lmenu_gameoptions_hard_path
	jmp	.Lmenu_gameoptions_nightmare
.Lmenu_gameoptions_easy_path:
	MENU_GAMEOPTIONS_PRINT $160,$80,.Lmenu_gameoptions_easy
	jmp	.Lmenu_gameoptions_frag_limit
.Lmenu_gameoptions_normal_path:
	MENU_GAMEOPTIONS_PRINT $160,$80,.Lmenu_gameoptions_normal
	jmp	.Lmenu_gameoptions_frag_limit
.Lmenu_gameoptions_hard_path:
	MENU_GAMEOPTIONS_PRINT $160,$80,.Lmenu_gameoptions_hard
	jmp	.Lmenu_gameoptions_frag_limit
.Lmenu_gameoptions_nightmare:
	MENU_GAMEOPTIONS_PRINT $160,$80,.Lmenu_gameoptions_nightmare_label

.Lmenu_gameoptions_frag_limit:
	MENU_GAMEOPTIONS_PRINT $0,$88,.Lmenu_gameoptions_frag_limit_label
	flds	C(fraglimit)+16
	fcomps	.Lmenu_gameoptions_float_zero
	fnstsw	%ax
	sahf
	jp	.Lmenu_gameoptions_frag_value
	je	.Lmenu_gameoptions_frag_none
.Lmenu_gameoptions_frag_value:
	fnstcw	-24(%ebp)
	movw	-24(%ebp),%dx
	orb	$12,%dh
	movw	%dx,-26(%ebp)
	fldcw	-26(%ebp)
	flds	C(fraglimit)+16
	fistpl	-28(%ebp)
	fldcw	-24(%ebp)
	pushl	-28(%ebp)
	pushl	$.Lmenu_gameoptions_frags
	call	C(va)
	addl	$8,%esp
	pushl	%eax
	pushl	$88
	pushl	$160
	call	C(M_Print)
	addl	$12,%esp
	jmp	.Lmenu_gameoptions_time_limit
.Lmenu_gameoptions_frag_none:
	MENU_GAMEOPTIONS_PRINT $160,$88,.Lmenu_gameoptions_none

.Lmenu_gameoptions_time_limit:
	MENU_GAMEOPTIONS_PRINT $0,$96,.Lmenu_gameoptions_time_limit_label
	flds	C(timelimit)+16
	fcomps	.Lmenu_gameoptions_float_zero
	fnstsw	%ax
	sahf
	jp	.Lmenu_gameoptions_time_value
	je	.Lmenu_gameoptions_time_none
.Lmenu_gameoptions_time_value:
	fnstcw	-24(%ebp)
	movw	-24(%ebp),%dx
	orb	$12,%dh
	movw	%dx,-26(%ebp)
	fldcw	-26(%ebp)
	flds	C(timelimit)+16
	fistpl	-28(%ebp)
	fldcw	-24(%ebp)
	pushl	-28(%ebp)
	pushl	$.Lmenu_gameoptions_minutes
	call	C(va)
	addl	$8,%esp
	pushl	%eax
	pushl	$96
	pushl	$160
	call	C(M_Print)
	addl	$12,%esp
	jmp	.Lmenu_gameoptions_episode
.Lmenu_gameoptions_time_none:
	MENU_GAMEOPTIONS_PRINT $160,$96,.Lmenu_gameoptions_none

.Lmenu_gameoptions_episode:
	MENU_GAMEOPTIONS_PRINT $0,$112,.Lmenu_gameoptions_episode_label
	movl	$C(episodes),%esi
	movl	$C(levels),%edi
	cmpl	$0,C(hipnotic)
	je	.Lmenu_gameoptions_episode_rogue
	movl	$C(hipnoticepisodes),%esi
	movl	$C(hipnoticlevels),%edi
	jmp	.Lmenu_gameoptions_episode_draw
.Lmenu_gameoptions_episode_rogue:
	cmpl	$0,C(rogue)
	je	.Lmenu_gameoptions_episode_draw
	movl	$C(rogueepisodes),%esi
	movl	$C(roguelevels),%edi
.Lmenu_gameoptions_episode_draw:
	movl	C(startepisode),%eax
	imull	$12,%eax
	movl	(%esi,%eax,1),%edx
	pushl	%edx
	pushl	$112
	pushl	$160
	call	C(M_Print)
	addl	$12,%esp

	MENU_GAMEOPTIONS_PRINT $0,$120,.Lmenu_gameoptions_level_label
	movl	C(startepisode),%eax
	imull	$12,%eax
	movl	4(%esi,%eax,1),%eax
	addl	C(startlevel),%eax
	shll	$3,%eax
	movl	4(%edi,%eax,1),%edx
	pushl	%edx
	pushl	$120
	pushl	$160
	call	C(M_Print)
	addl	$12,%esp
	movl	C(startepisode),%eax
	imull	$12,%eax
	movl	4(%esi,%eax,1),%eax
	addl	C(startlevel),%eax
	shll	$3,%eax
	movl	(%edi,%eax,1),%edx
	pushl	%edx
	pushl	$128
	pushl	$160
	call	C(M_Print)
	addl	$12,%esp

	/* The cast in the C cursor expression truncates toward zero. */
	fnstcw	-24(%ebp)
	fldl	C(realtime)
	fmull	.Lmenu_gameoptions_four
	movw	-24(%ebp),%dx
	orb	$12,%dh
	movw	%dx,-26(%ebp)
	fldcw	-26(%ebp)
	fistpl	-28(%ebp)
	fldcw	-24(%ebp)
	movl	-28(%ebp),%eax
	andl	$1,%eax
	addl	$12,%eax
	movl	C(gameoptions_cursor),%edx
	movl	C(gameoptions_cursor_table)(,%edx,4),%ecx
	pushl	%eax
	pushl	%ecx
	pushl	$144
	call	C(M_DrawCharacter)
	addl	$12,%esp

	cmpl	$0,C(m_serverInfoMessage)
	je	.Lmenu_gameoptions_done
	fldl	C(realtime)
	fsubl	C(m_serverInfoMessageTime)
	fcompl	.Lmenu_gameoptions_five
	fnstsw	%ax
	sahf
	jp	.Lmenu_gameoptions_server_info_expired
	jb	.Lmenu_gameoptions_server_info_visible
.Lmenu_gameoptions_server_info_expired:
	movl	$0,C(m_serverInfoMessage)
	jmp	.Lmenu_gameoptions_done
.Lmenu_gameoptions_server_info_visible:
	pushl	$4
	pushl	$24
	pushl	$138
	pushl	$56
	call	C(M_DrawTextBox)
	addl	$16,%esp
	MENU_GAMEOPTIONS_PRINT $64,$146,.Lmenu_gameoptions_server_info_1
	MENU_GAMEOPTIONS_PRINT $64,$154,.Lmenu_gameoptions_server_info_2
	MENU_GAMEOPTIONS_PRINT $64,$162,.Lmenu_gameoptions_server_info_3
	MENU_GAMEOPTIONS_PRINT $64,$170,.Lmenu_gameoptions_server_info_4

.Lmenu_gameoptions_done:
	addl	$20,%esp
	popl	%edi
	popl	%esi
	popl	%ebx
	leave
	ret

/* Search-menu rendering and completion state transition. */
.p2align 2
.globl C(M_Search_Draw)
C(M_Search_Draw):
	pushl	$.Lmenu_search_draw_multi_title
#ifdef BENCH486
	call	C(Bench486MenuTextCachePic)
#else
	call	C(Draw_CachePic)
#endif
	addl	$4,%esp
	movl	%eax,%ecx
	movl	$320,%edx
	subl	(%ecx),%edx
	movl	%edx,%eax
	shrl	$31,%eax
	addl	%edx,%eax
	sarl	$1,%eax
	pushl	%ecx
	pushl	$4
	pushl	%eax
	call	C(M_DrawPic)
	addl	$12,%esp

	pushl	$1
	pushl	$12
	pushl	$32
	pushl	$108
	call	C(M_DrawTextBox)
	addl	$16,%esp
	pushl	$.Lmenu_search_draw_searching
	pushl	$40
	pushl	$116
	call	C(M_Print)
	addl	$12,%esp

	cmpl	$0,C(slistInProgress)
	je	.Lmenu_search_draw_poll_done
#ifdef BENCH486
	call	C(Bench486MenuSearchNetPoll)
#else
	call	C(NET_Poll)
#endif
	ret

.Lmenu_search_draw_poll_done:
	cmpl	$0,C(searchComplete)
	jne	.Lmenu_search_draw_check_servers
	movl	$1,C(searchComplete)
	fldl	C(realtime)
	fstpl	C(searchCompleteTime)

.Lmenu_search_draw_check_servers:
	cmpl	$0,C(hostCacheCount)
	je	.Lmenu_search_draw_no_servers
	call	C(M_Menu_ServerList_f)
	ret

.Lmenu_search_draw_no_servers:
	pushl	$.Lmenu_search_draw_no_servers_text
	pushl	$64
	pushl	$72
	call	C(M_PrintWhite)
	addl	$12,%esp

	fldl	C(realtime)
	fsubl	C(searchCompleteTime)
	flds	.Lmenu_search_draw_three
	fxch	%st(1)
	fcompp
	fnstsw	%ax
	testb	$1,%ah
	jnz	.Lmenu_search_draw_done
	call	C(M_Menu_LanConfig_f)

.Lmenu_search_draw_done:
	ret

/* Video-menu dispatch and mode-list rendering. */
.p2align 2
.globl C(M_Video_Draw)
C(M_Video_Draw):
	movl	C(vid_menudrawfn),%eax
	call	*%eax
	ret

.p2align 2
.globl C(VID_MenuDraw)
C(VID_MenuDraw):
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	subl	$152,%esp
	movl	$0,C(vid_wmodes)

#ifdef BENCH486
	call	C(Bench486VIDMenuNumModes)
#else
	call	C(VID_NumModes)
#endif
	movl	%eax,-16(%ebp)

#ifdef BENCH486
	pushl	$.Lvm_mode_title
	call	C(Bench486VIDMenuCachePic)
#else
	pushl	$.Lvm_mode_title
	call	C(Draw_CachePic)
#endif
	addl	$4,%esp
	movl	%eax,-36(%ebp)
	movl	$320,%eax
	movl	-36(%ebp),%edx
	subl	(%edx),%eax
	cdq
	movl	$2,%ecx
	idivl	%ecx
	pushl	-36(%ebp)
	pushl	$4
	pushl	%eax
	call	C(M_DrawPic)
	addl	$12,%esp

	movl	$0,-20(%ebp)
.Lvm_mode_loop:
	movl	-20(%ebp),%eax
	cmpl	-16(%ebp),%eax
	jge	.Lvm_modes_done
	cmpl	$1,%eax
	je	.Lvm_mode_next
	cmpl	$VM_MODE_COUNT,C(vid_wmodes)
	jge	.Lvm_mode_next
	pushl	%eax
#ifdef BENCH486
	call	C(Bench486VIDMenuGetModeDescription)
#else
	call	C(VID_GetModeDescription)
#endif
	addl	$4,%esp
	movl	%eax,-28(%ebp)
	testl	%eax,%eax
	je	.Lvm_mode_next
	movl	$0,-32(%ebp)
	movl	$0,-24(%ebp)
.Lvm_find_duplicate:
	movl	-24(%ebp),%eax
	cmpl	C(vid_wmodes),%eax
	jge	.Lvm_new_description
	leal	(%eax,%eax,2),%edx
	leal	C(vid_modedescs)(,%edx,4),%edx
	pushl	-28(%ebp)
	pushl	VM_MODE_DESCRIPTION_OFFSET(%edx)
	call	C(strcmp)
	addl	$8,%esp
	testl	%eax,%eax
	jne	.Lvm_duplicate_next
	movl	$1,-32(%ebp)
	movl	-24(%ebp),%eax
	leal	(%eax,%eax,2),%edx
	leal	C(vid_modedescs)(,%edx,4),%edx
	cmpl	$0,VM_MODE_MODE_NUMBER_OFFSET(%edx)
	je	.Lvm_duplicate_found
	movl	-20(%ebp),%eax
	movl	%eax,VM_MODE_MODE_NUMBER_OFFSET(%edx)
	cmpl	C(vid_modenum),%eax
	jne	.Lvm_duplicate_found
	movl	$1,VM_MODE_IS_CURRENT_OFFSET(%edx)
.Lvm_duplicate_found:
	jmp	.Lvm_mode_next
.Lvm_duplicate_next:
	incl	-24(%ebp)
	jmp	.Lvm_find_duplicate

.Lvm_new_description:
	cmpl	$0,-32(%ebp)
	jne	.Lvm_mode_next
	movl	C(vid_wmodes),%eax
	leal	(%eax,%eax,2),%edx
	leal	C(vid_modedescs)(,%edx,4),%edx
	movl	-20(%ebp),%eax
	movl	%eax,VM_MODE_MODE_NUMBER_OFFSET(%edx)
	movl	-28(%ebp),%eax
	movl	%eax,VM_MODE_DESCRIPTION_OFFSET(%edx)
	movl	$0,VM_MODE_IS_CURRENT_OFFSET(%edx)
	movl	-20(%ebp),%eax
	cmpl	C(vid_modenum),%eax
	/* Compare the mode index, not the description pointer. */
	jne	.Lvm_new_not_current
	movl	$1,VM_MODE_IS_CURRENT_OFFSET(%edx)
.Lvm_new_not_current:
	incl	C(vid_wmodes)

.Lvm_mode_next:
	incl	-20(%ebp)
	jmp	.Lvm_mode_loop

.Lvm_modes_done:
	movl	C(vid_wmodes),%eax
	addl	$2,%eax
	movl	$0xaaaaaaab,%edx
	mull	%edx
	shrl	$1,%edx
	movl	%edx,C(vid_column_size)

	movl	$0,-20(%ebp)
	movl	$16,-40(%ebp)
	movl	$36,-44(%ebp)
.Lvm_draw_modes:
	movl	-20(%ebp),%eax
	cmpl	C(vid_wmodes),%eax
	jge	.Lvm_mode_text
	leal	(%eax,%eax,2),%edx
	leal	C(vid_modedescs)(,%edx,4),%edx
	pushl	VM_MODE_DESCRIPTION_OFFSET(%edx)
	pushl	-44(%ebp)
	pushl	-40(%ebp)
	cmpl	$0,VM_MODE_IS_CURRENT_OFFSET(%edx)
	je	.Lvm_draw_unselected
	call	C(M_PrintWhite)
	jmp	.Lvm_after_print_mode
.Lvm_draw_unselected:
	call	C(M_Print)
.Lvm_after_print_mode:
	addl	$12,%esp
	addl	$8,-44(%ebp)
	movl	-20(%ebp),%eax
	xorl	%edx,%edx
	movl	C(vid_column_size),%ecx
	divl	%ecx
	decl	%ecx
	cmpl	%ecx,%edx
	jne	.Lvm_draw_next
	addl	$104,-40(%ebp)
	movl	$36,-44(%ebp)
.Lvm_draw_next:
	incl	-20(%ebp)
	jmp	.Lvm_draw_modes

.Lvm_mode_text:
	cmpl	$0,C(vid_testingmode)
	je	.Lvm_mode_not_testing
	movl	C(vid_line),%eax
	leal	(%eax,%eax,2),%edx
	leal	C(vid_modedescs)(,%edx,4),%edx
	pushl	VM_MODE_DESCRIPTION_OFFSET(%edx)
	pushl	$.Lvm_testing_format
	leal	-164(%ebp),%eax
	pushl	%eax
	call	C(sprintf)
	addl	$12,%esp
	leal	-164(%ebp),%eax
	pushl	%eax
	pushl	$156
	pushl	$104
	call	C(M_Print)
	addl	$12,%esp
	pushl	$.Lvm_wait_message
	pushl	$172
	pushl	$72
	call	C(M_Print)
	addl	$12,%esp
	jmp	.Lvm_done

.Lvm_mode_not_testing:
	pushl	$.Lvm_press_enter
	pushl	$132
	pushl	$72
	call	C(M_Print)
	addl	$12,%esp
	pushl	$.Lvm_test_mode
	pushl	$148
	pushl	$48
	call	C(M_Print)
	addl	$12,%esp
	pushl	C(vid_modenum)
#ifdef BENCH486
	call	C(Bench486VIDMenuGetModeDescription)
#else
	call	C(VID_GetModeDescription)
#endif
	addl	$4,%esp
	pushl	%eax
	pushl	$.Lvm_default_format
	leal	-164(%ebp),%eax
	pushl	%eax
	call	C(sprintf)
	addl	$12,%esp
	leal	-164(%ebp),%eax
	pushl	%eax
	pushl	$164
	pushl	$48
	call	C(M_Print)
	addl	$12,%esp

	fnstcw	-60(%ebp)
	movw	-60(%ebp),%dx
	orb	$12,%dh
	movw	%dx,-62(%ebp)
	fldcw	-62(%ebp)
	flds	C(_vid_default_mode)+16
	fistpl	-56(%ebp)
	fldcw	-60(%ebp)
	pushl	-56(%ebp)
#ifdef BENCH486
	call	C(Bench486VIDMenuGetModeDescription)
#else
	call	C(VID_GetModeDescription)
#endif
	addl	$4,%esp
	testl	%eax,%eax
	je	.Lvm_no_default_description
	pushl	%eax
	pushl	$.Lvm_current_default_format
	leal	-164(%ebp),%eax
	pushl	%eax
	call	C(sprintf)
	addl	$12,%esp
	leal	-164(%ebp),%eax
	pushl	%eax
	pushl	$172
	pushl	$56
	call	C(M_Print)
	addl	$12,%esp
.Lvm_no_default_description:
	pushl	$.Lvm_escape
	pushl	$188
	pushl	$120
	call	C(M_Print)
	addl	$12,%esp

	movl	C(vid_line),%eax
	cdq
	idivl	C(vid_column_size)
	imull	$8,%edx,%edx
	addl	$36,%edx
	movl	%edx,-44(%ebp)
	imull	$104,%eax,%eax
	addl	$8,%eax
	movl	%eax,-40(%ebp)

	/* int(realtime * 4) truncates after multiplication under the incoming CW. */
	fldl	C(realtime)
	fmull	.Lvm_four
	fnstcw	-60(%ebp)
	movw	-60(%ebp),%dx
	orb	$12,%dh
	movw	%dx,-62(%ebp)
	fldcw	-62(%ebp)
	fistpl	-56(%ebp)
	fldcw	-60(%ebp)
	movl	-56(%ebp),%eax
	andl	$1,%eax
	addl	$12,%eax
	pushl	%eax
	pushl	-44(%ebp)
	pushl	-40(%ebp)
	call	C(M_DrawCharacter)
	addl	$12,%esp

.Lvm_done:
	leal	-12(%ebp),%esp
	popl	%edi
	popl	%esi
	popl	%ebx
	popl	%ebp
	ret

.section .rodata
.p2align 2
.Lvm_mode_title:
	.asciz	"gfx/vidmodes.lmp"
.Lvm_testing_format:
	.asciz	"TESTING %s"
.Lvm_wait_message:
	.asciz	"Please wait 5 seconds..."
.Lvm_press_enter:
	.asciz	"Press Enter to set mode"
.Lvm_test_mode:
	.asciz	"T to test mode for 5 seconds"
.Lvm_default_format:
	.asciz	"D to make %s the default"
.Lvm_current_default_format:
	.asciz	"Current default is %s"
.Lvm_escape:
	.asciz	"Esc to exit"
.Lvm_four:
	.double	4.0
.Lmenu_page_ten:
	.float	10.0
.Lmenu_plaque:
	.asciz	"gfx/qplaque.lmp"
.Lmenu_main_title:
	.asciz	"gfx/ttl_main.lmp"
.Lmenu_main_content:
	.asciz	"gfx/mainmenu.lmp"
.Lmenu_singleplayer_title:
	.asciz	"gfx/ttl_sgl.lmp"
.Lmenu_singleplayer_content:
	.asciz	"gfx/sp_menu.lmp"
.Lmenu_multi_title:
	.asciz	"gfx/p_multi.lmp"
.Lmenu_setup_bigbox:
	.asciz	"gfx/bigbox.lmp"
.Lmenu_setup_player:
	.asciz	"gfx/menuplyr.lmp"
.Lmenu_setup_hostname_label:
	.asciz	"Hostname"
.Lmenu_setup_name_label:
	.asciz	"Your name"
.Lmenu_setup_shirt_label:
	.asciz	"Shirt color"
.Lmenu_setup_pants_label:
	.asciz	"Pants color"
.Lmenu_setup_accept_label:
	.asciz	"Accept Changes"
.Lmenu_multi_content:
	.asciz	"gfx/mp_menu.lmp"
.Lmenu_modem_pulse:
	.asciz	"Pulse Dialing"
.Lmenu_modem_touch:
	.asciz	"Touch Tone Dialing"
.Lmenu_modem_clear:
	.asciz	"Clear"
.Lmenu_modem_init_label:
	.asciz	"Init"
.Lmenu_modem_hangup_label:
	.asciz	"Hangup"
.Lmenu_modem_ok_label:
	.asciz	"OK"
.Lmenu_options_title:
	.asciz	"gfx/p_option.lmp"
.Lmenu_options_customize:
	.asciz	"    Customize controls"
.Lmenu_options_console:
	.asciz	"         Go to console"
.Lmenu_options_defaults:
	.asciz	"     Reset to defaults"
.Lmenu_options_screen_size:
	.asciz	"           Screen size"
.Lmenu_options_brightness:
	.asciz	"            Brightness"
.Lmenu_options_mouse_speed:
	.asciz	"           Mouse Speed"
.Lmenu_options_cd_volume:
	.asciz	"       CD Music Volume"
.Lmenu_options_sound_volume:
	.asciz	"          Sound Volume"
.Lmenu_options_always_run:
	.asciz	"            Always Run"
.Lmenu_options_invert_mouse:
	.asciz	"          Invert Mouse"
.Lmenu_options_lookspring:
	.asciz	"            Lookspring"
.Lmenu_options_lookstrafe:
	.asciz	"            Lookstrafe"
.Lmenu_options_video:
	.asciz	"         Video Options"
.Lmenu_options_on:
	.asciz	"on"
.Lmenu_options_off:
	.asciz	"off"
.p2align 2
.Lmenu_options_thirty:
	.float	30.0
.Lmenu_options_inv_ninety:
	.float	0.011111111111111112
.Lmenu_options_tenth:
	.float	0.1
.Lmenu_options_seventy_two:
	.float	72.0
.Lmenu_options_two_hundred:
	.float	200.0
.Lmenu_options_four:
	.float	4.0
.p2align 3
.Lmenu_modem_four:
	.double	4.0
.p2align 2
.Lmenu_net_modem:
	.asciz	"gfx/netmen1.lmp"
.Lmenu_net_direct_path:
	.asciz	"gfx/netmen2.lmp"
.Lmenu_net_ipx_path:
	.asciz	"gfx/netmen3.lmp"
.Lmenu_net_tcpip_path:
	.asciz	"gfx/netmen4.lmp"
.Lmenu_net_fifth:
	.asciz	"gfx/netmen5.lmp"
.Lmenu_net_dim_modem_pic:
	.asciz	"gfx/dim_modm.lmp"
.Lmenu_net_dim_direct_path:
	.asciz	"gfx/dim_drct.lmp"
.Lmenu_net_dim_ipx_path:
	.asciz	"gfx/dim_ipx.lmp"
.Lmenu_net_dim_tcpip_path:
	.asciz	"gfx/dim_tcp.lmp"
.Lmenu_no_communications:
	.asciz	"No Communications Available"
.Lmenu_dot_format:
	.asciz	"gfx/menudot%i.lmp"
.Lmenu_dot_1:
	.asciz	"gfx/menudot1.lmp"
.Lmenu_dot_2:
	.asciz	"gfx/menudot2.lmp"
.Lmenu_dot_3:
	.asciz	"gfx/menudot3.lmp"
.Lmenu_dot_4:
	.asciz	"gfx/menudot4.lmp"
.Lmenu_dot_5:
	.asciz	"gfx/menudot5.lmp"
.Lmenu_dot_6:
	.asciz	"gfx/menudot6.lmp"
.Lmenu_help_format:
	.asciz	"gfx/help%i.lmp"
.Lmenu_load_title:
	.asciz	"gfx/p_load.lmp"
.Lmenu_save_title:
	.asciz	"gfx/p_save.lmp"
.Lmenu_save_time_four:
	.float	4.0
.Lmenu_dispatch_sound:
	.asciz	"misc/menu2.wav"
.Lmenu_dispatch_states:
	.long	.Lmd_state_none
	.long	.Lmd_state_main
	.long	.Lmd_state_singleplayer
	.long	.Lmd_state_load
	.long	.Lmd_state_save
	.long	.Lmd_state_multiplayer
	.long	.Lmd_state_setup
	.long	.Lmd_state_net
	.long	.Lmd_state_options
	.long	.Lmd_state_video
	.long	.Lmd_state_keys
	.long	.Lmd_state_help
	.long	.Lmd_state_quit
	.long	.Lmd_state_serialconfig
	.long	.Lmd_state_modemconfig
	.long	.Lmd_state_lanconfig
	.long	.Lmd_state_gameoptions
	.long	.Lmd_state_search
	.long	.Lmd_state_serverlist

.Lmenu_box_tl:
	.asciz	"gfx/box_tl.lmp"
.Lmenu_box_ml:
	.asciz	"gfx/box_ml.lmp"
.Lmenu_box_bl:
	.asciz	"gfx/box_bl.lmp"
.Lmenu_box_tm:
	.asciz	"gfx/box_tm.lmp"
.Lmenu_box_mm:
	.asciz	"gfx/box_mm.lmp"
.Lmenu_box_mm2:
	.asciz	"gfx/box_mm2.lmp"
.Lmenu_box_bm:
	.asciz	"gfx/box_bm.lmp"
.Lmenu_box_tr:
	.asciz	"gfx/box_tr.lmp"
.Lmenu_box_mr:
	.asciz	"gfx/box_mr.lmp"
.Lmenu_box_br:
	.asciz	"gfx/box_br.lmp"

.Lmenu_keys_title:
	.asciz	"gfx/ttl_cstm.lmp"
.Lmenu_keys_prompt_grab:
	.asciz	"Press a key or button for this action"
.Lmenu_keys_prompt_enter:
	.asciz	"Enter to change, backspace to clear"
.Lmenu_keys_no_binding:
	.asciz	"???"
.Lmenu_keys_or:
	.asciz	"or"

.Lmenu_gameoptions_qplaque:
	.asciz	"gfx/qplaque.lmp"
.Lmenu_gameoptions_title:
	.asciz	"gfx/p_multi.lmp"
.Lmenu_gameoptions_integer:
	.asciz	"%i"
.Lmenu_gameoptions_frags:
	.asciz	"%i frags"
.Lmenu_gameoptions_minutes:
	.asciz	"%i minutes"
.Lmenu_gameoptions_begin:
	.asciz	"begin game"
.Lmenu_gameoptions_maxplayers:
	.asciz	"      Max players"
.Lmenu_gameoptions_game_type:
	.asciz	"        Game Type"
.Lmenu_gameoptions_cooperative:
	.asciz	"Cooperative"
.Lmenu_gameoptions_deathmatch:
	.asciz	"Deathmatch"
.Lmenu_gameoptions_teamplay_label:
	.asciz	"        Teamplay"
.Lmenu_gameoptions_no_friendly_fire:
	.asciz	"No Friendly Fire"
.Lmenu_gameoptions_friendly_fire:
	.asciz	"Friendly Fire"
.Lmenu_gameoptions_tag:
	.asciz	"Tag"
.Lmenu_gameoptions_capture_flag:
	.asciz	"Capture the Flag"
.Lmenu_gameoptions_one_flag:
	.asciz	"One Flag CTF"
.Lmenu_gameoptions_three_team:
	.asciz	"Three Team CTF"
.Lmenu_gameoptions_off:
	.asciz	"Off"
.Lmenu_gameoptions_skill:
	.asciz	"            Skill"
.Lmenu_gameoptions_easy:
	.asciz	"Easy difficulty"
.Lmenu_gameoptions_normal:
	.asciz	"Normal difficulty"
.Lmenu_gameoptions_hard:
	.asciz	"Hard difficulty"
.Lmenu_gameoptions_nightmare_label:
	.asciz	"Nightmare difficulty"
.Lmenu_gameoptions_frag_limit_label:
	.asciz	"       Frag Limit"
.Lmenu_gameoptions_time_limit_label:
	.asciz	"       Time Limit"
.Lmenu_gameoptions_none:
	.asciz	"none"
.Lmenu_gameoptions_episode_label:
	.asciz	"         Episode"
.Lmenu_gameoptions_level_label:
	.asciz	"           Level"
.Lmenu_gameoptions_server_info_1:
	.asciz	"  More than 4 players   "
.Lmenu_gameoptions_server_info_2:
	.asciz	" requires using command "
.Lmenu_gameoptions_server_info_3:
	.asciz	"line parameters; please "
.Lmenu_gameoptions_server_info_4:
	.asciz	"   see techinfo.txt.    "

.Lmenu_search_draw_multi_title:
	.asciz	"gfx/p_multi.lmp"
.Lmenu_lanconfig_new_game:
	.asciz	"New Game"
.Lmenu_lanconfig_join_game:
	.asciz	"Join Game"
.Lmenu_lanconfig_ipx:
	.asciz	"IPX"
.Lmenu_lanconfig_tcpip:
	.asciz	"TCP/IP"
.Lmenu_lanconfig_title_format:
	.asciz	"%s - %s"
.Lmenu_lanconfig_address:
	.asciz	"Address:"
.Lmenu_lanconfig_port:
	.asciz	"Port"
.Lmenu_lanconfig_search:
	.asciz	"Search for local games..."
.Lmenu_lanconfig_join_at:
	.asciz	"Join game at:"
.Lmenu_lanconfig_ok:
	.asciz	"OK"
.Lmenu_search_draw_searching:
	.asciz	"Searching..."
.Lmenu_search_draw_no_servers_text:
	.asciz	"No Quake servers found"

.p2align 3
.Lmenu_keys_four:
	.double	4.0
.Lmenu_gameoptions_four:
	.double	4.0
.Lmenu_gameoptions_five:
	.double	5.0
.Lmenu_gameoptions_float_zero:
	.float	0.0
.Lmenu_gameoptions_float_one:
	.float	1.0
.Lmenu_gameoptions_float_two:
	.float	2.0
.Lmenu_search_draw_three:
	.float	3.0

.Lso_pause_path:
	.asciz	"gfx/pause.lmp"
.Lso_loading_path:
	.asciz	"gfx/loading.lmp"

#endif
