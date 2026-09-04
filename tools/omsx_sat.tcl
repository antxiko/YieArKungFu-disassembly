# Vuelca la tabla de atributos de sprites durante un combate.
#
# Para que sirve: docs/imagenes/figuras.png era un volcado crudo de los 64
# sprites de 16x16 de la tabla de patrones, sin orden y sin decir que era cada
# uno. Para MONTAR al protagonista hay que saber cuantos sprites lo forman, con
# que patrones y con que colores, y eso no se deduce de la tabla: se lee de la
# SAT de una maquina en marcha.
#
# No pone puntos de ruptura: los volcados van por reloj emulado, que es lo
# unico que no ahoga al emulador.
#
#   "C:/Program Files/openMSX/openmsx.exe" -machine C-BIOS_MSX1_EU \
#       -cart yiear.rom -script tools/omsx_sat.tcl
#
# Variables de entorno: YK_SALIDA (carpeta), YK_SEG (segundos emulados).

proc opcion {nombre porDefecto} {
    global env
    if {[info exists env($nombre)]} { return $env($nombre) }
    return $porDefecto
}

set ::SALIDA [opcion YK_SALIDA {C:/Users/Antxiko/Documents/DES_ASM/YIEARKUNGFU_DISAM/work/omsx_sat}]
file mkdir $::SALIDA
set ::SEG [expr {[opcion YK_SEG 150]}]

set LOG [open "$::SALIDA/sat.log" w]
proc say {m} { global LOG; puts $LOG "\[[format %8.2f [machine_info time]]\] $m"; flush $LOG }
set throttle off

set ::n 0

proc vuelca {} {
    set i [format %02d $::n]
    incr ::n
    set f [open "$::SALIDA/sat_$i.txt" w]
    puts $f "tiempo [machine_info time]"
    # los 32 sprites de la tabla de atributos: Y, X, patron, color
    for {set s 0} {$s < 32} {incr s} {
        set b {}
        for {set k 0} {$k < 4} {incr k} {
            lappend b [format %02X [debug read VRAM [expr {0x3b00 + $s*4 + $k}]]]
        }
        puts $f "$s [join $b { }]"
    }
    close $f
    # y la tabla de patrones de sprite entera, por si el juego la recarga
    set g [open "$::SALIDA/spr_$i.bin" w]
    fconfigure $g -translation binary
    puts -nonewline $g [debug read_block VRAM 0x1800 2048]
    close $g
    say "volcado $i"
}

# La barra de espacio arranca la partida; despues se aporrean los cursores y
# el disparo para que el protagonista cambie de pose.
proc pulsa {fila masc dur} { keymatrixdown $fila $masc; after time $dur [list keymatrixup $fila $masc] }
set ::DIRS {0x10 0x20 0x40 0x80}
expr {srand(11)}
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

for {set t 12} {$t < 60} {incr t 4} { after time $t vuelca }

after time $::SEG { say "FIN: $::n volcados"; exit 0 }
after realtime 180 { say "PERRO GUARDIAN"; exit 1 }
