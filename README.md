# Yie Ar Kung-Fu (Konami, RC-725) — a commented disassembly

A commented disassembly of the 16 KB MSX cartridge, reproducible byte for byte.

**[Read the work →](https://antxiko.github.io/YieArKungFu-disassembly/)**
· [En castellano](README.es.md)

    make            # traces, builds the listing, reassembles it and runs the tests
    make verify     # the test that settles it: reassembling must give the ROM back
    make sanity     # that not a byte is left unexplained
    make densidad   # how much is commented, routine by routine
    make web        # rebuilds the site

The ROM is **not distributed here**. Put your own dump in the root as
`yiear.rom`, 16384 bytes, sha256

    644c78c7d20bb30802888b513b384cf0ce4f9d8b6fd490f30e6211ac92274848

`make comprueba` checks it.

Two dumps of this cartridge circulate. The listing is the *easy* one, the hash
above; if you have the *hard* one too, put it in as `yiear_hard.rom` and
`tools/coteja_builds.py` will compare them.

## Where it stands

| | |
|---|---|
| reassembles byte for byte | yes |
| bytes explained | 16,384 of 16,384 (100%) |
| traced code | 7,494 bytes |
| identified data | 8,890 bytes across 253 named ranges |
| commented | 1707 line comments, 44.0% |
| routines below 10% | 0 of 568 |

The annotations live apart from the listing, anchored to the address they
describe, so they survive a retrace. What is in the `.notes`:

| | |
|---|---|
| named labels | 569 |
| anchored comments | 1707 |
| explained data ranges | 253 |

And the pictures on the site are not captures: Python paints them by running the
same interpreters the Z80 runs, and they are checked against openMSX's VRAM with
**zero differences in the colour table and zero in the pattern table**, 12,288
bytes.

## What is here

- `src/yiear.asm` — the listing; generated, not hand-written
- `src/yiear.notes` — the annotations, anchored to addresses
- `src/yiear.entries` — the entry points and the fifteen dispatch tables, each
  one justified
- `docs/` — the site, in English and Spanish
- `tools/` — the tracer, the listing builder, the two screen interpreters that
  draw the pictures from the ROM, and the collator for the two builds

## The work

| | |
|---|---|
| [Getting started](docs/GETTING-STARTED.md) | what you need and what each command does |
| [The game](docs/THE-GAME.md) | the five opponents, the five strikes and what each is worth |
| [The cartridge](docs/THE-CARTRIDGE.md) | the header, the two drawing interpreters and the alphabet that is not ASCII |
| [The code](docs/THE-CODE.md) | everything inside the interrupt, the pose recipes and the sound engine |
| [Findings](docs/FINDINGS.md) | the two builds collated, the 0x78 proof and the jump into mid-instruction |
| [In the emulator](docs/IN-THE-EMULATOR.md) | how the drawings are checked against the real VRAM |
| [Open questions](docs/OPEN-QUESTIONS.md) | what is not settled |

## What stands out most

- The **two builds** differ in 95.3% of their bytes and share **97.0% of their
  instructions**. What actually changes is five constants and two masks the hard
  build makes **depend on the level**: at the highest one the opponent reacts
  four times as often.
- **Only the hard build carries Konami's hidden mark** — the RC-725 and the
  katakana title Manuel Pazos found. The easy one has the title in Latin ASCII
  there instead, which nothing reads.
- The **temple backdrop** is not in the pattern table: a script writes it as
  tiles into the **name** table, the only long script in the cartridge that does
  that.
- The player is drawn with **sprites** and the opponent with **tiles**, which is
  why the cartridge stores every opponent tile twice, in place and **0x78
  further on** mirrored.
- A `jr z` that lands **inside another instruction** and runs the high byte of an
  address as if it were an `ld b,(hl)`, to save two bytes.

## Licence

The tools, the comments and the documentation, [MIT](LICENSE). The game is not:
its code, graphics and sounds still belong to their authors and to Konami. Read
the [legal notice](LEGAL-NOTICE.md).
