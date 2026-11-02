module comparador #(
  // Lo que define el usuario al instanciar
  parameter F_IN     = 48_000_000,  // Hz, frecuencia de HFOSC
  parameter F_OUT    = 12_000_000,  // Hz, frecuencia de la salida
  parameter CUADRADA = 0,           // 0 = tick, 1 = onda cuadrada

  // Derivados (no se tocan al instanciar)
  parameter M     = CUADRADA ? F_IN / (2 * F_OUT) : F_IN / F_OUT,
  parameter WIDTH = (M > 1) ? $clog2(M) : 1
)(
  input  wire [WIDTH-1:0] count,   // viene del contador
  output wire             fin      // 1 cuando count == M-1
);
  assign fin = (count == M - 1);
endmodule