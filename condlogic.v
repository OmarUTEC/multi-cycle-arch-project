// condlogic.v
// Lógica de condición y control final para procesador multicycle ARMv4

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
    input  wire       clk;       // Reloj
    input  wire       reset;     // Reset síncrono
    input  wire [3:0] Cond;      // Campo de condición de la instrucción
    input  wire [3:0] ALUFlags;  // Flags actuales (NZCV) de la ALU
    input  wire [1:0] FlagW;     // Máscara de flags a escribir (S bit)
    input  wire       PCS;       // Indica que la instrucción puede escribir PC
    input  wire       NextPC;    // Señal de PCWrite desde FSM
    input  wire       RegW;      // Señal interna de RegWrite desde FSM
    input  wire       MemW;      // Señal interna de MemWrite desde FSM
    output wire       PCWrite;   // Habilita escritura de PC final
    output wire       RegWrite;  // Habilita escritura de registros final
    output wire       MemWrite;  // Habilita escritura de memoria final

    // Señales internas
    wire [1:0] FlagWrite;  // Flags enmascarados y sincronizados
    wire [3:0] Flags;      // Registro de flags NZCV
    wire       CondEx;     // Expresión de condición verdadera

    // Delay writing flags hasta la etapa ALUWB (S bit y condicional)
    reg32 #(.WIDTH(2)) flagwritereg (
        .clk   (clk),
        .rst   (reset),        // coincide con el puerto rst del reg32
        .load  (1'b1),         // carga siempre el nuevo valor
        .d     (FlagW & {2{CondEx}}),
        .q     (FlagWrite)
    );

    // Registro de flags: almacena ALUFlags al final de ALUWB
    // Registro de 4 bits para almacenar flags NZCV
    reg32 #(.WIDTH(4)) flagsreg (
        .clk(clk),
        .rst(reset),
        .load(1'b1),
        .d(ALUFlags),
        .q(Flags)
    );

    // Chequeo de condición: compara Cond con Flags
    condcheck condchk (
        .Cond(Cond),
        .Flags(Flags),
        .CondEx(CondEx)
    );

    // Generación final de señales, solo si se cumple la condición
    assign PCWrite  = NextPC  & CondEx;
    assign RegWrite = RegW    & CondEx;
    assign MemWrite = MemW    & CondEx;

endmodule
