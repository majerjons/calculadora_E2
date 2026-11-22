module top (
    //Pines
    //entradas del teclado (su pull-up se configuro en el archivo de constrains)(logica invertida en el barrido!)
    input  wire gpio_2,
    input  wire gpio_46,
    input  wire gpio_47,
    input  wire gpio_45,
    input  wire boton_rst,

    //salidas del teclado para el ringcounter (el recorrido)
    output wire gpio_48,
    output wire gpio_3,
    output wire gpio_4,
    output wire gpio_44,
);

    //variables globales; el clock de 48MHz y el rst
    wire HFOSC;

    //Logica del rst para comenzar el sistema (lo hice con initial y eso esta mal, funca en pocas fpgas)

    //Lo primero es sincronizar la entrada del rst para evitar la metaestabilidad (lo que vimos de siempre)
    reg [1:0] btn_sync;
    always @(posedge HFOSC)
        btn_sync <= {btn_sync[0], boton_rst};
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

    //---------------- Ticks ----------------
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

    //Teclado 4x4
    wire [3:0]  ring_counter;       // columnas: ring_counter[0] = gpio_48 ... ring_counter[3] = gpio_44
    wire [15:0] matriz;             // foto de las 16 teclas (con rebotes)
    wire [15:0] teclas_estables;    // las 16 teclas ya sin rebotes (1 = apretada)
    wire [15:0] tecla_apretada;     // pulso de 1 ciclo cuando se aprieta una tecla

    //recorrido del teclado
    recorrer_teclado u_recorrer (
        .HFOSC        (HFOSC),            
        .rst          (rst),              
        .tick_barrido (tick_barrido),     // Enable a 1 KHz
        .ring_counter (ring_counter)
    );

    //conecto el bus del ring counter a los pines de las columnas
    assign gpio_48 = ring_counter[0];
    assign gpio_3  = ring_counter[1];
    assign gpio_4  = ring_counter[2];
    assign gpio_44 = ring_counter[3];

    //foto de las teclas: se captura en cada tick_barrido, justo antes de que el ring counter avance.
    //filas[0] = gpio_2, filas[1] = gpio_46, filas[2] = gpio_47, filas[3] = gpio_45
    captura_matriz #(.ACTIVO_BAJO(1)) u_captura (
        .HFOSC   (HFOSC),
        .rst     (rst),
        .en      (tick_barrido),
        .columna (ring_counter),
        .filas   ({gpio_45, gpio_47, gpio_46, gpio_2}),
        .matriz  (matriz)
    );

    //antirrebote: una tecla es "estable" si cambia durante N_MUESTRAS muestras seguidas (a 100Hz, 3 = 20 a 30ms)
    antirrebote #(.ANCHO(16), .N_MUESTRAS(3)) u_antirrebote (
        .HFOSC   (HFOSC),
        .rst     (rst),
        .en      (tick_anti_rebote),
        .entrada (matriz),
        .salida  (teclas_estables)
    );

    //detector de flanco ascendente: 1 pulso por cada pulsacion, sin importar cuanto la mantenga apretada
    detector_flanco #(.ANCHO(16), .MODO(0)) u_flanco (
        .HFOSC (HFOSC),
        .rst   (rst),
        .en    (1'b1),
        .senal (teclas_estables),
        .pulso (tecla_apretada)
    );

        //Decodificador (me indica la tecla apretada)
    wire        operador_suma, operador_resta, operador_igual, operador_clear, operador_digito;
    wire [3:0]  digito;
    
    /*
    operador_digito es una flag. En 1 significa que se ingresó un dígito, y ese 1 dura un ciclo de HFOSC
    operador_suma es una flag. En 1 significa que se ingresó el operador de hacer una suma, y ese 1 dura un ciclo de HFOSC
    idem los otros operador_algo

    los defino como wires porque ya están sincronizados con HFOSC, no hace falta que los sincronice
    */

    decodificador u_decodificador (
        .HFOSC           (HFOSC),
        .rst             (rst),
        .tecla_apretada  (tecla_apretada),     // sale del detector_flanco

        .operador_suma   (operador_suma),      // Obs: operador_suma/resta/igual/clear/digito valen 1 por un ciclo de HFOSC
        .operador_resta  (operador_resta),
        .operador_igual  (operador_igual),
        .operador_clear  (operador_clear),
        .operador_digito (operador_digito),
        .digito          (digito)
    );


    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //REGISTRO DE ENTRADA

    wire[15:0] op1;
    wire[15:0] op2;
    wire[1:0]  opN;
    wire operador, en_digito, en_operador; 
    // wires porque las controlo desde la FSM
    
    registrosEntrada u_registrosEntrada (
        .HFOSC(HFOSC),
        .en_digito(en_digito),
        .en_operador(en_operador),
        .operador_suma(operador_suma),
        .operador_resta(operador_resta),
        .operador_digito(operador_digito),
        .digito(digito),
        .opN(opN),

        .op1(op1),
        .op2(op2),
        .operador(operador) 
    );


    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //FSM de control y ALU


    alu u_alu(
        .op1(op1),
        .op2(op2),
        .op_sel(operador),
    );
    /*
    module alu #(
    parameter NUM_DIGITS = 4
    )(
    input  wire [NUM_DIGITS*4-1:0] op1,
    input  wire [NUM_DIGITS*4-1:0] op2,
    input  wire                    op_sel,
    output wire [NUM_DIGITS*4-1:0] result,
    output wire                    carry_out
    );

    */

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //DISPLAY
    transmisor_serie u_transmisor_serie (
        tick_disp(tick_disp),
        disp_word(disp_word)
    );
    
    
    
    
    /*
    module transmisor_serie (
        input tick_disp, 
        input [15:0] disp_word, 
        input input_en, 
        output reg salida_serie, 
        output reg output_en
    );
    */

endmodule