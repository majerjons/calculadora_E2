`default_nettype none

module alu #(
    parameter WIDTH = 8
)(
    input wire [WIDTH-1:0] op1,
    input wire [WIDTH-1:0] op2,
    input wire op_sel,
    output wire [WIDTH-1:0] result
);
    
    assign result = op_sel ? (op1 + op2) : (op1 - op2);
endmodule