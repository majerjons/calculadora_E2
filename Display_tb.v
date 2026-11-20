`default_nettype none


module display_tb ();


reg clk = 0 ;
reg [15:0]op1, op2, res, try, numero_usado;
reg  [1:0] estado, cantidad;
wire [15:0] numero_salida, display_word;


always #5 clk = ~clk; 

mux_formato m1(.clk(clk), .op1(op1), .op2(op2), .res(res), .estado(estado), .cantidad(cantidad), .display_word(display_word));


formateador f1(.clk(clk), .a(numero_usado), .num_format(numero_salida), .cantidad(cantidad));

initial begin

    $dumpfile("testbench.vcd");
    $dumpvars(0,display_tb);

    op1 = 16'h1000;
    op2 = 16'h1001;
    res = 16'h1001;
    try = 16'h1234;
    estado = 2'b00;
    cantidad = 3;
     @(negedge clk)
      @(negedge clk)
    $display("op1 = %h, op2 = %h, res = %h y display_world = %b", op1, op2, res, display_word);


    numero_usado = try;
    cantidad = 3;
    #2
    @(negedge clk)
    $display("entrada %h, salida %b, cantidad %b", numero_usado, numero_salida, cantidad);

        numero_usado = try;
    cantidad = 2;
    #2
        @(negedge clk)
    $display("entrada %h, salida %b, cantidad%b", numero_usado, numero_salida, cantidad);

        numero_usado = try;
    cantidad = 1;
    #2
        @(negedge clk)
    $display("entrada %h, salida %b, cantidad%b", numero_usado, numero_salida, cantidad);

        numero_usado = try;
    cantidad = 0;
    #2
        @(negedge clk)
    $display("entrada %h, salida %b, cantidad%b", numero_usado, numero_salida, cantidad);


    $display("ahora pruebo el modulo del mux");

    estado = 2'b00;
    cantidad = 3;
    @(negedge clk)
    $display("mux = %b, salida = %b, cantidad = %b",estado ,display_word, cantidad);
    estado= 2'b01;
    cantidad = 3;
        @(negedge clk)
    $display("mux = %b, salida = %b, cantidad = %b",estado ,display_word, cantidad);

    estado= 2'b10;
    cantidad = 3;
        @(negedge clk)
    $display("mux = %b, salida = %b, cantidad = %b",estado ,display_word, cantidad); 

    estado= 2'b11;
    cantidad = 3;

        @(negedge clk)
    $display("mux = %b, salida = %b, cantidad = %b",estado ,display_word, cantidad);   

    $finish;
end

endmodule






