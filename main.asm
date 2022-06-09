.386                                      ; create 32 bit code
.model flat, stdcall                      ; 32 bit memory model
option casemap :none                      ; case sensitive 

include windows.inc       ; main windows include file
include masm32.inc        ; masm32 library include

; -------------------------
; Windows API include files
; -------------------------
include gdi32.inc
include user32.inc
include kernel32.inc
include Comctl32.inc
include comdlg32.inc
include shell32.inc
include oleaut32.inc
include ole32.inc
include msvcrt.inc
include	winmm.inc

include dialogs.inc       ; macro file for dialogs
include C:\masm32\macros\macros.asm         ; masm32 macro file


includelib masm32.lib         ; masm32 static library

; ------------------------------------------
; import libraries for Windows API functions
; ------------------------------------------
;includelib di32.lib
includelib user32.lib
includelib kernel32.lib
includelib Comctl32.lib
includelib comdlg32.lib
includelib shell32.lib
includelib oleaut32.lib
includelib ole32.lib
includelib msvcrt.lib
includelib ucrt.lib
includelib winmm.lib


Dot	STRUCT
	x	dd	?
	y	dd	?
Dot	ENDS


.data
player	Dot<>
dotb1	Dot<>
dotb2	Dot<>
dotb3	Dot<>
dotb4	Dot<>
dotb5	Dot<>
isup	db	0
isdown	db	0
isleft	db	0
isright	db	0
former	db	0
gameSpeed dd 66
state	dd  1		;1开始界面，2游戏界面，3死亡界面，4过关界面
round   dd  1		;记录第几关
text_start		db  'PRESS ENTER TO START ! ',0
text_end		db	'YOU LOSE ! PRESS ENTER TO RESTART ! ',0
playingTime		dd	0
.data?
hInstance		dd	?
hWinMain		dd	?
text_x			db	10 dup(?)
text_y			db	10 dup(?)
text_round		db	10 dup(?)
text_time		db	10 dup(?)
rseed			dd  ?

speed           dd	?

;主人公的动作
hBmdown1	DWORD	?
hBmdown2	DWORD	?
hBmup1		DWORD	?
hBmup2		DWORD	?
hBmleft1	DWORD	?
hBmleft2	DWORD	?
hBmright1	DWORD	?
hBmright2	DWORD	?
hBmnormal	DWORD	?
;三种敌人
hBmgirl		DWORD	?
hBmzombie	DWORD	?
hBmrobot	DWORD	?
;三种背景
hBmbkg1		DWORD	?
hBmbkg2		DWORD	?
hBmbkg3		DWORD	?
mDc HDC		?
hBegin		DWORD	?
hEnd		DWORD	?

hBmenemy		DWORD	?
hBmbkg			DWORD	?

.const
szClassName		db	'MyClass', 0
szCaptionMain	db	'橄榄球、死亡与机器人', 0
szShow			db	'win32 assembly',0 ;叫szText会报错
edit			db	'edit', 0
formatNum		db	'ROUND %d', 0
szFail          db  '发生碰撞',0ah, 0
formatTime		db	'%d s', 0
defenH			dd	55
defenW			dd	45
plyH			dd	62
plyW			dd	49
pSpeed			dd	5
windowH			dd	600
windowW			dd	800
ROUND_TEXT		equ	99
START_TEXT		EQU 98
END_TEXT		EQU 97
TIME_TEXT		equ 96
;************************
ID_TEXTX	equ		0100h
ID_TIMER	equ		0200h
ID_TEXTY	equ		0300h
ID_TIMER2	equ		0400h
;************************
;三种背景
IDB_BKG1	equ		100
IDB_BKG2    equ		101
IDB_BKG3	equ		102

;主人公的动作
IDB_DOWN1	equ		109
IDB_DOWN2	equ		110
IDB_UP1     equ		111
IDB_UP2     equ		112
IDB_LEFT1   equ		113
IDB_LEFT2   equ		114
IDB_RIGHT1  equ		115
IDB_RIGHT2  equ		116
IDB_BITMAP1 equ		117
IDB_NORMAL  equ		118

;三种敌人
IDB_GIRL   equ		120
IDB_ZOMBIE  equ		121
IDB_ROBOT   equ		122

;开始和结束页面
IDB_BEGIN  equ		127
IDB_END   equ		128

;音乐
IDR_WAVE1	equ		129

.code
;rand PROTO C:DWORD
_ProcTimer	proc _hWnd, uMsg, _idEvent, _dwTime
			pushad

			;只需要修改这里
			add		playingTime,1
			invoke	wsprintf, addr text_time, addr formatTime, playingTime
			invoke	GetDlgItem, hWinMain, TIME_TEXT
			invoke	SendMessage, eax, WM_SETTEXT, NULL, addr text_time


			popad
			ret
_ProcTimer	endp

ChangeRound proc uses eax
			;改敌人和背景，三种场景轮流
			mov edx, 0
			mov eax, round
			mov ebx, 3
			div ebx
			.if edx == 1
				mov eax, hBmbkg1
				mov hBmbkg, eax
				mov eax, hBmgirl
				mov hBmenemy, eax
			.elseif edx == 2
				mov eax, hBmbkg2
				mov hBmbkg,eax
				mov eax, hBmzombie
				mov hBmenemy, eax
			.elseif edx == 0
				mov eax, hBmbkg3
				mov hBmbkg,eax
				mov eax, hBmrobot
				mov hBmenemy, eax
			.endif
			ret
ChangeRound endp

Random proc uses ecx edx,range:DWORD
	call crt_rand
	;inc eax
	mov rseed, eax
    ;inc rseed
	;mov eax, rseed
	mov ecx, 23
	mul ecx
	add eax, 7
	and eax, 0FFFFFFFFh
	ror eax, 1
	xor eax, rseed
	;mov rseed, eax
	mov ecx, range
	xor edx, edx
	div ecx
	mov eax, edx
	ret

Random endp

CreateBitmapMask proc hbmp:HBITMAP
				local hdcm1:HDC
				local hdcm2:HDC
				local bm1:BITMAP
				local hbmMask:HBITMAP

				invoke GetObject, hbmp, sizeof BITMAP, addr bm1
				invoke CreateBitmap, bm1.bmWidth, bm1.bmHeight, 1, 1, NULL
				mov hbmMask, eax
				invoke CreateCompatibleDC, 0
				mov hdcm1, eax
				invoke CreateCompatibleDC, 0
				mov hdcm2, eax
				INVOKE SelectObject, hdcm1, hbmp
				invoke SelectObject, hdcm2, hbmMask
				invoke SetBkColor, hdcm1, 0
				invoke BitBlt, hdcm2, 0, 0, bm1.bmWidth, bm1.bmHeight, hdcm1, 0, 0, SRCCOPY
				invoke BitBlt, hdcm1, 0, 0, bm1.bmWidth, bm1.bmHeight, hdcm2, 0, 0, SRCINVERT
				invoke DeleteDC, hdcm1
				invoke DeleteDC, hdcm2
				mov edx, hbmMask
				ret
CreateBitmapMask endp

_ProcWinMain	proc	uses ebx edi esi, hWnd, uMsg, wParam, lParam
			local	@stPs:PAINTSTRUCT
			local	@stRect:RECT
			local	@hDc:HDC
			local	@hDc_old:HDC
			local	hBmp:HBITMAP
			local	bm:BITMAP
			local	hPen:HPEN
			local	hBmpMask:HBITMAP

			mov	eax, uMsg

			.if		eax	==	WM_PAINT
					invoke BeginPaint, hWnd, addr @stPs
					mov	@hDc_old, eax
					invoke CreateCompatibleDC,@hDc_old
					mov	@hDc,eax
					invoke GetClientRect, hWnd, addr @stRect
					invoke CreateCompatibleBitmap, @hDc_old, @stRect.right, @stRect.bottom
					mov hBmp, eax
					invoke SelectObject, @hDc, hBmp
					invoke CreatePen, PS_SOLID, 1, 0
					mov hPen, eax
					
					invoke SelectObject, @hDc, hPen
					invoke Rectangle, @hDc, @stRect.left, @stRect.top,@stRect.right, @stRect.bottom
					invoke DeleteObject, hPen

					invoke SelectObject, mDc, hBmbkg
					invoke GetObject, hBmbkg, sizeof BITMAP, addr bm
					invoke BitBlt, @hDc, 0, 0, bm.bmWidth, bm.bmHeight, mDc, 0, 0, SRCCOPY
	
					;绘制障碍物
					invoke CreateBitmapMask,  hBmenemy
					mov hBmpMask,edx

					invoke SelectObject, mDc, hBmpMask
					invoke GetObject, hBmpMask, sizeof BITMAP, addr bm
					invoke BitBlt, @hDc, dotb1.x, dotb1.y, bm.bmWidth, bm.bmHeight, mDc, 0, 0, SRCAND
					invoke SelectObject, mDc, hBmenemy
					invoke GetObject, hBmenemy, sizeof BITMAP, addr bm
					invoke BitBlt, @hDc, dotb1.x, dotb1.y, bm.bmWidth, bm.bmHeight, mDc, 0, 0, SRCPAINT

					invoke SelectObject, mDc, hBmpMask
					invoke BitBlt, @hDc, dotb2.x, dotb2.y, bm.bmWidth, bm.bmHeight, mDc, 0, 0, SRCAND
					invoke SelectObject, mDc, hBmenemy
					invoke GetObject,hBmenemy, sizeof BITMAP, addr bm
					invoke BitBlt, @hDc, dotb2.x, dotb2.y, bm.bmWidth, bm.bmHeight, mDc, 0, 0, SRCPAINT

					invoke SelectObject, mDc, hBmpMask
					invoke BitBlt, @hDc, dotb3.x, dotb3.y, bm.bmWidth, bm.bmHeight, mDc, 0, 0, SRCAND
					invoke SelectObject, mDc, hBmenemy
					invoke GetObject,hBmenemy, sizeof BITMAP, addr bm
					invoke BitBlt, @hDc, dotb3.x, dotb3.y, bm.bmWidth, bm.bmHeight, mDc, 0, 0, SRCPAINT

					invoke SelectObject, mDc, hBmpMask
					invoke BitBlt, @hDc, dotb4.x, dotb4.y, bm.bmWidth, bm.bmHeight, mDc, 0, 0, SRCAND
					invoke SelectObject, mDc, hBmenemy
					invoke GetObject, hBmenemy, sizeof BITMAP, addr bm
					invoke BitBlt, @hDc, dotb4.x, dotb4.y, bm.bmWidth, bm.bmHeight, mDc, 0, 0, SRCPAINT

					invoke SelectObject, mDc, hBmpMask
					invoke BitBlt, @hDc, dotb5.x, dotb5.y, bm.bmWidth, bm.bmHeight, mDc, 0, 0, SRCAND
					invoke SelectObject, mDc,hBmenemy
					invoke GetObject, hBmenemy, sizeof BITMAP, addr bm
					invoke BitBlt, @hDc, dotb5.x, dotb5.y, bm.bmWidth, bm.bmHeight, mDc, 0, 0, SRCPAINT

;					invoke SelectObject,mDc,eax


					.if isdown == 1 || former == 1
						mov former, 1
						mov eax, player.y
						mov ebx, 2
						div ebx
						.if edx == 1
							invoke CreateBitmapMask,  hBmdown1
							mov hBmpMask,edx
							invoke SelectObject, mDc, hBmpMask
							invoke BitBlt, @hDc, player.x, player.y, bm.bmWidth, bm.bmHeight, mDc, 0, 0, SRCAND
							invoke SelectObject, mDc, hBmdown1
							invoke GetObject, hBmdown1, sizeof BITMAP, addr bm
						.else
							invoke CreateBitmapMask,  hBmdown2
							mov hBmpMask,edx
							invoke SelectObject, mDc, hBmpMask
							invoke BitBlt, @hDc, player.x, player.y, bm.bmWidth, bm.bmHeight, mDc, 0, 0, SRCAND
							invoke SelectObject, mDc, hBmdown2
							invoke GetObject, hBmdown2, sizeof BITMAP, addr bm
						.endif

					.elseif isup == 1 || former == 2
						mov former, 2
						mov eax, player.y
						mov ebx, 2
						div ebx
						.if edx == 1
							invoke CreateBitmapMask,  hBmup1
							mov hBmpMask,edx
							invoke SelectObject, mDc, hBmpMask
							invoke BitBlt, @hDc, player.x, player.y, bm.bmWidth, bm.bmHeight, mDc, 0, 0, SRCAND
							invoke SelectObject, mDc, hBmup1
							invoke GetObject, hBmup1, sizeof BITMAP, addr bm
						.else
							invoke CreateBitmapMask,  hBmup2
							mov hBmpMask,edx
							invoke SelectObject, mDc, hBmpMask
							invoke BitBlt, @hDc, player.x, player.y, bm.bmWidth, bm.bmHeight, mDc, 0, 0, SRCAND
							invoke SelectObject, mDc, hBmup2
							invoke GetObject, hBmup2, sizeof BITMAP, addr bm
						.endif

					.elseif isleft == 1 || former == 3
						mov former, 3
						mov eax, player.x
						mov ebx, 2
						div ebx
						.if edx == 1
							invoke CreateBitmapMask,  hBmleft1
							mov hBmpMask,edx
							invoke SelectObject, mDc, hBmpMask
							invoke BitBlt, @hDc, player.x, player.y, bm.bmWidth, bm.bmHeight, mDc, 0, 0, SRCAND
							invoke SelectObject, mDc, hBmleft1
							invoke GetObject, hBmleft1, sizeof BITMAP, addr bm
						.else
							invoke CreateBitmapMask,  hBmleft2
							mov hBmpMask,edx
							invoke SelectObject, mDc, hBmpMask
							invoke BitBlt, @hDc, player.x, player.y, bm.bmWidth, bm.bmHeight, mDc, 0, 0, SRCAND
							invoke SelectObject, mDc, hBmleft2
							invoke GetObject, hBmleft2, sizeof BITMAP, addr bm
						.endif

					.elseif isright == 1 || former == 4
						mov former, 4
						mov eax, player.x
						mov ebx, 2
						div ebx
						.if edx == 1
							invoke CreateBitmapMask,  hBmright1
							mov hBmpMask,edx
							invoke SelectObject, mDc, hBmpMask
							invoke BitBlt, @hDc, player.x, player.y, bm.bmWidth, bm.bmHeight, mDc, 0, 0, SRCAND
							invoke SelectObject, mDc, hBmright1
							invoke GetObject, hBmright1, sizeof BITMAP, addr bm
						.else
							invoke CreateBitmapMask,  hBmright2
							mov hBmpMask,edx
							invoke SelectObject, mDc, hBmpMask
							invoke BitBlt, @hDc, player.x, player.y, bm.bmWidth, bm.bmHeight, mDc, 0, 0, SRCAND
							invoke SelectObject, mDc, hBmright2
							invoke GetObject, hBmright2, sizeof BITMAP, addr bm
						.endif

					.else
						invoke CreateBitmapMask, hBmnormal
						mov hBmpMask,edx
						invoke SelectObject, mDc, hBmpMask
						invoke BitBlt, @hDc, player.x, player.y, bm.bmWidth, bm.bmHeight, mDc, 0, 0, SRCAND
						invoke SelectObject, mDc, hBmnormal
						invoke GetObject, hBmnormal, sizeof BITMAP, addr bm

					.endif
					invoke BitBlt, @hDc, player.x, player.y, bm.bmWidth, bm.bmHeight, mDc, 0, 0, SRCPAINT
					invoke BitBlt, @hDc_old, 0, 0,@stRect.right, @stRect.bottom, @hDc, 0, 0, SRCCOPY
					invoke DeleteObject, hBmp
					invoke DeleteDC, @hDc
					invoke ReleaseDC, hWnd, @hDc
					invoke EndPaint, hWnd, addr @stPs

					mov isup,0
					mov isdown,0
					mov isright,0
					mov isleft,0

			.elseif	eax == WM_CREATE	
				
				mov speed,	6

			    inc rseed
				;人点的初始化
				mov	eax,	windowH
				sub	eax,	plyH
				mov		player.x,	300
				mov		player.y,	eax

				;障碍物初始位置
				mov	ebx,	windowW
				sub	ebx,	defenW
				invoke	Random,		ebx
				mov		dotb1.x,	eax
				mov		dotb1.y,	0
				invoke	Random,		ebx
				mov		dotb2.x,	eax
				mov		dotb2.y,	100
				invoke	Random,		ebx
				mov		dotb3.x,	eax
				mov		dotb3.y,	200
				invoke	Random,		ebx
				mov		dotb4.x,	eax
				mov		dotb4.y,	300
				invoke	Random,		ebx
				mov		dotb5.x,	eax
				mov		dotb5.y,	400

				invoke CreateWindowEx, NULL, offset edit, offset text_round, \
				WS_CHILD + WS_VISIBLE + ES_RIGHT + ES_READONLY, 0, 0, 70, 20, \ 
				hWnd, ROUND_TEXT, hInstance, NULL

				invoke CreateWindowEx, NULL, offset edit, offset text_time, \
				WS_CHILD + WS_VISIBLE + ES_RIGHT + ES_READONLY, 700, 0, 50, 20, \ 
				hWnd, TIME_TEXT, hInstance, NULL

				invoke CreateWindowEx, NULL, offset edit, offset text_start, \
				WS_CHILD + WS_VISIBLE + ES_RIGHT + ES_READONLY, 300, 400,180, 20, \ 
				hWnd, START_TEXT, hInstance, NULL

				invoke CreateWindowEx, NULL, offset edit, offset text_end, \
				WS_CHILD + WS_VISIBLE + ES_RIGHT + ES_READONLY, 300, 400,0, 0, \ 
				hWnd, END_TEXT, hInstance, NULL

				invoke GetDC, hWnd
				mov @hDc, eax
				invoke CreateCompatibleDC,@hDc
				mov	mDc,eax
				invoke ReleaseDC, hWnd, @hDc

				;音乐
				invoke PlaySound, IDR_WAVE1, hWinMain, SND_RESOURCE+SND_LOOP+SND_ASYNC
				ret

			.elseif	eax == WM_CLOSE
				invoke	DestroyWindow, hWinMain
				invoke	PostQuitMessage, NULL
				ret

			.elseif eax == WM_TIMER
				.if state == 2	;游戏已开始
				INVOKE	GetAsyncKeyState, VK_W
				test	eax,	8000h
				mov		ebx,	pSpeed
				.if		!ZERO?
						.if		player.y >= ebx
							sub		player.y, ebx
							mov		isup, 1
							mov		former, 2
							.endif
						.endif
				INVOKE	GetAsyncKeyState, VK_A
				test	eax,8000h
				.if		!ZERO?
						.if		player.x >= ebx
							sub		player.x, ebx
							mov		isleft, 1
							mov		former, 3
							.endif
						.endif
				INVOKE	GetAsyncKeyState, VK_S
				test	eax,8000h
				.if		!ZERO?
						.if		player.y <= 546	;windowH-plyH-pSpeed
							add		player.y, ebx
							mov		isdown, 1
							mov		former, 1
							.endif
						.endif
				INVOKE	GetAsyncKeyState, VK_D
				test	eax,8000h
				.if		!ZERO?
						.if		player.x <= 746	;windowW-plyW-pSpeed
							add		player.x, ebx
							mov		isright,1
							mov		former, 4
							.endif
						.endif
				invoke	wsprintf, addr text_round, addr formatNum, round
				invoke	GetDlgItem, hWnd, ROUND_TEXT
				invoke	SendMessage, eax, WM_SETTEXT, NULL, addr text_round
				;invoke	GetDlgItem, hWnd, ID_TEXTY
				;invoke	SendMessage, eax, WM_SETTEXT, NULL, addr text_y
		
				;碰撞检测
				mov	eax,	dotb1.x
				mov	ebx,	dotb1.y
				sub	ebx,	plyH
				.if	player.y >= ebx
				add	ebx,	plyH
				add	ebx,	defenH
					.if	player.y <= ebx
						sub	eax,	plyW
						.if	player.x >= eax
							add	eax,	plyW
							add	eax,	defenW
							.if	player.x <= eax
								invoke crt_printf, offset szFail	;发生碰撞
								mov state,3
								ret
							.endif
						.endif
					.endif
				.endif
				mov	eax,	dotb2.x
				mov	ebx,	dotb2.y
				sub	ebx,	plyH
				.if	player.y >= ebx
				add	ebx,	plyH
				add	ebx,	defenH
					.if	player.y <= ebx
						sub	eax,	plyW
						.if	player.x >= eax
							add	eax,	plyW
							add	eax,	defenW
							.if	player.x <= eax
								invoke crt_printf, offset szFail	;发生碰撞
								mov state,3
								ret
							.endif
						.endif
					.endif
				.endif
				mov	eax,	dotb3.x
				mov	ebx,	dotb3.y
				sub	ebx,	plyH
				.if	player.y >= ebx
				add	ebx,	plyH
				add	ebx,	defenH
					.if	player.y <= ebx
						sub	eax,	plyW
						.if	player.x >= eax
							add	eax,	plyW
							add	eax,	defenW
							.if	player.x <= eax
								invoke crt_printf, offset szFail	;发生碰撞
								mov state, 3
								ret
							.endif
						.endif
					.endif
				.endif
				mov	eax,	dotb4.x
				mov	ebx,	dotb4.y
				sub	ebx,	plyH
				.if	player.y >= ebx
				add	ebx,	plyH
				add	ebx,	defenH
					.if	player.y <= ebx
						sub	eax,	plyW
						.if	player.x >= eax
							add	eax,	plyW
							add	eax,	defenW
							.if	player.x <= eax
								invoke crt_printf, offset szFail	;发生碰撞
								mov state, 3
								ret
							.endif
						.endif
					.endif
				.endif
				mov	eax,	dotb5.x
				mov	ebx,	dotb5.y
				sub	ebx,	plyH
				.if	player.y >= ebx
				add	ebx,	plyH
				add	ebx,	defenH
					.if	player.y <= ebx
						sub	eax,	plyW
						.if	player.x >= eax
							add	eax,	plyW
							add	eax,	defenW
							.if	player.x <= eax
								invoke crt_printf, offset szFail	;发生碰撞
								mov state, 3
								ret
							.endif
						.endif
					.endif
				.endif
				
				;障碍物轮回
				mov	eax,	windowH
				mov	ebx,	windowW
				sub	ebx,	defenW
				.if	dotb1.y > eax
					mov	dotb1.y,	0
					invoke Random,	ebx
					mov	dotb1.x,	eax
				.endif
				mov	eax,	windowH
				.if	dotb2.y > eax
					mov	dotb2.y,	0
					invoke Random,	ebx
					mov	dotb2.x,	eax
				.endif
				mov	eax,	windowH
				.if	dotb3.y > eax
					mov	dotb3.y,	0
					invoke Random,	ebx
					mov	dotb3.x,	eax
				.endif
				mov	eax,	windowH
				.if	dotb4.y > eax
					mov	dotb4.y,	0
					invoke Random,	ebx
					mov	dotb4.x,	eax
				.endif
				mov	eax,	windowH
				.if	dotb5.y > eax
					mov	dotb5.y,	0
					invoke Random,	ebx
					mov	dotb5.x,	eax
				.endif

				;障碍物整体移动
				;纵向移动
				invoke	Random, speed
				add	dotb1.y,	eax
				invoke	Random, speed
				add	dotb2.y,	eax
				invoke	Random, speed
				add	dotb3.y,	eax
				invoke	Random, speed
				add	dotb4.y,	eax
				invoke	Random, speed
				add	dotb5.y,	eax
				;横向移动
				invoke	Random, speed
				mov	ebx,	player.x
				.if	ebx > dotb1.x
					add	dotb1.x,	eax
				.else
					sub	dotb1.x,	eax
				.endif
				invoke	Random, speed
				.if	ebx > dotb2.x
					add	dotb2.x,	eax
				.else
					sub	dotb2.x,	eax
				.endif
				invoke	Random, speed
				.if	ebx > dotb3.x
					add	dotb3.x,	eax
				.else
					sub	dotb3.x,	eax
				.endif
				invoke	Random, speed
				.if	ebx > dotb4.x
					add	dotb4.x,	eax
				.else
					sub	dotb4.x,	eax
				.endif
				invoke	Random, speed
				.if	ebx > dotb5.x
					add	dotb5.x,	eax
				.else
					sub	dotb5.x,	eax
				.endif

				;过关检测
				.if		player.y <= 10

						;player初始化位置
						mov	eax,	windowH
						sub	eax,	plyH
						mov		player.x,	300
						mov		player.y,	eax
						;障碍物初始化位置
						mov	ebx,	windowW
						sub	ebx,	defenW
						invoke	Random,		ebx
						mov		dotb1.x,	eax
						mov		dotb1.y,	0
						invoke	Random,		ebx
						mov		dotb2.x,	eax
						mov		dotb2.y,	100
						invoke	Random,		ebx
						mov		dotb3.x,	eax
						mov		dotb3.y,	200
						invoke	Random,		ebx
						mov		dotb4.x,	eax
						mov		dotb4.y,	300
						invoke	Random,		ebx
						mov		dotb5.x,	eax
						mov		dotb5.y,	400

						add		round, 1
						;mov		playingTime, 0
						invoke KillTimer,hWnd, ID_TIMER2
						invoke	wsprintf, addr text_time, addr formatTime, playingTime
						invoke	GetDlgItem, hWinMain, TIME_TEXT
						invoke	SendMessage, eax, WM_SETTEXT, NULL, addr text_time
						invoke	ChangeRound
						;.if		gameSpeed>=50
								invoke KillTimer, hWinMain, ID_TIMER
								mov		eax, gameSpeed
								shr		eax, 1
								mov		gameSpeed, eax
								invoke SetTimer, hWinMain, ID_TIMER, gameSpeed, NULL
						;.endif
						;invoke SendMessage,hWnd,WM_CREATE,0,0
						mov	state,	4
				.endif
				.elseif state == 3
						invoke	GetDlgItem, hWnd, END_TEXT
						invoke	MoveWindow, eax, 220, 300,280,20,TRUE
						invoke KillTimer,hWnd, ID_TIMER2
				.endif
				invoke InvalidateRect,hWnd,NULL,FALSE
				ret

			.elseif eax == WM_KEYDOWN
				mov		eax, wParam
				mov		former, 0
				.if			eax == VK_SPACE	
					invoke KillTimer, hWinMain, ID_TIMER
					sub gameSpeed, 100
					invoke SetTimer, hWinMain, ID_TIMER, gameSpeed, NULL
					mov playingTime, 0
				.elseif		eax == VK_RETURN
					;计时器开始
					invoke	SetTimer, hWnd, ID_TIMER2, 1000, addr _ProcTimer
					.if state == 1		;restart
						;invoke SendMessage,hWnd,WM_CREATE,0,0

						;player初始化位置
						mov	eax,	windowH
						sub	eax,	plyH
						mov		player.x,	300
						mov		player.y,	eax
						;障碍物初始化位置
						mov	ebx,	windowW
						sub	ebx,	defenW
						invoke	Random,		ebx
						mov		dotb1.x,	eax
						mov		dotb1.y,	0
						invoke	Random,		ebx
						mov		dotb2.x,	eax
						mov		dotb2.y,	100
						invoke	Random,		ebx
						mov		dotb3.x,	eax
						mov		dotb3.y,	200
						invoke	Random,		ebx
						mov		dotb4.x,	eax
						mov		dotb4.y,	300
						invoke	Random,		ebx
						mov		dotb5.x,	eax
						mov		dotb5.y,	400

						;弹窗消失
						invoke	GetDlgItem, hWnd, START_TEXT
						invoke	MoveWindow, eax, 0,0,0,0,TRUE

						mov state,	2
					.elseif	state == 3
						invoke	GetDlgItem, hWnd, END_TEXT
						invoke	MoveWindow, eax,0,0,0,0,TRUE
						mov state,	1
					.elseif state == 4
						mov state,	2
					.endif
				.endif
				ret
			.else
				invoke	DefWindowProc, hWnd, uMsg, wParam, lParam
				ret
			.endif
			xor	eax,eax
			ret
_ProcWinMain	endp

_WinMain		proc
			local	@stWndClass:WNDCLASSEX
			local	@stMsg:MSG

			invoke	GetModuleHandle, NULL
			mov		hInstance, eax
			invoke	RtlZeroMemory, addr @stWndClass, sizeof @stWndClass
			
			;加载图像
			invoke LoadBitmap,hInstance,IDB_DOWN1
			mov	hBmdown1,eax
			invoke LoadBitmap,hInstance,IDB_DOWN2
			mov	hBmdown2,eax
			invoke LoadBitmap,hInstance,IDB_UP1
			mov	hBmup1,eax
			invoke LoadBitmap,hInstance,IDB_UP2
			mov	hBmup2,eax
			invoke LoadBitmap,hInstance,IDB_LEFT1
			mov	hBmleft1,eax
			invoke LoadBitmap,hInstance,IDB_LEFT2
			mov	hBmleft2,eax
			invoke LoadBitmap,hInstance,IDB_RIGHT1
			mov	hBmright1,eax
			invoke LoadBitmap,hInstance,IDB_RIGHT2
			mov	hBmright2,eax
			invoke LoadBitmap,hInstance,IDB_NORMAL
			mov	hBmnormal,eax
			invoke LoadBitmap,hInstance,IDB_BKG1
			mov	hBmbkg1,eax
			invoke LoadBitmap,hInstance,IDB_BKG2
			mov	hBmbkg2,eax
			invoke LoadBitmap,hInstance,IDB_BKG3
			mov	hBmbkg3,eax
			invoke LoadBitmap,hInstance,IDB_GIRL
			mov	hBmgirl,eax
			invoke LoadBitmap,hInstance,IDB_ZOMBIE
			mov	hBmzombie,eax
			invoke LoadBitmap,hInstance,IDB_ROBOT
			mov	hBmrobot,eax

			invoke LoadBitmap,hInstance,IDB_BEGIN
			mov	hBegin,eax
			invoke LoadBitmap,hInstance,IDB_END
			mov	hEnd,eax

			invoke	wsprintf, addr text_time, addr formatTime, playingTime
			invoke	GetDlgItem, hWinMain, TIME_TEXT
			invoke	SendMessage, eax, WM_SETTEXT, NULL, addr text_time
			invoke	ChangeRound

			invoke	LoadCursor, 0, IDC_ARROW
			mov		@stWndClass.hCursor, eax
			push	hInstance
			pop		@stWndClass.hInstance
			mov		@stWndClass.cbSize, sizeof WNDCLASSEX
			mov		@stWndClass.style, CS_HREDRAW or CS_VREDRAW
			mov		@stWndClass.lpfnWndProc, offset _ProcWinMain
			mov		@stWndClass.hbrBackground, COLOR_WINDOW+1
			mov		@stWndClass.lpszClassName, offset szClassName
			invoke	RegisterClassEx, addr @stWndClass
			invoke	CreateWindowEx, WS_EX_CLIENTEDGE, \
					offset szClassName, offset szCaptionMain, \
					WS_OVERLAPPEDWINDOW, \
					0,0,818,650, \
					NULL, NULL, hInstance, NULL
			mov		hWinMain, eax
			invoke	ShowWindow, hWinMain, SW_SHOWNORMAL
			invoke	SetTimer, hWinMain, ID_TIMER, gameSpeed, NULL

			invoke	UpdateWindow, hWinMain

			.while		TRUE
					invoke	GetMessage, addr @stMsg, NULL, 0, 0
							.break .if eax == 0
					invoke	TranslateMessage, addr @stMsg
					invoke	DispatchMessage, addr @stMsg
					.endw
					ret
_WinMain				endp

start:
			call	_WinMain
			invoke	ExitProcess, NULL
			end 	start
				;按键消息发送周期不知道