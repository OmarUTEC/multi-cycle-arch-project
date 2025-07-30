// corregido
module regfile (
    input  wire        clk,
    // Puertos de lectura
    input  wire [3:0]  ra1,
    input  wire [3:0]  ra2,
    output wire [31:0] rd1,
    output wire [31:0] rd2,

    // Puerto de escritura 1 (Rd, producto bajo)
    input  wire        we3,
    input  wire [3:0]  wa3,
    input  wire [31:0] wd3,

    // Puerto de escritura 2 (Ra, producto alto)
    input  wire        we4,
    input  wire [3:0]  wa4,
    input  wire [31:0] wd4,

    // Valor especial de R15
    input  wire [31:0] r15
);
    // Banco de 16 registros de 32 bits
    reg [31:0] rf [0:15];

    // Escrituras sincrónicas en flanco de subida de clk
    always @(posedge clk) begin
        if (we3)
            rf[wa3] <= wd3;
        if (we4)
            rf[wa4] <= wd4;
    end

    // Lectura combinacional (rn=1111 lee r15)
    assign rd1 = (ra1 == 4'hF ? r15 : rf[ra1]);
    assign rd2 = (ra2 == 4'hF ? r15 : rf[ra2]);
endmodule
