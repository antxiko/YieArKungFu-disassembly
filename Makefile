# Yie Ar Kung-Fu (Konami, MSX1) - desensamblado
#
# El orden de las cosas: trazar el flujo -> generar el listado -> comprobar que
# vuelve a dar la ROM byte a byte -> las comprobaciones que el reensamblado NO
# cubre.
#
# La ROM no se distribuye. Hace falta en la raiz como yiear.rom, y
# `make comprueba` verifica el sha256.

ROM      = yiear.rom
SHA      = 644c78c7d20bb30802888b513b384cf0ce4f9d8b6fd490f30e6211ac92274848
SRC      = src
WORK     = work
ORG      = 0x4000
TITULO   = YIE AR KUNG-FU - Konami - MSX1 - cartucho RC-725 de 16 KB en la pagina 1 (version facil)

all: listado verify sanity test

$(ROM):
	@echo "=================================================================="
	@echo " Falta $(ROM), y este repositorio NO lo distribuye."
	@echo ""
	@echo " Es Yie Ar Kung-Fu (Konami, RC-725), la version FACIL, 16384 bytes."
	@echo " Ponlo aqui con ese nombre. Para comprobar que es el mismo:"
	@echo "     shasum -a 256 $(ROM)"
	@echo "     $(SHA)"
	@echo "=================================================================="
	@false

comprueba: $(ROM)
	@echo "$(SHA)  $(ROM)" | shasum -a 256 -c -

# El trazado sigue el flujo desde los puntos de entrada. Los que no se pueden
# deducir estaticamente -ganchos de interrupcion, destinos de saltos
# indirectos- estan declarados en el .entries, cada uno con su justificacion.
$(WORK)/yiear.trace.json: $(ROM) $(SRC)/yiear.entries $(SRC)/yiear.nocode
	@mkdir -p $(WORK)
	python3 tools/z80trace.py $(ROM) $(ORG) $(SRC)/yiear.entries \
	        $(WORK)/yiear $(SRC)/yiear.nocode

trace: $(WORK)/yiear.trace.json

listado: $(WORK)/yiear.trace.json $(SRC)/yiear.notes
	python3 tools/mkasm.py $(ROM) $(ORG) $(WORK)/yiear.trace.json \
	        $(SRC)/yiear.notes work/msx.sym $(SRC)/yiear.asm "$(TITULO)"

# La prueba que decide si el desensamblado es fiable.
verify: $(SRC)/yiear.asm $(ROM)
	@sh tools/verify_build.sh $(SRC)/yiear.asm $(ROM) $(ORG)

# Lo que el reensamblado NO puede cazar: que unos datos se esten leyendo como
# codigo. El binario sale identico igual, porque los bytes no cambian; lo unico
# que cambia es lo que decimos de ellos.
sanity: $(WORK)/yiear.trace.json
	@echo "=================================================================="
	@echo " ningun byte declarado como datos puede salir como codigo"
	@echo "=================================================================="
	@python3 tools/check_trace.py $(WORK)/yiear.trace.json $(SRC)/yiear.nocode
	@python3 tools/check_datos_como_codigo.py $(WORK) $(SRC)
	@echo "=================================================================="
	@echo " ningun punto de entrada puede caer dentro de una zona de datos"
	@echo "=================================================================="
	@python3 tools/check_entradas.py $(SRC)/yiear.entries $(SRC)/yiear.notes \
	        $(SRC)/yiear.nocode
	@echo "=================================================================="
	@echo " ni un byte del cartucho sin asignar"
	@echo "=================================================================="
	@python3 tools/presupuesto.py $(WORK) $(SRC)

densidad:
	@python3 tools/densidad.py $(SRC)/yiear.asm

test:
	@echo "=================================================================="
	@echo " Tests"
	@echo "=================================================================="
	@python3 -m unittest discover -s tests -v

# Dibuja los bloques de datos graficos declarados en el .notes, para MIRARLOS.
imagenes: $(ROM)
	@mkdir -p work/gfx
	python3 tools/dibuja.py $(ROM) $(ORG) $(SRC)/yiear.notes work/gfx

# LA WEB
#
# Bilingue: el ingles en docs/ y el castellano en docs/es/. Las paginas se
# escriben en markdown y se convierten con md2html.py; la portada la monta
# make_web.py, que declara las cifras medidas de ESTE cartucho.
web: $(ROM)
	python3 tools/pantallas.py $(ROM) $(ORG) docs/imagenes
	python3 tools/md2html.py docs en
	python3 tools/md2html.py docs/es es
	python3 tools/make_web.py docs/imagenes docs/index.html en
	python3 tools/make_web.py docs/imagenes docs/es/index.html es
	python3 tools/check_enlaces.py docs

clean:
	rm -rf $(WORK)/yiear.trace.json $(WORK)/yiear.blocks

.PHONY: all comprueba trace listado verify sanity test densidad imagenes web clean
