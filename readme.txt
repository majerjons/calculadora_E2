Comandos para compilar y cargar a la fpga:

apio build      # sintetiza y genera el bitstream (yosys + nextpnr)
apio upload     # lo carga a la UPduino por USB

Comandos utiles para depurar:
apio lint       # revisa sintaxis y warnings (en versiones viejas: apio verify)
apio build -v   # compila mostrando todo el log de yosys/nextpnr
apio report     # uso de recursos (LUTs, FFs) y timing
apio clean      # borra lo generado, útil si algo queda raro
apio sim        # simula un testbench (_tb.v)