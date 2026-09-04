#!/usr/bin/env python3
"""Monta al PROTAGONISTA, que no es un sprite sino SEIS.

docs/imagenes/figuras.png era un volcado crudo de los 64 sprites de 16x16 de
la tabla de patrones, sueltos y en el orden en que caen en la VRAM. Asi no se
ve al luchador: el luchador se ARMA cada cuadro juntando seis sprites en
posiciones que cambian con la pose.

COMO SE ARMA (0x4fbe, `arma_al_luchador` en el listado)
-------------------------------------------------------
1. Los seis bytes de 0x50a6 -04 08 0C 10 14 18- se reparten por el campo de
   PATRON de los seis primeros sprites del buffer de 0xE0c4. Esos seis
   patrones no cambian nunca: lo que cambia con la pose es su CONTENIDO, que
   los guiones de la receta vuelven a cargar en la tabla de 0x1800.
2. La pose (0xE154) indexa la tabla de 22 punteros de 0x50ac y se mete en la
   receta que salga.
3. La receta empieza con dos campos opcionales -0x7- y 0x8-, que dejan sus
   nibbles bajos en 0xE174 y 0xE172- y una terna que se suma a la X.
4. Y luego, el bucle de 0x5064, una entrada por sprite:

       dy          se suma a la Y del luchador
       dx          se suma a su X
       [0xFn]      opcional: la X del golpe, a 0xE171
       patron      SE SALTA (el `inc hl` de 0x5087): ya lo puso el paso 1
       color       tal cual

   Un campo cuyo nibble alto valga 0x8- cierra la lista, y su nibble bajo dice
   cuantas PAREJAS DE DIRECCIONES vienen detras: cada una es un guion que se
   dibuja con encadena_el_guion, y son los que recargan los seis patrones.

Con 0xE162 distinto de cero -mirando a la izquierda- la receta se cambia por
la que diga el puntero de 0x5021 y las X salen espejadas (0x5034: 0x10 + dx,
negado, mas la X). Aqui se dibuja mirando a la derecha, que es la receta
directa.

COMPROBADO CONTRA LA MAQUINA
----------------------------
tools/omsx_sat.tcl vuelca la tabla de atributos de sprites durante un combate
de verdad. `protagonista.py --comprueba` compara los seis sprites que calcula
este fichero -desplazamientos y colores- con los que tiene puestos el MSX.

Uso: protagonista.py <rom> <carpeta> [--comprueba <carpeta de volcados>]
"""
import os
import sys

import guiones

ORG = 0x4000
SPRITES = 0x1800
PATRONES_DE_ARRANQUE = 0x50A6
TABLA_DE_RECETAS = 0x50AC
POSES = 22

# La paleta fija del TMS9918.
PALETA = [
    (0, 0, 0), (0, 0, 0), (33, 200, 66), (94, 220, 120),
    (84, 85, 237), (125, 118, 252), (212, 82, 77), (66, 235, 245),
    (252, 85, 84), (255, 121, 120), (212, 193, 84), (230, 206, 128),
    (33, 176, 59), (201, 91, 186), (204, 204, 204), (255, 255, 255),
]


def _b(rom, a):
    return rom[a - ORG]


def _w(rom, a):
    return _b(rom, a) | (_b(rom, a + 1) << 8)


def poses_legibles(rom):
    """Las poses cuya receta se lee entera y coherente.

    De las 22 entradas de la tabla, SEIS llevan delante un campo 0x8- y un
    puntero que cae dentro del propio bloque de recetas: son las variantes
    ESPEJADAS, a las que solo se llega por el camino de 0x5021 -mirando a la
    izquierda-, y el interprete directo de aqui no las sigue. Se reconocen
    porque leidas de frente dan listas absurdas: mas de seis sprites, colores
    fuera de rango o guiones que caen fuera del cartucho.
    """
    buenas = []
    for pose in range(POSES):
        sprites, gs = receta(rom, pose)
        if not 4 <= len(sprites) <= 6:
            continue
        if any(not (ORG <= g < ORG + len(rom)) for g in gs):
            continue
        if any(c > 0x0F for _dy, _dx, c in sprites):
            continue
        if any(abs(dy) > 40 or abs(dx) > 40 for dy, dx, _c in sprites):
            continue
        # una pose de verdad reparte cabeza, torso y piernas: si todos sus
        # sprites caen en la misma franja de 16 pixeles no es una figura
        if max(dy for dy, _dx, _c in sprites) -                 min(dy for dy, _dx, _c in sprites) < 16:
            continue
        buenas.append(pose)
    return buenas


def receta(rom, pose):
    """Desmenuza la receta de una pose.

    Devuelve (sprites, guiones): los sprites son ternas (dy, dx, color) en el
    orden en que se escriben, y los guiones las direcciones que hay que
    encadenar para dejar los seis patrones como toca.
    """
    hl = _w(rom, TABLA_DE_RECETAS + 2 * pose)
    # 0x4fec: el campo 0x7-, opcional
    if (_b(rom, hl) & 0xF0) == 0x70:
        hl += 1
    # 0x4fff: el campo 0x8-, opcional
    if (_b(rom, hl) & 0xF0) == 0x80:
        hl += 1
    # 0x500b: la terna que se suma a la X
    hl += 3
    # 0x501b: con 0xE162 a cero -mirando a la derecha- el `jr z` de 0x501f va
    # a 0x5061 SIN gastar nada mas, y la lista de sprites empieza justo aqui.
    # Solo el camino espejado lee dos bytes de puntero en este mismo sitio.
    sprites = []
    while True:
        campo = _b(rom, hl)
        if (campo & 0xF0) == 0x80:
            break
        dy = campo
        dx = _b(rom, hl + 1)
        hl += 2
        if (_b(rom, hl) & 0xF0) == 0xF0:    # la X del golpe, opcional
            hl += 1
        patron = _b(rom, hl)                 # el patron, que el bucle se salta
        hl += 1
        color = _b(rom, hl)
        hl += 1
        sprites.append((dy - 256 if dy > 127 else dy,
                        dx - 256 if dx > 127 else dx, color))
    # el nibble bajo del 0x8- dice cuantos guiones vienen detras
    cuantos = _b(rom, hl) & 0x0F
    hl += 1
    lista = []
    for _ in range(cuantos):
        lista.append(_w(rom, hl))
        hl += 2
    return sprites, lista


def tabla_de_sprites(rom, pose, base):
    """La tabla de patrones de sprite con los guiones de esta pose encima.

    `base` es la VRAM que deja el montaje de la pantalla de combate, que es
    donde el bucle de 0x4ca2 ha dejado los patrones de partida.
    """
    v = guiones.Vram()
    v.b[:] = base.b[:]
    for g in receta(rom, pose)[1]:
        if ORG <= g < ORG + len(rom) - 2:
            guiones.encadena(rom, g, v)
    return v


def dibuja_pose(rom, pose, base, ancho=48, alto=48):
    """La figura entera de una pose, con sus seis sprites en su sitio."""
    sprites = receta(rom, pose)[0]
    patrones = [_b(rom, PATRONES_DE_ARRANQUE + i) for i in range(6)]
    v = tabla_de_sprites(rom, pose, base)
    dys = [s[0] for s in sprites] or [0]
    dxs = [s[1] for s in sprites] or [0]
    oy = -min(dys) + 2
    ox = -min(dxs) + 2
    img = [[0] * ancho for _ in range(alto)]
    for i, (dy, dx, color) in enumerate(sprites):
        if i >= len(patrones):
            break
        p = patrones[i] & 0xFC
        for k in range(4):
            cx, cy = (8 if k >= 2 else 0), (8 if k % 2 else 0)
            for y in range(8):
                forma = v.b[(SPRITES + p * 8 + k * 8 + y) & 0x3FFF]
                for x in range(8):
                    if (forma >> (7 - x)) & 1:
                        iy, ix = oy + dy + cy + y, ox + dx + cx + x
                        if 0 <= iy < alto and 0 <= ix < ancho:
                            img[iy][ix] = color & 0x0F
    return img


FUENTE_GUION = 0x564E
FUENTE_BASE = 0x2080        # VRAM: el patron 0x10

# OJO: la fuente del cartucho NO trae la J, la Q, la X ni la Z -solo guarda
# las letras que sus propios textos necesitan-, asi que los rotulos de aqui
# estan escritos sin ellas.
TEXTOS = {
    "es": {"titulo": "EL PROTAGONISTA",
           "sub1": "SEIS SPRITES CON PATRONES SIEMPRE IGUALES",
           "sub2": "SOLO CAMBIA DONDE VA CADA UNO",
           "pie": "CADA POSE CON SU NUMERO"},
    "en": {"titulo": "THE PLAYER",
           "sub1": "HE IS 6 SPRITES ALWAYS THE SAME PATTERNS",
           "sub2": "ONLY WHERE EACH ONE GOES CHANGES",
           "pie": "EVERY POSE WITH ITS NUMBER"},
}


def _fuente(rom):
    """La tipografia del cartucho: el guion 0x564e en la VRAM 0x2080, o sea el
    patron 0x10. La 'A' es el 0x21 y siguen seguidas hasta la 'Z' en 0x3a; las
    cifras estan en 0x10-0x19. Lo que caiga fuera no es una letra y no se
    dibuja."""
    v = guiones.Vram()
    v.sitio(FUENTE_BASE)
    guiones.cuerpo(rom, FUENTE_GUION, v)
    return v


def escribe(img, fuente, texto, x, y, tinta=15):
    for i, ch in enumerate(texto):
        code = (ord(ch) - 0x20) & 0xFF
        if not (0x10 <= code <= 0x19 or 0x21 <= code <= 0x3A):
            continue
        base = 0x2000 + code * 8
        for fy in range(8):
            b = fuente.b[base + fy]
            for fx in range(8):
                if (b >> (7 - fx)) & 1:
                    iy, ix = y + fy, x + i * 8 + fx
                    if 0 <= iy < len(img) and 0 <= ix < len(img[0]):
                        img[iy][ix] = tinta


def lamina(rom, base, idioma="es"):
    """Las poses legibles, en cuadricula, con su numero debajo."""
    T = TEXTOS[idioma]
    fuente = _fuente(rom)
    poses = poses_legibles(rom)
    celda_an, celda_al = 48, 56
    cols = 7
    filas = (len(poses) + cols - 1) // cols
    ancho = cols * celda_an + 16
    alto = 34 + filas * celda_al + 20
    img = [[1] * ancho for _ in range(alto)]
    escribe(img, fuente, T["titulo"], 8, 6, 10)
    escribe(img, fuente, T["sub1"], 8, 16, 14)
    escribe(img, fuente, T["sub2"], 8, 25, 14)
    for i, pose in enumerate(poses):
        fig = dibuja_pose(rom, pose, base, celda_an, celda_al - 12)
        y0 = 34 + (i // cols) * celda_al
        x0 = 8 + (i % cols) * celda_an
        for y, fila in enumerate(fig):
            for x, c in enumerate(fila):
                if c:
                    img[y0 + y][x0 + x] = c
        escribe(img, fuente, "%02d" % pose, x0 + 14, y0 + celda_al - 11, 14)
    escribe(img, fuente, T["pie"], 8, alto - 12, 14)
    return img


def comprueba(rom, base, carpeta):
    """Compara los desplazamientos y colores calculados con los de la SAT real.

    De cada volcado se cogen los seis sprites del luchador -los que llevan los
    patrones 0x04 a 0x18- y se miran sus posiciones RELATIVAS al primero. Si
    alguna receta calculada coincide con esa firma, la pose esta reconocida.
    """
    import glob
    firmas = {}
    for pose in range(POSES):
        sprites = receta(rom, pose)[0]
        if not sprites:
            continue
        y0, x0 = sprites[0][0], sprites[0][1]
        firmas.setdefault(
            tuple((dy - y0, dx - x0, c & 0x0F) for dy, dx, c in sprites),
            []).append(pose)
    vistos = reconocidos = 0
    for fn in sorted(glob.glob(os.path.join(carpeta, "sat_*.txt"))):
        # el luchador ocupa los sprites 5 a 10 de la tabla: la receta escribe
        # desde 0xE0c4, y el buffer empieza en 0xE0b0, o sea 0xE0b0 + 5*4
        filas = []
        for linea in open(fn).read().splitlines()[1:]:
            p = linea.split()
            if not 5 <= int(p[0]) <= 10:
                continue
            y, x, patron, color = [int(v, 16) for v in p[1:]]
            if y in (0xD0, 0xE0):      # sprite aparcado: la receta acabo antes
                continue
            filas.append((y, x, patron, color))
        if not 4 <= len(filas) <= 6:
            continue
        vistos += 1
        y0, x0 = filas[0][0], filas[0][1]
        firma = tuple((y - y0, x - x0, c & 0x0F) for y, x, _p, c in filas)
        quien = firmas.get(firma)
        print("  %-12s %s" % (os.path.basename(fn),
                              "pose %s" % quien if quien
                              else "SIN RECONOCER %s" % (firma,)))
        reconocidos += 1 if quien else 0
    print("%d volcados con el luchador entero, %d reconocidos"
          % (vistos, reconocidos))
    return 0 if vistos and reconocidos == vistos else 1


def main():
    import pantallas
    rom = open(sys.argv[1], "rb").read()
    base = pantallas.combate(rom, 0)
    if "--comprueba" in sys.argv:
        return comprueba(rom, base,
                         sys.argv[sys.argv.index("--comprueba") + 1])
    carpeta = sys.argv[2]
    os.makedirs(carpeta, exist_ok=True)
    for idioma in TEXTOS:
        img = lamina(rom, base, idioma)
        nombre = ("protagonista.png" if idioma == "es"
                  else "protagonista_%s.png" % idioma)
        pantallas.png(os.path.join(carpeta, nombre), img, 3)
        print("  %s (%d poses)" % (nombre, len(poses_legibles(rom))))
    return 0


if __name__ == "__main__":
    sys.exit(main())
