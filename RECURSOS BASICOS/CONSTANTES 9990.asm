;;;;;;;;;;;;;;;;;;; G9K CONSTANTES INICIO

; Mode select defines for SetScreenMode

G9K_MODE_P1			EQU	0	; Pattern mode 0 256 212
G9K_MODE_P2			EQU	1	; Pattern mode 1 512 212
G9K_MODE_B1			EQU	2	; Bitmap mode 1 256 212
G9K_MODE_B2			EQU	3	; Bitmap mode 2 384 240
G9K_MODE_B3			EQU	4	; Bitmap mode 3 512 212
G9K_MODE_B4			EQU	5	; Bitmap mode 4 768 240
G9K_MODE_B5			EQU	6	; Bitmap mode 5 640 400 (VGA)
G9K_MODE_B6			EQU	7	; Bitmap mode 6 640 480 (VGA)
G9K_MODE_B7			EQU	8	; Bitmap mode 7 1024 212 (Undocumented v9990 mode)

; Bit defines G9K_SCREEN_MODE0 (register 6)

G9K_SCR0_STANDBY	EQU	192	; Stand by mode
G9K_SCR0_BITMAP		EQU	128	; Select Bit map mode
G9K_SCR0_P2			EQU	64	; Select P1 mode
G9K_SCR0_P1			EQU	0	; Select P1 mode
G9K_SCR0_DTCLK		EQU	32	; Master Dot clock not divided
G9K_SCR0_DTCLK2		EQU	16	; Master Dot clock divided by 2
G9K_SCR0_DTCLK4		EQU	0	; Master Dot clock divided by 4
G9K_SCR0_XIM2048	EQU	12	; Image size = 2048
G9K_SCR0_XIM1024	EQU	8	; Image size = 1024
G9K_SCR0_XIM512		EQU	4	; Image size = 512
G9K_SCR0_XIM256		EQU	0	; Image size = 256
G9K_SCR0_16BIT		EQU	3	; 16 bits/dot
G9K_SCR0_8BIT		EQU	2	; 8 bits/dot
G9K_SCR0_4BIT		EQU	1	; 4 bits/dot
G9K_SCR0_2BIT		EQU	0	; 2 bits/dot

; Register defines

G9K_WRITE_ADDR		EQU	0	; W
G9K_READ_ADDR		EQU	3	; W
G9K_SCREEN_MODE0	EQU	6	; R/W
G9K_SCREEN_MODE1	EQU	7	; R/W
G9K_CTRL			EQU	8	; R/W
G9K_INT_ENABLE      EQU 9   ; R/W
G9K_INT_V_LINE_LO	EQU	10	; R/W	
G9K_INT_V_LINE_HI	EQU	11	; R/W
G9K_INT_H_LINE		EQU	12	; R/W	
G9K_PALETTE_CTRL	EQU	13	; W
G9K_PALETTE_PTR		EQU	14	; W
G9K_BACK_DROP_COLOR	EQU 15  ; R/W
G9K_DISPLAY_ADJUST	EQU	16	; R/W
G9K_SCROLL_LOW_Y	EQU 17  ; R/W
G9K_SCROLL_HIGH_Y	EQU 18  ; R/W
G9K_SCROLL_LOW_X	EQU 19  ; R/W
G9K_SCROLL_HIGH_X	EQU 20  ; R/W
G9K_SCROLL_LOW_Y_B	EQU 21  ; R/W
G9K_SCROLL_HIGH_Y_B	EQU 22  ; R/W
G9K_SCROLL_LOW_X_B	EQU 23  ; R/W
G9K_SCROLL_HIGH_X_B	EQU 24  ; R/W
G9K_PAT_GEN_TABLE   EQU 25  ; R/W
G9K_LCD_CTRL        EQU 26  ; R/W
G9K_PRIORITY_CTRL  	EQU 27  ; R/W
G9K_SPR_PAL_CTRL	EQU	28	; W
G9K_SC_X			EQU	32	; W
G9K_SC_Y			EQU	34	; W
G9K_DS_X			EQU	36	; W
G9K_DS_Y			EQU	38	; W
G9K_NX				EQU	40	; W
G9K_NY				EQU	42	; W
G9K_ARG				EQU	44	; W
G9K_LOP				EQU	45	; W
G9K_WRITE_MASK		EQU	46	; W
G9K_FC				EQU	48	; W
G9K_BC				EQU	50	; W
G9K_OPCODE			EQU	52	; W

; Bit defines G9K_LOP           (Register 45)

G9K_LOP_TP			EQU	16
G9K_LOP_WCSC		EQU	12
G9K_LOP_WCNOTSC		EQU	3
G9K_LOP_WCANDSC		EQU	8
G9K_LOP_WCORSC		EQU	14
G9K_LOP_WCEORSC		EQU	6

; Port defines

G9K_VRAM			EQU	60h	; R/W
G9K_PALETTE			EQU	61h	; R/W
G9K_CMD_DATA		EQU	62h	; R/W
G9K_REG_DATA		EQU	63h	; R/W
G9K_REG_SELECT		EQU	64h	; W
G9K_STATUS			EQU	65h	; R
G9K_INT_FLAG		EQU	66h	; R/W
G9K_SYS_CTRL		EQU	67h	; W
G9K_OUTPUT_CTRL     EQU 6Fh ; R/W

; Bit defines G9K_STATUS

G9K_STATUS_TR       EQU 128
G9K_STATUS_VR       EQU 64
G9K_STATUS_HR       EQU 32
G9K_STATUS_BD       EQU 16
G9K_STATUS_MSC      EQU 4
G9K_STATUS_EO       EQU 2
G9K_STATUS_CE       EQU 1

; Blitter Commands G9K_OPCODE    (Register 52)

G9K_OPCODE_STOP		EQU	00h	; Command being excuted is stopped 
G9K_OPCODE_LMMC		EQU	10h ; Data is transferred from CPU to VRAM rectangle area
G9K_OPCODE_LMMV		EQU	20h ; VRAM rectangle area is painted out
G9K_OPCODE_LMCM		EQU	30h ; VRAM rectangle area is transferred to CPU
G9K_OPCODE_LMMM		EQU	40h ; Rectangle area os transferred from VRAM to VRAM
G9K_OPCODE_CMMC		EQU	050h; CPU character data is color-developed and transferred to VRAM rectangle area
G9K_OPCODE_CMMK		EQU	060h; Kanji ROM data is is color-developed and transferred to VRAM rectangle area
G9K_OPCODE_CMMM		EQU	070h; VRAM character data is color-developed and transferred to VRAM rectangle area 
G9K_OPCODE_BMXL		EQU	080h; Data on VRAM linear address is transferred to VRAM rectangle area
G9K_OPCODE_BMLX		EQU	090h; VRAM rectangle area is transferred to VRAM linear address 
G9K_OPCODE_BMLL		EQU	0A0h; Data on VRAM linear address is transferred to VRAM linear address 
G9K_OPCODE_LINE		EQU	0B0h; Straight line is drawer on X-Y co-ordinates
G9K_OPCODE_SRCH		EQU	0C0h; Border color co-ordinates on X-Y are detected
G9K_OPCODE_POINT	EQU	0D0h; Color code on specified point on X-Y is read out
G9K_OPCODE_PSET		EQU	0E0h; Drawing is executed at drawing point on X-Y co-ordinates
G9K_OPCODE_ADVN		EQU	0F0h; Drawing point on X-Y co-ordinates is shifted

; Bit defines G9K_CTRL    (Register 8)

G9K_CTRL_DISP		EQU	128	; Display VRAM
G9K_CTRL_DIS_SPD	EQU	64	; Disable display sprite (cursor)
G9K_CTRL_YSE		EQU	32	; /YS Enable
G9K_CTRL_VWTE		EQU	16	; VRAM Serial data bus control during digitization
G9K_CTRL_VWM		EQU	8	; VRAM write control during digitization
G9K_CTRL_DMAE		EQU	4	; Enable DMAQ output
G9K_CTRL_VRAM512	EQU	2	; VRAM=512KB
G9K_CTRL_VRAM256	EQU	1	; VRAM=256KB
G9K_CTRL_VRAM128	EQU	0	; VRAM=128KB

; Register Select options

G9K_DIS_INC_READ	EQU	64
G9K_DIS_INC_WRITE	EQU	128

; Bit defines G9K_SYS_CTRL

G9K_SYS_CTRL_SRS	EQU	2	; Power on reset state
G9K_SYS_CTRL_MCKIN	EQU	1	; Select MCKIN terminal
G9K_SYS_CTRL_XTAL	EQU	0	; Select XTAL

; Bit defines G9K_SCREEN_MODE1 (register 7)

G9K_SCR1_C25M		EQU	64	; Select 640*480 mode
G9K_SCR1_SM1		EQU	32	; Selection of 263 lines during non interlace , else 262
G9K_SCR1_SM			EQU	16	; Selection of horizontal frequency 1H=fsc/227.5
G9K_SCR1_PAL		EQU	8	; Select PAL, else NTSC
G9K_SCR1_EO			EQU	4	; Select of vertical resoltion of twice the non-interlace resolution
G9K_SCR1_IL			EQU	2	; Select Interlace
G9K_SCR1_HSCN		EQU	1	; Select High scan mode

;;;;;;;;;;;;;;;;;;; G9K CONSTANTES FIN

vram_first_pattern_name:equ 0000E008h

;indices a la cabecera del fichero g9b

g9b_object_bitdepth			equ 5 	;byte       ; 2,4,8 or 16 bit
g9b_object_colortype		equ 6 	;byte	    ; 0=64 color palette mode,64=256 color fixed ,128=yjk and 192=yuv mode
g9b_object_nrcolors			equ 7 	;byte       ; number of colors in palette mode
g9b_object_width			equ 8 	;word	    ; width
g9b_object_height      		equ 10 	;word       ; height
g9b_object_compression		equ 12 	;byte       ; 0 = no compression, other value = compression used
g9b_object_datasize			equ 13 	;d24        ; 24 bit data size
g9b_object_palete_pointer 	equ 16

puntero_g9b: 			equ 0000E001h
block_size: 			equ 0000E003h
blocks: 				equ 0000E005h
source_length: 			equ 0000E006h
