`default_nettype none

// Sumador BCD combinacional de NUM_DIGITS dígitos
module bcd_adder #(
    parameter NUM_DIGITS = 4
)(
    input  wire [NUM_DIGITS*4-1:0] op1,
    input  wire [NUM_DIGITS*4-1:0] op2,
    output reg  [NUM_DIGITS*4-1:0] result,
    output reg                     carry_out
);
    integer i;
    reg [4:0] digit_sum;   // 5 bits para detectar > 9
    reg       carry;

    always @(*) begin
        result = {NUM_DIGITS*4{1'b0}};
        carry  = 1'b0;

        for (i = 0; i < NUM_DIGITS; i = i + 1) begin
            digit_sum = {1'b0, op1[i*4 +: 4]} + {1'b0, op2[i*4 +: 4]} + {4'b0, carry};

            if (digit_sum > 5'd9) begin
                // Ajuste BCD: sumar 6
                digit_sum = digit_sum + 5'd6;
                carry     = 1'b1;
            end else begin
                carry     = 1'b0;
            end

            result[i*4 +: 4] = digit_sum[3:0];
        end

        carry_out = carry;  // VER QUÉ HACE EL DISPOSITIVO EN ESTE CASO
    end
endmodule
