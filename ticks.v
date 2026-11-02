//Autor: Solar Grillo, Lucas (LSG).

/*
Para el clock lo ideal es usar el oscilador interno debido a que tiene psitas globales para clock-skew
Ademas de que garantiza la no metaestabilidad. La forma de abordarlo es hacer un generador de ticks
que van a todos los enables de los dispositivos. El clock debe ser multiplo del oscilador sino requiero
un PLL pues esta el problema del jitter para el contador que solo cuenta enteros.
*/


module ticks (

    output wire tick_enable_interno
    output wire tick_enable_externo
    output wire tick_barrido;
    output wire tick_anti_rebote;

)

//instancio al oscilador interno, no es un clock, me toca craftearlo
SB_HFOSC u_SB_HFOSC (
        .CLKHFPU (1'b1),    //es el prendido del oscilador
        .CLKHFEN (1'b1),    //es el enable
        .CLKHF   (HFOSC), //conecto el oscilador a mi señal interna del modulo
        .TRIM0(), .TRIM1(), .TRIM2(), .TRIM3(), .TRIM4(),
        .TRIM5(), .TRIM6(), .TRIM7(), .TRIM8(), .TRIM9()
    );

wire HFOSC; 

always @(posedge HFOSC) begin

end




endmodule