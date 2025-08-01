module alu(
    input  [31:0] a, b,
    input  [3:0] ALUControl,
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

    // Salidas de los módulos de punto flotante 32 bits
    wire [31:0] float_add_result;
    wire [31:0] float_mul_result;
    
    // Salidas de los módulos de punto flotante 16 bits
    wire [15:0] float16_add_result;
    wire [15:0] float16_mul_result;

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

    // Instancia del módulo FADD (32 bits)
    fadd fadd_inst (
        .a(a),
        .b(b),
        .result(float_add_result)
    );

    // Instancia del módulo FMUL (32 bits)
    fmul fmul_inst (
        .a(a),
        .b(b),
        .result(float_mul_result)
    );
    
    // Instancia del módulo FADD16 (16 bits)
    fadd16 fadd16_inst (
        .a(a[15:0]),      // Toma los 16 bits bajos
        .b(b[15:0]),      // Toma los 16 bits bajos
        .result(float16_add_result)
    );
    
    // Instancia del módulo FMUL16 (16 bits)
    fmul16 fmul16_inst (
        .a(a[15:0]),      // Toma los 16 bits bajos
        .b(b[15:0]),      // Toma los 16 bits bajos
        .result(float16_mul_result)
    );
    
    always @(*) begin
        Result   = 32'b0;
        ResultHi = 32'b0;
        case (ALUControl[3:0])
            4'b0000, 4'b0001: Result = sum; // ADD, SUB
            4'b0010:          Result = a & b; // AND
            4'b0011:          Result = a | b; // OR
            4'b0111:          Result = a * b; // MUL
            4'b0100:          Result = a / b; // DIV
            4'b1011:          Result = ExtImm; // MOV low16
            4'b1100:          Result = (A & 32'h000FFFFF) | ExtImm;   // MOVT high16
            4'b1101:          Result = (A & 32'hFF000FFF) | ExtImm;   // MOVM
            4'b1010:         Result = b;

            4'b0110: begin //SMUL
                Result = smul_result[31:0];
                ResultHi = smul_result[63:32];
            end
            4'b0101: begin // UMUL
                Result = umul_result [31:0];
                ResultHi = umul_result [63:32];
            end
            4'b1000: begin // FADDS (suma flotante 32 bits)
                Result = float_add_result;
            end
            4'b1001: begin // FMULS (multiplicación flotante 32 bits)
                Result = float_mul_result;
            end
            4'b1110: begin // FADDH (suma flotante 16 bits)
                Result = {16'b0, float16_add_result};  // Resultado en los 16 bits bajos
            end
            4'b1111: begin // FMULH (multiplicación flotante 16 bits)
                Result = {16'b0, float16_mul_result};  // Resultado en los 16 bits bajos
            end
            default: Result = 32'b0;
        endcase
    end

    assign neg = Result[31];
    assign zero = (Result == 32'b0 && ResultHi == 32'b0);

    // Asignación modificada para is_logic
    assign is_logic = (ALUControl[3:1] == 3'b001)   // AND, OR 
                    || (ALUControl == 4'b0100)      // DIV 
                    || (ALUControl == 4'b0111)      // MUL 
                    || (ALUControl == 4'b0110)      // SMUL 
                    || (ALUControl == 4'b0101)      // UMUL 
                    || (ALUControl == 4'b1000)      // FADDS 
                    || (ALUControl == 4'b1001)      // FMULS 
                    || (ALUControl == 4'b1110)      // FADDH
                    || (ALUControl == 4'b1111)      // FMULH
                    || (ALUControl == 4'b1010);     // MOV

    assign carry = is_logic ? 1'b0 : sum[32]; 
    assign overflow = is_logic ? 1'b0 :
        ~(a[31] ^ b[31] ^ ALUControl[0]) &&
        (a[31] ^ sum[31]); 
    assign ALUFlags = {neg, zero, carry, overflow};

endmodule