module decode (
    clk,
    reset,
    Op,
    Funct,
    Rd,
    FlagW,
    PCS,
    NextPC,
    RegW,
    MemW,
    IRWrite,
    AdrSrc,
    ResultSrc,
    ALUSrcA,
    ALUSrcB,
    ImmSrc,
    RegSrc,
    ALUControl,
    RegWHi          // Nueva salida
);

    input  wire       clk;       
    input  wire       reset;     
    input  wire [1:0] Op;       
    input  wire [5:0] Funct;  
    input  wire [3:0] Rd;        

    output reg  [1:0] FlagW;      
    output wire       PCS;        
    output wire       NextPC;     
    output wire       RegW;       
    output wire       MemW;       
    output wire       IRWrite;    
    output wire       AdrSrc;     
    output wire [1:0] ResultSrc;  
    output wire       ALUSrcA;    
    output wire [1:0] ALUSrcB;    
    output wire [1:0] ImmSrc;     
    output wire [1:0] RegSrc;     
    output reg  [2:0] ALUControl;
    output wire       RegWHi;     // Nueva salida

    wire Branch;
    wire ALUOp;
    wire IsMulOp;

    mainfsm fsm (
        .clk       (clk),
        .reset     (reset),
        .Op        (Op),
        .Funct     (Funct),
        .IRWrite   (IRWrite),
        .AdrSrc    (AdrSrc),
        .ALUSrcA   (ALUSrcA),
        .ALUSrcB   (ALUSrcB),
        .ResultSrc (ResultSrc),
        .NextPC    (NextPC),
        .RegW      (RegW),
        .MemW      (MemW),
        .Branch    (Branch),
        .ALUOp     (ALUOp),
        .RegWHi    (RegWHi)     // Nueva conexión
    );

    always @(*) begin
        if (ALUOp) begin
            case (Funct[4:1])
                4'b0100: ALUControl = 3'b000;  // ADD
                4'b0010: ALUControl = 3'b001;  // SUB
                4'b0000: ALUControl = 3'b010;  // AND
                4'b1100: ALUControl = 3'b011;  // ORR
                4'b1001: ALUControl = 3'b111;  // MUL
                4'b1101: ALUControl = 3'b110;  // SMUL
                4'b1111: ALUControl = 3'b101;  // UMUL
                4'b0001: ALUControl = 3'b100;  // DIV
                default: ALUControl = 3'b000;  // Default ADD
            endcase
            FlagW = (Funct[0]) ? 2'b11 : 2'b00;
        end else begin
            ALUControl = 3'b000;
            FlagW = 2'b00;
        end
    end

    assign PCS = ((Rd == 4'b1111) & RegW) | Branch;
    assign ImmSrc = Op;
    assign RegSrc[0] = (Op == 2'b10); // PC on Branch
    assign RegSrc[1] = (Op == 2'b01); // Rd on STR 

endmodule