
/********************************************************************
*********************************************************************

                      MODULOS GLOBALES

*********************************************************************
*********************************************************************/



/********************************************************************
*********************************************************************
            Mux_formato
*********************************************************************
*********************************************************************/
// VARIABLES



module mux_formato (input clk, input  [15:0]op1, input [15:0]op2, input [15:0]res, input [1:0] estado, input [1:0]cantidad, output wire [15:0]display_word);


reg [15:0]disp;


/**

    FLIPEO DE BITS INTERNOS PARA CUMPLIR CON EL FORMATO
    
**/

    formateador flip1 (.clk(clk), .a(disp), .num_format(display_word), .cantidad(cantidad));


/**

    APAGADO DE LOS BITS NO USADOS
    
**/


always @(*) begin //apagar displays no usados


//// MUX
        case(estado) //consultar si estaría bien usar la bloqueante? quiero que esto se actualice en un flanco

        2'b00: disp = op1;
        2'b01: disp = op2;
        2'b10: disp = res;
        default: disp = 16'hFFFF;
    endcase

/////


end


endmodule

/********************************************************************
*********************************************************************
                      Transmisor serie
*********************************************************************
*********************************************************************/

//OBSERVACIONES  DE USO

//INPUT_EN = 0, el dispositivo no hace nada
//INPUT_EN = 1, el dispositivo transmite lo que le pasa disp_word

module transmisor_serie (input tick_disp, input [15:0] disp_word, input input_en, output reg salida_serie, output reg output_en);

reg [4:0] count=4'b0000;

always@(negedge tick_disp)begin

    if(input_en)begin
        output_en <= 1'b1;
        case (count)
        4'b0000: begin salida_serie <= disp_word[15];
                count <= count + 1; end
        4'b0001: begin salida_serie <= disp_word[14];
                count <= count + 1; end
        4'b0010: begin salida_serie <= disp_word[13];
                count <= count + 1; end
        4'b0011: begin salida_serie <= disp_word[12];
                count <= count + 1; end
        4'b0100: begin salida_serie <= disp_word[11];
                count <= count + 1; end
        4'b0101: begin salida_serie <= disp_word[10];
                count <= count + 1; end
        4'b0110: begin salida_serie <= disp_word[9];
                count <= count + 1; end
        4'b0111: begin salida_serie <= disp_word[8];
                count <= count + 1; end
        4'b1000: begin salida_serie <= disp_word[7];
                count <= count + 1; end
        4'b1001: begin salida_serie <= disp_word[6];
                count <= count + 1; end
        4'b1010: begin salida_serie <= disp_word[5];
                count <= count + 1; end
        4'b1011: begin salida_serie <= disp_word[4];
                count <= count + 1; end
        4'b1100: begin salida_serie <= disp_word[3];
                count <= count + 1; end
        4'b1101: begin salida_serie <= disp_word[2];
                count <= count + 1; end
        4'b1110: begin salida_serie <= disp_word[1];
                count <= count + 1; end
        4'b1111: begin salida_serie <= disp_word[0];
                count <= count + 1; end
        default: count <= 0;
        endcase
    end
    else begin
        output_en <= 1'b0;
        salida_serie <= 1'b0;
        count <= 0;
    end

end


endmodule


/********************************************************************
*********************************************************************

                      MODULOS LOCALES

*********************************************************************
*********************************************************************/



/********************************************************************
*********************************************************************
                      FORMATEO
*********************************************************************
*********************************************************************/


module formateador (input clk, input wire [15:0]a, input wire [1:0] cantidad, output reg [15:0]num_format);

wire [15:0] num_format_out;

// 15 14 13 12 11 10 9 8 7 6 5 4 3 2 1 0
// tengo que flippear y debe quedar
// 12 13 14 15 8 9 10 11 4 5 6 7 0 1 2 3

assign num_format_out = {a[12],a[13],a[14],a[15],
                         a[8], a[9], a[10], a[11],
                         a[4], a[5], a[6], a[7],
                         a[0], a[1], a[2], a[3]};

always@(negedge clk)begin


// Llena con ceros los números no usados


 if (cantidad == 2'b11)

    num_format <= num_format_out;

    else if  (cantidad == 2'b00)begin
    num_format <= { 4'hF, 4'hF, 4'hF, num_format_out[3:0]};
    end
    else if (cantidad == 2'b01)begin

    num_format <= { 4'hF, 4'hF, num_format_out[7:0]};
    end 

    else if (cantidad == 2'b10)begin

    num_format <= { 4'hF, num_format_out[11:0]};

    end
    else begin

    num_format <= 16'hFFFF;
    end

end



endmodule

////



