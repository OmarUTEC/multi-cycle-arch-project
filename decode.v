module decode (
    input  wire        clk,
    input  wire        reset,
    input  wire [31:0] Instr,

    output reg  [1:0]  FlagW,
    output wire        PCS,
    output wire        NextPC,
    output wire        RegW,
    output wire        MemW,
    output wire        IRWrite,
    output wire        AdrSrc,
    output wire [1:0]  ResultSrc,
    output wire        ALUSrcA,
    output wire [1:0]  ALUSrcB,
    output wire [1:0]  ImmSrc,
    output wire [1:0]  RegSrc,
    output reg  [2:0]  ALUControl,
    output wire        RegWHi
);
    /* ––– Campos que necesitaremos ––– */
    wire [1:0] Op    = Instr[27:26];
    wire [5:0] Funct = Instr[25:20];
    wire [3:0] Rd    = Instr[15:12];

    /* ––– Señales internas ––– */
    wire Branch, ALUOp, RegWHi_int;

    /* ––– FSM principal (sin cambios) ––– */
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
        .RegWHi    (RegWHi_int)
    );

    /* ––– Patrón MUL-long (SMULL / UMULL) –––
       op          = 00
       bits 27:22  = 00001U
       bits 7:4    = 1001
    */
    wire mul_long = (Op == 2'b00) &&
                    (Instr[27:23] == 5'b00001) &&  // 27-23 = 00001
                    (Instr[7:4]   == 4'b1001);

    wire is_umul =  mul_long &&  Instr[22];  // U = 1
    wire is_smul =  mul_long && !Instr[22];  // U = 0

    /* ––– ALUControl y FlagW ––– */
    always @(*) begin
        if (ALUOp) begin
            if (is_umul)      ALUControl = 3'b101;   // UMULL
            else if (is_smul) ALUControl = 3'b110;   // SMULL
            else begin
                case (Funct[4:1])
                    4'b0100: ALUControl = 3'b000;  // ADD
                    4'b0010: ALUControl = 3'b001;  // SUB
                    4'b0000: ALUControl = 3'b010;  // AND
                    4'b1100: ALUControl = 3'b011;  // ORR
                    4'b1001: ALUControl = 3'b111;  // MUL-32
                    4'b0001: ALUControl = 3'b100;  // DIV (extensión)
                    default: ALUControl = 3'b000;
                endcase
            end
            FlagW = (Funct[0]) ? 2'b11 : 2'b00;
        end else begin
            ALUControl = 3'b000;
            FlagW      = 2'b00;
        end
    end

    /* ––– Escritura del registro alto (Ra) ––– */
    assign RegWHi = RegW & mul_long;   // solo SMULL / UMULL

    /* ––– Resto de salidas ––– */
    assign PCS     = ((Rd == 4'b1111) & RegW) | Branch;
    assign ImmSrc  = Op;
    assign RegSrc[0] = (Op == 2'b10);  // PC en Branch
    assign RegSrc[1] = (Op == 2'b01);  // Rd en STR
endmodule
