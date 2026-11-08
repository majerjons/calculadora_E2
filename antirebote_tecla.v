//Autor: Solar Grillo, Lucas (LSG).

/*
Antirrebote de UNA senal. 
La salida ya esta estable.
La entrada se considera un estado nuevo solo si si es distinta de salida durante N_MUESTRAS consecutivas (1 muestra por cada en = 1)

Si en el medio vuelve a ser igual a "salida" (un rebote), el contador vuelve a 0 y se empieza de nuevo.
Tiempo minimo de estabilidad aprox = (N_MUESTRAS - 1) * periodo del tick (hasta N_MUESTRAS * periodo).

Ej: tick de 100Hz (10ms) y N_MUESTRAS = 3 -> la entrada tiene que estar estable entre 20ms y 30ms.
N_MUESTRAS = 1 deja pasar la entrada sin filtrar.
*/

module antirrebote_tecla #(
    parameter N_MUESTRAS = 3
)(
    input  wire HFOSC,
    input  wire rst,
    input  wire en,          // tick de muestreo (tick_anti_rebote)
    input  wire entrada,
    output reg  salida
);

    localparam ANCHO_CNT = (N_MUESTRAS > 1) ? $clog2(N_MUESTRAS) : 1;

    reg [ANCHO_CNT-1:0] cnt;

    always @(posedge HFOSC) begin
        if (rst) begin
            cnt    <= {ANCHO_CNT{1'b0}};
            salida <= 1'b0;
        end
        else if (en) begin
            if (entrada == salida) begin              // sin cambios (o volvio a su valor): reinicio la cuenta
                cnt <= {ANCHO_CNT{1'b0}};
            end
            else if (cnt == N_MUESTRAS - 1) begin     // estuvo distinta N_MUESTRAS veces seguidas: la acepto
                salida <= entrada;
                cnt    <= {ANCHO_CNT{1'b0}};
            end
            else begin                                // sigue distinta: sigo contando
                cnt <= cnt + 1'b1;
            end
        end
    end

endmodule