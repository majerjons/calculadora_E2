//Autor: Solar Grillo, Lucas (LSG).

/*
Para el clock lo ideal es usar el oscilador interno debido a que tiene psitas globales para clock-skew
Ademas de que garantiza la no metaestabilidad. La forma de abordarlo es hacer un generador de ticks
que van a todos los enables de los dispositivos. El clock debe ser multiplo del oscilador sino requiero
un PLL pues esta el problema del jitter para el contador que solo cuenta enteros.
*/


module ticks (

    input wire HFOSC
    output wire tick_enable_interno
    output wire tick_enable_externo
    output wire tick_barrido;
    output wire tick_anti_rebote;

)


always @(posedge HFOSC) begin

end




endmodule