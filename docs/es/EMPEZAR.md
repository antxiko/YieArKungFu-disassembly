# Empezar

Desensamblado comentado de **Yie Ar Kung-Fu**, el RC-725 de Konami para MSX,
un cartucho de 16 KB en la página 1 (0x4000–0x7FFF). Vuelve a ensamblar dando
la ROM exacta, byte a byte, y sus 16.384 bytes están todos explicados.

## El cartucho no está aquí

Ningún repositorio distribuye el juego. Pon tu propio volcado en la raíz como
`yiear.rom`, 16384 bytes, sha256

    644c78c7d20bb30802888b513b384cf0ce4f9d8b6fd490f30e6211ac92274848

`make comprueba` lo verifica.

De este cartucho circulan **dos volcados**, que los archivos llaman *easy* y
*hard*. El listado es el de la versión fácil, la de arriba. Si tienes también
la otra, ponla como `yiear_hard.rom` y `tools/coteja_builds.py` las compara;
el resultado está en [Hallazgos](HALLAZGOS.html).

## Qué hace cada orden

    make            traza el flujo, monta el listado, lo reensambla y pasa los tests
    make verify     la prueba que decide: reensamblar tiene que devolver la ROM
    make sanity     que no quede un byte sin explicar, y que ningún dato salga como código
    make densidad   cuánto está comentado, rutina por rutina
    make imagenes   dibuja los bloques de datos gráficos, para mirarlos
    make web        rehace este sitio desde la ROM y las notas

## Cómo está montado

El listado no se edita a mano: `tools/mkasm.py` lo genera a partir de un trazado
del flujo y de un fichero de notas ancladas a direcciones, así que los
comentarios sobreviven a un retrazado. El trazador sigue el flujo desde los
puntos de entrada; los que no puede deducir solo —el gancho de la interrupción
y las quince tablas de despacho— están declarados en `src/yiear.entries`, cada
uno con su justificación.

Las imágenes de la portada no son capturas. Las dibuja `tools/pantallas.py`
ejecutando en Python los pasos del propio cartucho: el intérprete de guiones de
0x442C, el de listas de tiles de 0x44A6, los rellenos y el espejo de 0x4C46. Y
no se dan por buenas: `tools/omsx_vram.tcl` vuelca la VRAM de openMSX durante
una partida y se compara byte a byte. La tabla de color sale con **cero
diferencias de 6.144 bytes** y la de patrón con **cero de 6.144**.

## Las herramientas

    tools/z80trace.py        el trazado del flujo, con las tablas declaradas
    tools/mkasm.py           el listado, desde el trazado y las notas
    tools/guiones.py         el intérprete de guiones de 0x442C, en Python
    tools/textos.py          el alfabeto de tiles y el intérprete de listas
    tools/pantallas.py       las pantallas, montadas paso a paso
    tools/cierra_datos.py    dónde acaba cada bloque, ejecutando su intérprete
    tools/apunta_a.py        quién apunta a un rango, buscando en los 16 KB
    tools/coteja_builds.py   las dos compilaciones, cotejadas por instrucción
    tools/presupuesto.py     el reparto de los 16.384 bytes
    tools/densidad.py        cuánto está comentado, rutina por rutina
