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
    wire tick_datos_disp;       // 48 MHz --> hacerlo de 1 MHz !!
    wire tick_refresco_disp;    // 1KHz
    wire tick_barrido;          // 1KHz
    wire tick_anti_rebote;      // 100Hz

    //Para cambiar la frecuencia de un tick se modifica el parameter
    ticks #(
        .F_IN            (48_000_000),
        .F_TICK_DATOS_DISP  (1_000_000), // 1 MHz
        .F_TICK_REFRESCO_DISP  (1_000), // 1 KHz
        .F_TICK_BARRIDO  (1_000),
        .F_TICK_ANTIREB  (100)
    ) u_ticks (
        .HFOSC               (HFOSC),
        .rst                 (rst),
        .tick_datos_disp (tick_datos_disp),
        .tick_refresco_disp (tick_refresco_disp),
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


    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //FSM, ALU y registros de entrada

    wire[1:0] estado_display, opN, cant_dig_mostrar;
    wire[15:0] op1, op2, result;
    wire operador, en_alu, pulso_dato_disp, rst_input_regs;

    fsm u_fsm (
        .clk(HFOSC),
        .operador_suma(operador_suma),
        .operador_resta(operador_resta),
        .operador_clear(operador_clear),
        .operador_igual(operador_igual),
        .operador_digito(operador_digito),
        .digito(digito),

        .estado_display(estado_display),
        .cant_dig_mostrar(cant_dig_mostrar),
        .opN(opN),
        .operador(operador)
        .rst_input_regs(rst_input_regs),
        .pulso_dato_disp(pulso_dato_disp)
    );

    registrosEntrada u_registrosEntrada (
        .clk(HFOSC),
        .rst_input_regs(rst_input_regs),
        .operador_digito(operador_digito),
        .digito(digito),
        .opN(opN),

        .op1(op1),
        .op2(op2),
    );
    
    alu u_alu(
        .en(en_alu),
        .op1(op1),
        .op2(op2),
        .op_sel(operador),
        
        .result(result),
        .carry_out();
    );

    
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //DISPLAY
    wire[15:0] disp_word;
    wire DataIn_disp, DataEn_disp, tick_datos_disp; // van conectados a la placa!!!

    mux_formato u_mux_disp (
        .clk(HFOSC),
        .op1(op1),
        .op2(op2),
        .res(result),
        .estado(estado_display),
        .cantidad(cant_dig_mostrar),

        .display_word(disp_word),
    );


    transmisor_serie u_transmisor_serie (
        .tick_disp(tick_datos_disp),
        .disp_word(disp_word), //controlado por el mux del display
        .input_en(pulso_dato_disp) // el pulso que mando para mandarle un dato nuevo al display
        
        .salida_serie(DataIn_disp),
        .output_en(DataEn_disp)
    );


    /*
    cables que van a la placa (gpios):
    - tick_refresco_disp --> clk datos display
    - DataEn_disp --> en
    - DataIn_disp --> datos
    - tick_refresco_disp --> clk refreco display
    */


endmodule