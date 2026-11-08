//Autor: Solar Grillo, Lucas (LSG).

/*
Arma la matriz de teclas apretadas de un teclado de 4x4(hardcodeado mucho bardo hacerlo modular). 
En cada paso del barrido hay una columna activa y se leen las 4 filas; 
la lectura se guarda en el pedazo de "matriz" que le corresponde a esa columna.

ej:
  matriz[3:0]   -> columna 0 (bit 0 = fila 0 ... bit 3 = fila 3)
  matriz[7:4]   -> columna 1
  matriz[11:8]  -> columna 2
  matriz[15:12] -> columna 3
Un 1 en la matriz significa tecla apretada.

ACTIVO_BAJO = 1 por la logica dle ring counter.

Se captura en el ciclo en que en = 1, es decir en el ultimo ciclo de la columna, antes de que el ring counter
 avance, cuando las filas ya estuvieron ~1ms estables.
 Las filas son entrandas asincronazas por ende pasan por el sincronizador.
*/

module captura_matriz #(
    parameter ACTIVO_BAJO = 1
)(
    input  wire        HFOSC,
    input  wire        rst,
    input  wire        en,          
    input  wire [3:0]  columna,     
    input  wire [3:0]  filas,       // pines de entrada del teclado
    output reg  [15:0] matriz
);

    //Sincronizador de las filas (no necesita reset: en 2 ciclos copia la entrada)
    reg [3:0] filas_s1;
    reg [3:0] filas_s2;
    always @(posedge HFOSC) begin
        filas_s1 <= filas;
        filas_s2 <= filas_s1;
    end

    //Paso todo a logica positiva (1 = columna activa / tecla apretada)
    wire [3:0] filas_pos  = ACTIVO_BAJO ? ~filas_s2 : filas_s2;
    wire [3:0] col_activa = ACTIVO_BAJO ? ~columna  : columna;

    //Cada columna guarda sus 4 bits cuando esta activa y llega el tick
    always @(posedge HFOSC) begin
        if (rst) begin
            matriz <= 16'b0;
        end
        else if (en) begin
            if (col_activa[0]) matriz[3:0]   <= filas_pos;   // Columna 0 (bits 0 a 3)
            if (col_activa[1]) matriz[7:4]   <= filas_pos;   // Columna 1 (bits 4 a 7)
            if (col_activa[2]) matriz[11:8]  <= filas_pos;   // Columna 2 (bits 8 a 11)
            if (col_activa[3]) matriz[15:12] <= filas_pos;   // Columna 3 (bits 12 a 15)
        end
    end

endmodule