# La música

Todo lo que suena aquí sale de ejecutar el motor de sonido del cartucho (`un_cuadro_de_sonido`, 0x7C5C, y `pon_la_melodia`, 0x7BCC, que le reparte los canales; lo llama la interrupción) en un Z80 emulado, cuadro a cuadro y a 60 por segundo, igual que lo llama el juego. Lo que el motor escribe en el PSG pasa a sonido con un AY-3-8910 (`tools/musica.py`). Cada MP3 es la pieza entera hasta donde vuelve a empezar, más 8 segundos de la vuelta apagándose; las que no se repiten acaban donde acaba el motor.

## Cotejado con openMSX

Las escrituras al PSG se han comparado cuadro a cuadro con las de openMSX (C-BIOS MSX1 japonés). En todos los cuadros el PSG queda igual:

- la música del combate (0x88), tal como el juego la pide, sus primeros 361 y 957 cuadros;
- el final de la partida (0x8F) entero, 175 cuadros, y la caída (0x8A) entera, 177, pedidas a la fuerza.

El timbre no está cotejado: es el de un AY-3-8910 de manual, no una grabación del emulador. Las sondas están en `tools/omsx_psg.tcl` y `tools/coteja_psg.py`.

## Cómo se pide una pieza

`pon_la_melodia` recibe el número en A, sin mirar prioridad. Los números bajos son efectos y del 0x88 en adelante hay música. Cada canal ocupa doce bytes desde 0xE018 y 0xE03C guarda la copia del mezclador del PSG, que el arranque deja en 0xB8. Las pistas «de la tabla» están en la tabla de pistas pero ninguna rutina las pide con un `ld a`. Hay tres piezas cotejadas con openMSX, la 0x88, la 0x8F y la 0x8A; las demás salen del mismo motor, pero no se ha comparado cada una.

## Las músicas

**La música del combate** (0x88)

Lo pide `escena_3_arranca_la_musica`, `escena_4_el_combate`, `premio` y `apunta_el_enemigo`; dura 29,9 s y vuelve a empezar en el segundo 0,0.

<audio controls preload="none" src="../audio/musica_88.mp3?v=2378cd28"></audio>

**El final de la partida** (0x8F)

Lo pide `se_acabo_la_partida`; dura 2,9 s.

<audio controls preload="none" src="../audio/musica_8F.mp3?v=87ab3279"></audio>

**La caída** (0x8A)

Lo pide `modo_3_la_caida_si_no_2`; dura 3,0 s.

<audio controls preload="none" src="../audio/musica_8A.mp3?v=3d146e7b"></audio>

**Pista 0x89 de la tabla** (0x89)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 32,8 s y vuelve a empezar en el segundo 2,9.

<audio controls preload="none" src="../audio/musica_89.mp3?v=f30dd76b"></audio>

**Pista 0x8B de la tabla** (0x8B)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 34,2 s.

<audio controls preload="none" src="../audio/musica_8B.mp3?v=2c76b9b1"></audio>

**Pista 0x8D de la tabla** (0x8D)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 2,9 s.

<audio controls preload="none" src="../audio/musica_8D.mp3?v=1e627eec"></audio>

**Pista 0x8E de la tabla** (0x8E)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 2,9 s.

<audio controls preload="none" src="../audio/musica_8E.mp3?v=b6138767"></audio>

**Pista 0x90 de la tabla** (0x90)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 2,9 s.

<audio controls preload="none" src="../audio/musica_90.mp3?v=bc588af4"></audio>

**Pista 0x91 de la tabla** (0x91)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 2,9 s.

<audio controls preload="none" src="../audio/musica_91.mp3?v=8e1cbe7a"></audio>
