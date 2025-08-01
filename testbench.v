//Harris version 
//ok
module testbench;
    reg         clk;
    reg         reset;
    wire [31:0] PC;
    wire [31:0] Instr;
    wire [31:0] WriteData;
    wire [31:0] Adr;
    wire        MemWrite;
    wire [3:0]  state;    // Internal FSM state
    integer     i;

    assign state = dut.arm.c.dec.fsm.state;

    top dut (
        .clk       (clk),
        .reset     (reset),
        .PC        (PC),
        .Instr     (Instr),
        .WriteData (WriteData),
        .Adr       (Adr),
        .MemWrite  (MemWrite)
    );

    initial begin
        reset = 1;
        #22;
        reset = 0;
    end

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        #25;
        $display("Contenido de IMEM tras el FETCH inicial:");
        for (i = 0; i < 7; i = i + 1)
            $display("IMEM[%0d] = %h", i, dut.mem.RAM[i]);
    end

    always @(posedge clk) begin
        if (dut.arm.dp.Instr !== 32'hxxxxxxxx) begin
            $display(
                "t=%0t  STATE=%0d  PC=0x%08h  Instr=0x%08h  IRWrite=%b  PCWrite=%b  MemWrite=%b  ALUControl=%03b  WriteData=0x%08h  Adr=0x%08h  ResultSrc=%b  ReadData=0x%08h  ExtImm=0x%08h  ALUFlags=%b",
                $time,
                state,
                dut.arm.dp.PC,
                dut.arm.dp.Instr,
                dut.arm.c.IRWrite,
                dut.arm.c.PCWrite,
                MemWrite,
                dut.arm.c.ALUControl,
                WriteData,
                Adr,
                dut.arm.c.ResultSrc,
                dut.mem.rd,
                dut.arm.dp.ExtImm,
                dut.arm.dp.ALUFlags
            );
        end
    end
    
    //----- REPORTE FINAL DEL BANCO DE REGISTROS -----
    initial begin
        #100000;                           // mismo instante en que ya ibas a terminar
        $display("\n=== CONTENIDO FINAL DEL REGFILE ===");
        for (i = 0; i < 16; i = i + 1)
            $display("R%0d=%08h", i, dut.arm.dp.rf.rf[i]);
        $finish;                         // finaliza la simulación
    end
    
initial begin
  $dumpfile("dump.vcd");   // Nombre del archivo de salida
  $dumpvars;               // Registra todas las señales del testbench
end
endmodule
