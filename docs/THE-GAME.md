# The game

Yie Ar Kung-Fu is a one-on-one fighting game: **LEE** against a line of
opponents, each with his own weapon and his own way of moving. Everything that
follows comes from reading the cartridge, not from playing it.

## The five opponents

Their names are at 0x6C35, four tiles each, right-aligned with blank tiles:

| index of 0xE054 | name | figure | tiles |
|---|---|---|---|
| 0 | WANG | scripts 0x5EEB and 0x6172 | 57 |
| 1 | " TAO" | 0x624B and 0x6421 | 67 |
| 2 | CHEN | 0x64BD and 0x669B | 68 |
| 3 | LANG | 0x6724 and 0x68A2 | 52 |
| 4 | "  WU" | 0x68FF and 0x6A9C | 62 |

Each brings **his own pattern script and his own colour script**, and that is
the whole of the difference between one and another on screen: the temple in the
background is the same for all five.

## What the player can do

The state machine at 0x4D24 takes whatever movement the controls bring and
dispatches it through a thirty-two entry table. The movements the code tells
apart:

- **Walking**, two pixels a frame, with the position in 0xE161 between 0x23 and
  0xE0, and two poses alternating every eight frames.
- **Jumping**, with the curve at 0x4DE1 adding into the height: six frames of
  −4, four of −3, two of −2, one of −1 and then the positives. Up fast, a pause
  at the top, and down.
- **Three standing strikes**, each with its pose and its number. The number
  indexes the points table at 0x4B23: **one hundred** for the first and **three
  hundred** for the second and third.
- **The sweep**, which is strike 4.
- **The mid-air strike**, number 5: you have to let go of the button and press
  it again past frame 0x0B of the jump. 0x4E69 checks it, with three chained
  conditions.

## The points

The score is kept in **BCD**, so the values read straight off the code:

| for | how much | where |
|---|---|---|
| strike 1 | 100 | table at 0x4B23 |
| strikes 2 and 3 | 300 | " |
| strikes 4 and 5 | 500 | " |
| each unit of the clock at the end | 200 | 0x488E |
| **PERFECT** on row 16 | **3000** | 0x47C9 |
| **PERFECT** on row 4 | **5000** | 0x48BD |
| each object in the bonus stage | 100 | 0x7BA3 |

The 3000 PERFECT is for finishing the round without being hit. The 5000 one
also requires the clock to be at its cap, 0x24.

## The bonus stage

With 0xE058 set there is no opponent: the frame goes off to 0x79B7, which
releases objects through the three slots at 0xE250 and counts the ones knocked
down in 0xE275, the figure drawn beside the **NUMBER OF HITS** at 0x7BBB.

Which object comes out is decided by the table at 0x7A7C, read **nibble by
nibble**: the two low bits pick the slot and the pattern, bit 2 the height and
the sign of the speed, and bit 3 between two speeds. The X is kept in two bytes
and the speed added with `add` and `adc`, sixteen bits: the lower byte is the
fractional part, so an object can travel slower than one pixel a frame without
the step showing.

## How the opponent decides

He does not move at random, not entirely. 0x5476 measures the gap to the player
and 0x5488 compares it, first against the three bytes the table at 0x54B8 gives
for that opponent and then against three fixed caps — 0x40, 0x48 and 0x68 —,
that is **seven bands**. The band picks the list, and the movement comes out of
the list.

What randomness there is comes from 0x6D2C: a ten-byte shift register with a
fixed seed, returning a number from 0 to 3. Each opponent has five character
routines that share those four values out among four different movements.

## The text it carries inside

With the cartridge's alphabet — A is tile 0x21, the digits are 0x10 and the
space 0x20 — everything it writes reads out:

    HI SCORE   SCORE   STAGE   REST        the scoreboard
    PLAY START                             scene 3, blinking
    PUSH SPACE KEY   (C)KONAMI 1985        the title screen
    GAME  OVER                             when the game ends
    VIDEO CARTRIDGE                        scene 0
    PERFECT 3000 / PERFECT 5000            the two prizes
    NUMBER OF HITS                         the bonus stage
    STAGE   BONUS STAGE                    the stage captions
    WANG   TAO   CHEN   LANG   WU          the opponents
