module mainfsm (
    clk,
    reset,
    Op,
    Funct,
    IRWrite,
    AdrSrc,
    ALUSrcA,
    ALUSrcB,
    ResultSrc,
    NextPC,
    RegW,
    MemW,
    Branch,
    ALUOp
);
    input  wire        clk;
    input  wire        reset;
    input  wire [1:0]  Op;
    input  wire [5:0]  Funct;
    output wire        IRWrite;
    output wire        AdrSrc;
    output wire        ALUSrcA;       // 1 bit
    output wire [1:0]  ALUSrcB;
    output wire [1:0]  ResultSrc;
    output wire        NextPC;
    output wire        RegW;
    output wire        MemW;
    output wire        Branch;
    output wire        ALUOp;

    reg  [3:0]  state, nextstate;
    reg  [11:0] controls;   // ALUSrcA para 1 bit

    // State encoding
    localparam FETCH    = 4'd0,
               DECODE   = 4'd1,
               MEMADR   = 4'd2,
               MEMRD    = 4'd3,
               MEMWB    = 4'd4,
               MEMWR    = 4'd5,
               EXECUTER = 4'd6,
               EXECUTEI = 4'd7,
               ALUWB    = 4'd8,
               BRANCH   = 4'd9,
               UNKNOWN  = 4'd10;

    // Sequential state register
    always @(posedge clk or posedge reset) begin
        if (reset)
            state <= FETCH;
        else
            state <= nextstate;
    end

    // Next‐state logic
    always @(*) begin
        casex (state)
            FETCH:  nextstate = DECODE; 
            DECODE: begin case (Op)  // dependiendo de Op
                2'b00: nextstate = (Funct[5]) ? EXECUTEI : EXECUTER; // R-type/I-type dependiendo de 'I'
                2'b01: nextstate = MEMADR;                           // Memoria
                2'b10: nextstate = BRANCH;                           // Branch
                default: nextstate = UNKNOWN;
            endcase end
            EXECUTER: nextstate = ALUWB;
            EXECUTEI: nextstate = ALUWB;
            MEMADR: nextstate = (Funct[0]) ? MEMRD : MEMWR;  // Load/Store dependiendo de 'L'
            MEMWR: nextstate = FETCH;                       // After Store
            MEMRD: nextstate = MEMWB;
            MEMWB: nextstate = FETCH;                       // After Load
            BRANCH: nextstate = FETCH;                      // After Branch
            ALUWB: nextstate = FETCH;                       // After ALU Write Back
            default: nextstate = FETCH;
        endcase
    end

    // Control signal generation
    // {NextPC,Branch,MemW,RegW,IRWrite,AdrSrc,ResultSrc[1:0],ALUSrcA,ALUSrcB[1:0],ALUOp}
    // output logic
    always @(*)
        case (state)
        FETCH:      controls = 12'b010010_10_1_10_0;
        DECODE:     controls = 12'b000000_10_1_10_0;
        EXECUTER:   controls = 12'b000000_00_0_00_1;
        EXECUTEI:   controls = 12'b000000_00_0_01_1;
        MEMADR:     controls = 12'b000000_00_0_01_0; 
        MEMRD:      controls = 12'b000001_00_0_00_0;
        MEMWR:      controls = 12'b001001_00_0_00_0;
        MEMWB:      controls = 12'b000100_01_0_00_0;
        ALUWB:      controls = 12'b000100_00_0_00_0; 
        BRANCH:     controls = 12'b010000_10_0_01_0;
        default:    controls = 12'bxxxxxx_xx_x_xx_x;
        endcase
    assign {NextPC, Branch, MemW, RegW, IRWrite, AdrSrc, ResultSrc, ALUSrcA, ALUSrcB, ALUOp} = controls;
endmodule
