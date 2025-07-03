module alu(
    input  [31:0] a, b,
    input  [2:0] ALUControl,
    output reg [31:0] Result,
    output reg [31:0] ResultHi,
    output wire [3:0] ALUFlags
);

    wire neg, zero, carry, overflow;
    wire [31:0] condinvb;
    wire [32:0] sum;
    wire is_logic;

    //para 64 bits
    wire signo_a, signo_b, resultado_signo;
    wire [31:0] abs_a, abs_b;
    wire [63:0] mul_unsigned;
    wire [63:0] smul_result;
    wire [63:0] umul_result = a * b;

    assign condinvb = ALUControl[0] ? ~b : b;
    assign sum = a + condinvb + ALUControl[0];

    //SMUL
    assign signo_a = a[31];   
    assign signo_b = b[31]; 
    assign resultado_signo = signo_a ^ signo_b;  //signo para el resultado
    
    //saco valores absolutos
    assign abs_a = signo_a ? (~a + 1) : a;  // |a|
    assign abs_b = signo_b ? (~b + 1) : b;  // |b|
    
    //multiplicacion sin signo de los valores absolutos
    assign mul_unsigned = abs_a * abs_b;
    
    // le damos signo al resultado
    assign smul_result = resultado_signo ? (~mul_unsigned[63:0] + 1) : mul_unsigned[63:0];
    always @(*) begin
        //ResultHi = 32'b0;
        case (ALUControl[2:0])
            3'b000, 3'b001: Result = sum;
            3'b010:       Result = a & b;
            3'b011:       Result = a | b;
            3'b111:       Result = a * b; // MUL
            3'b100:       Result = a / b; // DIV

            3'b110:       begin //SMUL
                Result = smul_result[31:0];
                ResultHi = smul_result[63:32];
            end
            3'b101:       begin // UMUL
                Result = umul_result [31:0];
                ResultHi = umul_result [63:32];
            end
            
            
    
            default:     Result = 32'b0;
        endcase
    end

    assign neg = Result[31];
    assign zero = (Result == 32'b0);

    // Asignación modificada para is_logic
    assign is_logic = (ALUControl[2:1] == 2'b01)    // AND, OR
                    || (ALUControl == 3'b100)    // EOR
                    || (ALUControl == 3'b111)   // MUL
                    || (ALUControl == 3'b101)  //UMUL
                    || (ALUControl == 3'b110);  //SMUL
                    

    assign carry = is_logic ? 1'b0 : sum[32];
    assign overflow = is_logic ? 1'b0 :
        ~(a[31] ^ b[31] ^ ALUControl[0]) &&
        (a[31] ^ sum[31]);

    assign ALUFlags = {neg, zero, carry, overflow};

endmodule