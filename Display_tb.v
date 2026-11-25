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
wire clk_disp_tx;

reg [15:0] recibido;
integer i;


/////

// Prueba del divisor
reg reset_div = 1;
wire clk_div;

clock_transmisor div1(
    .reset(reset_div),
    .clk(clk),
    .clk_disp(clk_div)
);

// Prueba del detector de flancos
wire tick_test;

detec_flanco det1(
    .clk(clk),
    .clk_disp(clk_div),
    .n_egedge(tick_test)
);

realtime t1, t2;

always #10.416667 clk = ~clk; //para tener el clock de 48myhz

mux_formato m1(.clk(clk), .op1(op1), .op2(op2), .res(res), .estado(estado), .cantidad(cantidad), .display_word(display_word));


formateador f1(.clk(clk), .a(numero_usado), .num_format(numero_salida), .cantidad(cantidad));

transmisor_serie tx1(
    .clk(clk),
    .reset(reset_tx),
    .disp_word(dato_tx),
    .input_en(input_en_tx),
    .salida_serie(salida_serie_tx),
    .output_en(output_en_tx),
    .clk_disp(clk_disp_tx)
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
    $display("op1 = %h, op2 = %h, res = %h y display_world = %b", op1, op2, res, display_word);


    numero_usado = try;
    cantidad = 3;
    @(negedge clk);
    #0.1;
    $display("entrada %h, salida %b, cantidad %b", numero_usado, numero_salida, cantidad);

        numero_usado = try;
    cantidad = 2;
    @(negedge clk);
    #0.1;
   $display("entrada %h, salida %b, cantidad%b", numero_usado, numero_salida, cantidad);

        numero_usado = try;
    cantidad = 1;
    @(negedge clk);
    #0.1;
   $display("entrada %h, salida %b, cantidad%b", numero_usado, numero_salida, cantidad);

        numero_usado = try;
    cantidad = 0;
    @(negedge clk);
    #0.1;
    $display("entrada %h, salida %b, cantidad%b", numero_usado, numero_salida, cantidad);
    @(negedge clk);
    #0.1;
    $display("ahora pruebo el modulo del mux");

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

// Reset
@(posedge clk);
reset_tx = 1;
input_en_tx = 0;
dato_tx = 16'h84C2;

repeat (5) @(posedge clk);

// Pedido de transmision
reset_tx = 0;
input_en_tx = 1;

// input_en dura un ciclo de 48 MHz
@(posedge clk);
input_en_tx = 0;

// Cambiar dato para probar la memoria interna
dato_tx = 16'hFFFF;

// Esperar que comience la transmision
wait(output_en_tx == 1'b1);

// Recibir los 16 bits como el 74HC595
for (i = 15; i >= 0; i = i - 1) begin

    @(posedge clk_disp_tx);

    recibido[i] = salida_serie_tx;

    $display("Bit %0d = %b, EN = %b",
             i, salida_serie_tx, output_en_tx);

    if (output_en_tx !== 1'b1)
        $display("ERROR: EN bajo");
end

// Verificar palabra recibida
$display("Esperado = %h", 16'h84C2);
$display("Recibido = %h", recibido);

if (recibido === 16'h84C2)
    $display("TRANSMISION CORRECTA");
else
    $display("ERROR EN TRANSMISION");

// Esperar la finalizacion
@(negedge clk_disp_tx);
repeat (5) @(posedge clk);

if (output_en_tx === 1'b0)
    $display("FINALIZACION CORRECTA");
else
    $display("ERROR: EN sigue activo");

// Comprobar que no reinicia solo
repeat (2) @(posedge clk_disp_tx);

if (output_en_tx === 1'b0)
    $display("REPOSO CORRECTO");
else
    $display("ERROR: TRANSMISION REPETIDA");


// ========================================
// TEST DEL DIVISOR DE FRECUENCIA
// ========================================

$display("PRUEBA DIVISOR");

@(posedge clk);
reset_div = 1;

repeat (5) @(posedge clk);
reset_div = 0;

// Medir periodo
@(posedge clk_div);
t1 = $realtime;

@(posedge clk_div);
t2 = $realtime;

$display("Periodo = %f ns", t2-t1);
$display("Frecuencia = %f Hz", 1.0e9/(t2-t1));

// ========================================
// TEST DEL DETECTOR DE FLANCOS
// ========================================

$display("PRUEBA DETECTOR DE FLANCOS");

// Esperar flanco descendente
@(negedge clk_div);
t1 = $realtime;

// Esperar tick
@(posedge tick_test);

$display("Tick detectado");
$display("Retardo = %f ns", $realtime-t1);

t1 = $realtime;

// Medir duracion del tick
@(negedge tick_test);
t2 = $realtime;

$display("Duracion tick = %f ns", t2-t1);

$finish;


    $finish;
end

endmodule






