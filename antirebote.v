//Autor: Solar Grillo, Lucas (LSG).
//CHECK ANTIRREBOTE DE MULTI-SEÑAL
/*
Antirrebote para un bus de ANCHO senales (por ejemplo las 16 teclas). Cada tecla tiene su propio contador
y su propio estado estable, y las 16 se filtran en el mismo always con un for.

Al final de todo hay un ejemplo sin bucle for, es un pijazo

Para cada tecla i, en cada tick de muestreo (en = 1):
  - Si entrada[i] es igual al estado estable salida[i]: no hay cambio, el contador de esa tecla vuelve a 0.
  - Si es distinta: cuenta. Cuando llega a N_MUESTRAS muestras seguidas distintas, salida[i] adopta
    el nuevo valor y el contador vuelve a 0.
  - Si en el medio la entrada vuelve a ser igual a salida[i] (un rebote), se reinicia la cuenta.

Tiempo minimo de estabilidad aprox = (N_MUESTRAS - 1) * periodo del tick (hasta N_MUESTRAS * periodo).
Ej: tick de 100Hz (10ms) y N_MUESTRAS = 3 -> la entrada tiene que estar estable entre 20ms y 30ms.
N_MUESTRAS = 1 deja pasar la entrada sin filtrar.
*/

module antirrebote #(
    parameter ANCHO      = 16,
    parameter N_MUESTRAS = 3
)(
    input  wire             HFOSC,
    input  wire             rst,
    input  wire             en,        // tick de muestreo (tick_anti_rebote)
    input  wire [ANCHO-1:0] entrada,   // senales con rebotes (la matriz)
    output reg  [ANCHO-1:0] salida     // senales estables
);

    localparam ANCHO_CNT = (N_MUESTRAS > 1) ? $clog2(N_MUESTRAS) : 1;

    //Un contador por tecla: cnt[0] es el de la tecla 0, cnt[1] el de la tecla 1, etc.
    reg [ANCHO_CNT-1:0] cnt [0:ANCHO-1];   //el segundo corchete representa la cantidad de contadores y el ancho es el ancho de cada uno. cd[i] es el contador numero i

    integer i;   // indice de la tecla; solo se usa dentro del for

    always @(posedge HFOSC) begin
        if (rst) begin
            salida <= {ANCHO{1'b0}};
            for (i = 0; i < ANCHO; i = i + 1) begin
                cnt[i] <= {ANCHO_CNT{1'b0}};
            end
        end
        else if (en) begin
            //El for repite el mismo bloque para cada tecla: primero i = 0, despues i = 1, ... hasta i = ANCHO-1.
            for (i = 0; i < ANCHO; i = i + 1) begin
                if (entrada[i] == salida[i]) begin              // sin cambios (o volvio a su valor): reinicio la cuenta
                    cnt[i] <= {ANCHO_CNT{1'b0}};
                end
                else if (cnt[i] == N_MUESTRAS - 1) begin       // estuvo distinta N_MUESTRAS veces seguidas: la acepto
                    salida[i] <= entrada[i];
                    cnt[i]    <= {ANCHO_CNT{1'b0}};
                end
                else begin                                      // sigue distinta: sigo contando
                    cnt[i] <= cnt[i] + 1'b1;
                end
            end
        end
    end

endmodule