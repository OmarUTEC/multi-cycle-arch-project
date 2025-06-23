`timescale 1ns/1ps

module testbench;
    reg         clk;
    reg         reset;
    wire [31:0] WriteData;
    wire [31:0] Adr;
    wire        MemWrite;
    integer     i;

    // Instanciación del sistema
    top dut (
        .clk       (clk),
        .reset     (reset),
        .WriteData (WriteData),
        .Adr       (Adr),
        .MemWrite  (MemWrite)
    );


	initial begin
		reset <= 1;
		#(2)
			;
		reset <= 0;
	end

    always begin
		clk <= 1;
		#(5)
			;
		clk <= 0;
		#(5)
			;
	end

    // Mostrar contenido de la memoria ROM tras reset
    initial begin
        #25;
        $display("Contenido de IMEM tras el FETCH inicial:");
        for (i = 0; i < 24; i = i + 1)
            $display("IMEM[%0d] = %h", i, dut.mem.RAM[i]);
    end

    always @(posedge clk) begin
        if (dut.arm.dp.Instr !== 32'hxxxxxxxx) begin
            $display(
                "t=%0t  PC=0x%08h  Instr=0x%08h  IRWrite=%b  PCWrite=%b  MemWrite=%b  ALUControl=%03b  WriteData=0x%08h  Adr=0x%08h  ResultSrc=%b  ReadData=0x%08h  ExtImm=0x%08h  ALUFlags=%b",
                $time,
                dut.arm.dp.PC,
                dut.arm.dp.Instr,
                dut.arm.c.IRWrite,
                dut.arm.c.PCWrite,
                MemWrite,
                dut.arm.c.ALUControl,  //NUEVO
                WriteData,
                Adr,
                dut.arm.c.ResultSrc,
                dut.mem.rd,
                dut.arm.dp.ExtImm,
                dut.arm.dp.ALUFlags
            );
        end
    end

    // Finalización automática
    initial begin
        #1000;
        $display("Fin de la simulación.");
        $finish;
    end

endmodule
