//Autor: Solar Grillo, Lucas (LSG).

//Flip-flop T con enable: cada vez que llega un pulso de "en" (el tick), Q cambia de estado.
//Si "en" es un tick de F Hz, Q sale como una onda cuadrada de F/2 Hz.
module toggle_ff (
    input  wire HFOSC,
    input  wire en,
    input  wire rst,
    output reg  Q          // reg porque se asigna dentro de un always
);

always @(posedge HFOSC or posedge rst) begin  //Si el rst es no sincronico que active el always para tirar todo a 0
    if (rst) begin   //Le doy prioridad al rst
        Q <= 1'b0;
    end
    else if (en) begin
        Q <= ~Q;
    end
end

endmodule
