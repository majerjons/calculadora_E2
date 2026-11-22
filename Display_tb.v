`default_nettype none
`timescale 1ns/1ps


module display_tb ();


reg clk = 0 ;
reg [15:0]op1, op2, res, try, numero_usado;
reg  [1:0] estado, cantidad;
wire [15:0] numero_salida, display_word;

///////////// transmisor serie

reg reset_tx;
reg input_en_tx;
reg [15:0] dato_tx;

wire salida_serie_tx;
wire output_en_tx;

reg [15:0] recibido;
integer i;


/////

always #1 clk = ~clk; 

mux_formato m1(.clk(clk), .op1(op1), .op2(op2), .res(res), .estado(estado), .cantidad(cantidad), .display_word(display_word));


formateador f1(.clk(clk), .a(numero_usado), .num_format(numero_salida), .cantidad(cantidad));

transmisor_serie tx1(
    .reset(reset_tx),
    .tick_disp(clk),
    .disp_word(dato_tx),
    .input_en(input_en_tx),
    .salida_serie(salida_serie_tx),
    .output_en(output_en_tx)
);

initial begin

    $dumpfile("testbench.vcd");
    $dumpvars(0,display_tb);



    op1 = 16'h1000;
    op2 = 16'h1001;
    res = 16'h1111;
    try = 16'h1234;
    estado = 2'b01;
    cantidad = 3;
    @(negedge clk);
    #0.1;
    $strobe("op1 = %h, op2 = %h, res = %h y display_world = %b", op1, op2, res, display_word);


    numero_usado = try;
    cantidad = 3;
    @(negedge clk);
    #0.1;
    $strobe("entrada %h, salida %b, cantidad %b", numero_usado, numero_salida, cantidad);

        numero_usado = try;
    cantidad = 2;
    @(negedge clk);
    #0.1;
   $strobe("entrada %h, salida %b, cantidad%b", numero_usado, numero_salida, cantidad);

        numero_usado = try;
    cantidad = 1;
    @(negedge clk);
    #0.1;
   $strobe("entrada %h, salida %b, cantidad%b", numero_usado, numero_salida, cantidad);

        numero_usado = try;
    cantidad = 0;
    @(negedge clk);
    #0.1;
    $strobe("entrada %h, salida %b, cantidad%b", numero_usado, numero_salida, cantidad);
    @(negedge clk);
    #0.1;
    $strobe("ahora pruebo el modulo del mux");

    estado = 2'b00;
    cantidad = 3;
    @(negedge clk);
    #0.1;
    $display("mux = %b, salida = %b, cantidad = %b",estado ,display_word, cantidad);
    estado= 2'b01;
    cantidad = 3;
    @(negedge clk);
    #0.1;
    $display("mux = %b, salida = %b, cantidad = %b",estado ,display_word, cantidad);

    estado= 2'b10;
    cantidad = 3;
    @(negedge clk);
    #0.1;
    $display("mux = %b, salida = %b, cantidad = %b",estado ,display_word, cantidad); 

    estado= 2'b11;
    cantidad = 3;

    @(negedge clk);
    #0.1;
    $display("mux = %b, salida = %b, cantidad = %b",estado ,display_word, cantidad);   
    @(negedge clk);
    #0.1;


// ========================================
// TEST DEL TRANSMISOR SERIE
// ========================================

$display("PRUEBA TRANSMISOR SERIE");

// RESET
@(posedge clk);
reset_tx = 1;
input_en_tx = 0;
dato_tx = 16'h84C2;

@(negedge clk);
#0.1;

// INICIO DE TRANSMISION
@(posedge clk);
reset_tx = 0;
input_en_tx = 1;

// Primer flanco descendente: comienza
// la transmision y se congela el dato.
@(negedge clk);

// Cambiamos la entrada para comprobar
// que el transmisor usa el dato guardado.
@(posedge clk);
recibido[15] = salida_serie_tx;

$display("Bit 15 = %b, EN = %b",
         salida_serie_tx, output_en_tx);

if (output_en_tx !== 1'b1)
    $display("ERROR: EN no esta activo");

// Deshabilitamos la solicitud y cambiamos el dato.
input_en_tx = 0;
dato_tx = 16'hFFFF;

// Recibir los otros 15 bits
for (i = 14; i >= 0; i = i - 1) begin

    @(posedge clk);

    recibido[i] = salida_serie_tx;

    $display("Bit %0d = %b, EN = %b",
             i, salida_serie_tx, output_en_tx);

    if (output_en_tx !== 1'b1)
        $display("ERROR: EN bajo durante transmision");
end

// Comparar palabra completa
$display("Dato esperado = %h", 16'h84C2);
$display("Dato recibido = %h", recibido);

if (recibido === 16'h84C2)
    $display("TRANSMISION CORRECTA");
else
    $display("ERROR EN TRANSMISION");

// Comprobar finalizacion
@(negedge clk);
#0.1;

$display("EN al terminar = %b", output_en_tx);

if (output_en_tx === 1'b0)
    $display("FINALIZACION CORRECTA");
else
    $display("ERROR: EN sigue activo");



    $finish;
end

endmodule






