module extend (
    input  wire [23:0] Instr,
    input  wire [1:0]  ImmSrc,
    input  wire        IsMovt,
    input  wire        IsMovm, // <-- AÑADIR

    output reg  [31:0] ExtImm
);
    always @(*) begin
        case (ImmSrc)
            2'b00: ExtImm = {24'b0, Instr[7:0]};   // 8-bit immediate
            2'b01: ExtImm = {20'b0, Instr[11:0]};  // 12-bit immediate
            2'b10: ExtImm = {{6{Instr[23]}}, Instr[23:0], 2'b00}; // Branch offset

                //...
            // Reemplaza el bloque 'begin..end' para 2'b11
            2'b11: begin  // MOV/MOVT/MOVM
                if (IsMovm) begin
                    // MOVM: inmediato de 8 bits, desplazado 12 bits a la izquierda
                    ExtImm = {12'b0, Instr[7:0], 12'b0};
                end else if (!IsMovt) begin
                    // MOV: 12-bit immediate en bits bajos
                    ExtImm = {20'b0, Instr[11:0]};
                end else begin
                    // MOVT: 12-bit immediate en la parte alta (bits 27-16)
                    ExtImm = {4'b0, Instr[11:0], 20'b0};
                end
            end
    //...
            default: ExtImm = 32'b0;
        endcase
    end
endmodule