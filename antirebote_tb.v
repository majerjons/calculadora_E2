//Testbench 2: el antirebote de las 1 se;ales sin el teclado
//Se le inyectan rebotes directamente en "entrada" (la matriz) y se mira "salida" (teclas_estables).
//
//Ademas de los casos dirigidos, hay un MODELO DE REFERENCIA escrito de otra forma (historial de las ultimas N muestras)
//que se compara con el DUT en cada ciclo. Si los dos coinciden en todos los rebotes al azar, el filtro anda bien.
//
//Tiene una frecuencia reducida para verlo, el tick de muestreo es cada 10 ciclos (en el real son 10 ms = 480000 ciclos).
//Los rebotes duran entre 2 y 14 ciclos, o sea menos de 1.5 muestras: ninguna secuencia de rebotes llega a tener
//N_MUESTRAS iguales seguidas, que es justo lo que el filtro tiene que rechazar.
//
//Codigo para correrlo:  iverilog -g2012 -o antirebote.vvp antirebote_tb.v antirebote.v ticks.v contador.v comparador.v
//         vvp antirebote.vvp      y despues      gtkwave antirebote_tb.vcd

`timescale 1ns/1ps

module antirebote_tb;

    localparam ANCHO      = 16;
    localparam N_MUESTRAS = 3;
    localparam F_IN       = 1000;
    localparam F_MUESTREO = 100;   // un tick cada 10 ciclos

    reg HFOSC = 1'b0;
    always #5 HFOSC = ~HFOSC;
    reg rst = 1'b1;

    //Tick de muestreo: se usa el mismo tick_gen del proyecto
    wire en;
    tick_gen #(.F_IN(F_IN), .F_OUT(F_MUESTREO)) u_tick (.HFOSC(HFOSC), .rst(rst), .tick(en));

    reg  [ANCHO-1:0] entrada = {ANCHO{1'b0}};
    wire [ANCHO-1:0] salida;
    antirrebote #(.ANCHO(ANCHO), .N_MUESTRAS(N_MUESTRAS)) dut (
        .HFOSC(HFOSC), .rst(rst), .en(en), .entrada(entrada), .salida(salida));

    //----------- Modelo de referencia: la salida cambia cuando las ultimas N muestras son todas el valor opuesto -----------
    reg [ANCHO-1:0] ref_salida = {ANCHO{1'b0}};
    reg [N_MUESTRAS-1:0] hist [0:ANCHO-1];
    integer i;
    initial for (i = 0; i < ANCHO; i = i + 1) hist[i] = {N_MUESTRAS{1'b0}};

    always @(posedge HFOSC) begin
        if (rst) begin
            ref_salida <= {ANCHO{1'b0}};
            for (i = 0; i < ANCHO; i = i + 1) hist[i] <= {N_MUESTRAS{1'b0}};
        end
        else if (en) begin
            for (i = 0; i < ANCHO; i = i + 1) begin
                hist[i] <= {hist[i][N_MUESTRAS-2:0], entrada[i]};
                //con la muestra nueva incluida, las N ultimas son todas distintas de la salida actual?
                if ( {hist[i][N_MUESTRAS-2:0], entrada[i]} == {N_MUESTRAS{~ref_salida[i]}} )
                    ref_salida[i] <= ~ref_salida[i];
            end
        end
    end

    integer errores = 0;
    always @(negedge HFOSC)
        if (!rst && salida !== ref_salida) begin
            errores = errores + 1;
            $display("[%0t] ERROR contra el modelo: salida = %b, referencia = %b", $time, salida, ref_salida);
        end

    //----------- Herramientas -----------
    integer seed = 11;
    function integer rnd(input integer lo, input integer hi);
        begin rnd = lo + ({$random(seed)} % (hi - lo + 1)); end
    endfunction

    //Espera a que el DUT procese una muestra (el tick llega, y en el flanco siguiente se muestrea)
    task tras_muestra;
        begin @(posedge en); @(posedge HFOSC); #1; end
    endtask

    //Pone la tecla b en "valor" y deja pasar n muestras
    task muestras(input integer b, input valor, input integer n);
        integer j;
        begin
            entrada[b] = valor;
            for (j = 0; j < n; j = j + 1) tras_muestra;
        end
    endtask

    task esperado(input integer b, input valor, input [255:0] txt);
        begin
            if (salida[b] !== valor) begin errores = errores + 1; $display("[%0t] ERROR %0s: salida[%0d] = %b, esperado %b", $time, txt, b, salida[b], valor); end
            else $display("[%0t] ok    %0s: salida[%0d] = %b", $time, txt, b, salida[b]);
        end
    endtask

    //Rebota la tecla b: la invierte "cambios" veces cada 2 a 14 ciclos y la deja en valor_final
    task rebotar(input integer b, input valor_final, input integer cambios);
        integer j;
        begin
            for (j = 0; j < cambios; j = j + 1) begin
                entrada[b] = ~entrada[b];
                repeat (rnd(2, 14)) @(posedge HFOSC);
            end
            entrada[b] = valor_final;
        end
    endtask

    integer r;

    initial begin
        $dumpfile("antirebote_tb.vcd");
        $dumpvars(0, antirebote_tb);
        repeat (5) @(posedge HFOSC);
        rst = 1'b0;
        tras_muestra;

        $display("== 1) Un pulso de 1 muestra (glitch): se rechaza ==");
        muestras(3, 1'b1, 1); muestras(3, 1'b0, 3);
        esperado(3, 1'b0, "glitch de 1 muestra");

        $display("== 2) Un pulso de 2 muestras (menos que N_MUESTRAS = 3): se rechaza ==");
        muestras(3, 1'b1, 2); muestras(3, 1'b0, 3);
        esperado(3, 1'b0, "pulso de 2 muestras");

        $display("== 3) Tres muestras seguidas: se acepta recien en la tercera ==");
        muestras(3, 1'b1, 2);
        esperado(3, 1'b0, "despues de 2 muestras todavia no");
        tras_muestra;
        esperado(3, 1'b1, "en la 3ra muestra se acepta");

        $display("== 4) Ya apretada: un hueco de 2 muestras no la suelta ==");
        muestras(3, 1'b0, 2); muestras(3, 1'b1, 3);
        esperado(3, 1'b1, "sigue apretada");

        $display("== 5) Soltar: 3 muestras en 0 la sueltan ==");
        muestras(3, 1'b0, 3);
        esperado(3, 1'b0, "soltada");

        $display("== 6) Dos teclas independientes (bits 0 y 9) ==");
        entrada[0] = 1'b1; entrada[9] = 1'b1; tras_muestra;
        entrada[9] = 1'b0; tras_muestra;                      // la 9 era un rebote
        entrada[9] = 1'b1; tras_muestra; tras_muestra;
        esperado(0, 1'b1, "tecla 0 aceptada");
        esperado(9, 1'b0, "tecla 9 rechazada (rebote)");
        muestras(9, 1'b1, 3);
        esperado(9, 1'b1, "tecla 9 aceptada despues de 3 estables");
        entrada[0] = 1'b0; entrada[9] = 1'b0;
        tras_muestra; tras_muestra; tras_muestra;
        esperado(0, 1'b0, "tecla 0 soltada");
        esperado(9, 1'b0, "tecla 9 soltada");

        $display("== 7) Rebotes al azar al apretar y al soltar, 8 veces. El modelo de referencia vigila cada ciclo ==");
        for (r = 0; r < 8; r = r + 1) begin
            rebotar(5, 1'b1, 3 + r);                // varios rebotes y queda apretada
            muestras(5, 1'b1, N_MUESTRAS + 2);      // estable: tiene que aceptarla
            esperado(5, 1'b1, "tras los rebotes quedo apretada");
            rebotar(5, 1'b0, 3 + r);                // rebotes al soltar
            muestras(5, 1'b0, N_MUESTRAS + 2);
            esperado(5, 1'b0, "tras los rebotes quedo soltada");
        end

        $display("== 8) Rebotes en varias teclas a la vez ==");
        for (r = 0; r < 4; r = r + 1) begin
            rebotar(1, 1'b1, 4); rebotar(12, 1'b1, 5); rebotar(15, 1'b1, 3);
            muestras(1, 1'b1, N_MUESTRAS + 2);
            if (salida[1] !== 1'b1 || salida[12] !== 1'b1 || salida[15] !== 1'b1) begin errores = errores + 1; $display("ERROR teclas 1, 12, 15 no quedaron apretadas: %b", salida); end
            entrada[1] = 1'b0; entrada[12] = 1'b0; entrada[15] = 1'b0;
            muestras(1, 1'b0, N_MUESTRAS + 2);
            if (salida !== 16'h0000) begin errores = errores + 1; $display("ERROR no quedaron soltadas: %b", salida); end
        end
        $display("   (barrido de rebotes en varias teclas terminado)");

        if (errores == 0) $display("\nANTIREBOTE: TODO OK");
        else              $display("\nANTIREBOTE: %0d ERRORES", errores);
        $finish;
    end
endmodule
