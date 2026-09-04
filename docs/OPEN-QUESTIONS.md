# Open questions

What is **not** settled. It is here to be seen, not to pad anything out.

## Which of the two builds came first

What is known is measured: they share 97.0% of their instructions, differ in five
constants and in two masks the hard build makes variable, and **only the hard one
carries Konami's hidden mark**, while the easy one has the title in Latin ASCII
in that same gap.

What is **not** known is what any of that means. The binary says what the code
does, not who published it or in what order. Venturing that one is original and
the other a modification, or the other way round, would be a guess, and there is
nothing inside the cartridge to hold it up.

## What exactly 0xE056 is

It turns up in six places as the index of four-entry tables: the random
generator's seeds (0x52C5), the per-opponent thresholds (0x4729 and 0x743A), the
delays (0x746B and 0x7592) and the hard build's variable mask. Everything points
to it being the **difficulty level** or the lap, but where it gets written with a
value that would confirm it has not been found.

It is the same trap that has cost dear in other disassemblies: knowing who
**reads** a variable is not enough; you have to see who **writes** it and with
what.

## How many poses each opponent has

The five pose tables have eighteen entries — twenty for the fifth — and the
blocks they point at alternate long-short: the even indices give one of between
eleven and twenty-seven bytes and the odd ones give seven flat. Nine pairs, with
the last block eating whatever is left.

What each pair is exactly — a pose and its variant, or the body and the weapon —
is not settled. It needs all of them drawn and looked at.

## The fifteen bytes at 0x595A that nothing reads

The block at 0x595A is twenty bytes: five sprite attribute entries, all five
`E0 00 00 00`. But the `ldir` at 0x594C copies **only five** of those twenty,
and that is enough, because 0x5942 has just zeroed the 0x80 destination bytes.

`apunta_a.py` confirms that no other address in the cartridge falls inside the
block. So the last fifteen are read by nothing. Whether they are leftovers from
an earlier version or room set aside on purpose, the binary does not say.

## The two bytes at 0x564C

Two bytes, `00 76`, between the `jp` at 0x5649 and the script at 0x564E. No
pointer anywhere in the ROM falls in them and the script does not start there,
because 0x5635 loads 0x564E. They are declared as leftovers, which is what the
measurement supports.

## What the tiles at 0x6C15 and 0x6C1A draw

Ten tiles in two runs of five — 0x67, 0x64, 0x65, 0x66, 0x63 and 0x6B, 0x68,
0x69, 0x6A, 0x63 — that 0x6BA5 uses to draw the energy bar depending on whether
there is a lot left or little. **When** each run is used is known; what each tile
draws exactly can be seen, but has not been tied to a meaning.
