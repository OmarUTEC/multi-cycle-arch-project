module condlogic (
    clk,
    reset,
    Cond,
    ALUFlags,
    FlagW,
    PCS,
    NextPC,
    RegW,
    MemW,
    PCWrite,
    RegWrite,
    MemWrite
);
    // Port declarations
    input  wire       clk;
    input  wire       reset;
    input  wire [3:0] Cond;
    input  wire [3:0] ALUFlags;
    input  wire [1:0] FlagW;
    input  wire       PCS;
    input  wire       NextPC;
    input  wire       RegW;
    input  wire       MemW;
    output wire       PCWrite;
    output wire       RegWrite;
    output wire       MemWrite;

    // Internal signals
    wire        CondEx;
    wire        CondExNext;
    wire [1:0]  FlagWrite;
    wire [3:0]  Flags;

    // Flag registers
    flopenr #(.WIDTH(2)) flagreg_hi (
        .clk   (clk),
        .reset (reset),
        .en    (FlagWrite[1]),
        .d     (ALUFlags[3:2]),
        .q     (Flags[3:2])
    );
    flopenr #(.WIDTH(2)) flagreg_lo (
        .clk   (clk),
        .reset (reset),
        .en    (FlagWrite[0]),
        .d     (ALUFlags[1:0]),
        .q     (Flags[1:0])
    );

    // Evaluate condition
    condcheck condchk (
        .Cond   (Cond),
        .Flags  (Flags),
        .CondEx (CondEx)
    );

    // Latch condition 
    flopr #(.WIDTH(1)) condreg (
        .clk   (clk),
        .reset (reset),
        .d     (CondEx),
        .q     (CondExNext)
    );

    assign FlagWrite = FlagW & {2{CondEx}};
    assign RegWrite  = RegW  & CondEx;      
    assign MemWrite  = MemW  & CondEx;     
    assign PCWrite   = PCS   | (NextPC & CondEx);

endmodule