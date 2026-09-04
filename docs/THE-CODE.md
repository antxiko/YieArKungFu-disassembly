# The code

## Everything happens inside the interrupt

INIT (0x4010) hooks the handler by hand: it puts a `0xC3` — a `jp` — into
H.KEYI (0xFD9A) with the address 0x4043 behind it, leaves the stack at 0xE400,
clears 0xE000–0xE3FF with an `ldir`, loads the graphics and settles into a jump
to itself. From there on **the whole game runs inside the interrupt**.

The handler at 0x4043 reads the VDP status, gives the sound engine a frame, and
with the latch at 0xE006 open reads the controls and does the game frame. On the
way out it looks at the status again: if another interrupt is pending, it gives
sound another frame.

## The scene dispatch

0xE000 is the **scene** — 0 to 8, the table at 0x409F — and 0xE001 the **step**
within it. Every scene starts with a chain of `djnz`, which is the shortest way
there is to write a `switch`: B comes in holding the step, and each `djnz` takes
one off it and jumps if it has not reached zero yet.

Scene 0 is the title screen: step 0 builds the whole screen, step 1 draws VIDEO
CARTRIDGE, step 2 erases it and step 3 paints the logo and the PUSH SPACE KEY.

## The controls

The joystick and the keyboard are read separately and joined with an `or`, so it
does not matter which you play with. The point is that both end up in the same
bit layout, the PSG's port A:

    bit 0  up           bit 3  right
    bit 1  down         bit 4  trigger A
    bit 2  left         bit 5  trigger B

Getting there from the keyboard takes **five chained rotations**, which is what
0x453F does. That all five line up is not a guess: with the MSX matrix's normal
arrangement — row 8 with SPACE at bit 0, LEFT at 4, UP at 5, DOWN at 6 and RIGHT
at 7 — each `and` lands exactly where it should.

With bit 6 of 0xE002 clear nobody is playing and 0x4564 makes the controls up:
that is how the attract sequence runs, stepping through the list at 0x55DE one
position every 0x20 frames.

## How the player is built

The player is made of **sprites**. 0x4FBE spreads the six patterns at 0x50A6
across the pattern field of the first six sprites — two at a time, so as not to
touch coordinates or colour — and then runs whichever recipe 0xE154 picks from
the table at 0x50AC.

A recipe is a run of fields with the **high nibble as the marker**:

| marker | what it does |
|---|---|
| 0x7- | the low nibble goes to 0xE174, the bitmap the strikes consult |
| 0x8- | the low nibble goes to 0xE172, the pose the strike is checked with; and mid-loop, it closes the list |
| 0xF- | the low nibble is used to work out the strike's X, 0xE171 |
| rest | sprite bytes: the first adds into the Y and the second into the X |

And there are **two bodies**, not one. Facing right it uses 0x5064, which adds
straight. Facing left, 0x5021 reads a pointer to another recipe out of the data
itself and runs 0x5028, which also **mirrors** the second coordinate with
`ld a,010h / add a,(hl) / neg / add a,b`.

## How the opponent is built

The opponent is made of **tiles**. 0x5374 writes tile numbers into the name
table: it walks down to the row 0xE182 says, places the column with 0xE183 and
copies the block row by row with LDIRVM.

What is unusual about it are the sums from 0x5387 to 0x53C1, which **clip**: if
the figure runs off the left or the right of the thirty-two columns, the width
is shortened and the source moved on, rather than drawing over the next row.

And the poses come compressed. 0x541D decompresses them into 0xE280 with three
commands — `0xF-` for consecutive tiles, `0xE-` for gaps and any other byte for
a single tile — and, if the pose is odd, 0x5454 writes them out again backwards
into 0xE2D0, swapping each tile for its twin.

## The hit boxes

0x52F5 takes four bytes from the opponent's recipe, adds the X at 0xE16E to each
and writes a **pair** into 0xE198: the value, and the value plus 10, plus 8,
plus 6 and plus 6. Four horizontal bands, each with its start and its end, from
widest to narrowest.

And 0x4A0F is what uses them: it takes the strike's X from 0xE171 and sees if it
falls inside one. Before that there are three cut-offs — the bit of 0xE173 that
matches the pose, the opponent's pose not being 0x0E or above, and the player's
Y having reached 0x72.

The strike's height is kept separately, in the table at 0x4B54: three values,
0x84, 0x91 and 0x9F — high, middle and low.

## The sound engine

Three voices, with the channel table in RAM and **eight bytes per channel**.
There are two areas: 0xE01A for music and 0xE032 for effects, and the tune number
decides which — below 8 it is an effect, from 8 up music, and from 0x0C up it
uses three channels instead of two.

The number's six low bits index the pointer table at 0x7DB6, which has
twenty-one entries. The first points nowhere, so the useful range runs 1 to 20,
and those twenty go to **sixteen distinct tunes**: several share the one at
0x7FEF, which is a single 0xFF — the tune that does not sound.

There are two tune formats. The short one carries duration, envelope and notes.
The long one, used when bit 7 of the number is set, adds the duration unit, the
decay, the **octave** and the semitone.

**The notes.** The table at 0x7DAC holds ten values: 106, 100, 95, 89, 84, 80,
75, 71, 67 and 63. The ratio between each and the next is 1.06, which is exactly
the semitone's (2 to the power 1/12 = 1.0595): they are **ten consecutive
semitones**. And they are a PSG **divider**, not a speed and not a frequency:
the lower the value, the higher the note. The octave is applied by doubling the
divider, which drops it an octave each time.

**Priority.** When 0x7BCC is entered with D at zero — which is how the whole
game enters — the tune plays, no questions asked. But from inside the engine
itself it is entered with D = 1, and then 0x7BF3 compares against what is already
playing on that channel and **does not overwrite it** if the current one is equal
or higher.
