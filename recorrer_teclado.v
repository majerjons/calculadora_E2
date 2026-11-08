//Autor: Solar Grillo, Lucas (LSG).

/*
Ring counter del barrido del teclado, el cual funca en active low, o sea el 0 recorre las columnas.
*/

module recorrer_teclado (
    input  wire       HFOSC,
    input  wire       rst,             // reset global sincrono
    input  wire       tick_barrido,    // avanza el ring counter (1 pulso de HFOSC)
    output reg  [3:0] ring_counter
);

    always @(posedge HFOSC) begin
        if (rst) begin
            // Estado inicial
            ring_counter[0] <= 1'b0;
            ring_counter[1] <= 1'b1;
            ring_counter[2] <= 1'b1;
            ring_counter[3] <= 1'b1;
        end
        else if (tick_barrido) begin
            // Conexion en serie, salida de un ff a la entrada del siguiente
            ring_counter[1] <= ring_counter[0];   // El bit 0 pasa al bit 1
            ring_counter[2] <= ring_counter[1];   // El bit 1 pasa al bit 2
            ring_counter[3] <= ring_counter[2];   // El bit 2 pasa al bit 3

            // Retroalimentacion: el ff final vuelve al inicial
            ring_counter[0] <= ring_counter[3];
        end
    end

endmodule

