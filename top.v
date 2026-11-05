//Autores: Solar Grillo, Lucas. LSG

module top (
    //Pines
    //entradas del teclado (su pull-up se configuro en el archivo de constrains)(logica invertida en el barrido!)
    input  wire gpio_2,
    input  wire gpio_46,
    input  wire gpio_47,
    input  wire gpio_45,
    input wire rst,

    //salidas del teclado para el ringcounter (el recorrido)
    output wire gpio_48,
    output wire gpio_3,
    output wire gpio_4,
    output wire gpio_44
);

    //variables globales; el clock de 48MHz y el rst
    wire HFOSC;
    reg [1:0] btn_sync;

    //Logica del rst para comenzar el sistema (lo hice con initialize y eso esta mal, funca en pocas fpgas)
    
    //Lo primero es sincronizar la entrada del rst para evitar la metaestabilidad (lo que vimos de siempre)
    reg [1:0] btn_sync;
    always @(posedge HFOSC)
        btn_sync <= {btn_sync[0], rst_btn};
    wire btn_rst = btn_sync[1];

    //Luego esta la logica del contador de ciclos del clk, la idea es dejarlo 8 ciclos de clk el reset activo
    //desde que se lo presiono.
    reg [3:0] rst_cnt;
    reg       rst;
    always @(posedge HFOSC) begin
        if (btn_rst) begin                  // boton apretado: reinicio la secuencia
            rst_cnt <= 4'd0;
            rst     <= 1'b1;
        end
        else if (rst_cnt != 4'd8) begin     // contando los ciclos de reset
            rst_cnt <= rst_cnt + 1'b1;
            rst     <= 1'b1;
        end
        else begin                          // termino: libero el reset
            rst     <= 1'b0;
        end
    end

    //instancio al oscilador interno, no es un clock, me toca craftearlo
    SB_HFOSC #(
        .CLKHF_DIV("0b00")   // 0b00 = 48MHz, 0b01 = 24MHz, 0b10 = 12MHz, 0b11 = 6MHz
    ) u_SB_HFOSC (
        .CLKHFPU (1'b1),    //es el prendido del oscilador
        .CLKHFEN (1'b1),    //es el enable
        .CLKHF   (HFOSC)    //conecto el oscilador a mi senial interna del modulo
    );

    wire tick_enable_interno;   // 48MHz
    wire tick_enable_externo;   // 1KHz
    wire tick_barrido;          // 1KHz
    wire tick_anti_rebote;      // 100Hz

    //Para cambiar la frecuencia de un tick se modifica el parameter
    ticks #(
        .F_IN            (48_000_000),
        .F_TICK_INTERNO  (48_000_000),
        .F_TICK_EXTERNO  (1_000),
        .F_TICK_BARRIDO  (1_000),
        .F_TICK_ANTIREB  (100)
    ) u_ticks (
        .HFOSC               (HFOSC),
        .rst                 (rst),
        .tick_enable_interno (tick_enable_interno),
        .tick_enable_externo (tick_enable_externo),
        .tick_barrido        (tick_barrido),
        .tick_anti_rebote    (tick_anti_rebote)
    );

    //recorrido del teclado
    recorrer_teclado u_recorrer (
        .clk          (HFOSC),                                     // Reloj principal a 48 MHz
        .rst          (rst),                                       // Reset conectado al reg rst
        .tick_barrido (tick_barrido),                              // Enable a 1 KHz
        .ring_counter ({gpio_44, gpio_4, gpio_3, gpio_48})         // Conexión directa del bus [3:0] a los pines
    );

endmodule