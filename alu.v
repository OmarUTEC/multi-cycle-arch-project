// Harris version con soporte para punto flotante IEEE 754 - 32 bits
// Implementación manual sin funciones $bitstoreal

module alu(
    input  [31:0] a, b,
    input  [3:0] ALUControl,  // Cambiado a 4 bits para más operaciones
    output reg [31:0] Result,
    output reg [31:0] ResultHi,
    output wire [3:0] ALUFlags,
    input wire [31:0] ExtImm,
    input wire [31:0] A
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

    // Variables para punto flotante IEEE 754
    wire sign_a, sign_b, result_sign;
    wire [7:0] exp_a, exp_b, result_exp;
    wire [22:0] mant_a, mant_b;
    wire [23:0] norm_mant_a, norm_mant_b; // Con bit implícito
    wire [47:0] mult_result;
    wire [24:0] add_result;
    wire [22:0] result_mant;
    reg [7:0] exp_diff;
    reg [23:0] aligned_mant;
    wire [31:0] float_add_result, float_mul_result;

    assign condinvb = ALUControl[0] ? ~b : b;
    assign sum = a + condinvb + ALUControl[0];

    //SMUL
    assign signo_a = a[31];   
    assign signo_b = b[31]; 
    assign resultado_signo = signo_a ^ signo_b;
    
    //saco valores absolutos
    assign abs_a = signo_a ? (~a + 1) : a;  // |a|
    assign abs_b = signo_b ? (~b + 1) : b;  // |b|
    
    //multiplicacion sin signo de los valores absolutos
    assign mul_unsigned = abs_a * abs_b;
    
    // le damos signo al resultado
    assign smul_result = resultado_signo ? (~mul_unsigned[63:0] + 1) : mul_unsigned[63:0];
    
    // Descomposición IEEE 754 para suma
    assign sign_a = a[31];
    assign sign_b = b[31];
    assign exp_a = a[30:23];
    assign exp_b = b[30:23];
    assign mant_a = a[22:0];
    assign mant_b = b[22:0];
    
    // Añadir bit implícito (1.mantissa)
    assign norm_mant_a = {1'b1, mant_a};
    assign norm_mant_b = {1'b1, mant_b};
    
    // Suma de punto flotante simplificada
    always @(*) begin
        if (exp_a >= exp_b) begin
            exp_diff = exp_a - exp_b;
            aligned_mant = norm_mant_b >> exp_diff;
        end else begin
            exp_diff = exp_b - exp_a;
            aligned_mant = norm_mant_a >> exp_diff;
        end
    end
    
    assign add_result = (exp_a >= exp_b) ? 
                       (sign_a == sign_b ? norm_mant_a + aligned_mant : norm_mant_a - aligned_mant) :
                       (sign_a == sign_b ? norm_mant_b + aligned_mant : norm_mant_b - aligned_mant);
    
    assign result_exp = (exp_a >= exp_b) ? exp_a : exp_b;
    assign result_sign = (exp_a >= exp_b) ? sign_a : sign_b;
    assign result_mant = add_result[22:0];
    
    assign float_add_result = {result_sign, result_exp, result_mant};
    
    // Multiplicación de punto flotante simplificada
    assign mult_result = norm_mant_a * norm_mant_b;
    assign float_mul_result = {
        sign_a ^ sign_b,                    // Signo
        exp_a + exp_b - 8'd127,             // Exponente
        mult_result[45:23]                  // Mantissa (tomamos bits superiores)
    };
    
    always @(*) begin
        Result   = 32'b0;
        ResultHi = 32'b0;
        
        case (ALUControl[3:0])
            4'b0000, 4'b0001: Result = sum;      // ADD, SUB
            4'b0010:          Result = a & b;     // AND
            4'b0011:          Result = a | b;     // OR
            4'b0111:          Result = a * b;     // MUL
            4'b0100:          Result = a / b;     // DIV
            4'b1011: Result = ExtImm;                        // MOV low16
            4'b1100: Result = (A & 32'h000FFFFF) | ExtImm;   // MOVT high16
            4'b1101: Result = (A & 32'hFF000FFF) | ExtImm;   // MOVM 

            4'b0110:          begin               // SMUL
                Result = smul_result[31:0];
                ResultHi = smul_result[63:32];
            end
            4'b0101:          begin               // UMUL
                Result = umul_result [31:0];
                ResultHi = umul_result [63:32];
            end
            4'b1000:          begin               // FADDS (suma flotante)
                Result = float_add_result;
            end
            4'b1001:          begin               // FMULS (multiplicación flotante)
                Result = float_mul_result;
            end
            default:          Result = 32'b0;
        endcase
    end

    assign neg = Result[31];
    assign zero = (Result == 32'b0);

    // Asignación modificada para is_logic - incluye MOV
    assign is_logic = (ALUControl[3:1] == 3'b001)   // AND, OR
                    || (ALUControl == 4'b0100)      // DIV
                    || (ALUControl == 4'b0111)      // MUL
                    || (ALUControl == 4'b0110)      // SMUL
                    || (ALUControl == 4'b0101)      // UMUL
                    || (ALUControl == 4'b1000)      // FADDS
                    || (ALUControl == 4'b1001)      // FMULS
                    || (ALUControl == 4'b1010);     // MOV - AGREGADO
                    

    assign carry = is_logic ? 1'b0 : sum[32];
    assign overflow = is_logic ? 1'b0 :
        ~(a[31] ^ b[31] ^ ALUControl[0]) &&
        (a[31] ^ sum[31]);

    assign ALUFlags = {neg, zero, carry, overflow};

endmodule