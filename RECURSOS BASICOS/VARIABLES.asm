				MAP 	#C000											; Dirección de memoria donde empezamos a escribir variables.
																		; Recordar que tiene que ser en una página de la RAM y nunca del ROM.
																		; Solemos utilizar el campo 3 que empieza en #C000.
SLOTVAR:				#1												; Controla el slot que ampliamos para uso de la RAM
PAGINA_A_LA_QUE_VOLVER:	#1												; Guarda la page en la que estaba el slot 2 para devolverlo tras la interrupcion

posicion_scroll_x_A:	#2												; Posición del scroll y en el plano A
posicion_scroll_y_A:	#2												; Posición del scroll y en el plano A
pos_scroll_x_A_objet:	#2												; Posición del scroll y en el plano A
pos_scroll_y_A_objet:	#2												; Posición del scroll y en el plano A
posicion_scroll_y_B:	#2												; Posición del scroll y en el plano B

PANTALLA_ACTUAL:		#2 
TILE_SUP_IZQ_PANTALLA:	#2
TILE_SUP_IZQ_HYPERTILE:	#2
BYTE_VRAM_EMPIEZA_E:	#2
BYTE_VRAM_EMPIEZA_HL:	#2
POSICION_ACTUAL_SCROLL:	#1
DIRECCION_DONDE_VAMOS:	#1
SPACE_PULSADO:			#1												; Guarda el valor del space
PROCESO_DE_SALTO:		#1
ATENCION_AL_SALTO:		#1
POSE_PROTA:				#1												; 0 A 3 CAMINAR
																		; ...

OBJETO_TOCANDO_1:		#1
OBJETO_TOCANDO_2:		#1

PERSONAJE:				#1
DETRAS_DE_POZO:			#1
SUMA_ALTURA_CAIDA:		#1
PANTALLA_ACTUAL_SAVE:	#1
X_SAVE:					#1
Y_SAVE:					#1
MEMORIZAMOS_POSICION:	#1
CONTADOR_DE_MUERTE:		#1
VIDAS:					#1
SALTO_COLCHONETA:		#1
QUIERE_CUERDA:			#1
CUERDA_PINTANDO:		#2
ANIM_CAN:				#1
POLVORA_DECIDIDA:		#1
MUERTE:					#1												; 0 NO MUERE
																		; 1 MUERTE CAIDA
																		; 2 MUERTE TOQUE
																		; 3 MUERTE RADIACION
																		; 4 MUERTE CAÑONO PARED
QUE_SOY:				#1												; 0 WALK
																		; 1 ASPIRADORA
																		; 2 FLAUTA
																		; 3 PARAGUAS
																		; 4 EXPLOTAO
																		; 5 VOY EN GLOBO
																		; 6 CAÑON

POSICION_BOLSILLO:		#1
PAUSA_ENTRE_BOTONES:	#1
BOLSILLO_CHANGE:		#1
LLEVANDO_CHANGE:		#1
ATRIBUTOS_SPRITES:		#96												; Y PATRON X ATRIBUTOS
																		; PROTAGONISTA*4 (0,4,8,12)
																		; ENEMIGO 1 (16,20,24,28)
																		; ENEMIGO 2 (32,36,40,44)
																		; ENEMIGO 3 (48,52,56,60)
																		; OBJETO PRESENTE 1 (64,68,72,76)
																		; OBJETO PRESENTE 2 (80.84.88.92)

ATRIBUTOS_USANDO:		#16
ATRIBUTOS_BOLSI_A:		#16
ATRIBUTOS_BOLSI_B:		#16
ATRIBUTOS_BOLSI_C:		#16

HYPERTILE_POSIC_1:		#1												; Posic. prota bajo pie izquierdo

; Objetos del juego
; 0 - en su pantalla 1 - esperando a ser colocado 2 - en uso 3 -29 - posición en el bolsillo
MONOCICLO:				#1 ;00
FLASH:					#1 ;01
PELOTA:					#1 ;02
ESPUELA:				#1 ;03
BARRIL:					#1 ;04
PARAGUAS:				#1 ;05
MANIFIESTO:				#1 ;06
SOPLADOR:				#1 ;07
CANON:					#1 ;08
ASPIRADORA:				#1 ;09
PUENTE_EXP:				#1 ;10
FLAUTA:					#1 ;11
BARRA_PLATA:			#1 ;12
PROPULSOR:				#1 ;13
FORMULA:				#1 ;14
MANIBELA:				#1 ;15
BOTON:					#1 ;16
BATERIA:				#1 ;17
PERCHA:					#1 ;18
TRAMPOLIN:				#1 ;19
PILA_ATOMICA:			#1 ;20
ANTI_RADIA:				#1 ;21
TAZA_TE:				#1 ;22
CRISTAL_ENER:			#1 ;23
GLOBO_A:				#1 ;24
GLOBO_B:				#1 ;25
POLVORA_PEQUE:			#1 ;26
POLVORA_MEDIA:			#1 ;27
POLVORA_GRAND:			#1 ;28
CRUZ_PLATA:				#1 ;29
CESTO:					#1 ;30
RESIDUO:				#1 ;31
; Valor de los tiles que tiene alrededor el prota
TYLE_POSIC_1:			#2												; bajo pies izquierda
TYLE_POSIC_2:			#2												; bajo pies derecha
TYLE_POSIC_3:			#2												; altura cabeza derecha
TYLE_POSIC_4:			#2												; altura rodilla derecha
TYLE_POSIC_5:			#2												; altura cabeza izquierda
TYLE_POSIC_6:			#2												; altura rodilla izquierda
TYLE_POSIC_7:			#2												; pisando derecha
TYLE_POSIC_8:			#2												; pisando izquierda
TYLE_POSIC_9:			#2												; bajo pies fuera izquierda
TYLE_POSIC_10:			#2												; bajo pies fuera derecha
TYLE_POSIC_11:			#2												; bajo pies izquierda a 3 pixeles para la caída del salto
TYLE_POSIC_12:			#2												; bajo pies derecha a 3 pixeles para la caída del salto 
TYLE_POSIC_13:			#2												;
TYLE_POSIC_14:			#2												; altura rodilla izquierda especial para subir escaleras
TYLE_POSIC_15:			#2												; altura rodilla derecha especial para subir escaleras
TYLE_POSIC_16:			#2												; bajo pies izquierda especial para subir escaleras
TYLE_POSIC_17:			#2												; bajo pies derecha especial para subir escaleras
TYLE_POSIC_18:			#2												; techo en cabeza izquierda
TYLE_POSIC_19:			#2												; techo en cabeza derecha

var_cir_1:				#2												; Bytes para uso efímero
var_cir_2:				#2
var_cir_3:				#2
var_cir_4:				#2
var_cir_5:				#2
var_cir_6:				#2
var_cir_7:				#2
