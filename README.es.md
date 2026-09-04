# Yie Ar Kung-Fu (Konami, RC-725) — desensamblado comentado

Desensamblado comentado del cartucho MSX de 16 KB, reproducible byte a byte.

**[Leer el trabajo →](https://antxiko.github.io/YieArKungFu-disassembly/es/)**
· [In English](README.md)

    make            # traza, monta el listado, lo reensambla y pasa los tests
    make verify     # la prueba que decide: reensamblar tiene que devolver la ROM
    make sanity     # que no quede un byte sin explicar
    make densidad   # cuánto está comentado, rutina por rutina
    make web        # rehace el sitio

La ROM **no se distribuye aquí**. Pon tu propio volcado en la raíz como
`yiear.rom`, 16384 bytes, sha256

    644c78c7d20bb30802888b513b384cf0ce4f9d8b6fd490f30e6211ac92274848

`make comprueba` lo verifica.

De este cartucho circulan **dos volcados**. El listado es el de la versión
*easy*, la del sha de arriba; si tienes también la *hard*, ponla como
`yiear_hard.rom` y `tools/coteja_builds.py` las compara.

## Cómo está

| | |
|---|---|
| reensambla byte a byte | sí |
| bytes explicados | 16.384 de 16.384 (100 %) |
| código trazado | 7.494 bytes |
| datos identificados | 8.890 bytes en 253 rangos con nombre |
| comentado | 1707 comentarios de línea, 44,0 % |
| rutinas por debajo del 10 % | 0 de 568 |

Las anotaciones viven aparte del listado, ancladas a la dirección que
describen, así que sobreviven a un retrazado. Lo que hay en el `.notes`:

| | |
|---|---|
| etiquetas con nombre | 569 |
| comentarios anclados | 1707 |
| rangos de datos con explicación | 253 |

Y las imágenes del sitio no son capturas: las pinta Python ejecutando los mismos
intérpretes que corre el Z80, y están comprobadas contra la VRAM de openMSX con
**cero diferencias en la tabla de color y cero en la de patrón**, 12.288 bytes.

## Qué hay aquí

- `src/yiear.asm` — el listado; generado, no escrito a mano
- `src/yiear.notes` — las anotaciones, ancladas a direcciones
- `src/yiear.entries` — los puntos de entrada y las quince tablas de despacho,
  cada uno justificado
- `docs/` — el sitio, en inglés y castellano
- `tools/` — el trazador, el montador del listado, los dos intérpretes de
  pantalla que dibujan las imágenes desde la ROM, y el cotejador de las dos
  compilaciones

## El trabajo

| | |
|---|---|
| [Empezar](docs/es/EMPEZAR.md) | qué hace falta y qué hace cada orden |
| [El juego](docs/es/EL-JUEGO.md) | los cinco oponentes, los cinco golpes y lo que vale cada uno |
| [El cartucho](docs/es/EL-CARTUCHO.md) | la cabecera, los dos intérpretes de dibujo y el alfabeto que no es ASCII |
| [El código](docs/es/EL-CODIGO.md) | todo dentro de la interrupción, las recetas de pose y el motor de sonido |
| [Hallazgos](docs/es/HALLAZGOS.md) | las dos compilaciones cotejadas, la prueba del 0x78 y el salto a media instrucción |
| [En el emulador](docs/es/EN-EL-EMULADOR.md) | cómo se comprueban los dibujos contra la VRAM de verdad |
| [Preguntas abiertas](docs/es/PREGUNTAS-ABIERTAS.md) | lo que no está resuelto |

## Lo que más llama la atención

- Las **dos compilaciones** difieren en el 95,3 % de los bytes y comparten el
  **97,0 % de las instrucciones**. Lo que cambia de verdad son cinco constantes
  y dos máscaras que la versión difícil hace **depender del nivel**: en el más
  alto el oponente reacciona cuatro veces más a menudo.
- **Solo la versión difícil lleva la marca oculta de Konami** —el RC-725 y el
  título en katakana que descubrió Manuel Pazos—. La fácil tiene ahí el título
  en ASCII latino, que no lee nadie.
- El **fondo del templo** no está en la tabla de patrones: lo escribe como tiles
  un guion en la tabla de **nombres**, el único guion largo del cartucho que
  hace eso.
- El jugador se dibuja con **sprites** y el oponente con **tiles**, y por eso el
  cartucho se guarda cada tile del oponente dos veces, en su sitio y **0x78 más
  allá** reflejado.
- Un `jr z` que aterriza **dentro de otra instrucción** y ejecuta el byte alto
  de una dirección como si fuera un `ld b,(hl)`, para ahorrarse dos bytes.

## Licencia

Las herramientas, los comentarios y la documentación, [MIT](LICENSE). El juego
no: su código, sus gráficos y sus sonidos siguen siendo de sus autores y de
Konami. Lee el [aviso legal](AVISO-LEGAL.md).
