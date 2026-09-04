; ==========================================================================
; YIE AR KUNG-FU - Konami - MSX1 - cartucho RC-725 de 16 KB en la pagina 1 (version facil)
; ==========================================================================
; Generado por tools/mkasm.py a partir del trazado de flujo real.
; Los comentarios provienen de tools/../src/*.notes y estan anclados a
; direccion, de modo que sobreviven a un retrazado.
; ==========================================================================

	org 0x04000


; ----------------------------------------------------------------------
; Etiquetas que no caen en ninguna posicion emitida del listado
; (destinos fuera del binario o dentro de una instruccion).
; ----------------------------------------------------------------------
dentro_del_jp_de_arriba:	equ 0x0462f

; ----------------------------------------------------------------------
; DATOS cabecera_del_cartucho: AB y la direccion de INIT; el resto a cero.
;   Aqui INIT esta pegado a la cabecera, en 0x4010
;   0x4000..0x4010  (16 bytes)
DATA_cabecera_del_cartucho:
	defw 04241h,04010h,00000h,00000h,00000h,00000h,00000h,00000h	; 4000

; ======================================================================
; CODIGO 0x4010..0x409f  (143 bytes)
; ======================================================================


arranca_el_cartucho:		; INIT, el que declara la cabecera. Engancha la interrupcion a mano -un 0xC3 en H.KEYI y la direccion 0x4043 detras-, deja la pila en 0xE400, borra 0xE000-0xE3FF con un ldir, enciende la luz de CAPS mientras carga los graficos y se queda dando vueltas: a partir de ahi todo el juego corre dentro de la interrupcion
	di			;4010   ; sin interrupciones mientras se monta
	im 1		;4011   ; modo 1, el de la BIOS
	ld a,0c3h		;4013   ; un 0xC3 -o sea un `jp`- en H.KEYI...
	ld (0fd9ah),a		;4015
	ld hl,interrupcion		;4018   ; ...y la direccion del manejador detras
	ld (0fd9bh),hl		;401b
	ld sp,0e400h		;401e   ; la pila, justo encima de la RAM de trabajo
	ld hl,0e000h		;4021   ; HL = 0xE000, DE = 0xE001 y un cero: el ldir lo arrastra
	ld de,0e001h		;4024
	ld bc,003ffh		;4027
	ld (hl),000h		;402a
	ldir		;402c
	ld a,001h		;402e
	ld (0e006h),a		;4030   ; (0xE006) := 1: el candado que impide reentrar
	call 00132h		;4033   ; BIOS CHGCAP - Alternates the CAPS lamp status | la luz de CAPS encendida mientras carga
	call carga_los_graficos		;4036   ; carga todos los graficos en VRAM
	xor a			;4039
	ld (0e006h),a		;403a   ; el candado, abierto
	call 0013eh		;403d   ; BIOS RDVDP - Reads VDP status register | lee el estado del VDP para reconocer la interrupcion
	ei			;4040
y_a_esperar:		; Todo lo demas pasa dentro de la interrupcion; aqui solo se da vueltas
	jr y_a_esperar		;4041   ; un salto a si mismo, para siempre
interrupcion:		; El manejador que INIT engancha en H.KEYI. Lee el estado del VDP para reconocer la interrupcion, le da un cuadro al sonido, y con el candado de 0xE006 abierto lee los mandos y hace el cuadro de juego. Al salir vuelve a mirar el estado: si hay otra interrupcion pendiente, le da otro cuadro al sonido
	call 0013eh		;4043   ; BIOS RDVDP - Reads VDP status register | reconoce la interrupcion y la borra
	di			;4046
	call un_cuadro_de_sonido		;4047   ; un cuadro del motor de sonido
	ld hl,0e006h		;404a   ; HL = 0xE006, el candado
	bit 0,(hl)		;404d   ; con el bit 0 puesto, ya hay una interrupcion dentro
	jr nz,interrupcion_si_no		;404f
	inc (hl)			;4051   ; y se cierra
	ei			;4052
	call lee_los_mandos_de_la_partida		;4053   ; lee los dos mandos
	call un_cuadro_de_juego		;4056   ; el cuadro de juego
	xor a			;4059
	ld (0e006h),a		;405a   ; y el candado, abierto otra vez
interrupcion_si_no:		; Dentro de interrupcion
	call 0013eh		;405d   ; BIOS RDVDP - Reads VDP status register | el estado del VDP otra vez
	or a			;4060
	di			;4061
	call m,un_cuadro_de_sonido		;4062   ; con el bit 7, otro cuadro de sonido
	ei			;4065
	ret			;4066
suma_a_hl:		; HL += A, con el acarreo propagado a H. El sumador de 8 bits de todas las tablas indexadas del cartucho
	add a,l			;4067   ; A += L
	ld l,a			;4068
	ret nc			;4069   ; sin desbordar, ya esta
	inc h			;406a
	ret			;406b
suma_a_de:		; Lo mismo con DE
	add a,e			;406c   ; A += E
	ld e,a			;406d
	ret nc			;406e   ; sin desbordar, ya esta
	inc d			;406f
	ret			;4070
despacha_por_la_tabla_de_al_lado:		; EL DESPACHADOR DEL CARTUCHO. La tabla va escrita DETRAS del propio `call`: `pop hl` la coge de la pila, A por dos entra en ella, y el puntero que salga se ejecuta con `jp (hl)`. Como el retorno se ha sacado de la pila, esto no vuelve: se va al destino y ya. Hay NUEVE sitios que despachan asi, y sin declarar sus tablas el trazado se queda en el 7,5 %
	pop hl			;4071   ; HL = la direccion de retorno, o sea la tabla
despacha_con_la_tabla_en_hl:		; La otra entrada, con la tabla ya puesta en HL
	add a,a			;4072   ; A por dos: son punteros de 16 bits
	call suma_a_hl		;4073   ; HL += A
	ld e,(hl)			;4076   ; E = el byte bajo del destino
	inc hl			;4077
	ld d,(hl)			;4078   ; D = el alto
	ex de,hl			;4079
	jp (hl)			;407a   ; y alla va
un_cuadro_de_juego:		; Sube el contador de 0xE003, se queda con sus tres bits bajos en 0xE005, y despacha la escena de 0xE000 por la tabla de 0x409f. El bit 6 de 0xE002 -que es el mando- elige a que rutina se vuelve al acabar: 0x411e con algo pulsado y 0x4583 sin nada
	ld hl,0e003h		;407b   ; HL = 0xE003, el contador de cuadros
	inc (hl)			;407e   ; un cuadro mas
	ld a,(hl)			;407f
	and 007h		;4080   ; sus tres bits bajos...
	inc hl			;4082
	inc hl			;4083
	ld (hl),a			;4084   ; ...a 0xE005
	ld a,(0e002h)		;4085   ; (0xE002), la lectura del mando
	and 040h		;4088   ; su bit 6
	ld hl,0411eh		;408a   ; HL = 0x411e, el retorno normal
	jr nz,un_cuadro_de_juego_si_no		;408d
	ld hl,04583h		;408f   ; o 0x4583 si el bit esta puesto
un_cuadro_de_juego_si_no:		; Dentro de un_cuadro_de_juego
	ld bc,(0e000h)		;4092   ; BC = (0xE000): C la escena y B el paso
	ld a,c			;4096
	cp 003h		;4097   ; la escena 3 no lleva retorno...
	jr z,un_cuadro_de_juego_si_no_2		;4099
	push hl			;409b   ; ...y las demas si
un_cuadro_de_juego_si_no_2:		; Dentro de un_cuadro_de_juego
	call despacha_por_la_tabla_de_al_lado		;409c

; ----------------------------------------------------------------------
; DATOS tabla_de_escenas: Los nueve punteros de la tabla que despacha 0x409c,
;   uno por escena de 0xE000: 0x40b1, 0x40f4, 0x40fc, 0x411f, 0x414d, 0x41be,
;   0x41d7, 0x4213 y 0x423e. La escribe el propio `call` de al lado, que es
;   como este cartucho hace todos sus despachos
;   0x409f..0x40b1  (18 bytes)
DATA_tabla_de_escenas:
	defw 040b1h,040f4h,040fch,0411fh,0414dh,041beh,041d7h,04213h	; 409f
	defw 0423eh	; 40af  -> escena_8_ha_ganado

; ======================================================================
; CODIGO 0x40b1..0x42c1  (528 bytes)
; ======================================================================


escena_0:		; La escena de arranque, la del VIDEO CARTRIDGE. El paso 1 espera a que 0x45c7 diga que si y dibuja la lista de 0x55c8; el 2 espera a que se agote el plazo, la BORRA -la misma lista con la mascara cerrada- y monta el fondo; el 3 dibuja los rotulos del titulo y pasa a la escena siguiente; y el ultimo cambia la musica y monta la pantalla entera
	djnz escena_0_paso_2		;40b1   ; el paso 1 sigue aqui
	ld a,(0e003h)		;40b3   ; (0xE003), el contador de cuadros
	rra			;40b6   ; su bit 0: uno de cada dos
	ret nc			;40b7
	call sube_un_paso		;40b8
	ret nz			;40bb
	ld de,055c8h		;40bc   ; DE = 0x55c8, la lista del VIDEO CARTRIDGE
	call dibuja_la_lista		;40bf
	xor a			;40c2   ; A = 0, el plazo
	jr pon_el_plazo		;40c3
escena_0_paso_2:		; Espera a que se agote el plazo de 0xE004 y entonces redibuja
	djnz escena_0_paso_3		;40c5   ; el paso 2 sigue aqui
	ld hl,0e004h		;40c7   ; HL = 0xE004, el plazo
	dec (hl)			;40ca   ; un cuadro menos
	ret nz			;40cb
	ld de,055c8h		;40cc   ; DE = 0x55c8 otra vez, y ahora a borrarla
	call borra_la_lista		;40cf
	call borra_y_dibuja_el_fondo		;40d2
	jr pasa_al_paso_siguiente		;40d5
escena_0_paso_3:		; Dibuja los rotulos del titulo y pasa a la escena siguiente. El `ret c` de 0x40dc no se cumple nunca: 0x4402 acaba en `xor a`, que borra el acarreo
	djnz escena_0_monta_la_pantalla		;40d7   ; el paso 3 sigue aqui
	call dibuja_los_rotulos_del_titulo		;40d9   ; el logotipo y el PUSH SPACE KEY
	ret c			;40dc
	xor a			;40dd
	jp pasa_a_la_escena_siguiente		;40de
escena_0_monta_la_pantalla:		; Cambia la musica, borra la VRAM, recarga los registros del VDP y dibuja la pantalla de titulo entera
	ld a,092h		;40e1   ; A = 0x92, la melodia
	call pon_la_melodia		;40e3
	call borra_la_pantalla		;40e6   ; borra la pantalla
	call carga_los_registros_del_vdp		;40e9   ; recarga los ocho registros del VDP
	call pinta_el_color_de_los_dieciseis		;40ec   ; dibuja la pantalla
	call arranca_la_subida		;40ef   ; y lo que va encima
	jr pasa_al_paso_siguiente		;40f2
escena_1:		; Un plazo y a la escena siguiente
	ld hl,0e004h		;40f4   ; HL = 0xE004, el plazo
	dec (hl)			;40f7   ; un cuadro menos
	ret nz			;40f8
	jp plazo_de_24		;40f9
escena_2:		; El paso 1 mira si hay partida en marcha en 0xE106; el 2 lleva la cuenta atras
	djnz escena_2_paso_2		;40fc   ; el paso 1 sigue aqui
	call un_cuadro_de_combate		;40fe
	ld a,(0e106h)		;4101   ; (0xE106): sin partida no hay nada que hacer
	and a			;4104
	ret z			;4105
arranca_la_partida:		; A cero y a 0x41e4
	xor a			;4106
	jp salta_a_la_escena		;4107
escena_2_paso_2:		; La cuenta atras, con su plazo de 0x18 cuadros
	call corre_la_cuenta_atras		;410a
	ret p			;410d   ; con el resultado positivo, no se sigue
	call monta_la_partida		;410e
	ld a,018h		;4111   ; A = 0x18, el plazo
pon_el_plazo:		; Deja A en 0xE004 y sube el paso
	ld (0e004h),a		;4113   ; (0xE004), el plazo
pasa_al_paso_siguiente:		; Sube 0xE001 y borra 0xE110
	ld hl,0e001h		;4116   ; HL = 0xE001, el paso
	inc (hl)			;4119   ; uno mas
	xor a			;411a
	ld (0e110h),a		;411b   ; (0xE110) := 0
	ret			;411e
escena_3:		; El paso 1 alterna dibujar y borrar la lista de 0x558a -el PLAY START- segun el bit 2 del plazo, que es lo que le hace parpadear
	djnz escena_3_arranca_la_musica		;411f   ; el paso 1 sigue aqui
	ld hl,0e004h		;4121   ; HL = 0xE004, el plazo
	dec (hl)			;4124   ; un cuadro menos
	jr z,escena_3_se_acabo_el_plazo		;4125
	bit 2,(hl)		;4127   ; su bit 2, que cambia cada cuatro cuadros
	ld de,0558ah		;4129   ; DE = 0x558a, la lista del PLAY START
	jp nz,borra_la_lista		;412c
	jp dibuja_la_lista		;412f
escena_3_se_acabo_el_plazo:		; Cierra y salta a 0x4194
	call borra_la_ram_del_combate		;4132
	jp plazo_de_24		;4135
escena_3_arranca_la_musica:		; Pone la melodia 0x88 y se da 0x50 cuadros
	ld a,088h		;4138   ; A = 0x88, la melodia
	call pon_la_melodia		;413a
	ld a,050h		;413d   ; (0xE004) := 0x50, el plazo
	ld (0e004h),a		;413f
	jr remata_la_escena		;4142
borra_y_sigue:		; Borra la pantalla antes de seguir
	call borra_la_pantalla		;4144
remata_la_escena:		; Dibuja lo que toque y pasa al paso siguiente
	call monta_la_pantalla_de_titulo		;4147
	jp pasa_al_paso_siguiente		;414a
escena_4:		; El montaje del combate. El paso 1 monta al enemigo -por 0x6c60 si acaba de ganar, por 0x6c49 si no-, dibuja el escenario y coloca a los dos
	djnz escena_4_paso_2		;414d   ; el paso 1 sigue aqui
	ld a,(0e058h)		;414f   ; (0xE058): puesto quiere decir que acaba de ganar
	and a			;4152
	jr z,escena_4_si_no		;4153
	call escribe_bonus_stage		;4155   ; monta el enemigo siguiente
	jr escena_4_si_no_2		;4158
escena_4_si_no:		; Dentro de escena_4
	call escribe_stage_y_el_numero		;415a   ; o el mismo otra vez
escena_4_si_no_2:		; Dentro de escena_4
	call dibuja_el_marcador		;415d   ; dibuja el escenario
	call monta_la_pantalla_de_combate		;4160   ; y coloca a los dos luchadores
	jp pasa_al_paso_siguiente		;4163
escena_4_paso_2:		; No sigue hasta que el puntero de 0xE01B llegue a 0x7e5d, que es el final del guion; entonces borra la fila de 0x38e0 y monta el combate
	djnz escena_4_paso_3		;4166
	ld hl,(0e01bh)		;4168   ; (0xE01B), por donde va el guion
	ld de,07e5dh		;416b   ; contra 0x7e5d, el final
	xor a			;416e
	sbc hl,de		;416f
	ret nz			;4171
	ld hl,038e0h		;4172   ; VRAM 0x38e0, una fila entera
	ld bc,00020h		;4175   ; 32 columnas
	xor a			;4178
	call 00056h		;4179   ; BIOS FILVRM - Fills VRAM with value | borrada
	call escribe_el_cuarto_sprite_por_aqui		;417c   ; prepara el combate
	call dibuja_el_templo		;417f   ; monta las fichas
	call escribe_el_nombre_del_oponente		;4182   ; y arranca
	jp pasa_al_paso_siguiente		;4185
escena_4_paso_3:		; Un paso vacio, solo para dejar pasar un cuadro
	djnz escena_4_paso_4		;4188
	jp pasa_al_paso_siguiente		;418a
escena_4_paso_4:		; Enciende la marca de 0xE053: el combate esta en marcha
	djnz escena_4_el_combate		;418d
	ld hl,0e053h		;418f   ; (0xE053) := 1
	ld (hl),001h		;4192
plazo_de_24:		; El plazo corriente entre escenas
	ld a,018h		;4194   ; A = 0x18, veinticuatro cuadros
pasa_a_la_escena_siguiente:		; Deja el plazo, sube 0xE000 y empieza por el paso cero
	ld (0e004h),a		;4196   ; (0xE004), el plazo
	ld hl,0e000h		;4199   ; HL = 0xE000, la escena
	inc (hl)			;419c   ; una escena mas
empieza_por_el_paso_cero:		; El paso y 0xE110 a cero
	xor a			;419d
	ld (0e001h),a		;419e   ; (0xE001) := 0, el paso
	ld (0e110h),a		;41a1   ; (0xE110) := 0
	ret			;41a4
escena_4_el_combate:		; El cuadro de combate: si 0xE01A esta a cero arranca la musica, y luego corre la cuenta atras de 0xE050 y el cuerpo de 0x5635
	ld a,(0e01ah)		;41a5   ; (0xE01A), la marca de la musica
	and a			;41a8
	jr nz,escena_4_el_combate_si_no		;41a9
	ld a,088h		;41ab   ; A = 0x88, la melodia del combate
	call pon_la_melodia		;41ad
escena_4_el_combate_si_no:		; Dentro de escena_4_el_combate
	call corre_la_cuenta_atras		;41b0   ; la cuenta atras
	ret p			;41b3   ; con el resultado positivo, no se sigue
	ld hl,0e050h		;41b4   ; HL = 0xE050, las vidas
	dec (hl)			;41b7   ; una menos: se acabo el tiempo
	call monta_el_fondo_de_pantalla		;41b8   ; el cuerpo del combate
	jp pon_el_plazo		;41bb
escena_5:		; El final del combate: con 0xE00B puesto se va a la escena 8, y si no se espera a que 0xE053 se apague
	call un_cuadro_de_combate		;41be   ; lee los mandos
	ld a,(0e00bh)		;41c1   ; (0xE00B), la marca del que ha ganado
	or a			;41c4
	jr z,escena_5_si_no		;41c5
	ld a,092h		;41c7   ; A = 0x92, la melodia
	call pon_la_melodia		;41c9
	ld a,008h		;41cc   ; A = 8, la escena de haber ganado
	jr salta_a_la_escena		;41ce
escena_5_si_no:		; Dentro de escena_5
	ld a,(0e053h)		;41d0   ; (0xE053), la marca de combate en marcha
	or a			;41d3
	ret nz			;41d4
	jr plazo_de_24		;41d5
escena_6:		; Se acabo una vida: musica, y si quedan vidas se vuelve al combate
	ld a,092h		;41d7   ; A = 0x92, la melodia
	call pon_la_melodia		;41d9
	ld a,(0e050h)		;41dc   ; (0xE050), las vidas que quedan
	or a			;41df
	jr z,se_acabo_la_partida		;41e0
vuelve_a_la_escena_4:		; Otra vez al combate
	ld a,004h		;41e2   ; A = 4, la escena de combate
salta_a_la_escena:		; Deja la escena en 0xE000, el plazo en 0x18 y enciende 0xE053
	ld (0e000h),a		;41e4   ; (0xE000), la escena
	ld a,018h		;41e7
	ld (0e004h),a		;41e9   ; (0xE004) := 0x18, el plazo
	ld a,001h		;41ec
	ld (0e053h),a		;41ee   ; (0xE053) := 1
	jr empieza_por_el_paso_cero		;41f1
se_acabo_la_partida:		; Dibuja el guion de 0x55bb -el cartel del final-, cambia la musica y se va a la escena 6 con cinco pasos
	call corre_la_cuenta_atras		;41f3   ; la cuenta atras
	ret p			;41f6
	call monta_el_fondo_de_pantalla		;41f7   ; cierra el combate
	ld de,055bbh		;41fa   ; DE = 0x55bb, el cartel del final
	call dibuja_la_lista		;41fd
	ld a,08fh		;4200   ; A = 0x8f, la melodia del final
	call pon_la_melodia		;4202
	xor a			;4205
	ld (0e016h),a		;4206   ; (0xE016) := 0
	ld a,006h		;4209
	ld (0e000h),a		;420b   ; (0xE000) := 6
	ld a,005h		;420e   ; A = 5, el paso
	jp pasa_a_la_escena_siguiente		;4210
escena_7:		; Lee el mando desde 0xE080 y, si la escena ya no es la 7, baja el bit 6 de 0xE002 y vuelve a la melodia normal
	ld a,(0e080h)		;4213   ; (0xE080), la entrada
	call mira_si_arranca_la_partida		;4216
	ld de,0e002h		;4219   ; DE = 0xE002, la lectura del mando
	ld a,(0e000h)		;421c   ; (0xE000), la escena
	cp 007h		;421f
	jr z,escena_7_espera		;4221
	ld a,(de)			;4223
	and 0bfh		;4224   ; el bit 6, fuera
	ld (de),a			;4226
	pop de			;4227   ; el retorno que puso 0x407b, tirado
	ld a,092h		;4228   ; A = 0x92, la melodia
	jp pon_la_melodia		;422a
escena_7_espera:		; Espera a que la musica calle y a que el plazo se agote
	ld a,(0e01ah)		;422d   ; (0xE01A), la marca de la musica
	and a			;4230
	ret nz			;4231
	ld hl,0e004h		;4232   ; HL = 0xE004, el plazo
	dec (hl)			;4235   ; un cuadro menos
	ret nz			;4236
	ld a,(de)			;4237
	and 0bfh		;4238   ; el bit 6 de 0xE002, fuera
	ld (de),a			;423a
	jp arranca_la_partida		;423b
escena_8_ha_ganado:		; Da una vida, apunta el enemigo vencido y, pasado el quinto, sube el escalon de dificultad y da otra vuelta
	ld hl,0e050h		;423e   ; HL = 0xE050, las vidas
	inc (hl)			;4241   ; una mas
	ld a,(0e058h)		;4242   ; (0xE058): si ya estaba puesta...
	and a			;4245
	jr nz,sube_el_tope		;4246
	ld a,(0e054h)		;4248   ; (0xE054), el enemigo que toca
	cp 001h		;424b   ; el primero...
	jr z,premio		;424d
	cp 004h		;424f   ; ...o el cuarto llevan premio
	jr nz,apunta_el_enemigo		;4251
premio:		; Enciende 0xE058 y cambia la musica
	ld a,001h		;4253   ; (0xE058) := 1
	ld (0e058h),a		;4255
	ld a,088h		;4258   ; A = 0x88, la melodia
	call pon_la_melodia		;425a
	jr y_vuelve_al_combate		;425d
sube_el_tope:		; Sube 0xE057, con tope en cuatro
	ld a,(0e057h)		;425f   ; (0xE057)
	inc a			;4262   ; una mas
	cp 004h		;4263   ; el tope son cuatro
	jr c,sube_el_tope_si_no		;4265
	ld a,004h		;4267
sube_el_tope_si_no:		; Dentro de sube_el_tope
	ld (0e057h),a		;4269   ; guardadas
apunta_el_enemigo:		; Apaga 0xE058, suma uno en BCD a la vuelta de 0xE051 y pasa al enemigo siguiente; al quinto, sube el escalon de dificultad -con tope tres- y da una vuelta mas
	xor a			;426c
	ld (0e058h),a		;426d   ; (0xE058) := 0
	ld a,088h		;4270   ; A = 0x88, la melodia
	call pon_la_melodia		;4272
	inc hl			;4275
	ld a,(hl)			;4276
	add a,001h		;4277   ; (0xE051) sube uno...
	daa			;4279   ; ...en BCD, que es como se lleva la vuelta
	ld (hl),a			;427a
	ld hl,0e054h		;427b   ; HL = 0xE054, el enemigo
	ld a,(hl)			;427e
	inc a			;427f   ; el siguiente
	cp 005h		;4280   ; pasado el quinto, se da la vuelta
	jr c,guarda_el_enemigo		;4282
	ld a,(0e056h)		;4284   ; (0xE056), el escalon de dificultad
	inc a			;4287
	cp 004h		;4288   ; con tope en tres
	jr c,guarda_el_escalon		;428a
	ld a,003h		;428c
guarda_el_escalon:		; El escalon nuevo
	ld (0e056h),a		;428e
	ld a,(0e059h)		;4291   ; (0xE059), la vuelta
	inc a			;4294
	and 003h		;4295   ; de cuatro en cuatro
	ld (0e059h),a		;4297
	xor a			;429a
guarda_el_enemigo:		; El enemigo que toca ahora
	ld (hl),a			;429b
y_vuelve_al_combate:		; Borra 0xE00B y se va a la escena 4
	xor a			;429c
	ld (0e00bh),a		;429d   ; (0xE00B) := 0
	jp vuelve_a_la_escena_4		;42a0
borra_la_ram_del_combate:		; Pone a cero los 235 bytes de 0xE049, que es todo el estado del combate, propagando un cero con ldir
	ld hl,0e049h		;42a3   ; HL = 0xE049
	ld bc,000ebh		;42a6   ; 235 bytes
	ld d,h			;42a9   ; DE = HL+1: el destino va un byte por delante
	ld e,l			;42aa
	inc e			;42ab
	ld (hl),000h		;42ac
	ldir		;42ae
	ld hl,042c1h		;42b0
	ld de,0e050h		;42b3
	ld bc,00004h		;42b6
	ldir		;42b9
	ld a,003h		;42bb
	ld (0e011h),a		;42bd
	ret			;42c0

; ----------------------------------------------------------------------
; DATOS estado_inicial: Los cuatro bytes con los que arranca una partida, que
;   0x42b0 copia a 0xE050: TRES vidas, la vuelta en 1, el proximo premio de
;   vida extra en 2 y 0xE053 en 2
;   0x42c1..0x42c5  (4 bytes)
DATA_estado_inicial:
	defb 003h,001h,002h,002h	; 42c1

; ======================================================================
; CODIGO 0x42c5..0x448a  (453 bytes)
; ======================================================================


monta_la_partida:		; Deja el combate listo: borra 0xE013 y 0xE00C, saca de 0xE016 el enemigo que toca, le da la vuelta a esa marca, y monta escenario, luchadores y fichas
	xor a			;42c5
	ld (0e013h),a		;42c6   ; (0xE013) := 0
	ld (0e00ch),a		;42c9   ; (0xE00C) := 0
	ld hl,0e016h		;42cc   ; HL = 0xE016
	ld a,(hl)			;42cf
	ld (0e054h),a		;42d0   ; (0xE054), el enemigo que toca
	and a			;42d3
	ld a,001h		;42d4   ; A = 1 si estaba a cero...
	jr z,monta_la_partida_si_no		;42d6
	xor a			;42d8   ; ...y 0 si no: la marca se da la vuelta
monta_la_partida_si_no:		; Dentro de monta_la_partida
	ld (hl),a			;42d9
	call monta_la_pantalla_de_combate		;42da   ; coloca a los dos luchadores
	call escribe_el_cuarto_sprite_por_aqui		;42dd   ; prepara el combate
	call dibuja_el_marcador		;42e0   ; dibuja el marcador
	call dibuja_el_templo		;42e3   ; y el escenario
	jp escribe_el_nombre_del_oponente		;42e6
corre_la_cuenta_atras:		; Baja el reloj del combate. 0xE003 es el contador de cuadros y 0xE004 los segundos; cuando 0xE004 se pasa de cero devuelve el signo puesto, que es como los que llaman se enteran de que se acabo el tiempo. Cada segundo borra una fila mas de la barra del reloj y la va vaciando de arriba abajo
	ld hl,0e003h		;42e9   ; HL = 0xE003, los cuadros
	dec (hl)			;42ec   ; uno menos
	inc hl			;42ed
	dec (hl)			;42ee   ; y un segundo menos
	ret m			;42ef   ; pasado de cero, se acabo el tiempo
	ld a,017h		;42f0   ; 0x17 menos lo que queda: cuanto se ha gastado
	sub (hl)			;42f2
	ld hl,001c0h		;42f3   ; HL = 0x01c0, la esquina de la barra
	add a,002h		;42f6   ; dos mas
	add a,l			;42f8
	ld l,a			;42f9
	add hl,hl			;42fa   ; por 32: cinco veces doblado
	add hl,hl			;42fb
	add hl,hl			;42fc
	add hl,hl			;42fd
	add hl,hl			;42fe
	ld bc,00020h		;42ff   ; 32 columnas
	xor a			;4302
	call 00056h		;4303   ; BIOS FILVRM - Fills VRAM with value | borradas
devuelve_el_reloj_al_tope:		; Repone los 32 tramos de la barra al valor 0xE0
	ld b,020h		;4306   ; 32 tramos
	ld hl,0e0b0h		;4308   ; HL = 0xE0B0, la barra
un_tramo_del_reloj:		; El tope, y cuatro bytes hasta el siguiente
	ld (hl),0e0h		;430b   ; el tope
	ld a,004h		;430d
	call suma_a_hl		;430f   ; cuatro bytes por tramo
	djnz un_tramo_del_reloj		;4312
	call vuelca_los_sprites		;4314   ; y se redibuja
	xor a			;4317
	ret			;4318
suma_a_la_puntuacion:		; Suma DE a la puntuacion de tres bytes de 0xE049, en BCD. Si con eso pasa del tercer byte, la puntuacion y el record se clavan en 999999; y si pasa del umbral de 0xE052, se regala una vida y el umbral sube dos, hasta que pasa de 6 y ya no se regalan mas
	ld a,(0e002h)		;4319   ; (0xE002), la lectura del mando
	add a,a			;431c   ; su bit 7...
	ret p			;431d   ; ...puesto quiere decir que no se suma
	ld hl,0e049h		;431e   ; HL = 0xE049, la puntuacion
	ld a,(hl)			;4321
	add a,e			;4322   ; mas el byte bajo...
	daa			;4323   ; ...en BCD
	ld (hl),a			;4324
	ld e,a			;4325
	inc l			;4326
	ld a,(hl)			;4327
	adc a,d			;4328   ; y el de en medio, con el acarreo
	daa			;4329
	ld (hl),a			;432a
	ld d,a			;432b
	inc hl			;432c
	jr nc,mira_si_hay_record		;432d
	ld a,(hl)			;432f
	add a,001h		;4330   ; y el alto
	daa			;4332
	ld (hl),a			;4333
	jr nc,mira_si_toca_vida_extra		;4334
	ld bc,09999h		;4336   ; pasado el tope, todo a 999999
	ld (0e043h),bc		;4339   ; la puntuacion
	ld (0e044h),bc		;433d   ; y el record
	jr escribe_el_record		;4341
mira_si_toca_vida_extra:		; El umbral de 0xE052 sube de dos en dos en BCD; pasado el 6 ya no se regalan mas vidas
	ld a,(0e052h)		;4343   ; (0xE052), el umbral
	cp 006h		;4346   ; pasado el 6, ya no hay mas premios
	jr nc,mira_si_hay_record		;4348
	cp (hl)			;434a   ; y la puntuacion tiene que haberlo alcanzado
	jr nc,mira_si_hay_record		;434b
	push de			;434d
	push hl			;434e
	add a,002h		;434f   ; dos mas...
	daa			;4351   ; ...en BCD
	jr nc,mira_si_toca_vida_extra_si_no		;4352
	ld a,0ffh		;4354   ; y con tope en 0xFF
mira_si_toca_vida_extra_si_no:		; Dentro de mira_si_toca_vida_extra
	ld (0e052h),a		;4356   ; el umbral nuevo
	ld hl,0e050h		;4359   ; HL = 0xE050, las vidas
	inc (hl)			;435c   ; una mas
	call escribe_las_vidas		;435d   ; repintadas
	ld a,005h		;4360   ; A = 5, el sonido del premio
	call pon_la_melodia		;4362
	pop hl			;4365
	pop de			;4366
mira_si_hay_record:		; Compara la puntuacion con el record de 0xE043/0xE045 y, si lo pasa, lo sustituye
	ld a,(0e045h)		;4367   ; (0xE045), el byte alto del record
	ld b,(hl)			;436a   ; contra el de la puntuacion
	sub b			;436b
	jr c,mira_si_hay_record_si_no		;436c
	jr nz,escribe_la_puntuacion		;436e
	ld hl,(0e043h)		;4370   ; (0xE043), los dos bajos del record
	sbc hl,de		;4373   ; contra los de la puntuacion
	jr nc,escribe_la_puntuacion		;4375
mira_si_hay_record_si_no:		; Dentro de mira_si_hay_record
	ld (0e043h),de		;4377   ; el record nuevo
	ld a,b			;437b
	ld (0e045h),a		;437c   ; y su byte alto
	jr escribe_el_record		;437f
dibuja_el_marcador:		; Pinta los cuatro rotulos fijos del marcador -HI SCORE, STAGE, SCORE y REST-, las vidas, la vuelta y las dos cifras del record
	ld de,05566h		;4381   ; DE = 0x5566, la lista de los rotulos
	call dibuja_la_lista		;4384
	call escribe_las_vidas		;4387   ; las vidas
	call escribe_la_vuelta		;438a   ; la vuelta
escribe_el_record:		; Los tres bytes del record, en la fila 0x382c
	ld de,0e045h		;438d   ; DE = 0xE045, el byte alto del record
	ld hl,0382ch		;4390   ; HL = VRAM 0x382c
	call seis_cifras		;4393
escribe_la_puntuacion:		; Los tres bytes de la puntuacion, en la fila 0x3822
	ld hl,03822h		;4396   ; HL = VRAM 0x3822
	ld de,0e04bh		;4399   ; DE = 0xE04B, el byte alto de la puntuacion
seis_cifras:		; Tres bytes, seis cifras, con los ceros de delante tapados
	ld b,003h		;439c   ; B = 3 bytes
	jr empieza_tapando		;439e
escribe_la_vuelta:		; La vuelta de 0xE051, dos cifras, y esta SIN tapar los ceros
	ld hl,0381bh		;43a0   ; HL = VRAM 0x381b
dos_cifras_sin_tapar:		; Un solo byte y con C ya a 0xFF: los ceros se ven
	ld de,0e051h		;43a3   ; DE = 0xE051, la vuelta
	ld b,001h		;43a6   ; un byte, dos cifras
	ld c,0ffh		;43a8   ; C = 0xFF: nada se tapa
	jr escribe_una_pareja_de_cifras		;43aa
empieza_tapando:		; C a cero: los ceros de delante se escriben como hueco
	ld c,000h		;43ac   ; C = 0, la mascara que tapa
escribe_una_pareja_de_cifras:		; El nibble alto y luego el bajo, cada uno como tile 0x10 + cifra, y en cuanto sale una cifra que no es cero la mascara se abre
	ld a,(de)			;43ae   ; A = el byte de la pareja
	rra			;43af   ; cuatro rotaciones: el nibble alto abajo
	rra			;43b0
	rra			;43b1
	rra			;43b2
	and 00fh		;43b3
	jr z,escribe_una_pareja_de_cifras_si_no		;43b5   ; si no es cero...
	ld c,0ffh		;43b7   ; ...la mascara se abre y ya no se tapa nada
escribe_una_pareja_de_cifras_si_no:		; Dentro de escribe_una_pareja_de_cifras
	add a,010h		;43b9   ; tile 0x10 + la cifra
	and c			;43bb   ; tapado o no, segun la mascara
	call 0004dh		;43bc   ; BIOS WRTVRM - Writes data in VRAM | escrito en la VRAM
	inc hl			;43bf
	djnz y_ahora_el_nibble_bajo		;43c0   ; en el ultimo byte...
	ld c,0ffh		;43c2   ; ...la mascara se abre siempre: el cero de las unidades se ve
y_ahora_el_nibble_bajo:		; La segunda cifra de la pareja
	inc b			;43c4
	ld a,(de)			;43c5   ; el byte otra vez
	and 00fh		;43c6   ; su nibble bajo
	jr z,y_ahora_el_nibble_bajo_si_no		;43c8
	ld c,0ffh		;43ca   ; la mascara se abre
y_ahora_el_nibble_bajo_si_no:		; Dentro de y_ahora_el_nibble_bajo
	add a,010h		;43cc   ; tile 0x10 + la cifra
	and c			;43ce
	call 0004dh		;43cf   ; BIOS WRTVRM - Writes data in VRAM | escrito
	dec de			;43d2   ; el byte anterior: se va de mas a menos peso
	inc hl			;43d3
	djnz escribe_una_pareja_de_cifras		;43d4
	ret			;43d6
escribe_las_vidas:		; Una sola cifra, la de 0xE050, en la fila 0x383a
	ld hl,0383ah		;43d7   ; HL = VRAM 0x383a
	ld a,(0e050h)		;43da   ; (0xE050), las vidas
	add a,010h		;43dd   ; tile 0x10 + la cifra
	jp 0004dh		;43df   ; BIOS WRTVRM - Writes data in VRAM
monta_la_pantalla_de_titulo:		; El fondo y el rotulo
	call borra_y_dibuja_el_fondo		;43e2
	jp dibuja_los_rotulos_del_titulo		;43e5
borra_y_dibuja_el_fondo:		; Pone el registro 7 a 0xE0, monta el combate y dibuja los dos guiones del fondo
	ld b,0e0h		;43e8   ; B = 0xE0, el color de borde
	call escribe_el_registro_7		;43ea   ; al registro 7 del VDP
	call monta_el_fondo_de_pantalla		;43ed
dibuja_los_dos_guiones_del_fondo:		; El de 0x57f5 en la VRAM 0x2600 y el de 0x57ee en la 0x0600: los patrones y sus colores
	ld hl,02600h		;43f0   ; HL = VRAM 0x2600, los patrones
	ld de,057f5h		;43f3   ; DE = 0x57f5, su guion
	call dibuja_el_guion_en_el_puerto_cero		;43f6
	ld hl,00600h		;43f9   ; HL = VRAM 0x0600, los colores
	ld de,057eeh		;43fc   ; DE = 0x57ee, su guion
	jp dibuja_el_guion_en_el_puerto_cero		;43ff
dibuja_los_rotulos_del_titulo:		; DOS listas, no tres: la de 0x5909, que es el logotipo del juego en treinta y seis tiles, y la de 0x559b, que trae el PUSH SPACE KEY y el copyright. Sale siempre con A a cero y, por tanto, con el acarreo borrado
	ld de,05909h		;4402   ; DE = 0x5909
	call dibuja_la_lista		;4405   ; dibujada
	ld de,0559bh		;4408   ; DE = 0x559b
	call dibuja_la_lista		;440b
	xor a			;440e
	ret			;440f
borra_la_pantalla:		; Repone el reloj y pone a cero las 768 posiciones de la tabla de nombres
	call devuelve_el_reloj_al_tope		;4410   ; el reloj, al tope
	ld hl,03800h		;4413   ; HL = VRAM 0x3800, la tabla de nombres
	ld bc,00300h		;4416   ; 768 posiciones
	xor a			;4419
	jp 00056h		;441a   ; BIOS FILVRM - Fills VRAM with value | a cero
copia_poniendo_b_a_cero:		; Pone SOLO el byte alto de la cuenta a cero y deja el bajo como venga, asi que copia los C bytes que traiga quien llama. Serian 256 unicamente si C entrase valiendo cero, y el unico que entra por aqui -0x53ca- trae en C la anchura de la fila que esta dibujando
	ld b,000h		;441d   ; solo el byte alto de la cuenta; C ya trae la anchura
copia_a_vram:		; BC bytes de (HL) a la VRAM que trae DE
	ex de,hl			;441f
	jp 0005ch		;4420   ; BIOS LDIRVM - Block transfers to VRAM from memory | LDIRVM lo hace todo
encadena_el_guion:		; El comando 0x80: lee del propio guion la direccion de VRAM nueva -BYTE BAJO PRIMERO, como en King's Valley- y sigue dibujando ahi
	ex de,hl			;4423   ; HL = el guion
	ld e,(hl)			;4424   ; E = el byte bajo de la direccion
	inc hl			;4425
	ld d,(hl)			;4426   ; D = el alto
	ex de,hl			;4427   ; y cambiados: HL la direccion, DE el guion
	inc de			;4428   ; el guion, dos bytes mas alla
dibuja_el_guion:		; Arma la escritura en HL y ejecuta el guion de DE
	call arma_la_escritura		;4429   ; arma la escritura y deja el puerto en C'
lee_un_comando_del_guion:		; El cuerpo del interprete. Un byte por vuelta: los siete bits bajos son la cuenta, y si el byte crudo es igual a ella -o sea si el bit 7 estaba a cero- es un relleno; si no, una copia cruda. La cuenta a cero es fin o encadenado
	ld a,(de)			;442c   ; A = el byte de comando
	and 07fh		;442d   ; los siete bits de cuenta
	ld b,a			;442f   ; B = la cuenta
	ld a,(de)			;4430   ; y A se queda el byte crudo
	inc de			;4431
	jr z,fin_o_encadena		;4432   ; cuenta cero: fin o encadenado
	cp b			;4434   ; iguales quiere decir bit 7 a cero: relleno
	jr z,relleno		;4435
copia_cruda:		; B bytes del guion al puerto de datos, tal cual
	ld a,(de)			;4437   ; el byte del guion
	inc de			;4438
	exx			;4439
	out (c),a		;443a   ; al VDP
	exx			;443c
	djnz copia_cruda		;443d   ; hasta agotar la cuenta
	jr lee_un_comando_del_guion		;443f
relleno:		; Un byte repetido B veces
	ld a,(de)			;4441   ; el byte que se repite
	inc de			;4442
escribe_el_relleno:		; B veces, con un `push hl / pop hl` de por medio que hace de espera: el VDP necesita unos ciclos entre byte y byte
	exx			;4443
	out (c),a		;4444   ; al VDP
	exx			;4446
	push hl			;4447   ; doce ciclos de espera para el VDP
	pop hl			;4448
	djnz escribe_el_relleno		;4449   ; hasta agotar la cuenta
	jr lee_un_comando_del_guion		;444b
fin_o_encadena:		; Con la cuenta a cero: 0x00 acaba el guion y 0x80 encadena
	cp b			;444d   ; 0x00 exacto: fin
	jr nz,encadena_el_guion		;444e   ; y si no, era 0x80: encadena
	ei			;4450
	ret			;4451
dibuja_el_guion_en_el_puerto_cero:		; Como dibuja_el_guion pero con C a cero
	ld c,000h		;4452   ; C = 0
	jr dibuja_el_guion		;4454
arma_la_escritura:		; SETWRT en HL y el puerto de datos, del byte 0x0006 de la BIOS, en el C del juego alterno: asi el bucle del guion puede sacar bytes sin tocar los registros normales
	ex af,af'			;4456
	call 00053h		;4457   ; BIOS SETWRT - Enables VDP to write | arma la escritura en la VRAM
	exx			;445a
	ld a,(00006h)		;445b   ; (0x0006) de la BIOS: el puerto de datos
	ld c,a			;445e   ; a C', el del juego alterno
	exx			;445f
	ex af,af'			;4460
	ret			;4461
refleja_varias_filas:		; Refleja C filas de tiles, subiendo 0x20 cada vez
	call refleja_una_fila		;4462
	ld a,020h		;4465   ; 0x20 hasta la fila siguiente
	call suma_a_de		;4467
	dec c			;446a   ; una fila menos
	jr nz,refleja_varias_filas		;446b
	ret			;446d
refleja_una_fila:		; Lee dieciseis bytes de la VRAM, les da la vuelta bit a bit y los escribe donde diga HL. Es como el cartucho consigue el luchador mirando al otro lado sin gastar un solo byte de dibujo mas
	push de			;446e   ; la fila, a salvo
dieciseis_bytes:		; Dieciseis, que son dos tiles de alto
	ld b,010h		;446f   ; dieciseis bytes
refleja_un_byte:		; Leer, dar la vuelta, escribir
	call 0004ah		;4471   ; BIOS RDVRM - Reads the content of VRAM | lee el byte de la VRAM
	call da_la_vuelta_al_byte		;4474   ; le da la vuelta bit a bit
	ex de,hl			;4477
	call 0004dh		;4478   ; BIOS WRTVRM - Writes data in VRAM | y lo escribe en el otro sitio
	ex de,hl			;447b
	inc e			;447c   ; origen y destino, uno mas
	inc hl			;447d
	djnz refleja_un_byte		;447e
	ld a,e			;4480   ; 0x20 atras
	sub 020h		;4481
	ld e,a			;4483
	bit 4,e		;4484   ; su bit 4 dice si quedan filas
	jr z,dieciseis_bytes		;4486
	pop de			;4488
	ret			;4489

; ----------------------------------------------------------------------
; DATOS resto_448a: Cinco bytes entre dos rutinas. Decodifican como codigo
;   -`ld a,(de) / inc de / bit 0,c / ret z`- y estan pegados al final de
;   refleja_una_fila, pero ningun salto ni llamada de toda la ROM aterriza en
;   ellos: son restos
;   0x448a..0x448f  (5 bytes)
DATA_resto_448a:
	defb 01ah,013h,0cbh,041h,0c8h	; 448a

; ======================================================================
; CODIGO 0x448f..0x4503  (116 bytes)
; ======================================================================


da_la_vuelta_al_byte:		; Invierte los ocho bits de A: los saca por abajo de C con `rr` y los mete por abajo de A con `rla`, ocho veces
	push bc			;448f
	ld c,a			;4490   ; C = el byte a invertir
	ld b,008h		;4491   ; ocho bits
un_bit_al_reves:		; Sale por abajo y entra por abajo, que es lo que le da la vuelta
	rr c		;4493   ; el bit de menos peso, al acarreo
	rla			;4495   ; y del acarreo al de menos peso de A
	djnz un_bit_al_reves		;4496
	pop bc			;4498
	ret			;4499
dibuja_la_lista_sin_encadenar:		; Entra directamente en el cuerpo, con la lista ya apuntada por DE
	ld c,0ffh		;449a   ; C = 0xFF: se escribe lo que diga la lista
	jr lee_un_tile_de_la_lista		;449c
dibuja_la_lista:		; Dibuja una lista de tiles: escribe lo que diga
	ld c,0ffh		;449e   ; C = 0xFF, la mascara abierta
encadena_la_lista:		; El comando 0xFE: lee la direccion de VRAM nueva -byte bajo primero- y sigue ahi
	ex de,hl			;44a0   ; HL = la lista
	ld e,(hl)			;44a1   ; E = el byte bajo de la direccion
	inc hl			;44a2
	ld d,(hl)			;44a3   ; D = el alto
	ex de,hl			;44a4   ; cambiados
	inc de			;44a5   ; la lista, dos bytes mas alla
lee_un_tile_de_la_lista:		; Un byte por vuelta. 0xFF acaba y 0xFE encadena; el resto es el tile, pasado por la mascara de C
	ld a,(de)			;44a6   ; el byte de la lista
	inc de			;44a7
	ld b,a			;44a8   ; B se lo queda
	inc b			;44a9   ; 0xFF: fin de la lista
	ret z			;44aa
	inc b			;44ab   ; 0xFE: encadena
	jr z,encadena_la_lista		;44ac
	and c			;44ae   ; por la mascara: 0xFF lo deja pasar y 0x00 escribe un hueco
	call 0004dh		;44af   ; BIOS WRTVRM - Writes data in VRAM | escrito en la VRAM
	inc hl			;44b2   ; la posicion siguiente
	jr lee_un_tile_de_la_lista		;44b3
borra_la_lista:		; La misma lista, pero con la mascara cerrada: donde habia tiles quedan huecos
	ld c,000h		;44b5   ; C = 0, la mascara cerrada
	jr encadena_la_lista		;44b7
rellena_los_tres_tercios:		; Rellena el mismo bloque en los tres tercios de SCREEN 2, subiendo 0x800 cada vez
	ld d,003h		;44b9   ; tres tercios
un_tercio_relleno:		; FILVRM y 0x800 mas
	push bc			;44bb
	push de			;44bc
	call 00056h		;44bd   ; BIOS FILVRM - Fills VRAM with value | relleno
	ld de,00800h		;44c0   ; 0x800: el tercio siguiente
	add hl,de			;44c3
	pop de			;44c4
	pop bc			;44c5
	dec d			;44c6   ; un tercio menos
	jr nz,un_tercio_relleno		;44c7
	ret			;44c9
dibuja_en_dos_tercios:		; El mismo guion en los dos primeros tercios
	ld b,002h		;44ca   ; dos tercios
	jr un_tercio_dibujado		;44cc
dibuja_en_los_tres_tercios:		; Y en los tres
	ld b,003h		;44ce   ; tres tercios
un_tercio_dibujado:		; El guion, y 0x800 mas
	push bc			;44d0
	push de			;44d1
	call dibuja_el_guion_en_el_puerto_cero		;44d2   ; el guion en este tercio
	ld de,00800h		;44d5   ; 0x800: el tercio siguiente
	add hl,de			;44d8
	pop de			;44d9
	pop bc			;44da
	djnz un_tercio_dibujado		;44db   ; un tercio menos
	ret			;44dd
carga_los_graficos:		; Lo que INIT llama antes de encender nada: calla el PSG, arranca la musica de la portada, borra los 16 KB de VRAM y programa los ocho registros del VDP
	ld a,0b8h		;44de   ; A = 0xB8, el registro 7 del PSG: todo callado
	call enciende_o_apaga_el_tono_otra_vuelta		;44e0
	ld a,092h		;44e3   ; A = 0x92, la melodia de la portada
	call pon_la_melodia		;44e5
	ld de,00000h		;44e8   ; DE = VRAM 0x0000
	ld bc,04000h		;44eb   ; los 16 KB enteros
	xor a			;44ee
	call 00056h		;44ef   ; BIOS FILVRM - Fills VRAM with value | a cero
carga_los_registros_del_vdp:		; Los ocho valores de 0x4503, de R0 a R7
	ld hl,04503h		;44f2   ; HL = la tabla de registros
	ld d,008h		;44f5   ; ocho
	ld c,000h		;44f7   ; empezando por el R0
un_registro_del_vdp:		; Valor y numero, y a por el siguiente
	ld b,(hl)			;44f9   ; B = el valor
	call 00047h		;44fa   ; BIOS WRTVDP - Writes data in the VDP-register | WRTVDP lo escribe
	inc hl			;44fd
	inc c			;44fe   ; el registro siguiente
	dec d			;44ff   ; uno menos
	jr nz,un_registro_del_vdp		;4500
	ret			;4502

; ----------------------------------------------------------------------
; DATOS tabla_registros_vdp: Los ocho valores crudos de R0 a R7 que carga
;   0x44f2: 02 E2 0E 7F 07 76 03 E0. Son los MISMOS que los de King's Valley y
;   Konami's Baseball salvo R7, el color de borde. El mapa de VRAM entero sale
;   de aqui: R2 = 0x0E pone la tabla de NOMBRES en 0x3800; R3 = 0x7F y R4 =
;   0x07 no son direcciones sino base y mascara, y dicen COLOR en 0x0000 y
;   PATRON en 0x2000, al reves de lo habitual; R5 = 0x76 pone los ATRIBUTOS de
;   sprite en 0x3b00 y R6 = 0x03 los PATRONES de sprite en 0x1800; y R1 =
;   0xE2, con el bit 1 puesto y el 0 a cero, quiere decir sprites de 16x16 sin
;   ampliar
;   0x4503..0x450b  (8 bytes)
DATA_tabla_registros_vdp:
	defb 002h,0e2h,00eh,07fh,007h,076h,003h,0e0h	; 4503  .....v..

; ======================================================================
; CODIGO 0x450b..0x460d  (258 bytes)
; ======================================================================


escribe_el_registro_7:		; El color de borde y de fondo, que el juego cambia varias veces
	ld c,007h		;450b   ; C = 7, el registro
	jp 00047h		;450d   ; BIOS WRTVDP - Writes data in the VDP-register
lee_el_joystick:		; El puerto A del joystick, por el PSG. Selecciona el puerto con el registro 15 y lee el 14; los seis bits bajos, invertidos, son arriba, abajo, izquierda, derecha y los dos disparos
	ld e,08fh		;4510   ; E = 0x8F al registro 15: puerto A seleccionado
	ld a,00fh		;4512
	call 00093h		;4514   ; BIOS WRTPSG - Writes data to PSG-register
	ld a,00eh		;4517   ; y a leer el registro 14
	di			;4519   ; sin interrupciones mientras se lee el PSG
	call 00096h		;451a   ; BIOS RDPSG - Reads value from PSG-register
	ei			;451d
	cpl			;451e   ; el PSG da los botones a cero: invertidos
	and 03fh		;451f   ; y solo los seis bits que hay
	ret			;4521
lee_los_mandos_de_la_partida:		; Junta joystick y teclado, y con el bit 6 de 0xE002 a cero -o sea sin nadie jugando- deja que 0x4564 se invente los mandos, que es como corre la secuencia de atraccion. Guarda el estado en 0xE00A y los RECIEN PULSADOS en 0xE009
	call lee_el_joystick		;4522   ; el joystick
	push af			;4525
	call lee_el_teclado		;4526   ; y el teclado
	pop hl			;4529
	or h			;452a   ; los dos juntos, que da igual con cual se juegue
	ld hl,0e002h		;452b
	bit 6,(hl)		;452e   ; el bit 6 de 0xE002: hay alguien jugando
	call z,se_inventa_los_mandos		;4530   ; y si no, los mandos se los inventa la demo
	ld hl,0e00ah		;4533   ; HL = 0xE00A, el estado del cuadro anterior
	ld c,(hl)			;4536
	ld (hl),a			;4537
	xor c			;4538   ; lo que ha cambiado...
	and (hl)			;4539   ; ...y de eso, lo que esta pulsado ahora: los flancos
	dec hl			;453a
	ld (hl),a			;453b   ; a 0xE009
	inc hl			;453c
	ld a,(hl)			;453d
	ret			;453e
lee_el_teclado:		; Las teclas, de las filas 7 y 8 de la matriz, colocadas en los mismos bits que el joystick. Las cinco rotaciones no son adorno: son lo que lleva cada tecla a su bit
	ld a,007h		;453f   ; la fila 7 de la matriz
	call 00141h		;4541   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix
	cpl			;4544   ; la matriz da las teclas a cero: invertida
	rrca			;4545   ; una rotacion, y el bit 6 -SELECT- cae en el 5, el del disparo B
	and 020h		;4546
	ld e,a			;4548
	ld a,008h		;4549   ; la fila 8
	call 00141h		;454b   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix
	cpl			;454e   ; invertida tambien
	rrca			;454f
	rrca			;4550   ; dos rotaciones: LEFT, que era el bit 4, cae en el 2
	ld b,a			;4551
	and 004h		;4552   ; y ese es el unico que se coge de aqui
	or e			;4554   ; con el disparo B de antes
	ld c,a			;4555
	ld a,b			;4556
	rrca			;4557   ; dos rotaciones mas, cuatro en total
	rrca			;4558
	ld b,a			;4559
	and 018h		;455a   ; RIGHT cae en el 3 y SPACE, dando la vuelta, en el 4
	or c			;455c
	ld c,a			;455d
	ld a,b			;455e
	rrca			;455f   ; la quinta: UP cae en el 0 y DOWN en el 1
	and 003h		;4560   ; los dos de arriba y abajo
	or c			;4562   ; y con todo lo demas
	ret			;4563
se_inventa_los_mandos:		; Lo que hace de jugador en la secuencia de atraccion: cada vez que 0xE013 llega a cero, sube 0xE00c y se da otros 0x20 cuadros
	ld hl,0e00ch		;4564   ; HL = 0xE00c, la posicion en la lista
	ld a,(0e013h)		;4567   ; el plazo
	or a			;456a
	jr nz,baja_el_plazo_de_la_atraccion		;456b   ; con plazo, no se cambia
	inc (hl)			;456d   ; una posicion mas
	ld a,020h		;456e   ; y otros 0x20 cuadros
baja_el_plazo_de_la_atraccion:		; Guarda A menos uno en 0xE013 y con lo que traiga 0xE00c busca en la lista de 0x55de; el 0xFF del final marca 0xE106
	dec a			;4570   ; un cuadro menos
	ld (0e013h),a		;4571   ; el plazo, guardado
	ld a,(hl)			;4574   ; la posicion en la lista
	ld hl,055deh		;4575   ; la lista de la atraccion
	call suma_a_hl		;4578
	ld a,(hl)			;457b
	cp 0ffh		;457c   ; el 0xFF cierra la vuelta
	ret nz			;457e
	ld (0e106h),a		;457f   ; y queda apuntado en 0xE106
	ret			;4582
mira_si_arranca_la_partida:		; El otro lector, el de fuera de la partida. Lleva su propio estado en 0xE040 y su anterior en 0xE041. Con la escena 1 en marcha y el disparo pulsado -el bit 4, o sea espacio- enciende el bit 6 de 0xE002, que es lo que dice que ya hay alguien jugando, y se va a la escena 3 con el paso 0
	call lee_el_joystick		;4583   ; el joystick
	ld d,a			;4586
	call lee_el_teclado		;4587   ; y el teclado
	or d			;458a
	ld hl,0e040h		;458b   ; HL = 0xE040, el estado de este lector
	ld c,(hl)			;458e
	ld (hl),a			;458f   ; el nuevo entra...
	inc hl			;4590
	ld (hl),c			;4591   ; ...y el viejo pasa a 0xE041
	ld b,a			;4592
	xor c			;4593   ; lo que ha cambiado...
	and b			;4594   ; ...y esta pulsado: los flancos
	ret z			;4595   ; sin nada nuevo, no hay mas que hacer
	ld b,a			;4596
	xor a			;4597
	ld (0e004h),a		;4598   ; el plazo, a cero
	ld a,001h		;459b
	ld hl,0e000h		;459d   ; y con la escena 1 en marcha...
	cp (hl)			;45a0
	jr nz,mira_si_arranca_la_partida_si_no		;45a1
	ld a,b			;45a3
	cp 010h		;45a4   ; ...hace falta el bit 4 o mas, o sea el disparo
	ret c			;45a6
	ld a,040h		;45a7   ; el bit 6 de 0xE002: ya hay alguien jugando
	ld (0e002h),a		;45a9
	ld hl,00003h		;45ac   ; escena 3 y paso 0, de una tacada
	ld (0e000h),hl		;45af
	ret			;45b2
mira_si_arranca_la_partida_si_no:		; Dentro de mira_si_arranca_la_partida
	ld (hl),a			;45b3   ; y si no era la escena 1, se pone la 1 y a seguir
	jp borra_y_sigue		;45b4
arranca_la_subida:		; Prepara la figura que sube por la portada: diecisiete pasos en 0xE00D, la posicion de partida en 0xE00E -la VRAM 0x3aaa, o sea la fila 21 columna 10- y el borde en 0xE4
	ld a,011h		;45b7   ; diecisiete pasos
	ld (0e00dh),a		;45b9
	ld hl,03aaah		;45bc   ; VRAM 0x3aaa: fila 21, columna 10
	ld (0e00eh),hl		;45bf
	ld b,0e4h		;45c2   ; B = 0xE4 al registro 7, el color de borde
	jp escribe_el_registro_7		;45c4
sube_un_paso:		; Un paso de la figura de la portada: sube una fila y se redibuja con tiles correlativos, tres arriba, once en medio y doce abajo, empezando por el 0x40. Debajo borra doce, que es el rastro que deja al subir. Vuelve con Z puesto cuando se agotan los diecisiete pasos de 0xE00D
	ld hl,(0e00eh)		;45c7   ; la posicion de ahora
	ld de,0ffe0h		;45ca   ; menos 0x20, o sea una fila mas arriba
	add hl,de			;45cd
	ld (0e00eh),hl		;45ce
	ld a,040h		;45d1   ; A = 0x40, el primer tile
	ld b,003h		;45d3   ; tres en la primera fila
	call escribe_tiles_correlativos		;45d5
	ld bc,00b0ch		;45d8   ; once en la segunda y doce en la tercera
	call escribe_tiles_correlativos		;45db
	ld b,c			;45de
	call escribe_tiles_correlativos		;45df
	xor a			;45e2   ; y debajo, doce a cero: el rastro
	call 00056h		;45e3   ; BIOS FILVRM - Fills VRAM with value
	ld hl,0e00dh		;45e6   ; un paso menos de los diecisiete
	dec (hl)			;45e9
	ret			;45ea
escribe_tiles_correlativos:		; B tiles seguidos a partir de A, y devuelve HL apuntando a la fila de abajo
	push hl			;45eb   ; la fila, a salvo
escribe_tiles_correlativos_otra_vuelta:		; Dentro de escribe_tiles_correlativos
	call 0004dh		;45ec   ; BIOS WRTVRM - Writes data in VRAM | el tile
	inc hl			;45ef
	inc a			;45f0   ; y el siguiente numero
	djnz escribe_tiles_correlativos_otra_vuelta		;45f1
	pop de			;45f3
	ld hl,00020h		;45f4   ; 0x20 mas: la fila de abajo
	add hl,de			;45f7
	ret			;45f8
un_cuadro_de_combate:		; El cuadro entero de la partida. Cada dos cuadros llama a 0x6b6a, siempre a 0x4b0f, y luego reparte por 0xE110 entre las siete rutinas de la tabla de 0x460d
	ld a,(0e003h)		;45f9   ; el contador de cuadros
	bit 0,a		;45fc   ; su bit 0: uno de cada dos
	call z,acerca_el_reloj_a_su_tope		;45fe
	call apunta_los_puntos_del_golpe		;4601
	ld a,(0e110h)		;4604   ; 0xE110 dice cual de los siete
	ld hl,0460dh		;4607
	call despacha_por_la_tabla_de_al_lado		;460a   ; y a repartir por la tabla de al lado

; ----------------------------------------------------------------------
; DATOS tabla_de_los_siete_dibujos: Los siete punteros que despacha 0x460a:
;   0x461b, 0x472d, 0x478c, 0x4802, 0x486b, 0x48ce y 0x4961
;   0x460d..0x461b  (14 bytes)
DATA_tabla_de_los_siete_dibujos:
	defw 0461bh,0472dh,0478ch,04802h,0486bh,048ceh,04961h	; 460d

; ======================================================================
; CODIGO 0x461b..0x4729  (270 bytes)
; ======================================================================


combate_normal:		; La primera de las siete, la del combate en marcha. Va por partes: los cuadros pares mueven al oponente, los impares rehacen las figuras y las mandan a la VRAM, y despues vienen las comprobaciones de golpe
	ld a,(0e003h)		;461b   ; el contador de cuadros
	rra			;461e   ; su bit 0, al acarreo
	jr c,solo_para_el_tercer_oponente		;461f
	ld a,(0e111h)		;4621   ; con 0xE111 puesto, se remata por 0x46cf
	and a			;4624
	jr z,$+10		;4625
	ld a,(0e1e4h)		;4627
	call escribe_el_cuarto_sprite_si_no_2		;462a   ; con lo que traiga 0xE1e4
	jp el_remate		;462d
	call el_paso_del_oponente		;4630   ; y si no, el paso normal del oponente
solo_para_el_tercer_oponente:		; Cuatro poses del oponente 2 -las 2, 3, 16 y 17 de 0xE184- llevan ademas 0x7162 y 0x718d. Los otros cuatro oponentes no pasan por aqui
	ld a,(0e054h)		;4633   ; el oponente de turno
	cp 002h		;4636   ; solo el 2, o sea CHEN
	jr nz,rehace_las_figuras		;4638
	ld a,(0e184h)		;463a   ; la pose de ahora
	sub 002h		;463d   ; la 2...
	jr z,solo_para_el_tercer_oponente_por_aqui		;463f
	dec a			;4641   ; ...la 3...
	jr z,solo_para_el_tercer_oponente_por_aqui		;4642
	sub 00dh		;4644   ; ...la 16...
	jr z,solo_para_el_tercer_oponente_por_aqui		;4646
	dec a			;4648   ; ...o la 17
	jr nz,rehace_las_figuras		;4649
solo_para_el_tercer_oponente_por_aqui:		; Dentro de solo_para_el_tercer_oponente
	call mueve_el_arma_larga		;464b
	call redibuja_el_arma_larga		;464e
rehace_las_figuras:		; Los cuadros IMPARES: la maquina de estados de 0x4d24, el montaje de la pose en 0xE0c4 y el volcado de los 0x80 bytes de atributos a la VRAM
	ld a,(0e003h)		;4651   ; el contador de cuadros otra vez
	rra			;4654   ; y ahora se quiere el impar
	jr nc,las_comprobaciones		;4655
	call la_maquina_de_estados		;4657   ; la maquina de estados grande
	call monta_la_pose		;465a   ; monta la pose en la tabla de atributos
	call vuelca_los_sprites		;465d   ; y los 0x80 bytes, a la VRAM
las_comprobaciones:		; Con 0xE058 distinto de cero no hay nada que comprobar. Si no, van seguidas la cuenta de 0xE11b, el golpe del oponente y el del jugador
	ld a,(0e058h)		;4660   ; con esto puesto no se comprueba nada
	and a			;4663
	jp nz,mira_si_le_da_el_jugador		;4664
	ld hl,0e11bh		;4667   ; HL = 0xE11b, una cuenta atras
	ld a,(hl)			;466a
	push af			;466b
	push hl			;466c
	dec a			;466d   ; valiendo uno, ademas se llama a 0x4b57
	call z,esconde_el_chispazo		;466e
	pop hl			;4671
	pop af			;4672
	and a			;4673
	jr z,mira_si_le_dan_al_jugador		;4674
	dec (hl)			;4676   ; y si no era cero, se baja uno
mira_si_le_dan_al_jugador:		; Con 0xE127 a cero y 0xE150 en 8 o mas, 0x4aec dice si hay contacto; entonces suena el golpe de 0x49f3 con la pose de 0xE172 y se levanta el banderin de 0xE115
	ld a,(0e127h)		;4677   ; con 0xE127 puesto no se comprueba
	and a			;467a
	jr nz,mira_si_se_acaba_el_asalto		;467b
	ld a,(0e150h)		;467d   ; y hace falta que 0xE150 llegue a 8
	cp 008h		;4680
	jr c,mira_si_se_acaba_el_asalto		;4682
	call mira_si_el_golpe_toca_al_arma		;4684   ; y que 0x4aec diga que si
	jr z,mira_si_se_acaba_el_asalto		;4687
	ld a,(0e172h)		;4689   ; la pose de ahora
	call marca_el_golpe_recibido		;468c
	ld a,001h		;468f
	ld (0e115h),a		;4691   ; el banderin, levantado
mira_si_se_acaba_el_asalto:		; 0x4aaf decide; el banderin de 0xE119 hace que solo cuente una vez
	call elige_el_arma_por_la_altura		;4694   ; con 0x4aaf diciendo que si...
	jr z,mira_si_se_acaba_el_asalto_si_no		;4697
	ld a,(0e119h)		;4699   ; ...y el banderin de 0xE119 sin levantar...
	and a			;469c
	jr nz,mira_el_umbral_del_oponente		;469d
	inc a			;469f   ; ...se levanta
	ld (0e119h),a		;46a0
	jr el_remate		;46a3
mira_si_se_acaba_el_asalto_si_no:		; Dentro de mira_si_se_acaba_el_asalto
	ld (0e119h),a		;46a5
mira_el_umbral_del_oponente:		; Con 0xE1d0 a cero, 0xE16b tiene que llegar al umbral que la tabla de 0x4729 da para este oponente; por debajo, no se sigue comprobando
	ld a,(0e1d0h)		;46a8   ; con esto puesto se salta el umbral
	and a			;46ab
	jr nz,remata_al_oponente		;46ac
	ld hl,04729h		;46ae   ; la tabla de los cuatro umbrales
	ld a,(0e056h)		;46b1   ; indexada por 0xE056
	call suma_a_hl		;46b4
	ld a,(0e16bh)		;46b7   ; contra 0xE16b
	cp (hl)			;46ba
	jr c,mira_si_le_da_el_jugador		;46bb   ; por debajo del umbral, a las de abajo
remata_al_oponente:		; Con 0x4a63 diciendo que si y el banderin de 0xE118 sin levantar, se levanta, se llama a 0x4b82 y se pasa al remate
	call mira_si_le_dan_al_jugador_de_verdad		;46bd   ; 0x4a63 decide
	jr z,baja_el_banderin_de_e118		;46c0
	ld a,(0e118h)		;46c2   ; el banderin de 0xE118
	and a			;46c5
	jr nz,mira_si_le_da_el_jugador		;46c6
	inc a			;46c8
	ld (0e118h),a		;46c9   ; levantado
	call escribe_el_cuarto_sprite_si_no		;46cc
el_remate:		; Plazo de 0x20 cuadros, melodia 0x42 y modo 5 en 0xE110
	ld a,020h		;46cf   ; 0x20 cuadros de plazo
	ld (0e004h),a		;46d1
	ld a,042h		;46d4   ; A = 0x42, la melodia del golpe
	call pon_la_melodia		;46d6
	ld a,005h		;46d9   ; y el modo 5
	jp fija_el_modo		;46db
baja_el_banderin_de_e118:		; Con A a cero, que es lo que trae 0x4a63 cuando dice que no
	ld (0e118h),a		;46de   ; el banderin, bajado
mira_si_le_da_el_jugador:		; Con 0xE165 en 5 y 0xE160 por debajo de 0x76 se pasa directo; si no, hace falta que 0xE150 llegue a 8
	ld a,(0e165h)		;46e1   ; 0xE165 valiendo 5...
	cp 005h		;46e4
	jr nz,mira_si_le_da_el_jugador_si_no		;46e6
	ld a,(0e160h)		;46e8   ; ...y 0xE160 por debajo de 0x76
	cp 076h		;46eb
	jr c,el_golpe_del_jugador		;46ed
mira_si_le_da_el_jugador_si_no:		; Dentro de mira_si_le_da_el_jugador
	ld a,(0e150h)		;46ef   ; y si no, 0xE150 tiene que llegar a 8
	cp 008h		;46f2
	jr c,baja_el_banderin_de_e11a		;46f4
el_golpe_del_jugador:		; Con 0xE1b8 a cero y 0x4a0f diciendo que si, y el banderin de 0xE11a sin levantar: suena la melodia 0x42, se apunta el tanto con 0x4b2d, 0xE165 se copia a 0xE115 y a 0xE11d, y se pasa al modo con plazo de 0x20
	ld a,(0e1b8h)		;46f6   ; con 0xE1b8 puesto no hay golpe
	and a			;46f9
	jr nz,baja_el_banderin_de_e11a		;46fa
	call mira_si_el_golpe_da		;46fc   ; 0x4a0f decide
	jr z,baja_el_banderin_de_e11a		;46ff
	ld a,(0e11ah)		;4701   ; el banderin de 0xE11a
	and a			;4704
	jr nz,baja_el_banderin_de_e11a_y_vuelve		;4705
	inc a			;4707
	ld (0e11ah),a		;4708   ; levantado
	ld a,042h		;470b   ; A = 0x42, la melodia del golpe
	call pon_la_melodia		;470d
	call pon_el_chispazo		;4710   ; apunta el tanto
	ld a,(0e165h)		;4713   ; 0xE165 se guarda por partida doble
	ld (0e115h),a		;4716
	ld (0e11dh),a		;4719
	call pide_cuatro_cuadros_de_espera		;471c   ; y el aviso de 0x744a
	ld a,020h		;471f   ; plazo de 0x20
	jp pon_plazo_y_pasa_de_modo		;4721
baja_el_banderin_de_e11a:		; Y a esperar al cuadro siguiente
	xor a			;4724   ; el banderin, bajado
	ld (0e11ah),a		;4725
baja_el_banderin_de_e11a_y_vuelve:		; Dentro de baja_el_banderin_de_e11a
	ret			;4728

; ----------------------------------------------------------------------
; DATOS umbrales_por_oponente: Cuatro bytes, 07 06 03 01, que 0x46ae indexa
;   por 0xE056 para compararlos con 0xE16b. Cuanto mas alto el oponente, mas
;   bajo el umbral
;   0x4729..0x472d  (4 bytes)
DATA_umbrales_por_oponente:
	defb 007h,006h,003h,001h	; 4729

; ======================================================================
; CODIGO 0x472d..0x47cc  (159 bytes)
; ======================================================================


modo_1_la_pausa:		; El segundo de los siete. Mientras 0xE134 no llegue a 4, mueve 0xE181 arriba y abajo con los dos bits bajos del contador de cuadros -sube en el 0 y baja en el 2- y rehace la figura. Cuando se agota el plazo de 0xE004 lo deja todo listo para el asalto siguiente
	ld de,0e134h		;472d   ; DE = 0xE134, el contador de la pausa
	ld a,(de)			;4730
	cp 004h		;4731   ; hasta cuatro
	jr nc,modo_1_la_pausa_si_no_4		;4733
	ld hl,0e181h		;4735   ; HL = 0xE181
	ld a,(0e003h)		;4738   ; los dos bits bajos del contador de cuadros
	and 003h		;473b
	jr nz,modo_1_la_pausa_si_no		;473d
	inc (hl)			;473f   ; con los dos a cero, arriba
	jr modo_1_la_pausa_si_no_2		;4740
modo_1_la_pausa_si_no:		; Dentro de modo_1_la_pausa
	cp 002h		;4742   ; y con el valor 2, abajo
	jr nz,modo_1_la_pausa_si_no_3		;4744
	dec (hl)			;4746
modo_1_la_pausa_si_no_2:		; Dentro de modo_1_la_pausa
	ld a,(de)			;4747
	inc a			;4748   ; una vuelta mas de la pausa
	ld (de),a			;4749
modo_1_la_pausa_si_no_3:		; Dentro de modo_1_la_pausa
	call borra_y_recoloca_al_oponente		;474a
modo_1_la_pausa_si_no_4:		; Dentro de modo_1_la_pausa
	ld hl,0e004h		;474d   ; el plazo
	dec (hl)			;4750
	ret nz			;4751
	xor a			;4752
	ld (de),a			;4753   ; el contador de la pausa, a cero
	xor a			;4754
	ld (0e1d0h),a		;4755
	call pon_el_otro_sprite		;4758
	ld a,020h		;475b
	ld (0e11bh),a		;475d   ; 0xE11b a 0x20
	call le_quita_energia_al_oponente		;4760
	call pone_a_cero_las_cuentas		;4763
	ld a,(0e117h)		;4766   ; con 0xE117 puesto se vuelve al modo 0
	and a			;4769
	jr z,modo_1_la_pausa_si_no_5		;476a
	xor a			;476c
	jp fija_el_modo		;476d
modo_1_la_pausa_si_no_5:		; Dentro de modo_1_la_pausa
	call esconde_los_tres_sprites		;4770
	ld a,04ch		;4773   ; A = 0x4c, la melodia
	call pon_la_melodia		;4775
	ld a,(0e185h)		;4778   ; la pose 0x0e o la 0x0f, segun 0xE185
	and a			;477b
	ld a,00eh		;477c
	jr nz,modo_1_la_pausa_si_no_6		;477e
	inc a			;4780
modo_1_la_pausa_si_no_6:		; Dentro de modo_1_la_pausa
	ld (0e184h),a		;4781
	call borra_y_recoloca_al_oponente		;4784
	ld a,030h		;4787   ; y plazo de 0x30
	jp pon_plazo_y_pasa_de_modo		;4789
modo_2_el_final_del_asalto:		; Con 0xE058 a cero se sale enseguida. Si no, y con el plazo por debajo de 0x60, mira 0xE275: valiendo 0x20 justo en el cuadro 0x5f del plazo, da el PERFECT
	call esconde_los_tres_sprites		;478c   ; rehace la figura
	call vuelca_los_sprites		;478f   ; y los atributos a la VRAM
	ld a,(0e058h)		;4792   ; con 0xE058 a cero no hay nada que hacer
	and a			;4795
	jr z,$+83		;4796
	ld a,(0e004h)		;4798   ; y el plazo tiene que haber bajado de 0x60
	cp 060h		;479b
	jr nc,$+62		;479d
	ld a,(0e275h)		;479f   ; 0xE275 valiendo 0x20...
	cp 020h		;47a2
	jr nz,modo_2_el_final_del_asalto_si_no		;47a4
	ld a,(0e004h)		;47a6   ; ...y el plazo justo en 0x5f
	cp 05fh		;47a9
	call z,da_el_perfect		;47ab
	jr $+59		;47ae
modo_2_el_final_del_asalto_si_no:		; Dentro de modo_2_el_final_del_asalto
	ld a,(0e004h)		;47b0   ; y si no, se espera al ultimo cuadro del plazo
	cp 001h		;47b3
	jr nz,$+52		;47b5
	ld (0e00bh),a		;47b7   ; (0xE00b) := 1
	ret			;47ba
da_el_perfect:		; El premio por acabar el asalto sin recibir un golpe: melodia 7, el rotulo PERFECT 3000 en la fila 16 y TRES MIL puntos a la cuenta. Los 0x3000 que se suman son BCD, que es como este cartucho lleva la puntuacion, asi que se leen 3000
	ld a,007h		;47bb   ; A = 7, la melodia del premio
	call pon_la_melodia		;47bd
	ld de,047cch		;47c0   ; DE = 0x47cc, la lista del rotulo
	call dibuja_la_lista		;47c3
	ld de,03000h		;47c6   ; DE = 0x3000 en BCD, o sea tres mil
	jp suma_a_la_puntuacion		;47c9   ; a la puntuacion

; ----------------------------------------------------------------------
; DATOS lista_de_perfect: PERFECT 3000 en la fila 16 columna 10: el aviso y
;   los puntos que da acabar el combate sin recibir un golpe. La dibuja 0x47c3
;   por la puerta normal -0x449e, que se lee los dos primeros bytes como
;   direccion- y 0x48ad por 0x449a, que se los salta y escribe donde ya apunte
;   HL
;   0x47cc..0x47db  (15 bytes)
DATA_lista_de_perfect:
	defb 00ah,03ah,030h,025h,032h,026h,025h,023h,034h,000h,013h,010h,010h,010h,0ffh	; 47cc  .:0%2&%#4......

; ======================================================================
; CODIGO 0x47db..0x4855  (122 bytes)
; ======================================================================


modo_3_la_caida:		; Le pasa el valor al motor de sonido -por 0x7baf hasta 0xA0 y por 0x7ba9 de 0xA0 a 0xC0- y espera a que se agote el plazo. Entonces borra 0xE125, deja 0xE160 en 0x87 y pone la melodia 0x8a
	cp 0a0h		;47db   ; por debajo de 0xA0...
	jr nc,modo_3_la_caida_si_no		;47dd
	call escribe_la_cuenta_de_golpes		;47df   ; ...un ruido...
	jr modo_3_la_caida_si_no_2		;47e2
modo_3_la_caida_si_no:		; Dentro de modo_3_la_caida
	cp 0c0h		;47e4   ; ...y entre 0xA0 y 0xC0, el otro
	call c,dibuja_number_of_hits		;47e6
modo_3_la_caida_si_no_2:		; Dentro de modo_3_la_caida
	ld hl,0e004h		;47e9   ; el plazo
	dec (hl)			;47ec
	ret nz			;47ed
	xor a			;47ee
	ld (0e125h),a		;47ef   ; 0xE125, a cero
	call esconde_el_chispazo		;47f2
	ld a,087h		;47f5   ; 0xE160 vuelve a 0x87
	ld (0e160h),a		;47f7
	ld a,08ah		;47fa   ; A = 0x8a, la melodia
	call pon_la_melodia		;47fc
	jp pasa_de_modo		;47ff
modo_4_la_ceremonia:		; Recorre la lista de 0x4855 a razon de una entrada cada once cuadros -0xE126 cuenta de 0x0a a 0- y cada valor es una pose, que se monta con 0x4fba y 0x4fbe. El 0xFF del final cierra el modo. Las entradas de 2 para arriba, y solo en el cuadro 9 de la cuenta, disparan ademas la melodia 1
	ld hl,0e126h		;4802   ; HL = 0xE126, la cuenta de once cuadros
	ld de,0e125h		;4805   ; DE = 0xE125, la posicion en la lista
	ld a,(hl)			;4808
	and a			;4809   ; llegando a cero...
	jr nz,modo_4_la_ceremonia_si_no		;480a
	ld a,(de)			;480c
	inc a			;480d   ; ...se avanza una entrada...
	ld (de),a			;480e
	ld (hl),00ah		;480f   ; ...y la cuenta vuelve a 0x0a
	jr modo_4_la_ceremonia_si_no_2		;4811
modo_4_la_ceremonia_si_no:		; Dentro de modo_4_la_ceremonia
	dec (hl)			;4813   ; y si no, un cuadro menos
modo_4_la_ceremonia_si_no_2:		; Dentro de modo_4_la_ceremonia
	ld hl,04855h		;4814   ; la lista de reacciones
	ld a,(de)			;4817   ; por la posicion de 0xE125
	call suma_a_hl		;4818
	ld a,(hl)			;481b
	push af			;481c
	cp 002h		;481d   ; los valores de 2 para arriba...
	jr c,modo_4_la_ceremonia_si_no_3		;481f
	ld a,(0e126h)		;4821   ; ...y solo en el cuadro 9...
	cp 009h		;4824
	ld a,001h		;4826
	call z,pon_la_melodia		;4828   ; ...llevan la melodia 1
modo_4_la_ceremonia_si_no_3:		; Dentro de modo_4_la_ceremonia
	pop af			;482b
	cp 0ffh		;482c   ; el 0xFF cierra la lista
	jr z,se_acabo_la_lista		;482e
	and 001h		;4830   ; el bit 0 del valor, a 0xE162
	ld (0e162h),a		;4832
	ld a,(hl)			;4835
	call fija_la_pose		;4836   ; el valor entero es la pose
	call monta_la_pose		;4839
	jp vuelca_los_sprites		;483c   ; y los atributos a la VRAM
se_acabo_la_lista:		; Con 0xE058 puesto sube uno y lo deja en 0xE00b; con 0xE058 a cero, copia 0xE116 a 0xE107 y se va al modo con plazo 0x1a
	ld a,(0e058h)		;483f   ; 0xE058 decide por donde sale
	and a			;4842
	jr z,se_acabo_la_lista_si_no		;4843
	inc a			;4845
	ld (0e00bh),a		;4846   ; (0xE00b) := 0xE058 + 1
	ret			;4849
se_acabo_la_lista_si_no:		; Dentro de se_acabo_la_lista
	ld a,(0e116h)		;484a   ; 0xE116 pasa a 0xE107
	ld (0e107h),a		;484d
	ld a,01ah		;4850   ; y plazo de 0x1a
	jp pon_plazo_y_pasa_de_modo		;4852

; ----------------------------------------------------------------------
; DATOS tabla_de_reacciones: Veintiun valores de 0x00 a 0x0e y un 0xFF de
;   cierre. 0x4814 la indexa por el byte que traiga DE y se queda con el
;   valor; si sale menor que 2 se va por 0x482b, y si no mira ademas 0xE126
;   contra 9
;   0x4855..0x486b  (22 bytes)
DATA_tabla_de_reacciones:
	defb 000h,000h,000h,000h,006h,000h,001h,007h,001h,000h,002h,000h,001h,003h,001h,000h	; 4855  ................
	defb 00eh,000h,000h,000h,000h,0ffh	; 4865

; ======================================================================
; CODIGO 0x486b..0x4920  (181 bytes)
; ======================================================================


modo_5_el_recuento:		; Coloca el sprite segun 0xE162 -0xE0 con el a cero y 0xC0 si no-, y cada ocho cuadros convierte una unidad de 0xE116 en DOSCIENTOS puntos, con la melodia 6 en cada una. Cuando 0xE116 se agota, mira si toca el premio grande
	ld a,(0e162h)		;486b   ; 0xE162 decide la altura
	and a			;486e
	ld a,0e0h		;486f   ; 0xE0 con el a cero...
	jr z,modo_5_el_recuento_si_no		;4871
	ld a,0c0h		;4873   ; ...y 0xC0 si no
modo_5_el_recuento_si_no:		; Dentro de modo_5_el_recuento
	ld (0e0cah),a		;4875   ; al campo Y del sprite
	call vuelca_los_sprites		;4878
	ld a,(0e003h)		;487b
	and 006h		;487e   ; uno de cada ocho cuadros
	ret nz			;4880
	ld hl,0e116h		;4881   ; HL = 0xE116, lo que queda por contar
	ld a,(hl)			;4884
	and a			;4885
	jr z,el_premio_de_los_cinco_mil		;4886
	ld a,001h		;4888
	ld (0e128h),a		;488a   ; el aviso de 0xE128
	dec (hl)			;488d   ; una unidad menos...
	ld de,00200h		;488e   ; ...que vale doscientos puntos en BCD
	call suma_a_la_puntuacion		;4891
	ld a,006h		;4894   ; y su melodia
	jp pon_la_melodia		;4896
el_premio_de_los_cinco_mil:		; Cuando ya no queda nada por contar y el plazo va justo por 0x15, con 0xE107 en 0x24 -el tope-, se dibuja el rotulo en la fila 4 y se le cambia el 3 por un 5: PERFECT 5000
	ld a,(0e004h)		;4899   ; el plazo, justo en 0x15
	cp 015h		;489c
	jr nz,y_a_esperar_el_plazo		;489e
	ld a,(0e107h)		;48a0   ; y 0xE107 en su tope, 0x24
	cp 024h		;48a3
	jr nz,y_a_esperar_el_plazo		;48a5
	ld hl,0388ah		;48a7   ; HL = VRAM 0x388a, fila 4 columna 10
	ld de,047ceh		;48aa   ; DE = 0x47ce, el texto SIN su direccion
	call dibuja_la_lista_sin_encadenar		;48ad   ; y por la puerta que no lee direccion
	ld a,015h		;48b0   ; A = 0x15, el digito 5...
	ld hl,03892h		;48b2   ; ...encima del 3 de la novena letra
	call 0004dh		;48b5   ; BIOS WRTVRM - Writes data in VRAM
	ld a,007h		;48b8   ; A = 7, la melodia del premio
	call pon_la_melodia		;48ba
	ld de,05000h		;48bd   ; y cinco mil puntos en BCD
	call suma_a_la_puntuacion		;48c0
y_a_esperar_el_plazo:		; Cuando se agota, (0xE00b) := 1
	ld hl,0e004h		;48c3   ; el plazo
	dec (hl)			;48c6
	ret nz			;48c7
	ld a,001h		;48c8
	ld (0e00bh),a		;48ca   ; y el aviso
	ret			;48cd
modo_6_el_zarandeo:		; Mueve 0xE161 un punto arriba y otro abajo segun el bit 0 del contador de cuadros, y rehace la figura. Al agotarse el plazo lo devuelve todo a su sitio
	ld hl,0e161h		;48ce   ; HL = 0xE161
	ld a,(0e003h)		;48d1   ; el bit 0 del contador de cuadros
	rra			;48d4
	inc (hl)			;48d5   ; sube uno...
	jr nc,modo_6_el_zarandeo_si_no		;48d6
	dec (hl)			;48d8   ; ...o baja uno, que son dos `dec` tras el `inc`
	dec (hl)			;48d9
modo_6_el_zarandeo_si_no:		; Dentro de modo_6_el_zarandeo
	call monta_la_pose		;48da
	call vuelca_los_sprites		;48dd
	ld hl,0e004h		;48e0   ; el plazo
	dec (hl)			;48e3
	ret nz			;48e4
	ld a,087h		;48e5   ; 0xE160 vuelve a 0x87
	ld (0e160h),a		;48e7
	xor a			;48ea
	ld (0e163h),a		;48eb   ; y tres banderines a cero
	ld (0e152h),a		;48ee
	ld (0e1d0h),a		;48f1
	call esconde_el_chispazo		;48f4
	ld a,(0e058h)		;48f7   ; con 0xE058 puesto no se sigue
	and a			;48fa
	jr nz,$+71		;48fb
repone_los_sprites:		; Con 0xE116 sin agotar, coge 0xE11c menos uno, saca de la tabla de 0x4920 el campo de PATRON del sprite que toque y lo escribe con 0x49f9
	call le_quita_energia_al_jugador		;48fd   ; la pantalla
	call pone_a_cero_las_cuentas		;4900
	ld a,(0e116h)		;4903   ; con 0xE116 a cero no hay nada
	and a			;4906
	jr z,$+59		;4907
	ld a,(0e11ch)		;4909   ; 0xE11c dice cual de los tres
	push af			;490c
	dec a			;490d
	ld hl,04920h		;490e   ; la tabla de los tres punteros a la RAM
	call indexa_una_tabla_de_punteros		;4911
	ex de,hl			;4914
	pop af			;4915
	call marca_el_sprite		;4916
	xor a			;4919
	ld (0e111h),a		;491a   ; 0xE111, a cero
	jp fija_el_modo		;491d

; ----------------------------------------------------------------------
; DATOS tabla_de_los_tres_patrones: Tres punteros, y no a la ROM sino a la
;   RAM: 0xE0b1, 0xE0b5 y 0xE0b9. Son los bytes de PATRON de los sprites 0, 1
;   y 2 dentro de la tabla de atributos que el juego monta en 0xE0b0. 0x4911
;   los indexa con el despachador de tablas de siempre
;   0x4920..0x4926  (6 bytes)
DATA_tabla_de_los_tres_patrones:
	defw 0e0b1h,0e0b5h,0e0b9h	; 4920

; ======================================================================
; CODIGO 0x4926..0x4aac  (390 bytes)
; ======================================================================


vuelve_al_estado_de_reposo:		; Melodia 0x4c, 0xE160 a 0x87, 0xE162 a cero y la pose 0x14 montada y volcada
	ld a,04ch		;4926   ; A = 0x4c, la melodia
	call pon_la_melodia		;4928
	call esconde_los_tres_sprites		;492b
	ld a,087h		;492e
	ld (0e160h),a		;4930   ; 0xE160 a 0x87, el reposo
	xor a			;4933
	ld (0e162h),a		;4934
	ld a,014h		;4937   ; A = 0x14, la pose de reposo
	call fija_la_pose		;4939
	call monta_la_pose		;493c   ; montada...
	jp vuelca_los_sprites		;493f   ; ...y a la VRAM
arranca_el_asalto:		; Lo de arriba y, con 0xE058 a cero, la pose 2 o la 3 segun 0xE185, la pantalla rehecha y un plazo de 0x70. Con 0xE058 puesto, el plazo es 0xE0
	call vuelve_al_estado_de_reposo		;4942   ; el reposo
	ld a,(0e058h)		;4945   ; 0xE058 decide
	and a			;4948
	ld a,0e0h		;4949   ; A = 0xE0, el plazo largo
	jr nz,arranca_el_asalto_si_no_2		;494b
	ld a,(0e185h)		;494d   ; 0xE185 elige entre la pose 2...
	and a			;4950
	ld a,002h		;4951
	jr nz,arranca_el_asalto_si_no		;4953
	inc a			;4955   ; ...y la 3
arranca_el_asalto_si_no:		; Dentro de arranca_el_asalto
	ld (0e184h),a		;4956
	call borra_y_recoloca_al_oponente		;4959
	ld a,070h		;495c   ; y el plazo corto, 0x70
arranca_el_asalto_si_no_2:		; Dentro de arranca_el_asalto
	jp pon_plazo_y_pasa_de_modo		;495e
modo_7_el_final:		; Con el plazo por debajo de 0x60 alterna dos parejas de patrones -0xbc y 0xc8- cada ocho cuadros
	ld a,(0e004h)		;4961   ; el plazo
	cp 060h		;4964   ; de 0x60 para arriba, todavia no
	jr nc,el_ruido_de_la_caida		;4966
	ld a,(0e003h)		;4968   ; el contador de cuadros
	bit 3,a		;496b   ; su bit 3: cada ocho
	jr z,suena_y_monta_la_pose_de_reposo		;496d
	ld hl,0e0c6h		;496f   ; HL = 0xE0c6, el patron de un sprite
	ld de,0e0cah		;4972   ; DE = 0xE0ca, el de otro
	ld a,0bch		;4975   ; patron 0xbc...
	ld (hl),a			;4977
	ld a,0c8h		;4978   ; ...y 0xc8
	ld (de),a			;497a
	jr y_a_la_vram		;497b
suena_y_monta_la_pose_de_reposo:		; Con los cuatro bits bajos a cero, la melodia 4; luego la pose 0x14, montada y volcada
	and 00fh		;497d   ; los cuatro bits bajos
	ld a,004h		;497f   ; A = 4, la melodia
	call z,pon_la_melodia		;4981
	ld a,014h		;4984   ; A = 0x14, la pose de reposo
	call fija_la_pose		;4986
	call monta_la_pose		;4989
y_a_la_vram:		; Los 0x80 bytes de atributos
	call vuelca_los_sprites		;498c   ; volcados
el_ruido_de_la_caida:		; Con 0xE058 puesto, el plazo elige el ruido: por encima de 0x80 el de 0x7baf y entre 0x80 y 0xB0 el de 0x7ba9. Al agotarse el plazo, o avisa por 0xE00b o pone 0xE053 a cero
	ld a,(0e058h)		;498f   ; con 0xE058 a cero no hay ruido
	and a			;4992
	jr z,el_ruido_de_la_caida_por_aqui		;4993
	ld a,(0e004h)		;4995   ; el plazo manda
	cp 080h		;4998
	jr nc,el_ruido_de_la_caida_si_no		;499a
	call escribe_la_cuenta_de_golpes		;499c   ; por encima de 0x80, un ruido...
	jr el_ruido_de_la_caida_por_aqui		;499f
el_ruido_de_la_caida_si_no:		; Dentro de el_ruido_de_la_caida
	cp 0b0h		;49a1   ; ...y entre 0x80 y 0xB0, el otro
	jr nc,el_ruido_de_la_caida_por_aqui		;49a3
	call dibuja_number_of_hits		;49a5
el_ruido_de_la_caida_por_aqui:		; Dentro de el_ruido_de_la_caida
	ld hl,0e004h		;49a8   ; el plazo
	dec (hl)			;49ab
	ret nz			;49ac
	ld a,(0e058h)		;49ad
	and a			;49b0
	jr z,el_ruido_de_la_caida_si_no_2		;49b1
	ld a,001h		;49b3
	ld (0e00bh),a		;49b5   ; (0xE00b) := 1
	ret			;49b8
el_ruido_de_la_caida_si_no_2:		; Dentro de el_ruido_de_la_caida
	ld (0e053h),a		;49b9   ; o 0xE053 a cero, que es lo que cierra la partida
	ret			;49bc
pone_a_cero_las_cuentas:		; 0xE1c3 a cero, y 0xE150 y 0xE16b a uno
	xor a			;49bd   ; 0xE1c3, a cero
	ld (0e1c3h),a		;49be
	inc a			;49c1
	ld (0e150h),a		;49c2   ; y los otros dos, a uno
	ld (0e16bh),a		;49c5
	ret			;49c8
esconde_los_tres_sprites:		; Los tres primeros sprites de 0xE0b0 a Y = 0xE0, o sea fuera de pantalla, y de paso borra cinco bytes en 0xE190 y otros cinco en 0xE186
	ld b,003h		;49c9   ; tres sprites
	ld hl,0e0b0h		;49cb   ; HL = 0xE0b0, la tabla de atributos en RAM
	xor a			;49ce
esconde_los_tres_sprites_otra_vuelta:		; Dentro de esconde_los_tres_sprites
	ld (hl),0e0h		;49cf   ; Y = 0xE0: fuera de la pantalla
	inc hl			;49d1
	ld (hl),a			;49d2   ; y el patron, a cero
	inc hl			;49d3
	inc hl			;49d4   ; los otros dos bytes del sprite, sin tocar
	inc hl			;49d5
	djnz esconde_los_tres_sprites_otra_vuelta		;49d6
	ld hl,0e190h		;49d8   ; cinco bytes de 0xE190...
	ld de,0e186h		;49db   ; ...y cinco de 0xE186, todos a cero
	ld b,005h		;49de
borra_las_dos_ternas:		; Cinco bytes en cada una
	ld (hl),a			;49e0   ; uno de aqui...
	ld (de),a			;49e1   ; ...y otro de alla
	inc hl			;49e2
	inc de			;49e3
	djnz borra_las_dos_ternas		;49e4
	ret			;49e6
fija_el_modo:		; Deja A en 0xE110, que es lo que reparte 0x4604
	ld (0e110h),a		;49e7   ; el modo, puesto
	ret			;49ea
pon_plazo_y_pasa_de_modo:		; Deja A de plazo en 0xE004 y sube 0xE110 al modo siguiente
	ld (0e004h),a		;49eb   ; el plazo
pasa_de_modo:		; La otra entrada, sin tocar el plazo
	ld hl,0e110h		;49ee   ; HL = 0xE110, el modo
	inc (hl)			;49f1   ; uno mas
	ret			;49f2
marca_el_golpe_recibido:		; B = 4 y C = 0x10, y a repartirlos por 0x49fd
	ld b,004h		;49f3   ; B = 4, lo que se escribe
	ld c,010h		;49f5   ; C = 0x10, lo que va a 0xE127
	jr escribe_en_la_terna		;49f7
marca_el_sprite:		; Lo mismo con B = 2 y C = 0
	ld b,002h		;49f9   ; B = 2
	ld c,000h		;49fb   ; y C = 0, o sea 0xE127 se queda a cero
escribe_en_la_terna:		; Segun A valga 1, 2 o mas, escribe B en 0xE190, en 0xE191 o en 0xE192, y deja C en 0xE127
	ld de,0e190h		;49fd   ; DE = 0xE190, el primero de la terna
	dec a			;4a00   ; A = 1 se queda aqui...
	jr z,escribe_en_la_terna_si_no_2		;4a01
	dec a			;4a03   ; ...A = 2 avanza uno...
	jr z,escribe_en_la_terna_si_no		;4a04
	inc de			;4a06   ; ...y el resto, dos
escribe_en_la_terna_si_no:		; Dentro de escribe_en_la_terna
	inc de			;4a07
escribe_en_la_terna_si_no_2:		; Dentro de escribe_en_la_terna
	ld a,b			;4a08
	ld (de),a			;4a09   ; B, escrito
	ld a,c			;4a0a
	ld (0e127h),a		;4a0b   ; y C a 0xE127
	ret			;4a0e
mira_si_el_golpe_da:		; Decide si el golpe del jugador alcanza al oponente comparando la X del golpe, 0xE171, contra las cajas de 0xE198. Antes hay tres cortes: el bit de 0xE173 que corresponde a la pose de 0xE172, que la pose del oponente (0xE184) no sea de 0x0e para arriba, y que 0xE160 haya llegado a 0x72
	ld a,(0e172h)		;4a0f   ; la pose del jugador manda
	ld b,a			;4a12
	ld c,a			;4a13
	ld a,(0e173h)		;4a14   ; y 0xE173 trae un bit por pose
mira_si_el_golpe_da_otra_vuelta:		; Dentro de mira_si_el_golpe_da
	srl a		;4a17   ; se baja el bit que toca al acarreo
	djnz mira_si_el_golpe_da_otra_vuelta		;4a19
	jr c,cae_dentro_del_tramo_por_aqui		;4a1b   ; puesto: no hay golpe
	ld a,(0e184h)		;4a1d   ; la pose del oponente
	and 00fh		;4a20
	cp 00eh		;4a22   ; de 0x0e para arriba, tampoco
	jr nc,cae_dentro_del_tramo_por_aqui		;4a24
	ld a,(0e160h)		;4a26   ; y la Y del jugador tiene que llegar a 0x72
	cp 072h		;4a29
	jr c,cae_dentro_del_tramo_por_aqui		;4a2b
	ld hl,0e198h		;4a2d   ; HL = 0xE198, la primera caja horizontal
	dec c			;4a30   ; la pose 1 usa esa...
	jr z,mira_si_el_golpe_da_si_no_2		;4a31
	dec c			;4a33   ; ...la 2 la de dos mas alla...
	jr z,mira_si_el_golpe_da_si_no		;4a34
	ld hl,0e19ch		;4a36   ; ...y el resto prueba DOS cajas seguidas
	ld b,(hl)			;4a39
	inc hl			;4a3a
	ld c,(hl)			;4a3b
	call cae_dentro_del_tramo		;4a3c   ; la primera, y si acierta ya esta
	ret nz			;4a3f
	inc hl			;4a40
	ld b,(hl)			;4a41
	inc hl			;4a42
	ld c,(hl)			;4a43
	jr cae_dentro_del_tramo		;4a44
mira_si_el_golpe_da_si_no:		; Dentro de mira_si_el_golpe_da
	inc hl			;4a46
	inc hl			;4a47
mira_si_el_golpe_da_si_no_2:		; Dentro de mira_si_el_golpe_da
	ld b,(hl)			;4a48
	inc hl			;4a49
	ld c,(hl)			;4a4a
cae_dentro_del_tramo:		; La X del golpe es 0xE171; con ella a cero no hay golpe, y si no tiene que caer entre B y C, los dos extremos de la caja
	ld a,(0e171h)		;4a4b   ; la X del golpe
	and a			;4a4e
	ret z			;4a4f   ; a cero no hay golpe
	cp b			;4a50   ; por debajo del principio, no
	jr c,cae_dentro_del_tramo_si_no		;4a51
	cp c			;4a53   ; por encima del final, tampoco
	jr nc,cae_dentro_del_tramo_si_no_2		;4a54
	or 001h		;4a56   ; y en medio: golpe
	ret			;4a58
cae_dentro_del_tramo_si_no:		; Dentro de cae_dentro_del_tramo
	ld a,001h		;4a59
	jr cae_dentro_del_tramo_si_no_3		;4a5b
cae_dentro_del_tramo_si_no_2:		; Dentro de cae_dentro_del_tramo
	xor a			;4a5d
cae_dentro_del_tramo_si_no_3:		; Dentro de cae_dentro_del_tramo
	ld (0e114h),a		;4a5e
cae_dentro_del_tramo_por_aqui:		; Dentro de cae_dentro_del_tramo
	xor a			;4a61
	ret			;4a62
mira_si_le_dan_al_jugador_de_verdad:		; Coge 0xE1b0 y 0xE1b1 y pasa a 0x4a6a
	ld a,(0e1b1h)		;4a63   ; B = 0xE1b1
	ld b,a			;4a66
	ld a,(0e1b0h)		;4a67   ; y A = 0xE1b0
comprueba_el_alcance:		; Con C a cero, o con 0xE1b2 a cero, no hay nada. Si no, el bit de 0xE174 que toca a la pose corta la comprobacion, y para las tres primeras poses hace falta ademas que 0xE160 pase del umbral de 0x4aac. Al final compara C contra un tramo de diez o doce
	ld c,a			;4a6a   ; C se queda con el valor
	ld hl,0e1b2h		;4a6b   ; HL = 0xE1b2, la terna de posiciones
	and a			;4a6e
	ret z			;4a6f   ; con C a cero, nada
	ld a,(hl)			;4a70
	and a			;4a71
	ret z			;4a72   ; y con la posicion a cero, tampoco
	push bc			;4a73
	ld a,(0e174h)		;4a74   ; 0xE174 trae un bit por pose
comprueba_el_alcance_otra_vuelta:		; Dentro de comprueba_el_alcance
	srl a		;4a77   ; se baja el que toca al acarreo
	djnz comprueba_el_alcance_otra_vuelta		;4a79
	pop bc			;4a7b
	jr c,no_hay_contacto		;4a7c   ; puesto: no hay contacto
	ld a,b			;4a7e
	dec a			;4a7f
	cp 003h		;4a80   ; solo las tres primeras miran el umbral
	jr nc,comprueba_el_alcance_si_no		;4a82
	ld de,04aach		;4a84   ; la tabla de los tres umbrales
	call suma_a_de		;4a87
	ld a,(0e160h)		;4a8a   ; contra 0xE160
	ex de,hl			;4a8d
	cp (hl)			;4a8e
	ex de,hl			;4a8f
	jr c,no_hay_contacto		;4a90   ; por debajo, no llega
comprueba_el_alcance_si_no:		; Dentro de comprueba_el_alcance
	ld a,b			;4a92
	ld b,00ah		;4a93   ; anchura 10 para la primera...
	dec a			;4a95
	jr z,comprueba_el_alcance_si_no_3		;4a96
	dec a			;4a98
	jr z,comprueba_el_alcance_si_no_2		;4a99
	inc hl			;4a9b
comprueba_el_alcance_si_no_2:		; Dentro de comprueba_el_alcance
	inc hl			;4a9c
	ld b,00ch		;4a9d   ; ...y 12 para la tercera
comprueba_el_alcance_si_no_3:		; Dentro de comprueba_el_alcance
	ld a,(hl)			;4a9f
	cp c			;4aa0   ; por debajo del principio, no
	jr nc,no_hay_contacto		;4aa1
	add a,b			;4aa3
	cp c			;4aa4   ; por encima del final, tampoco
	jr c,no_hay_contacto		;4aa5
	or 001h		;4aa7   ; y en medio: contacto
	ret			;4aa9
no_hay_contacto:		; A a cero y fuera
	xor a			;4aaa   ; que no
	ret			;4aab

; ----------------------------------------------------------------------
; DATOS tres_umbrales: Tres bytes, 0x86, 0x7c y 0x73, que 0x4a84 indexa y
;   compara con 0xE160
;   0x4aac..0x4aaf  (3 bytes)
DATA_tres_umbrales:
	defb 086h,07ch,073h	; 4aac

; ======================================================================
; CODIGO 0x4aaf..0x4b23  (116 bytes)
; ======================================================================


elige_el_arma_por_la_altura:		; La Y del jugador, 0xE160, dice cual de los tres sprites entra: de 0x86 para arriba el tercero, de 0x7c el segundo y de 0x73 el primero. Cada uno se prueba y, si no acierta, se cae al siguiente. Como en el TMS9918 la Y crece hacia abajo, 0x86 es el mas BAJO de los tres
	ld a,(0e160h)		;4aaf   ; la Y del jugador
	cp 086h		;4ab2   ; de 0x86 para abajo, el tercero
	jr nc,elige_el_arma_por_la_altura_si_no		;4ab4
	cp 07ch		;4ab6   ; de 0x7c, el segundo
	jr nc,elige_el_arma_por_la_altura_si_no_2		;4ab8
	cp 073h		;4aba   ; y por debajo de 0x73, ninguno
	jr c,ninguno_alcanza		;4abc
	jr elige_el_arma_por_la_altura_si_no_3		;4abe
elige_el_arma_por_la_altura_si_no:		; Dentro de elige_el_arma_por_la_altura
	ld b,003h		;4ac0
	ld hl,0e0b9h		;4ac2   ; HL = 0xE0b9, el tercer sprite
	call prueba_este_sprite		;4ac5
	ret nz			;4ac8
elige_el_arma_por_la_altura_si_no_2:		; Dentro de elige_el_arma_por_la_altura
	ld b,002h		;4ac9
	ld hl,0e0b5h		;4acb   ; HL = 0xE0b5, el segundo
	call prueba_este_sprite		;4ace
	ret nz			;4ad1
elige_el_arma_por_la_altura_si_no_3:		; Dentro de elige_el_arma_por_la_altura
	ld b,001h		;4ad2
	ld hl,0e0b1h		;4ad4   ; HL = 0xE0b1, el primero
prueba_este_sprite:		; Apunta en 0xE11c cual se esta probando, le suma 8 al alcance si el oponente es el 1 y 4 si no, y va a comprobarlo
	ld a,b			;4ad7
	ld (0e11ch),a		;4ad8   ; cual se esta probando
	ld a,(0e054h)		;4adb   ; el oponente de turno
	dec a			;4ade
	ld c,008h		;4adf   ; el oponente 1 alcanza ocho...
	jr z,prueba_este_sprite_si_no		;4ae1
	ld c,004h		;4ae3   ; ...y los demas, cuatro
prueba_este_sprite_si_no:		; Dentro de prueba_este_sprite
	ld a,(hl)			;4ae5
	add a,c			;4ae6   ; la posicion del sprite mas el alcance
	jp comprueba_el_alcance		;4ae7
ninguno_alcanza:		; A a cero
	xor a			;4aea   ; que no
	ret			;4aeb
mira_si_el_golpe_toca_al_arma:		; La pose del jugador (0xE172) elige uno de los tres sprites -la 1 el primero, la 4 el segundo, la 5 el tercero- y comprueba si su posicion cae en un tramo de quince
	ld hl,0e0b1h		;4aec   ; HL = 0xE0b1, el primer sprite
	ld a,(0e172h)		;4aef   ; la pose del jugador
	dec a			;4af2
	jr z,mira_si_el_golpe_toca_al_arma_por_aqui		;4af3   ; la pose 1 usa el primero
	dec a			;4af5
	cp 002h		;4af6
	jr nz,mira_si_el_golpe_toca_al_arma_si_no		;4af8
	ld hl,0e0b5h		;4afa   ; la 4 usa el segundo
	jr mira_si_el_golpe_toca_al_arma_por_aqui		;4afd
mira_si_el_golpe_toca_al_arma_si_no:		; Dentro de mira_si_el_golpe_toca_al_arma
	dec a			;4aff
	jr nz,ninguno_alcanza		;4b00
	ld hl,0e0b9h		;4b02   ; y la 5, el tercero
mira_si_el_golpe_toca_al_arma_por_aqui:		; Dentro de mira_si_el_golpe_toca_al_arma
	ld a,(hl)			;4b05
	and a			;4b06   ; con el sprite fuera, no hay nada
	ret z			;4b07
	ld b,a			;4b08
	add a,00fh		;4b09   ; un tramo de quince a partir de ahi
	ld c,a			;4b0b
	jp cae_dentro_del_tramo		;4b0c
apunta_los_puntos_del_golpe:		; Con 0xE115 puesto, saca de la tabla de 0x4b23 lo que vale ese golpe y lo suma a la puntuacion. Los cinco valores son 100, 300, 300, 500 y 500, leidos en BCD
	ld hl,0e115h		;4b0f   ; HL = 0xE115, que golpe ha sido
	ld a,(hl)			;4b12
	and a			;4b13
	ret z			;4b14   ; a cero, no hay nada que apuntar
	push hl			;4b15
	dec a			;4b16
	ld hl,04b23h		;4b17   ; la tabla de los cinco valores
	call indexa_una_tabla_de_punteros		;4b1a
	pop hl			;4b1d
	xor a			;4b1e
	ld (hl),a			;4b1f   ; y el aviso, borrado
	jp suma_a_la_puntuacion		;4b20   ; a la cuenta

; ----------------------------------------------------------------------
; DATOS puntos_por_golpe: Cinco palabras -0x0100, 0x0300, 0x0300, 0x0500 y
;   0x0500- que 0x4b1a indexa y 0x4b20 le pasa a suma_a_la_puntuacion. Leidas
;   como BCD, que es como este cartucho lleva la puntuacion, son CIEN,
;   TRESCIENTOS, TRESCIENTOS, QUINIENTOS y QUINIENTOS puntos
;   0x4b23..0x4b2d  (10 bytes)
DATA_puntos_por_golpe:
	defw 00100h,00300h,00300h,00500h,00500h	; 4b23

; ======================================================================
; CODIGO 0x4b2d..0x4b4f  (34 bytes)
; ======================================================================


pon_el_chispazo:		; Coloca el cuarto sprite donde ha caido el golpe: la X es 0xE171 menos siete, la Y sale de la tabla de 0x4b54 segun la pose del jugador -0x84 alto, 0x91 medio y 0x9f bajo-, el color es 0xF0 y el patron lo da 0x4b4f por oponente
	call esconde_los_tres_sprites		;4b2d   ; los tres primeros, escondidos
	ld a,(0e171h)		;4b30   ; la X del golpe...
	sub 007h		;4b33   ; ...siete pixeles a la izquierda
	ld b,a			;4b35
	ld a,(0e054h)		;4b36   ; el oponente elige el patron
	ld hl,04b4fh		;4b39
	call suma_a_hl		;4b3c
	ld e,(hl)			;4b3f
	ld a,(0e172h)		;4b40   ; y la pose del jugador, la altura
pon_el_chispazo_si_no:		; Dentro de pon_el_chispazo
	dec a			;4b43
	ld hl,04b54h		;4b44   ; la tabla de las tres alturas
	call suma_a_hl		;4b47
	ld a,(hl)			;4b4a
	ld d,0f0h		;4b4b   ; color 0xF0
	jr $+35		;4b4d

; ----------------------------------------------------------------------
; DATOS cinco_alturas: Cinco bytes, 06 06 06 0F 0F, que 0x4b3c indexa y deja
;   en E
;   0x4b4f..0x4b54  (5 bytes)
DATA_cinco_alturas:
	defb 006h,006h,006h,00fh,00fh	; 4b4f

; ----------------------------------------------------------------------
; DATOS tres_patrones: Tres bytes, 0x84, 0x91 y 0x9f, que 0x4b44 indexa por
;   (0xE172) menos uno y deja en A, con D a 0xF0
;   0x4b54..0x4b57  (3 bytes)
DATA_tres_patrones:
	defb 084h,091h,09fh	; 4b54

; ======================================================================
; CODIGO 0x4b57..0x4b7d  (38 bytes)
; ======================================================================


esconde_el_chispazo:		; Y = 0xE0, o sea fuera de pantalla, y X = 0
	ld b,000h		;4b57   ; X = 0
	ld a,0e0h		;4b59   ; Y = 0xE0: fuera
	jr escribe_el_cuarto_sprite		;4b5b
pon_el_otro_sprite:		; El mismo cuarto sprite, pero en Y = 0x78, con la X de 0xE16e, color blanco y el patron que la tabla de 0x4b7d da para 0xE11d
	ld a,(0e16eh)		;4b5d   ; la X, de 0xE16e
	ld b,a			;4b60
	ld a,(0e11dh)		;4b61   ; 0xE11d elige el patron
	dec a			;4b64
	ld hl,04b7dh		;4b65   ; la tabla de los cinco
	call suma_a_hl		;4b68
	ld d,(hl)			;4b6b
	ld e,00fh		;4b6c   ; color 0x0f, blanco
	ld a,078h		;4b6e   ; y Y = 0x78
escribe_el_cuarto_sprite:		; Los cuatro bytes de 0xE0c0 -Y, X, patron y color- y los 0x80 de la tabla a la VRAM
	ld hl,0e0c0h		;4b70   ; HL = 0xE0c0, el cuarto sprite
	ld (hl),a			;4b73   ; la Y
	inc hl			;4b74
	ld (hl),b			;4b75   ; la X
	inc hl			;4b76
	ld (hl),d			;4b77   ; el patron
	inc hl			;4b78
	ld (hl),e			;4b79   ; y el color
	jp vuelca_los_sprites		;4b7a   ; y todo a la VRAM

; ----------------------------------------------------------------------
; DATOS cinco_alturas_mas: Cinco bytes, F4 F8 F8 FC FC, que 0x4b65 indexa y
;   deja en D, con E a 0x0f y A a 0x78
;   0x4b7d..0x4b82  (5 bytes)
DATA_cinco_alturas_mas:
	defb 0f4h,0f8h,0f8h,0fch,0fch	; 4b7d

; ======================================================================
; CODIGO 0x4b82..0x4b9c  (26 bytes)
; ======================================================================


escribe_el_cuarto_sprite_si_no:		; Dentro de escribe_el_cuarto_sprite
	call esconde_los_tres_sprites		;4b82
	ld a,(0e1b0h)		;4b85
escribe_el_cuarto_sprite_si_no_2:		; Dentro de escribe_el_cuarto_sprite
	sub 007h		;4b88
	ld b,a			;4b8a
	ld e,00dh		;4b8b
	ld a,(0e1b1h)		;4b8d
	jr $-77		;4b90
escribe_el_cuarto_sprite_por_aqui:		; Dentro de escribe_el_cuarto_sprite
	call no_hace_nada		;4b92
	call borra_y_esconde_todos_los_sprites		;4b95
	call arranca_un_asalto		;4b98
	ret			;4b9b

; ----------------------------------------------------------------------
; DATOS tabla_de_oponentes_patrones: Los cinco punteros a los guiones de
;   PATRON de la figura del oponente, indexados por 0xE054 desde 0x4be5:
;   0x5eeb, 0x624b, 0x64bd, 0x6724 y 0x68ff. En el mismo orden que los nombres
;   de 0x6c35: WANG, TAO, CHEN, LANG y WU
;   0x4b9c..0x4ba6  (10 bytes)
DATA_tabla_de_oponentes_patrones:
	defw 05eebh,0624bh,064bdh,06724h,068ffh	; 4b9c

; ----------------------------------------------------------------------
; DATOS tabla_de_oponentes_colores: Los cinco de COLOR de la misma figura, en
;   el mismo orden: 0x6172, 0x6421, 0x669b, 0x68a2 y 0x6a9c. Los usa 0x4bf2
;   con el mismo indice, y los dibuja dos veces, en 0x0880 y en 0x0c40
;   0x4ba6..0x4bb0  (10 bytes)
DATA_tabla_de_oponentes_colores:
	defw 06172h,06421h,0669bh,068a2h,06a9ch	; 4ba6

; ----------------------------------------------------------------------
; DATOS tabla_de_remates: Tres punteros a los guiones cortos de aqui al lado,
;   indexados desde 0x4c2a por 0xE059 menos uno
;   0x4bb0..0x4bb6  (6 bytes)
DATA_tabla_de_remates:
	defw 04bb6h,04bc2h,04bceh	; 4bb0  -> DATA_tres_guiones_cortos 0x4bc2 0x4bce

; ----------------------------------------------------------------------
; DATOS tres_guiones_cortos: Los tres guiones de doce bytes que despacha la
;   tabla de arriba, uno detras de otro: 0x4bb6, 0x4bc2 y 0x4bce. Doce bytes
;   clavados los tres
;   0x4bb6..0x4bda  (36 bytes)
DATA_tres_guiones_cortos:
	defb 010h,04fh,088h,070h,050h,040h,000h,070h,050h,040h,000h,000h	; 4bb6  .O.pP@.pP@..
	defb 010h,0cfh,088h,030h,020h,0c0h,000h,030h,020h,0c0h,000h,000h	; 4bc2  ...0 ..0 ...
	defb 010h,0efh,088h,0f0h,0e0h,0e0h,000h,0f0h,0e0h,0e0h,000h,000h	; 4bce  ............

; ======================================================================
; CODIGO 0x4bda..0x4cd2  (248 bytes)
; ======================================================================


monta_la_pantalla_de_combate:		; Con 0xE058 puesto se salta al oponente y solo dibuja el fondo. Si no, saca de las tablas de 0x4b9c y 0x4ba6 los guiones del oponente de 0xE054 y los dibuja: el patron en la VRAM 0x2880 y el color en la 0x0880 y otra vez en la 0x0c40, los tres en dos tercios
	ld a,(0e058h)		;4bda   ; con 0xE058 puesto, solo el fondo
	and a			;4bdd
	jp nz,dibuja_el_fondo		;4bde
	ld a,(0e054h)		;4be1   ; el oponente de turno
	push af			;4be4
	ld hl,04b9ch		;4be5   ; la tabla de patrones
	call indexa_una_tabla_de_punteros		;4be8
	ld hl,02880h		;4beb   ; a la VRAM 0x2880, tiles 0x10 en adelante
	call dibuja_en_dos_tercios		;4bee
	pop af			;4bf1
	ld hl,04ba6h		;4bf2   ; y la de colores
	call indexa_una_tabla_de_punteros		;4bf5
	push de			;4bf8
	ld hl,00880h		;4bf9   ; a la VRAM 0x0880...
	call dibuja_en_dos_tercios		;4bfc
	pop de			;4bff
	ld hl,00c40h		;4c00   ; ...y a la 0x0c40
	call dibuja_en_dos_tercios		;4c03
dibuja_el_fondo:		; El templo, comun a los cinco: el patron de 0x605b en la VRAM 0x22f0 y el color de 0x6207 en la 0x02f0 y en la 0x06b0, los tres en los TRES tercios. Y con 0xE059 puesto, uno de los tres guiones cortos de 0x4bb0 encima
	ld hl,022f0h		;4c06   ; HL = VRAM 0x22f0, tiles 0x5e en adelante
	ld de,0605bh		;4c09   ; DE = 0x605b, el patron del templo
	call dibuja_en_los_tres_tercios		;4c0c
	ld hl,002f0h		;4c0f   ; HL = VRAM 0x02f0, su color
	ld de,06207h		;4c12
	push de			;4c15
	push hl			;4c16
	call dibuja_en_los_tres_tercios		;4c17
	pop hl			;4c1a
	ld de,003c0h		;4c1b   ; 0x3c0 mas alla: la VRAM 0x06b0
	add hl,de			;4c1e
	pop de			;4c1f
	call dibuja_en_los_tres_tercios		;4c20
	ld a,(0e059h)		;4c23   ; 0xE059 decide si hay remate
	and a			;4c26
	jr z,espeja_los_tiles_del_oponente		;4c27
	dec a			;4c29
	ld hl,04bb0h		;4c2a   ; la tabla de los tres guiones cortos
	call indexa_una_tabla_de_punteros		;4c2d
	push de			;4c30
	ld hl,00428h		;4c31   ; a la VRAM 0x0428...
	call dibuja_en_los_tres_tercios		;4c34
	pop de			;4c37
	ld hl,007e8h		;4c38   ; ...y a la 0x07e8
	call dibuja_en_los_tres_tercios		;4c3b
espeja_los_tiles_del_oponente:		; Copia 0x3c0 bytes de la VRAM 0x2880 a la 0x2440, dando la vuelta a cada byte, y repite el mismo origen en la 0x2c40 y en la 0x3440. El destino, 0x2440, es el tile 0x88: exactamente 0x78 mas alla del 0x10 de donde se copia
	ld hl,02880h		;4c3e   ; HL = VRAM 0x2880, el tile 0x10
	ld de,02440h		;4c41   ; DE = VRAM 0x2440, el tile 0x88
	ld b,003h		;4c44   ; tres tercios
espeja_un_tercio:		; 0x3c0 bytes leidos con RDVRM, del reves, y escritos con WRTVRM. El ORIGEN no avanza entre tercios: solo el destino
	push bc			;4c46
	push hl			;4c47
	push de			;4c48
	ld bc,003c0h		;4c49   ; 0x3c0 bytes, o sea 120 tiles
espeja_un_tercio_otra_vuelta:		; Dentro de espeja_un_tercio
	call 0004ah		;4c4c   ; BIOS RDVRM - Reads the content of VRAM | leidos de la VRAM...
	call da_la_vuelta_al_byte		;4c4f   ; ...del reves...
	ex de,hl			;4c52
	call 0004dh		;4c53   ; BIOS WRTVRM - Writes data in VRAM | ...y escritos en el otro sitio
	ex de,hl			;4c56
	inc hl			;4c57
	inc de			;4c58
	dec bc			;4c59
	ld a,b			;4c5a
	or c			;4c5b
	jr nz,espeja_un_tercio_otra_vuelta		;4c5c
	pop de			;4c5e
	ld hl,00800h		;4c5f   ; 0x800: el tercio siguiente
	add hl,de			;4c62
	ex de,hl			;4c63
	pop hl			;4c64   ; y el origen, otra vez el mismo
	pop bc			;4c65
	djnz espeja_un_tercio		;4c66
	ld c,000h		;4c68
	ld de,032b0h		;4c6a
copia_un_tile_de_vram_a_vram:		; Coge de la tabla de 0x4cd2 la direccion que toque y lleva ocho bytes a donde apunte DE
	ld hl,04cd2h		;4c6d   ; la tabla de las once direcciones
	push bc			;4c70
	push de			;4c71
	ld a,c			;4c72   ; por el numero de tile
	call indexa_una_tabla_de_punteros		;4c73
	ex de,hl			;4c76
	pop de			;4c77
	ld b,008h		;4c78   ; ocho bytes, o sea un tile
copia_un_tile_de_vram_a_vram_otra_vuelta:		; Dentro de copia_un_tile_de_vram_a_vram
	call 0004ah		;4c7a   ; BIOS RDVRM - Reads the content of VRAM
	ex de,hl			;4c7d
	call 0004dh		;4c7e   ; BIOS WRTVRM - Writes data in VRAM
	ex de,hl			;4c81
	inc hl			;4c82
	inc de			;4c83
	djnz copia_un_tile_de_vram_a_vram_otra_vuelta		;4c84
	pop bc			;4c86
	inc c			;4c87
	ld a,c			;4c88
	cp 00bh		;4c89
	jr c,copia_un_tile_de_vram_a_vram		;4c8b
	ld hl,012b0h		;4c8d
	ld a,0f0h		;4c90
	ld bc,00060h		;4c92
	call 00056h		;4c95   ; BIOS FILVRM - Fills VRAM with value
	ld hl,01800h		;4c98
	ld bc,00020h		;4c9b
	xor a			;4c9e
	call 00056h		;4c9f   ; BIOS FILVRM - Fills VRAM with value
	ld b,00dh		;4ca2
dibuja_las_figuras_del_luchador:		; Los trece guiones de 0x4cf0, de B = 13 a B = 1, cada uno en el destino que diga la tabla de 0x4d0a. Todos caen en 0x1800-0x1fff, la tabla de patrones de SPRITE
	push bc			;4ca4
	ld hl,04cf0h		;4ca5   ; la tabla de los trece guiones
	ld a,b			;4ca8
	dec a			;4ca9   ; el indice va de 12 a 0
	call indexa_una_tabla_de_punteros		;4caa
	push de			;4cad
	ld hl,04d0ah		;4cae   ; y la de los trece destinos
	ld a,b			;4cb1
	dec a			;4cb2
	call indexa_una_tabla_de_punteros		;4cb3
	ex de,hl			;4cb6
	pop de			;4cb7
	call dibuja_el_guion_en_el_puerto_cero		;4cb8   ; el guion, dibujado
	pop bc			;4cbb
	djnz dibuja_las_figuras_del_luchador		;4cbc
	ld hl,01a00h		;4cbe   ; HL = VRAM 0x1a00, el original
	ld de,01910h		;4cc1   ; DE = VRAM 0x1910, donde va el espejo
	ld c,030h		;4cc4   ; 0x30 filas de dieciseis bytes
	call refleja_varias_filas		;4cc6
	ld hl,01e40h		;4cc9   ; HL = VRAM 0x1e40
	ld de,05d02h		;4ccc   ; DE = 0x5d02, el ultimo guion
	jp dibuja_el_guion_en_el_puerto_cero		;4ccf

; ----------------------------------------------------------------------
; DATOS tabla_de_tiles_a_copiar: Once direcciones de VRAM -0x20d0, 0x2158,
;   0x2178, 0x2170, 0x2108, 0x2168, 0x2148, 0x2088, 0x20c8, 0x20c0 y 0x20a8-,
;   todas en la tabla de patrones. El bucle de 0x4c6d las recorre con C de 0 a
;   10 y copia ocho bytes de cada una a partir de 0x32b0, leyendo con RDVRM y
;   escribiendo con WRTVRM: son once tiles que se reordenan sin volver a pasar
;   por la ROM
;   0x4cd2..0x4ce8  (22 bytes)
DATA_tabla_de_tiles_a_copiar:
	defw 020d0h,02158h,02178h,02170h,02108h,02168h,02148h,02088h,020c8h,020c0h,020a8h	; 4cd2

; ======================================================================
; CODIGO 0x4ce8..0x4cf0  (8 bytes)
; ======================================================================


indexa_una_tabla_de_punteros:		; DE := la palabra que haya en HL mas A por dos. El sumador de todas las tablas indexadas del cartucho, y el que hace falta declarar para que el trazado siga sus destinos
	add a,a			;4ce8   ; A por dos, que son punteros
	call suma_a_hl		;4ce9   ; sumado a la tabla
	ld e,(hl)			;4cec   ; el byte bajo...
	inc hl			;4ced
	ld d,(hl)			;4cee   ; ...y el alto
	ret			;4cef

; ----------------------------------------------------------------------
; DATOS tabla_de_los_trece_guiones: Los trece punteros que recorre el bucle de
;   0x4ca4, de B=13 a B=1, o sea del ultimo al primero: 0x5971, 0x599a,
;   0x59f2, 0x5a43, 0x5a8f, 0x5ae5, 0x5b4a, 0x5b5d, 0x5b87, 0x5bc0, 0x5be4,
;   0x5be9 y 0x5c28
;   0x4cf0..0x4d0a  (26 bytes)
DATA_tabla_de_los_trece_guiones:
	defw 05971h,0599ah,059f2h,05a43h,05a8fh,05ae5h,05b4ah,05b5dh,05b87h,05bc0h,05be4h,05be9h,05c28h	; 4cf0

; ----------------------------------------------------------------------
; DATOS tabla_de_los_trece_destinos: Y las trece direcciones de VRAM donde va
;   cada uno, en el mismo orden: 0x1a00, 0x1a40, 0x1ac0, 0x1b40, 0x1bc0,
;   0x1c40, 0x1cc0, 0x1ce0, 0x1d20, 0x1d80, 0x1da0, 0x1e00 y 0x1e60. Todas
;   caen en 0x1800-0x1fff, que es donde R6 = 0x03 pone la TABLA DE PATRONES DE
;   SPRITE. O sea que estos trece guiones no dibujan fondo: dibujan las
;   figuras del luchador, y por eso 0x4cbe copia luego 0x1a00 sobre 0x1910
;   dandoles la vuelta bit a bit, para tenerlas tambien mirando al otro lado
;   0x4d0a..0x4d24  (26 bytes)
DATA_tabla_de_los_trece_destinos:
	defw 01a00h,01a40h,01ac0h,01b40h,01bc0h,01c40h,01cc0h,01ce0h,01d20h,01d80h,01da0h,01e00h,01e60h	; 4d0a

; ======================================================================
; CODIGO 0x4d24..0x4d6e  (74 bytes)
; ======================================================================


la_maquina_de_estados:		; Copia el golpe de 0xE165 a 0xE166, y con 0xE150 a cero acepta un movimiento nuevo. Los movimientos 2, 4 y 8, y el que repita el byte de 0xE151, se aceptan aunque haya uno en marcha
	ld a,(0e165h)		;4d24   ; el golpe de este cuadro...
	ld (0e166h),a		;4d27   ; ...se guarda para el siguiente
	ld a,(0e150h)		;4d2a   ; con un movimiento en marcha, a despachar
	and a			;4d2d
	jr nz,despacha_el_estado		;4d2e
	call lee_lo_que_se_pide		;4d30   ; lee lo que se pide
	ld hl,0e152h		;4d33   ; HL = 0xE152, el movimiento pedido
	ld a,(hl)			;4d36
	and a			;4d37   ; sin nada pedido, a despachar
	jr z,despacha_el_estado		;4d38
	cp 002h		;4d3a   ; el 2...
	jr z,despacha_el_estado		;4d3c
	cp 004h		;4d3e   ; ...el 4...
	jr z,despacha_el_estado		;4d40
	cp 008h		;4d42   ; ...y el 8 se encadenan
	jr z,despacha_el_estado		;4d44
	dec hl			;4d46
	xor (hl)			;4d47   ; y tambien si repite lo de 0xE151
	jr nz,despacha_el_estado		;4d48
	ld (0e150h),a		;4d4a   ; se acepta: a 0xE150 y a 0xE165
	ld (0e165h),a		;4d4d
	ret			;4d50
despacha_el_estado:		; Con 0xE150 justo en 0x0c suena la melodia 1. Luego baja 0xE150 en uno y reparte por la tabla de 0x4d6e con el movimiento de 0xE152
	ld a,(0e150h)		;4d51   ; los cuadros que quedan
	cp 00ch		;4d54   ; justo en 0x0c...
	jr nz,despacha_el_estado_si_no		;4d56
	ld a,001h		;4d58   ; ...suena la melodia 1
	call pon_la_melodia		;4d5a
despacha_el_estado_si_no:		; Dentro de despacha_el_estado
	xor a			;4d5d
	ld (0e165h),a		;4d5e   ; el golpe, borrado
	ld a,(0e152h)		;4d61   ; el movimiento pedido
	ld hl,0e150h		;4d64
	dec (hl)			;4d67   ; un cuadro menos
	ld hl,04d6eh		;4d68   ; y a la tabla de los treinta y dos
	call despacha_por_la_tabla_de_al_lado		;4d6b

; ----------------------------------------------------------------------
; DATOS tabla_de_la_maquina_de_estados: Los treinta y dos punteros que
;   despacha 0x4d6b. El 0x4dae -que es la palabra que va justo detras de la
;   tabla, o sea el estado que no hace nada- aparece CATORCE veces
;   0x4d6e..0x4dae  (64 bytes)
DATA_tabla_de_la_maquina_de_estados:
	defw 04daeh,04db3h,04dfch,04daeh,04e38h,04f2fh,04f3dh,04daeh,04e02h,04f28h,04f36h,04daeh,04daeh,04daeh,04daeh,04daeh	; 4d6e
	defw 04f44h,04e5eh,04ef3h,04daeh,04f21h,04e5eh,04ef3h,04daeh,04f1ah,04e5eh,04ef3h,04daeh,04daeh,04daeh,04daeh,04daeh	; 4d8e

; ======================================================================
; CODIGO 0x4dae..0x4de1  (51 bytes)
; ======================================================================


el_estado_que_no_hace_nada:		; A y B a cero y a 0x4f6b. Es a donde van catorce de las treinta y dos entradas de la tabla
	xor a			;4dae   ; nada que hacer
	ld b,a			;4daf
	jp fija_los_cuadros_y_dibuja		;4db0
el_salto:		; Recorre la curva de 0x4de1 con 0xE163 de indice y le suma cada valor a 0xE160, que es la Y del jugador: seis cuadros de -4, cuatro de -3, dos de -2, uno de -1 y luego los positivos, o sea que sube deprisa, se para arriba y baja. En los dos primeros cuadros, con el disparo pulsado, apunta el movimiento 0x11 en 0xE152: el golpe en el aire. Cuando la curva da su 0xA0 de cierre, se acabo el salto
	ld hl,0e163h		;4db3   ; HL = 0xE163, por donde va el salto
	ld a,(hl)			;4db6
	push af			;4db7
	cp 002h		;4db8   ; solo en los dos primeros cuadros...
	jr nc,el_salto_por_aqui		;4dba
	ld a,(0e00ah)		;4dbc   ; ...y con el disparo pulsado...
	bit 4,a		;4dbf
	jr z,el_salto_por_aqui		;4dc1
	ld a,011h		;4dc3   ; ...se apunta el movimiento 0x11
	ld (0e152h),a		;4dc5
el_salto_por_aqui:		; Dentro de el_salto
	pop af			;4dc8
	inc (hl)			;4dc9   ; un cuadro mas de salto
	ld hl,04de1h		;4dca   ; la curva de avance
	call suma_a_hl		;4dcd
	ld a,(hl)			;4dd0
	cp 0a0h		;4dd1   ; su 0xA0 acaba el salto
	jr z,el_estado_que_no_hace_nada		;4dd3
	ld hl,0e160h		;4dd5
	add a,(hl)			;4dd8   ; y si no, el valor se suma a la Y
	ld (hl),a			;4dd9
	ld a,001h		;4dda
	ld b,004h		;4ddc   ; B = 4, la pose
	jp fija_los_cuadros_y_dibuja		;4dde

; ----------------------------------------------------------------------
; DATOS curva_de_avance: Veintiseis valores y un 0xA0 de cierre: FC FC FC FC
;   FC FC FD FD FD FD FE FE FF 01 02 02 03 03 03 03 04 04 04 04 04 04. 0x4dca
;   los indexa uno por vuelta y se lo suma a 0xE160; cuando le sale el 0xA0 de
;   0x4dfb se va al estado que no hace nada. Leidos con signo van de -4 a +4
;   pasando por cero: primero atras, cada vez menos, y luego adelante, cada
;   vez mas
;   0x4de1..0x4dfc  (27 bytes)
DATA_curva_de_avance:
	defb 0fch,0fch,0fch,0fch,0fch,0fch,0fdh,0fdh,0fdh,0fdh,0feh,0feh,0ffh,001h,002h,002h	; 4de1  ................
	defb 003h,003h,003h,003h,004h,004h,004h,004h,004h,004h,0a0h	; 4df1  ...........

; ======================================================================
; CODIGO 0x4dfc..0x50a6  (682 bytes)
; ======================================================================


el_estado_de_la_pose_ocho:		; A a cero y B a 8
	xor a			;4dfc
	ld b,008h		;4dfd   ; B = 8, la pose
	jp fija_los_cuadros_y_dibuja		;4dff
anda_hacia_delante:		; Borra 0xE162 y 0xE150, y mientras 0xE161 no llegue a 0xDD lo sube de uno en uno; 0x5476 dice si hay algo que lo pare
	xor a			;4e02   ; 0xE162 y 0xE150, a cero
	ld (0e162h),a		;4e03
	ld (0e150h),a		;4e06
	ld hl,0e161h		;4e09   ; HL = 0xE161, la posicion
	ld a,(hl)			;4e0c
	cp 0ddh		;4e0d   ; con 0xDD ya no se puede seguir
	jp nc,el_estado_que_no_hace_nada		;4e0f
	push hl			;4e12
	call mide_la_separacion		;4e13   ; y 0x5476 dice si hay tope
	pop hl			;4e16
	and a			;4e17
	jr z,un_paso_adelante		;4e18
	ld a,b			;4e1a
	dec a			;4e1b
	jp z,el_estado_que_no_hace_nada		;4e1c
un_paso_adelante:		; Dos pixeles y a la animacion de andar
	inc (hl)			;4e1f   ; un paso adelante
	inc (hl)			;4e20   ; el segundo pixel
	jr y_a_la_animacion		;4e21
alterna_la_pose_de_andar:		; Cada ocho cuadros cambia 0xE164 entre 0 y 0x12, que son las dos poses de la zancada, y la deja en B
	ld hl,0e164h		;4e23   ; HL = 0xE164, la pose de la zancada
	ld a,(0e003h)		;4e26
	and 006h		;4e29   ; uno de cada ocho cuadros
	ld a,(hl)			;4e2b
	jr nz,alterna_la_pose_de_andar_si_no_2		;4e2c
	and a			;4e2e
	ld a,000h		;4e2f   ; la 0...
	jr nz,alterna_la_pose_de_andar_si_no		;4e31
	ld a,012h		;4e33   ; ...o la 0x12
alterna_la_pose_de_andar_si_no:		; Dentro de alterna_la_pose_de_andar
	ld (hl),a			;4e35   ; guardada
alterna_la_pose_de_andar_si_no_2:		; Dentro de alterna_la_pose_de_andar
	ld b,a			;4e36   ; y a B, que es lo que se dibuja
	ret			;4e37
anda_hacia_atras:		; Lo mismo al reves: 0xE162 puesto, y mientras 0xE161 no baje de 0x23 se resta de dos en dos
	xor a			;4e38
	ld (0e150h),a		;4e39   ; el movimiento, cerrado
	inc a			;4e3c
	ld (0e162h),a		;4e3d   ; 0xE162 puesto: mirando al otro lado
	ld hl,0e161h		;4e40   ; HL = 0xE161, la posicion
	ld a,(hl)			;4e43
	cp 023h		;4e44   ; con 0x23 ya no se puede seguir
	jp c,el_estado_que_no_hace_nada		;4e46
	push hl			;4e49
	call mide_la_separacion		;4e4a   ; y 0x5476 dice si hay tope
	pop hl			;4e4d
	and a			;4e4e
	jr nz,anda_hacia_atras_si_no		;4e4f
	ld a,b			;4e51
	dec a			;4e52
	jp z,el_estado_que_no_hace_nada		;4e53
anda_hacia_atras_si_no:		; Dentro de anda_hacia_atras
	dec (hl)			;4e56   ; dos pixeles atras
	dec (hl)			;4e57
y_a_la_animacion:		; La pose de la zancada y a dibujar
	call alterna_la_pose_de_andar		;4e58   ; la pose de andar
	jp dibuja_la_pose_de_b		;4e5b
el_salto_con_golpe:		; Igual que el salto normal, pero atento al disparo: si esta suelto se apunta en 0xE124, y con 0xE123 a cero, 0xE124 puesto, el salto pasado del cuadro 0x0b y el disparo otra vez pulsado, se pide el movimiento 9 y suena la melodia 1. O sea que hay que SOLTAR y volver a pulsar en el aire
	ld a,(0e00ah)		;4e5e   ; el estado del disparo
	and 010h		;4e61   ; con el bit 4 a cero...
	jr nz,mira_si_se_pide_el_golpe_en_el_aire		;4e63
	inc a			;4e65
	ld (0e124h),a		;4e66   ; ...se apunta que esta suelto
mira_si_se_pide_el_golpe_en_el_aire:		; Las cuatro condiciones seguidas
	ld hl,0e123h		;4e69   ; HL = 0xE123, el golpe en marcha
	ld a,(hl)			;4e6c
	and a			;4e6d
	jr nz,recorre_la_curva_del_salto		;4e6e   ; con uno en marcha, no
	inc hl			;4e70
	ld a,(hl)			;4e71   ; hace falta haberlo soltado
	and a			;4e72
	jr z,recorre_la_curva_del_salto		;4e73
	ld a,(0e163h)		;4e75   ; y que el salto pase del cuadro 0x0b
	cp 00bh		;4e78
	jr c,recorre_la_curva_del_salto		;4e7a
	ld a,(0e00ah)		;4e7c   ; y el disparo, pulsado otra vez
	bit 4,a		;4e7f
	jr z,recorre_la_curva_del_salto		;4e81
	ld a,009h		;4e83
	dec hl			;4e85
	ld (hl),a			;4e86   ; el golpe 9, pedido
	ld a,001h		;4e87   ; y su melodia
	call pon_la_melodia		;4e89
recorre_la_curva_del_salto:		; La misma curva de 0x4de1 que el salto normal; su 0xA0 de cierre borra 0xE123 y 0xE124 y acaba
	ld hl,0e163h		;4e8c   ; HL = 0xE163, por donde va el salto
	ld a,(hl)			;4e8f
	inc (hl)			;4e90   ; un cuadro mas
	ld hl,04de1h		;4e91   ; la curva de avance
	call suma_a_hl		;4e94
	ld a,(hl)			;4e97
	cp 0a0h		;4e98   ; su 0xA0 cierra el salto
	jp nz,avanza_en_el_aire		;4e9a
	xor a			;4e9d
	ld (0e123h),a		;4e9e   ; los dos avisos del golpe, borrados
	ld (0e124h),a		;4ea1
	jp el_estado_que_no_hace_nada		;4ea4
avanza_en_el_aire:		; Suma el valor de la curva a la Y, y del cuadro 3 en adelante mueve tambien la posicion: cuatro pixeles atras si 0xE162 esta puesto y cuatro adelante si no, con sus topes en 0x22 y 0xE0
	ld hl,0e160h		;4ea7   ; HL = 0xE160, la Y del jugador
	add a,(hl)			;4eaa
	ld (hl),a			;4eab
	ld a,001h		;4eac
	ld (0e150h),a		;4eae   ; un cuadro de movimiento
	ld a,(0e163h)		;4eb1
	cp 003h		;4eb4   ; hasta el cuadro 3 no se mueve
	jr c,la_pose_cuatro		;4eb6
	ld hl,0e161h		;4eb8
	ld a,(0e162h)		;4ebb   ; 0xE162 dice hacia donde
	and a			;4ebe
	ld a,(hl)			;4ebf
	jr z,avanza_en_el_aire_si_no_2		;4ec0
	sub 004h		;4ec2   ; cuatro pixeles atras...
	cp 022h		;4ec4   ; ...con su tope en 0x22
	jr c,avanza_en_el_aire_si_no		;4ec6
	ld (hl),a			;4ec8
avanza_en_el_aire_si_no:		; Dentro de avanza_en_el_aire
	ld a,005h		;4ec9   ; pose 5 volando a la izquierda
	ld c,00dh		;4ecb
	jr y_la_pose_del_golpe		;4ecd
avanza_en_el_aire_si_no_2:		; Dentro de avanza_en_el_aire
	add a,004h		;4ecf   ; cuatro adelante...
	cp 0e0h		;4ed1   ; ...con su tope en 0xE0
	jr nc,avanza_en_el_aire_si_no_3		;4ed3
	ld (hl),a			;4ed5
avanza_en_el_aire_si_no_3:		; Dentro de avanza_en_el_aire
	ld a,004h		;4ed6   ; pose 4 volando a la derecha
	ld c,00ch		;4ed8
y_la_pose_del_golpe:		; Con 0xE123 en 2 o mas, se baja uno, se usa la otra pose -0x0d o 0x0c- y se apunta el golpe 5 en 0xE165
	ld b,a			;4eda
	ld hl,0e123h		;4edb
	ld a,(hl)			;4ede
	cp 002h		;4edf   ; de 2 para arriba
	jr c,y_la_pose_del_golpe_si_no		;4ee1
	dec (hl)			;4ee3   ; un cuadro menos de golpe
	ld b,c			;4ee4   ; y la pose del golpe en el aire
	ld a,005h		;4ee5
	ld (0e165h),a		;4ee7   ; el golpe 5, apuntado
y_la_pose_del_golpe_si_no:		; Dentro de y_la_pose_del_golpe
	ld a,b			;4eea
	jp fija_la_pose		;4eeb   ; y la pose, montada
la_pose_cuatro:		; B = 4 y a dibujar
	ld b,004h		;4eee   ; B = 4, la pose
	jp dibuja_la_pose_de_b		;4ef0
el_barrido:		; Apunta el golpe 4 en 0xE165 y usa la pose 0x0a o la 0x0b segun el lado. Solo dibuja esa pose mientras 0xE150 este entre 4 y 7 o entre 8 y 0x0b; fuera de esos tramos vuelve a la pose 8
	ld a,004h		;4ef3   ; el golpe 4
	ld (0e165h),a		;4ef5
	ld a,(0e162h)		;4ef8   ; el lado al que se mira
	and a			;4efb
	ld a,00ah		;4efc   ; pose 0x0a a la derecha...
	jr z,el_barrido_si_no		;4efe
	inc a			;4f00   ; ...y 0x0b a la izquierda
el_barrido_si_no:		; Dentro de el_barrido
	ld b,a			;4f01
	ld a,(0e150h)		;4f02   ; los cuadros que quedan
	cp 00ch		;4f05   ; de 0x0c para arriba, la pose de espera
	jr nc,el_barrido_por_aqui		;4f07
	cp 008h		;4f09   ; entre 8 y 0x0b, la del golpe
	jr nc,el_barrido_si_no_2		;4f0b
	cp 004h		;4f0d   ; y por debajo de 4, la de espera
	jr c,el_barrido_por_aqui		;4f0f
el_barrido_si_no_2:		; Dentro de el_barrido
	ld a,b			;4f11
	jp fija_la_pose		;4f12
el_barrido_por_aqui:		; Dentro de el_barrido
	ld b,008h		;4f15   ; B = 8, la pose de espera
	jp dibuja_la_pose_de_b		;4f17
golpe_1_derecha:		; C = 1 y pose 2, mirando a la derecha
	ld c,001h		;4f1a   ; C = 1, el primer golpe
	ld b,002h		;4f1c   ; B = 2, su pose
	jp el_golpe_a_la_derecha		;4f1e
golpe_1_izquierda:		; El mismo golpe hacia el otro lado
	ld c,001h		;4f21   ; C = 1
	ld b,002h		;4f23   ; B = 2
	jp el_golpe_a_la_izquierda		;4f25
golpe_2_derecha:		; C = 2 y pose 6
	ld c,002h		;4f28   ; C = 2, el segundo golpe
	ld b,006h		;4f2a   ; B = 6, su pose
	jp el_golpe_a_la_derecha		;4f2c
golpe_2_izquierda:		; El mismo hacia el otro lado
	ld c,002h		;4f2f   ; C = 2
	ld b,006h		;4f31   ; B = 6
	jp el_golpe_a_la_izquierda		;4f33
golpe_3_derecha:		; C = 3 y pose 0x0e
	ld c,003h		;4f36   ; C = 3, el tercer golpe
	ld b,00eh		;4f38   ; B = 0x0e, su pose
	jp el_golpe_a_la_derecha		;4f3a
golpe_3_izquierda:		; El mismo hacia el otro lado
	ld c,003h		;4f3d   ; C = 3
	ld b,00eh		;4f3f   ; B = 0x0e
	jp el_golpe_a_la_izquierda		;4f41
golpe_1_hacia_donde_se_mire:		; Mira 0xE162 y se va al 0x4f1a o al 0x4f21
	ld a,(0e162h)		;4f44   ; el lado al que se mira
	and a			;4f47
	jp z,golpe_1_derecha		;4f48
	jp golpe_1_izquierda		;4f4b
lee_lo_que_se_pide:		; 0xE152 pasa a 0xE151 -el movimiento del cuadro anterior- y los cinco bits bajos de 0xE00a entran como movimiento nuevo. Sin nada pulsado, un solo cuadro; con algo, trece
	ld hl,0e152h		;4f4e   ; HL = 0xE152, el movimiento pedido
	ld a,(hl)			;4f51
	dec hl			;4f52
	ld (hl),a			;4f53   ; el de antes pasa a 0xE151
	ld a,(0e00ah)		;4f54   ; los mandos de este cuadro
	and 01fh		;4f57   ; y solo los cinco bits de direccion y disparo
	inc hl			;4f59
	ld (hl),a			;4f5a
	and a			;4f5b
	jr nz,lee_lo_que_se_pide_si_no		;4f5c
	inc a			;4f5e   ; sin nada, un cuadro...
	jr lee_lo_que_se_pide_si_no_2		;4f5f
lee_lo_que_se_pide_si_no:		; Dentro de lee_lo_que_se_pide
	ld a,00dh		;4f61   ; ...y con algo, trece
lee_lo_que_se_pide_si_no_2:		; Dentro de lee_lo_que_se_pide
	ld (0e150h),a		;4f63
	xor a			;4f66
	ld (0e163h),a		;4f67   ; y el salto, a cero
	ret			;4f6a
fija_los_cuadros_y_dibuja:		; Deja A en 0xE150 y cae en 0x4f6e
	ld (0e150h),a		;4f6b   ; los cuadros del movimiento
dibuja_la_pose_de_b:		; Ajusta el lado y monta la pose
	call la_pose_segun_el_lado		;4f6e   ; el lado y la pose
	jr fija_la_pose		;4f71
la_pose_segun_el_lado:		; Mirando a la derecha se usa B tal cual; a la izquierda, B mas uno. Por eso las poses van de dos en dos
	call mira_si_hay_que_darse_la_vuelta		;4f73
	ld a,(0e162h)		;4f76   ; el lado al que se mira
	and a			;4f79
	ld a,b			;4f7a   ; a la derecha, B tal cual
	ret z			;4f7b
	inc a			;4f7c   ; y a la izquierda, la de al lado
	ret			;4f7d
mira_si_hay_que_darse_la_vuelta:		; Solo con 0xE058 a cero y la Y de 0xE160 en 0x85 o mas, o sea con los pies en el suelo: en el aire no se gira. Entonces 0x5476 dice de que lado esta el otro y 0xE162 se pone al contrario
	ld a,(0e058h)		;4f7e   ; con 0xE058 puesto no se gira
	and a			;4f81
	ret nz			;4f82
	ld a,(0e160h)		;4f83   ; la Y del jugador
	cp 085h		;4f86   ; y por encima de 0x85, o sea en el aire, tampoco
	ret c			;4f88
	push bc			;4f89
	call mide_la_separacion		;4f8a   ; de que lado esta el otro
	xor 001h		;4f8d   ; al reves...
	ld (0e162h),a		;4f8f   ; ...y ese es el lado al que se mira
	pop bc			;4f92
	ret			;4f93
el_golpe_a_la_derecha:		; 0xE162 a cero y a la parte comun
	xor a			;4f94   ; mirando a la derecha
	jr monta_el_golpe		;4f95
el_golpe_a_la_izquierda:		; 0xE162 a uno
	ld a,001h		;4f97   ; mirando a la izquierda
monta_el_golpe:		; Guarda el lado, apunta el golpe de C en 0xE165 y saca la pose. Solo se dibuja la pose del golpe mientras 0xE150 este entre 4 y 0x0a; fuera de ahi se usa la pose 0 o la 1 segun el lado
	ld (0e162h),a		;4f99   ; el lado, guardado
	ld a,c			;4f9c
	ld (0e165h),a		;4f9d   ; el numero de golpe
	call la_pose_segun_el_lado		;4fa0   ; la pose, ajustada al lado
	ld b,a			;4fa3
	ld a,(0e150h)		;4fa4
	cp 00bh		;4fa7   ; de 0x0b para arriba, todavia no
	jr nc,monta_el_golpe_por_aqui		;4fa9
	cp 004h		;4fab   ; y por debajo de 4, ya no
	jr c,monta_el_golpe_por_aqui		;4fad
	ld a,b			;4faf
	jr fija_la_pose		;4fb0
monta_el_golpe_por_aqui:		; Dentro de monta_el_golpe
	ld a,(0e162h)		;4fb2   ; fuera del tramo, la pose de reposo
	and a			;4fb5
	jr z,fija_la_pose		;4fb6
	ld a,001h		;4fb8   ; o la 1 si mira a la izquierda
fija_la_pose:		; Deja A en 0xE154, que es lo que 0x4fe1 indexa para sacar la receta
	ld (0e154h),a		;4fba   ; la pose, puesta
	ret			;4fbd
monta_la_pose:		; Reparte los seis patrones de 0x50a6 por los seis primeros sprites de 0xE0c4, borra 0xE171 y 0xE172, y ejecuta la receta que 0xE154 elija en la tabla de 0x50ac
	ld hl,0e0c4h		;4fbe   ; HL = 0xE0c4, los sprites del jugador
	ld de,050a6h		;4fc1   ; DE = 0x50a6, los seis patrones
	ld b,006h		;4fc4   ; seis
reparte_los_seis_patrones:		; De dos en dos, para caer siempre en el campo de patron y no tocar las coordenadas ni el color
	inc hl			;4fc6   ; dos posiciones: el campo de patron
	inc hl			;4fc7
	ld a,(de)			;4fc8   ; el patron que toca
	ld (hl),a			;4fc9
	inc hl			;4fca   ; y otras dos hasta el sprite siguiente
	inc hl			;4fcb
	inc de			;4fcc
	djnz reparte_los_seis_patrones		;4fcd
	ld a,(0e160h)		;4fcf   ; C = la Y del jugador
	ld c,a			;4fd2
	ld a,(0e161h)		;4fd3   ; B = su X
	ld b,a			;4fd6
	xor a			;4fd7
	ld (0e172h),a		;4fd8   ; 0xE172 y 0xE171, borrados
	ld (0e171h),a		;4fdb
	ld a,(0e154h)		;4fde   ; la pose de ahora
	ld hl,050ach		;4fe1   ; la tabla de las veintidos recetas
	add a,a			;4fe4   ; por dos, que son punteros
	call suma_a_hl		;4fe5
	ld e,(hl)			;4fe8
	inc hl			;4fe9
	ld d,(hl)			;4fea
	ex de,hl			;4feb
el_campo_setenta:		; Con el nibble alto en 0x7-, el bajo va a 0xE174; si no, ahi queda un cero
	ld a,(hl)			;4fec
	and 0f0h		;4fed   ; el nibble alto
	cp 070h		;4fef   ; el 0x7-...
	ld a,000h		;4ff1
	jr nz,el_campo_ochenta		;4ff3
	ld a,(hl)			;4ff5
	and 00fh		;4ff6   ; ...deja su nibble bajo
	inc hl			;4ff8
el_campo_ochenta:		; Con el nibble alto en 0x8-, el bajo va a 0xE172, que es la pose con la que se comprueban los golpes
	ld (0e174h),a		;4ff9   ; a 0xE174
	ld de,0e172h		;4ffc   ; DE = 0xE172
	ld a,(hl)			;4fff
	and 0f0h		;5000
	cp 080h		;5002   ; el 0x8-...
	jr nz,las_tres_posiciones		;5004
	ld a,(hl)			;5006
	and 00fh		;5007   ; ...deja su nibble bajo
	ld (de),a			;5009
	inc hl			;500a
las_tres_posiciones:		; Tres bytes seguidos, cada uno sumado a la X del jugador, que van a 0xE1b2: son donde queda cada una de las tres armas
	push bc			;500b
	ld b,003h		;500c   ; tres
	ld de,0e1b2h		;500e   ; DE = 0xE1b2, la terna
las_tres_posiciones_otra_vuelta:		; Dentro de las_tres_posiciones
	ld a,(0e161h)		;5011   ; la X del jugador...
	add a,(hl)			;5014   ; ...mas lo que diga la receta
	ld (de),a			;5015
	inc hl			;5016
	inc de			;5017
	djnz las_tres_posiciones_otra_vuelta		;5018
	pop bc			;501a
	ld a,(0e162h)		;501b   ; el lado al que se mira
	and a			;501e
	jr z,monta_los_sprites		;501f   ; a la derecha, el cuerpo normal
	ld e,(hl)			;5021   ; y a la izquierda, la receta que este puntero diga
	inc hl			;5022
	ld d,(hl)			;5023
	ex de,hl			;5024
	ld de,0e0c4h		;5025   ; DE = 0xE0c4, el primer sprite del jugador
monta_los_sprites_espejados:		; El cuerpo de la izquierda. La primera coordenada se suma tal cual y la segunda se ESPEJA: 0x10 mas el dato, cambiado de signo, mas la del jugador
	ld a,(hl)			;5028   ; el nibble alto
	and 0f0h		;5029
	cp 080h		;502b   ; el 0x8- cierra la lista
	jr z,cierra_la_lista_de_sprites		;502d
	ld a,(hl)			;502f
	add a,c			;5030   ; la primera coordenada, sumada
	ld (de),a			;5031
	inc hl			;5032
	inc de			;5033
	ld a,010h		;5034   ; y la segunda, espejada
	add a,(hl)			;5036
	neg		;5037
	add a,b			;5039
	ld (de),a			;503a
	inc hl			;503b
	inc de			;503c
	push bc			;503d
	ld b,a			;503e
	ld a,(hl)			;503f
	and 0f0h		;5040
	cp 0f0h		;5042   ; con 0xF- de por medio...
	jr nz,monta_los_sprites_espejados_si_no		;5044
	ld a,(hl)			;5046
	and 00fh		;5047
	ld c,a			;5049
	ld a,010h		;504a
	sub c			;504c
	add a,b			;504d
	ld (0e171h),a		;504e   ; ...sale la X del golpe, tambien espejada
	inc hl			;5051
monta_los_sprites_espejados_si_no:		; Dentro de monta_los_sprites_espejados
	pop bc			;5052
	ld a,(hl)			;5053
	ld (de),a			;5054   ; el patron
	inc hl			;5055
	inc de			;5056
	ld a,(hl)			;5057
	ld (de),a			;5058   ; y el color, tal cual
	inc hl			;5059
	inc de			;505a
	jr monta_los_sprites_espejados		;505b
cierra_la_lista_de_sprites:		; Un 0xD0 en el campo Y, que es lo que el TMS9918 entiende por fin de la lista
	ld a,0d0h		;505d   ; 0xD0: no hay mas sprites
	ld (de),a			;505f
	ret			;5060
monta_los_sprites:		; El cuerpo de la derecha, sin espejar
	ld de,0e0c4h		;5061   ; DE = 0xE0c4, el primer sprite del jugador
monta_los_sprites_normales:		; El cuerpo de la derecha. Mientras el nibble alto no sea 0x8-, cada campo da un sprite: el primer byte se suma a la Y del jugador y el segundo a su X, y los otros dos -patron y color- van tal cual. Con 0xF- de por medio sale la X del golpe
	ld a,(hl)			;5064   ; el nibble alto del campo
	and 0f0h		;5065
	cp 080h		;5067   ; el 0x8- cierra la lista
	jr z,cierra_y_encadena_los_guiones		;5069
	ld a,(hl)			;506b
	add a,c			;506c   ; la Y del jugador mas el dato
	ld (de),a			;506d
	inc hl			;506e
	inc de			;506f
	ld a,(hl)			;5070
	add a,b			;5071   ; y la X del jugador mas el siguiente
	ld (de),a			;5072
	inc hl			;5073
	inc de			;5074
	push bc			;5075
	ld b,a			;5076
	ld a,(hl)			;5077
	and 0f0h		;5078
	cp 0f0h		;507a   ; con 0xF- de por medio...
	jr nz,monta_los_sprites_normales_si_no		;507c
	ld a,(hl)			;507e
	and 00fh		;507f
	add a,b			;5081   ; ...sale la X del golpe, a 0xE171
	ld (0e171h),a		;5082
	inc hl			;5085
monta_los_sprites_normales_si_no:		; Dentro de monta_los_sprites_normales
	pop bc			;5086
	inc hl			;5087
	inc de			;5088
	ld a,(hl)			;5089   ; el patron
	ld (de),a			;508a   ; y el color
	inc hl			;508b
	inc de			;508c
	jr monta_los_sprites_normales		;508d
cierra_y_encadena_los_guiones:		; El 0x8- del cuerpo normal hace dos cosas: cierra la lista de sprites con el 0xD0 y, si su nibble bajo no es cero, ese es el numero de PAREJAS de direcciones que vienen detras. Cada pareja se le pasa a encadena_el_guion, que se lee de ella la VRAM de destino
	ld a,0d0h		;508f   ; 0xD0: no hay mas sprites
	ld (de),a			;5091
	ld a,(hl)			;5092
	and 00fh		;5093   ; el nibble bajo dice cuantos guiones
	ret z			;5095   ; a cero, ninguno
	ld b,a			;5096
	inc hl			;5097
dibuja_un_guion_de_la_receta:		; Lee la pareja, la apila y llama a encadena_el_guion. Estas direcciones apuntan DOS BYTES ANTES de lo que dice la tabla de 0x4cf0, porque ahi es donde cada guion lleva escrito su destino
	ld e,(hl)			;5098   ; el byte bajo...
	inc hl			;5099
	ld d,(hl)			;509a   ; ...y el alto
	inc hl			;509b
	push bc			;509c
	push hl			;509d
	call encadena_el_guion		;509e   ; y a dibujar, con el destino dentro
	pop hl			;50a1
	pop bc			;50a2
	djnz dibuja_un_guion_de_la_receta		;50a3   ; el siguiente
	ret			;50a5

; ----------------------------------------------------------------------
; DATOS patrones_de_arranque: Los seis bytes que 0x4fc6 reparte por el campo
;   de patron de los seis primeros sprites de 0xE0c4
;   0x50a6..0x50ac  (6 bytes)
DATA_patrones_de_arranque:
	defb 004h,008h,00ch,010h,014h,018h	; 50a6

; ----------------------------------------------------------------------
; DATOS tabla_de_recetas: Los 22 punteros que 0x4fe1 indexa por 0xE154. Van a
;   20 recetas distintas: tres indices seguidos comparten la de 0x5217
;   0x50ac..0x50d8  (44 bytes)
DATA_tabla_de_recetas:
	defw 050d8h,050f8h,050fdh,0511fh,05125h,05146h,0514ch,0516ah,05170h,05191h,05197h,051bch,051c3h,051e6h,051edh,05211h	; 50ac
	defw 05217h,05217h,05217h,05235h,0523ah,05250h	; 50cc

; ----------------------------------------------------------------------
; DATOS receta_50d8: 32 bytes. Indice 0 de la tabla de 0x50ac
;   0x50d8..0x50f8  (32 bytes)
DATA_receta_50d8:
	defb 0fah,0fah,0fch,0f6h,0f9h,020h,006h,0fbh,0f9h,024h,00bh,009h,0f8h,028h,00bh,000h	; 50d8  ..... ...$...(..
	defb 008h,02ch,00bh,013h,0f0h,030h,004h,013h,000h,034h,004h,082h,06fh,059h,098h,059h	; 50e8  .,...0...4..oY.Y

; ----------------------------------------------------------------------
; DATOS receta_50f8: 5 bytes. Indice 1 de la tabla de 0x50ac
;   0x50f8..0x50fd  (5 bytes)
DATA_receta_50f8:
	defb 0fdh,0fch,0f8h,0dbh,050h	; 50f8

; ----------------------------------------------------------------------
; DATOS receta_50fd: 34 bytes. Indice 2 de la tabla de 0x50ac
;   0x50fd..0x511f  (34 bytes)
DATA_receta_50fd:
	defb 082h,002h,002h,004h,0f6h,001h,020h,006h,0fbh,001h,024h,00bh,00ah,000h,038h,00bh	; 50fd  ...... ...$...8.
	defb 004h,010h,0f2h,03ch,00bh,013h,0f8h,040h,004h,013h,008h,044h,004h,082h,06fh,059h	; 510d  ...<...@...D..oY
	defb 0f0h,059h	; 511d

; ----------------------------------------------------------------------
; DATOS receta_511f: 6 bytes. Indice 3 de la tabla de 0x50ac
;   0x511f..0x5125  (6 bytes)
DATA_receta_511f:
	defb 082h,0f4h,0f4h,0f0h,001h,051h	; 511f

; ----------------------------------------------------------------------
; DATOS receta_5125: 33 bytes. Indice 4 de la tabla de 0x50ac
;   0x5125..0x5146  (33 bytes)
DATA_receta_5125:
	defb 074h,0fah,0fah,0fch,0f6h,0f9h,020h,006h,0fbh,0f9h,024h,00bh,007h,0eeh,048h,00bh	; 5125  t..... ...$...H.
	defb 0ffh,0feh,04ch,00bh,00fh,0f6h,050h,004h,00fh,006h,054h,004h,082h,06fh,059h,041h	; 5135  ..L...P...T..oYA
	defb 05ah	; 5145

; ----------------------------------------------------------------------
; DATOS receta_5146: 6 bytes. Indice 5 de la tabla de 0x50ac
;   0x5146..0x514c  (6 bytes)
DATA_receta_5146:
	defb 074h,0fah,0fah,0fah,029h,051h	; 5146

; ----------------------------------------------------------------------
; DATOS receta_514c: 30 bytes. Indice 6 de la tabla de 0x50ac
;   0x514c..0x516a  (30 bytes)
DATA_receta_514c:
	defb 081h,002h,006h,0feh,0f8h,002h,078h,006h,000h,001h,068h,00bh,0fch,010h,0fch,06ch	; 514c  ......x...h....l
	defb 004h,010h,000h,070h,004h,00ch,008h,074h,004h,082h,048h,05bh,0e3h,05ah	; 515c  ...p...t..H[.Z

; ----------------------------------------------------------------------
; DATOS receta_516a: 6 bytes. Indice 7 de la tabla de 0x50ac
;   0x516a..0x5170  (6 bytes)
DATA_receta_516a:
	defb 081h,0f4h,0eeh,0f8h,050h,051h	; 516a

; ----------------------------------------------------------------------
; DATOS receta_5170: 33 bytes. Indice 8 de la tabla de 0x50ac
;   0x5170..0x5191  (33 bytes)
DATA_receta_5170:
	defb 071h,0fah,0fah,0fch,0fdh,0f9h,020h,006h,002h,0f9h,024h,00bh,00eh,0eeh,048h,00bh	; 5170  q..... ...$...H.
	defb 006h,0feh,04ch,00bh,016h,0f6h,050h,004h,016h,006h,054h,004h,082h,06fh,059h,041h	; 5180  ..L...P...T..oYA
	defb 05ah	; 5190

; ----------------------------------------------------------------------
; DATOS receta_5191: 6 bytes. Indice 9 de la tabla de 0x50ac
;   0x5191..0x5197  (6 bytes)
DATA_receta_5191:
	defb 071h,0fah,0fah,0fah,074h,051h	; 5191

; ----------------------------------------------------------------------
; DATOS receta_5197: 37 bytes. Indice 10 de la tabla de 0x50ac
;   0x5197..0x51bc  (37 bytes)
DATA_receta_5197:
	defb 071h,083h,0fah,0fah,0fah,0feh,0fah,078h,006h,006h,0f9h,07ch,00bh,0feh,009h,080h	; 5197  q......x...|....
	defb 00bh,014h,0f8h,084h,004h,014h,008h,088h,004h,01dh,00ch,0fch,08ch,004h,083h,048h	; 51a7  ...............H
	defb 05bh,05bh,05bh,085h,05bh	; 51b7

; ----------------------------------------------------------------------
; DATOS receta_51bc: 7 bytes. Indice 11 de la tabla de 0x50ac
;   0x51bc..0x51c3  (7 bytes)
DATA_receta_51bc:
	defb 071h,083h,0fch,0f8h,0f4h,09ch,051h	; 51bc

; ----------------------------------------------------------------------
; DATOS receta_51c3: 35 bytes. Indice 12 de la tabla de 0x50ac
;   0x51c3..0x51e6  (35 bytes)
DATA_receta_51c3:
	defb 074h,081h,0fah,0fah,0fah,0f6h,0f9h,020h,006h,0fbh,0f9h,024h,00bh,007h,0f2h,058h	; 51c3  t...... ...$...X
	defb 00bh,0fdh,002h,05ch,00bh,00dh,0fah,060h,004h,00eh,00ah,0f8h,064h,004h,082h,06fh	; 51d3  ...\...`....d..o
	defb 059h,08dh,05ah	; 51e3

; ----------------------------------------------------------------------
; DATOS receta_51e6: 7 bytes. Indice 13 de la tabla de 0x50ac
;   0x51e6..0x51ed  (7 bytes)
DATA_receta_51e6:
	defb 074h,081h,0fch,0fah,0fah,0c8h,051h	; 51e6

; ----------------------------------------------------------------------
; DATOS receta_51ed: 36 bytes. Indice 14 de la tabla de 0x50ac
;   0x51ed..0x5211  (36 bytes)
DATA_receta_51ed:
	defb 083h,002h,006h,0feh,0f8h,002h,078h,006h,000h,001h,07ch,00bh,0f8h,011h,080h,00bh	; 51ed  ......x...|.....
	defb 010h,000h,0a0h,004h,00dh,00bh,0a4h,004h,010h,010h,0fdh,0a8h,004h,083h,048h,05bh	; 51fd  ..............H[
	defb 05bh,05bh,0e7h,05bh	; 520d

; ----------------------------------------------------------------------
; DATOS receta_5211: 6 bytes. Indice 15 de la tabla de 0x50ac
;   0x5211..0x5217  (6 bytes)
DATA_receta_5211:
	defb 083h,0f4h,0eeh,0f8h,0f1h,051h	; 5211

; ----------------------------------------------------------------------
; DATOS receta_5217: 30 bytes. Indice 16, 17, 18 de la tabla de 0x50ac
;   0x5217..0x5235  (30 bytes)
DATA_receta_5217:
	defb 0fah,0f8h,0fah,0f6h,0f9h,020h,006h,0fbh,0f9h,024h,00bh,009h,0f8h,028h,00bh,000h	; 5217  ..... ...$...(..
	defb 008h,02ch,00bh,013h,0f7h,090h,004h,083h,06fh,059h,098h,059h,0beh,05bh	; 5227  .,......oY.Y.[

; ----------------------------------------------------------------------
; DATOS receta_5235: 5 bytes. Indice 19 de la tabla de 0x50ac
;   0x5235..0x523a  (5 bytes)
DATA_receta_5235:
	defb 0fdh,0fah,0fah,01ah,052h	; 5235

; ----------------------------------------------------------------------
; DATOS receta_523a: 22 bytes. Indice 20 de la tabla de 0x50ac
;   0x523a..0x5250  (22 bytes)
DATA_receta_523a:
	defb 008h,008h,008h,010h,0f4h,0ach,004h,010h,002h,0b0h,004h,010h,0ech,0b4h,00bh,010h	; 523a  ................
	defb 002h,0b8h,00bh,081h,026h,05ch	; 524a

; ----------------------------------------------------------------------
; DATOS receta_5250: 5 bytes. Indice 21 de la tabla de 0x50ac
;   0x5250..0x5255  (5 bytes)
DATA_receta_5250:
	defb 008h,008h,008h,03dh,052h	; 5250

; ======================================================================
; CODIGO 0x5255..0x52bd  (104 bytes)
; ======================================================================


arranca_un_asalto:		; Borra los 512 bytes de 0xE100 a 0xE2FF, pone al jugador en la Y 0x87 y la X 0x30, deja 0x24 -el tope de la barra- en los cuatro contadores de energia, y 0xE185 a uno. Con 0xE058 a cero copia ademas a 0xE135 la semilla de diez bytes que 0x52c5 da para 0xE056
	ld hl,0e100h		;5255   ; HL = 0xE100, DE = 0xE101 y un cero
	ld de,0e101h		;5258
	ld bc,00200h		;525b   ; 512 bytes: el `ldir` los arrastra
	ld (hl),000h		;525e
	ldir		;5260
	ld a,087h		;5262   ; la Y del jugador, en el suelo
	ld (0e160h),a		;5264
	ld a,030h		;5267   ; y su X, en 0x30, o sea a la izquierda
	ld (0e161h),a		;5269
	ld a,024h		;526c   ; 0x24 a los cuatro contadores
	ld (0e116h),a		;526e
	ld (0e130h),a		;5271
	ld (0e117h),a		;5274
	ld (0e131h),a		;5277
	ld a,001h		;527a   ; 0xE185, a uno
	ld (0e185h),a		;527c
	ld a,(0e058h)		;527f   ; 0xE058 decide
	and a			;5282
	jr nz,arranca_el_otro_asalto		;5283
	ld hl,052c5h		;5285   ; la tabla de las cuatro semillas
	ld a,(0e056h)		;5288   ; indexada por 0xE056
	call indexa_una_tabla_de_punteros		;528b
	ex de,hl			;528e
	ld de,0e135h		;528f   ; los diez bytes de semilla, a 0xE135
	ld bc,0000ah		;5292
	ldir		;5295
	ld a,012h		;5297   ; 0xE180 a 0x12...
	ld (0e180h),a		;5299
	ld a,01ah		;529c   ; ...y 0xE181 a 0x1a
	ld (0e181h),a		;529e
	call por_ocho		;52a1   ; lo que salga, a 0xE16e
	ld (0e16eh),a		;52a4
	ld a,020h		;52a7   ; y 0xE169 a 0x20
	ld (0e169h),a		;52a9
	ret			;52ac
arranca_el_otro_asalto:		; Con 0xE058 puesto: 0x20 en 0xE272 y en 0xE25b, y la X del jugador en 0x80, o sea en el centro
	ld a,016h		;52ad   ; un 0x16 que se pierde: lo pisa el 0x20 de la linea siguiente
	ld a,020h		;52af
	ld (0e272h),a		;52b1   ; 0x20 a los dos
	ld (0e25bh),a		;52b4
	ld a,080h		;52b7   ; y la X del jugador, en el centro
	ld (0e161h),a		;52b9
	ret			;52bc

; ----------------------------------------------------------------------
; DATOS dos_grupos_de_cuatro: Ocho bytes en dos grupos iguales salvo el
;   primero: 80 E8 CC 07 y E0 E8 CC 07
;   0x52bd..0x52c5  (8 bytes)
DATA_dos_grupos_de_cuatro:
	defb 080h,0e8h,0cch,007h	; 52bd
	defb 0e0h,0e8h,0cch,007h	; 52c1

; ----------------------------------------------------------------------
; DATOS tabla_de_las_cuatro_semillas: Cuatro punteros que 0x5285 indexa por
;   0xE056: 0x52cd, 0x52d7, 0x52e1 y 0x52eb
;   0x52c5..0x52cd  (8 bytes)
DATA_tabla_de_las_cuatro_semillas:
	defw 052cdh,052d7h,052e1h,052ebh	; 52c5  -> DATA_semilla_0 DATA_semilla_1 DATA_semilla_2 DATA_semilla_3

; ----------------------------------------------------------------------
; DATOS semilla_0: Diez bytes que el `ldir` de 0x5295 copia enteros a 0xE135,
;   que es el registro de desplazamiento que 0x6d2c usa de generador
;   pseudoaleatorio. O sea que esto es la SEMILLA con la que arranca la
;   partida
;   0x52cd..0x52d7  (10 bytes)
DATA_semilla_0:
	defb 044h,044h,050h,050h,044h,000h,005h,09fh,044h,0e4h	; 52cd  DDPPD...D.

; ----------------------------------------------------------------------
; DATOS semilla_1: La segunda semilla
;   0x52d7..0x52e1  (10 bytes)
DATA_semilla_1:
	defb 0e4h,022h,0e4h,012h,0e4h,0e4h,013h,0e4h,000h,0e4h	; 52d7  ."........

; ----------------------------------------------------------------------
; DATOS semilla_2: La tercera
;   0x52e1..0x52eb  (10 bytes)
DATA_semilla_2:
	defb 04fh,044h,0e4h,05fh,044h,0feh,025h,09fh,064h,0e4h	; 52e1  OD._D.%.d.

; ----------------------------------------------------------------------
; DATOS semilla_3: Y la cuarta
;   0x52eb..0x52f5  (10 bytes)
DATA_semilla_3:
	defb 0feh,0e4h,0e7h,0eeh,0f7h,07fh,034h,04fh,0ffh,0feh	; 52eb  ......4O..

; ======================================================================
; CODIGO 0x52f5..0x54b8  (451 bytes)
; ======================================================================


monta_las_cajas_de_golpe:		; Coge (0xE16e) y le suma los cuatro primeros bytes de la receta del oponente, y con cada uno escribe una PAREJA en 0xE198: el valor y el valor mas 10, mas 8, mas 6 y mas 6. Son las cuatro cajas horizontales que 0x4a0f consulta. Del quinto byte sale (0xE183), sumandole (0xE181)
	ld hl,0e16eh		;52f5   ; HL = 0xE16e
	ld a,(hl)			;52f8
	ld c,a			;52f9
	ld hl,0e198h		;52fa   ; DE = 0xE198, la primera caja
	ex de,hl			;52fd
	add a,(hl)			;52fe   ; el principio de la caja...
	ld (de),a			;52ff
	inc de			;5300
	add a,00ah		;5301   ; ...y diez mas alla, su final
	ld (de),a			;5303
	inc hl			;5304
	inc de			;5305
	ld a,c			;5306
	add a,(hl)			;5307   ; la segunda...
	ld (de),a			;5308
	inc de			;5309
	add a,008h		;530a   ; ...con ocho de ancho
	ld (de),a			;530c
	inc hl			;530d
	ld b,002h		;530e   ; y las dos ultimas, de seis
las_dos_cajas_de_seis:		; El mismo par dos veces, con seis de anchura
	inc de			;5310
	ld a,c			;5311
	add a,(hl)			;5312   ; el principio
	ld (de),a			;5313
	inc de			;5314
	add a,006h		;5315   ; y seis mas alla
	ld (de),a			;5317
	inc hl			;5318
	djnz las_dos_cajas_de_seis		;5319
	ex de,hl			;531b
	ld hl,0e181h		;531c   ; HL = 0xE181
	ex de,hl			;531f
	ld a,(de)			;5320
	add a,(hl)			;5321
	ld (0e183h),a		;5322   ; (0xE183) := (0xE181) mas lo que diga la receta
	inc hl			;5325
monta_al_oponente:		; Lee de la receta 0xE182 -la fila-, y luego los campos con nibble alto 0x7- y 0x8-: el primero deja su nibble bajo en 0xE173, el mapa de bits de los golpes; el segundo, en 0xE1b1, y ademas calcula 0xE1b0 sumando o restando a (0xE16e) segun el bit 0 de la pose
	call la_receta_del_otro_lado		;5326   ; el primer campo de la receta
	ld de,0e180h		;5329
	ld a,(de)			;532c   ; (0xE182) := (0xE180) mas el dato
	add a,(hl)			;532d
	ld (0e182h),a		;532e
	inc hl			;5331
	ex de,hl			;5332
	xor a			;5333
	ld (0e1b0h),a		;5334   ; 0xE1b0 y 0xE173, borrados
	ld (0e173h),a		;5337
	ld a,(de)			;533a
	and 0f0h		;533b   ; el nibble alto
	cp 070h		;533d   ; el 0x7-...
	jr nz,monta_al_oponente_si_no		;533f
	ld a,(de)			;5341
	and 00fh		;5342
	ld (0e173h),a		;5344   ; ...deja su nibble bajo en 0xE173
	inc de			;5347
monta_al_oponente_si_no:		; Dentro de monta_al_oponente
	ld a,(de)			;5348
	and 0f0h		;5349   ; el nibble alto del siguiente
	cp 080h		;534b   ; el 0x8-...
	jr nz,monta_al_oponente_si_no_3		;534d
	ld a,(de)			;534f
	and 00fh		;5350
	ld (0e1b1h),a		;5352   ; ...deja el suyo en 0xE1b1
	inc de			;5355
	ld hl,0e16eh		;5356
	ld a,(0e184h)		;5359   ; el bit 0 de la pose dice el signo
	rra			;535c
	ld a,(de)			;535d
	jr nc,monta_al_oponente_si_no_2		;535e
	neg		;5360   ; hacia el otro lado
monta_al_oponente_si_no_2:		; Dentro de monta_al_oponente
	add a,(hl)			;5362   ; mas (0xE16e)
	ld (0e1b0h),a		;5363
	inc de			;5366
monta_al_oponente_si_no_3:		; Dentro de monta_al_oponente
	ld a,(de)			;5367   ; y los dos siguientes son alto y ancho
	ld b,a			;5368
	inc de			;5369
	ld a,(de)			;536a
	ld c,a			;536b
	ld (0e104h),bc		;536c
	inc de			;5370
	call descomprime_la_pose		;5371
dibuja_el_bloque_de_tiles:		; Baja hasta la fila que diga 0xE182 y dibuja el bloque columna a columna, recortando lo que se salga de la pantalla por cualquiera de los dos lados
	ld hl,0e182h		;5374   ; HL = 0xE182, la fila
	ld a,(hl)			;5377
	and a			;5378
	ld hl,03800h		;5379   ; HL = VRAM 0x3800, la tabla de nombres
	jr z,dibuja_el_bloque_de_tiles_si_no		;537c
	dec a			;537e
	ld b,a			;537f
dibuja_el_bloque_de_tiles_otra_vuelta:		; Dentro de dibuja_el_bloque_de_tiles
	ld a,020h		;5380   ; 0x20 por cada fila que haya que bajar
	call suma_a_hl		;5382
	djnz dibuja_el_bloque_de_tiles_otra_vuelta		;5385
dibuja_el_bloque_de_tiles_si_no:		; Dentro de dibuja_el_bloque_de_tiles
	ld a,(0e183h)		;5387   ; 0xE183, la columna
	ld b,a			;538a
	cp 001h		;538b   ; negativa quiere decir salirse por la izquierda
	jr nc,dibuja_el_bloque_de_tiles_si_no_2		;538d
	add a,c			;538f
	jr dibuja_el_bloque_de_tiles_si_no_3		;5390
dibuja_el_bloque_de_tiles_si_no_2:		; Dentro de dibuja_el_bloque_de_tiles
	and a			;5392
	jp p,recorta_por_la_derecha		;5393
	add a,c			;5396
	ret nc			;5397
dibuja_el_bloque_de_tiles_si_no_3:		; Dentro de dibuja_el_bloque_de_tiles
	cp 002h		;5398   ; con menos de dos columnas visibles no se dibuja
	ret c			;539a
recorta_por_la_izquierda:		; Corre el origen y acorta la anchura tantas columnas como se salgan
	sub 001h		;539b
	ld b,a			;539d   ; lo que se sale
	ld a,c			;539e
	sub b			;539f
	call suma_a_de		;53a0   ; el origen, corrido
	ld c,b			;53a3   ; y la anchura, acortada
	ld a,001h		;53a4
	call suma_a_hl		;53a6
	jr una_fila_del_bloque		;53a9
recorta_por_la_derecha:		; Con la columna en 0x1f o mas no se ve nada; si no, se acorta lo que sobrepase las treinta y dos
	cp 01fh		;53ab   ; de 0x1f para arriba, fuera
	ret nc			;53ad
	add a,c			;53ae
	sub 01fh		;53af   ; lo que sobra por la derecha
	jr nc,recorta_por_la_derecha_si_no		;53b1
	ld a,b			;53b3
	call suma_a_hl		;53b4   ; el sitio, con la columna sumada
	jr una_fila_del_bloque		;53b7
recorta_por_la_derecha_si_no:		; Dentro de recorta_por_la_derecha
	sub c			;53b9
	neg		;53ba
	ld c,a			;53bc
	ld a,b			;53bd
	call suma_a_hl		;53be
una_fila_del_bloque:		; Guarda origen y anchura, copia la fila con LDIRVM, baja una fila y repite hasta agotar 0xE105
	ld (0e102h),de		;53c1   ; el origen, guardado
	ld (0e400h),bc		;53c5   ; y la anchura
	push bc			;53c9
	call copia_poniendo_b_a_cero		;53ca   ; la fila, a la VRAM
	pop bc			;53cd
	ld a,(0e105h)		;53ce
	dec a			;53d1   ; una fila menos
	ld (0e105h),a		;53d2
	ret z			;53d5
	ld a,(0e104h)		;53d6   ; el origen avanza la anchura entera
	ld de,(0e102h)		;53d9
	call suma_a_de		;53dd
	ld a,020h		;53e0   ; y el destino, una fila
	call suma_a_hl		;53e2
	jr una_fila_del_bloque		;53e5
dibuja_con_alto_y_ancho:		; Coge de la receta el alto y el ancho y se mete en el dibujador
	ld a,(de)			;53e7   ; el alto...
	ld b,a			;53e8
	inc de			;53e9
	ld a,(de)			;53ea   ; ...y el ancho
	ld c,a			;53eb
	ld (0e104h),bc		;53ec   ; los dos a 0xE104
	inc de			;53f0
	jp dibuja_el_bloque_de_tiles		;53f1
la_receta_del_otro_lado:		; Con el bit 0 de la pose puesto, la receta continua por el puntero que venga a continuacion
	ld a,(0e184h)		;53f4   ; la pose del oponente
	bit 0,a		;53f7   ; su bit 0 dice si hay que saltar
	ret z			;53f9
	ld e,(hl)			;53fa   ; el puntero, leido
	inc hl			;53fb
	ld d,(hl)			;53fc
	ex de,hl			;53fd
	ret			;53fe
descomprime_la_pose:		; Descomprime en 0xE280 y, si la pose es impar, saca ademas la version espejada en 0xE2d0. DE se queda apuntando al buffer que toque
	push bc			;53ff
	ld hl,0e280h		;5400   ; HL = 0xE280, el buffer
	call el_descompresor		;5403
	pop bc			;5406
	push bc			;5407
	ld a,(0e184h)		;5408   ; la pose del oponente
	bit 0,a		;540b   ; su bit 0: par o impar
	ld de,0e280h		;540d
	ld hl,0e2d0h		;5410   ; HL = 0xE2d0, el buffer del espejo
	jr z,descomprime_la_pose_si_no		;5413   ; la par se queda con el primero
	call espeja_el_bloque		;5415   ; y la impar se espeja
	ld de,0e2d0h		;5418
descomprime_la_pose_si_no:		; Dentro de descomprime_la_pose
	pop bc			;541b
	ret			;541c
el_descompresor:		; B filas por C columnas, y tres comandos: 0xF- para tiles correlativos, 0xE- para huecos y cualquier otro byte para un tile suelto
	xor a			;541d
el_descompresor_otra_vuelta:		; Dentro de el_descompresor
	add a,c			;541e   ; A = B por C, los tiles que hay que sacar
	djnz el_descompresor_otra_vuelta		;541f
	ld b,a			;5421   ; y esa es la cuenta
lee_un_comando:		; El nibble alto manda
	ld a,(de)			;5422
	and 0f0h		;5423   ; el nibble alto
	cp 0f0h		;5425   ; el 0xF- son tiles correlativos
	jr nz,mira_si_son_huecos		;5427
	ld a,(de)			;5429
	and 00fh		;542a   ; su nibble bajo es cuantos
	ld c,a			;542c
	inc de			;542d
	ld a,(de)			;542e   ; y el byte siguiente, el primero
escribe_correlativos:		; El tile, y el siguiente numero
	ld (hl),a			;542f   ; el tile
	inc hl			;5430
	inc a			;5431   ; y el de al lado
	dec b			;5432
	ret z			;5433   ; con la cuenta agotada, se acabo
	dec c			;5434
	jr nz,escribe_correlativos		;5435   ; hasta terminar la tirada
	inc de			;5437
	jr lee_un_comando		;5438
mira_si_son_huecos:		; El 0xE- son tiles vacios; su nibble bajo dice cuantos
	cp 0e0h		;543a   ; el 0xE-...
	jr nz,un_tile_suelto		;543c
	ld a,(de)			;543e
	and 00fh		;543f   ; ...y su nibble bajo, la cuenta
	ld c,a			;5441
escribe_huecos:		; Ceros, que en la tabla de nombres es el tile vacio
	ld (hl),000h		;5442   ; un hueco
	inc hl			;5444
	dec b			;5445
	ret z			;5446   ; con la cuenta agotada, se acabo
	dec c			;5447
	jr nz,escribe_huecos		;5448
	inc de			;544a
	jr lee_un_comando		;544b
un_tile_suelto:		; Cualquier otro byte va tal cual
	ld a,(de)			;544d
	ld (hl),a			;544e   ; el tile, copiado
	inc de			;544f
	inc hl			;5450
	djnz lee_un_comando		;5451
	ret			;5453
espeja_el_bloque:		; Reescribe el bloque de derecha a izquierda, fila a fila, cambiando cada tile por su gemelo: mas 0x78 los de 0x10 a 0x87 y menos 0x78 los de 0x88 para arriba. Los menores de 0x10 -que son la fuente y los huecos- se quedan como estan
	ld a,c			;5454   ; al final de la fila
	dec a			;5455
	call suma_a_de		;5456
	push de			;5459
	push bc			;545a
espeja_el_bloque_otra_vuelta:		; Dentro de espeja_el_bloque
	ld a,(de)			;545b
	cp 010h		;545c   ; por debajo de 0x10 no se toca
	jr c,espeja_el_bloque_por_aqui		;545e
	cp 088h		;5460   ; de 0x88 para arriba, se resta
	jr nc,espeja_el_bloque_si_no		;5462
	add a,078h		;5464   ; y de 0x10 a 0x87, se suma
	jr espeja_el_bloque_por_aqui		;5466
espeja_el_bloque_si_no:		; Dentro de espeja_el_bloque
	sub 078h		;5468
espeja_el_bloque_por_aqui:		; Dentro de espeja_el_bloque
	ld (hl),a			;546a   ; el tile gemelo
	inc hl			;546b
	dec de			;546c   ; y hacia atras por la fila
	dec c			;546d
	jr nz,espeja_el_bloque_otra_vuelta		;546e
	pop bc			;5470
	pop de			;5471
	inc de			;5472
	djnz espeja_el_bloque		;5473
	ret			;5475
mide_la_separacion:		; Resta la X del oponente (0xE16e) y la del jugador (0xE161), y deja en A la diferencia sin signo y en C de que lado esta cada uno: 1 con el oponente a la derecha y 0 al reves
	ld a,(0e16eh)		;5476   ; la X del oponente
	ld hl,0e161h		;5479   ; HL = 0xE161, la del jugador
	ld c,001h		;547c   ; C = 1: el oponente, a la derecha
	cp (hl)			;547e
	jr nc,mide_la_separacion_si_no		;547f
	dec c			;5481   ; y si no, C = 0
	ld b,a			;5482
	ld a,(hl)			;5483
	sub b			;5484   ; la resta, del otro lado
	jr en_que_tramo_cae		;5485
mide_la_separacion_si_no:		; Dentro de mide_la_separacion
	sub (hl)			;5487   ; o de este
en_que_tramo_cae:		; Con la separacion en A, recorre los tres bytes del tramo que 0x54b8 da para este oponente y devuelve en B en cual de ellos cae
	push af			;5488
	ld a,(0e054h)		;5489   ; el oponente de turno
	ld hl,054b8h		;548c   ; la tabla de los cinco tramos
	call indexa_una_tabla_de_punteros		;548f
	ex de,hl			;5492
	pop af			;5493
	ld b,000h		;5494   ; B = 0, el primer tramo
	cp (hl)			;5496   ; por debajo del primero, ya esta
	jr c,apunta_de_que_lado_esta		;5497
	inc b			;5499
	inc hl			;549a
	cp (hl)			;549b
	jr c,apunta_de_que_lado_esta		;549c
	inc b			;549e
	inc hl			;549f
	cp (hl)			;54a0
	jr c,apunta_de_que_lado_esta		;54a1
	inc b			;54a3
	cp 040h		;54a4
	jr c,apunta_de_que_lado_esta		;54a6
	inc b			;54a8
	cp 048h		;54a9
	jr c,apunta_de_que_lado_esta		;54ab
	inc b			;54ad
	cp 068h		;54ae
	jr c,apunta_de_que_lado_esta		;54b0
	inc b			;54b2
apunta_de_que_lado_esta:		; El lado que salio de 0x5476 se guarda en 0xE185
	ld a,c			;54b3   ; el lado, guardado
	ld (0e185h),a		;54b4
	ret			;54b7

; ----------------------------------------------------------------------
; DATOS tabla_de_los_cinco_tramos: Cinco punteros que 0x548f indexa: 0x54c2,
;   0x54c5, 0x54c8, 0x54cb y 0x54ce
;   0x54b8..0x54c2  (10 bytes)
DATA_tabla_de_los_cinco_tramos:
	defw 054c2h,054c5h,054c8h,054cbh,054ceh	; 54b8

; ----------------------------------------------------------------------
; DATOS tramos_de_tres: Cinco grupos de tres bytes seguidos, que 0x5496
;   recorre comparando con A hasta que uno se pasa: 14 18 26 / 14 18 22 / 14
;   18 22 / 1A 1E 28 / 1B 1F 28. Los dos de en medio son identicos
;   0x54c2..0x54d1  (15 bytes)
DATA_tramos_de_tres:
	defb 014h,018h,026h	; 54c2
	defb 014h,018h,022h	; 54c5
	defb 014h,018h,022h	; 54c8
	defb 01ah,01eh,028h	; 54cb
	defb 01bh,01fh,028h	; 54ce

; ======================================================================
; CODIGO 0x54d1..0x550e  (61 bytes)
; ======================================================================


por_ocho:		; Tres `add a,a` seguidos, o sea A por ocho: pasa de una fila de tiles a su Y en pixeles
	add a,a			;54d1   ; por dos...
	add a,a			;54d2   ; ...por cuatro...
	add a,a			;54d3   ; ...y por ocho
	ret			;54d4
elige_el_movimiento_del_oponente:		; Baja 0xE16b en uno y con lo que quede busca tramo entre los tres bytes que 0x550e da para 0xE056. El numero de tramo indexa la lista que 0x16a haya elegido, y el valor que salga sube uno si el jugador esta a la derecha
	ld a,(0e16ah)		;54d5   ; 0xE16a elige la lista
	call indexa_una_tabla_de_punteros		;54d8
	ld b,000h		;54db   ; B = 0, el primer tramo
	ld hl,0e16bh		;54dd   ; HL = 0xE16b
	dec (hl)			;54e0   ; uno menos
	ld a,(hl)			;54e1
	push af			;54e2
	push de			;54e3
	ld a,(0e056h)		;54e4   ; la dificultad de 0xE056
	ld hl,0550eh		;54e7   ; elige los tres topes
	call indexa_una_tabla_de_punteros		;54ea
	ex de,hl			;54ed
	pop de			;54ee
	pop af			;54ef
	cp (hl)			;54f0   ; por debajo del primero, tramo 0
	jr nc,elige_el_movimiento_del_oponente_por_aqui		;54f1
	inc b			;54f3
	inc hl			;54f4
	cp (hl)			;54f5   ; del segundo, tramo 1
	jr nc,elige_el_movimiento_del_oponente_por_aqui		;54f6
	inc b			;54f8
	inc hl			;54f9
	cp (hl)			;54fa   ; del tercero, tramo 2
	jr nc,elige_el_movimiento_del_oponente_por_aqui		;54fb
	inc b			;54fd   ; y si no, tramo 3
elige_el_movimiento_del_oponente_por_aqui:		; Dentro de elige_el_movimiento_del_oponente
	ld a,b			;54fe
	call suma_a_de		;54ff   ; el tramo indexa la lista
	ld a,(0e185h)		;5502   ; el lado en que esta el jugador
	and a			;5505
	ld a,(de)			;5506
	jr nz,fija_la_pose_del_oponente		;5507
	inc a			;5509   ; a la derecha, uno mas
fija_la_pose_del_oponente:		; El valor elegido va a 0xE184
	ld (0e184h),a		;550a   ; la pose, puesta
	ret			;550d

; ----------------------------------------------------------------------
; DATOS tabla_de_los_cuatro_tramos: Cuatro punteros que 0x54ea indexa: 0x5516,
;   0x5519, 0x551c y 0x551f
;   0x550e..0x5516  (8 bytes)
DATA_tabla_de_los_cuatro_tramos:
	defw 05516h,05519h,0551ch,0551fh	; 550e  -> DATA_tramos_de_tres_mas 0x5519 0x551c 0x551f

; ----------------------------------------------------------------------
; DATOS tramos_de_tres_mas: Cuatro grupos de tres, que 0x54f0 recorre igual:
;   14 0D 02 / 0F 0A 02 / 0C 09 02 / 08 04 01. Los tres primeros valores bajan
;   a la vez, o sea que es una escala
;   0x5516..0x5522  (12 bytes)
DATA_tramos_de_tres_mas:
	defb 014h,00dh,002h	; 5516
	defb 00fh,00ah,002h	; 5519
	defb 00ch,009h,002h	; 551c
	defb 008h,004h,001h	; 551f

; ======================================================================
; CODIGO 0x5522..0x555c  (58 bytes)
; ======================================================================


borra_y_recoloca_al_oponente:		; Borra las cinco filas de treinta tiles que empiezan en la VRAM 0x3a01 -donde estaba dibujado-, pasa su fila y su columna a pixeles, y con el oponente de 0xE054 y la pose de 0xE184 vuelve a montar las cajas de golpe
	ld hl,03a01h		;5522   ; HL = VRAM 0x3a01, fila 16 columna 1
	ld b,005h		;5525   ; cinco filas
borra_una_fila_de_treinta:		; Treinta tiles a cero y a la fila de abajo
	push bc			;5527
	ld bc,0001eh		;5528   ; treinta tiles
	xor a			;552b
	call 00056h		;552c   ; BIOS FILVRM - Fills VRAM with value | a cero
	ld a,020h		;552f   ; 0x20: la fila siguiente
	call suma_a_hl		;5531
	pop bc			;5534
	djnz borra_una_fila_de_treinta		;5535
	ld hl,0e180h		;5537   ; HL = 0xE180, la fila en tiles
	ld de,0e16dh		;553a   ; DE = 0xE16d, la Y en pixeles
	ld a,(hl)			;553d
	call por_ocho		;553e   ; la fila por ocho
	ld (de),a			;5541
	inc hl			;5542
	inc de			;5543
	ld a,(hl)			;5544
	call por_ocho		;5545   ; y la columna por ocho, que es la X
	ld (de),a			;5548
	ld hl,0555ch		;5549   ; la tabla de los cinco oponentes
	ld a,(0e054h)		;554c   ; por 0xE054
	call indexa_una_tabla_de_punteros		;554f
	ex de,hl			;5552
	ld a,(0e184h)		;5553   ; y el resultado, por la pose
	call indexa_una_tabla_de_punteros		;5556
	jp monta_las_cajas_de_golpe		;5559

; ----------------------------------------------------------------------
; DATOS tabla_de_poses_por_oponente: Cinco punteros indexados por 0xE054 desde
;   0x5549: 0x6d4b, 0x6efa, 0x71fb, 0x7621 y 0x785c. Cada uno es a su vez una
;   tabla, porque 0x5553 vuelve a indexar el resultado por 0xE184, la pose. O
;   sea: primero el oponente, despues su pose
;   0x555c..0x5566  (10 bytes)
DATA_tabla_de_poses_por_oponente:
	defw 06d4bh,06efah,071fbh,07621h,0785ch	; 555c

; ----------------------------------------------------------------------
; DATOS lista_del_marcador: Los cuatro rotulos fijos del marcador, que 0x4384
;   dibuja antes de escribir las cifras: HI SCORE en la fila 0 columna 11,
;   STAGE en la 0/21, SCORE en la 0/3 y REST en la 1/21. Encadena tres veces
;   con 0xFE
;   0x5566..0x558a  (36 bytes)
DATA_lista_del_marcador:
	defb 00bh,038h,028h,029h,020h,033h,023h,02fh,032h,025h,0feh,015h,038h,033h,034h,021h	; 5566  .8() 3#/2%..834!
	defb 027h,025h,020h,0feh,003h,038h,033h,023h,02fh,032h,025h,0feh,035h,038h,032h,025h	; 5576  '% ..83#/2%.582%
	defb 033h,034h,020h,0ffh	; 5586

; ----------------------------------------------------------------------
; DATOS lista_de_play_start: PLAY START, con dos espacios a cada lado, en la
;   fila 16 columna 9. La de la escena 3: el bit 2 del plazo de 0xE004 decide
;   si 0x412c la borra o la dibuja, y como ese bit cambia cada cuatro cuadros,
;   el rotulo parpadea
;   0x558a..0x559b  (17 bytes)
DATA_lista_de_play_start:
	defb 009h,03ah,000h,000h,030h,02ch,021h,039h,000h,033h,034h,021h,032h,034h,000h,000h	; 558a  .:..0,!9.34!24..
	defb 0ffh	; 559a

; ----------------------------------------------------------------------
; DATOS lista_de_push_space_key: PUSH SPACE KEY en la fila 16 columna 9, y
;   encadenado detras el (C) KONAMI 1985 de la fila 9 columna 10. El circulo
;   del copyright es el tile 0x1A. Es la segunda de las dos que dibuja 0x4402
;   0x559b..0x55bb  (32 bytes)
DATA_lista_de_push_space_key:
	defb 009h,03ah,030h,035h,033h,028h,000h,033h,030h,021h,023h,025h,000h,02bh,025h,039h	; 559b  .:053(.30!#%.+%9
	defb 0feh,02ah,039h,01ah,02bh,02fh,02eh,021h,02dh,029h,000h,011h,019h,018h,015h,0ffh	; 55ab  .*9.+/.!-)......

; ----------------------------------------------------------------------
; DATOS lista_de_game_over: GAME  OVER -con dos espacios en medio- en la fila
;   11 columna 11. La dibuja 0x41fd al acabarse la partida, justo antes de
;   poner la melodia 0x8f
;   0x55bb..0x55c8  (13 bytes)
DATA_lista_de_game_over:
	defb 06bh,039h,027h,021h,02dh,025h,000h,000h,02fh,036h,025h,032h,0ffh	; 55bb  k9'!-%../6%2.

; ----------------------------------------------------------------------
; DATOS lista_de_video_cartridge: VIDEO CARTRIDGE, centrado en la fila 11
;   columna 6 con un espacio a cada lado. La dibuja 0x40bf uno de cada dos
;   cuadros mientras 0x45c7 diga que si
;   0x55c8..0x55de  (22 bytes)
DATA_lista_de_video_cartridge:
	defb 066h,039h,020h,000h,036h,029h,024h,025h,02fh,000h,023h,021h,032h,034h,032h,029h	; 55c8  f9 .6)$%/.#!242)
	defb 024h,027h,025h,000h,020h,0ffh	; 55d8

; ----------------------------------------------------------------------
; DATOS secuencia_de_la_atraccion: Cuarenta y ocho valores de 0x00 a 0x12 y un
;   0xFF al final. 0x4564 avanza el indice de 0xE00C cada 0x20 cuadros, lee el
;   valor y vuelve; cuando le sale el 0xFF de 0x560e, lo escribe en 0xE106 y
;   con eso se cierra la vuelta. Los cuarenta y ocho van en tres tramos que
;   empiezan los tres por 0x01: quince, quince y dieciocho
;   0x55de..0x560f  (49 bytes)
DATA_secuencia_de_la_atraccion:
	defb 001h,008h,000h,011h,008h,012h,006h,005h,011h,010h,012h,011h,010h,004h,000h,001h	; 55de  ................
	defb 010h,000h,011h,008h,004h,006h,005h,011h,010h,012h,011h,010h,004h,000h,001h,004h	; 55ee  ................
	defb 004h,008h,008h,011h,010h,012h,005h,000h,006h,010h,000h,011h,000h,005h,004h,000h	; 55fe  ................
	defb 0ffh	; 560e

; ======================================================================
; CODIGO 0x560f..0x564c  (61 bytes)
; ======================================================================


pinta_el_color_de_los_dieciseis:		; Los tres tercios, cada uno con los dieciseis primeros tiles de color uniforme
	ld hl,00000h		;560f   ; el primer tercio
	call dieciseis_colores_seguidos		;5612
	ld hl,00800h		;5615   ; el segundo
	call dieciseis_colores_seguidos		;5618
	ld hl,01000h		;561b   ; y el tercero
	call dieciseis_colores_seguidos		;561e
	jp monta_el_fondo_de_pantalla		;5621
dieciseis_colores_seguidos:		; Ocho bytes de 0x00, ocho de 0x11, ocho de 0x22 y asi hasta el 0xFF: los dieciseis primeros tiles de un tercio, cada uno de un color plano
	xor a			;5624   ; A = 0, el primer color
	ld c,010h		;5625   ; dieciseis tiles
dieciseis_colores_seguidos_otra_vuelta:		; Dentro de dieciseis_colores_seguidos
	ld b,008h		;5627   ; ocho bytes por tile
dieciseis_colores_seguidos_otra_vuelta_2:		; Dentro de dieciseis_colores_seguidos
	call 0004dh		;5629   ; BIOS WRTVRM - Writes data in VRAM
	inc hl			;562c
	djnz dieciseis_colores_seguidos_otra_vuelta_2		;562d
	add a,011h		;562f   ; 0x11 mas: el color siguiente
	dec c			;5631
	jr nz,dieciseis_colores_seguidos_otra_vuelta		;5632
	ret			;5634
monta_el_fondo_de_pantalla:		; El guion de 0x564e en la VRAM 0x2080 en los tres tercios -que es la fuente-, un relleno de 0xF0 en la 0x0080 y los dos guiones del rotulo
	ld de,0564eh		;5635   ; DE = 0x564e, el guion de la fuente
	ld hl,02080h		;5638   ; HL = VRAM 0x2080, tiles 0x10 en adelante
	call dibuja_en_los_tres_tercios		;563b
	ld hl,00080h		;563e   ; HL = VRAM 0x0080, su color
	ld a,0f0h		;5641   ; A = 0xF0, tinta blanca sobre negro
	ld bc,00250h		;5643   ; 0x250 bytes
	call rellena_los_tres_tercios		;5646
	jp dibuja_los_dos_guiones_del_fondo		;5649

; ----------------------------------------------------------------------
; DATOS resto_564c: Dos bytes, 0x00 y 0x76, entre el `jp` de 0x5649 y el guion
;   de 0x564e. Ningun puntero de toda la ROM cae en ellos -buscado con
;   tools/apunta_a.py, que mira los 16 KB y no solo el listado-, y el guion no
;   empieza aqui: 0x5635 carga 0x564e. Son restos
;   0x564c..0x564e  (2 bytes)
DATA_resto_564c:
	defb 000h,076h	; 564c

; ----------------------------------------------------------------------
; DATOS guion_del_fondo_de_pantalla: Lo primero que hace 0x5635: 0x563b lo
;   dibuja en la VRAM 0x2080, en los TRES tercios. Esa rutina monta el fondo
;   tanto al entrar en la portada (0x43ed) como al cerrar el combate (0x41f7)
;   0x564e..0x57ee  (416 bytes)
DATA_guion_del_fondo_de_pantalla:
	defb 08ah,01ch,022h,063h,063h,063h,022h,01ch,000h,018h,038h,004h,018h,0cah,07eh,000h	; 564e  .."ccc"...8...~.
	defb 03eh,063h,003h,00eh,03ch,070h,07fh,000h,03eh,063h,003h,00eh,003h,063h,03eh,000h	; 565e  >c..<p..>c...c>.
	defb 00eh,01eh,036h,066h,066h,07fh,006h,000h,07fh,060h,07eh,063h,003h,063h,03eh,000h	; 566e  ..6ff....`~c.c>.
	defb 03eh,063h,060h,07eh,063h,063h,03eh,000h,07fh,063h,006h,00ch,018h,018h,018h,000h	; 567e  >c`~cc>..c......
	defb 03eh,063h,063h,03eh,063h,063h,03eh,000h,03eh,063h,063h,03fh,003h,063h,03eh,000h	; 568e  >cc>cc>.>cc?.c>.
	defb 03ch,042h,099h,0a1h,0a1h,099h,042h,03ch,007h,000h,020h,000h,004h,000h,001h,07eh	; 569e  <B....B<.. ....~
	defb 004h,000h,0c1h,01ch,036h,063h,063h,07fh,063h,063h,000h,07eh,063h,063h,07eh,063h	; 56ae  ....6cc.cc.~cc~c
	defb 063h,07eh,000h,03eh,063h,060h,060h,060h,063h,03eh,000h,07ch,066h,063h,063h,063h	; 56be  c~.>c```c>.|fccc
	defb 066h,07ch,000h,07fh,060h,060h,07eh,060h,060h,07fh,000h,07fh,060h,060h,07eh,060h	; 56ce  f|..``~``...``~`
	defb 060h,060h,000h,03eh,063h,060h,067h,063h,063h,03fh,000h,063h,063h,063h,07fh,063h	; 56de  ``.>c`gcc?.ccc.c
	defb 063h,063h,000h,03ch,005h,018h,081h,03ch,008h,000h,089h,000h,063h,066h,06ch,078h	; 56ee  cc.<...<....cflx
	defb 07ch,06eh,067h,000h,006h,060h,093h,07fh,000h,063h,077h,07fh,07fh,06bh,063h,063h	; 56fe  |ng..`...cw..kcc
	defb 000h,063h,073h,07bh,07fh,06fh,067h,063h,000h,03eh,005h,063h,089h,03eh,000h,07eh	; 570e  .cs{.ogc.>.c.>.~
	defb 063h,063h,063h,07eh,060h,060h,009h,000h,091h,07eh,063h,063h,062h,07ch,066h,063h	; 571e  ccc~``...~ccb|fc
	defb 000h,03eh,063h,060h,03eh,003h,063h,03eh,000h,07eh,006h,018h,001h,000h,006h,063h	; 572e  .>c`>.c>.~.....c
	defb 082h,03eh,000h,004h,063h,08bh,036h,01ch,008h,000h,063h,063h,06bh,06bh,07fh,077h	; 573e  .>..c.6...cckk.w
	defb 022h,009h,000h,087h,066h,066h,07eh,03ch,018h,018h,018h,031h,000h,00eh,000h,082h	; 574e  "...ff~<...1....
	defb 007h,00fh,006h,000h,082h,0f8h,0f0h,004h,03eh,004h,03fh,08bh,01fh,03fh,07fh,0ffh	; 575e  ........>.?..?..
	defb 0feh,0fch,0f8h,0f0h,0e0h,0c0h,080h,003h,000h,002h,03eh,005h,000h,083h,01fh,07fh	; 576e  ..........>.....
	defb 0fbh,005h,000h,083h,00fh,0cfh,0efh,005h,000h,083h,078h,0fch,0bch,005h,000h,083h	; 577e  ..........x.....
	defb 03fh,07fh,0f3h,005h,000h,083h,087h,0c7h,0c7h,005h,000h,083h,0bch,0feh,0dfh,005h	; 578e  ?...............
	defb 000h,088h,078h,0fch,0bch,060h,0f0h,0f0h,060h,000h,003h,0f0h,002h,03fh,006h,03eh	; 579e  ..x..`..`....?.>
	defb 088h,0f8h,0fch,0feh,07fh,03fh,01fh,00fh,007h,003h,03eh,085h,07eh,0fch,0fch,0f8h	; 57ae  .....?....>.~...
	defb 0e0h,005h,0f1h,083h,0fbh,07fh,01fh,006h,0efh,082h,0cfh,00fh,008h,01eh,088h,0e1h	; 57be  ................
	defb 003h,03fh,0f1h,0e1h,0f3h,07fh,01eh,007h,0e7h,081h,0f7h,008h,08fh,008h,01eh,082h	; 57ce  .?..............
	defb 0f1h,0f2h,004h,0f5h,08ah,0f2h,0f1h,0e0h,010h,0c8h,068h,0c8h,028h,010h,0e0h,000h	; 57de  ..........h.(...

; ----------------------------------------------------------------------
; DATOS guion_del_color_del_fondo: Siete bytes. 0x43ff lo dibuja en la VRAM
;   0x0600, que en este cartucho es color
;   0x57ee..0x57f5  (7 bytes)
DATA_guion_del_color_del_fondo:
	defb 078h,060h,078h,060h,078h,060h,000h	; 57ee

; ----------------------------------------------------------------------
; DATOS guion_del_patron_del_fondo: Y 0x43f6 dibuja este en la 0x2600, que es
;   patron. Los dos van juntos en dibuja_los_dos_guiones_del_fondo
;   0x57f5..0x5909  (276 bytes)
DATA_guion_del_patron_del_fondo:
	defb 098h,020h,070h,078h,079h,079h,07bh,07fh,03fh,060h,0f3h,0f7h,0f7h,0e3h,0e0h,0cch	; 57f5  . pxyy{.?`......
	defb 08eh,000h,000h,080h,080h,000h,00fh,03fh,07bh,006h,000h,08ch,080h,081h,006h,00fh	; 5805  .......?{.......
	defb 01fh,03fh,07fh,07bh,0f3h,0f7h,000h,080h,003h,0c0h,003h,0c7h,005h,000h,09ch,060h	; 5815  .?.{...........`
	defb 0f0h,0f0h,01ch,03eh,03eh,03ch,07dh,07bh,07fh,0ffh,061h,073h,0f7h,0f7h,0e7h,0efh	; 5825  ...>><}{..as....
	defb 0cfh,08fh,08ch,0ceh,0cfh,0dfh,09fh,09fh,0bfh,03eh,00ch,003h,01eh,002h,03eh,093h	; 5835  .........>....>.
	defb 03fh,07fh,020h,070h,078h,079h,0f9h,0f3h,0f3h,0e7h,01fh,07fh,0ffh,0f7h,0e7h,0e0h	; 5845  ?. pxy..........
	defb 0c7h,0dfh,000h,003h,080h,084h,000h,003h,007h,08fh,005h,000h,096h,00ch,0b8h,0f3h	; 5855  ................
	defb 03fh,0ffh,0ffh,07fh,078h,0f8h,0f0h,0fch,00ch,09eh,0beh,03eh,03ch,07ch,07dh,079h	; 5865  ?...x......><|}y
	defb 060h,070h,078h,004h,0f8h,09ch,0f0h,03fh,01fh,01eh,03eh,07ch,0f8h,0f0h,060h,09eh	; 5875  `px....?..>|..`.
	defb 01eh,03ch,03ch,078h,078h,070h,030h,073h,0f7h,0ffh,0e6h,0f0h,0feh,07eh,03ch,087h	; 5885  .<<xxp0s.....~<.
	defb 083h,003h,003h,007h,082h,003h,001h,004h,0ffh,090h,0cfh,0dfh,09eh,08eh,0cfh,08fh	; 5895  ................
	defb 09fh,0beh,03eh,03ch,03ch,018h,0e0h,080h,001h,001h,003h,003h,08ah,001h,0ffh,0feh	; 58a5  ..><<...........
	defb 0ffh,0efh,0efh,0c7h,0c7h,083h,01fh,003h,01eh,08eh,09fh,0dfh,0cfh,087h,03eh,07ch	; 58b5  ..............>|
	defb 07ch,0f8h,0f9h,0f1h,0e0h,0c0h,07fh,077h,003h,0f7h,085h,0e7h,0e3h,061h,0e7h,0e7h	; 58c5  |......w.....a..
	defb 003h,0c7h,08dh,087h,083h,080h,0dfh,08fh,09fh,0bfh,0feh,0fch,0f8h,0e0h,09fh,033h	; 58d5  ...............3
	defb 006h,000h,08ch,0e1h,0c1h,003h,003h,007h,007h,003h,001h,0feh,0fch,0e0h,0e0h,003h	; 58e5  ................
	defb 0c0h,091h,080h,0f9h,0f3h,0f3h,0f7h,0ffh,0ffh,07fh,03eh,0f0h,0e0h,0e0h,0c0h,0c0h	; 58f5  ..........>.....
	defb 080h,000h,000h,000h	; 5905

; ----------------------------------------------------------------------
; DATOS lista_del_logotipo: EL ROTULO DEL JUEGO. Dos espacios en la fila 4
;   columna 11 y luego, encadenados, los tiles 0xC0 a 0xD1 en la fila 5
;   columna 7 y los 0xD2 a 0xE3 en la fila 6: treinta y seis tiles en dos
;   filas de dieciocho, que son el dibujo de YIE AR KUNG-FU. La primera de las
;   dos que dibuja 0x4402
;   0x5909..0x5938  (47 bytes)
DATA_lista_del_logotipo:
	defb 08bh,038h,000h,000h,0feh,0a7h,038h,0c0h,0c1h,0c2h,0c3h,0c4h,0c5h,0c6h,0c7h,0c8h	; 5909  .8....8.........
	defb 0c9h,0cah,0cbh,0cch,0cdh,0ceh,0cfh,0d0h,0d1h,0feh,0c7h,038h,0d2h,0d3h,0d4h,0d5h	; 5919  ...........8....
	defb 0d6h,0d7h,0d8h,0d9h,0dah,0dbh,0dch,0ddh,0deh,0dfh,0e0h,0e1h,0e2h,0e3h,0ffh	; 5929  ...............

; ======================================================================
; CODIGO 0x5938..0x595a  (34 bytes)
; ======================================================================


borra_y_esconde_todos_los_sprites:		; Deja a cero los 0x80 bytes de la tabla de atributos de 0xE0b0 y copia encima los cinco primeros bytes de 0x595a: con eso los dos primeros sprites quedan en Y = 0xE0, fuera de pantalla. Luego lo vuelca todo
	ld hl,0595ah		;5938   ; HL = 0x595a, los sprites escondidos
	push hl			;593b
	ld hl,0e0b0h		;593c   ; HL = 0xE0b0, la tabla en RAM
	push hl			;593f
	ld b,080h		;5940   ; los 0x80 bytes
borra_y_esconde_todos_los_sprites_otra_vuelta:		; Dentro de borra_y_esconde_todos_los_sprites
	ld (hl),000h		;5942   ; a cero
	inc hl			;5944
	djnz borra_y_esconde_todos_los_sprites_otra_vuelta		;5945
	pop de			;5947
	pop hl			;5948
	ld bc,00005h		;5949   ; y los cinco primeros de 0x595a encima
	ldir		;594c
vuelca_los_sprites:		; Los 0x80 bytes de 0xE0b0 a la VRAM 0x3b00, que es donde R5 pone la tabla de atributos
	ld bc,00080h		;594e   ; los 0x80 bytes
	ld hl,03b00h		;5951   ; a la VRAM 0x3b00
	ld de,0e0b0h		;5954   ; desde 0xE0b0
	jp copia_a_vram		;5957

; ----------------------------------------------------------------------
; DATOS sprites_ocultos: Cinco entradas de atributo de sprite seguidas, las
;   cinco `E0 00 00 00`: Y = 0xE0, o sea 224, muy por debajo de la ultima
;   linea visible. El `ldir` de 0x594c copia SOLO CINCO de estos veinte bytes
;   a 0xE0B0 -y le basta, porque 0x5942 acaba de dejar los 0x80 bytes de ahi a
;   cero-, asi que los quince ultimos no los lee nadie. Buscado con
;   apunta_a.py: ninguna otra direccion de la ROM apunta dentro de este bloque
;   0x595a..0x596e  (20 bytes)
DATA_sprites_ocultos:
	defb 0e0h,000h,000h,000h	; 595a
	defb 0e0h,000h,000h,000h	; 595e
	defb 0e0h,000h,000h,000h	; 5962
	defb 0e0h,000h,000h,000h	; 5966
	defb 0e0h,000h,000h,000h	; 596a

; ======================================================================
; CODIGO 0x596e..0x596f  (1 bytes)
; ======================================================================


no_hace_nada:		; Un `ret` suelto al que se llama por su nombre desde 0x4b92
	ret			;596e   ; y ya

; ----------------------------------------------------------------------
; DATOS guion_del_luchador_00: Destino incrustado 0x1820; por la tabla va a la
;   VRAM 0x1a00
;   0x596f..0x5998  (41 bytes)
DATA_guion_del_luchador_00:
	defb 020h,018h,00ah,000h,086h,01fh,03fh,07fh,077h,060h,040h,00bh,000h,084h,080h,0c0h	; 596f   .....?.w`@.....
	defb 040h,040h,009h,000h,088h,008h,01fh,0bfh,0f5h,07fh,03dh,01bh,00eh,008h,000h,088h	; 597f  @@........=.....
	defb 080h,080h,0c0h,0c0h,080h,080h,000h,000h,000h	; 598f  .........

; ----------------------------------------------------------------------
; DATOS guion_del_luchador_01: Destino incrustado 0x1860; por la tabla, 0x1a40
;   0x5998..0x59f0  (88 bytes)
DATA_guion_del_luchador_01:
	defb 060h,018h,08ah,060h,0f0h,0f8h,0ffh,0eeh,0f1h,0ffh,05fh,060h,03fh,006h,000h,08ah	; 5998  `..`......_`?...
	defb 030h,07dh,0ffh,0ffh,077h,0b0h,0b0h,030h,0e0h,0e0h,00fh,000h,084h,0e0h,0c0h,0c0h	; 59a8  0}..w..0........
	defb 080h,014h,000h,083h,001h,003h,003h,005h,007h,084h,003h,001h,003h,00fh,003h,000h	; 59b8  ................
	defb 081h,07fh,004h,0ffh,081h,0f8h,003h,0e0h,084h,0c0h,080h,0c0h,0c0h,003h,000h,082h	; 59c8  ................
	defb 0f8h,0feh,003h,0ffh,081h,07fh,003h,01fh,084h,00fh,006h,00fh,00fh,007h,000h,005h	; 59d8  ................
	defb 080h,003h,000h,081h,0c0h,003h,000h,000h	; 59e8  ........

; ----------------------------------------------------------------------
; DATOS guion_del_luchador_02: Destino incrustado 0x1860; por la tabla, 0x1ac0
;   0x59f0..0x5a41  (81 bytes)
DATA_guion_del_luchador_02:
	defb 060h,018h,089h,018h,03fh,07fh,0ffh,0ddh,0deh,05fh,03fh,03fh,007h,000h,082h,0e0h	; 59f0  `...?...._??....
	defb 0feh,003h,0ffh,081h,000h,003h,0e0h,010h,000h,084h,0e0h,0f8h,0f8h,038h,018h,000h	; 5a00  .............8..
	defb 088h,001h,003h,00fh,03fh,07fh,077h,070h,038h,003h,000h,08ah,03fh,07fh,07fh,0ffh	; 5a10  ....?.wp8...?...
	defb 0ffh,0feh,0fch,0fch,0f8h,0e0h,006h,000h,082h,0f8h,0feh,003h,0ffh,081h,07fh,003h	; 5a20  ................
	defb 01fh,084h,00fh,006h,00fh,00fh,007h,000h,005h,080h,003h,000h,081h,0c0h,003h,000h	; 5a30  ................
	defb 000h	; 5a40

; ----------------------------------------------------------------------
; DATOS guion_del_luchador_03: Destino incrustado 0x1860; por la tabla, 0x1b40
;   0x5a41..0x5a8d  (76 bytes)
DATA_guion_del_luchador_03:
	defb 060h,018h,088h,000h,003h,007h,008h,017h,017h,016h,018h,008h,000h,089h,0e0h,0f0h	; 5a41  `...............
	defb 0f8h,0fch,07eh,07fh,07fh,0ffh,0c0h,010h,000h,087h,007h,00fh,01fh,03dh,0fch,0f8h	; 5a51  ..~..........=..
	defb 0f8h,00ah,000h,090h,080h,0e0h,0d8h,0bch,05ch,000h,03fh,0ffh,0ffh,0f3h,06fh,01fh	; 5a61  ........\.?...o.
	defb 03fh,038h,01eh,00fh,006h,000h,083h,0bfh,0dfh,0efh,003h,0f7h,084h,0efh,01fh,0e0h	; 5a71  ?8..............
	defb 070h,007h,000h,081h,080h,004h,0c0h,081h,080h,019h,000h,000h	; 5a81  p...........

; ----------------------------------------------------------------------
; DATOS guion_del_luchador_04: Destino incrustado 0x1860; por la tabla, 0x1bc0
;   0x5a8d..0x5ae3  (86 bytes)
DATA_guion_del_luchador_04:
	defb 060h,018h,088h,01eh,07fh,0ffh,0ffh,0e3h,0f1h,071h,001h,00ah,000h,083h,080h,0c1h	; 5a8d  `........q......
	defb 0e3h,003h,0ffh,082h,0fch,0e0h,00fh,000h,081h,078h,003h,0ffh,083h,0e0h,0c0h,0e0h	; 5a9d  .........x......
	defb 00bh,000h,083h,0e0h,0f0h,070h,004h,000h,087h,003h,01fh,07fh,03fh,07fh,0f8h,0f7h	; 5aad  .....p......?...
	defb 003h,0ffh,081h,07fh,003h,000h,005h,0ffh,087h,081h,07eh,078h,0f0h,0e0h,0e0h,0c0h	; 5abd  ..........~x....
	defb 004h,000h,082h,0e0h,0fch,003h,0ffh,083h,001h,000h,001h,00bh,000h,081h,0c0h,003h	; 5acd  ................
	defb 0e0h,081h,0c0h,008h,000h,000h	; 5add

; ----------------------------------------------------------------------
; DATOS guion_del_luchador_05: Destino incrustado 0x1840; por la tabla, 0x1c40
;   0x5ae3..0x5b48  (101 bytes)
DATA_guion_del_luchador_05:
	defb 040h,018h,083h,007h,003h,002h,004h,000h,081h,063h,003h,0ffh,002h,07fh,002h,03fh	; 5ae3  @........c.....?
	defb 081h,00fh,003h,000h,002h,00eh,082h,007h,0f7h,003h,0ffh,086h,0dfh,0eeh,0f0h,0e0h	; 5af3  ................
	defb 0c0h,080h,00ah,000h,082h,003h,00fh,003h,07fh,081h,0ffh,006h,000h,084h,007h,00fh	; 5b03  ................
	defb 01eh,0fch,003h,0f0h,08bh,0e0h,0c0h,080h,003h,003h,007h,00fh,01fh,01fh,03fh,03fh	; 5b13  ..............??
	defb 003h,07fh,085h,07eh,03ch,018h,03ch,0fch,003h,0ffh,087h,0feh,0f8h,0f0h,0e0h,0c0h	; 5b23  ...~<.<.........
	defb 080h,080h,006h,000h,084h,007h,00fh,01fh,03fh,00ch,000h,086h,0ffh,0fch,0f8h,0e0h	; 5b33  ........?.......
	defb 0c0h,080h,00ah,000h,000h	; 5b43

; ----------------------------------------------------------------------
; DATOS guion_del_luchador_06: Destino incrustado 0x1820; por la tabla, 0x1cc0
;   0x5b48..0x5b5b  (19 bytes)
DATA_guion_del_luchador_06:
	defb 020h,018h,007h,000h,082h,03eh,07fh,005h,0ffh,082h,07eh,038h,009h,000h,005h,080h	; 5b48   ....>....~8....
	defb 002h,000h,000h	; 5b58

; ----------------------------------------------------------------------
; DATOS guion_del_luchador_07: Destino incrustado 0x1840; por la tabla, 0x1ce0
;   0x5b5b..0x5b85  (42 bytes)
DATA_guion_del_luchador_07:
	defb 040h,018h,007h,000h,099h,063h,0ffh,0ffh,0ffh,07fh,07fh,03fh,03fh,00fh,070h,030h	; 5b5b  @....c.....??.p0
	defb 020h,000h,000h,00fh,0ffh,0ffh,0ffh,0fch,0fch,0fch,0feh,0f8h,0f0h,0c0h,00ah,000h	; 5b6b   ...............
	defb 086h,00ch,01ch,07ch,0f8h,0f0h,0c0h,010h,000h,000h	; 5b7b  ...|......

; ----------------------------------------------------------------------
; DATOS guion_del_luchador_08: Destino incrustado 0x1880; por la tabla, 0x1d20
;   0x5b85..0x5bbe  (57 bytes)
DATA_guion_del_luchador_08:
	defb 080h,018h,002h,000h,08ah,01fh,07fh,0ffh,0ffh,0dfh,0efh,070h,01fh,001h,007h,004h	; 5b85  ...........p....
	defb 000h,082h,007h,01fh,005h,0ffh,085h,0f0h,000h,0e0h,0c0h,080h,004h,000h,081h,0f0h	; 5b95  ................
	defb 006h,0ffh,081h,01fh,00ah,000h,088h,0c0h,0f0h,0fch,0feh,0ffh,0ffh,03fh,001h,016h	; 5ba5  .............?..
	defb 000h,084h,00eh,00fh,00fh,00eh,00ch,000h,000h	; 5bb5  .........

; ----------------------------------------------------------------------
; DATOS guion_del_luchador_09: Destino incrustado 0x18a0; por la tabla, 0x1d80
;   0x5bbe..0x5be2  (36 bytes)
DATA_guion_del_luchador_09:
	defb 0a0h,018h,0a0h,03fh,07fh,07fh,0ffh,0ffh,0fch,0f8h,0fch,07eh,03eh,00ch,01eh,07eh	; 5bbe  ...?.......~>..~
	defb 000h,000h,000h,0f8h,0fch,0fch,0feh,0feh,07eh,03eh,07eh,0fch,0f8h,060h,0f0h,0fch	; 5bce  ........~>~..`..
	defb 000h,000h,000h,000h	; 5bde

; ----------------------------------------------------------------------
; DATOS guion_del_luchador_10: Destino incrustado 0x1860; por la tabla,
;   0x1da0. Cinco bytes: un relleno de 96 ceros y el fin
;   0x5be2..0x5be7  (5 bytes)
DATA_guion_del_luchador_10:
	defb 060h,018h,060h,000h,000h	; 5be2

; ----------------------------------------------------------------------
; DATOS guion_del_luchador_11: Destino incrustado 0x1880; por la tabla, 0x1e00
;   0x5be7..0x5c26  (63 bytes)
DATA_guion_del_luchador_11:
	defb 080h,018h,002h,003h,086h,007h,00fh,01fh,01fh,03fh,03fh,003h,07fh,085h,07eh,03ch	; 5be7  .........??...~<
	defb 018h,03ch,0fch,005h,0ffh,085h,0f0h,0e0h,0c0h,080h,080h,006h,000h,083h,01ch,03fh	; 5bf7  .<.............?
	defb 0ffh,01dh,000h,08ah,0fch,0ffh,0ffh,0e7h,0dfh,05fh,03fh,01fh,007h,003h,008h,000h	; 5c07  ........._?.....
	defb 084h,080h,0c0h,0e0h,0e0h,003h,0f0h,084h,0f8h,03ch,01eh,00fh,003h,000h,000h	; 5c17  .........<.....

; ----------------------------------------------------------------------
; DATOS guion_del_luchador_12: Destino incrustado 0x1820; por la tabla,
;   0x1e60. El mas largo de los trece
;   0x5c26..0x5d02  (220 bytes)
DATA_guion_del_luchador_12:
	defb 020h,018h,088h,0fch,03ch,018h,03ch,07eh,0feh,0e2h,0dch,005h,0ffh,002h,07fh,081h	; 5c26   ...<.<~........
	defb 01fh,009h,000h,081h,087h,006h,0ffh,088h,03fh,03ch,018h,03ch,07eh,07fh,047h,03bh	; 5c36  ........?<.<~.G;
	defb 005h,0ffh,002h,0feh,081h,0f8h,01dh,000h,083h,087h,0dfh,07fh,00dh,000h,002h,080h	; 5c46  ................
	defb 081h,0e0h,00dh,000h,002h,001h,081h,007h,00dh,000h,087h,0e1h,0fbh,0feh,000h,033h	; 5c56  ...............3
	defb 033h,000h,003h,021h,002h,000h,081h,021h,006h,03fh,089h,0f0h,0c0h,080h,0e0h,0f8h	; 5c66  3..!...!.?......
	defb 0fch,0c6h,0bah,07fh,004h,0ffh,002h,0feh,081h,0f8h,008h,000h,088h,008h,01fh,0b5h	; 5c76  ................
	defb 0f5h,07fh,035h,01bh,00eh,008h,000h,002h,080h,002h,0c0h,002h,080h,002h,000h,087h	; 5c86  ..5.............
	defb 002h,004h,00fh,00fh,01fh,00fh,003h,009h,000h,087h,050h,080h,0b4h,0e0h,0fdh,0e0h	; 5c96  ..........P.....
	defb 088h,009h,000h,086h,020h,030h,04ch,0c8h,030h,010h,01ah,000h,085h,088h,070h,050h	; 5ca6  .... 0L.0.....pP
	defb 070h,088h,01bh,000h,08ah,012h,05ah,03fh,03fh,0ffh,03fh,07fh,0bfh,02ah,008h,007h	; 5cb6  p.....Z??.?..*..
	defb 000h,087h,0c0h,080h,000h,0e0h,080h,080h,040h,008h,000h,081h,091h,005h,0aah,081h	; 5cc6  ........@.......
	defb 091h,00ah,000h,005h,080h,00ah,000h,087h,0c4h,02ah,02ah,0cah,02ah,02ah,0c4h,009h	; 5cd6  .........**.**..
	defb 000h,081h,040h,005h,0a0h,081h,040h,009h,000h,087h,0e4h,08ah,08ah,0cah,02ah,02ah	; 5ce6  ..@...@.......**
	defb 0c4h,009h,000h,081h,040h,005h,0a0h,081h,040h,009h,000h,000h	; 5cf6  ....@...@...

; ----------------------------------------------------------------------
; DATOS guion_del_marcador: El guion que 0x4ccf dibuja en la VRAM 0x1e40, ya
;   sin destino incrustado: lo llama directo con la constante
;   0x5d02..0x5d74  (114 bytes)
DATA_guion_del_marcador:
	defb 089h,0f0h,0c0h,080h,0e0h,0f8h,0fch,0c6h,0bah,07fh,004h,0ffh,083h,0feh,0feh,0f8h	; 5d02  ................
	defb 013h,000h,08dh,001h,002h,003h,001h,007h,00dh,00bh,00bh,00fh,007h,007h,003h,001h	; 5d12  ................
	defb 003h,000h,085h,0c0h,020h,0e0h,0c0h,0f0h,004h,0f8h,002h,0f0h,082h,0e0h,0c0h,005h	; 5d22  .... ...........
	defb 000h,087h,03fh,01fh,02fh,037h,03ch,01ch,00fh,009h,000h,087h,0f8h,0fch,0feh,0feh	; 5d32  ..?./7<.........
	defb 092h,092h,0feh,026h,000h,085h,031h,01bh,01fh,00fh,003h,009h,000h,087h,060h,0f0h	; 5d42  ...&..1.......`.
	defb 0f8h,054h,0feh,0fch,0f8h,00ch,000h,089h,008h,004h,000h,000h,018h,000h,000h,004h	; 5d52  .T..............
	defb 008h,006h,000h,08bh,080h,088h,010h,000h,000h,00ch,000h,000h,010h,088h,080h,003h	; 5d62  ................
	defb 000h,000h	; 5d72

; ======================================================================
; CODIGO 0x5d74..0x5d8c  (24 bytes)
; ======================================================================


dibuja_el_templo:		; El guion de 0x5da4 en la VRAM 0x38a0 -o sea la tabla de NOMBRES de la fila 5 para abajo- y, con 0xE058 a cero, la cornisa de 0x5d8c en la 0x3860
	ld de,05da4h		;5d74   ; DE = 0x5da4, el templo entero
	ld hl,038a0h		;5d77   ; HL = VRAM 0x38a0, fila 5
	call dibuja_el_guion_en_el_puerto_cero		;5d7a
	ld a,(0e058h)		;5d7d   ; con 0xE058 puesto no hay cornisa
	and a			;5d80
	ret nz			;5d81
	xor a			;5d82
	ld hl,03860h		;5d83   ; HL = VRAM 0x3860, fila 3
	ld de,05d8ch		;5d86   ; DE = 0x5d8c, la cornisa
	jp dibuja_el_guion_en_el_puerto_cero		;5d89

; ----------------------------------------------------------------------
; DATOS nombres_de_la_fila_3: Veinticuatro bytes que 0x5d89 dibuja en la VRAM
;   0x3860, la fila 3 de la tabla de nombres: la cornisa del templo. Solo se
;   dibuja si 0xE058 vale cero
;   0x5d8c..0x5da4  (24 bytes)
DATA_nombres_de_la_fila_3:
	defb 004h,000h,081h,060h,009h,063h,084h,006h,05eh,05fh,006h,009h,063h,081h,0d8h,009h	; 5d8c  ...`.c..^_..c...
	defb 000h,083h,02ch,025h,025h,018h,000h,000h	; 5d9c  ..,%%...

; ----------------------------------------------------------------------
; DATOS nombres_del_templo: Los 327 que 0x5d7a dibuja en la VRAM 0x38a0, o sea
;   de la fila 5 para abajo. Es EL FONDO DEL COMBATE ENTERO -las columnas, las
;   lamparas, el cartel de dos kanjis, el gong, las ventanas y el suelo de
;   ladrillo- escrito como tiles en la tabla de nombres. El unico guion largo
;   del cartucho que no va a patrones ni a color
;   0x5da4..0x5eeb  (327 bytes)
DATA_nombres_del_templo:
	defb 0a4h,087h,081h,0f9h,087h,087h,081h,0f9h,087h,087h,081h,0f9h,087h,087h,081h,0f9h	; 5da4  ................
	defb 087h,087h,081h,0f9h,087h,087h,081h,0f9h,087h,087h,081h,0f9h,087h,087h,081h,0f9h	; 5db4  ................
	defb 087h,085h,000h,000h,061h,003h,000h,083h,061h,000h,000h,00ch,086h,002h,000h,081h	; 5dc4  ....a...a.......
	defb 061h,003h,000h,088h,061h,000h,000h,0fdh,085h,000h,000h,061h,003h,000h,092h,061h	; 5dd4  a...a......a...a
	defb 000h,000h,086h,00fh,00fh,06ch,06dh,00fh,00fh,070h,071h,00fh,00fh,086h,000h,000h	; 5de4  .....lm..pq.....
	defb 061h,003h,000h,0a8h,061h,000h,000h,0fdh,085h,000h,074h,075h,0ech,000h,074h,075h	; 5df4  a...a.....tu..tu
	defb 0ech,000h,086h,00fh,00fh,06eh,06fh,00fh,00fh,072h,073h,00fh,00fh,086h,000h,074h	; 5e04  .....no..rs....t
	defb 075h,0ech,000h,074h,075h,0ech,000h,0fdh,085h,000h,000h,062h,003h,000h,083h,062h	; 5e14  u..tu......b...b
	defb 000h,000h,00ch,086h,002h,000h,081h,062h,003h,000h,088h,062h,000h,000h,0fdh,085h	; 5e24  .......b...b....
	defb 000h,000h,062h,003h,000h,081h,062h,006h,000h,084h,076h,000h,000h,076h,006h,000h	; 5e34  ..b...b...v..v..
	defb 081h,062h,003h,000h,085h,062h,000h,000h,0fdh,085h,00dh,000h,084h,077h,078h,0f0h	; 5e44  .b...b.......wx.
	defb 0efh,00dh,000h,08ch,0fdh,085h,000h,000h,07eh,0f6h,000h,07eh,0f6h,000h,07eh,0f6h	; 5e54  ........~..~..~.
	defb 003h,000h,084h,079h,082h,084h,0f1h,003h,000h,096h,07eh,0f6h,000h,07eh,0f6h,000h	; 5e64  ...y......~..~..
	defb 07eh,0f6h,000h,000h,0fdh,085h,000h,000h,07fh,0f7h,000h,07fh,0f7h,000h,07fh,0f7h	; 5e74  ~...............
	defb 003h,000h,084h,07ah,083h,07dh,0f2h,003h,000h,096h,07fh,0f7h,000h,07fh,0f7h,000h	; 5e84  ...z.}..........
	defb 07fh,0f7h,000h,000h,0fdh,085h,000h,000h,080h,0f8h,000h,080h,0f8h,000h,080h,0f8h	; 5e94  ................
	defb 003h,000h,084h,07bh,07ch,0f4h,0f3h,003h,000h,08ch,080h,0f8h,000h,080h,0f8h,000h	; 5ea4  ...{|...........
	defb 080h,0f8h,000h,000h,0fdh,085h,01eh,000h,082h,0fdh,085h,01eh,000h,082h,0fdh,085h	; 5eb4  ................
	defb 01eh,000h,082h,0fdh,085h,01eh,000h,082h,0fdh,085h,01eh,000h,082h,0fdh,085h,01eh	; 5ec4  ................
	defb 000h,081h,0fdh,040h,087h,003h,000h,08ch,056h,057h,058h,059h,05ah,05bh,05ch,000h	; 5ed4  ...@....VWXYZ[\.
	defb 05dh,05eh,05fh,060h,011h,000h,000h	; 5ee4

; ----------------------------------------------------------------------
; DATOS oponente_0_patrones: Primer puntero de la tabla de 0x4b9c: la figura
;   de WANG. A la VRAM 0x2880, en dos tercios
;   0x5eeb..0x605b  (368 bytes)
DATA_oponente_0_patrones:
	defb 009h,003h,08fh,007h,009h,03fh,007h,017h,03fh,07fh,0c0h,0e0h,0f0h,0f0h,0f8h,0f8h	; 5eeb  .....?..?.......
	defb 0ffh,0ffh,006h,000h,084h,080h,0c0h,001h,003h,003h,007h,083h,003h,000h,000h,005h	; 5efb  ................
	defb 0ffh,083h,03fh,05fh,06fh,003h,0ffh,002h,0fbh,003h,0f7h,005h,0e0h,002h,0c0h,081h	; 5f0b  ..?_o...........
	defb 080h,004h,000h,087h,001h,003h,007h,007h,07fh,03fh,07fh,00ch,0ffh,084h,0fdh,080h	; 5f1b  .........?......
	defb 080h,0c0h,003h,0e0h,002h,0f0h,004h,007h,089h,003h,001h,007h,01fh,0ffh,0fch,0f8h	; 5f2b  ................
	defb 0f0h,0f0h,003h,0c0h,08ah,003h,01fh,00fh,007h,001h,000h,000h,001h,0f0h,0f8h,003h	; 5f3b  ................
	defb 0fch,086h,038h,07ch,0fch,080h,080h,0c0h,005h,0e0h,094h,0ffh,07fh,03fh,01fh,00fh	; 5f4b  ..8|.........?..
	defb 007h,007h,01fh,083h,0bfh,0bfh,0dfh,0dfh,0deh,0dch,0dfh,0e0h,0c0h,0c0h,080h,00ah	; 5f5b  ................
	defb 000h,082h,003h,00fh,005h,07fh,083h,03fh,05fh,06fh,005h,0e0h,002h,0c0h,081h,080h	; 5f6b  .......?_o......
	defb 004h,000h,002h,0ffh,006h,000h,002h,0e0h,002h,000h,005h,01fh,085h,00fh,007h,003h	; 5f7b  ................
	defb 0c0h,0e0h,003h,0ffh,083h,07fh,0bfh,0cfh,003h,003h,082h,007h,00eh,003h,000h,003h	; 5f8b  ................
	defb 0c0h,081h,080h,006h,000h,002h,003h,006h,000h,085h,080h,0f0h,07eh,00fh,001h,006h	; 5f9b  ............~...
	defb 000h,090h,0c0h,0f8h,0c0h,0c0h,0e0h,0f0h,0f0h,0f8h,0f8h,0feh,0ffh,0f8h,07fh,07fh	; 5fab  ................
	defb 01fh,007h,003h,000h,08ah,0e0h,03fh,0bfh,0c7h,0f9h,0feh,0ffh,07fh,0efh,01fh,003h	; 5fbb  ......?.........
	defb 0ffh,084h,07bh,087h,0ffh,000h,007h,080h,090h,000h,001h,003h,007h,060h,0e0h,0ffh	; 5fcb  ..{..........`..
	defb 03fh,0f0h,0cfh,0bfh,07fh,070h,060h,09fh,07fh,003h,0ffh,085h,0e7h,01fh,01fh,0ffh	; 5fdb  ?....p`.........
	defb 0ffh,004h,01fh,08ch,00fh,007h,01fh,07fh,080h,080h,0c0h,0e0h,0ech,0eeh,0dfh,0bfh	; 5feb  ................
	defb 005h,000h,083h,0c0h,0f0h,0f8h,004h,000h,088h,003h,00fh,00fh,007h,000h,001h,001h	; 5ffb  ................
	defb 003h,004h,0ffh,092h,0dfh,0b3h,0ach,0afh,0b3h,0f8h,0f0h,0f0h,0efh,0dfh,03fh,0ffh	; 600b  ..............?.
	defb 0ffh,0f9h,007h,0ffh,03fh,007h,006h,000h,084h,0f8h,0fch,07fh,03fh,004h,07fh,006h	; 601b  ....?.......?...
	defb 0ffh,082h,0feh,0f8h,003h,080h,005h,000h,088h,03fh,01fh,00fh,007h,001h,000h,000h	; 602b  .........?......
	defb 001h,006h,000h,08ah,0feh,03eh,03ch,07eh,0ffh,0ffh,0e1h,0deh,0ffh,0ffh,006h,000h	; 603b  .....><~........
	defb 082h,081h,0c3h,005h,000h,083h,087h,0dfh,07fh,005h,000h,002h,080h,081h,0e0h,000h	; 604b  ................

; ----------------------------------------------------------------------
; DATOS fondo_patrones: Comun a los cinco oponentes: 0x4c0c lo dibuja en la
;   VRAM 0x22f0, o sea los tiles 0x5e en adelante, en los TRES tercios. Son
;   los tiles con que la tabla de nombres de 0x5da4 pinta el templo
;   0x605b..0x6172  (279 bytes)
DATA_fondo_patrones:
	defb 08ah,000h,067h,06eh,07ch,07ch,06eh,067h,000h,000h,03eh,004h,063h,083h,03eh,000h	; 605b  ..gn||ng..>.c.>.
	defb 001h,005h,003h,082h,001h,000h,008h,018h,008h,0a5h,081h,0ffh,005h,000h,083h,0ffh	; 606b  ................
	defb 000h,0ffh,005h,0c0h,083h,0ffh,000h,0ffh,005h,0f0h,083h,0ffh,000h,0ffh,005h,0fch	; 607b  ................
	defb 082h,0ffh,000h,007h,0ffh,082h,000h,0ffh,005h,0c0h,083h,0ffh,000h,0ffh,005h,0f0h	; 608b  ................
	defb 083h,0ffh,000h,0ffh,005h,0fch,082h,0ffh,000h,007h,0ffh,081h,000h,004h,0ffh,09ah	; 609b  ................
	defb 0fdh,0f0h,080h,0c3h,0ffh,0cfh,0e7h,0e7h,0e1h,0c0h,004h,084h,0f3h,0f2h,0d0h,081h	; 60ab  ................
	defb 086h,0fdh,0ffh,0ffh,0e4h,0cch,098h,001h,0c3h,0e7h,003h,0ffh,0a8h,0f9h,0fch,0fch	; 60bb  ................
	defb 0e0h,0f0h,0fch,0fch,0ffh,0ffh,09fh,01fh,03fh,0dfh,08fh,00fh,0c0h,0f8h,0f8h,0f1h	; 60cb  ........?.......
	defb 0e3h,00fh,0ffh,0ffh,03fh,0ffh,01fh,087h,0c0h,0e1h,0ffh,0ffh,050h,050h,0ffh,07fh	; 60db  ....?.......PP..
	defb 03fh,01fh,015h,015h,07eh,005h,0ffh,002h,05ah,099h,042h,0e7h,0a5h,0e7h,042h,0e7h	; 60eb  ?...~...Z.B...B.
	defb 0a5h,0e7h,042h,0e7h,0a5h,0e7h,047h,0eeh,0bdh,0fbh,00fh,07fh,0f8h,0c7h,0bfh,07fh	; 60fb  ..B...G.........
	defb 0ffh,0ffh,03bh,003h,077h,008h,0efh,003h,077h,086h,03bh,01bh,01dh,00eh,007h,003h	; 610b  ..;.w...w.;.....
	defb 003h,000h,002h,0ffh,0a3h,07fh,08fh,0f0h,0ffh,07fh,00fh,0eeh,0eeh,0ceh,01ch,0fdh	; 611b  ................
	defb 0f9h,0e3h,00fh,001h,00fh,03fh,07fh,07fh,0f5h,0ffh,0d5h,0d5h,0ffh,0d5h,0d5h,0ffh	; 612b  .....?..........
	defb 0d5h,0d5h,0ffh,0d5h,0d5h,0ffh,0d5h,0d5h,003h,0ffh,08eh,081h,07fh,040h,053h,05eh	; 613b  .............@S^
	defb 040h,07fh,081h,0f0h,0c7h,09fh,0bfh,038h,073h,004h,077h,08eh,073h,038h,0bfh,09fh	; 614b  @......8s.w.s8..
	defb 0c7h,0f0h,00fh,0e3h,0f9h,0fdh,01ch,0ceh,0eeh,0eeh,008h,0fdh,008h,0ffh,003h,0dfh	; 615b  ................
	defb 081h,000h,003h,0fdh,081h,000h,000h	; 616b

; ----------------------------------------------------------------------
; DATOS oponente_0_colores: Primer puntero de la tabla de 0x4ba6: el color de
;   WANG. A la VRAM 0x0880 y a la 0x0c40
;   0x6172..0x6207  (149 bytes)
DATA_oponente_0_colores:
	defb 008h,060h,038h,0b0h,008h,040h,002h,0b0h,006h,040h,002h,0b0h,006h,040h,081h,0b0h	; 6172  .`8..@...@...@..
	defb 00dh,040h,002h,0f0h,006h,040h,002h,0f0h,007h,040h,081h,0f0h,006h,040h,002h,0f0h	; 6182  .@...@...@...@..
	defb 081h,0b0h,00dh,040h,002h,0f0h,006h,040h,002h,0f0h,010h,040h,006h,0b0h,002h,0b4h	; 6192  ...@...@...@....
	defb 004h,0b0h,002h,0b6h,002h,0b0h,010h,060h,008h,040h,005h,04bh,004h,040h,007h,0f0h	; 61a2  .......`.@.K.@..
	defb 081h,040h,007h,0f0h,010h,060h,006h,0b0h,082h,060h,0b6h,008h,0b0h,081h,0b6h,007h	; 61b2  .@...`...`......
	defb 0b0h,082h,060h,0b6h,01ah,0b0h,002h,0b6h,006h,0b0h,002h,0b6h,006h,0b0h,002h,0b6h	; 61c2  ..`.............
	defb 002h,0b0h,006h,040h,002h,0f0h,081h,0b0h,007h,040h,008h,0f0h,005h,040h,002h,04fh	; 61d2  ...@.....@...@.O
	defb 081h,040h,004h,0b0h,004h,040h,005h,0b0h,083h,040h,04bh,04bh,008h,0b0h,008h,040h	; 61e2  .@...@...@KK...@
	defb 002h,04bh,006h,040h,002h,0b0h,006h,040h,081h,0b0h,00eh,040h,009h,0f0h,010h,040h	; 61f2  .K.@...@...@...@
	defb 008h,0b0h,008h,0b4h,000h	; 6202

; ----------------------------------------------------------------------
; DATOS fondo_colores: El color de esos mismos tiles: 0x4c17 lo dibuja en la
;   VRAM 0x02f0 y 0x4c20 lo repite 0x3c0 mas alla, en la 0x06b0, los dos en
;   los tres tercios
;   0x6207..0x624b  (68 bytes)
DATA_fondo_colores:
	defb 010h,0f6h,021h,0f0h,005h,060h,003h,0f0h,005h,060h,003h,0f0h,005h,060h,003h,0f0h	; 6207  ..!..`...`...`..
	defb 005h,060h,003h,0f0h,005h,050h,003h,0f0h,005h,050h,003h,0f0h,005h,050h,003h,0f0h	; 6217  .`...P...P...P..
	defb 005h,050h,044h,0f0h,081h,099h,003h,0c0h,002h,0f0h,002h,0a0h,081h,099h,003h,0cch	; 6227  .PD.............
	defb 002h,0f0h,045h,060h,023h,06fh,010h,069h,010h,06fh,088h,090h,080h,060h,000h,090h	; 6237  ..E`#o.i.o...`..
	defb 080h,060h,000h,000h	; 6247

; ----------------------------------------------------------------------
; DATOS oponente_1_patrones: Segundo de la tabla de patrones: la figura de TAO
;   0x624b..0x6421  (470 bytes)
DATA_oponente_1_patrones:
	defb 08ch,00fh,01fh,02dh,06bh,0ffh,0dfh,0dfh,07fh,080h,0c0h,0e0h,060h,003h,0a0h,092h	; 624b  ...-k.......`...
	defb 078h,00fh,01fh,01fh,01bh,01fh,0dfh,0dfh,06fh,0bch,0c3h,0ffh,0ffh,0fch,0fbh,0fbh	; 625b  x.......o.......
	defb 0fdh,0fch,003h,0feh,084h,0deh,03eh,0fch,0f8h,003h,00fh,082h,01fh,03fh,003h,07fh	; 626b  ......>......?..
	defb 083h,0feh,0ffh,040h,004h,000h,089h,040h,000h,0e0h,0f0h,0f0h,0f8h,0f8h,0fch,0fch	; 627b  ...@...@........
	defb 003h,07fh,08ah,03fh,01fh,00eh,03eh,0feh,0cfh,087h,087h,083h,001h,003h,000h,004h	; 628b  ...?..>.........
	defb 0fch,08ch,0f8h,070h,0f8h,0feh,080h,0c0h,0e0h,0e0h,0a0h,0beh,0bfh,07fh,006h,000h	; 629b  ...p............
	defb 08fh,080h,0c0h,03ch,043h,07fh,07fh,077h,03fh,05fh,06fh,0ffh,0ffh,0f7h,0dbh,0fbh	; 62ab  ...<C..w?_o.....
	defb 003h,0f7h,005h,0e0h,088h,0c0h,0a0h,060h,06fh,02fh,00fh,01fh,03fh,003h,07fh,083h	; 62bb  .......`o/..?...
	defb 0fbh,0fch,040h,004h,000h,08bh,040h,060h,0e0h,0f0h,0f0h,0f8h,0f8h,0fch,0fch,001h	; 62cb  ..@...@`........
	defb 003h,004h,007h,002h,003h,090h,0bch,0c3h,0ffh,0ffh,0f7h,03fh,03fh,01fh,0ffh,0ffh	; 62db  ...........??...
	defb 0fbh,0fdh,0ddh,0fbh,0f7h,0f0h,005h,0e0h,083h,0c0h,080h,060h,004h,007h,094h,003h	; 62eb  ...........`....
	defb 001h,001h,007h,00fh,007h,000h,040h,020h,010h,0f0h,0f0h,0e0h,0c0h,000h,000h,004h	; 62fb  ......@ ........
	defb 004h,003h,003h,004h,0f0h,097h,0e0h,0c0h,0e0h,0f8h,080h,0c0h,0e0h,0e0h,0a0h,0b8h	; 630b  ................
	defb 0beh,07eh,003h,00fh,01fh,01eh,01eh,00eh,03eh,0ffh,0c3h,0ffh,07fh,003h,0ffh,083h	; 631b  .~......>.......
	defb 083h,003h,03fh,003h,01fh,084h,07eh,0f8h,0feh,0fch,005h,000h,083h,007h,01fh,03fh	; 632b  ..?...~........?
	defb 004h,000h,003h,0feh,081h,0f7h,003h,000h,081h,003h,003h,007h,084h,003h,038h,000h	; 633b  ..............8.
	defb 07fh,005h,0ffh,084h,02fh,01fh,01fh,01bh,003h,01fh,08ah,00fh,0bch,0c3h,0ffh,0ffh	; 634b  ..../...........
	defb 0fch,0fbh,0fbh,0fdh,0fch,003h,0feh,086h,0deh,03eh,0fch,0f8h,007h,001h,006h,000h	; 635b  .........>......
	defb 08bh,00fh,003h,03fh,00fh,003h,001h,000h,000h,0feh,0ffh,040h,003h,000h,086h,080h	; 636b  ...?.......@....
	defb 0c0h,01fh,007h,003h,001h,008h,000h,003h,0feh,082h,0f7h,038h,007h,000h,084h,02fh	; 637b  ...........8.../
	defb 01fh,01fh,01bh,003h,01fh,007h,00fh,002h,007h,083h,0feh,0ffh,040h,006h,000h,081h	; 638b  ............@...
	defb 0e0h,005h,0f0h,083h,0e0h,003h,001h,006h,000h,08ch,0c0h,080h,040h,060h,070h,070h	; 639b  ............@`pp
	defb 060h,0c0h,080h,0c0h,0e0h,060h,003h,0a0h,09ah,060h,000h,000h,00eh,00fh,00fh,003h	; 63ab  `....`...`......
	defb 000h,000h,00fh,03fh,0ffh,0feh,0fdh,0ddh,01eh,00fh,0bch,0c3h,0ffh,079h,087h,0ffh	; 63bb  ...?.........y..
	defb 07fh,080h,0f0h,004h,0f8h,086h,0f0h,0c0h,020h,0ffh,0ffh,040h,004h,000h,089h,040h	; 63cb  ........ ..@...@
	defb 0e0h,0e0h,0f0h,0f0h,0f8h,0f8h,0fch,0fch,003h,00fh,005h,01fh,003h,0e0h,004h,0f0h	; 63db  ................
	defb 083h,0e0h,00fh,006h,006h,000h,090h,07fh,0ffh,0ffh,0feh,07dh,073h,0f8h,0feh,0e0h	; 63eb  ...........}s...
	defb 0c0h,080h,000h,0c0h,0e0h,060h,0c0h,006h,000h,08ah,0fch,03ch,03ch,07eh,0ffh,0ffh	; 63fb  .....`.....<<~..
	defb 0e1h,0deh,0ffh,0ffh,005h,000h,083h,087h,0dfh,07fh,005h,000h,002h,080h,081h,0e0h	; 640b  ................
	defb 006h,000h,082h,081h,0c3h,000h	; 641b

; ----------------------------------------------------------------------
; DATOS oponente_1_colores: Segundo de la tabla de colores: el color de TAO
;   0x6421..0x64bd  (156 bytes)
DATA_oponente_1_colores:
	defb 02ah,0b0h,006h,0d0h,081h,0b0h,006h,0bdh,081h,00dh,00eh,0d0h,002h,0f0h,00eh,0d0h	; 6421  *...............
	defb 002h,0f0h,02ah,0b0h,006h,0d0h,002h,0b0h,005h,0bdh,082h,00dh,0b0h,007h,0d0h,007h	; 6431  ..*.............
	defb 0b0h,081h,0d0h,006h,0b0h,002h,0bdh,00fh,0b0h,007h,0d0h,002h,0f0h,002h,0bdh,004h	; 6441  ................
	defb 00dh,002h,0f0h,004h,0bdh,002h,00dh,002h,0f0h,006h,0d0h,002h,0f0h,008h,0b0h,006h	; 6451  ................
	defb 0d0h,002h,0f0h,081h,0dbh,005h,0d0h,082h,0dfh,00fh,006h,0bdh,002h,0d0h,010h,0b0h	; 6461  ................
	defb 004h,0d0h,002h,0dfh,002h,0d0h,002h,0b0h,006h,0d0h,003h,0b0h,005h,0bdh,010h,0b0h	; 6471  ................
	defb 008h,0d0h,002h,0bdh,006h,0d0h,002h,0b0h,004h,0bdh,002h,00dh,008h,0d0h,01ah,0b0h	; 6481  ................
	defb 006h,0d0h,081h,0b0h,007h,0bdh,00ch,0d0h,004h,0f0h,004h,0d0h,02ch,0b0h,007h,0bdh	; 6491  ............,...
	defb 082h,00dh,0b0h,007h,0d0h,002h,0b0h,006h,0d0h,081h,0b0h,015h,0d0h,002h,0f0h,004h	; 64a1  ................
	defb 0d0h,00ch,0f0h,008h,0d0h,008h,0b0h,008h,0bdh,008h,0d0h,000h	; 64b1  ............

; ----------------------------------------------------------------------
; DATOS oponente_2_patrones: Tercero de la tabla de patrones: la figura de
;   CHEN
;   0x64bd..0x669b  (478 bytes)
DATA_oponente_2_patrones:
	defb 005h,000h,003h,0e0h,08dh,00fh,01fh,00fh,03fh,01bh,01bh,033h,007h,0c0h,0e0h,0f0h	; 64bd  ........?..3....
	defb 0f0h,0fbh,003h,0ffh,002h,070h,081h,078h,004h,0f8h,08ah,0f0h,000h,003h,007h,01fh	; 64cd  .....p.x........
	defb 0ffh,0ffh,0e0h,000h,080h,003h,0c0h,002h,080h,002h,0c0h,084h,07fh,00fh,007h,001h	; 64dd  ................
	defb 004h,000h,081h,0e0h,007h,0c0h,004h,000h,087h,001h,003h,007h,007h,01fh,007h,078h	; 64ed  ...............x
	defb 007h,0ffh,081h,000h,005h,0ffh,088h,0c0h,000h,0e0h,0f8h,0fch,0feh,0ffh,0ffh,004h	; 64fd  ................
	defb 007h,089h,003h,001h,007h,01fh,0ffh,0fch,0f8h,0f0h,0f0h,003h,0c0h,082h,00fh,001h	; 650d  ................
	defb 006h,000h,003h,0ffh,088h,0feh,07ch,038h,07ch,07fh,0ffh,0ffh,000h,004h,0ffh,085h	; 651d  ......|8|.......
	defb 0fdh,080h,080h,000h,0c0h,004h,0e0h,094h,0ffh,07fh,03fh,01fh,00fh,007h,007h,01fh	; 652d  ..........?.....
	defb 083h,0bfh,0bfh,0dfh,0dfh,0deh,0dch,0dfh,0e0h,0c0h,0c0h,080h,004h,000h,002h,00eh	; 653d  ................
	defb 08fh,01eh,07eh,0fch,0fch,0f8h,0f0h,000h,003h,007h,01fh,0ffh,0ffh,0e0h,00fh,080h	; 654d  ..~.............
	defb 003h,0c0h,002h,080h,082h,0c0h,040h,005h,01fh,08bh,00fh,007h,003h,0bfh,0cfh,0f0h	; 655d  ......@.........
	defb 0ffh,0ffh,07fh,0bfh,0cfh,003h,003h,082h,007h,00eh,008h,000h,08bh,0f0h,0f8h,03fh	; 656d  ...............?
	defb 0c0h,0e0h,0f0h,0f0h,0f8h,0f8h,0f3h,0e7h,006h,000h,087h,080h,0c0h,03fh,03fh,01fh	; 657d  .............??.
	defb 00fh,003h,003h,000h,081h,0f8h,005h,0ffh,092h,03fh,01fh,01fh,033h,02ch,02fh,02fh	; 658d  .........?..3,//
	defb 0b0h,0bfh,0dfh,0efh,0dfh,03fh,0ffh,0ffh,0f9h,007h,0ffh,005h,0e0h,002h,0c0h,083h	; 659d  .....?..........
	defb 080h,007h,001h,006h,000h,084h,0efh,0f1h,07eh,03fh,004h,07fh,083h,0ffh,0f3h,003h	; 65ad  ........~?......
	defb 003h,0ffh,08ch,0feh,0f8h,03fh,01fh,00fh,007h,001h,000h,000h,001h,0f0h,0f8h,003h	; 65bd  .....?..........
	defb 0fch,083h,038h,07ch,0fch,003h,000h,0a5h,01fh,0ffh,0ffh,0e3h,000h,00fh,01fh,00fh	; 65cd  ..8|............
	defb 03dh,0ddh,0ddh,0bbh,0c3h,0c0h,0e0h,0f0h,0f0h,0f8h,0fch,0feh,083h,01fh,007h,038h	; 65dd  =..............8
	defb 03fh,03fh,00fh,03fh,03fh,0c8h,07ch,0fch,0fch,0f8h,0e0h,000h,000h,003h,080h,005h	; 65ed  ??.??.|.........
	defb 0c0h,093h,001h,007h,03fh,0ffh,0ffh,0e0h,000h,000h,05fh,047h,0b8h,0bfh,0bfh,08fh	; 65fd  ....?....._G....
	defb 03fh,03fh,0ffh,0ffh,000h,003h,0ffh,09ah,0feh,0fdh,003h,01fh,00fh,007h,001h,000h	; 660d  ??..............
	defb 000h,001h,000h,000h,001h,0e3h,0ffh,0ffh,03fh,00fh,01fh,047h,0b8h,0bfh,0bfh,08fh	; 661d  ........?..G....
	defb 03fh,03fh,003h,01fh,08ah,01dh,01eh,00fh,007h,01fh,0dfh,0e7h,0f8h,0ffh,0ffh,003h	; 662d  ??..............
	defb 07fh,088h,0c0h,000h,0c0h,09ch,0beh,05fh,0deh,0fch,004h,000h,094h,080h,0c0h,0c0h	; 663d  ......._........
	defb 080h,000h,01ch,01fh,01fh,007h,001h,000h,000h,017h,00fh,0bfh,0ffh,0ffh,0feh,0c0h	; 664d  ................
	defb 0c0h,004h,03fh,081h,07fh,003h,0ffh,083h,0c0h,000h,0c0h,003h,0e0h,002h,0f0h,006h	; 665d  ..?.............
	defb 000h,08ah,0feh,03eh,03ch,07eh,0ffh,0ffh,0e1h,0deh,0ffh,0ffh,006h,000h,082h,081h	; 666d  ...><~..........
	defb 0c3h,005h,0ffh,002h,07fh,081h,01fh,005h,000h,083h,087h,0dfh,07fh,003h,0c0h,081h	; 667d  ................
	defb 080h,009h,000h,083h,033h,0cch,033h,005h,000h,083h,03ch,0fch,03ch,000h	; 668d  ....3.3...<.<.

; ----------------------------------------------------------------------
; DATOS oponente_2_colores: Tercero de la tabla de colores: el color de CHEN
;   0x669b..0x6724  (137 bytes)
DATA_oponente_2_colores:
	defb 028h,0b0h,005h,0bch,003h,00ch,008h,0bch,004h,0b0h,02ah,0c0h,002h,0f0h,006h,0c0h	; 669b  (.........*.....
	defb 002h,0f0h,00eh,0c0h,002h,0f0h,016h,0c0h,002h,0f0h,006h,0c0h,002h,0f0h,008h,0c0h	; 66ab  ................
	defb 00fh,0b0h,081h,0c0h,005h,0bch,003h,00ch,011h,0c0h,00eh,0f0h,081h,0c0h,006h,0b0h	; 66bb  ................
	defb 002h,0bch,008h,0b0h,010h,0c0h,005h,0b0h,003h,0c0h,006h,0b0h,002h,0c0h,006h,0b0h	; 66cb  ................
	defb 021h,0c0h,081h,0f0h,006h,0c0h,002h,0f0h,017h,0b0h,081h,0bch,006h,0b0h,002h,0c0h	; 66db  !...............
	defb 008h,0bch,008h,0c0h,00eh,0b0h,011h,0c0h,081h,0f0h,007h,0b0h,081h,0c0h,006h,0b0h	; 66eb  ................
	defb 008h,0c0h,002h,0f0h,006h,0c0h,002h,0cfh,007h,0c0h,081h,0cfh,008h,0f0h,00eh,0b0h	; 66fb  ................
	defb 002h,00ch,008h,0cbh,008h,0c0h,008h,0f0h,010h,0c0h,008h,0cbh,008h,0b0h,081h,0c0h	; 670b  ................
	defb 00dh,0f0h,002h,0e0h,006h,0f0h,002h,0e0h,000h	; 671b  .........

; ----------------------------------------------------------------------
; DATOS oponente_3_patrones: Cuarto de la tabla de patrones: la figura de LANG
;   0x6724..0x68a2  (382 bytes)
DATA_oponente_3_patrones:
	defb 002h,000h,090h,003h,004h,00dh,00ch,007h,000h,07eh,0ffh,0e7h,000h,048h,000h,030h	; 6724  .........~...H.0
	defb 081h,001h,003h,004h,007h,086h,003h,000h,0ffh,0ffh,0dbh,0dbh,003h,0f9h,085h,0dbh	; 6734  ................
	defb 0f0h,0f8h,0feh,0cfh,003h,03fh,08eh,0ceh,001h,001h,000h,003h,007h,00fh,01fh,01fh	; 6744  .....?..........
	defb 0dbh,0ffh,0ffh,07fh,080h,003h,0ffh,002h,0e0h,090h,0c0h,038h,0fch,0feh,0ffh,0ffh	; 6754  ...........8....
	defb 03fh,03fh,07fh,07eh,07ch,07ch,078h,0f8h,0e1h,080h,006h,000h,08ah,0ffh,07fh,01fh	; 6764  ??.~||x.........
	defb 00fh,007h,007h,003h,003h,080h,080h,005h,0c0h,081h,0e0h,003h,000h,082h,007h,003h	; 6774  ................
	defb 003h,001h,002h,000h,08ah,003h,084h,0cdh,0cch,0e7h,0f0h,0ffh,07fh,03fh,00fh,003h	; 6784  .............?..
	defb 003h,099h,001h,07eh,0ffh,0e7h,000h,048h,000h,030h,081h,01eh,03ch,0fch,078h,0f8h	; 6794  ...~...H.0..<.x.
	defb 0f0h,0f8h,0fch,001h,003h,007h,00fh,01fh,03fh,07eh,07eh,006h,000h,002h,00eh,006h	; 67a4  ........?~~.....
	defb 000h,002h,001h,002h,01fh,083h,03dh,07dh,07fh,003h,0ffh,002h,07eh,092h,0feh,0eeh	; 67b4  ......=}....~...
	defb 0eeh,0beh,0beh,0fdh,0fch,0fch,0f8h,0f8h,0f0h,0f0h,0e0h,0e0h,003h,003h,007h,007h	; 67c4  ................
	defb 004h,000h,083h,0e1h,0c0h,080h,005h,000h,08bh,0fbh,0e7h,01fh,07fh,07fh,07eh,07eh	; 67d4  ..............~~
	defb 07ch,0c0h,0c0h,080h,005h,000h,090h,0fch,0f8h,0f8h,0f0h,0f0h,0e0h,0e0h,0c0h,01ch	; 67e4  |...............
	defb 01ch,03bh,07ch,079h,078h,07ch,07fh,008h,000h,003h,03fh,081h,003h,004h,000h,002h	; 67f4  .;|yx|....?.....
	defb 0ffh,002h,0fdh,088h,03fh,01fh,00fh,003h,0fch,0fch,0f0h,0c0h,004h,000h,002h,0ffh	; 6804  ....?...........
	defb 002h,0bfh,08fh,0ffh,0feh,0f8h,0e0h,00eh,00eh,0ceh,02eh,0beh,03eh,0fch,0fch,0f8h	; 6814  ............>...
	defb 0f0h,0f0h,004h,0e0h,081h,0cfh,006h,000h,087h,007h,00fh,000h,001h,003h,00fh,03fh	; 6824  ...............?
	defb 004h,0ffh,082h,07eh,081h,003h,0ffh,082h,0f8h,0c0h,003h,0ffh,082h,0f7h,0efh,003h	; 6834  ...~............
	defb 00fh,081h,080h,003h,0c0h,002h,080h,0ach,000h,080h,000h,000h,003h,004h,00dh,00ch	; 6844  ................
	defb 007h,0efh,003h,007h,00bh,00ch,01fh,0fch,0e3h,0c3h,0efh,0f7h,0fbh,0fdh,07dh,0feh	; 6854  ..............}.
	defb 0feh,0fch,083h,0ffh,0feh,07dh,083h,0ffh,0f7h,0e1h,0c0h,0c0h,000h,000h,080h,0e0h	; 6864  .....}..........
	defb 0fch,0fch,001h,001h,004h,000h,002h,001h,002h,0e0h,082h,0c0h,020h,004h,0e0h,004h	; 6874  ............ ...
	defb 003h,081h,001h,003h,000h,082h,0f7h,0efh,003h,0dfh,088h,0e7h,078h,0f9h,0e0h,0e0h	; 6884  ............x...
	defb 0c0h,080h,0e0h,003h,0f0h,002h,0ffh,002h,0dbh,003h,0ffh,081h,0dbh,000h	; 6894  ..............

; ----------------------------------------------------------------------
; DATOS oponente_3_colores: Cuarto de la tabla de colores: el color de LANG
;   0x68a2..0x68ff  (93 bytes)
DATA_oponente_3_colores:
	defb 00ah,080h,005h,08bh,081h,00bh,00ch,080h,003h,08bh,005h,080h,003h,08bh,01fh,080h	; 68a2  ................
	defb 002h,0f0h,00eh,080h,002h,0f0h,006h,080h,002h,0f0h,005h,0b0h,015h,080h,006h,08bh	; 68b2  ................
	defb 008h,080h,003h,0f0h,005h,080h,008h,0b0h,022h,080h,006h,0b0h,01dh,080h,003h,0f0h	; 68c2  ........".......
	defb 002h,0b0h,00eh,080h,002h,08bh,01eh,080h,002h,0b0h,00eh,080h,008h,0f0h,016h,080h	; 68d2  ................
	defb 002h,0f0h,006h,080h,002h,0f0h,00eh,080h,002h,08fh,010h,080h,002h,0b0h,004h,080h	; 68e2  ................
	defb 002h,08bh,01eh,080h,002h,0f0h,006h,080h,002h,0f0h,008h,080h,000h	; 68f2  .............

; ----------------------------------------------------------------------
; DATOS oponente_4_patrones: Quinto de la tabla de patrones: la figura de WU
;   0x68ff..0x6a9c  (413 bytes)
DATA_oponente_4_patrones:
	defb 090h,00fh,01fh,00fh,03dh,01eh,01dh,03fh,00fh,0c0h,0e0h,0f0h,0f0h,0f8h,0feh,0ffh	; 68ff  ....=..?........
	defb 0ffh,006h,000h,084h,080h,0c0h,007h,001h,006h,000h,088h,080h,0e3h,0f7h,0ffh,0ffh	; 690f  ................
	defb 07fh,03eh,000h,006h,0ffh,002h,07fh,003h,0ffh,002h,0fbh,003h,0f7h,006h,0e0h,002h	; 691f  .>..............
	defb 0c0h,003h,000h,082h,001h,007h,003h,00fh,002h,03fh,081h,07fh,00dh,0ffh,084h,080h	; 692f  .........?......
	defb 0c0h,0e0h,0e0h,003h,0f0h,081h,070h,004h,01fh,002h,007h,09ah,00fh,03eh,0ffh,0e0h	; 693f  ......p......>..
	defb 0c0h,0c0h,000h,080h,080h,000h,0c0h,01fh,00fh,00fh,01fh,01fh,00fh,00fh,0f0h,0f0h	; 694f  ................
	defb 0e0h,0e0h,0c0h,0c0h,080h,0e0h,004h,000h,081h,001h,005h,003h,081h,001h,005h,000h	; 695f  ................
	defb 090h,0ffh,0fch,0feh,0ffh,07fh,01eh,03eh,078h,0c0h,0e0h,0f6h,0f7h,0f9h,0feh,0ffh	; 696f  .......>x.......
	defb 0ffh,004h,000h,085h,040h,070h,0f8h,0fch,07fh,005h,0ffh,002h,07fh,003h,0fch,08bh	; 697f  ....@p..........
	defb 0f8h,0e0h,0e0h,0c0h,0c0h,07fh,01fh,00eh,00fh,007h,003h,003h,000h,087h,0f8h,07ch	; 698f  ...............|
	defb 03ch,01fh,01fh,00fh,007h,004h,000h,088h,080h,0e0h,0f0h,0f8h,007h,003h,003h,001h	; 699f  <...............
	defb 004h,000h,081h,0fch,004h,0ffh,093h,07fh,03fh,00fh,01fh,023h,05ch,0d7h,0ebh,0fch	; 69af  ........?..#\...
	defb 07fh,03fh,0ffh,0dfh,03fh,0ffh,0ffh,0f3h,00fh,0ffh,008h,080h,082h,003h,001h,006h	; 69bf  .?..?...........
	defb 000h,083h,0f0h,0feh,0ffh,004h,07fh,083h,03fh,0ffh,0fch,004h,0ffh,092h,0feh,0f8h	; 69cf  ........?.......
	defb 03fh,01fh,00fh,007h,003h,001h,000h,001h,0f0h,0f8h,0fch,0feh,0feh,0f8h,07ch,0fch	; 69df  ?.............|.
	defb 005h,000h,08dh,007h,01fh,0ffh,00fh,01fh,00fh,03dh,01eh,0ddh,0bfh,0cfh,0ffh,0e1h	; 69ef  .........=......
	defb 006h,000h,090h,0ffh,0e7h,058h,05fh,06fh,073h,07ch,07fh,000h,01fh,00fh,007h,001h	; 69ff  .....X_os|......
	defb 000h,000h,001h,006h,000h,087h,007h,01fh,0ffh,0e1h,000h,000h,00fh,003h,0ffh,002h	; 6a0f  ................
	defb 000h,086h,007h,01fh,03fh,038h,000h,000h,004h,0ffh,084h,0fch,0e0h,000h,000h,003h	; 6a1f  ....?8..........
	defb 0ffh,081h,0c7h,004h,000h,085h,0c0h,0e0h,0ffh,0ffh,03fh,003h,07fh,003h,000h,089h	; 6a2f  ..........?.....
	defb 0c0h,0e0h,0e0h,060h,0c0h,0c0h,0e0h,0f0h,0feh,004h,0ffh,004h,000h,084h,0c0h,007h	; 6a3f  ...`............
	defb 007h,00fh,004h,000h,087h,001h,0e7h,0fbh,0ffh,000h,000h,01ch,004h,0fch,091h,0fdh	; 6a4f  ................
	defb 000h,070h,0e8h,0d0h,0a0h,0c0h,080h,000h,0ffh,0e7h,018h,01fh,00fh,003h,004h,003h	; 6a5f  .p..............
	defb 007h,00fh,081h,007h,006h,0ffh,082h,0f8h,0c0h,003h,0fdh,082h,0f2h,0c8h,009h,000h	; 6a6f  ................
	defb 083h,0fch,03ch,07eh,003h,0ffh,084h,0e1h,0deh,0ffh,0ffh,006h,000h,082h,081h,0c3h	; 6a7f  ..<~............
	defb 005h,000h,083h,087h,0dfh,07fh,005h,0ffh,002h,07fh,081h,01fh,000h	; 6a8f  .............

; ----------------------------------------------------------------------
; DATOS oponente_4_colores: Quinto de la tabla de colores: el color de WU
;   0x6a9c..0x6b05  (105 bytes)
DATA_oponente_4_colores:
	defb 040h,060h,008h,0e0h,081h,060h,007h,0e0h,081h,060h,007h,0e0h,081h,060h,00bh,0e0h	; 6a9c  @`...`...`...`..
	defb 004h,060h,005h,0e0h,003h,060h,006h,0e0h,002h,060h,006h,0e0h,002h,060h,015h,0e0h	; 6aac  .`...`...`...`..
	defb 023h,060h,002h,0e0h,00ah,060h,01ch,0e0h,006h,060h,002h,06eh,010h,060h,008h,0e0h	; 6abc  #`...`...`.n.`..
	defb 002h,0e6h,006h,0e0h,002h,06eh,00dh,0e0h,081h,060h,006h,0e0h,022h,060h,007h,0e0h	; 6acc  .....n...`.."`..
	defb 081h,060h,008h,0e0h,002h,060h,006h,0e0h,008h,060h,010h,0e0h,002h,0e6h,006h,0e0h	; 6adc  .`...`...`......
	defb 015h,060h,003h,0e6h,00bh,0e0h,004h,0e6h,081h,0e0h,010h,060h,008h,0e6h,010h,0e0h	; 6aec  .`.........`....
	defb 008h,060h,010h,0e0h,008h,060h,008h,0e6h,000h	; 6afc  .`...`...

; ======================================================================
; CODIGO 0x6b05..0x6b4b  (70 bytes)
; ======================================================================


el_paso_del_oponente:		; Dos cuentas atras por delante de todo: 0xE129 primero y 0xE132 despues. Mientras alguna corra, el oponente va a 0x74e7 con 0xE169 en uno y el lado que digan 0xE185 o 0xE133. Solo cuando las dos se agotan se despacha el movimiento de verdad
	ld hl,0e129h		;6b05   ; HL = 0xE129, la primera cuenta
	ld a,(hl)			;6b08
	and a			;6b09
	jr z,la_segunda_cuenta		;6b0a
	xor a			;6b0c
	ld (0e1b8h),a		;6b0d   ; 0xE1b8, borrado
	dec (hl)			;6b10   ; un cuadro menos
	ld a,001h		;6b11
	ld (0e169h),a		;6b13   ; 0xE169 a uno
	ld a,(0e185h)		;6b16   ; el lado en que esta el jugador
	ld c,000h		;6b19
	and a			;6b1b
	jr nz,el_paso_del_oponente_si_no		;6b1c
	inc c			;6b1e   ; C = 1 si esta a la izquierda
el_paso_del_oponente_si_no:		; Dentro de el_paso_del_oponente
	jp con_la_pose_dos		;6b1f
la_segunda_cuenta:		; Lo mismo con 0xE132, pero el lado lo trae 0xE133
	ld hl,0e132h		;6b22   ; HL = 0xE132, la segunda cuenta
	ld a,(hl)			;6b25
	and a			;6b26
	jr z,despacha_el_movimiento		;6b27
	dec (hl)			;6b29   ; un cuadro menos
	ld a,001h		;6b2a
	ld (0e169h),a		;6b2c   ; 0xE169 a uno
	ld a,(0e133h)		;6b2f   ; y el lado, de 0xE133
	ld c,000h		;6b32
	and a			;6b34
	jr z,la_segunda_cuenta_si_no		;6b35
	inc c			;6b37
la_segunda_cuenta_si_no:		; Dentro de la_segunda_cuenta
	jp con_la_pose_dos		;6b38
despacha_el_movimiento:		; Con 0xE058 puesto se va a 0x79b7; si no, reparte por la tabla de 0x6b4b segun el oponente de 0xE054
	ld a,(0e058h)		;6b3b   ; 0xE058 decide
	and a			;6b3e
	jp nz,un_cuadro_de_bonus		;6b3f
	ld a,(0e054h)		;6b42   ; el oponente de turno
	ld hl,06b4bh		;6b45
	call despacha_por_la_tabla_de_al_lado		;6b48   ; y a su rutina

; ----------------------------------------------------------------------
; DATOS tabla_del_montaje_por_escenario: Cinco punteros indexados por 0xE054
;   desde 0x6b48: 0x6c90, 0x6e79, 0x7012, 0x7320 y 0x7758. Son CINCO y no
;   seis; el porque esta en el .entries
;   0x6b4b..0x6b55  (10 bytes)
DATA_tabla_del_montaje_por_escenario:
	defw 06c90h,06e79h,07012h,07320h,07758h	; 6b4b

; ======================================================================
; CODIGO 0x6b55..0x6c15  (192 bytes)
; ======================================================================


escribe_el_nombre_del_oponente:		; Con 0xE058 a cero, saca de la tabla de 0x6c2b los cuatro tiles del nombre y los pone en la VRAM 0x386a; con 0xE058 puesto, escribe en la 0x386a lo que traiga 0x6c63
	ld a,(0e058h)		;6b55   ; 0xE058 decide
	and a			;6b58
	jr z,escribe_el_nombre_del_oponente_si_no		;6b59
	ld hl,0386ah		;6b5b   ; HL = VRAM 0x386a, fila 3 columna 10
	jp escribe_bonus_stage_donde_diga_hl		;6b5e
escribe_el_nombre_del_oponente_si_no:		; Dentro de escribe_el_nombre_del_oponente
	ld hl,06c2bh		;6b61   ; la tabla de los cinco nombres
	ld a,(0e054h)		;6b64   ; por el oponente de turno
	call escribe_cuatro_tiles		;6b67
acerca_el_reloj_a_su_tope:		; 0xE130 no puede pasar de 0x24; luego se compara con 0xE116 y se le acerca
	ld a,(0e058h)		;6b6a   ; con 0xE058 puesto no se toca
	and a			;6b6d
	ret nz			;6b6e
	ld hl,0e116h		;6b6f   ; HL = 0xE116
	ld de,0e130h		;6b72   ; DE = 0xE130
	ld a,(de)			;6b75
	cp 024h		;6b76   ; el tope es 0x24
	jr c,acerca_una_unidad		;6b78
	ld a,024h		;6b7a   ; y ahi se queda
	ld (de),a			;6b7c
acerca_una_unidad:		; Si la pintada pasa de la de verdad, se le baja una; luego se redibuja la mitad del jugador desde la VRAM 0x386d
	cp (hl)			;6b7d   ; contra la energia de verdad
	jr c,la_mitad_del_oponente		;6b7e
	jr z,acerca_una_unidad_si_no		;6b80
	dec a			;6b82   ; una unidad menos
	ld (de),a			;6b83
acerca_una_unidad_si_no:		; Dentro de acerca_una_unidad
	ld hl,0386dh		;6b84   ; HL = VRAM 0x386d, donde empieza su mitad
	ld b,001h		;6b87   ; B = 1: la mitad del jugador
	call dibuja_media_barra		;6b89
la_mitad_del_oponente:		; Lo mismo con 0xE117 y 0xE131, y se dibuja desde la VRAM 0x3872
	ld hl,0e117h		;6b8c   ; HL = 0xE117, su energia
	ld de,0e131h		;6b8f   ; DE = 0xE131, la pintada
	ld a,(de)			;6b92
	cp 024h		;6b93   ; el mismo tope, 0x24
	jr c,la_mitad_del_oponente_si_no		;6b95
	ld a,024h		;6b97
	ld (de),a			;6b99
la_mitad_del_oponente_si_no:		; Dentro de la_mitad_del_oponente
	cp (hl)			;6b9a
	ret c			;6b9b
	jr z,la_mitad_del_oponente_si_no_2		;6b9c
	dec a			;6b9e   ; una unidad menos
	ld (de),a			;6b9f
la_mitad_del_oponente_si_no_2:		; Dentro de la_mitad_del_oponente
	ld b,000h		;6ba0   ; B = 0: la mitad del oponente
	ld hl,03872h		;6ba2   ; HL = VRAM 0x3872
dibuja_media_barra:		; Elige la tira de tiles -la de 0x6c1a de 0x10 para arriba y la de 0x6c15 por debajo- y, si es la mitad del jugador y 0xE128 esta sin levantar, avisa con la melodia 3 de que le queda poca
	push af			;6ba5
	cp 010h		;6ba6   ; por debajo de 0x10 queda poca
	ld de,06c1ah		;6ba8   ; DE = 0x6c1a, la tira normal
	jr nc,dibuja_media_barra_por_aqui		;6bab
	ld de,06c15h		;6bad   ; DE = 0x6c15, la de aviso
	bit 0,b		;6bb0   ; solo la mitad del jugador avisa
	jr z,dibuja_media_barra_por_aqui		;6bb2
	ld a,(0e128h)		;6bb4   ; y solo una vez
	and a			;6bb7
	jr nz,dibuja_media_barra_por_aqui		;6bb8
	ld a,003h		;6bba   ; A = 3, la melodia del aviso
	call pon_la_melodia		;6bbc
	ld a,001h		;6bbf
	ld (0e128h),a		;6bc1   ; el aviso, levantado
dibuja_media_barra_por_aqui:		; Dentro de dibuja_media_barra
	pop af			;6bc4
	ld c,000h		;6bc5
cuenta_los_tiles_enteros:		; Divide entre cuatro restando: C se queda con los tiles llenos y A con el resto, de 0 a 3
	cp 004h		;6bc7   ; por debajo de cuatro ya no hay tile entero
	jr c,rellena_los_tiles_llenos		;6bc9
	sub 004h		;6bcb   ; cuatro menos...
	inc c			;6bcd   ; ...y un tile mas
	jr cuenta_los_tiles_enteros		;6bce
rellena_los_tiles_llenos:		; Con al menos un tile entero, un FILVRM de C posiciones con el tile que traiga la tira. La mitad del jugador se dibuja hacia atras: la posicion se corre restando C
	push bc			;6bd0
	ld b,a			;6bd1
	ld a,c			;6bd2
	and a			;6bd3   ; sin tiles enteros no hay relleno
	ld a,b			;6bd4
	pop bc			;6bd5
	jr z,y_el_tile_de_resto		;6bd6
	push hl			;6bd8
	push af			;6bd9
	push bc			;6bda
	ld a,(de)			;6bdb   ; el tile de la tira
	bit 0,b		;6bdc   ; la mitad del jugador va al reves
	jr z,rellena_los_tiles_llenos_si_no		;6bde
	push af			;6be0
	ld a,l			;6be1
	sub c			;6be2   ; la posicion, corrida hacia atras
	inc a			;6be3
	ld l,a			;6be4
	pop af			;6be5
rellena_los_tiles_llenos_si_no:		; Dentro de rellena_los_tiles_llenos
	ld b,000h		;6be6   ; C tiles
	call 00056h		;6be8   ; BIOS FILVRM - Fills VRAM with value | rellenados de una vez
	pop bc			;6beb
	pop af			;6bec
	pop hl			;6bed
y_el_tile_de_resto:		; Con el resto a cero se usa el cuarto de la tira; luego se avanza y, con nueve tiles ya puestos, se acabo
	and a			;6bee
	jr nz,y_el_tile_de_resto_si_no		;6bef   ; con resto, el que toque
	ld a,004h		;6bf1   ; y sin resto, cuatro mas alla
y_el_tile_de_resto_si_no:		; Dentro de y_el_tile_de_resto
	call suma_a_de		;6bf3   ; la tira avanza
	ld a,c			;6bf6
	cp 009h		;6bf7   ; nueve tiles es media barra entera
	ret z			;6bf9
	and a			;6bfa
	jr z,escribe_el_tile_de_la_barra		;6bfb
	bit 0,b		;6bfd
	jr z,corre_la_posicion		;6bff
	push af			;6c01
	ld a,l			;6c02
	sub c			;6c03
	ld l,a			;6c04
	pop af			;6c05
	jr escribe_el_tile_de_la_barra		;6c06
corre_la_posicion:		; Le suma a HL lo que traiga A
	call suma_a_hl		;6c08   ; la posicion, corrida
escribe_el_tile_de_la_barra:		; El tile de la tira, y si es la mitad del jugador se le suma 0x78 para usar el gemelo, el que mira al otro lado. Es el mismo 0x78 del descompresor de poses
	ld a,(de)			;6c0b   ; el tile de la tira
	bit 0,b		;6c0c   ; la mitad del jugador...
	jr z,escribe_el_tile_de_la_barra_si_no		;6c0e
	add a,078h		;6c10   ; ...usa el tile gemelo, 0x78 mas alla
escribe_el_tile_de_la_barra_si_no:		; Dentro de escribe_el_tile_de_la_barra
	jp 0004dh		;6c12   ; BIOS WRTVRM - Writes data in VRAM | y a la VRAM

; ----------------------------------------------------------------------
; DATOS cinco_tiles_a: Cinco tiles -0x67, 0x64, 0x65, 0x66 y 0x63- que 0x6bad
;   copia a la VRAM. No son letras: caen fuera del alfabeto
;   0x6c15..0x6c1a  (5 bytes)
DATA_cinco_tiles_a:
	defb 067h,064h,065h,066h,063h	; 6c15

; ----------------------------------------------------------------------
; DATOS cinco_tiles_b: Los otros cinco -0x6b, 0x68, 0x69, 0x6a y 0x63- que
;   carga 0x6ba8. Comparten el ultimo con los de arriba
;   0x6c1a..0x6c1f  (5 bytes)
DATA_cinco_tiles_b:
	defb 06bh,068h,069h,06ah,063h	; 6c1a

; ======================================================================
; CODIGO 0x6c1f..0x6c2b  (12 bytes)
; ======================================================================


escribe_cuatro_tiles:		; Indexa la tabla que traiga HL y copia cuatro tiles a la VRAM 0x3897. Es como se pinta el nombre del oponente en la fila 4
	call indexa_una_tabla_de_punteros		;6c1f   ; el puntero que toque
	ld hl,03897h		;6c22   ; HL = VRAM 0x3897, fila 4 columna 23
	ld bc,00004h		;6c25   ; cuatro tiles
	jp copia_a_vram		;6c28

; ----------------------------------------------------------------------
; DATOS tabla_de_los_nombres: Cinco punteros que 0x6b62 indexa por 0xE054, el
;   escenario: 0x6c35, 0x6c39, 0x6c3d, 0x6c41 y 0x6c45
;   0x6c2b..0x6c35  (10 bytes)
DATA_tabla_de_los_nombres:
	defw 06c35h,06c39h,06c3dh,06c41h,06c45h	; 6c2b

; ----------------------------------------------------------------------
; DATOS los_nombres_de_los_cinco: LOS NOMBRES DE LOS OPONENTES, cuatro tiles
;   cada uno y sin direccion delante porque van a la VRAM con LDIRVM y no por
;   el interprete de listas: WANG, " TAO", CHEN, LANG y "  WU". Los que no
;   llegan a cuatro letras van alineados a la derecha con tiles vacios
;   0x6c35..0x6c49  (20 bytes)
DATA_los_nombres_de_los_cinco:
	defb 037h,021h,02eh,027h	; 6c35
	defb 000h,034h,021h,02fh	; 6c39
	defb 023h,028h,025h,02eh	; 6c3d
	defb 02ch,021h,02eh,027h	; 6c41
	defb 000h,000h,037h,035h	; 6c45

; ======================================================================
; CODIGO 0x6c49..0x6c5b  (18 bytes)
; ======================================================================


escribe_stage_y_el_numero:		; STAGE en la VRAM 0x38eb y las dos cifras de la fase en la 0x38f1
	ld hl,038ebh		;6c49   ; HL = VRAM 0x38eb
	ld de,06c5bh		;6c4c   ; DE = 0x6c5b, los cinco tiles de STAGE
	ld bc,00005h		;6c4f   ; cinco
	call copia_a_vram		;6c52
	ld hl,038f1h		;6c55   ; y las dos cifras al lado
	jp dos_cifras_sin_tapar		;6c58

; ----------------------------------------------------------------------
; DATOS texto_stage: STAGE, cinco tiles que 0x6c4c copia a la VRAM con BC = 5
;   antes de escribir las dos cifras en 0x38f1
;   0x6c5b..0x6c60  (5 bytes)
DATA_texto_stage:
	defb 033h,034h,021h,027h,025h	; 6c5b

; ======================================================================
; CODIGO 0x6c60..0x6c6c  (12 bytes)
; ======================================================================


escribe_bonus_stage:		; BONUS STAGE, once tiles, en la VRAM 0x38ea
	ld hl,038eah		;6c60   ; HL = VRAM 0x38ea
escribe_bonus_stage_donde_diga_hl:		; La otra entrada, con el sitio ya puesto
	ld de,06c6ch		;6c63   ; DE = 0x6c6c, los once tiles
	ld bc,0000bh		;6c66   ; once
	jp copia_a_vram		;6c69

; ----------------------------------------------------------------------
; DATOS texto_bonus_stage: BONUS STAGE, once tiles que 0x6c63 copia con BC =
;   0x0b
;   0x6c6c..0x6c77  (11 bytes)
DATA_texto_bonus_stage:
	defb 022h,02fh,02eh,035h,033h,000h,033h,034h,021h,027h,025h	; 6c6c  "/.53.34!'%

; ======================================================================
; CODIGO 0x6c77..0x6ca0  (41 bytes)
; ======================================================================


le_quita_energia_al_oponente:		; Cuatro unidades de 0xE117
	ld a,(0e165h)		;6c77   ; el golpe que ha sido
	ld b,004h		;6c7a   ; cuatro unidades
	ld hl,0e117h		;6c7c   ; HL = 0xE117, la energia del oponente
	jr resta_sin_pasarse_de_cero		;6c7f
le_quita_energia_al_jugador:		; Las mismas cuatro, pero de 0xE116
	ld b,004h		;6c81   ; cuatro unidades
	ld hl,0e116h		;6c83   ; HL = 0xE116, la del jugador
	jp resta_sin_pasarse_de_cero		;6c86
resta_sin_pasarse_de_cero:		; Resta B y, si se pasa, deja cero
	ld a,(hl)			;6c89   ; la energia de ahora
	sub b			;6c8a   ; menos las unidades
	jr nc,resta_sin_pasarse_de_cero_si_no		;6c8b
	xor a			;6c8d
resta_sin_pasarse_de_cero_si_no:		; Dentro de resta_sin_pasarse_de_cero
	ld (hl),a			;6c8e
	ret			;6c8f
el_cuadro_del_primer_oponente:		; Con 0xE16b a cero se acerca; si no, monta la pose de 0x6e5b y recoloca
	ld a,(0e16bh)		;6c90   ; el plazo del movimiento
	and a			;6c93
	jp z,mira_donde_esta		;6c94   ; a cero, a acercarse
	ld hl,06e5bh		;6c97   ; HL = 0x6e5b, su pose
	call elige_el_movimiento_del_oponente		;6c9a
	jp borra_y_recoloca_al_oponente		;6c9d

; ----------------------------------------------------------------------
; DATOS despacho_escenario_0: Siete punteros a rutina. El primero y el quinto
;   -0x73a2 y 0x74a2- son comunes a los cinco escenarios. Los 7 punteros:
;   0x73a2 0x6cbb 0x6cbb 0x6cb8 0x74a2 0x74d1 0x74d1
;   0x6ca0..0x6cae  (14 bytes)
DATA_despacho_escenario_0:
	defw 073a2h,06cbbh,06cbbh,06cb8h,074a2h,074d1h,074d1h	; 6ca0

; ======================================================================
; CODIGO 0x6cae..0x6cc1  (19 bytes)
; ======================================================================


el_cuadro_del_primer_oponente_otra_vuelta:		; Dentro de el_cuadro_del_primer_oponente
	ld a,(0e003h)		;6cae
	and 03eh		;6cb1
	ret nz			;6cb3
	pop hl			;6cb4
	jp el_otro_paso_de_todos		;6cb5
el_cuadro_del_primer_oponente_si_no:		; Dentro de el_cuadro_del_primer_oponente
	call el_cuadro_del_primer_oponente_otra_vuelta		;6cb8
el_cuadro_del_primer_oponente_si_no_2:		; Dentro de el_cuadro_del_primer_oponente
	call que_golpe_cuenta		;6cbb
	call despacha_por_la_tabla_de_al_lado		;6cbe

; ----------------------------------------------------------------------
; DATOS tabla_de_submodos_escenario_0: La que 0x6cbe despacha con la tabla
;   detras del `call`. Los 6 punteros: 0x6ccd 0x6cec 0x6cfc 0x6d0b 0x6d1b
;   0x6d0b
;   0x6cc1..0x6ccd  (12 bytes)
DATA_tabla_de_submodos_escenario_0:
	defw 06ccdh,06cech,06cfch,06d0bh,06d1bh,06d0bh	; 6cc1

; ======================================================================
; CODIGO 0x6ccd..0x6d4b  (126 bytes)
; ======================================================================


el_oponente_no_hace_nada:		; Baja 0xE169 y, cuando llega a cero, lo repone a 0x0a y sube 0xE168 dentro del tramo de 3 a 6
	ld hl,0e169h		;6ccd   ; HL = 0xE169, la cuenta
	dec (hl)			;6cd0   ; un cuadro menos
	ld a,(hl)			;6cd1
	and a			;6cd2
	ret nz			;6cd3
	ld a,00ah		;6cd4   ; y vuelta a empezar, 0x0a cuadros
	ld (0e169h),a		;6cd6
	ld hl,0e168h		;6cd9   ; HL = 0xE168
	ld a,(hl)			;6cdc
	inc a			;6cdd   ; uno mas
	cp 003h		;6cde   ; por debajo de 3...
	jr c,el_oponente_no_hace_nada_si_no		;6ce0
	cp 007h		;6ce2   ; ...o de 7...
	jr c,el_oponente_no_hace_nada_si_no_2		;6ce4
el_oponente_no_hace_nada_si_no:		; Dentro de el_oponente_no_hace_nada
	ld a,003h		;6ce6   ; ...se queda en 3
el_oponente_no_hace_nada_si_no_2:		; Dentro de el_oponente_no_hace_nada
	ld (hl),a			;6ce8
	jp fija_el_movimiento_y_su_plazo		;6ce9
caracter_a:		; Con el azar en 1 o 2 no hace nada, con el 3 va a 0x7458 y con el 0 a 0x744a
	call saca_un_numero_al_azar		;6cec   ; el azar, de 0 a 3
	dec a			;6cef   ; el 1...
	jr z,el_oponente_no_hace_nada		;6cf0
	dec a			;6cf2   ; ...y el 2, quietos
	jr z,el_oponente_no_hace_nada		;6cf3
	dec a			;6cf5   ; el 3, a 0x7458
	jp z,pide_el_movimiento_cinco		;6cf6
el_oponente_avisa:		; Un salto suelto a 0x744a al que se llama por su nombre
	jp pide_cuatro_cuadros_de_espera		;6cf9   ; y a 0x744a
caracter_b:		; El 1 y el 2 avisan, el 3 tambien y el 0 se queda quieto
	call saca_un_numero_al_azar		;6cfc   ; el azar
	dec a			;6cff   ; el 1...
	jr z,el_oponente_avisa		;6d00
	dec a			;6d02   ; ...y el 2, avisan
	jr z,el_oponente_avisa		;6d03
	dec a			;6d05   ; el 3, igual
	jp z,pide_cuatro_cuadros_de_espera		;6d06
	jr el_oponente_no_hace_nada		;6d09
caracter_c:		; El 1 quieto, el 2 avisa, el 3 va a 0x7454 y el 0 quieto
	call saca_un_numero_al_azar		;6d0b   ; el azar
	dec a			;6d0e   ; el 1, quieto
	jr z,el_oponente_no_hace_nada		;6d0f
	dec a			;6d11   ; el 2, avisa
	jr z,el_oponente_avisa		;6d12
	dec a			;6d14   ; y el 3, a 0x7454
	jp z,pide_el_movimiento_cuatro		;6d15
	jp el_oponente_no_hace_nada		;6d18
caracter_d:		; El mas movido: el 1 avisa, el 2 va a 0x7450, el 3 a 0x73cd y el 0 a 0x7458
	call saca_un_numero_al_azar		;6d1b   ; el azar
	dec a			;6d1e   ; el 1, avisa
	jr z,el_oponente_avisa		;6d1f
	dec a			;6d21   ; el 2, a 0x7450
	jp z,pide_el_movimiento_seis		;6d22
	dec a			;6d25   ; el 3, a 0x73cd
	jp z,pide_nueve_cuadros_de_espera		;6d26
	jp pide_el_movimiento_cinco		;6d29   ; y el 0, a 0x7458
saca_un_numero_al_azar:		; Corre el registro de diez bytes de 0xE135 dos posiciones y devuelve los dos bits bajos, o sea un numero de 0 a 3
	ld b,002h		;6d2c   ; dos vueltas
una_vuelta_del_registro:		; El bit de arriba sale por 0xE13e, se arrastra por los nueve de abajo y vuelve a entrar por arriba
	push bc			;6d2e
	ld hl,0e13eh		;6d2f   ; HL = 0xE13e, el byte alto
	ld a,(hl)			;6d32
	srl a		;6d33   ; su bit 0 al acarreo
	dec hl			;6d35
	ld b,009h		;6d36   ; nueve bytes por debajo
una_vuelta_del_registro_otra_vuelta:		; Dentro de una_vuelta_del_registro
	rr (hl)		;6d38   ; arrastrando el acarreo
	dec hl			;6d3a
	djnz una_vuelta_del_registro_otra_vuelta		;6d3b
	ld hl,0e13eh		;6d3d
	rr (hl)		;6d40   ; y el ultimo bit vuelve a entrar por arriba
	pop bc			;6d42
	djnz una_vuelta_del_registro		;6d43
	ld a,(0e135h)		;6d45   ; los dos bits bajos...
	and 003h		;6d48   ; ...que es el numero de 0 a 3
	ret			;6d4a

; ----------------------------------------------------------------------
; DATOS tabla_de_poses_oponente_0: Los 18 punteros que 0x5553 indexa por
;   0xE184 para el oponente 0. El primer destino es 0x6d6f, que es justo donde
;   acaba la tabla
;   0x6d4b..0x6d6f  (36 bytes)
DATA_tabla_de_poses_oponente_0:
	defw 06d9eh,06db8h,06d6fh,06d7ch,06dfdh,06e17h,06d9eh,06db8h,06dddh,06df6h,06e1eh,06e37h,06dbfh,06dd6h,06e3eh,06e54h	; 6d4b
	defw 06d83h,06d97h	; 6d6b  -> DATA_pose_oponente_0_6d83 DATA_pose_oponente_0_6d97

; ----------------------------------------------------------------------
; DATOS pose_oponente_0_6d6f: 13 bytes, largo. Indice 2 de la tabla de 0x6d4b
;   0x6d6f..0x6d7c  (13 bytes)
DATA_pose_oponente_0_6d6f:
	defb 0fah,0f9h,0f4h,008h,0feh,0ffh,005h,004h,000h,010h,0e3h,0ffh,011h	; 6d6f  .............

; ----------------------------------------------------------------------
; DATOS pose_oponente_0_6d7c: 7 bytes, corto. Indice 3 de la tabla de 0x6d4b
;   0x6d7c..0x6d83  (7 bytes)
DATA_pose_oponente_0_6d7c:
	defb 0feh,0ffh,0f2h,006h,0feh,074h,06dh	; 6d7c

; ----------------------------------------------------------------------
; DATOS pose_oponente_0_6d83: 20 bytes, largo. Indice 16 de la tabla de 0x6d4b
;   0x6d83..0x6d97  (20 bytes)
DATA_pose_oponente_0_6d83:
	defb 0f3h,0f1h,0f4h,006h,0fdh,0ffh,005h,004h,000h,010h,0e3h,0f7h,011h,000h,019h,01ah,020h,000h,0f3h,021h	; 6d83  ................ ..!

; ----------------------------------------------------------------------
; DATOS pose_oponente_0_6d97: 7 bytes, corto. Indice 17 de la tabla de 0x6d4b
;   0x6d97..0x6d9e  (7 bytes)
DATA_pose_oponente_0_6d97:
	defb 0feh,005h,000h,006h,0ffh,088h,06dh	; 6d97

; ----------------------------------------------------------------------
; DATOS pose_oponente_0_6d9e: 26 bytes, largo. Indice 0, 6 de la tabla de
;   0x6d4b
;   0x6d9e..0x6db8  (26 bytes)
DATA_pose_oponente_0_6d9e:
	defb 002h,001h,000h,000h,0ffh,000h,074h,004h,006h,000h,0f3h,011h,0e2h,024h,025h,016h,0f5h,026h,01ah,01bh,0e2h,02bh,02ch,01eh,01fh,0e2h	; 6d9e  ......t......$%..&...+,...

; ----------------------------------------------------------------------
; DATOS pose_oponente_0_6db8: 7 bytes, corto. Indice 1, 7 de la tabla de
;   0x6d4b
;   0x6db8..0x6dbf  (7 bytes)
DATA_pose_oponente_0_6db8:
	defb 0f6h,0f7h,000h,000h,0fbh,0a3h,06dh	; 6db8

; ----------------------------------------------------------------------
; DATOS pose_oponente_0_6dbf: 23 bytes, largo. Indice 12 de la tabla de 0x6d4b
;   0x6dbf..0x6dd6  (23 bytes)
DATA_pose_oponente_0_6dbf:
	defb 0fah,0f9h,0f4h,008h,0fch,000h,081h,0e8h,004h,006h,0f3h,02dh,011h,030h,0e3h,0f4h,031h,0e2h,0f4h,018h,0e2h,0f4h,01ch	; 6dbf  ...........-.0..1......

; ----------------------------------------------------------------------
; DATOS pose_oponente_0_6dd6: 7 bytes, corto. Indice 13 de la tabla de 0x6d4b
;   0x6dd6..0x6ddd  (7 bytes)
DATA_pose_oponente_0_6dd6:
	defb 0f6h,0f8h,000h,000h,0feh,0c4h,06dh	; 6dd6

; ----------------------------------------------------------------------
; DATOS pose_oponente_0_6ddd: 25 bytes, largo. Indice 8 de la tabla de 0x6d4b
;   0x6ddd..0x6df6  (25 bytes)
DATA_pose_oponente_0_6ddd:
	defb 0fah,0fah,0f4h,008h,0fch,000h,082h,0e8h,004h,006h,0e3h,011h,030h,000h,0a0h,027h,0f3h,035h,034h,0e2h,0f4h,018h,0e2h,0f4h,01ch	; 6ddd  ............0..'.54......

; ----------------------------------------------------------------------
; DATOS pose_oponente_0_6df6: 7 bytes, corto. Indice 9 de la tabla de 0x6d4b
;   0x6df6..0x6dfd  (7 bytes)
DATA_pose_oponente_0_6df6:
	defb 0feh,0ffh,0f2h,006h,0feh,0e2h,06dh	; 6df6

; ----------------------------------------------------------------------
; DATOS pose_oponente_0_6dfd: 26 bytes, largo. Indice 4 de la tabla de 0x6d4b
;   0x6dfd..0x6e17  (26 bytes)
DATA_pose_oponente_0_6dfd:
	defb 000h,0f8h,00ch,0fch,0fch,001h,073h,083h,0e8h,003h,007h,0e3h,011h,030h,0e2h,0a0h,027h,0f3h,035h,034h,0e3h,038h,02ah,01ah,039h,03ah	; 6dfd  ......s......0..'.54.8*.9:

; ----------------------------------------------------------------------
; DATOS pose_oponente_0_6e17: 7 bytes, corto. Indice 5 de la tabla de 0x6d4b
;   0x6e17..0x6e1e  (7 bytes)
DATA_pose_oponente_0_6e17:
	defb 002h,000h,0feh,006h,0fdh,002h,06eh	; 6e17

; ----------------------------------------------------------------------
; DATOS pose_oponente_0_6e1e: 25 bytes, largo. Indice 10 de la tabla de 0x6d4b
;   0x6e1e..0x6e37  (25 bytes)
DATA_pose_oponente_0_6e1e:
	defb 0f2h,0f2h,0f8h,0f8h,0fch,000h,082h,0e2h,004h,006h,0e2h,0f3h,011h,000h,0f4h,03bh,026h,028h,000h,0f4h,03fh,0e3h,043h,01fh,0e2h	; 6e1e  ...............;&(..?.C..

; ----------------------------------------------------------------------
; DATOS pose_oponente_0_6e37: 7 bytes, corto. Indice 11 de la tabla de 0x6d4b
;   0x6e37..0x6e3e  (7 bytes)
DATA_pose_oponente_0_6e37:
	defb 006h,006h,002h,002h,0feh,023h,06eh	; 6e37

; ----------------------------------------------------------------------
; DATOS pose_oponente_0_6e3e: 22 bytes, largo. Indice 14 de la tabla de 0x6d4b
;   0x6e3e..0x6e54  (22 bytes)
DATA_pose_oponente_0_6e3e:
	defb 000h,000h,000h,000h,0feh,001h,003h,005h,000h,044h,000h,0bch,0e2h,045h,046h,0bdh,000h,047h,048h,004h,0c0h,0bfh	; 6e3e  .........D...EF..GH...

; ----------------------------------------------------------------------
; DATOS pose_oponente_0_6e54: 37 bytes, largo. Indice 15 de la tabla de 0x6d4b
;   (el ultimo, que llega hasta donde acaba el bloque)
;   0x6e54..0x6e79  (37 bytes)
DATA_pose_oponente_0_6e54:
	defb 000h,000h,000h,000h,0feh,043h,06eh,06dh,06eh,044h,077h,040h,077h,04ch,077h,044h,077h,06dh,06eh,040h,077h,071h,06eh,075h,06eh,002h,000h,00ch,002h,004h,004h,004h,004h,000h,000h,000h,000h	; 6e54  .....CnmnDw@wLwDwmn@wqnun............

; ======================================================================
; CODIGO 0x6e79..0x6e8f  (22 bytes)
; ======================================================================


el_cuadro_del_segundo_oponente:		; Mueve las armas y, con 0xE16b puesto, elige movimiento con la lista de 0x6ffe y lanza
	call mueve_las_tres_armas		;6e79   ; las tres armas
	ld a,(0e16bh)		;6e7c   ; el plazo del movimiento
	and a			;6e7f
	jp z,mira_donde_esta		;6e80
	ld hl,06ffeh		;6e83   ; la lista de este oponente
	call elige_el_movimiento_del_oponente		;6e86
	call lanza_el_arma		;6e89   ; el arma, lanzada
	jp borra_y_recoloca_al_oponente		;6e8c

; ----------------------------------------------------------------------
; DATOS despacho_escenario_1: Siete punteros a rutina, misma forma. Los 7
;   punteros: 0x73a2 0x6ea0 0x6ea0 0x6e9d 0x74a2 0x74c7 0x74c7
;   0x6e8f..0x6e9d  (14 bytes)
DATA_despacho_escenario_1:
	defw 073a2h,06ea0h,06ea0h,06e9dh,074a2h,074c7h,074c7h	; 6e8f

; ======================================================================
; CODIGO 0x6e9d..0x6ea6  (9 bytes)
; ======================================================================


el_cuadro_del_segundo_oponente_si_no:		; Dentro de el_cuadro_del_segundo_oponente
	call el_cuadro_del_primer_oponente_otra_vuelta		;6e9d
el_cuadro_del_segundo_oponente_si_no_2:		; Dentro de el_cuadro_del_segundo_oponente
	call que_golpe_cuenta		;6ea0
	call despacha_por_la_tabla_de_al_lado		;6ea3

; ----------------------------------------------------------------------
; DATOS tabla_de_submodos_escenario_1: La que despacha 0x6ea3. Los 6 punteros:
;   0x6ccd 0x6eb2 0x6ec4 0x6ed6 0x6ee8 0x6ed6
;   0x6ea6..0x6eb2  (12 bytes)
DATA_tabla_de_submodos_escenario_1:
	defw 06ccdh,06eb2h,06ec4h,06ed6h,06ee8h,06ed6h	; 6ea6

; ======================================================================
; CODIGO 0x6eb2..0x6efa  (72 bytes)
; ======================================================================


caracter_6eb2:		; Pide un numero de 0 a 3 y reparte: el 1 a el_oponente_no_hace_nada, el 2 a 0x7458, el 3 a 0x747e, y el 0 a 0x744a
	call saca_un_numero_al_azar		;6eb2   ; el azar, de 0 a 3
	dec a			;6eb5
	jp z,el_oponente_no_hace_nada		;6eb6   ; el 1, a el_oponente_no_hace_nada
	dec a			;6eb9
	jp z,pide_el_movimiento_cinco		;6eba   ; el 2, a 0x7458
	dec a			;6ebd
	jp z,pide_el_movimiento_seis_otra_vez		;6ebe   ; el 3, a 0x747e
	jp pide_cuatro_cuadros_de_espera		;6ec1   ; y el 0, a 0x744a
caracter_6ec4:		; Pide un numero de 0 a 3 y reparte: el 1 a 0x7458, el 2 a 0x7482, el 3 a 0x747e, y el 0 a 0x744a
	call saca_un_numero_al_azar		;6ec4   ; el azar, de 0 a 3
	dec a			;6ec7
	jp z,pide_el_movimiento_cinco		;6ec8   ; el 1, a 0x7458
	dec a			;6ecb
	jp z,caracter_7482		;6ecc   ; el 2, a 0x7482
	dec a			;6ecf
	jp z,pide_el_movimiento_seis_otra_vez		;6ed0   ; el 3, a 0x747e
	jp pide_cuatro_cuadros_de_espera		;6ed3   ; y el 0, a 0x744a
caracter_6ed6:		; Pide un numero de 0 a 3 y reparte: el 1 a 0x7458, el 2 a 0x747e, el 3 a 0x744a, y el 0 a el_oponente_no_hace_nada
	call saca_un_numero_al_azar		;6ed6   ; el azar, de 0 a 3
	dec a			;6ed9
	jp z,pide_el_movimiento_cinco		;6eda   ; el 1, a 0x7458
	dec a			;6edd
	jp z,pide_el_movimiento_seis_otra_vez		;6ede   ; el 2, a 0x747e
	dec a			;6ee1
	jp z,pide_cuatro_cuadros_de_espera		;6ee2   ; el 3, a 0x744a
	jp el_oponente_no_hace_nada		;6ee5   ; y el 0, a el_oponente_no_hace_nada
caracter_6ee8:		; Pide un numero de 0 a 3 y reparte: el 1 a 0x7458, el 2 a 0x747e, el 3 a 0x744a, y el 0 a 0x744a
	call saca_un_numero_al_azar		;6ee8   ; el azar, de 0 a 3
	dec a			;6eeb
	jp z,pide_el_movimiento_cinco		;6eec   ; el 1, a 0x7458
	dec a			;6eef
	jp z,pide_el_movimiento_seis_otra_vez		;6ef0   ; el 2, a 0x747e
	dec a			;6ef3
	jp z,pide_cuatro_cuadros_de_espera		;6ef4   ; el 3, a 0x744a
	jp pide_cuatro_cuadros_de_espera		;6ef7   ; y el 0, a 0x744a

; ----------------------------------------------------------------------
; DATOS tabla_de_poses_oponente_1: Los 18 punteros que 0x5553 indexa por
;   0xE184 para el oponente 1. El primer destino es 0x6f1e, que es justo donde
;   acaba la tabla
;   0x6efa..0x6f1e  (36 bytes)
DATA_tabla_de_poses_oponente_1:
	defw 06f1eh,06f29h,06fadh,06fc0h,06f44h,06f53h,06f5ah,06f67h,06f6eh,06f86h,06f8dh,06fa6h,06f30h,06f3dh,06fc7h,06fddh	; 6efa
	defw 06fe4h,06ff7h	; 6f1a  -> DATA_pose_oponente_1_6fe4 DATA_pose_oponente_1_6ff7

; ----------------------------------------------------------------------
; DATOS pose_oponente_1_6f1e: 11 bytes, largo. Indice 0 de la tabla de 0x6efa
;   0x6f1e..0x6f29  (11 bytes)
DATA_pose_oponente_1_6f1e:
	defb 000h,0fbh,0fah,008h,0ffh,000h,004h,003h,000h,0fbh,010h	; 6f1e  ...........

; ----------------------------------------------------------------------
; DATOS pose_oponente_1_6f29: 7 bytes, corto. Indice 1 de la tabla de 0x6efa
;   0x6f29..0x6f30  (7 bytes)
DATA_pose_oponente_1_6f29:
	defb 0f6h,0f8h,0f2h,000h,0feh,023h,06fh	; 6f29

; ----------------------------------------------------------------------
; DATOS pose_oponente_1_6f30: 13 bytes, largo. Indice 12 de la tabla de 0x6efa
;   0x6f30..0x6f3d  (13 bytes)
DATA_pose_oponente_1_6f30:
	defb 0f8h,0fah,0f9h,008h,0ffh,000h,004h,003h,010h,0f8h,01bh,0f3h,018h	; 6f30  .............

; ----------------------------------------------------------------------
; DATOS pose_oponente_1_6f3d: 7 bytes, corto. Indice 13 de la tabla de 0x6efa
;   0x6f3d..0x6f44  (7 bytes)
DATA_pose_oponente_1_6f3d:
	defb 0feh,0ffh,001h,0f2h,0feh,035h,06fh	; 6f3d

; ----------------------------------------------------------------------
; DATOS pose_oponente_1_6f44: 15 bytes, largo. Indice 4 de la tabla de 0x6efa
;   0x6f44..0x6f53  (15 bytes)
DATA_pose_oponente_1_6f44:
	defb 000h,0f8h,0f5h,000h,0feh,001h,071h,003h,004h,000h,010h,01bh,01ch,0f8h,023h	; 6f44  ......q.......#

; ----------------------------------------------------------------------
; DATOS pose_oponente_1_6f53: 7 bytes, corto. Indice 5 de la tabla de 0x6efa
;   0x6f53..0x6f5a  (7 bytes)
DATA_pose_oponente_1_6f53:
	defb 000h,000h,005h,0fah,0feh,049h,06fh	; 6f53

; ----------------------------------------------------------------------
; DATOS pose_oponente_1_6f5a: 13 bytes, largo. Indice 6 de la tabla de 0x6efa
;   0x6f5a..0x6f67  (13 bytes)
DATA_pose_oponente_1_6f5a:
	defb 000h,000h,0fah,000h,0ffh,002h,073h,002h,003h,000h,010h,0f4h,02bh	; 6f5a  ......s.....+

; ----------------------------------------------------------------------
; DATOS pose_oponente_1_6f67: 7 bytes, corto. Indice 7 de la tabla de 0x6efa
;   0x6f67..0x6f6e  (7 bytes)
DATA_pose_oponente_1_6f67:
	defb 000h,000h,000h,0fah,0feh,05fh,06fh	; 6f67

; ----------------------------------------------------------------------
; DATOS pose_oponente_1_6f6e: 24 bytes, largo. Indice 8 de la tabla de 0x6efa
;   0x6f6e..0x6f86  (24 bytes)
DATA_pose_oponente_1_6f6e:
	defb 0f8h,0f3h,000h,000h,0fch,000h,082h,0e3h,004h,005h,000h,02fh,030h,010h,011h,0f5h,031h,000h,0f3h,036h,017h,0e3h,039h,01ah	; 6f6e  .........../0...1..6..9.

; ----------------------------------------------------------------------
; DATOS pose_oponente_1_6f86: 7 bytes, corto. Indice 9 de la tabla de 0x6efa
;   0x6f86..0x6f8d  (7 bytes)
DATA_pose_oponente_1_6f86:
	defb 0feh,005h,0fah,0fah,0ffh,073h,06fh	; 6f86

; ----------------------------------------------------------------------
; DATOS pose_oponente_1_6f8d: 25 bytes, largo. Indice 10 de la tabla de 0x6efa
;   0x6f8d..0x6fa6  (25 bytes)
DATA_pose_oponente_1_6f8d:
	defb 0f0h,0ebh,0f0h,0f0h,0fch,000h,081h,0e3h,004h,004h,02fh,03ah,010h,011h,03bh,03ch,034h,035h,000h,0f3h,03dh,000h,040h,018h,041h	; 6f8d  ........../:..;<45..=.@.A

; ----------------------------------------------------------------------
; DATOS pose_oponente_1_6fa6: 7 bytes, corto. Indice 11 de la tabla de 0x6efa
;   0x6fa6..0x6fad  (7 bytes)
DATA_pose_oponente_1_6fa6:
	defb 006h,00dh,00bh,00bh,000h,092h,06fh	; 6fa6

; ----------------------------------------------------------------------
; DATOS pose_oponente_1_6fad: 19 bytes, largo. Indice 2 de la tabla de 0x6efa
;   0x6fad..0x6fc0  (19 bytes)
DATA_pose_oponente_1_6fad:
	defb 000h,0fch,0f8h,008h,0feh,000h,004h,004h,0e2h,010h,0f5h,042h,000h,015h,047h,048h,000h,0f3h,018h	; 6fad  ...........B..GH...

; ----------------------------------------------------------------------
; DATOS pose_oponente_1_6fc0: 7 bytes, corto. Indice 3 de la tabla de 0x6efa
;   0x6fc0..0x6fc7  (7 bytes)
DATA_pose_oponente_1_6fc0:
	defb 0f0h,0fdh,0f2h,002h,0feh,0b2h,06fh	; 6fc0

; ----------------------------------------------------------------------
; DATOS pose_oponente_1_6fc7: 22 bytes, largo. Indice 14 de la tabla de 0x6efa
;   0x6fc7..0x6fdd  (22 bytes)
DATA_pose_oponente_1_6fc7:
	defb 000h,000h,000h,000h,0feh,001h,003h,005h,000h,04eh,000h,0c6h,0e2h,04fh,052h,0c7h,000h,050h,051h,00dh,0c9h,0c8h	; 6fc7  .........N...OR..PQ...

; ----------------------------------------------------------------------
; DATOS pose_oponente_1_6fdd: 7 bytes, corto. Indice 15 de la tabla de 0x6efa
;   0x6fdd..0x6fe4  (7 bytes)
DATA_pose_oponente_1_6fdd:
	defb 000h,000h,000h,000h,0fdh,0cch,06fh	; 6fdd

; ----------------------------------------------------------------------
; DATOS pose_oponente_1_6fe4: 19 bytes, largo. Indice 16 de la tabla de 0x6efa
;   0x6fe4..0x6ff7  (19 bytes)
DATA_pose_oponente_1_6fe4:
	defb 0f8h,0f4h,0f8h,0feh,0fdh,000h,004h,004h,0e2h,010h,0f5h,042h,000h,049h,047h,04ah,000h,0f3h,04bh	; 6fe4  ...........B.IGJ..K

; ----------------------------------------------------------------------
; DATOS pose_oponente_1_6ff7: 27 bytes, largo. Indice 17 de la tabla de 0x6efa
;   (el ultimo, que llega hasta donde acaba el bloque)
;   0x6ff7..0x7012  (27 bytes)
DATA_pose_oponente_1_6ff7:
	defb 0feh,005h,002h,002h,0ffh,0e9h,06fh,06dh,06eh,040h,077h,00eh,070h,050h,077h,04ch,077h,050h,077h,04ch,077h,054h,077h,002h,000h,006h,002h	; 6ff7  ......omn@w.pPwLwPwLwTw....

; ======================================================================
; CODIGO 0x7012..0x702c  (26 bytes)
; ======================================================================


el_cuadro_del_tercer_oponente:		; Con 0xE1c0 puesto atiende el arma larga; si no, y con 0xE16b puesto, elige movimiento con la lista de 0x7302 y lanza
	ld a,(0e1c0h)		;7012   ; el arma larga en marcha
	and a			;7015
	jp nz,atiende_el_arma_larga		;7016
	ld a,(0e16bh)		;7019   ; el plazo del movimiento
	and a			;701c
	jp z,mira_donde_esta		;701d
	ld hl,07302h		;7020   ; la lista de este oponente
	call elige_el_movimiento_del_oponente		;7023
	call lanza_el_arma_del_oponente_dos		;7026   ; el arma, lanzada
	jp borra_y_recoloca_al_oponente		;7029

; ----------------------------------------------------------------------
; DATOS despacho_escenario_2: Siete punteros a rutina, misma forma. Los 7
;   punteros: 0x73a2 0x73b1 0x703d 0x703a 0x74a2 0x709a 0x74d1
;   0x702c..0x703a  (14 bytes)
DATA_despacho_escenario_2:
	defw 073a2h,073b1h,0703dh,0703ah,074a2h,0709ah,074d1h	; 702c

; ======================================================================
; CODIGO 0x703a..0x7043  (9 bytes)
; ======================================================================


el_cuadro_del_tercer_oponente_si_no:		; Dentro de el_cuadro_del_tercer_oponente
	call el_cuadro_del_primer_oponente_otra_vuelta		;703a
el_cuadro_del_tercer_oponente_si_no_2:		; Dentro de el_cuadro_del_tercer_oponente
	call que_golpe_cuenta		;703d
	call despacha_por_la_tabla_de_al_lado		;7040

; ----------------------------------------------------------------------
; DATOS tabla_de_submodos_escenario_2: La que despacha 0x7040. Los 6 punteros:
;   0x6ccd 0x704f 0x7061 0x7073 0x7089 0x7482
;   0x7043..0x704f  (12 bytes)
DATA_tabla_de_submodos_escenario_2:
	defw 06ccdh,0704fh,07061h,07073h,07089h,07482h	; 7043

; ======================================================================
; CODIGO 0x704f..0x70e9  (154 bytes)
; ======================================================================


caracter_704f:		; Pide un numero de 0 a 3 y reparte: el 1 a 0x744a, el 2 a 0x7482, el 3 a 0x7458, y el 0 a 0x744a
	call saca_un_numero_al_azar		;704f   ; el azar, de 0 a 3
	dec a			;7052
	jp z,pide_cuatro_cuadros_de_espera		;7053   ; el 1, a 0x744a
	dec a			;7056
	jp z,caracter_7482		;7057   ; el 2, a 0x7482
	dec a			;705a
	jp z,pide_el_movimiento_cinco		;705b   ; el 3, a 0x7458
	jp pide_cuatro_cuadros_de_espera		;705e   ; y el 0, a 0x744a
caracter_7061:		; Pide un numero de 0 a 3 y reparte: el 1 a 0x7482, el 2 a 0x747e, el 3 a 0x7482, y el 0 a 0x7458
	call saca_un_numero_al_azar		;7061   ; el azar, de 0 a 3
	dec a			;7064
	jp z,caracter_7482		;7065   ; el 1, a 0x7482
	dec a			;7068
	jp z,pide_el_movimiento_seis_otra_vez		;7069   ; el 2, a 0x747e
	dec a			;706c
	jp z,caracter_7482		;706d   ; el 3, a 0x7482
	jp pide_el_movimiento_cinco		;7070   ; y el 0, a 0x7458
caracter_7073:		; Pide un numero de 0 a 3 y reparte: el 1 a 0x7084, el 2 a 0x747e, el 3 a 0x7458, y el 0 a 0x7482
	call saca_un_numero_al_azar		;7073   ; el azar, de 0 a 3
	dec a			;7076
	jr z,pide_el_movimiento_ocho		;7077   ; el 1, a 0x7084
	dec a			;7079
	jp z,pide_el_movimiento_seis_otra_vez		;707a   ; el 2, a 0x747e
	dec a			;707d
	jp z,pide_el_movimiento_cinco		;707e   ; el 3, a 0x7458
	jp caracter_7482		;7081   ; y el 0, a 0x7482
pide_el_movimiento_ocho:		; A = 8 y al plazo de 0x745a
	ld a,008h		;7084
	jp el_movimiento_con_el_otro_plazo		;7086
caracter_7089:		; Pide un numero de 0 a 3 y reparte: el 1 a 0x747e, el 2 a 0x7084, el 3 a 0x7482, y el 0 a 0x744a
	call saca_un_numero_al_azar		;7089   ; el azar, de 0 a 3
	dec a			;708c
	jp z,pide_el_movimiento_seis_otra_vez		;708d   ; el 1, a 0x747e
	dec a			;7090
	jr z,pide_el_movimiento_ocho		;7091   ; el 2, a 0x7084
	dec a			;7093
	jp z,caracter_7482		;7094   ; el 3, a 0x7482
	jp pide_cuatro_cuadros_de_espera		;7097   ; y el 0, a 0x744a
caracter_7089_si_no:		; Dentro de caracter_7089
	ld hl,0e1c6h		;709a
	jp gira_cada_sesenta_y_cuatro_cuadros		;709d
lanza_el_arma_del_oponente_dos:		; Como 0x7515 pero para el oponente 2, con su propio juego de bytes en 0xE1c0: patron de la tabla de 0x70e9, lado en 0xE1c4, y la columna en 0xE1c2 corrida dos a la derecha o cuatro a la izquierda
	ld a,(0e056h)		;70a0   ; la dificultad de 0xE056
	ld hl,07592h		;70a3   ; elige el umbral
	call suma_a_hl		;70a6
	ld a,(0e16bh)		;70a9   ; contra 0xE16b
	cp (hl)			;70ac
	ret nz			;70ad   ; sin coincidir, nada
	ld a,(0e16ah)		;70ae   ; y 0xE16a por debajo de 3
	cp 003h		;70b1
	ret nc			;70b3
	ld a,(0e1c6h)		;70b4   ; 0xE1c6 elige el patron
	inc a			;70b7
	ld (0e1b1h),a		;70b8   ; y uno mas, a 0xE1b1
	dec a			;70bb
	ld de,070e9h		;70bc   ; la tabla de los tres patrones
	call suma_a_de		;70bf
	ld a,(de)			;70c2
	ld (0e1c1h),a		;70c3   ; el patron, guardado
	ld hl,0e1c4h		;70c6
	ld de,0e1c0h		;70c9
	ld a,(0e185h)		;70cc
	ld (hl),a			;70cf   ; el lado, apuntado
	ld a,001h		;70d0
	ld (de),a			;70d2   ; y el arma, en marcha
	ld a,(0e181h)		;70d3   ; la columna del oponente
	ld b,a			;70d6
	ld a,(hl)			;70d7
	and a			;70d8
	ld a,002h		;70d9   ; dos a la derecha...
	jr z,lanza_el_arma_del_oponente_dos_si_no		;70db
	ld a,0fch		;70dd   ; ...o cuatro a la izquierda, que es el 0xFC
lanza_el_arma_del_oponente_dos_si_no:		; Dentro de lanza_el_arma_del_oponente_dos
	add a,b			;70df
	ld (0e1c2h),a		;70e0   ; y esa es la columna del arma
	ld a,012h		;70e3   ; 0xE1c3 a 0x12
	ld (0e1c3h),a		;70e5
	ret			;70e8

; ----------------------------------------------------------------------
; DATOS tres_patrones_mas: Tres bytes, 0x12, 0x13 y 0x14, que 0x70bf indexa y
;   deja en 0xE1c1
;   0x70e9..0x70ec  (3 bytes)
DATA_tres_patrones_mas:
	defb 012h,013h,014h	; 70e9

; ======================================================================
; CODIGO 0x70ec..0x714a  (94 bytes)
; ======================================================================


atiende_el_arma_larga:		; Con 0xE1c3 a cero la apaga; si no, le baja un cuadro
	ld hl,0e1c3h		;70ec   ; HL = 0xE1c3, la cuenta
	ld a,(hl)			;70ef
	and a			;70f0
	jr nz,el_arma_larga_avanza		;70f1
	ld (0e1c0h),a		;70f3   ; agotada: el arma se apaga
	ret			;70f6
el_arma_larga_avanza:		; Un cuadro menos y la columna dos adelante o dos atras segun el lado de 0xE1c4
	dec a			;70f7   ; un cuadro menos
	ld (hl),a			;70f8
	ld a,(0e1c4h)		;70f9   ; el lado
	and a			;70fc
	ld b,000h		;70fd   ; B = 0 a un lado...
	jr nz,el_arma_larga_avanza_si_no		;70ff
	ld b,002h		;7101   ; ...y B = 2 al otro
el_arma_larga_avanza_si_no:		; Dentro de el_arma_larga_avanza
	ld a,(hl)			;7103
	cp 008h		;7104
	jr nc,estira_o_encoge		;7106
	inc b			;7108
estira_o_encoge:		; Segun B, la columna de 0xE1c2 se corre una a la derecha o una a la izquierda
	cp 007h		;7109   ; el 7 no se mueve
	jr z,coloca_el_arma_larga		;710b
	ld hl,0e1c2h		;710d   ; HL = 0xE1c2, la columna
	ld a,b			;7110
	and a			;7111   ; con B a cero, atras
	jr z,estira_o_encoge_si_no		;7112
	dec a			;7114
	jr z,estira_o_encoge_por_aqui		;7115
	dec a			;7117
	jr z,estira_o_encoge_por_aqui		;7118
estira_o_encoge_si_no:		; Dentro de estira_o_encoge
	dec (hl)			;711a   ; dos atras...
	dec (hl)			;711b
estira_o_encoge_por_aqui:		; Dentro de estira_o_encoge
	inc (hl)			;711c   ; ...y una adelante: en total, una atras
coloca_el_arma_larga:		; La columna de 0xE1c2 por ocho da la X, y si el lado de 0xE1c4 esta a cero se le suman catorce
	push bc			;711d
	ld a,(0e1c2h)		;711e   ; la columna
	call por_ocho		;7121   ; por ocho: la X en pixeles
	ld b,a			;7124
	ld a,(0e1c4h)		;7125   ; el lado
	and a			;7128
	jr nz,dibuja_el_arma_larga		;7129
	ld a,b			;712b
	add a,00eh		;712c   ; catorce mas si va hacia el otro lado
	ld b,a			;712e
dibuja_el_arma_larga:		; Deja la X en 0xE1b0, copia 0xE1c1 y 0xE1c2 a 0xE182 y 0xE183 -la fila y la columna del dibujador- y saca la tira de la tabla de 0x714a
	ld a,b			;712f
	ld (0e1b0h),a		;7130   ; la X, guardada
	pop bc			;7133
	ld hl,0e1c1h		;7134   ; HL = 0xE1c1, el patron y la columna
	ld de,0e182h		;7137   ; DE = 0xE182, lo que lee el dibujador
	ld a,(hl)			;713a
	ld (de),a			;713b   ; el patron
	inc hl			;713c
	inc de			;713d
	ld a,(hl)			;713e
	ld (de),a			;713f   ; y la columna
	ld hl,0714ah		;7140   ; la tabla de las cuatro tiras
	ld a,b			;7143   ; por B
	call indexa_una_tabla_de_punteros		;7144
	jp dibuja_con_alto_y_ancho		;7147

; ----------------------------------------------------------------------
; DATOS tabla_de_las_cuatro_tiras: Cuatro punteros que 0x7144 indexa por B:
;   0x7152, 0x7156, 0x715a y 0x715e
;   0x714a..0x7152  (8 bytes)
DATA_tabla_de_las_cuatro_tiras:
	defw 07152h,07156h,0715ah,0715eh	; 714a  -> DATA_tira_7152 DATA_tira_7156 DATA_tira_715a DATA_tira_715e

; ----------------------------------------------------------------------
; DATOS tira_7152: 01 02 CB CA: cuenta 2, y los dos patrones
;   0x7152..0x7156  (4 bytes)
DATA_tira_7152:
	defb 001h,002h,0cbh,0cah	; 7152

; ----------------------------------------------------------------------
; DATOS tira_7156: 01 02 00 CB: cuenta 2, con el primero vacio
;   0x7156..0x715a  (4 bytes)
DATA_tira_7156:
	defb 001h,002h,000h,0cbh	; 7156

; ----------------------------------------------------------------------
; DATOS tira_715a: 01 02 52 53: los otros dos patrones
;   0x715a..0x715e  (4 bytes)
DATA_tira_715a:
	defb 001h,002h,052h,053h	; 715a

; ----------------------------------------------------------------------
; DATOS tira_715e: 01 02 53 00: y el ultimo, tambien con un vacio
;   0x715e..0x7162  (4 bytes)
DATA_tira_715e:
	defb 001h,002h,053h,000h	; 715e

; ======================================================================
; CODIGO 0x7162..0x71b7  (85 bytes)
; ======================================================================


mueve_el_arma_larga:		; Suma o resta uno a la columna del oponente segun el lado, y luego hace crecer 0xE1c7 hasta 7 y menguar hasta 0; 0xE1c9 dice en cual de las dos fases va
	ld a,(0e185h)		;7162   ; el lado
	and a			;7165
	ld a,001h		;7166   ; a un lado, uno mas...
	jr nz,estira_hasta_siete		;7168
	ld a,0ffh		;716a   ; ...y al otro, uno menos
estira_hasta_siete:		; La columna de partida a 0xE1c8 y luego el largo arriba o abajo
	ld b,a			;716c
	ld a,(0e181h)		;716d   ; la columna del oponente
	add a,b			;7170
	ld (0e1c8h),a		;7171   ; mas el paso, a 0xE1c8
	ld de,0e1c9h		;7174   ; DE = 0xE1c9, si crece o mengua
	ld hl,0e1c7h		;7177   ; HL = 0xE1c7, el largo
	ld a,(de)			;717a
	and a			;717b
	jr nz,encoge_hasta_cero		;717c
	inc (hl)			;717e   ; creciendo, uno mas
	ld a,(hl)			;717f
	cp 007h		;7180   ; y al llegar a 7...
	ret nz			;7182
	ld a,001h		;7183
	ld (de),a			;7185   ; ...se pasa a menguar
	ret			;7186
encoge_hasta_cero:		; Un punto menos por cuadro; al llegar a cero vuelve a crecer
	dec (hl)			;7187   ; un punto menos
	ld a,(hl)			;7188
	and a			;7189
	ret nz			;718a
	ld (de),a			;718b   ; y a cero, vuelta a crecer
	ret			;718c
redibuja_el_arma_larga:		; Borra las treinta posiciones de la fila 16 y vuelve a dibujar el arma en la fila 0x11, con la columna corregida por la tabla de ajustes de 0x71b7
	ld hl,03a01h		;718d   ; HL = VRAM 0x3a01, fila 16 columna 1
	ld bc,0001eh		;7190   ; treinta tiles
	xor a			;7193
	call 00056h		;7194   ; BIOS FILVRM - Fills VRAM with value
	ld de,0e1c7h		;7197   ; DE = 0xE1c7, el largo
	ld a,(de)			;719a
	ld hl,071b7h		;719b   ; la tabla de los ocho ajustes
	call suma_a_hl		;719e
	ld a,(0e1c8h)		;71a1   ; la columna de partida...
	add a,(hl)			;71a4   ; ...corregida
	ld (0e183h),a		;71a5
	ld a,011h		;71a8   ; la fila 0x11
	ld (0e182h),a		;71aa
	ld hl,071bfh		;71ad   ; la tabla de las ocho tiras
	ld a,(de)			;71b0
	call indexa_una_tabla_de_punteros		;71b1
	jp dibuja_con_alto_y_ancho		;71b4

; ----------------------------------------------------------------------
; DATOS ocho_ajustes: FB FC FD FE 00 00 00 00, que 0x719e indexa y suma a
;   0xE1c8 para dejar 0xE183. Con signo son -5, -4, -3, -2 y luego cuatro
;   ceros: primero corrige hacia atras cada vez menos, y despues ya no corrige
;   0x71b7..0x71bf  (8 bytes)
DATA_ocho_ajustes:
	defb 0fbh,0fch,0fdh,0feh,000h,000h,000h,000h	; 71b7  ........

; ----------------------------------------------------------------------
; DATOS tabla_de_las_ocho_tiras: Ocho punteros que 0x71b1 indexa por el byte
;   de (DE): 0x71cf, 0x71d6, 0x71dc, 0x71e1, 0x71e5, 0x71e9, 0x71ee y 0x71f4
;   0x71bf..0x71cf  (16 bytes)
DATA_tabla_de_las_ocho_tiras:
	defw 071cfh,071d6h,071dch,071e1h,071e5h,071e9h,071eeh,071f4h	; 71bf

; ----------------------------------------------------------------------
; DATOS tira_71cf: Cuenta 5: CB CA CA CA CA
;   0x71cf..0x71d6  (7 bytes)
DATA_tira_71cf:
	defb 001h,005h,0cbh,0cah,0cah,0cah,0cah	; 71cf

; ----------------------------------------------------------------------
; DATOS tira_71d6: Cuenta 4: CB CA CA CA
;   0x71d6..0x71dc  (6 bytes)
DATA_tira_71d6:
	defb 001h,004h,0cbh,0cah,0cah,0cah	; 71d6

; ----------------------------------------------------------------------
; DATOS tira_71dc: Cuenta 3: CB CA CA
;   0x71dc..0x71e1  (5 bytes)
DATA_tira_71dc:
	defb 001h,003h,0cbh,0cah,0cah	; 71dc

; ----------------------------------------------------------------------
; DATOS tira_71e1: Cuenta 2: CB CA
;   0x71e1..0x71e5  (4 bytes)
DATA_tira_71e1:
	defb 001h,002h,0cbh,0cah	; 71e1

; ----------------------------------------------------------------------
; DATOS tira_71e5: Cuenta 2: 52 53, ya con los otros patrones
;   0x71e5..0x71e9  (4 bytes)
DATA_tira_71e5:
	defb 001h,002h,052h,053h	; 71e5

; ----------------------------------------------------------------------
; DATOS tira_71e9: Cuenta 3: 52 52 53
;   0x71e9..0x71ee  (5 bytes)
DATA_tira_71e9:
	defb 001h,003h,052h,052h,053h	; 71e9

; ----------------------------------------------------------------------
; DATOS tira_71ee: Cuenta 4: 52 52 52 53
;   0x71ee..0x71f4  (6 bytes)
DATA_tira_71ee:
	defb 001h,004h,052h,052h,052h,053h	; 71ee

; ----------------------------------------------------------------------
; DATOS tira_71f4: Cuenta 5: 52 52 52 52 53
;   0x71f4..0x71fb  (7 bytes)
DATA_tira_71f4:
	defb 001h,005h,052h,052h,052h,052h,053h	; 71f4

; ----------------------------------------------------------------------
; DATOS tabla_de_poses_oponente_2: Los 18 punteros que 0x5553 indexa por
;   0xE184 para el oponente 2. El primer destino es 0x721f, que es justo donde
;   acaba la tabla
;   0x71fb..0x721f  (36 bytes)
DATA_tabla_de_poses_oponente_2:
	defw 0724ah,07264h,0721fh,0722ah,072a8h,072c1h,0726bh,07280h,07287h,072a1h,072c8h,072deh,072e5h,072fbh,072e5h,072fbh	; 71fb
	defw 07231h,07243h	; 721b  -> DATA_pose_oponente_2_7231 DATA_pose_oponente_2_7243

; ----------------------------------------------------------------------
; DATOS pose_oponente_2_721f: 11 bytes, largo. Indice 2 de la tabla de 0x71fb
;   0x721f..0x722a  (11 bytes)
DATA_pose_oponente_2_721f:
	defb 0fah,0f8h,0f4h,009h,0feh,000h,004h,004h,000h,0ffh,011h	; 721f  ...........

; ----------------------------------------------------------------------
; DATOS pose_oponente_2_722a: 7 bytes, corto. Indice 3 de la tabla de 0x71fb
;   0x722a..0x7231  (7 bytes)
DATA_pose_oponente_2_722a:
	defb 0feh,000h,0f2h,0fah,0feh,024h,072h	; 722a

; ----------------------------------------------------------------------
; DATOS pose_oponente_2_7231: 18 bytes, largo. Indice 16 de la tabla de 0x71fb
;   0x7231..0x7243  (18 bytes)
DATA_pose_oponente_2_7231:
	defb 0f2h,0f0h,0f4h,0fah,0fdh,000h,004h,004h,000h,0f7h,011h,000h,019h,020h,021h,000h,0f3h,022h	; 7231  ............. !.."

; ----------------------------------------------------------------------
; DATOS pose_oponente_2_7243: 7 bytes, corto. Indice 17 de la tabla de 0x71fb
;   0x7243..0x724a  (7 bytes)
DATA_pose_oponente_2_7243:
	defb 006h,008h,006h,000h,0ffh,036h,072h	; 7243

; ----------------------------------------------------------------------
; DATOS pose_oponente_2_724a: 26 bytes, largo. Indice 0 de la tabla de 0x71fb
;   0x724a..0x7264  (26 bytes)
DATA_pose_oponente_2_724a:
	defb 0fah,0f7h,000h,000h,0feh,0ffh,074h,005h,004h,0e3h,088h,000h,011h,012h,0f3h,025h,016h,017h,028h,029h,01ah,01bh,02ah,051h,01eh,01fh	; 724a  ......t........%..()..*Q..

; ----------------------------------------------------------------------
; DATOS pose_oponente_2_7264: 7 bytes, corto. Indice 1 de la tabla de 0x71fb
;   0x7264..0x726b  (7 bytes)
DATA_pose_oponente_2_7264:
	defb 0feh,000h,000h,000h,0feh,04fh,072h	; 7264

; ----------------------------------------------------------------------
; DATOS pose_oponente_2_726b: 21 bytes, largo. Indice 6 de la tabla de 0x71fb
;   0x726b..0x7280  (21 bytes)
DATA_pose_oponente_2_726b:
	defb 0f2h,0f2h,0ech,000h,0fdh,000h,004h,004h,0f3h,038h,0e2h,0f3h,03bh,018h,019h,040h,04bh,01ch,01dh,041h,037h	; 726b  .........8..;..@K..A7

; ----------------------------------------------------------------------
; DATOS pose_oponente_2_7280: 7 bytes, corto. Indice 7 de la tabla de 0x71fb
;   0x7280..0x7287  (7 bytes)
DATA_pose_oponente_2_7280:
	defb 006h,00ah,0fah,00eh,0ffh,070h,072h	; 7280

; ----------------------------------------------------------------------
; DATOS pose_oponente_2_7287: 26 bytes, largo. Indice 8 de la tabla de 0x71fb
;   0x7287..0x72a1  (26 bytes)
DATA_pose_oponente_2_7287:
	defb 0f2h,0f2h,0edh,000h,0fdh,000h,082h,0e8h,004h,004h,000h,011h,03ah,000h,03eh,03fh,03ch,03dh,018h,019h,040h,04bh,01ch,01dh,041h,037h	; 7287  ............:.>?<=..@K..A7

; ----------------------------------------------------------------------
; DATOS pose_oponente_2_72a1: 7 bytes, corto. Indice 9 de la tabla de 0x71fb
;   0x72a1..0x72a8  (7 bytes)
DATA_pose_oponente_2_72a1:
	defb 0feh,002h,0fah,00eh,0ffh,08ch,072h	; 72a1

; ----------------------------------------------------------------------
; DATOS pose_oponente_2_72a8: 25 bytes, largo. Indice 4 de la tabla de 0x71fb
;   0x72a8..0x72c1  (25 bytes)
DATA_pose_oponente_2_72a8:
	defb 000h,0f0h,0ech,0f4h,0fdh,001h,073h,083h,0e8h,003h,005h,000h,011h,03ah,0e2h,042h,043h,03ch,03dh,000h,044h,045h,040h,046h,047h	; 72a8  ......s......:.BC<=.DE@FG

; ----------------------------------------------------------------------
; DATOS pose_oponente_2_72c1: 7 bytes, corto. Indice 5 de la tabla de 0x71fb
;   0x72c1..0x72c8  (7 bytes)
DATA_pose_oponente_2_72c1:
	defb 002h,009h,006h,00eh,0feh,0adh,072h	; 72c1

; ----------------------------------------------------------------------
; DATOS pose_oponente_2_72c8: 22 bytes, largo. Indice 10 de la tabla de 0x71fb
;   0x72c8..0x72de  (22 bytes)
DATA_pose_oponente_2_72c8:
	defb 0f2h,0f2h,0f6h,0f8h,0fch,000h,081h,0e3h,004h,005h,02bh,000h,011h,0f7h,02ch,000h,0f3h,033h,0e3h,036h,037h,000h	; 72c8  ..........+...,..3.67.

; ----------------------------------------------------------------------
; DATOS pose_oponente_2_72de: 7 bytes, corto. Indice 11 de la tabla de 0x71fb
;   0x72de..0x72e5  (7 bytes)
DATA_pose_oponente_2_72de:
	defb 006h,00ah,002h,004h,0ffh,0cdh,072h	; 72de

; ----------------------------------------------------------------------
; DATOS pose_oponente_2_72e5: 22 bytes, largo. Indice 12, 14 de la tabla de
;   0x71fb
;   0x72e5..0x72fb  (22 bytes)
DATA_pose_oponente_2_72e5:
	defb 000h,000h,000h,000h,0fdh,001h,003h,005h,000h,04ch,000h,0c4h,0e2h,04dh,04eh,0c5h,000h,050h,04fh,00ch,0c7h,0c8h	; 72e5  .........L...MN..PO...

; ----------------------------------------------------------------------
; DATOS pose_oponente_2_72fb: 37 bytes, largo. Indice 13, 15 de la tabla de
;   0x71fb (el ultimo, que llega hasta donde acaba el bloque)
;   0x72fb..0x7320  (37 bytes)
DATA_pose_oponente_2_72fb:
	defb 000h,000h,000h,000h,0fdh,0eah,072h,00eh,070h,044h,077h,040h,077h,014h,073h,018h,073h,04ch,077h,050h,077h,071h,06eh,075h,06eh,002h,000h,00ah,002h,002h,010h,004h,002h,002h,010h,006h,002h	; 72fb  ......r.pDw@w.s.sLwPwqnun............

; ======================================================================
; CODIGO 0x7320..0x7381  (97 bytes)
; ======================================================================


el_cuadro_del_cuarto_oponente:		; Mueve las armas y, con 0xE16b puesto, elige movimiento con la lista de 0x772c y lanza; si no, mide la separacion y decide si acercarse
	call mueve_las_tres_armas		;7320   ; las tres armas
	ld a,(0e16bh)		;7323   ; 0xE16b decide
	and a			;7326
	jr z,mira_donde_esta		;7327
	ld hl,0772ch		;7329   ; la lista de este oponente
	call elige_el_movimiento_del_oponente		;732c
	call lanza_el_arma		;732f   ; el arma, lanzada
	jp borra_y_recoloca_al_oponente		;7332
mira_donde_esta:		; Con la columna en 0x1d o mas deja 1 en 0xE1b8, y por debajo de 3 deja 2: son los dos bordes
	call mide_la_separacion		;7335   ; la separacion
	ld a,(0e181h)		;7338   ; la columna del oponente
	cp 01dh		;733b   ; pegado al borde de la derecha...
	jr c,mira_donde_esta_si_no		;733d
	ld a,001h		;733f   ; ...deja 1
	jr mira_donde_esta_si_no_2		;7341
mira_donde_esta_si_no:		; Dentro de mira_donde_esta
	cp 003h		;7343   ; y pegado al de la izquierda...
	jr nc,mira_si_hay_que_volver		;7345
	ld a,002h		;7347   ; ...deja 2
mira_donde_esta_si_no_2:		; Dentro de mira_donde_esta
	ld (0e1b8h),a		;7349   ; apuntado en 0xE1b8
mira_si_hay_que_volver:		; Con 0xE1b8 puesto, C dice hacia donde
	ld a,(0e1b8h)		;734c
	and a			;734f   ; a cero, no hay nada
	jr z,despacha_por_oponente		;7350
	dec a			;7352
	ld c,000h		;7353   ; C = 0 de partida
	jr nz,anda_uno_de_cada_cuatro		;7355
	inc c			;7357   ; y C = 1 con el valor 1
anda_uno_de_cada_cuatro:		; El bit 1 del contador de cuadros lo deja pasar uno de cada cuatro, y el bit 3 elige la pose
	ld hl,0e003h		;7358   ; HL = 0xE003, el contador de cuadros
	bit 1,(hl)		;735b   ; su bit 1
	ret nz			;735d
	bit 3,(hl)		;735e   ; y el bit 3 elige la pose
	call con_la_pose_dieciseis		;7360
	ld a,(0e181h)		;7363
	cp 011h		;7366
	ret nz			;7368
	xor a			;7369
	ld (0e1b8h),a		;736a
	ret			;736d
despacha_por_oponente:		; Mide la separacion y luego reparte por la tabla de tablas de 0x7381: primero por el oponente de 0xE054 y despues por B
	call mide_la_separacion		;736e   ; la separacion, medida
	push bc			;7371
	ld a,(0e054h)		;7372   ; el oponente de turno
	ld hl,07381h		;7375   ; la tabla de tablas
	call indexa_una_tabla_de_punteros		;7378
	ex de,hl			;737b
	pop bc			;737c
	ld a,b			;737d
	jp despacha_con_la_tabla_en_hl		;737e   ; y a despachar por B

; ----------------------------------------------------------------------
; DATOS tabla_de_tablas_por_escenario: Los cinco punteros que 0x7375 indexa
;   por 0xE054: una tabla de despacho por escenario. Los 5 punteros: 0x6ca0
;   0x6e8f 0x702c 0x738b 0x7770
;   0x7381..0x738b  (10 bytes)
DATA_tabla_de_tablas_por_escenario:
	defw 06ca0h,06e8fh,0702ch,0738bh,07770h	; 7381

; ----------------------------------------------------------------------
; DATOS despacho_escenario_3: Siete punteros a rutina, pegada detras de la
;   tabla de tablas. Los 7 punteros: 0x73a2 0x73b1 0x73fb 0x73f8 0x74a2 0x74c7
;   0x74c7
;   0x738b..0x7399  (14 bytes)
DATA_despacho_escenario_3:
	defw 073a2h,073b1h,073fbh,073f8h,074a2h,074c7h,074c7h	; 738b

; ======================================================================
; CODIGO 0x7399..0x73b3  (26 bytes)
; ======================================================================


de_que_lado_esta_el_jugador:		; C = 1 si 0xE185 esta a cero y C = 0 si no
	ld a,(0e185h)		;7399   ; el lado que apunto 0x54b3
	ld c,000h		;739c   ; C = 0 de partida
	and a			;739e
	ret nz			;739f
	inc c			;73a0   ; y C = 1 al otro lado
	ret			;73a1
el_paso_de_todos:		; La primera entrada de las cinco tablas. Mira el lado y, con la Y del jugador en 0x7f o mas -o sea con el jugador por debajo-, deja cinco cuadros de espera en 0xE129
	call de_que_lado_esta_el_jugador		;73a2   ; el lado
	ld a,(0e160h)		;73a5   ; la Y del jugador
	cp 07fh		;73a8   ; por encima de 0x7f no hace nada
	ret c			;73aa
	ld a,005h		;73ab   ; cinco cuadros de espera
	ld (0e129h),a		;73ad
	ret			;73b0
salta_al_paso:		; Un `jr` de 0x48 que se planta en 0x73fb, saltando por encima de los veintiseis bytes muertos de 0x73b3
	jr $+74		;73b1   ; y de un salto a 0x73fb

; ----------------------------------------------------------------------
; DATOS resto_73b3: Veintiseis bytes que decodifican como `call 0x7399 / ld
;   hl,0e003h / ld a,(0e165h) / and a / jr z / cp 4 / jr z / cp 1 / jp
;   nz,0x7450 / bit 1,(hl) / jp nz,0x7450`. Nadie llega: 0x73b1 es un `jr` de
;   0x48 que salta por encima de todo esto y aterriza en 0x73fb
;   0x73b3..0x73cd  (26 bytes)
DATA_resto_73b3:
	defb 0cdh,099h,073h,021h,003h,0e0h,03ah,065h,0e1h,0a7h,028h,04eh,0feh,004h,028h,00ah	; 73b3  ..s!..:e..(N..(.
	defb 0feh,001h,0c2h,050h,074h,0cbh,04eh,0c2h,050h,074h	; 73c3  ...Pt.N.Pt

; ======================================================================
; CODIGO 0x73cd..0x73df  (18 bytes)
; ======================================================================


pide_nueve_cuadros_de_espera:		; Deja 9 en 0xE132 y el lado en 0xE133, que es la segunda cuenta atras de 0x6b22
	ld a,009h		;73cd
	ld (0e132h),a		;73cf
	ld a,(0e185h)		;73d2
	ld (0e133h),a		;73d5
	jr $+10		;73d8
salta_al_paso_otra_vuelta_2:		; Dentro de salta_al_paso
	call con_la_pose_dos		;73da
	jr $+5		;73dd

; ----------------------------------------------------------------------
; DATOS resto_73df: Tres bytes, `call 0x74da`. El `jr` de 0x73dd se los salta
;   y ninguna palabra del cartucho vale 0x73df: la entrada alternativa que
;   estos tres bytes serian no la usa nadie
;   0x73df..0x73e2  (3 bytes)
DATA_resto_73df:
	defb 0cdh,0dah,074h	; 73df

; ======================================================================
; CODIGO 0x73e2..0x7401  (31 bytes)
; ======================================================================


salta_al_paso_si_no:		; Dentro de salta_al_paso
	ld a,001h		;73e2
	ld (0e169h),a		;73e4
	ret			;73e7
que_golpe_cuenta:		; Con 0xE165 a cero no hay golpe. Y con 0xE150 por debajo de 5 tampoco: el golpe solo cuenta en los cinco primeros cuadros del movimiento
	ld a,(0e165h)		;73e8   ; el golpe de ahora
	and a			;73eb
	ret z			;73ec   ; a cero, ninguno
	ld a,(0e150h)		;73ed   ; los cuadros que quedan
	cp 005h		;73f0   ; hacen falta cinco
	ld a,(0e165h)		;73f2
	ret nc			;73f5
	xor a			;73f6   ; y si no, ninguno
	ret			;73f7
que_golpe_cuenta_si_no:		; Dentro de que_golpe_cuenta
	call el_cuadro_del_primer_oponente_otra_vuelta		;73f8
que_golpe_cuenta_si_no_2:		; Dentro de que_golpe_cuenta
	call que_golpe_cuenta		;73fb
	call despacha_por_la_tabla_de_al_lado		;73fe

; ----------------------------------------------------------------------
; DATOS tabla_de_submodos_escenario_3: La que despacha 0x73fe. Los 6 punteros:
;   0x740d 0x743e 0x746f 0x7482 0x7491 0x7482
;   0x7401..0x740d  (12 bytes)
DATA_tabla_de_submodos_escenario_3:
	defw 0740dh,0743eh,0746fh,07482h,07491h,07482h	; 7401

; ======================================================================
; CODIGO 0x740d..0x743a  (45 bytes)
; ======================================================================


espera_y_gira:		; Baja 0xE169 y, al agotarse, lo repone a 0x18 y sube 0xE168 dentro del tramo de 4 a 6. Es el hermano de 0x6ccd, con otra cuenta y otro tramo
	ld hl,0e169h		;740d   ; HL = 0xE169, la cuenta
	dec (hl)			;7410   ; un cuadro menos
	ld a,(hl)			;7411
	and a			;7412
	ret nz			;7413
	ld a,018h		;7414   ; y vuelta a empezar, 0x18 cuadros
	ld (0e169h),a		;7416
	ld hl,0e168h		;7419   ; HL = 0xE168
	ld a,(hl)			;741c
	inc a			;741d
	cp 004h		;741e   ; por debajo de 4...
	jr c,espera_y_gira_si_no		;7420
	cp 007h		;7422   ; ...o de 7...
	jr c,espera_y_gira_si_no_2		;7424
espera_y_gira_si_no:		; Dentro de espera_y_gira
	ld a,004h		;7426   ; ...se queda en 4
espera_y_gira_si_no_2:		; Dentro de espera_y_gira
	ld (hl),a			;7428
fija_el_movimiento_y_su_plazo:		; Deja A en 0xE16a y saca de la tabla de 0x743a el plazo que le toca a la dificultad de 0xE056
	ld (0e16ah),a		;7429   ; el movimiento
	ld hl,0743ah		;742c   ; la tabla de los cuatro plazos
	ld a,(0e056h)		;742f   ; por la dificultad
	call suma_a_hl		;7432
	ld a,(hl)			;7435
	ld (0e16bh),a		;7436   ; y el plazo, a 0xE16b
	ret			;7439

; ----------------------------------------------------------------------
; DATOS cuatro_umbrales_por_oponente: Cuatro bytes, 0x18, 0x10, 0x0d y 0x09,
;   que 0x742c indexa por 0xE056 y guarda en 0xE16b. Bajan segun sube el
;   oponente
;   0x743a..0x743e  (4 bytes)
DATA_cuatro_umbrales_por_oponente:
	defb 018h,010h,00dh,009h	; 743a

; ======================================================================
; CODIGO 0x743e..0x746b  (45 bytes)
; ======================================================================


caracter_743e:		; Pide un numero de 0 a 3 y reparte: el 1 a 0x7450, el 2 a 0x7454 y el 3 a 0x7458; el 0 cae en 0x744a
	call saca_un_numero_al_azar		;743e   ; el azar, de 0 a 3
	dec a			;7441
	jr z,pide_el_movimiento_seis		;7442   ; el 1, a 0x7450
	dec a			;7444
	jr z,pide_el_movimiento_cuatro		;7445   ; el 2, a 0x7454
	dec a			;7447
	jr z,pide_el_movimiento_cinco		;7448   ; y el 3, a 0x7458
pide_cuatro_cuadros_de_espera:		; Deja 4 en 0xE129, que es la primera cuenta atras de 0x6b05
	ld a,004h		;744a
	ld (0e129h),a		;744c
	ret			;744f
pide_el_movimiento_seis:		; A = 6 y al plazo de 0x745a
	ld a,006h		;7450
	jr el_movimiento_con_el_otro_plazo		;7452
pide_el_movimiento_cuatro:		; A = 4 y al plazo de 0x745a
	ld a,004h		;7454
	jr el_movimiento_con_el_otro_plazo		;7456
pide_el_movimiento_cinco:		; A = 5, y cae en el plazo de 0x745a
	ld a,005h		;7458
el_movimiento_con_el_otro_plazo:		; Como 0x7429 pero con la tabla de 0x746b, que trae los mismos cuatro valores que la de 0x7592
	call fija_el_movimiento_y_su_plazo		;745a   ; el movimiento y su plazo
	ld a,(0e056h)		;745d   ; la dificultad
	ld hl,0746bh		;7460   ; la otra tabla de cuatro
	call suma_a_hl		;7463
	ld a,(hl)			;7466
	ld (0e16bh),a		;7467   ; y su plazo, a 0xE16b
	ret			;746a

; ----------------------------------------------------------------------
; DATOS cuatro_umbrales_mas: 0x0b, 0x09, 0x08 y 0x03, que 0x7463 indexa y
;   tambien guarda en 0xE16b. Son los MISMOS cuatro valores que los de 0x7592,
;   byte a byte, pero cada tabla se usa por su lado: esta los escribe y
;   aquella los compara
;   0x746b..0x746f  (4 bytes)
DATA_cuatro_umbrales_mas:
	defb 00bh,009h,008h,003h	; 746b

; ======================================================================
; CODIGO 0x746f..0x74ae  (63 bytes)
; ======================================================================


caracter_746f:		; Pide un numero de 0 a 3 y reparte: el 1 a 0x747e, el 2 a z, el 3 a z, y el 0 a 0x740d
	call saca_un_numero_al_azar		;746f   ; el azar, de 0 a 3
	dec a			;7472
	jr z,pide_el_movimiento_seis_otra_vez		;7473   ; el 1, a 0x747e
	dec a			;7475
	jr z,$-34		;7476   ; el 2, a z
	dec a			;7478
	jr z,$-33		;7479   ; el 3, a z
	jp espera_y_gira		;747b   ; y el 0, a 0x740d
pide_el_movimiento_seis_otra_vez:		; A = 6 y de un `jr` corto al plazo
	ld a,006h		;747e
	jr $-38		;7480
caracter_7482:		; El 1 a 0x747e, el 2 a 0x740d, el 3 a 0x744a y el 0 a 0x7458
	call saca_un_numero_al_azar		;7482   ; el azar, de 0 a 3
	dec a			;7485
	jr z,pide_el_movimiento_seis_otra_vez		;7486   ; el 1, a 0x747e
	dec a			;7488
	jp z,espera_y_gira		;7489   ; el 2, a 0x740d
	dec a			;748c
	jr z,$-53		;748d   ; y el 3, a 0x744a
	jr $-69		;748f
caracter_7491:		; Pide un numero de 0 a 3 y reparte: el 1 a 0x747e, el 2 a 0x73cd, el 3 a 0x744a, y el 0 a 0x744a
	call saca_un_numero_al_azar		;7491   ; el azar, de 0 a 3
	dec a			;7494
	jr z,pide_el_movimiento_seis_otra_vez		;7495   ; el 1, a 0x747e
	dec a			;7497
	jp z,pide_nueve_cuadros_de_espera		;7498   ; el 2, a 0x73cd
	dec a			;749b
	jp z,pide_cuatro_cuadros_de_espera		;749c   ; el 3, a 0x744a
	jp pide_cuatro_cuadros_de_espera		;749f   ; y el 0, a 0x744a
el_otro_paso_de_todos:		; La quinta entrada de las cinco tablas: mira el lado y se va a 0x73da
	ld a,(0e185h)		;74a2   ; el lado
	ld c,000h		;74a5   ; C = 0 de partida
	and a			;74a7
	jr z,el_otro_paso_de_todos_si_no		;74a8
	inc c			;74aa   ; y C = 1 al otro lado
el_otro_paso_de_todos_si_no:		; Dentro de el_otro_paso_de_todos
	jp salta_al_paso_otra_vuelta_2		;74ab

; ----------------------------------------------------------------------
; DATOS resto_74ae: Ocho bytes, `ld a,030h / ld (0e169h),a / ld hl,0e16ch`.
;   Van detras del `jp 0x73da` de 0x74ab, que no vuelve, y nadie apunta aqui
;   0x74ae..0x74b6  (8 bytes)
DATA_resto_74ae:
	defb 03eh,030h,032h,069h,0e1h,021h,06ch,0e1h	; 74ae  >02i.!l.

; ======================================================================
; CODIGO 0x74b6..0x7586  (208 bytes)
; ======================================================================


gira_cada_sesenta_y_cuatro_cuadros:		; Uno de cada 0x40 cuadros sube el byte que traiga HL, con vuelta a cero al llegar a 3
	ld a,(0e003h)		;74b6   ; el contador de cuadros
	and 03fh		;74b9   ; uno de cada 0x40
	ret nz			;74bb
	ld a,(hl)			;74bc
	inc a			;74bd   ; uno mas
	cp 003h		;74be   ; y con 3 vuelve a cero
	jr c,gira_cada_sesenta_y_cuatro_cuadros_si_no		;74c0
	xor a			;74c2
gira_cada_sesenta_y_cuatro_cuadros_si_no:		; Dentro de gira_cada_sesenta_y_cuatro_cuadros
	ld (hl),a			;74c3
	jp fija_el_movimiento_y_su_plazo		;74c4
gira_a_media_velocidad:		; Lo mismo sobre 0xE16c, pero solo con el bit 6 del contador puesto, o sea la mitad del tiempo
	ld hl,0e16ch		;74c7   ; HL = 0xE16c
	ld a,(0e003h)		;74ca
	bit 6,a		;74cd   ; el bit 6 del contador de cuadros
	jr nz,gira_cada_sesenta_y_cuatro_cuadros		;74cf
anda_hacia_el_jugador:		; Una columna cada dieciseis cuadros: los tres bits bajos del contador tienen que ser cero y el bit 4 elige la pose, la 0x10 o la 2
	ld a,(0e185h)		;74d1   ; el lado
	ld c,000h		;74d4
	and a			;74d6
	jr z,anda_hacia_el_jugador_si_no		;74d7
	inc c			;74d9
anda_hacia_el_jugador_si_no:		; Dentro de anda_hacia_el_jugador
	ld hl,0e003h		;74da   ; HL = 0xE003, el contador de cuadros
	ld a,(hl)			;74dd
	and 00eh		;74de   ; uno de cada dieciseis
	ret nz			;74e0
	bit 4,(hl)		;74e1   ; y su bit 4 elige la pose
con_la_pose_dieciseis:		; B = 0x10
	ld b,010h		;74e3   ; B = 0x10, la otra pose
	jr nz,monta_la_pose_y_anda		;74e5
con_la_pose_dos:		; B = 2, y si el jugador esta al otro lado se usa la de al lado
	ld b,002h		;74e7   ; B = 2, la pose de andar
monta_la_pose_y_anda:		; La pose a 0xE184, sumando uno si el jugador esta al otro lado, y la columna de 0xE181 arriba o abajo segun C
	ld a,(0e185h)		;74e9   ; el lado
	and a			;74ec
	ld a,b			;74ed
	jr nz,monta_la_pose_y_anda_si_no		;74ee
	inc a			;74f0   ; al otro lado, la pose de al lado
monta_la_pose_y_anda_si_no:		; Dentro de monta_la_pose_y_anda
	ld hl,0e181h		;74f1   ; HL = 0xE181, la columna
	ld (0e184h),a		;74f4   ; la pose, puesta
	bit 0,c		;74f7   ; el bit 0 de C decide hacia donde
	jr nz,monta_la_pose_y_anda_si_no_2		;74f9
	call una_columna_a_la_derecha		;74fb
	jr monta_la_pose_y_anda_si_no_3		;74fe
monta_la_pose_y_anda_si_no_2:		; Dentro de monta_la_pose_y_anda
	call una_columna_a_la_izquierda		;7500
monta_la_pose_y_anda_si_no_3:		; Dentro de monta_la_pose_y_anda
	jp borra_y_recoloca_al_oponente		;7503   ; y a redibujarlo en el sitio nuevo
una_columna_a_la_derecha:		; Con tope en 0x1d
	ld a,(hl)			;7506
	cp 01dh		;7507   ; el tope de la derecha
	jr nc,una_columna_a_la_derecha_si_no		;7509
	inc a			;750b   ; una columna mas
una_columna_a_la_derecha_si_no:		; Dentro de una_columna_a_la_derecha
	ld (hl),a			;750c
	ret			;750d
una_columna_a_la_izquierda:		; Con tope en cero
	ld a,(hl)			;750e
	and a			;750f   ; en el borde ya no se puede seguir
	jr z,una_columna_a_la_izquierda_si_no		;7510
	dec a			;7512   ; una columna menos
una_columna_a_la_izquierda_si_no:		; Dentro de una_columna_a_la_izquierda
	ld (hl),a			;7513
	ret			;7514
lanza_el_arma:		; Solo cuando 0xE16b coincide con el umbral que 0x7592 da para 0xE056, y con 0xE16a por debajo de 3. Entonces monta el sprite que 0xE16c diga
	ld a,(0e056h)		;7515   ; la dificultad de 0xE056
	ld hl,07592h		;7518   ; elige el umbral
	call suma_a_hl		;751b
	ld a,(0e16bh)		;751e   ; contra 0xE16b
	cp (hl)			;7521
	ret nz			;7522   ; sin coincidir, nada
	ld a,(0e16ah)		;7523   ; y 0xE16a tiene que estar por debajo de 3
	cp 003h		;7526
	ret nc			;7528
	ld a,(0e16ch)		;7529   ; 0xE16c dice cual de los tres
	push af			;752c
	ld hl,07586h		;752d   ; la tabla de los cuatro sprites
	call indexa_una_tabla_de_punteros		;7530
	ex de,hl			;7533
	pop af			;7534
	ld de,0758eh		;7535   ; y la de las cuatro alturas
	call suma_a_de		;7538
	ld a,(de)			;753b
	ld (hl),a			;753c   ; la Y, escrita
	push hl			;753d
	ld a,(0e16ch)		;753e
	ld hl,0e194h		;7541
	ld de,0e190h		;7544
	and a			;7547
	jr z,apunta_el_arma_en_marcha		;7548
	inc hl			;754a
	inc de			;754b
	dec a			;754c
	jr z,apunta_el_arma_en_marcha		;754d
	inc hl			;754f
	inc de			;7550
apunta_el_arma_en_marcha:		; El lado va a 0xE194 y un uno a 0xE190, cada uno en su hueco de la terna
	ld a,(0e185h)		;7551   ; el lado
	ld (hl),a			;7554   ; apuntado
	ld a,001h		;7555
	ld (de),a			;7557   ; y el arma, en marcha
	ld a,(0e16eh)		;7558   ; la X del oponente
	ld b,a			;755b
	ld a,(hl)			;755c
	and a			;755d
	ld a,012h		;755e   ; 0x12 a la derecha...
	jr z,apunta_el_arma_en_marcha_si_no		;7560
	ld a,0eeh		;7562   ; ...o 0x12 a la izquierda, que es el 0xEE
apunta_el_arma_en_marcha_si_no:		; Dentro de apunta_el_arma_en_marcha
	add a,b			;7564   ; sumada a la del oponente
	pop hl			;7565
	inc hl			;7566
	ld (hl),a			;7567   ; y esa es la X del sprite
el_patron_y_el_color:		; El oponente 3 usa el patron 0xe8 con color blanco; los demas el 0xc4 o el 0xe4 segun el lado, con color 6
	ld a,(0e054h)		;7568   ; el oponente de turno
	cp 003h		;756b   ; solo el 3 va por aqui
	jr nz,el_patron_y_el_color_si_no		;756d
	ld a,0e8h		;756f   ; patron 0xe8...
	ld b,00fh		;7571   ; ...y color 0x0f, blanco
	jr escribe_el_patron_y_el_color		;7573
el_patron_y_el_color_si_no:		; Dentro de el_patron_y_el_color
	ld a,(0e185h)		;7575   ; el lado
	and a			;7578
	ld a,0c4h		;7579   ; patron 0xc4 a la derecha...
	jr z,el_patron_y_el_color_si_no_2		;757b
	ld a,0e4h		;757d   ; ...y 0xe4 a la izquierda
el_patron_y_el_color_si_no_2:		; Dentro de el_patron_y_el_color
	ld b,006h		;757f   ; color 6
escribe_el_patron_y_el_color:		; Los dos ultimos bytes del sprite
	inc hl			;7581
	ld (hl),a			;7582   ; el patron
	inc hl			;7583
	ld (hl),b			;7584   ; y el color
	ret			;7585

; ----------------------------------------------------------------------
; DATOS tabla_de_las_cuatro_yes: Cuatro punteros a la RAM: 0xE0b0, 0xE0b4,
;   0xE0b8 y 0xE0bc, o sea el campo Y de los sprites 0 a 3 de la tabla de
;   atributos. Los indexa 0x7530
;   0x7586..0x758e  (8 bytes)
DATA_tabla_de_las_cuatro_yes:
	defw 0e0b0h,0e0b4h,0e0b8h,0e0bch	; 7586

; ----------------------------------------------------------------------
; DATOS cuatro_patrones: 0x84, 0x92, 0xa0 y 0xe0, que 0x7538 indexa y escribe
;   donde apunte HL
;   0x758e..0x7592  (4 bytes)
DATA_cuatro_patrones:
	defb 084h,092h,0a0h,0e0h	; 758e

; ----------------------------------------------------------------------
; DATOS cuatro_umbrales_a_comparar: 0x0b, 0x09, 0x08 y 0x03. Los indexan
;   0x751b y 0x70a6, y los dos comparan el valor con 0xE16b y vuelven si no
;   coincide
;   0x7592..0x7596  (4 bytes)
DATA_cuatro_umbrales_a_comparar:
	defb 00bh,009h,008h,003h	; 7592

; ======================================================================
; CODIGO 0x7596..0x7621  (139 bytes)
; ======================================================================


mueve_las_tres_armas:		; Baja 0xE127 si no esta a cero y luego pasa por los tres proyectiles, cada uno con su sprite, su lado y su estado
	ld a,(0e127h)		;7596   ; 0xE127
	and a			;7599
	jr z,mueve_las_tres_armas_si_no		;759a
	dec a			;759c   ; un cuadro menos
	ld (0e127h),a		;759d
mueve_las_tres_armas_si_no:		; Dentro de mueve_las_tres_armas
	ld hl,0e0b1h		;75a0   ; el primero: sprite 0xE0b1
	ld a,(0e194h)		;75a3
	ld de,0e190h		;75a6
	call mueve_un_arma		;75a9
	ld hl,0e0b5h		;75ac   ; el segundo: sprite 0xE0b5
	ld a,(0e195h)		;75af
	ld de,0e191h		;75b2
	call mueve_un_arma		;75b5
	ld hl,0e0b9h		;75b8   ; y el tercero: sprite 0xE0b9
	ld a,(0e196h)		;75bb
	ld de,0e192h		;75be
mueve_un_arma:		; Con el estado a cero no hay arma. El 4 y el 3 la dejan quieta con el patron 0xdc o 0xf4 en blanco; los demas la mueven
	ld b,a			;75c1   ; B = el lado
	ld a,(de)			;75c2   ; el estado
	and a			;75c3
	ret z			;75c4   ; a cero, no hay arma
	cp 004h		;75c5   ; el estado 4...
	jr nz,mueve_un_arma_si_no		;75c7
	ld b,00ah		;75c9   ; ...cuenta hasta 0x0a con el patron 0xdc
	ld a,0dch		;75cb
	jr la_deja_quieta		;75cd
mueve_un_arma_si_no:		; Dentro de mueve_un_arma
	cp 003h		;75cf   ; el estado 3...
	jr nz,mira_si_se_borra		;75d1
	ld b,003h		;75d3   ; ...hasta 3 con el patron 0xf4
	ld a,0f4h		;75d5
la_deja_quieta:		; Escribe el patron y el color blanco, y baja el estado cuando 0xE127 llega a la cuenta
	inc hl			;75d7
	ld (hl),a			;75d8   ; el patron
	inc hl			;75d9
	ld a,00fh		;75da   ; color 0x0f, blanco
	ld (hl),a			;75dc
	ld a,(0e127h)		;75dd   ; 0xE127 contra la cuenta
	cp b			;75e0
	ret nc			;75e1
	ex de,hl			;75e2
	dec (hl)			;75e3   ; y un estado menos
	ex de,hl			;75e4
	ret			;75e5
mira_si_se_borra:		; El estado 2 la borra: patron a cero, estado a cero y la Y a 0xE0, fuera de pantalla
	cp 002h		;75e6   ; el estado 2...
	jr nz,la_hace_volar		;75e8
	xor a			;75ea
	ld (hl),a			;75eb   ; ...borra el patron...
	ld (de),a			;75ec   ; ...y el estado...
	dec hl			;75ed
	ld a,0e0h		;75ee   ; ...y saca el sprite de la pantalla
	ld (hl),a			;75f0
	ret			;75f1
la_hace_volar:		; Salvo en el oponente 1, el patron alterna entre 0xe8 y 0xec con el bit 1 del contador de cuadros, que es lo que la hace girar
	ld a,(0e054h)		;75f2   ; el oponente de turno
	dec a			;75f5   ; el 1 no cambia de patron
	jr z,tres_pixeles_por_cuadro		;75f6
	inc hl			;75f8
	ld a,(0e003h)		;75f9   ; el contador de cuadros
	bit 1,a		;75fc   ; su bit 1 alterna...
	ld a,0e8h		;75fe   ; ...entre el patron 0xe8...
	jr z,la_hace_volar_si_no		;7600
	ld a,0ech		;7602   ; ...y el 0xec
la_hace_volar_si_no:		; Dentro de la_hace_volar
	ld (hl),a			;7604
	dec hl			;7605
tres_pixeles_por_cuadro:		; Hacia la derecha con el lado a cero y hacia la izquierda si no, tres pixeles cada vez, hasta 0xf8 por un borde y 5 por el otro
	ld a,b			;7606
	and a			;7607   ; el lado manda
	jr nz,tres_pixeles_por_cuadro_si_no		;7608
	inc (hl)			;760a   ; tres pixeles a la derecha
	inc (hl)			;760b
	inc (hl)			;760c
	ld a,(hl)			;760d
	cp 0f8h		;760e   ; y el borde, en 0xf8
	ret c			;7610
	jr el_arma_se_sale		;7611
tres_pixeles_por_cuadro_si_no:		; Dentro de tres_pixeles_por_cuadro
	dec (hl)			;7613   ; tres pixeles a la izquierda
	dec (hl)			;7614
	dec (hl)			;7615
	ld a,(hl)			;7616
	cp 005h		;7617   ; con el borde en 5
	ret nc			;7619
el_arma_se_sale:		; Y a 0xE0, fuera de pantalla, y el estado a cero
	ld a,0e0h		;761a   ; fuera de pantalla
	dec hl			;761c
	ld (hl),a			;761d
	xor a			;761e
	ld (de),a			;761f   ; y el estado, borrado
	ret			;7620

; ----------------------------------------------------------------------
; DATOS tabla_de_poses_oponente_3: Los 18 punteros que 0x5553 indexa por
;   0xE184 para el oponente 3. El primer destino es 0x7645, que es justo donde
;   acaba la tabla
;   0x7621..0x7645  (36 bytes)
DATA_tabla_de_poses_oponente_3:
	defw 07645h,07659h,07660h,07676h,0767dh,07691h,07698h,076b3h,07698h,076b3h,076bah,076d4h,076dbh,076f1h,076f8h,07707h	; 7621
	defw 0770eh,07725h	; 7641  -> DATA_pose_oponente_3_770e DATA_pose_oponente_3_7725

; ----------------------------------------------------------------------
; DATOS pose_oponente_3_7645: 20 bytes, largo. Indice 0 de la tabla de 0x7621
;   0x7645..0x7659  (20 bytes)
DATA_pose_oponente_3_7645:
	defb 0f6h,0f6h,0f1h,004h,0feh,000h,004h,004h,010h,011h,088h,000h,0f3h,012h,000h,0f3h,015h,000h,0f4h,018h	; 7645  ....................

; ----------------------------------------------------------------------
; DATOS pose_oponente_3_7659: 7 bytes, corto. Indice 1 de la tabla de 0x7621
;   0x7659..0x7660  (7 bytes)
DATA_pose_oponente_3_7659:
	defb 002h,00ah,0f6h,00ah,0feh,04ah,076h	; 7659

; ----------------------------------------------------------------------
; DATOS pose_oponente_3_7660: 22 bytes, largo. Indice 2 de la tabla de 0x7621
;   0x7660..0x7676  (22 bytes)
DATA_pose_oponente_3_7660:
	defb 0f6h,0f6h,0f1h,004h,0fdh,000h,004h,005h,01ch,01dh,011h,088h,0e2h,01eh,043h,014h,0e2h,0f3h,015h,0e2h,0f4h,018h	; 7660  ..............C.......

; ----------------------------------------------------------------------
; DATOS pose_oponente_3_7676: 7 bytes, corto. Indice 3 de la tabla de 0x7621
;   0x7676..0x767d  (7 bytes)
DATA_pose_oponente_3_7676:
	defb 002h,00ah,0f6h,00ah,0feh,065h,076h	; 7676

; ----------------------------------------------------------------------
; DATOS pose_oponente_3_767d: 20 bytes, largo. Indice 4 de la tabla de 0x7621
;   0x767d..0x7691  (20 bytes)
DATA_pose_oponente_3_767d:
	defb 0e6h,0eah,0f0h,0f0h,0fch,0ffh,005h,004h,0e2h,022h,000h,010h,01fh,020h,021h,0f8h,023h,0e2h,02bh,000h	; 767d  ........."... !.#.+.

; ----------------------------------------------------------------------
; DATOS pose_oponente_3_7691: 7 bytes, corto. Indice 5 de la tabla de 0x7621
;   0x7691..0x7698  (7 bytes)
DATA_pose_oponente_3_7691:
	defb 012h,00eh,00ah,00ah,000h,082h,076h	; 7691

; ----------------------------------------------------------------------
; DATOS pose_oponente_3_7698: 27 bytes, largo. Indice 6, 8 de la tabla de
;   0x7621
;   0x7698..0x76b3  (27 bytes)
DATA_pose_oponente_3_7698:
	defb 0e6h,0eah,0f0h,0f0h,0fch,0ffh,082h,0e0h,005h,004h,0e2h,022h,000h,010h,01fh,020h,021h,02eh,02fh,025h,026h,0e2h,029h,02ah,0e2h,02bh,000h	; 7698  ..........."... !./%&.)*.+.

; ----------------------------------------------------------------------
; DATOS pose_oponente_3_76b3: 7 bytes, corto. Indice 7, 9 de la tabla de
;   0x7621
;   0x76b3..0x76ba  (7 bytes)
DATA_pose_oponente_3_76b3:
	defb 012h,00eh,00ah,00ah,000h,09dh,076h	; 76b3

; ----------------------------------------------------------------------
; DATOS pose_oponente_3_76ba: 26 bytes, largo. Indice 10 de la tabla de 0x7621
;   0x76ba..0x76d4  (26 bytes)
DATA_pose_oponente_3_76ba:
	defb 0eeh,0e8h,0eah,0eah,0fch,0ffh,081h,0e0h,005h,004h,000h,09ah,0e2h,099h,098h,01fh,0a4h,09eh,09dh,031h,030h,0a2h,0a1h,0e3h,0a3h,0e2h	; 76ba  ...................10.....

; ----------------------------------------------------------------------
; DATOS pose_oponente_3_76d4: 7 bytes, corto. Indice 11 de la tabla de 0x7621
;   0x76d4..0x76db  (7 bytes)
DATA_pose_oponente_3_76d4:
	defb 00ah,00fh,010h,010h,000h,0bfh,076h	; 76d4

; ----------------------------------------------------------------------
; DATOS pose_oponente_3_76db: 22 bytes, largo. Indice 12 de la tabla de 0x7621
;   0x76db..0x76f1  (22 bytes)
DATA_pose_oponente_3_76db:
	defb 0f0h,0e5h,0e0h,0e6h,0fbh,001h,071h,083h,0deh,003h,005h,000h,010h,01fh,032h,0e2h,012h,013h,033h,000h,0f5h,034h	; 76db  ......q.......2...3..4

; ----------------------------------------------------------------------
; DATOS pose_oponente_3_76f1: 7 bytes, corto. Indice 13 de la tabla de 0x7621
;   0x76f1..0x76f8  (7 bytes)
DATA_pose_oponente_3_76f1:
	defb 002h,013h,01ah,014h,000h,0e0h,076h	; 76f1

; ----------------------------------------------------------------------
; DATOS pose_oponente_3_76f8: 15 bytes, largo. Indice 14 de la tabla de 0x7621
;   0x76f8..0x7707  (15 bytes)
DATA_pose_oponente_3_76f8:
	defb 000h,000h,000h,000h,0fdh,002h,002h,005h,0e2h,039h,01fh,088h,034h,0f4h,03ah	; 76f8  .........9..4.:

; ----------------------------------------------------------------------
; DATOS pose_oponente_3_7707: 7 bytes, corto. Indice 15 de la tabla de 0x7621
;   0x7707..0x770e  (7 bytes)
DATA_pose_oponente_3_7707:
	defb 000h,000h,000h,000h,0feh,0fdh,076h	; 7707

; ----------------------------------------------------------------------
; DATOS pose_oponente_3_770e: 23 bytes, largo. Indice 16 de la tabla de 0x7621
;   0x770e..0x7725  (23 bytes)
DATA_pose_oponente_3_770e:
	defb 0eeh,0eeh,0f0h,0f6h,0fch,000h,004h,004h,01ch,01dh,011h,088h,000h,01eh,043h,014h,000h,03eh,016h,03fh,000h,0f3h,040h	; 770e  ..............C..>.?..@

; ----------------------------------------------------------------------
; DATOS pose_oponente_3_7725: 51 bytes, largo. Indice 17 de la tabla de 0x7621
;   (el ultimo, que llega hasta donde acaba el bloque)
;   0x7725..0x7758  (51 bytes)
DATA_pose_oponente_3_7725:
	defb 00ah,00ch,006h,00ah,000h,013h,077h,03ch,077h,040h,077h,044h,077h,044h,077h,048h,077h,04ch,077h,050h,077h,054h,077h,002h,000h,002h,002h,002h,000h,004h,002h,002h,000h,008h,002h,002h,010h,00ch,002h,002h,010h,00ah,002h,002h,010h,008h,002h,006h,006h,006h,006h	; 7725  ......w<w@wDwDwHwLwPwTw............................

; ======================================================================
; CODIGO 0x7758..0x7770  (24 bytes)
; ======================================================================


el_cuadro_del_quinto_oponente:		; Con 0xE1d0 puesto se va a 0x7805; si no, y con 0xE16b puesto, elige movimiento con la lista de 0x79a3
	ld hl,0e1d0h		;7758   ; HL = 0xE1d0
	ld a,(hl)			;775b
	and a			;775c
	jp nz,el_movimiento_largo_del_quinto		;775d   ; puesto: por el otro camino
	ld a,(0e16bh)		;7760   ; el plazo del movimiento
	and a			;7763
	jp z,mira_donde_esta		;7764
	ld hl,079a3h		;7767   ; la lista de este oponente
	call elige_el_movimiento_del_oponente		;776a
	jp borra_y_recoloca_al_oponente		;776d

; ----------------------------------------------------------------------
; DATOS despacho_escenario_4: Siete punteros a rutina, misma forma. Los 7
;   punteros: 0x73a2 0x73b1 0x7781 0x777e 0x74a2 0x77df 0x74d1
;   0x7770..0x777e  (14 bytes)
DATA_despacho_escenario_4:
	defw 073a2h,073b1h,07781h,0777eh,074a2h,077dfh,074d1h	; 7770

; ======================================================================
; CODIGO 0x777e..0x7787  (9 bytes)
; ======================================================================


el_cuadro_del_quinto_oponente_si_no:		; Dentro de el_cuadro_del_quinto_oponente
	call el_cuadro_del_primer_oponente_otra_vuelta		;777e
el_cuadro_del_quinto_oponente_si_no_2:		; Dentro de el_cuadro_del_quinto_oponente
	call que_golpe_cuenta		;7781
	call despacha_por_la_tabla_de_al_lado		;7784

; ----------------------------------------------------------------------
; DATOS tabla_de_submodos_escenario_4: La que despacha 0x7784. Los 6 punteros:
;   0x6ccd 0x7793 0x77a9 0x77ba 0x77cb 0x7454
;   0x7787..0x7793  (12 bytes)
DATA_tabla_de_submodos_escenario_4:
	defw 06ccdh,07793h,077a9h,077bah,077cbh,07454h	; 7787

; ======================================================================
; CODIGO 0x7793..0x7858  (197 bytes)
; ======================================================================


caracter_7793:		; Pide un numero de 0 a 3 y reparte: el 1 a 0x7450, el 2 a 0x77a4, el 3 a 0x7458, y el 0 a 0x744a
	call saca_un_numero_al_azar		;7793   ; el azar, de 0 a 3
	dec a			;7796
	jp z,pide_el_movimiento_seis		;7797   ; el 1, a 0x7450
	dec a			;779a
	jr z,pide_el_movimiento_tres		;779b   ; el 2, a 0x77a4
	dec a			;779d
	jp z,pide_el_movimiento_cinco		;779e   ; el 3, a 0x7458
caracter_7793_otra_vuelta:		; Dentro de caracter_7793
	jp pide_cuatro_cuadros_de_espera		;77a1   ; y el 0, a 0x744a
pide_el_movimiento_tres:		; A = 3 y al plazo de 0x745a
	ld a,003h		;77a4
	jp el_movimiento_con_el_otro_plazo		;77a6
caracter_77a9:		; Pide un numero de 0 a 3 y reparte: el 1 a 0x7458, el 2 a 0x77a4, el 3 a 0x7454, y el 0 a 0x744a
	call saca_un_numero_al_azar		;77a9   ; el azar, de 0 a 3
	dec a			;77ac
	jp z,pide_el_movimiento_cinco		;77ad   ; el 1, a 0x7458
	dec a			;77b0
	jr z,pide_el_movimiento_tres		;77b1   ; el 2, a 0x77a4
	dec a			;77b3
	jp z,pide_el_movimiento_cuatro		;77b4   ; el 3, a 0x7454
	jp pide_cuatro_cuadros_de_espera		;77b7   ; y el 0, a 0x744a
caracter_77ba:		; Pide un numero de 0 a 3 y reparte: el 1 a 0x7458, el 2 a 0x77a4, el 3 a 0x744a, y el 0 a 0x7454
	call saca_un_numero_al_azar		;77ba   ; el azar, de 0 a 3
	dec a			;77bd
	jp z,pide_el_movimiento_cinco		;77be   ; el 1, a 0x7458
	dec a			;77c1
	jr z,pide_el_movimiento_tres		;77c2   ; el 2, a 0x77a4
	dec a			;77c4
	jp z,pide_cuatro_cuadros_de_espera		;77c5   ; el 3, a 0x744a
	jp pide_el_movimiento_cuatro		;77c8   ; y el 0, a 0x7454
caracter_77cb:		; Pide un numero de 0 a 3 y reparte: el 1 a 0x77a4, el 2 a 0x7454, el 3 a 0x77a1, y el 0 a 0x77e8
	call saca_un_numero_al_azar		;77cb   ; el azar, de 0 a 3
	dec a			;77ce
	jr z,pide_el_movimiento_tres		;77cf   ; el 1, a 0x77a4
	dec a			;77d1
	jp z,pide_el_movimiento_cuatro		;77d2   ; el 2, a 0x7454
	dec a			;77d5
	jr z,caracter_7793_otra_vuelta		;77d6   ; el 3, a 0x77a1
	ld hl,0e003h		;77d8
	ld a,020h		;77db
	jr arranca_el_movimiento_del_quinto		;77dd   ; y el 0, a 0x77e8
caracter_77cb_si_no:		; Dentro de caracter_77cb
	ld hl,0e003h		;77df
	ld a,(hl)			;77e2
	and 03eh		;77e3
	ret nz			;77e5
	ld a,028h		;77e6
arranca_el_movimiento_del_quinto:		; Deja A en 0xE1d0 y, segun el bit 6 del dato, pone 1 o 0 en 0xE1d2
	ld (0e1d0h),a		;77e8   ; el movimiento, apuntado
	ld a,(hl)			;77eb
	bit 6,a		;77ec   ; el bit 6 del dato
	ld a,001h		;77ee   ; a cero, uno...
	jr z,apunta_el_lado_y_el_tipo		;77f0
	xor a			;77f2   ; ...y puesto, cero
apunta_el_lado_y_el_tipo:		; 0xE1d2 con lo que traiga A, el lado en 0xE1d1, y los dos bits que quedan tras dos rotaciones, en 0xE155
	ld (0e1d2h),a		;77f3   ; el tipo
	ld a,(0e185h)		;77f6   ; el lado en que esta el jugador
	ld (0e1d1h),a		;77f9
	ld a,(hl)			;77fc
	rlca			;77fd   ; dos rotaciones...
	rlca			;77fe
	and 003h		;77ff   ; ...y sus dos bits bajos
	ld (0e155h),a		;7801   ; a 0xE155
	ret			;7804
el_movimiento_largo_del_quinto:		; Baja la cuenta y, con ella por encima de 0x20, sigue por 0x784a; si no, la compara con el umbral que 0x7858 da para 0xE155
	dec a			;7805   ; un cuadro menos
	ld (hl),a			;7806
	push af			;7807
	ld a,(0e155h)		;7808   ; 0xE155 elige el umbral
	ld hl,07858h		;780b   ; la tabla de los cuatro
	call suma_a_hl		;780e
	pop af			;7811
	cp 020h		;7812   ; por encima de 0x20, otro camino
	jr c,el_movimiento_largo_del_quinto_si_no		;7814
	ld b,000h		;7816
	jr el_quinto_se_mueve_por_aqui		;7818
el_movimiento_largo_del_quinto_si_no:		; Dentro de el_movimiento_largo_del_quinto
	cp (hl)			;781a   ; contra el umbral
	jr nc,el_quinto_se_mueve		;781b
	ld b,002h		;781d
	jr el_quinto_se_mueve_por_aqui		;781f
el_quinto_se_mueve:		; Uno de cada cuatro cuadros: la columna de 0xE181 sube o baja segun 0xE1d1, con sus topes
	ld a,(0e003h)		;7821   ; el contador de cuadros
	and 002h		;7824   ; su bit 1: uno de cada cuatro
	ret nz			;7826
	ld hl,0e181h		;7827   ; HL = 0xE181, la columna
	ld a,(0e1d1h)		;782a   ; el lado
	and a			;782d
	jr nz,el_quinto_se_mueve_si_no_2		;782e
	ld a,(hl)			;7830
	cp 01dh		;7831   ; el tope de la derecha
	jr nc,el_quinto_se_mueve_si_no		;7833
	inc a			;7835   ; una columna mas
el_quinto_se_mueve_si_no:		; Dentro de el_quinto_se_mueve
	ld (hl),a			;7836
	jr el_quinto_se_mueve_si_no_4		;7837
el_quinto_se_mueve_si_no_2:		; Dentro de el_quinto_se_mueve
	ld a,(hl)			;7839
	cp 002h		;783a
	jr c,el_quinto_se_mueve_si_no_3		;783c
	dec a			;783e
el_quinto_se_mueve_si_no_3:		; Dentro de el_quinto_se_mueve
	ld (hl),a			;783f
el_quinto_se_mueve_si_no_4:		; Dentro de el_quinto_se_mueve
	ld a,(0e1d2h)		;7840
	and a			;7843
	ld b,012h		;7844
	jr z,el_quinto_se_mueve_por_aqui		;7846
	ld b,00ch		;7848
el_quinto_se_mueve_por_aqui:		; Dentro de el_quinto_se_mueve
	ld a,(0e1d1h)		;784a
	and a			;784d
	jr nz,el_quinto_se_mueve_si_no_5		;784e
	inc b			;7850
el_quinto_se_mueve_si_no_5:		; Dentro de el_quinto_se_mueve
	ld a,b			;7851
	ld (0e184h),a		;7852
	jp borra_y_recoloca_al_oponente		;7855

; ----------------------------------------------------------------------
; DATOS cuatro_umbrales_del_quinto: 0x03, 0x08, 0x0e y 0x15, que 0x780e indexa
;   antes de comparar A con 0x20
;   0x7858..0x785c  (4 bytes)
DATA_cuatro_umbrales_del_quinto:
	defb 003h,008h,00eh,015h	; 7858

; ----------------------------------------------------------------------
; DATOS tabla_de_poses_oponente_4: Los 20 punteros que 0x5553 indexa por
;   0xE184 para el oponente 4. El primer destino es 0x7884, que es justo donde
;   acaba la tabla
;   0x785c..0x7884  (40 bytes)
DATA_tabla_de_poses_oponente_4:
	defw 078b7h,078c9h,07884h,07895h,0790ch,07925h,078d0h,078e8h,078efh,07905h,07964h,0797fh,0792ch,07941h,07986h,0799ch	; 785c
	defw 0789ch,078b0h,07948h,0795dh	; 787c  -> DATA_pose_oponente_4_789c DATA_pose_oponente_4_78b0 DATA_pose_oponente_4_7948 DATA_pose_oponente_4_795d

; ----------------------------------------------------------------------
; DATOS pose_oponente_4_7884: 17 bytes, largo. Indice 2 de la tabla de 0x785c
;   0x7884..0x7895  (17 bytes)
DATA_pose_oponente_4_7884:
	defb 0fah,0fah,0f3h,004h,0fdh,000h,004h,005h,0e2h,0f8h,010h,000h,0f4h,018h,000h,0f4h,01ch	; 7884  .................

; ----------------------------------------------------------------------
; DATOS pose_oponente_4_7895: 7 bytes, corto. Indice 3 de la tabla de 0x785c
;   0x7895..0x789c  (7 bytes)
DATA_pose_oponente_4_7895:
	defb 0feh,0feh,0f6h,007h,0feh,089h,078h	; 7895

; ----------------------------------------------------------------------
; DATOS pose_oponente_4_789c: 20 bytes, largo. Indice 16 de la tabla de 0x785c
;   0x789c..0x78b0  (20 bytes)
DATA_pose_oponente_4_789c:
	defb 0f2h,0f2h,0f0h,0fch,0fch,000h,004h,005h,0e2h,0f8h,010h,000h,020h,0f3h,019h,000h,021h,022h,01eh,01fh	; 789c  ............ ...!"..

; ----------------------------------------------------------------------
; DATOS pose_oponente_4_78b0: 7 bytes, corto. Indice 17 de la tabla de 0x785c
;   0x78b0..0x78b7  (7 bytes)
DATA_pose_oponente_4_78b0:
	defb 006h,006h,0feh,00ah,0ffh,0a1h,078h	; 78b0

; ----------------------------------------------------------------------
; DATOS pose_oponente_4_78b7: 18 bytes, largo. Indice 0 de la tabla de 0x785c
;   0x78b7..0x78c9  (18 bytes)
DATA_pose_oponente_4_78b7:
	defb 0fah,0fah,004h,004h,0ffh,000h,004h,003h,010h,0f3h,023h,016h,026h,0f3h,019h,027h,01eh,01fh	; 78b7  ..........#.&..'..

; ----------------------------------------------------------------------
; DATOS pose_oponente_4_78c9: 7 bytes, corto. Indice 1 de la tabla de 0x785c
;   0x78c9..0x78d0  (7 bytes)
DATA_pose_oponente_4_78c9:
	defb 0feh,0feh,0f6h,0f4h,0feh,0bch,078h	; 78c9

; ----------------------------------------------------------------------
; DATOS pose_oponente_4_78d0: 24 bytes, largo. Indice 6 de la tabla de 0x785c
;   0x78d0..0x78e8  (24 bytes)
DATA_pose_oponente_4_78d0:
	defb 0f2h,0f2h,0f8h,0f8h,0fch,000h,081h,0e2h,004h,005h,028h,029h,010h,011h,000h,0f5h,02ah,000h,0f3h,02fh,0e3h,032h,033h,000h	; 78d0  ..........()....*../.23.

; ----------------------------------------------------------------------
; DATOS pose_oponente_4_78e8: 7 bytes, corto. Indice 7 de la tabla de 0x785c
;   0x78e8..0x78ef  (7 bytes)
DATA_pose_oponente_4_78e8:
	defb 006h,006h,002h,002h,0ffh,0d5h,078h	; 78e8

; ----------------------------------------------------------------------
; DATOS pose_oponente_4_78ef: 22 bytes, largo. Indice 8 de la tabla de 0x785c
;   0x78ef..0x7905  (22 bytes)
DATA_pose_oponente_4_78ef:
	defb 0eah,0eah,0e3h,0f8h,0fch,000h,081h,0e2h,004h,004h,034h,035h,011h,000h,036h,037h,02dh,02eh,0f6h,018h,038h,033h	; 78ef  ..........45..67-...83

; ----------------------------------------------------------------------
; DATOS pose_oponente_4_7905: 7 bytes, corto. Indice 9 de la tabla de 0x785c
;   0x7905..0x790c  (7 bytes)
DATA_pose_oponente_4_7905:
	defb 00eh,00eh,017h,008h,000h,0f4h,078h	; 7905

; ----------------------------------------------------------------------
; DATOS pose_oponente_4_790c: 25 bytes, largo. Indice 4 de la tabla de 0x785c
;   0x790c..0x7925  (25 bytes)
DATA_pose_oponente_4_790c:
	defb 0f2h,0f2h,0f2h,0f8h,0fbh,001h,073h,083h,0dch,003h,006h,0e2h,034h,035h,011h,0e2h,039h,03ah,037h,02dh,02eh,0f4h,03bh,031h,03fh	; 790c  ......s.....45..9:7-..;1?

; ----------------------------------------------------------------------
; DATOS pose_oponente_4_7925: 7 bytes, corto. Indice 5 de la tabla de 0x785c
;   0x7925..0x792c  (7 bytes)
DATA_pose_oponente_4_7925:
	defb 006h,006h,002h,008h,0ffh,011h,079h	; 7925

; ----------------------------------------------------------------------
; DATOS pose_oponente_4_792c: 21 bytes, largo. Indice 12 de la tabla de 0x785c
;   0x792c..0x7941  (21 bytes)
DATA_pose_oponente_4_792c:
	defb 0eah,000h,000h,000h,0fch,0ffh,076h,081h,0e2h,002h,007h,034h,035h,0f5h,040h,036h,045h,02dh,0f3h,046h,000h	; 792c  ......v....45.@6E-.F.

; ----------------------------------------------------------------------
; DATOS pose_oponente_4_7941: 7 bytes, corto. Indice 13 de la tabla de 0x785c
;   0x7941..0x7948  (7 bytes)
DATA_pose_oponente_4_7941:
	defb 00eh,006h,000h,000h,0fdh,031h,079h	; 7941

; ----------------------------------------------------------------------
; DATOS pose_oponente_4_7948: 21 bytes, largo. Indice 18 de la tabla de 0x785c
;   0x7948..0x795d  (21 bytes)
DATA_pose_oponente_4_7948:
	defb 000h,0eah,000h,000h,0fch,001h,075h,082h,0e2h,002h,007h,034h,035h,0f5h,040h,036h,045h,02dh,0f3h,046h,000h	; 7948  ......u....45.@6E-.F.

; ----------------------------------------------------------------------
; DATOS pose_oponente_4_795d: 7 bytes, corto. Indice 19 de la tabla de 0x785c
;   0x795d..0x7964  (7 bytes)
DATA_pose_oponente_4_795d:
	defb 002h,011h,000h,000h,0fdh,04dh,079h	; 795d

; ----------------------------------------------------------------------
; DATOS pose_oponente_4_7964: 27 bytes, largo. Indice 10 de la tabla de 0x785c
;   0x7964..0x797f  (27 bytes)
DATA_pose_oponente_4_7964:
	defb 0f2h,0f2h,0f8h,0f8h,0fbh,000h,082h,0ddh,004h,006h,0e2h,034h,035h,011h,0e2h,039h,03ah,037h,02dh,02eh,0f4h,03bh,031h,0e4h,032h,033h,000h	; 7964  ...........45..9:7-..;1.23.

; ----------------------------------------------------------------------
; DATOS pose_oponente_4_797f: 7 bytes, corto. Indice 11 de la tabla de 0x785c
;   0x797f..0x7986  (7 bytes)
DATA_pose_oponente_4_797f:
	defb 004h,006h,002h,002h,0ffh,069h,079h	; 797f

; ----------------------------------------------------------------------
; DATOS pose_oponente_4_7986: 22 bytes, largo. Indice 14 de la tabla de 0x785c
;   0x7986..0x799c  (22 bytes)
DATA_pose_oponente_4_7986:
	defb 000h,000h,000h,000h,0feh,001h,003h,005h,000h,049h,000h,0c1h,0e2h,04ah,04bh,0c2h,000h,04ch,04dh,00eh,0c5h,0c4h	; 7986  .........I...JK..LM...

; ----------------------------------------------------------------------
; DATOS pose_oponente_4_799c: 27 bytes, largo. Indice 15 de la tabla de 0x785c
;   (el ultimo, que llega hasta donde acaba el bloque)
;   0x799c..0x79b7  (27 bytes)
DATA_pose_oponente_4_799c:
	defb 000h,000h,000h,000h,0feh,08bh,079h,01ch,073h,050h,077h,040h,077h,04ch,077h,040h,077h,01ch,073h,050h,077h,075h,06eh,002h,010h,00ah,002h	; 799c  ......y.sPw@wLw@w.sPwun....

; ======================================================================
; CODIGO 0x79b7..0x7a7c  (197 bytes)
; ======================================================================


un_cuadro_de_bonus:		; Lo que corre en vez del oponente. Suelta objetos, los mueve y los comprueba; cuando los tres huecos estan libres y el contador de 0xE270 llega a 0x14, cierra la fase
	call mira_si_toca_soltar		;79b7   ; suelta lo que toque
	call mueve_los_tres_objetos		;79ba
	call mira_si_les_dan		;79bd
	call vuelca_los_tres_objetos		;79c0
	ld a,(0e270h)		;79c3   ; el contador de la fase
	cp 014h		;79c6   ; hasta 0x14 no se cierra
	ret c			;79c8
	ld a,(0e250h)		;79c9   ; el primer hueco...
	ld hl,0e258h		;79cc   ; ...el segundo...
	or (hl)			;79cf
	ld l,060h		;79d0
	or (hl)			;79d2   ; ...y el tercero
	ret nz			;79d3   ; con alguno ocupado, todavia no
	ld a,002h		;79d4
	ld (0e110h),a		;79d6   ; modo 2
	ld a,092h		;79d9   ; A = 0x92, la melodia
	call pon_la_melodia		;79db
	ld a,0d0h		;79de
	ld (0e004h),a		;79e0   ; y plazo de 0xD0
	ret			;79e3
mira_si_toca_soltar:		; Solo con 0xE273 por debajo de 2 y el contador de 0xE270 por debajo de 0x14; en el contador 1 hace falta ademas que se agote 0xE272
	ld a,(0e273h)		;79e4   ; 0xE273 tiene que estar por debajo de 2
	cp 002h		;79e7
	ret nc			;79e9
	ld a,(0e270h)		;79ea   ; el contador de la fase
	cp 014h		;79ed   ; y por debajo de 0x14
	ret nc			;79ef
	dec a			;79f0   ; en el 1...
	jr nz,elige_el_objeto		;79f1
	ld hl,0e272h		;79f3
	dec (hl)			;79f6   ; ...se espera a que 0xE272 se agote
	ret nz			;79f7
elige_el_objeto:		; Los tres bits bajos de 0xE057 por veinte, mas el contador de 0xE270, y el resultado a la mitad: la parte entera indexa la tabla de 0x7a7c y el acarreo elige nibble alto o bajo
	ld hl,0e057h		;79f8   ; HL = 0xE057
	ld a,(hl)			;79fb
	and 007h		;79fc   ; sus tres bits bajos
	add a,a			;79fe   ; por cuatro...
	add a,a			;79ff
	ld c,a			;7a00
	add a,a			;7a01   ; ...por dieciseis...
	add a,a			;7a02
	add a,c			;7a03   ; ...y sumando: por veinte
	ld hl,0e270h		;7a04
	add a,(hl)			;7a07   ; mas el contador de la fase
	rra			;7a08   ; a la mitad, y el resto al acarreo
	push af			;7a09
	and 07fh		;7a0a
	ld hl,07a7ch		;7a0c   ; la tabla de los objetos
	call suma_a_hl		;7a0f
	pop af			;7a12
	ld a,(hl)			;7a13
	jr c,monta_el_objeto		;7a14   ; con acarreo, el nibble bajo
	rra			;7a16   ; y sin el, cuatro rotaciones: el alto
	rra			;7a17
	rra			;7a18
	rra			;7a19
monta_el_objeto:		; Los dos bits bajos del nibble eligen hueco -de ocho en ocho a partir de 0xE250- y patron: 0x7f, 0x8f o 0x9f. Si el hueco esta ocupado no se suelta nada
	and 00fh		;7a1a   ; el nibble
	ld c,a			;7a1c
	and 003h		;7a1d   ; sus dos bits bajos...
	add a,a			;7a1f   ; ...por ocho, que es lo que ocupa un hueco
	add a,a			;7a20
	add a,a			;7a21
	ld hl,0e250h		;7a22   ; HL = 0xE250, el primer hueco
	call suma_a_hl		;7a25
	ld a,(hl)			;7a28
	and a			;7a29   ; ocupado: no se suelta
	ret nz			;7a2a
	ld (hl),001h		;7a2b   ; y si no, se marca
	inc l			;7a2d
	ld a,c			;7a2e
	and 003h		;7a2f
	ld b,07fh		;7a31   ; patron 0x7f...
	dec a			;7a33
	jr nz,monta_el_objeto_si_no		;7a34
	ld b,08fh		;7a36   ; ...0x8f...
monta_el_objeto_si_no:		; Dentro de monta_el_objeto
	dec a			;7a38
	jr nz,la_altura_y_la_velocidad		;7a39
	ld b,09fh		;7a3b   ; ...o 0x9f
la_altura_y_la_velocidad:		; El bit 2 del nibble da la altura -2 o 0xf0- y ademas cambia el signo de la velocidad; el bit 3 elige entre 0x0200 y 0x02a0
	ld (hl),b			;7a3d   ; el patron, guardado
	inc l			;7a3e
	inc l			;7a3f
	ld a,002h		;7a40   ; altura 2...
	bit 2,c		;7a42
	jr z,la_altura_y_la_velocidad_si_no		;7a44
	ld a,0f0h		;7a46   ; ...o 0xf0
la_altura_y_la_velocidad_si_no:		; Dentro de la_altura_y_la_velocidad
	ld (hl),a			;7a48
	inc l			;7a49
	bit 3,c		;7a4a   ; el bit 3 elige la velocidad
	ld de,00200h		;7a4c   ; 0x0200...
	jr z,la_altura_y_la_velocidad_si_no_2		;7a4f
	ld de,002a0h		;7a51   ; ...o 0x02a0
la_altura_y_la_velocidad_si_no_2:		; Dentro de la_altura_y_la_velocidad
	bit 2,c		;7a54   ; y el bit 2 la cambia de signo
	jr z,guarda_la_velocidad		;7a56
	ld a,e			;7a58
	cpl			;7a59   ; el complemento a dos: se niega...
	ld e,a			;7a5a
	ld a,d			;7a5b
	cpl			;7a5c
	ld d,a			;7a5d
	inc de			;7a5e   ; ...y se le suma uno
guarda_la_velocidad:		; Los dos bytes, y detras la pareja que 0x7aae da para este tipo
	ld (hl),e			;7a5f   ; el byte bajo
	inc l			;7a60
	ld (hl),d			;7a61   ; y el alto
	inc l			;7a62
	ld a,c			;7a63
	and 003h		;7a64   ; los dos bits bajos del nibble...
	add a,a			;7a66   ; ...por dos, que son parejas
	ld de,07aaeh		;7a67   ; la tabla de las tres parejas
	call suma_a_de		;7a6a
	ex de,hl			;7a6d
	ld bc,00002h		;7a6e
	ldir		;7a71
	ld hl,0e270h		;7a73
	inc (hl)			;7a76
	ld hl,0e273h		;7a77
	inc (hl)			;7a7a
	ret			;7a7b

; ----------------------------------------------------------------------
; DATOS cincuenta_bytes_de_7a7c: Los indexa 0x7a0f y se queda con uno; el
;   acarreo decide si lo rota o no. Empiezan con dos veces el mismo grupo, 54
;   56 10 12
;   0x7a7c..0x7aae  (50 bytes)
DATA_cincuenta_bytes_de_7a7c:
	defb 054h,056h,010h,012h,054h,056h,010h,012h,054h,056h,029h,00eh,0c6h,0e4h,096h,0a5h	; 7a7c  TV..TV..TV).....
	defb 082h,0e1h,0c1h,00dh,0e5h,04dh,018h,02ch,0e4h,096h,00eh,00ah,0d2h,049h,0a1h,05ch	; 7a8c  .....M.,.....I.\
	defb 086h,0e1h,090h,05ah,04eh,0d2h,01ch,0e4h,04eh,05ch,06dh,00ah,029h,018h,06dh,01eh	; 7a9c  ...ZN...N\m.).m.
	defb 0a0h,0c5h	; 7aac

; ----------------------------------------------------------------------
; DATOS tres_parejas: Seis bytes que 0x7a6a indexa para copiar de DOS EN DOS
;   con un `ldir` de BC = 2: 0x1ea0, 0x07cc y 0x0ed8
;   0x7aae..0x7ab4  (6 bytes)
DATA_tres_parejas:
	defw 007cch,00ed0h,00bd8h	; 7aae

; ======================================================================
; CODIGO 0x7ab4..0x7bbb  (263 bytes)
; ======================================================================


mueve_los_tres_objetos:		; Los tres huecos, uno detras de otro
	ld hl,0e250h		;7ab4   ; el primero
	call mueve_un_objeto		;7ab7
	ld hl,0e258h		;7aba   ; el segundo
	call mueve_un_objeto		;7abd
	ld hl,0e260h		;7ac0   ; y el tercero
mueve_un_objeto:		; Con el estado 1 le suma la velocidad a la X de dieciseis bits; si la parte alta se sale del tramo util, el objeto se apaga
	ld a,(hl)			;7ac3   ; el estado
	inc l			;7ac4
	inc l			;7ac5
	ld e,l			;7ac6   ; DE apunta a la velocidad
	ld d,h			;7ac7
	inc e			;7ac8
	inc e			;7ac9
	dec a			;7aca   ; el estado 1 vuela
	ret m			;7acb   ; a cero, no hay objeto
	jr nz,el_objeto_espera		;7acc
	ld a,(de)			;7ace   ; la velocidad, byte bajo...
	add a,(hl)			;7acf
	ld (hl),a			;7ad0   ; ...sumada a la X
	inc l			;7ad1
	inc e			;7ad2
	ld a,(de)			;7ad3
	adc a,(hl)			;7ad4   ; y el alto, con acarreo
	ld (hl),a			;7ad5
	add a,00fh		;7ad6   ; mas 0x0f...
	cp 011h		;7ad8   ; ...contra 0x11: el tramo util
	ret nc			;7ada
	dec e			;7adb   ; fuera, la velocidad a 0x10
	ld a,010h		;7adc
	ld (de),a			;7ade
	dec l			;7adf
	dec l			;7ae0
	dec l			;7ae1
	ld (hl),003h		;7ae2   ; y el estado a 3
	inc e			;7ae4
	inc e			;7ae5
	inc e			;7ae6
	xor a			;7ae7
	ld (de),a			;7ae8
	ret			;7ae9
el_objeto_espera:		; Baja el contador y, cuando se agota, o lo suelta -estado 1- o lo borra y baja 0xE273
	ex de,hl			;7aea
	dec (hl)			;7aeb   ; un cuadro menos
	ret nz			;7aec
	dec a			;7aed   ; con el estado 2, se suelta
	jr z,suelta_el_objeto		;7aee
	ex de,hl			;7af0
	dec l			;7af1
	dec l			;7af2
	ld (hl),000h		;7af3   ; y si no, el hueco queda libre
	ld hl,0e273h		;7af5   ; HL = 0xE273, los que quedan
	dec (hl)			;7af8   ; uno menos
	ret			;7af9
suelta_el_objeto:		; Le pone 0x10 de cuenta, estado 3, patron 0xf4 y color blanco
	ld (hl),010h		;7afa   ; 0x10 de cuenta
	dec e			;7afc
	dec e			;7afd
	ld a,003h		;7afe   ; el estado 3
	ld (de),a			;7b00
	inc l			;7b01
	inc l			;7b02
	ld (hl),0f4h		;7b03   ; patron 0xf4
	inc hl			;7b05
	ld (hl),00fh		;7b06   ; y color 0x0f, blanco
	ret			;7b08
vuelca_los_tres_objetos:		; Pasa los tres huecos de 0xE250 a la tabla de atributos de 0xE0b0, cuatro bytes por sprite
	ld hl,0e250h		;7b09   ; HL = 0xE250, el primer hueco
	ld de,0e0b0h		;7b0c   ; DE = 0xE0b0, la tabla de atributos
	ld b,003h		;7b0f   ; tres
vuelca_un_objeto:		; Con el hueco libre, la Y va a 0xE0 y el sprite no se ve
	ld a,(hl)			;7b11   ; el estado
	inc l			;7b12
	and a			;7b13
	ld a,(hl)			;7b14
	jr nz,escribe_el_sprite_del_objeto		;7b15
	ld a,0e0h		;7b17   ; libre: fuera de pantalla
escribe_el_sprite_del_objeto:		; Los cuatro bytes, saltandose los que no son de sprite
	ld (de),a			;7b19   ; la Y
	inc l			;7b1a
	inc l			;7b1b
	inc de			;7b1c
	ld a,(hl)			;7b1d
	ld (de),a			;7b1e   ; la X
	inc l			;7b1f
	inc l			;7b20
	inc l			;7b21
	inc de			;7b22
	ld a,(hl)			;7b23   ; el patron
	ld (de),a			;7b24
	inc l			;7b25
	inc de			;7b26
	ld a,(hl)			;7b27   ; y el color
	ld (de),a			;7b28
	inc de			;7b29
	inc l			;7b2a
	djnz vuelca_un_objeto		;7b2b
	ret			;7b2d
mira_si_les_dan:		; Comprueba los tres huecos, cada uno con su numero de golpe. El primero solo si 0xE174 no vale uno
	call mira_si_el_golpe_le_da		;7b2e   ; el reloj de la fase
	ld hl,0e250h		;7b31   ; el primer hueco
	ld a,(0e174h)		;7b34   ; con 0xE174 en uno, este no cuenta
	dec a			;7b37
	ld b,001h		;7b38
	call nz,comprueba_un_objeto		;7b3a
	ld hl,0e258h		;7b3d   ; el segundo
	ld b,002h		;7b40
	call comprueba_un_objeto		;7b42
	ld hl,0e260h		;7b45   ; y el tercero
	ld b,003h		;7b48
comprueba_un_objeto:		; Solo con el estado 1, o sea volando
	ld a,(hl)			;7b4a   ; el estado
	dec a			;7b4b   ; el 1 es el unico que se comprueba
	ret nz			;7b4c
	inc l			;7b4d
mira_si_el_arma_le_da:		; Coge la X del objeto mas ocho y se lo pasa al mismo comprobador que usan las armas del oponente. Si acierta: melodia 0x42 y modo 5
	inc l			;7b4e
	inc l			;7b4f
	ld a,(hl)			;7b50   ; la X del objeto
	add a,008h		;7b51   ; mas ocho, que es medio sprite
	call comprueba_el_alcance		;7b53   ; el comprobador de siempre
	ret z			;7b56
	ld a,042h		;7b57   ; A = 0x42, la melodia del golpe
	call pon_la_melodia		;7b59
	ld a,005h		;7b5c
	ld (0e110h),a		;7b5e   ; y el modo 5
	ret			;7b61
mira_si_el_golpe_le_da:		; Los tres huecos, pero solo el que corresponda a la pose de 0xE172: la 1 el primero, la 2 el segundo y la 3 el tercero
	ld hl,0e250h		;7b62   ; el primer hueco
	ld a,(0e172h)		;7b65   ; la pose del jugador
	dec a			;7b68   ; la 1 mira el primero
	push af			;7b69
	call z,comprueba_y_apunta		;7b6a
	pop af			;7b6d
	ld hl,0e258h		;7b6e   ; el segundo hueco
	dec a			;7b71   ; la 2 mira este
	push af			;7b72
	call z,comprueba_y_apunta		;7b73
	pop af			;7b76
	ld hl,0e260h		;7b77   ; y la 3, el tercero
	dec a			;7b7a
	ret nz			;7b7b
comprueba_y_apunta:		; Solo con el objeto volando. La X del golpe menos la del objeto, menos tres, tiene que caer por debajo de 0x0a. Entonces el objeto pasa a esperar, cambia al patron 0xdc en color 6, la cuenta de 0xE275 sube uno EN BCD y se apuntan cien puntos
	ld e,l			;7b7c
	ld d,h			;7b7d
	ld a,(hl)			;7b7e   ; el estado
	dec a			;7b7f   ; solo el 1, o sea volando
	ret nz			;7b80
	inc l			;7b81
	inc l			;7b82
	inc l			;7b83
	ld a,(0e171h)		;7b84   ; la X del golpe
	sub (hl)			;7b87   ; menos la del objeto...
	sub 003h		;7b88   ; ...menos tres...
	cp 00ah		;7b8a   ; ...tiene que caber en diez
	ret nc			;7b8c
	ld a,002h		;7b8d   ; el estado 2: esperando
	ld (de),a			;7b8f
	inc l			;7b90
	ld (hl),010h		;7b91   ; 0x10 de cuenta
	inc l			;7b93
	inc l			;7b94
	ld (hl),0dch		;7b95   ; patron 0xdc...
	inc l			;7b97
	ld (hl),006h		;7b98   ; ...y color 6
	ld a,(0e275h)		;7b9a   ; la cuenta de golpes
	add a,001h		;7b9d   ; uno mas...
	daa			;7b9f   ; ...en BCD, que es como se dibuja
	ld (0e275h),a		;7ba0
	ld de,00100h		;7ba3   ; y cien puntos
	jp suma_a_la_puntuacion		;7ba6
dibuja_number_of_hits:		; La lista de 0x7bbb
	ld de,07bbbh		;7ba9   ; DE = 0x7bbb, la lista
	jp dibuja_la_lista		;7bac
escribe_la_cuenta_de_golpes:		; Las cifras de 0xE275 en la VRAM 0x39f6, tapando los ceros de delante
	ld de,0e275h		;7baf   ; DE = 0xE275, la cuenta
	ld hl,039f6h		;7bb2   ; HL = VRAM 0x39f6
	ld b,001h		;7bb5   ; un byte de cifras
	call empieza_tapando		;7bb7
	ret			;7bba

; ----------------------------------------------------------------------
; DATOS lista_de_number_of_hits: NUMBER OF HITS en la fila 15 columna 7, la
;   lista que dibuja 0x7bac
;   0x7bbb..0x7bcc  (17 bytes)
DATA_lista_de_number_of_hits:
	defb 0e7h,039h,02eh,035h,02dh,022h,025h,032h,000h,02fh,026h,000h,028h,029h,034h,033h	; 7bbb  .9.5-"%2./&.()43
	defb 0ffh	; 7bcb

; ======================================================================
; CODIGO 0x7bcc..0x7dac  (480 bytes)
; ======================================================================


pon_la_melodia:		; La puerta del motor. Se le pasa la melodia en A, y lo hace todo con las interrupciones cerradas y los cuatro registros a salvo
	di			;7bcc   ; sin interrupciones
	push hl			;7bcd
	push de			;7bce
	push bc			;7bcf
	push af			;7bd0
	ld d,000h		;7bd1   ; D = 0, o sea sin mirar prioridad
	call elige_los_canales		;7bd3
	pop af			;7bd6
	pop bc			;7bd7
	pop de			;7bd8
	pop hl			;7bd9
	ei			;7bda
	ret			;7bdb
elige_los_canales:		; Los seis bits bajos deciden: por debajo de 8, efecto en 0xE032 con un canal; hasta 0x0c, musica en 0xE01a con dos; y de ahi para arriba, tres
	ld c,a			;7bdc   ; C se queda la melodia entera
	ld b,002h		;7bdd   ; dos canales de partida
	ld hl,0e01ah		;7bdf   ; HL = 0xE01a, los canales de musica
	and 03fh		;7be2   ; los seis bits del indice
	cp 008h		;7be4   ; por debajo de 8...
	jr c,elige_los_canales_si_no		;7be6
	cp 00ch		;7be8   ; ...de 0x0c...
	jr c,mira_la_prioridad		;7bea
	inc b			;7bec   ; ...y de ahi para arriba, tres canales
	jr mira_la_prioridad		;7bed
elige_los_canales_si_no:		; Dentro de elige_los_canales
	dec b			;7bef   ; un canal
	ld hl,0e032h		;7bf0   ; y en 0xE032, los de efectos
mira_la_prioridad:		; Solo cuando se entra con D = 1: si lo que ya suena en el canal tiene indice igual o mayor, no se pisa
	dec d			;7bf3   ; con D = 0 se toca sin mirar
	jr z,arranca_los_canales		;7bf4
	ld a,(hl)			;7bf6   ; lo que ya suena
	and 03fh		;7bf7
	ld e,a			;7bf9
	ld a,c			;7bfa   ; contra lo que se pide
	and 03fh		;7bfb
	cp e			;7bfd
	ret c			;7bfe   ; mas bajo, no se pisa
	ret z			;7bff   ; igual, tampoco
arranca_los_canales:		; Coge de la tabla de 0x7db6 el puntero de la melodia y lo reparte por los canales, de ocho en ocho bytes
	and 03fh		;7c00   ; los seis bits del indice
	add a,a			;7c02   ; por dos, que son punteros
	ld de,07db6h		;7c03   ; la tabla de las veintiuna melodias
	call suma_a_de		;7c06
	dec hl			;7c09   ; dos bytes atras: la cabecera del canal
	dec hl			;7c0a
arma_un_canal:		; Los dos primeros bytes a uno, la melodia entera y detras la direccion de donde leer
	ld (hl),001h		;7c0b   ; los dos contadores, a uno
	inc hl			;7c0d
	ld (hl),001h		;7c0e
	inc hl			;7c10
	ld (hl),c			;7c11   ; la melodia entera, con sus dos bits altos
	inc hl			;7c12
	ld a,(de)			;7c13   ; el byte bajo de la direccion...
	ld (hl),a			;7c14
	inc hl			;7c15
	inc de			;7c16
	ld a,(de)			;7c17   ; ...y el alto
	ld (hl),a			;7c18
	ld a,008h		;7c19   ; ocho bytes: el canal siguiente
	add a,l			;7c1b
	ld l,a			;7c1c
	inc de			;7c1d
	djnz arma_un_canal		;7c1e
	ret			;7c20
mira_si_toca_cambiar_de_melodia:		; Compara el byte 9 del canal mas uno con lo que venga; si coinciden se acabo, y si no, se pide la melodia del byte 2 CON prioridad, o sea con D = 1
	inc hl			;7c21
	ld a,(ix+009h)		;7c22   ; el byte 9 del canal
	inc a			;7c25
	cp (hl)			;7c26   ; contra el dato
	jp z,calla_el_canal		;7c27
	jp m,mira_si_toca_cambiar_de_melodia_si_no		;7c2a
	dec a			;7c2d
mira_si_toca_cambiar_de_melodia_si_no:		; Dentro de mira_si_toca_cambiar_de_melodia
	ex af,af'			;7c2e
	ld a,(ix+002h)		;7c2f   ; la melodia del byte 2
	push bc			;7c32
	ld d,001h		;7c33   ; D = 1: esta vez si se mira la prioridad
	call elige_los_canales		;7c35
	pop bc			;7c38
	ex af,af'			;7c39
	ld (ix+009h),a		;7c3a   ; y el byte 9, actualizado
	ret			;7c3d
enciende_o_apaga_el_tono:		; Coloca el bit del canal C en la copia de 0xE03c y lo manda al registro 7 del PSG. Con D a cero se enciende y con D a uno se apaga
	ld a,(0e03ch)		;7c3e   ; la copia del registro 7
	ld e,a			;7c41
	ld a,c			;7c42
	cp 001h		;7c43   ; el canal 1 se queda como esta...
	jr z,enciende_o_apaga_el_tono_si_no		;7c45
	dec a			;7c47   ; ...y los otros bajan uno
enciende_o_apaga_el_tono_si_no:		; Dentro de enciende_o_apaga_el_tono
	rlca			;7c48   ; tres rotaciones: el bit del canal
	rlca			;7c49
	rlca			;7c4a
	dec d			;7c4b   ; D dice si encender o apagar
	jr z,enciende_o_apaga_el_tono_si_no_2		;7c4c
	cpl			;7c4e   ; apagar: el bit al reves y `and`
	and e			;7c4f
	jr enciende_o_apaga_el_tono_otra_vuelta		;7c50
enciende_o_apaga_el_tono_si_no_2:		; Dentro de enciende_o_apaga_el_tono
	or e			;7c52   ; encender: `or`
enciende_o_apaga_el_tono_otra_vuelta:		; Dentro de enciende_o_apaga_el_tono
	ld (0e03ch),a		;7c53   ; la copia, guardada
	ld e,a			;7c56
	ld a,007h		;7c57   ; y al registro 7 del PSG
	jp 00093h		;7c59   ; BIOS WRTPSG - Writes data to PSG-register
un_cuadro_de_sonido:		; Lo que llama la interrupcion. Repone el registro 7, y luego los tres canales, de doce en doce bytes a partir de 0xE018
	ld a,(0e03ch)		;7c5c   ; la copia del registro 7
	call enciende_o_apaga_el_tono_otra_vuelta		;7c5f
	ld c,001h		;7c62   ; C = 1, el primer canal
	ld ix,0e018h		;7c64   ; IX = 0xE018, su cabecera
	exx			;7c68
	ld b,003h		;7c69   ; tres canales
	ld de,0000ch		;7c6b   ; doce bytes por canal
un_canal:		; Con el byte 2 a cero el canal esta callado
	exx			;7c6e
	ld a,(ix+002h)		;7c6f   ; la melodia del canal
	or a			;7c72
	call nz,toca_el_canal		;7c73   ; con algo, se toca
	inc c			;7c76   ; C sube de dos en dos
	inc c			;7c77
	exx			;7c78
	add ix,de		;7c79   ; y IX, doce
	djnz un_canal		;7c7b
	ret			;7c7d
toca_el_canal:		; Sin el bit 6 puesto, apaga el tono. Con el bit 7, se va por 0x7cfe. Si no, baja la cuenta de la nota y solo sigue cuando llega a cero
	bit 6,a		;7c7e   ; el bit 6 de la melodia
	ld d,001h		;7c80   ; D = 1: apagar
	call z,enciende_o_apaga_el_tono		;7c82
	ld a,(ix+002h)		;7c85   ; la melodia otra vez
	or a			;7c88
	jp m,apaga_poco_a_poco		;7c89   ; con el bit 7, por otro lado
	dec (ix+000h)		;7c8c   ; un cuadro menos de nota
	ret nz			;7c8f   ; y hasta que no se agote, nada
lee_el_dato_siguiente:		; Coge de los bytes 3 y 4 por donde iba y lee. El 0xFE cambia de melodia y de 0xFE para arriba se cierra
	ld l,(ix+003h)		;7c90   ; el byte bajo...
	ld h,(ix+004h)		;7c93   ; ...y el alto
	ld a,(hl)			;7c96
	cp 0feh		;7c97   ; el 0xFE cambia de melodia
	jp z,mira_si_toca_cambiar_de_melodia		;7c99
	jr nc,calla_el_canal		;7c9c   ; y de ahi para arriba, se cierra
	bit 7,(ix+002h)		;7c9e   ; con el bit 7 de la melodia, otro camino
	jp nz,el_formato_largo		;7ca2
	and 0f0h		;7ca5
	cp 020h		;7ca7   ; el 0x2- da la duracion...
	jr nz,mira_si_hay_envolvente		;7ca9
	ld a,(hl)			;7cab
	and 00fh		;7cac
	ld (ix+001h),a		;7cae   ; ...que se guarda en el byte 1
	inc hl			;7cb1
mira_si_hay_envolvente:		; El 0x1- escribe los cinco bits bajos en el registro 6 del PSG -el del ruido- y enciende el tono
	ld a,(hl)			;7cb2
	and 0f0h		;7cb3   ; el nibble alto
	cp 010h		;7cb5   ; el 0x1-...
	jr nz,la_nota		;7cb7
	ld a,(hl)			;7cb9
	and 01fh		;7cba   ; ...deja cinco bits...
	ld e,a			;7cbc
	ld a,006h		;7cbd   ; ...en el registro 6 del PSG
	call 00093h		;7cbf   ; BIOS WRTPSG - Writes data to PSG-register
	ld d,000h		;7cc2   ; D = 0: encender el tono
	call enciende_o_apaga_el_tono		;7cc4
	inc hl			;7cc7
la_nota:		; El nibble alto es el volumen y el bajo, con el byte siguiente, la nota. Guarda por donde va y calcula el divisor
	ld a,(hl)			;7cc8
	and 0f0h		;7cc9   ; el nibble alto: el volumen
	ld b,a			;7ccb
	xor (hl)			;7ccc   ; y el bajo, parte de la nota
	ld d,a			;7ccd
	inc hl			;7cce
	ld e,(hl)			;7ccf   ; el byte siguiente
	inc hl			;7cd0
	ld (ix+003h),l		;7cd1   ; por donde se ha quedado
	ld (ix+004h),h		;7cd4
	ex de,hl			;7cd7
	call escribe_el_divisor		;7cd8   ; el divisor de la nota
	ld a,b			;7cdb
	rrca			;7cdc   ; cuatro rotaciones: el volumen abajo
	rrca			;7cdd
	rrca			;7cde
	rrca			;7cdf
repone_la_duracion:		; La duracion del byte 1 vuelve al byte 0, y el volumen queda en el byte 8 con dos de mas
	ld h,a			;7ce0
	ld a,(ix+001h)		;7ce1   ; la duracion guardada
	ld (ix+000h),a		;7ce4   ; al contador
	add a,002h		;7ce7   ; y dos mas, al volumen
	ld (ix+008h),a		;7ce9
	jr escribe_el_volumen		;7cec
calla_el_canal:		; Bucle a cero, tono apagado, melodia a cero y volumen a cero
	xor a			;7cee
	ld (ix+009h),a		;7cef   ; el bucle, a cero
	ld d,001h		;7cf2   ; D = 1: apagar el tono
	call enciende_o_apaga_el_tono		;7cf4
	xor a			;7cf7
	ld (ix+002h),a		;7cf8   ; la melodia, borrada
	ld h,a			;7cfb   ; y el volumen a cero
	jr escribe_el_volumen		;7cfc
apaga_poco_a_poco:		; El otro camino, el del bit 7: baja la cuenta de la nota y, con ella agotada, lee el dato siguiente. Mientras tanto va bajando el volumen del byte 8 y luego el del byte 7
	dec (ix+000h)		;7cfe   ; un cuadro menos de nota
	jp z,lee_el_dato_siguiente		;7d01   ; agotada, a leer
	dec (ix+008h)		;7d04   ; un punto menos de volumen
	ld a,(ix+008h)		;7d07
	cp (ix+000h)		;7d0a   ; contra los cuadros que quedan
	jr nz,apaga_poco_a_poco_si_no		;7d0d
	cp 005h		;7d0f   ; por debajo de 5, no se baja mas
	jr c,baja_el_volumen_de_verdad		;7d11
	ret			;7d13
apaga_poco_a_poco_si_no:		; Dentro de apaga_poco_a_poco
	dec (ix+008h)		;7d14   ; y otro punto menos
baja_el_volumen_de_verdad:		; El byte 7 es el volumen que se manda al PSG; con el en negativo ya no se toca
	ld a,(ix+007h)		;7d17   ; el volumen del byte 7
	dec a			;7d1a   ; uno menos
	ret m			;7d1b   ; en negativo, se deja
	ld (ix+007h),a		;7d1c
	ld h,a			;7d1f   ; y ese es el que va al PSG
escribe_el_volumen:		; El registro de volumen del canal: 0x88 mas la mitad de C, que es 8, 9 o 10
	ld a,c			;7d20
	rrca			;7d21   ; C entre dos
	add a,088h		;7d22   ; mas 0x88: el registro del canal
	ld e,h			;7d24
	jp 00093h		;7d25   ; BIOS WRTPSG - Writes data to PSG-register | al PSG
el_formato_largo:		; Los tres campos opcionales, en orden: 0xD- la unidad de duracion, 0xF- el decaimiento y 0xE- la octava o el medio tono
	ld a,(hl)			;7d28
	and 0f0h		;7d29   ; el nibble alto
	cp 0d0h		;7d2b   ; el 0xD-...
	ld a,(hl)			;7d2d
	jr nz,mira_si_hay_decaimiento		;7d2e
	and 00fh		;7d30
	ld (ix+00ah),a		;7d32   ; ...deja la unidad de duracion en el byte 10
	inc hl			;7d35
	ld a,(hl)			;7d36
mira_si_hay_decaimiento:		; El 0xF- deja su nibble bajo en el byte 6
	cp 0f0h		;7d37   ; el 0xF-...
	jr c,mira_si_hay_octava		;7d39
	and 00fh		;7d3b
	ld (ix+006h),a		;7d3d   ; ...al byte 6
	inc hl			;7d40
	ld a,(hl)			;7d41
mira_si_hay_octava:		; El 0xE- con el bit 3 puesto va al byte 11 y vuelve a empezar; sin el, es la octava y va al byte 5
	cp 0e0h		;7d42   ; el 0xE-...
	jr c,la_duracion_de_la_nota		;7d44
	and 00fh		;7d46
	bit 3,a		;7d48   ; ...con el bit 3...
	jr z,mira_si_hay_octava_si_no		;7d4a
	ld (ix+00bh),a		;7d4c   ; ...al byte 11, el medio tono
	inc hl			;7d4f
	jr el_formato_largo		;7d50
mira_si_hay_octava_si_no:		; Dentro de mira_si_hay_octava
	ld (ix+005h),a		;7d52   ; y si no, al byte 5: la octava
	inc hl			;7d55
	ld a,(hl)			;7d56
la_duracion_de_la_nota:		; El nibble bajo dice cuantas veces se suma la unidad de duracion del byte 10
	and 00fh		;7d57
	ld b,a			;7d59   ; las veces
	ld a,(ix+00ah)		;7d5a   ; la unidad de duracion
	jr z,la_duracion_de_la_nota_si_no		;7d5d
la_duracion_de_la_nota_otra_vuelta:		; Dentro de la_duracion_de_la_nota
	add a,(ix+00ah)		;7d5f   ; sumada tantas veces
	djnz la_duracion_de_la_nota_otra_vuelta		;7d62
la_duracion_de_la_nota_si_no:		; Dentro de la_duracion_de_la_nota
	ld (ix+001h),a		;7d64   ; y esa es la duracion
la_nota_y_su_volumen:		; El nibble alto del byte siguiente es la nota; menos 0x0c da el volumen de partida, y si no sale cero se usa el decaimiento del byte 6
	ld a,(hl)			;7d67
	inc hl			;7d68   ; por donde se ha quedado
	ld (ix+003h),l		;7d69
	ld (ix+004h),h		;7d6c
	and 0f0h		;7d6f   ; el nibble alto: la nota
	rrca			;7d71
	rrca			;7d72
	rrca			;7d73
	rrca			;7d74
	ld b,a			;7d75
	sub 00ch		;7d76   ; menos 0x0c
	ld (ix+007h),a		;7d78   ; al byte 7, el volumen que va al PSG
	jr z,calcula_el_divisor		;7d7b
	ld a,(ix+006h)		;7d7d   ; y si no era cero, el decaimiento
	ld (ix+007h),a		;7d80
calcula_el_divisor:		; La tabla de 0x7dac da el divisor de la nota mas aguda, y el byte 5 lo DUPLICA una vez por octava. El byte 11, si esta puesto, le suma uno
	call repone_la_duracion		;7d83   ; la duracion, repuesta
	ld a,b			;7d86
	ld hl,07dach		;7d87   ; la tabla de los diez divisores
	call suma_a_hl		;7d8a
	ld l,(hl)			;7d8d   ; el divisor, en L con H a cero
	ld h,000h		;7d8e
	ld a,(ix+005h)		;7d90   ; las octavas del byte 5
	or a			;7d93
	jr z,escribe_el_divisor		;7d94
	ld b,a			;7d96
calcula_el_divisor_otra_vuelta:		; Dentro de calcula_el_divisor
	add hl,hl			;7d97   ; duplicar el divisor baja una octava
	djnz calcula_el_divisor_otra_vuelta		;7d98
	ld a,(ix+00bh)		;7d9a   ; el medio tono del byte 11
	or a			;7d9d
	jr z,escribe_el_divisor		;7d9e
	inc hl			;7da0   ; un punto mas de divisor
escribe_el_divisor:		; Los dos registros de tono del canal: el alto en C y el bajo en C menos uno
	ld a,c			;7da1
	ld e,h			;7da2   ; el byte alto del divisor
	call 00093h		;7da3   ; BIOS WRTPSG - Writes data to PSG-register
	ld a,c			;7da6   ; y el bajo, en el registro de al lado
	dec a			;7da7
	ld e,l			;7da8
	jp 00093h		;7da9   ; BIOS WRTPSG - Writes data to PSG-register

; ----------------------------------------------------------------------
; DATOS divisores_de_las_notas: Los diez de la escala cromatica: 106, 100, 95,
;   89, 84, 80, 75, 71, 67 y 63. Los indexa 0x7d8a y los baja de octava a
;   golpe de `add hl,hl`
;   0x7dac..0x7db6  (10 bytes)
DATA_divisores_de_las_notas:
	defb 06ah,064h,05fh,059h,054h,050h,04bh,047h,043h,03fh	; 7dac  jd_YTPKGC?

; ----------------------------------------------------------------------
; DATOS tabla_de_melodias: Las veintiuna entradas que indexa 0x7c03. La 0 vale
;   0x383c y no apunta a nada; las otras veinte van a 16 melodias distintas,
;   porque varias comparten la de 0x7fef
;   0x7db6..0x7de0  (42 bytes)
DATA_tabla_de_melodias:
	defw 0383ch,07de0h,07e0ah,07e1fh,07e26h,07e30h,07e3bh,07e3fh,07e48h,07ed6h,07f90h,07fa2h,07e14h,07fefh,07fefh,07fb6h	; 7db6
	defw 07fc9h,07fdeh,07fefh,07fefh,07fefh	; 7dd6

; ----------------------------------------------------------------------
; DATOS melodia_7de0: 42 bytes. Entrada 1 de la tabla de 0x7db6
;   0x7de0..0x7e0a  (42 bytes)
DATA_melodia_7de0:
	defb 021h,080h,08ah,0a0h,091h,0c0h,08dh,0d0h,08fh,023h,000h,000h,021h,0e0h,071h,0d0h	; 7de0  !........#..!.q.
	defb 072h,0d0h,074h,0c0h,077h,0d0h,07bh,0b0h,080h,0c0h,086h,0a0h,08ch,0b0h,093h,090h	; 7df0  r.t.w.{.........
	defb 09ah,0a0h,0a2h,080h,0ach,090h,0b7h,070h,0c3h,0ffh	; 7e00  .......p..

; ----------------------------------------------------------------------
; DATOS melodia_7e0a: 10 bytes. Entrada 2 de la tabla de 0x7db6
;   0x7e0a..0x7e14  (10 bytes)
DATA_melodia_7e0a:
	defb 021h,0f2h,0e8h,0d2h,051h,022h,015h,0b2h,0d6h,0ffh	; 7e0a  !...Q"....

; ----------------------------------------------------------------------
; DATOS melodia_7e14: 11 bytes. Entrada 12 de la tabla de 0x7db6
;   0x7e14..0x7e1f  (11 bytes)
DATA_melodia_7e14:
	defb 021h,015h,0f1h,055h,022h,000h,000h,019h,0f1h,088h,0ffh	; 7e14  !..U"......

; ----------------------------------------------------------------------
; DATOS melodia_7e1f: 7 bytes. Entrada 3 de la tabla de 0x7db6
;   0x7e1f..0x7e26  (7 bytes)
DATA_melodia_7e1f:
	defb 023h,0b0h,040h,000h,000h,0feh,00ch	; 7e1f

; ----------------------------------------------------------------------
; DATOS melodia_7e26: 10 bytes. Entrada 4 de la tabla de 0x7db6
;   0x7e26..0x7e30  (10 bytes)
DATA_melodia_7e26:
	defb 021h,0b0h,058h,022h,000h,000h,021h,0a0h,064h,0ffh	; 7e26  !.X"..!.d.

; ----------------------------------------------------------------------
; DATOS melodia_7e30: 11 bytes. Entrada 5 de la tabla de 0x7db6
;   0x7e30..0x7e3b  (11 bytes)
DATA_melodia_7e30:
	defb 024h,0b1h,01dh,0b0h,0d5h,0b0h,0a9h,0b0h,08eh,0feh,002h	; 7e30  $..........

; ----------------------------------------------------------------------
; DATOS melodia_7e3b: 4 bytes. Entrada 6 de la tabla de 0x7db6
;   0x7e3b..0x7e3f  (4 bytes)
DATA_melodia_7e3b:
	defb 021h,0c0h,050h,0ffh	; 7e3b

; ----------------------------------------------------------------------
; DATOS melodia_7e3f: 9 bytes. Entrada 7 de la tabla de 0x7db6
;   0x7e3f..0x7e48  (9 bytes)
DATA_melodia_7e3f:
	defb 023h,0c0h,087h,0b0h,078h,0c0h,06dh,0feh,003h	; 7e3f  #...x.m..

; ----------------------------------------------------------------------
; DATOS melodia_7e48: 142 bytes. Entrada 8 de la tabla de 0x7db6
;   0x7e48..0x7ed6  (142 bytes)
DATA_melodia_7e48:
	defb 0d8h,0fbh,0e0h,061h,060h,060h,041h,041h,011h,011h,0e1h,093h,0b0h,0e0h,010h,0e1h	; 7e48  ...a``AA........
	defb 0b0h,090h,061h,091h,065h,0c1h,0e2h,01dh,0e3h,091h,0e2h,04fh,01dh,0e3h,091h,0e2h	; 7e58  ..a.e......O....
	defb 06fh,0e1h,011h,010h,0e2h,0b0h,0e1h,011h,041h,013h,0e2h,093h,0b0h,0e1h,010h,0e2h	; 7e68  o.......A.......
	defb 0b0h,090h,061h,091h,0e1h,012h,0e2h,0b0h,0e1h,013h,0c1h,090h,060h,040h,011h,041h	; 7e78  ..a.........`@.A
	defb 061h,010h,0e2h,0b0h,0e1h,010h,0e2h,091h,0c0h,0e1h,090h,060h,040h,011h,0e2h,0b0h	; 7e88  a..........`@...
	defb 0e1h,010h,065h,0c1h,0b2h,0e0h,010h,0e1h,0b0h,090h,060h,090h,060h,090h,060h,040h	; 7e98  ..e.......`.`.`@
	defb 021h,061h,041h,0e2h,0b0h,0e1h,010h,040h,060h,090h,0b0h,0e0h,012h,0e1h,0b0h,0e0h	; 7ea8  !aA....@`.......
	defb 013h,0e1h,0b0h,0e0h,010h,0e1h,0b0h,090h,060h,090h,060h,040h,020h,040h,020h,0e2h	; 7eb8  ........`.`@ @ .
	defb 090h,0e1h,021h,061h,041h,0e2h,0b0h,0e1h,010h,040h,010h,041h,067h,0ffh	; 7ec8  ..!aA....@.Ag.

; ----------------------------------------------------------------------
; DATOS melodia_7ed6: 186 bytes. Entrada 9 de la tabla de 0x7db6
;   0x7ed6..0x7f90  (186 bytes)
DATA_melodia_7ed6:
	defb 0d8h,0fbh,0e0h,011h,010h,010h,0e1h,0b1h,0b1h,081h,081h,043h,060h,080h,060h,040h	; 7ed6  ...........C`.`@
	defb 011h,041h,015h,0c1h,0e3h,061h,060h,060h,0b1h,0e2h,011h,0e3h,061h,060h,060h,0b1h	; 7ee6  .A...a``....a``.
	defb 0e2h,011h,0e3h,061h,060h,060h,0b1h,0e2h,011h,0e3h,061h,060h,060h,0b1h,0e2h,011h	; 7ef6  ...a``....a``...
	defb 0e3h,061h,060h,060h,0b1h,0e2h,011h,0e3h,061h,060h,060h,0b1h,0e2h,011h,0e3h,061h	; 7f06  .a``....a``....a
	defb 060h,060h,0b1h,0e2h,011h,0e3h,061h,060h,060h,0b1h,0e2h,011h,0e3h,061h,0e2h,061h	; 7f16  ``....a``....a.a
	defb 011h,061h,0e3h,061h,0e2h,061h,011h,061h,0e3h,061h,0e2h,061h,011h,061h,0e3h,061h	; 7f26  .a.a.a.a.a.a.a.a
	defb 0e2h,061h,011h,061h,0e3h,091h,0e2h,091h,041h,091h,0e3h,091h,0e2h,091h,041h,091h	; 7f36  .a.a....A.....A.
	defb 0e3h,061h,0e2h,061h,011h,061h,0e3h,061h,0e2h,010h,0e3h,0b0h,0e2h,011h,061h,0e4h	; 7f46  .a.a.a.a......a.
	defb 0b1h,0e3h,0b1h,061h,0b1h,021h,0e2h,021h,0e3h,091h,0e2h,0b1h,0e3h,041h,0e2h,041h	; 7f56  ...a.!.!.....A.A
	defb 0e3h,0b1h,0e2h,041h,0e4h,091h,0e3h,091h,041h,091h,0e4h,0b1h,0e3h,0b1h,061h,0b1h	; 7f66  ...A....A.....a.
	defb 021h,0e2h,021h,0e3h,091h,0e2h,021h,0e3h,041h,0e2h,041h,0e3h,0b1h,0e2h,041h,0e3h	; 7f76  !.!...!.A.A...A.
	defb 061h,0e2h,010h,0e3h,0b0h,0e2h,011h,061h,0feh,0ffh	; 7f86  a......a..

; ----------------------------------------------------------------------
; DATOS melodia_7f90: 18 bytes. Entrada 10 de la tabla de 0x7db6
;   0x7f90..0x7fa2  (18 bytes)
DATA_melodia_7f90:
	defb 0d7h,0fch,0e1h,061h,060h,060h,081h,061h,0a1h,080h,060h,033h,010h,030h,060h,080h	; 7f90  ...a``.a..`3.0`.
	defb 0a4h,0ffh	; 7fa0

; ----------------------------------------------------------------------
; DATOS melodia_7fa2: 20 bytes. Entrada 11 de la tabla de 0x7db6
;   0x7fa2..0x7fb6  (20 bytes)
DATA_melodia_7fa2:
	defb 0d7h,0fch,0e1h,011h,010h,010h,031h,011h,061h,030h,010h,0e2h,0a3h,080h,0a0h,0e1h	; 7fa2  ......1.a0......
	defb 010h,030h,064h,0ffh	; 7fb2

; ----------------------------------------------------------------------
; DATOS melodia_7fb6: 19 bytes. Entrada 15 de la tabla de 0x7db6
;   0x7fb6..0x7fc9  (19 bytes)
DATA_melodia_7fb6:
	defb 0d8h,0fbh,0e1h,061h,040h,060h,0d9h,011h,0e2h,0b0h,0e1h,010h,041h,0dah,010h,0dbh	; 7fb6  ...a@`......A...
	defb 040h,065h,0ffh	; 7fc6

; ----------------------------------------------------------------------
; DATOS melodia_7fc9: 21 bytes. Entrada 16 de la tabla de 0x7db6
;   0x7fc9..0x7fde  (21 bytes)
DATA_melodia_7fc9:
	defb 0d8h,0fch,0e1h,011h,0e2h,0b0h,0e1h,010h,0d9h,0e2h,081h,060h,080h,0b1h,0dah,080h	; 7fc9  ...........`....
	defb 0dbh,0b0h,0e1h,015h,0ffh	; 7fd9

; ----------------------------------------------------------------------
; DATOS melodia_7fde: 17 bytes. Entrada 17 de la tabla de 0x7db6
;   0x7fde..0x7fef  (17 bytes)
DATA_melodia_7fde:
	defb 0d8h,0fch,0e3h,091h,060h,090h,0d9h,041h,010h,040h,060h,040h,0dah,060h,0dbh,080h	; 7fde  ....`..A.@`@.`..
	defb 095h	; 7fee

; ----------------------------------------------------------------------
; DATOS melodia_muda: UN SOLO BYTE, 0xFF. Cinco entradas de la tabla de 0x7db6
;   -la 13, la 14, la 18, la 19 y la 20- apuntan aqui, y lo que hacen es
;   callar el canal: el interprete de 0x7c97 compara con 0xFE y de ahi para
;   arriba cierra. Es la melodia que no suena
;   0x7fef..0x7ff0  (1 bytes)
DATA_melodia_muda:
	defb 0ffh	; 7fef

; ----------------------------------------------------------------------
; DATOS el_nombre_en_el_ultimo_hueco: Los ultimos dieciseis bytes del
;   cartucho: YIE AR KUNG FU en ASCII de siete bits -59 49 45 20 41 52 20 4B
;   55 4E 47 20 46 55- y dos 0xFF de relleno. No lo lee nadie: ni el codigo ni
;   ninguna lista de tiles, y ademas no podria, porque el alfabeto de este
;   cartucho no es ASCII sino la A en el tile 0x21.
;   0x7ff0..0x8000  (16 bytes)
DATA_el_nombre_en_el_ultimo_hueco:
	defb 059h,049h,045h,020h,041h,052h,020h,04bh,055h,04eh,047h,020h,046h,055h,0ffh,0ffh	; 7ff0  YIE AR KUNG FU..
