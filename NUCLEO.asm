 				output	"NEWTERRA.rom"   								; El nombre con el que saldrá nuestro archivo ROM
		
				include	"RECURSOS BASICOS/BIOS.asm"						; Referencias a la BIOS.
				include	"RECURSOS BASICOS/VARIABLES.asm"				; Las variables a usar en el programa.
				include	"RECURSOS BASICOS/CONSTANTES 9990.asm"			; Las constantes que necesita la GFX9000 para funcionar.
				include	"RECURSOS BASICOS/MACROS 9990.asm"				; Las macros que necesita la GFX9000 para funcionar.
				
				org		#4000											; Esto es la dirección de memoria donde va a volcar.
				
				db 		"AB"											; Esta es la cabecera que le indicará al ordenador que esto es un archivo Rom y cómo debe salvarlo.
				word 	INICIO											; Inicio es un ejemplo, pero es exactamente donde empezará a ejecutarse el programa.
				word 	0,0,0,0,0,0										; Esto siempre tal cual.

INICIO:

				di														; Desconectamos las interrupciones.									
				im 		1												; Modo de interrupciones 1.

				ld		a,#C9											;a tiene el valor de ret
				ld		(#FD9F),a										;colocamos ese ret en el gancho H.Timi POR SI EL ORDENADOR TUVIERA ALGO (ALGUN MSX 2 CONTROL DE DISQUETERA)
				ld		(#FD9A),a										;colocamos ese ret en el gancho H.Key POR SI EL ORDENADOR TUVIERA ALGO
		
				ld 		sp,#F380										; Colocamos el puntero de la pila en la dirección de memoria #F380

AMPLIA_RAM:																; Ampliaremos la ram usada a espadios 1 y 2.
		
				call 	BUSCA_SLOT										; Aquí repite el bucle que hace la magia
				call 	ENASLT											; Se define en el apartado BIOS, es referencia a dirección de memoria #0024
																		; y sirve para ampliar el banco de memoria usado de 16k a 32k
				jp		PREPARA_BANCOS									; Regresamos a la rutina general

BUSCA_SLOT:																; Bucle de la magia

				call 	RSLREG											; Se define en el apartado BIOS, es referencia a dirección de memoria #0138
																		; leerá el registro del slot primario lo saca en A																		; 76543210
				rrca													; 07654321	Carry = 0
				rrca													; 10765432	Carry = 1
				and 	3												; xxxxxxxx and	00000011 = 000000xx 
				ld 		c,a												; c = 000000xx	a = 000000xx
				ld 		b,0												; b = 00000000
				ld 		hl,0FCC1h										; hl = 1111110011000001
				add		hl,bc											; hl = 1111110011000001 + 00000000000000xx
				ld 		a,(hl)											; a = hl
				and 	080h											; a = hl and 10000000
				or 		c												; a =  (hl and 10000000) or 000000xx
				ld 		c,a												; c = (hl and 10000000) or 000000xx
				inc 	hl											
				inc 	hl
				inc		hl
				inc 	hl												; hl = (1111110011000001 + 00000000000000xx)+00000100
				ld 		a,(hl)											; a = hl
				and 	0Ch												; a = hl and 00001100
				or 		c												; a = (hl and 00001100) or (hl and 10000000) or 000000xx
				ld 		h,080h											; h = 10000000
				ld 		(SLOTVAR),a										; Se guarda el valor de a en esta variable que suele ser la primera de las variables en el banco 3 
																		; A partir de la dirección de memoria #C000				
				ret														; Regresamos
				
PREPARA_BANCOS:

				xor		a
				ld		[#6000],a										; Banco 1, pagina 0 del MEGAROM.			

				ld		a,1
				call	CAMBIA_PAGINA_2									; Banco 2, pagina 1 del MEGAROM.		
		
LIMPIA_MEMORIA:

				xor		a												; Rutina para limpiar la memoria.
				ld		hl,#c000
				ld		[hl],a
				ld 		de,#c001
				ld		bc,(#f169 - #c000) - 1					
				ldir

PREPARA_PANTALLA_MSX:

				xor		a												; Quitamos el sonido Click de las teclas.								
				ld		[CLIKSW],a

				ld		a,0												; SCREEN 0 (recordemos que vamos a trabajar en la pantalla de V9990 así que no afecta a los dibujos de vram MSX)
				call	CHGMOD

				ld		a,0												; a 	= el valor que vamos a poner
				ld		bc,40*24										; bc	= longitud del area a rellenar con el dato A
				ld		hl,0											; hl	= dirección en la que empieza a pintar
				call	FILVRM											; Limpiamos toda esta zona de la VRAM 				

DETECTAMOS_GFX9000:

				call    G9kDetecta										; Esta secuencia detecta la GFX9000
				call    nz,GFX9990_NO_DETECTADA
				call	GFX9990_DETECTADA

				CALL    G9kReset										; Esta secuencia limpia la vram de la GFX9000

				call	setup_graphic_mode_and_blitter

				ei
									
				call	G9kSpritesEnable
				
				G9kWriteReg G9K_PRIORITY_CTRL,00000101B

				call	clean_pattern_model_table

				call	setup_nametable	

				G9kWriteReg 25,#04										; escribe en el registro 25 para que la lectura de sprites sea en la dirección #10000
				G9kWriteReg 18,#80										; scroll y a 256 lineas

				G9kWriteReg	G9K_BACK_DROP_COLOR,#10
				
				xor		a
				ld		(posicion_scroll_y_B),a
				ld		(posicion_scroll_y_A),a

LIMPIAMOS_PATRONES_DE_A:

				ld		e,#7
				ld		hl,#c000
				push	de
				push	hl
				call	G9kSetVramWrite

				ld		b,32

.bucle_limpieza_1:

				push	bc
				ld		b,128

.bucle_limpieza_2:

				push	bc
				ld		e,0
				ld		hl,2
				call	OUT_ESCRIBE_UN_BYTE
				pop		bc
				djnz	.bucle_limpieza_2
				pop		bc
				djnz	.bucle_limpieza_1

PRESENTACION:

			; Aquí mostramos la historia con 5 fotos

MENU:

			; Aquí mostramos título (plano b), un rotativo de personajes (sprites), varias imágenes del meteorito hacia la tierra (plano 1 y sprites)

CARGAMOS_TILES_DE_A:

				ld		a,2
				push	af
				ld		hl,16384
				push	hl
				ld		a,1
				push	af
				ld		hl,16384
				push	hl
				ld		hl,0
				push	hl
				push	hl
				
				call	VUELCA_BIN_EN_V9990

CARGAMOS_COLOR_TILES_A:

				ld		hl,DATA_COLOR_TILES							; Cargamos en la paleta 1 los 16 colores
				ld		a,16
				ld		c,2
				call	carga_paleta_g9b

				G9kWaitVsync								
				G9kWaitVsync								

CARGAMOS_TILES_DE_B:

				ld		a,5
				push	af
				ld		hl,16384
				push	hl
				ld		a,4
				push	af
				ld		hl,16384
				push	hl
				ld		hl,0
				push	hl
				ld		de,4
				push	de
				
				call	VUELCA_BIN_EN_V9990

CARGAMOS_COLOR_TILES_B:

				ld		hl,DATA_COLOR_MARCADOR							; Cargamos en la paleta 1 los 16 colores
				ld		a,16
				ld		c,1
				call	carga_paleta_g9b

CARGAMOS_COLOR_SPRITES_PROTA:

				ld		hl,DATA_COLOR_EXPLO							; Cargamos en la paleta 1 los 16 colores
				ld		a,16
				ld		c,0
				call	carga_paleta_g9b

				call    G9kDisplayEnable

.CARGAMOS_SPRITES:

				ld		a,7
				push	af
				ld		hl,16384
				push	hl
				ld		a,6
				push	af
				ld		hl,16384
				push	hl
				ld		hl,0
				push	hl
				ld		hl,1
				push	hl
				
				call	VUELCA_BIN_EN_V9990

VARIABLES_INICIO_PARTIDA:

				ld		a,20						; PANTALLA 20
				ld		(PANTALLA_ACTUAL),a
				ld		(PANTALLA_ACTUAL_SAVE),a
				ld		a,1
				ld		(POSICION_ACTUAL_SCROLL),a
				ld		a,7
				ld		(BYTE_VRAM_EMPIEZA_E),a
				ld		hl,#c000
				ld		(BYTE_VRAM_EMPIEZA_HL),hl
				xor		a
				ld		(DIRECCION_DONDE_VAMOS),a
				ld		(POSE_PROTA),a
				ld		(PROCESO_DE_SALTO),a
				ld		(SPACE_PULSADO),a
				ld		(PERSONAJE),a
				ld		(POSICION_BOLSILLO),a
				ld		(DETRAS_DE_POZO),a
				ld		(MUERTE),a
				ld		a,32*3-8
				ld		(Y_SAVE),a
				ld		a,90
				ld		(X_SAVE),a
				ld		a,4
				ld		(VIDAS),a
				ld		b,16
				ld		de,1
				ld		ix,ATRIBUTOS_SPRITES
				ld		iy,VALORES_INICIALES_ATRIBUTOS_SPRITES

.bucle_atributos_sprites_iniciales:

				ld		a,(iy)
				ld		(ix),a
				add		ix,de
				add		iy,de
				djnz	.bucle_atributos_sprites_iniciales

				ld		a,3
				call	CAMBIA_PAGINA_2

PINTA_LA_PANTALLA_DE_INICIO:

			ld		a,(VIDAS)
			or		a
			jp		z,LIMPIAMOS_PATRONES_DE_A

			ld		a,(MUERTE)
			or		a
			jp		z,.PINTA_LA_PANTALLA_DE_INICIO_1
			
			xor		a
			ld		(MUERTE),a
			ld		(CONTADOR_DE_MUERTE),a
			ld		a,(PANTALLA_ACTUAL_SAVE)
			ld		(PANTALLA_ACTUAL),a

			ld		ix,ATRIBUTOS_SPRITES
			xor		a
			call	COMUN_PATRON_CUATRO_SPRITES
			ld      a,0000000b
			ld		(POSE_PROTA),a
			ld		(ix+3),a
			ld		(ix+7),a
			ld		(DIRECCION_DONDE_VAMOS),a
			ld		a,(Y_SAVE)
			call	COMUN_Y_CUATRO_SPRITES
			ld		a,(X_SAVE)
			call	COMUN_X_CUATRO_SPRITES

.PINTA_LA_PANTALLA_DE_INICIO_1:

			ld		a,1
			ld		(MEMORIZAMOS_POSICION),a
			call	PINTAMOS_PANTALLA_EN_LA_QUE_ESTAMOS

COLOCAMOS_AL_PROTA_SI_VENIMOS_DE_OTRA_PANTALLA:

			ld		a,(DIRECCION_DONDE_VAMOS)
			cp		3
			jp		z,.poner_a_la_izquierda
			cp		7
			jp		z,.poner_a_la_derecha
			cp		5
			jp		z,.poner_arriba
			cp		1
			jp		z,.poner_abajo

			jp		.muestra_sprites

.poner_a_la_izquierda:

			ld		ix,ATRIBUTOS_SPRITES
			ld		a,2
			call	COMUN_X_CUATRO_SPRITES
			jp		.muestra_sprites

.poner_a_la_derecha:

			ld		ix,ATRIBUTOS_SPRITES
			ld		a,255-31
			call	COMUN_X_CUATRO_SPRITES
			jp		.muestra_sprites

.poner_arriba:

			ld		ix,ATRIBUTOS_SPRITES
			ld		a,0
			call	COMUN_Y_CUATRO_SPRITES
			ld		a,(PANTALLA_ACTUAL)
			cp		24
			jp		nz,.muestra_sprites
			ld		ix,ATRIBUTOS_SPRITES
			ld		a,(ix+1)
			or		01000000b
			and		01011111b
			call	COMUN_PATRON_CUATRO_SPRITES
			jp		.muestra_sprites

.poner_abajo:

			ld		ix,ATRIBUTOS_SPRITES
			ld		a,(PANTALLA_ACTUAL)
			cp		12
			jp		nz,.poner_abajo_1
			ld		a,#4B
			jp		.poner_abajo_2

.poner_abajo_1:

			ld		a,110

.poner_abajo_2:

			call	COMUN_Y_CUATRO_SPRITES

.muestra_sprites:

			call	COSAS_ESPECIALES_POR_PANTALLA

			ld		ix,ATRIBUTOS_SPRITES
			ld		a,(ix+3)
			or		00100000b
			and		11101111b
			call	COMUN_ATRIBUTOS_CUATRO_SPRITES

.muestra_vidas:

			ld		e,3
			ld		hl,#fe00+4*4*10
			call	G9kSetVramWrite

			ld		b,28
			ld		a,(VIDAS)
			cp		4
			jp		z,.vidas_3
			cp		3
			jp		z,.vidas_2
			cp		2
			jp		z,.vidas_1

.vidas_0:

			ld		ix,ATRIBUTOS_VIDAS_0
			jp		.bucle_vidas
			
.vidas_1:

			ld		ix,ATRIBUTOS_VIDAS_1
			jp		.bucle_vidas
			
.vidas_2:

			ld		ix,ATRIBUTOS_VIDAS_2
			jp		.bucle_vidas
			
.vidas_3:

			ld		ix,ATRIBUTOS_VIDAS_3
			

.bucle_vidas:

			push	bc
			ld		l,(ix)
			ld		h,(ix+1)

			call	OUT_ESCRIBE_UN_BYTE

			ld		de,2
			add		ix,de

			pop		bc
			djnz	.bucle_vidas

BUCLE_CENTRAL:

			G9kWaitVsync
			call	VAMOS_A_SABER_QUE_SOY
			call	A_VER_SI_MUERE

			ld		a,(CONTADOR_DE_MUERTE)
			or		a
			jp		nz,.bucle_central_1
			
			ld		a,(QUE_SOY)
			cp		6
			jp		z,.bucle_central_2

			call	MIRA_QUE_HAY_ALREDEDOR_DEL_PROTA
			call	ALGO_ME_MATA
			call	MIRA_GRAVEDAD
			call	STICK

.bucle_central_1:

			call	TECLAS
			call	COGE_UN_OBJETO_1
			call	COGE_UN_OBJETO_2
			call	CONTROLA_SI_SALE_DE_PANTALLA

.bucle_central_2:

			call	EVENTO_ESPECIAL_SEGUN_PANTALLA
			G9kWaitVsync
			call	PINTA_SPRITES

			jp		BUCLE_CENTRAL

ALGO_ME_MATA:

			ld		b,4
			ld		ix,TYLE_POSIC_3

.bucle_1:

			ld		l,(ix)
			ld		h,(ix+1)
			ld		de,368
			call	DCOMPR
			jp		c,.bucle_2
			ld		de,384
			call	DCOMPR
			jp		nc,.bucle_2

			ld		a,2
			ld		(MUERTE),a
			ret

.bucle_2:

			ld		de,2
			add		ix,de
			djnz	.bucle_1

			ret

A_VER_SI_MUERE:

			ld		a,(CONTADOR_DE_MUERTE)
			or		a
			jp		z,.tipo_de_muerte

			inc		a
			ld		(CONTADOR_DE_MUERTE),a

			cp		50
			jp		nz,.tipo_de_muerte
			pop		hl

			ld		a,(VIDAS)
			dec		a
			ld		(VIDAS),a
			
			jp		PINTA_LA_PANTALLA_DE_INICIO

.tipo_de_muerte:

			ld		a,(MUERTE)
			or		a
			ret		z
			cp		2
			jp		z,.explosion
			cp		3
			jp		z,.radiacion
			cp		4
			jp		z,.canon_pared

.caida:			

			ld		a,(CONTADOR_DE_MUERTE)
			or		a
			ret		nz

			ld		a,1
			ld		(CONTADOR_DE_MUERTE),a

			ld		ix,ATRIBUTOS_SPRITES
			ld		a,116
			call	COMUN_PATRON_CUATRO_SPRITES
			ld      a,0001000b
			ld		(ix+3),a
			ld		(ix+7),a
			ret

.explosion:

			ld		a,(CONTADOR_DE_MUERTE)
			or		a
			jp		nz,.explosion_2

			ld		a,1
			ld		(CONTADOR_DE_MUERTE),a

.explosion_2:

			ld		ix,ATRIBUTOS_SPRITES
			ld		a,(CONTADOR_DE_MUERTE)
			cp		1
			jp		z,.fotograma_1
			cp		3
			jp		z,.fotograma_2
			cp		5
			jp		z,.fotograma_3
			cp		7
			jp		z,.fotograma_4
			cp		9
			jp		z,.fotograma_5
			ret

.fotograma_1:

			xor		a
			jp		COMUN_PATRON_CUATRO_SPRITES

.fotograma_2:

			ld		a,2
			jp		COMUN_PATRON_CUATRO_SPRITES

.fotograma_3:

			ld		a,4
			jp		COMUN_PATRON_CUATRO_SPRITES
			
.fotograma_4:

			ld		a,6
			jp		COMUN_PATRON_CUATRO_SPRITES
			
.fotograma_5:

			ld		a,238
			call	COMUN_PATRON_CUATRO_SPRITES
			ld		a,111
			jp		COMUN_Y_CUATRO_SPRITES
			
.radiacion:

			ret

.canon_pared:

			ld		a,(CONTADOR_DE_MUERTE)
			or		a
			ret		nz

			ld		a,1
			ld		(CONTADOR_DE_MUERTE),a

			ld		ix,ATRIBUTOS_SPRITES
			ld		a,116
			call	COMUN_PATRON_CUATRO_SPRITES
			ld      a,0001000b
			ld		(ix+3),a
			ld		(ix+7),a

			ret		
				
TECLAS:

			ld		a,(PAUSA_ENTRE_BOTONES)
			or		a
			jp		z,.miramos
			dec		a
			ld		(PAUSA_ENTRE_BOTONES),a
			ret

.miramos:

			ld		a,0
			call	SNSMAT
			bit		1,a
			jp		z,.rota_a_izquierda_1
			bit		2,a
			jp		z,.rota_a_derecha_2
			ld		a,4
			call	SNSMAT
			bit		6,a
			jp		z,.intercambia
			ret

.crea_la_pausa:

			ld		a,5
			ld		(PAUSA_ENTRE_BOTONES),a
			ret

.rota_a_izquierda_1:

			call	.crea_la_pausa
			ld		a,(POSICION_BOLSILLO)
			dec		a
			jp		.comun_rota

.rota_a_derecha_2:

			call	.crea_la_pausa
			ld		a,(POSICION_BOLSILLO)
			inc		a

.comun_rota:

			and		00011111b
			ld		(POSICION_BOLSILLO),a
			jp		COLOCA_OBJETOS_BOLSILLO_Y_USANDO

.intercambia:

			ld		ix,MONOCICLO
			ld		c,0
			ld		b,31

.bucle_busca_usando:

			ld		a,(ix)
			cp		2
			jp		z,.da_atributos_cogiendo

			inc		c
			ld		de,1
			add		ix,de
			djnz	.bucle_busca_usando

.da_atributos_cogiendo:

			push	bc

.busca_posicion_cercana_de_bolsillo:

			ld		ix,MONOCICLO
			ld		c,0
			ld		b,31

.bucle_busca_bolsillo_cercano:

			ld		a,(POSICION_BOLSILLO)
			add		3
			ld		d,a
			ld		a,(ix)
			cp		d
			jp		z,.soluciona_el_bolsillo

			inc		c
			ld		de,1
			add		ix,de
			djnz	.bucle_busca_bolsillo_cercano

.soluciona_el_bolsillo:

			ld		a,c
			pop		bc
			ld		b,a		; b posicion usando, c posicion bolsillo cercano en posición A
			
			ld		ix,MONOCICLO ; llevando
			ld		iy,MONOCICLO ; bolsillo A
			ld		e,c
			ld		d,0
			add		iy,de
			ld		e,b
			add		ix,de

.guarda_datos_futuro_USANDO:

			ld		a,31
			cp		b
			jp		z,.guarda_datos_futuro_A
			ld		a,2
			ld		(ix),a

.guarda_datos_futuro_A

			ld		a,31
			cp		c
			jp		z,.pintando_las_cosas
			ld		a,(POSICION_BOLSILLO)
			add		3
			ld		(iy),a

.pintando_las_cosas:

			call	COLOCA_OBJETOS_BOLSILLO_Y_USANDO
			call	.crea_la_pausa
			ret

VAMOS_A_SABER_QUE_SOY:

			ld		a,(QUE_SOY)
			cp		6
			ret		z

.EXPLOTAO:

			ld		a,(MUERTE)
			cp		2
			jp		nz,.GLOBO

			ld		a,(QUE_SOY)
			cp		4
			ret		z

			ld		a,4
			ld		(QUE_SOY),a

			ld		ix,TABLA_PEGA_4_POSE_1_DIREC
			ld		iy,SPR_EXPO_EXP
			jp		CARGA_ZONA_SPRITES

.GLOBO:

			ld		a,(QUE_SOY)
			cp		5
			ret		z

.ASPIRADORA:

			ld		a,(QUE_SOY)
			cp		1
			jp		nz,.FLAUTA

			ld		ix,ATRIBUTOS_SPRITES
			ld		a,(ix+1)
			and		00100000b
			ld		(ix+1),a
			ld		a,(ix+5)
			and		00100000b
			or		00000001b
			ld		(ix+5),a
			ld		a,(ix+9)
			and		00100000b
			or		00010000b
			ld		(ix+9),a
			ld		a,(ix+13)
			and		00100000b
			or		00010001b
			ld		(ix+13),a
			xor		a
			ld		(POSE_PROTA),a
			call	PINTA_SPRITES
			
			xor		a
			ld		(SPACE_PULSADO),a
			ret

.FLAUTA:
			ld		a,(FLAUTA)
			cp		2
			jp		nz,.PARAGUAS

.SI_FLAUTA:

			ld		a,(QUE_SOY)
			cp		2
			ret		z

			ld		ix,TABLA_PEGA_4_POSE_2_DIREC
			ld		iy,SPR_EXPO_FLU
			call	CARGA_ZONA_SPRITES

			ld		a,2
			ld		(QUE_SOY),a			
			ret	

.pintado_general:


			ld		a,(QUE_SOY)
			or		a
			ret		z

			ld		ix,TABLA_PEGA_4_POSE_2_DIREC
			ld		iy,SPR_EXPO_WAC
			call	CARGA_ZONA_SPRITES
			xor		a
			ld		(QUE_SOY),a
			ret

.PARAGUAS:

			ld		a,(PARAGUAS)
			cp		2
			jp		nz,.pintado_general

			ld		a,(ATENCION_AL_SALTO)
			cp		1
			jp		nz,.pintado_general
			ld		a,(QUE_SOY)
			cp		3
			ret		z

			ld		a,(PANTALLA_ACTUAL)
			cp		28
			jp		z,.pintado_general
			cp		16
			jp		z,.pintado_general

			ld		a,(SUMA_ALTURA_CAIDA)
			cp		5
			jp		c,.pintado_general
			ld		a,3
			ld		(QUE_SOY),a

			ld		ix,TABLA_PEGA_1_POSE_2_DIREC
			ld		iy,SPR_EXPO_UMB
			call	CARGA_ZONA_SPRITES
			ld		ix,ATRIBUTOS_SPRITES
			ld		a,(ix+1)
			and		00010000b
			call	COMUN_PATRON_CUATRO_SPRITES
			xor		a
			ld		(POSE_PROTA),a			
			RET		

EVENTO_ESPECIAL_SEGUN_PANTALLA:

			ld		ix,RELACION_DE_SUCESOS_POR_PANTALLA
			ld		a,(PANTALLA_ACTUAL)
			ld		e,a
			ld		d,0
[2]			add		ix,de
			ld		l,(ix)
			ld		h,(ix+1)
			jp		(hl)

.PANTALLA00:

			ld		a,5
			jp		SI_NO_TOCA_OBJETO_1_REGRESA

.PANTALLA01:
.PANTALLA02:
.PANTALLA03:

			jp		.PANTALLA15

.PANTALLA04:

			ld		a,21
			jp		SI_NO_TOCA_OBJETO_1_REGRESA

.PANTALLA05:
.PANTALLA06:

			ret
.PANTALLA07:

			ld		a,27
			jp		SI_NO_TOCA_OBJETO_1_REGRESA

.PANTALLA08:

			call	.COMUN_8_Y_20

.PANTALLA08_2:

			ld		a,10
			jp		SI_NO_TOCA_OBJETO_1_REGRESA

.PANTALLA09:

			ld		a,6
			jp		SI_NO_TOCA_OBJETO_1_REGRESA

.PANTALLA10:

			ld		a,12
			jp		SI_NO_TOCA_OBJETO_1_REGRESA

.PANTALLA11:

			xor		a
			jp		SI_NO_TOCA_OBJETO_1_REGRESA

.PANTALLA12:

			ld		a,(DETRAS_DE_POZO)
			or		a
			jp		nz,.PANTALLA12_2

			ld		ix,ATRIBUTOS_SPRITES
			ld		a,(ix+2)
			cp		#3c
			jp		c,.PANTALLA12_2
			cp		#44
			jp		nc,.PANTALLA12_2
			ld		a,(ix)
			cp		#49
			jp		c,.PANTALLA12_2
			cp		#4B
			jp		nc,.PANTALLA12_2

			ld		ix,DATAS_PUENTE
			call	TILES_DE_B.PINTURA_GLOBAL
			ld		a,1
			ld		(DETRAS_DE_POZO),a

.PANTALLA12_2:

			ld		ix,ATRIBUTOS_SPRITES
			ld		a,(ix+2)
			cp		#3c
			jp		c,.PANTALLA12_4
			cp		#44
			jp		nc,.PANTALLA12_4
			ld		a,(ix)
			cp		#57
			jp		c,.PANTALLA12_4

			ld		a,(DETRAS_DE_POZO)
			cp		2
			jp		nz,.PANTALLA12_3

			xor		a
			ld		(DETRAS_DE_POZO),a
			jp		.PANTALLA12_4

.PANTALLA12_3:

			cp		1
			jp		nz,.PANTALLA12_4

			ld		a,115
			call	COMUN_Y_CUATRO_SPRITES
			ld		a,2
			ld		(DETRAS_DE_POZO),a

.PANTALLA12_4:

			ld		a,2
			jp		SI_NO_TOCA_OBJETO_1_REGRESA

.PANTALLA13:
.PANTALLA14:
.PANTALLA15:

			ld		a,(SOPLADOR)
			cp		2
			jp		z,.PANTALLA15_0
			ld		a,(MANIFIESTO)
			cp		2
			jp		z,.PANTALLA15_0

			ld		ix,ATRIBUTOS_SPRITES+64
			ld		a,(ix)
			cp		#48
			jp		nc,.PANTALLA15_0

			inc		a
			call	COMUN_Y_CUATRO_SPRITES
			ld		de,16
			add		ix,de
			ld		a,(ix)
			inc		a
			call	COMUN_Y_CUATRO_SPRITES
			ld		ix,ATRIBUTOS_SPRITES
			ld		a,(ix)
			inc		a
			call	COMUN_Y_CUATRO_SPRITES

.PANTALLA15_0:

			ld		a,(OBJETO_TOCANDO_2)
			or		a
			jp		z,.PANTALLA15_4

			ld		a,(QUE_SOY)
			cp		5
			jp		z,.PANTALLA15_2

			ld		ix,TABLA_PEGA_1_POSE_1_DIREC
			ld		iy,SPR_EXPO_BAL
			call	CARGA_ZONA_SPRITES

			ld		a,5
			ld		(QUE_SOY),a	

.PANTALLA15_2:

			ld		a,(SOPLADOR)
			cp		2
			jp		z,.PANTALLA15_3
			ld		a,(MANIFIESTO)
			cp		2
			ret		nz

.PANTALLA15_3:

			ld		ix,ATRIBUTOS_SPRITES
			ld		a,(ix)
			dec		a
			call	COMUN_Y_CUATRO_SPRITES
			ld		de,4*4*4
			add		ix,de
			ld		a,(ix)
			dec		a
			call	COMUN_Y_CUATRO_SPRITES
			ld		de,4*4
			add		ix,de
			ld		a,(ix)
			dec		a
			jp		COMUN_Y_CUATRO_SPRITES			

.PANTALLA15_4:

			ld		a,(QUE_SOY)
			cp		5
			ret		nz

			ld		ix,TABLA_PEGA_4_POSE_2_DIREC
			ld		iy,SPR_EXPO_WAC
			call	CARGA_ZONA_SPRITES

			xor		a
			ld		(QUE_SOY),a
			ret

.PANTALLA16:

			ld		a,(OBJETO_TOCANDO_1)
			or		a
			jp		z,.PANTALLA16_2

			ld		a,7
			call	ENTREGA_UN_OBJETO
			call	BORRA_OBJETO_1_DE_PANTALLA
			call	PUNTOS
			ld		a,7
			call	COLOCA_OBJETO_EN_MARCADOR
			jp		.PANTALLA16_3

.PANTALLA16_2:

			ld		a,(OBJETO_TOCANDO_2)
			or		a
			jp		z,.PANTALLA16_3

			ld		a,3
			call	ENTREGA_UN_OBJETO
			call	BORRA_OBJETO_2_DE_PANTALLA
			call	PUNTOS
			ld		a,3
			call	COLOCA_OBJETO_EN_MARCADOR

.PANTALLA16_3:

			ld		a,(SALTO_COLCHONETA)
			or		a
			JP		z,.PANTALLA16_5

			ld		ix,ATRIBUTOS_SPRITES
			ld		a,(ix)
			cp		45
			jp		c,.PANTALLA16_4
		
			sub		2
			call	COMUN_Y_CUATRO_SPRITES
			ld		a,(ix+1)
			and		00100000b
			or		00001110b
			call	COMUN_PATRON_CUATRO_SPRITES
			jp		.PANTALLA16_5

.PANTALLA16_4:

			xor		a
			ld		(SALTO_COLCHONETA),a
			ld		(POSE_PROTA),a
			call	COMUN_PATRON_CUATRO_SPRITES

.PANTALLA16_5:

			ld		ix,ATRIBUTOS_SPRITES
			ld		a,(ix+2)
			cp		#2b
			jp		nc,.PANTALLA16_6

			ld		a,(QUIERE_CUERDA)
			cp		2
			jp		z,.PANTALLA16_6

			ld		a,1
			ld		(QUIERE_CUERDA),a

			ld		a,(ix+1)
			and		00111111b
			call	COMUN_PATRON_CUATRO_SPRITES
			ld		a,#2a
			call	COMUN_X_CUATRO_SPRITES

.PANTALLA16_6:

			ld		a,(QUIERE_CUERDA)
			or		a
			ret		z

			ld		a,(FLAUTA)
			cp		2
			ret		nz

			ld		hl,(CUERDA_PINTANDO)
			ld 		de,#c510
			call	DCOMPR
			jp		nz,.PANTALLA16_7

			ld		a,2
			ld		(QUIERE_CUERDA),a
			ret

.PANTALLA16_7:			

			ld		de,(BYTE_VRAM_EMPIEZA_HL)
			or		a
			adc		hl,de
			ld		de,#bfff
			sbc		hl,de
			ld		e,7
			call	G9kSetVramWrite	

			ld		hl,574
			call	OUT_ESCRIBE_UN_BYTE
			ld		hl,575
			call	OUT_ESCRIBE_UN_BYTE


			ld		hl,(CUERDA_PINTANDO)
			ld		de,#40
			or		a
			sbc		hl,de
			ld		(CUERDA_PINTANDO),hl

			ret

.PANTALLA17:
.PANTALLA18:
.PANTALLA19:

			ret
.PANTALLA20:

			call	.COMUN_8_Y_20
			jp		.PANTALLA20_2

.COMUN_8_Y_20:

			ld		a,(ASPIRADORA)
			cp		2
			jp		nz,.NO_VUELA

.SI_VUELA:

			ld		a,(QUE_SOY)
			cp		1
			ret		z

			ld		ix,TABLA_PEGA_1_POSE_2_DIREC
			ld		iy,SPR_EXPO_ASP
			call	CARGA_ZONA_SPRITES

			ld		a,1
			ld		(QUE_SOY),a			
			ret	

.NO_VUELA:


			ld		a,(QUE_SOY)
			or		a
			ret		z
			cp		2
			ret		z

			ld		ix,TABLA_PEGA_4_POSE_2_DIREC
			ld		iy,SPR_EXPO_WAC
			call	CARGA_ZONA_SPRITES
			xor		a
			ld		(QUE_SOY),a
			ret

.PANTALLA20_2:

			ld		a,9
			jp		SI_NO_TOCA_OBJETO_1_REGRESA

.PANTALLA21:

			ret
.PANTALLA22:

			ld		a,11
			jp		SI_NO_TOCA_OBJETO_1_REGRESA

.PANTALLA23:
.PANTALLA24:

			ret
.PANTALLA25:

			ld		a,(PUENTE_EXP)
			cp		2
			ret		nz

			ld 		ix,ATRIBUTOS_SPRITES
			ld		a,(ix+2)
			cp		56
			ret		c
			cp		180
			ret		nc

			ld		a,(ix)
			cp		#3a
			ret		nc

			ld		hl,#e000
			
			ld  	a,(ix+2)
[3]			srl		a
			sla		a
			add		2
			ld		e,a
			ld		d,0
			or		a
			adc		hl,de
			ld		de,32*2*2*11
			adc		hl,de
			ld		e,7
			call	G9kSetVramWrite
			
			ld		hl,978
			call	OUT_ESCRIBE_UN_BYTE

			ret

.PANTALLA26:
.PANTALLA27:

			ret

.PANTALLA28:

			ld		a,(SALTO_COLCHONETA)
			or		a
			jp		z,.PANTALLA28_1

			ld		ix,ATRIBUTOS_SPRITES
			ld		a,(ix)
			sub		2
			call	COMUN_Y_CUATRO_SPRITES
			ld		a,(ix+1)
			and		00100000b
			or		00001110b
			jp		COMUN_PATRON_CUATRO_SPRITES


.PANTALLA28_1:

			ld		ix,ATRIBUTOS_SPRITES
			ld		a,(ix+2)
			cp		#4D
			ret		c
			cp		#52
			ret		nc
			ld		a,(ix)
			cp		#33
			ret		c
			cp		#36
			ret		nc


			ld		a,1
			ld		(SALTO_COLCHONETA),a
			ret

.PANTALLA29:

			ld		a,(ANIM_CAN)
			or		a
			jp		nz,.preparamos_animacion_canyon
			
			ld		a,(OBJETO_TOCANDO_1)
			or		a
			jp		z,.PANTALLA29_2

			ld		a,(POLVORA_GRAND)
			cp		2
			jp		z,.PANTALLA29_1

			ld		a,(POLVORA_PEQUE)
			cp		2
			jp		z,.PANTALLA29_1

			ld		a,(POLVORA_MEDIA)
			cp		2
			jp		nz,.PANTALLA29_2

.PANTALLA29_1:

			ld		ix,TABLA_PEGA_4_POSE_1_DIREC
			ld		iy,SPR_EXPO_CAN
			call	CARGA_ZONA_SPRITES

			ld		a,1
			ld		(ANIM_CAN),a
			ld		a,6
			ld		(QUE_SOY),a

.preparamos_animacion_canyon:

			ld		a,21
			ld		[#7000],a
			call	ANIMACION_CANYON
			ld		a,3
			ld		[#7000],a

			ld		a,(QUE_SOY)
			or		a
			ret		nz
			
			ld		ix,TABLA_PEGA_4_POSE_2_DIREC
			ld		iy,SPR_EXPO_WAC
			call	CARGA_ZONA_SPRITES
			ld		ix,ATRIBUTOS_SPRITES
			ld		a,32
			call	COMUN_PATRON_CUATRO_SPRITES

.PANTALLA29_2:

			ld		a,(OBJETO_TOCANDO_2)
			or		a
			ret		z

			ld		a,28
			call	ENTREGA_UN_OBJETO
			call	BORRA_OBJETO_2_DE_PANTALLA
			call	PUNTOS
			ld		a,28
			call	COLOCA_OBJETO_EN_MARCADOR
			ret

.PANTALLA30:
.PANTALLA31:
.PANTALLA32:
			ret
.PANTALLA33:

			ld		a,26
			jp		SI_NO_TOCA_OBJETO_1_REGRESA

.PANTALLA34:

			ld		a,1
			jp		SI_NO_TOCA_OBJETO_1_REGRESA

.PANTALLA35:
.PANTALLA36:
.PANTALLA37:
.PANTALLA38:
			ret
.PANTALLA39:

			ld		a,15
			jp		SI_NO_TOCA_OBJETO_1_REGRESA

.PANTALLA40:

			ld		a,14
			jp		SI_NO_TOCA_OBJETO_1_REGRESA

.PANTALLA41:
			ret
.PANTALLA42:

			ld		a,4
			jp		SI_NO_TOCA_OBJETO_1_REGRESA

.PANTALLA43:
			ret
.PANTALLA44:

			ld		a,23
			jp		SI_NO_TOCA_OBJETO_1_REGRESA

.PANTALLA45:
.PANTALLA46:
.PANTALLA47:
.PANTALLA48:
			ret
.PANTALLA49:

			ld		a,18
			jp		SI_NO_TOCA_OBJETO_1_REGRESA

.PANTALLA50:
.PANTALLA51:
			ret
.PANTALLA52:

			ld		a,17
			jp		SI_NO_TOCA_OBJETO_1_REGRESA

.PANTALLA53:
.PANTALLA54:
.PANTALLA55:
.PANTALLA56:
.PANTALLA57:
.PANTALLA58:
.PANTALLA59:
			ret
.PANTALLA60:

			ld		a,20
			jp		SI_NO_TOCA_OBJETO_1_REGRESA

.PANTALLA61:
.PANTALLA62:
.PANTALLA63:
.PANTALLA64:
.PANTALLA65:
			ret
.PANTALLA66:

			ld		a,16
			jp		SI_NO_TOCA_OBJETO_1_REGRESA

.PANTALLA67:
.PANTALLA68:
			ret
.PANTALLA69:

			ld		a,22
			jp		SI_NO_TOCA_OBJETO_1_REGRESA

SI_NO_TOCA_OBJETO_1_REGRESA:

			ld		(var_cir_1),a
			ld		a,(OBJETO_TOCANDO_1)
			or		a
			ret		z
			ld		a,(var_cir_1)
			call	ENTREGA_UN_OBJETO
			call	BORRA_OBJETO_1_DE_PANTALLA
			call	PUNTOS
			ld		a,(var_cir_1)
			call	COLOCA_OBJETO_EN_MARCADOR
			ret			

PUNTOS:

			ret

COLOCA_OBJETO_EN_MARCADOR:

			ld		ix,MONOCICLO
			ld		e,a
			ld		d,0
			add		ix,de
			ld		a,(ix)
			cp		1
			ret		nz


ENTREGA_UN_OBJETO:

			ld		ix,MONOCICLO
			ld		e,a
			ld		d,0
			add		ix,de
			ld		a,(ix)

			or		a
			ret		nz
			inc		a
			ld		(ix),a

			call	ORGANIZA_OBJETOS
			call	COLOCA_OBJETOS_BOLSILLO_Y_USANDO
			;puntos
			ret			
BORRA_OBJETO_1_DE_PANTALLA:

		ld		ix,ATRIBUTOS_SPRITES+67
		jp		COMUN_BORRA_OBJETO

BORRA_OBJETO_2_DE_PANTALLA:

		ld		ix,ATRIBUTOS_SPRITES+83

COMUN_BORRA_OBJETO:

		ld		a,220
		ld		(ix),a
		ld		(ix+4),a
		ld		(ix+8),a
		ld		(ix+12),a
		ret
			
COGE_UN_OBJETO_1:

			xor		a
			ld		(OBJETO_TOCANDO_1),a
			ld		iy,ATRIBUTOS_SPRITES+64
			call	COMUN_COGE_UN_OBJETO

			ld		a,1
			ld		(OBJETO_TOCANDO_1),a
			ret

COGE_UN_OBJETO_2:

			xor		a
			ld		(OBJETO_TOCANDO_2),a
			ld		iy,ATRIBUTOS_SPRITES+80
			call	COMUN_COGE_UN_OBJETO

			ld		a,1
			ld		(OBJETO_TOCANDO_2),a
			ret

COMUN_COGE_UN_OBJETO:

			ld		ix,ATRIBUTOS_SPRITES
			ld		a,(iy)
			add		10
			ld		b,a
			ld		a,(ix)
			add		22
			cp		b
			jp		c,REGRESA_SIN_EFECTO

			ld		a,b
			add		12
			ld		b,a
			ld		a,(ix)
			add		10
			cp		b
			jp		nc,REGRESA_SIN_EFECTO

			ld		a,(iy+2)
			add		10
			ld		b,a
			ld		a,(ix+2)
			add		22
			cp		b
			jp		c,REGRESA_SIN_EFECTO

			ld		a,b
			add		12
			ld		b,a
			ld		a,(ix+2)
			add		10
			cp		b
			jp		nc,REGRESA_SIN_EFECTO			

			ret

REGRESA_SIN_EFECTO:

			pop		hl
			ret

MIRA_GRAVEDAD:

			ld		a,(SPACE_PULSADO)
			or		a
			ret		nz

			ld		a,(SALTO_COLCHONETA)
			cp		1
			ret		z

			ld		a,(QUE_SOY)
			cp		1
			ret		z
			cp		5
			ret		z

.mira_si_sube:

			ld		a,(ATENCION_AL_SALTO)
			or		a
			jp		z,.mira_si_baja

			xor		a
			ld		(ATENCION_AL_SALTO),a

			ld		hl,(TYLE_POSIC_13)
			ld		de,736
			call	DCOMPR	
			jp		c,.mira_si_baja

			ld		ix,ATRIBUTOS_SPRITES
			ld		a,(ix)
			dec		a
			jp		COMUN_Y_CUATRO_SPRITES

.mira_si_baja:

			ld		hl,(TYLE_POSIC_1)
			ld		de,544
			call	DCOMPR		
			jp		nc,.reinicia_caida_o_muere
		
			ld		hl,(TYLE_POSIC_2)
			ld		de,544
			call	DCOMPR		
			jp		nc,.reinicia_caida_o_muere
			jp		.fall

.reinicia_caida_o_muere:

			ld		a,(SUMA_ALTURA_CAIDA)
			cp		30
			jp		nc,.reinicia_caida_o_muere_2
			xor		a
			ld		(SUMA_ALTURA_CAIDA),a
			ld		a,(MUERTE)
			or		a
			ret		nz

			ld		a,(PANTALLA_ACTUAL)
			ld		(PANTALLA_ACTUAL_SAVE),a

			ld		a,(MEMORIZAMOS_POSICION)
			or		a
			ret		z
			xor		a
			ld		(MEMORIZAMOS_POSICION),a
			ld		ix,ATRIBUTOS_SPRITES
			ld		a,(ix)
			ld		(Y_SAVE),a
			ld		a,(ix+2)
			ld		(X_SAVE),a
			xor		a
			ld		(QUIERE_CUERDA),a

			ret

.reinicia_caida_o_muere_2:

			ld		a,1
			ld		(MUERTE),a
			xor		a
			ld		(SUMA_ALTURA_CAIDA),a
			ret

.fall:

			ld		a,(PANTALLA_ACTUAL)
			cp		25
			jp		nz,.fall_cont

			ld		a,(PUENTE_EXP)
			cp		2
			jp		nz,.fall_cont

			ld		ix,ATRIBUTOS_SPRITES
			ld		a,(ix)
			cp		#38
			jp		c,.fall_cont
			cp		#40
			ret		c

.fall_cont:

			ld		ix,ATRIBUTOS_SPRITES
			ld		a,(ix)
			add		2
			call	COMUN_Y_CUATRO_SPRITES
			ld		a,1
			ld		(ATENCION_AL_SALTO),a
			
			ld		a,(SUMA_ALTURA_CAIDA)
			inc		a
			ld		(SUMA_ALTURA_CAIDA),a

			ld		a,(QUIERE_CUERDA)
			cp		2
			jp		z,.no_morira
			ld		a,(QUE_SOY)
			cp		6
			jp		z,.no_morira

			ld		a,(PANTALLA_ACTUAL)
			cp		28
			jp		z,.fall_final
			cp		16
			jp		z,.fall_final

			ld		a,(PARAGUAS)
			cp		2
			jp		nz,.fall_final

.no_morira:

			ld		a,(SUMA_ALTURA_CAIDA)
			and		00000111b
			ld		(SUMA_ALTURA_CAIDA),a

.fall_final:

			pop		hl
			jp		BUCLE_CENTRAL.bucle_central_1

CONTROLA_SI_SALE_DE_PANTALLA:

			ld		a,(QUE_SOY)
			cp		1
			jp		z,.d_i_a_a_aspiradora
			cp		5
			jp		z,.d_i_a_a_aspiradora

			call	.a_a
			call	.d_i
			ret

.a_a:

			ld		ix,ATRIBUTOS_SPRITES
			ld		a,(ix)

.abajo:
			cp		33
			jp		c,.arriba_globo
			cp		140
			jp		c,.abajo_2
			cp		240
			jp		c,.arriba

			ret

.abajo_2:

			ld		a,(ix)
			cp		112
			ret		c

			ld		a,(PANTALLA_ACTUAL)
			add		12
			ld		(PANTALLA_ACTUAL),a
			pop		hl
			ld		a,5
			ld		(DIRECCION_DONDE_VAMOS),a
			jp		PINTA_LA_PANTALLA_DE_INICIO

.arriba_globo:

			ld		a,(QUE_SOY)
			cp		5
			ret		nz
			ld		a,(PANTALLA_ACTUAL)
			cp		15
			ret		nz

.arriba:

			ld		a,(PANTALLA_ACTUAL)
			sub		12
			ld		(PANTALLA_ACTUAL),a
			pop		hl
			ld		a,1
			ld		(DIRECCION_DONDE_VAMOS),a
			jp		PINTA_LA_PANTALLA_DE_INICIO

.d_i:

			ld		ix,ATRIBUTOS_SPRITES
			ld		a,(ix+2)

.derecha:

			cp		255-32
			jp		c,.izquierda
			ld		a,(DIRECCION_DONDE_VAMOS)
			cp		3
			ret		nz

			ld		a,(PANTALLA_ACTUAL)
			cp		11
			jp		z,.right_special
			cp		23
			jp		z,.right_special
			cp		35
			jp		z,.right_special
			cp		47
			jp		z,.right_special
			cp		59
			jp		z,.right_special
			cp		71
			jp		z,.right_special
			inc		a
			ld		(PANTALLA_ACTUAL),a
			pop		hl
			jp		PINTA_LA_PANTALLA_DE_INICIO

.right_special:

			sub		11
			ld		(PANTALLA_ACTUAL),a
			pop		hl
			jp		PINTA_LA_PANTALLA_DE_INICIO

.izquierda:

			cp		1
			ret		nc
			ld		a,(DIRECCION_DONDE_VAMOS)
			cp		7
			ret		nz			

			ld		a,(PANTALLA_ACTUAL)
			cp		0
			jp		z,.left_special			
			cp		12
			jp		z,.left_special			
			cp		24
			jp		z,.left_special			
			cp		36
			jp		z,.left_special			
			cp		48
			jp		z,.left_special			
			cp		60
			jp		z,.left_special			
			dec		a
			ld		(PANTALLA_ACTUAL),a
			pop		hl
			jp		PINTA_LA_PANTALLA_DE_INICIO

.left_special:

			add		11
			ld		(PANTALLA_ACTUAL),a
			pop		hl
			jp		PINTA_LA_PANTALLA_DE_INICIO

.d_i_a_a_aspiradora:

			call	.d_i_aspiradora
			ld		a,(PANTALLA_ACTUAL)
			cp		20
			jp		z,.a_a_aspiradora
			cp      8
			jp		nz,.a_a

.a_a_aspiradora:

			ld		a,(ix)

.abajo_aspiradora:

			cp		96
			jp		c,.arriba_aspiradora
			ld		a,(PANTALLA_ACTUAL)
			cp		20
			jp		nz,.abajo_2
			
			ld		a,96
			jp		.comun_arr_aba_aspir

.arriba_aspiradora:

			ld		a,(DIRECCION_DONDE_VAMOS)
			cp		1
			ret		nz

			ld		a,(ix)
			cp		2
			ret		nc
			ld		a,(PANTALLA_ACTUAL)
			cp		8
			jp		nz,.arriba

			ld		a,2

.comun_arr_aba_aspir:

			jp		COMUN_Y_CUATRO_SPRITES

.d_i_aspiradora:

			ld		ix,ATRIBUTOS_SPRITES
			ld		a,(ix+2)

.derecha_aspiradora:

			cp		255-32
			jp		c,.izquierda_aspiradora
			ld		a,255-33
			jp		.comun_der_izq_aspir

.izquierda_aspiradora:

			cp		4
			ret		nc
			ld		a,2

.comun_der_izq_aspir:

			jp		COMUN_X_CUATRO_SPRITES	

STICK:

			ld		a,(QUIERE_CUERDA)
			cp		2
			jp		nz,.stick_continua
			ld		ix,ATRIBUTOS_SPRITES
			ld		a,(ix+2)
			cp		#36
			jp		c,.stick_continua
			cp		#3c
			jp		nc,.stick_continua
			ld		a,(PANTALLA_ACTUAL)
			cp		16
			jp		z,.stick_continua_2
			cp		28
			jp		z,.stick_continua_2

.stick_continua:

			ld		a,(SPACE_PULSADO)
			or		a
			jp		nz,.jump_on_place

			ld		a,(SALTO_COLCHONETA)
			cp		1
			ret		z

			ld		a,(QUE_SOY)
			cp		5
			jp		z,.stick_real

			ld		a,(QUIERE_CUERDA)
			cp		2
			jp		z,.stick_real

			xor		a
			call	GTTRIG
			ld		(SPACE_PULSADO),a
			jp		.stick_real

.stick_continua_2:

			ld		a,5
			ld		(DIRECCION_DONDE_VAMOS),a
			jp		.stick_real_2

.stick_real:

			ld		a,(QUIERE_CUERDA)
			or		a
			jp		z,.stick_real_1
			cp		2
			jp		z,.stick_real_1

			ld		a,(FLAUTA)
			cp		2
			jp		c,.stick_real_0_5

			ld		ix,ATRIBUTOS_SPRITES
			ld		a,(ix+2)
			sub		2
			ld		(ix+2),a

.stick_real_0_5:

			ld		a,3
			ld		(DIRECCION_DONDE_VAMOS),a
			jp		.stick_real_2

.stick_real_1:

			xor		a												; Comprobando si ha tocado los cursores
			call	GTSTCK		
			or		a
			ld		(DIRECCION_DONDE_VAMOS),a
			ret		z

.stick_real_2:

			ld		ix,ATRIBUTOS_SPRITES
			cp		1
			jp		z,.up
			cp		3
			jp		z,.right
			cp		5
			jp		z,.down
			cp		7
			jp		z,.left

			ld		a,(SPACE_PULSADO)
			or		a
			ret		z

			ld		a,(QUE_SOY)
			cp		1
			ret		z
			
.jump_on_place:

			ld		ix,ATRIBUTOS_SPRITES
			
			ld		a,(ix+1)
			and		10111111b
			ld		(ix+1),a
			ld		a,(ix+5)
			and		10111111b
			ld		(ix+5),a
			ld		a,(ix+9)
			and		10111111b
			ld		(ix+9),a
			ld		a,(ix+13)
			and		10111111b
			ld		(ix+13),a

			ld		a,(PROCESO_DE_SALTO)

			ld		a,(DIRECCION_DONDE_VAMOS)
			cp		3
			jp		z,.be_ware_right
			cp		7
			jp		nz,.control_fall

.be_ware_left

			ld		a,(PROCESO_DE_SALTO)
			cp		7
			jp		c,.see_left_up
			cp		8
			jp		z,.see_left
			jp		.see_left_down

.see_left_up:

			ld		hl,(TYLE_POSIC_6)
			ld		de,864
			call	DCOMPR
			jp		c,.control_fall

.borra_desplazamiento:

			ld		a,0
			ld		(DIRECCION_DONDE_VAMOS),a
			jp		.doing_the_jump

.see_left:

			ld		hl,(TYLE_POSIC_5)
			ld		de,864
			call	DCOMPR
			jp		c,.control_fall
			jp		.borra_desplazamiento

.see_left_down:

			ld		hl,(TYLE_POSIC_5)
			ld		de,864
			call	DCOMPR
			jp		nc,.borra_desplazamiento
			ld		hl,(TYLE_POSIC_9)
			ld		de,864
			call	DCOMPR
			jp		c,.control_fall
			jp		.borra_desplazamiento

.be_ware_right:

			ld		a,(PROCESO_DE_SALTO)
			cp		7
			jp		c,.see_right_up
			cp		8
			jp		z,.see_right
			jp		.see_right_down

.see_right_up:

			ld		hl,(TYLE_POSIC_3)
			ld		de,864
			call	DCOMPR
			jp		c,.control_fall
			jp		.borra_desplazamiento

.see_right:

			ld		hl,(TYLE_POSIC_4)
			ld		de,864
			call	DCOMPR
			jp		c,.control_fall
			jp		.borra_desplazamiento

.see_right_down:

			ld		hl,(TYLE_POSIC_4)
			ld		de,864
			call	DCOMPR
			jp		nc,.borra_desplazamiento
			ld		hl,(TYLE_POSIC_10)
			ld		de,864
			call	DCOMPR
			jp		c,.control_fall
			jp		.borra_desplazamiento

.control_fall:

			ld		a,(PROCESO_DE_SALTO)
			cp		7
			jp		c,.doing_the_jump

			ld		hl,(TYLE_POSIC_11)
			ld		de,736
			call	DCOMPR			
			jp		nc,.stoping_the_jump

			ld		hl,(TYLE_POSIC_12)
			ld		de,736
			call	DCOMPR	
			jp		c,.doing_the_jump

.stoping_the_jump:

			ld		a,15
			ld		(PROCESO_DE_SALTO),a
			ld		a,1
			ld		(ATENCION_AL_SALTO),a

.doing_the_jump:

			ld		iy,RELACION_POSICION_DEL_SALTO
			ld		a,(PROCESO_DE_SALTO)
			add		a
			ld		d,0
			ld		e,a
			add		iy,de
			ld		l,(iy)
			ld		h,(iy+1)
			jp		hl

.paso_1:

			ld		iy,DATOS_PASO_1_SALTO
			jp		.rutina_salto

.paso_2:

			ld		iy,DATOS_PASO_2_SALTO
			jp		.rutina_salto

.paso_3:

			ld		iy,DATOS_PASO_3_SALTO
			jp		.rutina_salto

.paso_4:

			ld		iy,DATOS_PASO_4_SALTO
			jp		.rutina_salto

.paso_5:

			ld		iy,DATOS_PASO_5_SALTO
			jp		.rutina_salto

.paso_6:

			ld		iy,DATOS_PASO_6_SALTO
			jp		.rutina_salto

.paso_7:

			ld		iy,DATOS_PASO_7_SALTO
			jp		.rutina_salto

.paso_8:

			ld		iy,DATOS_PASO_8_SALTO
			jp		.rutina_salto

.paso_9:

			ld		iy,DATOS_PASO_9_SALTO
			jp		.rutina_salto

.rutina_salto:

			ld		b,(iy)
			ld		c,(iy+1)
			ld		a,(ix+1)
			or		b
			and		c
			ld		(ix+1),a
			ld		b,(iy+2)
			ld		c,(iy+3)
			ld		a,(ix+5)
			or		b
			and		c
			ld		(ix+5),a
			ld		b,(iy+4)
			ld		c,(iy+5)
			ld		a,(ix+9)
			or		b
			and		c
			ld		(ix+9),a
			ld		b,(iy+6)
			ld		c,(iy+7)
			ld		a,(ix+13)
			or		b
			and		c
			ld		(ix+13),a

			ld		a,(iy+8)
			cp		1
			jp		z,.aumenta_la_y

.disminuye_la_y:

			ld		b,(iy+9)
			ld		a,(ix)
			sub		b
			jp		.comun_aum_dism

.aumenta_la_y:

			ld		b,(iy+9)
			ld		a,(ix)
			add		b

.comun_aum_dism:

			call	COMUN_Y_CUATRO_SPRITES

			ld		a,(iy+10)
			or		a
			jp		z,.comun_salto

			xor		a
			ld		(PROCESO_DE_SALTO),a
			ld		(SPACE_PULSADO),a
			ld		a,2
			ld		(POSE_PROTA),a
			ret

.comun_salto:

			ld		a,(DIRECCION_DONDE_VAMOS)
			cp		3
			jp		z,.salto_derecha
			cp		7
			jp		z,.salto_izquierda
			jp		.solo_salto

.salto_derecha:

			ld		a,(ix+2)
			add		2
			jp		.comun_ambos_saltos

.salto_izquierda:

			ld		a,(ix+2)
			sub		2

.comun_ambos_saltos:

			call	COMUN_X_CUATRO_SPRITES
			jp		.solo_salto

.prev_solo_salto:

			xor		a
			ld		(DIRECCION_DONDE_VAMOS),a

.solo_salto:

			ld		a,(PROCESO_DE_SALTO)
			inc		a
			ld		(PROCESO_DE_SALTO),a
			ret

.right:

			ld		a,(QUE_SOY)
			cp		1
			jp		z,.right_aspiradora

			ld		hl,(TYLE_POSIC_4)
			ld		de,864
			call	DCOMPR
			ret		nc

			call	.right_left_comun_1
			and		10011111b
			or		00100000b
			call	.right_left_comun_2
			and		10011111b
			or		00100000b
			call	.right_left_comun_3
			and		10011111b
			or		00100000b
			call	.right_left_comun_4
			and		10011111b
			or		00100000b
			call	.right_left_comun_5
			add		2
			call	COMUN_X_CUATRO_SPRITES

			ld		a,(QUE_SOY)
			cp		5
			ret		nz
			ld		a,(SOPLADOR)
			cp		2
			ret		nz

.extra_globo_right:

			ld		ix,ATRIBUTOS_SPRITES+64
			ld		a,(ix+2)
			add		2
			call	COMUN_X_CUATRO_SPRITES
			ld		ix,ATRIBUTOS_SPRITES+80
			ld		a,(ix+2)
			add		2
			jp		COMUN_X_CUATRO_SPRITES			


.right_aspiradora:

			ld		a,(ix+1)
			or		00100000b
			ld		(ix+1),a
			ld		a,(ix+5)
			or		00100000b
			ld		(ix+5),a
			ld		a,(ix+9)
			or		00100000b
			ld		(ix+9),a
			ld		a,(ix+13)
			or		00100000b
			ld		(ix+13),a
			call	.right_left_comun_6
			add		2
			jp		COMUN_X_CUATRO_SPRITES

.left:

			ld		a,(QUE_SOY)
			cp		1
			jp		z,.left_aspiradora

			ld		hl,(TYLE_POSIC_5)
			ld		de,864
			call	DCOMPR
			ret		nc

			call	.right_left_comun_1
			and		10011111b
			call	.right_left_comun_2
			and		10011111b
			call	.right_left_comun_3
			and		10011111b
			call	.right_left_comun_4
			and		10011111b
			call	.right_left_comun_5
			sub		2
			call	COMUN_X_CUATRO_SPRITES

			ld		a,(QUE_SOY)
			cp		5
			ret		nz
			ld		a,(SOPLADOR)
			cp		2
			jp		z,.extra_globo_left
			ld		a,(MANIFIESTO)
			cp		2
			ret		nz

.extra_globo_left:

			ld		ix,ATRIBUTOS_SPRITES+64
			ld		a,(ix+2)
			sub		2
			call	COMUN_X_CUATRO_SPRITES
			ld		ix,ATRIBUTOS_SPRITES+80
			ld		a,(ix+2)
			sub		2
			jp		COMUN_X_CUATRO_SPRITES

.left_aspiradora:

			ld		a,(ix+1)
			and		11011111b
			ld		(ix+1),a
			ld		a,(ix+5)
			and		11011111b
			ld		(ix+5),a
			ld		a,(ix+9)
			and		11011111b
			ld		(ix+9),a
			ld		a,(ix+13)
			and		11011111b
			ld		(ix+13),a

			call	.right_left_comun_6
			sub		2
			jp		COMUN_X_CUATRO_SPRITES

.right_left_comun_1:

			ld		a,(POSE_PROTA)
			inc		a
			and		00000011
			ld		(POSE_PROTA),a
			ld		b,a
			ld		a,(ix+1)
			ret

.right_left_comun_2:

			call	.suma_pose
			ld		(ix+1),a
			ld		a,(ix+5)
			ret

.right_left_comun_3:

			call	.suma_pose
			ld		(ix+5),a
			ld		a,(ix+9)
			ret

.right_left_comun_4:

			call	.suma_pose
			ld		(ix+9),a
			ld		a,(ix+13)
			ret

.right_left_comun_5:

			call	.suma_pose
			ld		(ix+13),a

.right_left_comun_6:

			ld		a,(ix+2)
			ret

.up_down_comun_1:

			call	.suma_pose
			ld		(ix+13),a
			ld		a,(ix)
			ret

.suma_pose:

			push	af
			ld		a,b
			or		a
			jp		nz,.suma

.resta:		

			pop		af
			sub		6
			ret

.suma:
			pop		af
			add		00000010b
			ret

.up:

			ld		a,(QUE_SOY)
			cp		1
			jp		nz,.up_test_1
			ld		a,(ix)
			sub		2
			jp		COMUN_Y_CUATRO_SPRITES

.up_test_1:

			ld		hl,(TYLE_POSIC_16)
			ld		de,544
			call	DCOMPR
			jp		c,.up_test_2
			ld		de,608
			call	DCOMPR
			jp		nc,.up_test_2

			ld		hl,(TYLE_POSIC_17)
			ld		de,544
			call	DCOMPR
			jp		c,.up_test_2
			ld		de,608
			call	DCOMPR
			jp		c,.seeling

.up_test_2:

			ld		hl,(TYLE_POSIC_14)
			ld		de,544
			call	DCOMPR
			jp		c,.not_up_down
			ld		de,608
			call	DCOMPR
			jp		nc,.not_up_down

			ld		hl,(TYLE_POSIC_15)
			ld		de,544
			call	DCOMPR
			jp		c,.not_up_down
			ld		de,608
			call	DCOMPR
			jp		nc,.not_up_down

.seeling:

			ld		hl,(TYLE_POSIC_18)
			ld		de,864
			call	DCOMPR
			jp		nc,.not_up_down

			ld		hl,(TYLE_POSIC_19)
			ld		de,864
			call	DCOMPR
			jp		nc,.not_up_down

.real_up:

			call	.right_left_comun_1
			or		01000000b
			and		11011111b
			call	.right_left_comun_2
			or		01000000b
			and		11011111b
			call	.right_left_comun_3
			or		01000000b
			and		11011111b
			call	.right_left_comun_4
			or		01000000b
			and		11011111b
			call	.up_down_comun_1
			sub		2
			jp		COMUN_Y_CUATRO_SPRITES


.down:

			ld		a,(QUIERE_CUERDA)
			cp		2
			jp		z,.real_down

			ld		a,(QUE_SOY)
			cp		1
			jp		nz,.down_test_1
			ld		a,(ix)
			add		2
			cp		#58
			jp		c,COMUN_Y_CUATRO_SPRITES
			ld		a,(PANTALLA_ACTUAL)
			cp		20
			ret		z
			ld		a,(ix)
			add		2
			jp		COMUN_Y_CUATRO_SPRITES

.down_test_1:

			ld		hl,(TYLE_POSIC_16)
			ld		de,544
			call	DCOMPR
			jp		c,.not_up_down
			ld		de,608
			call	DCOMPR
			jp		nc,.not_up_down

			ld		hl,(TYLE_POSIC_17)
			ld		de,544
			call	DCOMPR
			jp		c,.not_up_down
			ld		de,608
			call	DCOMPR
			jp		nc,.not_up_down

.real_down:

			call	.right_left_comun_1
			or		01000000b
			and		11011111b
			call	.right_left_comun_2
			or		01000000b
			and		11011111b
			call	.right_left_comun_3
			or		01000000b
			and		11011111b
			call	.right_left_comun_4
			or		01000000b
			and		11011111b
			call	.up_down_comun_1
			add		2
			jp		COMUN_Y_CUATRO_SPRITES

.not_up_down:

			call	.right_left_comun_1
			call	.right_left_comun_2
			call	.right_left_comun_3
			call	.right_left_comun_4
			call	.right_left_comun_5
			jp		COMUN_X_CUATRO_SPRITES

COMUN_X_CUATRO_SPRITES:

			ld		(ix+2),a
			ld		(ix+10),a
			add		16
			ld		(ix+6),a
			ld		(ix+14),a
			xor		a
			ret

COMUN_Y_CUATRO_SPRITES:

			ld		(ix),a
			ld		(ix+4),a
			add		16
			ld		(ix+8),a
			ld		(ix+12),a
			xor		a
			ret

COMUN_PATRON_CUATRO_SPRITES:

			ld		(ix+1),a
			inc		a
			ld		(ix+5),a
			add		15
			ld		(ix+9),a
			inc		a
			ld		(ix+13),a
			ret	

COMUN_ATRIBUTOS_CUATRO_SPRITES:

			ld		(ix+3),a
			ld		(ix+7),a

.solo_dos:

			ld		(ix+11),a
			ld		(ix+15),a
			ret

PINTA_SPRITES:

			ld		hl,#FE00
			ld		e,3
			call	G9kSetVramWrite

			ld		ix,ATRIBUTOS_SPRITES

.salvamos_xy_por_si_la_cambiamos:

			ld		a,(ix)
			push	af
			ld		a,(ix+2)
			push	af

.si_esta_en_globo_cambiamos_x:

			ld		a,(PANTALLA_ACTUAL)
			cp		15
			jp		z,.control_de_globo
			cp		3
			jp		nz,.seguimos_segun_lo_planeado

.control_de_globo:

			ld		a,(QUE_SOY)
			cp		5
			jp		nz,.seguimos_segun_lo_planeado

			ld		a,(ix+82)
			call	COMUN_X_CUATRO_SPRITES
			ld		a,(ix+80)
			call	COMUN_Y_CUATRO_SPRITES
			xor		a
			call	COMUN_PATRON_CUATRO_SPRITES
			xor		a
			ld		(POSE_PROTA),a

.seguimos_segun_lo_planeado:

			xor		a
			ld		(var_cir_1),a
			ld		b,8

.bucle_prota:

			ld		h,(ix+1)
			ld		l,(ix)
			
			ld		a,(var_cir_1)
			or		a
			jp		nz,.bucle_prota_1

			ld		c,1
			ld		a,l
			sub		c
			ld		l,a

.bucle_prota_1:

			ld		a,(var_cir_1)
			inc		a
			and		00000001b
			ld		(var_cir_1),a

			ld		a,b
			and		00000001b
			or		a
			jp		nz,.salvamos_bytes
			ld		a,(ix+2)
			cp		#40
			jp		nc,.detras_de_b
			ld		a,(ix)
			cp		#40
			jp		nc,.detras_de_b

.detras_de_a:

			ld		a,(ix+3)
			and		11001111b
			ld		(ix+3),a
			jp		.salvamos_bytes

.detras_de_b:

			ld		a,(ix+3)
			or		00100000b
			ld		(ix+3),a

.salvamos_bytes:

			call	OUT_ESCRIBE_UN_BYTE
			ld		de,2
			add		ix,de
			djnz	.bucle_prota

			ld		ix,ATRIBUTOS_SPRITES

			pop		af
			call	COMUN_X_CUATRO_SPRITES
			pop		af
			call	COMUN_Y_CUATRO_SPRITES

.objeto:

			ld		hl,#FE40
			ld		e,3
			call	G9kSetVramWrite
			
			ld		ix,ATRIBUTOS_SPRITES
			ld		de,64
			add		ix,de

			ld		b,16

.bucle_objeto:

			ld		h,(ix+1)
			ld		l,(ix)
			call	OUT_ESCRIBE_UN_BYTE
			ld		de,2
			add		ix,de
			djnz	.bucle_objeto

			ret

CARGA_ZONA_SPRITES:
		
/*
	Direccion inicio a pintar en vram g9(3 bytes)
	bytes verticales (1bytes)
	bytes horizontales(1byte)
*/
			ld		a,(PERSONAJE) ; Tabla con datos de copia
			add		16
			ld		[#7000],a

			ld		e,(ix)
			ld		l,(ix+1)
			ld		h,(ix+2)
			call	G9kSetVramWrite	

			ld		a,(ix+3)
			ld		b,a

.bucle_exterior:

			push	bc
			ld		a,(ix+4)
			ld		b,a

.bucle_interior:

			push	bc
			push	hl
			ld		l,(iy) ; bytes del dibujo
			ld		h,(iy+1)
			call	OUT_ESCRIBE_UN_BYTE
			pop		hl
			ld		de,2
			add		iy,de
			pop		bc
			djnz	.bucle_interior
			ld		de,128
			or		a
			adc		hl,de
			ld		e,(ix)
			call	G9kSetVramWrite	



			pop		bc
			djnz	.bucle_exterior

			ld		a,3
			ld		[#7000],a

			ret

TABLA_PEGA_1_POSE_2_DIREC:

			db		#01,#00,#00,64,8 		; donde pintar 3, dp h, dp l, cant lineas horiz, cant lineas vertic

TABLA_PEGA_1_POSE_1_DIREC:

			db		#01,#00,#00,32,8 		; donde pintar 3, dp h, dp l, cant lineas horiz, cant lineas vertic

TABLA_PEGA_4_POSE_2_DIREC:

			db		#01,#00,#00,64,32 		; donde pintar 3, dp h, dp l, cant lineas horiz, cant lineas vertic

TABLA_PEGA_4_POSE_1_DIREC:

			db		#01,#00,#00,32,32 		; donde pintar 3, dp h, dp l, cant lineas horiz, cant lineas vertic

RUTINA_RETRASO:

			push	de
			ld		de,1
			or		a
			sbc		hl,de
			ld		a,h
			or		l
			or		a
			pop		de
			ret		z
			jp		RUTINA_RETRASO

			include	"TABLAS/TABLAS SOBRE SALTO.asm"

VALORES_INICIALES_ATRIBUTOS_SPRITES:

			include	"TABLAS/TABLA VAL INI ATRIB SPRITES.asm"

DATA_COLOR_EXPLO:

			include "PALETAS/SPRITES EXPLORADOR.PAL9G"

DATA_COLOR_TILES:

			include	"PALETAS/MINI TILES GLOBAL.PAL9G"

DATA_COLOR_MARCADOR:

			include "PALETAS/MARCADOR ALTO.PAL9G"

CAMBIA_PAGINA_2:

			ld		(PAGINA_A_LA_QUE_VOLVER),a
			ld		[#7000],a
				
			ret

GFX9990_NO_DETECTADA:
		
			ld		bc,31
			ld		de,123
			ld		hl,TEXTO_NO_HAY_GFX9000
			call	LDIRVM

			jr		$														

GFX9990_DETECTADA:

			ld		bc,31
			ld		de,123
			ld		hl,TEXTO_SI_HAY_GFX9000
			jp		LDIRVM
		
TEXTO_NO_HAY_GFX9000:

			db		"GFX9000/Powergraph no detectada"				;31				

TEXTO_SI_HAY_GFX9000:

			db		"Esto  sigue  GFX9000/Powergraph"				;31				

			include	"RECURSOS BASICOS/RUTINAS 9990.asm"

			ds		#8000-$													;llenamos de 0 hasta el final del bloque
								
; ********** FIN PAGINA 000 DEL MEGAROM **********)))	

; --------------------------------------------------
; (((********** PAGINA 001 DEL MEGAROM **********

				org		#8000

TILES_A_1:		incbin	"GRAFICOS/TILES A1.DAT"

				ds		#C000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 001 DEL MEGAROM **********)))			
; --------------------------------------------------

; --------------------------------------------------
; (((********** PAGINA 002 DEL MEGAROM **********

				org		#8000

TILES_A_2:		incbin	"GRAFICOS/TILES A2.DAT"

				ds		#C000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 002 DEL MEGAROM **********)))			
; --------------------------------------------------

; --------------------------------------------------
; (((********** PAGINA 003 DEL MEGAROM **********
; Pintar la pantalla que toca. mapa-hypertiles-tiles

				org		#8000

PINTAMOS_PANTALLA_EN_LA_QUE_ESTAMOS:

				call	SPRITES_DESAPARECIDOS
				call	PLANO_B_DESAPARECIDO
				call	CALCULA_PANTALLA_EN_LA_QUE_ESTA
				call	SITUA_EL_PUNTERO_EN_EL_MAPA_SEGUN_PANTALLA
				call	CALCULA_VRAM_DONDE_PINTAR
				call	PINTA_PATRONES_PANTALLA_A
				call	NUEVA_POSICION_DE_SCROLL
				call	CREA_SCROLL_ADECUADO
				call	TILES_DE_B
				ret

SPRITES_DESAPARECIDOS:


				ld		ix,	ATRIBUTOS_SPRITES+64
				ld		b,32
				ld		a,220

.bucle_borra_objeto:

				ld		(ix),a
				ld		de,1
				add		ix,de
				djnz	.bucle_borra_objeto

				ld		ix,ATRIBUTOS_SPRITES
				ld		a,(ix)
				ld		(var_cir_7),a
				ld		a,220
				ld		(ix),a
				ld		(ix+4),a
				ld		(ix+8),a
				ld		(ix+12),a
				
				ld		a,(ix+67)
				and		11001111b
				ld		(ix+67),a
				ld		(ix+71),a
				ld		(ix+75),a
				ld		(ix+79),a
				ld		(ix+83),a
				ld		(ix+87),a
				ld		(ix+91),a
				ld		(ix+95),a

				call	PINTA_SPRITES

				ld		ix,ATRIBUTOS_SPRITES
				ld		a,(var_cir_7)
				jp		COMUN_Y_CUATRO_SPRITES

PLANO_B_DESAPARECIDO:

				ld		e,7
				ld		hl,#e000
				push	hl
				call	G9kSetVramWrite
				ld		hl,960
				ld		bc,0
				ld		a,0
				ld      (var_cir_1),a

.bucle:

				push	hl
				push	bc
				pop		hl
				call	OUT_ESCRIBE_UN_BYTE
				ld		de,1
				or		a
				adc		hl,de

				push	hl
				pop		bc
				pop		hl

				ld		a,(var_cir_1)
				inc		a
				ld		(var_cir_1),a
				cp		32
				jp		nz,.bucle_2

				xor		a
				ld		(var_cir_1),a

				pop		de
				push	hl
				push	de
				pop		hl
				ld		de,128
				or		a
				adc		hl,de
				ld		e,7
				call	G9kSetVramWrite
				pop		de
				push	hl
				push	de
				pop		hl
				ld		de,1

.bucle_2:

				or		a
				sbc		hl,de
				ld		a,h
				or		l
				or		a
				jp		nz,.bucle
				pop		hl
				ret

NUEVA_POSICION_DE_SCROLL:

				push	ix
				ld		ix,RELACION_PARTE_VRAM_POS_SCROLL
				ld		a,(POSICION_ACTUAL_SCROLL)
	[2]			add		a
				ld		e,a
				ld		d,0
				add		ix,de
				ld		l,(ix)
				ld		h,(ix+1)
				ld		(pos_scroll_x_A_objet),hl
				ld		l,(ix+2)
				ld		h,(ix+3)
				ld		(pos_scroll_y_A_objet),hl
				pop		ix
				ret

CREA_SCROLL_ADECUADO:

				ld		a,(DIRECCION_DONDE_VAMOS)
				cp		1
				jp		z,.up
				cp		3
				jp		z,.right
				cp		5
				jp		z,.down
				cp		7
				jp		z,.left
				ret

.up:

				call	.scroll_adecuado_comun_1_vertical
				sbc		hl,de
				call	.scroll_adecuado_comun_2_vertical				
				jp		.up

.down:

				call	.scroll_adecuado_comun_1_vertical
				adc		hl,de
				call	.scroll_adecuado_comun_2_vertical
				jp		.down

.left:

				call	.scroll_adecuado_comun_1_horizontal
				sbc		hl,de
				call	.scroll_adecuado_comun_2_horizontal
				jp		.left

.right:

				call	.scroll_adecuado_comun_1_horizontal
				adc		hl,de
				call	.scroll_adecuado_comun_2_horizontal
				jp		.right

.scroll_adecuado_comun_1_vertical:

				ld		hl,(posicion_scroll_y_A)
				ld		de,(pos_scroll_y_A_objet)
				call	.comun_vertical_horizontal_1
				ld		de,1
				or		a
				ld		hl,(posicion_scroll_y_A)
				ret
				
.scroll_adecuado_comun_2_vertical:

				ld		a,h
				and		00000001b
				ld		h,a
				ld		(posicion_scroll_y_A),hl
				G9kWaitVsync
				G9kWriteReg G9K_SCROLL_LOW_Y,l
				G9kWriteReg G9K_SCROLL_HIGH_Y,h

				ret

.scroll_adecuado_comun_1_horizontal:

				ld		hl,(posicion_scroll_x_A)
				ld		de,(pos_scroll_x_A_objet)
				call	.comun_vertical_horizontal_1
				ld		de,64
				or		a
				ld		hl,(posicion_scroll_x_A)
				ret

.scroll_adecuado_comun_2_horizontal:

				ld		a,h
				and		00111111b
				ld		h,a
				ld		(posicion_scroll_x_A),hl
				G9kWriteReg G9K_SCROLL_LOW_X,l
				G9kWriteReg G9K_SCROLL_HIGH_X,h

				ld		hl,200
				call	RUTINA_RETRASO
				ret

.comun_vertical_horizontal_1:

				or		a
				sbc		hl,de
				ld		a,h
				or		l
				or		a
				jp		z,.saca_valor_pila_y_ret
				xor		a
				ret

.saca_valor_pila_y_ret:

	[2]			pop		hl
				ret

CALCULA_PANTALLA_EN_LA_QUE_ESTA:

				ld		ix,RELACION_PANTALLA_TILE
				ld		de,(PANTALLA_ACTUAL)
[2]				add 	ix,de
				ld		l,(ix)
				ld		h,(ix+1)
				ld		(TILE_SUP_IZQ_PANTALLA),hl
				ret

SITUA_EL_PUNTERO_EN_EL_MAPA_SEGUN_PANTALLA:

				ld		ix,MAPA
				ld		de,(TILE_SUP_IZQ_PANTALLA)
				add		ix,de
				ret

CALCULA_VRAM_DONDE_PINTAR:

				ld		a,(DIRECCION_DONDE_VAMOS)
				cp		1
				jp		Z,.up
				cp		3
				jp		Z,.right_left
				cp		5
				jp		Z,.down
				cp		7
				jp		Z,.right_left
				ret

.up:

				push	ix
				call	.comun_direcciones_1
				ld		de,0
				jp		.comun_direcciones_2

.right_left:

				push	ix
				call	.comun_direcciones_1
				ld		de,16
				jp		.comun_direcciones_2

.down:

				push	ix
				call	.comun_direcciones_1
				ld		de,32
				jp		.comun_direcciones_2

.comun_direcciones_1:

				ld		ix,RELACION_POSICION_VRAM_A_PINTAR
				ld		a,(POSICION_ACTUAL_SCROLL)
				add		a
				ld		e,a
				ld		d,0
				add		ix,de
				ld		l,(ix)
				ld		h,(ix+1)
				ld		(BYTE_VRAM_EMPIEZA_HL),hl
				ret

.comun_direcciones_2:				

				add		ix,de
				ld		l,(ix)
				ld		h,(ix+1)
				ld		(BYTE_VRAM_EMPIEZA_HL),hl
				ld		a,(ix+8*2*3)
				ld		(POSICION_ACTUAL_SCROLL),a
				pop		ix
				ret
				
PINTA_PATRONES_PANTALLA_A:

				ld		a,(BYTE_VRAM_EMPIEZA_E)
				ld		e,a
				ld		hl,(BYTE_VRAM_EMPIEZA_HL)
				push	de
				push	hl
				call	G9kSetVramWrite
				ld		b,4
			
.bucle:				
				ld		a,b
				ld		(var_cir_6),a
				call	PINTA_FILA_8_SUPERTYLES_Y_SE_COLOCA_EN_EL_SIGUIENTE
				ld		a,(var_cir_6)
				ld		b,a
				djnz	.bucle
				pop		de
				pop		hl
				ret

PINTA_FILA_8_SUPERTYLES_Y_SE_COLOCA_EN_EL_SIGUIENTE:

				pop		hl
				ld		(var_cir_2),hl

				ld		b,8

.bucle:

				ld		a,b
				ld		(var_cir_4),a
				call	PINTA_UN_HYPERTILE_Y_SE_COLOCA_PARA_EL_SIGUIENTE
				ld		a,(var_cir_4)
				ld		b,a
				djnz	.bucle

				pop		hl
				ld		de,32*2+64*2*3
				or		a
				adc		hl,de
				pop		de
				push	de
				push	hl
				call	G9kSetVramWrite
				ld		de,88
				add		ix,de

				ld		hl,(var_cir_2)
				push	hl

				ret

PINTA_UN_HYPERTILE_Y_SE_COLOCA_PARA_EL_SIGUIENTE:

				pop		hl
				ld		(var_cir_3),hl

				ld		a,(ix)
				call	CALCULA_HYPERTILE_EN_EL_QUE_ESTA
				call	SITUA_EL_PUNTERO_DE_SUPER_TILES
				call	PINTA_UN_TILE_DEL_HYPERTILE
				call	.BLOQUE_TRES_TYLES
				ld		b,3
.bucle:

				ld		a,b
				ld		(var_cir_5),a	
				call	AVANZA_A_LA_SIGUIENTE_LINEA_DE_PATRONES
				call	.BLOQUE_TRES_TYLES
				ld		a,(var_cir_5)
				ld		b,a
				djnz	.bucle
				
				pop		hl
				ld		de,62*2*3+4
				or		a
				sbc		hl,de
				pop		de
				push	de
				push	hl
				call	G9kSetVramWrite
				ld		de,1
				add		ix,de

				ld		hl,(var_cir_3)
				push	hl

				ret

.BLOQUE_TRES_TYLES:

				call	AVANZA_AL_SIGUIENTE_TYLE
				call	AVANZA_AL_SIGUIENTE_TYLE
				jp		AVANZA_AL_SIGUIENTE_TYLE

AVANZA_A_LA_SIGUIENTE_LINEA_DE_PATRONES:

				pop		de
				ld		(var_cir_1),de

				pop		hl
				ld		de,64*2
				or		a
				adc		hl,de
				pop		de
				push	de
				push	hl
				ld		bc,(var_cir_1)
				push	bc

				call	G9kSetVramWrite
				ld		de,29*2
				add		iy,de
				jp		PINTA_UN_TILE_DEL_HYPERTILE

AVANZA_AL_SIGUIENTE_TYLE:

				ld		de,2
				add		iy,de

PINTA_UN_TILE_DEL_HYPERTILE:

				ld		e,0
				ld		h,(iy+1)
				ld		l,(iy)
				jp		OUT_ESCRIBE_UN_BYTE

CALCULA_HYPERTILE_EN_EL_QUE_ESTA:

				ld		iy,RELACION_TILE_HYPERTILE
				ld		e,a
				ld		d,0
[2]				add 	iy,de
				ld		l,(iy)
				ld		h,(iy+1)
				ld		(TILE_SUP_IZQ_HYPERTILE),hl
				ret

SITUA_EL_PUNTERO_DE_SUPER_TILES:

				ld		iy,HYPERTYLES
				ld		de,(TILE_SUP_IZQ_HYPERTILE)
	[2]			add		iy,de
				ret

TILES_DE_B:

				ld		a,(PANTALLA_ACTUAL)
				add		a
				ld      ix,RELACION_EXTRAS_TILES_B
				ld		e,a
				ld		d,0
				add		ix,de

.REUSANDO_EL_PINTADO_DE_B:

				ld		l,(ix)
				ld		h,(ix+1)
				jp		hl
				ret

				include	"CODIGO/PINTA TILES EN B SEGUN PANTALLA.asm"

.PINTURA_GLOBAL:

				ld		a,(ix)
				ld		b,a
				
.bucle_cantidad_tiras:
				
				push	bc
				ld		de,2
				add		ix,de
				ld		a,(ix)
				ld		b,a
				
				push	bc
				ld		de,2
				add		ix,de
				ld		e,7
				ld		l,(ix)
				ld		h,(ix+1)
				call	G9kSetVramWrite
				pop		bc

.bucle_cantidad_tiles_en_tira:

				push	bc
				ld		de,2
				add		ix,de
				ld		l,(ix)
				ld		h,(ix+1)
				call	OUT_ESCRIBE_UN_BYTE
				pop		bc
				djnz	.bucle_cantidad_tiles_en_tira
				pop		bc
				djnz	.bucle_cantidad_tiras

				ret

MIRA_QUE_HAY_ALREDEDOR_DEL_PROTA:

				;	((((iy+(b?))/32)+1)*96)+((x+(c?))/32) + (y/8)*64+(x/8)

				ld		ix,POSICIONES_TYLES_ALREDEDOR
				ld		iy,TYLE_POSIC_1
				ld		b,19

.bucle:

				push	bc
				ld		b,(ix+1)
				ld		c,(ix)
				push	ix
				push	iy
				call	.calculo
				pop		iy
				pop		ix
				ld		(iy+1),d
				ld		(iy),e
				ld		de,2
				add		ix,de
				add		iy,de
				pop		bc
				djnz	.bucle
				ret

.calculo:

				call	CALCULA_PANTALLA_EN_LA_QUE_ESTA
				call	SITUA_EL_PUNTERO_EN_EL_MAPA_SEGUN_PANTALLA
				ld		iy,ATRIBUTOS_SPRITES

				ld		a,(iy)
				add		b
				ld		b,a
				and		11100000b
				ld		l,a
				ld		h,0
				push	hl
				pop		de
				or		a
[2]				adc		hl,de

				ld		a,(iy+2)
				add		c
				ld		c,a
[5]				srl		a
				ld		e,a
				ld		d,0
				or		a
				adc		hl,de

				push	hl
				pop		de
				add		ix,de
				ld		a,(ix)
				ld		(HYPERTILE_POSIC_1),a

				ld		ix,RELACION_TILE_HYPERTILE
				ld		a,(HYPERTILE_POSIC_1)
				ld		e,a
				ld		d,0
				push	de
				pop		hl
				or		a
				adc		hl,de
				push	hl
				pop		de
				add		ix,de

				ld		iy,HYPERTYLES
				ld		e,(ix)
				ld		d,(ix+1)
[2]				add		iy,de

				ld		a,b
				and		00011111b	
[3]				srl		a
				ld		e,a
				ld		d,0

				push	de
				pop		hl
				or		a
[6]				adc		hl,hl

				ld		a,c
				and		00011111b
[3]				srl		a
				ld		e,a
				ld		d,0
				or		a
[2]				adc		hl,de

				push	hl
				pop		de
				add		iy,de
				ld		e,(iy)
				ld		d,(iy+1)
				ret

COSAS_ESPECIALES_POR_PANTALLA:

				ld		ix,RELACION_DE_EVENTOS_ESPECIALES_POR_PANTALLA
				ld		a,(PANTALLA_ACTUAL)
				ld		e,a
				ld		d,0
[2]				add		ix,de
				ld		l,(ix)
				ld		h,(ix+1)
				jp		hl

INICIO_PANTALLA_00:

			ld	a,(PARAGUAS)
			or	a
			ret	nz

			jp	DA_ATRIBUTOS_OBJETO

INICIO_PANTALLA_01:
INICIO_PANTALLA_02:

			ret
INICIO_PANTALLA_03:

			; Si entra por abajo, poner el globo con x de deph

			ld  	ix,ATRIBUTOS_SPRITES
			ld		a,(ix)
			cp		#40
			ret		c

			ld		ix,ATRIBUTOS_SPRITES+64
			ld		a,(ix-62)
			call	COMUN_X_CUATRO_SPRITES
			ld		a,(ix-64)
			sub		16
			call	COMUN_Y_CUATRO_SPRITES
			ld		a,228
			call	COMUN_PATRON_CUATRO_SPRITES
			ld		a,00100000b
			call	COMUN_ATRIBUTOS_CUATRO_SPRITES


			ld		ix,ATRIBUTOS_SPRITES+80
			ld		a,(ix-78)
			call	COMUN_X_CUATRO_SPRITES
			ld		a,(ix-80)
			call	COMUN_Y_CUATRO_SPRITES
			ld		a,226
			call	COMUN_PATRON_CUATRO_SPRITES
			ld		a,00100000b
			call	COMUN_ATRIBUTOS_CUATRO_SPRITES
			ret

INICIO_PANTALLA_04:

			ld	a,(ANTI_RADIA)
			or	a
			ret	nz

			jp	DA_ATRIBUTOS_OBJETO

INICIO_PANTALLA_05:
INICIO_PANTALLA_06:
			ret
INICIO_PANTALLA_07:

			ld	a,(POLVORA_MEDIA)
			or	a
			ret	nz

			jp	DA_ATRIBUTOS_OBJETO

INICIO_PANTALLA_08:

			ld	a,(PUENTE_EXP)
			or	a
			ret	nz

			jp	DA_ATRIBUTOS_OBJETO

INICIO_PANTALLA_09:

			ld	a,(MANIFIESTO)
			or	a
			ret	nz

			jp	DA_ATRIBUTOS_OBJETO

INICIO_PANTALLA_10:

			ld	a,(BARRA_PLATA)
			or	a
			ret	nz

			jp	DA_ATRIBUTOS_OBJETO

INICIO_PANTALLA_11:

			ld	a,(MONOCICLO)
			or	a
			ret	nz

			jp	DA_ATRIBUTOS_OBJETO

INICIO_PANTALLA_12:

			ld	a,(PELOTA)
			or	a
			ret	nz

			jp	DA_ATRIBUTOS_OBJETO

INICIO_PANTALLA_13:
INICIO_PANTALLA_14:
			ret
INICIO_PANTALLA_15:

			call 	DA_ATRIBUTOS_OBJETO

			jp		DA_ATRIBUTOS_OBJETO_SECUNDARIO

INICIO_PANTALLA_16:

			xor		a
			ld		(QUIERE_CUERDA),a

			ld		hl,#c750+#80
			ld		(CUERDA_PINTANDO),hl

			ld		a,(SOPLADOR)
			or		a
			jp		nz,.MIRAMOS_SEGUNDO_OBJETO

			call 	DA_ATRIBUTOS_OBJETO

.MIRAMOS_SEGUNDO_OBJETO

			ld		a,(ESPUELA)
			or		a
			ret		nz
			jp		DA_ATRIBUTOS_OBJETO_SECUNDARIO
			
INICIO_PANTALLA_17:
INICIO_PANTALLA_18:
INICIO_PANTALLA_19:

			ret

INICIO_PANTALLA_20:

			ld	a,(ASPIRADORA)
			or	a
			ret	nz

			jp	DA_ATRIBUTOS_OBJETO

INICIO_PANTALLA_21:

			ret
INICIO_PANTALLA_22:

			ld	a,(FLAUTA)
			or	a
			ret	nz

			jp	DA_ATRIBUTOS_OBJETO

INICIO_PANTALLA_23:
INICIO_PANTALLA_24:
INICIO_PANTALLA_25:
INICIO_PANTALLA_26:
INICIO_PANTALLA_27:
			ret
INICIO_PANTALLA_28:

			ld		a,(QUIERE_CUERDA)
			cp		2
			jp		nz,.UNO

			ld		b,12
			ld		hl,#010
			ld		de,(BYTE_VRAM_EMPIEZA_HL)
			or		a
			adc		hl,de
			ld		e,7
			call	G9kSetVramWrite

.bucle_cuerda:

			push	hl
			ld		hl,574
			call	OUT_ESCRIBE_UN_BYTE
			ld		hl,575
			call	OUT_ESCRIBE_UN_BYTE
			pop		hl
			ld		de,32*2*2
			or		a
			adc		hl,de
			ld		e,7
			call	G9kSetVramWrite
			djnz	.bucle_cuerda

.UNO:

			xor	a
			ld	(SALTO_COLCHONETA),a

			ld	a,(TRAMPOLIN)
			or	a
			ret	nz

			jp	DA_ATRIBUTOS_OBJETO

INICIO_PANTALLA_29:

			xor		a
			ld		(ANIM_CAN),a

			ld		a,(CANON)
			or		a
			jp		nz,.MIRAMOS_SEGUNDO_OBJETO

			call 	DA_ATRIBUTOS_OBJETO

.MIRAMOS_SEGUNDO_OBJETO

			ld		a,(POLVORA_GRAND)
			or		a
			ret		nz
			jp		DA_ATRIBUTOS_OBJETO_SECUNDARIO
			
INICIO_PANTALLA_30:
INICIO_PANTALLA_31:
INICIO_PANTALLA_32:
			ret
INICIO_PANTALLA_33:

			ld	a,(POLVORA_PEQUE)
			or	a
			ret	nz

			jp	DA_ATRIBUTOS_OBJETO

INICIO_PANTALLA_34:

			ld	a,(FLASH)
			or	a
			ret	nz

			jp	DA_ATRIBUTOS_OBJETO

INICIO_PANTALLA_35:
INICIO_PANTALLA_36:
INICIO_PANTALLA_37:
INICIO_PANTALLA_38:
			ret
INICIO_PANTALLA_39:

			ld	a,(MANIBELA)
			or	a
			ret	nz

			jp	DA_ATRIBUTOS_OBJETO

INICIO_PANTALLA_40:

			ld	a,(FORMULA)
			or	a
			ret	nz

			jp	DA_ATRIBUTOS_OBJETO

INICIO_PANTALLA_41:
			ret
INICIO_PANTALLA_42:

			ld	a,(BARRIL)
			or	a
			ret	nz

			jp	DA_ATRIBUTOS_OBJETO

INICIO_PANTALLA_43:
			ret
INICIO_PANTALLA_44:

			ld	a,(CRISTAL_ENER)
			or	a
			ret	nz

			jp	DA_ATRIBUTOS_OBJETO

INICIO_PANTALLA_45:
INICIO_PANTALLA_46:
INICIO_PANTALLA_47:
INICIO_PANTALLA_48:
			ret
INICIO_PANTALLA_49:

			ld	a,(PERCHA)
			or	a
			ret	nz

			jp	DA_ATRIBUTOS_OBJETO

INICIO_PANTALLA_50:
			ret
INICIO_PANTALLA_51:

			ld	a,(PROPULSOR)
			or	a
			ret	nz

			jp	DA_ATRIBUTOS_OBJETO

INICIO_PANTALLA_52:

			ld	a,(BATERIA)
			or	a
			ret	nz

			jp	DA_ATRIBUTOS_OBJETO

INICIO_PANTALLA_53:
INICIO_PANTALLA_54:
INICIO_PANTALLA_55:
INICIO_PANTALLA_56:
INICIO_PANTALLA_57:
INICIO_PANTALLA_58:
INICIO_PANTALLA_59:
			ret
INICIO_PANTALLA_60:

			ld	a,(PILA_ATOMICA)
			or	a
			ret	nz

			jp	DA_ATRIBUTOS_OBJETO

INICIO_PANTALLA_61:
INICIO_PANTALLA_62:
			ret
INICIO_PANTALLA_63:

			ld	a,(CESTO)
			or	a
			ret	nz

			jp	DA_ATRIBUTOS_OBJETO

INICIO_PANTALLA_64:
INICIO_PANTALLA_65:
			ret
INICIO_PANTALLA_66:

			ld	a,(BOTON)
			or	a
			ret	nz

			jp	DA_ATRIBUTOS_OBJETO

INICIO_PANTALLA_67:
INICIO_PANTALLA_68:
			ret
INICIO_PANTALLA_69:

			ld	a,(TAZA_TE)
			or	a
			ret	nz

			jp	DA_ATRIBUTOS_OBJETO

DA_ATRIBUTOS_OBJETO_SECUNDARIO:

			ld	ix,ATRIBUTOS_SPRITES
			ld	iy,RELACION_POSICIONES_OBJETOS_2
			ld	de,80
			jp	DA_ATRIBUTOS_COMUN
			
DA_ATRIBUTOS_OBJETO:
	
			ld	ix,ATRIBUTOS_SPRITES
			ld	iy,RELACION_POSICIONES_OBJETOS
			ld	de,64

DA_ATRIBUTOS_COMUN:

			add		ix,de
			ld		de,(PANTALLA_ACTUAL)
[3]			add		iy,de

			ld		a,(iy)
			call	COMUN_Y_CUATRO_SPRITES
			ld		a,(iy+1)
			call	COMUN_PATRON_CUATRO_SPRITES
			ld		a,(iy+2)
			push	af
			call	COMUN_X_CUATRO_SPRITES
			pop		af
			ld		a,(PANTALLA_ACTUAL)
			cp		8
			jp		z,.atributos_1
			cp		12
			jp		nz,.atributos_2

.atributos_1:

			ld		a,00010000b
			ld		(ix+3),a
			ld		(ix+7),a
			ld		a,00000000b
			jp		COMUN_ATRIBUTOS_CUATRO_SPRITES.solo_dos			
.atributos_2:			
			ld		a,00000000b
			call	COMUN_ATRIBUTOS_CUATRO_SPRITES

			ret

ORGANIZA_OBJETOS:

.BUSCAMOS_EL_OBJETO_COGIDO:

			ld		ix,MONOCICLO
			ld		c,0

.bucle_busqueda_1:

			ld		a,(ix)
			cp		1
			jp		Z,.BUSCAMOS_EL_OBJETO_EN_USO

			ld		de,1
			add		ix,de
			inc		c
			jp		.bucle_busqueda_1

			ret

.BUSCAMOS_EL_OBJETO_EN_USO:

			ld		b,0
			push	bc
			ld		ix,MONOCICLO
			ld		c,0

.bucle_busqueda_2:

			ld		a,(ix)
			cp		2
			jp		Z,.BUSCAMOS_ESPACIO_LIBRE

			ld		de,1
			add		ix,de
			inc		c

			ld		a,31
			cp		c
			jp		nz,.bucle_busqueda_2

			ld		c,31

.BUSCAMOS_ESPACIO_LIBRE:

			ld		b,0
			push	bc
			ld		ix,MONOCICLO
			ld		c,3

.bucle_busqueda_3:

			ld		a,(ix)
			cp		c
			jp		z,.resetea

			ld		de,1
			add		ix,de
			inc		b

			ld		a,b
			cp		31
			jp		z,.ENCONTRADO
			jp		.bucle_busqueda_3

.resetea:

			ld		ix,MONOCICLO
			inc		c
			ld		b,0
			ld		a,c
			cp		34
			jp		z,.ENCONTRADO_POST
			jp		.bucle_busqueda_3

.ENCONTRADO_POST:

			push	hl
			push	hl
			ret

.ENCONTRADO:

			ld		a,c
			pop		de
			ld		ix,MONOCICLO
			add		ix,de
			ld		(ix),a
			ld		ix,MONOCICLO
			pop		de
			add		ix,de
			ld		a,2
			ld		(ix),a

			ret

COLOCA_OBJETOS_BOLSILLO_Y_USANDO:

			ld		e,3
			ld		hl,#fe00+4*6*16
			call	G9kSetVramWrite

			ld		ix,MONOCICLO
			ld		b,0

.bucle_busca_objeto_usando:

			ld		a,(ix)
			cp		2
			jp		nz,.bucle_sigue_usando;.pintamos_el_objeto_usando

			ld		e,b
			ld		d,0
			ld		ix,RELACION_POSICIONES_SPRITES_OBJETOS
			add		ix,de

			ld		a,(ix)
			push	af

			ld		ix,ATRIBUTOS_USANDO

			ld		a,145
			pop		bc
			ld		c,b
			ld		b,138
			call	.prepara_atributos
			jp		.bolsillos
			
.bucle_sigue_usando:

			ld		de,1
			add		ix,de
			inc		b
			ld		a,31
			cp		b
			jp		nz,.bucle_busca_objeto_usando

			ld		ix,ATRIBUTOS_USANDO
			ld		a,220
			call	.prepara_atributos

.bolsillos:

.bolsillo_A:

			ld		a,(POSICION_BOLSILLO)
			ld		c,3
			add		c
			call	.bolsillo_cont2

.bucle_objetos_de_bolsillo_a:

			ld		a,(ix)
			cp		c
			jp		nz,.bucle_sigue_a

			call	.prepara_relacion_posiciones_sprites
			ld		ix,ATRIBUTOS_BOLSI_A
			ld		a,145
			ld		b,170
			call	.prepara_atributos
			jp		.bolsillo_B

.bucle_sigue_a:

			inc		l
			ld		de,1
			add		ix,de
			djnz	.bucle_objetos_de_bolsillo_a

			ld		ix,ATRIBUTOS_BOLSI_A
			ld		a,220
			call	.prepara_atributos

.bolsillo_B:

.bolsillo_b_inicia:

			ld		c,4
			call	.bolsillo_prepara

.bucle_objetos_de_bolsillo_b:

			ld		a,(ix)
			cp		c
			jp		nz,.bucle_sigue_b

			call	.prepara_relacion_posiciones_sprites
			ld		ix,ATRIBUTOS_BOLSI_B
			ld		a,145
			ld		b,195
			call	.prepara_atributos
			jp		.bolsillo_C

.bucle_sigue_b:

			inc		l
			ld		de,1
			add		ix,de
			djnz	.bucle_objetos_de_bolsillo_b

			ld		ix,ATRIBUTOS_BOLSI_B
			ld		a,220
			call	.prepara_atributos

.bolsillo_C:

			ld		c,5
			call	.bolsillo_prepara

.bucle_objetos_de_bolsillo_c:

			ld		a,(ix)
			cp		c
			jp		nz,.bucle_sigue_c

			call	.prepara_relacion_posiciones_sprites
			ld		ix,ATRIBUTOS_BOLSI_C
			ld		a,145
			ld		b,220
			jp		.prepara_atributos

.bucle_sigue_c:

			inc		l
			ld		de,1
			add		ix,de
			djnz	.bucle_objetos_de_bolsillo_c

			ld		ix,ATRIBUTOS_BOLSI_C
			ld		a,220
			jp		.prepara_atributos

.prepara_relacion_posiciones_sprites:

			ld		e,l
			ld		d,0
			ld		ix,RELACION_POSICIONES_SPRITES_OBJETOS
			add		ix,de
			ld		c,(ix)
			ret

.bolsillo_prepara:

			ld		a,(POSICION_BOLSILLO)
			add		c

			cp		35
			jp		nz,.bolsillo_cont1
			ld		a,3
			jp		.bolsillo_cont2

.bolsillo_cont1:

			cp		36
			jp		nz,.bolsillo_cont2
			ld		a,4

.bolsillo_cont2:

			ld		c,a

			ld		ix,MONOCICLO
			ld		b,31
			ld		l,0
			ret

.prepara_atributos:

			call	COMUN_Y_CUATRO_SPRITES
			ld		a,b
			call	COMUN_X_CUATRO_SPRITES
			ld		a,c
			call	COMUN_PATRON_CUATRO_SPRITES
			xor		a
			call	COMUN_ATRIBUTOS_CUATRO_SPRITES

			ld		b,8

.bucle_pinta_dos_bytes_y_sigue:

			ld		a,7
			cp		b
			jp		z,.bucle_pinta_dos_bytes_y_sigue_0
			ld		a,5
			cp		b
			jp		nz,.bucle_pinta_dos_bytes_y_sigue_2

.bucle_pinta_dos_bytes_y_sigue_0:

			ld		a,(ix-1)
			cp		132
			jp		z,.bucle_pinta_dos_bytes_y_sigue_1
			cp		133
			jp		z,.bucle_pinta_dos_bytes_y_sigue_1
			cp		166
			jp		z,.bucle_pinta_dos_bytes_y_sigue_1
			cp		167
			jp		nz,.bucle_pinta_dos_bytes_y_sigue_2

.bucle_pinta_dos_bytes_y_sigue_1:

			ld		l,(ix)
			ld		a,00010000b
			ld		h,a
			jp		.bucle_pinta_dos_bytes_y_sigue_3

.bucle_pinta_dos_bytes_y_sigue_2:

			ld		l,(ix)
			ld		h,(ix+1)

.bucle_pinta_dos_bytes_y_sigue_3:

			call	OUT_ESCRIBE_UN_BYTE
			ld		de,2
			add		ix,de
			djnz	.bucle_pinta_dos_bytes_y_sigue
			ret		

ATRIBUTOS_VIDAS:

				include "TABLAS/TABLA VALORES INICIALES DIBUJO VIDAS.asm"
				
RELACION_POSICIONES_SPRITES_OBJETOS:

				include	"TABLAS/TABLA POSICIONES SPRITES OBJETOS.asm"

RELACION_DE_SUCESOS_POR_PANTALLA:

				include	"TABLAS/TABLA DE SUCESOS POR PANTALLA.asm"

RELACION_POSICIONES_OBJETOS:

				include "TABLAS/TABLA POSICIONES OBJETOS.asm"

RELACION_DE_EVENTOS_ESPECIALES_POR_PANTALLA:

				include	"TABLAS/TABLA INICIOS ESPECIALES POR PANTALLA.asm"

POSICIONES_TYLES_ALREDEDOR:

				include	"TABLAS/TABLA CONTROL TYLES ENTORNO.asm"

RELACION_EXTRAS_TILES_B:

				include	"TABLAS/TABLA DIRECCIONES TILES EN B.asm"
				include	"TABLAS/TABLAS TILES A PONER EN B.asm"	
				
RELACION_PARTE_VRAM_POS_SCROLL:

				include "TABLAS/TABLA POSICIONES SCROLL.asm"

RELACION_POSICION_VRAM_A_PINTAR:

				include "TABLAS/TABLA POSICION PINTA VRAM.asm"

RELACION_TILE_HYPERTILE:
				include "TABLAS/TABLA REFERENCIA HYPERTILES.asm"

RELACION_PANTALLA_TILE:
				include	"TABLAS/TABLA REFERENCIA MAPA.asm"

MAPA:
				include	"MAPAS/MAPA.asm"
				
HYPERTYLES:		
				include	"MAPAS/HYPERTILES.asm"

				ds		#C000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 003 DEL MEGAROM **********)))			
; --------------------------------------------------

; --------------------------------------------------
; (((********** PAGINA 004 DEL MEGAROM **********

				org		#8000

MARCADOR_B_1:	incbin	"GRAFICOS/MARCADOR1.DAT"

				ds		#C000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 004 DEL MEGAROM **********)))			
; --------------------------------------------------

; --------------------------------------------------
; (((********** PAGINA 005 DEL MEGAROM **********

				org		#8000

MARCADOR_B_2:	incbin	"GRAFICOS/MARCADOR2.DAT"

				ds		#C000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 005 DEL MEGAROM **********)))			
; --------------------------------------------------

; --------------------------------------------------
; (((********** PAGINA 006 DEL MEGAROM **********

				org		#8000

SPR_EXPO_1_1:	incbin	"GRAFICOS/SPRITES EXPLORADOR 11.DAT"

				ds		#C000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 006 DEL MEGAROM **********)))			
; --------------------------------------------------

; --------------------------------------------------
; (((********** PAGINA 007 DEL MEGAROM **********

				org		#8000

SPR_EXPO_1_2:	incbin	"GRAFICOS/SPRITES EXPLORADOR 12.DAT"

				ds		#C000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 007 DEL MEGAROM **********)))			
; --------------------------------------------------
; --------------------------------------------------
; (((********** PAGINA 008 DEL MEGAROM **********

				org		#8000



				ds		#C000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 008 DEL MEGAROM **********)))			
; --------------------------------------------------
; --------------------------------------------------
; (((********** PAGINA 009 DEL MEGAROM **********

				org		#8000



				ds		#C000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 009 DEL MEGAROM **********)))			
; --------------------------------------------------
; --------------------------------------------------
; (((********** PAGINA 010 DEL MEGAROM **********

				org		#8000



				ds		#C000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 010 DEL MEGAROM **********)))			
; --------------------------------------------------
; --------------------------------------------------
; (((********** PAGINA 011 DEL MEGAROM **********

				org		#8000



				ds		#C000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 011 DEL MEGAROM **********)))			
; --------------------------------------------------
; --------------------------------------------------
; (((********** PAGINA 012 DEL MEGAROM **********

				org		#8000



				ds		#C000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 012 DEL MEGAROM **********)))			
; --------------------------------------------------
; --------------------------------------------------
; (((********** PAGINA 013 DEL MEGAROM **********

				org		#8000



				ds		#C000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 013 DEL MEGAROM **********)))			
; --------------------------------------------------
; --------------------------------------------------
; (((********** PAGINA 014 DEL MEGAROM **********

				org		#8000



				ds		#C000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 014 DEL MEGAROM **********)))			
; --------------------------------------------------
; --------------------------------------------------
; (((********** PAGINA 015 DEL MEGAROM **********

				org		#8000



				ds		#C000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 015 DEL MEGAROM **********)))			
; --------------------------------------------------
; --------------------------------------------------
; (((********** PAGINA 016 DEL MEGAROM **********

				org		#8000

SPR_EXPO_ASP:	incbin	"GRAFICOS/SPRITES EXPLORADOR ASPIRADORA.DAT" 	; 32X64  (BYTES 16*64)
SPR_EXPO_UMB:	incbin	"GRAFICOS/SPRITES EXPLORADOR UMBRELLA.DAT" 		; 32X64  (BYTES 16*64)
SPR_EXPO_BAL:	incbin	"GRAFICOS/SPRITES EXPLORADOR BALLOON.DAT" 		; 32X32	 (BYTES 16*32)
SPR_EXPO_EXP:	incbin	"GRAFICOS/SPRITES EXPLORADOR EXPLOTE.DAT" 		; 128X32 (BYTES 64*32)
SPR_EXPO_FLU:	incbin	"GRAFICOS/SPRITES EXPLORADOR FLUTE.DAT" 		; 128X64 (BYTES 64*64)
SPR_EXPO_WAC:	incbin	"GRAFICOS/SPRITES EXPLORADOR WALK COMPLETE.DAT" ; 128X64 (BYTES 64*64)
SPR_EXPO_CAN:	incbin	"GRAFICOS/SPRITES EXPLORADOR CANYON.DAT" 		; 128X32 (BYTES 64*32)

				ds		#C000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 016 DEL MEGAROM **********)))			
; --------------------------------------------------
; --------------------------------------------------
; (((********** PAGINA 017 DEL MEGAROM **********

				org		#8000



				ds		#C000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 017 DEL MEGAROM **********)))			
; --------------------------------------------------
; --------------------------------------------------
; (((********** PAGINA 018 DEL MEGAROM **********

				org		#8000



				ds		#C000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 018 DEL MEGAROM **********)))			
; --------------------------------------------------
; --------------------------------------------------
; (((********** PAGINA 019 DEL MEGAROM **********

				org		#8000



				ds		#C000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 019 DEL MEGAROM **********)))			
; --------------------------------------------------
; --------------------------------------------------
; (((********** PAGINA 020 DEL MEGAROM **********

				org		#8000



				ds		#C000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 020 DEL MEGAROM **********)))			
; --------------------------------------------------
; --------------------------------------------------
; (((********** PAGINA 021 DEL MEGAROM **********

				org		#8000

ANIMACION_CANYON:

		ld		a,(POLVORA_DECIDIDA)
		or		a
		jp		nz,.ya_sabemos_lo_que_es

.miramos_polvora_peque:

		ld		a,(POLVORA_PEQUE)
		cp		2
		jp		nz,.miramos_polvora_med

		ld		a,1
		ld		(POLVORA_DECIDIDA),a
		jp		.ya_sabemos_lo_que_es

.miramos_polvora_med:

		ld		a,(POLVORA_MEDIA)
		cp		2
		jp		nz,.miramos_polvora_gra

		ld		a,2
		ld		(POLVORA_DECIDIDA),a
		jp		.ya_sabemos_lo_que_es

.miramos_polvora_gra:

		ld		a,(POLVORA_GRAND)
		cp		2
		ret		nz

		ld		a,3
		ld		(POLVORA_DECIDIDA),a

.ya_sabemos_lo_que_es:

		ld		a,(POLVORA_DECIDIDA)
		cp		1
		jp		z,.es_peque
		cp		2
		jp		z,.es_medi

.es_gran:

		ld		iy,DATAS_CANYON_HIG
		jp		.leemos_datos

.es_peque:

		ld		iy,DATAS_CANYON_LOW
		jp		.leemos_datos

.es_medi:

		ld		iy,DATAS_CANYON_MID

.leemos_datos:

		ld		a,(ANIM_CAN)
		dec		a
		cp		72
		jp		z,.se_acabo

		ld		b,a
[2]		add		b

		ld		e,a
		ld		d,0
		add		iy,de
		ld		ix,ATRIBUTOS_SPRITES
		ld		a,(iy)
		call	COMUN_Y_CUATRO_SPRITES
		ld		a,(iy+1)
		call	COMUN_PATRON_CUATRO_SPRITES
		ld		a,(iy+2)
		call	COMUN_X_CUATRO_SPRITES
		ld		a,(ANIM_CAN)
		inc		a
		ld		(ANIM_CAN),a
		ret

.se_acabo:
		
		xor		a
		ld		(ANIM_CAN),a
		ld		(QUE_SOY),a
		ld		(POSE_PROTA),a
		ld		(POLVORA_DECIDIDA),a
		ld		ix,ATRIBUTOS_SPRITES
		ld		a,(ix+2)
		cp		#de
		ret		c

		ld		a,4
		ld		(MUERTE),a

		ret

; Y,PATRON,X

DATAS_CANYON_LOW:

		db	#42,#00,#1c	
		db	#42,#00,#1c	
		db	#42,#00,#1c	
		db	#42,#00,#1c	
		db	#42,#00,#1c	
		db	#42,#00,#1c	
		db	#42,#00,#1c	
		db	#42,#00,#1c	
		db	#42,#00,#1c	
		db	#42,#00,#1c	
		db	#32,#04,#1c	
		db	#32,#04,#1c	
		db	#32,#04,#1c	
		db	#30,#02,#1e	
		db	#30,#02,#1e	
		db	#30,#02,#1e	
		db	#2e,#02,#20	
		db	#2e,#02,#20	
		db	#2e,#02,#20	
		db	#2c,#02,#24	
		db	#2c,#02,#24	
		db	#2c,#02,#24	
		db	#2a,#02,#28	
		db	#2a,#02,#28	
		db	#2a,#02,#28	
		db	#28,#02,#2c	
		db	#28,#02,#2c	
		db	#28,#02,#2c	
		db	#28,#02,#30
		db	#28,#02,#30
		db	#28,#02,#30
		db	#28,#02,#34
		db	#28,#02,#34
		db	#28,#02,#34
		db	#28,#06,#38
		db	#28,#06,#38
		db	#28,#06,#38
		db	#2a,#06,#3c
		db	#2a,#06,#3c
		db	#2a,#06,#3c
		db	#2c,#06,#40	
		db	#2c,#06,#40	
		db	#2c,#06,#40	
		db	#2e,#06,#42	
		db	#2e,#06,#42	
		db	#2e,#06,#42	
		db	#30,#06,#44	
		db	#30,#06,#44	
		db	#30,#06,#44	
		db	#32,#06,#46	
		db	#32,#06,#46	
		db	#32,#06,#46	
		db	#34,#06,#48	
		db	#34,#06,#48	
		db	#34,#06,#48	
		db	#36,#06,#49	
		db	#36,#06,#49	
		db	#36,#06,#49	
		db	#38,#06,#4a	
		db	#38,#06,#4a	
		db	#38,#06,#4a	
		db	#3a,#06,#4b	
		db	#3a,#06,#4b	
		db	#3a,#06,#4b	
		db	#3d,#06,#4c	
		db	#3d,#06,#4c	
		db	#3d,#06,#4c	
		db	#40,#06,#4d	
		db	#40,#06,#4d	
		db	#40,#06,#4d	
		db	#43,#06,#4e	
		db	#43,#06,#4e	
		db	#43,#06,#4e	

DATAS_CANYON_MID:

		db	#42,#00,#1c	
		db	#42,#00,#1c	
		db	#42,#00,#1c	
		db	#42,#00,#1c	
		db	#42,#00,#1c	
		db	#42,#00,#1c	
		db	#42,#00,#1c	
		db	#42,#00,#1c	
		db	#42,#00,#1c	
		db	#42,#00,#1c	
		db	#32,#04,#1c	
		db	#32,#04,#1c	
		db	#32,#04,#1c	
		db	#30,#02,#21	
		db	#30,#02,#21	
		db	#30,#02,#21	
		db	#2e,#02,#26	
		db	#2e,#02,#26	
		db	#2e,#02,#26	
		db	#2c,#02,#30	
		db	#2c,#02,#30	
		db	#2c,#02,#30	
		db	#2a,#02,#3a	
		db	#2a,#02,#3a	
		db	#2a,#02,#3a	
		db	#28,#02,#45	
		db	#28,#02,#45	
		db	#28,#02,#45	
		db	#28,#02,#50
		db	#28,#02,#50
		db	#28,#02,#50
		db	#28,#02,#5a
		db	#28,#02,#5a
		db	#28,#02,#5a
		db	#28,#06,#65
		db	#28,#06,#65
		db	#28,#06,#65
		db	#2a,#06,#70
		db	#2a,#06,#70
		db	#2a,#06,#70
		db	#2c,#06,#7a	
		db	#2c,#06,#7a	
		db	#2c,#06,#7a	
		db	#2e,#06,#85	
		db	#2e,#06,#85	
		db	#2e,#06,#85	
		db	#30,#06,#90	
		db	#30,#06,#90	
		db	#30,#06,#90	
		db	#32,#06,#95	
		db	#32,#06,#95	
		db	#32,#06,#95	
		db	#34,#06,#9a	
		db	#34,#06,#9a	
		db	#34,#06,#9a	
		db	#36,#06,#a0	
		db	#36,#06,#a0	
		db	#36,#06,#a0	
		db	#38,#06,#a4	
		db	#38,#06,#a4	
		db	#38,#06,#a4	
		db	#3a,#06,#a8	
		db	#3a,#06,#a8	
		db	#3a,#06,#a8	
		db	#3d,#06,#ac	
		db	#3d,#06,#ac	
		db	#3d,#06,#ac	
		db	#40,#06,#b0	
		db	#40,#06,#b0	
		db	#40,#06,#b0	
		db	#43,#06,#b4	
		db	#43,#06,#b4	
		db	#43,#06,#b4	
		
DATAS_CANYON_HIG:

		db	#42,#00,#1c	
		db	#42,#00,#1c	
		db	#42,#00,#1c	
		db	#42,#00,#1c	
		db	#42,#00,#1c	
		db	#42,#00,#1c	
		db	#42,#00,#1c	
		db	#42,#00,#1c	
		db	#42,#00,#1c	
		db	#42,#00,#1c	
		db	#32,#04,#1c	
		db	#32,#04,#1c	
		db	#32,#04,#1c	
		db	#30,#02,#21	
		db	#30,#02,#21	
		db	#30,#02,#21	
		db	#2e,#02,#26	
		db	#2e,#02,#26	
		db	#2e,#02,#26	
		db	#2c,#02,#30	
		db	#2c,#02,#30	
		db	#2c,#02,#30	
		db	#2a,#02,#3a	
		db	#2a,#02,#3a	
		db	#2a,#02,#3a	
		db	#28,#02,#45	
		db	#28,#02,#48	
		db	#28,#02,#4b	
		db	#28,#02,#4e
		db	#28,#02,#51
		db	#28,#02,#54
		db	#28,#02,#57
		db	#28,#02,#5a
		db	#28,#02,#5d
		db	#28,#06,#60
		db	#28,#06,#63
		db	#28,#06,#66
		db	#27,#06,#69
		db	#27,#06,#6c
		db	#27,#06,#6f
		db	#27,#06,#72	
		db	#27,#06,#75	
		db	#27,#06,#78	
		db	#26,#06,#7b	
		db	#26,#06,#7e	
		db	#26,#06,#81	
		db	#26,#06,#84	
		db	#26,#06,#87	
		db	#26,#06,#8a	
		db	#26,#06,#8e	
		db	#26,#06,#91	
		db	#26,#06,#94	
		db	#25,#06,#97	
		db	#25,#06,#9a	
		db	#25,#06,#9d	
		db	#25,#06,#a1	
		db	#25,#06,#a4	
		db	#25,#06,#a7	
		db	#25,#06,#aa	
		db	#25,#06,#ad	
		db	#25,#06,#b0	
		db	#25,#06,#b3	
		db	#25,#06,#b6	
		db	#25,#06,#b9	
		db	#25,#06,#c0	
		db	#25,#06,#c8	
		db	#25,#06,#d0	
		db	#25,#06,#da	
		db	#25,#06,#db
		db	#25,#06,#dc	
		db	#25,#06,#dd	
		db	#25,#06,#de	
		db	#25,#06,#df

				ds		#C000-$													;llenamos de 0 hasta el final del bloque

; ********** FIN PAGINA 021 DEL MEGAROM **********)))			
; --------------------------------------------------
