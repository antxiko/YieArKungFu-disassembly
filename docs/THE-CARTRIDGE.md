# The cartridge

16,384 bytes in page 1, from 0x4000 to 0x7FFF. The BIOS reads the `AB` header
and calls INIT.

## The header

The first ten bytes are `41 42 10 40 00 00 00 00 00 00`: it declares **only
INIT**, and here INIT sits right against the header, at 0x4010. No STATEMENT, no
DEVICE, no TEXT.

## How the 16,384 bytes are accounted for

| | bytes | |
|---|---|---|
| traced code | 7,494 | 45.7% |
| identified data | 8,890 | 54.3% |
| **unexplained** | **0** | **0.0%** |

`tools/presupuesto.py` counts it, crossing the flow trace with the ranges
declared in the notes. The check is not that the numbers add up: it is that
**every range has a name and an explanation**.

## The VRAM map

The eight values at 0x4503, R0 to R7, are `02 E2 0E 7F 07 76 03 E0`, and the
whole map comes out of them:

| | where | from which register |
|---|---|---|
| COLOUR | 0x0000 | R3 = 0x7F |
| SPRITE PATTERNS | 0x1800 | R6 = 0x03 |
| PATTERNS | 0x2000 | R4 = 0x07 |
| NAMES | 0x3800 | R2 = 0x0E |
| SPRITE ATTRIBUTES | 0x3B00 | R5 = 0x76 |

R3 and R4 **are not addresses**: they are a base bit and a mask. What they say
is colour below and pattern above, the reverse of the usual layout. And R1 =
0xE2, with bit 1 set and bit 0 clear, means **16x16 sprites, unmagnified**.

These eight values are the same as two other cartridges of the same family
except for R7, the border colour.

## The two drawing interpreters

The cartridge does not store VRAM dumps: it stores short programs that get
interpreted. There are two, and it pays not to mix them up.

**SCRIPTS** (the interpreter at 0x442C). They write through the VDP's **data
port**, byte by byte, with two commands:

    0x00           end
    0x80           chain: the next two bytes are a new VRAM address,
                   LOW BYTE FIRST
    n (bit 7 clear)  fill: the next byte, repeated n times
    n (bit 7 set)    raw copy of (n and 0x7F) bytes

**TILE LISTS** (the one at 0x44A6). They write into the **name** table with
WRTVRM, one tile per byte, passing each through a mask that decides whether it
is drawn or erased:

    0xFF   end
    0xFE   chain, the same as the other one's 0x80
    rest   the byte is a tile

And every list begins with its address, because 0x449E — the normal door — only
sets the mask and **falls into** 0x44A0, which is the body of command 0xFE: the
first thing it does is read two bytes. The only entry that skips that is 0x449A.

## The alphabet

It is not ASCII. A is tile **0x21** and on from there to Z at 0x3A; the digits
run 0x10 to 0x19, the space is 0x20 — and 0x00, the blank tile, does the same
job — and the copyright circle is 0x1A.

No need to assume it: KONAMI, PERFECT and GAME OVER read out on their own with
that arrangement and no other alignment gives them.

## The fifteen dispatch tables

The cartridge dispatches two ways. The first, 0x4071, has **the table written
behind the `call` itself**: `pop hl` takes it off the stack, A doubled indexes
into it, and whatever pointer comes out is executed with `jp (hl)`. Since the
return address has been popped, that does not come back.

The second, 0x7375, indexes a table of tables by the opponent and dispatches
whichever comes out.

Without declaring all fifteen the static trace falls well short: the six of the
per-opponent dispatch alone hide **315 bytes of code**.

## The two builds

**There are two different Yie Ar Kung-Fu cartridges**, and they do not play the
same. This is what is in each:

|  | easy | hard |
|---|---|---|
| sha256 | `644c78c7…` | `61c86ad4…` |
| how often the opponent reacts | always **1 frame in 32** | **1 in 32, 16 or 8**, by level |
| CHEN's long weapon | lasts 18 frames, grows to 8 | lasts 22, grows to 10 |
| the three height thresholds | three inline `cp`s | a three-byte table, one value changed |
| Konami's hidden mark | **does not carry it** | **carries it**: RC-725 and the title in katakana |
| this repository | **this is the one disassembled** | collated instruction by instruction |

At the highest level the hard cartridge's opponent reacts **four times as
often** as the easy one's, and on the easy cartridge that never happens at any
level. Everything else is five constants and one change of form.

Byte for byte the two differ in 15,618 of 16,384, 95.3%. That figure means
nothing — both are relocated. By instruction they share **97.0%**. The detail
of every difference is in [Findings](FINDINGS.html), and
`tools/coteja_builds.py` produces it.

