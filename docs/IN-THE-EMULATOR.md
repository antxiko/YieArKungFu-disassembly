# In the emulator

The pictures on this site are not captures: `tools/pantallas.py` builds them by
running in Python the cartridge's own steps. Looking at them is not enough to
take them on trust, so they are compared **byte for byte** with the real VRAM.

## How the real VRAM is taken

`tools/omsx_vram.tcl` lets the game run in openMSX and, at several points, dumps
the 16 KB of VRAM, the eight VDP registers and the variables that say what was
being drawn:

    "C:/Program Files/openMSX/openmsx.exe" -machine Philips_VG_8020 \
        -cart yiear.rom -script tools/omsx_vram.tcl

It sets no breakpoints. The whole game runs inside the interrupt at 0x4043 and a
`bp` there drowns the emulator, so the dumps go by emulated clock. It also
carries a real-time watchdog: a broken script cannot hang the emulator
indefinitely.

## The result

Comparing the VRAM `pantallas.py` builds with the one openMSX holds 120 seconds
into a game:

| table | bytes | differing |
|---|---|---|
| COLOUR (0x0000–0x17FF) | 6,144 | **0** |
| PATTERNS (0x2000–0x37FF) | 6,144 | **0** |
| NAMES (0x3800–0x3AFF) | 768 | 43 |
| SPRITE PATTERNS (0x1800–0x1FFF) | 2,048 | 520 |

The two big tables come out **exact**. What does not match is what the game
rewrites every frame and the build has no business placing:

- in the name table, the scoreboard figures, the opponent's name and the tiles
  the fighter is drawn with at that instant;
- in the sprite patterns, the player's pose for that frame, redrawn over the
  figures the startup left there.

## The buffer trap

The sprite patterns and part of the tiles are reused several times per frame. If
a dump comes out "all different except one thing", the fault is not the format:
it is the **moment** it was taken.

That is why the dump worth comparing is one taken with the fight running and
settled, not one from the startup or from a transition between scenes.

## A mistake only the comparison caught

The mirror loop at 0x4C46 was read at first as though the source advanced a
third each turn. The renders came out plausible — a temple showed up — and only
the VRAM comparison brought it down: **the source does not advance**, and each
turn the cartridge does `pop de / ld hl,00800h / add hl,de / ex de,hl / pop hl`,
which adds 0x800 to the **destination** and recovers the starting HL.

With that fixed, the pattern table went from 776 differing bytes to **zero**.
