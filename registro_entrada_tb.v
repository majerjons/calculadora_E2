//Testbench 3: registro de entrada (solo el modulo registro_entrada, con las senales que despues va a generar la FSM).
//Se sigue el ejemplo: 5-2-8-3 -> 0005, 0052, 0528, 5283.
//Tambien: quinto digito, clear, clear + digito en el mismo ciclo, op2_en, y que sin enable no cambie nada.
//
//Codigo para testear:  iverilog -g2012 -o registro.vvp registro_entrada_tb.v registros_entrada.v
//         vvp registro.vvp      y despues      gtkwave registro_entrada_tb.vcd

`timescale 1ns/1ps

module registro_entrada_tb;

    reg HFOSC = 1'b0;
    always #5 HFOSC = ~HFOSC;

    reg        rst = 1'b1, clear = 1'b0, op1_en = 1'b0, op2_en = 1'b0;
    reg  [3:0] digito = 4'd0;
    wire [15:0] bcd;
    wire [2:0]  cantidad;

    registro_entrada dut (.HFOSC(HFOSC), .rst(rst), .clear(clear), .op1_en(op1_en), .op2_en(op2_en),
                          .digito(digito), .bcd(bcd), .cantidad(cantidad));

    integer errores = 0;

    task chequear(input [15:0] bcd_esp, input [2:0] cant_esp, input [255:0] txt);
        begin
            if (bcd !== bcd_esp || cantidad !== cant_esp) begin
                errores = errores + 1;
                $display("[%0t] ERROR %0s: bcd = %h, cantidad = %0d  (esperado %h, %0d)", $time, txt, bcd, cantidad, bcd_esp, cant_esp);
            end
            else $display("[%0t] ok    %0s: bcd = %h, cantidad = %0d", $time, txt, bcd, cantidad);
        end
    endtask

    //Un pulso de 1 ciclo de op1_en (o op2_en) con el digito presente
    task tipear1(input [3:0] d);
        begin digito = d; op1_en = 1'b1; @(posedge HFOSC); #1; op1_en = 1'b0; end
    endtask
    task tipear2(input [3:0] d);
        begin digito = d; op2_en = 1'b1; @(posedge HFOSC); #1; op2_en = 1'b0; end
    endtask
    task borrar;
        begin clear = 1'b1; @(posedge HFOSC); #1; clear = 1'b0; end
    endtask

    initial begin
        $dumpfile("registro_entrada_tb.vcd");
        $dumpvars(0, registro_entrada_tb);
        repeat (3) @(posedge HFOSC);
        #1 rst = 1'b0;
        chequear(16'h0000, 3'd0, "despues del reset");

        $display("\n== Ejemplo del top: 5, 2, 8, 3 ==");
        tipear1(4'd5); chequear(16'h0005, 3'd1, "entra 5");
        tipear1(4'd2); chequear(16'h0052, 3'd2, "entra 2");
        tipear1(4'd8); chequear(16'h0528, 3'd3, "entra 8");
        tipear1(4'd3); chequear(16'h5283, 3'd4, "entra 3");

        $display("\n== Quinto digito: se ignora ==");
        tipear1(4'd9); chequear(16'h5283, 3'd4, "quinto digito ignorado");
        tipear1(4'd1); chequear(16'h5283, 3'd4, "sexto digito ignorado");

        $display("\n== Sin enable no cambia nada, aunque cambie digito ==");
        digito = 4'd7; repeat (4) @(posedge HFOSC); #1;
        chequear(16'h5283, 3'd4, "digito cambia sin enable");

        $display("\n== Clear solo ==");
        borrar; chequear(16'h0000, 3'd0, "clear");

        $display("\n== Clear y op1_en en el mismo ciclo (empezar cuenta nueva): queda solo el digito ==");
        tipear1(4'd4); tipear1(4'd6);
        chequear(16'h0046, 3'd2, "antes: 46");
        clear = 1'b1; digito = 4'd8; op1_en = 1'b1; @(posedge HFOSC); #1; clear = 1'b0; op1_en = 1'b0;
        chequear(16'h0008, 3'd1, "clear + 8 a la vez");

        $display("\n== op2_en tambien desplaza ==");
        tipear2(4'd3); chequear(16'h0083, 3'd2, "op2_en entra 3");

        $display("\n== Un 0 cuenta como digito ==");
        borrar; tipear1(4'd0); chequear(16'h0000, 3'd1, "entra 0");
        tipear1(4'd6);          chequear(16'h0006, 3'd2, "entra 6");

        $display("\n== op1_en y op2_en juntos: es un solo desplazamiento ==");
        borrar; digito = 4'd2; op1_en = 1'b1; op2_en = 1'b1; @(posedge HFOSC); #1; op1_en = 1'b0; op2_en = 1'b0;
        chequear(16'h0002, 3'd1, "enables juntos");

        $display("\n== Reset en el medio ==");
        tipear1(4'd9); rst = 1'b1; @(posedge HFOSC); #1; rst = 1'b0;
        chequear(16'h0000, 3'd0, "reset borra todo");

        if (errores == 0) $display("\nREGISTRO DE ENTRADA: TODO OK");
        else              $display("\nREGISTRO DE ENTRADA: %0d ERRORES", errores);
        $finish;
    end
endmodule
