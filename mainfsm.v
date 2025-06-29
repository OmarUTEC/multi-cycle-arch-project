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
            FETCH: nextstate = DECODE;
            DECODE: begin
                case (Op)
                    2'b00: begin
                        if (Funct[5] == 1'b1)
                            nextstate = EXECUTEI;
                        else
                            nextstate = EXECUTER;
                    end
                    2'b01: nextstate = MEMADR;
                    2'b10: nextstate = BRANCH;
                    default: nextstate = UNKNOWN;
                endcase
            end
            EXECUTER: nextstate = ALUWB;
            EXECUTEI: nextstate = ALUWB;
            MEMADR: begin
                if (Funct[0] == 1'b1)
                    nextstate = MEMRD;
                else
                    nextstate = MEMWR;
            end
            MEMRD: nextstate = MEMWB;
            MEMWR: nextstate = FETCH;
            MEMWB: nextstate = FETCH;
            BRANCH: nextstate = FETCH;
            ALUWB: nextstate = FETCH;
            default: nextstate = FETCH;
        endcase
    end

    // Control signal generation
    // {NextPC,Branch,MemW,RegW,IRWrite,AdrSrc,ResultSrc[1:0],ALUSrcA,ALUSrcB[1:0],ALUOp}
    // output logic
    always @(*) begin
        case (state)
        FETCH:      controls = 12'b010010101100;
        DECODE:     controls = 12'b000000101100;
        EXECUTER:   controls = 12'b000000000001;
        EXECUTEI:   controls = 12'b000000000011;
        MEMADR:     controls = 12'b000000000010; 
        MEMRD:      controls = 12'b000001000000;
        MEMWR:      controls = 12'b001001000000;
        MEMWB:      controls = 12'b000100010000;
        ALUWB:      controls = 12'b000100000000; 
        BRANCH:     controls = 12'b100000100010;
        default:    controls = 12'bxxxxxxxxxxxx;
        endcase
    end
    assign {NextPC, Branch, MemW, RegW, IRWrite, AdrSrc, ResultSrc, ALUSrcA, ALUSrcB, ALUOp} = controls;
endmodule
