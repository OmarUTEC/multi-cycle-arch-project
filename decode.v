// decode.v
// Decodificador de instrucciones y FSM para procesador multicycle ARMv4

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
    ALUControl
);

    // Puertos de entrada
    input  wire       clk;        // Reloj de máquina de estados
    input  wire       reset;      // Reset síncrono
    input  wire [1:0] Op;         // Bits [27:26] de Instr: clase de instrucción
    input  wire [5:0] Funct;      // Bits [25:20] de Instr: función/operación
    input  wire [3:0] Rd;         // Bits [15:12], registro destino

    // Puertos de salida
    output reg  [1:0] FlagW;      // Qué flags actualizar (NZCV)
    output wire       PCS;        // Habilita escritura de PC condicional
    output wire       NextPC;     // Desde FSM
    output wire       RegW;       // Enable escritura de registro
    output wire       MemW;       // Enable escritura de memoria
    output wire       IRWrite;    // Enable escritura de IR
    output wire       AdrSrc;     // Selección de dirección a memoria
    output wire [1:0] ResultSrc;  // Mux de WriteBack
    output wire [1:0] ALUSrcA;    // Mux A para ALU
    output wire [1:0] ALUSrcB;    // Mux B para ALU
    output wire [1:0] ImmSrc;     // Tipo de inmediato
    output wire [1:0] RegSrc;     // Mux para selección de registros
    output reg  [2:0] ALUControl; // Operación de la ALU

    // Señales internas
    wire Branch;
    wire ALUOp;

    // FSM principal
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
        .ALUOp     (ALUOp)
    );

    // ----------------- ALU Decoder -----------------
    // Actualiza banderas si S está activo
    always @(*) begin
        if (ALUOp) begin
            case (Funct[4:1])
                4'b0100: ALUControl = 3'b000;  // ADD
                4'b0010: ALUControl = 3'b001;  // SUB
                4'b0000: ALUControl = 3'b010;  // AND
                4'b1100: ALUControl = 3'b011;  // ORR
                4'b0001: ALUControl = 3'b100;  // EOR
                default: ALUControl = 3'b000;  // Default ADD
            endcase
            FlagW = (Funct[0]) ? 2'b11 : 2'b00;
        end else begin
            ALUControl = 3'b000;
            FlagW = 2'b00;
        end
    end

    // ----------------- PC Logic -----------------
    assign PCS = Branch;

    // ----------------- Instruction Decoder -----------------
    assign ImmSrc = Op;
    assign RegSrc = Op;

endmodule
