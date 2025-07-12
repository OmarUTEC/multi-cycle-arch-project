//  operand_selector.v
//  Encapsula TODA la lógica que decide qué registros leer/escribir
//  (RA1, RA2, WA3, WA4) y, opcionalmente, expone flags de MUL.
//---------------------------------------------------------------------
module operand_selector (
    input  wire [31:0] Instr,
    input  wire [1:0]  RegSrc,
    input  wire        IsMovt,
    input  wire        IsMovm,

    output wire [3:0]  RA1,           // Dirección puerto A
    output wire [3:0]  RA2,           // Dirección puerto B
    output wire [3:0]  WA3,           // RdLo / Destino principal
    output wire [3:0]  WA4,           // RdHi

    //--- Estos flags solo son útiles si el resto del sistema
    //--- quiere saber si es una MUL / UMULL / SMULL.
    output wire        isMul,
    output wire        mul_long
);
    //-----------------------------------------------------------------
    //  Decodificación mínima de la instrucción de multiplicación
    //-----------------------------------------------------------------
    assign mul_long = (Instr[27:23] == 5'b00001) && (Instr[7:4] == 4'b1001); // UMULL/SMULL
    assign isMul    = (Instr[27:21] == 7'b0000000) && (Instr[7:4] == 4'b1001) && !mul_long; // MUL de 32 bits

    //-----------------------------------------------------------------
    //  Direcciones de lectura (RA1, RA2)
    //-----------------------------------------------------------------
    assign RA1 = mul_long                 ? Instr[11:8]   :   // Rm en UMULL/SMULL
                 (IsMovt || IsMovm)       ? Instr[15:12]  :
                 (isMul)                  ? Instr[11:8]   :   // Rs en MUL
                 (RegSrc[0])              ? 4'hF          :   // PC
                                            Instr[19:16];     // Rd / Rn normal

    assign RA2 = mul_long                 ? Instr[3:0]    :   // Rn en UMULL/SMULL
                 (isMul)                  ? Instr[3:0]    :   // Rm en MUL
                 (RegSrc[1])              ? Instr[15:12]  :   // Rs
                                            Instr[3:0];       // Rm normal

    //-----------------------------------------------------------------
    //  Direcciones de escritura (WA3, WA4)
    //-----------------------------------------------------------------
    // * CORREGIDO: La dirección de destino para MUL está en [19:16] *
    assign WA3 = isMul ? Instr[19:16] : Instr[15:12];
    assign WA4 = Instr[19:16];   // RdHi
endmodule