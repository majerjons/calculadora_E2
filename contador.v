//Autor: Solar Grillo, Lucas (LSG).

//Defino la cantidad de estados: M= fin/(2.fout)
//Suponiendo que quiero hasta 1MHz, M= 48MHz/(2.1MHz) = 24 estados
//Luego calculo la cantidad de flipflops: log base 2 de (24) = 4.53 = 5 flip flops (1 flip flip = 1bit)

module #(
        //Las frecuencias definidas
        parameter INPUT_HFOSC          = 48000000,
        parameter CLK_EXT              = 5000,
        parameter CLK_INT              = 48000000,
        parameter TICK_BARRIDO         = 1,
        parameter TICK_ANTI_REBOTE     = 1,

        // Los M estados del contador: M = fin / (2 * fout)
        parameter M_INTERNO            = INPUT_HFOSC / (2 * CLK_INT),
        parameter M_EXTERNO            = INPUT_HFOSC / (2 * CLK_EXT),
        parameter M_BARRIDO            = INPUT_HFOSC / (2 * TICK_BARRIDO),
        parameter M_ANTI_REBOTE        = INPUT_HFOSC / (2 * TICK_ANTI_REBOTE),

        // Cuentas automáticas de bits necesarios usando logaritmo en base 2 ($clog2)
        parameter BIT_INTERNO          = (M_INTERNO > 1) ? $clog2(M_INTERNO) : 1,
        parameter BIT_EXTERNO          = (M_EXTERNO > 1) ? $clog2(M_EXTERNO) : 1,
        parameter BIT_TICK_BARRIDO     = (M_BARRIDO > 1) ? $clog2(M_BARRIDO) : 1,
        parameter BIT_TICK_ANTIREBOTE  = (M_ANTI_REBOTE > 1) ? $clog2(M_ANTI_REBOTE) : 1

)(
    input wire rst
    input wire HFOSC
    output wire contador_interno
    output wire contador_externo
    output wire contador_tick_barrido
    output wire contador_tick_anti_rebote
)
reg [BIT_INTERNO-1 : 0] contador_interno;
reg [BIT_EXTERNO-1 : 0] contador_externo;
reg [BIT_TICK_BARRIDO-1 : 0] contador_barrido;
reg [BIT_TICK_ANTIREBOTE-1 : 0] contador_antirebote;
//Si queiren un clock mayor al HFOSC me la mama y les mando el HFOSC, no hay mayor frecuencia que esa en el
//sistema.
generate
    if(CLK_INT >= INPUT_HFOSC) begin
        assign contador_interno = HFOSC;
    end
    else if (CLK_INT < INPUT_HFOSC) begin

        always @(negedge HFOSC or negedge rst) begin
                contador_interno 


        end
    end
endgenerate






endmodule