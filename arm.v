// ————————————————
// Top-level arm.v
// ————————————————
module arm (
  input  wire        clk,
  input  wire        reset,
  input  wire [31:0] ReadData,
  output wire        MemWrite,
  output wire [31:0] Adr,
  output wire [31:0] WriteData,
  output wire [31:0] PC,
  output wire [31:0] Instr
);

  //––– cables internos –––
  wire [3:0]  ALUFlags;
  wire        PCWrite, RegWrite, IRWrite, AdrSrc;
  wire [1:0]  RegSrc, ALUSrcB, ImmSrc, ResultSrc;
  wire ALUSrcA;
  wire [2:0]  ALUControl;

  controller c (
    .clk        (clk),
    .reset      (reset),
    .Instr      (Instr[31:0]),
    .ALUFlags   (ALUFlags),
    .PCWrite    (PCWrite),
    .MemWrite   (MemWrite),
    .RegWrite   (RegWrite),
    .IRWrite    (IRWrite),
    .AdrSrc     (AdrSrc),
    .RegSrc     (RegSrc),
    .ALUSrcA    (ALUSrcA),
    .ALUSrcB    (ALUSrcB),
    .ResultSrc  (ResultSrc),
    .ImmSrc     (ImmSrc),
    .ALUControl (ALUControl)
  );

  datapath dp (
    .clk        (clk),
    .reset      (reset),
    .MemWrite   (MemWrite),     // ← conecta aquí
    .Adr        (Adr),
    .WriteData  (WriteData),
    .ReadData   (ReadData),
    .Instr      (Instr),
    .PC         (PC),
    .ALUFlags   (ALUFlags),
    .PCWrite    (PCWrite),
    .RegWrite   (RegWrite),
    .IRWrite    (IRWrite),
    .AdrSrc     (AdrSrc),
    .RegSrc     (RegSrc),
    .ALUSrcA    (ALUSrcA),
    .ALUSrcB    (ALUSrcB),
    .ResultSrc  (ResultSrc),
    .ImmSrc     (ImmSrc),
    .ALUControl (ALUControl)
  );

endmodule
