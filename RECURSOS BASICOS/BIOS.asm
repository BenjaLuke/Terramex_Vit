RSLREG			equ		#0138											; Lee registro del slot primario y lo devuelve a A
ENASLT			equ		#0024											; Para ampliar la ram
FINAL_MEMORIA:	equ 	#0000E00A										; Dirección final de memoria a limpiar de GFX9000
CLIKSW:			equ 	#F3DB											; Controla el sonido click de cuando pulsas una tecla (0=apagado 1=encendido)
FILVRM:			equ		#0056											; Para rellenar parte de VRAM con un valor
LDIRVM:			equ		#005C											; Graba en vram una parte de ram
CHGMOD:			equ		#005F											; Cambiar modo gráfico
DCOMPR:			equ		#0020											; Compare pero para 16 bits
GTSTCK:			equ		#00D5											;controla los cursores o direcciones del joistick
																		;En a metes		0 para controlar cursores
																		;				1 para controlar puerto 1
																		;				2 para controlar puerto 2
																		;en a sale		0 Norte
																		;				1 Noreste
																		;				...
																		;				7 Noroeste
GTTRIG:			equ		#00D8											;controla los botones del joystick o la barra espaciadora
																		;En a metes 	0 para controlar barra espaciadora
																		;				1 para controlar boton 1 puerto 1
																		;				2 para controlar boton 1 puerto 2
																		;				3 para controlar boton 2 puerto 1
																		;				4 para controlar boton 2 puerto 2
																		; El resultado es #00 si no está pulsado y #FF si sí está pulsado
H.KEYI			equ		#FD9A											;lugar al que se va cada vez que hay una interrupción de cualquier tipo
SNSMAT			equ		#0141											;controla si se ha pulsado una tecla
CHGCPU			equ		#0180
