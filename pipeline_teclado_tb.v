//Testbench 4: todo junto. Teclado simulado con rebotes -> barrido -> captura -> antirrebote -> detector de flanco ->
//decodificador -> registro de entrada. Es el mismo pipeline del top, con la FSM reemplazada por algo temporal...
//
//La FSM todavia no existe: en el top, op1_en y op2_en estan en 0 (valores provisorios) y clear = operador_clear.
//El parametro MODO_EN elige como se generan esos enables en este testbench:
//   MODO_EN = 0 -> op1_en = 0. El registro de entrada nunca carga. Sirve para ver que el pipeline
//                  llega hasta el decodificador y que "no pasa nada" en el registro.
//   MODO_EN = 1 -> FSM provisoria: op1_en = operador_digito retrasado 1 ciclo. Se retrasa porque "digito" del decodificador
//                  es un registro y recien vale en el ciclo siguiente al pulso (si op1_en fuera en el mismo ciclo,
//                  el registro cargaria el digito anterior).
//
//Siempre se chequea el decodificador por su cuenta (no depende de la FSM):
//   - cada digito da 1 solo pulso de operador_digito, y "digito" vale lo que corresponde un ciclo despues y se retiene
//   - las teclas A, B, D y C dan un pulso de 1 ciclo en operador_suma / resta / igual / clear, y ninguna otra senal
//
//Frecuencias reducidas para verlo (1ms = 10 ciclos):
//   barrido 100 Hz (10 ciclos por columna), antirrebote 10 Hz (100 ciclos entre muestras, confirma en 200 a 300 ciclos).
//
//Codigo de testeo:
//  iverilog -g2012 -o pipeline.vvp pipeline_teclado_tb.v ticks.v contador.v comparador.v recorrer_teclado.v copia_matriz.v antirebote.v detector_flancos.v decoder_teclado.v registros_entrada.v
//  vvp pipeline.vvp      y despues      gtkwave pipeline_teclado_tb.vcd

`timescale 1ns/1ps

module pipeline_teclado_tb;

    //----------- Parametros que se pueden tocar -----------
    localparam MODO_EN   = 1;         // 0 = como el top actual (op1_en = 0), 1 = FSM provisoria
    localparam F_IN      = 1000;
    localparam F_BARRIDO = 100;
    localparam F_ANTIREB = 10;
    localparam HOLD      = 700;       // ciclos con la tecla apretada (mas que lo que tarda en confirmarse)
    localparam REPOSO    = 500;       // ciclos con todo suelto entre tecla y tecla
    localparam REB_MIN   = 10;        // cada rebote dura entre 1 y 8 ms reales
    localparam REB_MAX   = 80;

    reg HFOSC = 1'b0;
    always #5 HFOSC = ~HFOSC;
    reg rst = 1'b1;

    //----------- Pipeline (igual que el top) -----------
    wire tick_enable_interno, tick_enable_externo, tick_barrido, tick_anti_rebote;
    ticks #(.F_IN(F_IN), .F_TICK_INTERNO(F_IN), .F_TICK_EXTERNO(F_BARRIDO),
            .F_TICK_BARRIDO(F_BARRIDO), .F_TICK_ANTIREB(F_ANTIREB)) u_ticks (
        .HFOSC(HFOSC), .rst(rst), .tick_enable_interno(tick_enable_interno), .tick_enable_externo(tick_enable_externo),
        .tick_barrido(tick_barrido), .tick_anti_rebote(tick_anti_rebote));

    wire [3:0] ring_counter;
    recorrer_teclado u_recorrer (.HFOSC(HFOSC), .rst(rst), .tick_barrido(tick_barrido), .ring_counter(ring_counter));

    //Teclado simulado (pull-up en las filas, columna activa en 0)
    reg  [15:0] pres = 16'b0;
    reg  [3:0]  filas;
    integer c, f;
    always @* begin
        filas = 4'b1111;
        for (c = 0; c < 4; c = c + 1)
            for (f = 0; f < 4; f = f + 1)
                if (pres[4*c + f] && ring_counter[c] == 1'b0) filas[f] = 1'b0;
    end

    wire [15:0] matriz, teclas_estables, tecla_apretada;
    captura_matriz #(.ACTIVO_BAJO(1)) u_captura (
        .HFOSC(HFOSC), .rst(rst), .en(tick_barrido), .columna(ring_counter), .filas(filas), .matriz(matriz));
    antirrebote #(.ANCHO(16), .N_MUESTRAS(3)) u_antirrebote (
        .HFOSC(HFOSC), .rst(rst), .en(tick_anti_rebote), .entrada(matriz), .salida(teclas_estables));
    detector_flanco #(.ANCHO(16), .MODO(0)) u_flanco (
        .HFOSC(HFOSC), .rst(rst), .en(1'b1), .senal(teclas_estables), .pulso(tecla_apretada));

    wire        operador_suma, operador_resta, operador_igual, operador_clear, operador_digito;
    wire [3:0]  digito;
    decodificador u_decodificador (
        .HFOSC(HFOSC), .rst(rst), .tecla_apretada(tecla_apretada),
        .operador_suma(operador_suma), .operador_resta(operador_resta), .operador_igual(operador_igual),
        .operador_clear(operador_clear), .operador_digito(operador_digito), .digito(digito));

    //Lo que despues va a generar la FSM
    reg op_digito_d = 1'b0;
    always @(posedge HFOSC) op_digito_d <= operador_digito;
    wire op1_en = (MODO_EN == 1) ? op_digito_d : 1'b0;
    wire op2_en = 1'b0;
    wire clear  = operador_clear;

    wire [15:0] bcd;
    wire [2:0]  cantidad;
    registro_entrada u_registro_entrada (
        .HFOSC(HFOSC), .rst(rst), .clear(clear), .op1_en(op1_en), .op2_en(op2_en),
        .digito(digito), .bcd(bcd), .cantidad(cantidad));

    //----------- Monitores del decodificador -----------
    integer pulsos_digito = 0, pulsos_suma = 0, pulsos_resta = 0, pulsos_igual = 0, pulsos_clear = 0;
    reg p_dig = 0, p_sum = 0, p_res = 0, p_ig = 0, p_clr = 0;
    reg [3:0] ult_digito_visto = 4'hF;       // valor de "digito" un ciclo despues de cada pulso de operador_digito
    integer errores = 0;

    always @(posedge HFOSC) begin
        if (!rst) begin
            if (operador_digito) pulsos_digito = pulsos_digito + 1;
            if (operador_suma)   pulsos_suma   = pulsos_suma   + 1;
            if (operador_resta)  pulsos_resta  = pulsos_resta  + 1;
            if (operador_igual)  pulsos_igual  = pulsos_igual  + 1;
            if (operador_clear)  pulsos_clear  = pulsos_clear  + 1;
            //cada operador debe durar un solo ciclo
            if ((operador_digito & p_dig) | (operador_suma & p_sum) | (operador_resta & p_res) | (operador_igual & p_ig) | (operador_clear & p_clr)) begin
                errores = errores + 1;
                $display("[%0t] ERROR un operador duro mas de un ciclo", $time);
            end
            if (op_digito_d) ult_digito_visto = digito;
        end
        p_dig <= operador_digito; p_sum <= operador_suma; p_res <= operador_resta; p_ig <= operador_igual; p_clr <= operador_clear;
    end

    //----------- Herramientas -----------
    integer seed = 3;
    function integer rnd(input integer lo, input integer hi);
        begin rnd = lo + ({$random(seed)} % (hi - lo + 1)); end
    endfunction

    //De la etiqueta de la tecla al bit de la matriz (bit = 4*columna + fila)
    function integer idx(input [7:0] t);
        begin
            case (t)
                "1": idx = 0;  "4": idx = 1;  "7": idx = 2;  "*": idx = 3;
                "2": idx = 4;  "5": idx = 5;  "8": idx = 6;  "0": idx = 7;
                "3": idx = 8;  "6": idx = 9;  "9": idx = 10; "#": idx = 11;
                "A": idx = 12; "B": idx = 13; "C": idx = 14; "D": idx = 15;
                default: idx = 0;
            endcase
        end
    endfunction

    task rebotar(input integer k, input valor_final, input integer cambios);
        integer j;
        begin
            for (j = 0; j < cambios; j = j + 1) begin
                pres[k] = ~pres[k];
                repeat (rnd(REB_MIN, REB_MAX)) @(posedge HFOSC);
            end
            pres[k] = valor_final;
        end
    endtask

    //Aprieta una tecla (con rebotes), la mantiene "mant" ciclos, la suelta (con rebotes) y espera REPOSO ciclos
    task pulsar_mant(input [7:0] t, input integer mant);
        integer k;
        begin
            k = idx(t);
            rebotar(k, 1'b1, 6 + rnd(0, 3));
            repeat (mant) @(posedge HFOSC);
            rebotar(k, 1'b0, 5 + rnd(0, 3));
            repeat (REPOSO) @(posedge HFOSC);
        end
    endtask
    task pulsar(input [7:0] t);
        begin pulsar_mant(t, HOLD); end
    endtask

    //Modelo de lo esperado en el registro de entrada
    reg [15:0] bcd_esp = 16'h0000;
    reg [2:0]  cant_esp = 3'd0;
    reg [3:0]  dig_esp;

    task verificar(input [255:0] txt);
        begin
            if (bcd !== bcd_esp || cantidad !== cant_esp) begin
                errores = errores + 1;
                $display("[%0t] ERROR tras %0s: bcd = %h, cantidad = %0d (esperado %h, %0d)", $time, txt, bcd, cantidad, bcd_esp, cant_esp);
            end
            else $display("[%0t] ok    tras %0s: bcd = %h, cantidad = %0d", $time, txt, bcd, cantidad);
        end
    endtask

    task teclear_digito(input [7:0] t);
        integer antes;
        reg [31:0] nombre;
        begin
            antes = pulsos_digito;
            pulsar(t);
            dig_esp = t - "0";                                   // valor BCD de la tecla
            if (MODO_EN == 1 && cant_esp != 3'd4) begin bcd_esp = {bcd_esp[11:0], dig_esp}; cant_esp = cant_esp + 1'b1; end
            //decodificador: un solo pulso, digito correcto un ciclo despues y retenido
            if (pulsos_digito != antes + 1) begin
                errores = errores + 1;
                $display("[%0t] ERROR tecla '%c': %0d pulsos de operador_digito (esperado 1)", $time, t, pulsos_digito - antes);
            end
            if (ult_digito_visto !== dig_esp || digito !== dig_esp) begin
                errores = errores + 1;
                $display("[%0t] ERROR tecla '%c': digito = %0d un ciclo despues del pulso, %0d despues de soltar (esperado %0d)", $time, t, ult_digito_visto, digito, dig_esp);
            end
            nombre = {8'h27, t, 8'h27, 8'h00};
            verificar(nombre);
        end
    endtask

    //Una tecla de operacion: tiene que subir solo el contador de su operador, en 1
    task probar_operador(input [7:0] t);
        integer d0, s0, r0, i0, c0;
        reg [31:0] nombre;
        reg ok;
        begin
            d0 = pulsos_digito; s0 = pulsos_suma; r0 = pulsos_resta; i0 = pulsos_igual; c0 = pulsos_clear;
            pulsar(t);
            ok = (pulsos_digito == d0)
               && (pulsos_suma  == s0 + (t == "A"))
               && (pulsos_resta == r0 + (t == "B"))
               && (pulsos_igual == i0 + (t == "D"))
               && (pulsos_clear == c0 + (t == "C"));
            if (ok) $display("[%0t] ok    tecla '%c': un pulso de 1 ciclo en su operador y en ningun otro", $time, t);
            else begin
                errores = errores + 1;
                $display("[%0t] ERROR tecla '%c': deltas digito=%0d suma=%0d resta=%0d igual=%0d clear=%0d", $time, t,
                         pulsos_digito - d0, pulsos_suma - s0, pulsos_resta - r0, pulsos_igual - i0, pulsos_clear - c0);
            end
            if (t == "C") begin bcd_esp = 16'h0000; cant_esp = 3'd0; end    // un clear deja el registro en 0 (en los dos modos)
            nombre = {8'h27, t, 8'h27, 8'h00};
            verificar(nombre);
        end
    endtask

    initial begin
        $dumpfile("pipeline_teclado_tb.vcd");
        $dumpvars(0, pipeline_teclado_tb);
        if (MODO_EN == 1) $display("MODO_EN = 1: FSM provisoria, op1_en = operador_digito retrasado 1 ciclo");
        else              $display("MODO_EN = 0: como el top actual, op1_en = 0. El registro NO debe cargar (solo responde a clear)");
        repeat (5) @(posedge HFOSC);
        rst = 1'b0;
        repeat (REPOSO) @(posedge HFOSC);

        $display("\n== Se teclea 5 2 8 3 (con rebotes en cada tecla) ==");
        teclear_digito("5"); teclear_digito("2"); teclear_digito("8"); teclear_digito("3");

        $display("\n== Quinto digito: se ignora (en el registro) ==");
        teclear_digito("9");

        $display("\n== Operadores A (suma), B (resta), D (igual): no tocan el registro ==");
        probar_operador("A"); probar_operador("B"); probar_operador("D");

        $display("\n== Clear (tecla C): borra el registro ==");
        probar_operador("C");

        $display("\n== Otro numero: 0 7 1 ==");
        teclear_digito("0"); teclear_digito("7"); teclear_digito("1");

        $display("\n== Tecla mantenida mucho tiempo: un solo digito ==");
        begin : mantenida
            integer antes;
            antes = pulsos_digito;
            pulsar_mant("6", 5 * HOLD);
            dig_esp = 4'd6;
            if (MODO_EN == 1 && cant_esp != 3'd4) begin bcd_esp = {bcd_esp[11:0], dig_esp}; cant_esp = cant_esp + 1'b1; end
            if (pulsos_digito != antes + 1) begin errores = errores + 1; $display("ERROR tecla mantenida: %0d pulsos (esperado 1)", pulsos_digito - antes); end
            verificar("6 mantenida");
        end

        if (errores == 0) $display("\nPIPELINE COMPLETO: TODO OK");
        else              $display("\nPIPELINE COMPLETO: %0d ERRORES", errores);
        $finish;
    end
endmodule
