`default_nettype none

module fsm (
    input wire         clk,
    input wire         operador_suma,
    input wire         operador_resta,
    input wire         operador_clear,
    input wire         operador_igual,
    input wire         operador_digito,
    input wire[3:0]    digito,
    
    output reg[1:0]    estado_display = 2'b00,
    output reg[1:0]    cant_dig_mostrar = 2'b00,
    output reg[1:0]    opN = 2'b00,  // 01 ingreso op1 - 10 ingreso op2 (para saber en cual guardar el numero) - 00 ninguno (actua como enable!)
    output wire        operador = 1'b0, // 1 suma - 0 resta
    output reg         rst_input_regs = 1'b0,
    output reg         en_alu = 1'b0,
    output reg         pulso_dato_disp
);

    // Estados
    localparam ESP_OP1                   = 3'b0,
               ESP_OPERADOR              = 3'b1,
               ESP_OP2                   = 3'b010,
               ESP_IGUAL                 = 3'b011,
               MOSTRAR_RESUL             = 3'b100;
        /* 
        ESP = esperando
        Los estados ESP_OPERADOR y ESP_IGUAL se definen para que, una vez ingresados cuatro dígitos, 
        no se tome el ingreso de más dígitos.
        */

    reg [2:0] estadoProximo;
    reg [2:0] estadoActual = ESP_OP1; // inicializo
    reg [2:0] cant_dig = 3'b000; // inicializo
    reg rst_contador_ciclos = 1'b0;

    pulso_5to_ciclo u_pulso_5to_ciclo(.clk(clk), .rst(rst_contador_ciclos), .senal(pulso_dato_disp));
    /* Contando como "ciclo 1" al ciclo en el que le mando un pulso por rst, me manda un pulso (de un
   ciclo) por senal en el "ciclo 5" */

    always @(posedge clk) begin
        estadoActual <= estadoProximo;
        rst_input_regs <= 1'b0;
        rst_contador_ciclos <= 1'b0;

        //si estoy en la transicion de cualquier estado a ESP_OP1...
        if (operador_clear) begin
            cant_dig <= 3'b0;
            rst_input_regs <= 1'b1;
            rst_contador_ciclos <= 1'b1;
        end

        //si estoy en ESP_OP1 o en ESP_OP2, no transicionando, e ingresaron un dígito...
        else if (operador_digito && estadoActual==estadoProximo && (estadoActual==ESP_OP1 || estadoActual==ESP_OP2)) begin
            cant_dig <= cant_dig + 3'b1;
            rst_contador_ciclos <= 1'b1;
        end
        
        //si estoy transicionando a ESP_OP2...
        else if(estadoActual!=estadoProximo && estadoProximo==ESP_OP2) cant_dig <= 3'b0;

        if (operador_igual)  rst_input_regs <= 1'b1;
        else if (operador_suma) operador <= 1'b1; //entre la suma y la resta, priorizo la suma arbitrariamente
        else if (operador_resta) operador <= 1'b0;

    end

    /* 
    A continuación algo que escribí para organizar las ideas, no para documentar. 
    Los operador_x_propag son están definidos en el módulo del registrosEntrada.

    ANALISIS DE TIEMPOS DEL RESET:
    1er ciclo --> operador_clear se pone en 1
    2do ciclo --> se actualiza la variable de salida de rst
    3er ciclo --> registrosEntrada los resetea
    4to ciclo --> se actualiza (a cero) la entrada de transmisor_serie
    5to ciclo --> ahora si, le puedo mandar el pulso al display
        
    ***********************

    ANALISIS DE TIEMPOS DE LA TOMA DE DIGITOS:
    1er ciclo --> llega un digito, operador_digito se pone en 1, pero el digito nuevo todavia no está en "digito"
    2do ciclo --> en el flanco ascendente se actualiza opN si corresponde (lo consideramos porque es peor escenario). En este ciclo aparece el digito nuevo en la variable "digito". operador_digito_propag tiene el pulso aca
    3er ciclo --> recién en este flanco ascendente debería guardar el digito en el registro, si corresponde. el if (operador_digito_propag) se pone en 1 aca
    4to ciclo --> en este flanco ascendente se actualizó el resultado en la entrada de transmisor_serie. Si en este ciclo mando al display el pulso, tomaría el valor anterior del registro, así que no funcaría.
    5to ciclo --> en este ciclo le mandaría el pulso a transmisor_serie

    ***********************

    ANALISIS DE TIEMPOS DE LA TOMA DEL OPERADOR:
    1er ciclo --> se prende operador_suma/resta
    2do ciclo --> está guardado el valor ingresado
    3er ciclo --> se actualizó el resultado en la entrada de transmisor_serie, así que ahora se puede mandar el pulso al display
    4to ciclo --> en este ciclo le mandaría el pulso a transmisor_serie

    ***********************

    ANALISIS DE TIEMPOS DEL IGUAL:
    1er ciclo --> operador_igual se prende
    2do ciclo --> se actualiza la fsm y se hace la cuentita
    3er ciclo --> se actualiza la entrada de transmisor_serie
    4to ciclo --> ya se puede mandar el pulso al display

    ***********************

    ANALISIS DE TIEMPOS DE LA ALU (en):
    Ojo con el tiempo de propagación

    ***********************

    Conclusión: los dígitos ingresados y el reset me hacen quilombo porque dependen del clock dentro
    del módulo registrosEntrada, los que manejo aca directamente tardan un ciclo menos. Tomo 5 ciclos
    como cota superior.

    */


    always @(*) begin
        estadoProximo = estadoActual;                  // por defecto, se queda donde está
        case (estadoActual)
            ESP_OP1: begin
                if (operador_suma || operador_resta)  estadoProximo = ESP_OP2;
                else if (cant_dig==3'b100) estadoProximo = ESP_OPERADOR;
            end

            ESP_OPERADOR:  
                if (operador_suma || operador_resta)  estadoProximo = ESP_OP2;
            
            ESP_OP2:
                if (cant_dig==3'b100) estadoProximo = ESP_IGUAL;
            
            MOSTRAR_RESUL:
                if(operador_digito) estadoProximo = ESP_OP1;
        endcase

        if (operador_clear) estadoProximo = ESP_OP1;
        else if (operador_igual) estadoProximo = MOSTRAR_RESUL;
    end


    always @(*) begin
        if((estadoActual==ESP_OP1) || (estadoActual==MOSTRAR_RESUL)) opN = 2'b1; // asi cuando escribo el primer digito de op1 mientras muestro el resultado, se guarda
        else if (estadoActual == ESP_OP2) opN = 2'b10;
        else opN = 2'b00;

        if (estadoActual == ESP_OP1 || estadoActual == ESP_OPERADOR ) estado_display = 2'b00;
        else if (estadoActual == ESP_OP2 || estadoActual == ESP_IGUAL ) estado_display = 2'b01;
        else estado_display = 2'b10;

        if(cant_dig) cant_dig_mostrar = cant_dig - 3'b001;
        else cant_dig_mostrar = 3'b000;
    end
    assign en_alu = (estadoActual==MOSTRAR_RESUL);

endmodule

`default_nettype wire




module pulso_5to_ciclo (
  input  wire clk,
  input  wire rst,
  output wire senal
);
    reg [2:0] count;

    always @(posedge clk) begin
        if (rst)    count <= 0;
        else if (count != 5) count <= count + 1'b1; 
        /* llega a 5 (el 6to ciclo) y no a 4 porque si lo dejo en 4, la señal queda prendida en vez de
        mandar un pulso */
    end

    assign senal = (count == 4); // de 0 a 4 hay 5 ciclos
endmodule