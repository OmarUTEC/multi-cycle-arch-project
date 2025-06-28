//ARCH <<ll
module top (
    input  wire        clk,
    input  wire        reset,
    output wire [31:0] PC,
    output wire [31:0] Instr,
    output wire [31:0] WriteData,
    output wire [31:0] Adr,
    output wire        MemWrite
);
    // Señal para leer dato de memoria (compartida IMEM/DMEM)
    wire [31:0] ReadData;

    // Instancia del procesador
    arm arm (
        .clk       (clk),
        .reset     (reset),
        .PC        (PC),        // ahora sí existe en top
        .Instr     (Instr),     // ahora sí existe en top
        .MemWrite  (MemWrite),
        .Adr       (Adr),
        .WriteData (WriteData),
        .ReadData  (ReadData)
    );

    // Memoria unificada (Instrucciones ↔ Datos)
    mem mem (
        .clk (clk),
        .we  (MemWrite),
        .a   (Adr),
        .wd  (WriteData),
        .rd  (ReadData)
    );
endmodule
