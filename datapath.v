module datapath (
    clk,
    reset,
    MemWrite,
    Adr,
    WriteData,
    ReadData,
    Instr,
    PC,
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
    input  wire        MemWrite;     // <-- new
    output wire [31:0] Adr;
    output wire [31:0] WriteData;
    input  wire [31:0] ReadData;    //RD
    output wire [31:0] Instr;
    output wire [31:0] PC;
    output wire [3:0]  ALUFlags;
    input  wire        PCWrite;
    input  wire        RegWrite;
    input  wire        IRWrite;
    input  wire        AdrSrc;
    input  wire [1:0]  RegSrc;
    input  wire        ALUSrcA;
    input  wire [1:0]  ALUSrcB;
    input  wire [1:0]  ResultSrc;
    input  wire [1:0]  ImmSrc;
    input  wire [2:0]  ALUControl;

    // Señales internas
    wire [31:0] PCNext;
    wire [31:0] ExtImm;
    wire [31:0] SrcA;
    wire [31:0] SrcB;
    wire [31:0] Result;
    wire [31:0] Data;
    wire [31:0] RD1;
    wire [31:0] RD2;
    wire [31:0] A;
    wire [31:0] ALUResult;
    wire [31:0] ALUOut;
    wire [3:0]  RA1;
    wire [3:0]  RA2;
    

    assign PCNext = Result;
    
    //flip flop del PC
    flopenr #(.WIDTH(32)) pcreg (
        .clk(clk),
        .reset(reset),
        .en(PCWrite),
        .d(PCNext),
        .q(PC)
    );

    //flip flop del IRWrite
    flopenr #(.WIDTH(32)) irreg (
        .clk(clk),
        .reset(reset),
        .en(IRWrite),
        .d(ReadData),
        .q(Instr)
    );
    
    //flip flop de ReadData = Data
    flopr #(.WIDTH(32)) ffdd (
        .clk(clk),
        .reset(reset),
        .d(ReadData),
        .q(Data)
    );
    
    
    //mux AdrSrc
	mux2 #(32) muxAdrSrc(
		.d0(PC),
		.d1(Result),
		.s(AdrSrc),
		.y(Adr)
	);
    
    //register file
     regfile rf (
        .clk(clk),
        .we3(RegWrite),
        .ra1(RA1),
        .ra2(RA2),
        .wa3(Instr[15:12]),
        .wd3(Result),
        .r15(Result),
        .rd1(RD1),
        .rd2(RD2)
    );
 
 
     flopr #(.WIDTH(32)) ffRD1 (
        .clk(clk),
        .reset(reset),
        .d(RD1),
        .q(A)
    );

    flopr #(.WIDTH(32)) ffRD2 (
        .clk(clk),
        .reset(reset),
        .d(RD2),
        .q(WriteData)
    );


 	mux2 #(32) muxALUSrcA(
		.d0(A),
		.d1(PC),
		.s(ALUSrcA),
		.y(SrcA)
	);
 
     mux3 #(32) muxALUSrcB(
		.d0(WriteData),
		.d1(ExtImm),
		.d2(32'd4),
		.s(ALUSrcB),
		.y(SrcB)
	);
 
 
    extend ext(
		.Instr(Instr[23:0]),
		.ImmSrc(ImmSrc),
		.ExtImm(ExtImm)
	);
 
    alu alu(
        .a(SrcA), 
        .b(SrcB), 
        .ALUControl(ALUControl), 
        .Result(ALUResult), 
        .ALUFlags(ALUFlags)
	);
 
     flopr #(.WIDTH(32)) ffALUOut (
        .clk(clk),
        .reset(reset),
        .d(ALUResult),
        .q(ALUOut)
    );
 
    
    mux3 #(32) muxResultSrc(
		.d0(ALUOut),
		.d1(Data),
		.d2(ALUResult),
		.s(ResultSrc),
		.y(Result)
	);
 
 
    mux2 #(4) ra1mux(
		.d0(Instr[19:16]),
		.d1(4'b1111),
		.s(RegSrc[0]),
		.y(RA1)
	);
	mux2 #(4) ra2mux(
		.d0(Instr[3:0]),
		.d1(Instr[15:12]),
		.s(RegSrc[1]),
		.y(RA2)
	);
endmodule
