module toggle_ff (
    input wire clk
    input wire en
    input wire rst
    output wire Q
)

//Instancio el generador 
SB_HFOSC u_SB_HFOSC (
        .CLKHFPU (1'b1),    //es el prendido del oscilador
        .CLKHFEN (1'b1),    //es el enable
        .CLKHF   (clk), //conecto el oscilador a mi señal interna del modulo
        .TRIM0(), .TRIM1(), .TRIM2(), .TRIM3(), .TRIM4(),
        .TRIM5(), .TRIM6(), .TRIM7(), .TRIM8(), .TRIM9()
    );

always @(posedge clk or posedge rst) begin  //Si el rst es no sincronico que active el always para tirar todo a 0
    if(rst) begin   //Le doy prioridad al rst
        assign Q = 1`b0;
    end
    else if(en) begin
        assign Q = ~Q
    end
end

endmodule
