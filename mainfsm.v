// mainfsm.v
// Máquina de estados para procesador multicycle ARMv4

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
    input wire clk;
    input wire reset;
    input wire [1:0] Op;
    input wire [5:0] Funct;
    output wire IRWrite;
    output wire AdrSrc;
    output wire [1:0] ALUSrcA;
    output wire [1:0] ALUSrcB;
    output wire [1:0] ResultSrc;
    output wire NextPC;
    output wire RegW;
    output wire MemW;
    output wire Branch;
    output wire ALUOp;

    reg [3:0] state;
    reg [3:0] nextstate;
    reg [12:0] controls;

    localparam [3:0] FETCH    = 4'd0,
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

    // Registro de estado
    always @(posedge clk or posedge reset)
        if (reset)
            state <= FETCH;
        else
            state <= nextstate;

    // Lógica de transición entre estados
    always @(*) begin
        case (state)
            FETCH:    nextstate = DECODE;
            DECODE: begin
                case (Op)
                    2'b00: nextstate = (Funct[5]) ? EXECUTEI : EXECUTER;
                    2'b01: nextstate = MEMADR; // LDR o STR
                    2'b10: nextstate = BRANCH;
                    default: nextstate = DECODE;
                endcase
            end
            EXECUTER: nextstate = ALUWB;
            EXECUTEI: nextstate = ALUWB;
            ALUWB:    nextstate = FETCH;
        
            // 📌 Aquí es clave distinguir entre LDR y STR
            MEMADR: begin
                // bit 20 en ARM determina si es LDR (1) o STR (0)
                if (Funct[0] == 1'b1)
                    nextstate = MEMRD;   // LDR
                else
                    nextstate = MEMWR;   // STR
            end
            MEMRD:    nextstate = MEMWB;
            MEMWB:    nextstate = FETCH;
            MEMWR:    nextstate = FETCH;
            BRANCH:   nextstate = FETCH;
            default:  nextstate = FETCH;
        endcase
    end

    // Lógica de salidas (Moore) con vector de control de 13 bits:
    // {NextPC,Branch,MemW,RegW,IRWrite,AdrSrc,ResultSrc[1:0],ALUSrcA[1:0],ALUSrcB[1:0],ALUOp}
    always @(*) begin
        case (state)
            FETCH:     controls = 13'b1000101010010;
            DECODE:    controls = 13'b0000001001100; // Preparar A y B, ALU para direccionamiento
            EXECUTER:  controls = 13'b0000000001001; // ALU A=Reg, B=Reg, usar Funct
            EXECUTEI:  controls = 13'b0000000001101; // ALU A=Reg, B=Imm, usar Funct
            ALUWB:     controls = 13'b0001000000000; // WriteBack resultado ALU
            MEMADR:    controls = 13'b0000010001100; // ALU calcula dirección base+offset
            MEMRD:     controls = 13'b0000010000000; // Leer memoria (ReadData listo)
            MEMWB:     controls = 13'b0001000100000; // WriteBack dato de memoria
            MEMWR:     controls = 13'b0010010000000; // Escribir a memoria
            BRANCH:    controls = 13'b1100000000000; // Calcular y escribir nueva PC
            default:   controls = 13'bxxxxxxxxxxxxx; // Estado desconocido
        endcase
    end

    // Asignación de salidas del vector de control
    assign {NextPC, Branch, MemW, RegW, IRWrite, AdrSrc, ResultSrc, ALUSrcA, ALUSrcB, ALUOp} = controls;

endmodule
