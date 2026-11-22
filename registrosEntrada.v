module registrosEntrada(
    input  wire       HFOSC,
    input wire        en_digito,
    input wire        en_operador,
    input wire        operador_suma,
    input wire        operador_resta,
    input wire        operador_digito,
    input wire[3:0]   digito,
    input wire[1:0]   opN, // 01 ingreso op1 - 10 ingreso op2 (para saber en cual guardar el numero) - 00 ninguno

    output reg[15:0] op1 = 16'b0,
    output reg[15:0] op2 = 16'b0,
    output reg operador // 1 suma - 0 resta
);

always @(posedge HFOSC) begin
    if (en_operador) begin
        if (operador_suma) operador = 1'b1;
        if (operador_resta) operador = 1'b0; //Si se aprietan suma y resta, queda resta (porque si, arbitrario)
    end
    if(operador_digito && en_digito) begin
        if(opN==2'b1)   op1 = (op1<<4) | {12'b0, digito};
        if(opN==2'b2)   op2 = (op2<<4) | {12'b0, digito};
    end
end

endmodule


