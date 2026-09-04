# Preguntas abiertas

Lo que **no** está resuelto. Está aquí para que se vea, no para rellenar.

## Cuál de las dos compilaciones salió antes

Lo que se sabe está medido: comparten el 97,0 % de las instrucciones, difieren
en cinco constantes y en dos máscaras que la difícil hace variables, y **solo la
difícil lleva la marca oculta de Konami**, mientras la fácil tiene el título en
ASCII latino en ese mismo hueco.

Lo que **no** se sabe es qué significa eso. El binario dice qué hace el código,
no quién lo publicó ni en qué orden. Aventurar que una es original y la otra una
modificación, o al revés, sería una suposición, y no hay dentro del cartucho
nada que la sostenga.

## Qué es exactamente 0xE056

Aparece en seis sitios como índice de tablas de cuatro entradas: las semillas
del generador de azar (0x52C5), los umbrales por oponente (0x4729 y 0x743A), los
plazos (0x746B y 0x7592) y la máscara variable de la versión difícil. Todo apunta
a que es el **nivel de dificultad** o la vuelta, pero no se ha encontrado dónde
se escribe con un valor que lo confirme.

Es la misma trampa que ya cuesta cara en otros desensamblados: saber quién
**lee** una variable no basta; hay que ver quién **escribe** en ella y con qué.

## Cuántas poses tiene cada oponente

Las cinco tablas de poses tienen dieciocho entradas —veinte la del quinto— y los
bloques a los que apuntan se alternan largo-corto: los índices pares dan uno de
entre once y veintisiete bytes y los impares uno de siete clavados. Nueve
parejas, con el último bloque comiéndose lo que quede.

Qué es exactamente cada pareja —si es una pose y su variante, o el cuerpo y el
arma— no está cerrado. Hace falta dibujarlas todas y verlas.

## Los quince bytes de 0x595A que no lee nadie

El bloque de 0x595A son veinte bytes: cinco entradas de atributo de sprite, las
cinco `E0 00 00 00`. Pero el `ldir` de 0x594C copia **solo cinco** de esos
veinte, y le basta, porque 0x5942 acaba de dejar a cero los 0x80 bytes de
destino.

`apunta_a.py` confirma que ninguna otra dirección del cartucho cae dentro del
bloque. Así que los quince últimos no los lee nadie. Si son restos de una
versión anterior o sitio reservado a propósito, el binario no lo dice.

## Los dos bytes de 0x564C

Dos bytes, `00 76`, entre el `jp` de 0x5649 y el guion de 0x564E. Ningún puntero
de toda la ROM cae en ellos y el guion no empieza ahí, porque 0x5635 carga
0x564E. Están declarados como restos, que es lo que se puede decir con lo
medido.

## Qué dibujan los tiles de 0x6C15 y 0x6C1A

Diez tiles en dos tiras de cinco —0x67, 0x64, 0x65, 0x66, 0x63 y 0x6B, 0x68,
0x69, 0x6A, 0x63— que 0x6BA5 usa para dibujar la barra de energía según quede
mucha o poca. Se sabe **cuándo** se usa cada tira; qué dibujo tiene cada tile en
concreto se puede ver, pero no se ha atado a un significado.
