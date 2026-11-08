//Autor: Solar Grillo, Lucas (LSG).

/*
Antirrebote para un bus de ANCHO senales (por ejemplo las 16 teclas). Cada tecla tiene su propio contador
y su propio estado estable, y las 16 se filtran en el mismo always con un for.

Al final de todo hay un ejemplo sin bucle for, es un pijazo

Para cada tecla i, en cada tick de muestreo (en = 1):
  - Si entrada[i] es igual al estado estable salida[i]: no hay cambio, el contador de esa tecla vuelve a 0.
  - Si es distinta: cuenta. Cuando llega a N_MUESTRAS muestras seguidas distintas, salida[i] adopta
    el nuevo valor y el contador vuelve a 0.
  - Si en el medio la entrada vuelve a ser igual a salida[i] (un rebote), se reinicia la cuenta.

Tiempo minimo de estabilidad aprox = (N_MUESTRAS - 1) * periodo del tick (hasta N_MUESTRAS * periodo).
Ej: tick de 100Hz (10ms) y N_MUESTRAS = 3 -> la entrada tiene que estar estable entre 20ms y 30ms.
N_MUESTRAS = 1 deja pasar la entrada sin filtrar.
*/

module antirrebote #(
    parameter ANCHO      = 16,
    parameter N_MUESTRAS = 3
)(
    input  wire             HFOSC,
    input  wire             rst,
    input  wire             en,        // tick de muestreo (tick_anti_rebote)
    input  wire [ANCHO-1:0] entrada,   // senales con rebotes (la matriz)
    output reg  [ANCHO-1:0] salida     // senales estables
);

    localparam ANCHO_CNT = (N_MUESTRAS > 1) ? $clog2(N_MUESTRAS) : 1;

    //Un contador por tecla: cnt[0] es el de la tecla 0, cnt[1] el de la tecla 1, etc.
    reg [ANCHO_CNT-1:0] cnt [0:ANCHO-1];

    integer i;   // indice de la tecla; solo se usa dentro del for

    always @(posedge HFOSC) begin
        if (rst) begin
            salida <= {ANCHO{1'b0}};
            for (i = 0; i < ANCHO; i = i + 1) begin
                cnt[i] <= {ANCHO_CNT{1'b0}};
            end
        end
        else if (en) begin
            //El for repite el mismo bloque para cada tecla: primero i = 0, despues i = 1, ... hasta i = ANCHO-1.
            for (i = 0; i < ANCHO; i = i + 1) begin
                if (entrada[i] == salida[i]) begin              // sin cambios (o volvio a su valor): reinicio la cuenta
                    cnt[i] <= {ANCHO_CNT{1'b0}};
                end
                else if (cnt[i] == N_MUESTRAS - 1) begin       // estuvo distinta N_MUESTRAS veces seguidas: la acepto
                    salida[i] <= entrada[i];
                    cnt[i]    <= {ANCHO_CNT{1'b0}};
                end
                else begin                                      // sigue distinta: sigo contando
                    cnt[i] <= cnt[i] + 1'b1;
                end
            end
        end
    end

endmodule

// //Autor: Solar Grillo, Lucas (LSG).
//
// /*
// Antirrebote de 16 teclas usando el modulo contador ya hecho, con todo repetido a mano por cada tecla.
// Para cada tecla k (0 a 15), en cada tick de muestreo (en = 1):
//   - Si entrada[k] es igual al estado estable salida[k]: el contador de esa tecla se limpia.
//   - Si es distinta: el contador cuenta. Cuando ya conto N_MUESTRAS-1 muestras y llega otra distinta
//     (N_MUESTRAS seguidas), salida[k] adopta el nuevo valor y el contador se limpia.
//   - Si en el medio la entrada vuelve a ser igual a salida[k] (un rebote), el contador se limpia.
// Como el contador se usa para contar muestras (no para dividir una frecuencia), se instancia con
// F_IN = N_MUESTRAS y F_OUT = 1: asi M = F_IN / F_OUT = N_MUESTRAS y cuenta de 0 a N_MUESTRAS-1.
// Para cada tecla k hay 4 senales: cntk (la cuenta), distintak, llenok y aceptark.
// */
//
// module antirrebote #(
//     parameter N_MUESTRAS = 3
// )(
//     input  wire        HFOSC,
//     input  wire        rst,
//     input  wire        en,        // tick de muestreo (tick_anti_rebote)
//     input  wire [15:0] entrada,   // senales con rebotes (la matriz)
//     output reg  [15:0] salida     // senales estables
// );
//
//     //Mismo ancho que calcula el contador por dentro (WIDTH), porque su M va a ser N_MUESTRAS
//     localparam ANCHO_CNT = (N_MUESTRAS > 1) ? $clog2(N_MUESTRAS) : 1;
//
//     //---------------- Tecla 0 ----------------
//     wire [ANCHO_CNT-1:0] cnt0;
//     wire distinta0 = (entrada[0] != salida[0]);          // la entrada difiere del estado estable
//     wire lleno0    = (cnt0 == N_MUESTRAS - 1);      // ya conto N_MUESTRAS-1 muestras distintas
//     wire aceptar0  = en & distinta0 & lleno0;         // es la N_MUESTRAS-esima muestra distinta seguida
//     contador #(.F_IN(N_MUESTRAS), .F_OUT(1), .CUADRADA(0)) u_contador0 (
//         .HFOSC (HFOSC),
//         .rst   (rst),
//         .clear (en & (~distinta0 | lleno0)),   // limpio si volvio a ser igual (rebote) o si ya la acepte
//         .en    (en & distinta0),                // solo cuenta cuando la muestra es distinta
//         .count (cnt0)
//     );
//
//     //---------------- Tecla 1 ----------------
//     wire [ANCHO_CNT-1:0] cnt1;
//     wire distinta1 = (entrada[1] != salida[1]);          // la entrada difiere del estado estable
//     wire lleno1    = (cnt1 == N_MUESTRAS - 1);      // ya conto N_MUESTRAS-1 muestras distintas
//     wire aceptar1  = en & distinta1 & lleno1;         // es la N_MUESTRAS-esima muestra distinta seguida
//     contador #(.F_IN(N_MUESTRAS), .F_OUT(1), .CUADRADA(0)) u_contador1 (
//         .HFOSC (HFOSC),
//         .rst   (rst),
//         .clear (en & (~distinta1 | lleno1)),   // limpio si volvio a ser igual (rebote) o si ya la acepte
//         .en    (en & distinta1),                // solo cuenta cuando la muestra es distinta
//         .count (cnt1)
//     );
//
//     //---------------- Tecla 2 ----------------
//     wire [ANCHO_CNT-1:0] cnt2;
//     wire distinta2 = (entrada[2] != salida[2]);          // la entrada difiere del estado estable
//     wire lleno2    = (cnt2 == N_MUESTRAS - 1);      // ya conto N_MUESTRAS-1 muestras distintas
//     wire aceptar2  = en & distinta2 & lleno2;         // es la N_MUESTRAS-esima muestra distinta seguida
//     contador #(.F_IN(N_MUESTRAS), .F_OUT(1), .CUADRADA(0)) u_contador2 (
//         .HFOSC (HFOSC),
//         .rst   (rst),
//         .clear (en & (~distinta2 | lleno2)),   // limpio si volvio a ser igual (rebote) o si ya la acepte
//         .en    (en & distinta2),                // solo cuenta cuando la muestra es distinta
//         .count (cnt2)
//     );
//
//     //---------------- Tecla 3 ----------------
//     wire [ANCHO_CNT-1:0] cnt3;
//     wire distinta3 = (entrada[3] != salida[3]);          // la entrada difiere del estado estable
//     wire lleno3    = (cnt3 == N_MUESTRAS - 1);      // ya conto N_MUESTRAS-1 muestras distintas
//     wire aceptar3  = en & distinta3 & lleno3;         // es la N_MUESTRAS-esima muestra distinta seguida
//     contador #(.F_IN(N_MUESTRAS), .F_OUT(1), .CUADRADA(0)) u_contador3 (
//         .HFOSC (HFOSC),
//         .rst   (rst),
//         .clear (en & (~distinta3 | lleno3)),   // limpio si volvio a ser igual (rebote) o si ya la acepte
//         .en    (en & distinta3),                // solo cuenta cuando la muestra es distinta
//         .count (cnt3)
//     );
//
//     //---------------- Tecla 4 ----------------
//     wire [ANCHO_CNT-1:0] cnt4;
//     wire distinta4 = (entrada[4] != salida[4]);          // la entrada difiere del estado estable
//     wire lleno4    = (cnt4 == N_MUESTRAS - 1);      // ya conto N_MUESTRAS-1 muestras distintas
//     wire aceptar4  = en & distinta4 & lleno4;         // es la N_MUESTRAS-esima muestra distinta seguida
//     contador #(.F_IN(N_MUESTRAS), .F_OUT(1), .CUADRADA(0)) u_contador4 (
//         .HFOSC (HFOSC),
//         .rst   (rst),
//         .clear (en & (~distinta4 | lleno4)),   // limpio si volvio a ser igual (rebote) o si ya la acepte
//         .en    (en & distinta4),                // solo cuenta cuando la muestra es distinta
//         .count (cnt4)
//     );
//
//     //---------------- Tecla 5 ----------------
//     wire [ANCHO_CNT-1:0] cnt5;
//     wire distinta5 = (entrada[5] != salida[5]);          // la entrada difiere del estado estable
//     wire lleno5    = (cnt5 == N_MUESTRAS - 1);      // ya conto N_MUESTRAS-1 muestras distintas
//     wire aceptar5  = en & distinta5 & lleno5;         // es la N_MUESTRAS-esima muestra distinta seguida
//     contador #(.F_IN(N_MUESTRAS), .F_OUT(1), .CUADRADA(0)) u_contador5 (
//         .HFOSC (HFOSC),
//         .rst   (rst),
//         .clear (en & (~distinta5 | lleno5)),   // limpio si volvio a ser igual (rebote) o si ya la acepte
//         .en    (en & distinta5),                // solo cuenta cuando la muestra es distinta
//         .count (cnt5)
//     );
//
//     //---------------- Tecla 6 ----------------
//     wire [ANCHO_CNT-1:0] cnt6;
//     wire distinta6 = (entrada[6] != salida[6]);          // la entrada difiere del estado estable
//     wire lleno6    = (cnt6 == N_MUESTRAS - 1);      // ya conto N_MUESTRAS-1 muestras distintas
//     wire aceptar6  = en & distinta6 & lleno6;         // es la N_MUESTRAS-esima muestra distinta seguida
//     contador #(.F_IN(N_MUESTRAS), .F_OUT(1), .CUADRADA(0)) u_contador6 (
//         .HFOSC (HFOSC),
//         .rst   (rst),
//         .clear (en & (~distinta6 | lleno6)),   // limpio si volvio a ser igual (rebote) o si ya la acepte
//         .en    (en & distinta6),                // solo cuenta cuando la muestra es distinta
//         .count (cnt6)
//     );
//
//     //---------------- Tecla 7 ----------------
//     wire [ANCHO_CNT-1:0] cnt7;
//     wire distinta7 = (entrada[7] != salida[7]);          // la entrada difiere del estado estable
//     wire lleno7    = (cnt7 == N_MUESTRAS - 1);      // ya conto N_MUESTRAS-1 muestras distintas
//     wire aceptar7  = en & distinta7 & lleno7;         // es la N_MUESTRAS-esima muestra distinta seguida
//     contador #(.F_IN(N_MUESTRAS), .F_OUT(1), .CUADRADA(0)) u_contador7 (
//         .HFOSC (HFOSC),
//         .rst   (rst),
//         .clear (en & (~distinta7 | lleno7)),   // limpio si volvio a ser igual (rebote) o si ya la acepte
//         .en    (en & distinta7),                // solo cuenta cuando la muestra es distinta
//         .count (cnt7)
//     );
//
//     //---------------- Tecla 8 ----------------
//     wire [ANCHO_CNT-1:0] cnt8;
//     wire distinta8 = (entrada[8] != salida[8]);          // la entrada difiere del estado estable
//     wire lleno8    = (cnt8 == N_MUESTRAS - 1);      // ya conto N_MUESTRAS-1 muestras distintas
//     wire aceptar8  = en & distinta8 & lleno8;         // es la N_MUESTRAS-esima muestra distinta seguida
//     contador #(.F_IN(N_MUESTRAS), .F_OUT(1), .CUADRADA(0)) u_contador8 (
//         .HFOSC (HFOSC),
//         .rst   (rst),
//         .clear (en & (~distinta8 | lleno8)),   // limpio si volvio a ser igual (rebote) o si ya la acepte
//         .en    (en & distinta8),                // solo cuenta cuando la muestra es distinta
//         .count (cnt8)
//     );
//
//     //---------------- Tecla 9 ----------------
//     wire [ANCHO_CNT-1:0] cnt9;
//     wire distinta9 = (entrada[9] != salida[9]);          // la entrada difiere del estado estable
//     wire lleno9    = (cnt9 == N_MUESTRAS - 1);      // ya conto N_MUESTRAS-1 muestras distintas
//     wire aceptar9  = en & distinta9 & lleno9;         // es la N_MUESTRAS-esima muestra distinta seguida
//     contador #(.F_IN(N_MUESTRAS), .F_OUT(1), .CUADRADA(0)) u_contador9 (
//         .HFOSC (HFOSC),
//         .rst   (rst),
//         .clear (en & (~distinta9 | lleno9)),   // limpio si volvio a ser igual (rebote) o si ya la acepte
//         .en    (en & distinta9),                // solo cuenta cuando la muestra es distinta
//         .count (cnt9)
//     );
//
//     //---------------- Tecla 10 ----------------
//     wire [ANCHO_CNT-1:0] cnt10;
//     wire distinta10 = (entrada[10] != salida[10]);          // la entrada difiere del estado estable
//     wire lleno10    = (cnt10 == N_MUESTRAS - 1);      // ya conto N_MUESTRAS-1 muestras distintas
//     wire aceptar10  = en & distinta10 & lleno10;         // es la N_MUESTRAS-esima muestra distinta seguida
//     contador #(.F_IN(N_MUESTRAS), .F_OUT(1), .CUADRADA(0)) u_contador10 (
//         .HFOSC (HFOSC),
//         .rst   (rst),
//         .clear (en & (~distinta10 | lleno10)),   // limpio si volvio a ser igual (rebote) o si ya la acepte
//         .en    (en & distinta10),                // solo cuenta cuando la muestra es distinta
//         .count (cnt10)
//     );
//
//     //---------------- Tecla 11 ----------------
//     wire [ANCHO_CNT-1:0] cnt11;
//     wire distinta11 = (entrada[11] != salida[11]);          // la entrada difiere del estado estable
//     wire lleno11    = (cnt11 == N_MUESTRAS - 1);      // ya conto N_MUESTRAS-1 muestras distintas
//     wire aceptar11  = en & distinta11 & lleno11;         // es la N_MUESTRAS-esima muestra distinta seguida
//     contador #(.F_IN(N_MUESTRAS), .F_OUT(1), .CUADRADA(0)) u_contador11 (
//         .HFOSC (HFOSC),
//         .rst   (rst),
//         .clear (en & (~distinta11 | lleno11)),   // limpio si volvio a ser igual (rebote) o si ya la acepte
//         .en    (en & distinta11),                // solo cuenta cuando la muestra es distinta
//         .count (cnt11)
//     );
//
//     //---------------- Tecla 12 ----------------
//     wire [ANCHO_CNT-1:0] cnt12;
//     wire distinta12 = (entrada[12] != salida[12]);          // la entrada difiere del estado estable
//     wire lleno12    = (cnt12 == N_MUESTRAS - 1);      // ya conto N_MUESTRAS-1 muestras distintas
//     wire aceptar12  = en & distinta12 & lleno12;         // es la N_MUESTRAS-esima muestra distinta seguida
//     contador #(.F_IN(N_MUESTRAS), .F_OUT(1), .CUADRADA(0)) u_contador12 (
//         .HFOSC (HFOSC),
//         .rst   (rst),
//         .clear (en & (~distinta12 | lleno12)),   // limpio si volvio a ser igual (rebote) o si ya la acepte
//         .en    (en & distinta12),                // solo cuenta cuando la muestra es distinta
//         .count (cnt12)
//     );
//
//     //---------------- Tecla 13 ----------------
//     wire [ANCHO_CNT-1:0] cnt13;
//     wire distinta13 = (entrada[13] != salida[13]);          // la entrada difiere del estado estable
//     wire lleno13    = (cnt13 == N_MUESTRAS - 1);      // ya conto N_MUESTRAS-1 muestras distintas
//     wire aceptar13  = en & distinta13 & lleno13;         // es la N_MUESTRAS-esima muestra distinta seguida
//     contador #(.F_IN(N_MUESTRAS), .F_OUT(1), .CUADRADA(0)) u_contador13 (
//         .HFOSC (HFOSC),
//         .rst   (rst),
//         .clear (en & (~distinta13 | lleno13)),   // limpio si volvio a ser igual (rebote) o si ya la acepte
//         .en    (en & distinta13),                // solo cuenta cuando la muestra es distinta
//         .count (cnt13)
//     );
//
//     //---------------- Tecla 14 ----------------
//     wire [ANCHO_CNT-1:0] cnt14;
//     wire distinta14 = (entrada[14] != salida[14]);          // la entrada difiere del estado estable
//     wire lleno14    = (cnt14 == N_MUESTRAS - 1);      // ya conto N_MUESTRAS-1 muestras distintas
//     wire aceptar14  = en & distinta14 & lleno14;         // es la N_MUESTRAS-esima muestra distinta seguida
//     contador #(.F_IN(N_MUESTRAS), .F_OUT(1), .CUADRADA(0)) u_contador14 (
//         .HFOSC (HFOSC),
//         .rst   (rst),
//         .clear (en & (~distinta14 | lleno14)),   // limpio si volvio a ser igual (rebote) o si ya la acepte
//         .en    (en & distinta14),                // solo cuenta cuando la muestra es distinta
//         .count (cnt14)
//     );
//
//     //---------------- Tecla 15 ----------------
//     wire [ANCHO_CNT-1:0] cnt15;
//     wire distinta15 = (entrada[15] != salida[15]);          // la entrada difiere del estado estable
//     wire lleno15    = (cnt15 == N_MUESTRAS - 1);      // ya conto N_MUESTRAS-1 muestras distintas
//     wire aceptar15  = en & distinta15 & lleno15;         // es la N_MUESTRAS-esima muestra distinta seguida
//     contador #(.F_IN(N_MUESTRAS), .F_OUT(1), .CUADRADA(0)) u_contador15 (
//         .HFOSC (HFOSC),
//         .rst   (rst),
//         .clear (en & (~distinta15 | lleno15)),   // limpio si volvio a ser igual (rebote) o si ya la acepte
//         .en    (en & distinta15),                // solo cuenta cuando la muestra es distinta
//         .count (cnt15)
//     );
//
//     //El estado estable de cada tecla solo cambia cuando se acepta su entrada
//     always @(posedge HFOSC) begin
//         if (rst) begin
//             salida <= 16'b0;
//         end
//         else begin
//             if (aceptar0 ) salida[0] <= entrada[0];
//             if (aceptar1 ) salida[1] <= entrada[1];
//             if (aceptar2 ) salida[2] <= entrada[2];
//             if (aceptar3 ) salida[3] <= entrada[3];
//             if (aceptar4 ) salida[4] <= entrada[4];
//             if (aceptar5 ) salida[5] <= entrada[5];
//             if (aceptar6 ) salida[6] <= entrada[6];
//             if (aceptar7 ) salida[7] <= entrada[7];
//             if (aceptar8 ) salida[8] <= entrada[8];
//             if (aceptar9 ) salida[9] <= entrada[9];
//             if (aceptar10) salida[10] <= entrada[10];
//             if (aceptar11) salida[11] <= entrada[11];
//             if (aceptar12) salida[12] <= entrada[12];
//             if (aceptar13) salida[13] <= entrada[13];
//             if (aceptar14) salida[14] <= entrada[14];
//             if (aceptar15) salida[15] <= entrada[15];
//         end
//     end
//
// endmodule