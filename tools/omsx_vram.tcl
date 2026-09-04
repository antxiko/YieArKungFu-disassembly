# omsx_vram.tcl - Vuelca la VRAM de verdad de Yie Ar Kung-Fu.
#
# Para que sirve: tools/pantallas.py monta las imagenes de la web ejecutando en
# Python los mismos pasos que el cartucho -el interprete de guiones de 0x442c y
# el de listas de 0x44a6-. Mirar el dibujo no basta: hay que comparar sus bytes
# con los que el VDP tiene de verdad. Esto deja correr el juego y en varios
# instantes vuelca los 16 KB de VRAM, los ocho registros del VDP y las
# variables que dicen QUE se estaba dibujando.
#
# Aqui hace falta ademas la tabla de NOMBRES: ningun guion del cartucho escribe
# en 0x3800, asi que el fondo del combate se compone por codigo y la unica
# manera de saber con que tiles es mirarla.
#
# No pone ningun punto de ruptura: todo el juego corre dentro de la
# interrupcion de 0x4043 y un bp ahi ahoga al emulador. Los volcados van por
# reloj emulado.
#
# Variables de entorno:
#   YK_SALIDA  carpeta de salida (por defecto work/omsx)
#
#   "C:/Program Files/openMSX/openmsx.exe" -machine Philips_VG_8020 \
#       -cart yiear.rom -script tools/omsx_vram.tcl

proc opcion {nombre porDefecto} {
    global env
    if {[info exists env($nombre)]} { return $env($nombre) }
    return $porDefecto
}

set ::SALIDA [opcion YK_SALIDA {C:/Users/Antxiko/Documents/DES_ASM/YIEARKUNGFU_DISAM/work/omsx}]
file mkdir $::SALIDA
set ::n 0

proc vuelca {etiqueta} {
    set i [format %02d $::n]
    incr ::n
    set datos [debug read_block VRAM 0 16384]
    set f [open $::SALIDA/vram_$i.bin w]
    fconfigure $f -translation binary
    puts -nonewline $f $datos
    close $f
    set r {}
    for {set k 0} {$k < 8} {incr k} {
        lappend r [format %02X [debug read {VDP regs} $k]]
    }
    set f [open $::SALIDA/info_$i.txt w]
    puts $f [format {etiqueta %s} $etiqueta]
    puts $f [format {tiempo %s} [machine_info time]]
    puts $f [format {regs %s} [join $r { }]]
    # 0xE000 escena y 0xE001 paso son el reparto de 0x409f; 0xE054 el escenario,
    # que es el indice de las tablas de fondo de 0x4b9c y 0x4ba6.
    foreach {nombre dir} {escena 0xE000 paso 0xE001 mandos 0xE002
                          cuadros 0xE003 plazo 0xE004 candado 0xE006
                          escenario 0xE054 e050 0xE050 e056 0xE056
                          e058 0xE058 e059 0xE059 e106 0xE106
                          e154 0xE154 e184 0xE184} {
        puts $f [format {%s %d} $nombre [debug read memory $dir]]
    }
    close $f
    catch { screenshot -raw $::SALIDA/pant_$i.png }
}

# --- la barra de espacio, para pasar del titulo a la partida --------------
proc pulsa {} {
    keymatrixdown 8 0x01
    after time 0.4 suelta
}
proc suelta {} {
    keymatrixup 8 0x01
}

after time  8.0 { vuelca titulo }
after time 16.0 { pulsa }
after time 17.0 { pulsa }
after time 19.0 { vuelca tras_pulsar }
after time 24.0 { vuelca combate }
after time 30.0 { vuelca combate }
after time 38.0 { vuelca combate }
after time 46.0 { vuelca combate }
after time 56.0 { vuelca combate }
after time 66.0 { vuelca combate }
after time 78.0 { vuelca combate }
after time 90.0 { vuelca combate }
after time 105.0 { vuelca combate }
after time 120.0 { vuelca combate }
after time 122.0 { puts {FIN por calendario} ; exit }

# perro guardian de tiempo REAL: un guion roto no puede colgar el emulador
after realtime 300 {
    puts {PERRO GUARDIAN a los 300 s reales}
    exit
}
