# Vuelca la tabla de nombres con CADA UNO de los cinco oponentes en su pose de
# reposo, para saber COMO se colocan sus tiles.
#
# Los oponentes no son sprites: son tiles, y cada pose los reparte en una forma
# distinta -no en una rejilla-. Poner los tiles de cuatro en cuatro, que es lo
# que hacia la web antes, parte las figuras. La forma de la pose de reposo se
# mide aqui.
#
# El escenario lo elige (0xE054), y hay que forzarlo ANTES de que se monte el
# combate: forzarlo con la pelea ya en marcha no redibuja la figura. Por eso se
# escribe sin parar desde el arranque y se REINICIA la maquina entre uno y otro.
#
#   "C:/Program Files/openMSX/openmsx.exe" -machine C-BIOS_MSX1_EU \
#       -cart yiear.rom -script tools/omsx_oponentes.tcl

proc opcion {n d} { global env; if {[info exists env($n)]} { return $env($n) }; return $d }
set ::SALIDA [opcion YK_SALIDA {C:/Users/Antxiko/Documents/DES_ASM/YIEARKUNGFU_DISAM/work/omsx_oponentes}]
file mkdir $::SALIDA
set LOG [open "$::SALIDA/oponentes.log" w]
proc say {m} { global LOG; puts $LOG "\[[format %8.2f [machine_info time]]\] $m"; flush $LOG }
set throttle off

set ::CUAL 0

proc fuerza {} {
    debug write memory 0xe054 $::CUAL
    after time 0.1 fuerza
}
proc pulsa {fila masc dur} { keymatrixdown $fila $masc; after time $dur [list keymatrixup $fila $masc] }
proc arranca {} {
    after time 1.5 { pulsa 8 0x01 0.4 }
    after time 4.0 { pulsa 8 0x01 0.4 }
    after time 13.0 vuelca
}
proc vuelca {} {
    set f [open [format "$::SALIDA/vram_%d.bin" $::CUAL] w]
    fconfigure $f -translation binary
    puts -nonewline $f [debug read_block VRAM 0 16384]
    close $f
    say "oponente $::CUAL volcado"
    incr ::CUAL
    if {$::CUAL > 4} { say FIN; exit 0 }
    reset
    arranca
}
fuerza
arranca

after time 200 { say "FIN por tiempo: iba por $::CUAL"; exit 1 }
after realtime 200 { say PERRO; exit 1 }
