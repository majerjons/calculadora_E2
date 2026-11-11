//Autor: Solar Grillo, Lucas (LSG).

/*
Shift register de dígitos BCD. Los dígitos ingresan por la parte menos significativa (derecha) 
y desplazan los bits previos hacia la izquierda.

bcd[3:0]   = Dígito de las unidades (el último tipeado).
bcd[15:12] = Dígito de los miles. (hay 4 digitos en el display, el primer digito, el de los miles esta aca ubicado)
cantidad   = Contador de dígitos ingresados (0 a 4). El multiplexor del 
display la utiliza para apagar los dígitos no utilizados.
*/

module registro_entrada (
    input  wire        HFOSC,
    input  wire        rst,
    input  wire        clear,
    input  wire        op1_en,
    input  wire        op2_en,
    input  wire [3:0]  digito,
    output reg  [15:0] bcd,
    output reg  [2:0]  cantidad // cantidad de dígitos que llegaron
);

    wire shift_en = op1_en | op2_en; // si entro un dígito shiftea

    always @(posedge HFOSC) begin
        if (rst) begin
            bcd      <= 16'h0000;
            cantidad <= 3'd0;
        end
        else if (clear) begin
            if (shift_en) begin                 // si se ingresa borrar y desplazar en el mismo flanco
                bcd      <= {12'h000, digito}; // se borra y dsp se ingresa
                cantidad <= 3'd1;
            end
            else begin
                bcd      <= 16'h0000;
                cantidad <= 3'd0;
            end
        end
        // Desplazamiento normal: el nuevo dígito entra por la derecha y los anteriores se desplazan a la izquierda. 
        // Ejemplo: si entra '5' y luego '1', se obtiene 0x0051.
        // Se limita a un máximo de 4 dígitos (se ignora el 5to para proteger el primero).
        else if (shift_en && cantidad != 3'd4) begin
            bcd      <= {bcd[11:0], digito};
            cantidad <= cantidad + 1'b1;
        end
    end

endmodule