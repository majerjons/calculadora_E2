//Autor: Solar Grillo, Lucas (LSG).

/*
Para el clock lo ideal es usar el oscilador interno debido a que tiene psitas globales para clock-skew
Ademas de que garantiza la no metaestabilidad. La forma de abordarlo es hacer un generador de ticks
que van a todos los enables de los dispositivos. El clock debe ser multiplo del oscilador sino requiero
un PLL pues esta el problema del jitter para el contador que solo cuenta enteros.
*/

/*
Generador de ticks para los enables del sistema. El clock de todos los FF es siempre HFOSC (48MHz),
estos ticks no son clocks: son pulsos de 1 ciclo de HFOSC que se usan como "en" de los modulos.
Para cambiar la frecuencia de un tick solo hay que modificar su parameter (F_*).
F_IN debe ser multiplo entero de F_OUT, sino la division entera hace que la frecuencia real no sea la pedida.
*/

module ticks #(
    parameter F_IN             = 48_000_000,  // Hz, frecuencia del HFOSC
    parameter F_TICK_INTERNO   = 48_000_000,  // Hz, tick_enable_interno (a 48MHz queda siempre en 1)
    parameter F_TICK_EXTERNO   = 1_000,       // Hz, tick_enable_externo
    parameter F_TICK_BARRIDO   = 1_000,       // Hz, tick_barrido (avance del ring counter del teclado)
    parameter F_TICK_ANTIREB   = 100          // Hz, tick_anti_rebote (muestreo del debouncing, 10ms)
)(
    input  wire HFOSC,
    input  wire rst,
    output wire tick_enable_interno,
    output wire tick_enable_externo,
    output wire tick_barrido,
    output wire tick_anti_rebote
);

    //el tipo de dato tick, asi lo reutilizo.
    tick_gen #(.F_IN(F_IN), .F_OUT(F_TICK_INTERNO)) u_tick_interno (
        .HFOSC (HFOSC),
        .rst   (rst),
        .tick  (tick_enable_interno)
    );

    tick_gen #(.F_IN(F_IN), .F_OUT(F_TICK_EXTERNO)) u_tick_externo (
        .HFOSC (HFOSC),
        .rst   (rst),
        .tick  (tick_enable_externo)
    );

    tick_gen #(.F_IN(F_IN), .F_OUT(F_TICK_BARRIDO)) u_tick_barrido (
        .HFOSC (HFOSC),
        .rst   (rst),
        .tick  (tick_barrido)
    );

    tick_gen #(.F_IN(F_IN), .F_OUT(F_TICK_ANTIREB)) u_tick_anti_rebote (
        .HFOSC (HFOSC),
        .rst   (rst),
        .tick  (tick_anti_rebote)
    );

endmodule


// Un generador de tick = contador + comparador. El comparador avisa cuando count == M-1
// y esa misma salida limpia el contador, entonces cuenta 0..M-1 y tira 1 pulso por periodo.
// Con F_OUT == F_IN: M = 1, el contador queda siempre en 0 y fin queda siempre en 1 (el sintetizador lo optimiza).

//el modulo de tick_gen/ tipo de dato. Yo lo instancie arribe/cree su estructura con sus datos
//el tema es que sus datos/campo dependen de lo que regresen las funciones contador y comparador
//Tipo es todo anidado, creo mi tipo de dato tick, le cargo los valores iniciales, los tira los modulos
//contador y comparador y a medida que se actualizan sus valores me devuelva el tick.
module tick_gen #(
    parameter F_IN  = 48_000_000,
    parameter F_OUT = 1_000
)(
    input  wire HFOSC,
    input  wire rst,
    output wire tick
);

    // Misma M y WIDTH que usan contador y comparador (CUADRADA = 0 -> tick)
    localparam M     = F_IN / F_OUT;
    localparam WIDTH = (M > 1) ? $clog2(M) : 1;

    wire [WIDTH-1:0] count;

    //instancio al contador
    contador #(.F_IN(F_IN), .F_OUT(F_OUT), .CUADRADA(0)) u_contador (
        .HFOSC (HFOSC),
        .rst   (rst),
        .clear (tick),     // la salida del comparador reinicia la cuenta
        .en    (1'b1),
        .count (count)
    );

    //instancio al comparador
    comparador #(.F_IN(F_IN), .F_OUT(F_OUT), .CUADRADA(0)) u_comparador (
        .count (count),
        .fin   (tick)
    );

endmodule