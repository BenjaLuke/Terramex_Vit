;;;;;;;;;;;;;;;;;;;; G9K MACROS COMIENZO

		MACRO G9kReadReg register

; Lee un registro de Gfx9000
; Resultado queda en A

		LD		A,register
		OUT		(G9K_REG_SELECT),A
		IN		A,(G9K_REG_DATA)
		
		ENDM

; ---------------------------------------------

		MACRO	G9kCmdWait

; Espera a que se complete la ejecución del comando
; Modifica A

		IN		A,(G9K_STATUS)
		RRA
		JR		C,$-3
		
		ENDM

; ---------------------------------------------

		MACRO G9kWriteReg register,data

; escribe  un registro de Gfx9000
; modifica: A

		LD		A,register
		OUT		(G9K_REG_SELECT),A
		LD		A,data
		OUT		(G9K_REG_DATA),A
		
		ENDM

; ---------------------------------------------

        MACRO G9kWaitVsync

; Espera a la sincronización de Video

        IN      A,(G9K_STATUS)
        AND     A,G9K_STATUS_VR
		JR		NZ,$-4

        IN      A,(G9K_STATUS)
        AND     A,G9K_STATUS_VR
		JR		Z,$-4
        
        ENDM

; ---------------------------------------------
		
		MACRO G9kWaitComReady	

; Espera a que los datos del comando estén listos	

		IN      A,(G9K_STATUS)
		RLA
		JR		NC,$-3

		ENDM


; ---------------------------------------------

		MACRO 	ADD_HL_A												; add A to HL	
		add		a,l
		ld		l,a
		jr		nc,1f
		inc		h
1		
		ENDM	


; ---------------------------------------------

macro	GET_BIT_FROM_BITSTREAM

		add		a,a														; cambiar a nuevo bit
		jp		nz,.done												; Si el valor restante no es cero, hemos terminado
		ld		a,[hl]													; obtener 8 bits de flujo de bits
		inc		hl														; aumentar la dirección de datos de origen
		rla                    											; [¡¡¡¡El bit 0 será establecido!!!!]

.done:

endmacro

;;;;;;;;;;;;;;;;;;;; G9K MACROS FIN
