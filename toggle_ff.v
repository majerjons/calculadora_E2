module toggle_ff (
    input wire HFOSC
    input wire en
    input wire rst
    output wire Q
)
always @(posedge HFOSC or posedge rst) begin  //Si el rst es no sincronico que active el always para tirar todo a 0
    if(rst) begin   //Le doy prioridad al rst
        assign Q = 1`b0;
    end
    else if(en) begin
        assign Q = ~Q;
    end
end

endmodule
