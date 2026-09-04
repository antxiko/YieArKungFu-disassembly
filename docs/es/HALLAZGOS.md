# Hallazgos

Todo lo que sigue está medido sobre el binario. Donde hay una cifra, hay una
herramienta del repositorio que la saca.

## Las dos compilaciones son el mismo programa

Byte a byte, la versión fácil y la difícil difieren en **15.618 de 16.384
bytes**, el 95,3 %. Esa cifra no vale para nada: las dos están **relocalizadas**,
y un byte de más en un sitio desplaza todo lo que va detrás y con ello todas las
direcciones absolutas.

`tools/coteja_builds.py` las recorre instrucción a instrucción con la tabla de
longitudes del Z80 y sustituye por un comodín todo operando de 16 bits que caiga
dentro del cartucho —que es exactamente lo que la relocalización mueve—. Así
comparten **3.798 de las 3.917** instrucciones de la fácil, el **97,0 %**.

Las constantes que **no** se enmascaran son las que confirman el resultado: una
dirección de RAM como 0xE000 o un valor como 0x0080 no se desplazan, y siguen
coincidiendo.

## Lo que cambia de verdad: la máscara fija se vuelve variable

La versión fácil deja pasar un cuadro de cada 64 y uno de cada 32 con máscaras
escritas dentro del código:

    0x74b6   ld a,(0e003h) / and 03fh / ret nz
    0x77df   ld hl,0e003h / ld a,(hl) / and 03eh / ret nz

En la versión difícil, en esos dos sitios exactos, van delante estas ocho
instrucciones, que en la fácil **no aparecen ni una sola vez** —buscado sobre
los 16.384 bytes—:

    ld b,03eh
    ld a,(0e056h)
    and a
    jr z,+7
    ld b,01eh
    dec a
    jr z,+2
    ld b,00eh

y el `and 03fh` pasa a ser `and b`. La máscara ya no es fija: la elige 0xE056,
el nivel. Con 0x3E la condición se cumple una vez cada 32 cuadros, con 0x1E una
cada 16 y con 0x0E una cada 8. En el nivel más alto el oponente reacciona
**cuatro veces más a menudo**, y en la versión fácil eso no pasa nunca.

Lo demás son **cinco constantes**, todas del arma larga del tercer oponente:

    0x70e3   ld a,012h  ->  ld a,016h    la duración, de 18 a 22 cuadros
    0x7104   cp 008h    ->  cp 00ah      crece hasta 10 en vez de hasta 8
    0x7109   cp 007h    ->  cp 009h      y el tope de la otra rama, igual
    0x77ec   bit 6,a    ->  bit 7,a      otro bit del dato
    0x77ee   ld a,001h  ->  ld a,000h    y el valor, al revés

Y un cambio de forma: los tres umbrales de altura de 0x4AAF, que en la fácil son
tres `cp` incrustados —0x86, 0x7C, 0x73—, en la difícil salen a una tabla de
tres bytes, `72 7C 86`, con el primero cambiado de 0x73 a 0x72.

## Solo una de las dos lleva la marca oculta de Konami

Konami escondía su número de catálogo y el título en katakana al final de muchos
cartuchos; lo descubrió **Manuel Pazos**
([@ManuelPazosMSX](https://twitter.com/ManuelPazosMSX)).

`tools/busca_marca_konami.py` la rastrea por toda la ROM, no solo en el sitio de
siempre. La versión **difícil la lleva**: **RC-725** y el título en katakana,
diez bytes que cierran en 0x7FFF.

La versión **fácil no**. En ese mismo hueco, los últimos dieciséis bytes son

    59 49 45 20 41 52 20 4B 55 4E 47 20 46 55 FF FF        YIE AR KUNG FU

en **ASCII latino**, y no lo lee nadie: el cartucho no sabe leer ASCII, porque su
alfabeto empieza la A en el tile 0x21.

Lo que eso quiera decir sobre cuál salió antes o de dónde salió cada una **no lo
dice el binario**, y aquí no se supone.

## El fondo del templo está en la tabla de nombres

De los catorce guiones largos del cartucho, **uno solo escribe en 0x3800**: el
de 0x5DA4. Y lo que pone ahí, en 327 bytes, es el templo entero —las columnas,
las linternas, el cartel de los dos kanjis, el gong, las ventanas y el suelo de
ladrillo—.

Es el único guion largo que no va ni a patrones ni a color. Los otros trece
llenan la tabla de patrones y la de color con los tiles que este usa.

## Las tablas que parecían cinco escenarios son los cinco oponentes

Las tablas de 0x4B9C y 0x4BA6 dan un guion de patrón y otro de color por cada
valor de 0xE054, y se dibujan al montar la pantalla, así que parecen cinco
fondos distintos. No lo son, y hay tres medidas que lo dicen:

1. Montando la pantalla con los cinco y comparándolas cambian unos **4.000 bytes
   de VRAM**, pero **ninguno de los tiles que cambian está en uso** en la tabla
   de nombres del fondo. El templo se ve idéntico con los cinco.
2. Se dibujan en la VRAM 0x2880, que son los tiles 0x10 a 0x48 del **segundo y
   tercer tercio**, o sea la mitad de abajo de la pantalla, y encima de la
   fuente, que ahí ya no hace falta porque el marcador está arriba del todo.
3. Y sobre todo: 0x4C3E copia esos mismos tiles **reflejados** a los 0x88 en
   adelante, que son justo los que la tabla de nombres usa para pintar al
   oponente. Un fondo no necesita versión en espejo; un luchador que puede mirar
   a los dos lados, sí.

## La prueba del 0x78

El MSX no sabe reflejar ni un sprite ni un tile, así que un luchador que mira a
los dos lados necesita las dos versiones guardadas.

0x4C3E copia los tiles del oponente de la VRAM 0x2880 a la 0x2440 dando la
vuelta a cada byte: del tile **0x10** al **0x88**, o sea **0x78 más allá**.

Y el descompresor de poses, cuando le toca espejar un bloque (0x5454), cambia
cada tile por su gemelo **sumándole 0x78** —y restándoselo a los de 0x88 para
arriba—. Las dos mitades del mismo truco, a 10 KB de distancia una de otra.

Un detalle del bucle que costó un render mal antes de comparar con la VRAM: en
0x4C46 **el origen no avanza**, solo el destino. Los tres tercios se llenan con
la misma copia reflejada de 0x2880.

## El mismo rótulo de doce bytes, dos premios distintos

La lista de 0x47CC dice **PERFECT 3000** y se dibuja en la fila 16 columna 10
por la puerta normal, 0x449E, que se lee sus dos primeros bytes como dirección
de VRAM.

Pero 0x48AD entra por 0x449A, que **no lee dirección**, con DE en 0x47CE —dos
bytes más allá, saltándose justamente esa dirección— y HL en la VRAM 0x388A, la
fila 4. Y acto seguido 0x48B2 escribe el tile **0x15**, que es el dígito 5, en la
VRAM 0x3892, que es la novena letra: donde ponía un 3 pone un 5.

El rótulo pasa a decir **PERFECT 5000**, y lo que se suma son 0x5000 en BCD.
Doce bytes de texto para dos premios.

## Cada figura del luchador lleva su destino delante

Los trece guiones de 0x596F a 0x5D02 van pegados, sin un solo byte muerto entre
ellos, pero la tabla de 0x4CF0 no apunta al principio de cada uno: apunta **dos
bytes más allá**. Esos dos bytes son una dirección de VRAM, y en los trece cae
en 0x1820–0x18A0.

No es un descuadre: el cartucho dibuja estos mismos guiones por dos caminos.

- El bucle de 0x4CA4 entra por 0x4452, que quiere el destino en HL y se lo da la
  tabla de 0x4D0A. Por eso empieza a leer pasados los dos bytes.
- El bucle de 0x5098 entra por 0x4423, que es el cuerpo del comando 0x80: **lee
  el destino del propio guion**. Por eso empieza dos bytes antes.

Lo demuestra una cuenta: **veinticuatro** de las palabras del bloque de recetas
0x50A6–0x5254 valen exactamente una de esas trece direcciones menos dos, y
**ninguna** vale una de las trece de la tabla.

## Una entrada de más metía 178 bytes de basura en el listado

La regla para saber cuántas entradas tiene una tabla de punteros —leer palabras
mientras caigan dentro del cartucho— da **seis** para la de 0x6B4B. Son
**cinco**: la sexta, 0x583A, cae dentro del guion que 0x43F6 dibuja, y seguirla
como código llenaba el listado de `rst 18h` y `sbc a,a`.

Cinco es lo que dice el índice: 0x6B42 lee 0xE054, el oponente, y de esos hay
cinco. Y la prueba de que la tabla acaba en 0x6B55 es que **0x4182 hace `call
0x6b55`** y 0x42E6 un `jp 0x6b55`: ahí empieza código al que se llama por su
nombre.

## Un salto que aterriza dentro de otra instrucción

El `jr z` de 0x4625 tiene los bytes `28 08`, o sea desplazamiento 8, y salta a
**0x462F**. Y 0x462F no es el principio de ninguna instrucción: es el **tercer
byte** del `jp 0x46cf` que empieza en 0x462D.

    462d  C3 CF 46     jp 0x46cf
    4630  CD 05 6B     call 0x6b05

Cayendo en 0x462F, el Z80 se encuentra el byte **0x46** suelto y lo ejecuta como
lo que es: `ld b,(hl)`, una instrucción de un byte que solo carga B. Y acto
seguido cae en el `call` de 0x4630, que es a donde se quería ir. El byte alto de
una dirección haciendo de instrucción de paso, y dos bytes ahorrados.

Que es así y no un fallo del trazado lo dice el desplazamiento: es **0x08 y no
0x09**, que es lo que haría falta para caer en 0x4630 limpiamente.

## El azar es un registro de diez bytes con semilla fija

0x6D2C corre un registro de desplazamiento de **diez bytes**, de 0xE135 a
0xE13E: saca el bit por arriba de 0xE13E con `srl`, lo arrastra por los nueve de
abajo con `rr` y lo vuelve a meter por arriba, dos veces por llamada. Devuelve
los dos bits bajos, un número de 0 a 3.

La semilla son los diez bytes que 0x5295 copia al empezar el asalto, y hay
**cuatro juegos** distintos en 0x52CD elegidos por 0xE056. Con eso el oponente no
se repite pero tampoco depende de nada de fuera: la partida sale igual jugada
igual, que es justo lo que hace falta para poder comprobarla.

## Tres trozos de código que no alcanza nadie

Veintiséis bytes en 0x73B3, tres en 0x73DF y ocho en 0x74AE decodifican como
código Z80 coherente —el primero es `call 0x7399 / ld hl,0e003h / ld
a,(0e165h)…`—. No los alcanza nadie, y no es una impresión: `tools/apunta_a.py`
busca la palabra de 16 bits en **los 16.384 bytes** del cartucho, no solo en el
listado, y ninguna dirección cae dentro.

Delante de los tres hay un salto que pasa por encima. El de 0x73B1 es un `jr` de
0x48 que se planta en 0x73FB, saltándose los veintiséis bytes de golpe.

## Dos comentarios heredados que el binario contradecía

Comentar destapa errores ya escritos. Dos que salieron en esta pasada:

- `copia_256_a_vram` **no copia 256 bytes**. Lo que hace 0x441D es poner a cero
  el byte **alto** de la cuenta y dejar el bajo como venga, así que copia los C
  bytes que traiga quien llama. Serían 256 solo si C entrase valiendo cero, y el
  único que entra por ahí trae en C la anchura de la fila que está dibujando.
- **0xE160 es la coordenada Y**, no una distancia. Lo dice que 0x5064 la sume al
  **primer** byte de cada sprite, que en el TMS9918 es la Y. Encaja además con
  que la curva del salto se le sume y con que su valor de reposo sea 0x87, o sea
  135, la línea del suelo.
