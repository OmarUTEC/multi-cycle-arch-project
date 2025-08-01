// ARCHIVO: controller.v
module controller (
    clk,
    reset,
    Instr,
    ALUFlags,
    PCWrite,
    MemWrite,
    RegWrite,
    IRWrite,
    AdrSrc,
    RegSrc,
    ALUSrcA,
    ALUSrcB,
    ResultSrc,
    ImmSrc,
    ALUControl,
    RegWriteHi,
    IsMovt,
    IsMovm      // <-- 1. AÑADIR A LA LISTA DE PUERTOS
);
    input wire clk;
    input wire reset;
    input wire [31:0] Instr;
    input wire [3:0] ALUFlags;
    output wire PCWrite;
    output wire MemWrite;
    output wire RegWrite;
    output wire IRWrite;
    output wire AdrSrc;
    output wire [1:0] RegSrc;
    output wire ALUSrcA;
    output wire [1:0] ALUSrcB;
    output wire [1:0] ResultSrc;
    output wire [1:0] ImmSrc;
    output wire [3:0] ALUControl;
    output wire RegWriteHi;
    output wire IsMovt;
    output wire IsMovm;      // <-- 2. DECLARAR COMO SALIDA

    wire [1:0] FlagW;
    wire PCS;
    wire NextPC;
    wire RegW;
    wire MemW;
    wire RegWHi;

    /* ––– DECODE ––– */
    decode dec (
        .clk        (clk),
        .reset      (reset),
        .Instr      (Instr),
        // salidas:
        .FlagW      (FlagW),
        .PCS        (PCS),
        .NextPC     (NextPC),
        .RegW       (RegW),
        .MemW       (MemW),
        .IRWrite    (IRWrite),
        .AdrSrc     (AdrSrc),
        .ResultSrc  (ResultSrc),
        .ALUSrcA    (ALUSrcA),
        .ALUSrcB    (ALUSrcB),
        .ImmSrc     (ImmSrc),
        .RegSrc     (RegSrc),
        .ALUControl (ALUControl),
        .RegWHi     (RegWHi),
        .IsMovt     (IsMovt),
        .IsMovm     (IsMovm)    // <-- 3. CONECTAR LA SEÑAL DESDE 'decode'
    );

    condlogic cl(
        .clk(clk),
        .reset(reset),
        .Cond(Instr[31:28]),
        .ALUFlags(ALUFlags),
        .FlagW(FlagW),
        .PCS(PCS),
        .NextPC(NextPC),
        .RegW(RegW),
        .MemW(MemW),
        .PCWrite(PCWrite),
        .RegWrite(RegWrite),
        .MemWrite(MemWrite),
        .RegWHi(RegWHi),
        .RegWriteHi(RegWriteHi)
    );
endmodule