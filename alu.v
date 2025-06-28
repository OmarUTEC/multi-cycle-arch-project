module alu(
    input  [31:0] a, b,
    input  [2:0] ALUControl,
    output reg [31:0] Result,
    output wire [3:0] ALUFlags
);
    // Declaraciones de wires
    wire neg, zero, carry, overflow;
    wire [31:0] condinvb;
    wire [32:0] sum;
    wire is_logic;

    assign condinvb = ALUControl[0] ? ~b : b;
    assign sum = a + condinvb + ALUControl[0];

    always @(*) begin
        case (ALUControl[2:0])
            3'b000, 3'b001: Result = sum;
            3'b010:       Result = a & b;
            3'b011:       Result = a | b;
            3'b100:       Result = a ^ b;
            3'b111:       Result = a * b;
            default:     Result = 32'b0;
        endcase
    end

    assign neg = Result[31];
    assign zero = (Result == 32'b0);

    // Asignación modificada para is_logic
    assign is_logic = (ALUControl[2:1] == 2'b01)    // AND, OR
                    || (ALUControl == 3'b100)    // EOR
                    || (ALUControl == 3'b111);   // MUL

    assign carry = is_logic ? 1'b0 : sum[32];
    assign overflow = is_logic ? 1'b0 :
        ~(a[31] ^ b[31] ^ ALUControl[0]) &&
        (a[31] ^ sum[31]);

    assign ALUFlags = {neg, zero, carry, overflow};

endmodule