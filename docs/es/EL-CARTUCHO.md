# El cartucho

16.384 bytes en la página 1, de 0x4000 a 0x7FFF. La BIOS lee la cabecera `AB`
y llama a INIT.

## La cabecera

Los diez primeros bytes son `41 42 10 40 00 00 00 00 00 00`: declara **solo
INIT**, y aquí INIT está pegado a la cabecera, en 0x4010. Ni STATEMENT, ni
DEVICE, ni TEXT.

## El reparto de los 16.384 bytes

| | bytes | |
|---|---|---|
| código trazado | 7.494 | 45,7 % |
| datos identificados | 8.890 | 54,3 % |
| **sin explicar** | **0** | **0,0 %** |

Lo cuenta `tools/presupuesto.py`, que cruza el trazado del flujo con los rangos
declarados en las notas. La comprobación no es que las cifras cuadren: es que
**cada rango tenga nombre y explicación**.

## El mapa de VRAM

Los ocho valores de 0x4503, de R0 a R7, son `02 E2 0E 7F 07 76 03 E0`, y de ahí
sale el mapa entero:

| | dónde | de qué registro |
|---|---|---|
| COLOR | 0x0000 | R3 = 0x7F |
| PATRONES DE SPRITE | 0x1800 | R6 = 0x03 |
| PATRONES | 0x2000 | R4 = 0x07 |
| NOMBRES | 0x3800 | R2 = 0x0E |
| ATRIBUTOS DE SPRITE | 0x3B00 | R5 = 0x76 |

R3 y R4 **no son direcciones**: son un bit de base y una máscara. Lo que dicen
es color abajo y patrón arriba, al revés de lo habitual. Y R1 = 0xE2, con el bit
1 puesto y el 0 a cero, quiere decir **sprites de 16x16 sin ampliar**.

Estos ocho valores son los mismos que los de otros dos cartuchos de la misma
familia salvo R7, el color de borde.

## Los dos intérpretes de dibujo

El cartucho no guarda volcados de VRAM: guarda programas cortos que se
interpretan. Hay dos, y conviene no confundirlos.

**GUIONES** (el intérprete de 0x442C). Escriben por el **puerto de datos** del
VDP, byte a byte, con dos comandos:

    0x00           fin
    0x80           encadena: los dos bytes siguientes son una dirección
                   de VRAM nueva, BYTE BAJO PRIMERO
    n (bit 7 a 0)  relleno: el byte siguiente, repetido n veces
    n (bit 7 a 1)  copia cruda de (n and 0x7F) bytes

**LISTAS DE TILES** (el de 0x44A6). Escriben en la tabla de **nombres** con
WRTVRM, un tile por byte, pasándolo por una máscara que decide si se dibuja o
se borra:

    0xFF   fin
    0xFE   encadena, igual que el 0x80 del otro
    resto  el byte es un tile

Y toda lista empieza por su dirección, porque 0x449E —la puerta normal— solo
pone la máscara y **cae dentro** de 0x44A0, que es el cuerpo del comando 0xFE:
lo primero que hace es leerse dos bytes. La única entrada que se salta eso es
0x449A.

## El alfabeto

No es ASCII. La A es el tile **0x21** y de ahí seguidas hasta la Z en 0x3A; los
dígitos van del 0x10 al 0x19, el espacio es el 0x20 —y el 0x00, el tile vacío,
hace el mismo papel— y el círculo del copyright es el 0x1A.

No hace falta suponerlo: KONAMI, PERFECT y GAME OVER se leen solas con ese
reparto y ninguna otra alineación las da.

## Las quince tablas de despacho

El cartucho despacha de dos maneras. La primera, 0x4071, tiene **la tabla
escrita detrás del propio `call`**: `pop hl` la coge de la pila, A por dos entra
en ella, y el puntero que salga se ejecuta con `jp (hl)`. Como el retorno se ha
sacado de la pila, eso no vuelve.

La segunda, 0x7375, indexa una tabla de tablas por el oponente y despacha la que
salga.

Sin declarar las quince, el trazado estático se queda muy corto: solo las seis
del reparto por oponente esconden **315 bytes de código**.

## Las dos compilaciones

**Hay dos cartuchos distintos de Yie Ar Kung-Fu**, y no se juegan igual. Esto
es lo que lleva cada uno:

|  | fácil | difícil |
|---|---|---|
| sha256 | `644c78c7…` | `61c86ad4…` |
| cada cuánto reacciona el oponente | siempre **1 cuadro de cada 32** | **1 de cada 32, 16 u 8**, según el nivel |
| el arma larga de CHEN | dura 18 cuadros y crece hasta 8 | dura 22 y crece hasta 10 |
| los tres umbrales de altura | tres `cp` en línea | una tabla de tres bytes, con un valor cambiado |
| la marca oculta de Konami | **no la lleva** | **la lleva**: RC-725 y el título en katakana |
| este repositorio | **es el que está desensamblado** | cotejada instrucción a instrucción |

En el nivel más alto, el oponente del cartucho difícil reacciona **cuatro veces
más a menudo** que el del fácil, y en el fácil eso no pasa en ningún nivel. Lo
demás son cinco constantes y un cambio de forma.

Byte a byte las dos difieren en 15.618 de 16.384, el 95,3 %. Esa cifra no vale
nada: las dos están relocalizadas. Por instrucción comparten el **97,0 %**. El
detalle de cada diferencia está en [Hallazgos](HALLAZGOS.html), y lo produce
`tools/coteja_builds.py`.

