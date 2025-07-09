module fadd(
    input  wire [31:0] a,
    input  wire [31:0] b,
    output wire [31:0] result
);

    // paso 1: extraer los componentes de los mumero 
    wire sign_a = a[31];
    wire [7:0] exp_a = a[30:23];
    wire [22:0] mant_a = a[22:0];

    wire sign_b = b[31];
    wire [7:0] exp_b = b[30:23];
    wire [22:0] mant_b = b[22:0];

    // -- Paso 2: Anteponer el '1' implícito para formar la mantisa completa de 24 bits.
    wire [23:0] norm_mant_a = {1'b1, mant_a};
    wire [23:0] norm_mant_b = {1'b1, mant_b};

    // Variables para los pasos intermedios
    reg [7:0] exp_diff;
    reg [23:0] aligned_mant;
    wire [24:0] add_result;
    wire overflow;
    
    // -- Paso 3 y 4: Comparar exponentes y alinear la mantisa menor.
    always @(*) begin
        // Paso 3: Comparar exponentes para encontrar la diferencia (shift amount).
        if (exp_a >= exp_b) begin
            exp_diff = exp_a - exp_b;
            // Paso 4: Alinear la mantisa del número menor (b) desplazándola a la derecha.
            aligned_mant = norm_mant_b >> exp_diff;
        end else begin
            exp_diff = exp_b - exp_a;
            // Paso 4: Alinear la mantisa del número menor (a) desplazándola a la derecha.
            aligned_mant = norm_mant_a >> exp_diff;
        end
    end

    // -- Paso 5: Sumar (o restar) las mantisas ya alineadas.
    // El resultado tiene 25 bits para poder detectar el acarreo (overflow).
    assign add_result = (exp_a >= exp_b) ?
                       (sign_a == sign_b ? norm_mant_a + aligned_mant : norm_mant_a - aligned_mant) :
                       (sign_a == sign_b ? norm_mant_b + aligned_mant : norm_mant_b - aligned_mant);

    // -- Paso 6: Normalizar la mantisa y ajustar el exponente.
    // Se detecta un desbordamiento (overflow) si el bit más significativo de la suma es 1.
    assign overflow = add_result[24];

    // El exponente y la mantisa finales dependen de si hubo overflow.
    wire [7:0] pre_norm_exp = (exp_a >= exp_b) ? exp_a : exp_b;
    wire [7:0] normalized_exp = overflow ? pre_norm_exp + 1 : pre_norm_exp;
    wire [23:0] normalized_mant_full = overflow ? add_result[24:1] : add_result[23:0];

    // -- Paso 7: Redondear el resultado.
    // (Omitido)

    // -- Paso 8: Ensamblar el resultado final.
    wire result_sign = (exp_a >= exp_b) ? sign_a : sign_b;
    // Se usa el exponente normalizado y los 23 bits de la mantisa normalizada.
    assign result = {result_sign, normalized_exp, normalized_mant_full[22:0]};

endmodule