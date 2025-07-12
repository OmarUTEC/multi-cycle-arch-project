module fadd16(
    input  wire [15:0] a,
    input  wire [15:0] b,
    output wire [15:0] result
);

    // Paso 1: Extraer los componentes
    wire sign_a = a[15];
    wire [4:0] exp_a = a[14:10];
    wire [9:0] mant_a = a[9:0];

    wire sign_b = b[15];
    wire [4:0] exp_b = b[14:10];
    wire [9:0] mant_b = b[9:0];

    // Paso 2: Ponemos el 1 al inicio (bit implícito)
    wire [10:0] norm_mant_a = {1'b1, mant_a};
    wire [10:0] norm_mant_b = {1'b1, mant_b};

    // Variables intermedias 
    reg [4:0] exp_diff;
    reg [10:0] aligned_mant;
    reg [11:0] add_result;
    reg result_sign;
    reg [4:0] pre_norm_exp;
    reg [4:0] normalized_exp;
    reg [10:0] normalized_mant_full;

    // Paso 3 y 4: Comparar exponentes y alinear la mantisa menor
    always @(*) begin
        if (exp_a >= exp_b) begin
            exp_diff = exp_a - exp_b;
            aligned_mant = norm_mant_b >> exp_diff;
        end else begin
            exp_diff = exp_b - exp_a;
            aligned_mant = norm_mant_a >> exp_diff;
        end
    end

    // Paso 5: Sumar o restar las mantisas
    always @(*) begin
        if (exp_a >= exp_b) begin
            if (sign_a == sign_b) begin
                add_result = norm_mant_a + aligned_mant;
            end else begin
                add_result = norm_mant_a - aligned_mant;
            end
        end else begin
            if (sign_a == sign_b) begin
                add_result = norm_mant_b + aligned_mant;
            end else begin
                add_result = norm_mant_b - aligned_mant;
            end
        end
    end

    // Paso 6: Normalizar la mantisa y ajustar el exponente
    wire carry = add_result[11]; 

    always @(*) begin
        // Selección del exponente y signo base
        if (exp_a >= exp_b) begin
            pre_norm_exp = exp_a;
            result_sign = sign_a;
        end else begin
            pre_norm_exp = exp_b;
            result_sign = sign_b;
        end

        // Ajuste basado en el carry
        if (carry) begin
            normalized_exp = pre_norm_exp + 1;
            normalized_mant_full = add_result >> 1;
        end else begin
            normalized_exp = pre_norm_exp;
            normalized_mant_full = add_result[10:0];
        end
    end

    // Resultado
    assign result = {result_sign, normalized_exp, normalized_mant_full[9:0]};

endmodule