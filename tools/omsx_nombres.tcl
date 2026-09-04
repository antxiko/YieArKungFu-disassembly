# Vuelca la TABLA DE NOMBRES durante un combate, para ver como coloca el juego
# los tiles del oponente.
#
# Para que sirve: docs/imagenes/oponente_*.png ponia los tiles de cuatro en
# cuatro porque "con esa anchura la primera pose sale entera". Eso era una
# SUPOSICION, y era falsa: las poses siguientes salian partidas. Aqui se mira
# donde los pone el juego de verdad.
#
#   "C:/Program Files/openMSX/openmsx.exe" -machine C-BIOS_MSX1_EU \
#       -cart yiear.rom -script tools/omsx_nombres.tcl

proc opcion {nombre porDefecto} {
    global env
    if {[info exists env($nombre)]} { return $env($nombre) }
    return $porDefecto
}

set ::SALIDA [opcion YK_SALIDA {C:/Users/Antxiko/Documents/DES_ASM/YIEARKUNGFU_DISAM/work/omsx_nombres}]
file mkdir $::SALIDA
set LOG [open "$::SALIDA/nombres.log" w]
proc say {m} { global LOG; puts $LOG "\[[format %8.2f [machine_info time]]\] $m"; flush $LOG }
set throttle off

set ::n 0
proc vuelca {} {
    set i [format %02d $::n]
    incr ::n
    set f [open "$::SALIDA/vram_$i.bin" w]
    fconfigure $f -translation binary
    puts -nonewline $f [debug read_block VRAM 0 16384]
    close $f
    say "volcado $i"
}

proc pulsa {fila masc dur} { keymatrixdown $fila $masc; after time $dur [list keymatrixup $fila $masc] }
set ::DIRS {0x10 0x20 0x40 0x80}
expr {srand(3)}
proc paso {} {
    set r [expr {rand()}]
    if {$r < 0.7} {
        pulsa 8 [lindex $::DIRS [expr {int(rand()*4)}]] [expr {0.15 + rand()*0.4}]
    } else {
        pulsa 8 0x01 0.2
    }
    after time 0.35 paso
}
after time 1.5 { pulsa 8 0x01 0.4 }
after time 4.0 { pulsa 8 0x01 0.4 }
after time 7.0 { paso }
for {set t 14} {$t < 46} {incr t 4} { after time $t vuelca }

after time 60 { say "FIN: $::n volcados"; exit 0 }
after realtime 150 { say "PERRO GUARDIAN"; exit 1 }
