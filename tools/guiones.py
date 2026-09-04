#!/usr/bin/env python3
"""El interprete de guiones del cartucho, rehecho en Python.

Yie Ar Kung-Fu no guarda las pantallas como un volcado de VRAM: las guarda
como GUIONES, tiras de ordenes que el interprete de 0x442c va ejecutando
contra el puerto de datos del VDP. Este fichero reproduce ese interprete paso
a paso, para poder (a) saber DONDE ACABA cada guion -que es lo que el
presupuesto de bytes necesita- y (b) reconstruir la VRAM que dejan, que es de
donde salen los dibujos de la web.

EL LENGUAJE, tal como lo ejecuta 0x442c:

    0x00          fin del guion.
    0x80          encadena: los DOS bytes siguientes son una direccion de
                  VRAM nueva, BYTE BAJO PRIMERO, y se sigue dibujando ahi.
    n (bit 7 a 0) relleno: el byte siguiente, repetido n veces.
    n (bit 7 a 1) copia cruda de (n and 0x7F) bytes.

Es EXACTAMENTE el de King's Valley: mismo cuerpo y mismo orden de bytes en la
direccion. Konami's Baseball, que es de 1984, tiene ademas un comando 0x01 y
encadena con el byte alto primero; los dos cartuchos de 1985 -este y King's
Valley- no. Leer uno con el orden del otro da ruido.

La direccion se guarda tal como se la pasan a SETWRT, o sea con basura en los
dos bits altos -la BIOS hace (H and 0x3F) or 0x40-, asi que aqui se enmascara
igual, con 0x3FFF.
"""
ORG = 0x4000


class Vram:
    """Los 16 KB de VRAM, y por donde va el puntero de escritura."""

    def __init__(self):
        self.b = bytearray(0x4000)
        self.p = 0
        self.tocado = bytearray(0x4000)

    def sitio(self, dir_):
        self.p = dir_ & 0x3FFF

    def escribe(self, v):
        self.b[self.p] = v
        self.tocado[self.p] = 1
        self.p = (self.p + 1) & 0x3FFF


def _b(rom, a):
    return rom[a - ORG]


def encadena(rom, pos, vram=None):
    """El 0x80 y la entrada por 0x4423: direccion de VRAM y a dibujar."""
    dir_ = _b(rom, pos) | (_b(rom, pos + 1) << 8)
    if vram is not None:
        vram.sitio(dir_)
    return cuerpo(rom, pos + 2, vram)


def cuerpo(rom, pos, vram=None):
    """El cuerpo de 0x442c. Devuelve la posicion tras el ultimo byte."""
    while True:
        cmd = _b(rom, pos)
        pos += 1

        cuenta = cmd & 0x7F
        if cuenta == 0:
            if cmd == 0x00:                                  # fin del guion
                return pos
            return encadena(rom, pos, vram)                  # 0x80: encadena

        if cmd == cuenta:                                    # bit 7 a 0
            val = _b(rom, pos)
            pos += 1
            if vram is not None:
                for _ in range(cuenta):
                    vram.escribe(val)
        else:                                                # bit 7 a 1
            if vram is not None:
                for i in range(cuenta):
                    vram.escribe(_b(rom, pos + i))
            pos += cuenta


def replica(vram, origen, destino, cuenta=0x0FFF):
    """Copia VRAM a VRAM byte a byte, con los rangos SOLAPADOS.

    El truco del cartucho para llenar SCREEN 2 con un solo tercio de datos.
    Como el origen alcanza al destino a mitad de camino, lo que ya se escribio
    se vuelve a leer y el primer tercio acaba repetido en los otros dos. Se
    copia byte a byte, no de golpe, precisamente porque el solape es el efecto
    que se busca.
    """
    o, d = origen & 0x3FFF, destino & 0x3FFF
    for _ in range(cuenta):
        vram.b[d] = vram.b[o]
        vram.tocado[d] = 1
        o = (o + 1) & 0x3FFF
        d = (d + 1) & 0x3FFF


def borra_tabla_de_nombres(vram, dir_=0x7800):
    """Las 768 posiciones de la tabla de nombres a cero."""
    p = dir_ & 0x3FFF
    for i in range(768):
        vram.b[(p + i) & 0x3FFF] = 0
        vram.tocado[(p + i) & 0x3FFF] = 1


def tiles_correlativos(vram, dir_, primero, cuantos):
    """n tiles correlativos en una fila, y devuelve la fila de abajo."""
    p = dir_ & 0x3FFF
    for i in range(cuantos):
        vram.b[(p + i) & 0x3FFF] = (primero + i) & 0xFF
        vram.tocado[(p + i) & 0x3FFF] = 1
    return dir_ + 0x20
