#!/usr/bin/env python3
"""Genera la portada de la web de Yie Ar Kung-Fu, en los dos idiomas.

El diseno es el compartido por la serie (tools/estilo_web.py) y la pagina sale
autocontenida, con las imagenes embebidas como data URI.

Las imagenes NO son ilustraciones ni capturas: las dibuja tools/pantallas.py a
partir de los propios bytes de la ROM, ejecutando en Python los mismos
interpretes que corre el Z80, y estan comprobadas byte a byte contra la VRAM
de openMSX. Ninguna se ha retocado.

Uso: make_web.py <docs/imagenes> <salida.html> <idioma>
"""
import base64
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from estilo_web import ESTILO                                   # noqa: E402

# La tabla que compara las dos compilaciones, que no estaba en el estilo comun
ESTILO_DOS = (
    "table.dos{width:100%;border-collapse:collapse;margin:1.2em 0}"
    "table.dos th,table.dos td{border:1px solid rgba(255,255,255,.18);"
    "padding:.45em .7em;text-align:left;font-size:.95em;vertical-align:top}"
    "table.dos th{color:var(--oro)}"
    "table.dos td:first-child{opacity:.75}"
)

# Las cifras salen de contar sobre el listado generado, no de escribirlas a
# ojo: 16384 = 7494 + 8890, que es lo que imprime tools/presupuesto.py (make
# sanity). RUTINAS son las etiquetas con nombre propio, las que cuenta el
# .notes con su directiva L. La densidad la da tools/densidad.py.
CODIGO = 7494
DATOS = 8890
RUTINAS = 569
INSTRUCCIONES = 3917
COMPARTIDAS = 3798
DENSIDAD = "44,0"
DENSIDAD_EN = "44.0"


def mil(n, idioma):
    return f"{n:,}".replace(",", "." if idioma == "es" else ",")


TXT = {
    "es": dict(
        titulo="Yie Ar Kung-Fu - desensamblado comentado",
        aviso="<b>Aqui no hay ninguna captura.</b> Todas las imagenes estan "
              "<b>dibujadas desde los bytes de la ROM</b>, ejecutando en Python "
              "los mismos interpretes que corre el Z80, y comprobadas contra la "
              "VRAM del emulador: <b>cero diferencias en las tablas de color y "
              "de patron</b>, 12.288 bytes. El listado y las cifras se "
              "reproducen con <code>make</code>.",
        h_builds='LAS DOS COMPILACIONES',
        builds='<p>De Yie Ar Kung-Fu hay <b>dos cartuchos distintos</b> circulando, y no es un rumor: aqui estan los dos, y <code>tools/coteja_builds.py</code> los compara instruccion a instruccion. Son <b>el mismo programa</b> -comparten el 97,0 % de las instrucciones- pero no se juegan igual.</p><table class="dos"><tr><th></th><th>FACIL</th><th>DIFICIL</th></tr><tr><td>sha256</td><td><code>644c78c7...</code></td><td><code>61c86ad4...</code></td></tr><tr><td>cada cuanto reacciona el oponente</td><td>siempre <b>1 cuadro de cada 32</b></td><td><b>1 de cada 32, 16 u 8</b> segun el nivel</td></tr><tr><td>el arma larga de CHEN</td><td>dura 18 cuadros y crece hasta 8</td><td>dura 22 y crece hasta 10</td></tr><tr><td>la marca oculta de Konami</td><td>NO la lleva</td><td><b>SI</b>: RC-725 y el titulo en katakana</td></tr><tr><td>el listado de este repositorio</td><td><b>este</b></td><td>solo cotejada</td></tr></table><p>O sea: en el cartucho dificil, al nivel mas alto el oponente reacciona <b>cuatro veces mas a menudo</b> que en el facil, y eso en el facil no pasa nunca. Lo demas son cinco constantes del arma de CHEN y un cambio de forma en tres umbrales de altura.</p>',
        claim="El fondo del templo escrito como TILES por un guion, el "
              "oponente dibujado con tiles y el jugador con sprites, y las dos "
              "compilaciones del cartucho cotejadas instruccion a instruccion.",
        ficha=["Konami - <b>(c) Konami 1985</b>",
               "Cartucho <b>RC-725</b>, 16 KB",
               "MSX1 - <b>pagina 1</b>", "Volcado <b>644c78c7...</b>"],
        nav=[("#builds", "Las dos versiones"),
             ("#numbers", "Las cifras"), ("#findings", "Hallazgos"),
             ("#screens", "Lo que dibuja")],
        docnav=[("EMPEZAR.html", "Empezar"), ("EL-JUEGO.html", "El juego"),
                ("EL-CARTUCHO.html", "El cartucho"),
                ("EL-CODIGO.html", "El codigo"),
                ("LA-MUSICA.html", "La música"), ("HALLAZGOS.html", "Hallazgos"),
                ("EN-EL-EMULADOR.html", "En el emulador"),
                ("PREGUNTAS-ABIERTAS.html", "Preguntas abiertas")],
        otro=("../", "In English"),
        h_num="El cartucho en cifras", h_find="Lo que aparecio al desmontarlo",
        h_scr="Lo que el cartucho dibuja",
        cifras=[("100 %", "del binario explicado"),
                (str(RUTINAS), "rutinas con nombre"),
                (DENSIDAD + " %", "del listado comentado"),
                (mil(CODIGO, "es"), "bytes de codigo"),
                (mil(DATOS, "es"), "bytes de datos"),
                ("0", "bytes sin identificar")],
        nota_scr="Debajo de cada imagen esta de donde sale y que se esta "
                 "viendo.",
        pie_leg="Esto es trabajo de documentacion y preservacion: el codigo y "
                "los graficos siguen siendo de sus autores y de Konami, y la "
                "imagen del cartucho no se distribuye.",
    ),
    "en": dict(
        titulo="Yie Ar Kung-Fu - a commented disassembly",
        aviso="<b>Not one capture here.</b> Every picture is <b>drawn from "
              "the bytes of the ROM</b>, by running in Python the same "
              "interpreters the Z80 runs, and checked against the emulator's "
              "VRAM: <b>zero differences across the colour and pattern "
              "tables</b>, 12,288 bytes. The listing and the numbers are "
              "reproducible with <code>make</code>.",
        h_builds='THE TWO BUILDS',
        builds='<p>There are <b>two different Yie Ar Kung-Fu cartridges</b> in circulation, and this is not hearsay: both are here, and <code>tools/coteja_builds.py</code> collates them instruction by instruction. They are <b>the same program</b> -they share 97.0 % of the instructions- but they do not play the same.</p><table class="dos"><tr><th></th><th>EASY</th><th>HARD</th></tr><tr><td>sha256</td><td><code>644c78c7...</code></td><td><code>61c86ad4...</code></td></tr><tr><td>how often the opponent reacts</td><td>always <b>1 frame in 32</b></td><td><b>1 in 32, 16 or 8</b> depending on the level</td></tr><tr><td>CHEN&rsquo;s long weapon</td><td>lasts 18 frames, grows to 8</td><td>lasts 22, grows to 10</td></tr><tr><td>Konami&rsquo;s hidden mark</td><td>does NOT carry it</td><td><b>YES</b>: RC-725 and the title in katakana</td></tr><tr><td>the listing in this repository</td><td><b>this one</b></td><td>collated only</td></tr></table><p>So: on the hard cartridge, at the highest level the opponent reacts <b>four times as often</b> as on the easy one, and on the easy one that never happens. The rest is five constants of CHEN&rsquo;s weapon and a change of shape in three height thresholds.</p>',
        claim="The temple backdrop written as TILES by a script, the opponent "
              "drawn with tiles and the player with sprites, and the "
              "cartridge's two builds collated instruction by instruction.",
        ficha=["Konami - <b>(c) Konami 1985</b>",
               "An <b>RC-725</b> 16 KB cartridge",
               "MSX1 - <b>page 1</b>", "Dump <b>644c78c7...</b>"],
        nav=[("#builds", "The two builds"),
             ("#numbers", "The numbers"), ("#findings", "What turned up"),
             ("#screens", "What it draws")],
        docnav=[("GETTING-STARTED.html", "Getting started"),
                ("THE-GAME.html", "The game"),
                ("THE-CARTRIDGE.html", "The cartridge"),
                ("THE-CODE.html", "The code"),
                ("THE-MUSIC.html", "The music"), ("FINDINGS.html", "Findings"),
                ("IN-THE-EMULATOR.html", "In the emulator"),
                ("OPEN-QUESTIONS.html", "Open questions")],
        otro=("es/", "En castellano"),
        h_num="The cartridge in numbers",
        h_find="What turned up when we took it apart",
        h_scr="What the cartridge draws",
        cifras=[("100%", "of the binary explained"),
                (str(RUTINAS), "named routines"),
                (DENSIDAD_EN + "%", "of the listing commented"),
                (mil(CODIGO, "en"), "bytes of code"),
                (mil(DATOS, "en"), "bytes of data"),
                ("0", "bytes unidentified")],
        nota_scr="Under each picture is where it comes from and what is on it.",
        pie_leg="This is documentation and preservation work: the code and "
                "artwork still belong to their authors and to Konami, and the "
                "cartridge image is not distributed.",
    ),
}

HALLAZGOS = {
    "es": [
        ('Las dos compilaciones difieren en el 95 % de los bytes y comparten '
         'el 97 % de las instrucciones',
         '<p>De este cartucho circulan dos volcados, que los archivos llaman '
         '<b>easy</b> y <b>hard</b>. Byte a byte se parecen en nada: '
         '<b>15.618 de 16.384 bytes distintos</b>, el 95,3 %. Esa cifra no '
         'vale para nada, porque las dos estan <b>relocalizadas</b>: un byte '
         'de mas en un sitio desplaza todo lo que va detras y con ello todas '
         'las direcciones absolutas.</p>'
         '<p>Cotejadas por INSTRUCCION -sustituyendo por un comodin todo '
         'operando de 16 bits que caiga dentro del cartucho- comparten '
         '<b>3.798 de las 3.917</b> instrucciones, el <b>97,0 %</b>. Son el '
         'mismo programa.</p>'),
        ('Lo que cambia de verdad: una mascara fija que se vuelve variable',
         '<p>La version facil deja pasar un cuadro de cada 64 y de cada 32 '
         'con mascaras escritas dentro del codigo (<code>and 03fh</code>, '
         '<code>and 03eh</code>). La dificil mete delante, en esos dos sitios '
         'exactos, ocho instrucciones que <b>no aparecen ni una vez en la '
         'facil</b>:</p>'
         '<pre>ld b,03eh / ld a,(0e056h) / and a / jr z,+7\n'
         'ld b,01eh / dec a / jr z,+2 / ld b,00eh</pre>'
         '<p>y cambia el <code>and 03fh</code> por un <code>and b</code>. La '
         'mascara la elige el nivel: 0x3E, 0x1E o 0x0E. En el nivel mas alto '
         'el oponente reacciona <b>cuatro veces mas a menudo</b>, y en la '
         'version facil eso no pasa nunca.</p>'
         '<p>Lo demas son <b>cinco constantes</b>, todas del arma larga del '
         'tercer oponente: dura 22 cuadros en vez de 18 y se estira hasta 10 '
         'en vez de hasta 8.</p>'),
        ('Solo una de las dos lleva la marca oculta de Konami',
         '<p>Konami escondia su numero de catalogo y el titulo en katakana al '
         'final de muchos cartuchos; lo descubrio <b>Manuel Pazos</b> (<a '
         'href="https://twitter.com/ManuelPazosMSX">@ManuelPazosMSX</a>). La '
         'version <b>dificil la lleva</b>: <b>RC-725</b> y el titulo en '
         'katakana, cerrando en el ultimo byte.</p>'
         '<p>La version <b>facil no</b>. En ese mismo hueco tiene el titulo '
         'en <b>ASCII latino</b>, <code>YIE AR KUNG FU</code>, que no lo lee '
         'nadie: el cartucho no sabe leer ASCII, porque su alfabeto empieza '
         'la A en el tile 0x21. Lo que eso quiera decir sobre cual salio '
         'antes no lo dice el binario, y aqui no se supone.</p>'),
        ('El fondo del templo no esta en la tabla de patrones: esta en la de '
         'nombres',
         '<p>El cartucho tiene dos interpretes de dibujo. El de GUIONES '
         '(0x442c) escribe por el puerto de datos del VDP y se usa para '
         'patrones y colores; el de LISTAS (0x44a6) escribe tiles con WRTVRM. '
         'De los catorce guiones largos del cartucho, <b>uno solo escribe en '
         '0x3800</b>: el de 0x5da4, y lo que pone ahi es el templo entero '
         '-las columnas, las lamparas, el cartel de los dos kanjis, el gong, '
         'las ventanas y el suelo de ladrillo-, 327 bytes.</p>'),
        ('Las tablas que parecian cinco escenarios son los cinco oponentes',
         '<p>Las tablas de 0x4b9c y 0x4ba6 dan un guion de patron y otro de '
         'color por cada valor de 0xE054, y se dibujan al montar la pantalla, '
         'asi que parecen cinco fondos. No lo son: montando la pantalla con '
         'los cinco y comparandolas cambian unos <b>4.000 bytes de VRAM</b>, '
         'pero <b>ninguno de los tiles que cambian esta en uso</b> en la '
         'tabla de nombres del fondo. El templo se ve igual con los cinco.</p>'
         '<p>Lo que cambia es <b>la figura del oponente</b>: WANG, TAO, CHEN, '
         'LANG y WU, en el mismo orden que sus nombres en 0x6c35.</p>'),
        ('La prueba del 0x78: el jugador es de sprites y el oponente de tiles',
         '<p>El MSX no sabe reflejar ni un sprite ni un tile, asi que un '
         'luchador que mira a los dos lados necesita las dos versiones '
         'guardadas. 0x4c3e copia los tiles del oponente de la VRAM 0x2880 a '
         'la 0x2440 dandole la vuelta a cada byte: del tile <b>0x10</b> al '
         '<b>0x88</b>, o sea <b>0x78 mas alla</b>.</p>'
         '<p>Y el descompresor de poses, cuando le toca espejar un bloque '
         '(0x5454), cambia cada tile por su gemelo <b>sumandole 0x78</b>. Las '
         'dos mitades del truco, a 10 KB de distancia una de otra.</p>'),
        ('El mismo rotulo de doce bytes, dos premios distintos',
         '<p>La lista de 0x47cc dice <b>PERFECT 3000</b> y se dibuja en la '
         'fila 16 por la puerta normal, 0x449e, que se lee sus dos primeros '
         'bytes como direccion de VRAM.</p><p>Pero 0x48ad entra por 0x449a, '
         'que <b>no lee direccion</b>, con DE dos bytes mas alla -saltandose '
         'justamente esa direccion- y HL en la fila 4. Y acto seguido escribe '
         'el tile del <b>digito 5 encima del 3</b>. El mismo texto pasa a '
         'decir <b>PERFECT 5000</b>, y lo que se suma son 0x5000 en BCD.</p>'),
        ('Cada figura del luchador lleva su destino delante, y se dibuja por '
         'dos caminos',
         '<p>Los trece guiones de 0x596f van pegados, pero la tabla de 0x4cf0 '
         'no apunta al principio de cada uno: apunta <b>dos bytes mas '
         'alla</b>. Esos dos bytes son una direccion de VRAM.</p>'
         '<p>No es un descuadre: el bucle de 0x4ca4 entra por la puerta que '
         'quiere el destino en HL y por eso empieza pasados los dos bytes, y '
         'el de 0x5098 entra por el cuerpo del comando 0x80, que <b>lee el '
         'destino del propio guion</b>. Lo demuestra una cuenta: '
         '<b>veinticuatro</b> palabras del bloque de recetas valen exactamente '
         'una de esas trece direcciones menos dos, y <b>ninguna</b> vale una '
         'de la tabla.</p>'),
        ('Una tabla de despacho con una entrada de mas metia 178 bytes de '
         'basura en el listado',
         '<p>La regla para saber cuantas entradas tiene una tabla de punteros '
         '-leer palabras mientras caigan dentro del cartucho- da <b>seis</b> '
         'para la de 0x6b4b. Son <b>cinco</b>: la sexta, 0x583A, cae dentro '
         'de un guion de dibujo, y seguirla como codigo llenaba el listado de '
         '<code>rst 18h</code> y <code>sbc a,a</code>.</p><p>Cinco es lo que '
         'dice el indice, que es el oponente, y de esos hay cinco. Y la '
         'prueba de que la tabla acaba en 0x6b55 es que <b>0x4182 hace '
         '<code>call 0x6b55</code></b>: ahi empieza codigo al que se llama '
         'por su nombre.</p>'),
        ('Un salto que aterriza dentro de otra instruccion',
         '<p>El <code>jr z</code> de 0x4625 tiene desplazamiento 8, o sea que '
         'salta a <b>0x462F</b>. Y 0x462F no es el principio de nada: es el '
         '<b>tercer byte</b> del <code>jp 0x46cf</code> que empieza en '
         '0x462d.</p><p>Cayendo ahi, el Z80 se encuentra el byte <b>0x46</b> '
         'suelto y lo ejecuta como lo que es, <code>ld b,(hl)</code>, y luego '
         'cae en el <code>call</code> de 0x4630. El byte alto de una '
         'direccion haciendo de instruccion de paso, y dos bytes ahorrados. '
         'Que es asi y no un fallo del trazado lo dice el desplazamiento: es '
         '0x08 y no 0x09.</p>'),
        ('El azar del oponente es un registro de diez bytes con semilla fija',
         '<p>0x6d2c corre un <b>registro de desplazamiento de diez bytes</b>, '
         'de 0xE135 a 0xE13E: saca el bit por arriba, lo arrastra por los '
         'nueve de abajo y lo vuelve a meter por arriba, dos veces por '
         'llamada. Devuelve los dos bits bajos, un numero de 0 a 3.</p>'
         '<p>La semilla son diez bytes de la ROM, y hay <b>cuatro juegos</b> '
         'distintos elegidos por el nivel. Con eso el oponente no se repite '
         'pero tampoco depende de nada de fuera: la partida sale igual jugada '
         'igual, que es justo lo que hace falta para poder comprobarla.</p>'),
        ('Tres trozos de codigo que no alcanza nadie',
         '<p>Veintiseis bytes en 0x73b3, tres en 0x73df y ocho en 0x74ae '
         'decodifican como codigo Z80 coherente. No los alcanza nadie, y no '
         'es una impresion: se busco la palabra de 16 bits en <b>los 16.384 '
         'bytes</b> del cartucho, no solo en el listado, y ninguna direccion '
         'cae dentro. Delante de los tres hay un salto que pasa por '
         'encima.</p>'),
    ],
    "en": [
        ('The two builds differ in 95% of their bytes and share 97% of their '
         'instructions',
         '<p>Two dumps of this cartridge circulate, which the archives call '
         '<b>easy</b> and <b>hard</b>. Byte for byte they look nothing alike: '
         '<b>15,618 of 16,384 bytes differ</b>, 95.3%. That number is worth '
         'nothing, because both are <b>relocated</b>: one byte more in one '
         'place shifts everything behind it, and with it every absolute '
         'address.</p>'
         '<p>Collated by INSTRUCTION -replacing with a wildcard every 16-bit '
         'operand that falls inside the cartridge- they share <b>3,798 of the '
         '3,917</b> instructions, <b>97.0%</b>. They are the same '
         'program.</p>'),
        ('What actually changes: a fixed mask that becomes variable',
         '<p>The easy build lets one frame in 64 and one in 32 through with '
         'masks written into the code (<code>and 03fh</code>, <code>and '
         '03eh</code>). The hard build puts eight instructions in front, at '
         'those two exact spots, that <b>appear nowhere in the easy one</b>:'
         '</p>'
         '<pre>ld b,03eh / ld a,(0e056h) / and a / jr z,+7\n'
         'ld b,01eh / dec a / jr z,+2 / ld b,00eh</pre>'
         '<p>and swaps the <code>and 03fh</code> for an <code>and b</code>. '
         'The level picks the mask: 0x3E, 0x1E or 0x0E. At the highest level '
         'the opponent reacts <b>four times as often</b>, and in the easy '
         'build that never happens.</p>'
         '<p>The rest is <b>five constants</b>, all of the third opponent\'s '
         'long weapon: it lasts 22 frames instead of 18 and stretches to 10 '
         'instead of 8.</p>'),
        ("Only one of the two carries Konami's hidden mark",
         '<p>Konami hid its catalogue number and the title in katakana at the '
         'end of many cartridges; <b>Manuel Pazos</b> (<a '
         'href="https://twitter.com/ManuelPazosMSX">@ManuelPazosMSX</a>) '
         'found it. The <b>hard</b> build <b>has it</b>: <b>RC-725</b> and '
         'the title in katakana, closing on the very last byte.</p>'
         '<p>The <b>easy</b> build <b>does not</b>. In that same gap it '
         'carries the title in <b>Latin ASCII</b>, <code>YIE AR KUNG FU</code>, '
         'which nothing reads: the cartridge cannot read ASCII, because its '
         'alphabet starts A at tile 0x21. What that says about which came '
         'first the binary does not tell, and it is not assumed here.</p>'),
        ('The temple backdrop is not in the pattern table: it is in the name '
         'table',
         '<p>The cartridge has two drawing interpreters. The SCRIPT one '
         '(0x442c) writes through the VDP data port and is used for patterns '
         'and colours; the LIST one (0x44a6) writes tiles with WRTVRM. Of the '
         "cartridge's fourteen long scripts, <b>only one writes at "
         '0x3800</b>: the one at 0x5da4, and what it puts there is the whole '
         'temple -the columns, the lanterns, the two-kanji sign, the gong, '
         'the windows and the brick floor-, 327 bytes.</p>'),
        ('The tables that looked like five stages are the five opponents',
         '<p>The tables at 0x4b9c and 0x4ba6 give a pattern script and a '
         'colour script per value of 0xE054, and they are drawn while the '
         'screen is being built, so they look like five backdrops. They are '
         'not: building the screen with all five and comparing them, some '
         '<b>4,000 bytes of VRAM</b> change, but <b>none of the tiles that '
         "change is in use</b> in the backdrop's name table. The temple looks "
         'identical with all five.</p><p>What changes is <b>the opponent\'s '
         'figure</b>: WANG, TAO, CHEN, LANG and WU, in the same order as '
         'their names at 0x6c35.</p>'),
        ('The 0x78 proof: the player is sprites and the opponent is tiles',
         '<p>The MSX cannot mirror a sprite or a tile, so a fighter who faces '
         'both ways needs both versions stored. 0x4c3e copies the opponent\'s '
         'tiles from VRAM 0x2880 to 0x2440 flipping every byte: from tile '
         '<b>0x10</b> to <b>0x88</b>, that is <b>0x78 further on</b>.</p>'
         '<p>And the pose decompressor, when it has to mirror a block '
         '(0x5454), swaps each tile for its twin by <b>adding 0x78</b>. The '
         "trick's two halves, 10 KB apart.</p>"),
        ('The same twelve-byte caption, two different prizes',
         '<p>The list at 0x47cc reads <b>PERFECT 3000</b> and is drawn on row '
         '16 through the normal door, 0x449e, which reads its first two bytes '
         'as a VRAM address.</p><p>But 0x48ad comes in through 0x449a, which '
         '<b>reads no address</b>, with DE two bytes further on -skipping '
         'exactly that address- and HL on row 4. And right after it writes '
         "the tile for <b>digit 5 over the 3</b>. The same text now reads "
         '<b>PERFECT 5000</b>, and what is added is 0x5000 in BCD.</p>'),
        ("Each of the fighter's figures carries its destination in front, and "
         'is drawn two ways',
         '<p>The thirteen scripts from 0x596f run back to back, but the table '
         'at 0x4cf0 does not point at the start of each one: it points '
         '<b>two bytes further on</b>. Those two bytes are a VRAM address.</p>'
         '<p>It is not a misalignment: the loop at 0x4ca4 comes in through '
         'the door that wants the destination in HL and so starts past the '
         'two bytes, and the one at 0x5098 comes in through the body of '
         'command 0x80, which <b>reads the destination out of the script '
         'itself</b>. A count proves it: <b>twenty-four</b> words of the '
         'recipe block equal exactly one of those thirteen addresses minus '
         'two, and <b>none</b> equals one from the table.</p>'),
        ('A dispatch table with one entry too many put 178 bytes of rubbish '
         'in the listing',
         '<p>The rule for how many entries a pointer table has -read words '
         'while they land inside the cartridge- gives <b>six</b> for the one '
         'at 0x6b4b. There are <b>five</b>: the sixth, 0x583A, falls inside a '
         'drawing script, and following it as code filled the listing with '
         '<code>rst 18h</code> and <code>sbc a,a</code>.</p><p>Five is what '
         'the index says, which is the opponent, and there are five of those. '
         'And the proof that the table ends at 0x6b55 is that <b>0x4182 does '
         '<code>call 0x6b55</code></b>: code that is called by name starts '
         'there.</p>'),
        ('A jump that lands inside another instruction',
         '<p>The <code>jr z</code> at 0x4625 has displacement 8, so it jumps '
         'to <b>0x462F</b>. And 0x462F is not the start of anything: it is '
         'the <b>third byte</b> of the <code>jp 0x46cf</code> that begins at '
         '0x462d.</p><p>Landing there, the Z80 finds byte <b>0x46</b> on its '
         'own and runs it for what it is, <code>ld b,(hl)</code>, and then '
         'falls into the <code>call</code> at 0x4630. The high byte of an '
         'address doing duty as a filler instruction, and two bytes saved. '
         'That this is so and not a tracing slip is settled by the '
         'displacement: it is 0x08 and not 0x09.</p>'),
        ("The opponent's randomness is a ten-byte register with a fixed seed",
         '<p>0x6d2c runs a <b>ten-byte shift register</b>, 0xE135 to 0xE13E: '
         'it takes the bit off the top, drags it through the nine below and '
         'feeds it back in at the top, twice per call. It returns the two low '
         'bits, a number from 0 to 3.</p><p>The seed is ten bytes of ROM, and '
         'there are <b>four different sets</b> picked by the level. With that '
         'the opponent does not repeat but does not depend on anything '
         'outside either: the same play gives the same match, which is '
         'exactly what you need to be able to check it.</p>'),
        ('Three pieces of code nothing reaches',
         '<p>Twenty-six bytes at 0x73b3, three at 0x73df and eight at 0x74ae '
         'decode as coherent Z80 code. Nothing reaches them, and that is not '
         'an impression: the 16-bit word was searched across <b>all 16,384 '
         'bytes</b> of the cartridge, not just the listing, and no address '
         'falls inside. In front of all three there is a jump that steps over '
         'them.</p>'),
    ],
}

GALERIA = [
    ("protagonista{}.png",
     "<b>El protagonista, montado.</b> No es un sprite: son <b>SEIS</b>, y sus "
     "seis numeros de patron -04 08 0C 10 14 18, los de 0x50A6- no cambian "
     "nunca. Lo que cambia en cada pose es DONDE va cada uno y QUE dibujo "
     "tiene dentro, y las dos cosas las dice la receta de 0x50AC. Los "
     "desplazamientos y los colores de aqui estan comprobados contra la tabla "
     "de atributos de sprites de una maquina en marcha: <b>doce volcados, "
     "doce poses reconocidas</b>",
     "<b>The player, assembled.</b> He is not one sprite: he is <b>SIX</b>, "
     "and his six pattern numbers -04 08 0C 10 14 18, the ones at 0x50A6- "
     "never change. What changes in each pose is WHERE each goes and WHAT it "
     "holds, and the recipe at 0x50AC says both. The offsets and colours here "
     "are checked against the sprite attribute table of a running machine: "
     "<b>twelve dumps, twelve poses recognised</b>"),
    ("titulo.png",
     "<b>La pantalla del titulo</b>, montada con los pasos del propio "
     "cartucho: el color plano de los dieciseis primeros tiles (0x560f), el "
     "guion de la fuente en la VRAM 0x2080, el relleno de 0xF0 y los dos "
     "guiones del rotulo, y encima las listas de tiles de 0x5909 y 0x559b, "
     "que traen el logotipo, el PUSH SPACE KEY y el copyright",
     "<b>The title screen</b>, built with the cartridge's own steps: the flat "
     "colour of the first sixteen tiles (0x560f), the font script into VRAM "
     "0x2080, the 0xF0 fill and the two wordmark scripts, and on top the tile "
     "lists at 0x5909 and 0x559b, which bring the logo, the PUSH SPACE KEY "
     "and the copyright"),
    ("video_cartridge.png",
     "El mismo fondo con la <b>otra lista</b>, la de 0x55c8: el "
     "<b>VIDEO CARTRIDGE</b> que la escena 0 dibuja uno de cada dos cuadros "
     "antes de dar paso al logotipo",
     "The same backdrop with the <b>other list</b>, the one at 0x55c8: the "
     "<b>VIDEO CARTRIDGE</b> that scene 0 draws one frame in two before "
     "handing over to the logo"),
    ("combate_0.png",
     "<b>La pantalla de combate</b>. El templo -las columnas, las lamparas, "
     "el cartel, el gong, las ventanas y el ladrillo- lo escribe como tiles "
     "el guion de 0x5da4 en la tabla de NOMBRES; los patrones y los colores "
     "vienen de 0x605b y 0x6207. Comparada con la VRAM del emulador a los 120 "
     "segundos de partida: <b>cero diferencias</b> en color y en patron",
     "<b>The fighting screen</b>. The temple -the columns, the lanterns, the "
     "sign, the gong, the windows and the brickwork- is written as tiles by "
     "the script at 0x5da4 into the NAME table; the patterns and colours come "
     "from 0x605b and 0x6207. Compared against the emulator's VRAM 120 "
     "seconds into a game: <b>zero differences</b> in colour and pattern"),
    ("oponente_wang.png",
     "<b>WANG</b>, el primer oponente, con sus siete poses. Los oponentes NO "
     "son sprites como el protagonista: son <b>tiles</b> escritos en la tabla "
     "de nombres, y cada pose es un RECTANGULO de alto por ancho con sus "
     "tiles comprimidos dentro del propio bloque. La de reposo de WANG es "
     "<code>00 10 E3 FF 11</code>: un hueco, la cabeza, tres huecos y quince "
     "tiles correlativos. Veinte, que es 5 x 4",
     "<b>WANG</b>, the first opponent, in his seven poses. The opponents are "
     "NOT sprites like the player: they are <b>tiles</b> written into the "
     "name table, and each pose is a RECTANGLE of height by width with its "
     "tiles compressed inside the pose block itself. WANG&rsquo;s idle is "
     "<code>00 10 E3 FF 11</code>: a gap, the head, three gaps and fifteen "
     "consecutive tiles. Twenty, which is 5 x 4"),
    ("oponente_tao.png",
     "<b>TAO</b>, el segundo. Cada oponente tiene su propia anchura de pose "
     "-TAO 4 tiles, WANG 5, CHEN y LANG 5, WU 4-, y por eso ponerlos todos a "
     "cuatro por fila, que es lo que hacia esta web hasta el 2026-09-04, "
     "partia las figuras",
     "<b>TAO</b>, the second. Each opponent has his own pose width -TAO 4 "
     "tiles, WANG 5, CHEN and LANG 5, WU 4- which is why laying them all four "
     "to a row, as this site did until 2026-09-04, cut the figures to "
     "pieces"),
    ("oponente_chen.png",
     "<b>CHEN</b>, el tercero, el de la cadena. Es el unico al que la version "
     "dificil le cambia constantes -cinco-, todas de su arma larga",
     "<b>CHEN</b>, the third, the one with the chain. He is the only one "
     "whose constants the hard build changes -five of them- all belonging to "
     "his long weapon"),
    ("oponente_lang.png",
     "<b>LANG</b>, el cuarto, con ocho poses",
     "<b>LANG</b>, the fourth, with eight poses"),
    ("oponente_wu.png",
     "<b>WU</b>, el quinto y ultimo, tambien con ocho. Su tabla de poses "
     "tiene VEINTE entradas, dos mas que la de los otros cuatro",
     "<b>WU</b>, the fifth and last, also with eight. His pose table has "
     "TWENTY entries, two more than the other four"),
]


def img64(ruta):
    with open(ruta, "rb") as f:
        return "data:image/png;base64," + base64.b64encode(f.read()).decode()


def main(argv):
    if len(argv) < 4:
        print(__doc__)
        return 2
    imgdir, salida, idioma = argv[1:4]
    t = TXT[idioma]

    # El "logotipo" de la cabecera no es un montaje ni una captura: es el
    # rotulo que el propio cartucho pinta en su pantalla de titulo, dibujado
    # desde la ROM por pantallas.py. Si el PNG no esta, el trabajo NO esta
    # hecho: se cae al texto, y eso se ve.
    ruta_logo = os.path.join(imgdir, "rotulo.png")
    cabecera = (f'<img src="{img64(ruta_logo)}" alt="Yie Ar Kung-Fu">'
                if os.path.exists(ruta_logo) else "<h1>Yie Ar Kung-Fu</h1>")

    nav = "".join(f'<a href="{h}">{x}</a>' for h, x in t["nav"])
    nav += "".join(f'<a href="{h}">{x}</a>' for h, x in t["docnav"])
    nav += (f'<a href="{t["otro"][0]}" style="margin-left:auto;color:var(--oro)">'
            f'{t["otro"][1]}</a>')

    cifras = "".join(f'<div class="cifra"><b>{v}</b><span>{e}</span></div>'
                     for v, e in t["cifras"])
    halls = "".join(f'<div class="hall"><h3>{tit}</h3>{cuerpo}</div>'
                    for tit, cuerpo in HALLAZGOS[idioma])
    imgs = ""
    faltan = []
    for fich, es, en in GALERIA:
        # un "{}" en el nombre se sustituye por el idioma: asi la lamina del
        # protagonista sale rotulada en el idioma de la pagina
        if "{}" in fich:
            fich = fich.format("" if idioma == "es" else "_" + idioma)
        ruta = os.path.join(imgdir, fich)
        if not os.path.exists(ruta):
            faltan.append(fich)
            continue
        pie = es if idioma == "es" else en
        imgs += (f'<figure><img src="{img64(ruta)}" alt="{pie}">'
                 f'<figcaption>{pie}</figcaption></figure>')
    if faltan:
        print("  (faltan %d imagenes: %s)" % (len(faltan), " ".join(faltan)))

    html = f"""<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>{t['titulo']}</title>
<style>{ESTILO}{ESTILO_DOS}</style>
<header class="top">
  {cabecera}
  <p class="claim">{t['claim']}</p>
  <p class="ficha">{' - '.join(t['ficha'])}</p>
</header>
<p class="ficha" style="border:1px solid var(--oro);padding:.8em 1em;margin:1.5em 0">
{t['aviso']}</p>
<nav>{nav}</nav>
<section id="builds"><h2>{t['h_builds']}</h2>{t['builds']}</section>
<section id="numbers">
  <h2>{t['h_num']}</h2>
  <div class="cifras">{cifras}</div>
</section>
<section id="findings"><h2>{t['h_find']}</h2>{halls}</section>
<section id="screens">
  <h2>{t['h_scr']}</h2>
  <p class="n">{t['nota_scr']}</p>
  <div class="galeria">{imgs}</div>
</section>
<footer><p>{t['pie_leg']}</p></footer>
"""
    with open(salida, "w", encoding="utf-8") as f:
        f.write(html)
    print("  %s: %d KB (%s)" % (salida, len(html) // 1024, idioma))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
