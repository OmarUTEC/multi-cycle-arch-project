module decode (
    input  wire        clk,
    input  wire        reset,
    input  wire [31:0] Instr,

    // Control outputs
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
    output reg  [3:0]  ALUControl,
    output wire        RegWHi,
    output wire        IsMovt,
    output wire        IsMovm  // <-- AÑADIR ESTA LÍNEA

);
    // Instruction fields
    wire [1:0] Op      = Instr[27:26];            // opcode class
    wire        I_flag  = Instr[25];               // immediate flag
    wire [3:0]  Opcode  = Instr[24:21];            // nominal opcode
    wire        S_flag  = Instr[20];               // set flags
    wire [3:0]  Rd      = Instr[15:12];            // destination register

    // FSM control signals from mainfsm
    wire Branch, ALUOp, RegWHi_int;
    wire [5:0] Funct   = Instr[25:20];             // for mainfsm

    mainfsm fsm (
        .clk        (clk),
        .reset      (reset),
        .Op         (Op),
        .Funct      (Funct),
        .IRWrite    (IRWrite),
        .AdrSrc     (AdrSrc),
        .ALUSrcA    (ALUSrcA),
        .ALUSrcB    (ALUSrcB),
        .ResultSrc  (ResultSrc),
        .NextPC     (NextPC),
        .RegW       (RegW),
        .MemW       (MemW),
        .Branch     (Branch),
        .ALUOp      (ALUOp),
        .RegWHi     (RegWHi_int)
    );

    // Long multiply (UMULL/SMULL) pattern
    wire mul_long = (Op == 2'b00) && (Instr[27:23] == 5'b00001) && (Instr[7:4] == 4'b1001);
    wire is_movm = (Op == 2'b00) && I_flag && (Opcode == 4'b1110); // <-- AÑADIR

    wire is_umul   = mul_long && Instr[22];
    wire is_smul   = mul_long && !Instr[22];

    // Floating-point ops
    // En decode.v, reemplaza las líneas de detección de FADDS/FMULS por:

// En decode.v, busca las líneas donde se definen is_fadds e is_fmuls y reemplázalas por:
// Detección simplificada para instrucciones flotantes
    // Usamos Opcode bits para diferenciar: FADDS=1110, FMULS=1111
    wire is_custom_float = (Op == 2'b00) && (Opcode == 4'b1000);
    wire is_fadds = is_custom_float && !Instr[4];
    wire is_fmuls = is_custom_float && Instr[4];
    // MOV/MOVT immediates
    wire is_mov  = (Op == 2'b00) && I_flag && (Opcode == 4'b1101);
    wire is_movt = (Op == 2'b00) && I_flag && (Opcode == 4'b1010);
    assign IsMovt = is_movt;
    assign IsMovm = is_movm; // <-- AÑADIR

    // ALUControl and FlagW assignment
    always @(*) begin
        if (ALUOp) begin
            if      (is_umul)   ALUControl = 4'b0101;
            else if (is_smul)   ALUControl = 4'b0110;
            else if (is_fadds)  ALUControl = 4'b1000;
            else if (is_fmuls)  ALUControl = 4'b1001;
            else if (is_mov)    ALUControl = 4'b1011;
            else if (is_movt)   ALUControl = 4'b1100;
            else if (is_movm)   ALUControl = 4'b1101; // 

            else begin
                case (Opcode)
                    4'b0100: ALUControl = 4'b0000;  // ADD
                    4'b0010: ALUControl = 4'b0001;  // SUB
                    4'b0000: ALUControl = 4'b0010;  // AND
                    4'b1100: ALUControl = 4'b0011;  // ORR
                    4'b1001: ALUControl = 4'b0111;  // MUL (32)
                    4'b0001: ALUControl = 4'b0100;  // DIV
                    default: ALUControl = 4'b0000;
                endcase
            end
            FlagW = S_flag ? 2'b11 : 2'b00;
        end else begin
            ALUControl = 4'b0000;
            FlagW      = 2'b00;
        end
    end

    // Only write high register on long multiplies
    assign RegWHi = RegWHi_int & mul_long;

    // Final control outputs
    assign PCS     = ((Rd == 4'b1111) & RegW) | Branch;
    assign ImmSrc  = (is_mov || is_movt || is_movm) ? 2'b11 : Op; // <-- MODIFICAR

    assign RegSrc[0] = (Op == 2'b10);
    assign RegSrc[1] = (Op == 2'b01);
endmodule
