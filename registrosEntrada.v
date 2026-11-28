module registrosEntrada(
    input wire        clk,
    input wire        rst,
    input wire        operador_clear,
    input wire        operador_digito,
    input wire[3:0]   digito,
    input wire[1:0]   opN, // 01 ingreso op1 - 10 ingreso op2 (para saber en cual guardar el numero) - 00 ninguno

    output reg[15:0] op1 = 16'b0,
    output reg[15:0] op2 = 16'b0
);

reg operador_digito_propag = 1'b0;

always @(posedge clk) begin
    operador_digito_propag <= operador_digito;

    if (operador_clear || rst) begin
        op1 <= 16'b0;
        op2 <= 16'b0;
    end
    else if (operador_digito_propag && opN) begin
        if(opN==2'b1)   op1 <= (op1<<4) | {12'b0, digito};
        if(opN==2'b10)   op2 <= (op2<<4) | {12'b0, digito};
    end
end

endmodule



