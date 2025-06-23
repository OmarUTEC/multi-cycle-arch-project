// 32-bit ALU for ARM processor
module alu(
    input  [31:0] a, b,
    input  [2:0] ALUControl,
    output reg [31:0] Result,
    output wire [3:0] ALUFlags
);

    wire neg, zero, carry, overflow;
    wire [31:0] condinvb;
    wire [32:0] sum;

    // Suma o resta según ALUControl[0]
    assign condinvb = ALUControl[0] ? ~b : b;
    assign sum = a + condinvb + ALUControl[0];

    always @(*) begin
    case (ALUControl[2:0])
        3'b000, 3'b001: Result = sum;       // ADD or SUB
        3'b010:       Result = a & b;       // AND
        3'b011:       Result = a | b;       // OR
        3'b100:       Result = a ^ b;       // XOR
        //3'b101:       Result = b;           // MOV: pasar el operando B sin alterarlo
        default:     Result = 32'b0;        
    endcase
    end


    // Cálculo de las banderas
    assign neg = Result[31];
    assign zero = (Result == 32'b0);

    // Incluir MOV en is_logic para que carry/overflow sean 0 en MOV
    wire is_logic = (ALUControl[2:1] == 2'b01)    // códigos 010 (AND) o 011 (OR)
                    || (ALUControl == 3'b100);    // XOR
                    //|| (ALUControl == 3'b101);   // MOV

    assign carry = is_logic ? 1'b0 : sum[32];
    assign overflow = is_logic ? 1'b0 :
        ~(a[31] ^ b[31] ^ ALUControl[0]) &&
        (a[31] ^ sum[31]);

    assign ALUFlags = {neg, zero, carry, overflow};

endmodule