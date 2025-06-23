// condcheck.v
// Lógica de chequeo de condición según códigos ARM
module condcheck (
    Cond,
    Flags,
    CondEx
);
    input  wire [3:0] Cond;    // Código de condición de instrucción
    input  wire [3:0] Flags;   // Flags actuales de ALU: {N,Z,C,V}
    output wire       CondEx;  // 1 si condición se cumple

    // Extraer flags individuales
    wire N = Flags[3];
    wire Z = Flags[2];
    wire C = Flags[1];
    wire V = Flags[0];

    // Evaluar condición según especificación ARM
    assign CondEx = (Cond == 4'b0000) ? Z :            // EQ: Z == 1
                   (Cond == 4'b0001) ? ~Z :           // NE: Z == 0
                   (Cond == 4'b0010) ? C :            // CS/HS: C == 1
                   (Cond == 4'b0011) ? ~C :           // CC/LO: C == 0
                   (Cond == 4'b0100) ? N :            // MI: N == 1
                   (Cond == 4'b0101) ? ~N :           // PL: N == 0
                   (Cond == 4'b0110) ? V :            // VS: V == 1
                   (Cond == 4'b0111) ? ~V :           // VC: V == 0
                   (Cond == 4'b1000) ? (C && ~Z) :    // HI: C==1 && Z==0
                   (Cond == 4'b1001) ? (~C || Z) :    // LS: C==0 || Z==1
                   (Cond == 4'b1010) ? (N == V) :     // GE: N==V
                   (Cond == 4'b1011) ? (N != V) :     // LT: N!=V
                   (Cond == 4'b1100) ? (~Z && (N == V)) : // GT: Z==0 && N==V
                   (Cond == 4'b1101) ? (Z || (N != V)) :   // LE: Z==1 || N!=V
                   (Cond == 4'b1110) ? 1'b1 :         // AL: always
                   1'b0;                              // NV/undefined
endmodule
