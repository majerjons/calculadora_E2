//Autor: Solar Grillo, Lucas (LSG).

/*
Detector de flancos reutilizable. Para cada bit de "senal" genera un pulso de 1 ciclo de HFOSC
cuando detecta un flanco. Compara el valor actual con el valor anterior (guardado en un registro).
  MODO = 0 -> flanco ascendente  (0 -> 1)
  MODO = 1 -> flanco descendente (1 -> 0)
  MODO = 2 -> ambos flancos
ANCHO es la cantidad de senales que se vigilan a la vez (un bus completo con un solo modulo).
"en" es el tick de muestreo: el valor anterior solo se actualiza cuando en = 1.
Con en = 1'b1 muestrea en cada clock. El pulso sale registrado (1 ciclo despues del flanco).
*/

module detector_flanco #(
    parameter ANCHO = 1,
    parameter MODO  = 0
)(
    input  wire             HFOSC,
    input  wire             rst,
    input  wire             en,
    input  wire [ANCHO-1:0] senal,
    output reg  [ANCHO-1:0] pulso
);

    reg [ANCHO-1:0] anterior;

    wire [ANCHO-1:0] ascendente  =  senal & ~anterior;
    wire [ANCHO-1:0] descendente = ~senal &  anterior;

    always @(posedge HFOSC) begin
        if (rst) begin
            anterior <= senal;              // copio el valor actual: no genera un flanco falso al salir del reset
            pulso    <= {ANCHO{1'b0}};
        end
        else begin
            pulso <= {ANCHO{1'b0}};         // por defecto el pulso dura un solo ciclo
            if (en) begin
                anterior <= senal;
                if      (MODO == 0) pulso <= ascendente;
                else if (MODO == 1) pulso <= descendente;
                else                pulso <= ascendente | descendente;
            end
        end
    end

endmodule