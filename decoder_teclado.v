//Autor: Solar Grillo, Lucas (LSG).

/*
A partir de la coordenada fisica me indica cual tecla esta presionada. 
Entrada: tecla_apretada[15:0], pulsos de 1 ciclo (salida del detector_flanco). Bit = 4*columna + fila.

          col0  col1  col2  col3
  fila0:   1     2     3     A        (fila0 = gpio_2,  col0 = gpio_48)
  fila1:   4     5     6     B
  fila2:   7     8     9     C
  fila3:   *     0     #     D

Asignacion de operadores
  A = suma, B = resta, D = igual, C = clear. 

Los operadores duran 1 ciclo, a cambio los que son digito se retienen hasta el siguiente digito para que la FSM pueda
activar op1_en/op2_en un ciclo despues del pulso y el registro de entrada vea bien el valor/digito.

///////////////////////////////////////////////////////////////////////////////////////////////////
Con dos teclas en el mismo ciclo se da prioridad al digito mas bajo. (esto es un parche temporal)
///////////////////////////////////////////////////////////////////////////////////////////////////
*/

module decodificador (
    input  wire        HFOSC,
    input  wire        rst,
    input  wire [15:0] tecla_apretada,
    output wire        operador_suma,
    output wire        operador_resta,
    output wire        operador_igual,
    output wire        operador_clear,
    output wire        operador_digito,
    output reg  [3:0]  digito
);

    assign operador_suma  = tecla_apretada[12];   // A
    assign operador_resta = tecla_apretada[13];   // B
    assign operador_igual = tecla_apretada[15];   // D
    assign operador_clear = tecla_apretada[14];    // C

    //digitos: bit = 4*columna + fila. Se ponen en 1 durante un ciclo de HFOSC cuando se aprieta la tecla
    wire t1 = tecla_apretada[0];
    wire t4 = tecla_apretada[1];
    wire t7 = tecla_apretada[2];
    wire t2 = tecla_apretada[4];
    wire t5 = tecla_apretada[5];
    wire t8 = tecla_apretada[6];
    wire t0 = tecla_apretada[7];
    wire t3 = tecla_apretada[8];
    wire t6 = tecla_apretada[9];
    wire t9 = tecla_apretada[10];

    assign operador_digito = t0 | t1 | t2 | t3 | t4 | t5 | t6 | t7 | t8 | t9; //si se apreto algun digito vale 1

    //Al apretarse un digito, oeprador_digito = 1 y busco cual esta apretado asi lo asigno
    always @(posedge HFOSC) begin
        if (rst) digito <= 4'd0;
        else if (operador_digito) begin
            if      (t0) digito <= 4'd0;
            else if (t1) digito <= 4'd1;
            else if (t2) digito <= 4'd2;
            else if (t3) digito <= 4'd3;
            else if (t4) digito <= 4'd4;
            else if (t5) digito <= 4'd5;
            else if (t6) digito <= 4'd6;
            else if (t7) digito <= 4'd7;
            else if (t8) digito <= 4'd8;
            else         digito <= 4'd9;
        end
    end

endmodule

