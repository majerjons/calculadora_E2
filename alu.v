`default_nettype none

/* 

ALU BCD

op_sel = 1 ------> suma
op_sel = 0 ------> resta 

FALTA IMPLEMENTAR EL ENABLE!!!!!!!! La idea sería que el resultado está apagado (00...0) cuando en=0 y
está prendido (lo que tenga en la entrada) cuando en=1.

*/

module alu #(
    parameter NUM_DIGITS = 4
)(
    input  wire [NUM_DIGITS*4-1:0] op1,
    input  wire [NUM_DIGITS*4-1:0] op2,
    input  wire                    op_sel,
    output wire [NUM_DIGITS*4-1:0] result,
    output wire                    carry_out
);
    wire [NUM_DIGITS*4-1:0] add_result, sub_result;
    wire                    add_carry,  sub_borrow;

    bcd_adder #(.NUM_DIGITS(NUM_DIGITS)) u_adder (
        .op1       (op1),
        .op2       (op2),
        .result    (add_result),
        .carry_out (add_carry)
    );

    bcd_subtractor #(.NUM_DIGITS(NUM_DIGITS)) u_sub (
        .op1        (op1),
        .op2        (op2),
        .result     (sub_result),
        .borrow_out (sub_borrow)
    );

    assign result    = op_sel ? add_result : sub_result;
    assign carry_out = op_sel ? add_carry  : sub_borrow;
endmodule
