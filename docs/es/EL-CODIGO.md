# El código

## Todo pasa dentro de la interrupción

INIT (0x4010) engancha el manejador a mano: pone un `0xC3` —o sea un `jp`— en
H.KEYI (0xFD9A) y la dirección 0x4043 detrás, deja la pila en 0xE400, borra
0xE000–0xE3FF con un `ldir`, carga los gráficos y se planta en un salto a sí
mismo. A partir de ahí **el juego entero corre dentro de la interrupción**.

El manejador de 0x4043 lee el estado del VDP, le da un cuadro al motor de
sonido, y con el candado de 0xE006 abierto lee los mandos y hace el cuadro de
juego. Al salir vuelve a mirar el estado: si hay otra interrupción pendiente,
le da otro cuadro al sonido.

## El reparto por escenas

0xE000 es la **escena** —de 0 a 8, la tabla de 0x409F— y 0xE001 el **paso**
dentro de ella. Cada escena empieza con una cadena de `djnz`, que es la manera
más corta de escribir un `switch`: B entra valiendo el paso, y cada `djnz` lo
baja uno y salta si todavía no ha llegado a cero.

La escena 0 es la portada: el paso 0 monta la pantalla entera, el 1 dibuja el
VIDEO CARTRIDGE, el 2 lo borra y el 3 pinta el logotipo y el PUSH SPACE KEY.

## Los mandos

Se leen el joystick y el teclado por separado y se juntan con un `or`, así que
da igual con qué se juegue. La clave es que los dos acaban en la misma
disposición de bits, la del puerto A del PSG:

    bit 0  arriba        bit 3  derecha
    bit 1  abajo         bit 4  disparo A
    bit 2  izquierda     bit 5  disparo B

Para llegar ahí desde el teclado hacen falta **cinco rotaciones encadenadas**,
que es lo que hace 0x453F. Que las cinco cuadran no es una suposición: con el
reparto normal de la matriz del MSX —fila 8 con SPACE en el bit 0, LEFT en el 4,
UP en el 5, DOWN en el 6 y RIGHT en el 7— cada `and` cae exactamente en su
sitio.

Con el bit 6 de 0xE002 a cero no hay nadie jugando y 0x4564 se inventa los
mandos: es como corre la secuencia de atracción, avanzando por la lista de
0x55DE una posición cada 0x20 cuadros.

## Cómo se monta el jugador

El jugador es **de sprites**. 0x4FBE reparte los seis patrones de 0x50A6 por el
campo de patrón de los seis primeros sprites —de dos en dos, para no tocar
coordenadas ni color— y luego ejecuta la receta que 0xE154 elija en la tabla de
0x50AC.

Una receta es una tira de campos con el **nibble alto por marca**:

| marca | qué hace |
|---|---|
| 0x7- | el nibble bajo va a 0xE174, el mapa de bits que consultan los golpes |
| 0x8- | el nibble bajo va a 0xE172, la pose con la que se comprueba el golpe; y en medio del bucle, cierra la lista |
| 0xF- | el nibble bajo sirve para calcular la X del golpe, 0xE171 |
| resto | bytes de sprite: el primero se suma a la Y y el segundo a la X |

Y hay **dos cuerpos**, no uno. Mirando a la derecha se usa 0x5064, que suma
directamente. Mirando a la izquierda, 0x5021 se lee del propio dato un puntero
a otra receta y ejecuta 0x5028, que además **espeja** la segunda coordenada con
`ld a,010h / add a,(hl) / neg / add a,b`.

## Cómo se monta el oponente

El oponente es **de tiles**. 0x5374 escribe números de tile en la tabla de
nombres: baja hasta la fila que diga 0xE182, coloca la columna con 0xE183 y
copia el bloque fila a fila con LDIRVM.

Lo que tiene de particular son las cuentas de 0x5387 a 0x53C1, que **recortan**:
si la figura se sale por la izquierda o por la derecha de las treinta y dos
columnas, se acorta la anchura y se corre el origen, en vez de dibujar encima
de la fila siguiente.

Y las poses vienen comprimidas. 0x541D las descomprime a 0xE280 con tres
comandos —`0xF-` para tiles correlativos, `0xE-` para huecos y cualquier otro
byte para un tile suelto— y, si la pose es impar, 0x5454 vuelve a escribirlas
al revés en 0xE2D0 cambiando cada tile por su gemelo.

## Las cajas de golpe

0x52F5 coge de la receta del oponente cuatro bytes, les suma la X de 0xE16E y
con cada uno escribe una **pareja** en 0xE198: el valor y el valor más 10, más
8, más 6 y más 6. Son cuatro tramos horizontales, cada uno con su principio y
su final, de mayor a menor anchura.

Y 0x4A0F es quien los usa: coge la X del golpe en 0xE171 y mira si cae dentro
de uno. Antes hay tres cortes —el bit de 0xE173 que toca a la pose, que la pose
del oponente no sea de 0x0E para arriba, y que la Y del jugador haya llegado a
0x72—.

La altura del golpe la lleva aparte la tabla de 0x4B54: tres valores, 0x84, 0x91
y 0x9F, o sea alto, medio y bajo.

## El motor de sonido

Tres voces, con la tabla de canales en RAM y **ocho bytes por canal**. Hay dos
zonas: 0xE01A para la música y 0xE032 para los efectos, y el número de melodía
decide en cuál va —por debajo de 8 es efecto, de 8 para arriba música, y de 0x0C
para arriba se usan tres canales en vez de dos—.

Los seis bits bajos del número son el índice de la tabla de punteros de 0x7DB6,
que tiene veintiuna entradas. La primera no apunta a ninguna parte, así que el
reparto útil va de la 1 a la 20, y esas veinte van a **dieciséis melodías
distintas**: varias comparten la de 0x7FEF, que es un solo 0xFF, o sea la
melodía que no suena.

Hay dos formatos de melodía. El corto trae duración, envolvente y notas. El
largo, que se usa cuando el bit 7 del número está puesto, añade la unidad de
duración, el decaimiento, la **octava** y el medio tono.

**Las notas.** La tabla de 0x7DAC tiene diez valores: 106, 100, 95, 89, 84, 80,
75, 71, 67 y 63. La razón entre cada uno y el siguiente es 1,06, que es justo la
del semitono (2 elevado a 1/12 = 1,0595): son **diez semitonos seguidos**. Y son
un **divisor** del PSG, no una velocidad ni una frecuencia: cuanto más bajo, más
aguda la nota. La octava se aplica duplicando el divisor, que es bajar una
octava cada vez.

**La prioridad.** Cuando se entra por 0x7BCC con D a cero —que es como entra
todo el juego— la melodía se toca sin más. Pero desde dentro del propio motor se
entra con D = 1, y entonces 0x7BF3 compara con la que ya suena en ese canal y
**no la pisa** si la de ahora es igual o más alta.
