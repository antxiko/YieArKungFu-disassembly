# Findings

Everything here is measured against the binary. Where there is a number, there
is a tool in the repository that produces it.

## The two builds are the same program

Byte for byte, the easy build and the hard one differ in **15,618 of 16,384
bytes**, 95.3%. That number is worth nothing: both are **relocated**, and one
byte more in one place shifts everything behind it, and with it every absolute
address.

`tools/coteja_builds.py` walks both instruction by instruction with the Z80's
length table and replaces with a wildcard every 16-bit operand that falls inside
the cartridge — which is exactly what relocation moves. On that footing they
share **3,798 of the easy build's 3,917** instructions, **97.0%**.

The constants that are **not** masked are what confirms the result: a RAM
address like 0xE000 or a value like 0x0080 does not shift, and they still match.

## What actually changes: a fixed mask that becomes variable

The easy build lets one frame in 64 and one in 32 through with masks written
into the code:

    0x74b6   ld a,(0e003h) / and 03fh / ret nz
    0x77df   ld hl,0e003h / ld a,(hl) / and 03eh / ret nz

In the hard build, at those two exact spots, these eight instructions go in
front — and they **appear nowhere at all** in the easy one, searched across all
16,384 bytes:

    ld b,03eh
    ld a,(0e056h)
    and a
    jr z,+7
    ld b,01eh
    dec a
    jr z,+2
    ld b,00eh

and the `and 03fh` becomes an `and b`. The mask is no longer fixed: 0xE056, the
level, picks it. With 0x3E the condition is met once every 32 frames, with 0x1E
once every 16 and with 0x0E once every 8. At the highest level the opponent
reacts **four times as often**, and in the easy build that never happens.

The rest is **five constants**, all of the third opponent's long weapon:

    0x70e3   ld a,012h  ->  ld a,016h    the duration, 18 frames to 22
    0x7104   cp 008h    ->  cp 00ah      it grows to 10 instead of 8
    0x7109   cp 007h    ->  cp 009h      and the other branch's cap likewise
    0x77ec   bit 6,a    ->  bit 7,a      a different bit of the datum
    0x77ee   ld a,001h  ->  ld a,000h    and the value the other way round

Plus one change of form: the three height thresholds at 0x4AAF, which in the
easy build are three inline `cp`s — 0x86, 0x7C, 0x73 — come out into a
three-byte table in the hard one, `72 7C 86`, with the first changed from 0x73
to 0x72.

## Only one of the two carries Konami's hidden mark

Konami hid its catalogue number and the title in katakana at the end of many
cartridges; **Manuel Pazos**
([@ManuelPazosMSX](https://twitter.com/ManuelPazosMSX)) found it.

`tools/busca_marca_konami.py` hunts for it across the whole ROM, not just in the
usual place. The **hard** build **has it**: **RC-725** and the title in katakana,
ten bytes closing on 0x7FFF.

The **easy** build **does not**. In that same gap, the last sixteen bytes are

    59 49 45 20 41 52 20 4B 55 4E 47 20 46 55 FF FF        YIE AR KUNG FU

in **Latin ASCII**, and nothing reads it: the cartridge cannot read ASCII,
because its alphabet starts A at tile 0x21.

What that says about which came first, or where either came from, **the binary
does not tell**, and it is not assumed here.

## The temple backdrop is in the name table

Of the cartridge's fourteen long scripts, **only one writes at 0x3800**: the one
at 0x5DA4. And what it puts there, in 327 bytes, is the whole temple — the
columns, the lanterns, the two-kanji sign, the gong, the windows and the brick
floor.

It is the only long script that goes to neither patterns nor colour. The other
thirteen fill the pattern and colour tables with the tiles this one uses.

## The tables that looked like five stages are the five opponents

The tables at 0x4B9C and 0x4BA6 give a pattern script and a colour script per
value of 0xE054, and they are drawn while the screen is being built, so they look
like five different backdrops. They are not, and three measurements say so:

1. Building the screen with all five and comparing them, some **4,000 bytes of
   VRAM** change, but **none of the tiles that change is in use** in the
   backdrop's name table. The temple looks identical with all five.
2. They are drawn at VRAM 0x2880, which is tiles 0x10 to 0x48 of the **second
   and third thirds**, the bottom half of the screen — and over the font, which
   is not needed there because the scoreboard is right at the top.
3. And above all: 0x4C3E copies those same tiles **mirrored** to 0x88 upwards,
   which are exactly the ones the name table uses to paint the opponent. A
   backdrop does not need a mirrored version; a fighter who can face both ways
   does.

## The 0x78 proof

The MSX cannot mirror a sprite or a tile, so a fighter who faces both ways needs
both versions stored.

0x4C3E copies the opponent's tiles from VRAM 0x2880 to 0x2440 flipping every
byte: from tile **0x10** to **0x88**, that is **0x78 further on**.

And the pose decompressor, when it has to mirror a block (0x5454), swaps each
tile for its twin by **adding 0x78** — and subtracting it from those 0x88 and
up. The two halves of the same trick, 10 KB apart.

One detail of that loop, which cost a wrong render before the VRAM comparison
caught it: in 0x4C46 **the source does not advance**, only the destination. Each
turn the cartridge does `pop de / ld hl,00800h / add hl,de / ex de,hl / pop hl`,
which adds 0x800 to the destination and recovers the starting HL, so all three
thirds get the same mirrored copy of 0x2880.

## The same twelve-byte caption, two different prizes

The list at 0x47CC reads **PERFECT 3000** and is drawn on row 16 column 10
through the normal door, 0x449E, which reads its first two bytes as a VRAM
address.

But 0x48AD comes in through 0x449A, which **reads no address**, with DE at
0x47CE — two bytes further on, skipping exactly that address — and HL at VRAM
0x388A, row 4. And right after, 0x48B2 writes tile **0x15**, the digit 5, into
VRAM 0x3892, which is the ninth letter: where it said 3 it now says 5.

The caption now reads **PERFECT 5000**, and what is added is 0x5000 in BCD.
Twelve bytes of text for two prizes.

## Each of the fighter's figures carries its destination in front

The thirteen scripts from 0x596F to 0x5D02 run back to back without a single
dead byte, but the table at 0x4CF0 does not point at the start of each one: it
points **two bytes further on**. Those two bytes are a VRAM address, and in all
thirteen it lands in 0x1820–0x18A0.

It is not a misalignment: the cartridge draws these same scripts two ways.

- The loop at 0x4CA4 comes in through 0x4452, which wants the destination in HL
  and gets it from the table at 0x4D0A. That is why it starts reading past the
  two bytes.
- The loop at 0x5098 comes in through 0x4423, which is the body of command 0x80:
  it **reads the destination out of the script itself**. That is why it starts
  two bytes earlier.

A count proves it: **twenty-four** of the words in the recipe block
0x50A6–0x5254 equal exactly one of those thirteen addresses minus two, and
**none** equals one of the thirteen in the table.

## One entry too many put 178 bytes of rubbish in the listing

The rule for how many entries a pointer table has — read words while they land
inside the cartridge — gives **six** for the one at 0x6B4B. There are **five**:
the sixth, 0x583A, falls inside the script 0x43F6 draws, and following it as
code filled the listing with `rst 18h` and `sbc a,a`.

Five is what the index says: 0x6B42 reads 0xE054, the opponent, and there are
five of those. And the proof that the table ends at 0x6B55 is that **0x4182 does
`call 0x6b55`** and 0x42E6 a `jp 0x6b55`: code that is called by name starts
there.

## A jump that lands inside another instruction

The `jr z` at 0x4625 has the bytes `28 08`, displacement 8, and jumps to
**0x462F**. And 0x462F is not the start of any instruction: it is the **third
byte** of the `jp 0x46cf` that begins at 0x462D.

    462d  C3 CF 46     jp 0x46cf
    4630  CD 05 6B     call 0x6b05

Landing at 0x462F, the Z80 finds byte **0x46** on its own and runs it for what
it is: `ld b,(hl)`, a one-byte instruction that only loads B. And straight after
it falls into the `call` at 0x4630, which is where it wanted to go. The high
byte of an address doing duty as a filler instruction, and two bytes saved.

That this is so and not a tracing slip is settled by the displacement: it is
**0x08 and not 0x09**, which is what landing cleanly on 0x4630 would need.

## The randomness is a ten-byte register with a fixed seed

0x6D2C runs a **ten-byte** shift register, 0xE135 to 0xE13E: it takes the bit off
the top of 0xE13E with `srl`, drags it through the nine below with `rr` and feeds
it back in at the top, twice per call. It returns the two low bits, a number from
0 to 3.

The seed is the ten bytes 0x5295 copies when the round starts, and there are
**four different sets** at 0x52CD picked by 0xE056. With that the opponent does
not repeat but does not depend on anything outside either: the same play gives
the same match, which is exactly what you need to be able to check it.

## Three pieces of code nothing reaches

Twenty-six bytes at 0x73B3, three at 0x73DF and eight at 0x74AE decode as
coherent Z80 code — the first is `call 0x7399 / ld hl,0e003h / ld a,(0e165h)…`.
Nothing reaches them, and that is not an impression: `tools/apunta_a.py` searches
for the 16-bit word across **all 16,384 bytes** of the cartridge, not just the
listing, and no address falls inside.

In front of all three there is a jump that steps over them. The one at 0x73B1 is
a `jr` of 0x48 that lands at 0x73FB, clearing all twenty-six bytes in one go.

## Two inherited comments the binary contradicted

Commenting turns up mistakes that are already written down. Two that came out on
this pass:

- `copia_256_a_vram` **does not copy 256 bytes**. What 0x441D does is zero the
  **high** byte of the count and leave the low one as it comes, so it copies
  whatever C the caller brings. It would be 256 only if C came in at zero, and
  the only caller brings in C the width of the row it is drawing.
- **0xE160 is the Y coordinate**, not a distance. What settles it is that 0x5064
  adds it into the **first** byte of each sprite, which on the TMS9918 is the Y.
  It also fits with the jump curve adding into it and with its resting value
  being 0x87, that is 135, the floor line.
