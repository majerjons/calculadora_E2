`default_nettype none

// Restador BCD combinacional de NUM_DIGITS dígitos (op1 - op2)
module bcd_subtractor #(
    parameter NUM_DIGITS = 4
)(
    input  wire [NUM_DIGITS*4-1:0] op1,
    input  wire [NUM_DIGITS*4-1:0] op2,
    output reg  [NUM_DIGITS*4-1:0] result,
    output reg                     borrow_out   // 1 si op1 < op2 (resultado negativo)
);
    integer i;
    reg [4:0] digit_diff;  // el bit 4 indica que hubo borrow
    reg       borrow;

    always @(*) begin
        result = {NUM_DIGITS*4{1'b0}};
        borrow = 1'b0;

        for (i = 0; i < NUM_DIGITS; i = i + 1) begin
            digit_diff = {1'b0, op1[i*4 +: 4]} - {1'b0, op2[i*4 +: 4]} - {4'b0, borrow};

            if (digit_diff[4]) begin
                // Pidió prestado 16 en vez de 10: restamos 6 para ajustar a BCD
                digit_diff = digit_diff - 5'd6;
                borrow     = 1'b1;
            end else begin
                borrow     = 1'b0;
            end

            result[i*4 +: 4] = digit_diff[3:0];
        end

        borrow_out = borrow;  // VER QUÉ HACE EL DISPOSITIVO EN ESTE CASO
    end
endmodule
