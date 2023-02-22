G9kDetecta:

; Función  :    Detecta si hay conectada una V9990
; Input    :    nada
; Output   :    Z = detectada , NZ = no detectada
; Modifica :  	A,C,E,H,L,F
; Notas    :    Funciona aunque te la puedes ahorrar

         ld     E,0
         ld	  	H,E
         ld     L,E
         call   G9kSetVramWrite
         ld     A,0A2h
         out    (G9K_VRAM),A
         ld     E,0
         ld	  	H,E
         ld     L,E
         call   G9kSetVramRead
         in     A,(G9K_VRAM)
         cp     A,0A2h
         
         ret
                  	
G9kSetVramWrite:

; Función  :    Establece la dirección de escritura en Vram
; Input    : 	E:HL VRAM address
; Output   : 	nada
; Modifica : 	Nada

		  PUSH	AF
		  PUSH	BC
          ld    A,G9K_WRITE_ADDR
          out   (G9K_REG_SELECT),A
          ld    C,G9K_REG_DATA
          out   (C),L
          out   (C),H
          out   (C),E
          POP	BC
          POP	AF
          ret

G9kSetVramRead:

; Función  :   	Establecer la dirección de lectura de Vram
; Input    : 	E:HL VRAM address
; Output   : 	nada
; Modifica : 	A,C

           ld   A,G9K_READ_ADDR
           out  (G9K_REG_SELECT),A
           ld   C,G9K_REG_DATA
           out  (C),L
           out  (C),H
           out  (C),E
           
           ret

G9kReset:
 
; Función  :    Resetea la v9990, limpia la Paleta, apaga los sprites, detiene cualquier operación actual de blit, coloca V9990 en la correcta configuración de RAM y desactiva la pantalla
; Input    :    Nada
; Output   :    Nada
; Modifica : 	A,B
; Notas    :    No cambia los ajustes actuales

          G9kReadReg G9K_DISPLAY_ADJUST + G9K_DIS_INC_READ
          
          push  AF      												; Guardamos valor de ajuste

          ; Establecemos el estado de reset
 
          ld    A,G9K_SYS_CTRL_SRS
          out   (G9K_SYS_CTRL),A

		  ; Limpiamos el estado de reset
 
          xor   A,A
          out   (G9K_SYS_CTRL),A

          pop   AF
          out   (G9K_REG_DATA),A        								; Restauramos el valor de ajuste

          G9kWriteReg G9K_OPCODE,G9K_OPCODE_STOP
          G9kWriteReg G9K_CTRL,G9K_CTRL_DIS_SPD+G9K_CTRL_VRAM512

          ; Clear current palette
 
          G9kWriteReg G9K_PALETTE_PTR,0      		 					; A se convierte en 0
          
          ld    B,64 * 3
          out   (G9K_PALETTE),A
          djnz  $-2
          out 	(G9K_OUTPUT_CTRL),A    	   								; Establecemos la salida de GFX9000
          
          ret

G9kSetScreenMode:

; A = Modo
; B = Bit por pixel
; C = Tamaño de la imagen
; D = Interlazado
; E = Registro del control de paleta

          ld    L,A
          add   A,A
          add   A,L     ; A  = A * 3
          ld    HL,G9K_MODE_TABLE
 
          ADD_HL_A
 
          ld    A,G9K_SCREEN_MODE0
          out   (G9K_REG_SELECT),A
          ld    A,(HL)  ; Get fixed settings for mode reg 6
          inc   HL
          or    A,B     ; Set bits per dot
          or    A,C     ; Set image size
          out   (G9K_REG_DATA),A
          ld    A,(HL)  ; Get fixed settings for mode reg 7
          inc   HL
          dec   D
          inc   D       ; Is d 0?
          jr    Z,$+4
          or    A,G9K_SCR1_EO+G9K_SCR1_IL
          out   (G9K_REG_DATA),A
          ld    A,(HL)
          out   (G9K_SYS_CTRL),A

          G9kWriteReg G9K_PALETTE_CTRL,e
           
          ret

G9kSetCmdWriteMask:

; HL = Valor de máscara

		  G9kWriteReg G9K_WRITE_MASK,L
		   
		  ld    A,H
		  out   (G9K_REG_DATA),A
		
		  ret
		            
setup_graphic_mode_and_blitter:

		  ld    A,G9K_MODE_P1
		  ld    BC,G9K_SCR0_4BIT*256 + G9K_SCR0_XIM256
  		  ld    D,0														; no interlazado (en el modo P1 no tiene sentido)
		  ld	e,000000110b                           					; Situa la paleta para la página B en la segunda paleta
																		; los bits 3-2 seleccionan la paleta del plano B (de 4), los bits 1-0 seleccionan la paleta del plano A (de los 4)
		  call  G9kSetScreenMode	

		  ; Establece la configuración blitter por defecto
		  
		  G9kWriteReg G9K_ARG,0
		  G9kWriteReg G9K_LOP, G9K_LOP_WCSC 							; copia tal cual es
		  
		  LD    HL,#00FF												; #FFFF
		  jp	G9kSetCmdWriteMask

G9K_MODE_TABLE:

          ; Pattern mode 1      (P1)
          
          db    G9K_SCR0_P1+G9K_SCR0_DTCLK4
          db    0
          db    G9K_SYS_CTRL_XTAL
          
          ; Pattern mode 2      (P2)
          
          db    G9K_SCR0_P2+G9K_SCR0_DTCLK4
          db    0
          db    G9K_SYS_CTRL_XTAL
          
          ; Bitmap 256 * 212    (B1)
          
          db    G9K_SCR0_BITMAP+G9K_SCR0_DTCLK4
          db    0
          db    G9K_SYS_CTRL_XTAL
          
          ; Bitmap 384 * 240    (B2)
          
          db    G9K_SCR0_BITMAP+G9K_SCR0_DTCLK2
          db    0
          db    G9K_SYS_CTRL_MCKIN
          
          ; Bitmap 512 * 212    (B3)
          
          db    G9K_SCR0_BITMAP+G9K_SCR0_DTCLK2
          db    0
          db    G9K_SYS_CTRL_XTAL
          
          ; Bitmap 768 * 212    (B4)
          
          db    G9K_SCR0_BITMAP+G9K_SCR0_DTCLK
          db    0
          db    G9K_SYS_CTRL_MCKIN
          
          ; Bitmap 640 * 400    (B5)
          
          db    G9K_SCR0_BITMAP+G9K_SCR0_DTCLK
          db    G9K_SCR1_HSCN
          db    G9K_SYS_CTRL_XTAL
          
          ; Bitmap 640 * 480    (B6)
          
          db    G9K_SCR0_BITMAP+G9K_SCR0_DTCLK
          db    G9K_SCR1_HSCN+G9K_SCR1_C25M
          db    G9K_SYS_CTRL_XTAL
          
          ; Bitmap 1024 * 212   (B7) (modo no documentado)
          
          db    G9K_SCR0_BITMAP+G9K_SCR0_DTCLK
          db    0
          db    G9K_SYS_CTRL_XTAL

G9kSpritesEnable:

; Función  :	Conectar los sprites de la V9990
; Input    :    nada
; Output   :    nada
; Modifica :	A

         G9kReadReg G9K_CTRL+G9K_DIS_INC_READ
         
         and    A,255-G9K_CTRL_DIS_SPD
         out    (G9K_REG_DATA),A
         
         ret

clean_pattern_model_table:												; limpia desde #00000 a #3FE00-1 y de #40000 a #7c000

		ld		e,#0													; plano A
		ld		hl,#0000												; desde #e000 hasta #f000
		call	G9kSetVramWrite	
			
		call	clean_3_times		
		
		ld		de,#fe00-1												; desde #30000 hasta #3fe00-1
	
.loop_1:

		xor		a
		out		[c],a
		inc		de
		
		ld		a,d
		or		e
		jr		nz,.loop_1
	
		ld		e,#4													; plano B
		ld		hl,#0000												; desde #e000 hasta #f000
		call	G9kSetVramWrite	

		call	clean_3_times

		ld		de,#c000-1												; desde #30000 hasta #7c000-1

.loop_2:

		xor		a
		out		[c],a
		inc		de
		
		ld		a,d
		or		e
		jr		nz,.loop_2
		
		ret

clean_3_times:
	
		xor		a
		ld		c,G9K_VRAM
		ld		b,3
	
.loop_2:

		push	bc
		ld		de,#0000
	
.loop:	

		xor		a
		out		[c],a
		inc		de
		
		ld		a,d
		or		e
		jr		nz,.loop

		pop		bc
		djnz	.loop_2
		
		ret         

setup_nametable:

		  																; llena los atributos del plano A

		ld		hl,0
		ld		[vram_first_pattern_name],hl
		call	setup_nametable_Aplane

		ld		e,#7													; llena los atributos del plano B
		ld		hl,#e000												; desde #e000 hasta #f000
		CALL	G9kSetVramWrite	
		push	hl														; (**)
		
		ld		b,32
		
		ld		hl,#000	
		LD		C,G9K_VRAM	
			
.loop_b:

		ld		a,l
		out		[c],a
		ld		a,h
		out		[c],a
		inc		hl
		
		djnz	.loop_b
		
		pop		de
		push	hl														; contador actual (*)
		ld		hl,128													; 32*2
		
		add		hl,de				
		ld		e,#7		
		CALL	G9kSetVramWrite	

		push	hl
		pop		de														; guarda en de momentaneamente

		pop		hl														; continuamos  (*)
		push	de														; guarda para la siguiente fila (**)
		
		ld		b,32
		LD		C,G9K_VRAM		
		
		ld		a,d
		cp		#00
		jr		nz,.loop_b
		ld		a,e
		or		a
		jr		z,.fin_b
		jr		.loop_b

.fin_b:

		pop		hl														; (**)
		ret

;[vram_first_pattern_name] - first pattern name	
setup_nametable_Aplane:
		
		ld		e,#7
		ld		hl,#c000			;form #c000 to #d000
		CALL	G9kSetVramWrite	
		push	hl					;(**)
		
		ld		b,32
		
		ld		hl,[vram_first_pattern_name]
		LD		C,G9K_VRAM		
.loop:
		ld		a,l
		out		[c],a
		ld		a,h
		out		[c],a
		inc		hl
		
		djnz	.loop
		
		pop		de
		push	hl				;current counter (*)
		ld		hl,128;32*2
		
		add		hl,de				
		ld		e,#7		
		CALL	G9kSetVramWrite	

		push	hl
		pop		de			;save on de for a while

		pop		hl		;continuamos  (*)
		push	de		;save for next row (**)
		
		ld		b,32
		LD		C,G9K_VRAM		
		
		ld		a,d
		cp		#e0
		jr		nz,.loop
		ld		a,e
		or		a
		jr		z,.fin
		jr		.loop

.fin:
		pop		hl			;(**)
		ret

carga_paleta_g9b:

; A  = Numbero de colores
; HL = Puntero a la paleta
; C  = Palette pointer  (0-3)  ... >3 => ret (haz esto sólo en el caso de paletas de 16 colores)

		push af
		ld a,c
		cp 4
		jr.	nc,.exit
		
.paletavram:

		pop af	
		rrc c
		rrc c 															; c*64 (16 colores*4 bytes)
		ld	b,a
		add	a,a
		add	a,b															; number of colors * 3 = size
		ld	b,a    														; bytes a escribir

		ld	a,14														; g9k_palette_ptr
		out	[0x64],a
		ld	a,c
		out	[0x63],a
		ld	c,0x61														; g9k_palette
		otir
		
		ret

.exit:

		pop	af
		ld		de,#30													; ADVERTENCIA, si omites la paleta ... debería ser para 16 colores siempre
		add		hl,de

		ret

G9kDisplayEnable:

; Función  :	Conectar la pantalla de la V9990
; Input    :    nada
; Output   :    nada
; Modifica :	A

         G9kReadReg G9K_CTRL+G9K_DIS_INC_READ
         
         or     A,G9K_CTRL_DISP
         out    (G9K_REG_DATA),A
         
         ret

G9kDisplayDisable:

; Función  :	Desonectar la pantalla de la V9990
; Input    :    nada
; Output   :    nada
; Modifica :	A

         G9kReadReg G9K_CTRL+G9K_DIS_INC_READ
         
         and    A,255-G9K_CTRL_DISP
         out    (G9K_REG_DATA),A
         
         RET

OUT_ESCRIBE_UN_BYTE:													; Escribe 2 bytes y pasa al siguiente

		LD		C,G9K_VRAM
		ld		a,l
		out		[c],a
[4]		nop
		ld		a,h
		out		[c],a

		ret

VUELCA_BIN_EN_V9990:

; Función	:	Vuelca en vram de V9990 una cantidad de bytes nunca superior a 32K
; Input		:	Por orden en Stack:	Segunda página de bytes a volcar
;									Cantidad de bytes del segundo bloque a volcar
;									Primera página de bytes a volcar
;									Cantidad de bytes del primer bloque a volcar
;									4 dígitos menos significativos de dirección de V9990 donde copiar (hl)
;									2 dígitos más significativos de dirección de V9990 donde copiar (e)
; Output	:	Nada
; Modifica	:	A, HL, DE, C
; Notas		:	El bloque de datos a volcar debe ser lo primero de la página y sería conveniente dedicar esa página sólo a esos datos.

				pop		hl
				ld		(var_cir_1),hl
				
				pop		de				
				pop		hl				
				call	G9kSetVramWrite	
				
				pop		de
				ld		ix,#8000

				pop		af
				ld		[#7000],a
				ld		l,(ix)
				ld		h,(ix+1)

.escribe_A_1:
								
				call	OUT_ESCRIBE_UN_BYTE
				push	hl
				ex		de,hl
				ld		de,2
				or		a
				sbc		hl,de
				ld		de,0
				call	DCOMPR				
				jp		z,.segunda_parte
				
				ld		de,2
				add		ix,de				
				ex		de,hl
				pop		hl				
				ld		l,(ix)
				ld		h,(ix+1)				
						
				jp		.escribe_A_1	

.segunda_parte:

				pop		hl				
				pop		de
				ld		ix,#8000				
				pop		af
				ld		[#7000],a	
				ld		l,(ix)
				ld		h,(ix+1)	
								
.escribe_A_2:
				
				call	OUT_ESCRIBE_UN_BYTE
				push	hl
				ex		de,hl
				ld		de,2
				or		a
				sbc		hl,de
				ld		de,0
				call	DCOMPR				
				jp		z,.final
				
				ld		de,2
				add		ix,de
				ex		de,hl
				pop		hl
				ld		l,(ix)
				ld		h,(ix+1)
											
				jp		.escribe_A_2	

.final:

				pop		hl	
				
				ld		hl,(var_cir_1)
				push	hl
				
				ret			
