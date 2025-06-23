// datapath.v
// Datapath multicycle completo para ARMv4 (adaptado de Harris)

module datapath (
    clk,
    reset,
    Adr,
    WriteData,
    ReadData,
    Instr,
    ALUFlags,
    PCWrite,
    RegWrite,
    IRWrite,
    AdrSrc,
    RegSrc,
    ALUSrcA,
    ALUSrcB,
    ResultSrc,
    ImmSrc,
    ALUControl
);
    input  wire        clk;
    input  wire        reset;
    output wire [31:0] Adr;
    output wire [31:0] WriteData;
    input  wire [31:0] ReadData;
    output wire [31:0] Instr;
    output wire [3:0]  ALUFlags;
    input  wire        PCWrite;
    input  wire        RegWrite;
    input  wire        IRWrite;
    input  wire        AdrSrc;
    input  wire [1:0]  RegSrc;
    input  wire [1:0]  ALUSrcA;
    input  wire [1:0]  ALUSrcB;
    input  wire [1:0]  ResultSrc;
    input  wire [1:0]  ImmSrc;
    input  wire [2:0]  ALUControl;

    // Señales internas
    wire [31:0] PCNext;
    wire [31:0] PC;
    wire [31:0] ExtImm;
    wire [31:0] SrcA;
    wire [31:0] SrcB;
    wire [31:0] ALUB;
    wire [31:0] Result;
    wire [31:0] Data;
    wire [31:0] RD1;
    wire [31:0] RD2;
    wire [31:0] A;
    wire [31:0] ALUResult;
    wire [31:0] ALUOut;
    wire [3:0]  RA1;
    wire [3:0]  RA2;
    wire [3:0]  WA;

    assign Data = ReadData;

    // PC
    assign PCNext = Result;
    //assign PCNext = ALUOut;
    //assign PCNext = ALUOut; 

    reg32 pcreg (
        .clk(clk),
        .rst(reset),
        .load(PCWrite),
        .d(PCNext),
        .q(PC)
    );

    // IR
    reg32 irreg (
        .clk(clk),
        .rst(reset),
        .load(IRWrite),
        .d(ReadData),
        .q(Instr)
    );

    // Banco de registros
    mux3 #(.WIDTH(4)) ra1_mux (
        .d0(Instr[19:16]),
        .d1(4'd15),
        .d2(4'd15),
        .s({1'b0, RegSrc[0]}),
        .y(RA1)
    );

    mux3 #(.WIDTH(4)) ra2_mux (
        .d0(Instr[3:0]),
        .d1(Instr[15:12]),
        .d2(Instr[15:12]),
        .s({1'b0, RegSrc[1]}),
        .y(RA2)
    );

    mux3 #(.WIDTH(4)) waddr_mux (
        .d0(Instr[15:12]),
        .d1(Instr[3:0]),
        .d2((RegSrc==2)?4'd14:4'd15),
        .s(RegSrc),
        .y(WA)
    );

    mux3 #(.WIDTH(32)) wdata_mux (
        .d0(ALUOut),      // ResultSrc = 00
        .d1(Data),        // ResultSrc = 01
        .d2(PC + 4),      // ResultSrc = 10
        //.d2(ALUResult),
        .s(ResultSrc),
        .y(Result)
    );


    regfile rf (
        .clk(clk),
        .we3(RegWrite),
        .ra1(RA1),
        .ra2(RA2),
        .wa3(WA),
        .wd3(Result),
        .r15(PC),
        .rd1(RD1),
        .rd2(RD2)
    );

    assign Adr = AdrSrc ? ALUOut : PC;
    assign WriteData = RD2;

    // A y B
    reg32 areg (
        .clk(clk),
        .rst(reset),
        .load(1'b1),
        .d(RD1),
        .q(A)
    );

    reg32 breg (
        .clk(clk),
        .rst(reset),
        .load(1'b1),
        .d(RD2),
        .q(SrcB)
    );

    extend imm_ext (
        .Instr(Instr[23:0]),
        .ImmSrc(ImmSrc),
        .ExtImm(ExtImm)
    );

    mux3 #(.WIDTH(32)) mux_alu_a (
        .d0(A),
        .d1(PC),
        .d2(32'd0),
        .s(ALUSrcA),
        .y(SrcA)
    );

    mux3 #(.WIDTH(32)) mux_alu_b (
        .d0(RD2),
        .d1(ExtImm),
        .d2(32'd4),
        .s(ALUSrcB),
        .y(ALUB)
    );

    alu alu_unit (
        .a(SrcA),
        .b(ALUB),
        .ALUControl(ALUControl),
        .Result(ALUResult),
        .ALUFlags(ALUFlags)
    );

    reg32 aluout_reg (
        .clk(clk),
        .rst(reset),
        .load(1'b1),
        .d(ALUResult),
        .q(ALUOut)
    );

endmodule
