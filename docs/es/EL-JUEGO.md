# El juego

Yie Ar Kung-Fu es un juego de pelea de uno contra uno: **LEE** contra una fila
de adversarios, cada uno con su arma y su manera de moverse. Todo lo que sigue
sale de leer el cartucho, no de jugar.

## Los cinco oponentes

Sus nombres están en 0x6C35, cuatro tiles cada uno, alineados a la derecha con
tiles vacíos:

| índice de 0xE054 | nombre | figura | tiles |
|---|---|---|---|
| 0 | WANG | guiones 0x5EEB y 0x6172 | 57 |
| 1 | " TAO" | 0x624B y 0x6421 | 67 |
| 2 | CHEN | 0x64BD y 0x669B | 68 |
| 3 | LANG | 0x6724 y 0x68A2 | 52 |
| 4 | "  WU" | 0x68FF y 0x6A9C | 62 |

Cada uno trae **su propio guion de patrón y su propio guion de color**, y esa
es toda la diferencia entre uno y otro en pantalla: el templo del fondo es el
mismo para los cinco.

## Lo que puede hacer el jugador

La máquina de estados de 0x4D24 acepta el movimiento que traigan los mandos y
lo despacha por una tabla de treinta y dos entradas. Los movimientos que se
distinguen en el código:

- **Andar**, dos píxeles por cuadro, con la posición en 0xE161 entre 0x23 y
  0xE0, y dos poses que se alternan cada ocho cuadros.
- **Saltar**, con la curva de 0x4DE1 sumándose a la altura: seis cuadros de −4,
  cuatro de −3, dos de −2, uno de −1 y luego los positivos. Sube deprisa, se
  para arriba y baja.
- **Tres golpes de pie**, cada uno con su pose y su número. El número indexa la
  tabla de puntos de 0x4B23: **cien** el primero y **trescientos** el segundo y
  el tercero.
- **El barrido**, que es el golpe 4.
- **El golpe en el aire**, el 5: hay que soltar el disparo y volver a pulsarlo
  pasado el cuadro 0x0B del salto. Lo comprueba 0x4E69, con tres condiciones
  encadenadas.

## Los puntos

La puntuación se lleva en **BCD**, así que los valores se leen tal cual en el
código:

| por | cuánto | dónde |
|---|---|---|
| golpe 1 | 100 | tabla de 0x4B23 |
| golpes 2 y 3 | 300 | " |
| golpes 4 y 5 | 500 | " |
| cada unidad del reloj al acabar | 200 | 0x488E |
| **PERFECT** en la fila 16 | **3000** | 0x47C9 |
| **PERFECT** en la fila 4 | **5000** | 0x48BD |
| cada objeto de la fase de bonus | 100 | 0x7BA3 |

El PERFECT de 3000 lo da acabar el asalto sin recibir un golpe. El de 5000 pide
además que el reloj esté en su tope, 0x24.

## La fase de bonus

Con 0xE058 puesto no hay oponente: el cuadro se va a 0x79B7, que suelta objetos
por los tres huecos de 0xE250 y cuenta los que se derriban en 0xE275, la cifra
que se dibuja al lado del **NUMBER OF HITS** de 0x7BBB.

Qué objeto sale lo dice la tabla de 0x7A7C, leída **nibble a nibble**: los dos
bits bajos eligen hueco y patrón, el bit 2 la altura y el signo de la
velocidad, y el bit 3 entre dos velocidades. La X se lleva con dos bytes y la
velocidad se le suma con `add` y `adc`, o sea con dieciséis bits: el byte de
abajo son los decimales, y así el objeto puede ir más despacio que un píxel por
cuadro sin que se note el escalón.

## Cómo decide el oponente

No se mueve al azar del todo. 0x5476 mide la separación con el jugador y 0x5488
la compara, primero contra los tres bytes que la tabla de 0x54B8 da para ese
oponente y luego contra tres topes fijos —0x40, 0x48 y 0x68—, o sea **siete
tramos**. El tramo elige la lista, y de la lista sale el movimiento.

Lo que hay de azar lo pone 0x6D2C: un registro de desplazamiento de diez bytes
con semilla fija, que devuelve un número de 0 a 3. Cada oponente tiene cinco
rutinas de carácter que reparten esos cuatro valores entre cuatro movimientos
distintos.

## El texto que lleva dentro

Con el alfabeto del cartucho —la A es el tile 0x21, los dígitos el 0x10 y el
espacio el 0x20— se lee todo lo que escribe:

    HI SCORE   SCORE   STAGE   REST        el marcador
    PLAY START                             la escena 3, parpadeando
    PUSH SPACE KEY   (C)KONAMI 1985        la portada
    GAME  OVER                             al acabarse la partida
    VIDEO CARTRIDGE                        la escena 0
    PERFECT 3000 / PERFECT 5000            los dos premios
    NUMBER OF HITS                         la fase de bonus
    STAGE   BONUS STAGE                    los rótulos de fase
    WANG   TAO   CHEN   LANG   WU          los oponentes
