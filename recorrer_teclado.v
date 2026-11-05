module recorrer_teclado (
    input wire HFOSC,
    input wire tick_barrido,
    input wire rst,
    input wire gpio_48,
    input wire gpio_3,
    input wire gpio_4,
    input wire gpio_44,
    output reg [3:0] ring_counter
);
    assign gpio_44 = ring_counter[0];
    assign gpio_4 = ring_counter[0];
    assign gpio_3 = ring_counter[0];
    assign gpio_48 = ring_counter[0];
    always @(posedge HFOSC or posedge rst) begin
        if (rst) begin
            // Estado inicial obligatorio: el primer flip-flop en 0, el resto en 1
            ring_counter <= 4'b1110; 
        end else if(tick_barrido) begin
            // Conexión en serie, salida de un ff a la entrada de otro
            ring_counter[1] <= ring_counter[0]; // El bit 0 pasa al bit 1
            ring_counter[2] <= ring_counter[1]; // El bit 1 pasa al bit 2
            ring_counter[3] <= ring_counter[2]; // El bit 2 pasa al bit 3
        
            // Retroalimentación ff final al inicial
            ring_counter[0] <= ring_counter[3];
        end
    end

endmodule
