module fmul(
    input  wire [31:0] a,
    input  wire [31:0] b,
    output wire [31:0] result
);
    // descomponer los inputs
    wire sign_a = a[31];
    wire [7:0] exp_a = a[30:23];
    wire [22:0] mant_a = a[22:0];

    wire sign_b = b[31];
    wire [7:0] exp_b = b[30:23];
    wire [22:0] mant_b = b[22:0];

    // Paso 0: Detectar si algun operando es cero.
    wire is_a_zero = (a[30:0] == 31'b0);
    wire is_b_zero = (b[30:0] == 31'b0);
    wire is_result_zero = is_a_zero || is_b_zero;

    // 1 implicito para formar la mantisa completa de 24 bits
    wire [23:0] norm_mant_a = {1'b1, mant_a};
    wire [23:0] norm_mant_b = {1'b1, mant_b};

    // Paso 1: exponente del producto.
    // sumar expo y restar el sesgo (127)
    wire [7:0] pre_norm_exp = exp_a + exp_b - 8'd127;
    // Paso 2: Multiplicar las mantisas
    // 24 x 24 = 48 bits
    wire [47:0] mult_mant_result = norm_mant_a * norm_mant_b;
    // Paso 3: Para normalizar para MSB es 1
    wire needs_norm = mult_mant_result[47];

    reg [7:0] normalized_exp;
    reg [22:0] normalized_mant;

    always @(*) begin
        if (needs_norm) begin
            // caso 1 : normalizar
            normalized_exp = pre_norm_exp + 1;
            normalized_mant = mult_mant_result[46:24];
        end else begin
            // caso 2 : no normalizar
            normalized_exp = pre_norm_exp;
            normalized_mant = mult_mant_result[45:23];
        end
    end

    // Paso 5: Para el signo del producto.
    wire result_sign = sign_a ^ sign_b;

    // Resutado final con manejo de caso especial
    assign result = is_result_zero ? {result_sign, 31'b0} : {result_sign, normalized_exp, normalized_mant};

endmodule