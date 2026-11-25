
/********************************************************************
*********************************************************************

                      MODULOS GLOBALES

*********************************************************************
*********************************************************************/



/********************************************************************
            Mux_formato
*********************************************************************/
module mux_formato (
        input clk,
        input  [15:0] op1,
        input [15:0]op2,
        input [15:0]res,
        input [1:0] estado,
        input [1:0]cantidad,
        output wire [15:0] display_word
);

reg [15:0]disp;


// FLIPEO DE BITS INTERNOS PARA CUMPLIR CON EL FORMATO
formateador flip1 (.clk(clk), .a(disp), .num_format(display_word), .cantidad(cantidad));

always @(*) begin //apagar displays no usados
        case(estado)//MUX
                2'b00: disp = op1;
                2'b01: disp = op2;
                2'b10: disp = res;
                default: disp = 16'hFFFF;
        endcase
end

endmodule

/*
cantidad                digitos que se ven              resultado
2'b00                   1                               F F F d0
2'b01                   2                               F F d1 d0
2'b10                   3                               F d2 d1 d0
2'b11                   4                               d3 d2 d1 d0
*/



/********************************************************************
                      Transmisor serie
*********************************************************************/

//OBSERVACIONES  DE USO

//INPUT_EN = 0, el dispositivo no hace nada
//INPUT_EN = 1, el dispositivo transmite lo que le pasa disp_word

module transmisor_serie (
        input clk,
        input reset,
        input [15:0] disp_word,
        input input_en,
        output reg salida_serie,
        output reg output_en,
        output clk_disp
);

reg [4:0] count=4'b0000;
reg run =0 ;
reg [15:0] disp_word_mem;
reg flag =0;
wire tick_disp;
clock_transmisor cl (.reset(reset), .clk(clk), .clk_disp(clk_disp));
detec_flanco negedge1 (.clk(clk), .clk_disp(clk_disp), .n_egedge(tick_disp));

always@(negedge clk)begin

    if (input_en)begin
    end

    if (reset ==1)begin 
        output_en <= 1'b0;
        salida_serie <= 1'b0;
        count <= 0;
        run<=0;
        flag <=0;
    end
    else if (input_en && !run && !flag) begin // aca me esta 
        flag =1;
        disp_word_mem <= disp_word;
    end
    else if((flag||run) & tick_disp)begin
        case (count)
        0: begin salida_serie <= disp_word_mem[15];
                count <= count + 1; 
                run <=1;
                output_en <= 1'b1;
                flag <= 0;
                end
        1: begin salida_serie <= disp_word_mem[14];
                count <= count + 1; end
        2: begin salida_serie <= disp_word_mem[13];
                count <= count + 1; end
        3: begin salida_serie <= disp_word_mem[12];
                count <= count + 1; end
        4: begin salida_serie <= disp_word_mem[11];
                count <= count + 1; end
        5: begin salida_serie <= disp_word_mem[10];
                count <= count + 1; end
        6: begin salida_serie <= disp_word_mem[9];
                count <= count + 1; end
        7: begin salida_serie <= disp_word_mem[8];
                count <= count + 1; end
        8: begin salida_serie <= disp_word_mem[7];
                count <= count + 1; end
        9: begin salida_serie <= disp_word_mem[6];
                count <= count + 1; end
        10: begin salida_serie <= disp_word_mem[5];
                count <= count + 1; end
        11: begin salida_serie <= disp_word_mem[4];
                count <= count + 1; end
        12: begin salida_serie <= disp_word_mem[3];
                count <= count + 1; end
        13: begin salida_serie <= disp_word_mem[2];
                count <= count + 1; end
        14: begin salida_serie <= disp_word_mem[1];
                count <= count + 1; end
        15: begin salida_serie <= disp_word_mem[0];
                count <= count + 1; end
        16: begin count <=0; output_en <= 0; run<=0;
        end
        default: begin count <= 0;  
        run<=0;
        output_en <= 0;
        salida_serie <= 1'b0;
        end
        endcase
    end

end

endmodule


/********************************************************************
*********************************************************************

                      MODULOS LOCALES

*********************************************************************
*********************************************************************/



/********************************************************************
                      Formateo
*********************************************************************/


module formateador ( 
        input clk, 
        input wire [15:0]a,
        input wire [1:0] cantidad,
        output reg [15:0]num_format
);

wire [15:0] num_format_out;

// 15 14 13 12 11 10 9 8 7 6 5 4 3 2 1 0
// tengo que flippear y debe quedar
// 12 13 14 15 8 9 10 11 4 5 6 7 0 1 2 3

assign num_format_out = {a[12],a[13],a[14],a[15],
                         a[8], a[9], a[10], a[11],
                         a[4], a[5], a[6], a[7],
                         a[0], a[1], a[2], a[3]};

always@(negedge clk) begin  // Llena con ceros los números no usados
        if (cantidad == 2'b11)   num_format <= num_format_out;

                else if  (cantidad == 2'b00) num_format <= { 4'hF, 4'hF, 4'hF, num_format_out[3:0]};
                else if (cantidad == 2'b01)  num_format <= { 4'hF, 4'hF, num_format_out[7:0]};
                else if (cantidad == 2'b10)  num_format <= { 4'hF, num_format_out[11:0]};
                else num_format <= 16'hFFFF;
end



endmodule

////



/********************************************************************
                      Clock_transmisor
*********************************************************************/


// Crea un clock a partir de un clock de 48Mhz
module clock_transmisor (input reset, input clk, output clk_disp);

reg [14:0]cont =0;
reg clkint =0;
assign clk_disp = clkint;

always @(negedge clk) begin

        if(reset==1)begin
        cont <= 0;
        clkint <=0;
        end
        else if (cont == 2399)begin  
        // 2399 --> 10k
        // 23999 --> 1k
        cont <= 0;
        clkint <=~ clkint;
        end
        else begin
        cont <= cont + 1;
        end
end


endmodule


/********************************************************************
                      Detector de flancos
*********************************************************************/

module detec_flanco (input clk, input clk_disp, output n_egedge);

reg var_1 =0;
reg var_2 =0;

reg result =0;
assign n_egedge = result;

always @(negedge clk)begin

var_1 <= clk_disp;
var_2 <= var_1;

result <= (var_1 ^ var_2) & (var_2 == 1);

end


endmodule


