//---------------------------------------------------------------------
//  Datapath – versión completa con soporte UMULL/SMULL y punto flotante
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
    input  wire [3:0]  ALUControl,    // Cambiado a 4 bits
    input  wire        RegWriteHi,
    input  wire        IsMovt,
    input  wire        IsMovm         // <-- AÑADIR

);

    //––– Señales internas
    wire [31:0] PCNext, ExtImm;
    wire [31:0] SrcA, SrcB, Result, Data;
    wire [31:0] RD1, RD2, A, ALUResult, ALUOut;
    wire [31:0] ALUResultHi, ALUOutHi;
    wire [3:0]  WA4;

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
    // Detectar instrucción MUL de 32 bits (NO flotantes)
    wire isMul = (Instr[7:4] == 4'b1001) && (Instr[27:23] != 5'b00001);  // MUL pero no UMULL/SMULL

    // Primer operando (A) → Rm cuando MUL; de lo contrario Rn o PC
    // Si es MOVT, el operando A es el mismo registro de destino (Rd).
    // De lo contrario, se usa la lógica original.
    // Reemplaza la línea de assign RA1
    wire [3:0] RA1 = (IsMovt || IsMovm) ? Instr[15:12] : // <-- MODIFICAR
                 (isMul       ? Instr[11:8]      :
                 (RegSrc[0]   ? 4'hF             :
                                Instr[19:16]));

    // Segundo operando (B) → Rn cuando MUL; de lo contrario Rm o Rd
    wire [3:0] RA2 = isMul        ? Instr[3:0]             :
                     (RegSrc[1]   ? Instr[15:12]           :
                                    Instr[3:0]);

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
        .r15  (Result),
        .rd1  (RD1),
        .rd2  (RD2),
        .we4  (RegWriteHi),
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

    // Instancia del módulo extend con TODAS las conexiones
    extend ext (
        .Instr(Instr[23:0]),
        .ImmSrc(ImmSrc),
        .IsMovm(IsMovm),
        .IsMovt(IsMovt),      // Conectar IsMovt
        .ExtImm(ExtImm)
    );

    // Instancia del módulo alu con TODAS las conexiones
    alu alu (
        .a(SrcA),
        .b(SrcB),
        .ALUControl(ALUControl),
        .Result(ALUResult),
        .ResultHi(ALUResultHi),
        .ALUFlags(ALUFlags),
        .ExtImm(ExtImm),      // Conectar ExtImm
        .A(A)                 // Conectar A
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