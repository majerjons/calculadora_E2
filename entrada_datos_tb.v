//Testbench 1: entrada de datos sin el antirrebote.
//Primero se prueban los ticks, de ahi al recorrer_teclado, luego el teclado simulado y finalmente la captura de la matriz ticks
//La idea es ver que llega al teclado con los rebotes simulados.

//Para poder verlo en el GTKWave se reduce las frecuencias asi el barrido no tapa los rebotes. 1ms real son 10 ciclos en este testbench
//   real:   HFOSC 48 MHz, barrido 1 kHz (48000 ciclos por columna)
//   aca:    HFOSC  1 kHz, barrido 100 Hz (10 ciclos por columna, 40 ciclos por barrido completo)

//Para correrlo:  iverilog -g2012 -o entrada_datos.vvp entrada_datos_tb.v ticks.v contador.v comparador.v recorrer_teclado.v copia_matriz.v
//         vvp entrada_datos.vvp      y despues      gtkwave entrada_datos_tb.vcd

`timescale 1ns/1ps

module entrada_datos_tb;

    //----------- Parametros que se pueden tocar -----------
    localparam F_IN      = 1000;   // "HFOSC" reducido
    localparam F_BARRIDO = 100;    // 10 ciclos por columna
    localparam F_ANTIREB = 10;     // no se usa en este testbench (ticks lo pide)
    localparam HOLD      = 200;    // ciclos que se mantiene apretada una tecla antes de chequear
    localparam REB_MIN   = 10;     // cada rebote dura entre 1 ms y 8 ms reales (10 ciclos = 1 ms)
    localparam REB_MAX   = 80;

    //----------- Clock y reset -----------
    reg HFOSC = 1'b0;
    always #5 HFOSC = ~HFOSC;      // periodo 10 ns
    reg rst = 1'b1;

    //----------- DUT -----------
    wire tick_enable_interno, tick_enable_externo, tick_barrido, tick_anti_rebote;
    ticks #(.F_IN(F_IN), .F_TICK_INTERNO(F_IN), .F_TICK_EXTERNO(F_BARRIDO),
            .F_TICK_BARRIDO(F_BARRIDO), .F_TICK_ANTIREB(F_ANTIREB)) u_ticks (
        .HFOSC(HFOSC), .rst(rst),
        .tick_enable_interno(tick_enable_interno), .tick_enable_externo(tick_enable_externo),
        .tick_barrido(tick_barrido), .tick_anti_rebote(tick_anti_rebote));

    wire [3:0] ring_counter;
    recorrer_teclado u_recorrer (.HFOSC(HFOSC), .rst(rst), .tick_barrido(tick_barrido), .ring_counter(ring_counter));

    //----------- Teclado simulado -----------
    //pres[4*c + f] = 1 si la tecla de la columna c y fila f esta apretada.
    //Filas con pull-up (reposo = 1). Una tecla apretada conecta su fila con la columna ACTIVA (la que esta en 0).
    reg  [15:0] pres = 16'b0;
    reg  [3:0]  filas;
    integer c, f;
    always @* begin
        filas = 4'b1111;
        for (c = 0; c < 4; c = c + 1)
            for (f = 0; f < 4; f = f + 1)
                if (pres[4*c + f] && ring_counter[c] == 1'b0) filas[f] = 1'b0;
    end

    wire [15:0] matriz;
    captura_matriz #(.ACTIVO_BAJO(1)) u_captura (
        .HFOSC(HFOSC), .rst(rst), .en(tick_barrido), .columna(ring_counter), .filas(filas), .matriz(matriz));

    //----------- Herramientas del testbench -----------
    integer seed = 7;
    function integer rnd(input integer lo, input integer hi);   // numero pseudoaleatorio entre lo y hi
        begin rnd = lo + ({$random(seed)} % (hi - lo + 1)); end
    endfunction

    //Rebota la tecla k: la invierte "cambios" veces con tiempos al azar entre REB_MIN y REB_MAX ciclos y la deja en valor_final
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

    integer errores = 0;
    integer cambios_matriz = 0;
    always @(matriz) cambios_matriz = cambios_matriz + 1;

    task chequear(input [15:0] esperado, input [255:0] txt);
        begin
            if (matriz !== esperado) begin
                errores = errores + 1;
                $display("[%0t] ERROR %0s: matriz = %b, esperado %b", $time, txt, matriz, esperado);
            end
            else $display("[%0t] ok    %0s: matriz = %b", $time, txt, matriz);
        end
    endtask

    //El ring counter debe tener siempre un unico 0 que recorre las columnas
    always @(posedge HFOSC)
        if (!rst && !(ring_counter == 4'b1110 || ring_counter == 4'b1101 ||
                      ring_counter == 4'b1011 || ring_counter == 4'b0111)) begin
            errores = errores + 1;
            $display("[%0t] ERROR ring_counter invalido: %b", $time, ring_counter);
        end

    integer antes;
    initial begin
        $dumpfile("entrada_datos_tb.vcd");
        $dumpvars(0, entrada_datos_tb);
        repeat (5) @(posedge HFOSC);
        rst = 1'b0;
        repeat (50) @(posedge HFOSC);
        chequear(16'h0000, "sin teclas apretadas");

        $display("\n== 1) Tecla k5 (columna 1, fila 1) con rebotes al apretar y al soltar ==");
        antes = cambios_matriz;
        rebotar(5, 1'b1, 9);                     // rebota 9 veces y queda apretada
        $display("      cambios en matriz mientras rebotaba: %0d (el antirrebote tiene que filtrar esto)", cambios_matriz - antes);
        repeat (HOLD) @(posedge HFOSC);
        chequear(16'b0000_0000_0010_0000, "k5 apretada y estable");

        $display("\n== 2) Se mantiene apretada: matriz no debe cambiar ==");
        antes = cambios_matriz;
        repeat (500) @(posedge HFOSC);
        if (cambios_matriz != antes) begin errores = errores + 1; $display("ERROR matriz cambio con la tecla mantenida"); end
        else $display("ok    matriz estable durante 500 ciclos");

        $display("\n== 3) Se suelta con rebotes ==");
        antes = cambios_matriz;
        rebotar(5, 1'b0, 8);
        $display("      cambios en matriz mientras rebotaba: %0d", cambios_matriz - antes);
        repeat (HOLD) @(posedge HFOSC);
        chequear(16'h0000, "k5 soltada");

        $display("\n== 4) Dos teclas en filas y columnas distintas (k0 y k10) ==");
        rebotar(0, 1'b1, 4); rebotar(10, 1'b1, 5);
        repeat (HOLD) @(posedge HFOSC);
        chequear(16'b0000_0100_0000_0001, "k0 y k10 apretadas");
        rebotar(0, 1'b0, 3); rebotar(10, 1'b0, 3);
        repeat (HOLD) @(posedge HFOSC);
        chequear(16'h0000, "ambas soltadas");

        $display("\n== 5) Las 16 teclas, una por una (con rebotes): cada una aparece en su bit ==");
        begin : barrido_16
            integer k;
            for (k = 0; k < 16; k = k + 1) begin
                rebotar(k, 1'b1, 4);
                repeat (HOLD) @(posedge HFOSC);
                if (matriz !== (16'b1 << k)) begin errores = errores + 1; $display("ERROR tecla k%0d: matriz = %b", k, matriz); end
                rebotar(k, 1'b0, 4);
                repeat (HOLD) @(posedge HFOSC);
            end
            $display("      barrido de las 16 teclas terminado");
        end
        chequear(16'h0000, "todo suelto");

        if (errores == 0) $display("\nENTRADA DE DATOS: TODO OK");
        else              $display("\nENTRADA DE DATOS: %0d ERRORES", errores);
        $finish;
    end
endmodule
