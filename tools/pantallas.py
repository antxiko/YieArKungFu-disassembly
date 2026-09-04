#!/usr/bin/env python3
"""Las pantallas del cartucho, montadas ejecutando lo que ejecuta la ROM.

No hay ninguna captura aqui dentro. Se reproduce la secuencia de arranque tal
como la hace el cartucho -guiones, listas, rellenos y espejos, en ese orden- y
se revela la VRAM que queda. Si el dibujo sale bien es porque los interpretes
de `guiones.py` y `textos.py` son correctos, no porque se haya mirado una foto.

EL MAPA DE VRAM, que sale de los ocho registros de 0x4503 (02 E2 0E 7F 07 76
03 E0):

    0x0000  COLOR                    (R3 = 0x7F)
    0x1800  PATRONES DE SPRITE       (R6 = 0x03)
    0x2000  PATRONES                 (R4 = 0x07)
    0x3800  NOMBRES                  (R2 = 0x0E)
    0x3B00  ATRIBUTOS DE SPRITE      (R5 = 0x76)

O sea COLOR abajo y PATRON arriba, al reves de lo habitual.

LA PORTADA, como la monta la escena 0 (paso 0, en 0x40e1):
    0x4413  la tabla de nombres a cero
    0x44f2  los ocho registros del VDP
    0x560f  el color de los dieciseis primeros tiles de cada tercio: ocho
            bytes de 0x00, ocho de 0x11, ... hasta 0xFF
    0x5635  guion 0x564e en la VRAM 0x2080, en los tres tercios
    0x5646  relleno de 0xF0 desde la VRAM 0x0080, 0x250 bytes, tres tercios
    0x43f6  guion 0x57f5 en la VRAM 0x2600 ................... patrones
    0x43ff  guion 0x57ee en la VRAM 0x0600 ..................... colores
    0x40bf  lista 0x55c8 ................. el VIDEO CARTRIDGE del paso 1
    0x4402  listas 0x5909 y 0x559b ....... el logotipo y el PUSH SPACE KEY

EL COMBATE, como lo monta 0x4bda con el oponente de 0xE054:
    0x4bee  guion de PATRON del OPONENTE en la VRAM 0x2880, dos tercios
    0x4bfc  guion de COLOR en la VRAM 0x0880 y en la 0x0c40, dos tercios
    0x4c0c  guion 0x605b en la VRAM 0x22f0, tres tercios ..... el templo
    0x4c17  guion 0x6207 en la VRAM 0x02f0, tres tercios
    0x4c20  y el mismo 0x3c0 mas alla, en la VRAM 0x06b0
    0x4c3e  espejo: 0x3c0 bytes de la VRAM 0x2880 a la 0x2440, y luego a la
            0x2c40 y a la 0x3440. El ORIGEN no avanza; el destino, si
    0x4c68  once tiles ya dibujados, de VRAM a VRAM, a partir de 0x32b0
    0x4ca2  los trece guiones del luchador, en 0x1800-0x1fff
    0x4cbe  y su espejo, de 0x1a00 a 0x1910
    0x5d7a  guion 0x5da4 en la VRAM 0x38a0 ..... el templo en NOMBRES
    0x5d89  guion 0x5d8c en la VRAM 0x3860 ..... la cornisa

COMPROBADO: comparando la VRAM que sale de aqui con los 16 KB que openMSX
tiene a los 120 segundos de partida, la tabla de COLOR sale con CERO bytes de
diferencia de 6.144 y la de PATRON con CERO de 6.144. Lo que no coincide es lo
que el juego reescribe cada cuadro: los patrones de sprite y, en la tabla de
nombres, el marcador, el nombre del oponente y los tiles del luchador.

Uso: pantallas.py <rom> <org> <carpeta de salida>
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import guiones                                             # noqa: E402
import textos                                              # noqa: E402

ORG = 0x4000

# Las cinco parejas de guiones de OPONENTE, de las tablas de 0x4b9c y 0x4ba6:
# WANG, TAO, CHEN, LANG y WU, en el orden de los nombres de 0x6c35.
ESCENARIOS = [(0x5EEB, 0x6172), (0x624B, 0x6421), (0x64BD, 0x669B),
              (0x6724, 0x68A2), (0x68FF, 0x6A9C)]


def dibuja(rom, vram, guion, destino, tercios=1):
    """dibuja_en_dos_tercios / dibuja_en_los_tres_tercios de 0x44ca."""
    for i in range(tercios):
        vram.sitio(destino + i * 0x800)
        guiones.cuerpo(rom, guion, vram)


def rellena(vram, destino, valor, cuenta, tercios=1):
    """rellena_los_tres_tercios de 0x44b9, que es FILVRM tercio a tercio."""
    for i in range(tercios):
        p = (destino + i * 0x800) & 0x3FFF
        for k in range(cuenta):
            vram.b[(p + k) & 0x3FFF] = valor
            vram.tocado[(p + k) & 0x3FFF] = 1


def al_reves(v):
    """da_la_vuelta_al_byte de 0x448f: los ocho bits en orden inverso."""
    return int(format(v, "08b")[::-1], 2)


def espejo(vram, origen, destino, cuenta, veces=1):
    """El bucle de 0x4c46: copia dando la vuelta a cada byte.

    OJO con el origen: NO avanza. En cada vuelta el cartucho hace `pop de / ld
    hl,00800h / add hl,de / ex de,hl / pop hl`, o sea que suma 0x800 al DESTINO
    y recupera el HL de partida. Asi que los tres tercios se llenan con la
    MISMA copia reflejada de 0x2880, no cada uno con la suya.
    """
    o = origen & 0x3FFF
    for i in range(veces):
        d = (destino + i * 0x800) & 0x3FFF
        for k in range(cuenta):
            vram.b[(d + k) & 0x3FFF] = al_reves(vram.b[(o + k) & 0x3FFF])
            vram.tocado[(d + k) & 0x3FFF] = 1


def color_de_los_dieciseis(vram):
    """0x5624: ocho bytes de 0x00, ocho de 0x11, ... para los tres tercios."""
    for tercio in (0x0000, 0x0800, 0x1000):
        a = 0
        for fila in range(16):
            for k in range(8):
                vram.b[tercio + fila * 8 + k] = a
                vram.tocado[tercio + fila * 8 + k] = 1
            a = (a + 0x11) & 0xFF


def lista(rom, vram, ini):
    """El interprete de 0x44a6, escribiendo en la tabla de nombres."""
    fin, tramos = textos.lee(rom, ini)
    pos = ini + 2
    destino = rom[ini - ORG] | (rom[ini + 1 - ORG] << 8)
    p = destino & 0x3FFF
    while True:
        v = rom[pos - ORG]
        pos += 1
        if v == 0xFF:
            return
        if v == 0xFE:
            p = (rom[pos - ORG] | (rom[pos + 1 - ORG] << 8)) & 0x3FFF
            pos += 2
            continue
        vram.b[p] = v
        vram.tocado[p] = 1
        p = (p + 1) & 0x3FFF


def copia_en_vram(vram, origen, destino, cuenta):
    """El bucle de 0x4c7a: RDVRM y WRTVRM byte a byte, sin pasar por la ROM."""
    for k in range(cuenta):
        vram.b[(destino + k) & 0x3FFF] = vram.b[(origen + k) & 0x3FFF]
        vram.tocado[(destino + k) & 0x3FFF] = 1


def el_copyright_de_abajo(rom, vram):
    """0x4c68: once tiles ya dibujados, copiados de VRAM a VRAM.

    La tabla de 0x4cd2 da once direcciones de la tabla de patrones -las de la
    (C), la K, la O, la N, la A, la M, la I y los digitos 1, 9, 8 y 5- y el
    bucle las lleva de ocho en ocho a partir de 0x32b0, que es el patron del
    tile 0x56 del tercer tercio. Ahi es donde apunta la fila 23 de la tabla de
    nombres. Y 0x4c8d le pone el color de una vez, 0x60 bytes de 0xF0.
    """
    destino = 0x32B0
    for i in range(11):
        origen = rom[0x4CD2 - ORG + 2 * i] | (rom[0x4CD3 - ORG + 2 * i] << 8)
        copia_en_vram(vram, origen & 0x3FFF, destino, 8)
        destino += 8
    rellena(vram, 0x12B0, 0xF0, 0x60)


def figuras_del_luchador(rom, vram):
    """0x4ca2: los trece guiones de 0x596f, el espejo y el marcador.

    El bucle va de B = 13 a B = 1, o sea del ultimo guion al primero, y cada
    uno se dibuja donde diga la tabla de 0x4d0a. Todos caen en 0x1800-0x1fff,
    que es la tabla de patrones de SPRITE.
    """
    rellena(vram, 0x1800, 0x00, 0x20)
    for b in range(13, 0, -1):
        i = b - 1
        guion = rom[0x4CF0 - ORG + 2 * i] | (rom[0x4CF1 - ORG + 2 * i] << 8)
        destino = rom[0x4D0A - ORG + 2 * i] | (rom[0x4D0B - ORG + 2 * i] << 8)
        vram.sitio(destino)
        guiones.cuerpo(rom, guion, vram)
    # 0x4cbe: refleja_varias_filas con C = 0x30, o sea 48 filas de 16 bytes
    # desde la VRAM 0x1a00 a la 0x1910, cada byte del reves.
    origen, destino = 0x1A00, 0x1910
    for _ in range(0x30):
        for f in range(2):
            for k in range(16):
                o = origen + f * 0x20 + k
                vram.b[(destino + f * 0x20 + k) & 0x3FFF] = al_reves(vram.b[o & 0x3FFF])
                vram.tocado[(destino + f * 0x20 + k) & 0x3FFF] = 1
        origen += 0x20
        destino += 0x20
    dibuja(rom, vram, 0x5D02, 0x1E40)


def fondo_comun(rom, vram):
    """Lo que 0x560f y 0x5635 dejan puesto, y que llevan todas las pantallas."""
    color_de_los_dieciseis(vram)
    dibuja(rom, vram, 0x564E, 0x2080, 3)
    rellena(vram, 0x0080, 0xF0, 0x250, 3)
    dibuja(rom, vram, 0x57F5, 0x2600)          # patrones del rotulo
    dibuja(rom, vram, 0x57EE, 0x0600)          # y sus colores


def portada(rom, con_logotipo=True):
    """La pantalla de titulo. Sin logotipo es el paso 1, el VIDEO CARTRIDGE."""
    v = guiones.Vram()
    fondo_comun(rom, v)
    if con_logotipo:
        lista(rom, v, 0x5909)                  # el rotulo del juego
        lista(rom, v, 0x559B)                  # PUSH SPACE KEY y el copyright
    else:
        lista(rom, v, 0x55C8)                  # VIDEO CARTRIDGE
    return v


def combate(rom, cual):
    """La pantalla de combate con el oponente que se pida, de 0 a 4."""
    patron, color = ESCENARIOS[cual]
    v = guiones.Vram()
    fondo_comun(rom, v)
    dibuja(rom, v, patron, 0x2880, 2)
    dibuja(rom, v, color, 0x0880, 2)
    dibuja(rom, v, color, 0x0C40, 2)
    dibuja(rom, v, 0x605B, 0x22F0, 3)
    dibuja(rom, v, 0x6207, 0x02F0, 3)
    dibuja(rom, v, 0x6207, 0x06B0, 3)
    espejo(v, 0x2880, 0x2440, 0x3C0, 3)
    el_copyright_de_abajo(rom, v)
    figuras_del_luchador(rom, v)
    dibuja(rom, v, 0x5DA4, 0x38A0)             # el templo, en NOMBRES
    dibuja(rom, v, 0x5D8C, 0x3860)             # la cornisa
    lista(rom, v, 0x5566)                      # los rotulos del marcador
    return v



PATRONES = 0x2000        # (R4 and 0x04) * 0x800, con R4 = 0x07
COLORES = 0x0000         # (R3 and 0x80) * 0x40,  con R3 = 0x7F
NOMBRES = 0x3800         # R2 * 0x400, con R2 = 0x0E
SPRITES = 0x1800         # R6 * 0x800, con R6 = 0x03

PALETA = [
    (0, 0, 0), (0, 0, 0), (33, 200, 66), (94, 220, 120),
    (84, 85, 237), (125, 118, 252), (212, 82, 77), (66, 235, 245),
    (252, 85, 84), (255, 121, 120), (212, 193, 84), (230, 206, 128),
    (33, 176, 59), (201, 91, 186), (204, 204, 204), (255, 255, 255),
]


def pinta(v):
    """La VRAM a una imagen de 256x192, como la saca el TMS9918 en SCREEN 2."""
    img = [[0] * 256 for _ in range(192)]
    for fila in range(24):
        tercio = fila // 8
        for col in range(32):
            tile = v.b[NOMBRES + fila * 32 + col]
            base = tercio * 0x800 + tile * 8
            for y in range(8):
                forma = v.b[PATRONES + base + y]
                color = v.b[COLORES + base + y]
                tinta, fondo = color >> 4, color & 0x0F
                for x in range(8):
                    on = (forma >> (7 - x)) & 1
                    img[fila * 8 + y][col * 8 + x] = tinta if on else fondo
    return img


def figura(v, patron, tinta=15):
    """Un sprite de 16x16 de la tabla de 0x1800, como lo compone el VDP.

    Con R1 = 0xE2 los sprites son de 16x16, y el VDP los arma con CUATRO
    bloques de ocho bytes seguidos: el de arriba a la izquierda, el de abajo a
    la izquierda, el de arriba a la derecha y el de abajo a la derecha. Por eso
    el numero de patron se redondea a multiplo de cuatro.
    """
    base = SPRITES + (patron & 0xFC) * 8
    img = [[0] * 16 for _ in range(16)]
    for k in range(4):
        ox, oy = (8 if k >= 2 else 0), (8 if k % 2 else 0)
        for y in range(8):
            forma = v.b[(base + k * 8 + y) & 0x3FFF]
            for x in range(8):
                if (forma >> (7 - x)) & 1:
                    img[oy + y][ox + x] = tinta
    return img


def rejilla(lienzos, cols, sep=1, fondo=1):
    """Varios lienzos del mismo tamano, en una cuadricula con separacion."""
    if not lienzos:
        return [[fondo]]
    al, an = len(lienzos[0]), len(lienzos[0][0])
    filas = (len(lienzos) + cols - 1) // cols
    ancho = cols * an + (cols + 1) * sep
    alto = filas * al + (filas + 1) * sep
    img = [[fondo] * ancho for _ in range(alto)]
    for i, l in enumerate(lienzos):
        y0 = sep + (i // cols) * (al + sep)
        x0 = sep + (i % cols) * (an + sep)
        for y in range(al):
            for x in range(an):
                img[y0 + y][x0 + x] = l[y][x]
    return img


def png(ruta, img, escala=3):
    import struct
    import zlib

    al, an = len(img) * escala, len(img[0]) * escala
    crudo = b""
    for fila in img:
        linea = b"".join(bytes(PALETA[c]) * escala for c in fila)
        crudo += (b"\0" + linea) * escala
    del al, an

    def trozo(tipo, datos):
        return (struct.pack(">I", len(datos)) + tipo + datos
                + struct.pack(">I", zlib.crc32(tipo + datos) & 0xFFFFFFFF))

    with open(ruta, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n")
        f.write(trozo(b"IHDR", struct.pack(">IIBBBBB", len(img[0]) * escala,
                                           len(img) * escala, 8, 2, 0, 0, 0)))
        f.write(trozo(b"IDAT", zlib.compress(crudo, 9)))
        f.write(trozo(b"IEND", b""))



def tile_pintado(v, tercio, t):
    """Un tile de 8x8 con su color, tal como lo saca el VDP."""
    img = [[0] * 8 for _ in range(8)]
    base = tercio * 0x800 + t * 8
    for y in range(8):
        forma = v.b[PATRONES + base + y]
        color = v.b[COLORES + base + y]
        tinta, fondo = color >> 4, color & 0x0F
        for x in range(8):
            img[y][x] = tinta if (forma >> (7 - x)) & 1 else fondo
    return img


def hoja_del_oponente(rom, cual):
    """Los tiles que el guion del oponente deja en el segundo tercio.

    OJO: esto devuelve los tiles SUELTOS, en el orden en que caen en la VRAM.
    NO es la figura. Los oponentes se dibujan como tiles en la tabla de
    nombres, y CADA POSE los reparte en una forma irregular -medido en la
    maquina: la de reposo de WANG son dieciseis tiles en un hueco de 4x5 con
    la fila de arriba a medias, y las demas poses y los demas oponentes usan
    formas distintas-. Por eso ponerlos en una rejilla de anchura fija parte
    las figuras, que es lo que se publicaba antes.

    Mientras el formato de los bloques de pose de 0x555c no este descifrado,
    esta funcion se queda para mirar los tiles con tools/, no para la web.
    """
    v = combate(rom, cual)
    patron, _ = ESCENARIOS[cual]
    m = guiones.Vram()
    m.sitio(0x2880)
    guiones.cuerpo(rom, patron, m)
    tocados = [k for k, x in enumerate(m.tocado) if x]
    primero = (min(tocados) - 0x2800) // 8
    ultimo = (max(tocados) - 0x2800) // 8
    return [tile_pintado(v, 1, t) for t in range(primero, ultimo + 1)]


def recorta(img, y0, x0, alto, ancho):
    return [fila[x0:x0 + ancho] for fila in img[y0:y0 + alto]]


def el_rotulo(rom):
    """Solo el logotipo del juego, recortado de la pantalla de titulo.

    La lista de 0x5909 lo pone en las filas 4, 5 y 6 desde la columna 7, en
    treinta y seis tiles de dos filas de dieciocho. Aqui se recorta con un
    margen de una fila y una columna a cada lado.
    """
    v = portada(rom)
    return recorta(pinta(v), 3 * 8, 6 * 8, 5 * 8, 20 * 8)


def main():
    rom = open(sys.argv[1], "rb").read()
    carpeta = sys.argv[3] if len(sys.argv) > 3 else "work/gfx"
    os.makedirs(carpeta, exist_ok=True)
    png(os.path.join(carpeta, "rotulo.png"), el_rotulo(rom), 4)
    print("  rotulo.png")
    hechas = [("titulo", portada(rom)),
              ("video_cartridge", portada(rom, False))]
    hechas += [("combate_%d" % i, combate(rom, i)) for i in range(5)]
    for nombre, v in hechas:
        with open(os.path.join(carpeta, nombre + ".vram"), "wb") as f:
            f.write(bytes(v.b))
        png(os.path.join(carpeta, nombre + ".png"), pinta(v))
        print("  %-18s %5d bytes tocados" % (nombre, sum(v.tocado)))
    # El luchador NO se dibuja aqui. Volcar los 64 sprites de 16x16 de la
    # tabla de patrones daba una hoja sin orden y sin figura: el protagonista
    # se ARMA con seis de esos sprites en posiciones que cambian con la pose.
    # De eso se ocupa tools/protagonista.py, que lee las recetas de 0x50ac.
    # Las hojas de oponente NO se publican: eran tiles sueltos puestos de
    # cuatro en cuatro, y eso parte las figuras. Ver hoja_del_oponente.


if __name__ == "__main__":
    main()
