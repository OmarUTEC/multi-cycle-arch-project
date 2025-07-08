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
    ALUOp,
    RegWHi          // Nueva salida
);
    input  wire        clk;
    input  wire        reset;
    input  wire [1:0]  Op;
    input  wire [5:0]  Funct;
    output wire        IRWrite;
    output wire        AdrSrc;
    output wire        ALUSrcA;
    output wire [1:0]  ALUSrcB;
    output wire [1:0]  ResultSrc;
    output wire        NextPC;
    output wire        RegW;
    output wire        MemW;
    output wire        Branch;
    output wire        ALUOp;
    output wire        RegWHi;      // Nueva salida

    reg  [3:0]  state, nextstate;
    reg  [12:0] controls;   // Aumentado para incluir RegWHi

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
    // {RegWHi,NextPC,Branch,MemW,RegW,IRWrite,AdrSrc,ResultSrc[1:0],ALUSrcA,ALUSrcB[1:0],ALUOp}
    always @(*) begin
        case (state)
        FETCH:      controls = 13'b0010010101100;  // 13 bits
        DECODE:     controls = 13'b0000000101100;  // 13 bits
        EXECUTER:   controls = 13'b0000000000001;  // 13 bits
        EXECUTEI:   controls = 13'b0000000000011;  // 13 bits
        MEMADR:     controls = 13'b0000000000010;  // 13 bits
        MEMRD:      controls = 13'b0000001000000;  // 13 bits
        MEMWR:      controls = 13'b0001001000000;  // 13 bits
        MEMWB:      controls = 13'b0000100010000;  // 13 bits
        ALUWB:      controls = 13'b1000100000000;  // RegWHi = 1, 13 bits
        BRANCH:     controls = 13'b0100000100010;  // 13 bits
        default:    controls = 13'bxxxxxxxxxxxxx;  // 13 bits
        endcase
    end
    
    assign {RegWHi, NextPC, Branch, MemW, RegW, IRWrite, AdrSrc, ResultSrc, ALUSrcA, ALUSrcB, ALUOp} = controls;
endmodule