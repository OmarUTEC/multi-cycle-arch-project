//---------------------------------------------------------------------
//  Datapath – versión completa con soporte UMULL/SMULL 32×32→64 bits
//  Codificación: 19:16 = RdHi, 15:12 = RdLo, 11:8 = Rm, 3:0 = Rn
//---------------------------------------------------------------------
module datapath (
    input  wire        clk,
    input  wire        reset,
    // memoria
    input  wire        MemWrite,
    output wire [31:0] Adr,
    output wire [31:0] WriteData,
    input  wire [31:0] ReadData,
    // buses de control principal
    output wire [31:0] Instr,
    output wire [31:0] PC,
    output wire [3:0]  ALUFlags,
    input  wire        PCWrite,
    input  wire        RegWrite,
    input  wire        IRWrite,
    input  wire        AdrSrc,
    input  wire [1:0]  RegSrc,
    input  wire        ALUSrcA,
    input  wire [1:0]  ALUSrcB,
    input  wire [1:0]  ResultSrc,
    input  wire [1:0]  ImmSrc,
    input  wire [2:0]  ALUControl,
    input  wire        RegWriteHi         // escribir parte alta (Ra)
);

    //––– Señales internas
    wire [31:0] PCNext, ExtImm;
    wire [31:0] SrcA, SrcB, Result, Data;
    wire [31:0] RD1, RD2, A, ALUResult, ALUOut;
    wire [31:0] ALUResultHi, ALUOutHi;
    wire [3:0]  WA4;          // destino parte alta (RdHi)

    //-----------------------------------------------------------------
    //  Lógica de PC e IR
    //-----------------------------------------------------------------
    assign PCNext = Result;

    flopenr #(.WIDTH(32)) pcreg (
        .clk   (clk), .reset(reset), .en(PCWrite),
        .d(PCNext),  .q(PC)
    );

    flopenr #(.WIDTH(32)) irreg (
        .clk   (clk), .reset(reset), .en(IRWrite),
        .d(ReadData), .q(Instr)
    );

    //-----------------------------------------------------------------
    //  Banco de registros – selección de operandos
    //-----------------------------------------------------------------
    // Detectar cualquier instrucción de la familia MUL
    wire isMul = (Instr[7:4] == 4'b1001);

    // Primer operando (A) → Rm cuando MUL; de lo contrario Rn o PC
    wire [3:0] RA1 = isMul        ? Instr[11:8]            :        // Rm
                     (RegSrc[0]   ? 4'hF                   :        // PC
                                    Instr[19:16]);                  // Rn

    // Segundo operando (B) → Rn cuando MUL; de lo contrario Rn o Rd
    wire [3:0] RA2 = isMul        ? Instr[3:0]             :        // Rn
                     (RegSrc[1]   ? Instr[15:12]           :        // Rd en STR
                                    Instr[3:0]);                    // Rn

    // Direcciones de escritura
    wire [3:0] WA3 = Instr[15:12];   // RdLo
    assign     WA4 = Instr[19:16];   // RdHi

    regfile rf (
        .clk  (clk),
        .we3  (RegWrite),
        .ra1  (RA1),
        .ra2  (RA2),
        .wa3  (WA3),
        .wd3  (Result),
        .r15  (Result),     // PC se reenvía como R15
        .rd1  (RD1),
        .rd2  (RD2),
        .we4  (RegWriteHi), // habilitado sólo en UMULL/SMULL
        .wa4  (WA4),
        .wd4  (ALUOutHi)
    );

    //-----------------------------------------------------------------
    //  Canal de datos hacia la ALU
    //-----------------------------------------------------------------
    flopr #(.WIDTH(32)) ffRD1 (.clk(clk), .reset(reset), .d(RD1), .q(A));
    flopr #(.WIDTH(32)) ffRD2 (.clk(clk), .reset(reset), .d(RD2), .q(WriteData));

    assign SrcA = ALUSrcA ? PC : A;

    mux3 #(32) muxALUSrcB (
        .d0(WriteData),
        .d1(ExtImm),
        .d2(32'd4),
        .s(ALUSrcB),
        .y(SrcB)
    );

    extend ext (.Instr(Instr[23:0]), .ImmSrc(ImmSrc), .ExtImm(ExtImm));

    alu alu (
        .a(SrcA),
        .b(SrcB),
        .ALUControl(ALUControl),
        .Result(ALUResult),
        .ResultHi(ALUResultHi),
        .ALUFlags(ALUFlags)
    );

    //-----------------------------------------------------------------
    //  Retardo de un ciclo de los resultados de la ALU
    //-----------------------------------------------------------------
    flopr #(.WIDTH(32)) ffALUOut    (.clk(clk), .reset(reset), .d(ALUResult),   .q(ALUOut));
    flopr #(.WIDTH(32)) ffALUOutHi  (.clk(clk), .reset(reset), .d(ALUResultHi), .q(ALUOutHi));

    //-----------------------------------------------------------------
    //  Multiplexor de resultado final
    //-----------------------------------------------------------------
    mux3 #(32) muxResultSrc (
        .d0(ALUOut),
        .d1(Data),
        .d2(ALUResult),
        .s(ResultSrc),
        .y(Result)
    );

    //-----------------------------------------------------------------
    //  Acceso a memoria de datos
    //-----------------------------------------------------------------
    mux2 #(32) muxAdrSrc (.d0(PC), .d1(Result), .s(AdrSrc), .y(Adr));

    flopr #(.WIDTH(32)) ffData (.clk(clk), .reset(reset), .d(ReadData), .q(Data));
endmodule
