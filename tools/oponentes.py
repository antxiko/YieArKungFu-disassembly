#!/usr/bin/env python3
"""Monta las figuras de los CINCO OPONENTES, pose a pose.

Los oponentes no son sprites: son tiles escritos en la tabla de nombres. Cada
pose es un RECTANGULO de alto x ancho tiles, y sus tiles vienen COMPRIMIDOS
dentro del propio bloque de pose. Publicarlos en una rejilla de anchura fija
-cuatro por fila, como se hizo hasta el 2026-09-04- parte todas las poses,
porque cada una tiene su propia anchura.

EL BLOQUE DE POSE
-----------------
La tabla de 0x555c da cinco punteros, uno por oponente (0xE054), y cada uno es
otra tabla indexada por la pose (0xE184). Lo que hay en el bloque, leido de
monta_las_cajas_de_golpe (0x52f5) y de lo que sigue:

    +0..+3   las cuatro cajas de golpe (anchuras 10, 8, 6 y 6)
    +4       la COLUMNA, que se suma a (0xE181)
    +5       la FILA, que se suma a (0xE180)
    [0x7n]   opcional -> 0xE173
    [0x8n]   opcional -> 0xE1b1, y entonces UN byte mas -> 0xE1b0
    +n       ALTO en tiles
    +n+1     ANCHO en tiles
    ...      los tiles, comprimidos

EL DESCOMPRESOR (0x541d, `el_descompresor` en el listado)
---------------------------------------------------------
Saca alto x ancho tiles y para en cuanto los tiene. Tres comandos:

    0xFn  n tiles CORRELATIVOS: el byte siguiente es el primero y de ahi
          para arriba
    0xEn  n HUECOS (tile 0x00)
    otro  un tile suelto, copiado tal cual

La pose de reposo de WANG es `00 10 E3 FF 11`: un hueco, la cabeza, tres
huecos y quince tiles correlativos desde el 0x11. Veinte tiles, que es
exactamente 5 x 4.

COMPROBADO CONTRA LA MAQUINA
----------------------------
tools/omsx_nombres.tcl y tools/omsx_oponentes.tcl vuelcan la tabla de nombres
durante un combate de verdad. `oponentes.py --comprueba` busca en cada volcado
la figura del oponente y comprueba que alguna de las poses calculadas aqui la
reproduce tile a tile.

Uso: oponentes.py <rom> <carpeta> [--comprueba <carpeta de volcados>]
"""
import os
import sys

import guiones
import pantallas

ORG = 0x4000
TABLA_POR_OPONENTE = 0x555C
NOMBRES = 0x3800
NOMBRE = ("WANG", "TAO", "CHEN", "LANG", "WU")


def _b(rom, a):
    return rom[a - ORG]


def _w(rom, a):
    return _b(rom, a) | (_b(rom, a + 1) << 8)


def tabla_de_poses(rom, cual):
    """Los punteros de pose de un oponente.

    La tabla acaba justo donde empieza el PRIMERO DE SUS DESTINOS, que no es
    el primer puntero sino el mas bajo de todos. Se calcula leyendo punteros y
    recortando el tope segun va apareciendo un destino mas temprano; asi salen
    las dieciocho de cada uno de los cuatro primeros y las veinte del quinto,
    que es lo que dice el listado.
    """
    base = _w(rom, TABLA_POR_OPONENTE + 2 * cual)
    punteros = []
    tope = base + 2 * 32
    i = base
    while i + 1 < tope:
        d = _w(rom, i)
        if not _dentro(rom, d):
            break
        punteros.append(d)
        tope = min(tope, d)
        i += 2
    return punteros


def _dentro(rom, a):
    return ORG <= a < ORG + len(rom)


def pose(rom, direccion):
    """Un bloque de pose, ya desmenuzado.

    Devuelve (alto, ancho, tiles) con los tiles ya descomprimidos, en orden de
    lectura, o None si el bloque no se lee coherente.
    """
    p = direccion + 4          # las cuatro cajas de golpe
    p += 2                     # la columna y la fila
    if not _dentro(rom, p + 1):
        return None
    if (_b(rom, p) & 0xF0) == 0x70:
        p += 1
    if not _dentro(rom, p):
        return None
    if (_b(rom, p) & 0xF0) == 0x80:
        p += 2                 # el campo y el byte de 0xE1b0 que lo acompana
    if not _dentro(rom, p + 1):
        return None
    alto, ancho = _b(rom, p), _b(rom, p + 1)
    p += 2
    if not (1 <= alto <= 12 and 1 <= ancho <= 12):
        return None
    cuantos = alto * ancho
    tiles = []
    while len(tiles) < cuantos:
        if not (ORG <= p < ORG + len(rom)):
            return None
        cmd = _b(rom, p)
        alto_nibble, cuenta = cmd & 0xF0, cmd & 0x0F
        if alto_nibble == 0xF0:                 # correlativos
            p += 1
            t = _b(rom, p)
            for _ in range(cuenta):
                if len(tiles) >= cuantos:
                    break
                tiles.append(t)
                t = (t + 1) & 0xFF
            p += 1
        elif alto_nibble == 0xE0:               # huecos
            for _ in range(cuenta):
                if len(tiles) >= cuantos:
                    break
                tiles.append(0x00)
            p += 1
        else:                                   # un tile suelto
            tiles.append(cmd)
            p += 1
    return alto, ancho, tiles


def poses_de(rom, cual):
    """Las poses de un oponente que se leen enteras, sin repetir."""
    salida, vistas = [], set()
    for i, d in enumerate(tabla_de_poses(rom, cual)):
        r = pose(rom, d)
        if not r:
            continue
        alto, ancho, tiles = r
        # una pose de verdad usa los tiles de la figura, que empiezan en 0x10
        utiles = [t for t in tiles if t]
        if len(utiles) < 6 or min(utiles) < 0x10:
            continue
        firma = (alto, ancho, tuple(tiles))
        if firma in vistas:
            continue
        vistas.add(firma)
        salida.append((i, alto, ancho, tiles))
    return salida


def dibuja(rom, cual, alto, ancho, tiles, vram=None):
    """La pose, con los tiles de ese oponente y su color."""
    v = vram if vram is not None else pantallas.combate(rom, cual)
    img = [[1] * (ancho * 8) for _ in range(alto * 8)]
    for i, t in enumerate(tiles):
        if not t:
            continue
        f, c = divmod(i, ancho)
        celda = pantallas.tile_pintado(v, 1, t)
        for y in range(8):
            for x in range(8):
                img[f * 8 + y][c * 8 + x] = celda[y][x]
    return img


def comprueba(rom, carpeta):
    """Busca en cada volcado la figura y la casa con alguna pose calculada."""
    import glob
    catalogo = {}
    for cual in range(5):
        for i, alto, ancho, tiles in poses_de(rom, cual):
            catalogo.setdefault(tuple(t for t in tiles if t), []).append(
                (NOMBRE[cual], i))
    vistos = casados = 0
    for fn in sorted(glob.glob(os.path.join(carpeta, "vram_*.bin"))):
        v = open(fn, "rb").read()
        celdas = {}
        for f in range(24):
            for c in range(32):
                t = v[NOMBRES + f * 32 + c]
                if 0x10 <= t < 0x56:
                    celdas[(f, c)] = t
        if not celdas:
            continue
        # la figura del oponente esta en la mitad baja; el marcador, arriba
        celdas = {k: t for k, t in celdas.items() if k[0] >= 14}
        if len(celdas) < 6:
            continue
        vistos += 1
        firma = tuple(t for _k, t in sorted(celdas.items()))
        quien = catalogo.get(firma)
        print("  %-12s %s" % (os.path.basename(fn),
                              quien if quien else "SIN CASAR %s"
                              % (" ".join("%02X" % t for t in firma),)))
        casados += 1 if quien else 0
    print("%d volcados con figura, %d casados con una pose calculada"
          % (vistos, casados))
    return 0 if vistos and casados == vistos else 1


def main():
    rom = open(sys.argv[1], "rb").read()
    if "--comprueba" in sys.argv:
        return comprueba(rom, sys.argv[sys.argv.index("--comprueba") + 1])
    carpeta = sys.argv[2]
    os.makedirs(carpeta, exist_ok=True)
    for cual in range(5):
        v = pantallas.combate(rom, cual)
        poses = poses_de(rom, cual)
        alto = max(a for _i, a, _an, _t in poses)
        ancho = max(an for _i, _a, an, _t in poses)
        lienzos = []
        for _i, a, an, tiles in poses:
            fig = dibuja(rom, cual, a, an, tiles, v)
            marco = [[1] * (ancho * 8) for _ in range(alto * 8)]
            for y, fila in enumerate(fig):
                for x, c in enumerate(fila):
                    marco[y + (alto - a) * 8][x] = c
            lienzos.append(marco)
        salida = os.path.join(carpeta, "oponente_%s.png"
                              % NOMBRE[cual].lower())
        pantallas.png(salida, pantallas.rejilla(lienzos, 8, sep=1), 3)
        print("  oponente_%s.png (%d poses de %dx%d tiles)"
              % (NOMBRE[cual].lower(), len(poses), ancho, alto))
    return 0


if __name__ == "__main__":
    sys.exit(main())
