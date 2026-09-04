# En el emulador

Las imágenes de este sitio no son capturas: las monta `tools/pantallas.py`
ejecutando en Python los pasos del propio cartucho. Mirarlas no basta para
darlas por buenas, así que se comparan **byte a byte** con la VRAM de verdad.

## Cómo se saca la VRAM de verdad

`tools/omsx_vram.tcl` deja correr el juego en openMSX y, en varios instantes,
vuelca los 16 KB de VRAM, los ocho registros del VDP y las variables que dicen
qué se estaba dibujando:

    "C:/Program Files/openMSX/openmsx.exe" -machine Philips_VG_8020 \
        -cart yiear.rom -script tools/omsx_vram.tcl

No pone ningún punto de ruptura. Todo el juego corre dentro de la interrupción
de 0x4043 y un `bp` ahí ahoga al emulador, así que los volcados van por reloj
emulado. Lleva además un perro guardián de tiempo real: un guion roto no puede
colgar el emulador indefinidamente.

## El resultado

Comparando la VRAM que monta `pantallas.py` con la que openMSX tiene a los 120
segundos de partida:

| tabla | bytes | distintos |
|---|---|---|
| COLOR (0x0000–0x17FF) | 6.144 | **0** |
| PATRONES (0x2000–0x37FF) | 6.144 | **0** |
| NOMBRES (0x3800–0x3AFF) | 768 | 43 |
| PATRONES DE SPRITE (0x1800–0x1FFF) | 2.048 | 520 |

Las dos tablas grandes salen **exactas**. Lo que no coincide es lo que el juego
reescribe cada cuadro y que el montaje no tiene por qué poner:

- en la tabla de nombres, las cifras del marcador, el nombre del oponente y los
  tiles con que está dibujado el luchador en ese instante;
- en los patrones de sprite, la pose del jugador en ese cuadro, que se redibuja
  encima de las figuras que dejó el arranque.

## La trampa de los buffers

Los patrones de sprite y una parte de los tiles se reutilizan varias veces por
cuadro. Si un volcado sale "todo distinto menos una cosa", el fallo no es el
formato: es el **momento** en que se ha volcado.

Por eso el volcado que vale para comparar es uno tomado con el combate en
marcha y estable, no uno del arranque ni uno de la transición entre escenas.

## Un fallo que solo cazó la comparación

El bucle de espejo de 0x4C46 se leyó al principio como si el origen avanzara un
tercio en cada vuelta. Los renders salían plausibles —se veía un templo— y
solo la comparación con la VRAM lo tumbó: **el origen no avanza**, y en cada
vuelta el cartucho hace `pop de / ld hl,00800h / add hl,de / ex de,hl / pop hl`,
que suma 0x800 al **destino** y recupera el HL de partida.

Con eso arreglado, la tabla de patrones pasó de 776 bytes distintos a **cero**.
