#!/usr/bin/env python3
"""La musica del cartucho, ejecutando su motor de sonido (ver motor_musica.py).

Pide el sonido con `pon_la_melodia` (0x7BCC, A = numero) y corre
`un_cuadro_de_sonido` (0x7C5C), que la interrupcion llama cada cuadro. Tres
canales de 12 bytes desde 0xE018; la copia del registro 7 del PSG, en 0xE03C.
Uso:  musica.py registros 0x88 [cuadros] | mp3 0x88 f.mp3 | todas docs/audio
      musica.py barrido 0x80 0xBF | emu
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import motor_musica  # noqa: E402
from motor_musica import P  # noqa: E402

TABLA = "ninguna llamada directa: está en la tabla de pistas"

PIEZAS = [
    P(0x88, "La música del combate", "The fight tune",
      "`escena_3_arranca_la_musica`, `escena_4_el_combate`, `premio` y "
      "`apunta_el_enemigo`"),
    P(0x8F, "El final de la partida", "The end of the game",
      "`se_acabo_la_partida`"),
    P(0x8A, "La caída", "The fall", "`modo_3_la_caida_si_no_2`"),
] + [P(n, "Pista 0x%02X de la tabla" % n, "Table track 0x%02X" % n, TABLA)
     for n in (0x89, 0x8B, 0x8D, 0x8E, 0x90, 0x91)]

PAGINA = motor_musica.pagina_basica(
    "`un_cuadro_de_sonido`, 0x7C5C, y `pon_la_melodia`, 0x7BCC, que le "
    "reparte los canales; lo llama la interrupción",
    "`un_cuadro_de_sonido`, 0x7C5C, and `pon_la_melodia`, 0x7BCC, which "
    "hands it the channels; the interrupt calls it",
    "C-BIOS MSX1 japonés",
    [("la música del combate (0x88), tal como el juego la pide, sus primeros "
      "361 y 957 cuadros",
      "the fight tune (0x88), as the game asks for it, its first 361 and 957 "
      "frames"),
     ("el final de la partida (0x8F) entero, 175 cuadros, y la caída (0x8A) "
      "entera, 177, pedidas a la fuerza",
      "the end of the game (0x8F), whole, 175 frames, and the fall (0x8A), "
      "whole, 177, both forced")],
    [("Cómo se pide una pieza",
      "`pon_la_melodia` recibe el número en A, sin mirar prioridad. Los "
      "números bajos son efectos y del 0x88 en adelante hay música. Cada "
      "canal ocupa doce bytes desde 0xE018 y 0xE03C guarda la copia del "
      "mezclador del PSG, que el arranque deja en 0xB8. Las pistas «de la "
      "tabla» están en la tabla de pistas pero ninguna rutina las pide con "
      "un `ld a`. Hay tres piezas cotejadas con openMSX, la 0x88, la 0x8F y la 0x8A; "
      "las demás salen del mismo motor, pero no se ha comparado cada una.",
      "How a piece is asked for",
      "`pon_la_melodia` takes the number in A, without looking at priority. "
      "Low numbers are effects and from 0x88 up there is music. Each channel "
      "takes twelve bytes from 0xE018 and 0xE03C holds the copy of the PSG "
      "mixer, which start-up leaves at 0xB8. The tracks marked «in the "
      "table» are in the track table but no routine asks for them with an "
      "`ld a`. Three pieces have been checked against openMSX, 0x88, 0x8F and 0x8A; "
      "the rest come out of the same engine but each has not been compared.")])

CFG = dict(rom="yiear.rom", org=0x4000, frame=0x7C5C, pide=0x7BCC,
           ram=(0xE018, 0xE03D), ram0=[(0xE03C, 0xB8)],
           excluye=[0xE021, 0xE02D, 0xE039], hz=60, psg0={7: 0xB8},
           piezas=PIEZAS, pagina=PAGINA, cotejado=[(0x88, 1794, 1)])

if __name__ == "__main__":
    sys.exit(motor_musica.main(CFG, sys.argv[1:]))
