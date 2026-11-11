//Autores: Solar Grillo, Lucas. LSG

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

    creo que operador_digito está bien implementado, operador_suma y los otros tendría que revisarlos
    */

    decodificador u_decodificador (
        .HFOSC           (HFOSC),
        .rst             (rst),
        .tecla_apretada  (tecla_apretada),     // sale del detector_flanco
        .operador_suma   (operador_suma),
        .operador_resta  (operador_resta),
        .operador_igual  (operador_igual),
        .operador_clear  (operador_clear),
        .operador_digito (operador_digito),
        .digito          (digito)
    );

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //FSM de control. Las salidas del decodificador dependen de la FSM por eso ya dejo algo estructurado de la misma.
  
    wire op1_en = 1'b0;
    wire op2_en = 1'b0;
    wire clear  = operador_clear;
    /*
    Más flags
    
    La idea es que op1_en está en 1 cuando se ingresó el 1er primer número/operando de la operación y 
    op2_en cuando ingesó el 2do.
    
    Los valores asignados son provisorios

    OJO que operador_suma/resta/igual/clear/digito valen 1 por un ciclo de HFOSC osea los tengo que
    guardar de alguna forma para usarlos en la FSM por mas tiempo.
    */

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    //REGISTRO DE ENTRADA

    // se guarda el número que se está tipeando con todos sus dígitos, y luego se pasa al registro general

    //ej de como queda: 
    /*
    Ejemplo si presiono lso sigueintes numeros en etse orden: 5-2-8-3
    1. Estado inicial: 
        // bcd = 16'h0000, cantidad = 3'd0
     2. Ingresa '5':    
        // bcd = 16'h0005, cantidad = 3'd1  (Entra por la derecha)
     3. Ingresa '2':    
        // bcd = 16'h0052, cantidad = 3'd2  (Desplaza el 5 a decenas)
     4. Ingresa '8':    
        // bcd = 16'h0528, cantidad = 3'd3  (Desplaza a centenas)
     5. Ingresa '3':    
        // bcd = 16'h5283, cantidad = 3'd4  (Resultado final)
    */
    wire [15:0] bcd;
    wire [2:0]  cantidad; // cantidad de dígitos ingresados

    registro_entrada u_registro_entrada (
        .HFOSC    (HFOSC),
        .rst      (rst),
        .clear    (clear),
        .op1_en   (op1_en),
        .op2_en   (op2_en),
        .digito   (digito),
        .bcd      (bcd),
        .cantidad (cantidad)
    );


/*
variable "estado" (pasarle al control del display)
opcion 0 --> mostrar operador 1 (el numero completo, con los digitos que tenga)
opcion 1 --> mostrar operador 2
opcion 3--> clear (pone en 0 el display)
opcion 4--> mostrar resultado 
*/

endmodule