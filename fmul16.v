module fmul16(
    input  wire [15:0] a,
    input  wire [15:0] b,
    output wire [15:0] result
);

    // Descomponer los inputs
    wire sign_a = a[15];
    wire [4:0] exp_a = a[14:10];
    wire [9:0] mant_a = a[9:0];

    wire sign_b = b[15];
    wire [4:0] exp_b = b[14:10];
    wire [9:0] mant_b = b[9:0];

    // Paso 0: Detectar si algún operando es cero
    wire is_a_zero = (a[14:0] == 15'b0);
    wire is_b_zero = (b[14:0] == 15'b0);
    wire is_result_zero = is_a_zero || is_b_zero;

    // 1 implícito para formar la mantisa completa de 11 bits
    wire [10:0] norm_mant_a = {1'b1, mant_a};
    wire [10:0] norm_mant_b = {1'b1, mant_b};

    // Paso 1: Exponente del producto
    // Sumar exponentes y restar el sesgo (15 para half-precision)
    wire [4:0] pre_norm_exp = exp_a + exp_b - 5'd15;

    // Paso 2: Multiplicar las mantisas
    // 11 x 11 = 22 bits
    wire [21:0] mult_mant_result = norm_mant_a * norm_mant_b;

    // Paso 3: Normalizar para que MSB sea 1
    wire needs_norm = mult_mant_result[21];

    reg [4:0] normalized_exp;
    reg [9:0] normalized_mant;

    always @(*) begin
        if (needs_norm) begin
            // Caso 1: normalizar
            normalized_exp = pre_norm_exp + 1;
            normalized_mant = mult_mant_result[20:11];
        end else begin
            // Caso 2: no normalizar
            normalized_exp = pre_norm_exp;
            normalized_mant = mult_mant_result[19:10];
        end
    end

    // Paso 4: Signo del producto
    wire result_sign = sign_a ^ sign_b;

    // Resultado final con manejo de ceros
    assign result = is_result_zero ? {result_sign, 15'b0} : {result_sign, normalized_exp, normalized_mant};
endmodule