// reg32.v
// Registro de 32 bits con habilitación de carga y reset sincrónico
// Adaptado de flopenr, parametrizable en WIDTH pero usado a WIDTH=32

module reg32 #(
    parameter WIDTH = 32
)(
    input  wire               clk,   // Reloj de sincronización
    input  wire               rst,   // Reset síncrono
    input  wire               load,  // Habilita la carga del dato
    input  wire [WIDTH-1:0]   d,     // Dato de entrada
    output reg  [WIDTH-1:0]   q      // Salida del registro
);
    // Al flanco de reloj, si rst limpia a cero; si load=1 captura d
    always @(posedge clk) begin
        if (rst)
            q <= {WIDTH{1'b0}};
        else if (load)
            q <= d;
    end
endmodule
