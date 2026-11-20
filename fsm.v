`default_nettype none

module luz_fsm (
    
);

    // Estados
    /* localparam REPOSO             = 3'b0,
               ZONA1              = 3'b1,
               ZONA2              = 3'b2,
               TEMP_ALCANZADA     = 3'b3,
               ERROR              = 3'b4;

    reg [2:0] estadoActual, estadoProximo;

    // 1) Registro de estado
    always @(posedge clk)
        if (parar) estadoActual <= REPOSO;
        else     estadoActual <= estadoProximo;

    // 2) Próximo estado
    always @* begin
        estadoProximo = estadoActual;                  // por defecto, se queda donde está
        case (estadoActual)
            REPOSO: if (inicio) estadoProximo = ZONA1;
            ZONA1:  if(t10k) estadoProximo = ZONA2;
            ZONA2:  if(t20k) estadoProximo = TEMP_ALCANZADA;
            TEMP_ALCANZADA:  if(!t10k || !t20k) estadoProximo = ERROR;
            ERROR:  if(inicio) estadoProximo = ZONA1;
            default:   estadoProximo = REPOSO;
        endcase
    end

    // 3) Salidas de cada estado
    assign listo = (estadoActual == TEMP_ALCANZADA);
    assign err = (estadoActual == ERROR);
    assign z1 = (estadoActual == ZONA1) || (estadoActual == ZONA2) || (estadoActual == TEMP_ALCANZADA);
    assign z2 = (estadoActual == ZONA2) || (estadoActual == TEMP_ALCANZADA);
*/
endmodule

`default_nettype wire