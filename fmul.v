module fmul(
    input  wire [31:0] a,
    input  wire [31:0] b,
    output wire [31:0] result
);

    // -- Descomposición de las entradas
    wire sign_a = a[31];
    wire [7:0] exp_a = a[30:23];
    wire [22:0] mant_a = a[22:0];

    wire sign_b = b[31];
    wire [7:0] exp_b = b[30:23];
    wire [22:0] mant_b = b[22:0];

    // Se antepone el '1' implícito para formar la mantisa completa de 24 bits
    wire [23:0] norm_mant_a = {1'b1, mant_a};
    wire [23:0] norm_mant_b = {1'b1, mant_b};

    // -- Paso 1: Calcular el exponente del producto.
    // Se suman los exponentes sesgados y se resta el sesgo (127) una vez.
    wire [7:0] pre_norm_exp = exp_a + exp_b - 8'd127;

    // -- Paso 2: Multiplicar las mantisas. [cite: 32, 59]
    // El producto de dos mantisas de 24 bits resulta en un valor de 48 bits.
    wire [47:0] mult_mant_result = norm_mant_a * norm_mant_b;

    // -- Paso 3: Normalizar el producto si es necesario.
    // Si el bit más significativo (47) del producto es 1, se necesita normalizar.
    wire needs_norm = mult_mant_result[47];

    // Si se normaliza, se desplaza la mantisa a la derecha y se incrementa el exponente.
    wire [7:0] normalized_exp = needs_norm ? pre_norm_exp + 1 : pre_norm_exp;
    wire [22:0] normalized_mant = needs_norm ? mult_mant_result[46:24] : mult_mant_result[45:23];

    // -- Paso 4: Redondear la mantisa. 
    // (Omitido).

    // -- Paso 5: Determinar el signo del producto.
    // El signo es positivo si los signos originales son iguales, y negativo si son diferentes.
    wire result_sign = sign_a ^ sign_b;

    // -- Ensamblaje del resultado final
    assign result = {result_sign, normalized_exp, normalized_mant};

endmodule