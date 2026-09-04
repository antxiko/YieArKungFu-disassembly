# Getting started

A commented disassembly of **Yie Ar Kung-Fu**, Konami's RC-725 for the MSX, a
16 KB cartridge in page 1 (0x4000–0x7FFF). It reassembles into the exact ROM,
byte for byte, and all 16,384 of its bytes are accounted for.

## The cartridge is not here

No repository distributes the game. Put your own dump in the root as
`yiear.rom`, 16384 bytes, sha256

    644c78c7d20bb30802888b513b384cf0ce4f9d8b6fd490f30e6211ac92274848

`make comprueba` checks it.

Two dumps of this cartridge circulate, which the archives call *easy* and
*hard*. The listing is the easy one, the hash above. If you have the other one
too, put it in as `yiear_hard.rom` and `tools/coteja_builds.py` will compare
them; the result is in [Findings](FINDINGS.html).

## What each command does

    make            traces the flow, builds the listing, reassembles it and runs the tests
    make verify     the test that settles it: reassembling must give the ROM back
    make sanity     that not a byte is left unexplained, and no data comes out as code
    make densidad   how much is commented, routine by routine
    make imagenes   draws the graphic data blocks, so you can look at them
    make web        rebuilds this site from the ROM and the notes

## How it is put together

The listing is not edited by hand: `tools/mkasm.py` generates it from a flow
trace and a file of address-anchored notes, so the comments survive a retrace.
The tracer follows the flow from the entry points; the ones it cannot work out
on its own — the interrupt hook and the fifteen dispatch tables — are declared
in `src/yiear.entries`, each with its justification.

The pictures on the front page are not captures. `tools/pantallas.py` draws them
by running in Python the cartridge's own steps: the script interpreter at
0x442C, the tile-list one at 0x44A6, the fills and the mirror at 0x4C46. And
they are not taken on trust: `tools/omsx_vram.tcl` dumps openMSX's VRAM during a
game and it is compared byte for byte. The colour table comes out with **zero
differences across 6,144 bytes** and the pattern table with **zero across
6,144**.

## The tools

    tools/z80trace.py        the flow trace, with the tables declared
    tools/mkasm.py           the listing, from the trace and the notes
    tools/guiones.py         the script interpreter at 0x442C, in Python
    tools/textos.py          the tile alphabet and the list interpreter
    tools/pantallas.py       the screens, built step by step
    tools/cierra_datos.py    where each block ends, by running its interpreter
    tools/apunta_a.py        who points into a range, searched across all 16 KB
    tools/coteja_builds.py   the two builds, collated by instruction
    tools/presupuesto.py     how the 16,384 bytes are accounted for
    tools/densidad.py        how much is commented, routine by routine
