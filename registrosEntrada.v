module registrosEntrada(
    input  wire       clk,
    input wire        rst_input_regs,
    input wire        operador_suma,
    input wire        operador_resta,
    input wire        operador_digito,
    input wire[3:0]   digito,
    input wire[1:0]   opN, // 01 ingreso op1 - 10 ingreso op2 (para saber en cual guardar el numero) - 00 ninguno

    output reg[15:0] op1 = 16'b0,
    output reg[15:0] op2 = 16'b0,
);

reg operador_digito_propag = 1'b0;


always @(posedge clk) begin
    if(operador_digito) operador_digito_propag <= 1'b1;
    else operador_digito_propag <= 1'b0;

    if (rst_input_regs) begin
        op1 = 16'b0;
        op2 = 16'b0;
        operador = 1'b0;
    end
    else if (operador_digito_propag && opN) begin
        if(opN==2'b1)   op1 <= (op1<<4) | {12'b0, digito};
        if(opN==2'b2)   op2 <= (op2<<4) | {12'b0, digito};
    end
end

endmodule



