`default_nettype none

module fsm (
    input wire         operador_suma,
    input wire         operador_resta,
    input wire         operador_clear,
    input wire         operador_igual,
    input wire         operador_digito,
    input wire[3:0]    digito,
    input wire         HFOSC,
    output reg[1:0]    estado_display
);

    // Estados
    localparam ESP_OP1                   = 3'b0,
               ESP_OPERADOR              = 3'b1,
               ESP_OP2                   = 3'b2,
               ESP_IGUAL                 = 3'b3,
               MOSTRAR_RESUL             = 3'b4;
        /* 
        ESP = esperando
        Los estados ESP_OPERADOR y ESP_IGUAL se definen para que, una vez ingresados cuatro dígitos, 
        no se tome el ingreso de más dígitos.
        */

    reg [2:0] estadoActual, estadoProximo;
    reg [2:0] cant_dig;

    // 1) Registro de estado
    always @(posedge clk) begin
        estadoActual <= estadoProximo;

        if (operador_digito) cant_dig <= cant_dig + 4'b1;
        if(estadoActual != estadoProximo && (estadoProximo == ESP_OP2 || estadoProximo == ESP_OP1)) cant_dig <= 4'b0;
    end


    // 2) Próximo estado
    always @* begin
        estadoProximo = estadoActual;                  // por defecto, se queda donde está
        case (estadoActual)
            ESP_OP1:
                if (cant_dig==4) estadoProximo = ESP_OPERADOR;
                if (operador_suma || operador_resta)  estadoProximo = ESP_OP2;

            ESP_OPERADOR:  
                if (operador_suma || operador_resta)  estadoProximo = ESP_OP2;
            
            ESP_OP2:
                if (cant_dig==4) estadoProximo = ESP_IGUAL;

        endcase
        if (operador_igual) estadoProximo = MOSTRAR_RESUL;
        if (operador_clear) estadoProximo <= ESP_OP1;
    end


    // 3) Salidas de cada estado
    always @(*) begin
        if(estadoActual==ESP_OP1 || estadoActual==ESP_OPERADOR) estado_display = 2'b0;
        if (estadoActual == ESP_OP2) estado_display = 2'b1;
        if (estadoActual == MOSTRAR_RESUL) estado_display = 2'b2;
    end
    
endmodule

`default_nettype wire

/*
si el op2 es 0, sea porque no se ingreso nada o por cualquier otro motivo, el resultado es op1,
así que puedo ni hacer la cuenta
*/