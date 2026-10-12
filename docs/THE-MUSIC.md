# The music

Everything you hear here comes from running the cartridge's own sound engine (`un_cuadro_de_sonido`, 0x7C5C, and `pon_la_melodia`, 0x7BCC, which hands it the channels; the interrupt calls it) on an emulated Z80, frame by frame at 60 per second, just as the game calls it. What the engine writes to the PSG is turned into sound with an AY-3-8910 (`tools/musica.py`). Each MP3 is the whole piece up to where it starts again, plus 8 seconds of the repeat fading out; those that do not repeat end where the engine ends.

## Checked against openMSX

The PSG writes have been compared frame by frame with those of openMSX (C-BIOS MSX1 japonés). In every frame the PSG ends up the same:

- the fight tune (0x88), as the game asks for it, its first 361 and 957 frames.

The timbre is not checked: it is a textbook AY-3-8910, not a recording of the emulator. The probes are `tools/omsx_psg.tcl` and `tools/coteja_psg.py`.

## How a piece is asked for

`pon_la_melodia` takes the number in A, without looking at priority. Low numbers are effects and from 0x88 up there is music. Each channel takes twelve bytes from 0xE018 and 0xE03C holds the copy of the PSG mixer, which start-up leaves at 0xB8. The tracks marked «in the table» are in the track table but no routine asks for them with an `ld a`. Only one piece has been checked against openMSX, 0x88; the rest come out of the same engine but each has not been compared.

## The tunes

**The fight tune** (0x88)

Asked for by `escena_3_arranca_la_musica`, `escena_4_el_combate`, `premio` y `apunta_el_enemigo`; lasts 29.9 s and starts again at second 0.0.

<audio controls preload="none" src="audio/musica_88.mp3?v=2378cd28"></audio>

**The end of the game** (0x8F)

Asked for by `se_acabo_la_partida`; lasts 2.9 s.

<audio controls preload="none" src="audio/musica_8F.mp3?v=87ab3279"></audio>

**The fall** (0x8A)

Asked for by `modo_3_la_caida_si_no_2`; lasts 3.0 s.

<audio controls preload="none" src="audio/musica_8A.mp3?v=3d146e7b"></audio>

**Table track 0x89** (0x89)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 32.8 s and starts again at second 2.9.

<audio controls preload="none" src="audio/musica_89.mp3?v=f30dd76b"></audio>

**Table track 0x8B** (0x8B)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 34.2 s.

<audio controls preload="none" src="audio/musica_8B.mp3?v=2c76b9b1"></audio>

**Table track 0x8D** (0x8D)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 2.9 s.

<audio controls preload="none" src="audio/musica_8D.mp3?v=1e627eec"></audio>

**Table track 0x8E** (0x8E)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 2.9 s.

<audio controls preload="none" src="audio/musica_8E.mp3?v=b6138767"></audio>

**Table track 0x90** (0x90)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 2.9 s.

<audio controls preload="none" src="audio/musica_90.mp3?v=bc588af4"></audio>

**Table track 0x91** (0x91)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 2.9 s.

<audio controls preload="none" src="audio/musica_91.mp3?v=8e1cbe7a"></audio>
